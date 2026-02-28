local Migration = {}

--[[
Finds the last version that is NOT backwards compatible.
Returns the version number, or 0 if all migrations are backwards compatible.
]]
function Migration.getLastCompatibleVersion(migrations: { any }): number
	local serverVersion = #migrations

	for version = serverVersion, 1, -1 do
		local migration = migrations[version]

		-- Check if migration is NOT backwards compatible
		if typeof(migration) == "table" and migration.backwardsCompatible ~= true then
			return version
		elseif typeof(migration) == "function" then
			-- Functions are not backwards compatible by default
			return version
		end
	end

	return 0
end

--[[
Executes migrations on data and validates backwards compatibility.

Returns:
- success (boolean): Whether migration succeeded
- migratedData (table): The migrated data, or error message if failed
- lastCompatibleVersion (number): The last incompatible version
]]
function Migration.migrate(migrations: { any }, data: { [string]: any }, key: string?): (boolean, any, number)
	local serverVersion = #migrations
	local savedVersion = data.migrationVersion or 0
	local lastCompatibleVersion = data.lastCompatibleVersion

	-- Apply forwards migrations (saved version < server version)
	if serverVersion > savedVersion then
		for version = savedVersion + 1, serverVersion do
			local migration = migrations[version]
			local migrateFunction

			-- Extract the migration function
			if typeof(migration) == "function" then
				migrateFunction = migration
			elseif typeof(migration) == "table" and migration.migrate then
				migrateFunction = migration.migrate
			else
				return false, `Migration {version} has invalid structure`, 0
			end

			-- Execute migration
			local ok, migrated = pcall(migrateFunction, data, key)
			if not ok then
				return false, `Migration {version} threw an error: {migrated}`, 0
			end

			if migrated == nil then
				return false, `Migration {version} returned 'nil'`, 0
			end

			data = migrated
		end

		lastCompatibleVersion = Migration.getLastCompatibleVersion(migrations)
	-- Backwards compatibility check (saved version > server version)
	elseif serverVersion < savedVersion then
		-- lastCompatibleVersion will be nil for old documents that existed before backwards compatibility was added
		if lastCompatibleVersion == nil or serverVersion < lastCompatibleVersion then
			return false,
				`Saved migration version {savedVersion} is not backwards compatible with server version {serverVersion}`,
				0
		end
	end

	return true, data, lastCompatibleVersion
end

return Migration
