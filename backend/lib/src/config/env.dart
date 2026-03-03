import 'dart:io';

import 'package:eloquent/eloquent.dart';

class EnvConfig {
  static String get dbHost => Platform.environment['DB_HOST'] ?? 'localhost';
  static String get dbPort => Platform.environment['DB_PORT'] ?? '5432';
  static String get dbName => Platform.environment['DB_NAME'] ?? 'apac';
  static String get dbUser => Platform.environment['DB_USER'] ?? 'postgres';
  static String get dbPassword => Platform.environment['DB_PASSWORD'] ?? 'dart';

  static String get serverHost =>
      Platform.environment['SERVER_HOST'] ?? '0.0.0.0';
  static int get serverPort =>
      int.tryParse(Platform.environment['SERVER_PORT'] ?? '8080') ?? 8080;
}

class Database {
  Database._();

  static final Manager _manager = Manager();
  static dynamic _connection;

  static Future<void> initialize() async {
    _manager.addConnection({
      'driver': 'pgsql',
      'driver_implementation': 'postgres_v3',
      'host': EnvConfig.dbHost,
      'port': EnvConfig.dbPort,
      'database': EnvConfig.dbName,
      'username': EnvConfig.dbUser,
      'password': EnvConfig.dbPassword,
      'charset': 'utf8',
      'schema': 'public',
      'pool': true,
      'poolsize': 4,
    });

    _manager.setAsGlobal();
    _connection = await _manager.connection();
    await _ensureSchema();
  }

  static dynamic get connection {
    if (_connection == null) {
      throw StateError('Database not initialized.');
    }
    return _connection;
  }

  static Future<void> _ensureSchema() async {
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS public.laudos (
        id BIGSERIAL PRIMARY KEY,
        nome_paciente TEXT NOT NULL,
        cpf VARCHAR(14) NOT NULL,
        data_nascimento DATE NOT NULL,
        oci_codigo VARCHAR(20) NOT NULL DEFAULT '',
        oci_descricao TEXT NOT NULL DEFAULT '',
        unidade_solicitante TEXT NOT NULL DEFAULT '',
        unidade_cnes VARCHAR(10) NOT NULL DEFAULT '',
        status VARCHAR(20) NOT NULL DEFAULT 'rascunho',
        payload JSONB NOT NULL DEFAULT '{}'::jsonb,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
      );
    ''');

    await _connection.execute(
      "ALTER TABLE public.laudos ADD COLUMN IF NOT EXISTS nome_paciente TEXT NOT NULL DEFAULT ''",
    );
    await _connection.execute(
      "ALTER TABLE public.laudos ADD COLUMN IF NOT EXISTS cpf VARCHAR(14) NOT NULL DEFAULT ''",
    );
    await _connection.execute(
      "ALTER TABLE public.laudos ADD COLUMN IF NOT EXISTS data_nascimento DATE NOT NULL DEFAULT CURRENT_DATE",
    );
    await _connection.execute(
      "ALTER TABLE public.laudos ADD COLUMN IF NOT EXISTS oci_codigo VARCHAR(20) NOT NULL DEFAULT ''",
    );
    await _connection.execute(
      "ALTER TABLE public.laudos ADD COLUMN IF NOT EXISTS oci_descricao TEXT NOT NULL DEFAULT ''",
    );
    await _connection.execute(
      "ALTER TABLE public.laudos ADD COLUMN IF NOT EXISTS unidade_solicitante TEXT NOT NULL DEFAULT ''",
    );
    await _connection.execute(
      "ALTER TABLE public.laudos ADD COLUMN IF NOT EXISTS unidade_cnes VARCHAR(10) NOT NULL DEFAULT ''",
    );
    await _connection.execute(
      "ALTER TABLE public.laudos ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'rascunho'",
    );
    await _connection.execute(
      "ALTER TABLE public.laudos ADD COLUMN IF NOT EXISTS payload JSONB NOT NULL DEFAULT '{}'::jsonb",
    );
    await _connection.execute(
      "ALTER TABLE public.laudos ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()",
    );

    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_laudos_status ON public.laudos(status)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_laudos_unidade_cnes ON public.laudos(unidade_cnes)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_laudos_nome_paciente ON public.laudos(nome_paciente)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_laudos_cpf ON public.laudos(cpf)',
    );
  }
}
