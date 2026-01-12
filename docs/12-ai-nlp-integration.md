# AI/NLP Integration

## Overview

The AI/NLP layer provides natural language understanding using Perplexity AI. It's a **driven adapter** that implements the IntentAnalyzer port.

**Location**: `internal/adapter/driven/perplexity/`

**Technology**: Perplexity AI API (Sonar model)

## Architecture

```
User Message → Domain Service → IntentAnalyzer Port → Perplexity Adapter → Perplexity API → ParsedIntent
```

## File Structure

```
internal/adapter/driven/perplexity/
├── client.go           # Perplexity API client
├── prompt.go           # Prompt templates
├── parser.go           # Response parsing
└── cache.go            # Response caching (optional)
```

## Client Implementation

```go
// internal/adapter/driven/perplexity/client.go
package perplexity

import (
    "bytes"
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    
    "todobot/internal/domain/entity"
)

type Client struct {
    apiKey     string
    httpClient *http.Client
    baseURL    string
}

func NewClient(apiKey string) *Client {
    return &Client{
        apiKey:     apiKey,
        httpClient: &http.Client{Timeout: 30 * time.Second},
        baseURL:    "https://api.perplexity.ai",
    }
}

// Analyze implements output.IntentAnalyzer
func (c *Client) Analyze(
    ctx context.Context,
    message string,
    existingTodos []*entity.Todo,
    lang entity.Language,
) (*entity.ParsedIntent, error) {
    // Build prompt
    prompt := c.buildPrompt(message, existingTodos, lang)
    
    // Call Perplexity API
    response, err := c.callAPI(ctx, prompt)
    if err != nil {
        return nil, fmt.Errorf("API call failed: %w", err)
    }
    
    // Parse response
    intent, err := c.parseResponse(response, message, lang)
    if err != nil {
        return nil, fmt.Errorf("failed to parse response: %w", err)
    }
    
    return intent, nil
}

func (c *Client) callAPI(ctx context.Context, prompt string) (string, error) {
    reqBody := map[string]interface{}{
        "model": "sonar",
        "messages": []map[string]string{
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": prompt},
        },
        "temperature": 0.2,
    }
    
    jsonData, err := json.Marshal(reqBody)
    if err != nil {
        return "", err
    }
    
    req, err := http.NewRequestWithContext(ctx, "POST", c.baseURL+"/chat/completions", bytes.NewBuffer(jsonData))
    if err != nil {
        return "", err
    }
    
    req.Header.Set("Authorization", "Bearer "+c.apiKey)
    req.Header.Set("Content-Type", "application/json")
    
    resp, err := c.httpClient.Do(req)
    if err != nil {
        return "", err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        return "", fmt.Errorf("API returned status %d", resp.StatusCode)
    }
    
    var result struct {
        Choices []struct {
            Message struct {
                Content string `json:"content"`
            } `json:"message"`
        } `json:"choices"`
    }
    
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return "", err
    }
    
    if len(result.Choices) == 0 {
        return "", fmt.Errorf("no response from API")
    }
    
    return result.Choices[0].Message.Content, nil
}
```

## Prompt Engineering

```go
// internal/adapter/driven/perplexity/prompt.go

const systemPrompt = `You are a todo assistant that parses natural language into structured intents.
Parse the user's message and return a JSON object with the intent.

