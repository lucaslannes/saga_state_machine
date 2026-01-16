import 'package:meta/meta.dart';

/// Base class for all saga instances.
///
/// A saga represents a long-running process with state that can be
/// correlated across multiple events.
///
/// Example:
/// ```dart
/// class OrderSaga extends Saga {
///   String? customerId;
///   List<String> items = [];
///   double total = 0;
/// }
/// ```
abstract class Saga {
  /// Unique identifier for this saga instance.
  /// Used to correlate events to the correct saga.
  late String id;

  /// Timestamp when this saga was created.
  late DateTime createdAt;

  /// Timestamp when this saga was last updated.
  late DateTime updatedAt;

  /// Whether this saga has been finalized (completed/failed).
  bool isFinalized = false;

  /// Creates a new saga instance.
  Saga() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// Marks the saga as updated.
  @internal
  void markUpdated() {
    updatedAt = DateTime.now();
  }

  /// Marks the saga as finalized.
  @internal
  void markFinalized() {
    isFinalized = true;
    markUpdated();
  }
}
