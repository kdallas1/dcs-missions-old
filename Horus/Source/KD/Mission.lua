if not skipMoose then
  dofile(baseDir .. "../Moose/Moose.lua")
end

dofile(baseDir .. "KD/Object.lua")
dofile(baseDir .. "KD/Spawn.lua")
dofile(baseDir .. "KD/Events.lua")

---
-- @module KD.Mission

--- 
-- @type Mission
-- @extends KD.Object#Object
Mission = {
  className = "Mission",

  traceOn = true,
  traceLevel = 1,
  assert = true,
  mooseTrace = false,
  
  ---@field #list<Core.Spawn#SPAWN> spawners
  spawners = nil,
  
  ---@field #list<Wrapper.Group#GROUP> groups
  groups = nil,
  
  ---@field #list<Wrapper.Units#UNIT> players
  players = nil,
  
  --- @field KD.Events#Events events
  events = nil,
  
  playerGroupName = "Dodge Squadron",
  playerPrefix = "Dodge",
  playerCountMax = 0,
  playerMax = 4,
  
  gameLoopInterval = 1,
  winLoseDone = false,
  messageTimeShort = 20,
  messageTimeLong = 200,
  soundCounter = 1,
  
  mooseScheduler = SCHEDULER,
  mooseMessage = MESSAGE,
  mooseDatabase = _DATABASE,
  mooseUserSound = USERSOUND,
  mooseUnit = UNIT,
  mooseZone = ZONE,
  mooseSpawn = SPAWN,
  mooseGroup = GROUP,
  dcsUnit = Unit,
  
  OnStart = function(self) end,
  OnGameLoop = function(self) end,
  OnUnitSpawn = function(self, unit) end,
  OnUnitDamaged = function(self, unit) end,
  OnUnitDead = function(self, unit) end,
  OnPlayerSpawn = function(self, unit) end,
  OnPlayerDead = function(self, unit) end,
}

