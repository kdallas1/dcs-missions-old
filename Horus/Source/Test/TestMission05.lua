skipMoose = true
dofile(baseDir .. "Horus/Source/Mission05.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock()
  local mock = {}

  local moose = MockMoose:New()
  mock.moose = moose

  mock.friendlyHelo1 = moose:MockUnit({ name = "Friendly Helo #001", life = 10 })
  mock.friendlyHelo2 = moose:MockUnit({ name = "Friendly Helo #002", life = 10 })
  
  moose:MockGroup(
    {
      name = "Friendly Helos", 
      units = { mock.friendlyHelo1, mock.friendlyHelo2 },
      aliveCount = 2
    }
  )

  moose:MockGroup({ name = "Enemy SAMs", aliveCount = 2 })
  moose:MockZone({ name = "Landing" })

  moose.message.New = function()
    return {
      ToAll = function() end
    }
  end

  local dcs = MockDCS:New()
  mock.dcs = dcs

  dcs.unit.getByName = function() end

  mock.mission = Mission05:New {
    --trace = { _traceOn = false },
    trace = { _traceOn = true, _traceLevel = 4 },
    moose = moose,
    dcs = dcs
  }

  return mock
end

local function Test_FriendlyHelosAlive_MissionNotFailed()

  local mock = NewMock()
  local mission = mock.mission

  mission:Start()
  mission:GameLoop()

  TestAssert(
    mission.state.current ~= MissionState.MissionFailed,
    "Mission state should not be failed")

end

function Test_Mission05()
  return RunTests {
    "Mission05",
    Test_FriendlyHelosAlive_MissionNotFailed
  }
end
