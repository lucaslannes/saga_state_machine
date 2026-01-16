# saga_state_machine

A MassTransit-style state machine framework for Dart. Provides declarative, event-driven saga pattern with fluent builder API.

## Features

- **Declarative API**: Define state machines in a readable, self-documenting way
- **Event Correlation**: Automatically route events to the correct saga instance
- **Activities**: Execute side effects with optional compensation (rollback)
- **Timeouts**: Built-in timeout handling for states
- **Finalization**: Clean up resources when saga completes

## Usage

### Define your Saga

```dart
enum OrderStatus { pending, paid, shipped, delivered, cancelled }

class OrderSaga extends Saga {
  String? customerId;
  double amount = 0;
  OrderStatus status = OrderStatus.pending;
}
```

### Define Events

```dart
class OrderCreated {
  final String orderId;
  final String customerId;
  final double amount;
  OrderCreated(this.orderId, this.customerId, this.amount);
}

class PaymentReceived {
  final String orderId;
  PaymentReceived(this.orderId);
}
```

### Create the State Machine

```dart
class OrderStateMachine extends SagaStateMachine<OrderSaga, OrderStatus> {
  OrderStateMachine() {
    // Correlate events to sagas
    correlate<OrderCreated>((e) => e.orderId);
    correlate<PaymentReceived>((e) => e.orderId);

    // Initial state
    initially(
      when<OrderCreated>()
        .set((saga, e) => saga
          ..customerId = e.customerId
          ..amount = e.amount)
        .transitionTo(OrderStatus.pending),
    );

    // State handlers
    during(OrderStatus.pending,
      when<PaymentReceived>().transitionTo(OrderStatus.paid),
      timeout(Duration(hours: 24), transitionTo: OrderStatus.cancelled),
    );
  }

  @override
  OrderSaga createSaga(String id) => OrderSaga()..id = id;

  @override
  OrderStatus getState(OrderSaga saga) => saga.status;

  @override
  void setState(OrderSaga saga, OrderStatus state) => saga.status = state;
}
```

### Use It

```dart
final machine = OrderStateMachine();

// Dispatch events
await machine.dispatch(OrderCreated('order-1', 'customer-1', 99.99));
await machine.dispatch(PaymentReceived('order-1'));

// Query saga
final order = machine.getSaga('order-1');
print(order?.status); // OrderStatus.paid
```

## API Reference

### State Machine Methods

| Method                             | Description                     |
| ---------------------------------- | ------------------------------- |
| `correlate<E>((e) => id)`          | Define event correlation        |
| `initially(when<E>()...)`          | Handle new saga creation        |
| `during(state, when<E>()...)`      | Handle events in specific state |
| `duringAny(when<E>()...)`          | Handle events in any state      |
| `timeout(duration, transitionTo:)` | State timeout                   |
| `whenFinalized(execute:)`          | Cleanup on saga completion      |
| `onAnyTransition(callback)`        | Listen to all transitions       |

### Event Handler Methods

| Method                   | Description                   |
| ------------------------ | ----------------------------- |
| `when<E>()`              | Create handler for event type |
| `.where((e) => bool)`    | Filter events                 |
| `.set((saga, e) => ...)` | Set saga properties           |
| `.then((ctx) => ...)`    | Execute custom action         |
| `.execute(Activity)`     | Execute activity              |
| `.transitionTo(state)`   | Transition to state           |
| `.finalize()`            | Mark saga as complete         |
| `.schedule<E>(duration)` | Schedule delayed event        |
| `.unschedule<E>()`       | Cancel scheduled event        |

## Comparison with MassTransit

| Feature           | MassTransit (C#) | dart_saga             |
| ----------------- | ---------------- | --------------------- |
| Declarative DSL   | ✅               | ✅                    |
| Event correlation | ✅               | ✅                    |
| Timeouts          | ✅               | ✅                    |
| Activities        | ✅               | ✅                    |
| Compensation      | ✅               | ✅                    |
| Persistence       | RabbitMQ/SQL     | In-memory (pluggable) |

## Inspiration

This package is inspired by [MassTransit](https://masstransit.io/)'s state machine implementation for .NET. MassTransit is a trademark of Chris Patterson.

## License

MIT License - see [LICENSE](LICENSE) for details.
