---
last_mapped_commit: f2bd571
mapped_at: 2026-05-12
scope: full
focus: quality
---

# Testing Patterns

**Analysis Date:** 2026-05-12

## Test Framework

**Runner:**
- No test framework is configured or integrated in this project
- No test runner scripts found in `pesde.toml` dependencies
- No test configuration files found (no `jest.config`, `vitest.config`, or Roblox test runner configs)

**Assertion Library:**
- None configured
- The project uses `assert()` (Luau built-in) for runtime type validation and safety checks, but not for testing

**Run Commands:**
```bash
# No test commands are available
# The project has no test runner, test scripts, or test dependencies
```

## Test File Organization

**Location:**
- No test files exist in the `src/` directory
- No `*.test.luau` or `*.spec.luau` files in the project's own source code
- A test file exists in a vendored dependency: `roblox_packages/.pesde/sleitnick_signal@2.0.3/signal/init.test.luau` and `roblox_server_packages/.pesde/lm-loleris_profilestore@1.0.3/profilestore/ProfileStoreTest.server.luau`, but these belong to upstream packages, not this project

**Naming:**
- No convention established yet
- Based on dependency conventions (e.g., Signal package uses `init.test.luau`), the expected pattern would be:
  - Test files placed alongside the module: `ModuleName.test.luau`
  - Server-side tests would use `.server.luau` suffix: `ModuleName.test.server.luau`

**Structure:**
```
src/
├── client/          # No tests
├── server/          # No tests  
└── shared/          # No tests
```

## Test Structure

**Suite Organization:**
- Not applicable — no tests exist yet

**Patterns:**
- No test patterns established in this project

## Mocking

**Framework:** None

**Patterns:**
- The `Remotes` module (`src/shared/Remotes/lib.luau`) implements an environment-aware pattern that provides mock instances in test mode:
  ```lua
  local IS_TEST = RunService:IsStudio() and not RunService:IsRunning()

  if IS_TEST then
      function event()
          return Instance.new("RemoteEvent")
      end
  end
  ```
  This could serve as a basis for testing remote event logic without creating actual networked instances.

- The `Hooks` module (`src/shared/Hooks/init.luau`) uses `RunService:IsClient()` / `RunService:IsServer()` checks to conditionally skip hooks. Tests could mock `RunService` or run in the appropriate context.

**What to Mock:**
- `game:GetService("Players")` — for player-related tests
- `game:GetService("RunService")` — for environment detection (client/server/test)
- ProfileStore — for data persistence tests
- RemoteEvent/RemoteFunction instances — the Remotes module already provides test-mode stubs

**What NOT to Mock:**
- Migration logic — pure functions that transform data, easily testable directly
- Schema validation (GreenTea) — type checking functions that return boolean results
- Observer cleanup logic — pure functions with no side effects

## Fixtures and Factories

**Test Data:**
- Not applicable — no tests exist yet

**Location:**
- No fixture directory established

**Existing Data Templates (usable as fixtures):**
- `src/server/Data/ProfileData.luau` exports a `template` table that serves as the default player data shape:
  ```lua
  local template: Schema = {
      xp = 0,
      coins = 0,
      migrationVersion = 0,
      lastCompatibleVersion = 0,
  }
  ```
  This could be reused as a test fixture factory.

## Coverage

**Requirements:** None enforced — no coverage tooling configured

**View Coverage:**
```bash
# No coverage commands available
```

## Test Types

**Unit Tests:**
- Not used
- Best candidates for unit testing:
  - `Migration.migrate()` — pure function with clear input/output, already has error cases
  - `Migration.getLastCompatibleVersion()` — pure function
  - `DataService.GetKey()` — pure function
  - `ProfileData` schema validation via GreenTea
  - Audio Manager `create()` builder pattern
  - `deepAssign()` utility in `Sync.client.luau`

**Integration Tests:**
- Not used
- Best candidates for integration testing:
  - Profile loading lifecycle (`DataService.OnPlayerAdded` / `DataService.OnPlayerRemoving`)
  - CharmSync initialization and patch application
  - Remote event creation and type validation
  - Hook initialization and event wiring

**E2E Tests:**
- Not used
- No E2E testing infrastructure exists

## Common Patterns

**Async Testing:**
- Not established
- The project uses `task.wait()` for yielding (see `DataService.GetProfile` polling loop) which would need adaptation for test environments

**Error Testing:**
- Not established
- `Migration.migrate()` returns `(boolean, any, number)` tuples that are well-suited for assertion-based error testing:
  ```lua
  -- Expected pattern for testing Migration failures:
  local ok, msg, version = Migration.migrate(Migrations, badData, "test_key")
  assert(ok == false, "Expected migration failure")
  assert(string.find(msg, "Migration"), "Expected migration error message")
  ```

## Recommendations for Adding Tests

### Test Framework Options
Since this is a Roblox Luau project, suitable frameworks include:
- **TestEZ** — Lightweight BDD-style testing for Roblox (commonly used in the ecosystem)
- **Jest for Roblox** — More feature-rich, used by larger Roblox projects

### Recommended Test Structure
```
src/
├── client/
│   ├── Stores/
│   │   └── PlayerDataStore.luau
│   │   └── PlayerDataStore.test.luau    # Co-located test
├── server/
│   ├── Services/
│   │   └── DataService/
│   │       ├── init.luau
│   │       └── init.test.luau           # Co-located test
│   ├── Data/
│   │   ├── ProfileData.luau
│   │   ├── ProfileData.test.luau
│   │   ├── Migrations.luau
│   │   └── Migrations.test.luau
│   └── Stores/
│       ├── PlayerProfileStore.luau
│       └── PlayerProfileStore.test.luau
└── shared/
    ├── Remotes/
    │   ├── init.luau
    │   └── init.test.luau
    ├── Modules/
    │   ├── Observers.luau
    │   └── Observers.test.luau
    └── AudioManager/
        ├── init.luau
        └── init.test.luau
```

### High-Priority Test Targets
1. **`Migration.migrate()`** (`src/server/Services/DataService/Migration.luau`) — Pure function, critical for data integrity, clear success/failure cases
2. **`Migration.getLastCompatibleVersion()`** (`src/server/Services/DataService/Migration.luau`) — Pure function, edge cases with compatibility flags
3. **`ProfileData` schema validation** (`src/server/Data/ProfileData.luau`) — GreenTea type checking is directly testable
4. **`Observers` module** (`src/shared/Modules/Observers.luau`) — Generic observer pattern with cleanup, testable with mock callback tracking
5. **`Remotes.lib`** (`src/shared/Remotes/lib.luau`) — Test mode already built in, verify type assertion behavior

---

*Testing analysis: 2026-05-12*