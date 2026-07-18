--[[
    ╔═══════════════════════════════════════════════════╗
    ║   [CURE] Violence District — Multi Script         ║
    ║   Features: Fluent UI | ESP | Auto Parry          ║
    ║             Auto Perfect Gen | Crosshair          ║
    ╚═══════════════════════════════════════════════════╝
--]]

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- ─────────────────────────────────────────────────────
-- STARTUP NOTIFICATION
-- ─────────────────────────────────────────────────────
local startupScreen = Instance.new("ScreenGui")
startupScreen.Name = "VD_Startup"
startupScreen.ResetOnSpawn = false
startupScreen.DisplayOrder = 999999
startupScreen.Parent = CoreGui

local startupLabel = Instance.new("TextLabel")
startupLabel.Size = UDim2.new(0, 300, 0, 50)
startupLabel.Position = UDim2.new(0.5, -150, 0.5, -25)
startupLabel.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
startupLabel.BackgroundTransparency = 0.1
startupLabel.BorderSizePixel = 0
startupLabel.Font = Enum.Font.SourceSansSemibold
startupLabel.TextSize = 16
startupLabel.TextColor3 = Color3.fromRGB(220, 230, 255)
startupLabel.Text = "[CURE] Loading..."
startupLabel.Parent = startupScreen
Instance.new("UICorner", startupLabel).CornerRadius = UDim.new(0, 8)

-- ─────────────────────────────────────────────────────
-- FLUENT UI LOADER (with fallback)
-- ─────────────────────────────────────────────────────
local Fluent = nil
local FluentLoaded = false
pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua", true))()
    if Fluent and type(Fluent) == "table" and Fluent.CreateWindow then
        FluentLoaded = true
    end
end)
if not FluentLoaded then
    warn("[CURE] Fluent UI failed to load. Auto Parry & Generator will still work.")
    startupLabel.Text = "[CURE] Fluent UI unavailable\nAuto features will still run"
end

local Connections = {}
local Cleanups = {}

_G.VD_Cleanup = function()
    -- Disconnect all events
    for _, conn in ipairs(Connections) do
        if conn and conn.Disconnect then
            pcall(function() conn:Disconnect() end)
        end
    end
    -- Run custom cleanups (UI, crosshair, ESP)
    for _, cleanup in ipairs(Cleanups) do
        pcall(cleanup)
    end
    print("[Violence District] Old script session cleaned up successfully.")
end

-- Helper to register connections
local function regConn(conn)
    table.insert(Connections, conn)
    return conn
end

-- ─────────────────────────────────────────────────────
-- SERVICES
-- ─────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LP  = Players.LocalPlayer
local PG  = LP:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────────────
-- REMOTES (non-blocking)
-- ─────────────────────────────────────────────────────
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")

local GenRemotes, SkillCheckEvent, SkillCheckResult, KPRemotes, KSRemotes
local KingScourgeStart, KingScourgeHit, ItemRemotes, DaggerFolder, ParryEvent, ParryResultEvent
local AttacksFolder, BasicAttack

pcall(function()
    if not Remotes then return end
    GenRemotes = Remotes:FindFirstChild("Generator")
    SkillCheckEvent = GenRemotes and GenRemotes:FindFirstChild("SkillCheckEvent")
    SkillCheckResult = GenRemotes and GenRemotes:FindFirstChild("SkillCheckResultEvent")
    KPRemotes = Remotes:FindFirstChild("KillerPerks")
    KSRemotes = KPRemotes and KPRemotes:FindFirstChild("kingscourge")
    KingScourgeStart = KSRemotes and KSRemotes:FindFirstChild("KingScourgeStart")
    KingScourgeHit = KSRemotes and KSRemotes:FindFirstChild("KingScourgeHit")
    ItemRemotes = Remotes:FindFirstChild("Items")
    DaggerFolder = ItemRemotes and ItemRemotes:FindFirstChild("Parrying Dagger")
    ParryEvent = DaggerFolder and DaggerFolder:FindFirstChild("parry")
    ParryResultEvent = DaggerFolder and DaggerFolder:FindFirstChild("parryResult")
    AttacksFolder = Remotes:FindFirstChild("Attacks")
    BasicAttack = AttacksFolder and AttacksFolder:FindFirstChild("BasicAttack")
end)

