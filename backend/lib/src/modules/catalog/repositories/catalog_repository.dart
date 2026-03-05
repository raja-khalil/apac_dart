abstract class ICatalogRepository {
  Future<List<Map<String, dynamic>>> listEstabelecimentos({
    String? tipo,
    bool includeInativos = false,
  });
  Future<Map<String, dynamic>> createEstabelecimento({
    required String nome,
    required String cnes,
    required String tipo,
  });
  Future<Map<String, dynamic>?> updateEstabelecimento({
    required int id,
    String? nome,
    String? cnes,
    String? tipo,
  });
  Future<bool> setEstabelecimentoAtivo(int id, bool ativo);
  Future<bool> deleteEstabelecimento(int id);

  Future<List<Map<String, dynamic>>> listPrincipais(
      {bool includeInativos = false});
  Future<List<Map<String, dynamic>>> listSecundarios(
      {bool includeInativos = false});
  Future<Map<String, dynamic>> createProcedimentoSecundario({
    required String codigoSigtap,
    required String descricao,
  });
  Future<Map<String, dynamic>> createProcedimentoPrincipal({
    required String codigoSigtap,
    required String descricao,
    required String categoria,
    required List<int> secundariosIds,
  });
  Future<Map<String, dynamic>?> updateProcedimento({
    required int id,
    String? codigoSigtap,
    String? descricao,
    String? categoria,
    List<int>? secundariosIds,
  });
  Future<bool> setSecundarioPrincipais(
      int secundarioId, List<int> principaisIds);
  Future<bool> setProcedimentoAtivo(int id, bool ativo);
  Future<bool> deleteProcedimento(int id);
}
