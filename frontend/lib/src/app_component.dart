import 'dart:html' as html;
import 'dart:math';

import 'package:apac_frontend/src/data/procedimentos_data.dart';
import 'package:apac_frontend/src/models/laudo.dart';
import 'package:apac_frontend/src/services/laudo_service.dart';
import 'package:intl/intl.dart';
import 'package:ngdart/angular.dart';
import 'package:ngforms/ngforms.dart';

class MonthlyPoint {
  MonthlyPoint(this.label, this.count);

  final String label;
  final int count;
}

class CategoryPoint {
  CategoryPoint(this.name, this.count, this.color);

  final String name;
  final int count;
  final String color;
}

class LaudoGroup {
  LaudoGroup({
    required this.ociCodigo,
    required this.ociDescricao,
    required this.laudos,
  });

  final String ociCodigo;
  final String ociDescricao;
  final List<Laudo> laudos;
}

@Component(
  selector: 'my-app',
  templateUrl: 'app_component.html',
  styleUrls: ['app_component.css'],
  directives: [coreDirectives, formDirectives],
)
class AppComponent implements OnInit {
  AppComponent() : _service = LaudoService();

  final LaudoService _service;
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  final DateFormat _monthFormatter = DateFormat('MMM');

  String currentPage = 'dashboard';
  bool loading = false;
  bool saving = false;
  bool online = false;
  String? errorMessage;
  String apiEndpoint = 'API nao detectada';

  List<Laudo> laudos = <Laudo>[];

  String dashboardUnidadeFilter = 'all';
  String listSearch = '';
  String listStatusFilter = 'all';
  String ociSearch = '';

  int? editingId;
  bool viewOnly = false;

  String solicitanteCnes = '';
  String executanteCnes = '';
  String ociCodigo = '';
  String status = 'rascunho';

  String pacienteNome = '';
  String pacienteNomeSocial = '';
  String pacienteRegistro = '';
  String pacienteNomeMae = '';
  String pacienteCor = '';
  String pacienteCartaoSus = '';
  String pacienteCpf = '';
  String pacienteDataNasc = '';
  String pacienteResponsavel = '';
  String pacienteTelefone = '';
  String pacienteLogradouro = '';
  String pacienteNumero = '';
  String pacienteComplemento = '';
  String pacienteBairro = '';
  String pacienteMunicipio = 'Rio das Ostras';
  String pacienteIbge = '3304524';
  String pacienteUf = 'RJ';
  String pacienteCep = '';
  String pacienteSexo = '';

  String cid10Principal = '';
  String cid10Secundario = '';
  String cid10Causas = '';
  String descricaoDiagnostico = '';
  String observacoes = '';

  String profissionalSolicitante = '';
  String dataSolicitacao = '';
  String tipoDocumento = 'CPF';
  String documentoSolicitante = '';

  final Map<String, bool> secundarioSelecionado = <String, bool>{};
  final Map<String, String> secundarioDataExecucao = <String, String>{};
  final List<Map<String, String>> procedimentosSecundariosManuais =
      <Map<String, String>>[];

  List<Estabelecimento> get solicitantes => estabelecimentosSolicitantes;
  List<Estabelecimento> get executantes => estabelecimentosExecutantes;
  List<OciProcedimento> get ocis => ociProcedimentos;
  List<String> get statusList => statusOptions;

  List<String> get ociCategorias {
    final categories = ocis.map((o) => categoriaPorCodigoOci(o.codigo)).toSet().toList();
    categories.sort();
    return categories;
  }

  List<OciProcedimento> ocisPorCategoria(String categoria) {
    final filtered = ocis.where((o) => categoriaPorCodigoOci(o.codigo) == categoria);
    if (ociSearch.trim().isEmpty) {
      return filtered.toList();
    }
    final q = ociSearch.toLowerCase().trim();
    return filtered
        .where((o) => o.codigo.toLowerCase().contains(q) || o.nome.toLowerCase().contains(q))
        .toList();
  }

  OciProcedimento? get ociSelecionada {
    for (final oci in ocis) {
      if (oci.codigo == ociCodigo) {
        return oci;
      }
    }
    return null;
  }

