---
-- @module Mission

--- @type Mission
Mission = {

  traceOn = false,
  traceLevel = 1,
  assert = false,
  
  ---@field #list<Core.Spawn#SPAWN> spawners
  spawners = {},
  
  ---@field #list<Wrapper.Group#GROUP> groups
  groups = {},
  
  ---@field #list<Wrapper.Unit#UNIT> units
  units = {},
  
  ---@field #list<#function> eventHandlers
  eventHandlers = {},

  winLoseDone = false,
  messageTimeShort = 20,
  messageTimeLong = 200
}

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
-- @type Event
Event = {
  Spawn     = 0,
  Damaged   = 1,
  Dead      = 2,
}

--- Short hand to increment a number (no ++ in Lua)
-- @param #number i Start increment from this number.
-- @return #number Returns i + 1   
function _inc(i)
  return i + 1
end

---
-- @param #Mission self
-- @param child
-- @return #Mission
function Mission:New(child)
  local o = child or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

--- Turn on trace (logging)
-- @param #Mission self
-- @param #boolean traceOn True to enable trace.
function Mission:SetTraceOn(traceOn)
  self.traceOn = traceOn
end

--- Trace level (logging).
-- @param #Mission self
-- @param #number traceLevel 1 = low, 2 = med, 3 = high
function Mission:SetTraceLevel(traceLevel)
  self.traceLevel = traceLevel
end

--- Enable assert (a type of error reporting).
-- @param #Mission self
-- @param #boolean assert True to enable assert. 
function Mission:SetAssert(assert)
  self.assert = assert
end

--- Horus log function. Short hand for: env.info("Horus: " .. line)
-- @param #Mission self
-- @param #number level Level to trace at.
-- @param #string line Log line to output to env.info 
function Mission:Trace(level, line)

  if (self.assert) then
    assert(type(level) == type(0), "level arg must be a number")
    assert(type(line) == type(""), "line arg must be a string")
  end
  
  if (self.traceOn and (level <= self.traceLevel)) then
    local funcName = debug.getinfo(2, "n").name
    local lineNum = debug.getinfo(2, "S").linedefined
    funcName = (funcName and funcName or "?")
    
    env.info("Horus L" .. level .. " " .. funcName .. "@" .. lineNum .. ": " .. line)
  end
end

--- Assert wrapper which can be turned off
-- @param #Mission self
-- @param #boolean case If false, assert fails
-- @param #string message Assert message if fail
function Mission:Assert(case, message)
  if (not self.assert) then
    return
  end
  
  assert(case, message)
end

--- Asserts the correct type (Lua is loosely typed, so this is helpful)
-- @param #Mission self
-- @param Core.Base#BASE object Object to check
-- @param #table _type Either Moose class or type string name to assert
function Mission:CheckType(object, _type)
  if (not self.assert) then
    return
  end
  
  assert(object, "Cannot check type, object is nil")
  assert(_type, "Cannot check type, _type is nil")
  
  if (type(_type) == "string") then
    assert(type(object) == _type,
      "Invalid type, expected '" .. _type .. "' but was '" .. type(object) .. "'")
    return
  end
  
  -- in Lua, classes are tables
  if (type(object) == "table") then
    
    self:Trace(4, "Listing type properties")
    for field, v in pairs(object) do
      self:Trace(4, "Property: " .. field)
    end
  
    -- check for MOOSE class name
    if (object.ClassName or _type.ClassName) then
      assert(object.ClassName, "Missing ClassName property on object")
      assert(_type.ClassName, "Missing ClassName property on _type")
      
      assert(object.ClassName == _type.ClassName, 
        "Invalid type, expected '" .. _type.ClassName .. "' but was '" .. object.ClassName .. "'")
    else
      error("Type check failed, object and _type missing ClassName")
    end
  
  else
    error("Type check failed, invalid args")
  end
end

