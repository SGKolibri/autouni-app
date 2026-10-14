/// Situação da sessão vista pelo roteador.
enum SessionStatus {
  /// Ainda restaurando a sessão guardada (abertura do app).
  unknown,
  signedIn,
  signedOut,
}

/// Caminhos fora do shell de abas.
abstract final class SessionRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  /// Telas acessíveis sem login.
  static const Set<String> public = {login, forgotPassword};

  /// Parâmetro que guarda o destino original (deep link) até o login.
  static const String fromParam = 'from';
}

/// Guard de rotas por sessão (função pura, testável sem widgets):
///
/// - restaurando a sessão → splash (guardando o destino);
/// - deslogado → só telas públicas; o resto vai para o login, guardando o
///   destino para depois do login;
/// - logado → telas públicas e splash levam ao destino guardado (ou a
///   [home]).
///
/// Devolve o novo local, ou `null` para seguir.
String? sessionRedirect({
  required Uri uri,
  required SessionStatus status,
  required String home,
}) {
  final path = uri.path;
  final isPublic = SessionRoutes.public.contains(path);
  final isSplash = path == SessionRoutes.splash;

  switch (status) {
    case SessionStatus.unknown:
      if (isSplash) return null;
      return _withFrom(SessionRoutes.splash, _destinationOf(uri));
    case SessionStatus.signedOut:
      if (isPublic) return null;
      return _withFrom(
        SessionRoutes.login,
        isSplash ? _safeFrom(uri) : _destinationOf(uri),
      );
    case SessionStatus.signedIn:
      if (isPublic || isSplash) return _safeFrom(uri) ?? home;
      return null;
  }
}

/// Destino a lembrar: o local pedido, exceto a raiz.
String? _destinationOf(Uri uri) => uri.path == '/' ? null : uri.toString();

/// Só aceita destinos internos (`/x`), nunca `//host` ou URLs absolutas.
String? _safeFrom(Uri uri) {
  final from = uri.queryParameters[SessionRoutes.fromParam];
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  final target = Uri.tryParse(from);
  if (target == null) return null;
  final path = target.path;
  if (SessionRoutes.public.contains(path) || path == SessionRoutes.splash) {
    return null;
  }
  return from;
}

String _withFrom(String path, String? from) => from == null
    ? path
    : Uri(
        path: path,
        queryParameters: {SessionRoutes.fromParam: from},
      ).toString();
