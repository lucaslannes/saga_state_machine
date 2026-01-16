/// A MassTransit-style state machine framework for Dart.
///
/// Provides declarative, event-driven saga pattern with fluent builder API.
///
/// Example:
/// ```dart
/// class OrderSaga extends Saga {
///   String? orderId;
///   OrderStatus status = OrderStatus.pending;
/// }
///
/// class OrderStateMachine extends SagaStateMachine<OrderSaga, OrderStatus> {
///   OrderStateMachine() {
///     initially(
///       when<OrderCreated>()
///         .set((saga, e) => saga.orderId = e.orderId)
///         .transitionTo(OrderStatus.pending),
///     );
///
///     during(OrderStatus.pending,
///       when<PaymentReceived>().transitionTo(OrderStatus.paid),
///       when<OrderCancelled>().transitionTo(OrderStatus.cancelled).finalize(),
///       timeout(Duration(hours: 24), transitionTo: OrderStatus.expired),
///     );
///   }
/// }
/// ```
library saga_state_machine;

export 'src/saga.dart';
export 'src/saga_state_machine.dart';
export 'src/behavior_context.dart';
export 'src/event_handler.dart';
export 'src/activity.dart';
export 'src/scheduler.dart';
export 'src/saga_repository.dart';
