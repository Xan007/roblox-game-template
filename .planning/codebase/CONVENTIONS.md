---
last_mapped_commit: f2bd571
mapped_at: 2026-05-12
scope: full
focus: quality
---

# Coding Conventions

**Analysis Date:** 2026-05-12

## Naming Patterns

**Files:**
- Use **PascalCase** for module files: `ProfileData.luau`, `PlayerStore.luau`, `Observers.luau`, `Migration.luau`
- Use **camelCase** for command files: `kick.luau`, `admins.luau`
- Use **init.luau** for module entry points (directory-as-module pattern): `src/server/Services/DataService/init.luau`, `src/shared/Remotes/init.luau`
- Use **lib.luau** for internal/library modules co-located with init: `src/shared/Remotes/lib.luau`
- Use **.client.luau** suffix for client-only scripts: `Sync.client.luau`, `StartConchClient.client.luau`, `Bootstrap.client.luau`
- Use **.server.luau** suffix for server-only scripts: `sync.server.luau`, `init.server.luau`
- Use **Util/** directory for utility/builder helpers: `src/shared/AudioManager/Util/create.luau`

**Functions:**
- Use **PascalCase** for service methods and public API functions: `DataService.Start()`, `DataService.GetProfile()`, `DataService.OnPlayerAdded()`
- Use **camelCase** for local/helper functions: `deepAssign`, `noYield`, `typeCheck`, `wrapProfile`, `getPlayerData`
- Use **PascalCase** for module-scoped factory constructors: `Migration.migrate()`, `Migration.getLastCompatibleVersion()`
- Use **PascalCase** for observer functions: `observeTag`, `observePlayers`, `observeCharacter`

**Variables:**
- Use **PascalCase** for module tables returned as singletons: `DataService`, `PlayerStore`, `CommandService`, `AudioManager`
- Use **PascalCase** for constants/registries: `Profiles`, `ProfileData`, `Migrations`
- Use **camelCase** for local variables: `migrateOk`, `migratedData`, `lastCompatibleVersion`, `leadertstats`
- Use **SCREAMING_SNAKE_CASE** for runtime environment flags: `IS_CLIENT`, `IS_SERVER`, `IS_TEST`

**Types:**
- Use **PascalCase** for type names: `Schema`, `PlayerProfile`, `SoundGroups`, `SoundCategory`, `SoundNames`
- Use **PascalCase** for exported type aliases: `export type Schema = typeof(schema)`
- Use **camelCase** for type fields: `migrationVersion`, `lastCompatibleVersion`, `backwardsCompatible`
- Use generic type parameters in angle brackets: `Event<Args...>`, `Observer<Key>`, `Callback<Args..., Results...>`

## Code Style

**Formatting:**
- Tool: StyLua (configured via `pesde.toml` as dev dependency, version `^2.3.1`)
- Indentation: **Tabs** (standard Luau/StyLua default)
- String interpolation: Use backtick template literals (`` `Player_{userId}` ``) over `string.format` wherever possible
- Line width: Standard StyLua defaults (~120 columns)

**Linting:**
- Tool: Selene (configured via `selene.toml`, std = "selene_definitions")
- Custom definitions directory: `selene_definitions` (referenced in config)

**Type Annotations:**
- Annotate function parameters and return types consistently: `function DataService.GetProfile(target: Player | number, waitForProfile: boolean?): PlayerProfile?`
- Use `export type` for types that need to be consumed by other modules
- Use type narrowing with `typeof()` checks: `typeof(target) == "number"`, `typeof(migration) == "table"`
- Cast with `::` syntax: `profiles[player] :: PlayerProfile`, `(factory :: any)(...)`

## Import Organization

**Order:**
1. Roblox service imports: `local Players = game:GetService("Players")`
2. Package imports (from `roblox_packages/`): `local Charm = require("../../../roblox_packages/Charm")`
3. Same-module imports (relative or `@self`): `local PlayerStore = require("@self/PlayerStore")`
4. Sibling module imports (relative paths): `local ProfileData = require("../Data/ProfileData")`

**Path Aliases:**
- `@self` — resolves to the current package/module directory. Used for intra-module imports within Services: `require("@self/Migration")`, `require("@self/PlayerStore")`
- Relative paths (`../`, `../../`) used for cross-boundary imports between sibling directories

**Import Patterns:**
- Use `script:FindFirstAncestor("server")` for locating ancestry in the DataModel when needed (see `src/server/Lib/init.server.luau`)
- Use `script.Parent` for accessing sibling modules within the same directory
- Use `script:GetChildren()` for dynamic module enumeration (see `src/shared/Hooks/init.luau`)

## Error Handling

**Patterns:**
- Use `pcall` for operations that may fail: profile loading, migration execution, type checking
- Use `xpcall` with `debug.traceback` for observer callbacks that need stack traces
- Use `warn()` with descriptive context strings for non-fatal issues: `warn("[Observers] Error in callback for key...")`
- Use `assert()` for type validation of remote event instances and callback return types
- Use `error()` with `debug.traceback` in wrapper functions to preserve original stack traces

**Error Messages:**
- Use string interpolation (backtick templates) for error messages: `` `Migration {version} threw an error: {migrated}` ``
- Include context identifiers in error messages: player name, migration version, key

**Graceful Degradation:**
- When translations or sounds fail to load, fall back gracefully: TranslateHelper returns the raw key, AudioManager falls back to "SFX" group
- Use `foundPlayerTranslator` / `foundFallbackTranslator` boolean guards for optional resource availability

## Logging

**Framework:** No centralized logging framework — uses Luau built-ins

**Patterns:**
- Use `warn()` for recoverable errors with contextual prefixes: `warn("[Observers] Error in ...")`
- Use `warn()` in server-side type checking: `warn("Profile data for player {player.Name} failed typecheck: {msg}")`
- Use `warn()` for missing registrations: `warn("No sound group found for category {category}, defaulting to SFX")`

## Comments

**When to Comment:**
- Use block comments (`--[[ ... ]]`) for module-level documentation describing purpose and behavior
- Use inline comments for critical business rules: `-- DO NOT DELETE OR RENAME THESE FIELDS`
- Use inline comments for important context: `-- GDPR compliance`, `-- Fill in missing variables from PROFILE_TEMPLATE (optional)`

**JSDoc/TSDoc:**
- Not used. Documentation comments use Luau block comment style `--[[ ]]` for multi-line descriptions

## Function Design

**Size:** Functions generally range from 5-50 lines. The longest function is `DataService.OnPlayerAdded` at ~45 lines, which handles the entire profile lifecycle for a player joining.

**Parameters:**
- Use type annotations on all parameters: `function DataService.UseProfile(target: Player | number, callback: (profile: PlayerProfile) -> (), waitForProfile: boolean?)`
- Use union types for flexible parameters: `target: Player | number`
- Use optional parameters with `?`: `waitForProfile: boolean?`
- Place optional parameters after required ones

**Return Values:**
- Use explicit return types: `function Migration.migrate(...): (boolean, any, number)`
- Return multiple values for rich results: `(success, data, lastCompatibleVersion)`
- Return tables for module exports with named fields: `return { profiles = profiles, wrapProfile = wrapProfile, ... }`
- Use `nil` to signal absence rather than empty tables for single optional returns

## Module Design

**Exports:**
- Use a single returned table with named fields at the end of the file
- Include both data and functions in the export table
- Export types separately using `export type` at module level

**Barrel Files:**
- Use `init.luau` as module entry points — the directory IS the module
- Use `lib.luau` for internal implementation details consumed by `init.luau`
- The `init.luau` re-exports from `lib.luau` and adds domain-specific instances (see Remotes pattern)

**Module Patterns:**

1. **Service Pattern** — A table with methods and an `Order` property for initialization ordering:
   ```lua
   local DataService = {}
   DataService.Order = 0

   function DataService.Start()
       -- initialization logic
   end

   return DataService
   ```
   Used in `src/server/Services/DataService/init.luau`

2. **Hook Pattern** — Tables with lifecycle metadata that the Framework auto-loads:
   ```lua
   return {
       Name = "OnPlayerAdded",
       IsClient = false,
       IsServer = true,
       Hook = OnPlayerAdded,
       Init = function() ... end
   }
   ```
   Used in `src/shared/Hooks/`

3. **Observer Pattern** — Generic createObserver with cleanup functions:
   ```lua
   local function createObserver<Key>(setup, observer_id)
       -- returns a cleanup function
   end
   ```
   Used in `src/shared/Modules/Observers.luau`

4. **Builder Pattern** — Method chaining for sound configuration:
   ```lua
   create().fromId(2222).looped(true)
   ```
   Used in `src/shared/AudioManager/Util/create.luau`

5. **Schema + Template Pattern** — GreenTea schema co-located with a default template:
   ```lua
   local schema = gt.table({ xp = gt.number(), ... })
   local template: Schema = { xp = 0, ... }
   ```
   Used in `src/server/Data/ProfileData.luau`

## Environment Detection

**Pattern:** Use `RunService` checks for platform-specific behavior at module level or in conditionals:
- `RunService:IsClient()` — client-only code paths
- `RunService:IsServer()` — server-only code paths
- `RunService:IsStudio() and not RunService:IsRunning()` — test environment detection

This pattern is visible in `src/shared/Remotes/lib.luau` (three-way branch for test/client/server) and `src/shared/AudioManager/init.luau` (two-way branch for server/client).

## Data Flow Conventions

**Client-Server Synchronization:**
- Server owns authoritative data via ProfileStore
- Server replicates specific fields via `replicateSchema` whitelist
- Client receives patches via `OnClientEvent` and deep-merges into reactive store
- Use `CharmSync` for automatic reactive state synchronization

**Remote Event Safety:**
- All remote events use `Remotes.lib.assert` with GreenTea type validators for argument validation
- Define remotes declaratively in `src/shared/Remotes/init.luau`
- Use typed event constructors: `lib.event()`, `unreliableEvent()`, `callback()`

---

*Convention analysis: 2026-05-12*