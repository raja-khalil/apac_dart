import 'dart:convert';

import 'package:apac_backend/src/modules/laudo/repositories/laudo_repository.dart';
import 'package:apac_core/apac_core.dart';
import 'package:eloquent/eloquent.dart';

class EloquentLaudoRepository implements ILaudoRepository {
  EloquentLaudoRepository(this._db);

  final Connection _db;

  @override
  Future<List<Map<String, dynamic>>> listAll({
    String? query,
    String? status,
    String? unidadeCnes,
  }) async {
    dynamic builder = _baseSelectBuilder();

    final cleanQuery = query?.trim().toLowerCase();
    if (cleanQuery != null && cleanQuery.isNotEmpty) {
      final like = '%$cleanQuery%';
      final digits = cleanQuery.replaceAll(RegExp(r'[^0-9]'), '');
      builder = builder.whereRaw(
        'LOWER(p.nome) LIKE ? OR REPLACE(COALESCE(p.cpf, \'\'), \'\.\', \'\') LIKE ? OR LOWER(pp.codigo_sigtap) LIKE ? OR LOWER(pp.descricao) LIKE ?',
        [like, '%$digits%', like, like],
      );
    }

    final cleanStatus = status?.trim();
    if (cleanStatus != null && cleanStatus.isNotEmpty) {
      builder = builder.where('l.status', '=', cleanStatus);
    }

    final cleanUnidade = unidadeCnes?.trim();
    if (cleanUnidade != null && cleanUnidade.isNotEmpty) {
      builder = builder.where('es.cnes', '=', cleanUnidade);
    }

    final rows = await builder.orderBy('l.id', 'desc').get();
    return _mapRows((rows as List));
  }

  @override
  Future<Map<String, dynamic>?> getById(int id) async {
    final rows = await _baseSelectBuilder().where('l.id', '=', id).limit(1).get();
    if ((rows as List).isEmpty) return null;
    final mapped = await _mapRows(rows);
    return mapped.isEmpty ? null : mapped.first;
  }

  @override
  Future<Map<String, dynamic>> create(
    Map<String, dynamic> payload, {
    int? actorUserId,
    String? actorIp,
  }) async {
    final model = LaudoModel.fromRequestPayload(payload);
    final now = DateTime.now().toUtc().toIso8601String();

    final pacienteId = await _upsertPaciente(model.paciente, now);
    final solicitanteId =
        await _upsertEstabelecimento(model.estabelecimentoSolicitante, now);
    final executanteId = model.estabelecimentoExecutante == null
        ? null
        : await _upsertEstabelecimento(model.estabelecimentoExecutante!, now);
    final procedimentoPrincipalId =
        await _upsertProcedimento(model.procedimentoPrincipal, now);

    final insertedId = await _db.table('laudos_v2').insertGetId({
      'paciente_id': pacienteId,
      'estabelecimento_solicitante_id': solicitanteId,
      'estabelecimento_executante_id': executanteId,
      'procedimento_principal_id': procedimentoPrincipalId,
      'status': model.status,
      'descricao_diagnostico': model.descricaoDiagnostico,
      'cid10_principal': model.cid10Principal,
      'cid10_secundario': model.cid10Secundario,
      'cid10_causas_associadas': model.cid10CausasAssociadas,
      'observacoes': model.observacoes,
      'profissional_solicitante': model.profissionalSolicitante,
      'tipo_documento': model.tipoDocumento,
      'documento_solicitante': model.documentoSolicitante,
      'data_solicitacao': _dateOrNull(model.dataSolicitacao),
      'payload': jsonEncode(payload),
      'created_at': now,
      'updated_at': now,
    }, 'id');

    final laudoId = (insertedId as num).toInt();
    await _syncSecundarios(laudoId, model.procedimentosSecundarios, now);

    final created = await getById(laudoId);
    if (created == null) {
      throw StateError('Falha ao carregar laudo criado.');
    }

    await _writeAudit(
      acao: 'create',
      entidade: 'laudo',
      entidadeId: laudoId,
      dadosAntes: null,
      dadosDepois: created,
      actorUserId: actorUserId,
      actorIp: actorIp,
      createdAt: now,
    );

    return created;
  }