  List<ProcedimentoSecundario> get secundariosAtuais {
    return ociSelecionada?.secundarios ?? const <ProcedimentoSecundario>[];
  }

  List<Laudo> get dashboardLaudos {
    if (dashboardUnidadeFilter == 'all') return laudos;
    return laudos.where((l) => l.unidadeCnes == dashboardUnidadeFilter).toList();
  }

  List<Laudo> get recentLaudos {
    final copy = List<Laudo>.from(dashboardLaudos);
    copy.sort((a, b) => b.id.compareTo(a.id));
    return copy.take(10).toList();
  }

  List<Laudo> get listLaudos {
    final q = listSearch.toLowerCase().trim();

    return laudos.where((laudo) {
      final statusOk = listStatusFilter == 'all' || laudo.status == listStatusFilter;
      if (!statusOk) return false;

      if (q.isEmpty) return true;

      final name = laudo.nomePaciente.toLowerCase();
      final cpf = laudo.cpf.replaceAll(RegExp(r'[^0-9]'), '');
      final procCode = laudo.ociCodigo.toLowerCase();
      final procDesc = laudo.ociDescricao.toLowerCase();
      final normalizedQ = q.replaceAll(RegExp(r'[^0-9a-z]'), '');

      return name.contains(q) ||
          cpf.contains(normalizedQ) ||
          procCode.contains(q) ||
          procDesc.contains(q);
    }).toList();
  }

  List<LaudoGroup> get laudosPorOciPrincipal {
    final grouped = <String, List<Laudo>>{};
    for (final laudo in listLaudos) {
      final key = '${laudo.ociCodigo}|${laudo.ociDescricao}';
      grouped.putIfAbsent(key, () => <Laudo>[]).add(laudo);
    }

    final keys = grouped.keys.toList()
      ..sort((a, b) {
        final aCode = a.split('|').first;
        final bCode = b.split('|').first;
        return aCode.compareTo(bCode);
      });

    return keys.map((key) {
      final parts = key.split('|');
      return LaudoGroup(
        ociCodigo: parts.isNotEmpty ? parts.first : '',
        ociDescricao: parts.length > 1 ? parts.sublist(1).join('|') : '',
        laudos: grouped[key] ?? <Laudo>[],
      );
    }).toList();
  }

  String get novoTitulo {
    if (viewOnly) return 'Visualizar Laudo APAC/OCI';
    return editingId == null ? 'Novo Laudo APAC/OCI' : 'Editar Laudo APAC/OCI';
  }

  int get rascunhoCount => _statusCount('rascunho');
  int get solicitadoCount => _statusCount('solicitado');
  int get autorizadoCount => _statusCount('autorizado');
  int get executadoCount => _statusCount('executado');

  List<MonthlyPoint> get monthlyData {
    final now = DateTime.now();
    final result = <MonthlyPoint>[];

    for (var i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final label = _monthLabel(d);
      final count = laudos.where((laudo) {
        final created = DateTime.tryParse(laudo.createdAt);
        if (created == null) return false;
        return created.year == d.year && created.month == d.month;
      }).length;
      result.add(MonthlyPoint(label, count));
    }

    return result;
  }

