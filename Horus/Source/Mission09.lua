dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission09

--- 
-- @type Mission09
-- @extends KD.Mission#Mission
Mission09 = {
  className = "Mission09",

  traceLevel = 2,
}

---
-- @type Mission09.State
-- @extends KD.Mission#MissionState
Mission09.State = {
}

---
-- @param #Mission09 self
function Mission09:Mission09()

end

---
-- @param #Mission09 self
function Mission09:OnStart()

  self:MessageAll(MessageLength.Long, "Mission 9: Final assault on the ALF, capture Mineralnye Vody.")
  self:MessageAll(MessageLength.Long, "Read the mission brief before takeoff")

end

---
-- @param #Mission09 self
function Mission09:OnGameLoop()
end

---
-- @param #Mission09 self
-- @param Wrapper.Unit#UNIT unit
function Mission09:OnUnitDead(unit)

  self:Trace(1, "Unit dead: " .. unit:GetName())

end

Mission09 = createClass(Mission, Mission09)
