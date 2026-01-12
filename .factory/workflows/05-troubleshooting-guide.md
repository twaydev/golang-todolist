# Troubleshooting Guide

## Overview

This guide helps diagnose and fix common issues when working with the multi-agent Telegram Todo Bot system.

---

## Quick Diagnostics

### System Health Check

```bash
# 1. Application running?
curl http://localhost:8080/health

# 2. Database accessible?
psql $DATABASE_URL -c "SELECT 1;"

# 3. Tests passing?
go test ./... -v

# 4. Build successful?
go build -o bot cmd/bot/main.go

# 5. Dependencies OK?
go mod verify
```

---

## Common Issues by Agent

---

## Test-First Agent Issues

### Issue: Godog Tests Not Found

**Symptoms**:
```
no test files found
```

**Diagnosis**:
```bash
ls features/*.feature
ls test/bdd/*_test.go
```

**Solution**:
```bash
# Ensure feature files exist
mkdir -p features
touch features/todo_create.feature

# Ensure step definitions exist
mkdir -p test/bdd
touch test/bdd/todo_create_steps_test.go

# Run with explicit path
go test ./test/bdd/... -v
```

---

### Issue: Step Definition Not Matched

**Symptoms**:
```
Step definition not found for: When I create a todo "Buy milk"
```

**Solution**:
```go
// Check step definition pattern
func (ctx *TestContext) iCreateATodo(title string) error {
    // Make sure regex matches
}

// In InitializeScenario:
ctx.Step(`^I create a todo "([^"]*)"$`, ctx.iCreateATodo)
```

---

### Issue: Tests Pass Locally, Fail in CI

**Diagnosis**:
```bash
# Check environment differences
echo $DATABASE_URL
echo $GO_ENV

# Check timezone
date

# Check dependencies
go mod download
```

**Solution**:
```yaml
# .github/workflows/ci.yml
env:
  TZ: UTC
  DATABASE_URL: postgresql://test:test@localhost:5432/test
  GO_ENV: test
```

---

## Domain Logic Agent Issues

### Issue: Circular Import

**Symptoms**:
```
import cycle not allowed
package internal/domain/service imports internal/domain/entity imports internal/domain/service
```

**Diagnosis**:
```bash
go list -f '{{.ImportPath}} {{.Imports}}' ./internal/domain/...
```

**Solution**:
```
Move shared types to entity package or create separate types package.

internal/domain/
  ├── entity/       (no dependencies)
  ├── port/         (depends on entity only)
  └── service/      (depends on entity + port)
```

---

### Issue: Domain Imports Infrastructure

**Symptoms**:
```
internal/domain/service/todo_service.go:5:2: should not import "internal/adapter/driven/postgres"
```

**Solution**:
```
Use ports (interfaces) instead of concrete implementations.

❌ Bad:
import "internal/adapter/driven/postgres"

✅ Good:
import "internal/domain/port/output"
```

---

### Issue: Error Not Handled Properly

**Symptoms**:
```
panic: runtime error: invalid memory address or nil pointer dereference
```

**Diagnosis**:
```go
// Check error handling
result, err := someFunc()
if err != nil {
    return nil, fmt.Errorf("operation failed: %w", err)  // ✅ Wrapped
}

// Don't ignore errors
result, _ := someFunc()  // ❌ Dangerous
```

**Solution**:
```go
// Always handle errors
// Use error wrapping (%w) for context
// Return errors up the stack
// Handle errors at boundaries (API layer)
```

---

## Database Agent Issues

### Issue: Migration Fails

**Symptoms**:
```
error: migration failed: syntax error at or near "CREATE"
```

**Diagnosis**:
```bash
# Test migration locally
psql $DATABASE_URL < migrations/001_initial_schema.sql

# Check syntax
cat migrations/001_initial_schema.sql | psql $DATABASE_URL --dry-run
```

**Solution**:
```sql
-- Check for common issues:
-- 1. Missing semicolons
-- 2. Invalid SQL syntax
-- 3. References to non-existent tables
-- 4. Constraint violations

-- Test with transaction
BEGIN;
-- Your migration SQL
ROLLBACK;  -- Don't commit yet
```

---

### Issue: RLS Blocks Access

**Symptoms**:
```
ERROR: new row violates row-level security policy for table "todos"
```

**Diagnosis**:
```sql
-- Check RLS status
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename='todos';

-- Check policies
SELECT * FROM pg_policies WHERE tablename='todos';

-- Check current user context
SHOW app.user_id;
```

**Solution**:
```sql
-- Set user context before operations
SET app.user_id = '123456789';

-- Or in Go:
_, err := db.Exec(ctx, "SET app.user_id = $1", userID)

-- For service operations, use service role (bypasses RLS)
```

---

### Issue: Connection Pool Exhausted

**Symptoms**:
```
pq: sorry, too many clients already
```

**Diagnosis**:
```bash
# Check active connections
psql $DATABASE_URL -c "SELECT count(*) FROM pg_stat_activity;"

