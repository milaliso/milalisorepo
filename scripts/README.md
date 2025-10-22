# Scripts Directory

This directory contains automation scripts for repository setup, deployment, and maintenance tasks for the MilaLiso project.

## Overview

The scripts in this directory are designed to automate common development and deployment tasks, ensuring consistency and reducing manual errors. Each script is self-contained and includes comprehensive error handling and user feedback.

## Available Scripts

### 🔒 `setup-branch-protection.sh`

**Purpose:** Configure GitHub branch protection rules for the main branch  
**Story:** SCRUM-438 - Branch Protection Rules  
**Status:** ✅ Complete  

**What it does:**
- Blocks direct pushes to main branch
- Requires pull requests for all changes  
- Requires at least 1 approval before merge
- Enforces up-to-date branches before merge
- Applies rules to administrators
- Dismisses stale reviews on new commits

**Usage:**
```bash
./scripts/setup-branch-protection.sh
```

**Prerequisites:**
- GitHub CLI (`gh`) installed and authenticated
- Repository must be public or have GitHub Pro subscription
- User must have admin access to the repository

**Exit Codes:**
- `0` - Success: Branch protection rules applied
- `1` - Error: Missing prerequisites or authentication

## Prerequisites

### Required Tools

All scripts require the following tools to be installed:

#### GitHub CLI (`gh`)
```bash
# Install via Homebrew (macOS)
brew install gh

# Authenticate with GitHub
gh auth login
```

#### Git
```bash
# Usually pre-installed on macOS/Linux
git --version

# If not installed:
brew install git  # macOS
```

### Authentication Requirements

- **GitHub CLI Authentication:** Run `gh auth login` before using any scripts
- **Repository Access:** User must have appropriate permissions for the target repository
- **SSH Keys:** Ensure SSH keys are configured for Git operations

## Script Development Guidelines

When creating new scripts for this directory, follow these conventions:

### File Naming
- Use kebab-case: `script-name.sh`
- Include purpose in name: `setup-`, `deploy-`, `test-`
- Use `.sh` extension for shell scripts

### Script Structure
```bash
#!/bin/bash

#===============================================================================
# SCRIPT: script-name.sh
# PURPOSE: Brief description of what the script does
# STORY: SCRUM-XXX - Story name
# AUTHOR: MilaLiso Development Team
# VERSION: 1.0
# CREATED: YYYY-MM-DD
#===============================================================================

# Exit on any error
set -e

# Functions with documentation
function_name() {
    # Function implementation
}

# Main execution
main() {
    # Main logic
}

main "$@"
```

### Documentation Requirements
- Include comprehensive header with metadata
- Document all functions with purpose and parameters
- Add inline comments for complex logic
- Include usage examples and exit codes
- Document prerequisites and dependencies

### Error Handling
- Use `set -e` to exit on errors
- Check prerequisites before execution
- Provide clear error messages with solutions
- Use appropriate exit codes

### User Experience
- Provide progress indicators (🔒, ✅, ❌ emojis)
- Show clear success/failure messages
- Include next steps or testing instructions
- Use consistent formatting and colors

## Common Patterns

### Checking Prerequisites
```bash
check_prerequisites() {
    if ! command -v gh &> /dev/null; then
        echo "❌ GitHub CLI not installed"
        echo "   Install with: brew install gh"
        exit 1
    fi
}
```

### Getting Repository Information
```bash
get_repo_info() {
    REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    echo "📁 Repository: $REPO"
}
```

### Error Handling with Cleanup
```bash
cleanup() {
    # Cleanup temporary files or state
    echo "🧹 Cleaning up..."
}

trap cleanup EXIT
```

## Testing Scripts

### Manual Testing
1. Test with missing prerequisites
2. Test with invalid authentication
3. Test successful execution
4. Test error conditions
5. Verify cleanup on failure

### Automated Testing
Consider adding test scripts for complex automation:
```bash
# Example test structure
tests/
├── test-setup-branch-protection.sh
└── test-helpers.sh
```

## Security Considerations

- **Never commit secrets** or API keys in scripts
- **Use environment variables** for sensitive configuration
- **Validate inputs** to prevent injection attacks
- **Use least privilege** - only request necessary permissions
- **Audit script permissions** regularly

## Troubleshooting

### Common Issues

#### GitHub CLI Not Authenticated
```bash
Error: gh auth status failed
Solution: Run 'gh auth login'
```

#### Insufficient Permissions
```bash
Error: HTTP 403 Forbidden
Solution: Ensure user has admin access to repository
```

#### Repository Not Public
```bash
Error: Upgrade to GitHub Pro or make repository public
Solution: Change repository visibility or upgrade plan
```

### Debug Mode
Enable debug output for troubleshooting:
```bash
# Add to script for verbose output
set -x  # Enable debug mode
set +x  # Disable debug mode
```

## Contributing

When adding new scripts:

1. **Follow naming conventions** and structure guidelines
2. **Add comprehensive documentation** including this README
3. **Test thoroughly** in different scenarios
4. **Update this README** with new script information
5. **Follow security best practices**

## Future Scripts

Planned automation scripts for upcoming stories:

- `setup-pr-workflow.sh` - SCRUM-439: PR Approval Workflow
- `setup-dev-deployment.sh` - SCRUM-440: Dev Environment for Testing  
- `setup-feature-deployment.sh` - SCRUM-436: Feature Branch Auto-Deploy
- `setup-main-deployment.sh` - SCRUM-437: Main Branch Auto-Deploy
- `setup-prod-safety.sh` - SCRUM-441: Production Environment Safety
- `check-deployment-status.sh` - SCRUM-442: Clear Deployment Status

---

**© 2025 MilaLiso - All Rights Reserved**  
*Proprietary software - Unauthorized copying or distribution is prohibited*