--================================--
--        FIRE SCRIPT v1.6        --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

local Fire = {
	registered = {},
	active = {},
	binds = {},
	__index = self,
	init = function(object)
		object = object or {registered = {}, active = {}, binds = {}}
		setmetatable(object, self)
		self.__index = self
		return object
	end
}

local Whitelist = {
	players = {},
	config = {},
	__index = self,
	init = function(object)
		object = object or {players = {}, config = {}}
		setmetatable(object, self)
		return object
	end
}

local Dispatch = {
	players = {},
	lastNumber = 0,
	__index = self,
	init = function(object)
		object = object or {players = {}, lastNumber = 0}
		setmetatable(object, self)
		return object
	end
}

--================================--
--          INITIALIZE            --
--================================--

function onResourceStart(resourceName)
	if (GetCurrentResourceName() == resourceName) then
		Whitelist:load()
		Fire:loadRegistered()
	end
end

function onResourceStop(resourceName)
	if (GetCurrentResourceName() == resourceName) then
		Whitelist:save()
		Fire:saveRegistered()
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
	Dispatch:removePlayer(source)
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
		if not Whitelist:isWhitelisted(source) then
			return
		end
		local _source = source

		local maxSpread = (maxSpread ~= nil and tonumber(maxSpread) ~= nil) and tonumber(maxSpread) or Config.Fire.maximumSpreads
		local chance = (chance ~= nil and tonumber(chance) ~= nil) and tonumber(chance) or Config.Fire.fireSpreadChance

		local fireIndex = Fire:create(coords, maxSpread, chance)

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
		if not Whitelist:isWhitelisted(source) then
			return
		end

		local registeredFireID = Fire:register(triggerDispatch and coords or nil)

		sendMessage(source, "Registered fire #" .. registeredFireID)
	end
)

RegisterNetEvent('fireManager:command:addflame')
AddEventHandler(
	'fireManager:command:addflame',
	function(registeredFireID, coords, spread, chance)
		if not Whitelist:isWhitelisted(source) then
			return
		end
		local registeredFireID = tonumber(registeredFireID)
		local spread = tonumber(spread)
		local chance = tonumber(chance)

		if not (coords and registeredFireID and spread and chance) then
			return
		end

		local flameID = Fire:addFlame(registeredFireID, spread, chance)

		if not flameID then
			sendMessage(source, "No such fire registered.")
			return
		end

		sendMessage(source, "Registered flame #" .. flameID)
	end
)

RegisterCommand(
	'stopfire',
	function(source, args, rawCommand)
		if not Whitelist:isWhitelisted(source) then
			return
		end
		local fireIndex = tonumber(args[1])
		if not fireIndex then
			return
		end
		if Fire:remove(fireIndex) then
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
		if not Whitelist:isWhitelisted(source) then
			return
		end
		Fire:removeAll()
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
		if not Whitelist:isWhitelisted(source) then
			return
		end
		local registeredFireID = tonumber(args[1])
		local flameID = tonumber(args[2])

		if not (registeredFireID and flameID) then
			return
		end

		local success = Fire:deleteFlame(registeredFireID, flameID)

		if not success then
			sendMessage(source, "No such fire or flame registered.")
			return
		end

		sendMessage(source, "Removed flame #" .. flameID)
	end,
	false
)

RegisterCommand(
	'removefire',
	function(source, args, rawCommand)
		if not Whitelist:isWhitelisted(source) then
			return
		end
		local registeredFireID = tonumber(args[1])
		if not registeredFireID then
			return
		end

		local success = Fire:deleteRegistered(registeredFireID)

		if not success then
			sendMessage(source, "No such fire or flame registered.")
			return
		end

		sendMessage(source, "Removed fire #" .. registeredFireID)
	end,
	false
)

RegisterCommand(
	'startregisteredfire',
	function(source, args, rawCommand)
		if not Whitelist:isWhitelisted(source) then
			return
		end
		local _source = source
		local registeredFireID = tonumber(args[1])

		if not registeredFireID then
			return
		end

		local success = Fire:startRegistered(registeredFireID)

		if not success then
			sendMessage(source, "No such fire or flame registered.")
			return
		end

		sendMessage(source, "Started registered fire #" .. registeredFireID)
	end,
	false
)

RegisterCommand(
	'stopregisteredfire',
	function(source, args, rawCommand)
		if not Whitelist:isWhitelisted(source) then
			return
		end
		local _source = source
		local registeredFireID = tonumber(args[1])

		if not registeredFireID then
			return
		end

		local success = Fire:stopRegistered(registeredFireID)

		if not success then
			sendMessage(source, "No such fire active.")
			return
		end

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
			Whitelist:addPlayer(serverId, identifier)
			sendMessage(source, ("Added %s to the whitelist."):format(GetPlayerName(serverId)))
		elseif action == "remove" then
			Whitelist:removePlayer(serverId, identifier)
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
		Whitelist:load()
		sendMessage(source, "Reloaded whitelist from config.")
	end,
	true
)

