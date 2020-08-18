skipMoose = true
dofile(baseDir .. "Horus/Source/Mission05.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMockMission(moose, dcs)
  return Mission05:New {
    trace = { _traceOn = false },
    moose = moose or MockMoose:New(),
    dcs = dcs or MockDCS:New()
  }
end

local function Test_New()

  local moose = MockMoose:New()
  moose.group.FindByName = function() return {} end
  moose.zone.FindByName = function() return {} end
  moose.menu.coalition.New = function() end
  moose.menu.coalitionCommand.New = function() end

  NewMockMission(moose)

end

function Test_Mission05()
  return RunTests {
    "Mission05",
    Test_New
  }
end
