-- ============================================
--  99 NIGHTS IN THE FOREST - POWER HUB  (ID)
--  Self-contained GUI library (no remote loader)
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
local function getChar()
    return player.Character or player.CharacterAdded:Wait()
end
local function getHRP(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function getHum(char)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local char = getChar()
local hrp = getHRP(char)
local hum = getHum(char)
if not hrp or not hum then
    player.CharacterAdded:Wait()
    char = getChar(); hrp = getHRP(char); hum = getHum(char)
end

-- ============ UI LIBRARY (minimal custom) ============
local UI = {}
UI.Theme = {
    bg = Color3.fromRGB(18, 18, 22),
    panel = Color3.fromRGB(24, 24, 30),
    panel2 = Color3.fromRGB(30, 30, 40),
    accent = Color3.fromRGB(0, 200, 160),
    text = Color3.fromRGB(235, 235, 240),
    danger = Color3.fromRGB(220, 70, 70),
}

local Sl = Instance.new("ScreenGui")
Sl.Name = "PowerHub99"
Sl.ResetOnSpawn = false
Sl.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Sl.Parent = player:WaitForChild("PlayerGui")

-- rounded frame helper
local function F(trans) -- Frame
    local f = Instance.new("Frame")
    f.BackgroundTransparency = trans or 0
    f.BorderSizePixel = 0
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = f
    return f
end

local function Btn(txt, col, colHover)
    local b = Instance.new("TextButton")
    b.Text = txt
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.TextColor3 = UI.Theme.text
    b.BackgroundColor3 = col or UI.Theme.panel2
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = b
    b.MouseEnter:Connect(function() b.BackgroundColor3 = colHover or col:lerp(UI.Theme.text, 0.15) end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = col end)
    return b
end

local function Lbl(txt, size, color)
    local l = Instance.new("TextLabel")
    l.Text = txt; l.Font = Enum.Font.GothamBold; l.TextSize = size or 13
    l.TextColor3 = color or UI.Theme.text; l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = true
    return l
end

local Window = {
    tabs = {}, elements = {}, Elements = {},
    Frame = nil, TabBar = nil, TabContent = nil,
    minimized = false,
}

local activeTab = nil

function Window:New(opts)
    self.Title = opts.Name or "HUB"
    self.Size = opts.Size or UDim2.new(0, 420, 0, 560)

    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.Size = self.Size
    holder.Position = UDim2.new(0, 40, 0.5, -self.Size.Y.Offset / 2)
    holder.BackgroundColor3 = UI.Theme.bg
    holder.BackgroundTransparency = 0.15
    holder.BorderSizePixel = 0
    holder.ClipsDescendants = true
    holder.Parent = Sl
    local outer = Instance.new("UICorner"); outer.CornerRadius = UDim.new(0, 8); outer.Parent = holder
    local stroke = Instance.new("UIStroke"); stroke.Color = UI.Theme.accent; stroke.Thickness = 1.5; stroke.Parent = holder

    self.Frame = holder

    -- drag
    local dragging, dragOff
    holder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragOff = input.Position - holder.AbsolutePosition
        end
    end)
    holder.InputChanged:Connect(function(ic)
        if ic.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            holder.Position = UDim2.new(0, ic.Position.X - dragOff.X, 0, ic.Position.Y - dragOff.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(ie)
        if ie.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- header
    local header = F(0.4); header.Name = "Header"; header.Size = UDim2.new(1, 0, 0, 42); header.Parent = holder
    local shader = F(0); shader.Size = UDim2.new(1, 0, 1, 0); shader.BackgroundColor3 = UI.Theme.panel; shader.Parent = header
    local title = Lbl(" 🔮 " .. self.Title, 16, UI.Theme.text); title.Position = UDim2.new(0, 12, 0, 0); title.Size = UDim2.new(0.7, 0, 1, 0); title.Parent = header

    local minBtn = Btn("─", UI.Theme.panel2); minBtn.Size = UDim2.new(0, 30, 0, 26); minBtn.Position = UDim2.new(1, -70, 0, 8); minBtn.Parent = header
    local closeBtn = Btn("✕", UI.Theme.danger, UI.Theme.danger); closeBtn.Size = UDim2.new(0, 30, 0, 26); closeBtn.Position = UDim2.new(1, -38, 0, 8); closeBtn.Parent = header

    -- tab bar
    local tabBar = F(1); tabBar.Name = "TabBar"; tabBar.Size = UDim2.new(1, 0, 0, 40); tabBar.Position = UDim2.new(0, 0, 0, 42); tabBar.BackgroundColor3 = UI.Theme.panel; tabBar.Parent = holder
    local tabLayout = Instance.new("UIListLayout"); tabLayout.FillDirection = Enum.FillDirection.Horizontal; tabLayout.Padding = UDim.new(0, 4); tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; tabLayout.SortOrder = Enum.SortOrder.LayoutOrder; tabLayout.Parent = tabBar
    tabBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    self.TabBar = tabBar

    -- content
    local content = F(1); content.Name = "Content"; content.Size = UDim2.new(1, 0, 1, -82); content.Position = UDim2.new(0, 0, 0, 82); content.BackgroundColor3 = UI.Theme.panel; content.Parent = holder
    local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10); pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8); pad.Parent = content
    self.TabContent = content

    -- minimize / close
    minBtn.MouseButton1Click:Connect(function()
        self.minimized = not self.minimized
        content.Visible = not self.minimized
        tabBar.Visible = not self.minimized
        holder.Size = self.minimized and UDim2.new(0, 420, 0, 42) or self.Size
    end)
    closeBtn.MouseButton1Click:Connect(function()
        Sl:Destroy()
    end)

    return self
