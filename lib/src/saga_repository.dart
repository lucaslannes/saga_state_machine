import 'saga.dart';

/// Repository for storing and retrieving saga instances.
///
/// Implement this interface to persist sagas to your preferred storage.
abstract class SagaRepository<TSaga extends Saga> {
  /// Get a saga by its correlation ID.
  TSaga? getById(String id);

  /// Save a saga instance.
  void save(TSaga saga);

  /// Remove a saga instance.
  void remove(String id);

  /// Get all active (non-finalized) sagas.
  List<TSaga> getActive();

  /// Clear all sagas.
  void clear();
}

/// In-memory implementation of [SagaRepository].
///
/// Useful for testing and simple applications.
class InMemorySagaRepository<TSaga extends Saga>
    implements SagaRepository<TSaga> {
  final Map<String, TSaga> _sagas = {};

  @override
  TSaga? getById(String id) => _sagas[id];

  @override
  void save(TSaga saga) {
    _sagas[saga.id] = saga;
  }

  @override
  void remove(String id) {
    _sagas.remove(id);
  }

  @override
  List<TSaga> getActive() {
    return _sagas.values.where((s) => !s.isFinalized).toList();
  }

  @override
  void clear() {
    _sagas.clear();
  }
}
