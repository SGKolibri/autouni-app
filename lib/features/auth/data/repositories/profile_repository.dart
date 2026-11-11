import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/interceptors/auth_interceptor.dart';
import '../../../../core/network/network_providers.dart';
import '../../domain/models/user.dart';

/// A senha atual informada não confere.
class WrongCurrentPasswordException implements Exception {
  const WrongCurrentPasswordException();
}

/// Perfil do usuário logado (`/users/:id`).
abstract interface class ProfileRepository {
  /// `GET /users/:id` — inclui telefone e avatar, que a sessão restaurada
  /// do JWT não tem.
  Future<User> fetch(String userId);

  /// `PUT /users/:id` só com nome e telefone (nunca papel ou e-mail).
  Future<User> update(String userId, {required String name, String? phone});

  /// Troca a senha. O backend não confere a senha atual no `PUT`, então o
  /// app confere antes com `POST /auth/login`. Senha atual errada →
  /// [WrongCurrentPasswordException].
  Future<void> changePassword({
    required String userId,
    required String email,
    required String currentPassword,
    required String newPassword,
  });
}

class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository(this._dio);

  final Dio _dio;

  @override
  Future<User> fetch(String userId) async =>
      parseObject(await _dio.getJson('/users/$userId'), User.fromJson);

  @override
  Future<User> update(
    String userId, {
    required String name,
    String? phone,
  }) async => parseObject(
    await _dio.putJson(
      '/users/$userId',
      data: {'name': name.trim(), 'phone': phone},
    ),
    User.fromJson,
  );

  @override
  Future<void> changePassword({
    required String userId,
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/auth/login',
        data: {'email': email, 'password': currentPassword},
        // Rota pública: sem Bearer e sem refresh automático no 401.
        options: Options(extra: AuthInterceptor.skipAuth),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const WrongCurrentPasswordException();
      }
      final translated = error.error;
      throw translated is ApiException
          ? translated
          : ApiException.fromDioException(error);
    }
    await _dio.putJson('/users/$userId', data: {'password': newPassword});
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => HttpProfileRepository(ref.watch(dioProvider)),
  name: 'profileRepositoryProvider',
);
