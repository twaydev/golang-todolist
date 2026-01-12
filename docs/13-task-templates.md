# Task Templates

## Overview

Task templates allow users to create reusable task structures with variables, default values, and recurrence patterns. Templates can be **global** (shipped with the bot) or **user-defined** (stored per user).

**Location**: 
- Global templates: `templates/*.yaml`
- User templates: Database (`task_templates` table)
- Template entity: `internal/domain/entity/template.go`
- Template service: `internal/domain/service/template_service.go`

## Use Cases

- 📋 **Recurring tasks**: Daily standup, weekly review
- 🐛 **Bug tracking**: Standardized bug fix format
- 📝 **Meeting notes**: Consistent meeting structure
- ✅ **Checklists**: Onboarding, deployment steps
- 💼 **Work patterns**: Code review, client call

## TaskTemplate Entity

```go
// internal/domain/entity/template.go
package entity

import "time"

type TaskTemplate struct {
    ID             string
    TelegramUserID int64              // 0 for global templates
    Name           string              // Template name (e.g., "daily-standup")
    Title          string              // Title with variable placeholders
    Description    *string             // Description with placeholders
    Priority       Priority            // Default priority
    Tags           []string            // Default tags
    DueDuration    *time.Duration      // Relative due date (e.g., 24h, 7d)
    Recurrence     *RecurrenceRule     // Optional recurrence pattern
    Variables      map[string]string   // Variable definitions with defaults
    CreatedAt      time.Time
    UpdatedAt      time.Time
}

type RecurrenceRule struct {
    Frequency  RecurrenceFreq  // daily, weekly, monthly
    Interval   int             // Every N frequency units (e.g., every 2 weeks)
    DaysOfWeek []time.Weekday  // For weekly: which days (Monday, Friday)
    DayOfMonth int             // For monthly: which day (1-31)
    EndDate    *time.Time      // Optional end date for recurrence
}

type RecurrenceFreq string

const (
    RecurrenceDaily   RecurrenceFreq = "daily"
    RecurrenceWeekly  RecurrenceFreq = "weekly"
    RecurrenceMonthly RecurrenceFreq = "monthly"
)
```

## Business Rules

```go
// Validation
func (t *TaskTemplate) Validate() error {
    if t.Name == "" {
        return ErrTemplateNameRequired
    }
    if t.Title == "" {
        return ErrTemplateTitleRequired
    }
    if !isValidTemplateName(t.Name) {
        return ErrInvalidTemplateName // Must be lowercase, alphanumeric, hyphens only
    }
    return nil
}

func isValidTemplateName(name string) bool {
    // Only lowercase letters, numbers, and hyphens
    match, _ := regexp.MatchString(`^[a-z0-9-]+$`, name)
    return match
}

// Create todo from template
func (t *TaskTemplate) CreateTodo(userID int64, vars map[string]string) *Todo {
    title := t.interpolateVariables(t.Title, vars)
    
    var desc *string
    if t.Description != nil {
        d := t.interpolateVariables(*t.Description, vars)
        desc = &d
    }
    
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
    }
}

// Variable interpolation
func (t *TaskTemplate) interpolateVariables(text string, vars map[string]string) string {
    result := text
    
    // Merge defaults with provided variables
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
    
    // Special variables
    result = strings.ReplaceAll(result, "{{now:Mon Jan 2}}", time.Now().Format("Mon Jan 2"))
    result = strings.ReplaceAll(result, "{{today}}", time.Now().Format("2006-01-02"))
    
    return result
}
```

## Template File Format

### Example: Daily Standup

```yaml
# templates/daily-standup.yaml
name: daily-standup
title: "Daily Standup - {{date}}"
description: |
  What I did yesterday:
  - {{yesterday}}
  
  What I'm doing today:
  - {{today}}
  
  Blockers:
  - {{blockers}}
priority: medium
tags:
  - work
  - meeting
due_duration: 9h  # Due 9 hours from creation
variables:
  date: "{{now:Mon Jan 2}}"
  yesterday: ""
  today: ""
  blockers: "None"
```

### Example: Weekly Review with Recurrence

