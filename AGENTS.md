# Agent Orchestration Rules

This document defines the rules and protocols for the multi-agent orchestration system.

## Pre-flight: MCP Integration Check

**CRITICAL:** Before starting any workflow, verify all MCP integrations are working.

```bash
./orchestrator/scripts/check-mcp.sh
```

### Required MCP Servers

| MCP Server | Purpose | Commands |
|------------|---------|----------|
| **Linear** | Task tracking | `linear_get_teams`, `linear_create_issue`, `linear_update_issue` |
| **Supabase** | Database ops | `supabase_list_projects`, `supabase_execute_sql` |
| **Railway** | Deployment | `railway_list_projects`, `railway_deploy`, `railway_set_variable` |

### Verification Sequence

1. **Linear MCP**: `linear_get_teams` → should return team list
2. **Supabase MCP**: `supabase_list_projects` → should return project info
3. **Railway MCP**: `railway_list_projects` → should return project list

If any MCP fails, check environment variables:
- `LINEAR_API_KEY`
- `SUPABASE_URL`, `SUPABASE_KEY`
- `RAILWAY_TOKEN`

---

## Agent Architecture

### Orchestrator Agent
- **Role**: Coordinates all agents via Linear issues
- **Model**: claude-3.5-sonnet
- **Responsibilities**:
  - Parse user stories
  - Create Linear epics and tasks
  - Invoke agents in correct order
  - Validate checkpoints between phases
  - Report progress to Linear

### Specialized Agents

| Agent | Phase | Focus |
|-------|-------|-------|
| test-first-agent | 1 | Write failing tests (RED) |
| domain-logic-agent | 2 | Implement entities & services |
| database-agent | 2 | Create schemas & repositories |
| api-adapter-agent | 3 | Build REST API endpoints |
| infrastructure-agent | 4 | Deploy to production |

---

## The 4-Phase Workflow

```
Phase 1 (Sequential)     Phase 2 (Parallel)       Phase 3 (Sequential)     Phase 4 (Sequential)
┌─────────────────┐     ┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│  test-first     │────▶│  domain-logic   │─┬───▶│  api-adapter    │─────▶│  infrastructure │
│  (RED tests)    │     │  (entities)     │ │    │  (HTTP)         │      │  (deploy)       │
└─────────────────┘     ├─────────────────┤ │    └─────────────────┘      └─────────────────┘
                        │  database       │─┘
                        │  (schema)       │
                        └─────────────────┘
```

### Phase Rules

1. **Phase 1 must complete before Phase 2 starts**
2. **Phase 2 agents work in parallel** (domain + database)
3. **Phase 2 must complete before Phase 3 starts**
4. **Phase 3 must complete before Phase 4 starts**
5. **Each phase has validation checkpoint**

---

## Linear Integration Protocol

### Epic Structure
```
Title: [Feature] {feature_name}
Labels: type:feature
Status: In Progress → Done
```

### Task Structure
```
Title: [{Phase}] {task_description}
Labels: agent:{agent_name}, phase:{phase_number}
Parent: Epic
```

### Agent Labels
- `agent:test-first`
- `agent:domain-logic`
- `agent:database`
- `agent:adapter`
- `agent:infrastructure`

### Phase Labels
- `phase:1-red`
- `phase:2-green`
- `phase:3-adapters`
- `phase:4-deploy`

---

## Communication Protocol

### Completion Signal
```
{agent_name} complete

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

---

## Checkpoint Validation

Run validation scripts between phases:

```bash
# After Phase 1 - expect test failures
./orchestrator/scripts/validate-phase.sh 1

# After Phase 2 - expect test passes
./orchestrator/scripts/validate-phase.sh 2

# After Phase 3 - expect integration pass
./orchestrator/scripts/validate-phase.sh 3

# After Phase 4 - expect health check pass
./orchestrator/scripts/validate-phase.sh 4
```

### Validation Rules
- **Do NOT proceed to next phase if validation fails**
- Create sub-task for fix if blocked
- Re-run validation after fix
- Update Linear issue with validation results

---

## MCP Command Reference

### Linear MCP
| Command | Description |
|---------|-------------|
| `linear_get_teams` | List available teams |
| `linear_get_labels` | List issue labels |
| `linear_create_issue` | Create new issue |
| `linear_update_issue` | Update issue status |
| `linear_add_comment` | Add comment to issue |
| `linear_get_issue` | Get issue details |

### Supabase MCP
| Command | Description |
|---------|-------------|
| `supabase_list_projects` | List all projects |
| `supabase_get_project` | Get project details |
| `supabase_list_tables` | List database tables |
| `supabase_execute_sql` | Execute SQL query |
| `supabase_get_connection_string` | Get DB connection URL |

### Railway MCP
| Command | Description |
|---------|-------------|
| `railway_list_projects` | List all projects |
| `railway_get_project` | Get project details |
| `railway_list_services` | List services |
| `railway_deploy` | Trigger deployment |
| `railway_get_deployment_status` | Check deployment status |
| `railway_set_variable` | Set environment variable |
| `railway_get_service_url` | Get public URL |

---

## Error Handling

### MCP Connection Errors
1. Check environment variables are set
2. Verify API keys are valid
3. Check service status (Linear/Supabase/Railway dashboards)
4. Restart MCP servers if needed

### Phase Failures
1. Read validation output
2. Identify failing tests/checks
3. Create sub-task in Linear
4. Fix and re-validate
5. Continue only when passing

### Deployment Failures
1. Check Railway logs via MCP
2. Verify environment variables
3. Check health endpoint
4. Review build output

---

## Local Development with Docker Compose

For local development, use Docker Compose to run the full stack (PostgreSQL, migrations, API):

### Quick Start
```bash
# Start all services (db, migrations, api)
make up

# View logs
make logs

# Stop all services
make down
```

### Available Commands
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

### Services
| Service | Port | Description |
|---------|------|-------------|
| `db` | 5433:5432 | PostgreSQL 16 with health check |
| `migrate` | - | Runs SQL migrations on startup |
| `api` | 8080:8080 | Go API server |
| `test` | - | Smoke tests (optional) |

### Testing Locally
```bash
# Start services
make up

# Wait for healthy status
make ps

# Test endpoints
curl http://localhost:8080/health
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

---

## Quick Reference

### Start New Feature
```
1. Run MCP pre-flight check
2. Start local environment: make up
3. Orchestrator creates Linear epic
4. Phase 1: test-first-agent (RED)
5. Phase 2: domain + database (GREEN) [parallel]
6. Phase 3: api-adapter-agent (integration)
7. Phase 4: infrastructure-agent (deploy)
8. Verify acceptance criteria
```

### Initialize Project
```
1. Run MCP pre-flight check
2. ./orchestrator/scripts/init-project.sh
3. Follow .factory/workflows/00-project-init.md
4. Start local dev: make up
5. Test API endpoints
6. Deploy skeleton to Railway
```

---

## Resources

- **Workflows**: `.factory/workflows/`
- **Agent Configs**: `.factory/droids/`
- **Templates**: `orchestrator/templates/`
- **Scripts**: `orchestrator/scripts/`
