--================================--
--       FIRE SCRIPT v1.7.6       --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

--================================--
--         VERSION CHECK          --
--================================--

Version = "1.7.6"
LatestVersionFeed = "https://api.github.com/repos/gimicze/firescript/releases/latest"

Citizen.CreateThread(
	checkVersion
)

--================================--
--          INITIALIZE            --
--================================--

function onResourceStart(resourceName)
	if (GetCurrentResourceName() == resourceName) then
		Whitelist:load()
		Fire:loadRegistered()
		if Config.Fire.spawner.enableOnStartup and Config.Fire.spawner.interval then
			if not Fire:startSpawner() then
				sendMessage(0, "Couldn't start fire spawner.")
			end
		end
	end
end

RegisterNetEvent('onResourceStart')
AddEventHandler(
	'onResourceStart',
	onResourceStart
)

--================================--
--           CLEAN-UP             --
--================================--

function onPlayerDropped()
	Whitelist:removePlayer(source)
	Dispatch:unsubscribe(source)
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
	function(coords, maxSpread, chance, triggerDispatch, dispatchMessage)
		if not Whitelist:isWhitelisted(source, "firescript.start") then
			sendMessage(source, "Insufficient permissions.")
			return
		end

		local _source = source

		local maxSpread = (maxSpread ~= nil and tonumber(maxSpread) ~= nil) and tonumber(maxSpread) or Config.Fire.maximumSpreads
		local chance = (chance ~= nil and tonumber(chance) ~= nil) and tonumber(chance) or Config.Fire.fireSpreadChance

		local fireIndex = Fire:create(coords, maxSpread, chance)

		sendMessage(source, "Spawned fire #" .. fireIndex)

		if triggerDispatch then
			Citizen.SetTimeout(
				Config.Dispatch.timeout,
				function()
					if Config.Dispatch.enabled and not Config.Dispatch.disableCalls then
						if dispatchMessage then
							Dispatch:create(dispatchMessage, coords)
						else
							Dispatch.expectingInfo[_source] = true
							TriggerClientEvent('fd:dispatch', _source, coords)
						end
					end
				end
			)
		end
	end
)

RegisterNetEvent('fireManager:command:registerscenario')
AddEventHandler(
	'fireManager:command:registerscenario',
	function(coords)
		if not Whitelist:isWhitelisted(source, "firescript.manage") then
			sendMessage(source, "Insufficient permissions.")
			return
		end

		local registeredFireID = Fire:register(coords)

		sendMessage(source, "Created scenario #" .. registeredFireID)
	end
)

RegisterNetEvent('fireManager:command:addflame')
AddEventHandler(
	'fireManager:command:addflame',
	function(registeredFireID, coords, spread, chance)
		if not Whitelist:isWhitelisted(source, "firescript.manage") then
			sendMessage(source, "Insufficient permissions.")
			return
		end

		local registeredFireID = tonumber(registeredFireID)
		local spread = tonumber(spread)
		local chance = tonumber(chance)

		if not (coords and registeredFireID and spread and chance) then
			return
		end

		local flameID = Fire:addFlame(registeredFireID, coords, spread, chance)

		if not flameID then
			sendMessage(source, "No such scenario.")
			return
		end

		sendMessage(source, "Added flame #" .. flameID)
	end
)

RegisterCommand(
	'stopfire',
	function(source, args, rawCommand)
		if not Whitelist:isWhitelisted(source, "firescript.stop") then
			sendMessage(source, "Insufficient permissions.")
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
		if not Whitelist:isWhitelisted(source, "firescript.stop") then
			sendMessage(source, "Insufficient permissions.")
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
		if not Whitelist:isWhitelisted(source, "firescript.manage") then
			sendMessage(source, "Insufficient permissions.")
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
	'removescenario',
	function(source, args, rawCommand)
		if not Whitelist:isWhitelisted(source, "firescript.manage") then
			sendMessage(source, "Insufficient permissions.")
			return
		end
		local registeredFireID = tonumber(args[1])
		if not registeredFireID then
			return
		end

		local success = Fire:deleteRegistered(registeredFireID)

		if not success then
			sendMessage(source, "No such scenario.")
			return
		end

		sendMessage(source, "Removed scenario #" .. registeredFireID)
	end,
	false
)

