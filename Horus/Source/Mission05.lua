dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission05

--- 
-- @type Mission05
-- @extends KD.Mission#Mission
Mission05 = {
  className = "Mission05",

  traceLevel = 2,
  c4MaxCount = 40,
  c4ExplodeDelay = 60,
  c4MaxTime = 40
}

---
-- @type Mission05.State
-- @extends KD.Mission#MissionState
Mission05.State = {
  EnemySamsDestroyed        = State:NextState(),
  FriendlyHelosAdvancing    = State:NextState(),
  FriendlyHelosLanded       = State:NextState(),
  EnemyBaseDestroyed        = State:NextState(),
  EnemyAaaDestroyed         = State:NextState(),
  FriendlyHelosEscaped      = State:NextState(),
}

---
-- @type Mission05.Flags
Mission05.Flags = {
  FriendlyHelosAdvance      = 10,
  FriendlyHelosRTB          = 11,
  TestPlayerRTB             = 12
}

---
-- @param #Mission05 self
function Mission05:Mission05()

  self:LoadPlayer()
  
  self.friendlyHeloGroup = self.moose.group:FindByName("Friendly Helos")
  self.enemySamGroup = self.moose.group:FindByName("Enemy SAMs")
  self.enemyAAAGroup1 = self.moose.group:FindByName("Enemy AAA #001")
  self.enemyAAAGroup2 = self.moose.group:FindByName("Enemy AAA #002")
  self.enemyAAAGroup3 = self.moose.group:FindByName("Enemy AAA #003")
  self.nalchikParkZone = self.moose.zone:New("Nalchik Park")
  self.landingZone = self.moose.zone:New("Landing")
  self.beslanZone = self.moose.zone:New("Beslan")
  
  self:Assert(self.friendlyHeloGroup, "Friendly helo group not found")
  self:Assert(self.enemySamGroup, "Enemy SAM group not found")
  self:Assert(self.enemyAAAGroup1, "Enemy AAA group 1 not found")
  self:Assert(self.enemyAAAGroup2, "Enemy AAA group 2 not found")
  self:Assert(self.enemyAAAGroup3, "Enemy AAA group 3 not found")
  self:Assert(self.nalchikParkZone, "Nalchik park zone not found")
  self:Assert(self.landingZone, "Landing zone not found")
  self:Assert(self.beslanZone, "Beslan zone not found")
  
  self:AddGroup(self.nalchikPark)
  self:AddGroup(self.friendlyHeloGroup)
  self:AddGroup(self.enemySamGroup)
  self:AddGroup(self.enemyAAAGroup1)
  self:AddGroup(self.enemyAAAGroup2)
  self:AddGroup(self.enemyAAAGroup3)
  
  self.state:TriggerOnce(
    Mission05.State.EnemySamsDestroyed,
    function() return (self.enemySamGroup:CountAliveUnits() == 0) end,
    function() self:OnEnemySamsDestroyed() end
  )
  
  self.state:TriggerOnce(
    Mission05.State.FriendlyHelosLanded,
    function() return self:GroupIsParked(self.landingZone, self.friendlyHeloGroup) end,
    function() self:OnFriendlyHelosLanded() end
  )
  
  self.state:ActionOnce(
    Mission05.State.EnemyBaseDestroyed,
    function() self:OnEnemyBaseDestroyed() end
  )

  self.state:TriggerOnceAfter(
    Mission05.State.EnemyAaaDestroyed,
    Mission05.State.EnemyBaseDestroyed,
    function() return self:IsEnemyAaaDestroyed() end,
    function() self:OnEnemyAaaDestroyed() end
  )

  self.state:TriggerOnceAfter(
    Mission05.State.FriendlyHelosEscaped,
    Mission05.State.EnemyAaaDestroyed,
    function() return self.friendlyHeloGroup:IsNotInZone(self.beslanZone) end,
    function() self:OnFriendlyHelosEscaped() end
  )
  
  self.state:TriggerOnceAfter(
    MissionState.MissionAccomplished,
    Mission05.State.FriendlyHelosEscaped,
    function() return self:UnitsAreParked(self.nalchikParkZone, self.players) end,
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
function Mission05:OnGameLoop()
  
  self:SelfDestructDamagedUnitsInList(self.friendlyHeloGroup:GetUnits(), 10)
  self:SelfDestructDamagedUnitsInList(self.enemySamGroup:GetUnits(), 2)
  
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
  self:MessageAll(MessageLength.Short, "Friendly helos advancing Beslan")
  
  self:PlaySound(Sound.FirstObjectiveMet, 3)
  self:SetFlag(Mission05.Flags.FriendlyHelosAdvance, true)
  
end

---
-- @param #Mission05 self
function Mission05:OnFriendlyHelosLanded()
  
  self:MessageAll(MessageLength.Short, "Friendly helos have landed outside Beslan airbase.")
  self:ScheduleExplodeC4(self.c4ExplodeDelay)
  
end

---
-- @param #Mission05 self
function Mission05:OnStart()
  
  self:MessageAll(MessageLength.Long, "Mission 5: Sneak-attack on Beslan")
  self:MessageAll(MessageLength.Long, "Read the mission brief before takeoff")
  
end

---
-- @param #Mission05 self
function Mission05:ScheduleExplodeC4(delay)
  
  self:MessageAll(MessageLength.Short, "[Commandos] Planting C4. Detonating in T-" .. delay .. " seconds.")

  self:Trace(1, "Exploding C4, delay: " .. delay)
  self:PlaySound(Sound.KissItByeBye, delay)

  self.moose.scheduler:New(
    nil, function()
      self:MessageAll(MessageLength.Short, "[Commandos] Light 'er up!") 
    end, {}, delay)

  for i = 1, self.c4MaxCount do
    local name = string.format("C4 #%03d", i)
    local c4 = self.moose.static:FindByName(name)
    if c4 then
      self.moose.scheduler:New(
        nil, function() c4:GetCoordinate():Explosion(100) end, {}, delay + math.random(1, self.c4MaxTime))
    end
  end

  self.moose.scheduler:New(
    nil, function()
      self.state:Change(Mission05.State.EnemyBaseDestroyed)
    end, {}, delay + self.c4MaxTime)
  
end

function Mission05:OnEnemyBaseDestroyed()

  self:MessageAll(MessageLength.Short, "Enemy base destroyed.")
  self:MessageAll(MessageLength.Short, "Enemy AAAs have been deployed, destroy them to ensure our helos can escape.")

  self.enemyAAAGroup1:Activate()
  self.enemyAAAGroup2:Activate()
  self.enemyAAAGroup3:Activate()

end

function Mission05:IsEnemyAaaDestroyed()
  local aaa1 = self.enemyAAAGroup1:CountAliveUnits()
  local aaa2 = self.enemyAAAGroup2:CountAliveUnits()
  local aaa3 = self.enemyAAAGroup3:CountAliveUnits()
  return (aaa1 + aaa2 + aaa3) == 0
end

function Mission05:OnEnemyAaaDestroyed()

  self:MessageAll(MessageLength.Short, "Enemy AAA destroyed.")
  self:MessageAll(MessageLength.Short, "Friendly helos are leaving the extraction zone.")
  self:SetFlag(Mission05.Flags.FriendlyHelosRTB, true)

end

function Mission05:OnFriendlyHelosEscaped()

  self:MessageAll(MessageLength.Short, "Friendly helos have escape and are RTB.")

end

Mission05 = createClass(Mission, Mission05)
