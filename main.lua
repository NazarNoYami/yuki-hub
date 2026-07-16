--[[
  Yuki Hub v5.0 - Loader
  Loads WindUI + feature modules
--]]

local base = "https://raw.githubusercontent.com/NazarNoYami/yuki-hub/main"

-- Load WindUI
local WindUI = loadstring(game:HttpGet(base .. "/features/_windui.lua"))()

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

-- Shared state
_G.YH = {
    WindUI = WindUI,
    Players = Players, RunService = RunService, UserInputService = UserInputService,
    VirtualInputManager = VirtualInputManager, HttpService = HttpService,
    Lighting = Lighting, Workspace = Workspace,
    LocalPlayer = LocalPlayer, Mouse = Mouse, Camera = Camera, Map = Map,
    Window = nil, Tabs = {},
}

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "Yuki Hub v5.0",
    Folder = "YukiHub",
    Icon = "solar:home-2-bold-duotone",
    NewElements = true, HideSearchBar = false,
    OpenButton = { Title = "Open Yuki Hub", CornerRadius = UDim.new(1,0), Enabled = true, Draggable = true, Scale = 0.5 },
    Topbar = { Height = 44, ButtonsType = "Default" },
})

Window:Tag({ Title = "v5.0", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })
Window:SetAccentColor(Color3.fromRGB(0, 120, 255))
_G.YH.Window = Window

-- Colors
local C = {}
C.Blue = Color3.fromHex("#257AF7"); C.Green = Color3.fromHex("#10C550"); C.Red = Color3.fromHex("#EF4F1D")
C.Yellow = Color3.fromHex("#ECA201"); C.Purple = Color3.fromHex("#7775F2"); C.Grey = Color3.fromHex("#83889E")
_G.YH.C = C

-- Create tabs
local Tabs = {}
Tabs.Main = Window:Tab({ Title = "Main", Icon = "solar:home-2-bold", IconColor = C.Grey, Border = true })
Tabs.ESP = Window:Tab({ Title = "ESP", Icon = "solar:eye-bold", IconColor = C.Green, Border = true })
Tabs.Aimbot = Window:Tab({ Title = "Aimbot", Icon = "solar:crosshair-bold", IconColor = C.Red, Border = true })
Tabs.Visuals = Window:Tab({ Title = "Visuals", Icon = "solar:sun-bold", IconColor = C.Yellow, Border = true })
Tabs.Misc = Window:Tab({ Title = "Misc", Icon = "solar:settings-bold", IconColor = C.Purple, Border = true })
Tabs.HUD = Window:Tab({ Title = "HUD", Icon = "solar:chart-bold", IconColor = C.Blue, Border = true })
Tabs.Credits = Window:Tab({ Title = "Credits", Icon = "solar:info-square-bold", IconColor = C.Grey, IconShape = "Square", Border = true })
_G.YH.Tabs = Tabs

-- All features are inlined below



-- Main Tab
local YH = _G.YH
local T = YH.Tabs.Main
local S = T:Section({ Title = "Game Options" })
S:Button({ Title = "Rejoin Server", Callback = function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, YH.LocalPlayer)
end})
S:Space()
S:Button({ Title = "Server Hop", Callback = function()
    local function gs(c)
        local u = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100"
        if c then u = u.."&cursor="..c end
        return YH.HttpService:JSONDecode(game:HttpGet(u))
    end
    local s = gs()
    if s and s.data then
        for _, v in pairs(s.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, v.id, YH.LocalPlayer)
                return
            end
        end
    end
end})
local M = T:Section({ Title = "Movement" })
M:Toggle({ Title = "Walkspeed", Callback = function(s)
    if YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then
        YH.LocalPlayer.Character.Humanoid.WalkSpeed = s and 50 or 16
    end
end})
M:Space()
M:Slider({ Title = "Walkspeed Value", Width = 200, Value = { Min=16, Max=250, Default=50 }, Step = 1, Callback = function(v)
    if YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then YH.LocalPlayer.Character.Humanoid.WalkSpeed = v end
end})
M:Space()
M:Dropdown({ Title = "Jump Power", Values = {"50","75","100","150","200"}, Value = 1, Callback = function(s)
    if YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then YH.LocalPlayer.Character.Humanoid.JumpPower = tonumber(s) end
end})

-- ESP Tab
local YH = _G.YH
local T = YH.Tabs.ESP

