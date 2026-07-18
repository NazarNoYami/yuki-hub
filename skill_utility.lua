local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TARGET_FILE = "yuki_button_targets.json"
local CALIBRATION_FILE = "yuki_skill_calibration.json"

if _G.YukiSkillUtilityCleanup then pcall(_G.YukiSkillUtilityCleanup) end

local connections, instances = {}, {}
local function track(instance) table.insert(instances, instance); return instance end
local function connect(signal, callback, list)
    local connection = signal:Connect(callback)
    table.insert(list or connections, connection)
    return connection
end

local originalLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
}
local LUNGE_ID = "110355011987939"
local ATTACK_ID = "139369275981139"
local targets, selectedIndex, calibrationOffset = {}, 1, nil
local autoSkill, calibrating, brightOn, generatorOn, playerOn = false, false, false, false, false
local parryOn, parryRadius = false, 10
local parryCircle, parryTargetIndex
local parryConnections, watchedKiller = {}, nil
local lastParryTrigger = 0
-- Manual calibration already captures most device/reaction latency; keep only a small replay lead.
local accuracy, inputLead = 4, 0.01
local playerVisuals, generatorVisuals = {}, {}
local debugLines = {}
local debugLiveText = "Prompt inactive"
local debugLastUpdate = 0

local function cleanup()
    for _, target in ipairs(targets) do
        if target.touchActive then
            pcall(function() VirtualInputManager:SendTouchEvent(target.touchId, 2, target.lastX, target.lastY) end)
            target.touchActive = false
        end
    end
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    for _, connection in ipairs(parryConnections) do pcall(function() connection:Disconnect() end) end
    if parryCircle then pcall(function() parryCircle:Remove() end); parryCircle = nil end
    for _, instance in ipairs(instances) do pcall(function() instance:Destroy() end) end
    for property, value in pairs(originalLighting) do pcall(function() Lighting[property] = value end) end
    _G.YukiSkillUtilityCleanup = nil
end
_G.YukiSkillUtilityCleanup = cleanup

local screen = track(Instance.new("ScreenGui"))
screen.Name = "YukiSkillUtility"
screen.ResetOnSpawn = false
screen.DisplayOrder = 999998
screen.Parent = CoreGui

local debugPanel = Instance.new("Frame")
debugPanel.Size = UDim2.new(0, 220, 0, 210)
debugPanel.Position = UDim2.new(0, 270, 0.5, -105)
debugPanel.BackgroundColor3 = Color3.fromRGB(11, 14, 22)
debugPanel.BackgroundTransparency = 0.04
debugPanel.BorderSizePixel = 0
debugPanel.Visible = false
debugPanel.Active = true
debugPanel.Draggable = true
debugPanel.Parent = screen
Instance.new("UICorner", debugPanel).CornerRadius = UDim.new(0, 8)
local debugStroke = Instance.new("UIStroke", debugPanel)
debugStroke.Color = Color3.fromRGB(225, 160, 70)
debugStroke.Transparency = 0.3

local debugTitle = Instance.new("TextLabel")
debugTitle.Position = UDim2.new(0, 7, 0, 4)
debugTitle.Size = UDim2.new(1, -14, 0, 17)
debugTitle.BackgroundTransparency = 1
debugTitle.Font = Enum.Font.SourceSansBold
debugTitle.TextSize = 11
debugTitle.TextColor3 = Color3.fromRGB(255, 210, 130)
debugTitle.TextXAlignment = Enum.TextXAlignment.Left
debugTitle.Text = "AUTO SKILL DEBUG"
debugTitle.Parent = debugPanel

