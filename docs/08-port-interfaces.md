# Port Interfaces

## Overview

Ports are **interfaces** that define contracts between the domain and external systems. They enable the hexagonal architecture by providing abstraction boundaries.

**Location**: `internal/domain/port/`

## Two Types of Ports

### Input Ports (Driving)
- Define how external world calls domain
- Implemented by domain services
- Called by driving adapters (HTTP, Telegram)
- Location: `internal/domain/port/input/`

### Output Ports (Driven)
- Define how domain calls external systems
- Implemented by driven adapters (PostgreSQL, APIs)
- Called by domain services
- Location: `internal/domain/port/output/`

## Output Ports

### TodoRepository

**Purpose**: Persistence operations for todos

**Location**: `internal/domain/port/output/todo_repository.go`

```go
package output

import (
    "context"
    "time"
    
    "todobot/internal/domain/entity"
)

type TodoRepository interface {
    // Create a new todo
    Create(ctx context.Context, todo *entity.Todo) error
    
    // Update existing todo
    Update(ctx context.Context, todo *entity.Todo) error
    
    // Delete a todo
    Delete(ctx context.Context, userID int64, todoID string) error
    
    // Get todo by ID
    GetByID(ctx context.Context, userID int64, todoID string) (*entity.Todo, error)
    
    // Get todo by code (YY-NNNN format)
    GetByCode(ctx context.Context, userID int64, code string) (*entity.Todo, error)
    
    // List todos with filtering
    List(ctx context.Context, userID int64, filters ListFilters) ([]*entity.Todo, error)
    
    // Full-text search
    Search(ctx context.Context, userID int64, query string) ([]*entity.Todo, error)
}

// ListFilters for querying todos
type ListFilters struct {
    Status    *entity.Status
    Priority  *entity.Priority
    Tags      []string
    DueBefore *time.Time
    DueAfter  *time.Time
    Limit     int
    Offset    int
}
```

**Implementations**:
- `internal/adapter/driven/postgres/todo_repo.go` - PostgreSQL
- `internal/adapter/driven/memory/todo_repo.go` - In-memory (testing)

---

### UserRepository

**Purpose**: Manage user preferences

**Location**: `internal/domain/port/output/user_repository.go`

```go
package output

import (
    "context"
    
    "todobot/internal/domain/entity"
)

type UserRepository interface {
    // Get user preferences
    GetPreferences(ctx context.Context, userID int64) (*entity.UserPreferences, error)
    
    // Set language preference
    SetLanguage(ctx context.Context, userID int64, lang entity.Language) error
    
    // Set timezone preference
    SetTimezone(ctx context.Context, userID int64, tz string) error
    
    // Create or update full preferences
    UpsertPreferences(ctx context.Context, prefs *entity.UserPreferences) error
}
```

**Implementations**:
- `internal/adapter/driven/postgres/user_repo.go` - PostgreSQL
- `internal/adapter/driven/memory/user_repo.go` - In-memory (testing)

---

### IntentAnalyzer

**Purpose**: Parse natural language into structured intent

**Location**: `internal/domain/port/output/intent_analyzer.go`

```go
package output

import (
    "context"
    
    "todobot/internal/domain/entity"
)

type IntentAnalyzer interface {
    // Analyze natural language message
    Analyze(
        ctx context.Context,
        message string,
        existingTodos []*entity.Todo,
        lang entity.Language,
    ) (*entity.ParsedIntent, error)
}
```

**Implementations**:
- `internal/adapter/driven/perplexity/client.go` - Perplexity AI
- `internal/adapter/driven/memory/intent_analyzer.go` - Mock (testing)

---

### TemplateRepository

**Purpose**: Manage task templates

**Location**: `internal/domain/port/output/template_repository.go`

```go
package output

import (
    "context"
    
    "todobot/internal/domain/entity"
)

type TemplateRepository interface {
    // Get template by name (user templates first, then global)
    GetByName(ctx context.Context, userID int64, name string) (*entity.TaskTemplate, error)
    
    // List all templates available to user
    List(ctx context.Context, userID int64) ([]*entity.TaskTemplate, error)
    
    // List only global templates
    ListGlobal(ctx context.Context) ([]*entity.TaskTemplate, error)
    
    // User template CRUD
    Create(ctx context.Context, template *entity.TaskTemplate) error
    Update(ctx context.Context, template *entity.TaskTemplate) error
    Delete(ctx context.Context, userID int64, name string) error
}
```

**Implementations**:
- `internal/adapter/driven/filesystem/template_repo.go` - File-based (global templates)
- `internal/adapter/driven/postgres/template_repo.go` - PostgreSQL (user templates)

