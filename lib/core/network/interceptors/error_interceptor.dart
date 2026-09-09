import 'package:dio/dio.dart';

import '../api_exception.dart';

/// Última parada da cadeia de erro: traduz qualquer [DioException] crua para
/// uma [ApiException] tipada e a anexa em `DioException.error`, para que as
/// camadas acima nunca precisem inspecionar `dio` diretamente.
class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is ApiException) {
      handler.next(err);
      return;
    }
    handler.next(err.copyWith(error: ApiException.fromDioException(err)));
  }
}
