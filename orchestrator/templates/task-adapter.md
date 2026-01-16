# [Adapter] Implement REST API handlers for {Feature}

## Agent
**api-adapter-agent**

## Phase
Phase 3 - Adapters

## Objective
Implement driving adapters (Echo REST API) that translate external HTTP requests to domain service calls.

## Prerequisites
- Phase 2 complete (domain and database ready)
- Domain services available in `app/internal/domain/service/`
- Port interfaces defined

## Tasks
1. **REST API Handler** (`app/internal/adapter/driving/http/handlers.go`)
   - Bind and validate request
   - Map DTO to domain types
   - Call domain service
   - Map domain response to DTO
   - Return appropriate HTTP status

2. **API DTOs** (`app/internal/adapter/driving/http/dto.go`)
   - Request DTO with validation tags
   - Response DTO with JSON tags
   - Mapping functions (DTO <-> Domain)

3. **API Routes** (`app/internal/adapter/driving/http/routes.go`)
   - Add new endpoint(s)
   - Apply middleware (auth, logging)
   - Document with comments

4. **Integration Tests** (`test/integration/http_test.go`)
   - Test HTTP endpoints with httptest
   - Test success cases
   - Test validation errors
   - Test error handling

## Architecture Rules
- NO business logic in adapters
- Only translation (external <-> domain)
- Map domain errors to HTTP status codes
- Validate requests before calling domain

## Error Mapping
```go
domain.ErrNotFound     -> 404 Not Found
domain.ErrInvalidInput -> 400 Bad Request
domain.ErrUnauthorized -> 401 Unauthorized
domain.ErrForbidden    -> 403 Forbidden
domain.ErrConflict     -> 409 Conflict
Other errors           -> 500 Internal Server Error
```

## Skills Used
- golang/echo-framework
- rest-api/design
- authentication/jwt

## Output
- `app/internal/adapter/driving/http/handlers.go`
- `app/internal/adapter/driving/http/dto.go`
- `app/internal/adapter/driving/http/routes.go`
- `test/integration/http_test.go`
- API endpoints working

## Completion Signal
Post to Linear:
```
api-adapter-agent complete

Files modified:
- app/internal/adapter/driving/http/handlers.go
- app/internal/adapter/driving/http/dto.go

Endpoints added:
- POST /api/v1/{endpoint}
- GET /api/v1/{endpoint}

Integration tests: {X} passed

Ready for Phase 4 (infrastructure).
```

## Checkpoint Validation
Run: `orchestrator/scripts/validate-phase.sh 3`
- Expected: Integration tests pass
- Proceed to Phase 4 when validated

## References
- `.factory/droids/api-adapter-agent.yaml`
- `docs/09-echo-rest-api.md`
