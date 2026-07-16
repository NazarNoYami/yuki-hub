local CG = game:GetService("CoreGui")
local PG = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
local RS = game:GetService("RunService")

print("=== MINIGAME SCANNER ===")
print("Watch for new GUIs...")

-- Track rotation changes to find spinning needles
local lastRot = {}

RS.Heartbeat:Connect(function()
    for _, gui in pairs({CG, PG}) do
        if not gui then continue end
        for _, sg in pairs(gui:GetChildren()) do
            if not sg:IsA("ScreenGui") or not sg.Enabled then continue end
            for _, v in pairs(sg:GetDescendants()) do
                if not v:IsA("GuiObject") then continue end
                local ok, rot = pcall(function() return v.Rotation end)
                if not ok then continue end
                local key = v:GetFullName()
                local prev = lastRot[key]
                if prev and prev ~= rot then
                    local diff = math.abs(rot - prev)
                    if diff > 0.1 and diff < 180 then
                        print(string.format("[ROTATING] %s | rot=%.1f | prev=%.1f | delta=%.1f | cls=%s",
                            key, rot, prev, diff, v.ClassName))
                    end
                end
                lastRot[key] = rot
            end
        end
    end
end)

-- Print all existing GUIs on start
task.wait(1)
print("\n--- CURRENT GUI STRUCTURE ---")
for _, gui in pairs({CG, PG}) do
    if not gui then continue end
    for _, sg in pairs(gui:GetChildren()) do
        if not sg:IsA("ScreenGui") or not sg.Enabled then continue end
        print("\n[SCREEN GUI] " .. sg.Name)
        for _, v in pairs(sg:GetDescendants()) do
            if not v:IsA("GuiObject") then continue end
            local ok, rot = pcall(function() return v.Rotation end)
            local rotStr = ok and string.format("%.1f", rot) or "N/A"
            local ok2, vis = pcall(function() return v.Visible end)
            local visStr = ok2 and tostring(vis) or "?"
            local ok3, pos = pcall(function() return v.AbsolutePosition end)
            local posStr = ok3 and string.format("(%.0f,%.0f)", pos.X, pos.Y) or "?"
            local ok4, sz = pcall(function() return v.AbsoluteSize end)
            local szStr = ok4 and string.format("%.0fx%.0f", sz.X, sz.Y) or "?"
            print(string.format("  %-25s cls=%-12s rot=%-8s vis=%-6s pos=%-16s size=%s",
                v.Name, v.ClassName, rotStr, visStr, posStr, szStr))
        end
    end
end)
print("\n=== SCANNER ACTIVE - watch for rotation changes ===")
