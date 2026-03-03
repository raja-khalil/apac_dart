import 'dart:io';

import 'package:apac_backend/src/config/env.dart';
import 'package:eloquent/eloquent.dart';

Future<void> main() async {
  final manager = Manager();
  manager.addConnection({
    'driver': 'pgsql',
    'driver_implementation': 'postgres',
    'host': EnvConfig.dbHost,
    'port': EnvConfig.dbPort,
    'database': EnvConfig.dbName,
    'username': EnvConfig.dbUser,
    'password': EnvConfig.dbPassword,
    'charset': 'utf8',
    'schema': 'public',
    'pool': false,
  });

  manager.setAsGlobal();
  final db = await manager.connection();

  stdout.writeln('Reestruturando schema relacional (sem migracao de dados)...');
  stdout.writeln(
    'Conexao: ${EnvConfig.dbHost}:${EnvConfig.dbPort}/${EnvConfig.dbName}',
  );

  try {
    await db.execute('BEGIN');
    await _dropTables(db);
    await _createTables(db);
    await _createIndexes(db);
    await db.execute('COMMIT');
    stdout.writeln('Schema relacional criado com sucesso.');
  } catch (error, stackTrace) {
    await db.execute('ROLLBACK');
    stderr.writeln('Falha ao reestruturar schema: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  } finally {
    await db.disconnect();
  }
}

Future<void> _dropTables(Connection db) async {
  await db.execute('''
    DROP TABLE IF EXISTS public.laudo_procedimentos_secundarios_v2 CASCADE;
    DROP TABLE IF EXISTS public.laudos_v2 CASCADE;
    DROP TABLE IF EXISTS public.procedimentos_v2 CASCADE;
    DROP TABLE IF EXISTS public.estabelecimentos_v2 CASCADE;
    DROP TABLE IF EXISTS public.pacientes_v2 CASCADE;
  ''');
}

Future<void> _createTables(Connection db) async {
  await db.execute('''
    CREATE TABLE public.pacientes_v2 (
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

  await db.execute('''
    CREATE TABLE public.estabelecimentos_v2 (
      id BIGSERIAL PRIMARY KEY,
      cnes VARCHAR(10),
      nome TEXT NOT NULL,
      tipo VARCHAR(20) NOT NULL,
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      CONSTRAINT estabelecimentos_v2_tipo_chk CHECK (tipo IN ('solicitante', 'executante', 'ambos'))
    );
  ''');

  await db.execute('''
    CREATE TABLE public.procedimentos_v2 (
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

  await db.execute('''
    CREATE TABLE public.laudos_v2 (
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

  await db.execute('''
    CREATE TABLE public.laudo_procedimentos_secundarios_v2 (
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
}

Future<void> _createIndexes(Connection db) async {
  await db.execute(
    'CREATE UNIQUE INDEX idx_pacientes_v2_cpf_uq ON public.pacientes_v2(cpf) WHERE cpf IS NOT NULL AND cpf <> \'\'',
  );
  await db.execute(
    'CREATE INDEX idx_pacientes_v2_nome ON public.pacientes_v2(nome)',
  );
  await db.execute(
    'CREATE INDEX idx_estabelecimentos_v2_nome ON public.estabelecimentos_v2(nome)',
  );
  await db.execute(
    'CREATE INDEX idx_estabelecimentos_v2_cnes ON public.estabelecimentos_v2(cnes)',
  );
  await db.execute(
    'CREATE UNIQUE INDEX idx_procedimentos_v2_codigo_uq ON public.procedimentos_v2(codigo_sigtap)',
  );
  await db.execute(
    'CREATE INDEX idx_laudos_v2_status ON public.laudos_v2(status)',
  );
  await db.execute(
    'CREATE INDEX idx_laudos_v2_created_at ON public.laudos_v2(created_at)',
  );
  await db.execute(
    'CREATE INDEX idx_laudos_v2_paciente_id ON public.laudos_v2(paciente_id)',
  );
  await db.execute(
    'CREATE INDEX idx_laudos_v2_solicitante_id ON public.laudos_v2(estabelecimento_solicitante_id)',
  );
  await db.execute(
    'CREATE INDEX idx_laudos_v2_executante_id ON public.laudos_v2(estabelecimento_executante_id)',
  );
  await db.execute(
    'CREATE INDEX idx_laudos_v2_proc_principal_id ON public.laudos_v2(procedimento_principal_id)',
  );
  await db.execute(
    'CREATE INDEX idx_laudo_sec_v2_laudo_id ON public.laudo_procedimentos_secundarios_v2(laudo_id)',
  );
  await db.execute(
    'CREATE INDEX idx_laudo_sec_v2_codigo ON public.laudo_procedimentos_secundarios_v2(codigo_sigtap)',
  );
}