-- ─────────────────────────────────────────────────────
-- CONFIG (live-edited by toggles/sliders)
-- ─────────────────────────────────────────────────────
local Cfg = {
    -- ESP
    ESP_Enabled    = true,
    ESP_Killer     = true,
    ESP_Survivor   = true,
    ESP_Spectator  = false,
    ESP_Generator  = true,
    ESP_Names      = true,
    ESP_Distance   = true,
    ESP_Highlight  = true,
    -- Combat
    AutoParry      = false,
    ParryRange     = 18,
    AutoEquip      = true,
    ParryCooldown  = 1.0,
    -- Generator
    AutoPerfectGen = true,
    GenDelayMin    = 0.15,
    GenDelayMax    = 0.35,
    -- Crosshair
    Crosshair      = true,
    CHColor        = Color3.fromRGB(0, 220, 255),
    CHSize         = 10,
    CHGap          = 5,
    CHThick        = 2,
}

-- ─────────────────────────────────────────────────────
-- CROSSHAIR
-- ─────────────────────────────────────────────────────
local CrosshairGui = nil

local function DestroyCrosshair()
    if CrosshairGui and CrosshairGui.Parent then
        CrosshairGui:Destroy()
        CrosshairGui = nil
    end
end
table.insert(Cleanups, DestroyCrosshair)

local function BuildCrosshair()
    DestroyCrosshair()
    if not Cfg.Crosshair then return end

    local gui = Instance.new("ScreenGui")
    gui.Name            = "VD_Crosshair"
    gui.ResetOnSpawn    = false
    gui.DisplayOrder    = 999
    gui.IgnoreGuiInset  = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = PG end
    CrosshairGui = gui

    local function bar(sx, sy, px, py)
        local f = Instance.new("Frame", gui)
        f.Size                  = UDim2.new(0, sx, 0, sy)
        f.Position              = UDim2.new(0.5, px, 0.5, py)
        f.BackgroundColor3      = Cfg.CHColor
        f.BorderSizePixel       = 0
        f.ZIndex                = 10
        -- thin drop shadow
        local shadow = Instance.new("Frame", f)
        shadow.Size             = UDim2.new(1, 2, 1, 2)
        shadow.Position         = UDim2.new(0, -1, 0, 1)
        shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
        shadow.BorderSizePixel  = 0
        shadow.BackgroundTransparency = 0.7
        shadow.ZIndex           = 9
        return f
    end

    local sz, gap, th = Cfg.CHSize, Cfg.CHGap, Cfg.CHThick
    -- left  right  top  bottom  dot
    bar(sz, th, -sz - gap, -th/2)
    bar(sz, th,  gap,       -th/2)
    bar(th, sz, -th/2, -sz - gap)
    bar(th, sz, -th/2,  gap)
    bar(th, th, -th/2, -th/2)
end

-- ─────────────────────────────────────────────────────
-- ESP SYSTEM
-- ─────────────────────────────────────────────────────
local ESPObjects = {}  -- [model] = { highlight, billboard }

local RoleColors = {
    Killer    = Color3.fromRGB(255, 70,  70),
    Survivors = Color3.fromRGB(70,  160, 255),
    Spectator = Color3.fromRGB(180, 180, 180),
    Generator = Color3.fromRGB(255, 210, 50),
    GenDone   = Color3.fromRGB(50,  255, 100),
}

local function CleanESP(model)
    if ESPObjects[model] then
        for _, v in ipairs(ESPObjects[model]) do
            pcall(function()
                if typeof(v) == "Instance" then
                    v:Destroy()
                elseif type(v) == "userdata" and v.Disconnect then
                    v:Disconnect()
                end
            end)
        end
        ESPObjects[model] = nil
    end
end

