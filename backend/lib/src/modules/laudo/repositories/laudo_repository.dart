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
      'cpf',
      'data_nascimento',
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

    return (rows as List)
        .map((row) => _normalizeRow(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final rows = await _db
        .table('laudos')
        .select([
          'id',
          'nome_paciente',
          'cpf',
          'data_nascimento',
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

    return _normalizeRow(Map<String, dynamic>.from(rows.first as Map));
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final insertData = _extractColumns(payload);
    final createdAt = DateTime.now().toIso8601String();
    insertData['created_at'] = createdAt;
    insertData['updated_at'] = createdAt;

    final insertedId = await _db.table('laudos').insertGetId(insertData, 'id');
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
    updateData['updated_at'] = DateTime.now().toIso8601String();

    await _db.table('laudos').where('id', '=', id).update(updateData);

    return getById(id);
  }

  Future<bool> delete(int id) async {
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
    final cpf = (payload['cpf'] ?? paciente['cpf'] ?? '').toString().trim();
    final dataNascimento =
        (payload['data_nascimento'] ?? paciente['data_nascimento'] ?? '')
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
      'cpf': cpf,
      'data_nascimento': dataNascimento,
      'oci_codigo': ociCodigo,
      'oci_descricao': ociDescricao,
      'unidade_solicitante': unidadeSolicitante,
      'unidade_cnes': unidadeCnes,
      'status': status,
      'payload': jsonEncode(payload),
    };
  }

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
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
      'cpf': row['cpf']?.toString() ?? '',
      'data_nascimento': _asDateString(row['data_nascimento']),
      'oci_codigo': row['oci_codigo']?.toString() ?? '',
      'oci_descricao': row['oci_descricao']?.toString() ?? '',
      'unidade_solicitante': row['unidade_solicitante']?.toString() ?? '',
      'unidade_cnes': row['unidade_cnes']?.toString() ?? '',
      'status': row['status']?.toString() ?? 'rascunho',
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
