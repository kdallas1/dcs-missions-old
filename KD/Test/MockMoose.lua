skipMoose = true
dofile(baseDir .. "KD/Moose.lua")
skipMoose = false

---
-- @module KD.Test.MockMoose

---
-- @type MockMoose
-- @extends KD.Moose#Moose
MockMoose = {
  className = "MockMoose"
}

local function stubFunction(self, ...)
  assert(self, "Non-static function called as static function.")
end

---
-- @param self #MockMoose
function MockMoose:MockMoose()
  local moose = self

  self.data = {
    groups = {},
    units = {},
    zones = {},
    statics = {}
  }

  self.scheduler = self:MockScheduler({ trace = self._traceOn })
  self.spawn = self:MockObject("MockSpawn", { moose = moose })
  self.group = self:MockObject("MockGroup", { data = self.data })
  self.unit = self:MockObject("MockUnit", { data = self.data })
  self.zone = self:MockObject("MockZone", { data = self.data })
  self.static = self:MockObject("MockStatic", { data = self.data })
  self.userSound = self:MockObject("MockUserSound")
  self.message = self:MockObject("MockMessage")
  self.menu = self:MockObject("MockMenu", {
    coalition = self:MockObject("MockMenuCoalition"),
    coalitionCommand = self:MockObject("MockMenuCoalitionCommand")
  })

  self.group.FindByName = function(self, name) return self.data.groups[name] end
  self.unit.FindByName = function(self, name) return self.data.units[name] end
  self.zone.New = function(self, name) return self.data.zones[name] end
  self.static.FindByName = function(self, name) return self.data.statics[name] end
  self.spawn.New = function(self, name) return moose:MockSpawn({ group = moose.data.groups[name] }) end

  self.message.New = function(self)
    return {
      ToAll = stubFunction
    }
  end

  self.userSound.New = function(self)
    return {
      ToAll = stubFunction
    }
  end

end

function MockMoose:MockObject(className, fields1, fields2)
  local mock = {
    ClassName =  className,
    New = stubFunction
  }
  if fields1 then
    for k, v in pairs(fields1) do
      mock[k] = v
    end
  end
  if fields2 then
    for k, v in pairs(fields2) do
      mock[k] = v
    end
  end
  return mock
end

function MockMoose:MockScheduler(fields)
  local scheduler = self:MockObject(
    "MockScheduler",
    {
      -- run scheduled function immediately by default
      run = true
    },
    fields
  )

  scheduler.New = function(self, object, runFunction, args, start)

    self.runFunction = runFunction
    self.Run = function(self)
      if self.trace then
        env.info("Test: Scheduler mock, running function now, real start: " .. start)
      end
      self.runFunction()
    end

    if self.run then
      self:Run()
    end
  end

  return scheduler
end

function MockMoose:MockSpawn(fields)
  local spawn = self:MockObject(
    self.spawn.ClassName,
    {
      Spawn = stubFunction,
      SpawnCount = 0
    },
    fields
  )
  return spawn
end

function MockMoose:MockUnit(fields)
  local unit = self:MockObject(
    self.unit.ClassName,
    {
      name = "Mock Unit",
      life = 2,
      isAlive = true,
      velocity = 0,
      group = nil,

      GetName = function(self) return self.name end,
      GetLife = function(self) return self.life end,
      GetVelocityKNOTS = function(self) return self.velocity end,
      IsAlive = function(self) return self.isAlive end,
      GetGroup = function(self) return self.group end,

      GetVec3 = stubFunction,

      MockKill = function (self)
        self.life = 1
        self.isAlive = false
      end
    },
    fields
  )
  self.data.units[unit.name] = unit
  return unit
end

function MockMoose:MockGroup(fields)
  local group = self:MockObject(
    self.group.ClassName,
    {
      name = "Mock Group",
      units = {},
      aliveCount = 1,

      GetName = function(self) return self.name end,
      GetUnits = function(self) return self.units end,
      CountAliveUnits = function(self) return self.aliveCount end,

      Activate = stubFunction,
    },
    fields
  )
  self.data.groups[group.name] = group
  return group
end

function MockMoose:MockZone(fields)
  local zone = self:MockObject(
    self.zone.ClassName,
    {
      name = "Mock Zone",

      GetName = function(self) return self.name end,
      IsVec3InZone = stubFunction
    },
    fields
  )
  self.data.zones[zone.name] = zone
  return zone
end

function MockMoose:MockStatic(fields)
  local static = self:MockObject(
    self.static.ClassName,
    {
      name = "Mock Static",

      GetName = function(self) return self.name end,
      IsVec3InZone = stubFunction,
      GetCoordinate = function() return { Explosion = stubFunction } end
    },
    fields
  )
  self.data.statics[static.name] = static
  return static
end

MockMoose = createClass(Moose, MockMoose)
