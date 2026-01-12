# Project Initialization Guide

## Overview

This guide walks you through initializing the Golang Todo Bot project from scratch, leveraging the orchestrator system for automated development.

## Current State Review

### ✅ What You Have
- **Documentation** (23 files): Complete architecture, domain, adapters, testing
- **Factory.ai Droids** (7 droids): orchestrator + 6 specialized agents
- **Skills** (36 skills): Go, testing, DB, AI/NLP, DevOps, Linear integration
- **Workflows** (6 workflows): Feature, bug fix, refactor, deploy, troubleshoot, orchestrated
- **Orchestrator System**: Complete 4-phase workflow with Linear integration

### ❌ What You Need
- **Go Project Structure**: Directories and initial files
- **Configuration Files**: go.mod, .env, .gitignore, etc.
- **Build System**: Makefile, Docker, CI/CD
- **Foundation Code**: Main entry point, config loader

## Recommended Initialization Approach

I'll give you **two options** based on your preference:

---

## Option A: Automated with Orchestrator (Recommended) ⚡

**Use the orchestrator to build the entire project automatically**

### Why This Approach?
- ✅ Tests are written first (proper TDD)
- ✅ Architecture is enforced from the start
- ✅ All layers implemented correctly
- ✅ Deployed and tested end-to-end
- ✅ Takes ~12-15 hours (3 hours per major feature)
- ✅ Learning experience for your team

### Timeline

```
Phase 0: Project Setup (2 hours)
├── Initialize Go module
├── Create directory structure
├── Add configuration files
├── Setup Git and CI/CD
└── Deploy "Hello World" to Railway

Phase 1: Foundation (3 hours) - First orchestrated feature
├── User entity and preferences
├── Database schema with RLS
├── Basic REST API health check
└── Telegram bot /start command

Phase 2: Core Todo Management (3 hours) - Second orchestrated feature
├── Todo entity with validation
├── Create, Read, Update, Delete operations
├── REST API endpoints
└── Telegram bot commands

Phase 3: Advanced Features (3 hours) - Third orchestrated feature
├── Priority and status management
├── Due dates and reminders
├── Tags and filtering
└── Search functionality

Phase 4: AI/NLP Integration (3 hours) - Fourth orchestrated feature
├── Perplexity API integration
├── Intent parsing (EN + VI)
├── Natural language todo creation
└── Context-aware responses

Total: ~14 hours to production-ready app
```

### Steps for Option A

#### Step 1: Project Setup (Manual, 30 min)

```bash
# Initialize Go project
cd /Users/tway/Projects/golang-todolist
go mod init github.com/yourusername/golang-todolist

# Create directory structure
mkdir -p cmd/bot
mkdir -p internal/{domain/{entity,service,port/{input,output}},adapter/{driving/{http,telegram},driven/{postgres,perplexity,memory}},config,i18n}
mkdir -p features test/{bdd,unit/{domain,adapter},integration,mocks}
mkdir -p migrations templates prompts

# Create .gitignore
cat > .gitignore << 'EOF'
# Binaries
*.exe
*.exe~
*.dll
*.so
*.dylib
bin/
build/

# Test & Coverage
*.test
*.out
coverage*.out
coverage.html

# IDEs
.idea/
.vscode/
*.swp
*.swo
*~

# Environment
.env
.env.*
!.env.example

# OS
.DS_Store
Thumbs.db

# Go
vendor/
go.work
go.work.sum

# Temporary
tmp/
temp/
*.log

# Railway
.railway/

# Factory.ai artifacts
~/.factory/artifacts/
EOF

# Create .env.example
cat > .env.example << 'EOF'
# Telegram Bot
TELEGRAM_BOT_TOKEN=your_bot_token_here

# Database (Supabase)
DATABASE_URL=postgresql://user:pass@host:5432/dbname

# Perplexity AI
PERPLEXITY_API_KEY=your_perplexity_key_here

# Server
PORT=8080
LOG_LEVEL=info
ENV=development

# JWT (for REST API)
JWT_SECRET=your_jwt_secret_here_min_32_chars

# Railway (auto-set by Railway)
RAILWAY_ENVIRONMENT=
RAILWAY_SERVICE_NAME=
EOF

# Create go.mod (will be populated by orchestrator)
go mod tidy

# Initialize Git
git init
git add .
git commit -m "chore: initial project structure with orchestrator"
```