local debugLive = Instance.new("TextLabel")
debugLive.Position = UDim2.new(0, 7, 0, 24)
debugLive.Size = UDim2.new(1, -14, 0, 64)
debugLive.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
debugLive.BorderSizePixel = 0
debugLive.Font = Enum.Font.Code
debugLive.TextSize = 8
debugLive.TextWrapped = true
debugLive.TextColor3 = Color3.fromRGB(185, 205, 240)
debugLive.TextXAlignment = Enum.TextXAlignment.Left
debugLive.TextYAlignment = Enum.TextYAlignment.Top
debugLive.Text = debugLiveText
debugLive.Parent = debugPanel
Instance.new("UICorner", debugLive).CornerRadius = UDim.new(0, 6)

local debugLog = Instance.new("TextLabel")
debugLog.Position = UDim2.new(0, 7, 0, 93)
debugLog.Size = UDim2.new(1, -14, 1, -100)
debugLog.BackgroundColor3 = Color3.fromRGB(18, 21, 31)
debugLog.BorderSizePixel = 0
debugLog.Font = Enum.Font.Code
debugLog.TextSize = 8
debugLog.TextWrapped = true
debugLog.TextColor3 = Color3.fromRGB(190, 195, 210)
debugLog.TextXAlignment = Enum.TextXAlignment.Left
debugLog.TextYAlignment = Enum.TextYAlignment.Top
debugLog.Text = ""
debugLog.Parent = debugPanel
Instance.new("UICorner", debugLog).CornerRadius = UDim.new(0, 6)

local function addDebug(message)
    local elapsed = os.clock()
    table.insert(debugLines, string.format("[%06.2f] %s", elapsed % 1000, message))
    while #debugLines > 11 do table.remove(debugLines, 1) end
    debugLog.Text = table.concat(debugLines, "\n")
end

local function setDebugLive(text, force)
    debugLiveText = text
    local now = os.clock()
    if force or now - debugLastUpdate >= 0.1 then
        debugLastUpdate = now
        debugLive.Text = debugLiveText
    end
end

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 250, 0, 388)
panel.Position = UDim2.new(0, 12, 0.5, -143)
panel.BackgroundColor3 = Color3.fromRGB(15, 18, 27)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = screen
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color = Color3.fromRGB(90, 125, 220)
panelStroke.Transparency = 0.35

local title = Instance.new("TextLabel")
title.Position = UDim2.new(0, 10, 0, 4)
title.Size = UDim2.new(1, -42, 0, 28)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(235, 240, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Skill Utility"
title.Parent = panel

local close = Instance.new("TextButton")
close.Position = UDim2.new(1, -32, 0, 4)
close.Size = UDim2.new(0, 27, 0, 27)
close.BackgroundColor3 = Color3.fromRGB(44, 48, 64)
close.BorderSizePixel = 0
close.Font = Enum.Font.SourceSansBold
close.TextSize = 14
close.TextColor3 = Color3.fromRGB(255, 125, 140)
close.Text = "X"
close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel")
status.Position = UDim2.new(0, 10, 0, 36)
status.Size = UDim2.new(1, -20, 0, 38)
status.BackgroundColor3 = Color3.fromRGB(24, 28, 41)
status.BorderSizePixel = 0
status.Font = Enum.Font.SourceSans
status.TextSize = 12
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(175, 187, 218)
status.Text = "Loading saved targets..."
status.Parent = panel
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 7)

local function makeButton(text, y)
    local button = Instance.new("TextButton")
    button.Position = UDim2.new(0, 10, 0, y)
    button.Size = UDim2.new(1, -20, 0, 29)
    button.BackgroundColor3 = Color3.fromRGB(51, 57, 78)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.SourceSansSemibold
    button.TextSize = 13
    button.TextColor3 = Color3.fromRGB(230, 235, 250)
    button.Text = text
    button.Parent = panel
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
    return button
end

local targetButton = makeButton("Target: none", 80)
local calibrateButton = makeButton("Calibrate Next Manual Hit", 114)
local autoButton = makeButton("Auto Skill: OFF", 148)
local brightButton = makeButton("Full Bright: OFF", 182)
local generatorButton = makeButton("Generator ESP: OFF", 216)
local playerButton = makeButton("Player ESP: OFF", 250)
local parryTargetButton = makeButton("Parry Button: same target", 284)
local parryButton = makeButton("Auto Parry: OFF", 318)
local parryRadiusButton = makeButton("Parry Radius: 10 studs", 352)

