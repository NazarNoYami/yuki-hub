--[[
    ╔═══════════════════════════════════════════════════╗
    ║   [CURE] Violence District — Multi Script         ║
    ║   WindUI | Auto Parry | Auto Gen | ESP           ║
    ╚═══════════════════════════════════════════════════╝
--]]

if _G.VD_Cleanup then pcall(_G.VD_Cleanup) end

local Connections = {}
local Cleanups = {}
_G.VD_Cleanup = function()
    for _, conn in ipairs(Connections) do
        if conn and conn.Disconnect then pcall(function() conn:Disconnect() end) end
    end
    for _, c in ipairs(Cleanups) do pcall(c) end
end

local function regConn(conn) table.insert(Connections, conn); return conn end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- ── Remotes (non-blocking) ──
local Remotes, GenRemotes, SkillCheckEvent, SkillCheckResult, ParryEvent, BasicAttack
local KingScourgeStart, KingScourgeHit
pcall(function()
    Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not Remotes then return end
    local gen = Remotes:FindFirstChild("Generator")
    SkillCheckEvent = gen and gen:FindFirstChild("SkillCheckEvent")
    SkillCheckResult = gen and gen:FindFirstChild("SkillCheckResultEvent")
    local kp = Remotes:FindFirstChild("KillerPerks")
    local ks = kp and kp:FindFirstChild("kingscourge")
    KingScourgeStart = ks and ks:FindFirstChild("KingScourgeStart")
    KingScourgeHit = ks and ks:FindFirstChild("KingScourgeHit")
    local items = Remotes:FindFirstChild("Items")
    local df = items and items:FindFirstChild("Parrying Dagger")
    ParryEvent = df and df:FindFirstChild("parry")
    local atk = Remotes:FindFirstChild("Attacks")
    BasicAttack = atk and atk:FindFirstChild("BasicAttack")
end)

-- ── Config ──
local Cfg = {
    ESP_Killer = true, ESP_Survivor = true, ESP_Spectator = false, ESP_Generator = true,
    ESP_Names = true, ESP_Distance = true, ESP_Highlight = true,
    AutoParry = false, ParryRange = 18, AutoEquip = true, ParryCooldown = 1.0,
    AutoPerfectGen = true, GenDelayMin = 0.15, GenDelayMax = 0.35,
    Crosshair = true, CHColor = Color3.fromRGB(0, 220, 255), CHSize = 10, CHGap = 5, CHThick = 2,
}

-- ── Crosshair ──
local CrosshairGui
local function DestroyCrosshair() if CrosshairGui and CrosshairGui.Parent then CrosshairGui:Destroy(); CrosshairGui = nil end end
table.insert(Cleanups, DestroyCrosshair)
local function BuildCrosshair()
    DestroyCrosshair()
    if not Cfg.Crosshair then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "VD_Crosshair"; gui.ResetOnSpawn = false; gui.DisplayOrder = 999; gui.Parent = CoreGui
    CrosshairGui = gui
    local function bar(sx, sy, px, py)
        local f = Instance.new("Frame", gui)
        f.Size = UDim2.new(0, sx, 0, sy); f.Position = UDim2.new(0.5, px, 0.5, py)
        f.BackgroundColor3 = Cfg.CHColor; f.BorderSizePixel = 0; f.ZIndex = 10
        local s = Instance.new("Frame", f)
        s.Size = UDim2.new(1, 2, 1, 2); s.Position = UDim2.new(0, -1, 0, 1)
        s.BackgroundColor3 = Color3.new(0, 0, 0); s.BorderSizePixel = 0; s.BackgroundTransparency = 0.7; s.ZIndex = 9
    end
    local sz, gap, th = Cfg.CHSize, Cfg.CHGap, Cfg.CHThick
    bar(sz, th, -sz - gap, -th / 2); bar(sz, th, gap, -th / 2)
    bar(th, sz, -th / 2, -sz - gap); bar(th, sz, -th / 2, gap)
    bar(th, th, -th / 2, -th / 2)
end

-- ── ESP ──
local ESPObjects = {}
local RoleColors = {Killer = Color3.fromRGB(255, 70, 70), Survivors = Color3.fromRGB(70, 160, 255), Spectator = Color3.fromRGB(180, 180, 180), Generator = Color3.fromRGB(255, 210, 50), GenDone = Color3.fromRGB(50, 255, 100)}
local function CleanESP(model)
    if ESPObjects[model] then
        for _, v in ipairs(ESPObjects[model]) do pcall(function() if typeof(v) == "Instance" then v:Destroy() elseif type(v) == "userdata" and v.Disconnect then v:Disconnect() end end) end
        ESPObjects[model] = nil
    end
