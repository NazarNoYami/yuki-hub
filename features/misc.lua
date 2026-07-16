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

-- Click Scanner
local clickScanLogs = {"=== Click Scanner ==="}
local clickScanOn = false
local clickScanCon = nil

US:Toggle({ Title = "Click Scanner", Desc = "Record what GUI you click during minigame", Callback = function(s)
    clickScanOn = s
    if s then
        table.insert(clickScanLogs, "--- Started ---")
        table.insert(clickScanLogs, "Click the skill check button manually to see what it is!")
        if clickScanCon then clickScanCon:Disconnect() end
        local wasDown = false
        clickScanCon = YH.RunService.RenderStepped:Connect(function()
            local down = YH.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            if down and not wasDown then
                local x = YH.Mouse.X
                local y = YH.Mouse.Y
                table.insert(clickScanLogs, "--- Click " .. string.format("%.0f,%.0f", x, y) .. " ---")
                local hit = {}
                for _, gui in pairs({game:GetService("CoreGui"), YH.LocalPlayer:FindFirstChildOfClass("PlayerGui")}) do
                    if not gui then continue end
                    for _, sg in pairs(gui:GetChildren()) do
                        if not sg:IsA("ScreenGui") or not sg.Enabled then continue end
                        for _, v in pairs(sg:GetDescendants()) do
                            if v:IsA("GuiObject") and v.Visible then
                                local ok, pos, size = pcall(function() return v.AbsolutePosition, v.AbsoluteSize end)
                                if ok and pos and size and size.X > 0 and size.Y > 0 then
                                    if x >= pos.X and x <= pos.X + size.X and y >= pos.Y and y <= pos.Y + size.Y then
                                        table.insert(hit, v)
                                    end
                                end
                            end
                        end
                    end
                end
                if #hit > 0 then
                    for _, v in pairs(hit) do
                        table.insert(clickScanLogs, "  [HIT] " .. v:GetFullName() .. " (" .. v.ClassName .. ")")
                        local sg = v:FindFirstAncestorOfClass("ScreenGui")
                        if sg then
                            table.insert(clickScanLogs, "    Gui: " .. sg.Name)
                            table.insert(clickScanLogs, "    Children:")
                            for _, c in pairs(sg:GetChildren()) do
                                local info = c.Name .. " (" .. c.ClassName .. ")"
                                local vis = pcall(function() return c.Visible end) and tostring(c.Visible) or "?"
                                table.insert(clickScanLogs, "      " .. info .. " vis=" .. vis)
                            end
                        end
                    end
                else
                    table.insert(clickScanLogs, "  No GUI hit")
                end
            end
            wasDown = down
        end)
    else
        if clickScanCon then clickScanCon:Disconnect(); clickScanCon = nil end
        table.insert(clickScanLogs, "--- Stopped ---")
        local ok, err = pcall(function() writefile("yuki_click_scan_" .. tostring(math.floor(tick())) .. ".txt", table.concat(clickScanLogs, "\n")) end)
        if ok then warn("Click scan saved to file!") else warn("writefile failed: " .. tostring(err)) end
    end
end })

-- Rotate Scanner
local scanLogs = {"=== Rotate Scanner ==="}
local scanRunning = false
local scanCon = nil
local scanLastRot = {}

US:Space()
US:Toggle({ Title = "Rotate Scanner", Desc = "Record rotating GUI elements", Callback = function(s)
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
        if ok then warn("Rotate scan saved to file") else warn("writefile failed: " .. tostring(err)) end
    end
end })
US:Space()
US:Button({ Title = "Copy Click Log", Callback = function()
    local ok, err = pcall(function() setclipboard(table.concat(clickScanLogs, "\n")) end)
    if ok then warn("Click log copied!") else warn("setclipboard failed: " .. tostring(err)) end
end })

