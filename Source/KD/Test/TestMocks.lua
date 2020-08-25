dofile(baseDir .. "KD/Test/MockMoose.lua")

local function Test_MockMoose_TraceOn_MockSchedulerTraceOn()

  local moose = MockMoose:New({
    trace = { _traceOn = true, _traceLevel = 2 },
  })

  TestAssert(moose.scheduler.trace, "Mock Moose scheduler trace should be on")

end

function Test_Mocks()
  return RunTests {
    "Mocks",
    Test_MockMoose_TraceOn_MockSchedulerTraceOn
  }
end
