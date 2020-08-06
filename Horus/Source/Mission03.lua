---
-- @module Mission03

--- @type Mission03
-- @extends Mission#Mission 
Mission03 = {
  
  ---@field #Wrapper.Group#GROUP playerGroup
  playerGroup = nil,
  
  ---@field #list<Wrapper.Unit#UNIT> playerList
  playerList = {},
  
  --- @field Core.Spawn#SPAWN transportSpawn
  transportSpawn = nil,
  
  gameLoopInterval = 1,
  playerOnline = false,
  winLoseDone = false,
  soundCounter = 1,
  playerGroupName = "Dodge",
  playerPrefix = "Dodge",
  playerMax = 4,
  messageTimeShort = 20,
  messageTimeLong = 200,
  playerCountMax = 0,
  
  transportMaxCount = 3, -- easy to run out of fuel with >3
  transportSeparation = 300,
  transportMinLife = 30,
  transportSpawnCount = 0,
  transportSpawnStart = 10,
  transportSpawnStarted = false,
  
  migsSpawnStart = 60,
  migsSpawnSeparation = 300,
  migsSpawnVariation = .5,
  migsSpawnerMax = 3,
  migsPerPlayer = 4,
  migsSpawnInitCount = 0,
  migsSpawnDoneCount = 0,
  migsGroupSize = 2, -- pairs in ME
  migsDestroyed = 0,
  migsNextSpawner = 1,
  migsSpawnStarted = false
}

---
-- @param #Mission03 self
-- @return #Mission03
function Mission03:New()
  local new = Mission:New(self)
  return new
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
function Mission03:PlayEnemyDeadSound(delay)
  if not delay then
    delay = 0
  end
  
  local sounds = {
    Sound.ForKingAndCountry,
    Sound.KissItByeBye,
    Sound.ShakeItBaby
  }
  
  self:PlaySound(Sound.TargetDestoyed, delay)
  self:PlaySound(sounds[self.soundCounter], delay + 2)
  
  self.soundCounter = _inc(self.soundCounter)
  if self.soundCounter > #sounds then
    self.soundCounter = 1
  end
end

---
-- @param #Mission03 self
function Mission03:GetMaxMigs()
  return (self.playerCountMax * self.migsPerPlayer)
end

