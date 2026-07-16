--[[ Yuki Hub v5.0 - WindUI Edition ]]
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local VirtualInputManager=game:GetService("VirtualInputManager")
local HttpService=game:GetService("HttpService")
local Lighting=game:GetService("Lighting")
local CoreGui=game:GetService("CoreGui")
local Camera=workspace.CurrentCamera
local Map=workspace:FindFirstChild("Map") or workspace
local LP=Players.LocalPlayer
local Mouse=LP:GetMouse()

for _,v in pairs(CoreGui:GetChildren())do if v.Name=="YukiHub"then v:Destroy()end end

local WindUI=loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
local Window=WindUI:CreateWindow({Title="Yuki Hub v5.0",Folder="YukiHub",Icon="solar:home-2-bold-duotone",NewElements=true,HideSearchBar=false,Topbar={Height=44,ButtonsType="Default"}})

local function Tab(t,i)return Window:Tab({Title=t,Icon=i,IconColor=Color3.fromHex("#83889E"),Border=true})end
local T={Main=Tab("Main","solar:home-2-bold-duotone"),ESP=Tab("ESP","solar:eye-bold-duotone"),Aimbot=Tab("Aimbot","solar:target-bold-duotone"),Visuals=Tab("Visuals","solar:palette-bold-duotone"),Misc=Tab("Misc","solar:settings-bold-duotone"),HUD=Tab("HUD","solar:chart-bold-duotone"),Credits=Tab("Credits","solar:info-circle-bold-duotone")}

-- State
local S={
    aimOn=false,aimFOV=90,projOn=false,projV=150,projG=196.2,projTarget=nil,projLead=true,projLeadFac=1,
    espBox=false,espLine=false,espLineCol=Color3.fromRGB(0,255,100),espLineMd="Single",espLineOri="Character",
    pesp=false,gen=false,hook=false,pal=false,gate=false,win=false,
    bright=false,bLv=1,fov=false,fovV=70,fovOrig=Camera.FieldOfView,
    fog=false,fogS=0,fogE=1000,sky=false,skyB=50,skyE=50,
    spd=false,spdV=32,noc=false,spr=false,sprB=1.05,
    fl=false,ch=false,chLen=10,chW=2,st=false,stV=100,afk=false,
    hud=false,hudFPS=true,hudPing=true,hudKiller=true,
}
-- Original lighting values
local LO={Lighting.Ambient,Lighting.Brightness,Lighting.ClockTime,Lighting.FogEnd,Lighting.GlobalShadows,Lighting.OutdoorAmbient,Lighting.ColorShift_Top,Lighting.ColorShift_Bottom,Lighting.FogStart,Lighting.ExposureCompensation}

-- Helpers
local function Closest(fov)
    local c,cd=nil,fov or 1e9
    for _,p in pairs(Players:GetPlayers())do
        if p~=LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart")and p.Character:FindFirstChild("Humanoid")and p.Character.Humanoid.Health>0 then
            local pos,on=Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if on then local d=(Vector2.new(pos.X,pos.Y)-Vector2.new(Mouse.X,Mouse.Y)).Magnitude;if d<cd then cd=d;c=p end end
        end
    end
    return c
end
local function GetPos(t)return t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")and t.Character.HumanoidRootPart.Position end
local function TeamInfo(p)
    local t=p.Team;if not t then return"Other",Color3.fromRGB(255,255,255)end
    local n=t.Name:lower()
    if n:find("maniac")or n:find("killer")then return"Killer",Color3.fromRGB(255,80,80)end
    if n:find("survivor")then return"Survivor",Color3.fromRGB(100,255,100)end
    return"Other",Color3.fromRGB(255,255,255)
end
local function Clr(t)for k in pairs(t)do t[k]=nil end end

-- Projectile
local pPos={},pVel={}
local function GetVel(t)
    local p=GetPos(t);if not p then return Vector3.new()end
    local pr=pPos[t];pPos[t]=p
    if pr then local v=(p-pr)/0.1;pVel[t]=pVel[t]and(pVel[t]*0.7+v*0.3)or v end
    return pVel[t]or Vector3.new()
end
local function Angle(o,t,v,g)
    local dx=t.X-o.X;local dz=t.Z-o.Z;local dy=t.Y-o.Y;local d=math.sqrt(dx*dx+dz*dz)
    if d<1 then return nil end;local v2=v*v;local gv=g or 196.2
    local a=(gv*d*d)/(2*v2);local b=-d;local c=a+dy;local disc=b*b-4*a*c
    if disc<0 then return nil end;local sd=math.sqrt(disc)
    local ang=math.atan((-b+sd)/(2*a));if ang<0 then ang=math.atan((-b-sd)/(2*a))end
    if ang<0 then return nil end;return ang
