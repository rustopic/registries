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
├── index.yml              # Game registry index
├── games/                 # Game definitions
│   └── rust/             # Rust game configuration
│       ├── game.yml      # Game metadata and capabilities
│       ├── adapter.yml   # Game-specific adapter configuration
│       ├── frameworks/   # Supported frameworks
│       │   ├── oxide.yml # Oxide framework definition
│       │   └── carbon.yml # Carbon framework definition
│       └── plugins/      # Available plugins
│           └── gather-manager/
│               ├── plugin.yml
│               └── schema.yml
```

## Contributing

This registry is designed to be extensible. To add a new game:

1. Create a new directory under `games/` with the game identifier
2. Add `game.yml` and `adapter.yml` files following the existing structure
3. Add framework definitions under `frameworks/` if applicable
4. Add plugin definitions under `plugins/` if available
5. Update `index.yml` to include the new game entry

## Configuration Variables

Games in this registry use environment variables for configuration. Common variables include:

- `SERVER_IDENTITY`: Unique server identity folder name
- `HOSTNAME`: Server display name
- `SERVER_PORT`: Game server port
- `MAX_PLAYERS`: Maximum concurrent players
- `BRANCH`: Steam beta branch (staging, aux01, aux02, aux03)

Path placeholders like `{IDENTITY}` are replaced at runtime with the actual server identity value.

## License

See [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or contributions related to this registry, please refer to the Rustopic project documentation.

---

*This registry is maintained as part of the Rustopic game server management platform.*
