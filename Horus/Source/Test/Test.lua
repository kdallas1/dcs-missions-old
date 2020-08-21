dofile(baseDir .. "Horus/Source/Test/TestMission05.lua")
dofile(baseDir .. "Horus/Source/Test/TestMission06.lua")

function Test_Horus()
  RunTests {
    "Horus",
    Test_Mission05,
    Test_Mission06,
  }
end
