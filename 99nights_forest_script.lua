-- ===================================
-- 99 NIGHTS IN THE FOREST - XENO OPTIMIZED
-- ===================================
-- Script Otimizado para Xeno Executor
-- ===================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetWorkspace()

local player = Players.LocalPlayer
if not player then return end

local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- ===== CONFIGURAÇÕES =====
local config = {
    flySpeed = 50,
    sprintSpeed = 100,
    killAuraRange = 50,
    autoFarmRange = 100,
    espEnabled = false,
    godmodeEnabled = false,
    invisibilityEnabled = false
}

-- ===== VARIÁVEIS GLOBAIS =====
local isFlying = false
local flyConnection = nil
local killAuraActive = false
local autoFarmActive = false
local speedActive = false
local espObjects = {}
local espObjectCharConns = {}
local panelMinimized = false
local guiReady = false
local scriptClosed = false
local espConnections = {}

-- ===== CORES DO TEMA =====
local theme = {
    primary = Color3.fromRGB(0, 0, 0),           -- Preto
    accent = Color3.fromRGB(0, 255, 0),         -- Verde
    accentDark = Color3.fromRGB(0, 200, 0),     -- Verde Escuro
    text = Color3.fromRGB(255, 255, 255),       -- Branco
    background = Color3.fromRGB(15, 15, 15),    -- Preto com tom cinzento
    hover = Color3.fromRGB(0, 150, 0)           -- Verde Escuro para Hover
}

print("🔧 Inicializando 99 Nights Script para Xeno...")

