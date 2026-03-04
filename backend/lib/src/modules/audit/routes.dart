import 'package:apac_backend/src/modules/audit/controllers/audit_log_controller.dart';
import 'package:shelf_router/shelf_router.dart';

Router buildAuditRoutes(AuditLogController controller) {
  final router = Router();
  router.get('/audit-logs', controller.index);
  return router;
}
