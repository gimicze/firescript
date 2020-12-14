--================================--
--       FIRE SCRIPT v1.6.4       --
--  by GIMI (+ foregz, Albo1125)  --
--      License: GNU GPL 3.0      --
--================================--

Config = {}

Config.Fire = {
    fireSpreadChance = 5, -- Out of 100 chances, how many lead to fire spreading? (not exactly percents)
    maximumSpreads = 5
}

Config.DispatchTimeout = 15000

Config.Dispatch = {
    enabled = true, -- Set this to false if you don't want to use the default dispatch system
    timeout = 15000, -- The amount of time in ms to delay the dispatch after the fire has been created
    storeLast = 5, -- The client will store the last five dispatch coordinates for use with /remindme <dispatchNumber>
    clearGpsRadius = 20.0, -- If you don't want to automatically clear the route upon arrival, leave this to false
    removeBlipTimeout = 400000, -- The amount of time in ms after which the dispatch call blip will be automatically removed
    playSound = true
}