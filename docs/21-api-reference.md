# API Reference

## Overview

The REST API provides programmatic access to the todo management system. Built with **Echo v4**, it supports full CRUD operations, authentication, and advanced filtering.

**Base URL**: `https://your-app.railway.app/api/v1`

**Authentication**: JWT tokens or API keys

## Authentication

All API endpoints require authentication via JWT token or API key.

### Headers

```http
Authorization: Bearer <jwt_token>
# or
X-API-Key: <api_key>
```

### Get API Token

```http
POST /api/v1/auth/token
Content-Type: application/json

{
  "telegram_user_id": 123456789
}
```

**Response**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_at": "2026-01-11T00:00:00Z"
}
```

## Endpoints

### Health Check

#### GET /health

Check API health status (no auth required).

**Response**:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2026-01-10T12:00:00Z"
}
```

---

## Todos

### Create Todo

#### POST /api/v1/todos

Create a new todo.

**Request Body**:
```json
{
  "title": "Buy groceries",
  "description": "Milk, bread, eggs",
  "due_date": "2026-01-11T15:00:00Z",
  "priority": "medium",
  "tags": ["shopping", "personal"]
}
```

**Response** (201 Created):
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "code": "26-0042",
  "title": "Buy groceries",
  "description": "Milk, bread, eggs",
  "due_date": "2026-01-11T15:00:00Z",
  "priority": "medium",
  "status": "pending",
  "tags": ["shopping", "personal"],
  "created_at": "2026-01-10T12:00:00Z",
  "updated_at": "2026-01-10T12:00:00Z"
}
```

**Errors**:
- `400 Bad Request`: Invalid request body
- `401 Unauthorized`: Missing or invalid token

---

### List Todos

#### GET /api/v1/todos

List todos with optional filters.

**Query Parameters**:
- `status` (string): Filter by status (`pending`, `completed`, `cancelled`)
- `priority` (string): Filter by priority (`low`, `medium`, `high`)
- `tags` (string): Comma-separated tags
- `limit` (int): Max results (default: 20, max: 100)
- `offset` (int): Pagination offset (default: 0)
- `sort` (string): Sort field (default: `created_at`)
- `order` (string): Sort order (`asc`, `desc`, default: `desc`)

**Example**:
```http
GET /api/v1/todos?status=pending&priority=high&limit=10
```

**Response** (200 OK):
```json
{
  "todos": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "code": "26-0042",
      "title": "Buy groceries",
      "priority": "high",
      "status": "pending",
      "tags": ["shopping"],
      "created_at": "2026-01-10T12:00:00Z"
    }
  ],
  "total": 1,
  "limit": 10,
  "offset": 0
}
```

---

### Get Todo by ID

#### GET /api/v1/todos/:id

Get a specific todo by ID or code.

**Example**:
```http
GET /api/v1/todos/123e4567-e89b-12d3-a456-426614174000
# or
GET /api/v1/todos/26-0042
```

**Response** (200 OK):
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "code": "26-0042",
  "title": "Buy groceries",
  "description": "Milk, bread, eggs",
  "due_date": "2026-01-11T15:00:00Z",
  "priority": "medium",
  "status": "pending",
  "tags": ["shopping"],
  "created_at": "2026-01-10T12:00:00Z",
  "updated_at": "2026-01-10T12:00:00Z"
}
```

**Errors**:
- `404 Not Found`: Todo not found

---

### Update Todo

#### PUT /api/v1/todos/:id

Update an existing todo.

**Request Body**:
```json
{
  "title": "Buy groceries and fruits",
  "description": "Milk, bread, eggs, apples",
  "priority": "high",
  "tags": ["shopping", "urgent"]
}
```

**Response** (200 OK):
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "code": "26-0042",
  "title": "Buy groceries and fruits",
  "description": "Milk, bread, eggs, apples",
  "priority": "high",
  "status": "pending",
  "tags": ["shopping", "urgent"],
  "updated_at": "2026-01-10T13:00:00Z"
}
```

---

### Complete Todo

#### POST /api/v1/todos/:id/complete

Mark a todo as completed.

**Response** (200 OK):
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "code": "26-0042",
  "title": "Buy groceries",
  "status": "completed",
  "completed_at": "2026-01-10T14:00:00Z"
}
```

---

### Delete Todo

#### DELETE /api/v1/todos/:id

Delete a todo.

**Response** (204 No Content)

**Errors**:
- `404 Not Found`: Todo not found

---

### Search Todos

#### GET /api/v1/todos/search

Full-text search across todos.

**Query Parameters**:
- `q` (string, required): Search query

**Example**:
```http
GET /api/v1/todos/search?q=groceries
```

**Response** (200 OK):
```json
{
  "todos": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "code": "26-0042",
      "title": "Buy groceries",
      "description": "Milk, bread, eggs"
    }
  ],
  "total": 1
}
```