local function MakeESP(model, role)
    CleanESP(model)
    if not Cfg.ESP_Enabled then return end

    local color = RoleColors[role] or Color3.fromRGB(255,255,255)
    local objs  = {}
    ESPObjects[model] = objs

    -- Highlight (chams)
    if Cfg.ESP_Highlight then
        local hl = Instance.new("Highlight")
        hl.Adornee         = model
        hl.FillColor          = color
        hl.FillTransparency   = 0.75
        hl.OutlineColor       = color
        hl.OutlineTransparency = 0.0
        hl.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent          = model
        table.insert(objs, hl)
    end

    -- Billboard
    local adornee = model:FindFirstChild("HumanoidRootPart")
                 or model:FindFirstChild("RootPart")
                 or model:FindFirstChild("HitBox")
                 or model:FindFirstChildWhichIsA("BasePart")
    if not adornee then return end

    local bb = Instance.new("BillboardGui")
    bb.Name          = "VD_ESP"
    bb.Adornee       = adornee
    bb.AlwaysOnTop   = true
    bb.Size          = UDim2.new(0, 220, 0, 55)
    bb.StudsOffset   = Vector3.new(0, 3.2, 0)
    bb.Parent        = adornee
    table.insert(objs, bb)

    local bg = Instance.new("Frame", bb)
    bg.Size                    = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3        = Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency  = 0.55
    bg.BorderSizePixel         = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel", bg)
    lbl.Size                 = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3           = color
    lbl.TextStrokeColor3     = Color3.fromRGB(0,0,0)
    lbl.TextStrokeTransparency = 0.2
    lbl.Font                 = Enum.Font.GothamBold
    lbl.TextSize             = 13
    lbl.Text                 = ""

    -- Updater
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not model or not model.Parent then
            CleanESP(model)
            conn:Disconnect()
            return
        end

        local txt = ""
        local rootChar = LP.Character
        local hrp = rootChar and rootChar:FindFirstChild("HumanoidRootPart")

        if role == "Killer" or role == "Survivors" or role == "Spectator" then
            local player = Players:GetPlayerFromCharacter(model)
            local name   = player and player.DisplayName or model.Name
            if Cfg.ESP_Names then
                txt = ("[%s] %s"):format(role == "Survivors" and "SURVIVOR" or role:upper(), name)
            end
            if Cfg.ESP_Distance and hrp then
                local d = math.floor((adornee.Position - hrp.Position).Magnitude)
                txt = txt .. ("\n📍 %d studs"):format(d)
            end
            lbl.TextColor3 = color
        else
            -- Generator
            local prog = model:GetAttribute("RepairProgress") or 0
            local done = model:GetAttribute("Completed")
            local reg  = model:GetAttribute("Regressing")
            local repairing = (model:GetAttribute("PlayersRepairingCount") or 0) > 0

            local c  = done and RoleColors.GenDone or RoleColors.Generator
            txt = done and "⚙ Generator [✔ Done]"
                       or  ("⚙ Generator [%d%%]%s%s"):format(
                               math.floor(prog),
                               reg and " ↘" or "",
                               repairing and " 🔧" or "")

            if Cfg.ESP_Distance and hrp then
                local d = math.floor((adornee.Position - hrp.Position).Magnitude)
                txt = txt .. ("\n📍 %d studs"):format(d)
            end

            lbl.TextColor3 = c
            for _, o in ipairs(objs) do
                if typeof(o) == "Instance" and o:IsA("Highlight") then
                    o.FillColor    = c
                    o.OutlineColor = c
                    o.FillTransparency = 0.75
                    o.OutlineTransparency = 0.0
                end
            end
        end

        lbl.Text = txt
    end)
    table.insert(objs, conn)
end

local function RefreshESP()
    for model in pairs(ESPObjects) do
        CleanESP(model)
    end
    if not Cfg.ESP_Enabled then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local role = p.Team and p.Team.Name or "Unknown"
        local ok = (role == "Killer"   and Cfg.ESP_Killer)
                or (role == "Survivors" and Cfg.ESP_Survivor)
                or (role == "Spectator" and Cfg.ESP_Spectator)
        if ok and p.Character then
            MakeESP(p.Character, role)
        end
    end

    if Cfg.ESP_Generator then
        local gens = workspace:FindFirstChild("Map")
                 and workspace.Map:FindFirstChild("Generators")
        if gens then
            for _, g in ipairs(gens:GetChildren()) do
                if g.Name == "Generator" then
                    MakeESP(g, "Generator")
                end
            end
        end
    end
end

local function CleanAllESPObjects()
    for model in pairs(ESPObjects) do
        CleanESP(model)
    end
end
table.insert(Cleanups, CleanAllESPObjects)