#### Step 2: Use Orchestrator for Feature 1 - Foundation (3 hours)

```bash
droid
> /droid orchestrator
> Implement Phase 1: Project Foundation
>
> Requirements:
> 1. Main entry point with graceful shutdown
> 2. Configuration loader from environment
> 3. User entity with preferences (language, timezone)
> 4. User repository interface and PostgreSQL implementation
> 5. Health check endpoint (REST API)
> 6. Telegram bot /start command
>
> Acceptance Criteria:
> - [ ] Main.go starts server and bot
> - [ ] Configuration loads from .env
> - [ ] User table created with RLS
> - [ ] Health check returns 200 OK
> - [ ] /start command works in Telegram
> - [ ] Unit tests pass
> - [ ] Deployed to Railway

# Watch orchestrator create:
# ✅ Linear epic + 6 tasks
# ✅ Phase 1: Tests (features/foundation.feature, test stubs)
# ✅ Phase 2: Domain (User entity, config) + Database (migrations, user_repo)
# ✅ Phase 3: Adapters (main.go, health endpoint, /start)
# ✅ Phase 4: Infrastructure (Makefile, Dockerfile, .github/workflows)

# Result: Working foundation deployed to Railway
```

#### Step 3: Use Orchestrator for Feature 2 - Todo CRUD (3 hours)

```bash
> /droid orchestrator
> Implement Phase 2: Todo CRUD Operations
>
> Requirements:
> 1. Todo entity with validation (title, status, priority, due_date, tags)
> 2. Auto-generated sequential code (YY-NNNN format)
> 3. TodoService with Create, Read, Update, Delete, List
> 4. TodoRepository with PostgreSQL implementation
> 5. REST API endpoints (POST, GET, PUT, DELETE /api/v1/todos)
> 6. Telegram bot commands (/list, /done CODE)
>
> Acceptance Criteria:
> - [ ] Todo entity with business rules
> - [ ] TodoService implements all CRUD operations
> - [ ] Database schema with auto-generated codes
> - [ ] REST API endpoints work
> - [ ] Telegram bot commands work
> - [ ] Tests pass (unit + integration)
> - [ ] Deployed

# Orchestrator executes 4 phases automatically
# Result: Full CRUD functionality live
```

#### Step 4: Use Orchestrator for Feature 3 - Advanced Features (3 hours)

```bash
> /droid orchestrator
> Implement Phase 3: Advanced Todo Features
>
> Requirements:
> 1. Priority management (low, medium, high)
> 2. Status transitions (pending → in_progress → completed)
> 3. Due date handling with timezone support
> 4. Tags with array storage (JSONB)
> 5. Search and filtering (by status, priority, tags, date range)
> 6. Full-text search on title and description
>
> Acceptance Criteria:
> - [ ] Priority and status enums work
> - [ ] State transitions enforced
> - [ ] Search and filter work correctly
> - [ ] Full-text search performs well (<100ms)
> - [ ] REST API supports all filters
> - [ ] Tests pass
> - [ ] Deployed
```

#### Step 5: Use Orchestrator for Feature 4 - AI/NLP (3 hours)

```bash
> /droid orchestrator
> Implement Phase 4: AI-Powered Natural Language
>
> Requirements:
> 1. Perplexity API client with retry logic
> 2. Intent parsing (create, update, complete, list, search)
> 3. Entity extraction (title, priority, due_date, tags)
> 4. Multilingual support (English + Vietnamese)
> 5. Date parsing (tomorrow, next week, etc.)
> 6. Context-aware responses with existing todos
>
> Acceptance Criteria:
> - [ ] Intent classification >90% accurate
> - [ ] Both English and Vietnamese work
> - [ ] Natural language creates todos correctly
> - [ ] Ambiguous queries handled with candidates
> - [ ] Fallback to regex if API fails
> - [ ] Tests pass
> - [ ] Deployed
```

#### Step 6: Polish & Optimize (2 hours, manual)

