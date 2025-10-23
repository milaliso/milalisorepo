#!/bin/bash

#===============================================================================
# SCRIPT: setup-aws-github-integration.sh
# PURPOSE: Configure AWS IAM role for GitHub Actions OIDC integration
# STORY: SCRUM-439 - PR Approval Workflow (AWS Integration)
# AUTHOR: MilaLiso Development Team
# VERSION: 1.0
# CREATED: 2025-01-22
#===============================================================================

#===============================================================================
# DESCRIPTION:
#   This script sets up secure AWS integration for GitHub Actions using OIDC.
#   It creates an IAM role that GitHub Actions can assume to deploy resources.
#
# FEATURES:
#   - Creates OIDC identity provider for GitHub
#   - Creates IAM role with appropriate permissions
#   - Configures trust policy for your repository
#   - Outputs role ARN for GitHub secrets configuration
#
# REQUIREMENTS:
#   - AWS CLI installed and configured
#   - AWS credentials with IAM permissions
#   - GitHub repository owner/admin access
#
# USAGE:
#   ./scripts/setup-aws-github-integration.sh
#===============================================================================

set -e

# Configuration
GITHUB_REPO="milaliso/milalisorepo"
ROLE_NAME="GitHubActions-MilaLiso-Role"
POLICY_NAME="GitHubActions-MilaLiso-Policy"
OIDC_PROVIDER_URL="https://token.actions.githubusercontent.com"
AUDIENCE="sts.amazonaws.com"

#===============================================================================
# FUNCTION: check_prerequisites
# PURPOSE: Verify AWS CLI and credentials
#===============================================================================
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI not found. Please install AWS CLI."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "❌ AWS credentials not configured. Run 'aws configure'."
        exit 1
    fi
    
    echo "✅ Prerequisites check passed"
}

#===============================================================================
# FUNCTION: create_oidc_provider
# PURPOSE: Create GitHub OIDC identity provider in AWS
#===============================================================================
create_oidc_provider() {
    echo "🔗 Setting up GitHub OIDC identity provider..."
    
    # Check if OIDC provider already exists
    if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/token.actions.githubusercontent.com" &> /dev/null; then
        echo "✅ GitHub OIDC provider already exists"
    else
        # Get GitHub's OIDC thumbprint
        THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"
        
        # Create OIDC provider
        aws iam create-open-id-connect-provider \
            --url "$OIDC_PROVIDER_URL" \
            --client-id-list "$AUDIENCE" \
            --thumbprint-list "$THUMBPRINT"
        
        echo "✅ GitHub OIDC provider created"
    fi
}

#===============================================================================
# FUNCTION: create_trust_policy
# PURPOSE: Create trust policy for GitHub Actions
#===============================================================================
create_trust_policy() {
    echo "📝 Creating trust policy..."
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    cat > /tmp/trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO}:*"
                }
            }
        }
    ]
}
EOF
    
    echo "✅ Trust policy created"
}

#===============================================================================
# FUNCTION: create_permissions_policy
# PURPOSE: Create permissions policy for SAM deployments
#===============================================================================
create_permissions_policy() {
    echo "📝 Creating permissions policy..."
    
    cat > /tmp/permissions-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:*",
                "s3:*",
                "lambda:*",
                "apigateway:*",
                "iam:GetRole",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PassRole",
                "logs:*",
                "events:*",
                "application-autoscaling:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
    
    echo "✅ Permissions policy created"
}

#===============================================================================
# FUNCTION: create_iam_role
# PURPOSE: Create IAM role for GitHub Actions
#===============================================================================
create_iam_role() {
    echo "👤 Creating IAM role..."
    
    # Check if role already exists
    if aws iam get-role --role-name "$ROLE_NAME" &> /dev/null; then
        echo "⚠️  Role $ROLE_NAME already exists. Updating trust policy..."
        aws iam update-assume-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-document file:///tmp/trust-policy.json
    else
        # Create the role
        aws iam create-role \
            --role-name "$ROLE_NAME" \
            --assume-role-policy-document file:///tmp/trust-policy.json \
            --description "Role for GitHub Actions to deploy MilaLiso resources"
        
        echo "✅ IAM role created"
    fi
    
    # Create or update the permissions policy
    if aws iam get-policy --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/$POLICY_NAME" &> /dev/null; then
        echo "⚠️  Policy $POLICY_NAME already exists. Creating new version..."
        aws iam create-policy-version \
            --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/$POLICY_NAME" \
            --policy-document file:///tmp/permissions-policy.json \
            --set-as-default
    else
        # Create the policy
        aws iam create-policy \
            --policy-name "$POLICY_NAME" \
            --policy-document file:///tmp/permissions-policy.json \
            --description "Permissions for GitHub Actions to deploy MilaLiso resources"
        
        echo "✅ IAM policy created"
    fi
    
    # Attach policy to role
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/$POLICY_NAME"
    
    echo "✅ Policy attached to role"
}

#===============================================================================
# FUNCTION: display_setup_instructions
# PURPOSE: Show next steps for GitHub configuration
#===============================================================================
display_setup_instructions() {
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
    
    echo ""
    echo "✅ AWS setup completed successfully!"
    echo ""
    echo "📋 Next Steps - Configure GitHub Repository:"
    echo ""
    echo "1. Go to your GitHub repository: https://github.com/${GITHUB_REPO}"
    echo "2. Click Settings → Secrets and variables → Actions"
    echo "3. Click 'New repository secret'"
    echo "4. Add this secret:"
    echo ""
    echo "   Name: AWS_ROLE_ARN"
    echo "   Value: ${ROLE_ARN}"
    echo ""
    echo "5. Save the secret"
    echo ""
    echo "🎯 After adding the secret:"
    echo "   • Push a new commit to trigger GitHub Actions"
    echo "   • The deployment workflow should now work"
    echo "   • Check Actions tab for deployment progress"
    echo ""
    echo "🔧 Role Details:"
    echo "   • Role Name: ${ROLE_NAME}"
    echo "   • Role ARN: ${ROLE_ARN}"
    echo "   • Repository: ${GITHUB_REPO}"
    echo ""
    echo "🎉 AWS-GitHub integration setup complete!"
}

#===============================================================================
# FUNCTION: cleanup_temp_files
# PURPOSE: Clean up temporary policy files
#===============================================================================
cleanup_temp_files() {
    rm -f /tmp/trust-policy.json /tmp/permissions-policy.json
}

#===============================================================================
# MAIN EXECUTION
#===============================================================================
main() {
    echo "🚀 Setting up AWS-GitHub Actions integration..."
    echo "Repository: $GITHUB_REPO"
    echo ""
    
    check_prerequisites
    create_oidc_provider
    create_trust_policy
    create_permissions_policy
    create_iam_role
    display_setup_instructions
    cleanup_temp_files
}

# Execute main function
main "$@"