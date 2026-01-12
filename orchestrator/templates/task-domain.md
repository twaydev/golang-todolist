# [Domain] Implement entity and service for {Feature}

## Agent
**domain-logic-agent**

## Phase
Phase 2 - GREEN State (Parallel with database-agent)

## Objective
Implement domain entities, services, and port interfaces following hexagonal architecture principles to make all unit tests pass (GREEN state).

## Prerequisites
- Phase 1 complete (tests are RED)
- Failing unit tests available in `test/unit/domain/`

## Tasks
1. **Define Domain Entities** (`internal/domain/entity/{entity}.go`)
   - Struct with business-relevant fields
   - Validate() method (business rule validation)
   - State transition methods (e.g., MarkComplete())
   - Business logic methods (e.g., IsOverdue())
   - Document business rules in comments

2. **Define Port Interfaces** (`internal/domain/port/output/{port}.go`)
   - Repository interfaces (Create, Update, Delete, List, etc.)
   - External service interfaces (if needed)
   - Use context.Context for cancellation
   - Return domain entities, not DTOs

3. **Implement Application Services** (`internal/domain/service/{service}.go`)
   - Constructor with dependency injection
   - Orchestrate business logic
   - Call repositories through port interfaces
   - Handle errors with custom error types
   - NO infrastructure concerns

4. **Verify GREEN State**
   ```bash
   go test ./test/unit/domain/... -v
   # All tests should PASS
   ```

## Architecture Rules
- ❌ NO imports from `internal/adapter/`
- ❌ NO imports from infrastructure (postgres, http, telebot)
- ✅ ONLY stdlib and other domain packages
- ✅ All external dependencies via interfaces (ports)

## Skills Used
- golang/interfaces
- golang/error-handling
- design-patterns/hexagonal-architecture
- domain-driven-design
- solid-principles

## Output
- `internal/domain/entity/{entity}.go` ✅
- `internal/domain/entity/{value_objects}.go` ✅
- `internal/domain/port/output/{repository}.go` ✅
- `internal/domain/service/{service}.go` ✅
- All unit tests PASS (GREEN) ✅

## Completion Signal
Post to Linear:
```
✅ domain-logic-agent complete

Files created:
- internal/domain/entity/{entity}.go
- internal/domain/port/output/{repository}.go
- internal/domain/service/{service}.go

Test status: All PASSING (GREEN) ✅

Unit tests: {X} passed
Architecture violations: 0 ✅

Ready for Phase 3 (adapters).
```

## Checkpoint Validation
Run: `orchestrator/scripts/validate-phase.sh 2`
- Expected: All unit tests pass (GREEN state)
- Proceed to Phase 3 when validated (and database-agent completes)

## References
- `.factory/droids/domain-logic-agent.yaml`
- `docs/03-hexagonal-architecture.md`
- `docs/06-domain-entities.md`
- `docs/07-domain-services.md`
