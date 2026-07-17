cache = false
std = "lua51"
ignore = {
  "212", -- unused argument (callback params)
  "431", -- unused loop variable (_ in for pairs)
  "432", -- unused loop variable (second _)
  "411", -- undefined variable (YH.* is set at runtime)
}
globals = {
  "_G",
  "game", "workspace",
  "Instance", "Drawing",
  "Color3", "ColorSequence", "Vector2", "Vector3", "UDim2",
  "Enum", "UDim",
  "task", "typeof",
  "loadstring", "mousemoverel", "setfpscap",
  "readfile", "writefile", "firesignal",
}
