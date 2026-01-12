# Agent Specifications

This document provides detailed specifications for each specialized agent, including skills, tools, workflows, and example prompts.

## Agent 1: Test-First Agent (BDD/TDD Specialist)

### Primary Responsibility
Write feature files and test definitions BEFORE any implementation code is written.

### Skills Required
- `godog` (BDD framework for Go)
- `testify` (assertion library)
- `mockery` (mock generation)
- Gherkin syntax and BDD methodology
- Test-driven development (TDD)
- Test design patterns

### AI Model Recommendation
- **Primary**: Claude 3.5 Sonnet (excellent at structured thinking and test design)
- **Alternative**: GPT-4o (good at generating test scenarios)
- **Reasoning**: Claude excels at systematic thinking and creating comprehensive test scenarios

### Tools & Context

```yaml
skills:
  - testing/godog
  - testing/testify
  - mocking/mockery
  - bdd/gherkin
  
context_files:
  - features/*.feature
  - test/bdd/*_steps_test.go
  - test/unit/**/*_test.go
  - docs/04-tdd-bdd-workflow.md
  - docs/05-testing-strategy.md
  
workflows:
  1. Read requirements/user stories
  2. Write feature files in Gherkin
  3. Generate step definition stubs
  4. Write unit test stubs
  5. Verify tests fail (RED state)
  6. Report test status to orchestrator
```

### Example Prompt

```
You are a Test-First Development specialist. Your role is to write comprehensive 
BDD feature files and TDD unit tests BEFORE any implementation code is written.

Task: Create BDD scenarios for the "Create Todo via REST API" feature.

Requirements:
1. Write feature file with multiple scenarios covering:
   - Success cases (happy path)
   - Validation errors (empty title, invalid priority)
   - Business rule violations (duplicate codes, max length)
   - Edge cases (special characters, unicode, very long text)
   - Concurrent access scenarios

2. Include background setup and test data:
   - Given conditions (user exists, API is running)
   - Test fixtures (sample todos, users)
   - Authentication setup

3. Generate step definition stubs:
   - Create test context struct
   - Implement step functions (return stub errors)
   - Add helper functions for common operations

4. Write corresponding unit tests for domain service:
   - Test TodoService.CreateTodo with mocks
   - Test entity validation
   - Test error conditions
   - Use Arrange-Act-Assert pattern

5. Ensure all tests fail initially (RED state):
   - Run godog and verify failures
   - Run unit tests and verify failures
   - Document expected failures

Focus on:
- Edge cases and boundary conditions
- Validation errors with specific messages
- Business rule violations
- Concurrent access and race conditions
- Security concerns (injection, XSS in title/description)

Output:
- features/todo_create.feature
- test/bdd/todo_steps_test.go
- test/unit/domain/todo_service_test.go
- Test execution report showing RED state
```

### Checkpoint Criteria
- ✅ Feature file written with concrete scenarios
- ✅ Step definitions created (stubbed)
- ✅ Unit tests written with mocks
- ✅ All tests execute and FAIL (RED state)
- ✅ No implementation code exists yet

---

## Agent 2: Domain Logic Agent (Business Logic Specialist)

### Primary Responsibility
Implement core business logic, entities, and application services while maintaining hexagonal architecture principles.

### Skills Required
- Go programming (interfaces, structs, methods)
- Domain-Driven Design (DDD)
- Clean Architecture / Hexagonal Architecture
- Business logic implementation
- Error handling patterns
- SOLID principles

### AI Model Recommendation
- **Primary**: Claude 3.5 Sonnet (strong logical reasoning and architecture adherence)
- **Alternative**: o1-preview (excellent for complex business logic)
- **Reasoning**: Claude maintains architectural boundaries well and produces clean, idiomatic Go code

### Tools & Context

