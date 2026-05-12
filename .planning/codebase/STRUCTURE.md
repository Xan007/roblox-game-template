---
last_mapped_commit: f2bd571
mapped_at: 2026-05-12
scope: full
focus: arch
---

# Codebase Structure

**Analysis Date:** 2026-05-12

## Directory Layout

```
roblox-game-template/
├── .pesde/                        # pesde package manager internals (gitignored)
│   └── scripts/                   # Build/sync scripts
│       ├── roblox_sync_config_generator.luau
│       └── sourcemap_generator.luau
├── .planning/                     # GSD planning documents
│   └── codebase/                  # Codebase analysis documents
├── lune_packages/                 # Dev tool binaries (gitignored, pesde-managed)
├── roblox_packages/               # Replicated packages (gitignored, pesde-managed)
├── roblox_server_packages/        # Server-only packages (gitignored, pesde-managed)
├── luau_packages/                 # Luau-only packages (gitignored, pesde-managed)
├── src/                           # 🔑 All game source code
│   ├── server/                    # Server-only code
│   │   ├── Data/                  # Data schemas and migrations
│   │   ├── Lib/                   # Server bootstrap
│   │   ├── Services/              # Game services
│   │   └── Stores/                # Reactive state stores
│   ├── client/                    # Client-only code
│   │   ├── Scripts/               # Client scripts
│   │   ├── Stores/                # Client-side state
│   │   └── UI/                    # UI management
│   └── shared/                    # Shared client/server code
│       ├── AudioManager/          # Sound registry and playback
│       ├── Hooks/                 # Lifecycle hooks
│       ├── Modules/               # Shared utility modules
│       ├── Remotes/               # Type-safe networking
│       └── TranslationHelper.luau # Localization helper
├── default.project.json           # Rojo project configuration
├── pesde.toml                     # Package manifest
├── pesde.lock                     # Package lockfile (gitignored)
├── rokit.toml                     # Toolchain config (rojo version)
├── selene.toml                    # Lua linter config
├── sourcemap.json                 # Rojo sourcemap (gitignored)
├── LICENSE.md                     # MIT license
└── README.md                     # Project readme
```

## Directory Purposes

**`src/server/`:**
- Purpose: Server-only game logic; reparented away from clients at runtime for security
- Contains: Services, data models, bootstrap, reactive stores
- Key files: `Lib/init.server.luau` (entry), `Services/DataService/init.luau`, `Services/CommandService/init.luau`
- **Important:** All code here is inaccessible to clients after initialization

**`src/server/Data/`:**
- Purpose: Data schema definitions and migration history
- Contains: `ProfileData.luau` (schema/template/leaderstats config), `Migrations.luau` (ordered migration list)
- Key files: `ProfileData.luau`, `Migrations.luau`

**`src/server/Lib/`:**
- Purpose: Server initialization and synchronization
- Contains: `init.server.luau` (bootstrap + security reparenting), `sync.server.luau` (CharmSync server setup)
- Key files: `init.server.luau`, `sync.server.luau`

**`src/server/Services/`:**
- Purpose: Game services following the Framework service pattern
- Contains: `DataService/` and `CommandService/` as directories with `init.luau` entry points
- Key files: `DataService/init.luau`, `DataService/PlayerStore.luau`, `DataService/Migration.luau`, `CommandService/init.luau`

**`src/server/Stores/`:**
- Purpose: Charm reactive state stores for server-side data
- Contains: `PlayerProfileStore.luau` (wraps ProfileStore sessions in Charm reactive)
- Key files: `PlayerProfileStore.luau`

**`src/client/`:**
- Purpose: Client-only game logic, UI, and state management
- Contains: Bootstrap, Scripts, Stores, UI
- Key files: `Bootstrap.client.luau`, `Scripts/Sync.client.luau`, `Stores/PlayerDataStore.luau`

**`src/client/Scripts/`:**
- Purpose: Client-side script modules that run independently
- Contains: `StartConchClient.client.luau` (command system), `Sync.client.luau` (data sync)
- Key files: `Sync.client.luau`, `StartConchClient.client.luau`

**`src/client/Stores/`:**
- Purpose: Client-side Charm reactive state
- Contains: `PlayerDataStore.luau` (client-side player data mirror)
- Key files: `PlayerDataStore.luau`

**`src/client/UI/`:**
- Purpose: UI management (currently a stub)
- Contains: `Manager/init.luau` (empty UIManager table)
- Key files: `Manager/init.luau`

