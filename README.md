# �️ IT-Journey Scripts Collection

A comprehensive collection of powerful command-line utilities for project initialization, GitHub repository management, and development workflows.

## 📦 Available Tools

### 🚀 Project Initialization Wizard (`project-init.sh`)
A powerful, interactive command-line wizard for initializing new software projects with best practices, automated setup, and GitHub integration.

### 🍴 ForkMe - Repository Forking Utility (`forkme.sh`)
Advanced GitHub repository forking and cloning utility with 10 distinct strategies optimized for analysis, review, testing, and research. [See ForkMe Documentation →](FORKME.md)

### 📁 Rename Directory Utility (`rename-directory.sh`)
Safely rename directories with optional backup, Docker container management, and git repository integrity checks. Perfect for rebranding projects or reorganizing workspace structures.

---

## 🍴 ForkMe - Quick Overview

ForkMe provides flexible forking and cloning options for GitHub repositories, going beyond simple `git clone`:

### Key Features
- **10 Forking Strategies**: Full, shallow, sparse, toplevel, structure, filetype, analysis, mirror, bundle, and metadata-only
- **Intelligent Filtering**: Filter by file types, directory patterns, and custom rules
- **GitHub Integration**: Automatic fork creation with GitHub CLI
- **Analysis Tools**: Built-in repository metadata and structure analysis
- **Optimized for Speed**: Shallow clones and sparse checkouts for large repositories

### Quick Start Examples

```bash
# Full repository documentation
./forkme.sh --help

# Quick shallow clone for review
./forkme.sh --strategy shallow --depth 1 owner/repo

# Extract documentation only
./forkme.sh --strategy filetype --file-types "md,txt" owner/repo

# Security configuration audit
./forkme.sh --strategy sparse --sparse-paths "src/,*.config" owner/repo

# Get repository metadata without cloning
./forkme.sh --analyze-only owner/repo
```

**→ [Full ForkMe Documentation](FORKME.md)**  
**→ [Quick Reference Card](FORKME-QUICK-REFERENCE.md)**

---

## � Rename Directory Utility

A safe and reliable tool for renaming directories with intelligent handling of git repositories, Docker containers, and automatic backups.

### Key Features
- **Pre-flight Checks**: Validates source/target paths, permissions, and dependencies
- **Docker Integration**: Automatically detects and stops related containers
- **Git Safety**: Checks repository status and preserves git history
- **Backup Option**: Optional backup creation before rename operation
- **Comprehensive Logging**: Detailed status messages and error handling
- **Universal**: Works with any directory structure

### Quick Start Examples

```bash
# Basic directory rename
./rename-directory.sh ~/projects/old-name ~/projects/new-name

# Rename with full paths
./rename-directory.sh /Users/username/github/posthog /Users/username/github/bashog

# Get help
./rename-directory.sh --help
```

### What It Does

1. **Validates Paths**: Ensures source exists and target is available
2. **Checks Docker**: Finds and offers to stop related containers
3. **Verifies Git**: Checks repository status and uncommitted changes
4. **Creates Backup**: Optional full backup before rename (recommended)
5. **Performs Rename**: Safely moves directory to new location
6. **Verifies Operation**: Confirms rename success and git integrity
7. **Provides Guidance**: Lists next steps and important notes

### Safety Features

- Won't overwrite existing directories
- Checks write permissions before proceeding
- Preserves git history and configuration
- Stops related Docker containers to prevent conflicts
- Warns about uncommitted git changes
- Verifies successful rename before completion

### Use Cases

- **Rebranding Projects**: Rename project directories when changing names
- **Workspace Organization**: Restructure your development environment
- **Repository Migration**: Safely rename cloned repositories
- **Project Cleanup**: Reorganize project hierarchies

---

## �🚀 Project Initialization Wizard

## ✨ Features

- **🎯 Multiple Project Types**: Support for Django, React, Node.js, Python, Rust, Go, and custom projects
- **🔧 Interactive Wizard**: User-friendly prompts guide you through project configuration
- **📦 Environment Variables**: Full support for `.env` files for automated configuration
- **🐳 Docker Support**: Automatic Docker and docker-compose configuration
- **🔄 CI/CD Integration**: GitHub Actions workflow generation
- **📄 Documentation**: Automatic README and LICENSE file generation
- **🌐 GitHub Integration**: Automatic repository creation and initial push
- **🎨 Code Quality Tools**: ESLint, Prettier, Black, Flake8 setup based on project type
- **🧪 Testing Frameworks**: Pytest, Jest, and other testing tools pre-configured

## 🚀 Quick Start

### Installation

1. Clone or download the scripts:
```bash
git clone https://github.com/bamr87/scripts.git
cd scripts
```

2. Make the script executable:
```bash
chmod +x project-init.sh
```

3. (Optional) Add to PATH for global access:
```bash
echo 'export PATH="$PATH:~/github/scripts"' >> ~/.bashrc
source ~/.bashrc
```

### Basic Usage

#### Interactive Mode (Recommended)
```bash
./project-init.sh
```

The wizard will guide you through:
1. Selecting project type
2. Naming your project
3. Configuring GitHub settings
4. Choosing additional features (Docker, CI/CD, etc.)
5. Selecting a license

#### Non-Interactive Mode
```bash
# Using environment variables
PROJECT_TYPE=django PROJECT_NAME=myapp ./project-init.sh --non-interactive

# Using command-line arguments
./project-init.sh --type react --name my-react-app --dir ~/projects/my-react-app
```

## 📋 Configuration

### Environment Variables

