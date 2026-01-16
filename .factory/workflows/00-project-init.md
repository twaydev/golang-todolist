# Project Initialization Workflow

## Overview

This workflow creates a production-ready Go REST API skeleton with authentication and CI/CD. After completion, you can immediately test the API endpoints.

---

## What You Get

| Feature | Endpoint | Description |
|---------|----------|-------------|
| Health Check | `GET /health` | Verify API is running |
| Register | `POST /auth/register` | Create new user |
| Login | `POST /auth/login` | Get JWT token |
| Protected Route | `GET /api/v1/me` | Requires auth |

---

## Tech Stack & Integrations

| Component | Technology | MCP Required |
|-----------|------------|--------------|
| Language | Go 1.22+ | - |
| HTTP Framework | Echo | - |
| Database | PostgreSQL/Supabase | Supabase MCP |
| Task Management | Linear | Linear MCP |
| Deployment | Railway | Railway MCP |
| Architecture | Hexagonal | - |
| CI/CD | GitHub Actions | - |

---

## Pre-flight: MCP Integration Check

**IMPORTANT:** Before starting, verify all MCP integrations are working.

### Required MCP Servers

1. **Linear MCP** - Task management and progress tracking
2. **Supabase MCP** - Database operations and migrations
3. **Railway MCP** - Deployment and environment management

### Verification Checklist

#### 1. Linear MCP Check
```
Verify:
- [ ] Can list workspaces/teams
- [ ] Can create issues
- [ ] Can add labels
- [ ] Can update issue status

Test commands:
- List teams: linear_get_teams
- List labels: linear_get_labels
- Create test issue: linear_create_issue
```

**Expected Response:**
```json
{
  "teams": [{"id": "...", "name": "Your Team"}],
  "labels": [{"id": "...", "name": "type:feature"}]
}
```

#### 2. Supabase MCP Check
```
Verify:
- [ ] Can connect to project
- [ ] Can list tables
- [ ] Can execute queries
- [ ] Can run migrations

Test commands:
- List projects: supabase_list_projects
- Get project info: supabase_get_project
- Test query: supabase_execute_sql "SELECT 1"
```

**Expected Response:**
```json
{
  "project": {"id": "...", "name": "your-project"},
  "status": "ACTIVE"
}
```

#### 3. Railway MCP Check
```
Verify:
- [ ] Can list projects
- [ ] Can get service status
- [ ] Can view deployments
- [ ] Can access environment variables

Test commands:
- List projects: railway_list_projects
- Get project: railway_get_project
- List services: railway_list_services
```

**Expected Response:**
```json
{
  "projects": [{"id": "...", "name": "your-project"}],
  "status": "connected"
}
```

### Pre-flight Report Template

Post to Linear as first comment on Epic:
```
Pre-flight Check Complete

MCP Integrations:
- Linear: ✅ Connected (Team: {team_name})
- Supabase: ✅ Connected (Project: {project_name})
- Railway: ✅ Connected (Project: {project_name})

Environment:
- Go version: {go_version}
- Working directory: {cwd}

Ready to proceed with Phase 0.
```

### Troubleshooting MCP Issues

#### Linear MCP Not Responding
```bash
# Check MCP server status
# Verify API key in environment
# Restart MCP server if needed
```

#### Supabase MCP Connection Failed
```bash
# Verify SUPABASE_URL and SUPABASE_KEY
# Check project status in Supabase dashboard
# Ensure project is not paused
```

#### Railway MCP Authentication Error
```bash
# Run: railway login
# Verify RAILWAY_TOKEN is set
# Check project permissions
```

---

## Linear Epic

```markdown
Title: [Init] Project Skeleton with Auth

Description:
Create production-ready Go REST API skeleton with:
- Health check endpoint
- JWT authentication (register/login)
- Protected route example
- PostgreSQL database (Supabase)
- CI/CD pipeline
- Railway deployment

Acceptance Criteria:
- [ ] MCP integrations verified (Linear, Supabase, Railway)
- [ ] GET /health returns 200
- [ ] POST /auth/register creates user
- [ ] POST /auth/login returns JWT token
- [ ] GET /api/v1/me requires valid token
- [ ] CI/CD pipeline passing
- [ ] Deployed to Railway

Labels: type:init
```

---

## Phase 0: Directory Setup

**Run the init script:**
```bash
./orchestrator/scripts/init-project.sh
```

