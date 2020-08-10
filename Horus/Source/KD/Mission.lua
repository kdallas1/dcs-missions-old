if not skipMoose then
  dofile(baseDir .. "../Moose/Moose.lua")
end

dofile(baseDir .. "KD/Object.lua")
dofile(baseDir .. "KD/Spawn.lua")

---
-- @module KD.Mission

--- 
-- @type Mission
-- @extends KD.Object#Object
Mission = {
  className = "Mission",
  
  ---@field #list<Core.Spawn#SPAWN> spawners
  spawners = nil,
  
  ---@field #list<Wrapper.Group#GROUP> groups
  groups = nil,
  
  ---@field #list<Wrapper.Units#UNIT> players
  players = nil,
  
  --- @field KD.Events#Events events
  events = nil,

  winLoseDone = false,
  messageTimeShort = 20,
  messageTimeLong = 200,
  testPassed = false 
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
-- @param #Mission03 self
function Mission:Mission()
  self.spawners = {}
  self.groups = {}
  self.players = {}
  self.events = Events:New()
end

--- Checks if entire group is parked in a zone.
-- @param #Mission self
-- @param Core.Zone#ZONE zone Parking zone to check.
-- @param Wrapper.Group#GROUP group The group to check.
-- @return true If all units are parked in the zone.
function Mission:GroupIsParked(zone, group)
  
  self:AssertType(zone, ZONE)
  self:AssertType(group, GROUP)
  
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
  
  self:AssertType(zone, ZONE)

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
  
  self:AssertType(zone, ZONE)
  self:AssertType(spawn, SPAWN)
  
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
  
  self:AssertType(zone, ZONE)
  self:AssertType(group, GROUP)
  
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
  
  self:AssertType(zone, ZONE)
  self:AssertType(spawn, SPAWN)
  
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
function Mission:GameLoopBase()
  self:Trace(3, "*** Game loop start ***")
  self.events:UpdateFromGroupList(self.groups)
  self.events:UpdateFromSpawnerList(self.spawners)
  self.events:UpdateFromUnitList(self.players)
  self.events:CheckUnitList()
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
