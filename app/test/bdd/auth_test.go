package bdd

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/cucumber/godog"
	"github.com/labstack/echo/v4"

	apphttp "github.com/twaydev/golang-todolist/app/internal/adapter/driving/http"
	"github.com/twaydev/golang-todolist/app/internal/config"
	"github.com/twaydev/golang-todolist/app/internal/domain/service"
)

// testContext holds the state for each scenario
type testContext struct {
	server       *httptest.Server
	echo         *echo.Echo
	handlers     *apphttp.Handlers
	authService  *service.AuthService
	userRepo     *mockUserRepository
	response     *http.Response
	responseBody map[string]interface{}
	authToken    string
}

// newTestContext creates a fresh test context
func newTestContext() *testContext {
	return &testContext{
		userRepo: newMockUserRepository(),
	}
}

// setupServer initializes the test server
func (tc *testContext) setupServer() {
	cfg := &config.Config{
		Port:           "8080",
		Environment:    "test",
		JWTSecret:      "test-secret-key-minimum-32-characters-long",
		JWTExpiryHours: 24,
	}

	tc.authService = service.NewAuthService(tc.userRepo, cfg.JWTSecret, cfg.JWTExpiryHours)
	tc.handlers = apphttp.NewHandlers(tc.authService)

	tc.echo = echo.New()

	// Health
	tc.echo.GET("/health", tc.handlers.HealthCheck)

	// Auth routes
	tc.echo.POST("/auth/register", tc.handlers.Register)
	tc.echo.POST("/auth/login", tc.handlers.Login)

	// Protected routes
	protected := tc.echo.Group("/api/v1")
	protected.Use(apphttp.JWTMiddleware(tc.authService))
	protected.GET("/me", tc.handlers.GetMe)

	tc.server = httptest.NewServer(tc.echo)
}

// cleanup tears down the test server
func (tc *testContext) cleanup() {
	if tc.server != nil {
		tc.server.Close()
	}
}

// Step definitions

func (tc *testContext) theAPIServerIsRunning() error {
	tc.setupServer()
	return nil
}

func (tc *testContext) theDatabaseIsClean() error {
	tc.userRepo.clear()
	return nil
}

func (tc *testContext) iRegisterWithEmailAndPassword(email, password string) error {
	body := map[string]string{
		"email":    email,
		"password": password,
	}
	return tc.makePostRequest("/auth/register", body)
}

func (tc *testContext) iLoginWithEmailAndPassword(email, password string) error {
	body := map[string]string{
		"email":    email,
		"password": password,
	}
	return tc.makePostRequest("/auth/login", body)
}

func (tc *testContext) aUserExistsWithEmailAndPassword(email, password string) error {
	body := map[string]string{
		"email":    email,
		"password": password,
	}
	err := tc.makePostRequest("/auth/register", body)
	if err != nil {
		return err
	}
	// Reset response for next step
	tc.response = nil
	tc.responseBody = nil
	return nil
}

func (tc *testContext) iAmLoggedInAsWithPassword(email, password string) error {
	body := map[string]string{
		"email":    email,
		"password": password,
	}
	err := tc.makePostRequest("/auth/login", body)
	if err != nil {
		return err
	}
	if token, ok := tc.responseBody["token"].(string); ok {
		tc.authToken = token
	}
	return nil
}

func (tc *testContext) iRequestMyProfile() error {
	return tc.makeGetRequest("/api/v1/me", tc.authToken)
}

func (tc *testContext) iRequestMyProfileWithoutAuthentication() error {
	return tc.makeGetRequest("/api/v1/me", "")
}

func (tc *testContext) iRequestMyProfileWithToken(token string) error {
	return tc.makeGetRequest("/api/v1/me", token)
}

func (tc *testContext) iCheckTheHealthEndpoint() error {
	return tc.makeGetRequest("/health", "")
}

func (tc *testContext) theResponseStatusCodeShouldBe(expectedCode int) error {
	if tc.response.StatusCode != expectedCode {
		return fmt.Errorf("expected status code %d, got %d. Body: %v", expectedCode, tc.response.StatusCode, tc.responseBody)
	}
	return nil
}

func (tc *testContext) theResponseShouldContain(field string) error {
	if _, ok := tc.responseBody[field]; !ok {
		return fmt.Errorf("expected response to contain field '%s', got: %v", field, tc.responseBody)
	}
	return nil
}

func (tc *testContext) theResponseFieldShouldBeString(field, expected string) error {
	value, ok := tc.responseBody[field]
	if !ok {
		return fmt.Errorf("field '%s' not found in response: %v", field, tc.responseBody)
	}
	strValue, ok := value.(string)
	if !ok {
		return fmt.Errorf("field '%s' is not a string: %v", field, value)
	}
	if strValue != expected {
		return fmt.Errorf("expected '%s' to be '%s', got '%s'", field, expected, strValue)
	}
	return nil
}

