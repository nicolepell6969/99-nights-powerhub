-- ============================================
--  PowerHub - DATA DUMPER v1  (99 Nights)
--  Scan game structure: mobs, items, tools,
--  workspace folders, humanoids. Output = copy
--  & paste ke chat agar bisa dianalisis.
--  Usage: jalankan sekali di executor, salin
--  seluruh output ke chat.
-- ============================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local out = {}

local function log(...)
    local t = table.concat({...}, " ")
    table.insert(out, t)
    print(t)
end

log("===== POWERHUB DATA DUMPER mulai =====")
log("GameId: " .. tostring(game.GameId) .. " | PlaceId: " .. tostring(game.PlaceId) .. " | JobId: " .. tostring(game.JobId))
log("Player: " .. tostring(player and player.Name))

-- helper: get name path
local function pathOf(inst)
    local names = {}
    local p = inst
    while p do
        table.insert(names, 1, p.Name)
        p = p.Parent
    end
    return table.concat(names, ".")
end

-- ============ 1. WORKSPACE TOP-LEVEL ============
log("\n--- WORKSPACE top-level folders / objects ---")
for _, c in ipairs(Workspace:GetChildren()) do
    local cls = c.ClassName
    local kids = #c:GetChildren()
    log("  [" .. cls .. "] " .. c.Name .. "  (children: " .. tostring(kids) .. ")")
end

-- ============ 2. SCAN ALL MODELS WITH HUMANOID (mobs/NPCs) ============
log("\n--- MODELS with Humanoid (potential mobs/players) ---")
local seenMob = {}
local mobCount = 0
local function scanHumanoids(root, depth)
    if depth > 8 then return end
    for _, c in ipairs(root:GetChildren()) do
        if c:IsA("Model") then
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then
                if not seenMob[c] then
                    seenMob[c] = true
                    mobCount = mobCount + 1
                    local rootPart = c:FindFirstChild("HumanoidRootPart")
                    local health = hum.Health
                    local maxh = hum.MaxHealth
                    local isPlayer = Players:GetPlayerFromCharacter(c) ~= nil
                    local tag = isPlayer and "PLAYER" or "MOB/NPC"
                    log("  #" .. mobCount .. " [" .. tag .. "] " .. pathOf(c))
                    log("       Humanoid health=" .. tostring(math.floor(health)) .. "/" .. tostring(math.floor(maxh)) .. " | RootPart=" .. tostring(rootPart ~= nil))
                    -- list children classes to identify mob structure
                    local classes = {}
                    for _, pc in ipairs(c:GetChildren()) do
                        if not classes[pc.ClassName] then classes[pc.ClassName] = 0 end
                        classes[pc.ClassName] = classes[pc.ClassName] + 1
                    end
                    local cstr = {}
                    for k, v in pairs(classes) do table.insert(cstr, k .. ":" .. v) end
                    log("       children: " .. table.concat(cstr, ", "))
                end
            else
                scanHumanoids(c, depth + 1)
            end
        else
            scanHumanoids(c, depth + 1)
        end
    end
end
scanHumanoids(Workspace, 0)
if mobCount == 0 then log("  (tidak ada model dengan Humanoid ditemukan di Workspace scan ini)") end

-- ============ 3. ITEMS / TOOLS FOLDERS ============
log("\n--- FOLDERS/containers for items & tools ---")
local interestingNames = {"Item", "Items", "ItemDrop", "Drops", "Loot", "Chest", "Chests", "Pickup", "Pickups", "Resource", "Resources", "Tree", "Trees", "Ore", "Rocks", "Stone", "Gatherable"}
for _, c in ipairs(Workspace:GetChildren()) do
    local nm = c.Name:lower()
    for _, key in ipairs(interestingNames) do
        if nm:find(key:lower()) then
            log("  POTENTIAL ITEM FOLDER: [" .. c.ClassName .. "] " .. c.Name .. "  (children: " .. tostring(#c:GetChildren()) .. ")")
            -- sample first few children
            local count = 0
            for _, child in ipairs(c:GetChildren()) do
                if count < 8 then
                    log("      - [" .. child.ClassName .. "] " .. child.Name)
                    count = count + 1
                end
            end
            break
        end
    end
end

-- ============ 4. ReplicatedStorage structure ============
log("\n--- ReplicatedStorage top-level ---")
for _, c in ipairs(ReplicatedStorage:GetChildren()) do
    log("  [" .. c.ClassName .. "] " .. c.Name .. "  (children: " .. tostring(#c:GetChildren()) .. ")")
end

-- Remotes (for potential auto-collect / trigger features)
log("\n--- RemoteEvents/RemoteFunctions in ReplicatedStorage+Workspace ---")
local remoteCount = 0
local function scanRemotes(root, depth)
    if depth > 10 or remoteCount > 80 then return end
    for _, c in ipairs(root:GetChildren()) do
        if c:IsA("RemoteEvent") or c:IsA("RemoteFunction") or c:IsA("BindableEvent") then
            remoteCount = remoteCount + 1
            log("  #" .. remoteCount .. " [" .. c.ClassName .. "] " .. pathOf(c))
        else
            scanRemotes(c, depth + 1)
        end
    end
end
scanRemotes(ReplicatedStorage, 0)
scanRemotes(Workspace, 0)
if remoteCount == 0 then log("  (tidak ada remote ditemukan)") end

-- ============ 5. PLAYER BACKPACK (items player bawa) ============
if player then
    log("\n--- Player Backpack tools ---")
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, c in ipairs(bp:GetChildren()) do
            log("  [" .. c.ClassName .. "] " .. c.Name)
        end
    else
        log("  (no Backpack found)")
    end
    -- player leaderstats
    log("\n--- Player leaderstats ---")
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        for _, c in ipairs(ls:GetChildren()) do
            log("  [" .. c.ClassName .. "] " .. c.Name .. " = " .. tostring(c.Value))
        end
    else
        log("  (no leaderstats found)")
    end
    -- player character structure
    log("\n--- Player Character children ---")
    local char = player.Character
    if char then
        for _, c in ipairs(char:GetChildren()) do
            log("  [" .. c.ClassName .. "] " .. c.Name)
        end
    end
end

-- ============ 6. LIGHTING (fullbright helper) ============
log("\n--- Lighting ---")
log("  Brightness=" .. tostring(Lighting.Brightness) .. " ClockTime=" .. tostring(Lighting.ClockTime) .. " FogEnd=" .. tostring(Lighting.FogEnd))

log("\n===== POWERHUB DATA DUMPER selesai =====")
log("== Salin SEMUA output di atas ke chat. ==")

return table.concat(out, "\n")