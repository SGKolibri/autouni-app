import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/push/push_messaging.dart';
import '../../core/push/push_providers.dart';
import '../../core/session/session_hooks.dart';
import 'push_prompt_store.dart';
import 'push_token_repository.dart';

/// Situação do push para o usuário logado.
enum PushStatus {
  /// Sem push (Firebase não configurado, plataforma sem suporte) ou sem
  /// sessão.
  unavailable,

  /// Lendo a permissão / registrando o token.
  checking,

  /// O sistema ainda não perguntou: é a hora de mostrar o convite.
  promptable,

  /// O usuário tocou em "Agora não" há menos de [PushRegistration.promptCooldown].
  dismissed,

  /// Recusado no sistema. O app não insiste (a S6-T5 leva aos ajustes).
  denied,

  /// Permitido e token registrado no backend.
  enabled,

  /// Permitido, mas o token não foi registrado (sem token do FCM ou backend
  /// fora). Tenta de novo na próxima sessão.
  failed,
}

/// Plataforma do aparelho (sobrescrita nos testes).
final pushPlatformProvider = Provider<PushPlatform?>(
  (ref) => PushPlatform.current,
  name: 'pushPlatformProvider',
);

/// Relógio do convite (sobrescrito nos testes).
final pushClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
  name: 'pushClockProvider',
);

/// Push de uma sessão: o token registrado e a escuta de renovação.
class _PushSession {
  _PushSession(this.messaging, this.platform);

  final PushMessaging messaging;
  final PushPlatform platform;
  String? token;
  StreamSubscription<String>? refresh;

  /// A sessão acabou sem logout (ex.: expirou): o token não pode mais ser
  /// removido no backend, então é invalidado no FCM — o backend apaga
  /// tokens recusados no próximo envio.
  void close() {
    unawaited(refresh?.cancel());
    refresh = null;
    if (token != null) {
      token = null;
      unawaited(messaging.deleteToken());
    }
  }
}

/// Registro do token de push, ligado à sessão, com a permissão pedida no
/// momento certo:
///
/// - nunca pede ao abrir o app;
/// - com permissão já dada, registra o token ao entrar;
/// - sem resposta do sistema ainda, fica [PushStatus.promptable] para a tela
///   mostrar um convite explicando o porquê; o prompt do sistema só abre em
///   [accept];
/// - "Agora não" ([dismiss]) esconde o convite por [promptCooldown];
/// - no logout, remove o token no backend antes de a sessão acabar.
class PushRegistration extends Notifier<PushStatus> {
  static const Duration promptCooldown = Duration(days: 7);

  _PushSession? _session;

  @override
  PushStatus build() {
    final messaging = ref.watch(pushMessagingProvider);
    final userId = ref.watch(sessionUserIdProvider);
    final platform = ref.watch(pushPlatformProvider);
    _session = null;
    if (messaging == null || userId == null || platform == null) {
      return PushStatus.unavailable;
    }

    final session = _PushSession(messaging, platform);
    _session = session;
    final removeHook = ref
        .read(logoutHooksProvider)
        .add(() => _unregister(session));
    ref.onDispose(() {
      removeHook();
      session.close();
    });
    unawaited(_check(session));
    return PushStatus.checking;
  }

  bool _isCurrent(_PushSession session) =>
      ref.mounted && identical(_session, session);

  PushTokenRepository get _repository => ref.read(pushTokenRepositoryProvider);

  Future<void> _check(_PushSession session) async {
    final permission = await session.messaging.permission();
    if (!_isCurrent(session)) return;
    switch (permission) {
      case PushPermission.granted:
        await _register(session);
      case PushPermission.denied:
        state = PushStatus.denied;
      case PushPermission.notDetermined:
        final dismissedAt = await ref
            .read(pushPromptStoreProvider)
            .dismissedAt();
        if (!_isCurrent(session)) return;
        final now = ref.read(pushClockProvider)();
        final recent =
            dismissedAt != null && now.difference(dismissedAt) < promptCooldown;
        state = recent ? PushStatus.dismissed : PushStatus.promptable;
    }
  }

  Future<void> _register(_PushSession session) async {
    final token = await session.messaging.getToken();
    if (!_isCurrent(session)) return;
    if (token == null) {
      state = PushStatus.failed;
      return;
    }
    try {
      await _repository.register(token, session.platform);
    } on ApiException {
      if (_isCurrent(session)) state = PushStatus.failed;
      return;
    }
    if (!_isCurrent(session)) return;
    session.token = token;
    session.refresh ??= session.messaging.onTokenRefresh.listen(
      (fresh) => _onTokenRefresh(session, fresh),
    );
    state = PushStatus.enabled;
  }

  Future<void> _onTokenRefresh(_PushSession session, String fresh) async {
    if (!_isCurrent(session)) return;
    try {
      await _repository.register(fresh, session.platform);
      session.token = fresh;
    } on ApiException {
      // Fica com o token anterior registrado; a próxima sessão corrige.
    }
  }

  /// Gancho de logout: roda com o JWT ainda válido.
  Future<void> _unregister(_PushSession session) async {
    final token = session.token;
    session.token = null;
    await session.refresh?.cancel();
    session.refresh = null;
    if (token == null) return;
    try {
      await _repository.unregister(token);
    } on ApiException {
      // O FCM invalida o token abaixo; o backend apaga no próximo envio.
    }
    await session.messaging.deleteToken();
  }

  /// "Ativar" no convite: abre o prompt do sistema.
  Future<void> accept() async {
    final session = _session;
    if (session == null || state != PushStatus.promptable) return;
    state = PushStatus.checking;
    final permission = await session.messaging.requestPermission();
    if (!_isCurrent(session)) return;
    if (permission == PushPermission.granted) {
      await _register(session);
    } else {
      state = PushStatus.denied;
    }
  }

  /// "Agora não" no convite.
  Future<void> dismiss() async {
    if (state != PushStatus.promptable) return;
    state = PushStatus.dismissed;
    await ref
        .read(pushPromptStoreProvider)
        .setDismissedAt(ref.read(pushClockProvider)());
  }
}

final pushRegistrationProvider = NotifierProvider<PushRegistration, PushStatus>(
  PushRegistration.new,
  name: 'pushRegistrationProvider',
);
