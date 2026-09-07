--[[
    PowerHub Diagnostic v2 — Auto-save ke file
    Run this, output akan otomatis tersimpan di executor folder.
    Cari file "powerhub_diagnostic.txt" di workspace folder executor.
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")

local out = {}
local function p(s) table.insert(out, s) end

p("═══════════════════════════════════════════")
p("POWERHUB DIAGNOSTIC v2")
p("Player: " .. LP.Name)
p("Place: " .. game.PlaceId)
p("Time: " .. os.date())
p("═══════════════════════════════════════════")

-- 1. ALL RemoteEvents + RemoteFunctions
p("\n📡 REMOTE EVENTS:")
for _, v in pairs(RS:GetDescendants()) do
    if v:IsA("RemoteEvent") then
        p("  [RE] " .. v:GetFullName())
    end
end

p("\n📡 REMOTE FUNCTIONS:")
for _, v in pairs(RS:GetDescendants()) do
    if v:IsA("RemoteFunction") then
        p("  [RF] " .. v:GetFullName())
    end
end

-- 2. Workspace.Map top 3 levels
p("\n🗺️ WORKSPACE.MAP:")
local map = workspace:FindFirstChild("Map")
if map then
    local function dump(parent, depth, maxD)
        if depth > maxD then return end
        for _, v in pairs(parent:GetChildren()) do
            local pre = string.rep("  ", depth)
            local extra = ""
            if v:IsA("Model") then
                local bp = v:FindFirstChildWhichIsA("BasePart")
                if bp then extra = string.format(" @ [%.0f,%.0f,%.0f]", bp.Position.X, bp.Position.Y, bp.Position.Z) end
            end
            p(pre .. v.Name .. " (" .. v.ClassName .. ")" .. extra)
            if v:IsA("Model") or v:IsA("Folder") then dump(v, depth + 1, maxD) end
        end
    end
    dump(map, 0, 3)
else
    p("  Map not found!")
end

-- 3. Campfire search
p("\n🔥 CAMPFIRE SEARCH:")
local found = false
for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("Model") then
        local n = v.Name:lower()
        if n:find("camp") or n:find("fire") or n:find("flame") then
            local bp = v:FindFirstChildWhichIsA("BasePart")
            local pos = bp and string.format("[%.0f,%.0f,%.0f]", bp.Position.X, bp.Position.Y, bp.Position.Z) or "[no part]"
            p("  FOUND: " .. v:GetFullName() .. " " .. pos)
            found = true
        end
    end
end
if not found then p("  None found") end

-- 4. Items on ground (within 100m)
p("\n📦 ITEMS (100m):")
if hrp then
    local count = 0
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildWhichIsA("BasePart") and v ~= LP.Character then
            local bp = v:FindFirstChildWhichIsA("BasePart")
            local d = (bp.Position - hrp.Position).Magnitude
            if d < 100 then
                p("  " .. v.Name .. " @ " .. math.floor(d) .. "m")
                count = count + 1
                if count > 80 then p("  ... (80+ truncated)"); break end
            end
        end
    end
    if count == 0 then p("  No items nearby") end
end

-- 5. Trees (within 50m)
p("\n🌲 TREES (50m):")
if hrp then
    local count = 0
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildWhichIsA("BasePart") then
            local bp = v:FindFirstChildWhichIsA("BasePart")
            local d = (bp.Position - hrp.Position).Magnitude
            local n = v.Name:lower()
            if d < 50 and (n:find("tree") or n:find("log") or n:find("pine") or n:find("birch") or n:find("oak") or n:find("bush") or n:find("stump")) then
                p("  " .. v.Name .. " @ " .. math.floor(d) .. "m")
                count = count + 1
                if count > 30 then p("  ... (30+ truncated)"); break end
            end
        end
    end
end

-- 6. Entities with Humanoid (within 100m)
p("\n👾 ENTITIES (100m):")
if hrp then
    local count = 0
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildWhichIsA("Humanoid") and v ~= LP.Character then
            local bp = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
            if bp then
                local d = (bp.Position - hrp.Position).Magnitude
                local hum = v:FindFirstChildWhichIsA("Humanoid")
                if d < 100 then
                    p("  " .. v.Name .. " HP:" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. " @ " .. math.floor(d) .. "m")
                    count = count + 1
                end
            end
        end
    end
    if count == 0 then p("  No entities nearby") end
end

-- 7. Backpack + Character tools
p("\n🎒 BACKPACK:")
local bp = LP:FindFirstChild("Backpack")
if bp then for _, v in pairs(bp:GetChildren()) do p("  " .. v.Name .. " [" .. v.ClassName .. "]") end end

p("\n🔧 TOOLS EQUIPPED:")
if LP.Character then
    for _, v in pairs(LP.Character:GetChildren()) do
        if v:IsA("Tool") then p("  " .. v.Name) end
    end
end

p("\n═══════════════════════════════════════════")
p("DONE")

-- ═══ SAVE TO FILE ═══
local content = table.concat(out, "\n")
writefile("powerhub_diagnostic.txt", content)
print("✅ Diagnostic saved! File: powerhub_diagnostic.txt")
print("📂 Location: " .. (isfolder and "workspace folder" or "executor folder"))
print("Length: " .. #content .. " chars, " .. #out .. " lines")
