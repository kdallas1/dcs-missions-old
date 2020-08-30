skipMoose = true
dofile(baseDir .. "Horus/Mission02.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)
  mock.dcs = MockDCS:New()

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = Mission02:New(args)

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

function Test_Mission02()
  return RunTests {
    "Mission02",
    Test_Start
  }
end

--testOnly = Test_Mission02
