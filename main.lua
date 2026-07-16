--[[
  Yuki Hub v4.1 - WindUI
  ESP Line + Projectile Aimbot
--]]

-- Load WindUI library
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera
local Gravity = Workspace.Gravity

-- Window
local Window = WindUI:CreateWindow({
    Title = "Yuki Hub v4.1",
    Folder = "YukiHub",
    Icon = "solar:home-2-bold-duotone",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Open Yuki Hub",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        Scale = 0.5,
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

Window:Tag({ Title = "v4.1", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })

-- ============== HELPERS ==============
local function GetClosestPlayer(fov)
    local closest = nil; local closestDist = fov or math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local pos, on = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if on then
                local d = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if d < closestDist then closestDist = d; closest = p end
            end
        end
    end
    return closest
end

local function GetTargetPosition(target)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        return target.Character.HumanoidRootPart.Position
    end
    return nil
end

-- ============== ESP LINE ==============
local espLineEnabled = false
local espLineObj = nil

local function CreateESPLine()
    if not espLineObj then
        espLineObj = Drawing.new("Line")
        espLineObj.Thickness = 2
        espLineObj.Color = Color3.fromRGB(0, 255, 100)
        espLineObj.Transparency = 0.5
        espLineObj.Visible = false
    end
end

local function UpdateESPLine(target)
    if not espLineEnabled or not target then
        if espLineObj then espLineObj.Visible = false end
        return
    end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if espLineObj then espLineObj.Visible = false end
        return
    end
    local targetPos = GetTargetPosition(target)
    if not targetPos then
        if espLineObj then espLineObj.Visible = false end
        return
    end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local from, onScreen1 = Camera:WorldToViewportPoint(myPos)
    local to, onScreen2 = Camera:WorldToViewportPoint(targetPos)
    if onScreen1 or onScreen2 then
        espLineObj.From = Vector2.new(from.X, from.Y)
        espLineObj.To = Vector2.new(to.X, to.Y)
        espLineObj.Visible = true
    else
        espLineObj.Visible = false
    end
end

-- ============== PROJECTILE AIMBOT ==============
-- Calculates where to aim so a projectile arcs to the target
local projAimbotEnabled = false
local projVelocity = 150
local projGravity = 196.2
local projAimUp = true
local projTarget = nil

local function CalculateProjectileAngle(origin, target, velocity, gravity)
    local dx = target.X - origin.X
    local dz = target.Z - origin.Z
    local dy = target.Y - origin.Y
    local dist = math.sqrt(dx * dx + dz * dz)
    local flatDist = math.sqrt(dx * dx + dz * dz)
    if flatDist < 1 then return nil end

    local vSq = velocity * velocity
    local g = gravity or 196.2
    local v4 = vSq * vSq

    -- Quadratic: tan^2 * (g * dist^2 / (2 * v^2)) - tan * dist + (g * dist^2 / (2 * v^2) + dy) = 0
    local a = (g * flatDist * flatDist) / (2 * vSq)
    local b = -flatDist
    local c = a + dy

    local discriminant = b * b - 4 * a * c
    if discriminant < 0 then return nil end

    -- Two possible angles: high and low arc
    local sqrtD = math.sqrt(discriminant)
    local tanAngle1 = (-b + sqrtD) / (2 * a)
    local tanAngle2 = (-b - sqrtD) / (2 * a)

    -- Choose the higher arc (tanAngle1 is usually the higher arc for positive angle)
    local angle = math.atan(tanAngle1)
    if angle < 0 then angle = math.atan(tanAngle2) end
    if angle < 0 then return nil end

    return angle
end

local function GetProjectileAimPoint(origin, target, velocity, gravity)
    local angle = CalculateProjectileAngle(origin, target, velocity, gravity)
    if not angle then return nil end

    local dx = target.X - origin.X
    local dz = target.Z - origin.Z
    local dist = math.sqrt(dx * dx + dz * dz)
    local dir = Vector2.new(dx, dz).Unit

    -- Calculate the height offset based on the angle
    local heightOffset = math.tan(angle) * dist
    local aimPos = target + Vector3.new(0, heightOffset, 0)

    return aimPos
end

-- Projectile ESP prediction line (show the arc)
local projArcLine = nil
local projArcVisible = false

local function DrawProjectileArc(origin, target, velocity, gravity)
    if not projArcLine then
        projArcLine = Drawing.new("Line")
        projArcLine.Thickness = 1
        projArcLine.Color = Color3.fromRGB(255, 200, 50)
        projArcLine.Transparency = 0.3
        projArcLine.Visible = false
    end

    if not projArcVisible or not target then
        projArcLine.Visible = false
        return
    end

    local dx = target.X - origin.X
    local dz = target.Z - origin.Z
    local dist = math.sqrt(dx * dx + dz * dz)
    local dir = Vector2.new(dx, dz).Unit

    local angle = CalculateProjectileAngle(origin, target, velocity, gravity)
    if not angle then
        projArcLine.Visible = false
        return
    end

    local g = gravity or 196.2
    local v = velocity
    local vx = v * math.cos(angle)
    local vy = v * math.sin(angle)

    local points = {}
    local timeStep = 0.1
    local totalTime = (2 * vy) / g  -- total flight time

    for t = 0, totalTime, timeStep do
        local x = vx * t
        local y = vy * t - 0.5 * g * t * t
        local pos = origin + Vector3.new(dir.X * x, y, dir.Y * x)
        local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
        table.insert(points, Vector2.new(screenPos.X, screenPos.Y))
    end

    if #points > 1 then
        projArcLine.Visible = true
        projArcLine.Points = points
    else
        projArcLine.Visible = false
    end
end

-- ============== MAIN TAB ==============
local MainPage = Window:Page({ Title = "Main", Icon = "solar:home-2-bold-duotone" })

local GameSection = MainPage:Section({ Title = "Game Options", Side = "Left" })
GameSection:Button({ Title = "Rejoin Server", Description = "Teleport back", Callback = function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end})
GameSection:Button({ Title = "Server Hop", Description = "Find new server", Callback = function()
    local function getServers(c)
        local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100"
        if c then url = url.."&cursor="..c end
        return HttpService:JSONDecode(game:HttpGet(url))
    end
    local s = getServers()
    if s and s.data then
        for _, v in pairs(s.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, v.id, LocalPlayer)
                return
            end
        end
    end
end})

local MoveSection = MainPage:Section({ Title = "Movement", Side = "Right" })
MoveSection:Toggle({ Title = "Walkspeed", Default = false, Callback = function(state)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = state and 50 or 16
    end
end})
MoveSection:Slider({ Title = "Walkspeed Value", Default = 50, Min = 16, Max = 250, Step = 1, Callback = function(v)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end})
MoveSection:Dropdown({ Title = "Jump Power", Default = 1, Values = {"50","75","100","150","200"}, Callback = function(s)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = tonumber(s)
    end
end})

-- ============== ESP TAB ==============
local ESPPage = Window:Page({ Title = "ESP", Icon = "solar:eye-bold-duotone" })
local ESPVis = ESPPage:Section({ Title = "Visuals", Side = "Left" })

local ESPObjs = {}; local ESPOn = false

ESPVis:Toggle({ Title = "ESP Box", Default = false, Callback = function(state)
    ESPOn = state
    if state then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local box = Drawing.new("Square"); box.Thickness = 2; box.Color = Color3.fromRGB(255,50,50); box.Filled = false; box.Visible = false
                local nl = Drawing.new("Text"); nl.Center = true; nl.Size = 14; nl.Outline = true; nl.Color = Color3.fromRGB(255,255,255); nl.Visible = false
                ESPObjs[p] = { Box = box, Name = nl }
            end
        end
        RunService.RenderStepped:Connect(function()
            if not ESPOn then return end
            for plr, o in pairs(ESPObjs) do
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local root = plr.Character.HumanoidRootPart; local pos, on = Camera:WorldToViewportPoint(root.Position)
                    if on then
                        local sz = Vector2.new(2000/pos.Z, 3000/pos.Z); o.Box.Size = sz; o.Box.Position = Vector2.new(pos.X-sz.X/2, pos.Y-sz.Y/2); o.Box.Visible = true
                        o.Name.Position = Vector2.new(pos.X, pos.Y-sz.Y/2-16); o.Name.Text = plr.Name; o.Name.Visible = true
                    else o.Box.Visible = false; o.Name.Visible = false end
                else o.Box.Visible = false; o.Name.Visible = false end
            end
        end)
    else
        for _, o in pairs(ESPObjs) do o.Box.Visible = false; o.Name.Visible = false end
    end
end})

-- ESP Line
ESPVis:Toggle({ Title = "ESP Line", Description = "Line to locked target", Default = false, Callback = function(state)
    espLineEnabled = state
    CreateESPLine()
    if not state and espLineObj then espLineObj.Visible = false end
end})

-- Projectile Arc
ESPVis:Toggle({ Title = "Projectile Arc", Description = "Show trajectory prediction", Default = false, Callback = function(state)
    projArcVisible = state
    if not state and projArcLine then projArcLine.Visible = false end
end})

-- ============== AIMBOT TAB ==============
local AimPage = Window:Page({ Title = "Aimbot", Icon = "solar:crosshair-bold-duotone" })

-- Basic Aimbot Section
local BasicAim = AimPage:Section({ Title = "Basic Aimbot", Side = "Left" })
local aimEnabled = false; local aimSmooth = 1; local aimFOV = 90

BasicAim:Toggle({ Title = "Basic Aimbot", Default = false, Callback = function(s) aimEnabled = s end})
BasicAim:Slider({ Title = "Smoothness", Default = 1, Min = 1, Max = 10, Step = 1, Callback = function(v) aimSmooth = v end})
BasicAim:Slider({ Title = "FOV", Default = 90, Min = 10, Max = 360, Step = 1, Callback = function(v) aimFOV = v end})

-- Projectile Aimbot Section
local ProjAim = AimPage:Section({ Title = "Projectile Aimbot", Side = "Right" })
ProjAim:Toggle({ Title = "Projectile Aimbot", Description = "Aimbot for bows/arcs", Default = false, Callback = function(state)
    projAimbotEnabled = state
    if state then aimEnabled = false end
end})
ProjAim:Slider({ Title = "Projectile Velocity", Description = "Bow/arrow speed", Default = 150, Min = 30, Max = 500, Step = 5, Callback = function(v) projVelocity = v end})
ProjAim:Slider({ Title = "Gravity", Description = "Projectile gravity", Default = 196.2, Min = 50, Max = 500, Step = 1, Callback = function(v) projGravity = v end})
ProjAim:Dropdown({ Title = "Aim Mode", Default = 1, Values = {"Auto Closest", "Lock Target"}, Callback = function(s)
    if s == "Auto Closest" then projTarget = nil end
end})

-- Lock target button
ProjAim:Button({ Title = "Lock Target", Description = "Lock current closest player", Callback = function()
    projTarget = GetClosestPlayer(360)
    if projTarget then
        WindUI:Notify({ Title = "Target Locked", Content = "Locked: " .. projTarget.DisplayName, Duration = 2 })
    end
end})

ProjAim:Button({ Title = "Unlock Target", Callback = function()
    projTarget = nil; WindUI:Notify({ Title = "Target Unlocked", Duration = 2 })
end})

-- ============== AIMBOT LOOP ==============
RunService.RenderStepped:Connect(function()
    -- ESP Line update
    if espLineEnabled and espLineObj then
        local t = projTarget or GetClosestPlayer(360)
        UpdateESPLine(t)
    end

    -- Projectile Arc
    if projArcVisible and projTarget and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local tPos = GetTargetPosition(projTarget)
        if tPos then
            DrawProjectileArc(LocalPlayer.Character.HumanoidRootPart.Position, tPos, projVelocity, projGravity)
        end
    end

    -- Basic Aimbot
    if aimEnabled then
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local closest = GetClosestPlayer(aimFOV)
        if closest and closest.Character then
            local pos = Camera:WorldToViewportPoint(closest.Character.HumanoidRootPart.Position)
            local t = Vector2.new(pos.X, pos.Y); local c = Vector2.new(Mouse.X, Mouse.Y)
            local s = t:Lerp(c, 1/aimSmooth); mousemoverel(s.X-c.X, s.Y-c.Y)
        end
    end

    -- Projectile Aimbot
    if projAimbotEnabled then
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local target = projTarget or GetClosestPlayer(360)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
            local origin = LocalPlayer.Character.HumanoidRootPart.Position
            local targetPos = target.Character.HumanoidRootPart.Position
            local aimPoint = GetProjectileAimPoint(origin, targetPos, projVelocity, projGravity)
            if aimPoint then
                local pos, on = Camera:WorldToViewportPoint(aimPoint)
                if on then
                    local t = Vector2.new(pos.X, pos.Y); local c = Vector2.new(Mouse.X, Mouse.Y)
                    local s = t:Lerp(c, 1/aimSmooth); mousemoverel(s.X-c.X, s.Y-c.Y)
                end
            end
        end
    end
end)

-- ============== MISC TAB ==============
local MiscPage = Window:Page({ Title = "Misc", Icon = "solar:settings-bold-duotone" })
local MiscSect = MiscPage:Section({ Title = "Utilities", Side = "Left" })
MiscSect:Button({ Title = "Reset Character", Description = "Kill yourself", Callback = function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.Health = 0 end
end})
MiscSect:Button({ Title = "Anti AFK", Description = "Prevent kick", Callback = function()
    LocalPlayer.Idled:Connect(function() VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1); task.wait(0.1); VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1) end)
end})
MiscSect:Slider({ Title = "FPS Cap", Default = 60, Min = 15, Max = 360, Step = 1, Callback = function(v) setfpscap(v) end})
MiscSect:Button({ Title = "Infinite Yield", Description = "Admin commands", Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end})

-- ============== CREDITS TAB ==============
local CreditPage = Window:Page({ Title = "Credits", Icon = "solar:info-square-bold-duotone" })
local CreditSect = CreditPage:Section({ Title = "Info", Side = "Left" })
CreditSect:Button({ Title = "Yuki Hub v4.1", Description = "Made for Tuan | WindUI | Delta Executor", Callback = function() end})