-- Player ESP (Highlight)
local PH = T:Section({ Title = "Player ESP" })
local playerESPOn = false
local playerHighlights = {}; local playerLabels = {}
local function GetTeamInfo(plr)
    local team = plr.Team; if not team then return "Other", Color3.fromRGB(255,255,255) end
    local tn = team.Name:lower()
    if tn:find("maniac") or tn:find("killer") then return "Killer", Color3.fromRGB(255,80,80) end
    if tn:find("survivor") then return "Survivor", Color3.fromRGB(100,255,100) end
    return "Other", Color3.fromRGB(255,255,255)
end
PH:Toggle({ Title = "Player ESP", Desc = "Highlight + name + distance", Callback = function(s)
    playerESPOn = s
    if not s then
        for _, v in pairs(playerHighlights) do pcall(function() v:Destroy() end) end; table.clear(playerHighlights)
        for _, v in pairs(playerLabels) do pcall(function() v.Parent:Destroy() end) end; table.clear(playerLabels)
    end
end})
PH:Space()

-- Drawing ESP
local DE = T:Section({ Title = "Drawing ESP" })
local ESPObjs = {}; local ESPOn = false
DE:Toggle({ Title = "ESP Box", Callback = function(s)
    ESPOn = s
    if s then
        for _, p in pairs(YH.Players:GetPlayers()) do if p~=YH.LocalPlayer then
            local box=Drawing.new("Square"); box.Thickness=2; box.Color=Color3.fromRGB(255,50,50); box.Filled=false; box.Visible=false
            local nl=Drawing.new("Text"); nl.Center=true; nl.Size=14; nl.Outline=true; nl.Color=Color3.fromRGB(255,255,255); nl.Visible=false
            ESPObjs[p]={Box=box,Name=nl}
        end end
        YH.RunService.RenderStepped:Connect(function()
            if not ESPOn then return end
            for plr,o in pairs(ESPObjs) do
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local root=plr.Character.HumanoidRootPart; local pos,on=YH.Camera:WorldToViewportPoint(root.Position)
                    if on then local sz=Vector2.new(2000/pos.Z,3000/pos.Z); o.Box.Size=sz; o.Box.Position=Vector2.new(pos.X-sz.X/2,pos.Y-sz.Y/2); o.Box.Visible=true; o.Name.Position=Vector2.new(pos.X,pos.Y-sz.Y/2-16); o.Name.Text=plr.Name; o.Name.Visible=true
                    else o.Box.Visible=false; o.Name.Visible=false end
                else o.Box.Visible=false; o.Name.Visible=false end end end)
    else for _,o in pairs(ESPObjs) do o.Box.Visible=false; o.Name.Visible=false end end
end})
DE:Space()

-- ESP Line
local espLineOn = false; local espLineColor = Color3.fromRGB(0,255,100); local espLineMode = "Single"; local espLineOrigin = "Character"; local espLineObjs = {}
local function UpdateLines()
    if not espLineOn then for _,o in pairs(espLineObjs) do o.Visible=false end; return end
    local mp = nil; local msp = nil
    if YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        mp = YH.LocalPlayer.Character.HumanoidRootPart.Position; msp, _ = YH.Camera:WorldToViewportPoint(mp)
    end
    local ori; if espLineOrigin == "Top Screen" then ori = Vector2.new(YH.Camera.ViewportSize.X/2,0)
    elseif msp then ori = Vector2.new(msp.X,msp.Y) else return end
    local targets = {}
    if espLineMode == "Single" then
        local t = _G.YH.projTarget or (function() local c; local cd=360; for _,p in pairs(YH.Players:GetPlayers()) do if p~=YH.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health>0 then local pos,on=YH.Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position); if on then local d=(Vector2.new(pos.X,pos.Y)-Vector2.new(YH.Mouse.X,YH.Mouse.Y)).Magnitude; if d<cd then cd=d;t=p end end end end; return t end)()
        if t then table.insert(targets,t) end
    else for _,p in pairs(YH.Players:GetPlayers()) do if p~=YH.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health>0 then table.insert(targets,p) end end end
    for i=#targets+1,#espLineObjs do espLineObjs[i].Visible=false end
    for i,t in ipairs(targets) do
        if not espLineObjs[i] then espLineObjs[i]=Drawing.new("Line"); espLineObjs[i].Thickness=2; espLineObjs[i].Color=espLineColor; espLineObjs[i].Transparency=0.6 end
        local tp; if t.Character and t.Character:FindFirstChild("HumanoidRootPart") then tp=t.Character.HumanoidRootPart.Position end
        if tp then local to,_=YH.Camera:WorldToViewportPoint(tp); espLineObjs[i].From=ori; espLineObjs[i].To=Vector2.new(to.X,to.Y); espLineObjs[i].Visible=true; espLineObjs[i].Color=espLineColor else espLineObjs[i].Visible=false end
    end