---

### Notifier

**Purpose**: Send notifications to users

**Location**: `internal/domain/port/output/notifier.go`

```go
package output

import (
    "context"
)

type Notifier interface {
    // Send notification to user
    SendNotification(ctx context.Context, userID int64, message string) error
    
    // Send reminder for overdue todos
    SendReminder(ctx context.Context, userID int64, todoID string) error
}
```

**Implementations**:
- `internal/adapter/driven/telegram/notifier.go` - Telegram notifications
- `internal/adapter/driven/memory/notifier.go` - No-op (testing)

---

## Input Ports

Input ports are less common in this architecture since domain services act as the primary entry points. However, they can be defined for complex scenarios.

### MessageHandler

**Purpose**: Handle incoming messages (abstraction for different message sources)

**Location**: `internal/domain/port/input/message_handler.go`

```go
package input

import (
    "context"
)

type MessageHandler interface {
    // Handle text message from user
    HandleMessage(ctx context.Context, userID int64, message string) (string, error)
}
```

**Implementation**:
- `internal/domain/service/todo_service.go` implements this conceptually

---

## Design Patterns

### 1. Context First

All methods take `context.Context` as first parameter:

```go
Create(ctx context.Context, todo *entity.Todo) error
```

**Benefits**:
- Cancellation support
- Timeout propagation
- Request tracing

### 2. Return Entity Pointers

Return pointers for entities:

```go
GetByID(ctx context.Context, userID int64, todoID string) (*entity.Todo, error)
```

**Benefits**:
- Nil represents "not found"
- Avoid large struct copies

### 3. Accept Interfaces, Return Structs

```go
// Port interface
type TodoRepository interface {
    Create(ctx context.Context, todo *entity.Todo) error
}

// Service accepts interface
type TodoService struct {
    todoRepo TodoRepository  // Interface
}

// Service returns struct
func (s *TodoService) CreateTodo(...) (*entity.Todo, error) {
    return todo, nil  // Struct
}
```

### 4. Error Wrapping

Wrap errors for context:

```go
func (s *TodoService) CreateTodo(...) error {
    if err := s.todoRepo.Create(ctx, todo); err != nil {
        return fmt.Errorf("failed to create todo: %w", err)
    }
    return nil
}
```

### 5. Options Pattern for Complex Filters

```go
type ListFilters struct {
    Status    *entity.Status
    Priority  *entity.Priority
    Tags      []string
    Limit     int
}

// Usage
filters := output.ListFilters{
    Status: &entity.StatusPending,
    Limit:  10,
}
todos, err := repo.List(ctx, userID, filters)
```

---

## Implementation Examples

### PostgreSQL Implementation

```go
// internal/adapter/driven/postgres/todo_repo.go
type PostgresTodoRepository struct {
    pool *pgxpool.Pool
}

func NewTodoRepository(pool *pgxpool.Pool) *PostgresTodoRepository {
    return &PostgresTodoRepository{pool: pool}
}

// Implements output.TodoRepository
func (r *PostgresTodoRepository) Create(ctx context.Context, todo *entity.Todo) error {
    query := `
        INSERT INTO todos (telegram_user_id, title, description, due_date, priority, status, tags)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING id, code, created_at, updated_at`
    
    return r.pool.QueryRow(ctx, query,
        todo.TelegramUserID,
        todo.Title,
        todo.Description,
        todo.DueDate,
        todo.Priority,
        todo.Status,
        todo.Tags,
    ).Scan(&todo.ID, &todo.Code, &todo.CreatedAt, &todo.UpdatedAt)
}
```

### In-Memory Implementation (Testing)

```go
// internal/adapter/driven/memory/todo_repo.go
type TodoRepository struct {
    mu    sync.RWMutex
    todos map[int64][]*entity.Todo
    seq   map[int64]int
}

// Implements output.TodoRepository
func (r *TodoRepository) Create(ctx context.Context, todo *entity.Todo) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    
    r.seq[todo.TelegramUserID]++
    todo.ID = fmt.Sprintf("todo-%d", r.seq[todo.TelegramUserID])
    todo.Code = fmt.Sprintf("26-%04d", r.seq[todo.TelegramUserID])
    todo.CreatedAt = time.Now()
    todo.UpdatedAt = time.Now()
    
    r.todos[todo.TelegramUserID] = append(r.todos[todo.TelegramUserID], todo)
    return nil
}
```

---

## Testing with Ports

### Using Mocks

