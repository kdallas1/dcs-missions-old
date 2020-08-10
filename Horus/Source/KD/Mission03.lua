dofile(baseDir .. "KD/Mission.lua")

---
-- @module KD.Mission03

--- 
-- @type Mission03
-- @extends KD.Mission#Mission
Mission03 = {
  className = "Mission03",

  traceOn = true,
  traceLevel = 1,
  assert = true,
  mooseTrace = false,
  
  --- @field Wrapper.Group#GROUP playerGroup
  playerGroup = nil,
  
  --- @field Core.Spawn#SPAWN transportSpawn
  transportSpawn = nil,
  
  --- @field KD.Spawn#Spawn migsSpawn
  migsSpawn = nil,
  
  gameLoopInterval = 1,
  playerOnline = false,
  soundCounter = 1,
  playerGroupName = "Dodge",
  playerPrefix = "Dodge",
  playerMax = 4,
  playerCountMax = 0,
  
  transportMaxCount = 3, -- easy to run out of fuel with >3
  transportSeparation = 300,
  transportMinLife = 30,
  transportSpawnCount = 0,
  transportSpawnStart = 10,
  transportSpawnStarted = false,
  
  migsSpawnerMax = 3,
  migsPerPlayer = 4,
  migsSpawnDoneCount = 0,
  migsDestroyed = 0,
  migsSpawnStarted = false,
  migsGroupSize = 2, -- pairs in ME
  migsPrefix = "MiG",
}

Mission03 = createClass(Mission03, Mission)

---
-- @param #Mission03 self
function Mission03:Mission03()
  
  if self.mooseTrace then  
    BASE:TraceOnOff(true)
    BASE:TraceAll(true)
    BASE:TraceLevel(3)
  end
  
  self:SetTraceOn(self.traceOn)
  self:SetTraceLevel(self.traceLevel)
  self:SetAssert(self.assert)
  
  self.nalchikParkZone = ZONE:FindByName("Nalchik Park")
  self.transportSpawn = SPAWN:New("Transport")
  self.playerGroup = GROUP:FindByName(self.playerGroupName)
  
end

---
-- @param #Mission03 self
function Mission03:Start()
  
  self:Trace(1, "Starting mission")
  
  self:AddGroup(self.playerGroup)
  self:SetupMenu(self.transportSpawn)
  self:SetupEvents()
  
  SCHEDULER:New(nil,
    function() self:GameLoop(self.nalchikParkZone, self.transportSpawn, self.playerGroup) end, 
    {}, 0, self.gameLoopInterval)
  
  self:PlaySound(Sound.MissionLoaded)
  
  MESSAGE:New("Welcome to Mission 3", self.messageTimeShort):ToAll()
  MESSAGE:New("Please read the brief", self.messageTimeShort):ToAll()
  
  self:Trace(1, "Mission started")
  
end

---
-- @param #Mission03 self
function Mission03:GetMaxMigs()
  return (self.playerCountMax * self.migsPerPlayer)
end

---
-- @param #Mission03 self
function Mission03:StartSpawnTransport()

  self:Assert(not self.transportSpawnStarted, "Transport spawner already started")
  self.transportSpawnStarted = true
  
  self:Trace(1, "Starting transport spawner")

  self:AddSpawner(self.transportSpawn, self.transportMaxCount)
  
  -- using a manual scheduler because Moose's SpawnScheduled/InitLimit isn't reliable,
  -- as it often spawns 1 less than you ask for. 
  SCHEDULER:New(nil, function()
    if (self.transportSpawnCount < self.transportMaxCount) then
      self.transportSpawn:Spawn()
    end
  end, {}, self.transportSpawnStart, self.transportSeparation)
end

---
-- @param #Mission03 self
function Mission03:SetupEvents()
  self:HandleEvent(Event.Spawn, function(unit) self:OnUnitSpawn(unit) end)
  self:HandleEvent(Event.Damaged, function(unit) self:OnUnitDamaged(unit) end)
  self:HandleEvent(Event.Dead, function(unit) self:OnUnitDead(unit) end)