# Check max connections
psql $DATABASE_URL -c "SHOW max_connections;"
```

**Solution**:
```go
// Configure pool limits
poolConfig, err := pgxpool.ParseConfig(os.Getenv("DATABASE_URL"))
poolConfig.MaxConns = 10  // Reasonable limit
poolConfig.MinConns = 2
poolConfig.MaxConnIdleTime = 30 * time.Minute

pool, err := pgxpool.NewWithConfig(context.Background(), poolConfig)
```

---

### Issue: Query Performance Slow

**Diagnosis**:
```sql
-- Use EXPLAIN ANALYZE
EXPLAIN ANALYZE 
SELECT * FROM todos 
WHERE telegram_user_id = 123456789 
  AND status = 'pending'
ORDER BY created_at DESC;

-- Check for sequential scans (bad)
-- Look for index scans (good)
```

**Solution**:
```sql
-- Add missing indexes
CREATE INDEX idx_todos_user_status ON todos(telegram_user_id, status);

-- Update statistics
ANALYZE todos;
```

---

## API Adapter Agent Issues

### Issue: Echo Server Not Starting

**Symptoms**:
```
bind: address already in use
```

**Diagnosis**:
```bash
# Check what's using the port
lsof -i :8080

# Kill it
kill -9 <PID>
```

**Solution**:
```go
// Use environment variable for port
port := os.Getenv("PORT")
if port == "" {
    port = "8080"
}
e.Start(":" + port)
```

---

### Issue: CORS Error in Browser

**Symptoms**:
```
Access to fetch at 'http://localhost:8080/api/v1/todos' from origin 'http://localhost:3000' has been blocked by CORS policy
```

**Solution**:
```go
import "github.com/labstack/echo/v4/middleware"

e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
    AllowOrigins: []string{"http://localhost:3000"},
    AllowMethods: []string{http.MethodGet, http.MethodPost, http.MethodPut, http.MethodDelete},
    AllowHeaders: []string{echo.HeaderContentType, echo.HeaderAuthorization},
}))
```

---

### Issue: JWT Token Invalid

**Symptoms**:
```
401 Unauthorized: Invalid token
```

**Diagnosis**:
```bash
# Decode JWT token (without verifying)
echo "eyJhbGc..." | base64 -d

# Check token expiration
# Check secret key matches
```

**Solution**:
```go
// Ensure secret key matches between generation and validation
jwtSecret := os.Getenv("JWT_SECRET")
if jwtSecret == "" {
    log.Fatal("JWT_SECRET not set")
}

// Check token expiration
claims := &Claims{}
token, err := jwt.ParseWithClaims(tokenString, claims, ...)
if err != nil {
    if err == jwt.ErrSignatureInvalid {
        return echo.NewHTTPError(http.StatusUnauthorized, "Invalid signature")
    }
    return echo.NewHTTPError(http.StatusUnauthorized, "Invalid token")
}
```

---

### Issue: Telegram Bot Not Responding

**Symptoms**:
```
Bot doesn't respond to messages
```

**Diagnosis**:
```bash
# Check bot token
echo $TELEGRAM_BOT_TOKEN

# Test token with Telegram API
curl https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getMe
```

**Solution**:
```go
// Check bot initialization
bot, err := tele.NewBot(tele.Settings{
    Token:  os.Getenv("TELEGRAM_BOT_TOKEN"),
    Poller: &tele.LongPoller{Timeout: 10 * time.Second},
})
if err != nil {
    log.Fatal(err)  // Will show error
}

// Check handler registration
bot.Handle("/start", startHandler)
bot.Handle(tele.OnText, textHandler)

// Start bot
log.Println("Bot started...")
bot.Start()  // This blocks
```

---

## AI/NLP Agent Issues

### Issue: Perplexity API Returns Error

**Symptoms**:
```
API error: 401 Unauthorized
```

**Diagnosis**:
```bash
# Check API key
echo $PERPLEXITY_API_KEY

# Test API directly
curl https://api.perplexity.ai/chat/completions \
  -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3.1-sonar-small-128k-online",
    "messages": [{"role": "user", "content": "test"}]
  }'
```

**Solution**:
```go
// Ensure API key is set
apiKey := os.Getenv("PERPLEXITY_API_KEY")
if apiKey == "" {
    return nil, errors.New("PERPLEXITY_API_KEY not set")
}

// Add error handling and retries
func (c *Client) Chat(ctx context.Context, messages []Message) (*Response, error) {
    var resp *Response
    var err error
    
    for i := 0; i < 3; i++ {  // Retry up to 3 times
        resp, err = c.doRequest(ctx, messages)
        if err == nil {
            return resp, nil
        }
        
        if i < 2 {
            time.Sleep(time.Second * time.Duration(i+1))
        }
    }
    
    return nil, fmt.Errorf("API request failed after retries: %w", err)
}
```

---

### Issue: Intent Parsing Returns Wrong Action

**Symptoms**:
```
User: "Buy milk"
Parsed: action="delete" (should be "create")
```

**Diagnosis**:
```
Check system prompt in prompts/system_prompt_en.txt
Add more examples
Test with different messages
```

**Solution**:
```
Improve system prompt:
- Add more examples for each action
- Be more explicit about action keywords
- Include edge cases
- Use few-shot learning