func (tc *testContext) theResponseFieldShouldBeInt(field string, expected int) error {
	value, ok := tc.responseBody[field]
	if !ok {
		return fmt.Errorf("field '%s' not found in response: %v", field, tc.responseBody)
	}
	// JSON numbers are float64
	floatValue, ok := value.(float64)
	if !ok {
		return fmt.Errorf("field '%s' is not a number: %v", field, value)
	}
	if int(floatValue) != expected {
		return fmt.Errorf("expected '%s' to be %d, got %v", field, expected, floatValue)
	}
	return nil
}

// Helper methods

func (tc *testContext) makePostRequest(path string, body map[string]string) error {
	jsonBody, err := json.Marshal(body)
	if err != nil {
		return err
	}

	req, err := http.NewRequest("POST", tc.server.URL+path, bytes.NewBuffer(jsonBody))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	tc.response, err = client.Do(req)
	if err != nil {
		return err
	}

	return tc.parseResponseBody()
}

func (tc *testContext) makeGetRequest(path string, token string) error {
	req, err := http.NewRequest("GET", tc.server.URL+path, nil)
	if err != nil {
		return err
	}

	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	client := &http.Client{}
	tc.response, err = client.Do(req)
	if err != nil {
		return err
	}

	return tc.parseResponseBody()
}

func (tc *testContext) parseResponseBody() error {
	bodyBytes, err := io.ReadAll(tc.response.Body)
	tc.response.Body.Close()
	if err != nil {
		return err
	}

	tc.responseBody = make(map[string]interface{})
	if len(bodyBytes) > 0 {
		if err := json.Unmarshal(bodyBytes, &tc.responseBody); err != nil {
			// Response might not be JSON
			return nil
		}
	}
	return nil
}

// InitializeScenario sets up the scenario context
func InitializeScenario(ctx *godog.ScenarioContext) {
	tc := newTestContext()

	ctx.Before(func(ctx context.Context, sc *godog.Scenario) (context.Context, error) {
		tc = newTestContext()
		return ctx, nil
	})

	ctx.After(func(ctx context.Context, sc *godog.Scenario, err error) (context.Context, error) {
		tc.cleanup()
		return ctx, nil
	})

	// Background steps
	ctx.Step(`^the API server is running$`, tc.theAPIServerIsRunning)
	ctx.Step(`^the database is clean$`, tc.theDatabaseIsClean)

	// Registration steps
	ctx.Step(`^I register with email "([^"]*)" and password "([^"]*)"$`, tc.iRegisterWithEmailAndPassword)

	// Login steps
	ctx.Step(`^I login with email "([^"]*)" and password "([^"]*)"$`, tc.iLoginWithEmailAndPassword)

	// User exists step
	ctx.Step(`^a user exists with email "([^"]*)" and password "([^"]*)"$`, tc.aUserExistsWithEmailAndPassword)

	// Logged in step
	ctx.Step(`^I am logged in as "([^"]*)" with password "([^"]*)"$`, tc.iAmLoggedInAsWithPassword)

	// Profile steps
	ctx.Step(`^I request my profile$`, tc.iRequestMyProfile)
	ctx.Step(`^I request my profile without authentication$`, tc.iRequestMyProfileWithoutAuthentication)
	ctx.Step(`^I request my profile with token "([^"]*)"$`, tc.iRequestMyProfileWithToken)

	// Health check step
	ctx.Step(`^I check the health endpoint$`, tc.iCheckTheHealthEndpoint)

	// Response assertions
	ctx.Step(`^the response status code should be (\d+)$`, tc.theResponseStatusCodeShouldBe)
	ctx.Step(`^the response should contain "([^"]*)"$`, tc.theResponseShouldContain)
	ctx.Step(`^the response "([^"]*)" should be "([^"]*)"$`, tc.theResponseFieldShouldBeString)
	ctx.Step(`^the response "([^"]*)" should be (\d+)$`, tc.theResponseFieldShouldBeInt)
}

func TestFeatures(t *testing.T) {
	suite := godog.TestSuite{
		ScenarioInitializer: InitializeScenario,
		Options: &godog.Options{
			Format:   "pretty",
			Paths:    []string{"../../features"},
			TestingT: t,
		},
	}

	if suite.Run() != 0 {
		t.Fatal("non-zero status returned, failed to run feature tests")
	}
}

// Allow running with go test or standalone
func init() {
	if os.Getenv("GODOG_STANDALONE") == "true" {
		godog.TestSuite{
			ScenarioInitializer: InitializeScenario,
			Options: &godog.Options{
				Format: "pretty",
				Paths:  []string{"../../features"},
			},
		}.Run()
	}
}
