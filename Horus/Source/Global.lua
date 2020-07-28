hTraceOn = false
hTraceLevel = 1
hAssert = false

--- Horus log function. Short hand for: env.info("Horus: " .. line)
-- @param #number level Level to trace at.
-- @param #string line Log line to output to env.info 
function hTrace(level, line)
  if (hTraceOn and (level <= hTraceLevel)) then
    local funcName = debug.getinfo(2, "n").name
    local lineNum = debug.getinfo(2, "S").linedefined
    funcName = (funcName and funcName or "?")
    
    env.info("Horus L" .. level .. " " .. funcName .. "@" .. lineNum .. ": " .. line)
  end
end

--- Asserts the correct type (Lua is loosely typed)
-- @param Core.Base#BASE object Object to check
-- @param #table t Moose class to assert
function hType(object, t)
  if (hassert) then
    assert(object:GetClassName() == t.ClassName, 
      "Invalid type, expected '" .. t.ClassName .. "' but was '" .. object:GetClassName() .. "'")
  end
end

--- Short hand to increment a number (no ++ in Lua)
-- @param #number i Start increment from this number.
-- @return #number Returns i + 1   
function hInc(i)
  return i + 1
end

--- Checks if entire group is parked in a zone.
-- @param Core.Zone#ZONE_BASE zone Parking zone to check.
-- @param Wrapper.Group#GROUP group The group to check.
-- @return true If all units are parked in the zone.
function groupIsParked(zone, group)
  hType(zone, ZONE)
  hType(group, GROUP)

  hTrace(3, "zone: " .. zone:GetName())
  hTrace(3, "group: " .. group:GetName())
  
  units = group:GetUnits()
  if (units == nil) then
    hTrace(1, "no units in group: " .. group:GetName())
    return nil
  end
  
  stoppedCount = 0
  for i = 1, #units do
    unit = group:GetUnit(i)
    hTrace(3, "unit name: " .. unit:GetName())
    hTrace(3, "unit velocity: " .. unit:GetVelocityKNOTS())
    
    if unit:GetVelocityKNOTS() < 1 then
      stoppedCount = hInc(stoppedCount)
    end
  end
  
  hTrace(3, "#units: " .. #units)
  hTrace(3, "stoppedCount: " .. stoppedCount)
  
  stopped = stoppedCount == #units
  inParkZone = group:IsCompletelyInZone(zone)
  
  return inParkZone and stopped
end

--- Checks if all groups from a spawner are parked in a zone.
-- @param Core.Zone#ZONE_BASE zone Parking zone to check.
-- @param Core.Spawn#SPAWN spawn The spawner to check.
-- @param #number spawnCount Number of groups in spawner to check.
-- @return true If all units within all groups are parked in the zone. 
function spawnGroupsAreParked(zone, spawn, spawnCount)
  
  hType(zone, ZONE)
  hType(spawn, SPAWN)
  
  hTrace(3, "zone: " .. zone:GetName())
  hTrace(3, "spawnCount: " .. spawnCount)
  
  parkCount = 0
  for i = 1, spawnCount do
    group = spawn:GetGroupFromIndex(i)
    if ((group ~= nil) and groupIsParked(zone, group)) then
      parkCount = hInc(parkCount)
    end
  end
  
  hTrace(3, "parkCount: " .. parkCount)
  
  return parkCount == spawnCount
end

--- Keep alive air units when parked (to stop DCS from cleaning them up).
-- @param Core.Zone#ZONE_BASE zone Parking zone to check.
-- @param Wrapper.Group#GROUP group The group to check.
function keepAliveGroupIfParked(zone, group)
  
  parked = groupIsParked(zone, group)
  if (parked and not group.keepAliveDone) then
    
    -- Respawn uncontrolled (3rd arg) seems to stop DCS from cleaning groups up!
    hTrace(3, "respawning at airbase: " .. group:GetName())
    group:RespawnAtCurrentAirbase(nil, nil, true)
    group.keepAliveDone = true
    
  end
  
end

--- Keep alive air units when parked (to stop DCS from cleaning them up).
-- @param Core.Zone#ZONE_BASE zone Parking zone to check.
-- @param Core.Spawn#SPAWN spawn The spawner to check.
-- @param #number spawnCount Number of groups in spawner to check.
function keepAliveSpawnGroupsIfParked(zone, spawn, spawnCount)
  
  for i = 1, spawnCount do
    group = spawn:GetGroupFromIndex(i)
    if group then
      keepAliveGroupIfParked(zone, group)
    end
  end
  
end

--- Check if the group has a player.
-- @param Wrapper.Group#GROUP group The group to check.
-- @return true If player is in the group. 
function groupHasPlayer(group)
  
  local units = group:GetUnits()
  for i = 1, #units do
    local unit = units[i]
    
    if unit:IsPlayer() then
      hTrace(3, "found player in group: " .. group:GetName())
      return true
    end 
    
  end
  
  hTrace(3, "no players in group: " .. group:GetName())
  return false
end
