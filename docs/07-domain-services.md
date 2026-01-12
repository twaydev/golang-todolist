# Domain Services

## Overview

Domain services (application services) orchestrate business use cases by coordinating entities and calling infrastructure through ports (interfaces). They contain application logic but delegate business rules to entities.

**Location**: `internal/domain/service/`

## Design Principles

### 1. Orchestration, Not Business Logic

Services orchestrate, entities contain rules:

```go
// ❌ BAD - business logic in service
func (s *TodoService) CreateTodo(...) (*Todo, error) {
    if title == "" {
        return nil, errors.New("title required")
    }
    // ...
}

// ✅ GOOD - business logic in entity
func (s *TodoService) CreateTodo(...) (*Todo, error) {
    todo := &entity.Todo{Title: title}
    if err := todo.Validate(); err != nil {  // Entity validates itself
        return nil, err
    }
    // ...
}
```

### 2. Dependency Injection via Ports

Services depend on interfaces, not concrete implementations:

```go
type TodoService struct {
    todoRepo       port.TodoRepository    // Interface, not *postgres.Repo
    userRepo       port.UserRepository
    intentAnalyzer port.IntentAnalyzer
}
```

### 3. Context Propagation

Always pass context for cancellation and timeouts:

```go
func (s *TodoService) CreateTodo(ctx context.Context, userID int64, title string) (*Todo, error) {
    // Pass context to repository
    return s.todoRepo.Create(ctx, todo)
}
```

### 4. Transaction Boundaries

Services define transaction boundaries when needed.

---

## Service: TodoService

### Responsibility

Orchestrate todo-related use cases: create, update, delete, list, complete, search.

### Definition

```go
// internal/domain/service/todo_service.go
package service

import (
    "context"
    "fmt"
    "time"
    
    "todobot/internal/domain/entity"
    "todobot/internal/domain/port/output"
    "todobot/internal/i18n"
)

type TodoService struct {
    todoRepo       output.TodoRepository
    userRepo       output.UserRepository
    intentAnalyzer output.IntentAnalyzer
    i18n           *i18n.Translator
}

func NewTodoService(
    todoRepo output.TodoRepository,
    userRepo output.UserRepository,
    intentAnalyzer output.IntentAnalyzer,
    translator *i18n.Translator,
) *TodoService {
    return &TodoService{
        todoRepo:       todoRepo,
        userRepo:       userRepo,
        intentAnalyzer: intentAnalyzer,
        i18n:           translator,
    }
}
```

### Use Cases

#### 1. HandleMessage (Natural Language Interface)

**Purpose**: Process natural language messages and route to appropriate action

```go
func (s *TodoService) HandleMessage(ctx context.Context, userID int64, message string) (string, error) {
    // Get user preferences for language
    prefs, err := s.userRepo.GetPreferences(ctx, userID)
    if err != nil {
        // Default to English if preferences not found
        prefs = &entity.UserPreferences{Language: entity.LangEnglish}
    }
    
    lang := prefs.GetLanguageOrDefault()
    
    // Get existing todos for context
    todos, err := s.todoRepo.List(ctx, userID, output.ListFilters{})
    if err != nil {
        return s.i18n.T("error_listing", lang), err
    }
    
    // Analyze intent using AI
    intent, err := s.intentAnalyzer.Analyze(ctx, message, todos, lang)
    if err != nil {
        return s.i18n.T("error_understanding", lang), err
    }
    
    // Check confidence
    if !intent.IsConfident() {
        return s.i18n.T("low_confidence", lang), nil
    }
    
    // Check for ambiguity
    if intent.IsAmbiguous() {
        return s.formatAmbiguityResponse(intent, lang), nil
    }
    
    // Route to appropriate handler
    switch intent.Action {
    case entity.ActionCreate:
        return s.handleCreate(ctx, userID, intent, lang)
    case entity.ActionList:
        return s.handleList(ctx, userID, intent, lang)
    case entity.ActionComplete:
        return s.handleComplete(ctx, userID, intent, lang)
    case entity.ActionUpdate:
        return s.handleUpdate(ctx, userID, intent, lang)
    case entity.ActionDelete:
        return s.handleDelete(ctx, userID, intent, lang)
    case entity.ActionSearch:
        return s.handleSearch(ctx, userID, intent, lang)
    case entity.ActionHelp:
        return s.i18n.T("help_message", lang), nil
    default:
        return s.i18n.T("unknown_action", lang), nil
    }
}
```

#### 2. CreateTodo

**Purpose**: Create a new todo with validation