local function setToggle(button, label, enabled)
    button.Text = label .. ": " .. (enabled and "ON" or "OFF")
    button.BackgroundColor3 = enabled and Color3.fromRGB(45, 135, 105) or Color3.fromRGB(51, 57, 78)
end

local function angularDifference(a, b)
    return (a - b + 180) % 360 - 180
end

local function resolve(root, path)
    local current = root
    for _, name in ipairs(path or {}) do current = current and current:FindFirstChild(name) end
    return current
end

local function pathFrom(root, object)
    local path, current = {}, object
    while current and current ~= root do table.insert(path, 1, current.Name); current = current.Parent end
    return current == root and path or nil
end

local function imageFingerprint(button)
    local images, candidates = {}, {button}
    for _, descendant in ipairs(button:GetDescendants()) do table.insert(candidates, descendant) end
    for _, image in ipairs(candidates) do
        if image:IsA("ImageLabel") or image:IsA("ImageButton") then
            local active, current = image.Visible and image.ImageTransparency < 0.95, image.Parent
            while active and current and current ~= button do
                if current:IsA("GuiObject") and not current.Visible then active = false end
                current = current.Parent
            end
            if active then
                table.insert(images, table.concat({
                    table.concat(pathFrom(button, image) or {}, "/"), image.ClassName, image.Image,
                    tostring(image.ImageRectOffset), tostring(image.ImageRectSize),
                }, "|"))
            end
        end
    end
    table.sort(images)
    return #images > 0 and table.concat(images, ";") or "NO_IMAGE"
end

local function targetVisible(target)
    local object = target.object
    if not object or not object.Parent or not object:IsA("GuiObject") or not object.Visible then return false end
    local current = object.Parent
    while current do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("ScreenGui") and not current.Enabled then return false end
        current = current.Parent
    end
    return object.AbsoluteSize.X > 0 and object.AbsoluteSize.Y > 0 and imageFingerprint(object) == target.fingerprint
end

local function loadTargets()
    targets, selectedIndex = {}, 1
    if type(readfile) ~= "function" then status.Text = "File API unavailable"; return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(TARGET_FILE)) end)
    if not ok or type(data) ~= "table" then status.Text = "Record a button with button_detector.lua"; return end
    for index, saved in ipairs(data) do
        if type(saved.path) == "table" and type(saved.fingerprint) == "string" then
            local root = saved.root == "CoreGui" and CoreGui or PlayerGui
            table.insert(targets, {
                key = saved.key,
                name = (saved.name or saved.path[#saved.path] or "Button") .. " #" .. index,
                root = root,
                path = saved.path,
                object = resolve(root, saved.path),
                fingerprint = saved.fingerprint,
                x = tonumber(saved.x) or 0.5,
                y = tonumber(saved.y) or 0.5,
                inputType = saved.inputType == "Mouse" and "Mouse" or "Touch",
                touchId = 500 + index,
                busy = false,
            })
        end
    end
    targetButton.Text = "Target: " .. (#targets > 0 and targets[1].name or "none")
    status.Text = tostring(#targets) .. " target(s) loaded"
end

local function loadCalibration()
    if type(readfile) ~= "function" then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CALIBRATION_FILE)) end)
    if ok and type(data) == "table" then calibrationOffset = tonumber(data.offset) end
end

local function selectedTarget()
    return targets[selectedIndex]
end

local function fireSignals(object, x, y)
    if not object:IsA("GuiButton") then return false end
    local fired = pcall(function() object:Activate() end)
    if type(firesignal) == "function" then
        for _, event in ipairs({
            {object.MouseButton1Down, x, y}, {object.Activated, nil, 1},
            {object.MouseButton1Click}, {object.MouseButton1Up, x, y},
        }) do if pcall(firesignal, event[1], event[2], event[3]) then fired = true end end
    end
    return fired
end

local function replayTarget(target)
    if not target then addDebug("REPLAY fail: no target"); return end
    if target.busy then addDebug("REPLAY skip: target busy"); return end
    if not target.object or not target.object.Parent then target.object = resolve(target.root, target.path) end
    if not targetVisible(target) then
        status.Text = "Selected action icon is not visible"
        addDebug("REPLAY fail: icon/path not visible")
        return
    end
    target.busy = true
    local object, position, size = target.object, target.object.AbsolutePosition, target.object.AbsoluteSize
    local x, y = position.X + size.X * target.x, position.Y + size.Y * target.y
    target.lastX, target.lastY = x, y
    task.spawn(function()
        local signaled = fireSignals(object, x, y)
        if target.inputType == "Touch" then
            addDebug(string.format("REPLAY %s signal=%s input=Touch", target.name, tostring(signaled)))
            target.touchActive = pcall(function() VirtualInputManager:SendTouchEvent(target.touchId, 0, x, y) end)
            task.wait(0.06)
            pcall(function() VirtualInputManager:SendTouchEvent(target.touchId, 2, x, y) end)
            target.touchActive = false
        else
            addDebug(string.format("REPLAY %s signal=%s input=Mouse", target.name, tostring(signaled)))
            pcall(function() VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0) end)
            task.wait(0.04)
            pcall(function() VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0) end)
        end
        target.busy = false
    end)
