# Golang Todo Bot

A bilingual (English/Vietnamese) Telegram bot for personal task management, powered by AI intent analysis and built with hexagonal architecture.

## Features

- 📝 Create, update, and manage todos
- 🔢 Auto-generated sequential codes (YY-NNNN format)
- 🤖 AI-powered natural language processing (Perplexity)
- 🌐 Bilingual support (English + Vietnamese)
- 🔒 Row-Level Security with Supabase
- 📱 Telegram bot interface
- 🔌 REST API
- 🎯 Priority and status management
- 🏷️ Tags and full-text search
- 📅 Due dates with timezone support

## Quick Start

### Prerequisites
- Go 1.22+
- PostgreSQL (or Supabase account)
- Telegram Bot Token
- Perplexity API Key

### Setup

```bash
# 1. Clone repository
git clone https://github.com/yourusername/golang-todolist.git
cd golang-todolist

# 2. Install dependencies
go mod download

# 3. Configure environment
cp .env.example .env
# Edit .env with your credentials

# 4. Run migrations
make db-migrate

# 5. Start development server
make dev
```

### Using the Orchestrator

This project uses Factory.ai's orchestrator system for automated development:

```bash
droid
> /droid orchestrator
> Implement: {your feature description}
```

See `QUICKSTART_ORCHESTRATOR.md` for details.

## Project Structure

See `docs/02-directory-structure.md` for complete structure.

```
├── cmd/bot/              # Application entry point
├── internal/domain/      # Core business logic (hexagonal architecture)
├── internal/adapter/     # Adapters (HTTP, Telegram, DB, AI)
├── features/            # BDD feature files
├── test/                # Tests (unit, integration, BDD)
├── migrations/          # Database migrations
└── orchestrator/        # Orchestrator system for automated development
```

## Documentation

- [Architecture Overview](docs/01-architecture-overview.md)
- [Orchestrator Quick Start](QUICKSTART_ORCHESTRATOR.md)
- [Project Initialization](PROJECT_INIT_GUIDE.md)
- [Complete Documentation](docs/)

## Development

```bash
make dev           # Run with hot reload
make test          # Run all tests
make lint          # Run linters
make build         # Build binary
make docker-build  # Build Docker image
```

## Deployment

```bash
make deploy        # Deploy to Railway
```

## Contributing

See [Development Workflows](.factory/workflows/) for contribution guidelines.

## License

MIT
