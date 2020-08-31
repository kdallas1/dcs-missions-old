dofile(baseDir .. "KD/KDObject.lua")
dofile(baseDir .. "KD/Spawn.lua")
dofile(baseDir .. "KD/MissionEvents.lua")
dofile(baseDir .. "KD/Moose.lua")
dofile(baseDir .. "KD/DCS.lua")

---
-- @module KD.Mission

--- 
-- @type Mission
-- @extends KD.KDObject#KDObject
Mission = {
  className = "Mission",

  traceOn = true,
  traceLevel = 1,
  assert = true,
  mooseTrace = false,
  
  _playerGroupName = "Dodge Squadron",
  _playerPrefix = "Dodge",
  
  playerGroupName = nil,
  playerPrefix = nil,
  playerCountMax = 0,
  playerMax = 4,
  playerTestOn = true,
  
  gameLoopInterval = 1,
  messageTimeVeryShort = 5,
  messageTimeShort = 20,
  messageTimeLong = 200,
  soundCounter = 1,
  
  --- @field [parent=#Mission] KD.Moose#Moose moose
  moose = nil,
  
  --- @field [parent=#Mission] KD.DCS#DCS dcs
  dcs = nil,
  
  --- @field [parent=#Mission] #list<Wrapper.Unit#UNIT> groups
  groups = nil,
  
  --- @field [parent=#Mission] KD.MissionEvents#MissionEvents
  events = nil,
}

---
-- @function [parent=#Mission] New
-- @param #Mission self
-- @return #Mission

local nextSoundId_ = 1
local function nextSoundId()
  local r = nextSoundId_
  nextSoundId_ = nextSoundId_ + 1
  return r
end

---
-- @type Sound
Sound = {
  MissionLoaded                 = nextSoundId(),
  MissionAccomplished           = nextSoundId(),
  MissionFailed                 = nextSoundId(),
  EnemyApproching               = nextSoundId(),
  TargetDestoyed                = nextSoundId(),
  KissItByeBye                  = nextSoundId(),
  ShakeItBaby                   = nextSoundId(),
  ForKingAndCountry             = nextSoundId(),
  ObjectiveMet                  = nextSoundId(),
  FirstObjectiveMet             = nextSoundId(),
  SecondObjectiveMet            = nextSoundId(),
  ThirdObjectiveMet             = nextSoundId(),
  UnitLost                      = nextSoundId(),
  BattleControlTerminated       = nextSoundId(),
  ReinforcementsHaveArrived     = nextSoundId(),
  StructureDestoyed             = nextSoundId(),
  AlliedForcesHaveFallen        = nextSoundId(),
  SelectTarget                  = nextSoundId(),
  CommandCentreUnderAttack      = nextSoundId(),
  OurBaseIsUnderAttack          = nextSoundId(),
  MissionTimerInitialised       = nextSoundId()  
}

---
-- @type MessageLength
MessageLength = {
  VeryShort     = 0,
  Short         = 1,
  Long          = 2,
}

---
-- @type MissionState
-- @extends KD.State#State
MissionState = {
  MissionLoading            = State:NextState(),
  MissionStarted            = State:NextState(),
  MissionAccomplished       = State:NextState(),
  MissionFailed             = State:NextState()
}

---
-- @param #Mission self
function Mission:Mission(args)
  
  if args.moose then
    self.moose = args.moose
  else
    self.moose = Moose:New()
  end
  
  if args.dcs then
    self.dcs = args.dcs
  else
    self.dcs = DCS:New()
  end

  if self.mooseTrace then  
    BASE:TraceOnOff(true)
    BASE:TraceAll(true)
    BASE:TraceLevel(3)
  end
  
  if not args.trace then
    self:SetTraceOn(self.traceOn)
    self:SetTraceLevel(self.traceLevel)
    self:SetAssert(self.assert)
  end

  self.spawners = {}
  self.groups = {}
  self.units = {}
  self.players = {}
  
  self.state = StateMachine:New()
  self.state.current = MissionState.MissionLoading
  self.state:AddStates(MissionState)
  
  self.events = MissionEvents:New()
  self.events:CopyTrace(self)
  
  self:HandleEvent(MissionEvent.Spawn, function(unit) self:_OnUnitSpawn(unit) end)
  self:HandleEvent(MissionEvent.Damaged, function(unit) self:_OnUnitDamaged(unit) end)
  self:HandleEvent(MissionEvent.Dead, function(unit) self:_OnUnitDead(unit) end)
  
  self.state:ActionOnce(
    MissionState.MissionAccomplished,
    function() self:AnnounceWin(2) end
  )
  
  self.state:ActionOnce(
    MissionState.MissionFailed,
    function() self:AnnounceLose(2) end
  )
  
  self.state:SetFinal(MissionState.MissionAccomplished)
  self.state:SetFinal(MissionState.MissionFailed)
  
end

---
-- @param #Mission self
function Mission:Start()
  
  self:Trace(1, "Starting mission, " .. _VERSION)

  self:LoadPlayers()
  
  if self.OnStart then
    self:OnStart()
  end
  
  self.moose.scheduler:New(nil, function() self:GameLoop() end, {}, 0, self.gameLoopInterval)
  self:PlaySound(Sound.MissionLoaded)
  self.state.current = MissionState.MissionStarted
  self:Trace(1, "Mission started")
  
end

---
-- @param #Mission self
function Mission:GameLoop()

  self:Trace(3, "*** Game loop start ***")
  
  self:UpdatePlayers()
  
  self.events:UpdateFromGroupList(self.groups)
  self.events:UpdateFromSpawnerList(self.spawners)
  self.events:UpdateFromUnitList(self.units)
  self.events:UpdateFromUnitList(self.players)
  self.events:CheckUnitList()
  
  self.state:CheckTriggers()
  
  if self.OnGameLoop then
    self:OnGameLoop()
  end
  
  self:Trace(3, "*** Game loop end ***")
end

---
-- @param #Mission self
-- @param Wrapper.Unit#UNIT unit
function Mission:_OnUnitSpawn(unit)

  self:AssertType(unit, self.moose.unit)
  self:Trace(2, "Unit spawned: " .. unit:GetName())

  if self.OnUnitSpawn then
    self:OnUnitSpawn(unit)
  end
  
  if (self.playerPrefix and string.match(unit:GetName(), self.playerPrefix)) then
    self:_OnPlayerSpawn(unit)
  end
  
end

---
-- @param #Mission self
-- @param Wrapper.Unit#UNIT unit
function Mission:_OnPlayerSpawn(unit)

  self.playerCountMax = self.playerCountMax + 1
  self:Trace(1, "New player spawned, alive: " .. tostring(self.playerCountMax))
  
  if self.OnPlayerSpawn then
    self:OnPlayerSpawn(unit)
  end
  
end

---
-- @param #Mission self
-- @param Wrapper.Unit#UNIT unit
function Mission:_OnUnitDamaged(unit)

  self:AssertType(unit, self.moose.unit)
  self:Trace(2, "Unit damaged: " .. unit:GetName())

  if self.OnUnitDamaged then
    self:OnUnitDamaged(unit)
  end
end

---
-- @param #Mission self
-- @param Wrapper.Unit#UNIT unit
function Mission:_OnUnitDead(unit)

  self:AssertType(unit, self.moose.unit)
  self:Trace(2, "Unit dead: " .. unit:GetName())
  
  if (self.playerPrefix and string.match(unit:GetName(), self.playerPrefix)) then
    self:_OnPlayerDead(unit)
  end
  
  if self.OnUnitDead then
    self:OnUnitDead(unit)
  end
end

---
-- @param #Mission self
-- @param Wrapper.Unit#UNIT unit
function Mission:_OnPlayerDead(unit)

  local name = unit:GetPlayerName() or unit:GetName()

  self:AssertType(unit, self.moose.unit)
  self:Trace(1, "Player is dead: " .. name)
  
  self:MessageAll(MessageLength.Long, name .. " died!")
  self:PlaySound(Sound.UnitLost)
  
  if self.OnPlayerDead then
    self:OnPlayerDead(unit)
  end
  
  self.state:Change(MissionState.MissionFailed)
  
end

--- Checks if entire group is parked in a zone.
-- @param #Mission self
-- @param Core.Zone#ZONE zone Parking zone to check.
-- @param Wrapper.Group#GROUP group The group to check.
-- @return true If all units are parked in the zone.
function Mission:GroupIsParked(zone, group)
  
  self:AssertType(zone, self.moose.zone)
  self:AssertType(group, self.moose.group)
  
  self:Trace(4, "Checking if group parked: " .. group:GetName())
  
  -- Note: Moose randomly returns either nil or 0 from GROUP:GetUnits()
  local units = group:GetUnits()
  if not units then
    self:Trace(4, "No units in group: " .. group:GetName())
    return false
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
  
  self:AssertType(zone, self.moose.zone)
  
  if #units == 0 then
    return false
  end

  self:Trace(3, "Checking if units parked in zone: " .. zone:GetName())
  
  local stoppedCount = 0
  for i = 1, #units do
    local unit = units[i]
    self:Trace(3, "Checking unit name: " .. unit:GetName())
    self:Trace(3, "Checking unit velocity: " .. unit:GetVelocityKNOTS())
    
    if (unit:GetVelocityKNOTS() < 1) then
      stoppedCount = stoppedCount + 1
    end
  end
  
  self:Trace(3, "Unit count: " .. #units)
  self:Trace(3, "Stop count: " .. stoppedCount)
  
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
  
  self:AssertType(zone, self.moose.zone)
  self:AssertType(spawn, self.moose.spawn)
  
  self:Trace(3, "Checking spawn groups in zone: " .. zone:GetName())
  
  local parkCount = 0
  for i = 1, spawn.SpawnCount do
    local group = spawn:GetGroupFromIndex(i)
    if (group and self:GroupIsParked(zone, group)) then
      parkCount = parkCount + 1
    end
  end
  
  self:Trace(3, "Parked count: " .. parkCount)
  
  return parkCount == spawn.SpawnCount
end

--- Keep alive air units when parked (to stop DCS from cleaning them up).
-- @param #Mission self
-- @param Core.Zone#ZONE zone Parking zone to check.
-- @param Wrapper.Group#GROUP group The group to check.
function Mission:KeepAliveGroupIfParked(zone, group)
  
  self:AssertType(zone, self.moose.zone)
  self:AssertType(group, self.moose.group)
  
  local parked = self:GroupIsParked(zone, group)
  if (parked and not group.keepAliveDone) then
    
    -- Respawn uncontrolled (3rd arg) seems to stop DCS from cleaning groups up!
    self:Trace(3, "Respawning at airbase: " .. group:GetName())
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
  
  self:AssertType(zone, self.moose.zone)
  self:AssertType(spawn, self.moose.spawn)
  
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

  self:Trace(3, "Looking for player in group: " .. group:GetName())
  
  -- Note: Moose randomly returns either nil or 0 from GROUP:GetUnits()
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

  self:Trace(3, "Looking for player in list")
      
  for i = 1, #units do
    local unit = units[i]
    
    if unit:GetGroup() then
      if unit:IsPlayer() then
        self:Trace(3, "Found player in list")
        return true
      end 
    else
      self:Trace(3, "Can't check if unit is player, no group")
    end
  end
  
  self:Trace(3, "No players in list")
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
      local sound = self.moose.userSound:New(soundName .. ".ogg")
      if sound then
        self.moose.scheduler:New(nil, function() sound:ToAll() end, {}, delay)
        found = true
      end
    end
  end
  
  if not found then
    error("Sound not found by type: " .. tostring(soundType))
  end
  
  return found
end

---
-- @param #Mission self
-- @param Core.Spawn#SPAWN spawner
function Mission:AddSpawner(spawner)
  self:AssertType(spawner, self.moose.spawn)
  self.spawners[#self.spawners + 1] = spawner
  self:Trace(3, "Spawner added, alias: " .. spawner.SpawnTemplatePrefix)
end

---
-- @param #Mission self
-- @param Wrapper.Group#GROUP group
function Mission:AddGroup(group)
  self:AssertType(group, self.moose.group)
  self.groups[#self.groups + 1] = group
  self:Trace(3, "Group added, name: " .. group:GetName())
  
  -- Note: Moose randomly returns either nil or 0 from GROUP:GetUnits()
  group.permanentUnits = {}
  local units = group:GetUnits()
  if units then
    for i = 1, #units do
      group.permanentUnits[i] = units[i]
    end
  end
end

---
-- @param #Mission self
-- @param Wrapper.Unit#UNIT unit
function Mission:AddUnit(unit)
  self:AssertType(unit, self.moose.unit)
  self.units[#self.units + 1] = unit
  self:Trace(3, "Unit added, name: " .. unit:GetName())
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
-- @param #Mission self
-- @param #list unitList
function Mission:UpdateUnitList(unitList)
  self.events:UpdateUnitList(unitList)
end

---
-- @param #Mission self
function Mission:GetDcsNumber(i)
  return string.format("#%03d", i)
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
    local name = prefix .. " " .. self:GetDcsNumber(i)
    self:Trace(4, "Finding unit in Moose: " .. name)
    
    local unit = self.moose.unit:FindByName(name)
    if unit then
      self:Trace(4, "Found unit in Moose: " .. unit:GetName())
    else
      self:Trace(4, "Did not find unit in Moose: " .. name)
      
      self:Trace(4, "Finding unit in DCS: " .. name)
      local dcsUnit = self.dcs.unit.getByName(name)
      if dcsUnit then
        self:Trace(4, "Found unit in DCS, adding to Moose database: " .. name)
        self.moose.database:AddUnit(name)
        unit = self.moose.unit:FindByName(name)
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

  if not soundDelay then
    soundDelay = 0
  end
  
  self:Trace(1, "Mission accomplished")
  self:MessageAll(MessageLength.Long, "Mission accomplished!")
  self:PlaySound(Sound.MissionAccomplished, soundDelay)
  self:PlaySound(Sound.BattleControlTerminated, soundDelay + 2)

end

---
-- @param #Mission self
function Mission:AnnounceLose(soundDelay)
  
  if not soundDelay then
    soundDelay = 0
  end
  
  self:Trace(1, "Mission failed")
  self:MessageAll(MessageLength.Long, "Mission failed!")
  self:PlaySound(Sound.MissionFailed, soundDelay)
  self:PlaySound(Sound.BattleControlTerminated, soundDelay + 2)

end

---
-- @param #Mission self
-- @param Wrapper.Group#GROUP playerGroup
-- @param Wrapper.Airbase#AIRBASE airbase
-- @param #number speed
function Mission:LandTestPlayers(playerGroup, airbase, speed)
  
  self:Assert(playerGroup ~= nil, "Arg `playerGroup` was nil")
  self:Assert(airbase ~= nil, "Arg `airbase` was nil")
  self:Assert(speed ~= nil, "Arg `speed` was nil")
  
  self:AssertType(playerGroup, self.moose.group)
  
  self:Trace(1, "Landing test players")
  local airbase = self.moose.airbase:FindByName(airbase)
  local land = airbase:GetCoordinate():WaypointAirLanding(speed, airbase)
  local route = { land }
  playerGroup:Route(route)
  
end

---
-- @param #Mission self
-- @param Core.Spawn#SPAWN spawn
function Mission:SelfDestructGroupsInSpawn(spawn, power, delay, separation)
  self:AssertType(spawn, self.moose.spawn)
  self:Trace(1, "Self-destructing groups in spawner")

  for i = 1, spawn.SpawnCount do
    local group = spawn:GetGroupFromIndex(i)
    
    if group then
      self:SelfDestructGroup(group, power, delay)
    else
      self:Trace(1, "Moose spawner has no group at index: " .. i)
    end
  end
end

---
-- @param #Mission self
-- @param Wrapper.Group#GROUP group
function Mission:SelfDestructGroup(group, power, delay, separation)
  self:AssertType(group, self.moose.group)
  self:Trace(1, "Self-destructing group: " .. group:GetName())
  
  -- Note: Moose randomly returns either nil or 0 from GROUP:GetUnits()
  local units = group:GetUnits()
  if not units then
    self:Trace(1, "Moose spawner has no units (this happens sometimes)")
    return
  end
  
  self:SelfDestructUnits(units, power, delay, separation)
end

---
-- @param #Mission self
-- @param #list<Wrapper.Unit#UNIT> units
function Mission:SelfDestructUnits(units, power, delay, separation)
  
  self:Assert(units ~= nil, "Arg: `units` was nil.")
  self:AssertType(units, "table")
  
  if not power then
    power = 100
  end
  
  if not delay then
    delay = 0
  end
  
  if not separation then
    separation = 0
  end
  
  for i = 1, #units do
    local unit = units[i]
    self:AssertType(unit, self.moose.unit)
    self:Trace(1, "Self-destructing unit: " .. unit:GetName())
    unit:Explode(power, delay + ((i - 1) * separation))
    unit.selfDestructDone = true
  end
end

---
-- @param #Mission self
-- @param Core.Spawn#SPAWN spawn
function Mission:CountAliveUnitsFromSpawn(spawn)
  self:AssertType(spawn, self.moose.spawn)
  self:Trace(3, "Checking spawn for alive groups count: Prefix='" 
    .. spawn.SpawnTemplatePrefix .. "' Count=" .. spawn.SpawnCount)
    
  local count = 0
  for i = 1, spawn.SpawnCount do
    local group = spawn:GetGroupFromIndex(i)
    if group then
      self:Trace(3, "Checking group for alive count: " .. group:GetName())
      
      -- Note: Moose randomly returns either nil or 0 from GROUP:GetUnits()
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
  self:Trace(3, "Found units alive in spawn group: " .. count)
  return count
end

--- 
-- @param #Mission self
-- @param Core.Spawn#SPAWN spawn
-- @param #number minLife
function Mission:SelfDestructDamagedUnits(spawn, minLife)
  
  self:Assert(spawn ~= nil, "Param: spawn cannot be nil")
  self:AssertType(spawn, self.moose.spawn)
  
  self:Trace(3, "Checking spawn groups for damage, count=" .. spawn.SpawnCount)
  
  for i = 1, spawn.SpawnCount do
    local group = spawn:GetGroupFromIndex(i)
    if group then
      self:Trace(3, "Checking group for damage: " .. group:GetName())
      
      -- Note: Moose randomly returns either nil or 0 from GROUP:GetUnits()
      local units = group:GetUnits()
      if units then
        self:SelfDestructDamagedUnitsInList(units, minLife)
      end
    end
  end
end

---
-- @param #Mission self
-- @param Wrapper.Group#GROUP group
-- @param #number minLife
function Mission:SelfDestructDamagedUnitsInGroup(group, minLife)

  self:Assert(group ~= nil, "Param: group cannot be nil")
  self:AssertType(group, self.moose.group)
  
  self:Trace(3, "Checking unit list for damage")
  
  -- Note: Moose randomly returns either nil or 0 from GROUP:GetUnits()
  local units = group:GetUnits()
  if units then
    self:SelfDestructDamagedUnitsInList(units)
  end
  
end

---
-- @param #Mission self
-- @param #list<Wrapper.Unit#UNIT> list
-- @param #number minLife
function Mission:SelfDestructDamagedUnitsInList(units, minLife)

  self:Assert(minLife ~= nil, "Param: minLife cannot be nil")
  self:Assert(units ~= nil, "Param: units cannot be nil")
  
  self:AssertType(units, "table")
  self:AssertType(minLife, "number")
  
  self:Trace(3, "Checking unit list for damage, count: " .. #units)
  
  if units then
    for i = 1, #units do
      local unit = units[i]
      self:AssertType(unit, self.moose.unit)
      
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

---
-- @param #Mission self
-- @param #MessageLength length
-- @param #string message
function Mission:MessageAll(length, message)

  self:Assert(length ~= nil, "Arg: `length` was nil.")
  self:Assert(message ~= nil, "Arg: `message` was nil.")

  self:AssertType(length, "number")
  self:AssertType(message, "string")
  
  local logType = nil
  local duration = nil
  if length == MessageLength.VeryShort then
    duration = self.messageTimeVeryShort
    logType = "VS"
  elseif length == MessageLength.Short then
    duration = self.messageTimeShort
    logType = "S"
  elseif length == MessageLength.Long then
    duration = self.messageTimeLong
    logType = "L"
  end
  
  self:Trace(1, logType .. " Message: " .. message)
  self:Assert(duration, "Unknown message length")
  self.moose.message:New(message, duration):ToAll()
end

--- 
-- @param #Mission self
function Mission:SetFlag(flag, value)
  self:AssertType(flag, "number")
  self:AssertType(value, "boolean")
  
  self:Trace(2, "Setting flag " .. flag .. " to " .. Boolean:ToString(value))
  self.dcs.trigger.action.setUserFlag(flag, value)
end

---
-- @param #Mission self
function Mission:LoadPlayers()

  self.playerGroup = self.moose.group:FindByName(self._playerGroupName)
  
  -- if player didn't use slot on load, assume test mode 
  if self.playerGroup then
  
    self.playerGroupName = self._playerGroupName
    self.playerPrefix = self._playerPrefix
    
  elseif self.playerTestOn then
  
    self.playerGroupName = "Test Squadron"
    self.playerPrefix = "Test"
    self.playerGroup = self.moose.group:FindByName(self.playerGroupName)
    
    if self.playerGroup then
      self.playerGroup:Activate()
    else
      self:Trace(1, "Test group not found")
    end
    
  end

  self:UpdatePlayers()

end

--- Moose randomly returns either a new group or nil from functions like 
-- UNIT:GetGroup(), so this is a handy lookup function for retrieving our
-- original Moose group instance (for when we modify the original instance 
-- in any way, for example: a new field). In order to access the original, 
-- it must first be stored using self:AddGroup(...).
-- 
-- @param #Mission self
-- @param Wrapper.Unit#UNIT unit
-- @return Wrapper.Group#GROUP
function Mission:FindGroupForUnit(unit)
  
  self:AssertType(unit, self.moose.unit)
  
  for i = 1, #self.groups do
  
    local group = self.groups[i]
    self:AssertType(group, self.moose.group)
  
    local units = group.permanentUnits
    for j = 1, #units do
      
      local test = units[j]
      if test:GetName() == unit:GetName() then
        return group
      end
      
    end
    
  end
  
  return nil
  
end

--- Moose calls DCS setTask which randomly ignores requests, so this function
-- forces you to set a delay of at least 1 second (which apparently makes the
-- DCS function call more reliable).
-- 
-- @param #Mission self
-- @param Wrapper.Group#GROUP group
function Mission:SetGroupTask(group, task, delay)

  self:Assert(delay >= 1, "Delay must be at least 1 for setTask to be reliable.")
  group:SetTask(task, delay)
  
end

---
-- @param #Mission self
-- @return Core.Spawn#SPAWN
function Mission:NewMooseSpawn(name, limit)

  local spawn = self.moose.spawn:New(name)
  self:Assert(spawn, "Spawn with name '" .. name .. "' could not be created")
  if limit ~= nil then
    spawn:InitLimit(limit, 0)
  end
  self:AddSpawner(spawn)
  return spawn
  
end

---
-- @param #Mission self
-- @return Core.Zone#ZONE
function Mission:NewMooseZone(name)

  local unit = self.moose.zone:New(name)
  self:Assert(unit, "Zone with name '" .. name .. "' could not be found")
  return unit
  
end

---
-- @param #Mission self
-- @return Wrapper.Group#GROUP
function Mission:GetMooseGroup(name)

  local group = self.moose.group:FindByName(name)
  self:Assert(group, "Group with name '" .. name .. "' was not found")
  self:AddGroup(group)
  return group
  
end

---
-- @param #Mission self
-- @return Wrapper.Unit#UNIT
function Mission:GetMooseUnit(name)

  local unit = self.moose.unit:FindByName(name)
  self:Assert(unit, "Unit with name '" .. name .. "' was not found")
  self:AddUnit(unit)
  return unit
  
end

---
-- @param #Mission self
function Mission:CreateDebugMenu(killObjects)

  local power = 100
  local delay = 1
  local separation = 1

  self:Assert(killObjects, "table")

  local menu = self.moose.menu.coalition:New(self.dcs.coalition.side.BLUE, "Debug")
  
  for i = 1, #killObjects do
  
    local killObject = killObjects[i]
    if killObject then
    
      if killObject.ClassName == self.moose.unit.ClassName then
        self.moose.menu.coalitionCommand:New(
          self.dcs.coalition.side.BLUE, "Kill unit: " .. killObject:GetName(), menu,
          function() self:SelfDestructUnits({ killObject }, power, delay, separation) end)
      end
      
      if killObject.ClassName == self.moose.group.ClassName then
        self.moose.menu.coalitionCommand:New(
          self.dcs.coalition.side.BLUE, "Kill group: " .. killObject:GetName(), menu,
          function() self:SelfDestructGroup(killObject, power, delay, separation) end)
      end
      
      if killObject.ClassName == self.moose.spawn.ClassName then
        self.moose.menu.coalitionCommand:New(
          self.dcs.coalition.side.BLUE, "Kill spawner groups: " .. killObject.SpawnTemplatePrefix, menu,
          function() self:SelfDestructGroupsInSpawn(killObject, power, delay, separation) end)
      end
    
    end
    
  end
  
end

---
-- @param #Mission self
function Mission:UpdatePlayers()
  
  if self.playerPrefix then
    -- player list can change at any moment on an MP server, and is often 
    -- out of sync with the group. this is used by the events system
    self.players = self:FindUnitsByPrefix(self.playerPrefix, self.playerMax)
  end

end


Mission = createClass(KDObject, Mission)
