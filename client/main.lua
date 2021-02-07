--================================--
--       FIRE SCRIPT v1.6.10      --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

local syncInProgress = false

--================================--
--              CHAT              --
--================================--

TriggerEvent("chat:addTemplate", "firescript", '<div style="text-indent: 0 !important; padding: 0.5vw; margin: 0.05vw; color: rgba(255,255,255,0.9);background-color: rgba(250,26,56, 0.8); border-radius: 4px;"><b>{0}</b> {1} </div>')

TriggerEvent('chat:addSuggestion', '/startfire', 'Creates a fire', {
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
})

TriggerEvent('chat:addSuggestion', '/stopfire', 'Stops the fire', {
	{
		name = "index",
		help = "The fire's index"
	}
})

TriggerEvent('chat:addSuggestion', '/stopallfires', 'Stops all fires')

TriggerEvent('chat:addSuggestion', '/registerfire', 'Registers a new fire configuration')

TriggerEvent('chat:addSuggestion', '/addflame', 'Adds a flame to a registered fire', {
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
})

TriggerEvent('chat:addSuggestion', '/removeflame', 'Removes a flame from a registered fire', {
	{
		name = "fireID",
		help = "The fire ID"
	},
	{
		name = "flameID",
		help = "The flame ID"
	}
})

TriggerEvent('chat:addSuggestion', '/removefire', 'Removes a registered fire', {
	{
		name = "fireID",
		help = "The fire ID"
	}
})

TriggerEvent('chat:addSuggestion', '/startregisteredfire', 'Starts a registered fire', {
	{
		name = "fireID",
		help = "The fire ID"
	},
	{
		name = "triggerDispatch",
		help = "true / false - should the script trigger dispatch after spawning the fire? (default false)"
	}
})

TriggerEvent('chat:addSuggestion', '/stopregisteredfire', 'Stops a registered fire', {
	{
		name = "fireID",
		help = "The fire ID"
	}
})

TriggerEvent('chat:addSuggestion', '/firewl', 'Manages the fire script whitelist', {
	{
		name = "action",
		help = "add / remove"
	},
	{
		name = "playerID",
		help = "The player's server ID"
	}
})

TriggerEvent('chat:addSuggestion', '/firewlreload', 'Reloads the whitelist from the config')

TriggerEvent('chat:addSuggestion', '/firedispatch', 'Manages the fire script dispatch subscribers', {
	{
		name = "action",
		help = "add / remove"
	},
	{
		name = "playerID",
		help = "The player's server ID"
	}
})

TriggerEvent('chat:addSuggestion', '/remindme', 'Sets the GPS waypoint to the specified dispatch call.', {
	{
		name = "dispatchID",
		help = "The dispatch identifier (number)"
	}
})

TriggerEvent('chat:addSuggestion', '/cleardispatch', 'Clears navigation to the last dispatch call.', {
	{
		name = "dispatchID",
		help = "(optional) The dispatch identifier, if filled in, the call's blip will be removed."
	}
})

TriggerEvent('chat:addSuggestion', '/randomfires', 'Manages the random fire spawner', {
	{
		name = "action",
		help = "add / remove / enable / disable"
	},
	{
		name = "p2",
		help = "(optional) For add / remove action, fill in the registered fire ID."
	}
})

--================================--
--        SYNC ON CONNECT         --
--================================--

RegisterNetEvent('playerSpawned')
AddEventHandler(
	'playerSpawned',
	function()
		print("Requested synchronization..")
		TriggerServerEvent('fireManager:requestSync')
	end
)

RegisterNetEvent('onClientResourceStart')
AddEventHandler(
	'onClientResourceStart',
	function(resourceName)
		if resourceName == GetCurrentResourceName() then
			-- Check the command whitelist
			TriggerServerEvent('fireManager:checkWhitelist')
		end
	end
)

--================================--
--            COMMANDS            --
--================================--

RegisterCommand(
	'remindme',
	function(source, args, rawCommand)
		local dispatchNumber = tonumber(args[1])
		if not dispatchNumber then
			sendMessage("Invalid argument.")
			return
		end

		local success = Dispatch:remind(dispatchNumber)

		if not success then
			sendMessage("Couldn't find the specified dispatch.")
			return
		end
	end,
	false
)

RegisterCommand(
	'cleardispatch',
	function(source, args, rawCommand)
		Dispatch:clear(tonumber(args[1]))
	end,
	false
)

RegisterCommand(
	'startfire',
	function(source, args, rawCommand)
		local maxSpread = tonumber(args[1])
		local probability = tonumber(args[2])
		local triggerDispatch = args[3] == "true"

		TriggerServerEvent('fireManager:command:startfire', GetEntityCoords(GetPlayerPed(-1)), maxSpread, probability, triggerDispatch)
	end,
	false
)

RegisterCommand(
	'registerfire',
	function(source, args, rawCommand)
		TriggerServerEvent('fireManager:command:registerfire', GetEntityCoords(GetPlayerPed(-1)))
	end,
	false
)

RegisterCommand(
	'addflame',
	function(source, args, rawCommand)
		local registeredFireID = tonumber(args[1])
		local spread = tonumber(args[2])
		local chance = tonumber(args[3])

		if registeredFireID and spread and chance then
			TriggerServerEvent('fireManager:command:addflame', registeredFireID, GetEntityCoords(GetPlayerPed(-1)), spread, chance)
		end
	end,
	false
)

--================================--
--             EVENTS             --
--================================--

RegisterNetEvent('fireClient:synchronizeFlames')
AddEventHandler(
	'fireClient:synchronizeFlames',
	function(fires)
		syncInProgress = true
		Fire:removeAll(
			function()
				for k, v in pairs(fires) do
					for _k, _v in ipairs(v) do
						Fire:createFlame(k, _k, _v)
					end
				end
				syncInProgress = false
			end
		)
	end
)

RegisterNetEvent('fireClient:removeFire')
AddEventHandler(
	'fireClient:removeFire',
	function(fireIndex)
		while syncInProgress do
			Citizen.Wait(10)
		end
		Fire:remove(fireIndex)
	end
)

RegisterNetEvent('fireClient:removeAllFires')
AddEventHandler(
	'fireClient:removeAllFires',
	function()
		while syncInProgress do
			Citizen.Wait(10)
		end
		Fire:removeAll()
	end
)

RegisterNetEvent("fireClient:removeFlame")
AddEventHandler(
    "fireClient:removeFlame",
	function(fireIndex, flameIndex)
		while syncInProgress do
			Citizen.Wait(10)
		end
		Fire:removeFlame(fireIndex, flameIndex)
    end
)

RegisterNetEvent("fireClient:createFlame")
AddEventHandler(
    "fireClient:createFlame",
	function(fireIndex, flameIndex, coords)
		syncInProgress = true
		Fire:createFlame(fireIndex, flameIndex, coords)
		syncInProgress = false
    end
)

-- Dispatch

if Config.Dispatch.enabled == true then
	RegisterNetEvent('fd:dispatch')
	AddEventHandler(
		'fd:dispatch',
		function(coords)
			local streetName, crossingRoad = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
			local streetName = GetStreetNameFromHashKey(streetName)
			local text = ("A fire broke out at %s."):format((crossingRoad > 0) and streetName .. " / " .. GetStreetNameFromHashKey(crossingRoad) or streetName)
			TriggerServerEvent('fireDispatch:create', text, coords)
		end
	)
end

RegisterNetEvent('fireClient:createDispatch')
AddEventHandler(
	'fireClient:createDispatch',
	function(dispatchNumber, coords)
		Dispatch:create(dispatchNumber, coords)
	end
)
