baseDir = [[C:\Projects\kdallas1\dcs-missions\]]

dofile(baseDir .. "KD/Test/Test.lua")
dofile(baseDir .. "Horus/Source/Test/Test.lua")

if (Test { Test_Horus }) then

  dofile(baseDir .. "Horus/Source/Mission03.lua")
  Mission03:New():Start()
  
end