  @override
  Future<Map<String, dynamic>?> update(
    int id,
    Map<String, dynamic> payload, {
    int? actorUserId,
    String? actorIp,
  }) async {
    final before = await getById(id);
    if (before == null) return null;

    final model = LaudoModel.fromRequestPayload(payload);
    final now = DateTime.now().toUtc().toIso8601String();

    final pacienteId = await _upsertPaciente(model.paciente, now);
    final solicitanteId =
        await _upsertEstabelecimento(model.estabelecimentoSolicitante, now);
    final executanteId = model.estabelecimentoExecutante == null
        ? null
        : await _upsertEstabelecimento(model.estabelecimentoExecutante!, now);
    final procedimentoPrincipalId =
        await _upsertProcedimento(model.procedimentoPrincipal, now);

    await _db.table('laudos_v2').where('id', '=', id).update({
      'paciente_id': pacienteId,
      'estabelecimento_solicitante_id': solicitanteId,
      'estabelecimento_executante_id': executanteId,
      'procedimento_principal_id': procedimentoPrincipalId,
      'status': model.status,
      'descricao_diagnostico': model.descricaoDiagnostico,
      'cid10_principal': model.cid10Principal,
      'cid10_secundario': model.cid10Secundario,
      'cid10_causas_associadas': model.cid10CausasAssociadas,
      'observacoes': model.observacoes,
      'profissional_solicitante': model.profissionalSolicitante,
      'tipo_documento': model.tipoDocumento,
      'documento_solicitante': model.documentoSolicitante,
      'data_solicitacao': _dateOrNull(model.dataSolicitacao),
      'payload': jsonEncode(payload),
      'updated_at': now,
    });

    await _syncSecundarios(id, model.procedimentosSecundarios, now);
    final after = await getById(id);

    await _writeAudit(
      acao: 'update',
      entidade: 'laudo',
      entidadeId: id,
      dadosAntes: before,
      dadosDepois: after,
      actorUserId: actorUserId,
      actorIp: actorIp,
      createdAt: now,
    );

    return after;
  }

  @override
  Future<bool> delete(
    int id, {
    int? actorUserId,
    String? actorIp,
  }) async {
    final before = await getById(id);
    if (before == null) return false;

    final now = DateTime.now().toUtc().toIso8601String();
    final deleted = await _db.table('laudos_v2').where('id', '=', id).delete();

    if (deleted > 0) {
      await _writeAudit(
        acao: 'delete',
        entidade: 'laudo',
        entidadeId: id,
        dadosAntes: before,
        dadosDepois: null,
        actorUserId: actorUserId,
        actorIp: actorIp,
        createdAt: now,
      );
      return true;
    }

    return false;
  }

  dynamic _baseSelectBuilder() {
    return _db.table('laudos_v2 as l').select([
      'l.id as id',
      'p.nome as nome_paciente',
      'p.nome_social as nome_social',
      'p.cpf as cpf',
      'p.cartao_sus as cartao_sus',
      'p.data_nascimento as data_nascimento',
      'p.sexo as sexo',
      'p.logradouro as endereco_logradouro',
      'p.numero as endereco_numero',
      'p.complemento as endereco_complemento',
      'p.bairro as endereco_bairro',
      'pp.codigo_sigtap as oci_codigo',
      'pp.descricao as oci_descricao',
      'es.nome as unidade_solicitante',
      'es.cnes as unidade_cnes',
      'l.status as status',
      'l.payload as payload',
      'l.created_at as created_at',
      'l.updated_at as updated_at',
    ])
      ..join('pacientes_v2 as p', 'p.id', '=', 'l.paciente_id')
      ..join('procedimentos_v2 as pp', 'pp.id', '=', 'l.procedimento_principal_id')
      ..leftJoin('estabelecimentos_v2 as es', 'es.id', '=', 'l.estabelecimento_solicitante_id');
  }

