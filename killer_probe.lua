local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

if _G.YukiKillerProbeCleanup then pcall(_G.YukiKillerProbeCleanup) end

local connections, sessionConnections = {}, {}
local recording = false
local mode = "WalkIdle"
local startedAt = 0
local report = nil
local lastVelocityLog = 0
local healthCache = {}
local animationSeen = {}

local function disconnectAll(list)
    for _, connection in ipairs(list) do pcall(function() connection:Disconnect() end) end
    table.clear(list)
end

local screen = Instance.new("ScreenGui")
screen.Name = "YukiKillerProbe"
screen.ResetOnSpawn = false
screen.DisplayOrder = 999999
screen.Parent = CoreGui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 270, 0, 278)
panel.Position = UDim2.new(0, 12, 0.5, -139)
panel.BackgroundColor3 = Color3.fromRGB(14, 17, 25)
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = screen
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(230, 85, 95)
stroke.Transparency = 0.3

local title = Instance.new("TextLabel")
title.Position = UDim2.new(0, 10, 0, 4)
title.Size = UDim2.new(1, -42, 0, 28)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 215, 220)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Killer Attack Probe"
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
status.Size = UDim2.new(1, -20, 0, 48)
status.BackgroundColor3 = Color3.fromRGB(23, 27, 39)
status.BorderSizePixel = 0
status.Font = Enum.Font.Code
status.TextSize = 11
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(185, 195, 220)
status.Text = "Select a mode, then Start"
status.Parent = panel
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 7)

local function makeButton(text, y)
    local button = Instance.new("TextButton")
    button.Position = UDim2.new(0, 10, 0, y)
    button.Size = UDim2.new(1, -20, 0, 30)
    button.BackgroundColor3 = Color3.fromRGB(50, 56, 76)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.SourceSansSemibold
    button.TextSize = 13
    button.TextColor3 = Color3.fromRGB(235, 238, 250)
    button.Text = text
    button.Parent = panel
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
    return button
end

local modeButton = makeButton("Mode: Walk / Idle", 92)
local startButton = makeButton("Start Recording", 128)
local stopButton = makeButton("Stop & Save", 164)
local markerButton = makeButton("Add Manual HIT Marker", 200)
local copyButton = makeButton("Copy Latest JSON", 236)

local modes = {
    {id = "WalkIdle", label = "Walk / Idle"},
    {id = "HitEmpty", label = "Hit Empty"},
    {id = "HitPlayer", label = "Hit Player"},
}
local modeIndex = 1

local function cleanup()
    recording = false
    disconnectAll(sessionConnections)
    disconnectAll(connections)
    if screen.Parent then screen:Destroy() end
    _G.YukiKillerProbeCleanup = nil
end
_G.YukiKillerProbeCleanup = cleanup

local function elapsed()
    return math.floor((os.clock() - startedAt) * 1000 + 0.5)
end

local function rootOf(player)
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function distanceTo(player)
    local ownRoot, otherRoot = rootOf(LocalPlayer), rootOf(player)
    return ownRoot and otherRoot and math.floor((ownRoot.Position - otherRoot.Position).Magnitude * 10 + 0.5) / 10 or nil
end

local function nearbySnapshot()
    local snapshot = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            local distance = distanceTo(player)
            if humanoid and distance and distance <= 30 then
                table.insert(snapshot, {name = player.Name, distance = distance, health = humanoid.Health})
            end
        end
    end
    return snapshot
end

