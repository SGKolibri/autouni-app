import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Chamadas JSON sobre o `Dio` da aplicação, com as falhas já traduzidas
/// para [ApiException] — repositórios não lidam com `DioException`.
extension ApiClient on Dio {
  Future<Object?> getJson(String path, {Map<String, dynamic>? query}) =>
      _send(() => get<dynamic>(path, queryParameters: query));

  Future<Object?> postJson(String path, {Object? data}) =>
      _send(() => post<dynamic>(path, data: data));

  Future<Object?> putJson(String path, {Object? data}) =>
      _send(() => put<dynamic>(path, data: data));

  Future<Object?> patchJson(String path, {Object? data}) =>
      _send(() => patch<dynamic>(path, data: data));

  /// Aceita `204 No Content` (devolve `null`/vazio).
  Future<Object?> deleteJson(String path, {Object? data}) =>
      _send(() => delete<dynamic>(path, data: data));

  /// Baixa um arquivo binário. O nome vem do `Content-Disposition`, quando
  /// o backend manda.
  Future<DownloadedFile> getBytes(String path) async {
    try {
      final response = await get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
          // Relatórios grandes podem demorar mais que o timeout padrão.
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      return DownloadedFile(
        bytes: response.data ?? const [],
        fileName: fileNameFromDisposition(
          response.headers.value('content-disposition'),
        ),
      );
    } on DioException catch (error) {
      final translated = error.error;
      throw translated is ApiException
          ? translated
          : ApiException.fromDioException(error);
    }
  }

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

/// Arquivo recebido de [ApiClient.getBytes].
class DownloadedFile {
  const DownloadedFile({required this.bytes, this.fileName});

  final List<int> bytes;
  final String? fileName;
}

/// `attachment; filename="r1.pdf"` → `r1.pdf`. Só o nome (sem pastas).
String? fileNameFromDisposition(String? header) {
  if (header == null) return null;
  final match = RegExp(
    r'''filename\*?=(?:UTF-8'')?"?([^";]+)"?''',
    caseSensitive: false,
  ).firstMatch(header);
  final raw = match?.group(1)?.trim();
  if (raw == null || raw.isEmpty) return null;
  String decoded;
  try {
    decoded = Uri.decodeComponent(raw);
  } on ArgumentError {
    decoded = raw;
  }
  final name = decoded.split(RegExp(r'[/\\]')).last;
  return name.isEmpty ? null : name;
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
