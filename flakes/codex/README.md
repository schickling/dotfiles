# OpenAI Codex Nix Flake

This flake packages the [OpenAI Codex](https://github.com/openai/codex) CLI for Nix.

## Usage

### Direct installation

```bash
nix profile install github:schickling/nix-config?dir=flakes/codex
```

### Development shell

```bash
nix develop github:schickling/nix-config?dir=flakes/codex
```

### Run without installing

```bash
nix run github:schickling/nix-config?dir=flakes/codex
```

## Supported Platforms

- ✅ macOS (Intel)
- ✅ macOS (Apple Silicon)
- ✅ Linux (x86_64)
- ✅ Linux (ARM64)

## Version

Current version: **0.61.0**

Based on release `rust-v0.61.0` from the official OpenAI Codex repository.

## About Codex

OpenAI Codex is an AI-powered coding agent that runs locally on your computer. It supports:

- Terminal-based interaction
- Model Context Protocol (MCP)
- Authentication via ChatGPT account or API key
- Configuration via `~/.codex/config.toml`

For more information, visit the [official repository](https://github.com/openai/codex).