```bash
# After orchestrator completes all 4 phases:

# 1. Review generated code
# 2. Add any custom business logic
# 3. Optimize performance if needed
# 4. Write additional edge case tests
# 5. Update documentation
# 6. Final deployment

# Result: Production-ready todo bot!
```

### Benefits of Option A
- ✅ **Proven Architecture**: Hexagonal architecture enforced
- ✅ **Test Coverage**: >90% from TDD approach
- ✅ **Quality Code**: Generated by specialized agents
- ✅ **Full Audit Trail**: Everything tracked in Linear
- ✅ **Learning Experience**: See how agents work together
- ✅ **Production Ready**: Deployed and tested end-to-end

---

## Option B: Manual Foundation, Then Orchestrator 🛠️

**Create basic structure manually, then use orchestrator for features**

### Why This Approach?
- ✅ Learn the architecture hands-on
- ✅ Customize foundation to your needs
- ✅ Still use orchestrator for features
- ✅ Takes ~18-20 hours (5 manual + 12-15 orchestrated)

### Steps for Option B

#### Step 1: Manual Setup (5 hours)

1. **Initialize Project** (30 min)
   ```bash
   # Same as Option A Step 1
   go mod init github.com/yourusername/golang-todolist
   # Create directories, .gitignore, .env.example
   ```

2. **Create Foundation Files** (2 hours)
   ```bash
   # cmd/bot/main.go - entry point
   # internal/config/config.go - env loader
   # internal/domain/entity/user.go - user entity
   # internal/domain/entity/todo.go - todo entity stub
   # Makefile - basic commands
   ```

3. **Database Setup** (1 hour)
   ```bash
   # migrations/001_users.sql
   # migrations/002_todos.sql
   # Test migrations apply correctly
   ```

4. **Basic API Setup** (1 hour)
   ```bash
   # internal/adapter/driving/http/server.go
   # internal/adapter/driving/http/handlers.go
   # Health check endpoint
   ```

5. **Basic Bot Setup** (30 min)
   ```bash
   # internal/adapter/driving/telegram/bot.go
   # /start command
   ```

#### Step 2: Use Orchestrator for Features (12 hours)

Once foundation is ready:
```bash
> /droid orchestrator
> Implement Feature 1: Todo CRUD operations
# Let orchestrator build on your foundation

> /droid orchestrator
> Implement Feature 2: Search and filters

> /droid orchestrator
> Implement Feature 3: AI/NLP integration
```

### Benefits of Option B
- ✅ **Hands-on Learning**: Understand architecture deeply
- ✅ **Customization**: Foundation exactly as you want
- ✅ **Hybrid Approach**: Manual + automated
- ✅ **Flexibility**: Choose what to automate

---

## Option C: Traditional Manual Development 🐢

**Build everything manually without orchestrator**

### Why This Approach?
- For learning purposes
- Maximum control
- No dependency on Factory.ai
- Takes ~40-50 hours

### Not Recommended Because:
- ❌ Slower (3-4x longer)
- ❌ No automatic quality checks
- ❌ Manual coordination needed
- ❌ Easy to violate architecture
- ❌ Tests often written after (or never)

If you choose this path, follow the existing docs in order:
1. `docs/01-architecture-overview.md`
2. `docs/02-directory-structure.md`
3. `docs/03-hexagonal-architecture.md`
4. etc.

---

## My Recommendation 🎯

### **Use Option A: Automated with Orchestrator**

**Why?**
1. **Fastest**: 14 hours vs 40+ hours manual
2. **Best Quality**: TDD + architecture enforced
3. **Learning**: Watch agents apply best practices
4. **Production Ready**: Deployed and tested
5. **Reproducible**: Same process for future features

### **Phased Approach**

```
Week 1:
├── Day 1: Setup project structure (30 min)
├── Day 1: Configure Linear and Factory.ai (20 min)
├── Day 1-2: Phase 1 - Foundation (3 hours)
├── Day 2-3: Phase 2 - Todo CRUD (3 hours)

Week 2:
├── Day 1-2: Phase 3 - Advanced features (3 hours)
├── Day 2-3: Phase 4 - AI/NLP (3 hours)
├── Day 3-4: Polish and optimize (2 hours)
└── Day 4: Final testing and documentation

Result: Production-ready app in ~2 weeks of part-time work
```

