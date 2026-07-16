-- Aimbot Tab
local YH = _G.YH
local T = YH.Tabs.Aimbot

-- Basic Aimbot
local BA = T:Section({ Title = "Basic Aimbot" })
YH.aimOn = false; YH.aimSmooth = 1; YH.aimFOV = 90
BA:Toggle({ Title = "Basic Aimbot", Callback = function(s) YH.aimOn = s end })
BA:Space()
BA:Slider({ Title = "Smoothness", Width = 200, Value = { Min=1, Max=10, Default=1 }, Step = 1, Callback = function(v) YH.aimSmooth = v end })
BA:Space()
BA:Slider({ Title = "FOV", Width = 200, Value = { Min=10, Max=360, Default=90 }, Step = 1, Callback = function(v) YH.aimFOV = v end })

-- Projectile Aimbot
local PA = T:Section({ Title = "Projectile Aimbot" })
YH.projOn = false; YH.projV = 150; YH.projG = 196.2; YH.projTarget = nil; YH.projLead = true; YH.projLeadFac = 1
local prevPos = {}; local tVel = {}
local function GetTargetPos(t) if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then return t.Character.HumanoidRootPart.Position end; return nil end
local function GetTargetVel(t)
    local pos = GetTargetPos(t); if not pos then return Vector3.new() end
    local pr = prevPos[t]; prevPos[t] = pos
    if pr then local vel = (pos-pr)/0.1; tVel[t] = tVel[t] and (tVel[t]*0.7+vel*0.3) or vel end
    return tVel[t] or Vector3.new()
end
local function CalcAngle(orig, trg, vel, grav)
    local dx=trg.X-orig.X; local dz=trg.Z-orig.Z; local dy=trg.Y-orig.Y; local d=math.sqrt(dx*dx+dz*dz)
    if d<1 then return nil end; local vSq=vel*vel; local g=grav or 196.2
    local a=(g*d*d)/(2*vSq); local b=-d; local c=a+dy; local disc=b*b-4*a*c
    if disc<0 then return nil end; local sd=math.sqrt(disc)
    local ang=math.atan((-b+sd)/(2*a)); if ang<0 then ang=math.atan((-b-sd)/(2*a)) end
    if ang<0 then return nil end; return ang
end
local function GetAimPoint(orig, trg, vel, grav)
    local aimT = trg
    if YH.projLead then
        local est = (trg-orig).Magnitude / (vel*0.707)
        if est>0 then local pred = GetTargetPos(YH.projTarget) + GetTargetVel(YH.projTarget) * est * YH.projLeadFac; if pred then aimT = pred end end
    end
    local ang = CalcAngle(orig, aimT, vel, grav); if not ang then return nil end
    local dx=aimT.X-orig.X; local dz=aimT.Z-orig.Z; local d=math.sqrt(dx*dx+dz*dz); local ho=math.tan(ang)*d
    return aimT + Vector3.new(0, ho, 0)
end

PA:Toggle({ Title = "Projectile Aimbot", Desc = "For arcing weapons", Callback = function(s) YH.projOn = s end })
PA:Space()
PA:Slider({ Title = "Projectile Velocity", Width = 200, Value = { Min=30, Max=500, Default=150 }, Step = 5, Callback = function(v) YH.projV = v end })
PA:Space()
PA:Slider({ Title = "Gravity", Width = 200, Value = { Min=50, Max=500, Default=196.2 }, Step = 1, Callback = function(v) YH.projG = v end })
PA:Space()
PA:Toggle({ Title = "Lead Prediction", Callback = function(s) YH.projLead = s end })
PA:Space()
PA:Slider({ Title = "Lead Factor", Width = 200, Value = { Min=0.5, Max=3, Default=1 }, Step = 0.1, Callback = function(v) YH.projLeadFac = v end })
PA:Space()
PA:Button({ Title = "Lock Target", Color = YH.C.Blue, Callback = function()
    local closest; local cd = 360
    for _, p in pairs(YH.Players:GetPlayers()) do
        if p ~= YH.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local pos, on = YH.Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if on then local d = (Vector2.new(pos.X,pos.Y)-Vector2.new(YH.Mouse.X,YH.Mouse.Y)).Magnitude; if d < cd then cd = d; closest = p end end
        end
    end
    YH.projTarget = closest
end })
PA:Space()
PA:Button({ Title = "Unlock Target", Color = YH.C.Red, Callback = function() YH.projTarget = nil end })

-- Projectile aimbot loop
YH.RunService.RenderStepped:Connect(function()
    if YH.projOn then
        if not YH.LocalPlayer.Character or not YH.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local target = YH.projTarget or (function()
            local c; local cd = 360
            for _, p in pairs(YH.Players:GetPlayers()) do
                if p ~= YH.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    local pos, on = YH.Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                    if on then local d = (Vector2.new(pos.X,pos.Y)-Vector2.new(YH.Mouse.X,YH.Mouse.Y)).Magnitude; if d < cd then cd = d; c = p end end
                end
            end; return c
        end)()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
            local origin = YH.LocalPlayer.Character.HumanoidRootPart.Position
            local tPos = target.Character.HumanoidRootPart.Position
            local aim = GetAimPoint(origin, tPos, YH.projV, YH.projG)
            if aim then
                local pos, on = YH.Camera:WorldToViewportPoint(aim)
                if on then
                    local t = Vector2.new(pos.X,pos.Y); local cur = Vector2.new(YH.Mouse.X,YH.Mouse.Y)
                    local s = t:Lerp(cur, 1/(YH.aimSmooth or 1)); mousemoverel(s.X-cur.X, s.Y-cur.Y)
                end
            end
        end
    end
end)