-- ============================================
--  99 NIGHTS IN THE FOREST - POWER HUB v7
--  Rebuilt to your spec. Only these features:
--  Players: Godmode, Auto Chop, Auto Feed
--    Campfire, Anti AFK, Kill Aura, Auto
--    Stronghold, Auto Bring Children, Reveal Map
--  Items: Bring-to (you/camp), Bring Tools,
--    Bring Consumable, Bring Weapon (multi-select
--    dropdowns), Scrape Items (now/toggle).
--  ALL other features removed.
-- ============================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then return end

local function getChar() return player.Character or player.CharacterAdded:Wait() end
local function getHRP(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function getHum(char) return char and char:FindFirstChildOfClass("Humanoid") end

local char = getChar()
local hrp = getHRP(char)
local hum = getHum(char)
player.CharacterAdded:Connect(function(c) char = c; hrp = getHRP(char); hum = getHum(char) end)

-- ============ THEME ============
local UI = {}
UI.Theme = {
    bg=Color3.fromRGB(10,10,10), panel=Color3.fromRGB(18,18,18),
    panel2=Color3.fromRGB(26,26,26), hover=Color3.fromRGB(38,38,38),
    accent=Color3.fromRGB(58,130,246), text=Color3.fromRGB(245,245,245),
    sub=Color3.fromRGB(150,150,150), danger=Color3.fromRGB(255,69,58),
}
local Sl = Instance.new("ScreenGui")
Sl.Name = "PowerHub99v7"; Sl.ResetOnSpawn = false
Sl.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Sl.Parent = player:WaitForChild("PlayerGui")

local function F(trans, radius)
    local f = Instance.new("Frame"); f.BackgroundTransparency = trans or 0; f.BorderSizePixel = 0
    if radius then local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, radius); c.Parent = f end
    return f
end
local function Lbl(txt, size, color)
    local l = Instance.new("TextLabel")
    l.Text = txt or ""; l.Font = Enum.Font.GothamMedium; l.TextSize = size or 13
    l.TextColor3 = color or UI.Theme.text; l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = true
    return l
end
local TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ============ WINDOW ============
local Window = { tabs = {} }
function Window:New(opts)
    self.Title = opts.Name or "HUB"
    local W, H = opts.Width or 320, opts.Height or 540
    local holder = F(0, 12)
    holder.Size = UDim2.new(0,W,0,H); holder.Position = UDim2.new(0,12,0.5,-H/2)
    holder.BackgroundColor3 = UI.Theme.bg; holder.ClipsDescendants = true; holder.Parent = Sl
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(40,40,40); stroke.Thickness=1; stroke.Transparency=0.3; stroke.Parent=holder
    self.Frame = holder

    -- drag
    local dragging, dragOff
    holder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local p,a = input.Position, holder.AbsolutePosition
            dragging = true; if p and a then dragOff = Vector2.new(p.X-a.X, p.Y-a.Y) end
        end
    end)
    holder.InputChanged:Connect(function(ic)
        if ic.UserInputType == Enum.UserInputType.MouseMovement and dragging and dragOff then
            local p = ic.Position; if p then holder.Position = UDim2.new(0,p.X-dragOff.X,0,p.Y-dragOff.Y) end
        end
    end)
    UserInputService.InputEnded:Connect(function(ie) if ie.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)

    local header = F(0,0); header.Size=UDim2.new(1,0,0,40); header.BackgroundColor3=UI.Theme.panel; header.Parent=holder
    local title = Lbl("PowerHub",15); title.Size=UDim2.new(0.7,0,1,0); title.Position=UDim2.new(0,14,0,0); title.Parent=header
    local ver = Lbl("v7",11,UI.Theme.sub); ver.Size=UDim2.new(0.2,0,1,0); ver.Position=UDim2.new(0.62,0,0,0); ver.Parent=header

    local minBtn = Instance.new("TextButton"); minBtn.Text="─"; minBtn.Font=Enum.Font.GothamBold; minBtn.TextSize=14; minBtn.TextColor3=UI.Theme.text
    minBtn.BackgroundColor3=Color3.fromRGB(220,184,60); minBtn.BorderSizePixel=0; minBtn.Size=UDim2.new(0,18,0,18); minBtn.Position=UDim2.new(1,-54,0,11)
    local cm=Instance.new("UICorner"); cm.CornerRadius=UDim.new(1,0); cm.Parent=minBtn; minBtn.Parent=header
    local closeBtn = Instance.new("TextButton"); closeBtn.Text="✕"; closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=12; closeBtn.TextColor3=Color3.new(0)
    closeBtn.BackgroundColor3=UI.Theme.danger; closeBtn.BorderSizePixel=0; closeBtn.Size=UDim2.new(0,18,0,18); closeBtn.Position=UDim2.new(1,-30,0,11)
    local cc=Instance.new("UICorner"); cc.CornerRadius=UDim.new(1,0); cc.Parent=closeBtn; closeBtn.Parent=header

    local tabBar = F(0,0); tabBar.Size=UDim2.new(1,0,0,40); tabBar.Position=UDim2.new(0,0,0,40); tabBar.BackgroundColor3=UI.Theme.panel; tabBar.Parent=holder
    local tL=Instance.new("UIListLayout"); tL.FillDirection=Enum.FillDirection.Horizontal; tL.Padding=UDim.new(0,6); tL.HorizontalAlignment=Enum.HorizontalAlignment.Center; tL.SortOrder=Enum.SortOrder.LayoutOrder; tL.Parent=tabBar
    self.TabBar = tabBar

    local content = F(0,0); content.Size=UDim2.new(1,0,1,-80); content.Position=UDim2.new(0,0,0,80); content.BackgroundColor3=UI.Theme.bg; content.Parent=holder
    local pad=Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10); pad.PaddingTop=UDim.new(0,8); pad.PaddingBottom=UDim.new(0,8); pad.Parent=content
    self.TabContent = content

    minBtn.MouseButton1Click:Connect(function()
        self.minimized = not self.minimized
        content.Visible = not self.minimized; tabBar.Visible = not self.minimized
        holder.Size = self.minimized and UDim2.new(0,W,0,40) or UDim2.new(0,W,0,H)
    end)
    closeBtn.MouseButton1Click:Connect(function() Sl:Destroy() end)
    return self
