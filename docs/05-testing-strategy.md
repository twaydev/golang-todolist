# Testing Strategy

## Overview

This project follows a comprehensive testing strategy combining **BDD** (Behavior-Driven Development), **TDD** (Test-Driven Development), and multiple testing levels to ensure quality and maintainability.

## Test Pyramid

```
                    ┌───────────────┐
                    │   E2E Tests   │  Manual/Smoke (few)
                    │    (few)      │  Full system validation
                    └───────┬───────┘
                            │
                    ┌───────┴───────┐
                    │  Integration  │  Adapter tests (some)
                    │     Tests     │  Real dependencies
                    └───────┬───────┘
                            │
            ┌───────────────┴───────────────┐
            │        BDD Tests              │  Feature coverage (moderate)
            │      (Godog)                  │  Executable specifications
            └───────────────┬───────────────┘
                            │
    ┌───────────────────────┴───────────────────────┐
    │              Unit Tests                        │  Comprehensive (many)
    │          (testify + mocks)                     │  Domain logic
    └────────────────────────────────────────────────┘
```

### Pyramid Principles

1. **Many Unit Tests** - Fast, isolated, comprehensive coverage
2. **Some Integration Tests** - Verify adapter implementations
3. **Moderate BDD Tests** - Validate business scenarios
4. **Few E2E Tests** - Smoke tests for critical paths

## Testing Levels

### Level 1: Unit Tests (Foundation)

**Purpose**: Test individual components in isolation

**Scope**:
- Domain entities and business rules
- Application services
- Utility functions
- Value objects

**Tools**:
- `testify` (assertions and suites)
- `mockery` (mock generation)

**Characteristics**:
- ✅ Fast (<10ms per test)
- ✅ No external dependencies
- ✅ Use mocks for interfaces
- ✅ Test edge cases thoroughly
- ✅ 80%+ code coverage target

**Example**:
```go
// test/unit/domain/todo_service_test.go
func TestTodoService_CreateTodo_Success(t *testing.T) {
    // Arrange
    mockTodoRepo := mocks.NewMockTodoRepository(t)
    mockUserRepo := mocks.NewMockUserRepository(t)
    svc := service.NewTodoService(mockTodoRepo, mockUserRepo, nil, nil)
    
    mockTodoRepo.EXPECT().
        Create(mock.Anything, mock.MatchedBy(func(todo *entity.Todo) bool {
            return todo.Title == "Test Todo"
        })).
        Return(nil)
    
    // Act
    todo, err := svc.CreateTodo(context.Background(), 123, "Test Todo", nil)
    
    // Assert
    assert.NoError(t, err)
    assert.Equal(t, "Test Todo", todo.Title)
    assert.Equal(t, entity.StatusPending, todo.Status)
}

func TestTodo_Validate_EmptyTitle(t *testing.T) {
    // Arrange
    todo := &entity.Todo{Title: ""}
    
    // Act
    err := todo.Validate()
    
    // Assert
    assert.Error(t, err)
    assert.Equal(t, entity.ErrTitleRequired, err)
}
```

**What to Test**:
- ✅ Happy path scenarios
- ✅ Error conditions
- ✅ Boundary values
- ✅ Business rule validation
- ✅ State transitions
- ✅ Edge cases

### Level 2: BDD Tests (Behavior)

**Purpose**: Test business scenarios and user stories

**Scope**:
- Complete user workflows
- Feature specifications
- Acceptance criteria
- Business rules

**Tools**:
- `godog` (Cucumber for Go)
- Gherkin syntax

**Characteristics**:
- ✅ Written in business language
- ✅ Executable specifications
- ✅ Use in-memory adapters
- ✅ Test through domain layer
- ✅ Define BEFORE implementation

