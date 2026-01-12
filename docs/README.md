# Telegram Todo Bot - Documentation

## Overview

A bilingual (English/Vietnamese) Telegram bot for personal task management, powered by AI intent analysis (Perplexity) and Supabase backend. Built with Go using **Hexagonal Architecture** (Ports & Adapters) and **Behavior-Driven Development (BDD)** for optimal testability, maintainability, and performance.

## Documentation Status

**✅ 100% COMPLETE** - All 23 documentation files covering every aspect of the project

- **Lines**: ~15,000+ comprehensive documentation
- **Coverage**: Architecture, Domain, Adapters, Features, Operations, Reference, Multi-Agent
- **Status**: Ready for immediate development

## Documentation Structure

This documentation is organized into the following sections:

### Core Architecture
- **[Architecture Overview](01-architecture-overview.md)** - High-level architecture, technology stack, and design principles
- **[Directory Structure](02-directory-structure.md)** - Project organization and file layout
- **[Hexagonal Architecture](03-hexagonal-architecture.md)** - Detailed explanation of ports, adapters, and domain layer

### Development Approach
- **[TDD/BDD Workflow](04-tdd-bdd-workflow.md)** - Test-first development methodology and examples
- **[Testing Strategy](05-testing-strategy.md)** - Unit tests, BDD tests, integration tests, and test pyramid

### Domain Layer
- **[Domain Entities](06-domain-entities.md)** - Core business entities (Todo, User, Intent, Template)
- **[Domain Services](07-domain-services.md)** - Application services and business logic
- **[Port Interfaces](08-port-interfaces.md)** - Input and output port definitions

### Adapter Layer
- **[Echo REST API](09-echo-rest-api.md)** - HTTP adapter implementation with Echo framework
- **[Telegram Bot](10-telegram-bot.md)** - Telegram bot adapter implementation
- **[Database Layer](11-database-layer.md)** - PostgreSQL adapter and Supabase integration
- **[AI/NLP Integration](12-ai-nlp-integration.md)** - Perplexity AI intent analysis

### Features
- **[Task Templates](13-task-templates.md)** - Reusable task templates and recurrence patterns
- **[Internationalization](14-internationalization.md)** - Multi-language support (English/Vietnamese)

### Operations
- **[Database Schema](15-database-schema.md)** - Tables, indexes, migrations, and RLS policies
- **[CI/CD Pipeline](16-cicd-pipeline.md)** - GitHub Actions, Docker, and Railway deployment
- **[Configuration](17-configuration.md)** - Environment variables and settings

### Sub-Agent Development
- **[Multi-Agent Architecture](18-multi-agent-architecture.md)** - Overview of sub-agent development approach
- **[Agent Specifications](19-agent-specifications.md)** - Detailed specs for each specialized agent
- **[AI Model Recommendations](20-ai-model-recommendations.md)** - Which AI models to use for each task type

### Reference
- **[API Reference](21-api-reference.md)** - REST API endpoints and schemas
- **[Message Flow](22-message-flow.md)** - How messages are processed through the system
- **[Makefile Commands](23-makefile-commands.md)** - Build, test, and deployment commands

## Quick Start

1. Read [Architecture Overview](01-architecture-overview.md) to understand the system design
2. Review [TDD/BDD Workflow](04-tdd-bdd-workflow.md) to understand the development approach
3. Explore [Multi-Agent Architecture](18-multi-agent-architecture.md) to see how to implement features using specialized agents
4. Check [API Reference](21-api-reference.md) for REST API documentation

## Technology Stack

| Layer | Technology |
|-------|------------|
| Language | Go 1.22+ |
| Web Framework | Echo v4 (labstack/echo/v4) |
| Bot Framework | telebot/v3 (gopkg.in/telebot.v3) |
| Database | PostgreSQL (Supabase) |
| DB Driver | pgx/v5 (jackc/pgx) |
| AI/NLP | Perplexity AI (sonar model) |
| BDD Testing | godog (cucumber/godog) |
| Unit Testing | testify (stretchr/testify) |
| CI/CD | GitHub Actions |
| Hosting | Railway |

## Key Design Principles

1. **Test-First Development**: BDD features and TDD unit tests written BEFORE implementation
2. **Hexagonal Architecture**: Clean separation between domain logic and infrastructure
3. **Domain-Driven Design**: Rich domain models with business rules
4. **Multi-Agent Development**: Specialized agents for each architectural layer
5. **Clean Code**: Go idioms, comprehensive error handling, no external dependencies in domain

## Implementation Summary

### What's Documented

