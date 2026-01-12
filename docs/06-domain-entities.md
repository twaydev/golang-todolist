# Domain Entities

## Overview

Domain entities are the core business objects in the system. They contain business logic, validation rules, and state management. All entities are located in `internal/domain/entity/` and have **no external dependencies** (only Go stdlib).

## Design Principles

### 1. Rich Domain Model
Entities contain business rules and behavior, not just data:
```go
// ❌ Anemic model
type Todo struct {
    Title  string
    Status string
}

// ✅ Rich model
type Todo struct {
    Title  string
    Status Status
}

func (t *Todo) MarkComplete() {
    t.Status = StatusCompleted
    t.UpdatedAt = time.Now()
}

func (t *Todo) IsOverdue() bool {
    return t.DueDate != nil && 
           time.Now().After(*t.DueDate) && 
           t.Status != StatusCompleted
}
```

### 2. Self-Validating
Entities validate themselves:
```go
func (t *Todo) Validate() error {
    if t.Title == "" {
        return ErrTitleRequired
    }
    if len(t.Title) > 500 {
        return ErrTitleTooLong
    }
    return nil
}
```

### 3. Immutability Where Appropriate
Value objects are immutable:
```go
type Priority string  // Immutable value

const (
    PriorityLow    Priority = "low"
    PriorityMedium Priority = "medium"
    PriorityHigh   Priority = "high"
}
```

## Entity: Todo

### Definition

**Location**: `internal/domain/entity/todo.go`

**Purpose**: Represents a task/todo item with business rules

```go
type Todo struct {
    // Identity
    ID             string
    TelegramUserID int64
    Code           string  // Format: YY-NNNN (e.g., 26-0001)
    
    // Core fields
    Title       string
    Description *string
    
    // Scheduling
    DueDate *time.Time
    
    // Classification
    Priority Priority
    Status   Status
    Tags     []string
    
    // Metadata
    CreatedAt time.Time
    UpdatedAt time.Time
}
```

### Enumerations

#### Priority

```go
type Priority string

const (
    PriorityLow    Priority = "low"
    PriorityMedium Priority = "medium"
    PriorityHigh   Priority = "high"
)

// Validation
func (p Priority) IsValid() bool {
    switch p {
    case PriorityLow, PriorityMedium, PriorityHigh:
        return true
    default:
        return false
    }
}

// Comparison
func (p Priority) GreaterThan(other Priority) bool {
    priorityOrder := map[Priority]int{
        PriorityLow:    1,
        PriorityMedium: 2,
        PriorityHigh:   3,
    }
    return priorityOrder[p] > priorityOrder[other]
}
```

#### Status

```go
type Status string

const (
    StatusPending    Status = "pending"
    StatusInProgress Status = "in_progress"
    StatusCompleted  Status = "completed"
)

// State transition validation
func (s Status) CanTransitionTo(newStatus Status) bool {
    validTransitions := map[Status][]Status{
        StatusPending:    {StatusInProgress, StatusCompleted},
        StatusInProgress: {StatusPending, StatusCompleted},
        StatusCompleted:  {StatusPending}, // Can reopen
    }
    
    for _, allowed := range validTransitions[s] {
        if allowed == newStatus {
            return true
        }
    }
    return false
}
```

### Business Rules (Methods)

#### Validation

```go
var (
    ErrTitleRequired  = errors.New("title is required")
    ErrTitleTooLong   = errors.New("title must be 500 characters or less")
    ErrInvalidPriority = errors.New("invalid priority")
    ErrInvalidStatus  = errors.New("invalid status")
)

func (t *Todo) Validate() error {
    // Title validation
    if t.Title == "" {
        return ErrTitleRequired
    }
    if len(t.Title) > 500 {
        return ErrTitleTooLong
    }
    
    // Priority validation
    if !t.Priority.IsValid() {
        return ErrInvalidPriority
    }
    
    // Status validation
    switch t.Status {
    case StatusPending, StatusInProgress, StatusCompleted:
        // Valid
    default:
        return ErrInvalidStatus
    }
    
    return nil
}
```

#### State Transitions

