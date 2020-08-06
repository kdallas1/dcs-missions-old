dofile(baseDir .. "KD/Test/TestSpawn.lua")

function RunTests(list)
  for i = 1, #list do
    local test = list[i]
    env.info("Test: Start #" .. i .. " of " .. #list)
    test()
    env.info("Test: Passed")
  end
end

function TestAssert(condition, errorString)
  if not condition then error(errorString) end
end

function Test()
  env.info("Test: Running")  
  env.setErrorMessageBoxEnabled(true)
  
  RunTests {
    Test_Spawn
  }
  
  env.setErrorMessageBoxEnabled(false)
  env.info("Test: Finished")
end