**Creates:**
```
app/
├── cmd/api/              # Entry point
├── internal/
│   ├── domain/           # Business logic
│   ├── adapter/          # HTTP & DB
│   ├── auth/             # JWT handling
│   └── config/           # Configuration
├── migrations/           # Database
└── test/                 # Tests
```

**Linear Update:**
```
Phase 0 complete - Directory structure created

Files created:
- app/cmd/api/
- app/internal/domain/{entity,service,port}
- app/internal/adapter/{driving,driven}
- app/migrations/
- go.mod initialized
```

---

## Phase 1: Infrastructure

**Agent:** infrastructure-agent

### 1.1 Create Makefile

```makefile
.PHONY: dev build test lint run docker-build deploy

dev:
	air

run:
	go run app/cmd/api/main.go

build:
	go build -o bin/api app/cmd/api/main.go

test:
	go test ./app/... -v -cover

lint:
	golangci-lint run ./app/...

docker-build:
	docker build -t myapp .

deploy:
	railway up
```

### 1.2 Create Dockerfile

```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o api app/cmd/api/main.go

FROM alpine:3.19
RUN apk --no-cache add ca-certificates
RUN adduser -D -g '' appuser
WORKDIR /app
COPY --from=builder /build/api .
USER appuser
EXPOSE 8080
CMD ["./api"]
```

### 1.3 Create GitHub Actions CI

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - name: Install dependencies
        run: go mod download
      - name: Run tests
        run: go test ./app/... -v -cover
      - name: Build
        run: go build ./app/...

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - name: golangci-lint
        uses: golangci-lint/golangci-lint-action@v4
        with:
          version: latest
```

### 1.4 Create railway.toml

```toml
[build]
builder = "dockerfile"

[deploy]
healthcheckPath = "/health"
healthcheckTimeout = 300
restartPolicyType = "on_failure"
restartPolicyMaxRetries = 3
```

**Linear Update:**
```
infrastructure-agent complete

Files:
- Makefile
- Dockerfile
- .github/workflows/ci.yml
- railway.toml

Ready for Phase 2
```

---

## Phase 2: Core (Parallel)

### Phase 2a: Auth Domain

**Agent:** domain-logic-agent

#### User Entity
```go
// app/internal/domain/entity/user.go
package entity

import "time"

type User struct {
    ID           string
    Email        string
    PasswordHash string
    CreatedAt    time.Time
}
```

#### Auth Port
```go
// app/internal/domain/port/output/user_repository.go
package output

type UserRepository interface {
    Create(ctx context.Context, user *entity.User) error
    GetByEmail(ctx context.Context, email string) (*entity.User, error)
    GetByID(ctx context.Context, id string) (*entity.User, error)
}
```

#### Auth Service
```go
// app/internal/domain/service/auth_service.go
package service

type AuthService struct {
    userRepo   output.UserRepository
    jwtSecret  string
    jwtExpiry  time.Duration
}

func (s *AuthService) Register(ctx context.Context, email, password string) (*entity.User, error)
func (s *AuthService) Login(ctx context.Context, email, password string) (string, error)
func (s *AuthService) ValidateToken(token string) (*Claims, error)
```

**Linear Update:**
```
domain-logic-agent complete

Files:
- app/internal/domain/entity/user.go
- app/internal/domain/port/output/user_repository.go
- app/internal/domain/service/auth_service.go
- app/internal/auth/jwt.go
```

---

### Phase 2b: Database (Supabase)

**Agent:** database-agent

#### Create Migration via Supabase MCP
```sql
-- Execute via supabase_execute_sql or migration tool
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
```

#### Verify via Supabase MCP
```
Commands:
- supabase_list_tables -> should show "users"
- supabase_execute_sql "SELECT COUNT(*) FROM users" -> should return 0
```

#### Repository Implementation
```go
// app/internal/adapter/driven/postgres/user_repo.go
package postgres

type UserRepository struct {
    pool *pgxpool.Pool
}

func NewUserRepository(pool *pgxpool.Pool) *UserRepository
func (r *UserRepository) Create(ctx context.Context, user *entity.User) error
func (r *UserRepository) GetByEmail(ctx context.Context, email string) (*entity.User, error)
func (r *UserRepository) GetByID(ctx context.Context, id string) (*entity.User, error)
```

**Linear Update:**
```
database-agent complete

Supabase:
- Migration applied via MCP
- Table "users" created
- RLS enabled

Files:
- app/migrations/001_users.up.sql
- app/internal/adapter/driven/postgres/connection.go
- app/internal/adapter/driven/postgres/user_repo.go
```

---

## Phase 3: API

**Agent:** api-adapter-agent

### Server Setup
```go
// app/internal/adapter/driving/http/server.go
package http

