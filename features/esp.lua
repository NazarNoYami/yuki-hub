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
