# Orchestrated Feature Implementation with Linear

## Overview
This workflow uses the orchestrator droid to coordinate all 6 specialized agents through Linear issues, providing automated task decomposition, phase coordination, and checkpoint validation.

## Prerequisites
- ✅ Linear integration configured in Factory.ai
- ✅ Linear workspace has correct labels (see AGENTS.md)
- ✅ All 6 agent droids configured in `.factory/droids/`
- ✅ Orchestrator droid created
- ✅ AGENTS.md with orchestration rules exists

## Quick Start

### 1. Start Orchestration Session
```bash
droid
> /droid orchestrator
```

### 2. Provide Feature Request
```
Implement user story: "Users can create todos with priority via REST API"

Requirements:
- POST /api/v1/todos endpoint
- Required: title (1-500 chars)
- Optional: priority (low/medium/high), description, due_date, tags
- Returns 201 with auto-generated code (YY-NNNN)
- Validates input, returns 400 for errors

Acceptance Criteria:
- [ ] Unit tests pass for TodoService.CreateTodo
- [ ] BDD scenarios pass for todo creation
- [ ] REST API endpoint works
- [ ] Telegram bot can create todos via NL
- [ ] Todos stored in PostgreSQL with RLS
- [ ] Deployed to Railway
```

### 3. Orchestrator Creates Linear Epic
The orchestrator will:
1. Parse your requirements
2. Create Linear epic with title "[Feature] Create Todo with Priority"
3. Generate 6 Linear issues (one per phase/agent)
4. Set dependencies between issues
5. Return epic URL for tracking

You can also create the epic manually using:
```bash
cd orchestrator/scripts
./create-epic.sh "Create Todo with Priority" \
  "Users can create todos with priority levels" \
  "- REST API works\n- Tests pass\n- Deployed"

# Then create tasks
./create-tasks.sh ABC-123 "Create Todo with Priority"
```

## Automated Phase Execution

### Phase 1: Test-First (30 min)
```
┌─────────────────────────────────────────┐
│ Orchestrator switches to test-first-agent│
│ Passes Linear issue URL                 │
│ Agent writes:                           │
│   - features/todo_create.feature        │
│   - test/bdd/todo_steps_test.go         │
│   - test/unit/domain/todo_service_test.go│
│ Agent runs tests (expect failures)      │
│ Agent comments: "✅ Tests RED"          │
│ Orchestrator validates checkpoint       │
│ Proceeds to Phase 2                     │
└─────────────────────────────────────────┘
```

**Checkpoint**: `./orchestrator/scripts/validate-phase.sh 1`

### Phase 2: Domain + Database (60 min, parallel)
```
┌──────────────────────┐  ┌──────────────────────┐
│ domain-logic-agent   │  │   database-agent     │
│                      │  │                      │
│ Creates:             │  │ Creates:             │
│ - entity/todo.go     │  │ - migrations/*.sql   │
│ - port/todo_repo.go  │  │ - postgres/repo.go   │
│ - service/todo.go    │  │ - RLS policies       │
│                      │  │                      │
│ Tests pass (GREEN)   │  │ Schema applied       │
└──────────────────────┘  └──────────────────────┘
         │                          │
         └────────┬─────────────────┘
                  ↓
       Orchestrator validates checkpoint
       Proceeds to Phase 3
```

**Checkpoint**: `./orchestrator/scripts/validate-phase.sh 2`

### Phase 3: Adapters + AI/NLP (60 min, parallel)
```
┌──────────────────────┐  ┌──────────────────────┐
│  api-adapter-agent   │  │    ai-nlp-agent      │
│                      │  │                      │
│ Creates:             │  │ Updates:             │
│ - http/handlers.go   │  │ - perplexity/*.go    │
│ - http/dto.go        │  │ - intent_service.go  │
│ - telegram/bot.go    │  │ - prompts/*.txt      │
│                      │  │                      │
│ Integration tests ✅  │  │ NLP accuracy >90%    │
└──────────────────────┘  └──────────────────────┘
         │                          │
         └────────┬─────────────────┘
                  ↓
       Orchestrator validates checkpoint
       Proceeds to Phase 4
```

**Checkpoint**: `./orchestrator/scripts/validate-phase.sh 3`

### Phase 4: Infrastructure (30 min)
```
┌─────────────────────────────────────────┐
│     infrastructure-agent                 │
│                                         │
│ Reviews:                                │
│   - .github/workflows/*.yml             │
│   - Dockerfile                          │
│                                         │
│ Deploys:                                │
│   railway up                            │
│                                         │
│ Validates:                              │
│   curl /health → 200 OK                 │
│                                         │
│ Updates epic: Done ✅                   │
└─────────────────────────────────────────┘
```

**Checkpoint**: `./orchestrator/scripts/validate-phase.sh 4`

## Monitoring Progress

### Linear Dashboard
Open your Linear epic in browser to see:
- Overall epic progress percentage
- Each phase's issue status
- Agent comments with updates
- Files changed (via GitHub commits)
- Blockers and questions

### Real-time Status
```bash
# Check current phase
cat /tmp/orchestrator-status.txt

# View latest agent output
tail -f /tmp/orchestrator-agent.log

# Check Linear issue
# Use FetchUrl in droid with issue URL
```

## Timeline Example

