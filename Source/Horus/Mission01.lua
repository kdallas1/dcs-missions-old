dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission01

--- 
-- @type Mission01
-- @extends KD.Mission#Mission
Mission01 = {
  className = "Mission01",
  
  migs2Delay = 10,
  migsMinLife = 5,
  
  ewrTotalCount = 3
}

---
-- @type Mission01.State
-- @extends KD.Mission#MissionState
Mission01.State = {
  SendNorthMigs     = State:NextState(),
  SendSouthMigs     = State:NextState(),
  AllEwrDead        = State:NextState(),
}

---
-- @param #Mission01 self
function Mission01:Mission01()

  --self:SetTraceLevel(3)
  --self.playerTestOn = false

  self.state:AddStates(Mission01.State)
  
  self.migZone = self:NewMooseZone("Send MiGs")
  self.migs1A = self:GetMooseGroup("MiGs 1A")
  self.migs1B = self:GetMooseGroup("MiGs 1B")
  self.migs2A = self:GetMooseGroup("MiGs 2A")
  self.migs2B = self:GetMooseGroup("MiGs 2B")
  self.sam = self:GetMooseUnit("EWR 2 SAM #001")
  
  self.ewrList = {}
  self.ewrList[1] = self:GetMooseUnit("EWR #001")
  self.ewrList[2] = self:GetMooseUnit("EWR #002")
  self.ewrList[3] = self:GetMooseUnit("EWR #003")
  
  self.state:TriggerOnce(
    Mission01.State.SendNorthMigs,
    function() return self.playerGroup:IsAnyInZone(self.migZone) end,
    function() self:OnSendNorthMigs() end
  )
  
  self.state:TriggerOnceAfter(
    Mission01.State.SendSouthMigs,
    Mission01.State.SendNorthMigs,
    function() return self:CountEwrAlive() < self.ewrTotalCount end,
    function() self:OnSendSouthMigs() end
  )
  
  self.state:TriggerOnceAfter(
    Mission01.State.AllEwrDead,
    Mission01.State.SendSouthMigs,
    function() return self:CountEwrAlive() == 0 end,
    function() self:OnAllEwrDead() end
  )
  
  self.state:TriggerOnceAfter(
    MissionState.MissionAccomplished,
    Mission01.State.AllEwrDead,
    function() return self:ArePlayersLanded() end
  )
  
end

---
-- @param #Mission01 self
function Mission01:OnStart()
  
  self:MessageAll(MessageLength.Long, "Mission 1: Take out the early warning radar (EWR) systems in the mountains.")
  self:MessageAll(MessageLength.Long, "Read the mission brief before takeoff")
  
  self:CreateDebugMenu({
    self.ewrList[1], self.ewrList[2], self.ewrList[3],
    self.migs1A, self.migs1B, self.migs2A, self.migs2B,
    self.sam
  })
  
end

---
-- @param #Mission01 self
function Mission01:OnGameLoop()
  
  self:SelfDestructDamagedUnitsInList(self.migs1A:GetUnits(), self.migsMinLife)
  self:SelfDestructDamagedUnitsInList(self.migs1B:GetUnits(), self.migsMinLife)
  self:SelfDestructDamagedUnitsInList(self.migs2A:GetUnits(), self.migsMinLife)
  self:SelfDestructDamagedUnitsInList(self.migs2B:GetUnits(), self.migsMinLife)
  
end

---
-- @param #Mission01 self
-- @param Wrapper.Unit#UNIT unit
function Mission01:OnUnitDead(unit)

  if (string.match(unit:GetName(), "EWR")) then
    
    self:MessageAll(MessageLength.Short, "Objective met: EWR site destroyed.")
    self:PlaySound(Sound.ObjectiveMet)
    
  end

end

function Mission01:OnSendNorthMigs()
  
  self.migs1A:Activate()
  self.migs1B:Activate()
  
  self:MessageAll(MessageLength.Short, "Enemy MiGs approaching (north).")
  self:PlaySound(Sound.EnemyApproching)
  
end

function Mission01:OnSendSouthMigs()
  
  self.moose.scheduler:New(nil, function()
  
    self:MessageAll(MessageLength.Short, "Enemy MiGs approaching (south).")
    self:PlaySound(Sound.EnemyApproching)
    
    self.migs2A:Activate()
    self.migs2B:Activate()
    
  end, {}, self.migs2Delay)
  
end

function Mission01:OnAllEwrDead()

  self:MessageAll(MessageLength.Short, "All EWRs are dead, RTB (carrier).")
  self:LandTestPlayers(self.playerGroup, "Stennis", 400)

end

function Mission01:CountEwrAlive()
  
  local count = 0
  for i = 1, #self.ewrList do
    if self.ewrList[i]:IsAlive() then
      count = count + 1
    end
  end
  return count

end

function Mission01:ArePlayersLanded()

    -- aircraft carrier moves at about 10 knots
  local carrierSpeed = 10

  for i = 1, #self.players do
    local player = self.players[i] 
    
    if player:GetVelocityKNOTS() > carrierSpeed + 5 then
      return false
    end
  end
  
  return true

end

Mission01 = createClass(Mission, Mission01)
