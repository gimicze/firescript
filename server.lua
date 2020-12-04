--================================--
--        FIRE SCRIPT v1.5        --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

local activeFires = {}
local registeredFires = {}
local boundFires = {}

local whitelist = {}
local whitelistedPlayers = {}

local lastDispatchNumber = 0
local dispatchPlayers = {}

--================================--
--          INITIALIZE            --
--================================--

function onResourceStart(resourceName)
	if (GetCurrentResourceName() == resourceName) then
		loadWhitelist()
	end
end

function onResourceStop(resourceName)
	if (GetCurrentResourceName() == resourceName) then
		saveWhitelist()
	end
end

RegisterNetEvent('onResourceStart')
AddEventHandler(
	'onResourceStart',
	onResourceStart
)

RegisterNetEvent('onResourceStop')
AddEventHandler(
	'onResourceStop',
	onResourceStop
)

--================================--
--           CLEAN-UP             --
--================================--

function onPlayerDropped()
	whitelist[source] = nil
	removeFromDispatch(source)
end

RegisterNetEvent('playerDropped')
AddEventHandler(
	'playerDropped',
	onPlayerDropped
)

--================================--
--           COMMANDS             --
--================================--

RegisterNetEvent('fireManager:command:startfire')
AddEventHandler(
	'fireManager:command:startfire',
	function(coords, maxSpread, chance, triggerDispatch)
		if not isWhitelisted(source) then
			return
		end
		local _source = source

		local maxSpread = (maxSpread ~= nil and tonumber(maxSpread) ~= nil) and tonumber(maxSpread) or Config.Fire.maximumSpreads
		local chance = (chance ~= nil and tonumber(chance) ~= nil) and tonumber(chance) or Config.Fire.fireSpreadChance

		local fireIndex = createFire(coords, maxSpread, chance)

		sendMessage(source, "Created fire #" .. fireIndex)

		if triggerDispatch then
			Citizen.SetTimeout(
				Config.Dispatch.timeout,
				function()
					TriggerClientEvent('fd:dispatch', _source, coords)
				end
			)
		end
	end
)

RegisterNetEvent('fireManager:command:registerfire')
AddEventHandler(
	'fireManager:command:registerfire',
	function(coords, triggerDispatch)
		if not isWhitelisted(source) then
			return
		end

		local registeredFireID = registerFire(triggerDispatch and coords or nil)

		sendMessage(source, "Registered fire #" .. registeredFireID)
	end
)

RegisterNetEvent('fireManager:command:addflame')
AddEventHandler(
	'fireManager:command:addflame',
	function(registeredFireID, coords, spread, chance)
		if not isWhitelisted(source) then
			return
		end
		local registeredFireID = tonumber(registeredFireID)
		local spread = tonumber(spread)
		local chance = tonumber(chance)

		if not (coords and registeredFireID and spread and chance) then
			return
		end

		if not registeredFires[registeredFireID] then
			sendMessage(source, "No such fire registered.")
			return
		end

		local flameID = highestIndex(registeredFires[registeredFireID].flames) + 1
		registeredFires[registeredFireID].flames[flameID] = {}
		registeredFires[registeredFireID].flames[flameID].coords = coords
		registeredFires[registeredFireID].flames[flameID].spread = spread
		registeredFires[registeredFireID].flames[flameID].chance = chance

		sendMessage(source, "Registered flame #" .. flameID)
	end
)

RegisterCommand(
	'stopfire',
	function(source, args, rawCommand)
		if not isWhitelisted(source) then
			return
		end
		local fireIndex = tonumber(args[1])
		if not fireIndex then
			return
		end
		if removeFire(fireIndex) then
			sendMessage(source, "Stopping fire #" .. fireIndex)
			TriggerClientEvent("pNotify:SendNotification", source, {
				text = "Fire " .. fireIndex .. " going out...",
				type = "info",
				timeout = 5000,
				layout = "centerRight",
				queue = "fire"
			})
		end
	end,
	false
)

