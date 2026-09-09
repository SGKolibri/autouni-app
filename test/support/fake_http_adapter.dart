import 'dart:convert';

import 'package:dio/dio.dart';

/// Resposta programada para o [FakeHttpAdapter].
class FakeResponse {
  FakeResponse(
    this.statusCode, {
    this.body = const <String, dynamic>{},
    this.headers,
  });

  final int statusCode;
  final Object? body;
  final Map<String, List<String>>? headers;
}

/// [HttpClientAdapter] de teste: não faz rede, apenas devolve o que o
/// [handler] decidir a partir das [RequestOptions], e registra cada chamada
/// em [requests] para asserções.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  /// Atalho para um adapter que responde sempre a mesma coisa.
  factory FakeHttpAdapter.always(FakeResponse response) =>
      FakeHttpAdapter((_) => response);

  final FakeResponse Function(RequestOptions options) handler;

  final List<RequestOptions> requests = <RequestOptions>[];

  int get callCount => requests.length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = handler(options);
    final payload = response.body is String
        ? response.body! as String
        : jsonEncode(response.body);
    return ResponseBody.fromString(
      payload,
      response.statusCode,
      headers:
          response.headers ??
          {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
    );
  }

  @override
  void close({bool force = false}) {}
}
