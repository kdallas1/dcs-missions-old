skipMoose = true
dofile(baseDir .. "Horus/Source/Mission05.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

---
-- @module KD.Test.MockMission05

--- 
-- @type MockMission05
-- @extends KD.Mission#Mission
local MockMission05 = {
  className = "MockMission05"
}

---
-- @param #self #MockMission05
function MockMission05:MockMission05()
  self:SetTraceOn(false)
end

MockMission05 = createClass(Mission05, MockMission05)

local function Test_New()
  
  local moose = MockMoose:New()
  function moose.group:FindByName() end

  local misson = MockMission05:New(moose)
end

function Test_Mission05()
  return RunTests {
    "Mission05",
    Test_New
  }
end
