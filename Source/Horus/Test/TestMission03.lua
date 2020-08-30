skipMoose = true
dofile(baseDir .. "Horus/Mission03.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)
  
  mock.moose:MockZone({ name = "Nalchik Park" })
  mock.moose:MockGroup({ name = "Transport" })
  
  mock.dcs = MockDCS:New()

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = Mission03:New(args)

  return mock
  
end

local function Test_Start()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  TestAssert(
    mock.mission.state.current == MissionState.MissionStarted,
    "State should be: Mission accomplished")

end

function Test_Mission03()
  return RunTests {
    "Mission03",
    Test_Start
  }
end

--testOnly = Test_Mission03
