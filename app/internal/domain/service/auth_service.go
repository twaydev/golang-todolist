package service

import (
	"context"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/twaydev/golang-todolist/app/internal/auth"
	"github.com/twaydev/golang-todolist/app/internal/domain/entity"
	"github.com/twaydev/golang-todolist/app/internal/domain/port/output"
)

// AuthService handles authentication operations
type AuthService struct {
	userRepo   output.UserRepository
	jwtManager *auth.JWTManager
}

// NewAuthService creates a new auth service
func NewAuthService(userRepo output.UserRepository, jwtSecret string, jwtExpiryHours int) *AuthService {
	return &AuthService{
		userRepo:   userRepo,
		jwtManager: auth.NewJWTManager(jwtSecret, jwtExpiryHours),
	}
}

// Register creates a new user account
func (s *AuthService) Register(ctx context.Context, email, password string) (*entity.User, error) {
	// Validate password
	if err := entity.ValidatePassword(password); err != nil {
		return nil, err
	}

	// Create user entity
	user, err := entity.NewUser(email)
	if err != nil {
		return nil, err
	}

	// Check if email already exists
	existingUser, _ := s.userRepo.GetByEmail(ctx, email)
	if existingUser != nil {
		return nil, entity.ErrEmailExists
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	user.ID = uuid.New().String()
	user.PasswordHash = string(hashedPassword)

	// Save user
	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, err
	}

	return user, nil
}

// Login authenticates a user and returns a JWT token
func (s *AuthService) Login(ctx context.Context, email, password string) (string, error) {
	// Get user by email
	user, err := s.userRepo.GetByEmail(ctx, email)
	if err != nil {
		return "", entity.ErrUserNotFound
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return "", entity.ErrInvalidPassword
	}

	// Generate token
	token, err := s.jwtManager.GenerateToken(user.ID, user.Email)
	if err != nil {
		return "", err
	}

	return token, nil
}

// ValidateToken validates a JWT token and returns the claims
func (s *AuthService) ValidateToken(token string) (*auth.Claims, error) {
	return s.jwtManager.ValidateToken(token)
}

// GetUserByID retrieves a user by ID
func (s *AuthService) GetUserByID(ctx context.Context, id string) (*entity.User, error) {
	return s.userRepo.GetByID(ctx, id)
}
