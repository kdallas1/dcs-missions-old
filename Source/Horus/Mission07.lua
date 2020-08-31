dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission07

--- 
-- @type Mission07
-- @extends KD.Mission#Mission
Mission07 = {
  className = "Mission07",

  --- @field [parent=#Mission07] #list<Wrapper.Group#GROUP> enemyJetList
  enemyJetList = nil,
  
  enemyJetSpawnMaxPerPlayer = 5,
  enemyJetSpawnDelay = 120,
  enemyJetSpawnCount = 0,
  enemyJetDeadCount = 0,
  enemyJetSpawnSeparation = 60,
  enemyJetSpawnRandom = .5,
  enemyJetType = "Mirage 2000-5"
}

---
-- @type Mission07.State
-- @extends KD.Mission#MissionState
Mission07.State = {
  EnemyJetsActive = State:NextState(),
  EnemyJetsDestroyed = State:NextState(),
}

---
-- @type Mission07.EnemyJetStates
-- @extends KD.Mission#MissionState
Mission07.EnemyJetStates = {
  Idle = Event:NextEvent(),
  Startup = Event:NextEvent(),
  Taxiing = Event:NextEvent(),
  TakingOff = Event:NextEvent(),
}

---
-- @param #Mission07 self
function Mission07:Mission07()

  --self:SetTraceLevel(3)
  --self.playerTestOn = false

  self.state:AddStates(Mission07.State)

  self.mozdokParkZone = self:NewMooseZone("Mozdok Park")
  self.mozdokActivateZone = self:NewMooseZone("Mozdok Activate")
  self.mozdokTakeoffZone = self:NewMooseZone("Mozdok Takeoff")
  self.enemyJetSpawn = self:NewMooseSpawn("Enemy Jets")
  
  self.enemyJetList = {}

  self.state:TriggerOnce(
    Mission07.State.EnemyJetsActive,
    function() return self.playerGroup:IsCompletelyInZone(self.mozdokActivateZone) end,
    function()
      self:MessageAll(MessageLength.Long, "Enemy jets (" .. self.enemyJetType .. ") are being mobilised, take off ETA 5 minutes.")
      self:MessageAll(MessageLength.Long, "Start bombing those jets and don't let them take off!")
      self:PlaySound(Sound.MissionTimerInitialised)
      self:ActivateEnemyJets(self.enemyJetSpawnDelay, self.enemyJetSpawnSeparation, self.enemyJetSpawnRandom)
    end
  )

  self.state:TriggerOnceAfter(
    Mission07.State.EnemyJetsDestroyed,
    Mission07.State.EnemyJetsActive,
    function() return (self:CountAliveUnitsFromSpawn(self.enemyJetSpawn) == 0) end,
    function()
      self:MessageAll(MessageLength.Long, "First objective met. Now land at Mozdok.")
      self:PlaySound(Sound.FirstObjectiveMet)
    end
  )

  self.state:TriggerOnceAfter(
    MissionState.MissionAccomplished,
    Mission07.State.EnemyJetsDestroyed,
    function() return self:UnitsAreParked(self.mozdokParkZone, self.players) end
  )

end

---
-- @param #Mission07 self
function Mission07:OnStart()

  self:MessageAll(MessageLength.Long, "Mission 7: Capture Mozdok; destroy enemy aircraft on the ground")
  self:MessageAll(MessageLength.Long, "Read the mission brief before takeoff")
  
  self:CreateDebugMenu({
    self.playerGroup,
    self.enemyJetSpawn
  })

end

---
-- @param #Mission07 self
function Mission07:OnGameLoop()

    self:SpawnEnemyJets()
    
    for i = 1, #self.enemyJetList do
      local jet = self.enemyJetList[i]
      jet.state:CheckTriggers()
    end
    
    self:SelfDestructDamagedUnits(self.enemyJetSpawn, 5)
    
end

---
-- @param #Mission07 self
-- @param Wrapper.Unit#UNIT unit
function Mission07:OnUnitDead(unit)

  self:Trace(1, "Unit dead: " .. unit:GetName())
  
  if (string.match(unit:GetName(), "Enemy")) then
    
    if (string.match(unit:GetName(), "Jet")) then
    
      self.enemyJetDeadCount = self.enemyJetDeadCount + 1
      local remain = self:GetEnemyJetSpawnMax() - self.enemyJetDeadCount
      
      self:MessageAll(MessageLength.Short, unit:GetName() .. " destroyed. Remaining: " .. remain)
      self:PlayEnemyDeadSound()
  
    end
    
  end
end

---
-- @param #Mission07 self
function Mission07:GetEnemyJetSpawnMax()

  return (#self.players * self.enemyJetSpawnMaxPerPlayer)

end

---
-- @param #Mission07 self
function Mission07:SpawnEnemyJets()

  local maxJets = (self:GetEnemyJetSpawnMax() - self.enemyJetSpawnCount)
  for i = 1, maxJets do
    
    -- spawn uncontrolled so the jet doesn't take off yet.
    self.enemyJetSpawn:InitUnControlled(true)
    
    local jet = self.enemyJetSpawn:SpawnAtAirbase(
        self.moose.airbase:FindByName(self.moose.airbase.Caucasus.Mozdok),
        self.moose.spawn.Takeoff.Cold)
        
    jet.state = StateMachine:New()
    jet.state.current = Mission07.EnemyJetStates.Idle
    
    self.enemyJetList[#self.enemyJetList + 1] = jet
    
    self.enemyJetSpawnCount = self.enemyJetSpawnCount + 1
    
  end

end

---
-- @param #Mission07 self
function Mission07:ActivateEnemyJets(delay, separation, random)
  
  self:Assert(delay ~= nil, "Arg: `delay` was nil.")
  self:Assert(separation ~= nil, "Arg: `separation` was nil.")
  self:Assert(random ~= nil, "Arg: `random` was nil.")
  
  for i = 1, #self.enemyJetList do
  
    local time = delay + math.random((i * separation) * random, (i * separation))
    self:Trace(2, "Scheduling enemy jet #" .. i .. " spawn at: " .. time)
    self.moose.scheduler:New(nil, function() self:ActivateEnemyJet(i) end, {}, time)
    
  end

end

---
-- @param #Mission07 self
function Mission07:ActivateEnemyJet(index)

  self:Assert(index ~= nil, "Arg: `index` was nil.")
  
  -- respawn makes a new object, so replace the existing one in the list
  local oldJet = self.enemyJetList[index]
  local jet = oldJet:RespawnAtCurrentAirbase(nil, self.moose.spawn.Takeoff.Cold)
  self.enemyJetList[index] = jet
  
  jet.GetName = function()
    return "Enemy " .. self.enemyJetType .. " " .. self:GetDcsNumber(index)
  end
  
  jet.state = StateMachine:New()
  jet.state.current = Mission07.EnemyJetStates.Startup
  self:MessageAll(MessageLength.VeryShort, "Enemy jet starting: " .. jet:GetName())
  
  jet.state:TriggerOnceAfter(
    Mission07.EnemyJetStates.Taxiing,
    Mission07.EnemyJetStates.Startup,
    function() return (jet:GetVelocityKNOTS() > 1) end,
    function() self:MessageAll(MessageLength.VeryShort, "Enemy jet taxiing: " .. jet:GetName()) end
  )
  
  jet.state:TriggerOnceAfter(
    Mission07.EnemyJetStates.TakingOff,
    Mission07.EnemyJetStates.Taxiing,
    function() return jet:IsAnyInZone(self.mozdokTakeoffZone) end,
    function() self:MessageAll(MessageLength.VeryShort, "Enemy jet taking off: " .. jet:GetName()) end
  )
  
end

Mission07 = createClass(Mission, Mission07)
