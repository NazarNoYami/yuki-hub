--[[
  Yuki Hub v4.0 - WindUI
  Modern, responsive, library-based
--]]

-- Load WindUI library
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Window
local Window = WindUI:CreateWindow({
    Title = "Yuki Hub v4.0",
    Folder = "YukiHub",
    Icon = "solar:home-2-bold-duotone",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Open Yuki Hub",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.5,
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

-- Tag
Window:Tag({
    Title = "v4.0",
    Icon = "github",
    Color = Color3.fromHex("#1c1c1c"),
    Border = true,
})

-- Colors
local Blue = Color3.fromHex("#257AF7")
local Green = Color3.fromHex("#10C550")
local Red = Color3.fromHex("#EF4F1D")
local Yellow = Color3.fromHex("#ECA201")
local Purple = Color3.fromHex("#7775F2")
local Grey = Color3.fromHex("#83889E")

-- ============== MAIN TAB ==============
local MainPage = Window:Page({
    Title = "Main",
    Icon = "solar:home-2-bold-duotone",
})

local GameSection = MainPage:Section({
    Title = "Game Options",
    Side = "Left",
})

GameSection:Button({
    Title = "Rejoin Server",
    Description = "Teleport back to the same server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end,
})

GameSection:Button({
    Title = "Server Hop",
    Description = "Find a new server",
    Callback = function()
        local function getServers(cursor)
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"
            if cursor then url = url .. "&cursor=" .. cursor end
            local res = game:HttpGet(url)
            return HttpService:JSONDecode(res)
        end
        local servers = getServers()
        if servers and servers.data then
            for _, s in pairs(servers.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    return
                end
            end
        end
    end,
})

local MoveSection = MainPage:Section({
    Title = "Movement",
    Side = "Right",
})

MoveSection:Toggle({
    Title = "Walkspeed",
    Description = "Toggle fast walkspeed",
    Default = false,
    Callback = function(state)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = state and 50 or 16
        end
    end,
})

MoveSection:Slider({
    Title = "Walkspeed Value",
    Description = "Set walkspeed",
    Default = 50,
    Min = 16,
    Max = 250,
    Step = 1,
    Callback = function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end,
})

MoveSection:Dropdown({
    Title = "Jump Power",
    Description = "Set jump height",
    Default = 1,
    Values = {"50", "75", "100", "150", "200"},
    Callback = function(selected)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = tonumber(selected)
        end
    end,
})

-- ============== ESP TAB ==============
local ESPPage = Window:Page({
    Title = "ESP",
    Icon = "solar:eye-bold-duotone",
})

local ESPVis = ESPPage:Section({
    Title = "Visuals",
    Side = "Left",
})

local ESPObjs = {}
local ESPOn = false

ESPVis:Toggle({
    Title = "ESP Box",
    Description = "Show player boxes",
    Default = false,
    Callback = function(state)
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
    end,
})

-- ============== AIMBOT TAB ==============
local AimPage = Window:Page({
    Title = "Aimbot",
    Icon = "solar:crosshair-bold-duotone",
})

local AimSect = AimPage:Section({
    Title = "Aimbot Settings",
    Side = "Left",
})

local aimEnabled = false
local aimSmooth = 1
local aimFOV = 90

AimSect:Toggle({
    Title = "Aimbot",
    Description = "Auto aim at players",
    Default = false,
    Callback = function(s) aimEnabled = s end,
})

AimSect:Slider({
    Title = "Smoothness",
    Default = 1, Min = 1, Max = 10, Step = 1,
    Callback = function(v) aimSmooth = v end,
})

AimSect:Slider({
    Title = "FOV",
    Default = 90, Min = 10, Max = 360, Step = 1,
    Callback = function(v) aimFOV = v end,
})

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

-- ============== MISC TAB ==============
local MiscPage = Window:Page({
    Title = "Misc",
    Icon = "solar:settings-bold-duotone",
})

local MiscSect = MiscPage:Section({
    Title = "Utilities",
    Side = "Left",
})

MiscSect:Button({
    Title = "Reset Character",
    Description = "Kill your character",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Health = 0
        end
    end,
})

MiscSect:Button({
    Title = "Anti AFK",
    Description = "Prevent auto-kick",
    Callback = function()
        LocalPlayer.Idled:Connect(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end)
    end,
})

MiscSect:Slider({
    Title = "FPS Cap",
    Default = 60, Min = 15, Max = 360, Step = 1,
    Callback = function(v) setfpscap(v) end,
})

MiscSect:Button({
    Title = "Infinite Yield",
    Description = "Load admin commands",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end,
})

-- ============== CREDITS TAB ==============
local CreditPage = Window:Page({
    Title = "Credits",
    Icon = "solar:info-square-bold-duotone",
})

local CreditSect = CreditPage:Section({
    Title = "Info",
    Side = "Left",
})

CreditSect:Button({
    Title = "Yuki Hub v4.0",
    Description = "Made for Tuan | WindUI Library | Delta Executor",
    Callback = function() end,
})