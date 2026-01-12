# CI/CD Pipeline

## Overview

The project uses **GitHub Actions** for continuous integration and deployment to **Railway**. The pipeline includes linting, testing (unit + BDD), building, and automated deployment.

**Key Components**:
- ✅ GitHub Actions for CI/CD
- ✅ Docker multi-stage builds
- ✅ Railway for hosting
- ✅ Supabase for database
- ✅ Codecov for coverage tracking

## GitHub Actions Workflows

### 1. Continuous Integration (ci.yml)

Runs on every push and pull request.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Run golangci-lint
        uses: golangci/golangci-lint-action@v4
        with:
          version: latest
          args: --timeout=5m

  unit-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Install dependencies
        run: go mod download

      - name: Run unit tests
        run: go test -v -race -coverprofile=coverage-unit.out ./internal/...

      - name: Upload unit coverage
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage-unit.out
          flags: unit
          token: ${{ secrets.CODECOV_TOKEN }}

  bdd-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Install dependencies
        run: go mod download

      - name: Run BDD tests (Godog)
        run: go test -v -coverprofile=coverage-bdd.out ./test/bdd/...

      - name: Upload BDD coverage
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage-bdd.out
          flags: bdd
          token: ${{ secrets.CODECOV_TOKEN }}

  integration-test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: todobot_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Install dependencies
        run: go mod download

      - name: Run migrations
        run: |
          PGPASSWORD=postgres psql -h localhost -U postgres -d todobot_test -f migrations/001_initial.sql
        env:
          PGPASSWORD: postgres

      - name: Run integration tests
        run: go test -v -coverprofile=coverage-integration.out ./test/integration/...
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/todobot_test?sslmode=disable

      - name: Upload integration coverage
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage-integration.out
          flags: integration
          token: ${{ secrets.CODECOV_TOKEN }}

  build:
    runs-on: ubuntu-latest
    needs: [lint, unit-test, bdd-test, integration-test]
    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Build binary
        run: CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bot cmd/bot/main.go

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: bot-binary
          path: bot
          retention-days: 7

  docker-build:
    runs-on: ubuntu-latest
    needs: [lint, unit-test, bdd-test]
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: false
          tags: telegram-todo-bot:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### 2. Deployment (deploy.yml)

Runs on push to main branch.

```yaml
# .github/workflows/deploy.yml
name: Deploy to Railway

on:
  push:
    branches: [main]
  workflow_dispatch:  # Allow manual trigger

jobs:
  # Run CI first
  ci:
    uses: ./.github/workflows/ci.yml

  deploy:
    runs-on: ubuntu-latest
    needs: [ci]
    steps:
      - uses: actions/checkout@v4

      - name: Install Railway CLI
        run: npm install -g @railway/cli

      - name: Deploy to Railway
        run: railway up --service telegram-todo-bot
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}

      - name: Get deployment URL
        run: railway status
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}

      - name: Notify deployment
        if: success()
        run: |
          echo "🚀 Deployment successful!"
          echo "Commit: ${{ github.sha }}"
          echo "Branch: ${{ github.ref_name }}"
```

### 3. Scheduled Tests (scheduled.yml)

Optional: Run tests daily to catch environment issues.

```yaml
# .github/workflows/scheduled.yml
name: Scheduled Tests

on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight UTC
  workflow_dispatch:

jobs:
  test:
    uses: ./.github/workflows/ci.yml
```

## Deployment Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         GITHUB REPOSITORY                               │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
            ┌────────────────────┴────────────────────┐
            │                                         │
            ▼                                         ▼
    ┌───────────────┐                        ┌───────────────┐
    │  Pull Request │                        │  Push to main │
    └───────┬───────┘                        └───────┬───────┘
            │                                         │
            ▼                                         ▼
    ┌───────────────┐                        ┌───────────────┐
    │    ci.yml     │                        │  deploy.yml   │
    │  - Lint       │                        │  - Run CI     │
    │  - Unit Test  │                        │  - Railway up │
    │  - BDD Test   │                        └───────┬───────┘
    │  - Build      │                                │
    └───────────────┘                                ▼
                                            ┌───────────────┐
                                            │    RAILWAY    │
                                            │  - Build      │
                                            │  - Deploy     │
                                            │  - Run Bot    │
                                            └───────────────┘
```

## Docker Configuration

### Dockerfile

Multi-stage build for optimal image size.

```dockerfile
# Dockerfile
FROM golang:1.22-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /bot \
    cmd/bot/main.go

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk --no-cache add ca-certificates tzdata

# Copy binary from builder
COPY --from=builder /bot /bot

# Copy templates if any
COPY --from=builder /app/templates /templates

# Expose port (for health checks)
EXPOSE 8080

# Run as non-root user
RUN adduser -D -u 1000 botuser
USER botuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run bot
CMD ["/bot"]
```

### .dockerignore

```
# .dockerignore
.git
.github
.vscode
*.md
.env
.env.*
test/
docs/
.air.toml
tmp/
coverage*.out
*.log
```

## Railway Configuration

### railway.toml

```toml
[build]
builder = "dockerfile"
dockerfilePath = "Dockerfile"

[deploy]
startCommand = "/bot"
healthcheckPath = "/health"
healthcheckTimeout = 30
restartPolicyType = "on_failure"
restartPolicyMaxRetries = 3

