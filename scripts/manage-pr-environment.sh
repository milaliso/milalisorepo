#!/bin/bash

#===============================================================================
# SCRIPT: manage-pr-environment.sh
# PURPOSE: Manually manage PR-specific dev environments
# STORY: SCRUM-439 - PR Approval Workflow
# AUTHOR: MilaLiso Development Team
# VERSION: 1.0
# CREATED: 2025-01-22
#===============================================================================

#===============================================================================
# DESCRIPTION:
#   This script provides manual management of PR-specific dev environments:
#   - Deploy PR to dev environment
#   - Check PR environment status
#   - Clean up PR environment
#   - List all PR environments
#
# USAGE:
#   ./scripts/manage-pr-environment.sh <action> <pr-number>
#
# ACTIONS:
#   deploy <pr-number>  - Deploy PR to dev environment
#   status <pr-number>  - Check PR environment status
#   cleanup <pr-number> - Clean up PR environment
#   list               - List all PR environments
#
# EXAMPLES:
#   ./scripts/manage-pr-environment.sh deploy 42
#   ./scripts/manage-pr-environment.sh status 42
#   ./scripts/manage-pr-environment.sh cleanup 42
#   ./scripts/manage-pr-environment.sh list
#===============================================================================

set -e

# Configuration
AWS_REGION="us-east-1"
STACK_PREFIX="milaliso-pr"

#===============================================================================
# FUNCTION: show_usage
# PURPOSE: Display script usage information
#===============================================================================
show_usage() {
    echo "Usage: $0 <action> [pr-number]"
    echo ""
    echo "Actions:"
    echo "  deploy <pr-number>   Deploy PR to dev environment"
    echo "  status <pr-number>   Check PR environment status"
    echo "  cleanup <pr-number>  Clean up PR environment"
    echo "  list                 List all PR environments"
    echo ""
    echo "Examples:"
    echo "  $0 deploy 42"
    echo "  $0 status 42"
    echo "  $0 cleanup 42"
    echo "  $0 list"
}

#===============================================================================
# FUNCTION: check_prerequisites
# PURPOSE: Verify required tools are available
#===============================================================================
check_prerequisites() {
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI not found. Please install AWS CLI."
        exit 1
    fi
    
    if ! command -v sam &> /dev/null; then
        echo "❌ SAM CLI not found. Please install SAM CLI."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "❌ AWS credentials not configured. Run 'aws configure'."
        exit 1
    fi
}

