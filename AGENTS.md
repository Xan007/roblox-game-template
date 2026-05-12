# AGENTS.md — Roblox Game Template

## Toolchain Commands

- `pesde install` — install all dependencies (generates `roblox_packages/`, `roblox_server_packages/`, `luau_packages/`)
- `rokit install` — install dev tools (rojo, stylua, selene, luau-lsp)
- `pesde run sourcemap_generator` — regenerate `sourcemap.json` for Luau LSP
- `pesde run roblox_sync_config_generator` — regenerate Rojo sync config
- `stylua src/` — format code (no project config; uses StyLua defaults)
- `selene src/` — lint (std defined in `selene_definitions/` directory, config in `selene.toml`)

No test runner exists in this repo.

## Architecture

Built on **lumin/framework** with a Service/Hook/Store pattern:

- **Entry points**: `src/server/Lib/init.server.luau` (server), `src/client/Bootstrap.client.luau` (client)
- **Server boot**: `framework.Add({ Services, Modules })` then `framework.Start()`. Services are loaded by directory scan; `Order` field controls startup order.
- **Server code hiding**: `init.server.luau` reparents the entire server tree under a Camera to prevent client access.
- **Hooks**: `src/shared/Hooks/` — each file exports `{ Name, IsClient, IsServer, Hook, Init }`. The init module auto-loads all hooks, skipping those that don't match the current run context.
- **Lifecycle methods on services**: `Init()`, `Start()`, and named hooks like `OnPlayerAdded(player)`.

## Data Flow

`ProfileStore` → `PlayerStore` (per-player session) → `PlayerProfileStore` (Charm reactive wrapper) → `CharmSync.server` (replicates computed data to client) → `Remotes.patch` → `CharmSync.client` → `PlayerDataStore` (client-side Charm reactive state)

## Key Conventions

- **File extension**: `.luau` only — never `.lua`
- **Run-context suffixes**: `.client.luau` and `.server.luau` for Roblox run-context scripts
- **Service pattern**: each service is a directory with `init.luau` returning a table with lifecycle methods
- **Package requires**: dependencies use relative paths into `roblox_packages/` and `roblox_server_packages/` (e.g. `require("../../../roblox_packages/Charm")`)
- **Self-requires**: `require("@self/ModuleName")` for same-package references (pesde path alias)

## Data Migrations

Add new migrations to `src/server/Data/Migrations.luau`. Each entry is either a plain function or a table `{ migrate = fn, backwardsCompatible = bool }`. The `Migration.migrate()` function in `src/server/Services/DataService/Migration.luau` applies them sequentially and checks backwards compatibility. **Never delete or reorder existing migration entries.**

## Adding a New Remote

Define in `src/shared/Remotes/init.luau` using the GreenTea-validated wrapper:
```luau
myRemote = lib.event(gt.string(), gt.number()),
```
Use `Remotes.assert` on the server side to validate incoming arguments.

## Adding Audio

1. Add sound entries to `src/shared/AudioManager/Registry.luau` under a category
2. Map the category to a `SoundGroup` in `CategoryToGroup`
3. Add new `SoundGroup` entries to the `SoundGroups` set if needed
4. Play via `AudioManager.Play(soundName, category?)`

## Dependency Management

- **pesde** (`pesde.toml`): main package manager — dependencies installed to `roblox_packages/`, `roblox_server_packages/`, `luau_packages/`
- **rokit** (`rokit.toml`): dev toolchain — currently only `rojo`
- **Wally packages**: declared under `[dependencies]` with `wally =` prefix in `pesde.toml`
- All package directories are gitignored; run `pesde install` after cloning

## Gotchas

- `sourcemap.json` is gitignored and must be regenerated after dependency changes
- `selene.toml` points std to `selene_definitions` — this directory must exist for linting to work
- `default.project.json` mounts `src/shared`, `src/client`, `src/server` all under `ReplicatedStorage.src`, plus `roblox_packages` and `roblox_server_packages`
- Admin user IDs for Conch commands are defined in `src/server/Services/CommandService/admins.luau` — currently only `game.CreatorId`
- `ProfileData.luau` defines the schema, template, replication filter, and leaderstats config — all in one place