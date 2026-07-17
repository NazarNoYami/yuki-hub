-- [[ FILE: _init.lua ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

if _G.YH and _G.YH.Cleanup then
    pcall(_G.YH.Cleanup)
end

for _, child in ipairs(CoreGui:GetChildren()) do
    if child.Name == "YukiHub" or child.Name == "YukiHubHUD" then child:Destroy() end
end

local connections, drawings, instances, restorers = {}, {}, {}, {}
local YH = {
    Players = Players,
    LocalPlayer = LocalPlayer,
    RunService = RunService,
    UserInputService = UserInputService,
    VirtualInputManager = VirtualInputManager,
    HttpService = HttpService,
    Lighting = Lighting,
    CoreGui = CoreGui,
    Mouse = LocalPlayer:GetMouse(),
    C = {Blue = Color3.fromRGB(90, 140, 255), Red = Color3.fromRGB(255, 90, 105)},
    fovVal = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70,
    brightLevel = 1,
    fogS = 0,
    fogE = 1000,
    walkSpeed = 32,
    sprintMultiplier = 1.25,
    jumpPower = 50,
    chLen = 10,
    chW = 2,
}

function YH.GetCamera()
    return workspace.CurrentCamera
end

function YH.GetMap()
    return workspace:FindFirstChild("Map") or workspace
end

function YH.Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

function YH.TrackDrawing(drawing)
    table.insert(drawings, drawing)
    return drawing
end

function YH.TrackInstance(instance)
    table.insert(instances, instance)
    return instance
end

function YH.OnCleanup(callback)
    table.insert(restorers, callback)
end

function YH.Cleanup()
    for i = #restorers, 1, -1 do pcall(restorers[i]) end
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    for _, drawing in ipairs(drawings) do pcall(function() drawing:Remove() end) end
    for _, instance in ipairs(instances) do pcall(function() instance:Destroy() end) end
    for _, child in ipairs(CoreGui:GetChildren()) do
        if child.Name == "YukiHub" or child.Name == "YukiHubHUD" then pcall(function() child:Destroy() end) end
    end
end

_G.YH = YH

local WINDUI_COMMIT = "7b1d561cf658da1f2f49e700cf52963e7bdcb23a"
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/" .. WINDUI_COMMIT .. "/dist/main.lua"))()
YH.Window = WindUI:CreateWindow({
    Title = "Yuki Hub v6",
    Folder = "YukiHub",
    Icon = "solar:home-2-bold-duotone",
    NewElements = true,
    HideSearchBar = true,
    Topbar = {Height = 42, ButtonsType = "Default"},
})

local function tab(title, icon)
    return YH.Window:Tab({Title = title, Icon = icon, IconColor = Color3.fromHex("#8EA8FF"), Border = true})
end

YH.Tabs = {
    Main = tab("Main", "solar:home-2-bold-duotone"),
    ESP = tab("ESP", "solar:eye-bold-duotone"),
    Aimbot = tab("Combat", "solar:target-bold-duotone"),
    Visuals = tab("Visual", "solar:palette-bold-duotone"),
    Misc = tab("Utility", "solar:settings-bold-duotone"),
    HUD = tab("HUD", "solar:chart-bold-duotone"),
    Credits = tab("Info", "solar:info-circle-bold-duotone"),
}

-- [[ FILE: main.lua ]]
local YH = _G.YH
local T = YH.Tabs.Main

local server = T:Section({Title = "Server"})
server:Button({Title = "Rejoin", Callback = function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, YH.LocalPlayer)
end})
server:Space()
server:Button({Title = "Server Hop", Desc = "Find an available public server", Callback = function()
    local cursor
    repeat
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor then url = url .. "&cursor=" .. YH.HttpService:UrlEncode(cursor) end
        local ok, page = pcall(function() return YH.HttpService:JSONDecode(game:HttpGet(url)) end)
        if not ok or not page then return end
        for _, serverInfo in ipairs(page.data or {}) do
            if serverInfo.playing < serverInfo.maxPlayers and serverInfo.id ~= game.JobId then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, serverInfo.id, YH.LocalPlayer)
                return
            end
        end
        cursor = page.nextPageCursor
    until not cursor
end})

local movement = T:Section({Title = "Movement"})
movement:Toggle({Title = "Speed", Callback = function(value) YH.speedOn = value end})
movement:Space()
movement:Slider({Title = "Walk Speed", Width = 200, Value = {Min = 16, Max = 100, Default = 32}, Step = 1, Callback = function(value) YH.walkSpeed = value end})
movement:Space()
movement:Toggle({Title = "Sprint", Desc = "Hold Shift; uses Walk Speed as base", Callback = function(value) YH.sprintOn = value end})
movement:Space()
movement:Slider({Title = "Sprint Multiplier", Width = 200, Value = {Min = 1, Max = 2, Default = 1.25}, Step = 0.05, Callback = function(value) YH.sprintMultiplier = value end})
movement:Space()
movement:Toggle({Title = "Noclip", Callback = function(value) YH.noclipOn = value end})
movement:Space()
movement:Slider({Title = "Jump Power", Width = 200, Value = {Min = 50, Max = 200, Default = 50}, Step = 5, Callback = function(value) YH.jumpPower = value end})

local collisionState = setmetatable({}, {__mode = "k"})
local lastCharacter
local function restoreCollision()
    for part, canCollide in pairs(collisionState) do
        if part.Parent then part.CanCollide = canCollide end
        collisionState[part] = nil
    end
end

YH.OnCleanup(function()
    restoreCollision()
    local character = YH.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.WalkSpeed = 16; humanoid.JumpPower = 50 end
end)

