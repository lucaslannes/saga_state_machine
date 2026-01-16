import 'dart:async';

import 'saga.dart';
import 'behavior_context.dart';

/// Base interface for activities (side effects).
///
/// Activities encapsulate side effects like:
/// - Starting/stopping timers
/// - Sending notifications
/// - Making API calls
///
/// Activities can optionally implement [compensate] for rollback.
///
/// Example:
/// ```dart
/// class SendEmailActivity extends Activity<OrderSaga, OrderCreated> {
///   @override
///   Future<void> execute(BehaviorContext<OrderSaga, OrderCreated> context) async {
///     await emailService.send(context.saga.email, 'Order created!');
///   }
///
///   @override
///   Future<void> compensate(BehaviorContext<OrderSaga, OrderCreated> context) async {
///     await emailService.send(context.saga.email, 'Order cancelled');
///   }
/// }
/// ```
abstract class Activity<TSaga extends Saga, TEvent> {
  /// Execute the activity.
  FutureOr<void> execute(BehaviorContext<TSaga, TEvent> context);

  /// Compensate (rollback) the activity. Optional.
  FutureOr<void> compensate(BehaviorContext<TSaga, TEvent> context) async {}
}

/// Simple activity that executes a function.
///
/// Example:
/// ```dart
/// final activity = FunctionActivity<MySaga, MyEvent>(
///   (context) => print('Executing'),
///   compensate: (context) => print('Compensating'),
/// );
/// ```
class FunctionActivity<TSaga extends Saga, TEvent>
    extends Activity<TSaga, TEvent> {
  final FutureOr<void> Function(BehaviorContext<TSaga, TEvent> context)
      _execute;
  final FutureOr<void> Function(BehaviorContext<TSaga, TEvent> context)?
      _compensate;

  /// Creates a function-based activity.
  ///
  /// [_execute] is the main execution function.
  /// [compensate] is an optional rollback function.
  FunctionActivity(this._execute,
      {FutureOr<void> Function(BehaviorContext<TSaga, TEvent> context)?
          compensate})
      : _compensate = compensate;

  @override
  FutureOr<void> execute(BehaviorContext<TSaga, TEvent> context) =>
      _execute(context);

  @override
  FutureOr<void> compensate(BehaviorContext<TSaga, TEvent> context) {
    if (_compensate != null) return _compensate!(context);
  }
}

/// Activity that does nothing. Useful as placeholder.
class NoOpActivity<TSaga extends Saga, TEvent> extends Activity<TSaga, TEvent> {
  @override
  FutureOr<void> execute(BehaviorContext<TSaga, TEvent> context) {}
}
