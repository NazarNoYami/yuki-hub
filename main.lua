--[[
  Yuki Hub v5.0 - Native GUI
  Essential + Notties + Yuki Hub merged
  Zero dependencies
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
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
for _, v in pairs(CoreGui:GetChildren()) do if v.Name == "YukiHub" then v:Destroy() end end

-- Responsive sizing
local screenSize = Camera.ViewportSize
local guiW = math.clamp(screenSize.X * 0.55, 320, 580)
local guiH = math.clamp(screenSize.Y * 0.6, 280, 460)
local tabW = math.min(130, guiW * 0.25)
local fs = guiW > 500 and 13 or 11

-- Colors
local accent = Color3.fromRGB(0, 120, 255)
local bg1 = Color3.fromRGB(25, 25, 35); local bg2 = Color3.fromRGB(35, 35, 50)
local bg3 = Color3.fromRGB(20, 20, 30); local contentBg = Color3.fromRGB(30, 30, 42)
local textCol = Color3.fromRGB(200, 200, 220); local textBright = Color3.fromRGB(255, 255, 255)
local textMuted = Color3.fromRGB(150, 150, 180)
local elementBg = Color3.fromRGB(40, 40, 58); local borderCol = Color3.fromRGB(50, 50, 65)

-- GUI
local GUI = Instance.new("ScreenGui"); GUI.Name = "YukiHub"; GUI.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, guiW, 0, guiH); Main.Position = UDim2.new(0.5, -guiW/2, 0.5, -guiH/2)
Main.BackgroundColor3 = bg1; Main.BorderSizePixel = 0; Main.Active = true; Main.Draggable = true; Main.Parent = GUI
local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 8); Corner.Parent = Main

-- Shadow
local Shadow = Instance.new("Frame")
Shadow.Size = UDim2.new(1, 6, 1, 6); Shadow.Position = UDim2.new(0, -3, 0, -3)
Shadow.BackgroundColor3 = Color3.new(0,0,0); Shadow.BackgroundTransparency = 0.6; Shadow.BorderSizePixel = 0; Shadow.ZIndex = -1; Shadow.Parent = Main
local ShCorner = Instance.new("UICorner"); ShCorner.CornerRadius = UDim.new(0, 10); ShCorner.Parent = Shadow

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36); TitleBar.BackgroundColor3 = bg2; TitleBar.BorderSizePixel = 0; TitleBar.Parent = Main
local TCorner = Instance.new("UICorner"); TCorner.CornerRadius = UDim.new(0, 8); TCorner.Parent = TitleBar
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 4); TitleFix.Position = UDim2.new(0, 0, 1, -4); TitleFix.BackgroundColor3 = bg2; TitleFix.BorderSizePixel = 0; TitleFix.Parent = Main

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -80, 1, 0); TitleLbl.Position = UDim2.new(0, 12, 0, 0); TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "Yuki Hub v5.0"; TitleLbl.TextColor3 = textBright; TitleLbl.Font = Enum.Font.GothamBold; TitleLbl.TextSize = fs + 2; TitleLbl.TextXAlignment = Enum.TextXAlignment.Left; TitleLbl.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 24, 0, 24); MinBtn.Position = UDim2.new(1, -58, 0, 6); MinBtn.BackgroundColor3 = Color3.fromRGB(50,50,70)
MinBtn.Text = "_"; MinBtn.TextColor3 = textBright; MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 14; MinBtn.Parent = TitleBar
local MinBtnC = Instance.new("UICorner"); MinBtnC.CornerRadius = UDim.new(0, 5); MinBtnC.Parent = MinBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24); CloseBtn.Position = UDim2.new(1, -30, 0, 6); CloseBtn.BackgroundColor3 = Color3.fromRGB(50,50,70)
CloseBtn.Text = "X"; CloseBtn.TextColor3 = Color3.fromRGB(255,100,100); CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 13; CloseBtn.Parent = TitleBar
local CloseBtnC = Instance.new("UICorner"); CloseBtnC.CornerRadius = UDim.new(0, 5); CloseBtnC.Parent = CloseBtn

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Main:TweenSize(minimized and UDim2.new(0, guiW, 0, 36) or UDim2.new(0, guiW, 0, guiH), nil, nil, 0.2, true)
end)
CloseBtn.MouseButton1Click:Connect(function() GUI:Destroy() end)

-- Tab Bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0, tabW, 1, -36); TabBar.Position = UDim2.new(0, 0, 0, 36)
TabBar.BackgroundColor3 = bg3; TabBar.BorderSizePixel = 0; TabBar.Parent = Main

-- Content Area
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -tabW, 1, -36); Content.Position = UDim2.new(0, tabW, 0, 36)
Content.BackgroundColor3 = contentBg; Content.BorderSizePixel = 0; Content.Parent = Main
local ContentC = Instance.new("UICorner"); ContentC.CornerRadius = UDim.new(0, 8); ContentC.Parent = Content

