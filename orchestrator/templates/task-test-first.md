# [Test-First] Write tests for {Feature}

## Agent
**test-first-agent**

## Phase
Phase 1 - RED State (Sequential)

## Objective
Write comprehensive BDD scenarios and unit tests that FAIL initially, establishing the RED state for test-driven development.

## Tasks
1. **Write Gherkin Feature File** (`app/features/{feature}.feature`)
   - Happy path scenarios
   - Validation error scenarios
   - Edge cases (empty, null, max length, unicode, special chars)
   - Security scenarios (injection, XSS)
   - Concurrent access scenarios

2. **Create Step Definitions** (`app/test/bdd/{feature}_steps_test.go`)
   - Test context struct
   - Step functions (initially returning errors)
   - Helper functions for setup/teardown
   - Use in-memory adapters for isolation

3. **Write Unit Tests** (`app/test/unit/domain/{service}_test.go`)
   - Follow Arrange-Act-Assert pattern
   - Test success cases
   - Test all error paths
   - Use testify for assertions
   - Generate mocks with mockery

4. **Verify RED State**
   ```bash
   go test ./app/test/... -v
   # All tests should FAIL (expected)
   ```

## Skills Used
- testing/godog
- testing/testify
- mocking/mockery
- bdd/gherkin
- tdd/methodology

## Output
- `app/features/{feature}.feature` ✅
- `app/test/bdd/{feature}_steps_test.go` ✅
- `app/test/unit/domain/{service}_test.go` ✅
- All tests execute and FAIL ❌ (expected RED state)

## Completion Signal
Post to Linear:
```
✅ test-first-agent complete

Files created:
- app/features/{feature}.feature
- app/test/bdd/{feature}_steps_test.go
- app/test/unit/domain/{service}_test.go

Test status: All FAILING (RED) ❌ (as expected)

Scenarios: {X} total
Unit tests: {Y} total

Ready for Phase 2 (domain-logic-agent + database-agent).
```

## Checkpoint Validation
Run: `orchestrator/scripts/validate-phase.sh 1`
- Expected: Tests fail (RED state)
- Proceed to Phase 2 when validated

## References
- `.factory/droids/test-first-agent.yaml`
- `docs/04-tdd-bdd-workflow.md`
- `docs/05-testing-strategy.md`
