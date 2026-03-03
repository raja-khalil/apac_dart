class Estabelecimento {
  const Estabelecimento({required this.cnes, required this.nome});

  final String cnes;
  final String nome;
}

class ProcedimentoSecundario {
  const ProcedimentoSecundario({required this.codigo, required this.nome});

  final String codigo;
  final String nome;
}

class OciProcedimento {
  const OciProcedimento({
    required this.codigo,
    required this.nome,
    required this.secundarios,
  });

  final String codigo;
  final String nome;
  final List<ProcedimentoSecundario> secundarios;
}

const List<Estabelecimento> estabelecimentosSolicitantes = [
  Estabelecimento(cnes: '9587918', nome: 'AMBULATORIO DE SAUDE MENTAL RIO DAS OSTRAS'),
  Estabelecimento(cnes: '2275376', nome: 'UNIDADE BASICA DE SAUDE JARDIM MARILEA'),
  Estabelecimento(cnes: '5868807', nome: 'CENTRAL DE REGULACAO TFD RIO DAS OSTRAS'),
  Estabelecimento(cnes: '2275392', nome: 'CENTRO DE SAUDE RIO DAS OSTRAS'),
  Estabelecimento(cnes: '2298694', nome: 'UNIDADE SAUDE DA FAMILIA CIDADE PRAIANA'),
  Estabelecimento(cnes: '3405443', nome: 'MEDICINA DO TRABALHO RIO DAS OSTRAS'),
  Estabelecimento(cnes: '7612036', nome: 'PRONTO SOCORRO MUNICIPAL RIO DAS OSTRAS'),
  Estabelecimento(cnes: '2936844', nome: 'PROGRAMA DE COMBATE A HANSENIASE E DE CONTROLE A TUBERCULOSE'),
  Estabelecimento(cnes: '9240543', nome: 'DEPARTAMENTO DE PROGRAMAS DE SAUDE'),
  Estabelecimento(cnes: '2696835', nome: 'CENTRO DE REABILITACAO LAERCIO LUCIO DE CARVALHO'),
  Estabelecimento(cnes: '7100876', nome: 'FARMACIA MUNICIPAL DE RIO DAS OSTRAS'),
  Estabelecimento(cnes: '2275368', nome: 'UNIDADE SAUDE DA FAMILIA CANTAGALO'),
  Estabelecimento(cnes: '2275317', nome: 'UNIDADE BASICA DE SAUDE BOCA DA BARRA'),
  Estabelecimento(cnes: '9140212', nome: 'UNIDADE SAUDE DA FAMILIA CLAUDIO RIBEIRO'),
  Estabelecimento(cnes: '2275406', nome: 'COORDENADORIA DE VIGILANCIA EM SAUDE'),
  Estabelecimento(cnes: '6422608', nome: 'SECRETARIA MUNICIPAL DE SAUDE DE RIO DAS OSTRAS'),
  Estabelecimento(cnes: '4325192', nome: 'CAPS INFANTO JUVENIL RUI RIBEIRO DE FREITAS'),
  Estabelecimento(cnes: '4272188', nome: 'SERVICO DE CUIDADOS A PESSOAS COM ESTOMAS'),
  Estabelecimento(cnes: '5944406', nome: 'POLO DE DISTRIBUICAO DE MEDICAMENTOS ESPECIAIS CEAF RJ'),
  Estabelecimento(cnes: '3533913', nome: 'CENTRO DE REABILITACAO ROCHA LEAO RIO DAS OSTRAS'),
  Estabelecimento(cnes: '5851858', nome: 'CAPS CENTRO DE ATENCAO PSICOSSOCIAL RIO DAS OSTRAS'),
  Estabelecimento(cnes: '2275333', nome: 'UNIDADE SAUDE DA FAMILIA RECANTO'),
  Estabelecimento(cnes: '6069134', nome: 'HOSPITAL MUNICIPAL DRA NAELMA MONTEIRO DA SILVA'),
  Estabelecimento(cnes: '3533921', nome: 'UNIDADE SAUDE DA FAMILIA ANCORA'),
  Estabelecimento(cnes: '0484067', nome: 'CENTRAL DE ARMAZENAGEM E DISTRIBUICAO DE IMUNOBIOLOGICOS RO'),
  Estabelecimento(cnes: '2275341', nome: 'UNIDADE SAUDE DA FAMILIA NOVA CIDADE'),
  Estabelecimento(cnes: '7831145', nome: 'CEO RIO DAS OSTRAS'),
  Estabelecimento(cnes: '2275309', nome: 'UNIDADE SAUDE DA FAMILIA MAR DO NORTE'),
  Estabelecimento(cnes: '2275325', nome: 'UNIDADE BASICA DE SAUDE NOVA ESPERANCA'),
  Estabelecimento(cnes: '2275295', nome: 'UNIDADE SAUDE DA FAMILIA ROCHA LEAO'),
  Estabelecimento(cnes: '2295962', nome: 'UNIDADE SAUDE DA FAMILIA OPERARIO'),
  Estabelecimento(cnes: '7528655', nome: 'CLINICA DA FAMILIA PAULO HENRIQUE GUSSEM'),
  Estabelecimento(cnes: '2912295', nome: 'DEPARTAMENTO GERAL DE DIAGNOSTICO'),
  Estabelecimento(cnes: '4501918', nome: 'SERVICO DE ATENDIMENTO DOMICILIAR'),
  Estabelecimento(cnes: '7540345', nome: 'UNIDADE SAUDE DA FAMILIA DONA EDIMEIA'),
  Estabelecimento(cnes: '0106453', nome: 'UPA 24H VALMIR HESPANHOL'),
  Estabelecimento(cnes: '3980642', nome: 'CENTRO DE OFTALMOLOGIA NILTON GONCALVES MARINS'),
  Estabelecimento(cnes: '2947358', nome: 'SERVICO DE REFERENCIA A SAUDE DA MULHER'),
  Estabelecimento(cnes: '9997342', nome: 'NASCA NUCLEO DE ATENCAO A SAUDE DA CRIANCA E ADOLESCENTE'),
  Estabelecimento(cnes: '7731582', nome: 'SERVICO DE ASSISTENCIA ESPECIALIZADA EM DST'),
];

