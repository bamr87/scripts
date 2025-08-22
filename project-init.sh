#!/bin/bash

# ==========================
# 📝 INTRODUCTION SECTION 📝
# ==========================
echo "🌟 Welcome to the Django Project Initialization Script! 🌟"
echo "This script will guide you through the process of setting up a new Django project."
echo "Let's get started!"
echo "🔧 Preparing to initialize your Django project..."<end_of_in

# ==========================
# 🔮 CONFIGURATION SECTION 🔮
# ==========================

# 1. Try to load configuration from .env file
if [ -f .env ]; then
    echo "Loading configuration from .env file..."
    source .env || { echo "❌ Error: Could not load .env file."; exit 1; }
fi

# 2. Set hardcoded defaults for any missing variables
# : ${PROJECT_NAME:="django-magic"}
# : ${APP_NAME:="magic"}
: ${GITHUB_USERNAME:="bamr87"}
GITHUB_REPO="https://github.com/$GITHUB_USERNAME/$PROJECT_NAME.git"
: ${PYTHON_VERSION:="python3"}
: ${BRANCH_NAME:="main"}
: ${VENV_NAME:="venv"}

# 3. Prompt for any variable that is still missing (last resort)
if [ -z "$PROJECT_NAME" ]; then
    read -p "Enter project name (default: django-magic): " PROJECT_NAME
    PROJECT_NAME=${PROJECT_NAME:-django-magic}
fi

if [ -z "$APP_NAME" ]; then
    read -p "Enter Django app name (default: magic): " APP_NAME
    APP_NAME=${APP_NAME:-magic}
fi

if [ -z "$GITHUB_USERNAME" ]; then
    read -p "Enter GitHub username (default: bamr87): " GITHUB_USERNAME
    GITHUB_USERNAME=${GITHUB_USERNAME:-bamr87}
    GITHUB_REPO="https://github.com/$GITHUB_USERNAME/$PROJECT_NAME.git"
fi

if [ -z "$PYTHON_VERSION" ]; then
    read -p "Enter python version (default: python3): " PYTHON_VERSION
    PYTHON_VERSION=${PYTHON_VERSION:-python3}
fi

if [ -z "$BRANCH_NAME" ]; then
    read -p "Enter branch name (default: main): " BRANCH_NAME
    BRANCH_NAME=${BRANCH_NAME:-main}
fi

if [ -z "$VENV_NAME" ]; then
    read -p "Enter virtual environment name (default: venv): " VENV_NAME
    VENV_NAME=${VENV_NAME:-venv}
fi


# ==========================
# 🚀 NAVIGATION SECTION 🚀
# ==========================
echo "🚀 Navigating to ~/github directory..."<end_o
cd ~/github || error_exit "Failed to navigate to ~/github directory."

# ==========================
# 🚀 HELPER FUNCTIONS
# ==========================
error_exit() {
    echo "❌ Error: $1"
    exit 1
}

check_command() {
    command -v "$1" >/dev/null 2>&1 || error_exit "$1 is not installed. Please install it first."
}

# ==========================
# 🔥 SETTING UP DJANGO PROJECT
# ==========================
echo "✨ Ensuring project directory exists: $PROJECT_NAME..."
mkdir -p $PROJECT_NAME && cd $PROJECT_NAME || error_exit "Failed to navigate to project directory."

echo "🐍 Checking virtual environment..."
if [ ! -d "$VENV_NAME" ]; then
    check_command $PYTHON_VERSION
    echo "🚀 Creating virtual environment..."
    $PYTHON_VERSION -m venv $VENV_NAME || error_exit "Failed to create virtual environment."
else
    echo "✅ Virtual environment already exists."
fi

echo "🧙‍♂️ Activating virtual environment..."
source $VENV_NAME/bin/activate || error_exit "Failed to activate virtual environment."

echo "📦 Checking Django installation..."
if ! python -c "import django" 2>/dev/null; then
    echo "🚀 Installing Django..."
    pip install django || error_exit "Failed to install Django."
else
    echo "✅ Django is already installed."
fi

if [ ! -d $PROJECT_NAME ]; then
    echo "🚀 Starting Django project..."
    django-admin startproject $APP_NAME . || error_exit "Failed to start Django project."
else
    echo "✅ Django project already exists."
fi

# ==========================
# 🔥 INITIALIZING GIT
# ==========================
if [ ! -d ".git" ]; then
    echo "🎩 Initializing Git repository..."
    git init || error_exit "Failed to initialize Git repository."
else
    echo "✅ Git repository already initialized."
fi

echo "⚡ Ensuring .gitignore exists..."
cat <<EOL > .gitignore
$VENV_NAME/
__pycache__/
db.sqlite3
.env
EOL
echo "✅ .gitignore updated."

echo "📜 Adding files to Git..."
git add . || error_exit "Failed to add files to Git."

if ! git rev-parse HEAD >/dev/null 2>&1; then
    echo "🖊️ Making initial commit..."
    git commit -m "Initial commit - A wizard is never late!" || error_exit "Failed to commit changes."
else
    echo "✅ Changes are already committed."
fi

# ==========================
# 🕸️ CREATING GITHUB REPO (AUTOMATIC)
# ==========================
check_command gh
echo "🔗 Checking if repository exists on GitHub..."
if ! gh repo view $GITHUB_USERNAME/$PROJECT_NAME >/dev/null 2>&1; then
    echo "⚡ Repository does not exist. Creating on GitHub..."
    gh repo create $GITHUB_USERNAME/$PROJECT_NAME --public --source=. --remote=origin || error_exit "Failed to create GitHub repository."
else
    echo "✅ Repository already exists on GitHub."
fi

# ==========================
# 🕸️ LINKING TO GITHUB
# ==========================
if ! git remote get-url origin >/dev/null 2>&1; then
    echo "🔗 Adding remote repository..."
    git remote add origin $GITHUB_REPO || error_exit "Failed to add GitHub remote."
else
    echo "✅ Remote repository already set."
fi

echo "📡 Verifying remote link..."
git remote -v || error_exit "Failed to verify remote link."

if ! git rev-parse --abbrev-ref HEAD | grep -q "^$BRANCH_NAME$"; then
    echo "🌿 Renaming branch to $BRANCH_NAME..."
    git branch -M $BRANCH_NAME || error_exit "Failed to rename branch."
else
    echo "✅ Branch is already set to $BRANCH_NAME."
fi

echo "🚀 Pushing code to GitHub..."
git push -u origin $BRANCH_NAME || echo "⚠️ Failed to push code. Make sure you are authenticated with GitHub."

# ==========================
# 🎉 FINAL MESSAGE
# ==========================
echo "✨ All done! Your Django project is now safely stored in GitHub! 🚀"
echo "🎩 To start working on your project, use:"
echo "    cd $PROJECT_NAME && source $VENV_NAME/bin/activate && code ."
echo "🛠️ Happy coding, sorcerer! 🧙‍♂️"