---
last_mapped_commit: f2bd571
mapped_at: 2026-05-12
scope: full
focus: concerns
---

# Codebase Concerns

**Analysis Date:** 2026-05-12

## Tech Debt

**Hardcoded Relative Package Paths:**
- Issue: All `require()` calls use deep relative paths like `require("../../../roblox_packages/Charm")` and `require("../../../../roblox_server_packages/ProfileStore")`. These break if any file moves up or down a directory level and make refactoring error-prone.
- Files: `src/server/Services/DataService/init.luau` (lines 6-9), `src/server/Services/DataService/PlayerStore.luau` (line 3), `src/server/Stores/PlayerProfileStore.luau` (line 1), `src/server/Lib/sync.server.luau` (lines 3-4), `src/client/Scripts/Sync.client.luau` (line 4), `src/client/Stores/PlayerDataStore.luau` (line 1), `src/shared/Hooks/OnPlayerAdded.luau` (line 2), `src/shared/Hooks/OnPlayerRemoving.luau` (line 2), `src/shared/Remotes/lib.luau` (line 8), `src/shared/Remotes/init.luau` (line 2)
- Impact: Any directory restructuring requires manually updating dozens of require paths. prone to silent breakage where a wrong path loads an outdated or wrong module.
- Fix approach: Configure pesde package aliases or use a path alias system so requires become `require("@packages/Charm")` instead of relative navigation.

**Hardcoded Version-Specific Require Path:**
- Issue: `src/server/Lib/init.server.luau` (line 7) hardcodes a version-specific path: `require(ReplicatedStorage.roblox_packages[".pesde"]["littensy_charm-sync@0.4.0-rc.5"]["charm-sync"].server)`. Updating the CharmSync dependency requires manually finding and editing this string.
- Files: `src/server/Lib/init.server.luau` (line 7)
- Impact: Dependency upgrades silently break the game if this path is not updated.
- Fix approach: Remove the direct require and use the same pattern as other files (relative require from `roblox_packages`), or use pesde's alias system.

**Typo — `leadertstats`:**
- Issue: Variable is misspelled as `leadertstats` instead of `leaderstats` in `src/server/Services/DataService/init.luau` (line 29). This is functionally harmless because the local variable name is just used as a handle and then set as `Name = "leaderstats"`, but it hurts readability.
- Files: `src/server/Services/DataService/init.luau` (line 29)
- Impact: Reduced readability; copy-paste errors if someone references the typo variable name.
- Fix approach: Rename `leadertstats` → `leaderstats`.

**Empty UI Manager — Stub Module:**
- Issue: `src/client/UI/Manager/init.luau` exports an empty table with no methods. This is scaffolding with no implementation.
- Files: `src/client/UI/Manager/init.luau`
- Impact: Dead code; any code importing it gets a useless empty table.
- Fix approach: Remove until needed, or implement the UI management logic.

**Minimal Bootstrap — Single Require:**
- Issue: `src/client/Bootstrap.client.luau` contains only `require("../shared/AudioManager")`. A bootstrap file should initialize all client-side systems. Currently it only initializes AudioManager.
- Files: `src/client/Bootstrap.client.luau`
- Impact: Developers might assume client initialization happens here, but most client bootstrapping is scattered.
- Fix approach: Either make this the single entry point for client initialization or remove it and use Rojo's script execution order.

**`--!nonstrict` on TranslationHelper:**
- Issue: `src/shared/TranslationHelper.luau` (line 1) opts out of Luau's strict type checking with `--!nonstrict`. This disables type safety for the entire module.
- Files: `src/shared/TranslationHelper.luau` (line 1)
- Impact: Type errors in translation code go undetected. This module uses yielding calls at module load time, which is fragile.
- Fix approach: Refactor to use `--!strict` or at least `--!opt` and fix type annotations. Move yielding calls behind explicit function calls rather than running them at require-time.

**Sound Registry Placeholder Data:**
- Issue: `src/shared/AudioManager/Registry.luau` uses placeholder Roblox asset IDs (9111, 1111, 2222, 3333, 4444, 5555). These are unlikely to be valid Roblox audio assets.
- Files: `src/shared/AudioManager/Registry.luau` (lines 12-21)
- Impact: All audio playback silently fails (returns nil from GetSound, Play/Stop do nothing). Game ships with no working sound.
- Fix approach: Replace all placeholder IDs with real Roblox asset IDs before shipping. Add validation that SoundId resolves to a valid asset.

