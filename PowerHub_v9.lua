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
    Fly = false, NoClip = false, ESP = false,
}

local Settings = {
    CampfireFuel = "Logs",
    CookList = {"Morsel", "Steak", "Raw Steak", "Raw Morsel", "Fish", "Raw Fish",
                "Monster Meat", "Raw Monster Meat", "Kelp", "Raw Kelp"},
    ChopRange = 15, KillAuraRange = 20, FlySpeed = 50,
    GoldRange = 50, StrongholdRange = 100, AntiAFKInterval = 120,
}

-- ═══════════════════════════════════════════════════════════
-- AUTO CAMPFIRE
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AutoCampfire then
            pcall(function()
                local cf = workspace.Map.Campground:FindFirstChild("Campfire")
                    or workspace.Map.Campground:FindFirstChild("Fire")
                    or workspace.Map:FindFirstChild("Campfire")
                if not cf then return end

                for _, item in pairs(workspace:GetDescendants()) do
                    if not State.AutoCampfire then break end
                    if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") then
                        local n = item.Name:lower()
                        if n:find("coal") or n:find("log") or n:find("wood") or n:find("stick") then
                            local d = (item:GetPivot().Position - HRP.Position).Magnitude
                            if d < 50 then
                                pcall(function()
                                    fire("RequestStartDraggingItem", item)
                                    task.wait(0.3)
                                    fire("RequestThrowItem", cf.Position)
                                end)
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
-- AUTO CHOP
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AutoChop then
            pcall(function()
                for _, obj in pairs(workspace:GetDescendants()) do
                    if not State.AutoChop then break end
                    if obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") then
                        local n = obj.Name:lower()
                        if n:find("tree") or n:find("log") or n:find("birch") or n:find("pine") or n:find("oak") or n:find("dead") or n:find("super") then
                            local d = (obj:GetPivot().Position - HRP.Position).Magnitude
                            if d < Settings.ChopRange then
                                HRP.CFrame = obj:GetPivot() * CFrame.new(0, 0, 3)
                                task.wait(0.1)
                                pcall(function() fire("ToolDamageObject", obj) end)
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
-- AUTO COOK
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AutoCook then
            pcall(function()
                local cf = workspace.Map.Campground:FindFirstChild("Campfire")
                    or workspace.Map.Campground:FindFirstChild("Fire")
                    or workspace.Map:FindFirstChild("Campfire")
                if not cf then return end
                local fp = cf:GetPivot().Position

                for _, item in pairs(workspace:GetDescendants()) do
                    if not State.AutoCook then break end
                    if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") then
                        for _, cn in pairs(Settings.CookList) do
                            if item.Name:lower():find(cn:lower()) then
                                local d = (item:GetPivot().Position - HRP.Position).Magnitude
                                if d < 50 then
                                    pcall(function()
                                        item:SetPrimaryPartCFrame(CFrame.new(fp + Vector3.new(0, 5, 0)))
                                        task.wait(0.3)
                                        fire("RequestCookItem", item)
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
-- AUTO CROCKPOT
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AutoCrockpot then
            pcall(function()
                local cp = nil
                for _, obj in pairs(workspace.Map.Campground:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name:lower():find("crock") then cp = obj; break end
                end
                if not cp then return end
                local cpp = cp:GetPivot().Position

                local ings = {"Morsel", "Steak", "Monster Meat", "Fish", "Kelp", "Berry", "Carrot", "Mushroom", "Egg"}
                for _, item in pairs(workspace:GetDescendants()) do
                    if not State.AutoCrockpot then break end
                    if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") then
                        for _, ing in pairs(ings) do
                            if item.Name:lower():find(ing:lower()) then
                                local d = (item:GetPivot().Position - HRP.Position).Magnitude
                                if d < 50 then
                                    pcall(function()
                                        fire("RequestStartDraggingItem", item)
                                        task.wait(0.3)
                                        fire("RequestGiveItemToNPC", cp, item)
                                        fire("RequestThrowItem", cpp)
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
-- ESP
-- ═══════════════════════════════════════════════════════════
local espObjs = {}

local function mkESP(part, col, txt)
    if not part or espObjs[part] then return end
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0,200,0,50)
    bb.StudsOffset = Vector3.new(0,3,0)
    bb.AlwaysOnTop = true
    bb.Adornee = part
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = col
    lbl.TextStrokeTransparency = 0
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = txt
    lbl.Parent = bb
    bb.Parent = part
    espObjs[part] = bb
end

task.spawn(function()
    while true do
        if State.ESP then
            pcall(function()
                for p, bb in pairs(espObjs) do
                    if not p or not p.Parent then bb:Destroy(); espObjs[p] = nil end
                end
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LP and plr.Character then
                        local r = plr.Character:FindFirstChild("HumanoidRootPart")
                        if r then mkESP(r, Color3.fromRGB(0,255,0), plr.Name) end
                    end
                end
                for _, item in pairs(workspace:GetDescendants()) do
                    if item:IsA("Model") then
                        local n = item.Name:lower()
                        if n:find("gold") or n:find("diamond") or n:find("coin") then
                            local r = item:FindFirstChildWhichIsA("BasePart")
                            if r then mkESP(r, Color3.fromRGB(255,215,0), item.Name) end
                        end
                    end
                end
                for _, e in pairs(workspace:GetDescendants()) do
                    if e:IsA("Model") and e:FindFirstChildWhichIsA("Humanoid") then
                        local r = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChildWhichIsA("BasePart")
                        if r then
                            local isH = false
                            for _, h in pairs(Hostiles) do if e.Name:lower():find(h) then isH = true; break end end
                            local c = isH and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,200,255)
                            mkESP(r, c, e.Name .. " HP:" .. math.floor(e:FindFirstChildWhichIsA("Humanoid").Health))
                        end
                    end
                end
            end)
        end
        task.wait(1)
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
    ToggleUIKeybind = "RightControl",
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
Tab5:CreateSection("ESP")

Tab5:CreateToggle({
    Name = "ESP (Players + Items + Enemies)",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v) State.ESP = v end,
})

Tab5:CreateParagraph({
    Title = "ESP Colors",
    Content = "🟢 Green = Players | 🟡 Yellow = Gold/Diamonds | 🔴 Red = Hostiles | 🔵 Blue = Friendlies"
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
