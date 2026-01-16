# Multi-Agent Development Workflows

## Overview

This directory contains detailed workflows for developing the Go Todo List REST API using the multi-agent system with test-driven development and hexagonal architecture.

---

## Available Workflows

### [01-feature-implementation.md](./01-feature-implementation.md)
**Complete end-to-end feature development workflow**

- Step-by-step guide from tests to production
- Uses all 5 specialized agents
- Example: "Create Todo" feature
- RED-GREEN-REFACTOR methodology
- Hexagonal architecture enforcement
- Integration testing

**When to use**: Implementing any new feature

---

### [02-bug-fix-workflow.md](./02-bug-fix-workflow.md)
**Test-first bug fixing process**

- Reproduce bug with failing test
- Root cause analysis
- Fix implementation
- Regression testing
- Documentation updates

**When to use**: Fixing bugs or unexpected behavior

---

### [03-refactoring-workflow.md](./03-refactoring-workflow.md)
**Safe code refactoring with continuous verification**

- Test coverage requirements
- Step-by-step refactoring
- Architecture integrity checks
- Common refactoring patterns
- Rollback procedures

**When to use**: Improving code structure without changing behavior

---

### [04-deployment-workflow.md](./04-deployment-workflow.md)
**Complete deployment process to Railway**

- Local -> Staging -> Production
- Environment configuration
- CI/CD pipeline setup
- Health checks and monitoring
- Rollback procedures
- Zero-downtime deployments

**When to use**: Deploying to staging or production

---

### [05-troubleshooting-guide.md](./05-troubleshooting-guide.md)
**Comprehensive troubleshooting guide**

- Common issues by agent
- Diagnosis techniques
- Solutions and fixes
- Performance debugging
- Prevention strategies

**When to use**: Debugging issues or performance problems

---

## Quick Start

### First Feature Implementation

```bash
# 1. Initialize project
git init
go mod init github.com/yourusername/golang-todolist

# 2. Follow 01-feature-implementation.md
# Start with Test-First Agent
@test-first-agent "Write BDD tests for Create Todo via REST API"

# 3. Continue through all 6 steps:
#    Test-First -> Domain Logic -> Database -> API -> Infrastructure -> Integration
```

---

## Workflow Selection Guide

| Situation | Workflow | Agent(s) |
|-----------|----------|----------|
| New feature needed | 01-feature-implementation | All 5 agents |
| Bug reported | 02-bug-fix-workflow | Test-First + relevant agent |
| Code smells detected | 03-refactoring-workflow | Domain Logic + Test-First |
| Ready to deploy | 04-deployment-workflow | Infrastructure |
| Something broken | 05-troubleshooting-guide | Relevant agent |
| Tests failing | 05-troubleshooting-guide | Test-First |
| Performance issue | 05-troubleshooting-guide | Database/Infrastructure |

---

## Agent Responsibilities

### Test-First Agent
- Write BDD scenarios (Gherkin)
- Write step definitions
- Write unit tests
- Ensure tests fail first (RED)
- Write regression tests

**Skills**: godog, testify, mockery, bdd/gherkin, tdd/methodology

---

### Domain Logic Agent
- Implement business logic
- Define domain entities
- Create port interfaces
- Orchestrate use cases
- Make tests pass (GREEN)

**Skills**: interfaces, error-handling, DDD, hexagonal-architecture, SOLID, structs

---

### Database Agent
- Design database schema
- Write migrations
- Implement repositories
- Configure RLS policies
- Optimize queries

**Skills**: postgresql/advanced, supabase/rls, migrations, indexing, full-text-search, optimization, supabase/platform

---

### API Adapter Agent
- Implement REST API (Echo)
- Handle authentication (JWT)
- Map DTOs to domain models
- Error handling and status codes

**Skills**: echo-framework, rest-api/design, rest-api/versioning, authentication/jwt

---

### Infrastructure Agent
- Create Docker images
- Setup CI/CD pipelines
- Configure deployments
- Implement monitoring
- Manage secrets

**Skills**: github-actions, docker, multi-stage-builds, railway, monitoring/logging, secrets-management

---

## Development Principles

### 1. Test-First Always
```
Write test -> Test fails (RED) -> Implement -> Test passes (GREEN) -> Refactor
```

### 2. Hexagonal Architecture
```
Domain (core) <- Ports (interfaces) <- Adapters (infrastructure)
```
- Domain never imports infrastructure
- Use dependency injection
- Adapters depend on domain, not vice versa

