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
local SKILL_CALIBRATION_FILE = "yuki_skill_calibration.json"
YH.skillTolerance = 4
YH.skillLead = 0.04
local calibrationOffset
local calibrating = false
local function loadCalibration()
    if type(readfile) ~= "function" then return end
    local ok, data = pcall(function() return YH.HttpService:JSONDecode(readfile(SKILL_CALIBRATION_FILE)) end)
    if ok and type(data) == "table" then calibrationOffset = tonumber(data.offset) end
end
local function saveCalibration(offset)
    calibrationOffset = offset
    if type(writefile) == "function" then
        pcall(writefile, SKILL_CALIBRATION_FILE, YH.HttpService:JSONEncode({offset = offset}))
    end
end
loadCalibration()
local savedTargets, targetLabels, selectedTarget = {}, {}, nil
local function loadSavedTargets()
    savedTargets, targetLabels, selectedTarget = {}, {}, nil
    if type(readfile) ~= "function" then targetLabels = {"File API unavailable"}; return end
    local ok, data = pcall(function() return YH.HttpService:JSONDecode(readfile("yuki_button_targets.json")) end)
    if not ok or type(data) ~= "table" or #data == 0 then targetLabels = {"No saved buttons"}; return end
    for index, target in ipairs(data) do
        if type(target.path) == "table" and type(target.fingerprint) == "string" then
            target.label = (target.name or target.path[#target.path] or "Button") .. " #" .. index
            table.insert(savedTargets, target)
            table.insert(targetLabels, target.label)
        end
    end
    selectedTarget = savedTargets[1]
end
loadSavedTargets()

local targetDropdown = skill:Dropdown({Title = "Recorded Button", Values = targetLabels, Value = 1, Callback = function(value)
    for _, target in ipairs(savedTargets) do if target.label == value then selectedTarget = target; break end end
end})
skill:Space()
skill:Button({Title = "Reload Saved Buttons", Desc = "Reload yuki_button_targets.json", Callback = function()
    loadSavedTargets()
    pcall(function() targetDropdown:Refresh(targetLabels) end)
    warn("[Yuki] Loaded " .. tostring(#savedTargets) .. " saved button(s)")
end})
skill:Space()
skill:Button({Title = "Calibrate Next Manual Hit", Desc = "Press once, then complete one skill check manually", Callback = function()
    calibrating = true
    warn("[Yuki] Calibration armed; perform one correctly timed manual hit")
end})
skill:Space()
skill:Button({Title = "Clear Calibration", Callback = function()
    calibrationOffset = nil
    calibrating = false
    if type(writefile) == "function" then pcall(writefile, SKILL_CALIBRATION_FILE, "{}") end
    warn("[Yuki] Skill calibration cleared")
end})
skill:Space()
skill:Toggle({Title = "Auto Skill Check", Desc = "Clicks the selected recorded button in the goal", Callback = function(value)
    if value and not selectedTarget then warn("[Yuki] Record a button with button_detector.lua first") end
    if value and not calibrationOffset then warn("[Yuki] Calibrate one manual hit first") end
    YH.skillOn = value
end})
skill:Space()
skill:Slider({Title = "Accuracy Window", Desc = "Lower is more precise", Width = 200, Value = {Min = 1, Max = 15, Default = 4}, Step = 1, Callback = function(value) YH.skillTolerance = value end})
skill:Space()
skill:Slider({Title = "Input Lead", Desc = "Compensates click latency (ms)", Width = 200, Value = {Min = 0, Max = 120, Default = 40}, Step = 5, Callback = function(value) YH.skillLead = value / 1000 end})

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

local skillGui, previousRotation, previousError = nil, nil, nil
local angularVelocity = 0
local clickedPrompt = false
local function angularDifference(a, b)
    return (a - b + 180) % 360 - 180
end

local function findSkillGui()
    local playerGui = YH.LocalPlayer:FindFirstChildOfClass("PlayerGui")
    return (playerGui and playerGui:FindFirstChild("SkillCheckPromptGui")) or YH.CoreGui:FindFirstChild("SkillCheckPromptGui")
end

local function selectedRuntimeTarget()
    if not selectedTarget or type(_G.YukiButtonDetectorGetTargets) ~= "function" then return nil end
    for _, target in ipairs(_G.YukiButtonDetectorGetTargets()) do
        if target.key == selectedTarget.key then return target end
    end
end

YH.Connect(YH.UserInputService.InputBegan, function(input, processed)
    if not calibrating or processed and input.UserInputType == Enum.UserInputType.Keyboard then return end
    local gui = findSkillGui()
    if not gui or not gui.Enabled then return end
    local line = gui:FindFirstChild("Line", true)
    local goal = gui:FindFirstChild("Goal", true)
    if not line or not goal then return end
    local isAction = input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Keyboard
    if not isAction then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        local target = selectedRuntimeTarget()
        local object = target and target.object
        if object and object:IsA("GuiObject") then
            local point = input.UserInputType == Enum.UserInputType.Touch and input.Position or YH.UserInputService:GetMouseLocation()
            local position, size = object.AbsolutePosition, object.AbsoluteSize
            if point.X < position.X or point.X > position.X + size.X or point.Y < position.Y or point.Y > position.Y + size.Y then return end
        end
    end
    local offset = angularDifference(line.AbsoluteRotation % 360, goal.AbsoluteRotation % 360)
    saveCalibration(offset)
    calibrating = false
    warn(string.format("[Yuki] Skill calibration saved: %.2f degrees", offset))
end)

local function replaySelectedTarget()
    if not selectedTarget then return end
    if type(_G.YukiButtonDetectorGetTargets) == "function" and type(_G.YukiButtonDetectorClick) == "function" then
        for _, target in ipairs(_G.YukiButtonDetectorGetTargets()) do
            if target.key == selectedTarget.key then _G.YukiButtonDetectorClick(target); return end
        end
    end
    warn("[Yuki] Open button_detector.lua before auto replay")
end

YH.Connect(YH.RunService.RenderStepped, function(dt)
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

    if not YH.skillOn or not selectedTarget or not calibrationOffset then
        skillGui = nil; previousRotation = nil; previousError = nil; angularVelocity = 0; clickedPrompt = false; return
    end
    if not skillGui or not skillGui.Parent then
        skillGui = findSkillGui(); previousRotation = nil; previousError = nil; angularVelocity = 0; clickedPrompt = false
    end
    if not skillGui or not skillGui.Enabled then
        previousRotation = nil; previousError = nil; angularVelocity = 0; clickedPrompt = false; return
    end
    local check = skillGui:FindFirstChild("Check", true)
    local line = skillGui:FindFirstChild("Line", true)
    local goal = skillGui:FindFirstChild("Goal", true)
    if not check or not check:IsA("GuiObject") or not line or not goal then return end
    if goal.Rotation == 0 then
        previousRotation = nil; previousError = nil; angularVelocity = 0; clickedPrompt = false; return
    end

    local rotation = line.AbsoluteRotation % 360
    local goalRotation = goal.AbsoluteRotation % 360
    if previousRotation and dt > 0 then
        local measuredVelocity = angularDifference(rotation, previousRotation) / dt
        angularVelocity = angularVelocity == 0 and measuredVelocity or angularVelocity * 0.65 + measuredVelocity * 0.35
    end
    local predictedRotation = rotation + angularVelocity * YH.skillLead
    local difference = angularDifference(predictedRotation, goalRotation)
    local error = angularDifference(difference, calibrationOffset)
    local crossed = false
    if previousError then
        local step = math.abs(angularDifference(error, previousError))
        crossed = step < 45 and previousError * error <= 0
    end
    if not clickedPrompt and (math.abs(error) <= YH.skillTolerance or crossed) then
        clickedPrompt = true
        pcall(replaySelectedTarget)
    end
    previousRotation = rotation
    previousError = error
end)