-- Hook players
regConn(Players.PlayerAdded:Connect(function(p)
    regConn(p.CharacterAdded:Connect(function(char)
        task.wait(1)
        RefreshESP()
    end))
end))
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        regConn(p.CharacterAdded:Connect(function()
            task.wait(1)
            RefreshESP()
        end))
    end
end
regConn(Players.PlayerRemoving:Connect(function(p)
    if p.Character then CleanESP(p.Character) end
end))

-- Poll for new generators every 5s
task.spawn(function()
    while true do
        task.wait(5)
        if not Cfg.ESP_Generator or not Cfg.ESP_Enabled then continue end
        local gens = workspace:FindFirstChild("Map")
                 and workspace.Map:FindFirstChild("Generators")
        if gens then
            for _, g in ipairs(gens:GetChildren()) do
                if g.Name == "Generator" and not ESPObjects[g] then
                    MakeESP(g, "Generator")
                end
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────
-- AUTO PARRY
-- ─────────────────────────────────────────────────────
local parryCD = false

local function TryParry()
    if not Cfg.AutoParry then return end
    if parryCD then return end
    if not LP.Character then return end

    -- Must have Parrying Dagger
    local dagger = LP.Character:FindFirstChild("Parrying Dagger")
                or LP.Backpack:FindFirstChild("Parrying Dagger")
    if not dagger then return end

    -- Auto equip
    if Cfg.AutoEquip and dagger.Parent == LP.Backpack then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:EquipTool(dagger)
            task.wait(0.1)
        end
    end

    -- Must still be equipped
    if not LP.Character:FindFirstChild("Parrying Dagger") then return end

    if ParryEvent then
        parryCD = true
        ParryEvent:FireServer()
        task.delay(Cfg.ParryCooldown, function() parryCD = false end)
    end
end

local function WatchKillerAnimations(killerChar)
    local hum = killerChar:FindFirstChild("Humanoid")
    local anim = hum and hum:FindFirstChild("Animator")
    if not anim then return end

    regConn(anim.AnimationPlayed:Connect(function(track)
        if not Cfg.AutoParry then return end
        if not LP.Character then return end
        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
        local khrp = killerChar:FindFirstChild("HumanoidRootPart")
        if not hrp or not khrp then return end

        local dist = (hrp.Position - khrp.Position).Magnitude
        if dist > Cfg.ParryRange then return end

        -- Parry on any animation played by killer within range
        TryParry()
    end))
end

local function SetupAutoParry()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local role = p.Team and p.Team.Name or ""
            if role == "Killer" and p.Character then
                WatchKillerAnimations(p.Character)
            end
            regConn(p.CharacterAdded:Connect(function(char)
                task.wait(0.5)
                local r = p.Team and p.Team.Name or ""
                if r == "Killer" then WatchKillerAnimations(char) end
            end))
        end
    end

    regConn(Players.PlayerAdded:Connect(function(p)
        regConn(p.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            local r = p.Team and p.Team.Name or ""
            if r == "Killer" then WatchKillerAnimations(char) end
        end))
    end))
end

-- ─────────────────────────────────────────────────────
-- DUAL-LAYER AUTO PERFECT GENERATOR
-- Layer 1: Watch QTE appearance, snap line to success, simulate Space press.
-- Layer 2: Metamethod Hook (Failsafe) - Force success on any outgoing fail/neutral remotes.
-- ─────────────────────────────────────────────────────
do
    local genArg1, genArg2 = nil, nil
    local genWaiting       = false

    -- Capture generator QTE params on client event
    if SkillCheckEvent then
        regConn(SkillCheckEvent.OnClientEvent:Connect(function(p1, p2)
            genArg1   = p1
            genArg2   = p2
            genWaiting = true
        end))
    end

    local skillGui = PG:FindFirstChild("SkillCheckPromptGui")
    local Check    = skillGui and skillGui:FindFirstChild("Check")
    local Line     = Check and Check:FindFirstChild("Line")
    local Goal     = Check and Check:FindFirstChild("Goal")
    local lastVis  = false

    if Check and Line and Goal then
        regConn(RunService.Heartbeat:Connect(function()
            if not Cfg.AutoPerfectGen then
                lastVis = Check.Visible
                return
            end

            local vis = Check.Visible

            -- Detect when the SkillCheck UI turns visible
            if vis and not lastVis and genWaiting then
                genWaiting = false

                local delay = Cfg.GenDelayMin + math.random() * (Cfg.GenDelayMax - Cfg.GenDelayMin)

                task.delay(delay, function()
                    if not Cfg.AutoPerfectGen then return end
                    if not LP.Character then return end
                    local ci = LP.Character:FindFirstChild("CheckInterractable")
                    if not ci or not ci:GetAttribute("isRepairing") then return end

                    -- Snap line rotation into the success range (109 + Goal.Rotation)
                    Line.Rotation = 109 + Goal.Rotation

                    -- Simulate a real spacebar keystroke to trigger the game script's handler
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    end)
                end)
            end

            lastVis = vis
        end))
    end