end

-- helpers to add elements (fallback index via metatable-ish)
local ElementBuilder = {}
ElementBuilder.__index = ElementBuilder

function Window:AddTab(name, icon)
    local tabBtn = Btn((icon or "") .. name, UI.Theme.panel2)
    tabBtn.Size = UDim2.new(0, 72, 0, 30)
    tabBtn.Position = UDim2.new(0, 0, 0, 5)
    tabBtn.Parent = self.TabBar
    tabBtn.LayoutOrder = #self.tabs + 1

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 6
    page.ScrollBarImageColor3 = UI.Theme.accent
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = self.TabContent
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = page
    local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 2); pad.PaddingTop = UDim.new(0, 2); pad.Parent = page

    local tab = {
        Name = name, Page = page, Button = tabBtn, Layout = layout,
        elements = {},
    }
    self.tabs[#self.tabs + 1] = tab

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(self.tabs) do
            t.Page.Visible = false
            t.Button.BackgroundColor3 = UI.Theme.panel2
        end
        page.Visible = true
        tabBtn.BackgroundColor3 = UI.Theme.accent
        activeTab = tab
    end)

    if #self.tabs == 1 then tabBtn.MouseButton1Click:Fire() end

    -- builders
    function tab:Toggle(opts)
        local row = F(1); row.Size = UDim2.new(1, 0, 0, 44); row.BackgroundColor3 = UI.Theme.panel2; row.Parent = page
        row.LayoutOrder = #self.elements + 1
        local l = Lbl(opts.Text, 14); l.Size = UDim2.new(1, -64, 1, 0); l.Parent = row
        local sw = Btn("OFF", UI.Theme.panel); sw.Size = UDim2.new(0, 56, 0, 28); sw.Position = UDim2.new(1, -64, 0, 8); sw.Parent = row
        sw.TextColor3 = UI.Theme.text
        local state = opts.Value or false
        local update = function()
            sw.Text = state and "ON" or "OFF"
            sw.BackgroundColor3 = state and UI.Theme.accent or UI.Theme.panel
            sw.TextColor3 = state and UI.Theme.bg or UI.Theme.text
        end
        sw.MouseButton1Click:Connect(function()
            state = not state; update()
            if opts.Callback then opts.Callback(state) end
        end)
        update()
        self.elements[#self.elements + 1] = row
        return { Set = function(v) state = v; update() if opts.Callback then opts.Callback(v) end end }
    end

    function tab:Slider(opts)
        local core = F(1); core.Size = UDim2.new(1, 0, 0, 56); core.BackgroundColor3 = UI.Theme.panel2; core.Parent = page
        core.LayoutOrder = #self.elements + 1
        local l = Lbl(opts.Text, 13); l.Size = UDim2.new(0.6, 0, 0, 20); l.Parent = core
        local valLbl = Lbl("", 14, UI.Theme.accent); valLbl.Size = UDim2.new(0.4, 0, 0, 20); valLbl.Position = UDim2.new(0.6, 0, 0, 0); valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Parent = core
        local minus = Btn("−", UI.Theme.panel); minus.Size = UDim2.new(0, 30, 0, 24); minus.Position = UDim2.new(0, 0, 0, 26); minus.Parent = core
        local plus = Btn("+", UI.Theme.panel); plus.Size = UDim2.new(0, 30, 0, 24); plus.Position = UDim2.new(0, 36, 0, 26); plus.Parent = core
        local val = opts.Value or opts.Min
        local fmt = opts.Format or function(v) return tostring(v) end
        local update = function() valLbl.Text = fmt(val) end
        minus.MouseButton1Click:Connect(function()
            val = math.max(opts.Min, val - (opts.Step or 1)); update()
            if opts.Callback then opts.Callback(val) end
        end)
        plus.MouseButton1Click:Connect(function()
            val = math.min(opts.Max, val + (opts.Step or 1)); update()
            if opts.Callback then opts.Callback(val) end
        end)
        update()
        self.elements[#self.elements + 1] = core
        return { Set = function(v) val = math.clamp(v, opts.Min, opts.Max); update(); if opts.Callback then opts.Callback(val) end end }
    end

    function tab:Button(opts)
        local b = Btn(opts.Text, UI.Theme.accent, UI.Theme.accent:lerp(UI.Theme.text, 0.2))
        b.Size = UDim2.new(1, 0, 0, 40)
        b.TextColor3 = UI.Theme.bg
        b.Parent = page
        b.LayoutOrder = #self.elements + 1
        b.MouseButton1Click:Connect(function() if opts.Callback then opts.Callback() end end)
        self.elements[#self.elements + 1] = b
        return b
    end

    function tab:Label(txt)
        local l = Lbl(txt, 12, Color3.fromRGB(150, 150, 160))
        l.Parent = page
        l.LayoutOrder = #self.elements + 1
        self.elements[#self.elements + 1] = l
        return l
    end

    return tab
end

-- ============ WINDOW & TABS ============
local Hub = Window:New({ Name = "PowerHub • 99 Nights", Size = UDim2.new(0, 420, 0, 560) })

local PlayerTab = Hub:AddTab("Movement", "🚀 ")
local CombatTab = Hub:AddTab("Combat", "⚔️ ")
local FarmTab   = Hub:AddTab("Farm", "🧲 ")
local EspTab    = Hub:AddTab("ESP", "👁️ ")
local MiscTab   = Hub:AddTab("Misc", "🛠️ ")

-- ============ STATE & CONNECTIONS ============
local state = { fly = false, noclip = false, godmode = false, invisible = false, killaura = false, bring = false, farm = false, espP = false, espI = false, fullbright = false }
local conns = { fly = nil, noclip = nil, godmode = nil, killaura = nil, bring = nil, farm = nil, espP = {}, espI = {}, invis = nil }

local config = { flySpeed = 50, speed = 50, jump = 50, auraRange = 40, auraDamage = 25, bringRange = 60, farmRange = 80 }
local savedPos = nil

-- helper to re-acquire char/hrp after death
local function refreshChar(newChr)
    char = newChr
    hrp = getHRP(char); hum = getHum(char)
end
player.CharacterAdded:Connect(refreshChar)

-- ============ FEATURES ============
-- FLY
local function setFly(on, speed)
    state.fly = on
    if conns.fly then conns.fly:Disconnect(); conns.fly = nil end
    if not on then return end
    if not char or not hrp then return end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlyBV"; bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    conns.fly = RunService.RenderStepped:Connect(function()
        local c = char
        if not state.fly then return end
        if not c or not hrp or not hrp.Parent then return end
        local cam = Workspace.CurrentCamera
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

-- NOCLIP
local function setNoclip(on)
    state.noclip = on
    if conns.noclip then conns.noclip:Disconnect(); conns.noclip = nil end
    if not on then return end
    conns.noclip = RunService.Stepped:Connect(function(_, dt)
        if not state.noclip then return end
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end

-- GODMODE
local function setGodmode(on)
    state.godmode = on
    if conns.godmode then conns.godmode:Disconnect(); conns.godmode = nil end
    if not on then return end
    local h = hum
    conns.godmode = RunService.Heartbeat:Connect(function()
        if not state.godmode then return end
        local ch = char; local hh = getHum(ch)
        if ch and hh then
            if hh.MaxHealth > 1e9 then hh.MaxHealth = 1e9 end
            hh.Health = hh.MaxHealth
        end
    end)
end

-- INVISIBILITY
local function setInvisibility(on)
    state.invisible = on
    if conns.invis then conns.invis:Disconnect(); conns.invis = nil end
    if on then
        conns.invis = RunService.Heartbeat:Connect(function()
            if not state.invisible then return end
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.Transparency = 1 end end
        end)
    else
        if char then
            for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.Transparency = 0 end end
        end
    end
end

-- KILL AURA
local function setKillAura(on)
    state.killaura = on
    if conns.killaura then conns.killaura:Disconnect(); conns.killaura = nil end
    if not on then return end
    conns.killaura = RunService.Heartbeat:Connect(function()
        if not state.killaura or not char or not hrp then return end
        for _, t in ipairs(Players:GetPlayers()) do
            if t ~= player then
                local tc = t.Character
                local tr = tc and tc:FindFirstChild("HumanoidRootPart")
                local th = tc and tc:FindFirstChildOfClass("Humanoid")
                if tr and th and th.Health > 0 then
                    if (hrp.Position - tr.Position).Magnitude <= config.auraRange then
                        th:TakeDamage(config.auraDamage)
                    end
                end
            end
        end
    end)
end

-- BRING ITEMS (bring collectibles near player)
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
            if obj:IsA("BasePart") and obj.Anchored == false and obj.Parent ~= char then
                if (hrp.Position - obj.Position).Magnitude <= config.bringRange then
                    -- roughly collectible: not part of an enemy/player model that's alive
                    local model = obj:FindFirstAncestorOfClass("Model")
                    if model and model ~= char then
                        local isCharModel = model:FindFirstChildOfClass("Humanoid") ~= nil
                        if not isCharModel then
                            obj.CFrame = CFrame.new(front + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2)))
                            count = count + 1
                        end
                    end
                end
            end
        end
    end)
end

-- AUTO FARM (teleport to nearest enemy & attack)
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
                local tr = tc and tc:FindFirstChild("HumanoidRootPart")
                local th = tc and tc:FindFirstChildOfClass("Humanoid")
                if tr and th and th.Health > 0 then
                    local d = (hrp.Position - tr.Position).Magnitude
                    if d < bestD then best, bestD = tr, d end
                end
            end
        end
        if best then hrp.CFrame = CFrame.new(best.Position + Vector3.new(0, 3, 0)) end
    end)
end

-- ESP helpers
local function makeBillboard(target, color, labelText)
    local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local bg = Instance.new("BillboardGui")
    bg.Name = "PowerHubESP_" .. tostring(math.random(1e5))
    bg.Size = UDim2.new(0, 120, 0, 30)
    bg.MaxDistance = 600; bg.Adornee = root
    bg.Parent = root
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 0.3
    t.BackgroundColor3 = color; t.TextColor3 = Color3.new(1, 1, 1)
    t.Text = labelText or target.Name; t.Font = Enum.Font.GothamBold; t.TextSize = 13
    t.Parent = bg
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
        local chConn = t.CharacterAdded:Connect(function()
            task.wait(0.2)
            makeBillboard(t, Color3.new(1, 0.2, 0.2), t.Name)
        end)
        table.insert(conns.espP, chConn)
    end
    for _, t in ipairs(Players:GetPlayers()) do if t ~= player then add(t) end end
    table.insert(conns.espP, Players.PlayerAdded:Connect(function(t) if t ~= player then add(t) end end))
end

-- ESP ITEMS (highlight Tools / named collectibles)
local function setESPItems(on)
    state.espI = on
    for _, c in ipairs(conns.espI) do if c then c:Disconnect() end end
    conns.espI = {}
    if not on then
        for _, bg in ipairs(Workspace:GetDescendants()) do if bg.Name:match("PowerHubESP") then bg:Destroy() end end
        return
    end
    conns.espI[#conns.espI + 1] = RunService.Heartbeat:Connect(function()
        if not state.espI then return end
        local seen = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if seen > 120 then break end
            if (obj:IsA("Tool") or (obj:IsA("BasePart") and obj:FindFirstAncestorOfClass("Tool"))) and obj.Parent ~= char then
                if not obj:FindFirstChild("PowerHubItemTag") then
                    seen = seen + 1
                    local rootPart = (obj:IsA("Tool") and (obj.Handle or obj:FindFirstChildOfClass("BasePart"))) or obj
                    if rootPart then
                        local bg = Instance.new("BillboardGui")
                        bg.Name = "PowerHubESP"; bg.Size = UDim2.new(0, 60, 0, 20); bg.MaxDistance = 500
                        bg.Adornee = rootPart; bg.Parent = rootPart
                        local t = Instance.new("TextLabel")
                        t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundColor3 = Color3.new(0.2, 0.8, 1)
                        t.TextColor3 = Color3.new(1, 1, 1); t.Text = "ITEM"; t.Font = Enum.Font.GothamBold; t.TextSize = 11
                        t.Parent = bg
                        local tag = Instance.new("ObjectValue"); tag.Name = "PowerHubItemTag"; tag.Parent = obj
                    end
                end
            end
        end
    end)
end

-- FULLBRIGHT
local origLight = {
    Ambient = Lighting.Ambient, Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime, OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows, FogEnd = Lighting.FogEnd,
}
local function setFullbright(on)
    state.fullbright = on
    if on then
        Lighting.Brightness = 3; Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1); Lighting.GlobalShadows = false
        Lighting.ClockTime = 12
    else
        Lighting.Brightness = origLight.Brightness; Lighting.Ambient = origLight.Ambient
        Lighting.OutdoorAmbient = origLight.OutdoorAmbient; Lighting.GlobalShadows = origLight.GlobalShadows
        Lighting.ClockTime = origLight.ClockTime
    end
