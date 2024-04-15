--================================--
--       FIRE SCRIPT v1.6.3       --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

Dispatch = {
	lastCall = nil,
	blips = {},
	playingTone = nil,
	__index = self,
	init = function(o)
		o = o or {lastCall = {}, blips = {}, playingTone = nil}
		setmetatable(o, self)
		self.__index = self
		return o
	end
}

function Dispatch:renderRoute(coords)
	ClearGpsMultiRoute()

    StartGpsMultiRoute(6, true, true)
    AddPointToGpsMultiRoute(table.unpack(coords))
    SetGpsMultiRouteRender(true)
end

function Dispatch:create(dispatchNumber, coords)
	if not (dispatchNumber and coords) then
		return
	end

	-- Create a fire blip
	local blip = AddBlipForCoord(table.unpack(coords))
	SetBlipSprite(blip, 436)
	SetBlipDisplay(blip, 4)
	SetBlipScale(blip, 1.5)
	SetBlipColour(blip, 1)
	SetBlipAsShortRange(blip, false)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Fire #" .. dispatchNumber)
	EndTextCommandSetBlipName(blip)

	self.blips[dispatchNumber] = {
		coords = coords,
		blip = blip
	}

    self:renderRoute(coords)
    
    if Config.Dispatch.playSound then
        Citizen.CreateThread(
            function()
                for i = 1, 3 do
                    PlaySoundFromEntity(-1, "IDLE_BEEP", PlayerPedId(), "EPSILONISM_04_SOUNDSET", 0)
                    Citizen.Wait(300)
                end
            end
        )
    end

	FlashMinimapDisplay()

	Citizen.SetTimeout(
		Config.Dispatch.removeBlipTimeout,
		function()
			if self.blips[dispatchNumber] and self.blips[dispatchNumber].blip then
				RemoveBlip(blip)
				self.blips[dispatchNumber].blip = false
			end
			if self.lastCall == dispatchNumber then
				ClearGpsMultiRoute()
			end
		end
	)

	-- Only store the last 'Config.Dispatch.storeLast' dispatches' data.
	if countElements(self.blips) > Config.Dispatch.storeLast then
		local order = {}

		for k, v in pairs(self.blips) do
			table.insert(order, k)
		end

		table.sort(order)
		self.blips[order[1]] = nil
	end

	self.lastCall = dispatchNumber
end

function Dispatch:playTone()
	if self.playingTone or not (Config.Dispatch.toneSources and type(Config.Dispatch.toneSources) == "table") then
		return false
	end

	self.playingTone = true

	for k, v in ipairs(Config.Dispatch.toneSources) do
		local soundID = GetSoundId() -- The databank gets loaded when the script launches

		Citizen.CreateThread(
			function()
				PlaySoundFromCoord(soundID, "long_beeps", v.x, v.y, v.z, "firescript_alarm", 0, 150, 0)

				Citizen.Wait(8000)

				PlaySoundFromCoord(soundID, "short_beeps", v.x, v.y, v.z, "firescript_alarm", 0, 150, 0)

				Citizen.Wait(5000)

				ReleaseSoundId(soundID)
			end
		)
	end

	Citizen.SetTimeout(
		13000,
		function()
			self.playingTone = nil
		end
	)

	return true
end

function Dispatch:clear(dispatchNumber)
	ClearGpsMultiRoute()

	if dispatchNumber and self.blips[dispatchNumber] and self.blips[dispatchNumber].blip then
		RemoveBlip(self.blips[dispatchNumber].blip)
		self.blips[dispatchNumber].blip = false
	elseif dispatchNumber == 0 then
		for k, v in pairs(self.blips) do
			if self.blips[k].blip then
				RemoveBlip(self.blips[k].blip)
				self.blips[k].blip = false
			end
		end
	end
end

function Dispatch:remind(dispatchNumber)
	if self.blips[dispatchNumber] then
		SetNewWaypoint(table.unpack(self.blips[dispatchNumber].coords.xy))
		return true
	else
		return false
	end
end

--================================--
--     DISPATCH ROUTE REMOVAL     --
--================================--

if Config.Dispatch.clearGpsRadius and tonumber(Config.Dispatch.clearGpsRadius) then
	Citizen.CreateThread(
		function()
			while true do
				Citizen.Wait(5000)
				if Dispatch.lastCall and Dispatch.blips[Dispatch.lastCall] and Dispatch.blips[Dispatch.lastCall].blip and #(Dispatch.blips[Dispatch.lastCall].coords - GetEntityCoords(PlayerPedId())) < Config.Dispatch.clearGpsRadius then
					ClearGpsMultiRoute()
				end
			end
		end
	)
end