**Loosely Typed `replicateSchema`:**
- Issue: In `src/server/Data/ProfileData.luau` (line 20), `replicateSchema` is typed as `{[keys]: boolean}` — a generic dictionary map rather than a strict type derived directly from the schema. Keys can be added to the schema but forgotten from `replicateSchema`, silently failing to replicate.
- Files: `src/server/Data/ProfileData.luau` (line 20)
- Impact: New schema fields may silently not replicate to clients if developer forgets to add them to `replicateSchema`.
- Fix approach: Derive `replicateSchema` type from `Schema` or use a utility that automatically mirrors schema keys, reducing manual sync.

**Migration Functions Mutate Input In-Place:**
- Issue: In `src/server/Data/Migrations.luau`, migration functions (`v1`, `v2`) mutate the `old` table parameter directly rather than creating and returning a new table. This pattern is fragile — if a migration fails partway, the data object is left in a partially-mutated state.
- Files: `src/server/Data/Migrations.luau` (lines 1-9)
- Impact: A failed migration could corrupt the player's data object since mutations are not atomic.
- Fix approach: Migrations should deep-copy the input and return a new table, ensuring the original data remains untouched if the migration fails.

## Known Bugs

**`GetProfile` Busy-Wait Polling Loop:**
- Symptoms: `DataService.GetProfile` (line 104-110) uses a `while` loop with `task.wait()` to poll for profile availability. Under heavy load or slow data stores, this can spin for extended periods.
- Files: `src/server/Services/DataService/init.luau` (lines 101-114)
- Trigger: Calling `GetProfile(player, true)` when the profile is not yet loaded (e.g., during startup race conditions).
- Workaround: None currently; this is the only way to wait for a profile. Consider using a Signal/event-based approach instead.

**`PlayerStore` Type Export May Include Nil:**
- Symptoms: `src/server/Services/DataService/PlayerStore.luau` (line 7) defines `export type PlayerProfile = typeof(PlayerStore:StartSessionAsync())`. However, `StartSessionAsync` can return `nil` (as handled in DataService line 141-143). The exported type does not reflect this, potentially misleading consumers.
- Files: `src/server/Services/DataService/PlayerStore.luau` (line 7)
- Trigger: Type-checking code that assumes `PlayerProfile` is never `nil`.
- Workaround: Callers should manually check for `nil`.

## Security Considerations

**No Remote Event Rate Limiting:**
- Risk: The `patch` RemoteEvent in `src/shared/Remotes/init.luau` fires from server to client with no rate limiting. While CharmSync manages patches, malicious clients could still trigger expensive computations if any client-to-server remotes are added later.
- Files: `src/shared/Remotes/init.luau`, `src/shared/Remotes/lib.luau`
- Current mitigation: The Remotes system has an `assert` function for type validation, but it is not used on all remotes. The `patch` event is created without schema parameters.
- Recommendations: Add rate-limiting middleware for any future client-to-server remotes. Validate all incoming data on the server regardless of CharmSync's integrity checks.

**Admin List Based Only on Game Creator:**
- Risk: `src/server/Services/CommandService/admins.luau` returns `{ game.CreatorId }` — only the game creator is an admin. There is no way to add additional admins without code changes. Also, `game.CreatorId` returns a number for individual creators but may return a GroupId for group-owned games, which would be a UserId mismatch.
- Files: `src/server/Services/CommandService/admins.luau`
- Current mitigation: None beyond hardcoded creator check.
- Recommendations: Use a configurable DataStore-based or place configuration-based admin list. Add proper handling for group-owned games where `CreatorId` is a group, not a user.

**Client-Side Direct Mutation of Reactive State:**
- Risk: `src/client/Scripts/Sync.client.luau` directly mutates `PlayerDataStore.playerData` via the `deepAssign` function. If `deepAssign` receives crafted patch data, it could writing keys that were not intended to be in the client store.
- Files: `src/client/Scripts/Sync.client.luau` (lines 7-15, 27)
- Current mitigation: The server controls what data is replicated via `replicateSchema`, but the client-side `deepAssign` has no validation.
- Recommendations: Add schema validation on the client before applying patches, or use Charm's reactive update APIs instead of direct mutation.

**Server Reparenting Uses Camera Instance as Container:**
- Risk: `src/server/Lib/init.server.luau` (lines 23-44) creates a `Camera` instance to hold server-side code, reparenting both the server folder and `roblox_server_packages`. While this prevents client access, using `Camera` is a hack — it's a renderable instance. A `Folder` instance with `Archivable = false` would be more appropriate.
- Files: `src/server/Lib/init.server.luau` (lines 23-44)
- Current mitigation: The reparenting works to hide server code from clients.
- Recommendations: Replace `Instance.new("Camera")` with `Instance.new("Folder")` and set `Archivable = false`. Alternatively, use `ServerStorage` or `ServerScriptService` for server-only code.

