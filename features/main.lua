-- Main Tab
local YH = _G.YH
local T = YH.Tabs.Main
local S = T:Section({ Title = "Game Options" })
S:Button({ Title = "Rejoin Server", Callback = function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, YH.LocalPlayer)
end})
S:Space()
S:Button({ Title = "Server Hop", Callback = function()
    local function gs(c)
        local u = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100"
        if c then u = u.."&cursor="..c end
        return YH.HttpService:JSONDecode(game:HttpGet(u))
    end
    local s = gs()
    if s and s.data then
        for _, v in pairs(s.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, v.id, YH.LocalPlayer)
                return
            end
        end
    end
end})
local M = T:Section({ Title = "Movement" })
M:Toggle({ Title = "Walkspeed", Callback = function(s)
    if YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then
        YH.LocalPlayer.Character.Humanoid.WalkSpeed = s and 50 or 16
    end
end})
M:Space()
M:Slider({ Title = "Walkspeed Value", Width = 200, Value = { Min=16, Max=250, Default=50 }, Step = 1, Callback = function(v)
    if YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then YH.LocalPlayer.Character.Humanoid.WalkSpeed = v end
end})
M:Space()
M:Dropdown({ Title = "Jump Power", Values = {"50","75","100","150","200"}, Value = 1, Callback = function(s)
    if YH.LocalPlayer.Character and YH.LocalPlayer.Character:FindFirstChild("Humanoid") then YH.LocalPlayer.Character.Humanoid.JumpPower = tonumber(s) end
end})