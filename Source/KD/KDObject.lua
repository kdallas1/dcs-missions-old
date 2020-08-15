---
-- @module KD.KDObject

---
-- @type KDObject
KDObject = {
  className = "KDObject",
  
  _traceOn = false,
  _traceLevel = 1,
  _assert = true
}

local _tracePrefix = "[KD Trace]"

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
-- 
-- Arg ... for classes to combine (list of args). The order is important; 
-- constructors are called in the order that classes are listed.
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
    if not class.className then
      local fileName = debug.getinfo(2, "S").short_src:match("^.+[\\\/](.+)\".+$")
      if not fileName then fileName = "Unknown file" end
      env.info("Error: Debug " .. debug.traceback())
      error("Error: The `className` field cannot be nil. Called from: " .. fileName)
    end
    
    -- search for the existing class, and replace if exists.
    -- we're using a list instead of a table to maintain the ctor call order.
    local replaced = false
    for i = 1, #c.classes do
      if c.classes[i].className == class.className then
        c.classes[i] = class
        replaced = true
      end
    end
    
    if not replaced then
      c.classes[#c.classes + 1] = class
    end
    
  end

  -- define a new function for returned class
  function c:New()
  
    -- new object
    local o = {}
    setmetatable(o, c)
      
    -- call constructors for each class
    local classes = o.classes
    for i = 1, #classes do
      local class = classes[i]
      
      -- constructors are named the same as their class
      local ctor = class[class.className]
      
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
-- @param #KDObject self
-- @param #boolean traceOn True to enable trace.
function KDObject:SetTraceOn(traceOn)
  self._traceOn = traceOn
end

--- Trace level (logging).
-- @param #KDObject self
-- @param #number traceLevel 1 = low, 2 = med, 3 = high
function KDObject:SetTraceLevel(traceLevel)
  self._traceLevel = traceLevel
end

--- Enable assert (a type of error reporting).
-- @param #KDObject self
-- @param #boolean assert True to enable assert. 
function KDObject:SetAssert(assert)
  self._assert = assert
end

--- Copies trace options from an object.
-- @param #KDObject self
-- @param #KDObject object Object to copy from. 
function KDObject:CopyTrace(object)
  self._traceOn = object._traceOn
  self._traceLevel = object._traceLevel
  self._assert = object._assert
end

--- Horus log function. Short hand for: env.info("Horus: " .. line)
-- @param #KDObject self
-- @param #number level Level to trace at.
-- @param #string line Log line to output to env.info 
function KDObject:Trace(level, line)

  if (self._assert) then
    assert(type(level) == type(0), "level arg must be a number")
    assert(type(line) == type(""), "line arg must be a string")
  end
  
  if (self._traceOn and (level <= self._traceLevel)) then
    local funcName = debug.getinfo(2, "n").name
    local lineNum = debug.getinfo(2, "S").linedefined
    funcName = (funcName and funcName or "?")
    
    env.info(_tracePrefix .. " L" .. level .. " " .. funcName .. "@" .. lineNum .. ": " .. line)
  end
end

--- Assert wrapper which can be turned off
-- @param #KDObject self
-- @param #boolean case If false, assert fails
-- @param #string message Assert message if fail
-- @param #number stackPosition Adjust stack position of debug info
function KDObject:Assert(case, message, stackPosition)
  if (not self._assert) then
    return
  end
  
  if (not stackPosition) then
    stackPosition = 0
  end
  
  local funcName = debug.getinfo(2 + stackPosition, "n").name
  local lineNum = debug.getinfo(2 + stackPosition, "S").linedefined
  local fileName = debug.getinfo(2 + stackPosition, "S").source:match("^.+[\\\/](.+)\"?.?$")
  
  if not fileName then fileName = "Unknown" end
  if not funcName then funcName = "Unknown" end
  
  if (not case) then
    env.info(_tracePrefix .. " Assert: " .. message .. " [" .. fileName .. ":" .. funcName .. "@" .. lineNum .. "]")
    env.info(_tracePrefix .. " Assert: Debug " .. debug.traceback())
  end
  
  assert(case, message)
end

--- Asserts the correct type (Lua is loosely typed, so this is helpful)
-- @param #KDObject self
-- @param Core.Base#BASE object Object to check
-- @param #table _type Either Moose class or type string name to assert
function KDObject:AssertType(object, _type)
  if (not self._assert) then
    return
  end
  
  self:Assert(object, "Cannot check type, object is nil", 1)
  self:Assert(_type, "Cannot check type, _type is nil", 1)
  
  if (type(_type) == "string") then
    self:Assert(type(object) == _type,
      "Invalid type, expected '" .. _type .. "' but was '" .. type(object) .. "'", 1)
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
      self:Assert(object.ClassName, "Missing ClassName property on object", 1) 
      self:Assert(_type.ClassName, "Missing ClassName property on _type", 1)
      
      self:Assert(object.ClassName == _type.ClassName, 
        "Invalid type, expected '" .. _type.ClassName .. "' but was '" .. object.ClassName .. "'", 1)
    else
      error("Type check failed, object and _type missing ClassName")
    end
  
  else
    error("Type check failed, invalid args")
  end
end