```go
type CreateTodoOptions struct {
    Description *string
    DueDate     *time.Time
    Priority    entity.Priority
    Tags        []string
}

func (s *TodoService) CreateTodo(
    ctx context.Context,
    userID int64,
    title string,
    opts *CreateTodoOptions,
) (*entity.Todo, error) {
    // Create todo entity
    todo := &entity.Todo{
        TelegramUserID: userID,
        Title:          title,
        Status:         entity.StatusPending,
        Priority:       entity.PriorityMedium, // Default
        CreatedAt:      time.Now(),
        UpdatedAt:      time.Now(),
    }
    
    // Apply options
    if opts != nil {
        todo.Description = opts.Description
        todo.DueDate = opts.DueDate
        if opts.Priority.IsValid() {
            todo.Priority = opts.Priority
        }
        todo.Tags = opts.Tags
    }
    
    // Validate (business rules in entity)
    if err := todo.Validate(); err != nil {
        return nil, fmt.Errorf("validation failed: %w", err)
    }
    
    // Persist
    if err := s.todoRepo.Create(ctx, todo); err != nil {
        return nil, fmt.Errorf("failed to create todo: %w", err)
    }
    
    return todo, nil
}
```

#### 3. UpdateTodo

**Purpose**: Update existing todo

```go
type UpdateTodoOptions struct {
    Title       *string
    Description *string
    DueDate     *time.Time
    Priority    *entity.Priority
    Status      *entity.Status
    Tags        *[]string
}

func (s *TodoService) UpdateTodo(
    ctx context.Context,
    userID int64,
    todoID string,
    opts *UpdateTodoOptions,
) (*entity.Todo, error) {
    // Retrieve existing todo
    todo, err := s.todoRepo.GetByID(ctx, userID, todoID)
    if err != nil {
        return nil, fmt.Errorf("failed to get todo: %w", err)
    }
    
    // Apply updates
    if opts.Title != nil {
        todo.Title = *opts.Title
    }
    if opts.Description != nil {
        todo.Description = opts.Description
    }
    if opts.DueDate != nil {
        todo.SetDueDate(opts.DueDate)
    }
    if opts.Priority != nil {
        if err := todo.UpdatePriority(*opts.Priority); err != nil {
            return nil, err
        }
    }
    if opts.Status != nil {
        // Validate state transition
        if !todo.Status.CanTransitionTo(*opts.Status) {
            return nil, fmt.Errorf("invalid state transition: %s -> %s", todo.Status, *opts.Status)
        }
        todo.Status = *opts.Status
    }
    if opts.Tags != nil {
        todo.Tags = *opts.Tags
    }
    
    todo.UpdatedAt = time.Now()
    
    // Validate
    if err := todo.Validate(); err != nil {
        return nil, fmt.Errorf("validation failed: %w", err)
    }
    
    // Persist
    if err := s.todoRepo.Update(ctx, todo); err != nil {
        return nil, fmt.Errorf("failed to update todo: %w", err)
    }
    
    return todo, nil
}
```

#### 4. CompleteTodo

**Purpose**: Mark todo as completed

```go
func (s *TodoService) CompleteTodo(ctx context.Context, userID int64, todoID string) (*entity.Todo, error) {
    // Retrieve todo
    todo, err := s.todoRepo.GetByID(ctx, userID, todoID)
    if err != nil {
        return nil, fmt.Errorf("failed to get todo: %w", err)
    }
    
    // Mark complete (business rule in entity)
    if err := todo.MarkComplete(); err != nil {
        return nil, fmt.Errorf("cannot complete todo: %w", err)
    }
    
    // Persist
    if err := s.todoRepo.Update(ctx, todo); err != nil {
        return nil, fmt.Errorf("failed to update todo: %w", err)
    }
    
    return todo, nil
}
```

#### 5. DeleteTodo

**Purpose**: Delete a todo

```go
func (s *TodoService) DeleteTodo(ctx context.Context, userID int64, todoID string) error {
    // Check if exists
    _, err := s.todoRepo.GetByID(ctx, userID, todoID)
    if err != nil {
        return fmt.Errorf("todo not found: %w", err)
    }
    
    // Delete
    if err := s.todoRepo.Delete(ctx, userID, todoID); err != nil {
        return fmt.Errorf("failed to delete todo: %w", err)
    }
    
    return nil
}
```

#### 6. ListTodos

**Purpose**: List todos with filtering

```go
func (s *TodoService) ListTodos(
    ctx context.Context,
    userID int64,
    filters output.ListFilters,
) ([]*entity.Todo, error) {
    // Get todos from repository
    todos, err := s.todoRepo.List(ctx, userID, filters)
    if err != nil {
        return nil, fmt.Errorf("failed to list todos: %w", err)
    }
    
    return todos, nil
}
```

#### 7. SearchTodos

