abstract class ILaudoRepository {
  Future<List<Map<String, dynamic>>> listAll({
    String? query,
    String? status,
    String? unidadeCnes,
  });

  Future<Map<String, dynamic>?> getById(int id);

  Future<Map<String, dynamic>> create(
    Map<String, dynamic> payload, {
    int? actorUserId,
    String? actorIp,
  });

  Future<Map<String, dynamic>?> update(
    int id,
    Map<String, dynamic> payload, {
    int? actorUserId,
    String? actorIp,
  });

  Future<bool> delete(
    int id, {
    int? actorUserId,
    String? actorIp,
  });
}
