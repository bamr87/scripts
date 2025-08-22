# Linting Configuration Management

This directory contains scripts and tools for managing consistent linting configurations across the IT-Journey workspace.

## Overview

Lint configurations should be stored at the **repository root level** to ensure:

- ✅ **Tool Discovery**: Linting tools automatically find configurations
- ✅ **IDE Integration**: VS Code and other editors expect root-level configs
- ✅ **CI/CD Compatibility**: GitHub Actions and automation tools locate configs easily
- ✅ **Team Consistency**: All developers use the same rules

## Files

### Scripts

- **`setup-lint-configs.sh`**: Deploys appropriate lint configurations to all repositories
- **`validate-lint-setup.sh`**: Validates that all repositories have proper lint configurations

### Configuration Types

#### Jekyll Projects (`it-journey`, `zer0-mistakes`, `zer0-pages`)
- `.markdownlint.json` - Enhanced for Jekyll with Liquid templating support
- `.yamllint.yml` - YAML configuration validation

#### Shell Projects (`bashcrawl`, `scripts`)
- `.shellcheckrc` - Shell script linting rules
- `.markdownlint.json` - Basic markdown validation

#### JavaScript Projects (`ai-seed`)
- `.prettierrc.json` - Code formatting consistency
- `.editorconfig` - Editor configuration
- `.eslintrc.json` - JavaScript linting (in subdirectories)

#### AI/Evolution Projects (`ai-evolution-engine-seed`)
- All shell project configurations
- Enhanced YAML and JSON validation

## Usage

### Check Current Status
```bash
./scripts/linting/validate-lint-setup.sh
```

### Deploy Configurations
```bash
./scripts/linting/setup-lint-configs.sh
```

### Individual Repository Setup
You can also manually copy configurations to specific repositories:

```bash
# For Jekyll projects
cp configs/jekyll/.markdownlint.json /path/to/jekyll-repo/
cp configs/jekyll/.yamllint.yml /path/to/jekyll-repo/

# For Shell projects  
cp configs/shell/.shellcheckrc /path/to/shell-repo/
cp configs/shell/.markdownlint.json /path/to/shell-repo/
```

## Configuration Standards

### Markdown Linting
- **Line Length**: 120 characters (accommodates code blocks and tables)
- **HTML Elements**: Allow common Jekyll/HTML elements
- **Headers**: Flexible header rules for documentation
- **Code Blocks**: Prefer fenced blocks over indented

### YAML Linting
- **Line Length**: 120 characters maximum
- **Document Start**: Disabled (Jekyll frontmatter doesn't require `---` at start)
- **Comments**: Flexible indentation for readability
- **Truthy Values**: Standard boolean representations

### Shell Linting
- **Educational Focus**: Disabled some rules common in learning examples
- **Sourcing**: Handle dynamic script inclusion
- **Variables**: Allow unused variables in examples

## Integration with Development Workflow

### VS Code Integration
Lint configurations work automatically with VS Code extensions:
- **Markdown**: `DavidAnson.vscode-markdownlint`
- **YAML**: `redhat.vscode-yaml`
- **Shell**: `timonwong.shellcheck`

### CI/CD Integration
Configurations are automatically used by:
- GitHub Actions workflows
- Pre-commit hooks
- Automated code review tools

## Path-Driven Philosophy

Following the IT-Journey path-driven development approach:

1. **Discovery Path**: `validate-lint-setup.sh` → identifies configuration gaps
2. **Setup Path**: `setup-lint-configs.sh` → deploys appropriate configurations
3. **Validation Path**: Continuous validation ensures consistency
4. **Evolution Path**: Configurations adapt as repositories evolve

## Troubleshooting

### Common Issues

**Lint tool not found**:
```bash
# Install required tools
npm install -g markdownlint-cli2
pip install yamllint
brew install shellcheck  # macOS
```

**Configuration conflicts**:
- Remove old/conflicting configuration files
- Re-run setup script
- Check for IDE-specific overrides

**Custom project needs**:
- Extend base configurations rather than replacing
- Document project-specific requirements
- Consider creating specialized configs for unique cases

## Best Practices

1. **Repository Root**: Always place configs at repository root
2. **Consistency**: Use common configurations across similar projects
3. **Documentation**: Comment unusual or project-specific rules
4. **Validation**: Regularly check configurations are working
5. **Evolution**: Update configurations as tools and practices evolve

---

*This linting system supports the IT-Journey mission of maintaining high-quality, consistent code across all educational and development projects.*
