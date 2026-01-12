# [Feature] {Feature Name}

## User Story
As a {user type}, I want {feature} so that {benefit}.

## Requirements
- Requirement 1: {describe requirement}
- Requirement 2: {describe requirement}
- Requirement 3: {describe requirement}

## Acceptance Criteria
- [ ] Unit tests pass for all domain services
- [ ] BDD scenarios pass for feature
- [ ] REST API endpoint works correctly
- [ ] Telegram bot can handle feature via natural language
- [ ] Data stored in PostgreSQL with RLS
- [ ] Deployed to Railway successfully
- [ ] Health checks pass
- [ ] Documentation updated

## Technical Notes
### Affected Layers
- [ ] Domain (entities, services, ports)
- [ ] Database (schema, migrations, RLS)
- [ ] REST API (Echo handlers, DTOs)
- [ ] Telegram Bot (handlers, commands)
- [ ] AI/NLP (intent parsing, prompts)
- [ ] Infrastructure (CI/CD, deployment)

### Dependencies
- Depends on: {list other features/epics}
- Blocks: {list features waiting on this}

### Estimated Timeline
- Phase 1 (Test-First): 30 minutes
- Phase 2 (Domain + Database): 60 minutes (parallel)
- Phase 3 (Adapters + AI/NLP): 60 minutes (parallel)
- Phase 4 (Infrastructure): 30 minutes
- **Total**: ~3 hours

## Architecture Compliance
- [ ] Follows hexagonal architecture principles
- [ ] No domain dependencies on infrastructure
- [ ] All external dependencies via ports
- [ ] Test-first development (RED → GREEN → REFACTOR)

## Labels
- `type:feature`
- Phases will be added by orchestrator

## Related Documentation
- See: `.factory/workflows/01-feature-implementation.md`
- See: `AGENTS.md` for orchestration rules