local function log(kind, data)
    if not recording or not report then return end
    data = data or {}
    data.t = elapsed()
    data.kind = kind
    table.insert(report.events, data)
    status.Text = string.format("REC %s | %d events | %.1fs", mode, #report.events, data.t / 1000)
end

local function snapshotAttributes(instance, prefix)
    for name, value in pairs(instance:GetAttributes()) do
        log("attribute_initial", {owner = prefix, name = name, value = tostring(value)})
    end
end

local function watchAttributes(instance, prefix)
    snapshotAttributes(instance, prefix)
    table.insert(sessionConnections, instance.AttributeChanged:Connect(function(name)
        log("attribute", {owner = prefix, name = name, value = tostring(instance:GetAttribute(name))})
    end))
end

local function watchAnimation(animator)
    table.insert(sessionConnections, animator.AnimationPlayed:Connect(function(track)
        local id = track.Animation and track.Animation.AnimationId or ""
        local key = id .. "|" .. tostring(track.Name)
        animationSeen[key] = (animationSeen[key] or 0) + 1
        log("animation", {
            id = id,
            name = track.Name,
            priority = track.Priority.Name,
            speed = track.Speed,
            length = track.Length,
            looped = track.Looped,
            count = animationSeen[key],
            nearby = nearbySnapshot(),
        })
        table.insert(sessionConnections, track.Stopped:Connect(function()
            log("animation_stopped", {id = id, name = track.Name, position = track.TimePosition})
        end))
        table.insert(sessionConnections, track.KeyframeReached:Connect(function(keyframe)
            log("animation_keyframe", {id = id, name = track.Name, keyframe = keyframe, position = track.TimePosition})
        end))
    end))
end

local function watchTool(tool)
    log("tool_found", {name = tool.Name})
    watchAttributes(tool, "Tool:" .. tool.Name)
    table.insert(sessionConnections, tool.Activated:Connect(function()
        log("tool_activated", {name = tool.Name, nearby = nearbySnapshot()})
    end))
    table.insert(sessionConnections, tool.Deactivated:Connect(function()
        log("tool_deactivated", {name = tool.Name})
    end))
end

local function watchSound(sound)
    table.insert(sessionConnections, sound.Played:Connect(function()
        log("sound", {name = sound.Name, id = sound.SoundId, volume = sound.Volume, parent = sound.Parent and sound.Parent:GetFullName()})
    end))
end

local function watchCharacter(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5))
    watchAttributes(LocalPlayer, "Player")
    watchAttributes(character, "Character")
    if humanoid then
        watchAttributes(humanoid, "Humanoid")
        table.insert(sessionConnections, humanoid.StateChanged:Connect(function(oldState, newState)
            log("humanoid_state", {old = oldState.Name, new = newState.Name})
        end))
    end
    if animator then watchAnimation(animator) end
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("Sound") then watchSound(descendant) end
        if descendant:IsA("Tool") then watchTool(descendant) end
    end
    table.insert(sessionConnections, character.DescendantAdded:Connect(function(descendant)
        local lower = descendant.Name:lower()
        if descendant:IsA("Sound") then watchSound(descendant) end
        if descendant:IsA("Tool") then watchTool(descendant) end
        if lower:find("hit") or lower:find("attack") or lower:find("damage") or lower:find("weapon") then
            log("descendant_added", {name = descendant.Name, class = descendant.ClassName, parent = descendant.Parent and descendant.Parent:GetFullName()})
        end
    end))
    table.insert(sessionConnections, character.DescendantRemoving:Connect(function(descendant)
        local lower = descendant.Name:lower()
        if lower:find("hit") or lower:find("attack") or lower:find("damage") or lower:find("weapon") then
            log("descendant_removed", {name = descendant.Name, class = descendant.ClassName})
        end
    end))
end

local function watchBackpack()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:WaitForChild("Backpack", 5)
    if not backpack then return end
    for _, child in ipairs(backpack:GetChildren()) do if child:IsA("Tool") then watchTool(child) end end
    table.insert(sessionConnections, backpack.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then watchTool(child) end
    end))
end

local function watchOtherHealth()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                healthCache[player] = humanoid.Health
                table.insert(sessionConnections, humanoid.HealthChanged:Connect(function(health)
                    local old = healthCache[player] or health
                    healthCache[player] = health
                    if health ~= old then
                        log("nearby_health", {name = player.Name, old = old, new = health, delta = health - old, distance = distanceTo(player)})
                    end
                end))
            end
        end
    end
end

