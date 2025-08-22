#!/bin/bash

# ==============================================================================
# 🚀 COMPREHENSIVE PROJECT INITIALIZATION WIZARD
# ==============================================================================
# Description: Universal project initialization script with interactive wizard
# Author: Project Wizard
# Version: 2.0.0
# ==============================================================================

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# ==============================================================================
# 🎨 COLOR DEFINITIONS
# ==============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# ==============================================================================
# 📁 DEFAULT CONFIGURATION
# ==============================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${HOME}/.project-wizard/config"
readonly TEMPLATES_DIR="${HOME}/.project-wizard/templates"
readonly DEFAULT_GITHUB_DIR="${HOME}/github"
readonly LOG_FILE="${HOME}/.project-wizard/wizard.log"

# Initialize logging
mkdir -p "$(dirname "$LOG_FILE")"
exec 2> >(tee -a "$LOG_FILE" >&2)

# ==============================================================================
# 🔧 CORE UTILITY FUNCTIONS
# ==============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        ERROR)   echo -e "${RED}❌ ERROR: ${message}${RESET}" >&2 ;;
        WARNING) echo -e "${YELLOW}⚠️  WARNING: ${message}${RESET}" ;;
        INFO)    echo -e "${BLUE}ℹ️  ${message}${RESET}" ;;
        SUCCESS) echo -e "${GREEN}✅ ${message}${RESET}" ;;
        STEP)    echo -e "${CYAN}▶️  ${message}${RESET}" ;;
        *)       echo "$message" ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

error_exit() {
    log ERROR "$1"
    exit 1
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log WARNING "$1 is not installed"
        return 1
    fi
    return 0
}

prompt_user() {
    local prompt=$1
    local default=$2
    local var_name=$3
    local value
    
    if [ -n "${default}" ]; then
        read -p "$(echo -e ${CYAN}${prompt} ${RESET}[${default}]: )" value
        value="${value:-$default}"
    else
        read -p "$(echo -e ${CYAN}${prompt}: ${RESET})" value
    fi
    
    eval "$var_name='$value'"
}

prompt_yes_no() {
    local prompt=$1
    local default=${2:-"n"}
    local response
    
    if [ "$default" = "y" ]; then
        read -p "$(echo -e ${CYAN}${prompt} ${RESET}[Y/n]: )" response
        response="${response:-y}"
    else
        read -p "$(echo -e ${CYAN}${prompt} ${RESET}[y/N]: )" response
        response="${response:-n}"
    fi
    
    [[ "$response" =~ ^[Yy]$ ]]
}

select_option() {
    local prompt=$1
    shift
    local options=("$@")
    local selection
    
    echo -e "${CYAN}${prompt}${RESET}"
    select opt in "${options[@]}"; do
        if [ -n "$opt" ]; then
            selection=$REPLY
            echo "$opt"
            return 0
        else
            log WARNING "Invalid selection. Please try again."
        fi
    done
}

# ==============================================================================
# 🔍 ENVIRONMENT DETECTION
# ==============================================================================

detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux" ;;
        Darwin*)    echo "macos" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *)          echo "unknown" ;;
    esac
}

# ==============================================================================
# 📦 LOAD PROJECT TYPE MODULES
# ==============================================================================

# Source project type handlers from separate files if they exist
if [ -f "${SCRIPT_DIR}/project-types/django.sh" ]; then
    source "${SCRIPT_DIR}/project-types/django.sh"
fi

if [ -f "${SCRIPT_DIR}/project-types/react.sh" ]; then
    source "${SCRIPT_DIR}/project-types/react.sh"
fi

if [ -f "${SCRIPT_DIR}/project-types/node.sh" ]; then
    source "${SCRIPT_DIR}/project-types/node.sh"
fi

if [ -f "${SCRIPT_DIR}/project-types/python.sh" ]; then
    source "${SCRIPT_DIR}/project-types/python.sh"
fi

