--[[
  Yuki Hub v5.0 - Ultimate Edition
  Merged: Yuki Hub + Essential + Notties
  WindUI Library
--]]

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera
local Map = Workspace:FindFirstChild("Map") or Workspace

-- Window
local Window = WindUI:CreateWindow({
    Title = "Yuki Hub v5.0",
    Folder = "YukiHub",
    Icon = "solar:home-2-bold-duotone",
    NewElements = true, HideSearchBar = false,
    Theme = "Ocean",
    OpenButton = { Title = "Open Yuki Hub", CornerRadius = UDim.new(1,0), Enabled = true, Draggable = true, Scale = 0.5 },
    Topbar = { Height = 44, ButtonsType = "Default" },
})

Window:Tag({ Title = "v5.0", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })

-- Set blue accent
Window:SetAccentColor(Color3.fromRGB(0, 120, 255))

-- Colors
local Blue = Color3.fromHex("#257AF7"); local Green = Color3.fromHex("#10C550"); local Red = Color3.fromHex("#EF4F1D")
local Yellow = Color3.fromHex("#ECA201"); local Purple = Color3.fromHex("#7775F2"); local Grey = Color3.fromHex("#83889E")

-- ============== HELPERS ==============
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

-- ============== PROJECTILE AIMBOT ==============
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

-- ============== DRAWING ESP ==============
local espLineOn = false; local projArcObj = nil; local projArcOn = false
local espLineColor = Color3.fromRGB(0, 255, 100)
local espLineMode = "Single"; local espLineOrigin = "Character"
local espLineObjects = {}

local function UpdateESPLineMulti()
    if not espLineOn then for _, obj in pairs(espLineObjects) do obj.Visible = false end; return end
    local myPos = nil; local myScreenPos = nil
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        myPos = LocalPlayer.Character.HumanoidRootPart.Position; myScreenPos, _ = Camera:WorldToViewportPoint(myPos)
    end
    local originPoint
    if espLineOrigin == "Top Screen" then originPoint = Vector2.new(Camera.ViewportSize.X / 2, 0)
    elseif myScreenPos then originPoint = Vector2.new(myScreenPos.X, myScreenPos.Y)
    else for _, obj in pairs(espLineObjects) do obj.Visible = false end; return end
    local targets = {}
    if espLineMode == "Single" then local t = projTarget or GetClosestPlayer(360); if t then table.insert(targets, t) end
    else for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then table.insert(targets, p) end end end
    for i = #targets + 1, #espLineObjects do espLineObjects[i].Visible = false end
    for i, target in ipairs(targets) do
        if not espLineObjects[i] then espLineObjects[i] = Drawing.new("Line"); espLineObjects[i].Thickness = 2; espLineObjects[i].Color = espLineColor; espLineObjects[i].Transparency = 0.6 end
        local obj = espLineObjects[i]; local tp = GetTargetPos(target)
        if tp then local to, _ = Camera:WorldToViewportPoint(tp); obj.From = originPoint; obj.To = Vector2.new(to.X, to.Y); obj.Visible = true; obj.Color = espLineColor else obj.Visible = false end
    end
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

-- ============== HIGHLIGHT ESP SYSTEM (Notties + Essential) ==============
-- Player ESP
local playerHighlights = {}; local playerLabels = {}; local playerESPOn = false

local function GetTeamInfo(plr)
    local team = plr.Team; if not team then return "Other", Color3.fromRGB(255,255,255) end
    local tn = team.Name:lower()
    if tn:find("maniac") or tn:find("killer") then return "Killer", Color3.fromRGB(255,80,80) end
    if tn:find("survivor") then return "Survivor", Color3.fromRGB(100,255,100) end
    return "Other", Color3.fromRGB(255,255,255)
end

