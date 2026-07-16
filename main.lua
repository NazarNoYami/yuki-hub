--[[
  Yuki Hub v5.0 - Native GUI
  ESP Line + Projectile Aimbot + Lead Prediction
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Gravity = workspace.Gravity

-- Cleanup
for _, v in pairs(CoreGui:GetChildren()) do
    if v.Name == "YukiHub" then v:Destroy() end
end

-- Responsive sizing
local screenSize = Camera.ViewportSize
local guiW = math.clamp(screenSize.X * 0.55, 320, 580)
local guiH = math.clamp(screenSize.Y * 0.6, 280, 460)
local tabW = math.min(130, guiW * 0.25)
local fs = guiW > 500 and 13 or 11

-- Colors
local accent = Color3.fromRGB(0, 174, 255)
local bg1 = Color3.fromRGB(25, 25, 35)
local bg2 = Color3.fromRGB(35, 35, 50)
local bg3 = Color3.fromRGB(20, 20, 30)
local contentBg = Color3.fromRGB(30, 30, 42)
local textColor = Color3.fromRGB(200, 200, 220)
local textBright = Color3.fromRGB(255, 255, 255)

-- GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "YukiHub"; GUI.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, guiW, 0, guiH)
Main.Position = UDim2.new(0.5, -guiW/2, 0.5, -guiH/2)
Main.BackgroundColor3 = bg1; Main.BorderSizePixel = 0
Main.Active = true; Main.Draggable = true; Main.Parent = GUI

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8); Corner.Parent = Main

-- Drop shadow
local Shadow = Instance.new("Frame")
Shadow.Size = UDim2.new(1, 6, 1, 6)
Shadow.Position = UDim2.new(0, -3, 0, -3)
Shadow.BackgroundColor3 = Color3.new(0, 0, 0)
Shadow.BackgroundTransparency = 0.6
Shadow.BorderSizePixel = 0; Shadow.ZIndex = -1; Shadow.Parent = Main

local ShadowCorner = Instance.new("UICorner")
ShadowCorner.CornerRadius = UDim.new(0, 10); ShadowCorner.Parent = Shadow

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = bg2; TitleBar.BorderSizePixel = 0; TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8); TitleCorner.Parent = TitleBar

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 4)
TitleFix.Position = UDim2.new(0, 0, 1, -4)
TitleFix.BackgroundColor3 = bg2; TitleFix.BorderSizePixel = 0; TitleFix.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0); Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1; Title.Text = "Yuki Hub v5.0"
Title.TextColor3 = textBright; Title.Font = Enum.Font.GothamBold
Title.TextSize = fs + 2; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = TitleBar

-- Close/Minimize
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 24, 0, 24); MinBtn.Position = UDim2.new(1, -58, 0, 6)
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70); MinBtn.Text = "_"
MinBtn.TextColor3 = textBright; MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 14; MinBtn.Parent = TitleBar
local MinBtnCorner = Instance.new("UICorner"); MinBtnCorner.CornerRadius = UDim.new(0, 5); MinBtnCorner.Parent = MinBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24); CloseBtn.Position = UDim2.new(1, -30, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70); CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100); CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 13; CloseBtn.Parent = TitleBar
local CloseBtnCorner = Instance.new("UICorner"); CloseBtnCorner.CornerRadius = UDim.new(0, 5); CloseBtnCorner.Parent = CloseBtn

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

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 8); ContentCorner.Parent = Content

local ContentInner = Instance.new("ScrollingFrame")
ContentInner.Size = UDim2.new(1, -10, 1, -10); ContentInner.Position = UDim2.new(0, 5, 0, 5)
ContentInner.BackgroundTransparency = 1; ContentInner.BorderSizePixel = 0
ContentInner.ScrollBarThickness = 4; ContentInner.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
ContentInner.CanvasSize = UDim2.new(0, 0, 0, 0); ContentInner.Parent = Content

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6); ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; ContentLayout.Parent = ContentInner

local ContentPad = Instance.new("UIPadding")
ContentPad.PaddingTop = UDim.new(0, 6); ContentPad.PaddingLeft = UDim.new(0, 8); ContentPad.PaddingRight = UDim.new(0, 8); ContentPad.Parent = ContentInner

local function UpdateCanvas()
    ContentInner.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 12)
end
ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

-- ============== UI BUILDERS ==============
local function AddLabel(text, color)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 24); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = color or textColor
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = fs; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = ContentInner
end