```yaml
# templates/weekly-review.yaml
name: weekly-review
title: "Weekly Review - Week {{week}}"
description: |
  ## Accomplishments
  {{accomplishments}}
  
  ## Challenges
  {{challenges}}
  
  ## Next Week Goals
  {{goals}}
priority: high
tags:
  - review
  - planning
due_duration: 168h  # 7 days
recurrence:
  frequency: weekly
  interval: 1
  days_of_week: [friday]
variables:
  week: "{{now:W}}"
  accomplishments: ""
  challenges: ""
  goals: ""
```

### Example: Bug Fix Template

```yaml
# templates/bug-fix.yaml
name: bug-fix
title: "Fix: {{issue}}"
description: |
  **Issue:** {{issue}}
  **Severity:** {{severity}}
  **Steps to reproduce:**
  {{steps}}
  
  **Expected behavior:**
  {{expected}}
  
  **Actual behavior:**
  {{actual}}
priority: high
tags:
  - bug
  - code
variables:
  issue: ""
  severity: "medium"
  steps: ""
  expected: ""
  actual: ""
```

### Example: Meeting Notes

```yaml
# templates/meeting-notes.yaml
name: meeting-notes
title: "Meeting: {{topic}} - {{date}}"
description: |
  **Attendees:** {{attendees}}
  
  **Agenda:**
  {{agenda}}
  
  **Discussion:**
  {{discussion}}
  
  **Action Items:**
  {{actions}}
  
  **Next Steps:**
  {{next}}
priority: medium
tags:
  - meeting
  - notes
due_duration: 3h
variables:
  date: "{{today}}"
  topic: ""
  attendees: ""
  agenda: ""
  discussion: ""
  actions: ""
  next: ""
```

## Template Repository Port

```go
// internal/domain/port/output/template_repository.go
package output

type TemplateRepository interface {
    // Get template by name (checks user templates first, then global)
    GetByName(ctx context.Context, userID int64, name string) (*entity.TaskTemplate, error)
    
    // List all templates available to user (user + global)
    List(ctx context.Context, userID int64) ([]*entity.TaskTemplate, error)
    
    // List only global templates
    ListGlobal(ctx context.Context) ([]*entity.TaskTemplate, error)
    
    // User template CRUD
    Create(ctx context.Context, template *entity.TaskTemplate) error
    Update(ctx context.Context, template *entity.TaskTemplate) error
    Delete(ctx context.Context, userID int64, name string) error
}
```

## File-Based Template Adapter

```go
// internal/adapter/driven/filesystem/template_repo.go
package filesystem

type FileTemplateRepository struct {
    templatesDir string
    cache        map[string]*entity.TaskTemplate
    mu           sync.RWMutex
}

func NewFileTemplateRepository(dir string) (*FileTemplateRepository, error) {
    repo := &FileTemplateRepository{
        templatesDir: dir,
        cache:        make(map[string]*entity.TaskTemplate),
    }
    if err := repo.loadTemplates(); err != nil {
        return nil, err
    }
    return repo, nil
}

func (r *FileTemplateRepository) loadTemplates() error {
    files, err := filepath.Glob(filepath.Join(r.templatesDir, "*.yaml"))
    if err != nil {
        return err
    }
    
    for _, file := range files {
        data, err := os.ReadFile(file)
        if err != nil {
            log.Printf("Failed to read template %s: %v", file, err)
            continue
        }
        
        var tmpl entity.TaskTemplate
        if err := yaml.Unmarshal(data, &tmpl); err != nil {
            log.Printf("Failed to parse template %s: %v", file, err)
            continue
        }
        
        if err := tmpl.Validate(); err != nil {
            log.Printf("Invalid template %s: %v", file, err)
            continue
        }
        
        r.cache[tmpl.Name] = &tmpl
    }
    
    log.Printf("Loaded %d global templates", len(r.cache))
    return nil
}

func (r *FileTemplateRepository) GetByName(ctx context.Context, userID int64, name string) (*entity.TaskTemplate, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    
    tmpl, ok := r.cache[name]
    if !ok {
        return nil, fmt.Errorf("template %q not found", name)
    }
    return tmpl, nil
}

func (r *FileTemplateRepository) ListGlobal(ctx context.Context) ([]*entity.TaskTemplate, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    
    templates := make([]*entity.TaskTemplate, 0, len(r.cache))
    for _, t := range r.cache {
        templates = append(templates, t)
    }
    return templates, nil
}

// File-based repository doesn't support user templates
func (r *FileTemplateRepository) List(ctx context.Context, userID int64) ([]*entity.TaskTemplate, error) {
    return r.ListGlobal(ctx)
}

func (r *FileTemplateRepository) Create(ctx context.Context, template *entity.TaskTemplate) error {
    return fmt.Errorf("file-based repository does not support creating templates")
}

func (r *FileTemplateRepository) Update(ctx context.Context, template *entity.TaskTemplate) error {
    return fmt.Errorf("file-based repository does not support updating templates")
}

func (r *FileTemplateRepository) Delete(ctx context.Context, userID int64, name string) error {
    return fmt.Errorf("file-based repository does not support deleting templates")
}
```

