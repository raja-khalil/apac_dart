import 'dart:convert';
import 'dart:io';

import 'package:apac_backend/src/config/env.dart';
import 'package:apac_backend/src/modules/laudo/controllers/laudo_controller.dart';
import 'package:apac_backend/src/modules/laudo/repositories/laudo_repository.dart';
import 'package:apac_backend/src/modules/laudo/routes.dart';
import 'package:apac_backend/src/shared/middlewares.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

Future<void> main() async {
  await Database.initialize();

  final laudoController = LaudoController(LaudoRepository(Database.connection));

  final router = Router()
    ..get('/api/health', (Request request) {
      return Response.ok(jsonEncode({'status': 'ok'}));
    })
    ..mount('/api/', buildLaudoRoutes(laudoController).call);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addMiddleware(jsonContentTypeMiddleware())
      .addHandler(router.call);

  final server =
      await io.serve(handler, EnvConfig.serverHost, EnvConfig.serverPort);

  stdout.writeln(
    'APAC backend online: http://${server.address.host}:${server.port}',
  );
}