end

-- ============ BUILD UI ============
PlayerTab:Label("— Movement & Character —")

local tFly = PlayerTab:Toggle({ Text = "🚀 Fly", Value = false, Callback = setFly })
PlayerTab:Slider({ Text = "Fly Speed", Min = 10, Max = 200, Step = 5, Value = config.flySpeed, Format = function(v) config.flySpeed = v; return v .. " u/s" end })
PlayerTab:Toggle({ Text = "🧊 Noclip", Value = false, Callback = setNoclip })

PlayerTab:Slider({ Text = "Speed (WalkSpeed)", Min = 16, Max = 250, Step = 5, Value = config.speed, Format = function(v) config.speed = v; return v end, Callback = function(v)
    if hum then hum.WalkSpeed = v end
end })
PlayerTab:Slider({ Text = "Jump Power", Min = 50, Max = 400, Step = 10, Value = config.jump, Format = function(v) config.jump = v; return v end, Callback = function(v)
    if hum then hum.JumpPower = v end
end })
PlayerTab:Button({ Text = "🔄 Reset Movement", Callback = function()
    if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
    tFly:Set(false)
end })

CombatTab:Label("— Combat —")
CombatTab:Toggle({ Text = "⚔️ Kill Aura", Value = false, Callback = setKillAura })
CombatTab:Slider({ Text = "Range", Min = 10, Max = 200, Step = 5, Value = config.auraRange, Format = function(v) config.auraRange = v; return v .. " studs" end })
CombatTab:Slider({ Text = "Damage per tick", Min = 5, Max = 100, Step = 5, Value = config.auraDamage, Format = function(v) config.auraDamage = v; return v end })
CombatTab:Toggle({ Text = "🛡️ God Mode", Value = false, Callback = setGodmode })
CombatTab:Toggle({ Text = "👻 Invisibility", Value = false, Callback = setInvisibility })

