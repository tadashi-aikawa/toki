# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Toki is a macOS setup and customization project that manages dotfiles, configurations, and development tools. The project name comes from the Fist of the North Star character "Toki".

## Key Commands

### Initial Setup
```bash
# Clone and setup the project
mkdir -p ~/git/github.com/tadashi-aikawa
cd ~/git/github.com/tadashi-aikawa
git clone https://github.com/tadashi-aikawa/toki
./provision.sh
```

### Karabiner Elements Configuration
```bash
# Generate Karabiner Elements configuration files
cd karabiner/
deno task dev  # Watches for changes and auto-updates configuration
```

### Toki CLI Tool
The `toki` command provides project templates and utilities:
```bash
toki <target> <path>  # Create sandbox projects (node, vue, go, python, etc.)
toki status          # Check git status of related repositories
toki pull            # Pull all related repositories
toki provision       # Run provisioning
toki update          # Pull all repos and provision
toki webp           # Convert images to WebP format
toki mp4            # Convert MOV to MP4
toki claude         # Convert Claude Code logs to Obsidian bubble format
```

## Architecture

### Core Components

1. **Karabiner Configuration (`karabiner/`)**
   - TypeScript-based configuration using karabiner.ts library
   - Key remapping and leader key configurations
   - Modal editing support (normal, range, special modes)
   - App-specific key bindings

2. **Dotfiles and Configurations (`mnt/`)**
   - Symlinked configuration files for various tools
   - Neovim configuration with extensive plugin setup
   - Shell configurations (zsh, bash)
   - Application settings (VS Code, lazygit, etc.)

3. **Project Templates (`mnt/toki/template/`)**
   - Ready-to-use project scaffolds for different tech stacks
   - Includes configs for Node.js, Go, Python, Vue, React, etc.

4. **Raycast Extensions (`raycast/`)**
   - Custom Raycast configuration and scripts
   - Utility scripts for common tasks

### Key File Structure

- `provision.sh` - Main setup script that installs tools and creates symlinks
- `karabiner/index.ts` - Main Karabiner configuration entry point
- `mnt/nvim/` - Complete Neovim configuration with plugins and LSP setup
- `mnt/toki/toki.sh` - CLI tool for project management and utilities
- `mnt/toki/script/claude-log-to-bubble/main.ts` - Claude Code log converter for Obsidian
- `mnt/zshrc_base.sh` - Base zsh configuration

### Development Environment

- **Runtime Management**: Uses `mise` for managing multiple language versions
- **Terminal**: Ghostty terminal emulator
- **Editor**: Neovim with extensive LSP and plugin configuration
- **Launcher**: Raycast for application launching and utilities
- **Key Remapping**: Karabiner Elements for custom key bindings

### Language/Framework Support

The project includes LSP configurations and templates for:
- TypeScript/JavaScript (Node.js, Bun, Deno)
- Go with air for hot reloading
- Python with virtual environments
- Rust with Cargo
- Vue.js and Nuxt.js
- HTML/CSS with Tailwind CSS
- Lua for Neovim configuration

### Testing and Development

- No specific test commands - each template has its own testing approach
- Use `deno task dev` in `karabiner/` directory to develop key bindings
- The `toki` command provides quick project scaffolding for testing different configurations

## Important Notes

- This is a personal configuration tailored for tadashi-aikawa's workflow
- Many paths are hardcoded to specific directory structures
- The project assumes macOS environment with Homebrew
- Karabiner configurations include terminal-specific key mappings
- All configuration files use symlinks to maintain single source of truth

## Commit Rules

- Claude Code related md files (CLAUDE.md, commands/*.md, etc.) should use `feat:` prefix instead of `docs:` because they functionally add/modify Claude Code behavior