```go
func (t *Todo) MarkComplete() error {
    if !t.Status.CanTransitionTo(StatusCompleted) {
        return fmt.Errorf("cannot transition from %s to %s", t.Status, StatusCompleted)
    }
    
    t.Status = StatusCompleted
    t.UpdatedAt = time.Now()
    return nil
}

func (t *Todo) MarkInProgress() error {
    if !t.Status.CanTransitionTo(StatusInProgress) {
        return fmt.Errorf("cannot transition from %s to %s", t.Status, StatusInProgress)
    }
    
    t.Status = StatusInProgress
    t.UpdatedAt = time.Now()
    return nil
}

func (t *Todo) Reopen() error {
    if t.Status != StatusCompleted {
        return errors.New("can only reopen completed todos")
    }
    
    t.Status = StatusPending
    t.UpdatedAt = time.Now()
    return nil
}
```

#### Query Methods

```go
func (t *Todo) IsOverdue() bool {
    if t.DueDate == nil {
        return false
    }
    return time.Now().After(*t.DueDate) && t.Status != StatusCompleted
}

func (t *Todo) IsPending() bool {
    return t.Status == StatusPending
}

func (t *Todo) IsCompleted() bool {
    return t.Status == StatusCompleted
}

func (t *Todo) HasTag(tag string) bool {
    for _, t := range t.Tags {
        if t == tag {
            return true
        }
    }
    return false
}

func (t *Todo) DaysUntilDue() *int {
    if t.DueDate == nil {
        return nil
    }
    
    days := int(time.Until(*t.DueDate).Hours() / 24)
    return &days
}
```

#### Modification Methods

```go
func (t *Todo) UpdatePriority(priority Priority) error {
    if !priority.IsValid() {
        return ErrInvalidPriority
    }
    
    t.Priority = priority
    t.UpdatedAt = time.Now()
    return nil
}

func (t *Todo) AddTag(tag string) {
    // Avoid duplicates
    if !t.HasTag(tag) {
        t.Tags = append(t.Tags, tag)
        t.UpdatedAt = time.Now()
    }
}

func (t *Todo) RemoveTag(tag string) {
    filtered := make([]string, 0, len(t.Tags))
    for _, t := range t.Tags {
        if t != tag {
            filtered = append(filtered, t)
        }
    }
    t.Tags = filtered
    t.UpdatedAt = time.Now()
}

func (t *Todo) SetDueDate(dueDate *time.Time) {
    t.DueDate = dueDate
    t.UpdatedAt = time.Now()
}
```

### Example Usage

```go
// Create new todo
todo := &entity.Todo{
    TelegramUserID: 123456789,
    Title:          "Buy groceries",
    Priority:       entity.PriorityMedium,
    Status:         entity.StatusPending,
    Tags:           []string{"shopping"},
}

// Validate
if err := todo.Validate(); err != nil {
    return err
}

// Mark in progress
if err := todo.MarkInProgress(); err != nil {
    return err
}

// Check if overdue
if todo.IsOverdue() {
    fmt.Println("Todo is overdue!")
}

// Update priority
if err := todo.UpdatePriority(entity.PriorityHigh); err != nil {
    return err
}

// Mark complete
if err := todo.MarkComplete(); err != nil {
    return err
}
```

---

## Entity: UserPreferences

### Definition

**Location**: `internal/domain/entity/user.go`

**Purpose**: User settings and preferences

```go
type UserPreferences struct {
    TelegramUserID int64
    Language       Language
    Timezone       string
    CreatedAt      time.Time
    UpdatedAt      time.Time
}

type Language string

const (
    LangEnglish    Language = "en"
    LangVietnamese Language = "vi"
)
```

### Business Rules (Methods)

```go
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

func (u *UserPreferences) SetLanguage(lang Language) error {
    switch lang {
    case LangEnglish, LangVietnamese:
        u.Language = lang
        u.UpdatedAt = time.Now()
        return nil
    default:
        return errors.New("unsupported language")
    }
}

func (u *UserPreferences) SetTimezone(tz string) error {
    // Validate timezone
    _, err := time.LoadLocation(tz)
    if err != nil {
        return fmt.Errorf("invalid timezone: %w", err)
    }
    
    u.Timezone = tz
    u.UpdatedAt = time.Now()
    return nil
}

func (u *UserPreferences) IsVietnamese() bool {
    return u.Language == LangVietnamese
}
```

### Example Usage

```go
prefs := &entity.UserPreferences{
    TelegramUserID: 123456789,
    Language:       entity.LangEnglish,
    Timezone:       "UTC",
}

// Get language with default fallback
lang := prefs.GetLanguageOrDefault()

// Switch language
if err := prefs.SetLanguage(entity.LangVietnamese); err != nil {
    return err
}

// Timezone will auto-adjust for Vietnamese users
tz := prefs.GetTimezoneOrDefault()  // Returns "Asia/Ho_Chi_Minh"
```

---