**TranslationHelper Runs Yielding Calls at Module Load Time:**
- Risk: `src/shared/TranslationHelper.luau` (lines 19-24) calls `LocalizationService:GetTranslatorForPlayerAsync()` and `GetTranslatorForLocaleAsync()` at module require-time. These are yielding network calls. If they fail or hang, the entire require chain blocks. `--!nonstrict` also disables type checks.
- Files: `src/shared/TranslationHelper.luau` (lines 19-24)
- Current mitigation: Wrapped in `pcall`, but failures silently set `foundPlayerTranslator = false` or `foundFallbackTranslator = false`.
- Recommendations: Replace module-level yielding with lazy initialization. Load translators on first use or in a background task.

## Performance Bottlenecks

**Busy-Wait in Profile Loading:**
- Problem: `DataService.GetProfile` with `waitForProfile=true` polls in a `while` loop with `task.wait()`, checking `Profiles[player]` repeatedly.
- Files: `src/server/Services/DataService/init.luau` (lines 104-110)
- Cause: No event-driven notification system when a profile becomes available.
- Improvement path: Use a Signal or Promise that resolves when `ProfileLoaded` fires for the given player, eliminating the polling loop entirely.

**SoundService:WaitForChild on Client:**
- Problem: `src/shared/AudioManager/init.luau` (line 74) uses `WaitForChild` to find SoundGroups on the client, which can yield indefinitely if the server hasn't created them yet.
- Files: `src/shared/AudioManager/init.luau` (line 74)
- Cause: Server creates SoundGroups; client must wait for replication.
- Improvement path: Add a timeout to `WaitForChild` calls, or defer client AudioManager initialization until after game load.

**Charm.computed on Leaderstats Runs Per-Player Per-Stat:**
- Problem: Each player gets a `Charm.computed` listener per leaderstat column (`src/server/Services/DataService/init.luau` lines 38-46). With many stats or many players, this creates O(players × stats) reactive subscriptions.
- Files: `src/server/Services/DataService/init.luau` (lines 38-46)
- Cause: No batching mechanism for leaderstat updates.
- Improvement path: Consider batching leaderstat updates or using `Charm.subscribe` with a debounce for high-frequency stats.

## Fragile Areas

**Data Migration Pipeline:**
- Files: `src/server/Data/Migrations.luau`, `src/server/Services/DataService/Migration.luau`, `src/server/Services/DataService/init.luau` (lines 150-161)
- Why fragile: Migrations mutate data in-place and are applied sequentially in a `pcall` wrapper. If a migration throws after partially mutating data, the original data object is corrupted. The `lastCompatibleVersion` tracking is stored in-band with player data, so a failed migration can leave stale version metadata.
- Safe modification: Always deep-copy data before applying migrations. Apply mutations on the copy. Only write the copy back to profile.Data if all migrations succeed. Add integration tests for each migration.
- Test coverage: No test coverage for migration logic.

**Remote Event Creation with Numeric IDs:**
- Files: `src/shared/Remotes/lib.luau` (lines 46-124)
- Why fragile: RemoteEvent instances are created with auto-incrementing numeric names. The counter is module-level and resets on server restart. The ordering of `require()` calls determines the numeric ID, meaning any insertion or reordering of remotes silently changes IDs. On the client, `WaitForChild(nextId())` must match the server's exact creation order.
- Safe modification: Never reorder remote definitions in `src/shared/Remotes/init.luau`. Use named remotes (string identifiers) instead of auto-incremented numeric IDs for stability.

**Conch Lifecycle Initialization:**
- Files: `src/server/Services/CommandService/init.luau` (line 7), `src/client/Scripts/StartConchClient.client.luau` (line 4)
- Why fragile: `conch.initiate_default_lifecycle()` is called once on the server (in CommandService.Init) and once on the client (in StartConchClient). The server hooks into Framework lifecycle which calls `Init`, but the timing depends on service initialization order (Order = 0 for DataService).
- Safe modification: Ensure CommandService is initialized before any commands are registered. Do not call `initiate_default_lifecycle` from any other location.

**PlayerProfileStore Reactive State:**
- Files: `src/server/Stores/PlayerProfileStore.luau`
- Why fragile: The `profiles` table is a `Charm.reactive` table exposed as a module-level public field. Code across the server reads and writes to `profiles[player]` directly. The `wrapProfile` function both sets the profile AND returns the reactive reference, but `Profiles[player]` is also set to `nil` in `DataService.OnPlayerRemoving` (line 195), meaning there are two code paths that clear the profile.
- Safe modification: Centralize profile set/clear through PlayerProfileStore methods rather than direct assignment.

## Scaling Limits

**In-Memory Player Profiles:**
- Current capacity: Handles the Roblox server player limit (typically 50-100 players per server)
- Limit: All profile data for all players is held in memory via `Charm.reactive` tables. `Charm.computed` subscribers per player per replicated field scale linearly.
- Scaling path: If player data schemas grow large (many fields per player), memory and reactive computation overhead could become significant. Consider lazy-loading non-replicated fields or archiving inactive profile data.