[env]
# Environment variables are set in Railway dashboard
```

### Railway Setup Steps

1. **Create Railway Account**: https://railway.app
2. **Create New Project**: "New Project" → "Deploy from GitHub repo"
3. **Connect Repository**: Select `golang-todolist` repository
4. **Add Environment Variables**:
   - `TELEGRAM_BOT_TOKEN`
   - `DATABASE_URL` (from Supabase)
   - `PERPLEXITY_API_KEY`
   - `DEFAULT_LANGUAGE=en`
   - `PORT=8080`

5. **Configure Deployment**:
   - Build method: Dockerfile
   - Start command: `/bot`
   - Health check: `/health` endpoint

6. **Get Railway Token** (for GitHub Actions):
   - Go to Account Settings → Tokens
   - Create new token
   - Add to GitHub Secrets as `RAILWAY_TOKEN`

## Database Migrations (Supabase)

### Migration Workflow

```bash
# 1. Create new migration
supabase migration new add_feature_name

# 2. Edit migration file
# migrations/002_add_feature_name.sql

# 3. Test locally
supabase db reset  # Resets local DB and applies all migrations

# 4. Push to production
supabase db push --db-url "$DATABASE_URL"
```

### Supabase CLI Setup

```bash
# Install Supabase CLI
brew install supabase/tap/supabase  # macOS
# or
npm install -g supabase             # Cross-platform

# Login
supabase login

# Link to project
supabase link --project-ref your-project-ref

# Pull current schema
supabase db pull
```

## Secrets Configuration

### GitHub Secrets

Add these in GitHub repository: **Settings → Secrets and variables → Actions**

| Secret | Description | How to get |
|--------|-------------|------------|
| `RAILWAY_TOKEN` | Railway API token | Railway Account → Tokens |
| `CODECOV_TOKEN` | Codecov upload token | Codecov.io project settings |

### Railway Environment Variables

Add these in Railway project: **Project → Variables**

| Variable | Description | Example |
|----------|-------------|---------|
| `TELEGRAM_BOT_TOKEN` | Telegram Bot API token | `1234567890:ABCdef...` |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host:5432/db` |
| `PERPLEXITY_API_KEY` | Perplexity AI API key | `pplx-...` |
| `DEFAULT_LANGUAGE` | Default user language | `en` |
| `PORT` | Server port | `8080` |

### Getting Credentials

#### 1. Telegram Bot Token
```bash
# Talk to @BotFather on Telegram
/newbot
# Follow instructions
# Copy the token
```

#### 2. Supabase Database URL
```bash
# Go to Supabase Dashboard
# Project Settings → Database → Connection string
# Copy "URI" format
# Format: postgresql://postgres:[password]@[host]:5432/postgres
```

#### 3. Perplexity API Key
```bash
# Go to https://www.perplexity.ai/settings/api
# Create API key
# Copy key (starts with pplx-)
```

## Monitoring & Logging

### Railway Logs

```bash
# View logs via CLI
railway logs --service telegram-todo-bot

# Or view in dashboard
# Railway Project → Deployments → Logs
```

### Health Check Endpoint

```go
// internal/adapter/driving/http/health.go
func (s *Server) healthCheck(c echo.Context) error {
    return c.JSON(http.StatusOK, map[string]string{
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": time.Now().Format(time.RFC3339),
    })
}
```

## Testing the Pipeline

### Local Testing

```bash
# Run all tests locally
make test

# Run specific test suites
make test-unit
make test-bdd
make test-integration

# Test Docker build
docker build -t telegram-todo-bot:test .
docker run --rm telegram-todo-bot:test
```

### Manual Deployment

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Link to project
railway link

# Deploy manually
railway up
```

## Rollback Strategy

### Automatic Rollback

Railway automatically rolls back if health checks fail after deployment.

### Manual Rollback

```bash
# Via Railway dashboard
# Project → Deployments → Select previous deployment → Redeploy

# Via CLI
railway rollback
```

## Performance Optimization

1. **Docker Layer Caching**: Use GitHub Actions cache
2. **Parallel Jobs**: Run tests in parallel
3. **Conditional Deployment**: Only deploy on main branch
4. **Artifact Caching**: Cache Go modules between runs

## Best Practices

1. ✅ **Always run tests before deploy**
2. ✅ **Use semantic versioning for tags**
3. ✅ **Monitor deployment logs**
4. ✅ **Set up alerts for failures**
5. ✅ **Keep secrets secure** (never commit)
6. ✅ **Use environment-specific configs**
7. ✅ **Document deployment process**

## Troubleshooting

### Build Fails
```bash
# Check logs in GitHub Actions
# Verify Go version matches (1.22)
# Ensure all dependencies are available
```

### Deployment Fails
```bash
# Check Railway logs
railway logs --service telegram-todo-bot

# Verify environment variables
railway variables

# Check health endpoint
curl https://your-app.railway.app/health
```

### Database Migration Issues
```bash
# Check migration status
supabase migration list

# Repair migration
supabase db push --db-url "$DATABASE_URL" --force
```

## Next Steps

- See [Configuration](17-configuration.md) for environment variables
- Review [Database Schema](15-database-schema.md) for migrations
- Read [Makefile Commands](23-makefile-commands.md) for build scripts
