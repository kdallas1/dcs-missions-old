dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission04

--- 
-- @type Mission04
-- @extends KD.Mission#Mission
Mission04 = {
  className = "Mission04",
}

---
-- @type Mission04.State
-- @extends KD.Mission#MissionState
Mission04.State = {
  HeloRendezvousDone        = State:NextState(),
  FriendlyHelosLanded       = State:NextState(),
  EnemyHelosActivated       = State:NextState(),
  ExtractionComplete        = State:NextState()
}

---
-- @type Mission04.Flags
Mission04.Flags = {
  FriendlyHelosAdvance      = 10,
  TestPlayerRTB             = 11
}

---
-- @param #Mission04 self
function Mission04:Mission04()

  --self:SetTraceLevel(3)
  --self.playerTestOn = false

  self.state:AddStates(Mission04.State)
  self.state:CopyTrace(self)

  self.friendlyHeloGroup = self.moose.group:FindByName("Friendly Helos")
  self.enemyHeloGroup = self.moose.group:FindByName("Enemy Helos")
  self.enemyGroundGroup = self.moose.group:FindByName("Enemy Ground")
  self.extractionLandZone = self.moose.zone:New("Extraction Land")
  self.extractionZone = self.moose.zone:New("Extraction")
  self.rendezvousZone = self.moose.zone:New("Rendezvous")
  self.nalchikPark = self.moose.zone:New("Nalchik Park")
  
  self:Assert(self.friendlyHeloGroup, "Friendly helo group not found")
  self:Assert(self.enemyHeloGroup, "Enemy helo group not found")
  self:Assert(self.enemyGroundGroup, "Enemy ground group not found")
  self:Assert(self.extractionLandZone, "Extraction land zone not found")
  self:Assert(self.extractionZone, "Extraction zone not found")
  self:Assert(self.rendezvousZone, "Rendezvous zone not found")
  self:Assert(self.nalchikPark, "Nalchik park zone not found")
  
  self:AddGroup(self.friendlyHeloGroup)
  self:AddGroup(self.enemyHeloGroup)
  self:AddGroup(self.enemyGroundGroup)
  
  -- TODO: test how reliable `playerGroup:IsAnyInZone` is on MP server
  self.state:TriggerOnce(
    Mission04.State.HeloRendezvousDone,
    function() return self.playerGroup:IsAnyInZone(self.rendezvousZone) end,
    function() self:OnHeloRendezvousDone() end
  )
  
  self.state:TriggerOnce(
    Mission04.State.EnemyHelosActivated,
    function() return self.friendlyHeloGroup:IsCompletelyInZone(self.extractionZone) end,
    function() self:OnEnemyHelosActivated() end
  )
  
  self.state:TriggerOnce(
    Mission04.State.FriendlyHelosLanded,
    function() return self:GroupIsParked(self.extractionLandZone, self.friendlyHeloGroup) end,
    function() self:OnFriendlyHelosLanded() end
  )
  
  self.state:TriggerOnceAfter(
    Mission04.State.ExtractionComplete,
    Mission04.State.FriendlyHelosLanded,
    function() return self.friendlyHeloGroup:IsNotInZone(self.extractionZone) end,
    function() self:OnExtractionComplete() end
  )
  
  self.state:TriggerOnceAfter(
    MissionState.MissionAccomplished,
    Mission04.State.ExtractionComplete,
    function() return self:UnitsAreParked(self.nalchikPark, self.players) end,
    function() self:AnnounceWin(2) end
  )
  
  self:SetupMenu()
  
end

---
-- @param #Mission04 self
function Mission04:SetupMenu()

  local menu = self.moose.menu.coalition:New(self.dcs.coalition.side.BLUE, "Debug")
  
  self.moose.menu.coalitionCommand:New(
    self.dcs.coalition.side.BLUE, "Kill players", menu,
    function() self:SelfDestructGroup(self.playerGroup, 100, 1, 1) end)
    
  self.moose.menu.coalitionCommand:New(
    self.dcs.coalition.side.BLUE, "Kill friendly helos", menu,
    function() self:SelfDestructGroup(self.friendlyHeloGroup, 100, 1, 1) end)
    
  self.moose.menu.coalitionCommand:New(
    self.dcs.coalition.side.BLUE, "Kill enemy helos", menu,
    function() self:SelfDestructGroup(self.enemyHeloGroup, 100, 1, 1) end)
    
  self.moose.menu.coalitionCommand:New(
    self.dcs.coalition.side.BLUE, "Kill enemy ground", menu,
    function() self:SelfDestructGroup(self.enemyGroundGroup, 100, 1, 1) end)
    
