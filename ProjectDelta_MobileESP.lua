--[[
    PROJECT DELTA - MOBILE ESP
    Versão sem AIMBOT / SILENT AIM.

    Recursos:
    - GUI mobile minimalista
    - ESP Players e NPCs
    - Nome, distância, caixa, chams e vida
    - Distância máxima 0-5000 studs
    - FOV visual configurável
    - Crosshair configurável
    - Persistência local quando suportada pelo ambiente
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local CONFIG_FILE = "ProjectDelta_MobileESP.json"

local DefaultConfig = {
    MasterEnabled = true,
    PlayersEnabled = true,
    NPCsEnabled = false,
    PlayerName = true,
    PlayerDistance = true,
    PlayerBox = true,
    PlayerChams = false,
    PlayerHealth = true,
    NPCName = true,
    NPCDistance = true,
    NPCBox = true,
    NPCChams = false,
    NPCHealth = true,
    TeamCheck = true,
    MaxDistance = 1000,
    FOVEnabled = true,
    FOVVisibleWhenDisabled = true,
    FOVRadius = 150,
    FOVThickness = 2,
    CrosshairEnabled = true,
    CrosshairGap = 6,
    CrosshairLength = 8,
    CrosshairThickness = 2,
    Color = {R = 255, G = 255, B = 255}
}

local Config = {}
for k, v in pairs(DefaultConfig) do
    if type(v) == "table" then
        Config[k] = {}
        for a, b in pairs(v) do Config[k][a] = b end
    else
        Config[k] = v
    end
end

local FileAPIAvailable =
    type(isfile) == "function" and
    type(readfile) == "function" and
    type(writefile) == "function"

local function SaveConfig()
    if not FileAPIAvailable then return end
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(Config)
    end)
    if ok then pcall(function() writefile(CONFIG_FILE, encoded) end) end
end

local function LoadConfig()
    if not FileAPIAvailable or not isfile(CONFIG_FILE) then return end

    local ok, content = pcall(readfile, CONFIG_FILE)
    if not ok or not content then return end

    local decodedOk, decoded = pcall(function()
        return HttpService:JSONDecode(content)
    end)

    if not decodedOk or type(decoded) ~= "table" then return end

    for k, v in pairs(decoded) do
        if type(v) == "table" and type(Config[k]) == "table" then
            for a, b in pairs(v) do Config[k][a] = b end
        else
            Config[k] = v
        end
    end
end

LoadConfig()

local function GetESPColor()
    return Color3.fromRGB(Config.Color.R, Config.Color.G, Config.Color.B)
end

local function GetCharacterRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character.PrimaryPart
end

local function GetHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function GetDistance(character)
    local root = GetCharacterRoot(character)
    local localRoot = GetCharacterRoot(LocalPlayer.Character)
    if not root or not localRoot then return math.huge end
    return (root.Position - localRoot.Position).Magnitude
end

local function IsEnemy(player)
    if not Config.TeamCheck then return true end
    if not player then return false end
    if not LocalPlayer.Team or not player.Team then return true end
    return LocalPlayer.Team ~= player.Team
end

local PlayerESP = {}
local NPCESP = {}

local function GetGuiParent()
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then return result end
    end
    return CoreGui
end

local Parent = GetGuiParent()
local Existing = Parent:FindFirstChild("ProjectDeltaMobileESP")
if Existing then Existing:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ProjectDeltaMobileESP"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = Parent

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(245, 390)
Main.Position = UDim2.new(0, 15, 0.5, -195)
Main.BackgroundColor3 = Color3.new(0, 0, 0)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 5)
MainCorner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(45, 45, 45)
Stroke.Thickness = 1
Stroke.Parent = Main

local Dragging, DragStart, StartPosition

Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true
        DragStart = input.Position
        StartPosition = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if Dragging and (
        input.UserInputType == Enum.UserInputType.Touch or
        input.UserInputType == Enum.UserInputType.MouseMovement
    ) then
        local delta = input.Position - DragStart
        Main.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + delta.Y
        )
    end
end)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -10, 1, -10)
Scroll.Position = UDim2.fromOffset(5, 5)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.new(1, 1, 1)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.Parent = Scroll