**Example**:
```gherkin
# features/todo_create.feature
Feature: Create Todo
  As a user
  I want to create todos using natural language
  So that I can quickly capture tasks

  Background:
    Given a user with ID 123456789
    And the user's language is "en"

  Scenario: Create a simple todo
    When the user sends "Buy groceries tomorrow"
    Then a todo should be created with title "Buy groceries"
    And the todo should have due date "tomorrow"
    And the user should receive a confirmation message

  Scenario: Validation error for empty title
    When the user sends ""
    Then no todo should be created
    And the user should receive an error message "Title is required"

  Scenario: Create high priority todo
    When the user sends "Urgent: Call mom"
    Then a todo should be created with title "Call mom"
    And the todo should have priority "high"
```

**Step Definitions**:
```go
// test/bdd/todo_steps_test.go
type todoContext struct {
    userID       int64
    todoRepo     *memory.TodoRepository
    userRepo     *memory.UserRepository
    todoService  *service.TodoService
    lastResponse string
    lastError    error
}

func (tc *todoContext) aUserWithID(userID int64) error {
    tc.userID = userID
    tc.todoRepo = memory.NewTodoRepository()
    tc.userRepo = memory.NewUserRepository()
    tc.todoService = service.NewTodoService(tc.todoRepo, tc.userRepo, nil, nil)
    return nil
}

func (tc *todoContext) theUserSends(message string) error {
    tc.lastResponse, tc.lastError = tc.todoService.HandleMessage(
        context.Background(), tc.userID, message)
    return nil
}

func (tc *todoContext) aTodoShouldBeCreatedWithTitle(title string) error {
    todos, _ := tc.todoRepo.List(context.Background(), tc.userID, port.ListFilters{})
    for _, todo := range todos {
        if todo.Title == title {
            return nil
        }
    }
    return fmt.Errorf("todo with title %q not found", title)
}
```

**Coverage Goals**:
- ✅ All user stories have scenarios
- ✅ All acceptance criteria covered
- ✅ Happy paths validated
- ✅ Error paths validated
- ✅ Edge cases documented

### Level 3: Integration Tests (Infrastructure)

**Purpose**: Test adapters with real external systems

**Scope**:
- Database repositories
- API clients (Perplexity)
- HTTP endpoints
- Message queues

**Tools**:
- `testcontainers-go` (Docker test containers)
- Real PostgreSQL database
- HTTP test servers

**Characteristics**:
- ✅ Use real dependencies
- ✅ Slower than unit tests
- ✅ Verify adapter implementations
- ✅ Test connection handling
- ✅ Validate data persistence

**Example**:
```go
// test/integration/postgres_test.go
func TestPostgresTodoRepository_Create(t *testing.T) {
    // Setup test database
    ctx := context.Background()
    container := setupPostgresContainer(t)
    defer container.Terminate(ctx)
    
    db := connectToContainer(t, container)
    defer db.Close()
    
    repo := postgres.NewTodoRepository(db)
    
    // Test
    todo := &entity.Todo{
        TelegramUserID: 123,
        Title:          "Integration test todo",
        Status:         entity.StatusPending,
    }
    
    err := repo.Create(ctx, todo)
    
    // Verify
    assert.NoError(t, err)
    assert.NotEmpty(t, todo.ID)
    assert.NotEmpty(t, todo.Code)
    
    // Verify in database
    retrieved, err := repo.GetByID(ctx, 123, todo.ID)
    assert.NoError(t, err)
    assert.Equal(t, todo.Title, retrieved.Title)
}

// test/integration/http_test.go
func TestTodoAPI_CreateTodo(t *testing.T) {
    // Setup test server
    server := setupTestServer(t)
    defer server.Close()
    
    // Create request
    body := `{"title": "API test todo", "priority": "high"}`
    req := httptest.NewRequest("POST", "/api/v1/todos", strings.NewReader(body))
    req.Header.Set("Authorization", "Bearer "+testToken)
    req.Header.Set("Content-Type", "application/json")
    
    // Execute
    rec := httptest.NewRecorder()
    server.Handler.ServeHTTP(rec, req)
    
    // Verify
    assert.Equal(t, 201, rec.Code)
    
    var response TodoResponse
    json.Unmarshal(rec.Body.Bytes(), &response)
    assert.Equal(t, "API test todo", response.Title)
    assert.Equal(t, "high", response.Priority)
}
```