end
DE:Toggle({ Title = "ESP Line", Callback = function(s) espLineOn = s; if not s then for _,o in pairs(espLineObjs) do o.Visible=false end end end })
DE:Space()
DE:Colorpicker({ Title = "Line Color", Default = espLineColor, Callback = function(c) espLineColor = c end })
DE:Space()
DE:Dropdown({ Title = "Line Mode", Values = {"Single","All Players"}, Value = 1, Callback = function(s) espLineMode = (s=="All Players") and "All" or "Single" end })
DE:Space()
DE:Dropdown({ Title = "Line Origin", Values = {"Character","Top Screen"}, Value = 1, Callback = function(s) espLineOrigin = s end })
DE:Space()

-- Object ESP
local OE = T:Section({ Title = "Object ESP" })
local genH={}; local genL={}; local genOn=false
local hookH={}; local hookL={}; local hookOn=false
local palH={}; local palOn=false
local gateH={}; local gateL={}; local gateOn=false
local winL={}; local winOn=false

OE:Toggle({ Title = "Generator ESP", Callback = function(s) genOn=s; if not s then for _,v in pairs(genH) do pcall(function() v:Destroy() end) end; table.clear(genH); for _,v in pairs(genL) do pcall(function() v.Parent:Destroy() end) end; table.clear(genL) end end })
OE:Space()
OE:Toggle({ Title = "Hook ESP", Callback = function(s) hookOn=s; if not s then for _,v in pairs(hookH) do pcall(function() v:Destroy() end) end; table.clear(hookH); for _,v in pairs(hookL) do pcall(function() v.Parent:Destroy() end) end; table.clear(hookL) end end })
OE:Space()
OE:Toggle({ Title = "Pallet ESP", Callback = function(s) palOn=s; if not s then for _,v in pairs(palH) do pcall(function() v:Destroy() end) end; table.clear(palH) end end })
OE:Space()
OE:Toggle({ Title = "Gate ESP", Callback = function(s) gateOn=s; if not s then for _,v in pairs(gateH) do pcall(function() v:Destroy() end) end; table.clear(gateH); for _,v in pairs(gateL) do pcall(function() v.Parent:Destroy() end) end; table.clear(gateL) end end })
OE:Space()
OE:Toggle({ Title = "Window ESP", Callback = function(s) winOn=s; if not s then for _,v in pairs(winL) do pcall(function() v.Parent:Destroy() end) end; table.clear(winL) end end })