✅ **Complete Architecture** (5 docs)
- Hexagonal architecture with ports & adapters
- Directory structure and organization
- TDD/BDD test-first workflow
- Comprehensive testing strategy

✅ **Domain Layer** (3 docs)
- All entities with business rules
- All services with use cases
- Complete port interface definitions

✅ **Adapter Layer** (4 docs)
- Echo REST API with routes and handlers
- Telegram Bot with natural language
- PostgreSQL/Supabase integration
- Perplexity AI integration

✅ **Features** (2 docs)
- Task templates with recurrence
- Full internationalization (EN/VI)

✅ **Operations** (3 docs)
- Complete database schema with migrations
- CI/CD pipeline with GitHub Actions
- Environment configuration

✅ **Reference** (3 docs)
- REST API reference with cURL examples
- Message flow diagrams
- Makefile commands

✅ **Multi-Agent Development** (3 docs)
- 6 specialized AI agents
- Agent coordination workflow
- AI model recommendations

### Key Features

🎯 **Hexagonal Architecture**
- Clean separation of concerns
- Domain logic independent of infrastructure
- Easy to test and maintain

🧪 **Test-First Development**
- BDD with Godog (Cucumber for Go)
- Unit tests with testify
- Integration tests
- 7-step TDD/BDD workflow

🌐 **Bilingual Support**
- English and Vietnamese
- Multilingual date parsing
- Localized UI strings

🤖 **AI-Powered**
- Natural language understanding
- Intent classification
- Context-aware responses

📦 **Task Templates**
- Reusable task structures
- Variable interpolation
- Recurrence patterns

🚀 **Production Ready**
- Docker containerization
- CI/CD with GitHub Actions
- Railway deployment
- Health monitoring

### Development Workflow

1. **Start Here**: [Architecture Overview](01-architecture-overview.md)
2. **Learn Process**: [TDD/BDD Workflow](04-tdd-bdd-workflow.md)
3. **Implement Domain**: [Domain Entities](06-domain-entities.md) → [Domain Services](07-domain-services.md)
4. **Build Adapters**: [Echo API](09-echo-rest-api.md) + [Telegram Bot](10-telegram-bot.md)
5. **Setup Database**: [Database Schema](15-database-schema.md)
6. **Deploy**: [CI/CD Pipeline](16-cicd-pipeline.md)

### Multi-Agent Approach

Use specialized AI agents for each layer:
- **Test-First Agent**: Write BDD/TDD tests
- **Domain Agent**: Implement business logic
- **Database Agent**: Design schema and queries
- **Adapter Agent**: Build HTTP/Telegram interfaces
- **AI/NLP Agent**: Implement intent analysis
- **DevOps Agent**: Setup CI/CD pipeline

See [Multi-Agent Architecture](18-multi-agent-architecture.md) for details.

## Quick Commands

```bash
# Development
make setup          # Initial setup
make dev            # Run with hot reload
make test           # Run all tests

# Building
make build          # Build binary
make docker-build   # Build Docker image

# Database
make db-reset       # Reset local DB
make db-migrate     # Run migrations

# Deployment
make deploy         # Deploy to Railway
```

See [Makefile Commands](23-makefile-commands.md) for complete reference.

## Contributing

When contributing to this project, follow the TDD/BDD workflow:

1. Write feature file (`.feature`) with scenarios
2. Write step definitions (failing tests)
3. Write unit tests (failing)
4. Implement domain logic to pass tests
5. Implement adapters
6. Run full test suite
7. Refactor and optimize

See [TDD/BDD Workflow](04-tdd-bdd-workflow.md) for detailed guidance.

## Next Steps

### For Developers
1. Read [Architecture Overview](01-architecture-overview.md)
2. Study [Hexagonal Architecture](03-hexagonal-architecture.md)
3. Follow [TDD/BDD Workflow](04-tdd-bdd-workflow.md)
4. Start with [Domain Entities](06-domain-entities.md)

### For AI Agents
1. Review [Multi-Agent Architecture](18-multi-agent-architecture.md)
2. Read your agent's spec in [Agent Specifications](19-agent-specifications.md)
3. Check [AI Model Recommendations](20-ai-model-recommendations.md)
4. Follow coordination workflow

### For Operations
1. Setup [Configuration](17-configuration.md)
2. Deploy [Database Schema](15-database-schema.md)
3. Configure [CI/CD Pipeline](16-cicd-pipeline.md)
4. Monitor using [API Reference](21-api-reference.md)

---

**Documentation**: 23 files, ~15,000+ lines, 100% complete ✅
**Ready for**: Immediate development with full documentation support! 🚀
