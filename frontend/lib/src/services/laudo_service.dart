import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:apac_frontend/src/models/laudo.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

class UnauthorizedException implements Exception {
  UnauthorizedException([this.message = 'Nao autenticado.']);

  final String message;

  @override
  String toString() => message;
}

class LaudoService {
  LaudoService({http.Client? client}) : _client = client ?? BrowserClient() {
    _accessToken = html.window.localStorage[_tokenStorageKey];
    _tokenExpiresAt = html.window.localStorage[_tokenExpiresStorageKey];
    final rawUser = html.window.localStorage[_userStorageKey];
    if (rawUser != null && rawUser.trim().isNotEmpty) {
      try {
        _currentUser = Map<String, dynamic>.from(jsonDecode(rawUser) as Map);
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  final http.Client _client;
  static const String _tokenStorageKey = 'apac_auth_token';
  static const String _tokenExpiresStorageKey = 'apac_auth_expires_at';
  static const String _userStorageKey = 'apac_auth_user';

  String? _resolvedBaseUrl;
  String? _accessToken;
  String? _tokenExpiresAt;
  Map<String, dynamic>? _currentUser;
  void Function()? _onUnauthorized;

  String? get activeBaseUrl => _resolvedBaseUrl;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;
  Map<String, dynamic>? get currentUser => _currentUser;
  List<String> get currentRoles =>
      ((currentUser?['roles'] as List?) ?? const <dynamic>[])
          .map((e) => e.toString().trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();

  bool hasRole(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return currentRoles.contains(normalized);
  }

  void setUnauthorizedHandler(void Function()? handler) {
    _onUnauthorized = handler;
  }

  Future<bool> restoreSession() async {
    if (!isAuthenticated) return false;
    final me = await fetchMe();
    return me != null;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    return _executeWithRecovery((baseUrl) async {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _headers(includeJson: true),
            body: jsonEncode({'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = Map<String, dynamic>.from(
        (payload['data'] as Map?) ?? <String, dynamic>{},
      );
      _saveSession(data);
      return data;
    });
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    return _executeWithRecovery((baseUrl) async {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/forgot-password'),
            headers: _headers(includeJson: true),
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return Map<String, dynamic>.from(
          (payload['data'] as Map?) ?? <String, dynamic>{});
    });
  }

  Future<void> resetPassword({
    required String token,
    required String senha,
  }) async {
    await _executeWithRecovery((baseUrl) async {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/reset-password'),
            headers: _headers(includeJson: true),
            body: jsonEncode({'token': token, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
      return true;
    });
  }

  Future<Map<String, dynamic>> register({
    required String nome,
    required String email,
    required String senha,
  }) async {
    return _executeWithRecovery((baseUrl) async {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: _headers(includeJson: true),
            body: jsonEncode({'nome': nome, 'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 201) {
        throw Exception(_extractError(response.body, response.statusCode));
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return Map<String, dynamic>.from(
        (payload['data'] as Map?) ?? <String, dynamic>{},
      );
    });
  }

  Future<Map<String, dynamic>?> fetchMe() async {
    if (!isAuthenticated) return null;

    try {
      return await _executeWithRecovery((baseUrl) async {
        final response = await _client
            .get(Uri.parse('$baseUrl/auth/me'), headers: _headers())
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 401) {
          _handleUnauthorized();
          return null;
        }

        if (response.statusCode != 200) {
          throw Exception(_extractError(response.body, response.statusCode));
        }

        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final data = Map<String, dynamic>.from(
          (payload['data'] as Map?) ?? <String, dynamic>{},
        );
        _currentUser = data;
        html.window.localStorage[_userStorageKey] = jsonEncode(data);
        return data;
      });
    } on UnauthorizedException {
      return null;
    }
  }

  Future<void> logout() async {
    if (isAuthenticated) {
      try {
        await _executeWithRecovery((baseUrl) async {
          await _client
              .post(Uri.parse('$baseUrl/auth/logout'), headers: _headers())
              .timeout(const Duration(seconds: 4));
          return true;
        });
      } catch (_) {
        // Clear local session even if backend logout fails.
      }
    }
    clearSession();
  }

  void clearSession() {
    _accessToken = null;
    _tokenExpiresAt = null;
    _currentUser = null;
    html.window.localStorage.remove(_tokenStorageKey);
    html.window.localStorage.remove(_tokenExpiresStorageKey);
    html.window.localStorage.remove(_userStorageKey);
  }

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
    if (unidadeCnes != null &&
        unidadeCnes.trim().isNotEmpty &&
        unidadeCnes != 'all') {
      queryParams['unidade_cnes'] = unidadeCnes.trim();
    }

    try {
      return await _executeWithRecovery((baseUrl) async {
        final uri = Uri.parse('$baseUrl/laudos')
            .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
        final response = await _client
            .get(uri, headers: _headers())
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 401) {
          _handleUnauthorized();
          throw UnauthorizedException();
        }

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
              headers: _headers(includeJson: true),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 401) {
          _handleUnauthorized();
          throw UnauthorizedException();
        }

        if (response.statusCode != 201) {
          throw Exception(_extractError(response.body, response.statusCode));
        }

        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        return Laudo.fromJson(payload['data'] as Map<String, dynamic>);
      });
    } on TimeoutException {
      throw Exception('Tempo esgotado ao salvar laudo.');
    } catch (e) {
      throw Exception(
          'Nao foi possivel salvar. Verifique se o backend esta ativo. $e');
    }
  }

  Future<Laudo> updateLaudo(int id, Map<String, dynamic> body) async {
    try {
      return await _executeWithRecovery((baseUrl) async {
        final response = await _client
            .put(
              Uri.parse('$baseUrl/laudos/$id'),
              headers: _headers(includeJson: true),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 401) {
          _handleUnauthorized();
          throw UnauthorizedException();
        }

        if (response.statusCode != 200) {
          throw Exception(_extractError(response.body, response.statusCode));
        }

        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        return Laudo.fromJson(payload['data'] as Map<String, dynamic>);
      });
    } on TimeoutException {
      throw Exception('Tempo esgotado ao atualizar laudo.');
    } catch (e) {
      throw Exception(
          'Nao foi possivel atualizar. Verifique se o backend esta ativo. $e');
    }
  }

  Future<void> deleteLaudo(int id) async {
    try {
      await _executeWithRecovery((baseUrl) async {
        final response = await _client
            .delete(Uri.parse('$baseUrl/laudos/$id'), headers: _headers())
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 401) {
          _handleUnauthorized();
          throw UnauthorizedException();
        }
        if (response.statusCode != 200) {
          throw Exception(_extractError(response.body, response.statusCode));
        }
        return true;
      });
    } on TimeoutException {
      throw Exception('Tempo esgotado ao remover laudo.');
    } catch (e) {
      throw Exception(
          'Nao foi possivel remover. Verifique se o backend esta ativo. $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    return _executeWithRecovery((baseUrl) async {
      final response = await _client
          .get(Uri.parse('$baseUrl/users'), headers: _headers())
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (payload['data'] as List?) ?? const <dynamic>[];
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> body) async {
    return _executeWithRecovery((baseUrl) async {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/users'),
            headers: _headers(includeJson: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode != 201) {
        throw Exception(_extractError(response.body, response.statusCode));
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return Map<String, dynamic>.from(payload);
    });
  }

  Future<Map<String, dynamic>> updateUser(
      int id, Map<String, dynamic> body) async {
    return _executeWithRecovery((baseUrl) async {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/users/$id'),
            headers: _headers(includeJson: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return Map<String, dynamic>.from(
          (payload['data'] as Map?) ?? <String, dynamic>{});
    });
  }

  Future<void> deactivateUser(int id) async {
    await _executeWithRecovery((baseUrl) async {
      final response = await _client
          .delete(Uri.parse('$baseUrl/users/$id'), headers: _headers())
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode == 404) {
        return <Map<String, dynamic>>[];
      }
      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
      return true;
    });
  }

  Future<List<Map<String, dynamic>>> fetchCatalogEstabelecimentos({
    String? tipo,
    bool includeInativos = false,
  }) async {
    return _executeWithRecovery((baseUrl) async {
      final query = <String, String>{};
      if (tipo != null && tipo.trim().isNotEmpty) {
        query['tipo'] = tipo.trim();
      }
      if (includeInativos) {
        query['include_inativos'] = 'true';
      }
      final uri = Uri.parse('$baseUrl/catalog/estabelecimentos').replace(
        queryParameters: query.isEmpty ? null : query,
      );
      final response = await _client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode == 404) {
        return <Map<String, dynamic>>[];
      }
      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (payload['data'] as List?) ?? const <dynamic>[];
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }

  Future<List<Map<String, dynamic>>> fetchCatalogPrincipais({
    bool includeInativos = false,
  }) async {
    return _executeWithRecovery((baseUrl) async {
      final uri =
          Uri.parse('$baseUrl/catalog/procedimentos/principais').replace(
        queryParameters: includeInativos
            ? <String, String>{'include_inativos': 'true'}
            : null,
      );
      final response = await _client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode == 404) {
        return <Map<String, dynamic>>[];
      }
      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (payload['data'] as List?) ?? const <dynamic>[];
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }

  Future<List<Map<String, dynamic>>> fetchCatalogSecundarios({
    bool includeInativos = false,
  }) async {
    return _executeWithRecovery((baseUrl) async {
      final uri =
          Uri.parse('$baseUrl/catalog/procedimentos/secundarios').replace(
        queryParameters: includeInativos
            ? <String, String>{'include_inativos': 'true'}
            : null,
      );
      final response = await _client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode == 404) {
        return <Map<String, dynamic>>[];
      }
      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (payload['data'] as List?) ?? const <dynamic>[];
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }

  Future<void> createCatalogEstabelecimento({
    required String nome,
    required String cnes,
    required String tipo,
  }) async {
    await _executeWithRecovery((baseUrl) async {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/catalog/estabelecimentos'),
            headers: _headers(includeJson: true),
            body: jsonEncode({'nome': nome, 'cnes': cnes, 'tipo': tipo}),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode != 201) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
      return true;
    });
  }

  Future<void> deleteCatalogEstabelecimento(int id) async {
    await _executeWithRecovery((baseUrl) async {
      final response = await _client
          .delete(Uri.parse('$baseUrl/catalog/estabelecimentos/$id'),
              headers: _headers())
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
      return true;
    });
  }

  Future<Map<String, dynamic>> updateCatalogEstabelecimento(
    int id, {
    required String nome,
    required String cnes,
    required String tipo,
  }) async {
    return _executeWithRecovery((baseUrl) async {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/catalog/estabelecimentos/$id'),
            headers: _headers(includeJson: true),
            body: jsonEncode({'nome': nome, 'cnes': cnes, 'tipo': tipo}),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return Map<String, dynamic>.from(
          (payload['data'] as Map?) ?? <String, dynamic>{});
    });
  }

  Future<void> setCatalogEstabelecimentoAtivo(int id, bool ativo) async {
    await _executeWithRecovery((baseUrl) async {
      final response = await _client
          .patch(
            Uri.parse('$baseUrl/catalog/estabelecimentos/$id/status'),
            headers: _headers(includeJson: true),
            body: jsonEncode({'ativo': ativo}),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
      return true;
    });
  }

  Future<void> createCatalogSecundario({
    required String codigoSigtap,
    required String descricao,
  }) async {
    await _executeWithRecovery((baseUrl) async {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/catalog/procedimentos/secundarios'),
            headers: _headers(includeJson: true),
            body: jsonEncode(
                {'codigo_sigtap': codigoSigtap, 'descricao': descricao}),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode != 201) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
      return true;
    });
  }

  Future<void> createCatalogPrincipal({
    required String codigoSigtap,
    required String descricao,
    required List<int> secundariosIds,
  }) async {
    await _executeWithRecovery((baseUrl) async {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/catalog/procedimentos/principais'),
            headers: _headers(includeJson: true),
            body: jsonEncode({
              'codigo_sigtap': codigoSigtap,
              'descricao': descricao,
              'secundarios_ids': secundariosIds,
            }),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode != 201) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
      return true;
    });
  }

  Future<void> deleteCatalogProcedimento(int id) async {
    await _executeWithRecovery((baseUrl) async {
      final response = await _client
          .delete(Uri.parse('$baseUrl/catalog/procedimentos/$id'),
              headers: _headers())
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
      return true;
    });
  }

  Future<Map<String, dynamic>> updateCatalogProcedimento(
    int id, {
    required String codigoSigtap,
    required String descricao,
    List<int>? secundariosIds,
  }) async {
    return _executeWithRecovery((baseUrl) async {
      final payload = <String, dynamic>{
        'codigo_sigtap': codigoSigtap,
        'descricao': descricao,
      };
      if (secundariosIds != null) {
        payload['secundarios_ids'] = secundariosIds;
      }
      final response = await _client
          .put(
            Uri.parse('$baseUrl/catalog/procedimentos/$id'),
            headers: _headers(includeJson: true),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      return Map<String, dynamic>.from(
          (map['data'] as Map?) ?? <String, dynamic>{});
    });
  }

  Future<void> setCatalogProcedimentoAtivo(int id, bool ativo) async {
    await _executeWithRecovery((baseUrl) async {
      final response = await _client
          .patch(
            Uri.parse('$baseUrl/catalog/procedimentos/$id/status'),
            headers: _headers(includeJson: true),
            body: jsonEncode({'ativo': ativo}),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, response.statusCode));
      }
      return true;
    });
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
      final ok = await _isValidApiEndpoint(_resolvedBaseUrl!);
      if (ok) return _resolvedBaseUrl;
      _resolvedBaseUrl = null;
    }

    final protocol = html.window.location.protocol;
    final host = html.window.location.host;
    final port = html.window.location.port;

    final candidates = _candidateBaseUrls(protocol, host, port);

    for (final candidate in candidates.toSet()) {
      final ok = await _isValidApiEndpoint(candidate);
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
      'http://127.0.0.1:8081/api',
      'http://127.0.0.1:8080/api',
      'http://localhost:8081/api',
      'http://localhost:8080/api',
      '$protocol//$host/api',
    ];
  }

  Future<bool> _ping(String baseUrl) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode != 200) return false;

      final contentType =
          (response.headers['content-type'] ?? '').toLowerCase();
      if (!contentType.contains('application/json')) return false;

      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) return false;
      return (payload['status'] ?? '').toString().toLowerCase() == 'ok';
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isValidApiEndpoint(String baseUrl) async {
    final healthOk = await _ping(baseUrl);
    if (!healthOk) return false;

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(const {'email': '', 'senha': ''}),
          )
          .timeout(const Duration(seconds: 2));

      // Endpoint exists in this API if it returns validation/auth codes.
      return response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 422;
    } catch (_) {
      return false;
    }
  }

  Future<T> _executeWithRecovery<T>(
      Future<T> Function(String baseUrl) action) async {
    final first = await _ensureBaseUrl();
    try {
      return await action(first);
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      _resolvedBaseUrl = null;
      final second = await _resolveBaseUrl();
      if (second == null || second == first) rethrow;
      return action(second);
    }
  }

  Map<String, String> _headers({bool includeJson = false}) {
    final headers = <String, String>{};
    if (includeJson) {
      headers['content-type'] = 'application/json';
    }
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  void _saveSession(Map<String, dynamic> sessionData) {
    _accessToken = (sessionData['access_token'] ?? '').toString();
    _tokenExpiresAt = (sessionData['expires_at'] ?? '').toString();
    _currentUser = Map<String, dynamic>.from(
      (sessionData['user'] as Map?) ?? <String, dynamic>{},
    );

    html.window.localStorage[_tokenStorageKey] = _accessToken ?? '';
    html.window.localStorage[_tokenExpiresStorageKey] = _tokenExpiresAt ?? '';
    html.window.localStorage[_userStorageKey] = jsonEncode(_currentUser);
  }

  void _handleUnauthorized() {
    clearSession();
    final callback = _onUnauthorized;
    if (callback != null) callback();
  }

  String _extractError(String rawBody, int fallbackCode) {
    try {
      final payload = jsonDecode(rawBody) as Map<String, dynamic>;
      final message =
          payload['error']?.toString() ?? payload['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    } catch (_) {
      if (fallbackCode == 404) {
        return 'Rota nao encontrada na API (404). Reinicie o backend atualizado em 8081.';
      }
      return 'Falha na requisicao ($fallbackCode).';
    }
    if (fallbackCode == 404) {
      return 'Rota nao encontrada na API (404). Reinicie o backend atualizado em 8081.';
    }
    return 'Falha na requisicao ($fallbackCode).';
  }
}