local function AddButton(text, desc, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, desc and 48 or 32)
    frame.BackgroundColor3 = bg2; frame.BorderSizePixel = 0; frame.Parent = ContentInner
    local fCorner = Instance.new("UICorner"); fCorner.CornerRadius = UDim.new(0, 5); fCorner.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1
    btn.Text = text; btn.TextColor3 = textBright; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = fs; btn.Parent = frame
    if desc then
        btn.TextYAlignment = Enum.TextYAlignment.Top
        btn.Position = UDim2.new(0, 10, 0, 6)
        btn.Size = UDim2.new(1, -10, 0, 22)
        btn.TextXAlignment = Enum.TextXAlignment.Left
        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(1, -10, 0, 16); descLbl.Position = UDim2.new(0, 10, 0, 26)
        descLbl.BackgroundTransparency = 1; descLbl.Text = desc
        descLbl.TextColor3 = Color3.fromRGB(140, 140, 170); descLbl.Font = Enum.Font.Gotham; descLbl.TextSize = fs - 2
        descLbl.TextXAlignment = Enum.TextXAlignment.Left; descLbl.Parent = frame
    end
    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function() frame.BackgroundColor3 = Color3.fromRGB(45, 45, 65) end)
    btn.MouseLeave:Connect(function() frame.BackgroundColor3 = bg2 end)
end

local function AddToggle(text, desc, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, desc and 44 or 30)
    frame.BackgroundColor3 = bg2; frame.BorderSizePixel = 0; frame.Parent = ContentInner
    local fCorner = Instance.new("UICorner"); fCorner.CornerRadius = UDim.new(0, 5); fCorner.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 0, 20); lbl.Position = UDim2.new(0, 10, 0, 2)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = textBright
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = fs; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = frame
    if desc then
        lbl.Size = UDim2.new(1, -50, 0, 18)
        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(1, -50, 0, 16); descLbl.Position = UDim2.new(0, 10, 0, 20)
        descLbl.BackgroundTransparency = 1; descLbl.Text = desc
        descLbl.TextColor3 = Color3.fromRGB(140, 140, 170); descLbl.Font = Enum.Font.Gotham; descLbl.TextSize = fs - 2
        descLbl.TextXAlignment = Enum.TextXAlignment.Left; descLbl.Parent = frame
    end

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 38, 0, 20); toggleBtn.Position = UDim2.new(1, -46, 0, desc and 12 or 5)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80); toggleBtn.Text = ""; toggleBtn.Parent = frame
    local tglCorner = Instance.new("UICorner"); tglCorner.CornerRadius = UDim.new(0, 10); tglCorner.Parent = toggleBtn
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 14, 0, 14); circle.Position = UDim2.new(0, 3, 0, 3)
    circle.BackgroundColor3 = textBright; circle.BorderSizePixel = 0; circle.Parent = toggleBtn
    local circCorner = Instance.new("UICorner"); circCorner.CornerRadius = UDim.new(0, 7); circCorner.Parent = circle

    local state = default
    if state then toggleBtn.BackgroundColor3 = accent; circle.Position = UDim2.new(0, 21, 0, 3) end
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.BackgroundColor3 = state and accent or Color3.fromRGB(60, 60, 80)
        circle:TweenPosition(state and UDim2.new(0, 21, 0, 3) or UDim2.new(0, 3, 0, 3), nil, nil, 0.15, true)
        if callback then pcall(callback, state) end
    end)
    return { SetState = function(s) state = s; toggleBtn.BackgroundColor3 = s and accent or Color3.fromRGB(60, 60, 80); circle.Position = s and UDim2.new(0, 21, 0, 3) or UDim2.new(0, 3, 0, 3) end, GetState = function() return state end }
end

