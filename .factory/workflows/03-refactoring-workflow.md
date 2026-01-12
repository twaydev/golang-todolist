# Refactoring Workflow

## Overview

This workflow describes how to safely refactor code while maintaining test coverage and architecture integrity.

---

## Refactoring Principles

1. **Tests First**: Ensure comprehensive tests exist before refactoring
2. **Small Steps**: Make incremental changes, test after each
3. **No New Features**: Refactoring only improves structure, not behavior
4. **Architecture Integrity**: Maintain hexagonal architecture boundaries
5. **Continuous Verification**: Tests pass after each change

---

## Example: Extract Intent Parsing into Separate Service

### Current Problem

**TodoService** is doing too much:
- Creating todos
- Updating todos
- **Parsing natural language messages**
- **Calling Perplexity API**

This violates Single Responsibility Principle.

---

### Step 1: Ensure Test Coverage

**Agent**: `@test-first-agent`

**Prompt**:
```
Before refactoring, verify we have comprehensive tests for intent parsing.

Check test coverage for:
- internal/domain/service/todo_service.go
- ParseMessage() method

Run:
go test ./internal/domain/service/... -coverprofile=coverage.out
go tool cover -html=coverage.out

If coverage < 80%, add missing tests for:
- Valid message parsing
- Invalid messages
- API errors
- Edge cases
```

**Coverage Check**:
```bash
go test ./internal/domain/service/... -cover

# If coverage is low, add tests first
# Refactoring without tests is dangerous!
```

---

### Step 2: Extract Service Interface

**Agent**: `@domain-logic-agent`

**Prompt**:
```
Refactor: Extract intent parsing into a separate IntentService.

This is a refactoring - behavior must NOT change.

Steps:
1. Create internal/domain/port/output/intent_parser.go:
   - IntentParser interface with Parse() method

2. Create internal/domain/service/intent_service.go:
   - IntentService implementing business logic
   - No Perplexity API calls (that's infrastructure!)

3. Update internal/domain/service/todo_service.go:
   - Inject IntentParser dependency
   - Remove ParseMessage() method
   - Use injected parser

4. Run tests after EACH change:
   go test ./internal/domain/service/... -v

All tests should still PASS (behavior unchanged).
```

**Expected Changes**:

```go
// 1. New interface
// internal/domain/port/output/intent_parser.go
package output

type Intent struct {
    Action     string // "create", "update", "list", etc.
    Title      string
    Priority   Priority
    DueDate    *time.Time
    Tags       []string
}

type IntentParser interface {
    Parse(ctx context.Context, message string, userID int64) (*Intent, error)
}

// 2. New service
// internal/domain/service/intent_service.go
package service

type IntentService struct {
    llmClient output.LLMClient // Infrastructure dependency
}

func (s *IntentService) Parse(ctx context.Context, message string, userID int64) (*Intent, error) {
    // Business logic: validate, enrich context, etc.
    // Delegate LLM call to injected client
}

// 3. Updated TodoService
// internal/domain/service/todo_service.go
type TodoService struct {
    repo       output.TodoRepository
    intentParser output.IntentParser // NEW: injected
}

func (s *TodoService) CreateFromMessage(ctx context.Context, userID int64, message string) (*Todo, error) {
    intent, err := s.intentParser.Parse(ctx, message, userID)
    if err != nil {
        return nil, err
    }
    
    return s.CreateTodo(ctx, userID, intent.Title, /* ... */)
}
```

**Verify**:
```bash
# All tests should pass
go test ./internal/domain/service/... -v

# No new behavior added
# Just better structure
```

---

### Step 3: Update Infrastructure Adapter

**Agent**: `@ai-nlp-agent`

**Prompt**:
```
Update Perplexity adapter to implement the new IntentParser interface.

Refactoring only - no new features.

Changes:
1. internal/adapter/driven/perplexity/intent_adapter.go:
   - Implement IntentParser interface
   - Move Perplexity API calls here
   
2. Update dependency injection in cmd/bot/main.go:
   - Wire up new IntentParser

All integration tests should pass.
```

---

### Step 4: Update Tests

**Agent**: `@test-first-agent`

**Prompt**:
```
Update tests to use the new IntentParser interface.

Changes:
1. test/mocks/intent_parser_mock.go:
   - Generate mock: mockery --name=IntentParser
   
2. Update test/unit/domain/todo_service_test.go:
   - Inject mock IntentParser
   - Verify Parse() called correctly

All tests must pass.
```

---

### Step 5: Verify Architecture

**Agent**: `@domain-logic-agent`

**Prompt**:
```
Verify the refactoring maintains hexagonal architecture.

Check:
1. Domain layer doesn't import infrastructure:
   go list -f '{{.Imports}}' internal/domain/... | grep perplexity
   # Should return nothing

2. Dependencies point inward (ports in domain, adapters in infrastructure)

3. Run all tests:
   go test ./... -v

4. Check test coverage didn't decrease:
   go test ./... -coverprofile=coverage.out
   go tool cover -func=coverage.out
```

---

## Common Refactoring Patterns

### 1. Extract Method