```yaml
skills:
  - golang/interfaces
  - design-patterns/hexagonal-architecture
  - domain-driven-design
  - golang/error-handling
  
context_files:
  - internal/domain/entity/*.go
  - internal/domain/service/*.go
  - internal/domain/port/**/*.go
  - test/unit/domain/*_test.go
  - docs/03-hexagonal-architecture.md
  - docs/06-domain-entities.md
  - docs/07-domain-services.md
  
workflows:
  1. Read failing unit tests
  2. Define domain entities with business rules
  3. Define port interfaces (contracts)
  4. Implement application services
  5. Ensure tests pass (GREEN state)
  6. Refactor for clarity and performance
```

### Example Prompt

```
You are a Domain-Driven Design specialist implementing business logic in Go.

Context: 
- Feature: Create Todo with priority, due dates, and validation
- Tests: test/unit/domain/todo_service_test.go (currently FAILING)
- Architecture: Hexagonal Architecture (no infrastructure dependencies allowed)
- Existing: User entity, UserRepository port

Task:
1. Implement entity.Todo with business rules:
   - Validation: title required (1-500 chars), valid priority, valid status
   - State transitions: pending → in_progress → completed
   - Business rules: 
     * Cannot complete a todo with future due date without confirmation
     * Cannot delete a todo in progress without archive
     * Auto-generate code in format YY-NNNN
   - Methods: Validate(), MarkComplete(), IsOverdue(), UpdatePriority()

2. Define port interfaces in internal/domain/port/output/:
   - TodoRepository: Create, Update, Delete, GetByID, GetByCode, List, Search
   - IntentAnalyzer: Analyze(message, existingTodos, lang) -> ParsedIntent
   - Notifier: SendNotification(userID, message)
   
3. Implement service.TodoService:
   - Constructor with dependency injection (receive ports)
   - CreateTodo(ctx, userID, title, options) -> (*Todo, error)
   - UpdateTodo(ctx, userID, todoID, updates) -> (*Todo, error)
   - CompleteTodo(ctx, userID, todoID) -> error
   - ListTodos(ctx, userID, filters) -> ([]*Todo, error)
   - Business logic orchestration (call repositories, enforce rules)

4. Make all tests pass while maintaining clean architecture principles:
   - No database code in domain layer
   - All external dependencies via interfaces (ports)
   - Comprehensive error handling with custom error types
   - Follow Go idioms (accept interfaces, return structs)

Constraints:
- NO imports from internal/adapter/ or any infrastructure packages
- NO database, HTTP, or third-party library imports
- Only stdlib and domain packages allowed
- All business rules must be testable in isolation
- Errors must be descriptive and actionable

Output:
- internal/domain/entity/todo.go
- internal/domain/entity/priority.go
- internal/domain/entity/status.go
- internal/domain/port/output/todo_repository.go
- internal/domain/port/output/intent_analyzer.go
- internal/domain/service/todo_service.go
- Test execution report showing GREEN state
```

### Checkpoint Criteria
- ✅ Entities implemented with business rules
- ✅ Port interfaces defined
- ✅ Services implemented
- ✅ All unit tests PASS (GREEN state)
- ✅ No infrastructure dependencies
- ✅ Code follows Go idioms

---

## Agent 3: Database Schema Agent (Data Modeling Specialist)

### Primary Responsibility
Design database schema, create migrations, optimize queries, and implement Row-Level Security.

### Skills Required
- PostgreSQL (advanced features: JSONB, full-text search, RLS, triggers)
- Supabase platform
- SQL migration strategies (up/down, rollback)
- Database indexing (B-tree, GIN, Hash)
- Query optimization (EXPLAIN ANALYZE)
- Row-Level Security (RLS) policies

### AI Model Recommendation
- **Primary**: GPT-4o (excellent SQL generation and optimization)
- **Alternative**: Claude 3.5 Sonnet
- **Reasoning**: GPT-4o has strong SQL knowledge and optimization capabilities

### Tools & Context

```yaml
skills:
  - postgresql/advanced
  - supabase/platform
  - database/migrations
  - database/indexing
  - database/optimization
  
context_files:
  - migrations/*.sql
  - internal/adapter/driven/postgres/*_repo.go
  - internal/domain/entity/*.go
  - docs/15-database-schema.md
  
workflows:
  1. Analyze domain entities
  2. Design normalized schema with constraints
  3. Create migration files (up/down)
  4. Define indexes (B-tree, GIN for full-text)
  5. Implement RLS policies
  6. Write repository implementation
  7. Test migrations and queries
```

