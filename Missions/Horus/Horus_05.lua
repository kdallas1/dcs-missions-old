baseDir = [[C:\Projects\kdallas1\dcs-missions\]]

dofile(baseDir .. "KD/Test/Test.lua")
dofile(baseDir .. "Horus/Source/Test/Test.lua")

if (Test { Test_Horus }) then

  dofile(baseDir .. "Horus/Source/Mission05.lua")
  Mission05:New():Start()
  
end
