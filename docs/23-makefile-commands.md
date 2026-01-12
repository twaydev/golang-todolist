# Makefile Commands

## Overview

The `Makefile` provides convenient commands for building, testing, and deploying the application. All common development tasks are automated.

## Installation

No installation needed - `make` is included with most Unix-like systems.

```bash
# Verify make is installed
make --version
```

## Quick Reference

```bash
make help           # Show all available commands
make setup          # Initial project setup
make dev            # Run in development mode
make test           # Run all tests
make build          # Build production binary
make docker         # Build Docker image
make deploy         # Deploy to Railway
```

## Complete Makefile

```makefile
# Makefile for Telegram Todo Bot

# Variables
APP_NAME=telegram-todo-bot
VERSION=$(shell git describe --tags --always --dirty)
BUILD_TIME=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
LDFLAGS=-ldflags "-X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME) -w -s"

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod
BINARY_NAME=bot
BINARY_UNIX=$(BINARY_NAME)_unix

# Directories
BUILD_DIR=./build
CMD_DIR=./cmd/bot

.PHONY: help
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

##@ Development

.PHONY: setup
setup: ## Initial project setup
	@echo "Setting up project..."
	@$(GOGET) -v ./...
	@$(GOMOD) download
	@$(GOMOD) tidy
	@$(GOGET) -u github.com/cosmtrek/air@latest
	@$(GOGET) -u github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@$(GOGET) -u github.com/vektra/mockery/v2@latest
	@cp .env.example .env
	@echo "✅ Setup complete! Edit .env with your credentials."

.PHONY: deps
deps: ## Install/update dependencies
	@echo "Installing dependencies..."
	@$(GOGET) -v ./...
	@$(GOMOD) download
	@$(GOMOD) tidy
	@echo "✅ Dependencies installed"

.PHONY: dev
dev: ## Run in development mode with hot reload
	@echo "Starting development server with Air..."
	@air

.PHONY: run
run: ## Run the application
	@echo "Starting $(APP_NAME)..."
	@$(GOCMD) run $(CMD_DIR)/main.go

##@ Building

.PHONY: build
build: ## Build the binary
	@echo "Building $(APP_NAME)..."
	@mkdir -p $(BUILD_DIR)
	@$(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) -v $(CMD_DIR)/main.go
	@echo "✅ Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

.PHONY: build-linux
build-linux: ## Build for Linux
	@echo "Building for Linux..."
	@mkdir -p $(BUILD_DIR)
	@CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_UNIX) -v $(CMD_DIR)/main.go
	@echo "✅ Linux build complete: $(BUILD_DIR)/$(BINARY_UNIX)"

.PHONY: build-all
build-all: ## Build for all platforms
	@echo "Building for all platforms..."
	@mkdir -p $(BUILD_DIR)
	@CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64 -v $(CMD_DIR)/main.go
	@CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-amd64 -v $(CMD_DIR)/main.go
	@CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-arm64 -v $(CMD_DIR)/main.go
	@CGO_ENABLED=0 GOOS=windows GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-windows-amd64.exe -v $(CMD_DIR)/main.go
	@echo "✅ All platforms built"

.PHONY: clean
clean: ## Remove build artifacts
	@echo "Cleaning..."
	@$(GOCLEAN)
	@rm -rf $(BUILD_DIR)
	@rm -f coverage*.out
	@echo "✅ Clean complete"

##@ Testing

.PHONY: test
test: ## Run all tests
	@echo "Running all tests..."
	@$(GOTEST) -v -race -coverprofile=coverage.out ./...
	@echo "✅ Tests complete"

.PHONY: test-unit
test-unit: ## Run unit tests only
	@echo "Running unit tests..."
	@$(GOTEST) -v -race -coverprofile=coverage-unit.out ./internal/...
	@echo "✅ Unit tests complete"

.PHONY: test-bdd
test-bdd: ## Run BDD tests (Godog)
	@echo "Running BDD tests..."
	@$(GOTEST) -v -coverprofile=coverage-bdd.out ./test/bdd/...
	@echo "✅ BDD tests complete"

.PHONY: test-integration
test-integration: ## Run integration tests
	@echo "Running integration tests..."
	@$(GOTEST) -v -coverprofile=coverage-integration.out ./test/integration/...
	@echo "✅ Integration tests complete"

.PHONY: test-coverage
test-coverage: test ## Run tests and show coverage
	@echo "Generating coverage report..."
	@$(GOCMD) tool cover -html=coverage.out -o coverage.html
	@echo "✅ Coverage report: coverage.html"
	@$(GOCMD) tool cover -func=coverage.out

.PHONY: test-watch
test-watch: ## Run tests in watch mode
	@echo "Watching tests..."
	@gotestsum --watch -- -v ./...

##@ Code Quality

.PHONY: lint
lint: ## Run linters
	@echo "Running linters..."
	@golangci-lint run --timeout=5m
	@echo "✅ Linting complete"

.PHONY: lint-fix
lint-fix: ## Run linters and auto-fix issues
	@echo "Running linters with auto-fix..."
	@golangci-lint run --fix --timeout=5m
	@echo "✅ Linting and fixes complete"

.PHONY: fmt
fmt: ## Format code
	@echo "Formatting code..."
	@gofmt -w -s .
	@goimports -w .
	@echo "✅ Formatting complete"

.PHONY: vet
vet: ## Run go vet
	@echo "Running go vet..."
	@$(GOCMD) vet ./...
	@echo "✅ Vet complete"

.PHONY: check
check: fmt vet lint test ## Run all checks (fmt, vet, lint, test)
	@echo "✅ All checks passed"

##@ Code Generation

.PHONY: mocks
mocks: ## Generate mocks
	@echo "Generating mocks..."
	@mockery --all --dir=internal/domain/port/output --output=test/mocks --case=underscore
	@echo "✅ Mocks generated"

.PHONY: generate
generate: mocks ## Run all code generation
	@echo "Running code generation..."
	@$(GOCMD) generate ./...
	@echo "✅ Generation complete"

##@ Database

.PHONY: db-reset
db-reset: ## Reset local database
	@echo "Resetting database..."
	@supabase db reset
	@echo "✅ Database reset"

.PHONY: db-migrate
db-migrate: ## Run database migrations
	@echo "Running migrations..."
	@supabase db push
	@echo "✅ Migrations applied"

.PHONY: db-migration-new
db-migration-new: ## Create new migration (usage: make db-migration-new NAME=add_feature)
	@echo "Creating new migration: $(NAME)"
	@supabase migration new $(NAME)
	@echo "✅ Migration created: migrations/$(shell ls -t migrations/ | head -1)"

##@ Docker

.PHONY: docker-build
docker-build: ## Build Docker image
	@echo "Building Docker image..."
	@docker build -t $(APP_NAME):$(VERSION) .
	@docker tag $(APP_NAME):$(VERSION) $(APP_NAME):latest
	@echo "✅ Docker image built: $(APP_NAME):$(VERSION)"

.PHONY: docker-run
docker-run: ## Run Docker container
	@echo "Running Docker container..."
	@docker run --rm --env-file .env -p 8080:8080 $(APP_NAME):latest

.PHONY: docker-push
docker-push: ## Push Docker image to registry
	@echo "Pushing Docker image..."
	@docker push $(APP_NAME):$(VERSION)
	@docker push $(APP_NAME):latest
	@echo "✅ Docker image pushed"

##@ Deployment

.PHONY: deploy
deploy: ## Deploy to Railway
	@echo "Deploying to Railway..."
	@railway up
	@echo "✅ Deployed to Railway"

.PHONY: deploy-staging
deploy-staging: ## Deploy to staging environment
	@echo "Deploying to staging..."
	@railway up --service staging
	@echo "✅ Deployed to staging"

.PHONY: deploy-prod
deploy-prod: ## Deploy to production
	@echo "Deploying to production..."
	@railway up --service production
	@echo "✅ Deployed to production"

.PHONY: logs
logs: ## View Railway logs
	@railway logs

##@ Utilities

.PHONY: version
version: ## Show version information
	@echo "Version: $(VERSION)"
	@echo "Build Time: $(BUILD_TIME)"

.PHONY: install
install: build ## Install binary to $GOPATH/bin
	@echo "Installing $(APP_NAME)..."
	@cp $(BUILD_DIR)/$(BINARY_NAME) $(GOPATH)/bin/$(APP_NAME)
	@echo "✅ Installed to $(GOPATH)/bin/$(APP_NAME)"

.PHONY: uninstall
uninstall: ## Uninstall binary from $GOPATH/bin
	@echo "Uninstalling $(APP_NAME)..."
	@rm -f $(GOPATH)/bin/$(APP_NAME)
	@echo "✅ Uninstalled"

.PHONY: todo
todo: ## Show TODOs in code
	@echo "TODOs in code:"
	@grep -r "TODO" --include="*.go" . || echo "No TODOs found"

.PHONY: tree
tree: ## Show project structure
	@tree -I 'vendor|node_modules|build|tmp' -L 3

##@ CI/CD

.PHONY: ci
ci: lint test build ## Run CI pipeline locally
	@echo "✅ CI pipeline complete"

.PHONY: pre-commit
pre-commit: fmt lint test-unit ## Run pre-commit checks
	@echo "✅ Pre-commit checks passed"
```

