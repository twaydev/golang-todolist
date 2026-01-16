Feature: User Authentication
  As a user of the todolist application
  I want to register and login to my account
  So that I can manage my personal todos securely

  Background:
    Given the API server is running
    And the database is clean

  # ============================================================================
  # User Registration
  # ============================================================================

  @registration @happy-path
  Scenario: Successful user registration
    When I register with email "newuser@example.com" and password "password123"
    Then the response status code should be 201
    And the response should contain "id"
    And the response should contain "email"
    And the response "email" should be "newuser@example.com"

  @registration @validation
  Scenario: Registration fails with invalid email format
    When I register with email "invalid-email" and password "password123"
    Then the response status code should be 400
    And the response "error" should be "invalid_email"
    And the response "message" should be "Invalid email format"

  @registration @validation
  Scenario: Registration fails with short password
    When I register with email "user@example.com" and password "short"
    Then the response status code should be 400
    And the response "error" should be "password_too_short"
    And the response "message" should be "Password must be at least 8 characters"

  @registration @validation
  Scenario: Registration fails with empty email
    When I register with email "" and password "password123"
    Then the response status code should be 400
    And the response "error" should be "validation_error"
    And the response "message" should be "Email and password are required"

  @registration @validation
  Scenario: Registration fails with empty password
    When I register with email "user@example.com" and password ""
    Then the response status code should be 400
    And the response "error" should be "validation_error"
    And the response "message" should be "Email and password are required"

  @registration @duplicate
  Scenario: Registration fails with duplicate email
    Given a user exists with email "existing@example.com" and password "password123"
    When I register with email "existing@example.com" and password "newpassword123"
    Then the response status code should be 409
    And the response "error" should be "email_exists"
    And the response "message" should be "Email already registered"

  # ============================================================================
  # User Login
  # ============================================================================

  @login @happy-path
  Scenario: Successful login
    Given a user exists with email "login@example.com" and password "password123"
    When I login with email "login@example.com" and password "password123"
    Then the response status code should be 200
    And the response should contain "token"
    And the response should contain "expires_in"
    And the response "expires_in" should be 86400

  @login @validation
  Scenario: Login fails with wrong password
    Given a user exists with email "user@example.com" and password "correctpassword"
    When I login with email "user@example.com" and password "wrongpassword"
    Then the response status code should be 401
    And the response "error" should be "invalid_credentials"
    And the response "message" should be "Invalid email or password"

  @login @validation
  Scenario: Login fails with non-existent email
    When I login with email "nonexistent@example.com" and password "password123"
    Then the response status code should be 401
    And the response "error" should be "invalid_credentials"
    And the response "message" should be "Invalid email or password"

  @login @validation
  Scenario: Login fails with empty credentials
    When I login with email "" and password ""
    Then the response status code should be 400
    And the response "error" should be "validation_error"
    And the response "message" should be "Email and password are required"

  # ============================================================================
  # Protected Routes (JWT Authentication)
  # ============================================================================

  @protected @happy-path
  Scenario: Access protected route with valid token
    Given a user exists with email "protected@example.com" and password "password123"
    And I am logged in as "protected@example.com" with password "password123"
    When I request my profile
    Then the response status code should be 200
    And the response "email" should be "protected@example.com"
    And the response should contain "user_id"

  @protected @unauthorized
  Scenario: Access protected route without token
    When I request my profile without authentication
    Then the response status code should be 401

  @protected @unauthorized
  Scenario: Access protected route with invalid token
    When I request my profile with token "invalid.jwt.token"
    Then the response status code should be 401

  # ============================================================================
  # Health Check
  # ============================================================================

  @health
  Scenario: Health check endpoint
    When I check the health endpoint
    Then the response status code should be 200
    And the response "status" should be "ok"
    And the response should contain "time"
