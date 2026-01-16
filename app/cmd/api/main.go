package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/twaydev/golang-todolist/app/internal/adapter/driven/postgres"
	"github.com/twaydev/golang-todolist/app/internal/adapter/driving/http"
	"github.com/twaydev/golang-todolist/app/internal/config"
	"github.com/twaydev/golang-todolist/app/internal/domain/service"
)

func main() {
	// Load configuration
	cfg := config.Load()

	log.Printf("Starting server in %s mode...", cfg.Environment)

	// Create context for graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Connect to database
	pool, err := postgres.NewPoolFromURL(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer pool.Close()
	log.Println("Connected to database")

	// Initialize repositories
	userRepo := postgres.NewUserRepository(pool)

	// Initialize services
	authService := service.NewAuthService(userRepo, cfg.JWTSecret, cfg.JWTExpiryHours)

	// Create HTTP server
	server := http.NewServer(authService)

	// Start server in goroutine
	go func() {
		log.Printf("Server listening on :%s", cfg.Port)
		if err := server.Start(":" + cfg.Port); err != nil {
			log.Printf("Server error: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	// Graceful shutdown with timeout
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
	}

	log.Println("Server stopped")
}