**What to Test**:
- ✅ CRUD operations work
- ✅ Transactions rollback on error
- ✅ Connection pooling
- ✅ Query performance
- ✅ Data integrity
- ✅ Error handling

### Level 4: E2E Tests (System)

**Purpose**: Validate complete system behavior

**Scope**:
- Critical user journeys
- Smoke tests
- Deployment verification

**Tools**:
- Manual testing
- Automated smoke tests
- Postman collections

**Characteristics**:
- ✅ Full system stack
- ✅ Real external systems
- ✅ Slow execution
- ✅ Few tests (critical paths)
- ✅ Run before deployment

**Example Scenarios**:
1. User creates todo via Telegram → Verify in database → List via REST API
2. User creates todo via API → Complete via Telegram → Verify status
3. User sets language to Vietnamese → Creates todo → Receives Vietnamese response

## Test Organization

### Directory Structure

```
test/
├── unit/                       # Unit tests
│   ├── domain/
│   │   ├── todo_service_test.go
│   │   ├── user_service_test.go
│   │   └── entity_test.go
│   └── adapter/
│       └── dto_mapper_test.go
│
├── bdd/                        # BDD tests
│   ├── todo_steps_test.go
│   ├── user_steps_test.go
│   ├── template_steps_test.go
│   └── main_test.go            # Test runner
│
├── integration/                # Integration tests
│   ├── postgres_test.go
│   ├── http_test.go
│   └── perplexity_test.go
│
├── mocks/                      # Generated mocks
│   ├── mock_todo_repository.go
│   ├── mock_user_repository.go
│   └── mock_intent_analyzer.go
│
└── fixtures/                   # Test data
    ├── todos.json
    └── users.json
```

### File Naming Conventions

- `*_test.go` - Unit tests
- `*_steps_test.go` - BDD step definitions
- `mock_*.go` - Generated mocks
- `*_integration_test.go` - Integration tests

## Testing Tools

### testify

**Purpose**: Assertions and test suites

**Installation**:
```bash
go get github.com/stretchr/testify
```

**Usage**:
```go
import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestExample(t *testing.T) {
    // assert continues on failure
    assert.Equal(t, expected, actual)
    assert.NoError(t, err)
    assert.True(t, condition)
    
    // require stops on failure
    require.NoError(t, err)
    require.NotNil(t, obj)
}
```

### mockery

**Purpose**: Generate mocks from interfaces

**Installation**:
```bash
go install github.com/vektra/mockery/v2@latest
```

**Configuration** (`.mockery.yaml`):
```yaml
with-expecter: true
dir: "test/mocks"
outpkg: mocks
packages:
  github.com/yourusername/todobot/internal/domain/port/output:
    interfaces:
      TodoRepository:
      UserRepository:
      IntentAnalyzer:
```

**Generate**:
```bash
mockery --all
```

**Usage**:
```go
mockRepo := mocks.NewMockTodoRepository(t)
mockRepo.EXPECT().
    Create(mock.Anything, mock.Anything).
    Return(nil)
```

### godog

**Purpose**: BDD framework

**Installation**:
```bash
go get github.com/cucumber/godog/cmd/godog@latest
```

**Run Tests**:
```bash
godog features/
```

**Configuration**:
```go
// test/bdd/main_test.go
func TestFeatures(t *testing.T) {
    suite := godog.TestSuite{
        ScenarioInitializer: InitializeScenario,
        Options: &godog.Options{
            Format:   "pretty",
            Paths:    []string{"../../features"},
            TestingT: t,
        },
    }
    
    if suite.Run() != 0 {
        t.Fatal("non-zero status returned")
    }
}
```

## Coverage Goals

### Target Coverage by Layer

