dofile(baseDir .. "KD/Test/TestSpawn.lua")

function RunTests(list)
  local pass = true
  for i = 1, #list do
    local test = list[i]
    
    env.info("Test: Start " .. i)
    
    local noError, result = pcall(test)
    
    if noError then
      if result then
        env.info("Test: Passed")
      else
        pass = false
        env.error("Test: Failed")
      end
    else
      pass = false
      env.error("Test: Error: " .. result)
    end
  end
  return pass
end

function TestAssert(condition, errorString)
  if not condition then error(errorString) end
end

function Test()
  env.info("Test: Running")
  
  local pass = RunTests {
    Test_Spawn
  }
  
  if pass then
    env.info("Test: Finished")
    return true
  else
    env.error("Test: Failed", true)
    return false
  end
end