## Common Workflows

### Initial Setup

```bash
# 1. Clone repository
git clone https://github.com/your-org/golang-todolist.git
cd golang-todolist

# 2. Setup project
make setup

# 3. Edit .env with your credentials
vim .env

# 4. Run in development mode
make dev
```

### Development Workflow

```bash
# Start development server with hot reload
make dev

# In another terminal, run tests on file changes
make test-watch

# Format code before committing
make fmt

# Run all pre-commit checks
make pre-commit
```

### Testing Workflow

```bash
# Run all tests
make test

# Run specific test suites
make test-unit
make test-bdd
make test-integration

# Generate coverage report
make test-coverage
# Opens coverage.html in browser
```

### Building & Deployment

```bash
# Build for current platform
make build

# Build for Linux (for Railway)
make build-linux

# Build Docker image
make docker-build

# Deploy to Railway
make deploy
```

### Code Quality

```bash
# Format code
make fmt

# Run linter
make lint

# Auto-fix linting issues
make lint-fix

# Run all checks
make check
```

### Database Operations

```bash
# Create new migration
make db-migration-new NAME=add_user_avatars

# Run migrations locally
make db-reset

# Push migrations to production
make db-migrate
```

## Environment-Specific Commands

### Development

```bash
# Use development .env
cp .env.example .env.development

# Run with development config
ENV_FILE=.env.development make dev
```