YH.Connect(YH.RunService.Stepped, function()
    local character = YH.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if character ~= lastCharacter then restoreCollision(); lastCharacter = character end

    local speed = YH.speedOn and YH.walkSpeed or 16
    if YH.sprintOn and (YH.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or YH.UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then
        speed = speed * YH.sprintMultiplier
    end
    humanoid.WalkSpeed = speed
    humanoid.JumpPower = YH.jumpPower

    if YH.noclipOn then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if collisionState[part] == nil then collisionState[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    elseif next(collisionState) then
        restoreCollision()
    end
end)

-- [[ FILE: visuals.lua ]]
local YH = _G.YH
local T = YH.Tabs.Visuals
local Lighting = YH.Lighting
local original = {
    Ambient = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ExposureCompensation = Lighting.ExposureCompensation,
}

local function restoreLighting()
    for property, value in pairs(original) do Lighting[property] = value end
    local camera = YH.GetCamera()
    if camera then camera.FieldOfView = YH.originalFOV or 70 end
end
YH.originalFOV = YH.GetCamera() and YH.GetCamera().FieldOfView or 70
YH.OnCleanup(restoreLighting)

local lighting = T:Section({Title = "Lighting"})
lighting:Toggle({Title = "Full Bright", Callback = function(value) YH.brightOn = value; if not value then restoreLighting() end end})
lighting:Space()
lighting:Slider({Title = "Brightness", Width = 200, Value = {Min = 0.5, Max = 5, Default = 1}, Step = 0.1, Callback = function(value) YH.brightLevel = value end})
lighting:Space()
lighting:Toggle({Title = "Custom Fog", Callback = function(value) YH.fogOn = value; if not value then Lighting.FogStart = original.FogStart; Lighting.FogEnd = original.FogEnd end end})
lighting:Space()
lighting:Slider({Title = "Fog Start", Width = 200, Value = {Min = 0, Max = 500, Default = 0}, Step = 1, Callback = function(value) YH.fogS = value end})
lighting:Space()
lighting:Slider({Title = "Fog End", Width = 200, Value = {Min = 100, Max = 5000, Default = 1000}, Step = 10, Callback = function(value) YH.fogE = value end})

local cameraSection = T:Section({Title = "Camera"})
cameraSection:Toggle({Title = "Custom FOV", Callback = function(value) YH.fovOn = value end})
cameraSection:Space()
cameraSection:Slider({Title = "Field of View", Width = 200, Value = {Min = 30, Max = 120, Default = 70}, Step = 1, Callback = function(value) YH.fovVal = value end})

YH.Connect(YH.RunService.RenderStepped, function()
    if YH.brightOn then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = YH.brightLevel * 2
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = false
    end
    if YH.fogOn then Lighting.FogStart = YH.fogS; Lighting.FogEnd = YH.fogE end
    local camera = YH.GetCamera()
    if camera then camera.FieldOfView = YH.fovOn and YH.fovVal or YH.originalFOV end
end)

-- [[ FILE: esp.lua ]]
-- ESP Tab
local YH = _G.YH
local T = YH.Tabs.ESP

-- Helper: clear table without table.clear()
local function ClearTable(t)
    for k in pairs(t) do t[k] = nil end
end

-- ============== PLAYER ESP ==============
local PH = T:Section({ Title = "Player ESP" })
local playerESPOn = false
local playerHighlights = {}
local playerLabels = {}
local ESPObjs = {}

local function RemoveDrawing(drawing)
    if drawing then pcall(function() drawing:Remove() end) end
end

local function RemovePlayerDrawing(player)
    local object = ESPObjs and ESPObjs[player]
    if object then RemoveDrawing(object.Box); RemoveDrawing(object.Name); ESPObjs[player] = nil end
end

local function GetTeamInfo(plr)
    local team = plr.Team
    if not team then return "Other", Color3.fromRGB(255, 255, 255) end
    local tn = team.Name:lower()
    if tn:find("maniac") or tn:find("killer") then return "Killer", Color3.fromRGB(255, 80, 80) end
    if tn:find("survivor") then return "Survivor", Color3.fromRGB(100, 255, 100) end
    return "Other", Color3.fromRGB(255, 255, 255)
end

PH:Toggle({ Title = "Player ESP", Desc = "Highlight + name + distance + status", Callback = function(s)
    playerESPOn = s
    if not s then
        for _, v in pairs(playerHighlights) do pcall(function() v:Destroy() end) end; ClearTable(playerHighlights)
        for _, v in pairs(playerLabels) do pcall(function() v.Parent:Destroy() end) end; ClearTable(playerLabels)
    end
end})
PH:Space()

-- ============== DRAWING ESP ==============
local DE = T:Section({ Title = "Drawing ESP" })

-- ESP Box
local espBoxOn = false
local function EnsurePlayerDrawing(player)
    if player == YH.LocalPlayer or ESPObjs[player] then return end
    local box = YH.TrackDrawing(Drawing.new("Square"))
    box.Thickness = 2
    box.Color = Color3.fromRGB(255, 80, 90)
    box.Filled = false
    box.Visible = false
    local name = YH.TrackDrawing(Drawing.new("Text"))
    name.Center = true
    name.Size = 14
    name.Outline = true
    name.Color = Color3.new(1, 1, 1)
    name.Visible = false
    ESPObjs[player] = {Box = box, Name = name}
end
DE:Toggle({ Title = "ESP Box", Callback = function(s)
    espBoxOn = s
    if s then
        for _, p in pairs(YH.Players:GetPlayers()) do EnsurePlayerDrawing(p) end
    else
        for _, o in pairs(ESPObjs) do
            o.Box.Visible = false; o.Name.Visible = false
        end
    end
end})
DE:Space()

-- ESP Line
local espLineOn = false
local espLineColor = Color3.fromRGB(0, 255, 100)
local espLineMode = "Single"
local espLineOrigin = "Character"
local espLineObjs = {}

DE:Toggle({ Title = "ESP Line", Callback = function(s)
    espLineOn = s
    if not s then
        for _, o in pairs(espLineObjs) do o.Visible = false end
    end
end})
DE:Space()
DE:Colorpicker({ Title = "Line Color", Default = espLineColor, Callback = function(c) espLineColor = c end })
DE:Space()
DE:Dropdown({ Title = "Line Mode", Values = {"Single", "All Players"}, Value = 1, Callback = function(s) espLineMode = (s == "All Players") and "All" or "Single" end })
DE:Space()
DE:Dropdown({ Title = "Line Origin", Values = {"Character", "Top Screen"}, Value = 1, Callback = function(s) espLineOrigin = s end })
DE:Space()

-- Projectile Arc
DE:Toggle({ Title = "Projectile Arc", Desc = "Shows the locked target trajectory", Callback = function(s) YH.projArcOn = s end })
DE:Space()

-- ============== OBJECT ESP ==============
local OE = T:Section({ Title = "Object ESP" })

-- Cache for object scanning
local cacheTimer = 0
local cachedGens = {}
local cachedHooks = {}
local cachedPallets = {}
local cachedGates = {}
local cachedWindows = {}
local genH = {}; local genL = {}; local genOn = false
local hookH = {}; local hookL = {}; local hookOn = false
local palH = {}; local palOn = false
local gateH = {}; local gateL = {}; local gateOn = false
local winL = {}; local winOn = false

local function Prune(objects)
    for object, visual in pairs(objects) do
        if not object.Parent then
            pcall(function()
                if visual.Destroy then visual:Destroy() else visual:Remove() end
            end)
            objects[object] = nil
        end
    end
end

local function ScanObjects()
    ClearTable(cachedGens)
    ClearTable(cachedHooks)
    ClearTable(cachedPallets)
    ClearTable(cachedGates)
    ClearTable(cachedWindows)

    for _, obj in pairs(YH.GetMap():GetDescendants()) do
        if not obj:IsA("Model") and not obj:IsA("BasePart") then continue end
        local ln = obj.Name:lower()

        if obj:IsA("Model") then
            if ln:find("generator") or obj:GetAttribute("RepairProgress") ~= nil then table.insert(cachedGens, obj)
            elseif ln:find("hook") then table.insert(cachedHooks, obj)
            elseif ln:find("pallet") then table.insert(cachedPallets, obj)
            elseif ln:find("gate") or ln:find("exit") then table.insert(cachedGates, obj) end
        end

        if obj:IsA("BasePart") and ln:find("window") then
            table.insert(cachedWindows, obj)
        end
    end
    Prune(genH); Prune(genL); Prune(hookH); Prune(hookL); Prune(palH); Prune(gateH); Prune(gateL); Prune(winL)
end

OE:Toggle({ Title = "Generator ESP", Callback = function(s)
    genOn = s
    if not s then
        for _, v in pairs(genH) do pcall(function() v:Destroy() end) end; ClearTable(genH)
        for _, v in pairs(genL) do pcall(function() v:Destroy() end) end; ClearTable(genL)
    end
end})
OE:Space()
OE:Toggle({ Title = "Hook ESP", Callback = function(s)
    hookOn = s
    if not s then
        for _, v in pairs(hookH) do pcall(function() v:Destroy() end) end; ClearTable(hookH)
        for _, v in pairs(hookL) do pcall(function() v.Parent:Destroy() end) end; ClearTable(hookL)
    end
end})
OE:Space()
OE:Toggle({ Title = "Pallet ESP", Callback = function(s)
    palOn = s
    if not s then
        for _, v in pairs(palH) do pcall(function() v:Destroy() end) end; ClearTable(palH)
    end
end})
OE:Space()
OE:Toggle({ Title = "Gate ESP", Callback = function(s)
    gateOn = s
    if not s then
        for _, v in pairs(gateH) do pcall(function() v:Destroy() end) end; ClearTable(gateH)
        for _, v in pairs(gateL) do pcall(function() v.Parent:Destroy() end) end; ClearTable(gateL)
    end
end})
OE:Space()
OE:Toggle({ Title = "Window ESP", Callback = function(s)
    winOn = s
    if not s then
        for _, v in pairs(winL) do pcall(function() v.Parent:Destroy() end) end; ClearTable(winL)
    end
end})

-- ============== HELPER ==============
local function GetClosestPlayer(fov)
    local closest, cd = nil, fov or math.huge
    for _, p in pairs(YH.Players:GetPlayers()) do
        if p ~= YH.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local camera = YH.GetCamera()
            local pos, on = camera and camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if on then
                local d = (Vector2.new(pos.X, pos.Y) - Vector2.new(YH.Mouse.X, YH.Mouse.Y)).Magnitude
                if d < cd then cd = d; closest = p end
            end
        end
    end
    return closest
end

-- ============== PROJ ARC HELPERS ==============
local prevPos = {}
local tVel = {}
local velocityDt = 1 / 60
local function GetTargetPos(t)
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        return t.Character.HumanoidRootPart.Position
    end
    return nil
end
local function GetTargetVel(t)
    local pos = GetTargetPos(t)
    if not pos then return Vector3.new() end
    local pr = prevPos[t]
    prevPos[t] = pos
    if pr then
        local vel = (pos - pr) / math.max(velocityDt, 1 / 240)
        tVel[t] = tVel[t] and (tVel[t] * 0.7 + vel * 0.3) or vel
    end
    return tVel[t] or Vector3.new()
end
local function CalcAngle(orig, trg, vel, grav)
    local dx = trg.X - orig.X; local dz = trg.Z - orig.Z; local dy = trg.Y - orig.Y
    local d = math.sqrt(dx * dx + dz * dz)
    if d < 1 then return nil end
    local vSq = vel * vel; local g = grav or 196.2
    local a = (g * d * d) / (2 * vSq); local b = -d; local c = a + dy
    local disc = b * b - 4 * a * c
    if disc < 0 then return nil end
    local sd = math.sqrt(disc)
    local ang = math.atan((-b + sd) / (2 * a))
    if ang < 0 then ang = math.atan((-b - sd) / (2 * a)) end
    if ang < 0 then return nil end
    return ang
end

-- ============== MAIN ESP LOOP ==============
local arcLines = {}
YH.Connect(YH.RunService.RenderStepped, function(dt)
    velocityDt = dt
    local camera = YH.GetCamera()
    if not camera then return end
    -- Cache scan every 2 seconds
    cacheTimer = cacheTimer + dt
    if cacheTimer >= 2 then
        cacheTimer = 0
        ScanObjects()
    end

    -- ESP Box
    if espBoxOn then
        for _, player in ipairs(YH.Players:GetPlayers()) do EnsurePlayerDrawing(player) end
        for plr, o in pairs(ESPObjs) do
            if not plr.Parent then RemovePlayerDrawing(plr); continue end
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local root = plr.Character.HumanoidRootPart
                local pos, on = camera:WorldToViewportPoint(root.Position)
                if on and pos.Z > 0 then
                    local sz = Vector2.new(2000 / pos.Z, 3000 / pos.Z)
                    o.Box.Size = sz
                    o.Box.Position = Vector2.new(pos.X - sz.X / 2, pos.Y - sz.Y / 2)
                    o.Box.Visible = true
                    o.Name.Position = Vector2.new(pos.X, pos.Y - sz.Y / 2 - 16)
                    o.Name.Text = plr.Name
                    o.Name.Visible = true
                else
                    o.Box.Visible = false; o.Name.Visible = false
                end
            else
                o.Box.Visible = false; o.Name.Visible = false
            end
        end
    end

    -- ESP Line
    if espLineOn then
        local mp, msp = nil, nil
        if YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            mp = YH.LocalPlayer.Character.HumanoidRootPart.Position
            msp, _ = camera:WorldToViewportPoint(mp)
        end
        local ori
        if espLineOrigin == "Top Screen" then
            ori = Vector2.new(camera.ViewportSize.X / 2, 0)
        elseif msp then
            ori = Vector2.new(msp.X, msp.Y)
        else
            for _, o in pairs(espLineObjs) do o.Visible = false end
        end
        if ori then
            local targets = {}
            if espLineMode == "Single" then
                local t = YH.projTarget or GetClosestPlayer(360)
                if t then table.insert(targets, t) end
            else
                for _, p in pairs(YH.Players:GetPlayers()) do
                    if p ~= YH.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                        table.insert(targets, p)
                    end
                end
            end
            for i = #targets + 1, #espLineObjs do espLineObjs[i].Visible = false end
            for i, target in ipairs(targets) do
                if not espLineObjs[i] then
                    espLineObjs[i] = YH.TrackDrawing(Drawing.new("Line"))
                    espLineObjs[i].Thickness = 2
                    espLineObjs[i].Color = espLineColor
                    espLineObjs[i].Transparency = 0.6
                end
                local tp = target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character.HumanoidRootPart.Position
                if tp then
                    local to, visible = camera:WorldToViewportPoint(tp)
                    espLineObjs[i].From = ori
                    espLineObjs[i].To = Vector2.new(to.X, to.Y)
                    espLineObjs[i].Visible = visible and to.Z > 0
                    espLineObjs[i].Color = espLineColor
                else
                    espLineObjs[i].Visible = false
                end
            end
        end
    end

    -- Projectile Arc
    if YH.projArcOn and YH.projTarget and YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local tp = GetTargetPos(YH.projTarget)
        if tp then
            local orig = YH.LocalPlayer.Character.HumanoidRootPart.Position
            local trg = tp; local vel = YH.projV; local grav = YH.projG
            local ang = CalcAngle(orig, trg, vel, grav)
            if ang then
                local dx = trg.X - orig.X; local dz = trg.Z - orig.Z
                local dir = Vector2.new(dx, dz).Unit; local g = grav; local v = vel
                local vx = v * math.cos(ang); local vy = v * math.sin(ang)
                local pts = {}; local tt = (2 * vy) / g
                for t = 0, tt, 0.1 do
                    local x = vx * t; local y = vy * t - 0.5 * g * t * t
                    local pos = orig + Vector3.new(dir.X * x, y, dir.Y * x)
                    local sp, visible = camera:WorldToViewportPoint(pos)
                    table.insert(pts, {point = Vector2.new(sp.X, sp.Y), visible = visible and sp.Z > 0})
                end
                if #pts > 1 then
                    for i = 1, #pts - 1 do
                        if not arcLines[i] then
                            arcLines[i] = YH.TrackDrawing(Drawing.new("Line"))
                            arcLines[i].Thickness = 1
                            arcLines[i].Color = Color3.fromRGB(255, 200, 50)
                            arcLines[i].Transparency = 0.7
                        end
                        arcLines[i].From = pts[i].point
                        arcLines[i].To = pts[i + 1].point
                        arcLines[i].Visible = pts[i].visible and pts[i + 1].visible
                    end
                    for i = #pts, #arcLines do arcLines[i].Visible = false end
                else for _, line in ipairs(arcLines) do line.Visible = false end end
            else
                for _, line in ipairs(arcLines) do line.Visible = false end
            end
        end
    else
        for _, line in ipairs(arcLines) do line.Visible = false end
    end

    -- Player ESP (Highlight)
    if playerESPOn then
        for _, plr in pairs(YH.Players:GetPlayers()) do
            if plr == YH.LocalPlayer then continue end
            local char = plr.Character
            if not char then continue end
            local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
            if not head then continue end
            local tt, bc = GetTeamInfo(plr)
            local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid")
            local hooked = char:GetAttribute("IsHooked") or char:GetAttribute("Hooked")
            local knocked = hum and hum.Health < hum.MaxHealth * 0.3
            local color = bc
            if tt == "Survivor" then
                if hooked then color = Color3.fromRGB(255, 110, 80)
                elseif knocked then color = Color3.fromRGB(255, 170, 80)
                elseif hum and hum.Health < hum.MaxHealth then color = Color3.fromRGB(255, 255, 120)
                else color = Color3.fromRGB(100, 255, 100) end
            end
            if not playerHighlights[plr] then
                local hl = Instance.new("Highlight")
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.OutlineColor = Color3.new(1, 1, 1)
                hl.FillTransparency = 0.5
                hl.Parent = YH.CoreGui
                playerHighlights[plr] = hl
            end
            local hl = playerHighlights[plr]
            hl.Adornee = char
            hl.FillColor = color
            hl.FillTransparency = 0.3
            hl.OutlineTransparency = 0
            if not playerLabels[plr] or not playerLabels[plr].Parent then
                local bill = Instance.new("BillboardGui")
                bill.Size = UDim2.new(0, 200, 0, 50)
                bill.StudsOffset = Vector3.new(0, 3, 0)
                bill.AlwaysOnTop = true
                bill.Parent = YH.CoreGui
                local txt = Instance.new("TextLabel")
                txt.Size = UDim2.new(1, 0, 1, 0)
                txt.BackgroundTransparency = 1
                txt.Font = Enum.Font.SourceSansSemibold
                txt.TextSize = 14
                txt.TextStrokeTransparency = 0.3
                txt.TextStrokeColor3 = Color3.new(0, 0, 0)
                txt.TextXAlignment = Enum.TextXAlignment.Center
                txt.Parent = bill
                playerLabels[plr] = txt
            end
            local txt = playerLabels[plr]
            txt.Parent.Adornee = head
            local dist = 0
            if YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                dist = math.floor((head.Position - YH.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
            end
            local line3 = tostring(dist) .. "m"
            local line2 = ""
            if tt == "Killer" then
                local sk = plr:GetAttribute("SelectedKiller") or plr:GetAttribute("KillerName")
                line2 = sk and "KILLER: " .. tostring(sk) or "KILLER"
            elseif tt == "Survivor" then
                if hooked then line2 = "HOOKED"
                elseif knocked then line2 = "HURT" end
            end
            txt.Text = plr.Name .. " | " .. line3 .. (line2 ~= "" and (" | " .. line2) or "")
            txt.TextColor3 = color
        end
    end

    -- Object ESP using cached scan results
    if genOn then
        for _, obj in pairs(cachedGens) do
            local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if not att then continue end
            local progress = obj:GetAttribute("RepairProgress") or 0
            local repairing = obj:GetAttribute("PlayersRepairingCount") or 0
            local full = progress >= 100
            if not genH[obj] then
                local hl = Instance.new("Highlight")
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
                hl.FillColor = Color3.new(1, 1, 1); hl.OutlineColor = Color3.new(1, 1, 1)
                hl.Parent = YH.CoreGui; genH[obj] = hl
                local bill = Instance.new("BillboardGui")
                bill.Name = "YukiGeneratorCard"
                bill.Size = UDim2.new(0, 145, 0, 46)
                bill.StudsOffset = Vector3.new(0, 3.2, 0)
                bill.AlwaysOnTop = true; bill.Parent = YH.CoreGui
                local card = Instance.new("Frame")
                card.Name = "Card"; card.Size = UDim2.fromScale(1, 1)
                card.BackgroundColor3 = Color3.fromRGB(15, 18, 28); card.BackgroundTransparency = 0.12
                card.BorderSizePixel = 0; card.Parent = bill
                Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)
                local stroke = Instance.new("UIStroke", card)
                stroke.Color = Color3.fromRGB(95, 115, 175); stroke.Transparency = 0.35; stroke.Thickness = 1
                local title = Instance.new("TextLabel")
                title.Name = "Title"; title.Position = UDim2.new(0, 8, 0, 4); title.Size = UDim2.new(1, -50, 0, 13)
                title.BackgroundTransparency = 1; title.Font = Enum.Font.SourceSansSemibold; title.TextSize = 11
                title.TextColor3 = Color3.fromRGB(235, 240, 255); title.TextXAlignment = Enum.TextXAlignment.Left
                title.Text = "GENERATOR"; title.Parent = card
                local percent = Instance.new("TextLabel")
                percent.Name = "Percent"; percent.Position = UDim2.new(1, -42, 0, 4); percent.Size = UDim2.new(0, 34, 0, 13)
                percent.BackgroundTransparency = 1; percent.Font = Enum.Font.SourceSansBold; percent.TextSize = 11
                percent.TextColor3 = Color3.fromRGB(125, 220, 255); percent.TextXAlignment = Enum.TextXAlignment.Right
                percent.Parent = card
                local track = Instance.new("Frame")
                track.Name = "Track"; track.Position = UDim2.new(0, 8, 0, 20); track.Size = UDim2.new(1, -16, 0, 6)
                track.BackgroundColor3 = Color3.fromRGB(39, 44, 61); track.BorderSizePixel = 0; track.ClipsDescendants = true; track.Parent = card
                Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
                local fill = Instance.new("Frame")
                fill.Name = "Fill"; fill.Size = UDim2.fromScale(0, 1); fill.BackgroundColor3 = Color3.fromRGB(255, 95, 105)
                fill.BorderSizePixel = 0; fill.Parent = track
                Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
                local gradient = Instance.new("UIGradient", fill)
                gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(205, 225, 255))
                local status = Instance.new("TextLabel")
                status.Name = "Status"; status.Position = UDim2.new(0, 8, 0, 29); status.Size = UDim2.new(1, -16, 0, 12)
                status.BackgroundTransparency = 1; status.Font = Enum.Font.SourceSans; status.TextSize = 10
                status.TextColor3 = Color3.fromRGB(165, 175, 205); status.TextXAlignment = Enum.TextXAlignment.Left
                status.Parent = card
                genL[obj] = bill
            end
            genH[obj].Adornee = obj
            local bill = genL[obj]
            bill.Adornee = att
            local card = bill.Card
            local percent = card.Percent
            local fill = card.Track.Fill
            local status = card.Status
            local ratio = math.clamp(progress / 100, 0, 1)
            local color = ratio < 0.5
                and Color3.fromRGB(255, 90, 105):Lerp(Color3.fromRGB(255, 205, 85), ratio * 2)
                or Color3.fromRGB(255, 205, 85):Lerp(Color3.fromRGB(85, 235, 145), (ratio - 0.5) * 2)
            fill.Size = UDim2.fromScale(ratio, 1)
            fill.BackgroundColor3 = color
            percent.Text = string.format("%.0f%%", progress)
            percent.TextColor3 = color
            status.Text = repairing > 0 and (tostring(repairing) .. " repairing") or "Ready for repair"
            if full then
                status.Text = "COMPLETED"
                status.TextColor3 = Color3.fromRGB(100, 245, 155)
                genH[obj].FillColor = Color3.fromRGB(85, 235, 145)
                genH[obj].OutlineColor = Color3.fromRGB(85, 235, 145)
            else
                status.TextColor3 = repairing > 0 and Color3.fromRGB(125, 205, 255) or Color3.fromRGB(165, 175, 205)
                genH[obj].FillColor = color
                genH[obj].OutlineColor = color
            end
        end
    end
    if hookOn then
        for _, obj in pairs(cachedHooks) do
            local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if not att then continue end
            if not hookH[obj] then
                local hl = Instance.new("Highlight")
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillTransparency = 0.6; hl.FillColor = Color3.fromRGB(255, 80, 80)
                hl.OutlineColor = Color3.fromRGB(255, 0, 0); hl.Parent = YH.CoreGui; hookH[obj] = hl
                local bill = Instance.new("BillboardGui")
                bill.Size = UDim2.new(0, 100, 0, 30); bill.StudsOffset = Vector3.new(0, 2, 0)
                bill.AlwaysOnTop = true; bill.Parent = YH.CoreGui
                local txt = Instance.new("TextLabel")
                txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1
                txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14
                txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0, 0, 0)
                txt.TextXAlignment = Enum.TextXAlignment.Center
                txt.TextColor3 = Color3.fromRGB(255, 100, 100); txt.Text = "Hook"; txt.Parent = bill; hookL[obj] = txt
            end
            hookH[obj].Adornee = obj
        end
    end
    if palOn then
        for _, obj in pairs(cachedPallets) do
            local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if not att then continue end
            if not palH[obj] then
                local hl = Instance.new("Highlight")
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
                hl.FillColor = Color3.fromRGB(255, 255, 100); hl.OutlineColor = Color3.fromRGB(255, 200, 0)
                hl.Parent = YH.CoreGui; palH[obj] = hl
            end
            palH[obj].Adornee = obj
        end
    end
    if gateOn then
        for _, obj in pairs(cachedGates) do
            local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if not att then continue end
            if not gateH[obj] then
                local hl = Instance.new("Highlight")
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
                hl.FillColor = Color3.fromRGB(160, 0, 255); hl.OutlineColor = Color3.fromRGB(200, 120, 255)
                hl.Parent = YH.CoreGui; gateH[obj] = hl
                local bill = Instance.new("BillboardGui")
                bill.Size = UDim2.new(0, 100, 0, 30); bill.StudsOffset = Vector3.new(0, 2, 0)
                bill.AlwaysOnTop = true; bill.Parent = YH.CoreGui
                local txt = Instance.new("TextLabel")
                txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1
                txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14
                txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0, 0, 0)
                txt.TextXAlignment = Enum.TextXAlignment.Center
                txt.TextColor3 = Color3.fromRGB(200, 150, 255); txt.Text = "Gate"; txt.Parent = bill; gateL[obj] = txt
            end
            gateH[obj].Adornee = att
        end
    end
    if winOn then
        for _, obj in pairs(cachedWindows) do
            if not winL[obj] then
                local bill = Instance.new("BillboardGui")
                bill.Size = UDim2.new(0, 80, 0, 25); bill.StudsOffset = Vector3.new(0, 1.5, 0)
                bill.AlwaysOnTop = true; bill.Parent = YH.CoreGui
                local txt = Instance.new("TextLabel")
                txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1
                txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 12
                txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0, 0, 0)
                txt.TextXAlignment = Enum.TextXAlignment.Center
                txt.TextColor3 = Color3.fromRGB(180, 230, 255); txt.Text = "Window"; txt.Parent = bill; winL[obj] = txt
            end
            winL[obj].Parent.Adornee = obj
        end
    end
