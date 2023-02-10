--================================--
--       FIRE SCRIPT v1.7.6       --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

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
	},
	{
		name = "dispatchMessage",
		help = "Sets a custom dispatch message (leave empty to generate automatically)"
	}
})

TriggerEvent('chat:addSuggestion', '/stopfire', 'Stops the fire', {
	{
		name = "index",
		help = "The fire's index"
	}
})

TriggerEvent('chat:addSuggestion', '/stopallfires', 'Stops all fires')

TriggerEvent('chat:addSuggestion', '/registerscenario', 'Registers a new fire configuration')

TriggerEvent('chat:addSuggestion', '/addflame', 'Adds a flame to a scenario', {
	{
		name = "scenarioID",
		help = "The scenario"
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

TriggerEvent('chat:addSuggestion', '/removeflame', 'Removes a flame from a scenario', {
	{
		name = "scenarioID",
		help = "The fire ID"
	},
	{
		name = "flameID",
		help = "The flame ID"
	}
})

TriggerEvent('chat:addSuggestion', '/removescenario', 'Removes a scenario', {
	{
		name = "scenarioID",
		help = "The fire ID"
	}
})

TriggerEvent('chat:addSuggestion', '/startscenario', 'Starts a scenario', {
	{
		name = "scenarioID",
		help = "The fire ID"
	},
	{
		name = "triggerDispatch",
		help = "true / false - should the script trigger dispatch after spawning the fire? (default false)"
	}
})

TriggerEvent('chat:addSuggestion', '/stopscenario', 'Stops a scenario', {
	{
		name = "scenarioID",
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
		help = "add / remove / scenario (scenario = sets the scenario's dispatch message)"
	},
	{
		name = "playerID / scenarioID",
		help = "The player's server ID / the scenario's ID"
	},
	{
		name = "dispatchMessage",
		help = "(optional) Sets a custom dispatch message for the scenario (use only with par. #1 scenario; leave empty to remove previous custom message)"
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
		help = "(optional) The dispatch identifier, if filled in, the call's blip will be removed. Set to 0 to remove all dispatch blips."
	}
})

TriggerEvent('chat:addSuggestion', '/randomfires', 'Manages the random fire spawner', {
	{
		name = "action",
		help = "add / remove / enable / disable"
	},
	{
		name = "p2",
		help = "(optional) For add / remove action, fill in the scenario ID."
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

		table.remove(args, 1)
		table.remove(args, 1)
		table.remove(args, 1)

		local dispatchMessage = next(args) and table.concat(args, " ") or nil

		TriggerServerEvent('fireManager:command:startfire', GetEntityCoords(GetPlayerPed(-1)), maxSpread, probability, triggerDispatch, dispatchMessage)
	end,
	false
)

RegisterCommand(
	'registerscenario',
	function(source, args, rawCommand)
		local coords = nil

		local x = tonumber(args[1])
		local y = tonumber(args[2])
		local z = tonumber(args[3])

		if x and y and z then
			coords = vector3(x, y, z)
		end

		TriggerServerEvent('fireManager:command:registerscenario', coords or GetEntityCoords(GetPlayerPed(-1)))
	end,
	false
)

RegisterCommand(
	'addflame',
	function(source, args, rawCommand)
		local registeredFireID = tonumber(args[1])
		local spread = tonumber(args[2])
		local chance = tonumber(args[3])

		local coords = nil

		local x = tonumber(args[4])
		local y = tonumber(args[5])
		local z = tonumber(args[6])

		if x and y and z then
			coords = vector3(x, y, z)
		end

		if registeredFireID and spread and chance then
			TriggerServerEvent('fireManager:command:addflame', registeredFireID, coords or GetEntityCoords(GetPlayerPed(-1)), spread, chance)
		end
	end,
	false
)

-- Aliases

RegisterCommand(
	'registerfire',
	function(source, args, rawCommand)
		ExecuteCommand("registerscenario" .. rawCommand:sub(13))
	end,
	false
)

RegisterCommand(
	'removeregisteredfire',
	function(source, args, rawCommand)
		ExecuteCommand("removescenario" .. rawCommand:sub(21))
	end,
	false
)

RegisterCommand(
	'startregisteredfire',
	function(source, args, rawCommand)
		ExecuteCommand("startscenario" .. rawCommand:sub(20))
	end,
	false
)

RegisterCommand(
	'stopregisteredfire',
	function(source, args, rawCommand)
		ExecuteCommand("stopscenario" .. rawCommand:sub(19))
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
		syncInProgress = true
		Fire:remove(fireIndex)
		syncInProgress = false
	end
)

RegisterNetEvent('fireClient:removeAllFires')
AddEventHandler(
	'fireClient:removeAllFires',
	function()
		while syncInProgress do
			Citizen.Wait(10)
		end
		syncInProgress = true
		Fire:removeAll(
			function()
				syncInProgress = false
			end
		)
	end
)

RegisterNetEvent("fireClient:removeFlame")
AddEventHandler(
    "fireClient:removeFlame",
	function(fireIndex, flameIndex)
		while syncInProgress do
			Citizen.Wait(10)
		end
		syncInProgress = true
		Fire:removeFlame(fireIndex, flameIndex)
		syncInProgress = false
    end
)

RegisterNetEvent("fireClient:createFlame")
AddEventHandler(
    "fireClient:createFlame",
	function(fireIndex, flameIndex, coords)
		while syncInProgress do
			Citizen.Wait(10)
		end
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

--================================--
--     DISPATCH ROUTE for AUTO-SUBSCRIBE     --
--================================--

if Config.Framework == "qb" then
	QBCore = exports['qb-core']:GetCoreObject()
	PlayerJob = {}
	local PlayerData = QBCore.Functions.GetPlayerData()

	RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
		QBCore.Functions.GetPlayerData(function(PlayerData)
			PlayerJob = PlayerData.job
			onDuty = PlayerData.job.onduty
			if PlayerData.job.onduty then
				if PlayerData.job.name == Config.Dispatch.JobName then
					TriggerServerEvent("fire:server:Adddispatch")
					QBCore.Functions.Notify("Your subscribe to fire call!", "success", 1000) 
				end
			end
		end)
	end)
	
	RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
		QBCore.Functions.GetPlayerData(function(PlayerData)
			PlayerJob = PlayerData.job
			if PlayerData.job.name == Config.Dispatch.JobName and onDuty then
				TriggerServerEvent("fire:server:Removedispatch")
				QBCore.Functions.Notify("Your unsubscribe from fire call!", "error", 1000) 
			end
		end)
	end)
	
	
	RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
		PlayerJob = JobInfo
		if JobInfo.name == Config.Dispatch.JobName then
			TriggerServerEvent("fire:server:Adddispatch")
			QBCore.Functions.Notify("Your subscribe to fire call!", "success", 1000) 
		else
			TriggerServerEvent("fire:server:Removedispatch")
			OnDuty = false
			--QBCore.Functions.Notify("Your unsubscribe from fire call!", "error", 1000)   
		end
	end)	
end
