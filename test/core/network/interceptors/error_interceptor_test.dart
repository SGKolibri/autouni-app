import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/network/interceptors/error_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

void main() {
  Dio buildDio(FakeHttpAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(ErrorInterceptor());
    return dio;
  }

  test(
    'converte DioException de status em ApiException tipada no campo error',
    () async {
      final dio = buildDio(
        FakeHttpAdapter.always(FakeResponse(404, body: {'message': 'sumiu'})),
      );

      try {
        await dio.get<void>('/x');
        fail('deveria lançar');
      } on DioException catch (e) {
        expect(e.error, isA<NotFoundException>());
        expect((e.error! as ApiException).message, 'sumiu');
      }
    },
  );

  test('erro de conexão vira NetworkException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = _ThrowingAdapter()
      ..interceptors.add(ErrorInterceptor());

    try {
      await dio.get<void>('/x');
      fail('deveria lançar');
    } on DioException catch (e) {
      expect(e.error, isA<NetworkException>());
    }
  });

  test('não re-embrulha um erro que já carrega ApiException', () async {
    final original = UnauthorizedException(message: 'sessão expirada');
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeHttpAdapter.always(FakeResponse(200))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(requestOptions: options, error: original),
            true,
          ),
        ),
      )
      ..interceptors.add(ErrorInterceptor());

    try {
      await dio.get<void>('/x');
      fail('deveria lançar');
    } on DioException catch (e) {
      expect(e.error, same(original));
    }
  });
}

class _ThrowingAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'sem rede',
    );
  }
}
