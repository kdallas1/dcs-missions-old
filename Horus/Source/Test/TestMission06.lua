skipMoose = true
dofile(baseDir .. "Horus/Source/Mission06.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)

  for i = 1, 4 do
    local fobName = "FOB " .. i
    mock.moose:MockGroup({ name = fobName .. " SAM" })
    mock.moose:MockStatic({ name = fobName .. " Command" })
    mock.moose:MockGroup({ name = fobName .. " Tanks" })
    mock.moose:MockGroup({ name = fobName .. " Helos" })
  end

  mock.dcs = MockDCS:New()

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = Mission06:New(args)

  return mock
end

local function Test_Start()

  local mock = NewMock()

  mock.mission:Start()

end

function Test_Mission06()
  return RunTests {
    "Mission06",
    Test_Start
  }
end

testOnly = Test_Mission06
