dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission07

--- 
-- @type Mission07
-- @extends KD.Mission#Mission
Mission07 = {
  className = "Mission07",

  traceLevel = 2,
}

---
-- @type Mission07.State
-- @extends KD.Mission#MissionState
Mission07.State = {
}

---
-- @param #Mission07 self
function Mission07:Mission07()

  self.nalchikParkZone = self.moose.zone:New("Nalchik Park")
  self:Assert(self.nalchikParkZone, "Nalchik park zone not found")

end

---
-- @param #Mission07 self
function Mission07:OnStart()

  self:MessageAll(MessageLength.Long, "Mission 7: Capture Mozdok; destroy enemy aircraft on the ground")
  self:MessageAll(MessageLength.Long, "Read the mission brief before takeoff")

end

---
-- @param #Mission07 self
function Mission07:OnGameLoop()
end

---
-- @param #Mission07 self
-- @param Wrapper.Unit#UNIT unit
function Mission07:OnUnitDead(unit)

  self:Trace(1, "Unit dead: " .. unit:GetName())

end

Mission07 = createClass(Mission, Mission07)
