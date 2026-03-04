import 'dart:convert';

import 'package:apac_backend/src/modules/auth/services/auth_service.dart';
import 'package:shelf/shelf.dart';

class AuthController {
  AuthController(this._service);

  final AuthService _service;

  Future<Response> register(Request request) async {
    final roles = (request.context['auth_roles'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    if (!roles.contains('admin')) {
      return _json({'error': 'Acesso negado. Perfil admin obrigatorio.'}, status: 403);
    }

    final payload = await _readPayload(request);
    if (payload == null) return _json({'error': 'JSON invalido.'}, status: 400);

    final nome = (payload['nome'] ?? '').toString().trim();
    final email = (payload['email'] ?? '').toString().trim();
    final senha = (payload['senha'] ?? '').toString();
    final perfis = ((payload['perfis'] as List?) ?? const <dynamic>[])
        .map((e) => e.toString())
        .toList();

    if (nome.isEmpty || email.isEmpty || senha.length < 6) {
      return _json({'error': 'Informe nome, email e senha (min. 6).'}, status: 422);
    }

    try {
      final user = await _service.register(
        nome: nome,
        email: email,
        senha: senha,
        perfis: perfis.isEmpty ? const <String>['operador'] : perfis,
      );
      return _json({'data': user}, status: 201);
    } catch (error) {
      return _json({'error': error.toString().replaceFirst('Bad state: ', '')}, status: 422);
    }
  }

  Future<Response> login(Request request) async {
    final payload = await _readPayload(request);
    if (payload == null) return _json({'error': 'JSON invalido.'}, status: 400);

    final email = (payload['email'] ?? '').toString().trim();
    final senha = (payload['senha'] ?? '').toString();
    if (email.isEmpty || senha.isEmpty) {
      return _json({'error': 'Informe email e senha.'}, status: 422);
    }

    try {
      final session = await _service.login(email: email, senha: senha);
      return _json({'data': session});
    } catch (_) {
      return _json({'error': 'Credenciais invalidas.'}, status: 401);
    }
  }

  Future<Response> me(Request request) async {
    final user = request.context['auth_user'];
    if (user is! Map<String, dynamic>) {
      return _json({'error': 'Nao autenticado.'}, status: 401);
    }

    return _json({'data': user});
  }

  Future<Response> logout(Request request) async {
    final auth = request.headers['authorization'] ?? '';
    final token = auth.toLowerCase().startsWith('bearer ')
        ? auth.substring(7).trim()
        : '';

    if (token.isNotEmpty) {
      await _service.logout(token);
    }

    return _json({'message': 'Logout realizado com sucesso.'});
  }

  Future<Map<String, dynamic>?> _readPayload(Request request) async {
    final body = await request.readAsString();
    if (body.trim().isEmpty) return null;
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  }

  Response _json(Map<String, dynamic> payload, {int status = 200}) {
    return Response(
      status,
      body: jsonEncode(payload),
      headers: const {
        'content-type': 'application/json; charset=utf-8',
      },
    );
  }
}
