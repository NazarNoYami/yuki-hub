local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TARGET_FILE = "yuki_button_targets.json"
local OUTPUT_FILE = "parry_probe_results.json"
local LUNGE_ID = "110355011987939"
local ATTACK_ID = "139369275981139"

if _G.YukiParryProbeCleanup then pcall(_G.YukiParryProbeCleanup) end

local connections, sessionConnections, killerConnections = {}, {}, {}
local targets, selectedIndex = {}, 1
local attempts = {}
local timeline = {}
local currentAttempt
local running = false
local watchedCharacter
local sessionStartedAt = 0
local ownHealth

local function disconnectAll(list)
    for _, connection in ipairs(list) do pcall(function() connection:Disconnect() end) end
    table.clear(list)
end

local function connect(signal, callback, list)
    local connection = signal:Connect(callback)
    table.insert(list or connections, connection)
    return connection
end

local screen = Instance.new("ScreenGui")
screen.Name = "YukiParryProbe"
screen.ResetOnSpawn = false
screen.DisplayOrder = 999999
screen.Parent = CoreGui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 270, 0, 316)
panel.Position = UDim2.new(0, 12, 0.5, -158)
panel.BackgroundColor3 = Color3.fromRGB(14, 17, 25)
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = screen
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(90, 175, 235)
stroke.Transparency = 0.3

local title = Instance.new("TextLabel")
title.Position = UDim2.new(0, 10, 0, 4)
title.Size = UDim2.new(1, -42, 0, 28)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(215, 238, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Parry Timing Probe"
title.Parent = panel

local close = Instance.new("TextButton")
close.Position = UDim2.new(1, -32, 0, 4)
close.Size = UDim2.new(0, 27, 0, 27)
close.BackgroundColor3 = Color3.fromRGB(45, 49, 64)
close.BorderSizePixel = 0
close.Font = Enum.Font.SourceSansBold
close.TextSize = 14
close.TextColor3 = Color3.fromRGB(255, 130, 140)
close.Text = "X"
close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel")
status.Position = UDim2.new(0, 10, 0, 36)
status.Size = UDim2.new(1, -20, 0, 58)
status.BackgroundColor3 = Color3.fromRGB(23, 27, 39)
status.BorderSizePixel = 0
status.Font = Enum.Font.Code
status.TextSize = 11
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(185, 200, 225)
status.Text = "Load a Parry target, then Start"
status.Parent = panel
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 7)

local function makeButton(text, y, color)
    local button = Instance.new("TextButton")
    button.Position = UDim2.new(0, 10, 0, y)
    button.Size = UDim2.new(1, -20, 0, 30)
    button.BackgroundColor3 = color or Color3.fromRGB(50, 56, 76)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.SourceSansSemibold
    button.TextSize = 13
    button.TextColor3 = Color3.fromRGB(235, 238, 250)
    button.Text = text
    button.Parent = panel
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
    return button
end

local targetButton = makeButton("Target: none", 102)
local startButton = makeButton("Start Probe", 138)
local earlyButton = makeButton("Result: TOO EARLY", 174, Color3.fromRGB(170, 105, 45))
local successButton = makeButton("Result: SUCCESS", 210, Color3.fromRGB(40, 135, 90))
local lateButton = makeButton("Result: TOO LATE", 246, Color3.fromRGB(160, 60, 75))
local saveButton = makeButton("Save / Copy Results", 282)

local function cleanup()
    running = false
    disconnectAll(sessionConnections)
    disconnectAll(killerConnections)
    disconnectAll(connections)
    if screen.Parent then screen:Destroy() end
    _G.YukiParryProbeCleanup = nil
end
_G.YukiParryProbeCleanup = cleanup

local function normalizeId(id)
    return tostring(id or ""):match("(%d+)") or ""
end

local function elapsedMs()
    return sessionStartedAt > 0 and math.floor((os.clock() - sessionStartedAt) * 1000 + 0.5) or 0
