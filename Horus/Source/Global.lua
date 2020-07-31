---
-- @module Global

--- @type Global
Global = {

  ---@field #list<Core.Spawn#SPAWN> m_spawners
  m_spawners = {},
  
  ---@field #list<Wrapper.Group#GROUP> m_groups
  m_groups = {},
  
  ---@field #list<Wrapper.Unit#UNIT> m_units
  m_units = {},
  
  ---@field #list<#function> m_eventHandlers
  m_eventHandlers = {}
}

local _traceOn = false
local _traceLevel = 1
local _assert = false

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

--- Turn on trace (logging)
-- @param #Global self
-- @param #boolean traceOn True to enable trace.
function Global:SetTraceOn(traceOn)
  _traceOn = traceOn
end

--- Trace level (logging).
-- @param #Global self
-- @param #number traceLevel 1 = low, 2 = med, 3 = high
function Global:SetTraceLevel(traceLevel)
  _traceLevel = traceLevel
end

--- Enable assert (a type of error reporting).
-- @param #Global self
-- @param #boolean assert True to enable assert. 
function Global:SetAssert(assert)
  _assert = assert
end

--- Horus log function. Short hand for: env.info("Horus: " .. line)
-- @param #Global self
-- @param #number level Level to trace at.
-- @param #string line Log line to output to env.info 
function Global:Trace(level, line)

  if (_assert) then
    assert(type(level) == type(0), "level arg must be a number")
    assert(type(line) == type(""), "line arg must be a string")
  end
  
  if (_traceOn and (level <= _traceLevel)) then
    local funcName = debug.getinfo(2, "n").name
    local lineNum = debug.getinfo(2, "S").linedefined
    funcName = (funcName and funcName or "?")
    
    env.info("Horus L" .. level .. " " .. funcName .. "@" .. lineNum .. ": " .. line)
  end
end