--- Checks if entire group is parked in a zone.
-- @param #Mission self
-- @param Core.Zone#ZONE zone Parking zone to check.
-- @param Wrapper.Group#GROUP group The group to check.
-- @return true If all units are parked in the zone.
function Mission:GroupIsParked(zone, group)
  
  self:CheckType(zone, ZONE)
  self:CheckType(group, GROUP)
  
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
  
  self:CheckType(zone, ZONE)

  self:Trace(3, "zone: " .. zone:GetName())
  
  local stoppedCount = 0
  for i = 1, #units do
    local unit = units[i]
    self:Trace(3, "unit name: " .. unit:GetName())
    self:Trace(3, "unit velocity: " .. unit:GetVelocityKNOTS())
    
    if (unit:GetVelocityKNOTS() < 1) then
      stoppedCount = _inc(stoppedCount)
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
-- @param #number spawnCount Number of groups in spawner to check.
-- @return true If all units within all groups are parked in the zone. 
function Mission:SpawnGroupsAreParked(zone, spawn, spawnCount)
  
  self:CheckType(zone, ZONE)
  self:CheckType(spawn, SPAWN)
  
  self:Trace(3, "zone: " .. zone:GetName())
  self:Trace(3, "spawnCount: " .. spawnCount)
  
  local parkCount = 0
  for i = 1, spawnCount do
    local group = spawn:GetGroupFromIndex(i)
    if (group and self:GroupIsParked(zone, group)) then
      parkCount = _inc(parkCount)
    end
  end
  
  self:Trace(3, "parkCount: " .. parkCount)
  
  return parkCount == spawnCount
end