Copy `env.example` to `.env` and customize:

```bash
cp env.example .env
# Edit .env with your preferred settings
```

Key configuration options:

| Variable | Description | Options |
|----------|-------------|---------|
| `PROJECT_TYPE` | Type of project to create | `django`, `react`, `node`, `python`, `rust`, `go`, `custom` |
| `PROJECT_NAME` | Name of your project | Any valid directory name |
| `GITHUB_USERNAME` | Your GitHub username | Your GitHub handle |
| `LICENSE` | License type | `MIT`, `Apache-2.0`, `GPL-3.0`, `BSD-3-Clause`, `None` |
| `SETUP_DOCKER` | Create Docker configuration | `true`, `false` |
| `SETUP_CI` | Setup GitHub Actions | `true`, `false` |

See `env.example` for the complete list of available options.

### Command-Line Options

```
Usage: project-init.sh [OPTIONS]

OPTIONS:
    --config FILE          Use specific configuration file
    --type TYPE           Set project type (django, react, node, python, rust, go, custom)
    --name NAME           Set project name
    --dir DIRECTORY       Set project directory
    --non-interactive     Run in non-interactive mode (uses env vars)
    --help               Show help message
```

## 🛠️ Project Type Details

### Django Projects
- Virtual environment with `venv`
- Django + Django REST Framework
- Testing with pytest and pytest-django
- Code formatting with Black and Flake8
- `.env` file support with python-decouple
- Database migrations ready

### React Projects
- Choice between Vite or Create React App
- TypeScript support
- ESLint and Prettier configuration
- Husky for git hooks
- Modern React best practices

### Node.js Projects
- Express, Fastify, or Koa framework options
- TypeScript support
- Nodemon for development
- Security headers with Helmet
- CORS configuration

### Python Projects
Three sub-types available:
- **Package**: Complete package structure with setup.py
- **CLI**: Click-based CLI application template
- **Data Science**: Jupyter, NumPy, Pandas, and visualization tools

### Rust Projects
- Cargo project initialization
- Common dependencies pre-configured
- Binary or library project options

### Go Projects
- Go modules initialization
- Basic HTTP server template
- Standard project layout

## 🐳 Docker Integration

When Docker support is enabled, the wizard creates:
- `Dockerfile` optimized for your project type
- `docker-compose.yml` for local development
- `.dockerignore` with sensible defaults

## 🔄 CI/CD Integration

GitHub Actions workflows are tailored to each project type:
- **Python/Django**: Multiple Python version testing, linting, formatting checks
- **Node/React**: Node version matrix, build verification, test execution
- **Custom workflows**: Easily extensible for other project types

## 📝 Generated Files

The wizard creates a complete project structure:

```
my-project/
├── src/                 # Source code
├── tests/               # Test files
├── docs/                # Documentation
├── .github/
│   └── workflows/
│       └── ci.yml       # GitHub Actions workflow
├── Dockerfile           # Docker configuration
├── docker-compose.yml   # Docker Compose setup
├── README.md            # Project documentation
├── LICENSE              # License file
├── .gitignore           # Git ignore rules
└── [Type-specific files]
```

## 🔒 Prerequisites

### Required
- Git
- Bash 4.0+

### Optional (based on project type)
- Python 3.8+
- Node.js 16+
- Docker
- GitHub CLI (`gh`) for automatic repository creation
- Rust/Cargo
- Go 1.21+

## 🤝 Advanced Features

### Custom Project Templates

Create your own project templates by:
1. Adding a new handler function in the script
2. Defining the project structure
3. Specifying dependencies and configuration

### Post-Installation Hooks

The wizard supports custom initialization scripts:
```bash
RUN_CUSTOM_SCRIPT=true
CUSTOM_SCRIPT_PATH=./my-custom-init.sh
```

### Workspace Configuration

For VS Code users, enable workspace settings generation:
```bash
SETUP_VSCODE=true
```

## 📚 Examples

### Create a Django REST API
```bash
PROJECT_TYPE=django \
PROJECT_NAME=my-api \
SETUP_DOCKER=true \
SETUP_CI=true \
./project-init.sh --non-interactive
```

### Create a React TypeScript App with Vite
```bash
./project-init.sh --type react --name my-app
# Then select TypeScript and Vite options
```

### Create a Python Package
```bash
PROJECT_TYPE=python \
PROJECT_NAME=awesome-package \
LICENSE=MIT \
./project-init.sh --non-interactive
```

## 🐛 Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   chmod +x project-init.sh
   ```

2. **GitHub CLI Not Found**
   - Install with: `brew install gh` (macOS) or `apt install gh` (Ubuntu)
   - Or create repository manually after project initialization

3. **Python/Node Version Issues**
   - Ensure the correct version is installed
   - Update `PYTHON_VERSION` or `NODE_VERSION` in `.env`

### Logs

Check the wizard log for detailed information:
```bash
tail -f ~/.project-wizard/wizard.log
```

## 🚀 Features Overview

The consolidated `project-init.sh` provides:

1. Interactive wizard interface with intuitive prompts
2. Full environment variable support for automation
3. Multiple project type support with best practices
4. Automated GitHub integration and repository creation
5. Docker and CI/CD setup for modern development workflows

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📮 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing issues for solutions
- Read the logs in `~/.project-wizard/wizard.log`

## 🙏 Acknowledgments

- Inspired by various project scaffolding tools
- Built with best practices from the developer community
- Special thanks to all contributors

---

**Happy Coding! 🎉**

*Built with ❤️ by the developer community*
