-- KD Mission

-- Change this value to the dir
-- where you extracted the files.
local baseDir = [[C:\Projects\kdallas1\dcs-missions\Source\]]
local missionId = "?"
local campaign = "Horus"
local enableTest = true

dofile(baseDir .. "LoadScript.lua")
LoadScript(baseDir, missionId, campaign, enableTest)
