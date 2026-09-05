-- ============================================
--  PowerHub - DATA DUMPER v2  (99 Nights)
--  Depth-dump ReplicatedStorage (full catalog
--  of kid/tool/item definitions) + query server
--  RemoteFunctions for map progress & state.
--  No need to travel (campfire-locked maps ok).
--  Copy ALL output & paste to chat.
-- ============================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local out = {}
local function log(...)
    local t = table.concat({...}," ")
    table.insert(out, t); print(t)
end

log("===== POWERHUB DATA DUMPER v2 mulai =====")
log("Player: " .. tostring(player and player.Name))

local function pathOf(inst)
    local n={}; local p=inst
    while p do table.insert(n,1,p.Name); p=p.Parent end
    return table.concat(n,".")
end

-- recursive dump of a folder tree with object type/name
local function dumpTree(root, depth, maxDepth, prefix)
    maxDepth = maxDepth or 20
    for _, c in ipairs(root:GetChildren()) do
        -- skip noisy internals
        if c:IsA("Camera") then
        else
            log(prefix .. "[" .. c.ClassName .. "] " .. c.Name)
            if depth < maxDepth then
                dumpTree(c, depth+1, maxDepth, prefix.."  ")
            end
        end
    end
end

-- ============ 1. DEPTH DUMP KEY FOLDERS ============
local keyFolders = { "Databases","Tools","Shops","Crafting Table","Containers","Configs","TempStorage","Assets" }
for _, fname in ipairs(keyFolders) do
    local f = ReplicatedStorage:FindFirstChild(fname)
    if f then
        log("\n=== ReplicatedStorage." .. fname .. "  (" .. tostring(#f:GetChildren()) .. " children) ===")
        dumpTree(f, 0, 3, "  ")
    else
        log("\n=== ReplicatedStorage." .. fname .. " = NOT FOUND ===")
    end
end

-- ============ 2. FULL TREE of ReplicatedStorage (shallow, 2 levels) ============
log("\n=== ReplicatedStorage full tree (depth 2) ===")
for _, c in ipairs(ReplicatedStorage:GetChildren()) do
    log("["..c.ClassName.."] "..c.Name)
    for _, c2 in ipairs(c:GetChildren()) do
        log("  ["..c2.ClassName.."] "..c2.Name)
    end
end

-- ============ 3. WORKSPACE.MAP.LANDMARKS (campfire-locked visible landmexports) ============
log("\n=== Workspace.Map structure ===")
local mapF = Workspace:FindFirstChild("Map")
if mapF then
    dumpTree(mapF, 0, 3, "  ")
else
    log("  (no Map folder)")
end

-- ============ 4. WORKSPACE.CHARACTERS names only (mob list, unique) ============
log("\n=== Unique Character/mob names ===")
local charsF = Workspace:FindFirstChild("Characters")
local mobNames = {}
if charsF then
    for _, c in ipairs(charsF:GetChildren()) do
        if not mobNames[c.Name] then mobNames[c.Name]=0 end
        mobNames[c.Name] = mobNames[c.Name]+1
    end
end
for k, v in pairs(mobNames) do log("  "..k.."  (x"..v..")") end
if not charsF then log("  (no Characters folder)") end

-- ============ 5. QUERY SERVER RemoteFunctions ============
log("\n=== RemoteFunction queries (server data) ===")
local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
local queryTargets = {
    "RequestServerMapProgress",
    "GetExtraState",
    "UpdateOwnedPets",
    "RequestBroadcastPing",
    "RequestMapIconReplay",
}
for _, rname in ipairs(queryTargets) do
    local r = re and re:FindFirstChild(rname)
    if r then
        local ok, res = pcall(function()
            return r:InvokeServer()
        end)
        if ok then
            log("  "..rname.." -> OK")
            log("      "..tostring(res))
        else
            log("  "..rname.." -> ERR "..tostring(res))
        end
    else
        log("  "..rname.." -> NOT FOUND")
    end
end

-- ============ 6. Find ANY object named like kid / missing ============
log("\n=== Search: kid/missing/child/dino/kraken named objects ===")
local function huntNames(root, depth)
    if depth > 8 then return end
    for _, c in ipairs(root:GetChildren()) do
        local nm = c.Name:lower()
        if nm:find("child") or nm:find("kid") or nm:find("missing") or nm:find("dino") or nm:find("kraken") or nm:find("save") then
            log("  FOUND: "..pathOf(c).."  ["..c.ClassName.."]")
        end
        huntNames(c, depth+1)
    end
end
huntNames(ReplicatedStorage, 0)
huntNames(Workspace, 0)

-- ============ 7. ReplicatedStorage.Tools list (full catalog) ============
log("\n=== ReplicatedStorage.Tools (item/tool definitions) ===")
local toolsF = ReplicatedStorage:FindFirstChild("Tools")
if toolsF then
    for _, c in ipairs(toolsF:GetChildren()) do
        log("  ["..c.ClassName.."] "..c.Name)
    end
else
    log("  (no Tools folder)")
end

log("\n===== POWERHUB DATA DUMPER v2 selesai =====")
log("== Salin SEMUA output ke chat. ==")
return table.concat(out,"\n")