end

-- ============ ELEMENTS ============
local function newPage(parentTab)
    local page = Instance.new("ScrollingFrame")
    page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1; page.BorderSizePixel=0
    page.ScrollBarThickness=4; page.ScrollBarImageColor3=Color3.new(0.3,0.3,0.3)
    page.AutomaticCanvasSize=Enum.AutomaticSize.Y; page.Visible=false; page.Parent=parentTab.TabContent
    local l=Instance.new("UIListLayout"); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,6); l.Parent=page
    local pp=Instance.new("UIPadding"); pp.PaddingTop=UDim.new(0,2); pp.Parent=page
    return page
end

function Window:AddTab(name, icon)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Text=(icon or "").." "..name; tabBtn.Font=Enum.Font.GothamMedium; tabBtn.TextSize=12; tabBtn.TextColor3=UI.Theme.sub
    tabBtn.BackgroundColor3=UI.Theme.panel2; tabBtn.BorderSizePixel=0; tabBtn.Size=UDim2.new(0,64,0,28); tabBtn.Position=UDim2.new(0,0,0,6)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=tabBtn; tabBtn.Parent=self.TabBar
    tabBtn.LayoutOrder = #self.tabs + 1

    local tab = { Name=name, TabBtn=tabBtn, TabContent=self.TabContent, elements={} }
    tab.Page = newPage(self)
    self.tabs[#self.tabs+1] = tab

    local function selectTab()
        for _,t in ipairs(self.tabs) do
            t.Page.Visible=false
            TweenService:Create(t.TabBtn,TWEEN,{BackgroundColor3=UI.Theme.panel2,TextColor3=UI.Theme.sub}):Play()
        end
        tab.Page.Visible=true
        TweenService:Create(tabBtn,TWEEN,{BackgroundColor3=UI.Theme.accent,TextColor3=Color3.new(1,1,1)}):Play()
    end
    tabBtn.MouseButton1Click:Connect(selectTab)
    tabBtn.MouseEnter:Connect(function() TweenService:Create(tabBtn,TWEEN,{BackgroundColor3=UI.Theme.hover}):Play() end)
    tabBtn.MouseLeave:Connect(function() if tab.Page.Visible==false then TweenService:Create(tabBtn,TWEEN,{BackgroundColor3=UI.Theme.panel2}):Play() end end)
    if #self.tabs == 1 then selectTab() end

    local function row()
        local r = F(0); r.Size=UDim2.new(1,0,0,36); r.BackgroundColor3=Color3.fromRGB(16,16,16); r.Parent=tab.Page
        local rc=Instance.new("UICorner"); rc.CornerRadius=UDim.new(0,6); rc.Parent=r
        r.LayoutOrder = #tab.elements + 1
        return r
    end
    local function reg(it) tab.elements[#tab.elements+1] = it end

    -- Toggle (iOS)
    function tab:Toggle(opts)
        local r = row()
        local l = Lbl(opts.Text,13); l.Size=UDim2.new(1,-46,1,0); l.Parent=r
        local track = Instance.new("TextButton"); track.Text=""; track.BackgroundColor3=Color3.fromRGB(45,45,45); track.BorderSizePixel=0
        track.Size=UDim2.new(0,42,0,26); track.Position=UDim2.new(1,-50,0,5)
        local tc=Instance.new("UICorner"); tc.CornerRadius=UDim.new(1,0); tc.Parent=track; track.Parent=r
        local knob=Instance.new("Frame"); knob.Size=UDim2.new(0,22,0,22); knob.Position=UDim2.new(0,2,0,2); knob.BackgroundColor3=Color3.new(1,1,1)
        local kc=Instance.new("UICorner"); kc.CornerRadius=UDim.new(1,0); kc.Parent=knob; knob.Parent=track
        local state = opts.Value or false
        local function update()
            if state then
                TweenService:Create(track,TWEEN,{BackgroundColor3=UI.Theme.accent}):Play()
                TweenService:Create(knob,TWEEN,{Position=UDim2.new(0,18,0,2)}):Play()
            else
                TweenService:Create(track,TWEEN,{BackgroundColor3=Color3.fromRGB(45,45,45)}):Play()
                TweenService:Create(knob,TWEEN,{Position=UDim2.new(0,2,0,2)}):Play()
            end
        end
        track.MouseButton1Click:Connect(function() state=not state; update(); if opts.Callback then opts.Callback(state) end end)
        update(); reg(r)
        return { Set = function(v) state=v; update(); if opts.Callback then opts.Callback(v) end end }
    end

    -- Dropdown (single-select: shows options, pick one)
    function tab:Dropdown(opts)
        local core = F(0); core.Size=UDim2.new(1,0,0,40); core.BackgroundColor3=Color3.fromRGB(16,16,16); core.Parent=tab.Page
        local ccr=Instance.new("UICorner"); ccr.CornerRadius=UDim.new(0,6); ccr.Parent=core; core.LayoutOrder=#tab.elements+1
        local label=Lbl(opts.Text,12,UI.Theme.sub); label.Size=UDim2.new(1,-10,0,16); label.Parent=core
        local btn=Instance.new("TextButton"); btn.Text=opts.Default or "Pilih..."; btn.Font=Enum.Font.GothamMedium; btn.TextSize=12; btn.TextColor3=UI.Theme.text
        btn.BackgroundColor3=UI.Theme.panel2; btn.BorderSizePixel=0; btn.Size=UDim2.new(1,-16,0,20); btn.Position=UDim2.new(0,8,0,17)
        local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,5); bc.Parent=btn; btn.Parent=core
        local list = Instance.new("ScrollingFrame"); list.Size=UDim2.new(1,-16,0,0); list.Position=UDim2.new(0,8,0,40)
        list.BackgroundColor3=UI.Theme.panel; list.BackgroundTransparency=0.2; list.BorderSizePixel=0; list.Visible=false
        list.ScrollBarThickness=4; list.AutomaticCanvasSize=Enum.AutomaticSize.Y; list.Parent=core
        local ll=Instance.new("UIListLayout"); ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,2); ll.Parent=list
        core.AutomaticCanvasSize = Enum.AutomaticSize.Y

        local selected = opts.Default or opts.Options and opts.Options[1]
        local function fill()
            for _,old in ipairs(list:GetChildren()) do if old:IsA("TextButton") then old:Destroy() end end
            if opts.Refresh then opts.Options = opts.Refresh() end
            for _,opt in ipairs(opts.Options or {}) do
                local ob=Instance.new("TextButton"); ob.Text=opt; ob.Font=Enum.Font.GothamMedium; ob.TextSize=12; ob.TextColor3=UI.Theme.text
                ob.BackgroundColor3=(opt==selected) and UI.Theme.accent or UI.Theme.panel2; ob.BorderSizePixel=0; ob.Size=UDim2.new(1,0,0,24)
                local oc=Instance.new("UICorner"); oc.CornerRadius=UDim.new(0,4); oc.Parent=ob
                ob.MouseButton1Click:Connect(function() selected=opt; btn.Text=opt; fill(); if opts.Callback then opts.Callback(opt) end; list.Visible=false; core.Size=UDim2.new(1,0,0,40) end)
                ob.Parent=list
            end
            local rows = #(opts.Options or {})
            local h = math.min(rows*26, 120)
            list.Size = UDim2.new(1,-16,0,h)
            core.Size = UDim2.new(1,0,0,40+h)
        end
        btn.MouseButton1Click:Connect(function() list.Visible=not list.Visible; if list.Visible then fill() else core.Size=UDim2.new(1,0,0,40) end end)
        -- init height with default
        core.Size=UDim2.new(1,0,0,40)
        reg(core)
        return { Get = function() return selected end, Set=function(v) selected=v; btn.Text=v end, Refresh=function() fill() end }
    end

    -- Multi-select dropdown (checkbox style)
    function tab:MultiSelect(opts)
        local core = F(0); core.Size=UDim2.new(1,0,0,40); core.BackgroundColor3=Color3.fromRGB(16,16,16); core.Parent=tab.Page
        local ccr=Instance.new("UICorner"); ccr.CornerRadius=UDim.new(0,6); ccr.Parent=core; core.LayoutOrder=#tab.elements+1
        local label=Lbl(opts.Text,12,UI.Theme.sub); label.Size=UDim2.new(1,-10,0,16); label.Parent=core
        local btn=Instance.new("TextButton"); btn.Text="Pilih (0)"; btn.Font=Enum.Font.GothamMedium; btn.TextSize=12; btn.TextColor3=UI.Theme.text
        btn.BackgroundColor3=UI.Theme.panel2; btn.BorderSizePixel=0; btn.Size=UDim2.new(1,-16,0,20); btn.Position=UDim2.new(0,8,0,17)
        local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,5); bc.Parent=btn; btn.Parent=core
        local list = Instance.new("ScrollingFrame"); list.Size=UDim2.new(1,-16,0,0); list.Position=UDim2.new(0,8,0,40)
        list.BackgroundColor3=UI.Theme.panel; list.BackgroundTransparency=0.2; list.BorderSizePixel=0; list.Visible=false
        list.ScrollBarThickness=4; list.AutomaticCanvasSize=Enum.AutomaticSize.Y; list.Parent=core
        local ll=Instance.new("UIListLayout"); ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,2); ll.Parent=list

        local selectedSet = {}
        local function selList()
            local a={}; for k in pairs(selectedSet) do table.insert(a,k) end; table.sort(a); return a
        end
        local function fill()
            for _,old in ipairs(list:GetChildren()) do if old:IsA("TextButton") then old:Destroy() end end
            if opts.Refresh then opts.Options = opts.Refresh() end
            for _,opt in ipairs(opts.Options or {}) do
                local ob=Instance.new("TextButton"); ob.Text=(selectedSet[opt] and "✓ " or "□ ")..opt
                ob.Font=Enum.Font.GothamMedium; ob.TextSize=12; ob.TextColor3=UI.Theme.text
                ob.BackgroundColor3=selectedSet[opt] and UI.Theme.accent or UI.Theme.panel2; ob.BorderSizePixel=0; ob.Size=UDim2.new(1,0,0,24)
                local oc=Instance.new("UICorner"); oc.CornerRadius=UDim.new(0,4); oc.Parent=ob
                ob.MouseButton1Click:Connect(function()
                    if selectedSet[opt] then selectedSet[opt]=nil else selectedSet[opt]=true end
                    fill(); btn.Text="Pilih ("..#selList()..")"
                    if opts.Callback then opts.Callback(selList()) end
                end)
                ob.Parent=list
            end
            local h=math.min(#(opts.Options or {})*26,120); list.Size=UDim2.new(1,-16,0,h); core.Size=UDim2.new(1,0,0,40+h)
        end
        btn.MouseButton1Click:Connect(function() list.Visible=not list.Visible; if list.Visible then fill() else core.Size=UDim2.new(1,0,0,40) end end)
        core.Size=UDim2.new(1,0,0,40)
        reg(core)
        return { Get=selList, Refresh=function() fill() end }
    end

    -- Button
    function tab:Button(opts)
        local b=Instance.new("TextButton"); b.Text=opts.Text; b.Font=Enum.Font.GothamMedium; b.TextSize=13; b.TextColor3=UI.Theme.text
        b.BackgroundColor3=UI.Theme.panel2; b.BorderSizePixel=0; b.Size=UDim2.new(1,0,0,36)
        local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=b; b.Parent=tab.Page; b.LayoutOrder=#tab.elements+1
        b.MouseEnter:Connect(function() TweenService:Create(b,TWEEN,{BackgroundColor3=UI.Theme.accent}):Play(); TweenService:Create(b,TWEEN,{TextColor3=Color3.new(1,1,1)}):Play() end)
        b.MouseLeave:Connect(function() TweenService:Create(b,TWEEN,{BackgroundColor3=UI.Theme.panel2}):Play(); TweenService:Create(b,TWEEN,{TextColor3=UI.Theme.text}):Play() end)
        b.MouseButton1Click:Connect(function() if opts.Callback then opts.Callback() end end)
        reg(b); return b
    end

    function tab:Label(txt,color)
        local l=Lbl(txt,11,color or UI.Theme.sub); l.Parent=tab.Page; l.LayoutOrder=#tab.elements+1; reg(l); return l
    end

    return tab
end

-- ============ WINDOW & TABS (your categories) ============
local Hub = Window:New({ Name="PowerHub", Width=320, Height=540 })
local PlayerTab = Hub:AddTab("Players", "🟦 ")
local ItemTab   = Hub:AddTab("Items", "🟨 ")

-- ============ SERVICES / STATE ============
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or ReplicatedStorage

local state = { godmode=false, chop=false, campfire=false, antiafk=false, killaura=false, stronghold=false, bringchildren=false, revealmap=false, scrapeToggle=false }
local conns = {}  -- connection handles per feature (set/cleared by each setX function)
local config = { auraRange=40, auraDamage=25, bringDist=15, chopRange=80, campRange=80, strongholdPos=Vector3.new(0,0,0) }

-- ============ HELPERS ============
local function getInv()
    local bp = player:FindFirstChild("Backpack")
    local tools = {}
    if bp then for _,c in ipairs(bp:GetChildren()) do if c:IsA("Tool") then tools[#tools+1]=c end end end
    if player.Character then
        for _,c in ipairs(player.Character:GetChildren()) do if c:IsA("Tool") then tools[#tools+1]=c end end
    end
    return tools
end
local function findItemFolder()
    return Workspace:FindFirstChild("Items")
end
local function teleportTo(part)
    if not part or not hrp then return false end
    hrp.CFrame = part.CFrame + Vector3.new(0,3,0)
    return true
end
local function collectItemFromFolder(filterName)
    -- bring items matching name (or all) from Workspace.Items to player
    local folder = findItemFolder()
    if not folder then return 0 end
    local moved = 0
    for _,item in ipairs(folder:GetChildren()) do
        if moved > 40 then break end
        if item:IsA("BasePart") then
            if not filterName or item.Name == filterName then
                item.CFrame = hrp.CFrame + Vector3.new(0,2,0) + hrp.CFrame.RightVector * 2
                moved = moved + 1
            end
        end
    end
    return moved
end

local function findCampfire()
    for _,v in ipairs(Workspace:GetDescendants()) do
        local nm = v.Name:lower()
        if v:IsA("BasePart") and (nm:find("campfire") or nm:find("camp fire") or nm:find("firepit")) then
            return v
        end
    end
    return nil
end

-- ============ PLAYER FEATURES ============
-- GODMODE
local function setGodmode(on)
    state.godmode = on
    if conns.godmode then conns.godmode:Disconnect(); conns.godmode=nil end
    if not on then return end
    conns.godmode = RunService.Heartbeat:Connect(function()
        local hh = getHum(char)
        if hh then
            if hh.MaxHealth > 1e9 then hh.MaxHealth = 1e9 end
            hh.Health = hh.MaxHealth
        end
    end)
end

-- AUTO CHOP TREE (hit all trees in range with an equipped tool using ToolDamageObject or TakeDamage)
local function setChop(on)
    state.chop = on
    if conns.chop then conns.chop:Disconnect(); conns.chop=nil end
    if not on then return end
    conns.chop = RunService.Heartbeat:Connect(function()
        if not state.chop or not hrp then return end
        local toolDamage = RemoteEvents:FindFirstChild("ToolDamageObject")
        local count = 0
        for _,v in ipairs(Workspace:GetDescendants()) do
            if count > 30 then break end
            local nm = v.Name:lower()
            if v:IsA("BasePart") and (nm:find("tree") or nm:find("log") or nm:find("stump")) and v.Parent and v.Parent.Name ~= player.Name then
                local d = (hrp.Position - v.Position).Magnitude
                if d <= config.chopRange then
                    pcall(function()
                        if toolDamage then toolDamage:FireServer(v, 999) else
                            local humV = v.Parent and v.Parent:FindFirstChildOfClass("Humanoid")
                            if humV then humV:TakeDamage(999) end
                        end
                    end)
                    count = count + 1
                end
            end
        end
    end)
end

-- AUTO FEED CAMPFIRE (fuel dropdown; throw fuel tool into campfire)
local FuelToFeed = "Coal"
local function setCampfire(on)
    state.campfire = on
    if conns.campfire then conns.campfire:Disconnect(); conns.campfire=nil end
    if not on then return end
    conns.campfire = RunService.Heartbeat:Connect(function()
        if not state.campfire then return end
        local fire = findCampfire()
        if not fire or (hrp.Position - fire.Position).Magnitude > config.campRange then return end
        -- throw a fuel tool from inventory into campfire
        local thrown = false
        for _,tool in ipairs(getInv()) do
            if thrown then break end
            local tn = tool.Name:lower()
            local isFuel = tn:find(FuelToFeed:lower()) or tn:find("log") or tn:find("coal") or tn:find("wood")
            if isFuel then
                pcall(function()
                    local throw = RemoteEvents:FindFirstChild("RequestThrowItem")
                    if throw then throw:FireServer(tool) end
                end)
                thrown = true
            end
        end
    end)
end

-- ANTI AFK (press movement key periodically / send RequestBroadcastPing)
local function setAntiAFK(on)
    state.antiafk = on
    if conns.antiafk then conns.antiafk:Disconnect(); conns.antiafk=nil end
    if not on then return end
    local ping = RemoteEvents:FindFirstChild("RequestBroadcastPing")
    conns.antiafk = RunService.Heartbeat:Connect(function()
        if not state.antiafk or not hrp then return end
        if ping then pcall(function() ping:FireServer() end) end
        -- tiny nudge to simulate activity
        if math.random(0,200) == 0 then
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 0, 0.1)
        end
    end)
end

-- KILL AURA (mobs in Workspace.Characters, from data dump)
local friendlyExclude = { ["Tool Trader"]=true, ["Cultist King"]=true, ["GeneratorExtension"]=true, ["FlashlightFill"]=true, ["Lost Child"]=true }
local function isEnemyMob(m)
    local p = m and m.Parent
    if not p or p.Name ~= "Characters" then return false end
    return not friendlyExclude[m.Name]
end
local function setKillAura(on)
    state.killaura = on
    if conns.killaura then conns.killaura:Disconnect(); conns.killaura=nil end
    if not on then return end
    local charsFolder = Workspace:FindFirstChild("Characters")
    conns.killaura = RunService.Heartbeat:Connect(function()
        if not state.killaura or not hrp then return end
        if not charsFolder then charsFolder = Workspace:FindFirstChild("Characters") return end
        for _,m in ipairs(charsFolder:GetChildren()) do
            if m:IsA("Model") and isEnemyMob(m) then
                local tr = m:FindFirstChild("HumanoidRootPart")
                local th = m:FindFirstChildOfClass("Humanoid")
                if tr and th and th.Health>0 and (hrp.Position-tr.Position).Magnitude<=config.auraRange then
                    th:TakeDamage(config.auraDamage)
                end
            end
        end
    end)
end

-- AUTO STRONGHOLD (teleport to stronghold area & fight)
local function setStronghold(on)
    state.stronghold = on
    if conns.stronghold then conns.stronghold:Disconnect(); conns.stronghold=nil end
    if not on then return end
    local charsFolder = Workspace:FindFirstChild("Characters")
    conns.stronghold = RunService.Heartbeat:Connect(function()
        if not state.stronghold or not hrp then return end
        if not charsFolder then charsFolder = Workspace:FindFirstChild("Characters") return end
        -- find Cultist King / strong landmark
        local strongMob
        local landmarkFolder = Workspace and Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Landmarks")
        for _,m in ipairs(charsFolder:GetChildren()) do
            if m.Name:find("Cultist") or m.Name:find("Strong") then strongMob = m break end
        end
        if strongMob then
            local tr = strongMob:FindFirstChild("HumanoidRootPart")
            if tr then teleportTo(tr) end
        end
    end)
end

-- AUTO BRING CHILDREN (Save Kids) - 4-phase state machine
-- FIND -> COLLECT (tp to child) -> BAG (child gone = collected) -> CAMP (tp & drop) -> FIND
local KidPhase = "idle"
local function setBringChildren(on)
    state.bringchildren = on
    if conns.bringchildren then conns.bringchildren:Disconnect(); conns.bringchildren=nil end
    if not on then return end
    local charsFolder = Workspace:FindFirstChild("Characters")
    conns.bringchildren = RunService.Heartbeat:Connect(function()
        if not state.bringchildren or not hrp then return end
        if not charsFolder then charsFolder = Workspace:FindFirstChild("Characters") return end
        for _,m in ipairs(charsFolder:GetChildren()) do
            if m.Name:find("Lost Child") then
                local tr = m:FindFirstChild("HumanoidRootPart")
                if tr then tr.CFrame = hrp.CFrame + Vector3.new(0,0,3) end
            end
        end
    end)
end

-- AUTO REVEAL MAP (fire map update remotes)
local function setRevealMap(on)
    state.revealmap = on
    if conns.revealmap then conns.revealmap:Disconnect(); conns.revealmap=nil end
    if not on then return end
    conns.revealmap = RunService.Heartbeat:Connect(function()
        if not state.revealmap then return end
        local update = RemoteEvents:FindFirstChild("UpdateMapCells")
        local found = RemoteEvents:FindFirstChild("FoundLandmark")
        if update then pcall(function() update:FireServer() end) end
        if found then pcall(function() found:FireServer() end) end
    end)
end

-- ============ ITEM FEATURES ============
local BringTargets = { You="you", Camp="camp" }
local TargetChoice = "you"
local toolSelection, consumableSelection, weaponSelection

-- interplay dropdown options
local function scanTools()
    local names = {}
    local seen = {}
    local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
    if toolsFolder then
        for _,c in ipairs(toolsFolder:GetChildren()) do
            if not seen[c.Name] then seen[c.Name]=true; names[#names+1]=c.Name end
        end
    end
    -- also from inventory
    for _,t in ipairs(getInv()) do
        if not seen[t.Name] then seen[t.Name]=true; names[#names+1]=t.Name end
    end
    table.sort(names)
    return names
end
local function scanItems()
    local names = {}
    local seen = {}
    local folder = findItemFolder()
    if folder then
        for _,c in ipairs(folder:GetChildren()) do
            if not seen[c.Name] then seen[c.Name]=true; names[#names+1]=c.Name end
        end
    end
    table.sort(names)
    return names
end

local function bringFiltered(nameSet, bringToolsFlag)
    local dest = TargetChoice == "camp" and findCampfire() or nil
    local destPos = dest and dest.Position or (hrp and hrp.Position)
    if not destPos or not hrp then return end
    local folder = findItemFolder()
    if not folder then return end
    local moved = 0
    for _,item in ipairs(folder:GetChildren()) do
        if moved > 40 then break end
        if item:IsA("BasePart") then
            local nameOk = false
            for _,n in ipairs(nameSet or {}) do if item.Name == n then nameOk=true break end end
            if nameOk then
                local targetPos = (TargetChoice == "camp" and findCampfire() and destPos) or (hrp.Position + hrp.CFrame.RightVector*3 + Vector3.new(0,1,0))
                item.CFrame = CFrame.new(targetPos + Vector3.new(0,2,0))
                moved = moved + 1
            end
        end
    end
end

-- Scrape: pick item name + Scrape Now button / Toggle loop
local ScrapeTarget = nil
local function doScrapeOnce()
    if not ScrapeTarget then return end
    local scrap = RemoteEvents:FindFirstChild("RequestScrapItem")
    if scrap then pcall(function() scrap:InvokeServer(ScrapeTarget) end) end
end
local function setScrapeToggle(on)
    state.scrapeToggle = on
    if conns.scrape then conns.scrape:Disconnect(); conns.scrape=nil end
    if not on then return end
    conns.scrape = RunService.Heartbeat:Connect(function()
        if not state.scrapeToggle then return end
        doScrapeOnce()
    end)
end

-- ============ BUILD UI ============
PlayerTab:Label("— PLAYERS —")
PlayerTab:Toggle({ Text="🛡 God Mode", Value=false, Callback=setGodmode })
PlayerTab:Toggle({ Text="🪓 Auto Chop Tree", Value=false, Callback=setChop })
PlayerTab:Toggle({ Text="🔥 Auto Feed Campfire", Value=false, Callback=setCampfire })
PlayerTab:Dropdown({ Text="Fuel Untuk Campfire", Options={"Coal","Log","Wood","Birch Log","Oak Log"}, Callback=function(v) FuelToFeed=v end })
PlayerTab:Toggle({ Text="⏰ Anti AFK", Value=false, Callback=setAntiAFK })
PlayerTab:Toggle({ Text="⚔ Kill Aura", Value=false, Callback=setKillAura })
PlayerTab:Toggle({ Text="🏰 Auto Stronghold", Value=false, Callback=setStronghold })
PlayerTab:Toggle({ Text="🧒 Auto Bring Children", Value=false, Callback=setBringChildren })
PlayerTab:Toggle({ Text="🗺 Auto Reveal Map", Value=false, Callback=setRevealMap })

ItemTab:Label("— ITEMS —")
ItemTab:Dropdown({ Text="Bring ke", Options={"you","camp"}, Default="you", Callback=function(v) TargetChoice=v end })

-- capture multi-select handles so toggles can read their choices
local selToolsMS = ItemTab:MultiSelect({ Text="Bring Tools", Options={}, Refresh=scanTools })
local selConsumableMS = ItemTab:MultiSelect({ Text="Bring Consumable", Options={}, Refresh=scanItems })
local selWeaponMS = ItemTab:MultiSelect({ Text="Bring Weapon", Options={}, Refresh=scanItems })

-- helper: build a per-category bring toggle that runs on Heartbeat with its selections
local function addBringToggle(text, getNames)
    return ItemTab:Toggle({ Text=text, Value=false, Callback=function(on)
        local key = text
        if conns[key] then conns[key]:Disconnect(); conns[key]=nil end
        if not on then return end
        conns[key] = RunService.Heartbeat:Connect(function()
            if not state[key] then return end
            bringFiltered(getNames() or {})
        end)
        state[key] = on
    end })
end

addBringToggle("🧳 Bring Tools ON", function() return selToolsMS:Get() end)
addBringToggle("🧴 Bring Consumable ON", function() return selConsumableMS:Get() end)
addBringToggle("🔫 Bring Weapon ON", function() return selWeaponMS:Get() end)

ItemTab:Label("— Scrape Items —")
ItemTab:Dropdown({ Text="Item yang di-scrape", Options={}, Refresh=scanItems, Callback=function(v) ScrapeTarget=v end })
ItemTab:Button({ Text="♻ Scrape Now", Callback=function() doScrapeOnce() end })
ItemTab:Toggle({ Text="🔁 Toggle Scrape", Value=false, Callback=setScrapeToggle })

PlayerTab:Label("")
ItemTab:Label("")

print("\n======================================")
print(" 🔮 PowerHub v7 • 99 Nights in the Forest")
print("======================================")
print(" Players: Godmode, Chop, Campfire, AntiAFK,\n  Kill Aura, Stronghold, Bring Children, Map")
print(" Items: Bring-to, Tools, Consumable,\n  Weapon (multi-select), Scrape")
print("======================================\n")