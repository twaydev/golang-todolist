# AI Model Recommendations

This document provides guidance on selecting the right AI model for each type of task in the multi-agent development workflow.

## Model Comparison Matrix

| Task Type | Primary Model | Alternative | Reasoning |
|-----------|--------------|-------------|-----------|
| **Test Design** | Claude 3.5 Sonnet | GPT-4o | Excellent at structured thinking, comprehensive scenarios |
| **Business Logic** | Claude 3.5 Sonnet | o1-preview | Strong reasoning, maintains architecture boundaries |
| **Database Design** | GPT-4o | Claude 3.5 | Superior SQL generation and optimization knowledge |
| **API Development** | GPT-4o | Claude 3.5 | Extensive framework knowledge, API patterns |
| **AI/NLP Integration** | Claude 3.5 Sonnet | GPT-4o | Better prompt engineering and structured output |
| **DevOps/CI/CD** | GPT-4o | Claude 3.5 | Strong DevOps knowledge, script generation |
| **Code Review** | Claude 3.5 Sonnet | GPT-4o | Detailed analysis, catches architecture violations |
| **Documentation** | GPT-4o | Claude 3.5 | Clear, comprehensive writing |
| **Refactoring** | Claude 3.5 Sonnet | o1-preview | Maintains code quality, suggests improvements |
| **Debugging** | o1-preview | Claude 3.5 | Deep reasoning, complex problem solving |

## Model Characteristics

### Claude 3.5 Sonnet (Anthropic)

**Strengths**:
- ✅ **Structured Thinking**: Excellent at systematic, step-by-step reasoning
- ✅ **Architecture Adherence**: Maintains hexagonal architecture principles
- ✅ **Clean Code**: Produces idiomatic, maintainable code
- ✅ **Long Context**: 200K token context window
- ✅ **Test Design**: Creates comprehensive, edge-case-aware tests
- ✅ **Code Analysis**: Detailed reviews with architectural insights

**Best For**:
- Test-First Agent (BDD/TDD)
- Domain Logic Agent (hexagonal architecture)
- AI/NLP Agent (prompt engineering)
- Code review and refactoring

**Limitations**:
- ⚠️ Less extensive knowledge of specific frameworks
- ⚠️ Can be verbose in explanations

**Example Use Case**:
```
Task: Implement TodoService with hexagonal architecture
Why Claude: Maintains clean separation between domain and infrastructure,
           produces well-structured code with proper interfaces
```

### GPT-4o (OpenAI)

**Strengths**:
- ✅ **Framework Knowledge**: Extensive knowledge of web frameworks, libraries
- ✅ **SQL Excellence**: Superior database design and query optimization
- ✅ **DevOps**: Strong knowledge of CI/CD tools and cloud platforms
- ✅ **API Design**: RESTful patterns, versioning, best practices
- ✅ **Documentation**: Clear, comprehensive writing
- ✅ **Fast**: Lower latency than Claude

**Best For**:
- Database Schema Agent (PostgreSQL/Supabase)
- HTTP/Bot Adapter Agent (Echo, Telegram)
- Infrastructure Agent (CI/CD, Docker)
- Documentation writing

**Limitations**:
- ⚠️ Can occasionally violate architecture boundaries
- ⚠️ May skip edge cases in testing

**Example Use Case**:
```
Task: Design database schema with RLS and full-text search
Why GPT-4o: Excellent SQL knowledge, understands Supabase specifics,
            generates optimized queries and indexes
```

### o1-preview (OpenAI Reasoning Model)

**Strengths**:
- ✅ **Deep Reasoning**: Excellent for complex logic and algorithms
- ✅ **Problem Solving**: Handles intricate business rules
- ✅ **Debugging**: Traces complex issues through code
- ✅ **Optimization**: Finds performance improvements
- ✅ **Mathematical**: Strong with calculations and algorithms

**Best For**:
- Complex business logic (alternative to Claude)
- Debugging difficult issues
- Algorithm optimization
- Performance tuning

**Limitations**:
- ⚠️ Slower than other models
- ⚠️ Higher cost per token
- ⚠️ Less knowledge of specific frameworks
- ⚠️ Overkill for simple tasks

**Example Use Case**:
```
Task: Debug race condition in concurrent todo creation
Why o1: Deep reasoning traces through goroutines, identifies subtle
        synchronization issues that other models might miss
```

### Perplexity Sonar (for Intent Analysis)

**Strengths**:
- ✅ **Real-time Information**: Can access current data
- ✅ **Natural Language**: Excellent at parsing user intent
- ✅ **Multilingual**: Good support for English/Vietnamese
- ✅ **Fast**: Low latency responses

**Best For**:
- Actual production intent analysis
- Natural language parsing
- User message understanding

**Limitations**:
- ⚠️ Not for code generation
- ⚠️ Requires specific prompt engineering