end
local function MakeESP(model, role)
    CleanESP(model); if not Cfg.ESP_Generator and role == "Generator" then return end
    local color = RoleColors[role] or Color3.new(1, 1, 1)
    local objs = {}; ESPObjects[model] = objs
    if Cfg.ESP_Highlight and role ~= "Generator" then
        local hl = Instance.new("Highlight")
        hl.Adornee = model; hl.FillColor = color; hl.FillTransparency = 0.75; hl.OutlineColor = color; hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = model; table.insert(objs, hl)
    end
    local adornee = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart") or model:FindFirstChild("HitBox") or model:FindFirstChildWhichIsA("BasePart")
    if not adornee then return end
    local bb = Instance.new("BillboardGui"); bb.Name = "VD_ESP"; bb.Adornee = adornee; bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 220, 0, 55); bb.StudsOffset = Vector3.new(0, 3.2, 0); bb.Parent = adornee; table.insert(objs, bb)
    local bg = Instance.new("Frame", bb); bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = Color3.new(0, 0, 0)
    bg.BackgroundTransparency = 0.55; bg.BorderSizePixel = 0; Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)
    local lbl = Instance.new("TextLabel", bg); lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.TextColor3 = color; lbl.TextStrokeColor3 = Color3.new(0, 0, 0); lbl.TextStrokeTransparency = 0.2
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13; lbl.Text = ""
    local conn = RunService.Heartbeat:Connect(function()
        if not model or not model.Parent then CleanESP(model); conn:Disconnect(); return end
        local txt = ""; local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if role ~= "Generator" then
            local p = Players:GetPlayerFromCharacter(model); local name = p and p.DisplayName or model.Name
            if Cfg.ESP_Names then txt = ("[%s] %s"):format(role == "Survivors" and "SURVIVOR" or role:upper(), name) end
            if Cfg.ESP_Distance and hrp then txt = txt .. ("\n%ds"):format(math.floor((adornee.Position - hrp.Position).Magnitude)) end
            lbl.TextColor3 = color
        else
            local prog = model:GetAttribute("RepairProgress") or 0; local done = model:GetAttribute("Completed")
            local reg = model:GetAttribute("Regressing"); local repairing = (model:GetAttribute("PlayersRepairingCount") or 0) > 0
            local c = done and RoleColors.GenDone or RoleColors.Generator
            txt = done and "Generator DONE" or ("Generator %d%%%s%s"):format(math.floor(prog), reg and " reg" or "", repairing and " *" or "")
            if Cfg.ESP_Distance and hrp then txt = txt .. ("\n%ds"):format(math.floor((adornee.Position - hrp.Position).Magnitude)) end
            lbl.TextColor3 = c
            for _, o in ipairs(objs) do if typeof(o) == "Instance" and o:IsA("Highlight") then o.FillColor = c; o.OutlineColor = c; o.FillTransparency = 0.75; o.OutlineTransparency = 0 end end
        end
        lbl.Text = txt
    end)
    table.insert(objs, conn)
end
local function RefreshESP()
    for m in pairs(ESPObjects) do CleanESP(m) end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local role = p.Team and p.Team.Name or ""
        local ok = (role == "Killer" and Cfg.ESP_Killer) or (role == "Survivors" and Cfg.ESP_Survivor) or (role == "Spectator" and Cfg.ESP_Spectator)
        if ok and p.Character then MakeESP(p.Character, role) end
    end
    if Cfg.ESP_Generator then
        local gens = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Generators")
        if gens then for _, g in ipairs(gens:GetChildren()) do if g.Name == "Generator" then MakeESP(g, "Generator") end end end
    end
end
local function CleanAllESPObjects() for m in pairs(ESPObjects) do CleanESP(m) end end
table.insert(Cleanups, CleanAllESPObjects)
regConn(Players.PlayerAdded:Connect(function(p) regConn(p.CharacterAdded:Connect(function() task.wait(1); RefreshESP() end)) end))
for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then regConn(p.CharacterAdded:Connect(function() task.wait(1); RefreshESP() end)) end end
regConn(Players.PlayerRemoving:Connect(function(p) if p.Character then CleanESP(p.Character) end end))
task.spawn(function() while true do task.wait(5)
    if not Cfg.ESP_Generator then continue end
    local gens = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Generators")
    if gens then for _, g in ipairs(gens:GetChildren()) do if g.Name == "Generator" and not ESPObjects[g] then MakeESP(g, "Generator") end end end
end end)
regConn(LP.CharacterAdded:Connect(function() task.wait(2); RefreshESP() end))

