# Configuration

## Overview

The application uses **environment variables** for configuration. This approach allows for easy deployment across different environments (development, staging, production) without code changes.

**Configuration Package**: `internal/config/config.go`

## Environment Variables

### Required Variables

| Variable | Description | Example | Where to get |
|----------|-------------|---------|--------------|
| `TELEGRAM_BOT_TOKEN` | Telegram Bot API token | `1234567890:ABCdef...` | @BotFather on Telegram |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host:5432/db` | Supabase Dashboard |
| `PERPLEXITY_API_KEY` | Perplexity AI API key | `pplx-...` | perplexity.ai/settings/api |

### Optional Variables

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `DEFAULT_LANGUAGE` | Default user language | `en` | `en`, `vi` |
| `PORT` | HTTP server port | `8080` | Any valid port |
| `LOG_LEVEL` | Logging level | `info` | `debug`, `info`, `warn`, `error` |
| `ENVIRONMENT` | Deployment environment | `production` | `development`, `staging`, `production` |
| `MAX_DB_CONNECTIONS` | Max DB connection pool size | `25` | Integer |
| `MIN_DB_CONNECTIONS` | Min DB connection pool size | `5` | Integer |
| `TEMPLATES_DIR` | Global templates directory | `./templates` | Path |

## Configuration Structure

```go
// internal/config/config.go
package config

import (
    "fmt"
    "os"
    "strconv"
    "time"
)

type Config struct {
    // Required
    TelegramBotToken  string
    DatabaseURL       string
    PerplexityAPIKey  string
    
    // Optional with defaults
    DefaultLanguage   string
    Port              string
    LogLevel          string
    Environment       string
    TemplatesDir      string
    
    // Database
    MaxDBConnections  int
    MinDBConnections  int
    DBConnTimeout     time.Duration
    
    // HTTP Server
    ReadTimeout       time.Duration
    WriteTimeout      time.Duration
    ShutdownTimeout   time.Duration
}

func Load() (*Config, error) {
    cfg := &Config{
        // Load required variables
        TelegramBotToken: os.Getenv("TELEGRAM_BOT_TOKEN"),
        DatabaseURL:      os.Getenv("DATABASE_URL"),
        PerplexityAPIKey: os.Getenv("PERPLEXITY_API_KEY"),
        
        // Load optional with defaults
        DefaultLanguage:  getEnvOrDefault("DEFAULT_LANGUAGE", "en"),
        Port:             getEnvOrDefault("PORT", "8080"),
        LogLevel:         getEnvOrDefault("LOG_LEVEL", "info"),
        Environment:      getEnvOrDefault("ENVIRONMENT", "production"),
        TemplatesDir:     getEnvOrDefault("TEMPLATES_DIR", "./templates"),
        
        // Database config
        MaxDBConnections: getEnvAsInt("MAX_DB_CONNECTIONS", 25),
        MinDBConnections: getEnvAsInt("MIN_DB_CONNECTIONS", 5),
        DBConnTimeout:    getEnvAsDuration("DB_CONN_TIMEOUT", 30*time.Second),
        
        // HTTP config
        ReadTimeout:      getEnvAsDuration("HTTP_READ_TIMEOUT", 10*time.Second),
        WriteTimeout:     getEnvAsDuration("HTTP_WRITE_TIMEOUT", 10*time.Second),
        ShutdownTimeout:  getEnvAsDuration("SHUTDOWN_TIMEOUT", 30*time.Second),
    }
    
    // Validate required fields
    if err := cfg.Validate(); err != nil {
        return nil, err
    }
    
    return cfg, nil
}

func (c *Config) Validate() error {
    if c.TelegramBotToken == "" {
        return fmt.Errorf("TELEGRAM_BOT_TOKEN is required")
    }
    if c.DatabaseURL == "" {
        return fmt.Errorf("DATABASE_URL is required")
    }
    if c.PerplexityAPIKey == "" {
        return fmt.Errorf("PERPLEXITY_API_KEY is required")
    }
    
    // Validate language
    if c.DefaultLanguage != "en" && c.DefaultLanguage != "vi" {
        return fmt.Errorf("DEFAULT_LANGUAGE must be 'en' or 'vi'")
    }
    
    return nil
}

func (c *Config) IsDevelopment() bool {
    return c.Environment == "development"
}

func (c *Config) IsProduction() bool {
    return c.Environment == "production"
}

// Helper functions
func getEnvOrDefault(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
    if value := os.Getenv(key); value != "" {
        if intValue, err := strconv.Atoi(value); err == nil {
            return intValue
        }
    }
    return defaultValue
}

