package http

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"

	"github.com/twaydev/golang-todolist/app/internal/domain/entity"
	"github.com/twaydev/golang-todolist/app/internal/domain/service"
)

// Handlers holds the HTTP handlers
type Handlers struct {
	authService *service.AuthService
}

// NewHandlers creates a new handlers instance
func NewHandlers(authService *service.AuthService) *Handlers {
	return &Handlers{
		authService: authService,
	}
}

// HealthCheck handles GET /health
func (h *Handlers) HealthCheck(c echo.Context) error {
	return c.JSON(http.StatusOK, HealthResponse{
		Status: "ok",
		Time:   time.Now().Format(time.RFC3339),
	})
}

// Register handles POST /auth/register
func (h *Handlers) Register(c echo.Context) error {
	var req RegisterRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
		})
	}

	// Validate request
	if req.Email == "" || req.Password == "" {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "validation_error",
			Message: "Email and password are required",
		})
	}

	user, err := h.authService.Register(c.Request().Context(), req.Email, req.Password)
	if err != nil {
		switch err {
		case entity.ErrInvalidEmail:
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "invalid_email",
				Message: "Invalid email format",
			})
		case entity.ErrPasswordTooShort:
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "password_too_short",
				Message: "Password must be at least 8 characters",
			})
		case entity.ErrEmailExists:
			return c.JSON(http.StatusConflict, ErrorResponse{
				Error:   "email_exists",
				Message: "Email already registered",
			})
		default:
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				Error:   "internal_error",
				Message: "An error occurred during registration",
			})
		}
	}

	return c.JSON(http.StatusCreated, UserResponse{
		ID:        user.ID,
		Email:     user.Email,
		CreatedAt: user.CreatedAt,
	})
}

// Login handles POST /auth/login
func (h *Handlers) Login(c echo.Context) error {
	var req LoginRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
		})
	}

	// Validate request
	if req.Email == "" || req.Password == "" {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "validation_error",
			Message: "Email and password are required",
		})
	}

	token, err := h.authService.Login(c.Request().Context(), req.Email, req.Password)
	if err != nil {
		switch err {
		case entity.ErrUserNotFound, entity.ErrInvalidPassword:
			return c.JSON(http.StatusUnauthorized, ErrorResponse{
				Error:   "invalid_credentials",
				Message: "Invalid email or password",
			})
		default:
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				Error:   "internal_error",
				Message: "An error occurred during login",
			})
		}
	}

	return c.JSON(http.StatusOK, TokenResponse{
		Token:     token,
		ExpiresIn: 24 * 60 * 60, // 24 hours in seconds
	})
}

// GetMe handles GET /api/v1/me
func (h *Handlers) GetMe(c echo.Context) error {
	userID := c.Get("user_id").(string)
	email := c.Get("email").(string)

	return c.JSON(http.StatusOK, MeResponse{
		UserID: userID,
		Email:  email,
	})
}
