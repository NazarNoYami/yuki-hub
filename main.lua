--[[
  Yuki Hub v5.0 - WindUI Edition
  Essential + Notties + Yuki Hub merged
  WindUI Library v1.6.65
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local Map = workspace:FindFirstChild("Map") or workspace
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Gravity = workspace.Gravity

-- Cleanup
for _, v in pairs(CoreGui:GetChildren()) do
    if v.Name == "YukiHub" then v:Destroy() end
end

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "Yuki Hub v5.0",
    Folder = "YukiHub",
    Icon = "solar:home-2-bold-duotone",
    NewElements = true,
    HideSearchBar = false,
    Topbar = {
        Height = 44,
        ButtonsType = "Default",
    },
})

Window:SetAccentColor(Color3.fromRGB(0, 120, 255))

-- ============== TABS ==============
local Tabs = {}
Tabs.Main = Window:Tab({ Title = "Main", Icon = "solar:home-2-bold-duotone", IconColor = Color3.fromHex("#83889E"), Border = true })
Tabs.ESP = Window:Tab({ Title = "ESP", Icon = "solar:eye-bold-duotone", IconColor = Color3.fromHex("#83889E"), Border = true })
Tabs.Aimbot = Window:Tab({ Title = "Aimbot", Icon = "solar:target-bold-duotone", IconColor = Color3.fromHex("#83889E"), Border = true })
Tabs.Visuals = Window:Tab({ Title = "Visuals", Icon = "solar:palette-bold-duotone", IconColor = Color3.fromHex("#83889E"), Border = true })
Tabs.Misc = Window:Tab({ Title = "Misc", Icon = "solar:settings-bold-duotone", IconColor = Color3.fromHex("#83889E"), Border = true })
Tabs.HUD = Window:Tab({ Title = "HUD", Icon = "solar:chart-bold-duotone", IconColor = Color3.fromHex("#83889E"), Border = true })
Tabs.Credits = Window:Tab({ Title = "Credits", Icon = "solar:info-circle-bold-duotone", IconColor = Color3.fromHex("#83889E"), Border = true })

-- ============== SHARED STATE ==============
_G.YH = {
    Players = Players, RunService = RunService, UserInputService = UserInputService,
    VirtualInputManager = VirtualInputManager, HttpService = HttpService,
    Lighting = Lighting, CoreGui = CoreGui, Camera = Camera, Map = Map,
    LocalPlayer = LocalPlayer, Mouse = Mouse, Gravity = Gravity,
    WindUI = WindUI, Window = Window, Tabs = Tabs,
    C = {
        Blue = Color3.fromRGB(0, 120, 255), Red = Color3.fromRGB(255, 50, 50),
        Green = Color3.fromRGB(0, 255, 100), Yellow = Color3.fromRGB(255, 200, 50),
        Purple = Color3.fromRGB(160, 0, 255), White = Color3.fromRGB(255, 255, 255),
        Orange = Color3.fromRGB(255, 150, 50),
    },
    -- State
    aimOn = false, aimSmooth = 1, aimFOV = 90,
    projOn = false, projV = 150, projG = 196.2, projTarget = nil, projLead = true, projLeadFac = 1,
    espBoxOn = false, espLineOn = false, espLineColor = Color3.fromRGB(0, 255, 100),
    espLineMode = "Single", espLineOrigin = "Character", espLineObjs = {},
    ESPObjs = {}, playerESPOn = false, playerHighlights = {}, playerLabels = {},
    genOn = false, genH = {}, genL = {}, hookOn = false, hookH = {}, hookL = {},
    palOn = false, palH = {}, gateOn = false, gateH = {}, gateL = {}, winOn = false, winL = {},
    projArcOn = false, projArcObj = nil,
    brightOn = false, brightLevel = 1, fovOn = false, fovVal = 70, origFOV = Camera.FieldOfView,
    fogOn = false, fogS = 0, fogE = 1000, skyOn = false, skyB = 50, skyE = 50,
    spdOn = false, spdVal = 32, noclipOn = false,
    sprintOn = false, sprintBoost = 1.05, sprinting = false,
    flOn = false, flObj = nil, chOn = false, chLen = 10, chW = 2,
    stOn = false, stVal = 100, afkConnected = false,
    hudOn = false, hudFPS = true, hudPing = true, hudKiller = true,
    hudFrames = 0, hudTime = 0, hudFpsVal = 0, hudGui = nil,
}

-- ============== HELPERS ==============
local function GetClosestPlayer(fov)
    local closest, cd = nil, fov or math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local pos, on = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if on then
                local d = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if d < cd then cd = d; closest = p end
            end
        end
    end
    return closest
end
local function GetTargetPos(t) if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then return t.Character.HumanoidRootPart.Position end; return nil end

local function GetTeamInfo(plr)
    local team = plr.Team
    if not team then return "Other", Color3.fromRGB(255, 255, 255) end
    local tn = team.Name:lower()
    if tn:find("maniac") or tn:find("killer") then return "Killer", Color3.fromRGB(255, 80, 80) end
    if tn:find("survivor") then return "Survivor", Color3.fromRGB(100, 255, 100) end
    return "Other", Color3.fromRGB(255, 255, 255)
