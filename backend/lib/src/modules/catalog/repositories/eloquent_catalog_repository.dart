import 'package:apac_backend/src/modules/catalog/repositories/catalog_repository.dart';
import 'package:eloquent/eloquent.dart';

class EloquentCatalogRepository implements ICatalogRepository {
  EloquentCatalogRepository(this._db);

  final Connection _db;

  String _normalizeCnes(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 7) return digits.substring(0, 7);
    return digits;
  }

  String _normalizeSigtap(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final truncated = digits.length > 10 ? digits.substring(0, 10) : digits;
    if (truncated.length <= 2) return truncated;
    if (truncated.length <= 4) {
      return '${truncated.substring(0, 2)}.${truncated.substring(2)}';
    }
    if (truncated.length <= 6) {
      return '${truncated.substring(0, 2)}.${truncated.substring(2, 4)}.${truncated.substring(4)}';
    }
    if (truncated.length <= 9) {
      return '${truncated.substring(0, 2)}.${truncated.substring(2, 4)}.${truncated.substring(4, 6)}.${truncated.substring(6)}';
    }
    return '${truncated.substring(0, 2)}.${truncated.substring(2, 4)}.${truncated.substring(4, 6)}.${truncated.substring(6, 9)}-${truncated.substring(9)}';
  }

  @override
  Future<List<Map<String, dynamic>>> listCategoriasProcedimentoPrincipal({
    bool includeInativos = false,
  }) async {
    dynamic q = _db.table('procedimento_categorias_v2').select([
      'id',
      'nome',
      'ativo',
      'created_at',
      'updated_at',
    ]);
    if (!includeInativos) {
      q = q.where('ativo', '=', true);
    }
    final rows = await q.orderBy('nome', 'asc').get();
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Future<Map<String, dynamic>> createCategoriaProcedimentoPrincipal(
      String nome) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final id = await _db.table('procedimento_categorias_v2').insertGetId({
      'nome': nome.trim(),
      'ativo': true,
      'created_at': now,
      'updated_at': now,
    }, 'id');
    final rows = await _db
        .table('procedimento_categorias_v2')
        .select(['id', 'nome', 'ativo', 'created_at', 'updated_at'])
        .where('id', '=', (id as num).toInt())
        .limit(1)
        .get();
    return Map<String, dynamic>.from((rows as List).first as Map);
  }

  @override
  Future<Map<String, dynamic>?> updateCategoriaProcedimentoPrincipal({
    required int id,
    required String nome,
  }) async {
    final exists = await _db
        .table('procedimento_categorias_v2')
        .select(['id'])
        .where('id', '=', id)
        .limit(1)
        .get();
    if ((exists as List).isEmpty) return null;
    await _db.table('procedimento_categorias_v2').where('id', '=', id).update({
      'nome': nome.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    final rows = await _db
        .table('procedimento_categorias_v2')
        .select(['id', 'nome', 'ativo', 'created_at', 'updated_at'])
        .where('id', '=', id)
        .limit(1)
        .get();
    return Map<String, dynamic>.from((rows as List).first as Map);
  }

  @override
  Future<bool> deleteCategoriaProcedimentoPrincipal(int id) async {
    final affected =
        await _db.table('procedimento_categorias_v2').where('id', '=', id).delete();
    return affected > 0;
  }

  @override
  Future<List<Map<String, dynamic>>> listEstabelecimentos({
    String? tipo,
    bool includeInativos = false,
  }) async {
    dynamic q = _db.table('estabelecimentos_v2').select([
      'id',
      'nome',
      'cnes',
      'tipo',
      'ativo',
      'created_at',
      'updated_at',
    ]);
    if (!includeInativos) {
      q = q.where('ativo', '=', true);
    }
    final normalizedTipo = (tipo ?? '').trim().toLowerCase();
    if (normalizedTipo == 'solicitante') {
      q = q.whereRaw("tipo IN ('solicitante','ambos')");
    } else if (normalizedTipo == 'executante') {
      q = q.whereRaw("tipo IN ('executante','ambos')");
    } else if (normalizedTipo.isNotEmpty) {
      q = q.where('tipo', '=', normalizedTipo);
    }
    final rows = await q.orderBy('nome', 'asc').get();
    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> createEstabelecimento({
    required String nome,
    required String cnes,
    required String tipo,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final id = await _db.table('estabelecimentos_v2').insertGetId({
      'nome': nome.trim(),
      'cnes': _normalizeCnes(cnes.trim()),
      'tipo': tipo.trim().toLowerCase(),
      'ativo': true,
      'created_at': now,
      'updated_at': now,
    }, 'id');
    final rows = await _db
        .table('estabelecimentos_v2')
        .select(
            ['id', 'nome', 'cnes', 'tipo', 'ativo', 'created_at', 'updated_at'])
        .where('id', '=', (id as num).toInt())
        .limit(1)
        .get();
    return Map<String, dynamic>.from((rows as List).first as Map);
  }

  @override
  Future<Map<String, dynamic>?> updateEstabelecimento({
    required int id,
    String? nome,
    String? cnes,
    String? tipo,
  }) async {
    final exists = await _db
        .table('estabelecimentos_v2')
        .select(['id'])
        .where('id', '=', id)
        .limit(1)
        .get();
    if ((exists as List).isEmpty) return null;

    final now = DateTime.now().toUtc().toIso8601String();
    final updates = <String, dynamic>{'updated_at': now};
    if (nome != null) updates['nome'] = nome.trim();
    if (cnes != null) updates['cnes'] = _normalizeCnes(cnes.trim());
    if (tipo != null) updates['tipo'] = tipo.trim().toLowerCase();
    await _db.table('estabelecimentos_v2').where('id', '=', id).update(updates);

    final rows = await _db
        .table('estabelecimentos_v2')
        .select(
            ['id', 'nome', 'cnes', 'tipo', 'ativo', 'created_at', 'updated_at'])
        .where('id', '=', id)
        .limit(1)
        .get();
    return Map<String, dynamic>.from((rows as List).first as Map);
  }

  @override
  Future<bool> setEstabelecimentoAtivo(int id, bool ativo) async {
    final affected =
        await _db.table('estabelecimentos_v2').where('id', '=', id).update({
      'ativo': ativo,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return affected > 0;
  }

  @override
  Future<bool> deleteEstabelecimento(int id) async {
    final affected =
        await _db.table('estabelecimentos_v2').where('id', '=', id).delete();
    return affected > 0;
  }

  @override
  Future<List<Map<String, dynamic>>> listPrincipais(
      {bool includeInativos = false}) async {
    dynamic query = _db
        .table('procedimentos_v2')
        .select([
          'id',
          'codigo_sigtap',
          'descricao',
          'categoria',
          'tipo',
          'ativo',
          'created_at',
          'updated_at',
        ])
        .where('tipo', '=', 'principal')
        .orderBy('descricao', 'asc');
    if (!includeInativos) {
      query = query.where('ativo', '=', true);
    }
    final principais = await query.get();

    final result = <Map<String, dynamic>>[];
    for (final raw in (principais as List)) {
      final row = Map<String, dynamic>.from(raw as Map);
      final pid = (row['id'] as num).toInt();
      final linksQ =
          _db.table('procedimento_principal_secundario_v2 as rel').select([
        's.id as id',
        's.codigo_sigtap as codigo_sigtap',
        's.descricao as descricao',
      ])
            ..join('procedimentos_v2 as s', 's.id', '=', 'rel.secundario_id')
            ..where('rel.principal_id', '=', pid)
            ..where('s.ativo', '=', true)
            ..orderBy('s.descricao', 'asc');
      final links = await linksQ.get();
      row['secundarios'] = (links as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      result.add(row);
    }
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> listSecundarios(
      {bool includeInativos = false}) async {
    dynamic query = _db
        .table('procedimentos_v2')
        .select([
          'id',
          'codigo_sigtap',
          'descricao',
          'tipo',
          'ativo',
          'created_at',
          'updated_at',
        ])
        .where('tipo', '=', 'secundario')
        .orderBy('descricao', 'asc');
    if (!includeInativos) {
      query = query.where('ativo', '=', true);
    }
    final rows = await query.get();
    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> createProcedimentoSecundario({
    required String codigoSigtap,
    required String descricao,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final id = await _db.table('procedimentos_v2').insertGetId({
      'codigo_sigtap': _normalizeSigtap(codigoSigtap.trim()),
      'descricao': descricao.trim(),
      'categoria': '',
      'tipo': 'secundario',
      'ativo': true,
      'created_at': now,
      'updated_at': now,
    }, 'id');
    final rows = await _db
        .table('procedimentos_v2')
        .select([
          'id',
          'codigo_sigtap',
          'descricao',
          'categoria',
          'tipo',
          'ativo',
          'created_at',
          'updated_at'
        ])
        .where('id', '=', (id as num).toInt())
        .limit(1)
        .get();
    return Map<String, dynamic>.from((rows as List).first as Map);
  }

  @override
  Future<Map<String, dynamic>> createProcedimentoPrincipal({
    required String codigoSigtap,
    required String descricao,
    required String categoria,
    required List<int> secundariosIds,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final id = await _db.table('procedimentos_v2').insertGetId({
      'codigo_sigtap': _normalizeSigtap(codigoSigtap.trim()),
      'descricao': descricao.trim(),
      'categoria': categoria.trim(),
      'tipo': 'principal',
      'ativo': true,
      'created_at': now,
      'updated_at': now,
    }, 'id');
    final principalId = (id as num).toInt();
    for (final sid in secundariosIds.toSet()) {
      await _db.table('procedimento_principal_secundario_v2').insert({
        'principal_id': principalId,
        'secundario_id': sid,
        'created_at': now,
      });
    }
    final rows = await _db
        .table('procedimentos_v2')
        .select([
          'id',
          'codigo_sigtap',
          'descricao',
          'categoria',
          'tipo',
          'ativo',
          'created_at',
          'updated_at'
        ])
        .where('id', '=', principalId)
        .limit(1)
        .get();
    return Map<String, dynamic>.from((rows as List).first as Map);
  }

  @override
  Future<Map<String, dynamic>?> updateProcedimento({
    required int id,
    String? codigoSigtap,
    String? descricao,
    String? categoria,
    List<int>? secundariosIds,
  }) async {
    final rows = await _db
        .table('procedimentos_v2')
        .select(['id', 'tipo'])
        .where('id', '=', id)
        .limit(1)
        .get();
    if ((rows as List).isEmpty) return null;
    final tipo = ((rows.first as Map)['tipo'] ?? '').toString();
    final now = DateTime.now().toUtc().toIso8601String();
    final updates = <String, dynamic>{'updated_at': now};
    if (codigoSigtap != null) {
      updates['codigo_sigtap'] = _normalizeSigtap(codigoSigtap.trim());
    }
    if (descricao != null) updates['descricao'] = descricao.trim();
    if (categoria != null) updates['categoria'] = categoria.trim();
    await _db.table('procedimentos_v2').where('id', '=', id).update(updates);

    if (tipo == 'principal' && secundariosIds != null) {
      await _db
          .table('procedimento_principal_secundario_v2')
          .where('principal_id', '=', id)
          .delete();
      for (final sid in secundariosIds.toSet()) {
        await _db.table('procedimento_principal_secundario_v2').insert({
          'principal_id': id,
          'secundario_id': sid,
          'created_at': now,
        });
      }
    }

    final updated = await _db
        .table('procedimentos_v2')
        .select([
          'id',
          'codigo_sigtap',
          'descricao',
          'categoria',
          'tipo',
          'ativo',
          'created_at',
          'updated_at'
        ])
        .where('id', '=', id)
        .limit(1)
        .get();
    return Map<String, dynamic>.from((updated as List).first as Map);
  }

  @override
  Future<bool> setProcedimentoAtivo(int id, bool ativo) async {
    final affected =
        await _db.table('procedimentos_v2').where('id', '=', id).update({
      'ativo': ativo,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return affected > 0;
  }

  @override
  Future<bool> setSecundarioPrincipais(
      int secundarioId, List<int> principaisIds) async {
    final secRows = await _db
        .table('procedimentos_v2')
        .select(['id'])
        .where('id', '=', secundarioId)
        .where('tipo', '=', 'secundario')
        .limit(1)
        .get();
    if ((secRows as List).isEmpty) return false;

    await _db
        .table('procedimento_principal_secundario_v2')
        .where('secundario_id', '=', secundarioId)
        .delete();

    if (principaisIds.isNotEmpty) {
      final principalRows = await _db
          .table('procedimentos_v2')
          .select(['id'])
          .whereIn('id', principaisIds.toSet().toList())
          .where('tipo', '=', 'principal')
          .get();
      final validPrincipalIds = (principalRows as List)
          .map((e) => ((e as Map)['id'] as num).toInt())
          .toSet()
          .toList();
      final now = DateTime.now().toUtc().toIso8601String();
      for (final principalId in validPrincipalIds) {
        await _db.table('procedimento_principal_secundario_v2').insert({
          'principal_id': principalId,
          'secundario_id': secundarioId,
          'created_at': now,
        });
      }
    }

    return true;
  }

  @override
  Future<bool> deleteProcedimento(int id) async {
    await _db
        .table('procedimento_principal_secundario_v2')
        .where('principal_id', '=', id)
        .orWhere('secundario_id', '=', id)
        .delete();
    final affected =
        await _db.table('procedimentos_v2').where('id', '=', id).update({
      'ativo': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return affected > 0;
  }
}