end
local function AimP(o,t,v,g)
    local at=t
    if S.projLead then
        local e=(t-o).Magnitude/(v*0.707)
        if e>0 then local pr=GetPos(S.projTarget)+GetVel(S.projTarget)*e*S.projLeadFac;if pr then at=pr end end
    end
    local ang=Angle(o,at,v,g);if not ang then return nil end
    local dx=at.X-o.X;local dz=at.Z-o.Z;local d=math.sqrt(dx*dx+dz*dz);local ho=math.tan(ang)*d
    return at+Vector3.new(0,ho,0)
end

-- ESP state
local espBoxD={},espLineD={},espLineC=0
local pHl={},pLb={}
local gH={},gL={},hH={},hL={},pH={},gH2={},gL2={},wL={}
local cTimer=0
local cG={},cH={},cP={},cGt={},cW={}
local function Scan()
    Clr(cG);Clr(cH);Clr(cP);Clr(cGt);Clr(cW)
    for _,o in pairs(Map:GetDescendants())do
        if not o:IsA("Model")and not o:IsA("BasePart")then continue end;local n=o.Name:lower()
        if o:IsA("Model")then
            if n:find("generator")then table.insert(cG,o)
            elseif n:find("hook")then table.insert(cH,o)
            elseif n:find("pallet")then table.insert(cP,o)
            elseif n:find("gate")or n:find("exit")then table.insert(cGt,o)end
        end
        if o:IsA("BasePart")and n:find("window")then table.insert(cW,o)end
    end
end

-- Crosshair lines
local chL={}
for i=1,4 do chL[i]=Drawing.new("Line");chL[i].Thickness=2;chL[i].Color=Color3.fromRGB(0,255,100);chL[i].Transparency=0.8;chL[i].Visible=false end

-- HUD
local hudG=nil
local function MakeHUD()
    if hudG and hudG.sg and hudG.sg.Parent then pcall(function()hudG.sg:Destroy()end)end
    local sg=Instance.new("ScreenGui");sg.Name="YukiHubHUD";sg.Parent=CoreGui
    local f=Instance.new("Frame");f.Size=UDim2.new(0,180,0,80);f.Position=UDim2.new(1,-190,0,10);f.BackgroundColor3=Color3.fromRGB(15,15,25);f.BackgroundTransparency=0.3;f.BorderSizePixel=0;f.Parent=sg
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local st=Instance.new("UIStroke",f);st.Color=Color3.fromRGB(50,50,70);st.Thickness=1
    local ly=Instance.new("UIListLayout",f);ly.Padding=UDim.new(0,2)
    local pd=Instance.new("UIPadding",f);pd.PaddingTop=UDim.new(0,6);pd.PaddingLeft=UDim.new(0,8);pd.PaddingBottom=UDim.new(0,6)
    local function Lbl(c)local l=Instance.new("TextLabel",f);l.Size=UDim2.new(1,0,0,18);l.BackgroundTransparency=1;l.TextColor3=c;l.Font=Enum.Font.SourceSansSemibold;l.TextSize=15;l.TextXAlignment=Enum.TextXAlignment.Left;return l end
    hudG={sg=sg,frame=f,fps=Lbl(Color3.fromRGB(100,255,100)),ping=Lbl(Color3.fromRGB(100,200,255)),killer=Lbl(Color3.fromRGB(255,100,100))}
    hudG.fps.Text="FPS: 0";hudG.ping.Text="Ping: 0ms";hudG.killer.Text="Killer: --"
end

-- ============== UI ==============
-- Main
T.Main:Toggle({Title="Walkspeed",Callback=function(s)if LP.Character and LP.Character:FindFirstChild("Humanoid")then LP.Character.Humanoid.WalkSpeed=s and 50 or 16 end end})
T.Main:Space()
T.Main:Slider({Title="Walkspeed Value",Width=200,Value={Min=16,Max=250,Default=50},Step=1,Callback=function(v)if LP.Character and LP.Character:FindFirstChild("Humanoid")then LP.Character.Humanoid.WalkSpeed=v end end})
T.Main:Space()
T.Main:Dropdown({Title="Jump Power",Values={"50","75","100","150","200"},Value=1,Callback=function(s)if LP.Character and LP.Character:FindFirstChild("Humanoid")then LP.Character.Humanoid.JumpPower=tonumber(s)end end})
T.Main:Space()
T.Main:Button({Title="Rejoin",Callback=function()game:GetService("TeleportService"):Teleport(game.PlaceId,LP)end})
T.Main:Space()
T.Main:Button({Title="Server Hop",Callback=function()
    local function gs(c)local u="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100";if c then u=u.."&cursor="..c end;return HttpService:JSONDecode(game:HttpGet(u))end
    local s=gs();if s and s.data then for _,v in pairs(s.data)do if v.playing<v.maxPlayers and v.id~=game.JobId then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,v.id,LP);return end end end
end})