end

-- Clear table helper
local function ClearTable(t) for k in pairs(t) do t[k] = nil end end

-- Projectile helpers
local prevPos = {}; local tVel = {}
local function GetTargetVel(t)
    local pos = GetTargetPos(t); if not pos then return Vector3.new() end
    local pr = prevPos[t]; prevPos[t] = pos
    if pr then local vel = (pos - pr) / 0.1; tVel[t] = tVel[t] and (tVel[t] * 0.7 + vel * 0.3) or vel end
    return tVel[t] or Vector3.new()
end
local function CalcAngle(orig, trg, vel, grav)
    local dx = trg.X - orig.X; local dz = trg.Z - orig.Z; local dy = trg.Y - orig.Y
    local d = math.sqrt(dx * dx + dz * dz)
    if d < 1 then return nil end; local vSq = vel * vel; local g = grav or 196.2
    local a = (g * d * d) / (2 * vSq); local b = -d; local c = a + dy; local disc = b * b - 4 * a * c
    if disc < 0 then return nil end; local sd = math.sqrt(disc)
    local ang = math.atan((-b + sd) / (2 * a)); if ang < 0 then ang = math.atan((-b - sd) / (2 * a)) end
    if ang < 0 then return nil end; return ang
end
local function GetAimPoint(orig, trg, vel, grav)
    local aimT = trg
    if _G.YH.projLead then
        local est = (trg - orig).Magnitude / (vel * 0.707)
        if est > 0 then local pred = GetTargetPos(_G.YH.projTarget) + GetTargetVel(_G.YH.projTarget) * est * _G.YH.projLeadFac; if pred then aimT = pred end end
    end
    local ang = CalcAngle(orig, aimT, vel, grav); if not ang then return nil end
    local dx = aimT.X - orig.X; local dz = aimT.Z - orig.Z; local d = math.sqrt(dx * dx + dz * dz); local ho = math.tan(ang) * d
    return aimT + Vector3.new(0, ho, 0)
end

-- ============== MAIN TAB ==============
do
    local T = Tabs.Main
    T:Section({ Title = "Game Options" })
    T:Button({ Title = "Rejoin Server", Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end })
    T:Space()
    T:Button({ Title = "Server Hop", Callback = function()
        local function gs(c) local u = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"; if c then u = u .. "&cursor=" .. c end; return HttpService:JSONDecode(game:HttpGet(u)) end
        local s = gs(); if s and s.data then for _, v in pairs(s.data) do if v.playing < v.maxPlayers and v.id ~= game.JobId then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, v.id, LocalPlayer); return end end end
    end })
    T:Space()
    T:Section({ Title = "Movement" })
    T:Toggle({ Title = "Walkspeed", Callback = function(s) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = s and 50 or 16 end end })
    T:Space()
    T:Slider({ Title = "Walkspeed Value", Width = 200, Value = { Min = 16, Max = 250, Default = 50 }, Step = 1, Callback = function(v) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = v end end })
    T:Space()
    T:Dropdown({ Title = "Jump Power", Values = { "50", "75", "100", "150", "200" }, Value = 1, Callback = function(s) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.JumpPower = tonumber(s) end end })
end

