--================================--
--       FIRE SCRIPT v2.0.2       --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

Fire = {
	scenario = {},
	random = {},
	active = {},
	binds = {},
	activeBinds = {},
	__index = self,
	init = function(o)
		o = o or {scenario = {}, random = {}, active = {}, binds = {}, activeBinds = {}}
		setmetatable(o, self)
		self.__index = self
		return o
	end
}

function Fire:create(coords, maximumSpread, spreadChance, difficulty)
	maximumSpread = maximumSpread and maximumSpread or Config.Fire.maximumSpreads
	spreadChance = spreadChance and spreadChance or Config.Fire.fireSpreadChance
	difficulty = difficulty and difficulty or Config.Fire.difficulty

	local fireIndex = highestIndex(self.active)
	fireIndex = fireIndex + 1

	self.active[fireIndex] = {
		maxSpread = maxSpread,
		spreadChance = spreadChance,
		difficulty = difficulty
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
							local x = self.active[fireIndex][k].c.x
							local y = self.active[fireIndex][k].c.y
							local z = self.active[fireIndex][k].c.z
	
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
	self.active[fireIndex][flameIndex] = {
		c = coords
	}
	self.active[fireIndex][flameIndex].extinguished = self.active[fireIndex].difficulty and 1 or nil
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

function Fire:removeFlame(fireIndex, flameIndex, force)
	if self.active[fireIndex] and self.active[fireIndex][flameIndex] then
		if self.active[fireIndex][flameIndex].ignore and not force then
			return
		end

		self.active[fireIndex][flameIndex].ignore = true
		
		if not force and self.active[fireIndex].difficulty ~= nil and self.active[fireIndex][flameIndex].extinguished < self.active[fireIndex].difficulty then
			self.active[fireIndex][flameIndex].extinguished = self.active[fireIndex][flameIndex].extinguished + 1

			Citizen.SetTimeout(1500,
				function()
					self.active[fireIndex][flameIndex].ignore = nil
				end
			)
		else
			self.active[fireIndex][flameIndex] = nil
			
			if type(next(self.active[fireIndex])) == "string" then
				self:remove(fireIndex)
			end

			TriggerClientEvent('fireClient:removeFlame', -1, fireIndex, flameIndex)
		end
	end
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

function Fire:register(coords, difficulty)
	local scenarioID = highestIndex(self.scenario) + 1

	self.scenario[scenarioID] = {
		flames = {}
	}

	if coords then
		self.scenario[scenarioID].dispatchCoords = coords
	end

	self:saveScenarios()

	return scenarioID
end

function Fire:startScenario(scenarioID, triggerDispatch, dispatchPlayer)
	if not self.scenario[scenarioID] then
		return false
	end

	if not self.binds[scenarioID] then
		self.binds[scenarioID] = {}
	end

	for k, v in pairs(self.scenario[scenarioID].flames) do
		local fireID = Fire:create(v.coords, v.spread, v.chance, self.scenario[scenarioID].difficulty)
		self.binds[scenarioID][fireID] = true
		self.activeBinds[fireID] = scenarioID
		Citizen.Wait(10)
	end

	if self.scenario[scenarioID].dispatchCoords and triggerDispatch and dispatchPlayer then
		if Config.Dispatch.toneSources and type(Config.Dispatch.toneSources) == "table" then
			TriggerClientEvent('fireClient:playTone', -1)
		end
		
		local dispatchCoords = self.scenario[scenarioID].dispatchCoords
		Citizen.SetTimeout(
			Config.Dispatch.timeout,
			function()
				if Config.Dispatch.enabled then
					if self.scenario[scenarioID].message ~= nil then
						Dispatch:create(self.scenario[scenarioID].message, dispatchCoords)
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

function Fire:stopScenario(scenarioID)
	if not self.binds[scenarioID] then
		return false
	end

	for k, v in pairs(self.binds[scenarioID]) do
		self.activeBinds[k] = nil
		Fire:remove(k)
		Citizen.Wait(10)
	end

	self.binds[scenarioID] = nil

	if self.currentRandom and self.currentRandom == scenarioID then
		self.currentRandom = nil
	end

	return true
end

function Fire:deleteScenario(scenarioID)
	if not self.scenario[scenarioID] then
		return false
	end

	if self.scenario[scenarioID].random then
		self:setRandom(scenarioID, false)
	end

	self.scenario[scenarioID] = nil

	self:saveScenarios()

	return true
end

function Fire:setScenarioDifficulty(scenarioID, difficulty)
	if not self.scenario[scenarioID] then
		return false
	end

	difficulty = difficulty < 1 and nil or difficulty

	self.scenario[scenarioID].difficulty = difficulty

	self:saveScenarios()

	return true
end

function Fire:addFlame(scenarioID, coords, spread, chance)
	if not (scenarioID and coords and spread and chance and self.scenario[scenarioID]) then
		return false
	end

	local flameID = highestIndex(self.scenario[scenarioID].flames) + 1

	self.scenario[scenarioID].flames[flameID] = {}
	self.scenario[scenarioID].flames[flameID].coords = coords
	self.scenario[scenarioID].flames[flameID].spread = spread
	self.scenario[scenarioID].flames[flameID].chance = chance

	self:saveScenarios()

	return flameID
end

function Fire:deleteFlame(scenarioID, flameID)
	if not (self.scenario[scenarioID] and self.scenario[scenarioID].flames[flameID]) then
		return false
	end

	table.remove(self.scenario[scenarioID].flames, flameID)

	self:saveScenarios()

	return true
end

function Fire:setRandom(scenarioID, random)
	random = random or nil
	scenarioID = tonumber(scenarioID)

	if not scenarioID or not self.scenario[scenarioID] then
		return false
	end

	self.scenario[scenarioID].random = random
	self.random[scenarioID] = random

	self:saveScenarios()

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
						local randomscenarioID = table.random(self.random)
						local randomPlayer = Dispatch:getRandomPlayer()

						if randomscenarioID and randomPlayer then
							if self:startScenario(randomscenarioID, true, randomPlayer) then
								self.currentRandom = randomscenarioID
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

-- Saving scenarios

function Fire:saveScenarios()
	saveData(self.scenario, "fires")
end

function Fire:loadScenarios()
	local firesFile = loadData("fires")
	self.random = {}
	if firesFile ~= nil then
		self.scenario = firesFile
		for index, fire in pairs(self.scenario) do
			if fire.dispatchCoords then
				self.scenario[index].dispatchCoords = vector3(fire.dispatchCoords.x, fire.dispatchCoords.y, fire.dispatchCoords.z)
			end
			for _, flame in pairs(fire.flames) do
				self.scenario[index].flames[_].coords = vector3(flame.coords.x, flame.coords.y, flame.coords.z)
			end
			if fire.random == true then
				self.random[index] = true
			end
		end
	else
		self.scenario = {}
		saveData(self.scenario, "fires")
	end
end