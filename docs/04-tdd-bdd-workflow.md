# TDD/BDD Workflow

## Overview

This project follows a **TDD/BDD-first methodology** where features and tests are defined BEFORE implementation.

## 7-Step Development Process

```
1. DEFINE FEATURE (BDD)
   ├── Write .feature file in Gherkin syntax
   ├── Define acceptance criteria
   └── Review with stakeholders
          │
          ▼
2. IMPLEMENT STEP DEFINITIONS (BDD)
   ├── Write step definition stubs (failing tests)
   ├── Define test context and helpers
   └── Run tests (RED state)
          │
          ▼
3. WRITE UNIT TESTS (TDD)
   ├── Write failing unit tests for domain logic
   ├── Define interfaces and contracts
   └── Run tests (RED state)
          │
          ▼
4. IMPLEMENT DOMAIN LOGIC (TDD)
   ├── Write minimal code to pass tests
   ├── Implement entities and services
   └── Run tests (GREEN state)
          │
          ▼
5. IMPLEMENT ADAPTERS
   ├── Write adapter tests
   ├── Implement infrastructure code
   └── Run all tests (GREEN state)
          │
          ▼
6. REFACTOR & OPTIMIZE
   ├── Clean up code
   ├── Optimize performance
   └── Ensure tests still pass (GREEN state)
          │
          ▼
7. INTEGRATION TESTING
   ├── Run BDD scenarios end-to-end
   ├── Test with real adapters
   └── Verify acceptance criteria met
```

## Test Pyramid Implementation

```
                    ┌───────────────┐
                    │  BDD Features │  ← Acceptance tests (Godog)
                    │  (Gherkin)    │    Define user stories FIRST
                    └───────┬───────┘
                            │
                    ┌───────┴───────┐
                    │  Integration  │  ← Test adapters with real dependencies
                    │     Tests     │
                    └───────┬───────┘
                            │
            ┌───────────────┴───────────────┐
            │          Unit Tests           │  ← TDD for domain logic
            │     (testify + mockery)       │
            └───────────────────────────────┘
```

## Complete Example: Feature-First Development

### Step 1: Define Feature File (FIRST)

Create `features/todo_create.feature`:

```gherkin
Feature: Create Todo via REST API
  As a user
  I want to create todos via REST API
  So that I can integrate with other systems

  Background:
    Given the REST API is running
    And I have a valid API token for user 123456789

  Scenario: Create a simple todo via POST
    When I POST to "/api/v1/todos" with:
      """
      {
        "title": "Buy groceries",
        "priority": "medium",
        "tags": ["shopping"]
      }
      """
    Then the response status should be 201
    And the response should contain:
      | field    | value          |
      | title    | Buy groceries  |
      | priority | medium         |
      | status   | pending        |
    And a todo should exist in the database with title "Buy groceries"

  Scenario: Create todo with natural language via Telegram
    Given the user's language is "en"
    When the user sends message "Buy milk tomorrow"
    Then AI should parse the intent
    And a todo should be created with:
      | field    | value      |
      | title    | Buy milk   |
      | due_date | tomorrow   |
```

**Checkpoint**: Feature defined, acceptance criteria clear ✅

### Step 2: Write Step Definitions (SECOND)

Create `test/bdd/api_steps_test.go`:

```go
package bdd

import (
    "github.com/cucumber/godog"
)

type testContext struct {
    apiClient    *TestAPIClient
    lastResponse *APIResponse
    lastError    error
}

func (tc *testContext) theRESTAPIIsRunning() error {
    tc.apiClient = NewTestAPIClient()
    return nil
}

func (tc *testContext) iHaveAValidAPITokenForUser(userID int64) error {
    tc.apiClient.SetAuthToken(generateTestToken(userID))
    return nil
}

func (tc *testContext) iPOSTToWith(endpoint string, body *godog.DocString) error {
    tc.lastResponse, tc.lastError = tc.apiClient.POST(endpoint, body.Content)
    return nil
}

func (tc *testContext) theResponseStatusShouldBe(expectedStatus int) error {
    if tc.lastResponse.Status != expectedStatus {
        return fmt.Errorf("expected status %d, got %d", expectedStatus, tc.lastResponse.Status)
    }
    return nil
}

func (tc *testContext) theResponseShouldContain(table *godog.Table) error {
    for _, row := range table.Rows[1:] { // Skip header
        field := row.Cells[0].Value
        expectedValue := row.Cells[1].Value
        actualValue := tc.lastResponse.GetField(field)
        if actualValue != expectedValue {
            return fmt.Errorf("field %s: expected %s, got %s", field, expectedValue, actualValue)
        }
    }
    return nil
}
```