const List<Estabelecimento> estabelecimentosExecutantes = [
  Estabelecimento(cnes: '2275392', nome: 'CENTRO DE SAUDE RIO DAS OSTRAS'),
  Estabelecimento(cnes: '6069134', nome: 'HOSPITAL MUNICIPAL DRA NAELMA MONTEIRO DA SILVA'),
  Estabelecimento(cnes: '3980642', nome: 'CENTRO DE OFTALMOLOGIA NILTON GONCALVES MARINS'),
  Estabelecimento(cnes: '2947358', nome: 'SERVICO DE REFERENCIA A SAUDE DA MULHER'),
];

const List<OciProcedimento> ociProcedimentos = [
  OciProcedimento(codigo: '09.01.01.001-4', nome: 'OCI Avaliacao Diagnostica Inicial Cancer Mama', secundarios: [ProcedimentoSecundario(codigo: '02.04.03.003-0', nome: 'Mamografia')]),
  OciProcedimento(codigo: '09.01.01.009-0', nome: 'OCI Progressao Avaliacao Cancer Mama I', secundarios: [ProcedimentoSecundario(codigo: '02.01.01.058-5', nome: 'PAAF'), ProcedimentoSecundario(codigo: '02.03.01.004-3', nome: 'Citopatologico')]),
  OciProcedimento(codigo: '09.01.01.010-3', nome: 'OCI Progressao Avaliacao Cancer Mama II', secundarios: [ProcedimentoSecundario(codigo: '02.01.01.060-7', nome: 'Core Biopsy'), ProcedimentoSecundario(codigo: '02.03.02.006-5', nome: 'Anatomopatologico')]),
  OciProcedimento(codigo: '09.01.01.005-7', nome: 'OCI Investigacao Cancer Colo Utero', secundarios: [ProcedimentoSecundario(codigo: '02.01.01.006-6', nome: 'Biopsia Colo'), ProcedimentoSecundario(codigo: '02.03.02.008-1', nome: 'Anatomopatologico')]),
  OciProcedimento(codigo: '09.01.01.011-1', nome: 'OCI Avaliacao Terapeutica Colo Utero I', secundarios: [ProcedimentoSecundario(codigo: '04.09.06.008-9', nome: 'Excisao Tipo I'), ProcedimentoSecundario(codigo: '02.03.02.002-2', nome: 'Anatomopatologico')]),
  OciProcedimento(codigo: '09.01.01.012-0', nome: 'OCI Avaliacao Terapeutica Colo Utero II', secundarios: [ProcedimentoSecundario(codigo: '04.09.06.030-5', nome: 'Excisao Tipo II'), ProcedimentoSecundario(codigo: '02.03.02.002-2', nome: 'Anatomopatologico')]),
  OciProcedimento(codigo: '09.01.01.004-9', nome: 'OCI Progressao Avaliacao Cancer Prostata', secundarios: [ProcedimentoSecundario(codigo: '02.05.02.011-9', nome: 'US Transretal'), ProcedimentoSecundario(codigo: '02.01.01.041-0', nome: 'Biopsia'), ProcedimentoSecundario(codigo: '02.03.02.003-0', nome: 'Anatomopatologico')]),
  OciProcedimento(codigo: '09.01.01.007-3', nome: 'OCI Avaliacao Diagnostica Cancer Gastrico', secundarios: [ProcedimentoSecundario(codigo: '02.09.01.003-7', nome: 'Esofagogastroduodenoscopia')]),
  OciProcedimento(codigo: '09.01.01.008-1', nome: 'OCI Avaliacao Diagnostica Cancer Colorretal', secundarios: [ProcedimentoSecundario(codigo: '02.09.01.002-9', nome: 'Colonoscopia')]),
  OciProcedimento(codigo: '09.02.01.001-8', nome: 'OCI Avaliacao Risco Cirurgico', secundarios: [ProcedimentoSecundario(codigo: '02.11.02.003-6', nome: 'ECG')]),
  OciProcedimento(codigo: '09.02.01.002-6', nome: 'OCI Avaliacao Cardiologica', secundarios: [ProcedimentoSecundario(codigo: '02.11.02.003-6', nome: 'ECG')]),
  OciProcedimento(codigo: '09.02.01.003-4', nome: 'OCI Avaliacao Sindrome Coronariana Cronica', secundarios: [ProcedimentoSecundario(codigo: '02.11.02.003-6', nome: 'ECG'), ProcedimentoSecundario(codigo: '02.11.02.006-0', nome: 'Teste Ergometrico')]),
  OciProcedimento(codigo: '09.02.01.004-2', nome: 'OCI Progressao Avaliacao Coronariana I', secundarios: [ProcedimentoSecundario(codigo: '02.05.01.001-6', nome: 'Ecocardiografia Estresse')]),
  OciProcedimento(codigo: '09.02.01.005-0', nome: 'OCI Progressao Avaliacao Coronariana II', secundarios: [ProcedimentoSecundario(codigo: '02.08.01.003-3', nome: 'Cintilografia Repouso'), ProcedimentoSecundario(codigo: '02.08.01.002-5', nome: 'Cintilografia Estresse')]),
  OciProcedimento(codigo: '09.02.01.006-9', nome: 'OCI Avaliacao Insuficiencia Cardiaca', secundarios: [ProcedimentoSecundario(codigo: '02.11.02.003-6', nome: 'ECG'), ProcedimentoSecundario(codigo: '02.11.02.004-4', nome: 'Holter'), ProcedimentoSecundario(codigo: '02.02.01.079-1', nome: 'BNP')]),
  OciProcedimento(codigo: '09.03.01.001-1', nome: 'OCI Avaliacao Ortopedia Radiologia', secundarios: [ProcedimentoSecundario(codigo: '02.04.01.001-0', nome: 'Radiografia por CID')]),
  OciProcedimento(codigo: '09.03.01.002-0', nome: 'OCI Avaliacao Ortopedia Radiologia e US', secundarios: [ProcedimentoSecundario(codigo: '02.05.02.006-2', nome: 'Ultrassonografia Articulacao')]),
  OciProcedimento(codigo: '09.03.01.003-8', nome: 'OCI Avaliacao Ortopedia Tomografia', secundarios: [ProcedimentoSecundario(codigo: '02.06.01.001-0', nome: 'Tomografia Computadorizada por CID')]),
  OciProcedimento(codigo: '09.03.01.004-6', nome: 'OCI Avaliacao Ortopedia Ressonancia', secundarios: [ProcedimentoSecundario(codigo: '02.07.01.001-0', nome: 'Ressonancia Magnetica por CID')]),
  OciProcedimento(codigo: '09.04.01.001-5', nome: 'OCI Avaliacao Inicial Deficit Auditivo', secundarios: [ProcedimentoSecundario(codigo: '02.11.07.004-1', nome: 'Audiometria Tonal')]),
  OciProcedimento(codigo: '09.04.01.002-3', nome: 'OCI Progressao Avaliacao Deficit Auditivo', secundarios: [ProcedimentoSecundario(codigo: '02.11.07.004-1', nome: 'Audiometria'), ProcedimentoSecundario(codigo: '02.11.07.026-2', nome: 'BERA')]),
  OciProcedimento(codigo: '09.04.01.003-1', nome: 'OCI Avaliacao Nasofaringe e Orofaringe', secundarios: [ProcedimentoSecundario(codigo: '02.09.04.004-1', nome: 'Videolaringoscopia'), ProcedimentoSecundario(codigo: '02.09.04.002-5', nome: 'Laringoscopia')]),
  OciProcedimento(codigo: '09.05.01.001-9', nome: 'OCI Avaliacao Oftalmo 0-8 anos', secundarios: [ProcedimentoSecundario(codigo: '02.11.06.023-2', nome: 'Teste Ortoptico'), ProcedimentoSecundario(codigo: '02.11.06.012-7', nome: 'Mapeamento de Retina')]),
  OciProcedimento(codigo: '09.05.01.002-7', nome: 'OCI Avaliacao de Estrabismo', secundarios: [ProcedimentoSecundario(codigo: '02.11.06.023-2', nome: 'Teste Ortoptico'), ProcedimentoSecundario(codigo: '02.11.06.025-9', nome: 'Tonometria')]),
  OciProcedimento(codigo: '09.05.01.003-5', nome: 'OCI Avaliacao Oftalmo +9 anos', secundarios: [ProcedimentoSecundario(codigo: '02.11.06.025-9', nome: 'Tonometria'), ProcedimentoSecundario(codigo: '02.11.06.012-7', nome: 'Mapeamento de Retina')]),
  OciProcedimento(codigo: '09.05.01.004-3', nome: 'OCI Avaliacao Retinopatia Diabetica', secundarios: [ProcedimentoSecundario(codigo: '02.11.06.012-7', nome: 'Mapeamento de Retina'), ProcedimentoSecundario(codigo: '02.11.06.017-8', nome: 'Retinografia')]),
  OciProcedimento(codigo: '09.05.01.005-1', nome: 'OCI Inicial Oncologia Oftalmologica', secundarios: [ProcedimentoSecundario(codigo: '02.05.02.008-9', nome: 'US Globo Ocular'), ProcedimentoSecundario(codigo: '02.11.06.025-9', nome: 'Tonometria')]),
  OciProcedimento(codigo: '09.05.01.006-0', nome: 'OCI Avaliacao Neuro Oftalmologia', secundarios: [ProcedimentoSecundario(codigo: '02.11.06.003-8', nome: 'Campimetria'), ProcedimentoSecundario(codigo: '02.11.06.022-4', nome: 'Teste de Cores')]),
  OciProcedimento(codigo: '09.05.01.007-8', nome: 'OCI Exames Oftalmo sob Sedacao', secundarios: [ProcedimentoSecundario(codigo: '04.17.01.006-0', nome: 'Sedacao')]),
  OciProcedimento(codigo: '09.06.01.001-2', nome: 'OCI Gin1 Saude da Mulher I', secundarios: [ProcedimentoSecundario(codigo: '02.05.02.018-6', nome: 'US Transvaginal')]),
  OciProcedimento(codigo: '09.06.01.002-0', nome: 'OCI Gin1 Saude da Mulher II', secundarios: [ProcedimentoSecundario(codigo: '02.05.02.016-0', nome: 'US Pelvica')]),
  OciProcedimento(codigo: '09.06.01.003-9', nome: 'OCI Gin2 Sangramento Uterino I', secundarios: [ProcedimentoSecundario(codigo: '02.09.03.001-1', nome: 'Histeroscopia'), ProcedimentoSecundario(codigo: '04.17.01.006-0', nome: 'Sedacao')]),
  OciProcedimento(codigo: '09.06.01.004-7', nome: 'OCI Gin2 Sangramento Uterino II', secundarios: [ProcedimentoSecundario(codigo: '02.01.01.016-0', nome: 'Biopsia Endometrio AMIU')]),
  OciProcedimento(codigo: '09.06.01.005-5', nome: 'OCI Gin3 Endometriose Profunda', secundarios: [ProcedimentoSecundario(codigo: '02.07.03.002-2', nome: 'Ressonancia Bacia Pelve')]),
];

const List<String> statusOptions = [
  'rascunho',
  'solicitado',
  'autorizado',
  'executado',
];

const Map<String, String> ociCategoryPrefix = {
  '09.01.01': 'Cancer',
  '09.02.01': 'Cardiologia',
  '09.03.01': 'Ortopedia',
  '09.04.01': 'Otorrinolaringologia',
  '09.05.01': 'Oftalmologia',
  '09.06.01': 'Ginecologia',
};

String categoriaPorCodigoOci(String codigo) {
  for (final entry in ociCategoryPrefix.entries) {
    if (codigo.startsWith(entry.key)) return entry.value;
  }
  return 'Outros';
}
