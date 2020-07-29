Mission = {}

local _gameLoopInterval = 1
local _landTestPlayersDone = false
local _playerOnline = false
local _winLoseDone = false
local _transportCount = 5
local _maxUnitsAlive = 100
local _transportSeparation = 200
local _transportVariation = .5
local _nalchikParkZone = nil
local _transportSpawn = nil
local _events = nil

function Mission:Setup()
  Global:Trace(1, "Setup begin")
  
  --BASE:TraceOnOff(true)
  BASE:TraceAll(true)
  BASE:TraceLevel(3)
  
  Global:SetTraceOn(true)
  Global:SetTraceLevel(1)
  Global:SetAssert(true)
  
  _events = EVENTHANDLER:New()
  _nalchikParkZone = ZONE:FindByName("Nalchik Park")
  _transportSpawn = SPAWN:New("Transport")
    :InitLimit(_maxUnitsAlive, _transportCount)
    :SpawnScheduled(_transportSeparation, _transportVariation)
  
  Mission:SetupMenu()
  Mission:SetupEvents()
  
  SCHEDULER:New(nil,
    function() Mission:GameLoop() end, 
    {}, 0, _gameLoopInterval)
  
  Global:Trace(1, "Setup done")
end

function Mission:SetupMenu()
  local menu = MENU_COALITION:New(coalition.side.BLUE, "Debug")
  MENU_COALITION_COMMAND:New(
    coalition.side.BLUE, "Kill transport", menu,
    function() Mission:KillTransport() end)
end

function Mission:SetupEvents()
  _events:HandleEvent(EVENTS.Birth,
    function(h, e) Mission:OnEventBirth(h, e) end)
end

function Mission:OnEventBirth(h, e)
  Global:CheckType(h, EVENTHANDLER)
  Global:CheckType(e, "table")
  Global:CheckType(e.IniUnit, UNIT)
  
  local unit = e.IniUnit
  Global:Trace(2, "Unit birth: " .. unit:GetName())
  unit:HandleEvent(EVENTS.Crash,
    function(_unit) Mission:OnTransportCrashed(_unit) end)
end

function Mission:OnTransportCrashed(unit)
  Global:CheckType(unit, UNIT)
  Global:Trace(1, "Transport crashed: " .. unit:GetName())
  
  MESSAGE:New("Transport crashed!", 100):ToAll()
  if (not _winLoseDone) then
    Mission:AnnounceLose()
  end
end

function Mission:AnnounceWin()
  Global:Trace(1, "Mission accomplished")
  MESSAGE:New("Mission accomplished!", 100):ToAll()
  USERSOUND:New("MissionAccomplished.ogg"):ToAll()
  _winLoseDone = true
end

function Mission:AnnounceLose()
  Global:Trace(1, "Mission failed")
  MESSAGE:New("Mission failed!", 100):ToAll()
  USERSOUND:New("MissionFailed.ogg"):ToAll()
  _winLoseDone = true
end

function Mission:LandTestPlayers(playerGroup)
  Global:Trace(1, "Landing test players")
  local airbase = AIRBASE:FindByName(AIRBASE.Caucasus.Nalchik)
  local land = airbase:GetCoordinate():WaypointAirLanding(300, airbase)
  local route = { land }
  playerGroup:Route(route)
end

function Mission:KillTransport()
  Global:Trace(1, "Killing transport")
  local group = _transportSpawn:GetGroupFromIndex(1)
  if group then
    unit = group:GetUnit(1)
    unit:Explode(100, 0)
  end
end

function Mission:GameLoop()
    
  local playerGroup = GROUP:FindByName("Dodge Squadron")

  -- if no players, then say all players are parked (not sure if this makes sense).
  local playersAreParked = ((not playerGroup) or Global:GroupIsParked(_nalchikParkZone, playerGroup))
  local transportsAreParked = Global:SpawnGroupsAreParked(_nalchikParkZone, _transportSpawn, _transportCount)
  local everyoneParked = (playersAreParked and transportsAreParked)
  
  Global:Trace(2, (playersAreParked and "✔️ Players: All parked" or "❌ Players: Not all parked"), 1)
  Global:Trace(2, (transportsAreParked and "✔️ Transports: All parked" or "❌ Transports: Not all parked"), 1)
  Global:Trace(2, (everyoneParked and "✔️ Everyone: All parked" or "❌ Everyone: Not all parked"), 1)
  
  if (everyoneParked and not _winLoseDone) then
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
      Global:KeepAliveGroupIfParked(_nalchikParkZone, playerGroup)
    end
    
  end
  
  Global:KeepAliveSpawnGroupsIfParked(_nalchikParkZone, _transportSpawn, _transportCount)
  
end

Mission:Setup()