---
-- @param #Mission03 self
function Mission03:StartSpawnEnemies()
  self:Assert(not self.migsSpawnStarted, "MiG spawner already started")
  self.migsSpawnStarted = true
  
  self:Trace(2, "Setting up MiG spawners")
  
  local spawners = {}
  for i = 1, self.migsSpawnerMax do
    
    local spawn = SPAWN:New("MiG " .. i)
    spawn.id = i
    self:AddSpawner(spawn)
    spawners[#spawners + 1] = spawn
    
  end
  
  self:ShuffleList(spawners)
  
  -- using a manual scheduler because Moose's SpawnScheduled/InitLimit isn't reliable,
  -- as it often spawns 1 less than you ask for.
  SCHEDULER:New(nil, function()
    
    self.migsNextSpawner = _inc(self.migsNextSpawner)
    if (self.migsNextSpawner > #spawners) then
      self.migsNextSpawner = 1
    end 
    
    local spawn = spawners[self.migsNextSpawner]
    local maxMigs = self:GetMaxMigs()
    
    self:Trace(2, "MiG spawn tick, id=" .. spawn.id .. " max=" .. maxMigs .. " count=" .. self.migsSpawnInitCount)
    
    if (self.migsSpawnInitCount < maxMigs) then
      
      -- spawns a pair
      self:Trace(2, "MiG spawn, id=" .. spawn.id)
      spawn:Spawn()
      
      -- increment here instead of OnUnitSpawn to prevent race condition, since
      -- events happen only on game tick
      self.migsSpawnInitCount = self.migsSpawnInitCount + self.migsGroupSize
      
    end
  end, {}, self.migsSpawnStart, self.migsSpawnSeparation, self.migsSpawnVariation)
end

---
-- @param #Mission03 self
function Mission03:StartSpawnTransport()

  self:Assert(not self.migsSpawnStarted, "Transport spawner already started")
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

  self:CheckType(unit, UNIT)
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
      self:StartSpawnEnemies()
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
    function() self:KillTransport(transportSpawn) end)
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
  self:CheckType(unit, UNIT)
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
  self:CheckType(unit, UNIT)
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
  self:CheckType(unit, UNIT)
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
    self:LandTestPlayers(self.playerGroup)
  end
end

---
-- @param #Mission03 self
function Mission03:AnnounceWin(soundDelay)
  self:Assert(not self.winLoseDone, "Win/lose already announced")

  if not soundDelay then
    soundDelay = 0
  end
  
  self:Trace(1, "Mission accomplished")
  MESSAGE:New("Mission accomplished!", self.messageTimeLong):ToAll()
  self:PlaySound(Sound.MissionAccomplished, soundDelay)
  self:PlaySound(Sound.BattleControlTerminated, soundDelay + 2)
  self.winLoseDone = true
end

---
-- @param #Mission03 self
function Mission03:AnnounceLose(soundDelay)
  self:Assert(not self.winLoseDone, "Win/lose already announced")
  
  if not soundDelay then
    soundDelay = 0
  end
  
  self:Trace(1, "Mission failed")
  MESSAGE:New("Mission failed!", self.messageTimeLong):ToAll()
  self:PlaySound(Sound.MissionFailed, soundDelay)
  self:PlaySound(Sound.BattleControlTerminated, soundDelay + 2)
  self.winLoseDone = true
end

---
-- @param #Mission03 self
-- @param Wrapper.Group#GROUP playerGroup
function Mission03:LandTestPlayers(playerGroup)
  self:Trace(1, "Landing test players")
  local airbase = AIRBASE:FindByName(AIRBASE.Caucasus.Nalchik)
  local land = airbase:GetCoordinate():WaypointAirLanding(300, airbase)
  local route = { land }
  playerGroup:Route(route)
end

---
-- @param #Mission03 self
-- @param Core.Spawn#SPAWN transportSpawn
function Mission03:KillTransport(transportSpawn)
  self:Trace(1, "Killing transport")
  local group = transportSpawn:GetGroupFromIndex(1)
  if group then
    unit = group:GetUnit(1)
    unit:Explode(100, 0)
    unit.selfDestructDone = true
  end
end

-- TODO: refactor into global class
--- 
-- @param #Mission03 self
-- @param Core.Spawn#SPAWN transportSpawn
function Mission03:KillDamagedTransports(transportSpawn)
  self:Trace(3, "Checking transport spawn groups for damage")
  for i = 1, self.transportMaxCount do
    local group = transportSpawn:GetGroupFromIndex(i)
    if group then
      self:Trace(3, "Checking group for damage: " .. group:GetName())
      
      local units = group:GetUnits()
      if units then
        for j = 1, #units do
          local unit = group:GetUnit(j)
          local life = unit:GetLife()
          
          self:Trace(3, "Checking unit for damage: " .. unit:GetName() .. ", health " .. tostring(life))
          
          -- only kill the unit if it's alive, otherwise it'll never crash.
          -- explode transports below a certain live level, otherwise
          -- transports can land in a damaged and prevent other transports
          -- from landing (also enemies will often stop attacking damaged units)
          if (unit:IsAlive() and (not unit.selfDestructDone) and (unit:GetLife() < self.transportMinLife)) then
            self:Trace(1, "Auto-kill " .. unit:GetName() .. ", health " .. tostring(life) .. "<" .. self.transportMinLife)
            unit:Explode(100, 1)
            unit.selfDestructDone = true
          end
        end
      end
    end
  end
end

-- TODO: consider merging this with KillDamagedTransports
---
-- @param #Mission03 self
-- @param Core.Spawn#SPAWN transportSpawn
function Mission03:GetAliveTransportCount(transportSpawn)
  self:Trace(3, "Checking spawn groups for alive count")
  
  local count = 0
  for i = 1, self.transportMaxCount do
    local group = transportSpawn:GetGroupFromIndex(i)
    if group then
      self:Trace(3, "Checking group for alive count: " .. group:GetName())
      
      local units = group:GetUnits()
      if units then
        for j = 1, #units do
          local unit = group:GetUnit(j)
          self:Trace(3, "Checking if unit is alive: " .. unit:GetName())
          
          if unit:IsAlive() then
            count = _inc(count)
          end
        end
      end
    end
  end
  return count
end

---
-- @param #Mission03 self
-- @param Core.Zone#ZONE nalchikParkZone
-- @param Core.Spawn#SPAWN transportSpawn
-- @param Wrapper.Group#GROUP playerGroup
function Mission03:GameLoop(nalchikParkZone, transportSpawn, playerGroup)
  self:CheckType(nalchikParkZone, ZONE)
  self:CheckType(transportSpawn, SPAWN)
  
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
  
  self:Trace(2, "Transports alive: " .. self:GetAliveTransportCount(transportSpawn))
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
  self:KillDamagedTransports(transportSpawn)
  
end

local m = Mission03:New()
m:Start()