---
-- @function [parent=#Mission] New
-- @param #Mission self
-- @return #Mission

Mission = createClass(Mission, Object)

---
-- @type Sound
Sound = {
  MissionLoaded                 = 0,
  MissionAccomplished           = 1,
  MissionFailed                 = 2,
  EnemyApproching               = 3,
  TargetDestoyed                = 4,
  KissItByeBye                  = 5,
  ShakeItBaby                   = 6,
  ForKingAndCountry             = 7,
  FirstObjectiveMet             = 8,
  UnitLost                      = 9,
  BattleControlTerminated       = 10,
  ReinforcementsHaveArrived     = 11
}

---
-- @type MessageLength
MessageLength = {
  Short = 0,
  Long  = 1
}

---
-- @param #Mission self
function Mission:Mission()
  
  if self.mooseTrace then  
    BASE:TraceOnOff(true)
    BASE:TraceAll(true)
    BASE:TraceLevel(3)
  end
  
  self:SetTraceOn(self.traceOn)
  self:SetTraceLevel(self.traceLevel)
  self:SetAssert(self.assert)

  self.spawners = {}
  self.groups = {}
  self.players = {}
  self.events = Events:New()
  
  self:HandleEvent(Event.Spawn, function(unit) self:_OnUnitSpawn(unit) end)
  self:HandleEvent(Event.Damaged, function(unit) self:_OnUnitDamaged(unit) end)
  self:HandleEvent(Event.Dead, function(unit) self:_OnUnitDead(unit) end)
  
end

---
-- @param #Mission self
function Mission:Start()
  
  self:Trace(1, "Starting mission")
  self:OnStart()
  self.mooseScheduler:New(nil, function() self:GameLoop() end, {}, 0, self.gameLoopInterval)
  self:PlaySound(Sound.MissionLoaded)
  self:Trace(1, "Mission started")
  
end

---
-- @param #Mission self
-- @param Wrapper.Unit#UNIT unit
function Mission:_OnUnitSpawn(unit)

  self:AssertType(unit, self.mooseUnit)
  self:Trace(2, "Unit spawned: " .. unit:GetName())

  self:OnUnitSpawn(unit)
  
  if (string.match(unit:GetName(), self.playerPrefix)) then
    self:_OnPlayerSpawn(unit)
  end
  
end

---
-- @param #Mission self
-- @param Wrapper.Unit#UNIT unit
function Mission:_OnPlayerSpawn(unit)

  self.playerCountMax = self.playerCountMax + 1
  self:Trace(1, "New player spawned, alive: " .. tostring(self.playerCountMax))
  
  self:OnPlayerSpawn(unit)
  
end

---
-- @param #Mission self
-- @param Wrapper.Unit#UNIT unit
function Mission:_OnUnitDamaged(unit)

  self:AssertType(unit, self.mooseUnit)
  self:Trace(2, "Unit damaged: " .. unit:GetName())

  self:OnUnitDamaged(unit)
  
end

---
-- @param #Mission self
-- @param Wrapper.Unit#UNIT unit
function Mission:_OnUnitDead(unit)

  self:AssertType(unit, self.mooseUnit)
  self:Trace(2, "Unit dead: " .. unit:GetName())
  
  if (string.match(unit:GetName(), self.playerGroupName)) then
    self:_OnPlayerDead(unit)
  end
  
  self:OnUnitDead(unit)
end

---
-- @param #Mission self
-- @param Wrapper.Unit#UNIT unit
function Mission:_OnPlayerDead(unit)

  self:AssertType(unit, self.mooseUnit)
  self:Trace(1, "Player is dead: " .. unit:GetName())
  
  self:MessageAll(MessageLength.Long, "Player is dead!")
  self:PlaySound(Sound.UnitLost)
  
  self:OnPlayerDead(unit)
  
  if (not self.winLoseDone) then
    self:AnnounceLose(2)
  end
  
end

--- Checks if entire group is parked in a zone.
-- @param #Mission self
-- @param Core.Zone#ZONE zone Parking zone to check.
-- @param Wrapper.Group#GROUP group The group to check.
-- @return true If all units are parked in the zone.
function Mission:GroupIsParked(zone, group)
  
  self:AssertType(zone, self.mooseZone)
  self:AssertType(group, self.mooseGroup)
  
  self:Trace(4, "group: " .. group:GetName())
  
  local units = group:GetUnits()
  if not units then
    self:Trace(4, "no units in group: " .. group:GetName())
    return nil
  end
  
  -- don't return function (for better trace info)
  local r = self:UnitsAreParked(zone, units)
  return r
end

--- Checks if all units are in a zone.
-- @param #Mission self
-- @param Core.Zone#ZONE zone Parking zone to check.
-- @param #list<Wrapper.Unit#UNIT> units The list of units to check.
-- @return true If all units are parked in the zone.
function Mission:UnitsAreInZone(zone, units)
  
  for i = 1, #units do
    local unit = units[i]
    self:Trace(4, "Checking if unit in zone: " .. unit:GetName())
    if not zone:IsVec3InZone(unit:GetVec3()) then
      self:Trace(4, "Unit is not in zone: " .. unit:GetName())
      return false
    end
  end
  
  self:Trace(4, "All units are in the zone")
  return true
end

--- Checks if all units are parked in a zone.
-- @param #Mission self
-- @param Core.Zone#ZONE zone Parking zone to check.
-- @param #list<Wrapper.Unit#UNIT> units The list of units to check.
-- @return true If all units are parked in the zone.
function Mission:UnitsAreParked(zone, units)
  
  self:AssertType(zone, self.mooseZone)

  self:Trace(3, "zone: " .. zone:GetName())
  
  local stoppedCount = 0
  for i = 1, #units do
    local unit = units[i]
    self:Trace(3, "unit name: " .. unit:GetName())
    self:Trace(3, "unit velocity: " .. unit:GetVelocityKNOTS())
    
    if (unit:GetVelocityKNOTS() < 1) then
      stoppedCount = stoppedCount + 1
    end
  end
  
  self:Trace(3, "#units: " .. #units)
  self:Trace(3, "stoppedCount: " .. stoppedCount)
  
  local stopped = stoppedCount == #units
  local inParkZone = self:UnitsAreInZone(zone, units)
  
  return (inParkZone and stopped)
end

--- Checks if all groups from a spawner are parked in a zone.
-- @param #Mission self
-- @param Core.Zone#ZONE zone Parking zone to check.
-- @param Core.Spawn#SPAWN spawn The spawner to check.
-- @return true If all units within all groups are parked in the zone. 
function Mission:SpawnGroupsAreParked(zone, spawn)
  
  self:AssertType(zone, self.mooseZone)
  self:AssertType(spawn, self.mooseSpawn)
  
  self:Trace(3, "zone: " .. zone:GetName())
  
  local parkCount = 0
  for i = 1, spawn.SpawnCount do
    local group = spawn:GetGroupFromIndex(i)
    if (group and self:GroupIsParked(zone, group)) then
      parkCount = parkCount + 1
    end
  end
  
  self:Trace(3, "parkCount: " .. parkCount)
  
  return parkCount == spawn.SpawnCount
end

--- Keep alive air units when parked (to stop DCS from cleaning them up).
-- @param #Mission self
-- @param Core.Zone#ZONE zone Parking zone to check.
-- @param Wrapper.Group#GROUP group The group to check.
function Mission:KeepAliveGroupIfParked(zone, group)
  
  self:AssertType(zone, self.mooseZone)
  self:AssertType(group, self.mooseGroup)
  
  local parked = self:GroupIsParked(zone, group)
  if (parked and not group.keepAliveDone) then
    
    -- Respawn uncontrolled (3rd arg) seems to stop DCS from cleaning groups up!
    self:Trace(3, "respawning at airbase: " .. group:GetName())
    group:RespawnAtCurrentAirbase(nil, nil, true)
    group.keepAliveDone = true
    
  end
  
end

--- Keep alive air units when parked (to stop DCS from cleaning them up).
-- @param #Mission self
-- @param Core.Zone#ZONE zone Parking zone to check.
-- @param Core.Spawn#SPAWN spawn The spawner to check.
-- @param #number spawnCount Number of groups in spawner to check.
function Mission:KeepAliveSpawnGroupsIfParked(zone, spawn)
  
  self:AssertType(zone, self.mooseZone)
  self:AssertType(spawn, self.mooseSpawn)
  
  for i = 1, spawn.SpawnCount do
    local group = spawn:GetGroupFromIndex(i)
    if group then
      self:KeepAliveGroupIfParked(zone, group)
    end
  end
  
end

--- Check if the group has a player.
-- @param #Mission self
-- @param Wrapper.Group#GROUP group The group to check.
-- @return true If player is in the group. 
function Mission:GroupHasPlayer(group)

  self:Trace(3, "looking for player in group: " .. group:GetName())
  
  local units = group:GetUnits()
  if not units then
    return false
  end
  
  -- don't return function (for better trace info)
  local r = self:ListHasPlayer(units)
  return r
end

--- Check if a list has a player.
-- @param #Mission self
-- @param #list<Wrapper.Unit#UNIT> units The list to check.
-- @return true If player is in the list.
function Mission:ListHasPlayer(units)

  self:Trace(3, "looking for player in list")
      
  for i = 1, #units do
    local unit = units[i]
    
    if unit:GetGroup() then
      if unit:IsPlayer() then
        self:Trace(3, "found player in list")
        return true
      end 
    else
      self:Trace(3, "can't check if unit is player, no group")
    end
  end
  
  self:Trace(3, "no players in list")
  return false
  
end

---
-- @param #Mission self
-- @param #Sound soundType
-- @param #number delay (optional)
-- @return #boolean True if sound was found
function Mission:PlaySound(soundType, delay)
  if not delay then
    delay = 0
  end
  
  local found = false
  for soundName, v in pairs(Sound) do
    if v == soundType then
      self:Trace(3, "Schedule sound: " .. soundName .. " (delay: " .. tostring(delay) .. ")")
      local sound = self.mooseUserSound:New(soundName .. ".ogg")
      self.mooseScheduler:New(nil, function() sound:ToAll() end, {}, delay)
      found = true
    end
  end
  
  if not found then
    error("Sound not found by type: " .. tostring(soundType))
  end
  
  return found
end

---
-- @param #Mission self
function Mission:GameLoop()

  self:Trace(3, "*** Game loop start ***")
  
  -- player list can change at any moment on an MP server, and is often 
  -- out of sync with the group. this is used by the events system
  self.players = self:FindUnitsByPrefix(self.playerPrefix, self.playerMax)
  
  self.events:UpdateFromGroupList(self.groups)
  self.events:UpdateFromSpawnerList(self.spawners)
  self.events:UpdateFromUnitList(self.players)
  self.events:CheckUnitList()
  
  self:OnGameLoop()
  
  self:Trace(3, "*** Game loop end ***")
end

---
-- @param #Mission self
-- @param Core.Spawn#SPAWN spawner
function Mission:AddSpawner(spawner)
  self.spawners[#self.spawners + 1] = spawner
  self:Trace(3, "Spawner added, total=" .. #self.spawners)
end

---
-- @param #Mission self
-- @param Wrapper.Group#GROUP group
function Mission:AddGroup(group)
  self.groups[#self.groups + 1] = group
  self:Trace(3, "Group added, total=" .. #self.groups)
end

---
-- @param #Mission self
-- @param #Event event
-- @param #function handler
function Mission:HandleEvent(event, handler)
  self.events:HandleEvent(event, handler)
end

---
-- @param #Mission self
-- @param #Event event
function Mission:FireEvent(event, arg)
  self.events:FireEvent(event, arg)
end

---
-- @param #list unitList
function Mission:UpdateUnitList(unitList)
  self.events:UpdateUnitList(unitList)
end

--- Get a list of all units with a certain prefix.
-- The `GROUP:GetUnits` function seems unreliable for getting all players 
-- in a group of multiplayer clients, so let's try finding by a prefix.
-- Note: The units must use #00n
-- @param #Mission self
-- @param #string prefix
-- @param #number max
-- @return #list<Wrapper.Unit#UNIT>
function Mission:FindUnitsByPrefix(prefix, max)
  
  local list = {}
  for i = 1, max do
    local name = prefix .. string.format(" #%03d", i)
    self:Trace(4, "Finding unit in Moose: " .. name)
    
    local unit = self.mooseUnit:FindByName(name)
    if unit then
      self:Trace(4, "Found unit in Moose: " .. unit:GetName())
    else
      self:Trace(4, "Did not find unit in Moose: " .. name)
      
      self:Trace(4, "Finding unit in DCS: " .. name)
      local dcsUnit = self.dcsUnit.getByName(name)
      if dcsUnit then
        self:Trace(4, "Found unit in DCS, adding to Moose database: " .. name)
        self.mooseDatabase:AddUnit(name)
        unit = self.mooseUnit:FindByName(name)
      else
        self:Trace(4, "Did not find unit in DCS: " .. name)
      end
    end
    
    if unit then
      list[#list + 1] = unit
      self:Trace(4, "Total units found: " .. #list)
    end
  end
  
  return list
  
end

---
-- @param #Mission self
function Mission:PlayEnemyDeadSound(delay)
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
  
  self.soundCounter = self.soundCounter + 1
  if self.soundCounter > #sounds then
    self.soundCounter = 1
  end
end

---
-- @param #Mission self
function Mission:AnnounceWin(soundDelay)
  self:Assert(not self.winLoseDone, "Win/lose already announced")

  if not soundDelay then
    soundDelay = 0
  end
  
  self:Trace(1, "Mission accomplished")
  self:MessageAll(MessageLength.Long, "Mission accomplished!")
  self:PlaySound(Sound.MissionAccomplished, soundDelay)
  self:PlaySound(Sound.BattleControlTerminated, soundDelay + 2)
  self.winLoseDone = true
end

---
-- @param #Mission self
function Mission:AnnounceLose(soundDelay)
  self:Assert(not self.winLoseDone, "Win/lose already announced")
  
  if not soundDelay then
    soundDelay = 0
  end
  
  self:Trace(1, "Mission failed")
  self:MessageAll(MessageLength.Long, "Mission failed!")
  self:PlaySound(Sound.MissionFailed, soundDelay)
  self:PlaySound(Sound.BattleControlTerminated, soundDelay + 2)
  self.winLoseDone = true
end

---
-- @param #Mission self
-- @param Wrapper.Group#GROUP playerGroup
-- @param Wrapper.Airbase#AIRBASE airbase
-- @param #number speed
function Mission:LandTestPlayers(playerGroup, airbase, speed)
  self:Trace(1, "Landing test players")
  local airbase = AIRBASE:FindByName(airbase)
  local land = airbase:GetCoordinate():WaypointAirLanding(speed, airbase)
  local route = { land }
  playerGroup:Route(route)
end

---
-- @param #Mission self
-- @param Core.Spawn#SPAWN spawn
function Mission:SelfDestructGroupsInSpawn(spawn, power, delay)
  self:Trace(1, "Self-destructing groups in spawner")
  
  if not power then
    power = 100
  end
  
  if not delay then
    delay = 0
  end

  for i = 1, spawn.SpawnCount do
    local group = spawn:GetGroupFromIndex(i)
    
    if group then
      local units = group:GetUnits()
      for j = 1, #units do
        local unit = units[j]
        unit:Explode(power, delay)
        unit.selfDestructDone = true
      end
    end
  end
end

---
-- @param #Mission self
-- @param Core.Spawn#SPAWN spawn
function Mission:GetAliveUnitsFromSpawn(spawn)
  self:Trace(3, "Checking spawn groups for alive count")
  
  local count = 0
  for i = 1, spawn.SpawnCount do
    local group = spawn:GetGroupFromIndex(i)
    if group then
      self:Trace(3, "Checking group for alive count: " .. group:GetName())
      
      local units = group:GetUnits()
      if units then
        for j = 1, #units do
          local unit = units[j]
          self:Trace(3, "Checking if unit is alive: " .. unit:GetName())
          
          if unit:IsAlive() then
            count = count + 1
          end
        end
      end
    end
  end
  return count
end

--- 
-- @param #Mission self
-- @param Core.Spawn#SPAWN spawn
-- @param #number minLife
function Mission:SelfDestructDamagedUnits(spawn, minLife)
  self:Trace(3, "Checking spawn groups for damage, count=" .. spawn.SpawnCount)
  for i = 1, spawn.SpawnCount do
    local group = spawn:GetGroupFromIndex(i)
    if group then
      self:Trace(3, "Checking group for damage: " .. group:GetName())
      
      local units = group:GetUnits()
      if units then
        for j = 1, #units do
          local unit = units[j]
          local life = unit:GetLife()
          
          self:Trace(3, "Checking unit for damage: " .. unit:GetName() .. ", health " .. tostring(life))
          
          -- only kill the unit if it's alive, otherwise it'll never crash.
          -- explode units below a certain live level, otherwise
          -- units can land in a damaged and prevent other transports
          -- from landing (also enemies will often stop attacking damaged units)
          if (unit:IsAlive() and (not unit.selfDestructDone) and (unit:GetLife() < minLife)) then
            self:Trace(1, "Auto-kill " .. unit:GetName() .. ", health " .. tostring(life) .. "<" .. minLife)
            unit:Explode(100, 1)
            unit.selfDestructDone = true
          end
        end
      end
    end
  end
end

---
-- @param #Mission self
-- @param #MessageLength length
-- @param #string message
function Mission:MessageAll(length, message)
  self:Trace(2, "Message: " .. message)
  
  local duration = nil
  if length == MessageLength.Short then
    duration = self.messageTimeShort
  elseif length == MessageLength.Long then
    duration = self.messageTimeLong
  end
  
  self:Assert(duration, "Unknown message length")
  self.mooseMessage:New(message, duration):ToAll()
end
