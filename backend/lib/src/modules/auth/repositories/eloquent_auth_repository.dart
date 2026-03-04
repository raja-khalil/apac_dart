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
          'ativo',
          'created_at',
          'updated_at',
        ])
        .where('email', '=', email.toLowerCase().trim())
        .limit(1)
        .get();

    if ((rows as List).isEmpty) return null;
    final user = Map<String, dynamic>.from(rows.first as Map);

    final credRows = await _db
        .table('usuario_credenciais_v2')
        .select(['senha_hash', 'senha_salt'])
        .where('usuario_id', '=', (user['id'] as num).toInt())
        .limit(1)
        .get();

    if ((credRows as List).isEmpty) return null;
    user['senha_hash'] = (credRows.first as Map)['senha_hash'];
    user['senha_salt'] = (credRows.first as Map)['senha_salt'];
    user['roles'] = await getUserRoles((user['id'] as num).toInt());

    return user;
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
    final user = Map<String, dynamic>.from(rows.first as Map);
    user['roles'] = await getUserRoles(id);
    return user;
  }

  @override
  Future<bool> hasAnyUser() async {
    final rows = await _db.table('usuarios_v2').select(['id']).limit(1).get();
    return (rows as List).isNotEmpty;
  }

  @override
  Future<Map<String, dynamic>> createUser({
    required String nome,
    required String email,
    required String senhaHash,
    required String senhaSalt,
    required List<String> perfis,
    bool ativo = true,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final id = await _db.table('usuarios_v2').insertGetId({
      'nome': nome,
      'email': email.toLowerCase().trim(),
      'ativo': ativo,
      'created_at': now,
      'updated_at': now,
    }, 'id');

    final userId = (id as num).toInt();

    await _db.table('usuario_credenciais_v2').insert({
      'usuario_id': userId,
      'senha_hash': senhaHash,
      'senha_salt': senhaSalt,
      'created_at': now,
      'updated_at': now,
    });

    await _syncRoles(userId, perfis, now);

    final user = await getUserById(userId);
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

    final session = Map<String, dynamic>.from(result.first as Map);
    session['roles'] = await getUserRoles((session['id'] as num).toInt());
    return session;
  }

  @override
  Future<void> revokeSession(String token) async {
    await _db.table('sessoes_v2').where('token', '=', token).update({
      'revoked_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<List<String>> getUserRoles(int userId) async {
    final rows = await _db.table('usuario_perfis_v2 as up').select([
      'p.codigo as codigo',
    ])
      ..join('perfis_v2 as p', 'p.id', '=', 'up.perfil_id')
      ..where('up.usuario_id', '=', userId);

    final result = await rows.get();
    return (result as List)
        .map((e) => ((e as Map)['codigo'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _syncRoles(int userId, List<String> roles, String now) async {
    final normalized = roles.map((r) => r.trim().toLowerCase()).where((r) => r.isNotEmpty).toSet();
    if (normalized.isEmpty) {
      normalized.add('operador');
    }

    await _db.table('usuario_perfis_v2').where('usuario_id', '=', userId).delete();

    for (final role in normalized) {
      final perfilRows = await _db
          .table('perfis_v2')
          .select(['id'])
          .where('codigo', '=', role)
          .limit(1)
          .get();

      if ((perfilRows as List).isEmpty) continue;
      final perfilId = ((perfilRows.first as Map)['id'] as num).toInt();
      await _db.table('usuario_perfis_v2').insert({
        'usuario_id': userId,
        'perfil_id': perfilId,
        'created_at': now,
      });
    }
  }
}
