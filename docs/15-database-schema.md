# Database Schema

## Overview

The application uses **PostgreSQL 15+** hosted on **Supabase** with Row-Level Security (RLS) for data isolation. The schema supports multi-tenant architecture with user-specific data segregation.

**Key Features**:
- ✅ Row-Level Security (RLS) for data isolation
- ✅ Auto-generated sequential codes (YY-NNNN format)
- ✅ Full-text search with GIN indexes
- ✅ Auto-updated timestamps
- ✅ JSONB for flexible data structures
- ✅ Triggers for business logic

## Tables

### 1. todos

Main task storage table.

```sql
CREATE TABLE IF NOT EXISTS todos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    telegram_user_id BIGINT NOT NULL,
    code TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    description TEXT,
    due_date TIMESTAMP WITH TIME ZONE,
    priority TEXT CHECK (priority IN ('low', 'medium', 'high')) DEFAULT 'medium',
    status TEXT CHECK (status IN ('pending', 'completed', 'cancelled')) DEFAULT 'pending',
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX idx_todos_user ON todos(telegram_user_id);
CREATE INDEX idx_todos_status ON todos(status);
CREATE INDEX idx_todos_due_date ON todos(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_todos_priority ON todos(priority);
CREATE INDEX idx_todos_tags ON todos USING GIN(tags);

-- Full-text search
CREATE INDEX idx_todos_search ON todos USING GIN(
    to_tsvector('english', title || ' ' || COALESCE(description, ''))
);

-- Composite index for common queries
CREATE INDEX idx_todos_user_status ON todos(telegram_user_id, status);
```

**Columns**:
- `id` - UUID primary key
- `telegram_user_id` - Telegram user ID for data isolation
- `code` - Sequential code (e.g., `26-0001`) - unique per user per year
- `title` - Task title
- `description` - Optional detailed description
- `due_date` - Optional due date with timezone
- `priority` - low, medium, high
- `status` - pending, completed, cancelled
- `tags` - Array of string tags
- `created_at` - Creation timestamp
- `updated_at` - Last update timestamp
- `completed_at` - Completion timestamp (when status changed to completed)

### 2. user_preferences

User settings and preferences.

```sql
CREATE TABLE IF NOT EXISTS user_preferences (
    telegram_user_id BIGINT PRIMARY KEY,
    language TEXT CHECK (language IN ('en', 'vi')) DEFAULT 'en',
    timezone TEXT DEFAULT 'UTC',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX idx_preferences_language ON user_preferences(language);
```

**Columns**:
- `telegram_user_id` - Telegram user ID (primary key)
- `language` - User's preferred language (en, vi)
- `timezone` - User's timezone (e.g., "Asia/Ho_Chi_Minh", "UTC")
- `created_at` - Creation timestamp
- `updated_at` - Last update timestamp

### 3. code_sequences

Auto-increment sequence tracking for todo codes.

```sql
CREATE TABLE IF NOT EXISTS code_sequences (
    telegram_user_id BIGINT NOT NULL,
    year_prefix TEXT NOT NULL,
    last_number INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (telegram_user_id, year_prefix)
);

-- Index
CREATE INDEX idx_sequences_user ON code_sequences(telegram_user_id);
```

**Columns**:
- `telegram_user_id` - User ID
- `year_prefix` - Two-digit year (e.g., "26" for 2026)
- `last_number` - Last used sequence number for this user/year

**Usage**: Generates codes like `26-0001`, `26-0002`, etc.

### 4. task_templates

User-defined task templates.

```sql
CREATE TABLE IF NOT EXISTS task_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    telegram_user_id BIGINT NOT NULL,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    priority TEXT CHECK (priority IN ('low', 'medium', 'high')) DEFAULT 'medium',
    tags TEXT[] DEFAULT '{}',
    due_duration INTERVAL,
    recurrence JSONB,
    variables JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (telegram_user_id, name)
);

-- Indexes
CREATE INDEX idx_templates_user ON task_templates(telegram_user_id);
CREATE INDEX idx_templates_name ON task_templates(name);
```

**Columns**:
- `id` - UUID primary key
- `telegram_user_id` - User ID
- `name` - Template name (unique per user)
- `title` - Template title with variable placeholders
- `description` - Template description
- `priority` - Default priority
- `tags` - Default tags array
- `due_duration` - Relative due date (e.g., '24 hours')
- `recurrence` - Recurrence rules as JSON
- `variables` - Variable definitions with defaults as JSON
- `created_at` - Creation timestamp
- `updated_at` - Last update timestamp

## Triggers

### Auto-update timestamps

```sql
-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to todos
CREATE TRIGGER update_todos_updated_at
    BEFORE UPDATE ON todos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply to user_preferences
CREATE TRIGGER update_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply to task_templates
CREATE TRIGGER update_templates_updated_at
    BEFORE UPDATE ON task_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### Auto-set completed_at

```sql
-- Function to set completed_at when status changes to completed
CREATE OR REPLACE FUNCTION set_completed_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        NEW.completed_at = NOW();
    ELSIF NEW.status != 'completed' THEN
        NEW.completed_at = NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to todos
