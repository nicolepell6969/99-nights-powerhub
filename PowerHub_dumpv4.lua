-- ============================================
--  PowerHub - DATA DUMPER v4  (99 Nights)
--  Same as v3 but NEW FILENAME to bust the
--  "Real" executor's per-filename cache (v3 was
--  cached with the old HttpPost bug). Uses
--  HttpService:PostAsync -- reliable upload. 
-- ============================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ENDPOINT = "http://95.111.193.38/phdump/"
local TOKEN = "aWx035ytzsPCOBgmQmSeBYPy"

local out = {}
local function log(...)
    local t = table.concat({...}, " ")
    table.insert(out, t)
    -- also print so user sees progress live
    print(t)
end

log("===== POWERHUB DATA DUMPER v4 mulai =====")
log("Player: " .. tostring(player and player.Name))

local function pathOf(inst)
    local n={}; local p=inst
    while p do table.insert(n,1,p.Name); p=p.Parent end
    return table.concat(n,".")
end

local function dumpTree(root, depth, maxDepth, prefix)
    maxDepth = maxDepth or 12
    for _, c in ipairs(root:GetChildren()) do
        log(prefix .. "[" .. c.ClassName .. "] " .. c.Name)
        if depth < maxDepth then dumpTree(c, depth+1, maxDepth, prefix.."  ") end
    end
end

-- ============ 1. RELEVANT FULL DUMPS ============
-- (include everything; server truncation no longer matters because we POST)

-- Key ReplicatedStorage definition folders
local keyFolders = { "Databases","Tools","Shops","Crafting Table","Containers","Configs","TempStorage","Assets","Modules","Core" }
for _, fname in ipairs(keyFolders) do
    local f = ReplicatedStorage:FindFirstChild(fname)
    if f then
        log("\n=== ReplicatedStorage." .. fname .. "  (" .. tostring(#f:GetChildren()) .. " children) ===")
        dumpTree(f, 0, 4, "  ")
    else
        log("\n=== ReplicatedStorage." .. fname .. " = NOT FOUND ===")
    end
end

-- Kid-related (SPECIAL focus: locate all 4 kids & mechanics)
log("\n=== KIDS / MISSING CHILDREN (search) ===")
local function huntNames(root, depth)
    if depth > 10 then return end
    for _, c in ipairs(root:GetChildren()) do
        local nm = c.Name:lower()
        if nm:find("child") or nm:find("kid") or nm:find("missing") or nm:find("dino") or nm:find("kraken") or nm:find("squid") or nm:find("koala") or nm:find("save kid") then
            log("  FOUND: " .. pathOf(c) .. "  [" .. c.ClassName .. "]")
        end
        huntNames(c, depth+1)
    end
end
huntNames(ReplicatedStorage, 0)

log("\n=== MissingKids in Workspace ===")
local mk = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("MissingKids")
if mk then
    dumpTree(mk, 0, 4, "  ")
else
    log("  (Workspace.Map.MissingKids NOT FOUND)")
end

-- Unique mob names
log("\n=== Unique Character/mob names ===")
local charsF = Workspace:FindFirstChild("Characters")
local mobNames = {}
if charsF then
    for _, c in ipairs(charsF:GetChildren()) do
        mobNames[c.Name] = (mobNames[c.Name] or 0) + 1
    end
    for k, v in pairs(mobNames) do log("  " .. k .. "  (x" .. v .. ")") end
else
    log("  (no Characters folder)")
end

-- Full Tools catalog
log("\n=== ReplicatedStorage.Tools ===")
local toolsF = ReplicatedStorage:FindFirstChild("Tools")
if toolsF then for _, c in ipairs(toolsF:GetChildren()) do log("  ["..c.ClassName.."] "..c.Name) end end

-- Workspace.Items sample
log("\n=== Workspace.Items (first 120) ===")
local itemsF = Workspace:FindFirstChild("Items")
if itemsF then
    local count = 0
    for _, c in ipairs(itemsF:GetChildren()) do
        if count >= 120 then break end
        log("  ["..c.ClassName.."] "..c.Name)
        count = count + 1
    end
    log("  ... total: "..tostring(#itemsF:GetChildren()))
else log("  (no Items folder)") end

-- RemoteEvents (full list)
log("\n=== RemoteEvents (full) ===")
local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
if re then for _, c in ipairs(re:GetChildren()) do log("  ["..c.ClassName.."] "..c.Name) end end

log("\n===== POWERHUB DATA DUMPER v3 selesai =====")

-- ============ SEND VIA POST ============
local fullDump = table.concat(out, "\n")
log("\n[Dump size: "..tostring(#fullDump).." chars]")

-- POST in background thread (large body) via HttpService:PostAsync (executor-safe)
task.spawn(function()
    local ok, result = pcall(function()
        local http = game:GetService("HttpService")
        local url = ENDPOINT .. "?token=" .. TOKEN .. "&name=dumpv3_" .. tostring(os.time())
        -- PostAsync(url, body, contentType, compress) returns response string
        return http:PostAsync(url, fullDump, "application/x-www-form-urlencoded", false)
    end)
    if ok then
        print("✅ DUMP UPLOADED. Cek GitHub /dumps/dumpv3_*.txt")
        print("   Response: " .. tostring(result))
    else
        print("❌ Upload GAGAL: " .. tostring(result))
        print("   Jangan copy manual — ini penampung. Detail:")
        print("   " .. tostring(result))
    end
end)

return fullDump