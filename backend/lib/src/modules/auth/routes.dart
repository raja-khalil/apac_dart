import 'package:apac_backend/src/modules/auth/controllers/auth_controller.dart';
import 'package:shelf_router/shelf_router.dart';

Router buildAuthRoutes(AuthController controller) {
  final router = Router();

  router.post('/auth/register', controller.register);
  router.post('/auth/login', controller.login);
  router.post('/auth/forgot-password', controller.forgotPassword);
  router.post('/auth/reset-password', controller.resetPassword);
  router.get('/auth/me', controller.me);
  router.post('/auth/logout', controller.logout);

  return router;
}
