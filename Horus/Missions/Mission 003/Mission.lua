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

function landTestPlayers(playerGroup)
  hTrace(2, "landing test players")
  local airbase = AIRBASE:FindByName(AIRBASE.Caucasus.Nalchik)
  local land = airbase:GetCoordinate():WaypointAirLanding(300, airbase)
  local route = { land }
  playerGroup:Route(route)
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
    local parked = playersAreParked and transportsAreParked 
    
    hTrace(1, (playersAreParked and "✔ Players: All parked" or "❌ Players: Not all parked"), 1)
    hTrace(1, (transportsAreParked and "✔ Transports: All parked" or "❌ Transports: Not all parked"), 1)
    hTrace(1, (parked and "✔ Everyone: All parked" or "❌ Everyone: Not all parked"), 1)
    
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
