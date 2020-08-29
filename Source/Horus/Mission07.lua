dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission07

--- 
-- @type Mission07
-- @extends KD.Mission#Mission
Mission07 = {
  className = "Mission07",

  enemyJetInfoStart = 10,
  enemyJetSpawnStart = 300,
  enemyJetSpawnSeparation = 300,
  enemyJetSpawnMaxPerPlayer = 3,
  enemyJetSpawnDelay = 60
}

---
-- @type Mission07.State
-- @extends KD.Mission#MissionState
Mission07.State = {
  EnemyJetsDestroyed = State:NextState(),
}

---
-- @param #Mission07 self
function Mission07:Mission07()

  self.mozdokParkZone = self:NewMooseZone("Mozdok Park")
  self.enemyJets = self:NewMooseSpawn("Enemy Jets")

  self.state:TriggerOnce(
    Mission07.State.EnemyJetsDestroyed,
    function() return (self:CountAliveUnitsFromSpawn(self.enemyJets) == 0) end,
    function()
      self:MessageAll(MessageLength.Long, "First objective met. Land at Mozdok.")
      self:PlaySound(Sound.FirstObjectiveMet)
      self.enemyJets:SpawnScheduleStop()
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

  self.moose.scheduler:New(nil, function()

    -- TODO: is a cold start actually 5 mins?
    self:MessageAll(MessageLength.Short, "Enemy jets are being mobilised in T-5 minutes.")
    self:PlaySound(Sound.MissionTimerInitialised)

    local enemyJetsMax = #self.players * self.enemyJetSpawnMaxPerPlayer
    local startCount = enemyJetsMax - self:CountAliveUnitsFromSpawn(self.enemyJets)
    self:SpawnEnemyJets(startCount)

    self.moose.scheduler:New(nil, function()
  
      self:MessageAll(MessageLength.Short, "Enemy jets have been mobilised, takeoff in 60 seconds.")
      self:PlaySound(Sound.EnemyApproching)
  
    end, {}, self.enemyJetSpawnStart, self.enemyJetSpawnSeparation)

  end, {}, self.enemyJetInfoStart)

end

---
-- @param #Mission07 self
-- @param Wrapper.Unit#UNIT unit
function Mission07:OnUnitDead(unit)

  self:Trace(1, "Unit dead: " .. unit:GetName())
  
  if (string.match(unit:GetName(), "Enemy")) then
    
    if (string.match(unit:GetName(), "Jet")) then
    
      self:MessageAll(MessageLength.Short, "Enemy jet destroyed. Remaining: " .. self:CountEnemyJets())
      self:PlayEnemyDeadSound()

      self.moose.scheduler:New(nil, function()
        self:SpawnEnemyJets(1)
      end, {}, self.enemyJetSpawnDelay)
  
    end
    
  end
end

---
-- @param #Mission07 self
function Mission07:SpawnEnemyJets(count)

  for i = 1, count do

    self.enemyJets:SpawnAtAirbase(
        self.moose.airbase:FindByName(self.moose.airbase.Caucasus.Mozdok),
        self.moose.spawn.Takeoff.Cold)
    
  end

end

Mission07 = createClass(Mission, Mission07)
