BASE:TraceAll(true)
--BASE:TraceOnOff(true)
BASE:TraceLevel(1)

hlog("Script start")

transport = SPAWN:New("Transport"):InitLimit(3,3):SpawnScheduled(2,0)

hlog("Script end")
