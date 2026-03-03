class PacienteModel {
  const PacienteModel({
    required this.nome,
    this.nomeSocial = '',
    this.cpf = '',
    this.cartaoSus = '',
    this.dataNascimento = '',
    this.sexo = '',
    this.nomeMae = '',
    this.registro = '',
    this.telefone = '',
    this.logradouro = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.municipio = '',
    this.ibge = '',
    this.uf = '',
    this.cep = '',
  });

  final String nome;
  final String nomeSocial;
  final String cpf;
  final String cartaoSus;
  final String dataNascimento;
  final String sexo;
  final String nomeMae;
  final String registro;
  final String telefone;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String municipio;
  final String ibge;
  final String uf;
  final String cep;

  factory PacienteModel.fromJson(Map<String, dynamic> json) {
    return PacienteModel(
      nome: (json['nome'] ?? '').toString(),
      nomeSocial: (json['nome_social'] ?? '').toString(),
      cpf: (json['cpf'] ?? '').toString(),
      cartaoSus: (json['cartao_sus'] ?? '').toString(),
      dataNascimento: (json['data_nascimento'] ?? '').toString(),
      sexo: (json['sexo'] ?? '').toString(),
      nomeMae: (json['nome_mae'] ?? '').toString(),
      registro: (json['registro'] ?? '').toString(),
      telefone: (json['telefone'] ?? '').toString(),
      logradouro: (json['logradouro'] ?? '').toString(),
      numero: (json['numero'] ?? '').toString(),
      complemento: (json['complemento'] ?? '').toString(),
      bairro: (json['bairro'] ?? '').toString(),
      municipio: (json['municipio'] ?? '').toString(),
      ibge: (json['ibge'] ?? '').toString(),
      uf: (json['uf'] ?? '').toString(),
      cep: (json['cep'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'nome_social': nomeSocial,
      'cpf': cpf,
      'cartao_sus': cartaoSus,
      'data_nascimento': dataNascimento,
      'sexo': sexo,
      'nome_mae': nomeMae,
      'registro': registro,
      'telefone': telefone,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'municipio': municipio,
      'ibge': ibge,
      'uf': uf,
      'cep': cep,
    };
  }
}
