# Internationalization (i18n)

## Overview

The Telegram Todo Bot supports **bilingual** operation in English and Vietnamese. All user-facing strings, date formats, and AI responses are localized based on user preferences.

**Supported Languages**:
- 🇺🇸 English (en) - Default
- 🇻🇳 Vietnamese (vi)

**Location**: `internal/i18n/`

## Language Support

### Features by Language

| Feature | English | Vietnamese |
|---------|---------|------------|
| Commands | ✅ Yes | ✅ Yes |
| Date parsing | tomorrow, next week, today | ngày mai, tuần sau, hôm nay |
| Priority keywords | urgent, important, high | gấp, quan trọng, cao |
| Status keywords | done, complete, pending | xong, hoàn thành, chưa làm |
| UI strings | ✅ Full | ✅ Full |
| Error messages | ✅ Full | ✅ Full |
| Help text | ✅ Full | ✅ Full |
| Default timezone | UTC | Asia/Ho_Chi_Minh |

## Language Entity

```go
// internal/domain/entity/user.go
package entity

type Language string

const (
    LangEnglish    Language = "en"
    LangVietnamese Language = "vi"
)

func (l Language) String() string {
    return string(l)
}

func (l Language) IsValid() bool {
    return l == LangEnglish || l == LangVietnamese
}

func ParseLanguage(s string) (Language, error) {
    switch strings.ToLower(s) {
    case "en", "english":
        return LangEnglish, nil
    case "vi", "vietnamese", "vn":
        return LangVietnamese, nil
    default:
        return "", fmt.Errorf("unsupported language: %s", s)
    }
}
```

## User Preferences

```go
// internal/domain/entity/user.go
type UserPreferences struct {
    TelegramUserID int64
    Language       Language
    Timezone       string
    CreatedAt      time.Time
    UpdatedAt      time.Time
}

func (u *UserPreferences) GetLanguageOrDefault() Language {
    if u == nil || u.Language == "" {
        return LangEnglish
    }
    return u.Language
}

func (u *UserPreferences) GetTimezoneOrDefault() string {
    if u == nil || u.Timezone == "" {
        // Vietnamese users default to Vietnam timezone
        if u != nil && u.Language == LangVietnamese {
            return "Asia/Ho_Chi_Minh"
        }
        return "UTC"
    }
    return u.Timezone
}
```

## Translator Implementation

### Translator Structure

```go
// internal/i18n/i18n.go
package i18n

type Translator struct {
    translations map[Language]map[string]string
}

func NewTranslator() *Translator {
    return &Translator{
        translations: map[Language]map[string]string{
            LangEnglish:    englishStrings,
            LangVietnamese: vietnameseStrings,
        },
    }
}

// Translate a key to the target language
func (t *Translator) T(key string, lang Language) string {
    if strings, ok := t.translations[lang]; ok {
        if translation, ok := strings[key]; ok {
            return translation
        }
    }
    
    // Fallback to English
    if translation, ok := t.translations[LangEnglish][key]; ok {
        return translation
    }
    
    // Last resort: return the key itself
    return key
}

// Translate with variables
func (t *Translator) Tf(key string, lang Language, args map[string]string) string {
    template := t.T(key, lang)
    
    for k, v := range args {
        template = strings.ReplaceAll(template, "{{"+k+"}}", v)
    }
    
    return template
}
```

### English Strings

```go
// internal/i18n/en.go
package i18n

var englishStrings = map[string]string{
    // Welcome & Help
    "welcome": `👋 *Welcome to Todo Bot!*

I can help you manage tasks using natural language.

*Commands:*
/list - View your todos
/help - Get help
/settings - Change settings

*Or just send a message:*
"Buy groceries tomorrow"
"Complete 26-0001"
"List high priority todos"`,

    "help": `📖 *How to use*

*Create todos:*
• "Buy milk tomorrow"
• "Call mom urgent"
• "Team meeting 3pm #work"

*List todos:*
• /list - All todos
• "List pending todos"
• "Show high priority tasks"

*Complete:*
• "Done 26-0001"
• "Complete buy milk"

*Update:*
• "Change 26-0001 to high priority"
• "Add #urgent to 26-0001"

*Search:*
• "Find todos about shopping"