end

-- ─────────────────────────────────────────────────────
-- DUAL-LAYER AUTO PERFECT GENERATOR (King's Scourge)
-- ─────────────────────────────────────────────────────
do
    local ksArg2    = nil
    local ksWaiting = false

    if KingScourgeStart then
        regConn(KingScourgeStart.OnClientEvent:Connect(function(p1, p2, p3)
            ksArg2   = p2
            ksWaiting = true
        end))
    end

    local skillGui = PG:FindFirstChild("SkillCheckPromptGui")
    local Check    = skillGui and skillGui:FindFirstChild("Check")
    local Line     = Check and Check:FindFirstChild("Line")
    local Goal     = Check and Check:FindFirstChild("Goal")
    local ksLastVis = false

    if Check and Line and Goal then
        regConn(RunService.Heartbeat:Connect(function()
            if not Cfg.AutoPerfectGen then
                ksLastVis = Check.Visible
                return
            end

            local vis = Check.Visible

            if vis and not ksLastVis and ksWaiting then
                ksWaiting = false
                local delay = Cfg.GenDelayMin + math.random() * (Cfg.GenDelayMax - Cfg.GenDelayMin)

                task.delay(delay, function()
                    if not Cfg.AutoPerfectGen then return end
                    if not LP.Character then return end
                    local ci = LP.Character:FindFirstChild("CheckInterractable")
                    if not ci or not ci:GetAttribute("isRepairing") then return end

                    Line.Rotation = 109 + Goal.Rotation

                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    end)
                end)
            end

            ksLastVis = vis
        end))
    end
end

-- ─────────────────────────────────────────────────────
-- LAYER 2: OUTGOING REMOTE METAMETHOD HOOK (FAILSAFE)
-- Automatically redirects any failed/neutral remote calls to "success"
-- Only works on executors that support hookmetamethod (e.g. Synapse, Script-Ware)
-- ─────────────────────────────────────────────────────
if type(hookmetamethod) == "function" and type(newcclosure) == "function" and type(getnamecallmethod) == "function" then
    local namecallHook = nil
    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args   = {...}

            if method == "FireServer" and not checkcaller() then
                -- Intercept standard Generator QTE results
                if self == SkillCheckResult then
                    if Cfg.AutoPerfectGen then
                        args[1] = "success"
                        args[2] = 1
                        return oldNamecall(self, table.unpack(args))
                    end
                -- Intercept King's Scourge QTE results
                elseif self == KingScourgeHit then
                    if Cfg.AutoPerfectGen then
                        args[2] = "success"
                        return oldNamecall(self, table.unpack(args))
                    end
                end
            end

            return oldNamecall(self, ...)
        end))
    end)
end

-- ─────────────────────────────────────────────────────
-- FLUENT UI WINDOW (only if Fluent loaded)
-- ─────────────────────────────────────────────────────
if FluentLoaded then
local FluentUI_Instance = nil
local Window = Fluent:CreateWindow({
    Title       = "[CURE] Violence District",
    SubTitle    = "Multi Script • by ValleryBot",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(600, 430),
    Acrylic     = true,
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift,
})
FluentUI_Instance = Window
table.insert(Cleanups, function()
    if FluentUI_Instance then
        pcall(function() FluentUI_Instance:Destroy() end)
    end
end)

local Tabs = {
    Main      = Window:AddTab({ Title = "Main",      Icon = "home"     }),
    ESP       = Window:AddTab({ Title = "ESP",        Icon = "eye"      }),
    Generator = Window:AddTab({ Title = "Generator",  Icon = "cpu"      }),
    Combat    = Window:AddTab({ Title = "Combat",     Icon = "swords"   }),
    Crosshair = Window:AddTab({ Title = "Crosshair",  Icon = "crosshair"}),
}

