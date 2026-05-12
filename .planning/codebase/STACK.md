---
last_mapped_commit: f2bd571
mapped_at: 2026-05-12
scope: full
focus: tech
---

# Technology Stack

**Analysis Date:** 2026-05-12

## Languages

**Primary:**
- Luau — Roblox's typed Lua variant, used for all game logic, services, client scripts, and shared modules. All source files use `.luau` extension.

**Secondary:**
- JSON — Used for Rojo project configuration (`default.project.json`) and sourcemap (`sourcemap.json`).
- TOML — Used for package manager config (`pesde.toml`, `rokit.toml`, `selene.toml`).

## Runtime

**Environment:**
- Roblox — The target platform. All `.luau` code runs inside the Roblox engine (client and server contexts).
- Lune — Standalone Luau runtime (v0.10.4) used for build/dev scripts (sourcemap generation, Rojo sync config).

**Package Manager:**
- pesde (v0.7.1+) — Primary package manager, manages both Roblox and Lune-targeted dependencies
- Lockfile: `pesde.lock` present (gitignored)
- rokit — Toolchain manager for Rojo, defined in `rokit.toml`

**Indices:**
- pesde index: `https://github.com/pesde-pkg/index` (default)
- wally index: `https://github.com/UpliftGames/wally-index` (default)

## Frameworks

**Core:**
- lumin/framework v11.0.0 — Service/module lifecycle framework (init/start pattern). Used as the backbone for server-side service orchestration.
  - Entry: `src/server/Lib/init.server.luau` calls `framework.Add()` and `framework.Start()`

**State Management:**
- littensy/charm v0.11.0-rc.4 — Reactive state management library. Used for creating reactive data stores on both client and server.
  - Server-side profile store: `src/server/Stores/PlayerProfileStore.luau`
  - Client-side data: `src/client/Stores/PlayerDataStore.luau`
- littensy/charm-sync v0.4.0-rc.6 — Client-server state synchronization for Charm. Syncs reactive state between server and client via RemoteEvents.
  - Server sync: `src/server/Lib/sync.server.luau`
  - Client sync: `src/client/Scripts/Sync.client.luau`

**Command Framework:**
- alicesaidhi/conch v0.4.0-rc.6 — Admin command framework
  - Server registration: `src/server/Services/CommandService/init.luau`
  - Client UI: `src/client/Scripts/StartConchClient.client.luau`
- alicesaidhi/conch_ui v0.4.0-rc.6 — UI bindings for Conch command console

**Data Persistence:**
- lm-loleris/profilestore v1.0.3 — Roblox DataStore wrapper for player data profiles with session locking
  - Store creation: `src/server/Services/DataService/PlayerStore.luau`
  - Session management: `src/server/Services/DataService/init.luau`

## Key Dependencies

**Critical:**
- Signal (sleitnick/signal v2.0.3) — Event/signal library used for custom event dispatching (e.g., `DataService.ProfileLoaded` signal)
- GreenTea (corecii/greentea v0.4.11) — Type validation and runtime type-checking library. Used for:
  - Remote event argument validation in `src/shared/Remotes/lib.luau`
  - Schema validation of player profile data in `src/server/Data/ProfileData.luau`
  - Type casting in `src/server/Services/DataService/init.luau`
- Sift (csqrl/sift v0.0.11) — Utility library (declared, available for use)
- lumin/debugger v1.0.3 — Debug utility (transitive dependency of lumin/framework)

**Build/Dev:**
- Rojo v7.7.0-rc.1 — File-to-Instance sync tool for Roblox Studio. Syncs `src/` directory into the Roblox DataModel.
  - Config: `default.project.json`
- luau-lsp v1.62.0 — Language server for Luau type checking and IntelliSense
- StyLua v2.3.1 — Code formatter for Luau
- selene v0.30.0 — Linting tool for Luau/Lua
  - Config: `selene.toml` (uses `selene_definitions` std)
- pesde/scripts_rojo v0.2.0 — Build scripts for Rojo integration (generates sourcemap and sync config)

## Configuration

**Environment:**
- Roblox game context (client/server split enforced by `.client.luau` / `.server.luau` file suffixes)
- Server-only packages placed in `roblox_server_packages/` (not replicated to clients)
- Shared/client packages placed in `roblox_packages/` (replicated via ReplicatedStorage)

**Build:**
- `default.project.json` — Rojo project definition. Maps `src/` tree to Roblox DataModel hierarchy under `ReplicatedStorage.src`
- `pesde.toml` — Package manifest. Defines dependencies, dev dependencies, engine requirements, and build scripts
- `rokit.toml` — Tool version management. Currently pins `rojo = "rojo-rbx/rojo@7.7.0-rc.1"`
- `selene.toml` — Linter config: `std = "selene_definitions"`
- `.pesde/scripts/` — Contains `roblox_sync_config_generator.luau` and `sourcemap_generator.luau` (not committed, listed in `.gitignore`)

**Key Config Details:**
- `pesde.toml` declares `environment = "roblox"` and `build_files = ["src"]`
- Lune engine requirement: `^0.10.4`
- Pesde engine requirement: `^0.7.1`

## Platform Requirements

**Development:**
- pesde package manager (v0.7.1+)
- Lune runtime (v0.10.4+) for running build scripts
- rokit for tool installation (Rojo, etc.)
- Roblox Studio with Rojo plugin for live sync
- luau-lsp for IDE integration

**Production:**
- Roblox platform — Game runs as a Roblox experience
- DataStore API access (used via ProfileStore for player data persistence)
- No external hosting required (Roblox-hosted)

---

*Stack analysis: 2026-05-12*