end

local function findSkillGui()
    return PlayerGui:FindFirstChild("SkillCheckPromptGui") or CoreGui:FindFirstChild("SkillCheckPromptGui")
end

connect(targetButton.MouseButton1Click, function()
    if #targets == 0 then return end
    selectedIndex = selectedIndex % #targets + 1
    targetButton.Text = "Target: " .. targets[selectedIndex].name
    addDebug("TARGET selected: " .. targets[selectedIndex].name)
end)

connect(calibrateButton.MouseButton1Click, function()
    calibrating = true
    status.Text = "Calibration armed: make one correct manual hit"
    addDebug("CALIBRATION armed")
end)

connect(autoButton.MouseButton1Click, function()
    autoSkill = not autoSkill
    setToggle(autoButton, "Auto Skill", autoSkill)
    debugPanel.Visible = autoSkill
    addDebug("AUTO " .. (autoSkill and "enabled" or "disabled"))
    if autoSkill and not calibrationOffset then status.Text = "Calibrate one manual hit first" end
end)

connect(brightButton.MouseButton1Click, function()
    brightOn = not brightOn
    setToggle(brightButton, "Full Bright", brightOn)
    if not brightOn then for property, value in pairs(originalLighting) do Lighting[property] = value end end
end)

connect(generatorButton.MouseButton1Click, function()
    generatorOn = not generatorOn
    setToggle(generatorButton, "Generator ESP", generatorOn)
    if not generatorOn then
        for object, visual in pairs(generatorVisuals) do visual:Destroy(); generatorVisuals[object] = nil end
    end
end)

connect(playerButton.MouseButton1Click, function()
    playerOn = not playerOn
    setToggle(playerButton, "Player ESP", playerOn)
    if not playerOn then
        for player, visual in pairs(playerVisuals) do visual:Destroy(); playerVisuals[player] = nil end
    end
end)

connect(parryTargetButton.MouseButton1Click, function()
    if #targets == 0 then return end
    parryTargetIndex = parryTargetIndex and parryTargetIndex % #targets + 1 or 1
    parryTargetButton.Text = "Parry Button: " .. targets[parryTargetIndex].name
    addDebug("PARRY target set to " .. targets[parryTargetIndex].name)
end)
local function parryTarget() return targets[parryTargetIndex or selectedIndex] end

