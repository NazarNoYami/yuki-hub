-- [CURE] Violence District - WindUI edition
-- Features preserved from hadiprasetiyo/violence-district-script.

if _G.VD_Cleanup then pcall(_G.VD_Cleanup) end

local Connections, Cleanups = {}, {}
local Running = true
local function regConn(connection)
    table.insert(Connections, connection)
    return connection
end

_G.VD_Cleanup = function()
    Running = false
    for _, connection in ipairs(Connections) do
        pcall(function() connection:Disconnect() end)
    end
    for i = #Cleanups, 1, -1 do pcall(Cleanups[i]) end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local function waitRemote(parent, name)
    return parent and parent:WaitForChild(name, 5)
end

local ItemRemotes = waitRemote(Remotes, "Items")
local DaggerFolder = ItemRemotes and ItemRemotes:FindFirstChild("Parrying Dagger")
local ParryEvent = DaggerFolder and DaggerFolder:FindFirstChild("parry")

local Cfg = {
    ESP_Enabled = false,
    ESP_Killer = true,
    ESP_Survivor = true,
    ESP_Spectator = false,
    ESP_Generator = true,
    ESP_Names = true,
    ESP_Distance = true,
    ESP_Highlight = true,
    AutoParry = false,
    ParryRange = 18,
    ShowParryRadius = true,
    AutoEquip = true,
    ParryCooldown = 1,
    AutoSkillCheck = false,
    SkillTolerance = 4,
    SkillLead = 0.04,
    Crosshair = false,
    CHColor = Color3.fromRGB(0, 220, 255),
    CHSize = 10,
    CHGap = 5,
    CHThick = 2,
}

local CrosshairGui
local function DestroyCrosshair()
    if CrosshairGui then pcall(function() CrosshairGui:Destroy() end); CrosshairGui = nil end
end
table.insert(Cleanups, DestroyCrosshair)

local StatusGui = Instance.new("ScreenGui")
StatusGui.Name = "VD_Status"
StatusGui.ResetOnSpawn = false
StatusGui.DisplayOrder = 998
pcall(function() StatusGui.Parent = CoreGui end)
if not StatusGui.Parent then StatusGui.Parent = PG end
table.insert(Cleanups, function() pcall(function() StatusGui:Destroy() end) end)

local StatusPanel = Instance.new("Frame")
StatusPanel.AnchorPoint = Vector2.new(1, 0)
StatusPanel.Position = UDim2.new(1, -12, 0, 54)
StatusPanel.Size = UDim2.new(0, 270, 0, 62)
StatusPanel.BackgroundColor3 = Color3.fromRGB(12, 16, 25)
StatusPanel.BackgroundTransparency = 0.12
StatusPanel.BorderSizePixel = 0
StatusPanel.Parent = StatusGui
local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = StatusPanel
local StatusStroke = Instance.new("UIStroke")
StatusStroke.Color = Color3.fromRGB(90, 140, 255)
StatusStroke.Transparency = 0.45
StatusStroke.Parent = StatusPanel

local function statusLabel(y)
    local label = Instance.new("TextLabel")
    label.Position = UDim2.new(0, 10, 0, y)
    label.Size = UDim2.new(1, -20, 0, 22)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(255, 95, 105)
    label.Parent = StatusPanel
    return label
end

local ParryStatus = statusLabel(7)
local SkillStatus = statusLabel(33)
ParryStatus.Text = "AUTO PARRY: OFF"
SkillStatus.Text = "SKILL REPLAY: OFF"

local ParryRadius
local function DestroyParryRadius()
    if ParryRadius then pcall(function() ParryRadius:Destroy() end); ParryRadius = nil end
end
table.insert(Cleanups, DestroyParryRadius)