*Language:*
• /language - Change language`,

    // Todo Actions
    "todo.created":        "✅ Todo created successfully!",
    "todo.updated":        "✅ Todo updated!",
    "todo.completed":      "✅ Todo completed!",
    "todo.deleted":        "✅ Todo deleted!",
    "todo.not_found":      "❌ Todo not found",
    "todo.no_todos":       "📭 No todos found",
    
    // Priority
    "priority.high":       "🔴 High",
    "priority.medium":     "🟡 Medium",
    "priority.low":        "🟢 Low",
    
    // Status
    "status.pending":      "⏳ Pending",
    "status.completed":    "✅ Completed",
    "status.cancelled":    "❌ Cancelled",
    
    // Errors
    "error":               "❌ An error occurred. Please try again.",
    "error.invalid_date":  "❌ Invalid date format",
    "error.invalid_input": "❌ Invalid input",
    
    // Settings
    "settings.language_changed": "✅ Language changed to English",
    "settings.timezone_changed": "✅ Timezone changed to {{timezone}}",
    
    // Templates
    "template.created":     "✅ Template created!",
    "template.not_found":   "❌ Template not found",
    "template.list_header": "📋 Available Templates ({{count}})",
}
```

### Vietnamese Strings

```go
// internal/i18n/vi.go
package i18n

var vietnameseStrings = map[string]string{
    // Welcome & Help
    "welcome": `👋 *Chào mừng bạn đến với Todo Bot!*

Tôi có thể giúp bạn quản lý công việc bằng ngôn ngữ tự nhiên.

*Các lệnh:*
/list - Xem danh sách công việc
/help - Trợ giúp
/settings - Cài đặt

*Hoặc gửi tin nhắn:*
"Thêm việc mua rau ngày mai"
"Hoàn thành 26-0001"
"Danh sách công việc ưu tiên cao"`,

    "help": `📖 *Hướng dẫn sử dụng*

*Tạo công việc:*
• "Mua sữa ngày mai"
• "Gọi điện cho mẹ gấp"
• "Họp nhóm 15:00 #công việc"

*Xem danh sách:*
• /list - Tất cả công việc
• "Danh sách công việc chưa làm"
• "Công việc ưu tiên cao"

*Hoàn thành:*
• "Xong 26-0001"
• "Hoàn thành mua sữa"

*Cập nhật:*
• "Đổi 26-0001 thành ưu tiên cao"
• "Thêm #khẩn cấp vào 26-0001"

*Tìm kiếm:*
• "Tìm công việc về mua sắm"

*Ngôn ngữ:*
• /language - Đổi ngôn ngữ`,

    // Todo Actions
    "todo.created":        "✅ Đã tạo công việc!",
    "todo.updated":        "✅ Đã cập nhật công việc!",
    "todo.completed":      "✅ Đã hoàn thành công việc!",
    "todo.deleted":        "✅ Đã xóa công việc!",
    "todo.not_found":      "❌ Không tìm thấy công việc",
    "todo.no_todos":       "📭 Không có công việc nào",
    
    // Priority
    "priority.high":       "🔴 Cao",
    "priority.medium":     "🟡 Trung bình",
    "priority.low":        "🟢 Thấp",
    
    // Status
    "status.pending":      "⏳ Chưa làm",
    "status.completed":    "✅ Đã xong",
    "status.cancelled":    "❌ Đã hủy",
    
    // Errors
    "error":               "❌ Đã xảy ra lỗi. Vui lòng thử lại.",
    "error.invalid_date":  "❌ Định dạng ngày không hợp lệ",
    "error.invalid_input": "❌ Dữ liệu không hợp lệ",
    
    // Settings
    "settings.language_changed": "✅ Đã đổi sang tiếng Việt",
    "settings.timezone_changed": "✅ Đã đổi múi giờ thành {{timezone}}",
    
    // Templates
    "template.created":     "✅ Đã tạo mẫu!",
    "template.not_found":   "❌ Không tìm thấy mẫu",
    "template.list_header": "📋 Các mẫu có sẵn ({{count}})",
}
```

## Usage in Services

