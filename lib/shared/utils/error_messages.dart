import '../../core/network/api_exception.dart';

/// Mensagem apresentável para qualquer erro vindo das camadas de dados.
String describeError(Object? error) => switch (error) {
  ApiException(:final message) => message,
  _ => 'Algo deu errado. Tente novamente.',
};