end)

YH.Connect(YH.Players.PlayerRemoving, function(player)
    RemovePlayerDrawing(player)
    local highlight = playerHighlights[player]
    if highlight then highlight:Destroy(); playerHighlights[player] = nil end
    local label = playerLabels[player]
    if label and label.Parent then label.Parent:Destroy(); playerLabels[player] = nil end
end)

YH.OnCleanup(function()
    for _, group in ipairs({playerHighlights, genH, hookH, palH, gateH}) do
        for _, object in pairs(group) do pcall(function() object:Destroy() end) end
    end
    for _, group in ipairs({playerLabels, genL, hookL, gateL, winL}) do
        for _, label in pairs(group) do pcall(function()
            if label:IsA("BillboardGui") then label:Destroy() else label.Parent:Destroy() end
        end) end
    end
end)

-- [[ FILE: aimbot.lua ]]
local YH = _G.YH
local T = YH.Tabs.Aimbot

YH.aimOn = false
YH.aimSmooth = 4
YH.aimFOV = 120
YH.projOn = false
YH.projV = 150
YH.projG = 196.2
YH.projLead = true
YH.projLeadFac = 1
YH.projTarget = nil

local function rootOf(player)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and humanoid and humanoid.Health > 0 then return root end
end

local function closestPlayer(radius)
    local camera = YH.GetCamera()
    if not camera then return nil end
    local mouse = Vector2.new(YH.Mouse.X, YH.Mouse.Y)
    local closest, distance = nil, radius
    for _, player in ipairs(YH.Players:GetPlayers()) do
        if player ~= YH.LocalPlayer then
            local root = rootOf(player)
            if root then
                local point, visible = camera:WorldToViewportPoint(root.Position)
                if visible and point.Z > 0 then
                    local current = (Vector2.new(point.X, point.Y) - mouse).Magnitude
                    if current < distance then closest, distance = player, current end
                end
            end
        end
    end
    return closest
