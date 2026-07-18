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
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local function waitRemote(parent, name)
    return parent and parent:WaitForChild(name, 5)
end

local GenRemotes = waitRemote(Remotes, "Generator")
local SkillCheckEvent = waitRemote(GenRemotes, "SkillCheckEvent")
local SkillCheckResult = waitRemote(GenRemotes, "SkillCheckResultEvent")
local KPRemotes = Remotes and Remotes:FindFirstChild("KillerPerks")
local KSRemotes = KPRemotes and KPRemotes:FindFirstChild("kingscourge")
local KingScourgeStart = KSRemotes and KSRemotes:FindFirstChild("KingScourgeStart")
local KingScourgeHit = KSRemotes and KSRemotes:FindFirstChild("KingScourgeHit")
local ItemRemotes = waitRemote(Remotes, "Items")
local DaggerFolder = ItemRemotes and ItemRemotes:FindFirstChild("Parrying Dagger")
local ParryEvent = DaggerFolder and DaggerFolder:FindFirstChild("parry")

local Cfg = {
    ESP_Enabled = true,
    ESP_Killer = true,
    ESP_Survivor = true,
    ESP_Spectator = false,
    ESP_Generator = true,
    ESP_Names = true,
    ESP_Distance = true,
    ESP_Highlight = true,
    AutoParry = false,
    ParryRange = 18,
    AutoEquip = true,
    ParryCooldown = 1,
    AutoPerfectGen = true,
    GenDelayMin = 0.15,
    GenDelayMax = 0.35,
    Crosshair = true,
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

local genWaiting, ksWaiting = false, false
if SkillCheckEvent then regConn(SkillCheckEvent.OnClientEvent:Connect(function() genWaiting = true end)) end
if KingScourgeStart then regConn(KingScourgeStart.OnClientEvent:Connect(function() ksWaiting = true end)) end

local function setupSkillCheck(source)
    local skillGui = PG:WaitForChild("SkillCheckPromptGui", 5)
    local check = skillGui and skillGui:WaitForChild("Check", 5)
    local line = check and check:WaitForChild("Line", 5)
    local goal = check and check:WaitForChild("Goal", 5)
    if not check or not line or not goal then return end
    local lastVisible = false
    regConn(RunService.Heartbeat:Connect(function()
        local visible = check.Visible
        local waiting = source == "generator" and genWaiting or ksWaiting
        if Cfg.AutoPerfectGen and visible and not lastVisible and waiting then
            if source == "generator" then genWaiting = false else ksWaiting = false end
            local minimum, maximum = Cfg.GenDelayMin, Cfg.GenDelayMax
            local delayTime = minimum + math.random() * (math.max(minimum, maximum) - minimum)
            task.delay(delayTime, function()
                if not Running or not Cfg.AutoPerfectGen or not LP.Character or not check.Visible then return end
                local interactable = LP.Character:FindFirstChild("CheckInterractable")
                if not interactable or not interactable:GetAttribute("isRepairing") then return end
                line.Rotation = 109 + goal.Rotation
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                end)
            end)
        end
        lastVisible = visible
    end))
end
setupSkillCheck("generator")
setupSkillCheck("kingscourge")

if type(hookmetamethod) == "function" and type(newcclosure) == "function" and type(getnamecallmethod) == "function" then
    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local args = {...}
            if getnamecallmethod() == "FireServer" and not checkcaller() and Running and Cfg.AutoPerfectGen then
                if self == SkillCheckResult then
                    args[1], args[2] = "success", 1
                    return oldNamecall(self, table.unpack(args))
                elseif self == KingScourgeHit then
                    args[2] = "success"
                    return oldNamecall(self, table.unpack(args))
                end
            end
            return oldNamecall(self, ...)
        end))
    end)
end

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

local generator = Tabs.Generator:Section({Title = "Auto Perfect Generator"})
generator:Toggle({Title = "Enable", Desc = "Rotation snap, Space input, and remote failsafe",
    Default = Cfg.AutoPerfectGen,
    Callback = function(value) Cfg.AutoPerfectGen = value end,
})
generator:Space()
generator:Slider({Title = "Minimum Delay", Desc = "Humanized delay in seconds", Width = 200,
    Value = {Min = 0.05, Max = 1, Default = Cfg.GenDelayMin}, Step = 0.01,
    Callback = function(value) Cfg.GenDelayMin = value end,
})
generator:Space()
generator:Slider({Title = "Maximum Delay", Desc = "Humanized delay in seconds", Width = 200,
    Value = {Min = 0.1, Max = 1.5, Default = Cfg.GenDelayMax}, Step = 0.01,
    Callback = function(value) Cfg.GenDelayMax = value end,
})

local combat = Tabs.Combat:Section({Title = "Auto Parry"})
combat:Toggle({Title = "Enable", Desc = "Requires Parrying Dagger", Default = Cfg.AutoParry,
    Callback = function(value) Cfg.AutoParry = value end,
})
combat:Space()
combat:Toggle({Title = "Auto Equip Dagger", Default = Cfg.AutoEquip, Callback = function(value)
    Cfg.AutoEquip = value
end})
combat:Space()
combat:Slider({Title = "Parry Range", Width = 200,
    Value = {Min = 5, Max = 40, Default = Cfg.ParryRange}, Step = 1,
    Callback = function(value) Cfg.ParryRange = value end,
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
