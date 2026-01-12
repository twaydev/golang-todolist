#!/bin/bash
# Initialize Golang Todo Bot Project Structure
# Usage: ./init-project.sh

set -e

echo "🚀 Initializing Golang Todo Bot Project"
echo ""

# Check if we're in the right directory
if [ ! -d ".factory" ]; then
  echo "❌ Error: .factory directory not found"
  echo "Please run this script from the project root directory"
  exit 1
fi

# Check if go.mod exists
if [ -f "go.mod" ]; then
  echo "✅ go.mod already exists"
else
  echo "Creating go.mod..."
  read -p "Enter your GitHub username: " github_user
  go mod init github.com/${github_user}/golang-todolist
  echo "✅ go.mod created"
fi

# Create directory structure
echo ""
echo "Creating directory structure..."

# Core directories
mkdir -p cmd/bot
mkdir -p internal/domain/{entity,service,port/{input,output}}
mkdir -p internal/adapter/driving/{http,telegram}
mkdir -p internal/adapter/driven/{postgres,perplexity,memory}
mkdir -p internal/{config,i18n}

# Test directories
mkdir -p features
mkdir -p test/{bdd,unit/{domain,adapter},integration,mocks}

# Other directories
mkdir -p migrations
mkdir -p templates
mkdir -p prompts

echo "✅ Directory structure created"

# Create .gitignore if not exists
if [ ! -f ".gitignore" ]; then
  echo ""
  echo "Creating .gitignore..."
  cat > .gitignore << 'EOF'
# Binaries
*.exe
*.exe~
*.dll
*.so
*.dylib
bin/
build/
dist/

# Test & Coverage
*.test
*.out
coverage*.out
coverage*.html
.nyc_output/

# Environment
.env
.env.*
!.env.example

# IDEs
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
.DS_Store?
._*
.Spotlight-V100
.Trashes

# Go
vendor/
go.work
go.work.sum

# Temporary
tmp/
temp/
*.log
*.pid

# Railway
.railway/

# Factory.ai artifacts
~/.factory/artifacts/

# Build artifacts
*.test
*.prof
EOF
  echo "✅ .gitignore created"
else
  echo "✅ .gitignore already exists"
fi

# Create .env.example if not exists
if [ ! -f ".env.example" ]; then
  echo ""
  echo "Creating .env.example..."
  cat > .env.example << 'EOF'
# Telegram Bot
TELEGRAM_BOT_TOKEN=your_bot_token_here

# Database (Supabase PostgreSQL)
DATABASE_URL=postgresql://user:password@host:5432/database

# Perplexity AI
PERPLEXITY_API_KEY=your_perplexity_api_key_here

# Server Configuration
PORT=8080
LOG_LEVEL=info
ENV=development

# JWT Authentication (for REST API)
JWT_SECRET=your_jwt_secret_here_minimum_32_characters_long

# Railway (auto-set by Railway platform)
RAILWAY_ENVIRONMENT=
RAILWAY_SERVICE_NAME=
RAILWAY_PUBLIC_DOMAIN=
EOF
  echo "✅ .env.example created"
  echo ""
  echo "⚠️  Action required: Copy .env.example to .env and fill in your credentials"
  echo "   cp .env.example .env"
  echo "   vim .env  # or use your favorite editor"
else
  echo "✅ .env.example already exists"
fi

# Create README.md if not exists
if [ ! -f "README.md" ]; then
  echo ""
  echo "Creating README.md..."
  cat > README.md << 'EOF'
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
EOF
  echo "✅ README.md created"
else
  echo "✅ README.md already exists"
fi

# Initialize git if not exists
if [ ! -d ".git" ]; then
  echo ""
  echo "Initializing git repository..."
  git init
  git add .
  git commit -m "chore: initial project structure with orchestrator system"
  echo "✅ Git repository initialized"
else
  echo "✅ Git repository already initialized"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Project initialization complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Directory structure created:"
echo "   ✓ cmd/bot/ - Application entry point"
echo "   ✓ internal/ - Domain & adapters"
echo "   ✓ features/ - BDD scenarios"
echo "   ✓ test/ - Unit, integration, BDD tests"
echo "   ✓ migrations/ - Database migrations"
echo "   ✓ orchestrator/ - Orchestration system"
echo ""
echo "📋 Next steps:"
echo ""
echo "1️⃣  Configure environment:"
echo "   cp .env.example .env"
echo "   vim .env  # Add your credentials"
echo ""
echo "2️⃣  Configure Linear (one-time, 15 min):"
echo "   - Open Linear workspace settings"
echo "   - Create labels (see orchestrator/README.md)"
echo "   - Configure workflow states"
echo ""
echo "3️⃣  Connect Factory.ai to Linear (one-time, 5 min):"
echo "   - Go to: https://app.factory.ai/settings/integrations"
echo "   - Click 'Connect Linear'"
echo "   - Authorize and grant permissions"
echo ""
echo "4️⃣  Start building with orchestrator:"
echo "   droid"
echo "   > /droid orchestrator"
echo "   > Implement foundation: main.go, config, health check, /start command"
echo ""
echo "📚 Documentation:"
echo "   - Quick start: QUICKSTART_ORCHESTRATOR.md"
echo "   - Full guide: PROJECT_INIT_GUIDE.md"
echo "   - System docs: orchestrator/README.md"
echo "   - Architecture: docs/01-architecture-overview.md"
echo ""
echo "🚀 Ready to build! The orchestrator will guide you through"
echo "   test-driven development with proper hexagonal architecture."
echo ""
