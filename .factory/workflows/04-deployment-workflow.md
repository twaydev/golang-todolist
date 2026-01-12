# Deployment Workflow

## Overview

This workflow describes the complete deployment process from local development to production using Railway with CI/CD automation.

---

## Deployment Stages

```
Local Development → Staging → Production
     ↓                ↓           ↓
  Unit Tests    Integration   Smoke Tests
                  Tests
```

---

## Prerequisites

### 1. Environment Setup

**Required Services**:
- GitHub repository
- Railway account
- Supabase project (database)
- Telegram Bot Token
- Perplexity API key

**Required Tools**:
```bash
# Install Railway CLI
npm install -g @railway/cli

# Install GitHub CLI (optional)
brew install gh

# Docker for local testing
brew install docker
```

---

## Step 1: Prepare for Deployment

### Agent: `@infrastructure-agent`

**Prompt**:
```
Prepare the application for Railway deployment.

Create:
1. Dockerfile (production-ready, multi-stage)
2. railway.toml (deployment configuration)
3. .github/workflows/deploy.yml
4. Health check endpoint
5. Graceful shutdown

Use skills:
- containerization/docker
- containerization/multi-stage-builds
- deployment/railway
- cicd/github-actions
```

**Expected Files**:

```dockerfile
# Dockerfile
FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-w -s" -o /bot cmd/bot/main.go

FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata

RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

WORKDIR /app

COPY --from=builder /bot /app/bot

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["/app/bot"]
```

```toml
# railway.toml
[build]
builder = "dockerfile"
dockerfilePath = "Dockerfile"

[deploy]
startCommand = "/app/bot"
healthcheckPath = "/health"
healthcheckTimeout = 30
restartPolicyType = "on_failure"
restartPolicyMaxRetries = 3
```

---

## Step 2: Local Testing

### Test Docker Build

```bash
# Build image
docker build -t telegram-todo-bot:test .

# Verify image size (should be < 20MB)
docker images telegram-todo-bot:test

# Test container locally
docker run --rm \
  -p 8080:8080 \
  -e DATABASE_URL="$DATABASE_URL" \
  -e TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN" \
  -e PERPLEXITY_API_KEY="$PERPLEXITY_API_KEY" \
  telegram-todo-bot:test

# Test health endpoint (in another terminal)
curl http://localhost:8080/health
# Expected: {"status":"ok"}

# Test API
curl -X POST http://localhost:8080/api/v1/todos \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test deployment"}'

# Stop container
docker stop $(docker ps -q --filter ancestor=telegram-todo-bot:test)
```

---

## Step 3: Setup Staging Environment

### Create Railway Project

```bash
# Login to Railway
railway login

# Create new project
railway init

# Link to GitHub repo
railway link

# Create staging environment
railway environment create staging
```

### Configure Environment Variables (Staging)

```bash
# Switch to staging
railway environment staging

# Set variables
railway variables set DATABASE_URL="postgresql://..."
railway variables set TELEGRAM_BOT_TOKEN="123456:ABC..."
railway variables set PERPLEXITY_API_KEY="pplx-..."
railway variables set GO_ENV="staging"
railway variables set LOG_LEVEL="debug"

# View all variables
railway variables
```

### Deploy to Staging

```bash
# Deploy current branch to staging
railway up

# View logs
railway logs --tail

# Open staging dashboard
railway open
```

### Verify Staging Deployment

```bash
# Get staging URL
railway domain

# Test health endpoint
curl https://your-app.railway.app/health

# Test API
curl -X POST https://your-app.railway.app/api/v1/todos \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Staging test"}'

# Test Telegram bot (send message to bot)
# Verify bot responds correctly
```

---

## Step 4: Setup Production Environment

### Create Production Environment

```bash
# Create production environment
railway environment create production

# Switch to production
railway environment production
```

### Configure Environment Variables (Production)

