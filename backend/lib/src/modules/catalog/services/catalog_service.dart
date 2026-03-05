import 'package:apac_backend/src/modules/catalog/repositories/catalog_repository.dart';

class CatalogService {
  CatalogService(this._repository);

  final ICatalogRepository _repository;

  Future<List<Map<String, dynamic>>> listCategoriasProcedimentoPrincipal({
    bool includeInativos = false,
  }) {
    return _repository.listCategoriasProcedimentoPrincipal(
      includeInativos: includeInativos,
    );
  }

  Future<Map<String, dynamic>> createCategoriaProcedimentoPrincipal(
      String nome) {
    return _repository.createCategoriaProcedimentoPrincipal(nome);
  }

  Future<Map<String, dynamic>?> updateCategoriaProcedimentoPrincipal({
    required int id,
    required String nome,
  }) {
    return _repository.updateCategoriaProcedimentoPrincipal(id: id, nome: nome);
  }

  Future<bool> deleteCategoriaProcedimentoPrincipal(int id) {
    return _repository.deleteCategoriaProcedimentoPrincipal(id);
  }

  Future<List<Map<String, dynamic>>> listEstabelecimentos({
    String? tipo,
    bool includeInativos = false,
  }) {
    return _repository.listEstabelecimentos(
      tipo: tipo,
      includeInativos: includeInativos,
    );
  }

  Future<Map<String, dynamic>> createEstabelecimento({
    required String nome,
    required String cnes,
    required String tipo,
  }) {
    return _repository.createEstabelecimento(
        nome: nome, cnes: cnes, tipo: tipo);
  }

  Future<Map<String, dynamic>?> updateEstabelecimento({
    required int id,
    String? nome,
    String? cnes,
    String? tipo,
  }) {
    return _repository.updateEstabelecimento(
      id: id,
      nome: nome,
      cnes: cnes,
      tipo: tipo,
    );
  }

  Future<bool> setEstabelecimentoAtivo(int id, bool ativo) {
    return _repository.setEstabelecimentoAtivo(id, ativo);
  }

  Future<bool> deleteEstabelecimento(int id) =>
      _repository.deleteEstabelecimento(id);

  Future<List<Map<String, dynamic>>> listPrincipais(
          {bool includeInativos = false}) =>
      _repository.listPrincipais(includeInativos: includeInativos);
  Future<List<Map<String, dynamic>>> listSecundarios(
          {bool includeInativos = false}) =>
      _repository.listSecundarios(includeInativos: includeInativos);

  Future<Map<String, dynamic>> createProcedimentoSecundario({
    required String codigoSigtap,
    required String descricao,
  }) {
    return _repository.createProcedimentoSecundario(
      codigoSigtap: codigoSigtap,
      descricao: descricao,
    );
  }

  Future<Map<String, dynamic>> createProcedimentoPrincipal({
    required String codigoSigtap,
    required String descricao,
    required String categoria,
    required List<int> secundariosIds,
  }) {
    return _repository.createProcedimentoPrincipal(
      codigoSigtap: codigoSigtap,
      descricao: descricao,
      categoria: categoria,
      secundariosIds: secundariosIds,
    );
  }

  Future<Map<String, dynamic>?> updateProcedimento({
    required int id,
    String? codigoSigtap,
    String? descricao,
    String? categoria,
    List<int>? secundariosIds,
  }) {
    return _repository.updateProcedimento(
      id: id,
      codigoSigtap: codigoSigtap,
      descricao: descricao,
      categoria: categoria,
      secundariosIds: secundariosIds,
    );
  }

  Future<bool> setSecundarioPrincipais(
      int secundarioId, List<int> principaisIds) {
    return _repository.setSecundarioPrincipais(secundarioId, principaisIds);
  }

  Future<bool> setProcedimentoAtivo(int id, bool ativo) {
    return _repository.setProcedimentoAtivo(id, ativo);
  }

  Future<bool> deleteProcedimento(int id) => _repository.deleteProcedimento(id);
}
