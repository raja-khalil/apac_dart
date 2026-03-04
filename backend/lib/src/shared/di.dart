import 'package:apac_backend/src/config/env.dart';
import 'package:apac_backend/src/modules/audit/controllers/audit_log_controller.dart';
import 'package:apac_backend/src/modules/audit/repositories/audit_log_repository.dart';
import 'package:apac_backend/src/modules/audit/repositories/eloquent_audit_log_repository.dart';
import 'package:apac_backend/src/modules/audit/services/audit_log_service.dart';
import 'package:apac_backend/src/modules/auth/controllers/auth_controller.dart';
import 'package:apac_backend/src/modules/auth/repositories/auth_repository.dart';
import 'package:apac_backend/src/modules/auth/repositories/eloquent_auth_repository.dart';
import 'package:apac_backend/src/modules/auth/services/auth_service.dart';
import 'package:apac_backend/src/modules/auth/services/password_hasher.dart';
import 'package:apac_backend/src/modules/laudo/controllers/laudo_controller.dart';
import 'package:apac_backend/src/modules/laudo/repositories/eloquent_laudo_repository.dart';
import 'package:apac_backend/src/modules/laudo/repositories/laudo_repository.dart';
import 'package:apac_backend/src/modules/laudo/services/laudo_service.dart';
import 'package:apac_backend/src/modules/user/controllers/user_controller.dart';
import 'package:apac_backend/src/modules/user/repositories/eloquent_user_repository.dart';
import 'package:apac_backend/src/modules/user/repositories/user_repository.dart';
import 'package:apac_backend/src/modules/user/services/user_service.dart';
import 'package:get_it/get_it.dart';

final GetIt di = GetIt.instance;

Future<void> configureDependencies() async {
  if (di.isRegistered<LaudoController>()) {
    return;
  }

  await Database.initialize();

  di.registerLazySingleton<PasswordHasher>(() => const PasswordHasher());

  di.registerLazySingleton<IAuthRepository>(
    () => EloquentAuthRepository(Database.connection),
  );
  di.registerLazySingleton<AuthService>(
    () => AuthService(di<IAuthRepository>(), di<PasswordHasher>()),
  );
  di.registerLazySingleton<AuthController>(
    () => AuthController(di<AuthService>()),
  );

  di.registerLazySingleton<IAuditLogRepository>(
    () => EloquentAuditLogRepository(Database.connection),
  );
  di.registerLazySingleton<AuditLogService>(
    () => AuditLogService(di<IAuditLogRepository>()),
  );
  di.registerLazySingleton<AuditLogController>(
    () => AuditLogController(di<AuditLogService>()),
  );

  di.registerLazySingleton<ILaudoRepository>(
    () => EloquentLaudoRepository(Database.connection),
  );
  di.registerLazySingleton<LaudoService>(
    () => LaudoService(di<ILaudoRepository>()),
  );
  di.registerLazySingleton<LaudoController>(
    () => LaudoController(di<LaudoService>()),
  );

  di.registerLazySingleton<IUserRepository>(
    () => EloquentUserRepository(Database.connection),
  );
  di.registerLazySingleton<UserService>(
    () => UserService(di<IUserRepository>(), di<PasswordHasher>()),
  );
  di.registerLazySingleton<UserController>(
    () => UserController(di<UserService>()),
  );
}
