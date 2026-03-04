import 'package:apac_backend/src/modules/audit/repositories/audit_log_repository.dart';
import 'package:eloquent/eloquent.dart';

class EloquentAuditLogRepository implements IAuditLogRepository {
  EloquentAuditLogRepository(this._db);

  final Connection _db;

  @override
  Future<List<Map<String, dynamic>>> list({
    String? entidade,
    String? acao,
    int? usuarioId,
    int limit = 200,
  }) async {
    dynamic builder = _db.table('audit_logs_v2 as a').select([
      'a.id as id',
      'a.usuario_id as usuario_id',
      'u.nome as usuario_nome',
      'u.email as usuario_email',
      'a.acao as acao',
      'a.entidade as entidade',
      'a.entidade_id as entidade_id',
      'a.dados_antes as dados_antes',
      'a.dados_depois as dados_depois',
      'a.ip_origem as ip_origem',
      'a.created_at as created_at',
    ])
      ..leftJoin('usuarios_v2 as u', 'u.id', '=', 'a.usuario_id');

    if (entidade != null && entidade.trim().isNotEmpty) {
      builder = builder.where('a.entidade', '=', entidade.trim());
    }
    if (acao != null && acao.trim().isNotEmpty) {
      builder = builder.where('a.acao', '=', acao.trim());
    }
    if (usuarioId != null) {
      builder = builder.where('a.usuario_id', '=', usuarioId);
    }

    final rows = await builder.orderBy('a.id', 'desc').limit(limit).get();
    return (rows as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
