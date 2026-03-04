import 'dart:convert';

import 'package:apac_backend/src/modules/audit/services/audit_log_service.dart';
import 'package:shelf/shelf.dart';

class AuditLogController {
  AuditLogController(this._service);

  final AuditLogService _service;

  Future<Response> index(Request request) async {
    final roles = (request.context['auth_roles'] as List?)
            ?.map((e) => e.toString().trim().toLowerCase())
            .toSet() ??
        <String>{};
    if (!roles.contains('admin') && !roles.contains('gestor')) {
      return Response(
        403,
        body: jsonEncode({'error': 'Acesso negado para este perfil.'}),
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    }

    final entidade = request.url.queryParameters['entidade'];
    final acao = request.url.queryParameters['acao'];
    final usuarioId = int.tryParse(request.url.queryParameters['usuario_id'] ?? '');
    final limit = int.tryParse(request.url.queryParameters['limit'] ?? '') ?? 200;

    final data = await _service.list(
      entidade: entidade,
      acao: acao,
      usuarioId: usuarioId,
      limit: limit > 1000 ? 1000 : limit,
    );

    return Response.ok(
      jsonEncode({'data': data}),
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