-- ============== ESP TAB ==============
do
    local T = Tabs.ESP
    local playerESPOn = false
    local playerHighlights = {}; local playerLabels = {}
    local espBoxOn = false; local ESPObjs = {}
    local espLineOn = false; local espLineColor = Color3.fromRGB(0, 255, 100); local espLineMode = "Single"; local espLineOrigin = "Character"; local espLineObjs = {}
    local genOn = false; local genH = {}; local genL = {}
    local hookOn = false; local hookH = {}; local hookL = {}
    local palOn = false; local palH = {}
    local gateOn = false; local gateH = {}; local gateL = {}
    local winOn = false; local winL = {}
    local cacheTimer = 0; local cachedGens = {}; local cachedHooks = {}; local cachedPallets = {}; local cachedGates = {}; local cachedWindows = {}

    local function ScanObjects()
        ClearTable(cachedGens); ClearTable(cachedHooks); ClearTable(cachedPallets); ClearTable(cachedGates); ClearTable(cachedWindows)
        for _, obj in pairs(Map:GetDescendants()) do
            if not obj:IsA("Model") and not obj:IsA("BasePart") then continue end; local ln = obj.Name:lower()
            if obj:IsA("Model") then
                if ln:find("generator") then table.insert(cachedGens, obj)
                elseif ln:find("hook") then table.insert(cachedHooks, obj)
                elseif ln:find("pallet") then table.insert(cachedPallets, obj)
                elseif ln:find("gate") or ln:find("exit") then table.insert(cachedGates, obj) end
            end
            if obj:IsA("BasePart") and ln:find("window") then table.insert(cachedWindows, obj) end
        end
    end

    T:Section({ Title = "Player ESP" })
    T:Toggle({ Title = "Player ESP", Desc = "Highlight + name + distance + status", Callback = function(s) playerESPOn = s; if not s then for _, v in pairs(playerHighlights) do pcall(function() v:Destroy() end) end; ClearTable(playerHighlights); for _, v in pairs(playerLabels) do pcall(function() v.Parent:Destroy() end) end; ClearTable(playerLabels) end end })
    T:Space()

    T:Section({ Title = "Drawing ESP" })
    T:Toggle({ Title = "ESP Box", Callback = function(s) espBoxOn = s; if s then for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then local box = Drawing.new("Square"); box.Thickness = 2; box.Color = Color3.fromRGB(255, 50, 50); box.Filled = false; box.Visible = false; local nl = Drawing.new("Text"); nl.Center = true; nl.Size = 14; nl.Outline = true; nl.Color = Color3.fromRGB(255, 255, 255); nl.Visible = false; ESPObjs[p] = { Box = box, Name = nl } end end else for _, o in pairs(ESPObjs) do o.Box.Visible = false; o.Name.Visible = false end end end })
    T:Space()
    T:Toggle({ Title = "ESP Line", Callback = function(s) espLineOn = s; if not s then for _, o in pairs(espLineObjs) do o.Visible = false end end end })
    T:Space()
    T:Colorpicker({ Title = "Line Color", Default = espLineColor, Callback = function(c) espLineColor = c end })
    T:Space()
    T:Dropdown({ Title = "Line Mode", Values = { "Single", "All Players" }, Value = 1, Callback = function(s) espLineMode = (s == "All Players") and "All" or "Single" end })
    T:Space()
    T:Dropdown({ Title = "Line Origin", Values = { "Character", "Top Screen" }, Value = 1, Callback = function(s) espLineOrigin = s end })
    T:Space()
    T:Toggle({ Title = "Projectile Arc", Desc = "Trajectory prediction", Callback = function(s) _G.YH.projArcOn = s; if not s and _G.YH.projArcObj then _G.YH.projArcObj.Visible = false end end })
    T:Space()

    T:Section({ Title = "Object ESP" })
    T:Toggle({ Title = "Generator ESP", Callback = function(s) genOn = s; if not s then for _, v in pairs(genH) do pcall(function() v:Destroy() end) end; ClearTable(genH); for _, v in pairs(genL) do pcall(function() v.Parent:Destroy() end) end; ClearTable(genL) end end })
    T:Space()
    T:Toggle({ Title = "Hook ESP", Callback = function(s) hookOn = s; if not s then for _, v in pairs(hookH) do pcall(function() v:Destroy() end) end; ClearTable(hookH); for _, v in pairs(hookL) do pcall(function() v.Parent:Destroy() end) end; ClearTable(hookL) end end })
    T:Space()
    T:Toggle({ Title = "Pallet ESP", Callback = function(s) palOn = s; if not s then for _, v in pairs(palH) do pcall(function() v:Destroy() end) end; ClearTable(palH) end end })
    T:Space()
    T:Toggle({ Title = "Gate ESP", Callback = function(s) gateOn = s; if not s then for _, v in pairs(gateH) do pcall(function() v:Destroy() end) end; ClearTable(gateH); for _, v in pairs(gateL) do pcall(function() v.Parent:Destroy() end) end; ClearTable(gateL) end end })
    T:Space()
    T:Toggle({ Title = "Window ESP", Callback = function(s) winOn = s; if not s then for _, v in pairs(winL) do pcall(function() v.Parent:Destroy() end) end; ClearTable(winL) end end })

    -- ESP RenderStepped
    RunService.RenderStepped:Connect(function(dt)
        cacheTimer = cacheTimer + dt
        if cacheTimer >= 2 then cacheTimer = 0; ScanObjects() end

        -- ESP Box
        if espBoxOn then
            for plr, o in pairs(ESPObjs) do
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local root = plr.Character.HumanoidRootPart; local pos, on = Camera:WorldToViewportPoint(root.Position)
                    if on then local sz = Vector2.new(2000 / pos.Z, 3000 / pos.Z); o.Box.Size = sz; o.Box.Position = Vector2.new(pos.X - sz.X / 2, pos.Y - sz.Y / 2); o.Box.Visible = true; o.Name.Position = Vector2.new(pos.X, pos.Y - sz.Y / 2 - 16); o.Name.Text = plr.Name; o.Name.Visible = true else o.Box.Visible = false; o.Name.Visible = false end
                else o.Box.Visible = false; o.Name.Visible = false end
            end
        end

        -- ESP Line
        if espLineOn then
            local mp, msp = nil, nil
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then mp = LocalPlayer.Character.HumanoidRootPart.Position; msp, _ = Camera:WorldToViewportPoint(mp) end
            local ori; if espLineOrigin == "Top Screen" then ori = Vector2.new(Camera.ViewportSize.X / 2, 0) elseif msp then ori = Vector2.new(msp.X, msp.Y) else for _, o in pairs(espLineObjs) do o.Visible = false end; return end
            local targets = {}
            if espLineMode == "Single" then local t = _G.YH.projTarget or GetClosestPlayer(360); if t then table.insert(targets, t) end
            else for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then table.insert(targets, p) end end end
            for i = #targets + 1, #espLineObjs do espLineObjs[i].Visible = false end
            for i, t in ipairs(targets) do
                if not espLineObjs[i] then espLineObjs[i] = Drawing.new("Line"); espLineObjs[i].Thickness = 2; espLineObjs[i].Color = espLineColor; espLineObjs[i].Transparency = 0.6 end
                local tp = t.Character and t.Character:FindFirstChild("HumanoidRootPart") and t.Character.HumanoidRootPart.Position
                if tp then local to, _ = Camera:WorldToViewportPoint(tp); espLineObjs[i].From = ori; espLineObjs[i].To = Vector2.new(to.X, to.Y); espLineObjs[i].Visible = true; espLineObjs[i].Color = espLineColor else espLineObjs[i].Visible = false end
            end
        end

        -- Projectile Arc
        if _G.YH.projArcOn and _G.YH.projTarget and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local tp = GetTargetPos(_G.YH.projTarget)
            if tp then
                local orig = LocalPlayer.Character.HumanoidRootPart.Position; local trg = tp; local vel = _G.YH.projV; local grav = _G.YH.projG
                if not _G.YH.projArcObj then _G.YH.projArcObj = Drawing.new("Line"); _G.YH.projArcObj.Thickness = 1; _G.YH.projArcObj.Color = Color3.fromRGB(255, 200, 50); _G.YH.projArcObj.Transparency = 0.3 end
                local ang = CalcAngle(orig, trg, vel, grav)
                if ang then
                    local dx = trg.X - orig.X; local dz = trg.Z - orig.Z; local dir = Vector2.new(dx, dz).Unit; local g = grav; local v = vel
                    local vx = v * math.cos(ang); local vy = v * math.sin(ang); local pts = {}; local tt = (2 * vy) / g
                    for t = 0, tt, 0.1 do local x = vx * t; local y = vy * t - 0.5 * g * t * t; local pos = orig + Vector3.new(dir.X * x, y, dir.Y * x); local sp, _ = Camera:WorldToViewportPoint(pos); table.insert(pts, Vector2.new(sp.X, sp.Y)) end
                    if #pts > 1 then _G.YH.projArcObj.Visible = true; _G.YH.projArcObj.Points = pts else _G.YH.projArcObj.Visible = false end
                else _G.YH.projArcObj.Visible = false end
            end
        end

        -- Player ESP
        if playerESPOn then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr == LocalPlayer then continue end; local char = plr.Character; if not char then continue end; local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"); if not head then continue end
                local tt, bc = GetTeamInfo(plr); local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid")
                local hooked = char:GetAttribute("IsHooked") or char:GetAttribute("Hooked"); local knocked = hum and hum.Health < hum.MaxHealth * 0.3
                local color = bc
                if tt == "Survivor" then if hooked then color = Color3.fromRGB(255, 110, 80); elseif knocked then color = Color3.fromRGB(255, 170, 80); elseif hum and hum.Health < hum.MaxHealth then color = Color3.fromRGB(255, 255, 120); else color = Color3.fromRGB(100, 255, 100) end end
                if not playerHighlights[plr] then local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.OutlineColor = Color3.new(1, 1, 1); hl.FillTransparency = 0.5; hl.Parent = Camera; playerHighlights[plr] = hl end
                local hl = playerHighlights[plr]; hl.Adornee = char; hl.FillColor = color; hl.FillTransparency = 0.3; hl.OutlineTransparency = 0
                if not playerLabels[plr] or not playerLabels[plr].Parent then
                    local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0, 200, 0, 50); bill.StudsOffset = Vector3.new(0, 3, 0); bill.AlwaysOnTop = true; bill.Parent = Camera
                    local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.3; txt.TextStrokeColor3 = Color3.new(0, 0, 0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.Parent = bill; playerLabels[plr] = txt
                end
                local txt = playerLabels[plr]; txt.Parent.Adornee = head
                local dist = 0; if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then dist = math.floor((head.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude) end
                local line3 = tostring(dist) .. "m"; local line2 = ""
                if tt == "Killer" then local sk = plr:GetAttribute("SelectedKiller") or plr:GetAttribute("KillerName"); line2 = sk and "KILLER: " .. tostring(sk) or "KILLER"
                elseif tt == "Survivor" then if hooked then line2 = "HOOKED"; elseif knocked then line2 = "HURT" end end
                txt.Text = plr.Name .. " | " .. line3 .. (line2 ~= "" and (" | " .. line2) or ""); txt.TextColor3 = color
            end
        end

        -- Object ESP
        if genOn then for _, obj in pairs(cachedGens) do local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"); if not att then continue end; if not genH[obj] then local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.FillColor = Color3.new(1, 1, 1); hl.OutlineColor = Color3.new(1, 1, 1); hl.Parent = Camera; genH[obj] = hl; local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0, 150, 0, 30); bill.StudsOffset = Vector3.new(0, 2.5, 0); bill.AlwaysOnTop = true; bill.Parent = Camera; local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0, 0, 0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.TextColor3 = Color3.fromRGB(200, 200, 255); txt.Text = "Generator"; txt.Parent = bill; genL[obj] = txt end; genH[obj].Adornee = obj; genL[obj].Parent.Adornee = att end end
        if hookOn then for _, obj in pairs(cachedHooks) do local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"); if not att then continue end; if not hookH[obj] then local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.6; hl.FillColor = Color3.fromRGB(255, 80, 80); hl.OutlineColor = Color3.fromRGB(255, 0, 0); hl.Parent = Camera; hookH[obj] = hl; local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0, 100, 0, 30); bill.StudsOffset = Vector3.new(0, 2, 0); bill.AlwaysOnTop = true; bill.Parent = Camera; local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0, 0, 0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.TextColor3 = Color3.fromRGB(255, 100, 100); txt.Text = "Hook"; txt.Parent = bill; hookL[obj] = txt end; hookH[obj].Adornee = obj end end
        if palOn then for _, obj in pairs(cachedPallets) do local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"); if not att then continue end; if not palH[obj] then local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.FillColor = Color3.fromRGB(255, 255, 100); hl.OutlineColor = Color3.fromRGB(255, 200, 0); hl.Parent = Camera; palH[obj] = hl end; palH[obj].Adornee = obj end end
        if gateOn then for _, obj in pairs(cachedGates) do local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"); if not att then continue end; if not gateH[obj] then local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.FillColor = Color3.fromRGB(160, 0, 255); hl.OutlineColor = Color3.fromRGB(200, 120, 255); hl.Parent = Camera; gateH[obj] = hl; local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0, 100, 0, 30); bill.StudsOffset = Vector3.new(0, 2, 0); bill.AlwaysOnTop = true; bill.Parent = Camera; local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0, 0, 0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.TextColor3 = Color3.fromRGB(200, 150, 255); txt.Text = "Gate"; txt.Parent = bill; gateL[obj] = txt end; gateH[obj].Adornee = att end end
        if winOn then for _, obj in pairs(cachedWindows) do if not winL[obj] then local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0, 80, 0, 25); bill.StudsOffset = Vector3.new(0, 1.5, 0); bill.AlwaysOnTop = true; bill.Parent = Camera; local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 12; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0, 0, 0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.TextColor3 = Color3.fromRGB(180, 230, 255); txt.Text = "Window"; txt.Parent = bill; winL[obj] = txt end; winL[obj].Parent.Adornee = obj end end
    end)
