---
-- @module Mission

--- @type Mission
Mission = {}

local _gameLoopInterval = 1
local _landTestPlayersDone = false
local _playerOnline = false
local _winLoseDone = false
local _transportCount = 5
local _maxUnitsAlive = 100
local _transportSeparation = 200
local _transportVariation = .5
local _migsPerAirbase = 4;
local _migsSpawnSeparation = 300
local _migsSpawnVariation = .5
local _transportMinLife = 30

---
-- @param #Mission self
function Mission:Setup()
  Global:Trace(1, "Setup begin")
  
  --BASE:TraceOnOff(true)
  BASE:TraceAll(true)
  BASE:TraceLevel(3)
  
  --GROUP:FindByName("Dodge Squadron"):Destroy()
  
  Global:SetTraceOn(true)
  Global:SetTraceLevel(1)
  Global:SetAssert(true)
  
  local events = EVENTHANDLER:New()
  local nalchikParkZone = ZONE:FindByName("Nalchik Park")
  local transportSpawn = SPAWN:New("Transport")
    :InitLimit(_maxUnitsAlive, _transportCount)
    :SpawnScheduled(_transportSeparation, _transportVariation)
  
  Mission:SetupMenu(transportSpawn)
  
  for i = 1, 3 do
    SPAWN:New("MiG " .. i)
      :InitLimit(_migsPerAirbase, _migsPerAirbase)
      :SpawnScheduled(_migsSpawnSeparation, _migsSpawnVariation)
  end
  
  SCHEDULER:New(nil,
    function() Mission:GameLoop(nalchikParkZone, transportSpawn) end, 
    {}, 0, _gameLoopInterval)
  
  Global:Trace(1, "Setup done")
  
end

---
-- @param #Mission self
-- @param Core.Spawn#SPAWN transportSpawn
function Mission:SetupMenu(transportSpawn)
  local menu = MENU_COALITION:New(coalition.side.BLUE, "Debug")
  MENU_COALITION_COMMAND:New(
    coalition.side.BLUE, "Kill transport", menu,
    function() Mission:KillTransport(transportSpawn) end)
end

---
-- @param #Mission self
-- @param Wrapper.Unit#UNIT unit
function Mission:OnTransportDead(unit)
  Global:CheckType(unit, UNIT)
  Global:Trace(1, "Transport destroyed: " .. unit:GetName())
  MESSAGE:New("Transport destroyed!", 100):ToAll()
  if (not _winLoseDone) then
    Mission:AnnounceLose()
  end
end

---
-- @param #Mission self
function Mission:AnnounceWin()
  Global:Trace(1, "Mission accomplished")
  MESSAGE:New("Mission accomplished!", 100):ToAll()
  USERSOUND:New("MissionAccomplished.ogg"):ToAll()
  _winLoseDone = true
end

---
-- @param #Mission self
function Mission:AnnounceLose()
  Global:Trace(1, "Mission failed")
  MESSAGE:New("Mission failed!", 100):ToAll()
  USERSOUND:New("MissionFailed.ogg"):ToAll()
  _winLoseDone = true
end

---
-- @param #Mission self
-- @param Wrapper.Group#GROUP playerGroup
function Mission:LandTestPlayers(playerGroup)
  Global:Trace(1, "Landing test players")
  local airbase = AIRBASE:FindByName(AIRBASE.Caucasus.Nalchik)
  local land = airbase:GetCoordinate():WaypointAirLanding(300, airbase)
  local route = { land }
  playerGroup:Route(route)
end

---
-- @param #Mission self
-- @param Core.Spawn#SPAWN transportSpawn
function Mission:KillTransport(transportSpawn)
  Global:Trace(1, "Killing transport")
  local group = transportSpawn:GetGroupFromIndex(1)
  if group then
    unit = group:GetUnit(1)
    unit:Explode(100, 0)
    unit.selfDestructDone = true
  end
end

