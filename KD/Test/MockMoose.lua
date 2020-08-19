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

---
-- @param self #MockMoose
function MockMoose:MockMoose(args)
  local trace = args.trace

  self:SetTraceOn(trace)

  self.data = {
    groups = {},
    units = {},
    zones = {},
    statics = {}
  }

  self.spawn = self:MockObject("MockSpawn")
  self.group = self:MockObject("MockGroup", { data = self.data })
  self.unit = self:MockObject("MockUnit", { data = self.data })
  self.zone = self:MockObject("MockZone", { data = self.data })
  self.static = self:MockObject("MockStatic", { data = self.data })
  self.scheduler = self:MockObject("MockScheduler")
  self.userSound = self:MockObject("MockUserSound")
  self.message = self:MockObject("MockMessage")
  self.menu = self:MockObject("MockMenu", {
    coalition = self:MockObject("MockMenuCoalition"),
    coalitionCommand = self:MockObject("MockMenuCoalitionCommand")
  })

  self.group.FindByName = function(self, name) return self.data.groups[name] end
  self.unit.FindByName = function(self, name) return self.data.units[name] end
  self.zone.FindByName = function(self, name) return self.data.zones[name] end
  self.static.FindByName = function(self, name) return self.data.statics[name] end

  -- run scheduled function immediately by default
  self.scheduler.run = true
  self.scheduler.New = function(self, object, function_, args, start)
    if self.run then
      if trace then
        env.info("Test: Scheduler mock, running function now, real start: " .. start)
      end
      function_()
    end
  end

  self.message.New = function()
    return {
      ToAll = function() end
    }
  end

  self.userSound.New = function()
    return {
      ToAll = function() end
    }
  end

end

function MockMoose:MockObject(className, fields1, fields2)
  local mock = {
    ClassName =  className,
    New = function() end
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

function MockMoose:MockUnit(fields)
  local unit = self:MockObject(
    self.unit.ClassName,
    {
      name = "Mock Unit",
      life = 0,
      isAlive = true,

      GetName = function(self) return self.name end,
      GetLife = function(self) return self.life end,
      GetVelocityKNOTS = function() return 0 end,
      GetVec3 = function() end,
      IsAlive = function() return self.isAlive end,
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
      aliveCount = 0,

      GetName = function(self) return self.name end,
      GetUnits = function(self) return self.units end,
      CountAliveUnits = function(self) return self.aliveCount end,
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
      IsVec3InZone = function() end
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
      IsVec3InZone = function() end
    },
    fields
  )
  self.data.statics[static.name] = static
  return static
end

MockMoose = createClass(Moose, MockMoose)