local function UpdateParryRadius()
    if not Cfg.AutoParry or not Cfg.ShowParryRadius then DestroyParryRadius(); return end
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then DestroyParryRadius(); return end
    if not ParryRadius then
        ParryRadius = Instance.new("Part")
        ParryRadius.Name = "VD_ParryRadius"
        ParryRadius.Shape = Enum.PartType.Cylinder
        ParryRadius.Anchored = true
        ParryRadius.CanCollide = false
        ParryRadius.CanQuery = false
        ParryRadius.CanTouch = false
        ParryRadius.CastShadow = false
        ParryRadius.Material = Enum.Material.Neon
        ParryRadius.Color = Color3.fromRGB(80, 165, 255)
        ParryRadius.Transparency = 0.78
        ParryRadius.Parent = workspace
    end
    local diameter = Cfg.ParryRange * 2
    ParryRadius.Size = Vector3.new(0.08, diameter, diameter)
    ParryRadius.CFrame = CFrame.new(root.Position - Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90))
end

local function BuildCrosshair()
    DestroyCrosshair()
    if not Cfg.Crosshair then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "VD_Crosshair"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = PG end
    CrosshairGui = gui

    local function bar(sx, sy, px, py)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, sx, 0, sy)
        frame.Position = UDim2.new(0.5, px, 0.5, py)
        frame.BackgroundColor3 = Cfg.CHColor
        frame.BorderSizePixel = 0
        frame.ZIndex = 10
        frame.Parent = gui

        local shadow = Instance.new("Frame")
        shadow.Size = UDim2.new(1, 2, 1, 2)
        shadow.Position = UDim2.new(0, -1, 0, 1)
        shadow.BackgroundColor3 = Color3.new(0, 0, 0)
        shadow.BackgroundTransparency = 0.7
        shadow.BorderSizePixel = 0
        shadow.ZIndex = 9
        shadow.Parent = frame
    end

    local size, gap, thick = Cfg.CHSize, Cfg.CHGap, Cfg.CHThick
    bar(size, thick, -size - gap, -thick / 2)
    bar(size, thick, gap, -thick / 2)
    bar(thick, size, -thick / 2, -size - gap)
    bar(thick, size, -thick / 2, gap)
    bar(thick, thick, -thick / 2, -thick / 2)
end

local ESPObjects = {}
local RoleColors = {
    Killer = Color3.fromRGB(255, 70, 70),
    Survivors = Color3.fromRGB(70, 160, 255),
    Spectator = Color3.fromRGB(180, 180, 180),
    Generator = Color3.fromRGB(255, 210, 50),
    GenDone = Color3.fromRGB(50, 255, 100),
}

local function CleanESP(model)
    local objects = ESPObjects[model]
    if not objects then return end
    ESPObjects[model] = nil
    for _, object in ipairs(objects) do
        pcall(function()
            if typeof(object) == "Instance" then object:Destroy() else object:Disconnect() end
        end)
    end
end

local function MakeESP(model, role)
    CleanESP(model)
    if not Cfg.ESP_Enabled then return end

    local color = RoleColors[role] or Color3.new(1, 1, 1)
    local objects = {}
    ESPObjects[model] = objects

    if Cfg.ESP_Highlight then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = model
        highlight.FillColor = color
        highlight.FillTransparency = 0.75
        highlight.OutlineColor = color
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = model
        table.insert(objects, highlight)
    end

    local adornee = model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("RootPart")
        or model:FindFirstChild("HitBox")
        or model:FindFirstChildWhichIsA("BasePart")
    if not adornee then CleanESP(model); return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "VD_ESP"
    billboard.Adornee = adornee
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 220, 0, 55)
    billboard.StudsOffset = Vector3.new(0, 3.2, 0)
    billboard.Parent = adornee
    table.insert(objects, billboard)

    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.55
    background.BorderSizePixel = 0
    background.Parent = billboard
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = background

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextStrokeTransparency = 0.2
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Parent = background

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not model.Parent then CleanESP(model); return end
        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local text = ""
        if role ~= "Generator" then
            local player = Players:GetPlayerFromCharacter(model)
            if Cfg.ESP_Names then
                local roleName = role == "Survivors" and "SURVIVOR" or role:upper()
                text = ("[%s] %s"):format(roleName, player and player.DisplayName or model.Name)
            end
            if Cfg.ESP_Distance and root then
                text = text .. ("\n%d studs"):format(math.floor((adornee.Position - root.Position).Magnitude))
            end
        else
            local progress = model:GetAttribute("RepairProgress") or 0
            local done = model:GetAttribute("Completed")
            local regressing = model:GetAttribute("Regressing")
            local repairing = (model:GetAttribute("PlayersRepairingCount") or 0) > 0
            color = done and RoleColors.GenDone or RoleColors.Generator
            text = done and "Generator [Done]" or ("Generator [%d%%]%s%s"):format(
                math.floor(progress), regressing and " Regressing" or "", repairing and " Repairing" or "")
            if Cfg.ESP_Distance and root then
                text = text .. ("\n%d studs"):format(math.floor((adornee.Position - root.Position).Magnitude))
            end
            for _, object in ipairs(objects) do
                if typeof(object) == "Instance" and object:IsA("Highlight") then
                    object.FillColor, object.OutlineColor = color, color
                end
            end
        end
        label.TextColor3, label.Text = color, text
    end)
    table.insert(objects, connection)
