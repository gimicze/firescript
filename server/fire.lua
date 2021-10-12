--================================--
--       FIRE SCRIPT v1.7.6       --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

Fire = {
	registered = {},
	random = {},
	active = {},
	binds = {},
	activeBinds = {},
	__index = self,
	init = function(o)
		o = o or {registered = {}, random = {}, active = {}, binds = {}, activeBinds = {}}
		setmetatable(o, self)
		self.__index = self
		return o
	end
}

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
				if flames ~= 0 and flames <= maximumSpread and self.active[fireIndex] ~= nil then
					for k, v in ipairs(self.active[fireIndex]) do
						index, flames = highestIndex(self.active, fireIndex)
						local rndSpread = math.random(100)
						if flames <= maximumSpread and rndSpread <= spreadChance then
							local x = self.active[fireIndex][k].x
							local y = self.active[fireIndex][k].y
							local z = self.active[fireIndex][k].z
	
							local xSpread = math.random(-3, 3)
							local ySpread = math.random(-3, 3)
	
							coords = vector3(x + xSpread, y + ySpread, z)
	
							self:createFlame(fireIndex, coords)
						elseif flames > maximumSpread then
							spread = false
							break
						end
					end
				elseif flames == 0 or self.active[fireIndex] == nil then
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

	if self.activeBinds[fireIndex] then
		self.binds[self.activeBinds[fireIndex]][fireIndex] = nil

		if self.activeBinds[fireIndex] == self.currentRandom and next(self.binds[self.activeBinds[fireIndex]]) == nil then
			self.currentRandom = nil
		end
	end

	self.active[fireIndex] = {}
	return true
end

function Fire:removeFlame(fireIndex, flameIndex)
	if self.active[fireIndex] and self.active[fireIndex][flameIndex] then
		self.active[fireIndex][flameIndex] = nil
		if type(next(self.active[fireIndex])) == "string" then
			self:remove(fireIndex)
		end
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
	self.activeBinds = {}
	self.binds = {}
	self.currentRandom = nil
end

function Fire:register(coords)
	local registeredFireID = highestIndex(self.registered) + 1

	self.registered[registeredFireID] = {
		flames = {}
	}

	if coords then
		self.registered[registeredFireID].dispatchCoords = coords
	end

	self:saveRegistered()

	return registeredFireID
end

function Fire:startRegistered(registeredFireID, triggerDispatch, dispatchPlayer)
	if not self.registered[registeredFireID] then
		return false
	end

	if not self.binds[registeredFireID] then
		self.binds[registeredFireID] = {}
	end

	for k, v in pairs(self.registered[registeredFireID].flames) do
		local fireID = Fire:create(v.coords, v.spread, v.chance)
		self.binds[registeredFireID][fireID] = true
		self.activeBinds[fireID] = registeredFireID
		Citizen.Wait(10)
	end

	if self.registered[registeredFireID].dispatchCoords and triggerDispatch and dispatchPlayer then
		local dispatchCoords = self.registered[registeredFireID].dispatchCoords
		Citizen.SetTimeout(
			Config.Dispatch.timeout,
			function()
				if Config.Dispatch.enabled then
					if self.registered[registeredFireID].message ~= nil then
						Dispatch:create(self.registered[registeredFireID].message, dispatchCoords)
					else
						Dispatch.expectingInfo[dispatchPlayer] = true
						TriggerClientEvent('fd:dispatch', dispatchPlayer, dispatchCoords)
					end
				end
			end
		)
	end

	return true
end

function Fire:stopRegistered(registeredFireID)
	if not self.binds[registeredFireID] then
		return false
	end

	for k, v in pairs(self.binds[registeredFireID]) do
		self.activeBinds[k] = nil
		Fire:remove(k)
		Citizen.Wait(10)
	end

	self.binds[registeredFireID] = nil

	if self.currentRandom and self.currentRandom == registeredFireID then
		self.currentRandom = nil
	end

	return true
end

function Fire:deleteRegistered(registeredFireID)
	if not self.registered[registeredFireID] then
		return false
	end

	if self.registered[registeredFireID].random then
		self:setRandom(registeredFireID, false)
	end

	self.registered[registeredFireID] = nil

	self:saveRegistered()

	return true
end

function Fire:addFlame(registeredFireID, coords, spread, chance)
	if not (registeredFireID and coords and spread and chance and self.registered[registeredFireID]) then
		return false
	end

	local flameID = highestIndex(self.registered[registeredFireID].flames) + 1

	self.registered[registeredFireID].flames[flameID] = {}
	self.registered[registeredFireID].flames[flameID].coords = coords
	self.registered[registeredFireID].flames[flameID].spread = spread
	self.registered[registeredFireID].flames[flameID].chance = chance

	self:saveRegistered()

	return flameID
end

function Fire:deleteFlame(registeredFireID, flameID)
	if not (self.registered[registeredFireID] and self.registered[registeredFireID].flames[flameID]) then
		return false
	end

	table.remove(self.registered[registeredFireID].flames, flameID)

	self:saveRegistered()

	return true
end

function Fire:setRandom(registeredFireID, random)
	random = random or nil
	registeredFireID = tonumber(registeredFireID)

	if not registeredFireID or not self.registered[registeredFireID] then
		return false
	end

	self.registered[registeredFireID].random = random
	self.random[registeredFireID] = random

	self:saveRegistered()

	return true
end

function Fire:startSpawner(frequency, chance)
	frequency = tonumber(frequency) or Config.Fire.spawner.interval
	chance = tonumber(chance) or Config.Fire.spawner.chance

	if self._stopSpawner or not self.random or not frequency then
		return false
	end

	local spawnerActive = true

	self._stopSpawner = function()
		spawnerActive = nil
	end

	Citizen.CreateThread(
		function()
			while spawnerActive do
				if next(self.random) and not self.currentRandom and Dispatch:firefighters() >= Config.Fire.spawner.players then
					if math.random(100) < chance then
						local randomRegisteredFireID = table.random(self.random)
						local randomPlayer = Dispatch:getRandomPlayer()

						if randomRegisteredFireID and randomPlayer then
							if self:startRegistered(randomRegisteredFireID, true, randomPlayer) then
								self.currentRandom = randomRegisteredFireID
							end
						end
					end
				end
				
				Citizen.Wait(frequency)
			end
		end
	)

	return true
end

function Fire:stopSpawner()
	if self._stopSpawner then
		self._stopSpawner()
		self._stopSpawner = nil
	end
end

-- Saving registered fires

function Fire:saveRegistered()
	saveData(self.registered, "fires")
end

function Fire:loadRegistered()
	local firesFile = loadData("fires")
	self.random = {}
	if firesFile ~= nil then
		for index, fire in pairs(firesFile) do
			for _, flame in pairs(fire.flames) do
				flame.coords = vector3(flame.coords.x, flame.coords.y, flame.coords.z)
			end
			if fire.dispatchCoords then
				fire.dispatchCoords = vector3(fire.dispatchCoords.x, fire.dispatchCoords.y, fire.dispatchCoords.z)
			end
			if fire.random == true then
				self.random[index] = true
			end
		end
		self.registered = firesFile
	else
		saveData({}, "fires")
	end
end