## Database Template Adapter

```go
// internal/adapter/driven/postgres/template_repo.go
type PostgresTemplateRepository struct {
    pool *pgxpool.Pool
}

func (r *PostgresTemplateRepository) Create(ctx context.Context, template *entity.TaskTemplate) error {
    query := `
        INSERT INTO task_templates (telegram_user_id, name, title, description, priority, 
                                   tags, due_duration, recurrence, variables)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING id, created_at, updated_at`
    
    var recurrenceJSON []byte
    if template.Recurrence != nil {
        recurrenceJSON, _ = json.Marshal(template.Recurrence)
    }
    
    variablesJSON, _ := json.Marshal(template.Variables)
    
    return r.pool.QueryRow(ctx, query,
        template.TelegramUserID,
        template.Name,
        template.Title,
        template.Description,
        template.Priority,
        template.Tags,
        template.DueDuration,
        recurrenceJSON,
        variablesJSON,
    ).Scan(&template.ID, &template.CreatedAt, &template.UpdatedAt)
}

func (r *PostgresTemplateRepository) List(ctx context.Context, userID int64) ([]*entity.TaskTemplate, error) {
    query := `
        SELECT id, name, title, description, priority, tags, due_duration, 
               recurrence, variables, created_at, updated_at
        FROM task_templates
        WHERE telegram_user_id = $1
        ORDER BY name`
    
    rows, err := r.pool.Query(ctx, query, userID)
    if err != nil {
        return nil, err
    }
    defer rows.Close()
    
    var templates []*entity.TaskTemplate
    for rows.Next() {
        tmpl := &entity.TaskTemplate{}
        var recurrenceJSON, variablesJSON []byte
        
        err := rows.Scan(
            &tmpl.ID, &tmpl.Name, &tmpl.Title, &tmpl.Description,
            &tmpl.Priority, &tmpl.Tags, &tmpl.DueDuration,
            &recurrenceJSON, &variablesJSON,
            &tmpl.CreatedAt, &tmpl.UpdatedAt,
        )
        if err != nil {
            return nil, err
        }
        
        tmpl.TelegramUserID = userID
        
        if len(recurrenceJSON) > 0 {
            json.Unmarshal(recurrenceJSON, &tmpl.Recurrence)
        }
        if len(variablesJSON) > 0 {
            json.Unmarshal(variablesJSON, &tmpl.Variables)
        }
        
        templates = append(templates, tmpl)
    }
    
    return templates, rows.Err()
}
```

## Template Service

