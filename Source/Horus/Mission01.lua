dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission01

--- 
-- @type Mission01
-- @extends KD.Mission#Mission
Mission01 = {
  className = "Mission01",
}

---
-- @type Mission01.State
-- @extends KD.Mission#MissionState
Mission01.State = {
}

---
-- @param #Mission01 self
function Mission01:Mission01()

  --self:SetTraceLevel(3)
  --self.playerTestOn = false

  self.state:AddStates(Mission01.State)
  
end

---
-- @param #Mission01 self
function Mission01:OnStart()
  
  self:MessageAll(MessageLength.Long, "Mission 1: Take out the early warning radar (EWR) systems in the mountains.")
  self:MessageAll(MessageLength.Long, "Read the mission brief before takeoff")
  
end

---
-- @param #Mission01 self
function Mission01:OnGameLoop()
  
end

---
-- @param #Mission01 self
-- @param Wrapper.Unit#UNIT unit
function Mission01:OnUnitSpawn(unit)

end

---
-- @param #Mission01 self
-- @param Wrapper.Unit#UNIT unit
function Mission01:OnPlayerSpawn(unit)

end

---
-- @param #Mission01 self
-- @param Wrapper.Unit#UNIT unit
function Mission01:OnUnitDead(unit)

end

Mission01 = createClass(Mission, Mission01)
