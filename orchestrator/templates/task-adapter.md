# [Adapter] Implement REST API and bot handlers for {Feature}

## Agent
**api-adapter-agent**

## Phase
Phase 3 - Adapters (Parallel with ai-nlp-agent)

## Objective
Implement driving adapters (Echo REST API and Telegram bot) that translate external requests to domain service calls.

## Prerequisites
- Phase 2 complete (domain and database ready)
- Domain services available in `internal/domain/service/`
- Port interfaces defined

## Tasks
1. **REST API Handler** (`internal/adapter/driving/http/handlers.go`)
   - Bind and validate request
   - Map DTO to domain types
   - Call domain service
   - Map domain response to DTO
   - Return appropriate HTTP status

2. **API DTOs** (`internal/adapter/driving/http/dto.go`)
   - Request DTO with validation tags
   - Response DTO with JSON tags
   - Mapping functions (DTO ↔ Domain)

3. **API Routes** (`internal/adapter/driving/http/routes.go`)
   - Add new endpoint(s)
   - Apply middleware (auth, logging)
   - Document with comments

4. **Telegram Bot Handler** (`internal/adapter/driving/telegram/handlers.go`)
   - Command handlers (e.g., /command)
   - OnText handler for natural language
   - Inline keyboard for interactive responses
   - Format responses with Markdown

5. **Integration Tests** (`test/integration/http_test.go`)
   - Test HTTP endpoints with httptest
   - Test success cases
   - Test validation errors
   - Test error handling

## Architecture Rules
- ❌ NO business logic in adapters
- ✅ Only translation (external ↔ domain)
- ✅ Map domain errors to HTTP status codes
- ✅ Validate requests before calling domain

## Skills Used
- golang/echo-framework
- golang/telebot
- rest-api/design
- authentication/jwt

## Output
- `internal/adapter/driving/http/handlers.go` ✅
- `internal/adapter/driving/http/dto.go` ✅
- `internal/adapter/driving/http/routes.go` ✅
- `internal/adapter/driving/telegram/handlers.go` ✅
- `test/integration/http_test.go` ✅
- API endpoints working ✅

## Completion Signal
Post to Linear:
```
✅ api-adapter-agent complete

Files modified:
- internal/adapter/driving/http/handlers.go
- internal/adapter/driving/http/dto.go
- internal/adapter/driving/telegram/handlers.go

Endpoints added:
- POST /api/v1/{endpoint}
- GET /api/v1/{endpoint}

Integration tests: ✅ {X} passed

Ready for Phase 4 (infrastructure).
```

## Checkpoint Validation
Run: `orchestrator/scripts/validate-phase.sh 3`
- Expected: Integration tests pass
- Proceed to Phase 4 when validated (and ai-nlp-agent completes)

## References
- `.factory/droids/api-adapter-agent.yaml`
- `docs/09-echo-rest-api.md`
- `docs/10-telegram-bot.md`
