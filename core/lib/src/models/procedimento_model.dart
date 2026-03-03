class ProcedimentoModel {
  const ProcedimentoModel({
    required this.codigoSigtap,
    required this.descricao,
    this.tipo = 'principal',
  });

  final String codigoSigtap;
  final String descricao;
  final String tipo;

  factory ProcedimentoModel.fromJson(Map<String, dynamic> json) {
    return ProcedimentoModel(
      codigoSigtap: (json['codigo'] ?? json['codigo_sigtap'] ?? '').toString(),
      descricao: (json['descricao'] ?? '').toString(),
      tipo: (json['tipo'] ?? 'principal').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigoSigtap,
      'descricao': descricao,
      'tipo': tipo,
    };
  }
}
