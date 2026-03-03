import 'dart:convert';

import 'package:apac_frontend/src/models/laudo.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

class LaudoService {
  LaudoService({http.Client? client}) : _client = client ?? BrowserClient();

  final http.Client _client;
  static const String _baseUrl = 'http://localhost:8080/api';

  Future<bool> checkHealth() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/health'));
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

    final uri = Uri.parse('$_baseUrl/laudos').replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar laudos (${response.statusCode}).');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (payload['data'] as List<dynamic>?) ?? <dynamic>[];

    return data
        .map((item) => Laudo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Laudo> createLaudo(Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/laudos'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractError(response.body, response.statusCode));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return Laudo.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<Laudo> updateLaudo(int id, Map<String, dynamic> body) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/laudos/$id'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, response.statusCode));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return Laudo.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<void> deleteLaudo(int id) async {
    final response = await _client.delete(Uri.parse('$_baseUrl/laudos/$id'));
    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, response.statusCode));
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
