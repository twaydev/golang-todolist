# Bug Fix Workflow

## Overview

This workflow describes how to fix bugs using the test-first approach with specialized agents.

---

## Bug Fix Process

```
1. Reproduce bug with failing test (Test-First Agent)
2. Fix domain logic (Domain Logic Agent)
3. Fix infrastructure if needed (Database/API/Infrastructure Agents)
4. Verify fix with tests
5. Deploy with confidence
```

---

## Example: Fix "Todo Code Not Sequential" Bug

### Bug Report

**Issue**: Todo codes skip numbers (e.g., 26-0001, 26-0003, missing 26-0002)

**Expected**: Sequential codes 26-0001, 26-0002, 26-0003, ...

**Actual**: Codes skip numbers on concurrent creation

---

### Step 1: Reproduce with Test

**Agent**: `@test-first-agent`

**Prompt**:
```
Write a test that reproduces the "non-sequential todo codes" bug.

Create test/integration/todo_code_sequence_test.go:

Test scenario:
1. Create 3 todos concurrently
2. Verify codes are sequential (26-0001, 26-0002, 26-0003)
3. No gaps allowed

Use:
- testing/testify
- Goroutines for concurrent creation
- Real database (test container)

Test should FAIL initially, exposing the bug.
```

**Expected Output**:
```
✅ test/integration/todo_code_sequence_test.go created
❌ Test FAILS - codes have gaps
```

**Run Test**:
```bash
go test ./test/integration/todo_code_sequence_test.go -v

# Expected output:
# FAIL: Got codes [26-0001, 26-0003, 26-0005] - not sequential
```

---

### Step 2: Analyze Root Cause

**Agent**: `@database-agent`

**Prompt**:
```
Analyze the generate_todo_code() function in migrations/002_code_sequence.sql.

The bug is: concurrent todo creation causes code gaps.

Examine:
1. Is the sequence transaction properly locked?
2. Are there race conditions in code assignment?
3. How does the trigger handle concurrent INSERTs?

Provide root cause analysis.
```

**Expected Analysis**:
```
Root Cause:
- generate_todo_code() uses SELECT FOR UPDATE
- But trigger fires BEFORE INSERT
- Race condition: two transactions can read same sequence number
- Both increment, but one fails → gap created

Solution:
- Use SELECT FOR UPDATE SKIP LOCKED
- Or move to SERIAL sequence (PostgreSQL native)
- Or use advisory locks
```

---

### Step 3: Fix the Bug

**Agent**: `@database-agent`

**Prompt**:
```
Fix the todo code sequence bug.

Create migration:
migrations/004_fix_code_sequence.sql

Solution approach:
1. Replace custom sequence with PostgreSQL SERIAL
2. Update generate_todo_code() function:
   - Use advisory lock for year boundaries
   - Use NEXTVAL for sequence (atomic operation)
   - No race conditions possible

3. Add retry logic for unique constraint violations

Test the fix handles:
- Concurrent creation (100 goroutines)
- Year rollover (sequence resets)
- Failed transactions (rollback doesn't waste numbers)
```

**Expected Output**:
```sql
-- migrations/004_fix_code_sequence.sql

-- Drop old implementation
DROP TRIGGER IF EXISTS assign_todo_code ON todos;
DROP FUNCTION IF EXISTS generate_todo_code();
DROP TABLE IF EXISTS code_sequences;

-- Create per-year sequences
CREATE TABLE code_sequences (
    year INT PRIMARY KEY,
    next_number INT NOT NULL DEFAULT 1
);

-- Improved function with advisory lock
CREATE OR REPLACE FUNCTION generate_todo_code()
RETURNS TRIGGER AS $$
DECLARE
    current_year INT;
    next_num INT;
    new_code TEXT;
BEGIN
    -- Get current year
    current_year := EXTRACT(YEAR FROM NOW()) % 100;
    
    -- Use advisory lock to prevent race conditions
    PERFORM pg_advisory_xact_lock(hashtext('todo_code_' || current_year::text));
    
    -- Get and increment sequence
    INSERT INTO code_sequences (year, next_number)
    VALUES (current_year, 2)
    ON CONFLICT (year) 
    DO UPDATE SET next_number = code_sequences.next_number + 1
    RETURNING next_number - 1 INTO next_num;
    
    -- Format code
    new_code := current_year::text || '-' || LPAD(next_num::text, 4, '0');
    
    -- Assign to todo
    NEW.code := new_code;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger
CREATE TRIGGER assign_todo_code
    BEFORE INSERT ON todos
    FOR EACH ROW
    WHEN (NEW.code IS NULL)
    EXECUTE FUNCTION generate_todo_code();
```