### Example Prompt

```
You are a PostgreSQL database architect specializing in Supabase.

Task: Design schema for Todo application with these requirements:

Requirements:
1. Multi-tenant architecture:
   - Isolated by telegram_user_id (BIGINT)
   - Row-Level Security (RLS) enforced
   - No cross-user data leakage

2. Todo table features:
   - Auto-generated UUID primary keys
   - Sequential codes per user per year (format: YY-NNNN)
   - Full-text search on title AND description
   - JSONB for tags array
   - Timezone-aware timestamps

3. Performance requirements:
   - List todos: <50ms for 1000 todos
   - Search: <100ms with full-text
   - Filter by status/priority/tags: <50ms
   - Concurrent writes: handle 100 req/sec

4. Data integrity:
   - Foreign key constraints
   - Check constraints (priority, status enums)
   - NOT NULL where appropriate
   - Unique constraints (user_id + code)

5. Audit trail:
   - created_at, updated_at timestamps
   - Auto-update triggers
   - Consider soft deletes (deleted_at)

Deliverables:

1. migrations/001_initial_schema.sql:
   ```sql
   -- Create tables with all constraints
   -- Add indexes for performance
   -- Create RLS policies
   -- Create triggers for timestamps
   -- Create views for common queries
   ```

2. migrations/002_code_sequence.sql:
   ```sql
   -- Create sequence table per user/year
   -- Create function to generate next code
   -- Create trigger to auto-assign codes
   ```

3. Performance optimization notes:
   - Index strategy explanation
   - Query patterns to use/avoid
   - Estimated query costs
   - Monitoring recommendations

4. internal/adapter/driven/postgres/todo_repo.go:
   - Implement TodoRepository interface
   - Use pgx/v5 with connection pooling
   - Parameterized queries (no SQL injection)
   - Error handling with context
   - Transaction support where needed

RLS Policies to implement:
- Enable RLS on all tables
- Policy: Users can only see their own todos
- Policy: Users can only insert with their own telegram_user_id
- Policy: Users can only update/delete their own todos
- Service role bypass (for admin operations)

Indexes to create:
- Primary key (UUID)
- Unique index on (telegram_user_id, code)
- B-tree index on (telegram_user_id, status, due_date)
- GIN index on tags (for JSONB containment)
- GIN index for full-text search (title + description)
- Index on (telegram_user_id, updated_at) for recent todos

Output:
- migrations/001_initial_schema.sql
- migrations/002_code_sequence.sql
- internal/adapter/driven/postgres/todo_repo.go
- Performance analysis document
```

### Checkpoint Criteria
- ✅ Migrations created and tested
- ✅ RLS policies implemented
- ✅ Indexes created for performance
- ✅ Repository implementation complete
- ✅ Migrations apply successfully
- ✅ Query performance meets requirements

---

## Agent 4: HTTP/Bot Adapter Agent (Interface Specialist)

### Primary Responsibility
Implement driving adapters (Echo REST API and Telegram bot) that translate external requests to domain calls.

### Skills Required
- Echo framework (routing, middleware, validation)
- telebot/v3 (Telegram bot API)
- REST API design principles
- DTO mapping (domain <-> API)
- Authentication (JWT, API keys)
- CORS, rate limiting, security

### AI Model Recommendation
- **Primary**: GPT-4o (great at API design and framework usage)
- **Alternative**: Claude 3.5 Sonnet
- **Reasoning**: GPT-4o has extensive knowledge of web frameworks and API patterns

### Tools & Context

