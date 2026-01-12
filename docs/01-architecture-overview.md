# Architecture Overview

## Overview

A bilingual (English/Vietnamese) Telegram bot for personal task management, powered by AI intent analysis (Perplexity) and Supabase backend. Built with Go using **Hexagonal Architecture** (Ports & Adapters) and **Behavior-Driven Development (BDD)** for optimal testability, maintainability, and performance.

## Technology Stack

| Layer | Technology |
|-------|------------|
| Language | Go 1.22+ |
| Web Framework | Echo v4 (labstack/echo/v4) |
| Bot Framework | telebot/v3 (gopkg.in/telebot.v3) |
| Database | PostgreSQL (Supabase) |
| DB Driver | pgx/v5 (jackc/pgx) |
| AI/NLP | Perplexity AI (sonar model) |
| HTTP Client | net/http (stdlib) |
| Configuration | envconfig or viper |
| BDD Testing | godog (cucumber/godog) |
| Unit Testing | testify (stretchr/testify) |
| Mocking | mockery (vektra/mockery) |
| Containerization | Docker (multi-stage build) |
| CI/CD | GitHub Actions |
| Hosting | Railway |

## Core Design Principles

### 1. Hexagonal Architecture (Ports & Adapters)

The application follows **Hexagonal Architecture** to decouple business logic from external dependencies, enabling easy testing and swapping of adapters.

**Benefits:**
- Business logic is independent of frameworks and infrastructure
- Easy to test (can use in-memory adapters)
- Easy to swap implementations (e.g., switch from Supabase to local PostgreSQL)
- Clear boundaries between layers

### 2. Test-Driven Development (TDD) & Behavior-Driven Development (BDD)

- **BDD**: Features written in Gherkin syntax BEFORE implementation
- **TDD**: Unit tests written BEFORE domain logic
- **Workflow**: RED → GREEN → REFACTOR cycle
- **Tools**: Godog for BDD, Testify for unit tests

### 3. Domain-Driven Design (DDD)

- Rich domain entities with business rules
- Application services orchestrate use cases
- No infrastructure dependencies in domain layer
- Clear ubiquitous language

### 4. Multi-Agent Development

- Specialized AI agents for each architectural layer
- Test-First Agent, Domain Logic Agent, Adapter Agent, etc.
- Each agent focuses on specific skills and responsibilities

## System Capabilities

### User Interfaces
1. **Telegram Bot** - Natural language interface with AI-powered intent analysis
2. **REST API** - Programmatic access via Echo framework

### Core Features
- ✅ Create todos via natural language or structured API
- ✅ List, search, filter todos
- ✅ Update, complete, delete todos
- ✅ Task templates with variables and recurrence
- ✅ Multi-language support (English/Vietnamese)
- ✅ Auto-generated sequential codes (YY-NNNN format)
- ✅ Priority levels and due dates
- ✅ Tags and full-text search

### Technical Features
- ✅ AI-powered intent analysis (Perplexity)
- ✅ Row-Level Security (RLS) for data isolation
- ✅ JWT authentication for REST API
- ✅ Comprehensive test coverage (BDD + TDD)
- ✅ CI/CD pipeline (GitHub Actions)
- ✅ Docker containerization
- ✅ Automated deployment (Railway)

## Performance Benefits (Go vs Node.js)

| Aspect | Previous (Node.js + Edge) | Current (Go) |
|--------|---------------------------|--------------|
| Cold start | ~500-2000ms (edge fn) | None (always running) |
| Memory | ~100MB+ | ~10-20MB |
| Latency | 2 HTTP hops | 1 HTTP hop (AI only) |
| Concurrency | Event loop | Goroutines |
| Binary size | N/A (interpreted) | ~10-15MB |

## Supported Languages

| Feature | English | Vietnamese |
|---------|---------|------------|
| Commands | Yes | Yes |
| Date parsing | tomorrow, next week | ngày mai, tuần sau |
| Priority | urgent, important | gấp, quan trọng |
| UI strings | Full | Full |
| Default timezone | UTC | Asia/Ho_Chi_Minh |

## Next Steps

- Read [Hexagonal Architecture](03-hexagonal-architecture.md) for detailed layer explanations
- See [TDD/BDD Workflow](04-tdd-bdd-workflow.md) for development methodology
- Explore [Multi-Agent Architecture](18-multi-agent-architecture.md) for implementation approach
