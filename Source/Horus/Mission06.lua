dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission06

--- 
-- @type Mission06
-- @extends KD.Mission#Mission
Mission06 = {
  className = "Mission06",

  enemyFobMax = 4,
  enemyFobSpawnStart = 0,
  enemyFobSpawnGap = 60,
  enemyFobMaxAlivePerSpawn = 2,
  enemyTankMinLife = 10,
  enemyHeloMinLife = 10,

  friendlyBaseMax = 2,
  friendlyBaseSpawnStart = 0,
  friendlyBaseSpawnGap = 60,
  friendlyBaseMaxAlivePerSpawn = 3,
  friendlyTankMinLife = 10,
  friendlyHeloMinLife = 10,

  friendlyBaseNames = {
    [1] = "Nalchik",
    [2] = "Beslan"
  }
}

---
-- @type Mission06.State
-- @extends KD.Mission#MissionState
Mission06.State = {
  EnemyFobsDead        = State:NextState(),
}

---
-- @param #Mission06 self
function Mission06:Mission06()

  --self:SetTraceLevel(3)
  --self.playerTestOn = false

  self.state:AddStates(Mission06.State)

  self.enemyFob = {}
  for i = 1, self.enemyFobMax do
    self.enemyFob[i] = self:NewEnemyFob(i)
  end

  self.friendlyBase = {}
  for i = 1, self.friendlyBaseMax do
    self.friendlyBase[i] = self:NewFriendlyBase(i)
  end

  self.nalchikParkZone = self.moose.zone:New("Nalchik Park")
  self:Assert(self.nalchikParkZone, "Nalchik park zone not found")

  self.state:TriggerOnce(
    Mission06.State.EnemyFobsDead,
    function() return (self:EnemyFobAliveCount() == 0) end
  )

  self.state:TriggerOnceAfter(
    MissionState.MissionAccomplished,
    Mission06.State.EnemyFobsDead,
    function() return self:UnitsAreParked(self.nalchikParkZone, self.players) end
  )
  
  self:SetupMenu()

end

---
-- @param #Mission06 self
function Mission06:SetupMenu()

  local menu = self.moose.menu.coalition:New(self.dcs.coalition.side.BLUE, "Debug")
  
  self.moose.menu.coalitionCommand:New(
    self.dcs.coalition.side.BLUE, "Kill players", menu,
    function() self:SelfDestructGroup(self.playerGroup, 100, 1, 1) end)
  
  for i = 1, self.friendlyBaseMax do
    self.moose.menu.coalitionCommand:New(
      self.dcs.coalition.side.BLUE, "Kill Base " .. i .. " Command", menu,
      function() self:SelfDestructUnits({ self.friendlyBase[i].command }, 100, 1, 1) end)
  end
  
  for i = 1, self.enemyFobMax do
    self.moose.menu.coalitionCommand:New(
      self.dcs.coalition.side.BLUE, "Kill FOB " .. i .. " Command", menu,
      function() self:SelfDestructUnits({ self.enemyFob[i].command }, 100, 1, 1) end)
  end
  
end

function Mission06:NewEnemyFob(i)

  local fobName = "FOB " .. i
  local fob = {}

  fob.name = fobName
  fob.command = self.moose.unit:FindByName(fobName .. " Command")
  fob.tankSpawn = self.moose.spawn:New(fobName .. " Tanks")
  fob.heloSpawn = self.moose.spawn:New(fobName .. " Helos")

  self:Assert(fob.command, fobName .. " Command not found")
  self:Assert(fob.tankSpawn, fobName .. " Tanks not found")
  self:Assert(fob.heloSpawn, fobName .. " Helos not found")

  fob.command.enemyFob = fob

  self:AddUnit(fob.command)
  self:AddSpawner(fob.tankSpawn)
  self:AddSpawner(fob.heloSpawn)

  self.moose.scheduler:New(nil, function()
    if (fob.command:IsAlive()) then
      
      if (self:CountAliveUnitsFromSpawn(fob.tankSpawn) < self.enemyFobMaxAlivePerSpawn) then
        self:AddGroup(fob.tankSpawn:Spawn())
      end
      
      if (self:CountAliveUnitsFromSpawn(fob.heloSpawn) < self.enemyFobMaxAlivePerSpawn) then
        self:AddGroup(fob.heloSpawn:Spawn())
      end
      
      fob.command:SmokeRed()
    end
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

  self:AddGroup(base.sam)
  self:AddUnit(base.command)
  self:AddSpawner(base.tankSpawn)
  self:AddSpawner(base.heloSpawn)

  self.moose.scheduler:New(nil, function()
    if (base.command:IsAlive()) then
      if (self:CountAliveUnitsFromSpawn(base.tankSpawn) < self.friendlyBaseMaxAlivePerSpawn) then
        self:AddGroup(base.tankSpawn:Spawn())
      end
      
      if (self:CountAliveUnitsFromSpawn(base.heloSpawn) < self.friendlyBaseMaxAlivePerSpawn) then
        self:AddGroup(base.heloSpawn:Spawn())
      end
    end
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

  for i = 1, #self.enemyFob do
    local fob = self.enemyFob[i]
    self:SelfDestructDamagedUnits(fob.tankSpawn, self.enemyTankMinLife)
    self:SelfDestructDamagedUnits(fob.heloSpawn, self.enemyHeloMinLife)
  end
  
  for i = 1, #self.friendlyBase do
    local base = self.friendlyBase[i]
    self:SelfDestructDamagedUnits(base.tankSpawn, self.friendlyTankMinLife)
    self:SelfDestructDamagedUnits(base.heloSpawn, self.friendlyHeloMinLife)
  end
  
end

---
-- @param #Mission06 self
-- @param Wrapper.Unit#UNIT unit
function Mission06:OnUnitDamaged(unit)

  self:Trace(1, "Unit damaged: " .. unit:GetName())

  if (unit.friendlyBase) then

    self:PlaySound(Sound.OurBaseIsUnderAttack)
    self:MessageAll(MessageLength.Long, unit.friendlyBase.name .. " is under attack! Health: " .. unit.GetLife())

  end

  if (unit.enemyFob) then

    self:PlaySound(Sound.ShakeItBaby)
    self:MessageAll(MessageLength.Short, unit.enemyFob.name .. " is taking damage. Health: " .. unit.GetLife())

  end

end

---
-- @param #Mission06 self
-- @param Wrapper.Unit#UNIT unit
function Mission06:OnUnitDead(unit)

  self:Trace(1, "Unit dead: " .. unit:GetName())

  if (unit.friendlyBase) then

    self:PlaySound(Sound.StructureDestoyed)
    self:MessageAll(MessageLength.Long, unit.friendlyBase.name .. " has been captured!")
    self.state:Change(MissionState.MissionFailed)

  end

  if (unit.enemyFob) then

    self:PlaySound(Sound.KissItByeBye)
    self:MessageAll(MessageLength.Short, unit.enemyFob.name .. " has been destroyed!")
    unit.enemyFob.dead = true

  end

end

function Mission06:EnemyFobAliveCount()

  local count = 0
  for i = 1, #self.enemyFob do
    if not self.enemyFob[i].dead then
      count = count + 1
    end
  end
  return count

end

Mission06 = createClass(Mission, Mission06)
