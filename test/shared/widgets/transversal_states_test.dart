import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/realtime/realtime_client.dart';
import 'package:autouni_app/core/realtime/realtime_providers.dart';
import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:autouni_app/shared/widgets/cached_async_view.dart';
import 'package:autouni_app/shared/widgets/realtime_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/pump_app.dart';

class _MockRealtimeClient extends Mock implements RealtimeClient {}

void main() {
  group('componentes de estado', () {
    testWidgets('AppListSkeleton desenha as linhas de carregamento', (
      tester,
    ) async {
      await tester.pumpApp(const AppListSkeleton(itemCount: 3));

      expect(find.bySemanticsLabel('Carregando'), findsOneWidget);
      expect(find.byType(AppSkeleton), findsNWidgets(9));
    });

    testWidgets('AppEmptyState mostra título, mensagem e ação', (tester) async {
      var tapped = 0;
      await tester.pumpApp(
        AppEmptyState(
          title: 'Nenhum prédio',
          message: 'Cadastre prédios no painel web.',
          actionLabel: 'Atualizar',
          onAction: () => tapped++,
        ),
      );

      expect(find.text('Nenhum prédio'), findsOneWidget);
      expect(find.text('Cadastre prédios no painel web.'), findsOneWidget);
      await tester.tap(find.text('Atualizar'));
      expect(tapped, 1);
    });

    testWidgets('AppErrorState oferece "Tentar de novo"', (tester) async {
      var retries = 0;
      await tester.pumpApp(
        AppErrorState(message: 'Sem conexão.', onRetry: () => retries++),
      );

      expect(find.text('Não foi possível carregar'), findsOneWidget);
      await tester.tap(find.text('Tentar de novo'));
      expect(retries, 1);
    });
  });

  group('CachedAsyncView', () {
    Widget view(AsyncValue<Cached<List<int>>> value, {VoidCallback? onRetry}) =>
        CachedAsyncView<List<int>>(
          value: value,
          onRetry: onRetry,
          isEmpty: (items) => items.isEmpty,
          empty: const Text('vazio'),
          builder: (_, items) => Text('itens: ${items.join(',')}'),
        );

    testWidgets('carregando sem cache mostra o skeleton', (tester) async {
      await tester.pumpApp(view(const AsyncLoading()));

      expect(find.byType(AppListSkeleton), findsOneWidget);
    });

    testWidgets('erro sem cache mostra o estado de erro com retry', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpApp(
        view(
          const AsyncError(NetworkException(), StackTrace.empty),
          onRetry: () => retries++,
        ),
      );

      expect(find.text('Sem conexão com a internet.'), findsOneWidget);
      await tester.tap(find.text('Tentar de novo'));
      expect(retries, 1);
    });

    testWidgets('dados vazios mostram o estado vazio', (tester) async {
      await tester.pumpApp(view(const AsyncData(Cached(<int>[]))));

      expect(find.text('vazio'), findsOneWidget);
    });

    testWidgets('dados frescos aparecem sem banner', (tester) async {
      await tester.pumpApp(view(const AsyncData(Cached([1, 2]))));

      expect(find.text('itens: 1,2'), findsOneWidget);
      expect(find.byType(StaleDataBanner), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('cache enquanto a rede responde mostra progresso fino', (
      tester,
    ) async {
      await tester.pumpApp(
        view(AsyncData(Cached([1], savedAt: DateTime(2026, 10, 14, 9)))),
      );

      expect(find.text('itens: 1'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(StaleDataBanner), findsNothing);
    });

    testWidgets('offline mostra os dados salvos com o horário', (tester) async {
      final savedAt = DateTime.now().copyWith(hour: 9, minute: 5);
      await tester.pumpApp(
        view(AsyncData(Cached([1], savedAt: savedAt, offline: true))),
      );

      expect(find.text('itens: 1'), findsOneWidget);
      expect(
        find.text('Sem conexão. Mostrando dados salvos às 09:05.'),
        findsOneWidget,
      );
    });
  });

  group('RealtimeStatusBanner', () {
    Future<void> pumpBanner(
      WidgetTester tester,
      RealtimeConnectionStatus status, {
      RealtimeClient? client,
    }) => tester.pumpApp(
      const RealtimeStatusBanner(),
      overrides: [
        realtimeStatusProvider.overrideWithValue(status),
        if (client != null) realtimeClientProvider.overrideWithValue(client),
      ],
    );

    for (final status in [
      RealtimeConnectionStatus.connected,
      RealtimeConnectionStatus.connecting,
      RealtimeConnectionStatus.idle,
    ]) {
      testWidgets('escondido quando ${status.name}', (tester) async {
        await pumpBanner(tester, status);

        expect(find.byType(AppBanner), findsNothing);
      });
    }

    testWidgets('reconectando mostra o aviso de tempo real', (tester) async {
      await pumpBanner(tester, RealtimeConnectionStatus.reconnecting);

      expect(
        find.text('Tempo real indisponível — tentando reconectar.'),
        findsOneWidget,
      );
      expect(find.text('Tentar de novo'), findsNothing);
    });

    testWidgets('recusado pelo servidor oferece reconectar', (tester) async {
      final client = _MockRealtimeClient();
      when(client.connect).thenAnswer((_) async {});
      await pumpBanner(
        tester,
        RealtimeConnectionStatus.unauthorized,
        client: client,
      );

      await tester.tap(find.text('Tentar de novo'));

      verify(client.connect).called(1);
    });
  });
}
