local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if _G.YukiButtonDetectorCleanup then pcall(_G.YukiButtonDetectorCleanup) end
local old = CoreGui:FindFirstChild("YukiButtonDetector")
if old then old:Destroy() end

local screen = Instance.new("ScreenGui")
screen.Name = "YukiButtonDetector"
screen.ResetOnSpawn = false
screen.DisplayOrder = 999999
screen.Parent = CoreGui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 252, 0, 188)
panel.Position = UDim2.new(0, 14, 0.5, -94)
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
title.Text = "GUI Button Detector"
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
status.Size = UDim2.new(1, -20, 0, 34)
status.Position = UDim2.new(0, 10, 0, 36)
status.BackgroundColor3 = Color3.fromRGB(24, 28, 41)
status.BorderSizePixel = 0
status.Font = Enum.Font.SourceSans
status.TextSize = 13
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(170, 182, 215)
status.Text = "No button recorded"
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

local record = makeButton("Record Next Game Click", 76, Color3.fromRGB(70, 105, 205))
local notify = makeButton("Notify: ON", 112, Color3.fromRGB(45, 135, 105))
local auto = makeButton("Auto Click: OFF", 148, Color3.fromRGB(64, 69, 89))

local recording = false
local notifyOn = true
local autoOn = false
local target
local targetRoot
local targetPath
local relativeX, relativeY = 0.5, 0.5
local wasVisible = false
local hasDisappeared = false
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
    local toastGui = Instance.new("TextLabel")
    toastGui.AnchorPoint = Vector2.new(0.5, 0)
    toastGui.Position = UDim2.new(0.5, 0, 0, 16)
    toastGui.Size = UDim2.new(0, 270, 0, 38)
    toastGui.BackgroundColor3 = Color3.fromRGB(18, 22, 33)
    toastGui.BackgroundTransparency = 0.08
    toastGui.BorderSizePixel = 0
    toastGui.Font = Enum.Font.SourceSansSemibold
    toastGui.TextSize = 14
    toastGui.TextColor3 = Color3.fromRGB(220, 230, 255)
    toastGui.Text = text
    toastGui.Parent = screen
    Instance.new("UICorner", toastGui).CornerRadius = UDim.new(0, 8)
    task.delay(2.5, function() if toastGui.Parent then toastGui:Destroy() end end)
end

local function visible(gui)
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
    for _, name in ipairs(path or {}) do
        current = current and current:FindFirstChild(name)
    end
    return current
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
        local aa = a.object.AbsoluteSize.X * a.object.AbsoluteSize.Y
        local ba = b.object.AbsoluteSize.X * b.object.AbsoluteSize.Y
        return aa < ba
    end)
    return objects
end

record.MouseButton1Click:Connect(function()
    recording = true
    record.Text = "Click the game button now..."
    status.Text = "Waiting for one click outside this detector"
end)

notify.MouseButton1Click:Connect(function()
    notifyOn = not notifyOn
    notify.Text = "Notify: " .. (notifyOn and "ON" or "OFF")
    notify.BackgroundColor3 = notifyOn and Color3.fromRGB(45, 135, 105) or Color3.fromRGB(64, 69, 89)
end)

auto.MouseButton1Click:Connect(function()
    autoOn = not autoOn
    auto.Text = "Auto Click: " .. (autoOn and "ON" or "OFF")
    auto.BackgroundColor3 = autoOn and Color3.fromRGB(185, 105, 65) or Color3.fromRGB(64, 69, 89)
end)

connect(UserInputService.InputBegan, function(input)
    if not recording then return end
    local isPointer = input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
    if not isPointer then return end
    local point = input.UserInputType == Enum.UserInputType.Touch and input.Position or UserInputService:GetMouseLocation()
    local candidates = objectsAt(point.X, point.Y)
    local picked = candidates[1]
    if not picked then status.Text = "No game GUI found there"; return end

    target = picked.object
    targetRoot = picked.root
    targetPath = pathFrom(targetRoot, target)
    local position, size = target.AbsolutePosition, target.AbsoluteSize
    relativeX = math.clamp((point.X - position.X) / math.max(size.X, 1), 0, 1)
    relativeY = math.clamp((point.Y - position.Y) / math.max(size.Y, 1), 0, 1)
    recording = false
    wasVisible = visible(target)
    hasDisappeared = not wasVisible
    record.Text = "Record Next Game Click"
    status.Text = "Recorded: " .. target.Name .. "\nWaiting for it to disappear"
    toast("Recorded button: " .. target.Name)
end)

connect(RunService.Heartbeat, function()
    if not targetPath then return end
    if not target or not target.Parent then target = resolve(targetRoot, targetPath) end
    local isVisible = visible(target)
    if not isVisible then
        hasDisappeared = true
        if wasVisible then status.Text = "Recorded: " .. targetPath[#targetPath] .. "\nWaiting for it to appear" end
    elseif not wasVisible and hasDisappeared then
        local name = targetPath[#targetPath]
        status.Text = "Detected: " .. name .. " appeared"
        if notifyOn then toast(name .. " appeared") end
        if autoOn then
            local position, size = target.AbsolutePosition, target.AbsoluteSize
            local x, y = position.X + size.X * relativeX, position.Y + size.Y * relativeY
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
                task.wait(0.04)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
            end)
        end
    end
    wasVisible = isVisible
end)

close.MouseButton1Click:Connect(function()
    cleanup()
end)
