--================================--
--        FIRE SCRIPT v1.6        --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

-- Chat

function sendMessage(source, text, customName)
	TriggerClientEvent(
		"chat:addMessage",
		source,
		{
			templateId = "firescript",
			args = {
				((customName ~= nil) and customName or "FireScript v1.5"),
				text
			}
		}
	)
end

-- Table functions

function highestIndex(table, fireIndex)
	if not table then
		return
	end
	local table = fireIndex ~= nil and table[fireIndex] or table
	local index = 0
	local count = 0

	for k, v in ipairs(table) do
		count = count + 1
		if k >= index then
			index = k
		end
	end

	return index, count
end

-- JSON config

function saveData(data, keyword)
	if type(keyword) ~= "string" then
		return
	end
	SaveResourceFile(GetCurrentResourceName(), keyword .. ".json", json.encode(data), -1)
end

function loadData(keyword)
	local fileContents = LoadResourceFile(GetCurrentResourceName(), keyword .. ".json")
	return fileContents and json.decode(fileContents) or nil
end