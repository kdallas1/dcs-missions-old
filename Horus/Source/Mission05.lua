dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission05

--- 
-- @type Mission05
-- @extends KD.Mission#Mission
Mission05 = {
  className = "Mission05",

  traceLevel = 2
}

---
-- @type Mission05.State
-- @extends KD.Mission#MissionState
Mission05.State = {
  EnemySamsDestroyed        = State:NextState(),
  FriendlyHeloProceed       = State:NextState(),
  FriendlyHeloLanded        = State:NextState(),
  EnemyBaseDestroyed        = State:NextState(),
}

---
-- @param #Mission05 self
function Mission05:Mission05()

  self:LoadPlayer()
  
  self.friendlyHeloGroup = self.moose.group:FindByName("Friendly Helos")
  self.enemySamGroup = self.moose.group:FindByName("Enemy SAMs")
  self.landingZone = self.moose.zone:FindByName("Landing")
  
  self:Assert(self.friendlyHeloGroup, "Friendly helo group not found")
  self:Assert(self.enemySamGroup, "Enemy SAM group not found")
  self:Assert(self.landingZone, "Landing zone not found")
  
  self:AddGroup(self.friendlyHeloGroup)
  self:AddGroup(self.enemySamGroup)
  
  self.state:TriggerOnce(
    Mission05.State.EnemySamsDestroyed,
    function() return (self.enemySamGroup:CountAliveUnits() == 0) end,
    function() self:OnEnemySamsDestroyed() end
  )
  
  self.state:TriggerOnce(
    Mission05.State.FriendlyHeloLanded,
    function() return self:GroupIsParked(self.landingZone, self.friendlyHeloGroup) end,
    function() self:OnFriendlyHeloLanded() end
  )
  
  self.state:TriggerOnceAfter(
    MissionState.MissionAccomplished,
    Mission05.State.EnemyBaseDestroyed,
    function() return self:UnitsAreParked(self.nalchikPark, self.players) end,
    function() self:AnnounceWin(2) end
  )
  
  self.state:TriggerOnce(
    MissionState.MissionFailed,
    function() return (self.friendlyHeloGroup:CountAliveUnits() == 0) end,
    function() self:AnnounceLose(2) end
  )
  
  self.state:SetFinal(MissionState.MissionAccomplished)
  self.state:SetFinal(MissionState.MissionFailed)
  
  self:SetupMenu()
  
end

---
-- @param #Mission05 self
-- @param Wrapper.Unit#UNIT unit
function Mission05:OnUnitDead(unit)

  self:Trace(1, "Unit dead: " .. unit:GetName())
    
  if (string.match(unit:GetName(), "Friendly Helo")) then
    
    self:Trace(1, "Friendly helo destroyed: " .. unit:GetName())
    self:MessageAll(MessageLength.Long, "Friendly helo destroyed!")
    self:PlaySound(Sound.UnitLost)
    
  end
  
  if (string.match(unit:GetName(), "Enemy SAM")) then
    
    self:Trace(1, "Enemy SAM destroyed: " .. unit:GetName())
    self:MessageAll(MessageLength.Short, "Enemy SAM destroyed!")
    self:PlayEnemyDeadSound()
    
  end
  
end

---
-- @param #Mission05 self
function Mission05:OnEnemySamsDestroyed()
  
  self:MessageAll(MessageLength.Short, "All SAMs have been destroyed")
  self:PlaySound(Sound.FirstObjectiveMet, 3)
  
end

---
-- @param #Mission05 self
function Mission05:OnFriendlyHeloLanded()
  
  self:MessageAll(MessageLength.Short, "Friendly helos have landed, planting C4")
  self:ExplodeC4(1)
  
end

---
-- @param #Mission05 self
function Mission05:SetupMenu()

  local menu = self.moose.menu.coalition:New(self.dcs.coalition.side.BLUE, "Debug")
  
  self.moose.menu.coalitionCommand:New(
    self.dcs.coalition.side.BLUE, "Kill players", menu,
    function() self:SelfDestructGroup(self.playerGroup, 100, 1, 1) end)
  
  self.moose.menu.coalitionCommand:New(
    self.dcs.coalition.side.BLUE, "Kill friendly helos", menu,
    function() self:SelfDestructGroup(self.friendlyHeloGroup, 100, 1, 1) end)
  
  self.moose.menu.coalitionCommand:New(
    self.dcs.coalition.side.BLUE, "Kill enemy SAMs", menu,
    function() self:SelfDestructGroup(self.enemySamGroup, 100, 1, 1) end)
    
end

---
-- @param #Mission05 self
function Mission05:OnStart()
  
  self:MessageAll(MessageLength.Long, "Mission 5: Sneak-attack on Beslan")
  self:MessageAll(MessageLength.Long, "Read the mission brief before takeoff")
  
end

---
-- @param #Mission05 self
function Mission05:ExplodeC4(delay)
  
  self:MessageAll(MessageLength.Short, "[Commandos] Light 'er up!")
  for i = 1, 40 do
    local name = string.format("C4 #%03d", i)
    local c4 = STATIC:FindByName(name)
    if c4 then
      SCHEDULER:New(nil, function() c4:GetCoordinate():Explosion(100) end, {}, delay + math.random(1, 20))
    end
  end
  
  self.state:Change(Mission05.State.EnemyBaseDestroyed)
  
end

---
-- @param #Mission05 self
function Mission05:OnGameLoop()
  
  self:SelfDestructDamagedUnitsInList(self.friendlyHeloGroup:GetUnits(), 10)
  self:SelfDestructDamagedUnitsInList(self.enemySamGroup:GetUnits(), 2)
  
end

Mission05 = createClass(Mission, Mission05)
