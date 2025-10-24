# PR Workflow Troubleshooting Guide

This guide helps you diagnose and fix common issues with the MilaLiso PR workflow system.

## 🚨 Common Issues and Solutions

### 1. **PR Creation Issues**

#### Problem: PR template doesn't load
**Symptoms:**
- Empty PR description when creating PR
- No checklist or template visible

**Solutions:**
```bash
# Check if template exists
ls -la .github/PULL_REQUEST_TEMPLATE.md

# If missing, run setup script
./scripts/setup-pr-workflow.sh

# Or create PR via web UI (template auto-loads there)
```

#### Problem: Auto-labeling not working
**Symptoms:**
- PR created but no labels applied
- Labels applied incorrectly

**Solutions:**
```bash
# Check if labeler config exists
ls -la .github/labeler.yml

# Check if labeler workflow exists
ls -la .github/workflows/pr-labeler.yml

# Manually trigger labeler workflow
gh workflow run pr-labeler.yml
```

### 2. **Deployment Issues**

#### Problem: PR deployment fails
**Symptoms:**
- Status check `pr-deployment/dev` shows failure
- No deployment comment on PR
- Error in GitHub Actions logs

**Common Causes & Solutions:**

**AWS Credentials Issue:**
```bash
# Check if AWS role is configured in repository secrets
# Go to: Settings → Secrets → Actions → AWS_ROLE_ARN

# Test AWS access locally
aws sts get-caller-identity
```

**SAM Template Validation Error:**
```bash
# Validate templates locally
find . -name "template.yaml" -exec sam validate -t {} \;

# Check for syntax errors in YAML
yamllint components/*/template.yaml
```

**Build Failure:**
```bash
# Test build locally
cd components/sample-component
sam build

# Check for missing dependencies
ls -la src/requirements.txt
```

**Stack Name Conflicts:**
```bash
# Check for existing stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Clean up conflicting stacks
./scripts/manage-pr-environment.sh cleanup <pr-number>
```

#### Problem: Deployment succeeds but no comment on PR
**Symptoms:**
- GitHub Actions shows success
- No deployment status comment on PR

**Solutions:**
```bash
# Check GitHub token permissions
# Ensure GITHUB_TOKEN has pull-requests: write permission

# Check workflow file permissions section
grep -A 5 "permissions:" .github/workflows/pr-deploy-to-dev.yml
```

### 3. **Status Check Issues**

#### Problem: Status checks never complete
**Symptoms:**
- PR shows "Some checks haven't completed yet"
- Status checks stuck in pending state

**Solutions:**
```bash
# Check if workflows are running
gh run list --workflow=pr-validation.yml
gh run list --workflow=pr-deploy-to-dev.yml

# Check workflow logs
gh run view <run-id> --log

# Re-trigger workflows
git commit --allow-empty -m "Trigger workflows"
git push
```

#### Problem: Status checks fail but should pass
**Symptoms:**
- All code looks correct
- Local testing works
- GitHub Actions fail

**Solutions:**
```bash
# Check GitHub Actions runner logs
gh run view --log

# Test locally with same commands
sam validate -t components/sample-component/template.yaml
sam build

# Check for environment differences
env | grep AWS
```

### 4. **Merge Issues**

#### Problem: Merge button disabled
**Symptoms:**
- "Merge pull request" button is grayed out
- Message about required status checks

**Solutions:**
```bash
# Check which status checks are required
gh api repos/milaliso/milalisorepo/branches/main/protection

# Check status of current PR
gh pr status

# Wait for status checks to complete or fix failing checks
```

#### Problem: Can't merge even with passing checks
**Symptoms:**
- All status checks pass
- Still can't merge

**Solutions:**
```bash
# Check if branch is up to date
git checkout main
git pull origin main
git checkout your-feature-branch
git rebase main
git push --force-with-lease

# Check branch protection settings
gh api repos/milaliso/milalisorepo/branches/main/protection
```

### 5. **Cleanup Issues**

#### Problem: PR environment not cleaned up after merge
**Symptoms:**
- PR merged but stacks still exist
- AWS resources still running

