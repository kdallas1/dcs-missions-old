baseDir = [[C:\Projects\kdallas1\dcs-missions\Source\]]

dofile(baseDir .. "KD/Test/Test.lua")
dofile(baseDir .. "Horus/Test/Test.lua")

if (Test { Test_Horus }) then

  dofile(baseDir .. "Horus/Mission05.lua")
  Mission05:New():Start()
  
end