**`src/shared/`:**
- Purpose: Code that runs on both client and server, placed in ReplicatedStorage
- Contains: Remotes, Hooks, AudioManager, Observers, TranslationHelper
- **Important:** Never put secrets or server-authoritative logic here — it replicates to clients

**`src/shared/Remotes/`:**
- Purpose: Type-safe networking abstraction and remote definitions
- Contains: `init.luau` (remote definitions), `lib.luau` (RemoteEvent/Function factory)
- Key files: `init.luau`, `lib.luau`

**`src/shared/Hooks/`:**
- Purpose: Lifecycle hooks that auto-select client/server environment
- Contains: `init.luau` (auto-loader), `OnPlayerAdded.luau`, `OnPlayerRemoving.luau`
- Key files: `init.luau`, `OnPlayerAdded.luau`, `OnPlayerRemoving.luau`

**`src/shared/AudioManager/`:**
- Purpose: Sound system with registry, builder, and SoundGroup management
- Contains: `init.luau` (manager), `Registry.luau` (sound definitions), `Util/create.luau` (builder)
- Key files: `init.luau`, `Registry.luau`, `Util/create.luau`

**`src/shared/Modules/`:**
- Purpose: Shared utility modules
- Contains: `Observers.luau` (typed observer pattern)
- Key files: `Observers.luau`

**`roblox_packages/`:**
- Purpose: Third-party packages available to both client and server
- Contains: Re-export modules for Charm, CharmSync, Signal, GreenTea, Sift, Framework, conch, conch_ui
- **Important:** Gitignored; managed by pesde. Each `.luau` file is a thin re-export wrapper.

**`roblox_server_packages/`:**
- Purpose: Server-only third-party packages
- Contains: ProfileStore re-export
- **Important:** Gitignored; managed by pesde. Reparented away from clients at runtime.

## Key File Locations

**Entry Points:**
- `src/server/Lib/init.server.luau`: Server bootstrap — loads Framework, services, reparents for security
- `src/server/Lib/sync.server.luau`: Server-side data synchronization setup
- `src/client/Bootstrap.client.luau`: Client bootstrap (currently minimal)
- `src/client/Scripts/Sync.client.luau`: Client-side data sync handler
- `src/client/Scripts/StartConchClient.client.luau`: Client-side command system startup

**Configuration:**
- `default.project.json`: Rojo project file mapping `src/` to ReplicatedStorage
- `pesde.toml`: Package manifest (dependencies, dev dependencies, build config)
- `rokit.toml`: Toolchain config (Rojo version)
- `selene.toml`: Linter config

**Core Logic:**
- `src/server/Services/DataService/init.luau`: Player data lifecycle (load, validate, sync, release)
- `src/server/Services/DataService/PlayerStore.luau`: ProfileStore wrapper with type export
- `src/server/Services/DataService/Migration.luau`: Migration engine
- `src/server/Data/ProfileData.luau`: Data schema, template, replication rules, leaderstats config
- `src/server/Data/Migrations.luau`: Migration definitions list
- `src/server/Stores/PlayerProfileStore.luau`: Charm reactive wrapper for player profiles
- `src/shared/Remotes/lib.luau`: Type-safe RemoteEvent/Function factory
- `src/shared/Modules/Observers.luau`: Generic observer pattern implementation

**Shared Utilities:**
- `src/shared/AudioManager/Registry.luau`: Sound definitions registry
- `src/shared/AudioManager/Util/create.luau`: Fluent builder for sound configs
- `src/shared/TranslationHelper.luau`: Localization with fallback

**Testing:**
- No test files detected in the repository

## Naming Conventions

**Files:**
- `init.luau`: Directory entry point module (e.g., `Services/DataService/init.luau`)
- `init.server.luau`: Server-only entry point (e.g., `src/server/Lib/init.server.luau`)
- `.client.luau`: Client-only script suffix (e.g., `Bootstrap.client.luau`, `Sync.client.luau`)
- `.server.luau`: Server-only script suffix (e.g., `sync.server.luau`)
- `PascalCase.luau`: Module files (e.g., `Migration.luau`, `ProfileData.luau`, `Observers.luau`)

**Directories:**
- `PascalCase`: Feature directories (e.g., `DataService/`, `CommandService/`, `AudioManager/`)
- `PascalCase` plural for groups: `Services/`, `Stores/`, `Scripts/`, `Modules/`
- `Util/`: Utility subdirectories within feature modules

