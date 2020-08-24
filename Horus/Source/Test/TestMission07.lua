skipMoose = true
dofile(baseDir .. "Horus/Source/Mission07.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)

  local player = mock.moose:MockUnit({ name = "Dodge #001" })
  mock.moose:MockGroup({ name = "Dodge Squadron", units = { player } })

  mock.moose:MockZone({ name = "Nalchik Park" })

  mock.dcs = MockDCS:New()

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = Mission07:New(args)

  return mock
end

local function Test_Start()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  mock.mission:Start()

end

function Test_Mission07()
  return RunTests {
    "Mission07",
    Test_Start
  }
end

--testOnly = Test_Mission07
