# Feature Implementation Workflow

## Overview

This workflow describes the complete process for implementing a new feature using all 5 specialized agents in a test-first, hexagonal architecture approach.

---

## Prerequisites

### Start Local Development Environment
```bash
# Start PostgreSQL, migrations, and API via Docker Compose
make up

# Verify services are running
make ps

# View logs if needed
make logs
```

---

## Complete Feature Flow

```
Step 0: Start local environment     -> make up
Step 1: Test-First Agent (RED)     -> Write tests that FAIL
Step 2: Domain Logic Agent (GREEN)  -> Make tests PASS
Step 3: Database Agent              -> Create schema & repositories
Step 4: API Adapter Agent           -> Build REST API interface
Step 5: Infrastructure Agent        -> Deploy
Step 6: Integration Testing         -> Verify everything works
```

---

## Example: Create Todo Feature

### Step 1: Test-First Agent (RED State)

**Agent**: `@test-first-agent`

**Prompt**:
```
Write comprehensive BDD tests for "Create Todo via REST API" feature.

Requirements:
- Users can create todos via REST API
- Todo requires a title (1-500 characters)
- Optional: description, priority, due_date, tags
- Returns 201 Created with auto-generated code (YY-NNNN format)
- Returns 400 Bad Request for validation errors
- Returns 401 Unauthorized without valid token

Use skills:
- testing/godog for Gherkin scenarios
- testing/testify for assertions
- mocking/mockery for mocks

Create:
1. features/todo_create.feature with scenarios:
   - Valid todo creation
   - Empty title validation
   - Title too long validation
   - Invalid priority validation
   - Missing authentication
   - Edge cases (unicode, special characters)

2. test/bdd/todo_create_steps_test.go with:
   - Test context setup
   - Step definitions
   - Helper functions

3. test/unit/domain/todo_service_test.go with:
   - TestCreateTodo_Success
   - TestCreateTodo_EmptyTitle
   - TestCreateTodo_TitleTooLong
   - TestCreateTodo_RepositoryError

Ensure ALL tests FAIL initially (RED state).
```

**Expected Output**:
```
features/todo_create.feature (10 scenarios)
test/bdd/todo_create_steps_test.go (step definitions)
test/unit/domain/todo_service_test.go (unit tests)
Test Status: All FAILING (RED) - as expected
```

**Validation**:
```bash
# Verify tests fail
go test ./test/bdd/... -v
go test ./test/unit/domain/... -v

# Both should show failures
```

---

### Step 2: Domain Logic Agent (GREEN State)

**Agent**: `@domain-logic-agent`

**Prompt**:
```
Implement domain logic to make all todo creation tests pass.

Context:
- Failing tests in test/unit/domain/todo_service_test.go
- Following hexagonal architecture principles
- NO infrastructure dependencies allowed

Use skills:
- golang/interfaces for port definitions
- golang/error-handling for errors
- domain-driven-design for entities
- design-patterns/hexagonal-architecture

Implement:
1. internal/domain/entity/todo.go:
   - Todo struct with fields: ID, UserID, Code, Title, Description,
     DueDate, Priority, Status, Tags, CreatedAt, UpdatedAt
   - Validate() method (title 1-500 chars, valid priority)
   - MarkComplete() method
   - IsOverdue() method

2. internal/domain/entity/priority.go:
   - Priority type (low, medium, high)
   - Validation method

3. internal/domain/entity/status.go:
   - Status type (pending, in_progress, completed)

4. internal/domain/port/output/todo_repository.go:
   - TodoRepository interface with methods:
     * Create(ctx, todo) error
     * Update(ctx, todo) error
     * Delete(ctx, userID, todoID) error
     * GetByID(ctx, userID, todoID) (*Todo, error)
     * GetByCode(ctx, userID, code) (*Todo, error)
     * List(ctx, userID, filters) ([]*Todo, error)

5. internal/domain/service/todo_service.go:
   - TodoService struct with injected dependencies
   - CreateTodo(ctx, userID, title, options) (*Todo, error)
   - Business logic orchestration
   - Error handling

Make ALL tests PASS (GREEN state).
```

**Expected Output**:
```
internal/domain/entity/todo.go
internal/domain/entity/priority.go
internal/domain/entity/status.go
internal/domain/port/output/todo_repository.go
internal/domain/service/todo_service.go
Test Status: All PASSING (GREEN)
Architecture: No infrastructure imports
```

**Validation**:
```bash
# Verify tests pass
go test ./test/unit/domain/... -v

# Verify no infrastructure imports
go list -f '{{.Imports}}' internal/domain/... | grep -E '(postgres|http)'
# Should return nothing (no infrastructure imports)
```

---

### Step 3: Database Agent

**Agent**: `@database-agent`

**Prompt**:
```
Design PostgreSQL schema for todos with RLS and auto-generated codes.

Use skills:
- postgresql/advanced for JSONB, triggers, full-text search
- supabase/rls for multi-tenant security
- database/migrations for versioning

Create:
1. migrations/001_initial_schema.sql:
   - user_preferences table (user_id, language, timezone)
   - todos table with:
     * id UUID PRIMARY KEY
     * user_id BIGINT
     * code TEXT (YY-NNNN format)
     * title TEXT (1-500 chars constraint)
     * description TEXT
     * due_date TIMESTAMPTZ
     * priority TEXT CHECK (low/medium/high)
     * status TEXT CHECK (pending/in_progress/completed)
     * tags TEXT[]
     * created_at, updated_at TIMESTAMPTZ
   - Indexes: user+status, user+created, due_date, tags (GIN)
   - Auto-update timestamp trigger

2. migrations/001_initial_schema_down.sql:
   - Rollback migration

3. migrations/002_code_sequence.sql:
   - code_sequences table
   - generate_todo_code() function
   - Trigger to auto-assign codes on INSERT

4. migrations/003_enable_rls.sql:
   - Enable RLS on todos and user_preferences
   - Policy: users_manage_own_todos
   - Policy: service_role_bypass

5. internal/adapter/driven/postgres/connection.go:
   - Connection pool setup with pgx

6. internal/adapter/driven/postgres/todo_repo.go:
   - Implement TodoRepository interface
   - Set user context for RLS
   - All CRUD methods
```

