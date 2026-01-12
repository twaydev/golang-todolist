# Orchestrator System

## Overview

The orchestrator system coordinates 6 specialized Factory.ai droids through Linear issues to implement features using a test-driven, hexagonal architecture approach.

## Quick Start

### 1. Configure Linear Integration
1. Go to https://app.factory.ai/settings/integrations
2. Connect your Linear workspace
3. Create labels in Linear (see below)

### 2. Start Orchestration
```bash
droid
> /droid orchestrator
> Implement feature: "Users can create todos with priority"
```

The orchestrator will:
- Create Linear epic
- Generate 6 phase-specific tasks
- Coordinate agent execution
- Validate checkpoints
- Deploy to production

### 3. Monitor Progress
Open your Linear epic to watch real-time progress and agent updates.

## Directory Structure

```
orchestrator/
├── README.md                    # This file
├── plans/
│   └── feature-decomposition.yaml  # Task decomposition rules
├── scripts/
│   ├── validate-phase.sh        # Checkpoint validation
│   ├── create-epic.sh           # Helper to create Linear epic
│   └── create-tasks.sh          # Helper to create agent tasks
└── templates/
    ├── epic-template.md         # Linear epic template
    ├── task-test-first.md       # Phase 1 task template
    ├── task-domain.md           # Phase 2 domain task
    ├── task-database.md         # Phase 2 database task
    ├── task-adapter.md          # Phase 3 adapter task
    ├── task-ai-nlp.md          # Phase 3 NLP task
    └── task-infrastructure.md   # Phase 4 infra task
```

## Linear Setup

### Required Labels
Create these labels in your Linear workspace:

**Agent Labels:**
- `agent:test-first`
- `agent:domain-logic`
- `agent:database`
- `agent:adapter`
- `agent:ai-nlp`
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

### Custom Workflow States
Configure these states in Linear:
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

**Output:** All tests execute and FAIL ❌

**Checkpoint:** `./scripts/validate-phase.sh 1`

---

### Phase 2: Implementation (60 min, Parallel)
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

**Output:** All tests PASS ✅

**Checkpoint:** `./scripts/validate-phase.sh 2`

---

### Phase 3: Adapters (60 min, Parallel)
**Agents:** api-adapter-agent + ai-nlp-agent  
**Goal:** Integration tests PASS

**API Adapter:**
- Implement REST API
- Implement Telegram bot
- Create DTOs

**AI/NLP Agent:**
- Update Perplexity client
- Update intent parsing
- Update prompts

**Output:** Integration tests PASS ✅

**Checkpoint:** `./scripts/validate-phase.sh 3`

---

### Phase 4: Infrastructure (30 min, Sequential)
**Agent:** infrastructure-agent  
**Goal:** Deploy to production

**Tasks:**
- Review CI/CD
- Deploy to Railway
- Verify health checks

**Output:** Health check PASS ✅

**Checkpoint:** `./scripts/validate-phase.sh 4`

---

**Total Time:** ~3 hours from story to production

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
✅ {agent} complete

Files changed:
- path/to/file.go

Tests: ✅ X passed

Ready for next phase.
```

### Blocker Signal
```
⚠️ BLOCKED

Reason: {description}
Needs: @orchestrator clarification

Cannot proceed.
```

### Question Signal
```
❓ Question for @orchestrator

{question}

Options: A, B, or C?

Waiting for guidance.
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
droid
> /droid {specific-agent}
> Fix: {specific instructions}
```

## Feature Types

The orchestrator supports different feature patterns:

1. **Full Feature** - All layers (all 6 agents)
2. **API Feature** - No NLP (skip ai-nlp-agent)
3. **Schema Change** - Database only
4. **NLP Enhancement** - Intent parsing improvements
5. **Infrastructure** - CI/CD changes only
6. **Bug Fix** - Reproduce, fix, regression test
7. **Refactoring** - Improve code structure

See `plans/feature-decomposition.yaml` for details.

## Files and Configuration

### Key Files
- **AGENTS.md** - Orchestration rules (root)
- **orchestrator.yaml** - Orchestrator droid config (.factory/droids/)
- **06-orchestrated-feature.md** - Workflow guide (.factory/workflows/)
- **linear-integration.yaml** - Linear skill (.factory/skills/)

### Templates
- `templates/epic-template.md` - Linear epic structure
- `templates/task-*.md` - Per-agent task templates

### Scripts
- `scripts/validate-phase.sh` - Phase validation
- `scripts/create-epic.sh` - Epic creation helper
- `scripts/create-tasks.sh` - Task creation helper

## Best Practices

1. **Clear Requirements** - Provide detailed user stories
2. **Monitor Progress** - Watch Linear for updates
3. **Trust Process** - Let agents handle their work
4. **Validate Checkpoints** - Don't skip validation
5. **Document Decisions** - Keep Linear updated

## Resources

- **Workflow:** `.factory/workflows/06-orchestrated-feature.md`
- **Rules:** `AGENTS.md`
- **Droids:** `.factory/droids/orchestrator.yaml`
- **Skills:** `.factory/skills/linear-integration.yaml`

## Getting Help

1. Check `AGENTS.md` for orchestration rules
2. Review `.factory/workflows/05-troubleshooting-guide.md`
3. Read agent droid configurations
4. Ask in Linear issue comments

## Example: Create Todo Feature

```bash
# 1. Start orchestrator
droid
> /droid orchestrator

# 2. Provide user story
> Implement: Users can create todos with priority via REST API
> 
> Requirements:
> - POST /api/v1/todos endpoint
> - Priority: low/medium/high
> - Auto-generate code YY-NNNN
> - Validation and error handling
>
> Acceptance Criteria:
> - Unit tests pass
> - BDD scenarios pass  
> - REST API works
> - Telegram bot supports NL
> - Deployed to Railway

# 3. Orchestrator creates Linear epic + 6 tasks
# 4. Orchestrator executes 4 phases automatically
# 5. Feature deployed in ~3 hours
```

## Timeline

```
00:00 ━━ Orchestrator creates epic + tasks
00:05 ━━ Phase 1: test-first-agent (30 min)
00:35 ━━ Phase 2: domain + database (60 min, parallel)
01:35 ━━ Phase 3: adapter + ai-nlp (60 min, parallel)
02:35 ━━ Phase 4: infrastructure (30 min)
03:05 ━━ Complete: Feature live in production ✅
```

---

**Happy Orchestrating!** 🎭

The orchestrator is your conductor, coordinating specialized agents to create beautiful, tested, production-ready code automatically.
