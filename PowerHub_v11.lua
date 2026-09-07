--[[
    PowerHub v11 — 99 Nights in the Forest
    Based on REAL remote spy arguments (verified)
    UI: Rayfield Interface Suite
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local Char = LP.Character or LP.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")
local Hum = Char:WaitForChild("Humanoid")

LP.CharacterAdded:Connect(function(c)
    Char = c; HRP = c:WaitForChild("HumanoidRootPart"); Hum = c:WaitForChild("Humanoid")
end)

-- ═══════════════════════════════════════════════════════════
-- REMOTES (verified from diagnostic)
-- ═══════════════════════════════════════════════════════════
local RE = RS:WaitForChild("RemoteEvents")

local function fire(name, ...) local r = RE:FindFirstChild(name); if r and r:IsA("RemoteEvent") then r:FireServer(...) end end
local function invoke(name, ...) local r = RE:FindFirstChild(name); if r and r:IsA("RemoteFunction") then return r:InvokeServer(...) end end

-- ═══════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════
local function getTool()
    -- Find equipped tool or first tool in Backpack
    local t = Char:FindFirstChildWhichIsA("Tool")
    if t then return t end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, v in pairs(bp:GetChildren()) do
            if v:IsA("Tool") then return v end
        end
    end
    return nil
end

local function getBag()
    local inv = Char:FindFirstChild("Inventory") or LP:FindFirstChild("Inventory")
    if inv then
        for _, v in pairs(inv:GetChildren()) do
            if v.Name:lower():find("sack") or v.Name:lower():find("bag") then return v end
        end
    end
    return nil
end

local function getTempItem(name)
    local ts = RS:FindFirstChild("TempStorage")
    if ts then return ts:FindFirstChild(name) end
    return nil
end

local function getCraftingBench()
    local cg = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Campground")
    if cg then
        for _, v in pairs(cg:GetDescendants()) do
            if v:IsA("Model") and v.Name:lower():find("crafting") then return v end
        end
    end
    return nil
end

local function getScrapper()
    local cg = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Campground")
    if cg then
        for _, v in pairs(cg:GetDescendants()) do
            if v:IsA("Model") and v.Name:lower():find("scrap") then return v end
        end
    end
    return nil
end

local function isFuel(name)
    local n = name:lower()
    return n:find("log") or n:find("coal") or n:find("fuel") or n:find("oil")
        or n:find("biofuel") or n:find("wood") or n:find("stick") or n:find("branch")
        or n:find("plank") or n:find("charcoal") or n:find("pumpkin")
end

local function isCookable(name)
    local n = name:lower()
    return n:find("raw") or n:find("morsel") or n:find("steak") or n:find("fish")
        or n:find("meat") or n:find("kelp") or n:find("berry") or n:find("carrot")
        or n:find("mushroom") or n:find("egg") or n:find("frog") or n:find("bunny leg")
end

local function isTree(name)
    local n = name:lower()
    return n:find("small tree") or n:find("treebig") or n:find("bush") or n:find("stump")
        or n:find("log pile") or n:find("dead tree") or n:find("brightwood") or n:find("sapling")
end

-- ═══════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════
local State = {
    AutoCampfire = false, AutoCook = false, AutoChop = false,
    AutoGold = false, AutoCraft = false, AutoScrap = false,
    AutoStronghold = false, KillAura = false, AntiAFK = false,
    Fly = false, NoClip = false, GodMode = false, ESP = false,
    ESP_Players = false, ESP_Enemies = false, ESP_Friendlies = false,
    ESP_Gold = false, ESP_Items = false, ESP_Distance = true,
}
local Settings = {
    ChopRange = 15, KillAuraRange = 20, FlySpeed = 50,
    GoldRange = 100, AntiAFKInterval = 120, ChopDelay = 0.4,
}

-- ═══════════════════════════════════════════════════════════
-- AUTO CHOP — ToolDamageObject (5 args, verified!)
-- ═══════════════════════════════════════════════════════════
local chopHitCounter = 0

task.spawn(function()
    while true do
        if State.AutoChop then
            pcall(function()
                local tool = getTool()
                if not tool then return end

                for _, obj in pairs(workspace:GetDescendants()) do
                    if not State.AutoChop then break end
                    if obj:IsA("Model") and isTree(obj.Name) then
                        local d = (obj:GetPivot().Position - HRP.Position).Magnitude
                        if d <= Settings.ChopRange then
                            chopHitCounter = chopHitCounter + 1
                            -- VERIFIED ARGUMENTS from remote spy:
                            -- [1] target, [2] tool, [3] "hitCount_assetId", [4] CFrame, [5] false
                            local hitStr = chopHitCounter .. "_11603799514"
                            invoke("ToolDamageObject", obj, tool, hitStr, tool:GetPivot(), false)
                            task.wait(Settings.ChopDelay)
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO CAMPFIRE — RequestBurnItem + drag fallback
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AutoCampfire then
            pcall(function()
                for _, item in pairs(workspace:GetDescendants()) do
                    if not State.AutoCampfire then break end
                    if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") and isFuel(item.Name) then
                        local d = (item:GetPivot().Position - HRP.Position).Magnitude
                        if d < 60 then
                            -- Method 1: RequestBurnItem
                            fire("RequestBurnItem", item)
                            task.wait(0.2)
                            -- Method 2: drag + throw at campfire [0,2,0]
                            fire("RequestStartDraggingItem", item)
                            task.wait(0.3)
                            fire("RequestThrowItem", Vector3.new(0, 2, 0))
                            task.wait(0.5)
                            -- Method 3: BurnItemInFire
                            fire("BurnItemInFire", item)
                            task.wait(0.3)
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO COOK — RequestCookItem + RequestConsumeItem fallback
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AutoCook then
            pcall(function()
                local firePos = Vector3.new(0, 4, 0) -- MainFire @ [0,2,0]
                for _, item in pairs(workspace:GetDescendants()) do
                    if not State.AutoCook then break end
                    if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") and isCookable(item.Name) then
                        local d = (item:GetPivot().Position - HRP.Position).Magnitude
                        if d < 60 then
                            -- Teleport food to fire
                            pcall(function() item:SetPrimaryPartCFrame(CFrame.new(firePos)) end)
                            task.wait(0.3)
                            fire("RequestCookItem", item)
                            task.wait(0.5)
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO COLLECT COINS — RequestCollectCoints (RF, verified)
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
                            if root and (root.Position - HRP.Position).Magnitude < Settings.GoldRange then
                                invoke("RequestCollectCoints", item)
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
-- AUTO CRAFT — CraftItem (RF) + RequestSelectRecipe (RE)
-- ═══════════════════════════════════════════════════════════
local CraftRecipes = {"Axe", "Iron Axe", "Gold Axe", "Torch", "Flashlight",
    "Bandage", "Medkit", "Armor", "Iron Armor", "Spear", "Iron Spear",
    "Arrow", "Fire Arrow", "Stone Wall", "Wood Wall", "Wooden Chair",
    "Wooden Table", "Sapling", "Old Sack", "Giant Sack"}

task.spawn(function()
    while true do
        if State.AutoCraft then
            pcall(function()
                local bench = getCraftingBench()
                if bench then
                    local d = (bench:GetPivot().Position - HRP.Position).Magnitude
                    if d < 30 then
                        for _, recipe in pairs(CraftRecipes) do
                            fire("RequestSelectRecipe", recipe)
                            task.wait(0.1)
                            invoke("CraftItem", recipe)
                            task.wait(0.2)
                        end
                    end
                end
            end)
        end
        task.wait(3)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO SCRAP — RequestScrapItem (RF, verified!)
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AutoScrap then
            pcall(function()
                local bench = getCraftingBench()
                if not bench then return end
                -- Find items in bag/inventory to scrap
                local inv = Char:FindFirstChild("Inventory") or LP:FindFirstChild("Inventory")
                if inv then
                    for _, item in pairs(inv:GetChildren()) do
                        if not State.AutoScrap then break end
                        if item:IsA("Model") then
                            -- VERIFIED: RequestScrapItem(bench, item)
                            invoke("RequestScrapItem", bench, item)
                            task.wait(0.3)
                        end
                    end
                end
            end)
        end
        task.wait(2)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO STRONGHOLD — RequestTeleport
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AutoStronghold then
            pcall(function()
                for _, obj in pairs(workspace:GetDescendants()) do
                    if not State.AutoStronghold then break end
                    if obj:IsA("Model") and (obj.Name:lower():find("stronghold") or obj.Name:lower():find("boss")) then
                        if (obj:GetPivot().Position - HRP.Position).Magnitude > 50 then
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
-- KILL AURA — ToolDamageObject on enemies
-- ═══════════════════════════════════════════════════════════
local Hostiles = {"wolf", "bear", "deer", "mammoth", "fox", "polar", "alpha",
    "entity", "hostile", "monster", "spider", "snake", "bat", "zombie", "cultist"}

task.spawn(function()
    while true do
        if State.KillAura then
            pcall(function()
                local tool = getTool()
                if not tool then return end
                for _, e in pairs(workspace:GetDescendants()) do
                    if not State.KillAura then break end
                    if e:IsA("Model") and e:FindFirstChildWhichIsA("Humanoid") then
                        local hum = e:FindFirstChildWhichIsA("Humanoid")
                        local root = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChildWhichIsA("BasePart")
                        if hum and hum.Health > 0 and root then
                            local n = e.Name:lower()
                            for _, h in pairs(Hostiles) do
                                if n:find(h) and (root.Position - HRP.Position).Magnitude < Settings.KillAuraRange then
                                    -- Same format as ToolDamageObject for trees
                                    chopHitCounter = chopHitCounter + 1
                                    invoke("ToolDamageObject", e, tool, chopHitCounter .. "_11603799514", tool:GetPivot(), false)
                                    task.wait(0.2)
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
            pcall(function() game:GetService("VirtualUser"):CaptureController(); game:GetService("VirtualUser"):ClickButton2(Vector2.new()) end)
            fire("RequestBroadcastPing")
        end
        task.wait(Settings.AntiAFKInterval)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- GOD MODE
-- ═══════════════════════════════════════════════════════════
local godConn = nil
local function enableGM()
    if godConn then pcall(function() godConn:Disconnect() end) end
    godConn = Hum.HealthChanged:Connect(function()
        if State.GodMode and Hum.Health < Hum.MaxHealth then Hum.Health = Hum.MaxHealth end
    end)
    pcall(function() Hum.Health = Hum.MaxHealth end)
end
local function disableGM() if godConn then pcall(function() godConn:Disconnect() end); godConn = nil end end
LP.CharacterAdded:Connect(function() if State.GodMode then task.wait(1); enableGM() end end)

-- ═══════════════════════════════════════════════════════════
-- FLY + NOCLIP
-- ═══════════════════════════════════════════════════════════
local flyBV, flyBG
RunService.Heartbeat:Connect(function()
    if State.Fly then
        if not flyBV then flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.new(math.huge,math.huge,math.huge); flyBV.Parent = HRP end
        if not flyBG then flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque = Vector3.new(math.huge,math.huge,math.huge); flyBG.P = 9e4; flyBG.Parent = HRP end
        local cam = workspace.CurrentCamera.CFrame
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        flyBV.Velocity = dir * Settings.FlySpeed; flyBG.CFrame = cam
    else
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
    end
end)
RunService.Stepped:Connect(function()
    if State.NoClip and Char then for _, p in pairs(Char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
end)

-- ═══════════════════════════════════════════════════════════
-- ESP (optimized)
-- ═══════════════════════════════════════════════════════════
local espObjs, ESP_RANGE = {}, 200
local function clearESP() for _,bb in pairs(espObjs) do pcall(function() if bb and bb.Parent then bb:Destroy() end end) end; espObjs = {} end
local function hpC(p) return p>0.5 and Color3.fromRGB(0,255,80) or p>0.25 and Color3.fromRGB(255,200,0) or Color3.fromRGB(255,50,30) end
local function dStr(a,b) return string.format("[%.0fm]",(a-b).Magnitude) end
local function mkBB(part,col,lines)
    if not part then return end
    if espObjs[part] then pcall(function() espObjs[part]:Destroy() end); espObjs[part]=nil end
    local bb=Instance.new("BillboardGui"); bb.Name="PH_ESP"; bb.Size=UDim2.new(0,220,0,#lines*16+8)
    bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true; bb.LightInfluence=0; bb.Adornee=part
    for i,l in ipairs(lines) do
        local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-8,0,16); lbl.Position=UDim2.new(0,4,0,(i-1)*16+4)
        lbl.BackgroundTransparency=1; lbl.TextColor3=l.Color or col; lbl.TextStrokeColor3=Color3.new(0,0,0); lbl.TextStrokeTransparency=0.2
        lbl.TextSize=12; lbl.Font=Enum.Font.GothamBold; lbl.TextXAlignment=l.Align or Enum.TextXAlignment.Left; lbl.Text=l.Text or ""; lbl.Parent=bb
        if l.HPBar then
            local bg=Instance.new("Frame"); bg.Size=UDim2.new(1,-8,0,4); bg.Position=UDim2.new(0,4,0,(i-1)*16+18)
            bg.BackgroundColor3=Color3.fromRGB(40,40,40); bg.BorderSizePixel=0; bg.Parent=bb
            local fill=Instance.new("Frame"); fill.Size=UDim2.new(l.Pct or 1,0,1,0); fill.BackgroundColor3=l.HPC or col; fill.BorderSizePixel=0; fill.Parent=bg
        end
    end; bb.Parent=part; espObjs[part]=bb
end
task.spawn(function()
    while true do
        for obj,bb in pairs(espObjs) do if not obj or not obj.Parent then pcall(function() if bb and bb.Parent then bb:Destroy() end end); espObjs[obj]=nil end end
        if State.ESP then
            pcall(function()
                local myPos=HRP.Position; local active={}
                for _,obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj:FindFirstChildWhichIsA("Humanoid") then
                        local root=obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                        local hum=obj:FindFirstChildWhichIsA("Humanoid")
                        if root and hum and (root.Position-myPos).Magnitude<=ESP_RANGE then
                            local n=obj.Name:lower(); local isP,isH=false,false
                            for _,plr in pairs(Players:GetPlayers()) do if plr~=LP and plr.Character and obj==plr.Character then isP=true;break end end
                            if not isP then for _,h in pairs(Hostiles) do if n:find(h) then isH=true;break end end end
                            local hp=math.clamp(hum.Health/hum.MaxHealth,0,1)
                            local d=State.ESP_Distance and {Text=dStr(myPos,root.Position),Color=Color3.fromRGB(200,200,200),Align=Enum.TextXAlignment.Right} or nil
                            if State.ESP_Players and isP then
                                local l={{Text=obj.Name,Color=Color3.fromRGB(0,255,0)}};if d then table.insert(l,d) end
                                table.insert(l,{Text=string.format("HP %d/%d",math.floor(hum.Health),math.floor(hum.MaxHealth)),Color=hpC(hp),HPBar=true,Pct=hp,HPC=hpC(hp)})
                                mkBB(root,Color3.fromRGB(0,255,0),l);active[root]=true
                            elseif State.ESP_Enemies and isH then
                                local l={{Text=obj.Name,Color=Color3.fromRGB(255,60,40)}};if d then table.insert(l,d) end
                                table.insert(l,{Text=string.format("HP %d/%d",math.floor(hum.Health),math.floor(hum.MaxHealth)),Color=hpC(hp),HPBar=true,Pct=hp,HPC=hpC(hp)})
                                mkBB(root,Color3.fromRGB(255,60,40),l);active[root]=true
                            elseif State.ESP_Friendlies and not isP and not isH then
                                local l={{Text=obj.Name,Color=Color3.fromRGB(0,200,255)}};if d then table.insert(l,d) end
                                table.insert(l,{Text=string.format("HP %d/%d",math.floor(hum.Health),math.floor(hum.MaxHealth)),Color=hpC(hp),HPBar=true,Pct=hp,HPC=hpC(hp)})
                                mkBB(root,Color3.fromRGB(0,200,255),l);active[root]=true
                            end
                        end
                    elseif obj:IsA("Model") and not active[obj] then
                        local root=obj:FindFirstChildWhichIsA("BasePart")
                        if root and (root.Position-myPos).Magnitude<=ESP_RANGE then
                            local n=obj.Name:lower()
                            if State.ESP_Gold and (n:find("coin") or n:find("diamond") or n:find("gold")) then
                                local l={{Text=obj.Name,Color=Color3.fromRGB(255,215,0)}};if State.ESP_Distance then table.insert(l,{Text=dStr(myPos,root.Position),Color=Color3.fromRGB(200,200,200),Align=Enum.TextXAlignment.Right}) end;mkBB(root,Color3.fromRGB(255,215,0),l);active[root]=true
                            elseif State.ESP_Items and not active[root] then
                                for _,p in pairs({"carrot","berry","mushroom","morsel","steak","fish","kelp","log","coal","iron","stone","scrap","egg","wood","sapling"}) do
                                    if n:find(p) then local l={{Text=obj.Name,Color=Color3.fromRGB(180,255,100)}};if State.ESP_Distance then table.insert(l,{Text=dStr(myPos,root.Position),Color=Color3.fromRGB(200,220,150),Align=Enum.TextXAlignment.Right}) end;mkBB(root,Color3.fromRGB(180,255,100),l);active[root]=true;break end
                                end
                            end
                        end
                    end
                end
                for obj,bb in pairs(espObjs) do if not active[obj] then pcall(function() if bb and bb.Parent then bb:Destroy() end end);espObjs[obj]=nil end end
            end)
        else clearESP() end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- RAYFIELD UI
-- ═══════════════════════════════════════════════════════════
local W = Rayfield:CreateWindow({Name="⚡ PowerHub v11",Icon=0,LoadingTitle="PowerHub v11",LoadingSubtitle="99 Nights in the Forest",ShowText="PowerHub",Theme="Default",ToggleUIKeybind="K",ConfigurationSaving={Enabled=true,FolderName="PowerHub",FileName="PowerHub_v11"},KeySystem=false})

local T1=W:CreateTab("🔥 Campfire",4483362458)
T1:CreateSection("Campfire")
T1:CreateToggle({Name="Auto Campfire (Burn Fuel)",CurrentValue=false,Flag="AC",Callback=function(v)State.AutoCampfire=v end})
T1:CreateSection("Cooking")
T1:CreateToggle({Name="Auto Cook",CurrentValue=false,Flag="AK",Callback=function(v)State.AutoCook=v end})

local T2=W:CreateTab("⚔️ Combat",4483362458)
T2:CreateSection("Defense")
T2:CreateToggle({Name="🛡️ God Mode",CurrentValue=false,Flag="GM",Callback=function(v)State.GodMode=v;if v then enableGM()else disableGM()end end})
T2:CreateSection("Offense")
T2:CreateToggle({Name="Kill Aura",CurrentValue=false,Flag="KA",Callback=function(v)State.KillAura=v end})
T2:CreateSlider({Name="Kill Aura Range",Range={5,50},Increment=1,Suffix=" studs",CurrentValue=20,Flag="KAR",Callback=function(v)Settings.KillAuraRange=v end})
T2:CreateToggle({Name="Auto Stronghold",CurrentValue=false,Flag="AS",Callback=function(v)State.AutoStronghold=v end})

local T3=W:CreateTab("⛏️ Farming",4483362458)
T3:CreateSection("Chop (No Teleport)")
T3:CreateToggle({Name="Auto Chop Tree",CurrentValue=false,Flag="AC2",Callback=function(v)State.AutoChop=v end})
T3:CreateSlider({Name="Chop Range",Range={5,30},Increment=1,Suffix=" studs",CurrentValue=15,Flag="CR",Callback=function(v)Settings.ChopRange=v end})
T3:CreateSlider({Name="Chop Delay",Range={0.2,1.0},Increment=0.1,Suffix="s",CurrentValue=0.4,Flag="CD",Callback=function(v)Settings.ChopDelay=v end})
T3:CreateSection("Collect")
T3:CreateToggle({Name="Auto Collect Coins",CurrentValue=false,Flag="AG",Callback=function(v)State.AutoGold=v end})
T3:CreateSection("Craft & Scrap")
T3:CreateToggle({Name="Auto Craft",CurrentValue=false,Flag="ACR",Callback=function(v)State.AutoCraft=v end})
T3:CreateToggle({Name="Auto Scrap",CurrentValue=false,Flag="ASC",Callback=function(v)State.AutoScrap=v end})

local T4=W:CreateTab("🚀 Movement",4483362458)
T4:CreateToggle({Name="Fly",CurrentValue=false,Flag="FL",Callback=function(v)State.Fly=v end})
T4:CreateSlider({Name="Fly Speed",Range={10,200},Increment=5,Suffix=" studs/s",CurrentValue=50,Flag="FS",Callback=function(v)Settings.FlySpeed=v end})
T4:CreateToggle({Name="NoClip",CurrentValue=false,Flag="NC",Callback=function(v)State.NoClip=v end})
T4:CreateToggle({Name="Anti AFK",CurrentValue=false,Flag="AA",Callback=function(v)State.AntiAFK=v end})

local T5=W:CreateTab("👁️ Visuals",4483362458)
T5:CreateSection("Master")
T5:CreateToggle({Name="ESP Master",CurrentValue=false,Flag="ESP",Callback=function(v)State.ESP=v end})
T5:CreateSection("Categories")
T5:CreateToggle({Name="🟢 Players",CurrentValue=false,Flag="ESP1",Callback=function(v)State.ESP_Players=v end})
T5:CreateToggle({Name="🔴 Enemies",CurrentValue=false,Flag="ESP2",Callback=function(v)State.ESP_Enemies=v end})
T5:CreateToggle({Name="🔵 Friendlies",CurrentValue=false,Flag="ESP3",Callback=function(v)State.ESP_Friendlies=v end})
T5:CreateToggle({Name="🟡 Coins/Gold",CurrentValue=false,Flag="ESP4",Callback=function(v)State.ESP_Gold=v end})
T5:CreateToggle({Name="🟢 Items",CurrentValue=false,Flag="ESP5",Callback=function(v)State.ESP_Items=v end})
T5:CreateSection("Options")
T5:CreateToggle({Name="Show Distance",CurrentValue=true,Flag="ESPD",Callback=function(v)State.ESP_Distance=v end})

Rayfield:LoadConfiguration()
Rayfield:Notify({Title="PowerHub v11",Content="Real args from remote spy. Press K.",Duration=3})
print("✅ PowerHub v11 — verified remote arguments")