### Staging

```bash
# Deploy to staging
make deploy-staging

# View staging logs
railway logs --service staging
```

### Production

```bash
# Deploy to production (requires confirmation)
make deploy-prod

# View production logs
railway logs --service production
```

## Troubleshooting

### "command not found: air"

```bash
# Install air for hot reload
go install github.com/cosmtrek/air@latest

# Or use go run instead
make run
```

### "command not found: golangci-lint"

```bash
# Install golangci-lint
brew install golangci-lint  # macOS
# or
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

### "command not found: mockery"

```bash
# Install mockery
go install github.com/vektra/mockery/v2@latest
```

### Tests failing

```bash
# Clean and rebuild
make clean
make deps
make test
```

## Advanced Usage

### Custom Build Flags

```bash
# Build with custom flags
LDFLAGS="-X main.Environment=production" make build
```

### Parallel Testing

```bash
# Run tests in parallel
go test -v -race -parallel 4 ./...
```

### Coverage Threshold

```bash
# Fail if coverage is below 80%
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out | grep total | awk '{if ($3 < 80.0) exit 1}'
```

## Integration with CI/CD

### GitHub Actions

```yaml
# .github/workflows/ci.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - run: make ci
```

### Pre-commit Hook

```bash
# .git/hooks/pre-commit
#!/bin/sh
make pre-commit
```

## Next Steps

- See [CI/CD Pipeline](16-cicd-pipeline.md) for automated workflows
- Review [Testing Strategy](05-testing-strategy.md) for test commands
- Read [Configuration](17-configuration.md) for environment setup
