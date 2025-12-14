# Astralis Game Registry

A centralized registry repository for game server configurations, frameworks, and plugins used by the Astralis game server management daemon.

## Overview

This registry serves as the single source of truth for game server definitions, framework configurations, and plugin metadata. The Astralis daemon automatically fetches and caches this registry from GitHub to provide comprehensive game server management capabilities.

## What's Inside

This repository contains **data-only** configurations:

- **Game Definitions**: Complete server configurations for supported games
- **Framework Definitions**: Modding framework specifications (Oxide, Carbon, etc.)
- **Plugin Definitions**: Plugin metadata and configuration schemas
- **Adapter Specifications**: Game-specific operations and path mappings

## Current Status

This is a **development registry** that's actively being expanded. Currently, we support:

- **Rust** - Full server configuration with Oxide and Carbon framework support

More games will be added as the registry grows.

## How It Works

The Astralis daemon consumes this registry through the following process:

1. **Fetch**: Automatically pulls the latest registry data from GitHub
2. **Parse**: Validates and parses YAML configuration files
3. **Cache**: Stores validated data locally for fast access
4. **Serve**: Uses cached data to:
   - Generate server configuration options
   - Validate plugin configurations
   - Provide framework installation instructions
   - Map game-specific operations (reloads, resource discovery, etc.)

All registry data is **read-only** from the daemon's perspective. The daemon never modifies registry files.

## Repository Structure

```
astralis-registries/
├── README.md              # This file
├── LICENSE                # License information
├── manifest.yml           # Registry manifest (spec version, compatibility)
├── index.yml              # Game registry index
├── schemas/               # JSON Schema validation files
│   ├── manifest.schema.json
│   ├── index.schema.json
│   ├── game.schema.json
│   ├── adapter.schema.json
│   ├── framework.schema.json
│   ├── plugin.schema.json
│   ├── action.schema.json
│   └── variables.schema.json
├── tools/                 # Validation and tooling scripts
│   └── validate.mjs      # Registry validation script
├── .github/
│   └── workflows/
│       └── validate.yml  # CI validation workflow
└── games/                 # Game definitions
    ├── rust/             # Rust game configuration
    │   ├── game.yml      # Game metadata and capabilities
    │   ├── adapter.yml   # Game-specific adapter configuration
    │   ├── frameworks/   # Supported frameworks
    │   │   ├── oxide.yml # Oxide framework definition
    │   │   └── carbon.yml # Carbon framework definition
    │   └── plugins/      # Available plugins
    │       └── gather-manager/
    │           ├── plugin.yml
    │           └── schema.yml
    └── cs2/              # Counter-Strike 2 game configuration
        ├── game.yml
        └── adapter.yml
```

## Contributing

This registry is designed to be extensible. To add a new game:

1. Create a new directory under `games/` with the game identifier
2. Add `game.yml` and `adapter.yml` files following the existing structure
3. Add framework definitions under `frameworks/` if applicable
4. Add plugin definitions under `plugins/` if available
5. Update `index.yml` to include the new game entry

## Registry Specification Contract

### Versioning

The registry uses a **specification version contract** defined in `manifest.yml`:

- **specVersion**: Registry specification version (major.minor format)
  - Breaking changes increment the major version
  - Non-breaking additions increment the minor version
- **registryVersion**: Content version (semantic versioning)
- **minDaemonVersion**: Minimum required Astralis daemon version

### Breaking Change Rules

Breaking changes that require a specVersion major bump:
- Removing required fields
- Changing field types
- Removing or renaming top-level keys
- Changing enum values
- Removing game definitions

Non-breaking changes (minor version bump):
- Adding optional fields
- Adding new games
- Adding new enum values
- Extending schemas with `x-*` extension keys

### Pinning Strategy

**For Production Use:**
- Pin to **Git tags/releases** for stability
- Tags follow semantic versioning (e.g., `v0.1.0`)
- Use specific tag: `registry@v0.1.0`

**For Development:**
- Use **branch names** (e.g., `main`, `develop`)
- Branch `main` is considered stable
- Branch `develop` may contain breaking changes

**Astralis Daemon Pinning:**
- Daemon should pin to a specific tag by default
- Configuration should allow branch pinning for development
- Daemon must validate `specVersion` compatibility
- If `specVersion` is incompatible, daemon should warn and refuse to load

### Schema Validation

All registry files are validated against JSON Schema:
- YAML syntax validation
- Schema compliance checks
- Referential integrity (games exist, frameworks referenced, etc.)
- CI runs validation on every push and PR

Run validation locally:
```bash
npm install
npm run validate
```

## Configuration Variables

Games in this registry define variables with UI metadata for panel form rendering:

- **Variables** include: label, description, group, restartRequired, isSecret
- **Groups**: General, Networking, World, Advanced
- **Types**: text, number, select, boolean, textarea, password
- **Validation**: Rules follow Laravel-style validation syntax

Common variables:
- `SERVER_IDENTITY`: Unique server identity folder name
- `SERVER_NAME`: Server display name
- `SERVER_PORT`: Game server port
- `MAX_PLAYERS`: Maximum concurrent players
- `MAP_SIZE`: Map size (for procedural maps)
- `MAP_SEED`: Map seed value

Path placeholders like `{IDENTITY}` or `{{identity}}` are replaced at runtime with the actual server identity value.

## License

See [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or contributions related to this registry, please refer to the Rustopic project documentation.

---

*This registry is maintained as part of the Rustopic game server management platform.*
