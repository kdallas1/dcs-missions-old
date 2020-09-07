dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission09

--- 
-- @type Mission09
-- @extends KD.Mission#Mission
Mission09 = {
  className = "Mission09",
  
  enableDebugMenu = true,
  
  enemySoldiersMax = 5,
  enemyTanksMax = 5,
  enemyHelosMax = 5,
  enemyJetsMaxPerPlayer = 1,
  enemySpawnInterval = 30,
  enemyJetsSpawnInterval = 300,
  enemyJetsAliveCount = 0,
  
  friendlySoldiersMax = 5,
  friendlyTanksMax = 3,
  friendlyHelosMax = 3,
  friendlySpawnInterval = 30,
  
  spawnVariation = .5,
}

---
-- @type Mission09.State
-- @extends KD.Mission#MissionState
Mission09.State = {
  EnemyCommandDead = State:NextState(),
  EnemySoldiersDead = State:NextState(),
}

---
-- @param #Mission09 self
function Mission09:Mission09()

  --self:SetTraceLevel(3)
  --self.playerTestOn = false
  
  self.state:AddStates(Mission09.State)
  self.state:CopyTrace(self)

  self.mineralnyeVodyPark = self:NewMooseZone("Mineralnye Vody Park")
  
  self.enemyCommand1 = self:GetMooseGroup("Enemy Command #001")
  self.enemyCommand2 = self:GetMooseGroup("Enemy Command #002")
  self.enemySoldiers = self:NewMooseSpawn("Enemy Soldiers", self.enemySoldiersMax)
  self.enemyTanks = self:NewMooseSpawn("Enemy Tanks", self.enemyTanksMax)
  self.enemyHelos = self:NewMooseSpawn("Enemy Helos", self.enemyHelosMax)
  self.enemyJets = self:NewMooseSpawn("Enemy Jets")
  self.enemyAaa = self:GetMooseGroup("Enemy AAA")
  
  self.friendlyCommand1 = self:GetMooseGroup("Friendly Command #001")
  self.friendlyCommand2 = self:GetMooseGroup("Friendly Command #002")
  self.friendlySoldiers = self:NewMooseSpawn("Friendly Soldiers", self.friendlySoldiersMax)
  self.friendlyTanks = self:NewMooseSpawn("Friendly Tanks", self.friendlyTanksMax)
  self.friendlyHelos = self:NewMooseSpawn("Friendly Helos", self.friendlyHelosMax)
  
  self.state:TriggerOnce(
    MissionState.MissionFailed,
    function() return self:IsMissionFailed() end
  )

  self.state:TriggerOnce(
    Mission09.State.EnemyCommandDead,
    function() return self:IsEnemyCommandDead() end,
    function() self:OnEnemyCommandDead() end
  )

  self.state:TriggerOnceAfter(
    Mission09.State.EnemySoldiersDead,
    Mission09.State.EnemyCommandDead,
    function() return (self:CountAliveUnitsFromSpawn(self.enemySoldiers) == 0) end,
    function() self:OnEnemySoldiersDead() end
  )

  self.state:TriggerOnceAfter(
    MissionState.MissionAccomplished,
    Mission09.State.EnemySoldiersDead,
    function() return self:UnitsAreParked(self.mineralnyeVodyPark, self.players) end
  )
  
end

---
-- @param #Mission09 self
function Mission09:OnStart()
  
  if self.enableDebugMenu then
    self:CreateDebugMenu({
      self.playerGroup,
      self.enemyCommand1,
      self.enemyCommand2,
      self.enemySoldiers,
      self.enemyTanks,
      self.enemyHelos,
      self.enemyJets,
      self.friendlyCommand1,
      self.friendlyCommand2,
      self.friendlySoldiers,
      self.friendlyTanks,
      self.friendlyHelos
    })
  end

  self:MessageAll(MessageLength.Long, "Mission 9: Final assault on the ALF, capture Mineralnye Vody.")
  self:MessageAll(MessageLength.Long, "Read the mission brief before takeoff")
  
  self.moose.scheduler:New(nil, function()
    self.enemySoldiers:SpawnScheduled(self.enemySpawnInterval, self.spawnVariation)
    self.enemyTanks:SpawnScheduled(self.enemySpawnInterval, self.spawnVariation)
    self.enemyHelos:SpawnScheduled(self.enemySpawnInterval, self.spawnVariation)
    
    self.friendlySoldiers:SpawnScheduled(self.friendlySpawnInterval, self.spawnVariation)
    self.friendlyTanks:SpawnScheduled(self.friendlySpawnInterval, self.spawnVariation)
    self.friendlyHelos:SpawnScheduled(self.friendlySpawnInterval, self.spawnVariation)
  end, {}, 300)

end

