# Telegram Bot Adapter

## Overview

The Telegram Bot adapter provides a conversational interface to the domain layer using natural language. It's a **driving adapter** that translates Telegram messages into domain service calls.

**Location**: `internal/adapter/driving/telegram/`

**Framework**: telebot v3 (gopkg.in/telebot.v3)

## Architecture

```
Telegram → Bot Webhook/Polling → Handler → Domain Service → AI Intent Analysis → Response
```

### Responsibilities

- ✅ Handle Telegram commands and messages
- ✅ Parse natural language via domain service
- ✅ Format responses for Telegram (Markdown)
- ✅ Provide interactive keyboards
- ✅ Handle user preferences (language)
- ❌ NO business logic
- ❌ NO AI processing (delegated to domain)

## File Structure

```
internal/adapter/driving/telegram/
├── bot.go              # Bot setup and lifecycle
├── handlers.go         # Command handlers
├── handlers_text.go    # Text message handlers
├── keyboards.go        # Inline keyboards
├── formatter.go        # Response formatting
└── helpers.go          # Helper functions
```

## Bot Setup

### Bot Structure

```go
// internal/adapter/driving/telegram/bot.go
package telegram

import (
    "context"
    "log"
    "time"
    
    "gopkg.in/telebot.v3"
    
    "todobot/internal/domain/service"
)

type TelegramBot struct {
    bot         *telebot.Bot
    todoService *service.TodoService
    userService *service.UserService
}

func NewTelegramBot(
    token string,
    todoSvc *service.TodoService,
    userSvc *service.UserService,
) (*TelegramBot, error) {
    pref := telebot.Settings{
        Token:  token,
        Poller: &telebot.LongPoller{Timeout: 10 * time.Second},
    }
    
    bot, err := telebot.NewBot(pref)
    if err != nil {
        return nil, err
    }
    
    tb := &TelegramBot{
        bot:         bot,
        todoService: todoSvc,
        userService: userSvc,
    }
    
    tb.registerHandlers()
    return tb, nil
}

func (tb *TelegramBot) Start(ctx context.Context) error {
    log.Println("Telegram bot starting...")
    
    // Start in goroutine to allow graceful shutdown
    go tb.bot.Start()
    
    // Wait for context cancellation
    <-ctx.Done()
    
    log.Println("Telegram bot stopping...")
    tb.bot.Stop()
    return nil
}
```

## Command Handlers

### Register Handlers

```go
// internal/adapter/driving/telegram/handlers.go

func (tb *TelegramBot) registerHandlers() {
    // Command handlers
    tb.bot.Handle("/start", tb.handleStart)
    tb.bot.Handle("/help", tb.handleHelp)
    tb.bot.Handle("/list", tb.handleList)
    tb.bot.Handle("/settings", tb.handleSettings)
    tb.bot.Handle("/language", tb.handleLanguage)
    
    // Text messages (natural language)
    tb.bot.Handle(telebot.OnText, tb.handleText)
    
    // Callback queries (inline keyboards)
    tb.bot.Handle(telebot.OnCallback, tb.handleCallback)
}
```

### /start Command

```go
func (tb *TelegramBot) handleStart(c telebot.Context) error {
    userID := c.Sender().ID
    
    // Get or create user preferences
    prefs, err := tb.userService.GetPreferences(context.Background(), userID)
    if err != nil {
        prefs = &entity.UserPreferences{
            Language: entity.LangEnglish,
        }
    }
    
    lang := prefs.GetLanguageOrDefault()
    
    // Welcome message
    welcomeMsg := tb.getWelcomeMessage(lang)
    
    return c.Send(welcomeMsg, telebot.ModeMarkdown)
}

func (tb *TelegramBot) getWelcomeMessage(lang entity.Language) string {
    if lang == entity.LangVietnamese {
        return `👋 *Chào mừng bạn đến với Todo Bot!*

Tôi có thể giúp bạn quản lý công việc bằng ngôn ngữ tự nhiên.

*Các lệnh:*
/list - Xem danh sách công việc
/help - Trợ giúp
/settings - Cài đặt

*Hoặc gửi tin nhắn:*
"Thêm việc mua rau ngày mai"
"Hoàn thành 26-0001"
"Danh sách công việc ưu tiên cao"`
    }
    
    return `👋 *Welcome to Todo Bot!*

I can help you manage tasks using natural language.

*Commands:*
/list - View your todos
/help - Get help
/settings - Change settings

*Or just send a message:*
"Buy groceries tomorrow"
"Complete 26-0001"
"List high priority todos"`
}
```

### /help Command

