--[[
  Yuki Hub v5.0 - Minimal Test
  WindUI - stripped down for compatibility
--]]

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Window
local Window = WindUI:CreateWindow({
    Title = "Yuki Hub v5.0",
    Folder = "YukiHub",
    Icon = "solar:home-2-bold-duotone",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Open Yuki Hub",
        CornerRadius = UDim.new(1,0),
        Enabled = true,
        Draggable = true,
        Scale = 0.5,
    },
    Topbar = { Height = 44, ButtonsType = "Mac" },
})

Window:Tag({ Title = "v5.0", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })

-- Colors
local Grey = Color3.fromHex("#83889E")
local Blue = Color3.fromHex("#257AF7")
local Green = Color3.fromHex("#10C550")
local Red = Color3.fromHex("#EF4F1D")
local Purple = Color3.fromHex("#7775F2")
local Yellow = Color3.fromHex("#ECA201")

-- ============== MAIN TAB ==============
local MainTab = Window:Tab({ Title = "Main", Icon = "solar:home-2-bold", IconColor = Grey, Border = true })
local GameSect = MainTab:Section({ Title = "Game Options" })
GameSect:Button({ Title = "Rejoin Server", Callback = function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end})
GameSect:Space()
GameSect:Button({ Title = "Server Hop", Callback = function()
    local function gs(c)
        local u = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100"
        if c then u = u.."&cursor="..c end
        return HttpService:JSONDecode(game:HttpGet(u))
    end
    local s = gs()
    if s and s.data then
        for _, v in pairs(s.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, v.id, LocalPlayer)
                return
            end
        end
    end
end})

local MoveSect = MainTab:Section({ Title = "Movement" })
MoveSect:Toggle({ Title = "Walkspeed", Callback = function(s)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = s and 50 or 16
    end
end})
MoveSect:Space()
MoveSect:Slider({ Title = "Walkspeed Value", Width = 200, Value = { Min=16, Max=250, Default=50 }, Step = 1, Callback = function(v)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end})
MoveSect:Space()
MoveSect:Dropdown({ Title = "Jump Power", Values = {"50","75","100","150","200"}, Value = 1, Callback = function(s)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = tonumber(s)
    end
end})

-- ============== ESP TAB ==============
local ESPTab = Window:Tab({ Title = "ESP", Icon = "solar:eye-bold", IconColor = Green, Border = true })
local ESPVis = ESPTab:Section({ Title = "ESP Options" })
ESPVis:Toggle({ Title = "ESP Box", Callback = function(s)
    if s then
        for _, p in pairs(Players:GetPlayers()) do if p~=LocalPlayer then
            local box=Drawing.new("Square"); box.Thickness=2; box.Color=Color3.fromRGB(255,50,50); box.Filled=false; box.Visible=false
            local nl=Drawing.new("Text"); nl.Center=true; nl.Size=14; nl.Outline=true; nl.Color=Color3.fromRGB(255,255,255); nl.Visible=false
            ESPObj[p]={Box=box,Name=nl}
        end end
        RunService.RenderStepped:Connect(function()
            if not _G.ESPOn then return end
            for plr,o in pairs(ESPObj) do
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local root=plr.Character.HumanoidRootPart; local pos,on=workspace.CurrentCamera:WorldToViewportPoint(root.Position)
                    if on then local sz=Vector2.new(2000/pos.Z,3000/pos.Z); o.Box.Size=sz; o.Box.Position=Vector2.new(pos.X-sz.X/2,pos.Y-sz.Y/2); o.Box.Visible=true; o.Name.Position=Vector2.new(pos.X,pos.Y-sz.Y/2-16); o.Name.Text=plr.Name; o.Name.Visible=true
                    else o.Box.Visible=false; o.Name.Visible=false end
                else o.Box.Visible=false; o.Name.Visible=false end end end)
    else for _,o in pairs(ESPObj) do o.Box.Visible=false; o.Name.Visible=false end end
end})

-- ============== AIMBOT TAB ==============
local AimTab = Window:Tab({ Title = "Aimbot", Icon = "solar:crosshair-bold", IconColor = Red, Border = true })
local BasicAim = AimTab:Section({ Title = "Basic Aimbot" })
BasicAim:Toggle({ Title = "Aimbot", Callback = function(s) _G.aimOn = s end})
BasicAim:Space()
BasicAim:Slider({ Title = "Smoothness", Width = 200, Value = { Min=1, Max=10, Default=1 }, Step = 1, Callback = function(v) _G.aimSmooth = v end})
BasicAim:Space()
BasicAim:Slider({ Title = "FOV", Width = 200, Value = { Min=10, Max=360, Default=90 }, Step = 1, Callback = function(v) _G.aimFOV = v end})

-- ============== MISC TAB ==============
local MiscTab = Window:Tab({ Title = "Misc", Icon = "solar:settings-bold", IconColor = Purple, Border = true })
local MiscSect = MiscTab:Section({ Title = "Utilities" })
MiscSect:Button({ Title = "Reset Character", Callback = function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
    end
end})
MiscSect:Space()
MiscSect:Slider({ Title = "FPS Cap", Width = 200, Value = { Min=15, Max=360, Default=60 }, Step = 1, Callback = function(v) setfpscap(v) end})
MiscSect:Space()
MiscSect:Button({ Title = "Infinite Yield", Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end})

-- ============== CREDITS TAB ==============
local CreditTab = Window:Tab({ Title = "Credits", Icon = "solar:info-square-bold", IconColor = Grey, IconShape = "Square", Border = true })
local CreditSect = CreditTab:Section({ Title = "Info" })
CreditSect:Button({ Title = "Yuki Hub v5.0", Desc = "Made for Tuan | WindUI", Callback = function() end })

-- Aimbot loop
local Mouse = LocalPlayer:GetMouse()
_G.ESPObj = {}; _G.ESPOn = false; _G.aimOn = false; _G.aimSmooth = 1; _G.aimFOV = 90

RunService.RenderStepped:Connect(function()
    if _G.aimOn then
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local closest = nil; local cd = _G.aimFOV
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local pos, on = workspace.CurrentCamera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if on then
                    local d = (Vector2.new(pos.X,pos.Y)-Vector2.new(Mouse.X,Mouse.Y)).Magnitude
                    if d < cd then cd = d; closest = p end
                end
            end
        end
        if closest and closest.Character then
            local pos = workspace.CurrentCamera:WorldToViewportPoint(closest.Character.HumanoidRootPart.Position)
            local t = Vector2.new(pos.X,pos.Y); local cur = Vector2.new(Mouse.X,Mouse.Y)
            local s = t:Lerp(cur, 1/_G.aimSmooth); mousemoverel(s.X-cur.X, s.Y-cur.Y)
        end
    end
end)