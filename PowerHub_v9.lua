--[[
    PowerHub v9 — 99 Nights in the Forest
    UI: Rayfield Interface Suite
    Features: Auto Campfire, Auto Craft, Auto Gold, Auto Chop,
              Auto Cook, Auto Crockpot, Auto Stronghold,
              Kill Aura, Anti AFK, Fly, NoClip, ESP
    Executor: Real (Luau)
]]

-- ═══════════════════════════════════════════════════════════
-- LOAD RAYFIELD
-- ═══════════════════════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ═══════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LP = Players.LocalPlayer
local Char = LP.Character or LP.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")
local Hum = Char:WaitForChild("Humanoid")

LP.CharacterAdded:Connect(function(c)
    Char = c
    HRP = c:WaitForChild("HumanoidRootPart")
    Hum = c:WaitForChild("Humanoid")
end)

-- ═══════════════════════════════════════════════════════════
-- REMOTE HELPER
-- ═══════════════════════════════════════════════════════════
local function getRemote(name, class)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == name and v:IsA(class or "RemoteEvent") then return v end
    end
end

local function fire(name, ...)
    local r = getRemote(name, "RemoteEvent")
    if r then r:FireServer(...) end
end

local function invoke(name, ...)
    local r = getRemote(name, "RemoteFunction")
    if r then return r:InvokeServer(...) end
end

-- ═══════════════════════════════════════════════════════════
-- FEATURE STATES
-- ═══════════════════════════════════════════════════════════
local State = {
    AutoCampfire = false, AutoCraft = false, AutoGold = false,
    AutoChop = false, AutoCook = false, AutoCrockpot = false,
    AutoStronghold = false, KillAura = false, AntiAFK = false,
    Fly = false, NoClip = false, ESP = false, GodMode = false,
}

local Settings = {
    CampfireFuel = "Logs",
    -- ALL fuel items from wiki
    FuelItems = {"Log", "Logs", "Coal", "Fuel Canister", "Fuel Canister",
        "Oil Barrel", "Biofuel", "Wood", "Sticks", "Stick", "Branch",
        "Wooden Chair", "Wooden Table", "Wooden Plank", "Plank",
        "Super Log", "Charcoal", "Paper", "Cloth", "Leather",
        "Glowing Pumpkin", "Pumpkin"},
    -- ALL cookable raw food from wiki
    CookList = {"Raw Morsel", "Morsel", "Raw Steak", "Steak",
        "Raw Fish", "Fish", "Raw Monster Meat", "Monster Meat",
        "Raw Kelp", "Kelp", "Berry", "Carrot", "Mushroom",
        "Egg", "Raw Egg", "Raw Frog Leg", "Frog Leg",
        "Raw Bunny Leg", "Bunny Leg", "Raw Wolf Leg", "Wolf Leg",
        "Cactus Fruit", "Pumpkin"},
    ChopRange = 15, KillAuraRange = 20, FlySpeed = 50,
    GoldRange = 50, StrongholdRange = 100, AntiAFKInterval = 120,
}

-- ═══════════════════════════════════════════════════════════
-- AUTO CAMPFIRE — drag ALL fuel items to campfire
-- ═══════════════════════════════════════════════════════════
local function isFuel(name)
    local n = name:lower()
    for _, f in pairs(Settings.FuelItems) do
        if n:find(f:lower()) then return true end
    end
    return false
end

local function findCampfire()
    -- Search multiple locations
    local searchPaths = {
        workspace:FindFirstChild("Map"),
        workspace.Map and workspace.Map:FindFirstChild("Campground"),
    }
    for _, parent in pairs(searchPaths) do
        if parent then
            for _, obj in pairs(parent:GetDescendants()) do
                if obj:IsA("Model") then
                    local n = obj.Name:lower()
                    if n:find("campfire") or n:find("camp fire") or n:find("fire")
                        or n:find("bonfire") or n:find("flame") then
                        -- Must be a structure, not an effect
                        local part = obj:FindFirstChildWhichIsA("BasePart")
                        if part then return obj end
                    end
                end
            end
        end
    end
    return nil
end

