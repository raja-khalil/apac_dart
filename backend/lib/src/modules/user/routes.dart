import 'package:apac_backend/src/modules/user/controllers/user_controller.dart';
import 'package:shelf_router/shelf_router.dart';

Router buildUserRoutes(UserController controller) {
  final router = Router();
  router.get('/users', controller.index);
  router.post('/users', controller.store);
  router.put('/users/<id>', controller.update);
  router.delete('/users/<id>', controller.destroy);
  return router;
}