---
-- @param #Mission09 self
function Mission09:OnGameLoop()

  self:SelfDestructDamagedUnits(self.enemyJets, 5)
  self:SelfDestructDamagedUnits(self.enemyHelos, 10)
  self:SelfDestructDamagedUnits(self.friendlyHelos, 10)
  
end

---
-- @param #Mission09 self
-- @param Wrapper.Unit#UNIT unit
function Mission09:OnUnitSpawn(unit)

  if (string.match(unit:GetName(), "Enemy Jets")) then
    
    self.enemyJetsAliveCount = self.enemyJetsAliveCount + 1
    
    self:PlaySound(Sound.EnemyApproching)
    self:MessageAll(MessageLength.Short, 
      "Enemy MiG approaching from Mineralnye Vody. Alive: " .. self.enemyJetsAliveCount)
    
  end

end

---
-- @param #Mission09 self
-- @param Wrapper.Unit#UNIT unit
function Mission09:OnPlayerSpawn(unit)

  self.enemyJets:InitLimit(self.enemyJetsMaxPerPlayer * #self.players, 0)
  
  -- start enemy jet spawn if not started yet
  if not self.enemyJets.SpawnScheduler then
    self.enemyJets:SpawnScheduled(self.enemyJetsSpawnInterval, self.spawnVariation)
  end

end

---
-- @param #Mission09 self
-- @param Wrapper.Unit#UNIT unit
function Mission09:OnUnitDead(unit)

  self:Trace(1, "Unit dead: " .. unit:GetName())
  
  if (string.match(unit:GetName(), "Friendly")) then
  
    if (string.match(unit:GetName(), "Command")) then
      
      self:PlaySound(Sound.CommandCentreUnderAttack)
      self:MessageAll(MessageLength.Short, "Friendly command lost: " .. unit:GetName())
      
      if self:IsFriendlyCommandDead() then
      
        self.friendlySoldiers:SpawnScheduleStop()
        self.friendlyTanks:SpawnScheduleStop()
        self.friendlyHelos:SpawnScheduleStop()
        
      end
      
    else
    
      self:MessageAll(MessageLength.VeryShort, "Friendly unit lost: " .. (unit:GetTypeName() or unit:GetName()))
      
    end
    
  elseif (string.match(unit:GetName(), "Enemy")) then
    
    if (string.match(unit:GetName(), "Jets")) then
    
      self.enemyJetsAliveCount = self.enemyJetsAliveCount - 1
      self:MessageAll(MessageLength.Short, "Enemy MiGs destroyed. Remaining: " .. self.enemyJetsAliveCount)
      self:PlayEnemyDeadSound()
  
    elseif (string.match(unit:GetName(), "Command")) then
      
      self:PlaySound(Sound.StructureDestoyed)
      self:MessageAll(MessageLength.Short, "Enemy command destroyed: " .. unit:GetName())
      
    else
      
      self:MessageAll(MessageLength.VeryShort, "Enemy unit destroyed: " .. (unit:GetTypeName() or unit:GetName()))
      
    end
    
  end

end

---
-- @param #Mission09 self
function Mission09:OnEnemySoldiersDead()

  self:MessageAll(MessageLength.Long, "Second objective met. Land at Mineralnye Vody.")
  self:PlaySound(Sound.SecondObjectiveMet, 2)
  
  self:LandTestPlayers(self.playerGroup, self.moose.airbase.Caucasus.Mineralnye_Vody, 400)
  
end

---
-- @param #Mission09 self
function Mission09:OnEnemyCommandDead()

  self:MessageAll(MessageLength.Long, "First objective met. Second objective: Ensure all ALF soldiers are destroyed.")
  self:PlaySound(Sound.FirstObjectiveMet, 2)
  
  self.enemySoldiers:SpawnScheduleStop()
  self.enemyTanks:SpawnScheduleStop()
  self.enemyHelos:SpawnScheduleStop()
  
  if self.enemyJets.SpawnScheduler then
    self.enemyJets:SpawnScheduleStop()
  end
  
  self:SelfDestructGroup(self.enemyAaa, 100, 0, 0)
  
end

---
-- @param #Mission09 self
function Mission09:IsMissionFailed()

  local friendlyCommandDead = self:IsFriendlyCommandDead()
  local friendlySoldersDead = (self:CountAliveUnitsFromSpawn(self.friendlySoldiers) == 0)
  return friendlyCommandDead and friendlySoldersDead
  
end

---
-- @param #Mission09 self
function Mission09:IsEnemyCommandDead()

  return (self.enemyCommand1:CountAliveUnits() <= 0) and (self.enemyCommand2:CountAliveUnits() <= 0)
  
end

---
-- @param #Mission09 self
function Mission09:IsFriendlyCommandDead()

  return (self.friendlyCommand1:CountAliveUnits() <= 0) and (self.friendlyCommand2:CountAliveUnits() <= 0)
  
end

Mission09 = createClass(Mission, Mission09)