**Example Use Case**:
```
Task: Parse "Buy milk tomorrow #groceries" to structured intent
Why Perplexity: Fast, accurate intent parsing, handles multilingual input
```

## Task-Specific Recommendations

### Test Design (Test-First Agent)

**Primary: Claude 3.5 Sonnet**

Why:
- Creates comprehensive test scenarios
- Thinks systematically about edge cases
- Produces clean, well-structured test code
- Excellent at Gherkin syntax
- Considers security and validation

Example Prompt:
```
You are a Test-First Development specialist using Claude 3.5 Sonnet.
Write comprehensive BDD scenarios for "Create Todo via REST API" feature.
Include edge cases, validation errors, and concurrent access scenarios.
```

**Alternative: GPT-4o**
- Use when you need tests for specific frameworks
- Good for API integration tests

### Business Logic (Domain Logic Agent)

**Primary: Claude 3.5 Sonnet**

Why:
- Maintains hexagonal architecture boundaries
- Produces clean, idiomatic Go code
- Strong understanding of DDD principles
- Doesn't leak infrastructure into domain
- Good error handling patterns

Example Prompt:
```
You are a DDD specialist using Claude 3.5 Sonnet.
Implement TodoService with NO infrastructure dependencies.
All external systems via ports (interfaces).
```

**Alternative: o1-preview**
- Use for complex business rules
- Better for algorithmic logic
- Good for optimization

### Database Design (Database Schema Agent)

**Primary: GPT-4o**

Why:
- Superior SQL knowledge
- Understands PostgreSQL advanced features
- Knows Supabase specifics
- Excellent at query optimization
- Good with RLS policies

Example Prompt:
```
You are a PostgreSQL expert using GPT-4o.
Design schema with RLS, full-text search, and auto-generated codes.
Create optimized indexes for list, search, and filter operations.
```

**Alternative: Claude 3.5 Sonnet**
- Use for complex data modeling
- Good for explaining trade-offs

### API Development (HTTP/Bot Adapter Agent)

**Primary: GPT-4o**

Why:
- Extensive Echo framework knowledge
- Knows Telegram bot API well
- Good at REST API patterns
- Understands middleware patterns
- Strong security knowledge

Example Prompt:
```
You are a Go web framework expert using GPT-4o.
Implement Echo REST API with JWT auth, CORS, rate limiting.
Create DTOs that map cleanly to domain entities.
```

**Alternative: Claude 3.5 Sonnet**
- Use when architecture adherence is critical
- Better at avoiding business logic in adapters

### AI/NLP Integration (AI/NLP Agent)

**Primary: Claude 3.5 Sonnet**

Why:
- Excellent at prompt engineering
- Good with structured output parsing
- Understands context management
- Strong at multilingual considerations
- Better at handling ambiguity

Example Prompt:
```
You are an NLP specialist using Claude 3.5 Sonnet.
Design intent parsing with Perplexity API.
Handle English/Vietnamese with date parsing and priority extraction.
```

**Alternative: GPT-4o**
- Use for integration code
- Good at error handling patterns

### DevOps/CI/CD (Infrastructure Agent)

**Primary: GPT-4o**

Why:
- Strong GitHub Actions knowledge
- Docker expertise
- Knows Railway platform
- Good at shell scripting
- Security best practices

Example Prompt:
```
You are a DevOps expert using GPT-4o.
Create GitHub Actions CI/CD pipeline with parallel test jobs.
Build multi-stage Docker image with security hardening.
```

**Alternative: Claude 3.5 Sonnet**
- Use for complex workflow logic
- Better at explaining trade-offs

## Cost Considerations

### Token Costs (Approximate)

| Model | Input Cost | Output Cost | Context Window |
|-------|-----------|-------------|----------------|
| Claude 3.5 Sonnet | $3/1M | $15/1M | 200K tokens |
| GPT-4o | $2.50/1M | $10/1M | 128K tokens |
| o1-preview | $15/1M | $60/1M | 128K tokens |
| Perplexity Sonar | $1/1M | $1/1M | 127K tokens |

### Cost Optimization Strategies

1. **Use the Right Model for the Task**
   - Don't use o1-preview for simple tasks
   - Use Perplexity only for actual intent analysis
   - Use GPT-4o for framework-specific code

2. **Minimize Context**
   - Only include relevant files in agent context
   - Use targeted documentation references
   - Avoid repeating large code blocks

3. **Batch Operations**
   - Generate multiple related files in one call
   - Review multiple issues together
   - Create related tests simultaneously

4. **Cache Prompts** (when supported)
   - Reuse system prompts
   - Cache large context documents
   - Minimize repeated content

## Model Selection Decision Tree

