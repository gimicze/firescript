--================================--
--       FIRE SCRIPT v1.7.6       --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

Config = {}

Config.Fire = {
    fireSpreadChance = 5, -- Out of 100 chances, how many lead to fire spreading? (not exactly percents)
    maximumSpreads = 5,
    spawner = { -- Requires the use of the built-in dispatch system
        enableOnStartup = true,
        interval = 1800000, -- Random fire spawn interval (set to nil or false if you don't want to spawn random fires) in ms
        chance = 50, -- Fire spawn chance (out of 100 chances, how many lead to spawning a fire?); Set to values between 1-100
        players = 3, -- Sets the minimum number of players subscribed to dispatch for the spawner to spawn fires.
        firefighterJobs = { -- If using ESX or QB (Config.Dispatch.enableESX), you can specify which players will count as firefighters in Config.Fire.spawner.players above; If not using ESX or QB you can set this to nil
            ["ambulance"] = true -- QB is "ambulance" or ESX job is "fd"
        }
    }
}

Config.Dispatch = {
    enabled = true, -- Set this to false if you don't want to use the default dispatch system
    timeout = 15000, -- The amount of time in ms to delay the dispatch after the fire has been created
    storeLast = 5, -- The client will store the last five dispatch coordinates for use with /remindme <dispatchNumber>
    clearGpsRadius = 20.0, -- If you don't want to automatically clear the route upon arrival, leave this to false
    removeBlipTimeout = 400000, -- The amount of time in ms after which the dispatch call blip will be automatically removed
    playSound = "chat", -- test for new Sound "inferno" or "chat" or "none"
    Framework = "qb", -- * "qb" (qb-core) * "esx" (ESX) * "none" -- Set to a esx or qb job / jobs you want to be automatically subscribed to dispatch; Set to nil or false if you don't want to use this
}