**Variables and Functions:**
- `PascalCase` for services, modules, and classes (e.g., `DataService`, `PlayerStore`, `ProfileData`)
- `camelCase` for local variables and function names (e.g., `getPlayerData`, `noYield`, `deepAssign`)
- `UPPER_SNAKE_CASE` for constants (not currently present but follows Luau convention)

**Types:**
- `PascalCase` for exported types (e.g., `PlayerProfile`, `Schema`, `Observer`, `SoundNames`)
- Type definitions co-located with implementations using `export type`

## Where to Add New Code

**New Server Service:**
- Create directory: `src/server/Services/{ServiceName}/`
- Create entry: `src/server/Services/{ServiceName}/init.luau`
- Service must be a table with lifecycle methods: `Init()`, `Start()`, `OnPlayerAdded()`, `OnPlayerRemoving()`
- The Framework.Add() call in `src/server/Lib/init.server.luau` auto-discovers services in the Services folder

**New Data Field:**
- Add to schema: `src/server/Data/ProfileData.luau` (add to `schema` and `template`)
- Add replication rule: Update `replicateSchema` in same file (set to `true` to replicate to clients)
- Add leaderstat config: Add to `leaderstats` table in same file (optional)
- Add migration: Add entry to `src/server/Data/Migrations.luau`

**New Client Store:**
- Create file: `src/client/Stores/{StoreName}.luau`
- Use Charm reactive: `Charm.reactive({...})` or `Charm.computed(...)` for derived values
- Sync from server: Add signal in `src/server/Lib/sync.server.luau`

**New Remote Event:**
- Define in: `src/shared/Remotes/init.luau`
- Use `lib.event()` for RemoteEvent, `lib.unreliableEvent()` for UnreliableRemoteEvent, `lib.callback()` for RemoteFunction
- Add GreenTea type schema arguments to validate payloads
- Fire server→client: `Remotes.{name}:FireClient(player, ...)`
- Fire client→server: `Remotes.{name}:FireServer(...)`
- Listen server: `Remotes.{name}.OnServerEvent:Connect(function(player, ...) ... end)`
- Listen client: `Remotes.{name}.OnClientEvent:Connect(function(...) ... end)`

**New Hook:**
- Create file: `src/shared/Hooks/{HookName}.luau`
- Must return table with: `{ Name, IsClient, IsServer, Hook, Init }`
- Hook registered via `Framework.Hook("HookName")`
- Auto-loaded by `src/shared/Hooks/init.luau`

**New Sound:**
- Add to: `src/shared/AudioManager/Registry.luau`
- Add category entry or append to existing category
- Use builder pattern: `create().fromId(id).volume(v).looped(l).build()`
- Optionally add new SoundGroup to `SoundGroups` and category-to-group mapping

**New Observer:**
- Use existing: `src/shared/Modules/Observers.luau` provides `observePlayers`, `observeTag`, `observeCharacter`, `observeChildWhichIsA`
- Create custom: Use `createObserver(setup)` for new observer types

**New Migration:**
- Append to: `src/server/Data/Migrations.luau`
- Format: `{ migrate = function(old) ... return old end, backwardsCompatible = true/false }`
- Migrations are applied sequentially based on array position

**New Package Dependency:**
- Add to: `pesde.toml` under `[dependencies]` (replicated) or server deps
- Run: `pesde install` to download
- Package appears in `roblox_packages/` (replicated) or `roblox_server_packages/` (server-only)
- Re-export in `roblox_packages/{Name}.luau` if needed (pesde auto-generates)

## Special Directories

**`.pesde/`:**
- Purpose: Package manager scripts and internal data
- Generated: Yes (by pesde)
- Committed: No (gitignored)

**`lune_packages/`:**
- Purpose: Dev tool binaries (Rojo, StyLua, Selene, Luau LSP)
- Generated: Yes (by pesde)
- Committed: No (gitignored)

**`roblox_packages/`:**
- Purpose: Runtime packages replicated to all clients
- Generated: Yes (by pesde)
- Committed: No (gitignored)
- Contains: Charm, CharmSync, Signal, GreenTea, Sift, Framework, conch, conch_ui

**`roblox_server_packages/`:**
- Purpose: Server-only runtime packages
- Generated: Yes (by pesde)
- Committed: No (gitignored)
- Contains: ProfileStore
- **Security:** Reparented into a Camera instance at runtime to prevent client access

**`luau_packages/`:**
- Purpose: Luau-only packages (not Roblox runtime)
- Generated: Yes (by pesde)
- Committed: No (gitignored)

---

*Structure analysis: 2026-05-12*