---
last_mapped_commit: f2bd571
mapped_at: 2026-05-12
scope: full
focus: tech
---

# External Integrations

**Analysis Date:** 2026-05-12

## APIs & External Services

**Roblox Platform APIs:**
- DataStore API — Used via ProfileStore for persistent player data storage
  - SDK/Client: `ProfileStore` (lm-loleris/profilestore v1.0.3) loaded from `roblox_server_packages/ProfileStore`
  - Store name: `"PlayerStore"` (defined in `src/server/Services/DataService/PlayerStore.luau`)
  - Auth: Handled by Roblox engine (no manual credentials)
- DataStore API — Used directly by ProfileStore internally for session-locked data operations

- LocalizationService API — Roblox's built-in localization system
  - Implementation: `src/shared/TranslationHelper.luau`
  - Functions: `GetTranslatorForPlayerAsync`, `GetTranslatorForLocaleAsync`
  - Source language: `"en"`

- Players Service — Roblox's built-in player management
  - Auth: Automatic by Roblox engine
  - Used in: `src/shared/Hooks/OnPlayerAdded.luau`, `src/shared/Hooks/OnPlayerRemoving.luau`, `src/shared/Modules/Observers.luau`

- CollectionService — Roblox's tag-based instance management
  - Used in: `src/shared/Modules/Observers.luau` for `observeTag`

- SoundService — Roblox's audio service
  - Used in: `src/shared/AudioManager/init.luau` for sound group and instance creation
  - Sound references: `rbxassetid://` IDs (e.g., `9111`, `1111`)

## Data Storage

**Databases:**
- Roblox DataStore (via ProfileStore)
  - Connection: Automatic via Roblox engine API
  - Client library: `ProfileStore` (`roblox_server_packages/ProfileStore`)
  - Store key pattern: `Player_{userId}` (defined in `src/server/Services/DataService/init.luau` line 80)
  - Template data structure set in `src/server/Data/ProfileData.luau`:
    ```luau
    {
        xp = 0,
        coins = 0,
        migrationVersion = 0,
        lastCompatibleVersion = 0,
    }
    ```
  - Schema validation: GreenTea type-checking (`src/server/Data/ProfileData.luau`)
  - Migration system: `src/server/Data/Migrations.luau` + `src/server/Services/DataService/Migration.luau`

**File Storage:**
- Local filesystem only (Roblox game instance hierarchy)
- No external file storage services

**Caching:**
- In-memory reactive state via Charm (`src/server/Stores/PlayerProfileStore.luau`, `src/client/Stores/PlayerDataStore.luau`)
- ProfileStore session-based caching with auto-save

## Authentication & Identity

**Auth Provider:**
- Roblox Platform — Player identity is handled entirely by the Roblox engine
  - Implementation: Implicit via `Players` service; `player.UserId` used as the primary key
  - Admin identification: Game creator's `CreatorId` is auto-granted super-user role
  - Admin list: `src/server/Services/CommandService/admins.luau` returns `{game.CreatorId}`
  - No custom auth or external identity provider

## Networking (Client-Server Communication)

**RemoteEvent System:**
- Custom typed wrapper in `src/shared/Remotes/lib.luau` providing:
  - `event()` — Typed RemoteEvent creation
  - `unreliableEvent()` — Typed UnreliableRemoteEvent creation
  - `callback()` — Typed RemoteFunction creation
  - `assert()` — Runtime type validation of remote arguments using GreenTea schemas
- Registered remotes defined in `src/shared/Remotes/init.luau`:
  - `patch` — Server-to-client state sync event (CharmSync patches)

**State Synchronization (CharmSync):**
- Server side (`src/server/Lib/sync.server.luau`):
  - `server.addSignalsToClient()` — Pushes computed reactive state to each player
  - `server.connect()` — Sends patches via `Remotes.patch:FireClient()`
  - Data filtered per `ProfileData.replicateSchema` (only whitelisted keys are sent to clients)
- Client side (`src/client/Scripts/Sync.client.luau`):
  - `client.addSignals()` — Registers signal handlers to update local reactive state
  - `Remotes.patch.OnClientEvent` — Receives server patches and applies via `client.patch()`
  - Local state: `PlayerDataStore.playerData` (Charm reactive object)

## Monitoring & Observability

**Error Tracking:**
- None configured beyond Roblox's built-in logging

**Logs:**
- `warn()` calls used in `src/server/Services/DataService/init.luau` for:
  - Profile type-check failures
  - Callback errors before profile release
- `warn()` in `src/shared/AudioManager/init.luau` for missing sound groups
- Roblox Studio output window during development

## CI/CD & Deployment

**Hosting:**
- Roblox platform — Game published via Roblox Studio
- No external hosting or deployment pipeline detected

**CI Pipeline:**
- None detected — No `.github/workflows/`, no `Makefile`, no CI configuration files

**Build/Sync Pipeline:**
- `pesde` manages dependency installation
- `rokit` manages tool versions (Rojo)
- Rojo syncs source files to Roblox Studio via plugin
- Pesde scripts generate sourcemap and Rojo config

## Environment Configuration

**Required env vars:**
- None — All configuration is embedded in code and Roblox game settings
- Roblox API keys are managed by the platform automatically

**Secrets location:**
- No secrets files present — Roblox DataStore access is managed by the engine
- `.env` files: Not detected

## Webhooks & Callbacks

**Incoming:**
- None — Game acts as a Roblox experience, no inbound webhooks

**Outgoing:**
- None — No outbound HTTP calls or webhook integrations detected

## Game Services Architecture

**Framework Lifecycle (lumin/framework v11.0.0):**
- Server entry: `src/server/Lib/init.server.luau`
  1. Requires shared Hooks (`OnPlayerAdded`, `OnPlayerRemoving`)
  2. Requires shared AudioManager
  3. Registers Services and Modules via `framework.Add()`
   4. Calls `framework.Start()` to initialize all services
   5. Reparents server code to a Camera instance (obfuscation to prevent client access)

**Hook System:**
- `src/shared/Hooks/init.luau` — Auto-discovers and initializes hook modules
- Hooks provide cross-cutting lifecycle events (e.g., `OnPlayerAdded`, `OnPlayerRemoving`)
- Each hook module exports `{Name, IsClient, IsServer, Hook, Init}` and is auto-loaded based on runtime context

**Migration System:**
- `src/server/Data/Migrations.luau` — Array of migration functions with `backwardsCompatible` flags
- `src/server/Services/DataService/Migration.luau` — Migration engine that:
  - Applies forward migrations sequentially
  - Checks backward compatibility for version downgrades
  - Tracks `migrationVersion` and `lastCompatibleVersion` fields in stored data

**Audio System:**
- `src/shared/AudioManager/` — Registry-based sound management
  - `Registry.luau` — Defines sound categories, groups, and builder pattern
  - `Util/create.luau` — Builder pattern for sound configuration (`fromId`, `url`, `volume`, `looped`)
  - Sound groups: SFX, Music, Ambient, Enemies
  - Categories: UI, Zombies, Players

---

*Integration audit: 2026-05-12*