end

local function RefreshESP()
    for model in pairs(ESPObjects) do CleanESP(model) end
    if not Cfg.ESP_Enabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local role = player.Team and player.Team.Name or "Unknown"
            local enabled = role == "Killer" and Cfg.ESP_Killer
                or role == "Survivors" and Cfg.ESP_Survivor
                or role == "Spectator" and Cfg.ESP_Spectator
            if enabled and player.Character then MakeESP(player.Character, role) end
        end
    end
    if Cfg.ESP_Generator then
        local map = workspace:FindFirstChild("Map")
        local generators = map and map:FindFirstChild("Generators")
        if generators then
            for _, generator in ipairs(generators:GetChildren()) do
                if generator.Name == "Generator" then MakeESP(generator, "Generator") end
            end
        end
    end
end

table.insert(Cleanups, function()
    for model in pairs(ESPObjects) do CleanESP(model) end
end)

local function watchPlayer(player)
    regConn(player.CharacterAdded:Connect(function()
        task.wait(1)
        if Running then RefreshESP() end
    end))
end
for _, player in ipairs(Players:GetPlayers()) do if player ~= LP then watchPlayer(player) end end
regConn(Players.PlayerAdded:Connect(watchPlayer))
regConn(Players.PlayerRemoving:Connect(function(player)
    if player.Character then CleanESP(player.Character) end
end))
regConn(LP.CharacterAdded:Connect(function()
    task.wait(2)
    if Running then RefreshESP() end
end))
task.spawn(function()
    while Running do
        task.wait(5)
        if Cfg.ESP_Enabled and Cfg.ESP_Generator then
            local map = workspace:FindFirstChild("Map")
            local generators = map and map:FindFirstChild("Generators")
            if generators then
                for _, generator in ipairs(generators:GetChildren()) do
                    if generator.Name == "Generator" and not ESPObjects[generator] then
                        MakeESP(generator, "Generator")
                    end
                end
            end
        end
    end
end)

local parryCD = false
local function TryParry()
    if not Cfg.AutoParry or parryCD or not LP.Character then return end
    local dagger = LP.Character:FindFirstChild("Parrying Dagger") or LP.Backpack:FindFirstChild("Parrying Dagger")
    if not dagger then return end
    if Cfg.AutoEquip and dagger.Parent == LP.Backpack then
        local humanoid = LP.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:EquipTool(dagger); task.wait(0.1) end
    end
    if not LP.Character:FindFirstChild("Parrying Dagger") or not ParryEvent then return end
    parryCD = true
    ParryEvent:FireServer()
    task.delay(Cfg.ParryCooldown, function() parryCD = false end)
end