-- Tab system
local tabs = {}; local currentTab = nil
local tabNames = {"Main","ESP","Aimbot","Visuals","Misc","HUD","Credits"}
local tabIcons = {"H","E","A","V","M","D","I"}

-- Tab content pages (ScrollingFrames)
local tabPages = {}

for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 32); btn.Position = UDim2.new(0, 4, 0, 4 + (i-1) * 36)
    btn.BackgroundColor3 = Color3.fromRGB(25,25,38); btn.Text = tabIcons[i] .. "  " .. name
    btn.TextColor3 = textMuted; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = fs
    btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = TabBar
    local btnC = Instance.new("UICorner"); btnC.CornerRadius = UDim.new(0, 5); btnC.Parent = btn

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -10, 1, -10); page.Position = UDim2.new(0, 5, 0, 5)
    page.BackgroundTransparency = 1; page.BorderSizePixel = 0; page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(80,80,120); page.CanvasSize = UDim2.new(0,0,0,0)
    page.Visible = false; page.Parent = Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; layout.Parent = page
    local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 6); pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8); pad.Parent = page
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
    end)

    table.insert(tabs, {btn = btn, page = page, name = name})
    tabPages[name] = page

    btn.MouseButton1Click:Connect(function()
        if currentTab then currentTab.btn.BackgroundColor3 = Color3.fromRGB(25,25,38); currentTab.btn.TextColor3 = textMuted; currentTab.page.Visible = false end
        currentTab = tabs[i]; currentTab.btn.BackgroundColor3 = Color3.fromRGB(45,45,70); currentTab.btn.TextColor3 = textBright; currentTab.page.Visible = true
    end)
end

-- Select first tab
tabs[1].btn.BackgroundColor3 = Color3.fromRGB(45,45,70); tabs[1].btn.TextColor3 = textBright; tabs[1].page.Visible = true; currentTab = tabs[1]

-- ============== UI BUILDERS ==============
local function SectionTitle(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 24); lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.TextColor3 = accent; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = fs; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = parent
end

local function AddButton(parent, text, desc, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, desc and 48 or 32); frame.BackgroundColor3 = elementBg; frame.BorderSizePixel = 0; frame.Parent = parent
    local fC = Instance.new("UICorner"); fC.CornerRadius = UDim.new(0, 5); fC.Parent = frame
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = text; btn.TextColor3 = textBright
    btn.Font = Enum.Font.GothamSemibold; btn.TextSize = fs; btn.Parent = frame
    if desc then
        btn.TextYAlignment = Enum.TextYAlignment.Top; btn.Position = UDim2.new(0,10,0,6); btn.Size = UDim2.new(1,-10,0,22)
        btn.TextXAlignment = Enum.TextXAlignment.Left
        local dl = Instance.new("TextLabel"); dl.Size = UDim2.new(1,-10,0,16); dl.Position = UDim2.new(0,10,0,26)
        dl.BackgroundTransparency = 1; dl.Text = desc; dl.TextColor3 = Color3.fromRGB(140,140,170); dl.Font = Enum.Font.Gotham; dl.TextSize = fs - 2; dl.TextXAlignment = Enum.TextXAlignment.Left; dl.Parent = frame
    end
    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function() frame.BackgroundColor3 = Color3.fromRGB(50,50,70) end)
    btn.MouseLeave:Connect(function() frame.BackgroundColor3 = elementBg end)
end

local function AddToggle(parent, text, desc, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, desc and 44 or 30); frame.BackgroundColor3 = elementBg; frame.BorderSizePixel = 0; frame.Parent = parent
    local fC = Instance.new("UICorner"); fC.CornerRadius = UDim.new(0, 5); fC.Parent = frame
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 0, 20); lbl.Position = UDim2.new(0,10,0,2); lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.TextColor3 = textBright; lbl.Font = Enum.Font.Gotham; lbl.TextSize = fs; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = frame
    if desc then
        lbl.Size = UDim2.new(1, -50, 0, 18)
        local dl = Instance.new("TextLabel"); dl.Size = UDim2.new(1,-50,0,16); dl.Position = UDim2.new(0,10,0,20)
        dl.BackgroundTransparency = 1; dl.Text = desc; dl.TextColor3 = Color3.fromRGB(140,140,170); dl.Font = Enum.Font.Gotham; dl.TextSize = fs - 2; dl.TextXAlignment = Enum.TextXAlignment.Left; dl.Parent = frame
    end
    local tgl = Instance.new("TextButton")
    tgl.Size = UDim2.new(0,38,0,20); tgl.Position = UDim2.new(1,-46,0,desc and 12 or 5); tgl.BackgroundColor3 = Color3.fromRGB(60,60,80); tgl.Text = ""; tgl.Parent = frame
    local tglC = Instance.new("UICorner"); tglC.CornerRadius = UDim.new(0,10); tglC.Parent = tgl
    local circ = Instance.new("Frame"); circ.Size = UDim2.new(0,14,0,14); circ.Position = UDim2.new(0,3,0,3); circ.BackgroundColor3 = textBright; circ.BorderSizePixel = 0; circ.Parent = tgl
    local circC = Instance.new("UICorner"); circC.CornerRadius = UDim.new(0,7); circC.Parent = circ
    local state = default
    if state then tgl.BackgroundColor3 = accent; circ.Position = UDim2.new(0,21,0,3) end
    tgl.MouseButton1Click:Connect(function()
        state = not state; tgl.BackgroundColor3 = state and accent or Color3.fromRGB(60,60,80)
        circ:TweenPosition(state and UDim2.new(0,21,0,3) or UDim2.new(0,3,0,3), nil, nil, 0.15, true)
        if callback then pcall(callback, state) end
    end)
    return {SetState = function(s) state=s; tgl.BackgroundColor3=s and accent or Color3.fromRGB(60,60,80); circ.Position=s and UDim2.new(0,21,0,3) or UDim2.new(0,3,0,3) end, GetState = function() return state end}
