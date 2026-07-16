local CG = game:GetService("CoreGui")
local PG = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
local RS = game:GetService("RunService")

local out = {"=== MINIGAME SCANNER ==="}
local function log(t)
    table.insert(out, tostring(t))
    print(t)
end

log("Waiting 3s for GUI to load...")
task.wait(3)

log("\n--- CURRENT GUI STRUCTURE ---")
for _, gui in pairs({CG, PG}) do
    if not gui then continue end
    for _, sg in pairs(gui:GetChildren()) do
        if not sg:IsA("ScreenGui") then continue end
        log("\n[SCREEN GUI] " .. sg.Name .. " enabled=" .. tostring(sg.Enabled))
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
            log(string.format("  %-25s cls=%-12s rot=%-8s vis=%-6s pos=%-16s size=%s",
                v.Name, v.ClassName, rotStr, visStr, posStr, szStr))
        end
    end
end

log("\n=== LIVE MONITOR: watching for rotation changes ===")
log("Trigger a skill check in-game, then check the output below.\n")

-- Track rotation changes
local lastRot = {}
local found = {}
local monitorCount = 0

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
                    if diff > 0.5 and diff < 180 and not found[key] then
                        found[key] = true
                        monitorCount = monitorCount + 1
                        local msg = string.format("[ROTATING #%d] %s | rot=%.1f | cls=%s | sg=%s",
                            monitorCount, v.Name, rot, v.ClassName, sg.Name)
                        log(msg)
                    end
                end
                lastRot[key] = rot
            end
        end
    end
end)

-- Save to file after 15s
task.delay(15, function()
    local ok, err = pcall(function()
        writefile("yuki_scanner_result.txt", table.concat(out, "\n"))
    end)
    if ok then
        log("\n=== SAVED to 'yuki_scanner_result.txt' ===")
    else
        log("\n=== writefile failed: " .. tostring(err) .. " ===")
        log("Copy output above manually from console (F9).")
    end
end)
