--[[
    PowerHub v9 — 99 Nights in the Forest
    Features: Auto Campfire, Auto Craft, Auto Gold, Auto Chop,
              Auto Cook, Auto Crockpot, Auto Stronghold,
              Kill Aura, Anti AFK, Teleport, Fly
    Executor: Real (Luau)
]]

-- ═══════════════════════════════════════════════════════════
-- SERVICES & REFERENCES
-- ═══════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Re-fetch on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
end)

-- ═══════════════════════════════════════════════════════════
-- HELPER: Remote Finder
-- ═══════════════════════════════════════════════════════════
local function getRemote(name, class)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == name and v:IsA(class or "RemoteEvent") then
            return v
        end
    end
    return nil
end

local function fireRemote(name, ...)
    local r = getRemote(name, "RemoteEvent")
    if r then r:FireServer(...) end
end

local function invokeRemote(name, ...)
    local r = getRemote(name, "RemoteFunction")
    if r then return r:InvokeServer(...) end
end

-- ═══════════════════════════════════════════════════════════
-- FEATURE FLAGS
-- ═══════════════════════════════════════════════════════════
local Flags = {
    AutoCampfire = false,
    AutoCraft = false,
    AutoGold = false,
    AutoChop = false,
    AutoCook = false,
    AutoCrockpot = false,
    AutoStronghold = false,
    KillAura = false,
    AntiAFK = false,
    Fly = false,
    NoClip = false,
    ESP = false,
}

-- Settings
local Settings = {
    CampfireFuel = "Logs",
    CookList = {"Morsel", "Steak", "Raw Steak", "Raw Morsel", "Fish", "Raw Fish",
                "Monster Meat", "Raw Monster Meat", "Kelp", "Raw Kelp"},
    ChopRange = 15,
    KillAuraRange = 20,
    FlySpeed = 50,
    GoldCollectRange = 50,
    StrongholdRange = 100,
    AntiAFKInterval = 120,
}

-- ═══════════════════════════════════════════════════════════
-- FEATURE: AUTO CAMPFIRE
-- Finds fuel items, drags to campfire
-- ═══════════════════════════════════════════════════════════
local function autoCampfire()
    while Flags.AutoCampfire do
        pcall(function()
            local campfire = workspace.Map.Campground:FindFirstChild("Campfire")
                or workspace.Map.Campground:FindFirstChild("Fire")
                or workspace.Map:FindFirstChild("Campfire")
            if not campfire then return end

            -- Find fuel items nearby
            local fuelNames = {"Coal", "Log", "Logs", "Super Log", "Wood", "Stick"}
            for _, item in pairs(workspace:GetDescendants()) do
                if not Flags.AutoCampfire then break end
                if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") then
                    for _, fname in pairs(fuelNames) do
                        if item.Name:lower():find(fname:lower()) then
                            local dist = (item:GetPivot().Position - HumanoidRootPart.Position).Magnitude
                            if dist < 50 then
                                pcall(function()
                                    fireRemote("RequestStartDraggingItem", item)
                                    task.wait(0.3)
                                    fireRemote("RequestThrowItem", campfire.Position)
                                end)
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end
        end)
        task.wait(1)
    end
end

-- ═══════════════════════════════════════════════════════════
-- FEATURE: AUTO CRAFT
-- Auto craft items from recipe list
-- ═══════════════════════════════════════════════════════════
local craftRecipes = {
    "Axe", "Iron Axe", "Gold Axe",
    "Torch", "Flashlight",
    "Bandage", "Medkit",
    "Armor", "Iron Armor",
    "Spear", "Iron Spear",
    "Arrow", "Fire Arrow",
    "Stone Wall", "Wood Wall",
}

local function autoCraft()
    while Flags.AutoCraft do
        pcall(function()
            -- Find crafting stations
            for _, station in pairs(workspace:GetDescendants()) do
                if not Flags.AutoCraft then break end
                if station:IsA("Model") and station.Name:lower():find("craft") then
                    local dist = (station:GetPivot().Position - HumanoidRootPart.Position).Magnitude
                    if dist < 30 then
                        -- Try to craft each recipe
                        for _, recipe in pairs(craftRecipes) do
                            pcall(function()
                                -- Attempt to trigger craft via remote or proximity
                                fireRemote("RequestCraft", recipe)
                                fireRemote("CraftItem", recipe)
                            end)
                            task.wait(0.2)
                        end
                    end
                end
            end
        end)
        task.wait(3)
    end
end

