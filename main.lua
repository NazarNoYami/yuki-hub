--[[
  Yuki Hub v2.1 - Delta Executor
  Responsive Native GUI
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

-- Cleanup
for _, v in pairs(CoreGui:GetChildren()) do
    if v.Name == "YukiHub" then v:Destroy() end
end

-- Responsive sizing
local screenSize = Camera.ViewportSize
local guiW = math.clamp(screenSize.X * 0.55, 320, 580)
local guiH = math.clamp(screenSize.Y * 0.6, 280, 460)
local tabW = math.min(130, guiW * 0.25)
local fontSize = guiW > 500 and 13 or 11

-- GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "YukiHub"
GUI.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, guiW, 0, guiH)
Main.Position = UDim2.new(0.5, -guiW/2, 0.5, -guiH/2)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = GUI

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Main

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local TitleBarFix = Instance.new("Frame")
TitleBarFix.Size = UDim2.new(1, 0, 0, 4)
TitleBarFix.Position = UDim2.new(0, 0, 1, -4)
TitleBarFix.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
TitleBarFix.BorderSizePixel = 0
TitleBarFix.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Yuki Hub  v2.1"
Title.TextColor3 = Color3.fromRGB(200, 200, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = fontSize + 2
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -62, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
MinBtn.Text = "_"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 5)
MinCorner.Parent = MinBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -32, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 5)
CloseCorner.Parent = CloseBtn

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Main:TweenSize(
        minimized and UDim2.new(0, guiW, 0, 36) or UDim2.new(0, guiW, 0, guiH),
        Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true
    )
end)

CloseBtn.MouseButton1Click:Connect(function() GUI:Destroy() end)

-- Tab Bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0, tabW, 1, -36)
TabBar.Position = UDim2.new(0, 0, 0, 36)
TabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

-- Content Area
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -tabW, 1, -36)
Content.Position = UDim2.new(0, tabW, 0, 36)
Content.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
Content.BorderSizePixel = 0
Content.Parent = Main

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 8)
ContentCorner.Parent = Content

-- Scrolling Content
local ContentInner = Instance.new("ScrollingFrame")
ContentInner.Size = UDim2.new(1, -10, 1, -10)
ContentInner.Position = UDim2.new(0, 5, 0, 5)
ContentInner.BackgroundTransparency = 1
ContentInner.BorderSizePixel = 0
ContentInner.ScrollBarThickness = 4
ContentInner.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
ContentInner.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentInner.Parent = Content

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentLayout.Parent = ContentInner

local ContentPad = Instance.new("UIPadding")
ContentPad.PaddingTop = UDim.new(0, 6)
ContentPad.PaddingLeft = UDim.new(0, 8)
ContentPad.PaddingRight = UDim.new(0, 8)
ContentPad.Parent = ContentInner

-- Auto canvas resize
local function UpdateCanvas()
    ContentInner.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 12)
end
ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

-- Tab buttons
local Tabs = {"Main", "ESP", "Aimbot", "Misc", "Credits"}
local TabIcons = {"[H]", "[E]", "[A]", "[M]", "[I]"}
local TabButtons = {}
local currentTab = "Main"

local function ClearContent()
    for _, v in pairs(ContentInner:GetChildren()) do
        if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then
            v:Destroy()
        end
    end
end

-- ============== UI BUILDERS ==============
local function AddLabel(text, color)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(200, 200, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = fontSize
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = ContentInner
end

local function AddButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = fontSize
    btn.Parent = ContentInner

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 5)
    bCorner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(60, 60, 90) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(45, 45, 70) end)
    return btn
end

