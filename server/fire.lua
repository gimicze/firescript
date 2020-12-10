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