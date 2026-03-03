import 'package:apac_backend/src/modules/laudo/controllers/laudo_controller.dart';
import 'package:shelf_router/shelf_router.dart';

Router buildLaudoRoutes(LaudoController controller) {
  final router = Router();

  router.get('/laudos', controller.index);
  router.get('/laudos/<id>', controller.show);
  router.post('/laudos', controller.store);
  router.put('/laudos/<id>', controller.update);
  router.delete('/laudos/<id>', controller.destroy);

  return router;
}
