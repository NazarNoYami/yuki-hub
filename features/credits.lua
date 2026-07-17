-- Credits Tab
local YH = _G.YH
local T = YH.Tabs.Credits
local S = T:Section({ Title = "Yuki Hub v6" })
S:Button({ Title = "Clean modular build", Desc = "Delta-oriented | Pinned dependencies | Rerun safe", Callback = function() end })
S:Space()
S:Button({ Title = "Unload Hub", Color = YH.C.Red, Callback = function() YH.Cleanup(); _G.YH = nil end })
