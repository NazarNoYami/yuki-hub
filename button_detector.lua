local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local CLICK_INTERVAL = 0.65

if _G.YukiButtonDetectorCleanup then pcall(_G.YukiButtonDetectorCleanup) end
local old = CoreGui:FindFirstChild("YukiButtonDetector")
if old then old:Destroy() end

local screen = Instance.new("ScreenGui")
screen.Name = "YukiButtonDetector"
screen.ResetOnSpawn = false
screen.DisplayOrder = 999999
screen.Parent = CoreGui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 252, 0, 260)
panel.Position = UDim2.new(0, 14, 0.5, -130)
panel.BackgroundColor3 = Color3.fromRGB(15, 18, 27)
panel.BackgroundTransparency = 0.06
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = screen
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(90, 125, 220)
stroke.Transparency = 0.35

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -38, 0, 30)
title.Position = UDim2.new(0, 10, 0, 4)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(235, 240, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Multi Button Detector"
title.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 26, 0, 26)
close.Position = UDim2.new(1, -30, 0, 5)
close.BackgroundColor3 = Color3.fromRGB(42, 47, 63)
close.BorderSizePixel = 0
close.Font = Enum.Font.SourceSansBold
close.TextSize = 14
close.TextColor3 = Color3.fromRGB(255, 130, 140)
close.Text = "X"
close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 42)
status.Position = UDim2.new(0, 10, 0, 36)
status.BackgroundColor3 = Color3.fromRGB(24, 28, 41)
status.BorderSizePixel = 0
status.Font = Enum.Font.SourceSans
status.TextSize = 13
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(170, 182, 215)
status.Text = "0 targets recorded"
status.Parent = panel
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 7)

local function makeButton(text, y, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, y)
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Font = Enum.Font.SourceSansSemibold
    button.TextSize = 14
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = text
    button.Parent = panel
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
    return button
end

local record = makeButton("Add Target: Record Next Click", 84, Color3.fromRGB(70, 105, 205))
local clear = makeButton("Clear All Targets", 118, Color3.fromRGB(115, 65, 80))
local notify = makeButton("Notify On Appear: ON", 152, Color3.fromRGB(45, 135, 105))
local clickAppear = makeButton("Click On Appear: OFF", 186, Color3.fromRGB(64, 69, 89))
local clickVisible = makeButton("Click While Visible: OFF", 220, Color3.fromRGB(64, 69, 89))

local recording = false
local notifyOn = true
local clickAppearOn = false
local clickVisibleOn = false
local targets = {}
local connections = {}

local function cleanup()
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    if screen.Parent then screen:Destroy() end
    _G.YukiButtonDetectorCleanup = nil
end
_G.YukiButtonDetectorCleanup = cleanup

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
end

local function toast(text)
    local label = Instance.new("TextLabel")
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.Position = UDim2.new(0.5, 0, 0, 16)
    label.Size = UDim2.new(0, 280, 0, 38)
    label.BackgroundColor3 = Color3.fromRGB(18, 22, 33)
    label.BackgroundTransparency = 0.08
    label.BorderSizePixel = 0
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(220, 230, 255)
    label.Text = text
    label.Parent = screen
    Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)
    task.delay(2.5, function() if label.Parent then label:Destroy() end end)
end

local function isVisible(gui)
    if not gui or not gui.Parent or not gui:IsA("GuiObject") or not gui.Visible then return false end
    local current = gui.Parent
    while current do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("ScreenGui") and not current.Enabled then return false end
        current = current.Parent
    end
    return gui.AbsoluteSize.X > 0 and gui.AbsoluteSize.Y > 0
end

local function pathFrom(root, object)
    local path = {}
    local current = object
    while current and current ~= root do
        table.insert(path, 1, current.Name)
        current = current.Parent
    end
    return current == root and path or nil
end

local function resolve(root, path)
    local current = root
    for _, name in ipairs(path) do current = current and current:FindFirstChild(name) end
    return current
end

local function pathKey(root, path)
    return (root == CoreGui and "CoreGui/" or "PlayerGui/") .. table.concat(path, "/")
end

