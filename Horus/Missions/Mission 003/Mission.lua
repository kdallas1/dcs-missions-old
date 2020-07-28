BASE:TraceAll(true)
--BASE:TraceOnOff(true)
BASE:TraceLevel(1)

hlog("Script start")

transport = SPAWN:New("Transport")
transportCount = 0
maxTransports = 3

function spawnTransport()
  hlog("Spawn transport start")
  transport:Spawn()
  transportCount = incr(transportCount)
  
  if (transportCount < maxTransports) then
    SCHEDULER:New(nil, spawnTransport, {}, 2, 0, 0, 0)
  end
  
  hlog("Spawn transport end")
end

SCHEDULER:New(nil, spawnTransport, {}, 0, 0, 0, 0)

hlog("Script end")
