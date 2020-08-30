-- KD Mission

-- change this value to the dir
-- where you extracted the files
baseDir = [[C:\Projects\kdallas1\dcs-missions\Source\]]

local missionId = "?"
local campaign = "Horus"
local enableTest = true

local function test()

  dofile(baseDir .. "KD/Test/Test.lua")
  dofile(baseDir .. "Horus/Test/Test.lua")
  
  local pass, errorCount = Test { Test_Horus }
  
  if (not pass) then
    error("Unit tests failed: " .. errorCount)
  end
  
end 

if enableTest then
  local pass, value = pcall(test)
  if not pass then
    env.error("Error: " .. value, true)
  end
end

local missionName = "Mission" .. missionId
dofile(baseDir .. campaign .. "/" .. missionName .. ".lua")
_G[missionName]:New():Start()