end

local function logEvent(kind, data)
    if not running then return end
    data = data or {}
    data.t = elapsedMs()
    data.kind = kind
    table.insert(timeline, data)
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

local function clickableObject(object, root)
    local current = object
    while current and current ~= root do
        if current:IsA("GuiButton") then return current end
        current = current.Parent
    end
    return object
end

local function objectsAt(x, y)
    local result, seen = {}, {}
    for _, root in ipairs({PlayerGui, CoreGui}) do
        local ok, objects = pcall(function() return root:GetGuiObjectsAtPosition(x, y) end)
        if ok then
            for _, object in ipairs(objects) do
                local clickable = clickableObject(object, root)
                if not seen[clickable] then
                    seen[clickable] = true
                    table.insert(result, {
                        name = clickable.Name,
                        class = clickable.ClassName,
                        root = root == CoreGui and "CoreGui" or "PlayerGui",
                        path = table.concat(pathFrom(root, clickable) or {}, "/"),
                        fingerprint = imageFingerprint(clickable),
                    })
                end
            end
        end
    end
    return result
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
    return imageFingerprint(object) == target.fingerprint
end

local function loadTargets()
    targets, selectedIndex = {}, 1
    if type(readfile) ~= "function" then status.Text = "File API unavailable"; return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(TARGET_FILE)) end)
    if not ok or type(data) ~= "table" then status.Text = "Record Parry with button_detector.lua"; return end
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
            })
        end
    end
    targetButton.Text = "Target: " .. (#targets > 0 and targets[1].name or "none")
    status.Text = tostring(#targets) .. " target(s) loaded"
end

local function selectedTarget()
    return targets[selectedIndex]
end

local function rootOf(player)
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function geometry(killer)
    local killerRoot, ownRoot = rootOf(killer), rootOf(LocalPlayer)
    if not killerRoot or not ownRoot then return nil, nil end
    local offset = ownRoot.Position - killerRoot.Position
    local distance = offset.Magnitude
    local facing = distance > 0 and killerRoot.CFrame.LookVector:Dot(offset.Unit) or 0
    return math.floor(distance * 100 + 0.5) / 100, math.floor(facing * 1000 + 0.5) / 1000
end

local function killerPlayer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local team = player.Team and player.Team.Name:lower() or ""
            if team:find("killer") or team:find("maniac") then return player end
        end
    end
end

local function saveResults()
    local counts = {TooEarly = 0, Success = 0, TooLate = 0}
    for _, attempt in ipairs(attempts) do
        if counts[attempt.outcome] ~= nil then counts[attempt.outcome] = counts[attempt.outcome] + 1 end
    end
    local payload = {
        version = 1,
        placeId = game.PlaceId,
        savedUnix = os.time(),
        counts = counts,
        attempts = attempts,
        timeline = timeline,
    }
    local json = HttpService:JSONEncode(payload)
    local saved = type(writefile) == "function" and pcall(function()
        writefile(OUTPUT_FILE, json)
        writefile("parry_probe_" .. tostring(os.time()) .. ".json", json)
    end)
    if type(setclipboard) == "function" then pcall(setclipboard, json) end
    local summary = string.format("E:%d S:%d L:%d", counts.TooEarly, counts.Success, counts.TooLate)
    status.Text = (saved and "Saved " or "Copied ") .. tostring(#attempts) .. " attempts | " .. summary
end

local function newAttempt(killer, cue)
    if currentAttempt and not currentAttempt.outcome then
        local cueAt = currentAttempt.lungeAt or currentAttempt.attackAt
        if cueAt and os.clock() - cueAt < 0.1 then return end
    end
    local distance, facing = geometry(killer)
    currentAttempt = {
        index = #attempts + 1,
        killer = killer.Name,
        selectedKiller = killer:GetAttribute("SelectedKiller"),
        cue = cue,
        lungeAt = cue == "lungehold" and os.clock() or nil,
        attackAt = cue == "attack" and os.clock() or nil,
        distanceAtCue = distance,
        facingAtCue = facing,
        parryAt = nil,
        outcome = nil,
    }
    table.insert(attempts, currentAttempt)
    logEvent("attempt_started", {
        attempt = currentAttempt.index,
        cue = cue,
        killer = killer.Name,
        distance = distance,
        facing = facing,
    })
    status.Text = string.format("Attempt #%d: %s | %.1f studs", currentAttempt.index, cue, distance or -1)
end

local function watchKiller(character, killer)
    disconnectAll(killerConnections)
    watchedCharacter = character
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5))
    if not animator then status.Text = "Killer Animator not found"; return end
    connect(animator.AnimationPlayed, function(track)
        if not running then return end
        local id = normalizeId(track.Animation and track.Animation.AnimationId)
        logEvent("killer_animation", {
            killer = killer.Name,
            id = id,
            name = track.Name,
            priority = track.Priority.Name,
            speed = track.Speed,
            length = track.Length,
            distance = select(1, geometry(killer)),
            facing = select(2, geometry(killer)),
        })
        connect(track.Stopped, function()
            logEvent("killer_animation_stopped", {
                killer = killer.Name,
                id = id,
                name = track.Name,
                position = track.TimePosition,
            })
        end, killerConnections)
        if id == LUNGE_ID then
            newAttempt(killer, "lungehold")
        elseif id == ATTACK_ID then
            if not currentAttempt or not currentAttempt.lungeAt or os.clock() - currentAttempt.lungeAt > 0.6 then
                newAttempt(killer, "attack")
            else
                currentAttempt.attackAt = os.clock()
                currentAttempt.lungeToAttackMs = math.floor((currentAttempt.attackAt - currentAttempt.lungeAt) * 1000 + 0.5)
                local distance, facing = geometry(killer)
                currentAttempt.distanceAtAttack = distance
                currentAttempt.facingAtAttack = facing
                logEvent("attack_linked", {
                    attempt = currentAttempt.index,
                    lungeToAttackMs = currentAttempt.lungeToAttackMs,
                    distance = distance,
                    facing = facing,
                })
                status.Text = string.format("Attempt #%d: attack | %.1f studs", currentAttempt.index, distance or -1)
            end
        end
    end, killerConnections)
end

local function refreshKiller()
    local killer = killerPlayer()
    if not killer then status.Text = "Waiting for Killer..."; return end
    if killer.Character and killer.Character ~= watchedCharacter then watchKiller(killer.Character, killer) end
end

local function recordParry(input)
    if not running then return end
    local isPointer = input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
    local point = isPointer and (input.UserInputType == Enum.UserInputType.Touch and input.Position or UserInputService:GetMouseLocation()) or nil
    local clicked = point and objectsAt(point.X, point.Y) or {}
    logEvent("input_began", {
        input = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name or input.UserInputType.Name,
        x = point and point.X or nil,
        y = point and point.Y or nil,
        gui = clicked,
    })
    if not currentAttempt or currentAttempt.parryAt then return end
    local target = selectedTarget()
    if not target then return end
    if not target.object or not target.object.Parent then target.object = resolve(target.root, target.path) end
    if not targetVisible(target) then return end
    if not isPointer then return end
    local position, size = target.object.AbsolutePosition, target.object.AbsoluteSize
    if point.X < position.X or point.X > position.X + size.X or point.Y < position.Y or point.Y > position.Y + size.Y then return end
    currentAttempt.parryAt = os.clock()
    currentAttempt.inputType = input.UserInputType.Name
    currentAttempt.fromLungeMs = currentAttempt.lungeAt and math.floor((currentAttempt.parryAt - currentAttempt.lungeAt) * 1000 + 0.5) or nil
    currentAttempt.fromAttackMs = currentAttempt.attackAt and math.floor((currentAttempt.parryAt - currentAttempt.attackAt) * 1000 + 0.5) or nil
    local killer = killerPlayer()
    currentAttempt.distanceAtParry, currentAttempt.facingAtParry = killer and geometry(killer) or nil, nil
    if killer then
        local distance, facing = geometry(killer)
        currentAttempt.distanceAtParry, currentAttempt.facingAtParry = distance, facing
    end
    logEvent("parry_pressed", {
        attempt = currentAttempt.index,
        target = target.name,
        fromLungeMs = currentAttempt.fromLungeMs,
        fromAttackMs = currentAttempt.fromAttackMs,
        distance = currentAttempt.distanceAtParry,
        facing = currentAttempt.facingAtParry,
        gui = clicked,
    })
    status.Text = string.format("Attempt #%d parry: L=%sms A=%sms\nChoose result", currentAttempt.index,
        tostring(currentAttempt.fromLungeMs), tostring(currentAttempt.fromAttackMs))
end

local function setOutcome(outcome)
    if not currentAttempt or not currentAttempt.parryAt then
        status.Text = "No recorded Parry input for current attempt"
        return
    end
    currentAttempt.outcome = outcome
    currentAttempt.completedUnix = os.time()
    logEvent("attempt_outcome", {
        attempt = currentAttempt.index,
        outcome = outcome,
        fromLungeMs = currentAttempt.fromLungeMs,
        fromAttackMs = currentAttempt.fromAttackMs,
    })
    status.Text = string.format("Attempt #%d = %s\nL=%sms A=%sms", currentAttempt.index, outcome,
        tostring(currentAttempt.fromLungeMs), tostring(currentAttempt.fromAttackMs))
    saveResults()
    currentAttempt = nil
end

connect(targetButton.MouseButton1Click, function()
    if #targets == 0 then return end
    selectedIndex = selectedIndex % #targets + 1
    targetButton.Text = "Target: " .. targets[selectedIndex].name
end)
connect(startButton.MouseButton1Click, function()
    running = not running
    startButton.Text = running and "Probe Running" or "Start Probe"
    startButton.BackgroundColor3 = running and Color3.fromRGB(45, 135, 100) or Color3.fromRGB(50, 56, 76)
    if running then
        if sessionStartedAt == 0 then
            sessionStartedAt = os.clock()
            timeline = {}
            attempts = {}
        end
        logEvent("probe_started", {target = selectedTarget() and selectedTarget().name})
        refreshKiller()
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            ownHealth = humanoid.Health
            connect(humanoid.HealthChanged, function(health)
                logEvent("survivor_health", {old = ownHealth, new = health, delta = health - ownHealth})
                ownHealth = health
            end, sessionConnections)
            connect(humanoid.StateChanged, function(oldState, newState)
                logEvent("survivor_state", {old = oldState.Name, new = newState.Name})
            end, sessionConnections)
        end
    else
        logEvent("probe_stopped")
        disconnectAll(sessionConnections)
        disconnectAll(killerConnections)
        watchedCharacter = nil
        saveResults()
    end
end)
connect(earlyButton.MouseButton1Click, function() setOutcome("TooEarly") end)
connect(successButton.MouseButton1Click, function() setOutcome("Success") end)
connect(lateButton.MouseButton1Click, function() setOutcome("TooLate") end)
connect(saveButton.MouseButton1Click, saveResults)
connect(UserInputService.InputBegan, recordParry)
connect(UserInputService.InputEnded, function(input)
    logEvent("input_ended", {
        input = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name or input.UserInputType.Name,
    })
end)
local function watchPlayer(player)
    connect(player.CharacterAdded, function() if running then task.wait(0.5); refreshKiller() end end)
end
for _, player in ipairs(Players:GetPlayers()) do watchPlayer(player) end
connect(Players.PlayerAdded, watchPlayer)
connect(RunService.Heartbeat, function()
    if running then refreshKiller() end
end)
connect(close.MouseButton1Click, function()
    if #attempts > 0 then saveResults() end
    cleanup()
end)

loadTargets()