local function UpdatePlayerESP()
    if not playerESPOn then
        for _, v in pairs(playerHighlights) do pcall(function() v:Destroy() end) end
        for _, v in pairs(playerLabels) do pcall(function() v.Parent:Destroy() end) end
        table.clear(playerHighlights); table.clear(playerLabels); return
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character; if not char then continue end
        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"); if not head then continue end
        local teamType, baseColor = GetTeamInfo(plr)
        local humanoid = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid")
        local hooked = char:GetAttribute("IsHooked") or char:GetAttribute("Hooked")
        local knocked = humanoid and humanoid.Health < humanoid.MaxHealth * 0.3
        local selectedKiller = plr:GetAttribute("SelectedKiller") or plr:GetAttribute("KillerName")

        -- Determine color
        local color = baseColor
        if teamType == "Survivor" then
            if hooked then color = Color3.fromRGB(255,110,80)
            elseif knocked then color = Color3.fromRGB(255,170,80)
            elseif humanoid and humanoid.Health < humanoid.MaxHealth then color = Color3.fromRGB(255,255,120)
            else color = Color3.fromRGB(100,255,100) end
        end

        -- Highlight
        if not playerHighlights[plr] then
            local hl = Instance.new("Highlight")
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.OutlineColor = Color3.new(1,1,1); hl.FillTransparency = 0.5; hl.Parent = Camera
            playerHighlights[plr] = hl
        end
        local hl = playerHighlights[plr]; hl.Adornee = char; hl.FillColor = color; hl.FillTransparency = 0.3; hl.OutlineTransparency = 0

        -- Billboard label
        if not playerLabels[plr] or not playerLabels[plr].Parent then
            local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0,200,0,50); bill.StudsOffset = Vector3.new(0,3,0); bill.AlwaysOnTop = true
            local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.3; txt.TextStrokeColor3 = Color3.new(0,0,0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.Parent = bill
            bill.Parent = Camera; playerLabels[plr] = txt
        end
        local txt = playerLabels[plr]
        local bill = txt.Parent; bill.Adornee = head
        local dist = 0
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            dist = math.floor((head.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
        end
        local line1 = plr.Name; local line2 = ""; local line3 = tostring(dist) .. "m"
        if teamType == "Killer" then
            line2 = "KILLER"
            if selectedKiller then line2 = "KILLER: " .. tostring(selectedKiller) end
            color = Color3.fromRGB(255,80,80)
        elseif teamType == "Survivor" then
            if hooked then line2 = "HOOKED"; color = Color3.fromRGB(255,110,80)
            elseif knocked then line2 = "HURT"; color = Color3.fromRGB(255,170,80) end
        end
        txt.Text = line1 .. " | " .. line3
        if line2 ~= "" then txt.Text = line1 .. " | " .. line3 .. " | " .. line2 end
        txt.TextColor3 = color
    end
end

-- Generator ESP
local genHighlights = {}; local genLabels = {}; local genESPOn = false
local function UpdateGeneratorESP()
    if not genESPOn then
        for _, v in pairs(genHighlights) do pcall(function() v:Destroy() end) end
        for _, v in pairs(genLabels) do pcall(function() v.Parent:Destroy() end) end
        table.clear(genHighlights); table.clear(genLabels); return
    end
    for _, obj in pairs(Map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("generator") then
            local attach = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if not attach then continue end
            if not genHighlights[obj] then
                local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.Parent = Camera
                local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0,150,0,30); bill.StudsOffset = Vector3.new(0,2.5,0); bill.AlwaysOnTop = true
                local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0,0,0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.Parent = bill; bill.Parent = Camera
                genHighlights[obj] = hl; genLabels[obj] = txt
            end
            local hl = genHighlights[obj]; hl.Adornee = obj; hl.FillColor = Color3.new(1,1,1); hl.OutlineColor = Color3.new(1,1,1)
            local txt = genLabels[obj]; local bill = txt.Parent; bill.Adornee = attach
            txt.Text = "Generator"; txt.TextColor3 = Color3.fromRGB(200,200,255)
        end
    end
end

-- Hook ESP
local hookHighlights = {}; local hookLabels = {}; local hookESPOn = false
local function UpdateHookESP()
    if not hookESPOn then
        for _, v in pairs(hookHighlights) do pcall(function() v:Destroy() end) end
        for _, v in pairs(hookLabels) do pcall(function() v.Parent:Destroy() end) end
        table.clear(hookHighlights); table.clear(hookLabels); return
    end
    for _, obj in pairs(Map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("hook") then
            local attach = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if not attach then continue end
            if not hookHighlights[obj] then
                local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.6; hl.FillColor = Color3.fromRGB(255,80,80); hl.OutlineColor = Color3.fromRGB(255,0,0); hl.Parent = Camera
                local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0,100,0,30); bill.StudsOffset = Vector3.new(0,2,0); bill.AlwaysOnTop = true
                local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0,0,0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.TextColor3 = Color3.fromRGB(255,100,100); txt.Text = "Hook"; txt.Parent = bill; bill.Parent = Camera
                hookHighlights[obj] = hl; hookLabels[obj] = txt
            end
            local hl = hookHighlights[obj]; hl.Adornee = obj
        end
    end
end

-- Pallet ESP
local palletHighlights = {}; local palletESPOn = false
local function UpdatePalletESP()
    if not palletESPOn then
        for _, v in pairs(palletHighlights) do pcall(function() v:Destroy() end) end
        table.clear(palletHighlights); return
    end
    for _, obj in pairs(Map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("pallet") then
            local attach = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if not attach then continue end
            if not palletHighlights[obj] then
                local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.FillColor = Color3.fromRGB(255,255,100); hl.OutlineColor = Color3.fromRGB(255,200,0); hl.Parent = Camera
                palletHighlights[obj] = hl
            end
            local hl = palletHighlights[obj]; hl.Adornee = obj
        end
    end
end

-- Gate ESP
local gateHighlights = {}; local gateLabels = {}; local gateESPOn = false
local function UpdateGateESP()
    if not gateESPOn then
        for _, v in pairs(gateHighlights) do pcall(function() v:Destroy() end) end
        for _, v in pairs(gateLabels) do pcall(function() v.Parent:Destroy() end) end
        table.clear(gateHighlights); table.clear(gateLabels); return
    end
    for _, obj in pairs(Map:GetDescendants()) do
        local lname = obj.Name:lower()
        if obj:IsA("Model") and (lname:find("gate") or lname:find("exit")) then
            local attach = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if not attach then continue end
            if not gateHighlights[obj] then
                local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.FillColor = Color3.fromRGB(160,0,255); hl.OutlineColor = Color3.fromRGB(200,120,255); hl.Parent = Camera
                local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0,100,0,30); bill.StudsOffset = Vector3.new(0,2,0); bill.AlwaysOnTop = true
                local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0,0,0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.TextColor3 = Color3.fromRGB(200,150,255); txt.Text = "Gate"; txt.Parent = bill; bill.Parent = Camera
                gateHighlights[obj] = hl; gateLabels[obj] = txt
            end
            local hl = gateHighlights[obj]; hl.Adornee = attach
        end
    end
end

-- Window ESP
local windowLabels = {}; local windowESPOn = false
local function UpdateWindowESP()
    if not windowESPOn then
        for _, v in pairs(windowLabels) do pcall(function() v.Parent:Destroy() end) end
        table.clear(windowLabels); return
    end
    for _, obj in pairs(Map:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("window") then
            if not windowLabels[obj] then
                local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0,80,0,25); bill.StudsOffset = Vector3.new(0,1.5,0); bill.AlwaysOnTop = true
                local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 12; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0,0,0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.TextColor3 = Color3.fromRGB(180,230,255); txt.Text = "Window"; txt.Parent = bill; bill.Parent = Camera
                windowLabels[obj] = txt
            end
            local txt = windowLabels[obj]; txt.Parent.Adornee = obj
        end
    end
end

-- ============== ESSENTIAL FEATURES ==============
-- Custom FOV
local fovEnabled = false; local fovValue = 70; local originalFOV = Camera.FieldOfView

-- Speedhack
local speedhackOn = false; local speedhackValue = 32

-- Flashlight
local flashlightOn = false; local flashlightObj = nil

-- Custom Fog
local fogEnabled = false; local fogStart = 0; local fogEnd = 1000; local fogR = 150; local fogG = 150; local fogB = 150

-- Custom Crosshair
local crosshairOn = false; local crosshairLen = 10; local crosshairW = 2; local cxR = 0; local cxG = 255; local cxB = 0
local crosshairGui = nil

-- Noclip
local noclipOn = false

-- Stretched Resolution
local stretchOn = false; local stretchValue = 100

-- Skybox
local skyboxOn = false; local skyBrightness = 50; local skyExposure = 50

-- Sprint Speed
local sprintOn = false; local sprintBoost = 1.05; local sprinting = false

-- HUD
local hudOn = false; local hudShowFPS = true; local hudShowPing = true; local hudShowKiller = true
local hudGui = nil; local hudFrames = 0; local hudTime = 0; local hudFpsVal = 0

-- Config
local configName = "default"

-- ============== MAIN TAB ==============
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

-- ============== ESP TAB ==============
local ESPTab = Window:Tab({ Title = "ESP", Icon = "solar:eye-bold", IconColor = Green, Border = true })
local ESPPlayers = ESPTab:Section({ Title = "Player ESP" })
ESPPlayers:Toggle({ Title = "Player ESP (Highlight)", Desc = "Glow + name + distance + status", Callback = function(s) playerESPOn = s end })
ESPPlayers:Space()

-- Drawing ESP (existing Yuki Hub)
local ESPLines = ESPTab:Section({ Title = "Drawing ESP" })
local ESPObjs = {}; local ESPOn = false
ESPLines:Toggle({ Title = "ESP Box", Desc = "2D box around players", Callback = function(s)
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
ESPLines:Space()
ESPLines:Toggle({ Title = "ESP Line", Desc = "Line to players", Callback = function(s) espLineOn = s; if not s then for _,o in pairs(espLineObjects) do o.Visible=false end end end })
ESPLines:Space()
ESPLines:Colorpicker({ Title = "Line Color", Default = espLineColor, Callback = function(c) espLineColor = c end })
ESPLines:Space()
ESPLines:Dropdown({ Title = "Line Mode", Values = {"Single", "All Players"}, Value = 1, Callback = function(s) espLineMode = (s == "All Players") and "All" or "Single" end })
ESPLines:Space()
ESPLines:Dropdown({ Title = "Line Origin", Values = {"Character", "Top Screen"}, Value = 1, Callback = function(s) espLineOrigin = s end })
ESPLines:Space()
ESPLines:Toggle({ Title = "Projectile Arc", Desc = "Trajectory prediction", Callback = function(s) projArcOn = s; if not s and projArcObj then projArcObj.Visible=false end end })

-- Object ESP (from Notties)
local ESPObj = ESPTab:Section({ Title = "Object ESP" })
ESPObj:Toggle({ Title = "Generator ESP", Desc = "Highlight + label", Callback = function(s) genESPOn = s end })
ESPObj:Space()
ESPObj:Toggle({ Title = "Hook ESP", Desc = "Highlight + label", Callback = function(s) hookESPOn = s end })
ESPObj:Space()
ESPObj:Toggle({ Title = "Pallet ESP", Desc = "Highlight", Callback = function(s) palletESPOn = s end })
ESPObj:Space()
ESPObj:Toggle({ Title = "Gate ESP", Desc = "Highlight + label", Callback = function(s) gateESPOn = s end })
ESPObj:Space()
ESPObj:Toggle({ Title = "Window ESP", Desc = "Label", Callback = function(s) windowESPOn = s end })

-- ============== AIMBOT TAB ==============
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

-- ============== VISUALS TAB ==============
local VisTab = Window:Tab({ Title = "Visuals", Icon = "solar:sun-bold", IconColor = Yellow, Border = true })
local BrightSect = VisTab:Section({ Title = "Bright Mode" })
BrightSect:Toggle({ Title = "Bright Mode", Desc = "Keep maps bright (auto-reapplies)", Callback = function(s) brightOn = s end })
BrightSect:Space()
BrightSect:Slider({ Title = "Brightness Level", Width = 200, Value = { Min=0.5, Max=5, Default=1 }, Step = 0.1, Callback = function(v) brightLevel = v end })
BrightSect:Space()

local FOVSect = VisTab:Section({ Title = "Custom FOV" })
FOVSect:Toggle({ Title = "Custom FOV", Callback = function(s) fovEnabled = s; if s then Camera.FieldOfView = fovValue else Camera.FieldOfView = originalFOV end end })
FOVSect:Space()
FOVSect:Slider({ Title = "FOV Value", Width = 200, Value = { Min=30, Max=120, Default=70 }, Step = 1, Callback = function(v) fovValue = v; if fovEnabled then Camera.FieldOfView = v end end })
FOVSect:Space()

local FogSect = VisTab:Section({ Title = "Custom Fog" })
FogSect:Toggle({ Title = "Custom Fog", Callback = function(s) fogEnabled = s end })
FogSect:Space()
FogSect:Slider({ Title = "Fog Start", Width = 200, Value = { Min=0, Max=500, Default=0 }, Step = 1, Callback = function(v) fogStart = v end })
FogSect:Space()
FogSect:Slider({ Title = "Fog End", Width = 200, Value = { Min=100, Max=2000, Default=1000 }, Step = 10, Callback = function(v) fogEnd = v end })
FogSect:Space()

local SkySect = VisTab:Section({ Title = "Skybox" })
SkySect:Toggle({ Title = "Skybox", Desc = "Override sky brightness", Callback = function(s) skyboxOn = s end })
SkySect:Space()
SkySect:Slider({ Title = "Brightness", Width = 200, Value = { Min=0, Max=100, Default=50 }, Step = 1, Callback = function(v) skyBrightness = v end })
SkySect:Space()
SkySect:Slider({ Title = "Exposure", Width = 200, Value = { Min=0, Max=100, Default=50 }, Step = 1, Callback = function(v) skyExposure = v end })

-- ============== MISC TAB ==============
local MiscTab = Window:Tab({ Title = "Misc", Icon = "solar:settings-bold", IconColor = Purple, Border = true })
local MoveSect2 = MiscTab:Section({ Title = "Movement" })
MoveSect2:Toggle({ Title = "Speedhack", Desc = "Walkspeed boost", Callback = function(s) speedhackOn = s end })
MoveSect2:Space()
MoveSect2:Slider({ Title = "Speed Value", Width = 200, Value = { Min=16, Max=100, Default=32 }, Step = 1, Callback = function(v) speedhackValue = v end })
MoveSect2:Space()
MoveSect2:Toggle({ Title = "Sprint Speed", Desc = "5% faster while sprinting", Callback = function(s) sprintOn = s end })
MoveSect2:Space()
MoveSect2:Toggle({ Title = "Noclip", Desc = "Walk through walls", Callback = function(s) noclipOn = s end })
MoveSect2:Space()

local UtilSect = MiscTab:Section({ Title = "Utilities" })
UtilSect:Toggle({ Title = "Flashlight", Desc = "Senter", Callback = function(s) flashlightOn = s end })
UtilSect:Space()
UtilSect:Toggle({ Title = "Custom Crosshair", Callback = function(s) crosshairOn = s end })
UtilSect:Space()
UtilSect:Slider({ Title = "Crosshair Length", Width = 200, Value = { Min=5, Max=30, Default=10 }, Step = 1, Callback = function(v) crosshairLen = v end })
UtilSect:Space()
UtilSect:Slider({ Title = "Crosshair Width", Width = 200, Value = { Min=1, Max=8, Default=2 }, Step = 1, Callback = function(v) crosshairW = v end })
UtilSect:Space()
UtilSect:Toggle({ Title = "Stretched Res", Desc = "Aspect ratio hack", Callback = function(s) stretchOn = s end })
UtilSect:Space()
UtilSect:Slider({ Title = "Stretch Value", Width = 200, Value = { Min=50, Max=200, Default=100 }, Step = 1, Callback = function(v) stretchValue = v end })
UtilSect:Space()
UtilSect:Button({ Title = "Reset Character", Callback = function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.Health = 0 end end })
UtilSect:Space()
UtilSect:Button({ Title = "Anti AFK", Callback = function() LocalPlayer.Idled:Connect(function() VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1); task.wait(0.1); VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1) end) end })
UtilSect:Space()
UtilSect:Slider({ Title = "FPS Cap", Width = 200, Value = { Min=15, Max=360, Default=60 }, Step = 1, Callback = function(v) setfpscap(v) end })
UtilSect:Space()
UtilSect:Button({ Title = "Infinite Yield", Desc = "Admin commands", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end })

-- ============== HUD TAB ==============
local HUDTab = Window:Tab({ Title = "HUD", Icon = "solar:chart-bold", IconColor = Blue, Border = true })
local HUDSect = HUDTab:Section({ Title = "Essential HUD" })
HUDSect:Toggle({ Title = "Enable HUD", Desc = "FPS, Ping, Killer info", Callback = function(s) hudOn = s end })
HUDSect:Space()
HUDSect:Toggle({ Title = "Show FPS", Default = true, Callback = function(s) hudShowFPS = s end })
HUDSect:Space()
HUDSect:Toggle({ Title = "Show Ping", Default = true, Callback = function(s) hudShowPing = s end })
HUDSect:Space()
HUDSect:Toggle({ Title = "Show Killer", Default = true, Callback = function(s) hudShowKiller = s end })

-- ============== CREDITS TAB ==============
local CreditTab = Window:Tab({ Title = "Credits", Icon = "solar:info-square-bold", IconColor = Grey, IconShape = "Square", Border = true })
local CreditSect = CreditTab:Section({ Title = "Info" })
CreditSect:Button({ Title = "Yuki Hub v5.0", Desc = "Made for Tuan | WindUI | Merged: Essential + Notties", Callback = function() end })
CreditSect:Space()
CreditSect:Button({ Title = "Save Config", Color = Green, Callback = function() end })
CreditSect:Space()
CreditSect:Button({ Title = "Load Config", Color = Blue, Callback = function() end })

-- ============== MAIN LOOP ==============
RunService.RenderStepped:Connect(function()
    -- Bright Mode
    if brightOn then
        local b = brightLevel * 2
        Lighting.Ambient = Color3.fromRGB(255,255,255); Lighting.Brightness = b; Lighting.ClockTime = 12
        Lighting.FogEnd = 100000; Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        Lighting.ColorShift_Top = Color3.fromRGB(255,255,255); Lighting.ColorShift_Bottom = Color3.fromRGB(255,255,255)
    end

    -- ESP Line
    if espLineOn then UpdateESPLineMulti() end

    -- Projectile Arc
    if projArcOn and projTarget and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local tp = GetTargetPos(projTarget); if tp then DrawArc(LocalPlayer.Character.HumanoidRootPart.Position, tp, projV, projG) end
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

    -- Player ESP
    UpdatePlayerESP()

    -- Object ESP
    UpdateGeneratorESP(); UpdateHookESP(); UpdatePalletESP(); UpdateGateESP(); UpdateWindowESP()

    -- Speedhack
    if speedhackOn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = speedhackValue
    end

    -- Noclip
    if noclipOn and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    -- Sprint Speed
    if sprintOn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        sprinting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        LocalPlayer.Character.Humanoid.WalkSpeed = sprinting and 16 * sprintBoost or 16
    end

    -- Custom Fog
    if fogEnabled then
        Lighting.FogStart = fogStart; Lighting.FogEnd = fogEnd; Lighting.FogColor = Color3.fromRGB(fogR, fogG, fogB)
    end

    -- Skybox
    if skyboxOn then
        Lighting.Brightness = skyBrightness / 10; Lighting.ExposureCompensation = skyExposure / 10
    end

    -- HUD
    hudFrames = hudFrames + 1; hudTime = hudTime + 0.1
    if hudTime >= 1 then hudFpsVal = math.floor(hudFrames / hudTime); hudFrames = 0; hudTime = 0 end
end)

-- Flashlight
RunService.Heartbeat:Connect(function()
    if flashlightOn then
        if not flashlightObj then
            flashlightObj = Instance.new("SpotLight")
            flashlightObj.Brightness = 2; flashlightObj.Range = 60; flashlightObj.Angle = 90; flashlightObj.Face = Enum.NormalId.Front
            flashlightObj.Parent = Camera
        end
        flashlightObj.Enabled = true
    elseif flashlightObj then
        flashlightObj.Enabled = false
    end
end)

-- Sprint keybinds
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if sprintOn and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then
        sprinting = true
    end
end)
UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if sprintOn and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then
        sprinting = false
    end
end)