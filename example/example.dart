// ignore_for_file: avoid_print
import 'package:saga_state_machine/saga_state_machine.dart';

// ─────────────────────────────────────────────────────────────────
// SAGA DEFINITION
// ─────────────────────────────────────────────────────────────────

enum OrderStatus { pending, paid, shipped, delivered, cancelled, expired }

class OrderSaga extends Saga {
  String? customerId;
  String? productId;
  double amount = 0;
  OrderStatus status = OrderStatus.pending;
}

// ─────────────────────────────────────────────────────────────────
// EVENTS
// ─────────────────────────────────────────────────────────────────

class OrderCreated {
  final String orderId;
  final String customerId;
  final String productId;
  final double amount;

  OrderCreated(this.orderId, this.customerId, this.productId, this.amount);
}

class PaymentReceived {
  final String orderId;
  PaymentReceived(this.orderId);
}

class OrderShipped {
  final String orderId;
  OrderShipped(this.orderId);
}

class OrderDelivered {
  final String orderId;
  OrderDelivered(this.orderId);
}

class OrderCancelled {
  final String orderId;
  OrderCancelled(this.orderId);
}

class PaymentTimeout extends TimeoutEvent {
  PaymentTimeout(super.sagaId);
}

// ─────────────────────────────────────────────────────────────────
// STATE MACHINE - This is the clean, declarative API!
// ─────────────────────────────────────────────────────────────────

class OrderStateMachine extends SagaStateMachine<OrderSaga, OrderStatus> {
  OrderStateMachine() {
    // Define how to correlate events to sagas
    correlate<OrderCreated>((e) => e.orderId);
    correlate<PaymentReceived>((e) => e.orderId);
    correlate<OrderShipped>((e) => e.orderId);
    correlate<OrderDelivered>((e) => e.orderId);
    correlate<OrderCancelled>((e) => e.orderId);
    correlate<PaymentTimeout>((e) => e.sagaId);

    // Initial state - when saga is created
    initially(
      when<OrderCreated>()
          .set((saga, e) => saga
            ..customerId = e.customerId
            ..productId = e.productId
            ..amount = e.amount)
          .transitionTo(OrderStatus.pending)
          .schedule<PaymentTimeout>(const Duration(hours: 24)),
    );

    // Pending state
    during(
      OrderStatus.pending,
      when<PaymentReceived>()
          .unschedule<PaymentTimeout>()
          .transitionTo(OrderStatus.paid),
      [
        when<OrderCancelled>().transitionTo(OrderStatus.cancelled).finalize(),
        when<PaymentTimeout>().transitionTo(OrderStatus.expired).finalize(),
      ],
    );

    // Paid state
    during(
      OrderStatus.paid,
      when<OrderShipped>().transitionTo(OrderStatus.shipped),
    );

    // Shipped state
    during(
      OrderStatus.shipped,
      when<OrderDelivered>().transitionTo(OrderStatus.delivered).finalize(),
    );

    // Global handler - can cancel from any state
    duringAny(
      when<OrderCancelled>()
          .where((e) => true) // Could add conditions
          .transitionTo(OrderStatus.cancelled)
          .finalize(),
    );

    // Transition logging
    onAnyTransition((saga, from, to) {
      print('Order ${saga.id}: $from → $to');
    });

    // Cleanup on finalization
    whenFinalized(
      execute: FunctionActivity((ctx) {
        print('Order ${ctx.saga.id} finalized with status: ${ctx.saga.status}');
      }),
    );
  }

  @override
  OrderSaga createSaga(String correlationId) {
    final saga = OrderSaga();
    saga.id = correlationId;
    return saga;
  }

  @override
  OrderStatus getState(OrderSaga saga) => saga.status;

  @override
  void setState(OrderSaga saga, OrderStatus state) {
    saga.status = state;
  }
}

// ─────────────────────────────────────────────────────────────────
// USAGE EXAMPLE
// ─────────────────────────────────────────────────────────────────

void main() async {
  final machine = OrderStateMachine();

  // Create an order
  await machine
      .dispatch(OrderCreated('order-123', 'customer-1', 'product-abc', 99.99));

  // Get the saga
  final order = machine.getSaga('order-123');
  print('Order status: ${order?.status}'); // pending

  // Payment received
  await machine.dispatch(PaymentReceived('order-123'));
  print('Order status: ${order?.status}'); // paid

  // Ship the order
  await machine.dispatch(OrderShipped('order-123'));
  print('Order status: ${order?.status}'); // shipped

  // Deliver
  await machine.dispatch(OrderDelivered('order-123'));
  print('Order status: ${order?.status}'); // delivered
  print('Order finalized: ${order?.isFinalized}'); // true

  machine.dispose();
}
