import 'package:autouni_app/core/config/flavor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Flavor', () {
    test('expõe um rótulo curto para exibição', () {
      expect(Flavor.dev.label, 'DEV');
      expect(Flavor.prod.label, 'PROD');
    });

    test('isDev distingue desenvolvimento de produção', () {
      expect(Flavor.dev.isDev, isTrue);
      expect(Flavor.prod.isDev, isFalse);
    });

    test('fromName resolve o flavor pelo nome', () {
      expect(Flavor.fromName('dev'), Flavor.dev);
      expect(Flavor.fromName('prod'), Flavor.prod);
      expect(Flavor.fromName('PROD'), Flavor.prod);
    });

    test('fromName cai no fallback quando o nome é desconhecido ou vazio', () {
      expect(Flavor.fromName(''), Flavor.dev);
      expect(Flavor.fromName('staging'), Flavor.dev);
      expect(Flavor.fromName('', fallback: Flavor.prod), Flavor.prod);
    });
  });
}