-- Slider with global drag
local activeSlider = nil
local function AddSlider(text, default, min, max, callback)
    local sFrame = Instance.new("Frame")
    sFrame.Size = UDim2.new(1, 0, 0, 44); sFrame.BackgroundColor3 = bg2; sFrame.BorderSizePixel = 0; sFrame.Parent = ContentInner
    local sCorner = Instance.new("UICorner"); sCorner.CornerRadius = UDim.new(0, 5); sCorner.Parent = sFrame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 0, 18); lbl.Position = UDim2.new(0, 8, 0, 3)
    lbl.BackgroundTransparency = 1; lbl.Text = text .. ": " .. tostring(default)
    lbl.TextColor3 = textBright; lbl.Font = Enum.Font.Gotham; lbl.TextSize = fs; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = sFrame

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 40, 0, 18); valLbl.Position = UDim2.new(1, -44, 0, 3)
    valLbl.BackgroundTransparency = 1; valLbl.Text = tostring(default)
    valLbl.TextColor3 = accent; lbl.Font = Enum.Font.GothamBold; valLbl.TextSize = fs; valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Parent = sFrame

    local sBg = Instance.new("Frame")
    sBg.Size = UDim2.new(1, -16, 0, 5); sBg.Position = UDim2.new(0, 8, 0, 28)
    sBg.BackgroundColor3 = Color3.fromRGB(60, 60, 80); sBg.BorderSizePixel = 0; sBg.Parent = sFrame
    local sBgCorner = Instance.new("UICorner"); sBgCorner.CornerRadius = UDim.new(0, 3); sBgCorner.Parent = sBg

    local sFill = Instance.new("Frame")
    local ratio = max > min and (default - min) / (max - min) or 0
    sFill.Size = UDim2.new(ratio, 0, 1, 0); sFill.BackgroundColor3 = accent; sFill.BorderSizePixel = 0; sFill.Parent = sBg
    local sFillCorner = Instance.new("UICorner"); sFillCorner.CornerRadius = UDim.new(0, 3); sFillCorner.Parent = sFill

    local val = default
    local sd = { bg = sBg, fill = sFill, lbl = valLbl, min = min, max = max, text = text, cb = callback }

    sBg.MouseButton1Down:Connect(function()
        activeSlider = sd
        local pos = math.clamp((UserInputService:GetMouseLocation().X - sBg.AbsolutePosition.X) / sBg.AbsoluteSize.X, 0, 1)
        val = math.floor(min + (max - min) * pos)
        sFill.Size = UDim2.new(pos, 0, 1, 0); valLbl.Text = tostring(val)
        if callback then pcall(callback, val) end
    end)

    return { SetValue = function(v) val = v; local r = max > min and (v - min) / (max - min) or 0; sFill.Size = UDim2.new(r, 0, 1, 0); valLbl.Text = tostring(v) end }
end

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and activeSlider then
        local d = activeSlider
        local pos = math.clamp((UserInputService:GetMouseLocation().X - d.bg.AbsolutePosition.X) / d.bg.AbsoluteSize.X, 0, 1)
        local v = math.floor(d.min + (d.max - d.min) * pos)
        d.fill.Size = UDim2.new(pos, 0, 1, 0); d.lbl.Text = tostring(v)
        if d.cb then pcall(d.cb, v) end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then activeSlider = nil end
end)

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

-- ============== PROJECTILE AIMBOT ==============
local projEnabled = false; local projV = 150; local projG = 196.2
local projTarget = nil; local projLead = true; local projLeadFac = 1
local targetPrevPos = {}; local targetVel = {}

local function GetTargetPos(t)
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then return t.Character.HumanoidRootPart.Position end
    return nil
end

local function GetTargetVel(t)
    local pos = GetTargetPos(t); if not pos then return Vector3.new() end
    local prev = targetPrevPos[t]; targetPrevPos[t] = pos
    if prev then
        local vel = (pos - prev) / 0.1
        targetVel[t] = targetVel[t] and (targetVel[t] * 0.7 + vel * 0.3) or vel
    end
    return targetVel[t] or Vector3.new()
end

local function PredictPos(t, time)
    local pos = GetTargetPos(t); if not pos then return nil end
    return pos + GetTargetVel(t) * time
end

local function CalcAngle(origin, target, vel, grav)
    local dx = target.X - origin.X; local dz = target.Z - origin.Z; local dy = target.Y - origin.Y
    local dist = math.sqrt(dx*dx + dz*dz); if dist < 1 then return nil end
    local vSq = vel*vel; local g = grav or 196.2
    local a = (g * dist * dist) / (2 * vSq); local b = -dist; local c = a + dy
    local disc = b*b - 4*a*c; if disc < 0 then return nil end
    local sqrtD = math.sqrt(disc)
    local ang = math.atan((-b + sqrtD) / (2*a))
    if ang < 0 then ang = math.atan((-b - sqrtD) / (2*a)) end
    if ang < 0 then return nil end
    return ang
end

local function GetAimPoint(origin, target, vel, grav)
    local aimT = target
    if projLead then
        local dist = (target - origin).Magnitude
        local estTime = dist / (vel * 0.707) -- rough estimate
        if estTime > 0 then
            local pred = PredictPos(projTarget, estTime * projLeadFac)
            if pred then aimT = pred end
        end
    end
    local angle = CalcAngle(origin, aimT, vel, grav)
    if not angle then return nil end
    local dx = aimT.X - origin.X; local dz = aimT.Z - origin.Z
    local dist = math.sqrt(dx*dx + dz*dz)
    local ho = math.tan(angle) * dist
    return aimT + Vector3.new(0, ho, 0)
