# MilaLiso Components

This directory contains independent system components, each with its own AWS SAM template and configuration.

## Component Architecture

Each component follows this structure:
```
component-name/
├── template.yaml          # SAM template with AWS resources
├── samconfig.toml         # Multi-environment deployment config
├── src/                   # Source code
├── tests/                 # Component tests
└── README.md             # Component-specific documentation
```

## Configuration Strategy

Components use **dual-layer configuration**:

### Environment-Level Defaults
- Located in `../environments/{env}/samconfig.toml`
- Defines shared settings: region, capabilities, tags, naming conventions
- Inherited by all components in that environment

### Component-Level Overrides
- Located in `{component}/samconfig.toml`
- Defines component-specific settings: stack names, parameters, S3 prefixes
- Inherits and can override environment defaults

## Deployment Commands

### From Component Directory
```bash
cd components/your-component
sam deploy --config-env dev
```

### From Root Directory
```bash
sam deploy --config-env dev \
  --template-file components/your-component/template.yaml
```

## Available Components

- **sample-component** - Example component demonstrating architecture patterns

## Creating New Components

1. Copy `sample-component` as a template
2. Update `template.yaml` with your resources
3. Modify `samconfig.toml` with component-specific settings
4. Update component README with specific documentation
5. Implement your business logic in `src/`

## Best Practices

- Keep components independent and loosely coupled
- Use environment variables for cross-component communication
- Follow consistent naming conventions defined in environment configs
- Write component-specific tests in the `tests/` directory