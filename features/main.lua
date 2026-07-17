local YH = _G.YH
local T = YH.Tabs.Main

local server = T:Section({Title = "Server"})
server:Button({Title = "Rejoin", Callback = function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, YH.LocalPlayer)
end})
server:Space()
server:Button({Title = "Server Hop", Desc = "Find an available public server", Callback = function()
    local cursor
    repeat
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor then url = url .. "&cursor=" .. YH.HttpService:UrlEncode(cursor) end
        local ok, page = pcall(function() return YH.HttpService:JSONDecode(game:HttpGet(url)) end)
        if not ok or not page then return end
        for _, serverInfo in ipairs(page.data or {}) do
            if serverInfo.playing < serverInfo.maxPlayers and serverInfo.id ~= game.JobId then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, serverInfo.id, YH.LocalPlayer)
                return
            end
        end
        cursor = page.nextPageCursor
    until not cursor
end})

local movement = T:Section({Title = "Movement"})
movement:Toggle({Title = "Speed", Callback = function(value) YH.speedOn = value end})
movement:Space()
movement:Slider({Title = "Walk Speed", Width = 200, Value = {Min = 16, Max = 100, Default = 32}, Step = 1, Callback = function(value) YH.walkSpeed = value end})
movement:Space()
movement:Toggle({Title = "Sprint", Desc = "Hold Shift; uses Walk Speed as base", Callback = function(value) YH.sprintOn = value end})
movement:Space()
movement:Slider({Title = "Sprint Multiplier", Width = 200, Value = {Min = 1, Max = 2, Default = 1.25}, Step = 0.05, Callback = function(value) YH.sprintMultiplier = value end})
movement:Space()
movement:Toggle({Title = "Noclip", Callback = function(value) YH.noclipOn = value end})
movement:Space()
movement:Slider({Title = "Jump Power", Width = 200, Value = {Min = 50, Max = 200, Default = 50}, Step = 5, Callback = function(value) YH.jumpPower = value end})

local collisionState = setmetatable({}, {__mode = "k"})
local lastCharacter
local function restoreCollision()
    for part, canCollide in pairs(collisionState) do
        if part.Parent then part.CanCollide = canCollide end
        collisionState[part] = nil
    end
end

YH.OnCleanup(function()
    restoreCollision()
    local character = YH.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.WalkSpeed = 16; humanoid.JumpPower = 50 end
end)

YH.Connect(YH.RunService.Stepped, function()
    local character = YH.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if character ~= lastCharacter then restoreCollision(); lastCharacter = character end

    local speed = YH.speedOn and YH.walkSpeed or 16
    if YH.sprintOn and (YH.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or YH.UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then
        speed = speed * YH.sprintMultiplier
    end
    humanoid.WalkSpeed = speed
    humanoid.JumpPower = YH.jumpPower

    if YH.noclipOn then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if collisionState[part] == nil then collisionState[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    elseif next(collisionState) then
        restoreCollision()
    end
end)
