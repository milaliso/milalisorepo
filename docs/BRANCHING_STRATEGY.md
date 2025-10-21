# Branching Strategy

This document defines the branching strategy and naming conventions for the MilaLiso repository.

## Branch Types

### **Main Branch**

- **`main`** - Production-ready code

- Protected branch - no direct pushes allowed

- All changes must come through Pull Requests

- Requires at least 1 approval before merge

- Automatically deploys to test and production environments

### **Feature Branches**

- **Format**: `feature/description-of-feature`

- **Purpose**: New features, enhancements, or significant changes

- **Examples**:

- `feature/setup-ci-cd-pipeline`

- `feature/migrate-pcc-component`

- `feature/add-shopify-integration`

- `feature/implement-roy-custom-sizing`

### **Bugfix Branches**

- **Format**: `bugfix/description-of-fix`

- **Purpose**: Non-critical bug fixes

- **Examples**:

- `bugfix/fix-readme-typo`

- `bugfix/correct-environment-config`

- `bugfix/update-deployment-script`

### **Hotfix Branches**

- **Format**: `hotfix/description-of-critical-fix`

- **Purpose**: Critical production issues that need immediate attention

- **Examples**:

- `hotfix/security-vulnerability-patch`

- `hotfix/production-deployment-failure`

### **Documentation Branches**

- **Format**: `docs/description-of-documentation`

- **Purpose**: Documentation-only changes

- **Examples**:

- `docs/update-branching-strategy`

- `docs/add-deployment-guide`

- `docs/update-component-readme`

## Naming Conventions

### **Branch Name Rules**

- Use lowercase letters only

- Use hyphens (-) to separate words

- Be descriptive but concise

- Start with branch type prefix

- No spaces or special characters

### **Good Examples**

✅ `feature/setup-multi-environment-deployment`  

✅ `bugfix/fix-sam-template-syntax`  

✅ `docs/add-contributing-guidelines`  

✅ `hotfix/critical-lambda-timeout`  

### **Bad Examples**

❌ `Feature/Setup_Multi_Environment`  

❌ `fix-bug`  

❌ `my-branch`  

❌ `feature/setup multi environment deployment`  

## Workflow

### **1. Starting New Work**

```bash

# Always start from latest main

git checkout main

git pull origin main

# Create new feature branch

git checkout -b feature/your-feature-name

```

### **2. Working on Feature**

```bash

# Make your changes

git add .

git commit -m "Descriptive commit message"

# Push to remote branch

git push origin feature/your-feature-name

```

### **3. Creating Pull Request**

1. Push your branch to GitHub

2. Create Pull Request from your branch to `main`

3. Add clear description of changes

4. Request review from team member

5. Wait for approval before merging

### **4. After Merge**

```bash

# Switch back to main and clean up

git checkout main

git pull origin main

git branch -d feature/your-feature-name

```

## Branch Protection Rules

### **Main Branch Protection**

- No direct pushes allowed

- Require pull request reviews

- Require at least 1 approval

- Require branches to be up to date before merging

- Dismiss stale reviews when new commits are pushed

### **Pull Request Requirements**

- Clear title and description

- All checks must pass

- At least 1 approving review

- No merge conflicts

- Branch must be up to date with main

## Deployment Strategy

| Branch Type | Deployment Target | Trigger |

|-------------|------------------|---------|

| `feature/*` | Dev environment | Push to branch |

| `main` | Test & Production | Merge to main |

| `hotfix/*` | All environments | Push to branch |

## Best Practices

### **Commit Messages**

- Use present tense ("Add feature" not "Added feature")

- Be descriptive but concise

- Reference issues when applicable

- Examples:

- `Add branching strategy documentation`

- `Fix SAM template syntax error`

- `Update deployment script for multi-environment`

### **Branch Lifecycle**

- Keep branches short-lived (1-3 days max)

- Delete branches after successful merge

- Regularly sync with main to avoid conflicts

- Test locally before pushing

### **Code Review**

- Review your own code before requesting review

- Provide context in PR description

- Respond to feedback promptly

- Keep PRs focused and small when possible

## Emergency Procedures

### **Hotfix Process**

1. Create hotfix branch from main

2. Make minimal necessary changes

3. Test thoroughly

4. Create PR with "HOTFIX" label

5. Get expedited review

6. Deploy immediately after merge

### **Rollback Process**

1. Identify last known good commit

2. Create hotfix branch from that commit

3. Follow standard hotfix process

4. Document incident and resolution

---

This branching strategy ensures code quality, enables safe parallel development, and maintains a stable main branch for production deployments.