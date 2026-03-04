import 'package:apac_backend/src/modules/auth/services/password_hasher.dart';
import 'package:apac_backend/src/modules/user/repositories/user_repository.dart';

class UserService {
  UserService(this._repository, this._passwordHasher);

  final IUserRepository _repository;
  final PasswordHasher _passwordHasher;

  Future<List<Map<String, dynamic>>> listAll() {
    return _repository.listAll();
  }

  Future<Map<String, dynamic>> create({
    required String nome,
    required String email,
    String? senha,
    required bool ativo,
    required List<String> perfis,
  }) async {
    final normalizedEmail = email.toLowerCase().trim();
    final existing = await _repository.getByEmail(normalizedEmail);
    if (existing != null) {
      throw StateError('Ja existe usuario com esse email.');
    }

    String? salt;
    String? hash;
    final senhaNormalizada = senha?.trim() ?? '';
    if (senhaNormalizada.isNotEmpty) {
      salt = _passwordHasher.generateSalt();
      hash = _passwordHasher.hashPassword(senhaNormalizada, salt);
    }

    return _repository.create(
      nome: nome,
      email: normalizedEmail,
      senhaHash: hash,
      senhaSalt: salt,
      ativo: ativo,
      perfis: perfis,
    );
  }

  Future<Map<String, dynamic>?> update({
    required int id,
    String? nome,
    String? email,
    bool? ativo,
    String? senha,
    List<String>? perfis,
  }) async {
    if (email != null) {
      final existing = await _repository.getByEmail(email.toLowerCase().trim());
      if (existing != null && ((existing['id'] as num).toInt() != id)) {
        throw StateError('Ja existe usuario com esse email.');
      }
    }

    String? senhaHash;
    String? senhaSalt;

    if (senha != null && senha.trim().isNotEmpty) {
      senhaSalt = _passwordHasher.generateSalt();
      senhaHash = _passwordHasher.hashPassword(senha, senhaSalt);
    }

    return _repository.update(
      id: id,
      nome: nome,
      email: email,
      ativo: ativo,
      senhaHash: senhaHash,
      senhaSalt: senhaSalt,
      perfis: perfis,
    );
  }

  Future<bool> deactivate(int id) {
    return _repository.deactivate(id);
  }
}