**Checkpoint**: Step definitions created, tests FAIL (RED state) ❌

### Step 3: Write Unit Tests (THIRD)

Create `test/unit/domain/todo_service_test.go`:

```go
package domain_test

import (
    "context"
    "testing"
    
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
    
    "todobot/internal/domain/entity"
    "todobot/internal/domain/service"
    "todobot/test/mocks"
)

func TestTodoService_CreateTodo_Success(t *testing.T) {
    // Arrange
    mockTodoRepo := mocks.NewMockTodoRepository(t)
    mockUserRepo := mocks.NewMockUserRepository(t)
    svc := service.NewTodoService(mockTodoRepo, mockUserRepo, nil, nil)
    
    mockTodoRepo.EXPECT().
        Create(mock.Anything, mock.MatchedBy(func(todo *entity.Todo) bool {
            return todo.Title == "Buy groceries" && 
                   todo.TelegramUserID == 123456789
        })).
        Return(nil)
    
    // Act
    todo, err := svc.CreateTodo(context.Background(), 123456789, "Buy groceries", nil)
    
    // Assert
    assert.NoError(t, err)
    assert.NotNil(t, todo)
    assert.Equal(t, "Buy groceries", todo.Title)
    assert.Equal(t, entity.StatusPending, todo.Status)
}

func TestTodoService_CreateTodo_ValidationError(t *testing.T) {
    // Arrange
    svc := service.NewTodoService(nil, nil, nil, nil)
    
    // Act
    todo, err := svc.CreateTodo(context.Background(), 123456789, "", nil)
    
    // Assert
    assert.Error(t, err)
    assert.Nil(t, todo)
    assert.Contains(t, err.Error(), "title required")
}
```

**Checkpoint**: Unit tests created, tests FAIL (RED state) ❌

### Step 4: Implement Domain Logic (FOURTH)

Create `internal/domain/entity/todo.go`:

```go
package entity

import (
    "errors"
    "time"
)

var (
    ErrTitleRequired = errors.New("title is required")
)

type Todo struct {
    ID             string
    TelegramUserID int64
    Code           string
    Title          string
    Description    *string
    DueDate        *time.Time
    Priority       Priority
    Status         Status
    Tags           []string
    CreatedAt      time.Time
    UpdatedAt      time.Time
}

func (t *Todo) Validate() error {
    if t.Title == "" {
        return ErrTitleRequired
    }
    return nil
}
```

Create `internal/domain/service/todo_service.go`:

```go
package service

import (
    "context"
    
    "todobot/internal/domain/entity"
    "todobot/internal/domain/port/output"
)

type TodoService struct {
    todoRepo output.TodoRepository
    userRepo output.UserRepository
}

func NewTodoService(
    todoRepo output.TodoRepository,
    userRepo output.UserRepository,
    intentAnalyzer output.IntentAnalyzer,
    i18n *i18n.Translator,
) *TodoService {
    return &TodoService{
        todoRepo: todoRepo,
        userRepo: userRepo,
    }
}

func (s *TodoService) CreateTodo(
    ctx context.Context,
    userID int64,
    title string,
    options *CreateOptions,
) (*entity.Todo, error) {
    todo := &entity.Todo{
        TelegramUserID: userID,
        Title:          title,
        Status:         entity.StatusPending,
        Priority:       entity.PriorityMedium,
    }
    
    if err := todo.Validate(); err != nil {
        return nil, err
    }
    
    if err := s.todoRepo.Create(ctx, todo); err != nil {
        return nil, err
    }
    
    return todo, nil
}
```

**Checkpoint**: Domain logic implemented, unit tests PASS (GREEN state) ✅

