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

function Test_Object()
  return RunTests {
    Test_ObjectsAreUnique
  }
end
