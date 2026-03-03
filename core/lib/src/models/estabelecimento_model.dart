class EstabelecimentoModel {
  const EstabelecimentoModel({
    required this.nome,
    this.cnes = '',
    this.tipo = 'solicitante',
  });

  final String cnes;
  final String nome;
  final String tipo;

  factory EstabelecimentoModel.fromJson(Map<String, dynamic> json) {
    return EstabelecimentoModel(
      cnes: (json['cnes'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      tipo: (json['tipo'] ?? 'solicitante').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cnes': cnes,
      'nome': nome,
      'tipo': tipo,
    };
  }
}
