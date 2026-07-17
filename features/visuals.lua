local YH = _G.YH
local T = YH.Tabs.Visuals
local Lighting = YH.Lighting
local original = {
    Ambient = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ExposureCompensation = Lighting.ExposureCompensation,
}

local function restoreLighting()
    for property, value in pairs(original) do Lighting[property] = value end
    local camera = YH.GetCamera()
    if camera then camera.FieldOfView = YH.originalFOV or 70 end
end
YH.originalFOV = YH.GetCamera() and YH.GetCamera().FieldOfView or 70
YH.OnCleanup(restoreLighting)

local lighting = T:Section({Title = "Lighting"})
lighting:Toggle({Title = "Full Bright", Callback = function(value) YH.brightOn = value; if not value then restoreLighting() end end})
lighting:Space()
lighting:Slider({Title = "Brightness", Width = 200, Value = {Min = 0.5, Max = 5, Default = 1}, Step = 0.1, Callback = function(value) YH.brightLevel = value end})
lighting:Space()
lighting:Toggle({Title = "Custom Fog", Callback = function(value) YH.fogOn = value; if not value then Lighting.FogStart = original.FogStart; Lighting.FogEnd = original.FogEnd end end})
lighting:Space()
lighting:Slider({Title = "Fog Start", Width = 200, Value = {Min = 0, Max = 500, Default = 0}, Step = 1, Callback = function(value) YH.fogS = value end})
lighting:Space()
lighting:Slider({Title = "Fog End", Width = 200, Value = {Min = 100, Max = 5000, Default = 1000}, Step = 10, Callback = function(value) YH.fogE = value end})

local cameraSection = T:Section({Title = "Camera"})
cameraSection:Toggle({Title = "Custom FOV", Callback = function(value) YH.fovOn = value end})
cameraSection:Space()
cameraSection:Slider({Title = "Field of View", Width = 200, Value = {Min = 30, Max = 120, Default = 70}, Step = 1, Callback = function(value) YH.fovVal = value end})

YH.Connect(YH.RunService.RenderStepped, function()
    if YH.brightOn then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = YH.brightLevel * 2
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = false
    end
    if YH.fogOn then Lighting.FogStart = YH.fogS; Lighting.FogEnd = YH.fogE end
    local camera = YH.GetCamera()
    if camera then camera.FieldOfView = YH.fovOn and YH.fovVal or YH.originalFOV end
end)