-- ESP
T.ESP:Toggle({Title="Player ESP",Desc="Highlight + name + distance + status",Callback=function(s)S.pesp=s;if not s then for _,v in pairs(pHl)do pcall(function()v:Destroy()end)end;Clr(pHl);for _,v in pairs(pLb)do pcall(function()v.Parent:Destroy()end)end;Clr(pLb)end end})
T.ESP:Space()
T.ESP:Toggle({Title="ESP Box",Callback=function(s)S.espBox=s;if s then for _,p in pairs(Players:GetPlayers())do if p~=LP then local bx=Drawing.new("Square");bx.Thickness=2;bx.Color=Color3.fromRGB(255,50,50);bx.Filled=false;bx.Visible=false;local nl=Drawing.new("Text");nl.Center=true;nl.Size=14;nl.Outline=true;nl.Color=Color3.fromRGB(255,255,255);nl.Visible=false;espBoxD[p]={Box=bx,Name=nl}end end else for _,o in pairs(espBoxD)do o.Box.Visible=false;o.Name.Visible=false end end end})
T.ESP:Space()
T.ESP:Toggle({Title="ESP Line",Callback=function(s)S.espLine=s;if not s then for _,o in pairs(espLineD)do o.Visible=false end end end})
T.ESP:Space()
T.ESP:Colorpicker({Title="Line Color",Default=S.espLineCol,Callback=function(c)S.espLineCol=c end})
T.ESP:Space()
T.ESP:Dropdown({Title="Line Mode",Values={"Single","All Players"},Value=1,Callback=function(s)S.espLineMd=(s=="All Players")and"All"or"Single"end})
T.ESP:Space()
T.ESP:Dropdown({Title="Line Origin",Values={"Character","Top Screen"},Value=1,Callback=function(s)S.espLineOri=s end})
T.ESP:Space()
T.ESP:Toggle({Title="Projectile Arc",Desc="Trajectory prediction",Callback=function(s)if not s and S.projArcObj then S.projArcObj.Visible=false end end})
T.ESP:Space()
T.ESP:Toggle({Title="Generator ESP",Callback=function(s)S.gen=s;if not s then for _,v in pairs(gH)do pcall(function()v:Destroy()end)end;Clr(gH);for _,v in pairs(gL)do pcall(function()v.Parent:Destroy()end)end;Clr(gL)end end})
T.ESP:Space()
T.ESP:Toggle({Title="Hook ESP",Callback=function(s)S.hook=s;if not s then for _,v in pairs(hH)do pcall(function()v:Destroy()end)end;Clr(hH);for _,v in pairs(hL)do pcall(function()v.Parent:Destroy()end)end;Clr(hL)end end})
T.ESP:Space()
T.ESP:Toggle({Title="Pallet ESP",Callback=function(s)S.pal=s;if not s then for _,v in pairs(pH)do pcall(function()v:Destroy()end)end;Clr(pH)end end})
T.ESP:Space()
T.ESP:Toggle({Title="Gate ESP",Callback=function(s)S.gate=s;if not s then for _,v in pairs(gH2)do pcall(function()v:Destroy()end)end;Clr(gH2);for _,v in pairs(gL2)do pcall(function()v.Parent:Destroy()end)end;Clr(gL2)end end})
T.ESP:Space()
T.ESP:Toggle({Title="Window ESP",Callback=function(s)S.win=s;if not s then for _,v in pairs(wL)do pcall(function()v.Parent:Destroy()end)end;Clr(wL)end end})

-- Aimbot
T.Aimbot:Toggle({Title="Basic Aimbot",Callback=function(s)S.aimOn=s end})
T.Aimbot:Space()
T.Aimbot:Slider({Title="Smoothness",Width=200,Value={Min=1,Max=10,Default=1},Step=1,Callback=function(v)S.aimS=v end})
T.Aimbot:Space()
T.Aimbot:Slider({Title="FOV",Width=200,Value={Min=10,Max=360,Default=90},Step=1,Callback=function(v)S.aimFOV=v end})
T.Aimbot:Space()
T.Aimbot:Toggle({Title="Projectile Aimbot",Desc="For arcing weapons",Callback=function(s)S.projOn=s end})
T.Aimbot:Space()
T.Aimbot:Slider({Title="Proj. Velocity",Width=200,Value={Min=30,Max=500,Default=150},Step=5,Callback=function(v)S.projV=v end})
T.Aimbot:Space()
T.Aimbot:Slider({Title="Gravity",Width=200,Value={Min=50,Max=500,Default=196.2},Step=1,Callback=function(v)S.projG=v end})
T.Aimbot:Space()
T.Aimbot:Toggle({Title="Lead Prediction",Callback=function(s)S.projLead=s end})
T.Aimbot:Space()
T.Aimbot:Slider({Title="Lead Factor",Width=200,Value={Min=0.5,Max=3,Default=1},Step=0.1,Callback=function(v)S.projLeadFac=v end})
T.Aimbot:Space()
T.Aimbot:Button({Title="Lock Target",Color=Color3.fromRGB(0,120,255),Callback=function()S.projTarget=Closest(360)end})
T.Aimbot:Space()
T.Aimbot:Button({Title="Unlock Target",Color=Color3.fromRGB(255,50,50),Callback=function()S.projTarget=nil end})