## Value Object: ParsedIntent

### Definition

**Location**: `internal/domain/entity/intent.go`

**Purpose**: Represents parsed natural language intent

```go
type ParsedIntent struct {
    Action           ActionType
    Data             IntentData
    Confidence       float64  // 0.0 - 1.0
    DetectedLanguage Language
    RawMessage       string
    Ambiguities      []string // When multiple interpretations possible
}

type ActionType string

const (
    ActionCreate      ActionType = "create"
    ActionUpdate      ActionType = "update"
    ActionDelete      ActionType = "delete"
    ActionView        ActionType = "view"
    ActionList        ActionType = "list"
    ActionComplete    ActionType = "complete"
    ActionSearch      ActionType = "search"
    ActionSetLanguage ActionType = "set_language"
    ActionHelp        ActionType = "help"
    ActionUnknown     ActionType = "unknown"
)

type IntentData struct {
    Title       *string
    Description *string
    DueDate     *time.Time
    Priority    *Priority
    Status      *Status
    Tags        []string
    SearchQuery *string
    TodoID      *string
    Language    *Language
}
```

### Business Rules (Methods)

```go
func (p *ParsedIntent) IsConfident() bool {
    return p.Confidence >= 0.7
}

func (p *ParsedIntent) IsAmbiguous() bool {
    return len(p.Ambiguities) > 0
}

func (p *ParsedIntent) RequiresClarification() bool {
    return !p.IsConfident() || p.IsAmbiguous()
}

func (p *ParsedIntent) IsCreateAction() bool {
    return p.Action == ActionCreate
}

func (p *ParsedIntent) IsModifyAction() bool {
    return p.Action == ActionUpdate || 
           p.Action == ActionDelete || 
           p.Action == ActionComplete
}
```

### Example Usage

```go
intent := &entity.ParsedIntent{
    Action:           entity.ActionCreate,
    Confidence:       0.95,
    DetectedLanguage: entity.LangEnglish,
    RawMessage:       "Buy milk tomorrow #groceries",
    Data: entity.IntentData{
        Title:   ptrString("Buy milk"),
        DueDate: ptrTime(tomorrow),
        Tags:    []string{"groceries"},
    },
}

if intent.IsConfident() {
    // Process the intent
} else {
    // Ask for clarification
}
```

---

## Entity: TaskTemplate

### Definition

**Location**: `internal/domain/entity/template.go`

**Purpose**: Reusable task templates with variables

```go
type TaskTemplate struct {
    ID             string
    TelegramUserID int64
    Name           string            // e.g., "daily-standup"
    Title          string            // Supports variables: "{{date}} Standup"
    Description    *string
    Priority       Priority
    Tags           []string
    DueDuration    *time.Duration    // Relative: 24h, 7d
    Recurrence     *RecurrenceRule
    Variables      map[string]string // Variable defaults
    CreatedAt      time.Time
    UpdatedAt      time.Time
}

type RecurrenceRule struct {
    Frequency  RecurrenceFreq
    Interval   int            // Every N units
    DaysOfWeek []time.Weekday // For weekly
    DayOfMonth int            // For monthly
    EndDate    *time.Time
}

type RecurrenceFreq string

const (
    RecurrenceDaily   RecurrenceFreq = "daily"
    RecurrenceWeekly  RecurrenceFreq = "weekly"
    RecurrenceMonthly RecurrenceFreq = "monthly"
)
```

### Business Rules (Methods)

