import 'estabelecimento_model.dart';
import 'paciente_model.dart';
import 'procedimento_model.dart';
import 'procedimento_secundario_model.dart';

class LaudoModel {
  const LaudoModel({
    this.id,
    required this.paciente,
    required this.estabelecimentoSolicitante,
    this.estabelecimentoExecutante,
    required this.procedimentoPrincipal,
    this.procedimentosSecundarios = const <ProcedimentoSecundarioModel>[],
    this.status = 'rascunho',
    this.descricaoDiagnostico = '',
    this.cid10Principal = '',
    this.cid10Secundario = '',
    this.cid10CausasAssociadas = '',
    this.observacoes = '',
    this.profissionalSolicitante = '',
    this.tipoDocumento = 'CPF',
    this.documentoSolicitante = '',
    this.dataSolicitacao = '',
    this.payload = const <String, dynamic>{},
    this.createdAt = '',
    this.updatedAt = '',
  });

  final int? id;
  final PacienteModel paciente;
  final EstabelecimentoModel estabelecimentoSolicitante;
  final EstabelecimentoModel? estabelecimentoExecutante;
  final ProcedimentoModel procedimentoPrincipal;
  final List<ProcedimentoSecundarioModel> procedimentosSecundarios;
  final String status;
  final String descricaoDiagnostico;
  final String cid10Principal;
  final String cid10Secundario;
  final String cid10CausasAssociadas;
  final String observacoes;
  final String profissionalSolicitante;
  final String tipoDocumento;
  final String documentoSolicitante;
  final String dataSolicitacao;
  final Map<String, dynamic> payload;
  final String createdAt;
  final String updatedAt;

  factory LaudoModel.fromRequestPayload(Map<String, dynamic> body) {
    final pacienteJson = Map<String, dynamic>.from(
      (body['paciente'] as Map?) ?? <String, dynamic>{},
    );
    final solicitanteJson = Map<String, dynamic>.from(
      (body['estabelecimento_solicitante'] as Map?) ?? <String, dynamic>{},
    );
    final executanteJson = Map<String, dynamic>.from(
      (body['estabelecimento_executante'] as Map?) ?? <String, dynamic>{},
    );
    final principalJson = Map<String, dynamic>.from(
      (body['procedimento_principal'] as Map?) ?? <String, dynamic>{},
    );

    final secundariosRaw =
        (body['procedimentos_secundarios'] as List?) ?? <dynamic>[];

    return LaudoModel(
      id: body['id'] is num ? (body['id'] as num).toInt() : null,
      paciente: PacienteModel.fromJson({
        ...pacienteJson,
        'nome': (body['nome_paciente'] ?? pacienteJson['nome'] ?? '').toString(),
        'nome_social':
            (body['nome_social'] ?? pacienteJson['nome_social'] ?? '').toString(),
        'cpf': (body['cpf'] ?? pacienteJson['cpf'] ?? '').toString(),
        'cartao_sus':
            (body['cartao_sus'] ?? pacienteJson['cartao_sus'] ?? '').toString(),
        'data_nascimento':
            (body['data_nascimento'] ?? pacienteJson['data_nascimento'] ?? '')
                .toString(),
        'sexo': (body['sexo'] ?? pacienteJson['sexo'] ?? '').toString(),
        'logradouro': (body['endereco_logradouro'] ?? pacienteJson['logradouro'] ?? '')
            .toString(),
        'numero': (body['endereco_numero'] ?? pacienteJson['numero'] ?? '').toString(),
        'complemento':
            (body['endereco_complemento'] ?? pacienteJson['complemento'] ?? '')
                .toString(),
        'bairro': (body['endereco_bairro'] ?? pacienteJson['bairro'] ?? '').toString(),
      }),
      estabelecimentoSolicitante: EstabelecimentoModel.fromJson({
        ...solicitanteJson,
        'nome': (body['unidade_solicitante'] ?? solicitanteJson['nome'] ?? '')
            .toString(),
        'cnes':
            (body['unidade_cnes'] ?? solicitanteJson['cnes'] ?? '').toString(),
        'tipo': 'solicitante',
      }),
      estabelecimentoExecutante: executanteJson.isEmpty
          ? null
          : EstabelecimentoModel.fromJson({
              ...executanteJson,
              'tipo': 'executante',
            }),
      procedimentoPrincipal: ProcedimentoModel.fromJson({
        ...principalJson,
        'codigo': (body['oci_codigo'] ?? principalJson['codigo'] ?? '').toString(),
        'descricao':
            (body['oci_descricao'] ?? principalJson['descricao'] ?? '').toString(),
        'tipo': 'principal',
      }),
      procedimentosSecundarios: secundariosRaw
          .whereType<Map>()
          .map((e) => ProcedimentoSecundarioModel.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      status: (body['status'] ?? 'rascunho').toString(),
      descricaoDiagnostico: (body['descricao_diagnostico'] ?? '').toString(),
      cid10Principal: (body['cid10_principal'] ?? '').toString(),
      cid10Secundario: (body['cid10_secundario'] ?? '').toString(),
      cid10CausasAssociadas: (body['cid10_causas_associadas'] ?? '').toString(),
      observacoes: (body['observacoes'] ?? '').toString(),
      profissionalSolicitante: (body['profissional_solicitante'] ?? '').toString(),
      tipoDocumento: (body['tipo_documento'] ?? 'CPF').toString(),
      documentoSolicitante: (body['documento_solicitante'] ?? '').toString(),
      dataSolicitacao: (body['data_solicitacao'] ?? '').toString(),
      payload: Map<String, dynamic>.from(body),
      createdAt: (body['created_at'] ?? '').toString(),
      updatedAt: (body['updated_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toApiResponse() {
    return {
      'id': id,
      'nome_paciente': paciente.nome,
      'nome_social': paciente.nomeSocial,
      'cpf': paciente.cpf,
      'cartao_sus': paciente.cartaoSus,
      'data_nascimento': paciente.dataNascimento,
      'sexo': paciente.sexo,
      'endereco_logradouro': paciente.logradouro,
      'endereco_numero': paciente.numero,
      'endereco_complemento': paciente.complemento,
      'endereco_bairro': paciente.bairro,
      'oci_codigo': procedimentoPrincipal.codigoSigtap,
      'oci_descricao': procedimentoPrincipal.descricao,
      'unidade_solicitante': estabelecimentoSolicitante.nome,
      'unidade_cnes': estabelecimentoSolicitante.cnes,
      'status': status,
      'procedimentos_secundarios':
          procedimentosSecundarios.map((e) => e.toJson()).toList(),
      'payload': payload,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