end

-- ============== AIMBOT TAB ==============
do
    local T = Tabs.Aimbot
    T:Section({ Title = "Basic Aimbot" })
    T:Toggle({ Title = "Basic Aimbot", Callback = function(s) _G.YH.aimOn = s end })
    T:Space()
    T:Slider({ Title = "Smoothness", Width = 200, Value = { Min = 1, Max = 10, Default = 1 }, Step = 1, Callback = function(v) _G.YH.aimSmooth = v end })
    T:Space()
    T:Slider({ Title = "FOV", Width = 200, Value = { Min = 10, Max = 360, Default = 90 }, Step = 1, Callback = function(v) _G.YH.aimFOV = v end })
    T:Space()
    T:Section({ Title = "Projectile Aimbot" })
    T:Toggle({ Title = "Projectile Aimbot", Desc = "For arcing weapons", Callback = function(s) _G.YH.projOn = s end })
    T:Space()
    T:Slider({ Title = "Projectile Velocity", Width = 200, Value = { Min = 30, Max = 500, Default = 150 }, Step = 5, Callback = function(v) _G.YH.projV = v end })
    T:Space()
    T:Slider({ Title = "Gravity", Width = 200, Value = { Min = 50, Max = 500, Default = 196.2 }, Step = 1, Callback = function(v) _G.YH.projG = v end })
    T:Space()
    T:Toggle({ Title = "Lead Prediction", Callback = function(s) _G.YH.projLead = s end })
    T:Space()
    T:Slider({ Title = "Lead Factor", Width = 200, Value = { Min = 0.5, Max = 3, Default = 1 }, Step = 0.1, Callback = function(v) _G.YH.projLeadFac = v end })
    T:Space()
    T:Button({ Title = "Lock Target", Color = _G.YH.C.Blue, Callback = function() _G.YH.projTarget = GetClosestPlayer(360) end })
    T:Space()
    T:Button({ Title = "Unlock Target", Color = _G.YH.C.Red, Callback = function() _G.YH.projTarget = nil end })

    -- Aimbot loop
    RunService.RenderStepped:Connect(function()
        if _G.YH.aimOn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local c = GetClosestPlayer(_G.YH.aimFOV)
            if c and c.Character then
                local pos = Camera:WorldToViewportPoint(c.Character.HumanoidRootPart.Position)
                local t = Vector2.new(pos.X, pos.Y); local cur = Vector2.new(Mouse.X, Mouse.Y)
                local s = t:Lerp(cur, 1 / _G.YH.aimSmooth); mousemoverel(s.X - cur.X, s.Y - cur.Y)
            end
        end
        if _G.YH.projOn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local target = _G.YH.projTarget or GetClosestPlayer(360)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
                local origin = LocalPlayer.Character.HumanoidRootPart.Position; local tPos = target.Character.HumanoidRootPart.Position
                local aim = GetAimPoint(origin, tPos, _G.YH.projV, _G.YH.projG)
                if aim then local pos, on = Camera:WorldToViewportPoint(aim); if on then local t = Vector2.new(pos.X, pos.Y); local cur = Vector2.new(Mouse.X, Mouse.Y); local s = t:Lerp(cur, 1 / _G.YH.aimSmooth); mousemoverel(s.X - cur.X, s.Y - cur.Y) end end
            end
        end
    end)
