-- HUD Tab
local YH = _G.YH
local T = YH.Tabs.HUD
local S = T:Section({ Title = "Essential HUD" })
local hudOn = false; local hudFPS = true; local hudPing = true; local hudKiller = true
local hudFrames = 0; local hudTime = 0; local hudFpsVal = 0; local hudGui = nil
S:Toggle({ Title = "Enable HUD", Desc = "FPS, Ping, Killer info", Callback = function(s) hudOn = s end })
S:Space()
S:Toggle({ Title = "Show FPS", Default = true, Callback = function(s) hudFPS = s end })
S:Space()
S:Toggle({ Title = "Show Ping", Default = true, Callback = function(s) hudPing = s end })
S:Space()
S:Toggle({ Title = "Show Killer", Default = true, Callback = function(s) hudKiller = s end })

-- HUD loop
YH.RunService.RenderStepped:Connect(function()
    hudFrames = hudFrames + 1; hudTime = hudTime + 0.1
    if hudTime >= 1 then hudFpsVal = math.floor(hudFrames / hudTime); hudFrames = 0; hudTime = 0 end
    if hudOn then
        -- Simple HUD text
    end
end)