-- [[ FILE: _init.lua ]]
local P=game:GetService("Players")local RS=game:GetService("RunService")local UIS=game:GetService("UserInputService")local VIM=game:GetService("VirtualInputManager")local H=game:GetService("HttpService")local L=game:GetService("Lighting")local CG=game:GetService("CoreGui")local C=workspace.CurrentCamera local M=workspace:FindFirstChild("Map")or workspace local LP=P.LocalPlayer local MO=LP:GetMouse()for _,v in pairs(CG:GetChildren())do if v.Name=="YukiHub"or v.Name=="YukiHubHUD"then v:Destroy()end end
_G.YH={Players=P,LocalPlayer=LP,RunService=RS,UserInputService=UIS,VirtualInputManager=VIM,HttpService=H,Lighting=L,Camera=C,Map=M,Mouse=MO,origFOV=C.FieldOfView,C={Blue=Color3.fromRGB(0,120,255),Red=Color3.fromRGB(255,50,50)},origLighting={L.Ambient,L.Brightness,L.ClockTime,L.FogEnd,L.GlobalShadows,L.OutdoorAmbient,L.ColorShift_Top,L.ColorShift_Bottom,L.FogStart,L.ExposureCompensation},brightLevel=1,fovVal=70,fogS=0,fogE=1000,skyB=50,skyE=50,spdVal=32,sprintBoost=1.05,chLen=10,chW=2,stVal=100}
local W=(loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua")))()
_G.YH.Window=W:CreateWindow({Title="Yuki Hub v5.0",Folder="YukiHub",Icon="solar:home-2-bold-duotone",NewElements=true,HideSearchBar=false,Topbar={Height=44,ButtonsType="Default"}})
local function MT(t,i)return _G.YH.Window:Tab({Title=t,Icon=i,IconColor=Color3.fromHex("#83889E"),Border=true})end
_G.YH.Tabs={Main=MT("Main","solar:home-2-bold-duotone"),ESP=MT("ESP","solar:eye-bold-duotone"),Aimbot=MT("Aimbot","solar:target-bold-duotone"),Visuals=MT("Visuals","solar:palette-bold-duotone"),Misc=MT("Misc","solar:settings-bold-duotone"),HUD=MT("HUD","solar:chart-bold-duotone"),Credits=MT("Credits","solar:info-circle-bold-duotone")}

-- [[ FILE: main.lua ]]
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

-- [[ FILE: visuals.lua ]]
-- Visuals Tab
local YH = _G.YH
local T = YH.Tabs.Visuals

-- Bright Mode
local BS = T:Section({ Title = "Bright Mode" })
local brOrig = {}
BS:Toggle({ Title = "Bright Mode", Desc = "Auto-reapplies on map change", Callback = function(s)
    YH.brightOn = s
    if s then
        brOrig = {YH.Lighting.Ambient,YH.Lighting.Brightness,YH.Lighting.ClockTime,YH.Lighting.FogEnd,YH.Lighting.GlobalShadows,YH.Lighting.OutdoorAmbient,YH.Lighting.ColorShift_Top,YH.Lighting.ColorShift_Bottom}
    else
        YH.Lighting.Ambient=brOrig[1];YH.Lighting.Brightness=brOrig[2];YH.Lighting.ClockTime=brOrig[3];YH.Lighting.FogEnd=brOrig[4];YH.Lighting.GlobalShadows=brOrig[5];YH.Lighting.OutdoorAmbient=brOrig[6];YH.Lighting.ColorShift_Top=brOrig[7];YH.Lighting.ColorShift_Bottom=brOrig[8]
    end
end })
BS:Space()
BS:Slider({ Title = "Brightness Level", Width = 200, Value = { Min=0.5, Max=5, Default=1 }, Step = 0.1, Callback = function(v) YH.brightLevel = v end })
BS:Space()

-- Custom FOV
local FS = T:Section({ Title = "Custom FOV" })
FS:Toggle({ Title = "Custom FOV", Callback = function(s) YH.fovOn = s; YH.Camera.FieldOfView = s and YH.fovVal or YH.origFOV end })
FS:Space()
FS:Slider({ Title = "FOV Value", Width = 200, Value = { Min=30, Max=120, Default=70 }, Step = 1, Callback = function(v) YH.fovVal = v; if YH.fovOn then YH.Camera.FieldOfView = v end end })
FS:Space()

-- Custom Fog
local FG = T:Section({ Title = "Custom Fog" })
local fgOrig = {}
FG:Toggle({ Title = "Custom Fog", Callback = function(s)
    YH.fogOn = s
    if s then fgOrig = {YH.Lighting.FogStart,YH.Lighting.FogEnd} else YH.Lighting.FogStart=fgOrig[1];YH.Lighting.FogEnd=fgOrig[2] end
end })
FG:Space()
FG:Slider({ Title = "Fog Start", Width = 200, Value = { Min=0, Max=500, Default=0 }, Step = 1, Callback = function(v) YH.fogS = v end })
FG:Space()
FG:Slider({ Title = "Fog End", Width = 200, Value = { Min=100, Max=2000, Default=1000 }, Step = 10, Callback = function(v) YH.fogE = v end })
FG:Space()

-- Skybox
local SK = T:Section({ Title = "Skybox" })
local skOrig = {}
SK:Toggle({ Title = "Skybox", Callback = function(s)
    YH.skyOn = s
    if s then skOrig={YH.Lighting.Brightness,YH.Lighting.ExposureCompensation} else YH.Lighting.Brightness=skOrig[1];YH.Lighting.ExposureCompensation=skOrig[2] end
end })
SK:Space()
SK:Slider({ Title = "Brightness", Width = 200, Value = { Min=0, Max=100, Default=50 }, Step = 1, Callback = function(v) YH.skyB = v end })
SK:Space()
SK:Slider({ Title = "Exposure", Width = 200, Value = { Min=0, Max=100, Default=50 }, Step = 1, Callback = function(v) YH.skyE = v end })

-- Render loop
YH.RunService.RenderStepped:Connect(function()
    if YH.brightOn then
        YH.Lighting.Ambient=Color3.fromRGB(255,255,255);YH.Lighting.Brightness=(YH.brightLevel or 1)*2
        YH.Lighting.ClockTime=12;YH.Lighting.FogEnd=100000;YH.Lighting.GlobalShadows=false
        YH.Lighting.OutdoorAmbient=Color3.fromRGB(255,255,255);YH.Lighting.ColorShift_Top=Color3.fromRGB(255,255,255);YH.Lighting.ColorShift_Bottom=Color3.fromRGB(255,255,255)
    end
    if YH.fovOn then YH.Camera.FieldOfView=YH.fovVal or 70 end
    if YH.fogOn then YH.Lighting.FogStart=YH.fogS or 0;YH.Lighting.FogEnd=YH.fogE or 1000 end
    if YH.skyOn and not YH.brightOn then YH.Lighting.Brightness=(YH.skyB or 50)/10;YH.Lighting.ExposureCompensation=(YH.skyE or 50)/10 end
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
local ESPObjs = {}
local espBoxOn = false
DE:Toggle({ Title = "ESP Box", Callback = function(s)
    espBoxOn = s
    if s then
        for _, p in pairs(YH.Players:GetPlayers()) do
            if p ~= YH.LocalPlayer then
                local box = Drawing.new("Square")
                box.Thickness = 2
                box.Color = Color3.fromRGB(255, 50, 50)
                box.Filled = false
                box.Visible = false
                local nl = Drawing.new("Text")
                nl.Center = true
                nl.Size = 14
                nl.Outline = true
                nl.Color = Color3.fromRGB(255, 255, 255)
                nl.Visible = false
                ESPObjs[p] = { Box = box, Name = nl }
            end
        end
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
DE:Toggle({ Title = "Projectile Arc", Desc = "Trajectory prediction", Callback = function(s) YH.projArcOn = s; if not s and YH.projArcObj then YH.projArcObj.Visible = false end end })
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

local function ScanObjects()
    ClearTable(cachedGens)
    ClearTable(cachedHooks)
    ClearTable(cachedPallets)
    ClearTable(cachedGates)
    ClearTable(cachedWindows)

    for _, obj in pairs(YH.Map:GetDescendants()) do
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
end

-- Object ESP state
local genH = {}; local genL = {}; local genOn = false
local hookH = {}; local hookL = {}; local hookOn = false
local palH = {}; local palOn = false
local gateH = {}; local gateL = {}; local gateOn = false
local winL = {}; local winOn = false

OE:Toggle({ Title = "Generator ESP", Callback = function(s)
    genOn = s
    if not s then
        for _, v in pairs(genH) do pcall(function() v:Destroy() end) end; ClearTable(genH)
        for _, v in pairs(genL) do pcall(function() v.Parent:Destroy() end) end; ClearTable(genL)
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
            local pos, on = YH.Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
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
        local vel = (pos - pr) / 0.1
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
YH.RunService.RenderStepped:Connect(function(dt)
    -- Cache scan every 2 seconds
    cacheTimer = cacheTimer + dt
    if cacheTimer >= 2 then
        cacheTimer = 0
        ScanObjects()
    end

    -- ESP Box
    if espBoxOn then
        for plr, o in pairs(ESPObjs) do
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local root = plr.Character.HumanoidRootPart
                local pos, on = YH.Camera:WorldToViewportPoint(root.Position)
                if on then
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
            msp, _ = YH.Camera:WorldToViewportPoint(mp)
        end
        local ori
        if espLineOrigin == "Top Screen" then
            ori = Vector2.new(YH.Camera.ViewportSize.X / 2, 0)
        elseif msp then
            ori = Vector2.new(msp.X, msp.Y)
        else
            for _, o in pairs(espLineObjs) do o.Visible = false end; return
        end
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
        -- Hide extra lines
        for i = #targets + 1, #espLineObjs do espLineObjs[i].Visible = false end
        -- Update lines
        for i, t in ipairs(targets) do
            if not espLineObjs[i] then
                espLineObjs[i] = Drawing.new("Line")
                espLineObjs[i].Thickness = 2
                espLineObjs[i].Color = espLineColor
                espLineObjs[i].Transparency = 0.6
            end
            local tp = t.Character and t.Character:FindFirstChild("HumanoidRootPart") and t.Character.HumanoidRootPart.Position
            if tp then
                local to, _ = YH.Camera:WorldToViewportPoint(tp)
                espLineObjs[i].From = ori
                espLineObjs[i].To = Vector2.new(to.X, to.Y)
                espLineObjs[i].Visible = true
                espLineObjs[i].Color = espLineColor
            else
                espLineObjs[i].Visible = false
            end
        end
    end

    -- Projectile Arc
    if YH.projArcOn and YH.projTarget and YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local tp = GetTargetPos(YH.projTarget)
        if tp then
            local orig = YH.LocalPlayer.Character.HumanoidRootPart.Position
            local trg = tp; local vel = YH.projV; local grav = YH.projG
            if not YH.projArcObj then
                YH.projArcObj = Drawing.new("Line")
                YH.projArcObj.Thickness = 1
                YH.projArcObj.Color = Color3.fromRGB(255, 200, 50)
                YH.projArcObj.Transparency = 0.3
            end
            local ang = CalcAngle(orig, trg, vel, grav)
            if ang then
                local dx = trg.X - orig.X; local dz = trg.Z - orig.Z
                local dir = Vector2.new(dx, dz).Unit; local g = grav; local v = vel
                local vx = v * math.cos(ang); local vy = v * math.sin(ang)
                local pts = {}; local tt = (2 * vy) / g
                for t = 0, tt, 0.1 do
                    local x = vx * t; local y = vy * t - 0.5 * g * t * t
                    local pos = orig + Vector3.new(dir.X * x, y, dir.Y * x)
                    local sp, _ = YH.Camera:WorldToViewportPoint(pos)
                    table.insert(pts, Vector2.new(sp.X, sp.Y))
                end
                if #pts > 1 then
                    YH.projArcObj.Visible = true
                    YH.projArcObj.Points = pts
                else
                    YH.projArcObj.Visible = false
                end
            else
                YH.projArcObj.Visible = false
            end
        end
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
                hl.Parent = YH.Camera
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
                bill.Parent = YH.Camera
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
                hl.Parent = YH.Camera; genH[obj] = hl
                local bill = Instance.new("BillboardGui")
                bill.Size = UDim2.new(0, 170, 0, 38)
                bill.StudsOffset = Vector3.new(0, 4, 0)
                bill.AlwaysOnTop = true; bill.Parent = YH.Camera
                local txt = Instance.new("TextLabel")
                txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1
                txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14
                txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0, 0, 0)
                txt.TextXAlignment = Enum.TextXAlignment.Center
                txt.Parent = bill; genL[obj] = txt
            end
            genH[obj].Adornee = obj
            genL[obj].Parent.Adornee = att
            local txt = genL[obj]
            if full then
                txt.Text = "Generator\n100.0%"
                txt.TextColor3 = Color3.fromRGB(0, 255, 0)
                genH[obj].FillColor = Color3.fromRGB(0, 255, 0)
                genH[obj].OutlineColor = Color3.fromRGB(0, 255, 0)
            else
                local g = math.clamp(progress / 100, 0, 1)
                txt.TextColor3 = Color3.new(1 - g * 0.7, 1, 1 - g * 0.7)
                if repairing > 0 then
                    txt.Text = string.format("Generator\n%.1f%% [%d]", progress, repairing)
                else
                    txt.Text = string.format("Generator\n%.1f%%", progress)
                end
                genH[obj].FillColor = Color3.new(1, 1, 1)
                genH[obj].OutlineColor = Color3.new(1, 1, 1)
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
                hl.OutlineColor = Color3.fromRGB(255, 0, 0); hl.Parent = YH.Camera; hookH[obj] = hl
                local bill = Instance.new("BillboardGui")
                bill.Size = UDim2.new(0, 100, 0, 30); bill.StudsOffset = Vector3.new(0, 2, 0)
                bill.AlwaysOnTop = true; bill.Parent = YH.Camera
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
                hl.Parent = YH.Camera; palH[obj] = hl
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
                hl.Parent = YH.Camera; gateH[obj] = hl
                local bill = Instance.new("BillboardGui")
                bill.Size = UDim2.new(0, 100, 0, 30); bill.StudsOffset = Vector3.new(0, 2, 0)
                bill.AlwaysOnTop = true; bill.Parent = YH.Camera
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
                bill.AlwaysOnTop = true; bill.Parent = YH.Camera
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

-- [[ FILE: aimbot.lua ]]
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

-- [[ FILE: misc.lua ]]
-- Misc Tab
local YH = _G.YH
local T = YH.Tabs.Misc

local MS = T:Section({ Title = "Movement" })
MS:Toggle({ Title = "Speedhack", Callback = function(s) YH.spdOn = s end })
MS:Space()
MS:Slider({ Title = "Speed Value", Width = 200, Value = { Min=16, Max=100, Default=32 }, Step = 1, Callback = function(v) YH.spdVal = v end })
MS:Space()
MS:Toggle({ Title = "Sprint Speed", Desc = "Faster while holding Shift", Callback = function(s) YH.sprintOn = s end })
MS:Space()
MS:Slider({ Title = "Sprint Boost", Width = 200, Value = { Min=1.0, Max=2.0, Default=1.05 }, Step = 0.05, Callback = function(v) YH.sprintBoost = v end })
MS:Space()
MS:Toggle({ Title = "Noclip", Desc = "Walk through walls", Callback = function(s) YH.noclipOn = s end })
MS:Space()

-- Utilities
local US = T:Section({ Title = "Utilities" })

-- Crosshair
US:Toggle({ Title = "Custom Crosshair", Callback = function(s) YH.chOn = s end })
US:Space()
US:Slider({ Title = "Crosshair Length", Width = 200, Value = { Min=5, Max=30, Default=10 }, Step = 1, Callback = function(v) YH.chLen = v end })
US:Space()
US:Slider({ Title = "Crosshair Width", Width = 200, Value = { Min=1, Max=8, Default=2 }, Step = 1, Callback = function(v) YH.chW = v end })
US:Space()

-- Flashlight
US:Toggle({ Title = "Flashlight", Callback = function(s) YH.flOn = s end })
US:Space()

-- Stretched Res
US:Toggle({ Title = "Stretched Res", Desc = "Wider field of view", Callback = function(s) YH.stOn = s end })
US:Space()
US:Slider({ Title = "Stretch Amount", Width = 200, Value = { Min=50, Max=200, Default=100 }, Step = 5, Callback = function(v) YH.stVal = v end })
US:Space()

-- Actions
US:Button({ Title = "Reset Character", Callback = function()
    if YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then
        YH.LocalPlayer.Character.Humanoid.Health = 0
    end
end})
US:Space()
US:Button({ Title = "Anti AFK", Desc = "Prevent auto-kick", Callback = function()
    if YH.afkConnected then return end
    YH.afkConnected = true
    YH.LocalPlayer.Idled:Connect(function()
        YH.VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.1)
        YH.VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
end})
US:Space()
US:Slider({ Title = "FPS Cap", Width = 200, Value = { Min=15, Max=360, Default=60 }, Step = 1, Callback = function(v) setfpscap(v) end})
US:Space()
US:Button({ Title = "Infinite Yield", Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end})
US:Space()

-- Auto Skill Check
US:Toggle({ Title = "Auto Skill Check", Desc = "Auto-complete generator minigame", Callback = function(s) YH.asOn = s end })
US:Space()

-- Minigame Scanner
local scanLogs = {"=== Minigame Scanner ==="}
local scanRunning = false
local scanCon = nil
local scanLastRot = {}

US:Toggle({ Title = "Scanner", Desc = "Record rotating GUI elements", Callback = function(s)
    scanRunning = s
    if s then
        table.insert(scanLogs, "--- Started ---")
        if scanCon then scanCon:Disconnect() end
        scanCon = YH.RunService.Heartbeat:Connect(function()
            for _, gui in pairs({game:GetService("CoreGui"), YH.LocalPlayer:FindFirstChildOfClass("PlayerGui")}) do
                if not gui then continue end
                for _, sg in pairs(gui:GetChildren()) do
                    if not sg:IsA("ScreenGui") or not sg.Enabled then continue end
                    for _, v in pairs(sg:GetDescendants()) do
                        if not v:IsA("GuiObject") then continue end
                        local ok, rot = pcall(function() return v.Rotation end)
                        if not ok then continue end
                        local key = v:GetFullName()
                        local prev = scanLastRot[key]
                        if prev and prev ~= rot and math.abs(rot - prev) > 0.5 and math.abs(rot - prev) < 180 then
                            table.insert(scanLogs, "[ROT] " .. v.Name .. " rot=" .. string.format("%.1f", rot) .. " (" .. sg.Name .. ")")
                        end
                        scanLastRot[key] = rot
                    end
                end
            end
        end)
    else
        if scanCon then scanCon:Disconnect(); scanCon = nil end
        table.insert(scanLogs, "--- Stopped ---")
        local ok, err = pcall(function() writefile("yuki_scan_" .. tostring(math.floor(tick())) .. ".txt", table.concat(scanLogs, "\n")) end)
        if ok then warn("Scanner saved to file") else warn("writefile failed: " .. tostring(err)) end
    end
end })
US:Space()
US:Button({ Title = "Copy Scan Log", Callback = function()
    local ok, err = pcall(function() setclipboard(table.concat(scanLogs, "\n")) end)
    if ok then warn("Scan log copied!") else warn("setclipboard failed: " .. tostring(err)) end
end })

-- Auto Skill Check state
local asSG, asLine, asGoal, asState, asPrevRot = nil, nil, nil, 0, nil

-- Crosshair drawing
local chLines = {}
for i = 1, 4 do
    chLines[i] = Drawing.new("Line")
    chLines[i].Thickness = 2
    chLines[i].Color = Color3.fromRGB(0, 255, 100)
    chLines[i].Transparency = 0.8
    chLines[i].Visible = false
end

YH.RunService.RenderStepped:Connect(function()
    -- Speedhack
    if YH.spdOn and YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then
        YH.LocalPlayer.Character.Humanoid.WalkSpeed = YH.spdVal or 32
    end
    -- Sprint
    if YH.sprintOn and YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then
        local sh = YH.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or YH.UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        YH.LocalPlayer.Character.Humanoid.WalkSpeed = sh and (16 * (YH.sprintBoost or 1.05)) or 16
    end
    -- Noclip
    if YH.noclipOn and YH.LocalPlayer.Character then
        for _, p in pairs(YH.LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
    -- Auto Skill Check
    if YH.asOn then
        if not asSG or not asSG.Parent then
            if asSG then warn("[ASC] Minigame GUI hilang") end
            asSG = nil; asState = 0; asPrevRot = nil
            local plrGui = YH.LocalPlayer:FindFirstChildOfClass("PlayerGui")
            for _, gui in pairs({game:GetService("CoreGui"), plrGui}) do
                if not gui then continue end
                asSG = gui:FindFirstChild("SkillCheckPromptGui", false)
                if asSG then warn("[ASC] Minigame terdeteksi!") end
            end
        end
        if asSG and asSG.Enabled then
            if not asLine or not asLine.Parent then
                asLine = asSG:FindFirstChild("Line", true)
                if asLine then warn("[ASC] Jarum (Line) ditemukan") end
            end
            if not asGoal or not asGoal.Parent then
                asGoal = asSG:FindFirstChild("Goal", true)
                if asGoal then warn("[ASC] Target (Goal) ditemukan") end
            end
            if asLine and asGoal and asGoal.Rotation ~= 0 then
                local lRot = asLine.Rotation % 360
                local gRot = asGoal.Rotation
                local diff = math.min(math.abs(lRot - gRot), math.abs(lRot - gRot - 360), math.abs(lRot - gRot + 360))
                local inZone = diff < 30
                if not inZone and asPrevRot then
                    local function between(a, b, t) if a <= b then return t >= a and t <= b else return t >= a or t <= b end end
                    inZone = between(asPrevRot, lRot, gRot)
                end
                if inZone then
                    if asState == 0 then
                        asState = 1
                        warn("[ASC] CLICK! Line=" .. string.format("%.1f", lRot) .. " Goal=" .. string.format("%.1f", gRot))
                        local pf = asLine:FindFirstAncestorOfClass("Frame") or asLine.Parent
                        if pf:IsA("GuiObject") then
                            local pos = pf.AbsolutePosition + pf.AbsoluteSize / 2
                            YH.VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        end
                    elseif asState == 1 then
                        asState = 2
                        local pf = asLine:FindFirstAncestorOfClass("Frame") or asLine.Parent
                        if pf:IsA("GuiObject") then
                            local pos = pf.AbsolutePosition + pf.AbsoluteSize / 2
                            YH.VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                        end
                    end
                elseif diff > 40 then
                    if asState ~= 0 then warn("[ASC] Selesai, reset") end
                    asState = 0
                end
                asPrevRot = lRot
            else
                if asState ~= 0 then warn("[ASC] Minigame selesai") end
                asState = 0; asPrevRot = nil
            end
        end
    end
    -- Crosshair
    if YH.chOn then
        local cx = YH.Camera.ViewportSize.X / 2
        local cy = YH.Camera.ViewportSize.Y / 2
        local len = YH.chLen
        local w = YH.chW
        for i = 1, 4 do chLines[i].Visible = true; chLines[i].Thickness = w end
        chLines[1].From = Vector2.new(cx, cy - len); chLines[1].To = Vector2.new(cx, cy - 2)
        chLines[2].From = Vector2.new(cx, cy + 2); chLines[2].To = Vector2.new(cx, cy + len)
        chLines[3].From = Vector2.new(cx - len, cy); chLines[3].To = Vector2.new(cx - 2, cy)
        chLines[4].From = Vector2.new(cx + 2, cy); chLines[4].To = Vector2.new(cx + len, cy)
    else
        for i = 1, 4 do chLines[i].Visible = false end
    end
    -- Stretched Res
    if YH.stOn then
        YH.Camera.ViewportSize = Vector2.new(YH.Camera.ViewportSize.X * (YH.stVal / 100), YH.Camera.ViewportSize.Y)
    end
end)

-- Flashlight
YH.RunService.Heartbeat:Connect(function()
    if YH.flOn then
        if not YH.flObj then
            YH.flObj = Instance.new("SpotLight")
            YH.flObj.Brightness = 2; YH.flObj.Range = 60; YH.flObj.Angle = 90
            YH.flObj.Face = Enum.NormalId.Front; YH.flObj.Parent = YH.Camera
        end
        YH.flObj.Enabled = true
    elseif YH.flObj then
        YH.flObj.Enabled = false
    end
end)

-- [[ FILE: hud.lua ]]
-- HUD Tab
local YH = _G.YH
local T = YH.Tabs.HUD
local S = T:Section({ Title = "Essential HUD" })
local hudOn = false; local hudFPS = true; local hudPing = true; local hudKiller = true
local hudFrames = 0; local hudTime = 0; local hudFpsVal = 0; local hudGui = nil

local function MakeHUD()
    if hudGui and hudGui.sg and hudGui.sg.Parent then pcall(function() hudGui.sg:Destroy() end) end
    local sg = Instance.new("ScreenGui"); sg.Name = "YukiHubHUD"; sg.Parent = game:GetService("CoreGui")
    local f = Instance.new("Frame"); f.Size = UDim2.new(0,180,0,80); f.Position = UDim2.new(1,-190,0,10)
    f.BackgroundColor3 = Color3.fromRGB(15,15,25); f.BackgroundTransparency = 0.3; f.BorderSizePixel = 0; f.Parent = sg
    Instance.new("UICorner",f).CornerRadius = UDim.new(0,6)
    local st = Instance.new("UIStroke",f); st.Color = Color3.fromRGB(50,50,70); st.Thickness = 1
    local ly = Instance.new("UIListLayout",f); ly.Padding = UDim.new(0,2)
    local pd = Instance.new("UIPadding",f); pd.PaddingTop = UDim.new(0,6); pd.PaddingLeft = UDim.new(0,8); pd.PaddingBottom = UDim.new(0,6)
    local function Lb(c)
        local l = Instance.new("TextLabel",f); l.Size = UDim2.new(1,0,0,18); l.BackgroundTransparency = 1
        l.TextColor3 = c; l.Font = Enum.Font.SourceSansSemibold; l.TextSize = 15; l.TextXAlignment = Enum.TextXAlignment.Left
        return l
    end
    hudGui = {sg=sg,frame=f,fps=Lb(Color3.fromRGB(100,255,100)),ping=Lb(Color3.fromRGB(100,200,255)),killer=Lb(Color3.fromRGB(255,100,100))}
    hudGui.fps.Text = "FPS: 0"; hudGui.ping.Text = "Ping: 0ms"; hudGui.killer.Text = "Killer: --"
end

S:Toggle({ Title = "Enable HUD", Desc = "FPS, Ping, Killer info", Callback = function(s) hudOn = s; if not s and hudGui then pcall(function() hudGui.sg:Destroy() end); hudGui = nil end end })
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
        if not hudGui then MakeHUD() end
        local vc = 0
        if hudFPS then hudGui.fps.Text = "FPS: " .. tostring(hudFpsVal); hudGui.fps.Visible = true; vc = vc + 1 else hudGui.fps.Visible = false end
        if hudPing then local pn = math.floor(YH.LocalPlayer:GetNetworkPing() * 1000); hudGui.ping.Text = "Ping: " .. tostring(pn) .. "ms"; hudGui.ping.Visible = true; vc = vc + 1 else hudGui.ping.Visible = false end
        if hudKiller then
            local kn = "--"
            for _, plr in pairs(YH.Players:GetPlayers()) do
                if plr ~= YH.LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                    local tm = plr.Team
                    if tm and (tm.Name:lower():find("maniac") or tm.Name:lower():find("killer")) then kn = plr.Name; break end
                end
            end
            hudGui.killer.Text = "Killer: " .. kn; hudGui.killer.Visible = true; vc = vc + 1
        else hudGui.killer.Visible = false end
        hudGui.frame.Size = UDim2.new(0,180,0,8 + vc * 22)
    elseif hudGui then pcall(function() hudGui.sg:Destroy() end); hudGui = nil end
end)

-- [[ FILE: credits.lua ]]
-- Credits Tab
local YH = _G.YH
local T = YH.Tabs.Credits
local S = T:Section({ Title = "Info" })
S:Button({ Title = "Yuki Hub v5.0", Desc = "Made for Tuan | WindUI | Modular", Callback = function() end })
S:Space()
S:Button({ Title = "Features:", Desc = "ESP, Aimbot, Visuals, Misc, HUD", Callback = function() end })
S:Space()
S:Button({ Title = "Merged from:", Desc = "Essential Script + Notties Script + Yuki Hub", Callback = function() end })