RegisterCommand(
	'startscenario',
	function(source, args, rawCommand)
		if not Whitelist:isWhitelisted(source, "firescript.start") then
			sendMessage(source, "Insufficient permissions.")
			return
		end
		local _source = source
		local registeredFireID = tonumber(args[1])
		local triggerDispatch = args[2] == "true"

		if not registeredFireID then
			return
		end

		local success = Fire:startRegistered(registeredFireID, triggerDispatch, source)

		if not success then
			sendMessage(source, "No such scenario.")
			return
		end

		sendMessage(source, "Started scenario #" .. registeredFireID)
	end,
	false
)

RegisterCommand(
	'stopscenario',
	function(source, args, rawCommand)
		if not Whitelist:isWhitelisted(source, "firescript.stop") then
			sendMessage(source, "Insufficient permissions.")
			return
		end
		local _source = source
		local registeredFireID = tonumber(args[1])

		if not registeredFireID then
			return
		end

		local success = Fire:stopRegistered(registeredFireID)

		if not success then
			sendMessage(source, "No such scenario active.")
			return
		end

		sendMessage(source, "Stopping scenario #" .. registeredFireID)

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

		if not (action and serverId) or serverId < 1 then
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

		if not (action and serverId) or serverId < 1 then
			return
		end

		if action == "scenario" then
			if not Fire.registered[serverId] then
				sendMessage(source, "The specified scenario hasn't been found.")
				return
			end

			table.remove(args, 1)
			table.remove(args, 1)

			Fire.registered[serverId].message = next(args) and table.concat(args, " ") or nil
			Fire:saveRegistered()
			sendMessage(source, ("Changed scenario's (#%s) dispatch message."):format(serverId))
		else
			local identifier = GetPlayerIdentifier(serverId, 0)

			if not identifier then
				sendMessage(source, "Player not online.")
				return
			end

			if action == "add" then
				Dispatch:subscribe(serverId, (not args[3] or args[3] ~= "false"))
				sendMessage(source, ("Subscribed %s to dispatch."):format(GetPlayerName(serverId)))
			elseif action == "remove" then
				Dispatch:unsubscribe(serverId, identifier)
				sendMessage(source, ("Unsubscribed %s from the dispatch."):format(GetPlayerName(serverId)))
			else
				sendMessage(source, "Invalid action.")
			end
		end
	end,
	true
)

RegisterCommand(
	'randomfires',
	function(source, args, rawCommand)
		if not Whitelist:isWhitelisted(source, "firescript.manage") then
			sendMessage(source, "Insufficient permissions.")
			return
		end

		local _source = source
		local action = args[1]
		local registeredFireID = tonumber(args[2])

		if not action then
			return
		end

		if action == "add" then
			if not registeredFireID then
				sendMessage(source, "Invalid argument (2).")
				return
			end
			Fire:setRandom(registeredFireID, true)
			sendMessage(source, ("Set scenario #%s to start randomly."):format(registeredFireID))
		elseif action == "remove" then
			if not registeredFireID then
				sendMessage(source, "Invalid argument (2).")
				return
			end
			Fire:setRandom(registeredFireID, false)
			sendMessage(source, ("Set scenario #%s not to start randomly."):format(registeredFireID))
		elseif action == "disable" then
			Fire:stopSpawner()
			sendMessage(source, "Disabled random fire spawn.")
		elseif action == "enable" then
			Fire:startSpawner()
			sendMessage(source, "Enabled random fire spawn.")
		else
			sendMessage(source, "Invalid action.")
		end
	end,
	false
)

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
	function(fireIndex, coords)
		Fire:createFlame(fireIndex, coords)
	end
)

RegisterNetEvent('fireManager:createFire')
AddEventHandler(
	'fireManager:createFire',
	function()
		Fire:create(coords, maximumSpread, spreadChance)
	end
)

RegisterNetEvent('fireManager:removeFire')
AddEventHandler(
	'fireManager:removeFire',
	function(fireIndex)
		Fire:remove(fireIndex)
	end
)

RegisterNetEvent('fireManager:removeAllFires')
AddEventHandler(
	'fireManager:removeAllFires',
	function()
		Fire:removeAll()
	end
)

RegisterNetEvent('fireManager:removeFlame')
AddEventHandler(
	'fireManager:removeFlame',
	function(fireIndex, flameIndex)
		Fire:removeFlame(fireIndex, flameIndex)
	end
)

