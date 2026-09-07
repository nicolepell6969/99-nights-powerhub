--[[
    PowerHub Diagnostic — Run this in-game, copy ALL output
    Finds: real RemoteEvents, RemoteFunctions, workspace structure, item names
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

print("═══════════════════════════════════════════")
print("POWERHUB DIAGNOSTIC — PASTE THIS OUTPUT")
print("═══════════════════════════════════════════")

-- 1. ALL RemoteEvents
print("\n📡 REMOTE EVENTS:")
for _, v in pairs(RS:GetDescendants()) do
    if v:IsA("RemoteEvent") then
        print("  [RE] " .. v:GetFullName())
    end
end

-- 2. ALL RemoteFunctions
print("\n📡 REMOTE FUNCTIONS:")
for _, v in pairs(RS:GetDescendants()) do
    if v:IsA("RemoteFunction") then
        print("  [RF] " .. v:GetFullName())
    end
end

-- 3. Workspace.Map structure (top 3 levels)
print("\n🗺️ WORKSPACE.MAP:")
local map = workspace:FindFirstChild("Map")
if map then
    local function dumpTree(parent, depth, maxD)
        if depth > maxD then return end
        for _, v in pairs(parent:GetChildren()) do
            local prefix = string.rep("  ", depth)
            local extra = ""
            if v:IsA("Model") then
                local bp = v:FindFirstChildWhichIsA("BasePart")
                if bp then
                    extra = string.format(" [pos: %.0f,%.0f,%.0f]", bp.Position.X, bp.Position.Y, bp.Position.Z)
                end
            end
            print(prefix .. v.Name .. " (" .. v.ClassName .. ")" .. extra)
            if v:IsA("Model") or v:IsA("Folder") then
                dumpTree(v, depth + 1, maxD)
            end
        end
    end
    dumpTree(map, 0, 3)
else
    print("  Map not found!")
end

-- 4. Campfire detection
print("\n🔥 CAMPFIRE SEARCH:")
local found = false
for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("Model") then
        local n = v.Name:lower()
        if n:find("camp") or n:find("fire") or n:find("flame") then
            local bp = v:FindFirstChildWhichIsA("BasePart")
            local pos = bp and string.format("[%.0f,%.0f,%.0f]", bp.Position.X, bp.Position.Y, bp.Position.Z) or "[no part]"
            print("  FOUND: " .. v:GetFullName() .. " " .. pos)
            found = true
        end
    end
end
if not found then print("  None found") end

-- 5. Item names on ground (within 100 studs)
print("\n📦 ITEMS ON GROUND (100m):")
local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
if hrp then
    local count = 0
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildWhichIsA("BasePart") then
            local bp = v:FindFirstChildWhichIsA("BasePart")
            local d = (bp.Position - hrp.Position).Magnitude
            if d < 100 and v ~= LP.Character then
                print("  " .. v.Name .. " @ " .. math.floor(d) .. "m [" .. v.ClassName .. "]")
                count = count + 1
                if count > 50 then print("  ... (50+ items, truncated)"); break end
            end
        end
    end
    if count == 0 then print("  No items found nearby") end
end

-- 6. Trees (within 50m)
print("\n🌲 TREES (50m):")
if hrp then
    local count = 0
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildWhichIsA("BasePart") then
            local bp = v:FindFirstChildWhichIsA("BasePart")
            local d = (bp.Position - hrp.Position).Magnitude
            local n = v.Name:lower()
            if d < 50 and (n:find("tree") or n:find("log") or n:find("pine") or n:find("birch") or n:find("oak") or n:find("bush") or n:find("stump")) then
                print("  " .. v.Name .. " @ " .. math.floor(d) .. "m")
                count = count + 1
                if count > 20 then print("  ... (20+ trees, truncated)"); break end
            end
        end
    end
end

-- 7. Entities with Humanoid (within 100m)
print("\n👾 ENTITIES (100m):")
if hrp then
    local count = 0
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildWhichIsA("Humanoid") and v ~= LP.Character then
            local bp = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
            if bp then
                local d = (bp.Position - hrp.Position).Magnitude
                local hum = v:FindFirstChildWhichIsA("Humanoid")
                if d < 100 then
                    print("  " .. v.Name .. " HP:" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. " @ " .. math.floor(d) .. "m")
                    count = count + 1
                end
            end
        end
    end
    if count == 0 then print("  No entities nearby") end
end

-- 8. Player backpack (tools, items)
print("\n🎒 BACKPACK:")
local bp = LP:FindFirstChild("Backpack")
if bp then
    for _, v in pairs(bp:GetChildren()) do
        print("  " .. v.Name .. " [" .. v.ClassName .. "]")
    end
end

-- 9. Character tools
print("\n🔧 CHARACTER TOOLS:")
if LP.Character then
    for _, v in pairs(LP.Character:GetChildren()) do
        if v:IsA("Tool") then
            print("  " .. v.Name .. " [equipped]")
        end
    end
end

print("\n═══════════════════════════════════════════")
print("DONE — Copy ALL output above and paste it")
print("═══════════════════════════════════════════")