end

local previous = setmetatable({}, {__mode = "k"})
local velocity = setmetatable({}, {__mode = "k"})
local function targetVelocity(player, position, dt)
    local old = previous[player]
    previous[player] = position
    if old and dt > 0 then
        local measured = (position - old) / dt
        velocity[player] = velocity[player] and velocity[player]:Lerp(measured, 0.3) or measured
    end
    return velocity[player] or Vector3.new()
end

local function projectilePoint(origin, player, dt)
    local root = rootOf(player)
    if not root or YH.projV <= 0 then return nil end
    local target = root.Position
    if YH.projLead then
        local travelTime = (target - origin).Magnitude / YH.projV
        target = target + targetVelocity(player, target, dt) * travelTime * YH.projLeadFac
    end
    local horizontal = Vector3.new(target.X - origin.X, 0, target.Z - origin.Z)
    local distance = horizontal.Magnitude
    if distance < 1 then return target end
    local speedSquared = YH.projV * YH.projV
    local height = target.Y - origin.Y
    local discriminant = speedSquared * speedSquared - YH.projG * (YH.projG * distance * distance + 2 * height * speedSquared)
    if discriminant < 0 then return nil end
    local angle = math.atan((speedSquared - math.sqrt(discriminant)) / (YH.projG * distance))
    return target + Vector3.new(0, math.tan(angle) * distance, 0)
