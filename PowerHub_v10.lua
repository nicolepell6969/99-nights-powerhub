--[[
    PowerHub v10 — 99 Nights in the Forest
    Based on REAL diagnostic data (Place: 126509999114328)
    UI: Rayfield Interface Suite
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LP = Players.LocalPlayer
local Char = LP.Character or LP.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")
local Hum = Char:WaitForChild("Humanoid")

LP.CharacterAdded:Connect(function(c)
    Char = c; HRP = c:WaitForChild("HumanoidRootPart"); Hum = c:WaitForChild("Humanoid")
end)

-- ═══════════════════════════════════════════════════════════
-- REMOTE SHORTCUTS (from real diagnostic)
-- ═══════════════════════════════════════════════════════════
local RE = RS:WaitForChild("RemoteEvents")

local function fire(name, ...)
    local r = RE:FindFirstChild(name)
    if r and r:IsA("RemoteEvent") then r:FireServer(...) end
end

local function invoke(name, ...)
    local r = RE:FindFirstChild(name)
    if r and r:IsA("RemoteFunction") then return r:InvokeServer(...) end
end

-- ═══════════════════════════════════════════════════════════
-- STATE & SETTINGS
-- ═══════════════════════════════════════════════════════════
local State = {
    AutoCampfire = false, AutoCook = false, AutoCrockpot = false,
    AutoChop = false, AutoGold = false, AutoCraft = false,
    AutoStronghold = false, KillAura = false, AntiAFK = false,
    Fly = false, NoClip = false, GodMode = false, ESP = false,
    ESP_Players = false, ESP_Enemies = false, ESP_Friendlies = false,
    ESP_Gold = false, ESP_Items = false, ESP_Kids = false, ESP_Distance = true,
}

local Settings = {
    ChopRange = 15, KillAuraRange = 20, FlySpeed = 50,
    GoldRange = 100, StrongholdRange = 100, AntiAFKInterval = 120,
}

-- ═══════════════════════════════════════════════════════════
-- AUTO CAMPFIRE — RequestBurnItem (real remote)
-- ═══════════════════════════════════════════════════════════
local FuelPatterns = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel",
    "Wood", "Stick", "Branch", "Plank", "Charcoal", "Paper", "Pumpkin"}

local function isFuel(name)
    local n = name:lower()
    for _, f in pairs(FuelPatterns) do
        if n:find(f:lower()) then return true end
    end
    return false
end

task.spawn(function()
    while true do
        if State.AutoCampfire then
            pcall(function()
                for _, item in pairs(workspace:GetDescendants()) do
                    if not State.AutoCampfire then break end
                    if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") then
                        if isFuel(item.Name) then
                            local d = (item:GetPivot().Position - HRP.Position).Magnitude
                            if d < 60 then
                                -- Real remote: RequestBurnItem
                                fire("RequestBurnItem", item)
                                task.wait(0.3)
                                -- Also try drag+throw as backup
                                fire("RequestStartDraggingItem", item)
                                task.wait(0.3)
                                fire("RequestThrowItem", Vector3.new(0, 2, 0)) -- MainFire position
                                task.wait(0.5)
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
-- AUTO COOK — RequestCookItem (real remote)
-- ═══════════════════════════════════════════════════════════
local CookPatterns = {"Raw Morsel", "Morsel", "Raw Steak", "Steak",
    "Raw Fish", "Fish", "Raw Monster Meat", "Monster Meat",
    "Raw Kelp", "Kelp", "Berry", "Carrot", "Mushroom", "Egg",
    "Frog Leg", "Bunny Leg", "Wolf Leg", "Cactus Fruit"}

local function isCookable(name)
    local n = name:lower()
    for _, c in pairs(CookPatterns) do
        if n:find(c:lower()) then return true end
    end
    return false
end

task.spawn(function()
    while true do
        if State.AutoCook then
            pcall(function()
                local firePos = Vector3.new(0, 4, 0) -- MainFire @ [0,2,0]
                for _, item in pairs(workspace:GetDescendants()) do
                    if not State.AutoCook then break end
                    if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") then
                        if isCookable(item.Name) then
                            local d = (item:GetPivot().Position - HRP.Position).Magnitude
                            if d < 60 then
                                -- Teleport food near fire
                                pcall(function()
                                    item:SetPrimaryPartCFrame(CFrame.new(firePos))
                                end)
                                task.wait(0.3)
                                fire("RequestCookItem", item)
                                task.wait(0.5)
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
-- AUTO CROCKPOT — RequestCrockpotItem (RemoteFunction!)
-- ═══════════════════════════════════════════════════════════
local CrockpotItems = {"Morsel", "Steak", "Monster Meat", "Fish", "Kelp",
    "Berry", "Carrot", "Mushroom", "Egg", "Frog Leg", "Bunny Leg", "Wolf Leg"}

task.spawn(function()
    while true do
        if State.AutoCrockpot then
            pcall(function()
                local cp = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Campground")
                    and workspace.Map.Campground:FindFirstChild("Scrapper")
                -- Search broader for crockpot
                if not cp then
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("Model") and v.Name:lower():find("crock") then cp = v; break end
                    end
                end
                if not cp then return end

                for _, item in pairs(workspace:GetDescendants()) do
                    if not State.AutoCrockpot then break end
                    if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") then
                        for _, ing in pairs(CrockpotItems) do
                            if item.Name:lower():find(ing:lower()) then
                                local d = (item:GetPivot().Position - HRP.Position).Magnitude
                                if d < 60 then
                                    -- RemoteFunction!
                                    invoke("RequestCrockpotItem", cp, item)
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
-- AUTO CHOP — RequestDestroyFoliage (real remote, NO teleport)
-- ═══════════════════════════════════════════════════════════
local TreeNames = {"Small Tree", "TreeBig2", "TreeBig3", "Bush", "Stump",
    "Log Pile", "Dead Tree", "Brightwood", "Sapling"}

local function isTree(name)
    local n = name:lower()
    for _, t in pairs(TreeNames) do
        if n:find(t:lower()) then return true end
    end
    return false
end

task.spawn(function()
    while true do
        if State.AutoChop then
            pcall(function()
                for _, obj in pairs(workspace:GetDescendants()) do
                    if not State.AutoChop then break end
                    if obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") then
                        if isTree(obj.Name) then
                            local d = (obj:GetPivot().Position - HRP.Position).Magnitude
                            if d <= Settings.ChopRange then
                                -- Real remote: RequestDestroyFoliage (RemoteFunction)
                                invoke("RequestDestroyFoliage", obj)
                                task.wait(0.4)
                                -- Also try ToolDamageObject as backup
                                invoke("ToolDamageObject", obj)
                                task.wait(0.3)
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
-- AUTO COLLECT GOLD — RequestCollectCoints (typo in game!)
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AutoGold then
            pcall(function()
                for _, item in pairs(workspace:GetDescendants()) do
                    if not State.AutoGold then break end
                    if item:IsA("Model") then
                        local n = item.Name:lower()
                        if n:find("coin") or n:find("diamond") or n:find("gold") or n:find("gem") then
                            local root = item:FindFirstChildWhichIsA("BasePart")
                            if root then
                                local d = (root.Position - HRP.Position).Magnitude
                                if d < Settings.GoldRange then
                                    -- Real remote: RequestCollectCoints (note typo!)
                                    invoke("RequestCollectCoints", item)
                                    task.wait(0.2)
                                end
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
-- AUTO CRAFT — CraftItem (RemoteFunction, real)
-- ═══════════════════════════════════════════════════════════
local CraftRecipes = {"Axe", "Iron Axe", "Gold Axe", "Torch", "Flashlight",
    "Bandage", "Medkit", "Armor", "Iron Armor", "Spear", "Iron Spear",
    "Arrow", "Fire Arrow", "Stone Wall", "Wood Wall", "Wooden Chair",
    "Wooden Table", "Sapling"}

task.spawn(function()
    while true do
        if State.AutoCraft then
            pcall(function()
                -- Find CraftingBench
                for _, v in pairs(workspace:GetDescendants()) do
                    if not State.AutoCraft then break end
                    if v:IsA("Model") and v.Name:lower():find("crafting") then
                        local d = (v:GetPivot().Position - HRP.Position).Magnitude
                        if d < 30 then
                            for _, recipe in pairs(CraftRecipes) do
                                invoke("CraftItem", recipe)
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
-- AUTO STRONGHOLD — RequestTeleport (RemoteFunction)
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AutoStronghold then
            pcall(function()
                for _, obj in pairs(workspace:GetDescendants()) do
                    if not State.AutoStronghold then break end
                    if obj:IsA("Model") and (obj.Name:lower():find("stronghold") or obj.Name:lower():find("raid") or obj.Name:lower():find("boss")) then
                        local d = (obj:GetPivot().Position - HRP.Position).Magnitude
                        if d > Settings.StrongholdRange then
                            invoke("RequestTeleport", obj:GetPivot().Position)
                            task.wait(2)
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- KILL AURA — ProjectileDamageEnemy / ToolDamageObject
-- ═══════════════════════════════════════════════════════════
local Hostiles = {"wolf", "bear", "deer", "mammoth", "fox", "polar", "alpha",
    "entity", "hostile", "monster", "spider", "snake", "bat", "zombie", "cultist"}

task.spawn(function()
    while true do
        if State.KillAura then
            pcall(function()
                for _, e in pairs(workspace:GetDescendants()) do
                    if not State.KillAura then break end
                    if e:IsA("Model") and e:FindFirstChildWhichIsA("Humanoid") then
                        local hum = e:FindFirstChildWhichIsA("Humanoid")
                        local root = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChildWhichIsA("BasePart")
                        if hum and hum.Health > 0 and root then
                            local n = e.Name:lower()
                            for _, h in pairs(Hostiles) do
                                if n:find(h) and (root.Position - HRP.Position).Magnitude < Settings.KillAuraRange then
                                    -- Try multiple damage methods
                                    invoke("ToolDamageObject", e)
                                    invoke("ProjectileDamageEnemy", e, root.Position)
                                    invoke("RequestDissolveEnemy", e)
                                    fire("ClientTriggerNPCAttack", e)
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
-- ANTI AFK — RequestBroadcastPing
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AntiAFK then
            pcall(function()
                local VU = game:GetService("VirtualUser")
                VU:CaptureController()
                VU:ClickButton2(Vector2.new())
            end)
            fire("RequestBroadcastPing")
        end
        task.wait(Settings.AntiAFKInterval)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- GOD MODE — HealthChanged hook
-- ═══════════════════════════════════════════════════════════
local godModeConn = nil

local function enableGodMode()
    if godModeConn then pcall(function() godModeConn:Disconnect() end) end
    godModeConn = Hum.HealthChanged:Connect(function()
        if State.GodMode and Hum.Health < Hum.MaxHealth then
            Hum.Health = Hum.MaxHealth
        end
    end)
    pcall(function() Hum.Health = Hum.MaxHealth end)
end

local function disableGodMode()
    if godModeConn then pcall(function() godModeConn:Disconnect() end); godModeConn = nil end
end

LP.CharacterAdded:Connect(function()
    if State.GodMode then task.wait(1); enableGodMode() end
end)

-- ═══════════════════════════════════════════════════════════
-- FLY
-- ═══════════════════════════════════════════════════════════
local flyBV, flyBG
RunService.Heartbeat:Connect(function()
    if State.Fly then
        if not flyBV then
            flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.new(math.huge,math.huge,math.huge); flyBV.Parent = HRP
        end
        if not flyBG then
            flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque = Vector3.new(math.huge,math.huge,math.huge); flyBG.P = 9e4; flyBG.Parent = HRP
        end
        local cam = workspace.CurrentCamera.CFrame
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        flyBV.Velocity = dir * Settings.FlySpeed
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
-- ESP — optimized single-scan
-- ═══════════════════════════════════════════════════════════
local espObjs = {}
local ESP_RANGE = 200
local KidNames = {"dino", "squid", "kraken", "koala"}

local function clearAllESP()
    for _, bb in pairs(espObjs) do pcall(function() if bb and bb.Parent then bb:Destroy() end end) end
    espObjs = {}
end

local function cleanStale()
    for obj, bb in pairs(espObjs) do
        if not obj or not obj.Parent then pcall(function() if bb and bb.Parent then bb:Destroy() end end); espObjs[obj] = nil end
    end
end

local function hpColor(pct)
    if pct > 0.5 then return Color3.fromRGB(0,255,80)
    elseif pct > 0.25 then return Color3.fromRGB(255,200,0)
    else return Color3.fromRGB(255,50,30) end
end

local function distStr(a, b)
    if not a or not b then return "" end
    return string.format("[%.0fm]", (a - b).Magnitude)
end

local function mkBB(part, col, lines)
    if not part then return end
    if espObjs[part] then pcall(function() espObjs[part]:Destroy() end); espObjs[part] = nil end
    local bb = Instance.new("BillboardGui")
    bb.Name = "PH_ESP"; bb.Size = UDim2.new(0,220,0,#lines*16+8); bb.StudsOffset = Vector3.new(0,3,0)
    bb.AlwaysOnTop = true; bb.LightInfluence = 0; bb.Adornee = part
    for i, l in ipairs(lines) do
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,-8,0,16); lbl.Position = UDim2.new(0,4,0,(i-1)*16+4)
        lbl.BackgroundTransparency = 1; lbl.TextColor3 = l.Color or col
        lbl.TextStrokeColor3 = Color3.new(0,0,0); lbl.TextStrokeTransparency = 0.2
        lbl.TextSize = 12; lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = l.Align or Enum.TextXAlignment.Left; lbl.Text = l.Text or ""
        lbl.Parent = bb
        if l.HPBar then
            local bg = Instance.new("Frame"); bg.Size = UDim2.new(1,-8,0,4); bg.Position = UDim2.new(0,4,0,(i-1)*16+4+14)
            bg.BackgroundColor3 = Color3.fromRGB(40,40,40); bg.BorderSizePixel = 0; bg.Parent = bb
            local fill = Instance.new("Frame"); fill.Size = UDim2.new(l.HPPct or 1,0,1,0)
            fill.BackgroundColor3 = l.HPColor or col; fill.BorderSizePixel = 0; fill.Parent = bg
        end
    end
    bb.Parent = part; espObjs[part] = bb
end

task.spawn(function()
    while true do
        cleanStale()
        if State.ESP then
            pcall(function()
                local myPos = HRP.Position
                local active = {}
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj:FindFirstChildWhichIsA("Humanoid") then
                        local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                        local hum = obj:FindFirstChildWhichIsA("Humanoid")
                        if root and hum and (root.Position - myPos).Magnitude <= ESP_RANGE then
                            local n = obj.Name:lower()
                            local isP, isH = false, false
                            for _, plr in pairs(Players:GetPlayers()) do
                                if plr ~= LP and plr.Character and obj == plr.Character then isP = true; break end
                            end
                            if not isP then for _, h in pairs(Hostiles) do if n:find(h) then isH = true; break end end end
                            local hp = math.clamp(hum.Health/hum.MaxHealth,0,1)
                            local d = State.ESP_Distance and {Text=distStr(myPos,root.Position),Color=Color3.fromRGB(200,200,200),Align=Enum.TextXAlignment.Right} or nil
                            if State.ESP_Players and isP then
                                local l = {{Text=obj.Name,Color=Color3.fromRGB(0,255,0)}}
                                if d then table.insert(l,d) end
                                table.insert(l,{Text=string.format("HP %d/%d",math.floor(hum.Health),math.floor(hum.MaxHealth)),Color=hpColor(hp),HPBar=true,HPPct=hp,HPColor=hpColor(hp)})
                                mkBB(root,Color3.fromRGB(0,255,0),l); active[root]=true
                            elseif State.ESP_Enemies and isH then
                                local l = {{Text=obj.Name,Color=Color3.fromRGB(255,60,40)}}
                                if d then table.insert(l,d) end
                                table.insert(l,{Text=string.format("HP %d/%d",math.floor(hum.Health),math.floor(hum.MaxHealth)),Color=hpColor(hp),HPBar=true,HPPct=hp,HPColor=hpColor(hp)})
                                mkBB(root,Color3.fromRGB(255,60,40),l); active[root]=true
                            elseif State.ESP_Friendlies and not isP and not isH then
                                local l = {{Text=obj.Name,Color=Color3.fromRGB(0,200,255)}}
                                if d then table.insert(l,d) end
                                table.insert(l,{Text=string.format("HP %d/%d",math.floor(hum.Health),math.floor(hum.MaxHealth)),Color=hpColor(hp),HPBar=true,HPPct=hp,HPColor=hpColor(hp)})
                                mkBB(root,Color3.fromRGB(0,200,255),l); active[root]=true
                            end
                        end
                    elseif obj:IsA("Model") and not active[obj] then
                        local root = obj:FindFirstChildWhichIsA("BasePart")
                        if root and (root.Position - myPos).Magnitude <= ESP_RANGE then
                            local n = obj.Name:lower()
                            if State.ESP_Gold and (n:find("coin") or n:find("diamond") or n:find("gold") or n:find("gem")) then
                                local l = {{Text=obj.Name,Color=Color3.fromRGB(255,215,0)}}
                                if State.ESP_Distance then table.insert(l,{Text=distStr(myPos,root.Position),Color=Color3.fromRGB(200,200,200),Align=Enum.TextXAlignment.Right}) end
                                mkBB(root,Color3.fromRGB(255,215,0),l); active[root]=true
                            elseif State.ESP_Kids then
                                for _, kn in pairs(KidNames) do
                                    if n:find(kn) and (n:find("kid") or n:find("child")) then
                                        local l = {{Text="🧒 "..obj.Name,Color=Color3.fromRGB(255,150,255)}}
                                        if State.ESP_Distance then table.insert(l,{Text=distStr(myPos,root.Position),Color=Color3.fromRGB(255,200,255),Align=Enum.TextXAlignment.Right}) end
                                        mkBB(root,Color3.fromRGB(255,150,255),l); active[root]=true; break
                                    end
                                end
                            elseif State.ESP_Items and not active[root] then
                                for _, pat in pairs({"carrot","berry","mushroom","morsel","steak","fish","kelp","log","coal","iron","stone","scrap","egg","wood"}) do
                                    if n:find(pat) then
                                        local l = {{Text=obj.Name,Color=Color3.fromRGB(180,255,100)}}
                                        if State.ESP_Distance then table.insert(l,{Text=distStr(myPos,root.Position),Color=Color3.fromRGB(200,220,150),Align=Enum.TextXAlignment.Right}) end
                                        mkBB(root,Color3.fromRGB(180,255,100),l); active[root]=true; break
                                    end
                                end
                            end
                        end
                    end
                end
                for obj, bb in pairs(espObjs) do
                    if not active[obj] then pcall(function() if bb and bb.Parent then bb:Destroy() end end); espObjs[obj]=nil end
                end
            end)
        else clearAllESP() end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- RAYFIELD UI
-- ═══════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name = "⚡ PowerHub v10",
    Icon = 0,
    LoadingTitle = "PowerHub v10",
    LoadingSubtitle = "99 Nights in the Forest",
    ShowText = "PowerHub",
    Theme = "Default",
    ToggleUIKeybind = "K",
    ConfigurationSaving = {Enabled = true, FolderName = "PowerHub", FileName = "PowerHub_v10"},
    KeySystem = false,
})

-- TAB: CAMPFIRE
local T1 = Window:CreateTab("🔥 Campfire", 4483362458)
T1:CreateSection("Campfire")
T1:CreateToggle({Name = "Auto Campfire (Burn Fuel)", CurrentValue = false, Flag = "AutoCampfire", Callback = function(v) State.AutoCampfire = v end})
T1:CreateSection("Cooking")
T1:CreateToggle({Name = "Auto Cook", CurrentValue = false, Flag = "AutoCook", Callback = function(v) State.AutoCook = v end})
T1:CreateToggle({Name = "Auto Crockpot", CurrentValue = false, Flag = "AutoCrockpot", Callback = function(v) State.AutoCrockpot = v end})

-- TAB: COMBAT
local T2 = Window:CreateTab("⚔️ Combat", 4483362458)
T2:CreateSection("Defense")
T2:CreateToggle({Name = "🛡️ God Mode", CurrentValue = false, Flag = "GodMode", Callback = function(v) State.GodMode=v; if v then enableGodMode() else disableGodMode() end end})
T2:CreateSection("Offense")
T2:CreateToggle({Name = "Kill Aura", CurrentValue = false, Flag = "KillAura", Callback = function(v) State.KillAura = v end})
T2:CreateSlider({Name = "Kill Aura Range", Range = {5,50}, Increment = 1, Suffix = " studs", CurrentValue = 20, Flag = "KillAuraRange", Callback = function(v) Settings.KillAuraRange = v end})
T2:CreateToggle({Name = "Auto Stronghold", CurrentValue = false, Flag = "AutoStronghold", Callback = function(v) State.AutoStronghold = v end})

-- TAB: FARMING
local T3 = Window:CreateTab("⛏️ Farming", 4483362458)
T3:CreateSection("Chop")
T3:CreateToggle({Name = "Auto Chop Tree (No Teleport)", CurrentValue = false, Flag = "AutoChop", Callback = function(v) State.AutoChop = v end})
T3:CreateSlider({Name = "Chop Range", Range = {5,30}, Increment = 1, Suffix = " studs", CurrentValue = 15, Flag = "ChopRange", Callback = function(v) Settings.ChopRange = v end})
T3:CreateSection("Collect")
T3:CreateToggle({Name = "Auto Collect Coins", CurrentValue = false, Flag = "AutoGold", Callback = function(v) State.AutoGold = v end})
T3:CreateSlider({Name = "Coin Range", Range = {10,200}, Increment = 10, Suffix = " studs", CurrentValue = 100, Flag = "GoldRange", Callback = function(v) Settings.GoldRange = v end})
T3:CreateSection("Craft")
T3:CreateToggle({Name = "Auto Craft", CurrentValue = false, Flag = "AutoCraft", Callback = function(v) State.AutoCraft = v end})

-- TAB: MOVEMENT
local T4 = Window:CreateTab("🚀 Movement", 4483362458)
T4:CreateToggle({Name = "Fly", CurrentValue = false, Flag = "Fly", Callback = function(v) State.Fly = v end})
T4:CreateSlider({Name = "Fly Speed", Range = {10,200}, Increment = 5, Suffix = " studs/s", CurrentValue = 50, Flag = "FlySpeed", Callback = function(v) Settings.FlySpeed = v end})
T4:CreateToggle({Name = "NoClip", CurrentValue = false, Flag = "NoClip", Callback = function(v) State.NoClip = v end})
T4:CreateToggle({Name = "Anti AFK", CurrentValue = false, Flag = "AntiAFK", Callback = function(v) State.AntiAFK = v end})

-- TAB: VISUALS
local T5 = Window:CreateTab("👁️ Visuals", 4483362458)
T5:CreateSection("Master")
T5:CreateToggle({Name = "ESP Master", CurrentValue = false, Flag = "ESP", Callback = function(v) State.ESP = v end})
T5:CreateSection("Categories")
T5:CreateToggle({Name = "🟢 Players", CurrentValue = false, Flag = "ESP_Players", Callback = function(v) State.ESP_Players = v end})
T5:CreateToggle({Name = "🔴 Enemies", CurrentValue = false, Flag = "ESP_Enemies", Callback = function(v) State.ESP_Enemies = v end})
T5:CreateToggle({Name = "🔵 Friendlies", CurrentValue = false, Flag = "ESP_Friendlies", Callback = function(v) State.ESP_Friendlies = v end})
T5:CreateToggle({Name = "🟡 Coins/Gold", CurrentValue = false, Flag = "ESP_Gold", Callback = function(v) State.ESP_Gold = v end})
T5:CreateToggle({Name = "🟢 Items", CurrentValue = false, Flag = "ESP_Items", Callback = function(v) State.ESP_Items = v end})
T5:CreateToggle({Name = "🧒 Kids", CurrentValue = false, Flag = "ESP_Kids", Callback = function(v) State.ESP_Kids = v end})
T5:CreateSection("Options")
T5:CreateToggle({Name = "Show Distance", CurrentValue = true, Flag = "ESP_Distance", Callback = function(v) State.ESP_Distance = v end})

Rayfield:LoadConfiguration()
Rayfield:Notify({Title = "PowerHub v10", Content = "Based on real game data. Press K to toggle.", Duration = 3})
print("✅ PowerHub v10 loaded — real remotes")