```go
// internal/domain/service/todo_service.go
func (s *TodoService) HandleMessage(
    ctx context.Context,
    userID int64,
    message string,
) (string, error) {
    // Get user's language
    prefs, _ := s.userRepo.GetPreferences(ctx, userID)
    lang := prefs.GetLanguageOrDefault()
    
    // Analyze intent with language context
    todos, _ := s.todoRepo.List(ctx, userID, port.ListFilters{})
    intent, err := s.intentAnalyzer.Analyze(ctx, message, todos, lang)
    if err != nil {
        return s.i18n.T("error", lang), err
    }
    
    // Route to action
    switch intent.Action {
    case entity.ActionCreate:
        return s.createTodo(ctx, userID, intent, lang)
    case entity.ActionList:
        return s.listTodos(ctx, userID, lang)
    default:
        return s.i18n.T("error.invalid_input", lang), nil
    }
}

func (s *TodoService) createTodo(
    ctx context.Context,
    userID int64,
    intent *entity.ParsedIntent,
    lang entity.Language,
) (string, error) {
    todo := &entity.Todo{
        TelegramUserID: userID,
        Title:          *intent.Data.Title,
        Priority:       *intent.Data.Priority,
        // ...
    }
    
    if err := s.todoRepo.Create(ctx, todo); err != nil {
        return s.i18n.T("error", lang), err
    }
    
    // Return localized success message
    return s.formatTodoCreated(todo, lang), nil
}

func (s *TodoService) formatTodoCreated(
    todo *entity.Todo,
    lang entity.Language,
) string {
    msg := s.i18n.T("todo.created", lang) + "\n\n"
    msg += fmt.Sprintf("Code: `%s`\n", todo.Code)
    msg += fmt.Sprintf("Title: %s\n", todo.Title)
    msg += fmt.Sprintf("Priority: %s\n", s.formatPriority(todo.Priority, lang))
    return msg
}

func (s *TodoService) formatPriority(
    priority entity.Priority,
    lang entity.Language,
) string {
    key := fmt.Sprintf("priority.%s", strings.ToLower(string(priority)))
    return s.i18n.T(key, lang)
}
```

## Date Parsing (Multilingual)

```go
// internal/domain/service/date_parser.go
package service

type DateParser struct {
    timezone *time.Location
}

func NewDateParser(timezone string) (*DateParser, error) {
    loc, err := time.LoadLocation(timezone)
    if err != nil {
        return nil, err
    }
    return &DateParser{timezone: loc}, nil
}

func (p *DateParser) Parse(
    dateStr string,
    lang entity.Language,
) (*time.Time, error) {
    now := time.Now().In(p.timezone)
    lowerDate := strings.ToLower(dateStr)
    
    // Vietnamese date keywords
    if lang == entity.LangVietnamese {
        switch {
        case strings.Contains(lowerDate, "hôm nay"), strings.Contains(lowerDate, "hom nay"):
            return &now, nil
        case strings.Contains(lowerDate, "ngày mai"), strings.Contains(lowerDate, "ngay mai"):
            tomorrow := now.AddDate(0, 0, 1)
            return &tomorrow, nil
        case strings.Contains(lowerDate, "tuần sau"), strings.Contains(lowerDate, "tuan sau"):
            nextWeek := now.AddDate(0, 0, 7)
            return &nextWeek, nil
        case strings.Contains(lowerDate, "tháng sau"), strings.Contains(lowerDate, "thang sau"):
            nextMonth := now.AddDate(0, 1, 0)
            return &nextMonth, nil
        }
    }
    
    // English date keywords
    switch {
    case strings.Contains(lowerDate, "today"):
        return &now, nil
    case strings.Contains(lowerDate, "tomorrow"):
        tomorrow := now.AddDate(0, 0, 1)
        return &tomorrow, nil
    case strings.Contains(lowerDate, "next week"):
        nextWeek := now.AddDate(0, 0, 7)
        return &nextWeek, nil
    case strings.Contains(lowerDate, "next month"):
        nextMonth := now.AddDate(0, 1, 0)
        return &nextMonth, nil
    }
    
    // Try parsing ISO 8601 format
    if t, err := time.ParseInLocation(time.RFC3339, dateStr, p.timezone); err == nil {
        return &t, nil
    }
    
    // Try common formats
    formats := []string{
        "2006-01-02",
        "02/01/2006",
        "Jan 2, 2006",
    }
    
    for _, format := range formats {
        if t, err := time.ParseInLocation(format, dateStr, p.timezone); err == nil {
            return &t, nil
        }
    }
    
    return nil, fmt.Errorf("unable to parse date: %s", dateStr)
}
```

## Priority Keywords (Multilingual)