-- ===== FUNÇÃO: CRIAR GUI AVANÇADO =====
local function createAdvancedGui()
    print("📦 Criando interface gráfica...")
    
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "99NightsGui_Xeno"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- Main Panel
    local mainPanel = Instance.new("Frame")
    mainPanel.Name = "MainPanel"
    mainPanel.Size = UDim2.new(0, 380, 0, 650)
    mainPanel.Position = UDim2.new(0, 20, 0, 20)
    mainPanel.BackgroundColor3 = theme.primary
    mainPanel.BorderColor3 = theme.accent
    mainPanel.BorderSizePixel = 3
    mainPanel.Parent = screenGui

    -- Adicionar cantos arredondados
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 10)
    panelCorner.Parent = mainPanel

    -- Header Panel
    local headerPanel = Instance.new("Frame")
    headerPanel.Name = "Header"
    headerPanel.Size = UDim2.new(1, 0, 0, 60)
    headerPanel.BackgroundColor3 = theme.accent
    headerPanel.BorderSizePixel = 0
    headerPanel.Parent = mainPanel

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = headerPanel

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0.65, 0, 1, 0)
    titleLabel.Position = UDim2.new(0.05, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = theme.primary
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "99 NIGHTS"
    titleLabel.Parent = headerPanel

    -- Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.Size = UDim2.new(0, 45, 1, 0)
    minimizeBtn.Position = UDim2.new(0.60, 0, 0, 0)
    minimizeBtn.BackgroundColor3 = theme.accent
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.TextColor3 = theme.primary
    minimizeBtn.TextSize = 18
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Text = "−"
    minimizeBtn.Parent = headerPanel

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 45, 1, 0)
    closeBtn.Position = UDim2.new(0.88, 0, 0, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    closeBtn.BorderSizePixel = 0
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "X"
    closeBtn.Parent = headerPanel

    -- Hover effects para botões
    minimizeBtn.MouseEnter:Connect(function()
        minimizeBtn.BackgroundColor3 = theme.hover
    end)
    minimizeBtn.MouseLeave:Connect(function()
        minimizeBtn.BackgroundColor3 = theme.accent
    end)

    closeBtn.MouseEnter:Connect(function()
        closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    end)
    closeBtn.MouseLeave:Connect(function()
        closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end)

    -- Content Panel
    local contentPanel = Instance.new("Frame")
    contentPanel.Name = "Content"
    contentPanel.Size = UDim2.new(1, 0, 1, -60)
    contentPanel.Position = UDim2.new(0, 0, 0, 60)
    contentPanel.BackgroundColor3 = theme.background
    contentPanel.BorderSizePixel = 0
    contentPanel.Parent = mainPanel

    -- ScrollingFrame para múltiplas opções
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Name = "ScrollFrame"
    scrollingFrame.Size = UDim2.new(1, -15, 1, -15)
    scrollingFrame.Position = UDim2.new(0, 7, 0, 7)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.BorderSizePixel = 0
    scrollingFrame.ScrollBarThickness = 10
    scrollingFrame.ScrollBarImageColor3 = theme.accent
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.Parent = contentPanel

    -- UIListLayout para organizar botões
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Padding = UDim.new(0, 12)
    uiListLayout.FillDirection = Enum.FillDirection.Vertical
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Parent = scrollingFrame

    -- Função para criar botão de toggle
    local buttonStates = {}
    
    local function createToggleButton(name, text, defaultState, index)
        local buttonContainer = Instance.new("Frame")
        buttonContainer.Name = name .. "Container"
        buttonContainer.Size = UDim2.new(1, 0, 0, 55)
        buttonContainer.BackgroundColor3 = theme.primary
        buttonContainer.BorderColor3 = theme.accent
        buttonContainer.BorderSizePixel = 2
        buttonContainer.Parent = scrollingFrame
        buttonContainer.LayoutOrder = index

        local button = Instance.new("TextButton")
        button.Name = name .. "Button"
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundColor3 = defaultState and theme.accent or theme.primary
        button.BorderSizePixel = 0
        button.TextColor3 = defaultState and theme.primary or theme.text
        button.TextSize = 16
        button.Font = Enum.Font.GothamBold
        button.Text = text .. " [" .. (defaultState and "ON" or "OFF") .. "]"
        button.Parent = buttonContainer

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button

        local state = defaultState
        buttonStates[name] = state
        
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = state and theme.hover or theme.accentDark
        end)
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = state and theme.accent or theme.primary
        end)

        button.MouseButton1Click:Connect(function()
            state = not state
            buttonStates[name] = state
            button.BackgroundColor3 = state and theme.accent or theme.primary
            button.TextColor3 = state and theme.primary or theme.text
            button.Text = text .. " [" .. (state and "ON" or "OFF") .. "]"
        end)

        return button
    end

    -- Criar botões
    createToggleButton("Fly", "🚀 FLY", false, 1)
    createToggleButton("KillAura", "⚔️ KILL AURA", false, 2)
    createToggleButton("AutoFarm", "🌾 AUTO FARM", false, 3)
    createToggleButton("Sprint", "💨 SPRINT", false, 4)
    createToggleButton("GodMode", "🛡️ GODMODE", false, 5)
    createToggleButton("ESP", "👁️ ESP", false, 6)
    createToggleButton("Invisibility", "👻 INVISÍVEL", false, 7)

    -- Update scrolling frame canvas size
    local function updateCanvasSize()
        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, uiListLayout.AbsoluteContentSize.Y + 20)
    end
    
    uiListLayout.Changed:Connect(updateCanvasSize)
    updateCanvasSize()

    -- Minimized Pill Button
    local pillButton = Instance.new("TextButton")
    pillButton.Name = "PillButton"
    pillButton.Size = UDim2.new(0, 70, 0, 70)
    pillButton.Position = UDim2.new(0, 30, 0.5, -35)
    pillButton.BackgroundColor3 = theme.primary
    pillButton.BorderColor3 = theme.accent
    pillButton.BorderSizePixel = 3
    pillButton.TextColor3 = theme.accent
    pillButton.TextSize = 28
    pillButton.Font = Enum.Font.GothamBold
    pillButton.Text = "J"
    pillButton.Visible = false
    pillButton.Parent = screenGui

    -- Tornar o botão redondo
    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(1, 0)
    pillCorner.Parent = pillButton

    pillButton.MouseEnter:Connect(function()
        pillButton.BorderColor3 = theme.hover
    end)
    pillButton.MouseLeave:Connect(function()
        pillButton.BorderColor3 = theme.accent
    end)

    -- Funções de minimizar/maximizar
    minimizeBtn.MouseButton1Click:Connect(function()
        panelMinimized = not panelMinimized
        mainPanel.Visible = not panelMinimized
        pillButton.Visible = panelMinimized
    end)

    pillButton.MouseButton1Click:Connect(function()
        panelMinimized = false
        mainPanel.Visible = true
        pillButton.Visible = false
    end)

    -- Fechar script
    closeBtn.MouseButton1Click:Connect(function()
        scriptClosed = true
        print("❌ Script desativado!")
        toggleFly(false)
        toggleKillAura(false)
        toggleAutoFarm(false)
        toggleSprint(false)
        toggleGodMode(false)
        toggleESP(false)
        toggleInvisibility(false)
        screenGui:Destroy()
    end)

    print("✅ Interface gráfica criada com sucesso!")
    
    return buttonStates
end