---
-- @param #Mission self
-- @param Core.Spawn#SPAWN transportSpawn
function Mission:CheckTransportDamage(transportSpawn)
  Global:Trace(3, "Checking spawn groups for damage")
  for i = 1, _transportCount do
    local group = transportSpawn:GetGroupFromIndex(i)
    if group then
      Global:Trace(3, "Checking group for damage: " .. group:GetName())
      
      local units = group:GetUnits()
      if units then
        for j = 1, #units do
          local unit = group:GetUnit(j)
          local life = unit:GetLife()
          local fireDieEvent = false
          
          Global:Trace(3, "Checking unit for damage: " .. unit:GetName() .. ", health " .. tostring(life))
          
          -- we can't use IsAlive here, because the unit may not have spawned yet 
          if (life <= 1) then
            fireDieEvent = true
          end
          
          -- only kill the unit if it's alive, otherwise it'll never crash.
          -- explode transports below a certain live level, otherwise
          -- transports can land in a damaged and prevent other transports
          -- from landing
          if (unit:IsAlive() and (not unit.selfDestructDone) and (unit:GetLife() < _transportMinLife)) then
            Global:Trace(1, "Auto-kill " .. unit:GetName() .. ", health " .. tostring(life) .. "<" .. _transportMinLife)
            unit:Explode(100, 1)
            unit.selfDestructDone = true
            fireDieEvent = true
          end
          
          -- previously using the EVENTS.Crash event, but it was a bit unreliable
          if (fireDieEvent and (not unit.eventDeadFired)) then
            Global:Trace(3, "Firing unit dead event: " .. unit:GetName())
            Mission:OnTransportDead(unit)
            unit.eventDeadFired = true
          end
        end
      end
    end
  end
end

-- TODO: consider merging this with CheckTransportDamage
---
-- @param #Mission self
-- @param Core.Spawn#SPAWN transportSpawn
function Mission:GetAliveTransportCount(transportSpawn)
  Global:Trace(3, "Checking spawn groups for alive count")
  
  local count = 0
  for i = 1, _transportCount do
    local group = transportSpawn:GetGroupFromIndex(i)
    if group then
      Global:Trace(3, "Checking group for alive count: " .. group:GetName())
      
      local units = group:GetUnits()
      if units then
        for j = 1, #units do
          local unit = group:GetUnit(j)
          Global:Trace(3, "Checking if unit is alive: " .. unit:GetName())
          
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
-- @param #Mission self
-- @param Core.Zone#ZONE nalchikParkZone
-- @param Core.Spawn#SPAWN transportSpawn
function Mission:GameLoop(nalchikParkZone, transportSpawn)
  Global:CheckType(nalchikParkZone, ZONE)
  Global:CheckType(transportSpawn, SPAWN)
  
  if (_winLoseDone) then
    return
  end
  
  local playerGroup = GROUP:FindByName("Dodge Squadron")

  -- if no players, then say all players are parked (not sure if this makes sense).
  local playersAreParked = ((not playerGroup) or Global:GroupIsParked(nalchikParkZone, playerGroup))
  local transportsAreParked = Global:SpawnGroupsAreParked(nalchikParkZone, transportSpawn, _transportCount)
  local everyoneParked = (playersAreParked and transportsAreParked)
  
  Global:Trace(2, "Transports alive: " .. Mission:GetAliveTransportCount(transportSpawn))
  Global:Trace(2, (playersAreParked and "✔️ Players: All parked" or "❌ Players: Not all parked"), 1)
  Global:Trace(2, (transportsAreParked and "✔️ Transports: All parked" or "❌ Transports: Not all parked"), 1)
  Global:Trace(2, (everyoneParked and "✔️ Everyone: All parked" or "❌ Everyone: Not all parked"), 1)
  
  if (everyoneParked) then
    Mission:AnnounceWin()
  end
  
  -- no player group happens when no players are online yet
  if (playerGroup) then
  
    if (Global:GroupHasPlayer(playerGroup) and not _playerOnline) then
      Global:Trace(1, "Player is now online (in player group)")
      _playerOnline = true
    end
  
    if (transportsAreParked and (not _landTestPlayersDone)) then
      Mission:LandTestPlayers(playerGroup)
      _landTestPlayersDone = true
    end
    
    -- keep alive only needed for AI player group (which is useful for testing).
    if (transportsAreParked and (not _playerOnline)) then
      Global:KeepAliveGroupIfParked(nalchikParkZone, playerGroup)
    end
    
  end
  
  Global:KeepAliveSpawnGroupsIfParked(nalchikParkZone, transportSpawn, _transportCount)
  Mission:CheckTransportDamage(transportSpawn)
  
end

Mission:Setup()
