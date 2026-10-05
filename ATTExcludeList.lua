-- Initialisation
local appName, app = ...						-- App name and app table
--app.L = app.L or {}							-- Localisation table
--local L = app.L								-- Localisation table
app.api = {}									-- Api table for our app
ATTExcludeList = app.api  						-- Api namespace
local api = app.api								-- Api prefix for easier access
app.Name = "AllTheThings Exclude List"			-- Do not localize

-- Event registration
local event = CreateFrame("Frame")
event:SetScript("OnEvent", function(self, eventName, ...)
	if self[eventName] then
		self[eventName](self, ...)
	end
end)
event:RegisterEvent("ADDON_LOADED")

local function SetThingsExcluded(things, excluded)
	if not things then
		return
	end

	for _, thing in ipairs(things) do
		if excluded then
			thing.collectible = false
		else
			thing.collectible = nil
		end
	end
end

local function GetThingLink(kind, id)
	local thing = ATTC.SearchForObject(kind, id)
	return ATTC:SearchLink({
		key = kind,
		searchKey = kind,
		[kind] = id,
		text = thing and (thing.text or thing.hash) or (kind .. ":" .. id),
	})
end

-- Initial load
function app.Initialise()
	-- Declare SavedVariables
	if not ATTExcludeListDB then
		ATTExcludeListDB = {}
	end

	if not ATTExcludeListDB.ExcludeList then
		ATTExcludeListDB.ExcludeList = {}
	end

	ATTC.AddEventHandler("OnReady", function()
		for kind, ids in pairs(ATTExcludeListDB.ExcludeList) do
			for id in pairs(ids) do
				SetThingsExcluded(ATTC.SearchForObject(kind, id, nil, true), true)
			end
		end
	end)
end

-- Addon is loaded
function event:ADDON_LOADED(addOnName, containsBindings)
    if addOnName == appName then
        app.Initialise()
    end
end

-------------------------------------------------------------------------------
-- Slash command
-------------------------------------------------------------------------------

SLASH_ATTEXCLUDELIST1 = "/attex"
SlashCmdList["ATTEXCLUDELIST"] = function(msg)
	local filter, link = msg:match("^(%S*)%s*(.-)$")
	if filter == "add" and link then
		if not link:find("|H", 1, true) then
			print("Please provide a thing link")
			return
		end

		local things, kind, id = ATTC.SearchForLink(link)
		if not kind or not id then
			print("Could not find a valid thing link")
			return
		end

		local ids = ATTExcludeListDB.ExcludeList[kind]
		if ids and ids[id] then
			print(GetThingLink(kind, id), "is already in the exclude list")
			return
		end

		if not ids then
			ids = {}
			ATTExcludeListDB.ExcludeList[kind] = ids
		end
		ids[id] = true
		SetThingsExcluded(things, true)
		ATTC.RefreshCollections()
		print("Added", GetThingLink(kind, id), "to the exclude list")
		return
	end
	if filter == "remove" and link then
		if not link:find("|H", 1, true) then
			print("Please provide a thing link")
			return
		end

		local things, kind, id = ATTC.SearchForLink(link)
		if not kind or not id then
			print("Could not find a valid thing link")
			return
		end

		local ids = ATTExcludeListDB.ExcludeList[kind]
		if not ids or not ids[id] then
			print(GetThingLink(kind, id), "was not found in the exclude list")
			return
		end

		ids[id] = nil
		if not next(ids) then
			ATTExcludeListDB.ExcludeList[kind] = nil
		end
		SetThingsExcluded(things, false)
		ATTC.RefreshCollections()
		print("Removed", GetThingLink(kind, id), "from the exclude list")
		return
	end
	if filter == "print" then
		local hasExclusions = false
		for kind, ids in pairs(ATTExcludeListDB.ExcludeList) do
			for id in pairs(ids) do
				print(GetThingLink(kind, id))
				hasExclusions = true
			end
		end
		if not hasExclusions then
			print("The exclude list is empty")
		end
		return
	end
	print("Usage: /attex [add|remove] <thing link> or /attex print")
end