import 'dart:convert';

class LaudoRepository {
  LaudoRepository(this._db);

  final dynamic _db;

  Future<List<Map<String, dynamic>>> listAll({
    String? query,
    String? status,
    String? unidadeCnes,
  }) async {
    dynamic builder = _db.table('laudos').select([
      'id',
      'nome_paciente',
      'nome_social',
      'cpf',
      'cartao_sus',
      'data_nascimento',
      'sexo',
      'endereco_logradouro',
      'endereco_numero',
      'endereco_complemento',
      'endereco_bairro',
      'oci_codigo',
      'oci_descricao',
      'unidade_solicitante',
      'unidade_cnes',
      'status',
      'payload',
      'created_at',
      'updated_at',
    ]);

    final cleanQuery = query?.trim();
    if (cleanQuery != null && cleanQuery.isNotEmpty) {
      final like = '%${cleanQuery.toLowerCase()}%';
      builder = builder.whereRaw(
        'LOWER(nome_paciente) LIKE ? OR REPLACE(cpf, ''.'', '''') LIKE REPLACE(?, ''.'', '''') OR LOWER(oci_codigo) LIKE ? OR LOWER(oci_descricao) LIKE ?',
        [like, like, like, like],
      );
    }

    final cleanStatus = status?.trim();
    if (cleanStatus != null && cleanStatus.isNotEmpty) {
      builder = builder.where('status', '=', cleanStatus);
    }

    final cleanUnidade = unidadeCnes?.trim();
    if (cleanUnidade != null && cleanUnidade.isNotEmpty) {
      builder = builder.where('unidade_cnes', '=', cleanUnidade);
    }

    final rows = await builder.orderBy('id', 'desc').get();
    final mapped = <Map<String, dynamic>>[];
    for (final row in (rows as List)) {
      final mapRow = Map<String, dynamic>.from(row as Map);
      final secundarios = await _loadSecundariosByLaudoId(
        (mapRow['id'] as num).toInt(),
      );
      mapped.add(_normalizeRow(mapRow, secundarios));
    }
    return mapped;
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final rows = await _db
        .table('laudos')
        .select([
          'id',
          'nome_paciente',
          'nome_social',
          'cpf',
          'cartao_sus',
          'data_nascimento',
          'sexo',
          'endereco_logradouro',
          'endereco_numero',
          'endereco_complemento',
          'endereco_bairro',
          'oci_codigo',
          'oci_descricao',
          'unidade_solicitante',
          'unidade_cnes',
          'status',
          'payload',
          'created_at',
          'updated_at',
        ])
        .where('id', '=', id)
        .limit(1)
        .get();

    if ((rows as List).isEmpty) {
      return null;
    }
    final mapRow = Map<String, dynamic>.from(rows.first as Map);
    final secundarios = await _loadSecundariosByLaudoId(
      (mapRow['id'] as num).toInt(),
    );
    return _normalizeRow(mapRow, secundarios);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final insertData = _extractColumns(payload);
    final secundarios = _extractSecundarios(payload);
    final createdAt = DateTime.now().toIso8601String();
    insertData['created_at'] = createdAt;
    insertData['updated_at'] = createdAt;

    final insertedId = await _db.table('laudos').insertGetId(insertData, 'id');
    await _syncSecundarios(insertedId.toInt(), secundarios);
    final created = await getById((insertedId as num).toInt());

    if (created == null) {
      throw StateError('Falha ao ler registro criado.');
    }

    return created;
  }

  Future<Map<String, dynamic>?> update(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final updateData = _extractColumns(payload);
    final secundarios = _extractSecundarios(payload);
    updateData['updated_at'] = DateTime.now().toIso8601String();

    await _db.table('laudos').where('id', '=', id).update(updateData);
    await _syncSecundarios(id, secundarios);

    return getById(id);
  }

  Future<bool> delete(int id) async {
    await _db
        .table('laudo_procedimentos_secundarios')
        .where('laudo_id', '=', id)
        .delete();
    final deleted = await _db.table('laudos').where('id', '=', id).delete();
    if (deleted is num) {
      return deleted > 0;
    }
    return false;
  }