-- ── Auto Parry ──
local parryCD = false
local function TryParry()
    if not Cfg.AutoParry or parryCD or not LP.Character then return end
    local dagger = LP.Character:FindFirstChild("Parrying Dagger") or LP.Backpack:FindFirstChild("Parrying Dagger")
    if not dagger then return end
    if Cfg.AutoEquip and dagger.Parent == LP.Backpack then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:EquipTool(dagger); task.wait(0.1) end
    end
    if not LP.Character:FindFirstChild("Parrying Dagger") then return end
    if ParryEvent then parryCD = true; ParryEvent:FireServer(); task.delay(Cfg.ParryCooldown, function() parryCD = false end) end
end
local function WatchKillerAnimations(killerChar)
    local hum = killerChar:FindFirstChild("Humanoid"); local anim = hum and hum:FindFirstChild("Animator")
    if not anim then return end
    regConn(anim.AnimationPlayed:Connect(function()
        if not Cfg.AutoParry or not LP.Character then return end
        local hrp = LP.Character:FindFirstChild("HumanoidRootPart"); local khrp = killerChar:FindFirstChild("HumanoidRootPart")
        if not hrp or not khrp then return end
        if (hrp.Position - khrp.Position).Magnitude <= Cfg.ParryRange then TryParry() end
    end))
end
local function SetupAutoParry()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local r = p.Team and p.Team.Name or ""
            if r == "Killer" and p.Character then WatchKillerAnimations(p.Character) end
            regConn(p.CharacterAdded:Connect(function() task.wait(0.5); if p.Team and p.Team.Name == "Killer" then WatchKillerAnimations(p.Character) end end))
        end
    end
    regConn(Players.PlayerAdded:Connect(function(p) regConn(p.CharacterAdded:Connect(function() task.wait(0.5); if p.Team and p.Team.Name == "Killer" then WatchKillerAnimations(p.Character) end end)) end))
end

-- ── Auto Perfect Generator ──
local genWaiting = false
if SkillCheckEvent then regConn(SkillCheckEvent.OnClientEvent:Connect(function() genWaiting = true end)) end
local ksWaiting = false
if KingScourgeStart then regConn(KingScourgeStart.OnClientEvent:Connect(function(p1, p2) ksWaiting = true end)) end
local gCheck, gLine, gGoal, gLastVis, gSection = nil, nil, nil, false
task.spawn(function()
    while true do task.wait(0.3)
        gCheck = gCheck or PG:FindFirstChild("SkillCheckPromptGui")
        if gCheck then
            gLine = gLine or gCheck:FindFirstChild("Line", true); gGoal = gGoal or gCheck:FindFirstChild("Goal", true)
        end
        if not gLine or not gGoal then task.wait(1); continue end
        local vis = gCheck.Visible and gCheck.Enabled
        if vis and not gLastVis and (genWaiting or ksWaiting) then
            genWaiting = false; ksWaiting = false
            local d = Cfg.GenDelayMin + math.random() * (Cfg.GenDelayMax - Cfg.GenDelayMin)
            task.delay(d, function()
                if not Cfg.AutoPerfectGen or not LP.Character then return end
                local ci = LP.Character:FindFirstChild("CheckInterractable")
                if not ci or not ci:GetAttribute("isRepairing") then return end
                gLine.Rotation = 109 + gGoal.Rotation
                pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game); task.wait(0.05); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
            end)
        end
        gLastVis = vis
    end
end)

-- ── Metamethod Hook (Synapse only) ──
if type(hookmetamethod) == "function" and type(newcclosure) == "function" and type(getnamecallmethod) == "function" then
    pcall(function()
        local old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local m = getnamecallmethod(); local a = {...}
            if m == "FireServer" and not checkcaller() then
                if self == SkillCheckResult and Cfg.AutoPerfectGen then a[1] = "success"; a[2] = 1; return old(self, table.unpack(a))
                elseif self == KingScourgeHit and Cfg.AutoPerfectGen then a[2] = "success"; return old(self, table.unpack(a)) end
            end
            return old(self, ...)
        end))
    end)
end

-- ── WindUI ──
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/7b1d561cf658da1f2f49e700cf52963e7bdcb23a/dist/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "[CURE] Violence District",
    Folder = "CURE_VD",
    Icon = "solar:skull-bold-duotone",
    NewElements = true,
    HideSearchBar = true,
    Topbar = {Height = 36, ButtonsType = "Minimize"},
})
table.insert(Cleanups, function() pcall(function() Window:Destroy() end) end)
local function tab(t, i) return Window:Tab({Title = t, Icon = i, IconColor = Color3.fromHex("#FF6B6B"), Border = true}) end
local T = {Main = tab("Main", "solar:home-2-bold-duotone"), Combat = tab("Combat", "solar:target-bold-duotone"), Gen = tab("Generator", "solar:cpu-bold-duotone"), Cross = tab("Crosshair", "solar:crosshair-bold-duotone")}

