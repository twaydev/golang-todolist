# Orchestrator Quick Start Guide

## TL;DR

3 steps to automated feature development:

```bash
# 1. Configure Linear (one-time setup)
# 2. Connect Factory.ai to Linear (one-time)
# 3. Use orchestrator
droid
> /droid orchestrator
> Implement: {your feature}
```

Then watch as 6 agents automatically build your feature in ~3 hours! 🚀

---

## Step 1: Configure Linear (15 min, one-time)

### Create Labels
In Linear workspace → Settings → Labels, create:

```
Agent Labels:
✅ agent:test-first
✅ agent:domain-logic
✅ agent:database
✅ agent:adapter
✅ agent:ai-nlp
✅ agent:infrastructure

Phase Labels:
✅ phase:1-red
✅ phase:2-green
✅ phase:3-adapters
✅ phase:4-deploy

Status Labels:
✅ status:blocked
✅ status:in-progress
✅ status:review

Type Labels:
✅ type:feature
✅ type:bug
✅ type:refactor
```

### Configure Workflow States
Linear → Settings → Workflows → Add states:

```
1. Backlog
2. Ready
3. In Progress
4. Tests RED
5. Tests GREEN
6. Review
7. Done
8. Canceled
```

---

## Step 2: Connect Factory.ai (5 min, one-time)

1. Go to https://app.factory.ai/settings/integrations
2. Click "Connect Linear"
3. Authorize Factory.ai
4. Grant permissions
5. Test connection:
   ```bash
   droid
   > Use FetchUrl with a Linear issue URL
   ```

---

## Step 3: Use Orchestrator

### Basic Usage

```bash
droid
> /droid orchestrator
> Implement feature: Users can create todos with priority via REST API
>
> Requirements:
> - POST /api/v1/todos endpoint
> - Priority: low/medium/high
> - Auto-generate code
>
> Acceptance Criteria:
> - Tests pass
> - API works
> - Deployed
```

**That's it!** The orchestrator will:
- ✅ Create Linear epic
- ✅ Generate 6 tasks (one per agent)
- ✅ Execute 4 phases with validation
- ✅ Deploy to Railway
- ✅ Verify health checks

**Timeline:** ~3 hours from story to production

---

## What Happens Behind the Scenes

```
Phase 1 (30 min) - test-first-agent
├── Writes BDD scenarios
├── Creates step definitions
├── Writes unit tests
└── Validates: Tests FAIL ❌ (expected RED state)

Phase 2 (60 min) - domain-logic + database agents (parallel)
├── domain-logic-agent:
│   ├── Defines entities
│   ├── Defines ports
│   └── Implements services
├── database-agent:
│   ├── Creates migrations
│   ├── Adds indexes & RLS
│   └── Implements repositories
└── Validates: Tests PASS ✅ (GREEN state)

Phase 3 (60 min) - api-adapter + ai-nlp agents (parallel)
├── api-adapter-agent:
│   ├── Implements REST API
│   └── Implements Telegram bot
├── ai-nlp-agent:
│   └── Updates intent parsing
└── Validates: Integration tests PASS ✅

Phase 4 (30 min) - infrastructure-agent
├── Deploys to Railway
├── Verifies health checks
└── Validates: Health check 200 OK ✅

Result: Feature live in production! 🎉
```

---

## Monitor Progress

### In Linear
Open your epic in browser to see:
- Real-time agent progress
- Comments with updates
- Files changed
- Issues completed
- Blockers/questions

### Checkpoint Validation
```bash
# Orchestrator runs these automatically
./orchestrator/scripts/validate-phase.sh 1  # Tests RED
./orchestrator/scripts/validate-phase.sh 2  # Tests GREEN
./orchestrator/scripts/validate-phase.sh 3  # Integration pass
./orchestrator/scripts/validate-phase.sh 4  # Health check pass
```

---

## Common Use Cases

### Full Feature (All Layers)
```bash
> Implement: Create Todo with Priority
> Affects: Domain, Database, API, NLP, Infrastructure
```
Uses all 6 agents, 4 phases, ~3 hours

### API-Only Feature
```bash
> Implement: Export Todos to CSV
> Affects: Domain, Database, API only (no NLP)
```
Uses 4 agents, skips NLP, ~2.5 hours