RegisterCommand(
	'stopallfires',
	function(source, args, rawCommand)
		if not isWhitelisted(source) then
			return
		end
		removeAllFires()
		sendMessage(source, "Stopping fires")
		TriggerClientEvent("pNotify:SendNotification", source, {
			text = "Fires going out...",
			type = "info",
			timeout = 5000,
			layout = "centerRight",
			queue = "fire"
		})
	end,
	false
)

RegisterCommand(
	'removeflame',
	function(source, args, rawCommand)
		if not isWhitelisted(source) then
			return
		end
		local registeredFireID = tonumber(args[1])
		local flameID = tonumber(args[2])

		if not (registeredFireID and flameID) then
			return
		end


		if not (registeredFires[registeredFireID] and registeredFires[registeredFireID].flames[flameID]) then
			sendMessage(source, "No such fire or flame registered.")
			return
		end

		table.remove(registeredFires[registeredFireID].flames, flameID)

		sendMessage(source, "Removed flame #" .. flameID)
	end,
	false
)

RegisterCommand(
	'removefire',
	function(source, args, rawCommand)
		if not isWhitelisted(source) then
			return
		end
		local registeredFireID = tonumber(args[1])
		if not registeredFireID then
			return
		end

		if not registeredFires[registeredFireID] then
			sendMessage(source, "No such fire or flame registered.")
			return
		end

		registeredFires[registeredFireID] = nil

		sendMessage(source, "Removed fire #" .. registeredFireID)
	end,
	false
)

RegisterCommand(
	'startregisteredfire',
	function(source, args, rawCommand)
		if not isWhitelisted(source) then
			return
		end
		local _source = source
		local registeredFireID = tonumber(args[1])

		if not registeredFireID then
			return
		end

		if not registeredFires[registeredFireID] then
			sendMessage(source, "No such fire or flame registered.")
			return
		end

		boundFires[registeredFireID] = {}

		for k, v in pairs(registeredFires[registeredFireID].flames) do
			local fireID = createFire(v.coords, v.spread, v.chance)
			table.insert(boundFires[registeredFireID], fireID)
			Citizen.Wait(10)
		end

		if registeredFires[registeredFireID].dispatchCoords then
			local dispatchCoords = registeredFires[registeredFireID].dispatchCoords
			Citizen.SetTimeout(
				Config.Dispatch.timeout,
				function()
					TriggerClientEvent('fd:dispatch', _source, dispatchCoords)
				end
			)
		end

		sendMessage(source, "Started registered fire #" .. registeredFireID)
	end,
	false
)

RegisterCommand(
	'stopregisteredfire',
	function(source, args, rawCommand)
		if not isWhitelisted(source) then
			return
		end
		local _source = source
		local registeredFireID = tonumber(args[1])

		if not registeredFireID then
			return
		end

		if not boundFires[registeredFireID] then
			sendMessage(source, "No such fire or flame registered.")
			return
		end

		for k, v in ipairs(boundFires[registeredFireID]) do
			removeFire(v)
			Citizen.Wait(10)
		end

		boundFires[registeredFireID] = {}

		sendMessage(source, "Stopping registered fire #" .. registeredFireID)

		TriggerClientEvent("pNotify:SendNotification", source, {
			text = "Fire going out...",
			type = "info",
			timeout = 5000,
			layout = "centerRight",
			queue = "fire"
		})
	end,
	false
)

RegisterCommand(
	'firewl',
	function(source, args, rawCommand)
		local _source = source
		local action = args[1]
		local serverId = tonumber(args[2])

		if not (action and serverId) then
			return
		end

		local identifier = GetPlayerIdentifier(serverId, 0)

		if not identifier then
			sendMessage(source, "Player not online.")
			return
		end

		if action == "add" then
			addToWhitelist(serverId, identifier)
			sendMessage(source, ("Added %s to the whitelist."):format(GetPlayerName(serverId)))
		elseif action == "remove" then
			removeFromWhitelist(serverId, identifier)
			sendMessage(source, ("Removed %s from the whitelist."):format(GetPlayerName(serverId)))
		else
			sendMessage(source, "Invalid action.")
		end
	end,
	true
)