local Padding = Instance.new("UIPadding")
Padding.PaddingTop = UDim.new(0, 5)
Padding.PaddingBottom = UDim.new(0, 10)
Padding.Parent = Scroll

local function CreateButton(text)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 38)
    button.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 14
    button.Font = Enum.Font.Gotham
    button.Text = text
    button.AutoButtonColor = false
    button.Parent = Scroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button

    return button
end

local function SetButtonState(button, text, enabled)
    button.Text = text .. (enabled and "  [ON]" or "  [OFF]")
    button.BackgroundColor3 = enabled
        and Color3.fromRGB(35, 35, 35)
        or Color3.fromRGB(10, 10, 10)
end

local function CreateSlider(name, min, max, initial, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -10, 0, 58)
    holder.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    holder.BorderSizePixel = 0
    holder.Parent = Scroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = holder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -15, 0, 23)
    label.Position = UDim2.fromOffset(8, 2)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 5)
    bar.Position = UDim2.fromOffset(10, 40)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bar.BorderSizePixel = 0
    bar.Parent = holder

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.new(1, 1, 1)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local touching = false

    local function update(x)
        local alpha = math.clamp(
            (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
            0, 1
        )
        local value = math.floor(min + (max - min) * alpha)
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        label.Text = name .. ": " .. tostring(value)
        callback(value)
        SaveConfig()
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            touching = true
            update(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if touching and (
            input.UserInputType == Enum.UserInputType.Touch or
            input.UserInputType == Enum.UserInputType.MouseMovement
        ) then
            update(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            touching = false
        end
    end)

    fill.Size = UDim2.new(
        (initial - min) / (max - min), 0, 1, 0
    )
    label.Text = name .. ": " .. tostring(initial)

    return holder
end

local function AddToggle(label, key)
    local button = CreateButton(label)
    SetButtonState(button, label, Config[key])

    button.Activated:Connect(function()
        Config[key] = not Config[key]
        SetButtonState(button, label, Config[key])
        SaveConfig()
    end)

    return button
end

AddToggle("ESP", "MasterEnabled")
AddToggle("Players", "PlayersEnabled")
AddToggle("Nome", "PlayerName")
AddToggle("Distância", "PlayerDistance")
AddToggle("Caixa", "PlayerBox")
AddToggle("Chams", "PlayerChams")
AddToggle("Vida", "PlayerHealth")

AddToggle("NPCs", "NPCsEnabled")
AddToggle("NPC Nome", "NPCName")
AddToggle("NPC Distância", "NPCDistance")
AddToggle("NPC Caixa", "NPCBox")
AddToggle("NPC Chams", "NPCChams")
AddToggle("NPC Vida", "NPCHealth")

AddToggle("Team Check", "TeamCheck")

CreateSlider(
    "Distância máxima", 0, 5000, Config.MaxDistance,
    function(value) Config.MaxDistance = value end
)

AddToggle("FOV", "FOVEnabled")
AddToggle("Linha do FOV", "FOVVisibleWhenDisabled")

CreateSlider(
    "FOV", 20, 500, Config.FOVRadius,
    function(value) Config.FOVRadius = value end
)

CreateSlider(
    "Grossura FOV", 1, 8, Config.FOVThickness,
    function(value) Config.FOVThickness = value end
)

AddToggle("Mira", "CrosshairEnabled")

CreateSlider(
    "Distância da mira", 0, 50, Config.CrosshairGap,
    function(value) Config.CrosshairGap = value end
)

CreateSlider(
    "Tamanho da mira", 2, 30, Config.CrosshairLength,
    function(value) Config.CrosshairLength = value end
)

CreateSlider(
    "Grossura da mira", 1, 8, Config.CrosshairThickness,
    function(value) Config.CrosshairThickness = value end
)

local FOVCircle = Instance.new("Frame")
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.fromScale(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Parent = ScreenGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Parent = FOVCircle

local Crosshair = Instance.new("Frame")
Crosshair.Size = UDim2.fromOffset(1, 1)
Crosshair.Position = UDim2.fromScale(0.5, 0.5)
Crosshair.BackgroundTransparency = 1
Crosshair.BorderSizePixel = 0
Crosshair.Parent = ScreenGui

local CrossParts = {}
for i = 1, 4 do
    local part = Instance.new("Frame")
    part.BorderSizePixel = 0
    part.BackgroundColor3 = GetESPColor()
    part.AnchorPoint = Vector2.new(0.5, 0.5)
    part.Parent = Crosshair
    CrossParts[i] = part
end

local function DestroyESP(container, character)
    local data = container[character]
    if not data then return end

    for _, object in pairs(data) do
        if typeof(object) == "Instance" then
            pcall(function() object:Destroy() end)
        end
    end

    container[character] = nil
end

local function CreateESP(character, isPlayer)
    if not character or (isPlayer and PlayerESP[character]) or
        (not isPlayer and NPCESP[character]) then return end

    local humanoid = GetHumanoid(character)
    local root = GetCharacterRoot(character)
    if not humanoid or not root then return end

    local data = {}

    local highlight = Instance.new("Highlight")
    highlight.Name = "DeltaChams"
    highlight.Adornee = character
    highlight.FillColor = GetESPColor()
    highlight.OutlineColor = GetESPColor()
    highlight.FillTransparency = 0.65
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    data.Highlight = highlight

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "DeltaBox"
    box.Adornee = root
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Color3 = GetESPColor()
    box.Transparency = 0
    box.Size = Vector3.new(4, 6, 2)
    box.Parent = root
    data.Box = box

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DeltaInfo"
    billboard.Adornee = root
    billboard.Size = UDim2.fromOffset(170, 70)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 5000
    billboard.Parent = ScreenGui
    data.Billboard = billboard

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 22)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = GetESPColor()
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.Text = character.Name
    nameLabel.Parent = billboard
    data.NameLabel = nameLabel

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Position = UDim2.fromOffset(0, 22)
    distanceLabel.Size = UDim2.new(1, 0, 0, 20)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.TextSize = 12
    distanceLabel.Parent = billboard
    data.DistanceLabel = distanceLabel

    local healthLabel = Instance.new("TextLabel")
    healthLabel.Position = UDim2.fromOffset(0, 42)
    healthLabel.Size = UDim2.new(1, 0, 0, 20)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextStrokeTransparency = 0
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextSize = 12
    healthLabel.Parent = billboard
    data.HealthLabel = healthLabel

    if isPlayer then
        PlayerESP[character] = data
    else
        NPCESP[character] = data
    end
end

local function IsNPC(model)
    if not model:IsA("Model") then return false end
    if not model:FindFirstChildOfClass("Humanoid") then return false end
    return Players:GetPlayerFromCharacter(model) == nil
end

local function UpdateESP(character, data, isPlayer)
    if not character or not character.Parent or not data then return end

    local humanoid = GetHumanoid(character)
    local root = GetCharacterRoot(character)

    if not humanoid or not root then
        DestroyESP(isPlayer and PlayerESP or NPCESP, character)
        return
    end

    local distance = GetDistance(character)
    local visible = Config.MasterEnabled and distance <= Config.MaxDistance

    if isPlayer then
        local player = Players:GetPlayerFromCharacter(character)
        visible = visible and player ~= nil and player ~= LocalPlayer
            and IsEnemy(player) and Config.PlayersEnabled
    else
        visible = visible and Config.NPCsEnabled
    end

    data.Billboard.Enabled = visible
    data.Box.Visible = visible and (
        (isPlayer and Config.PlayerBox) or
        (not isPlayer and Config.NPCBox)
    )
    data.Highlight.Enabled = visible and (
        (isPlayer and Config.PlayerChams) or
        (not isPlayer and Config.NPCChams)
    )

    if not visible then return end

    local color = GetESPColor()
    data.NameLabel.TextColor3 = color
    data.Box.Color3 = color
    data.Highlight.FillColor = color
    data.Highlight.OutlineColor = color

    local showName = isPlayer and Config.PlayerName or
        (not isPlayer and Config.NPCName)
    data.NameLabel.Visible = showName
    if showName then data.NameLabel.Text = character.Name end

    local showDistance = isPlayer and Config.PlayerDistance or
        (not isPlayer and Config.NPCDistance)
    data.DistanceLabel.Visible = showDistance
    if showDistance then
        data.DistanceLabel.Text = string.format("%.0f studs", distance)
    end

    local showHealth = isPlayer and Config.PlayerHealth or
        (not isPlayer and Config.NPCHealth)
    data.HealthLabel.Visible = showHealth

    if showHealth then
        local health = math.max(0, humanoid.Health)
        local maxHealth = math.max(1, humanoid.MaxHealth)
        data.HealthLabel.Text =
            string.format("HP: %.0f / %.0f", health, maxHealth)

        local ratio = math.clamp(health / maxHealth, 0, 1)
        data.HealthLabel.TextColor3 =
            Color3.fromHSV(ratio * 0.33, 1, 1)
    end
end

local function RegisterPlayer(player)
    if player == LocalPlayer then return end

    local function characterAdded(character)
        task.wait(0.5)
        CreateESP(character, true)
    end

    player.CharacterAdded:Connect(characterAdded)

    if player.Character then
        task.spawn(characterAdded, player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    RegisterPlayer(player)
end

Players.PlayerAdded:Connect(RegisterPlayer)

Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        DestroyESP(PlayerESP, player.Character)
    end
end)

local function TryRegisterNPC(instance)
    if IsNPC(instance) and not NPCESP[instance] then
        CreateESP(instance, false)
    end
end

for _, instance in ipairs(workspace:GetDescendants()) do
    if instance:IsA("Model") then
        task.spawn(TryRegisterNPC, instance)
    end
end

workspace.DescendantAdded:Connect(function(instance)
    if instance:IsA("Model") then
        task.wait(0.1)
        TryRegisterNPC(instance)
    end
end)

workspace.DescendantRemoving:Connect(function(instance)
    if PlayerESP[instance] then
        DestroyESP(PlayerESP, instance)
    end
    if NPCESP[instance] then
        DestroyESP(NPCESP, instance)
    end
end)

local UpdateAccumulator = 0

RunService.RenderStepped:Connect(function(delta)
    local camera = workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize
    local color = GetESPColor()

    FOVCircle.Size = UDim2.fromOffset(
        Config.FOVRadius * 2,
        Config.FOVRadius * 2
    )
    FOVStroke.Thickness = Config.FOVThickness
    FOVStroke.Color = color
    FOVCircle.Visible =
        Config.FOVVisibleWhenDisabled or Config.FOVEnabled

    local gap = Config.CrosshairGap
    local length = Config.CrosshairLength
    local thickness = Config.CrosshairThickness
    local centerX = viewport.X / 2
    local centerY = viewport.Y / 2

    CrossParts[1].Size = UDim2.fromOffset(length, thickness)
    CrossParts[1].Position =
        UDim2.fromOffset(centerX - gap - length / 2, centerY)

    CrossParts[2].Size = UDim2.fromOffset(length, thickness)
    CrossParts[2].Position =
        UDim2.fromOffset(centerX + gap + length / 2, centerY)

    CrossParts[3].Size = UDim2.fromOffset(thickness, length)
    CrossParts[3].Position =
        UDim2.fromOffset(centerX, centerY - gap - length / 2)

    CrossParts[4].Size = UDim2.fromOffset(thickness, length)
    CrossParts[4].Position =
        UDim2.fromOffset(centerX, centerY + gap + length / 2)

    for _, part in ipairs(CrossParts) do
        part.BackgroundColor3 = color
        part.Visible = Config.CrosshairEnabled
    end

    UpdateAccumulator += delta
    if UpdateAccumulator < 0.08 then return end
    UpdateAccumulator = 0

    for character, data in pairs(PlayerESP) do
        UpdateESP(character, data, true)
    end

    for character, data in pairs(NPCESP) do
        UpdateESP(character, data, false)
    end
end)

local function AdaptForScreen()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize

    if viewport.X < 500 then
        Main.Size = UDim2.new(
            0,
            math.max(200, math.min(225, viewport.X - 25)),
            0,
            370
        )
    else
        Main.Size = UDim2.fromOffset(245, 390)
    end
end

AdaptForScreen()

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal(
        "ViewportSize"
    ):Connect(AdaptForScreen)
end

SaveConfig()
