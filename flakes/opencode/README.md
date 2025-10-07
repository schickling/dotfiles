# opencode Nix Flake

This flake packages the [opencode](https://github.com/sst/opencode) CLI for Nix.

## Usage

### Direct installation

```bash
nix profile install github:schickling/nix-config?dir=flakes/opencode
```

### Development shell

```bash
nix develop github:schickling/nix-config?dir=flakes/opencode
```

### Run without installing

```bash
nix run github:schickling/nix-config?dir=flakes/opencode
```

## Supported Platforms

- ✅ macOS (Intel)
- ✅ macOS (Apple Silicon)
- ✅ Linux (x86_64)
- ✅ Linux (ARM64)

## Version

Current version: **0.14.5**

Based on release `v0.14.5` from the official opencode repository.

## About opencode

opencode is an open-source, self-hosted AI coding agent created by the SST team. It focuses on transparency and control while providing:

- Local execution with Model Context Protocol support
- Integrations for popular editors and tooling
- Fast Bun-based runtime

For more information, visit the [official repository](https://github.com/sst/opencode).
