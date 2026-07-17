local YH = _G.YH
local T = YH.Tabs.Aimbot

YH.aimOn = false
YH.aimSmooth = 4
YH.aimFOV = 120
YH.projOn = false
YH.projV = 150
YH.projG = 196.2
YH.projLead = true
YH.projLeadFac = 1
YH.projTarget = nil

local function rootOf(player)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and humanoid and humanoid.Health > 0 then return root end
end

local function closestPlayer(radius)
    local camera = YH.GetCamera()
    if not camera then return nil end
    local mouse = Vector2.new(YH.Mouse.X, YH.Mouse.Y)
    local closest, distance = nil, radius
    for _, player in ipairs(YH.Players:GetPlayers()) do
        if player ~= YH.LocalPlayer then
            local root = rootOf(player)
            if root then
                local point, visible = camera:WorldToViewportPoint(root.Position)
                if visible and point.Z > 0 then
                    local current = (Vector2.new(point.X, point.Y) - mouse).Magnitude
                    if current < distance then closest, distance = player, current end
                end
            end
        end
    end
    return closest
end

local previous = setmetatable({}, {__mode = "k"})
local velocity = setmetatable({}, {__mode = "k"})
local function targetVelocity(player, position, dt)
    local old = previous[player]
    previous[player] = position
    if old and dt > 0 then
        local measured = (position - old) / dt
        velocity[player] = velocity[player] and velocity[player]:Lerp(measured, 0.3) or measured
    end
    return velocity[player] or Vector3.new()
end

local function projectilePoint(origin, player, dt)
    local root = rootOf(player)
    if not root or YH.projV <= 0 then return nil end
    local target = root.Position
    if YH.projLead then
        local travelTime = (target - origin).Magnitude / YH.projV
        target = target + targetVelocity(player, target, dt) * travelTime * YH.projLeadFac
    end
    local horizontal = Vector3.new(target.X - origin.X, 0, target.Z - origin.Z)
    local distance = horizontal.Magnitude
    if distance < 1 then return target end
    local speedSquared = YH.projV * YH.projV
    local height = target.Y - origin.Y
    local discriminant = speedSquared * speedSquared - YH.projG * (YH.projG * distance * distance + 2 * height * speedSquared)
    if discriminant < 0 then return nil end
    local angle = math.atan((speedSquared - math.sqrt(discriminant)) / (YH.projG * distance))
    return target + Vector3.new(0, math.tan(angle) * distance, 0)
end

local basic = T:Section({Title = "Aim Assist"})
basic:Toggle({Title = "Enable", Desc = "Nearest visible player inside FOV", Callback = function(value) YH.aimOn = value end})
basic:Space()
basic:Slider({Title = "FOV Radius", Width = 200, Value = {Min = 30, Max = 360, Default = 120}, Step = 5, Callback = function(value) YH.aimFOV = value end})
basic:Space()
basic:Slider({Title = "Smoothness", Width = 200, Value = {Min = 1, Max = 12, Default = 4}, Step = 1, Callback = function(value) YH.aimSmooth = value end})

local projectile = T:Section({Title = "Projectile"})
projectile:Toggle({Title = "Ballistic Aim", Callback = function(value) YH.projOn = value end})
projectile:Space()
projectile:Slider({Title = "Velocity", Width = 200, Value = {Min = 30, Max = 500, Default = 150}, Step = 5, Callback = function(value) YH.projV = value end})
projectile:Space()
projectile:Slider({Title = "Gravity", Width = 200, Value = {Min = 50, Max = 500, Default = 196}, Step = 1, Callback = function(value) YH.projG = value end})
projectile:Space()
projectile:Toggle({Title = "Movement Prediction", Default = true, Callback = function(value) YH.projLead = value end})
projectile:Space()
projectile:Slider({Title = "Lead Factor", Width = 200, Value = {Min = 0.5, Max = 2, Default = 1}, Step = 0.1, Callback = function(value) YH.projLeadFac = value end})
projectile:Space()
projectile:Button({Title = "Lock Nearest", Callback = function() YH.projTarget = closestPlayer(YH.aimFOV) end})
projectile:Space()
projectile:Button({Title = "Clear Lock", Color = YH.C.Red, Callback = function() YH.projTarget = nil end})

YH.Connect(YH.RunService.RenderStepped, function(dt)
    if not YH.aimOn and not YH.projOn then return end
    if type(mousemoverel) ~= "function" then return end
    local camera = YH.GetCamera()
    local character = YH.LocalPlayer.Character
    local ownRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not camera or not ownRoot then return end

    local target = rootOf(YH.projTarget) and YH.projTarget or closestPlayer(YH.aimFOV)
    local targetRoot = rootOf(target)
    if not targetRoot then return end
    local worldPoint = targetRoot.Position
    if YH.projOn then
        worldPoint = projectilePoint(ownRoot.Position, target, dt)
        if not worldPoint then return end
    end
    local point, visible = camera:WorldToViewportPoint(worldPoint)
    if not visible or point.Z <= 0 then return end
    local current = Vector2.new(YH.Mouse.X, YH.Mouse.Y)
    local delta = (Vector2.new(point.X, point.Y) - current) / math.max(YH.aimSmooth, 1)
    mousemoverel(delta.X, delta.Y)
end)
