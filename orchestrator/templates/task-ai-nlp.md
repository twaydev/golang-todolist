# [AI/NLP] Implement intent parsing for {Feature}

## Agent
**ai-nlp-agent**

## Phase
Phase 3 - Adapters (Parallel with api-adapter-agent)

## Objective
Implement AI-powered intent parsing using Perplexity API to enable natural language interaction for this feature.

## Prerequisites
- Phase 2 complete (domain and database ready)
- Domain entities and services available

## Tasks
1. **Update Intent Schema** (`internal/domain/entity/intent.go`)
   - Add new action type if needed
   - Add new intent data fields
   - Update ParsedIntent structure

2. **Perplexity Client** (`internal/adapter/driven/perplexity/client.go`)
   - Update or extend client methods
   - Add feature-specific parsing logic
   - Handle API errors and retries

3. **System Prompts** (`prompts/system_prompt_{lang}.txt`)
   - Update English prompt with new feature
   - Update Vietnamese prompt with new feature
   - Add examples for new intent types
   - Include feature-specific keywords

4. **Intent Service** (`internal/domain/service/intent_service.go`)
   - Update Analyze() method for new feature
   - Add feature-specific entity extraction
   - Handle ambiguous queries

5. **NLP Tests** (`test/unit/adapter/perplexity_test.go`)
   - Test intent classification for new feature
   - Test entity extraction
   - Test language detection
   - Test error handling

## Language Support
### English Keywords
- {list relevant English keywords}

### Vietnamese Keywords
- {list relevant Vietnamese keywords}

## Skills Used
- ai/perplexity-api
- nlp/intent-classification
- nlp/entity-extraction
- prompt-engineering

## Output
- `internal/domain/entity/intent.go` (updated) ✅
- `internal/adapter/driven/perplexity/client.go` (updated) ✅
- `prompts/system_prompt_en.txt` (updated) ✅
- `prompts/system_prompt_vi.txt` (updated) ✅
- `internal/domain/service/intent_service.go` (updated) ✅
- NLP tests passing ✅

## Completion Signal
Post to Linear:
```
✅ ai-nlp-agent complete

Files modified:
- internal/domain/entity/intent.go
- internal/adapter/driven/perplexity/client.go
- prompts/system_prompt_en.txt
- prompts/system_prompt_vi.txt

Intent classification accuracy: >90% ✅
Languages supported: English + Vietnamese ✅
NLP tests: ✅ {X} passed

Ready for Phase 4 (infrastructure).
```

## Checkpoint Validation
Run: `orchestrator/scripts/validate-phase.sh 3`
- Expected: Integration tests pass
- Proceed to Phase 4 when validated (and api-adapter-agent completes)

## References
- `.factory/droids/ai-nlp-agent.yaml`
- `docs/12-ai-nlp-integration.md`
