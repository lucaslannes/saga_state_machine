import 'dart:async';

/// Scheduler for delayed/timeout events.
///
/// Manages scheduled events for saga timeouts.
class Scheduler {
  final Map<String, Timer> _timers = {};
  final void Function<T>(String sagaId, T event) _dispatchEvent;

  Scheduler(this._dispatchEvent);

  /// Schedule an event to be dispatched after a delay.
  void schedule<TEvent>({
    required String sagaId,
    required TEvent event,
    required Duration delay,
  }) {
    final key = _makeKey(sagaId, TEvent);

    // Cancel existing timer for same type
    _timers[key]?.cancel();

    _timers[key] = Timer(delay, () {
      _timers.remove(key);
      _dispatchEvent<TEvent>(sagaId, event);
    });
  }

  /// Cancel a scheduled event.
  void unschedule<TEvent>(String sagaId) {
    final key = _makeKey(sagaId, TEvent);
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  /// Cancel all scheduled events for a saga.
  void unscheduleAll(String sagaId) {
    final keysToRemove =
        _timers.keys.where((k) => k.startsWith('$sagaId:')).toList();
    for (final key in keysToRemove) {
      _timers[key]?.cancel();
      _timers.remove(key);
    }
  }

  /// Check if an event is scheduled.
  bool isScheduled<TEvent>(String sagaId) {
    return _timers.containsKey(_makeKey(sagaId, TEvent));
  }

  String _makeKey(String sagaId, Type eventType) => '$sagaId:$eventType';

  /// Dispose all timers.
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}

/// Timeout event marker.
///
/// Use as base class for timeout events:
/// ```dart
/// class RingingTimeout extends TimeoutEvent {
///   RingingTimeout(super.sagaId);
/// }
/// ```
abstract class TimeoutEvent {
  final String sagaId;
  TimeoutEvent(this.sagaId);
}