-- Visuals
T.Visuals:Toggle({Title="Bright Mode",Desc="Full bright",Callback=function(s)S.bright=s;if s then for i=1,8 do LO[i]={Lighting.Ambient,Lighting.Brightness,Lighting.ClockTime,Lighting.FogEnd,Lighting.GlobalShadows,Lighting.OutdoorAmbient,Lighting.ColorShift_Top,Lighting.ColorShift_Bottom}[i]end else Lighting.Ambient=LO[1];Lighting.Brightness=LO[2];Lighting.ClockTime=LO[3];Lighting.FogEnd=LO[4];Lighting.GlobalShadows=LO[5];Lighting.OutdoorAmbient=LO[6];Lighting.ColorShift_Top=LO[7];Lighting.ColorShift_Bottom=LO[8]end end})
T.Visuals:Space()
T.Visuals:Slider({Title="Bright Level",Width=200,Value={Min=0.5,Max=5,Default=1},Step=0.1,Callback=function(v)S.bLv=v end})
T.Visuals:Space()
T.Visuals:Toggle({Title="Custom FOV",Callback=function(s)S.fov=s;Camera.FieldOfView=s and S.fovV or S.fovOrig end})
T.Visuals:Space()
T.Visuals:Slider({Title="FOV Value",Width=200,Value={Min=30,Max=120,Default=70},Step=1,Callback=function(v)S.fovV=v;if S.fov then Camera.FieldOfView=v end end})
T.Visuals:Space()
T.Visuals:Toggle({Title="Custom Fog",Callback=function(s)S.fog=s;if not s then Lighting.FogStart=LO[9];Lighting.FogEnd=LO[4]end end})
T.Visuals:Space()
T.Visuals:Slider({Title="Fog Start",Width=200,Value={Min=0,Max=500,Default=0},Step=1,Callback=function(v)S.fogS=v end})
T.Visuals:Space()
T.Visuals:Slider({Title="Fog End",Width=200,Value={Min=100,Max=2000,Default=1000},Step=10,Callback=function(v)S.fogE=v end})
T.Visuals:Space()
T.Visuals:Toggle({Title="Skybox",Callback=function(s)S.sky=s;if not s then Lighting.Brightness=LO[2];Lighting.ExposureCompensation=LO[10]end end})
T.Visuals:Space()
T.Visuals:Slider({Title="Sky Brightness",Width=200,Value={Min=0,Max=100,Default=50},Step=1,Callback=function(v)S.skyB=v end})
T.Visuals:Space()
T.Visuals:Slider({Title="Exposure",Width=200,Value={Min=0,Max=100,Default=50},Step=1,Callback=function(v)S.skyE=v end})

-- Misc
T.Misc:Toggle({Title="Speedhack",Callback=function(s)S.spd=s end})
T.Misc:Space()
T.Misc:Slider({Title="Speed Value",Width=200,Value={Min=16,Max=100,Default=32},Step=1,Callback=function(v)S.spdV=v end})
T.Misc:Space()
T.Misc:Toggle({Title="Sprint",Desc="Hold Shift",Callback=function(s)S.spr=s end})
T.Misc:Space()
T.Misc:Slider({Title="Sprint Boost",Width=200,Value={Min=1.0,Max=2.0,Default=1.05},Step=0.05,Callback=function(v)S.sprB=v end})
T.Misc:Space()
T.Misc:Toggle({Title="Noclip",Callback=function(s)S.noc=s end})
T.Misc:Space()
T.Misc:Toggle({Title="Custom Crosshair",Callback=function(s)S.ch=s end})
T.Misc:Space()
T.Misc:Slider({Title="CH Length",Width=200,Value={Min=5,Max=30,Default=10},Step=1,Callback=function(v)S.chLen=v end})
T.Misc:Space()
T.Misc:Slider({Title="CH Width",Width=200,Value={Min=1,Max=8,Default=2},Step=1,Callback=function(v)S.chW=v end})
T.Misc:Space()
T.Misc:Toggle({Title="Flashlight",Callback=function(s)S.fl=s end})
T.Misc:Space()
T.Misc:Toggle({Title="Stretched Res",Callback=function(s)S.st=s end})
T.Misc:Space()
T.Misc:Slider({Title="Stretch Amount",Width=200,Value={Min=50,Max=200,Default=100},Step=5,Callback=function(v)S.stV=v end})
T.Misc:Space()
T.Misc:Button({Title="Reset Character",Callback=function()if LP.Character and LP.Character:FindFirstChild("Humanoid")then LP.Character.Humanoid.Health=0 end end})
T.Misc:Space()
T.Misc:Button({Title="Anti AFK",Callback=function()if S.afk then return end;S.afk=true;LP.Idled:Connect(function()VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1);task.wait(0.1);VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)end)end})
T.Misc:Space()
T.Misc:Slider({Title="FPS Cap",Width=200,Value={Min=15,Max=360,Default=60},Step=1,Callback=function(v)setfpscap(v)end})
T.Misc:Space()
T.Misc:Button({Title="Infinite Yield",Callback=function()loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()end})

