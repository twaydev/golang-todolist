# Database Layer

## Overview

The database layer provides PostgreSQL/Supabase persistence for the application. It's a **driven adapter** that implements repository ports.

**Location**: `internal/adapter/driven/postgres/`

**Technology**: 
- PostgreSQL 15+
- Supabase (managed PostgreSQL)
- pgx/v5 driver

## Architecture

```
Domain Service → Repository Port (Interface) → PostgreSQL Adapter → Supabase
```

## File Structure

```
internal/adapter/driven/postgres/
├── connection.go       # Connection pool setup
├── todo_repo.go        # TodoRepository implementation
├── user_repo.go        # UserRepository implementation
├── template_repo.go    # TemplateRepository implementation
└── helpers.go          # Common SQL helpers
```

## Connection Setup

```go
// internal/adapter/driven/postgres/connection.go
package postgres

import (
    "context"
    "fmt"
    
    "github.com/jackc/pgx/v5/pgxpool"
)

func NewConnection(ctx context.Context, databaseURL string) (*pgxpool.Pool, error) {
    config, err := pgxpool.ParseConfig(databaseURL)
    if err != nil {
        return nil, fmt.Errorf("unable to parse DATABASE_URL: %w", err)
    }
    
    // Configure connection pool
    config.MaxConns = 25
    config.MinConns = 5
    config.MaxConnLifetime = time.Hour
    config.MaxConnIdleTime = 30 * time.Minute
    
    pool, err := pgxpool.NewWithConfig(ctx, config)
    if err != nil {
        return nil, fmt.Errorf("unable to create connection pool: %w", err)
    }
    
    // Test connection
    if err := pool.Ping(ctx); err != nil {
        return nil, fmt.Errorf("unable to ping database: %w", err)
    }
    
    return pool, nil
}
```

## TodoRepository Implementation

```go
// internal/adapter/driven/postgres/todo_repo.go
type PostgresTodoRepository struct {
    pool *pgxpool.Pool
}

func NewTodoRepository(pool *pgxpool.Pool) *PostgresTodoRepository {
    return &PostgresTodoRepository{pool: pool}
}

// Create implements output.TodoRepository
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

// Update implements output.TodoRepository
func (r *PostgresTodoRepository) Update(ctx context.Context, todo *entity.Todo) error {
    query := `
        UPDATE todos 
        SET title = $1, description = $2, due_date = $3, priority = $4, status = $5, 
            tags = $6, updated_at = NOW()
        WHERE telegram_user_id = $7 AND id = $8`
    
    result, err := r.pool.Exec(ctx, query,
        todo.Title, todo.Description, todo.DueDate, todo.Priority, todo.Status, todo.Tags,
        todo.TelegramUserID, todo.ID,
    )
    if err != nil {
        return err
    }
    
    if result.RowsAffected() == 0 {
        return fmt.Errorf("todo not found")
    }
    
    return nil
}

// List implements output.TodoRepository
func (r *PostgresTodoRepository) List(ctx context.Context, userID int64, filters output.ListFilters) ([]*entity.Todo, error) {
    query := `SELECT id, code, title, description, due_date, priority, status, tags, created_at, updated_at
              FROM todos WHERE telegram_user_id = $1`
    args := []interface{}{userID}
    argPos := 2
    
    // Apply filters
    if filters.Status != nil {
        query += fmt.Sprintf(" AND status = $%d", argPos)
        args = append(args, *filters.Status)
        argPos++
    }
    
    if filters.Priority != nil {
        query += fmt.Sprintf(" AND priority = $%d", argPos)
        args = append(args, *filters.Priority)
        argPos++
    }
    
    // Order and limit
    query += " ORDER BY created_at DESC"
    if filters.Limit > 0 {
        query += fmt.Sprintf(" LIMIT $%d", argPos)
        args = append(args, filters.Limit)
        argPos++
    }
    
    rows, err := r.pool.Query(ctx, query, args...)
    if err != nil {
        return nil, err
    }
    defer rows.Close()
    
    var todos []*entity.Todo
    for rows.Next() {
        todo := &entity.Todo{}
        err := rows.Scan(
            &todo.ID, &todo.Code, &todo.Title, &todo.Description,
            &todo.DueDate, &todo.Priority, &todo.Status, &todo.Tags,
            &todo.CreatedAt, &todo.UpdatedAt,
        )
        if err != nil {
            return nil, err
        }
        todo.TelegramUserID = userID
        todos = append(todos, todo)
    }
    
    return todos, rows.Err()
}

// Search implements output.TodoRepository
func (r *PostgresTodoRepository) Search(ctx context.Context, userID int64, query string) ([]*entity.Todo, error) {
    sqlQuery := `
        SELECT id, code, title, description, due_date, priority, status, tags, created_at, updated_at
        FROM todos
        WHERE telegram_user_id = $1
          AND (
            to_tsvector('english', title) @@ plainto_tsquery('english', $2)
            OR to_tsvector('english', COALESCE(description, '')) @@ plainto_tsquery('english', $2)
          )
        ORDER BY created_at DESC
        LIMIT 50`
    
    rows, err := r.pool.Query(ctx, sqlQuery, userID, query)
    if err != nil {
        return nil, err
    }
    defer rows.Close()
    
    var todos []*entity.Todo
    for rows.Next() {
        todo := &entity.Todo{}
        err := rows.Scan(
            &todo.ID, &todo.Code, &todo.Title, &todo.Description,
            &todo.DueDate, &todo.Priority, &todo.Status, &todo.Tags,
            &todo.CreatedAt, &todo.UpdatedAt,
        )
        if err != nil {
            return nil, err
        }
        todo.TelegramUserID = userID
        todos = append(todos, todo)
    }
    
    return todos, rows.Err()
}
```