end

-- ESP Line
local espLineObj = nil; local espLineOn = false
local function UpdateESPLine(t)
    if not espLineOn or not t then if espLineObj then espLineObj.Visible = false end; return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then if espLineObj then espLineObj.Visible = false end; return end
    local tp = GetTargetPos(t); if not tp then if espLineObj then espLineObj.Visible = false end; return end
    local mp = LocalPlayer.Character.HumanoidRootPart.Position
    local from, _ = Camera:WorldToViewportPoint(mp); local to, _ = Camera:WorldToViewportPoint(tp)
    if not espLineObj then
        espLineObj = Drawing.new("Line"); espLineObj.Thickness = 2; espLineObj.Color = Color3.fromRGB(0, 255, 100); espLineObj.Transparency = 0.5
    end
    espLineObj.From = Vector2.new(from.X, from.Y); espLineObj.To = Vector2.new(to.X, to.Y); espLineObj.Visible = true
end

-- Projectile Arc
local projArcObj = nil; local projArcOn = false
local function DrawArc(origin, target, vel, grav)
    if not projArcObj then
        projArcObj = Drawing.new("Line"); projArcObj.Thickness = 1; projArcObj.Color = Color3.fromRGB(255, 200, 50); projArcObj.Transparency = 0.3
    end
    if not projArcOn or not target then projArcObj.Visible = false; return end
    local angle = CalcAngle(origin, target, vel, grav)
    if not angle then projArcObj.Visible = false; return end
    local dx = target.X - origin.X; local dz = target.Z - origin.Z
    local dir = Vector2.new(dx, dz).Unit; local g = grav or 196.2; local v = vel
    local vx = v * math.cos(angle); local vy = v * math.sin(angle)
    local pts = {}; local totalT = (2 * vy) / g
    for t = 0, totalT, 0.1 do
        local x = vx * t; local y = vy * t - 0.5 * g * t * t
        local pos = origin + Vector3.new(dir.X * x, y, dir.Y * x)
        local sp, _ = Camera:WorldToViewportPoint(pos); table.insert(pts, Vector2.new(sp.X, sp.Y))
    end
    if #pts > 1 then projArcObj.Visible = true; projArcObj.Points = pts else projArcObj.Visible = false end
end

-- Aimbot Basic
local aimEnabled = false; local aimSmooth = 1; local aimFOV = 90

-- ============== TABS ==============
local Tabs = {"Main", "ESP", "Aimbot", "Misc", "Credits"}
local TabIcons = {"[H]", "[E]", "[A]", "[M]", "[I]"}
local TabButtons = {}

local function ClearContent()
    for _, v in pairs(ContentInner:GetChildren()) do
        if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then v:Destroy() end
    end
end

-- Tab content functions
function LoadMainTab()
    AddLabel("Game Options", Color3.fromRGB(100, 180, 255))
    AddButton("Rejoin Server", nil, function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)
    AddButton("Server Hop", nil, function()
        local function gs(c)
            local u = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100"
            if c then u = u.."&cursor="..c end; return HttpService:JSONDecode(game:HttpGet(u))
        end; local s = gs()
        if s and s.data then for _, v in pairs(s.data) do if v.playing < v.maxPlayers and v.id ~= game.JobId then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, v.id, LocalPlayer); return end end end
    end)
    AddLabel("Movement", Color3.fromRGB(100, 255, 180))
    AddToggle("Walkspeed", nil, false, function(s)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = s and 50 or 16 end
    end)
    AddSlider("Walkspeed", 50, 16, 250, function(v)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = v end
    end)
end

function LoadESPTab()
    AddLabel("Visuals", Color3.fromRGB(255, 180, 100))
    local ESPObjs = {}; local ESPOn = false
    AddToggle("ESP Box", nil, false, function(s)
        ESPOn = s
        if s then
            for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then
                local box = Drawing.new("Square"); box.Thickness = 2; box.Color = Color3.fromRGB(255,50,50); box.Filled = false; box.Visible = false
                local nl = Drawing.new("Text"); nl.Center = true; nl.Size = 14; nl.Outline = true; nl.Color = Color3.fromRGB(255,255,255); nl.Visible = false
                ESPObjs[p] = {Box=box,Name=nl}
            end end
            RunService.RenderStepped:Connect(function() if not ESPOn then return end
                for plr,o in pairs(ESPObjs) do
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local root=plr.Character.HumanoidRootPart; local pos,on=Camera:WorldToViewportPoint(root.Position)
                        if on then local sz=Vector2.new(2000/pos.Z,3000/pos.Z); o.Box.Size=sz; o.Box.Position=Vector2.new(pos.X-sz.X/2,pos.Y-sz.Y/2); o.Box.Visible=true; o.Name.Position=Vector2.new(pos.X,pos.Y-sz.Y/2-16); o.Name.Text=plr.Name; o.Name.Visible=true
                        else o.Box.Visible=false; o.Name.Visible=false end
                    else o.Box.Visible=false; o.Name.Visible=false end end end)
        else for _,o in pairs(ESPObjs) do o.Box.Visible=false; o.Name.Visible=false end end
    end)
    AddToggle("ESP Line", "Green line to locked target", false, function(s) espLineOn = s; if not s and espLineObj then espLineObj.Visible = false end end)
    AddToggle("Projectile Arc", "Show trajectory arc", false, function(s) projArcOn = s; if not s and projArcObj then projArcObj.Visible = false end end)