-- ── MAIN TAB ─────────────────────────────────────────
Tabs.Main:AddParagraph({
    Title   = "Welcome!",
    Content = "Press RightShift to toggle the UI.\nAll features are configured in their respective tabs."
})

Tabs.Main:AddButton({
    Title       = "Refresh ESP",
    Description = "Re-scan all players & generators.",
    Callback    = RefreshESP
})

Tabs.Main:AddButton({
    Title       = "Rebuild Crosshair",
    Description = "Recreate crosshair with current settings.",
    Callback    = BuildCrosshair
})

-- ── ESP TAB ──────────────────────────────────────────
local t_ESPEnabled = Tabs.ESP:AddToggle("ESPEnabled", {
    Title   = "Enable ESP",
    Default = Cfg.ESP_Enabled,
})
t_ESPEnabled:OnChanged(function()
    Cfg.ESP_Enabled = t_ESPEnabled.Value
    RefreshESP()
end)

local t_Killer = Tabs.ESP:AddToggle("ESPKiller", {
    Title   = "Show Killers",
    Default = Cfg.ESP_Killer,
})
t_Killer:OnChanged(function()
    Cfg.ESP_Killer = t_Killer.Value
    RefreshESP()
end)

local t_Surv = Tabs.ESP:AddToggle("ESPSurvivor", {
    Title   = "Show Survivors",
    Default = Cfg.ESP_Survivor,
})
t_Surv:OnChanged(function()
    Cfg.ESP_Survivor = t_Surv.Value
    RefreshESP()
end)

local t_Spec = Tabs.ESP:AddToggle("ESPSpectator", {
    Title   = "Show Spectators",
    Default = Cfg.ESP_Spectator,
})
t_Spec:OnChanged(function()
    Cfg.ESP_Spectator = t_Spec.Value
    RefreshESP()
end)

local t_Gen = Tabs.ESP:AddToggle("ESPGenerator", {
    Title   = "Show Generators (w/ Progress)",
    Default = Cfg.ESP_Generator,
})
t_Gen:OnChanged(function()
    Cfg.ESP_Generator = t_Gen.Value
    RefreshESP()
end)

local t_Names = Tabs.ESP:AddToggle("ESPNames", {
    Title   = "Show Names & Role",
    Default = Cfg.ESP_Names,
})
t_Names:OnChanged(function()
    Cfg.ESP_Names = t_Names.Value
end)

local t_Dist = Tabs.ESP:AddToggle("ESPDistance", {
    Title   = "Show Distance",
    Default = Cfg.ESP_Distance,
})
t_Dist:OnChanged(function()
    Cfg.ESP_Distance = t_Dist.Value
end)

local t_HL = Tabs.ESP:AddToggle("ESPHighlight", {
    Title   = "Highlight (Chams)",
    Default = Cfg.ESP_Highlight,
})
t_HL:OnChanged(function()
    Cfg.ESP_Highlight = t_HL.Value
    RefreshESP()
end)

-- ── GENERATOR TAB ────────────────────────────────────
Tabs.Generator:AddParagraph({
    Title   = "Auto Perfect Generator",
    Content = "Dual-layer system: snaps rotation + presses space. Outgoing fails/neutrals are hooked to succeed."
})

local t_AutoGen = Tabs.Generator:AddToggle("AutoPerfectGen", {
    Title   = "Auto Perfect Generator",
    Default = Cfg.AutoPerfectGen,
})
t_AutoGen:OnChanged(function()
    Cfg.AutoPerfectGen = t_AutoGen.Value
end)

Tabs.Generator:AddSlider("GenDelayMin", {
    Title       = "QTE Delay Min (seconds)",
    Description = "Minimum humanized delay before firing success.",
    Default     = Cfg.GenDelayMin,
    Min         = 0.05,
    Max         = 1.0,
    Rounding    = 2,
    Callback    = function(v) Cfg.GenDelayMin = v end,
})

Tabs.Generator:AddSlider("GenDelayMax", {
    Title       = "QTE Delay Max (seconds)",
    Description = "Maximum humanized delay before firing success.",
    Default     = Cfg.GenDelayMax,
    Min         = 0.1,
    Max         = 1.5,
    Rounding    = 2,
    Callback    = function(v) Cfg.GenDelayMax = v end,
})

