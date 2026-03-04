abstract class IAuditLogRepository {
  Future<List<Map<String, dynamic>>> list({
    String? entidade,
    String? acao,
    int? usuarioId,
    int limit,
  });
}