```go
// internal/adapter/driven/perplexity/parser.go
func parsePriorityKeywords(text string, lang entity.Language) *entity.Priority {
    lowerText := strings.ToLower(text)
    
    // Vietnamese keywords
    if lang == entity.LangVietnamese {
        if strings.Contains(lowerText, "gấp") || 
           strings.Contains(lowerText, "khẩn cấp") ||
           strings.Contains(lowerText, "quan trọng") {
            p := entity.PriorityHigh
            return &p
        }
    }
    
    // English keywords
    if strings.Contains(lowerText, "urgent") ||
       strings.Contains(lowerText, "important") ||
       strings.Contains(lowerText, "high priority") {
        p := entity.PriorityHigh
        return &p
    }
    
    return nil
}
```

## Language Switching

### Via Command

```go
// internal/domain/service/user_service.go
func (s *UserService) SetLanguage(
    ctx context.Context,
    userID int64,
    language entity.Language,
) error {
    if !language.IsValid() {
        return fmt.Errorf("invalid language: %s", language)
    }
    
    prefs, err := s.userRepo.GetPreferences(ctx, userID)
    if err != nil {
        // Create new preferences
        prefs = &entity.UserPreferences{
            TelegramUserID: userID,
            Language:       language,
        }
        return s.userRepo.SavePreferences(ctx, prefs)
    }
    
    prefs.Language = language
    return s.userRepo.UpdatePreferences(ctx, prefs)
}
```

### Via Natural Language

```gherkin
# features/language_switch.feature
Feature: Language Switching
  As a bilingual user
  I want to switch between English and Vietnamese
  So that I can use the bot in my preferred language

  Scenario: Switch to Vietnamese
    Given a user with ID 123456789
    And the user's language is "en"
    When the user sends "Switch to Vietnamese"
    Then the user's language should be "vi"
    And the response should be in Vietnamese

  Scenario: Switch using Vietnamese command
    Given a user with ID 123456789
    When the user sends "Chuyển sang tiếng Việt"
    Then the user's language should be "vi"
```

## AI Prompt Engineering (Multilingual)

```go
// internal/adapter/driven/perplexity/prompt.go
func buildPrompt(message string, lang entity.Language) string {
    var systemPrompt string
    
    if lang == entity.LangVietnamese {
        systemPrompt = `Bạn là trợ lý quản lý công việc. Phân tích tin nhắn và trả về JSON với ý định.

Các từ khóa tiếng Việt:
- "thêm", "tạo" = tạo công việc
- "xong", "hoàn thành" = hoàn thành
- "gấp", "khẩn cấp" = ưu tiên cao
- "ngày mai" = tomorrow
- "tuần sau" = next week`
    } else {
        systemPrompt = `You are a todo assistant. Parse the message and return JSON with intent.

Keywords:
- "add", "create" = create todo
- "done", "complete" = complete
- "urgent", "important" = high priority
- "tomorrow" = +1 day
- "next week" = +7 days`
    }
    
    return systemPrompt
}
```

## Testing

```go
func TestTranslator_T(t *testing.T) {
    translator := i18n.NewTranslator()
    
    // English
    assert.Equal(t, "✅ Todo created successfully!", 
        translator.T("todo.created", entity.LangEnglish))
    
    // Vietnamese
    assert.Equal(t, "✅ Đã tạo công việc!", 
        translator.T("todo.created", entity.LangVietnamese))
    
    // Fallback to English for missing key
    assert.Equal(t, "unknown.key", 
        translator.T("unknown.key", entity.LangVietnamese))
}

func TestDateParser_Vietnamese(t *testing.T) {
    parser, _ := NewDateParser("Asia/Ho_Chi_Minh")
    
    date, err := parser.Parse("ngày mai", entity.LangVietnamese)
    
    assert.NoError(t, err)
    assert.Equal(t, time.Now().AddDate(0, 0, 1).Day(), date.Day())
}
```

## Best Practices

1. **Always get user's language** before generating responses
2. **Use translation keys** instead of hardcoded strings
3. **Provide fallbacks** to English for missing translations
4. **Test both languages** for all features
5. **Consider timezone** when parsing dates
6. **Use unicode** for emoji and special characters

## Next Steps

- See [Telegram Bot](10-telegram-bot.md) for localized bot responses
- Review [AI/NLP Integration](12-ai-nlp-integration.md) for multilingual parsing
- Read [Domain Services](07-domain-services.md) for i18n usage
