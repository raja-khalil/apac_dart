import 'package:apac_backend/src/modules/catalog/controllers/catalog_controller.dart';
import 'package:shelf_router/shelf_router.dart';

Router buildCatalogRoutes(CatalogController controller) {
  final router = Router()
    ..get('/catalog/categorias/principais', controller.listCategoriasProcedimentoPrincipal)
    ..post('/catalog/categorias/principais', controller.createCategoriaProcedimentoPrincipal)
    ..put('/catalog/categorias/principais/<id>', controller.updateCategoriaProcedimentoPrincipal)
    ..delete('/catalog/categorias/principais/<id>', controller.deleteCategoriaProcedimentoPrincipal)
    ..get('/catalog/estabelecimentos', controller.listEstabelecimentos)
    ..post('/catalog/estabelecimentos', controller.createEstabelecimento)
    ..put('/catalog/estabelecimentos/<id>', controller.updateEstabelecimento)
    ..patch('/catalog/estabelecimentos/<id>/status',
        controller.setEstabelecimentoStatus)
    ..delete('/catalog/estabelecimentos/<id>', controller.deleteEstabelecimento)
    ..get('/catalog/procedimentos/principais', controller.listPrincipais)
    ..post('/catalog/procedimentos/principais', controller.createPrincipal)
    ..get('/catalog/procedimentos/secundarios', controller.listSecundarios)
    ..post('/catalog/procedimentos/secundarios', controller.createSecundario)
    ..patch('/catalog/procedimentos/secundarios/<id>/principais',
        controller.setSecundarioPrincipais)
    ..put('/catalog/procedimentos/<id>', controller.updateProcedimento)
    ..patch(
        '/catalog/procedimentos/<id>/status', controller.setProcedimentoStatus)
    ..delete('/catalog/procedimentos/<id>', controller.deleteProcedimento);
  return router;
}