--================================--
--           DISPATCH             --
--================================--

RegisterNetEvent('fireDispatch:registerPlayer')
AddEventHandler(
	'fireDispatch:registerPlayer',
	function(playerSource, isFirefighter)
		source = tonumber(source)
		playerSource = tonumber(playerSource)
		if (source and source > 0) or not playerSource or playerSource < 0 then
			return
		end

		Dispatch:subscribe(playerSource, not (isFirefighter))
	end
)

RegisterNetEvent('fireDispatch:removePlayer')
AddEventHandler(
	'fireDispatch:removePlayer',
	function(playerSource)
		source = tonumber(source)
		playerSource = tonumber(playerSource)
		if (source and source > 0) or not playerSource or playerSource < 0 then
			return
		end

		Dispatch:subscribe(playerSource)
	end
)

RegisterNetEvent('fireDispatch:create')
AddEventHandler(
	'fireDispatch:create',
	function(text, coords)
		if not Config.Dispatch.disableCalls and (source < 1 or Dispatch.expectingInfo[source]) then
			Dispatch:create(text, coords)
			if source > 0 then
				Dispatch.expectingInfo[source] = nil
			end
		end
	end
)

--================================--
--          WHITELIST             --
--================================--

RegisterNetEvent('fireManager:checkWhitelist')
AddEventHandler(
	'fireManager:checkWhitelist',
	function(serverId)
		if serverId then
			source = tonumber(serverId) or source
		end

		Whitelist:check(source)
	end
)

--================================--
--         AUTO-SUBSCRIBE         --
--================================--

local QBCore, ESX
if Config.Dispatch.Framework == "esx" then
    TriggerEvent("esx:getSharedObject", function(object)
        ESX = object
    end)
elseif Config.Dispatch.Framework == "qb" then
    QBCore = exports["qb-core"]:GetCoreObject()

	-- is you use old QB
	--QBCore = nil
	--TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
end

if Config.Dispatch.Framework == "esx" or Config.Dispatch.Framework == "qb" then
    if Config.Dispatch.enabled then
        if Config.Dispatch.Framework == "esx" then
            local allowedJobs = {}
			local firefighterJobs = Config.Fire.spawner.firefighterJobs or {}

			if type(Config.Dispatch.enableJob) == "table" then
				for k, v in pairs(Config.Dispatch.enableJob) do
					allowedJobs[v] = true
				end
			else
				allowedJobs[Config.Dispatch.enableJob] = true
				firefighterJobs[Config.Dispatch.enableJob] = true
			end

			RegisterNetEvent("esx:setJob")
			AddEventHandler("esx:setJob", function(source)
				local xPlayer = ESX.GetPlayerFromId(source)
			
				if allowedJobs[xPlayer.job.name] then
					Dispatch:subscribe(source, firefighterJobs[xPlayer.job.name])
				else
					Dispatch:unsubscribe(source)
				end
			end)
    
			RegisterNetEvent("esx:playerLoaded")
			AddEventHandler("esx:playerLoaded", function(source, xPlayer)
				if allowedJobs[xPlayer.job.name] then
					Dispatch:subscribe(source, firefighterJobs[xPlayer.job.name])
				else
					Dispatch:unsubscribe(source)
				end
			end)
        elseif Config.Dispatch.Framework == "qb" then
		
			local firefighterJobs = Config.Fire.spawner.firefighterJobs or {}
		
			if type(Config.Fire.spawner.firefighterJobs) == "table" then
				for k, v in pairs(Config.Fire.spawner.firefighterJobs) do
				   firefighterJobs[Config.Fire.spawner.firefighterJobs] = true
				end
			end
			
			RegisterServerEvent('fire:server:firedispatch')
			AddEventHandler('fire:server:firedispatch', function(source)
				local src = source
		
				for k, v in pairs(QBCore.Functions.GetPlayers()) do
					local Player = QBCore.Functions.GetPlayer(v)
					if Player ~= nil then 
						if (Config.Fire.spawner.firefighterJobs and Player.PlayerData.job.onduty) then
							Dispatch:subscribe(v, firefighterJobs)
							-- Notify here
						elseif (Config.Fire.spawner.firefighterJobs) then
							Dispatch:unsubscribe(v)
							-- Notify here
						end
					end
				end
			end)
        end
    end
end