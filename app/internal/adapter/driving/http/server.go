package http

import (
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"

	"github.com/twaydev/golang-todolist/app/internal/domain/service"
)

// NewServer creates and configures a new Echo server
func NewServer(authService *service.AuthService) *echo.Echo {
	e := echo.New()
	e.HideBanner = true

	// Middleware
	e.Use(middleware.RequestLoggerWithConfig(middleware.RequestLoggerConfig{
		LogStatus:   true,
		LogURI:      true,
		LogError:    true,
		HandleError: true,
		LogValuesFunc: func(c echo.Context, v middleware.RequestLoggerValues) error {
			return nil
		},
	}))
	e.Use(middleware.Recover())
	e.Use(middleware.RequestID())
	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: []string{"*"},
		AllowMethods: []string{echo.GET, echo.POST, echo.PUT, echo.DELETE, echo.OPTIONS},
		AllowHeaders: []string{echo.HeaderOrigin, echo.HeaderContentType, echo.HeaderAccept, echo.HeaderAuthorization},
	}))

	// Initialize handlers
	handlers := NewHandlers(authService)

	// Public routes
	e.GET("/health", handlers.HealthCheck)

	// Auth routes (public)
	auth := e.Group("/auth")
	auth.POST("/register", handlers.Register)
	auth.POST("/login", handlers.Login)

	// Protected routes
	api := e.Group("/api/v1")
	api.Use(JWTMiddleware(authService))
	api.GET("/me", handlers.GetMe)

	return e
}
