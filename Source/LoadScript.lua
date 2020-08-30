
local function test(campaign)

  dofile(baseDir .. "KD/Test/Test.lua")
  dofile(baseDir .. campaign .. "/Test/Test.lua")
  
  local pass, errorCount = Test { _G["Test_" .. campaign] }
  
  if (not pass) then
    error("Unit tests failed: " .. errorCount)
  end
  
end 

function LoadScript(baseDir_, missionId, campaign, enableTest)

  baseDir = baseDir_

  if enableTest then
    local success, value = pcall(test, campaign)
    if not success then
      env.error("Error: " .. value, true)
    end
  end
  
  local missionName = "Mission" .. missionId
  dofile(baseDir .. campaign .. "/" .. missionName .. ".lua")
  _G[missionName]:New():Start()

end
