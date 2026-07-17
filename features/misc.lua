local YH = _G.YH
local T = YH.Tabs.Misc

local utility = T:Section({Title = "Utility"})
utility:Toggle({Title = "Anti AFK", Callback = function(value) YH.antiAfkOn = value end})
utility:Space()
utility:Slider({Title = "FPS Cap", Width = 200, Value = {Min = 30, Max = 240, Default = 60}, Step = 10, Callback = function(value)
    if type(setfpscap) == "function" then setfpscap(value) end
end})
utility:Space()
utility:Button({Title = "Reset Character", Callback = function()
    local character = YH.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.Health = 0 end
end})
utility:Space()
utility:Button({Title = "Infinite Yield", Desc = "Pinned audited revision", Callback = function()
    local commit = "f43b55d282a33e5a009b20a2bedb5b527e4c9560"
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/" .. commit .. "/source"))()
end})

local crosshair = T:Section({Title = "Crosshair"})
crosshair:Toggle({Title = "Enable", Callback = function(value) YH.chOn = value end})
crosshair:Space()
crosshair:Slider({Title = "Length", Width = 200, Value = {Min = 5, Max = 30, Default = 10}, Step = 1, Callback = function(value) YH.chLen = value end})
crosshair:Space()
crosshair:Slider({Title = "Thickness", Width = 200, Value = {Min = 1, Max = 6, Default = 2}, Step = 1, Callback = function(value) YH.chW = value end})

local skill = T:Section({Title = "Skill Check"})
YH.skillTolerance = 18
YH.skillRecorded = nil
YH.skillRecording = false
skill:Button({Title = "Record Next Input", Desc = "Open a skill check, then press or click it once", Callback = function()
    YH.skillRecording = true
    warn("[Yuki] Skill input recorder armed")
end})
skill:Space()
skill:Button({Title = "Clear Recorded Input", Callback = function()
    YH.skillRecorded = nil
    YH.skillRecording = false
    warn("[Yuki] Recorded skill input cleared")
end})
skill:Space()
skill:Toggle({Title = "Auto Skill Check", Desc = "Replays the recorded input inside the goal", Callback = function(value)
    if value and not YH.skillRecorded then warn("[Yuki] Record one manual skill input first") end
    YH.skillOn = value
end})
skill:Space()
skill:Slider({Title = "Tolerance", Desc = "Increase if clicks are late", Width = 200, Value = {Min = 8, Max = 30, Default = 18}, Step = 1, Callback = function(value) YH.skillTolerance = value end})

local lines = {}
for i = 1, 4 do
    local line = YH.TrackDrawing(Drawing.new("Line"))
    line.Color = Color3.fromRGB(105, 255, 175)
    line.Transparency = 0.9
    line.Visible = false
    lines[i] = line
end

local function setCrosshairVisible(visible)
    for _, line in ipairs(lines) do line.Visible = visible end
end

YH.Connect(YH.LocalPlayer.Idled, function()
    if not YH.antiAfkOn then return end
    pcall(function()
        YH.VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        YH.VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end)

local skillGui, previousRotation, armed = nil, nil, true
local function angularDifference(a, b)
    return (a - b + 180) % 360 - 180
end

local function findSkillGui()
    local playerGui = YH.LocalPlayer:FindFirstChildOfClass("PlayerGui")
    return (playerGui and playerGui:FindFirstChild("SkillCheckPromptGui")) or YH.CoreGui:FindFirstChild("SkillCheckPromptGui")
end

local function activeSkillCheck()
    local gui = findSkillGui()
    if not gui or not gui.Enabled then return nil end
    local check = gui:FindFirstChild("Check", true)
    if check and check:IsA("GuiObject") then return gui, check end
end

YH.Connect(YH.UserInputService.InputBegan, function(input)
    if not YH.skillRecording then return end
    local _, check = activeSkillCheck()
    if not check then return end

    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
        YH.skillRecorded = {kind = "Key", key = input.KeyCode}
        YH.skillRecording = false
        warn("[Yuki] Recorded skill key: " .. input.KeyCode.Name)
        return
    end

    local button
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then button = 0
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then button = 1
    elseif input.UserInputType == Enum.UserInputType.MouseButton3 then button = 2 end
    if button == nil then return end

    local position, size = check.AbsolutePosition, check.AbsoluteSize
    local pointer = YH.UserInputService:GetMouseLocation()
    if input.UserInputType == Enum.UserInputType.Touch then pointer = input.Position end
    YH.skillRecorded = {
        kind = "Pointer",
        button = button,
        x = math.clamp((pointer.X - position.X) / math.max(size.X, 1), 0, 1),
        y = math.clamp((pointer.Y - position.Y) / math.max(size.Y, 1), 0, 1),
    }
    YH.skillRecording = false
    warn("[Yuki] Recorded skill pointer input")
end)

local function sendSkillInput(check)
    local recorded = YH.skillRecorded
    if not recorded then return end
    if recorded.kind == "Key" then
        YH.VirtualInputManager:SendKeyEvent(true, recorded.key, false, game)
        task.delay(0.04, function() pcall(function() YH.VirtualInputManager:SendKeyEvent(false, recorded.key, false, game) end) end)
        return
    end
    local position, size = check.AbsolutePosition, check.AbsoluteSize
    local x, y = position.X + size.X * recorded.x, position.Y + size.Y * recorded.y
    YH.VirtualInputManager:SendMouseButtonEvent(x, y, recorded.button, true, game, 0)
    task.delay(0.04, function() pcall(function() YH.VirtualInputManager:SendMouseButtonEvent(x, y, recorded.button, false, game, 0) end) end)
end

YH.Connect(YH.RunService.RenderStepped, function()
    local camera = YH.GetCamera()
    if camera and YH.chOn then
        local x, y = camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2
        local length, gap = YH.chLen, 3
        for _, line in ipairs(lines) do line.Thickness = YH.chW; line.Visible = true end
        lines[1].From = Vector2.new(x, y - length); lines[1].To = Vector2.new(x, y - gap)
        lines[2].From = Vector2.new(x, y + gap); lines[2].To = Vector2.new(x, y + length)
        lines[3].From = Vector2.new(x - length, y); lines[3].To = Vector2.new(x - gap, y)
        lines[4].From = Vector2.new(x + gap, y); lines[4].To = Vector2.new(x + length, y)
    else
        setCrosshairVisible(false)
    end

    if not YH.skillOn or not YH.skillRecorded then skillGui = nil; previousRotation = nil; armed = true; return end
    if not skillGui or not skillGui.Parent then skillGui = findSkillGui(); previousRotation = nil; armed = true end
    if not skillGui or not skillGui.Enabled then previousRotation = nil; armed = true; return end
    local check = skillGui:FindFirstChild("Check", true)
    local line = skillGui:FindFirstChild("Line", true)
    local goal = skillGui:FindFirstChild("Goal", true)
    if not check or not check:IsA("GuiObject") or not line or not goal then return end

    local rotation = line.Rotation % 360
    local difference = angularDifference(rotation, goal.Rotation % 360)
    local crossed = false
    if previousRotation then
        local previousDifference = angularDifference(previousRotation, goal.Rotation % 360)
        local step = math.abs(angularDifference(rotation, previousRotation))
        crossed = step < 90 and previousDifference * difference <= 0
    end
    if armed and (math.abs(difference) <= YH.skillTolerance or crossed) then
        armed = false
        pcall(sendSkillInput, check)
    elseif math.abs(difference) > YH.skillTolerance + 12 then
        armed = true
    end
    previousRotation = rotation
end)
