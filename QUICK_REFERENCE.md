# Quick Reference Card

## 🚀 Get Started in 5 Minutes

```bash
# 1. Initialize project
./orchestrator/scripts/init-project.sh

# 2. Add credentials
cp .env.example .env
vim .env

# 3. Start orchestrator
droid
> /droid orchestrator
```

---

## 📋 Common Commands

### Orchestrator
```bash
droid
> /droid orchestrator               # Start orchestrator
> /droid test-first-agent          # Switch to specific agent
> /droid domain-logic-agent        # Domain implementation
```

### Development
```bash
make dev                            # Run with hot reload
make test                           # Run all tests
make test-unit                      # Unit tests only
make lint                           # Run linters
make build                          # Build binary
```

### Validation
```bash
./orchestrator/scripts/validate-phase.sh 1  # Tests RED
./orchestrator/scripts/validate-phase.sh 2  # Tests GREEN
./orchestrator/scripts/validate-phase.sh 3  # Integration
./orchestrator/scripts/validate-phase.sh 4  # Deployment
```

### Linear Helpers
```bash
./orchestrator/scripts/create-epic.sh "Feature" "Desc" "Criteria"
./orchestrator/scripts/create-tasks.sh ABC-123 "Feature Name"
```

---

## 🎭 The 4-Phase Workflow

```
Phase 1: Test-First (30 min)
└─ test-first-agent → Tests RED ❌

Phase 2: Implementation (60 min, parallel)
├─ domain-logic-agent → Domain code
└─ database-agent → Schema + repos
└─ Tests GREEN ✅

Phase 3: Adapters (60 min, parallel)
├─ api-adapter-agent → REST + Bot
└─ ai-nlp-agent → NLP parsing
└─ Integration tests PASS ✅

Phase 4: Infrastructure (30 min)
└─ infrastructure-agent → Deploy
└─ Health check PASS ✅

Total: ~3 hours per feature
```

---

## 📝 Orchestrator Usage Pattern

```bash
> /droid orchestrator
> Implement: {Feature Description}
>
> Requirements:
> - Requirement 1
> - Requirement 2
>
> Acceptance Criteria:
> - [ ] Criterion 1
> - [ ] Criterion 2
```

---

## 📊 Linear Setup (One-time)

### Labels to Create
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
type:feature
```

### Workflow States
```
Backlog → Ready → In Progress → 
Tests RED → Tests GREEN → 
Review → Done
```

---

## 🔧 Project Structure

```
golang-todolist/
├── cmd/bot/                    # Entry point
├── internal/
│   ├── domain/                 # Business logic
│   │   ├── entity/            # Entities
│   │   ├── service/           # Services
│   │   └── port/              # Interfaces
│   ├── adapter/               # Adapters
│   │   ├── driving/           # HTTP, Telegram
│   │   └── driven/            # DB, AI
│   └── config/                # Configuration
├── features/                   # BDD scenarios
├── test/                       # Tests
├── migrations/                 # DB migrations
└── orchestrator/              # Orchestration system
```

---

## 🐛 Troubleshooting

### Checkpoint Fails
```bash
# Check error
./orchestrator/scripts/validate-phase.sh {N}

# Fix issue
> /droid {relevant-agent}
> Fix: {specific problem}

# Re-validate
./orchestrator/scripts/validate-phase.sh {N}
```

### Agent Blocked
```
Check Linear comments → 
Provide clarification → 
Agent continues automatically
```

---

## 📚 Documentation Quick Links

| Document | Purpose |
|----------|---------|
| `QUICKSTART_ORCHESTRATOR.md` | Get started fast |
| `PROJECT_INIT_GUIDE.md` | Full initialization guide |
| `orchestrator/README.md` | Orchestrator system docs |
| `AGENTS.md` | Orchestration rules |
| `.factory/workflows/06-orchestrated-feature.md` | Complete workflow |
| `docs/01-architecture-overview.md` | Architecture details |

---

## ⚡ Quick Wins

### First Feature (3 hours)
```bash
> Implement foundation:
> - Main entry point
> - Configuration loader
> - Health check
> - /start command
```

### Second Feature (3 hours)
```bash
> Implement Todo CRUD:
> - Create, Read, Update, Delete
> - REST API endpoints
> - Telegram bot commands
```

---

## 🎯 Success Checklist

- [ ] Project initialized (`./init-project.sh`)
- [ ] `.env` configured with credentials
- [ ] Linear labels created
- [ ] Factory.ai connected to Linear
- [ ] Orchestrator tested
- [ ] First feature deployed

---

## 💡 Pro Tips

1. **Trust the Process**: Let orchestrator handle coordination
2. **Monitor Linear**: Watch agent progress in real-time
3. **Validate Checkpoints**: Quality gates prevent bad code
4. **Ask Questions**: Use Linear comments for clarification
5. **Learn & Iterate**: Review completed epics

---

## 🆘 Getting Help

1. Check `orchestrator/README.md`
2. Review `AGENTS.md`
3. Read workflow documentation
4. Ask in Linear issue comments
5. Review Factory.ai docs

---

**Timeline**: 3 hours per feature, story to production ⚡

**Quality**: Test-driven, architecture-enforced, production-ready ✅

**Scalability**: Same process for every feature 🔄