end

-- Slider
local activeSlider = nil
local function AddSlider(parent, text, default, min, max, callback)
    local sf = Instance.new("Frame")
    sf.Size = UDim2.new(1,0,0,44); sf.BackgroundColor3 = elementBg; sf.BorderSizePixel = 0; sf.Parent = parent
    local sfC = Instance.new("UICorner"); sfC.CornerRadius = UDim.new(0,5); sfC.Parent = sf
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-16,0,18); lbl.Position = UDim2.new(0,8,0,3); lbl.BackgroundTransparency = 1; lbl.Text = text .. ": " .. tostring(default)
    lbl.TextColor3 = textBright; lbl.Font = Enum.Font.Gotham; lbl.TextSize = fs; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = sf
    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(0,40,0,18); vl.Position = UDim2.new(1,-44,0,3); vl.BackgroundTransparency = 1; vl.Text = tostring(default)
    vl.TextColor3 = accent; vl.Font = Enum.Font.GothamBold; vl.TextSize = fs; vl.TextXAlignment = Enum.TextXAlignment.Right; vl.Parent = sf
    local sbg = Instance.new("Frame")
    sbg.Size = UDim2.new(1,-16,0,5); sbg.Position = UDim2.new(0,8,0,28); sbg.BackgroundColor3 = Color3.fromRGB(60,60,80); sbg.BorderSizePixel = 0; sbg.Parent = sf
    local sbgC = Instance.new("UICorner"); sbgC.CornerRadius = UDim.new(0,3); sbgC.Parent = sbg
    local sfill = Instance.new("Frame")
    local ratio = max > min and (default-min)/(max-min) or 0
    sfill.Size = UDim2.new(ratio,0,1,0); sfill.BackgroundColor3 = accent; sfill.BorderSizePixel = 0; sfill.Parent = sbg
    local sfillC = Instance.new("UICorner"); sfillC.CornerRadius = UDim.new(0,3); sfillC.Parent = sfill
    local val = default; local sd = {bg=sbg, fill=sfill, lbl=vl, min=min, max=max, text=text, cb=callback}
    sbg.MouseButton1Down:Connect(function()
        activeSlider = sd
        local pos = math.clamp((UserInputService:GetMouseLocation().X - sbg.AbsolutePosition.X) / sbg.AbsoluteSize.X, 0, 1)
        val = math.floor(min + (max-min) * pos); sfill.Size = UDim2.new(pos,0,1,0); vl.Text = tostring(val)
        if callback then pcall(callback, val) end
    end)
    return {SetValue = function(v) val=v; local r=max>min and (v-min)/(max-min) or 0; sfill.Size=UDim2.new(r,0,1,0); vl.Text=tostring(v) end}
end
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and activeSlider then
        local d = activeSlider; local pos = math.clamp((UserInputService:GetMouseLocation().X - d.bg.AbsolutePosition.X) / d.bg.AbsoluteSize.X, 0, 1)
        local v = math.floor(d.min + (d.max - d.min) * pos); d.fill.Size = UDim2.new(pos,0,1,0); d.lbl.Text = tostring(v)
        if d.cb then pcall(d.cb, v) end
    end
end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then activeSlider = nil end end)

-- Dropdown
local function AddDropdown(parent, text, values, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,32); frame.BackgroundColor3 = elementBg; frame.BorderSizePixel = 0; frame.Parent = parent
    local fC = Instance.new("UICorner"); fC.CornerRadius = UDim.new(0,5); fC.Parent = frame
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-50,1,0); lbl.Position = UDim2.new(0,10,0,0); lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.TextColor3 = textBright; lbl.Font = Enum.Font.Gotham; lbl.TextSize = fs; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = frame
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,40,0,22); btn.Position = UDim2.new(1,-46,0,5); btn.BackgroundColor3 = accent; btn.Text = values[default or 1] or values[1]
    btn.TextColor3 = textBright; btn.Font = Enum.Font.GothamBold; btn.TextSize = fs - 2; btn.Parent = frame
    local btnC = Instance.new("UICorner"); btnC.CornerRadius = UDim.new(0,5); btnC.Parent = btn
    local idx = default or 1
    btn.MouseButton1Click:Connect(function()
        idx = idx % #values + 1; btn.Text = values[idx]
        if callback then pcall(callback, values[idx]) end
    end)