#===============================================================================
# FUNCTION: deploy_pr
# PURPOSE: Deploy PR to dev environment
#===============================================================================
deploy_pr() {
    local pr_number=$1
    local stack_name="${STACK_PREFIX}-${pr_number}-dev"
    
    echo "🚀 Deploying PR #${pr_number} to dev environment..."
    echo "Stack name: ${stack_name}"
    
    # Validate stack name length
    if [ ${#stack_name} -gt 100 ]; then
        echo "❌ Stack name too long: ${stack_name}"
        echo "   Base stack names should be under 100 characters to allow for component suffixes"
        return 1
    fi
    
    local deployment_success=true
    local failed_components=""
    
    # Deploy each component
    for component_dir in components/*/; do
        component_name=$(basename "$component_dir")
        
        if [ -f "$component_dir/template.yaml" ]; then
            echo "📦 Deploying component: $component_name"
            
            cd "$component_dir"
            
            # Build and deploy
            sam build
            
            # Validate stack name length
            component_stack_name="${stack_name}-${component_name}"
            if [ ${#component_stack_name} -gt 128 ]; then
                echo "❌ Component stack name too long: $component_stack_name"
                echo "   AWS CloudFormation stack names must be 128 characters or less"
                cd - > /dev/null
                return 1
            fi
            
            # Check if S3 bucket exists, create if needed
            s3_bucket="milaliso-sam-deployments-${AWS_REGION}"
            if ! aws s3api head-bucket --bucket "$s3_bucket" 2>/dev/null; then
                echo "📦 Creating S3 bucket: $s3_bucket"
                if [ "$AWS_REGION" = "us-east-1" ]; then
                    aws s3api create-bucket --bucket "$s3_bucket" || {
                        echo "⚠️ Could not create bucket, using resolve_s3 fallback"
                        sam deploy \
                            --config-env dev \
                            --stack-name "$component_stack_name" \
                            --parameter-overrides Environment=pr-${pr_number} \
                            --resolve-s3 \
                            --no-confirm-changeset \
                            --no-fail-on-empty-changeset
                        cd - > /dev/null
                        return $?
                    }
                else
                    aws s3api create-bucket \
                        --bucket "$s3_bucket" \
                        --create-bucket-configuration LocationConstraint=$AWS_REGION || {
                        echo "⚠️ Could not create bucket, using resolve_s3 fallback"
                        sam deploy \
                            --config-env dev \
                            --stack-name "$component_stack_name" \
                            --parameter-overrides Environment=pr-${pr_number} \
                            --resolve-s3 \
                            --no-confirm-changeset \
                            --no-fail-on-empty-changeset
                        cd - > /dev/null
                        return $?
                    }
                fi
            fi
            
            # Deploy with explicit S3 bucket
            if sam deploy \
                --config-env dev \
                --stack-name "$component_stack_name" \
                --parameter-overrides Environment=pr-${pr_number} \
                --s3-bucket "$s3_bucket" \
                --s3-prefix "pr-${pr_number}" \
                --no-confirm-changeset \
                --no-fail-on-empty-changeset; then
                echo "✅ Deployed $component_name"
            else
                echo "❌ Failed to deploy $component_name"
                deployment_success=false
                failed_components="$failed_components $component_name"
            fi
            
            cd - > /dev/null
        else
            echo "⏭️ Skipping $component_name (no template.yaml)"
        fi
    done
    
    # Summary
    if [ "$deployment_success" = true ]; then
        echo "✅ PR #${pr_number} deployed successfully!"
        return 0
    else
        echo "❌ PR #${pr_number} deployment completed with failures"
        echo "   Failed components:$failed_components"
        return 1
    fi
}

#===============================================================================
# FUNCTION: check_status
# PURPOSE: Check PR environment status
#===============================================================================
check_status() {
    local pr_number=$1
    local stack_pattern="${STACK_PREFIX}-${pr_number}-"
    
    echo "🔍 Checking status for PR #${pr_number}..."
    
    # Find stacks for this PR
    local stacks=$(aws cloudformation list-stacks \
        --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE CREATE_IN_PROGRESS UPDATE_IN_PROGRESS \
        --query "StackSummaries[?contains(StackName, '${stack_pattern}')].{Name:StackName,Status:StackStatus,Created:CreationTime}" \
        --output table)
    
    if [ -n "$stacks" ]; then
        echo "📊 PR #${pr_number} Environment Status:"
        echo "$stacks"
        
        # Get stack outputs
        aws cloudformation list-stacks \
            --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
            --query "StackSummaries[?contains(StackName, '${stack_pattern}')].StackName" \
            --output text | while read stack_name; do
            
            if [ -n "$stack_name" ]; then
                echo ""
                echo "🔗 Outputs for $stack_name:"
                aws cloudformation describe-stacks \
                    --stack-name "$stack_name" \
                    --query 'Stacks[0].Outputs[].{Key:OutputKey,Value:OutputValue}' \
                    --output table 2>/dev/null || echo "  No outputs available"
            fi
        done
    else
        echo "ℹ️ No active stacks found for PR #${pr_number}"
    fi
}

#===============================================================================
# FUNCTION: cleanup_pr
# PURPOSE: Clean up PR environment
#===============================================================================
cleanup_pr() {
    local pr_number=$1
    local stack_pattern="${STACK_PREFIX}-${pr_number}-"
    
    echo "🧹 Cleaning up PR #${pr_number} environment..."
    
    # Find and delete stacks
    local stacks=$(aws cloudformation list-stacks \
        --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
        --query "StackSummaries[?contains(StackName, '${stack_pattern}')].StackName" \
        --output text)
    
    if [ -n "$stacks" ]; then
        for stack_name in $stacks; do
            echo "🗑️ Deleting stack: $stack_name"
            aws cloudformation delete-stack --stack-name "$stack_name"
            
            echo "⏳ Waiting for deletion to complete..."
            aws cloudformation wait stack-delete-complete --stack-name "$stack_name"
            echo "✅ Deleted $stack_name"
        done
        
        echo "✅ PR #${pr_number} environment cleaned up successfully!"
    else
        echo "ℹ️ No stacks found to clean up for PR #${pr_number}"
    fi
}

#===============================================================================
# FUNCTION: list_pr_environments
# PURPOSE: List all PR environments
#===============================================================================
list_pr_environments() {
    echo "📋 Listing all PR environments..."
    
    local stacks=$(aws cloudformation list-stacks \
        --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE CREATE_IN_PROGRESS UPDATE_IN_PROGRESS \
        --query "StackSummaries[?contains(StackName, '${STACK_PREFIX}-')].{Name:StackName,Status:StackStatus,Created:CreationTime}" \
        --output table)
    
    if [ -n "$stacks" ]; then
        echo "$stacks"
    else
        echo "ℹ️ No PR environments found"
    fi
}

#===============================================================================
# MAIN EXECUTION
#===============================================================================
main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi
    
    check_prerequisites
    
    local action=$1
    local pr_number=$2
    
    case $action in
        deploy)
            if [ -z "$pr_number" ]; then
                echo "❌ PR number required for deploy action"
                show_usage
                exit 1
            fi
            deploy_pr "$pr_number"
            ;;
        status)
            if [ -z "$pr_number" ]; then
                echo "❌ PR number required for status action"
                show_usage
                exit 1
            fi
            check_status "$pr_number"
            ;;
        cleanup)
            if [ -z "$pr_number" ]; then
                echo "❌ PR number required for cleanup action"
                show_usage
                exit 1
            fi
            cleanup_pr "$pr_number"
            ;;
        list)
            list_pr_environments
            ;;
        *)
            echo "❌ Unknown action: $action"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"