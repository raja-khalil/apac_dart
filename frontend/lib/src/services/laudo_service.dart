import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:apac_frontend/src/models/laudo.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

class LaudoService {
  LaudoService({http.Client? client}) : _client = client ?? BrowserClient();

  final http.Client _client;
  String? _resolvedBaseUrl;

  Future<bool> checkHealth() async {
    final baseUrl = await _resolveBaseUrl();
    if (baseUrl == null) return false;

    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Laudo>> fetchLaudos({
    String? query,
    String? status,
    String? unidadeCnes,
  }) async {
    final baseUrl = await _ensureBaseUrl();

    final queryParams = <String, String>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['q'] = query.trim();
    }
    if (status != null && status.trim().isNotEmpty && status != 'all') {
      queryParams['status'] = status.trim();
    }
    if (unidadeCnes != null && unidadeCnes.trim().isNotEmpty && unidadeCnes != 'all') {
      queryParams['unidade_cnes'] = unidadeCnes.trim();
    }

    final uri = Uri.parse('$baseUrl/laudos').replace(queryParameters: queryParams);

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        throw Exception('Falha ao carregar laudos (${response.statusCode}).');
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (payload['data'] as List<dynamic>?) ?? <dynamic>[];

      return data
          .map((item) => Laudo.fromJson(item as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw Exception('Tempo esgotado ao consultar API em $baseUrl.');
    } catch (e) {
      throw Exception('Nao foi possivel conectar na API em $baseUrl. $e');
    }
  }

  Future<Laudo> createLaudo(Map<String, dynamic> body) async {
    final baseUrl = await _ensureBaseUrl();

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/laudos'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 201) {
        throw Exception(_extractError(response.body, response.statusCode));
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return Laudo.fromJson(payload['data'] as Map<String, dynamic>);
    } on TimeoutException {
      throw Exception('Tempo esgotado ao salvar laudo em $baseUrl.');
    } catch (e) {
      throw Exception('Nao foi possivel salvar. Verifique se o backend esta ativo em $baseUrl. $e');
    }
  }

  Future<Laudo> updateLaudo(int id, Map<String, dynamic> body) async {
    final baseUrl = await _ensureBaseUrl();

    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/laudos/$id'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return Laudo.fromJson(payload['data'] as Map<String, dynamic>);
    } on TimeoutException {
      throw Exception('Tempo esgotado ao atualizar laudo em $baseUrl.');
    } catch (e) {
      throw Exception('Nao foi possivel atualizar. Verifique se o backend esta ativo em $baseUrl. $e');
    }
  }

  Future<void> deleteLaudo(int id) async {
    final baseUrl = await _ensureBaseUrl();

    try {
      final response = await _client
          .delete(Uri.parse('$baseUrl/laudos/$id'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
    } on TimeoutException {
      throw Exception('Tempo esgotado ao remover laudo em $baseUrl.');
    } catch (e) {
      throw Exception('Nao foi possivel remover. Verifique se o backend esta ativo em $baseUrl. $e');
    }
  }

  Future<String> _ensureBaseUrl() async {
    final baseUrl = await _resolveBaseUrl();
    if (baseUrl == null) {
      throw Exception(
        'Backend nao encontrado. Inicie o servidor Shelf (ex.: dart run bin/server.dart) na porta 8081 ou 8080.',
      );
    }
    return baseUrl;
  }

  Future<String?> _resolveBaseUrl() async {
    if (_resolvedBaseUrl != null) {
      return _resolvedBaseUrl;
    }

    final protocol = html.window.location.protocol;
    final host = html.window.location.host;
    final port = html.window.location.port;

    final candidates = <String>[
      if (port == '8080') 'http://localhost:8081/api',
      if (port == '8081') 'http://localhost:8081/api',
      '$protocol//$host/api',
      'http://localhost:8081/api',
      'http://localhost:8080/api',
    ];

    for (final candidate in candidates.toSet()) {
      try {
        final response = await _client
            .get(Uri.parse('$candidate/health'))
            .timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          _resolvedBaseUrl = candidate;
          return _resolvedBaseUrl;
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  String _extractError(String rawBody, int fallbackCode) {
    try {
      final payload = jsonDecode(rawBody) as Map<String, dynamic>;
      final message = payload['error']?.toString() ?? payload['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    } catch (_) {
      return 'Falha na requisicao ($fallbackCode).';
    }
    return 'Falha na requisicao ($fallbackCode).';
  }
}