```bash
# Use PRODUCTION database (separate from staging!)
railway variables set DATABASE_URL="postgresql://prod..."
railway variables set TELEGRAM_BOT_TOKEN="789012:XYZ..."
railway variables set PERPLEXITY_API_KEY="pplx-..."
railway variables set GO_ENV="production"
railway variables set LOG_LEVEL="info"  # Less verbose in prod

# Optional: Set resource limits
railway variables set RAILWAY_HEALTHCHECK_TIMEOUT="30"
```

### Run Migrations on Production

```bash
# IMPORTANT: Test migrations on staging first!

# Connect to production database
psql "$PRODUCTION_DATABASE_URL"

# Run migrations
migrate -database "$PRODUCTION_DATABASE_URL" -path ./migrations up

# Verify tables
\dt

# Verify RLS enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname='public';

# Exit
\q
```

---

## Step 5: Setup CI/CD Pipeline

### Agent: `@infrastructure-agent`

**Create** `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Railway

on:
  push:
    branches:
      - main        # Production
      - develop     # Staging

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      
      - name: Run tests
        run: |
          go test ./... -v -coverprofile=coverage.out
          go tool cover -func=coverage.out
      
      - name: Lint
        uses: golangci/golangci-lint-action@v4
        with:
          version: latest

  deploy-staging:
    needs: test
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Railway CLI
        run: npm install -g @railway/cli
      
      - name: Deploy to Staging
        run: railway up --service telegram-todo-bot --environment staging
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN_STAGING }}

  deploy-production:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Railway CLI
        run: npm install -g @railway/cli
      
      - name: Deploy to Production
        run: railway up --service telegram-todo-bot --environment production
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN_PRODUCTION }}
      
      - name: Run Smoke Tests
        run: |
          sleep 30  # Wait for deployment
          curl -f https://your-production-url.railway.app/health || exit 1
```

### Setup GitHub Secrets

```bash
# Generate Railway tokens
railway whoami --token  # Copy staging token
railway whoami --token  # Copy production token

# Add to GitHub
gh secret set RAILWAY_TOKEN_STAGING
gh secret set RAILWAY_TOKEN_PRODUCTION

# Verify
gh secret list
```

---

## Step 6: Deploy to Production

### Pre-Deployment Checklist

- [ ] All tests pass locally
- [ ] Staging deployment successful
- [ ] Database migrations tested
- [ ] Environment variables configured
- [ ] Health check endpoint working
- [ ] Rollback plan ready
- [ ] Team notified

### Deploy

```bash
# Option 1: Via Git Push
git checkout main
git merge develop
git push origin main
# GitHub Actions automatically deploys

# Option 2: Manual Deploy
railway environment production
railway up

# Monitor deployment
railway logs --tail
```

### Post-Deployment Verification

```bash
# 1. Health check
curl https://prod.railway.app/health

# 2. API test
curl -X POST https://prod.railway.app/api/v1/todos \
  -H "Authorization: Bearer $PROD_TOKEN" \
  -d '{"title":"Production test"}'

# 3. Telegram bot test
# Send message to production bot
# Verify response

# 4. Check logs
railway logs --tail

# 5. Monitor metrics
railway status
```

---

## Step 7: Monitoring

### Setup Monitoring

```bash
# View logs
railway logs --tail

# View metrics
railway status

# Set up alerts (Railway dashboard)
# - High error rate
# - High memory usage
# - Health check failures
```

### Check Application Health

```go
// cmd/bot/main.go - Health check endpoint
func healthHandler(c echo.Context) error {
    // Check database
    if err := db.Ping(context.Background()); err != nil {
        return c.JSON(503, map[string]string{
            "status": "unhealthy",
            "database": "down",
        })
    }
    
    // Check Telegram API
    if _, err := bot.GetMe(); err != nil {
        return c.JSON(503, map[string]string{
            "status": "unhealthy",
            "telegram": "down",
        })
    }
    
    return c.JSON(200, map[string]string{
        "status": "ok",
        "version": "1.0.0",
        "uptime": time.Since(startTime).String(),
    })
}
```

