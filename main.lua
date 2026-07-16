--[[
  Yuki Hub v5.0 - WindUI Edition
  Essential + Notties + Yuki Hub merged
  Modular structure
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

-- Cleanup previous instances
for _, v in pairs(CoreGui:GetChildren()) do
    if v.Name == "YukiHub" then v:Destroy() end
end

-- Load WindUI with fallback
local WindUI_ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if not WindUI_ok or not WindUI then
    -- Fallback: create native GUI
    WindUI = nil
    warn("Yuki Hub: WindUI failed to load, using native GUI fallback")
end

-- ============== SHARED STATE ==============
_G.YH = {
    Players = Players, RunService = RunService, UserInputService = UserInputService,
    TweenService = TweenService, VirtualInputManager = VirtualInputManager,
    HttpService = HttpService, Lighting = Lighting, CoreGui = CoreGui,
    Camera = Camera, Map = Map, LocalPlayer = LocalPlayer, Mouse = Mouse, Gravity = Gravity,
    WindUI = WindUI, Window = nil, Tabs = {},
    IsNative = not WindUI_ok,
    C = {
        Blue = Color3.fromRGB(0, 120, 255), Red = Color3.fromRGB(255, 50, 50),
        Green = Color3.fromRGB(0, 255, 100), Yellow = Color3.fromRGB(255, 200, 50),
        Purple = Color3.fromRGB(160, 0, 255), White = Color3.fromRGB(255, 255, 255),
        Orange = Color3.fromRGB(255, 150, 50),
    },
    -- State
    aimOn = false, aimSmooth = 1, aimFOV = 90,
    projOn = false, projV = 150, projG = 196.2, projTarget = nil, projLead = true, projLeadFac = 1,
    espBoxOn = false, espLineOn = false, espLineColor = Color3.fromRGB(0, 255, 100),
    espLineMode = "Single", espLineOrigin = "Character", espLineObjs = {},
    ESPObjs = {}, playerESPOn = false, playerHighlights = {}, playerLabels = {},
    genOn = false, genH = {}, genL = {}, hookOn = false, hookH = {}, hookL = {},
    palOn = false, palH = {}, gateOn = false, gateH = {}, gateL = {}, winOn = false, winL = {},
    projArcOn = false, projArcObj = nil,
    brightOn = false, brightLevel = 1, fovOn = false, fovVal = 70, origFOV = Camera.FieldOfView,
    fogOn = false, fogS = 0, fogE = 1000, skyOn = false, skyB = 50, skyE = 50,
    spdOn = false, spdVal = 32, noclipOn = false,
    sprintOn = false, sprintBoost = 1.05, sprinting = false,
    flOn = false, flObj = nil, chOn = false, chLen = 10, chW = 2,
    stOn = false, stVal = 100, afkConnected = false,
    hudOn = false, hudFPS = true, hudPing = true, hudKiller = true,
    hudFrames = 0, hudTime = 0, hudFpsVal = 0, hudGui = nil,
}

-- ============== CREATE WINDOW ==============
local tabNames = {"Main", "ESP", "Aimbot", "Visuals", "Misc", "HUD", "Credits"}
local tabIcons = {
    "solar:home-2-bold-duotone", "solar:eye-bold-duotone", "solar:target-bold-duotone",
    "solar:palette-bold-duotone", "solar:settings-bold-duotone", "solar:chart-bold-duotone",
    "solar:info-circle-bold-duotone",
}

if WindUI then
    -- WINDUI MODE
    local Window = WindUI:CreateWindow({
        Title = "Yuki Hub v5.0",
        Folder = "YukiHub",
        Icon = "solar:home-2-bold-duotone",
        NewElements = true,
        HideSearchBar = false,
        Topbar = { Height = 44, ButtonsType = "Default" },
    })
    _G.YH.Window = Window
    Window:SetAccentColor(Color3.fromRGB(0, 120, 255))

    for i, name in ipairs(tabNames) do
        _G.YH.Tabs[name] = Window:Tab({
            Title = name, Icon = tabIcons[i],
            IconColor = Color3.fromHex("#83889E"), Border = true,
        })
    end
else
    -- NATIVE MODE (fallback)
    local screenSize = Camera.ViewportSize
    local guiW = math.clamp(screenSize.X * 0.55, 320, 580)
    local guiH = math.clamp(screenSize.Y * 0.6, 280, 460)
    local tabW = math.min(130, guiW * 0.25)
    local fs = guiW > 500 and 13 or 11

    -- Colors
    local accent = Color3.fromRGB(0, 120, 255)
    local bg1 = Color3.fromRGB(25, 25, 35); local bg2 = Color3.fromRGB(35, 35, 50)
    local bg3 = Color3.fromRGB(20, 20, 30); local contentBg = Color3.fromRGB(30, 30, 42)
    local textBright = Color3.fromRGB(255, 255, 255); local textMuted = Color3.fromRGB(150, 150, 180)
    local elementBg = Color3.fromRGB(40, 40, 58)

    local GUI = Instance.new("ScreenGui"); GUI.Name = "YukiHub"; GUI.Parent = CoreGui
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, guiW, 0, guiH); Main.Position = UDim2.new(0.5, -guiW/2, 0.5, -guiH/2)
    Main.BackgroundColor3 = bg1; Main.BorderSizePixel = 0; Main.Active = true; Main.Draggable = true; Main.Parent = GUI
    local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 8); Corner.Parent = Main

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 36); TitleBar.BackgroundColor3 = bg2; TitleBar.BorderSizePixel = 0; TitleBar.Parent = Main
    local TCorner = Instance.new("UICorner"); TCorner.CornerRadius = UDim.new(0, 8); TCorner.Parent = TitleBar
    local TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0, 4); TitleFix.Position = UDim2.new(0, 0, 1, -4); TitleFix.BackgroundColor3 = bg2; TitleFix.BorderSizePixel = 0; TitleFix.Parent = Main
    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size = UDim2.new(1, -80, 1, 0); TitleLbl.Position = UDim2.new(0, 12, 0, 0); TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text = "Yuki Hub v5.0"; TitleLbl.TextColor3 = textBright; TitleLbl.Font = Enum.Font.GothamBold; TitleLbl.TextSize = fs + 2; TitleLbl.TextXAlignment = Enum.TextXAlignment.Left; TitleLbl.Parent = TitleBar
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 24, 0, 24); CloseBtn.Position = UDim2.new(1, -30, 0, 6); CloseBtn.BackgroundColor3 = Color3.fromRGB(50,50,70)
    CloseBtn.Text = "X"; CloseBtn.TextColor3 = Color3.fromRGB(255,100,100); CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 13; CloseBtn.Parent = TitleBar
    local CloseBtnC = Instance.new("UICorner"); CloseBtnC.CornerRadius = UDim.new(0, 5); CloseBtnC.Parent = CloseBtn
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
    local tabPages = {}
    local tabIconsNative = {"H","E","A","V","M","D","I"}

    for i, name in ipairs(tabNames) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 32); btn.Position = UDim2.new(0, 4, 0, 4 + (i-1) * 36)
        btn.BackgroundColor3 = Color3.fromRGB(25,25,38); btn.Text = tabIconsNative[i] .. "  " .. name
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
    tabs[1].btn.BackgroundColor3 = Color3.fromRGB(45,45,70); tabs[1].btn.TextColor3 = textBright; tabs[1].page.Visible = true; currentTab = tabs[1]

    -- Native UI builders (compatibility layer)
        local function NativeSection(parent, title)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 24); lbl.BackgroundTransparency = 1; lbl.Text = title
            lbl.TextColor3 = accent; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = fs; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = parent
            local api = {}
            function api:Space() end
            function api:Button(cfg)
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 0, cfg.Desc and 48 or 32); frame.BackgroundColor3 = elementBg; frame.BorderSizePixel = 0; frame.Parent = parent
                local fC = Instance.new("UICorner"); fC.CornerRadius = UDim.new(0, 5); fC.Parent = frame
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = cfg.Title; btn.TextColor3 = textBright
                btn.Font = Enum.Font.GothamSemibold; btn.TextSize = fs; btn.Parent = frame
                if cfg.Desc then
                    btn.TextYAlignment = Enum.TextYAlignment.Top; btn.Position = UDim2.new(0,10,0,6); btn.Size = UDim2.new(1,-10,0,22)
                    btn.TextXAlignment = Enum.TextXAlignment.Left
                    local dl = Instance.new("TextLabel"); dl.Size = UDim2.new(1,-10,0,16); dl.Position = UDim2.new(0,10,0,26)
                    dl.BackgroundTransparency = 1; dl.Text = cfg.Desc; dl.TextColor3 = Color3.fromRGB(140,140,170); dl.Font = Enum.Font.Gotham; dl.TextSize = fs - 2; dl.TextXAlignment = Enum.TextXAlignment.Left; dl.Parent = frame
                end
                btn.MouseButton1Click:Connect(cfg.Callback or function() end)
                btn.MouseEnter:Connect(function() frame.BackgroundColor3 = Color3.fromRGB(50,50,70) end)
                btn.MouseLeave:Connect(function() frame.BackgroundColor3 = elementBg end)
            end
            function api:Toggle(cfg)
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 0, cfg.Desc and 44 or 30); frame.BackgroundColor3 = elementBg; frame.BorderSizePixel = 0; frame.Parent = parent
                local fC = Instance.new("UICorner"); fC.CornerRadius = UDim.new(0, 5); fC.Parent = frame
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -50, 0, cfg.Desc and 18 or 20); lbl.Position = UDim2.new(0,10,0,2); lbl.BackgroundTransparency = 1; lbl.Text = cfg.Title
                lbl.TextColor3 = textBright; lbl.Font = Enum.Font.Gotham; lbl.TextSize = fs; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = frame
                if cfg.Desc then
                    local dl = Instance.new("TextLabel"); dl.Size = UDim2.new(1,-50,0,16); dl.Position = UDim2.new(0,10,0,20)
                    dl.BackgroundTransparency = 1; dl.Text = cfg.Desc; dl.TextColor3 = Color3.fromRGB(140,140,170); dl.Font = Enum.Font.Gotham; dl.TextSize = fs - 2; dl.TextXAlignment = Enum.TextXAlignment.Left; dl.Parent = frame
                end
                local tgl = Instance.new("TextButton")
                tgl.Size = UDim2.new(0,38,0,20); tgl.Position = UDim2.new(1,-46,0,cfg.Desc and 12 or 5); tgl.BackgroundColor3 = Color3.fromRGB(60,60,80); tgl.Text = ""; tgl.Parent = frame
                local tglC = Instance.new("UICorner"); tglC.CornerRadius = UDim.new(0,10); tglC.Parent = tgl
                local circ = Instance.new("Frame"); circ.Size = UDim2.new(0,14,0,14); circ.Position = UDim2.new(0,3,0,3); circ.BackgroundColor3 = textBright; circ.BorderSizePixel = 0; circ.Parent = tgl
                local circC = Instance.new("UICorner"); circC.CornerRadius = UDim.new(0,7); circC.Parent = circ
                local state = cfg.Default or false
                if state then tgl.BackgroundColor3 = accent; circ.Position = UDim2.new(0,21,0,3) end
                tgl.MouseButton1Click:Connect(function()
                    state = not state; tgl.BackgroundColor3 = state and accent or Color3.fromRGB(60,60,80)
                    circ:TweenPosition(state and UDim2.new(0,21,0,3) or UDim2.new(0,3,0,3), nil, nil, 0.15, true)
                    if cfg.Callback then pcall(cfg.Callback, state) end
                end)
            end
            function api:Slider(cfg)
                local sf = Instance.new("Frame")
                sf.Size = UDim2.new(1,0,0,44); sf.BackgroundColor3 = elementBg; sf.BorderSizePixel = 0; sf.Parent = parent
                local sfC = Instance.new("UICorner"); sfC.CornerRadius = UDim.new(0,5); sfC.Parent = sf
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1,-16,0,18); lbl.Position = UDim2.new(0,8,0,3); lbl.BackgroundTransparency = 1
                lbl.Text = cfg.Title .. ": " .. tostring(cfg.Value.Default)
                lbl.TextColor3 = textBright; lbl.Font = Enum.Font.Gotham; lbl.TextSize = fs; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = sf
                local vl = Instance.new("TextLabel")
                vl.Size = UDim2.new(0,40,0,18); vl.Position = UDim2.new(1,-44,0,3); vl.BackgroundTransparency = 1; vl.Text = tostring(cfg.Value.Default)
                vl.TextColor3 = accent; vl.Font = Enum.Font.GothamBold; vl.TextSize = fs; vl.TextXAlignment = Enum.TextXAlignment.Right; vl.Parent = sf
                local sbg = Instance.new("Frame")
                sbg.Size = UDim2.new(1,-16,0,5); sbg.Position = UDim2.new(0,8,0,28); sbg.BackgroundColor3 = Color3.fromRGB(60,60,80); sbg.BorderSizePixel = 0; sbg.Parent = sf
                local sbgC = Instance.new("UICorner"); sbgC.CornerRadius = UDim.new(0,3); sbgC.Parent = sbg
                local sfill = Instance.new("Frame")
                local mn, mx, def = cfg.Value.Min or 0, cfg.Value.Max or 100, cfg.Value.Default or 50
                local ratio = mx > mn and (def-mn)/(mx-mn) or 0
                sfill.Size = UDim2.new(ratio,0,1,0); sfill.BackgroundColor3 = accent; sfill.BorderSizePixel = 0; sfill.Parent = sbg
                local sfillC = Instance.new("UICorner"); sfillC.CornerRadius = UDim.new(0,3); sfillC.Parent = sfill
                local val = def; local step = cfg.Step or 1
                                local activeS = nil
                                sbg.MouseButton1Down:Connect(function()
                                    _G.YH._activeSlider = {sbg=sbg, sfill=sfill, vl=vl, mn=mn, mx=mx, cb=cfg.Callback, step=step}
                    local pos = math.clamp((UserInputService:GetMouseLocation().X - sbg.AbsolutePosition.X) / sbg.AbsoluteSize.X, 0, 1)
                    val = math.floor(mn + (mx-mn) * pos); if val % step ~= 0 then val = math.floor(val / step) * step end
                    sfill.Size = UDim2.new(pos,0,1,0); vl.Text = tostring(val)
                    if cfg.Callback then pcall(cfg.Callback, val) end
                end)
                UserInputService.InputChanged:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseMovement and _G.YH._activeSlider then
                                        local d = _G.YH._activeSlider; local pos = math.clamp((UserInputService:GetMouseLocation().X - d.sbg.AbsolutePosition.X) / d.sbg.AbsoluteSize.X, 0, 1)
                                        local v = math.floor(d.mn + (d.mx - d.mn) * pos); if v % d.step ~= 0 then v = math.floor(v / d.step) * d.step end
                                        d.sfill.Size = UDim2.new(pos,0,1,0); d.vl.Text = tostring(v)
                                        if d.cb then pcall(d.cb, v) end
                                    end
                                end)
                                UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then _G.YH._activeSlider = nil end end)
            end
            function api:Dropdown(cfg)
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1,0,0,32); frame.BackgroundColor3 = elementBg; frame.BorderSizePixel = 0; frame.Parent = parent
                local fC = Instance.new("UICorner"); fC.CornerRadius = UDim.new(0,5); fC.Parent = frame
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1,-50,1,0); lbl.Position = UDim2.new(0,10,0,0); lbl.BackgroundTransparency = 1; lbl.Text = cfg.Title
                lbl.TextColor3 = textBright; lbl.Font = Enum.Font.Gotham; lbl.TextSize = fs; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = frame
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0,40,0,22); btn.Position = UDim2.new(1,-46,0,5); btn.BackgroundColor3 = accent; btn.Text = (cfg.Values or {})[cfg.Value or 1] or ""
                btn.TextColor3 = textBright; btn.Font = Enum.Font.GothamBold; btn.TextSize = fs - 2; btn.Parent = frame
                local btnC = Instance.new("UICorner"); btnC.CornerRadius = UDim.new(0,5); btnC.Parent = btn
                local idx = cfg.Value or 1; local vals = cfg.Values or {}
                btn.MouseButton1Click:Connect(function()
                    idx = idx % #vals + 1; btn.Text = vals[idx]
                    if cfg.Callback then pcall(cfg.Callback, vals[idx]) end
                end)
            end
            function api:Colorpicker(cfg)
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1,0,0,32); frame.BackgroundColor3 = elementBg; frame.BorderSizePixel = 0; frame.Parent = parent
                local fC = Instance.new("UICorner"); fC.CornerRadius = UDim.new(0,5); fC.Parent = frame
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1,-44,1,0); lbl.Position = UDim2.new(0,10,0,0); lbl.BackgroundTransparency = 1; lbl.Text = cfg.Title
                lbl.TextColor3 = textBright; lbl.Font = Enum.Font.Gotham; lbl.TextSize = fs; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = frame
                local colorBtn = Instance.new("Frame")
                colorBtn.Size = UDim2.new(0,34,0,22); colorBtn.Position = UDim2.new(1,-40,0,5); colorBtn.BackgroundColor3 = cfg.Default or Color3.fromRGB(0,255,100); colorBtn.BorderSizePixel = 0; colorBtn.Parent = frame
                local cbC = Instance.new("UICorner"); cbC.CornerRadius = UDim.new(0,5); cbC.Parent = colorBtn
                local colors = {Color3.fromRGB(255,50,50), Color3.fromRGB(0,255,100), Color3.fromRGB(0,174,255), Color3.fromRGB(255,200,50), Color3.fromRGB(255,100,255), Color3.fromRGB(255,255,255), Color3.fromRGB(100,255,100)}
                local ci = 1; local color = cfg.Default or colors[1]
                colorBtn.Parent.MouseButton1Click:Connect(function()
                    ci = ci % #colors + 1; color = colors[ci]; colorBtn.BackgroundColor3 = color
                    if cfg.Callback then pcall(cfg.Callback, color) end
                end)
            end
            return api
        end
        for name, page in pairs(tabPages) do
            _G.YH.Tabs[name] = {Section = function(self, cfg) return NativeSection(page, cfg.Title or "") end}
        end
        _G.YH.TabBar = TabBar
        _G.YH.tabPages = tabPages
        _G.YH.fs = fs
        _G.YH.elementBg = elementBg
        _G.YH.textBright = textBright
        _G.YH.textMuted = textMuted
        _G.YH.accent = accent
    end

