BASE:TraceAll(true)
--BASE:TraceOnOff(true)
BASE:TraceLevel(1)

hlog("Script start")

transport = SPAWN:New("Transport")
transport:SpawnScheduled(2, 0)

function helloScheduler()
  hlog("Scheduled function start")
  transport:SpawnScheduleStop()
  hlog("Scheduled function end")
end

SCHEDULER:New(nil, helloScheduler, {}, 2, 0, 0, 0)

hlog("Script end")