Example:
"When user says 'buy X', 'get X', 'add X' → action: create
When user says 'done X', 'complete X', 'finish X' → action: complete"
```

---

## Infrastructure Agent Issues

### Issue: Docker Build Fails

**Symptoms**:
```
ERROR: failed to solve: process "/bin/sh -c go build..." did not complete successfully
```

**Diagnosis**:
```bash
# Build with verbose output
docker build -t test . --progress=plain

# Check for errors in output
```

**Solution**:
```dockerfile
# Common fixes:

# 1. Copy go.mod first for caching
COPY go.mod go.sum ./
RUN go mod download
COPY . .

# 2. Set CGO_ENABLED=0 for alpine
RUN CGO_ENABLED=0 go build ...

# 3. Check file paths
COPY . .  # Not COPY . /app
```

---

### Issue: Railway Deployment Fails

**Symptoms**:
```
Deployment failed: Health check timeout
```

**Diagnosis**:
```bash
# Check Railway logs
railway logs

# Common issues:
# 1. Application not listening on correct port
# 2. Health check endpoint not responding
# 3. Environment variables missing
```

**Solution**:
```go
// 1. Use PORT from environment
port := os.Getenv("PORT")
if port == "" {
    port = "8080"
}
e.Start("0.0.0.0:" + port)  // Must be 0.0.0.0, not localhost

// 2. Implement health check
e.GET("/health", func(c echo.Context) error {
    return c.JSON(200, map[string]string{"status": "ok"})
})

// 3. Check environment variables
railway variables
```

---

### Issue: CI/CD Pipeline Fails

**Symptoms**:
```
GitHub Actions workflow failed
```

**Diagnosis**:
```bash
# Check workflow file
cat .github/workflows/ci.yml

# Check action logs on GitHub
# Common issues:
# 1. Tests fail in CI (but pass locally)
# 2. Missing environment variables
# 3. Dependencies not installed
```

**Solution**:
```yaml
# Ensure dependencies installed
- name: Install dependencies
  run: go mod download

# Set environment variables
env:
  DATABASE_URL: postgresql://test:test@localhost/test
  GO_ENV: test

# Run services (like Postgres)
services:
  postgres:
    image: postgres:15
    env:
      POSTGRES_PASSWORD: test
    ports:
      - 5432:5432
```

---

## Performance Issues

### Issue: High Memory Usage

**Diagnosis**:
```bash
# Profile memory
go test -memprofile mem.prof ./...
go tool pprof mem.prof

# Check for leaks
(pprof) top10
(pprof) list <function>
```

**Solution**:
```go
// Close database connections
defer db.Close()

// Use connection pooling
// Limit goroutines
// Avoid storing large data in memory
```

---

### Issue: Slow Response Times

**Diagnosis**:
```bash
# Profile CPU
go test -cpuprofile cpu.prof ./...
go tool pprof cpu.prof

# Check database queries
# Check API call latency
```

**Solution**:
```go
// Add caching
// Optimize database queries (add indexes)
// Use connection pooling
// Implement rate limiting
// Use goroutines for concurrent operations
```

---

## Debugging Techniques

### Enable Debug Logging

```go
// Use slog with debug level
logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelDebug,
}))

logger.Debug("processing request",
    "user_id", userID,
    "action", action,
    "input", input,
)
```

### Use Delve Debugger

```bash
# Install delve
go install github.com/go-delve/delve/cmd/dlv@latest

# Debug tests
dlv test ./internal/domain/service/...

# Set breakpoint
(dlv) break todo_service.go:42
(dlv) continue
(dlv) print todo
(dlv) next
```

### Add Tracing

```go
import "go.opentelemetry.io/otel"

// Add tracing to functions
func (s *TodoService) CreateTodo(ctx context.Context, ...) (*Todo, error) {
    ctx, span := otel.Tracer("domain").Start(ctx, "CreateTodo")
    defer span.End()
    
    // Your code
}
```

---

## Getting Help

### Check Documentation
1. Read relevant skill in `.factory/skills/`
2. Review workflow in `.factory/workflows/`
3. Check architecture docs in `docs/`

### Search Logs
```bash
# Local logs
tail -f logs/app.log | grep ERROR

# Railway logs
railway logs --tail | grep ERROR
```

### Ask the Right Agent
- Test issues → `@test-first-agent`
- Domain logic → `@domain-logic-agent`
- Database → `@database-agent`
- API/Bot → `@api-adapter-agent`
- NLP → `@ai-nlp-agent`
- Deploy → `@infrastructure-agent`

---

## Prevention

### Write Tests First
- Catch issues early
- Document expected behavior
- Prevent regressions

### Use Linters
```bash
# Install
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Run
golangci-lint run
```

### Code Review
- Have agents review each other's work
- Check architecture boundaries
- Verify error handling

### Monitor Production
- Check logs regularly
- Set up alerts
- Monitor performance metrics