```
┌─────────────────────────────────────┐
│     What type of task?              │
└──────────┬──────────────────────────┘
           │
           ├─ Writing Tests?
           │  └─> Claude 3.5 Sonnet (comprehensive scenarios)
           │
           ├─ Business Logic?
           │  ├─ Simple/Medium?
           │  │  └─> Claude 3.5 Sonnet (clean architecture)
           │  └─ Complex/Algorithmic?
           │     └─> o1-preview (deep reasoning)
           │
           ├─ Database Work?
           │  └─> GPT-4o (SQL expertise)
           │
           ├─ API/Framework Work?
           │  └─> GPT-4o (framework knowledge)
           │
           ├─ AI/NLP Integration?
           │  └─> Claude 3.5 Sonnet (prompt engineering)
           │
           ├─ DevOps/Infrastructure?
           │  └─> GPT-4o (tooling knowledge)
           │
           ├─ Debugging Complex Issue?
           │  └─> o1-preview (deep reasoning)
           │
           └─ Documentation?
              └─> GPT-4o (clear writing)
```

## Switching Models Mid-Task

Sometimes you may want to switch models during a task:

### Scenario 1: Complex Business Logic
1. **Claude 3.5 Sonnet**: Design interfaces and structure
2. **o1-preview**: Implement complex algorithm
3. **Claude 3.5 Sonnet**: Refactor for clarity

### Scenario 2: Database with Complex Queries
1. **GPT-4o**: Design schema and basic queries
2. **o1-preview**: Optimize complex query with multiple joins
3. **GPT-4o**: Document and finalize

### Scenario 3: API with Tricky Logic
1. **GPT-4o**: Set up Echo routes and middleware
2. **Claude 3.5 Sonnet**: Implement complex validation logic
3. **GPT-4o**: Add error handling and logging

## Quality Indicators by Model

### Claude 3.5 Sonnet Quality Checks
✅ Clean separation of concerns
✅ No infrastructure in domain
✅ Comprehensive error handling
✅ Well-structured tests
✅ Good documentation comments

### GPT-4o Quality Checks
✅ Correct framework usage
✅ Proper SQL optimization
✅ Security best practices
✅ Complete error handling
✅ Production-ready code

### o1-preview Quality Checks
✅ Algorithm correctness
✅ Performance optimization
✅ Edge case coverage
✅ Mathematical accuracy
✅ Deep issue resolution

## Factory.ai Model Configuration

When using Factory.ai platform, specify models in droid configs:

```yaml
# Use Claude for domain logic
# .factory/droids/domain-logic.yaml
name: domain-logic-agent
model: claude-3.5-sonnet
temperature: 0.2  # Lower for consistency

# Use GPT-4o for API work
# .factory/droids/api-adapter.yaml
name: api-adapter-agent
model: gpt-4o
temperature: 0.3

# Use o1 for complex debugging
# .factory/droids/debugger.yaml
name: debugger-agent
model: o1-preview
temperature: 1.0  # o1 uses fixed temp
```

## Best Practices

### For All Models

1. **Be Specific**: Clearly state requirements and constraints
2. **Provide Context**: Include relevant docs and code
3. **Set Expectations**: Define output format and structure
4. **Verify Output**: Always review generated code
5. **Iterate**: Refine prompts based on results

### For Claude 3.5 Sonnet

✅ Emphasize architecture principles
✅ Ask for step-by-step reasoning
✅ Request comprehensive test coverage
✅ Specify clean code requirements

### For GPT-4o

✅ Reference specific frameworks/tools
✅ Ask for best practices
✅ Request performance optimization
✅ Specify security requirements

### For o1-preview

✅ Present complex problems clearly
✅ Ask for deep analysis
✅ Request algorithmic solutions
✅ Allow time for reasoning

## Monitoring Model Performance

Track these metrics for each model/agent:

| Metric | Target | Action if Below Target |
|--------|--------|----------------------|
| Test Coverage | >80% | Switch to Claude for tests |
| Architecture Violations | 0 | Use Claude for domain |
| Failed Tests | <5% | Review agent prompts |
| Query Performance | <100ms | Use GPT-4o for DB optimization |
| Intent Accuracy | >90% | Tune Perplexity prompts |
| Build Success | >95% | Review infra agent config |

## Summary

**Choose Models Based On**:
- Task complexity and type
- Need for framework knowledge vs. clean architecture
- Cost constraints
- Speed requirements
- Quality expectations

**General Guidelines**:
- **Claude 3.5 Sonnet**: Architecture, logic, tests
- **GPT-4o**: Frameworks, SQL, DevOps, docs
- **o1-preview**: Complex debugging, algorithms
- **Perplexity Sonar**: Production intent parsing

**Remember**: The best model is the one that produces the highest quality output for your specific task while maintaining reasonable cost and speed.

## Next Steps

- Read [Multi-Agent Architecture](18-multi-agent-architecture.md) for agent coordination
- See [Agent Specifications](19-agent-specifications.md) for detailed agent configs
- Review [TDD/BDD Workflow](04-tdd-bdd-workflow.md) for development process