local WatchedKillers = setmetatable({}, {__mode = "k"})
local function WatchKillerAnimations(character)
    if WatchedKillers[character] then return end
    local humanoid = character:WaitForChild("Humanoid", 5)
    local animator = humanoid and humanoid:WaitForChild("Animator", 5)
    if not animator then return end
    WatchedKillers[character] = true
    regConn(animator.AnimationPlayed:Connect(function()
        if not Cfg.AutoParry or not LP.Character then return end
        local root = LP.Character:FindFirstChild("HumanoidRootPart")
        local killerRoot = character:FindFirstChild("HumanoidRootPart")
        if root and killerRoot and (root.Position - killerRoot.Position).Magnitude <= Cfg.ParryRange then TryParry() end
    end))
end

local function SetupAutoParryPlayer(player)
    if player == LP then return end
    if player.Team and player.Team.Name == "Killer" and player.Character then
        WatchKillerAnimations(player.Character)
    end
    regConn(player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        if Running and player.Team and player.Team.Name == "Killer" then WatchKillerAnimations(character) end
    end))
end
for _, player in ipairs(Players:GetPlayers()) do SetupAutoParryPlayer(player) end
regConn(Players.PlayerAdded:Connect(SetupAutoParryPlayer))

local TARGETS_FILE = "yuki_button_targets.json"
local CALIBRATION_FILE = "yuki_skill_calibration.json"
local savedTargets, targetLabels, selectedTarget = {}, {}, nil
local calibrationOffset, calibrating

local function angularDifference(a, b)
    return (a - b + 180) % 360 - 180
end

local function loadCalibration()
    if type(readfile) ~= "function" then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CALIBRATION_FILE)) end)
    if ok and type(data) == "table" then calibrationOffset = tonumber(data.offset) end
end

local function saveCalibration(offset)
    calibrationOffset = offset
    if type(writefile) == "function" then
        pcall(writefile, CALIBRATION_FILE, HttpService:JSONEncode({offset = offset}))
    end
end

