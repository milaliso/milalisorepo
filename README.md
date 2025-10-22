# MilaLiso Repository

MilaLiso beaded jewelry design and business management system built with AWS SAM and component-based architecture.

## Repository Structure

```
milalisorepo/
├── .github/workflows/     # CI/CD pipeline configurations
├── components/           # Independent system components
│   ├── sample-component/ # Example component with template & config
│   └── README.md        # Component development guide
├── environments/        # Environment-level configuration defaults
│   ├── dev/             # Development environment defaults
│   ├── test/            # Test environment defaults
│   └── prod/            # Production environment defaults
├── docs/               # Documentation and guides
└── scripts/            # Deployment and utility scripts
```

## Architecture

This repository uses a **component-based architecture** with **dual-layer configuration**:

- **Environment-level configs** (`environments/*/samconfig.toml`) - Shared defaults (region, tags, capabilities)
- **Component-level configs** (`components/*/samconfig.toml`) - Component-specific overrides (stack names, parameters)

## Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/yourusername/milalisorepo.git
cd milalisorepo
```

### 2. Deploy a Component
```bash
# Deploy sample component to dev
cd components/sample-component
sam deploy --config-env dev --config-file ../../environments/dev/samconfig.toml

# Or from root directory
sam deploy --config-env dev --config-file environments/dev/samconfig.toml --template-file components/sample-component/template.yaml
```

### 3. Development Workflow
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make changes and test
sam build
sam local invoke SampleFunction

# Deploy to dev for testing
sam deploy --config-env dev --config-file ../../environments/dev/samconfig.toml

# Commit and push
git add .
git commit -m "Your changes"
git push origin feature/your-feature-name
```

## Environment Management

- **dev** - Fast iteration, no changeset confirmation
- **test** - Staging environment with changeset confirmation
- **prod** - Production environment with strict controls

See [Branching Strategy](docs/BRANCHING_STRATEGY.md) for deployment workflows.

---

**© 2025 MilaLiso - All Rights Reserved**  
*Proprietary software - Unauthorized copying or distribution is prohibited*