## Database Schema

See [Database Schema](15-database-schema.md) for complete schema details.

### Key Tables

**todos**:
- `id` UUID (primary key)
- `telegram_user_id` BIGINT (user isolation)
- `code` TEXT (unique, format: YY-NNNN)
- `title` TEXT
- `description` TEXT (nullable)
- `due_date` TIMESTAMPTZ (nullable)
- `priority` TEXT
- `status` TEXT
- `tags` TEXT[]
- `created_at` TIMESTAMPTZ
- `updated_at` TIMESTAMPTZ

**user_preferences**:
- `telegram_user_id` BIGINT (primary key)
- `language` TEXT
- `timezone` TEXT
- `created_at` TIMESTAMPTZ
- `updated_at` TIMESTAMPTZ

## Testing

```go
// test/integration/postgres_test.go
func TestPostgresTodoRepository_Create(t *testing.T) {
    // Setup test database
    ctx := context.Background()
    pool := setupTestDB(t)
    defer pool.Close()
    
    repo := postgres.NewTodoRepository(pool)
    
    // Test
    todo := &entity.Todo{
        TelegramUserID: 123456789,
        Title:          "Test todo",
        Status:         entity.StatusPending,
        Priority:       entity.PriorityMedium,
    }
    
    err := repo.Create(ctx, todo)
    
    // Assert
    assert.NoError(t, err)
    assert.NotEmpty(t, todo.ID)
    assert.NotEmpty(t, todo.Code)
}
```

## Best Practices

1. **Use Parameterized Queries** - Prevent SQL injection
2. **Handle NULL values** - Use pointers for nullable fields
3. **Connection Pooling** - Reuse connections
4. **Row-Level Security** - Isolate user data
5. **Indexes** - Optimize query performance

## Next Steps

- See [Database Schema](15-database-schema.md) for schema details
- Review [Port Interfaces](08-port-interfaces.md) for repository interface
- Read [Testing Strategy](05-testing-strategy.md) for integration testing
