-- Visuals Tab
local YH = _G.YH
local T = YH.Tabs.Visuals

-- Bright Mode
local BS = T:Section({ Title = "Bright Mode" })
BS:Toggle({ Title = "Bright Mode", Desc = "Auto-reapplies on map change", Callback = function(s) YH.brightOn = s end })
BS:Space()
BS:Slider({ Title = "Brightness Level", Width = 200, Value = { Min=0.5, Max=5, Default=1 }, Step = 0.1, Callback = function(v) YH.brightLevel = v end })
BS:Space()

-- Custom FOV
local FS = T:Section({ Title = "Custom FOV" })
FS:Toggle({ Title = "Custom FOV", Callback = function(s) YH.fovOn = s; YH.Camera.FieldOfView = s and YH.fovVal or YH.origFOV end })
FS:Space()
FS:Slider({ Title = "FOV Value", Width = 200, Value = { Min=30, Max=120, Default=70 }, Step = 1, Callback = function(v) YH.fovVal = v; if YH.fovOn then YH.Camera.FieldOfView = v end end })
FS:Space()

-- Custom Fog
local FG = T:Section({ Title = "Custom Fog" })
FG:Toggle({ Title = "Custom Fog", Callback = function(s) YH.fogOn = s end })
FG:Space()
FG:Slider({ Title = "Fog Start", Width = 200, Value = { Min=0, Max=500, Default=0 }, Step = 1, Callback = function(v) YH.fogS = v end })
FG:Space()
FG:Slider({ Title = "Fog End", Width = 200, Value = { Min=100, Max=2000, Default=1000 }, Step = 10, Callback = function(v) YH.fogE = v end })
FG:Space()

-- Skybox
local SK = T:Section({ Title = "Skybox" })
SK:Toggle({ Title = "Skybox", Callback = function(s) YH.skyOn = s end })
SK:Space()
SK:Slider({ Title = "Brightness", Width = 200, Value = { Min=0, Max=100, Default=50 }, Step = 1, Callback = function(v) YH.skyB = v end })
SK:Space()
SK:Slider({ Title = "Exposure", Width = 200, Value = { Min=0, Max=100, Default=50 }, Step = 1, Callback = function(v) YH.skyE = v end })