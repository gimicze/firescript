--================================--
--       FIRE SCRIPT v1.6.3       --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

function checkVersion()
	PerformHttpRequest(
		LatestVersionFeed,
		function(errorCode, data, headers)
			if tonumber(errorCode) == 200 then
				data = json.decode(data)
				if not data then
					print("^3[FireScript]^7 Couldn't check version - no data returned!")
					return
				end
				if data.tag_name == "v" .. Version then
					print("^2[FireScript]^7 Up to date.")
				else
					print(("^3[FireScript]^7 The script isn't up to date! Please update to version %s."):format(data.tag_name))
				end
			else
				print(("^3[FireScript]^7 Couldn't check version! Error code %s."):format(errorCode))
				print(LatestVersionFeed)
			end
		end,
		'GET',
		'',
		{
			['User-Agent'] = ("FireScript v%s"):format(Version)
		}
	)
end

-- Chat

function sendMessage(source, text, customName)
	if source > 0 then
		TriggerClientEvent(
			"chat:addMessage",
			source,
			{
				templateId = "firescript",
				args = {
					((customName ~= nil) and customName or ("FireScript v%s"):format(Version)),
					text
				}
			}
		)
	else
		print(("[FireScript v%s] %s"):format(Version, text))
	end
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

function table.length(t)
	if not t or type(t) ~= "table" then
		return
	end

	local count = 0

	for k, v in pairs(t) do count = count + 1 end

	return count
end

function table.random(t)
	if not t or type(t) ~= "table" or next(t) == nil then
		return false
	end

	local randomPosition = math.random(1, table.length(t))
	local currentPosition = 0
	local randomKey = nil

	for k, v in pairs(t) do -- Select a random registered fire
		currentPosition = currentPosition + 1

		if currentPosition == randomPosition then
			randomKey = k
			break
		end
	end

	return randomKey, t[randomKey]
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