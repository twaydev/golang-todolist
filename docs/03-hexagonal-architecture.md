# Hexagonal Architecture (Ports & Adapters)

## Overview

This project implements **Hexagonal Architecture** (also known as Ports & Adapters) to achieve clean separation between business logic and infrastructure concerns.

## What is Hexagonal Architecture?

Hexagonal Architecture is a design pattern that:
- Places business logic at the center (domain)
- Isolates domain from external concerns (databases, APIs, UI)
- Uses **ports** (interfaces) to define contracts
- Uses **adapters** to implement those contracts

### Key Principle

> "Business logic should not depend on frameworks, databases, or external systems"

## Architecture Diagram

```
                              ┌─────────────────────────────────────┐
                              │           DRIVING ADAPTERS          │
                              │         (Primary/Input)             │
                              │  ┌───────────┐  ┌───────────────┐  │
                              │  │ Telegram  │  │  Echo REST    │  │
                              │  │  Adapter  │  │     API       │  │
                              │  └─────┬─────┘  └───────┬───────┘  │
                              └───────┼────────────────┼──────────┘
                                      │                │
                                      ▼                ▼
                              ┌─────────────────────────────────────┐
                              │            INPUT PORTS              │
                              │  ┌───────────────────────────────┐  │
                              │  │     MessageHandler (port)     │  │
                              │  │     CommandHandler (port)     │  │
                              │  │     HTTPHandler (port)        │  │
                              │  └───────────────────────────────┘  │
                              └─────────────────┬───────────────────┘
                                                │
                                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│                          DOMAIN / CORE                                  │
│                                                                         │
│   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐        │
│   │   Todo Entity   │  │  User Entity    │  │ Intent Entity   │        │
│   └─────────────────┘  └─────────────────┘  └─────────────────┘        │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────┐      │
│   │                    APPLICATION SERVICES                      │      │
│   │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │      │
│   │  │ TodoService  │  │ UserService  │  │IntentService │       │      │
│   │  └──────────────┘  └──────────────┘  └──────────────┘       │      │
│   └─────────────────────────────────────────────────────────────┘      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
                              ┌─────────────────────────────────────┐
                              │           OUTPUT PORTS              │
                              │  ┌───────────────────────────────┐  │
                              │  │   TodoRepository (port)       │  │
                              │  │   UserRepository (port)       │  │
                              │  │   IntentAnalyzer (port)       │  │
                              │  │   Notifier (port)             │  │
                              │  └───────────────────────────────┘  │
                              └─────────────────┬───────────────────┘
                                                │
                                                ▼
                              ┌─────────────────────────────────────┐
                              │          DRIVEN ADAPTERS            │
                              │        (Secondary/Output)           │
                              │  ┌───────────┐  ┌───────────────┐  │
                              │  │ PostgreSQL│  │  Perplexity   │  │
                              │  │  Adapter  │  │   Adapter     │  │
                              │  └─────┬─────┘  └───────┬───────┘  │
                              └───────┼────────────────┼──────────┘
                                      │                │
                                      ▼                ▼
                              ┌───────────────┐  ┌───────────────┐
                              │   Supabase    │  │  Perplexity   │
                              │  PostgreSQL   │  │     API       │
                              └───────────────┘  └───────────────┘
```

## The Five Layers

### 1. Domain / Core (Center)

**Location**: `internal/domain/`

**Purpose**: Contains business logic, entities, and rules

**Characteristics**:
- ✅ No external dependencies (only Go stdlib)
- ✅ Framework-agnostic
- ✅ Testable in isolation
- ✅ Pure business logic

**Components**:
- **Entities**: `entity/` - Domain objects with business rules
- **Services**: `service/` - Application services that orchestrate use cases
- **Ports**: `port/` - Interfaces for external communication

**Example**:
```go
// internal/domain/entity/todo.go
type Todo struct {
    ID      string
    Title   string
    Status  Status
}

func (t *Todo) Validate() error {
    if t.Title == "" {
        return ErrTitleRequired
    }
    return nil
}
```

### 2. Input Ports (Driving Side)

**Location**: `internal/domain/port/input/`

**Purpose**: Define how external world can interact with domain

**Characteristics**:
- Interfaces only (no implementation)
- Define use cases
- Called by driving adapters