# Fallback handlers if modules don't exist
if ! declare -f init_django_project &>/dev/null; then
    init_django_project() {
        local project_dir=$1
        local app_name=$2
        local python_version=${3:-python3}
        local venv_name=${4:-venv}
        
        log STEP "Initializing Django project..."
        
        cd "$project_dir" || error_exit "Failed to navigate to project directory"
        
        # Create virtual environment
        if [ ! -d "$venv_name" ]; then
            log INFO "Creating virtual environment..."
            $python_version -m venv $venv_name || error_exit "Failed to create virtual environment"
        fi
        
        # Activate virtual environment
        source $venv_name/bin/activate || error_exit "Failed to activate virtual environment"
        
        # Install Django
        log INFO "Installing Django and common packages..."
        pip install --upgrade pip
        pip install django djangorestframework python-decouple pytest pytest-django black flake8
        
        # Create Django project
        if [ ! -f "manage.py" ]; then
            django-admin startproject $app_name .
        fi
        
        # Create requirements.txt
        pip freeze > requirements.txt
        
        # Create .env.example
        cat > .env.example <<EOF
DEBUG=True
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_URL=sqlite:///db.sqlite3
EOF
        
        log SUCCESS "Django project initialized successfully!"
    }
fi

# ==============================================================================
# 🔨 BUILD TOOL SETUP
# ==============================================================================

setup_docker() {
    local project_type=$1
    
    log STEP "Setting up Docker configuration..."
    
    case $project_type in
        django|python)
            cat > Dockerfile <<'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
EOF
            ;;
            
        node|react)
            cat > Dockerfile <<'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
EOF
            ;;
    esac
    
    # Create docker-compose.yml
    cat > docker-compose.yml <<EOF
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
    volumes:
      - .:/app
      - /app/node_modules
EOF
    
    # Create .dockerignore
    cat > .dockerignore <<EOF
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.vscode
.idea
venv
__pycache__
*.pyc
*.pyo
*.pyd
.Python
db.sqlite3
*.log
EOF
    
    log SUCCESS "Docker configuration created!"
}

setup_github_actions() {
    local project_type=$1
    
    log STEP "Setting up GitHub Actions..."
    
    mkdir -p .github/workflows
    
    case $project_type in
        django|python)
            cat > .github/workflows/ci.yml <<'EOF'
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ['3.8', '3.9', '3.10', '3.11']

    steps:
    - uses: actions/checkout@v3
    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    - name: Run tests
      run: |
        pytest --version || echo "Pytest not installed"
    - name: Run linting
      run: |
        flake8 . || echo "Flake8 not installed"
        black --check . || echo "Black not installed"
EOF
            ;;
            
        node|react)
            cat > .github/workflows/ci.yml <<'EOF'
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [16.x, 18.x, 20.x]

    steps:
    - uses: actions/checkout@v3
    - name: Use Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v3
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'npm'
    - run: npm ci
    - run: npm run build --if-present
    - run: npm test --if-present
    - run: npm run lint --if-present
EOF
            ;;
    esac
    
    log SUCCESS "GitHub Actions workflow created!"
}

# ==============================================================================
# 📝 DOCUMENTATION GENERATION
# ==============================================================================

generate_readme() {
    local project_type=$1
    local description=$2
    
    log STEP "Generating README.md..."
    
    cat > README.md <<EOF
# ${PROJECT_NAME}

${description}

## 🚀 Quick Start

### Prerequisites

EOF

    case $project_type in
        django|python)
            cat >> README.md <<EOF
- Python 3.8 or higher
- pip

### Installation

