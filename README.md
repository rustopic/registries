# Astralis Game Registry

This repository serves as a centralized registry for game server configurations, frameworks, and plugins consumed by the Astralis game server management daemon.

## Purpose

This registry is a **data-only** repository that provides:
- Game server definitions and configurations
- Framework definitions and compatibility information
- Plugin metadata and configuration schemas
- Adapter specifications for game-specific operations

The Astralis daemon automatically fetches and caches this registry from GitHub to provide game server management capabilities.

## Development Status

⚠️ **This is a development registry repository.**

Currently, this registry contains configurations for development and testing purposes. The structure is designed to be production-ready and extensible for future game additions.

## How Astralis Consumes This Registry

1. **Fetch**: The daemon fetches this repository from GitHub (via HTTPS or Git protocol)
2. **Parse**: YAML files are parsed and validated against expected schemas
3. **Cache**: Validated data is cached locally for performance
4. **Serve**: Cached registry data is used to:
   - Generate server configuration options
   - Validate plugin configurations
   - Provide framework installation instructions
   - Map game-specific operations (reloads, resource discovery, etc.)

The daemon **does not modify** registry files. All registry data is read-only from the daemon's perspective.

## Repository Structure

```
astralis-registries/
├── README.md              # This file
├── index.yml              # Game registry index
├── games/                 # Game definitions
│   └── rust/             # Rust game configuration
│       ├── game.yml      # Game metadata and capabilities
│       ├── adapter.yml   # Game-specific adapter configuration
│       ├── frameworks/   # Supported frameworks
│       └── plugins/      # Available plugins
```

## Adding New Games

To add a new game to the registry:

1. Create a new directory under `games/` with the game identifier
2. Add `game.yml` and `adapter.yml` files
3. Add framework definitions under `frameworks/`
4. Add plugin definitions under `plugins/`
5. Update `index.yml` to include the new game

## License

This registry is maintained for use with the Astralis daemon. Configuration schemas and metadata follow standard conventions for game server management.

