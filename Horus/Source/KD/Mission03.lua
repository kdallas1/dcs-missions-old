dofile(baseDir .. "KD/Mission.lua")

---
-- @module KD.Mission03

--- 
-- @type Mission03
-- @extends KD.Mission#Mission

---
-- @field #Mission03
Mission03 = Mission:_New {
  
  --- @field Wrapper.Group#GROUP playerGroup
  playerGroup = nil,
  
  --- @field #list<Wrapper.Unit#UNIT> playerList
  playerList = {},
  
  --- @field Core.Spawn#SPAWN transportSpawn
  transportSpawn = nil,
  
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
  
  --- @field KD.Spawn#Spawn migsSpawn
  migsSpawn = nil
}

---
-- @param #Mission03 self
-- @return #Mission03
function Mission03:New()
  local o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

---
-- @param #Mission03 self
function Mission03:Start()
  self:Trace(1, "Setup begin")
    
  --BASE:TraceOnOff(true)
  BASE:TraceAll(true)
  BASE:TraceLevel(3)
  
  self:SetTraceOn(true)
  self:SetTraceLevel(3)
  self:SetAssert(true)
  
  local nalchikParkZone = ZONE:FindByName("Nalchik Park")
  
  self.transportSpawn = SPAWN:New("Transport")
  
  local playerGroup = GROUP:FindByName(self.playerGroupName)
  self.playerGroup = playerGroup
  self:AddGroup(playerGroup)
  
  self:SetupMenu(self.transportSpawn)
  self:SetupEvents()
  
  SCHEDULER:New(nil,
    function() self:GameLoop(nalchikParkZone, self.transportSpawn, playerGroup) end, 
    {}, 0, self.gameLoopInterval)
  
  self:PlaySound(Sound.MissionLoaded)
  
  MESSAGE:New("Welcome to Mission 3", self.messageTimeShort):ToAll()
  MESSAGE:New("Please read the brief", self.messageTimeShort):ToAll()
  self:Trace(1, "Setup done")
  
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

-- TODO: implement own birth event, pretty sure this is unreliable
---
-- @param #Mission03 self
-- @param Wrapper.Unit#UNIT unit
function Mission03:OnUnitSpawn(unit)

  self:AssertType(unit, UNIT)
  self:Trace(2, "Unit spawned: " .. unit:GetName())
  
  if (string.match(unit:GetName(), "Transport")) then
    self.transportSpawnCount = _inc(self.transportSpawnCount)
    self:Trace(1, "New transport spawned, alive: " .. tostring(self.transportSpawnCount))
    
    MESSAGE:New(
      "Transport #".. tostring(self.transportSpawnCount) .." of " .. 
      tostring(self.transportMaxCount) .. " arrived, inbound to Nalchik", self.messageTimeShort
    ):ToAll()
    
    self:PlaySound(Sound.ReinforcementsHaveArrived, 2)
  end
  
  if (string.match(unit:GetName(), "MiG")) then
    self.migsSpawnDoneCount = _inc(self.migsSpawnDoneCount)
    self:Trace(1, "New enemy spawned, alive: " .. tostring(self.migsSpawnDoneCount))
    MESSAGE:New("Enemy MiG #" .. tostring(self.migsSpawnDoneCount) .. " incoming, inbound to Nalchik", self.messageTimeShort):ToAll()
    self:PlaySound(Sound.EnemyApproching)
  end
  
  if (string.match(unit:GetName(), self.playerPrefix)) then
    self.playerCountMax = _inc(self.playerCountMax)
    self:Trace(1, "New player spawned, alive: " .. tostring(self.playerCountMax))
    
    if not self.transportSpawnStarted then
      self:StartSpawnTransport()
    end
    
    if not self.migsSpawnStarted then    
      self:Assert(not self.migsSpawnStarted, "MiG spawner already started")
      self.migsSpawnStarted = true
      self.migsSpawn = Spawn:New(self, self.migsSpawnerMax, self.GetMaxMigs, self.migsGroupSize, self.migsPrefix)
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
  
  self.migsDestroyed = _inc(self.migsDestroyed)
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
  
  self.playerList = self:FindUnitsByPrefix(self.playerPrefix, self.playerMax)
  self:AddUnitList(self.playerList)
  
  local playersExist = (#self.playerList > 0)
  self:Trace(2, "Players list size: " .. #self.playerList)
  self:Trace(2, "Players exist: " .. (playersExist and "true" or "false")) 
  
  self:GameLoopBase()
  
  if (self.winLoseDone) then
    return
  end

  -- if no players, then say all players are parked (not sure if this makes sense).
  local playersAreParked = ((not playersExist) or self:UnitsAreParked(nalchikParkZone, self.playerList))
  local transportsAreParked = self:SpawnGroupsAreParked(nalchikParkZone, transportSpawn, self.transportMaxCount)
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
  
    if (self:ListHasPlayer(self.playerList) and not self.playerOnline) then
      self:Trace(1, "Player is now online (in player group)")
      self.playerOnline = true
    end
    
    -- keep alive only needed for AI player group (which is useful for testing).
    if (transportsAreParked and (not self.playerOnline)) then
      self:KeepAliveGroupIfParked(nalchikParkZone, playerGroup)
    end
    
  end
  
  self:KeepAliveSpawnGroupsIfParked(nalchikParkZone, transportSpawn, self.transportMaxCount)
  self:SelfDestructDamagedUnits(transportSpawn, self.transportMinLife)
  
end