  Future<List<Map<String, dynamic>>> _mapRows(List rows) async {
    final result = <Map<String, dynamic>>[];
    for (final item in rows) {
      final row = Map<String, dynamic>.from(item as Map);
      final id = (row['id'] as num).toInt();
      final secundarios = await _loadSecundariosByLaudoId(id);
      result.add(_normalizeRow(row, secundarios));
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> _loadSecundariosByLaudoId(int laudoId) async {
    final rows = await _db
        .table('laudo_procedimentos_secundarios_v2')
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

  Future<void> _syncSecundarios(
    int laudoId,
    List<ProcedimentoSecundarioModel> secundarios,
    String now,
  ) async {
    await _db
        .table('laudo_procedimentos_secundarios_v2')
        .where('laudo_id', '=', laudoId)
        .delete();

    for (final sec in secundarios) {
      if (sec.codigo.trim().isEmpty || sec.nome.trim().isEmpty) continue;

      final procedimentoId = await _upsertProcedimento(
        ProcedimentoModel(
          codigoSigtap: sec.codigo,
          descricao: sec.nome,
          tipo: 'secundario',
        ),
        now,
      );

      await _db.table('laudo_procedimentos_secundarios_v2').insert({
        'laudo_id': laudoId,
        'procedimento_id': procedimentoId,
        'codigo_sigtap': sec.codigo,
        'nome_procedimento': sec.nome,
        'data_execucao': _dateOrNull(sec.dataExecucao),
        'origem': sec.origem.isEmpty ? 'oci' : sec.origem,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  Future<int> _upsertPaciente(PacienteModel paciente, String now) async {
    final cpf = paciente.cpf.trim();
    if (cpf.isNotEmpty) {
      final existing = await _db
          .table('pacientes_v2')
          .select(['id'])
          .where('cpf', '=', cpf)
          .limit(1)
          .get();

      if ((existing as List).isNotEmpty) {
        final id = ((existing.first as Map)['id'] as num).toInt();
        await _db.table('pacientes_v2').where('id', '=', id).update({
          'nome': paciente.nome,
          'nome_social': paciente.nomeSocial,
          'cartao_sus': paciente.cartaoSus,
          'data_nascimento': _dateOrNull(paciente.dataNascimento),
          'sexo': paciente.sexo,
          'nome_mae': paciente.nomeMae,
          'registro': paciente.registro,
          'telefone': paciente.telefone,
          'logradouro': paciente.logradouro,
          'numero': paciente.numero,
          'complemento': paciente.complemento,
          'bairro': paciente.bairro,
          'municipio': paciente.municipio,
          'ibge': paciente.ibge,
          'uf': paciente.uf,
          'cep': paciente.cep,
          'updated_at': now,
        });
        return id;
      }
    }

    final insertedId = await _db.table('pacientes_v2').insertGetId({
      'nome': paciente.nome,
      'nome_social': paciente.nomeSocial,
      'cpf': cpf.isEmpty ? null : cpf,
      'cartao_sus': paciente.cartaoSus,
      'data_nascimento': _dateOrNull(paciente.dataNascimento),
      'sexo': paciente.sexo,
      'nome_mae': paciente.nomeMae,
      'registro': paciente.registro,
      'telefone': paciente.telefone,
      'logradouro': paciente.logradouro,
      'numero': paciente.numero,
      'complemento': paciente.complemento,
      'bairro': paciente.bairro,
      'municipio': paciente.municipio,
      'ibge': paciente.ibge,
      'uf': paciente.uf,
      'cep': paciente.cep,
      'created_at': now,
      'updated_at': now,
    }, 'id');

    return (insertedId as num).toInt();
  }

  Future<int> _upsertEstabelecimento(
    EstabelecimentoModel estabelecimento,
    String now,
  ) async {
    dynamic query = _db.table('estabelecimentos_v2').select(['id']);
    final cnes = estabelecimento.cnes.trim();
    final tipo = estabelecimento.tipo.trim().isEmpty
        ? 'solicitante'
        : estabelecimento.tipo.trim();

    if (cnes.isNotEmpty) {
      query = query.where('cnes', '=', cnes);
    } else {
      query = query.where('nome', '=', estabelecimento.nome.trim());
    }
    query = query.whereRaw("tipo IN (?, 'ambos')", [tipo]).limit(1);

    final existing = await query.get();
    if ((existing as List).isNotEmpty) {
      final id = ((existing.first as Map)['id'] as num).toInt();
      await _db.table('estabelecimentos_v2').where('id', '=', id).update({
        'nome': estabelecimento.nome,
        'cnes': cnes.isEmpty ? null : cnes,
        'updated_at': now,
      });
      return id;
    }

    final insertedId = await _db.table('estabelecimentos_v2').insertGetId({
      'nome': estabelecimento.nome,
      'cnes': cnes.isEmpty ? null : cnes,
      'tipo': tipo,
      'created_at': now,
      'updated_at': now,
    }, 'id');

    return (insertedId as num).toInt();
  }

  Future<int> _upsertProcedimento(ProcedimentoModel procedimento, String now) async {
    final codigo = procedimento.codigoSigtap.trim();

    final existing = await _db
        .table('procedimentos_v2')
        .select(['id'])
        .where('codigo_sigtap', '=', codigo)
        .limit(1)
        .get();

    if ((existing as List).isNotEmpty) {
      final id = ((existing.first as Map)['id'] as num).toInt();
      await _db.table('procedimentos_v2').where('id', '=', id).update({
        'descricao': procedimento.descricao,
        'tipo': procedimento.tipo,
        'updated_at': now,
      });
      return id;
    }

    final insertedId = await _db.table('procedimentos_v2').insertGetId({
      'codigo_sigtap': codigo,
      'descricao': procedimento.descricao,
      'tipo': procedimento.tipo,
      'ativo': true,
      'created_at': now,
      'updated_at': now,
    }, 'id');

    return (insertedId as num).toInt();
  }

  Future<void> _writeAudit({
    required String acao,
    required String entidade,
    required int entidadeId,
    required Map<String, dynamic>? dadosAntes,
    required Map<String, dynamic>? dadosDepois,
    required int? actorUserId,
    required String? actorIp,
    required String createdAt,
  }) async {
    await _db.table('audit_logs_v2').insert({
      'usuario_id': actorUserId,
      'acao': acao,
      'entidade': entidade,
      'entidade_id': entidadeId,
      'dados_antes': jsonEncode(dadosAntes ?? <String, dynamic>{}),
      'dados_depois': jsonEncode(dadosDepois ?? <String, dynamic>{}),
      'ip_origem': (actorIp ?? '').trim(),
      'created_at': createdAt,
    });
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
      return value.toUtc().toIso8601String().split('T').first;
    }
    final text = value.toString();
    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  String _asDateTimeString(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value.toString();
  }

  String? _dateOrNull(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return null;
    final parsed = DateTime.tryParse(clean);
    if (parsed == null) return null;
    return parsed.toUtc().toIso8601String().split('T').first;
  }
}