end

-- Color Picker (simple)
local function AddColorPicker(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,32); frame.BackgroundColor3 = elementBg; frame.BorderSizePixel = 0; frame.Parent = parent
    local fC = Instance.new("UICorner"); fC.CornerRadius = UDim.new(0,5); fC.Parent = frame
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-44,1,0); lbl.Position = UDim2.new(0,10,0,0); lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.TextColor3 = textBright; lbl.Font = Enum.Font.Gotham; lbl.TextSize = fs; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = frame
    local colorBtn = Instance.new("Frame")
    colorBtn.Size = UDim2.new(0,34,0,22); colorBtn.Position = UDim2.new(1,-40,0,5); colorBtn.BackgroundColor3 = default; colorBtn.BorderSizePixel = 0; colorBtn.Parent = frame
    local cbC = Instance.new("UICorner"); cbC.CornerRadius = UDim.new(0,5); cbC.Parent = colorBtn
    local color = default; local colors = {Color3.fromRGB(255,50,50), Color3.fromRGB(0,255,100), Color3.fromRGB(0,174,255), Color3.fromRGB(255,200,50), Color3.fromRGB(255,100,255), Color3.fromRGB(255,255,255), Color3.fromRGB(100,255,100)}
    local ci = 1
    colorBtn.Parent.MouseButton1Click:Connect(function()
        ci = ci % #colors + 1; color = colors[ci]; colorBtn.BackgroundColor3 = color
        if callback then pcall(callback, color) end
    end)
end

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
local function GetTargetPos(t) if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then return t.Character.HumanoidRootPart.Position end; return nil end

-- ============== STATE ==============
local aimOn = false; local aimSmooth = 1; local aimFOV = 90
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

-- ESP state
local espBoxOn = false; local espLineOn = false; local espLineColor = Color3.fromRGB(0,255,100); local espLineMode = "Single"; local espLineOrigin = "Character"
local espLineObjs = {}; local ESPObjs = {}; local projArcObj = nil; local projArcOn = false
local brightOn = false; local brightLevel = 1
local spdOn = false; local spdVal = 32; local noclipOn = false; local sprintOn = false; local sprintBoost = 1.05; local sprinting = false
local flOn = false; local flObj = nil; local chOn = false; local fovOn = false; local fovVal = 70; local origFOV = Camera.FieldOfView
local fogOn = false; local fogS = 0; local fogE = 1000; local skyOn = false; local skyB = 50; local skyE = 50
local hudOn = false; local hudFPS = true; local hudPing = true; local hudKiller = true; local hudFrames = 0; local hudTime = 0; local hudFpsVal = 0

-- Player ESP (Highlight)
local playerESPOn = false; local playerHighlights = {}; local playerLabels = {}
local function GetTeamInfo(plr)
    local team = plr.Team; if not team then return "Other", Color3.fromRGB(255,255,255) end
    local tn = team.Name:lower()
    if tn:find("maniac") or tn:find("killer") then return "Killer", Color3.fromRGB(255,80,80) end
    if tn:find("survivor") then return "Survivor", Color3.fromRGB(100,255,100) end
    return "Other", Color3.fromRGB(255,255,255)
end
-- Object ESP state
local genOn = false; local genH = {}; local genL = {}
local hookOn = false; local hookH = {}; local hookL = {}
local palOn = false; local palH = {}
local gateOn = false; local gateH = {}; local gateL = {}
local winOn = false; local winL = {}

-- ============== MAIN TAB ==============
local p = tabPages["Main"]
SectionTitle(p, "Game Options")
AddButton(p, "Rejoin Server", nil, function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)
AddButton(p, "Server Hop", nil, function()
    local function gs(c) local u="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100"; if c then u=u.."&cursor="..c end; return HttpService:JSONDecode(game:HttpGet(u)) end
    local s=gs(); if s and s.data then for _,v in pairs(s.data) do if v.playing<v.maxPlayers and v.id~=game.JobId then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,v.id,LocalPlayer); return end end end
end)
SectionTitle(p, "Movement")
AddToggle(p, "Walkspeed", nil, false, function(s) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = s and 50 or 16 end end)
AddSlider(p, "Walkspeed", 50, 16, 250, function(v) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = v end end)
AddDropdown(p, "Jump Power", {"50","75","100","150","200"}, 1, function(s) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.JumpPower = tonumber(s) end end)

-- ============== ESP TAB ==============
p = tabPages["ESP"]
SectionTitle(p, "Player ESP")
AddToggle(p, "Player ESP (Highlight)", "Glow + name + distance + status", false, function(s) playerESPOn = s; if not s then for _,v in pairs(playerHighlights) do pcall(function() v:Destroy() end) end; table.clear(playerHighlights); for _,v in pairs(playerLabels) do pcall(function() v.Parent:Destroy() end) end; table.clear(playerLabels) end end)

