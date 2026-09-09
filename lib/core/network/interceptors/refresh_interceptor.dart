// Construtor com nomes públicos (retrier/tokenStore/refresher) e campos
// privados — o formal `this._x` daria o mesmo, mantemos assim por clareza.
// ignore_for_file: prefer_initializing_formals

import 'package:dio/dio.dart';

import '../api_exception.dart';
import '../auth_token_store.dart';
import '../token_refresher.dart';
import 'auth_interceptor.dart';

/// Renova o access token automaticamente quando uma request autenticada
/// recebe 401, e repete a request original com o token novo.
///
/// - Uma única renovação por vez (single-flight): requests concorrentes que
///   também tomaram 401 aguardam o mesmo refresh e reusam o token.
/// - Se outra request já renovou enquanto esta esperava, repete direto sem
///   chamar o [TokenRefresher] de novo.
/// - Refresh recusado (ou sem refresh token) → limpa a sessão e emite
///   [UnauthorizedException].
/// - Cada request é repetida no máximo uma vez.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required Dio retrier,
    required AuthTokenStore tokenStore,
    required TokenRefresher refresher,
  }) : _retrier = retrier,
       _tokenStore = tokenStore,
       _refresher = refresher;

  final Dio _retrier;
  final AuthTokenStore _tokenStore;
  final TokenRefresher _refresher;

  static const String _retriedKey = 'autouni.network.retried';

  Future<TokenPair?>? _inFlightRefresh;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final shouldHandle =
        err.response?.statusCode == 401 &&
        options.extra[_retriedKey] != true &&
        !AuthInterceptor.isSkipAuth(options);

    if (!shouldHandle) {
      handler.next(err);
      return;
    }

    try {
      final token = await _freshAccessToken(_bearerOf(options));
      if (token == null) {
        await _tokenStore.clear();
        handler.reject(_sessionExpired(err));
        return;
      }
      handler.resolve(await _retry(options, token));
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode == 401) {
        await _tokenStore.clear();
        handler.reject(_sessionExpired(retryError));
      } else {
        handler.next(retryError);
      }
    }
  }

  /// Token válido para repetir a request, ou `null` se a sessão acabou.
  Future<String?> _freshAccessToken(String? usedToken) async {
    final current = await _tokenStore.readAccessToken();
    if (current != null && current.isNotEmpty && current != usedToken) {
      return current;
    }
    final pair = await (_inFlightRefresh ??= _runRefresh());
    return pair?.accessToken;
  }

  Future<TokenPair?> _runRefresh() async {
    try {
      final refreshToken = await _tokenStore.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return null;

      final pair = await _refresher.refresh(refreshToken);
      if (pair != null) {
        await _tokenStore.saveTokens(
          accessToken: pair.accessToken,
          refreshToken: pair.refreshToken,
        );
      }
      return pair;
    } finally {
      _inFlightRefresh = null;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions options, String token) {
    options.headers['Authorization'] = 'Bearer $token';
    options.extra[_retriedKey] = true;
    return _retrier.fetch<dynamic>(options);
  }

  String? _bearerOf(RequestOptions options) {
    final value = options.headers['Authorization'];
    if (value is String && value.startsWith('Bearer ')) {
      return value.substring('Bearer '.length);
    }
    return null;
  }

  DioException _sessionExpired(DioException source) => source.copyWith(
    error: UnauthorizedException(
      message: 'Sessão expirada. Entre novamente.',
      cause: source,
    ),
  );
}
