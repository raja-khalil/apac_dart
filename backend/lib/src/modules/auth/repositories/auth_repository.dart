abstract class IAuthRepository {
  Future<Map<String, dynamic>?> getUserByEmail(String email);
  Future<Map<String, dynamic>?> getUserById(int id);
  Future<bool> hasAnyUser();
  Future<Map<String, dynamic>> createUser({
    required String nome,
    required String email,
    required String senhaHash,
    required String senhaSalt,
    required List<String> perfis,
    bool ativo = true,
  });

  Future<Map<String, dynamic>> createSession({
    required int usuarioId,
    required String token,
    required DateTime expiresAt,
  });

  Future<Map<String, dynamic>?> getSessionWithUser(String token);
  Future<void> revokeSession(String token);

  Future<List<String>> getUserRoles(int userId);
}