| Layer | Coverage Target | Why |
|-------|----------------|-----|
| Domain Entities | 100% | Critical business logic |
| Domain Services | 90%+ | Core use cases |
| Adapters | 70%+ | Infrastructure code |
| DTOs/Mappers | 80%+ | Data transformation |
| Overall | 80%+ | Comprehensive coverage |

### Measuring Coverage

```bash
# Generate coverage report
go test -coverprofile=coverage.out ./...

# View in browser
go tool cover -html=coverage.out

# Check coverage percentage
go tool cover -func=coverage.out | grep total
```

### Coverage Report Structure

```
coverage.out
coverage-unit.out       # Unit tests only
coverage-bdd.out        # BDD tests only
coverage-integration.out # Integration tests only
```

## Test Execution

### Running Tests

```bash
# All tests
make test

# Unit tests only
make test-unit
go test ./test/unit/... -v

# BDD tests only
make test-bdd
go test ./test/bdd/... -v

# Integration tests only
make test-integration
go test ./test/integration/... -v -tags=integration

# Specific package
go test ./internal/domain/service -v

# Specific test
go test ./internal/domain/service -v -run TestTodoService_CreateTodo

# With coverage
go test ./... -cover

# With race detector
go test ./... -race

# Parallel execution
go test ./... -parallel 4
```

### Makefile Targets

```makefile
# Makefile
.PHONY: test test-unit test-bdd test-integration coverage lint

test: test-unit test-bdd test-integration

test-unit:
	go test -v -race -coverprofile=coverage-unit.out ./internal/...

test-bdd:
	go test -v -coverprofile=coverage-bdd.out ./test/bdd/...

test-integration:
	go test -v -tags=integration -coverprofile=coverage-integration.out ./test/integration/...

coverage:
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out

mocks:
	mockery --all

lint:
	golangci-lint run ./...

ci: lint test coverage
```

## Test Data Management

### Fixtures

Store reusable test data:

```go
// test/fixtures/todos.go
var TestTodos = []*entity.Todo{
    {
        ID:             "todo-1",
        TelegramUserID: 123,
        Title:          "Test Todo 1",
        Status:         entity.StatusPending,
    },
    {
        ID:             "todo-2",
        TelegramUserID: 123,
        Title:          "Test Todo 2",
        Status:         entity.StatusCompleted,
    },
}
```

### Test Helpers

```go
// test/helpers/helpers.go
func CreateTestTodo(title string) *entity.Todo {
    return &entity.Todo{
        ID:             uuid.New().String(),
        TelegramUserID: 123,
        Title:          title,
        Status:         entity.StatusPending,
        Priority:       entity.PriorityMedium,
        CreatedAt:      time.Now(),
        UpdatedAt:      time.Now(),
    }
}

func AssertTodoEqual(t *testing.T, expected, actual *entity.Todo) {
    assert.Equal(t, expected.Title, actual.Title)
    assert.Equal(t, expected.Status, actual.Status)
    assert.Equal(t, expected.Priority, actual.Priority)
}
```

## Best Practices

### Unit Testing

✅ **Test Behavior, Not Implementation**
```go
// ❌ BAD - testing implementation
func TestTodoService_CreateTodo_CallsRepository(t *testing.T) {
    mockRepo.EXPECT().Create(mock.Anything, mock.Anything).Return(nil)
    svc.CreateTodo(...)
    // Just testing that Create was called
}

// ✅ GOOD - testing behavior
func TestTodoService_CreateTodo_ReturnsTodoWithCorrectFields(t *testing.T) {
    mockRepo.EXPECT().Create(mock.Anything, mock.Anything).Return(nil)
    todo, err := svc.CreateTodo(ctx, 123, "Test", nil)
    assert.NoError(t, err)
    assert.Equal(t, "Test", todo.Title)
    assert.Equal(t, StatusPending, todo.Status)
}
```