Output format:
{
  "action": "create|update|delete|complete|list|search|help|unknown",
  "confidence": 0.0-1.0,
  "data": {
    "title": "task title",
    "due_date": "ISO 8601 date",
    "priority": "low|medium|high",
    "tags": ["tag1", "tag2"],
    "todo_id": "code or partial match"
  }
}`

func (c *Client) buildPrompt(message string, existingTodos []*entity.Todo, lang entity.Language) string {
    var prompt strings.Builder
    
    // Add context
    prompt.WriteString(fmt.Sprintf("User's language: %s\n", lang))
    prompt.WriteString(fmt.Sprintf("Current date: %s\n", time.Now().Format("2006-01-02")))
    
    // Add existing todos for context
    if len(existingTodos) > 0 {
        prompt.WriteString("\nExisting todos:\n")
        for _, todo := range existingTodos {
            prompt.WriteString(fmt.Sprintf("- %s: %s\n", todo.Code, todo.Title))
        }
    }
    
    // Add user message
    prompt.WriteString(fmt.Sprintf("\nUser message: %s\n", message))
    
    // Add language-specific keywords
    if lang == entity.LangVietnamese {
        prompt.WriteString("\nVietnamese keywords:\n")
        prompt.WriteString("- 'gấp', 'khẩn cấp' = high priority\n")
        prompt.WriteString("- 'ngày mai' = tomorrow\n")
        prompt.WriteString("- 'tuần sau' = next week\n")
        prompt.WriteString("- 'xong', 'hoàn thành' = complete\n")
    }
    
    return prompt.String()
}

func (c *Client) parseResponse(response string, rawMessage string, lang entity.Language) (*entity.ParsedIntent, error) {
    // Parse JSON response
    var data struct {
        Action     string  `json:"action"`
        Confidence float64 `json:"confidence"`
        Data       struct {
            Title    *string   `json:"title"`
            DueDate  *string   `json:"due_date"`
            Priority *string   `json:"priority"`
            Tags     []string  `json:"tags"`
            TodoID   *string   `json:"todo_id"`
        } `json:"data"`
    }
    
    if err := json.Unmarshal([]byte(response), &data); err != nil {
        // Fallback to regex parsing if JSON fails
        return c.fallbackParse(rawMessage, lang)
    }
    
    intent := &entity.ParsedIntent{
        Action:           entity.ActionType(data.Action),
        Confidence:       data.Confidence,
        DetectedLanguage: lang,
        RawMessage:       rawMessage,
    }
    
    // Parse data fields
    intent.Data = entity.IntentData{
        Title:  data.Data.Title,
        Tags:   data.Data.Tags,
        TodoID: data.Data.TodoID,
    }
    
    // Parse due date
    if data.Data.DueDate != nil {
        if t, err := time.Parse(time.RFC3339, *data.Data.DueDate); err == nil {
            intent.Data.DueDate = &t
        }
    }
    
    // Parse priority
    if data.Data.Priority != nil {
        p := entity.Priority(*data.Data.Priority)
        intent.Data.Priority = &p
    }
    
    return intent, nil
}

func (c *Client) fallbackParse(message string, lang entity.Language) (*entity.ParsedIntent, error) {
    // Simple regex-based fallback
    intent := &entity.ParsedIntent{
        Action:           entity.ActionUnknown,
        Confidence:       0.5,
        DetectedLanguage: lang,
        RawMessage:       message,
    }
    
    // Detect action from keywords
    messageLower := strings.ToLower(message)
    
    if lang == entity.LangVietnamese {
        if strings.Contains(messageLower, "thêm") || strings.Contains(messageLower, "tạo") {
            intent.Action = entity.ActionCreate
            intent.Data.Title = &message
        } else if strings.Contains(messageLower, "xong") || strings.Contains(messageLower, "hoàn thành") {
            intent.Action = entity.ActionComplete
        }
    } else {
        if strings.Contains(messageLower, "create") || strings.Contains(messageLower, "add") {
            intent.Action = entity.ActionCreate
            intent.Data.Title = &message
        } else if strings.Contains(messageLower, "done") || strings.Contains(messageLower, "complete") {
            intent.Action = entity.ActionComplete
        }
    }
    
    return intent, nil
}
```

## Multilingual Support

```go
// Language-specific date parsing
func parseDateInLanguage(dateStr string, lang entity.Language) (*time.Time, error) {
    now := time.Now()
    lowerDate := strings.ToLower(dateStr)
    
    if lang == entity.LangVietnamese {
        switch {
        case strings.Contains(lowerDate, "hôm nay"):
            return &now, nil
        case strings.Contains(lowerDate, "ngày mai"):
            tomorrow := now.AddDate(0, 0, 1)
            return &tomorrow, nil
        case strings.Contains(lowerDate, "tuần sau"):
            nextWeek := now.AddDate(0, 0, 7)
            return &nextWeek, nil
        }
    } else {
        switch {
        case strings.Contains(lowerDate, "today"):
            return &now, nil
        case strings.Contains(lowerDate, "tomorrow"):
            tomorrow := now.AddDate(0, 0, 1)
            return &tomorrow, nil
        case strings.Contains(lowerDate, "next week"):
            nextWeek := now.AddDate(0, 0, 7)
            return &nextWeek, nil
        }
    }
    
    // Try ISO 8601 format
    if t, err := time.Parse(time.RFC3339, dateStr); err == nil {
        return &t, nil
    }
    
    return nil, fmt.Errorf("unable to parse date: %s", dateStr)
}
```

## Testing

```go
// test/unit/adapter/perplexity_test.go
func TestPerplexityClient_Analyze(t *testing.T) {
    client := perplexity.NewClient("test-key")
    
    intent, err := client.Analyze(
        context.Background(),
        "Buy milk tomorrow",
        nil,
        entity.LangEnglish,
    )
    
    assert.NoError(t, err)
    assert.Equal(t, entity.ActionCreate, intent.Action)
    assert.True(t, intent.IsConfident())
    assert.NotNil(t, intent.Data.Title)
}
```

## Best Practices

1. **Timeout Handling** - Set reasonable API timeouts
2. **Error Handling** - Provide fallback parsing
3. **Caching** - Cache common patterns
4. **Rate Limiting** - Respect API limits
5. **Context Injection** - Include existing todos for better accuracy

## Next Steps

- See [Domain Services](07-domain-services.md) for IntentAnalyzer usage
- Review [Port Interfaces](08-port-interfaces.md) for IntentAnalyzer interface
- Read [Internationalization](14-internationalization.md) for multilingual support