-- ═══════════════════════════════════════════════════════════
-- FEATURE: AUTO COLLECT GOLD
-- Collect gold coins/diamonds without moving
-- ═══════════════════════════════════════════════════════════
local function autoGold()
    while Flags.AutoGold do
        pcall(function()
            local range = Settings.GoldCollectRange

            for _, item in pairs(workspace:GetDescendants()) do
                if not Flags.AutoGold then break end
                if item:IsA("Model") or item:IsA("Part") then
                    local name = item.Name:lower()
                    local isGold = name:find("gold") or name:find("coin") or name:find("diamond")
                        or name:find("gem") or name:find("currency") or name:find("money")

                    if isGold then
                        local pos = item:IsA("Model") and item:GetPivot().Position or item.Position
                        local dist = (pos - HumanoidRootPart.Position).Magnitude

                        if dist < range then
                            pcall(function()
                                -- Teleport item to player
                                if item:IsA("Model") then
                                    item:SetPrimaryPartCFrame(HumanoidRootPart.CFrame)
                                else
                                    item.CFrame = HumanoidRootPart.CFrame
                                end
                            end)
                            task.wait(0.1)
                        elseif dist < range * 3 then
                            -- Drag if further
                            pcall(function()
                                fireRemote("RequestStartDraggingItem", item)
                                task.wait(0.2)
                            end)
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

-- ═══════════════════════════════════════════════════════════
-- FEATURE: AUTO CHOP TREE
-- Chop nearby trees automatically
-- ═══════════════════════════════════════════════════════════
local function autoChop()
    while Flags.AutoChop do
        pcall(function()
            local range = Settings.ChopRange

            -- Find trees
            for _, obj in pairs(workspace:GetDescendants()) do
                if not Flags.AutoChop then break end
                if obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") then
                    local name = obj.Name:lower()
                    local isTree = name:find("tree") or name:find("log") or name:find("wood")
                        or name:find("birch") or name:find("pine") or name:find("oak")
                        or name:find("dead") or name:find("super")

                    if isTree then
                        local pivot = obj:GetPivot()
                        local dist = (pivot.Position - HumanoidRootPart.Position).Magnitude

                        if dist < range then
                            -- Move close to tree
                            local targetCF = pivot * CFrame.new(0, 0, 3)
                            HumanoidRootPart.CFrame = targetCF
                            task.wait(0.1)

                            -- Damage the tree via remote
                            pcall(function()
                                fireRemote("ToolDamageObject", obj)
                            end)
                            task.wait(0.2)

                            -- Also try direct method
                            pcall(function()
                                local tool = Character:FindFirstChildWhichIsA("Tool")
                                if tool and tool:FindFirstChild("Handle") then
                                    -- Swing animation
                                    tool:Activate()
                                end
                            end)
                            task.wait(0.3)
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

-- ═══════════════════════════════════════════════════════════
-- FEATURE: AUTO COOK FOOD
-- Cook raw food items at campfire
-- ═══════════════════════════════════════════════════════════
local function autoCook()
    while Flags.AutoCook do
        pcall(function()
            local campfire = workspace.Map.Campground:FindFirstChild("Campfire")
                or workspace.Map.Campground:FindFirstChild("Fire")
                or workspace.Map:FindFirstChild("Campfire")
            if not campfire then return end

            local firePos = campfire:GetPivot().Position

            -- Find raw food items
            for _, item in pairs(workspace:GetDescendants()) do
                if not Flags.AutoCook then break end
                if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") then
                    local itemName = item.Name

                    -- Check if it's a cookable item
                    for _, cookName in pairs(Settings.CookList) do
                        if itemName:lower():find(cookName:lower()) then
                            local dist = (item:GetPivot().Position - HumanoidRootPart.Position).Magnitude
                            if dist < 50 then
                                pcall(function()
                                    -- Teleport item to campfire for cooking
                                    item:SetPrimaryPartCFrame(CFrame.new(firePos + Vector3.new(0, 5, 0)))
                                    task.wait(0.3)

                                    -- Request cook
                                    fireRemote("RequestCookItem", item)
                                    fireRemote("CookItem", item)
                                end)
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end
        end)
        task.wait(1)
    end
end

-- ═══════════════════════════════════════════════════════════
-- FEATURE: AUTO CROCKPOT
-- Auto fill crockpot with ingredients
-- ═══════════════════════════════════════════════════════════
local function autoCrockpot()
    while Flags.AutoCrockpot do
        pcall(function()
            -- Find crockpot
            local crockpot = workspace.Map.Campground:FindFirstChild("Crockpot")
                or workspace.Map:FindFirstChild("Crockpot")
                or workspace.Map.Campground:FindFirstChildWhichIsA("Model", true)

            -- Also search by class
            if not crockpot then
                for _, obj in pairs(workspace.Map.Campground:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name:lower():find("crock") then
                        crockpot = obj
                        break
                    end
                end
            end

            if not crockpot then return end

            local cpPos = crockpot:GetPivot().Position

            -- Food ingredients for crockpot
            local ingredients = {"Morsel", "Steak", "Monster Meat", "Fish", "Kelp",
                                 "Berry", "Carrot", "Mushroom", "Egg"}

            for _, item in pairs(workspace:GetDescendants()) do
                if not Flags.AutoCrockpot then break end
                if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") then
                    for _, ing in pairs(ingredients) do
                        if item.Name:lower():find(ing:lower()) then
                            local dist = (item:GetPivot().Position - HumanoidRootPart.Position).Magnitude
                            if dist < 50 then
                                pcall(function()
                                    fireRemote("RequestStartDraggingItem", item)
                                    task.wait(0.3)
                                    fireRemote("RequestGiveItemToNPC", crockpot, item)
                                    fireRemote("RequestThrowItem", cpPos)
                                end)
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end
        end)
        task.wait(1.5)
    end
end

-- ═══════════════════════════════════════════════════════════
-- FEATURE: AUTO STRONGHOLD
-- Auto teleport to and complete strongholds
-- ═══════════════════════════════════════════════════════════
local function autoStronghold()
    while Flags.AutoStronghold do
        pcall(function()
            -- Find stronghold locations
            for _, obj in pairs(workspace.Map:GetDescendants()) do
                if not Flags.AutoStronghold then break end
                if obj:IsA("Model") and (obj.Name:lower():find("stronghold")
                    or obj.Name:lower():find("raid") or obj.Name:lower():find("boss")) then
                    local pivot = obj:GetPivot()
                    local dist = (pivot.Position - HumanoidRootPart.Position).Magnitude

                    if dist > Settings.StrongholdRange then
                        -- Teleport to stronghold
                        pcall(function()
                            fireRemote("RequestTeleport", pivot.Position)
                            HumanoidRootPart.CFrame = pivot * CFrame.new(0, 5, 0)
                        end)
                        task.wait(2)
                    end

                    -- Kill all enemies in stronghold
                    for _, enemy in pairs(workspace:GetDescendants()) do
                        if enemy:IsA("Model") and enemy:FindFirstChildWhichIsA("Humanoid") then
                            local enemyHum = enemy:FindFirstChildWhichIsA("Humanoid")
                            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
                                or enemy:FindFirstChildWhichIsA("BasePart")
                            if enemyHum and enemyHum.Health > 0 and enemyRoot then
                                local eDist = (enemyRoot.Position - HumanoidRootPart.Position).Magnitude
                                if eDist < Settings.KillAuraRange then
                                    pcall(function()
                                        -- Teleport to enemy
                                        HumanoidRootPart.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, 3)
                                        task.wait(0.05)
                                        fireRemote("ToolDamageObject", enemy)
                                    end)
                                    task.wait(0.15)
                                end
                            end
                        end
                    end
                end
            end
        end)
        task.wait(1)
    end
end

-- ═══════════════════════════════════════════════════════════
-- FEATURE: KILL AURA
-- Damage all nearby hostile entities
-- ═══════════════════════════════════════════════════════════
local hostileNames = {"wolf", "bear", "deer", "mammoth", "fox", "polar",
                      "alpha", "entity", "enemy", "hostile", "monster",
                      "spider", "snake", "bat", "zombie"}

local function killAura()
    while Flags.KillAura do
        pcall(function()
            local range = Settings.KillAuraRange

            for _, entity in pairs(workspace:GetDescendants()) do
                if not Flags.KillAura then break end
                if entity:IsA("Model") then
                    local hum = entity:FindFirstChildWhichIsA("Humanoid")
                    local root = entity:FindFirstChild("HumanoidRootPart")
                        or entity:FindFirstChildWhichIsA("BasePart")

                    if hum and hum.Health > 0 and root then
                        local dist = (root.Position - HumanoidRootPart.Position).Magnitude
                        local name = entity.Name:lower()

                        -- Check if hostile
                        local hostile = false
                        for _, h in pairs(hostileNames) do
                            if name:find(h) then hostile = true; break end
                        end

                        if hostile and dist < range then
                            pcall(function()
                                fireRemote("ToolDamageObject", entity)
                            end)
                        end
                    end
                end
            end
        end)
        task.wait(0.3)
    end
end

-- ═══════════════════════════════════════════════════════════
-- FEATURE: ANTI AFK
-- ═══════════════════════════════════════════════════════════
local function antiAFK()
    while Flags.AntiAFK do
        pcall(function()
            -- Method 1: Virtual input
            pcall(function()
                local VirtualUser = game:GetService("VirtualUser")
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)

            -- Method 2: Broadcast ping
            fireRemote("RequestBroadcastPing")

            -- Method 3: Small movement
            pcall(function()
                HumanoidRootPart.CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0.1, 0)
                task.wait(0.1)
                HumanoidRootPart.CFrame = HumanoidRootPart.CFrame * CFrame.new(0, -0.1, 0)
            end)

            -- Method 4: Tool equip/unequip cycle
            pcall(function()
                local tool = Character:FindFirstChildWhichIsA("Tool")
                if tool then
                    Humanoid:UnequipTools()
                    task.wait(0.5)
                    Humanoid:EquipTool(tool)
                end
            end)
        end)
        task.wait(Settings.AntiAFKInterval)
    end
end

-- ═══════════════════════════════════════════════════════════
-- FEATURE: FLY
-- ═══════════════════════════════════════════════════════════
local flyBodyVel, flyBodyGyro

local function flyLoop()
    if Flags.Fly then
        flyBodyVel = Instance.new("BodyVelocity")
        flyBodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyVel.Velocity = Vector3.zero
        flyBodyVel.Parent = HumanoidRootPart

        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyGyro.P = 9e4
        flyBodyGyro.Parent = HumanoidRootPart
    end

    RunService.Heartbeat:Connect(function()
        if not Flags.Fly then
            if flyBodyVel then flyBodyVel:Destroy() end
            if flyBodyGyro then flyBodyGyro:Destroy() end
            return
        end

        local cam = workspace.CurrentCamera.CFrame
        local moveDir = Vector3.zero
        local speed = Settings.FlySpeed

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        if flyBodyVel then flyBodyVel.Velocity = moveDir * speed end
        if flyBodyGyro then flyBodyGyro.CFrame = cam end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- FEATURE: NOCLIP
-- ═══════════════════════════════════════════════════════════
local function noClipLoop()
    RunService.Stepped:Connect(function()
        if Flags.NoClip and Character then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- FEATURE: ESP
-- ═══════════════════════════════════════════════════════════
local espObjects = {}

local function createESP(part, color, text)
    if not part or espObjects[part] then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "PowerHub_ESP"
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.Parent = bb

    bb.Parent = part
    espObjects[part] = bb
end

local function espLoop()
    while Flags.ESP do
        pcall(function()
            -- Clear old ESP
            for part, bb in pairs(espObjects) do
                if not part or not part.Parent then
                    bb:Destroy()
                    espObjects[part] = nil
                end
            end

            -- Player ESP
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        createESP(root, Color3.fromRGB(0, 255, 0), plr.Name)
                    end
                end
            end

            -- Item ESP (gold, diamonds)
            for _, item in pairs(workspace:GetDescendants()) do
                if item:IsA("Model") then
                    local name = item.Name:lower()
                    if name:find("gold") or name:find("diamond") or name:find("coin") then
                        local root = item:FindFirstChildWhichIsA("BasePart")
                        if root then
                            createESP(root, Color3.fromRGB(255, 215, 0), item.Name)
                        end
                    end
                end
            end

            -- Entity ESP
            for _, entity in pairs(workspace:GetDescendants()) do
                if entity:IsA("Model") and entity:FindFirstChildWhichIsA("Humanoid") then
                    local root = entity:FindFirstChild("HumanoidRootPart")
                        or entity:FindFirstChildWhichIsA("BasePart")
                    if root then
                        local isHostile = false
                        for _, h in pairs(hostileNames) do
                            if entity.Name:lower():find(h) then isHostile = true; break end
                        end
                        local col = isHostile and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 200, 255)
                        createESP(root, col, entity.Name .. " HP:" .. math.floor(entity:FindFirstChildWhichIsA("Humanoid").Health))
                    end
                end
            end
        end)
        task.wait(1)
    end

    -- Clear ESP when disabled
    for part, bb in pairs(espObjects) do
        if bb then bb:Destroy() end
    end
    espObjects = {}
end

-- ═══════════════════════════════════════════════════════════
-- GUI: iOS-Style Toggle Interface
-- ═══════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PowerHub_v9"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 480)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 16)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚡ PowerHub v9"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -42, 0.5, -17)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 10)
CloseBtnCorner.Parent = CloseBtn