end

-- ============== VISUALS TAB ==============
do
    local T = Tabs.Visuals
    T:Section({ Title = "Bright Mode" })
    T:Toggle({ Title = "Bright Mode", Desc = "Auto-reapplies on map change", Callback = function(s) _G.YH.brightOn = s end })
    T:Space()
    T:Slider({ Title = "Brightness Level", Width = 200, Value = { Min = 0.5, Max = 5, Default = 1 }, Step = 0.1, Callback = function(v) _G.YH.brightLevel = v end })
    T:Space()
    T:Section({ Title = "Custom FOV" })
    T:Toggle({ Title = "Custom FOV", Callback = function(s) _G.YH.fovOn = s; Camera.FieldOfView = s and _G.YH.fovVal or _G.YH.origFOV end })
    T:Space()
    T:Slider({ Title = "FOV Value", Width = 200, Value = { Min = 30, Max = 120, Default = 70 }, Step = 1, Callback = function(v) _G.YH.fovVal = v; if _G.YH.fovOn then Camera.FieldOfView = v end end })
    T:Space()
    T:Section({ Title = "Custom Fog" })
    T:Toggle({ Title = "Custom Fog", Callback = function(s) _G.YH.fogOn = s end })
    T:Space()
    T:Slider({ Title = "Fog Start", Width = 200, Value = { Min = 0, Max = 500, Default = 0 }, Step = 1, Callback = function(v) _G.YH.fogS = v end })
    T:Space()
    T:Slider({ Title = "Fog End", Width = 200, Value = { Min = 100, Max = 2000, Default = 1000 }, Step = 10, Callback = function(v) _G.YH.fogE = v end })
    T:Space()
    T:Section({ Title = "Skybox" })
    T:Toggle({ Title = "Skybox", Callback = function(s) _G.YH.skyOn = s end })
    T:Space()
    T:Slider({ Title = "Brightness", Width = 200, Value = { Min = 0, Max = 100, Default = 50 }, Step = 1, Callback = function(v) _G.YH.skyB = v end })
    T:Space()
    T:Slider({ Title = "Exposure", Width = 200, Value = { Min = 0, Max = 100, Default = 50 }, Step = 1, Callback = function(v) _G.YH.skyE = v end })