CREATE TRIGGER set_todos_completed_at
    BEFORE UPDATE ON todos
    FOR EACH ROW
    EXECUTE FUNCTION set_completed_at();
```

### Auto-generate todo codes

```sql
-- Function to generate next code for user
CREATE OR REPLACE FUNCTION generate_todo_code(user_id BIGINT)
RETURNS TEXT AS $$
DECLARE
    year_prefix TEXT;
    next_number INTEGER;
    new_code TEXT;
BEGIN
    -- Get current year (last 2 digits)
    year_prefix := TO_CHAR(NOW(), 'YY');
    
    -- Get or create sequence for this user/year
    INSERT INTO code_sequences (telegram_user_id, year_prefix, last_number)
    VALUES (user_id, year_prefix, 1)
    ON CONFLICT (telegram_user_id, year_prefix)
    DO UPDATE SET last_number = code_sequences.last_number + 1
    RETURNING last_number INTO next_number;
    
    -- Format code as YY-NNNN
    new_code := year_prefix || '-' || LPAD(next_number::TEXT, 4, '0');
    
    RETURN new_code;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate code on insert
CREATE OR REPLACE FUNCTION set_todo_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.code IS NULL OR NEW.code = '' THEN
        NEW.code := generate_todo_code(NEW.telegram_user_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_todos_code
    BEFORE INSERT ON todos
    FOR EACH ROW
    EXECUTE FUNCTION set_todo_code();
```

## Row-Level Security (RLS)

Enable RLS to ensure users can only access their own data.

```sql
-- Enable RLS on all tables
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE code_sequences ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_templates ENABLE ROW LEVEL SECURITY;

-- Service role has full access (used by the application)
CREATE POLICY "Enable all operations for service role"
    ON todos FOR ALL
    USING (true);

CREATE POLICY "Enable all operations for service role"
    ON user_preferences FOR ALL
    USING (true);

CREATE POLICY "Enable all operations for service role"
    ON code_sequences FOR ALL
    USING (true);

CREATE POLICY "Enable all operations for service role"
    ON task_templates FOR ALL
    USING (true);
```

**Note**: In production, you would add more granular policies for user-specific access if using direct client connections.

## Views

### Pending Todos

```sql
CREATE OR REPLACE VIEW pending_todos AS
SELECT 
    id,
    telegram_user_id,
    code,
    title,
    description,
    due_date,
    priority,
    tags,
    created_at,
    updated_at,
    CASE
        WHEN due_date < NOW() THEN 'overdue'
        WHEN due_date < NOW() + INTERVAL '24 hours' THEN 'due_soon'
        ELSE 'normal'
    END AS urgency
FROM todos
WHERE status = 'pending'
ORDER BY 
    CASE priority
        WHEN 'high' THEN 1
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 3
    END,
    due_date NULLS LAST,
    created_at DESC;
```

### Today's Todos

```sql
CREATE OR REPLACE VIEW todays_todos AS
SELECT *
FROM todos
WHERE status = 'pending'
  AND due_date IS NOT NULL
  AND DATE(due_date) = CURRENT_DATE
ORDER BY
    CASE priority
        WHEN 'high' THEN 1
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 3
    END,
    due_date;
```

### Overdue Todos

```sql
CREATE OR REPLACE VIEW overdue_todos AS
SELECT *
FROM todos
WHERE status = 'pending'
  AND due_date < NOW()
ORDER BY due_date;
```

## Migration File

### migrations/001_initial.sql

```sql
-- Initial migration for Telegram Todo Bot
-- Version: 001
-- Description: Create todos, user_preferences, code_sequences, task_templates tables

BEGIN;

-- 1. Create todos table
CREATE TABLE IF NOT EXISTS todos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    telegram_user_id BIGINT NOT NULL,
    code TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    description TEXT,
    due_date TIMESTAMP WITH TIME ZONE,
    priority TEXT CHECK (priority IN ('low', 'medium', 'high')) DEFAULT 'medium',
    status TEXT CHECK (status IN ('pending', 'completed', 'cancelled')) DEFAULT 'pending',
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 2. Create user_preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
    telegram_user_id BIGINT PRIMARY KEY,
    language TEXT CHECK (language IN ('en', 'vi')) DEFAULT 'en',
    timezone TEXT DEFAULT 'UTC',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create code_sequences table
CREATE TABLE IF NOT EXISTS code_sequences (
    telegram_user_id BIGINT NOT NULL,
    year_prefix TEXT NOT NULL,
    last_number INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (telegram_user_id, year_prefix)
);

-- 4. Create task_templates table
CREATE TABLE IF NOT EXISTS task_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    telegram_user_id BIGINT NOT NULL,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    priority TEXT CHECK (priority IN ('low', 'medium', 'high')) DEFAULT 'medium',
    tags TEXT[] DEFAULT '{}',
    due_duration INTERVAL,
    recurrence JSONB,
    variables JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (telegram_user_id, name)
);