-- ============== LOAD FEATURE MODULES ==============
local base = "https://raw.githubusercontent.com/NazarNoYami/yuki-hub/main/features"
local features = {"main", "esp", "aimbot", "visuals", "misc", "hud", "credits"}
for _, name in ipairs(features) do
    local ok, err = pcall(function()
        local src = game:HttpGet(base .. "/" .. name .. ".lua")
        loadstring(src)()
    end)
    if not ok then
        warn("Yuki Hub: Failed to load " .. name .. " - " .. tostring(err))
    end
end

-- ============== HUD CREATION ==============
local function CreateHUD()
    if _G.YH.hudGui and _G.YH.hudGui.sg and _G.YH.hudGui.sg.Parent then
        pcall(function() _G.YH.hudGui.sg:Destroy() end)
    end
    local sg = Instance.new("ScreenGui"); sg.Name = "YukiHubHUD"; sg.Parent = CoreGui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 180, 0, 80); frame.Position = UDim2.new(1, -190, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25); frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0; frame.Parent = sg
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = frame
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(50, 50, 70); stroke.Thickness = 1; stroke.Parent = frame
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 2); layout.Parent = frame
    local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 6); pad.PaddingLeft = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 6); pad.Parent = frame

    local fpsLbl = Instance.new("TextLabel")
    fpsLbl.Size = UDim2.new(1, 0, 0, 18); fpsLbl.BackgroundTransparency = 1; fpsLbl.Text = "FPS: 0"
    fpsLbl.TextColor3 = Color3.fromRGB(100, 255, 100); fpsLbl.Font = Enum.Font.SourceSansSemibold; fpsLbl.TextSize = 15
    fpsLbl.TextXAlignment = Enum.TextXAlignment.Left; fpsLbl.Parent = frame

    local pingLbl = Instance.new("TextLabel")
    pingLbl.Size = UDim2.new(1, 0, 0, 18); pingLbl.BackgroundTransparency = 1; pingLbl.Text = "Ping: 0ms"
    pingLbl.TextColor3 = Color3.fromRGB(100, 200, 255); pingLbl.Font = Enum.Font.SourceSansSemibold; pingLbl.TextSize = 15
    pingLbl.TextXAlignment = Enum.TextXAlignment.Left; pingLbl.Parent = frame

    local killerLbl = Instance.new("TextLabel")
    killerLbl.Size = UDim2.new(1, 0, 0, 18); killerLbl.BackgroundTransparency = 1; killerLbl.Text = "Killer: --"
    killerLbl.TextColor3 = Color3.fromRGB(255, 100, 100); killerLbl.Font = Enum.Font.SourceSansSemibold; killerLbl.TextSize = 15
    killerLbl.TextXAlignment = Enum.TextXAlignment.Left; killerLbl.Parent = frame

    _G.YH.hudGui = {sg = sg, frame = frame, fpsLbl = fpsLbl, pingLbl = pingLbl, killerLbl = killerLbl}
