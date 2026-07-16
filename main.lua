--[[
  Yuki Hub v5.0 - WindUI Edition
  Essential + Notties + Yuki Hub merged
  Modular structure
  Load this file in your executor.
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

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Shared state
_G.YH = {
    -- Services
    Players = Players,
    RunService = RunService,
    UserInputService = UserInputService,
    TweenService = TweenService,
    VirtualInputManager = VirtualInputManager,
    HttpService = HttpService,
    Lighting = Lighting,
    CoreGui = CoreGui,
    Camera = Camera,
    Map = Map,
    LocalPlayer = LocalPlayer,
    Mouse = Mouse,
    Gravity = Gravity,
    WindUI = WindUI,
    Window = nil,
    Tabs = {},
    -- Color palette
    C = {
        Blue = Color3.fromRGB(0, 120, 255),
        Red = Color3.fromRGB(255, 50, 50),
        Green = Color3.fromRGB(0, 255, 100),
        Yellow = Color3.fromRGB(255, 200, 50),
        Purple = Color3.fromRGB(160, 0, 255),
        White = Color3.fromRGB(255, 255, 255),
        Orange = Color3.fromRGB(255, 150, 50),
    },
    -- Aimbot state
    aimOn = false, aimSmooth = 1, aimFOV = 90,
    projOn = false, projV = 150, projG = 196.2, projTarget = nil, projLead = true, projLeadFac = 1,
    -- ESP state
    espBoxOn = false, espLineOn = false, espLineColor = Color3.fromRGB(0, 255, 100),
    espLineMode = "Single", espLineOrigin = "Character", espLineObjs = {},
    ESPObjs = {}, playerESPOn = false, playerHighlights = {}, playerLabels = {},
    genOn = false, genH = {}, genL = {},
    hookOn = false, hookH = {}, hookL = {},
    palOn = false, palH = {},
    gateOn = false, gateH = {}, gateL = {},
    winOn = false, winL = {},
    projArcOn = false, projArcObj = nil,
    -- Visuals state
    brightOn = false, brightLevel = 1,
    fovOn = false, fovVal = 70, origFOV = Camera.FieldOfView,
    fogOn = false, fogS = 0, fogE = 1000,
    skyOn = false, skyB = 50, skyE = 50,
    -- Misc state
    spdOn = false, spdVal = 32,
    noclipOn = false,
    sprintOn = false, sprintBoost = 1.05, sprinting = false,
    flOn = false, flObj = nil,
    chOn = false, chLen = 10, chW = 2,
    stOn = false, stVal = 100,
    afkConnected = false,
    -- HUD state
    hudOn = false, hudFPS = true, hudPing = true, hudKiller = true,
    hudFrames = 0, hudTime = 0, hudFpsVal = 0, hudGui = nil,
}

-- Create Window
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

-- Create tabs
local tabConfig = {
    { Name = "Main", Icon = "solar:home-2-bold-duotone" },
    { Name = "ESP", Icon = "solar:eye-bold-duotone" },
    { Name = "Aimbot", Icon = "solar:target-bold-duotone" },
    { Name = "Visuals", Icon = "solar:palette-bold-duotone" },
    { Name = "Misc", Icon = "solar:settings-bold-duotone" },
    { Name = "HUD", Icon = "solar:chart-bold-duotone" },
    { Name = "Credits", Icon = "solar:info-circle-bold-duotone" },
}

for _, cfg in ipairs(tabConfig) do
    _G.YH.Tabs[cfg.Name] = Window:Tab({
        Title = cfg.Name,
        Icon = cfg.Icon,
        IconColor = Color3.fromHex("#83889E"),
        Border = true,
    })
end

-- Load feature modules
local base = "https://raw.githubusercontent.com/NazarNoYami/yuki-hub/main/features"
local features = {"main", "esp", "aimbot", "visuals", "misc", "hud", "credits"}
for _, name in ipairs(features) do
    local ok, err = pcall(function()
        loadstring(game:HttpGet(base .. "/" .. name .. ".lua"))()
    end)
    if not ok then
        warn("Yuki Hub: Failed to load " .. name .. " - " .. tostring(err))
    end
end

-- HUD creation
local function CreateHUD()
    if _G.YH.hudGui and _G.YH.hudGui.Parent then
        _G.YH.hudGui:Destroy()
    end
    local sg = Instance.new("ScreenGui")
    sg.Name = "YukiHubHUD"
    sg.Parent = CoreGui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 180, 0, 80)
    frame.Position = UDim2.new(1, -190, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = sg
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(50, 50, 70)
    stroke.Thickness = 1
    stroke.Parent = frame
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = frame
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 6)
    pad.Parent = frame
    local fpsLbl = Instance.new("TextLabel")
    fpsLbl.Size = UDim2.new(1, 0, 0, 18)
    fpsLbl.BackgroundTransparency = 1
    fpsLbl.Text = "FPS: 0"
    fpsLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
    fpsLbl.Font = Enum.Font.SourceSansSemibold
    fpsLbl.TextSize = 15
    fpsLbl.TextXAlignment = Enum.TextXAlignment.Left
    fpsLbl.Parent = frame
    local pingLbl = Instance.new("TextLabel")
    pingLbl.Size = UDim2.new(1, 0, 0, 18)
    pingLbl.BackgroundTransparency = 1
    pingLbl.Text = "Ping: 0ms"
    pingLbl.TextColor3 = Color3.fromRGB(100, 200, 255)
    pingLbl.Font = Enum.Font.SourceSansSemibold
    pingLbl.TextSize = 15
    pingLbl.TextXAlignment = Enum.TextXAlignment.Left
    pingLbl.Parent = frame
    local killerLbl = Instance.new("TextLabel")
    killerLbl.Size = UDim2.new(1, 0, 0, 18)
    killerLbl.BackgroundTransparency = 1
    killerLbl.Text = "Killer: --"
    killerLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
    killerLbl.Font = Enum.Font.SourceSansSemibold
    killerLbl.TextSize = 15
    killerLbl.TextXAlignment = Enum.TextXAlignment.Left
    killerLbl.Parent = frame
    _G.YH.hudGui = {sg = sg, frame = frame, fpsLbl = fpsLbl, pingLbl = pingLbl, killerLbl = killerLbl}
end

-- Main loop
RunService.RenderStepped:Connect(function(dt)
    local YH = _G.YH

    -- Bright Mode
    if YH.brightOn then
        local b = YH.brightLevel * 2
        YH.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        YH.Lighting.Brightness = b
        YH.Lighting.ClockTime = 12
        YH.Lighting.FogEnd = 100000
        YH.Lighting.GlobalShadows = false
        YH.Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        YH.Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
        YH.Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
    end

    -- Custom FOV
    if YH.fovOn then
        YH.Camera.FieldOfView = YH.fovVal
    end

    -- Fog
    if YH.fogOn then
        YH.Lighting.FogStart = YH.fogS
        YH.Lighting.FogEnd = YH.fogE
    end

    -- Skybox
    if YH.skyOn then
        YH.Lighting.Brightness = YH.skyB / 10
        YH.Lighting.ExposureCompensation = YH.skyE / 10
    end

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

    -- Crosshair
    if YH.chOn then
        -- implemented in misc.lua via Drawing
    end

    -- HUD
    if YH.hudOn then
        if not YH.hudGui then CreateHUD() end
        YH.hudFrames = YH.hudFrames + 1
        YH.hudTime = YH.hudTime + dt
        if YH.hudTime >= 1 then
            YH.hudFpsVal = math.floor(YH.hudFrames / YH.hudTime)
            YH.hudFrames = 0
            YH.hudTime = 0
        end
        if YH.hudFPS then
            YH.hudGui.fpsLbl.Text = "FPS: " .. tostring(YH.hudFpsVal)
            YH.hudGui.fpsLbl.Visible = true
        else
            YH.hudGui.fpsLbl.Visible = false
        end
        if YH.hudPing then
            local ping = math.floor(YH.LocalPlayer:GetNetworkPing() * 1000)
            YH.hudGui.pingLbl.Text = "Ping: " .. tostring(ping) .. "ms"
            YH.hudGui.pingLbl.Visible = true
        else
            YH.hudGui.pingLbl.Visible = false
        end
        if YH.hudKiller then
            -- Find killer
            local killerName = "--"
            for _, plr in pairs(YH.Players:GetPlayers()) do
                if plr ~= YH.LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                    local team = plr.Team
                    if team and (team.Name:lower():find("maniac") or team.Name:lower():find("killer")) then
                        killerName = plr.Name
                        break
                    end
                end
            end
            YH.hudGui.killerLbl.Text = "Killer: " .. killerName
            YH.hudGui.killerLbl.Visible = true
        else
            YH.hudGui.killerLbl.Visible = false
        end
        -- Resize frame based on visible labels
        local visibleCount = 0
        if YH.hudGui.fpsLbl.Visible then visibleCount = visibleCount + 1 end
        if YH.hudGui.pingLbl.Visible then visibleCount = visibleCount + 1 end
        if YH.hudGui.killerLbl.Visible then visibleCount = visibleCount + 1 end
        YH.hudGui.frame.Size = UDim2.new(0, 180, 0, 8 + visibleCount * 22)
    else
        if YH.hudGui then
            YH.hudGui.sg:Destroy()
            YH.hudGui = nil
        end
    end
end)

-- Flashlight (Heartbeat)
RunService.Heartbeat:Connect(function()
    local YH = _G.YH
    if YH.flOn then
        if not YH.flObj then
            YH.flObj = Instance.new("SpotLight")
            YH.flObj.Brightness = 2
            YH.flObj.Range = 60
            YH.flObj.Angle = 90
            YH.flObj.Face = Enum.NormalId.Front
            YH.flObj.Parent = YH.Camera
        end
        YH.flObj.Enabled = true
    elseif YH.flObj then
        YH.flObj.Enabled = false
    end
end)