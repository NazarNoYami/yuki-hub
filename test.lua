-- Yuki Hub v5.0 - MINIMAL TEST
-- Cuma 1 tab + 1 toggle buat test WindUI

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Yuki Hub v5.0 - TEST",
    Folder = "YukiHubTest",
    Icon = "solar:home-2-bold-duotone",
    NewElements = true,
    HideSearchBar = false,
    Topbar = { Height = 44, ButtonsType = "Default" },
})

Window:SetAccentColor(Color3.fromRGB(0, 120, 255))

local Tab = Window:Tab({
    Title = "Test",
    Icon = "solar:home-2-bold-duotone",
    IconColor = Color3.fromHex("#83889E"),
    Border = true,
})

Tab:Section({ Title = "Test Section" })
Tab:Toggle({ Title = "Test Toggle", Callback = function(s) print("Toggle:", s) end })
Tab:Space()
Tab:Button({ Title = "Test Button", Callback = function() print("Button clicked") end })

print("Yuki Hub TEST loaded successfully!")