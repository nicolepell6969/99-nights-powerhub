-- ============================================
--  99 NIGHTS IN THE FOREST - POWER HUB v5
--  Refined GUI: iOS toggles, draggable sliders,
--  smooth hover, compact left panel, all-black.
--  Features: Fly, Noclip, Speed, Jump, Godmode,
--  Invisibility, Kill Aura, Bring Items, Auto
--  Farm, ESP (Player/Items), Fullbright, Teleport
-- ============================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then return end

-- ============ UTIL ============
local function getChar() return player.Character or player.CharacterAdded:Wait() end
local function getHRP(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function getHum(char) return char and char:FindFirstChildOfClass("Humanoid") end

local char = getChar()
local hrp = getHRP(char)
local hum = getHum(char)
if not hrp or not hum then
    player.CharacterAdded:Wait()
    char = getChar(); hrp = getHRP(char); hum = getHum(char)
end

local function refreshChar(c) char = c; hrp = getHRP(char); hum = getHum(char) end
player.CharacterAdded:Connect(refreshChar)

-- ============ THEME (all-black, white text) ============
local UI = {}
UI.Theme = {
    bg      = Color3.fromRGB(10, 10, 10),
    panel   = Color3.fromRGB(18, 18, 18),
    panel2  = Color3.fromRGB(26, 26, 26),
    hover   = Color3.fromRGB(38, 38, 38),
    accent  = Color3.fromRGB(58, 130, 246),   -- iOS blue
    accentOn= Color3.fromRGB(58, 130, 246),
    text    = Color3.fromRGB(245, 245, 245),
    sub     = Color3.fromRGB(150, 150, 150),
    danger  = Color3.fromRGB(255, 69, 58),
}

local Sl = Instance.new("ScreenGui")
Sl.Name = "PowerHub99v5"
Sl.ResetOnSpawn = false
Sl.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Sl.Parent = player:WaitForChild("PlayerGui")

local function F(trans, radius)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = trans or 0
    f.BorderSizePixel = 0
    if radius then local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, radius); c.Parent = f end
    return f
end
local function Lbl(txt, size, color, align)
    local l = Instance.new("TextLabel")
    l.Text = txt or ""
    l.Font = Enum.Font.GothamMedium
    l.TextSize = size or 13
    l.TextColor3 = color or UI.Theme.text
    l.BackgroundTransparency = 1
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.TextWrapped = true
    return l
end

local TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ============ WINDOW ============
local Window = { minimized = false, tabs = {} }
local activeTab = nil

