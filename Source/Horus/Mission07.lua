dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission07

--- 
-- @type Mission07
-- @extends KD.Mission#Mission
Mission07 = {
  className = "Mission07",

  enemyJetSpawnCount = 10,
  enemyJetInfoStart = 10,
  enemyJetSpawnStart = 300
}

---
-- @type Mission07.State
-- @extends KD.Mission#MissionState
Mission07.State = {
}

---
-- @param #Mission07 self
function Mission07:Mission07()

  self.nalchikParkZone = self:NewMooseZone("Nalchik Park")
  
  self.enemyJetSpawns = {}
  for i = 1, self.enemyJetSpawnCount do
    self.enemyJetSpawns[i] = self:NewMooseSpawn("Enemy Jet " .. self:GetDcsNumber(i))
  end

  self.state:TriggerOnce(
    MissionState.MissionAccomplished,
    function() return self:CountEnemyJets() == 0 end
  )

end

---
-- @param #Mission07 self
function Mission07:OnStart()

  self:MessageAll(MessageLength.Long, "Mission 7: Capture Mozdok; destroy enemy aircraft on the ground")
  self:MessageAll(MessageLength.Long, "Read the mission brief before takeoff")

  self.moose.scheduler:New(nil, function()

    self:PlaySound(Sound.MissionTimerInitialised)
    self:MessageAll(MessageLength.Short, "Enemy fighters are being mobilised in T-5 minutes.")

  end, {}, self.enemyJetInfoStart)

  self.moose.scheduler:New(nil, function()

    self:PlaySound(Sound.EnemyApproching)
    self:MessageAll(MessageLength.Short, "Enemy fighters have been mobilised, takeoff in 60 seconds.")

  end, {}, self.enemyJetInfoStart + self.enemyJetSpawnStart)

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
  
  if (string.match(unit:GetName(), "Enemy")) then
    
    if (string.match(unit:GetName(), "Jet")) then
    
      self:MessageAll(MessageLength.Short, "Enemy jet destroyed. Remaining: " .. self:CountEnemyJets())
      self:PlayEnemyDeadSound()
  
    end
    
  end
end

function Mission07:CountEnemyJets()
  local count = 0
  for i = 1, #self.enemyJetSpawns do
    count = count + self:CountAliveUnitsFromSpawn(self.enemyJetSpawns[i])
  end
  return count
end

Mission07 = createClass(Mission, Mission07)