### Schema Change
```bash
> Implement: Add index to todos table
> Affects: Database only
```
Uses 1 agent (database), ~45 minutes

### Bug Fix
```bash
> Fix: Todo deletion error
> Type: Bug
```
Uses test-first + affected agent, ~1 hour

---

## Troubleshooting

### Agent Reports Blocker
**You see in Linear:**
```
⚠️ BLOCKED
Reason: Missing interface definition
```

**Orchestrator automatically:**
1. Reads blocker
2. Provides clarification
3. Updates issue
4. Agent continues

**You do:** Nothing (unless orchestrator needs input)

### Checkpoint Fails
**Orchestrator:**
1. Keeps phase in progress
2. Creates sub-task for fix
3. Re-validates when fixed
4. Proceeds when passing

**You do:** Monitor Linear comments

### Manual Override Needed
```bash
droid
> /droid {specific-agent}
> [Give specific instructions]
> [Agent completes]
> /droid orchestrator
> Continue Phase {N}
```

---

## Example Session

```bash
$ droid
🤖 Droid started

> /droid orchestrator
🎭 Switched to orchestrator

> Implement feature: Users can set todo priority
>
> Requirements:
> - Add priority field to Todo entity
> - Values: low, medium, high
> - REST API: POST /api/v1/todos with priority
> - Telegram bot: Parse priority from natural language
> - Default priority: medium
>
> Acceptance Criteria:
> - [ ] Unit tests pass
> - [ ] API accepts priority field
> - [ ] Telegram bot recognizes "urgent", "important", etc.
> - [ ] Deployed to Railway

✅ Creating Linear epic: ABC-123
✅ Creating 6 agent tasks
✅ Starting Phase 1...

[test-first-agent working...]
✅ Phase 1 complete: Tests RED

[domain-logic-agent + database-agent working...]
✅ Phase 2 complete: Tests GREEN

[api-adapter-agent + ai-nlp-agent working...]
✅ Phase 3 complete: Integration tests pass

[infrastructure-agent working...]
✅ Phase 4 complete: Deployed

🎉 Feature complete: ABC-123
📍 URL: https://your-app.railway.app
⏱️  Total time: 2h 58m
```

---

## Tips & Best Practices

### ✅ Do
- Provide clear requirements upfront
- Include acceptance criteria
- Monitor Linear for blockers
- Trust the automated process
- Review at the end

### ❌ Don't
- Intervene unless needed
- Skip checkpoint validation
- Manually modify agent code during execution
- Rush the process
- Ignore blocker signals

---

## Resources

### Documentation
- **Full Guide:** `.factory/workflows/06-orchestrated-feature.md`
- **Rules:** `AGENTS.md`
- **System Overview:** `orchestrator/README.md`

### Scripts
```bash
# Validation
./orchestrator/scripts/validate-phase.sh {1-4}

# Manual epic creation
./orchestrator/scripts/create-epic.sh "Name" "Desc" "Criteria"
./orchestrator/scripts/create-tasks.sh {epic-id} "Name"
```

### Factory.ai
- https://docs.factory.ai/cli/configuration/custom-droids
- https://docs.factory.ai/onboarding/integrating-with-your-engineering-system/linear

---

## Success Checklist

After setup, verify:
- ✅ Linear labels created
- ✅ Workflow states configured
- ✅ Factory.ai connected to Linear
- ✅ Orchestrator droid exists (`.factory/droids/orchestrator.yaml`)
- ✅ AGENTS.md exists in root
- ✅ Scripts are executable (`chmod +x orchestrator/scripts/*.sh`)

Test with simple feature:
- ✅ Orchestrator creates epic
- ✅ 6 tasks generated
- ✅ Phases execute automatically
- ✅ Checkpoints validate
- ✅ Feature deployed

---

## Next Steps

1. ✅ Complete Linear setup (15 min)
2. ✅ Connect Factory.ai (5 min)
3. 🧪 Test with simple feature (1 hour)
4. 🚀 Build real features automatically!

---

**Questions?**
- Check `orchestrator/README.md`
- Review `AGENTS.md`
- Read full workflow guide
- Ask in Linear issue comments

**Ready to orchestrate?** 🎭🤖

```bash
droid
> /droid orchestrator
> Let's build something amazing!
```
