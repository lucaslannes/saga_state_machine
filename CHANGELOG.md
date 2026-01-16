# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-17

### Added

- Initial release of saga_state_machine
- `SagaStateMachine` - MassTransit-style declarative state machine
- `Saga` - Base class for saga instances with lifecycle tracking
- `EventHandler` - Fluent builder API for event handling
  - `when<E>()` - Create handler for event type
  - `where()` - Filter events by condition
  - `set()` - Set saga properties from event
  - `then()` - Execute custom async actions
  - `execute()` - Run activities with optional compensation
  - `transitionTo()` - Static state transitions
  - `transitionToState()` - Dynamic state resolution
  - `finalize()` - Mark saga as complete
  - `schedule()` / `unschedule()` - Delayed event scheduling
- `Activity` - Side effect abstraction with compensation support
  - `FunctionActivity` - Inline activity from function
  - `NoOpActivity` - Placeholder activity
- `Scheduler` - Timer-based event scheduling
- `SagaRepository` - Pluggable persistence interface
  - `InMemorySagaRepository` - Default in-memory implementation
- `BehaviorContext` - Context passed to actions and activities
- Event correlation via `correlate<E>()`
- State handlers: `initially()`, `during()`, `duringAny()`
- Timeout support for states
- Transition and finalization callbacks
- Comprehensive test suite (52 tests)
- Two complete examples:
  - Order processing workflow
  - VoIP call state management