-- ── COMBAT TAB ───────────────────────────────────────
Tabs.Combat:AddParagraph({
    Title   = "Auto Parry",
    Content = "Automatically parries when the killer plays an animation within range.\n⚠️ Requires Parrying Dagger in inventory or hand."
})

local t_AutoParry = Tabs.Combat:AddToggle("AutoParry", {
    Title   = "Auto Parry",
    Default = Cfg.AutoParry,
})
t_AutoParry:OnChanged(function()
    Cfg.AutoParry = t_AutoParry.Value
end)

local t_AutoEquip = Tabs.Combat:AddToggle("AutoEquipDagger", {
    Title   = "Auto Equip Parrying Dagger",
    Default = Cfg.AutoEquip,
    Description = "Equips dagger from backpack automatically if not held.",
})
t_AutoEquip:OnChanged(function()
    Cfg.AutoEquip = t_AutoEquip.Value
end)

Tabs.Combat:AddSlider("ParryRange", {
    Title       = "Parry Range (studs)",
    Description = "Maximum distance from killer to trigger auto parry.",
    Default     = Cfg.ParryRange,
    Min         = 5,
    Max         = 40,
    Rounding    = 1,
    Callback    = function(v) Cfg.ParryRange = v end,
})

Tabs.Combat:AddSlider("ParryCooldown", {
    Title       = "Parry Cooldown (seconds)",
    Description = "Minimum time between parry attempts.",
    Default     = Cfg.ParryCooldown,
    Min         = 0.5,
    Max         = 5.0,
    Rounding    = 1,
    Callback    = function(v) Cfg.ParryCooldown = v end,
})

Tabs.Combat:AddButton({
    Title       = "Manual Parry",
    Description = "Manually fire the parry event right now.",
    Callback    = function()
        if ParryEvent then
            ParryEvent:FireServer()
        end
    end
})

-- ── CROSSHAIR TAB ────────────────────────────────────
local t_CH = Tabs.Crosshair:AddToggle("CrosshairEnabled", {
    Title   = "Enable Crosshair",
    Default = Cfg.Crosshair,
})
t_CH:OnChanged(function()
    Cfg.Crosshair = t_CH.Value
    BuildCrosshair()
end)

Tabs.Crosshair:AddSlider("CHSize", {
    Title       = "Size (pixels)",
    Default     = Cfg.CHSize,
    Min         = 4,
    Max         = 30,
    Rounding    = 1,
    Callback    = function(v)
        Cfg.CHSize = v
        BuildCrosshair()
    end,
})

Tabs.Crosshair:AddSlider("CHGap", {
    Title       = "Gap (pixels)",
    Default     = Cfg.CHGap,
    Min         = 0,
    Max         = 20,
    Rounding    = 1,
    Callback    = function(v)
        Cfg.CHGap = v
        BuildCrosshair()
    end,
})

Tabs.Crosshair:AddSlider("CHThick", {
    Title       = "Thickness (pixels)",
    Default     = Cfg.CHThick,
    Min         = 1,
    Max         = 6,
    Rounding    = 1,
    Callback    = function(v)
        Cfg.CHThick = v
        BuildCrosshair()
    end,
})

Tabs.Crosshair:AddColorpicker("CHColor", {
    Title   = "Crosshair Color",
    Default = Cfg.CHColor,
    Callback = function(v)
        Cfg.CHColor = v
        BuildCrosshair()
    end,
})

-- ─────────────────────────────────────────────────────
-- STARTUP
-- ─────────────────────────────────────────────────────
BuildCrosshair()
SetupAutoParry()
RefreshESP()

-- Respawn handler
regConn(LP.CharacterAdded:Connect(function()
    task.wait(2)
    RefreshESP()
end))

if FluentLoaded then
    Fluent:Notify({
        Title    = "[CURE] Violence District",
        Content  = "Script loaded! Press RightShift to toggle menu.",
        Duration = 6,
    })
end

end -- end if FluentLoaded

-- Startup notification cleanup
task.delay(3, function()
    if startupScreen and startupScreen.Parent then startupScreen:Destroy() end
end)
