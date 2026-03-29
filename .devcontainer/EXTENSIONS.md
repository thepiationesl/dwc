# VS Code Extensions Configuration

## Overview

This document describes the VS Code extensions configuration for DWC dev containers.

## Container Profiles

### cs50-vm

Optimized for CS50 education with comprehensive extensions:

**CS50-specific Extensions:**
- `cs50.ddb50` - CS50 Duck Debugger (rubber duck debugging)
- `cs50.lab50` - CS50 Lab for VS Code
- `cs50.markdown50` - CS50-Flavored Markdown
- `cs50.vscode-presentation-mode` - Presentation Mode for teaching
- `surisurya19.style50` - Python/C code formatter

**Development Tools:**
- `ms-python.python` - Python support
- `ms-python.autopep8` - Python code formatter
- `ms-vscode.cpptools` - C/C++ support
- `redhat.java` - Java support
- `vscjava.vscode-java-debug` - Java debugger

**Utilities:**
- `github.copilot` - GitHub Copilot
- `github.copilot-chat` - Copilot Chat
- `cs50.extension-uninstaller` - Batch uninstaller
- `inferrinizzard.prettier-sql-vscode` - SQL formatter
- `mathematic.vscode-pdf` - PDF viewer
- `ms-vsliveshare.vsliveshare` - Live Share
- `vsls-contrib.gitdoc` - GitDoc for collaborative editing

**Language Packs:**
- Czech, German, Spanish, French, Italian, Japanese, Korean
- Polish, Portuguese (BR), Russian, Chinese (Simplified & Traditional)

### dev-debian

Minimal setup for general development:

**Core Extensions:**
- `ms-azuretools.vscode-docker` - Docker support
- `ms-python.python` - Python support
- `ms-python.autopep8` - Python formatter
- `ms-vscode.cpptools` - C/C++ support

## Migration from Local .vsix Files

**Previous Configuration (No Longer Used):**

The old configuration referenced local .vsix files that were not included in the repository:
- `/opt/cs50/extensions/explain50-1.0.0.vsix`
- `/opt/cs50/extensions/cs50-0.0.1.vsix`
- `/opt/cs50/extensions/design50-1.0.0.vsix`
- `/opt/cs50/extensions/ddb50-2.0.0.vsix`
- `/opt/cs50/extensions/phpliteadmin-0.0.1.vsix`
- `/opt/cs50/extensions/style50-0.0.1.vsix`

**Current Approach:**

All extensions are now sourced from VS Code Marketplace, ensuring:
- ✅ Automatic installation during container creation
- ✅ Consistent versions across all environments
- ✅ No missing dependencies
- ✅ Easy maintenance and updates

## Adding Custom Extensions

To add a custom .vsix extension in the future:

1. Download or build the `.vsix` file
2. Place it in any accessible directory within the container
3. Update the devcontainer.json to reference it:
   ```json
   "/path/to/your/extension.vsix"
   ```

The `/opt/cs50/extensions/` directory remains available for this purpose.

## Debugging

To verify installed extensions:

```bash
code --list-extensions
```

Setup logs are available at:
```
/tmp/cs50_devcontainer_setup.log
```

## References

- [VS Code Extension Marketplace](https://marketplace.visualstudio.com)
- [DevContainers Extensions Reference](https://containers.dev/implementers/json_reference/#customizations)
- [CS50 Extensions](https://marketplace.visualstudio.com/search?term=cs50&sortBy=Relevance)