```go
func (tb *TelegramBot) handleHelp(c telebot.Context) error {
    userID := c.Sender().ID
    prefs, _ := tb.userService.GetPreferences(context.Background(), userID)
    lang := prefs.GetLanguageOrDefault()
    
    helpMsg := tb.getHelpMessage(lang)
    return c.Send(helpMsg, telebot.ModeMarkdown)
}

func (tb *TelegramBot) getHelpMessage(lang entity.Language) string {
    if lang == entity.LangVietnamese {
        return `📖 *Hướng dẫn sử dụng*

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
• /language - Đổi ngôn ngữ`
    }
    
    return `📖 *How to use*

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
• /language - Change language`
}
```

### /list Command

```go
func (tb *TelegramBot) handleList(c telebot.Context) error {
    userID := c.Sender().ID
    ctx := context.Background()
    
    // Get user preferences
    prefs, _ := tb.userService.GetPreferences(ctx, userID)
    lang := prefs.GetLanguageOrDefault()
    
    // List pending todos
    filters := output.ListFilters{
        Status: &entity.StatusPending,
        Limit:  20,
    }
    
    todos, err := tb.todoService.ListTodos(ctx, userID, filters)
    if err != nil {
        return c.Send(tb.getErrorMessage(lang), telebot.ModeMarkdown)
    }
    
    if len(todos) == 0 {
        return c.Send(tb.getNoTodosMessage(lang), telebot.ModeMarkdown)
    }
    
    // Format response
    response := tb.formatTodoList(todos, lang)
    return c.Send(response, telebot.ModeMarkdown)
}

func (tb *TelegramBot) formatTodoList(todos []*entity.Todo, lang entity.Language) string {
    var header string
    if lang == entity.LangVietnamese {
        header = fmt.Sprintf("📋 *Danh sách công việc* (%d)\n\n", len(todos))
    } else {
        header = fmt.Sprintf("📋 *Your Todos* (%d)\n\n", len(todos))
    }
    
    var builder strings.Builder
    builder.WriteString(header)
    
    for _, todo := range todos {
        priorityIcon := tb.getPriorityIcon(todo.Priority)
        
        builder.WriteString(fmt.Sprintf("%s *%s*\n", priorityIcon, todo.Code))
        builder.WriteString(fmt.Sprintf("   %s\n", todo.Title))
        
        if todo.DueDate != nil {
            dueStr := todo.DueDate.Format("Jan 2, 3:04 PM")
            builder.WriteString(fmt.Sprintf("   📅 %s\n", dueStr))
        }
        
        if len(todo.Tags) > 0 {
            builder.WriteString(fmt.Sprintf("   🏷 %s\n", strings.Join(todo.Tags, ", ")))
        }
        
        builder.WriteString("\n")
    }
    
    return builder.String()
}

func (tb *TelegramBot) getPriorityIcon(priority entity.Priority) string {
    switch priority {
    case entity.PriorityHigh:
        return "🔴"
    case entity.PriorityMedium:
        return "🟡"
    case entity.PriorityLow:
        return "🟢"
    default:
        return "⚪"
    }
}
```

### /settings Command

```go
func (tb *TelegramBot) handleSettings(c telebot.Context) error {
    userID := c.Sender().ID
    prefs, _ := tb.userService.GetPreferences(context.Background(), userID)
    
    // Create settings keyboard
    keyboard := tb.createSettingsKeyboard(prefs)
    
    msg := "⚙️ *Settings*\n\nCurrent settings:"
    if prefs != nil {
        msg += fmt.Sprintf("\nLanguage: %s", prefs.Language)
        msg += fmt.Sprintf("\nTimezone: %s", prefs.Timezone)
    }
    
    return c.Send(msg, keyboard, telebot.ModeMarkdown)
}
```

## Text Message Handler (Natural Language)

```go
// internal/adapter/driving/telegram/handlers_text.go

func (tb *TelegramBot) handleText(c telebot.Context) error {
    userID := c.Sender().ID
    message := c.Text()
    ctx := context.Background()
    
    // Send typing indicator
    c.Notify(telebot.Typing)
    
    // Get user preferences for language
    prefs, _ := tb.userService.GetPreferences(ctx, userID)
    lang := prefs.GetLanguageOrDefault()
    
    // Process message through domain service (AI-powered)
    response, err := tb.todoService.HandleMessage(ctx, userID, message)
    if err != nil {
        log.Printf("Error handling message: %v", err)
        return c.Send(tb.getErrorMessage(lang), telebot.ModeMarkdown)
    }
    
    // Send response
    return c.Send(response, telebot.ModeMarkdown)
}
```

## Inline Keyboards

