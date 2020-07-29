Global = {}

local _traceOn = false
local _traceLevel = 1
local _assert = false

--- Short hand to increment a number (no ++ in Lua)
-- @param #number i Start increment from this number.
-- @return #number Returns i + 1   
local function _inc(i)
  return i + 1
end

--- Turn on trace (logging)
-- @param #boolean traceOn True to enable trace.
function Global:SetTraceOn(traceOn)
  _traceOn = traceOn
end

--- Trace level (logging).
-- @param #number 1 = low, 2 = med, 3 = high
function Global:SetTraceLevel(traceLevel)
  _traceLevel = traceLevel
end

--- Enable assert (a type of error reporting).
-- @param #boolean True to enable assert. 
function Global:SetAssert(assert)
  _assert = assert
end

--- Horus log function. Short hand for: env.info("Horus: " .. line)
-- @param #number level Level to trace at.
-- @param #string line Log line to output to env.info 
function Global:Trace(level, line)
  if (_traceOn and (level <= _traceLevel)) then
    local funcName = debug.getinfo(2, "n").name
    local lineNum = debug.getinfo(2, "S").linedefined
    funcName = (funcName and funcName or "?")
    
    env.info("Horus L" .. level .. " " .. funcName .. "@" .. lineNum .. ": " .. line)
  end
end

--- Asserts the correct type (Lua is loosely typed)
-- @param Core.Base#BASE object Object to check
-- @param #table t Moose class to assert
function Global:CheckType(object, t)
  if (_assert) then
    assert(object:GetClassName() == t.ClassName, 
      "Invalid type, expected '" .. t.ClassName .. "' but was '" .. object:GetClassName() .. "'")
  end
end

--- Checks if entire group is parked in a zone.
-- @param Core.Zone#ZONE_BASE zone Parking zone to check.
-- @param Wrapper.Group#GROUP group The group to check.
-- @return true If all units are parked in the zone.
function Global:GroupIsParked(zone, group)
  
  Global:CheckType(zone, ZONE)
  Global:CheckType(group, GROUP)

  Global:Trace(3, "zone: " .. zone:GetName())
  Global:Trace(3, "group: " .. group:GetName())
  
  local units = group:GetUnits()
  if (units == nil) then
    Global:Trace(1, "no units in group: " .. group:GetName())
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
-- @param Core.Zone#ZONE_BASE zone Parking zone to check.
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
-- @param Core.Zone#ZONE_BASE zone Parking zone to check.
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
-- @param Core.Zone#ZONE_BASE zone Parking zone to check.
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
-- @param Wrapper.Group#GROUP group The group to check.
-- @return true If player is in the group. 
function Global:GroupHasPlayer(group)
  
  local units = group:GetUnits()
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
