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

  local friendlyHelo1 = moose:MockUnit("Friendly Helo #001", 10)
  local friendlyHelo2 = moose:MockUnit("Friendly Helo #002", 10)
  
  local friendlyHeloGroup = moose:MockGroup(
    "Friendly Helos", 
    { friendlyHelo1, friendlyHelo2 })
  friendlyHeloGroup.aliveCount = 2

  local enemySamGroup = moose:MockGroup("Enemy SAMs")
  enemySamGroup.aliveCount = 2

  moose:MockZone("Landing")

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
