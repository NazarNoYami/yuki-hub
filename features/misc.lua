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
skill:Toggle({Title = "Auto Skill Check", Desc = "Clicks the selected recorded button in the goal", Callback = function(value)
    if value and not selectedTarget then warn("[Yuki] Record a button with button_detector.lua first") end
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

local function replaySelectedTarget()
    if not selectedTarget then return end
    if type(_G.YukiButtonDetectorGetTargets) == "function" and type(_G.YukiButtonDetectorClick) == "function" then
        for _, target in ipairs(_G.YukiButtonDetectorGetTargets()) do
            if target.key == selectedTarget.key then _G.YukiButtonDetectorClick(target); return end
        end
    end
    warn("[Yuki] Open button_detector.lua before auto replay")
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

    if not YH.skillOn or not selectedTarget then skillGui = nil; previousRotation = nil; armed = true; return end
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
        pcall(replaySelectedTarget)
    elseif math.abs(difference) > YH.skillTolerance + 12 then
        armed = true
    end
    previousRotation = rotation
end)
