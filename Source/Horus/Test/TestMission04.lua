skipMoose = true
dofile(baseDir .. "Horus/Mission04.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)
  
  mock.playerGroup = mock.moose:MockGroup({
    name = "Dodge Squadron",
    units = { mock.moose:MockUnit({ name = "Dodge #001" }) },
    IsAnyInZone = function() return false end
  })
  
  mock.moose:MockGroup({
    name = "Friendly Helos",
    units = { mock.moose:MockUnit({ name = "Helo #001" }) },
    IsCompletelyInZone = function() return false end
  })
  
  mock.moose:MockGroup({ name = "Enemy Helos" })
  mock.moose:MockGroup({ name = "Enemy Ground" })
  mock.moose:MockZone({ name = "Extraction Land" })
  mock.moose:MockZone({ name = "Extraction" })
  mock.moose:MockZone({ name = "Rendezvous" })
  mock.moose:MockZone({ name = "Nalchik Park" })
  
  mock.dcs = MockDCS:New()

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = Mission04:New(args)

  return mock
  
end

local function Test_Start()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 3 },
  })

  mock.mission:Start()

  TestAssert(
    mock.mission.state.current == MissionState.MissionStarted,
    "State should be: Mission accomplished")

end

function Test_Mission04()
  return RunTests {
    "Mission04",
    Test_Start
  }
end

--testOnly = Test_Mission04
