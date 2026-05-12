---
last_mapped_commit: f2bd571
mapped_at: 2026-05-12
scope: full
focus: arch
---

<!-- refreshed: 2026-05-12 -->
# Architecture

**Analysis Date:** 2026-05-12

## System Overview

```text
┌────────────────────────────────────────────────────────────────────────┐
│                     Shared Layer (ReplicatedStorage)                    │
│  `src/shared/` — Runs on both Client & Server                         │
├──────────────┬──────────────────┬──────────────────┬───────────────────┤
│ Remotes      │   Hooks          │  AudioManager     │  Observers       │
│ `Remotes/`   │   `Hooks/`       │  `AudioManager/`  │  `Modules/`      │
└──────┬───────┴────────┬─────────┴─────────┬─────────┴────────┬──────────┘
       │                │                   │                  │
       ▼                ▼                   ▼                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        Server Layer                                     │
│  `src/server/` — Server-only, reparented to non-replicated instance    │
├──────────────────┬────────────────────┬────────────────┬───────────────┤
│   DataService     │  CommandService     │  Data Schema   │  Stores      │
│ `Services/DataService/`│`Services/CommandService/`│ `Data/` │ `Stores/`  │
└────────┬─────────┴──────────┬─────────┴────────┬────────┴───────┬──────┘
         │                    │                  │                │
         ▼                    ▼                  ▼                ▼
┌────────────────────────────────────────────────────────────────────────┐
│  Client Layer                                                           │
│  `src/client/` — Client-only                                           │
├───────────────────┬──────────────────┬────────────────────────────────┤
│  Bootstrap         │  Scripts/Sync     │  Stores                       │
│  `Bootstrap.client.luau`│ `Scripts/`  │  `Stores/`                    │
└───────────────────┴──────────────────┴────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────────────────────────┐
│  External Packages (ReplicatedStorage)                                  │
│  `roblox_packages/` — Client + Server   `roblox_server_packages/`      │
│  Charm, CharmSync, Signal, GreenTea, Sift, Framework, conch, conch_ui  │
│  ProfileStore (server-only)                                             │
└────────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| **DataService** | Player data persistence, profile loading/releasing, migration dispatch, type-checking | `src/server/Services/DataService/init.luau` |
| **CommandService** | Admin command system initialization via conch | `src/server/Services/CommandService/init.luau` |
| **PlayerStore** | ProfileStore wrapper, exports `PlayerProfile` type | `src/server/Services/DataService/PlayerStore.luau` |
| **PlayerProfileStore** | Charm reactive store for online player profiles, wraps/references ProfileStore sessions | `src/server/Stores/PlayerProfileStore.luau` |
| **ProfileData** | Schema definition, default template, replication rules, leaderstats config | `src/server/Data/ProfileData.luau` |
| **Migrations** | Ordered list of data migration functions with backwards compatibility metadata | `src/server/Data/Migrations.luau` |
| **Migration** | Migration engine: applies forward migrations, validates backwards compatibility | `src/server/Services/DataService/Migration.luau` |
| **Remotes** | Type-safe RemoteEvent/RemoteFunction factory and `patch` event for CharmSync | `src/shared/Remotes/init.luau`, `src/shared/Remotes/lib.luau` |
| **Hooks** | Lifecycle hooks (OnPlayerAdded, OnPlayerRemoving) auto-registered per environment | `src/shared/Hooks/init.luau` |
| **OnPlayerAdded** | Framework Hook that fires on player join (handles existing players too) | `src/shared/Hooks/OnPlayerAdded.luau` |
| **OnPlayerRemoving** | Framework Hook that fires on player leave | `src/shared/Hooks/OnPlayerRemoving.luau` |
| **Observers** | Generic observer pattern (observePlayers, observeTag, observeCharacter, observeChildWhichIsA) | `src/shared/Modules/Observers.luau` |
| **AudioManager** | Sound registry, builder pattern for sound config, SoundGroup management | `src/shared/AudioManager/init.luau`, `AudioManager/Registry.luau` |
| **TranslationHelper** | Localization helper with fallback translator | `src/shared/TranslationHelper.luau` |
| **Server Init** | Framework bootstrap, service loading, reparents server code away from clients | `src/server/Lib/init.server.luau` |
| **Sync (Server)** | CharmSync server — adds reactive signal per player, pushes patches via Remotes | `src/server/Lib/sync.server.luau` |
| **Sync (Client)** | CharmSync client — receives patches, deep-assigns into local PlayerDataStore | `src/client/Scripts/Sync.client.luau` |
| **PlayerDataStore** | Client-side Charm reactive state for player data (xp, coins) | `src/client/Stores/PlayerDataStore.luau` |
| **UIManager** | Placeholder for UI management (empty shell) | `src/client/UI/Manager/init.luau` |
| **Admins** | Admin user ID list (defaults to game creator) | `src/server/Services/CommandService/admins.luau` |

## Pattern Overview

**Overall:** Service-Oriented Architecture with Reactive State Management

**Key Characteristics:**
- **Framework-driven services** — Server code organized as services with `Init`/`Start`/`OnPlayerAdded` lifecycle methods, loaded by Lumin Framework
- **Reactive data layer** — Charm (reactive signals + computed) for both server-side profile state and client-side player data; CharmSync bridges server↔client
- **Observer pattern** — Custom `Observers` module (`src/shared/Modules/Observers.luau`) gives typed cleanup-returning observers for players, tags, characters, and children
- **Data migration system** — Ordered migration list with backwards compatibility tracking and dual-direction validation
- **Type-safe networking** — GreenTea-powered remote schema validation in `lib.luau` with assert-and-build pattern
- **Builder pattern** — Audio registry uses a fluent builder (`create().fromId().volume().looped().build()`) for sound configuration
- **Hooks system** — Shared hooks auto-select client/server environment and initialize via Framework's Hook API

## Layers

**Shared Layer (`src/shared/`):**
- Purpose: Code that runs on both client and server, placed in ReplicatedStorage
- Location: `src/shared/`
- Contains: Remotes, Hooks, AudioManager, Observers, TranslationHelper
- Depends on: `roblox_packages/` (Charm, GreenTea, Signal, Framework)
- Used by: Both server and client layers

**Server Layer (`src/server/`):**
- Purpose: Server-only game logic, data persistence, command handling
- Location: `src/server/`
- Contains: Services, Data schemas, Stores, Bootstrap
- Depends on: Shared layer, `roblox_packages/`, `roblox_server_packages/` (ProfileStore)
- Used by: Cannot be accessed by clients (reparented at runtime)
- **Critical:** `src/server/Lib/init.server.luau` reparents the entire `server` folder and `roblox_server_packages` into a Camera instance to prevent client access

**Client Layer (`src/client/`):**
- Purpose: Client-side state, UI, input handling
- Location: `src/client/`
- Contains: Bootstrap, Scripts, Stores, UI Manager
- Depends on: Shared layer, `roblox_packages/`
- Used by: Player connections only

**Packages Layer (`roblox_packages/` and `roblox_server_packages/`):**
- Purpose: Third-party dependencies managed by pesde
- Location: `roblox_packages/` (replicated), `roblox_server_packages/` (server-only)
- Contains: Charm, CharmSync, Signal, GreenTea, Sift, Framework, conch, conch_ui, ProfileStore
- Depends on: Managed externally via `pesde.toml`
- Used by: All game code

## Data Flow

### Primary Request Path: Player Data Loading

1. Player joins → Framework Hook `OnPlayerAdded` fires (`src/shared/Hooks/OnPlayerAdded.luau`)
2. DataService.OnPlayerAdded receives the player (`src/server/Services/DataService/init.luau:132`)
3. ProfileStore loads/creates profile via `PlayerStore:StartSessionAsync()` (`src/server/Services/DataService/init.luau:134`)
4. Migrations applied via `Migration.migrate()` (`src/server/Services/DataService/Migration.luau:33`)
5. Type-checking via GreenTea schema (`src/server/Services/DataService/init.luau:174`)
6. Profile wrapped in Charm reactive via `PlayerProfileStore.wrapProfile()` (`src/server/Stores/PlayerProfileStore.luau:10`)
7. DataService.ProfileLoaded signal fires (`src/server/Services/DataService/init.luau:177`)
8. Leaderstats created from ProfileData config (`src/server/Services/DataService/init.luau:28-49`)

### Data Replication Path: Server → Client Sync

1. sync.server runs: `CharmSync.server.addSignalsToClient()` creates a computed signal per player (`src/server/Lib/sync.server.luau:11-28`)
2. Signal computes player data, filters by `ProfileData.replicateSchema` (`src/server/Lib/sync.server.luau:21-24`)
3. Observers.observePlayers connects player lifecycle (`src/server/Lib/sync.server.luau:39-45`)
4. CharmSync server.connect sends patches to specific client via Remotes.patch (`src/server/Lib/sync.server.luau:35-37`)
5. Client receives patches via `Remotes.patch.OnClientEvent` (`src/client/Scripts/Sync.client.luau:31-32`)
6. `client.patch()` applies diffs to local state
7. PlayerDataStore updates, UI can react via Charm computed (`src/client/Stores/PlayerDataStore.luau:15-17`)

### Player Disconnect Path

1. Framework Hook `OnPlayerRemoving` fires (`src/shared/Hooks/OnPlayerRemoving.luau`)
2. DataService.OnPlayerRemoving runs pre-release callbacks (`src/server/Services/DataService/init.luau:180-196`)
3. Type-checking performed on final data (`src/server/Services/DataService/init.luau:193`)
4. Profile session ended, player removed from reactive store (`src/server/Services/DataService/init.luau:194-195`)
5. CharmSync server.removeClient cleans up (`src/server/Lib/sync.server.luau:31-33`)

**State Management:**
- Server: ProfileStore (persistent) wraps into Charm reactive (`PlayerProfileStore.profiles`) for in-memory access
- Client: `PlayerDataStore` uses Charm reactive state, updated via CharmSync patches from server
- Both: Charm computed properties for derived values (leaderstats, etc.)

## Key Abstractions

**Service Pattern:**
- Purpose: Encapsulate server-side game subsystems with lifecycle methods
- Examples: `src/server/Services/DataService/init.luau`, `src/server/Services/CommandService/init.luau`
- Pattern: Plain table with ordered methods (`Init`, `Start`, `OnPlayerAdded`, `OnPlayerRemoving`); loaded and called by Lumin Framework

**Hook Pattern:**
- Purpose: Cross-cutting lifecycle events that run in correct environment (client/server)
- Examples: `src/shared/Hooks/OnPlayerAdded.luau`, `src/shared/Hooks/OnPlayerRemoving.luau`
- Pattern: Module returns table with `Name`, `IsClient`, `IsServer`, `Hook`, `Init` fields; auto-loaded by `src/shared/Hooks/init.luau` which skips modules not matching current environment

**Observer Pattern:**
- Purpose: Resource lifecycle management with automatic cleanup
- Examples: `src/shared/Modules/Observers.luau`
- Pattern: Factory functions (`observePlayers`, `observeTag`, `observeCharacter`, `observeChildWhichIsA`) that return cleanup functions; callback can return a cleanup function for teardown

**Migration Pattern:**
- Purpose: Evolve persistent data schema over time
- Examples: `src/server/Data/Migrations.luau`, `src/server/Services/DataService/Migration.luau`
- Pattern: Migrations are ordered array of tables `{ migrate = fn, backwardsCompatible = bool }`; engine applies sequenced transforms and tracks version compatibility

**Builder Pattern (Audio):**
- Purpose: Declaratively define sound configurations
- Examples: `src/shared/AudioManager/Util/create.luau`, `src/shared/AudioManager/Registry.luau`
- Pattern: `create(id?)` returns a builder with fluent methods `.fromId()`, `.url()`, `.volume()`, `.looped()`, `.build()`; registry maps categories → sounds

**Type-Safe Remote Pattern:**
- Purpose: Roblox networking with runtime type validation
- Examples: `src/shared/Remotes/lib.luau`, `src/shared/Remotes/init.luau`
- Pattern: Factory functions (`lib.event()`, `lib.unreliableEvent()`, `lib.callback()`) create RemoteEvent/RemoteFunction instances; `lib.assert()` validates payloads against GreenTea schemas

## Entry Points

**Server Bootstrap:**
- Location: `src/server/Lib/init.server.luau`
- Triggers: Rojo sync / game server start
- Responsibilities: Requires shared hooks and AudioManager, registers services with Framework, calls `framework.Start()`, reparents server code to a Camera instance for security

**Client Bootstrap:**
- Location: `src/client/Bootstrap.client.luau`
- Triggers: Player loads
- Responsibilities: Currently only requires AudioManager (placeholder)

**Conch Client Bootstrap:**
- Location: `src/client/Scripts/StartConchClient.client.luau`
- Triggers: Player loads
- Responsibilities: Initializes conch command system and binds UI toggle to F4

**Data Sync (Server):**
- Location: `src/server/Lib/sync.server.luau`
- Triggers: Server start (required by init.server.luau indirectly via Framework)
- Responsibilities: Sets up CharmSync server, creates per-player computed signals, connects remote patch events, observes player lifecycle

**Data Sync (Client):**
- Location: `src/client/Scripts/Sync.client.luau`
- Triggers: Client loads
- Responsibilities: Sets up CharmSync client, connects remote patch receiver, deep-assigns data into PlayerDataStore

## Architectural Constraints

- **Threading:** Single-threaded (Roblox Lua coroutine model). DataService uses `noYield` wrappers to prevent yielding inside profile callbacks.
- **Global state:** `PlayerProfileStore.profiles` is a Charm reactive singleton; `PlayerStore` is a ProfileStore singleton; `Remotes` module creates instances in `script` Parent.
- **Circular imports:** Potential circular dependency between DataService → PlayerProfileStore → DataService/PlayerStore. DataService imports PlayerProfileStore; PlayerProfileStore imports PlayerStore (from DataService directory). This is acceptable because Luau caches module requires.
- **Security:** Server code is explicitly reparented away from ReplicatedStorage to prevent client access (`init.server.luau:23-44`). `roblox_server_packages` gets same treatment.
- **Environment gating:** Shared hooks use `RunService:IsClient()`/`IsServer()` to skip modules not matching current environment. Remotes module uses `IS_CLIENT`/`IS_SERVER`/`IS_TEST` to create vs. wait for instances.
- **Data ownership:** Server is authoritative for all player data. Client receives patches only for fields marked `true` in `ProfileData.replicateSchema`.

## Anti-Patterns

### Direct require of `@self` for sibling modules

**What happens:** DataService uses `require("@self/PlayerStore")` and `require("@self/Migration")` which depends on pesde path aliasing and doesn't work with standard Roblox require paths.
**Why it's wrong:** This only works when built through pesde's toolchain. It breaks if modules are loaded directly in Roblox Studio without the build step.
**Do this instead:** Use relative path requires (e.g., `require(script.Parent.PlayerStore)`) which work both with pesde and natively in Studio. This is actually the pattern used in other files like `Migration.luau` and `ProfileData.luau`, so be consistent.

### Client Data Mutation Without Validation

**What happens:** `src/client/Scripts/Sync.client.luau` deep-assigns server patches directly into `PlayerDataStore.playerData` without validating the data structure.
**Why it's wrong:** While the server is authoritative, corrupted or unexpected patch data could cause client-side errors in charm computed properties.
**Do this instead:** Add a validation step before deep-assigning, or use Charm's built-in patch mechanism exclusively (which `client.patch()` already does — the manual `deepAssign` in the signal handler is redundant with the `client.patch` receiver).

### Bootstrap.client.luau is a placeholder

**What happens:** `src/client/Bootstrap.client.luau` only requires AudioManager; client Scripts load independently.
**Why it's wrong:** No centralized client initialization — each script is a separate `.client.luau` file that runs independently.
**Do this instead:** Centralize client initialization in Bootstrap.client.luau requiring Sync and other client scripts, or document that client scripts are independently-launched modules.

## Error Handling

**Strategy:** Defense-in-depth with type-checking and yield protection

**Patterns:**
- `noYield` wrapper: Wraps callbacks to prevent yielding inside ProfileStore callbacks (`src/server/Services/DataService/init.luau:52-65`)
- GreenTea type-checking: Validates profile data against schema before and after modifications (`src/server/Services/DataService/init.luau:67-77, 174, 193`)
- Migration safety: `pcall` wraps each migration function; returns error on nil result (`src/server/Services/DataService/Migration.luau:58-65`)
- Player kick on critical failure: Profile load failure or migration failure kicks the player with a descriptive message (`src/server/Services/DataService/init.luau:142, 152-154`)
- Observer error handling: `xpcall` wraps observer callbacks with error capture and warning (`src/shared/Modules/Observers.luau:28-54`)
- `RegisterBeforeProfileRelease`: Allows services to register cleanup callbacks before profile release with error isolation (`src/server/Services/DataService/init.luau:199-201, 183-190`)

## Cross-Cutting Concerns

**Logging:** Minimal logging. `warn()` used for profile type-check failures, observer errors, and audio manager warnings. No structured logging framework.

**Validation:** GreenTea schema validation on profile data at load and save. Migration's `pcall` wrapping catches runtime errors in migration functions. Client-only data is not validated (trusts server).

**Authentication:** Roblox platform-managed. Admin detection uses `game.CreatorId` via `src/server/Services/CommandService/admins.luau`. No custom auth.

**Networking:** All client-server communication goes through the type-safe Remotes abstraction (`src/shared/Remotes/`). CharmSync patches are the primary data replication mechanism. Conch handles command networking.

**Localization:** `src/shared/TranslationHelper.luau` provides `translate()` and `translateByKey()` with fallback translator pattern. Client-only.

---

*Architecture analysis: 2026-05-12*