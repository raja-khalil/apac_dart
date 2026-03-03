import 'dart:convert';

import 'package:apac_backend/src/modules/laudo/repositories/laudo_repository.dart';
import 'package:shelf/shelf.dart';

class LaudoController {
  LaudoController(this._repository);

  final LaudoRepository _repository;

  Future<Response> index(Request request) async {
    final query = request.url.queryParameters['q'];
    final status = request.url.queryParameters['status'];
    final unidade = request.url.queryParameters['unidade_cnes'];

    final laudos = await _repository.listAll(
      query: query,
      status: status,
      unidadeCnes: unidade,
    );

    return _json({'data': laudos});
  }

  Future<Response> show(Request request, String id) async {
    final parsedId = int.tryParse(id);
    if (parsedId == null) {
      return _json({'error': 'ID invalido.'}, status: 400);
    }

    final laudo = await _repository.getById(parsedId);
    if (laudo == null) {
      return _json({'error': 'Laudo nao encontrado.'}, status: 404);
    }

    return _json({'data': laudo});
  }

  Future<Response> store(Request request) async {
    final payload = await _readPayload(request);
    if (payload == null) {
      return _json({'error': 'JSON invalido.'}, status: 400);
    }

    final validationError = _validatePayload(payload);
    if (validationError != null) {
      return _json({'error': validationError}, status: 422);
    }

    final created = await _repository.create(payload);
    return _json({'data': created}, status: 201);
  }

  Future<Response> update(Request request, String id) async {
    final parsedId = int.tryParse(id);
    if (parsedId == null) {
      return _json({'error': 'ID invalido.'}, status: 400);
    }

    final payload = await _readPayload(request);
    if (payload == null) {
      return _json({'error': 'JSON invalido.'}, status: 400);
    }

    final validationError = _validatePayload(payload);
    if (validationError != null) {
      return _json({'error': validationError}, status: 422);
    }

    final updated = await _repository.update(parsedId, payload);
    if (updated == null) {
      return _json({'error': 'Laudo nao encontrado.'}, status: 404);
    }

    return _json({'data': updated});
  }

  Future<Response> destroy(Request request, String id) async {
    final parsedId = int.tryParse(id);
    if (parsedId == null) {
      return _json({'error': 'ID invalido.'}, status: 400);
    }

    final deleted = await _repository.delete(parsedId);
    if (!deleted) {
      return _json({'error': 'Laudo nao encontrado.'}, status: 404);
    }

    return _json({'message': 'Laudo removido com sucesso.'});
  }

  Future<Map<String, dynamic>?> _readPayload(Request request) async {
    final body = await request.readAsString();
    if (body.trim().isEmpty) return null;
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  }

  String? _validatePayload(Map<String, dynamic> payload) {
    final paciente = Map<String, dynamic>.from(
      (payload['paciente'] as Map?) ?? <String, dynamic>{},
    );

    final nomePaciente = (payload['nome_paciente'] ?? paciente['nome'] ?? '')
        .toString()
        .trim();
    final cpf = (payload['cpf'] ?? paciente['cpf'] ?? '').toString().trim();
    final dataNascimento =
        (payload['data_nascimento'] ?? paciente['data_nascimento'] ?? '')
            .toString()
            .trim();

    if (nomePaciente.isEmpty || cpf.isEmpty || dataNascimento.isEmpty) {
      return 'Campos obrigatorios: nome_paciente, cpf, data_nascimento.';
    }

    return null;
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