**Example**:
```go
// internal/domain/port/input/message_handler.go
type MessageHandler interface {
    HandleMessage(ctx context.Context, userID int64, message string) (string, error)
}
```

### 3. Output Ports (Driven Side)

**Location**: `internal/domain/port/output/`

**Purpose**: Define how domain interacts with external systems

**Characteristics**:
- Interfaces only (no implementation)
- Define contracts for infrastructure
- Implemented by driven adapters

**Example**:
```go
// internal/domain/port/output/todo_repository.go
type TodoRepository interface {
    Create(ctx context.Context, todo *entity.Todo) error
    GetByID(ctx context.Context, userID int64, todoID string) (*entity.Todo, error)
    List(ctx context.Context, userID int64, filters ListFilters) ([]*entity.Todo, error)
}
```

### 4. Driving Adapters (Primary)

**Location**: `internal/adapter/driving/`

**Purpose**: Translate external requests into domain calls

**Types**:
- HTTP REST API (Echo framework)
- Telegram Bot (telebot)
- CLI (future)

**Characteristics**:
- Implement input ports
- Handle external protocols (HTTP, Telegram)
- Map external data to domain format
- No business logic

**Example**:
```go
// internal/adapter/driving/http/handlers.go
func (h *TodoHandler) CreateTodo(c echo.Context) error {
    var req CreateTodoRequest
    if err := c.Bind(&req); err != nil {
        return c.JSON(400, ErrorResponse{Message: "Invalid request"})
    }
    
    // Call domain service
    todo, err := h.todoService.CreateTodo(c.Request().Context(), 
        getUserID(c), req.Title, req.toOptions())
    if err != nil {
        return c.JSON(500, ErrorResponse{Message: err.Error()})
    }
    
    return c.JSON(201, toTodoResponse(todo))
}
```

### 5. Driven Adapters (Secondary)

**Location**: `internal/adapter/driven/`

**Purpose**: Implement output ports to interact with external systems

**Types**:
- PostgreSQL database adapter
- Perplexity AI adapter
- File system adapter (templates)
- In-memory adapter (testing)

**Characteristics**:
- Implement output ports
- Handle external systems (database, APIs)
- No business logic
- Swappable implementations

**Example**:
```go
// internal/adapter/driven/postgres/todo_repo.go
type PostgresTodoRepository struct {
    pool *pgxpool.Pool
}

// Implements TodoRepository interface
func (r *PostgresTodoRepository) Create(ctx context.Context, todo *entity.Todo) error {
    query := `INSERT INTO todos (title, status, telegram_user_id) 
              VALUES ($1, $2, $3) RETURNING id, created_at`
    return r.pool.QueryRow(ctx, query, todo.Title, todo.Status, todo.TelegramUserID).
        Scan(&todo.ID, &todo.CreatedAt)
}
```

## Layer Responsibilities

| Layer | Responsibility | Can Import | Cannot Import |
|-------|----------------|------------|---------------|
| **Domain** | Business logic, entities, rules | stdlib only | adapter/, any framework |
| **Input Ports** | Define use case interfaces | domain/entity | adapter/, frameworks |
| **Output Ports** | Define infrastructure interfaces | domain/entity | adapter/, frameworks |
| **Driving Adapters** | Translate external → domain | domain/, frameworks | other adapters |
| **Driven Adapters** | Translate domain → external | domain/, frameworks | other adapters |

## Dependency Rules

### The Dependency Rule

> "Dependencies point inward, toward the domain"

```
External Systems → Driven Adapters → Output Ports → DOMAIN ← Input Ports ← Driving Adapters ← External World
```

### What This Means

1. **Domain NEVER imports adapters**
   ```go
   // ❌ BAD - domain importing adapter
   import "todobot/internal/adapter/driven/postgres"
   
   // ✅ GOOD - domain only uses interface
   import "todobot/internal/domain/port/output"
   ```

2. **Adapters import domain**
   ```go
   // ✅ GOOD - adapter imports domain
   import "todobot/internal/domain/entity"
   import "todobot/internal/domain/port/output"
   ```

3. **Domain uses only interfaces for external systems**
   ```go
   // Domain service
   type TodoService struct {
       todoRepo port.TodoRepository  // Interface, not concrete type
   }
   ```

## Benefits of Hexagonal Architecture

### 1. Testability

