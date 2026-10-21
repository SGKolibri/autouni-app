import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/firebase_config.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FirebaseConfig? parse({
    String apiKey = 'key',
    String projectId = 'autouni',
    String messagingSenderId = '123',
    String androidAppId = '1:123:android:abc',
    String iosAppId = '',
    String iosBundleId = '',
  }) => FirebaseConfig.fromDefines(
    apiKey: apiKey,
    projectId: projectId,
    messagingSenderId: messagingSenderId,
    androidAppId: androidAppId,
    iosAppId: iosAppId,
    iosBundleId: iosBundleId,
  );

  group('FirebaseConfig.fromDefines', () {
    test('lê os defines, aparando espaços', () {
      final config = parse(apiKey: ' key ', iosAppId: ' 1:123:ios:def ');

      expect(config, isNotNull);
      expect(config!.apiKey, 'key');
      expect(config.projectId, 'autouni');
      expect(config.messagingSenderId, '123');
      expect(config.androidAppId, '1:123:android:abc');
      expect(config.iosAppId, '1:123:ios:def');
      expect(config.iosBundleId, isNull);
    });

    test('sem os campos comuns, push fica desligado (null)', () {
      expect(parse(apiKey: ''), isNull);
      expect(parse(projectId: '  '), isNull);
      expect(parse(messagingSenderId: ''), isNull);
    });

    test('sem nenhum app id, push fica desligado', () {
      expect(parse(androidAppId: ''), isNull);
      expect(parse(androidAppId: '', iosAppId: '1:123:ios:def'), isNotNull);
    });
  });

  group('FirebaseConfig.appIdFor', () {
    test('escolhe o app id da plataforma', () {
      final config = parse(iosAppId: '1:123:ios:def')!;

      expect(config.appIdFor(TargetPlatform.android), '1:123:android:abc');
      expect(config.appIdFor(TargetPlatform.iOS), '1:123:ios:def');
      expect(config.appIdFor(TargetPlatform.linux), isNull);
    });

    test('plataforma sem app id configurado devolve null', () {
      expect(parse()!.appIdFor(TargetPlatform.iOS), isNull);
    });
  });

  test('igualdade por valor', () {
    expect(parse(), parse());
    expect(parse().hashCode, parse().hashCode);
    expect(parse(), isNot(parse(apiKey: 'outra')));
  });

  group('AppConfig.firebase', () {
    test('sem Firebase por padrão', () {
      expect(AppConfig.forFlavor(Flavor.dev).firebase, isNull);
    });

    test('carrega a config do Firebase e entra na igualdade', () {
      final a = AppConfig.forFlavor(Flavor.prod, firebase: parse());
      final b = AppConfig.forFlavor(Flavor.prod, firebase: parse());

      expect(a.firebase, parse());
      expect(a, b);
      expect(a, isNot(AppConfig.forFlavor(Flavor.prod)));
    });
  });
}