RegisterCommand(
	'firewlreload',
	function(source, args, rawCommand)
		loadWhitelist()
		sendMessage(source, "Reloaded whitelist from config.")
	end,
	true
)

RegisterCommand(
	'firewlsave',
	function(source, args, rawCommand)
		saveWhitelist()
		sendMessage(source, "Saved whitelist.")
	end,
	true
)

RegisterCommand(
	'firedispatch',
	function(source, args, rawCommand)
		local _source = source
		local action = args[1]
		local serverId = tonumber(args[2])

		if not (action and serverId) then
			return
		end

		local identifier = GetPlayerIdentifier(serverId, 0)

		if not identifier then
			sendMessage(source, "Player not online.")
			return
		end

		if action == "add" then
			addToDispatch(serverId)
			sendMessage(source, ("Subscribed %s to dispatch."):format(GetPlayerName(serverId)))
		elseif action == "remove" then
			removeFromWhitelist(serverId, identifier)
			sendMessage(source, ("Unsubscribed %s from the dispatch."):format(GetPlayerName(serverId)))
		else
			sendMessage(source, "Invalid action.")
		end
	end,
	true
)

--================================--
--           FUNCTIONS            --
--================================--

-- Fire essentials

function createFire(coords, maximumSpread, spreadChance)
	maximumSpread = maximumSpread and maximumSpread or Config.Fire.maximumSpreads
	spreadChance = spreadChance and spreadChance or Config.Fire.fireSpreadChance

	local fireIndex = highestIndex(activeFires)
	fireIndex = fireIndex + 1

	activeFires[fireIndex] = {
		maxSpread = maxSpread,
		spreadChance = spreadChance
	}

	createFlame(fireIndex, coords)

	local spread = true

	-- Spreading
	Citizen.CreateThread(
		function()
			while spread do
				Citizen.Wait(1000)
				local index, flames = highestIndex(activeFires, fireIndex)
				if flames ~= 0 and flames <= maximumSpread then
					for k, v in ipairs(activeFires[fireIndex]) do
						index, flames = highestIndex(activeFires, fireIndex)
						local rndSpread = math.random(100)
						if count ~= 0 and flames <= maximumSpread and rndSpread <= spreadChance then
							local x = activeFires[fireIndex][k].x
							local y = activeFires[fireIndex][k].y
							local z = activeFires[fireIndex][k].z
	
							local xSpread = math.random(-2, 2)
							local ySpread = math.random(-2, 2)
	
							coords = vector3(x + xSpread, y + ySpread, z)
	
							createFlame(fireIndex, coords)
						end
					end
				elseif flames == 0 then
					break
				end
			end
		end
	)

	activeFires[fireIndex].stopSpread = function()
		spread = false
	end

	return fireIndex
end

function createFlame(fireIndex, coords)
	local flameIndex = highestIndex(activeFires, fireIndex) + 1
	activeFires[fireIndex][flameIndex] = coords
	TriggerClientEvent('fireClient:createFlame', -1, fireIndex, flameIndex, coords)
end

function removeFire(fireIndex)
	if not (activeFires[fireIndex] and next(activeFires[fireIndex])) then
		return false
	end
	activeFires[fireIndex].stopSpread()
	TriggerClientEvent('fireClient:removeFire', -1, fireIndex)
	activeFires[fireIndex] = {}
	return true
end

function removeFlame(fireIndex, flameIndex)
	if activeFires[fireIndex] and activeFires[fireIndex][flameIndex] then
		activeFires[fireIndex][flameIndex] = nil
	end
	TriggerClientEvent('fireClient:removeFlame', -1, fireIndex, flameIndex)
end

function removeAllFires()
	TriggerClientEvent('fireClient:removeAllFires', -1)
	activeFires = {}
	boundFires = {}