end

-- ============== MISC TAB ==============
do
    local T = Tabs.Misc
    T:Section({ Title = "Movement" })
    T:Toggle({ Title = "Speedhack", Callback = function(s) _G.YH.spdOn = s end })
    T:Space()
    T:Slider({ Title = "Speed Value", Width = 200, Value = { Min = 16, Max = 100, Default = 32 }, Step = 1, Callback = function(v) _G.YH.spdVal = v end })
    T:Space()
    T:Toggle({ Title = "Sprint Speed", Desc = "Faster while holding Shift", Callback = function(s) _G.YH.sprintOn = s end })
    T:Space()
    T:Slider({ Title = "Sprint Boost", Width = 200, Value = { Min = 1.0, Max = 2.0, Default = 1.05 }, Step = 0.05, Callback = function(v) _G.YH.sprintBoost = v end })
    T:Space()
    T:Toggle({ Title = "Noclip", Desc = "Walk through walls", Callback = function(s) _G.YH.noclipOn = s end })
    T:Space()

    T:Section({ Title = "Utilities" })
    T:Toggle({ Title = "Custom Crosshair", Callback = function(s) _G.YH.chOn = s end })
    T:Space()
    T:Slider({ Title = "Crosshair Length", Width = 200, Value = { Min = 5, Max = 30, Default = 10 }, Step = 1, Callback = function(v) _G.YH.chLen = v end })
    T:Space()
    T:Slider({ Title = "Crosshair Width", Width = 200, Value = { Min = 1, Max = 8, Default = 2 }, Step = 1, Callback = function(v) _G.YH.chW = v end })
    T:Space()
    T:Toggle({ Title = "Flashlight", Callback = function(s) _G.YH.flOn = s end })
    T:Space()
    T:Toggle({ Title = "Stretched Res", Desc = "Wider field of view", Callback = function(s) _G.YH.stOn = s end })
    T:Space()
    T:Slider({ Title = "Stretch Amount", Width = 200, Value = { Min = 50, Max = 200, Default = 100 }, Step = 5, Callback = function(v) _G.YH.stVal = v end })
    T:Space()
    T:Button({ Title = "Reset Character", Callback = function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.Health = 0 end end })
    T:Space()
    T:Button({ Title = "Anti AFK", Desc = "Prevent auto-kick", Callback = function()
        if _G.YH.afkConnected then return end; _G.YH.afkConnected = true
        LocalPlayer.Idled:Connect(function() VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1); task.wait(0.1); VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1) end)
    end })
    T:Space()
    T:Slider({ Title = "FPS Cap", Width = 200, Value = { Min = 15, Max = 360, Default = 60 }, Step = 1, Callback = function(v) setfpscap(v) end })
    T:Space()
    T:Button({ Title = "Infinite Yield", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end })

    -- Crosshair drawing
    local chLines = {}
    for i = 1, 4 do chLines[i] = Drawing.new("Line"); chLines[i].Thickness = 2; chLines[i].Color = Color3.fromRGB(0, 255, 100); chLines[i].Transparency = 0.8; chLines[i].Visible = false end

    RunService.RenderStepped:Connect(function()
        -- Crosshair
        if _G.YH.chOn then
            local cx = Camera.ViewportSize.X / 2; local cy = Camera.ViewportSize.Y / 2; local len = _G.YH.chLen; local w = _G.YH.chW
            for i = 1, 4 do chLines[i].Visible = true; chLines[i].Thickness = w end
            chLines[1].From = Vector2.new(cx, cy - len); chLines[1].To = Vector2.new(cx, cy - 2)
            chLines[2].From = Vector2.new(cx, cy + 2); chLines[2].To = Vector2.new(cx, cy + len)
            chLines[3].From = Vector2.new(cx - len, cy); chLines[3].To = Vector2.new(cx - 2, cy)
            chLines[4].From = Vector2.new(cx + 2, cy); chLines[4].To = Vector2.new(cx + len, cy)
        else for i = 1, 4 do chLines[i].Visible = false end end

        -- Stretched Res
        if _G.YH.stOn then Camera.ViewportSize = Vector2.new(Camera.ViewportSize.X * (_G.YH.stVal / 100), Camera.ViewportSize.Y) end
    end)
