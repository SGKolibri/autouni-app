import 'package:dio/dio.dart';

/// Erro de rede/API já traduzido para o domínio do app.
///
/// As camadas de dados e apresentação lidam com esta hierarquia selada em vez
/// de `DioException`, o que mantém o `dio` contido na camada core.
sealed class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.cause});

  /// Mensagem apresentável ao usuário (extraída do corpo quando disponível).
  final String message;

  /// Status HTTP, quando o erro veio de uma resposta.
  final int? statusCode;

  /// Erro de origem, preservado para logging/diagnóstico.
  final DioException? cause;

  /// Traduz uma [DioException] para a subclasse mais específica.
  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return NetworkTimeoutException(cause: error);
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return NetworkException(cause: error);
      case DioExceptionType.cancel:
        return RequestCancelledException(cause: error);
      case DioExceptionType.badResponse:
        return _fromResponse(error);
      case DioExceptionType.unknown:
        if (error.error is DioException) {
          return ApiException.fromDioException(error.error! as DioException);
        }
        return NetworkException(cause: error);
    }
  }

  static ApiException _fromResponse(DioException error) {
    final status = error.response?.statusCode ?? 0;
    final body = error.response?.data;
    final message = _extractMessage(body);

    switch (status) {
      case 400:
      case 422:
        return BadRequestException(
          message: message ?? 'Requisição inválida.',
          statusCode: status,
          fieldErrors: _extractFieldErrors(body),
          cause: error,
        );
      case 401:
        return UnauthorizedException(
          message: message ?? 'Sessão expirada. Entre novamente.',
          cause: error,
        );
      case 403:
        return ForbiddenException(
          message: message ?? 'Você não tem permissão para esta ação.',
          cause: error,
        );
      case 404:
        return NotFoundException(
          message: message ?? 'Recurso não encontrado.',
          cause: error,
        );
      default:
        if (status >= 500) {
          return ServerException(
            message: message ?? 'Erro no servidor. Tente novamente.',
            statusCode: status,
            cause: error,
          );
        }
        return UnexpectedResponseException(
          message: message ?? 'Resposta inesperada do servidor.',
          statusCode: status,
          cause: error,
        );
    }
  }

  static String? _extractMessage(Object? body) {
    if (body is! Map) return null;
    final raw = body['message'] ?? body['error'] ?? body['detail'];
    if (raw is String && raw.trim().isNotEmpty) return raw;
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => e.toString()).join('\n');
    }
    return null;
  }

  static Map<String, List<String>> _extractFieldErrors(Object? body) {
    if (body is! Map) return const {};
    final errors = body['errors'];
    if (errors is! Map) return const {};
    return errors.map(
      (key, value) => MapEntry(
        key.toString(),
        value is List
            ? value.map((e) => e.toString()).toList()
            : [value.toString()],
      ),
    );
  }

  @override
  String toString() => '$runtimeType(${statusCode ?? '-'}): $message';
}

/// Sem conexão / host inacessível / falha de TLS.
class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'Sem conexão com a internet.',
    super.cause,
  });
}

/// Estourou connect/send/receive timeout.
class NetworkTimeoutException extends ApiException {
  const NetworkTimeoutException({
    super.message = 'A conexão demorou demais. Tente novamente.',
    super.cause,
  });
}

/// A request foi cancelada (ex.: tela descartada).
class RequestCancelledException extends ApiException {
  const RequestCancelledException({
    super.message = 'Requisição cancelada.',
    super.cause,
  });
}

/// 400/422 — payload inválido. [fieldErrors] traz erros por campo quando o
/// backend os envia em `errors`.
class BadRequestException extends ApiException {
  const BadRequestException({
    required super.message,
    this.fieldErrors = const {},
    super.statusCode,
    super.cause,
  });

  final Map<String, List<String>> fieldErrors;
}

/// 401 — token ausente/expirado e o refresh não resolveu.
class UnauthorizedException extends ApiException {
  const UnauthorizedException({required super.message, super.cause})
    : super(statusCode: 401);
}

/// 403 — autenticado, mas sem permissão (RBAC).
class ForbiddenException extends ApiException {
  const ForbiddenException({required super.message, super.cause})
    : super(statusCode: 403);
}

/// 404 — recurso inexistente.
class NotFoundException extends ApiException {
  const NotFoundException({required super.message, super.cause})
    : super(statusCode: 404);
}

/// 5xx — falha do lado do servidor.
class ServerException extends ApiException {
  const ServerException({
    required super.message,
    super.statusCode,
    super.cause,
  });
}

/// Qualquer outro status HTTP não previsto.
class UnexpectedResponseException extends ApiException {
  const UnexpectedResponseException({
    required super.message,
    super.statusCode,
    super.cause,
  });
}