SectionTitle(p, "Drawing ESP")
AddToggle(p, "ESP Box", "2D box around players", false, function(s)
    espBoxOn = s
    if s then
        for _, pl in pairs(Players:GetPlayers()) do if pl~=LocalPlayer then
            local box=Drawing.new("Square"); box.Thickness=2; box.Color=Color3.fromRGB(255,50,50); box.Filled=false; box.Visible=false
            local nl=Drawing.new("Text"); nl.Center=true; nl.Size=14; nl.Outline=true; nl.Color=Color3.fromRGB(255,255,255); nl.Visible=false
            ESPObjs[pl]={Box=box,Name=nl}
        end end
    else for _,o in pairs(ESPObjs) do o.Box.Visible=false; o.Name.Visible=false end end
end)
AddToggle(p, "ESP Line", "Line to players", false, function(s) espLineOn = s; if not s then for _,o in pairs(espLineObjs) do o.Visible=false end end end)
AddColorPicker(p, "Line Color", espLineColor, function(c) espLineColor = c end)
AddDropdown(p, "Line Mode", {"Single", "All Players"}, 1, function(s) espLineMode = (s == "All Players") and "All" or "Single" end)
AddDropdown(p, "Line Origin", {"Character", "Top Screen"}, 1, function(s) espLineOrigin = s end)
AddToggle(p, "Projectile Arc", "Trajectory prediction", false, function(s) projArcOn = s; if not s and projArcObj then projArcObj.Visible=false end end)

SectionTitle(p, "Object ESP")
AddToggle(p, "Generator ESP", "Highlight + label", false, function(s) genOn=s; if not s then for _,v in pairs(genH) do pcall(function() v:Destroy() end) end; table.clear(genH); for _,v in pairs(genL) do pcall(function() v.Parent:Destroy() end) end; table.clear(genL) end end)
AddToggle(p, "Hook ESP", "Highlight + label", false, function(s) hookOn=s; if not s then for _,v in pairs(hookH) do pcall(function() v:Destroy() end) end; table.clear(hookH); for _,v in pairs(hookL) do pcall(function() v.Parent:Destroy() end) end; table.clear(hookL) end end)
AddToggle(p, "Pallet ESP", "Highlight", false, function(s) palOn=s; if not s then for _,v in pairs(palH) do pcall(function() v:Destroy() end) end; table.clear(palH) end end)
AddToggle(p, "Gate ESP", "Highlight + label", false, function(s) gateOn=s; if not s then for _,v in pairs(gateH) do pcall(function() v:Destroy() end) end; table.clear(gateH); for _,v in pairs(gateL) do pcall(function() v.Parent:Destroy() end) end; table.clear(gateL) end end)
AddToggle(p, "Window ESP", "Label", false, function(s) winOn=s; if not s then for _,v in pairs(winL) do pcall(function() v.Parent:Destroy() end) end; table.clear(winL) end end)

-- ============== AIMBOT TAB ==============
p = tabPages["Aimbot"]
SectionTitle(p, "Basic Aimbot")
AddToggle(p, "Basic Aimbot", nil, false, function(s) aimOn = s end)
AddSlider(p, "Smoothness", 1, 1, 10, function(v) aimSmooth = v end)
AddSlider(p, "FOV", 90, 10, 360, function(v) aimFOV = v end)

SectionTitle(p, "Projectile Aimbot (Bows/Daggers)")
AddToggle(p, "Projectile Aimbot", "For arcing weapons", false, function(s) projOn = s end)
AddSlider(p, "Proj. Velocity", 150, 30, 500, function(v) projV = v end)
AddSlider(p, "Proj. Gravity", 196.2, 50, 500, function(v) projG = v end)
AddToggle(p, "Lead Prediction", "Predict moving targets", true, function(s) projLead = s end)
AddSlider(p, "Lead Factor", 1, 0.5, 3, function(v) projLeadFac = v end)
AddButton(p, "Lock Target", "Lock closest player", function() projTarget = GetClosestPlayer(360) end)
AddButton(p, "Unlock Target", nil, function() projTarget = nil end)

-- ============== VISUALS TAB ==============
p = tabPages["Visuals"]
SectionTitle(p, "Bright Mode")
AddToggle(p, "Bright Mode", "Auto-reapplies on map change", false, function(s) brightOn = s end)
AddSlider(p, "Brightness Level", 1, 0.5, 5, function(v) brightLevel = v end)

SectionTitle(p, "Custom FOV")
AddToggle(p, "Custom FOV", nil, false, function(s) fovOn = s; Camera.FieldOfView = s and fovVal or origFOV end)
AddSlider(p, "FOV Value", 70, 30, 120, function(v) fovVal = v; if fovOn then Camera.FieldOfView = v end end)