end

function LoadAimbotTab()
    AddLabel("Basic Aimbot", Color3.fromRGB(255, 100, 100))
    AddToggle("Basic Aimbot", nil, false, function(s) aimEnabled = s; if s then projEnabled = false end end)
    AddSlider("Smoothness", 1, 1, 10, function(v) aimSmooth = v end)
    AddSlider("FOV", 90, 10, 360, function(v) aimFOV = v end)

    AddLabel("Projectile Aimbot (Bows/Daggers)", Color3.fromRGB(255, 200, 100))
    AddToggle("Projectile Aimbot", "For arcing weapons", false, function(s) projEnabled = s; if s then aimEnabled = false end end)
    AddSlider("Proj. Velocity", 150, 30, 500, function(v) projV = v end)
    AddSlider("Proj. Gravity", 196.2, 50, 500, function(v) projG = v end)
    AddToggle("Lead Prediction", "Predict moving targets", true, function(s) projLead = s end)
    AddSlider("Lead Factor", 1, 0.5, 3, function(v) projLeadFac = v end)
    AddButton("Lock Target", "Lock closest player", function()
        projTarget = GetClosestPlayer(360)
    end)
    AddButton("Unlock Target", nil, function() projTarget = nil end)
end

function LoadMiscTab()
    AddLabel("Utilities", Color3.fromRGB(180, 180, 255))
    AddButton("Reset Character", "Kill yourself", function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.Health = 0 end
    end)
    AddButton("Anti AFK", "Prevent auto-kick", function()
        LocalPlayer.Idled:Connect(function() VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1); task.wait(0.1); VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1) end)
    end)
    AddSlider("FPS Cap", 60, 15, 360, function(v) setfpscap(v) end)
    AddButton("Infinite Yield", "Admin commands", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end)
end

function LoadCreditsTab()
    AddLabel("Yuki Hub v5.0", Color3.fromRGB(255, 200, 100))
    AddLabel("Made for Tuan", Color3.fromRGB(180, 180, 200))
    AddLabel("Native GUI", Color3.fromRGB(150, 150, 180))
    AddLabel("Zero external dependencies", Color3.fromRGB(100, 100, 150))
end

-- Build tabs
for i, name in ipairs(Tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 32); btn.Position = UDim2.new(0, 4, 0, 4 + (i-1) * 36)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 38); btn.Text = TabIcons[i] .. "  " .. name
    btn.TextColor3 = Color3.fromRGB(150, 150, 180); btn.Font = Enum.Font.GothamSemibold; btn.TextSize = fs
    btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = TabBar
    local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(0, 5); btnCorner.Parent = btn
    btn.MouseButton1Click:Connect(function()
        for _, b in pairs(TabButtons) do b.BackgroundColor3 = Color3.fromRGB(25, 25, 38); b.TextColor3 = Color3.fromRGB(150, 150, 180) end
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 70); btn.TextColor3 = textBright; ClearContent()
        if name == "Main" then LoadMainTab() elseif name == "ESP" then LoadESPTab() elseif name == "Aimbot" then LoadAimbotTab() elseif name == "Misc" then LoadMiscTab() elseif name == "Credits" then LoadCreditsTab() end
        UpdateCanvas()
    end)
    table.insert(TabButtons, btn)
end

-- Default load
LoadMainTab(); TabButtons[1].BackgroundColor3 = Color3.fromRGB(45, 45, 70); TabButtons[1].TextColor3 = textBright; UpdateCanvas()

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
    if projEnabled then
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local target = projTarget or GetClosestPlayer(360)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
            local origin = LocalPlayer.Character.HumanoidRootPart.Position
            local tPos = target.Character.HumanoidRootPart.Position
            local aimPoint = GetAimPoint(origin, tPos, projV, projG)
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