**Before**:
```go
func (s *TodoService) CreateTodo(ctx context.Context, userID int64, title string) (*Todo, error) {
    // 50 lines of validation logic
    if title == "" {
        return nil, ErrTitleRequired
    }
    if len(title) > 500 {
        return nil, ErrTitleTooLong
    }
    // ... more validation
    
    // Create todo
    todo := &Todo{Title: title}
    return todo, s.repo.Create(ctx, todo)
}
```

**After**:
```go
func (s *TodoService) CreateTodo(ctx context.Context, userID int64, title string) (*Todo, error) {
    if err := s.validateTitle(title); err != nil {
        return nil, err
    }
    
    todo := &Todo{Title: title}
    return todo, s.repo.Create(ctx, todo)
}

func (s *TodoService) validateTitle(title string) error {
    if title == "" {
        return ErrTitleRequired
    }
    if len(title) > 500 {
        return ErrTitleTooLong
    }
    return nil
}
```

---

### 2. Replace Conditional with Polymorphism

**Before**:
```go
func (s *NotificationService) Send(todo *Todo) error {
    if todo.DueDate.Before(time.Now()) {
        return s.sendUrgent(todo)
    } else if todo.Priority == PriorityHigh {
        return s.sendHighPriority(todo)
    } else {
        return s.sendNormal(todo)
    }
}
```

**After**:
```go
type NotificationStrategy interface {
    Send(todo *Todo) error
}

type UrgentStrategy struct{}
type HighPriorityStrategy struct{}
type NormalStrategy struct{}

func (s *NotificationService) Send(todo *Todo) error {
    strategy := s.selectStrategy(todo)
    return strategy.Send(todo)
}
```

---

### 3. Introduce Parameter Object

**Before**:
```go
func CreateTodo(title string, desc string, priority Priority, dueDate *time.Time, tags []string) (*Todo, error) {
    // Too many parameters
}
```

**After**:
```go
type CreateTodoParams struct {
    Title       string
    Description string
    Priority    Priority
    DueDate     *time.Time
    Tags        []string
}

func CreateTodo(params CreateTodoParams) (*Todo, error) {
    // Much cleaner
}
```

---

## Refactoring Checklist

**Before Refactoring**:
- [ ] Tests exist and pass
- [ ] Test coverage > 80%
- [ ] Understand current behavior completely
- [ ] Commit current working state

**During Refactoring**:
- [ ] Make small, incremental changes
- [ ] Run tests after EACH change
- [ ] Keep application working at all times
- [ ] Don't add new features

**After Refactoring**:
- [ ] All tests pass
- [ ] Test coverage maintained or improved
- [ ] No architecture violations
- [ ] Code is more readable
- [ ] Documentation updated
- [ ] Git commit with clear message

---

## Architecture Refactoring Rules

### ✅ Safe Refactorings
- Extract method/interface
- Rename variables/methods
- Move code within same layer
- Replace magic numbers with constants
- Simplify conditionals

### ⚠️ Careful Refactorings
- Moving code between layers (check dependencies)
- Changing interfaces (affects all implementations)
- Modifying database schema (needs migration)
- Changing API contracts (affects clients)

### ❌ Dangerous
- Removing tests to make refactoring easier
- Changing behavior without tests
- Breaking architecture boundaries
- Large refactorings without commits

---

## When to Refactor

### Good Times
- Code smells detected (long methods, duplicate code)
- Adding new feature reveals design issues
- Test coverage is good
- No urgent bugs or deadlines

### Bad Times
- Production is down
- No test coverage
- Right before release
- While adding features (refactor OR add feature, not both)

---

## Code Smells to Refactor

### Long Method
- Method > 50 lines
- **Fix**: Extract method

### Large Class
- Class > 500 lines
- **Fix**: Extract class

### Duplicate Code
- Same logic in multiple places
- **Fix**: Extract method/interface

### Feature Envy
- Method uses more data from another class
- **Fix**: Move method to that class

### Too Many Parameters
- Function has > 4 parameters
- **Fix**: Introduce parameter object

### Infrastructure in Domain
- Domain imports postgres/http/etc
- **Fix**: Extract port interface

---

## Example: Large Refactoring (Step by Step)

### Goal: Split TodoService into Multiple Services

**Current**: TodoService handles create, update, delete, search, templates

**Target**: Separate services for each responsibility

**Steps**:

1. **Week 1**: Extract SearchService
   - Create interface
   - Move search logic
   - Update tests
   - Deploy, verify

2. **Week 2**: Extract TemplateService
   - Create interface
   - Move template logic
   - Update tests
   - Deploy, verify

3. **Week 3**: Refactor remaining TodoService
   - Clean up now-smaller service
   - Improve naming
   - Final tests

**Never**: Try to do all at once!

---

## Rollback Plan

If refactoring goes wrong:

```bash
# Option 1: Git revert
git status
git diff
git checkout -- .

# Option 2: Revert commit
git log --oneline
git revert <commit-hash>

# Option 3: Create fix-forward commit
# Fix the issue, don't hide it
```

---

## Success Metrics

After refactoring:
- ✅ All tests pass
- ✅ Code is more readable
- ✅ Classes/methods are smaller
- ✅ Easier to add new features
- ✅ Architecture cleaner
- ✅ Test coverage maintained
- ✅ No production issues

If metrics aren't met, reconsider the refactoring approach.
