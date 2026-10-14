import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta um componente do design system dentro do tema real do app, num
/// quadro de tamanho fixo — base tanto para testes de comportamento quanto
/// para os golden tests.
Future<void> pumpComponent(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  Size size = const Size(390, 220),
  EdgeInsets padding = const EdgeInsets.all(16),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: Padding(padding: padding, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Envolve um componente que precisa de um `Scaffold`/altura própria (app bar,
/// bottom nav).
Widget scaffoldWith({
  PreferredSizeWidget? appBar,
  Widget? bottomNav,
  Widget? body,
}) {
  return Scaffold(
    appBar: appBar,
    bottomNavigationBar: bottomNav,
    body: body ?? const SizedBox.expand(),
  );
}