connect(parryButton.MouseButton1Click, function()
    parryOn = not parryOn
    setToggle(parryButton, "Auto Parry", parryOn)
    if parryOn then
        if not parryCircle then
            parryCircle = track(Drawing.new("Circle"))
            parryCircle.Color = Color3.fromRGB(90, 175, 235)
            parryCircle.Thickness = 1.5
            parryCircle.Transparency = 0.65
            parryCircle.Filled = false
            parryCircle.Visible = false
        end
        refreshKillerWatcher()
        addDebug("PARRY enabled")
    else
        disconnectAll(parryConnections)
        watchedKiller = nil
        if parryCircle then parryCircle.Visible = false end
        addDebug("PARRY disabled")
    end
end)

local parryRadii = {6, 8, 10, 12, 14, 16}
local parryRadiusIdx = 3
connect(parryRadiusButton.MouseButton1Click, function()
    parryRadiusIdx = parryRadiusIdx % #parryRadii + 1
    parryRadius = parryRadii[parryRadiusIdx]
    parryRadiusButton.Text = "Parry Radius: " .. parryRadius .. " studs"
end)

local function normalizeId(id) return tostring(id or ""):match("(%d+)") or "" end
local function rootOf(player) return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end
local function killerPlayer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local team = player.Team and player.Team.Name:lower() or ""
            if team:find("killer") or team:find("maniac") then return player end
        end
    end
end

local function geometry(killer)
    local killerRoot, ownRoot = rootOf(killer), rootOf(LocalPlayer)
    if not killerRoot or not ownRoot then return nil, nil end
    local offset = ownRoot.Position - killerRoot.Position
    return offset.Magnitude, killerRoot.CFrame.LookVector:Dot(offset.Unit)
end

local function watchKillerAnimator(killer, character)
    disconnectAll(parryConnections)
    watchedKiller = killer
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5))
    if not animator then return end
    connect(animator.AnimationPlayed, function(track)
        if not parryOn then return end
        local id = normalizeId(track.Animation and track.Animation.AnimationId)
        if id == LUNGE_ID or id == ATTACK_ID then
            local now = os.clock()
            if now - lastParryTrigger < 0.5 then return end
            lastParryTrigger = now
            local distance, facing = geometry(killer)
            if distance and distance <= parryRadius and facing and facing > 0.3 then
                addDebug("PARRY trigger " .. track.Name .. " dist=" .. string.format("%.1f", distance))
                local target = parryTarget()
                if target then replayTarget(target) end
            end
        end
    end, parryConnections)
end

local function refreshKillerWatcher()
    local killer = killerPlayer()
    if not killer then return end
    if killer.Character and killer.Character ~= watchedKiller then watchKillerAnimator(killer, killer.Character) end
end

connect(close.MouseButton1Click, cleanup)

connect(UserInputService.InputBegan, function(input, processed)
    if not calibrating or processed and input.UserInputType == Enum.UserInputType.Keyboard then return end
    local gui, target = findSkillGui(), selectedTarget()
    if not gui or not gui.Enabled or not target then return end
    if not target.object or not target.object.Parent then target.object = resolve(target.root, target.path) end
    local line, goal = gui:FindFirstChild("Line", true), gui:FindFirstChild("Goal", true)
    if not line or not goal then return end
    local action = input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Keyboard
    if not action then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard and target.object then
        local point = input.UserInputType == Enum.UserInputType.Touch and input.Position or UserInputService:GetMouseLocation()
        local position, size = target.object.AbsolutePosition, target.object.AbsoluteSize
        if point.X < position.X or point.X > position.X + size.X or point.Y < position.Y or point.Y > position.Y + size.Y then return end
    elseif input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end
    calibrationOffset = angularDifference(line.AbsoluteRotation % 360, goal.AbsoluteRotation % 360)
    calibrating = false
    if type(writefile) == "function" then
        pcall(writefile, CALIBRATION_FILE, HttpService:JSONEncode({offset = calibrationOffset}))
    end
    status.Text = string.format("Calibration saved: %.1f deg", calibrationOffset)
    addDebug(string.format("CALIBRATION saved offset=%.2f", calibrationOffset))
end)