**Sound Instance Creation on Server Start:**
- Current capacity: Fixed set of sounds defined in `src/shared/AudioManager/Registry.luau`
- Limit: All sounds are pre-created at server start. Adding sounds dynamically at runtime is not supported.
- Scaling path: For large sound libraries, implement lazy sound creation or sound pooling.

## Dependencies at Risk

**Multiple Release Candidate Dependencies:**
- Risk: Four dependencies are RC (release candidate) versions: `Charm@0.11.0-rc.4`, `CharmSync@0.4.0-rc.6`, `conch@0.4.0-rc.5`, `conch_ui@0.4.0-rc.5`, and `Rojo@7.7.0-rc.1`. RC versions are not stable; APIs may change between RCs, and there are no backward compatibility guarantees.
- Impact: Upgrading any RC dependency could break the game if APIs change. Pinning prevents updates, including security patches.
- Migration plan: Track each dependency's stable release. Once stable versions are published, upgrade and pin to `^x.y.0` ranges. Test thoroughly after each upgrade.

**ProfileStore is a Wally Dependency:**
- Risk: `ProfileStore` (Wally: `lm-loleris/profilestore@^1.0.3`) is loaded from a different package ecosystem (Wally) than pesde-managed packages. The `roblox_server_packages` directory is separate from `roblox_packages`, and the require path is different (`require("../../../../roblox_server_packages/ProfileStore")`).
- Impact: Two package management systems increase maintenance complexity. Wally packages may not receive the same level of pesde toolchain support (sourcemaps, type checking).
- Migration plan: Migrate ProfileStore to a pesde-managed dependency if a pesde-compatible version exists, or consolidate all dependencies under pesde.

**Missing Selene Definitions:**
- Risk: `selene.toml` references `std = "selene_definitions"` but no `selene_definitions` directory or file exists in the project. This means linting with selene likely fails or has no custom Roblox API definitions.
- Impact: Luau linting may produce false positives or miss real issues. Static analysis is effectively disabled.
- Migration plan: Generate selene definitions using `pesde run selene generate` or create the definitions file. Configure selene to use roblox standard definitions.

## Missing Critical Features

**No Automated Testing:**
- Problem: The project has zero test files. No unit, integration, or E2E tests exist for any module — including the critical data migration pipeline, profile management, and remote event system.
- Blocks: Confident refactoring, CI/CD validation, regression detection.

**No Rate Limiting or Anti-Cheat Infrastructure:**
- Problem: No rate limiting on remote events, no server-side validation of client state changes (beyond what CharmSync provides), and no anti-exploit detection.
- Blocks: Production readiness for a multiplayer Roblox game.

**No Data Store Error Recovery Strategy:**
- Problem: If `ProfileStore:StartSessionAsync` fails, the player is kicked with a generic message (`Profile load fail - Please rejoin`). There is no retry logic, no queue mechanism, and no graceful degradation.
- Files: `src/server/Services/DataService/init.luau` (lines 134-143)
- Blocks: Graceful handling of Roblox DataStore outages.

## Test Coverage Gaps

**All Server Logic — Untested:**
- What's not tested: DataService, Migration pipeline, PlayerStore, PlayerProfileStore, CommandService, sync logic
- Files: `src/server/Services/DataService/init.luau`, `src/server/Services/DataService/Migration.luau`, `src/server/Services/DataService/PlayerStore.luau`, `src/server/Stores/PlayerProfileStore.luau`, `src/server/Lib/sync.server.luau`, `src/server/Services/CommandService/init.luau`
- Risk: Any change to data handling, migration logic, or profile management could introduce bugs that silently corrupt player data.
- Priority: High

**All Client Logic — Untested:**
- What's not tested: PlayerDataStore, Sync.client, Bootstrap, UI Manager
- Files: `src/client/Stores/PlayerDataStore.luau`, `src/client/Scripts/Sync.client.luau`, `src/client/Bootstrap.client.luau`, `src/client/UI/Manager/init.luau`
- Risk: Client-side state synchronization bugs could cause UI desync or data loss.
- Priority: Medium

**Shared Modules — Untested:**
- What's not tested: Remotes, Observers, AudioManager, TranslationHelper
- Files: `src/shared/Remotes/lib.luau`, `src/shared/Modules/Observers.luau`, `src/shared/AudioManager/init.luau`, `src/shared/TranslationHelper.luau`
- Risk: Observer cleanup leaks, remote event type mismatches, and translation fallback failures.
- Priority: Medium

---

*Concerns audit: 2026-05-12*