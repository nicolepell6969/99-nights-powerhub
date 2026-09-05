-- ============================================================
--  Lua sandbox harness to load-test a Roblox (Lua-global) script
--  Uses Lua 5.4 which we have locally. Mocks the minimal Roblox
--  API surface the hub uses. Aim: catch API typos, nil-indexes,
--  bad method names, runtime errors on load + on toggling features.
-- ============================================================
local ok = pcall(require, "luaunit")
-- (no external deps; plain script)

-- ---------- minimal Vector3 ----------
local Vector3 = {}
Vector3.__index = Vector3
local function newV(x, y, z)
    return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3)
end
function Vector3.new(x, y, z) return newV(x, y, z) end
local VZ = newV(0, 0, 0)
function Vector3:Magnitude() return math.sqrt(self.X ^ 2 + self.Y ^ 2 + self.Z ^ 2) end
function Vector3:Unit() local m = self:Magnitude(); return m > 0 and newV(self.X / m, self.Y / m, self.Z / m) or VZ end
function Vector3:__add(o) return newV(self.X + o.X, self.Y + o.Y, self.Z + o.Z) end
function Vector3:__sub(o) return newV(self.X - o.X, self.Y - o.Y, self.Z - o.Z) end
function Vector3:__mul(s) if type(s) == "number" then return newV(self.X * s, self.Y * s, self.Z * s) end end
function Vector3:__eq(o) return self.X == o.X and self.Y == o.Y and self.Z == o.Z end
function Vector3:__tostring() return string.format("(%g, %g, %g)", self.X, self.Y, self.Z) end
local Zero = VZ

-- ---------- minimal CFrame ----------
local CFrame = {}
CFrame.__index = CFrame
function CFrame.metatable() return CFrame end
function newCF(px, py, pz, lx, ly, lz, rx, ry, rz, ux, uy, uz)
    local t = {
        Position = newV(px or 0, py or 0, pz or 0),
        LookVector = newV(lx or 0, ly or 0, lz or -1),
        RightVector = newV(rx or 1, ry or 0, rz or 0),
        UpVector = newV(ux or 0, uy or 1, uz or 0),
    }
    return setmetatable(t, CFrame)
end
CFrame.new = function(a, b, c)
    if type(a) == "table" and a.X then return newCF(a.X, a.Y, a.Z) end -- CFrame.new(Vector3)
    return newCF(a or 0, b or 0, c or 0)
end
-- CFrame.new(pos) where pos is a Vector3: handled above
-- Position + Vector3*: use real table add (Lua has no metatable add on ours) — replicate
function CFrame.__add(self, v)
    return newCF(self.Position.X + v.X, self.Position.Y + v.Y, self.Position.Z + v.Z)
end

-- ---------- Event (<signal>):Connect(cb) ----------
local Event = {}
Event.__index = Event
local function newEvent()
    local e = setmetatable({ _fns = {} }, Event)
    return e
end
function Event:Connect(fn)
    table.insert(self._fns, fn)
    return { Disconnect = function() end }
end
function Event:Fire(...)
    local args = {...}
    for _, fn in ipairs(self._fns) do pcall(fn, unpack(args)) end
end

-- ---------- Enum mock ----------
local Enum = {
    KeyCode = {}, UserInputType = {}, FillDirection = {}, SortOrder = {},
    AutomaticSize = {}, TextXAlignment = {}, ZIndexBehavior = {},
}
Enum.KeyCode.W = "W"; Enum.KeyCode.A = "A"; Enum.KeyCode.S = "S"; Enum.KeyCode.D = "D"
Enum.KeyCode.Space = "Space"; Enum.KeyCode.LeftControl = "LeftControl"
Enum.KeyCode.F = "F"; Enum.KeyCode.K = "K"; Enum.KeyCode.T = "T"; Enum.KeyCode.G = "G"
Enum.KeyCode.E = "E"; Enum.KeyCode.I = "I"; Enum.KeyCode.LeftShift = "LeftShift"
Enum.UserInputType.MouseButton1 = "MouseButton1"
Enum.UserInputType.MouseMovement = "MouseMovement"
Enum.UserInputType.MouseButton1Click = "MouseButton1Click"
Enum.FillDirection.Vertical = "Vertical"; Enum.FillDirection.Horizontal = "Horizontal"
Enum.SortOrder.LayoutOrder = "LayoutOrder"
Enum.AutomaticSize.Y = "Y"
Enum.TextXAlignment.Left = "Left"; Enum.TextXAlignment.Right = "Right"
Enum.ZIndexBehavior.Sibling = "Sibling"

-- ---------- Instance mock ----------
local InstanceM = {}
InstanceM.__index = InstanceM
local classDefaults = {
    ScreenGui = { ResetOnSpawn = true },
}
local function makeInstance(className, name)
    local inst = setmetatable({
        _className = className,
        Name = name or className,
        Children = {}, _evts = {},
        Visible = true,
        Parent = nil,
        Size = nil, Position = nil,
        BackgroundColor3 = Color? and nil or nil,
        BackgroundColor3 = classDefaults[className] and classDefaults[className].BackgroundColor3 or nil,
        BackgroundTransparency = 1,
        Text = "", TextSize = 14, Font = nil,
        TextColor3 = Color? and nil or nil,
        TextColor3 = nil,
        TextXAlignment = nil,
        LayoutOrder = 0,
        ScrollBarThickness = 10, ScrollBarImageColor3 = nil,
        AutomaticCanvasSize = nil,
        CanvasSize = nil,
        CanCollide = true,
        Anchored = true,
        Transparency = 0,
        Health = 100, MaxHealth = 100,
        WalkSpeed = 16, JumpPower = 50,
        AssemblyLinearVelocity = nil,
        Velocity = nil, MaxForce = nil,
        CornerRadius = nil,
        Padding = nil,
        Thickness = nil,
        ParentOf = nil,
    }, InstanceM)

    -- events
    if withEvents[className] then
        for _, e in ipairs(withEvents[className]) do inst[e] = newEvent() end
    end
    return inst
end