local function loadSavedTargets()
    savedTargets, targetLabels, selectedTarget = {}, {}, nil
    if type(readfile) ~= "function" then targetLabels = {"File API unavailable"}; return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(TARGETS_FILE)) end)
    if not ok or type(data) ~= "table" or #data == 0 then targetLabels = {"No saved buttons"}; return end
    for index, target in ipairs(data) do
        if type(target.path) == "table" and type(target.fingerprint) == "string" then
            local fingerprintState = target.fingerprint == "NO_IMAGE" and "NO IMG" or "IMG"
            target.label = (target.name or target.path[#target.path] or "Button")
                .. " #" .. index .. " [" .. fingerprintState .. "]"
            table.insert(savedTargets, target)
            table.insert(targetLabels, target.label)
        end
    end
    selectedTarget = savedTargets[1]
end

local function selectedRuntimeTarget()
    if not selectedTarget or type(_G.YukiButtonDetectorGetTargets) ~= "function" then return nil end
    for _, target in ipairs(_G.YukiButtonDetectorGetTargets()) do
        if target.key == selectedTarget.key then return target end
    end
end

local function UpdateStatus()
    if Cfg.AutoParry then
        local dagger = LP.Character and LP.Character:FindFirstChild("Parrying Dagger")
            or LP.Backpack:FindFirstChild("Parrying Dagger")
        ParryStatus.Text = dagger and ("AUTO PARRY: ON - READY | %d STUDS"):format(Cfg.ParryRange)
            or "AUTO PARRY: ON - WAITING FOR DAGGER"
        ParryStatus.TextColor3 = dagger and Color3.fromRGB(85, 255, 160) or Color3.fromRGB(255, 205, 90)
    else
        ParryStatus.Text = "AUTO PARRY: OFF"
        ParryStatus.TextColor3 = Color3.fromRGB(255, 95, 105)
    end

    if not Cfg.AutoSkillCheck then
        SkillStatus.Text = "SKILL REPLAY: OFF"
        SkillStatus.TextColor3 = Color3.fromRGB(255, 95, 105)
        return
    end
    local runtimeTarget = selectedRuntimeTarget()
    if not selectedTarget then
        SkillStatus.Text = "SKILL REPLAY: ON - RECORD BUTTON"
    elseif type(_G.YukiButtonDetectorGetTargets) ~= "function" then
        SkillStatus.Text = "SKILL REPLAY: ON - OPEN RECORDER"
    elseif not runtimeTarget then
        SkillStatus.Text = "SKILL REPLAY: ON - FINGERPRINT MISMATCH"
    elseif not calibrationOffset then
        SkillStatus.Text = "SKILL REPLAY: ON - CALIBRATE"
    else
        local imageState = selectedTarget.fingerprint == "NO_IMAGE" and "NO IMG" or "IMG READY"
        SkillStatus.Text = "SKILL REPLAY: ON - READY | " .. imageState
    end
    SkillStatus.TextColor3 = runtimeTarget and calibrationOffset and Color3.fromRGB(85, 255, 160)
        or Color3.fromRGB(255, 205, 90)
end

local function findSkillGui()
    return PG:FindFirstChild("SkillCheckPromptGui") or CoreGui:FindFirstChild("SkillCheckPromptGui")
end

loadCalibration()
loadSavedTargets()

regConn(UserInputService.InputBegan:Connect(function(input, processed)
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
    saveCalibration(angularDifference(line.AbsoluteRotation % 360, goal.AbsoluteRotation % 360))
    calibrating = false
    warn(string.format("[CURE] Skill timing saved: %.2f degrees", calibrationOffset))
end))

local skillGui, previousRotation, previousError
local angularVelocity = 0
local clickedPrompt = false
regConn(RunService.RenderStepped:Connect(function(dt)
    UpdateParryRadius()
    UpdateStatus()
    local target = selectedRuntimeTarget()
    if not Cfg.AutoSkillCheck or not target or not calibrationOffset then
        skillGui, previousRotation, previousError = nil, nil, nil
        angularVelocity, clickedPrompt = 0, false
        return
    end
    if not skillGui or not skillGui.Parent then
        skillGui = findSkillGui()
        previousRotation, previousError, angularVelocity, clickedPrompt = nil, nil, 0, false
    end
    if not skillGui or not skillGui.Enabled then
        previousRotation, previousError, angularVelocity, clickedPrompt = nil, nil, 0, false
        return
    end
    local check = skillGui:FindFirstChild("Check", true)
    local line = skillGui:FindFirstChild("Line", true)
    local goal = skillGui:FindFirstChild("Goal", true)
    if not check or not check:IsA("GuiObject") or not check.Visible or not line or not goal then return end
    if goal.Rotation == 0 then
        previousRotation, previousError, angularVelocity, clickedPrompt = nil, nil, 0, false
        return
    end

    local rotation = line.AbsoluteRotation % 360
    if previousRotation and dt > 0 then
        local measured = angularDifference(rotation, previousRotation) / dt
        angularVelocity = angularVelocity == 0 and measured or angularVelocity * 0.65 + measured * 0.35
    end
    local predicted = rotation + angularVelocity * Cfg.SkillLead
    local difference = angularDifference(predicted, goal.AbsoluteRotation % 360)
    local skillError = angularDifference(difference, calibrationOffset)
    local crossed = previousError
        and math.abs(angularDifference(skillError, previousError)) < 45
        and previousError * skillError <= 0
    if not clickedPrompt and (math.abs(skillError) <= Cfg.SkillTolerance or crossed) then
        clickedPrompt = true
        pcall(_G.YukiButtonDetectorClick, target)
    end
    previousRotation, previousError = rotation, skillError
end))

local WINDUI_COMMIT = "7b1d561cf658da1f2f49e700cf52963e7bdcb23a"
local WindUIURL = "https://raw.githubusercontent.com/Footagesus/WindUI/" .. WINDUI_COMMIT .. "/dist/main.lua"
local WindUI = loadstring(game:HttpGet(WindUIURL))()
local Window = WindUI:CreateWindow({
    Title = "[CURE] Violence District",
    Folder = "CUREViolenceDistrict",
    Icon = "solar:shield-bold-duotone",
    NewElements = true,
    HideSearchBar = true,
    Topbar = {Height = 42, ButtonsType = "Default"},
})
table.insert(Cleanups, function() pcall(function() Window:Destroy() end) end)

local function tab(title, icon)
    return Window:Tab({Title = title, Icon = icon, IconColor = Color3.fromHex("#8EA8FF"), Border = true})
end
local Tabs = {
    Main = tab("Main", "solar:home-2-bold-duotone"),
    ESP = tab("ESP", "solar:eye-bold-duotone"),
    Generator = tab("Generator", "solar:cpu-bold-duotone"),
    Combat = tab("Combat", "solar:sword-bold-duotone"),
    Crosshair = tab("Crosshair", "solar:target-bold-duotone"),
}

local main = Tabs.Main:Section({Title = "CURE"})
main:Button({Title = "Refresh ESP", Desc = "Re-scan players and generators", Callback = RefreshESP})
main:Space()
main:Button({Title = "Rebuild Crosshair", Desc = "Apply current crosshair settings", Callback = BuildCrosshair})
main:Space()
main:Button({Title = "Unload", Color = Color3.fromRGB(255, 90, 105), Callback = function()
    _G.VD_Cleanup()
    _G.VD_Cleanup = nil
end})

local esp = Tabs.ESP:Section({Title = "ESP"})
esp:Toggle({Title = "Enable ESP", Default = Cfg.ESP_Enabled, Callback = function(value)
    Cfg.ESP_Enabled = value
    RefreshESP()
end})
esp:Space()
esp:Toggle({Title = "Show Killers", Default = Cfg.ESP_Killer, Callback = function(value)
    Cfg.ESP_Killer = value
    RefreshESP()
end})
esp:Space()
esp:Toggle({Title = "Show Survivors", Default = Cfg.ESP_Survivor, Callback = function(value)
    Cfg.ESP_Survivor = value
    RefreshESP()
end})
esp:Space()
esp:Toggle({Title = "Show Spectators", Default = Cfg.ESP_Spectator, Callback = function(value)
    Cfg.ESP_Spectator = value
    RefreshESP()
end})
esp:Space()
esp:Toggle({Title = "Show Generators", Desc = "Includes progress and state", Default = Cfg.ESP_Generator,
    Callback = function(value)
        Cfg.ESP_Generator = value
        RefreshESP()
    end,
})
esp:Space()
esp:Toggle({Title = "Show Names and Roles", Default = Cfg.ESP_Names, Callback = function(value)
    Cfg.ESP_Names = value
end})
esp:Space()
esp:Toggle({Title = "Show Distance", Default = Cfg.ESP_Distance, Callback = function(value)
    Cfg.ESP_Distance = value
end})
esp:Space()
esp:Toggle({Title = "Highlight", Desc = "Always-on-top chams", Default = Cfg.ESP_Highlight,
    Callback = function(value)
        Cfg.ESP_Highlight = value
        RefreshESP()
    end,
})

local generator = Tabs.Generator:Section({Title = "Recorded Skill Check"})
local targetDropdown = generator:Dropdown({Title = "Recorded Button", Values = targetLabels, Value = 1,
    Callback = function(value)
        for _, target in ipairs(savedTargets) do
            if target.label == value then selectedTarget = target; break end
        end
    end,
})
generator:Space()
generator:Button({Title = "Open Button Recorder", Desc = "Record the skill-check button you press",
    Callback = function()
        local commit = "535ffdb8fcfef4eb272e4ee41fac2d1fa23c0343"
        local url = "https://raw.githubusercontent.com/NazarNoYami/yuki-hub/" .. commit .. "/button_detector.lua"
        loadstring(game:HttpGet(url))()
    end,
})
generator:Space()
generator:Button({Title = "Reload Recorded Buttons", Desc = "Reload yuki_button_targets.json", Callback = function()
    loadSavedTargets()
    pcall(function() targetDropdown:Refresh(targetLabels) end)
end})
generator:Space()
generator:Button({Title = "Calibrate Next Manual Hit", Desc = "Arm once, then hit one skill check normally",
    Callback = function()
        calibrating = true
        warn("[CURE] Calibration armed; complete one skill check manually")
    end,
})
generator:Space()
generator:Button({Title = "Clear Calibration", Callback = function()
    calibrationOffset, calibrating = nil, false
    if type(writefile) == "function" then pcall(writefile, CALIBRATION_FILE, "{}") end
end})
generator:Space()
generator:Toggle({Title = "Auto Skill Check", Desc = "Replays your recorded click at your calibrated timing",
    Default = Cfg.AutoSkillCheck,
    Callback = function(value)
        if value and not selectedRuntimeTarget() then warn("[CURE] Open recorder and record a button first") end
        if value and not calibrationOffset then warn("[CURE] Calibrate one manual hit first") end
        Cfg.AutoSkillCheck = value
    end,
})
generator:Space()
generator:Slider({Title = "Accuracy Window", Desc = "Lower is more precise", Width = 200,
    Value = {Min = 1, Max = 15, Default = Cfg.SkillTolerance}, Step = 1,
    Callback = function(value) Cfg.SkillTolerance = value end,
})
generator:Space()
generator:Slider({Title = "Input Lead", Desc = "Click latency compensation in milliseconds", Width = 200,
    Value = {Min = 0, Max = 120, Default = Cfg.SkillLead * 1000}, Step = 5,
    Callback = function(value) Cfg.SkillLead = value / 1000 end,
})

local combat = Tabs.Combat:Section({Title = "Auto Parry"})
combat:Toggle({Title = "Enable", Desc = "Requires Parrying Dagger", Default = Cfg.AutoParry,
    Callback = function(value)
        Cfg.AutoParry = value
        if not value then DestroyParryRadius() end
        UpdateStatus()
    end,
})
combat:Space()
combat:Toggle({Title = "Show Parry Radius", Desc = "Circle under your character", Default = Cfg.ShowParryRadius,
    Callback = function(value)
        Cfg.ShowParryRadius = value
        if not value then DestroyParryRadius() end
    end,
})
combat:Space()
combat:Toggle({Title = "Auto Equip Dagger", Default = Cfg.AutoEquip, Callback = function(value)
    Cfg.AutoEquip = value
end})
combat:Space()
combat:Slider({Title = "Parry Range", Width = 200,
    Value = {Min = 5, Max = 40, Default = Cfg.ParryRange}, Step = 1,
    Callback = function(value) Cfg.ParryRange = value; UpdateStatus() end,
})
combat:Space()
combat:Slider({Title = "Parry Cooldown", Width = 200,
    Value = {Min = 0.5, Max = 5, Default = Cfg.ParryCooldown}, Step = 0.1,
    Callback = function(value) Cfg.ParryCooldown = value end,
})
combat:Space()
combat:Button({Title = "Manual Parry", Callback = function() if ParryEvent then ParryEvent:FireServer() end end})

local crosshair = Tabs.Crosshair:Section({Title = "Crosshair"})
crosshair:Toggle({Title = "Enable", Default = Cfg.Crosshair, Callback = function(value)
    Cfg.Crosshair = value
    BuildCrosshair()
end})
crosshair:Space()
crosshair:Slider({Title = "Size", Width = 200, Value = {Min = 4, Max = 30, Default = Cfg.CHSize}, Step = 1,
    Callback = function(value) Cfg.CHSize = value; BuildCrosshair() end,
})
crosshair:Space()
crosshair:Slider({Title = "Gap", Width = 200, Value = {Min = 0, Max = 20, Default = Cfg.CHGap}, Step = 1,
    Callback = function(value) Cfg.CHGap = value; BuildCrosshair() end,
})
crosshair:Space()
crosshair:Slider({Title = "Thickness", Width = 200,
    Value = {Min = 1, Max = 6, Default = Cfg.CHThick}, Step = 1,
    Callback = function(value) Cfg.CHThick = value; BuildCrosshair() end,
})
crosshair:Space()
crosshair:Colorpicker({Title = "Color", Default = Cfg.CHColor, Callback = function(value)
    Cfg.CHColor = value
    BuildCrosshair()
end})

BuildCrosshair()
RefreshESP()
