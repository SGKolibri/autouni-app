import 'dart:async';

import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/features/automations/data/automations_repository.dart';
import 'package:autouni_app/features/automations/domain/automation_models.dart';
import 'package:autouni_app/features/automations/presentation/providers/automations_providers.dart';
import 'package:autouni_app/shared/models/user_role.dart';
import 'package:autouni_app/shared/rbac/rbac_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/automation_fixtures.dart';

class _MockRepository extends Mock implements AutomationsRepository {}

void main() {
  late _MockRepository repository;
  late ProviderContainer container;

  final automation = Automation.fromJson(automationJson(id: 'a1'));
  const draft = AutomationDraft(
    name: 'Nova',
    description: '',
    triggerType: TriggerType.manual,
    cron: null,
    action: AutomationAction(topic: 't'),
  );

  setUpAll(() => registerFallbackValue(draft));

  ProviderContainer build({UserRole role = UserRole.technician}) =>
      ProviderContainer.test(
        overrides: [
          automationsRepositoryProvider.overrideWithValue(repository),
          currentUserRoleProvider.overrideWithValue(role),
        ],
      );

  AutomationsController controller() =>
      container.read(automationsControllerProvider);

  bool enabledOf(Automation a) =>
      container.read(automationEnabledOverridesProvider).enabledOf(a);

  setUp(() {
    repository = _MockRepository();
    when(() => repository.watchAll())
        .thenAnswer((_) => Stream.value(Cached([automation])));
    container = build();
  });

  group('setEnabled (toggle otimista)', () {
    test('muda na hora e mantém o valor confirmado pelo backend', () async {
      final response = Completer<Automation>();
      when(() => repository.setEnabled('a1', enabled: false))
          .thenAnswer((_) => response.future);

      final pending = controller().setEnabled(automation, enabled: false);

      expect(enabledOf(automation), isFalse);
      expect(
        container.read(automationEnabledOverridesProvider).isPending('a1'),
        isTrue,
      );

      response.complete(automation.copyWith(enabled: false));
      final outcome = await pending;

      expect(outcome.isSuccess, isTrue);
      expect(enabledOf(automation), isFalse);
      expect(
        container.read(automationEnabledOverridesProvider).isPending('a1'),
        isFalse,
      );
    });

    test('erro desfaz a mudança e devolve a mensagem', () async {
      when(() => repository.setEnabled('a1', enabled: false))
          .thenThrow(const ServerException(message: 'Falhou no servidor'));

      final outcome = await controller().setEnabled(automation, enabled: false);

      expect(outcome.isSuccess, isFalse);
      expect(outcome.message, 'Falhou no servidor');
      expect(enabledOf(automation), isTrue);
    });

    test('toque repetido enquanto aguarda é ignorado', () async {
      final response = Completer<Automation>();
      when(() => repository.setEnabled('a1', enabled: any(named: 'enabled')))
          .thenAnswer((_) => response.future);

      final first = controller().setEnabled(automation, enabled: false);
      final second = await controller().setEnabled(automation, enabled: true);

      expect(second.isSuccess, isFalse);
      expect(second.message, isNull);
      response.complete(automation.copyWith(enabled: false));
      await first;
      verify(() => repository.setEnabled('a1', enabled: any(named: 'enabled')))
          .called(1);
    });

    test('dado novo da rede substitui o valor confirmado', () async {
      when(() => repository.setEnabled('a1', enabled: false))
          .thenAnswer((_) async => automation.copyWith(enabled: false));
      await controller().setEnabled(automation, enabled: false);
      expect(
        container.read(automationEnabledOverridesProvider).hasOverride('a1'),
        isTrue,
      );

      final subscription = container.listen(automationsProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(automationsProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(automationEnabledOverridesProvider).hasOverride('a1'),
        isFalse,
      );
    });
  });

  group('RBAC: VIEWER é somente leitura', () {
    setUp(() => container = build(role: UserRole.viewer));

    test('nenhuma ação chega ao backend', () async {
      final outcomes = [
        await controller().setEnabled(automation, enabled: false),
        await controller().execute(automation),
        await controller().delete(automation),
        await controller().save(draft),
      ];

      for (final outcome in outcomes) {
        expect(outcome.isSuccess, isFalse);
        expect(outcome.message, 'Seu perfil não permite gerenciar automações.');
      }
      verifyNever(
        () => repository.setEnabled(any(), enabled: any(named: 'enabled')),
      );
      verifyNever(() => repository.execute(any()));
      verifyNever(() => repository.delete(any()));
      verifyNever(() => repository.create(any()));
    });
  });

  group('execute', () {
    test('executa e recarrega lista e histórico', () async {
      when(() => repository.execute('a1')).thenAnswer((_) async {});
      when(() => repository.watchHistory('a1'))
          .thenAnswer((_) => Stream.value(const Cached(<AutomationRun>[])));
      final list = container.listen(automationsProvider, (_, _) {});
      final history = container.listen(
        automationHistoryProvider('a1'),
        (_, _) {},
      );
      addTearDown(list.close);
      addTearDown(history.close);
      await container.read(automationsProvider.future);
      await container.read(automationHistoryProvider('a1').future);

      final outcome = await controller().execute(automation);
      await container.read(automationsProvider.future);
      await container.read(automationHistoryProvider('a1').future);

      expect(outcome.isSuccess, isTrue);
      verify(() => repository.watchAll()).called(2);
      verify(() => repository.watchHistory('a1')).called(2);
    });

    test('desativada não executa', () async {
      final outcome = await controller().execute(
        automation.copyWith(enabled: false),
      );

      expect(outcome.isSuccess, isFalse);
      expect(outcome.message, 'Ative a automação para executar.');
      verifyNever(() => repository.execute(any()));
    });

    test('erro do backend vira mensagem', () async {
      when(
        () => repository.execute('a1'),
      ).thenThrow(const BadRequestException(message: 'Automation is disabled'));

      final outcome = await controller().execute(automation);

      expect(outcome.message, 'Automation is disabled');
    });
  });

  group('delete', () {
    test('exclui e recarrega a lista', () async {
      when(() => repository.delete('a1')).thenAnswer((_) async {});
      final list = container.listen(automationsProvider, (_, _) {});
      addTearDown(list.close);
      await container.read(automationsProvider.future);

      final outcome = await controller().delete(automation);
      await container.read(automationsProvider.future);

      expect(outcome.isSuccess, isTrue);
      verify(() => repository.delete('a1')).called(1);
      verify(() => repository.watchAll()).called(2);
    });

    test('falha mantém tudo e devolve a mensagem', () async {
      when(() => repository.delete('a1')).thenThrow(const NetworkException());

      final outcome = await controller().delete(automation);

      expect(outcome.message, 'Sem conexão com a internet.');
    });
  });

  group('save', () {
    test('sem id cria', () async {
      when(() => repository.create(draft))
          .thenAnswer((_) async => automation.copyWith(id: 'nova'));

      final outcome = await controller().save(draft);

      expect(outcome.isSuccess, isTrue);
      expect(outcome.automation?.id, 'nova');
    });

    test('com id edita', () async {
      when(() => repository.update('a1', draft))
          .thenAnswer((_) async => automation);

      final outcome = await controller().save(draft, id: 'a1');

      expect(outcome.isSuccess, isTrue);
      verify(() => repository.update('a1', draft)).called(1);
      verifyNever(() => repository.create(any()));
    });

    test('erro de validação do backend vira mensagem', () async {
      when(() => repository.create(draft)).thenThrow(
        const BadRequestException(message: 'Invalid cron expression'),
      );

      final outcome = await controller().save(draft);

      expect(outcome.isSuccess, isFalse);
      expect(outcome.message, 'Invalid cron expression');
    });
  });
}
