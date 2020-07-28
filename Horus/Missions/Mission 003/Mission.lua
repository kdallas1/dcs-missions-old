--BASE:TraceOnOff(true)
BASE:TraceAll(true)
BASE:TraceLevel(3)

hTraceOn = true
hTraceLevel = 2
hAssert = true

hTrace(1, "Script start")

nalchikParkZone = ZONE:FindByName("Nalchik Park")
transportCount = 5
transportSpawn = SPAWN:New("Transport"):InitLimit(100, transportCount):SpawnScheduled(200, 0)
winCheckInterval = 10
landTestPlayersDone = false
playerOnline = false
winLoseDone = false

function killTransport()
  group = transportSpawn:GetGroupFromIndex(1)
  if group then
    unit = group:GetUnit(1)
    unit:Explode(100, 0)
  end
end

local menu = MENU_COALITION:New(coalition.side.BLUE, "Debug")
MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Kill transport", menu, killTransport)

function landTestPlayers(playerGroup)
  hTrace(2, "landing test players")
  local airbase = AIRBASE:FindByName(AIRBASE.Caucasus.Nalchik)
  local land = airbase:GetCoordinate():WaypointAirLanding(300, airbase)
  local route = { land }
  playerGroup:Route(route)
end

function announceWin()
  MESSAGE:New("Mission accomplished!", 100):ToAll()
  USERSOUND:New("MissionAccomplished.ogg"):ToAll()
  winLoseDone = true
end

function announceLose()
  MESSAGE:New("Mission failed!", 100):ToAll()
  USERSOUND:New("MissionFailed.ogg"):ToAll()
  winLoseDone = true
end

function onTransportCrashed(e)
  MESSAGE:New("Transport crashed!", 100):ToAll()
  if (not winLoseDone) then
    announceLose()
  end
end

function onTransportHit(e)
  MESSAGE:New("Transport hit!", 100):ToAll()
end

events = EVENTHANDLER:New()
events:HandleEvent(EVENTS.Birth)

function events:OnEventBirth(e)
  unit = e.IniUnit
  hTrace(1, "Birth: " .. unit:GetName())
  
  unit:HandleEvent(EVENTS.Crash, onTransportCrashed)
  unit:HandleEvent(EVENTS.Hit, onTransportHit)
end

Messager = SCHEDULER:New(nil,
  function()
    
    local playerGroup = GROUP:FindByName("Dodge Squadron")
    if (not playerGroup) then
      return
    end
    
    if (groupHasPlayer(playerGroup) and not playerOnline) then
      hTrace(2, "player is now online (in player group)")
      playerOnline = true
    end
  
    local playersAreParked = groupIsParked(nalchikParkZone, playerGroup)
    local transportsAreParked =  spawnGroupsAreParked(nalchikParkZone, transportSpawn, transportCount)
    local everyoneParked = playersAreParked and transportsAreParked
    
    hTrace(1, (playersAreParked and "✔ Players: All parked" or "❌ Players: Not all parked"), 1)
    hTrace(1, (transportsAreParked and "✔ Transports: All parked" or "❌ Transports: Not all parked"), 1)
    hTrace(1, (everyoneParked and "✔ Everyone: All parked" or "❌ Everyone: Not all parked"), 1)
    
    if (everyoneParked and not winLoseDone) then
      announceWin()
    end
    
    if (transportsAreParked and not landTestPlayersDone) then
      landTestPlayers(playerGroup)
      landTestPlayersDone = true
    end
    
    keepAliveSpawnGroupsIfParked(nalchikParkZone, transportSpawn, transportCount)
    
    -- Only needed for AI (useful for testing).
    if (transportsAreParked and not playerOnline) then
      keepAliveGroupIfParked(nalchikParkZone, playerGroup)
    end
    
  end,
  {}, 0, winCheckInterval
)

hTrace(1, "Script end")
