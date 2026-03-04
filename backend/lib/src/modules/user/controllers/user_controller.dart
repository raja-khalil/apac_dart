import 'dart:convert';

import 'package:apac_backend/src/modules/user/services/user_service.dart';
import 'package:shelf/shelf.dart';

class UserController {
  UserController(this._service);

  final UserService _service;

  Future<Response> index(Request request) async {
    final denied = _forbiddenIfNotAdmin(request);
    if (denied != null) return denied;

    final users = await _service.listAll();
    return _json({'data': users});
  }

  Future<Response> store(Request request) async {
    final denied = _forbiddenIfNotAdmin(request);
    if (denied != null) return denied;

    final payload = await _readPayload(request);
    if (payload == null) return _json({'error': 'JSON invalido.'}, status: 400);

    final nome = (payload['nome'] ?? '').toString().trim();
    final email = (payload['email'] ?? '').toString().trim();
    final senha = (payload['senha'] ?? '').toString();
    final ativo = payload['ativo'] != false;
    final perfis = ((payload['perfis'] as List?) ?? const <dynamic>[])
        .map((e) => e.toString())
        .toList();

    if (nome.isEmpty || email.isEmpty || senha.length < 6) {
      return _json({'error': 'Campos obrigatorios: nome, email, senha >= 6.'}, status: 422);
    }

    try {
      final user = await _service.create(
        nome: nome,
        email: email,
        senha: senha,
        ativo: ativo,
        perfis: perfis,
      );
      return _json({'data': user}, status: 201);
    } catch (error) {
      return _json({'error': error.toString().replaceFirst('Bad state: ', '')}, status: 422);
    }
  }

  Future<Response> update(Request request, String id) async {
    final denied = _forbiddenIfNotAdmin(request);
    if (denied != null) return denied;

    final parsedId = int.tryParse(id);
    if (parsedId == null) return _json({'error': 'ID invalido.'}, status: 400);

    final payload = await _readPayload(request);
    if (payload == null) return _json({'error': 'JSON invalido.'}, status: 400);

    final nome = payload['nome']?.toString();
    final email = payload['email']?.toString();
    final senha = payload['senha']?.toString();
    final ativo = payload.containsKey('ativo') ? payload['ativo'] == true : null;
    final perfis = payload.containsKey('perfis')
        ? ((payload['perfis'] as List?) ?? const <dynamic>[])
            .map((e) => e.toString())
            .toList()
        : null;

    final user = await _service.update(
      id: parsedId,
      nome: nome,
      email: email,
      senha: senha,
      ativo: ativo,
      perfis: perfis,
    );

    if (user == null) return _json({'error': 'Usuario nao encontrado.'}, status: 404);
    return _json({'data': user});
  }

  Future<Response> destroy(Request request, String id) async {
    final denied = _forbiddenIfNotAdmin(request);
    if (denied != null) return denied;

    final parsedId = int.tryParse(id);
    if (parsedId == null) return _json({'error': 'ID invalido.'}, status: 400);

    final ok = await _service.deactivate(parsedId);
    if (!ok) return _json({'error': 'Usuario nao encontrado.'}, status: 404);

    return _json({'message': 'Usuario desativado.'});
  }

  Response? _forbiddenIfNotAdmin(Request request) {
    final roles = (request.context['auth_roles'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    if (!roles.contains('admin')) {
      return _json({'error': 'Acesso negado. Perfil admin obrigatorio.'}, status: 403);
    }
    return null;
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
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
