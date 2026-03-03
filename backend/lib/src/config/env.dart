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
    if (_connection != null) {
      return;
    }

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
      CREATE TABLE IF NOT EXISTS public.pacientes_v2 (
        id BIGSERIAL PRIMARY KEY,
        nome TEXT NOT NULL,
        nome_social TEXT NOT NULL DEFAULT '',
        cpf VARCHAR(14),
        cartao_sus VARCHAR(32) NOT NULL DEFAULT '',
        data_nascimento DATE,
        sexo VARCHAR(20) NOT NULL DEFAULT '',
        nome_mae TEXT NOT NULL DEFAULT '',
        registro TEXT NOT NULL DEFAULT '',
        telefone VARCHAR(20) NOT NULL DEFAULT '',
        logradouro TEXT NOT NULL DEFAULT '',
        numero VARCHAR(20) NOT NULL DEFAULT '',
        complemento TEXT NOT NULL DEFAULT '',
        bairro TEXT NOT NULL DEFAULT '',
        municipio TEXT NOT NULL DEFAULT '',
        ibge VARCHAR(10) NOT NULL DEFAULT '',
        uf VARCHAR(2) NOT NULL DEFAULT '',
        cep VARCHAR(10) NOT NULL DEFAULT '',
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
      );
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS public.estabelecimentos_v2 (
        id BIGSERIAL PRIMARY KEY,
        cnes VARCHAR(10),
        nome TEXT NOT NULL,
        tipo VARCHAR(20) NOT NULL,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        CONSTRAINT estabelecimentos_v2_tipo_chk CHECK (tipo IN ('solicitante', 'executante', 'ambos'))
      );
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS public.procedimentos_v2 (
        id BIGSERIAL PRIMARY KEY,
        codigo_sigtap VARCHAR(20) NOT NULL,
        descricao TEXT NOT NULL,
        tipo VARCHAR(20) NOT NULL DEFAULT 'principal',
        ativo BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        CONSTRAINT procedimentos_v2_tipo_chk CHECK (tipo IN ('principal', 'secundario'))
      );
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS public.laudos_v2 (
        id BIGSERIAL PRIMARY KEY,
        paciente_id BIGINT NOT NULL REFERENCES public.pacientes_v2(id),
        estabelecimento_solicitante_id BIGINT NOT NULL REFERENCES public.estabelecimentos_v2(id),
        estabelecimento_executante_id BIGINT REFERENCES public.estabelecimentos_v2(id),
        procedimento_principal_id BIGINT NOT NULL REFERENCES public.procedimentos_v2(id),
        status VARCHAR(20) NOT NULL DEFAULT 'rascunho',
        descricao_diagnostico TEXT NOT NULL DEFAULT '',
        cid10_principal VARCHAR(10) NOT NULL DEFAULT '',
        cid10_secundario VARCHAR(10) NOT NULL DEFAULT '',
        cid10_causas_associadas VARCHAR(10) NOT NULL DEFAULT '',
        observacoes TEXT NOT NULL DEFAULT '',
        profissional_solicitante TEXT NOT NULL DEFAULT '',
        tipo_documento VARCHAR(10) NOT NULL DEFAULT 'CPF',
        documento_solicitante VARCHAR(32) NOT NULL DEFAULT '',
        data_solicitacao DATE,
        payload JSONB NOT NULL DEFAULT '{}'::jsonb,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        CONSTRAINT laudos_v2_status_chk CHECK (status IN ('rascunho', 'solicitado', 'autorizado', 'executado')),
        CONSTRAINT laudos_v2_tipo_documento_chk CHECK (tipo_documento IN ('CPF', 'CNS'))
      );
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS public.laudo_procedimentos_secundarios_v2 (
        id BIGSERIAL PRIMARY KEY,
        laudo_id BIGINT NOT NULL REFERENCES public.laudos_v2(id) ON DELETE CASCADE,
        procedimento_id BIGINT REFERENCES public.procedimentos_v2(id),
        codigo_sigtap VARCHAR(20) NOT NULL,
        nome_procedimento TEXT NOT NULL,
        data_execucao DATE,
        origem VARCHAR(20) NOT NULL DEFAULT 'oci',
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        CONSTRAINT laudo_proc_sec_v2_origem_chk CHECK (origem IN ('oci', 'manual'))
      );
    ''');

    await _connection.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_pacientes_v2_cpf_uq ON public.pacientes_v2(cpf) WHERE cpf IS NOT NULL AND cpf <> \'\'',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_pacientes_v2_nome ON public.pacientes_v2(nome)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_estabelecimentos_v2_nome ON public.estabelecimentos_v2(nome)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_estabelecimentos_v2_cnes ON public.estabelecimentos_v2(cnes)',
    );
    await _connection.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_procedimentos_v2_codigo_uq ON public.procedimentos_v2(codigo_sigtap)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_laudos_v2_status ON public.laudos_v2(status)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_laudos_v2_created_at ON public.laudos_v2(created_at)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_laudos_v2_paciente_id ON public.laudos_v2(paciente_id)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_laudos_v2_solicitante_id ON public.laudos_v2(estabelecimento_solicitante_id)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_laudos_v2_executante_id ON public.laudos_v2(estabelecimento_executante_id)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_laudos_v2_proc_principal_id ON public.laudos_v2(procedimento_principal_id)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_laudo_sec_v2_laudo_id ON public.laudo_procedimentos_secundarios_v2(laudo_id)',
    );
  }
}
