-- Visuals Tab
local YH = _G.YH
local T = YH.Tabs.Visuals

-- Bright Mode
local BS = T:Section({ Title = "Bright Mode" })
local brightOn = false; local brightLevel = 1
BS:Toggle({ Title = "Bright Mode", Desc = "Auto-reapplies on map change", Callback = function(s) brightOn = s end })
BS:Space()
BS:Slider({ Title = "Brightness Level", Width = 200, Value = { Min=0.5, Max=5, Default=1 }, Step = 0.1, Callback = function(v) brightLevel = v end })
BS:Space()

-- Custom FOV
local FS = T:Section({ Title = "Custom FOV" })
local fovOn = false; local fovVal = 70; local origFOV = YH.Camera.FieldOfView
FS:Toggle({ Title = "Custom FOV", Callback = function(s) fovOn = s; YH.Camera.FieldOfView = s and fovVal or origFOV end })
FS:Space()
FS:Slider({ Title = "FOV Value", Width = 200, Value = { Min=30, Max=120, Default=70 }, Step = 1, Callback = function(v) fovVal = v; if fovOn then YH.Camera.FieldOfView = v end end })
FS:Space()

-- Custom Fog
local FG = T:Section({ Title = "Custom Fog" })
local fogOn = false; local fogS = 0; local fogE = 1000
FG:Toggle({ Title = "Custom Fog", Callback = function(s) fogOn = s end })
FG:Space()
FG:Slider({ Title = "Fog Start", Width = 200, Value = { Min=0, Max=500, Default=0 }, Step = 1, Callback = function(v) fogS = v end })
FG:Space()
FG:Slider({ Title = "Fog End", Width = 200, Value = { Min=100, Max=2000, Default=1000 }, Step = 10, Callback = function(v) fogE = v end })
FG:Space()

-- Skybox
local SK = T:Section({ Title = "Skybox" })
local skyOn = false; local skyB = 50; local skyE = 50
SK:Toggle({ Title = "Skybox", Callback = function(s) skyOn = s end })
SK:Space()
SK:Slider({ Title = "Brightness", Width = 200, Value = { Min=0, Max=100, Default=50 }, Step = 1, Callback = function(v) skyB = v end })
SK:Space()
SK:Slider({ Title = "Exposure", Width = 200, Value = { Min=0, Max=100, Default=50 }, Step = 1, Callback = function(v) skyE = v end })

-- Visuals loop
YH.RunService.RenderStepped:Connect(function()
    if brightOn then
        local b = brightLevel * 2
        YH.Lighting.Ambient = Color3.fromRGB(255,255,255); YH.Lighting.Brightness = b; YH.Lighting.ClockTime = 12
        YH.Lighting.FogEnd = 100000; YH.Lighting.GlobalShadows = false; YH.Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        YH.Lighting.ColorShift_Top = Color3.fromRGB(255,255,255); YH.Lighting.ColorShift_Bottom = Color3.fromRGB(255,255,255)
    end
    if fogOn then YH.Lighting.FogStart = fogS; YH.Lighting.FogEnd = fogE end
    if skyOn then YH.Lighting.Brightness = skyB / 10; YH.Lighting.ExposureCompensation = skyE / 10 end
end)