end

local basic = T:Section({Title = "Aim Assist"})
basic:Toggle({Title = "Enable", Desc = "Nearest visible player inside FOV", Callback = function(value) YH.aimOn = value end})
basic:Space()
basic:Slider({Title = "FOV Radius", Width = 200, Value = {Min = 30, Max = 360, Default = 120}, Step = 5, Callback = function(value) YH.aimFOV = value end})
basic:Space()
basic:Slider({Title = "Smoothness", Width = 200, Value = {Min = 1, Max = 12, Default = 4}, Step = 1, Callback = function(value) YH.aimSmooth = value end})

local projectile = T:Section({Title = "Projectile"})
projectile:Toggle({Title = "Ballistic Aim", Callback = function(value) YH.projOn = value end})
projectile:Space()
projectile:Slider({Title = "Velocity", Width = 200, Value = {Min = 30, Max = 500, Default = 150}, Step = 5, Callback = function(value) YH.projV = value end})
projectile:Space()
projectile:Slider({Title = "Gravity", Width = 200, Value = {Min = 50, Max = 500, Default = 196}, Step = 1, Callback = function(value) YH.projG = value end})
projectile:Space()
projectile:Toggle({Title = "Movement Prediction", Default = true, Callback = function(value) YH.projLead = value end})
projectile:Space()
projectile:Slider({Title = "Lead Factor", Width = 200, Value = {Min = 0.5, Max = 2, Default = 1}, Step = 0.1, Callback = function(value) YH.projLeadFac = value end})
projectile:Space()
projectile:Button({Title = "Lock Nearest", Callback = function() YH.projTarget = closestPlayer(YH.aimFOV) end})
projectile:Space()
projectile:Button({Title = "Clear Lock", Color = YH.C.Red, Callback = function() YH.projTarget = nil end})