-- ===== FUNÇÃO: FLY =====
local function toggleFly(enabled)
    isFlying = enabled
    
    if isFlying then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Parent = humanoidRootPart
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Name = "FlyVelocity"
        
        if flyConnection then flyConnection:Disconnect() end
        
        flyConnection = RunService.RenderStepped:Connect(function()
            if not isFlying or not character or not humanoidRootPart or not bodyVelocity.Parent then
                if flyConnection then flyConnection:Disconnect() end
                if bodyVelocity and bodyVelocity.Parent then bodyVelocity:Destroy() end
                return
            end
            
            local camera = workspace.CurrentCamera
            local moveDirection = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0)
            end
            
            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit
            end
            
            bodyVelocity.Velocity = moveDirection * config.flySpeed
        end)
        print("✅ FLY ativado!")
    else
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        local bodyVelocity = humanoidRootPart:FindFirstChild("FlyVelocity")
        if bodyVelocity then bodyVelocity:Destroy() end
        print("❌ FLY desativado!")
    end
end

-- ===== FUNÇÃO: KILL AURA =====
local function toggleKillAura(enabled)
    killAuraActive = enabled
    
    if killAuraActive then
        local killConnection
        killConnection = RunService.Heartbeat:Connect(function()
            if not killAuraActive or not character or not humanoidRootPart then
                if killConnection then killConnection:Disconnect() end
                return
            end
            
            for _, target in pairs(Players:GetPlayers()) do
                if target ~= player and target.Character then
                    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                    local targetHumanoid = target.Character:FindFirstChild("Humanoid")
                    
                    if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                        local distance = (humanoidRootPart.Position - targetRoot.Position).Magnitude
                        
                        if distance <= config.killAuraRange then
                            targetHumanoid:TakeDamage(15)
                        end
                    end
                end
            end
        end)
        print("✅ KILL AURA ativado!")
    else
        print("❌ KILL AURA desativado!")
    end
end

-- ===== FUNÇÃO: AUTO FARM =====
local function toggleAutoFarm(enabled)
    autoFarmActive = enabled
    
    if autoFarmActive then
        local farmConnection
        farmConnection = RunService.Heartbeat:Connect(function()
            if not autoFarmActive or not character or not humanoidRootPart then
                if farmConnection then farmConnection:Disconnect() end
                return
            end
            
            local hrpPos = humanoidRootPart.Position
            local best, bestDist = nil, config.autoFarmRange
            
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Anchored == false then
                    local model = obj:FindFirstAncestorOfClass("Model")
                    if model and model ~= character and model:FindFirstChild("Humanoid") then
                        local dist = (hrpPos - obj.Position).Magnitude
                        if dist < bestDist then
                            -- flag the model's HRP if it has one, else the part itself
                            best = model:FindFirstChild("HumanoidRootPart") or obj
                            bestDist = dist
                        end
                    end
                end
            end
            
            if best then
                humanoidRootPart.CFrame = CFrame.new(best.Position + Vector3.new(0, 3, 0))
                humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end)
        print("✅ AUTO FARM ativado!")
    else
        print("❌ AUTO FARM desativado!")
    end
end

-- ===== FUNÇÃO: SPRINT =====
local function toggleSprint(enabled)
    speedActive = enabled
    
    if speedActive then
        humanoid.WalkSpeed = config.sprintSpeed
        print("✅ SPRINT ativado!")
    else
        humanoid.WalkSpeed = 16
        print("❌ SPRINT desativado!")
    end
end

-- ===== FUNÇÃO: GODMODE =====
local function toggleGodMode(enabled)
    config.godmodeEnabled = enabled
    
    if config.godmodeEnabled then
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
        print("✅ GODMODE ativado!")
    else
        print("❌ GODMODE desativado!")
    end
end

