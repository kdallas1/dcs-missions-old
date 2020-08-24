dofile(baseDir .. "Horus/Source/Test/TestMission05.lua")
dofile(baseDir .. "Horus/Source/Test/TestMission06.lua")
dofile(baseDir .. "Horus/Source/Test/TestMission07.lua")
dofile(baseDir .. "Horus/Source/Test/TestMission08.lua")
dofile(baseDir .. "Horus/Source/Test/TestMission09.lua")

function Test_Horus()
  RunTests {
    "Horus",
    Test_Mission05,
    Test_Mission06,
    Test_Mission07,
    Test_Mission08,
    Test_Mission09,
  }
end