**Purpose**: Full-text search

```go
func (s *TodoService) SearchTodos(
    ctx context.Context,
    userID int64,
    query string,
) ([]*entity.Todo, error) {
    if query == "" {
        return nil, fmt.Errorf("search query cannot be empty")
    }
    
    todos, err := s.todoRepo.Search(ctx, userID, query)
    if err != nil {
        return nil, fmt.Errorf("search failed: %w", err)
    }
    
    return todos, nil
}
```

### Private Helper Methods

```go
func (s *TodoService) handleCreate(ctx context.Context, userID int64, intent *entity.ParsedIntent, lang entity.Language) (string, error) {
    if intent.Data.Title == nil {
        return s.i18n.T("title_required", lang), nil
    }
    
    opts := &CreateTodoOptions{
        Description: intent.Data.Description,
        DueDate:     intent.Data.DueDate,
        Tags:        intent.Data.Tags,
    }
    
    if intent.Data.Priority != nil {
        opts.Priority = *intent.Data.Priority
    }
    
    todo, err := s.CreateTodo(ctx, userID, *intent.Data.Title, opts)
    if err != nil {
        return s.i18n.T("error_creating", lang), err
    }
    
    return s.formatTodoCreated(todo, lang), nil
}

func (s *TodoService) formatTodoCreated(todo *entity.Todo, lang entity.Language) string {
    return fmt.Sprintf(
        s.i18n.T("todo_created", lang),
        todo.Code,
        todo.Title,
        todo.Priority,
    )
}

func (s *TodoService) formatAmbiguityResponse(intent *entity.ParsedIntent, lang entity.Language) string {
    response := s.i18n.T("ambiguous_request", lang) + "\n"
    for i, ambiguity := range intent.Ambiguities {
        response += fmt.Sprintf("%d. %s\n", i+1, ambiguity)
    }
    return response
}
```

---

## Service: UserService

### Responsibility

Manage user preferences: language, timezone.

### Definition

```go
// internal/domain/service/user_service.go
package service

import (
    "context"
    "fmt"
    
    "todobot/internal/domain/entity"
    "todobot/internal/domain/port/output"
    "todobot/internal/i18n"
)

type UserService struct {
    userRepo output.UserRepository
    i18n     *i18n.Translator
}

func NewUserService(
    userRepo output.UserRepository,
    translator *i18n.Translator,
) *UserService {
    return &UserService{
        userRepo: userRepo,
        i18n:     translator,
    }
}
```

### Use Cases

#### 1. GetPreferences

```go
func (s *UserService) GetPreferences(ctx context.Context, userID int64) (*entity.UserPreferences, error) {
    prefs, err := s.userRepo.GetPreferences(ctx, userID)
    if err != nil {
        // Return default preferences if not found
        return &entity.UserPreferences{
            TelegramUserID: userID,
            Language:       entity.LangEnglish,
            Timezone:       "UTC",
        }, nil
    }
    
    return prefs, nil
}
```

#### 2. SetLanguage

```go
func (s *UserService) SetLanguage(ctx context.Context, userID int64, lang entity.Language) error {
    // Validate language
    switch lang {
    case entity.LangEnglish, entity.LangVietnamese:
        // Valid
    default:
        return fmt.Errorf("unsupported language: %s", lang)
    }
    
    // Get existing preferences
    prefs, err := s.GetPreferences(ctx, userID)
    if err != nil {
        return err
    }
    
    // Update language
    if err := prefs.SetLanguage(lang); err != nil {
        return err
    }
    
    // Persist
    if err := s.userRepo.SetLanguage(ctx, userID, lang); err != nil {
        return fmt.Errorf("failed to set language: %w", err)
    }
    
    return nil
}
```

#### 3. SetTimezone

```go
func (s *UserService) SetTimezone(ctx context.Context, userID int64, tz string) error {
    // Validate timezone
    if _, err := time.LoadLocation(tz); err != nil {
        return fmt.Errorf("invalid timezone: %w", err)
    }
    
    // Persist
    if err := s.userRepo.SetTimezone(ctx, userID, tz); err != nil {
        return fmt.Errorf("failed to set timezone: %w", err)
    }
    
    return nil
}
```

---

## Service: TemplateService

### Responsibility

Manage task templates: CRUD operations and instantiation.

### Definition

```go
// internal/domain/service/template_service.go
package service

import (
    "context"
    "fmt"
    
    "todobot/internal/domain/entity"
    "todobot/internal/domain/port/output"
)

type TemplateService struct {
    templateRepo output.TemplateRepository
    todoRepo     output.TodoRepository
}

func NewTemplateService(
    templateRepo output.TemplateRepository,
    todoRepo output.TodoRepository,
) *TemplateService {
    return &TemplateService{
        templateRepo: templateRepo,
        todoRepo:     todoRepo,
    }
}
```

