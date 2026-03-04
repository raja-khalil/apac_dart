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
    required String senha,
    required bool ativo,
    required List<String> perfis,
  }) async {
    final salt = _passwordHasher.generateSalt();
    final hash = _passwordHasher.hashPassword(senha, salt);

    return _repository.create(
      nome: nome,
      email: email,
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