**Apply Migration**:
```bash
migrate -database "$DATABASE_URL" -path ./migrations up
```

---

### Step 4: Verify Fix

**Run Test Again**:
```bash
go test ./test/integration/todo_code_sequence_test.go -v

# Expected output:
# PASS: All codes sequential [26-0001, 26-0002, 26-0003]
```

**Stress Test**:
```bash
# Create test that spawns 100 concurrent todos
go test ./test/integration/todo_code_sequence_test.go -v -run TestConcurrentCreation

# Should pass: all 100 codes sequential with no gaps
```

---

### Step 5: Add Regression Test

**Agent**: `@test-first-agent`

**Prompt**:
```
Add the sequential code test to the BDD suite to prevent regression.

Update features/todo_create.feature:

Scenario: Concurrent todo creation maintains sequential codes
    Given the database is clean
    When 10 users create todos concurrently
    Then all todos should have sequential codes
    And there should be no gaps in code sequence
```

---

### Step 6: Update Documentation

**Create**:
```markdown
# Bug Fix Log

## #001 - Non-Sequential Todo Codes

**Date**: 2026-01-10
**Severity**: Medium
**Status**: Fixed in v1.0.1

### Problem
Todo codes had gaps during concurrent creation.

### Root Cause
Race condition in generate_todo_code() function.

### Fix
- Added pg_advisory_xact_lock for atomicity
- Used INSERT ... ON CONFLICT for safe increment
- Added regression test

### Migration
migrations/004_fix_code_sequence.sql

### Tests
test/integration/todo_code_sequence_test.go
```

---

## Common Bug Types

### 1. Data Validation Bugs

**Example**: Accepting invalid priority values

**Fix Flow**:
1. Test-First: Write test for validation
2. Domain Logic: Add validation to entity.Validate()
3. Test passes

---

### 2. Database Concurrency Bugs

**Example**: Lost updates in concurrent modifications

**Fix Flow**:
1. Test-First: Write concurrent update test
2. Database: Add optimistic locking (version column)
3. Domain Logic: Handle version mismatch errors
4. API Adapter: Return 409 Conflict

---

### 3. API Contract Bugs

**Example**: Wrong HTTP status code returned

**Fix Flow**:
1. Test-First: Add BDD scenario for error case
2. API Adapter: Map domain error to correct status
3. Test passes

---

### 4. Integration Bugs

**Example**: Telegram bot doesn't handle Perplexity API errors

**Fix Flow**:
1. Test-First: Mock API failure
2. AI/NLP: Add retry logic in client
3. Telegram Adapter: Show friendly error to user
4. Test passes

---

## Bug Fix Checklist

- [ ] Bug reproduced with failing test
- [ ] Root cause identified
- [ ] Fix implemented in correct layer
- [ ] All tests pass (including new regression test)
- [ ] No architecture violations introduced
- [ ] Documentation updated
- [ ] Migration created (if database change)
- [ ] Deployed to staging first
- [ ] Verified fix in production

---

## Troubleshooting

### Can't Reproduce Bug
```bash
# Check environment differences
# Staging vs Production database version?
# Different load patterns?

# Add logging to capture context
slog.Error("bug context", 
    "user_id", userID,
    "timestamp", time.Now(),
    "input", input)
```

### Fix Works Locally But Fails in Production
```bash
# Check production logs
railway logs

# Verify migration applied
psql $PRODUCTION_DATABASE_URL -c "\d todos"

# Check environment variables
railway variables
```

### Test Passes But Bug Still Occurs
```bash
# Test might not be comprehensive enough
# Add edge cases
# Test with production-like data volume
```

---

## Prevention

### Add More Tests
- Unit tests for business logic
- Integration tests for database operations
- BDD tests for user scenarios
- Stress tests for concurrency

### Code Review
- Have Domain Logic Agent review changes
- Verify architecture boundaries maintained
- Check error handling

### Monitoring
- Add metrics for critical operations
- Alert on error rate increases
- Log detailed context for errors

---

## Next Steps

After fix is deployed:
1. Monitor error rates
2. Verify no new issues introduced
3. Update documentation
4. Share learnings with team
