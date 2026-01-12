# Agent Orchestration Rules

## Workflow Phases

### Phase 1: Test-First (Sequential) - RED State
**Duration**: ~30 minutes  
**Agent**: test-first-agent  
**Linear Label**: `agent:test-first`, `phase:1-red`

**Input**: 
- User story from Linear epic
- Requirements and acceptance criteria

**Tasks**:
1. Write Gherkin feature file (features/*.feature)
2. Create step definitions (test/bdd/*_steps_test.go)
3. Write unit test stubs (test/unit/domain/*_test.go)
4. Run tests: `go test ./test/... -v`

**Output**: 
- All tests execute and FAIL (RED state)
- Comment on Linear issue: "✅ Tests RED. Files: {...}"

**Checkpoint**: 
```bash
orchestrator/scripts/validate-phase.sh 1
# Expect: Tests fail as expected
```

**Proceed to Phase 2**: When checkpoint passes

---

### Phase 2: Implementation (Parallel) - GREEN State
**Duration**: ~45-60 minutes  
**Agents**: domain-logic-agent + database-agent  
**Linear Labels**: `agent:domain-logic`, `agent:database`, `phase:2-green`

#### Domain Logic Agent Task:
**Input**: Failing tests from Phase 1

**Tasks**:
1. Define entities (internal/domain/entity/*.go)
2. Define port interfaces (internal/domain/port/output/*.go)
3. Implement services (internal/domain/service/*.go)
4. Run tests: `go test ./test/unit/domain/... -v`

**Output**: All unit tests PASS (GREEN state)

#### Database Agent Task (Parallel):
**Input**: Domain entities structure

**Tasks**:
1. Create migrations (migrations/*.sql)
2. Implement repositories (internal/adapter/driven/postgres/*_repo.go)
3. Enable RLS policies
4. Test migrations: `migrate up && migrate down`

**Output**: Schema created, repos implemented

**Checkpoint**:
```bash
orchestrator/scripts/validate-phase.sh 2
# Expect: All unit tests pass
```

**Proceed to Phase 3**: When both agents complete AND checkpoint passes

---

### Phase 3: Adapters (Parallel)
**Duration**: ~45-60 minutes  
**Agents**: api-adapter-agent + ai-nlp-agent  
**Linear Labels**: `agent:adapter`, `agent:ai-nlp`, `phase:3-adapters`

#### API Adapter Agent Task:
**Tasks**:
1. Implement REST API (internal/adapter/driving/http/*.go)
2. Implement Telegram bot (internal/adapter/driving/telegram/*.go)
3. Create DTOs and mapping
4. Add middleware

**Output**: API endpoints and bot handlers working

#### AI/NLP Agent Task (Parallel):
**Tasks**:
1. Implement Perplexity client (internal/adapter/driven/perplexity/*.go)
2. Create intent service (internal/domain/service/intent_service.go)
3. Design prompts (prompts/*.txt)

**Output**: Natural language parsing working

**Checkpoint**:
```bash
orchestrator/scripts/validate-phase.sh 3
# Expect: Integration tests pass
```

**Proceed to Phase 4**: When both complete AND checkpoint passes

---

### Phase 4: Infrastructure (Sequential)
**Duration**: ~30 minutes  
**Agent**: infrastructure-agent  
**Linear Label**: `agent:infrastructure`, `phase:4-deploy`

**Tasks**:
1. Update CI/CD if needed (.github/workflows/*.yml)
2. Update Dockerfile if needed
3. Deploy to Railway: `railway up`
4. Verify health check: `curl https://app.railway.app/health`

**Checkpoint**:
```bash
orchestrator/scripts/validate-phase.sh 4
# Expect: Health check returns 200 OK
```

**Mark epic Done**: When checkpoint passes

---

## Agent Communication Protocol

### Completion Signal
Agents post to Linear issue:
```
✅ {AgentName} complete

Files changed:
- path/to/file1.go
- path/to/file2.go

Tests:
- Unit: ✅ 15 passed
- Integration: ✅ 3 passed

Ready for next phase.
```

### Blocker Signal
```
⚠️ BLOCKED

Reason: Missing interface definition for XYZ
Needs: @orchestrator to clarify requirements

Cannot proceed until resolved.
```

### Question Signal
```
❓ Question for @orchestrator

Which priority enum values to support?
Options: low/medium/high or p1/p2/p3/p4?

Waiting for guidance.
```

## Orchestrator Responses

### To Blockers
1. Read blocker reason
2. Clarify requirements
3. Update Linear issue description
4. Notify agent: "Updated requirements, please proceed"

### To Questions
1. Review question
2. Check existing docs/architecture decisions
3. Provide clear answer in Linear comment
4. Update AGENTS.md if it's a common question

## Task Decomposition Rules

### Feature Type: CRUD Endpoint
**Affects**: Domain, Database, API Adapter  
**Skip**: AI/NLP (unless natural language needed)  
**Phases**: 1 → 2 (Domain + DB) → 3 (API only) → 4

### Feature Type: Natural Language Feature
**Affects**: All agents  
**Phases**: 1 → 2 → 3 (API + NLP) → 4

### Feature Type: Schema Change
**Affects**: Database, Domain  
**Phases**: 1 → 2 (Domain + DB) → (skip 3) → 4

### Feature Type: Deployment Configuration
**Affects**: Infrastructure only  
**Phases**: 4 only (no tests needed)

## Checkpoint Validation Scripts

Located in: `orchestrator/scripts/validate-phase.sh`

Usage: `./validate-phase.sh <phase_number>`

### Phase 1: RED state validation
```bash
#!/bin/bash
# Expect tests to fail
go test ./test/... -v > /tmp/test-output.txt 2>&1
if grep -q "FAIL" /tmp/test-output.txt; then
  echo "✅ Phase 1 valid: Tests are RED"
  exit 0
else
  echo "❌ Phase 1 invalid: Tests should fail"
  exit 1
fi
```

### Phase 2: GREEN state validation
```bash
#!/bin/bash
# Expect tests to pass
go test ./test/unit/domain/... -v
if [ $? -eq 0 ]; then
  echo "✅ Phase 2 valid: Tests are GREEN"
  exit 0
else
  echo "❌ Phase 2 invalid: Tests should pass"
  exit 1
fi
```

### Phase 3: Integration validation
```bash
#!/bin/bash
# Expect integration tests to pass
go test ./test/integration/... -v
if [ $? -eq 0 ]; then
  echo "✅ Phase 3 valid: Integration tests pass"
  exit 0
else
  echo "❌ Phase 3 invalid: Integration tests failing"
  exit 1
fi
```

### Phase 4: Deployment validation
```bash
#!/bin/bash
# Expect health check to pass
HEALTH_URL="${RAILWAY_URL}/health"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL")
if [ "$STATUS" -eq 200 ]; then
  echo "✅ Phase 4 valid: Health check passing"
  exit 0
else
  echo "❌ Phase 4 invalid: Health check failing (status: $STATUS)"
  exit 1
fi
```

## Linear Integration

### Labels Required in Linear Workspace
```
agent:test-first
agent:domain-logic
agent:database
agent:adapter
agent:ai-nlp
agent:infrastructure
phase:1-red
phase:2-green
phase:3-adapters
phase:4-deploy
status:blocked
status:in-progress
status:review
type:feature
```

### Custom Workflow States
```
- Backlog
- Ready (agent can start)
- In Progress
- Tests RED (Phase 1 complete)
- Tests GREEN (Phase 2 complete)
- Review
- Done
```

### Epic Template
```markdown
# [Feature] {Feature Name}

## User Story
As a {user type}, I want {feature} so that {benefit}.

## Requirements
- Requirement 1
- Requirement 2
- Requirement 3

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Notes
- Affects layers: {domain/database/api/nlp/infra}
- Dependencies: {other epics/features}
- Timeline: {estimated hours}
```

## Architecture Compliance

### Hexagonal Architecture Rules
1. Domain layer NEVER imports from adapters
2. All external dependencies via interfaces (ports)
3. Business logic only in domain entities and services
4. Adapters only translate, never contain logic

### Test-First Rules
1. Write tests BEFORE implementation (RED state required)
2. Make tests pass (GREEN state)
3. Refactor for quality
4. Never skip tests

### Quality Gates
- Phase 1 → 2: Tests must be RED
- Phase 2 → 3: Tests must be GREEN
- Phase 3 → 4: Integration tests must pass
- Complete: All acceptance criteria met

## Parallel Execution Guidelines

### Phase 2: Domain + Database
- Domain agent focuses on business logic
- Database agent focuses on schema and queries
- Both reference the same entity definitions
- Database agent may wait for entity structure from domain

### Phase 3: Adapter + AI/NLP
- API adapter implements driving adapters (HTTP, Telegram)
- AI/NLP agent implements driven adapter (Perplexity)
- Both reference domain interfaces
- No interdependencies between them

## Error Recovery

### If Phase Checkpoint Fails
1. Orchestrator marks phase as "Needs Fix"
2. Creates sub-task with specific issue
3. Relevant agent fixes the issue
4. Re-runs checkpoint validation
5. Proceeds only when checkpoint passes

### If Agent Reports Blocker
1. Orchestrator reviews blocker description
2. Provides clarification or missing information
3. Updates Linear issue with resolution
4. Agent resumes work

### If Integration Test Fails
1. Orchestrator identifies failing test
2. Determines which agent's code is failing
3. Creates fix task for that agent
4. Re-runs integration tests after fix
5. Proceeds when all tests pass

## Monitoring and Reporting

### Progress Tracking
- Linear epic shows overall progress
- Each issue shows phase progress
- Comments show detailed updates
- Labels indicate current state

### Metrics to Track
- Time per phase (actual vs estimated)
- Number of blockers encountered
- Checkpoint failures and retries
- Lines of code changed per phase
- Test coverage per phase

## Best Practices

### For Orchestrator
1. Always validate checkpoints before proceeding
2. Keep Linear issues updated with current status
3. Document all decisions in Linear comments
4. Handle blockers promptly
5. Run integration tests at phase boundaries

### For Specialized Agents
1. Follow the instructions in your droid YAML
2. Post completion signals to Linear
3. Report blockers immediately
4. Ask questions when requirements unclear
5. Update Linear with files changed

### For Developers
1. Monitor Linear epic for progress
2. Review agent comments for context
3. Intervene only when necessary
4. Let agents handle their specialties
5. Provide feedback to improve process