func getEnvAsDuration(key string, defaultValue time.Duration) time.Duration {
    if value := os.Getenv(key); value != "" {
        if duration, err := time.ParseDuration(value); err == nil {
            return duration
        }
    }
    return defaultValue
}
```

## Environment Files

### .env (Development)

```bash
# .env - Local development configuration
# DO NOT COMMIT THIS FILE

# Required
TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/todobot_dev
PERPLEXITY_API_KEY=pplx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Optional
DEFAULT_LANGUAGE=en
PORT=8080
LOG_LEVEL=debug
ENVIRONMENT=development
TEMPLATES_DIR=./templates

# Database
MAX_DB_CONNECTIONS=10
MIN_DB_CONNECTIONS=2

# HTTP
HTTP_READ_TIMEOUT=10s
HTTP_WRITE_TIMEOUT=10s
```

### .env.example (Template)

```bash
# .env.example - Template for environment variables
# Copy to .env and fill in actual values

# Required - Get these from respective services
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here
DATABASE_URL=postgresql://user:password@host:5432/database
PERPLEXITY_API_KEY=your_perplexity_api_key_here

# Optional - These have defaults
DEFAULT_LANGUAGE=en
PORT=8080
LOG_LEVEL=info
ENVIRONMENT=production
```

### .env.test (Testing)

```bash
# .env.test - Test environment configuration
TELEGRAM_BOT_TOKEN=test-token
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/todobot_test
PERPLEXITY_API_KEY=test-key
LOG_LEVEL=debug
ENVIRONMENT=test
```

## Loading Configuration

### In main.go

```go
// cmd/bot/main.go
package main

import (
    "context"
    "log"
    "os"
    "os/signal"
    "syscall"
    
    "todobot/internal/config"
    "todobot/internal/domain/service"
    "todobot/internal/adapter/driven/postgres"
    "todobot/internal/adapter/driven/perplexity"
    "todobot/internal/adapter/driven/filesystem"
    "todobot/internal/adapter/driving/telegram"
    "todobot/internal/adapter/driving/http"
    "todobot/internal/i18n"
)

func main() {
    // Load configuration
    cfg, err := config.Load()
    if err != nil {
        log.Fatalf("Failed to load config: %v", err)
    }
    
    // Setup logging
    setupLogging(cfg.LogLevel)
    
    log.Printf("Starting Telegram Todo Bot...")
    log.Printf("Environment: %s", cfg.Environment)
    log.Printf("Log Level: %s", cfg.LogLevel)
    
    // Initialize database
    db, err := postgres.NewConnection(context.Background(), cfg.DatabaseURL)
    if err != nil {
        log.Fatalf("Failed to connect to database: %v", err)
    }
    defer db.Close()
    
    // Initialize repositories
    todoRepo := postgres.NewTodoRepository(db)
    userRepo := postgres.NewUserRepository(db)
    templateDBRepo := postgres.NewTemplateRepository(db)
    
    // Initialize file-based templates
    templateFileRepo, err := filesystem.NewTemplateRepository(cfg.TemplatesDir)
    if err != nil {
        log.Fatalf("Failed to load templates: %v", err)
    }
    
    // Initialize AI client
    aiClient := perplexity.NewClient(cfg.PerplexityAPIKey)
    
    // Initialize i18n
    translator := i18n.NewTranslator()
    
    // Initialize services
    todoService := service.NewTodoService(todoRepo, userRepo, aiClient, translator)
    userService := service.NewUserService(userRepo, translator)
    templateService := service.NewTemplateService(templateFileRepo, templateDBRepo, todoRepo)
    
    // Initialize Telegram bot
    bot, err := telegram.NewTelegramBot(cfg.TelegramBotToken, todoService, userService)
    if err != nil {
        log.Fatalf("Failed to create Telegram bot: %v", err)
    }
    
    // Initialize HTTP server (for health checks)
    httpServer := http.NewServer(cfg.Port, todoService, userService, templateService)
    
    // Start services
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()
    
    // Start HTTP server
    go func() {
        if err := httpServer.Start(); err != nil {
            log.Printf("HTTP server error: %v", err)
        }
    }()
    
    // Start Telegram bot
    go func() {
        if err := bot.Start(ctx); err != nil {
            log.Printf("Bot error: %v", err)
        }
    }()
    
    // Wait for interrupt signal
    sigChan := make(chan os.Signal, 1)
    signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
    <-sigChan
    
    log.Println("Shutting down gracefully...")
    
    // Shutdown
    shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
    defer shutdownCancel()
    
    if err := httpServer.Shutdown(shutdownCtx); err != nil {
        log.Printf("HTTP server shutdown error: %v", err)
    }
    
    cancel() // Stop bot
    
    log.Println("Shutdown complete")
}
```

## Getting Credentials

### 1. Telegram Bot Token

```bash
# 1. Open Telegram and search for @BotFather
# 2. Start a chat and send: /newbot
# 3. Follow instructions:
#    - Enter bot name: "My Todo Bot"
#    - Enter bot username: "my_todo_bot" (must end with 'bot')
# 4. Copy the token provided
#    Format: 1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
# 5. Add to .env:
TELEGRAM_BOT_TOKEN=your_token_here
```

### 2. Supabase Database URL

```bash
# 1. Go to https://supabase.com
# 2. Create new project or select existing
# 3. Go to: Project Settings → Database
# 4. Copy "Connection string" (URI format)
# 5. Replace [YOUR-PASSWORD] with actual password
# Format: postgresql://postgres:[password]@[host]:5432/postgres
# 6. Add to .env:
DATABASE_URL=postgresql://postgres:yourpassword@db.xxxxx.supabase.co:5432/postgres
```

### 3. Perplexity API Key

```bash
# 1. Go to https://www.perplexity.ai
# 2. Sign up or log in
# 3. Go to: Settings → API
# 4. Click "Create API Key"
# 5. Copy the key (starts with pplx-)
# 6. Add to .env:
PERPLEXITY_API_KEY=pplx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## Environment-Specific Configuration

