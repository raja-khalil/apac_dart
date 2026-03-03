abstract class ILaudoRepository {
  Future<List<Map<String, dynamic>>> listAll({
    String? query,
    String? status,
    String? unidadeCnes,
  });

  Future<Map<String, dynamic>?> getById(int id);

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload);

  Future<Map<String, dynamic>?> update(int id, Map<String, dynamic> payload);

  Future<bool> delete(int id);
}
