import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/cached.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/rbac/app_permission.dart';
import '../../../../shared/rbac/rbac_providers.dart';
import '../../data/automations_repository.dart';
import '../../domain/automation_models.dart';

/// Lista de automações. Cada resposta nova da rede descarta os valores de
/// "ativa" já confirmados (ver [AutomationEnabledOverrides]).
final automationsProvider =
    StreamProvider.autoDispose<Cached<List<Automation>>>((ref) {
      final overrides = ref.read(automationEnabledOverridesProvider.notifier);
      return ref.watch(automationsRepositoryProvider).watchAll().map((cached) {
        if (!cached.isStale && !cached.offline) overrides.clearConfirmed();
        return cached;
      });
    }, name: 'automationsProvider');

/// Uma automação (detalhe e edição).
final automationProvider = StreamProvider.autoDispose
    .family<Cached<Automation>, String>(
      (ref, id) => ref.watch(automationsRepositoryProvider).watchOne(id),
      name: 'automationProvider',
    );

/// Histórico de execuções de uma automação.
final automationHistoryProvider = StreamProvider.autoDispose
    .family<Cached<List<AutomationRun>>, String>(
      (ref, id) => ref.watch(automationsRepositoryProvider).watchHistory(id),
      name: 'automationHistoryProvider',
    );

/// "Ativa" de uma automação enquanto o toggle é enviado ([pending]) e depois
/// de confirmado, até a próxima resposta da rede trazer o valor do servidor.
@immutable
class EnabledOverride {
  const EnabledOverride({required this.enabled, required this.pending});

  final bool enabled;
  final bool pending;
}

@immutable
class EnabledOverrides {
  const EnabledOverrides([this._byId = const {}]);

  final Map<String, EnabledOverride> _byId;

  /// O valor que a tela deve mostrar.
  bool enabledOf(Automation automation) =>
      _byId[automation.id]?.enabled ?? automation.enabled;

  bool isPending(String id) => _byId[id]?.pending ?? false;

  bool hasOverride(String id) => _byId.containsKey(id);
}

class AutomationEnabledOverrides extends Notifier<EnabledOverrides> {
  @override
  EnabledOverrides build() => const EnabledOverrides();

  Map<String, EnabledOverride> get _current => state._byId;

  void begin(String id, {required bool enabled}) => state = EnabledOverrides({
    ..._current,
    id: EnabledOverride(enabled: enabled, pending: true),
  });

  void confirm(String id, {required bool enabled}) => state = EnabledOverrides({
    ..._current,
    id: EnabledOverride(enabled: enabled, pending: false),
  });

  void remove(String id) {
    if (!_current.containsKey(id)) return;
    state = EnabledOverrides({..._current}..remove(id));
  }

  /// Descarta os valores já confirmados (os pendentes seguem valendo).
  void clearConfirmed() {
    if (_current.values.every((o) => o.pending)) return;
    state = EnabledOverrides({
      for (final entry in _current.entries)
        if (entry.value.pending) entry.key: entry.value,
    });
  }
}

final automationEnabledOverridesProvider =
    NotifierProvider<AutomationEnabledOverrides, EnabledOverrides>(
      AutomationEnabledOverrides.new,
      name: 'automationEnabledOverridesProvider',
    );

/// Desfecho de uma ação sobre automação.
@immutable
class AutomationOutcome {
  const AutomationOutcome.success([this.automation])
    : message = null,
      _ok = true;

  /// [message] nulo = ignorado em silêncio (ex.: toque repetido).
  const AutomationOutcome.failure([this.message])
    : automation = null,
      _ok = false;

  final bool _ok;
  final String? message;

  /// A automação salva (criar/editar).
  final Automation? automation;

  bool get isSuccess => _ok;
}

/// Ações de automação, todas sob [AppPermission.manageAutomations]: VIEWER
/// não chega a fazer requests.
class AutomationsController {
  AutomationsController(this._ref);

  static const String forbiddenMessage =
      'Seu perfil não permite gerenciar automações.';

  final Ref _ref;

  AutomationsRepository get _repository =>
      _ref.read(automationsRepositoryProvider);
  AutomationEnabledOverrides get _overrides =>
      _ref.read(automationEnabledOverridesProvider.notifier);

  bool get _allowed =>
      _ref.read(hasPermissionProvider(AppPermission.manageAutomations));

  /// Ativa/desativa com atualização otimista e rollback em erro.
  Future<AutomationOutcome> setEnabled(
    Automation automation, {
    required bool enabled,
  }) async {
    if (!_allowed) return const AutomationOutcome.failure(forbiddenMessage);
    if (_ref
        .read(automationEnabledOverridesProvider)
        .isPending(automation.id)) {
      return const AutomationOutcome.failure();
    }
    _overrides.begin(automation.id, enabled: enabled);
    try {
      final saved = await _repository.setEnabled(
        automation.id,
        enabled: enabled,
      );
      _overrides.confirm(automation.id, enabled: saved.enabled);
      return AutomationOutcome.success(saved);
    } on ApiException catch (error) {
      _overrides.remove(automation.id);
      return AutomationOutcome.failure(error.message);
    }
  }

  /// Executa agora. A automação precisa estar ativa (regra do backend).
  Future<AutomationOutcome> execute(Automation automation) async {
    if (!_allowed) return const AutomationOutcome.failure(forbiddenMessage);
    final enabled = _ref
        .read(automationEnabledOverridesProvider)
        .enabledOf(automation);
    if (!enabled) {
      return const AutomationOutcome.failure(
        'Ative a automação para executar.',
      );
    }
    return _guard(() async {
      await _repository.execute(automation.id);
      _refresh(automation.id);
      return const AutomationOutcome.success();
    });
  }

  Future<AutomationOutcome> delete(Automation automation) async {
    if (!_allowed) return const AutomationOutcome.failure(forbiddenMessage);
    return _guard(() async {
      await _repository.delete(automation.id);
      _overrides.remove(automation.id);
      _ref.invalidate(automationsProvider);
      return const AutomationOutcome.success();
    });
  }

  /// Cria (sem [id]) ou edita.
  Future<AutomationOutcome> save(AutomationDraft draft, {String? id}) async {
    if (!_allowed) return const AutomationOutcome.failure(forbiddenMessage);
    return _guard(() async {
      final saved = id == null
          ? await _repository.create(draft)
          : await _repository.update(id, draft);
      _refresh(saved.id);
      return AutomationOutcome.success(saved);
    });
  }

  void _refresh(String id) {
    _ref
      ..invalidate(automationsProvider)
      ..invalidate(automationProvider(id))
      ..invalidate(automationHistoryProvider(id));
  }

  Future<AutomationOutcome> _guard(
    Future<AutomationOutcome> Function() action,
  ) async {
    try {
      return await action();
    } on ApiException catch (error) {
      return AutomationOutcome.failure(error.message);
    }
  }
}

final automationsControllerProvider = Provider<AutomationsController>(
  AutomationsController.new,
  name: 'automationsControllerProvider',
);