local skillGui, previousRotation, previousRawError, velocity, clickedPrompt = nil, nil, nil, 0, false
local promptElapsed, promptArmed = 0, false
local promptStatus, promptActive
local lastTriggerSummary
local scanTimer = 0
local function resetPrompt()
    if promptActive then addDebug("PROMPT ended") end
    previousRotation, previousRawError, velocity, clickedPrompt = nil, nil, 0, false
    promptElapsed, promptArmed = 0, false
    promptStatus, promptActive = nil, false
    setDebugLive(lastTriggerSummary and ("Prompt inactive\n" .. lastTriggerSummary) or "Prompt inactive", true)
end
local function setPromptStatus(value)
    if promptStatus == value then return end
    promptStatus = value
    status.Text = "Skill: " .. value
    addDebug("STATE -> " .. value)
end
connect(RunService.RenderStepped, function(dt)
    if brightOn then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    end

    if autoSkill and calibrationOffset and selectedTarget() then
        if not skillGui or not skillGui.Parent then
            skillGui = findSkillGui()
            resetPrompt()
            if not skillGui then setDebugLive("Waiting for SkillCheckPromptGui") end
        end
        if skillGui and skillGui.Enabled then
            local line, goal = skillGui:FindFirstChild("Line", true), skillGui:FindFirstChild("Goal", true)
            if line and goal and goal.Rotation ~= 0 then
                if not promptActive then
                    promptActive = true
                    addDebug("PROMPT started")
                end
                promptElapsed = promptElapsed + dt
                setPromptStatus(promptArmed and "armed" or "waiting")
                local rotation, goalRotation = line.AbsoluteRotation % 360, goal.AbsoluteRotation % 360
                local rawDifference = angularDifference(rotation, goalRotation)
                local rawError = angularDifference(rawDifference, calibrationOffset)
                if previousRotation and dt > 0 then
                    local measured = angularDifference(rotation, previousRotation) / dt
                    velocity = velocity == 0 and measured or velocity * 0.65 + measured * 0.35
                end
                local errorVelocity = velocity
                local err = rawError + errorVelocity * inputLead
                local moving = math.abs(velocity) >= 15
                if promptElapsed >= 0.18 and moving and math.abs(err) >= math.max(accuracy + 8, 12) then
                    promptArmed = true
                    setPromptStatus("armed")
                end
                local timeToTarget = errorVelocity ~= 0 and (-rawError / errorVelocity) or math.huge
                local frameMargin = math.min(dt * 0.5, 0.008)
                local approaching = timeToTarget >= 0 and timeToTarget <= inputLead + frameMargin
                -- Crossing is only a narrow fallback when a low-FPS frame skips the target.
                local crossingRange = accuracy
                local crossed = previousRawError
                    and math.abs(previousRawError) <= crossingRange
                    and math.abs(rawError) <= crossingRange
                    and previousRawError * rawError <= 0
                setDebugLive(string.format(
                    "state=%s armed=%s clicked=%s\nline=%.2f goal=%.2f targetOff=%.2f\nrawErr=%.2f predErr=%.2f vel=%.1f tTarget=%dms\nlead=%dms move=%s approach=%s cross=%s",
                    promptStatus or "waiting", tostring(promptArmed), tostring(clickedPrompt),
                    rotation, goalRotation, calibrationOffset, rawError, err, velocity,
                    timeToTarget == math.huge and -1 or math.floor(timeToTarget * 1000 + 0.5),
                    math.floor(inputLead * 1000 + 0.5), tostring(moving), tostring(approaching), tostring(crossed)
                ))
                if promptArmed and not clickedPrompt and moving and (math.abs(err) <= accuracy or approaching or crossed) then
                    clickedPrompt = true
                    setPromptStatus("clicked")
                    lastTriggerSummary = string.format("last raw=%.2f pred=%.2f t=%dms", rawError, err,
                        timeToTarget == math.huge and -1 or math.floor(timeToTarget * 1000 + 0.5))
                    addDebug(string.format("TRIGGER raw=%.2f pred=%.2f t=%dms approach=%s cross=%s", rawError, err,
                        timeToTarget == math.huge and -1 or math.floor(timeToTarget * 1000 + 0.5),
                        tostring(approaching), tostring(crossed)))
                    replayTarget(selectedTarget())
                end
                previousRotation, previousRawError = rotation, rawError
            else
                resetPrompt()
                if not line or not goal then setDebugLive("Prompt GUI found; missing Line/Goal") end
            end
        else
            resetPrompt()
            if skillGui then setDebugLive("SkillCheckPromptGui disabled") end
        end
    elseif previousRotation or promptElapsed > 0 then
        resetPrompt()
    end

    scanTimer = scanTimer + dt
    if scanTimer < 0.4 then return end
    scanTimer = 0

    if parryOn then
        refreshKillerWatcher()
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if parryCircle and root then
            local camera = workspace.CurrentCamera
            local point, visible = camera and camera:WorldToViewportPoint(root.Position)
            if visible then
                parryCircle.Radius = math.max(parryRadius * 1000 / point.Z, 5)
                parryCircle.Position = Vector2.new(point.X, point.Y)
                parryCircle.Visible = true
            else
                parryCircle.Visible = false
            end
        end
    end

    if playerOn then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local visual = playerVisuals[player]
                if not visual then
                    visual = track(Instance.new("Highlight"))
                    visual.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    visual.FillTransparency = 0.45
                    visual.OutlineTransparency = 0
                    visual.Parent = CoreGui
                    playerVisuals[player] = visual
                end
                visual.Adornee = player.Character
                local teamName = player.Team and player.Team.Name:lower() or ""
                visual.FillColor = (teamName:find("killer") or teamName:find("maniac"))
                    and Color3.fromRGB(255, 75, 90) or Color3.fromRGB(90, 235, 145)
            end
        end
        for player, visual in pairs(playerVisuals) do
            if not player.Parent or not player.Character then visual:Destroy(); playerVisuals[player] = nil end
        end
    end

    if generatorOn then
        local map = workspace:FindFirstChild("Map") or workspace
        local found = {}
        for _, object in ipairs(map:GetDescendants()) do
            if object:IsA("Model") and (object.Name:lower():find("generator") or object:GetAttribute("RepairProgress") ~= nil) then
                found[object] = true
                local visual = generatorVisuals[object]
                if not visual then
                    visual = track(Instance.new("Highlight"))
                    visual.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    visual.FillTransparency = 0.5
                    visual.OutlineTransparency = 0
                    visual.Parent = CoreGui
                    generatorVisuals[object] = visual
                end
                local ratio = math.clamp((object:GetAttribute("RepairProgress") or 0) / 100, 0, 1)
                local color = Color3.fromRGB(255, 90, 105):Lerp(Color3.fromRGB(85, 235, 145), ratio)
                visual.Adornee = object
                visual.FillColor, visual.OutlineColor = color, color
            end
        end
        for object, visual in pairs(generatorVisuals) do
            if not object.Parent or not found[object] then visual:Destroy(); generatorVisuals[object] = nil end
        end
    end
end)

loadTargets()
loadCalibration()
if calibrationOffset then status.Text = status.Text .. " | calibrated" end
addDebug("INIT targets=" .. tostring(#targets))
addDebug(calibrationOffset and string.format("INIT calibration=%.2f", calibrationOffset) or "INIT no calibration")
if targets[1] then addDebug("INIT target=" .. targets[1].name) end
