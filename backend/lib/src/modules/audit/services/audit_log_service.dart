import 'package:apac_backend/src/modules/audit/repositories/audit_log_repository.dart';

class AuditLogService {
  AuditLogService(this._repository);

  final IAuditLogRepository _repository;

  Future<List<Map<String, dynamic>>> list({
    String? entidade,
    String? acao,
    int? usuarioId,
    int limit = 200,
  }) {
    return _repository.list(
      entidade: entidade,
      acao: acao,
      usuarioId: usuarioId,
      limit: limit,
    );
  }
}