end

---
-- @param #Mission03 self
-- @param Wrapper.Unit#UNIT unit
function Mission03:OnUnitSpawn(unit)

  self:AssertType(unit, UNIT)
  self:Trace(2, "Unit spawned: " .. unit:GetName())
  
  if (string.match(unit:GetName(), "Transport")) then
    self.transportSpawnCount = self.transportSpawnCount + 1
    self:Trace(1, "New transport spawned, alive: " .. tostring(self.transportSpawnCount))
    
    MESSAGE:New(
      "Transport #".. tostring(self.transportSpawnCount) .." of " .. 
      tostring(self.transportMaxCount) .. " arrived, inbound to Nalchik", self.messageTimeShort
    ):ToAll()
    
    self:PlaySound(Sound.ReinforcementsHaveArrived, 2)
  end
  
  if (string.match(unit:GetName(), "MiG")) then
    self.migsSpawnDoneCount = self.migsSpawnDoneCount + 1
    self:Trace(1, "New enemy spawned, alive: " .. tostring(self.migsSpawnDoneCount))
    MESSAGE:New("Enemy MiG #" .. tostring(self.migsSpawnDoneCount) .. " incoming, inbound to Nalchik", self.messageTimeShort):ToAll()
    self:PlaySound(Sound.EnemyApproching)
  end
  
  if (string.match(unit:GetName(), self.playerPrefix)) then
    self.playerCountMax = self.playerCountMax + 1
    self:Trace(1, "New player spawned, alive: " .. tostring(self.playerCountMax))
    
    if not self.transportSpawnStarted then
      self:StartSpawnTransport()
    end
    
    if not self.migsSpawnStarted then    
      self:Assert(not self.migsSpawnStarted, "MiG spawner already started")
      self.migsSpawnStarted = true
      self.migsSpawn = Spawn:_New(self, self.migsSpawnerMax, self.GetMaxMigs, self.migsGroupSize, self.migsPrefix)
      self.migsSpawn:CopyTrace(self)
      self.migsSpawn:StartSpawnEnemies()
    end
  end
end

---
-- @param #Mission03 self
-- @param Core.Spawn#SPAWN transportSpawn
function Mission03:SetupMenu(transportSpawn)
  local menu = MENU_COALITION:New(coalition.side.BLUE, "Debug")
  MENU_COALITION_COMMAND:New(
    coalition.side.BLUE, "Kill transport", menu,
    function() self:SelfDestructGroupsInSpawn(transportSpawn, 100, 1) end)
end

---
-- @param #Mission03 self
-- @param Wrapper.Unit#UNIT unit
function Mission03:OnUnitDead(unit)
  if (string.match(unit:GetName(), self.playerGroupName)) then
    self:OnPlayerDead(unit)
  end
  if (string.match(unit:GetName(), "Transport")) then
    self:OnTransportDead(unit)
  end
  if (string.match(unit:GetName(), "MiG")) then
    self:OnEnemyDead(unit)
  end
end

---
-- @param #Mission03 self
-- @param Wrapper.Unit#UNIT unit
function Mission03:OnTransportDead(unit)
  self:AssertType(unit, UNIT)
  self:Trace(1, "Transport destroyed: " .. unit:GetName())
  MESSAGE:New("Transport destroyed!", self.messageTimeLong):ToAll()
  self:PlaySound(Sound.UnitLost)
  
  if (not self.winLoseDone) then
    self:AnnounceLose(2)
  end
end

---
-- @param #Mission03 self
-- @param Wrapper.Unit#UNIT unit
function Mission03:OnPlayerDead(unit)
  self:AssertType(unit, UNIT)
  self:Trace(1, "Player is dead: " .. unit:GetName())
  
  MESSAGE:New("Player is dead!", self.messageTimeLong):ToAll()
  self:PlaySound(Sound.UnitLost)
  
  if (not self.winLoseDone) then
    self:AnnounceLose(2)
  end
end