end
---
-- @param #Mission04 self
function Mission04:OnStart()
  
  self.friendlyHeloGroup:Activate(0)
  
  self:MessageAll(MessageLength.Long, "Mission 4: Assist rescue of downed recon pilots")
  self:MessageAll(MessageLength.Long, "Read the mission brief before takeoff")
  
end

---
-- @param #Mission04 self
function Mission04:OnGameLoop()
  
  self:SelfDestructDamagedUnitsInList(self.friendlyHeloGroup:GetUnits(), 10)
  
end

--- 
-- @param #Mission04 self
function Mission04:OnHeloRendezvousDone()
  
  self:PlaySound(Sound.ForKingAndCountry)
  self:MessageAll(MessageLength.Short, "Rendezvous complete, helos proceeding to extraction")
  
  -- ME waypoint stop condition
  self:SetFlag(Mission04.Flags.FriendlyHelosAdvance, true)
  
end

---
-- @param #Mission04 self
-- @param Wrapper.Unit#UNIT unit
function Mission04:OnUnitDead(unit)

  self:Trace(1, "Unit dead: " .. unit:GetName())
    
  if (string.match(unit:GetName(), "Friendly Helo")) then
    
    self:Trace(1, "Friendly helo destroyed: " .. unit:GetName())
    self:MessageAll(MessageLength.Long, "Friendly helo destroyed!")
    self:PlaySound(Sound.UnitLost)
    self.state:Change(MissionState.MissionFailed)
    
  end
  
  if (string.match(unit:GetName(), "Enemy Helo")) then
    
    self:Trace(1, "Enemy helo destroyed: " .. unit:GetName())
    self:MessageAll(MessageLength.Short, "Enemy helo destroyed!")
    self:PlayEnemyDeadSound()
    
  end
  
  if (string.match(unit:GetName(), "Enemy Ground")) then
    
    self:Trace(1, "Enemy ground unit destroyed: " .. unit:GetName())
    self:MessageAll(MessageLength.Short, "Enemy ground unit destroyed!")
    self:PlayEnemyDeadSound()
    
  end
  
end

---
-- @param #Mission04 self
function Mission04:OnEnemyHelosActivated()

  self:PlaySound(Sound.EnemyApproching, 0)
  
  self.enemyHeloGroup:Activate(0)
  self:MessageAll(MessageLength.Short, "Enemy attack helos inbound from Beslan to Fahrn (WP2), ETA 2 minutes")
  self:Trace(1, "Enemy helos activated")
  
  -- TODO: maybe move ground units to another trigger
  self.enemyGroundGroup:Activate(0)
  self.enemyGroundGroup:SmokeRed()
  self:MessageAll(MessageLength.Short, "Enemy light ground units heading through Fahrn (WP2), ETA 5 minutes")
  self:Trace(1, "Enemy ground activated")
  
end

---
-- @param #Mission04 self
function Mission04:OnFriendlyHelosLanded()

  self.friendlyHeloGroup:SmokeWhite()
  self:MessageAll(MessageLength.Short, "Friendly helos landed Fahrn (WP2), extraction T-1 minute")
  self:Trace(1, "Friendly helos landed")
  
end

---
-- @param #Mission04 self
function Mission04:OnExtractionComplete()

  self:PlaySound(Sound.FirstObjectiveMet)
  self:MessageAll(MessageLength.Short, "Extraction complete, RTB to Nalchik")
  self:Trace(1, "Friendly helos out of extraction zone")
  self:LandTestPlayers(self.playerGroup, self.moose.airbase.Caucasus.Nalchik, 400)
  
end

Mission04 = createClass(Mission, Mission04)