-- Main Tab
local MS = T.Main:Section({Title = "ESP"})
MS:Toggle({Title = "Killer", Default = Cfg.ESP_Killer, Callback = function(v) Cfg.ESP_Killer = v; RefreshESP() end}); MS:Space()
MS:Toggle({Title = "Survivor", Default = Cfg.ESP_Survivor, Callback = function(v) Cfg.ESP_Survivor = v; RefreshESP() end}); MS:Space()
MS:Toggle({Title = "Spectator", Default = Cfg.ESP_Spectator, Callback = function(v) Cfg.ESP_Spectator = v; RefreshESP() end}); MS:Space()
MS:Toggle({Title = "Generator", Default = Cfg.ESP_Generator, Callback = function(v) Cfg.ESP_Generator = v; RefreshESP() end}); MS:Space()
MS:Toggle({Title = "Names", Default = Cfg.ESP_Names, Callback = function(v) Cfg.ESP_Names = v end}); MS:Space()
MS:Toggle({Title = "Distance", Default = Cfg.ESP_Distance, Callback = function(v) Cfg.ESP_Distance = v end}); MS:Space()
MS:Toggle({Title = "Highlight", Default = Cfg.ESP_Highlight, Callback = function(v) Cfg.ESP_Highlight = v; RefreshESP() end}); MS:Space()
MS:Button({Title = "Refresh ESP", Callback = RefreshESP})

-- Combat Tab
local CS = T.Combat:Section({Title = "Auto Parry"})
CS:Toggle({Title = "Enable", Default = Cfg.AutoParry, Callback = function(v) Cfg.AutoParry = v end}); CS:Space()
CS:Toggle({Title = "Auto Equip Dagger", Default = Cfg.AutoEquip, Callback = function(v) Cfg.AutoEquip = v end}); CS:Space()
CS:Slider({Title = "Range", Width = 200, Value = {Min = 5, Max = 40, Default = 18}, Step = 1, Callback = function(v) Cfg.ParryRange = v end}); CS:Space()
CS:Slider({Title = "Cooldown", Width = 200, Value = {Min = 0.5, Max = 5, Default = 1}, Step = 0.1, Callback = function(v) Cfg.ParryCooldown = v end}); CS:Space()
CS:Button({Title = "Manual Parry", Callback = function() if ParryEvent then ParryEvent:FireServer() end end})

-- Generator Tab
local GS = T.Gen:Section({Title = "Auto Perfect Generator"})
GS:Toggle({Title = "Enable", Default = Cfg.AutoPerfectGen, Callback = function(v) Cfg.AutoPerfectGen = v end}); GS:Space()
GS:Slider({Title = "Min Delay", Width = 200, Value = {Min = 0.05, Max = 1, Default = 0.15}, Step = 0.05, Callback = function(v) Cfg.GenDelayMin = v end}); GS:Space()
GS:Slider({Title = "Max Delay", Width = 200, Value = {Min = 0.1, Max = 1.5, Default = 0.35}, Step = 0.05, Callback = function(v) Cfg.GenDelayMax = v end})

-- Crosshair Tab
local XS = T.Cross:Section({Title = "Crosshair"})
XS:Toggle({Title = "Enable", Default = Cfg.Crosshair, Callback = function(v) Cfg.Crosshair = v; BuildCrosshair() end}); XS:Space()
XS:Slider({Title = "Size", Width = 200, Value = {Min = 4, Max = 30, Default = 10}, Step = 1, Callback = function(v) Cfg.CHSize = v; BuildCrosshair() end}); XS:Space()
XS:Slider({Title = "Gap", Width = 200, Value = {Min = 0, Max = 20, Default = 5}, Step = 1, Callback = function(v) Cfg.CHGap = v; BuildCrosshair() end}); XS:Space()
XS:Slider({Title = "Thickness", Width = 200, Value = {Min = 1, Max = 6, Default = 2}, Step = 1, Callback = function(v) Cfg.CHThick = v; BuildCrosshair() end})

-- ── Startup ──
BuildCrosshair()
SetupAutoParry()
RefreshESP()
Window:SelectTab(1)
Window:Notify({Title = "CURE VD", Content = "Loaded. RightShift to toggle.", Duration = 3})
