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
US:Space()

-- Auto Skill Check
US:Toggle({ Title = "Auto Skill Check", Desc = "Auto-complete generator minigame", Callback = function(s) YH.asOn = s end })
US:Space()

-- Minigame Scanner
local scanLogs = {"=== Minigame Scanner ==="}
local scanRunning = false
local scanCon = nil
local scanLastRot = {}

US:Toggle({ Title = "Scanner", Desc = "Record rotating GUI elements", Callback = function(s)
    scanRunning = s
    if s then
        table.insert(scanLogs, "--- Started ---")
        if scanCon then scanCon:Disconnect() end
        scanCon = YH.RunService.Heartbeat:Connect(function()
            for _, gui in pairs({game:GetService("CoreGui"), YH.LocalPlayer:FindFirstChildOfClass("PlayerGui")}) do
                if not gui then continue end
                for _, sg in pairs(gui:GetChildren()) do
                    if not sg:IsA("ScreenGui") or not sg.Enabled then continue end
                    for _, v in pairs(sg:GetDescendants()) do
                        if not v:IsA("GuiObject") then continue end
                        local ok, rot = pcall(function() return v.Rotation end)
                        if not ok then continue end
                        local key = v:GetFullName()
                        local prev = scanLastRot[key]
                        if prev and prev ~= rot and math.abs(rot - prev) > 0.5 and math.abs(rot - prev) < 180 then
                            table.insert(scanLogs, "[ROT] " .. v.Name .. " rot=" .. string.format("%.1f", rot) .. " (" .. sg.Name .. ")")
                        end
                        scanLastRot[key] = rot
                    end
                end
            end
        end)
    else
        if scanCon then scanCon:Disconnect(); scanCon = nil end
        table.insert(scanLogs, "--- Stopped ---")
        local ok, err = pcall(function() writefile("yuki_scan_" .. tostring(math.floor(tick())) .. ".txt", table.concat(scanLogs, "\n")) end)
        if ok then warn("Scanner saved to file") else warn("writefile failed: " .. tostring(err)) end
    end
end })
US:Space()
US:Button({ Title = "Copy Scan Log", Callback = function()
    local ok, err = pcall(function() setclipboard(table.concat(scanLogs, "\n")) end)
    if ok then warn("Scan log copied!") else warn("setclipboard failed: " .. tostring(err)) end
end })

-- Auto Skill Check state
local asNeedle, asState

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
    -- Speedhack
    if YH.spdOn and YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then
        YH.LocalPlayer.Character.Humanoid.WalkSpeed = YH.spdVal or 32
    end
    -- Sprint
    if YH.sprintOn and YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then
        local sh = YH.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or YH.UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        YH.LocalPlayer.Character.Humanoid.WalkSpeed = sh and (16 * (YH.sprintBoost or 1.05)) or 16
    end
    -- Noclip
    if YH.noclipOn and YH.LocalPlayer.Character then
        for _, p in pairs(YH.LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
    -- Auto Skill Check
    if YH.asOn then
        if not asNeedle or not asNeedle.Parent then
            asNeedle = nil; asState = 0
            local plrGui = YH.LocalPlayer:FindFirstChildOfClass("PlayerGui")
            for _, gui in pairs({game:GetService("CoreGui"), plrGui}) do
                if not gui then continue end
                for _, sg in pairs(gui:GetChildren()) do
                    if sg:IsA("ScreenGui") and sg.Enabled then
                        for _, v in pairs(sg:GetDescendants()) do
                            local n = v.Name:lower()
                            if (v:IsA("Frame") or v:IsA("ImageLabel")) and (n:find("needle") or n:find("arrow") or n:find("indicator") or n:find("rotate")) then
                                asNeedle = v; break
                            end
                        end
                    end
                    if asNeedle then break end
                end
                if asNeedle then break end
            end
        end
        if asNeedle then
            local rot = asNeedle.Rotation
            if asState == 0 and math.abs(rot) < 5 then
                asState = 1
                local pf = asNeedle:FindFirstAncestorOfClass("Frame") or asNeedle.Parent
                if pf:IsA("GuiObject") then
                    local pos = pf.AbsolutePosition + pf.AbsoluteSize / 2
                    YH.VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                end
            elseif asState == 1 then
                asState = 2
                local pf = asNeedle:FindFirstAncestorOfClass("Frame") or asNeedle.Parent
                if pf:IsA("GuiObject") then
                    local pos = pf.AbsolutePosition + pf.AbsoluteSize / 2
                    YH.VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                end
            elseif math.abs(rot) > 10 then
                asState = 0
            end
        end
    end
    -- Crosshair
    if YH.chOn then
        local cx = YH.Camera.ViewportSize.X / 2
        local cy = YH.Camera.ViewportSize.Y / 2
        local len = YH.chLen
        local w = YH.chW
        for i = 1, 4 do chLines[i].Visible = true; chLines[i].Thickness = w end
        chLines[1].From = Vector2.new(cx, cy - len); chLines[1].To = Vector2.new(cx, cy - 2)
        chLines[2].From = Vector2.new(cx, cy + 2); chLines[2].To = Vector2.new(cx, cy + len)
        chLines[3].From = Vector2.new(cx - len, cy); chLines[3].To = Vector2.new(cx - 2, cy)
        chLines[4].From = Vector2.new(cx + 2, cy); chLines[4].To = Vector2.new(cx + len, cy)
    else
        for i = 1, 4 do chLines[i].Visible = false end
    end
    -- Stretched Res
    if YH.stOn then
        YH.Camera.ViewportSize = Vector2.new(YH.Camera.ViewportSize.X * (YH.stVal / 100), YH.Camera.ViewportSize.Y)
    end
end)

-- Flashlight
YH.RunService.Heartbeat:Connect(function()
    if YH.flOn then
        if not YH.flObj then
            YH.flObj = Instance.new("SpotLight")
            YH.flObj.Brightness = 2; YH.flObj.Range = 60; YH.flObj.Angle = 90
            YH.flObj.Face = Enum.NormalId.Front; YH.flObj.Parent = YH.Camera
        end
        YH.flObj.Enabled = true
    elseif YH.flObj then
        YH.flObj.Enabled = false
    end
end)