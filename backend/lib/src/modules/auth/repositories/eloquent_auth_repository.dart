import 'package:apac_backend/src/modules/auth/repositories/auth_repository.dart';
import 'package:eloquent/eloquent.dart';

class EloquentAuthRepository implements IAuthRepository {
  EloquentAuthRepository(this._db);

  final Connection _db;

  @override
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final rows = await _db
        .table('usuarios_v2')
        .select([
          'id',
          'nome',
          'email',
          'senha_hash',
          'senha_salt',
          'ativo',
          'created_at',
          'updated_at',
        ])
        .where('email', '=', email.toLowerCase().trim())
        .limit(1)
        .get();

    if ((rows as List).isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  @override
  Future<Map<String, dynamic>?> getUserById(int id) async {
    final rows = await _db
        .table('usuarios_v2')
        .select([
          'id',
          'nome',
          'email',
          'ativo',
          'created_at',
          'updated_at',
        ])
        .where('id', '=', id)
        .limit(1)
        .get();

    if ((rows as List).isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  @override
  Future<Map<String, dynamic>> createUser({
    required String nome,
    required String email,
    required String senhaHash,
    required String senhaSalt,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final id = await _db.table('usuarios_v2').insertGetId({
      'nome': nome,
      'email': email.toLowerCase().trim(),
      'senha_hash': senhaHash,
      'senha_salt': senhaSalt,
      'ativo': true,
      'created_at': now,
      'updated_at': now,
    }, 'id');

    final user = await getUserById((id as num).toInt());
    if (user == null) throw StateError('Falha ao carregar usuario criado');
    return user;
  }

  @override
  Future<Map<String, dynamic>> createSession({
    required int usuarioId,
    required String token,
    required DateTime expiresAt,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final id = await _db.table('sessoes_v2').insertGetId({
      'usuario_id': usuarioId,
      'token': token,
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'created_at': now,
      'revoked_at': null,
    }, 'id');

    final rows = await _db
        .table('sessoes_v2')
        .select(['id', 'usuario_id', 'token', 'expires_at', 'created_at', 'revoked_at'])
        .where('id', '=', (id as num).toInt())
        .limit(1)
        .get();

    return Map<String, dynamic>.from((rows as List).first as Map);
  }

  @override
  Future<Map<String, dynamic>?> getSessionWithUser(String token) async {
    final builder = _db.table('sessoes_v2 as s').select([
      's.id as session_id',
      's.usuario_id as usuario_id',
      's.token as token',
      's.expires_at as expires_at',
      's.revoked_at as revoked_at',
      'u.id as id',
      'u.nome as nome',
      'u.email as email',
      'u.ativo as ativo',
    ])
      ..join('usuarios_v2 as u', 'u.id', '=', 's.usuario_id')
      ..where('s.token', '=', token)
      ..limit(1);

    final result = await builder.get();
    if ((result as List).isEmpty) return null;
    return Map<String, dynamic>.from(result.first as Map);
  }

  @override
  Future<void> revokeSession(String token) async {
    await _db.table('sessoes_v2').where('token', '=', token).update({
      'revoked_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
