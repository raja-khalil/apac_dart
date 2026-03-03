import 'package:apac_backend/src/config/env.dart';
import 'package:apac_backend/src/modules/laudo/controllers/laudo_controller.dart';
import 'package:apac_backend/src/modules/laudo/repositories/eloquent_laudo_repository.dart';
import 'package:apac_backend/src/modules/laudo/repositories/laudo_repository.dart';
import 'package:apac_backend/src/modules/laudo/services/laudo_service.dart';
import 'package:get_it/get_it.dart';

final GetIt di = GetIt.instance;

Future<void> configureDependencies() async {
  if (di.isRegistered<LaudoController>()) {
    return;
  }

  await Database.initialize();

  di.registerLazySingleton<ILaudoRepository>(
    () => EloquentLaudoRepository(Database.connection),
  );
  di.registerLazySingleton<LaudoService>(
    () => LaudoService(di<ILaudoRepository>()),
  );
  di.registerLazySingleton<LaudoController>(
    () => LaudoController(di<LaudoService>()),
  );
}
