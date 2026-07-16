--[[
  Yuki Hub v5.0 - Loader
  Loads WindUI + feature modules
--]]

local base = "https://raw.githubusercontent.com/NazarNoYami/yuki-hub/main"

-- Load WindUI
local WindUI = loadstring(game:HttpGet(base .. "/features/_windui.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera
local Map = Workspace:FindFirstChild("Map") or Workspace

-- Shared state
_G.YH = {
    WindUI = WindUI,
    Players = Players, RunService = RunService, UserInputService = UserInputService,
    VirtualInputManager = VirtualInputManager, HttpService = HttpService,
    Lighting = Lighting, Workspace = Workspace,
    LocalPlayer = LocalPlayer, Mouse = Mouse, Camera = Camera, Map = Map,
    Window = nil, Tabs = {},
}

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "Yuki Hub v5.0",
    Folder = "YukiHub",
    Icon = "solar:home-2-bold-duotone",
    NewElements = true, HideSearchBar = false,
    OpenButton = { Title = "Open Yuki Hub", CornerRadius = UDim.new(1,0), Enabled = true, Draggable = true, Scale = 0.5 },
    Topbar = { Height = 44, ButtonsType = "Default" },
})

Window:Tag({ Title = "v5.0", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })
Window:SetAccentColor(Color3.fromRGB(0, 120, 255))
_G.YH.Window = Window

-- Colors
local C = {}
C.Blue = Color3.fromHex("#257AF7"); C.Green = Color3.fromHex("#10C550"); C.Red = Color3.fromHex("#EF4F1D")
C.Yellow = Color3.fromHex("#ECA201"); C.Purple = Color3.fromHex("#7775F2"); C.Grey = Color3.fromHex("#83889E")
_G.YH.C = C

-- Create tabs
local Tabs = {}
Tabs.Main = Window:Tab({ Title = "Main", Icon = "solar:home-2-bold", IconColor = C.Grey, Border = true })
Tabs.ESP = Window:Tab({ Title = "ESP", Icon = "solar:eye-bold", IconColor = C.Green, Border = true })
Tabs.Aimbot = Window:Tab({ Title = "Aimbot", Icon = "solar:crosshair-bold", IconColor = C.Red, Border = true })
Tabs.Visuals = Window:Tab({ Title = "Visuals", Icon = "solar:sun-bold", IconColor = C.Yellow, Border = true })
Tabs.Misc = Window:Tab({ Title = "Misc", Icon = "solar:settings-bold", IconColor = C.Purple, Border = true })
Tabs.HUD = Window:Tab({ Title = "HUD", Icon = "solar:chart-bold", IconColor = C.Blue, Border = true })
Tabs.Credits = Window:Tab({ Title = "Credits", Icon = "solar:info-square-bold", IconColor = C.Grey, IconShape = "Square", Border = true })
_G.YH.Tabs = Tabs

-- Load feature modules
local features = {"main", "esp", "aimbot", "visuals", "misc", "hud", "credits"}
for _, name in ipairs(features) do
    local success, err = pcall(function()
        loadstring(game:HttpGet(base .. "/features/" .. name .. ".lua"))()
    end)
    if not success then
        warn("[YukiHub] Failed to load " .. name .. ": " .. tostring(err))
    end
end

-- Aimbot loop
RunService.RenderStepped:Connect(function()
    if _G.YH.aimOn then
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local closest = nil; local cd = _G.YH.aimFOV or 90
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local pos, on = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if on then
                    local d = (Vector2.new(pos.X,pos.Y)-Vector2.new(Mouse.X,Mouse.Y)).Magnitude
                    if d < cd then cd = d; closest = p end
                end
            end
        end
        if closest and closest.Character then
            local pos = Camera:WorldToViewportPoint(closest.Character.HumanoidRootPart.Position)
            local t = Vector2.new(pos.X,pos.Y); local cur = Vector2.new(Mouse.X,Mouse.Y)
            local s = t:Lerp(cur, 1/(_G.YH.aimSmooth or 1)); mousemoverel(s.X-cur.X, s.Y-cur.Y)
        end
    end
end)