end

-- ============== HUD TAB ==============
do
    local T = Tabs.HUD
    T:Section({ Title = "Essential HUD" })
    T:Toggle({ Title = "Enable HUD", Desc = "FPS, Ping, Killer info", Callback = function(s) _G.YH.hudOn = s end })
    T:Space()
    T:Toggle({ Title = "Show FPS", Default = true, Callback = function(s) _G.YH.hudFPS = s end })
    T:Space()
    T:Toggle({ Title = "Show Ping", Default = true, Callback = function(s) _G.YH.hudPing = s end })
    T:Space()
    T:Toggle({ Title = "Show Killer", Default = true, Callback = function(s) _G.YH.hudKiller = s end })

    -- HUD creation
    local function CreateHUD()
        if _G.YH.hudGui and _G.YH.hudGui.sg and _G.YH.hudGui.sg.Parent then pcall(function() _G.YH.hudGui.sg:Destroy() end) end
        local sg = Instance.new("ScreenGui"); sg.Name = "YukiHubHUD"; sg.Parent = CoreGui
        local frame = Instance.new("Frame"); frame.Size = UDim2.new(0, 180, 0, 80); frame.Position = UDim2.new(1, -190, 0, 10); frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25); frame.BackgroundTransparency = 0.3; frame.BorderSizePixel = 0; frame.Parent = sg
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = frame
        local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(50, 50, 70); stroke.Thickness = 1; stroke.Parent = frame
        local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 2); layout.Parent = frame
        local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 6); pad.PaddingLeft = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 6); pad.Parent = frame
        local fpsLbl = Instance.new("TextLabel"); fpsLbl.Size = UDim2.new(1, 0, 0, 18); fpsLbl.BackgroundTransparency = 1; fpsLbl.Text = "FPS: 0"; fpsLbl.TextColor3 = Color3.fromRGB(100, 255, 100); fpsLbl.Font = Enum.Font.SourceSansSemibold; fpsLbl.TextSize = 15; fpsLbl.TextXAlignment = Enum.TextXAlignment.Left; fpsLbl.Parent = frame
        local pingLbl = Instance.new("TextLabel"); pingLbl.Size = UDim2.new(1, 0, 0, 18); pingLbl.BackgroundTransparency = 1; pingLbl.Text = "Ping: 0ms"; pingLbl.TextColor3 = Color3.fromRGB(100, 200, 255); fpsLbl.Font = Enum.Font.SourceSansSemibold; pingLbl.TextSize = 15; pingLbl.TextXAlignment = Enum.TextXAlignment.Left; pingLbl.Parent = frame
        local killerLbl = Instance.new("TextLabel"); killerLbl.Size = UDim2.new(1, 0, 0, 18); killerLbl.BackgroundTransparency = 1; killerLbl.Text = "Killer: --"; killerLbl.TextColor3 = Color3.fromRGB(255, 100, 100); killerLbl.Font = Enum.Font.SourceSansSemibold; killerLbl.TextSize = 15; killerLbl.TextXAlignment = Enum.TextXAlignment.Left; killerLbl.Parent = frame
        _G.YH.hudGui = {sg = sg, frame = frame, fpsLbl = fpsLbl, pingLbl = pingLbl, killerLbl = killerLbl}
    end

    -- HUD loop
    RunService.RenderStepped:Connect(function(dt)
        if _G.YH.hudOn then
            if not _G.YH.hudGui then CreateHUD() end
            _G.YH.hudFrames = _G.YH.hudFrames + 1; _G.YH.hudTime = _G.YH.hudTime + dt
            if _G.YH.hudTime >= 1 then _G.YH.hudFpsVal = math.floor(_G.YH.hudFrames / _G.YH.hudTime); _G.YH.hudFrames = 0; _G.YH.hudTime = 0 end
            if _G.YH.hudFPS then _G.YH.hudGui.fpsLbl.Text = "FPS: " .. tostring(_G.YH.hudFpsVal); _G.YH.hudGui.fpsLbl.Visible = true else _G.YH.hudGui.fpsLbl.Visible = false end
            if _G.YH.hudPing then local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000); _G.YH.hudGui.pingLbl.Text = "Ping: " .. tostring(ping) .. "ms"; _G.YH.hudGui.pingLbl.Visible = true else _G.YH.hudGui.pingLbl.Visible = false end
            if _G.YH.hudKiller then
                local killerName = "--"
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                        local team = plr.Team
                        if team and (team.Name:lower():find("maniac") or team.Name:lower():find("killer")) then killerName = plr.Name; break end
                    end
                end
                _G.YH.hudGui.killerLbl.Text = "Killer: " .. killerName; _G.YH.hudGui.killerLbl.Visible = true
            else _G.YH.hudGui.killerLbl.Visible = false end
            local vc = 0; if _G.YH.hudGui.fpsLbl.Visible then vc = vc + 1 end; if _G.YH.hudGui.pingLbl.Visible then vc = vc + 1 end; if _G.YH.hudGui.killerLbl.Visible then vc = vc + 1 end
            _G.YH.hudGui.frame.Size = UDim2.new(0, 180, 0, 8 + vc * 22)
        else
            if _G.YH.hudGui then pcall(function() _G.YH.hudGui.sg:Destroy() end); _G.YH.hudGui = nil end
        end
    end)
