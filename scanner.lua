local CG=game:GetService("CoreGui")local PG=game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")local RS=game:GetService("RunService")local UIS=game:GetService("UserInputService")

local logs={"=== MINIGAME SCANNER ==="}local running=false local lastRot={}local con=nil

local sg=Instance.new("ScreenGui")sg.Name="YukiScanner"pcall(function()sg.ResetOnSpawn=false end)sg.Parent=CG

local bg=Instance.new("Frame")bg.Size=UDim2.new(0,520,0,420)bg.Position=UDim2.new(0.5,-260,0.5,-210)bg.BackgroundColor3=Color3.fromRGB(15,15,25)bg.BackgroundTransparency=0.08 bg.BorderSizePixel=0 bg.Active=true bg.Draggable=true bg.Parent=sg
Instance.new("UICorner",bg).CornerRadius=UDim.new(0,8)
local st=Instance.new("UIStroke",bg)st.Color=Color3.fromRGB(50,50,70)st.Thickness=1

local title=Instance.new("TextLabel")title.Size=UDim2.new(1,-30,0,32)title.Position=UDim2.new(0,10,0,0)title.BackgroundTransparency=1 title.Text="Yuki Scanner — idle"title.TextColor3=Color3.fromRGB(200,200,255)title.Font=Enum.Font.SourceSansSemibold title.TextSize=18 title.TextXAlignment=Enum.TextXAlignment.Left title.Parent=bg

local closeBtn=Instance.new("TextButton")closeBtn.Size=UDim2.new(0,26,0,26)closeBtn.Position=UDim2.new(1,-30,0,3)closeBtn.BackgroundColor3=Color3.fromRGB(180,40,40)closeBtn.Text="X"closeBtn.TextColor3=Color3.new(1,1,1)closeBtn.Font=Enum.Font.SourceSansBold closeBtn.TextSize=16 closeBtn.BorderSizePixel=0 closeBtn.Parent=bg
Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,6)
closeBtn.MouseButton1Click:Connect(function()sg:Destroy()end)

local logBox=Instance.new("ScrollingFrame")logBox.Size=UDim2.new(1,-20,1,-80)logBox.Position=UDim2.new(0,10,0,35)logBox.BackgroundColor3=Color3.fromRGB(0,0,0)logBox.BackgroundTransparency=0.4 logBox.BorderSizePixel=0 logBox.ScrollBarThickness=6 logBox.Parent=bg
Instance.new("UICorner",logBox).CornerRadius=UDim.new(0,4)
local ul=Instance.new("UIListLayout",logBox)ul.SortOrder=Enum.SortOrder.LayoutOrder ul.Padding=UDim.new(0,2)

local btnFrame=Instance.new("Frame")btnFrame.Size=UDim2.new(1,-20,0,35)btnFrame.Position=UDim2.new(0,10,1,-40)btnFrame.BackgroundTransparency=1 btnFrame.Parent=bg

local function makeBtn(text,x,col)
    local b=Instance.new("TextButton")b.Size=UDim2.new(x,0,1,0)b.BackgroundColor3=col b.Text=text b.TextColor3=Color3.new(1,1,1)b.Font=Enum.Font.SourceSansSemibold b.TextSize=16 b.BorderSizePixel=0 b.Parent=btnFrame
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)return b
end

local startBtn=makeBtn("Start Monitor",0.5,Color3.fromRGB(0,130,50))
startBtn.Position=UDim2.new(0,0,0,0)
local copyBtn=makeBtn("Copy Logs",0.5,Color3.fromRGB(50,50,130))
copyBtn.Position=UDim2.new(0.5,4,0,0)

local function scrollBottom()
    task.spawn(function()task.wait()logBox.CanvasPosition=Vector2.new(0,math.huge)end)
end

local function addLog(txt,col)
    local tc=col or Color3.fromRGB(200,200,200)
    local l=Instance.new("TextLabel")l.Size=UDim2.new(1,-10,0,16)l.BackgroundTransparency=1 l.Text=tostring(txt)l.TextColor3=tc l.TextXAlignment=Enum.TextXAlignment.Left l.Font=Enum.Font.SourceSans l.TextSize=13 l.TextWrapped=true l.RichText=true l.Parent=logBox
    table.insert(logs,tostring(txt))
    scrollBottom()
end

local function writeLogFile()
    local ok,err=pcall(function()writefile("yuki_scanner_"..tostring(math.floor(tick()))..".txt",table.concat(logs,"\n"))end)
    if ok then addLog("Saved to file!",Color3.fromRGB(100,255,100))
    else addLog("writefile failed: "..tostring(err),Color3.fromRGB(255,100,100))addLog("Use Copy Logs button.",Color3.fromRGB(255,200,100))end
end

startBtn.MouseButton1Click:Connect(function()
    running=not running
    if running then
        startBtn.Text="Stop"
        startBtn.BackgroundColor3=Color3.fromRGB(180,40,40)
        title.Text="Yuki Scanner — RUNNING"
        addLog("--- Monitor started ---",Color3.fromRGB(100,255,255))
        if con then con:Disconnect()end
        con=RS.Heartbeat:Connect(function()
            for _,gui in pairs({CG,PG})do
                if not gui then continue end
                for _,sg in pairs(gui:GetChildren())do
                    if not sg:IsA("ScreenGui")or not sg.Enabled then continue end
                    for _,v in pairs(sg:GetDescendants())do
                        if not v:IsA("GuiObject")then continue end
                        local ok,rot=pcall(function()return v.Rotation end)
                        if not ok then continue end
                        local key=v:GetFullName()
                        local prev=lastRot[key]
                        if prev and prev~=rot then
                            local diff=math.abs(rot-prev)
                            if diff>0.5 and diff<180 then
                                addLog("[ROT] "..v.Name.." rot="..string.format("%.1f",rot).." ("..sg.Name..")",Color3.fromRGB(255,255,100))
                            end
                        end
                        lastRot[key]=rot
                    end
                end
            end
        end)
    else
        startBtn.Text="Start Monitor"
        startBtn.BackgroundColor3=Color3.fromRGB(0,130,50)
        title.Text="Yuki Scanner — stopped"
        addLog("--- Monitor stopped ---",Color3.fromRGB(255,200,100))
        if con then con:Disconnect()con=nil end
        writeLogFile()
    end
end)

copyBtn.MouseButton1Click:Connect(function()
    local ok,err=pcall(function()setclipboard(table.concat(logs,"\n"))end)
    if ok then addLog("Copied to clipboard!",Color3.fromRGB(100,255,100))
    else addLog("setclipboard failed: "..tostring(err),Color3.fromRGB(255,100,100))end
end)

UIS.InputBegan:Connect(function(i)if i.KeyCode==Enum.KeyCode.Escape and sg then sg:Destroy()end end)

addLog("Click Start, play normally, then Stop.",Color3.fromRGB(150,200,255))
addLog("ESC to close. Auto-saves on Stop.",Color3.fromRGB(150,200,255))
