dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission06

--- 
-- @type Mission06
-- @extends KD.Mission#Mission
Mission06 = {
  className = "Mission06",

  traceLevel = 2,

  enemyFobCount = 4
}

---
-- @param #Mission06 self
function Mission06:Mission06()

  self.enemyFob = {}
  for i = 1, self.enemyFobCount do
    self.enemyFob[i] = self:NewEnemyFob(i)
  end

end

function Mission06:NewEnemyFob(i)

  local fobName = "FOB " .. i
  local fob = {}

  fob.sam = self.moose.group:FindByName(fobName .. " SAM")
  fob.command = self.moose.static:FindByName(fobName .. " Command")
  fob.tankSpawn = self.moose.spawn:New(fobName .. " Tanks")
  fob.heloSpawn = self.moose.spawn:New(fobName .. " Helos")

  self:Assert(fob.sam, fobName .. " SAM not found")
  self:Assert(fob.command, fobName .. " Command not found")
  self:Assert(fob.tankSpawn, fobName .. " Tanks not found")
  self:Assert(fob.heloSpawn, fobName .. " Helos not found")

  return fob

end

---
-- @param #Mission06 self
function Mission06:OnStart()

  self:MessageAll(MessageLength.Long, "Mission 6: Disrupt enemy attack on Nalchik and Beslan")
  self:MessageAll(MessageLength.Long, "Read the mission brief before takeoff")

end

---
-- @param #Mission06 self
function Mission06:OnGameLoop()
end

Mission06 = createClass(Mission, Mission06)
