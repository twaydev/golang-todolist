# Orchestrator System

## Overview

The orchestrator system coordinates 5 specialized agents through Linear issues to implement features using test-driven development and hexagonal architecture.

## Tech Stack

| Component | Technology |
|-----------|------------|
| Language | Go 1.22+ |
| HTTP Framework | Echo |
| Database | PostgreSQL / Supabase |
| Architecture | Hexagonal (Ports & Adapters) |
| Testing | Godog (BDD) + Testify |
| CI/CD | GitHub Actions |
| Deployment | Railway |
| Task Management | Linear |
| Local Development | Docker Compose |

## Required MCP Integrations

The orchestrator and all agents require these MCP servers to be configured and working:

| MCP Server | Purpose | Required For |
|------------|---------|--------------|
| **Linear MCP** | Task tracking, progress updates | All phases |
| **Supabase MCP** | Database operations, migrations | Phase 2, Phase 4 |
| **Railway MCP** | Deployment, environment variables | Phase 4 |

### Pre-flight Verification

**Before starting any workflow**, verify MCP integrations:

```bash
# Run the MCP check script
./orchestrator/scripts/check-mcp.sh
```

Or manually verify each MCP:

| MCP | Test Command | Expected |
|-----|--------------|----------|
| Linear | `linear_get_teams` | Returns team list |
| Supabase | `supabase_list_projects` | Returns project info |
| Railway | `railway_list_projects` | Returns project list |

See `.factory/workflows/00-project-init.md` for detailed verification checklist.

### Environment Variables

Ensure these are set in your environment:

```bash
# Linear
LINEAR_API_KEY=lin_api_xxxxx

# Supabase (from project settings)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJxxxxx

# Railway
RAILWAY_TOKEN=xxxxx
```

## Quick Start

### 1. Initialize Project Skeleton
```bash
./orchestrator/scripts/init-project.sh
```

This creates the directory structure. Then use the orchestrator to build the skeleton with auth:

```
Skeleton includes:
- GET  /health          -> Health check
- POST /auth/register   -> Create user
- POST /auth/login      -> Get JWT token
- GET  /api/v1/me       -> Protected route (requires token)
```

See `.factory/workflows/00-project-init.md` for the full workflow.

### 2. Start Local Development Environment
```bash
# Start PostgreSQL, run migrations, and start API
make up

# Check services are running
make ps

# View API logs
make logs
```

**Available Docker Compose Commands:**
| Command | Description |
|---------|-------------|
| `make up` | Start db, migrate, and api services |
| `make down` | Stop all services |
| `make up-all` | Build and start all services including test |
| `make up-db` | Start only PostgreSQL |
| `make logs` | Follow API logs |
| `make logs-db` | Follow database logs |
| `make ps` | Show running containers |
| `make test-docker` | Run integration tests in Docker |
| `make restart` | Restart all services |

**Services:**
| Service | Port | Description |
|---------|------|-------------|
| `db` | 5433:5432 | PostgreSQL 16 with health check |
| `migrate` | - | Runs SQL migrations on startup |
| `api` | 8080:8080 | Go API server |
| `test` | - | Smoke tests (optional) |

### 3. Configure Linear Integration
1. Open Linear workspace settings
2. Create labels (see below)
3. Configure workflow states

### 4. Test Your API
After starting services:
```bash
# Health check
curl http://localhost:8080/health

# Register user
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Protected route (use token from login)
curl http://localhost:8080/api/v1/me \
  -H "Authorization: Bearer <token>"
```

### 5. Add Your Features
Use the orchestrator to add domain-specific features on top of the skeleton.

## Directory Structure

```
orchestrator/
├── README.md                       # This file
├── plans/
│   └── feature-decomposition.yaml  # Task decomposition rules
├── scripts/
│   ├── init-project.sh             # Project initialization
│   ├── validate-phase.sh           # Checkpoint validation
│   ├── create-epic.sh              # Helper to create Linear epic
│   └── create-tasks.sh             # Helper to create agent tasks
└── templates/
    ├── epic-template.md            # Linear epic template
    ├── task-test-first.md          # Phase 1 task template
    ├── task-domain.md              # Phase 2 domain task
    ├── task-database.md            # Phase 2 database task
    ├── task-adapter.md             # Phase 3 adapter task
    └── task-infrastructure.md      # Phase 4 infra task
```