### Use Cases

#### 1. CreateFromTemplate

```go
func (s *TemplateService) CreateFromTemplate(
    ctx context.Context,
    userID int64,
    templateName string,
    variables map[string]string,
) (*entity.Todo, error) {
    // Get template
    template, err := s.templateRepo.GetByName(ctx, userID, templateName)
    if err != nil {
        return nil, fmt.Errorf("template not found: %w", err)
    }
    
    // Validate template
    if err := template.Validate(); err != nil {
        return nil, fmt.Errorf("invalid template: %w", err)
    }
    
    // Create todo from template
    todo := template.CreateTodo(userID, variables)
    
    // Validate todo
    if err := todo.Validate(); err != nil {
        return nil, fmt.Errorf("invalid todo from template: %w", err)
    }
    
    // Persist
    if err := s.todoRepo.Create(ctx, todo); err != nil {
        return nil, fmt.Errorf("failed to create todo: %w", err)
    }
    
    return todo, nil
}
```

#### 2. ListTemplates

```go
func (s *TemplateService) ListTemplates(
    ctx context.Context,
    userID int64,
) ([]*entity.TaskTemplate, error) {
    templates, err := s.templateRepo.List(ctx, userID)
    if err != nil {
        return nil, fmt.Errorf("failed to list templates: %w", err)
    }
    
    return templates, nil
}
```

---

## Service Testing

### Unit Test Example

```go
// internal/domain/service/todo_service_test.go
package service_test

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
            return todo.Title == "Test Todo" && todo.Status == entity.StatusPending
        })).
        Return(nil)
    
    // Act
    todo, err := svc.CreateTodo(context.Background(), 123, "Test Todo", nil)
    
    // Assert
    assert.NoError(t, err)
    assert.NotNil(t, todo)
    assert.Equal(t, "Test Todo", todo.Title)
    assert.Equal(t, entity.StatusPending, todo.Status)
}

func TestTodoService_CreateTodo_ValidationError(t *testing.T) {
    // Arrange
    svc := service.NewTodoService(nil, nil, nil, nil)
    
    // Act
    todo, err := svc.CreateTodo(context.Background(), 123, "", nil)
    
    // Assert
    assert.Error(t, err)
    assert.Nil(t, todo)
    assert.Contains(t, err.Error(), "validation failed")
}
```

### BDD Test Example

```go
// test/bdd/todo_steps_test.go
func (tc *testContext) theUserCreatesATodoWithTitle(title string) error {
    todo, err := tc.todoService.CreateTodo(
        context.Background(),
        tc.userID,
        title,
        nil,
    )
    tc.lastTodo = todo
    tc.lastError = err
    return nil
}
```

## Best Practices

### 1. Keep Services Thin

Services orchestrate, don't implement business rules:

```go
// ✅ GOOD
func (s *TodoService) CompleteTodo(...) error {
    todo, _ := s.todoRepo.GetByID(...)
    todo.MarkComplete()  // Entity method
    return s.todoRepo.Update(...)
}

// ❌ BAD
func (s *TodoService) CompleteTodo(...) error {
    todo, _ := s.todoRepo.GetByID(...)
    todo.Status = StatusCompleted  // Business logic in service
    todo.UpdatedAt = time.Now()
    return s.todoRepo.Update(...)
}
```

### 2. Return Domain Errors

Return errors that callers can handle:

```go
var (
    ErrTodoNotFound = errors.New("todo not found")
    ErrUnauthorized = errors.New("unauthorized")
)

func (s *TodoService) GetTodo(...) (*Todo, error) {
    todo, err := s.todoRepo.GetByID(...)
    if err == sql.ErrNoRows {
        return nil, ErrTodoNotFound  // Domain error
    }
    return todo, err
}
```

### 3. Use Options Pattern

For methods with many optional parameters:

```go
type CreateTodoOptions struct {
    Description *string
    DueDate     *time.Time
    Priority    entity.Priority
    Tags        []string
}

func (s *TodoService) CreateTodo(
    ctx context.Context,
    userID int64,
    title string,
    opts *CreateTodoOptions,  // Optional
) (*entity.Todo, error) {
    // ...
}
```

### 4. Context First

Always pass context as first parameter:

```go
func (s *TodoService) CreateTodo(ctx context.Context, ...) {...}
```

## Next Steps

- Read [Port Interfaces](08-port-interfaces.md) for interface definitions
- See [Domain Entities](06-domain-entities.md) for entity details
- Review [Testing Strategy](05-testing-strategy.md) for testing services
