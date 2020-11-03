--================================--
--        FIRE SCRIPT v1.3        --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

local activeFires = {}
local registeredFires = {}
local boundFires = {}

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
	function(fireIndex, flameIndex)
		removeFlame(fireIndex, flameIndex)
	end
)

--================================--
--           COMMANDS             --
--================================--

TriggerEvent('es:addAdminCommand', 'startfire', Config.AdminLevel, 
	function(source, args, user)
		local coords = nil
		local _source = source

		local maxSpread = (args[1] ~= nil and tonumber(args[1]) ~= nil) and tonumber(args[1]) or Config.Fire.maximumSpreads
		local probability = (args[2] ~= nil and tonumber(args[2]) ~= nil) and tonumber(args[2]) or Config.Fire.fireSpreadChance

		coords = GetEntityCoords(GetPlayerPed(source))
		local fireIndex = createFire(coords, maxSpread, probability)

		sendMessage(source, "Created fire #" .. fireIndex)

		if args[3] == "true" then
			Citizen.SetTimeout(
				Config.DispatchTimeout,
				function()
					TriggerClientEvent('fd:dispatch', _source, coords)
				end
			)
		end
	end,
	function(source, args, user)
		-- The user isn't administrator
	end,
	{
		help = "Creates a fire",
		params = {
			{
				name = "spread",
				help = "How many times can the fire spread?"
			},
			{
				name = "chance",
				help = "0 - 100; How quickly the fire spreads?"
			},
			{
				name = "dispatch",
				help = "true or false (default false)"
			}
		}
	}
)

TriggerEvent('es:addAdminCommand', 'stopfire', Config.AdminLevel, 
	function(source, args, user)
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
	function(source, args, user)
		-- The user isn't administrator
	end,
	{
		help = "Stops the fire",
		params = {
			{
				name = "index",
				help = "The fire's index"
			}
		}
	}
)

TriggerEvent('es:addAdminCommand', 'stopallfires', Config.AdminLevel, 
	function(source, args, user)
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
	function(source, args, user)
		-- The user isn't administrator
	end,
	{
		help = "Stops all the fires"
	}
)

TriggerEvent('es:addAdminCommand', 'registerfire', Config.AdminLevel, 
	function(source, args, user)
		local coords = nil

		if not (args[1] == nil or args[1] == "false") then
			coords = GetEntityCoords(GetPlayerPed(source))
		end

		local registeredFireID = registerFire(coords)

		sendMessage(source, "Registered fire #" .. registeredFireID)
	end,
	function(source, args, user)
		-- The user isn't administrator
	end,
	{
		help = "Registers a new fire configuration",
		params = {
			{
				name = "dispatch",
				help = "Should the fire trigger dispatch? (default true)"
			}
		}
	}
)

TriggerEvent('es:addAdminCommand', 'addflame', Config.AdminLevel, 
	function(source, args, user)
		local registeredFireID = tonumber(args[1])
		local spread = tonumber(args[2])
		local chance = tonumber(args[3])

		if not (registeredFireID and spread and chance) then
			return
		end

		if not registeredFires[registeredFireID] then
			sendMessage(source, "No such fire registered.")
			return
		end

		local coords = GetEntityCoords(GetPlayerPed(source))

		local flameID = highestIndex(registeredFires[registeredFireID].flames) + 1
		registeredFires[registeredFireID].flames[flameID] = {}
		registeredFires[registeredFireID].flames[flameID].coords = coords
		registeredFires[registeredFireID].flames[flameID].spread = spread
		registeredFires[registeredFireID].flames[flameID].chance = chance

		sendMessage(source, "Registered flame #" .. flameID)
	end,
	function(source, args, user)
		-- The user isn't administrator
	end,
	{
		help = "Adds a flame to a registered fire.",
		params = {
			{
				name = "fireID",
				help = "The registered fire"
			},
			{
				name = "spread",
				help = "How many times can the flame spread?"
			},
			{
				name = "chance",
				help = "How many out of 100 chances should the fire spread? (0-100)"
			}
		}
	}
)

TriggerEvent('es:addAdminCommand', 'removeflame', Config.AdminLevel, 
	function(source, args, user)
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
	function(source, args, user)
		-- The user isn't administrator
	end,
	{
		help = "Removes a flame from a registered fire",
		params = {
			{
				name = "fireID",
				help = "The fire ID"
			},
			{
				name = "flameID",
				help = "The flame ID"
			}
		}
	}
)

TriggerEvent('es:addAdminCommand', 'removefire', Config.AdminLevel, 
	function(source, args, user)
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
	function(source, args, user)
		-- The user isn't administrator
	end,
	{
		help = "Removes a flame from a registered fire",
		params = {
			{
				name = "fireID",
				help = "The fire ID"
			}
		}
	}
)

TriggerEvent('es:addAdminCommand', 'startregisteredfire', Config.AdminLevel, 
	function(source, args, user)
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
				Config.DispatchTimeout,
				function()
					TriggerClientEvent('fd:dispatch', _source, dispatchCoords)
				end
			)
		end

		sendMessage(source, "Started registered fire #" .. registeredFireID)
	end,
	function(source, args, user)
		-- The user isn't administrator
	end,
	{
		help = "Starts a registered fire",
		params = {
			{
				name = "fireID",
				help = "The fire ID"
			}
		}
	}
)

TriggerEvent('es:addAdminCommand', 'stopregisteredfire', Config.AdminLevel, 
	function(source, args, user)
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
	function(source, args, user)
		-- The user isn't administrator
	end,
	{
		help = "Stops a registered fire",
		params = {
			{
				name = "fireID",
				help = "The fire ID"
			}
		}
	}
)

--================================--
--           FUNCTIONS            --
--================================--

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
	
							local newX = x + xSpread
							local newY = y + ySpread
	
							coords = vector3(newX, newY, z)
	
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

function sendMessage(source, text)
	TriggerClientEvent(
		"chat:addMessage",
		source,
		{
			templateId = "firescript",
			args = {
				text
			}
		}
	)
end

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