-- Auto Skill Check state
local asSG, asLine, asGoal, asState, asPrevRot = nil, nil, nil, 0, nil

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
        if not asSG or not asSG.Parent then
            if asSG then warn("[ASC] Minigame GUI hilang") end
            asSG = nil; asState = 0; asPrevRot = nil
            local plrGui = YH.LocalPlayer:FindFirstChildOfClass("PlayerGui")
            for _, gui in pairs({game:GetService("CoreGui"), plrGui}) do
                if not gui then continue end
                asSG = gui:FindFirstChild("SkillCheckPromptGui", false)
                if asSG then
                    warn("[ASC] Minigame terdeteksi!")
                    -- Print full structure for debugging
                    for _, v in pairs(asSG:GetDescendants()) do
                        if v:IsA("GuiObject") then
                            warn("  " .. v:GetFullName() .. " (" .. v.ClassName .. ")")
                        end
                    end
                end
            end
        end
        if asSG and asSG.Enabled then
            if not asLine or not asLine.Parent then
                asLine = asSG:FindFirstChild("Line", true)
                if asLine then warn("[ASC] Jarum (Line) ditemukan cls=" .. asLine.ClassName) end
            end
            if not asGoal or not asGoal.Parent then
                asGoal = asSG:FindFirstChild("Goal", true)
                if asGoal then warn("[ASC] Target (Goal) ditemukan cls=" .. asGoal.ClassName) end
            end
            if asLine and asGoal and asGoal.Rotation ~= 0 then
                local lRot = asLine.Rotation % 360
                local gRot = asGoal.Rotation
                local diff = math.min(math.abs(lRot - gRot), math.abs(lRot - gRot - 360), math.abs(lRot - gRot + 360))
                local inZone = diff < 30
                if not inZone and asPrevRot then
                    local function between(a, b, t) if a <= b then return t >= a and t <= b else return t >= a or t <= b end end
                    inZone = between(asPrevRot, lRot, gRot)
                end
                if inZone then
                    if asState == 0 then
                        asState = 1
                        warn("[ASC] CLICK! Line=" .. string.format("%.1f", lRot) .. " Goal=" .. string.format("%.1f", gRot))
                        -- Jump method (most common for DBD skill checks)
                        if YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then
                            YH.LocalPlayer.Character.Humanoid.Jump = true
                            warn("[ASC] Jump triggered")
                        end
                        -- ContextActionService
                        pcall(function()
                            local CAS = game:GetService("ContextActionService")
                            for _, name in pairs({"SkillCheck","skillCheck","Generator","generator","Interact","Action","Use","Repair","E"}) do
                                local ok = pcall(function() CAS:CallFunction(name, Enum.UserInputType.Keyboard, Enum.KeyCode.Space) end)
                                if ok then warn("[ASC] CAS fired: " .. name) end
                            end
                        end)
                        -- Fire Activated on all GuiObjects
                        for _, v in pairs(asSG:GetDescendants()) do
                            if v:IsA("GuiObject") then
                                pcall(function() v.Activated:Fire() end)
                            end
                        end
                        -- VirtualInputManager at GUI center + screen center
                        local pos = asSG.AbsolutePosition + asSG.AbsoluteSize / 2
                        local vs = YH.Camera.ViewportSize
                        YH.VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        YH.VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                        YH.VirtualInputManager:SendMouseButtonEvent(vs.X/2, vs.Y/2, 0, true, game, 1)
                        YH.VirtualInputManager:SendMouseButtonEvent(vs.X/2, vs.Y/2, 0, false, game, 1)
                        -- Space + E keys
                        YH.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        YH.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                        YH.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        YH.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                        -- mouse1click
                        pcall(mouse1click)
                        warn("[ASC] All methods fired")
                        asState = 2
                    end
                elseif diff > 40 then
                    if asState ~= 0 then warn("[ASC] Selesai, reset") end
                    asState = 0
                end
                asPrevRot = lRot
            else
                if asState ~= 0 then warn("[ASC] Minigame selesai (goal=0)") end
                asState = 0; asPrevRot = nil
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
