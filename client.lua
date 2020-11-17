--================================--
--        FIRE SCRIPT v1.3        --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

activeFires = {}

local syncInProgress = false

TriggerEvent("chat:addTemplate", "firescript", '<div style="text-indent: 0 !important; padding: 0.5vw; margin: 0.05vw; color: rgba(255,255,255,0.9);background-color: rgba(250,26,56, 0.8); border-radius: 4px;"><b>FireScript v1.3</b> {0} </div>')

--================================--
--          SUGGESTIONS           --
--================================--

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

TriggerEvent('chat:addSuggestion', '/registerfire', 'Registers a new fire configuration', {
	{
		name = "dispatch",
		help = "Should the fire trigger dispatch? (default true)"
	}
})

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

TriggerEvent('chat:addSuggestion', '/removefire', 'Removes a register fire', {
	{
		name = "fireID",
		help = "The fire ID"
	}
})

TriggerEvent('chat:addSuggestion', '/startregisteredfire', 'Starts a registered fire', {
	{
		name = "fireID",
		help = "The fire ID"
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
			TriggerServerEvent('fireManager:checkWhitelist')
		end
	end
)

--================================--
--           FUNCTIONS            --
--================================--

function createFlame(fireIndex, flameIndex, coords)
	if activeFires[fireIndex] == nil then
		activeFires[fireIndex] = {
			flameCoords = {},
			flames = {},
			particles = {},
			flameParticles = {}
		}
	end
	activeFires[fireIndex].flameCoords[flameIndex] = coords
end

function removeFlame(fireIndex, flameIndex)
	if not (fireIndex and flameIndex and activeFires[fireIndex]) then
		return
	end
	if activeFires[fireIndex].flames[flameIndex] and activeFires[fireIndex].flames[flameIndex] ~= 0 then
		RemoveScriptFire(activeFires[fireIndex].flames[flameIndex])
		activeFires[fireIndex].flames[flameIndex] = nil
	end
	if activeFires[fireIndex].particles[flameIndex] and activeFires[fireIndex].particles[flameIndex] ~= 0 then
		local particles = activeFires[fireIndex].particles[flameIndex]
		Citizen.SetTimeout(
			5000,
			function()
				StopParticleFxLooped(particles, false)
			end
		)
		activeFires[fireIndex].particles[flameIndex] = nil
	end
	if activeFires[fireIndex].flameParticles[flameIndex] and activeFires[fireIndex].flameParticles[flameIndex] ~= 0 then
		local flameParticles = activeFires[fireIndex].flameParticles[flameIndex]
		Citizen.SetTimeout(
			5000,
			function()
				StopParticleFxLooped(flameParticles, false)
			end
		)
		activeFires[fireIndex].flameParticles[flameIndex] = nil
	end
	activeFires[fireIndex].flameCoords[flameIndex] = nil

	if countElements(activeFires[fireIndex].flameCoords) < 1 and activeFires[fireIndex] ~= nil then
		table.remove(activeFires, fireIndex)
	end
end

function removeFire(fireIndex, callback)
	if not (activeFires[fireIndex] and activeFires[fireIndex].particles) then
		return
	end

	for k, v in pairs(activeFires[fireIndex].flames) do
		removeFlame(fireIndex, k)
	end

	Citizen.SetTimeout(
		200,
		function()
			if activeFires[fireIndex] and next(activeFires[fireIndex].flames) ~= nil then
				print("WARNING: A fire persisted!")
				removeFire(fireIndex)
			end
		end
	)

	if callback then
		callback(fireIndex)
	end
end

function removeAllFires(callback)
	for k, v in pairs(activeFires) do
		removeFire(k)
	end
	
	if callback then
		callback()
	end
end

function countElements(table)
	local count = 0
	if type(table) == "table" then
		for k, v in pairs(table) do
			count = count + 1
		end
	end
	return count
end

--================================--
--             EVENTS             --
--================================--

RegisterNetEvent('fireClient:synchronizeFlames')
AddEventHandler(
	'fireClient:synchronizeFlames',
	function(fires)
		syncInProgress = true
		removeAllFires(
			function()
				for k, v in pairs(fires) do
					for _k, _v in pairs(v) do
						createFlame(k, _k, _v)
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
		removeFire(fireIndex)
	end
)

RegisterNetEvent('fireClient:removeAllFires')
AddEventHandler(
	'fireClient:removeAllFires',
	function()
		while syncInProgress do
			Citizen.Wait(10)
		end
		removeAllFires()
	end
)

RegisterNetEvent("fireClient:removeFlame")
AddEventHandler(
    "fireClient:removeFlame",
	function(fireIndex, flameIndex)
		while syncInProgress do
			Citizen.Wait(10)
		end
		removeFlame(fireIndex, flameIndex)
    end
)

RegisterNetEvent("fireClient:createFlame")
AddEventHandler(
    "fireClient:createFlame",
	function(fireIndex, flameIndex, coords)
		syncInProgress = true
        createFlame(fireIndex, flameIndex, coords)
		syncInProgress = false
    end
)

--================================--
-- PARTICLES & FIRE EXTINGUISHING --
--================================--

Citizen.CreateThread(
	function()
		if not HasNamedPtfxAssetLoaded("scr_agencyheistb") then
			RequestNamedPtfxAsset("scr_agencyheistb")
			while not HasNamedPtfxAssetLoaded("scr_agencyheistb") do
				Wait(1)
			end
		end

        if not HasNamedPtfxAssetLoaded("scr_trevor3") then
            RequestNamedPtfxAsset("scr_trevor3")
            while not HasNamedPtfxAssetLoaded("scr_trevor3") do
                Wait(1)
            end
		end
		
		while true do
			Citizen.Wait(1000)
			for fireIndex, v in pairs(activeFires) do
				if countElements(v.particles) ~= 0 then
					for flameIndex, _v in pairs(activeFires[fireIndex].particles) do
						local isFirePresent = GetNumberOfFiresInRange(
							v.flameCoords[flameIndex].x,
							v.flameCoords[flameIndex].y,
							v.flameCoords[flameIndex].z,
							0.5
						)
						if isFirePresent == 0 then
							TriggerServerEvent('fireManager:removeFlame', fireIndex, flameIndex)
						end
					end
				end
			end
		end
	end
)

Citizen.CreateThread(
	function()
		while true do
			local pedCoords = GetEntityCoords(GetPlayerPed(-1))
			for fireIndex, v in pairs(activeFires) do
				for flameIndex, coords in pairs(v.flameCoords) do
					Citizen.Wait(10)
					if not v.flames[flameIndex] and GetDistanceBetweenCoords(pedCoords, coords) < 300.0 then
						local z = coords.z
		
						repeat
							Wait(0)
							ground, newZ = GetGroundZFor_3dCoord(coords.x, coords.y, z, 1)
							if not ground then
								z = z + 0.1
							end
						until ground
						z = newZ
	
						v.flames[flameIndex] = StartScriptFire(coords.x, coords.y, z, 0, false)

						v.flameCoords[flameIndex] = vector3(coords.x, coords.y, z)
		
						SetPtfxAssetNextCall("scr_agencyheistb")
						
						v.particles[flameIndex] = StartParticleFxLoopedAtCoord(
							"scr_env_agency3b_smoke",
							coords.x,
							coords.y,
							z + 1.0,
							0.0,
							0.0,
							0.0,
							1.0,
							false,
							false,
							false,
							false
						)
					
						SetPtfxAssetNextCall("scr_trevor3")
					
						v.flameParticles[flameIndex] = StartParticleFxLoopedAtCoord(
							"scr_trev3_trailer_plume",
							coords.x,
							coords.y,
							z + 1.2,
							0.0,
							0.0,
							0.0,
							1.0,
							false,
							false,
							false,
							false
						)
					end
				end
			end
			Citizen.Wait(1000)
		end
	end
)
