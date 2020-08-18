dofile(baseDir .. "Horus/Source/Test/TestMission05.lua")

function Test_Horus()
  RunTests {
    "Horus",
    Test_Mission05
  }
end