local function startRecording()
    if recording then return end
    local character = LocalPlayer.Character
    if not character then status.Text = "No local character"; return end
    disconnectAll(sessionConnections)
    table.clear(healthCache)
    table.clear(animationSeen)
    startedAt = os.clock()
    report = {
        version = 1,
        mode = mode,
        placeId = game.PlaceId,
        jobId = game.JobId,
        player = LocalPlayer.Name,
        selectedKiller = LocalPlayer:GetAttribute("SelectedKiller"),
        startedUnix = os.time(),
        events = {},
    }
    recording = true
    startButton.Text = "Recording..."
    startButton.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    watchCharacter(character)
    watchBackpack()
    watchOtherHealth()
    table.insert(sessionConnections, UserInputService.InputBegan:Connect(function(input, processed)
        local inputName = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name or input.UserInputType.Name
        log("input_began", {input = inputName, processed = processed, nearby = nearbySnapshot()})
    end))
    table.insert(sessionConnections, UserInputService.InputEnded:Connect(function(input, processed)
        local inputName = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name or input.UserInputType.Name
        log("input_ended", {input = inputName, processed = processed})
    end))
    table.insert(sessionConnections, workspace.DescendantAdded:Connect(function(descendant)
        local lower = descendant.Name:lower()
        if lower:find("hitbox") or lower:find("damage") or lower:find("attack") then
            local part = descendant:IsA("BasePart") and descendant or descendant:FindFirstAncestorWhichIsA("BasePart")
            local ownRoot = rootOf(LocalPlayer)
            local distance = part and ownRoot and (part.Position - ownRoot.Position).Magnitude or nil
            if not distance or distance <= 35 then
                log("workspace_attack_object", {
                    name = descendant.Name,
                    class = descendant.ClassName,
                    parent = descendant.Parent and descendant.Parent:GetFullName(),
                    distance = distance,
                })
            end
        end
    end))
    log("session_start", {mode = mode, nearby = nearbySnapshot()})
    table.insert(sessionConnections, RunService.Heartbeat:Connect(function()
        if os.clock() - lastVelocityLog < 0.25 then return end
        lastVelocityLog = os.clock()
        local root = rootOf(LocalPlayer)
        if root then
            log("motion", {velocity = tostring(root.AssemblyLinearVelocity), nearby = nearbySnapshot()})
        end
    end))
end

local function stopRecording()
    if not recording or not report then return end
    log("session_stop", {nearby = nearbySnapshot()})
    recording = false
    disconnectAll(sessionConnections)
    report.durationMs = elapsed()
    startButton.Text = "Start Recording"
    startButton.BackgroundColor3 = Color3.fromRGB(50, 56, 76)
    local json = HttpService:JSONEncode(report)
    local stamp = tostring(os.time())
    local filename = "killer_probe_" .. mode .. "_" .. stamp .. ".json"
    local saved = type(writefile) == "function" and pcall(function()
        writefile(filename, json)
        writefile("killer_probe_latest.json", json)
    end)
    status.Text = saved and ("Saved " .. filename .. "\n" .. tostring(#report.events) .. " events")
        or ("File save failed; " .. tostring(#report.events) .. " events in memory")
end

table.insert(connections, modeButton.MouseButton1Click:Connect(function()
    if recording then return end
    modeIndex = modeIndex % #modes + 1
    mode = modes[modeIndex].id
    modeButton.Text = "Mode: " .. modes[modeIndex].label
end))
table.insert(connections, startButton.MouseButton1Click:Connect(startRecording))
table.insert(connections, stopButton.MouseButton1Click:Connect(stopRecording))
table.insert(connections, markerButton.MouseButton1Click:Connect(function()
    log("manual_hit_marker", {nearby = nearbySnapshot()})
end))
table.insert(connections, copyButton.MouseButton1Click:Connect(function()
    if not report then return end
    local json = HttpService:JSONEncode(report)
    if type(setclipboard) == "function" then
        pcall(setclipboard, json)
        status.Text = "Latest JSON copied"
    end
end))
table.insert(connections, close.MouseButton1Click:Connect(function()
    if recording then stopRecording() end
    cleanup()
end))
