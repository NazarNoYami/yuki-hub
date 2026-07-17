local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

if _G.YH and _G.YH.Cleanup then
    pcall(_G.YH.Cleanup)
end

for _, child in ipairs(CoreGui:GetChildren()) do
    if child.Name == "YukiHub" or child.Name == "YukiHubHUD" then child:Destroy() end
end

local connections, drawings, instances, restorers = {}, {}, {}, {}
local YH = {
    Players = Players,
    LocalPlayer = LocalPlayer,
    RunService = RunService,
    UserInputService = UserInputService,
    VirtualInputManager = VirtualInputManager,
    HttpService = HttpService,
    Lighting = Lighting,
    CoreGui = CoreGui,
    Mouse = LocalPlayer:GetMouse(),
    C = {Blue = Color3.fromRGB(90, 140, 255), Red = Color3.fromRGB(255, 90, 105)},
    fovVal = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70,
    brightLevel = 1,
    fogS = 0,
    fogE = 1000,
    walkSpeed = 32,
    sprintMultiplier = 1.25,
    jumpPower = 50,
    chLen = 10,
    chW = 2,
}

function YH.GetCamera()
    return workspace.CurrentCamera
end

function YH.GetMap()
    return workspace:FindFirstChild("Map") or workspace
end

function YH.Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

function YH.TrackDrawing(drawing)
    table.insert(drawings, drawing)
    return drawing
end

function YH.TrackInstance(instance)
    table.insert(instances, instance)
    return instance
end

function YH.OnCleanup(callback)
    table.insert(restorers, callback)
end

function YH.Cleanup()
    for i = #restorers, 1, -1 do pcall(restorers[i]) end
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    for _, drawing in ipairs(drawings) do pcall(function() drawing:Remove() end) end
    for _, instance in ipairs(instances) do pcall(function() instance:Destroy() end) end
    for _, child in ipairs(CoreGui:GetChildren()) do
        if child.Name == "YukiHub" or child.Name == "YukiHubHUD" then pcall(function() child:Destroy() end) end
    end
end

_G.YH = YH

local WINDUI_COMMIT = "7b1d561cf658da1f2f49e700cf52963e7bdcb23a"
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/" .. WINDUI_COMMIT .. "/dist/main.lua"))()
YH.Window = WindUI:CreateWindow({
    Title = "Yuki Hub v6",
    Folder = "YukiHub",
    Icon = "solar:home-2-bold-duotone",
    NewElements = true,
    HideSearchBar = true,
    Topbar = {Height = 42, ButtonsType = "Default"},
})

local function tab(title, icon)
    return YH.Window:Tab({Title = title, Icon = icon, IconColor = Color3.fromHex("#8EA8FF"), Border = true})
end

YH.Tabs = {
    Main = tab("Main", "solar:home-2-bold-duotone"),
    ESP = tab("ESP", "solar:eye-bold-duotone"),
    Aimbot = tab("Combat", "solar:target-bold-duotone"),
    Visuals = tab("Visual", "solar:palette-bold-duotone"),
    Misc = tab("Utility", "solar:settings-bold-duotone"),
    HUD = tab("HUD", "solar:chart-bold-duotone"),
    Credits = tab("Info", "solar:info-circle-bold-duotone"),
}
