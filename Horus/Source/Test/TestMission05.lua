skipMoose = true
dofile(baseDir .. "Horus/Source/Mission05.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMockMission(moose, dcs)
  return Mission05:New {
    --trace = { _traceOn = false },
    trace = { _traceOn = true, _traceLevel = 4 },
    moose = moose or MockMoose:New(),
    dcs = dcs or MockDCS:New()
  }
end

local function Test_FriendlyHelosAlive_MissionNotFailed()

  local moose = MockMoose:New()

  local friendlyHelo1 = moose:MockUnit({ name = "Friendly Helo #001", life = 10 })
  local friendlyHelo2 = moose:MockUnit({ name = "Friendly Helo #002", life = 10 })
  
  moose:MockGroup(
    {
      name = "Friendly Helos", 
      units = { friendlyHelo1, friendlyHelo2 },
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
  dcs.unit.getByName = function() end

  local mission = NewMockMission(moose, dcs)

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
