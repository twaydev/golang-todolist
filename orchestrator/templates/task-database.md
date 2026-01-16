# [Database] Create schema and repository for {Feature}

## Agent
**database-agent**

## Phase
Phase 2 - GREEN State (Parallel with domain-logic-agent)

## Objective
Design PostgreSQL schema with RLS policies and implement repository following the domain port interface.

## Prerequisites
- Phase 1 complete (tests are RED)
- Domain entity structure available (from domain-logic-agent)

## Tasks
1. **Create Migrations** (`app/migrations/00X_{feature}.sql`)
   - Table definition with proper constraints
   - Primary keys (UUID)
   - Foreign keys with CASCADE rules
   - Check constraints for enums
   - NOT NULL where appropriate
   - Unique constraints
   - Include DOWN migration

2. **Add Indexes** (`app/migrations/00X_{feature}_indexes.sql`)
   - B-tree indexes for common queries
   - GIN indexes for JSONB/arrays
   - Partial indexes where beneficial
   - Full-text search indexes if needed

3. **Enable RLS Policies** (`app/migrations/00X_{feature}_rls.sql`)
   - Enable RLS on tables
   - Policy: Users can only access their own data
   - Service role bypass for admin operations
   - Test policies with different users

4. **Implement Repository** (`app/internal/adapter/driven/postgres/{entity}_repo.go`)
   - Implement port interface from domain
   - Use pgx/v5 with connection pooling
   - Parameterized queries (prevent SQL injection)
   - Context-aware operations
   - Map PostgreSQL errors to domain errors
   - Transaction support where needed

5. **Test Migrations**
   ```bash
   migrate -database "$DATABASE_URL" -path ./migrations up
   migrate -database "$DATABASE_URL" -path ./migrations down
   ```

## Performance Targets
- INSERT single row: <10ms
- SELECT by ID: <5ms
- LIST 100 rows: <50ms
- SEARCH with full-text: <100ms

## Skills Used
- postgresql/advanced
- supabase/rls
- database/migrations
- database/optimization

## Output
- `app/migrations/00X_{feature}.sql` ✅
- `app/migrations/00X_{feature}_down.sql` ✅
- `app/migrations/00X_{feature}_indexes.sql` ✅
- `app/migrations/00X_{feature}_rls.sql` ✅
- `app/internal/adapter/driven/postgres/{entity}_repo.go` ✅
- Migrations apply successfully ✅

## Completion Signal
Post to Linear:
```
✅ database-agent complete

Files created:
- app/migrations/00X_{feature}.sql (UP/DOWN)
- app/migrations/00X_{feature}_indexes.sql
- app/migrations/00X_{feature}_rls.sql
- app/internal/adapter/driven/postgres/{entity}_repo.go

Migration status: Applied successfully ✅
RLS policies: Enabled and tested ✅
Repository: Implements port interface ✅
Performance: All queries < 100ms ✅

Ready for Phase 3 (adapters).
```

## Checkpoint Validation
Run: `orchestrator/scripts/validate-phase.sh 2`
- Expected: All tests pass (GREEN state)
- Proceed to Phase 3 when validated (and domain-logic-agent completes)

## References
- `.factory/droids/database-agent.yaml`
- `docs/15-database-schema.md`
- `docs/11-database-layer.md`
