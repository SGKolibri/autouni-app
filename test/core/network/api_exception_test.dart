import 'package:autouni_app/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dioError(DioExceptionType type, {int? statusCode, Object? data}) {
  final requestOptions = RequestOptions(path: '/x');
  return DioException(
    requestOptions: requestOptions,
    type: type,
    response: statusCode == null
        ? null
        : Response(
            requestOptions: requestOptions,
            statusCode: statusCode,
            data: data,
          ),
  );
}

void main() {
  group('ApiException.fromDioException', () {
    test('timeouts viram NetworkTimeoutException', () {
      for (final type in const [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(
          ApiException.fromDioException(_dioError(type)),
          isA<NetworkTimeoutException>(),
        );
      }
    });

    test('erro de conexão vira NetworkException', () {
      expect(
        ApiException.fromDioException(
          _dioError(DioExceptionType.connectionError),
        ),
        isA<NetworkException>(),
      );
    });

    test('cancelamento vira RequestCancelledException', () {
      expect(
        ApiException.fromDioException(_dioError(DioExceptionType.cancel)),
        isA<RequestCancelledException>(),
      );
    });

    test('401 vira UnauthorizedException', () {
      expect(
        ApiException.fromDioException(
          _dioError(DioExceptionType.badResponse, statusCode: 401),
        ),
        isA<UnauthorizedException>(),
      );
    });

    test('403 vira ForbiddenException', () {
      expect(
        ApiException.fromDioException(
          _dioError(DioExceptionType.badResponse, statusCode: 403),
        ),
        isA<ForbiddenException>(),
      );
    });

    test('404 vira NotFoundException', () {
      expect(
        ApiException.fromDioException(
          _dioError(DioExceptionType.badResponse, statusCode: 404),
        ),
        isA<NotFoundException>(),
      );
    });

    test('422 vira BadRequestException com os erros de campo', () {
      final exception = ApiException.fromDioException(
        _dioError(
          DioExceptionType.badResponse,
          statusCode: 422,
          data: {
            'message': 'Dados inválidos',
            'errors': {
              'email': ['obrigatório'],
            },
          },
        ),
      );

      expect(exception, isA<BadRequestException>());
      expect(exception.message, 'Dados inválidos');
      expect((exception as BadRequestException).fieldErrors['email'], [
        'obrigatório',
      ]);
    });

    test('5xx vira ServerException com o status', () {
      final exception = ApiException.fromDioException(
        _dioError(DioExceptionType.badResponse, statusCode: 503),
      );

      expect(exception, isA<ServerException>());
      expect(exception.statusCode, 503);
    });

    test('extrai a mensagem do corpo quando presente', () {
      final exception = ApiException.fromDioException(
        _dioError(
          DioExceptionType.badResponse,
          statusCode: 400,
          data: {'message': 'Requisição ruim'},
        ),
      );

      expect(exception.message, 'Requisição ruim');
    });

    test('mensagem em lista é achatada', () {
      final exception = ApiException.fromDioException(
        _dioError(
          DioExceptionType.badResponse,
          statusCode: 400,
          data: {
            'message': ['campo a inválido', 'campo b inválido'],
          },
        ),
      );

      expect(exception.message, contains('campo a inválido'));
      expect(exception.message, contains('campo b inválido'));
    });

    test('status inesperado sem corpo vira UnexpectedResponseException', () {
      final exception = ApiException.fromDioException(
        _dioError(DioExceptionType.badResponse, statusCode: 418),
      );

      expect(exception, isA<UnexpectedResponseException>());
      expect(exception.statusCode, 418);
    });

    test('preserva a DioException de origem em cause', () {
      final source = _dioError(DioExceptionType.connectionError);

      expect(ApiException.fromDioException(source).cause, same(source));
    });
  });
}
