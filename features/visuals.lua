-- Visuals Tab
local YH = _G.YH
local T = YH.Tabs.Visuals

-- Bright Mode
local BS = T:Section({ Title = "Bright Mode" })
local brOrig = {}
BS:Toggle({ Title = "Bright Mode", Desc = "Auto-reapplies on map change", Callback = function(s)
    YH.brightOn = s
    if s then
        brOrig = {YH.Lighting.Ambient,YH.Lighting.Brightness,YH.Lighting.ClockTime,YH.Lighting.FogEnd,YH.Lighting.GlobalShadows,YH.Lighting.OutdoorAmbient,YH.Lighting.ColorShift_Top,YH.Lighting.ColorShift_Bottom}
    else
        YH.Lighting.Ambient=brOrig[1];YH.Lighting.Brightness=brOrig[2];YH.Lighting.ClockTime=brOrig[3];YH.Lighting.FogEnd=brOrig[4];YH.Lighting.GlobalShadows=brOrig[5];YH.Lighting.OutdoorAmbient=brOrig[6];YH.Lighting.ColorShift_Top=brOrig[7];YH.Lighting.ColorShift_Bottom=brOrig[8]
    end
end })
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
local fgOrig = {}
FG:Toggle({ Title = "Custom Fog", Callback = function(s)
    YH.fogOn = s
    if s then fgOrig = {YH.Lighting.FogStart,YH.Lighting.FogEnd} else YH.Lighting.FogStart=fgOrig[1];YH.Lighting.FogEnd=fgOrig[2] end
end })
FG:Space()
FG:Slider({ Title = "Fog Start", Width = 200, Value = { Min=0, Max=500, Default=0 }, Step = 1, Callback = function(v) YH.fogS = v end })
FG:Space()
FG:Slider({ Title = "Fog End", Width = 200, Value = { Min=100, Max=2000, Default=1000 }, Step = 10, Callback = function(v) YH.fogE = v end })
FG:Space()

-- Skybox
local SK = T:Section({ Title = "Skybox" })
local skOrig = {}
SK:Toggle({ Title = "Skybox", Callback = function(s)
    YH.skyOn = s
    if s then skOrig={YH.Lighting.Brightness,YH.Lighting.ExposureCompensation} else YH.Lighting.Brightness=skOrig[1];YH.Lighting.ExposureCompensation=skOrig[2] end
end })
SK:Space()
SK:Slider({ Title = "Brightness", Width = 200, Value = { Min=0, Max=100, Default=50 }, Step = 1, Callback = function(v) YH.skyB = v end })
SK:Space()
SK:Slider({ Title = "Exposure", Width = 200, Value = { Min=0, Max=100, Default=50 }, Step = 1, Callback = function(v) YH.skyE = v end })

-- Render loop
YH.RunService.RenderStepped:Connect(function()
    if YH.brightOn then
        YH.Lighting.Ambient=Color3.fromRGB(255,255,255);YH.Lighting.Brightness=(YH.brightLevel or 1)*2
        YH.Lighting.ClockTime=12;YH.Lighting.FogEnd=100000;YH.Lighting.GlobalShadows=false
        YH.Lighting.OutdoorAmbient=Color3.fromRGB(255,255,255);YH.Lighting.ColorShift_Top=Color3.fromRGB(255,255,255);YH.Lighting.ColorShift_Bottom=Color3.fromRGB(255,255,255)
    end
    if YH.fovOn then YH.Camera.FieldOfView=YH.fovVal or 70 end
    if YH.fogOn then YH.Lighting.FogStart=YH.fogS or 0;YH.Lighting.FogEnd=YH.fogE or 1000 end
    if YH.skyOn and not YH.brightOn then YH.Lighting.Brightness=(YH.skyB or 50)/10;YH.Lighting.ExposureCompensation=(YH.skyE or 50)/10 end
end)