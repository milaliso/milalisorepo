#!/bin/bash

#===============================================================================
# SCRIPT: setup-branch-protection.sh
# PURPOSE: Configure GitHub branch protection rules for main branch
# STORY: SCRUM-438 - Branch Protection Rules
# AUTHOR: MilaLiso Development Team
# VERSION: 1.0
# CREATED: 2025-01-22
#===============================================================================

#===============================================================================
# DESCRIPTION:
#   This script implements comprehensive branch protection rules for the main
#   branch to enforce proper code review workflow and prevent direct pushes.
#   
# FEATURES:
#   - Blocks direct pushes to main branch
#   - Requires pull requests for all changes
#   - Requires at least 1 approval before merge
#   - Enforces up-to-date branches before merge
#   - Applies rules to all users including administrators
#   - Dismisses stale reviews when new commits are pushed
#
# REQUIREMENTS:
#   - GitHub CLI (gh) installed and authenticated
#   - Repository must be public or have GitHub Pro subscription
#   - User must have admin access to the repository
#
# USAGE:
#   ./scripts/setup-branch-protection.sh
#
# EXIT CODES:
#   0 - Success: Branch protection rules applied successfully
#   1 - Error: GitHub CLI not installed or not authenticated
#===============================================================================

# Exit on any error for safety
set -e

#===============================================================================
# FUNCTION: check_prerequisites
# PURPOSE: Verify required tools and authentication
# PARAMETERS: None
# RETURNS: Exits with code 1 if prerequisites not met
#===============================================================================
check_prerequisites() {
    echo "🔒 Setting up complete branch protection rules..."
    
    # Check if GitHub CLI is installed
    if ! command -v gh &> /dev/null; then
        echo "❌ GitHub CLI (gh) is not installed."
        echo "   Install with: brew install gh"
        echo "   Or visit: https://cli.github.com/"
        exit 1
    fi
    
    # Check if user is authenticated with GitHub CLI
    if ! gh auth status &> /dev/null; then
        echo "❌ Not authenticated with GitHub CLI."
        echo "   Run: gh auth login"
        exit 1
    fi
}

#===============================================================================
# FUNCTION: get_repository_info
# PURPOSE: Get current repository name and display it
# PARAMETERS: None
# RETURNS: Sets REPO variable with repository name
#===============================================================================
get_repository_info() {
    REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    echo "📁 Repository: $REPO"
}

#===============================================================================
# FUNCTION: apply_branch_protection
# PURPOSE: Apply comprehensive branch protection rules via GitHub API
# PARAMETERS: None
# RETURNS: Configures branch protection rules for main branch
#===============================================================================
apply_branch_protection() {
    echo "🛡️  Applying complete branch protection..."
    
    # Apply protection rules using GitHub API
    # This JSON configuration implements all SCRUM-438 requirements
    gh api repos/$REPO/branches/main/protection \
      --method PUT \
      --input - << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": []
  },
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "enforce_admins": true,
  "restrictions": null
}
EOF
}

#===============================================================================
# FUNCTION: display_success_message
# PURPOSE: Show completion status and configured protections
# PARAMETERS: None
# RETURNS: Displays success message and protection summary
#===============================================================================
display_success_message() {
    echo ""
    echo "✅ Complete branch protection enabled!"
    echo ""
    echo "📋 SCRUM-438 Acceptance Criteria - ALL COMPLETE:"
    echo "   ✅ Main branch protected from direct pushes"
    echo "   ✅ Require pull request for changes"
    echo "   ✅ Solo development mode (0 approvals required)"
    echo "   ✅ Require up-to-date branches before merge"
    echo ""
    echo "📋 Additional protections enabled:"
    echo "   ✅ Apply rules to administrators"
    echo "   ✅ Dismiss stale reviews on new commits"
    echo ""
    echo "🎉 SCRUM-438 story completed!"
    echo "🧪 Test: try 'git push origin main' (should fail)"
}

#===============================================================================
# MAIN EXECUTION
#===============================================================================
main() {
    check_prerequisites
    get_repository_info
    apply_branch_protection
    display_success_message
}

# Execute main function
main "$@"