dofile(baseDir .. "KD/Test/TestSpawn.lua")

function RunTests(list)
  local pass = true
  for i = 1, #list do
    local test = list[i]
    local r = test()
    if not r then
      pass = false
    end
  end
  return pass
end

function Test()
  env.info("Test: Running")
  
  local pass = RunTests {
    Test_Spawn
  }
  
  if pass then
    env.info("Test: Passed")
  else
    env.error("Test: Failed", true)
  end
end