For "Create Todo with Priority" feature:
```
00:00 ━━ Start: Orchestrator creates epic + 6 issues
00:05 ━━ Phase 1 Start: test-first-agent
00:35 ━━ Phase 1 Done: Tests RED ✅
00:36 ━━ Phase 2 Start: domain + database (parallel)
01:36 ━━ Phase 2 Done: Tests GREEN ✅
01:37 ━━ Phase 3 Start: adapter + ai-nlp (parallel)
02:37 ━━ Phase 3 Done: Integration tests pass ✅
02:38 ━━ Phase 4 Start: infrastructure
03:08 ━━ Phase 4 Done: Health check pass ✅
03:10 ━━ Complete: Epic Done, feature live

Total: ~3 hours from story to production
```

## Verification After Completion

### 1. Run All Tests
```bash
make test

# Should show:
# ✅ Unit tests: X passed
# ✅ BDD tests: Y scenarios passed
# ✅ Integration tests: Z passed
```

### 2. Test REST API
```bash
# Local
curl -X POST http://localhost:8080/api/v1/todos \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test orchestration",
    "priority": "high",
    "tags": ["test"]
  }'

# Production
curl -X POST https://{app}.railway.app/api/v1/todos \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test orchestration",
    "priority": "high"
  }'
```

### 3. Test Telegram Bot
Send message: "Create high priority todo: Test orchestration"  
Bot should create todo with high priority.

### 4. Verify Database
```bash
psql $DATABASE_URL -c "
  SELECT code, title, priority 
  FROM todos 
  ORDER BY created_at DESC 
  LIMIT 5;
"
```

## Troubleshooting

### Agent Reports Blocker
```
⚠️ BLOCKED
Reason: Missing interface definition for XYZ
```

**Orchestrator Response**:
1. Reviews blocker reason
2. Clarifies requirements
3. Updates Linear issue description
4. Notifies agent to continue

**Your Action**: Monitor Linear comments, provide input if needed

### Checkpoint Validation Fails
```bash
❌ Phase 2 invalid: Tests should pass but they're failing
```

**Orchestrator Response**:
1. Keeps phase in "In Progress"
2. Creates sub-task for fix
3. Waits for fix completion
4. Re-runs validation
5. Proceeds when passing

**Your Action**: Review test failures in Linear comments

### Manual Override Needed
If orchestrator needs guidance:
```bash
droid
> /droid {specific-agent}
> Fix the issue with {specific problem}
> [Provide detailed instructions]
```

Then return to orchestrator:
```bash
> /droid orchestrator
> Continue with Phase {N}
```

## Benefits

### ✅ Automated Coordination
- Orchestrator handles agent sequencing
- No manual handoffs needed
- Parallel execution where possible
- Checkpoint gates ensure quality

### ✅ Full Visibility
- All work tracked in Linear
- Real-time status updates
- Complete audit trail in comments
- Easy to see who did what when

### ✅ Quality Assurance
- Tests written first (RED state)
- Tests must pass (GREEN state)
- Integration validated at boundaries
- Deployment verified with health checks

### ✅ Time Savings
- 3-hour feature vs days of manual work
- No coordination overhead
- Automatic error detection
- Consistent process every time

### ✅ Reproducible
- Same workflow for every feature
- Documented in AGENTS.md
- Scripts for validation
- Templates for consistency

## Advanced Usage

### Multiple Concurrent Features
You can run multiple orchestrations simultaneously:
```bash
# Terminal 1
droid
> /droid orchestrator
> Feature A: Create priority field

# Terminal 2
droid
> /droid orchestrator
> Feature B: Add due date reminders
```

Each gets its own Linear epic and independent phases.

### Skipping Phases
For simple changes (e.g., just database):
```bash
> /droid orchestrator
> Schema change only: Add index to todos table
> Skip phases: 1, 3, 4
```

Orchestrator will only run Phase 2 (database-agent).

### Custom Workflows
For non-standard features, reference different workflow:
```bash
> /droid orchestrator
> Use workflow: .factory/workflows/02-bug-fix-workflow.md
> Fix bug in todo creation
```

## Best Practices

### 1. Clear Requirements
Provide detailed requirements upfront:
- What the feature does
- Acceptance criteria
- Edge cases to handle
- Performance requirements

### 2. Monitor Progress
- Check Linear epic regularly
- Read agent comments
- Watch for blockers
- Provide clarifications promptly

### 3. Trust the Process
- Let agents handle their specialties
- Don't intervene unless needed
- Checkpoints ensure quality
- Review at the end

### 4. Learn and Iterate
- Review completed epics
- Note what worked well
- Update templates if needed
- Improve AGENTS.md rules

## Related Documentation

- `AGENTS.md` - Orchestration rules and phase definitions
- `.factory/workflows/01-feature-implementation.md` - Detailed 7-step workflow
- `.factory/droids/orchestrator.yaml` - Orchestrator droid configuration
- `orchestrator/templates/` - Linear task templates
- `orchestrator/scripts/` - Validation and helper scripts

## Getting Help

### Common Issues
See: `.factory/workflows/05-troubleshooting-guide.md`

### Questions
1. Check AGENTS.md for orchestration rules
2. Review orchestrator droid instructions
3. Ask in Linear issue comments
4. Escalate to human if needed

---

**Happy Orchestrating!** 🎭🤖

The orchestrator is your conductor, the agents are your orchestra, and Linear is your score. Together they create beautiful code, automatically.