-- ESP update loop
YH.RunService.RenderStepped:Connect(function()
    -- Update lines
    if espLineOn then UpdateLines() end

    -- Player ESP (Highlight)
    if playerESPOn then
        for _, plr in pairs(YH.Players:GetPlayers()) do
            if plr == YH.LocalPlayer then continue end
            local char = plr.Character; if not char then continue end
            local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"); if not head then continue end
            local tt, bc = GetTeamInfo(plr); local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid")
            local hooked = char:GetAttribute("IsHooked") or char:GetAttribute("Hooked")
            local knocked = hum and hum.Health < hum.MaxHealth * 0.3
            local color = bc
            if tt == "Survivor" then
                if hooked then color = Color3.fromRGB(255,110,80)
                elseif knocked then color = Color3.fromRGB(255,170,80)
                elseif hum and hum.Health < hum.MaxHealth then color = Color3.fromRGB(255,255,120)
                else color = Color3.fromRGB(100,255,100) end
            end
            if not playerHighlights[plr] then
                local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.OutlineColor = Color3.new(1,1,1); hl.FillTransparency = 0.5; hl.Parent = YH.Camera
                playerHighlights[plr] = hl
            end
            local hl = playerHighlights[plr]; hl.Adornee = char; hl.FillColor = color; hl.FillTransparency = 0.3; hl.OutlineTransparency = 0
            if not playerLabels[plr] or not playerLabels[plr].Parent then
                local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0,200,0,50); bill.StudsOffset = Vector3.new(0,3,0); bill.AlwaysOnTop = true
                local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.3; txt.TextStrokeColor3 = Color3.new(0,0,0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.Parent = bill; bill.Parent = YH.Camera
                playerLabels[plr] = txt
            end
            local txt = playerLabels[plr]; txt.Parent.Adornee = head
            local dist = 0
            if YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                dist = math.floor((head.Position - YH.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
            end
            local line3 = tostring(dist) .. "m"; local line2 = ""
            if tt == "Killer" then
                local sk = plr:GetAttribute("SelectedKiller") or plr:GetAttribute("KillerName")
                line2 = sk and "KILLER: "..tostring(sk) or "KILLER"
            elseif tt == "Survivor" then
                if hooked then line2 = "HOOKED"; elseif knocked then line2 = "HURT" end
            end
            txt.Text = plr.Name .. " | " .. line3 .. (line2 ~= "" and (" | " .. line2) or "")
            txt.TextColor3 = color
        end
    end

    -- Generator ESP
    if genOn then
        for _, obj in pairs(YH.Map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:lower():find("generator") then
                local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"); if not att then continue end
                if not genH[obj] then
                    local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.FillColor = Color3.new(1,1,1); hl.OutlineColor = Color3.new(1,1,1); hl.Parent = YH.Camera; genH[obj] = hl
                    local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0,150,0,30); bill.StudsOffset = Vector3.new(0,2.5,0); bill.AlwaysOnTop = true
                    local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0,0,0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.TextColor3 = Color3.fromRGB(200,200,255); txt.Text = "Generator"; txt.Parent = bill; bill.Parent = YH.Camera; genL[obj] = txt
                end
                local hl = genH[obj]; hl.Adornee = obj; genL[obj].Parent.Adornee = att
            end
        end
    end
    -- Hook ESP
    if hookOn then
        for _, obj in pairs(YH.Map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:lower():find("hook") then
                local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"); if not att then continue end
                if not hookH[obj] then
                    local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.6; hl.FillColor = Color3.fromRGB(255,80,80); hl.OutlineColor = Color3.fromRGB(255,0,0); hl.Parent = YH.Camera; hookH[obj] = hl
                    local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0,100,0,30); bill.StudsOffset = Vector3.new(0,2,0); bill.AlwaysOnTop = true
                    local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0,0,0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.TextColor3 = Color3.fromRGB(255,100,100); txt.Text = "Hook"; txt.Parent = bill; bill.Parent = YH.Camera; hookL[obj] = txt
                end
                hookH[obj].Adornee = obj
            end
        end
    end
    -- Pallet ESP
    if palOn then
        for _, obj in pairs(YH.Map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:lower():find("pallet") then
                local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"); if not att then continue end
                if not palH[obj] then
                    local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.FillColor = Color3.fromRGB(255,255,100); hl.OutlineColor = Color3.fromRGB(255,200,0); hl.Parent = YH.Camera; palH[obj] = hl
                end
                palH[obj].Adornee = obj
            end
        end
    end
    -- Gate ESP
    if gateOn then
        for _, obj in pairs(YH.Map:GetDescendants()) do
            local ln = obj.Name:lower()
            if obj:IsA("Model") and (ln:find("gate") or ln:find("exit")) then
                local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"); if not att then continue end
                if not gateH[obj] then
                    local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.FillColor = Color3.fromRGB(160,0,255); hl.OutlineColor = Color3.fromRGB(200,120,255); hl.Parent = YH.Camera; gateH[obj] = hl
                    local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0,100,0,30); bill.StudsOffset = Vector3.new(0,2,0); bill.AlwaysOnTop = true
                    local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0,0,0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.TextColor3 = Color3.fromRGB(200,150,255); txt.Text = "Gate"; txt.Parent = bill; bill.Parent = YH.Camera; gateL[obj] = txt
                end
                gateH[obj].Adornee = att
            end
        end
    end
    -- Window ESP
    if winOn then
        for _, obj in pairs(YH.Map:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name:lower():find("window") then
                if not winL[obj] then
                    local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0,80,0,25); bill.StudsOffset = Vector3.new(0,1.5,0); bill.AlwaysOnTop = true
                    local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 12; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0,0,0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.TextColor3 = Color3.fromRGB(180,230,255); txt.Text = "Window"; txt.Parent = bill; bill.Parent = YH.Camera; winL[obj] = txt
                end
                winL[obj].Parent.Adornee = obj
            end
        end
    end
end)

-- Aimbot Tab
local YH = _G.YH
local T = YH.Tabs.Aimbot

-- Basic Aimbot
local BA = T:Section({ Title = "Basic Aimbot" })
YH.aimOn = false; YH.aimSmooth = 1; YH.aimFOV = 90
BA:Toggle({ Title = "Basic Aimbot", Callback = function(s) YH.aimOn = s end })
BA:Space()
BA:Slider({ Title = "Smoothness", Width = 200, Value = { Min=1, Max=10, Default=1 }, Step = 1, Callback = function(v) YH.aimSmooth = v end })
BA:Space()
BA:Slider({ Title = "FOV", Width = 200, Value = { Min=10, Max=360, Default=90 }, Step = 1, Callback = function(v) YH.aimFOV = v end })

-- Projectile Aimbot
local PA = T:Section({ Title = "Projectile Aimbot" })
YH.projOn = false; YH.projV = 150; YH.projG = 196.2; YH.projTarget = nil; YH.projLead = true; YH.projLeadFac = 1
local prevPos = {}; local tVel = {}
local function GetTargetPos(t) if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then return t.Character.HumanoidRootPart.Position end; return nil end
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
    if YH.projLead then
        local est = (trg-orig).Magnitude / (vel*0.707)
        if est>0 then local pred = GetTargetPos(YH.projTarget) + GetTargetVel(YH.projTarget) * est * YH.projLeadFac; if pred then aimT = pred end end
    end
    local ang = CalcAngle(orig, aimT, vel, grav); if not ang then return nil end
    local dx=aimT.X-orig.X; local dz=aimT.Z-orig.Z; local d=math.sqrt(dx*dx+dz*dz); local ho=math.tan(ang)*d
    return aimT + Vector3.new(0, ho, 0)
end

PA:Toggle({ Title = "Projectile Aimbot", Desc = "For arcing weapons", Callback = function(s) YH.projOn = s end })
PA:Space()
PA:Slider({ Title = "Projectile Velocity", Width = 200, Value = { Min=30, Max=500, Default=150 }, Step = 5, Callback = function(v) YH.projV = v end })
PA:Space()
PA:Slider({ Title = "Gravity", Width = 200, Value = { Min=50, Max=500, Default=196.2 }, Step = 1, Callback = function(v) YH.projG = v end })
PA:Space()
PA:Toggle({ Title = "Lead Prediction", Callback = function(s) YH.projLead = s end })
PA:Space()
PA:Slider({ Title = "Lead Factor", Width = 200, Value = { Min=0.5, Max=3, Default=1 }, Step = 0.1, Callback = function(v) YH.projLeadFac = v end })
PA:Space()
PA:Button({ Title = "Lock Target", Color = YH.C.Blue, Callback = function()
    local closest; local cd = 360
    for _, p in pairs(YH.Players:GetPlayers()) do
        if p ~= YH.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local pos, on = YH.Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if on then local d = (Vector2.new(pos.X,pos.Y)-Vector2.new(YH.Mouse.X,YH.Mouse.Y)).Magnitude; if d < cd then cd = d; closest = p end end
        end
    end
    YH.projTarget = closest
end })
PA:Space()
PA:Button({ Title = "Unlock Target", Color = YH.C.Red, Callback = function() YH.projTarget = nil end })

-- Projectile aimbot loop
YH.RunService.RenderStepped:Connect(function()
    if YH.projOn then
        if not YH.LocalPlayer.Character or not YH.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local target = YH.projTarget or (function()
            local c; local cd = 360
            for _, p in pairs(YH.Players:GetPlayers()) do
                if p ~= YH.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    local pos, on = YH.Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                    if on then local d = (Vector2.new(pos.X,pos.Y)-Vector2.new(YH.Mouse.X,YH.Mouse.Y)).Magnitude; if d < cd then cd = d; c = p end end
                end
            end; return c
        end)()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
            local origin = YH.LocalPlayer.Character.HumanoidRootPart.Position
            local tPos = target.Character.HumanoidRootPart.Position
            local aim = GetAimPoint(origin, tPos, YH.projV, YH.projG)
            if aim then
                local pos, on = YH.Camera:WorldToViewportPoint(aim)
                if on then
                    local t = Vector2.new(pos.X,pos.Y); local cur = Vector2.new(YH.Mouse.X,YH.Mouse.Y)
                    local s = t:Lerp(cur, 1/(YH.aimSmooth or 1)); mousemoverel(s.X-cur.X, s.Y-cur.Y)
                end
            end
        end
    end
end)

-- Visuals Tab
local YH = _G.YH
local T = YH.Tabs.Visuals

-- Bright Mode
local BS = T:Section({ Title = "Bright Mode" })
local brightOn = false; local brightLevel = 1
BS:Toggle({ Title = "Bright Mode", Desc = "Auto-reapplies on map change", Callback = function(s) brightOn = s end })
BS:Space()
BS:Slider({ Title = "Brightness Level", Width = 200, Value = { Min=0.5, Max=5, Default=1 }, Step = 0.1, Callback = function(v) brightLevel = v end })
BS:Space()

-- Custom FOV
local FS = T:Section({ Title = "Custom FOV" })
local fovOn = false; local fovVal = 70; local origFOV = YH.Camera.FieldOfView
FS:Toggle({ Title = "Custom FOV", Callback = function(s) fovOn = s; YH.Camera.FieldOfView = s and fovVal or origFOV end })
FS:Space()
FS:Slider({ Title = "FOV Value", Width = 200, Value = { Min=30, Max=120, Default=70 }, Step = 1, Callback = function(v) fovVal = v; if fovOn then YH.Camera.FieldOfView = v end end })
FS:Space()

-- Custom Fog
local FG = T:Section({ Title = "Custom Fog" })
local fogOn = false; local fogS = 0; local fogE = 1000
FG:Toggle({ Title = "Custom Fog", Callback = function(s) fogOn = s end })
FG:Space()
FG:Slider({ Title = "Fog Start", Width = 200, Value = { Min=0, Max=500, Default=0 }, Step = 1, Callback = function(v) fogS = v end })
FG:Space()
FG:Slider({ Title = "Fog End", Width = 200, Value = { Min=100, Max=2000, Default=1000 }, Step = 10, Callback = function(v) fogE = v end })
FG:Space()

-- Skybox
local SK = T:Section({ Title = "Skybox" })
local skyOn = false; local skyB = 50; local skyE = 50
SK:Toggle({ Title = "Skybox", Callback = function(s) skyOn = s end })
SK:Space()
SK:Slider({ Title = "Brightness", Width = 200, Value = { Min=0, Max=100, Default=50 }, Step = 1, Callback = function(v) skyB = v end })
SK:Space()
SK:Slider({ Title = "Exposure", Width = 200, Value = { Min=0, Max=100, Default=50 }, Step = 1, Callback = function(v) skyE = v end })

-- Visuals loop
YH.RunService.RenderStepped:Connect(function()
    if brightOn then
        local b = brightLevel * 2
        YH.Lighting.Ambient = Color3.fromRGB(255,255,255); YH.Lighting.Brightness = b; YH.Lighting.ClockTime = 12
        YH.Lighting.FogEnd = 100000; YH.Lighting.GlobalShadows = false; YH.Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        YH.Lighting.ColorShift_Top = Color3.fromRGB(255,255,255); YH.Lighting.ColorShift_Bottom = Color3.fromRGB(255,255,255)
    end
    if fogOn then YH.Lighting.FogStart = fogS; YH.Lighting.FogEnd = fogE end
    if skyOn then YH.Lighting.Brightness = skyB / 10; YH.Lighting.ExposureCompensation = skyE / 10 end
end)

-- Misc Tab
local YH = _G.YH
local T = YH.Tabs.Misc

local MS = T:Section({ Title = "Movement" })
local spdOn = false; local spdVal = 32
MS:Toggle({ Title = "Speedhack", Callback = function(s) spdOn = s end })
MS:Space()
MS:Slider({ Title = "Speed Value", Width = 200, Value = { Min=16, Max=100, Default=32 }, Step = 1, Callback = function(v) spdVal = v end })
MS:Space()

local sprintOn = false; local sprintBoost = 1.05; local sprinting = false
MS:Toggle({ Title = "Sprint Speed", Desc = "5% faster while sprinting", Callback = function(s) sprintOn = s end })
MS:Space()

local noclipOn = false
MS:Toggle({ Title = "Noclip", Desc = "Walk through walls", Callback = function(s) noclipOn = s end })
MS:Space()

-- Crosshair
local US = T:Section({ Title = "Utilities" })
local chOn = false; local chLen = 10; local chW = 2
US:Toggle({ Title = "Custom Crosshair", Callback = function(s) chOn = s end })
US:Space()
US:Slider({ Title = "Crosshair Length", Width = 200, Value = { Min=5, Max=30, Default=10 }, Step = 1, Callback = function(v) chLen = v end })
US:Space()
US:Slider({ Title = "Crosshair Width", Width = 200, Value = { Min=1, Max=8, Default=2 }, Step = 1, Callback = function(v) chW = v end })
US:Space()

-- Flashlight
local flOn = false; local flObj = nil
US:Toggle({ Title = "Flashlight", Callback = function(s) flOn = s end })
US:Space()

-- Stretched Res
local stOn = false; local stVal = 100
US:Toggle({ Title = "Stretched Res", Callback = function(s) stOn = s end })
US:Space()
US:Slider({ Title = "Stretch Value", Width = 200, Value = { Min=50, Max=200, Default=100 }, Step = 1, Callback = function(v) stVal = v end })
US:Space()

-- Actions
US:Button({ Title = "Reset Character", Callback = function()
    if YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then YH.LocalPlayer.Character.Humanoid.Health = 0 end
end})
US:Space()
US:Button({ Title = "Anti AFK", Callback = function()
    YH.LocalPlayer.Idled:Connect(function() YH.VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1); task.wait(0.1); YH.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1) end)
end})
US:Space()
US:Slider({ Title = "FPS Cap", Width = 200, Value = { Min=15, Max=360, Default=60 }, Step = 1, Callback = function(v) setfpscap(v) end})
US:Space()
US:Button({ Title = "Infinite Yield", Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end})