--- Keep alive air units when parked (to stop DCS from cleaning them up).
-- @param #Mission self
-- @param Core.Zone#ZONE zone Parking zone to check.
-- @param Wrapper.Group#GROUP group The group to check.
function Mission:KeepAliveGroupIfParked(zone, group)
  
  self:CheckType(zone, ZONE)
  self:CheckType(group, GROUP)
  
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
function Mission:KeepAliveSpawnGroupsIfParked(zone, spawn, spawnCount)
  
  self:CheckType(zone, ZONE)
  self:CheckType(spawn, SPAWN)
  
  for i = 1, spawnCount do
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
    
    if unit:IsPlayer() then
      self:Trace(3, "found player in list")
      return true
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
      local sound = USERSOUND:New(soundName .. ".ogg")
      SCHEDULER:New(nil, function() sound:ToAll() end, {}, delay)
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
-- @param Wrapper.Group#GROUP group
function Mission:CheckGroup(group)

  self:Trace(3, "Checking group: " .. group:GetName())
  
  local units = group:GetUnits()
  if units then
    
    self:Trace(3, "Unit count: " .. #units)
    
    for i = 1, #units do
      
      -- add all units to our own list so we can watch units come and go
      local unit = group:GetUnit(i)
      
      self:Trace(3, "Checking unit: " .. unit:GetName())
      self:AddUnit(unit)
    end
  end
end

---
-- @param #Mission self
-- @param Wrapper.Unit#UNIT unit
function Mission:AddUnit(unit)
  
  local id = unit:GetID()
  if not self.units[id] then
    self.units[id] = unit
    self:Trace(3, "Firing unit spawn event: " .. unit:GetName())
    self:FireEvent(Event.Spawn, unit)
  end
end

---
-- @param #Mission self
-- @param #list<Wrapper.Unit#UNIT> units
function Mission:AddUnitList(units)
  for i = 1, #units do
    self:AddUnit(units[i])
  end
end

---
-- @param #Mission self
-- @param #list<Wrapper.Group#GROUP> groups
function Mission:CheckGroupList(groups)

  self:Trace(3, "Checking group list")
  
  -- check internal groups list by default
  if not groups then
    groups = self.groups
  end
  
  for i = 1, #groups do
    local group = groups[i]
    if group then
      self:CheckGroup(group)
    end
  end
end

---
-- @param #Mission self
function Mission:CheckUnitList()

  self:Trace(3, "Checking unit list")
  
  for id, unit in pairs(self.units) do
    self:CheckUnit(unit)
  end
end

---
-- @param #Mission self
-- @param Wrapper.Unit#UNIT unit
function Mission:CheckUnit(unit)
  
  local life = unit:GetLife()
  local fireDieEvent = false
  self:Trace(3, "Checking unit: " .. unit:GetName() .. ", health " .. tostring(life))
  
  -- we can't use IsAlive here, because the unit may not have spawned yet 
  if (life <= 1) then
    fireDieEvent = true
  end
  
  -- previously using the EVENTS.Crash event, but it was a bit unreliable
  if (fireDieEvent and (not unit.eventDeadFired)) then
    self:Trace(3, "Firing unit dead event: " .. unit:GetName())
    self:FireEvent(Event.Dead, unit)
    unit.eventDeadFired = true
  end
end

---
-- @param #Mission self
function Mission:CheckSpawnerList()

  self:Trace(3, "Checking spawner list")
  
  for i = 1, #self.spawners do
    local spawner = self.spawners[i]
    self:Trace(3, "Checking spawner: " .. tostring(i))
    
    groups = {}
    for i = 1, spawner.SpawnCount do
    
      local group = spawner:GetGroupFromIndex(i)
      if group then
        groups[#groups + 1] = group
      end
    end
    
    self:CheckGroupList(groups)
  end
end


---
-- @param #Mission self
function Mission:GameLoopBase()
  self:Trace(3, "*** Game loop start ***")
  self:CheckSpawnerList()
  self:CheckGroupList()
  self:CheckUnitList()
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
  self.eventHandlers[event] = handler
  self:Trace(3, "Event handler added, total=" .. #self.eventHandlers)
end

---
-- @param #Mission self
-- @param #Event event
function Mission:FireEvent(event, arg)
  local f = self.eventHandlers[event]
  if f then
    f(arg)
  end
end

---
-- @param #Mission self
function Mission:TestEvents()
  local test = "Hello world"
  self:FireEvent(Event.Spawn, test)
  self:FireEvent(Event.Damaged, test)
  self:FireEvent(Event.Dead, test)
end

--- Get a list of all units with a certain prefix.
-- The `GROUP:GetUnits` function seems unreliable for getting all players 
-- in a groupo of multiplayer clients, so let's try finding by a prefix.
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
    
    local unit = UNIT:FindByName(UnitName)
    if unit then
      self:Trace(4, "Found unit in Moose: " .. unit:GetName())
    else
      self:Trace(4, "Did not find unit in Moose: " .. name)
      
      self:Trace(4, "Finding unit in DCS: " .. name)
      local dcsUnit = Unit.getByName(name)
      if dcsUnit then
        self:Trace(4, "Found unit in DCS: " .. name)
        _DATABASE:AddUnit(name)
        unit = UNIT:FindByName(name)
      else
        self:Trace(4, "Did not find unit in DCS: " .. name)
      end
    end
    
    if unit then
      self:Trace(4, "Adding unit to list: " .. unit:GetName())
      list[#list + 1] = unit
      self:Trace(4, "New list size: " .. #list)
    end
  end
  
  return list
  
end

--- 
-- @param #list list
function Mission:ShuffleList(list)
  for i = #list, 2, -1 do
    local j = math.random(i)
    list[i], list[j] = list[j], list[i]
  end
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
  
  self.soundCounter = _inc(self.soundCounter)
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
  MESSAGE:New("Mission accomplished!", self.messageTimeLong):ToAll()
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
  MESSAGE:New("Mission failed!", self.messageTimeLong):ToAll()
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
function Mission:SelfDestructGroupsInSpawn(spawn)
  self:Trace(1, "Self-destructing groups in spawner")
  for i = 1, #spawn.SpawnCount do
    local group = spawn:GetGroupFromIndex(i)
    
    if group then
      local units = group:GetUnits()
      for j = 1, #units do
        local unit = units[j]
        unit:Explode(100, 0)
        unit.selfDestructDone = true
      end
    end
  end
end