-- Scrollable Content
local Scroller = Instance.new("ScrollingFrame")
Scroller.Size = UDim2.new(1, -20, 1, -60)
Scroller.Position = UDim2.new(0, 10, 0, 55)
Scroller.BackgroundTransparency = 1
Scroller.ScrollBarThickness = 4
Scroller.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
Scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroller.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroller

-- Toggle Button Creator
local function createToggle(text, flag, order, callback)
    local Toggle = Instance.new("Frame")
    Toggle.Name = text
    Toggle.Size = UDim2.new(1, 0, 0, 40)
    Toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Toggle.BorderSizePixel = 0
    Toggle.LayoutOrder = order
    Toggle.Parent = Scroller

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 10)
    ToggleCorner.Parent = Toggle

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Toggle

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 48, 0, 26)
    ToggleBtn.Position = UDim2.new(1, -58, 0.5, -13)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ToggleBtn.Text = ""
    ToggleBtn.Parent = Toggle

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(1, 0)
    BtnCorner.Parent = ToggleBtn

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 22, 0, 22)
    Circle.Position = UDim2.new(0, 2, 0.5, -11)
    Circle.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    Circle.Parent = ToggleBtn

    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle

    local state = false

    local function updateVisual()
        if state then
            Circle:TweenPosition(UDim2.new(1, -24, 0.5, -11), "Out", "Quad", 0.2, true)
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        else
            Circle:TweenPosition(UDim2.new(0, 2, 0.5, -11), "Out", "Quad", 0.2, true)
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            Circle.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
        end
    end

    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        Flags[flag] = state
        updateVisual()
        if callback then callback(state) end
    end)

    return Toggle