  Map<String, dynamic> _extractColumns(Map<String, dynamic> payload) {
    final paciente = Map<String, dynamic>.from(
      (payload['paciente'] as Map?) ?? <String, dynamic>{},
    );
    final procedimentoPrincipal = Map<String, dynamic>.from(
      (payload['procedimento_principal'] as Map?) ?? <String, dynamic>{},
    );
    final estabelecimentoSolicitante = Map<String, dynamic>.from(
      (payload['estabelecimento_solicitante'] as Map?) ?? <String, dynamic>{},
    );

    final nomePaciente = (payload['nome_paciente'] ?? paciente['nome'] ?? '')
        .toString()
        .trim();
    final nomeSocial =
        (payload['nome_social'] ?? paciente['nome_social'] ?? '')
            .toString()
            .trim();
    final cpf = (payload['cpf'] ?? paciente['cpf'] ?? '').toString().trim();
    final cartaoSus =
        (payload['cartao_sus'] ?? paciente['cartao_sus'] ?? '')
            .toString()
            .trim();
    final dataNascimento =
        (payload['data_nascimento'] ?? paciente['data_nascimento'] ?? '')
            .toString()
            .trim();
    final sexo = (payload['sexo'] ?? paciente['sexo'] ?? '').toString().trim();
    final enderecoLogradouro =
        (payload['endereco_logradouro'] ?? paciente['logradouro'] ?? '')
            .toString()
            .trim();
    final enderecoNumero =
        (payload['endereco_numero'] ?? paciente['numero'] ?? '')
            .toString()
            .trim();
    final enderecoComplemento =
        (payload['endereco_complemento'] ?? paciente['complemento'] ?? '')
            .toString()
            .trim();
    final enderecoBairro =
        (payload['endereco_bairro'] ?? paciente['bairro'] ?? '')
            .toString()
            .trim();
    final ociCodigo =
        (payload['oci_codigo'] ?? procedimentoPrincipal['codigo'] ?? '')
            .toString()
            .trim();
    final ociDescricao =
        (payload['oci_descricao'] ?? procedimentoPrincipal['descricao'] ?? '')
            .toString()
            .trim();
    final unidadeSolicitante =
        (payload['unidade_solicitante'] ??
                estabelecimentoSolicitante['nome'] ??
                '')
            .toString()
            .trim();
    final unidadeCnes =
        (payload['unidade_cnes'] ?? estabelecimentoSolicitante['cnes'] ?? '')
            .toString()
            .trim();
    final status = (payload['status'] ?? 'rascunho').toString().trim();

    return {
      'nome_paciente': nomePaciente,
      'nome_social': nomeSocial,
      'cpf': cpf,
      'cartao_sus': cartaoSus,
      'data_nascimento': dataNascimento,
      'sexo': sexo,
      'endereco_logradouro': enderecoLogradouro,
      'endereco_numero': enderecoNumero,
      'endereco_complemento': enderecoComplemento,
      'endereco_bairro': enderecoBairro,
      'oci_codigo': ociCodigo,
      'oci_descricao': ociDescricao,
      'unidade_solicitante': unidadeSolicitante,
      'unidade_cnes': unidadeCnes,
      'status': status,
      'payload': jsonEncode(payload),
    };
  }

  List<Map<String, dynamic>> _extractSecundarios(Map<String, dynamic> payload) {
    final secundarios = (payload['procedimentos_secundarios'] as List?) ?? <dynamic>[];
    final result = <Map<String, dynamic>>[];
    for (final item in secundarios) {
      final map = Map<String, dynamic>.from(item as Map);
      final codigo = (map['codigo'] ?? '').toString().trim();
      final nome = (map['nome'] ?? '').toString().trim();
      if (codigo.isEmpty || nome.isEmpty) continue;
      result.add({
        'codigo_sigtap': codigo,
        'nome_procedimento': nome,
        'data_execucao': (map['data_execucao'] ?? '').toString().trim(),
        'origem': (map['origem'] ?? 'oci').toString().trim(),
      });
    }
    return result;
  }

  Future<void> _syncSecundarios(
    int laudoId,
    List<Map<String, dynamic>> secundarios,
  ) async {
    await _db
        .table('laudo_procedimentos_secundarios')
        .where('laudo_id', '=', laudoId)
        .delete();

    if (secundarios.isEmpty) return;

    for (final sec in secundarios) {
      await _db.table('laudo_procedimentos_secundarios').insert({
        'laudo_id': laudoId,
        'codigo_sigtap': sec['codigo_sigtap'],
        'nome_procedimento': sec['nome_procedimento'],
        'data_execucao':
            (sec['data_execucao'] as String).isEmpty ? null : sec['data_execucao'],
        'origem': (sec['origem'] as String).isEmpty ? 'oci' : sec['origem'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadSecundariosByLaudoId(int laudoId) async {
    final rows = await _db
        .table('laudo_procedimentos_secundarios')
        .select([
          'codigo_sigtap',
          'nome_procedimento',
          'data_execucao',
          'origem',
        ])
        .where('laudo_id', '=', laudoId)
        .orderBy('id', 'asc')
        .get();

    return (rows as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  Map<String, dynamic> _normalizeRow(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> secundarios,
  ) {
    dynamic payload = row['payload'];
    if (payload is String && payload.isNotEmpty) {
      try {
        payload = jsonDecode(payload);
      } catch (_) {
        payload = <String, dynamic>{};
      }
    }

    return {
      'id': row['id'],
      'nome_paciente': row['nome_paciente']?.toString() ?? '',
      'nome_social': row['nome_social']?.toString() ?? '',
      'cpf': row['cpf']?.toString() ?? '',
      'cartao_sus': row['cartao_sus']?.toString() ?? '',
      'data_nascimento': _asDateString(row['data_nascimento']),
      'sexo': row['sexo']?.toString() ?? '',
      'endereco_logradouro': row['endereco_logradouro']?.toString() ?? '',
      'endereco_numero': row['endereco_numero']?.toString() ?? '',
      'endereco_complemento': row['endereco_complemento']?.toString() ?? '',
      'endereco_bairro': row['endereco_bairro']?.toString() ?? '',
      'oci_codigo': row['oci_codigo']?.toString() ?? '',
      'oci_descricao': row['oci_descricao']?.toString() ?? '',
      'unidade_solicitante': row['unidade_solicitante']?.toString() ?? '',
      'unidade_cnes': row['unidade_cnes']?.toString() ?? '',
      'status': row['status']?.toString() ?? 'rascunho',
      'procedimentos_secundarios': secundarios
          .map((s) => {
                'codigo': s['codigo_sigtap']?.toString() ?? '',
                'nome': s['nome_procedimento']?.toString() ?? '',
                'data_execucao': _asDateString(s['data_execucao']),
                'origem': s['origem']?.toString() ?? 'oci',
              })
          .toList(),
      'payload': payload is Map ? payload : <String, dynamic>{},
      'created_at': _asDateTimeString(row['created_at']),
      'updated_at': _asDateTimeString(row['updated_at']),
    };
  }

  String _asDateString(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) {
      final date = value.toUtc().toIso8601String();
      return date.split('T').first;
    }

    final text = value.toString();
    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  String _asDateTimeString(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value.toString();
  }
}
