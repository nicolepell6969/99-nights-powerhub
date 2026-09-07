--[[
    PowerHub Remote Spy — Capture ALL remote arguments
    Run this, play normally (burn fuel, chop tree, cook, craft)
    All captured data auto-saved to file
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local out = {}
local function p(s) table.insert(out, s) end
local seen = {}

p("═══════════════════════════════════════════")
p("REMOTE SPY — Capture arguments")
p("Time: " .. os.date())
p("PLAY THE GAME NOW: burn fuel, chop tree,")
p("cook food, craft, attack enemies, etc.")
p("Wait 60s then the file auto-saves.")
p("═══════════════════════════════════════════")

local RE = RS:WaitForChild("RemoteEvents")

-- ══ Hook ALL RemoteEvents ══
for _, remote in pairs(RE:GetChildren()) do
    if remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(function(...)
            local key = remote.Name .. "_RE"
            if not seen[key] then seen[key] = 0 end
            seen[key] = seen[key] + 1
            if seen[key] <= 5 then -- max 5 captures per remote
                local args = {...}
                local argStrs = {}
                for i, a in ipairs(args) do
                    if typeof(a) == "Instance" then
                        table.insert(argStrs, string.format("[%d] Instance(%s) %s", i, a.ClassName, a:GetFullName()))
                    elseif typeof(a) == "Vector3" then
                        table.insert(argStrs, string.format("[%d] Vector3(%.1f, %.1f, %.1f)", i, a.X, a.Y, a.Z))
                    elseif typeof(a) == "CFrame" then
                        table.insert(argStrs, string.format("[%d] CFrame(%.1f, %.1f, %.1f)", i, a.Position.X, a.Position.Y, a.Position.Z))
                    elseif typeof(a) == "BrickColor" then
                        table.insert(argStrs, string.format("[%d] BrickColor(%s)", i, tostring(a)))
                    elseif typeof(a) == "Color3" then
                        table.insert(argStrs, string.format("[%d] Color3(%d,%d,%d)", i, math.floor(a.R*255), math.floor(a.G*255), math.floor(a.B*255)))
                    elseif typeof(a) == "table" then
                        table.insert(argStrs, string.format("[%d] Table(%s)", i, game:GetService("HttpService"):JSONEncode(a)))
                    else
                        table.insert(argStrs, string.format("[%d] %s(%s)", i, typeof(a), tostring(a)))
                    end
                end
                p(string.format("\n[RE] %s (#%d)", remote.Name, seen[key]))
                p("  Args: " .. table.concat(argStrs, " | "))
            end
        end)
    elseif remote:IsA("RemoteFunction") then
        -- Hook RemoteFunction via Namecall hook
        pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                if self == remote then
                    local method = getnamecallmethod()
                    if method == "InvokeServer" then
                        local key = remote.Name .. "_RF"
                        if not seen[key] then seen[key] = 0 end
                        seen[key] = seen[key] + 1
                        if seen[key] <= 5 then
                            local args = {...}
                            local argStrs = {}
                            for i, a in ipairs(args) do
                                if typeof(a) == "Instance" then
                                    table.insert(argStrs, string.format("[%d] Instance(%s) %s", i, a.ClassName, a:GetFullName()))
                                elseif typeof(a) == "Vector3" then
                                    table.insert(argStrs, string.format("[%d] Vector3(%.1f, %.1f, %.1f)", i, a.X, a.Y, a.Z))
                                elseif typeof(a) == "table" then
                                    table.insert(argStrs, string.format("[%d] Table(%s)", i, game:GetService("HttpService"):JSONEncode(a)))
                                else
                                    table.insert(argStrs, string.format("[%d] %s(%s)", i, typeof(a), tostring(a)))
                                end
                            end
                            p(string.format("\n[RF] %s (#%d)", remote.Name, seen[key]))
                            p("  Args: " .. table.concat(argStrs, " | "))
                        end
                    end
                end
                return oldNamecall(self, ...)
            end)
        end)
    end
end

p("\n\n⏳ Hooks active! Play the game for 60 seconds...")
p("Do these actions:")
p("  1. Pick up fuel → burn in campfire")
p("  2. Pick up raw food → cook at fire")
p("  3. Chop a tree")
p("  4. Attack an enemy")
p("  5. Craft something")
p("  6. Collect a coin")

-- Auto-save after 60s
task.delay(60, function()
    local content = table.concat(out, "\n")
    writefile("powerhub_remotespy.txt", content)
    print("✅ Remote spy saved! File: powerhub_remotespy.txt")
    print("Lines: " .. #out)
end)