**Expected Output**:
```
migrations/001_initial_schema.sql
migrations/001_initial_schema_down.sql
migrations/002_code_sequence.sql
migrations/003_enable_rls.sql
internal/adapter/driven/postgres/connection.go
internal/adapter/driven/postgres/todo_repo.go
Migrations apply successfully
```

**Validation**:
```bash
# Apply migrations (requires DATABASE_URL)
migrate -database "$DATABASE_URL" -path ./migrations up

# Verify tables exist
psql $DATABASE_URL -c "\dt"

# Verify RLS enabled
psql $DATABASE_URL -c "SELECT tablename, rowsecurity FROM pg_tables WHERE tablename='todos';"
```

---

### Step 4: API Adapter Agent

**Agent**: `@api-adapter-agent`

**Prompt**:
```
Implement REST API for todo creation.

Use skills:
- golang/echo-framework for HTTP API
- authentication/jwt for security

Implement:
1. internal/adapter/driving/http/server.go:
   - Echo server setup
   - Middleware (logger, recover, CORS)

2. internal/adapter/driving/http/routes.go:
   - POST /api/v1/todos
   - GET /api/v1/todos
   - With JWT middleware

3. internal/adapter/driving/http/handlers.go:
   - createTodo handler
   - Bind request, validate, call service
   - Map domain errors to HTTP status codes

4. internal/adapter/driving/http/dto.go:
   - CreateTodoRequest struct
   - TodoResponse struct
   - Mapping functions

NO business logic in adapters - only translation.
```

**Expected Output**:
```
internal/adapter/driving/http/*.go
POST /api/v1/todos endpoint works
```

**Validation**:
```bash
# Start server
go run cmd/api/main.go

# Test API (in another terminal)
curl -X POST http://localhost:8080/api/v1/todos \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Buy milk"}'

# Should return 201 with todo JSON
```

---

### Step 5: Infrastructure Agent

**Agent**: `@infrastructure-agent`

**Prompt**:
```
Setup CI/CD pipeline and deployment.

Use skills:
- cicd/github-actions for workflows
- containerization/docker
- deployment/railway

Create:
1. .github/workflows/ci.yml:
   - Lint (golangci-lint)
   - Test (unit + BDD)
   - Build

2. .github/workflows/deploy.yml:
   - Deploy to Railway on push to main

3. Dockerfile:
   - Multi-stage build
   - Alpine runtime
   - Non-root user

4. railway.toml:
   - Build and deploy config

5. Makefile:
   - Common commands (build, test, lint, deploy)
```

**Expected Output**:
```
.github/workflows/ci.yml
.github/workflows/deploy.yml
Dockerfile
railway.toml
Makefile
```

**Validation**:
```bash
# Test Docker build
docker build -t golang-todolist .
docker run --env-file .env golang-todolist

# Test CI locally
make lint
make test
```

---

### Step 6: Integration Testing

**Manual verification**:

```bash
# 1. Ensure local environment is running
make up
make ps

# 2. Run all tests
make test

# 3. Run Docker-based integration tests
make test-docker

# 4. Test REST API
curl -X POST http://localhost:8080/api/v1/todos \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Buy groceries",
    "priority": "high",
    "tags": ["shopping"]
  }'

# 5. Verify in database (connect to Docker PostgreSQL)
docker compose exec db psql -U postgres -d todolist -c "SELECT code, title, due_date FROM todos ORDER BY created_at DESC LIMIT 5;"

# 6. Deploy to staging
git push origin main
# GitHub Actions runs CI/CD
# Railway deploys automatically
```

---

## Success Criteria

- All unit tests pass
- All BDD scenarios pass
- REST API endpoint works
- Database has proper data
- RLS policies enforced
- CI/CD pipeline succeeds
- Application deployed to Railway

---

## Troubleshooting

### Tests Still Failing After Domain Implementation
```bash
# Check what's failing
go test ./test/... -v

# Review the specific error
# Fix domain logic
# Re-run tests
```

### Architecture Violations
```bash
# Check for bad imports
go list -f '{{.Imports}}' internal/domain/... | grep -E '(postgres|echo)'

# If found, refactor to use ports
```

### Database Connection Issues
```bash
# Verify Docker database is running
make ps

# Restart database if needed
make restart

# Connect to Docker PostgreSQL
docker compose exec db psql -U postgres -d todolist -c "SELECT 1;"

# Check RLS is working
docker compose exec db psql -U postgres -d todolist -c "SET app.user_id = '123'; SELECT * FROM todos;"
```

### Docker Compose Issues
```bash
# Check service status
make ps

# View logs for specific service
make logs      # API logs
make logs-db   # Database logs

# Rebuild and restart all services
make down
make up-all

# Reset database (WARNING: deletes data)
make down
docker volume rm golang-todolist_postgres_data
make up
```

---

## Next Features

After completing "Create Todo", follow the same workflow for:
- List Todos
- Complete Todo
- Update Todo
- Delete Todo
- Search Todos
- Task Templates

Each feature goes through the same 6 steps.
