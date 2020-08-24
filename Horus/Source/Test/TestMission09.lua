skipMoose = true
dofile(baseDir .. "Horus/Source/Mission09.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)

  local player = mock.moose:MockUnit({ name = "Dodge #001" })
  mock.moose:MockGroup({ name = "Dodge Squadron", units = { player } })

  mock.dcs = MockDCS:New()

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = Mission09:New(args)

  return mock
end

local function Test_Start()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  mock.mission:Start()

end

function Test_Mission09()
  return RunTests {
    "Mission09",
    Test_Start
  }
end

--testOnly = Test_Mission09