## Linear Setup

### Required Labels

**Agent Labels:**
- `agent:test-first`
- `agent:domain-logic`
- `agent:database`
- `agent:adapter`
- `agent:infrastructure`

**Phase Labels:**
- `phase:1-red`
- `phase:2-green`
- `phase:3-adapters`
- `phase:4-deploy`

**Status Labels:**
- `status:blocked`
- `status:in-progress`
- `status:review`

**Type Labels:**
- `type:feature`
- `type:bug`
- `type:refactor`
- `type:init`

### Custom Workflow States
1. Backlog
2. Ready
3. In Progress
4. Tests RED (Phase 1 complete)
5. Tests GREEN (Phase 2 complete)
6. Review
7. Done
8. Canceled

## The 4-Phase Workflow

### Phase 1: Test-First (30 min, Sequential)
**Agent:** test-first-agent
**Goal:** Write tests that FAIL (RED state)

**Tasks:**
- Write Gherkin scenarios
- Create step definitions
- Write unit test stubs
- Verify all tests fail

**Output:** All tests execute and FAIL

**Checkpoint:** `./scripts/validate-phase.sh 1`

---

### Phase 2: Implementation (45 min, Parallel)
**Agents:** domain-logic-agent + database-agent
**Goal:** Make tests PASS (GREEN state)

**Domain Agent:**
- Define entities
- Define port interfaces
- Implement services

**Database Agent:**
- Create migrations
- Add indexes and RLS
- Implement repositories

**Output:** All tests PASS

**Checkpoint:** `./scripts/validate-phase.sh 2`

---

### Phase 3: Adapters (45 min, Sequential)
**Agent:** api-adapter-agent
**Goal:** Integration tests PASS

**Tasks:**
- Implement REST API endpoints
- Create DTOs and validation
- Write integration tests

**Output:** Integration tests PASS

**Checkpoint:** `./scripts/validate-phase.sh 3`

---

### Phase 4: Infrastructure (30 min, Sequential)
**Agent:** infrastructure-agent
**Goal:** Deploy to production

**Tasks:**
- Review CI/CD
- Deploy to Railway
- Verify health checks

**Output:** Health check PASS

**Checkpoint:** `./scripts/validate-phase.sh 4`

---

**Total Time:** ~2.5 hours from story to production

## Validation Scripts

### Run Checkpoint Validation
```bash
# Validate Phase 1 (expect failures)
./scripts/validate-phase.sh 1

# Validate Phase 2 (expect success)
./scripts/validate-phase.sh 2

# Validate Phase 3 (expect integration pass)
./scripts/validate-phase.sh 3

# Validate Phase 4 (expect health check)
./scripts/validate-phase.sh 4
```

### Manual Epic Creation
```bash
# Create epic structure
./scripts/create-epic.sh \
  "Create Todo with Priority" \
  "Users can create todos with priority levels" \
  "- REST API works\n- Tests pass\n- Deployed"

# Create agent tasks
./scripts/create-tasks.sh ABC-123 "Create Todo with Priority"
```

## Agent Communication

### Completion Signal
Agents post this to Linear when done:
```
{agent} complete

Files changed:
- path/to/file.go

Tests: X passed

Ready for next phase.
```

### Blocker Signal
```
BLOCKED

Reason: {description}
Needs: @orchestrator clarification

Cannot proceed.
```

### Question Signal
```
Question for @orchestrator

{question}

Options: A, B, or C?

Waiting for guidance.
```

## Feature Types

The orchestrator supports different feature patterns:

1. **Full Feature** - All layers (all 5 agents)
2. **API Feature** - REST API feature
3. **Schema Change** - Database only
4. **Infrastructure** - CI/CD changes only
5. **Bug Fix** - Reproduce, fix, regression test
6. **Refactoring** - Improve code structure
7. **Project Init** - Initialize new project