```go
// test/unit/domain/todo_service_test.go
func TestTodoService_CreateTodo(t *testing.T) {
    // Create mock
    mockRepo := mocks.NewMockTodoRepository(t)
    
    // Set expectations
    mockRepo.EXPECT().
        Create(mock.Anything, mock.MatchedBy(func(todo *entity.Todo) bool {
            return todo.Title == "Test"
        })).
        Return(nil)
    
    // Create service with mock
    svc := service.NewTodoService(mockRepo, nil, nil, nil)
    
    // Test
    todo, err := svc.CreateTodo(context.Background(), 123, "Test", nil)
    
    assert.NoError(t, err)
    assert.Equal(t, "Test", todo.Title)
}
```

### Using In-Memory Adapters

```go
// test/bdd/todo_steps_test.go
func (tc *testContext) setup() {
    // Use in-memory implementations
    tc.todoRepo = memory.NewTodoRepository()
    tc.userRepo = memory.NewUserRepository()
    
    // Create service with in-memory adapters
    tc.todoService = service.NewTodoService(
        tc.todoRepo,
        tc.userRepo,
        nil,
        nil,
    )
}
```

---

## Port Evolution

### Adding New Methods

When adding methods to ports, consider:

1. **Backward Compatibility**: Can existing implementations support it?
2. **Optional Methods**: Consider separate interfaces if optional
3. **Default Behavior**: Can adapters provide sensible defaults?

### Example: Adding Batch Operations

```go
// Original
type TodoRepository interface {
    Create(ctx context.Context, todo *entity.Todo) error
}

// Extended
type TodoRepository interface {
    Create(ctx context.Context, todo *entity.Todo) error
    CreateBatch(ctx context.Context, todos []*entity.Todo) error  // New method
}

// Or separate interface
type BatchTodoRepository interface {
    TodoRepository
    CreateBatch(ctx context.Context, todos []*entity.Todo) error
}
```

---

## Benefits of Ports

### 1. Testability

Easy to mock or provide in-memory implementations:

```go
// Production
todoService := service.NewTodoService(
    postgres.NewTodoRepository(db),  // Real database
    // ...
)

// Testing
todoService := service.NewTodoService(
    memory.NewTodoRepository(),  // In-memory
    // ...
)
```

### 2. Swappable Implementations

Change infrastructure without touching domain:

```go
// Switch from PostgreSQL to MySQL
todoRepo := mysql.NewTodoRepository(conn)  // Different adapter, same interface
```

### 3. Clear Contracts

Interfaces document what domain needs:

```go
// Domain explicitly declares: "I need to persist todos"
type TodoRepository interface {
    Create(ctx context.Context, todo *entity.Todo) error
    // ...
}
```

### 4. Parallel Development

Teams can work independently:
- Domain team: Define ports
- Infrastructure team: Implement adapters
- Both use the agreed interface

---

## Common Mistakes

### ❌ Mistake 1: Leaking Infrastructure Details

```go
// BAD - SQL-specific error in port
type TodoRepository interface {
    Create(ctx context.Context, todo *entity.Todo) (*sql.Result, error)
}

// GOOD - Domain error
type TodoRepository interface {
    Create(ctx context.Context, todo *entity.Todo) error
}
```

### ❌ Mistake 2: Too Many Methods

```go
// BAD - too specific
type TodoRepository interface {
    CreateTodoWithHighPriority(...)
    CreateTodoWithTags(...)
    CreateTodoWithDueDate(...)
}

// GOOD - general method
type TodoRepository interface {
    Create(ctx context.Context, todo *entity.Todo) error
}
```

### ❌ Mistake 3: Domain Logic in Port

```go
// BAD - validation in interface
type TodoRepository interface {
    CreateIfValid(ctx context.Context, todo *entity.Todo) error
}

// GOOD - validation in entity/service
type TodoRepository interface {
    Create(ctx context.Context, todo *entity.Todo) error
}
```

---

## Summary

### Key Principles

1. **Interfaces Only** - Ports are pure interfaces, no implementation
2. **Domain-Centric** - Ports define what domain needs, not what infrastructure provides
3. **Context First** - Always pass context for cancellation
4. **Error Wrapping** - Wrap errors for context
5. **Return Pointers** - For entities and nullable values

### Port Design Checklist

- [ ] Takes `context.Context` as first parameter
- [ ] Returns domain errors, not infrastructure errors
- [ ] Methods are general, not implementation-specific
- [ ] Can be implemented by multiple adapters
- [ ] Documented with godoc comments
- [ ] Tested with mocks and in-memory implementations

## Next Steps

- See [Domain Services](07-domain-services.md) for port usage
- Review [Database Layer](11-database-layer.md) for port implementation
- Read [Testing Strategy](05-testing-strategy.md) for testing with ports
