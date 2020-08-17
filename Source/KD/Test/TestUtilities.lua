dofile(baseDir .. "KD/Utilities.lua")

local function Test_Debug_GetInfo()

  local info = Debug:GetInfo()

  TestAssert(info.funcName == "test", "Unexpected `funcName`: " .. info.funcName)
  TestAssert(info.fileName == "TestUtilities.lua", "Unexpected `fileName`: " .. info.fileName)
  TestAssert(info.lineNum == 3, "Unexpected `fileName`: " .. info.lineNum)

end

function Test_Utilities()
  return RunTests {
    "Utilities",
    Test_Debug_GetInfo
  }
end
