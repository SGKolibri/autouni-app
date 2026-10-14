import 'package:autouni_app/core/router/session_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const home = '/dashboard';

  String? redirect(String location, SessionStatus status) =>
      sessionRedirect(uri: Uri.parse(location), status: status, home: home);

  group('restaurando a sessão', () {
    test('qualquer tela vai para o splash, lembrando o destino', () {
      expect(
        redirect('/environments/buildings/b1', SessionStatus.unknown),
        '/splash?from=%2Fenvironments%2Fbuildings%2Fb1',
      );
    });

    test('a raiz vai para o splash sem destino', () {
      expect(redirect('/', SessionStatus.unknown), '/splash');
    });

    test('o splash fica', () {
      expect(redirect('/splash', SessionStatus.unknown), isNull);
    });
  });

  group('deslogado', () {
    test('tela protegida vai para o login, lembrando o destino', () {
      expect(
        redirect('/dashboard', SessionStatus.signedOut),
        '/login?from=%2Fdashboard',
      );
    });

    test('telas públicas ficam', () {
      expect(redirect('/login', SessionStatus.signedOut), isNull);
      expect(redirect('/forgot-password', SessionStatus.signedOut), isNull);
    });

    test('saindo do splash, o destino guardado vai junto para o login', () {
      expect(
        redirect('/splash?from=%2Fnotifications', SessionStatus.signedOut),
        '/login?from=%2Fnotifications',
      );
      expect(redirect('/splash', SessionStatus.signedOut), '/login');
    });
  });

  group('logado', () {
    test('telas protegidas ficam', () {
      expect(redirect('/dashboard', SessionStatus.signedIn), isNull);
      expect(redirect('/environments/x', SessionStatus.signedIn), isNull);
    });

    test('login e splash levam ao destino guardado', () {
      expect(
        redirect(
          '/login?from=%2Fenvironments%2Fbuildings%2Fb1',
          SessionStatus.signedIn,
        ),
        '/environments/buildings/b1',
      );
      expect(
        redirect('/splash?from=%2Fsettings', SessionStatus.signedIn),
        '/settings',
      );
    });

    test('sem destino guardado, vão para a home', () {
      expect(redirect('/login', SessionStatus.signedIn), home);
      expect(redirect('/splash', SessionStatus.signedIn), home);
      expect(redirect('/forgot-password', SessionStatus.signedIn), home);
    });

    for (final from in [
      'https://evil.com',
      '//evil.com/x',
      'dashboard',
      '/login',
      '/splash',
    ]) {
      test('ignora destino inseguro ou circular "$from"', () {
        final location = Uri(
          path: '/login',
          queryParameters: {'from': from},
        ).toString();
        expect(redirect(location, SessionStatus.signedIn), home);
      });
    }
  });
}
