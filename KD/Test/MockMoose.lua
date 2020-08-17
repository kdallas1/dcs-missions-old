dofile(baseDir .. "KD/Moose.lua")

---
-- @module KD.Test.MockMoose

--- 
-- @type MockMoose
-- @extends KD.Mission#Mission
MockMoose = {
  className = "MockMoose"
}

---
-- @param self #MockMoose
function MockMoose:MockMoose()
  self:SetTraceOn(false)
  self.zone = { ClassName = "MockZone" }
  self.spawn = { ClassName =  "MockSpawn" }
  self.group = { ClassName =  "MockGroup" }
  self.unit = { ClassName =  "MockUnit" }
  self.scheduler = { ClassName = "MockScheduler" }
  self.userSound = { ClassName = "MockUserSound" }
  self.message = { ClassName = "MockMessage" }
end

MockMoose = createClass(Moose, MockMoose)