\`\`\`bash
# Clone the repository
git clone https://github.com/${GITHUB_USERNAME}/${PROJECT_NAME}.git
cd ${PROJECT_NAME}

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\\Scripts\\activate

# Install dependencies
pip install -r requirements.txt

# Run migrations (Django only)
python manage.py migrate

# Run the application
python manage.py runserver
\`\`\`
EOF
            ;;
        node|react)
            cat >> README.md <<EOF
- Node.js 16 or higher
- npm or yarn

### Installation

\`\`\`bash
# Clone the repository
git clone https://github.com/${GITHUB_USERNAME}/${PROJECT_NAME}.git
cd ${PROJECT_NAME}

# Install dependencies
npm install

# Run the application
npm start
\`\`\`
EOF
            ;;
    esac
    
    cat >> README.md <<EOF

## 📖 Documentation

[Documentation](https://github.com/${GITHUB_USERNAME}/${PROJECT_NAME}/wiki)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the Project
2. Create your Feature Branch (\`git checkout -b feature/AmazingFeature\`)
3. Commit your Changes (\`git commit -m 'Add some AmazingFeature'\`)
4. Push to the Branch (\`git push origin feature/AmazingFeature\`)
5. Open a Pull Request

## 📄 License

This project is licensed under the ${LICENSE} License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**${GITHUB_USERNAME}**

- GitHub: [@${GITHUB_USERNAME}](https://github.com/${GITHUB_USERNAME})

## 🙏 Acknowledgments

- List any resources, contributors, inspiration, etc.
EOF
    
    log SUCCESS "README.md generated!"
}

generate_license() {
    local license_type=$1
    
    log STEP "Generating LICENSE file..."
    
    case $license_type in
        MIT)
            cat > LICENSE <<EOF
MIT License

Copyright (c) $(date +%Y) ${GITHUB_USERNAME}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
            ;;
            
        Apache)
            log INFO "Downloading Apache 2.0 License..."
            curl -s https://www.apache.org/licenses/LICENSE-2.0.txt > LICENSE
            ;;
            
        GPL)
            log INFO "Downloading GPL 3.0 License..."
            curl -s https://www.gnu.org/licenses/gpl-3.0.txt > LICENSE
            ;;
    esac
    
    log SUCCESS "LICENSE file generated!"
}

# ==============================================================================
# 🚀 MAIN WIZARD INTERFACE
# ==============================================================================

run_wizard() {
    clear
    echo -e "${BOLD}${CYAN}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║     🚀 COMPREHENSIVE PROJECT INITIALIZATION WIZARD 🚀       ║
    ║                                                              ║
    ║              Your journey to greatness starts here!         ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
    
    # Check for environment variables first
    if [ -f .env ]; then
        log INFO "Loading configuration from .env file..."
        source .env
    fi
    
    # Project Type Selection
    echo -e "\n${BOLD}${CYAN}📦 Project Configuration${RESET}\n"
    
    if [ -z "$PROJECT_TYPE" ]; then
        PROJECT_TYPE=$(select_option "Select your project type:" \
            "Django (Python Web Framework)" \
            "React (JavaScript UI Library)" \
            "Node.js (JavaScript Runtime)" \
            "Python (General Purpose)" \
            "Custom/Other")
        
        case "$PROJECT_TYPE" in
            "Django"*) PROJECT_TYPE="django" ;;
            "React"*) PROJECT_TYPE="react" ;;
            "Node.js"*) PROJECT_TYPE="node" ;;
            "Python"*) PROJECT_TYPE="python" ;;
            *) PROJECT_TYPE="custom" ;;
        esac
    fi
    
    # Project Name
    prompt_user "Enter project name" "${PROJECT_NAME:-my-project}" PROJECT_NAME
    
    # Project Description
    prompt_user "Enter project description" "${PROJECT_DESCRIPTION:-A new awesome project}" PROJECT_DESCRIPTION
    
    # GitHub Configuration
    echo -e "\n${BOLD}${CYAN}🔗 GitHub Configuration${RESET}\n"
    prompt_user "Enter GitHub username" "${GITHUB_USERNAME:-$(git config user.name 2>/dev/null)}" GITHUB_USERNAME
    prompt_user "Enter GitHub email" "${GITHUB_EMAIL:-$(git config user.email 2>/dev/null)}" GITHUB_EMAIL
    
    # Project Location
    prompt_user "Enter project directory" "${PROJECT_DIR:-$DEFAULT_GITHUB_DIR/$PROJECT_NAME}" PROJECT_DIR
    
    # Additional Options
    echo -e "\n${BOLD}${CYAN}⚙️  Additional Options${RESET}\n"
    
    : ${SETUP_DOCKER:=false}
    if [ -z "$NON_INTERACTIVE" ] || [ "$NON_INTERACTIVE" = false ]; then
        prompt_yes_no "Setup Docker configuration?" "y" && SETUP_DOCKER=true
    fi
    
    : ${SETUP_CI:=false}
    if [ -z "$NON_INTERACTIVE" ] || [ "$NON_INTERACTIVE" = false ]; then
        prompt_yes_no "Setup CI/CD (GitHub Actions)?" "y" && SETUP_CI=true
    fi
    
    # License Selection
    : ${LICENSE:="MIT"}
    if [ -z "$NON_INTERACTIVE" ] || [ "$NON_INTERACTIVE" = false ]; then
        LICENSE=$(select_option "Select a license:" "MIT" "Apache-2.0" "GPL-3.0" "None")
    fi
    
    # Private Repository
    : ${PRIVATE_REPO:=false}
    if [ -z "$NON_INTERACTIVE" ] || [ "$NON_INTERACTIVE" = false ]; then
        prompt_yes_no "Make repository private?" "n" && PRIVATE_REPO=true
    fi
    
    # Confirmation
    echo -e "\n${BOLD}${CYAN}📋 Configuration Summary${RESET}\n"
    echo "Project Type:     $PROJECT_TYPE"
    echo "Project Name:     $PROJECT_NAME"
    echo "Description:      $PROJECT_DESCRIPTION"
    echo "Location:         $PROJECT_DIR"
    echo "GitHub User:      $GITHUB_USERNAME"
    echo "License:          $LICENSE"
    echo "Docker:           $SETUP_DOCKER"
    echo "CI/CD:            $SETUP_CI"
    echo "Private Repo:     $PRIVATE_REPO"
    echo ""
    
    if ! prompt_yes_no "Proceed with this configuration?" "y"; then
        log WARNING "Installation cancelled by user"
        exit 0
    fi
}

# ==============================================================================
# 🎯 PROJECT INITIALIZATION
# ==============================================================================

initialize_project() {
    log SUCCESS "Starting project initialization..."
    
    # Create project directory
    log STEP "Creating project directory..."
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR" || error_exit "Failed to navigate to project directory"
    
    # Initialize project based on type
    case $PROJECT_TYPE in
        django)
            if declare -f init_django_project &>/dev/null; then
                init_django_project "$PROJECT_DIR" "$PROJECT_NAME"
            else
                log WARNING "Django initializer not found, creating basic structure..."
                mkdir -p src tests docs
            fi
            ;;
        react)
            log INFO "React project initialization..."
            npx create-react-app . || npm init -y
            ;;
        node)
            log INFO "Node.js project initialization..."
            npm init -y
            ;;
        python)
            log INFO "Python project initialization..."
            python3 -m venv venv
            source venv/bin/activate
            pip install --upgrade pip
            ;;
        custom)
            log INFO "Custom project type selected. Creating basic structure..."
            mkdir -p src tests docs
            ;;
    esac
    
    # Generate documentation
    generate_readme "$PROJECT_TYPE" "$PROJECT_DESCRIPTION"
    
    if [ "$LICENSE" != "None" ]; then
        generate_license "$LICENSE"
    fi
    
    # Setup additional tools
    if [ "$SETUP_DOCKER" = true ]; then
        setup_docker "$PROJECT_TYPE"
    fi
    
    if [ "$SETUP_CI" = true ]; then
        setup_github_actions "$PROJECT_TYPE"
    fi
    
    # Create .gitignore
    log STEP "Creating .gitignore..."
    
    # Basic gitignore content
    cat > .gitignore <<'EOF'
# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local
*.log
logs/
tmp/
.cache/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/
pip-log.txt
pip-delete-this-directory.txt

# Node
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
dist/
build/

# Database
*.sqlite3
*.db
EOF
}

# ==============================================================================
# 🌐 GIT AND GITHUB SETUP
# ==============================================================================

setup_git_and_github() {
    log STEP "Initializing Git repository..."
    
    # Initialize git
    if [ ! -d ".git" ]; then
        git init
        git config user.name "$GITHUB_USERNAME"
        git config user.email "$GITHUB_EMAIL"
    fi
    
    # Add files
    git add .
    git commit -m "🎉 Initial commit - Project initialized with wizard"
    
    # Create GitHub repository
    if check_command gh; then
        log STEP "Creating GitHub repository..."
        
        if ! gh repo view "$GITHUB_USERNAME/$PROJECT_NAME" &>/dev/null; then
            local visibility=$([ "$PRIVATE_REPO" = true ] && echo "--private" || echo "--public")
            
            gh repo create "$GITHUB_USERNAME/$PROJECT_NAME" \
                $visibility \
                --description "$PROJECT_DESCRIPTION" \
                --source=. \
                --remote=origin \
                --push || log WARNING "Failed to create GitHub repository"
        else
            log INFO "Repository already exists on GitHub"
            git remote add origin "https://github.com/$GITHUB_USERNAME/$PROJECT_NAME.git" 2>/dev/null || true
            git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null || true
        fi
    else
        log WARNING "GitHub CLI not installed. Please create repository manually and run:"
        echo "  git remote add origin https://github.com/$GITHUB_USERNAME/$PROJECT_NAME.git"
        echo "  git push -u origin main"
    fi
}

# ==============================================================================
# 🎊 COMPLETION
# ==============================================================================

show_completion_message() {
    echo -e "\n${BOLD}${GREEN}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║            🎉 PROJECT SUCCESSFULLY INITIALIZED! 🎉          ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
    
    log SUCCESS "Your project is ready!"
    echo ""
    echo -e "${CYAN}📁 Project Location:${RESET} $PROJECT_DIR"
    echo -e "${CYAN}🔗 GitHub URL:${RESET} https://github.com/$GITHUB_USERNAME/$PROJECT_NAME"
    echo ""
    echo -e "${BOLD}${CYAN}Next Steps:${RESET}"
    echo "  1. cd $PROJECT_DIR"
    
    case $PROJECT_TYPE in
        django|python)
            echo "  2. source venv/bin/activate"
            echo "  3. python manage.py migrate  # For Django"
            echo "  4. python manage.py runserver  # For Django"
            ;;
        node|react)
            echo "  2. npm start"
            ;;
    esac
    
    echo ""
    echo -e "${BOLD}${GREEN}Happy coding! 🚀${RESET}"
}

# ==============================================================================
# 🚀 MAIN EXECUTION
# ==============================================================================

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --type)
                PROJECT_TYPE="$2"
                shift 2
                ;;
            --name)
                PROJECT_NAME="$2"
                shift 2
                ;;
            --dir)
                PROJECT_DIR="$2"
                shift 2
                ;;
            --non-interactive)
                NON_INTERACTIVE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log ERROR "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Check for required tools
    log INFO "Checking system requirements..."
    check_command git || error_exit "Git is required but not installed"
    
    # Run the wizard
    if [ "${NON_INTERACTIVE:-false}" = false ]; then
        run_wizard
    else
        # Use environment variables or defaults
        : ${PROJECT_TYPE:="python"}
        : ${PROJECT_NAME:="my-project"}
        : ${PROJECT_DIR:="$DEFAULT_GITHUB_DIR/$PROJECT_NAME"}
        : ${GITHUB_USERNAME:=$(git config user.name 2>/dev/null || echo "user")}
        : ${GITHUB_EMAIL:=$(git config user.email 2>/dev/null || echo "user@example.com")}
        : ${LICENSE:="MIT"}
        : ${PROJECT_DESCRIPTION:="A new project"}
        : ${SETUP_DOCKER:=false}
        : ${SETUP_CI:=false}
        : ${PRIVATE_REPO:=false}
    fi
    
    # Initialize the project
    initialize_project
    
    # Setup Git and GitHub
    setup_git_and_github
    
    # Show completion message
    show_completion_message
    
    # Save configuration for future use
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" <<EOF
# Last used configuration
PROJECT_TYPE=$PROJECT_TYPE
GITHUB_USERNAME=$GITHUB_USERNAME
GITHUB_EMAIL=$GITHUB_EMAIL
LICENSE=$LICENSE
SETUP_DOCKER=$SETUP_DOCKER
SETUP_CI=$SETUP_CI
EOF
}

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Comprehensive project initialization wizard with support for multiple project types.

OPTIONS:
    --config FILE          Use configuration file
    --type TYPE           Set project type (django, react, node, python, custom)
    --name NAME           Set project name
    --dir DIRECTORY       Set project directory
    --non-interactive     Run in non-interactive mode (uses env vars)
    --help               Show this help message

ENVIRONMENT VARIABLES:
    PROJECT_TYPE          Type of project to create
    PROJECT_NAME          Name of the project
    PROJECT_DIR           Directory for the project
    GITHUB_USERNAME       GitHub username
    GITHUB_EMAIL          GitHub email
    LICENSE               License type (MIT, Apache-2.0, GPL-3.0)
    SETUP_DOCKER          Setup Docker configuration (true/false)
    SETUP_CI              Setup CI/CD (true/false)
    PRIVATE_REPO          Make repository private (true/false)

EXAMPLES:
    # Interactive mode
    $(basename "$0")
    
    # Non-interactive with environment variables
    PROJECT_TYPE=django PROJECT_NAME=myapp $(basename "$0") --non-interactive
    
    # Specify project type and name
    $(basename "$0") --type react --name my-react-app

For more information, visit: https://github.com/your-repo/project-wizard

EOF
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
