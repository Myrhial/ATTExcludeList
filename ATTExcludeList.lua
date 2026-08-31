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

-- Set item as excluded or not
local function SetItemExcluded(itemID, excluded)
	local item = ATTC.SearchForObject("itemID", itemID)
	if item then
		item.collectible = not excluded
		return true
	end
	return false
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

	for _, itemID in ipairs(ATTExcludeListDB.ExcludeList) do
		SetItemExcluded(itemID, true)
	end
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
	-- TODO: Handle other types of links too but we can start with items for now
	if filter == "add" and link then
		local itemID = tonumber(link:match("|Hitem:(%d+)"))
		if itemID then
			for _, id in ipairs(ATTExcludeListDB.ExcludeList) do
				if id == itemID then
					print(itemID, "is already in the exclude list")
					return
				end
			end
			table.insert(ATTExcludeListDB.ExcludeList, itemID)
			SetItemExcluded(itemID, true)
			ATTC.RefreshCollections()
			print("Added", itemID, "to the exclude list")
		else
        	print("Could not find a valid item link")
		end
		return
	end
	if filter == "remove" and link then
		local itemID = tonumber(link:match("|Hitem:(%d+)"))
		if itemID then
			local found = false
			for i, id in ipairs(ATTExcludeListDB.ExcludeList) do
				if id == itemID then
					table.remove(ATTExcludeListDB.ExcludeList, i)
					SetItemExcluded(itemID, false)
					ATTC.RefreshCollections()
					print("Removed", itemID, "from the exclude list")
					found = true
					break
				end
			end
			if not found then
				print(itemID, "was not found in the exclude list")
			end
		end
		return
	end
	if filter == "print" then
		if #ATTExcludeListDB.ExcludeList == 0 then
			print("The exclude list is empty")
		else
			for i = 1, #ATTExcludeListDB.ExcludeList, 1 do
				print(ATTExcludeListDB.ExcludeList[i])
			end
		end
		return
	end
	print("Usage: /attex [add||remove] <thing link> or /attex print")
end