function Window:New(opts)
    self.Title = opts.Name or "HUB"
    local W, H = opts.Width or 320, opts.Height or 520

    local holder = F(0, 12)
    holder.Name = "Holder"
    holder.Size = UDim2.new(0, W, 0, H)
    holder.Position = UDim2.new(0, 12, 0.5, -H / 2)
    holder.BackgroundColor3 = UI.Theme.bg
    holder.ClipsDescendants = true
    holder.Parent = Sl
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(40, 40, 40); stroke.Thickness = 1; stroke.Transparency = 0.3; stroke.Parent = holder

    self.Frame = holder

    -- drag
    local dragging, dragOff
    holder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local p, a = input.Position, holder.AbsolutePosition
            if p and a then dragOff = Vector2.new(p.X - a.X, p.Y - a.Y) end
        end
    end)
    holder.InputChanged:Connect(function(ic)
        if ic.UserInputType == Enum.UserInputType.MouseMovement and dragging and dragOff then
            local p = ic.Position
            if p then holder.Position = UDim2.new(0, p.X - dragOff.X, 0, p.Y - dragOff.Y) end
        end
    end)
    UserInputService.InputEnded:Connect(function(ie)
        if ie.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- header
    local header = F(0, 0); header.Name = "Header"; header.Size = UDim2.new(1, 0, 0, 40); header.BackgroundColor3 = UI.Theme.panel; header.Parent = holder
    local title = Lbl("PowerHub", 15, UI.Theme.text); title.Size = UDim2.new(0.7, 0, 1, 0); title.Position = UDim2.new(0, 14, 0, 0); title.Parent = header
    local ver = Lbl("v5", 11, UI.Theme.sub); ver.Size = UDim2.new(0.2, 0, 1, 0); ver.Position = UDim2.new(0.62, 0, 0, 0); ver.Parent = header

    -- minimize / close as small iOS dots
    local minBtn = Instance.new("TextButton"); minBtn.Text = "─"; minBtn.Font = Enum.Font.GothamBold; minBtn.TextSize = 14; minBtn.TextColor3 = UI.Theme.text
    minBtn.BackgroundColor3 = Color3.fromRGB(220, 184, 60); minBtn.BorderSizePixel = 0; minBtn.Size = UDim2.new(0, 18, 0, 18); minBtn.Position = UDim2.new(1, -54, 0, 11)
    local cm = Instance.new("UICorner"); cm.CornerRadius = UDim.new(1, 0); cm.Parent = minBtn; minBtn.Parent = header
    minBtn.MouseEnter:Connect(function() TweenService:Create(minBtn, TWEEN, { BackgroundColor3 = Color3.new(1, 0.86, 0.5) }):Play() end)
    minBtn.MouseLeave:Connect(function() TweenService:Create(minBtn, TWEEN, { BackgroundColor3 = Color3.fromRGB(220, 184, 60) }):Play() end)

    local closeBtn = Instance.new("TextButton"); closeBtn.Text = "✕"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 12; closeBtn.TextColor3 = Color3.new(0)
    closeBtn.BackgroundColor3 = UI.Theme.danger; closeBtn.BorderSizePixel = 0; closeBtn.Size = UDim2.new(0, 18, 0, 18); closeBtn.Position = UDim2.new(1, -30, 0, 11)
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = closeBtn; closeBtn.Parent = header

    -- tab bar
    local tabBar = F(0, 0); tabBar.Name = "TabBar"; tabBar.Size = UDim2.new(1, 0, 0, 40); tabBar.Position = UDim2.new(0, 0, 0, 40); tabBar.BackgroundColor3 = UI.Theme.panel; tabBar.Parent = holder
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal; tabLayout.Padding = UDim.new(0, 6)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; tabLayout.SortOrder = Enum.SortOrder.LayoutOrder; tabLayout.Parent = tabBar
    self.TabBar = tabBar

    -- content
    local content = F(0, 0); content.Name = "Content"; content.Size = UDim2.new(1, 0, 1, -80); content.Position = UDim2.new(0, 0, 0, 80); content.BackgroundColor3 = UI.Theme.bg; content.Parent = holder
    local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10); pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8); pad.Parent = content
    self.TabContent = content

    minBtn.MouseButton1Click:Connect(function()
        self.minimized = not self.minimized
        content.Visible = not self.minimized
        tabBar.Visible = not self.minimized
        holder.Size = self.minimized and UDim2.new(0, W, 0, 40) or UDim2.new(0, W, 0, H)
    end)
    closeBtn.MouseButton1Click:Connect(function() Sl:Destroy() end)

    return self
end