YH.Connect(YH.RunService.RenderStepped, function(dt)
    if not YH.aimOn and not YH.projOn then return end
    if type(mousemoverel) ~= "function" then return end
    local camera = YH.GetCamera()
    local character = YH.LocalPlayer.Character
    local ownRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not camera or not ownRoot then return end

    local target = rootOf(YH.projTarget) and YH.projTarget or closestPlayer(YH.aimFOV)
    local targetRoot = rootOf(target)
    if not targetRoot then return end
    local worldPoint = targetRoot.Position
    if YH.projOn then
        worldPoint = projectilePoint(ownRoot.Position, target, dt)
        if not worldPoint then return end
    end
    local point, visible = camera:WorldToViewportPoint(worldPoint)
    if not visible or point.Z <= 0 then return end
    local current = Vector2.new(YH.Mouse.X, YH.Mouse.Y)
    local delta = (Vector2.new(point.X, point.Y) - current) / math.max(YH.aimSmooth, 1)
    mousemoverel(delta.X, delta.Y)
end)

-- [[ FILE: misc.lua ]]
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
YH.skillRecorded = nil
YH.skillRecording = false
skill:Button({Title = "Record Next Input", Desc = "Open a skill check, then press or click it once", Callback = function()
    YH.skillRecording = true
    warn("[Yuki] Skill input recorder armed")
end})
skill:Space()
skill:Button({Title = "Clear Recorded Input", Callback = function()
    YH.skillRecorded = nil
    YH.skillRecording = false
    warn("[Yuki] Recorded skill input cleared")
end})
skill:Space()
skill:Toggle({Title = "Auto Skill Check", Desc = "Replays the recorded input inside the goal", Callback = function(value)
    if value and not YH.skillRecorded then warn("[Yuki] Record one manual skill input first") end
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

local function activeSkillCheck()
    local gui = findSkillGui()
    if not gui or not gui.Enabled then return nil end
    local check = gui:FindFirstChild("Check", true)
    if check and check:IsA("GuiObject") then return gui, check end
end

YH.Connect(YH.UserInputService.InputBegan, function(input)
    if not YH.skillRecording then return end
    local _, check = activeSkillCheck()
    if not check then return end

    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
        YH.skillRecorded = {kind = "Key", key = input.KeyCode}
        YH.skillRecording = false
        warn("[Yuki] Recorded skill key: " .. input.KeyCode.Name)
        return
    end

    local button
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then button = 0
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then button = 1
    elseif input.UserInputType == Enum.UserInputType.MouseButton3 then button = 2 end
    if button == nil then return end

    local position, size = check.AbsolutePosition, check.AbsoluteSize
    local pointer = YH.UserInputService:GetMouseLocation()
    if input.UserInputType == Enum.UserInputType.Touch then pointer = input.Position end
    YH.skillRecorded = {
        kind = "Pointer",
        button = button,
        x = math.clamp((pointer.X - position.X) / math.max(size.X, 1), 0, 1),
        y = math.clamp((pointer.Y - position.Y) / math.max(size.Y, 1), 0, 1),
    }
    YH.skillRecording = false
    warn("[Yuki] Recorded skill pointer input")
end)

local function sendSkillInput(check)
    local recorded = YH.skillRecorded
    if not recorded then return end
    if recorded.kind == "Key" then
        YH.VirtualInputManager:SendKeyEvent(true, recorded.key, false, game)
        task.delay(0.04, function() pcall(function() YH.VirtualInputManager:SendKeyEvent(false, recorded.key, false, game) end) end)
        return
    end
    local position, size = check.AbsolutePosition, check.AbsoluteSize
    local x, y = position.X + size.X * recorded.x, position.Y + size.Y * recorded.y
    YH.VirtualInputManager:SendMouseButtonEvent(x, y, recorded.button, true, game, 0)
    task.delay(0.04, function() pcall(function() YH.VirtualInputManager:SendMouseButtonEvent(x, y, recorded.button, false, game, 0) end) end)
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

    if not YH.skillOn or not YH.skillRecorded then skillGui = nil; previousRotation = nil; armed = true; return end
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
        pcall(sendSkillInput, check)
    elseif math.abs(difference) > YH.skillTolerance + 12 then
        armed = true
    end
    previousRotation = rotation
end)

-- [[ FILE: hud.lua ]]
local YH = _G.YH
local T = YH.Tabs.HUD
local section = T:Section({Title = "Status Overlay"})
local enabled, showFPS, showPing, showKiller = false, true, true, true
local gui

local function createLabel(parent, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function createHUD()
    local screen = YH.TrackInstance(Instance.new("ScreenGui"))
    screen.Name = "YukiHubHUD"
    screen.ResetOnSpawn = false
    screen.Parent = YH.CoreGui
    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.Position = UDim2.new(1, -12, 0, 12)
    frame.Size = UDim2.new(0, 164, 0, 74)
    frame.BackgroundColor3 = Color3.fromRGB(16, 19, 29)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = screen
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(85, 105, 165)
    stroke.Transparency = 0.35
    local padding = Instance.new("UIPadding", frame)
    padding.PaddingTop = UDim.new(0, 7); padding.PaddingLeft = UDim.new(0, 9)
    local layout = Instance.new("UIListLayout", frame)
    layout.Padding = UDim.new(0, 2)
    gui = {
        screen = screen,
        frame = frame,
        fps = createLabel(frame, Color3.fromRGB(120, 255, 160)),
        ping = createLabel(frame, Color3.fromRGB(125, 190, 255)),
        killer = createLabel(frame, Color3.fromRGB(255, 120, 135)),
    }
end

local function destroyHUD()
    if gui then pcall(function() gui.screen:Destroy() end); gui = nil end
end

section:Toggle({Title = "Enable HUD", Callback = function(value) enabled = value; if not value then destroyHUD() end end})
section:Space()
section:Toggle({Title = "FPS", Default = true, Callback = function(value) showFPS = value end})
section:Space()
section:Toggle({Title = "Ping", Default = true, Callback = function(value) showPing = value end})
section:Space()
section:Toggle({Title = "Killer", Default = true, Callback = function(value) showKiller = value end})

YH.OnCleanup(destroyHUD)
local elapsed, frames, fps = 0, 0, 0
YH.Connect(YH.RunService.RenderStepped, function(dt)
    elapsed = elapsed + dt; frames = frames + 1
    if elapsed >= 0.5 then fps = math.floor(frames / elapsed + 0.5); elapsed = 0; frames = 0 end
    if not enabled then return end
    if not gui then createHUD() end
    local visible = 0
    gui.fps.Visible = showFPS
    if showFPS then gui.fps.Text = "FPS  " .. fps; visible = visible + 1 end
    gui.ping.Visible = showPing
    if showPing then gui.ping.Text = "PING  " .. math.floor(YH.LocalPlayer:GetNetworkPing() * 1000) .. " ms"; visible = visible + 1 end
    gui.killer.Visible = showKiller
    if showKiller then
        local name = "--"
        for _, player in ipairs(YH.Players:GetPlayers()) do
            local teamName = player.Team and player.Team.Name:lower() or ""
            if teamName:find("maniac") or teamName:find("killer") then name = player.Name; break end
        end
        gui.killer.Text = "KILLER  " .. name
        visible = visible + 1
    end
    gui.frame.Size = UDim2.new(0, 164, 0, math.max(30, 12 + visible * 20))
end)

-- [[ FILE: credits.lua ]]
-- Credits Tab
local YH = _G.YH
local T = YH.Tabs.Credits
local S = T:Section({ Title = "Yuki Hub v6" })
S:Button({ Title = "Clean modular build", Desc = "Delta-oriented | Pinned dependencies | Rerun safe", Callback = function() end })
S:Space()
S:Button({ Title = "Unload Hub", Color = YH.C.Red, Callback = function() YH.Cleanup(); _G.YH = nil end })