### Step 5: Implement HTTP Adapter (FIFTH)

Create `internal/adapter/driving/http/handlers.go`:

```go
package http

import (
    "net/http"
    
    "github.com/labstack/echo/v4"
    
    "todobot/internal/domain/service"
)

type TodoHandler struct {
    todoService *service.TodoService
}

func NewTodoHandler(todoSvc *service.TodoService) *TodoHandler {
    return &TodoHandler{todoService: todoSvc}
}

func (h *TodoHandler) CreateTodo(c echo.Context) error {
    var req CreateTodoRequest
    if err := c.Bind(&req); err != nil {
        return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
    }
    
    if err := req.Validate(); err != nil {
        return echo.NewHTTPError(http.StatusBadRequest, err.Error())
    }
    
    userID := getUserIDFromContext(c)
    
    todo, err := h.todoService.CreateTodo(
        c.Request().Context(),
        userID,
        req.Title,
        req.toOptions(),
    )
    if err != nil {
        return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
    }
    
    return c.JSON(http.StatusCreated, toTodoResponse(todo))
}
```

Create `internal/adapter/driving/http/dto.go`:

```go
package http

type CreateTodoRequest struct {
    Title       string   `json:"title" validate:"required,min=1,max=500"`
    Description *string  `json:"description,omitempty"`
    Priority    *string  `json:"priority,omitempty" validate:"omitempty,oneof=low medium high"`
    DueDate     *string  `json:"due_date,omitempty"`
    Tags        []string `json:"tags,omitempty"`
}

func (req *CreateTodoRequest) Validate() error {
    // Use go-validator or custom validation
    return nil
}

func (req *CreateTodoRequest) toOptions() *service.CreateOptions {
    // Convert DTO to domain options
    return &service.CreateOptions{
        // Map fields
    }
}
```

**Checkpoint**: Adapters implemented, integration tests PASS ✅

### Step 6: Run BDD Tests (VERIFY)

```bash
# Run all BDD scenarios
go test ./test/bdd/... -v

# Output:
Feature: Create Todo via REST API
  Scenario: Create a simple todo via POST
    ✓ Given the REST API is running
    ✓ And I have a valid API token for user 123456789
    ✓ When I POST to "/api/v1/todos" with:...
    ✓ Then the response status should be 201
    ✓ And the response should contain:...
    ✓ And a todo should exist in the database with title "Buy groceries"

1 scenario (1 passed)
6 steps (6 passed)
```

**Checkpoint**: All BDD tests PASS (GREEN state) ✅

### Step 7: Refactor & Optimize

- Extract common logic
- Improve error messages
- Add logging
- Optimize database queries
- Ensure all tests still pass

## RED → GREEN → REFACTOR Cycle

```
┌─────────────────────────────────────────────┐
│                                             │
│  1. RED: Write failing test                │
│  2. GREEN: Write minimal code to pass      │
│  3. REFACTOR: Improve code, tests pass     │
│                                             │
│  Repeat for each requirement               │
│                                             │
└─────────────────────────────────────────────┘
```

## Best Practices

### For BDD Features
- ✅ Write in business language, not technical terms
- ✅ Focus on "what", not "how"
- ✅ Use concrete examples
- ✅ Keep scenarios independent
- ✅ One feature per file

### For TDD Unit Tests
- ✅ Test one thing at a time
- ✅ Use descriptive test names
- ✅ Arrange-Act-Assert pattern
- ✅ Use mocks for external dependencies
- ✅ Test edge cases and error conditions

### For Implementation
- ✅ Write minimum code to pass tests
- ✅ Refactor after tests pass
- ✅ Keep domain logic pure (no infrastructure)
- ✅ Follow SOLID principles
- ✅ Add logging and error handling

## Running Tests

```bash
# Run all tests
make test

# Run only BDD tests
make test-bdd

# Run only unit tests
make test-unit

# Run with coverage
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# Run specific feature
go test ./test/bdd/... -v -godog.tags=@todo_create
```

## Next Steps

- See [Testing Strategy](05-testing-strategy.md) for comprehensive testing approach
- Read [Multi-Agent Architecture](18-multi-agent-architecture.md) to understand how specialized agents implement this workflow