-- ============ ELEMENT BUILDERS ============
function Window:AddTab(name, icon)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Text = (icon or "") .. " " .. name
    tabBtn.Font = Enum.Font.GothamMedium; tabBtn.TextSize = 12; tabBtn.TextColor3 = UI.Theme.sub
    tabBtn.BackgroundColor3 = UI.Theme.panel2; tabBtn.BorderSizePixel = 0
    tabBtn.Size = UDim2.new(0, 64, 0, 28); tabBtn.Position = UDim2.new(0, 0, 0, 6)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = tabBtn
    tabBtn.Parent = self.TabBar
    tabBtn.LayoutOrder = #self.tabs + 1

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.BorderSizePixel = 0
    page.ScrollBarThickness = 4; page.ScrollBarImageColor3 = Color3.new(0.3, 0.3, 0.3)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y; page.Visible = false
    page.Parent = self.TabContent
    local layout = Instance.new("UIListLayout"); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 6); layout.Parent = page
    local ppad = Instance.new("UIPadding"); ppad.PaddingTop = UDim.new(0, 2); ppad.Parent = page

    local tab = { Name = name, Page = page, TabBtn = tabBtn, Layout = layout, elements = {} }
    self.tabs[#self.tabs + 1] = tab

    local function selectTab()
        for _, t in ipairs(self.tabs) do
            t.Page.Visible = false
            TweenService:Create(t.TabBtn, TWEEN, { BackgroundColor3 = UI.Theme.panel2, TextColor3 = UI.Theme.sub }):Play()
        end
        page.Visible = true
        tabBtn.BackgroundColor3 = UI.Theme.accent
        TweenService:Create(tabBtn, TWEEN, { BackgroundColor3 = UI.Theme.accent, TextColor3 = Color3.new(1, 1, 1) }):Play()
        activeTab = tab
    end
    tabBtn.MouseButton1Click:Connect(selectTab)
    tabBtn.MouseEnter:Connect(function() if activeTab ~= tab then TweenService:Create(tabBtn, TWEEN, { BackgroundColor3 = UI.Theme.hover }):Play() end end)
    tabBtn.MouseLeave:Connect(function() if activeTab ~= tab then TweenService:Create(tabBtn, TWEEN, { BackgroundColor3 = UI.Theme.panel2 }):Play() end end)

    if #self.tabs == 1 then selectTab() end

    -- iOS Toggle
    function tab:Toggle(opts)
        local row = F(0); row.Size = UDim2.new(1, 0, 0, 36); row.BackgroundColor3 = Color3.fromRGB(16, 16, 16); row.Parent = page
        local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = row
        row.LayoutOrder = #self.elements + 1
        local l = Lbl(opts.Text, 13, UI.Theme.text); l.Size = UDim2.new(1, -46, 1, 0); l.Parent = row

        -- iOS switch: 42x26 track + 22 knob
        local track = Instance.new("TextButton")
        track.Text = ""; track.BackgroundColor3 = Color3.fromRGB(45, 45, 45); track.BorderSizePixel = 0
        track.Size = UDim2.new(0, 42, 0, 26); track.Position = UDim2.new(1, -50, 0, 5)
        local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1, 0); tc.Parent = track
        track.Parent = row
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 22, 0, 22); knob.Position = UDim2.new(0, 2, 0, 2); knob.BackgroundColor3 = Color3.new(1, 1, 1)
        local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = knob
        knob.Parent = track

        local state = opts.Value or false
        local function update()
            if state then
                TweenService:Create(track, TWEEN, { BackgroundColor3 = UI.Theme.accentOn }):Play()
                TweenService:Create(knob, TWEEN, { Position = UDim2.new(0, 18, 0, 2) }):Play()
            else
                TweenService:Create(track, TWEEN, { BackgroundColor3 = Color3.fromRGB(45, 45, 45) }):Play()
                TweenService:Create(knob, TWEEN, { Position = UDim2.new(0, 2, 0, 2) }):Play()
            end
        end
        track.MouseButton1Click:Connect(function()
            state = not state; update()
            if opts.Callback then opts.Callback(state) end
        end)
        update()
        self.elements[#self.elements + 1] = row
        return { Set = function(v) state = v; update(); if opts.Callback then opts.Callback(v) end end }
    end

    -- Draggable slider with white handle
    function tab:Slider(opts)
        local core = F(0); core.Size = UDim2.new(1, 0, 0, 44); core.BackgroundColor3 = Color3.fromRGB(16, 16, 16); core.Parent = page
        local ccr = Instance.new("UICorner"); ccr.CornerRadius = UDim.new(0, 6); ccr.Parent = core
        core.LayoutOrder = #self.elements + 1

        local l = Lbl(opts.Text, 13, UI.Theme.text); l.Size = UDim2.new(1, -56, 0, 18); l.Parent = core
        local valLbl = Lbl("", 13, UI.Theme.sub); valLbl.Size = UDim2.new(0, 50, 0, 18); valLbl.Position = UDim2.new(1, -56, 0, 0); valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Parent = core

        -- track
        local track = F(0); track.Size = UDim2.new(1, -16, 0, 4); track.Position = UDim2.new(0, 8, 0, 26); track.BackgroundColor3 = Color3.fromRGB(45, 45, 45); track.Parent = core
        local tcc = Instance.new("UICorner"); tcc.CornerRadius = UDim.new(1, 0); tcc.Parent = track
        local fill = F(0); fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundColor3 = UI.Theme.accent; fill.Parent = track
        local fcc = Instance.new("UICorner"); fcc.CornerRadius = UDim.new(1, 0); fcc.Parent = fill

        -- handle
        local handle = Instance.new("Frame")
        handle.Size = UDim2.new(0, 14, 0, 14); handle.Position = UDim2.new(0, 0, 0, -5); handle.BackgroundColor3 = Color3.new(1, 1, 1)
        local hcc = Instance.new("UICorner"); hcc.CornerRadius = UDim.new(1, 0); hcc.Parent = handle
        handle.Parent = track

        local val = opts.Value or opts.Min
        local fmt = opts.Format or function(v) return tostring(v) end
        local trackW = 0
        local function setFromX(xAbs)
            local trackAbs = track.AbsolutePosition
            local w = track.AbsoluteSize.X
            if w <= 0 then return end
            local frac = math.clamp((xAbs - trackAbs.X) / w, 0, 1)
            val = math.round(opts.Min + frac * (opts.Max - opts.Min) / (opts.Step or 1)) * (opts.Step or 1)
            val = math.clamp(val, opts.Min, opts.Max)
            updateVisual()
            if opts.Callback then opts.Callback(val) end
        end
        local function updateVisual()
            local w = track.AbsoluteSize.X or 0
            local frac = (val - opts.Min) / ((opts.Max - opts.Min) or 1)
            fill.Size = UDim2.new(0, w * frac, 1, 0)
            handle.Position = UDim2.new(0, w * frac - 7, 0, -5)
            valLbl.Text = fmt(val)
            trackW = w
        end

        local draggingS = false
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingS = true end
        end)
        handle.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and draggingS then
                setFromX(input.Position.X)
            end
        end)
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingS = true
                setFromX(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(ie)
            if ie.UserInputType == Enum.UserInputType.MouseButton1 then draggingS = false end
        end)
        updateVisual()
        self.elements[#self.elements + 1] = core
        return { Set = function(v) val = math.clamp(v, opts.Min, opts.Max); updateVisual(); if opts.Callback then opts.Callback(val) end end }
    end

    -- Button (full-width, hover anim)
    function tab:Button(opts)
        local b = Instance.new("TextButton")
        b.Text = opts.Text; b.Font = Enum.Font.GothamMedium; b.TextSize = 13; b.TextColor3 = UI.Theme.text
        b.BackgroundColor3 = UI.Theme.panel2; b.BorderSizePixel = 0; b.Size = UDim2.new(1, 0, 0, 36)
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = b
        b.Parent = page; b.LayoutOrder = #self.elements + 1
        b.MouseEnter:Connect(function() TweenService:Create(b, TWEEN, { BackgroundColor3 = UI.Theme.accent }):Play(); TweenService:Create(b, TWEEN, { TextColor3 = Color3.new(1, 1, 1) }):Play() end)
        b.MouseLeave:Connect(function() TweenService:Create(b, TWEEN, { BackgroundColor3 = UI.Theme.panel2 }):Play(); TweenService:Create(b, TWEEN, { TextColor3 = UI.Theme.text }):Play() end)
        b.MouseButton1Click:Connect(function() if opts.Callback then opts.Callback() end end)
        self.elements[#self.elements + 1] = b
        return b
    end

    function tab:Label(txt, color)
        local l = Lbl(txt, 11, color or UI.Theme.sub); l.Parent = page; l.LayoutOrder = #self.elements + 1
        self.elements[#self.elements + 1] = l
        return l
    end

    return tab
end

-- ============ WINDOW & TABS ============
local Hub = Window:New({ Name = "PowerHub", Width = 300, Height = 480 })

local PlayerTab = Hub:AddTab("Move", "🛩 ")
local CombatTab = Hub:AddTab("Combat", "⚔️ ")
local FarmTab   = Hub:AddTab("Farm", "🧲 ")
local EspTab    = Hub:AddTab("Visual", "👁️ ")
local MiscTab   = Hub:AddTab("Misc", "🛠️ ")

-- ============ STATE & CONNECTIONS ============
local state = { fly = false, noclip = false, godmode = false, invisible = false, killaura = false, bring = false, farm = false, espP = false, espI = false, fullbright = false }
local conns = { fly = nil, noclip = nil, godmode = nil, killaura = nil, bring = nil, farm = nil, espP = {}, espI = {}, invis = nil }
local config = { flySpeed = 50, speed = 50, jump = 50, auraRange = 40, auraDamage = 25, bringRange = 60, farmRange = 80 }
local savedPos = nil

-- ============ FEATURES ============
local function setFly(on)
    state.fly = on
    if conns.fly then conns.fly:Disconnect(); conns.fly = nil end
    if not on then return end
    if not char or not hrp then return end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlyBV"; bv.MaxForce = Vector3.new(1e9, 1e9, 1e9); bv.Velocity = Vector3.zero; bv.Parent = hrp
    conns.fly = RunService.RenderStepped:Connect(function()
        if not state.fly or not hrp or not hrp.Parent then return end
        local cam = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
        if not cam then return end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then dir = dir.Unit end
        bv.Velocity = dir * config.flySpeed
    end)
end

local function setNoclip(on)
    state.noclip = on
    if conns.noclip then conns.noclip:Disconnect(); conns.noclip = nil end
    if not on then return end
    conns.noclip = RunService.Stepped:Connect(function()
        if not state.noclip or not char then return end
        for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
    end)
end

local function setGodmode(on)
    state.godmode = on
    if conns.godmode then conns.godmode:Disconnect(); conns.godmode = nil end
    if not on then return end
    conns.godmode = RunService.Heartbeat:Connect(function()
        if not state.godmode then return end
        local hh = getHum(char)
        if hh then hh.Health = hh.MaxHealth; if hh.MaxHealth > 1e9 then hh.MaxHealth = 1e9 end end
    end)
end

local function setInvisibility(on)
    state.invisible = on
    if conns.invis then conns.invis:Disconnect(); conns.invis = nil end
    if on then
        conns.invis = RunService.Heartbeat:Connect(function()
            if not state.invisible or not char then return end
            for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.Transparency = 1 end end
        end)
    else
        if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.Transparency = 0 end end end
    end
end

local function setKillAura(on)
    state.killaura = on
    if conns.killaura then conns.killaura:Disconnect(); conns.killaura = nil end
    if not on then return end
    conns.killaura = RunService.Heartbeat:Connect(function()
        if not state.killaura or not char or not hrp then return end
        for _, t in ipairs(Players:GetPlayers()) do
            if t ~= player then
                local tc = t.Character
                local tr, th = tc and tc:FindFirstChild("HumanoidRootPart"), tc and tc:FindFirstChildOfClass("Humanoid")
                if tr and th and th.Health > 0 and (hrp.Position - tr.Position).Magnitude <= config.auraRange then
                    th:TakeDamage(config.auraDamage)
                end
            end
        end
    end)
end

local function setBring(on)
    state.bring = on
    if conns.bring then conns.bring:Disconnect(); conns.bring = nil end
    if not on then return end
    conns.bring = RunService.Heartbeat:Connect(function()
        if not state.bring or not char or not hrp then return end
        local front = hrp.CFrame.Position + hrp.CFrame.LookVector * 5 + Vector3.new(0, 1, 0)
        local count = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if count >= 40 then break end
            if obj:IsA("BasePart") and not obj.Anchored and obj.Parent ~= char and (hrp.Position - obj.Position).Magnitude <= config.bringRange then
                local model = obj:FindFirstAncestorOfClass("Model")
                if model and model ~= char and not model:FindFirstChildOfClass("Humanoid") then
                    obj.CFrame = CFrame.new(front + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2)))
                    count = count + 1
                end
            end
        end
    end)
end

local function setFarm(on)
    state.farm = on
    if conns.farm then conns.farm:Disconnect(); conns.farm = nil end
    if not on then return end
    conns.farm = RunService.Heartbeat:Connect(function()
        if not state.farm or not char or not hrp then return end
        local best, bestD = nil, config.farmRange
        for _, t in ipairs(Players:GetPlayers()) do
            if t ~= player then
                local tc = t.Character
                local tr, th = tc and tc:FindFirstChild("HumanoidRootPart"), tc and tc:FindFirstChildOfClass("Humanoid")
                if tr and th and th.Health > 0 then
                    local d = (hrp.Position - tr.Position).Magnitude
                    if d < bestD then best, bestD = tr, d end
                end
            end
        end
        if best then hrp.CFrame = CFrame.new(best.Position + Vector3.new(0, 3, 0)) end
    end)
end

local function makeBillboard(target, color, labelText)
    local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local bg = Instance.new("BillboardGui")
    bg.Name = "PowerHubESP_" .. tostring(math.random(1e5))
    bg.Size = UDim2.new(0, 120, 0, 30); bg.MaxDistance = 600; bg.Adornee = root; bg.Parent = root
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 0.3; t.BackgroundColor3 = color; t.TextColor3 = Color3.new(1, 1, 1)
    t.Text = labelText or target.Name; t.Font = Enum.Font.GothamBold; t.TextSize = 13; t.Parent = bg
    return bg
end

local function setESPPlayer(on)
    state.espP = on
    for _, c in ipairs(conns.espP) do if c then c:Disconnect() end end
    conns.espP = {}
    if not on then
        for _, bg in ipairs(Workspace:GetDescendants()) do if bg.Name:match("PowerHubESP") then bg:Destroy() end end
        return
    end
    local add = function(t)
        makeBillboard(t, Color3.new(1, 0.2, 0.2), t.Name)
        table.insert(conns.espP, t.CharacterAdded:Connect(function() task.wait(0.2); makeBillboard(t, Color3.new(1, 0.2, 0.2), t.Name) end))
    end
    for _, t in ipairs(Players:GetPlayers()) do if t ~= player then add(t) end end
    table.insert(conns.espP, Players.PlayerAdded:Connect(function(t) if t ~= player then add(t) end end))
end

local function setESPItems(on)
    state.espI = on
    for _, c in ipairs(conns.espI) do if c then c:Disconnect() end end
    conns.espI = {}
    if not on then
        for _, bg in ipairs(Workspace:GetDescendants()) do if bg.Name:match("PowerHubESP") then bg:Destroy() end end
        return
    end
    conns.espI[1] = RunService.Heartbeat:Connect(function()
        if not state.espI then return end
        local seen = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if seen > 120 then break end
            if (obj:IsA("Tool") or (obj:IsA("BasePart") and obj:FindFirstAncestorOfClass("Tool"))) and obj.Parent ~= char and not obj:FindFirstChild("PowerHubItemTag") then
                seen = seen + 1
                local rootPart = (obj:IsA("Tool") and (obj.Handle or obj:FindFirstChildOfClass("BasePart"))) or obj
                if rootPart then
                    local bg = Instance.new("BillboardGui")
                    bg.Name = "PowerHubESP"; bg.Size = UDim2.new(0, 60, 0, 20); bg.MaxDistance = 500; bg.Adornee = rootPart; bg.Parent = rootPart
                    local t = Instance.new("TextLabel")
                    t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundColor3 = Color3.new(0.2, 0.8, 1); t.TextColor3 = Color3.new(1, 1, 1)
                    t.Text = "ITEM"; t.Font = Enum.Font.GothamBold; t.TextSize = 11; t.Parent = bg
                    local tag = Instance.new("ObjectValue"); tag.Name = "PowerHubItemTag"; tag.Parent = obj
                end
            end
        end
    end)
end

local origLight = {
    Ambient = Lighting.Ambient, Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
    OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows, FogEnd = Lighting.FogEnd,
}
local function setFullbright(on)
    state.fullbright = on
    if on then
        Lighting.Brightness = 3; Lighting.Ambient = Color3.new(1, 1, 1); Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.GlobalShadows = false; Lighting.ClockTime = 12
    else
        Lighting.Brightness = origLight.Brightness; Lighting.Ambient = origLight.Ambient; Lighting.OutdoorAmbient = origLight.OutdoorAmbient
        Lighting.GlobalShadows = origLight.GlobalShadows; Lighting.ClockTime = origLight.ClockTime
    end
end

-- ============ BUILD UI ============
PlayerTab:Label("Movement")
PlayerTab:Toggle({ Text = "Fly", Value = false, Callback = setFly })
PlayerTab:Slider({ Text = "Fly Speed", Min = 10, Max = 200, Step = 5, Value = config.flySpeed, Format = function(v) config.flySpeed = v; return v end })
PlayerTab:Toggle({ Text = "Noclip", Value = false, Callback = setNoclip })
PlayerTab:Slider({ Text = "WalkSpeed", Min = 16, Max = 250, Step = 5, Value = config.speed, Format = function(v) config.speed = v; return v end, Callback = function(v) if hum then hum.WalkSpeed = v end end })
PlayerTab:Slider({ Text = "Jump Power", Min = 50, Max = 400, Step = 10, Value = config.jump, Format = function(v) config.jump = v; return v end, Callback = function(v) if hum then hum.JumpPower = v end end })

CombatTab:Label("Combat")
CombatTab:Toggle({ Text = "Kill Aura", Value = false, Callback = setKillAura })
CombatTab:Slider({ Text = "Range", Min = 10, Max = 200, Step = 5, Value = config.auraRange, Format = function(v) config.auraRange = v; return v end })
CombatTab:Slider({ Text = "Damage", Min = 5, Max = 100, Step = 5, Value = config.auraDamage, Format = function(v) config.auraDamage = v; return v end })
CombatTab:Toggle({ Text = "God Mode", Value = false, Callback = setGodmode })
CombatTab:Toggle({ Text = "Invisibility", Value = false, Callback = setInvisibility })

FarmTab:Label("Farming")
FarmTab:Toggle({ Text = "Bring Items", Value = false, Callback = setBring })
FarmTab:Slider({ Text = "Bring Range", Min = 20, Max = 200, Step = 10, Value = config.bringRange, Format = function(v) config.bringRange = v; return v end })
FarmTab:Toggle({ Text = "Auto Farm", Value = false, Callback = setFarm })
FarmTab:Slider({ Text = "Farm Range", Min = 20, Max = 250, Step = 10, Value = config.farmRange, Format = function(v) config.farmRange = v; return v end })

EspTab:Label("Visuals")
EspTab:Toggle({ Text = "Player ESP", Value = false, Callback = setESPPlayer })
EspTab:Toggle({ Text = "Item ESP", Value = false, Callback = setESPItems })
EspTab:Toggle({ Text = "Fullbright", Value = false, Callback = setFullbright })

MiscTab:Label("Tools")
MiscTab:Button({ Text = "Save Position", Callback = function() if hrp then savedPos = hrp.CFrame; print("[PowerHub] Posisi disimpan") end end })
MiscTab:Button({ Text = "Teleport to Saved", Callback = function() if savedPos and hrp then hrp.CFrame = savedPos end end })

MiscTab:Label("")
MiscTab:Label("v5 • GUI halus • Gunakan di server pribadi.", Color3.fromRGB(110, 110, 110))

print("\n======================================")
print(" 🔮 PowerHub v5 • 99 Nights in the Forest")
print("======================================")
print(" Motion: Fly, Noclip, Speed, Jump")
print(" Combat: Kill Aura, Godmode, Invisible")
print(" Farm: Bring Items, Auto Farm")
print(" Visual: Player ESP, Item ESP, Fullbright")
print("======================================\n")