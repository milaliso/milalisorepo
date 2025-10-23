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
- Solo development mode (0 approvals required)
- Enforces up-to-date branches before merge
- Applies rules to administrators
- Dismisses stale reviews on new commits

**Usage:**
```bash
./scripts/setup-branch-protection.sh
```

### 🔄 `setup-pr-workflow.sh`

**Purpose:** Configure complete PR workflow automation system  
**Story:** SCRUM-439 - PR Approval Workflow  
**Status:** ✅ Complete  

**What it does:**
- Creates PR template with comprehensive checklist
- Configures auto-labeling based on file changes
- Sets up CODEOWNERS for automatic reviewer assignment
- Creates GitHub Actions for PR validation and deployment
- Integrates with branch protection rules
- Enables PR-specific dev environments with auto-cleanup

**Usage:**
```bash
./scripts/setup-pr-workflow.sh
```

### 🛠️ `manage-pr-environment.sh`

**Purpose:** Manual management of PR-specific dev environments  
**Story:** SCRUM-439 - PR Approval Workflow  
**Status:** ✅ Complete  

**What it does:**
- Deploy PR to dev environment manually
- Check PR environment status and outputs
- Clean up PR environment resources
- List all active PR environments

**Usage:**
```bash
# Deploy PR to dev environment
./scripts/manage-pr-environment.sh deploy <pr-number>

# Check PR environment status
./scripts/manage-pr-environment.sh status <pr-number>

# Clean up PR environment
./scripts/manage-pr-environment.sh cleanup <pr-number>

# List all PR environments
./scripts/manage-pr-environment.sh list
```

**Examples:**
```bash
./scripts/manage-pr-environment.sh deploy 42
./scripts/manage-pr-environment.sh status 42
./scripts/manage-pr-environment.sh cleanup 42
./scripts/manage-pr-environment.sh list
```

**Prerequisites:**
- AWS CLI configured with appropriate credentials
- SAM CLI installed
- GitHub CLI (`gh`) installed and authenticated
- Repository must be public or have GitHub Pro subscription
- User must have admin access to the repository

**Exit Codes:**
- `0` - Success: Operation completed successfully
- `1` - Error: Missing prerequisites or operation failed

## 🔄 PR Workflow System

The MilaLiso repository uses an automated PR workflow system that provides:
- **Automated PR deployment** to isolated dev environments
- **Status checks** and validation before merge
- **Auto-labeling** and reviewer assignment
- **Automatic cleanup** of resources

### Complete PR Workflow

#### 1. **Development Phase**
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make your changes
# ... develop your feature ...

# Test locally (optional)
./scripts/manage-pr-environment.sh deploy 999  # Use 999 for local testing
./scripts/manage-pr-environment.sh cleanup 999  # Clean up when done
```

#### 2. **PR Creation**
```bash
# Push your branch
git push origin feature/your-feature-name

# Create PR (auto-populates with template)
gh pr create --fill

# Or create via GitHub web UI
```

#### 3. **Automated PR Processing**
When PR is created, GitHub Actions automatically:
- ✅ **Validates** SAM templates and builds components
- ✅ **Deploys** to PR-specific dev environment (`milaliso-pr-N-dev`)
- ✅ **Labels** PR based on changed files
- ✅ **Assigns** reviewers based on CODEOWNERS
- ✅ **Reports** deployment status in PR comments

#### 4. **Testing Phase**
- ✅ **Test** your changes in the deployed PR environment
- ✅ **Review** deployment logs and status checks
- ✅ **Iterate** by pushing new commits (triggers redeployment)

#### 5. **Merge Phase**
- ✅ **Status checks** must pass (validation + deployment)
- ✅ **Merge** when ready (no approval required for solo dev)
- ✅ **Automatic cleanup** of PR environment after merge

### PR Environment Naming

Each PR gets its own isolated environment:
- **Stack Names**: `milaliso-pr-{number}-dev-{component}`
- **Environment Variable**: `pr-{number}`
- **Examples**:
  - PR #1: `milaliso-pr-1-dev-sample-component`
  - PR #42: `milaliso-pr-42-dev-sample-component`

### Status Checks

The following status checks must pass before merge:
- **`pr-validation`**: SAM template validation and component builds
- **`pr-deployment/dev`**: Successful deployment to PR environment

### Auto-Labeling

PRs are automatically labeled based on changed files:
- **`backend`**: Python, SAM templates, infrastructure
- **`scripts`**: Shell scripts, automation
- **`documentation`**: Markdown files, docs
- **`configuration`**: Config files, TOML, YAML
- **`cicd`**: GitHub Actions, workflows
- **`feature`/`bugfix`/`hotfix`**: Based on branch name
- **`small`/`medium`/`large`**: Based on number of files changed

### Manual Override

For emergency situations or debugging:
```bash
# Deploy specific PR manually
./scripts/manage-pr-environment.sh deploy 42

# Check what's deployed
./scripts/manage-pr-environment.sh status 42

# Force cleanup if needed
./scripts/manage-pr-environment.sh cleanup 42
```

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