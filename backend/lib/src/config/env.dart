import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
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
      int.tryParse(Platform.environment['SERVER_PORT'] ?? '8081') ?? 8081;

  static String get frontendBaseUrl =>
      Platform.environment['FRONTEND_BASE_URL'] ?? 'http://127.0.0.1:8080';

  static String get smtpHost => Platform.environment['SMTP_HOST'] ?? '';
  static int get smtpPort =>
      int.tryParse(Platform.environment['SMTP_PORT'] ?? '587') ?? 587;
  static String get smtpUser => Platform.environment['SMTP_USER'] ?? '';
  static String get smtpPassword => Platform.environment['SMTP_PASSWORD'] ?? '';
  static String get smtpFromEmail =>
      Platform.environment['SMTP_FROM_EMAIL'] ?? '';
  static String get smtpFromName =>
      Platform.environment['SMTP_FROM_NAME'] ?? 'APAC/OCI';
  static bool get smtpUseSsl =>
      (Platform.environment['SMTP_SSL'] ?? 'false').toLowerCase() == 'true';
  static bool get smtpAllowInsecure =>
      (Platform.environment['SMTP_ALLOW_INSECURE'] ?? 'false')
          .toLowerCase() ==
      'true';
  static bool get smtpConfigured =>
      smtpHost.isNotEmpty &&
      smtpUser.isNotEmpty &&
      smtpPassword.isNotEmpty &&
      smtpFromEmail.isNotEmpty;
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

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS public.usuarios_v2 (
        id BIGSERIAL PRIMARY KEY,
        nome TEXT NOT NULL,
        email VARCHAR(255) NOT NULL,
        ativo BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
      );
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS public.usuario_credenciais_v2 (
        usuario_id BIGINT PRIMARY KEY REFERENCES public.usuarios_v2(id) ON DELETE CASCADE,
        senha_hash VARCHAR(255) NOT NULL,
        senha_salt VARCHAR(255) NOT NULL,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
      );
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS public.perfis_v2 (
        id BIGSERIAL PRIMARY KEY,
        codigo VARCHAR(40) NOT NULL,
        nome VARCHAR(120) NOT NULL,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
      );
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS public.usuario_perfis_v2 (
        usuario_id BIGINT NOT NULL REFERENCES public.usuarios_v2(id) ON DELETE CASCADE,
        perfil_id BIGINT NOT NULL REFERENCES public.perfis_v2(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        PRIMARY KEY (usuario_id, perfil_id)
      );
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS public.sessoes_v2 (
        id BIGSERIAL PRIMARY KEY,
        usuario_id BIGINT NOT NULL REFERENCES public.usuarios_v2(id) ON DELETE CASCADE,
        token TEXT NOT NULL,
        expires_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        revoked_at TIMESTAMP WITHOUT TIME ZONE NULL
      );
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS public.password_reset_tokens_v2 (
        id BIGSERIAL PRIMARY KEY,
        usuario_id BIGINT NOT NULL REFERENCES public.usuarios_v2(id) ON DELETE CASCADE,
        token TEXT NOT NULL,
        expires_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        used_at TIMESTAMP WITHOUT TIME ZONE NULL,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
      );
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS public.audit_logs_v2 (
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
    await _connection.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_usuarios_v2_email_uq ON public.usuarios_v2(email)',
    );
    await _connection.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_perfis_v2_codigo_uq ON public.perfis_v2(codigo)',
    );
    await _connection.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_sessoes_v2_token_uq ON public.sessoes_v2(token)',
    );
    await _connection.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_password_reset_tokens_v2_token_uq ON public.password_reset_tokens_v2(token)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_v2_usuario_id ON public.password_reset_tokens_v2(usuario_id)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_v2_expires_at ON public.password_reset_tokens_v2(expires_at)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_sessoes_v2_usuario_id ON public.sessoes_v2(usuario_id)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_sessoes_v2_expires_at ON public.sessoes_v2(expires_at)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_v2_usuario_id ON public.audit_logs_v2(usuario_id)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_v2_entidade ON public.audit_logs_v2(entidade, entidade_id)',
    );
    await _connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_v2_created_at ON public.audit_logs_v2(created_at)',
    );

    await _seedProfilesAndAdmin();
  }

  static Future<void> _seedProfilesAndAdmin() async {
    final now = DateTime.now().toUtc().toIso8601String();

    final profiles = <Map<String, String>>[
      {'codigo': 'admin', 'nome': 'Administrador'},
      {'codigo': 'faturista', 'nome': 'Faturista'},
      {'codigo': 'operador', 'nome': 'Operador'},
      {'codigo': 'gestor', 'nome': 'Gestor'},
    ];

    for (final profile in profiles) {
      await _connection.execute('''
        INSERT INTO public.perfis_v2 (codigo, nome, created_at)
        SELECT '${profile['codigo']}', '${profile['nome']}', '$now'
        WHERE NOT EXISTS (
          SELECT 1 FROM public.perfis_v2 WHERE codigo = '${profile['codigo']}'
        );
      ''');
    }

    final perfilRows = await _connection
        .table('perfis_v2')
        .select(['id'])
        .where('codigo', '=', 'admin')
        .limit(1)
        .get();
    if ((perfilRows as List).isEmpty) return;
    final adminProfileId = ((perfilRows.first as Map)['id'] as num).toInt();
    await _ensureAdminUser(
      nome: 'Administrador',
      email: 'admin@apac.local',
      senha: 'ostras123',
      salt: 'apac_admin_seed_salt',
      adminProfileId: adminProfileId,
      now: now,
    );
    await _ensureAdminUser(
      nome: 'Raja Khalil',
      email: 'raja.pmro@gmail.com',
      senha: 'ostras123',
      salt: 'apac_raja_seed_salt',
      adminProfileId: adminProfileId,
      now: now,
    );
  }

  static Future<void> _ensureAdminUser({
    required String nome,
    required String email,
    required String senha,
    required String salt,
    required int adminProfileId,
    required String now,
  }) async {
    final rows = await _connection
        .table('usuarios_v2')
        .select(['id'])
        .where('email', '=', email.toLowerCase().trim())
        .limit(1)
        .get();

    int userId;
    if ((rows as List).isEmpty) {
      final inserted = await _connection.table('usuarios_v2').insertGetId({
        'nome': nome,
        'email': email.toLowerCase().trim(),
        'ativo': true,
        'created_at': now,
        'updated_at': now,
      }, 'id');
      userId = (inserted as num).toInt();
    } else {
      userId = ((rows.first as Map)['id'] as num).toInt();
      await _connection.table('usuarios_v2').where('id', '=', userId).update({
        'nome': nome,
        'ativo': true,
        'updated_at': now,
      });
    }

    final hash = sha256.convert(utf8.encode('$salt:$senha')).toString();
    final credRows = await _connection
        .table('usuario_credenciais_v2')
        .select(['usuario_id'])
        .where('usuario_id', '=', userId)
        .limit(1)
        .get();
    if ((credRows as List).isEmpty) {
      await _connection.table('usuario_credenciais_v2').insert({
        'usuario_id': userId,
        'senha_hash': hash,
        'senha_salt': salt,
        'created_at': now,
        'updated_at': now,
      });
    }

    final linkRows = await _connection
        .table('usuario_perfis_v2')
        .select(['usuario_id'])
        .where('usuario_id', '=', userId)
        .where('perfil_id', '=', adminProfileId)
        .limit(1)
        .get();
    if ((linkRows as List).isEmpty) {
      await _connection.table('usuario_perfis_v2').insert({
        'usuario_id': userId,
        'perfil_id': adminProfileId,
        'created_at': now,
      });
    }
  }
}
