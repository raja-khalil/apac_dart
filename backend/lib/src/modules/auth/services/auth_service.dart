import 'dart:convert';
import 'dart:math';

import 'package:apac_backend/src/config/env.dart';
import 'package:apac_backend/src/modules/auth/repositories/auth_repository.dart';
import 'package:apac_backend/src/modules/auth/services/email_sender.dart';
import 'package:apac_backend/src/modules/auth/services/password_hasher.dart';

class AuthService {
  AuthService(this._repository, this._hasher, this._emailSender);

  final IAuthRepository _repository;
  final PasswordHasher _hasher;
  final IEmailSender _emailSender;

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

  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    final normalizedEmail = email.toLowerCase().trim();
    final user = await _repository.getUserByEmail(normalizedEmail);
    if (user == null) {
      return {
        'message': 'Se o email existir, um codigo de redefinicao foi gerado.',
      };
    }

    final ativo = user['ativo'] == true || user['ativo'] == 1;
    if (!ativo) {
      return {
        'message': 'Se o email existir, um codigo de redefinicao foi gerado.',
      };
    }

    final token = _generateToken();
    final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 30));
    await _repository.createPasswordResetToken(
      userId: (user['id'] as num).toInt(),
      token: token,
      expiresAt: expiresAt,
    );

    return {
      'message': 'Codigo de redefinicao gerado.',
      'reset_token': token,
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> sendPasswordSetupInvite({
    required String email,
    String? nome,
  }) async {
    final resetData = await requestPasswordReset(email: email);
    final token = (resetData['reset_token'] ?? '').toString();
    if (token.isEmpty) {
      return {
        'sent': false,
        'message': 'Nao foi possivel gerar token de redefinicao.',
      };
    }

    final link =
        '${EnvConfig.frontendBaseUrl}/?reset_token=$token&email=${Uri.encodeComponent(email)}';

    final text = '''
Olá${(nome ?? '').trim().isNotEmpty ? ' $nome' : ''},

Seu usuário foi cadastrado no sistema APAC/OCI.
Para criar sua senha de acesso, use o link abaixo:
$link

Se preferir, no login clique em "Esqueci senha" e use este código:
$token

Este código expira em 30 minutos.
''';

    final html = '''
<p>Olá${(nome ?? '').trim().isNotEmpty ? ' ${nome!.trim()}' : ''},</p>
<p>Seu usuário foi cadastrado no sistema APAC/OCI.</p>
<p>Para criar sua senha de acesso, use o link abaixo:</p>
<p><a href="$link">$link</a></p>
<p>Se preferir, no login clique em <strong>Esqueci senha</strong> e use este código:</p>
<p><strong>$token</strong></p>
<p>Este código expira em 30 minutos.</p>
''';

    bool sent = false;
    try {
      sent = await _emailSender.send(
        toEmail: email,
        subject: 'APAC/OCI - Criacao de senha',
        text: text,
        html: html,
      );
    } catch (_) {
      sent = false;
    }

    if (sent) {
      return {
        'sent': true,
        'message': 'Convite enviado por email.',
      };
    }

    return {
      'sent': false,
      'message':
          'Usuario criado, mas nao foi possivel enviar email (SMTP nao configurado).',
      'reset_token': token,
      'reset_link': link,
    };
  }

  Future<void> resetPassword({
    required String token,
    required String senha,
  }) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw StateError('Token invalido.');
    }
    if (senha.trim().length < 6) {
      throw StateError('Nova senha deve ter no minimo 6 caracteres.');
    }

    final reset = await _repository.getPasswordResetByToken(normalizedToken);
    if (reset == null) {
      throw StateError('Token invalido ou expirado.');
    }
    if (reset['used_at'] != null && reset['used_at'].toString().trim().isNotEmpty) {
      throw StateError('Token invalido ou expirado.');
    }

    final expiresAt = DateTime.tryParse((reset['expires_at'] ?? '').toString());
    if (expiresAt == null || DateTime.now().toUtc().isAfter(expiresAt.toUtc())) {
      throw StateError('Token invalido ou expirado.');
    }

    final userId = (reset['usuario_id'] as num).toInt();
    final salt = _hasher.generateSalt();
    final hash = _hasher.hashPassword(senha.trim(), salt);

    await _repository.updateUserPassword(
      userId: userId,
      senhaHash: hash,
      senhaSalt: salt,
    );
    await _repository.markPasswordResetUsed((reset['id'] as num).toInt());
    await _repository.revokeSessionsByUserId(userId);
  }

  String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(48, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
