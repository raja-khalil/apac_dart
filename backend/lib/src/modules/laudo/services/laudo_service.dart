import 'package:apac_backend/src/modules/laudo/repositories/laudo_repository.dart';

class LaudoService {
  LaudoService(this._repository);

  final ILaudoRepository _repository;

  Future<List<Map<String, dynamic>>> listAll({
    String? query,
    String? status,
    String? unidadeCnes,
  }) {
    return _repository.listAll(
      query: query,
      status: status,
      unidadeCnes: unidadeCnes,
    );
  }

  Future<Map<String, dynamic>?> getById(int id) {
    return _repository.getById(id);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) {
    return _repository.create(payload);
  }

  Future<Map<String, dynamic>?> update(int id, Map<String, dynamic> payload) {
    return _repository.update(id, payload);
  }

  Future<bool> delete(int id) {
    return _repository.delete(id);
  }
}
