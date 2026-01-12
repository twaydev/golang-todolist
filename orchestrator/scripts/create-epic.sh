#!/bin/bash
# Creates Linear epic for a feature
# Usage: ./create-epic.sh "Feature Name" "Description" "Acceptance Criteria"

FEATURE_NAME="$1"
DESCRIPTION="$2"
ACCEPTANCE="$3"

if [ -z "$FEATURE_NAME" ]; then
  echo "Usage: $0 \"Feature Name\" \"Description\" \"Acceptance Criteria\""
  echo ""
  echo "Example:"
  echo "  $0 \"Create Todo with Priority\" \\"
  echo "     \"Users can create todos with priority levels\" \\"
  echo "     \"- REST API endpoint works\n- Tests pass\n- Deployed\""
  exit 1
fi

echo "📋 Creating Linear epic for: $FEATURE_NAME"
echo ""
echo "This script will help you create a Linear epic."
echo "You can use Factory.ai's Linear integration or create manually."
echo ""
echo "Epic Template:"
echo "============================================"
echo "Title: [Feature] $FEATURE_NAME"
echo ""
echo "Description:"
echo "$DESCRIPTION"
echo ""
echo "Acceptance Criteria:"
echo "$ACCEPTANCE"
echo ""
echo "Labels: type:feature"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Copy the template above"
echo "2. Create the epic in Linear (via web or Factory.ai)"
echo "3. Note the epic ID or URL"
echo "4. Run: ./create-tasks.sh <epic_id>"
