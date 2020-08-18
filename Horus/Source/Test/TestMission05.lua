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

local function Test_FriendlyHelosDead_MissionFailed()

  local moose = MockMoose:New()

  local friendlyHeloGroup = nil
  local friendlyHelos = {
    {
      ClassName = moose.unit.ClassName,
      GetName = function(self) return self.name end,
      GetLife = function(self) return self.life end,
      GetVelocityKNOTS = function() return 0 end,
      GetVec3 = function() end,
      IsAlive = function() return true end,
      name = "Friendly Helo #001",
      life = 50,
    },
    {
      ClassName = moose.unit.ClassName,
      GetName = function(self) return self.name end,
      GetLife = function(self) return self.life end,
      GetVelocityKNOTS = function() return 0 end,
      GetVec3 = function() end,
      IsAlive = function() return true end,
      name = "Friendly Helo #002",
      life = 50,
    }
  }

  moose.group.FindByName = function(self, name)

    local group = {
      ClassName = moose.group.ClassName,
      GetName = function(self) return self.name end,
      CountAliveUnits = function(self) return self.aliveCount end,
      GetUnits = function(self) 
        local units = {}
        if self.name == "Friendly Helos" then
          units = friendlyHelos
        end
        return units
      end,
      name = name,
      aliveCount = 0,
    }

    if name == "Friendly Helos" then
      friendlyHeloGroup = group
      group.aliveCount = 2
    end

    if name == "Enemy SAMs" then
      group.aliveCount = 2
    end
    
    return group

  end

  moose.unit.FindByName = function(self, name)
    local unit = {
      ClassName = moose.unit.ClassName,
      GetName = function(self) return self.name end,
      GetLife = function(self) return self.life end,
      name = name,
      life = 50,
    }
    return unit

  end

  moose.zone.FindByName = function(self, name) 
    return {
      ClassName = moose.zone.ClassName,
      GetName = function() return name end,
      IsVec3InZone = function() end
    }
  end

  moose.message.New = function()
    return {
      ToAll = function() end
    }
  end

  moose.menu.coalition.New = function() end
  moose.menu.coalitionCommand.New = function() end
  moose.scheduler.New = function() end
  moose.userSound.New = function() end

  local dcs = MockDCS:New()
  dcs.unit.getByName = function() end

  local mission = NewMockMission(moose, dcs)

  mission:Start()
  mission:GameLoop()

end

function Test_Mission05()
  return RunTests {
    "Mission05",
    Test_FriendlyHelosDead_MissionFailed
  }
end
