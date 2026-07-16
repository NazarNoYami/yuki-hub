--[[
  Yuki Hub v4.2 - WindUI (FIXED API)
  ESP Line + Projectile Aimbot + Lead Prediction
--]]

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Window
local Window = WindUI:CreateWindow({
    Title = "Yuki Hub v4.2",
    Folder = "YukiHub",
    Icon = "solar:home-2-bold-duotone",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = { Title = "Open Yuki Hub", CornerRadius = UDim.new(1,0), Enabled = true, Draggable = true, Scale = 0.5 },
    Topbar = { Height = 44, ButtonsType = "Mac" },
})

Window:Tag({ Title = "v4.2", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })

-- Colors
local Blue = Color3.fromHex("#257AF7"); local Green = Color3.fromHex("#10C550"); local Red = Color3.fromHex("#EF4F1D")
local Yellow = Color3.fromHex("#ECA201"); local Purple = Color3.fromHex("#7775F2"); local Grey = Color3.fromHex("#83889E")

-- Helpers
local function GetClosestPlayer(fov)
    local closest = nil; local cd = fov or math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local pos, on = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if on then local d = (Vector2.new(pos.X,pos.Y)-Vector2.new(Mouse.X,Mouse.Y)).Magnitude; if d < cd then cd = d; closest = p end end
        end
    end
    return closest
end

local function GetTargetPos(t)
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then return t.Character.HumanoidRootPart.Position end
    return nil
end

-- Projectile Aimbot
local projOn = false; local projV = 150; local projG = 196.2; local projTarget = nil; local projLead = true; local projLeadFac = 1
local prevPos = {}; local tVel = {}
local function GetTargetVel(t)
    local pos = GetTargetPos(t); if not pos then return Vector3.new() end
    local pr = prevPos[t]; prevPos[t] = pos
    if pr then local vel = (pos-pr)/0.1; tVel[t] = tVel[t] and (tVel[t]*0.7+vel*0.3) or vel end
    return tVel[t] or Vector3.new()
end
local function CalcAngle(orig, trg, vel, grav)
    local dx=trg.X-orig.X; local dz=trg.Z-orig.Z; local dy=trg.Y-orig.Y; local d=math.sqrt(dx*dx+dz*dz)
    if d<1 then return nil end; local vSq=vel*vel; local g=grav or 196.2
    local a=(g*d*d)/(2*vSq); local b=-d; local c=a+dy; local disc=b*b-4*a*c
    if disc<0 then return nil end; local sd=math.sqrt(disc)
    local ang=math.atan((-b+sd)/(2*a)); if ang<0 then ang=math.atan((-b-sd)/(2*a)) end
    if ang<0 then return nil end; return ang
end
local function GetAimPoint(orig, trg, vel, grav)
    local aimT = trg
    if projLead then
        local est = (trg-orig).Magnitude / (vel*0.707)
        if est>0 then local pred = GetTargetPos(projTarget) + GetTargetVel(projTarget) * est * projLeadFac; if pred then aimT = pred end end
    end
    local ang = CalcAngle(orig, aimT, vel, grav); if not ang then return nil end
    local dx=aimT.X-orig.X; local dz=aimT.Z-orig.Z; local d=math.sqrt(dx*dx+dz*dz); local ho=math.tan(ang)*d
    return aimT + Vector3.new(0, ho, 0)
end

-- ESP
local espLineObj = nil; local espLineOn = false; local projArcObj = nil; local projArcOn = false
local function UpdateESPLine(t)
    if not espLineOn or not t then if espLineObj then espLineObj.Visible=false end; return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then if espLineObj then espLineObj.Visible=false end; return end
    local tp=GetTargetPos(t); if not tp then if espLineObj then espLineObj.Visible=false end; return end
    local mp=LocalPlayer.Character.HumanoidRootPart.Position; local from,_=Camera:WorldToViewportPoint(mp); local to,_=Camera:WorldToViewportPoint(tp)
    if not espLineObj then espLineObj=Drawing.new("Line"); espLineObj.Thickness=2; espLineObj.Color=Color3.fromRGB(0,255,100); espLineObj.Transparency=0.5 end
    espLineObj.From=Vector2.new(from.X,from.Y); espLineObj.To=Vector2.new(to.X,to.Y); espLineObj.Visible=true
end
local function DrawArc(orig, trg, vel, grav)
    if not projArcObj then projArcObj=Drawing.new("Line"); projArcObj.Thickness=1; projArcObj.Color=Color3.fromRGB(255,200,50); projArcObj.Transparency=0.3 end
    if not projArcOn or not trg then projArcObj.Visible=false; return end
    local ang=CalcAngle(orig,trg,vel,grav); if not ang then projArcObj.Visible=false; return end
    local dx=trg.X-orig.X; local dz=trg.Z-orig.Z; local dir=Vector2.new(dx,dz).Unit; local g=grav or 196.2; local v=vel
    local vx=v*math.cos(ang); local vy=v*math.sin(ang); local pts={}; local tt=(2*vy)/g
    for t=0,tt,0.1 do local x=vx*t; local y=vy*t-0.5*g*t*t; local pos=orig+Vector3.new(dir.X*x,y,dir.Y*x); local sp,_=Camera:WorldToViewportPoint(pos); table.insert(pts,Vector2.new(sp.X,sp.Y)) end
    if #pts>1 then projArcObj.Visible=true; projArcObj.Points=pts else projArcObj.Visible=false end
