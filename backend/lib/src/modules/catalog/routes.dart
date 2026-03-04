import 'package:apac_backend/src/modules/catalog/controllers/catalog_controller.dart';
import 'package:shelf_router/shelf_router.dart';

Router buildCatalogRoutes(CatalogController controller) {
  final router = Router()
    ..get('/catalog/estabelecimentos', controller.listEstabelecimentos)
    ..post('/catalog/estabelecimentos', controller.createEstabelecimento)
    ..delete('/catalog/estabelecimentos/<id>', controller.deleteEstabelecimento)
    ..get('/catalog/procedimentos/principais', controller.listPrincipais)
    ..post('/catalog/procedimentos/principais', controller.createPrincipal)
    ..get('/catalog/procedimentos/secundarios', controller.listSecundarios)
    ..post('/catalog/procedimentos/secundarios', controller.createSecundario)
    ..delete('/catalog/procedimentos/<id>', controller.deleteProcedimento);
  return router;
}