```yaml
skills:
  - golang/echo-framework
  - golang/telebot
  - rest-api/design
  - authentication/jwt
  - api/versioning
  
context_files:
  - internal/adapter/driving/http/*.go
  - internal/adapter/driving/telegram/*.go
  - internal/domain/service/*.go
  - internal/domain/entity/*.go
  - docs/09-echo-rest-api.md
  - docs/10-telegram-bot.md
  
workflows:
  1. Read domain service interfaces
  2. Design RESTful API endpoints
  3. Implement Echo handlers with DTOs
  4. Add middleware (auth, logging, CORS)
  5. Implement Telegram bot handlers
  6. Write adapter integration tests
```

### Example Prompt

```
You are a Go web framework specialist (Echo + Telebot).

Task: Implement REST API and Telegram bot adapters for TodoService.

Requirements:

1. Echo REST API (internal/adapter/driving/http/):

   Routes (internal/adapter/driving/http/routes.go):
   ```go
   POST   /api/v1/todos              - Create todo
   GET    /api/v1/todos              - List todos (with filters)
   GET    /api/v1/todos/:id          - Get todo by ID
   PUT    /api/v1/todos/:id          - Update todo
   DELETE /api/v1/todos/:id          - Delete todo
   POST   /api/v1/todos/:id/complete - Mark complete
   GET    /api/v1/todos/search       - Search todos
   
   GET    /api/v1/templates          - List templates
   POST   /api/v1/templates/:name/instantiate - Create from template
   
   GET    /api/v1/preferences        - Get user preferences
   PUT    /api/v1/preferences/language - Set language
   ```

   Middleware (internal/adapter/driving/http/middleware.go):
   - JWT authentication (extract user ID)
   - Request ID generation
   - Logging (structured JSON)
   - CORS (configurable origins)
   - Rate limiting (per user)
   - Error recovery

   DTOs (internal/adapter/driving/http/dto.go):
   ```go
   type CreateTodoRequest struct {
       Title       string   `json:"title" validate:"required,min=1,max=500"`
       Description *string  `json:"description,omitempty"`
       Priority    *string  `json:"priority,omitempty" validate:"omitempty,oneof=low medium high"`
       DueDate     *string  `json:"due_date,omitempty"` // ISO 8601
       Tags        []string `json:"tags,omitempty"`
   }
   
   type TodoResponse struct {
       ID          string   `json:"id"`
       Code        string   `json:"code"`
       Title       string   `json:"title"`
       Description *string  `json:"description,omitempty"`
       Priority    string   `json:"priority"`
       Status      string   `json:"status"`
       DueDate     *string  `json:"due_date,omitempty"`
       Tags        []string `json:"tags"`
       CreatedAt   string   `json:"created_at"`
       UpdatedAt   string   `json:"updated_at"`
   }
   ```

   Error Handling:
   - 400 Bad Request: validation errors
   - 401 Unauthorized: missing/invalid token
   - 403 Forbidden: insufficient permissions
   - 404 Not Found: resource doesn't exist
   - 409 Conflict: business rule violation
   - 500 Internal Server Error: unexpected errors

2. Telegram Bot (internal/adapter/driving/telegram/):

   Handlers (internal/adapter/driving/telegram/handlers.go):
   - /start - Welcome message, setup
   - /help - Command list
   - /list - List pending todos
   - /done CODE - Mark todo complete
   - OnText - Natural language processing

   Features:
   - Natural language processing (call IntentService)
   - Interactive inline keyboards (for ambiguous queries)
   - Markdown formatting for responses
   - Error messages in user's language
   - Command autocompletion

Constraints:
- Adapters ONLY translate requests to domain calls
- NO business logic in adapters (all in domain)
- Map domain errors to appropriate HTTP status codes
- Validate requests before calling domain
- Handle all error cases gracefully
- Log all requests and errors

Output:
- internal/adapter/driving/http/server.go
- internal/adapter/driving/http/routes.go
- internal/adapter/driving/http/handlers.go
- internal/adapter/driving/http/middleware.go
- internal/adapter/driving/http/dto.go
- internal/adapter/driving/telegram/bot.go
- internal/adapter/driving/telegram/handlers.go
- test/integration/http_test.go
```

### Checkpoint Criteria
- ✅ Echo server implemented with all routes
- ✅ Telegram bot implemented with handlers
- ✅ DTOs map correctly to domain
- ✅ Middleware functions correctly
- ✅ Integration tests PASS
- ✅ No business logic in adapters

