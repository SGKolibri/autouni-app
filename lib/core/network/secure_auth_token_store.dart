import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_token_store.dart';

/// [AuthTokenStore] persistido no armazenamento seguro do sistema
/// (Keychain no iOS, Keystore no Android), para a sessão sobreviver ao
/// fechamento do app.
///
/// Os tokens são lidos do disco uma única vez e servidos da memória depois —
/// o `AuthInterceptor` consulta o access token a cada request.
///
/// O armazenamento seguro pode falhar (ex.: chave do Keystore invalidada
/// após restauração de backup). Nenhuma falha vaza daqui:
/// - na leitura, o conteúdo ilegível é descartado e a sessão começa vazia;
/// - na escrita, a sessão segue valendo em memória até o app fechar;
/// - ao apagar, a sessão em memória é encerrada de qualquer forma.
class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore([this._storage = defaultStorage]);

  static const String accessTokenKey = 'autouni.auth.access_token';
  static const String refreshTokenKey = 'autouni.auth.refresh_token';

  /// No iOS os tokens ficam legíveis após o primeiro desbloqueio (o app pode
  /// renovar a sessão em background) e não migram para outro aparelho.
  static const FlutterSecureStorage defaultStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final FlutterSecureStorage _storage;

  Future<_Tokens>? _tokens;

  @override
  Future<String?> readAccessToken() async => (await _load()).access;

  @override
  Future<String?> readRefreshToken() async => (await _load()).refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _tokens = Future.value((access: accessToken, refresh: refreshToken));
    try {
      await _storage.write(key: accessTokenKey, value: accessToken);
      await _storage.write(key: refreshTokenKey, value: refreshToken);
    } on PlatformException {
      // Sem persistência: a sessão vale só até o app fechar.
    }
  }

  @override
  Future<void> clear() async {
    _tokens = Future.value(_noTokens);
    await _deleteStored();
  }

  Future<_Tokens> _load() => _tokens ??= _readStored();

  Future<_Tokens> _readStored() async {
    try {
      return (
        access: await _storage.read(key: accessTokenKey),
        refresh: await _storage.read(key: refreshTokenKey),
      );
    } on PlatformException {
      await _deleteStored();
      return _noTokens;
    }
  }

  Future<void> _deleteStored() async {
    try {
      await _storage.delete(key: accessTokenKey);
      await _storage.delete(key: refreshTokenKey);
    } on PlatformException {
      // Nada a fazer: a sessão em memória já foi encerrada.
    }
  }
}

typedef _Tokens = ({String? access, String? refresh});

const _Tokens _noTokens = (access: null, refresh: null);
