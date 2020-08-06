---
-- @module KD.Object

--- 
-- @type Object

---
-- @field #Object
Object = {
  traceOn = false,
  traceLevel = 1,
  assert = false
}

-- https://www.lua.org/pil/16.3.html
-- look up for `k' in list of tables `plist'
local function search (k, plist)
  for i=1, table.getn(plist) do
    if plist[i] then
      local v = plist[i][k]     -- try `i'-th superclass
      if v then return v end
    end
  end
end

-- https://www.lua.org/pil/16.3.html
function createClass (...)
  local c = {}        -- new class

  -- class will search for each method in the list of its
  -- parents (`arg' is the list of parents)
  setmetatable(c, {__index = function (t, k)
    return search(k, arg)
  end})

  -- prepare `c' to be the metatable of its instances
  c.__index = c

  -- define a new constructor for this new class
  function c:new (o)
    o = o or {}
    setmetatable(o, c)
    return o
  end

  -- return new class
  return c
end

--- Turn on trace (logging)
-- @param #Object self
-- @param #boolean traceOn True to enable trace.
function Object:SetTraceOn(traceOn)
  self.traceOn = traceOn
end

--- Trace level (logging).
-- @param #Object self
-- @param #number traceLevel 1 = low, 2 = med, 3 = high
function Object:SetTraceLevel(traceLevel)
  self.traceLevel = traceLevel
end

--- Enable assert (a type of error reporting).
-- @param #Object self
-- @param #boolean assert True to enable assert. 
function Object:SetAssert(assert)
  self.assert = assert
end

--- Horus log function. Short hand for: env.info("Horus: " .. line)
-- @param #Object self
-- @param #number level Level to trace at.
-- @param #string line Log line to output to env.info 
function Object:Trace(level, line)

  if (self.assert) then
    assert(type(level) == type(0), "level arg must be a number")
    assert(type(line) == type(""), "line arg must be a string")
  end
  
  if (self.traceOn and (level <= self.traceLevel)) then
    local funcName = debug.getinfo(2, "n").name
    local lineNum = debug.getinfo(2, "S").linedefined
    funcName = (funcName and funcName or "?")
    
    env.info("Horus L" .. level .. " " .. funcName .. "@" .. lineNum .. ": " .. line)
  end
end

--- Assert wrapper which can be turned off
-- @param #Object self
-- @param #boolean case If false, assert fails
-- @param #string message Assert message if fail
function Object:Assert(case, message)
  if (not self.assert) then
    return
  end
  
  assert(case, message)
end

--- Asserts the correct type (Lua is loosely typed, so this is helpful)
-- @param #Object self
-- @param Core.Base#BASE object Object to check
-- @param #table _type Either Moose class or type string name to assert
function Object:AssertType(object, _type)
  if (not self.assert) then
    return
  end
  
  assert(object, "Cannot check type, object is nil")
  assert(_type, "Cannot check type, _type is nil")
  
  if (type(_type) == "string") then
    assert(type(object) == _type,
      "Invalid type, expected '" .. _type .. "' but was '" .. type(object) .. "'")
    return
  end
  
  -- in Lua, classes are tables
  if (type(object) == "table") then
    
    self:Trace(4, "Listing type properties")
    for field, v in pairs(object) do
      self:Trace(4, "Property: " .. field)
    end
  
    -- check for MOOSE class name
    if (object.ClassName or _type.ClassName) then
      assert(object.ClassName, "Missing ClassName property on object")
      assert(_type.ClassName, "Missing ClassName property on _type")
      
      assert(object.ClassName == _type.ClassName, 
        "Invalid type, expected '" .. _type.ClassName .. "' but was '" .. object.ClassName .. "'")
    else
      error("Type check failed, object and _type missing ClassName")
    end
  
  else
    error("Type check failed, invalid args")
  end
end

--- 
-- @param #Object self
-- @param #list list
function Object:ShuffleList(list)
  for i = #list, 2, -1 do
    local j = math.random(i)
    list[i], list[j] = list[j], list[i]
  end
end