end

-- Section Header
local function createHeader(text, order)
    local Header = Instance.new("TextLabel")
    Header.Size = UDim2.new(1, 0, 0, 28)
    Header.BackgroundTransparency = 1
    Header.Text = "  " .. text
    Header.TextColor3 = Color3.fromRGB(100, 180, 255)
    Header.TextSize = 11
    Header.Font = Enum.Font.GothamBold
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.LayoutOrder = order
    Header.Parent = Scroller
    return Header
end

-- ═══════════════════════════════════════════════════════════
-- BUILD GUI
-- ═══════════════════════════════════════════════════════════
createHeader("🔥 CAMPFIRE & SURVIVAL", 1)
createToggle("Auto Campfire", "AutoCampfire", 2, function(on)
    if on then task.spawn(autoCampfire) end
end)
createToggle("Auto Cook", "AutoCook", 3, function(on)
    if on then task.spawn(autoCook) end
end)
createToggle("Auto Crockpot", "AutoCrockpot", 4, function(on)
    if on then task.spawn(autoCrockpot) end
end)

createHeader("⚔️ COMBAT & DEFENSE", 5)
createToggle("Kill Aura", "KillAura", 6, function(on)
    if on then task.spawn(killAura) end
end)
createToggle("Auto Stronghold", "AutoStronghold", 7, function(on)
    if on then task.spawn(autoStronghold) end
end)

createHeader("⛏️ FARMING & CRAFTING", 8)
createToggle("Auto Chop Tree", "AutoChop", 9, function(on)
    if on then task.spawn(autoChop) end
end)
createToggle("Auto Collect Gold", "AutoGold", 10, function(on)
    if on then task.spawn(autoGold) end
end)
createToggle("Auto Craft", "AutoCraft", 11, function(on)
    if on then task.spawn(autoCraft) end
end)

createHeader("🚀 MOVEMENT & MISC", 12)
createToggle("Fly", "Fly", 13, function(on)
    if on then
        task.spawn(flyLoop)
    end
end)
createToggle("NoClip", "NoClip", 14, function(on)
    if on then task.spawn(noClipLoop) end
end)
createToggle("Anti AFK", "AntiAFK", 15, function(on)
    if on then task.spawn(antiAFK) end
end)
createToggle("ESP", "ESP", 16, function(on)
    if on then task.spawn(espLoop) end
end)

-- Close button
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Toggle key: RightControl
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Notify
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "PowerHub v9",
        Text = "Loaded! Press RightCtrl to toggle UI",
        Duration = 3
    })
end)

print("✅ PowerHub v9 loaded successfully!")