---

## Templates

### List Templates

#### GET /api/v1/templates

List all available templates (global + user).

**Response** (200 OK):
```json
{
  "templates": [
    {
      "name": "daily-standup",
      "title": "Daily Standup - {{date}}",
      "priority": "medium",
      "tags": ["work", "meeting"],
      "variables": {
        "date": "{{now:Mon Jan 2}}",
        "yesterday": "",
        "today": "",
        "blockers": "None"
      }
    }
  ]
}
```

---

### Create Template

#### POST /api/v1/templates

Create a user-defined template.

**Request Body**:
```json
{
  "name": "my-meeting",
  "title": "Meeting: {{topic}}",
  "description": "Attendees: {{attendees}}",
  "priority": "medium",
  "tags": ["meeting"],
  "variables": {
    "topic": "",
    "attendees": ""
  }
}
```

**Response** (201 Created):
```json
{
  "id": "456e7890-e89b-12d3-a456-426614174000",
  "name": "my-meeting",
  "title": "Meeting: {{topic}}",
  "created_at": "2026-01-10T12:00:00Z"
}
```

---

### Instantiate Template

#### POST /api/v1/templates/:name/instantiate

Create a todo from a template.

**Request Body**:
```json
{
  "variables": {
    "topic": "Sprint Planning",
    "attendees": "Team A, Team B"
  }
}
```

**Response** (201 Created):
```json
{
  "id": "789e0123-e89b-12d3-a456-426614174000",
  "code": "26-0043",
  "title": "Meeting: Sprint Planning",
  "description": "Attendees: Team A, Team B"
}
```

---

## User Preferences

### Get Preferences

#### GET /api/v1/preferences

Get user preferences.

**Response** (200 OK):
```json
{
  "telegram_user_id": 123456789,
  "language": "en",
  "timezone": "UTC",
  "created_at": "2026-01-01T00:00:00Z",
  "updated_at": "2026-01-10T12:00:00Z"
}
```

---

### Set Language

#### PUT /api/v1/preferences/language

Update user language.

**Request Body**:
```json
{
  "language": "vi"
}
```

**Response** (200 OK):
```json
{
  "language": "vi",
  "updated_at": "2026-01-10T12:00:00Z"
}
```

---

### Set Timezone

#### PUT /api/v1/preferences/timezone

Update user timezone.

**Request Body**:
```json
{
  "timezone": "Asia/Ho_Chi_Minh"
}
```

**Response** (200 OK):
```json
{
  "timezone": "Asia/Ho_Chi_Minh",
  "updated_at": "2026-01-10T12:00:00Z"
}
```

---

## Data Models

### Todo

```typescript
{
  id: string (UUID)
  code: string (format: YY-NNNN)
  title: string
  description?: string
  due_date?: string (ISO 8601)
  priority: "low" | "medium" | "high"
  status: "pending" | "completed" | "cancelled"
  tags: string[]
  created_at: string (ISO 8601)
  updated_at: string (ISO 8601)
  completed_at?: string (ISO 8601)
}
```

### Template

```typescript
{
  id: string (UUID)
  name: string
  title: string
  description?: string
  priority: "low" | "medium" | "high"
  tags: string[]
  due_duration?: string (ISO 8601 duration)
  recurrence?: RecurrenceRule
  variables: Record<string, string>
  created_at: string (ISO 8601)
  updated_at: string (ISO 8601)
}
```

## Error Responses

All errors follow this format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request body",
    "details": {
      "field": "title",
      "issue": "Title is required"
    }
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid request data |
| `UNAUTHORIZED` | 401 | Missing or invalid auth |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource already exists |
| `INTERNAL_ERROR` | 500 | Server error |

## Rate Limiting

- **Rate limit**: 100 requests per minute per user
- **Headers**:
  - `X-RateLimit-Limit`: 100
  - `X-RateLimit-Remaining`: 95
  - `X-RateLimit-Reset`: 1704902400

**429 Too Many Requests**:
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests",
    "retry_after": 60
  }
}
```

## cURL Examples

### Create Todo
```bash
curl -X POST https://your-app.railway.app/api/v1/todos \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Buy groceries",
    "priority": "high",
    "tags": ["shopping"]
  }'
```

### List Pending Todos
```bash
curl https://your-app.railway.app/api/v1/todos?status=pending \
  -H "Authorization: Bearer $TOKEN"
```

### Complete Todo
```bash
curl -X POST https://your-app.railway.app/api/v1/todos/26-0042/complete \
  -H "Authorization: Bearer $TOKEN"
```

## Next Steps

- See [Echo REST API](09-echo-rest-api.md) for implementation details
- Review [Message Flow](22-message-flow.md) for request/response diagrams
- Read [Configuration](17-configuration.md) for API deployment
