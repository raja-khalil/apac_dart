class ProcedimentoSecundarioModel {
  const ProcedimentoSecundarioModel({
    required this.codigo,
    required this.nome,
    this.dataExecucao = '',
    this.origem = 'oci',
  });

  final String codigo;
  final String nome;
  final String dataExecucao;
  final String origem;

  factory ProcedimentoSecundarioModel.fromJson(Map<String, dynamic> json) {
    return ProcedimentoSecundarioModel(
      codigo: (json['codigo'] ?? json['codigo_sigtap'] ?? '').toString(),
      nome: (json['nome'] ?? json['nome_procedimento'] ?? '').toString(),
      dataExecucao: (json['data_execucao'] ?? '').toString(),
      origem: (json['origem'] ?? 'oci').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nome': nome,
      'data_execucao': dataExecucao,
      'origem': origem,
    };
  }
}