```go
// internal/adapter/driving/telegram/keyboards.go

func (tb *TelegramBot) createSettingsKeyboard(prefs *entity.UserPreferences) *telebot.ReplyMarkup {
    keyboard := &telebot.ReplyMarkup{}
    
    // Language buttons
    btnEnglish := keyboard.Data("🇺🇸 English", "lang", "en")
    btnVietnamese := keyboard.Data("🇻🇳 Tiếng Việt", "lang", "vi")
    
    // Timezone buttons
    btnUTC := keyboard.Data("🌍 UTC", "tz", "UTC")
    btnVietnam := keyboard.Data("🇻🇳 Vietnam", "tz", "Asia/Ho_Chi_Minh")
    
    keyboard.Inline(
        keyboard.Row(btnEnglish, btnVietnamese),
        keyboard.Row(btnUTC, btnVietnam),
    )
    
    return keyboard
}

func (tb *TelegramBot) handleCallback(c telebot.Context) error {
    callback := c.Callback()
    userID := c.Sender().ID
    ctx := context.Background()
    
    switch callback.Data {
    case "lang|en":
        err := tb.userService.SetLanguage(ctx, userID, entity.LangEnglish)
        if err != nil {
            return c.Respond(&telebot.CallbackResponse{Text: "Error"})
        }
        c.Respond(&telebot.CallbackResponse{Text: "✅ Language set to English"})
        return c.Edit("Language updated to English 🇺🇸")
        
    case "lang|vi":
        err := tb.userService.SetLanguage(ctx, userID, entity.LangVietnamese)
        if err != nil {
            return c.Respond(&telebot.CallbackResponse{Text: "Lỗi"})
        }
        c.Respond(&telebot.CallbackResponse{Text: "✅ Đã đổi sang tiếng Việt"})
        return c.Edit("Ngôn ngữ đã được cập nhật 🇻🇳")
        
    case "tz|UTC":
        err := tb.userService.SetTimezone(ctx, userID, "UTC")
        if err != nil {
            return c.Respond(&telebot.CallbackResponse{Text: "Error"})
        }
        c.Respond(&telebot.CallbackResponse{Text: "✅ Timezone set to UTC"})
        return c.Edit("Timezone updated to UTC 🌍")
        
    case "tz|Asia/Ho_Chi_Minh":
        err := tb.userService.SetTimezone(ctx, userID, "Asia/Ho_Chi_Minh")
        if err != nil {
            return c.Respond(&telebot.CallbackResponse{Text: "Lỗi"})
        }
        c.Respond(&telebot.CallbackResponse{Text: "✅ Đã đổi sang giờ Việt Nam"})
        return c.Edit("Múi giờ đã được cập nhật 🇻🇳")
    }
    
    return c.Respond(&telebot.CallbackResponse{Text: "Unknown action"})
}
```

## Response Formatting

```go
// internal/adapter/driving/telegram/formatter.go

func (tb *TelegramBot) formatTodoCreated(todo *entity.Todo, lang entity.Language) string {
    if lang == entity.LangVietnamese {
        msg := fmt.Sprintf("✅ *Đã tạo công việc*\n\n")
        msg += fmt.Sprintf("Mã: `%s`\n", todo.Code)
        msg += fmt.Sprintf("Tiêu đề: %s\n", todo.Title)
        msg += fmt.Sprintf("Ưu tiên: %s\n", tb.formatPriority(todo.Priority, lang))
        
        if todo.DueDate != nil {
            msg += fmt.Sprintf("Hạn: %s\n", todo.DueDate.Format("02/01/2006 15:04"))
        }
        
        if len(todo.Tags) > 0 {
            msg += fmt.Sprintf("Tags: %s\n", strings.Join(todo.Tags, ", "))
        }
        
        return msg
    }
    
    msg := fmt.Sprintf("✅ *Todo Created*\n\n")
    msg += fmt.Sprintf("Code: `%s`\n", todo.Code)
    msg += fmt.Sprintf("Title: %s\n", todo.Title)
    msg += fmt.Sprintf("Priority: %s\n", tb.formatPriority(todo.Priority, lang))
    
    if todo.DueDate != nil {
        msg += fmt.Sprintf("Due: %s\n", todo.DueDate.Format("Jan 2, 2006 3:04 PM"))
    }
    
    if len(todo.Tags) > 0 {
        msg += fmt.Sprintf("Tags: %s\n", strings.Join(todo.Tags, ", "))
    }
    
    return msg
}

func (tb *TelegramBot) formatPriority(priority entity.Priority, lang entity.Language) string {
    icon := tb.getPriorityIcon(priority)
    
    if lang == entity.LangVietnamese {
        switch priority {
        case entity.PriorityHigh:
            return fmt.Sprintf("%s Cao", icon)
        case entity.PriorityMedium:
            return fmt.Sprintf("%s Trung bình", icon)
        case entity.PriorityLow:
            return fmt.Sprintf("%s Thấp", icon)
        }
    }
    
    switch priority {
    case entity.PriorityHigh:
        return fmt.Sprintf("%s High", icon)
    case entity.PriorityMedium:
        return fmt.Sprintf("%s Medium", icon)
    case entity.PriorityLow:
        return fmt.Sprintf("%s Low", icon)
    }
    
    return string(priority)
}

func (tb *TelegramBot) getNoTodosMessage(lang entity.Language) string {
    if lang == entity.LangVietnamese {
        return "📭 *Không có công việc nào*\n\nHãy tạo công việc đầu tiên bằng cách gửi tin nhắn!"
    }
    return "📭 *No todos found*\n\nCreate your first todo by sending a message!"
}

func (tb *TelegramBot) getErrorMessage(lang entity.Language) string {
    if lang == entity.LangVietnamese {
        return "❌ Đã xảy ra lỗi. Vui lòng thử lại."
    }
    return "❌ An error occurred. Please try again."
}
```