Test domain logic without any infrastructure:

```go
func TestTodoService_CreateTodo(t *testing.T) {
    // Use in-memory mock, no database needed
    mockRepo := &memory.TodoRepository{}
    service := service.NewTodoService(mockRepo, nil, nil)
    
    todo, err := service.CreateTodo(ctx, 123, "Test Todo", nil)
    
    assert.NoError(t, err)
    assert.Equal(t, "Test Todo", todo.Title)
}
```

### 2. Swappable Infrastructure

Change databases without touching business logic:

```go
// Use PostgreSQL in production
todoRepo := postgres.NewTodoRepository(pgPool)

// Use in-memory in tests
todoRepo := memory.NewTodoRepository()

// Use MySQL in future
todoRepo := mysql.NewTodoRepository(mysqlConn)

// Same service, different storage
service := service.NewTodoService(todoRepo, ...)
```

### 3. Independent Development

Teams can work in parallel:
- Domain team: Implement business logic
- API team: Build REST endpoints
- Bot team: Build Telegram interface
- DB team: Optimize database

### 4. Framework Independence

Not locked into any framework:
- Switch from Echo to Gin
- Switch from telebot to another bot library
- Domain code remains unchanged

### 5. Delayed Decisions

Can defer infrastructure choices:
- Start with in-memory storage
- Add PostgreSQL later
- Switch to another database if needed

## Common Mistakes to Avoid

### ❌ Mistake 1: Business Logic in Adapters

```go
// ❌ BAD - validation in HTTP handler
func (h *TodoHandler) CreateTodo(c echo.Context) error {
    var req CreateTodoRequest
    c.Bind(&req)
    
    // Business logic in adapter!
    if req.Title == "" {
        return c.JSON(400, "Title required")
    }
    if len(req.Title) > 500 {
        return c.JSON(400, "Title too long")
    }
    
    // ...
}

// ✅ GOOD - validation in domain
func (t *Todo) Validate() error {
    if t.Title == "" {
        return ErrTitleRequired
    }
    if len(t.Title) > 500 {
        return ErrTitleTooLong
    }
    return nil
}
```

### ❌ Mistake 2: Domain Importing Adapters

```go
// ❌ BAD
package service

import "todobot/internal/adapter/driven/postgres"

type TodoService struct {
    repo *postgres.TodoRepository  // Concrete type!
}

// ✅ GOOD
package service

import "todobot/internal/domain/port/output"

type TodoService struct {
    repo port.TodoRepository  // Interface!
}
```

### ❌ Mistake 3: Direct Database Access in Domain

```go
// ❌ BAD
func (s *TodoService) CreateTodo(...) (*Todo, error) {
    // Direct SQL in domain!
    row := s.db.QueryRow("INSERT INTO todos ...")
}

// ✅ GOOD
func (s *TodoService) CreateTodo(...) (*Todo, error) {
    todo := &Todo{...}
    if err := s.todoRepo.Create(ctx, todo); err != nil {
        return nil, err
    }
    return todo, nil
}
```

### ❌ Mistake 4: Adapters Talking to Each Other

```go
// ❌ BAD - HTTP adapter directly calling Postgres adapter
func (h *TodoHandler) CreateTodo(c echo.Context) error {
    repo := postgres.NewTodoRepository(...)
    repo.Create(...)  // Bypassing domain!
}

// ✅ GOOD - HTTP adapter calls domain service
func (h *TodoHandler) CreateTodo(c echo.Context) error {
    todo, err := h.todoService.CreateTodo(...)  // Through domain
}
```

## Practical Example: Create Todo Flow

### 1. Request Arrives (Driving Adapter)

```go
// internal/adapter/driving/http/handlers.go
func (h *TodoHandler) CreateTodo(c echo.Context) error {
    var req CreateTodoRequest
    c.Bind(&req)  // HTTP-specific
    
    // Convert HTTP request to domain call
    todo, err := h.todoService.CreateTodo(
        c.Request().Context(),
        getUserID(c),
        req.Title,
        req.toOptions(),
    )
    
    if err != nil {
        return mapError(err)  // HTTP-specific error handling
    }
    
    return c.JSON(201, toTodoResponse(todo))  // HTTP response
}
```

### 2. Domain Processes (Core)

