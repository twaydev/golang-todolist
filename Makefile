.PHONY: dev run build test lint docker-build deploy clean

# Development (uses Docker Compose for full stack)
dev:
	@echo "Starting development environment with Docker Compose..."
	docker compose up -d db migrate api
	@echo "Development server running at http://localhost:8080"
	@echo "Use 'make logs' to view logs, 'make down' to stop"

run: dev

# Build
build:
	@echo "Building binary..."
	go build -o bin/api app/cmd/api/main.go

# Test (via Docker Compose)
test:
	@echo "Running all tests via Docker..."
	docker compose up --build --abort-on-container-exit test-bdd

test-unit:
	@echo "Running unit tests via Docker..."
	docker compose run --rm test-bdd sh -c "go test ./app/internal/... -v -cover"

test-bdd:
	@echo "Running BDD tests via Docker..."
	docker compose up --build --abort-on-container-exit test-bdd

test-integration:
	@echo "Running integration tests via Docker..."
	docker compose up --build --abort-on-container-exit test

# Lint
lint:
	golangci-lint run ./app/...

# Docker
docker-build:
	docker build -t golang-todolist .

docker-run:
	docker run -p 8080:8080 --env-file .env golang-todolist

# Docker Compose (Local Development)
up:
	docker compose up -d db migrate api

down:
	docker compose down

up-all:
	docker compose up --build

up-db:
	docker compose up -d db

logs:
	docker compose logs -f api

logs-db:
	docker compose logs -f db

ps:
	docker compose ps

test-docker:
	docker compose up --build --abort-on-container-exit test

restart:
	docker compose down && docker compose up -d db migrate api

# Database
db-migrate:
	@echo "Running migrations..."
	migrate -database "$(DATABASE_URL)" -path app/migrations up

db-migrate-down:
	migrate -database "$(DATABASE_URL)" -path app/migrations down 1

# Deploy
deploy:
	railway up

# Clean
clean:
	rm -rf bin/
	go clean

# Dependencies
deps:
	go mod download
	go mod tidy
