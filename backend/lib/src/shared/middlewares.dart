import 'dart:io';

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

