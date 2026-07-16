--[[
  Yuki Hub v3.0 - Fluent UI
  Modern, responsive, library-based
  Load via: loadstring(game:HttpGet("https://raw.githubusercontent.com/NazarNoYami/yuki-hub/main/main.lua"))()
--]]

-- Load Fluent UI library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/save_manager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/interface_manager.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Window
local Window = Fluent:CreateWindow({
    Title = "Yuki Hub v3.0",
    SubTitle = "by Tuan",
    TabWidth = 140,
    Size = UDim2.fromOffset(520, 420),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Aimbot = Window:AddTab({ Title = "Aimbot", Icon = "crosshair" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings" }),
    Credits = Window:AddTab({ Title = "Credits", Icon = "info" })
}

-- ============== MAIN TAB ==============
local SectionGame = Tabs.Main:AddSection({ Title = "Game Options" })

SectionGame:AddButton({ Title = "Rejoin Server", Callback = function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end})

SectionGame:AddButton({ Title = "Server Hop", Callback = function()
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
end})

local SectionMove = Tabs.Main:AddSection({ Title = "Movement" })

local wsToggle = SectionMove:AddToggle({ Title = "Walkspeed", Default = false, Callback = function(state)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = state and 50 or 16
    end
end})

SectionMove:AddSlider({ Title = "Walkspeed Value", Default = 50, Min = 16, Max = 250, Rounding = 1, Callback = function(value)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
end})

SectionMove:AddDropdown({ Title = "Jump Power", Values = { "50", "75", "100", "150", "200" }, Default = 1, Callback = function(selected)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = tonumber(selected)
    end
end})

-- ============== ESP TAB ==============
local SectionESP = Tabs.ESP:AddSection({ Title = "Visuals" })

local ESPObjs = {}
local ESPOn = false

SectionESP:AddToggle({ Title = "ESP Box", Default = false, Callback = function(state)
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
end})

SectionESP:AddColorPicker({ Title = "ESP Color", Default = Color3.fromRGB(255, 50, 50), Callback = function(color)
    for _, o in pairs(ESPObjs) do o.Box.Color = color end
end})

-- ============== AIMBOT TAB ==============
local SectionAim = Tabs.Aimbot:AddSection({ Title = "Aimbot Settings" })

local aimEnabled = false
local aimSmooth = 1
local aimFOV = 90

SectionAim:AddToggle({ Title = "Aimbot", Default = false, Callback = function(s) aimEnabled = s end})
SectionAim:AddSlider({ Title = "Smoothness", Default = 1, Min = 1, Max = 10, Rounding = 1, Callback = function(v) aimSmooth = v end})
SectionAim:AddSlider({ Title = "FOV", Default = 90, Min = 10, Max = 360, Rounding = 1, Callback = function(v) aimFOV = v end})

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
local SectionMisc = Tabs.Misc:AddSection({ Title = "Utilities" })

SectionMisc:AddButton({ Title = "Reset Character", Callback = function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
    end
end})

SectionMisc:AddButton({ Title = "Anti AFK", Callback = function()
    LocalPlayer.Idled:Connect(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.1)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
end})

SectionMisc:AddSlider({ Title = "FPS Cap", Default = 60, Min = 15, Max = 360, Rounding = 1, Callback = function(v) setfpscap(v) end})

SectionMisc:AddButton({ Title = "Infinite Yield", Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end})

-- ============== CREDITS TAB ==============
local SectionCredits = Tabs.Credits:AddSection({ Title = "Info" })
SectionCredits:AddParagraph({ Title = "Yuki Hub v3.0", Content = "Made for Tuan\nFluent UI Library\nDelta Executor\nResponsive & Modern" })
SectionCredits:AddColorPicker({ Title = "Accent Color", Default = Color3.fromRGB(0, 174, 255), Callback = function(c) Window:SetAccentColor(c) end})

-- Save/Load system
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:SetFolder("YukiHub")
InterfaceManager:SetFolder("YukiHub")
SaveManager:BuildConfigSection(Tabs.Credits)
InterfaceManager:BuildInterfaceSection(Tabs.Credits)

-- Init
Window:SelectTab(1)
Fluent:Notify({ Title = "Yuki Hub", Content = "Loaded successfully!", Duration = 3 })