---

## Agent 5: AI/NLP Agent (Machine Learning Specialist)

### Primary Responsibility
Implement AI-powered intent analysis using Perplexity API with multilingual support.

### Skills Required
- Perplexity AI API integration
- Natural language processing
- Intent classification
- Entity extraction
- Date parsing (multiple languages)
- Prompt engineering
- Context management

### AI Model Recommendation
- **Primary**: GPT-4o or Claude 3.5 Sonnet (for meta-AI implementation)
- **Specialized**: Use Perplexity Sonar for actual intent analysis
- **Reasoning**: Need strong prompt engineering and structured output parsing

### Tools & Context

```yaml
skills:
  - ai/perplexity-api
  - nlp/intent-classification
  - nlp/entity-extraction
  - nlp/multilingual
  - prompt-engineering
  
context_files:
  - internal/adapter/driven/perplexity/client.go
  - internal/domain/service/intent_service.go
  - internal/domain/entity/intent.go
  - docs/12-ai-nlp-integration.md
  
workflows:
  1. Design intent schema (actions + entities)
  2. Craft system prompts for Perplexity
  3. Implement context injection (existing todos)
  4. Parse AI responses into structured intents
  5. Handle ambiguous queries
  6. Implement fallback strategies
  7. Test multilingual support
```

### Example Prompt

