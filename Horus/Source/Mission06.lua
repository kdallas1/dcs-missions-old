dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission06

--- 
-- @type Mission06
-- @extends KD.Mission#Mission
Mission06 = {
  className = "Mission06",

  traceLevel = 2,

  enemyFobMax = 4,
  enemyFobSpawnStart = 0,
  enemyFobSpawnGap = 60,

  friendlyBaseMax = 2,
  friendlyBaseSpawnStart = 0,
  friendlyBaseSpawnGap = 60,

  friendlyBaseNames = {
    [1] = "Nalchik",
    [2] = "Beslan"
  }
}

---
-- @param #Mission06 self
function Mission06:Mission06()

  self.enemyFob = {}
  for i = 1, self.enemyFobMax do
    self.enemyFob[i] = self:NewEnemyFob(i)
  end

  self.friendlyBase = {}
  for i = 1, self.enemyFobMax do
    self.friendlyBase[i] = self:NewFriendlyBase(i)
  end

end

function Mission06:NewEnemyFob(i)

  local fobName = "Enemy FOB " .. i
  local fob = {}

  fob.name = fobName
  fob.sam = self.moose.group:FindByName(fobName .. " SAM")
  fob.command = self.moose.unit:FindByName(fobName .. " Command")
  fob.tankSpawn = self.moose.spawn:New(fobName .. " Tanks")
  fob.heloSpawn = self.moose.spawn:New(fobName .. " Helos")

  self:Assert(fob.sam, fobName .. " SAM not found")
  self:Assert(fob.command, fobName .. " Command not found")
  self:Assert(fob.tankSpawn, fobName .. " Tanks not found")
  self:Assert(fob.heloSpawn, fobName .. " Helos not found")

  fob.command.enemyFob = fob

  self.moose.scheduler:New(nil, function()
    fob.tankSpawn:Spawn()
    fob.heloSpawn:Spawn()
  end, {}, self.enemyFobSpawnStart, self.enemyFobSpawnGap)

  return fob

end

function Mission06:NewFriendlyBase(i)

  local baseName = "Base " .. i
  local base = {}

  base.name = self.friendlyBaseNames[i]
  base.sam = self.moose.group:FindByName(baseName .. " SAM")
  base.command = self.moose.unit:FindByName(baseName .. " Command")
  base.tankSpawn = self.moose.spawn:New(baseName .. " Tanks")
  base.heloSpawn = self.moose.spawn:New(baseName .. " Helos")

  self:Assert(base.sam, baseName .. " SAM not found")
  self:Assert(base.command, baseName .. " Command not found")
  self:Assert(base.tankSpawn, baseName .. " Tanks not found")
  self:Assert(base.heloSpawn, baseName .. " Helos not found")

  base.command.friendlyBase = base

  self.moose.scheduler:New(nil, function()
    base.tankSpawn:Spawn()
    base.heloSpawn:Spawn()
  end, {}, self.friendlyBaseSpawnStart, self.friendlyBaseSpawnGap)

  return base

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

---
-- @param #Mission06 self
-- @param Wrapper.Unit#UNIT unit
function Mission06:OnUnitDamaged(unit)

  self:Trace(1, "Unit damaged: " .. unit:GetName())

  if (unit.friendlyBase) then

    self:PlaySound(Sound.OurBaseIsUnderAttack)
    self:MessageAll(MessageLength.Long, unit.friendlyBase.name + " is under attack! Health: " .. unit.GetLife())

  end

  if (unit.enemyFob) then

    self:PlaySound(Sound.ShakeItBaby)
    self:MessageAll(MessageLength.Short, unit.enemyFob.name + " is taking damage. Health: " .. unit.GetLife())

  end

end

---
-- @param #Mission06 self
-- @param Wrapper.Unit#UNIT unit
function Mission06:OnUnitDead(unit)

  self:Trace(1, "Unit dead: " .. unit:GetName())

  if (unit.friendlyBase) then

    self:PlaySound(Sound.StructureDestoyed)
    self:MessageAll(MessageLength.Long, unit.friendlyBase.name + " has been captured!")
    self.state.Change(MissionState.MissionFailed)

  end

  if (unit.enemyFob) then

    self:PlaySound(Sound.KissItByeBye)
    self:MessageAll(MessageLength.Short, unit.enemyFob.name + " has been destroyed!")
    unit.enemyFob.dead = true

  end

end

Mission06 = createClass(Mission, Mission06)