✅ **Use Table-Driven Tests for Multiple Cases**
```go
func TestTodo_Validate(t *testing.T) {
    tests := []struct {
        name    string
        todo    *entity.Todo
        wantErr error
    }{
        {"empty title", &entity.Todo{Title: ""}, entity.ErrTitleRequired},
        {"title too long", &entity.Todo{Title: strings.Repeat("a", 501)}, entity.ErrTitleTooLong},
        {"valid todo", &entity.Todo{Title: "Valid"}, nil},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := tt.todo.Validate()
            if tt.wantErr != nil {
                assert.Equal(t, tt.wantErr, err)
            } else {
                assert.NoError(t, err)
            }
        })
    }
}
```

✅ **Arrange-Act-Assert Pattern**
```go
func TestExample(t *testing.T) {
    // Arrange - set up test dependencies
    mockRepo := mocks.NewMockRepository(t)
    svc := service.New(mockRepo)
    
    // Act - execute the code being tested
    result, err := svc.DoSomething()
    
    // Assert - verify the results
    assert.NoError(t, err)
    assert.Equal(t, expected, result)
}
```

### BDD Testing

✅ **Write Scenarios in Business Language**
```gherkin
# ✅ GOOD
Scenario: User creates a high priority todo
  When the user sends "Urgent: Call mom"
  Then a todo should be created with priority "high"

# ❌ BAD - too technical
Scenario: TodoService.CreateTodo called with priority parameter
  When CreateTodo is called with priority="high"
  Then repository.Create is called
```

✅ **Keep Scenarios Independent**
- Each scenario should be runnable in isolation
- Don't depend on execution order
- Reset state in Background

✅ **Use Background for Common Setup**
```gherkin
Background:
  Given a user with ID 123456789
  And the user's language is "en"
  And the database is empty

Scenario: ...
```

### Integration Testing

✅ **Use Test Containers**
```go
func setupPostgresContainer(t *testing.T) testcontainers.Container {
    ctx := context.Background()
    req := testcontainers.ContainerRequest{
        Image:        "postgres:15-alpine",
        ExposedPorts: []string{"5432/tcp"},
        Env: map[string]string{
            "POSTGRES_PASSWORD": "test",
            "POSTGRES_DB":       "testdb",
        },
        WaitingFor: wait.ForLog("database system is ready"),
    }
    
    container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: req,
        Started:          true,
    })
    require.NoError(t, err)
    return container
}
```

✅ **Clean Up After Tests**
```go
func TestWithDatabase(t *testing.T) {
    db := setupTestDB(t)
    defer db.Close()  // Always clean up
    
    // Test code...
}
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      
      - name: Run unit tests
        run: make test-unit
      
      - name: Run BDD tests
        run: make test-bdd
      
      - name: Run integration tests
        run: make test-integration
      
      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage.out
```

## Troubleshooting

### Common Issues

**Flaky Tests**:
- Use deterministic test data
- Avoid sleep() - use channels/context
- Clean up shared resources
- Run with `-count=10` to detect

**Slow Tests**:
- Run unit tests separately from integration
- Use parallel execution: `-parallel 4`
- Profile tests: `go test -cpuprofile=cpu.out`
- Mock external services

**Coverage Gaps**:
- Use `go tool cover` to find uncovered lines
- Focus on critical paths first
- Test error conditions
- Add table-driven tests for multiple cases

## Summary

### Testing Philosophy

1. **Test First** - Write tests before code (TDD/BDD)
2. **Test Layers** - Each layer has appropriate tests
3. **Fast Feedback** - Unit tests run in milliseconds
4. **Comprehensive** - 80%+ coverage with focus on domain
5. **Maintainable** - Clear, readable test code

### Key Metrics

- ✅ 80%+ overall test coverage
- ✅ 100% coverage for domain entities
- ✅ All user stories have BDD scenarios
- ✅ Integration tests for all adapters
- ✅ Unit tests run <5 seconds
- ✅ Full test suite runs <60 seconds

## Next Steps

- Read [TDD/BDD Workflow](04-tdd-bdd-workflow.md) for step-by-step process
- See [Agent Specifications](19-agent-specifications.md) for test-first agent details
- Review [Domain Entities](06-domain-entities.md) for testable business logic
