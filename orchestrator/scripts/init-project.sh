#!/bin/bash
# Initialize Golang REST API Skeleton Project
# Usage: ./init-project.sh
#
# Creates a production-ready skeleton with:
# - Go + Echo Framework (REST API)
# - PostgreSQL + Supabase (Database with RLS)
# - JWT Authentication
# - Hexagonal Architecture
# - TDD with Godog + Testify
# - GitHub Actions (CI/CD)
# - Railway (Deployment)
# - Health check endpoint (testable immediately)

set -e

echo "Initializing Golang REST API Skeleton"
echo ""

# Check if we're in the right directory
if [ ! -d ".factory" ]; then
  echo "Error: .factory directory not found"
  echo "Please run this script from the project root directory"
  exit 1
fi

# Check if go.mod exists
if [ -f "go.mod" ]; then
  echo "go.mod already exists"
else
  echo "Creating go.mod..."
  read -p "Enter your GitHub username: " github_user
  read -p "Enter project name (e.g., myapp): " project_name
  go mod init github.com/${github_user}/${project_name}
  echo "go.mod created"
fi

# Create directory structure
echo ""
echo "Creating directory structure..."

# Core directories
mkdir -p app/cmd/api
mkdir -p app/internal/domain/{entity,service,port/{input,output}}
mkdir -p app/internal/adapter/driving/http
mkdir -p app/internal/adapter/driven/{postgres,memory}
mkdir -p app/internal/config
mkdir -p app/internal/auth

# Test directories
mkdir -p app/features
mkdir -p app/test/{bdd,unit/{domain,adapter},integration,mocks}

# Database
mkdir -p app/migrations

echo "Directory structure created"

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
EOF
  echo ".gitignore created"
else
  echo ".gitignore already exists"
fi

# Create .env.example if not exists
if [ ! -f ".env.example" ]; then
  echo ""
  echo "Creating .env.example..."
  cat > .env.example << 'EOF'
# Server Configuration
PORT=8080
ENV=development
LOG_LEVEL=info

# Database (Supabase PostgreSQL)
DATABASE_URL=postgresql://user:password@host:5432/database

# JWT Authentication
JWT_SECRET=your_jwt_secret_here_minimum_32_characters_long
JWT_EXPIRY_HOURS=24

# Railway (auto-set by Railway platform)
RAILWAY_ENVIRONMENT=
RAILWAY_PUBLIC_DOMAIN=
EOF
  echo ".env.example created"
else
  echo ".env.example already exists"
fi

# Initialize git if not exists
if [ ! -d ".git" ]; then
  echo ""
  echo "Initializing git repository..."
  git init
  echo "Git repository initialized"
else
  echo "Git repository already initialized"
fi

# Summary
echo ""
echo "================================================"
echo "Project skeleton initialized!"
echo "================================================"
echo ""
echo "Directory structure:"
echo "   app/cmd/api/              - Entry point"
echo "   app/internal/domain/      - Business logic"
echo "   app/internal/adapter/     - HTTP & DB adapters"
echo "   app/internal/auth/        - JWT authentication"
echo "   app/internal/config/      - Configuration"
echo "   app/test/                 - Tests"
echo "   app/migrations/           - Database migrations"
echo ""
echo "Next steps:"
echo ""
echo "1. Configure environment:"
echo "   cp .env.example .env"
echo "   # Edit .env with your credentials"
echo ""
echo "2. Use orchestrator to build the skeleton:"
echo "   The orchestrator will create:"
echo "   - Health check endpoint (GET /health)"
echo "   - Auth endpoints (POST /auth/login, /auth/register)"
echo "   - Protected route example"
echo "   - Database connection"
echo "   - CI/CD pipeline"
echo "   - Docker + Railway deployment"
echo ""
echo "3. After init completes, test the API:"
echo "   curl http://localhost:8080/health"
echo "   curl http://localhost:8080/api/v1/protected -H 'Authorization: Bearer <token>'"
echo ""
