---
-- @module KD.Object

---
-- @type Object
Object = {
  className = "Object",
  
  _traceOn = false,
  _traceLevel = 1,
  _assert = false
}

--- Search for a field in a list of objects
-- Source: https://www.lua.org/pil/16.3.html
-- @param #string k Name of field to search for
local function search(k, plist)
  for i=1, table.getn(plist) do
    if plist[i] then
      -- try `i'-th superclass
      local v = plist[i][k]
      if v then return v end
    end
  end
end

--- Combine multiple classes together.
-- Arg ... for classes to combine (list of args)
-- 
-- Source: https://www.lua.org/pil/16.3.html
-- @return #table Returns a class
function createClass(...)
  local classList = arg
  
  -- ensure all args are tables
  for i = 1, classList.n do
    local class = classList[i]
    
    if type(class) ~= "table" then
      local fileName = debug.getinfo(2, "S").short_src:match("^.+[\\\/](.+)\".+$")
      if not fileName then fileName = "Unknown file" end
      
      error(
        "Error: Expected `table` type, but arg #" .. i .. " was `" .. type(class) .. "`. " ..
        "All createClass args must be tables. Called from: " .. fileName)
        
      return
    end
  end

  -- new class
  local c = {}

  -- class will search for each method in the list of its
  -- parents (`arg' is the list of parents)
  setmetatable(c, {__index = function (t, k)
    return search(k, classList)
  end})
  
  -- prepare `c' to be the metatable of its instances
  c.__index = c
  
  if not c.classes then
    c.classes = {}
  end
  
  -- save parents
  for i = 1, classList.n do
    local class = classList[i]
    if class.className then
      c.classes[class.className] = class
    end
  end

  -- define a new function for returned class
  function c:New()
  
    -- new object
    local o = {}
    setmetatable(o, c)
      
    -- call constructors for each class
    for className, class in pairs(o.classes) do
      local ctor = o[class.className]
      
      -- constructors are named the same as their class
      if ctor then
        ctor(o)
      end
    end
    
    -- object
    return o
  end
  
  -- class
  return c
end

--- Turn on trace (logging)
-- @param #Object self
-- @param #boolean traceOn True to enable trace.
function Object:SetTraceOn(traceOn)
  self._traceOn = traceOn
end

--- Trace level (logging).
-- @param #Object self
-- @param #number traceLevel 1 = low, 2 = med, 3 = high
function Object:SetTraceLevel(traceLevel)
  self._traceLevel = traceLevel
end

--- Enable assert (a type of error reporting).
-- @param #Object self
-- @param #boolean assert True to enable assert. 
function Object:SetAssert(assert)
  self._assert = assert
end

--- Copies trace options from an object.
-- @param #Object self
-- @param #Object object Object to copy from. 
function Object:CopyTrace(object)
  self._traceOn = object._traceOn
  self._traceLevel = object._traceLevel
  self._assert = object._assert
end

--- Horus log function. Short hand for: env.info("Horus: " .. line)
-- @param #Object self
-- @param #number level Level to trace at.
-- @param #string line Log line to output to env.info 
function Object:Trace(level, line)

  if (self._assert) then
    assert(type(level) == type(0), "level arg must be a number")
    assert(type(line) == type(""), "line arg must be a string")
  end
  
  if (self._traceOn and (level <= self._traceLevel)) then
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
  if (not self._assert) then
    return
  end
  
  assert(case, message)
end

--- Asserts the correct type (Lua is loosely typed, so this is helpful)
-- @param #Object self
-- @param Core.Base#BASE object Object to check
-- @param #table _type Either Moose class or type string name to assert
function Object:AssertType(object, _type)
  if (not self._assert) then
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
    
    self:Trace(5, "Listing type properties")
    for field, v in pairs(object) do
      self:Trace(5, "Property: " .. field)
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
