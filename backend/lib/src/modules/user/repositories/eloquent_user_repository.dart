import 'package:apac_backend/src/modules/user/repositories/user_repository.dart';
import 'package:eloquent/eloquent.dart';

class EloquentUserRepository implements IUserRepository {
  EloquentUserRepository(this._db);

  final Connection _db;

  @override
  Future<List<Map<String, dynamic>>> listAll() async {
    final rows = await _db
        .table('usuarios_v2')
        .select(['id', 'nome', 'email', 'ativo', 'created_at', 'updated_at'])
        .orderBy('id', 'asc')
        .get();

    final result = <Map<String, dynamic>>[];
    for (final row in (rows as List)) {
      final mapped = Map<String, dynamic>.from(row as Map);
      mapped['roles'] = await _rolesByUserId((mapped['id'] as num).toInt());
      result.add(mapped);
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>?> getById(int id) async {
    final rows = await _db
        .table('usuarios_v2')
        .select(['id', 'nome', 'email', 'ativo', 'created_at', 'updated_at'])
        .where('id', '=', id)
        .limit(1)
        .get();

    if ((rows as List).isEmpty) return null;
    final user = Map<String, dynamic>.from(rows.first as Map);
    user['roles'] = await _rolesByUserId(id);
    return user;
  }

  @override
  Future<Map<String, dynamic>?> getByEmail(String email) async {
    final rows = await _db
        .table('usuarios_v2')
        .select(['id', 'nome', 'email', 'ativo', 'created_at', 'updated_at'])
        .where('email', '=', email.toLowerCase().trim())
        .limit(1)
        .get();

    if ((rows as List).isEmpty) return null;
    final user = Map<String, dynamic>.from(rows.first as Map);
    user['roles'] = await _rolesByUserId((user['id'] as num).toInt());
    return user;
  }

  @override
  Future<Map<String, dynamic>> create({
    required String nome,
    required String email,
    String? senhaHash,
    String? senhaSalt,
    required bool ativo,
    required List<String> perfis,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final id = await _db.table('usuarios_v2').insertGetId({
      'nome': nome.trim(),
      'email': email.toLowerCase().trim(),
      'ativo': ativo,
      'created_at': now,
      'updated_at': now,
    }, 'id');

    final userId = (id as num).toInt();

    if (senhaHash != null && senhaSalt != null) {
      await _db.table('usuario_credenciais_v2').insert({
        'usuario_id': userId,
        'senha_hash': senhaHash,
        'senha_salt': senhaSalt,
        'created_at': now,
        'updated_at': now,
      });
    }

    await _syncRoles(userId, perfis, now);

    final user = await getById(userId);
    if (user == null) throw StateError('Falha ao carregar usuario criado');
    return user;
  }

  @override
  Future<Map<String, dynamic>?> update({
    required int id,
    String? nome,
    String? email,
    bool? ativo,
    String? senhaHash,
    String? senhaSalt,
    List<String>? perfis,
  }) async {
    final existing = await getById(id);
    if (existing == null) return null;

    final now = DateTime.now().toUtc().toIso8601String();

    final updates = <String, dynamic>{
      'updated_at': now,
    };

    if (nome != null) updates['nome'] = nome.trim();
    if (email != null) updates['email'] = email.toLowerCase().trim();
    if (ativo != null) updates['ativo'] = ativo;

    await _db.table('usuarios_v2').where('id', '=', id).update(updates);

    if (senhaHash != null && senhaSalt != null) {
      final credRows = await _db
          .table('usuario_credenciais_v2')
          .select(['usuario_id'])
          .where('usuario_id', '=', id)
          .limit(1)
          .get();

      if ((credRows as List).isEmpty) {
        await _db.table('usuario_credenciais_v2').insert({
          'usuario_id': id,
          'senha_hash': senhaHash,
          'senha_salt': senhaSalt,
          'created_at': now,
          'updated_at': now,
        });
      } else {
        await _db.table('usuario_credenciais_v2').where('usuario_id', '=', id).update({
          'senha_hash': senhaHash,
          'senha_salt': senhaSalt,
          'updated_at': now,
        });
      }
    }

    if (perfis != null) {
      await _syncRoles(id, perfis, now);
    }

    return getById(id);
  }

  @override
  Future<bool> deactivate(int id) async {
    final affected = await _db.table('usuarios_v2').where('id', '=', id).update({
      'ativo': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return affected > 0;
  }

  Future<List<String>> _rolesByUserId(int userId) async {
    final builder = _db.table('usuario_perfis_v2 as up').select([
      'p.codigo as codigo',
    ])
      ..join('perfis_v2 as p', 'p.id', '=', 'up.perfil_id')
      ..where('up.usuario_id', '=', userId);

    final rows = await builder.get();
    return (rows as List)
        .map((e) => ((e as Map)['codigo'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _syncRoles(int userId, List<String> roles, String now) async {
    final normalized = roles.map((r) => r.trim().toLowerCase()).where((r) => r.isNotEmpty).toSet();
    if (normalized.isEmpty) normalized.add('operador');

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
