--================================--
--        FIRE SCRIPT v1.6        --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

local Whitelist = {
	players = {},
	config = {},
	__index = self,
	init = function(object)
		object = object or {players = {}, config = {}}
		setmetatable(object, self)
		return object
	end
}

function Whitelist:check(serverId)
	if serverId then
		source = serverId
	end

	if source > 0 then
		local steamID = GetPlayerIdentifier(source, 0)
		if self.config[steamID] == true or IsPlayerAceAllowed(source, "firescript.all") then
			self.players[source] = true
		elseif self.players[source] ~= nil then
			self.players[source] = nil
		end
	end
end

function Whitelist:isWhitelisted(serverId)
	return (serverId > 0 and self.players[serverId] == true)
end

function Whitelist:addPlayer(serverId, steamId)
	self.player[serverId], self.config[steamId] = true, true
end

function Whitelist:removePlayer(serverId, steamId)
	self.player[serverId], self.config[steamId] = nil, nil
end

function Whitelist:load()
	local whitelistFile = loadData("whitelist")
	if whitelistFile ~= nil then
		self.config = whitelistFile
		for _, playerId in ipairs(GetPlayers()) do
			self:check(tonumber(playerId))
		end
	else
		saveData({}, "whitelist")
	end
end

function Whitelist:save()
	saveData(self.config, "whitelist")
end