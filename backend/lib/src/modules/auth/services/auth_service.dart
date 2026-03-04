import 'dart:convert';
import 'dart:math';

import 'package:apac_backend/src/modules/auth/repositories/auth_repository.dart';
import 'package:apac_backend/src/modules/auth/services/password_hasher.dart';

class AuthService {
  AuthService(this._repository, this._hasher);

  final IAuthRepository _repository;
  final PasswordHasher _hasher;

  Future<Map<String, dynamic>> register({
    required String nome,
    required String email,
    required String senha,
    List<String> perfis = const <String>['operador'],
  }) async {
    final normalizedEmail = email.toLowerCase().trim();
    final existing = await _repository.getUserByEmail(normalizedEmail);
    if (existing != null) {
      throw StateError('Ja existe usuario com esse email.');
    }

    final salt = _hasher.generateSalt();
    final hash = _hasher.hashPassword(senha, salt);

    return _repository.createUser(
      nome: nome.trim(),
      email: normalizedEmail,
      senhaHash: hash,
      senhaSalt: salt,
      perfis: perfis,
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    final normalizedEmail = email.toLowerCase().trim();
    final user = await _repository.getUserByEmail(normalizedEmail);
    if (user == null) {
      throw StateError('Credenciais invalidas.');
    }

    final ativo = user['ativo'] == true || user['ativo'] == 1;
    if (!ativo) {
      throw StateError('Usuario inativo.');
    }

    final senhaHash = (user['senha_hash'] ?? '').toString();
    final senhaSalt = (user['senha_salt'] ?? '').toString();
    final ok = _hasher.verify(senha, senhaSalt, senhaHash);
    if (!ok) {
      throw StateError('Credenciais invalidas.');
    }

    final token = _generateToken();
    final expiresAt = DateTime.now().toUtc().add(const Duration(hours: 12));
    await _repository.createSession(
      usuarioId: (user['id'] as num).toInt(),
      token: token,
      expiresAt: expiresAt,
    );

    return {
      'access_token': token,
      'token_type': 'Bearer',
      'expires_at': expiresAt.toIso8601String(),
      'user': {
        'id': user['id'],
        'nome': user['nome'],
        'email': user['email'],
        'roles': user['roles'] ?? const <String>[],
      },
    };
  }

  Future<Map<String, dynamic>?> authenticate(String token) async {
    if (token.trim().isEmpty) return null;
    final session = await _repository.getSessionWithUser(token.trim());
    if (session == null) return null;

    if (session['revoked_at'] != null && session['revoked_at'].toString().isNotEmpty) {
      return null;
    }

    final expiresAt = DateTime.tryParse((session['expires_at'] ?? '').toString());
    if (expiresAt == null || DateTime.now().toUtc().isAfter(expiresAt.toUtc())) {
      return null;
    }

    final ativo = session['ativo'] == true || session['ativo'] == 1;
    if (!ativo) return null;

    return {
      'id': (session['id'] as num).toInt(),
      'nome': (session['nome'] ?? '').toString(),
      'email': (session['email'] ?? '').toString(),
      'roles': (session['roles'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
    };
  }

  Future<void> logout(String token) async {
    await _repository.revokeSession(token.trim());
  }

  String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(48, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
