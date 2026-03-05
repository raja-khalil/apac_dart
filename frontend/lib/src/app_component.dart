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

  String currentPage = 'login';
  bool isAuthenticated = false;
  bool loggingIn = false;
  bool requestingReset = false;
  bool resettingPassword = false;
  bool showPassword = false;
  bool forgotMode = false;
  String loginEmail = '';
  String loginSenha = '';
  String forgotEmail = '';
  String forgotToken = '';
  String forgotNewPassword = '';
  String? resetInfoMessage;
  String? authMessage;
  String? successMessage;
  Map<String, dynamic>? authUser;
  bool loading = false;
  bool saving = false;
  bool online = false;
  String? errorMessage;
  String apiEndpoint = 'API nao detectada';

  List<Laudo> laudos = <Laudo>[];
  List<Estabelecimento> catalogSolicitantes = <Estabelecimento>[];
  List<Estabelecimento> catalogExecutantes = <Estabelecimento>[];
  List<OciProcedimento> catalogOcis = <OciProcedimento>[];
  List<Map<String, dynamic>> adminCatalogEstabelecimentos =
      <Map<String, dynamic>>[];
  List<Map<String, dynamic>> adminCatalogPrincipais = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> adminCatalogSecundarios = <Map<String, dynamic>>[];

  String dashboardUnidadeFilter = 'all';
  String dashboardMonthFilter = 'all';
  String dashboardDateFrom = '';
  String dashboardDateTo = '';
  String listSearch = '';
  String listStatusFilter = 'all';
  String listMonthFilter = 'all';
  String listDateFrom = '';
  String listDateTo = '';
  String solicitanteSearch = '';
  String ociSearch = '';
  final Set<int> selectedLaudoIds = <int>{};
  bool batchPrintMode = false;

  List<Map<String, dynamic>> adminUsers = <Map<String, dynamic>>[];
  bool adminLoading = false;
  bool adminSaving = false;
  int? adminEditingUserId;
  String adminNome = '';
  String adminEmail = '';
  String adminSenha = '';
  bool adminAtivo = true;
  bool adminRoleFaturista = false;
  bool adminRoleOperador = true;
  bool adminRoleGestor = false;

  String adminNovoEstNome = '';
  String adminNovoEstCnes = '';
  String adminNovoEstTipo = 'solicitante';
  String adminNovoSecCodigo = '';
  String adminNovoSecDescricao = '';
  final Set<int> adminNovoSecPrincipalIds = <int>{};
  String adminNovoPriCodigo = '';
  String adminNovoPriDescricao = '';
  String adminNovoPriCategoria = 'Cardiologia';
  final Set<int> adminNovoPriSecIds = <int>{};
  String adminCatalogEstFiltroTipo = 'all';
  String adminCatalogEstFiltroStatus = 'all';
  int? adminEditEstId;
  String adminEditEstNome = '';
  String adminEditEstCnes = '';
  String adminEditEstTipo = 'solicitante';
  int? adminEditSecId;
  String adminEditSecCodigo = '';
  String adminEditSecDescricao = '';
  final Set<int> adminEditSecPrincipalIds = <int>{};
  int? adminEditPriId;
  String adminEditPriCodigo = '';
  String adminEditPriDescricao = '';
  String adminEditPriCategoria = '';
  final Set<int> adminEditPriSecIds = <int>{};
  bool adminRoleAdmin = false;

  final Map<String, String> _ociCategoriaPorCodigo = <String, String>{};

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

  List<Estabelecimento> get solicitantes {
    final merged = <String, Estabelecimento>{};
    for (final est in estabelecimentosSolicitantes) {
      merged[est.cnes] = est;
    }
    for (final est in catalogSolicitantes) {
      merged[est.cnes] = est;
    }
    final list = merged.values.toList();
    list.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return list;
  }

  List<Estabelecimento> get solicitantesFiltrados {
    final query = solicitanteSearch.toLowerCase().trim();
    if (query.isEmpty) return solicitantes;
    return solicitantes.where((est) {
      return est.nome.toLowerCase().contains(query);
    }).toList();
  }

  List<Estabelecimento> get executantes {
    final merged = <String, Estabelecimento>{};
    for (final est in estabelecimentosExecutantes) {
      merged[est.cnes] = est;
    }
    for (final est in catalogExecutantes) {
      merged[est.cnes] = est;
    }
    final list = merged.values.toList();
    list.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return list;
  }

  List<OciProcedimento> get ocis {
    final merged = <String, OciProcedimento>{};
    for (final oci in ociProcedimentos) {
      merged[oci.codigo] = oci;
    }
    for (final oci in catalogOcis) {
      merged[oci.codigo] = oci;
    }
    final list = merged.values.toList();
    list.sort((a, b) => a.codigo.compareTo(b.codigo));
    return list;
  }

  List<String> get statusList => statusOptions;
  List<Map<String, dynamic>> get adminCatalogEstabelecimentosFiltrados {
    final out = <Map<String, dynamic>>[];
    for (final raw in adminCatalogEstabelecimentos) {
      final item = Map<String, dynamic>.from(raw);
      final tipo = (item['tipo'] ?? '').toString();
      if (adminCatalogEstFiltroTipo != 'all' &&
          tipo != adminCatalogEstFiltroTipo) {
        continue;
      }
      final ativo = isAtivo(item['ativo']);
      if (adminCatalogEstFiltroStatus == 'ativos' && !ativo) continue;
      if (adminCatalogEstFiltroStatus == 'inativos' && ativo) continue;
      out.add(item);
    }
    return out;
  }

  bool get canAccessAdmin => _service.hasRole('admin');
  bool get canWriteLaudo =>
      _service.hasRole('admin') ||
      _service.hasRole('operador') ||
      _service.hasRole('gestor');
  bool get catalogApiAvailable => _service.catalogRoutesAvailable;
  List<Map<String, dynamic>> get adminSecundariosAssociaveis {
    return adminCatalogSecundarios
        .where((s) => idAsInt(s['id']) > 0 && !isCatalogReadOnly(s))
        .toList();
  }

  List<Map<String, dynamic>> get adminPrincipaisAssociaveis {
    return adminCatalogPrincipais
        .where((p) => idAsInt(p['id']) > 0 && !isCatalogReadOnly(p))
        .toList();
  }

  List<String> get adminCategoriasPrincipais {
    final categorias = <String>{
      ...ociCategoryPrefix.values,
    };
    for (final p in adminCatalogPrincipais) {
      final categoria = (p['categoria'] ?? '').toString().trim();
      if (categoria.isNotEmpty) categorias.add(categoria);
    }
    final list = categorias.toList();
    list.sort();
    return list;
  }

  List<String> get ociCategorias {
    final categories =
        ocis.map((o) => _categoriaOci(o.codigo)).toSet().toList();
    categories.sort();
    return categories;
  }

  List<OciProcedimento> ocisPorCategoria(String categoria) {
    final filtered = ocis.where((o) => _categoriaOci(o.codigo) == categoria);
    if (ociSearch.trim().isEmpty) {
      return filtered.toList();
    }
    final q = ociSearch.toLowerCase().trim();
    return filtered
        .where((o) =>
            o.codigo.toLowerCase().contains(q) ||
            o.nome.toLowerCase().contains(q))
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
    final fromDate =
        dashboardDateFrom.isEmpty ? null : DateTime.tryParse(dashboardDateFrom);
    final toDate =
        dashboardDateTo.isEmpty ? null : DateTime.tryParse(dashboardDateTo);

    return laudos.where((l) {
      if (dashboardUnidadeFilter != 'all' &&
          l.unidadeCnes != dashboardUnidadeFilter) {
        return false;
      }
      final createdAt = _parseCreatedAt(l);
      if (dashboardMonthFilter != 'all') {
        if (createdAt == null || _monthKey(createdAt) != dashboardMonthFilter)
          return false;
      }
      if (fromDate != null) {
        if (createdAt == null ||
            createdAt.isBefore(
                DateTime(fromDate.year, fromDate.month, fromDate.day))) {
          return false;
        }
      }
      if (toDate != null) {
        final endExclusive =
            DateTime(toDate.year, toDate.month, toDate.day + 1);
        if (createdAt == null || !createdAt.isBefore(endExclusive)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  String get dashboardUnidadeLabel {
    if (dashboardUnidadeFilter == 'all') return 'Todas as unidades';
    for (final unidade in dashboardUnidades) {
      if (unidade.cnes == dashboardUnidadeFilter) {
        return '${unidade.nome} (CNES ${unidade.cnes})';
      }
    }
    return 'Unidade selecionada';
  }

  List<String> get dashboardAvailableMonths {
    final months = <String>{};
    for (final laudo in laudos) {
      final created = _parseCreatedAt(laudo);
      if (created == null) continue;
      months.add(_monthKey(created));
    }
    final list = months.toList();
    list.sort((a, b) => b.compareTo(a));
    return list;
  }

  List<Laudo> get recentLaudos {
    final copy = List<Laudo>.from(dashboardLaudos);
    copy.sort((a, b) => b.id.compareTo(a.id));
    return copy.take(10).toList();
  }

  List<Laudo> get listLaudos {
    final q = listSearch.toLowerCase().trim();
    final fromDate =
        listDateFrom.isEmpty ? null : DateTime.tryParse(listDateFrom);
    final toDate = listDateTo.isEmpty ? null : DateTime.tryParse(listDateTo);

    final filtered = laudos.where((laudo) {
      final statusOk =
          listStatusFilter == 'all' || laudo.status == listStatusFilter;
      if (!statusOk) return false;

      final createdAt = _parseCreatedAt(laudo);
      if (listMonthFilter != 'all') {
        if (createdAt == null || _monthKey(createdAt) != listMonthFilter)
          return false;
      }

      if (fromDate != null) {
        if (createdAt == null ||
            createdAt.isBefore(
                DateTime(fromDate.year, fromDate.month, fromDate.day))) {
          return false;
        }
      }

      if (toDate != null) {
        final endExclusive =
            DateTime(toDate.year, toDate.month, toDate.day + 1);
        if (createdAt == null || !createdAt.isBefore(endExclusive)) {
          return false;
        }
      }

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

    filtered.sort((a, b) {
      final byName =
          a.nomePaciente.toLowerCase().compareTo(b.nomePaciente.toLowerCase());
      if (byName != 0) return byName;
      final aCreated = _parseCreatedAt(a);
      final bCreated = _parseCreatedAt(b);
      if (aCreated == null && bCreated == null) return 0;
      if (aCreated == null) return 1;
      if (bCreated == null) return -1;
      return aCreated.compareTo(bCreated);
    });

    return filtered;
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
      final groupLaudos = grouped[key] ?? <Laudo>[];
      groupLaudos.sort((a, b) {
        final byName = a.nomePaciente
            .toLowerCase()
            .compareTo(b.nomePaciente.toLowerCase());
        if (byName != 0) return byName;
        final aCreated = _parseCreatedAt(a);
        final bCreated = _parseCreatedAt(b);
        if (aCreated == null && bCreated == null) return 0;
        if (aCreated == null) return 1;
        if (bCreated == null) return -1;
        return aCreated.compareTo(bCreated);
      });
      return LaudoGroup(
        ociCodigo: parts.isNotEmpty ? parts.first : '',
        ociDescricao: parts.length > 1 ? parts.sublist(1).join('|') : '',
        laudos: groupLaudos,
      );
    }).toList();
  }

  List<String> get availableMonths {
    final months = <String>{};
    for (final laudo in laudos) {
      final created = _parseCreatedAt(laudo);
      if (created == null) continue;
      months.add(_monthKey(created));
    }
    final list = months.toList();
    list.sort((a, b) => b.compareTo(a));
    return list;
  }

  String monthLabel(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return key;
    return '${_monthLabel(DateTime(year, month, 1))} $year';
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
      parts.add(
          '${item.color} ${start.toStringAsFixed(2)}deg ${end.toStringAsFixed(2)}deg');
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
    _service.setUnauthorizedHandler(_handleUnauthorizedFromService);
    await _service.resolveBaseUrl();
    apiEndpoint = _service.activeBaseUrl ?? 'API nao detectada';
    online = await _service.checkHealth();
    apiEndpoint = _service.activeBaseUrl ?? apiEndpoint;

    isAuthenticated = await _service.restoreSession();
    authUser = _service.currentUser;

    if (isAuthenticated) {
      currentPage = 'dashboard';
      await refreshAll();
    } else {
      currentPage = 'login';
    }
  }

  Future<void> refreshAll() async {
    loading = true;
    errorMessage = null;
    successMessage = null;

    await _service.resolveBaseUrl();
    apiEndpoint = _service.activeBaseUrl ?? 'API nao detectada';
    online = await _service.checkHealth();
    apiEndpoint = _service.activeBaseUrl ?? apiEndpoint;

    if (!isAuthenticated) {
      loading = false;
      return;
    }

    try {
      laudos = await _service.fetchLaudos();
      await _loadCatalogData();
      _normalizeDashboardUnidadeFilter();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      loading = false;
    }
  }

  Future<void> _loadCatalogData() async {
    final solicitantesRows =
        await _service.fetchCatalogEstabelecimentos(tipo: 'solicitante');
    final executantesRows =
        await _service.fetchCatalogEstabelecimentos(tipo: 'executante');
    final principaisRows = await _service.fetchCatalogPrincipais();
    _ociCategoriaPorCodigo.clear();

    catalogSolicitantes = solicitantesRows
        .map(
          (e) => Estabelecimento(
            cnes: (e['cnes'] ?? '').toString(),
            nome: (e['nome'] ?? '').toString(),
          ),
        )
        .toList();
    catalogExecutantes = executantesRows
        .map(
          (e) => Estabelecimento(
            cnes: (e['cnes'] ?? '').toString(),
            nome: (e['nome'] ?? '').toString(),
          ),
        )
        .toList();
    catalogOcis = principaisRows.map((e) {
      final codigo = (e['codigo_sigtap'] ?? '').toString();
      final categoria = (e['categoria'] ?? '').toString().trim();
      if (codigo.isNotEmpty && categoria.isNotEmpty) {
        _ociCategoriaPorCodigo[codigo] = categoria;
      }
      final secundarios = ((e['secundarios'] as List?) ?? const <dynamic>[])
          .map((s) => Map<String, dynamic>.from(s as Map))
          .map(
            (s) => ProcedimentoSecundario(
              codigo: (s['codigo_sigtap'] ?? '').toString(),
              nome: (s['descricao'] ?? '').toString(),
            ),
          )
          .toList();
      return OciProcedimento(
        codigo: codigo,
        nome: (e['descricao'] ?? '').toString(),
        secundarios: secundarios,
      );
    }).toList();
  }

  void switchPage(String page) {
    if (!isAuthenticated) {
      currentPage = 'login';
      return;
    }
    if (page == 'admin' && !canAccessAdmin) {
      errorMessage =
          'Acesso negado: area administrativa disponivel apenas para perfil admin.';
      return;
    }
    currentPage = page;
    errorMessage = null;
    successMessage = null;
    if (page == 'novo' && editingId == null) {
      viewOnly = false;
      _clearForm();
    }
    if (page == 'laudos') {
      selectedLaudoIds.clear();
      batchPrintMode = false;
    }
    if (page == 'admin') {
      loadAdminUsers();
    }
  }

  Future<void> login() async {
    authMessage = null;
    final email = loginEmail.trim();
    final senha = loginSenha.trim();

    if (email.isEmpty || senha.isEmpty) {
      authMessage = 'Informe email e senha.';
      return;
    }

    try {
      loggingIn = true;
      await _service.login(email: email, senha: senha);
      authUser = _service.currentUser;
      isAuthenticated = true;
      loginSenha = '';
      currentPage = 'dashboard';
      await refreshAll();
    } catch (error) {
      authMessage = _errorText(error);
    } finally {
      loggingIn = false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _logoutLocal('Sessao encerrada.');
  }

  void toggleShowPassword() {
    showPassword = !showPassword;
  }

  void toggleForgotMode() {
    forgotMode = !forgotMode;
    resetInfoMessage = null;
    authMessage = null;
    if (!forgotMode) {
      forgotEmail = '';
      forgotToken = '';
      forgotNewPassword = '';
    } else {
      forgotEmail = loginEmail.trim();
    }
  }

  Future<void> requestPasswordReset() async {
    final email = forgotEmail.trim();
    if (email.isEmpty) {
      authMessage = 'Informe o email para solicitar nova senha.';
      return;
    }
    requestingReset = true;
    authMessage = null;
    resetInfoMessage = null;
    try {
      final data = await _service.forgotPassword(email: email);
      final token = (data['reset_token'] ?? '').toString();
      forgotToken = token;
      resetInfoMessage =
          token.isEmpty ? 'Solicitacao registrada.' : 'Codigo gerado: $token';
    } catch (error) {
      authMessage = _errorText(error);
    } finally {
      requestingReset = false;
    }
  }

  Future<void> resetPassword() async {
    final token = forgotToken.trim();
    final senha = forgotNewPassword.trim();
    if (token.isEmpty || senha.isEmpty) {
      authMessage = 'Informe codigo e nova senha.';
      return;
    }
    resettingPassword = true;
    authMessage = null;
    try {
      await _service.resetPassword(token: token, senha: senha);
      resetInfoMessage =
          'Senha redefinida com sucesso. Faça login com a nova senha.';
      forgotNewPassword = '';
      forgotToken = '';
      forgotMode = false;
    } catch (error) {
      authMessage = _errorText(error);
    } finally {
      resettingPassword = false;
    }
  }

  void _handleUnauthorizedFromService() {
    _logoutLocal('Sessao expirada. Faca login novamente.');
  }

  void _logoutLocal(String message) {
    isAuthenticated = false;
    authUser = null;
    authMessage = message;
    successMessage = null;
    resetInfoMessage = null;
    errorMessage = null;
    laudos = <Laudo>[];
    adminUsers = <Map<String, dynamic>>[];
    resetAdminForm();
    selectedLaudoIds.clear();
    batchPrintMode = false;
    currentPage = 'login';
    forgotMode = false;
    showPassword = false;
    forgotEmail = '';
    forgotToken = '';
    forgotNewPassword = '';
    _clearForm();
  }

  String _errorText(Object error) {
    var text = error.toString();
    text = text.replaceFirst('Exception: ', '').replaceFirst('Bad state: ', '');
    return text;
  }

  void onDashboardUnidadeFilterChanged(dynamic value) {
    final next = (value?.toString() ?? '').trim();
    dashboardUnidadeFilter = (next.isEmpty || next == 'all') ? 'all' : next;
    _normalizeDashboardUnidadeFilter();
  }

  Future<void> submitForm() async {
    if (viewOnly) return;
    if (!canWriteLaudo) {
      errorMessage =
          'Seu perfil permite apenas consulta/impressao. Edicao de laudo nao autorizada.';
      return;
    }

    if (pacienteNome.trim().isEmpty ||
        pacienteCpf.trim().isEmpty ||
        pacienteDataNasc.isEmpty) {
      errorMessage = 'Preencha os campos obrigatorios do paciente.';
      return;
    }

    if (solicitanteCnes.isEmpty ||
        executanteCnes.isEmpty ||
        ociCodigo.isEmpty) {
      errorMessage =
          'Preencha estabelecimento solicitante, executante e OCI principal.';
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
    if (!canWriteLaudo) {
      errorMessage =
          'Seu perfil permite apenas consulta/impressao. Edicao nao autorizada.';
      return;
    }
    viewOnly = false;
    _loadLaudoInForm(laudo);
  }

  void startView(Laudo laudo) {
    viewOnly = true;
    _loadLaudoInForm(laudo);
  }

  void enableEditingFromView() {
    if (!canWriteLaudo) {
      errorMessage =
          'Seu perfil permite apenas consulta/impressao. Edicao nao autorizada.';
      return;
    }
    viewOnly = false;
  }

  void _loadLaudoInForm(Laudo laudo) {
    final payload = laudo.payload;
    final paciente = Map<String, dynamic>.from(
        (payload['paciente'] as Map?) ?? <String, dynamic>{});
    final solicitante = Map<String, dynamic>.from(
        (payload['estabelecimento_solicitante'] as Map?) ??
            <String, dynamic>{});
    final executante = Map<String, dynamic>.from(
        (payload['estabelecimento_executante'] as Map?) ?? <String, dynamic>{});
    final secundarios =
        (payload['procedimentos_secundarios'] as List?) ?? <dynamic>[];

    editingId = laudo.id;
    solicitanteCnes = (solicitante['cnes'] ?? laudo.unidadeCnes).toString();
    solicitanteSearch = '';
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
    pacienteDataNasc =
        (paciente['data_nascimento'] ?? laudo.dataNascimento).toString();
    pacienteResponsavel = (paciente['nome_responsavel'] ?? '').toString();
    pacienteTelefone = (paciente['telefone'] ?? '').toString();
    pacienteLogradouro = (paciente['logradouro'] ?? '').toString();
    pacienteNumero = (paciente['numero'] ?? '').toString();
    pacienteComplemento = (paciente['complemento'] ?? '').toString();
    pacienteBairro = (paciente['bairro'] ?? '').toString();
    if (pacienteLogradouro.isEmpty &&
        (paciente['endereco'] ?? '').toString().isNotEmpty) {
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

    profissionalSolicitante =
        (payload['profissional_solicitante'] ?? '').toString();
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
        secundarioDataExecucao[codigo] =
            (sec['data_execucao'] ?? '').toString();
      }
    }

    currentPage = 'novo';
    errorMessage = null;
  }

  Future<void> removeLaudo(int id) async {
    if (!canWriteLaudo) {
      errorMessage =
          'Seu perfil permite apenas consulta/impressao. Exclusao nao autorizada.';
      return;
    }
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
    documentoSolicitante = _formatDocumentoSolicitante(value?.toString() ?? '');
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
    listMonthFilter = 'all';
    listDateFrom = '';
    listDateTo = '';
  }

  void clearDashboardFilters() {
    dashboardUnidadeFilter = 'all';
    dashboardMonthFilter = 'all';
    dashboardDateFrom = '';
    dashboardDateTo = '';
  }

  bool isSelectedForBatch(int id) => selectedLaudoIds.contains(id);

  void toggleLaudoSelection(int id, bool selected) {
    if (selected) {
      selectedLaudoIds.add(id);
    } else {
      selectedLaudoIds.remove(id);
    }
  }

  bool isGroupFullySelected(LaudoGroup group) {
    if (group.laudos.isEmpty) return false;
    for (final laudo in group.laudos) {
      if (!selectedLaudoIds.contains(laudo.id)) return false;
    }
    return true;
  }

  void toggleGroupSelection(LaudoGroup group, bool selected) {
    for (final laudo in group.laudos) {
      if (selected) {
        selectedLaudoIds.add(laudo.id);
      } else {
        selectedLaudoIds.remove(laudo.id);
      }
    }
  }

  void clearBatchSelection() {
    selectedLaudoIds.clear();
    batchPrintMode = false;
  }

  Future<void> printSelectedLaudos({bool suggestPdf = false}) async {
    if (selectedLaudoIds.isEmpty) {
      errorMessage = 'Selecione ao menos um laudo para imprimir em lote.';
      return;
    }
    batchPrintMode = true;
    errorMessage = null;
    if (suggestPdf) {
      authMessage =
          'Na janela de impressao selecione "Salvar como PDF" para baixar o lote.';
    }
    await Future<void>.delayed(const Duration(milliseconds: 60));
    html.window.print();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    batchPrintMode = false;
  }

  List<Laudo> get selectedLaudosInPrintOrder {
    final ordered = <Laudo>[];
    for (final laudo in listLaudos) {
      if (selectedLaudoIds.contains(laudo.id)) {
        ordered.add(laudo);
      }
    }
    return ordered;
  }

  String payloadText(Laudo laudo, String key, {String fallback = ''}) {
    final value = laudo.payload[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String payloadPacienteText(Laudo laudo, String key, {String fallback = ''}) {
    final paciente = Map<String, dynamic>.from(
        (laudo.payload['paciente'] as Map?) ?? const <String, dynamic>{});
    final value = paciente[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String laudoEnderecoLinha(Laudo laudo) {
    final logradouro = payloadPacienteText(laudo, 'logradouro');
    final numero = payloadPacienteText(laudo, 'numero');
    final complemento = payloadPacienteText(laudo, 'complemento');
    final bairro = payloadPacienteText(laudo, 'bairro');
    final partes = <String>[
      if (logradouro.isNotEmpty) logradouro,
      if (numero.isNotEmpty) 'Nº $numero',
      if (complemento.isNotEmpty) complemento,
      if (bairro.isNotEmpty) bairro,
    ];
    return partes.join(' - ');
  }

  List<Map<String, String>> laudoSecundarios(Laudo laudo) {
    final raw = (laudo.payload['procedimentos_secundarios'] as List?) ??
        const <dynamic>[];
    final data = <Map<String, String>>[];
    for (final item in raw) {
      final mapped = Map<String, dynamic>.from(item as Map);
      data.add({
        'codigo': (mapped['codigo'] ?? '').toString(),
        'nome': (mapped['nome'] ?? '').toString(),
        'data_execucao': (mapped['data_execucao'] ?? '').toString(),
      });
    }
    return data;
  }

  String laudoSecundariosTexto(Laudo laudo) {
    final itens = laudoSecundarios(laudo);
    if (itens.isEmpty) return '';
    final linhas = <String>[];
    for (final s in itens) {
      final codigo = (s['codigo'] ?? '').trim();
      final nome = (s['nome'] ?? '').trim();
      final dataExec = (s['data_execucao'] ?? '').trim();
      var linha = '$codigo - $nome'.trim();
      if (dataExec.isNotEmpty) {
        linha = '$linha (Data: ${formatDate(dataExec)})';
      }
      linhas.add(linha);
    }
    return linhas.join('\n');
  }

  Future<void> loadAdminUsers() async {
    if (!canAccessAdmin) return;
    adminLoading = true;
    try {
      adminUsers = await _service.fetchUsers();
      await _loadAdminCatalog();
    } catch (error) {
      errorMessage = _errorText(error);
    } finally {
      adminLoading = false;
    }
  }

  void resetAdminForm() {
    adminEditingUserId = null;
    adminNome = '';
    adminEmail = '';
    adminSenha = '';
    adminAtivo = true;
    adminRoleAdmin = false;
    adminRoleFaturista = false;
    adminRoleOperador = true;
    adminRoleGestor = false;
  }

  List<String> get _adminFormRoles {
    final roles = <String>[];
    if (adminRoleAdmin) roles.add('admin');
    if (adminRoleFaturista) roles.add('faturista');
    if (adminRoleOperador) roles.add('operador');
    if (adminRoleGestor) roles.add('gestor');
    return roles;
  }

  Future<void> saveAdminUser() async {
    if (!canAccessAdmin) return;
    if (adminNome.trim().isEmpty || adminEmail.trim().isEmpty) {
      errorMessage = 'Preencha nome e email do usuario.';
      return;
    }

    final roles = _adminFormRoles;
    if (roles.isEmpty) {
      errorMessage = 'Selecione ao menos um perfil de acesso.';
      return;
    }

    adminSaving = true;
    errorMessage = null;
    successMessage = null;
    final payload = <String, dynamic>{
      'nome': adminNome.trim(),
      'email': adminEmail.trim(),
      'ativo': adminAtivo,
      'perfis': roles,
    };
    if (adminSenha.trim().isNotEmpty) {
      payload['senha'] = adminSenha.trim();
    }

    try {
      if (adminEditingUserId == null) {
        final result = await _service.createUser(payload);
        final convite = Map<String, dynamic>.from(
          (result['convite'] as Map?) ?? <String, dynamic>{},
        );
        final sent = convite['sent'] == true;
        final fallbackLink = (convite['reset_link'] ?? '').toString();
        if (sent) {
          successMessage = 'Usuario cadastrado. Convite enviado por email.';
        } else if (fallbackLink.isNotEmpty) {
          successMessage =
              'Usuario cadastrado, mas SMTP nao configurado. Link de criacao de senha: $fallbackLink';
        } else {
          successMessage = 'Usuario cadastrado.';
        }
      } else {
        await _service.updateUser(adminEditingUserId!, payload);
        successMessage = 'Usuario atualizado com sucesso.';
      }
      await loadAdminUsers();
      resetAdminForm();
    } catch (error) {
      errorMessage = _errorText(error);
    } finally {
      adminSaving = false;
    }
  }

  void editAdminUser(Map<String, dynamic> user) {
    adminEditingUserId = (user['id'] as num?)?.toInt();
    adminNome = (user['nome'] ?? '').toString();
    adminEmail = (user['email'] ?? '').toString();
    adminSenha = '';
    adminAtivo = user['ativo'] == true || user['ativo'] == 1;
    final roles = ((user['roles'] as List?) ?? const <dynamic>[])
        .map((e) => e.toString().trim().toLowerCase())
        .toSet();
    adminRoleAdmin = roles.contains('admin');
    adminRoleFaturista = roles.contains('faturista');
    adminRoleOperador = roles.contains('operador');
    adminRoleGestor = roles.contains('gestor');
    currentPage = 'admin';
  }

  Future<void> deactivateAdminUser(int id) async {
    if (!canAccessAdmin) return;
    try {
      await _service.deactivateUser(id);
      await loadAdminUsers();
      if (adminEditingUserId == id) {
        resetAdminForm();
      }
    } catch (error) {
      errorMessage = _errorText(error);
    }
  }

  Future<void> activateAdminUser(int id) async {
    if (!canAccessAdmin) return;
    try {
      await _service.updateUser(id, {'ativo': true});
      await loadAdminUsers();
      successMessage = 'Usuario ativado com sucesso.';
    } catch (error) {
      errorMessage = _errorText(error);
    }
  }

  Future<void> _loadAdminCatalog() async {
    final estApi = await _service.fetchCatalogEstabelecimentos(
      includeInativos: true,
    );
    final priApi = await _service.fetchCatalogPrincipais(
      includeInativos: true,
    );
    final secApi = await _service.fetchCatalogSecundarios(
      includeInativos: true,
    );

    final estFallback = _fallbackAdminEstabelecimentos();
    final secFallback = _fallbackAdminSecundarios();
    final priFallback = _fallbackAdminPrincipais(secFallback);

    adminCatalogEstabelecimentos = _mergeCatalogByKey(
      estApi,
      estFallback,
      (m) =>
          '${(m['cnes'] ?? '').toString().trim()}|${(m['nome'] ?? '').toString().trim().toLowerCase()}',
    );
    adminCatalogSecundarios = _mergeCatalogByKey(
      secApi,
      secFallback,
      (m) => (m['codigo_sigtap'] ?? '').toString().trim().toLowerCase(),
    )
        .where((m) => (m['tipo'] ?? 'secundario').toString() == 'secundario')
        .toList();
    adminCatalogPrincipais = _mergeCatalogByKey(
      priApi,
      priFallback,
      (m) => (m['codigo_sigtap'] ?? '').toString().trim().toLowerCase(),
    )
        .where((m) => (m['tipo'] ?? 'principal').toString() == 'principal')
        .toList();

    for (final p in adminCatalogPrincipais) {
      final categoriaAtual = (p['categoria'] ?? '').toString().trim();
      if (categoriaAtual.isEmpty) {
        p['categoria'] =
            categoriaPorCodigoOci((p['codigo_sigtap'] ?? '').toString());
      }
    }
  }

  List<Map<String, dynamic>> _mergeCatalogByKey(
    List<Map<String, dynamic>> primary,
    List<Map<String, dynamic>> fallback,
    String Function(Map<String, dynamic>) keyOf,
  ) {
    final merged = <String, Map<String, dynamic>>{};
    for (final item in fallback) {
      merged[keyOf(item)] = Map<String, dynamic>.from(item);
    }
    for (final item in primary) {
      final normalized = Map<String, dynamic>.from(item);
      normalized['readonly'] = false;
      merged[keyOf(normalized)] = normalized;
    }
    return merged.values.toList();
  }

  List<Map<String, dynamic>> _fallbackAdminEstabelecimentos() {
    final byKey = <String, Map<String, dynamic>>{};
    var id = -1;

    for (final est in estabelecimentosSolicitantes) {
      final key = '${est.cnes}|${est.nome}'.toLowerCase();
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = <String, dynamic>{
          'id': id--,
          'nome': est.nome,
          'cnes': est.cnes,
          'tipo': 'solicitante',
          'ativo': true,
          'readonly': true,
        };
      } else if ((existing['tipo'] ?? '') == 'executante') {
        existing['tipo'] = 'ambos';
      }
    }

    for (final est in estabelecimentosExecutantes) {
      final key = '${est.cnes}|${est.nome}'.toLowerCase();
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = <String, dynamic>{
          'id': id--,
          'nome': est.nome,
          'cnes': est.cnes,
          'tipo': 'executante',
          'ativo': true,
          'readonly': true,
        };
      } else if ((existing['tipo'] ?? '') == 'solicitante') {
        existing['tipo'] = 'ambos';
      }
    }

    final list = byKey.values.toList();
    list.sort((a, b) {
      final an = (a['nome'] ?? '').toString().toLowerCase();
      final bn = (b['nome'] ?? '').toString().toLowerCase();
      return an.compareTo(bn);
    });
    return list;
  }

  List<Map<String, dynamic>> _fallbackAdminSecundarios() {
    final byCode = <String, Map<String, dynamic>>{};
    var id = -200000;
    for (final oci in ociProcedimentos) {
      for (final sec in oci.secundarios) {
        final key = sec.codigo.trim().toLowerCase();
        byCode.putIfAbsent(
          key,
          () => <String, dynamic>{
            'id': id--,
            'codigo_sigtap': sec.codigo,
            'descricao': sec.nome,
            'tipo': 'secundario',
            'ativo': true,
            'readonly': true,
          },
        );
      }
    }
    final list = byCode.values.toList();
    list.sort((a, b) {
      final ac = (a['codigo_sigtap'] ?? '').toString();
      final bc = (b['codigo_sigtap'] ?? '').toString();
      return ac.compareTo(bc);
    });
    return list;
  }

  List<Map<String, dynamic>> _fallbackAdminPrincipais(
    List<Map<String, dynamic>> secundariosFallback,
  ) {
    final secByCode = <String, Map<String, dynamic>>{};
    for (final sec in secundariosFallback) {
      secByCode[(sec['codigo_sigtap'] ?? '').toString().trim().toLowerCase()] =
          sec;
    }

    final list = <Map<String, dynamic>>[];
    var id = -100000;
    for (final oci in ociProcedimentos) {
      final secundarios = <Map<String, dynamic>>[];
      for (final sec in oci.secundarios) {
        final row = secByCode[sec.codigo.trim().toLowerCase()];
        secundarios.add(<String, dynamic>{
          'id': row != null ? idAsInt(row['id']) : 0,
          'codigo_sigtap': sec.codigo,
          'descricao': sec.nome,
          'readonly': true,
        });
      }
      list.add(<String, dynamic>{
        'id': id--,
        'codigo_sigtap': oci.codigo,
        'descricao': oci.nome,
        'categoria': categoriaPorCodigoOci(oci.codigo),
        'tipo': 'principal',
        'ativo': true,
        'readonly': true,
        'secundarios': secundarios,
      });
    }
    list.sort((a, b) {
      final ac = (a['codigo_sigtap'] ?? '').toString();
      final bc = (b['codigo_sigtap'] ?? '').toString();
      return ac.compareTo(bc);
    });
    return list;
  }

  Future<void> createAdminEstabelecimento() async {
    if (adminNovoEstNome.trim().isEmpty) {
      errorMessage = 'Informe o nome do estabelecimento.';
      return;
    }
    if (adminNovoEstCnes.trim().isNotEmpty &&
        adminNovoEstCnes.trim().length != 7) {
      errorMessage = 'CNES deve conter 7 digitos.';
      return;
    }
    try {
      await _service.createCatalogEstabelecimento(
        nome: adminNovoEstNome.trim(),
        cnes: adminNovoEstCnes.trim(),
        tipo: adminNovoEstTipo,
      );
      adminNovoEstNome = '';
      adminNovoEstCnes = '';
      await _loadAdminCatalog();
      await _loadCatalogData();
      successMessage = 'Estabelecimento cadastrado.';
    } catch (error) {
      errorMessage = _errorText(error);
    }
  }

  Future<void> removeAdminEstabelecimento(int id) async {
    try {
      await _service.deleteCatalogEstabelecimento(id);
      await _loadAdminCatalog();
      await _loadCatalogData();
      successMessage = 'Estabelecimento removido.';
    } catch (error) {
      errorMessage = _errorText(error);
    }
  }

  Future<void> createAdminSecundario() async {
    if (adminNovoSecCodigo.trim().isEmpty ||
        adminNovoSecDescricao.trim().isEmpty) {
      errorMessage = 'Informe codigo e descricao do procedimento secundario.';
      return;
    }
    if (adminNovoSecCodigo.trim().length != 14) {
      errorMessage = 'Codigo SIGTAP deve estar no formato 00.00.00.000-0.';
      return;
    }
    try {
      final created = await _service.createCatalogSecundario(
        codigoSigtap: adminNovoSecCodigo.trim(),
        descricao: adminNovoSecDescricao.trim(),
      );
      final secId = idAsInt(created['id']);
      final principaisIds =
          adminNovoSecPrincipalIds.where((e) => e > 0).toList();
      if (secId > 0 && principaisIds.isNotEmpty) {
        await _service.setCatalogSecundarioPrincipais(secId, principaisIds);
      }
      adminNovoSecCodigo = '';
      adminNovoSecDescricao = '';
      adminNovoSecPrincipalIds.clear();
      await _loadAdminCatalog();
      await _loadCatalogData();
      successMessage = 'Procedimento secundario cadastrado.';
    } catch (error) {
      errorMessage = _errorText(error);
    }
  }

  void toggleAdminNovoPriSec(int id, bool checked) {
    if (checked) {
      adminNovoPriSecIds.add(id);
    } else {
      adminNovoPriSecIds.remove(id);
    }
  }

  Future<void> createAdminPrincipal() async {
    if (adminNovoPriCodigo.trim().isEmpty ||
        adminNovoPriDescricao.trim().isEmpty) {
      errorMessage = 'Informe codigo e descricao do procedimento principal.';
      return;
    }
    if (adminNovoPriCodigo.trim().length != 14) {
      errorMessage = 'Codigo SIGTAP deve estar no formato 00.00.00.000-0.';
      return;
    }
    if (adminNovoPriCategoria.trim().isEmpty) {
      errorMessage = 'Informe a categoria do procedimento principal.';
      return;
    }
    try {
      await _service.createCatalogPrincipal(
        codigoSigtap: adminNovoPriCodigo.trim(),
        descricao: adminNovoPriDescricao.trim(),
        categoria: adminNovoPriCategoria.trim(),
        secundariosIds: adminNovoPriSecIds.where((e) => e > 0).toList(),
      );
      adminNovoPriCodigo = '';
      adminNovoPriDescricao = '';
      adminNovoPriCategoria = 'Cardiologia';
      adminNovoPriSecIds.clear();
      await _loadAdminCatalog();
      await _loadCatalogData();
      successMessage = 'Procedimento principal cadastrado.';
    } catch (error) {
      errorMessage = _errorText(error);
    }
  }

  Future<void> removeAdminProcedimento(int id) async {
    try {
      await _service.deleteCatalogProcedimento(id);
      await _loadAdminCatalog();
      await _loadCatalogData();
      successMessage = 'Procedimento removido.';
    } catch (error) {
      errorMessage = _errorText(error);
    }
  }

  void startEditAdminEstabelecimento(Map<String, dynamic> est) {
    adminEditEstId = idAsInt(est['id']);
    adminEditEstNome = (est['nome'] ?? '').toString();
    adminEditEstCnes = (est['cnes'] ?? '').toString();
    adminEditEstTipo = (est['tipo'] ?? 'solicitante').toString();
  }

  void cancelEditAdminEstabelecimento() {
    adminEditEstId = null;
    adminEditEstNome = '';
    adminEditEstCnes = '';
    adminEditEstTipo = 'solicitante';
  }

  Future<void> saveEditAdminEstabelecimento() async {
    if (adminEditEstId == null) return;
    if (adminEditEstNome.trim().isEmpty) {
      errorMessage = 'Informe o nome do estabelecimento.';
      return;
    }
    if (adminEditEstCnes.trim().isNotEmpty &&
        adminEditEstCnes.trim().length != 7) {
      errorMessage = 'CNES deve conter 7 digitos.';
      return;
    }
    try {
      await _service.updateCatalogEstabelecimento(
        adminEditEstId!,
        nome: adminEditEstNome.trim(),
        cnes: adminEditEstCnes.trim(),
        tipo: adminEditEstTipo.trim(),
      );
      await _loadAdminCatalog();
      await _loadCatalogData();
      cancelEditAdminEstabelecimento();
      successMessage = 'Estabelecimento atualizado com sucesso.';
    } catch (error) {
      errorMessage = _errorText(error);
    }
  }

  Future<void> setAdminEstabelecimentoAtivo(int id, bool ativo) async {
    try {
      await _service.setCatalogEstabelecimentoAtivo(id, ativo);
      await _loadAdminCatalog();
      await _loadCatalogData();
      successMessage = ativo
          ? 'Estabelecimento ativado com sucesso.'
          : 'Estabelecimento desativado com sucesso.';
    } catch (error) {
      errorMessage = _errorText(error);
    }
  }

  void startEditAdminSecundario(Map<String, dynamic> sec) {
    adminEditSecId = idAsInt(sec['id']);
    adminEditSecCodigo = (sec['codigo_sigtap'] ?? '').toString();
    adminEditSecDescricao = (sec['descricao'] ?? '').toString();
    adminEditSecPrincipalIds.clear();
    final secId = idAsInt(sec['id']);
    for (final principal in adminCatalogPrincipais) {
      final secundarios =
          (principal['secundarios'] as List?) ?? const <dynamic>[];
      for (final raw in secundarios) {
        final secMap = Map<String, dynamic>.from(raw as Map);
        if (idAsInt(secMap['id']) == secId) {
          adminEditSecPrincipalIds.add(idAsInt(principal['id']));
          break;
        }
      }
    }
  }

  void cancelEditAdminSecundario() {
    adminEditSecId = null;
    adminEditSecCodigo = '';
    adminEditSecDescricao = '';
    adminEditSecPrincipalIds.clear();
  }

  Future<void> saveEditAdminSecundario() async {
    if (adminEditSecId == null) return;
    if (adminEditSecCodigo.trim().isEmpty ||
        adminEditSecDescricao.trim().isEmpty) {
      errorMessage = 'Informe codigo e descricao do procedimento secundario.';
      return;
    }
    if (adminEditSecCodigo.trim().length != 14) {
      errorMessage = 'Codigo SIGTAP deve estar no formato 00.00.00.000-0.';
      return;
    }
    try {
      await _service.updateCatalogProcedimento(
        adminEditSecId!,
        codigoSigtap: adminEditSecCodigo.trim(),
        descricao: adminEditSecDescricao.trim(),
      );
      await _service.setCatalogSecundarioPrincipais(
        adminEditSecId!,
        adminEditSecPrincipalIds.where((e) => e > 0).toList(),
      );
      await _loadAdminCatalog();
      await _loadCatalogData();
      cancelEditAdminSecundario();
      successMessage = 'Procedimento secundario atualizado com sucesso.';
    } catch (error) {
      errorMessage = _errorText(error);
    }
  }

  Future<void> setAdminSecundarioAtivo(int id, bool ativo) async {
    try {
      await _service.setCatalogProcedimentoAtivo(id, ativo);
      await _loadAdminCatalog();
      await _loadCatalogData();
      successMessage = ativo
          ? 'Procedimento secundario ativado com sucesso.'
          : 'Procedimento secundario desativado com sucesso.';
    } catch (error) {
      errorMessage = _errorText(error);
    }
  }

  void startEditAdminPrincipal(Map<String, dynamic> pri) {
    adminEditPriId = idAsInt(pri['id']);
    adminEditPriCodigo = (pri['codigo_sigtap'] ?? '').toString();
    adminEditPriDescricao = (pri['descricao'] ?? '').toString();
    adminEditPriCategoria = (pri['categoria'] ?? '').toString().trim();
    if (adminEditPriCategoria.isEmpty) {
      adminEditPriCategoria = categoriaPorCodigoOci(adminEditPriCodigo);
    }
    adminEditPriSecIds.clear();
    final secundarios = (pri['secundarios'] as List?) ?? const <dynamic>[];
    for (final raw in secundarios) {
      final sec = Map<String, dynamic>.from(raw as Map);
      adminEditPriSecIds.add(idAsInt(sec['id']));
    }
  }

  void cancelEditAdminPrincipal() {
    adminEditPriId = null;
    adminEditPriCodigo = '';
    adminEditPriDescricao = '';
    adminEditPriCategoria = '';
    adminEditPriSecIds.clear();
  }

  void toggleAdminEditPriSec(int id, bool checked) {
    if (checked) {
      adminEditPriSecIds.add(id);
    } else {
      adminEditPriSecIds.remove(id);
    }
  }

  void toggleAdminNovoSecPrincipal(int id, bool checked) {
    if (checked) {
      adminNovoSecPrincipalIds.add(id);
    } else {
      adminNovoSecPrincipalIds.remove(id);
    }
  }

  void toggleAdminEditSecPrincipal(int id, bool checked) {
    if (checked) {
      adminEditSecPrincipalIds.add(id);
    } else {
      adminEditSecPrincipalIds.remove(id);
    }
  }

  Future<void> saveEditAdminPrincipal() async {
    if (adminEditPriId == null) return;
    if (adminEditPriCodigo.trim().isEmpty ||
        adminEditPriDescricao.trim().isEmpty) {
      errorMessage = 'Informe codigo e descricao do procedimento principal.';
      return;
    }
    if (adminEditPriCodigo.trim().length != 14) {
      errorMessage = 'Codigo SIGTAP deve estar no formato 00.00.00.000-0.';
      return;
    }
    if (adminEditPriCategoria.trim().isEmpty) {
      errorMessage = 'Informe a categoria do procedimento principal.';
      return;
    }
    try {
      await _service.updateCatalogProcedimento(
        adminEditPriId!,
        codigoSigtap: adminEditPriCodigo.trim(),
        descricao: adminEditPriDescricao.trim(),
        categoria: adminEditPriCategoria.trim(),
        secundariosIds: adminEditPriSecIds.where((e) => e > 0).toList(),
      );
      await _loadAdminCatalog();
      await _loadCatalogData();
      cancelEditAdminPrincipal();
      successMessage = 'Procedimento principal atualizado com sucesso.';
    } catch (error) {
      errorMessage = _errorText(error);
    }
  }

  Future<void> setAdminPrincipalAtivo(int id, bool ativo) async {
    try {
      await _service.setCatalogProcedimentoAtivo(id, ativo);
      await _loadAdminCatalog();
      await _loadCatalogData();
      successMessage = ativo
          ? 'Procedimento principal ativado com sucesso.'
          : 'Procedimento principal desativado com sucesso.';
    } catch (error) {
      errorMessage = _errorText(error);
    }
  }

  void startViewAndPrint(Laudo laudo) {
    startView(laudo);
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      printLaudo();
    });
  }

  Future<void> deactivateAdminUserByValue(dynamic idValue) async {
    final id = (idValue is num)
        ? idValue.toInt()
        : int.tryParse(idValue?.toString() ?? '');
    if (id == null) return;
    await deactivateAdminUser(id);
  }

  void printLaudo() {
    html.window.print();
  }

  void onAdminNovoEstCnesChanged(String value) {
    final digits = _digitsOnly(value);
    adminNovoEstCnes = digits.length > 7 ? digits.substring(0, 7) : digits;
  }

  void onAdminEditEstCnesChanged(String value) {
    final digits = _digitsOnly(value);
    adminEditEstCnes = digits.length > 7 ? digits.substring(0, 7) : digits;
  }

  void onAdminNovoSecCodigoChanged(String value) {
    adminNovoSecCodigo = _formatCodigoSigtap(value);
  }

  void onAdminNovoPriCodigoChanged(String value) {
    adminNovoPriCodigo = _formatCodigoSigtap(value);
  }

  void onAdminEditSecCodigoChanged(String value) {
    adminEditSecCodigo = _formatCodigoSigtap(value);
  }

  void onAdminEditPriCodigoChanged(String value) {
    adminEditPriCodigo = _formatCodigoSigtap(value);
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

  String userRolesLabel(Map<String, dynamic> user) {
    final roles = ((user['roles'] as List?) ?? const <dynamic>[])
        .map((e) => e.toString())
        .toList();
    if (roles.isEmpty) return 'sem perfil';
    return roles.join(', ');
  }

  int idAsInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool isAtivo(dynamic value) => value == true || value == 1;

  bool isCatalogReadOnly(Map<String, dynamic> item) => item['readonly'] == true;

  String catalogStatusLabel(Map<String, dynamic> item) {
    final base = isAtivo(item['ativo']) ? 'Ativo' : 'Inativo';
    if (isCatalogReadOnly(item)) {
      return '$base (referencia)';
    }
    return base;
  }

  String secundariosCodesText(dynamic list) {
    final rows = (list as List?) ?? const <dynamic>[];
    final codes = <String>[];
    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final code = (row['codigo_sigtap'] ?? '').toString();
      if (code.isNotEmpty) codes.add(code);
    }
    return codes.join(', ');
  }

  String formatDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return _dateFormatter.format(date);
  }

  int monthlyBarHeight(int count) {
    final maxValue =
        monthlyData.fold<int>(0, (maxV, item) => max(maxV, item.count));
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
    return _categoriaOci(code);
  }

  String _categoriaOci(String code) {
    final fromCatalog = _ociCategoriaPorCodigo[code];
    if (fromCatalog != null && fromCatalog.trim().isNotEmpty) {
      return fromCatalog.trim();
    }
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

  DateTime? _parseCreatedAt(Laudo laudo) {
    return DateTime.tryParse(laudo.createdAt);
  }

  String _monthKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    return '${value.year}-$month';
  }

  Estabelecimento? _estabelecimentoByCnes(
      String cnes, List<Estabelecimento> list) {
    for (final item in list) {
      if (item.cnes == cnes) {
        return item;
      }
    }
    return null;
  }

  void _normalizeDashboardUnidadeFilter() {
    if (dashboardUnidadeFilter == 'all') return;
    for (final unidade in dashboardUnidades) {
      if (unidade.cnes == dashboardUnidadeFilter) return;
    }
    dashboardUnidadeFilter = 'all';
  }

  void _clearForm() {
    editingId = null;
    viewOnly = false;

    solicitanteCnes = '';
    solicitanteSearch = '';
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
      final end =
          (start + size > truncated.length) ? truncated.length : start + size;
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
    final p1 =
        truncated.substring(0, truncated.length >= 2 ? 2 : truncated.length);
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
    final base =
        '$letter${baseTail.length >= 2 ? baseTail.substring(0, 2) : baseTail}';
    if (base.length < 3) return base;

    final restSource = baseTail.length > 2 ? baseTail.substring(2) : '';
    final rest =
        restSource.length > 2 ? restSource.substring(0, 2) : restSource;
    return rest.isEmpty ? base : '$base.$rest';
  }

  String _formatDocumentoSolicitante(String input) {
    if (tipoDocumento == 'CPF') {
      return _formatCpf(input);
    }
    return _formatCartaoSus(input);
  }
}