end

-- Basic Aimbot
local aimOn = false; local aimSmooth = 1; local aimFOV = 90

-- Bright Mode
local brightOn = false; local brightLevel = 1
local originalLighting = {
    Ambient = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
}

-- ============== TABS ==============
-- Main Tab
local MainTab = Window:Tab({ Title = "Main", Icon = "solar:home-2-bold", IconColor = Grey, Border = true })

local GameSect = MainTab:Section({ Title = "Game Options" })
GameSect:Button({ Title = "Rejoin Server", Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end })
GameSect:Space()
GameSect:Button({ Title = "Server Hop", Callback = function()
    local function gs(c) local u="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100"; if c then u=u.."&cursor="..c end; return HttpService:JSONDecode(game:HttpGet(u)) end
    local s=gs(); if s and s.data then for _,v in pairs(s.data) do if v.playing<v.maxPlayers and v.id~=game.JobId then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,v.id,LocalPlayer); return end end end
end})

local MoveSect = MainTab:Section({ Title = "Movement" })
MoveSect:Toggle({ Title = "Walkspeed", Callback = function(s) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = s and 50 or 16 end end })
MoveSect:Space()
MoveSect:Slider({ Title = "Walkspeed Value", Width = 200, Value = { Min=16, Max=250, Default=50 }, Step = 1, Callback = function(v) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = v end end })
MoveSect:Space()
MoveSect:Dropdown({ Title = "Jump Power", Values = {"50","75","100","150","200"}, Value = 1, Callback = function(s) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.JumpPower = tonumber(s) end end })

-- ESP Tab
local ESPTab = Window:Tab({ Title = "ESP", Icon = "solar:eye-bold", IconColor = Green, Border = true })
local ESPVis = ESPTab:Section({ Title = "Visuals" })

local ESPObjs = {}; local ESPOn = false
ESPVis:Toggle({ Title = "ESP Box", Callback = function(s)
    ESPOn = s
    if s then
        for _, p in pairs(Players:GetPlayers()) do if p~=LocalPlayer then
            local box=Drawing.new("Square"); box.Thickness=2; box.Color=Color3.fromRGB(255,50,50); box.Filled=false; box.Visible=false
            local nl=Drawing.new("Text"); nl.Center=true; nl.Size=14; nl.Outline=true; nl.Color=Color3.fromRGB(255,255,255); nl.Visible=false
            ESPObjs[p]={Box=box,Name=nl}
        end end
        RunService.RenderStepped:Connect(function() if not ESPOn then return end
            for plr,o in pairs(ESPObjs) do
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local root=plr.Character.HumanoidRootPart; local pos,on=Camera:WorldToViewportPoint(root.Position)
                    if on then local sz=Vector2.new(2000/pos.Z,3000/pos.Z); o.Box.Size=sz; o.Box.Position=Vector2.new(pos.X-sz.X/2,pos.Y-sz.Y/2); o.Box.Visible=true; o.Name.Position=Vector2.new(pos.X,pos.Y-sz.Y/2-16); o.Name.Text=plr.Name; o.Name.Visible=true
                    else o.Box.Visible=false; o.Name.Visible=false end
                else o.Box.Visible=false; o.Name.Visible=false end end end)
    else for _,o in pairs(ESPObjs) do o.Box.Visible=false; o.Name.Visible=false end end
end})
ESPVis:Space()
ESPVis:Toggle({ Title = "ESP Line", Desc = "Green line to locked target", Callback = function(s) espLineOn = s; if not s and espLineObj then espLineObj.Visible=false end end })
ESPVis:Space()
ESPVis:Toggle({ Title = "Projectile Arc", Desc = "Trajectory prediction", Callback = function(s) projArcOn = s; if not s and projArcObj then projArcObj.Visible=false end end })

-- Aimbot Tab
local AimTab = Window:Tab({ Title = "Aimbot", Icon = "solar:crosshair-bold", IconColor = Red, Border = true })

local BasicAim = AimTab:Section({ Title = "Basic Aimbot" })
BasicAim:Toggle({ Title = "Basic Aimbot", Callback = function(s) aimOn = s; if s then projOn=false end end })
BasicAim:Space()
BasicAim:Slider({ Title = "Smoothness", Width = 200, Value = { Min=1, Max=10, Default=1 }, Step = 1, Callback = function(v) aimSmooth = v end })
BasicAim:Space()
BasicAim:Slider({ Title = "FOV", Width = 200, Value = { Min=10, Max=360, Default=90 }, Step = 1, Callback = function(v) aimFOV = v end })