```
You are an NLP specialist implementing AI-powered intent analysis.

Task: Implement IntentAnalyzer using Perplexity AI with multilingual support.

Requirements:

1. Intent Schema (internal/domain/entity/intent.go):
   ```go
   type ActionType string
   const (
       ActionCreate      ActionType = "create"
       ActionUpdate      ActionType = "update"
       ActionDelete      ActionType = "delete"
       ActionComplete    ActionType = "complete"
       ActionList        ActionType = "list"
       ActionSearch      ActionType = "search"
       ActionHelp        ActionType = "help"
       ActionUnknown     ActionType = "unknown"
   )
   
   type ParsedIntent struct {
       Action           ActionType
       Data             IntentData
       Confidence       float64
       DetectedLanguage Language
       RawMessage       string
       Ambiguities      []string
   }
   
   type IntentData struct {
       Title       *string
       Description *string
       DueDate     *time.Time
       Priority    *Priority
       Status      *Status
       Tags        []string
       SearchQuery *string
       TodoID      *string
       Language    *Language
   }
   ```

2. Perplexity Client (internal/adapter/driven/perplexity/client.go):
   - HTTP client with retry logic
   - Rate limiting (API quotas)
   - Error handling
   - Response parsing
   - Caching for common patterns

3. System Prompt Design:
   ```
   You are a todo assistant that parses natural language into structured intents.
   
   User's language: {language}
   Current date: {current_date}
   User's timezone: {timezone}
   
   Existing todos:
   {list of user's todos with codes}
   
   Parse this message: "{user_message}"
   
   Extract:
   - Action: create/update/delete/complete/list/search/help
   - Title: task title (if creating/updating)
   - Due date: parse relative dates (tomorrow, next week, etc.)
   - Priority: detect keywords (urgent, important, high, gấp, quan trọng)
   - Tags: hashtags #tag or keywords
   - Todo reference: code (YY-NNNN) or partial title match
   - Confidence: 0.0-1.0 based on clarity
   
   If ambiguous (multiple possible todos match), list candidates.
   
   Output JSON:
   {json schema}
   ```

4. Language-Specific Parsing:

   English:
   - "tomorrow", "next week", "in 3 days"
   - "urgent", "important", "high priority"
   - "done with", "finished", "completed"
   
   Vietnamese:
   - "ngày mai", "tuần sau", "3 ngày nữa"
   - "gấp", "quan trọng", "ưu tiên cao"
   - "xong", "hoàn thành"

5. Context-Aware Parsing:
   - For "update X" or "mark done X", search existing todos
   - If multiple matches, return ambiguity with candidates
   - If no matches, suggest creating new todo
   - Consider recent todos for implicit references

6. Error Handling:
   - API errors: fallback to regex patterns
   - Low confidence (<0.7): ask for clarification
   - Ambiguous: return multiple candidates
   - Invalid dates: ask for clarification

Output:
- internal/adapter/driven/perplexity/client.go
- internal/domain/service/intent_service.go
- prompts/system_prompt_en.txt
- prompts/system_prompt_vi.txt
- test/unit/adapter/perplexity_test.go
```

### Checkpoint Criteria
- ✅ Perplexity client implemented
- ✅ Intent parsing accurate (>90%)
- ✅ Multilingual support works
- ✅ Ambiguity handling functional
- ✅ Fallback strategies work
- ✅ NLP tests PASS

---

## Agent 6: Infrastructure/DevOps Agent (CI/CD Specialist)

### Primary Responsibility
Set up CI/CD pipelines, Docker containerization, Railway deployment, and monitoring.

### Skills Required
- GitHub Actions (workflows, secrets, matrix builds)
- Docker (multi-stage builds, optimization)
- Railway platform
- Environment configuration
- Logging and monitoring
- Secret management

### AI Model Recommendation
- **Primary**: GPT-4o (excellent at DevOps scripts and configuration)
- **Alternative**: Claude 3.5 Sonnet
- **Reasoning**: GPT-4o has strong DevOps knowledge and script generation

### Tools & Context

```yaml
skills:
  - cicd/github-actions
  - containerization/docker
  - deployment/railway
  - monitoring/logging
  - security/secrets
  
context_files:
  - .github/workflows/*.yml
  - Dockerfile
  - railway.toml
  - Makefile
  - docs/16-cicd-pipeline.md
  
workflows:
  1. Design CI pipeline (lint, test, build)
  2. Create multi-stage Dockerfile
  3. Set up GitHub Actions workflows
  4. Configure Railway deployment
  5. Add health checks and monitoring
  6. Document deployment process
```

### Example Prompt

```
You are a DevOps specialist focused on Go applications.

Task: Set up complete CI/CD pipeline for the Telegram Todo Bot.

Requirements:

1. GitHub Actions CI (.github/workflows/ci.yml):
   ```yaml
   name: CI
   on: [push, pull_request]
   jobs:
     lint:
       - golangci-lint
       - gosec (security scan)
     
     test:
       - Unit tests with coverage
       - BDD tests (godog)
       - Integration tests
       - Upload to codecov
     
     build:
       - Build for linux/amd64
       - Build for linux/arm64
       - Verify no errors
   ```

2. Docker (Dockerfile):
   ```dockerfile
   # Multi-stage build
   # Stage 1: Builder
   FROM golang:1.22-alpine AS builder
   - Install dependencies
   - Copy source
   - Build binary (CGO_ENABLED=0)
   - Strip debug symbols
   
   # Stage 2: Runtime
   FROM alpine:latest
   - Install ca-certificates, tzdata
   - Create non-root user
   - Copy binary from builder
   - Expose ports
   - Health check endpoint
   - Run as non-root
   ```

3. Railway Deployment (railway.toml):
   ```toml
   [build]
   builder = "dockerfile"
   
   [deploy]
   startCommand = "/app/bot"
   healthcheckPath = "/health"
   healthcheckTimeout = 30
   restartPolicyType = "on_failure"
   ```

4. GitHub Actions CD (.github/workflows/deploy.yml):
   ```yaml
   name: Deploy
   on:
     push:
       branches: [main]
   jobs:
     deploy:
       - Run tests
       - Build Docker image
       - Push to Railway
       - Run smoke tests
       - Notify on failure
   ```

5. Makefile:
   ```makefile
   .PHONY: build test lint docker-build deploy
   
   build:        # Build binary
   test:         # Run all tests
   test-unit:    # Unit tests only
   test-bdd:     # BDD tests only
   lint:         # Run linters
   mocks:        # Generate mocks
   docker-build: # Build Docker image
   docker-run:   # Run locally
   deploy:       # Deploy to Railway
   ```

6. Monitoring & Logging:
   - Structured logging (JSON format)
   - Log levels (debug, info, warn, error)
   - Request ID tracking
   - Error tracking (Sentry integration optional)
   - Performance metrics
   - Health check endpoint

7. Environment Variables:
   ```
   TELEGRAM_BOT_TOKEN=xxx
   DATABASE_URL=postgresql://...
   PERPLEXITY_API_KEY=xxx
   JWT_SECRET=xxx
   LOG_LEVEL=info
   PORT=8080
   ```

Security:
- No secrets in repository
- Use GitHub Secrets for CI/CD
- Use Railway environment variables for deployment
- Scan for vulnerabilities (gosec, trivy)
- Run as non-root user in Docker
- Minimal Docker image (Alpine)

Output:
- .github/workflows/ci.yml
- .github/workflows/deploy.yml
- Dockerfile
- .dockerignore
- railway.toml
- Makefile
- docs/deployment-guide.md
```

### Checkpoint Criteria
- ✅ CI pipeline runs successfully
- ✅ Docker image builds and runs
- ✅ Railway deployment successful
- ✅ Health checks work
- ✅ Monitoring configured
- ✅ Documentation complete

---

## Factory.ai Droid Configuration

For use with the Factory.ai platform, create these droid configuration files:

### .factory/droids/test-first.yaml
```yaml
name: test-first-agent
description: BDD/TDD specialist that writes tests before implementation
model: claude-3.5-sonnet
skills:
  - testing/godog
  - testing/testify
  - bdd/gherkin
context:
  - features/**/*.feature
  - test/**/*_test.go
  - docs/04-tdd-bdd-workflow.md
  - docs/05-testing-strategy.md
```

### .factory/droids/domain-logic.yaml
```yaml
name: domain-logic-agent
description: Implements business logic following hexagonal architecture
model: claude-3.5-sonnet
skills:
  - golang/interfaces
  - design-patterns/hexagonal-architecture
  - domain-driven-design
context:
  - internal/domain/**/*.go
  - test/unit/domain/**/*_test.go
  - docs/03-hexagonal-architecture.md
  - docs/06-domain-entities.md
  - docs/07-domain-services.md
```

### .factory/droids/api-adapter.yaml
```yaml
name: api-adapter-agent
description: Implements Echo REST API and Telegram bot adapters
model: gpt-4o
skills:
  - golang/echo-framework
  - golang/telebot
  - rest-api/design
context:
  - internal/adapter/driving/**/*.go
  - docs/09-echo-rest-api.md
  - docs/10-telegram-bot.md
```

### .factory/droids/database.yaml
```yaml
name: database-agent
description: PostgreSQL schema design and optimization
model: gpt-4o
skills:
  - postgresql/advanced
  - supabase/platform
  - database/migrations
context:
  - migrations/**/*.sql
  - internal/adapter/driven/postgres/**/*.go
  - docs/15-database-schema.md
```

### .factory/droids/ai-nlp.yaml
```yaml
name: ai-nlp-agent
description: Implements AI-powered intent analysis
model: claude-3.5-sonnet
skills:
  - ai/perplexity-api
  - nlp/intent-classification
  - nlp/multilingual
context:
  - internal/adapter/driven/perplexity/**/*.go
  - internal/domain/service/intent_service.go
  - docs/12-ai-nlp-integration.md
```

### .factory/droids/infrastructure.yaml
```yaml
name: infrastructure-agent
description: CI/CD, Docker, and deployment automation
model: gpt-4o
skills:
  - cicd/github-actions
  - containerization/docker
  - deployment/railway
context:
  - .github/workflows/**/*.yml
  - Dockerfile
  - railway.toml
  - docs/16-cicd-pipeline.md
```

## Next Steps

- See [Multi-Agent Architecture](18-multi-agent-architecture.md) for coordination workflow
- Read [AI Model Recommendations](20-ai-model-recommendations.md) for model selection rationale
- Review [TDD/BDD Workflow](04-tdd-bdd-workflow.md) for test-first methodology
