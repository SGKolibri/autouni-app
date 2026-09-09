import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/component_harness.dart';

void main() {
  testWidgets('mostra título, mensagem e dispara a ação', (tester) async {
    var pressed = 0;
    await pumpComponent(
      tester,
      AppBanner(
        title: 'Falha ao carregar',
        message: 'Não foi possível buscar os dispositivos.',
        tone: AppTone.danger,
        action: AppBannerAction(
          label: 'Tentar de novo',
          onPressed: () => pressed++,
        ),
      ),
    );
    expect(find.text('Falha ao carregar'), findsOneWidget);
    expect(
      find.text('Não foi possível buscar os dispositivos.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tentar de novo'));
    expect(pressed, 1);
  });

  testWidgets('onDismiss mostra o X e responde ao toque', (tester) async {
    var dismissed = false;
    await pumpComponent(
      tester,
      AppBanner(message: 'Aviso qualquer', onDismiss: () => dismissed = true),
    );
    await tester.tap(find.byIcon(Icons.close));
    expect(dismissed, isTrue);
  });

  testWidgets('wsDisconnected traz mensagem e ação de reconectar', (
    tester,
  ) async {
    var retried = false;
    await pumpComponent(
      tester,
      AppBanner.wsDisconnected(onRetry: () => retried = true),
    );
    expect(find.textContaining('Tempo real indisponível'), findsOneWidget);
    await tester.tap(find.text('Tentar de novo'));
    expect(retried, isTrue);
  });

  testWidgets('golden: os quatro tons', (tester) async {
    await pumpComponent(
      tester,
      size: const Size(390, 360),
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBanner(message: 'Mensagem informativa.', tone: AppTone.info),
          SizedBox(height: 8),
          AppBanner(message: 'Tudo certo por aqui.', tone: AppTone.success),
          SizedBox(height: 8),
          AppBanner(message: 'Atenção a este ponto.', tone: AppTone.warning),
          SizedBox(height: 8),
          AppBanner(
            title: 'Erro',
            message: 'Algo deu errado.',
            tone: AppTone.danger,
          ),
        ],
      ),
    );
    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('goldens/app_banner.png'),
    );
  });
}
