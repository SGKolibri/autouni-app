import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Chamadas JSON sobre o `Dio` da aplicação, com as falhas já traduzidas
/// para [ApiException] — repositórios não lidam com `DioException`.
extension ApiClient on Dio {
  Future<Object?> getJson(String path, {Map<String, dynamic>? query}) =>
      _send(() => get<dynamic>(path, queryParameters: query));

  Future<Object?> postJson(String path, {Object? data}) =>
      _send(() => post<dynamic>(path, data: data));

  Future<Object?> _send(Future<Response<dynamic>> Function() request) async {
    try {
      return (await request()).data;
    } on DioException catch (error) {
      final translated = error.error;
      throw translated is ApiException
          ? translated
          : ApiException.fromDioException(error);
    }
  }
}

/// Lê um objeto JSON com [fromJson]; formato inesperado (campo ausente,
/// tipo errado) vira [UnexpectedResponseException] em vez de erro de cast.
T parseObject<T>(Object? json, T Function(Map<String, dynamic>) fromJson) {
  try {
    if (json is Map<String, dynamic>) return fromJson(json);
  } on TypeError {
    // cai no erro abaixo
  } on FormatException {
    // idem
  }
  throw const UnexpectedResponseException(
    message: 'Resposta inesperada do servidor.',
  );
}

/// Lê uma lista JSON de objetos com [fromJson] (ver [parseObject]).
List<T> parseList<T>(Object? json, T Function(Map<String, dynamic>) fromJson) {
  if (json is! List) {
    throw const UnexpectedResponseException(
      message: 'Resposta inesperada do servidor.',
    );
  }
  return [for (final item in json) parseObject(item, fromJson)];
}