-- HUD
T.HUD:Toggle({Title="Enable HUD",Desc="FPS, Ping, Killer",Callback=function(s)S.hud=s end})
T.HUD:Space()
T.HUD:Toggle({Title="Show FPS",Default=true,Callback=function(s)S.hudFPS=s end})
T.HUD:Space()
T.HUD:Toggle({Title="Show Ping",Default=true,Callback=function(s)S.hudPing=s end})
T.HUD:Space()
T.HUD:Toggle({Title="Show Killer",Default=true,Callback=function(s)S.hudKiller=s end})

-- Credits
T.Credits:Button({Title="Yuki Hub v5.0",Desc="Made for Tuan | WindUI",Callback=function()end})
T.Credits:Space()
T.Credits:Button({Title="Features:",Desc="ESP, Aimbot, Visuals, Misc, HUD",Callback=function()end})
T.Credits:Space()
T.Credits:Button({Title="Merged from:",Desc="Essential Script + Notties Script",Callback=function()end})

-- ============== SINGLE MAIN LOOP ==============
local hFrames=0;local hTime=0;local hFps=0
local flObj=nil
local hF=nil

RunService.RenderStepped:Connect(function(dt)
    -- BRIGHT MODE
    if S.bright then
        Lighting.Ambient=Color3.fromRGB(255,255,255);Lighting.Brightness=S.bLv*2;Lighting.ClockTime=12
        Lighting.FogEnd=100000;Lighting.GlobalShadows=false;Lighting.OutdoorAmbient=Color3.fromRGB(255,255,255)
        Lighting.ColorShift_Top=Color3.fromRGB(255,255,255);Lighting.ColorShift_Bottom=Color3.fromRGB(255,255,255)
    end
    -- FOV
    if S.fov then Camera.FieldOfView=S.fovV end
    -- FOG
    if S.fog then Lighting.FogStart=S.fogS;Lighting.FogEnd=S.fogE end
    -- SKYBOX (only when Bright Mode is OFF)
    if S.sky and not S.bright then Lighting.Brightness=S.skyB/10;Lighting.ExposureCompensation=S.skyE/10 end

    -- SPEEDHACK
    if S.spd and LP.Character and LP.Character:FindFirstChild("Humanoid")then LP.Character.Humanoid.WalkSpeed=S.spdV end
    -- NOCLIP
    if S.noc and LP.Character then for _,p in pairs(LP.Character:GetDescendants())do if p:IsA("BasePart")then p.CanCollide=false end end end
    -- SPRINT
    if S.spr and LP.Character and LP.Character:FindFirstChild("Humanoid")then
        local sh=UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        LP.Character.Humanoid.WalkSpeed=sh and(16*S.sprB)or 16
    end

    -- CROSSHAIR
    if S.ch then
        local cx=Camera.ViewportSize.X/2;local cy=Camera.ViewportSize.Y/2;local len=S.chLen;local w=S.chW
        for i=1,4 do chL[i].Visible=true;chL[i].Thickness=w end
        chL[1].From=Vector2.new(cx,cy-len);chL[1].To=Vector2.new(cx,cy-2)
        chL[2].From=Vector2.new(cx,cy+2);chL[2].To=Vector2.new(cx,cy+len)
        chL[3].From=Vector2.new(cx-len,cy);chL[3].To=Vector2.new(cx-2,cy)
        chL[4].From=Vector2.new(cx+2,cy);chL[4].To=Vector2.new(cx+len,cy)
    else for i=1,4 do chL[i].Visible=false end end

    -- STRETCHED RES
    if S.st then Camera.ViewportSize=Vector2.new(Camera.ViewportSize.X*(S.stV/100),Camera.ViewportSize.Y)end

    -- ESP BOX
    if S.espBox then
        for plr,o in pairs(espBoxD)do
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")then
                local root=plr.Character.HumanoidRootPart;local pos,on=Camera:WorldToViewportPoint(root.Position)
                if on then local sz=Vector2.new(2000/pos.Z,3000/pos.Z);o.Box.Size=sz;o.Box.Position=Vector2.new(pos.X-sz.X/2,pos.Y-sz.Y/2);o.Box.Visible=true;o.Name.Position=Vector2.new(pos.X,pos.Y-sz.Y/2-16);o.Name.Text=plr.Name;o.Name.Visible=true else o.Box.Visible=false;o.Name.Visible=false end
            else o.Box.Visible=false;o.Name.Visible=false end
        end
    end

    -- ESP LINE
    if S.espLine then
        local mp,msp=nil,nil
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")then mp=LP.Character.HumanoidRootPart.Position;msp,_=Camera:WorldToViewportPoint(mp)end
        local ori;if S.espLineOri=="Top Screen"then ori=Vector2.new(Camera.ViewportSize.X/2,0)elseif msp then ori=Vector2.new(msp.X,msp.Y)else for _,o in pairs(espLineD)do o.Visible=false end;return end
        local targets={}
        if S.espLineMd=="Single"then local t=S.projTarget or Closest(360);if t then table.insert(targets,t)end
        else for _,p in pairs(Players:GetPlayers())do if p~=LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart")and p.Character:FindFirstChild("Humanoid")and p.Character.Humanoid.Health>0 then table.insert(targets,p)end end end
        for i=#targets+1,#espLineD do espLineD[i].Visible=false end
        for i,t in ipairs(targets)do
            if not espLineD[i]then espLineD[i]=Drawing.new("Line");espLineD[i].Thickness=2;espLineD[i].Color=S.espLineCol;espLineD[i].Transparency=0.6 end
            local tp=t.Character and t.Character:FindFirstChild("HumanoidRootPart")and t.Character.HumanoidRootPart.Position
            if tp then local to,_=Camera:WorldToViewportPoint(tp);espLineD[i].From=ori;espLineD[i].To=Vector2.new(to.X,to.Y);espLineD[i].Visible=true;espLineD[i].Color=S.espLineCol else espLineD[i].Visible=false end
        end
    end

    -- PROJECTILE ARC
    if S.projTarget and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")then
        local tp=GetPos(S.projTarget)
        if tp then
            local orig=LP.Character.HumanoidRootPart.Position;local trg=tp;local vel=S.projV;local grav=S.projG
            if not S.projArcObj then S.projArcObj=Drawing.new("Line");S.projArcObj.Thickness=1;S.projArcObj.Color=Color3.fromRGB(255,200,50);S.projArcObj.Transparency=0.3 end
            local ang=Angle(orig,trg,vel,grav)
            if ang then
                local dx=trg.X-orig.X;local dz=trg.Z-orig.Z;local dir=Vector2.new(dx,dz).Unit;local g=grav;local v=vel
                local vx=v*math.cos(ang);local vy=v*math.sin(ang);local pts={};local tt=(2*vy)/g
                for t=0,tt,0.1 do local x=vx*t;local y=vy*t-0.5*g*t*t;local pos=orig+Vector3.new(dir.X*x,y,dir.Y*x);local sp,_=Camera:WorldToViewportPoint(pos);table.insert(pts,Vector2.new(sp.X,sp.Y))end
                if #pts>1 then S.projArcObj.Visible=true;S.projArcObj.Points=pts else S.projArcObj.Visible=false end
            else S.projArcObj.Visible=false end
        end
    end

    -- AIMBOT
    if S.aimOn and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")then
        local c=Closest(S.aimFOV)
        if c and c.Character then local pos=Camera:WorldToViewportPoint(c.Character.HumanoidRootPart.Position);local t=Vector2.new(pos.X,pos.Y);local cur=Vector2.new(Mouse.X,Mouse.Y);local s=t:Lerp(cur,1/(S.aimS or 1));mousemoverel(s.X-cur.X,s.Y-cur.Y)end
    end
    if S.projOn and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")then
        local target=S.projTarget or Closest(360)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")and target.Character:FindFirstChild("Humanoid")and target.Character.Humanoid.Health>0 then
            local origin=LP.Character.HumanoidRootPart.Position;local tPos=target.Character.HumanoidRootPart.Position;local aim=AimP(origin,tPos,S.projV,S.projG)
            if aim then local pos,on=Camera:WorldToViewportPoint(aim);if on then local t=Vector2.new(pos.X,pos.Y);local cur=Vector2.new(Mouse.X,Mouse.Y);local s=t:Lerp(cur,1/(S.aimS or 1));mousemoverel(s.X-cur.X,s.Y-cur.Y)end end
        end
    end

    -- PLAYER ESP
    if S.pesp then
        for _,plr in pairs(Players:GetPlayers())do
            if plr==LP then continue end;local char=plr.Character;if not char then continue end;local head=char:FindFirstChild("Head")or char:FindFirstChild("HumanoidRootPart");if not head then continue end
            local tt,bc=TeamInfo(plr);local hum=char:FindFirstChildOfClass("Humanoid")or char:FindFirstChild("Humanoid")
            local hooked=char:GetAttribute("IsHooked")or char:GetAttribute("Hooked");local knocked=hum and hum.Health<hum.MaxHealth*0.3
            local color=bc;if tt=="Survivor"then if hooked then color=Color3.fromRGB(255,110,80);elseif knocked then color=Color3.fromRGB(255,170,80);elseif hum and hum.Health<hum.MaxHealth then color=Color3.fromRGB(255,255,120);else color=Color3.fromRGB(100,255,100)end end
            if not pHl[plr]then local hl=Instance.new("Highlight");hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;hl.OutlineColor=Color3.new(1,1,1);hl.FillTransparency=0.5;hl.Parent=Camera;pHl[plr]=hl end
            local hl=pHl[plr];hl.Adornee=char;hl.FillColor=color;hl.FillTransparency=0.3;hl.OutlineTransparency=0
            if not pLb[plr]or not pLb[plr].Parent then local bill=Instance.new("BillboardGui");bill.Size=UDim2.new(0,200,0,50);bill.StudsOffset=Vector3.new(0,3,0);bill.AlwaysOnTop=true;bill.Parent=Camera;local txt=Instance.new("TextLabel");txt.Size=UDim2.new(1,0,1,0);txt.BackgroundTransparency=1;txt.Font=Enum.Font.SourceSansSemibold;txt.TextSize=14;txt.TextStrokeTransparency=0.3;txt.TextStrokeColor3=Color3.new(0,0,0);txt.TextXAlignment=Enum.TextXAlignment.Center;txt.Parent=bill;pLb[plr]=txt end
            local txt=pLb[plr];txt.Parent.Adornee=head;local dist=0;if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")then dist=math.floor((head.Position-LP.Character.HumanoidRootPart.Position).Magnitude)end
            local line3=tostring(dist).."m";local line2="";if tt=="Killer"then local sk=plr:GetAttribute("SelectedKiller")or plr:GetAttribute("KillerName");line2=sk and"KILLER: "..tostring(sk)or"KILLER"elseif tt=="Survivor"then if hooked then line2="HOOKED";elseif knocked then line2="HURT"end end
            txt.Text=plr.Name.." | "..line3..(line2~=""and(" | "..line2)or"");txt.TextColor3=color
        end
    end

    -- OBJECT ESP (cached, scan every 2s)
    cTimer=cTimer+dt
    if cTimer>=2 then cTimer=0;Scan()end
    if S.gen then for _,o in pairs(cG)do local at=o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart");if not at then continue end;if not gH[o]then local hl=Instance.new("Highlight");hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;hl.FillTransparency=0.5;hl.OutlineTransparency=0;hl.FillColor=Color3.new(1,1,1);hl.OutlineColor=Color3.new(1,1,1);hl.Parent=Camera;gH[o]=hl;local bill=Instance.new("BillboardGui");bill.Size=UDim2.new(0,150,0,30);bill.StudsOffset=Vector3.new(0,2.5,0);bill.AlwaysOnTop=true;bill.Parent=Camera;local txt=Instance.new("TextLabel");txt.Size=UDim2.new(1,0,1,0);txt.BackgroundTransparency=1;txt.Font=Enum.Font.SourceSansSemibold;txt.TextSize=14;txt.TextStrokeTransparency=0.4;txt.TextStrokeColor3=Color3.new(0,0,0);txt.TextXAlignment=Enum.TextXAlignment.Center;txt.TextColor3=Color3.fromRGB(200,200,255);txt.Text="Generator";txt.Parent=bill;gL[o]=txt end;gH[o].Adornee=o;gL[o].Parent.Adornee=at end end
    if S.hook then for _,o in pairs(cH)do local at=o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart");if not at then continue end;if not hH[o]then local hl=Instance.new("Highlight");hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;hl.FillTransparency=0.6;hl.FillColor=Color3.fromRGB(255,80,80);hl.OutlineColor=Color3.fromRGB(255,0,0);hl.Parent=Camera;hH[o]=hl;local bill=Instance.new("BillboardGui");bill.Size=UDim2.new(0,100,0,30);bill.StudsOffset=Vector3.new(0,2,0);bill.AlwaysOnTop=true;bill.Parent=Camera;local txt=Instance.new("TextLabel");txt.Size=UDim2.new(1,0,1,0);txt.BackgroundTransparency=1;txt.Font=Enum.Font.SourceSansSemibold;txt.TextSize=14;txt.TextStrokeTransparency=0.4;txt.TextStrokeColor3=Color3.new(0,0,0);txt.TextXAlignment=Enum.TextXAlignment.Center;txt.TextColor3=Color3.fromRGB(255,100,100);txt.Text="Hook";txt.Parent=bill;hL[o]=txt end;hH[o].Adornee=o end end
    if S.pal then for _,o in pairs(cP)do local at=o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart");if not at then continue end;if not pH[o]then local hl=Instance.new("Highlight");hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;hl.FillTransparency=0.5;hl.OutlineTransparency=0;hl.FillColor=Color3.fromRGB(255,255,100);hl.OutlineColor=Color3.fromRGB(255,200,0);hl.Parent=Camera;pH[o]=hl end;pH[o].Adornee=o end end
    if S.gate then for _,o in pairs(cGt)do local at=o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart");if not at then continue end;if not gH2[o]then local hl=Instance.new("Highlight");hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;hl.FillTransparency=0.5;hl.OutlineTransparency=0;hl.FillColor=Color3.fromRGB(160,0,255);hl.OutlineColor=Color3.fromRGB(200,120,255);hl.Parent=Camera;gH2[o]=hl;local bill=Instance.new("BillboardGui");bill.Size=UDim2.new(0,100,0,30);bill.StudsOffset=Vector3.new(0,2,0);bill.AlwaysOnTop=true;bill.Parent=Camera;local txt=Instance.new("TextLabel");txt.Size=UDim2.new(1,0,1,0);txt.BackgroundTransparency=1;txt.Font=Enum.Font.SourceSansSemibold;txt.TextSize=14;txt.TextStrokeTransparency=0.4;txt.TextStrokeColor3=Color3.new(0,0,0);txt.TextXAlignment=Enum.TextXAlignment.Center;txt.TextColor3=Color3.fromRGB(200,150,255);txt.Text="Gate";txt.Parent=bill;gL2[o]=txt end;gH2[o].Adornee=at end end
    if S.win then for _,o in pairs(cW)do if not wL[o]then local bill=Instance.new("BillboardGui");bill.Size=UDim2.new(0,80,0,25);bill.StudsOffset=Vector3.new(0,1.5,0);bill.AlwaysOnTop=true;bill.Parent=Camera;local txt=Instance.new("TextLabel");txt.Size=UDim2.new(1,0,1,0);txt.BackgroundTransparency=1;txt.Font=Enum.Font.SourceSansSemibold;txt.TextSize=12;txt.TextStrokeTransparency=0.4;txt.TextStrokeColor3=Color3.new(0,0,0);txt.TextXAlignment=Enum.TextXAlignment.Center;txt.TextColor3=Color3.fromRGB(180,230,255);txt.Text="Window";txt.Parent=bill;wL[o]=txt end;wL[o].Parent.Adornee=o end end

    -- HUD
    if S.hud then
        if not hudG then MakeHUD()end
        hFrames=hFrames+1;hTime=hTime+dt
        if hTime>=1 then hFps=math.floor(hFrames/hTime);hFrames=0;hTime=0 end
        if S.hudFPS then hudG.fps.Text="FPS: "..tostring(hFps);hudG.fps.Visible=true else hudG.fps.Visible=false end
        if S.hudPing then local ping=math.floor(LP:GetNetworkPing()*1000);hudG.ping.Text="Ping: "..tostring(ping).."ms";hudG.ping.Visible=true else hudG.ping.Visible=false end
        if S.hudKiller then
            local kn="--"
            for _,plr in pairs(Players:GetPlayers())do if plr~=LP and plr.Character and plr.Character:FindFirstChild("Humanoid")and plr.Character.Humanoid.Health>0 then local team=plr.Team;if team and(team.Name:lower():find("maniac")or team.Name:lower():find("killer"))then kn=plr.Name;break end end end
            hudG.killer.Text="Killer: "..kn;hudG.killer.Visible=true
        else hudG.killer.Visible=false end
        local vc=0;if hudG.fps.Visible then vc=vc+1 end;if hudG.ping.Visible then vc=vc+1 end;if hudG.killer.Visible then vc=vc+1 end
        hudG.frame.Size=UDim2.new(0,180,0,8+vc*22)
    elseif hudG then pcall(function()hudG.sg:Destroy()end);hudG=nil end
end)

-- FLASHLIGHT (Heartbeat)
RunService.Heartbeat:Connect(function()
    if S.fl then
        if not flObj then flObj=Instance.new("SpotLight");flObj.Brightness=2;flObj.Range=60;flObj.Angle=90;flObj.Face=Enum.NormalId.Front;flObj.Parent=Camera end
        flObj.Enabled=true
    elseif flObj then flObj.Enabled=false end
end)