--- Asserts the correct type (Lua is loosely typed, so this is helpful)
-- @param #Global self
-- @param Core.Base#BASE object Object to check
-- @param #table _type Either Moose class or type string name to assert
function Global:CheckType(object, _type)
  if (not _assert) then
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
    
    Global:Trace(4, "Listing type properties")
    for field, v in pairs(object) do
      Global:Trace(4, "Property: " .. field)
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
-- @param #Global self
-- @param Core.Zone#ZONE zone Parking zone to check.
-- @param Wrapper.Group#GROUP group The group to check.
-- @return true If all units are parked in the zone.
function Global:GroupIsParked(zone, group)
  
  Global:CheckType(zone, ZONE)
  Global:CheckType(group, GROUP)

  Global:Trace(3, "zone: " .. zone:GetName())
  Global:Trace(3, "group: " .. group:GetName())
  
  local units = group:GetUnits()
  if (units == nil) then
    Global:Trace(3, "no units in group: " .. group:GetName())
    return nil
  end
  
  local stoppedCount = 0
  for i = 1, #units do
    unit = group:GetUnit(i)
    Global:Trace(3, "unit name: " .. unit:GetName())
    Global:Trace(3, "unit velocity: " .. unit:GetVelocityKNOTS())
    
    if (unit:GetVelocityKNOTS() < 1) then
      stoppedCount = _inc(stoppedCount)
    end
  end
  
  Global:Trace(3, "#units: " .. #units)
  Global:Trace(3, "stoppedCount: " .. stoppedCount)
  
  local stopped = stoppedCount == #units
  local inParkZone = group:IsCompletelyInZone(zone)
  
  return (inParkZone and stopped)
end

--- Checks if all groups from a spawner are parked in a zone.
-- @param #Global self
-- @param Core.Zone#ZONE zone Parking zone to check.
-- @param Core.Spawn#SPAWN spawn The spawner to check.
-- @param #number spawnCount Number of groups in spawner to check.
-- @return true If all units within all groups are parked in the zone. 
function Global:SpawnGroupsAreParked(zone, spawn, spawnCount)
  
  Global:CheckType(zone, ZONE)
  Global:CheckType(spawn, SPAWN)
  
  Global:Trace(3, "zone: " .. zone:GetName())
  Global:Trace(3, "spawnCount: " .. spawnCount)
  
  local parkCount = 0
  for i = 1, spawnCount do
    local group = spawn:GetGroupFromIndex(i)
    if (group and Global:GroupIsParked(zone, group)) then
      parkCount = _inc(parkCount)
    end
  end
  
  Global:Trace(3, "parkCount: " .. parkCount)
  
  return parkCount == spawnCount
end

--- Keep alive air units when parked (to stop DCS from cleaning them up).
-- @param #Global self
-- @param Core.Zone#ZONE zone Parking zone to check.
-- @param Wrapper.Group#GROUP group The group to check.
function Global:KeepAliveGroupIfParked(zone, group)
  
  Global:CheckType(zone, ZONE)
  Global:CheckType(group, GROUP)
  
  local parked = Global:GroupIsParked(zone, group)
  if (parked and not group.keepAliveDone) then
    
    -- Respawn uncontrolled (3rd arg) seems to stop DCS from cleaning groups up!
    Global:Trace(3, "respawning at airbase: " .. group:GetName())
    group:RespawnAtCurrentAirbase(nil, nil, true)
    group.keepAliveDone = true
    
  end
  
end

--- Keep alive air units when parked (to stop DCS from cleaning them up).
-- @param #Global self
-- @param Core.Zone#ZONE zone Parking zone to check.
-- @param Core.Spawn#SPAWN spawn The spawner to check.
-- @param #number spawnCount Number of groups in spawner to check.
function Global:KeepAliveSpawnGroupsIfParked(zone, spawn, spawnCount)
  
  Global:CheckType(zone, ZONE)
  Global:CheckType(spawn, SPAWN)
  
  for i = 1, spawnCount do
    local group = spawn:GetGroupFromIndex(i)
    if group then
      Global:KeepAliveGroupIfParked(zone, group)
    end
  end
  
end

--- Check if the group has a player.
-- @param #Global self
-- @param Wrapper.Group#GROUP group The group to check.
-- @return true If player is in the group. 
function Global:GroupHasPlayer(group)
  
  local units = group:GetUnits()
  if not units then
    return false
  end
  
  for i = 1, #units do
    local unit = units[i]
    
    if unit:IsPlayer() then
      Global:Trace(3, "found player in group: " .. group:GetName())
      return true
    end 
    
  end
  
  Global:Trace(3, "no players in group: " .. group:GetName())
  return false
end

---
-- @param #Global self
-- @param #Sound soundType
-- @param #number delay (optional)
-- @return #boolean True if sound was found
function Global:PlaySound(soundType, delay)
  if not delay then
    delay = 0
  end
  
  local found = false
  for soundName, v in pairs(Sound) do
    if v == soundType then
      Global:Trace(3, "Schedule sound: " .. soundName .. " (delay: " .. tostring(delay) .. ")")
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
-- @param #Global self
-- @param Wrapper.Group#GROUP group
function Global:CheckGroup(group)

  Global:Trace(3, "Checking group: " .. group:GetName())
  
  local units = group:GetUnits()
  if units then
    for i = 1, #units do
      
      -- add all units to our own list so we can watch units come and go
      local unit = group:GetUnit(i)
      local id = unit:GetID()
      
      if not self.m_units[id] then
        self.m_units[id] = unit
        Global:FireEvent(Event.Spawn, unit)
      end
    end
  end
end

---
-- @param #Global self
-- @param #list<Wrapper.Group#GROUP> groups
function Global:CheckGroupList(groups)

  Global:Trace(3, "Checking group list")
  
  -- check internal groups list by default
  if not groups then
    groups = self.m_groups
  end
  
  for i = 1, #groups do
    local group = groups[i]
    if group then
      Global:CheckGroup(group)
    end
  end
end

---
-- @param #Global self
function Global:CheckUnitList()

  Global:Trace(3, "Checking unit list")
  
  for id, unit in pairs(self.m_units) do
    self:CheckUnit(unit)
  end
end

---
-- @param #Global self
-- @param Wrapper.Unit#UNIT unit
function Global:CheckUnit(unit)
  
  local life = unit:GetLife()
  local fireDieEvent = false
  Global:Trace(3, "Checking unit: " .. unit:GetName() .. ", health " .. tostring(life))
  
  -- we can't use IsAlive here, because the unit may not have spawned yet 
  if (life <= 1) then
    fireDieEvent = true
  end
  
  -- previously using the EVENTS.Crash event, but it was a bit unreliable
  if (fireDieEvent and (not unit.eventDeadFired)) then
    Global:Trace(3, "Firing unit dead event: " .. unit:GetName())
    self:FireEvent(Event.Dead, unit)
    unit.eventDeadFired = true
  end
end

---
-- @param #Global self
function Global:CheckSpawnerList()

  Global:Trace(3, "Checking spawner list")
  
  for i = 1, #self.m_spawners do
    local spawner = self.m_spawners[i]
    Global:Trace(3, "Checking spawner: " .. tostring(i))
    
    groups = {}
    for i = 1, spawner.m_maxGroups do
    
      local group = spawner:GetGroupFromIndex(i)
      if group then
        groups[#groups + 1] = group
      end
    end
    
    Global:CheckGroupList(groups)
  end
end


---
-- @param #Global self
function Global:GameLoop()
  Global:Trace(3, "*** Game loop start ***")
  self:CheckSpawnerList()
  self:CheckGroupList()
  self:CheckUnitList()
end

---
-- @param #Global self
-- @param Core.Spawn#SPAWN spawner
-- @param #number maxGroups
function Global:AddSpawner(spawner, maxGroups)
  spawner.m_maxGroups = maxGroups
  self.m_spawners[#self.m_spawners + 1] = spawner
  Global:Trace(3, "Spawner added, total=" .. #self.m_spawners)
end

---
-- @param #Global self
-- @param Wrapper.Group#GROUP group
function Global:AddGroup(group)
  self.m_groups[#self.m_groups + 1] = group
  Global:Trace(3, "Group added, total=" .. #self.m_groups)
end

---
-- @param #Global self
-- @param #Event event
-- @param #function handler
function Global:HandleEvent(event, handler)
  self.m_eventHandlers[event] = handler
  Global:Trace(3, "Event handler added, total=" .. #self.m_eventHandlers)
end

---
-- @param #Global self
-- @param #Event event
function Global:FireEvent(event, arg)
  local f = self.m_eventHandlers[event]
  if f then
    f(arg)
  end
end

---
-- @param #Global self
function Global:TestEvents()
  local test = "Hello world"
  self:FireEvent(Event.Spawn, test)
  self:FireEvent(Event.Damaged, test)
  self:FireEvent(Event.Dead, test)
end