```go
// internal/domain/service/template_service.go
package service

type TemplateService struct {
    globalRepo port.TemplateRepository  // Filesystem adapter (global templates)
    userRepo   port.TemplateRepository  // PostgreSQL adapter (user templates)
    todoRepo   port.TodoRepository
}

func NewTemplateService(
    globalRepo port.TemplateRepository,
    userRepo port.TemplateRepository,
    todoRepo port.TodoRepository,
) *TemplateService {
    return &TemplateService{
        globalRepo: globalRepo,
        userRepo:   userRepo,
        todoRepo:   todoRepo,
    }
}

// Create todo from template
func (s *TemplateService) CreateFromTemplate(
    ctx context.Context,
    userID int64,
    templateName string,
    variables map[string]string,
) (*entity.Todo, error) {
    // Try user templates first
    tmpl, err := s.userRepo.GetByName(ctx, userID, templateName)
    if err != nil || tmpl == nil {
        // Fall back to global templates
        tmpl, err = s.globalRepo.GetByName(ctx, userID, templateName)
        if err != nil {
            return nil, fmt.Errorf("template %q not found", templateName)
        }
    }
    
    // Create todo from template
    todo := tmpl.CreateTodo(userID, variables)
    
    if err := s.todoRepo.Create(ctx, todo); err != nil {
        return nil, err
    }
    
    return todo, nil
}

// List all available templates (user + global)
func (s *TemplateService) ListTemplates(
    ctx context.Context,
    userID int64,
) ([]*entity.TaskTemplate, error) {
    userTemplates, _ := s.userRepo.List(ctx, userID)
    globalTemplates, _ := s.globalRepo.ListGlobal(ctx)
    
    // User templates override global ones with same name
    byName := make(map[string]*entity.TaskTemplate)
    
    // Add global templates first
    for _, t := range globalTemplates {
        byName[t.Name] = t
    }
    
    // User templates override
    for _, t := range userTemplates {
        byName[t.Name] = t
    }
    
    result := make([]*entity.TaskTemplate, 0, len(byName))
    for _, t := range byName {
        result = append(result, t)
    }
    
    return result, nil
}

// Create user template
func (s *TemplateService) CreateUserTemplate(
    ctx context.Context,
    template *entity.TaskTemplate,
) error {
    if err := template.Validate(); err != nil {
        return err
    }
    
    return s.userRepo.Create(ctx, template)
}

// Delete user template
func (s *TemplateService) DeleteUserTemplate(
    ctx context.Context,
    userID int64,
    name string,
) error {
    return s.userRepo.Delete(ctx, userID, name)
}
```

## Usage via Natural Language

Users can create tasks from templates using natural language:

```
User: "Create daily standup"
Bot: ✅ Todo Created
     Code: 26-0042
     Title: Daily Standup - Fri Jan 10
     Priority: Medium
     Tags: work, meeting

User: "Create bug fix for login error"
Bot: ✅ Todo Created
     Code: 26-0043
     Title: Fix: login error
     Priority: High
     Tags: bug, code

User: "Show templates"
Bot: 📋 Available Templates (4)
     
     daily-standup - Daily standup meeting
     weekly-review - Weekly review and planning
     bug-fix - Bug fix template
     meeting-notes - Meeting notes template
```

## Intent Extension

```go
// Extended ActionType for templates
const (
    ActionCreateFromTemplate ActionType = "create_from_template"
    ActionListTemplates      ActionType = "list_templates"
    ActionSaveTemplate       ActionType = "save_template"
    ActionDeleteTemplate     ActionType = "delete_template"
)

// Extended IntentData
type IntentData struct {
    // ... existing fields
    TemplateName      *string           `json:"template_name,omitempty"`
    TemplateVariables map[string]string `json:"template_variables,omitempty"`
}
```

## Database Schema

```sql
-- User-defined templates
CREATE TABLE IF NOT EXISTS task_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    telegram_user_id BIGINT NOT NULL,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    priority TEXT CHECK (priority IN ('low', 'medium', 'high')) DEFAULT 'medium',
    tags TEXT[],
    due_duration INTERVAL,
    recurrence JSONB,
    variables JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (telegram_user_id, name)
);

CREATE INDEX idx_templates_user ON task_templates(telegram_user_id);
CREATE INDEX idx_templates_name ON task_templates(name);

-- Enable RLS
ALTER TABLE task_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own templates" ON task_templates
    FOR ALL USING (true);
```

## Testing

```go
func TestTaskTemplate_CreateTodo(t *testing.T) {
    tmpl := &entity.TaskTemplate{
        Name:     "test-template",
        Title:    "Task: {{name}}",
        Priority: entity.PriorityHigh,
        Tags:     []string{"test"},
        Variables: map[string]string{
            "name": "default",
        },
    }
    
    todo := tmpl.CreateTodo(123, map[string]string{"name": "example"})
    
    assert.Equal(t, "Task: example", todo.Title)
    assert.Equal(t, entity.PriorityHigh, todo.Priority)
    assert.Equal(t, []string{"test"}, todo.Tags)
}
```

## Best Practices

1. **Variable Naming**: Use descriptive names (e.g., `{{issue}}` not `{{x}}`)
2. **Default Values**: Provide sensible defaults for optional variables
3. **Documentation**: Include description in template files
4. **Testing**: Test templates with various variable combinations
5. **Validation**: Validate template format on load

## Next Steps

- See [Domain Entities](06-domain-entities.md) for TaskTemplate entity details
- Review [Domain Services](07-domain-services.md) for TemplateService
- Read [Database Schema](15-database-schema.md) for task_templates table