-- Misc loop
YH.RunService.RenderStepped:Connect(function()
    if spdOn and YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then
        YH.LocalPlayer.Character.Humanoid.WalkSpeed = spdVal
    end
    if noclipOn and YH.LocalPlayer.Character then
        for _, part in pairs(YH.LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
    if sprintOn and YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then
        sprinting = YH.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or YH.UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        YH.LocalPlayer.Character.Humanoid.WalkSpeed = sprinting and 16 * sprintBoost or 16
    end
    if flOn then
        if not flObj then flObj = Instance.new("SpotLight"); flObj.Brightness = 2; flObj.Range = 60; flObj.Angle = 90; flObj.Face = Enum.NormalId.Front; flObj.Parent = YH.Camera end
        flObj.Enabled = true
    elseif flObj then flObj.Enabled = false end
end)

-- HUD Tab
local YH = _G.YH
local T = YH.Tabs.HUD
local S = T:Section({ Title = "Essential HUD" })
local hudOn = false; local hudFPS = true; local hudPing = true; local hudKiller = true
local hudFrames = 0; local hudTime = 0; local hudFpsVal = 0; local hudGui = nil
S:Toggle({ Title = "Enable HUD", Desc = "FPS, Ping, Killer info", Callback = function(s) hudOn = s end })
S:Space()
S:Toggle({ Title = "Show FPS", Default = true, Callback = function(s) hudFPS = s end })
S:Space()
S:Toggle({ Title = "Show Ping", Default = true, Callback = function(s) hudPing = s end })
S:Space()
S:Toggle({ Title = "Show Killer", Default = true, Callback = function(s) hudKiller = s end })

-- HUD loop
YH.RunService.RenderStepped:Connect(function()
    hudFrames = hudFrames + 1; hudTime = hudTime + 0.1
    if hudTime >= 1 then hudFpsVal = math.floor(hudFrames / hudTime); hudFrames = 0; hudTime = 0 end
    if hudOn then
        -- Simple HUD text
    end
end)

-- Credits Tab
local YH = _G.YH
local T = YH.Tabs.Credits
local S = T:Section({ Title = "Info" })
S:Button({ Title = "Yuki Hub v5.0", Desc = "Made for Tuan | WindUI | Modular", Callback = function() end })
S:Space()
S:Button({ Title = "Features:", Desc = "ESP, Aimbot, Visuals, Misc, HUD", Callback = function() end })
S:Space()
S:Button({ Title = "Merged from:", Desc = "Essential Script + Notties Script + Yuki Hub", Callback = function() end })