end

-- ============== MAIN LOOP ==============
RunService.RenderStepped:Connect(function(dt)
    local YH = _G.YH

    -- Bright Mode
    if YH.brightOn then
        local b = YH.brightLevel * 2; YH.Lighting.Ambient = Color3.fromRGB(255,255,255); YH.Lighting.Brightness = b
        YH.Lighting.ClockTime = 12; YH.Lighting.FogEnd = 100000; YH.Lighting.GlobalShadows = false
        YH.Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        YH.Lighting.ColorShift_Top = Color3.fromRGB(255,255,255); YH.Lighting.ColorShift_Bottom = Color3.fromRGB(255,255,255)
    end

    -- Custom FOV
    if YH.fovOn then YH.Camera.FieldOfView = YH.fovVal end

    -- Fog & Sky
    if YH.fogOn then YH.Lighting.FogStart = YH.fogS; YH.Lighting.FogEnd = YH.fogE end
    if YH.skyOn then YH.Lighting.Brightness = YH.skyB / 10; YH.Lighting.ExposureCompensation = YH.skyE / 10 end

    -- Speedhack
    if YH.spdOn and YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then
        YH.LocalPlayer.Character.Humanoid.WalkSpeed = YH.spdVal
    end

    -- Noclip
    if YH.noclipOn and YH.LocalPlayer.Character then
        for _, part in pairs(YH.LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    -- Sprint
    if YH.sprintOn and YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then
        local shift = YH.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or YH.UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        YH.LocalPlayer.Character.Humanoid.WalkSpeed = shift and (16 * YH.sprintBoost) or 16
    end

    -- HUD
    if YH.hudOn then
        if not YH.hudGui then CreateHUD() end
        YH.hudFrames = YH.hudFrames + 1; YH.hudTime = YH.hudTime + dt
        if YH.hudTime >= 1 then YH.hudFpsVal = math.floor(YH.hudFrames / YH.hudTime); YH.hudFrames = 0; YH.hudTime = 0 end
        if YH.hudFPS then YH.hudGui.fpsLbl.Text = "FPS: " .. tostring(YH.hudFpsVal); YH.hudGui.fpsLbl.Visible = true else YH.hudGui.fpsLbl.Visible = false end
        if YH.hudPing then local ping = math.floor(YH.LocalPlayer:GetNetworkPing() * 1000); YH.hudGui.pingLbl.Text = "Ping: " .. tostring(ping) .. "ms"; YH.hudGui.pingLbl.Visible = true else YH.hudGui.pingLbl.Visible = false end
        if YH.hudKiller then
            local killerName = "--"
            for _, plr in pairs(YH.Players:GetPlayers()) do
                if plr ~= YH.LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                    local team = plr.Team
                    if team and (team.Name:lower():find("maniac") or team.Name:lower():find("killer")) then killerName = plr.Name; break end
                end
            end
            YH.hudGui.killerLbl.Text = "Killer: " .. killerName; YH.hudGui.killerLbl.Visible = true
        else YH.hudGui.killerLbl.Visible = false end
        local vc = 0; if YH.hudGui.fpsLbl.Visible then vc = vc + 1 end; if YH.hudGui.pingLbl.Visible then vc = vc + 1 end; if YH.hudGui.killerLbl.Visible then vc = vc + 1 end
        YH.hudGui.frame.Size = UDim2.new(0, 180, 0, 8 + vc * 22)
    else
        if YH.hudGui then pcall(function() YH.hudGui.sg:Destroy() end); YH.hudGui = nil end
    end
end)

-- Flashlight (Heartbeat)
RunService.Heartbeat:Connect(function()
    local YH = _G.YH
    if YH.flOn then
        if not YH.flObj then YH.flObj = Instance.new("SpotLight"); YH.flObj.Brightness = 2; YH.flObj.Range = 60; YH.flObj.Angle = 90; YH.flObj.Face = Enum.NormalId.Front; YH.flObj.Parent = YH.Camera end
        YH.flObj.Enabled = true
    elseif YH.flObj then YH.flObj.Enabled = false end
end)