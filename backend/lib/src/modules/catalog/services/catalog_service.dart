import 'package:apac_backend/src/modules/catalog/repositories/catalog_repository.dart';

class CatalogService {
  CatalogService(this._repository);

  final ICatalogRepository _repository;

  Future<List<Map<String, dynamic>>> listEstabelecimentos({String? tipo}) {
    return _repository.listEstabelecimentos(tipo: tipo);
  }

  Future<Map<String, dynamic>> createEstabelecimento({
    required String nome,
    required String cnes,
    required String tipo,
  }) {
    return _repository.createEstabelecimento(nome: nome, cnes: cnes, tipo: tipo);
  }

  Future<bool> deleteEstabelecimento(int id) => _repository.deleteEstabelecimento(id);

  Future<List<Map<String, dynamic>>> listPrincipais() => _repository.listPrincipais();
  Future<List<Map<String, dynamic>>> listSecundarios() => _repository.listSecundarios();

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
    required List<int> secundariosIds,
  }) {
    return _repository.createProcedimentoPrincipal(
      codigoSigtap: codigoSigtap,
      descricao: descricao,
      secundariosIds: secundariosIds,
    );
  }

  Future<bool> deleteProcedimento(int id) => _repository.deleteProcedimento(id);
}

