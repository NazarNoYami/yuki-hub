local YH = _G.YH
local T = YH.Tabs.HUD
local section = T:Section({Title = "Status Overlay"})
local enabled, showFPS, showPing, showKiller = false, true, true, true
local gui

local function createLabel(parent, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function createHUD()
    local screen = YH.TrackInstance(Instance.new("ScreenGui"))
    screen.Name = "YukiHubHUD"
    screen.ResetOnSpawn = false
    screen.Parent = YH.CoreGui
    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.Position = UDim2.new(1, -12, 0, 12)
    frame.Size = UDim2.new(0, 164, 0, 74)
    frame.BackgroundColor3 = Color3.fromRGB(16, 19, 29)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = screen
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(85, 105, 165)
    stroke.Transparency = 0.35
    local padding = Instance.new("UIPadding", frame)
    padding.PaddingTop = UDim.new(0, 7); padding.PaddingLeft = UDim.new(0, 9)
    local layout = Instance.new("UIListLayout", frame)
    layout.Padding = UDim.new(0, 2)
    gui = {
        screen = screen,
        frame = frame,
        fps = createLabel(frame, Color3.fromRGB(120, 255, 160)),
        ping = createLabel(frame, Color3.fromRGB(125, 190, 255)),
        killer = createLabel(frame, Color3.fromRGB(255, 120, 135)),
    }
end

local function destroyHUD()
    if gui then pcall(function() gui.screen:Destroy() end); gui = nil end
end

section:Toggle({Title = "Enable HUD", Callback = function(value) enabled = value; if not value then destroyHUD() end end})
section:Space()
section:Toggle({Title = "FPS", Default = true, Callback = function(value) showFPS = value end})
section:Space()
section:Toggle({Title = "Ping", Default = true, Callback = function(value) showPing = value end})
section:Space()
section:Toggle({Title = "Killer", Default = true, Callback = function(value) showKiller = value end})

YH.OnCleanup(destroyHUD)
local elapsed, frames, fps = 0, 0, 0
YH.Connect(YH.RunService.RenderStepped, function(dt)
    elapsed = elapsed + dt; frames = frames + 1
    if elapsed >= 0.5 then fps = math.floor(frames / elapsed + 0.5); elapsed = 0; frames = 0 end
    if not enabled then return end
    if not gui then createHUD() end
    local visible = 0
    gui.fps.Visible = showFPS
    if showFPS then gui.fps.Text = "FPS  " .. fps; visible = visible + 1 end
    gui.ping.Visible = showPing
    if showPing then gui.ping.Text = "PING  " .. math.floor(YH.LocalPlayer:GetNetworkPing() * 1000) .. " ms"; visible = visible + 1 end
    gui.killer.Visible = showKiller
    if showKiller then
        local name = "--"
        for _, player in ipairs(YH.Players:GetPlayers()) do
            local teamName = player.Team and player.Team.Name:lower() or ""
            if teamName:find("maniac") or teamName:find("killer") then name = player.Name; break end
        end
        gui.killer.Text = "KILLER  " .. name
        visible = visible + 1
    end
    gui.frame.Size = UDim2.new(0, 164, 0, math.max(30, 12 + visible * 20))
end)