end

function registerFire(coords)
	local registeredFireID = highestIndex(registeredFires) + 1

	registeredFires[registeredFireID] = {
		flames = {}
	}

	if coords then
		registeredFires[registeredFireID].dispatchCoords = coords
	end

	return registeredFireID
end

-- Whitelist

function checkWhitelist(serverId)
	if serverId then
		source = serverId
	end
	if source > 0 then
		local steamID = GetPlayerIdentifier(source, 0)
		if whitelistedPlayers[steamID] == true or IsPlayerAceAllowed(source, "firescript.all") then
			whitelist[source] = true
		elseif whitelist[source] ~= nil then
			whitelist[source] = nil
		end
	end
end

function isWhitelisted(source)
	return (source > 0 and whitelist[source] == true)
end

function addToWhitelist(serverId, steamId)
	whitelist[serverId] = true
	whitelistedPlayers[steamId] = true
end

function removeFromWhitelist(serverId, steamId)
	whitelist[serverId] = nil
	whitelistedPlayers[steamId] = nil
end

function loadWhitelist()
	local whitelistFile = loadData("whitelist")
	if whitelistFile ~= nil then
		whitelistedPlayers = whitelistFile
		for _, playerId in ipairs(GetPlayers()) do
			checkWhitelist(tonumber(playerId))
		end
	else
		saveData({}, "whitelist")
	end
end

function saveWhitelist()
	saveData(whitelistedPlayers, "whitelist")
end

-- Dispatch

function addToDispatch(source)
	dispatchPlayers[source] = true
end

function removeFromDispatch(source)
	dispatchPlayers[source] = nil
end

function createDispatch(text, coords)
	if not (text and coords) then
		return
	end

	lastDispatchNumber = lastDispatchNumber + 1

	for k, v in pairs(dispatchPlayers) do
		sendMessage(k, text, ("Dispatch (#%s)"):format(lastDispatchNumber))
		TriggerClientEvent('fireClient:createDispatch', k, lastDispatchNumber, coords)
	end
end

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
	return json.decode(LoadResourceFile(GetCurrentResourceName(), keyword .. ".json"))
end

--================================--
--           FIRE SYNC            --
--================================--

RegisterNetEvent('fireManager:requestSync')
AddEventHandler(
	'fireManager:requestSync',
	function()
		if source > 0 then
			TriggerClientEvent('fireClient:synchronizeFlames', source, activeFires)
		end
	end
)

RegisterNetEvent('fireManager:createFlame')
AddEventHandler(
	'fireManager:createFlame',
	createFlame
)

RegisterNetEvent('fireManager:createFire')
AddEventHandler(
	'fireManager:createFire',
	createFire
)

RegisterNetEvent('fireManager:removeFire')
AddEventHandler(
	'fireManager:removeFire',
	removeFire
)

RegisterNetEvent('fireManager:removeAllFires')
AddEventHandler(
	'fireManager:removeAllFires',
	removeAllFires
)

RegisterNetEvent('fireManager:removeFlame')
AddEventHandler(
	'fireManager:removeFlame',
	removeFlame
)

--================================--
--           DISPATCH             --
--================================--

RegisterNetEvent('fireDispatch:registerPlayer')
AddEventHandler(
	'fireDispatch:registerPlayer',
	function(playerSource)
		if source > 0 then
			return
		end

		dispatchPlayers[playerSource] = true
	end
)

RegisterNetEvent('fireDispatch:removePlayer')
AddEventHandler(
	'fireDispatch:removePlayer',
	function(playerSource)
		if source > 0 then
			return
		end

		dispatchPlayers[playerSource] = nil
	end
)

RegisterNetEvent('fireDispatch:create')
AddEventHandler(
	'fireDispatch:create',
	createDispatch
)

--================================--
--          WHITELIST             --
--================================--

RegisterNetEvent('fireManager:checkWhitelist')
AddEventHandler(
	'fireManager:checkWhitelist',
	checkWhitelist
)