end

-- ============== CREDITS TAB ==============
do
    local T = Tabs.Credits
    T:Section({ Title = "Info" })
    T:Button({ Title = "Yuki Hub v5.0", Desc = "Made for Tuan | WindUI | Modular", Callback = function() end })
    T:Space()
    T:Button({ Title = "Features:", Desc = "ESP, Aimbot, Visuals, Misc, HUD", Callback = function() end })
    T:Space()
    T:Button({ Title = "Merged from:", Desc = "Essential Script + Notties Script + Yuki Hub", Callback = function() end })
end

-- ============== MAIN LOOP ==============
RunService.RenderStepped:Connect(function()
    -- Bright Mode
    if _G.YH.brightOn then
        local b = _G.YH.brightLevel * 2; Lighting.Ambient = Color3.fromRGB(255, 255, 255); Lighting.Brightness = b; Lighting.ClockTime = 12
        Lighting.FogEnd = 100000; Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255); Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
    end
    if _G.YH.fovOn then Camera.FieldOfView = _G.YH.fovVal end
    if _G.YH.fogOn then Lighting.FogStart = _G.YH.fogS; Lighting.FogEnd = _G.YH.fogE end
    if _G.YH.skyOn then Lighting.Brightness = _G.YH.skyB / 10; Lighting.ExposureCompensation = _G.YH.skyE / 10 end
    if _G.YH.spdOn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = _G.YH.spdVal end
    if _G.YH.noclipOn and LocalPlayer.Character then for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end
    if _G.YH.sprintOn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        LocalPlayer.Character.Humanoid.WalkSpeed = shift and (16 * _G.YH.sprintBoost) or 16
    end
end)

-- Flashlight
RunService.Heartbeat:Connect(function()
    if _G.YH.flOn then
        if not _G.YH.flObj then _G.YH.flObj = Instance.new("SpotLight"); _G.YH.flObj.Brightness = 2; _G.YH.flObj.Range = 60; _G.YH.flObj.Angle = 90; _G.YH.flObj.Face = Enum.NormalId.Front; _G.YH.flObj.Parent = Camera end
        _G.YH.flObj.Enabled = true
    elseif _G.YH.flObj then _G.YH.flObj.Enabled = false end
end)