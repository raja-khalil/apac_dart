import 'dart:io';

import 'package:apac_backend/src/modules/auth/services/auth_service.dart';
import 'package:shelf/shelf.dart';

Middleware corsMiddleware() {
  return (innerHandler) {
    return (request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }

      final response = await innerHandler(request);
      return response.change(headers: {
        ...response.headers,
        ..._corsHeaders,
      });
    };
  };
}

const Map<String, String> _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
};

Middleware jsonContentTypeMiddleware() {
  return (innerHandler) {
    return (request) async {
      final response = await innerHandler(request);
      if (response.headers.containsKey(HttpHeaders.contentTypeHeader)) {
        return response;
      }

      return response.change(headers: {
        ...response.headers,
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
      });
    };
  };
}

Middleware authMiddleware(AuthService authService) {
  const publicPaths = <String>{
    '/api/health',
    '/api/auth/login',
    '/api/auth/register',
  };

  return (innerHandler) {
    return (request) async {
      final path = '/${request.url.path}';
      if (publicPaths.contains(path)) {
        return innerHandler(request);
      }

      final auth = request.headers['authorization'] ?? '';
      if (!auth.toLowerCase().startsWith('bearer ')) {
        return Response(
          401,
          body: '{"error":"Nao autenticado."}',
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final token = auth.substring(7).trim();
      final user = await authService.authenticate(token);
      if (user == null) {
        return Response(
          401,
          body: '{"error":"Token invalido ou expirado."}',
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }

      return innerHandler(
        request.change(context: {
          ...request.context,
          'auth_user': user,
          'auth_user_id': user['id'],
        }),
      );
    };
  };
}
