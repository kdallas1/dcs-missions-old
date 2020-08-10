dofile(baseDir .. "KD/Object.lua")

local function Test_CreateClass_ObjectsAreUnique()

  local TestChild1 = { className = "TestChild1" }
  local TestChild2 = { className = "TestChild2" }
  local TestChild3 = createClass(TestChild2, TestChild1, Object)
  local c1 = TestChild3:New()
  local c2 = TestChild3:New()
  
  c1.string = "foo"
  c2.string = "bar"
  
  TestAssert(c1.string ~= c2.string, "String values are shared")
  
end

local function Test_CreateClass_ObjectsInherit()

  local TestChild1 = { className = "TestChild1", foo = "test" }
  local TestChild1 = createClass(TestChild1, Object)
  local c = TestChild1:New()
  
  TestAssert(c.foo, "Expected field from Child1")
  TestAssert(c.foo == "test", "Expected string from Child1")
  
end

local function Test_CreateClass_ObjectsInheritWidely()

  local TestChild1 = { className = "TestChild1", foo = "test" }
  local TestChild2 = { className = "TestChild2", bar = "test" }
  local TestChild3 = { className = "TestChild3", baz = "test" }
  local TestChild3 = createClass(TestChild3, TestChild2, TestChild1, Object)
  local c = TestChild3:New()
  
  TestAssert(c.foo == "test", "Expected string from Child1")
  TestAssert(c.bar == "test", "Expected string from Child2")
  TestAssert(c.baz == "test", "Expected string from Child3")
  
end

local function Test_CreateClass_ObjectsInheritDeeply()

  local TestChild1 = { className = "TestChild1", foo = "test" }
  local TestChild1 = createClass(TestChild1, Object)
  
  local TestChild2 = { className = "TestChild2", bar = "test" }
  local TestChild2 = createClass(TestChild2, TestChild1)
  
  local TestChild3 = { className = "TestChild3", baz = "test" }
  local TestChild3 = createClass(TestChild3, TestChild2)
  
  local c = TestChild3:New()
  
  TestAssert(c.foo == "test", "Expected string from Child1")
  TestAssert(c.bar == "test", "Expected string from Child2")
  TestAssert(c.baz == "test", "Expected string from Child3")
  
end

local function Test_CreateClass_ArgTypeError()

  local TestClass = { className = "TestClass", foo = "test" }
  ok, result = pcall(function() createClass(TestClass, "foo", TestClass) end)
  
  TestAssert(not ok, "Non-table args for createClass shouldn't work")
  
end

local function Test_New_ConstructorsCalled()
  
  local calledCtor1 = false
  local TestChild1 = {
    className = "TestChild1",
    TestChild1 = function() calledCtor1 = true end
  }
  local TestChild1 = createClass(TestChild1, Object)
  
  local calledCtor2 = false
  local TestChild2 = {
    className = "TestChild2",
    TestChild2 = function() calledCtor2 = true end
  }
  function TestChild2:TestChild2()
    calledCtor2 = true
  end
  local TestChild2 = createClass(TestChild2, TestChild1)
  
  local calledCtor3 = false
  local TestChild3 = {
    className = "TestChild3",
    TestChild3 = function() calledCtor3 = true end
  }
  local TestChild3 = createClass(TestChild3, TestChild2)
  
  local c = TestChild3:New()
  
  TestAssert(calledCtor1, "Expected ctor call for TestChild1")
  TestAssert(calledCtor2, "Expected ctor call for TestChild2")
  TestAssert(calledCtor3, "Expected ctor call for TestChild3")
  
end

local function Test_CreateClass_CtorCallOrder()

  local TestChild1 = { className = "TestChild1" }
  local TestChild2 = { className = "TestChild2" }
  
  local callOrder = {}
  
  function Object:Object()
    callOrder[#callOrder + 1] = "Object"
  end
  
  function TestChild1:TestChild1()
    callOrder[#callOrder + 1] = "TestChild1"
  end
  
  function TestChild2:TestChild2()
    callOrder[#callOrder + 1] = "TestChild2"
  end
  
  TestChild1 = createClass(Object, TestChild1)
  TestChild2 = createClass(TestChild1, TestChild2)
  
  TestChild2:New()
  
  TestAssert(#callOrder == 3, "Expected 3 ctor calls, but got " .. #callOrder)
  TestAssert(callOrder[1] == "Object", "Expected Object ctor to be called 1st, but was " .. callOrder[1])
  TestAssert(callOrder[2] == "TestChild1", "Expected TestChild1 ctor to be called 2nd, but was " .. callOrder[2])
  TestAssert(callOrder[3] == "TestChild2", "Expected TestChild2 ctor to be called 3rd, but was " .. callOrder[3])
  
end

function Test_Object()
  return RunTests {
    "Object",
    Test_CreateClass_ObjectsInherit,
    Test_CreateClass_ObjectsInheritWidely,
    Test_CreateClass_ObjectsInheritDeeply,
    Test_CreateClass_ObjectsAreUnique,
    Test_CreateClass_ArgTypeError,
    Test_CreateClass_CtorCallOrder,
    Test_New_ConstructorsCalled,
  }
end