RegisterCommand(
	'firewlsave',
	function(source, args, rawCommand)
		Whitelist:save()
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
			Dispatch:addPlayer(serverId)
			sendMessage(source, ("Subscribed %s to dispatch."):format(GetPlayerName(serverId)))
		elseif action == "remove" then
			Whitelist:removePlayer(serverId, identifier)
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

function Fire:create(coords, maximumSpread, spreadChance)
	maximumSpread = maximumSpread and maximumSpread or Config.Fire.maximumSpreads
	spreadChance = spreadChance and spreadChance or Config.Fire.fireSpreadChance

	local fireIndex = highestIndex(self.active)
	fireIndex = fireIndex + 1

	self.active[fireIndex] = {
		maxSpread = maxSpread,
		spreadChance = spreadChance
	}

	self:createFlame(fireIndex, coords)

	local spread = true

	-- Spreading
	Citizen.CreateThread(
		function()
			while spread do
				Citizen.Wait(2000)
				local index, flames = highestIndex(self.active, fireIndex)
				if flames ~= 0 and flames <= maximumSpread then
					for k, v in ipairs(self.active[fireIndex]) do
						index, flames = highestIndex(self.active, fireIndex)
						local rndSpread = math.random(100)
						if count ~= 0 and flames <= maximumSpread and rndSpread <= spreadChance then
							local x = self.active[fireIndex][k].x
							local y = self.active[fireIndex][k].y
							local z = self.active[fireIndex][k].z
	
							local xSpread = math.random(-2, 2)
							local ySpread = math.random(-2, 2)
	
							coords = vector3(x + xSpread, y + ySpread, z)
	
							self:createFlame(fireIndex, coords)
						end
					end
				elseif flames == 0 then
					break
				end
			end
		end
	)

	self.active[fireIndex].stopSpread = function()
		spread = false
	end

	return fireIndex
end

function Fire:createFlame(fireIndex, coords)
	local flameIndex = highestIndex(self.active, fireIndex) + 1
	self.active[fireIndex][flameIndex] = coords
	TriggerClientEvent('fireClient:createFlame', -1, fireIndex, flameIndex, coords)
end

function Fire:remove(fireIndex)
	if not (self.active[fireIndex] and next(self.active[fireIndex])) then
		return false
	end
	self.active[fireIndex].stopSpread()
	TriggerClientEvent('fireClient:removeFire', -1, fireIndex)
	self.active[fireIndex] = {}
	return true
end

function Fire:removeFlame(fireIndex, flameIndex)
	if self.active[fireIndex] and self.active[fireIndex][flameIndex] then
		self.active[fireIndex][flameIndex] = nil
	end
	TriggerClientEvent('fireClient:removeFlame', -1, fireIndex, flameIndex)
end

function Fire:removeAll()
	TriggerClientEvent('fireClient:removeAllFires', -1)
	for k, v in pairs(self.active) do
		if v.stopSpread then
			v.stopSpread()
		end
	end
	self.active = {}
	self.binds = {}
end

function Fire:register(coords)
	local registeredFireID = highestIndex(self.registered) + 1

	self.registered[registeredFireID] = {
		flames = {}
	}

	if coords then
		self.registered[registeredFireID].dispatchCoords = coords
	end

	return registeredFireID
end

function Fire:startRegistered(registeredFireID)
	if not self.registered[registeredFireID] then
		return false
	end

	self.binds[registeredFireID] = {}

	for k, v in pairs(self.registered[registeredFireID].flames) do
		local fireID = Fire:create(v.coords, v.spread, v.chance)
		table.insert(self.binds[registeredFireID], fireID)
		Citizen.Wait(10)
	end

	if self.registered[registeredFireID].dispatchCoords then
		local dispatchCoords = self.registered[registeredFireID].dispatchCoords
		Citizen.SetTimeout(
			Config.Dispatch.timeout,
			function()
				TriggerClientEvent('fd:dispatch', _source, dispatchCoords)
			end
		)
	end

	return true
end

function Fire:stopRegistered()
	if not self.binds[registeredFireID] then
		return false
	end

	for k, v in ipairs(self.binds[registeredFireID]) do
		Fire:remove(v)
		Citizen.Wait(10)
	end

	self.binds[registeredFireID] = {}

	return true
end

function Fire:deleteRegistered(registeredFireID)
	if not self.registered[registeredFireID] then
		return false
	end

	self.registered[registeredFireID] = nil
end

function Fire:addFlame(registeredFireID, spread, chance)
	if not (registeredFireID and spread and chance) or self.registered[registeredFireID] then
		return false
	end

	local flameID = highestIndex(self.registered[registeredFireID].flames) + 1

	self.registered[registeredFireID].flames[flameID] = {}
	self.registered[registeredFireID].flames[flameID].coords = coords
	self.registered[registeredFireID].flames[flameID].spread = spread
	self.registered[registeredFireID].flames[flameID].chance = chance

	return flameID
end

function Fire:deleteFlame(registeredFireID, flameID)
	if not (self.registered[registeredFireID] and self.registered[registeredFireID].flames[flameID]) then
		return false
	end

	table.remove(self.registered[registeredFireID].flames, flameID)
	return true
end

-- Whitelist

function Whitelist:check(serverId)
	if serverId then
		source = serverId
	end

	if source > 0 then
		local steamID = GetPlayerIdentifier(source, 0)
		if self.config[steamID] == true or IsPlayerAceAllowed(source, "firescript.all") then
			self.players[source] = true
		elseif self.players[source] ~= nil then
			self.players[source] = nil
		end
	end
end

function Whitelist:isWhitelisted(serverId)
	return (serverId > 0 and self.players[serverId] == true)
end

function Whitelist:addPlayer(serverId, steamId)
	self.player[serverId], self.config[steamId] = true, true
end

function Whitelist:removePlayer(serverId, steamId)
	self.player[serverId], self.config[steamId] = nil, nil
end

function Whitelist:load()
	local whitelistFile = loadData("whitelist")
	if whitelistFile ~= nil then
		self.config = whitelistFile
		for _, playerId in ipairs(GetPlayers()) do
			self:check(tonumber(playerId))
		end
	else
		saveData({}, "whitelist")
	end
end

function Whitelist:save()
	saveData(self.config, "whitelist")
end

-- Saving registered fires

function Fire:saveRegistered()
	saveData(self:registered, "fires")
end

function Fire:loadRegistered()
	local firesFile = loadData("fires")
	if firesFile ~= nil then
		for index, fire in pairs(firesFile) do
			for _, flame in pairs(fire.flames) do
				flame.coords = vector3(flame.coords.x, flame.coords.y, flame.coords.z)
			end
		end
		self.registered = firesFile
	else
		saveData({}, "fires")
	end
end

-- Dispatch

function Dispatch:create(text, coords)
	if not (text and coords) then
		return
	end

	self.lastNumber = self.lastNumber + 1

	for k, v in pairs(self.players) do
		sendMessage(k, text, ("Dispatch (#%s)"):format(self.lastNumber))
		TriggerClientEvent('fireClient:createDispatch', k, self.lastNumber, coords)
	end
end

function Dispatch:addPlayer(serverId)
	self.players[serverId] = true
end

function Dispatch:removePlayer(serverId)
	self.players[serverId] = nil
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
	local fileContents = LoadResourceFile(GetCurrentResourceName(), keyword .. ".json")
	return fileContents and json.decode(fileContents) or nil
end

--================================--
--           FIRE SYNC            --
--================================--

RegisterNetEvent('fireManager:requestSync')
AddEventHandler(
	'fireManager:requestSync',
	function()
		if source > 0 then
			TriggerClientEvent('fireClient:synchronizeFlames', source, Fire.active)
		end
	end
)

RegisterNetEvent('fireManager:createFlame')
AddEventHandler(
	'fireManager:createFlame',
	Fire:createFlame
)

RegisterNetEvent('fireManager:createFire')
AddEventHandler(
	'fireManager:createFire',
	Fire:create
)

RegisterNetEvent('fireManager:removeFire')
AddEventHandler(
	'fireManager:removeFire',
	Fire:remove
)

RegisterNetEvent('fireManager:removeAllFires')
AddEventHandler(
	'fireManager:removeAllFires',
	Fire:removeAll
)

RegisterNetEvent('fireManager:removeFlame')
AddEventHandler(
	'fireManager:removeFlame',
	Fire:removeFlame
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

		Dispatch:addPlayer(playerSource)
	end
)

RegisterNetEvent('fireDispatch:removePlayer')
AddEventHandler(
	'fireDispatch:removePlayer',
	function(playerSource)
		if source > 0 then
			return
		end

		Dispatch:removePlayer(playerSource)
	end
)

RegisterNetEvent('fireDispatch:create')
AddEventHandler(
	'fireDispatch:create',
	Dispatch:create
)

--================================--
--          WHITELIST             --
--================================--

RegisterNetEvent('fireManager:checkWhitelist')
AddEventHandler(
	'fireManager:checkWhitelist',
	Whitelist:check
)