-- ===== FUNÇÃO: ESP =====
local function toggleESP(enabled)
    config.espEnabled = enabled
    
    if config.espEnabled then
        local function addESP(target)
            if target == player or not target.Character then return end
            if espObjects[target] then return end
            local humanoidRootPart_target = target.Character:WaitForChild("HumanoidRootPart", 5)
            if not humanoidRootPart_target then return end
            
            local billboard = Instance.new("BillboardGui")
            billboard.Size = UDim2.new(0, 120, 0, 50)
            billboard.MaxDistance = 500
            billboard.Parent = humanoidRootPart_target
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 0.2
            textLabel.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            textLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
            textLabel.Text = target.Name
            textLabel.Font = Enum.Font.GothamBold
            textLabel.TextSize = 14
            textLabel.Parent = billboard
            
            espObjects[target] = billboard
        end
        
        for _, target in pairs(Players:GetPlayers()) do
            addESP(target)
        end
        
        espConnections[#espConnections + 1] = Players.PlayerAdded:Connect(addESP)
        espConnections[#espConnections + 1] = Players.PlayerAdded:Connect(function(target)
            local charConn
            charConn = target.CharacterAdded:Connect(function()
                espObjects[target] = nil
                addESP(target)
            end)
            espObjectCharConns[target] = charConn
        end)
        print("✅ ESP ativado!")
    else
        for _, billboard in pairs(espObjects) do
            if billboard and billboard.Parent then
                billboard:Destroy()
            end
        end
        espObjects = {}
        for _, conn in pairs(espConnections) do
            if conn then conn:Disconnect() end
        end
        espConnections = {}
        for _, conn in pairs(espObjectCharConns) do
            if conn then conn:Disconnect() end
        end
        espObjectCharConns = {}
        print("❌ ESP desativado!")
    end
end

-- ===== FUNÇÃO: INVISIBILIDADE =====
local function toggleInvisibility(enabled)
    config.invisibilityEnabled = enabled
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if config.invisibilityEnabled then
                part.Transparency = 1
            else
                part.Transparency = 0
            end
        end
    end
    
    if config.invisibilityEnabled then
        print("✅ INVISIBILIDADE ativado!")
    else
        print("❌ INVISIBILIDADE desativado!")
    end
end

-- ===== CRIAR GUI E INICIAR =====
local buttonStates = createAdvancedGui()
guiReady = true

-- ===== MONITORAR MUDANÇAS NO GUI =====
RunService.Heartbeat:Connect(function()
    if not guiReady or scriptClosed then return end
    
    if buttonStates.Fly and not isFlying then
        toggleFly(true)
    elseif not buttonStates.Fly and isFlying then
        toggleFly(false)
    end
    
    if buttonStates.KillAura and not killAuraActive then
        toggleKillAura(true)
    elseif not buttonStates.KillAura and killAuraActive then
        toggleKillAura(false)
    end
    
    if buttonStates.AutoFarm and not autoFarmActive then
        toggleAutoFarm(true)
    elseif not buttonStates.AutoFarm and autoFarmActive then
        toggleAutoFarm(false)
    end
    
    if buttonStates.Sprint and not speedActive then
        toggleSprint(true)
    elseif not buttonStates.Sprint and speedActive then
        toggleSprint(false)
    end
    
    if buttonStates.GodMode and not config.godmodeEnabled then
        toggleGodMode(true)
    elseif not buttonStates.GodMode and config.godmodeEnabled then
        toggleGodMode(false)
    end
    
    if buttonStates.ESP and not config.espEnabled then
        toggleESP(true)
    elseif not buttonStates.ESP and config.espEnabled then
        toggleESP(false)
    end
    
    if buttonStates.Invisibility and not config.invisibilityEnabled then
        toggleInvisibility(true)
    elseif not buttonStates.Invisibility and config.invisibilityEnabled then
        toggleInvisibility(false)
    end
end)

-- ===== INPUT BINDINGS =====
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        buttonStates.Fly = not buttonStates.Fly
    elseif input.KeyCode == Enum.KeyCode.K then
        buttonStates.KillAura = not buttonStates.KillAura
    elseif input.KeyCode == Enum.KeyCode.T then
        buttonStates.AutoFarm = not buttonStates.AutoFarm
    elseif input.KeyCode == Enum.KeyCode.G then
        buttonStates.GodMode = not buttonStates.GodMode
    elseif input.KeyCode == Enum.KeyCode.E then
        buttonStates.ESP = not buttonStates.ESP
    elseif input.KeyCode == Enum.KeyCode.I then
        buttonStates.Invisibility = not buttonStates.Invisibility
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        buttonStates.Sprint = not buttonStates.Sprint
    end
end)

-- ===== LIMPEZA AO MORRER =====
humanoid.Died:Connect(function()
    isFlying = false
    killAuraActive = false
    autoFarmActive = false
    speedActive = false
    if flyConnection then flyConnection:Disconnect() end
    print("💀 Você morreu! Script ainda ativo.")
end)

-- ===== LIMPEZA AO RECARREGAR CHARACTER =====
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    print("✅ Character recarregado!")
end)

print("\n" .. string.rep("=", 50))
print("✅ 99 NIGHTS SCRIPT CARREGADO COM SUCESSO NO XENO!")
print("=" .. string.rep("=", 49))
print("\n📋 CONTROLES:")
print("  F - FLY (Voar)")
print("  K - KILL AURA (Aura de Morte)")
print("  T - AUTO FARM (Farmar Automático)")
print("  G - GODMODE (Modo Deus)")
print("  E - ESP (Ver Inimigos)")
print("  I - INVISIBILIDADE (Ficar Invisível)")
print("  SHIFT - SPRINT (Correr Rápido)")
print("\n💚 Use o painel na tela para controlar todas as funções!")
print("📌 Clique no botão (−) para minimizar o painel em uma bolinha 'J'")
print("❌ Clique no botão (X) para fechar o script")
print(string.rep("=", 50) .. "\n")
