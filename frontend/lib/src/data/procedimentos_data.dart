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
    required this.categoria,
    required this.secundarios,
  });

  final String codigo;
  final String nome;
  final String categoria;
  final List<ProcedimentoSecundario> secundarios;
}

const List<Estabelecimento> estabelecimentosSolicitantes = [
  Estabelecimento(cnes: '9587918', nome: 'AMBULATORIO DE SAUDE MENTAL RIO DAS OSTRAS'),
  Estabelecimento(cnes: '2275392', nome: 'CENTRO DE SAUDE RIO DAS OSTRAS'),
  Estabelecimento(cnes: '6069134', nome: 'HOSPITAL MUNICIPAL DRA NAELMA MONTEIRO DA SILVA'),
  Estabelecimento(cnes: '3980642', nome: 'CENTRO DE OFTALMOLOGIA NILTON GONCALVES MARINS'),
  Estabelecimento(cnes: '2947358', nome: 'SERVICO DE REFERENCIA A SAUDE DA MULHER'),
  Estabelecimento(cnes: '2275368', nome: 'UNIDADE SAUDE DA FAMILIA CANTAGALO'),
  Estabelecimento(cnes: '2275317', nome: 'UNIDADE BASICA DE SAUDE BOCA DA BARRA'),
  Estabelecimento(cnes: '0106453', nome: 'UPA 24H VALMIR HESPANHOL'),
  Estabelecimento(cnes: '2912295', nome: 'DEPARTAMENTO GERAL DE DIAGNOSTICO'),
  Estabelecimento(cnes: '7831145', nome: 'CEO RIO DAS OSTRAS'),
];

const List<Estabelecimento> estabelecimentosExecutantes = [
  Estabelecimento(cnes: '2275392', nome: 'CENTRO DE SAUDE RIO DAS OSTRAS'),
  Estabelecimento(cnes: '6069134', nome: 'HOSPITAL MUNICIPAL DRA NAELMA MONTEIRO DA SILVA'),
  Estabelecimento(cnes: '3980642', nome: 'CENTRO DE OFTALMOLOGIA NILTON GONCALVES MARINS'),
  Estabelecimento(cnes: '2947358', nome: 'SERVICO DE REFERENCIA A SAUDE DA MULHER'),
];

const List<OciProcedimento> ociProcedimentos = [
  OciProcedimento(
    codigo: '09.01.01.001-4',
    nome: 'OCI Avaliacao Diagnostica Inicial Cancer Mama',
    categoria: 'Cancer',
    secundarios: [ProcedimentoSecundario(codigo: '02.04.03.003-0', nome: 'Mamografia')],
  ),
  OciProcedimento(
    codigo: '09.01.01.005-7',
    nome: 'OCI Investigacao Cancer Colo Utero',
    categoria: 'Cancer',
    secundarios: [
      ProcedimentoSecundario(codigo: '02.01.01.006-6', nome: 'Biopsia Colo'),
      ProcedimentoSecundario(codigo: '02.03.02.008-1', nome: 'Anatomopatologico'),
    ],
  ),
  OciProcedimento(
    codigo: '09.02.01.001-8',
    nome: 'OCI Avaliacao Risco Cirurgico',
    categoria: 'Cardiologia',
    secundarios: [ProcedimentoSecundario(codigo: '02.11.02.003-6', nome: 'ECG')],
  ),
  OciProcedimento(
    codigo: '09.02.01.003-4',
    nome: 'OCI Avaliacao Sindrome Coronariana Cronica',
    categoria: 'Cardiologia',
    secundarios: [
      ProcedimentoSecundario(codigo: '02.11.02.003-6', nome: 'ECG'),
      ProcedimentoSecundario(codigo: '02.11.02.006-0', nome: 'Teste Ergometrico'),
    ],
  ),
  OciProcedimento(
    codigo: '09.03.01.001-1',
    nome: 'OCI Avaliacao Ortopedia Radiologia',
    categoria: 'Ortopedia',
    secundarios: [ProcedimentoSecundario(codigo: '02.04.01.001-0', nome: 'Radiografia por CID')],
  ),
  OciProcedimento(
    codigo: '09.04.01.001-5',
    nome: 'OCI Avaliacao Inicial Deficit Auditivo',
    categoria: 'Otorrinolaringologia',
    secundarios: [ProcedimentoSecundario(codigo: '02.11.07.004-1', nome: 'Audiometria Tonal')],
  ),
  OciProcedimento(
    codigo: '09.05.01.003-5',
    nome: 'OCI Avaliacao Oftalmo +9 anos',
    categoria: 'Oftalmologia',
    secundarios: [
      ProcedimentoSecundario(codigo: '02.11.06.025-9', nome: 'Tonometria'),
      ProcedimentoSecundario(codigo: '02.11.06.012-7', nome: 'Mapeamento de Retina'),
    ],
  ),
  OciProcedimento(
    codigo: '09.06.01.001-2',
    nome: 'OCI Gin1 Saude da Mulher I',
    categoria: 'Ginecologia',
    secundarios: [ProcedimentoSecundario(codigo: '02.05.02.018-6', nome: 'US Transvaginal')],
  ),
  OciProcedimento(
    codigo: '09.06.01.003-9',
    nome: 'OCI Gin2 Sangramento Uterino I',
    categoria: 'Ginecologia',
    secundarios: [
      ProcedimentoSecundario(codigo: '02.09.03.001-1', nome: 'Histeroscopia'),
      ProcedimentoSecundario(codigo: '04.17.01.006-0', nome: 'Sedacao'),
    ],
  ),
];

const List<String> statusOptions = [
  'rascunho',
  'solicitado',
  'autorizado',
  'executado',
];
