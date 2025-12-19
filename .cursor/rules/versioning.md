# Versioning Rules

## Scope
These rules apply to all repositories in this project unless explicitly overridden.

## Versioning Policy
- The project MUST use Semantic Versioning.
- During active development, versions MUST remain in the `0.x.y` range.
- The initial development version is `0.1.0`.

## When to Bump Versions
- Increment PATCH (`0.1.y`) for:
  - Bug fixes
  - Non-breaking internal changes
  - Documentation-only changes

- Increment MINOR (`0.x.0`) for:
  - Backward-compatible feature additions
  - Configuration or registry extensions that do not break existing setups

- Increment MINOR when introducing breaking changes during `0.x` development.
  - MAJOR version increments are not required before `1.0.0`.

## Pre-release Identifiers
- Use pre-release suffixes when the version is not production-ready:
  - `-alpha.N`
  - `-beta.N`
  - `-rc.N`
- Pre-release identifiers MUST be removed before a stable release.

## Release Policy
- A public release does NOT require a `1.0.0` version.
- Version `1.0.0` MUST only be used when APIs, configuration formats, and behaviors are considered stable.

## Repository Types
- Code repositories (panel, agent, services) MUST maintain independent versions.
- Registry/data repositories MUST bump versions when schema or structure changes occur.

## Enforcement
- Any change that modifies public APIs, configuration schemas, or registries MUST include a version bump.
