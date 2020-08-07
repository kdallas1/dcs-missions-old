dofile(baseDir .. "KD/Object.lua")

local function Test_ObjectsAreUnique()

  Child1 = { }
  Child2 = { }
  Child3 = createClass(Child2, Child1, Object)
  local c1 = Child3:New()
  local c2 = Child3:New()
  
  c1.string = "foo"
  c2.string = "bar"
  
  TestAssert(c1.string ~= c2.string, "String values are shared")
  
end

local function Test_ObjectsInherit()

  Child1 = { foo = "test" }
  Child1 = createClass(Child1, Object)
  local c = Child1:New()
  
  TestAssert(c.foo, "Expected field from Child1")
  TestAssert(c.foo == "test", "Expected string from Child1")
  
end

local function Test_ObjectsInheritDeeply()

  Child1 = { foo = "test" }
  Child2 = { bar = "test" }
  Child3 = { baz = "test" }
  Child3 = createClass(Child3, Child2, Child1, Object)
  local c = Child3:New()
  
  TestAssert(c.foo == "test", "Expected string from Child1")
  TestAssert(c.bar == "test", "Expected string from Child2")
  TestAssert(c.baz == "test", "Expected string from Child3")
  
end

function Test_Object()
  return RunTests {
    Test_ObjectsInherit,
    Test_ObjectsInheritDeeply,
    Test_ObjectsAreUnique,
  }
end
