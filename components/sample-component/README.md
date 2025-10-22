# Sample Component

Example AWS SAM component demonstrating the MilaLiso component architecture and dual-layer configuration approach.

## Overview

This component serves as a template and reference implementation for:
- Component-based architecture patterns
- Dual-layer configuration (environment + component)
- Multi-environment deployment strategies
- Testing and development workflows

## Architecture

```
sample-component/
├── template.yaml          # SAM template defining AWS resources
├── samconfig.toml         # Multi-environment deployment configuration
├── src/                   # Source code
│   └── main.py           # Lambda function handler
├── tests/                 # Component tests
│   └── test_main.py      # Unit tests
└── README.md             # This file
```

## Configuration

### Environment Inheritance
This component inherits shared settings from environment-level configs:
- **Region**: `us-east-1`
- **Capabilities**: `CAPABILITY_IAM`
- **Tags**: `Environment={env} Project=milaliso`
- **Stack Prefix**: `milaliso`

### Component-Specific Settings
Defined in `samconfig.toml`:
- **Stack Names**: `milaliso-sample-{env}`
- **S3 Prefixes**: `milaliso-sample-{env}`

## Deployment

### Development Environment
```bash
# From component directory
sam deploy --config-env dev --config-file ../../environments/dev/samconfig.toml

# From root directory
sam deploy --config-env dev \
  --config-file environments/dev/samconfig.toml \
  --template-file components/sample-component/template.yaml
```

### Test Environment
```bash
sam deploy --config-env test --config-file ../../environments/test/samconfig.toml
```

### Production Environment
```bash
sam deploy --config-env prod --config-file ../../environments/prod/samconfig.toml
```

## Local Development

### Build and Test
```bash
# Build the component
sam build

# Run unit tests
python -m pytest tests/

# Test function locally
sam local invoke SampleFunction
```

### Environment Variables
Set these for local development:
```bash
export ENVIRONMENT=dev
export LOG_LEVEL=DEBUG
```

## Resources Created

This component creates the following AWS resources:
- **Lambda Function**: Sample standalone function handler
- **IAM Role**: Execution role for Lambda (automatically created by SAM)

## Customization

To create a new component based on this template:

1. **Copy the directory structure**
2. **Update `template.yaml`**:
   - Change resource names and descriptions
   - Modify Lambda function properties
   - Add/remove AWS resources as needed
3. **Update `samconfig.toml`**:
   - Change stack names to match your component
   - Update S3 prefixes
   - Add component-specific parameters
4. **Implement your business logic** in `src/`
5. **Write tests** in `tests/`
6. **Update this README** with component-specific documentation

## Testing

Run the test suite:
```bash
# Unit tests
python -m pytest tests/ -v

# Integration tests (requires deployed stack)
python -m pytest tests/integration/ -v
```

## Monitoring

After deployment, monitor your component:
- **CloudWatch Logs**: `/aws/lambda/milaliso-sample-{env}-function`
- **CloudWatch Metrics**: Lambda function metrics
- **X-Ray Tracing**: Distributed tracing (if enabled)

## Troubleshooting

Common issues and solutions:

### Deployment Fails
- Check AWS credentials and permissions
- Verify environment-level config exists
- Ensure stack name doesn't conflict

### Local Testing Issues
- Run `sam build` before `sam local invoke`
- Check Python dependencies in `requirements.txt`
- Verify environment variables are set

### Function Errors
- Check CloudWatch logs for detailed error messages
- Verify IAM permissions for Lambda execution role
- Test function locally with `sam local invoke`