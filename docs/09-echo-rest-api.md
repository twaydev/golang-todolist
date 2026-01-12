# Echo REST API

## Overview

The Echo REST API adapter provides HTTP/REST interface to the domain layer. It's a **driving adapter** that translates HTTP requests into domain service calls.

**Location**: `internal/adapter/driving/http/`

**Framework**: Echo v4 (https://echo.labstack.com/)

## Architecture

```
HTTP Request → Echo Router → Middleware → Handler → DTO → Domain Service → Response
```

### Responsibilities

- ✅ Handle HTTP requests/responses
- ✅ Validate request data
- ✅ Map DTOs to domain entities
- ✅ Call domain services
- ✅ Format responses
- ✅ Handle errors with proper status codes
- ❌ NO business logic

## File Structure

```
internal/adapter/driving/http/
├── server.go           # Echo server setup
├── routes.go           # Route definitions
├── handlers.go         # HTTP handlers (todo operations)
├── handlers_template.go # Template handlers
├── handlers_user.go    # User preference handlers
├── middleware.go       # Authentication, logging, CORS
├── dto.go              # Request/Response DTOs
├── error.go            # Error handling
└── helpers.go          # Helper functions
```

## Server Setup

### Server Structure

```go
// internal/adapter/driving/http/server.go
package http

import (
    "context"
    
    "github.com/labstack/echo/v4"
    "github.com/labstack/echo/v4/middleware"
    
    "todobot/internal/config"
    "todobot/internal/domain/service"
)

type Server struct {
    echo        *echo.Echo
    todoService *service.TodoService
    userService *service.UserService
    config      *config.Config
}

func NewServer(
    todoSvc *service.TodoService,
    userSvc *service.UserService,
    cfg *config.Config,
) *Server {
    e := echo.New()
    
    // Configure Echo
    e.HideBanner = true
    e.HidePort = false
    
    // Middleware
    e.Use(middleware.Logger())
    e.Use(middleware.Recover())
    e.Use(middleware.CORS())
    e.Use(middleware.RequestID())
    e.Use(middleware.Secure())
    
    s := &Server{
        echo:        e,
        todoService: todoSvc,
        userService: userSvc,
        config:      cfg,
    }
    
    s.registerRoutes()
    return s
}

func (s *Server) Start(addr string) error {
    return s.echo.Start(addr)
}

func (s *Server) Shutdown(ctx context.Context) error {
    return s.echo.Shutdown(ctx)
}
```

## Routes

### Route Registration

```go
// internal/adapter/driving/http/routes.go
func (s *Server) registerRoutes() {
    // Health check (no auth required)
    s.echo.GET("/health", s.handleHealth)
    s.echo.GET("/ready", s.handleReady)
    
    // API v1
    v1 := s.echo.Group("/api/v1")
    v1.Use(s.authMiddleware)  // All v1 routes require auth
    
    // Todo endpoints
    todos := v1.Group("/todos")
    todos.POST("", s.createTodo)              // Create todo
    todos.GET("", s.listTodos)                // List todos with filters
    todos.GET("/:id", s.getTodo)              // Get todo by ID
    todos.PUT("/:id", s.updateTodo)           // Update todo
    todos.DELETE("/:id", s.deleteTodo)        // Delete todo
    todos.POST("/:id/complete", s.completeTodo) // Mark complete
    todos.POST("/:id/reopen", s.reopenTodo)   // Reopen completed todo
    todos.GET("/search", s.searchTodos)       // Full-text search
    
    // Template endpoints
    templates := v1.Group("/templates")
    templates.GET("", s.listTemplates)
    templates.POST("", s.createTemplate)
    templates.GET("/:name", s.getTemplate)
    templates.PUT("/:name", s.updateTemplate)
    templates.DELETE("/:name", s.deleteTemplate)
    templates.POST("/:name/instantiate", s.instantiateTemplate)
    
    // User preferences
    prefs := v1.Group("/preferences")
    prefs.GET("", s.getPreferences)
    prefs.PUT("/language", s.setLanguage)
    prefs.PUT("/timezone", s.setTimezone)
}
```

### API Endpoints Summary

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | `/health` | Health check | No |
| GET | `/ready` | Readiness check | No |
| **Todos** |
| POST | `/api/v1/todos` | Create todo | Yes |
| GET | `/api/v1/todos` | List todos | Yes |
| GET | `/api/v1/todos/:id` | Get todo | Yes |
| PUT | `/api/v1/todos/:id` | Update todo | Yes |
| DELETE | `/api/v1/todos/:id` | Delete todo | Yes |
| POST | `/api/v1/todos/:id/complete` | Complete todo | Yes |
| POST | `/api/v1/todos/:id/reopen` | Reopen todo | Yes |
| GET | `/api/v1/todos/search?q=query` | Search todos | Yes |
| **Templates** |
| GET | `/api/v1/templates` | List templates | Yes |
| POST | `/api/v1/templates` | Create template | Yes |
| GET | `/api/v1/templates/:name` | Get template | Yes |
| PUT | `/api/v1/templates/:name` | Update template | Yes |
| DELETE | `/api/v1/templates/:name` | Delete template | Yes |
| POST | `/api/v1/templates/:name/instantiate` | Create from template | Yes |
| **Preferences** |
| GET | `/api/v1/preferences` | Get preferences | Yes |
| PUT | `/api/v1/preferences/language` | Set language | Yes |
| PUT | `/api/v1/preferences/timezone` | Set timezone | Yes |

## Handlers

### Todo Handlers

```go
// internal/adapter/driving/http/handlers.go

// Create Todo
func (s *Server) createTodo(c echo.Context) error {
    var req CreateTodoRequest
    if err := c.Bind(&req); err != nil {
        return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
    }
    
    if err := req.Validate(); err != nil {
        return echo.NewHTTPError(http.StatusBadRequest, err.Error())
    }
    
    userID := getUserIDFromContext(c)
    
    todo, err := s.todoService.CreateTodo(
        c.Request().Context(),
        userID,
        req.Title,
        req.toOptions(),
    )
    if err != nil {
        return handleDomainError(err)
    }
    
    return c.JSON(http.StatusCreated, toTodoResponse(todo))
}

// List Todos
func (s *Server) listTodos(c echo.Context) error {
    userID := getUserIDFromContext(c)
    filters := parseListFilters(c)
    
    todos, err := s.todoService.ListTodos(c.Request().Context(), userID, filters)
    if err != nil {
        return handleDomainError(err)
    }
    
    return c.JSON(http.StatusOK, ListTodosResponse{
        Todos: toTodoResponses(todos),
        Total: len(todos),
    })
}

// Get Todo
func (s *Server) getTodo(c echo.Context) error {
    userID := getUserIDFromContext(c)
    todoID := c.Param("id")
    
    todo, err := s.todoService.GetTodo(c.Request().Context(), userID, todoID)
    if err != nil {
        return handleDomainError(err)
    }
    
    return c.JSON(http.StatusOK, toTodoResponse(todo))
}

// Update Todo
func (s *Server) updateTodo(c echo.Context) error {
    var req UpdateTodoRequest
    if err := c.Bind(&req); err != nil {
        return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
    }
    
    if err := req.Validate(); err != nil {
        return echo.NewHTTPError(http.StatusBadRequest, err.Error())
    }
    
    userID := getUserIDFromContext(c)
    todoID := c.Param("id")
    
    todo, err := s.todoService.UpdateTodo(
        c.Request().Context(),
        userID,
        todoID,
        req.toOptions(),
    )
    if err != nil {
        return handleDomainError(err)
    }
    
    return c.JSON(http.StatusOK, toTodoResponse(todo))
}

// Complete Todo
func (s *Server) completeTodo(c echo.Context) error {
    userID := getUserIDFromContext(c)
    todoID := c.Param("id")
    
    todo, err := s.todoService.CompleteTodo(c.Request().Context(), userID, todoID)
    if err != nil {
        return handleDomainError(err)
    }
    
    return c.JSON(http.StatusOK, toTodoResponse(todo))
}

// Delete Todo
func (s *Server) deleteTodo(c echo.Context) error {
    userID := getUserIDFromContext(c)
    todoID := c.Param("id")
    
    if err := s.todoService.DeleteTodo(c.Request().Context(), userID, todoID); err != nil {
        return handleDomainError(err)
    }
    
    return c.NoContent(http.StatusNoContent)
}

// Search Todos
func (s *Server) searchTodos(c echo.Context) error {
    userID := getUserIDFromContext(c)
    query := c.QueryParam("q")
    
    if query == "" {
        return echo.NewHTTPError(http.StatusBadRequest, "Query parameter 'q' is required")
    }
    
    todos, err := s.todoService.SearchTodos(c.Request().Context(), userID, query)
    if err != nil {
        return handleDomainError(err)
    }
    
    return c.JSON(http.StatusOK, SearchTodosResponse{
        Todos: toTodoResponses(todos),
        Query: query,
        Total: len(todos),
    })
}
```

### Health Check Handlers

```go
func (s *Server) handleHealth(c echo.Context) error {
    return c.JSON(http.StatusOK, map[string]string{
        "status": "healthy",
    })
}

func (s *Server) handleReady(c echo.Context) error {
    // Check dependencies (database, etc.)
    // For now, simple response
    return c.JSON(http.StatusOK, map[string]string{
        "status": "ready",
    })
}
```

## DTOs (Data Transfer Objects)

### Request DTOs

```go
// internal/adapter/driving/http/dto.go

type CreateTodoRequest struct {
    Title       string   `json:"title" validate:"required,min=1,max=500"`
    Description *string  `json:"description,omitempty"`
    Priority    *string  `json:"priority,omitempty" validate:"omitempty,oneof=low medium high"`
    DueDate     *string  `json:"due_date,omitempty"` // ISO 8601 format
    Tags        []string `json:"tags,omitempty"`
}

func (r *CreateTodoRequest) Validate() error {
    if r.Title == "" {
        return errors.New("title is required")
    }
    if len(r.Title) > 500 {
        return errors.New("title too long (max 500 characters)")
    }
    if r.Priority != nil {
        p := entity.Priority(*r.Priority)
        if !p.IsValid() {
            return errors.New("invalid priority")
        }
    }
    return nil
}

func (r *CreateTodoRequest) toOptions() *service.CreateTodoOptions {
    opts := &service.CreateTodoOptions{
        Description: r.Description,
        Tags:        r.Tags,
    }
    
    if r.Priority != nil {
        p := entity.Priority(*r.Priority)
        opts.Priority = p
    }
    
    if r.DueDate != nil {
        if t, err := time.Parse(time.RFC3339, *r.DueDate); err == nil {
            opts.DueDate = &t
        }
    }
    
    return opts
}

type UpdateTodoRequest struct {
    Title       *string  `json:"title,omitempty"`
    Description *string  `json:"description,omitempty"`
    Priority    *string  `json:"priority,omitempty"`
    Status      *string  `json:"status,omitempty"`
    DueDate     *string  `json:"due_date,omitempty"`
    Tags        *[]string `json:"tags,omitempty"`
}

func (r *UpdateTodoRequest) Validate() error {
    if r.Title != nil && *r.Title == "" {
        return errors.New("title cannot be empty")
    }
    if r.Priority != nil {
        p := entity.Priority(*r.Priority)
        if !p.IsValid() {
            return errors.New("invalid priority")
        }
    }
    if r.Status != nil {
        // Validate status
        validStatuses := []string{"pending", "in_progress", "completed"}
        valid := false
        for _, s := range validStatuses {
            if *r.Status == s {
                valid = true
                break
            }
        }
        if !valid {
            return errors.New("invalid status")
        }
    }
    return nil
}
```

### Response DTOs

```go
type TodoResponse struct {
    ID          string   `json:"id"`
    Code        string   `json:"code"`
    Title       string   `json:"title"`
    Description *string  `json:"description,omitempty"`
    Priority    string   `json:"priority"`
    Status      string   `json:"status"`
    DueDate     *string  `json:"due_date,omitempty"` // ISO 8601
    Tags        []string `json:"tags"`
    CreatedAt   string   `json:"created_at"`
    UpdatedAt   string   `json:"updated_at"`
}

func toTodoResponse(todo *entity.Todo) TodoResponse {
    resp := TodoResponse{
        ID:        todo.ID,
        Code:      todo.Code,
        Title:     todo.Title,
        Priority:  string(todo.Priority),
        Status:    string(todo.Status),
        Tags:      todo.Tags,
        CreatedAt: todo.CreatedAt.Format(time.RFC3339),
        UpdatedAt: todo.UpdatedAt.Format(time.RFC3339),
    }
    
    if todo.Description != nil {
        resp.Description = todo.Description
    }
    
    if todo.DueDate != nil {
        dueDateStr := todo.DueDate.Format(time.RFC3339)
        resp.DueDate = &dueDateStr
    }
    
    return resp
}

func toTodoResponses(todos []*entity.Todo) []TodoResponse {
    responses := make([]TodoResponse, len(todos))
    for i, todo := range todos {
        responses[i] = toTodoResponse(todo)
    }
    return responses
}

type ListTodosResponse struct {
    Todos []TodoResponse `json:"todos"`
    Total int            `json:"total"`
}

type SearchTodosResponse struct {
    Todos []TodoResponse `json:"todos"`
    Query string         `json:"query"`
    Total int            `json:"total"`
}

type ErrorResponse struct {
    Error   string `json:"error"`
    Message string `json:"message"`
    Code    string `json:"code,omitempty"`
}
```

## Middleware

### Authentication Middleware

```go
// internal/adapter/driving/http/middleware.go

func (s *Server) authMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
    return func(c echo.Context) error {
        // Extract token from Authorization header
        authHeader := c.Request().Header.Get("Authorization")
        if authHeader == "" {
            return echo.NewHTTPError(http.StatusUnauthorized, "Missing authorization header")
        }
        
        // Expected format: "Bearer <token>"
        parts := strings.Split(authHeader, " ")
        if len(parts) != 2 || parts[0] != "Bearer" {
            return echo.NewHTTPError(http.StatusUnauthorized, "Invalid authorization format")
        }
        
        token := parts[1]
        
        // Validate token and extract user ID
        userID, err := s.validateToken(token)
        if err != nil {
            return echo.NewHTTPError(http.StatusUnauthorized, "Invalid token")
        }
        
        // Store user ID in context
        c.Set("user_id", userID)
        
        return next(c)
    }
}

func (s *Server) validateToken(token string) (int64, error) {
    // For now, simple token validation
    // In production, use JWT validation
    
    // Example: token format "user:<userID>"
    if strings.HasPrefix(token, "user:") {
        userIDStr := strings.TrimPrefix(token, "user:")
        userID, err := strconv.ParseInt(userIDStr, 10, 64)
        if err != nil {
            return 0, errors.New("invalid token format")
        }
        return userID, nil
    }
    
    return 0, errors.New("invalid token")
}

func getUserIDFromContext(c echo.Context) int64 {
    userID, ok := c.Get("user_id").(int64)
    if !ok {
        return 0
    }
    return userID
}
```

### CORS Middleware

```go
func corsConfig() echo.MiddlewareFunc {
    return middleware.CORSWithConfig(middleware.CORSConfig{
        AllowOrigins: []string{"*"},  // Configure based on environment
        AllowMethods: []string{http.MethodGet, http.MethodPost, http.MethodPut, http.MethodDelete},
        AllowHeaders: []string{echo.HeaderOrigin, echo.HeaderContentType, echo.HeaderAccept, echo.HeaderAuthorization},
    })
}
```

## Error Handling

```go
// internal/adapter/driving/http/error.go

func handleDomainError(err error) error {
    switch {
    case errors.Is(err, service.ErrTodoNotFound):
        return echo.NewHTTPError(http.StatusNotFound, "Todo not found")
    case errors.Is(err, service.ErrUnauthorized):
        return echo.NewHTTPError(http.StatusForbidden, "Unauthorized")
    case errors.Is(err, entity.ErrTitleRequired):
        return echo.NewHTTPError(http.StatusBadRequest, "Title is required")
    case errors.Is(err, entity.ErrTitleTooLong):
        return echo.NewHTTPError(http.StatusBadRequest, "Title too long")
    case errors.Is(err, entity.ErrInvalidPriority):
        return echo.NewHTTPError(http.StatusBadRequest, "Invalid priority")
    case errors.Is(err, entity.ErrInvalidStatus):
        return echo.NewHTTPError(http.StatusBadRequest, "Invalid status")
    default:
        return echo.NewHTTPError(http.StatusInternalServerError, "Internal server error")
    }
}
```

## Helper Functions

```go
// internal/adapter/driving/http/helpers.go

func parseListFilters(c echo.Context) output.ListFilters {
    filters := output.ListFilters{
        Limit:  20,  // Default
        Offset: 0,
    }
    
    // Parse status filter
    if status := c.QueryParam("status"); status != "" {
        s := entity.Status(status)
        filters.Status = &s
    }
    
    // Parse priority filter
    if priority := c.QueryParam("priority"); priority != "" {
        p := entity.Priority(priority)
        filters.Priority = &p
    }
    
    // Parse tags filter
    if tags := c.QueryParam("tags"); tags != "" {
        filters.Tags = strings.Split(tags, ",")
    }
    
    // Parse limit
    if limitStr := c.QueryParam("limit"); limitStr != "" {
        if limit, err := strconv.Atoi(limitStr); err == nil && limit > 0 {
            filters.Limit = limit
        }
    }
    
    // Parse offset
    if offsetStr := c.QueryParam("offset"); offsetStr != "" {
        if offset, err := strconv.Atoi(offsetStr); err == nil && offset >= 0 {
            filters.Offset = offset
        }
    }
    
    return filters
}
```

## Usage Examples

### cURL Examples

```bash
# Create todo
curl -X POST http://localhost:8080/api/v1/todos \
  -H "Authorization: Bearer user:123456789" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Buy groceries",
    "priority": "high",
    "tags": ["shopping"],
    "due_date": "2026-01-11T10:00:00Z"
  }'

# List todos
curl http://localhost:8080/api/v1/todos?status=pending&limit=10 \
  -H "Authorization: Bearer user:123456789"

# Get todo
curl http://localhost:8080/api/v1/todos/todo-123 \
  -H "Authorization: Bearer user:123456789"

# Update todo
curl -X PUT http://localhost:8080/api/v1/todos/todo-123 \
  -H "Authorization: Bearer user:123456789" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Buy groceries and cook dinner",
    "priority": "high"
  }'

# Complete todo
curl -X POST http://localhost:8080/api/v1/todos/todo-123/complete \
  -H "Authorization: Bearer user:123456789"

# Search todos
curl "http://localhost:8080/api/v1/todos/search?q=grocery" \
  -H "Authorization: Bearer user:123456789"

# Delete todo
curl -X DELETE http://localhost:8080/api/v1/todos/todo-123 \
  -H "Authorization: Bearer user:123456789"
```

## Testing

### Integration Test Example

```go
// test/integration/http_test.go
func TestTodoAPI_CreateTodo(t *testing.T) {
    // Setup test server
    server := setupTestServer(t)
    defer server.Shutdown(context.Background())
    
    // Create request
    body := `{"title": "Test Todo", "priority": "high"}`
    req := httptest.NewRequest(http.MethodPost, "/api/v1/todos", strings.NewReader(body))
    req.Header.Set("Authorization", "Bearer user:123456789")
    req.Header.Set("Content-Type", "application/json")
    
    // Execute
    rec := httptest.NewRecorder()
    server.echo.ServeHTTP(rec, req)
    
    // Assert
    assert.Equal(t, http.StatusCreated, rec.Code)
    
    var response TodoResponse
    json.Unmarshal(rec.Body.Bytes(), &response)
    assert.Equal(t, "Test Todo", response.Title)
    assert.Equal(t, "high", response.Priority)
}
```

## Best Practices

### 1. DTOs for Boundary

Always use DTOs at the HTTP boundary:

```go
// ✅ GOOD
func (s *Server) createTodo(c echo.Context) error {
    var req CreateTodoRequest  // DTO
    c.Bind(&req)
    
    todo, err := s.todoService.CreateTodo(...)  // Domain entity
    return c.JSON(200, toTodoResponse(todo))     // DTO
}

// ❌ BAD - exposing domain entity directly
func (s *Server) createTodo(c echo.Context) error {
    var todo entity.Todo  // Domain entity at boundary!
    c.Bind(&todo)
    return c.JSON(200, todo)
}
```

### 2. Proper HTTP Status Codes

```go
// 200 OK - Success with body
// 201 Created - Resource created
// 204 No Content - Success without body
// 400 Bad Request - Validation error
// 401 Unauthorized - Missing/invalid auth
// 403 Forbidden - Valid auth but insufficient permissions
// 404 Not Found - Resource not found
// 409 Conflict - Business rule violation
// 500 Internal Server Error - Unexpected error
```

### 3. Context Propagation

Always pass context from request:

```go
func (s *Server) createTodo(c echo.Context) error {
    ctx := c.Request().Context()  // Get context from request
    todo, err := s.todoService.CreateTodo(ctx, ...)  // Pass to service
    // ...
}
```

### 4. Validation at Boundary

Validate requests before calling domain:

```go
func (s *Server) createTodo(c echo.Context) error {
    var req CreateTodoRequest
    if err := c.Bind(&req); err != nil {
        return echo.NewHTTPError(400, "Invalid request")
    }
    
    if err := req.Validate(); err != nil {  // Validate at boundary
        return echo.NewHTTPError(400, err.Error())
    }
    
    // Now call domain
    todo, err := s.todoService.CreateTodo(...)
}
```

## Next Steps

- See [Telegram Bot](10-telegram-bot.md) for bot adapter
- Review [Domain Services](07-domain-services.md) for service layer
- Read [Testing Strategy](05-testing-strategy.md) for API testing