  List<CategoryPoint> get categoryData {
    const colors = <String>[
      '#2867a8',
      '#2c9db4',
      '#f39a3d',
      '#41a76b',
      '#de5f5f',
      '#67768c',
    ];

    final map = <String, int>{};
    for (final laudo in dashboardLaudos) {
      final category = _categoryForCode(laudo.ociCodigo);
      map[category] = (map[category] ?? 0) + 1;
    }

    final keys = map.keys.toList()..sort();
    final data = <CategoryPoint>[];
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      data.add(CategoryPoint(key, map[key] ?? 0, colors[i % colors.length]));
    }
    return data;
  }

  String get donutStyle {
    final categories = categoryData;
    if (categories.isEmpty) {
      return 'conic-gradient(#cfd8e3 0deg 360deg)';
    }

    final total = categories.fold<int>(0, (sum, item) => sum + item.count);
    var start = 0.0;
    final parts = <String>[];

    for (final item in categories) {
      final sweep = total == 0 ? 0.0 : (item.count / total) * 360.0;
      final end = min(360.0, start + sweep);
      parts.add('${item.color} ${start.toStringAsFixed(2)}deg ${end.toStringAsFixed(2)}deg');
      start = end;
    }

    if (start < 360.0) {
      parts.add('#e5ebf3 ${start.toStringAsFixed(2)}deg 360deg');
    }

    return 'conic-gradient(${parts.join(', ')})';
  }

  List<Estabelecimento> get dashboardUnidades {
    final map = <String, Estabelecimento>{};
    for (final laudo in laudos) {
      if (laudo.unidadeCnes.isEmpty) continue;
      map[laudo.unidadeCnes] = Estabelecimento(
        cnes: laudo.unidadeCnes,
        nome: laudo.unidadeSolicitante,
      );
    }
    return map.values.toList();
  }

  @override
  Future<void> ngOnInit() async {
    await refreshAll();
  }

  Future<void> refreshAll() async {
    loading = true;
    errorMessage = null;

    await _service.resolveBaseUrl();
    apiEndpoint = _service.activeBaseUrl ?? 'API nao detectada';
    online = await _service.checkHealth();
    apiEndpoint = _service.activeBaseUrl ?? apiEndpoint;

    try {
      laudos = await _service.fetchLaudos();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      loading = false;
    }
  }

  void switchPage(String page) {
    currentPage = page;
    errorMessage = null;
    if (page == 'novo' && editingId == null) {
      viewOnly = false;
      _clearForm();
    }
  }

  Future<void> submitForm() async {
    if (viewOnly) return;

    if (pacienteNome.trim().isEmpty || pacienteCpf.trim().isEmpty || pacienteDataNasc.isEmpty) {
      errorMessage = 'Preencha os campos obrigatorios do paciente.';
      return;
    }

    if (solicitanteCnes.isEmpty || executanteCnes.isEmpty || ociCodigo.isEmpty) {
      errorMessage = 'Preencha estabelecimento solicitante, executante e OCI principal.';
      return;
    }

    saving = true;
    errorMessage = null;

    final solicitante = _estabelecimentoByCnes(solicitanteCnes, solicitantes);
    final executante = _estabelecimentoByCnes(executanteCnes, executantes);
    final oci = ociSelecionada;

    final secundarios = <Map<String, dynamic>>[];
    if (oci != null) {
      for (final sec in oci.secundarios) {
        if (secundarioSelecionado[sec.codigo] == true) {
          secundarios.add({
            'codigo': sec.codigo,
            'nome': sec.nome,
            'data_execucao': secundarioDataExecucao[sec.codigo] ?? '',
            'quantidade': 1,
            'origem': 'oci',
          });
        }
      }
    }
    for (final manual in procedimentosSecundariosManuais) {
      final codigo = (manual['codigo'] ?? '').trim();
      final nome = (manual['nome'] ?? '').trim();
      if (codigo.isEmpty || nome.isEmpty) continue;
      secundarios.add({
        'codigo': codigo,
        'nome': nome,
        'data_execucao': (manual['data_execucao'] ?? '').trim(),
        'quantidade': 1,
        'origem': 'manual',
      });
    }

    final payload = <String, dynamic>{
      'nome_paciente': pacienteNome.trim(),
      'nome_social': pacienteNomeSocial.trim(),
      'cpf': pacienteCpf.trim(),
      'cartao_sus': pacienteCartaoSus.trim(),
      'data_nascimento': pacienteDataNasc,
      'sexo': pacienteSexo,
      'endereco_logradouro': pacienteLogradouro.trim(),
      'endereco_numero': pacienteNumero.trim(),
      'endereco_complemento': pacienteComplemento.trim(),
      'endereco_bairro': pacienteBairro.trim(),
      'oci_codigo': ociCodigo,
      'oci_descricao': oci?.nome ?? '',
      'unidade_solicitante': solicitante?.nome ?? '',
      'unidade_cnes': solicitante?.cnes ?? '',
      'status': status,
      'estabelecimento_solicitante': {
        'cnes': solicitante?.cnes ?? '',
        'nome': solicitante?.nome ?? '',
      },
      'estabelecimento_executante': {
        'cnes': executante?.cnes ?? '',
        'nome': executante?.nome ?? '',
      },
      'paciente': {
        'nome': pacienteNome,
        'nome_social': pacienteNomeSocial,
        'registro': pacienteRegistro,
        'nome_mae': pacienteNomeMae,
        'cor': pacienteCor,
        'cartao_sus': pacienteCartaoSus,
        'cpf': pacienteCpf,
        'data_nascimento': pacienteDataNasc,
        'sexo': pacienteSexo,
        'nome_responsavel': pacienteResponsavel,
        'telefone': pacienteTelefone,
        'logradouro': pacienteLogradouro,
        'numero': pacienteNumero,
        'complemento': pacienteComplemento,
        'bairro': pacienteBairro,
        'endereco':
            '${pacienteLogradouro.trim()} ${pacienteNumero.trim()} ${pacienteComplemento.trim()} ${pacienteBairro.trim()}'
                .trim(),
        'municipio': pacienteMunicipio,
        'ibge': pacienteIbge,
        'uf': pacienteUf,
        'cep': pacienteCep,
      },
      'procedimento_principal': {
        'codigo': ociCodigo,
        'descricao': oci?.nome ?? '',
        'quantidade': 1,
      },
      'procedimentos_secundarios': secundarios,
      'cid10_principal': cid10Principal,
      'cid10_secundario': cid10Secundario,
      'cid10_causas_associadas': cid10Causas,
      'descricao_diagnostico': descricaoDiagnostico,
      'observacoes': observacoes,
      'profissional_solicitante': profissionalSolicitante,
      'documento_solicitante': documentoSolicitante,
      'tipo_documento': tipoDocumento,
      'data_solicitacao': dataSolicitacao,
    };

    try {
      if (editingId == null) {
        await _service.createLaudo(payload);
      } else {
        await _service.updateLaudo(editingId!, payload);
      }
      await refreshAll();
      _clearForm();
      currentPage = 'laudos';
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      saving = false;
    }
  }

  void startEdit(Laudo laudo) {
    viewOnly = false;
    _loadLaudoInForm(laudo);
  }

  void startView(Laudo laudo) {
    viewOnly = true;
    _loadLaudoInForm(laudo);
  }

  void enableEditingFromView() {
    viewOnly = false;
  }

  void _loadLaudoInForm(Laudo laudo) {
    final payload = laudo.payload;
    final paciente = Map<String, dynamic>.from((payload['paciente'] as Map?) ?? <String, dynamic>{});
    final solicitante = Map<String, dynamic>.from((payload['estabelecimento_solicitante'] as Map?) ?? <String, dynamic>{});
    final executante = Map<String, dynamic>.from((payload['estabelecimento_executante'] as Map?) ?? <String, dynamic>{});
    final secundarios = (payload['procedimentos_secundarios'] as List?) ?? <dynamic>[];

    editingId = laudo.id;
    solicitanteCnes = (solicitante['cnes'] ?? laudo.unidadeCnes).toString();
    executanteCnes = (executante['cnes'] ?? '').toString();
    ociCodigo = laudo.ociCodigo;
    status = laudo.status;

    pacienteNome = (paciente['nome'] ?? laudo.nomePaciente).toString();
    pacienteNomeSocial = (paciente['nome_social'] ?? '').toString();
    pacienteRegistro = (paciente['registro'] ?? '').toString();
    pacienteNomeMae = (paciente['nome_mae'] ?? '').toString();
    pacienteCor = (paciente['cor'] ?? '').toString();
    pacienteCartaoSus = (paciente['cartao_sus'] ?? '').toString();
    pacienteCpf = (paciente['cpf'] ?? laudo.cpf).toString();
    pacienteDataNasc = (paciente['data_nascimento'] ?? laudo.dataNascimento).toString();
    pacienteResponsavel = (paciente['nome_responsavel'] ?? '').toString();
    pacienteTelefone = (paciente['telefone'] ?? '').toString();
    pacienteLogradouro = (paciente['logradouro'] ?? '').toString();
    pacienteNumero = (paciente['numero'] ?? '').toString();
    pacienteComplemento = (paciente['complemento'] ?? '').toString();
    pacienteBairro = (paciente['bairro'] ?? '').toString();
    if (pacienteLogradouro.isEmpty && (paciente['endereco'] ?? '').toString().isNotEmpty) {
      pacienteLogradouro = (paciente['endereco'] ?? '').toString();
    }
    pacienteMunicipio = (paciente['municipio'] ?? 'Rio das Ostras').toString();
    pacienteIbge = (paciente['ibge'] ?? '3304524').toString();
    pacienteUf = (paciente['uf'] ?? 'RJ').toString();
    pacienteCep = (paciente['cep'] ?? '').toString();
    pacienteSexo = (paciente['sexo'] ?? '').toString();

    cid10Principal = (payload['cid10_principal'] ?? '').toString();
    cid10Secundario = (payload['cid10_secundario'] ?? '').toString();
    cid10Causas = (payload['cid10_causas_associadas'] ?? '').toString();
    descricaoDiagnostico = (payload['descricao_diagnostico'] ?? '').toString();
    observacoes = (payload['observacoes'] ?? '').toString();

    profissionalSolicitante = (payload['profissional_solicitante'] ?? '').toString();
    documentoSolicitante = (payload['documento_solicitante'] ?? '').toString();
    tipoDocumento = (payload['tipo_documento'] ?? 'CPF').toString();
    dataSolicitacao = (payload['data_solicitacao'] ?? '').toString();

    secundarioSelecionado.clear();
    secundarioDataExecucao.clear();
    procedimentosSecundariosManuais.clear();
    for (final item in secundarios) {
      final sec = Map<String, dynamic>.from(item as Map);
      final codigo = (sec['codigo'] ?? '').toString();
      if (codigo.isEmpty) continue;
      final origem = (sec['origem'] ?? 'oci').toString();
      if (origem == 'manual') {
        procedimentosSecundariosManuais.add({
          'codigo': codigo,
          'nome': (sec['nome'] ?? '').toString(),
          'data_execucao': (sec['data_execucao'] ?? '').toString(),
        });
      } else {
        secundarioSelecionado[codigo] = true;
        secundarioDataExecucao[codigo] = (sec['data_execucao'] ?? '').toString();
      }
    }

    currentPage = 'novo';
    errorMessage = null;
  }

  Future<void> removeLaudo(int id) async {
    try {
      await _service.deleteLaudo(id);
      await refreshAll();
      if (editingId == id) {
        _clearForm();
      }
    } catch (error) {
      errorMessage = error.toString();
    }
  }

  void toggleSecundario(String codigo, bool selected) {
    secundarioSelecionado[codigo] = selected;
    if (!selected) {
      secundarioDataExecucao.remove(codigo);
    }
  }

  void handleOciChange() {
    secundarioSelecionado.clear();
    secundarioDataExecucao.clear();
  }

  void onPacienteCpfChanged(dynamic value) {
    pacienteCpf = _formatCpf(value?.toString() ?? '');
  }

  void onPacienteCartaoSusChanged(dynamic value) {
    pacienteCartaoSus = _formatCartaoSus(value?.toString() ?? '');
  }

  void onPacienteTelefoneChanged(dynamic value) {
    pacienteTelefone = _formatTelefone(value?.toString() ?? '');
  }

  void onPacienteCepChanged(dynamic value) {
    pacienteCep = _formatCep(value?.toString() ?? '');
  }

  void onCid10PrincipalChanged(dynamic value) {
    cid10Principal = _formatCid10(value?.toString() ?? '');
  }

  void onCid10SecundarioChanged(dynamic value) {
    cid10Secundario = _formatCid10(value?.toString() ?? '');
  }

  void onCid10CausasChanged(dynamic value) {
    cid10Causas = _formatCid10(value?.toString() ?? '');
  }

  void onTipoDocumentoChanged(dynamic value) {
    final next = value?.toString() ?? 'CPF';
    tipoDocumento = next;
    documentoSolicitante = _formatDocumentoSolicitante(documentoSolicitante);
  }

  void onDocumentoSolicitanteChanged(dynamic value) {
    documentoSolicitante =
        _formatDocumentoSolicitante(value?.toString() ?? '');
  }

  int get documentoMaskMaxLength => tipoDocumento == 'CPF' ? 14 : 18;

  String get documentoMaskPlaceholder =>
      tipoDocumento == 'CPF' ? '000.000.000-00' : '000 0000 0000 0000';

  void addProcedimentoSecundarioManual() {
    procedimentosSecundariosManuais.add({
      'codigo': '',
      'nome': '',
      'data_execucao': '',
    });
  }

  void removeProcedimentoSecundarioManual(int index) {
    if (index < 0 || index >= procedimentosSecundariosManuais.length) return;
    procedimentosSecundariosManuais.removeAt(index);
  }

  void onManualSecCodigoChanged(int index, dynamic value) {
    if (index < 0 || index >= procedimentosSecundariosManuais.length) return;
    procedimentosSecundariosManuais[index]['codigo'] =
        _formatCodigoSigtap(value?.toString() ?? '');
  }

  Future<void> tentarReconectarApi() async {
    await refreshAll();
  }

  void clearFilters() {
    listSearch = '';
    listStatusFilter = 'all';
  }

  void printLaudo() {
    html.window.print();
  }

  String statusLabel(String value) {
    switch (value) {
      case 'solicitado':
        return 'Solicitado';
      case 'autorizado':
        return 'Autorizado';
      case 'executado':
        return 'Executado';
      default:
        return 'Rascunho';
    }
  }

  String statusClass(String value) {
    switch (value) {
      case 'solicitado':
        return 'tag solicitado';
      case 'autorizado':
        return 'tag autorizado';
      case 'executado':
        return 'tag executado';
      default:
        return 'tag rascunho';
    }
  }

  String formatDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return _dateFormatter.format(date);
  }

  int monthlyBarHeight(int count) {
    final maxValue = monthlyData.fold<int>(0, (maxV, item) => max(maxV, item.count));
    if (maxValue == 0) return 4;
    final height = ((count / maxValue) * 100).round();
    return max(4, height);
  }

  int categoryPercent(int count) {
    final total = categoryData.fold<int>(0, (sum, c) => sum + c.count);
    if (total == 0) return 0;
    return ((count / total) * 100).round();
  }

  int _statusCount(String value) {
    return dashboardLaudos.where((laudo) => laudo.status == value).length;
  }

  String _categoryForCode(String code) {
    return categoriaPorCodigoOci(code);
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _monthLabel(DateTime value) {
    const labels = <int, String>{
      1: 'Jan.',
      2: 'Fev.',
      3: 'Mar.',
      4: 'Abr.',
      5: 'Mai.',
      6: 'Jun.',
      7: 'Jul.',
      8: 'Ago.',
      9: 'Set.',
      10: 'Out.',
      11: 'Nov.',
      12: 'Dez.',
    };
    return labels[value.month] ?? _capitalize(_monthFormatter.format(value));
  }

  Estabelecimento? _estabelecimentoByCnes(String cnes, List<Estabelecimento> list) {
    for (final item in list) {
      if (item.cnes == cnes) {
        return item;
      }
    }
    return null;
  }

  void _clearForm() {
    editingId = null;
    viewOnly = false;

    solicitanteCnes = '';
    executanteCnes = '';
    ociCodigo = '';
    status = 'rascunho';

    pacienteNome = '';
    pacienteNomeSocial = '';
    pacienteRegistro = '';
    pacienteNomeMae = '';
    pacienteCor = '';
    pacienteCartaoSus = '';
    pacienteCpf = '';
    pacienteDataNasc = '';
    pacienteResponsavel = '';
    pacienteTelefone = '';
    pacienteLogradouro = '';
    pacienteNumero = '';
    pacienteComplemento = '';
    pacienteBairro = '';
    pacienteMunicipio = 'Rio das Ostras';
    pacienteIbge = '3304524';
    pacienteUf = 'RJ';
    pacienteCep = '';
    pacienteSexo = '';

    cid10Principal = '';
    cid10Secundario = '';
    cid10Causas = '';
    descricaoDiagnostico = '';
    observacoes = '';

    profissionalSolicitante = '';
    dataSolicitacao = '';
    tipoDocumento = 'CPF';
    documentoSolicitante = '';

    secundarioSelecionado.clear();
    secundarioDataExecucao.clear();
    procedimentosSecundariosManuais.clear();
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _formatCpf(String input) {
    final digits = _digitsOnly(input);
    final truncated = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < truncated.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(truncated[i]);
    }
    return buffer.toString();
  }

  String _formatCartaoSus(String input) {
    final digits = _digitsOnly(input);
    final truncated = digits.length > 15 ? digits.substring(0, 15) : digits;
    final groups = <int>[3, 4, 4, 4];
    var start = 0;
    final chunks = <String>[];
    for (final size in groups) {
      if (start >= truncated.length) break;
      final end = (start + size > truncated.length) ? truncated.length : start + size;
      chunks.add(truncated.substring(start, end));
      start = end;
    }
    return chunks.join(' ');
  }

  String _formatTelefone(String input) {
    final digits = _digitsOnly(input);
    final truncated = digits.length > 11 ? digits.substring(0, 11) : digits;
    if (truncated.isEmpty) return '';

    if (truncated.length <= 2) return '($truncated';
    final ddd = truncated.substring(0, 2);
    final rest = truncated.substring(2);

    if (rest.length <= 4) return '($ddd) $rest';
    if (rest.length <= 8) {
      return '($ddd) ${rest.substring(0, 4)}-${rest.substring(4)}';
    }
    return '($ddd) ${rest.substring(0, 5)}-${rest.substring(5)}';
  }

  String _formatCep(String input) {
    final digits = _digitsOnly(input);
    final truncated = digits.length > 8 ? digits.substring(0, 8) : digits;
    if (truncated.length <= 5) return truncated;
    return '${truncated.substring(0, 5)}-${truncated.substring(5)}';
  }

  String _formatCodigoSigtap(String input) {
    final digits = _digitsOnly(input);
    final truncated = digits.length > 10 ? digits.substring(0, 10) : digits;
    final parts = <String>[];

    if (truncated.isEmpty) return '';
    final p1 = truncated.substring(0, truncated.length >= 2 ? 2 : truncated.length);
    parts.add(p1);
    if (truncated.length <= 2) return parts.first;

    final p2End = truncated.length >= 4 ? 4 : truncated.length;
    parts.add(truncated.substring(2, p2End));
    if (truncated.length <= 4) return '${parts[0]}.${parts[1]}';

    final p3End = truncated.length >= 6 ? 6 : truncated.length;
    parts.add(truncated.substring(4, p3End));
    if (truncated.length <= 6) return '${parts[0]}.${parts[1]}.${parts[2]}';

    final p4End = truncated.length >= 9 ? 9 : truncated.length;
    final p4 = truncated.substring(6, p4End);
    if (truncated.length <= 9) return '${parts[0]}.${parts[1]}.${parts[2]}.$p4';

    final p5 = truncated.substring(9, 10);
    return '${parts[0]}.${parts[1]}.${parts[2]}.$p4-$p5';
  }

  String _formatCid10(String input) {
    final raw = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (raw.isEmpty) return '';

    final letterMatch = RegExp(r'[A-Z]').firstMatch(raw);
    if (letterMatch == null) return '';
    final letter = letterMatch.group(0)!;
    final afterLetter = raw.substring(letterMatch.start + 1);
    final baseTail = afterLetter.replaceAll(RegExp(r'[^0-9A-Z]'), '');
    final base = '$letter${baseTail.length >= 2 ? baseTail.substring(0, 2) : baseTail}';
    if (base.length < 3) return base;

    final restSource = baseTail.length > 2 ? baseTail.substring(2) : '';
    final rest = restSource.length > 2 ? restSource.substring(0, 2) : restSource;
    return rest.isEmpty ? base : '$base.$rest';
  }

  String _formatDocumentoSolicitante(String input) {
    if (tipoDocumento == 'CPF') {
      return _formatCpf(input);
    }
    return _formatCartaoSus(input);
  }
}