FarmTab:Label("— Farming & Collection —")
FarmTab:Toggle({ Text = "🧲 Bring Items", Value = false, Callback = setBring })
FarmTab:Slider({ Text = "Bring Range", Min = 20, Max = 200, Step = 10, Value = config.bringRange, Format = function(v) config.bringRange = v; return v .. " studs" end })
FarmTab:Toggle({ Text = "🌾 Auto Farm", Value = false, Callback = setFarm })
FarmTab:Slider({ Text = "Farm Range", Min = 20, Max = 250, Step = 10, Value = config.farmRange, Format = function(v) config.farmRange = v; return v .. " studs" end })

EspTab:Label("— Visuals —")
EspTab:Toggle({ Text = "👤 Player ESP", Value = false, Callback = setESPPlayer })
EspTab:Toggle({ Text = "📦 Item ESP", Value = false, Callback = setESPItems })
EspTab:Toggle({ Text = "🔆 Fullbright", Value = false, Callback = setFullbright })

MiscTab:Label("— Teleport & Tools —")
MiscTab:Button({ Text = "📍 Save Position", Callback = function()
    if hrp then savedPos = hrp.CFrame; print("[PowerHub] Posisi disimpan") end
end })
MiscTab:Button({ Text = "🚀 Teleport to Saved", Callback = function()
    if savedPos and hrp then hrp.CFrame = savedPos end
end })
MiscTab:Button({ Text = "🪀 Click-to-TP (hold) OFF", Callback = function()
    -- placeholder note: disabled by default (avoid accidental TP)
    print("[PowerHub] Click-to-TP disabled. Gunakan tombol teleport.")
end })

MiscTab:Label("")
MiscTab:Label("✔ Semua fitur generik & berdiri sendiri (tanpa key / remote loader).")
MiscTab:Label("⚠ Gunakan di server pribadi untuk hindari deteksi/ban.")

-- ============ HELPER PRINT ============
print("\n======================================")
print(" 🔮 PowerHub • 99 Nights in the Forest")
print("======================================")
print(" Motion: Fly, Noclip, Speed, Jump")
print(" Combat: Kill Aura, Godmode, Invisible")
print(" Farm: Bring Items, Auto Farm")
print(" Visual: Player ESP, Item ESP, Fullbright")
print("======================================\n")

-- restore defaults at spawn
player.CharacterAdded:Connect(function(ch) refreshChar(ch) end)