**Solutions:**
```bash
# Check if cleanup workflow ran
gh run list --workflow=pr-cleanup.yml

# Manual cleanup
./scripts/manage-pr-environment.sh cleanup <pr-number>

# Check for stuck CloudFormation stacks
aws cloudformation list-stacks --stack-status-filter DELETE_IN_PROGRESS
```

#### Problem: Cleanup workflow fails
**Symptoms:**
- Cleanup workflow shows failure
- Some resources remain

**Solutions:**
```bash
# Check cleanup workflow logs
gh run view --log --workflow=pr-cleanup.yml

# Manual stack deletion
aws cloudformation delete-stack --stack-name milaliso-pr-N-dev-component

# Force delete if stuck
aws cloudformation cancel-update-stack --stack-name milaliso-pr-N-dev-component
aws cloudformation delete-stack --stack-name milaliso-pr-N-dev-component
```

## 🔧 Diagnostic Commands

### Check Overall System Health
```bash
# Verify all GitHub config files
ls -la .github/PULL_REQUEST_TEMPLATE.md
ls -la .github/CODEOWNERS
ls -la .github/labeler.yml
ls -la .github/workflows/

# Check branch protection
gh api repos/milaliso/milalisorepo/branches/main/protection

# List recent workflow runs
gh run list --limit 10
```

### Check PR-Specific Issues
```bash
# Check PR status
gh pr status

# View PR details
gh pr view <pr-number>

# Check PR-specific stacks
./scripts/manage-pr-environment.sh status <pr-number>

# View workflow runs for specific PR
gh run list --branch feature/your-branch
```

### Check AWS Resources
```bash
# List all PR-related stacks
aws cloudformation list-stacks --query "StackSummaries[?contains(StackName, 'milaliso-pr-')]"

# Check stack events for errors
aws cloudformation describe-stack-events --stack-name milaliso-pr-N-dev-component

# Check S3 deployment artifacts
aws s3 ls s3://aws-sam-cli-managed-default-samclisourcebucket-* --recursive | grep milaliso-pr
```

## 🚑 Emergency Procedures

### Complete System Reset
If everything is broken:

```bash
# 1. Clean up all PR environments
./scripts/manage-pr-environment.sh list
# For each PR environment found:
./scripts/manage-pr-environment.sh cleanup <pr-number>

# 2. Re-run setup scripts
./scripts/setup-branch-protection.sh
./scripts/setup-pr-workflow.sh

# 3. Test with a simple PR
git checkout -b test/emergency-fix
echo "# Test" > test.md
git add test.md
git commit -m "Emergency test"
git push origin test/emergency-fix
gh pr create --title "Emergency Test" --body "Testing system recovery"
```

### Cost Control Emergency
If AWS costs are too high:

```bash
# List all stacks to see what's running
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Delete all PR environments immediately
for pr in $(aws cloudformation list-stacks --query "StackSummaries[?contains(StackName, 'milaliso-pr-')].StackName" --output text); do
  aws cloudformation delete-stack --stack-name "$pr"
done

# Monitor deletion progress
watch aws cloudformation list-stacks --stack-status-filter DELETE_IN_PROGRESS
```

## 📞 Getting Help

### Useful Commands for Support
```bash
# System information
echo "OS: $(uname -s)"
echo "GitHub CLI: $(gh --version)"
echo "AWS CLI: $(aws --version)"
echo "SAM CLI: $(sam --version)"

# Repository information
gh repo view
git remote -v
git branch -a

# Recent activity
gh run list --limit 5
gh pr list --state all --limit 5
```

### Log Collection
```bash
# Collect logs for troubleshooting
mkdir -p troubleshooting-logs

# GitHub Actions logs
gh run list --limit 5 --json > troubleshooting-logs/github-runs.json
gh run view --log > troubleshooting-logs/latest-run.log

# AWS CloudFormation events
aws cloudformation describe-stack-events --stack-name milaliso-pr-N-dev-component > troubleshooting-logs/stack-events.json

# System configuration
gh api repos/milaliso/milalisorepo/branches/main/protection > troubleshooting-logs/branch-protection.json
```

---

**Need more help?** Check the [scripts README](../scripts/README.md) for additional information or create an issue in the repository.