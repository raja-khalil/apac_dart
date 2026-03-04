import 'dart:convert';

import 'package:apac_backend/src/modules/catalog/services/catalog_service.dart';
import 'package:shelf/shelf.dart';

class CatalogController {
  CatalogController(this._service);

  final CatalogService _service;

  String _normalizeCnes(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 7) return digits.substring(0, 7);
    return digits;
  }

  String _normalizeSigtap(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final truncated = digits.length > 10 ? digits.substring(0, 10) : digits;
    if (truncated.length <= 2) return truncated;
    if (truncated.length <= 4) {
      return '${truncated.substring(0, 2)}.${truncated.substring(2)}';
    }
    if (truncated.length <= 6) {
      return '${truncated.substring(0, 2)}.${truncated.substring(2, 4)}.${truncated.substring(4)}';
    }
    if (truncated.length <= 9) {
      return '${truncated.substring(0, 2)}.${truncated.substring(2, 4)}.${truncated.substring(4, 6)}.${truncated.substring(6)}';
    }
    return '${truncated.substring(0, 2)}.${truncated.substring(2, 4)}.${truncated.substring(4, 6)}.${truncated.substring(6, 9)}-${truncated.substring(9)}';
  }

  Future<Response> listEstabelecimentos(Request request) async {
    final tipo = request.url.queryParameters['tipo'];
    final includeInativos =
        (request.url.queryParameters['include_inativos'] ?? '').toLowerCase() ==
            'true';
    final data = await _service.listEstabelecimentos(
      tipo: tipo,
      includeInativos: includeInativos,
    );
    return _json({'data': data});
  }

  Future<Response> createEstabelecimento(Request request) async {
    final denied = _forbiddenIfNotAdmin(request);
    if (denied != null) return denied;

    final payload = await _readPayload(request);
    if (payload == null) return _json({'error': 'JSON invalido.'}, status: 400);
    final nome = (payload['nome'] ?? '').toString().trim();
    final cnes = _normalizeCnes((payload['cnes'] ?? '').toString().trim());
    final tipo = (payload['tipo'] ?? '').toString().trim().toLowerCase();
    if (nome.isEmpty || tipo.isEmpty) {
      return _json({'error': 'Campos obrigatorios: nome e tipo.'}, status: 422);
    }
    if (!const {'solicitante', 'executante', 'ambos'}.contains(tipo)) {
      return _json({'error': 'Tipo invalido.'}, status: 422);
    }
    if (cnes.isNotEmpty && cnes.length != 7) {
      return _json({'error': 'CNES deve conter 7 digitos.'}, status: 422);
    }
    try {
      final item = await _service.createEstabelecimento(
          nome: nome, cnes: cnes, tipo: tipo);
      return _json({'data': item}, status: 201);
    } catch (error) {
      return _json({'error': error.toString().replaceFirst('Bad state: ', '')},
          status: 422);
    }
  }

  Future<Response> deleteEstabelecimento(Request request, String id) async {
    final denied = _forbiddenIfNotAdmin(request);
    if (denied != null) return denied;
    final parsedId = int.tryParse(id);
    if (parsedId == null) return _json({'error': 'ID invalido.'}, status: 400);
    final ok = await _service.deleteEstabelecimento(parsedId);
    if (!ok) return _json({'error': 'Nao encontrado.'}, status: 404);
    return _json({'message': 'Removido com sucesso.'});
  }

  Future<Response> updateEstabelecimento(Request request, String id) async {
    final denied = _forbiddenIfNotAdmin(request);
    if (denied != null) return denied;
    final parsedId = int.tryParse(id);
    if (parsedId == null) return _json({'error': 'ID invalido.'}, status: 400);
    final payload = await _readPayload(request);
    if (payload == null) return _json({'error': 'JSON invalido.'}, status: 400);
    final item = await _service.updateEstabelecimento(
      id: parsedId,
      nome: payload['nome']?.toString(),
      cnes: payload['cnes'] != null
          ? _normalizeCnes(payload['cnes'].toString())
          : null,
      tipo: payload['tipo']?.toString(),
    );
    if (item == null) return _json({'error': 'Nao encontrado.'}, status: 404);
    return _json({'data': item});
  }

  Future<Response> setEstabelecimentoStatus(
    Request request,
    String id,
  ) async {
    final denied = _forbiddenIfNotAdmin(request);
    if (denied != null) return denied;
    final parsedId = int.tryParse(id);
    if (parsedId == null) return _json({'error': 'ID invalido.'}, status: 400);
    final payload = await _readPayload(request);
    if (payload == null) return _json({'error': 'JSON invalido.'}, status: 400);
    final ativo = payload['ativo'] == true;
    final ok = await _service.setEstabelecimentoAtivo(parsedId, ativo);
    if (!ok) return _json({'error': 'Nao encontrado.'}, status: 404);
    return _json({'message': ativo ? 'Ativado.' : 'Desativado.'});
  }

  Future<Response> listPrincipais(Request request) async {
    final includeInativos =
        (request.url.queryParameters['include_inativos'] ?? '').toLowerCase() ==
            'true';
    final data =
        await _service.listPrincipais(includeInativos: includeInativos);
    return _json({'data': data});
  }

  Future<Response> listSecundarios(Request request) async {
    final includeInativos =
        (request.url.queryParameters['include_inativos'] ?? '').toLowerCase() ==
            'true';
    final data =
        await _service.listSecundarios(includeInativos: includeInativos);
    return _json({'data': data});
  }

  Future<Response> createSecundario(Request request) async {
    final denied = _forbiddenIfNotAdmin(request);
    if (denied != null) return denied;
    final payload = await _readPayload(request);
    if (payload == null) return _json({'error': 'JSON invalido.'}, status: 400);
    final codigo =
        _normalizeSigtap((payload['codigo_sigtap'] ?? '').toString().trim());
    final descricao = (payload['descricao'] ?? '').toString().trim();
    if (codigo.isEmpty || descricao.isEmpty) {
      return _json({'error': 'Campos obrigatorios: codigo_sigtap e descricao.'},
          status: 422);
    }
    if (codigo.length != 14) {
      return _json(
          {'error': 'Codigo SIGTAP invalido. Use formato 00.00.00.000-0.'},
          status: 422);
    }
    try {
      final item = await _service.createProcedimentoSecundario(
        codigoSigtap: codigo,
        descricao: descricao,
      );
      return _json({'data': item}, status: 201);
    } catch (error) {
      return _json({'error': error.toString().replaceFirst('Bad state: ', '')},
          status: 422);
    }
  }

  Future<Response> createPrincipal(Request request) async {
    final denied = _forbiddenIfNotAdmin(request);
    if (denied != null) return denied;
    final payload = await _readPayload(request);
    if (payload == null) return _json({'error': 'JSON invalido.'}, status: 400);
    final codigo =
        _normalizeSigtap((payload['codigo_sigtap'] ?? '').toString().trim());
    final descricao = (payload['descricao'] ?? '').toString().trim();
    final secundariosIds =
        ((payload['secundarios_ids'] as List?) ?? const <dynamic>[])
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0)
            .toList();
    if (codigo.isEmpty || descricao.isEmpty) {
      return _json({'error': 'Campos obrigatorios: codigo_sigtap e descricao.'},
          status: 422);
    }
    if (codigo.length != 14) {
      return _json(
          {'error': 'Codigo SIGTAP invalido. Use formato 00.00.00.000-0.'},
          status: 422);
    }
    try {
      final item = await _service.createProcedimentoPrincipal(
        codigoSigtap: codigo,
        descricao: descricao,
        secundariosIds: secundariosIds,
      );
      return _json({'data': item}, status: 201);
    } catch (error) {
      return _json({'error': error.toString().replaceFirst('Bad state: ', '')},
          status: 422);
    }
  }

  Future<Response> deleteProcedimento(Request request, String id) async {
    final denied = _forbiddenIfNotAdmin(request);
    if (denied != null) return denied;
    final parsedId = int.tryParse(id);
    if (parsedId == null) return _json({'error': 'ID invalido.'}, status: 400);
    final ok = await _service.deleteProcedimento(parsedId);
    if (!ok) return _json({'error': 'Nao encontrado.'}, status: 404);
    return _json({'message': 'Removido com sucesso.'});
  }

  Future<Response> updateProcedimento(Request request, String id) async {
    final denied = _forbiddenIfNotAdmin(request);
    if (denied != null) return denied;
    final parsedId = int.tryParse(id);
    if (parsedId == null) return _json({'error': 'ID invalido.'}, status: 400);
    final payload = await _readPayload(request);
    if (payload == null) return _json({'error': 'JSON invalido.'}, status: 400);
    final secundariosIds = payload.containsKey('secundarios_ids')
        ? ((payload['secundarios_ids'] as List?) ?? const <dynamic>[])
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0)
            .toList()
        : null;
    final item = await _service.updateProcedimento(
      id: parsedId,
      codigoSigtap: payload['codigo_sigtap'] != null
          ? _normalizeSigtap(payload['codigo_sigtap'].toString())
          : null,
      descricao: payload['descricao']?.toString(),
      secundariosIds: secundariosIds,
    );
    if (item == null) return _json({'error': 'Nao encontrado.'}, status: 404);
    return _json({'data': item});
  }

  Future<Response> setProcedimentoStatus(Request request, String id) async {
    final denied = _forbiddenIfNotAdmin(request);
    if (denied != null) return denied;
    final parsedId = int.tryParse(id);
    if (parsedId == null) return _json({'error': 'ID invalido.'}, status: 400);
    final payload = await _readPayload(request);
    if (payload == null) return _json({'error': 'JSON invalido.'}, status: 400);
    final ativo = payload['ativo'] == true;
    final ok = await _service.setProcedimentoAtivo(parsedId, ativo);
    if (!ok) return _json({'error': 'Nao encontrado.'}, status: 404);
    return _json({'message': ativo ? 'Ativado.' : 'Desativado.'});
  }

  Future<Response> setSecundarioPrincipais(Request request, String id) async {
    final denied = _forbiddenIfNotAdmin(request);
    if (denied != null) return denied;
    final parsedId = int.tryParse(id);
    if (parsedId == null) return _json({'error': 'ID invalido.'}, status: 400);
    final payload = await _readPayload(request);
    if (payload == null) return _json({'error': 'JSON invalido.'}, status: 400);
    final principaisIds =
        ((payload['principais_ids'] as List?) ?? const <dynamic>[])
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0)
            .toList();
    final ok = await _service.setSecundarioPrincipais(parsedId, principaisIds);
    if (!ok)
      return _json({'error': 'Procedimento secundario nao encontrado.'},
          status: 404);
    return _json({'message': 'Associacoes atualizadas com sucesso.'});
  }

  Response? _forbiddenIfNotAdmin(Request request) {
    final roles = (request.context['auth_roles'] as List?)
            ?.map((e) => e.toString().trim().toLowerCase())
            .toList() ??
        <String>[];
    if (!roles.contains('admin')) {
      return _json({'error': 'Acesso negado. Perfil admin obrigatorio.'},
          status: 403);
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
      body: jsonEncode(
        payload,
        toEncodable: (value) {
          if (value is DateTime) return value.toIso8601String();
          return value.toString();
        },
      ),
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