SectionTitle(p, "Custom Fog")
AddToggle(p, "Custom Fog", nil, false, function(s) fogOn = s end)
AddSlider(p, "Fog Start", 0, 0, 500, function(v) fogS = v end)
AddSlider(p, "Fog End", 1000, 100, 2000, function(v) fogE = v end)

SectionTitle(p, "Skybox")
AddToggle(p, "Skybox", nil, false, function(s) skyOn = s end)
AddSlider(p, "Brightness", 50, 0, 100, function(v) skyB = v end)
AddSlider(p, "Exposure", 50, 0, 100, function(v) skyE = v end)

-- ============== MISC TAB ==============
p = tabPages["Misc"]
SectionTitle(p, "Movement")
AddToggle(p, "Speedhack", "Walkspeed boost", false, function(s) spdOn = s end)
AddSlider(p, "Speed Value", 32, 16, 100, function(v) spdVal = v end)
AddToggle(p, "Sprint Speed", "5% faster while sprinting", false, function(s) sprintOn = s end)
AddToggle(p, "Noclip", "Walk through walls", false, function(s) noclipOn = s end)

SectionTitle(p, "Utilities")
AddToggle(p, "Flashlight", "Senter", false, function(s) flOn = s end)
AddToggle(p, "Custom Crosshair", nil, false, function(s) chOn = s end)
AddToggle(p, "Stretched Res", nil, false, function(s) end)
AddButton(p, "Reset Character", nil, function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.Health = 0 end end)
AddButton(p, "Anti AFK", nil, function() LocalPlayer.Idled:Connect(function() VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1); task.wait(0.1); VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1) end) end)
AddSlider(p, "FPS Cap", 60, 15, 360, function(v) setfpscap(v) end)
AddButton(p, "Infinite Yield", "Admin commands", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end)

-- ============== HUD TAB ==============
p = tabPages["HUD"]
SectionTitle(p, "Essential HUD")
AddToggle(p, "Enable HUD", "FPS, Ping, Killer info", false, function(s) hudOn = s end)
AddToggle(p, "Show FPS", nil, true, function(s) hudFPS = s end)
AddToggle(p, "Show Ping", nil, true, function(s) hudPing = s end)
AddToggle(p, "Show Killer", nil, true, function(s) hudKiller = s end)

-- ============== CREDITS TAB ==============
p = tabPages["Credits"]
SectionTitle(p, "Yuki Hub v5.0")
AddButton(p, "Made for Tuan", "WindUI | Native GUI | Merged", function() end)
AddButton(p, "Features:", "ESP, Aimbot, Visuals, Misc, HUD", function() end)
AddButton(p, "Sources:", "Essential Script + Notties Script", function() end)

