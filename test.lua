-- Yuki Hub v5.0 - TEST 2 (tanpa Section, tanpa SetAccentColor)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Yuki Hub v5.0 - TEST",
    Folder = "YukiHubTest",
    Icon = "solar:home-2-bold-duotone",
    NewElements = true,
    HideSearchBar = false,
    Topbar = { Height = 44, ButtonsType = "Default" },
})

local Tab = Window:Tab({
    Title = "Test",
    Icon = "solar:home-2-bold-duotone",
    IconColor = Color3.fromHex("#83889E"),
    Border = true,
})

Tab:Toggle({ Title = "Test Toggle", Callback = function(s) print("Toggle:", s) end })
Tab:Space()
Tab:Button({ Title = "Test Button", Callback = function() print("Button clicked") end })
Tab:Space()
Tab:Slider({ Title = "Test Slider", Width = 200, Value = { Min = 0, Max = 100, Default = 50 }, Step = 1, Callback = function(v) print("Slider:", v) end })
Tab:Space()
Tab:Dropdown({ Title = "Test Dropdown", Values = { "A", "B", "C" }, Value = 1, Callback = function(s) print("Dropdown:", s) end })
Tab:Space()
Tab:Colorpicker({ Title = "Test Color", Default = Color3.fromRGB(0, 255, 0), Callback = function(c) print("Color:", c) end })

print("Yuki Hub TEST 2 loaded!")