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
  String? get activeBaseUrl => _resolvedBaseUrl;

  Future<bool> checkHealth() async {
    final baseUrl = await _resolveBaseUrl();
    if (baseUrl == null) return false;
    return _ping(baseUrl);
  }

  Future<List<Laudo>> fetchLaudos({
    String? query,
    String? status,
    String? unidadeCnes,
  }) async {
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

    try {
      return await _executeWithRecovery((baseUrl) async {
        final uri = Uri.parse('$baseUrl/laudos')
            .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
        final response = await _client.get(uri).timeout(const Duration(seconds: 5));
        if (response.statusCode != 200) {
          throw Exception('Falha ao carregar laudos (${response.statusCode}).');
        }

        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (payload['data'] as List<dynamic>?) ?? <dynamic>[];

        return data
            .map((item) => Laudo.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    } on TimeoutException {
      throw Exception('Tempo esgotado ao consultar API.');
    } catch (e) {
      throw Exception('Nao foi possivel conectar na API. $e');
    }
  }

  Future<Laudo> createLaudo(Map<String, dynamic> body) async {
    try {
      return await _executeWithRecovery((baseUrl) async {
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
      });
    } on TimeoutException {
      throw Exception('Tempo esgotado ao salvar laudo.');
    } catch (e) {
      throw Exception('Nao foi possivel salvar. Verifique se o backend esta ativo. $e');
    }
  }

  Future<Laudo> updateLaudo(int id, Map<String, dynamic> body) async {
    try {
      return await _executeWithRecovery((baseUrl) async {
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
      });
    } on TimeoutException {
      throw Exception('Tempo esgotado ao atualizar laudo.');
    } catch (e) {
      throw Exception('Nao foi possivel atualizar. Verifique se o backend esta ativo. $e');
    }
  }

  Future<void> deleteLaudo(int id) async {
    try {
      await _executeWithRecovery((baseUrl) async {
        final response = await _client
            .delete(Uri.parse('$baseUrl/laudos/$id'))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode != 200) {
          throw Exception(_extractError(response.body, response.statusCode));
        }
        return true;
      });
    } on TimeoutException {
      throw Exception('Tempo esgotado ao remover laudo.');
    } catch (e) {
      throw Exception('Nao foi possivel remover. Verifique se o backend esta ativo. $e');
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

  Future<String?> resolveBaseUrl() async {
    return _resolveBaseUrl();
  }

  Future<String?> _resolveBaseUrl() async {
    if (_resolvedBaseUrl != null) {
      final ok = await _ping(_resolvedBaseUrl!);
      if (ok) return _resolvedBaseUrl;
      _resolvedBaseUrl = null;
    }

    final protocol = html.window.location.protocol;
    final host = html.window.location.host;
    final port = html.window.location.port;

    final candidates = _candidateBaseUrls(protocol, host, port);

    for (final candidate in candidates.toSet()) {
      final ok = await _ping(candidate);
      if (ok) {
        _resolvedBaseUrl = candidate;
        return _resolvedBaseUrl;
      }
    }

    return null;
  }

  List<String> _candidateBaseUrls(String protocol, String host, String port) {
    return <String>[
      if (port == '8080') 'http://127.0.0.1:8081/api',
      if (port == '8081') 'http://127.0.0.1:8081/api',
      '$protocol//$host/api',
      'http://127.0.0.1:8081/api',
      'http://127.0.0.1:8080/api',
      'http://localhost:8081/api',
      'http://localhost:8080/api',
    ];
  }

  Future<bool> _ping(String baseUrl) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<T> _executeWithRecovery<T>(Future<T> Function(String baseUrl) action) async {
    final first = await _ensureBaseUrl();
    try {
      return await action(first);
    } catch (_) {
      _resolvedBaseUrl = null;
      final second = await _resolveBaseUrl();
      if (second == null || second == first) rethrow;
      return action(second);
    }
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