-- ============== MAIN LOOP ==============
RunService.RenderStepped:Connect(function()
    -- Bright Mode
    if brightOn then
        local b = brightLevel * 2; Lighting.Ambient = Color3.fromRGB(255,255,255); Lighting.Brightness = b; Lighting.ClockTime = 12
        Lighting.FogEnd = 100000; Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        Lighting.ColorShift_Top = Color3.fromRGB(255,255,255); Lighting.ColorShift_Bottom = Color3.fromRGB(255,255,255)
    end

    -- ESP Box
    if espBoxOn then
        for plr,o in pairs(ESPObjs) do
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local root=plr.Character.HumanoidRootPart; local pos,on=Camera:WorldToViewportPoint(root.Position)
                if on then local sz=Vector2.new(2000/pos.Z,3000/pos.Z); o.Box.Size=sz; o.Box.Position=Vector2.new(pos.X-sz.X/2,pos.Y-sz.Y/2); o.Box.Visible=true; o.Name.Position=Vector2.new(pos.X,pos.Y-sz.Y/2-16); o.Name.Text=plr.Name; o.Name.Visible=true
                else o.Box.Visible=false; o.Name.Visible=false end
            else o.Box.Visible=false; o.Name.Visible=false end
        end
    end

    -- ESP Line
    if espLineOn then
        local mp = nil; local msp = nil
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then mp=LocalPlayer.Character.HumanoidRootPart.Position; msp,_=Camera:WorldToViewportPoint(mp) end
        local ori; if espLineOrigin=="Top Screen" then ori=Vector2.new(Camera.ViewportSize.X/2,0) elseif msp then ori=Vector2.new(msp.X,msp.Y) else for _,o in pairs(espLineObjs) do o.Visible=false end; return end
        local targets = {}
        if espLineMode=="Single" then local t=projTarget or GetClosestPlayer(360); if t then table.insert(targets,t) end
        else for _,pl in pairs(Players:GetPlayers()) do if pl~=LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and pl.Character:FindFirstChild("Humanoid") and pl.Character.Humanoid.Health>0 then table.insert(targets,pl) end end end
        for i=#targets+1,#espLineObjs do espLineObjs[i].Visible=false end
        for i,t in ipairs(targets) do
            if not espLineObjs[i] then espLineObjs[i]=Drawing.new("Line"); espLineObjs[i].Thickness=2; espLineObjs[i].Color=espLineColor; espLineObjs[i].Transparency=0.6 end
            local tp = t.Character and t.Character:FindFirstChild("HumanoidRootPart") and t.Character.HumanoidRootPart.Position
            if tp then local to,_=Camera:WorldToViewportPoint(tp); espLineObjs[i].From=ori; espLineObjs[i].To=Vector2.new(to.X,to.Y); espLineObjs[i].Visible=true; espLineObjs[i].Color=espLineColor else espLineObjs[i].Visible=false end
        end
    end

    -- Projectile Arc
    if projArcOn and projTarget and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local tp = GetTargetPos(projTarget)
        if tp then
            local orig=LocalPlayer.Character.HumanoidRootPart.Position; local trg=tp; local vel=projV; local grav=projG
            if not projArcObj then projArcObj=Drawing.new("Line"); projArcObj.Thickness=1; projArcObj.Color=Color3.fromRGB(255,200,50); projArcObj.Transparency=0.3 end
            local ang=CalcAngle(orig,trg,vel,grav)
            if ang then
                local dx=trg.X-orig.X; local dz=trg.Z-orig.Z; local dir=Vector2.new(dx,dz).Unit; local g=grav; local v=vel
                local vx=v*math.cos(ang); local vy=v*math.sin(ang); local pts={}; local tt=(2*vy)/g
                for t=0,tt,0.1 do local x=vx*t; local y=vy*t-0.5*g*t*t; local pos=orig+Vector3.new(dir.X*x,y,dir.Y*x); local sp,_=Camera:WorldToViewportPoint(pos); table.insert(pts,Vector2.new(sp.X,sp.Y)) end
                if #pts>1 then projArcObj.Visible=true; projArcObj.Points=pts else projArcObj.Visible=false end
            else projArcObj.Visible=false end
        end
    end

    -- Basic Aimbot
    if aimOn then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local c = GetClosestPlayer(aimFOV)
            if c and c.Character then
                local pos = Camera:WorldToViewportPoint(c.Character.HumanoidRootPart.Position)
                local t = Vector2.new(pos.X,pos.Y); local cur = Vector2.new(Mouse.X,Mouse.Y)
                local s = t:Lerp(cur, 1/aimSmooth); mousemoverel(s.X-cur.X, s.Y-cur.Y)
            end
        end
    end

    -- Projectile Aimbot
    if projOn then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local target = projTarget or GetClosestPlayer(360)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
                local origin = LocalPlayer.Character.HumanoidRootPart.Position; local tPos = target.Character.HumanoidRootPart.Position
                local aim = GetAimPoint(origin, tPos, projV, projG)
                if aim then local pos,on=Camera:WorldToViewportPoint(aim); if on then local t=Vector2.new(pos.X,pos.Y); local cur=Vector2.new(Mouse.X,Mouse.Y); local s=t:Lerp(cur,1/aimSmooth); mousemoverel(s.X-cur.X,s.Y-cur.Y) end end
            end
        end
    end

    -- Player ESP
    if playerESPOn then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end; local char = plr.Character; if not char then continue end; local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"); if not head then continue end
            local tt, bc = GetTeamInfo(plr); local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid")
            local hooked = char:GetAttribute("IsHooked") or char:GetAttribute("Hooked"); local knocked = hum and hum.Health < hum.MaxHealth * 0.3
            local color = bc
            if tt == "Survivor" then
                if hooked then color = Color3.fromRGB(255,110,80); elseif knocked then color = Color3.fromRGB(255,170,80); elseif hum and hum.Health < hum.MaxHealth then color = Color3.fromRGB(255,255,120); else color = Color3.fromRGB(100,255,100) end
            end
            if not playerHighlights[plr] then local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.OutlineColor = Color3.new(1,1,1); hl.FillTransparency = 0.5; hl.Parent = Camera; playerHighlights[plr] = hl end
            local hl = playerHighlights[plr]; hl.Adornee = char; hl.FillColor = color; hl.FillTransparency = 0.3; hl.OutlineTransparency = 0
            if not playerLabels[plr] or not playerLabels[plr].Parent then
                local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0,200,0,50); bill.StudsOffset = Vector3.new(0,3,0); bill.AlwaysOnTop = true
                local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.3; txt.TextStrokeColor3 = Color3.new(0,0,0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.Parent = bill; bill.Parent = Camera; playerLabels[plr] = txt
            end
            local txt = playerLabels[plr]; txt.Parent.Adornee = head
            local dist = 0; if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then dist = math.floor((head.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude) end
            local line3 = tostring(dist) .. "m"; local line2 = ""
            if tt == "Killer" then local sk = plr:GetAttribute("SelectedKiller") or plr:GetAttribute("KillerName"); line2 = sk and "KILLER: "..tostring(sk) or "KILLER"
            elseif tt == "Survivor" then if hooked then line2 = "HOOKED"; elseif knocked then line2 = "HURT" end end
            txt.Text = plr.Name .. " | " .. line3 .. (line2 ~= "" and (" | " .. line2) or ""); txt.TextColor3 = color
        end
    end

    -- Object ESP
    if genOn then for _,obj in pairs(Map:GetDescendants()) do if obj:IsA("Model") and obj.Name:lower():find("generator") then local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"); if not att then continue end; if not genH[obj] then local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.FillColor = Color3.new(1,1,1); hl.OutlineColor = Color3.new(1,1,1); hl.Parent = Camera; genH[obj] = hl; local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0,150,0,30); bill.StudsOffset = Vector3.new(0,2.5,0); bill.AlwaysOnTop = true; local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0,0,0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.TextColor3 = Color3.fromRGB(200,200,255); txt.Text = "Generator"; txt.Parent = bill; bill.Parent = Camera; genL[obj] = txt end; genH[obj].Adornee = obj; genL[obj].Parent.Adornee = att end end end
    if hookOn then for _,obj in pairs(Map:GetDescendants()) do if obj:IsA("Model") and obj.Name:lower():find("hook") then local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"); if not att then continue end; if not hookH[obj] then local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.6; hl.FillColor = Color3.fromRGB(255,80,80); hl.OutlineColor = Color3.fromRGB(255,0,0); hl.Parent = Camera; hookH[obj] = hl; local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0,100,0,30); bill.StudsOffset = Vector3.new(0,2,0); bill.AlwaysOnTop = true; local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0,0,0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.TextColor3 = Color3.fromRGB(255,100,100); txt.Text = "Hook"; txt.Parent = bill; bill.Parent = Camera; hookL[obj] = txt end; hookH[obj].Adornee = obj end end end
    if palOn then for _,obj in pairs(Map:GetDescendants()) do if obj:IsA("Model") and obj.Name:lower():find("pallet") then local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"); if not att then continue end; if not palH[obj] then local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.FillColor = Color3.fromRGB(255,255,100); hl.OutlineColor = Color3.fromRGB(255,200,0); hl.Parent = Camera; palH[obj] = hl end; palH[obj].Adornee = obj end end end
    if gateOn then for _,obj in pairs(Map:GetDescendants()) do local ln = obj.Name:lower(); if obj:IsA("Model") and (ln:find("gate") or ln:find("exit")) then local att = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"); if not att then continue end; if not gateH[obj] then local hl = Instance.new("Highlight"); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.FillColor = Color3.fromRGB(160,0,255); hl.OutlineColor = Color3.fromRGB(200,120,255); hl.Parent = Camera; gateH[obj] = hl; local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0,100,0,30); bill.StudsOffset = Vector3.new(0,2,0); bill.AlwaysOnTop = true; local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 14; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0,0,0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.TextColor3 = Color3.fromRGB(200,150,255); txt.Text = "Gate"; txt.Parent = bill; bill.Parent = Camera; gateL[obj] = txt end; gateH[obj].Adornee = att end end end
    if winOn then for _,obj in pairs(Map:GetDescendants()) do if obj:IsA("BasePart") and obj.Name:lower():find("window") then if not winL[obj] then local bill = Instance.new("BillboardGui"); bill.Size = UDim2.new(0,80,0,25); bill.StudsOffset = Vector3.new(0,1.5,0); bill.AlwaysOnTop = true; local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.SourceSansSemibold; txt.TextSize = 12; txt.TextStrokeTransparency = 0.4; txt.TextStrokeColor3 = Color3.new(0,0,0); txt.TextXAlignment = Enum.TextXAlignment.Center; txt.TextColor3 = Color3.fromRGB(180,230,255); txt.Text = "Window"; txt.Parent = bill; bill.Parent = Camera; winL[obj] = txt end; winL[obj].Parent.Adornee = obj end end end

    -- Speedhack
    if spdOn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = spdVal end
    -- Noclip
    if noclipOn and LocalPlayer.Character then for _,part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end
    -- Sprint
    if sprintOn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then sprinting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift); LocalPlayer.Character.Humanoid.WalkSpeed = sprinting and 16 * sprintBoost or 16 end
    -- Fog
    if fogOn then Lighting.FogStart = fogS; Lighting.FogEnd = fogE end
    -- Sky
    if skyOn then Lighting.Brightness = skyB / 10; Lighting.ExposureCompensation = skyE / 10 end
    -- HUD counting
    hudFrames = hudFrames + 1; hudTime = hudTime + 0.1; if hudTime >= 1 then hudFpsVal = math.floor(hudFrames / hudTime); hudFrames = 0; hudTime = 0 end
end)

-- Flashlight
RunService.Heartbeat:Connect(function()
    if flOn then if not flObj then flObj = Instance.new("SpotLight"); flObj.Brightness = 2; flObj.Range = 60; flObj.Angle = 90; flObj.Face = Enum.NormalId.Front; flObj.Parent = Camera end; flObj.Enabled = true elseif flObj then flObj.Enabled = false end
end)