func NewServer(authService *service.AuthService) *echo.Echo {
    e := echo.New()

    e.Use(middleware.Logger())
    e.Use(middleware.Recover())
    e.Use(middleware.CORS())

    e.GET("/health", healthCheck)
    e.POST("/auth/register", register(authService))
    e.POST("/auth/login", login(authService))

    api := e.Group("/api/v1")
    api.Use(jwtMiddleware(authService))
    api.GET("/me", getMe)

    return e
}
```

**Linear Update:**
```
api-adapter-agent complete

Files:
- app/cmd/api/main.go
- app/internal/adapter/driving/http/server.go
- app/internal/adapter/driving/http/handlers.go
- app/internal/adapter/driving/http/dto.go
- app/internal/adapter/driving/http/middleware.go

Endpoints:
- GET  /health
- POST /auth/register
- POST /auth/login
- GET  /api/v1/me (protected)
```

---

## Phase 4: Deploy & Verify

**Agent:** infrastructure-agent

### 4.1 Set Railway Environment Variables
```
Using Railway MCP:
- railway_set_variable DATABASE_URL <supabase_connection_string>
- railway_set_variable JWT_SECRET <secure_random_string>
- railway_set_variable JWT_EXPIRY_HOURS 24
- railway_set_variable ENV production
```

### 4.2 Deploy to Railway
```
Using Railway MCP:
- railway_deploy
- railway_get_deployment_status
```

### 4.3 Verify Deployment
```bash
# Get deployment URL from Railway MCP
DEPLOY_URL=$(railway_get_service_url)

# Health check
curl $DEPLOY_URL/health

# Register test user
curl -X POST $DEPLOY_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Login
curl -X POST $DEPLOY_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### 4.4 Final Linear Update
```
infrastructure-agent complete

Railway Deployment:
- Service: {service_name}
- URL: {deployment_url}
- Status: ACTIVE

Verification:
- GET  /health -> 200 ✅
- POST /auth/register -> 201 ✅
- POST /auth/login -> 200 ✅
- GET  /api/v1/me -> 200 ✅

Epic Status: DONE
```

---

## MCP Command Reference

### Linear MCP
| Command | Description |
|---------|-------------|
| `linear_get_teams` | List available teams |
| `linear_get_labels` | List labels for filtering |
| `linear_create_issue` | Create new issue |
| `linear_update_issue` | Update issue status/fields |
| `linear_add_comment` | Add comment to issue |
| `linear_get_issue` | Get issue details |

### Supabase MCP
| Command | Description |
|---------|-------------|
| `supabase_list_projects` | List all projects |
| `supabase_get_project` | Get project details |
| `supabase_list_tables` | List database tables |
| `supabase_execute_sql` | Execute SQL query |
| `supabase_get_connection_string` | Get DB connection URL |

### Railway MCP
| Command | Description |
|---------|-------------|
| `railway_list_projects` | List all projects |
| `railway_get_project` | Get project details |
| `railway_list_services` | List services |
| `railway_deploy` | Trigger deployment |
| `railway_get_deployment_status` | Check deployment status |
| `railway_set_variable` | Set environment variable |
| `railway_get_service_url` | Get public URL |

---

## Timeline

```
Pre-flight ━━ MCP Integration Check (5 min)
00:00 ━━━━━━ Phase 0: Directory setup
00:10 ━━━━━━ Phase 1: Infrastructure
00:40 ━━━━━━ Phase 2: Domain + Database (parallel)
01:25 ━━━━━━ Phase 3: API
02:00 ━━━━━━ Phase 4: Deploy & Verify
02:15 ━━━━━━ API live and testable
```

**Total: ~2.5 hours**

---

## After Init: Add Your Features

The skeleton is ready. Use the orchestrator to add domain features:

```bash
@orchestrator "Implement Create Todo with priority via REST API"
```

Each feature follows the 4-phase workflow with Linear tracking.

---

## Troubleshooting

### MCP Connection Issues
```
Linear: Check LINEAR_API_KEY
Supabase: Check SUPABASE_URL, SUPABASE_KEY
Railway: Run `railway login` or check RAILWAY_TOKEN
```

### Database Connection Failed
```
# Via Supabase MCP
supabase_get_connection_string
# Verify the URL is correct in Railway variables
```

### Deployment Failed
```
# Check Railway logs via MCP
railway_get_logs

# Common issues:
# - Missing environment variables
# - Build failure (check Dockerfile)
# - Health check failing
```