See `plans/feature-decomposition.yaml` for details.

## Workflows

| Workflow | Description | File |
|----------|-------------|------|
| Project Init | Initialize new project | `.factory/workflows/00-project-init.md` |
| Feature Implementation | End-to-end feature | `.factory/workflows/01-feature-implementation.md` |
| Bug Fix | Test-first bug fix | `.factory/workflows/02-bug-fix-workflow.md` |
| Refactoring | Code improvement | `.factory/workflows/03-refactoring-workflow.md` |
| Deployment | Deploy to production | `.factory/workflows/04-deployment-workflow.md` |
| Troubleshooting | Debug issues | `.factory/workflows/05-troubleshooting-guide.md` |

## Files and Configuration

### Key Files
- **AGENTS.md** - Orchestration rules (root)
- **orchestrator.yaml** - Orchestrator droid config (.factory/droids/)
- **linear-integration.yaml** - Linear skill (.factory/skills/)

### Templates
- `templates/epic-template.md` - Linear epic structure
- `templates/task-*.md` - Per-agent task templates

### Scripts
- `scripts/init-project.sh` - Project initialization
- `scripts/validate-phase.sh` - Phase validation
- `scripts/create-epic.sh` - Epic creation helper
- `scripts/create-tasks.sh` - Task creation helper

## Example: Initialize Project Skeleton

```bash
# 1. Run init script (creates directories)
./orchestrator/scripts/init-project.sh

# 2. Configure environment
cp .env.example .env
vim .env

# 3. Use orchestrator to build skeleton with auth
# The orchestrator will:
# - Create Linear epic "[Init] Project Skeleton with Auth"
# - Setup infrastructure (Dockerfile, Makefile, CI/CD)
# - Create User entity and AuthService
# - Setup database with users table
# - Create auth endpoints (register, login)
# - Create protected route example
# - Deploy to Railway

# 4. Start local development environment
make up

# 5. Test the API
curl http://localhost:8080/health
curl -X POST http://localhost:8080/auth/register -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"pass123"}'
curl -X POST http://localhost:8080/auth/login -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"pass123"}'
```

## Example: Add Feature to Skeleton

After init, add your domain-specific features:

```bash
# Example: Add todo management
> Implement: Users can create todos with priority via REST API
>
> Requirements:
> - POST /api/v1/todos endpoint
> - Priority: low/medium/high
> - Validation and error handling
>
> Acceptance Criteria:
> - Unit tests pass
> - REST API works
> - Deployed to Railway

# Orchestrator creates Linear epic + 5 tasks
# Orchestrator executes 4 phases automatically
# Feature deployed in ~2.5 hours
```

## Timeline

```
00:00 ━━ Orchestrator creates epic + tasks
00:05 ━━ Phase 1: test-first-agent (30 min)
00:35 ━━ Phase 2: domain + database (45 min, parallel)
01:20 ━━ Phase 3: api-adapter (45 min)
02:05 ━━ Phase 4: infrastructure (30 min)
02:35 ━━ Complete: Feature live in production
```

## Troubleshooting

### Checkpoint Fails
1. Review error message
2. Check test output
3. Fix issue
4. Re-run validation
5. Proceed when passing

### Agent Blocked
1. Read blocker in Linear
2. Provide clarification
3. Update issue description
4. Agent continues

### Manual Override
```bash
# Invoke specific agent
@{specific-agent} "Fix: {specific instructions}"
```

## Best Practices

1. **Clear Requirements** - Provide detailed user stories
2. **Monitor Progress** - Watch Linear for updates
3. **Trust Process** - Let agents handle their work
4. **Validate Checkpoints** - Don't skip validation
5. **Document Decisions** - Keep Linear updated

## Resources

- **Workflow Guide:** `.factory/workflows/`
- **Agent Configs:** `.factory/droids/`
- **Skills:** `.factory/skills/`

---

**Happy Building!**

The orchestrator coordinates specialized agents to create tested, production-ready code automatically using TDD and hexagonal architecture.