-- 5. Create indexes
CREATE INDEX idx_todos_user ON todos(telegram_user_id);
CREATE INDEX idx_todos_status ON todos(status);
CREATE INDEX idx_todos_due_date ON todos(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_todos_priority ON todos(priority);
CREATE INDEX idx_todos_tags ON todos USING GIN(tags);
CREATE INDEX idx_todos_user_status ON todos(telegram_user_id, status);
CREATE INDEX idx_todos_search ON todos USING GIN(
    to_tsvector('english', title || ' ' || COALESCE(description, ''))
);

CREATE INDEX idx_preferences_language ON user_preferences(language);
CREATE INDEX idx_sequences_user ON code_sequences(telegram_user_id);
CREATE INDEX idx_templates_user ON task_templates(telegram_user_id);
CREATE INDEX idx_templates_name ON task_templates(name);

-- 6. Create trigger functions
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_completed_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        NEW.completed_at = NOW();
    ELSIF NEW.status != 'completed' THEN
        NEW.completed_at = NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_todo_code(user_id BIGINT)
RETURNS TEXT AS $$
DECLARE
    year_prefix TEXT;
    next_number INTEGER;
    new_code TEXT;
BEGIN
    year_prefix := TO_CHAR(NOW(), 'YY');
    
    INSERT INTO code_sequences (telegram_user_id, year_prefix, last_number)
    VALUES (user_id, year_prefix, 1)
    ON CONFLICT (telegram_user_id, year_prefix)
    DO UPDATE SET last_number = code_sequences.last_number + 1
    RETURNING last_number INTO next_number;
    
    new_code := year_prefix || '-' || LPAD(next_number::TEXT, 4, '0');
    
    RETURN new_code;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_todo_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.code IS NULL OR NEW.code = '' THEN
        NEW.code := generate_todo_code(NEW.telegram_user_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Create triggers
CREATE TRIGGER update_todos_updated_at
    BEFORE UPDATE ON todos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_templates_updated_at
    BEFORE UPDATE ON task_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_todos_completed_at
    BEFORE UPDATE ON todos
    FOR EACH ROW
    EXECUTE FUNCTION set_completed_at();

CREATE TRIGGER set_todos_code
    BEFORE INSERT ON todos
    FOR EACH ROW
    EXECUTE FUNCTION set_todo_code();

-- 8. Enable RLS
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE code_sequences ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable all operations for service role"
    ON todos FOR ALL USING (true);

CREATE POLICY "Enable all operations for service role"
    ON user_preferences FOR ALL USING (true);

CREATE POLICY "Enable all operations for service role"
    ON code_sequences FOR ALL USING (true);

CREATE POLICY "Enable all operations for service role"
    ON task_templates FOR ALL USING (true);

-- 9. Create views
CREATE OR REPLACE VIEW pending_todos AS
SELECT 
    id, telegram_user_id, code, title, description,
    due_date, priority, tags, created_at, updated_at,
    CASE
        WHEN due_date < NOW() THEN 'overdue'
        WHEN due_date < NOW() + INTERVAL '24 hours' THEN 'due_soon'
        ELSE 'normal'
    END AS urgency
FROM todos
WHERE status = 'pending'
ORDER BY 
    CASE priority
        WHEN 'high' THEN 1
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 3
    END,
    due_date NULLS LAST,
    created_at DESC;

COMMIT;
```

## Query Examples

### Create a todo (code auto-generated)
```sql
INSERT INTO todos (telegram_user_id, title, priority, tags)
VALUES (123456789, 'Buy groceries', 'medium', ARRAY['shopping']);
-- Result: code will be auto-generated like '26-0001'
```

### List pending todos for user
```sql
SELECT * FROM pending_todos
WHERE telegram_user_id = 123456789
LIMIT 20;
```

### Full-text search
```sql
SELECT * FROM todos
WHERE telegram_user_id = 123456789
  AND to_tsvector('english', title || ' ' || COALESCE(description, ''))
      @@ plainto_tsquery('english', 'groceries shopping');
```

### Filter by tags
```sql
SELECT * FROM todos
WHERE telegram_user_id = 123456789
  AND tags && ARRAY['work', 'urgent'];  -- Contains any of these tags
```

## Performance Optimization

1. **Use prepared statements** in Go code
2. **Connection pooling** (25 max, 5 min connections)
3. **Index-only scans** where possible
4. **Partial indexes** for filtered queries
5. **GIN indexes** for arrays and full-text search
6. **Regular VACUUM** and ANALYZE

## Migration Management

```bash
# Using Supabase CLI
supabase migration new add_feature_x     # Create new migration
supabase db reset                        # Reset local DB
supabase db push                         # Push to production
```

## Next Steps

- See [Database Layer](11-database-layer.md) for repository implementation
- Review [CI/CD Pipeline](16-cicd-pipeline.md) for migration deployment
- Read [Configuration](17-configuration.md) for DATABASE_URL setup
