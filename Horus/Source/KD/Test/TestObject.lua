dofile(baseDir .. "KD/Object.lua")

local function Test_CreateClass_ObjectsAreUnique()

  TestChild1 = { }
  TestChild2 = { }
  TestChild3 = createClass(TestChild2, TestChild1, Object)
  local c1 = TestChild3:New()
  local c2 = TestChild3:New()
  
  c1.string = "foo"
  c2.string = "bar"
  
  TestAssert(c1.string ~= c2.string, "String values are shared")
  
end

local function Test_CreateClass_ObjectsInherit()

  TestChild1 = { foo = "test" }
  TestChild1 = createClass(TestChild1, Object)
  local c = TestChild1:New()
  
  TestAssert(c.foo, "Expected field from Child1")
  TestAssert(c.foo == "test", "Expected string from Child1")
  
end

local function Test_CreateClass_ObjectsInheritWidely()

  TestChild1 = { foo = "test" }
  TestChild2 = { bar = "test" }
  TestChild3 = { baz = "test" }
  TestChild3 = createClass(TestChild3, TestChild2, TestChild1, Object)
  local c = TestChild3:New()
  
  TestAssert(c.foo == "test", "Expected string from Child1")
  TestAssert(c.bar == "test", "Expected string from Child2")
  TestAssert(c.baz == "test", "Expected string from Child3")
  
end

local function Test_CreateClass_ObjectsInheritDeeply()

  TestChild1 = { foo = "test" }
  TestChild1 = createClass(TestChild1, Object)
  
  TestChild2 = { bar = "test" }
  TestChild2 = createClass(TestChild2, TestChild1)
  
  TestChild3 = { baz = "test" }
  TestChild3 = createClass(TestChild3, TestChild2)
  
  local c = TestChild3:New()
  
  TestAssert(c.foo == "test", "Expected string from Child1")
  TestAssert(c.bar == "test", "Expected string from Child2")
  TestAssert(c.baz == "test", "Expected string from Child3")
  
end

local function Test_CreateClass_ArgTypeError()

  TestClass = { foo = "test" }
  ok, result = pcall(function() createClass(TestClass, "foo", TestClass) end)
  
  TestAssert(not ok, "Non-table args for createClass shouldn't work")
  
end

function Test_Object()
  return RunTests {
    "Object",
    Test_CreateClass_ObjectsInherit,
    Test_CreateClass_ObjectsInheritWidely,
    Test_CreateClass_ObjectsInheritDeeply,
    Test_CreateClass_ObjectsAreUnique,
    Test_CreateClass_ArgTypeError
  }
end
