import 'dart:convert';
import 'dart:io';

import 'package:apac_backend/src/config/env.dart';
import 'package:crypto/crypto.dart';
import 'package:eloquent/eloquent.dart';

Future<void> main() async {
  final manager = Manager();
  manager.addConnection({
    'driver': 'pgsql',
    'driver_implementation': 'postgres_v3',
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
  stdout.writeln('Conexao: ${EnvConfig.dbHost}:${EnvConfig.dbPort}/${EnvConfig.dbName}');

  try {
    await db.execute('BEGIN');
    await _dropTables(db);
    await _createTables(db);
    await _createIndexes(db);
    await _seedProfilesAndAdmin(db);
    await db.execute('COMMIT');
    stdout.writeln('Schema relacional criado com sucesso.');
  } catch (error, stackTrace) {
    await db.execute('ROLLBACK');
    stderr.writeln('Falha ao reestruturar schema: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

Future<void> _dropTables(Connection db) async {
  await db.execute('''
    DROP TABLE IF EXISTS public.audit_logs_v2 CASCADE;
    DROP TABLE IF EXISTS public.usuario_perfis_v2 CASCADE;
    DROP TABLE IF EXISTS public.perfis_v2 CASCADE;
    DROP TABLE IF EXISTS public.sessoes_v2 CASCADE;
    DROP TABLE IF EXISTS public.usuario_credenciais_v2 CASCADE;
    DROP TABLE IF EXISTS public.usuarios_v2 CASCADE;
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

    CREATE TABLE public.estabelecimentos_v2 (
      id BIGSERIAL PRIMARY KEY,
      cnes VARCHAR(10),
      nome TEXT NOT NULL,
      tipo VARCHAR(20) NOT NULL,
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      CONSTRAINT estabelecimentos_v2_tipo_chk CHECK (tipo IN ('solicitante', 'executante', 'ambos'))
    );

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
      updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );

    CREATE TABLE public.laudo_procedimentos_secundarios_v2 (
      id BIGSERIAL PRIMARY KEY,
      laudo_id BIGINT NOT NULL REFERENCES public.laudos_v2(id) ON DELETE CASCADE,
      procedimento_id BIGINT REFERENCES public.procedimentos_v2(id),
      codigo_sigtap VARCHAR(20) NOT NULL,
      nome_procedimento TEXT NOT NULL,
      data_execucao DATE,
      origem VARCHAR(20) NOT NULL DEFAULT 'oci',
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );

    CREATE TABLE public.usuarios_v2 (
      id BIGSERIAL PRIMARY KEY,
      nome TEXT NOT NULL,
      email VARCHAR(255) NOT NULL,
      ativo BOOLEAN NOT NULL DEFAULT TRUE,
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );

    CREATE TABLE public.usuario_credenciais_v2 (
      usuario_id BIGINT PRIMARY KEY REFERENCES public.usuarios_v2(id) ON DELETE CASCADE,
      senha_hash VARCHAR(255) NOT NULL,
      senha_salt VARCHAR(255) NOT NULL,
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );

    CREATE TABLE public.perfis_v2 (
      id BIGSERIAL PRIMARY KEY,
      codigo VARCHAR(40) NOT NULL,
      nome VARCHAR(120) NOT NULL,
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );

    CREATE TABLE public.usuario_perfis_v2 (
      usuario_id BIGINT NOT NULL REFERENCES public.usuarios_v2(id) ON DELETE CASCADE,
      perfil_id BIGINT NOT NULL REFERENCES public.perfis_v2(id) ON DELETE CASCADE,
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      PRIMARY KEY (usuario_id, perfil_id)
    );

    CREATE TABLE public.sessoes_v2 (
      id BIGSERIAL PRIMARY KEY,
      usuario_id BIGINT NOT NULL REFERENCES public.usuarios_v2(id) ON DELETE CASCADE,
      token TEXT NOT NULL,
      expires_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
      revoked_at TIMESTAMP WITHOUT TIME ZONE NULL
    );

    CREATE TABLE public.audit_logs_v2 (
      id BIGSERIAL PRIMARY KEY,
      usuario_id BIGINT REFERENCES public.usuarios_v2(id),
      acao VARCHAR(20) NOT NULL,
      entidade VARCHAR(60) NOT NULL,
      entidade_id BIGINT,
      dados_antes JSONB NOT NULL DEFAULT '{}'::jsonb,
      dados_depois JSONB NOT NULL DEFAULT '{}'::jsonb,
      ip_origem VARCHAR(64) NOT NULL DEFAULT '',
      created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
  ''');
}

Future<void> _createIndexes(Connection db) async {
  await db.execute('CREATE UNIQUE INDEX idx_pacientes_v2_cpf_uq ON public.pacientes_v2(cpf) WHERE cpf IS NOT NULL AND cpf <> \'\'');
  await db.execute('CREATE INDEX idx_pacientes_v2_nome ON public.pacientes_v2(nome)');
  await db.execute('CREATE INDEX idx_estabelecimentos_v2_nome ON public.estabelecimentos_v2(nome)');
  await db.execute('CREATE INDEX idx_estabelecimentos_v2_cnes ON public.estabelecimentos_v2(cnes)');
  await db.execute('CREATE UNIQUE INDEX idx_procedimentos_v2_codigo_uq ON public.procedimentos_v2(codigo_sigtap)');
  await db.execute('CREATE INDEX idx_laudos_v2_status ON public.laudos_v2(status)');
  await db.execute('CREATE INDEX idx_laudos_v2_created_at ON public.laudos_v2(created_at)');
  await db.execute('CREATE INDEX idx_laudos_v2_paciente_id ON public.laudos_v2(paciente_id)');
  await db.execute('CREATE INDEX idx_laudos_v2_solicitante_id ON public.laudos_v2(estabelecimento_solicitante_id)');
  await db.execute('CREATE INDEX idx_laudos_v2_executante_id ON public.laudos_v2(estabelecimento_executante_id)');
  await db.execute('CREATE INDEX idx_laudos_v2_proc_principal_id ON public.laudos_v2(procedimento_principal_id)');
  await db.execute('CREATE INDEX idx_laudo_sec_v2_laudo_id ON public.laudo_procedimentos_secundarios_v2(laudo_id)');
  await db.execute('CREATE INDEX idx_laudo_sec_v2_codigo ON public.laudo_procedimentos_secundarios_v2(codigo_sigtap)');
  await db.execute('CREATE UNIQUE INDEX idx_usuarios_v2_email_uq ON public.usuarios_v2(email)');
  await db.execute('CREATE UNIQUE INDEX idx_perfis_v2_codigo_uq ON public.perfis_v2(codigo)');
  await db.execute('CREATE UNIQUE INDEX idx_sessoes_v2_token_uq ON public.sessoes_v2(token)');
  await db.execute('CREATE INDEX idx_sessoes_v2_usuario_id ON public.sessoes_v2(usuario_id)');
  await db.execute('CREATE INDEX idx_sessoes_v2_expires_at ON public.sessoes_v2(expires_at)');
  await db.execute('CREATE INDEX idx_audit_logs_v2_usuario_id ON public.audit_logs_v2(usuario_id)');
  await db.execute('CREATE INDEX idx_audit_logs_v2_entidade ON public.audit_logs_v2(entidade, entidade_id)');
  await db.execute('CREATE INDEX idx_audit_logs_v2_created_at ON public.audit_logs_v2(created_at)');
}

Future<void> _seedProfilesAndAdmin(Connection db) async {
  final now = DateTime.now().toUtc().toIso8601String();

  final profiles = const <Map<String, String>>[
    {'codigo': 'admin', 'nome': 'Administrador'},
    {'codigo': 'faturista', 'nome': 'Faturista'},
    {'codigo': 'operador', 'nome': 'Operador'},
    {'codigo': 'gestor', 'nome': 'Gestor'},
  ];

  for (final profile in profiles) {
    await db.table('perfis_v2').insert({
      'codigo': profile['codigo'],
      'nome': profile['nome'],
      'created_at': now,
    });
  }

  final adminId = await db.table('usuarios_v2').insertGetId({
    'nome': 'Administrador',
    'email': 'admin@apac.local',
    'ativo': true,
    'created_at': now,
    'updated_at': now,
  }, 'id');

  const salt = 'apac_admin_seed_salt';
  final hash = sha256.convert(utf8.encode('$salt:ostras123')).toString();

  await db.table('usuario_credenciais_v2').insert({
    'usuario_id': (adminId as num).toInt(),
    'senha_hash': hash,
    'senha_salt': salt,
    'created_at': now,
    'updated_at': now,
  });

  final perfilAdmin = await db
      .table('perfis_v2')
      .select(['id'])
      .where('codigo', '=', 'admin')
      .limit(1)
      .get();
  final adminProfileId = ((perfilAdmin as List).first as Map)['id'];

  await db.table('usuario_perfis_v2').insert({
    'usuario_id': adminId,
    'perfil_id': (adminProfileId as num).toInt(),
    'created_at': now,
  });
}