### 3. Single Responsibility
- Each agent has specific concerns
- Each layer has specific purpose
- Each class has one reason to change

### 4. Continuous Integration
```
Every commit -> Tests -> Lint -> Build -> Deploy (if main)
```

---

## Complete Feature Example

### Feature: Create Todo via REST API

**Step 1: Test-First Agent**
```bash
@test-first-agent "Write BDD tests for Create Todo"
```
- Creates `features/todo_create.feature`
- Creates `test/bdd/todo_create_steps_test.go`
- Creates `test/unit/domain/todo_service_test.go`
- All tests FAIL (RED)

**Step 2: Domain Logic Agent**
```bash
@domain-logic-agent "Implement TodoService to pass tests"
```
- Creates `internal/domain/entity/todo.go`
- Creates `internal/domain/port/output/todo_repository.go`
- Creates `internal/domain/service/todo_service.go`
- All tests PASS (GREEN)

**Step 3: Database Agent**
```bash
@database-agent "Create PostgreSQL schema with RLS"
```
- Creates `migrations/001_initial_schema.sql`
- Creates `internal/adapter/driven/postgres/todo_repo.go`
- Integration tests pass

**Step 4: API Adapter Agent**
```bash
@api-adapter-agent "Implement REST API"
```
- Creates `internal/adapter/driving/http/handlers.go`
- API endpoint works

**Step 5: Infrastructure Agent**
```bash
@infrastructure-agent "Setup CI/CD and deployment"
```
- Creates `.github/workflows/ci.yml`
- Creates `Dockerfile`
- Creates `railway.toml`
- Deployed to Railway

**Step 6: Integration Testing**
```bash
# Manual verification
make test
make run
# Test API, database
```
- All systems working

---

## Best Practices

### Before Starting Work
1. Read the relevant workflow
2. Understand the full process
3. Check which agents are needed
4. Review relevant skills in `.factory/skills/`

### During Development
1. Follow workflows step-by-step
2. Run tests frequently
3. Commit after each agent completes work
4. Verify architecture boundaries

### After Completing Work
1. All tests pass
2. Code reviewed (by relevant agents)
3. Documentation updated
4. Changes committed
5. Deploy to staging first

---

## Workflow Patterns

### Pattern 1: Test-Driven Feature
```
Test-First Agent (RED)
  -> Domain Logic Agent (GREEN)
  -> Database Agent (persistence)
  -> API Adapter Agent (interface)
  -> Infrastructure Agent (deploy)
```

### Pattern 2: Bug Fix
```
Test-First Agent (reproduce)
  -> Relevant Agent (fix)
  -> Test-First Agent (regression test)
```

### Pattern 3: Refactoring
```
Test-First Agent (verify coverage)
  -> Domain Logic Agent (refactor)
  -> Test-First Agent (verify tests still pass)
```

### Pattern 4: Deploy
```
Infrastructure Agent (prepare)
  -> Deploy to Staging
  -> Test
  -> Deploy to Production
  -> Monitor
```

---

## Next Steps

1. **Read** the workflow you need
2. **Follow** step-by-step instructions
3. **Use** the appropriate agent(s)
4. **Verify** with tests
5. **Deploy** with confidence

---

## Additional Resources

### Documentation
- `.factory/README.md` - Quick start guide
- `.factory/WORKFLOW_GUIDE.md` - Overview of workflows
- `.factory/AGENT_COORDINATION.md` - Agent communication
- `.factory/skills/` - Skill references

### Architecture
- `docs/18-multi-agent-architecture.md` - System design
- `docs/19-agent-specifications.md` - Agent details
- `docs/20-ai-model-recommendations.md` - Model selection

### Examples
- Each workflow includes complete examples
- Step definitions provided
- Code snippets included
- Common issues documented

---

## Support

### Getting Help
1. Check the troubleshooting guide first
2. Review the relevant skill documentation
3. Ask the appropriate agent for guidance
4. Check logs and error messages

### Improving Workflows
These workflows are living documents. If you find issues or have suggestions:
1. Document the problem
2. Propose a solution
3. Update the workflow
4. Share with the team

---

**Remember**: These workflows are designed to ensure consistency, quality, and maintainability. Following them prevents common mistakes and ensures all agents work together effectively.

Happy coding!
