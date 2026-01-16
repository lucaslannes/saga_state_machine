import 'saga.dart';
import 'scheduler.dart';

/// Context passed to event handlers and activities.
///
/// Provides access to the saga instance, the triggering event,
/// and services like the scheduler.
class BehaviorContext<TSaga extends Saga, TEvent> {
  /// The saga instance being operated on.
  final TSaga saga;

  /// The event that triggered this behavior.
  final TEvent event;

  /// Scheduler for delayed/timeout events.
  final Scheduler scheduler;

  /// Previous state before transition (if applicable).
  final dynamic previousState;

  /// Target state after transition (if applicable).
  final dynamic targetState;

  /// Creates a new behavior context.
  ///
  /// [saga] is the saga instance being operated on.
  /// [event] is the event that triggered this behavior.
  /// [scheduler] provides access to event scheduling.
  /// [previousState] is the state before transition (optional).
  /// [targetState] is the state after transition (optional).
  BehaviorContext({
    required this.saga,
    required this.event,
    required this.scheduler,
    this.previousState,
    this.targetState,
  });

  /// Create a new context with a different event type.
  BehaviorContext<TSaga, T> withEvent<T>(T newEvent) {
    return BehaviorContext<TSaga, T>(
      saga: saga,
      event: newEvent,
      scheduler: scheduler,
      previousState: previousState,
      targetState: targetState,
    );
  }
}