---

## Next Steps - Getting Started Today

### Immediate Actions (30 minutes)

```bash
# 1. Initialize Go project
cd /Users/tway/Projects/golang-todolist
go mod init github.com/yourusername/golang-todolist

# 2. Create directory structure
./orchestrator/scripts/create-project-structure.sh  # (we'll create this)

# 3. Setup Git
git init
git add .
git commit -m "chore: initial project structure with orchestrator"

# 4. Configure Linear
# - Go to Linear
# - Create labels (from orchestrator/README.md)
# - Configure workflow states

# 5. Connect Factory.ai
# - Go to app.factory.ai/settings/integrations
# - Connect Linear

# 6. Test orchestrator
droid
> /droid orchestrator
> Hello! Ready to build the foundation?
```

### First Feature (3 hours)

```bash
> /droid orchestrator
> Implement foundation:
> - Main entry point
> - Configuration from .env
> - User entity
> - Health check endpoint
> - /start command
> 
> Deploy to Railway when done.

# Watch orchestrator work through 4 phases
# Result: Foundation deployed and working
```

---

## Create Helper Script

Let me create a quick initialization script:

```bash
#!/bin/bash
# orchestrator/scripts/init-project.sh

echo "🚀 Initializing Golang Todo Bot Project"

# Check if go.mod exists
if [ -f "go.mod" ]; then
  echo "✅ go.mod already exists"
else
  echo "Creating go.mod..."
  go mod init github.com/yourusername/golang-todolist
fi

# Create directory structure
echo "Creating directory structure..."
mkdir -p cmd/bot
mkdir -p internal/domain/{entity,service,port/{input,output}}
mkdir -p internal/adapter/driving/{http,telegram}
mkdir -p internal/adapter/driven/{postgres,perplexity,memory}
mkdir -p internal/{config,i18n}
mkdir -p features
mkdir -p test/{bdd,unit/{domain,adapter},integration,mocks}
mkdir -p migrations templates prompts

echo "✅ Directory structure created"

# Create .gitignore if not exists
if [ ! -f ".gitignore" ]; then
  echo "Creating .gitignore..."
  cat > .gitignore << 'GITIGNORE'
# Binaries
*.exe
bin/
build/

# Test & Coverage
*.test
*.out
coverage*.html

# Environment
.env
.env.*
!.env.example

# IDEs
.idea/
.vscode/

# OS
.DS_Store

# Go
vendor/

# Temporary
tmp/
*.log

# Factory.ai artifacts
~/.factory/artifacts/
GITIGNORE
  echo "✅ .gitignore created"
fi

# Create .env.example if not exists
if [ ! -f ".env.example" ]; then
  echo "Creating .env.example..."
  cat > .env.example << 'ENVFILE'
TELEGRAM_BOT_TOKEN=your_token_here
DATABASE_URL=postgresql://user:pass@host:5432/dbname
PERPLEXITY_API_KEY=your_key_here
PORT=8080
LOG_LEVEL=info
JWT_SECRET=your_jwt_secret_min_32_chars
ENVFILE
  echo "✅ .env.example created"
  echo "⚠️  Copy .env.example to .env and add your credentials"
fi

# Initialize git if not exists
if [ ! -d ".git" ]; then
  echo "Initializing git..."
  git init
  echo "✅ Git initialized"
fi

echo ""
echo "✅ Project initialization complete!"
echo ""
echo "Next steps:"
echo "1. Copy .env.example to .env and add credentials"
echo "2. Configure Linear (see orchestrator/README.md)"
echo "3. Connect Factory.ai to Linear"
echo "4. Run: droid"
echo "5. Switch to orchestrator: /droid orchestrator"
echo "6. Start first feature!"
```

Would you like me to:
1. Create the init-project.sh script?
2. Create a detailed step-by-step guide for your first orchestrated feature?
3. Set up the foundation files manually so you can start immediately?

**My strong recommendation**: Use Option A with the orchestrator. It will save you weeks of development time and ensure proper architecture from day 1.
