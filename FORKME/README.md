# 🍴 ForkMe - Advanced GitHub Repository Forking Utility

Advanced command-line utility for flexible GitHub repository forking and cloning with 10 distinct strategies optimized for analysis, review, testing, and research.

## 📚 Documentation

- **[FORKME.md](FORKME.md)** - Complete documentation with installation, strategies, examples, and best practices
- **[FORKME-QUICK-REFERENCE.md](FORKME-QUICK-REFERENCE.md)** - Quick reference card for common commands
- **[FORKME-EXAMPLES.md](FORKME-EXAMPLES.md)** - Real-world usage examples
- **[FORKME-IMPLEMENTATION-SUMMARY.md](FORKME-IMPLEMENTATION-SUMMARY.md)** - Implementation details

## 🚀 Quick Start

```bash
# Make executable
chmod +x forkme.sh

# Show help
./forkme.sh --help

# Quick shallow clone
./forkme.sh --strategy shallow --depth 1 owner/repo

# Metadata only (no clone)
./forkme.sh --analyze-only owner/repo
```

## ✨ Key Features

- **10 Forking Strategies**: Full, shallow, sparse, toplevel, structure, filetype, analysis, mirror, bundle, and metadata-only
- **Intelligent Filtering**: Filter by file types, directory patterns, and custom rules
- **GitHub Integration**: Automatic fork creation with GitHub CLI
- **Analysis Tools**: Built-in repository metadata and structure analysis
- **Optimized for Speed**: Shallow clones and sparse checkouts for large repositories

## 📋 Prerequisites

- `git` - Version control system
- `gh` - GitHub CLI (for forking functionality)
- `jq` - JSON processor (for metadata parsing)

### Installation

```bash
# macOS
brew install git gh jq

# Ubuntu/Debian
sudo apt-get install git gh jq

# Fedora/RHEL
sudo dnf install git gh jq
```

## 📖 Usage

See [FORKME.md](FORKME.md) for complete documentation.

## 🔗 Quick Links

- [Installation Guide](FORKME.md#installation)
- [Forking Strategies](FORKME.md#forking-strategies)
- [Real-World Examples](FORKME-EXAMPLES.md)
- [Quick Reference](FORKME-QUICK-REFERENCE.md)

---

**Built with ❤️ by the IT-Journey Scripts Team**
