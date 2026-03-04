abstract class IAuthRepository {
  Future<Map<String, dynamic>?> getUserByEmail(String email);
  Future<Map<String, dynamic>?> getUserById(int id);
  Future<Map<String, dynamic>> createUser({
    required String nome,
    required String email,
    required String senhaHash,
    required String senhaSalt,
  });

  Future<Map<String, dynamic>> createSession({
    required int usuarioId,
    required String token,
    required DateTime expiresAt,
  });

  Future<Map<String, dynamic>?> getSessionWithUser(String token);
  Future<void> revokeSession(String token);
}
