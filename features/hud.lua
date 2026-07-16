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