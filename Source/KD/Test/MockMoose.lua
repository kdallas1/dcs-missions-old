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
    spawn = {},
    groups = {},
    units = {},
    zones = {},
    statics = {},
    arty = {},
    airbase = {}
  }

  self.scheduler = self:MockScheduler({ trace = self._traceOn })
  self.group = self:MockObject("MockGroup", { data = self.data })
  self.unit = self:MockObject("MockUnit", { data = self.data })
  self.zone = self:MockObject("MockZone", { data = self.data })
  self.static = self:MockObject("MockStatic", { data = self.data })
  self.arty = self:MockObject("MockArty", { data = self.data, WeaponType = {} })
  self.userSound = self:MockObject("MockUserSound")
  self.message = self:MockObject("MockMessage")
  self.menu = self:MockObject("MockMenu", {
    coalition = self:MockObject("MockMenuCoalition"),
    coalitionCommand = self:MockObject("MockMenuCoalitionCommand")
  })

  self.spawn = self:MockObject("MockSpawn", {
    data = self.data,
    Takeoff = { }
  })
  
  self.airbase = self:MockObject("MockAirbase", {
    data = self.data,
    
    Caucasus = {
      Nalchik = "Stub",
      Mineralnye_Vody = "Stub",
      Mozdok = "Stub"
    }
  })

  self.group.FindByName = function(self, name) return self.data.groups[name] end
  self.unit.FindByName = function(self, name) return self.data.units[name] end
  self.static.FindByName = function(self, name) return self.data.statics[name] end
  self.arty.New = function(self, name) return self.data.arty[name] end
  
  self.zone.FindByName = function(self, name) return self.data.zones[name] end
  self.zone.New = self.zone.FindByName
  
  self.airbase.FindByName = function(self, name)
    if self.data.airbase[name] then
      return self.data.airbase[name] 
    else
      return moose:MockAirbase({ name = name })
    end
  end
  
  self.spawn.New = function(self, name) 
    if moose.data.spawn[name] then
      return moose.data.spawn[name]
    else
      return moose:MockSpawn({ group = moose.data.groups[name] })
    end
  end

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
  
  self:AssertType(className, "string")
  
  local mock = {
    ClassName =  className,
    New = stubFunction
  }
  
  if fields1 then
    self:AssertType(fields1, "table")
    for k, v in pairs(fields1) do
      mock[k] = v
    end
  end
  
  if fields2 then
    self:AssertType(fields2, "table")
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
      SpawnCount = 0,
      SpawnTemplatePrefix = "Mock Spawn",
      SpawnAliasPrefix = nil,
      
      InitLimit = function() return self end,
      Spawn = function() return self:MockGroup() end,
      SpawnScheduled = function(self) return self end,
      SpawnAtAirbase = function() return self:MockGroup() end,
      SpawnScheduleStop = function(self) return self end,
      SpawnScheduleStart = function(self) return self end,
      
      GetGroupFromIndex = stubFunction,
      InitUnControlled = stubFunction
    },
    fields
  )
  self.data.spawn[spawn.SpawnTemplatePrefix] = spawn
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

      GetPlayerName = function(self) return self.name end,
      GetName = function(self) return self.name end,
      GetLife = function(self) return self.life end,
      GetVelocityKNOTS = function(self) return self.velocity end,
      IsAlive = function(self) return self.isAlive end,
      
      -- Moose often returns nil for the ID, so always assume worst case.
      GetID = function(self) return nil end,
      
      -- Moose either returns a new group instance rather than remembering a single group instance,
      -- or returns nil. Also, nil seems to be randomly returned, so let's assume the worst case.
      GetGroup = function(self_) return nil end,
      
      GetCoordinate = function(self)
        return {
          GetVec2 = stubFunction
        }
      end,

      GetVec3 = stubFunction,
      Explode = stubFunction,
      
      SmokeGreen = stubFunction,
      SmokeRed = stubFunction,
      SmokeWhite = stubFunction,
      SmokeOrange = stubFunction,
      SmokeBlue = stubFunction,
      IsAboveRunway = stubFunction,

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
      aliveUnit = nil,
      ammunition = 0,
      
      GetName = function(self) return self.name end,
      GetUnits = function(self) return self.units end,
      CountAliveUnits = function(self) return self.aliveCount end,
      GetFirstUnitAlive = function(self) return self.aliveUnit end,
      GetAmmunition = function(self) return self.ammunition end,
      IsAlive = function(self) return self.aliveCount > 0 end,
      GetTemplate = function() return {} end,

      -- Moose often returns nil for the ID, so always assume worst case.
      GetID = function(self) return nil end,

      Activate = stubFunction,      
      TaskFireAtPoint = stubFunction,
      SetTask = stubFunction,
      Route = stubFunction,
      IsCompletelyInZone = stubFunction,
      RespawnAtCurrentAirbase = stubFunction,
      GetVelocityKNOTS = stubFunction,
      IsAnyInZone = stubFunction,
      GetTypeName = stubFunction,
      GetUnit = stubFunction,
      TaskAttackGroup = stubFunction,
      Respawn = stubFunction,
      
      SmokeGreen = stubFunction,
      SmokeRed = stubFunction,
      SmokeWhite = stubFunction,
      SmokeOrange = stubFunction,
      SmokeBlue = stubFunction,

      MockKill = function (self)
        self.aliveCount = 0
        self.aliveUnit = nil
        for i = 1, #self.units do
          self.units[i]:MockKill()
        end
      end
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

function MockMoose:MockArty(fields)
  local arty = self:MockObject(
    self.static.ClassName,
    {
      name = "Mock Arty",

      Start = stubFunction,
      SetRearmingGroup = stubFunction,
      SetMaxFiringRange = stubFunction
    },
    fields
  )
  self.data.arty[arty.name] = arty
  return arty
end

function MockMoose:MockAirbase(fields)
  local airbase = self:MockObject(
    self.static.ClassName,
    {
      name = "Mock Airbase",

      GetCoordinate = function()
        return {
          WaypointAirLanding = stubFunction
        }
      end,
    },
    fields
  )
  self.data.airbase[airbase.name] = airbase
  return airbase
end

MockMoose = createClass(Moose, MockMoose)
