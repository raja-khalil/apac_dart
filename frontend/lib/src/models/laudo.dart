class Laudo {
  Laudo({
    required this.id,
    required this.nomePaciente,
    required this.cpf,
    required this.dataNascimento,
    required this.ociCodigo,
    required this.ociDescricao,
    required this.unidadeSolicitante,
    required this.unidadeCnes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.payload,
  });

  final int id;
  final String nomePaciente;
  final String cpf;
  final String dataNascimento;
  final String ociCodigo;
  final String ociDescricao;
  final String unidadeSolicitante;
  final String unidadeCnes;
  final String status;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic> payload;

  factory Laudo.fromJson(Map<String, dynamic> json) {
    return Laudo(
      id: (json['id'] as num).toInt(),
      nomePaciente: (json['nome_paciente'] ?? '').toString(),
      cpf: (json['cpf'] ?? '').toString(),
      dataNascimento: (json['data_nascimento'] ?? '').toString(),
      ociCodigo: (json['oci_codigo'] ?? '').toString(),
      ociDescricao: (json['oci_descricao'] ?? '').toString(),
      unidadeSolicitante: (json['unidade_solicitante'] ?? '').toString(),
      unidadeCnes: (json['unidade_cnes'] ?? '').toString(),
      status: (json['status'] ?? 'rascunho').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      payload: Map<String, dynamic>.from(
        (json['payload'] as Map?) ?? <String, dynamic>{},
      ),
    );
  }
}
