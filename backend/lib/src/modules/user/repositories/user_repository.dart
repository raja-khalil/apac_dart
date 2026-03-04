abstract class IUserRepository {
  Future<List<Map<String, dynamic>>> listAll();
  Future<Map<String, dynamic>?> getById(int id);
  Future<Map<String, dynamic>?> getByEmail(String email);
  Future<Map<String, dynamic>> create({
    required String nome,
    required String email,
    String? senhaHash,
    String? senhaSalt,
    required bool ativo,
    required List<String> perfis,
  });
  Future<Map<String, dynamic>?> update({
    required int id,
    String? nome,
    String? email,
    bool? ativo,
    String? senhaHash,
    String? senhaSalt,
    List<String>? perfis,
  });
  Future<bool> deactivate(int id);
}