```go
var (
    ErrTemplateNameRequired  = errors.New("template name is required")
    ErrTemplateTitleRequired = errors.New("template title is required")
)

func (t *TaskTemplate) Validate() error {
    if t.Name == "" {
        return ErrTemplateNameRequired
    }
    if t.Title == "" {
        return ErrTemplateTitleRequired
    }
    return nil
}

func (t *TaskTemplate) CreateTodo(userID int64, vars map[string]string) *Todo {
    // Interpolate variables
    title := t.interpolateVariables(t.Title, vars)
    var desc *string
    if t.Description != nil {
        interpolated := t.interpolateVariables(*t.Description, vars)
        desc = &interpolated
    }
    
    // Calculate due date
    var dueDate *time.Time
    if t.DueDuration != nil {
        d := time.Now().Add(*t.DueDuration)
        dueDate = &d
    }
    
    return &Todo{
        TelegramUserID: userID,
        Title:          title,
        Description:    desc,
        Priority:       t.Priority,
        Tags:           t.Tags,
        DueDate:        dueDate,
        Status:         StatusPending,
        CreatedAt:      time.Now(),
        UpdatedAt:      time.Now(),
    }
}

func (t *TaskTemplate) interpolateVariables(text string, vars map[string]string) string {
    result := text
    
    // Merge default variables with provided ones
    merged := make(map[string]string)
    for k, v := range t.Variables {
        merged[k] = v
    }
    for k, v := range vars {
        merged[k] = v
    }
    
    // Replace {{variable}} patterns
    for k, v := range merged {
        result = strings.ReplaceAll(result, "{{"+k+"}}", v)
    }
    
    return result
}

func (t *TaskTemplate) HasRecurrence() bool {
    return t.Recurrence != nil
}

func (t *TaskTemplate) NextOccurrence() *time.Time {
    if !t.HasRecurrence() {
        return nil
    }
    
    now := time.Now()
    var next time.Time
    
    switch t.Recurrence.Frequency {
    case RecurrenceDaily:
        next = now.AddDate(0, 0, t.Recurrence.Interval)
    case RecurrenceWeekly:
        next = now.AddDate(0, 0, 7*t.Recurrence.Interval)
    case RecurrenceMonthly:
        next = now.AddDate(0, t.Recurrence.Interval, 0)
    }
    
    // Check if past end date
    if t.Recurrence.EndDate != nil && next.After(*t.Recurrence.EndDate) {
        return nil
    }
    
    return &next
}
```

### Example Usage

```go
template := &entity.TaskTemplate{
    Name:  "daily-standup",
    Title: "Daily Standup - {{date}}",
    Description: ptrString("Yesterday: {{yesterday}}\nToday: {{today}}"),
    Priority: entity.PriorityMedium,
    Tags: []string{"work", "meeting"},
    DueDuration: ptrDuration(9 * time.Hour),
    Variables: map[string]string{
        "date": time.Now().Format("Jan 2"),
        "yesterday": "",
        "today": "",
    },
}

// Create todo from template
vars := map[string]string{
    "yesterday": "Finished feature X",
    "today": "Working on feature Y",
}
todo := template.CreateTodo(123456789, vars)

// Check next occurrence
if nextDate := template.NextOccurrence(); nextDate != nil {
    fmt.Printf("Next occurrence: %s\n", nextDate)
}
```

---

## Common Patterns

### Pointer Fields

Use pointers for optional fields:

```go
type Todo struct {
    Description *string     // Optional
    DueDate     *time.Time  // Optional
}

// Helper function
func ptrString(s string) *string {
    return &s
}

// Usage
todo.Description = ptrString("Details here")
```

### Custom Errors

Define domain-specific errors:

```go
var (
    ErrTitleRequired    = errors.New("title is required")
    ErrTodoNotFound     = errors.New("todo not found")
    ErrInvalidTransition = errors.New("invalid status transition")
)
```

### Validation

Centralized validation in entity methods:

```go
func (t *Todo) Validate() error {
    if t.Title == "" {
        return ErrTitleRequired
    }
    // More validation...
    return nil
}
```

### Encapsulation

Keep fields public but use methods for business logic:

```go
// Public fields for easy serialization
type Todo struct {
    Status Status
}

// But use methods for state changes
func (t *Todo) MarkComplete() error {
    // Business logic here
    t.Status = StatusCompleted
    return nil
}
```

## Testing Entities

```go
func TestTodo_Validate(t *testing.T) {
    tests := []struct {
        name    string
        todo    *entity.Todo
        wantErr error
    }{
        {
            name: "valid todo",
            todo: &entity.Todo{
                Title:    "Test",
                Priority: entity.PriorityMedium,
                Status:   entity.StatusPending,
            },
            wantErr: nil,
        },
        {
            name: "empty title",
            todo: &entity.Todo{
                Title: "",
            },
            wantErr: entity.ErrTitleRequired,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := tt.todo.Validate()
            if tt.wantErr != nil {
                assert.Equal(t, tt.wantErr, err)
            } else {
                assert.NoError(t, err)
            }
        })
    }
}

func TestTodo_MarkComplete(t *testing.T) {
    todo := &entity.Todo{
        Status: entity.StatusPending,
    }
    
    err := todo.MarkComplete()
    
    assert.NoError(t, err)
    assert.Equal(t, entity.StatusCompleted, todo.Status)
}
```

## Next Steps

- Read [Domain Services](07-domain-services.md) for application services
- See [Port Interfaces](08-port-interfaces.md) for interface definitions
- Review [Testing Strategy](05-testing-strategy.md) for testing entities