```go
// internal/domain/service/todo_service.go
func (s *TodoService) CreateTodo(ctx context.Context, userID int64, title string, opts *CreateOptions) (*entity.Todo, error) {
    // Pure business logic
    todo := &entity.Todo{
        TelegramUserID: userID,
        Title:          title,
        Status:         entity.StatusPending,
        Priority:       entity.PriorityMedium,
    }
    
    // Business rule: validate
    if err := todo.Validate(); err != nil {
        return nil, err
    }
    
    // Call repository through interface
    if err := s.todoRepo.Create(ctx, todo); err != nil {
        return nil, err
    }
    
    return todo, nil
}
```

### 3. Storage Happens (Driven Adapter)

```go
// internal/adapter/driven/postgres/todo_repo.go
func (r *PostgresTodoRepository) Create(ctx context.Context, todo *entity.Todo) error {
    // Database-specific implementation
    query := `INSERT INTO todos (telegram_user_id, title, status, priority) 
              VALUES ($1, $2, $3, $4) 
              RETURNING id, code, created_at, updated_at`
    
    return r.pool.QueryRow(ctx, query,
        todo.TelegramUserID, todo.Title, todo.Status, todo.Priority,
    ).Scan(&todo.ID, &todo.Code, &todo.CreatedAt, &todo.UpdatedAt)
}
```

## Testing with Hexagonal Architecture

### Unit Tests (Domain Only)

```go
func TestTodoService_CreateTodo(t *testing.T) {
    // Arrange - use mock repository
    mockRepo := mocks.NewMockTodoRepository(t)
    service := service.NewTodoService(mockRepo, nil, nil, nil)
    
    mockRepo.EXPECT().
        Create(mock.Anything, mock.Anything).
        Return(nil)
    
    // Act
    todo, err := service.CreateTodo(ctx, 123, "Test", nil)
    
    // Assert
    assert.NoError(t, err)
    assert.Equal(t, "Test", todo.Title)
}
```

### Integration Tests (Adapter + Domain)

```go
func TestPostgresRepository_Create(t *testing.T) {
    // Use real database (test container)
    db := setupTestDatabase(t)
    defer db.Close()
    
    repo := postgres.NewTodoRepository(db)
    
    todo := &entity.Todo{
        TelegramUserID: 123,
        Title:          "Integration test",
    }
    
    err := repo.Create(context.Background(), todo)
    
    assert.NoError(t, err)
    assert.NotEmpty(t, todo.ID)
}
```

## Dependency Injection

All dependencies are injected at application startup:

```go
// cmd/bot/main.go
func main() {
    // Load configuration
    cfg := config.Load()
    
    // Create driven adapters (infrastructure)
    db := postgres.NewConnection(cfg.DatabaseURL)
    todoRepo := postgres.NewTodoRepository(db)
    userRepo := postgres.NewUserRepository(db)
    intentAnalyzer := perplexity.NewClient(cfg.PerplexityAPIKey)
    
    // Create domain services (inject dependencies)
    todoService := service.NewTodoService(todoRepo, userRepo, intentAnalyzer, translator)
    userService := service.NewUserService(userRepo, translator)
    
    // Create driving adapters (UI/API)
    httpServer := http.NewServer(todoService, userService, cfg)
    telegramBot := telegram.NewBot(cfg.TelegramToken, todoService, userService)
    
    // Start application
    go httpServer.Start(":8080")
    telegramBot.Start()
}
```

## Summary

### Key Principles

1. **Domain at Center** - Business logic isolated from infrastructure
2. **Ports as Contracts** - Interfaces define boundaries
3. **Adapters Implement Ports** - Concrete implementations are pluggable
4. **Dependencies Point Inward** - Domain never depends on infrastructure
5. **Testable in Isolation** - Domain can be tested without external systems

### Benefits Recap

✅ **Testability** - Easy to test business logic
✅ **Flexibility** - Easy to change infrastructure
✅ **Maintainability** - Clear separation of concerns
✅ **Scalability** - Easy to add new interfaces
✅ **Independence** - Not locked to frameworks

## Next Steps

- Read [Domain Entities](06-domain-entities.md) for entity details
- See [Port Interfaces](08-port-interfaces.md) for interface definitions
- Review [Echo REST API](09-echo-rest-api.md) for driving adapter example
- Check [Database Layer](11-database-layer.md) for driven adapter example