local function objectsAt(x, y)
    local objects = {}
    for _, root in ipairs({playerGui, CoreGui}) do
        local ok, found = pcall(function() return root:GetGuiObjectsAtPosition(x, y) end)
        if ok then
            for _, object in ipairs(found) do
                if not object:IsDescendantOf(screen) then table.insert(objects, {object = object, root = root}) end
            end
        end
    end
    table.sort(objects, function(a, b)
        return a.object.AbsoluteSize.X * a.object.AbsoluteSize.Y < b.object.AbsoluteSize.X * b.object.AbsoluteSize.Y
    end)
    return objects
end

local function updateStatus(message)
    status.Text = tostring(#targets) .. " targets recorded" .. (message and ("\n" .. message) or "")
end

local function clickTarget(target)
    local object = target.object
    if not isVisible(object) then return end
    target.lastClick = os.clock()
    local position, size = object.AbsolutePosition, object.AbsoluteSize
    local x = position.X + size.X * target.x
    local y = position.Y + size.Y * target.y
    task.spawn(function()
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.04)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
    end)
end

record.MouseButton1Click:Connect(function()
    recording = true
    record.Text = "Click a game button now..."
    updateStatus("Waiting for a click outside this panel")
end)

clear.MouseButton1Click:Connect(function()
    targets = {}
    recording = false
    record.Text = "Add Target: Record Next Click"
    updateStatus()
end)

notify.MouseButton1Click:Connect(function()
    notifyOn = not notifyOn
    notify.Text = "Notify On Appear: " .. (notifyOn and "ON" or "OFF")
    notify.BackgroundColor3 = notifyOn and Color3.fromRGB(45, 135, 105) or Color3.fromRGB(64, 69, 89)
end)

clickAppear.MouseButton1Click:Connect(function()
    clickAppearOn = not clickAppearOn
    clickAppear.Text = "Click On Appear: " .. (clickAppearOn and "ON" or "OFF")
    clickAppear.BackgroundColor3 = clickAppearOn and Color3.fromRGB(185, 105, 65) or Color3.fromRGB(64, 69, 89)
end)

clickVisible.MouseButton1Click:Connect(function()
    clickVisibleOn = not clickVisibleOn
    clickVisible.Text = "Click While Visible: " .. (clickVisibleOn and "ON" or "OFF")
    clickVisible.BackgroundColor3 = clickVisibleOn and Color3.fromRGB(185, 105, 65) or Color3.fromRGB(64, 69, 89)
end)

connect(UserInputService.InputBegan, function(input)
    if not recording then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local point = input.UserInputType == Enum.UserInputType.Touch and input.Position or UserInputService:GetMouseLocation()
    local picked = objectsAt(point.X, point.Y)[1]
    if not picked then updateStatus("No game GUI found there"); return end

    local path = pathFrom(picked.root, picked.object)
    if not path then return end
    local key = pathKey(picked.root, path)
    local position, size = picked.object.AbsolutePosition, picked.object.AbsoluteSize
    local newTarget = {
        key = key,
        name = picked.object.Name,
        root = picked.root,
        path = path,
        object = picked.object,
        x = math.clamp((point.X - position.X) / math.max(size.X, 1), 0, 1),
        y = math.clamp((point.Y - position.Y) / math.max(size.Y, 1), 0, 1),
        wasVisible = isVisible(picked.object),
        hasDisappeared = false,
        lastClick = 0,
    }
    local replaced = false
    for index, target in ipairs(targets) do
        if target.key == key then targets[index] = newTarget; replaced = true; break end
    end
    if not replaced then table.insert(targets, newTarget) end
    recording = false
    record.Text = "Add Target: Record Next Click"
    updateStatus((replaced and "Updated: " or "Added: ") .. newTarget.name)
    toast((replaced and "Updated " or "Added ") .. newTarget.name)
end)

connect(RunService.Heartbeat, function()
    local now = os.clock()
    for _, target in ipairs(targets) do
        if not target.object or not target.object.Parent then target.object = resolve(target.root, target.path) end
        local visible = isVisible(target.object)
        if not visible then
            target.hasDisappeared = true
        elseif not target.wasVisible and target.hasDisappeared then
            updateStatus(target.name .. " appeared")
            if notifyOn then toast(target.name .. " appeared") end
            if clickAppearOn then clickTarget(target) end
        end
        if visible and clickVisibleOn and now - target.lastClick >= CLICK_INTERVAL then clickTarget(target) end
        target.wasVisible = visible
    end
end)

close.MouseButton1Click:Connect(cleanup)