## Message Examples

### English

**Create Todo:**
```
User: Buy groceries tomorrow #shopping
Bot: ✅ Todo Created

Code: `26-0042`
Title: Buy groceries
Priority: 🟡 Medium
Due: Jan 11, 2026 12:00 PM
Tags: shopping
```

**Complete Todo:**
```
User: Done 26-0042
Bot: ✅ Todo completed!

`26-0042` - Buy groceries
Status: ✅ Completed
```

**List Todos:**
```
User: /list
Bot: 📋 Your Todos (3)

🔴 26-0040
   Call important client
   📅 Jan 10, 2:00 PM

🟡 26-0041
   Prepare presentation
   📅 Jan 12, 10:00 AM

🟢 26-0043
   Read documentation
```

### Vietnamese

**Create Todo:**
```
User: Mua rau ngày mai #mua sắm
Bot: ✅ Đã tạo công việc

Mã: `26-0042`
Tiêu đề: Mua rau
Ưu tiên: 🟡 Trung bình
Hạn: 11/01/2026 12:00
Tags: mua sắm
```

## Best Practices

### 1. Always Use Context

```go
func (tb *TelegramBot) handleText(c telebot.Context) error {
    ctx := context.Background()  // Or c.Context() if available
    response, err := tb.todoService.HandleMessage(ctx, ...)
}
```

### 2. Provide User Feedback

```go
// Show typing indicator
c.Notify(telebot.Typing)

// Use emojis for visual feedback
return c.Send("✅ Todo created!", telebot.ModeMarkdown)
```

### 3. Handle Errors Gracefully

```go
func (tb *TelegramBot) handleText(c telebot.Context) error {
    response, err := tb.todoService.HandleMessage(...)
    if err != nil {
        log.Printf("Error: %v", err)
        return c.Send(tb.getErrorMessage(lang))  // User-friendly error
    }
    return c.Send(response)
}
```

### 4. Use Markdown Formatting

```go
msg := `✅ *Todo Created*

Code: \`26-0042\`
Title: Buy groceries`

return c.Send(msg, telebot.ModeMarkdown)
```

### 5. Multilingual Support

```go
// Always get user's language preference
prefs, _ := tb.userService.GetPreferences(ctx, userID)
lang := prefs.GetLanguageOrDefault()

// Use appropriate message
message := tb.getMessage(lang)
```

## Testing

### Mock Telegram Context

```go
// test/integration/telegram_test.go
type mockContext struct {
    userID   int64
    text     string
    response string
}

func (m *mockContext) Sender() *telebot.User {
    return &telebot.User{ID: m.userID}
}

func (m *mockContext) Text() string {
    return m.text
}

func (m *mockContext) Send(text string, opts ...interface{}) error {
    m.response = text
    return nil
}

func TestTelegramBot_HandleText(t *testing.T) {
    // Setup
    bot := setupTestBot(t)
    ctx := &mockContext{
        userID: 123456789,
        text:   "Buy milk tomorrow",
    }
    
    // Execute
    err := bot.handleText(ctx)
    
    // Assert
    assert.NoError(t, err)
    assert.Contains(t, ctx.response, "Todo Created")
}
```

## Integration with Domain

The Telegram bot adapter is thin - it delegates all logic to domain services:

```go
// ✅ GOOD - Adapter delegates to domain
func (tb *TelegramBot) handleText(c telebot.Context) error {
    response, err := tb.todoService.HandleMessage(...)  // Domain handles logic
    return c.Send(response)
}

// ❌ BAD - Business logic in adapter
func (tb *TelegramBot) handleText(c telebot.Context) error {
    // Parse message
    // Validate
    // Call AI
    // Save to database
    // Format response
}
```

## Next Steps

- See [AI/NLP Integration](12-ai-nlp-integration.md) for intent analysis
- Review [Domain Services](07-domain-services.md) for HandleMessage implementation
- Read [Internationalization](14-internationalization.md) for multilingual support
