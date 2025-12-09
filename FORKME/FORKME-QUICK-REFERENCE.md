# ForkMe Quick Reference Card

## 🚀 Command Format

```bash
./forkme.sh [options] <repo-url>
```

## 📋 Forking Strategies Cheat Sheet

| Strategy | Use Case | Command |
|----------|----------|---------|
| **full** | Complete development | `--strategy full` |
| **shallow** | Quick review/testing | `--strategy shallow --depth 1` |
| **sparse** | Specific directories | `--strategy sparse --sparse-paths "src/,docs/"` |
| **toplevel** | Root files only | `--strategy toplevel` |
| **structure** | Directory tree | `--strategy structure` |
| **filetype** | Specific file types | `--strategy filetype --file-types "py,js"` |
| **analysis** | Fast audit/review | `--strategy analysis` |
| **mirror** | Backup/archival | `--strategy mirror` |
| **bundle** | Offline/portable | `--strategy bundle` |
| **metadata** | Info only (no clone) | `--strategy metadata` or `--analyze-only` |

## ⚡ Common Commands

### Quick Review
```bash
./forkme.sh --strategy shallow --depth 1 owner/repo
```

### Documentation Only
```bash
./forkme.sh --strategy filetype --file-types "md,txt" owner/repo
```

### Security Audit
```bash
./forkme.sh --strategy analysis --sparse-paths "src/,*.config" owner/repo
```

### No Fork (Clone Only)
```bash
./forkme.sh --no-fork --strategy shallow owner/repo
```

### Dry Run (Preview)
```bash
./forkme.sh --dry-run --strategy <type> owner/repo
```

### Get Repository Info
```bash
./forkme.sh --analyze-only owner/repo
```

## 🎯 Use Case Matrix

| Need | Strategy | Options |
|------|----------|---------|
| **Quick code review** | `shallow` | `--depth 1` |
| **Docs extraction** | `filetype` | `--file-types "md,txt,rst"` |
| **Config audit** | `sparse` | `--sparse-paths "*.yml,*.json"` |
| **Structure overview** | `structure` | `--analyze` |
| **Full development** | `full` | (default) |
| **Offline work** | `bundle` | - |
| **Project info** | `metadata` | `--analyze-only` |

## 🔧 Essential Options

```bash
--strategy <type>           # Forking strategy
--depth <n>                 # Commit depth (shallow)
--branch <name>             # Specific branch
--no-fork                   # Skip GitHub fork
--target <dir>              # Target directory
--work-dir <dir>            # Working directory
--file-types <ext>          # File extensions (comma-separated)
--sparse-paths <paths>      # Sparse checkout paths
--analyze-only              # Metadata only
--dry-run                   # Preview mode
--verbose                   # Debug output
--help                      # Show help
```

## 💡 Pro Tips

1. **Always start with metadata:**
   ```bash
   ./forkme.sh --analyze-only owner/repo
   ```

2. **Use dry run for complex operations:**
   ```bash
   ./forkme.sh --dry-run --verbose --strategy sparse owner/repo
   ```

3. **Combine strategies for efficiency:**
   ```bash
   ./forkme.sh --strategy analysis --sparse-paths "src/" --depth 1 owner/repo
   ```

4. **Security-first approach:**
   ```bash
   # Check metadata first, then shallow clone
   ./forkme.sh --analyze-only unknown/repo
   ./forkme.sh --strategy shallow --depth 1 --no-fork unknown/repo
   ```

## 📊 File Type Shortcuts

| Use Case | File Types |
|----------|------------|
| **Documentation** | `md,txt,rst,adoc` |
| **Python** | `py,pyx,pyi` |
| **JavaScript** | `js,jsx,ts,tsx` |
| **Web** | `html,css,js` |
| **Config** | `yml,yaml,json,toml,ini` |
| **Infrastructure** | `tf,hcl,dockerfile,yml` |
| **Scripts** | `sh,bash,zsh,py,rb` |

## 🐛 Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| Auth failed | `gh auth login` |
| Missing deps | `brew install git gh jq` (macOS) |
| Permission denied | Use HTTPS URL |
| Slow clone | Use `--strategy shallow --depth 1` |
| Sparse paths fail | Check path format (no leading `/`) |
| Target exists | Remove it or use `--target` option |

## 📖 Repository URL Formats

```bash
# Full URL
./forkme.sh https://github.com/owner/repo

# SSH URL
./forkme.sh git@github.com:owner/repo.git

# Short form
./forkme.sh owner/repo
```

## 🔍 Common Workflows

### Security Review Workflow
```bash
# Step 1: Get metadata
./forkme.sh --analyze-only vendor/library

# Step 2: Review configs
./forkme.sh --strategy sparse --sparse-paths "*.yml,*.json,Dockerfile" --no-fork vendor/library

# Step 3: Review source
./forkme.sh --strategy sparse --sparse-paths "src/,lib/" vendor/library
```

### Contribution Workflow
```bash
# Step 1: Check project
./forkme.sh --analyze-only owner/project

# Step 2: Get structure
./forkme.sh --strategy structure owner/project

# Step 3: Fork and clone
./forkme.sh --strategy full owner/project
```

### Documentation Extraction
```bash
# Get all docs
./forkme.sh --strategy filetype --file-types "md,txt,rst" --no-fork owner/repo

# Get specific docs
./forkme.sh --strategy sparse --sparse-paths "docs/,README.md" --no-fork owner/repo
```

---

**For complete documentation, see [FORKME.md](FORKME.md)**
