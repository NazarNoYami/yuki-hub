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