### Development

```bash
# Use local database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/todobot_dev

# More verbose logging
LOG_LEVEL=debug

# Mark as development
ENVIRONMENT=development
```

### Staging

```bash
# Use staging database
DATABASE_URL=postgresql://postgres:xxx@staging-db.supabase.co:5432/postgres

# Production-like logging
LOG_LEVEL=info

# Mark as staging
ENVIRONMENT=staging
```

### Production

```bash
# Use production database
DATABASE_URL=postgresql://postgres:xxx@prod-db.supabase.co:5432/postgres

# Minimal logging
LOG_LEVEL=warn

# Mark as production
ENVIRONMENT=production
```

## Security Best Practices

1. ✅ **Never commit .env files** - Add to .gitignore
2. ✅ **Use .env.example** as template
3. ✅ **Rotate credentials regularly**
4. ✅ **Use different credentials per environment**
5. ✅ **Store production secrets** in secure vaults (Railway, GitHub Secrets)
6. ✅ **Validate all configuration** on startup
7. ✅ **Use read-only database users** where possible

## .gitignore

```bash
# .gitignore
.env
.env.local
.env.development
.env.staging
.env.production
.env.*.local

# Keep templates
!.env.example
!.env.test
```

## Testing Configuration

```go
// internal/config/config_test.go
package config

import (
    "os"
    "testing"
    
    "github.com/stretchr/testify/assert"
)

func TestLoad_Success(t *testing.T) {
    // Set test environment variables
    os.Setenv("TELEGRAM_BOT_TOKEN", "test-token")
    os.Setenv("DATABASE_URL", "postgresql://test")
    os.Setenv("PERPLEXITY_API_KEY", "test-key")
    defer func() {
        os.Unsetenv("TELEGRAM_BOT_TOKEN")
        os.Unsetenv("DATABASE_URL")
        os.Unsetenv("PERPLEXITY_API_KEY")
    }()
    
    cfg, err := Load()
    
    assert.NoError(t, err)
    assert.Equal(t, "test-token", cfg.TelegramBotToken)
    assert.Equal(t, "postgresql://test", cfg.DatabaseURL)
    assert.Equal(t, "test-key", cfg.PerplexityAPIKey)
    assert.Equal(t, "en", cfg.DefaultLanguage) // default
}

func TestLoad_MissingRequired(t *testing.T) {
    cfg, err := Load()
    
    assert.Error(t, err)
    assert.Nil(t, cfg)
}

func TestConfig_IsDevelopment(t *testing.T) {
    cfg := &Config{Environment: "development"}
    assert.True(t, cfg.IsDevelopment())
    assert.False(t, cfg.IsProduction())
}
```

## Troubleshooting

### Missing Required Variable
```
Error: TELEGRAM_BOT_TOKEN is required
Solution: Set the variable in .env or environment
```

### Invalid Database URL
```
Error: unable to connect to database
Solution: Check DATABASE_URL format and credentials
```

### Invalid Language
```
Error: DEFAULT_LANGUAGE must be 'en' or 'vi'
Solution: Set to 'en' or 'vi'
```

## Next Steps

- See [CI/CD Pipeline](16-cicd-pipeline.md) for deployment configuration
- Review [Database Schema](15-database-schema.md) for DATABASE_URL details
- Read [Telegram Bot](10-telegram-bot.md) for bot token usage