---

## Rollback Procedures

### If Deployment Fails

**Option 1: Rollback via Railway Dashboard**
1. Go to Railway dashboard
2. Select "Deployments"
3. Click "Rollback" on previous working deployment

**Option 2: Rollback via Git**
```bash
# Revert the commit
git revert HEAD
git push origin main
# Auto-deploys previous version

# Or deploy specific commit
git checkout <previous-commit>
railway up
```

**Option 3: Quick Fix Forward**
```bash
# Fix the issue
git commit -m "hotfix: fix deployment issue"
git push origin main
# Auto-deploys fix
```

---

## Deployment Strategies

### Blue-Green Deployment

```bash
# Keep old version running
# Deploy new version to different service
railway service create telegram-todo-bot-v2

# Test new version
curl https://v2.railway.app/health

# Switch traffic (update DNS/proxy)
# Monitor for issues

# If good, decommission old version
# If bad, switch back to old version
```

### Canary Deployment

```bash
# Deploy to small % of users first
# Monitor metrics
# Gradually increase traffic
# Full rollout if stable
```

---

## Troubleshooting

### Deployment Fails

```bash
# Check build logs
railway logs --deployment <deployment-id>

# Common issues:
# 1. Dockerfile errors
docker build -t test . --progress=plain

# 2. Missing dependencies
go mod tidy
go mod verify

# 3. Environment variables
railway variables | grep DATABASE_URL
```

### Application Crashes After Deploy

```bash
# Check logs
railway logs --tail

# Common causes:
# 1. Database connection fails
# 2. Missing environment variables
# 3. Port binding issues (must listen on 0.0.0.0:$PORT)
```

### Health Check Fails

```bash
# Test health endpoint locally
curl http://localhost:8080/health

# Check health check configuration
cat railway.toml

# Adjust timeout if needed
railway variables set RAILWAY_HEALTHCHECK_TIMEOUT=60
```

---

## Best Practices

### Version Tagging

```bash
# Tag releases
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0

# Deploy specific version
git checkout v1.0.0
railway up
```

### Database Migrations

```bash
# Always test migrations on staging first
# Use reversible migrations (up + down)
# Backup before migration
# Run migrations before deploying new code
```

### Zero-Downtime Deployments

```bash
# Use graceful shutdown
# Keep old version running until new is healthy
# Use health checks
# Database migrations must be backward compatible
```

### Security

```bash
# Never commit secrets
# Use Railway environment variables
# Rotate secrets regularly
railway variables set TELEGRAM_BOT_TOKEN="new-token"

# Use HTTPS only
# Enable CORS properly
```

---

## Deployment Checklist

**Pre-Deploy**:
- [ ] All tests pass
- [ ] Code reviewed
- [ ] Staging tested
- [ ] Migrations ready
- [ ] Secrets configured
- [ ] Rollback plan ready

**Deploy**:
- [ ] Deploy to staging
- [ ] Run smoke tests
- [ ] Deploy to production
- [ ] Verify health checks
- [ ] Monitor logs
- [ ] Test key features

**Post-Deploy**:
- [ ] Application healthy
- [ ] No errors in logs
- [ ] Performance acceptable
- [ ] Team notified
- [ ] Documentation updated
- [ ] Tag release

---

## Success Metrics

After deployment:
- ✅ Health check returns 200
- ✅ API endpoints respond correctly
- ✅ Telegram bot works
- ✅ No errors in logs
- ✅ Response times < 200ms
- ✅ Database queries working
- ✅ Authentication working
- ✅ Natural language parsing working

---

## Deployment Schedule

**Staging**: Deploy on every merge to `develop` (automatic)

**Production**: 
- Deploy on merge to `main` (automatic)
- Schedule: Tuesday/Thursday afternoons (avoid Fridays!)
- Freeze: No deploys before weekends/holidays
