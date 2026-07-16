-- Misc Tab
local YH = _G.YH
local T = YH.Tabs.Misc

local MS = T:Section({ Title = "Movement" })
local spdOn = false; local spdVal = 32
MS:Toggle({ Title = "Speedhack", Callback = function(s) spdOn = s end })
MS:Space()
MS:Slider({ Title = "Speed Value", Width = 200, Value = { Min=16, Max=100, Default=32 }, Step = 1, Callback = function(v) spdVal = v end })
MS:Space()

local sprintOn = false; local sprintBoost = 1.05; local sprinting = false
MS:Toggle({ Title = "Sprint Speed", Desc = "5% faster while sprinting", Callback = function(s) sprintOn = s end })
MS:Space()

local noclipOn = false
MS:Toggle({ Title = "Noclip", Desc = "Walk through walls", Callback = function(s) noclipOn = s end })
MS:Space()

-- Crosshair
local US = T:Section({ Title = "Utilities" })
local chOn = false; local chLen = 10; local chW = 2
US:Toggle({ Title = "Custom Crosshair", Callback = function(s) chOn = s end })
US:Space()
US:Slider({ Title = "Crosshair Length", Width = 200, Value = { Min=5, Max=30, Default=10 }, Step = 1, Callback = function(v) chLen = v end })
US:Space()
US:Slider({ Title = "Crosshair Width", Width = 200, Value = { Min=1, Max=8, Default=2 }, Step = 1, Callback = function(v) chW = v end })
US:Space()

-- Flashlight
local flOn = false; local flObj = nil
US:Toggle({ Title = "Flashlight", Callback = function(s) flOn = s end })
US:Space()

-- Stretched Res
local stOn = false; local stVal = 100
US:Toggle({ Title = "Stretched Res", Callback = function(s) stOn = s end })
US:Space()
US:Slider({ Title = "Stretch Value", Width = 200, Value = { Min=50, Max=200, Default=100 }, Step = 1, Callback = function(v) stVal = v end })
US:Space()

-- Actions
US:Button({ Title = "Reset Character", Callback = function()
    if YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then YH.LocalPlayer.Character.Humanoid.Health = 0 end
end})
US:Space()
US:Button({ Title = "Anti AFK", Callback = function()
    YH.LocalPlayer.Idled:Connect(function() YH.VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1); task.wait(0.1); YH.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1) end)
end})
US:Space()
US:Slider({ Title = "FPS Cap", Width = 200, Value = { Min=15, Max=360, Default=60 }, Step = 1, Callback = function(v) setfpscap(v) end})
US:Space()
US:Button({ Title = "Infinite Yield", Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end})

-- Misc loop
YH.RunService.RenderStepped:Connect(function()
    if spdOn and YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then
        YH.LocalPlayer.Character.Humanoid.WalkSpeed = spdVal
    end
    if noclipOn and YH.LocalPlayer.Character then
        for _, part in pairs(YH.LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
    if sprintOn and YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then
        sprinting = YH.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or YH.UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        YH.LocalPlayer.Character.Humanoid.WalkSpeed = sprinting and 16 * sprintBoost or 16
    end
    if flOn then
        if not flObj then flObj = Instance.new("SpotLight"); flObj.Brightness = 2; flObj.Range = 60; flObj.Angle = 90; flObj.Face = Enum.NormalId.Front; flObj.Parent = YH.Camera end
        flObj.Enabled = true
    elseif flObj then flObj.Enabled = false end
end)