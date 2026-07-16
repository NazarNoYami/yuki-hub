-- Misc Tab
local YH = _G.YH
local T = YH.Tabs.Misc

local MS = T:Section({ Title = "Movement" })
MS:Toggle({ Title = "Speedhack", Callback = function(s) YH.spdOn = s end })
MS:Space()
MS:Slider({ Title = "Speed Value", Width = 200, Value = { Min=16, Max=100, Default=32 }, Step = 1, Callback = function(v) YH.spdVal = v end })
MS:Space()
MS:Toggle({ Title = "Sprint Speed", Desc = "Faster while holding Shift", Callback = function(s) YH.sprintOn = s end })
MS:Space()
MS:Slider({ Title = "Sprint Boost", Width = 200, Value = { Min=1.0, Max=2.0, Default=1.05 }, Step = 0.05, Callback = function(v) YH.sprintBoost = v end })
MS:Space()
MS:Toggle({ Title = "Noclip", Desc = "Walk through walls", Callback = function(s) YH.noclipOn = s end })
MS:Space()

-- Utilities
local US = T:Section({ Title = "Utilities" })

-- Crosshair
US:Toggle({ Title = "Custom Crosshair", Callback = function(s) YH.chOn = s end })
US:Space()
US:Slider({ Title = "Crosshair Length", Width = 200, Value = { Min=5, Max=30, Default=10 }, Step = 1, Callback = function(v) YH.chLen = v end })
US:Space()
US:Slider({ Title = "Crosshair Width", Width = 200, Value = { Min=1, Max=8, Default=2 }, Step = 1, Callback = function(v) YH.chW = v end })
US:Space()

-- Flashlight
US:Toggle({ Title = "Flashlight", Callback = function(s) YH.flOn = s end })
US:Space()

-- Stretched Res
US:Toggle({ Title = "Stretched Res", Desc = "Wider field of view", Callback = function(s) YH.stOn = s end })
US:Space()
US:Slider({ Title = "Stretch Amount", Width = 200, Value = { Min=50, Max=200, Default=100 }, Step = 5, Callback = function(v) YH.stVal = v end })
US:Space()

-- Actions
US:Button({ Title = "Reset Character", Callback = function()
    if YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then
        YH.LocalPlayer.Character.Humanoid.Health = 0
    end
end})
US:Space()
US:Button({ Title = "Anti AFK", Desc = "Prevent auto-kick", Callback = function()
    if YH.afkConnected then return end
    YH.afkConnected = true
    YH.LocalPlayer.Idled:Connect(function()
        YH.VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.1)
        YH.VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
end})
US:Space()
US:Slider({ Title = "FPS Cap", Width = 200, Value = { Min=15, Max=360, Default=60 }, Step = 1, Callback = function(v) setfpscap(v) end})
US:Space()
US:Button({ Title = "Infinite Yield", Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end})

-- Crosshair drawing
local chLines = {}
for i = 1, 4 do
    chLines[i] = Drawing.new("Line")
    chLines[i].Thickness = 2
    chLines[i].Color = Color3.fromRGB(0, 255, 100)
    chLines[i].Transparency = 0.8
    chLines[i].Visible = false
end

YH.RunService.RenderStepped:Connect(function()
    -- Crosshair
    if YH.chOn then
        local cx = YH.Camera.ViewportSize.X / 2
        local cy = YH.Camera.ViewportSize.Y / 2
        local len = YH.chLen
        local w = YH.chW
        for i = 1, 4 do chLines[i].Visible = true; chLines[i].Thickness = w end
        -- Top
        chLines[1].From = Vector2.new(cx, cy - len)
        chLines[1].To = Vector2.new(cx, cy - 2)
        -- Bottom
        chLines[2].From = Vector2.new(cx, cy + 2)
        chLines[2].To = Vector2.new(cx, cy + len)
        -- Left
        chLines[3].From = Vector2.new(cx - len, cy)
        chLines[3].To = Vector2.new(cx - 2, cy)
        -- Right
        chLines[4].From = Vector2.new(cx + 2, cy)
        chLines[4].To = Vector2.new(cx + len, cy)
    else
        for i = 1, 4 do chLines[i].Visible = false end
    end

    -- Stretched Res
    if YH.stOn then
        YH.Camera.ViewportSize = Vector2.new(
            YH.Camera.ViewportSize.X * (YH.stVal / 100),
            YH.Camera.ViewportSize.Y
        )
    end
end)