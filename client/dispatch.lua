--================================--
--       FIRE SCRIPT v2.1.0       --
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

function Dispatch:renderRoute(dispatchNumber, coords, showBlip)
	ClearGpsMultiRoute()

    StartGpsMultiRoute(6, true, true)
    AddPointToGpsMultiRoute(table.unpack(coords))
    SetGpsMultiRouteRender(true)

	if showBlip and (not self.blips[dispatchNumber] or not self.blips[dispatchNumber].blip) then
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

		Citizen.SetTimeout(
			Config.Dispatch.removeBlipTimeout,
			function()
				self:removeBlip(dispatchNumber)
				if self.lastCall == dispatchNumber then
					ClearGpsMultiRoute()
				end
			end
		)
	end
end

function Dispatch:createNotification(dispatchNumber, message, playSound, showInBrief)
	if Config.Dispatch.useChat then
		sendMessage(message, ("Dispatch (#%s)"):format(dispatchNumber))
	else
		local showInBrief = showInBrief == nil and true or showInBrief;

		local txd = "CHAR_CALL911"

		BeginTextCommandThefeedPost("STRING")
		AddTextComponentSubstringPlayerName(tostring(message))
		EndTextCommandThefeedPostMessagetext(txd, txd, true, 0, "Fire Department", ("Call #%s"):format(dispatchNumber))
		EndTextCommandThefeedPostTicker(true, showInBrief)
	end
	if playSound then
        Citizen.CreateThread(
            function()
                for i = 1, 3 do
                    PlaySoundFromEntity(-1, "IDLE_BEEP", PlayerPedId(), "EPSILONISM_04_SOUNDSET", 0)
                    Citizen.Wait(300)
                end
            end
        )
    end
end

function Dispatch:removeBlip(dispatchNumber)
	if self.blips[dispatchNumber] and self.blips[dispatchNumber].blip then
		RemoveBlip(self.blips[dispatchNumber].blip)
		self.blips[dispatchNumber].blip = false
	end
end

function Dispatch:create(dispatchNumber, coords, message)
	if not (dispatchNumber and coords and message) then
		return
	end

    self:renderRoute(dispatchNumber, coords, true)
	self:createNotification(dispatchNumber, message, Config.Dispatch.playSound)

	FlashMinimapDisplay()

	-- Only store the last 'Config.Dispatch.storeLast' dispatches' data.
	if countElements(self.blips) > Config.Dispatch.storeLast then
		local order = {}

		for k, v in pairs(self.blips) do
			table.insert(order, k)
		end

		table.sort(order)
		self:removeBlip(order[1])
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

	if dispatchNumber then
		self:removeBlip(dispatchNumber)
	elseif dispatchNumber == 0 then
		for k, v in pairs(self.blips) do
			self:removeBlip(v)
		end
	end
end

function Dispatch:remind(dispatchNumber)
	if self.blips[dispatchNumber] then
		self:renderRoute(dispatchNumber, self.blips[dispatchNumber].coords, true)
		self.lastCall = dispatchNumber
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
					Dispatch.lastCall = nil
					ClearGpsMultiRoute()
				end
			end
		end
	)
end