# Directory Structure

This document describes the project's directory organization following Hexagonal Architecture principles.

## Complete Directory Tree

```
the-private-todolist/
├── cmd/
│   └── bot/
│       └── main.go                   # Entry point, dependency injection
│
├── internal/
│   │
│   ├── domain/                       # CORE DOMAIN (no external dependencies)
│   │   ├── entity/
│   │   │   ├── todo.go               # Todo entity + business rules
│   │   │   ├── user.go               # User entity + preferences
│   │   │   └── intent.go             # ParsedIntent value object
│   │   ├── service/
│   │   │   ├── todo_service.go       # Todo application service
│   │   │   ├── user_service.go       # User application service
│   │   │   └── intent_service.go     # Intent processing service
│   │   └── port/
│   │       ├── input/                # INPUT PORTS (driving)
│   │       │   ├── message_handler.go
│   │       │   ├── command_handler.go
│   │       │   └── http_handler.go
│   │       └── output/               # OUTPUT PORTS (driven)
│   │           ├── todo_repository.go
│   │           ├── user_repository.go
│   │           ├── intent_analyzer.go
│   │           └── notifier.go
│   │
│   ├── adapter/                      # ADAPTERS (infrastructure)
│   │   ├── driving/                  # PRIMARY ADAPTERS (input)
│   │   │   ├── telegram/
│   │   │   │   ├── bot.go            # Telebot setup
│   │   │   │   ├── handlers.go       # Command handlers
│   │   │   │   └── mapper.go         # DTO <-> Domain mapping
│   │   │   └── http/
│   │   │       ├── server.go         # Echo server setup
│   │   │       ├── routes.go         # Route definitions
│   │   │       ├── handlers.go       # HTTP handlers
│   │   │       ├── middleware.go     # Auth, CORS, logging
│   │   │       └── dto.go            # Request/Response DTOs
│   │   └── driven/                   # SECONDARY ADAPTERS (output)
│   │       ├── postgres/
│   │       │   ├── connection.go     # pgx pool setup
│   │       │   ├── todo_repo.go      # TodoRepository impl
│   │       │   └── user_repo.go      # UserRepository impl
│   │       ├── perplexity/
│   │       │   └── client.go         # IntentAnalyzer impl
│   │       └── memory/               # In-memory adapters for testing
│   │           ├── todo_repo.go
│   │           └── user_repo.go
│   │
│   ├── config/
│   │   └── config.go                 # Environment configuration
│   │
│   └── i18n/
│       ├── i18n.go                   # Translation helper
│       ├── en.go                     # English strings
│       └── vi.go                     # Vietnamese strings
│
├── features/                         # BDD FEATURE FILES
│   ├── todo_create.feature
│   ├── todo_list.feature
│   ├── todo_complete.feature
│   ├── todo_update.feature
│   ├── todo_delete.feature
│   ├── language_switch.feature
│   └── timezone.feature
│
├── test/
│   ├── bdd/                          # BDD step definitions
│   │   ├── todo_steps_test.go
│   │   ├── user_steps_test.go
│   │   └── main_test.go              # Godog test runner
│   ├── unit/                         # Unit tests
│   │   ├── domain/
│   │   │   ├── todo_service_test.go
│   │   │   └── intent_service_test.go
│   │   └── adapter/
│   │       └── postgres_test.go
│   ├── integration/                  # Integration tests
│   │   └── telegram_test.go
│   └── mocks/                        # Generated mocks (mockery)
│       ├── mock_todo_repository.go
│       ├── mock_user_repository.go
│       └── mock_intent_analyzer.go
│
├── migrations/
│   └── 001_initial.sql               # Database migrations
│
├── templates/                        # GLOBAL TEMPLATES (shipped with bot)
│   ├── daily-standup.yaml
│   ├── weekly-review.yaml
│   ├── bug-fix.yaml
│   └── meeting-notes.yaml
│
├── docs/                             # Documentation
│   ├── README.md
│   ├── 01-architecture-overview.md
│   ├── 02-directory-structure.md
│   └── ...
│
├── .github/
│   └── workflows/
│       ├── ci.yml                    # Test & lint (includes BDD)
│       └── deploy.yml                # Deploy to Railway
│
├── Dockerfile
├── go.mod
├── go.sum
├── railway.toml
├── Makefile                          # Build, test, generate commands
└── README.md
```

## Directory Descriptions

### `cmd/`
Entry points for applications. Contains `main.go` with dependency injection and application bootstrapping.

### `internal/domain/`
**Pure business logic - NO external dependencies allowed.**

- `entity/` - Domain entities with business rules and validation
- `service/` - Application services that orchestrate use cases
- `port/input/` - Interfaces for driving adapters (how external world calls us)
- `port/output/` - Interfaces for driven adapters (how we call external systems)

### `internal/adapter/`
**Infrastructure code - implements ports.**

- `driving/telegram/` - Telegram bot adapter (input)
- `driving/http/` - Echo REST API adapter (input)
- `driven/postgres/` - PostgreSQL repository adapter (output)
- `driven/perplexity/` - AI intent analyzer adapter (output)
- `driven/memory/` - In-memory adapters for testing (output)

### `internal/config/`
Configuration management (environment variables, settings).

### `internal/i18n/`
Internationalization support for English and Vietnamese.

### `features/`
BDD feature files in Gherkin syntax. These define acceptance criteria and are written FIRST.

### `test/`
All test code:
- `bdd/` - Godog step definitions
- `unit/` - Unit tests with mocks
- `integration/` - Integration tests with real dependencies
- `mocks/` - Auto-generated mocks (via mockery)

### `migrations/`
Database migration SQL files.

### `templates/`
Global task templates (YAML files) shipped with the application.

### `docs/`
Comprehensive documentation split into focused topics.

### `.github/workflows/`
CI/CD pipeline definitions.

## Dependency Rules

```
┌─────────────────────────────────────────────────┐
│  Dependency Flow (arrows show allowed imports)  │
└─────────────────────────────────────────────────┘

cmd/ ──────────────┐
                   ↓
internal/adapter/ ─────→ internal/domain/
                         (implements ports)
       ↓                        ↑
       ↓                        ↑
external systems          NO external deps!
(DB, APIs, etc.)
```

**Key Rules:**
1. `internal/domain/` NEVER imports from `internal/adapter/`
2. `internal/domain/` NEVER imports external libraries (except stdlib)
3. `internal/adapter/` imports and implements `internal/domain/port/` interfaces
4. `cmd/` wires everything together via dependency injection

## File Naming Conventions

- `*_test.go` - Test files (unit or integration)
- `*_steps_test.go` - BDD step definitions
- `*.feature` - Gherkin feature files
- `*_repo.go` - Repository implementations
- `*.sql` - Database migrations
- `*.yaml` / `*.yml` - Configuration or template files

## Next Steps

- See [Hexagonal Architecture](03-hexagonal-architecture.md) for detailed layer responsibilities
- Read [Port Interfaces](08-port-interfaces.md) for interface definitions
