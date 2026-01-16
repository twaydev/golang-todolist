#!/bin/bash
# Checkpoint validation script for orchestrator
# Usage: ./validate-phase.sh <phase_number>

set -e

PHASE=$1

if [ -z "$PHASE" ]; then
  echo "Usage: $0 <phase_number>"
  echo "Example: $0 1"
  exit 1
fi

echo "🔍 Validating Phase $PHASE checkpoint..."

case $PHASE in
  1)
    echo "Phase 1: Validating RED state (tests should fail)"
    
    # Run tests and capture output
    go test ./app/test/... -v > /tmp/test-output.txt 2>&1 || true
    
    # Check if tests failed
    if grep -q "FAIL" /tmp/test-output.txt; then
      echo "✅ Phase 1 VALID: Tests are RED (failing as expected)"
      echo ""
      echo "Test failures found:"
      grep "FAIL" /tmp/test-output.txt | head -5
      exit 0
    else
      echo "❌ Phase 1 INVALID: Tests should fail but they didn't"
      echo "This phase requires tests to be written that fail initially (RED state)"
      exit 1
    fi
    ;;
    
  2)
    echo "Phase 2: Validating GREEN state (tests should pass)"
    
    # Run unit tests for domain layer
    if go test ./app/test/unit/domain/... -v; then
      echo "✅ Phase 2 VALID: Tests are GREEN (passing)"
      exit 0
    else
      echo "❌ Phase 2 INVALID: Tests should pass but they're failing"
      echo "Domain implementation is not complete or has issues"
      exit 1
    fi
    ;;
    
  3)
    echo "Phase 3: Validating integration tests"
    
    # Run integration tests
    if go test ./app/test/integration/... -v; then
      echo "✅ Phase 3 VALID: Integration tests pass"
      exit 0
    else
      echo "❌ Phase 3 INVALID: Integration tests failing"
      echo "Adapter implementations have issues"
      exit 1
    fi
    ;;
    
  4)
    echo "Phase 4: Validating deployment"
    
    # Check if RAILWAY_URL is set
    if [ -z "$RAILWAY_URL" ]; then
      echo "⚠️  RAILWAY_URL not set, checking local health endpoint"
      HEALTH_URL="http://localhost:${PORT:-8080}/health"
    else
      HEALTH_URL="${RAILWAY_URL}/health"
    fi
    
    echo "Checking health endpoint: $HEALTH_URL"
    
    # Check health endpoint
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" 2>/dev/null || echo "000")
    
    if [ "$STATUS" -eq 200 ]; then
      echo "✅ Phase 4 VALID: Health check passing (HTTP $STATUS)"
      exit 0
    else
      echo "❌ Phase 4 INVALID: Health check failing (HTTP $STATUS)"
      echo "Deployment or health endpoint has issues"
      exit 1
    fi
    ;;
    
  *)
    echo "❌ Invalid phase number: $PHASE"
    echo "Valid phases: 1 (RED), 2 (GREEN), 3 (Integration), 4 (Deploy)"
    exit 1
    ;;
esac
