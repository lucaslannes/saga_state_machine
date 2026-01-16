// Example: VoIP Call State Machine using saga_state_machine
//
// This demonstrates a real-world use case: managing VoIP call lifecycle
// with states like ringing, answered, on hold, and call termination.

import 'package:saga_state_machine/saga_state_machine.dart';

// ─────────────────────────────────────────────────────────────────
// STATE ENUM (existing)
// ─────────────────────────────────────────────────────────────────

enum CallStatus {
  notStarted,
  ringing,
  answered,
  onHold,
  completed,
  failed,
  timeout,
  rejected,
  cancelled,
}

// ─────────────────────────────────────────────────────────────────
// SAGA INSTANCE (replaces CallState)
// ─────────────────────────────────────────────────────────────────

enum CallDirection { inbound, outbound }

class CallSaga extends Saga {
  CallStatus status = CallStatus.notStarted;
  String? phoneNumber;
  CallDirection? direction;
  DateTime? callStartedAt;
  Duration talkTime = Duration.zero;
  bool isMuted = false;
  Map<String, dynamic> metadata = {};
}

// ─────────────────────────────────────────────────────────────────
// EVENTS
// ─────────────────────────────────────────────────────────────────

class IncomingCallReceived {
  final String callId;
  final String phoneNumber;
  final String? displayName;
  IncomingCallReceived(this.callId, this.phoneNumber, {this.displayName});
}

class OutgoingCallStarted {
  final String callId;
  final String phoneNumber;
  OutgoingCallStarted(this.callId, this.phoneNumber);
}

class CallAnswered {
  final String callId;
  CallAnswered(this.callId);
}

class CallHeld {
  final String callId;
  CallHeld(this.callId);
}

class CallResumed {
  final String callId;
  CallResumed(this.callId);
}

class CallEnded {
  final String callId;
  final CallStatus endReason;
  CallEnded(this.callId, this.endReason);
}

class RingingTimeout extends TimeoutEvent {
  RingingTimeout(super.sagaId);
}

// ─────────────────────────────────────────────────────────────────
// STATE MACHINE - Clean, declarative, self-documenting!
// ─────────────────────────────────────────────────────────────────

class CallStateMachine extends SagaStateMachine<CallSaga, CallStatus> {
  final void Function(CallSaga saga, CallStatus from, CallStatus to)?
      onStateChanged;

  CallStateMachine({this.onStateChanged}) {
    // Event correlation by callId
    correlate<IncomingCallReceived>((e) => e.callId);
    correlate<OutgoingCallStarted>((e) => e.callId);
    correlate<CallAnswered>((e) => e.callId);
    correlate<CallHeld>((e) => e.callId);
    correlate<CallResumed>((e) => e.callId);
    correlate<CallEnded>((e) => e.callId);
    correlate<RingingTimeout>((e) => e.sagaId);

    // ═══════════════════════════════════════════════════════════════
    // INITIAL STATE - Saga creation
    // ═══════════════════════════════════════════════════════════════

    initially(
      when<IncomingCallReceived>()
          .set((saga, e) => saga
            ..phoneNumber = e.phoneNumber
            ..direction = CallDirection.inbound
            ..metadata = {'displayName': e.displayName})
          .transitionTo(CallStatus.ringing)
          .schedule<RingingTimeout>(const Duration(seconds: 30)),
      [
        when<OutgoingCallStarted>()
            .set((saga, e) => saga
              ..phoneNumber = e.phoneNumber
              ..direction = CallDirection.outbound)
            .transitionTo(CallStatus.ringing)
            .schedule<RingingTimeout>(const Duration(seconds: 60)),
      ],
    );

    // ═══════════════════════════════════════════════════════════════
    // RINGING STATE
    // ═══════════════════════════════════════════════════════════════

    during(
      CallStatus.ringing,
      when<CallAnswered>()
          .unschedule<RingingTimeout>()
          .set((saga, _) => saga.callStartedAt = DateTime.now())
          .transitionTo(CallStatus.answered),
      [
        when<CallEnded>()
            .unschedule<RingingTimeout>()
            .transitionToState((ctx) => ctx.event.endReason)
            .finalize(),
        when<RingingTimeout>().transitionTo(CallStatus.timeout).finalize(),
      ],
    );

    // ═══════════════════════════════════════════════════════════════
    // ANSWERED STATE
    // ═══════════════════════════════════════════════════════════════

    during(
      CallStatus.answered,
      when<CallHeld>().transitionTo(CallStatus.onHold),
      [
        when<CallEnded>()
            .set((saga, _) => saga.talkTime =
                DateTime.now().difference(saga.callStartedAt ?? DateTime.now()))
            .transitionTo(CallStatus.completed)
            .finalize(),
      ],
    );

    // ═══════════════════════════════════════════════════════════════
    // ON HOLD STATE
    // ═══════════════════════════════════════════════════════════════

    during(
      CallStatus.onHold,
      when<CallResumed>().transitionTo(CallStatus.answered),
      [
        when<CallEnded>()
            .set((saga, _) => saga.talkTime =
                DateTime.now().difference(saga.callStartedAt ?? DateTime.now()))
            .transitionTo(CallStatus.completed)
            .finalize(),
      ],
    );

    // ═══════════════════════════════════════════════════════════════
    // CALLBACKS
    // ═══════════════════════════════════════════════════════════════

    onAnyTransition((saga, from, to) {
      onStateChanged?.call(saga, from, to);
    });
  }

  @override
  CallSaga createSaga(String correlationId) {
    final saga = CallSaga();
    saga.id = correlationId;
    return saga;
  }

  @override
  CallStatus getState(CallSaga saga) => saga.status;

  @override
  void setState(CallSaga saga, CallStatus state) {
    saga.status = state;
  }
}

// ─────────────────────────────────────────────────────────────────
// USAGE EXAMPLE
// ─────────────────────────────────────────────────────────────────

void main() async {
  final machine = CallStateMachine(
    onStateChanged: (saga, from, to) {
      print('Call ${saga.id}: $from → $to');
    },
  );

  // Incoming call
  await machine.dispatch(
      IncomingCallReceived('call-123', '+1234567890', displayName: 'John'));
  print('Status: ${machine.getSaga("call-123")?.status}'); // ringing

  // Answer
  await machine.dispatch(CallAnswered('call-123'));
  print('Status: ${machine.getSaga("call-123")?.status}'); // answered

  // Hold
  await machine.dispatch(CallHeld('call-123'));
  print('Status: ${machine.getSaga("call-123")?.status}'); // onHold

  // Resume
  await machine.dispatch(CallResumed('call-123'));
  print('Status: ${machine.getSaga("call-123")?.status}'); // answered

  // End - saga is finalized and removed from repository
  final endedSaga =
      await machine.dispatch(CallEnded('call-123', CallStatus.completed));
  print('Was finalized: ${endedSaga?.isFinalized}'); // true (before removal)
  print(
      'Still in repo: ${machine.getSaga("call-123") != null}'); // false (removed after finalize)

  machine.dispose();
}