local function AddToggle(text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    frame.BorderSizePixel = 0
    frame.Parent = ContentInner

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, 5)
    fCorner.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -48, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200, 200, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = fontSize
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 38, 0, 20)
    toggleBtn.Position = UDim2.new(1, -46, 0, 5)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    toggleBtn.Text = ""
    toggleBtn.Parent = frame

    local tglCorner = Instance.new("UICorner")
    tglCorner.CornerRadius = UDim.new(0, 10)
    tglCorner.Parent = toggleBtn

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = UDim2.new(0, 3, 0, 3)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel = 0
    circle.Parent = toggleBtn

    local circCorner = Instance.new("UICorner")
    circCorner.CornerRadius = UDim.new(0, 7)
    circCorner.Parent = circle

    local state = default
    if state then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 174, 255)
        circle.Position = UDim2.new(0, 21, 0, 3)
    end

    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 174, 255)
            circle:TweenPosition(UDim2.new(0, 21, 0, 3), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            circle:TweenPosition(UDim2.new(0, 3, 0, 3), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        end
        if callback then pcall(callback, state) end
    end)

    return { SetState = function(s) state = s
        toggleBtn.BackgroundColor3 = s and Color3.fromRGB(0, 174, 255) or Color3.fromRGB(60, 60, 80)
        circle.Position = s and UDim2.new(0, 21, 0, 3) or UDim2.new(0, 3, 0, 3)
    end, GetState = function() return state end }
end

-- Slider with global drag support
local activeSlider = nil

local function AddSlider(text, default, min, max, callback)
    local sFrame = Instance.new("Frame")
    sFrame.Size = UDim2.new(1, 0, 0, 44)
    sFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    sFrame.BorderSizePixel = 0
    sFrame.Parent = ContentInner

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 5)
    sCorner.Parent = sFrame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 0, 18)
    lbl.Position = UDim2.new(0, 8, 0, 3)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. tostring(default)
    lbl.TextColor3 = Color3.fromRGB(200, 200, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = fontSize
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = sFrame

    local sBg = Instance.new("Frame")
    sBg.Size = UDim2.new(1, -16, 0, 5)
    sBg.Position = UDim2.new(0, 8, 0, 28)
    sBg.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    sBg.BorderSizePixel = 0
    sBg.Parent = sFrame

    local sBgCorner = Instance.new("UICorner")
    sBgCorner.CornerRadius = UDim.new(0, 3)
    sBgCorner.Parent = sBg

    local sFill = Instance.new("Frame")
    local ratio = (default - min) / (max - min)
    sFill.Size = UDim2.new(ratio, 0, 1, 0)
    sFill.BackgroundColor3 = Color3.fromRGB(0, 174, 255)
    sFill.BorderSizePixel = 0
    sFill.Parent = sBg

    local sFillCorner = Instance.new("UICorner")
    sFillCorner.CornerRadius = UDim.new(0, 3)
    sFillCorner.Parent = sFill

    local val = default
    local sliderData = { bg = sBg, fill = sFill, lbl = lbl, min = min, max = max, text = text, cb = callback }

    sBg.MouseButton1Down:Connect(function()
        activeSlider = sliderData
        local pos = math.clamp((UserInputService:GetMouseLocation().X - sBg.AbsolutePosition.X) / sBg.AbsoluteSize.X, 0, 1)
        val = math.floor(min + (max - min) * pos)
        sFill.Size = UDim2.new(pos, 0, 1, 0)
        lbl.Text = text .. ": " .. tostring(val)
        if callback then pcall(callback, val) end
    end)

    return { SetValue = function(v) val = v
        local r = (v - min) / (max - min)
        sFill.Size = UDim2.new(r, 0, 1, 0)
        lbl.Text = text .. ": " .. tostring(v)
    end }
end

-- Global slider drag
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and activeSlider then
        local d = activeSlider
        local pos = math.clamp((UserInputService:GetMouseLocation().X - d.bg.AbsolutePosition.X) / d.bg.AbsoluteSize.X, 0, 1)
        local v = math.floor(d.min + (d.max - d.min) * pos)
        d.fill.Size = UDim2.new(pos, 0, 1, 0)
        d.lbl.Text = d.text .. ": " .. tostring(v)
        if d.cb then pcall(d.cb, v) end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        activeSlider = nil
    end
end)

-- ============== TAB CONTENT ==============
local ESPObjs = {}
local ESPOn = false

function LoadMainTab()
    AddLabel("Game Options", Color3.fromRGB(100, 180, 255))
    AddButton("Rejoin Server", function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end)
    AddButton("Server Hop", function()
        local function getServers(c)
            local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100"
            if c then url = url.."&cursor="..c end
            local r = game:HttpGet(url)
            return HttpService:JSONDecode(r)
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
    end)
    AddLabel("Movement", Color3.fromRGB(100, 255, 180))
    AddToggle("Walkspeed", false, function(state)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = state and 50 or 16
        end
    end)
    AddSlider("Walkspeed Value", 50, 16, 250, function(v)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end)
end