task.spawn(function()
    while true do
        if State.AutoCampfire then
            pcall(function()
                local cf = findCampfire()
                if not cf then return end

                -- Get campfire position (use PrimaryPart or first BasePart)
                local cfPart = cf.PrimaryPart or cf:FindFirstChildWhichIsA("BasePart")
                if not cfPart then return end
                local cfPos = cfPart.Position

                -- Scan ALL descendants for fuel items
                for _, item in pairs(workspace:GetDescendants()) do
                    if not State.AutoCampfire then break end
                    if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") then
                        if isFuel(item.Name) then
                            local itemPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                            if itemPart then
                                local d = (itemPart.Position - HRP.Position).Magnitude
                                -- Pick up from reasonable distance
                                if d < 60 then
                                    -- Method 1: Drag + Throw at campfire
                                    pcall(function()
                                        fire("RequestStartDraggingItem", item)
                                        task.wait(0.4)
                                        fire("RequestThrowItem", cfPos)
                                    end)
                                    task.wait(0.6)

                                    -- Method 2: If drag failed, try proximity-based add
                                    pcall(function()
                                        fire("RequestGiveItemToNPC", cf, item)
                                    end)
                                    task.wait(0.3)

                                    -- Method 3: Try direct fuel add
                                    pcall(function()
                                        fire("AddFuel", item)
                                        fire("FuelCampfire", item)
                                    end)
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO CRAFT
-- ═══════════════════════════════════════════════════════════
local Recipes = {"Axe", "Iron Axe", "Gold Axe", "Torch", "Flashlight",
    "Bandage", "Medkit", "Armor", "Iron Armor", "Spear", "Iron Spear",
    "Arrow", "Fire Arrow", "Stone Wall", "Wood Wall"}

task.spawn(function()
    while true do
        if State.AutoCraft then
            pcall(function()
                for _, st in pairs(workspace:GetDescendants()) do
                    if not State.AutoCraft then break end
                    if st:IsA("Model") and st.Name:lower():find("craft") then
                        local d = (st:GetPivot().Position - HRP.Position).Magnitude
                        if d < 30 then
                            for _, r in pairs(Recipes) do
                                pcall(function() fire("RequestCraft", r) end)
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(3)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO GOLD
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AutoGold then
            pcall(function()
                for _, item in pairs(workspace:GetDescendants()) do
                    if not State.AutoGold then break end
                    if item:IsA("Model") or item:IsA("Part") then
                        local n = item.Name:lower()
                        if n:find("gold") or n:find("coin") or n:find("diamond") or n:find("gem") then
                            local pos = item:IsA("Model") and item:GetPivot().Position or item.Position
                            local d = (pos - HRP.Position).Magnitude
                            if d < Settings.GoldRange then
                                pcall(function()
                                    if item:IsA("Model") then
                                        item:SetPrimaryPartCFrame(HRP.CFrame)
                                    else
                                        item.CFrame = HRP.CFrame
                                    end
                                end)
                                task.wait(0.1)
                            elseif d < Settings.GoldRange * 3 then
                                pcall(function()
                                    fire("RequestStartDraggingItem", item)
                                end)
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO CHOP — NO TELEPORT, auto-damage when player is near
-- ═══════════════════════════════════════════════════════════
local treePatterns = {"tree", "log", "birch", "pine", "oak", "dead tree",
    "stump", "trunk", "branch", "bush", "shrub", "brightwood", "elm",
    "willow", "cedar", "redwood", "sapling", "foliage"}

task.spawn(function()
    while true do
        if State.AutoChop then
            pcall(function()
                for _, obj in pairs(workspace:GetDescendants()) do
                    if not State.AutoChop then break end
                    if obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") then
                        local n = obj.Name:lower()
                        local isTree = false
                        for _, pat in pairs(treePatterns) do
                            if n:find(pat) then isTree = true; break end
                        end

                        if isTree then
                            local pivot = obj:GetPivot()
                            local d = (pivot.Position - HRP.Position).Magnitude

                            -- Only chop if player is ALREADY within range (no teleport!)
                            if d <= Settings.ChopRange then
                                -- Auto-equip axe if needed
                                pcall(function()
                                    if not Character:FindFirstChildWhichIsA("Tool") then
                                        -- Find axe in Backpack
                                        local bp = LP:FindFirstChild("Backpack")
                                        if bp then
                                            for _, tool in pairs(bp:GetChildren()) do
                                                if tool:IsA("Tool") and tool.Name:lower():find("axe") then
                                                    Hum:EquipTool(tool)
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end)
                                task.wait(0.1)

                                -- Damage the tree via remote
                                pcall(function() fire("ToolDamageObject", obj) end)
                                task.wait(0.3)

                                -- Also activate tool for animation
                                pcall(function()
                                    local tool = Character:FindFirstChildWhichIsA("Tool")
                                    if tool then tool:Activate() end
                                end)
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO COOK — teleport raw food near campfire to cook
-- ═══════════════════════════════════════════════════════════
local function isCookable(name)
    local n = name:lower()
    for _, cn in pairs(Settings.CookList) do
        if n:find(cn:lower()) then return true end
    end
    return false
end

task.spawn(function()
    while true do
        if State.AutoCook then
            pcall(function()
                local cf = findCampfire()
                if not cf then return end
                local cfPart = cf.PrimaryPart or cf:FindFirstChildWhichIsA("BasePart")
                if not cfPart then return end
                local fp = cfPart.Position

                for _, item in pairs(workspace:GetDescendants()) do
                    if not State.AutoCook then break end
                    if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") then
                        if isCookable(item.Name) then
                            local itemPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                            if itemPart then
                                local d = (itemPart.Position - HRP.Position).Magnitude
                                if d < 60 then
                                    pcall(function()
                                        -- Teleport food to campfire position (above flames)
                                        item:SetPrimaryPartCFrame(CFrame.new(fp + Vector3.new(0, 4, 0)))
                                        task.wait(0.4)
                                        fire("RequestCookItem", item)
                                        fire("CookItem", item)
                                    end)
                                    task.wait(0.6)
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO CROCKPOT
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AutoCrockpot then
            pcall(function()
                -- Find crockpot near campfire area
                local cp = nil
                local searchArea = workspace:FindFirstChild("Map")
                if searchArea then
                    for _, obj in pairs(searchArea:GetDescendants()) do
                        if obj:IsA("Model") and obj.Name:lower():find("crock") then
                            cp = obj; break
                        end
                    end
                end
                if not cp then return end
                local cpp = cp.PrimaryPart or cp:FindFirstChildWhichIsA("BasePart")
                if not cpp then return end
                local cpPos = cpp.Position

                local ings = {"Morsel", "Steak", "Monster Meat", "Fish", "Kelp",
                    "Berry", "Carrot", "Mushroom", "Egg", "Frog Leg",
                    "Bunny Leg", "Wolf Leg", "Cactus Fruit", "Pumpkin"}
                for _, item in pairs(workspace:GetDescendants()) do
                    if not State.AutoCrockpot then break end
                    if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") then
                        local n = item.Name:lower()
                        for _, ing in pairs(ings) do
                            if n:find(ing:lower()) then
                                local d = (item:GetPivot().Position - HRP.Position).Magnitude
                                if d < 60 then
                                    pcall(function()
                                        fire("RequestStartDraggingItem", item)
                                        task.wait(0.4)
                                        fire("RequestGiveItemToNPC", cp, item)
                                        fire("RequestThrowItem", cpPos)
                                    end)
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1.5)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO STRONGHOLD
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AutoStronghold then
            pcall(function()
                for _, obj in pairs(workspace.Map:GetDescendants()) do
                    if not State.AutoStronghold then break end
                    if obj:IsA("Model") and (obj.Name:lower():find("stronghold") or obj.Name:lower():find("raid") or obj.Name:lower():find("boss")) then
                        local p = obj:GetPivot()
                        local d = (p.Position - HRP.Position).Magnitude

                        if d > Settings.StrongholdRange then
                            pcall(function() fire("RequestTeleport", p.Position) end)
                            HRP.CFrame = p * CFrame.new(0, 5, 0)
                            task.wait(2)
                        end

                        for _, en in pairs(workspace:GetDescendants()) do
                            if en:IsA("Model") and en:FindFirstChildWhichIsA("Humanoid") then
                                local eh = en:FindFirstChildWhichIsA("Humanoid")
                                local er = en:FindFirstChild("HumanoidRootPart") or en:FindFirstChildWhichIsA("BasePart")
                                if eh and eh.Health > 0 and er then
                                    local ed = (er.Position - HRP.Position).Magnitude
                                    if ed < Settings.KillAuraRange then
                                        pcall(function()
                                            HRP.CFrame = er.CFrame * CFrame.new(0, 0, 3)
                                            task.wait(0.05)
                                            fire("ToolDamageObject", en)
                                        end)
                                        task.wait(0.15)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- KILL AURA
-- ═══════════════════════════════════════════════════════════
local Hostiles = {"wolf", "bear", "deer", "mammoth", "fox", "polar", "alpha", "entity", "hostile", "monster", "spider", "snake", "bat", "zombie"}

task.spawn(function()
    while true do
        if State.KillAura then
            pcall(function()
                for _, e in pairs(workspace:GetDescendants()) do
                    if not State.KillAura then break end
                    if e:IsA("Model") then
                        local h = e:FindFirstChildWhichIsA("Humanoid")
                        local r = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChildWhichIsA("BasePart")
                        if h and h.Health > 0 and r then
                            local n = e.Name:lower()
                            for _, ho in pairs(Hostiles) do
                                if n:find(ho) and (r.Position - HRP.Position).Magnitude < Settings.KillAuraRange then
                                    pcall(function() fire("ToolDamageObject", e) end)
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.3)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- ANTI AFK
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AntiAFK then
            pcall(function()
                local VU = game:GetService("VirtualUser")
                VU:CaptureController()
                VU:ClickButton2(Vector2.new())
            end)
            pcall(function() fire("RequestBroadcastPing") end)
            pcall(function()
                HRP.CFrame = HRP.CFrame * CFrame.new(0, 0.1, 0)
                task.wait(0.1)
                HRP.CFrame = HRP.CFrame * CFrame.new(0, -0.1, 0)
            end)
        end
        task.wait(Settings.AntiAFKInterval)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- GOD MODE — prevent health decrease
-- ═══════════════════════════════════════════════════════════
local godModeConn = nil

local function enableGodMode()
    if godModeConn then pcall(function() godModeConn:Disconnect() end) end
    godModeConn = Hum.HealthChanged:Connect(function()
        if State.GodMode and Hum.Health < Hum.MaxHealth then
            Hum.Health = Hum.MaxHealth
        end
    end)
    -- Also set max health immediately
    pcall(function() Hum.Health = Hum.MaxHealth end)
end

local function disableGodMode()
    if godModeConn then
        pcall(function() godModeConn:Disconnect() end)
        godModeConn = nil
    end
end

-- Re-hook on respawn
LP.CharacterAdded:Connect(function(c)
    if State.GodMode then
        task.wait(1)
        enableGodMode()
    end
end)

-- ═══════════════════════════════════════════════════════════
-- FLY
-- ═══════════════════════════════════════════════════════════
local flyBV, flyBG

RunService.Heartbeat:Connect(function()
    if State.Fly then
        if not flyBV then
            flyBV = Instance.new("BodyVelocity")
            flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            flyBV.Velocity = Vector3.zero
            flyBV.Parent = HRP
        end
        if not flyBG then
            flyBG = Instance.new("BodyGyro")
            flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            flyBG.P = 9e4
            flyBG.Parent = HRP
        end
        local cam = workspace.CurrentCamera.CFrame
        local dir = Vector3.zero
        local spd = Settings.FlySpeed
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        flyBV.Velocity = dir * spd
        flyBG.CFrame = cam
    else
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- NOCLIP
-- ═══════════════════════════════════════════════════════════
RunService.Stepped:Connect(function()
    if State.NoClip and Char then
        for _, p in pairs(Char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- ESP ENGINE
-- ═══════════════════════════════════════════════════════════
local espObjs = {}

-- Sub-category toggles for ESP
State.ESP_Players = false
State.ESP_Gold = false
State.ESP_Enemies = false
State.ESP_Friendlies = false
State.ESP_Items = false
State.ESP_Kids = false
State.ESP_Distance = true  -- show distance by default

-- Clear ALL ESP objects (called when ESP master is off or refresh)
local function clearAllESP()
    for obj, bb in pairs(espObjs) do
        pcall(function() if bb and bb.Parent then bb:Destroy() end end)
    end
    espObjs = {}
end

-- Remove stale ESP entries (object destroyed or nil parent)
local function cleanStaleESP()
    for obj, bb in pairs(espObjs) do
        if not obj or not obj.Parent or (obj:IsA("BasePart") and not obj.Parent) then
            pcall(function() if bb and bb.Parent then bb:Destroy() end end)
            espObjs[obj] = nil
        end
    end
end

-- Create BillboardGui ESP on a part
local function mkBillboard(part, col, lines)
    if not part then return end
    -- If this part already has an ESP, destroy old one first (for HP updates)
    if espObjs[part] then
        pcall(function() espObjs[part]:Destroy() end)
        espObjs[part] = nil
    end

    local bb = Instance.new("BillboardGui")
    bb.Name = "PH_ESP"
    bb.Size = UDim2.new(0, 220, 0, 0)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.Adornee = part

    -- Auto-size height based on number of lines
    local lineH = 16
    local totalH = #lines * lineH + 8
    bb.Size = UDim2.new(0, 220, 0, totalH)

    for i, line in ipairs(lines) do
        local lbl = Instance.new("TextLabel")
        lbl.Name = "Line" .. i
        lbl.Size = UDim2.new(1, -8, 0, lineH)
        lbl.Position = UDim2.new(0, 4, 0, (i - 1) * lineH + 4)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = line.Color or col
        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        lbl.TextStrokeTransparency = 0.2
        lbl.TextScaled = false
        lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = line.Align or Enum.TextXAlignment.Left
        lbl.Text = line.Text or ""
        lbl.Parent = bb

        -- Optional health bar (for entities)
        if line.HealthBar then
            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(1, -8, 0, 4)
            barBg.Position = UDim2.new(0, 4, 0, (i - 1) * lineH + 4 + lineH - 2)
            barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            barBg.BorderSizePixel = 0
            barBg.Parent = bb

            local barFill = Instance.new("Frame")
            barFill.Size = UDim2.new(line.HealthPct or 1, 0, 1, 0)
            barFill.BackgroundColor3 = line.HealthColor or col
            barFill.BorderSizePixel = 0
            barFill.Parent = barBg
        end
    end

    bb.Parent = part
    espObjs[part] = bb
end

-- Helper: format distance
local function distStr(from, to)
    if not from or not to then return "" end
    local d = (from - to).Magnitude
    if d < 1 then return "[0m]" end
    if d < 100 then return string.format("[%.0fm]", d) end
    return string.format("[%.0fm]", d)
end

-- Helper: health color (green→yellow→red)
local function hpColor(pct)
    if pct > 0.5 then return Color3.fromRGB(0, 255, 80)
    elseif pct > 0.25 then return Color3.fromRGB(255, 200, 0)
    else return Color3.fromRGB(255, 50, 30) end
end

-- Child names for Kid ESP
local KidNames = {"dino", "squid", "kraken", "koala"}

-- Item name patterns for Item ESP
local ItemPatterns = {"morsel", "steak", "fish", "kelp", "berry", "carrot",
    "mushroom", "egg", "meat", "coal", "log", "iron", "gold bar",
    "stone", "scrap", "wood", "stick"}

-- ═══════════════════════════════════════════════════════════
-- ESP MAIN LOOP
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        -- ALWAYS clean stale entries even when master ESP is off
        cleanStaleESP()

        if State.ESP then
            pcall(function()
                local myPos = HRP.Position

                -- ── PLAYER ESP ──
                if State.ESP_Players then
                    for _, plr in pairs(Players:GetPlayers()) do
                        if plr ~= LP and plr.Character then
                            local root = plr.Character:FindFirstChild("HumanoidRootPart")
                            local hum = plr.Character:FindFirstChildWhichIsA("Humanoid")
                            if root and hum then
                                local lines = {{Text = plr.Name, Color = Color3.fromRGB(0, 255, 0)}}
                                if State.ESP_Distance then
                                    table.insert(lines, {Text = distStr(myPos, root.Position), Color = Color3.fromRGB(200, 200, 200), Align = Enum.TextXAlignment.Right})
                                end
                                -- Health bar
                                local hpPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                                table.insert(lines, {Text = string.format("HP %d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth)), Color = hpColor(hpPct), HealthBar = true, HealthPct = hpPct, HealthColor = hpColor(hpPct)})
                                mkBillboard(root, Color3.fromRGB(0, 255, 0), lines)
                            end
                        end
                    end
                else
                    -- Remove player ESP entries
                    for obj, bb in pairs(espObjs) do
                        if obj and obj.Parent then
                            local isPlayerRoot = false
                            for _, plr in pairs(Players:GetPlayers()) do
                                if plr ~= LP and plr.Character and obj == plr.Character:FindFirstChild("HumanoidRootPart") then
                                    isPlayerRoot = true; break
                                end
                            end
                            if isPlayerRoot then pcall(function() bb:Destroy() end); espObjs[obj] = nil end
                        end
                    end
                end

                -- ── GOLD / DIAMOND ESP ──
                if State.ESP_Gold then
                    for _, item in pairs(workspace:GetDescendants()) do
                        if item:IsA("Model") then
                            local n = item.Name:lower()
                            if n:find("gold") or n:find("diamond") or n:find("coin") or n:find("gem") or n:find("currency") then
                                local root = item:FindFirstChildWhichIsA("BasePart")
                                if root then
                                    local lines = {{Text = item.Name, Color = Color3.fromRGB(255, 215, 0)}}
                                    if State.ESP_Distance then
                                        table.insert(lines, {Text = distStr(myPos, root.Position), Color = Color3.fromRGB(200, 200, 200), Align = Enum.TextXAlignment.Right})
                                    end
                                    mkBillboard(root, Color3.fromRGB(255, 215, 0), lines)
                                end
                            end
                        end
                    end
                end

                -- ── ENEMY ESP ──
                if State.ESP_Enemies then
                    for _, e in pairs(workspace:GetDescendants()) do
                        if e:IsA("Model") and e:FindFirstChildWhichIsA("Humanoid") then
                            local name = e.Name:lower()
                            local isHostile = false
                            for _, h in pairs(Hostiles) do
                                if name:find(h) then isHostile = true; break end
                            end
                            if isHostile then
                                local root = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChildWhichIsA("BasePart")
                                local hum = e:FindFirstChildWhichIsA("Humanoid")
                                if root and hum then
                                    local hpPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                                    local lines = {
                                        {Text = e.Name, Color = Color3.fromRGB(255, 60, 40)},
                                        {Text = string.format("HP %d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth)), Color = hpColor(hpPct), HealthBar = true, HealthPct = hpPct, HealthColor = hpColor(hpPct)},
                                    }
                                    if State.ESP_Distance then
                                        table.insert(lines, {Text = distStr(myPos, root.Position), Color = Color3.fromRGB(255, 150, 150), Align = Enum.TextXAlignment.Right})
                                    end
                                    mkBillboard(root, Color3.fromRGB(255, 60, 40), lines)
                                end
                            end
                        end
                    end
                else
                    for obj, bb in pairs(espObjs) do
                        if obj and obj.Parent then
                            local isH = false
                            for _, e in pairs(workspace:GetDescendants()) do
                                if e:IsA("Model") and (obj == e:FindFirstChild("HumanoidRootPart") or obj == e:FindFirstChildWhichIsA("BasePart")) then
                                    local n = e.Name:lower()
                                    for _, h in pairs(Hostiles) do if n:find(h) then isH = true; break end end
                                end
                            end
                            if isH then pcall(function() bb:Destroy() end); espObjs[obj] = nil end
                        end
                    end
                end

                -- ── FRIENDLY / NPC ESP ──
                if State.ESP_Friendlies then
                    for _, e in pairs(workspace:GetDescendants()) do
                        if e:IsA("Model") and e:FindFirstChildWhichIsA("Humanoid") then
                            local name = e.Name:lower()
                            local isFriendly = false
                            -- Check it's NOT hostile
                            local isH = false
                            for _, h in pairs(Hostiles) do if name:find(h) then isH = true; break end end
                            -- Check it's NOT a player
                            local isP = false
                            for _, plr in pairs(Players:GetPlayers()) do
                                if plr.Character and e == plr.Character then isP = true; break end
                            end
                            if not isH and not isP then isFriendly = true end

                            if isFriendly then
                                local root = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChildWhichIsA("BasePart")
                                local hum = e:FindFirstChildWhichIsA("Humanoid")
                                if root and hum then
                                    local hpPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                                    local lines = {
                                        {Text = e.Name, Color = Color3.fromRGB(0, 200, 255)},
                                        {Text = string.format("HP %d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth)), Color = hpColor(hpPct), HealthBar = true, HealthPct = hpPct, HealthColor = hpColor(hpPct)},
                                    }
                                    if State.ESP_Distance then
                                        table.insert(lines, {Text = distStr(myPos, root.Position), Color = Color3.fromRGB(150, 220, 255), Align = Enum.TextXAlignment.Right})
                                    end
                                    mkBillboard(root, Color3.fromRGB(0, 200, 255), lines)
                                end
                            end
                        end
                    end
                end

                -- ── KID ESP (missing children) ──
                if State.ESP_Kids then
                    for _, e in pairs(workspace:GetDescendants()) do
                        if e:IsA("Model") then
                            local n = e.Name:lower()
                            for _, kn in pairs(KidNames) do
                                if n:find(kn) and (n:find("kid") or n:find("child") or n:find("baby")) then
                                    local root = e:FindFirstChildWhichIsA("BasePart")
                                    if root then
                                        local lines = {{Text = "🧒 " .. e.Name, Color = Color3.fromRGB(255, 150, 255)}}
                                        if State.ESP_Distance then
                                            table.insert(lines, {Text = distStr(myPos, root.Position), Color = Color3.fromRGB(255, 200, 255), Align = Enum.TextXAlignment.Right})
                                        end
                                        mkBillboard(root, Color3.fromRGB(255, 150, 255), lines)
                                    end
                                end
                            end
                        end
                    end
                end

                -- ── ITEM ESP (food, materials, fuel) ──
                if State.ESP_Items then
                    for _, item in pairs(workspace:GetDescendants()) do
                        if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") then
                            local n = item.Name:lower()
                            for _, pat in pairs(ItemPatterns) do
                                if n:find(pat) then
                                    local root = item:FindFirstChildWhichIsA("BasePart")
                                    if root then
                                        local lines = {{Text = item.Name, Color = Color3.fromRGB(180, 255, 100)}}
                                        if State.ESP_Distance then
                                            table.insert(lines, {Text = distStr(myPos, root.Position), Color = Color3.fromRGB(200, 220, 150), Align = Enum.TextXAlignment.Right})
                                        end
                                        mkBillboard(root, Color3.fromRGB(180, 255, 100), lines)
                                    end
                                    break
                                end
                            end
                        end
                    end
                end

            end)
        else
            -- MASTER ESP OFF → destroy everything
            clearAllESP()
        end

        task.wait(0.5)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- RAYFIELD UI
-- ═══════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name = "⚡ PowerHub v9",
    Icon = 0,
    LoadingTitle = "PowerHub v9",
    LoadingSubtitle = "99 Nights in the Forest",
    ShowText = "PowerHub",
    Theme = "Dark",
    ToggleUIKeybind = "K",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "PowerHub",
        FileName = "PowerHub_v9"
    },
    KeySystem = false,
})

-- ── TAB: CAMPFIRE & SURVIVAL ──────────────────────────────
local Tab1 = Window:CreateTab("🔥 Campfire", 4483362458)
Tab1:CreateSection("Campfire")

Tab1:CreateToggle({
    Name = "Auto Campfire",
    CurrentValue = false,
    Flag = "AutoCampfire",
    Callback = function(v) State.AutoCampfire = v end,
})

Tab1:CreateDropdown({
    Name = "Fuel Type",
    Options = {"Logs", "Coal", "Super Log", "Wood"},
    CurrentOption = {"Logs"},
    MultipleOptions = false,
    Flag = "FuelType",
    Callback = function(opt) Settings.CampfireFuel = opt[1] end,
})

Tab1:CreateSection("Cooking")

Tab1:CreateToggle({
    Name = "Auto Cook",
    CurrentValue = false,
    Flag = "AutoCook",
    Callback = function(v) State.AutoCook = v end,
})

Tab1:CreateToggle({
    Name = "Auto Crockpot",
    CurrentValue = false,
    Flag = "AutoCrockpot",
    Callback = function(v) State.AutoCrockpot = v end,
})

-- ── TAB: COMBAT ───────────────────────────────────────────
local Tab2 = Window:CreateTab("⚔️ Combat", 4483362458)
Tab2:CreateSection("Defense")

Tab2:CreateToggle({
    Name = "🛡️ God Mode",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(v)
        State.GodMode = v
        if v then enableGodMode() else disableGodMode() end
    end,
})

Tab2:CreateSection("Offense")

Tab2:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = false,
    Flag = "KillAura",
    Callback = function(v) State.KillAura = v end,
})

Tab2:CreateSlider({
    Name = "Kill Aura Range",
    Range = {5, 50},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 20,
    Flag = "KillAuraRange",
    Callback = function(v) Settings.KillAuraRange = v end,
})

Tab2:CreateToggle({
    Name = "Auto Stronghold",
    CurrentValue = false,
    Flag = "AutoStronghold",
    Callback = function(v) State.AutoStronghold = v end,
})

Tab2:CreateSlider({
    Name = "Stronghold Auto TP Range",
    Range = {50, 200},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = 100,
    Flag = "StrongholdRange",
    Callback = function(v) Settings.StrongholdRange = v end,
})

-- ── TAB: FARMING ──────────────────────────────────────────
local Tab3 = Window:CreateTab("⛏️ Farming", 4483362458)
Tab3:CreateSection("Resources")

Tab3:CreateToggle({
    Name = "Auto Chop Tree",
    CurrentValue = false,
    Flag = "AutoChop",
    Callback = function(v) State.AutoChop = v end,
})

Tab3:CreateSlider({
    Name = "Chop Range",
    Range = {5, 30},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 15,
    Flag = "ChopRange",
    Callback = function(v) Settings.ChopRange = v end,
})

Tab3:CreateToggle({
    Name = "Auto Collect Gold",
    CurrentValue = false,
    Flag = "AutoGold",
    Callback = function(v) State.AutoGold = v end,
})

Tab3:CreateSlider({
    Name = "Gold Collect Range",
    Range = {10, 100},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 50,
    Flag = "GoldRange",
    Callback = function(v) Settings.GoldRange = v end,
})

Tab3:CreateToggle({
    Name = "Auto Craft",
    CurrentValue = false,
    Flag = "AutoCraft",
    Callback = function(v) State.AutoCraft = v end,
})

-- ── TAB: MOVEMENT ─────────────────────────────────────────
local Tab4 = Window:CreateTab("🚀 Movement", 4483362458)
Tab4:CreateSection("Flight")

Tab4:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(v) State.Fly = v end,
})

Tab4:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    Suffix = " studs/s",
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(v) Settings.FlySpeed = v end,
})

Tab4:CreateSection("Passive")

Tab4:CreateToggle({
    Name = "NoClip",
    CurrentValue = false,
    Flag = "NoClip",
    Callback = function(v) State.NoClip = v end,
})

Tab4:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(v) State.AntiAFK = v end,
})

Tab4:CreateSlider({
    Name = "Anti AFK Interval",
    Range = {30, 300},
    Increment = 10,
    Suffix = " seconds",
    CurrentValue = 120,
    Flag = "AntiAFKInterval",
    Callback = function(v) Settings.AntiAFKInterval = v end,
})

-- ── TAB: VISUALS ──────────────────────────────────────────
local Tab5 = Window:CreateTab("👁️ Visuals", 4483362458)
Tab5:CreateSection("Master Switch")

Tab5:CreateToggle({
    Name = "ESP Master",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v) State.ESP = v end,
})

Tab5:CreateSection("Show Category")

Tab5:CreateToggle({
    Name = "🟢 Players",
    CurrentValue = false,
    Flag = "ESP_Players",
    Callback = function(v) State.ESP_Players = v end,
})

Tab5:CreateToggle({
    Name = "🔴 Enemies",
    CurrentValue = false,
    Flag = "ESP_Enemies",
    Callback = function(v) State.ESP_Enemies = v end,
})

Tab5:CreateToggle({
    Name = "🔵 Friendlies / NPCs",
    CurrentValue = false,
    Flag = "ESP_Friendlies",
    Callback = function(v) State.ESP_Friendlies = v end,
})

Tab5:CreateToggle({
    Name = "🟡 Gold / Diamonds",
    CurrentValue = false,
    Flag = "ESP_Gold",
    Callback = function(v) State.ESP_Gold = v end,
})

Tab5:CreateToggle({
    Name = "🟢 Items (Food/Materials)",
    CurrentValue = false,
    Flag = "ESP_Items",
    Callback = function(v) State.ESP_Items = v end,
})

Tab5:CreateToggle({
    Name = "🧒 Kids (Missing Children)",
    CurrentValue = false,
    Flag = "ESP_Kids",
    Callback = function(v) State.ESP_Kids = v end,
})

Tab5:CreateSection("Options")

Tab5:CreateToggle({
    Name = "Show Distance",
    CurrentValue = true,
    Flag = "ESP_Distance",
    Callback = function(v) State.ESP_Distance = v end,
})

-- ═══════════════════════════════════════════════════════════
-- LOAD SAVED CONFIG
-- ═══════════════════════════════════════════════════════════
Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title = "PowerHub v9",
    Content = "Loaded! Press RightCtrl to toggle UI",
    Duration = 3,
})

print("✅ PowerHub v9 loaded — Rayfield UI")
