--================================--
--       FIRE SCRIPT v2.0.0       --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

Config = {}

Config.Fire = {
    fireSpreadChance = 5, -- Out of 100 chances, how many lead to fire spreading? (not exactly percents)
    maximumSpreads = 5,
    difficulty = 3, -- 1 to 10; sets how hard (lengthy) it will be to extinguish a fire (set nil as default or a whole number larger than 0, e.g. 2, to increase difficulty; try how it works, probably don't go higher than 10)
    spawner = { -- Requires the use of the built-in dispatch system
        enableOnStartup = true,
        interval = 1800000, -- Random fire spawn interval (set to nil or false if you don't want to spawn random fires) in ms
        chance = 50, -- Fire spawn chance (out of 100 chances, how many lead to spawning a fire?); Set to values between 1-100
        players = 3, -- Sets the minimum number of players subscribed to dispatch for the spawner to spawn fires.
        firefighterJobs = { -- If using a framework (Config.Dispatch.enableFramework), you can specify which players will count as firefighters in Config.Fire.spawner.players above; If set to nil, all jobs specified in Config.Dispatch.jobs will count as firefighters
            ["fd"] = true -- Always set the job name in the key, value has to be true
        }
    }
}

Config.Dispatch = {
    enabled = true, -- Set this to false if you don't want to use the default dispatch system
    timeout = 15000, -- The amount of time in ms to delay the dispatch after the fire has been created
    storeLast = 5, -- The client will store the last five dispatch coordinates for use with /remindme <dispatchNumber>
    clearGpsRadius = 20.0, -- If you don't want to automatically clear the route upon arrival, leave this to false
    removeBlipTimeout = 400000, -- The amount of time in ms after which the dispatch call blip will be automatically removed
    playSound = true,
    enableFramework = 1, -- Set to nil if you don't want to use any framework implementation. Set to 1 for ESX, 2 for QB-Core.
    jobs = { -- Set to a ESX job / jobs you want to be automatically subscribed to dispatch; Set to nil or false if you don't want to use this
        "fd"
    },
    toneSources = { -- Here you can set coordinates of sound sources for the fire tones to go off at; Set to nil if you wish to disable this function.
        -- Fire Station 7
        vector3(1207.11, -1463.37, 36),
        vector3(1195, -1464, 36),
        vector3(1195, -1484, 36),
        vector3(1207.11, -1484, 36),
        -- Sandy Shores
        vector3(1691, 3586, 37)
    }
}
