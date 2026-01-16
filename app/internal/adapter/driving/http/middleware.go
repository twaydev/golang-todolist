package http

import (
	"net/http"
	"strings"

	"github.com/labstack/echo/v4"

	"github.com/twaydev/golang-todolist/app/internal/domain/service"
)

// JWTMiddleware creates a middleware that validates JWT tokens
func JWTMiddleware(authService *service.AuthService) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			// Get Authorization header
			authHeader := c.Request().Header.Get("Authorization")
			if authHeader == "" {
				return c.JSON(http.StatusUnauthorized, ErrorResponse{
					Error:   "missing_token",
					Message: "Authorization header is required",
				})
			}

			// Check Bearer prefix
			parts := strings.SplitN(authHeader, " ", 2)
			if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
				return c.JSON(http.StatusUnauthorized, ErrorResponse{
					Error:   "invalid_token_format",
					Message: "Authorization header must be in format: Bearer <token>",
				})
			}

			token := parts[1]

			// Validate token
			claims, err := authService.ValidateToken(token)
			if err != nil {
				return c.JSON(http.StatusUnauthorized, ErrorResponse{
					Error:   "invalid_token",
					Message: "Token is invalid or expired",
				})
			}

			// Set user info in context
			c.Set("user_id", claims.UserID)
			c.Set("email", claims.Email)

			return next(c)
		}
	}
}