function LoadESPTab()
    AddLabel("Visuals", Color3.fromRGB(255, 180, 100))
    AddToggle("ESP Box", false, function(state)
        ESPOn = state
        if state then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    local box = Drawing.new("Square")
                    box.Thickness = 2; box.Color = Color3.fromRGB(255, 50, 50)
                    box.Filled = false; box.Visible = false
                    local nl = Drawing.new("Text")
                    nl.Center = true; nl.Size = 14; nl.Outline = true
                    nl.Color = Color3.fromRGB(255, 255, 255); nl.Visible = false
                    ESPObjs[p] = { Box = box, Name = nl }
                end
            end
            RunService.RenderStepped:Connect(function()
                if not ESPOn then return end
                for plr, o in pairs(ESPObjs) do
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local root = plr.Character.HumanoidRootPart
                        local pos, on = workspace.CurrentCamera:WorldToViewportPoint(root.Position)
                        if on then
                            local sz = Vector2.new(2000/pos.Z, 3000/pos.Z)
                            o.Box.Size = sz; o.Box.Position = Vector2.new(pos.X-sz.X/2, pos.Y-sz.Y/2)
                            o.Box.Visible = true
                            o.Name.Position = Vector2.new(pos.X, pos.Y-sz.Y/2-16)
                            o.Name.Text = plr.Name; o.Name.Visible = true
                        else o.Box.Visible = false; o.Name.Visible = false end
                    else o.Box.Visible = false; o.Name.Visible = false end
                end
            end)
        else
            for _, o in pairs(ESPObjs) do o.Box.Visible = false; o.Name.Visible = false end
        end
    end)
end

local aimEnabled = false
local aimSmooth = 1
local aimFOV = 90

function LoadAimbotTab()
    AddLabel("Aimbot", Color3.fromRGB(255, 100, 100))
    AddToggle("Aimbot", false, function(s) aimEnabled = s end)
    AddSlider("Smoothness", 1, 1, 10, function(v) aimSmooth = v end)
    AddSlider("FOV", 90, 10, 360, function(v) aimFOV = v end)
    RunService.RenderStepped:Connect(function()
        if not aimEnabled then return end
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local closest = nil; local closestDist = aimFOV
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local pos, on = workspace.CurrentCamera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if on then
                    local d = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if d < closestDist then closestDist = d; closest = p end
                end
            end
        end
        if closest and closest.Character then
            local pos = workspace.CurrentCamera:WorldToViewportPoint(closest.Character.HumanoidRootPart.Position)
            local t = Vector2.new(pos.X, pos.Y); local c = Vector2.new(Mouse.X, Mouse.Y)
            local s = t:Lerp(c, 1/aimSmooth)
            mousemoverel(s.X-c.X, s.Y-c.Y)
        end
    end)
end

function LoadMiscTab()
    AddLabel("Utilities", Color3.fromRGB(180, 180, 255))
    AddButton("Reset Character", function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Health = 0
        end
    end)
    AddButton("Anti AFK", function()
        LocalPlayer.Idled:Connect(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end)
    end)
    AddSlider("FPS Cap", 60, 15, 360, function(v) setfpscap(v) end)
    AddButton("Infinite Yield", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end)
end

function LoadCreditsTab()
    AddLabel("Yuki Hub v2.1", Color3.fromRGB(255, 200, 100))
    AddLabel("Made for Tuan", Color3.fromRGB(180, 180, 200))
    AddLabel("Delta Executor", Color3.fromRGB(150, 150, 180))
    AddLabel("Responsive Native GUI", Color3.fromRGB(100, 100, 150))
end

-- Build tabs
for i, name in ipairs(Tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 32)
    btn.Position = UDim2.new(0, 4, 0, 4 + (i-1) * 36)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
    btn.Text = TabIcons[i] .. "  " .. name
    btn.TextColor3 = Color3.fromRGB(150, 150, 180)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = fontSize
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = TabBar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        currentTab = name
        for _, b in pairs(TabButtons) do
            b.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
            b.TextColor3 = Color3.fromRGB(150, 150, 180)
        end
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ClearContent()
        if name == "Main" then LoadMainTab()
        elseif name == "ESP" then LoadESPTab()
        elseif name == "Aimbot" then LoadAimbotTab()
        elseif name == "Misc" then LoadMiscTab()
        elseif name == "Credits" then LoadCreditsTab() end
        UpdateCanvas()
    end)
    table.insert(TabButtons, btn)
end

-- Default load
LoadMainTab()
TabButtons[1].BackgroundColor3 = Color3.fromRGB(45, 45, 70)
TabButtons[1].TextColor3 = Color3.fromRGB(255, 255, 255)
UpdateCanvas()