local ProjAim = AimTab:Section({ Title = "Projectile Aimbot (Bows/Daggers)" })
ProjAim:Toggle({ Title = "Projectile Aimbot", Desc = "For arcing weapons", Callback = function(s) projOn = s; if s then aimOn=false end end })
ProjAim:Space()
ProjAim:Slider({ Title = "Projectile Velocity", Width = 200, Value = { Min=30, Max=500, Default=150 }, Step = 5, Callback = function(v) projV = v end })
ProjAim:Space()
ProjAim:Slider({ Title = "Gravity", Width = 200, Value = { Min=50, Max=500, Default=196.2 }, Step = 1, Callback = function(v) projG = v end })
ProjAim:Space()
ProjAim:Toggle({ Title = "Lead Prediction", Desc = "Auto-aim ahead of moving targets", Callback = function(s) projLead = s end })
ProjAim:Space()
ProjAim:Slider({ Title = "Lead Factor", Width = 200, Value = { Min=0.5, Max=3, Default=1 }, Step = 0.1, Callback = function(v) projLeadFac = v end })
ProjAim:Space()
ProjAim:Button({ Title = "Lock Target", Color = Blue, Icon = "target", Callback = function() projTarget = GetClosestPlayer(360) end })
ProjAim:Space()
ProjAim:Button({ Title = "Unlock Target", Color = Red, Icon = "x", Callback = function() projTarget = nil end })

-- Misc Tab
local MiscTab = Window:Tab({ Title = "Misc", Icon = "solar:settings-bold", IconColor = Purple, Border = true })
local MiscSect = MiscTab:Section({ Title = "Utilities" })
MiscSect:Button({ Title = "Reset Character", Desc = "Kill yourself", Callback = function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.Health = 0 end end })
MiscSect:Space()
MiscSect:Button({ Title = "Anti AFK", Desc = "Prevent auto-kick", Callback = function() LocalPlayer.Idled:Connect(function() VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1); task.wait(0.1); VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1) end) end })
MiscSect:Space()
MiscSect:Slider({ Title = "FPS Cap", Width = 200, Value = { Min=15, Max=360, Default=60 }, Step = 1, Callback = function(v) setfpscap(v) end })
MiscSect:Space()

local BrightSect = MiscTab:Section({ Title = "Bright Mode" })
BrightSect:Toggle({ Title = "Bright Mode", Desc = "Make dark maps visible", Callback = function(s)
    brightOn = s
    if s then
        local b = brightLevel * 2
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = b
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
        Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Ambient = originalLighting.Ambient
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        Lighting.ColorShift_Top = originalLighting.ColorShift_Top
        Lighting.ColorShift_Bottom = originalLighting.ColorShift_Bottom
    end
end })
BrightSect:Space()
BrightSect:Slider({ Title = "Brightness Level", Width = 200, Value = { Min=0.5, Max=5, Default=1 }, Step = 0.1, Callback = function(v)
    brightLevel = v
    if brightOn then
        Lighting.Brightness = v * 2
    end
end })

MiscSect:Space()
MiscSect:Button({ Title = "Infinite Yield", Desc = "Admin commands", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end })

-- Credits Tab
local CreditTab = Window:Tab({ Title = "Credits", Icon = "solar:info-square-bold", IconColor = Grey, IconShape = "Square", Border = true })
local CreditSect = CreditTab:Section({ Title = "Info" })
CreditSect:Button({ Title = "Yuki Hub v4.2", Desc = "Made for Tuan | WindUI | Delta Executor", Callback = function() end })

-- ============== MAIN LOOP ==============
RunService.RenderStepped:Connect(function()
    -- ESP Line
    if espLineOn then
        local t = projTarget or GetClosestPlayer(360)
        UpdateESPLine(t)
    end
    -- Projectile Arc
    if projArcOn and projTarget and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local tp = GetTargetPos(projTarget)
        if tp then DrawArc(LocalPlayer.Character.HumanoidRootPart.Position, tp, projV, projG) end
    end
    -- Basic Aimbot
    if aimOn then
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local c = GetClosestPlayer(aimFOV)
        if c and c.Character then
            local pos = Camera:WorldToViewportPoint(c.Character.HumanoidRootPart.Position)
            local t = Vector2.new(pos.X,pos.Y); local cur = Vector2.new(Mouse.X,Mouse.Y)
            local s = t:Lerp(cur, 1/aimSmooth); mousemoverel(s.X-cur.X, s.Y-cur.Y)
        end
    end
    -- Projectile Aimbot
    if projOn then
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local target = projTarget or GetClosestPlayer(360)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
            local origin = LocalPlayer.Character.HumanoidRootPart.Position
            local tPos = target.Character.HumanoidRootPart.Position
            local aim = GetAimPoint(origin, tPos, projV, projG)
            if aim then
                local pos, on = Camera:WorldToViewportPoint(aim)
                if on then
                    local t = Vector2.new(pos.X,pos.Y); local cur = Vector2.new(Mouse.X,Mouse.Y)
                    local s = t:Lerp(cur, 1/aimSmooth); mousemoverel(s.X-cur.X, s.Y-cur.Y)
                end
            end
        end
    end
end)