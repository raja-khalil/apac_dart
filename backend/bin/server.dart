import 'dart:convert';
import 'dart:io';

import 'package:apac_backend/src/config/env.dart';
import 'package:apac_backend/src/modules/audit/controllers/audit_log_controller.dart';
import 'package:apac_backend/src/modules/audit/routes.dart';
import 'package:apac_backend/src/modules/auth/controllers/auth_controller.dart';
import 'package:apac_backend/src/modules/auth/routes.dart';
import 'package:apac_backend/src/modules/auth/services/auth_service.dart';
import 'package:apac_backend/src/modules/laudo/controllers/laudo_controller.dart';
import 'package:apac_backend/src/modules/laudo/routes.dart';
import 'package:apac_backend/src/shared/di.dart';
import 'package:apac_backend/src/shared/middlewares.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

Future<void> main() async {
  await configureDependencies();

  final router = Router()
    ..get('/api/health', (Request request) {
      return Response.ok(jsonEncode({'status': 'ok'}));
    })
    ..mount('/api/', buildAuthRoutes(di<AuthController>()).call)
    ..mount('/api/', buildAuditRoutes(di<AuditLogController>()).call)
    ..mount('/api/', buildLaudoRoutes(di<LaudoController>()).call);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addMiddleware(jsonContentTypeMiddleware())
      .addMiddleware(authMiddleware(di<AuthService>()))
      .addHandler(router.call);

  final server =
      await io.serve(handler, EnvConfig.serverHost, EnvConfig.serverPort);

  stdout.writeln(
    'APAC backend online: http://${server.address.host}:${server.port}',
  );
}
