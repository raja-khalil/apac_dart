abstract class ICatalogRepository {
  Future<List<Map<String, dynamic>>> listEstabelecimentos({String? tipo});
  Future<Map<String, dynamic>> createEstabelecimento({
    required String nome,
    required String cnes,
    required String tipo,
  });
  Future<bool> deleteEstabelecimento(int id);

  Future<List<Map<String, dynamic>>> listPrincipais();
  Future<List<Map<String, dynamic>>> listSecundarios();
  Future<Map<String, dynamic>> createProcedimentoSecundario({
    required String codigoSigtap,
    required String descricao,
  });
  Future<Map<String, dynamic>> createProcedimentoPrincipal({
    required String codigoSigtap,
    required String descricao,
    required List<int> secundariosIds,
  });
  Future<bool> deleteProcedimento(int id);
}

