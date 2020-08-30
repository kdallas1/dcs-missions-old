dofile(baseDir .. "Horus/Test/TestMission01.lua")
dofile(baseDir .. "Horus/Test/TestMission02.lua")
dofile(baseDir .. "Horus/Test/TestMission03.lua")
dofile(baseDir .. "Horus/Test/TestMission04.lua")
dofile(baseDir .. "Horus/Test/TestMission05.lua")
dofile(baseDir .. "Horus/Test/TestMission06.lua")
dofile(baseDir .. "Horus/Test/TestMission07.lua")
dofile(baseDir .. "Horus/Test/TestMission08.lua")
dofile(baseDir .. "Horus/Test/TestMission09.lua")

function Test_Horus()
  RunTests {
    "Horus",
    Test_Mission01,
    Test_Mission02,
    Test_Mission03,
    Test_Mission04,
    Test_Mission05,
    Test_Mission06,
    Test_Mission07,
    Test_Mission08,
    Test_Mission09,
  }
end
