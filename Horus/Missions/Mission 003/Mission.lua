BASE:TraceAll(true)
--BASE:TraceOnOff(true)
BASE:TraceLevel(1)

hlog("Script start")

transport = SPAWN:New("Transport")

function helloScheduler()
  hlog("Scheduled function start")
  transport:Spawn()
  hlog("Scheduled function end")
end

SCHEDULER:New(nil, helloScheduler, {}, 0, 2, 0, 10)

hlog("Script end")