---
-- @param #Mission03 self
-- @param Wrapper.Unit#UNIT unit
function Mission03:OnEnemyDead(unit)
  self:AssertType(unit, UNIT)
  self:Trace(1, "Enemy MiG is dead: " .. unit:GetName())
  
  self:PlayEnemyDeadSound()
  
  self.migsDestroyed = self.migsDestroyed + 1
  local remain = self:GetMaxMigs() - self.migsDestroyed
  
  if (self.winLoseDone) then
    return
  end
  
  if (remain > 0) then
    self:Trace(1, "MiGs remain: " .. remain)
    MESSAGE:New("Enemy MiG is dead! Remaining: " .. remain, self.messageTimeShort):ToAll()
  else
    self:Trace(1, "All MiGs are dead")
    self:PlaySound(Sound.FirstObjectiveMet, 2)
    MESSAGE:New("All enemy MiGs are dead!", self.messageTimeLong):ToAll()
    MESSAGE:New("Land at Nalchik and park for tasty Nal-chicken dinner! On nom nom", self.messageTimeLong):ToAll()    
    self:LandTestPlayers(self.playerGroup, AIRBASE.Caucasus.Nalchik, 300)
  end
end

---
-- @param #Mission03 self
-- @param Core.Zone#ZONE nalchikParkZone
-- @param Core.Spawn#SPAWN transportSpawn
-- @param Wrapper.Group#GROUP playerGroup
function Mission03:GameLoop(nalchikParkZone, transportSpawn, playerGroup)
  self:AssertType(nalchikParkZone, ZONE)
  self:AssertType(transportSpawn, SPAWN)
  
  -- TODO: consider moving to the parent `Mission`
  -- player list can change at any moment on an MP server, and is often 
  -- out of sync with the group. this is used by the events system
  self.players = self:FindUnitsByPrefix(self.playerPrefix, self.playerMax)
  
  local playersExist = (#self.players > 0)
  self:Trace(2, "Player count: " .. #self.players)
  self:Trace(2, "Players exist: " .. (playersExist and "true" or "false")) 
  
  local transportsExist = (self.transportSpawnCount > 0)
  self:Trace(2, "Transport count: " .. self.transportSpawnCount)
  self:Trace(2, "Transports exist: " .. (transportsExist and "true" or "false")) 
  
  self:GameLoopBase()
  
  if (self.winLoseDone) then
    return
  end

  -- if no players, then say all players are parked (not sure if this makes sense).
  local playersAreParked = ((not playersExist) or self:UnitsAreParked(nalchikParkZone, self.players))
  local transportsAreParked = (transportsExist and self:SpawnGroupsAreParked(nalchikParkZone, transportSpawn))
  local everyoneParked = (playersAreParked and transportsAreParked)
  
  self:Trace(2, "Transports alive: " .. self:GetAliveUnitsFromSpawn(transportSpawn))
  self:Trace(2, (playersAreParked and "✔️ Players: All parked" or "❌ Players: Not all parked"), 1)
  self:Trace(2, (transportsAreParked and "✔️ Transports: All parked" or "❌ Transports: Not all parked"), 1)
  self:Trace(2, (everyoneParked and "✔️ Everyone: All parked" or "❌ Everyone: Not all parked"), 1)
  
  if (everyoneParked) then
    self:AnnounceWin()
  end
  
  -- no players can happen when no AI/human players are online yet
  if (playersExist) then
  
    if (self:ListHasPlayer(self.players) and not self.playerOnline) then
      self:Trace(1, "Player is now online (in player group)")
      self.playerOnline = true
    end
    
    -- keep alive only needed for AI player group (which is useful for testing).
    if (transportsAreParked and (not self.playerOnline)) then
      self:KeepAliveGroupIfParked(nalchikParkZone, playerGroup)
    end
    
  end
  
  self:KeepAliveSpawnGroupsIfParked(nalchikParkZone, transportSpawn)
  self:SelfDestructDamagedUnits(transportSpawn, self.transportMinLife)
  
end
