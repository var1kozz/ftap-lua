--// FTAP MOD MENU
--// ESP + AIM
--// AIM KEY: Q

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CLEAN OLD VERSION
--==================================================

pcall(function()
    local old = CoreGui:FindFirstChild("FTAP_ModMenu")
    if old then
        old:Destroy()
    end
end)

pcall(function()
    local old = LocalPlayer.PlayerGui:FindFirstChild("FTAP_ModMenu")
    if old then
        old:Destroy()
    end
end)

--==================================================
-- SETTINGS
--==================================================

local ESP_ENABLED = false
local BOTS_ENABLED = false

local AIM_ENABLED = false

local AIM_FOV = 150
local AIM_MAX_DISTANCE = 500
local AIM_SMOOTHNESS = 8

local AIM_TARGET_PART = "Head"

local AIM_VISIBLE_CHECK = true
local AIM_TEAM_CHECK = false
local AIM_SELECTED_ONLY = false

local AIM_HOLD_MODE = true

-- AIM = Q
local AIM_KEY = Enum.KeyCode.Q

local aimHolding = false
local aimToggled = false

local waitingForKey = false

local selectedPlayers = {}
local activeESP = {}

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        selectedPlayers[player.UserId] = false
    end
end

--==================================================
-- COLORS
--==================================================

local PLAYER_COLOR = Color3.fromRGB(0, 255, 120)
local BOT_COLOR = Color3.fromRGB(255, 170, 0)
local AIM_COLOR = Color3.fromRGB(0, 200, 255)

--==================================================
-- HELPERS
--==================================================

local function getCharacter(player)
    return player and player.Character
end

local function getHumanoid(character)
    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end

local function isAlive(character)
    local humanoid = getHumanoid(character)

    return humanoid
        and humanoid.Health > 0
end

local function getRoot(character)
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
end

local function getTargetPart(character)
    if not character then
        return nil
    end

    if AIM_TARGET_PART == "Head" then
        return character:FindFirstChild("Head")
            or character:FindFirstChild("HumanoidRootPart")
    end

    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
end

--==================================================
-- REMOVE ESP
--==================================================

local function removeESP(character)
    if not character then
        return
    end

    local data = activeESP[character]

    if data then
        if data.highlight then
            pcall(function()
                data.highlight:Destroy()
            end)
        end

        if data.billboard then
            pcall(function()
                data.billboard:Destroy()
            end)
        end

        activeESP[character] = nil
    end

    local oldHighlight = character:FindFirstChild("FTAP_ESP_Highlight")

    if oldHighlight then
        oldHighlight:Destroy()
    end

    local oldName = character:FindFirstChild("FTAP_ESP_Name")

    if oldName then
        oldName:Destroy()
    end
end

--==================================================
-- CREATE ESP
--==================================================

local function createESP(character, displayName, kind)
    if not character then
        return
    end

    removeESP(character)

    local color = PLAYER_COLOR

    if kind == "BOT" then
        color = BOT_COLOR
    end

    local highlight = Instance.new("Highlight")

    highlight.Name = "FTAP_ESP_Highlight"
    highlight.Adornee = character
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.65
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    local billboard = Instance.new("BillboardGui")

    billboard.Name = "FTAP_ESP_Name"
    billboard.Adornee = getRoot(character)
    billboard.Size = UDim2.new(0, 220, 0, 70)
    billboard.StudsOffset = Vector3.new(0, 3.2, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 10000
    billboard.Parent = character

    local text = Instance.new("TextLabel")

    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, 0, 1, 0)
    text.Text = displayName
    text.TextColor3 = color
    text.TextStrokeTransparency = 0
    text.TextSize = 14
    text.Font = Enum.Font.GothamBold
    text.Parent = billboard

    activeESP[character] = {
        displayName = displayName,
        kind = kind,
        highlight = highlight,
        billboard = billboard,
        text = text
    }
end

--==================================================
-- PLAYER ESP
--==================================================

local function updatePlayerESP(player)
    if not player or player == LocalPlayer then
        return
    end

    local character = player.Character

    if not character then
        return
    end

    removeESP(character)

    if not ESP_ENABLED then
        return
    end

    if not selectedPlayers[player.UserId] then
        return
    end

    createESP(
        character,
        player.DisplayName .. "  [" .. player.Name .. "]",
        "PLAYER"
    )
end

--==================================================
-- BOT DETECTION
--==================================================

local function isPlayerCharacter(character)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == character then
            return true
        end
    end

    return false
end

local function scanBots()
    if not ESP_ENABLED or not BOTS_ENABLED then
        return
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then

            local humanoid = obj:FindFirstChildOfClass("Humanoid")

            if humanoid
                and humanoid.Health > 0
                and not isPlayerCharacter(obj)
                and getRoot(obj)
            then

                if not activeESP[obj] then

                    local nameValue =
                        obj:GetAttribute("DisplayName")

                    local botName =
                        nameValue
                        or obj.Name
                        or "BOT"

                    createESP(
                        obj,
                        tostring(botName) .. "  [BOT]",
                        "BOT"
                    )
                end
            end
        end
    end
end

--==================================================
-- REMOVE ALL ESP
--==================================================

local function removeAllESP()

    for character in pairs(activeESP) do
        removeESP(character)
    end

    for _, obj in ipairs(workspace:GetDescendants()) do

        if obj:IsA("Highlight")
            and obj.Name == "FTAP_ESP_Highlight"
        then
            obj:Destroy()

        elseif obj:IsA("BillboardGui")
            and obj.Name == "FTAP_ESP_Name"
        then
            obj:Destroy()
        end
    end
end

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")

ScreenGui.Name = "FTAP_ModMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.DisplayOrder = 2147483647

pcall(function()
    ScreenGui.Parent = CoreGui
end)

if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

--==================================================
-- MAIN WINDOW
--==================================================

local Main = Instance.new("Frame")

Main.Name = "Main"
Main.Size = UDim2.new(0, 620, 0, 440)
Main.Position = UDim2.new(0.5, -310, 0.5, -220)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 23)
Main.BorderSizePixel = 0
Main.ZIndex = 10
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(55, 55, 70)
MainStroke.Thickness = 1
MainStroke.Parent = Main

--==================================================
-- TOP BAR
--==================================================

local TopBar = Instance.new("Frame")

TopBar.Size = UDim2.new(1, 0, 0, 48)
TopBar.BackgroundColor3 = Color3.fromRGB(24, 24, 31)
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 11
TopBar.Parent = Main

local Title = Instance.new("TextLabel")

Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 18, 0, 0)
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Text = "FTAP  •  MOD MENU"
Title.TextColor3 = Color3.fromRGB(240, 240, 245)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 12
Title.Parent = TopBar

--==================================================
-- MINIMIZE
--==================================================

local Minimize = Instance.new("TextButton")

Minimize.Size = UDim2.new(0, 38, 0, 30)
Minimize.Position = UDim2.new(1, -85, 0, 9)
Minimize.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
Minimize.Text = "—"
Minimize.TextColor3 = Color3.fromRGB(230, 230, 235)
Minimize.TextSize = 18
Minimize.Font = Enum.Font.GothamBold
Minimize.BorderSizePixel = 0
Minimize.ZIndex = 13
Minimize.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = Minimize

--==================================================
-- CLOSE
--==================================================

local Close = Instance.new("TextButton")

Close.Size = UDim2.new(0, 38, 0, 30)
Close.Position = UDim2.new(1, -43, 0, 9)
Close.BackgroundColor3 = Color3.fromRGB(130, 45, 50)
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.TextSize = 20
Close.Font = Enum.Font.GothamBold
Close.BorderSizePixel = 0
Close.ZIndex = 13
Close.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = Close

--==================================================
-- SIDEBAR
--==================================================

local Sidebar = Instance.new("Frame")

Sidebar.Position = UDim2.new(0, 0, 0, 48)
Sidebar.Size = UDim2.new(0, 120, 1, -48)
Sidebar.BackgroundColor3 = Color3.fromRGB(21, 21, 27)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 11
Sidebar.Parent = Main

local ESPTab = Instance.new("TextButton")

ESPTab.Position = UDim2.new(0, 8, 0, 15)
ESPTab.Size = UDim2.new(1, -16, 0, 42)
ESPTab.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
ESPTab.Text = "ESP"
ESPTab.TextColor3 = Color3.fromRGB(240, 240, 245)
ESPTab.TextSize = 14
ESPTab.Font = Enum.Font.GothamBold
ESPTab.BorderSizePixel = 0
ESPTab.ZIndex = 12
ESPTab.Parent = Sidebar

local ESPCorner = Instance.new("UICorner")
ESPCorner.CornerRadius = UDim.new(0, 7)
ESPCorner.Parent = ESPTab

local AIMTab = Instance.new("TextButton")

AIMTab.Position = UDim2.new(0, 8, 0, 65)
AIMTab.Size = UDim2.new(1, -16, 0, 42)
AIMTab.BackgroundColor3 = Color3.fromRGB(29, 29, 36)
AIMTab.Text = "AIM"
AIMTab.TextColor3 = Color3.fromRGB(180, 180, 190)
AIMTab.TextSize = 14
AIMTab.Font = Enum.Font.GothamBold
AIMTab.BorderSizePixel = 0
AIMTab.ZIndex = 12
AIMTab.Parent = Sidebar

local AIMCorner = Instance.new("UICorner")
AIMCorner.CornerRadius = UDim.new(0, 7)
AIMCorner.Parent = AIMTab

--==================================================
-- CONTENT
--==================================================

local ESPContent = Instance.new("Frame")

ESPContent.Position = UDim2.new(0, 120, 0, 48)
ESPContent.Size = UDim2.new(1, -120, 1, -48)
ESPContent.BackgroundTransparency = 1
ESPContent.ZIndex = 11
ESPContent.Parent = Main

local AIMContent = Instance.new("ScrollingFrame")

AIMContent.Position = UDim2.new(0, 120, 0, 48)
AIMContent.Size = UDim2.new(1, -120, 1, -48)
AIMContent.BackgroundTransparency = 1
AIMContent.BorderSizePixel = 0
AIMContent.ScrollBarThickness = 4
AIMContent.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 85)
AIMContent.CanvasSize = UDim2.new(0, 0, 0, 570)
AIMContent.Visible = false
AIMContent.ZIndex = 11
AIMContent.Parent = Main

--==================================================
-- ESP TITLE
--==================================================

local ESPTitle = Instance.new("TextLabel")

ESPTitle.BackgroundTransparency = 1
ESPTitle.Position = UDim2.new(0, 18, 0, 15)
ESPTitle.Size = UDim2.new(1, -36, 0, 28)
ESPTitle.Text = "ESP SETTINGS"
ESPTitle.TextColor3 = Color3.fromRGB(240, 240, 245)
ESPTitle.TextSize = 15
ESPTitle.Font = Enum.Font.GothamBold
ESPTitle.TextXAlignment = Enum.TextXAlignment.Left
ESPTitle.ZIndex = 12
ESPTitle.Parent = ESPContent

--==================================================
-- ESP TOGGLE
--==================================================

local ESPToggle = Instance.new("TextButton")

ESPToggle.Position = UDim2.new(0, 18, 0, 50)
ESPToggle.Size = UDim2.new(1, -36, 0, 40)
ESPToggle.BackgroundColor3 = Color3.fromRGB(29, 29, 37)
ESPToggle.TextColor3 = Color3.fromRGB(235, 235, 240)
ESPToggle.TextSize = 13
ESPToggle.Font = Enum.Font.GothamMedium
ESPToggle.TextXAlignment = Enum.TextXAlignment.Left
ESPToggle.BorderSizePixel = 0
ESPToggle.ZIndex = 12
ESPToggle.Parent = ESPContent

local ESPToggleCorner = Instance.new("UICorner")
ESPToggleCorner.CornerRadius = UDim.new(0, 7)
ESPToggleCorner.Parent = ESPToggle

local function refreshESPToggle()

    ESPToggle.Text =
        "   ESP     ["
        .. (ESP_ENABLED and "ON" or "OFF")
        .. "]"

    if ESP_ENABLED then
        ESPToggle.BackgroundColor3 =
            Color3.fromRGB(30, 65, 50)
    else
        ESPToggle.BackgroundColor3 =
            Color3.fromRGB(29, 29, 37)
    end
end

ESPToggle.MouseButton1Click:Connect(function()

    ESP_ENABLED = not ESP_ENABLED

    if not ESP_ENABLED then

        removeAllESP()

    else

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                updatePlayerESP(player)
            end
        end

        scanBots()
    end

    refreshESPToggle()
end)

refreshESPToggle()

--==================================================
-- BOT TOGGLE
--==================================================

local BotToggle = Instance.new("TextButton")

BotToggle.Position = UDim2.new(0, 18, 0, 98)
BotToggle.Size = UDim2.new(1, -36, 0, 40)
BotToggle.BackgroundColor3 = Color3.fromRGB(29, 29, 37)
BotToggle.TextColor3 = Color3.fromRGB(235, 235, 240)
BotToggle.TextSize = 13
BotToggle.Font = Enum.Font.GothamMedium
BotToggle.TextXAlignment = Enum.TextXAlignment.Left
BotToggle.BorderSizePixel = 0
BotToggle.ZIndex = 12
BotToggle.Parent = ESPContent

local BotCorner = Instance.new("UICorner")
BotCorner.CornerRadius = UDim.new(0, 7)
BotCorner.Parent = BotToggle

local function refreshBotToggle()

    BotToggle.Text =
        "   BOTS     ["
        .. (BOTS_ENABLED and "ON" or "OFF")
        .. "]"

    if BOTS_ENABLED then
        BotToggle.BackgroundColor3 =
            Color3.fromRGB(70, 52, 28)
    else
        BotToggle.BackgroundColor3 =
            Color3.fromRGB(29, 29, 37)
    end
end

BotToggle.MouseButton1Click:Connect(function()

    BOTS_ENABLED = not BOTS_ENABLED

    if not BOTS_ENABLED then

        for character, data in pairs(activeESP) do

            if data.kind == "BOT" then
                removeESP(character)
            end

        end
    end

    refreshBotToggle()
end)

refreshBotToggle()

--==================================================
-- PLAYER LIST
--==================================================

local PlayerTitle = Instance.new("TextLabel")

PlayerTitle.BackgroundTransparency = 1
PlayerTitle.Position = UDim2.new(0, 18, 0, 150)
PlayerTitle.Size = UDim2.new(1, -36, 0, 25)
PlayerTitle.Text = "PLAYERS"
PlayerTitle.TextColor3 = Color3.fromRGB(180, 180, 190)
PlayerTitle.TextSize = 12
PlayerTitle.Font = Enum.Font.GothamBold
PlayerTitle.TextXAlignment = Enum.TextXAlignment.Left
PlayerTitle.ZIndex = 12
PlayerTitle.Parent = ESPContent

local PlayerList = Instance.new("ScrollingFrame")

PlayerList.Position = UDim2.new(0, 18, 0, 178)
PlayerList.Size = UDim2.new(1, -36, 0, 205)
PlayerList.BackgroundColor3 = Color3.fromRGB(22, 22, 29)
PlayerList.BorderSizePixel = 0
PlayerList.ScrollBarThickness = 4
PlayerList.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 85)
PlayerList.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerList.ZIndex = 12
PlayerList.Parent = ESPContent

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 7)
ListCorner.Parent = PlayerList

local PlayerLayout = Instance.new("UIListLayout")

PlayerLayout.Padding = UDim.new(0, 5)
PlayerLayout.SortOrder = Enum.SortOrder.Name
PlayerLayout.Parent = PlayerList

local PlayerPadding = Instance.new("UIPadding")

PlayerPadding.PaddingTop = UDim.new(0, 6)
PlayerPadding.PaddingBottom = UDim.new(0, 6)
PlayerPadding.PaddingLeft = UDim.new(0, 6)
PlayerPadding.PaddingRight = UDim.new(0, 6)
PlayerPadding.Parent = PlayerList

local function refreshPlayerList()

    for _, child in ipairs(PlayerList:GetChildren()) do

        if child:IsA("TextButton") then
            child:Destroy()
        end

    end

    local players = Players:GetPlayers()

    table.sort(players, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    for _, player in ipairs(players) do

        if player ~= LocalPlayer then

            if selectedPlayers[player.UserId] == nil then
                selectedPlayers[player.UserId] = false
            end

            local button = Instance.new("TextButton")

            button.Size = UDim2.new(1, -4, 0, 32)

            button.BackgroundColor3 =
                selectedPlayers[player.UserId]
                and Color3.fromRGB(30, 65, 50)
                or Color3.fromRGB(32, 32, 40)

            button.Text =
                "  "
                .. player.DisplayName
                .. "  ["
                .. (
                    selectedPlayers[player.UserId]
                    and "ON"
                    or "OFF"
                )
                .. "]"

            button.TextColor3 =
                Color3.fromRGB(230, 230, 235)

            button.TextSize = 12
            button.Font = Enum.Font.GothamMedium
            button.TextXAlignment =
                Enum.TextXAlignment.Left

            button.BorderSizePixel = 0
            button.ZIndex = 13
            button.Parent = PlayerList

            local corner = Instance.new("UICorner")

            corner.CornerRadius = UDim.new(0, 5)
            corner.Parent = button

            button.MouseButton1Click:Connect(function()

                selectedPlayers[player.UserId] =
                    not selectedPlayers[player.UserId]

                updatePlayerESP(player)

                refreshPlayerList()
            end)
        end
    end

    task.defer(function()

        PlayerList.CanvasSize =
            UDim2.new(
                0,
                0,
                0,
                PlayerLayout.AbsoluteContentSize.Y + 12
            )
    end)
end

refreshPlayerList()

--==================================================
-- AIM TITLE
--==================================================

local AIMTitle = Instance.new("TextLabel")

AIMTitle.BackgroundTransparency = 1
AIMTitle.Position = UDim2.new(0, 18, 0, 15)
AIMTitle.Size = UDim2.new(1, -36, 0, 28)
AIMTitle.Text = "AIM SETTINGS"
AIMTitle.TextColor3 = Color3.fromRGB(240, 240, 245)
AIMTitle.TextSize = 15
AIMTitle.Font = Enum.Font.GothamBold
AIMTitle.TextXAlignment = Enum.TextXAlignment.Left
AIMTitle.ZIndex = 12
AIMTitle.Parent = AIMContent

--==================================================
-- AIM TOGGLE
--==================================================

local AIMToggle = Instance.new("TextButton")

AIMToggle.Position = UDim2.new(0, 18, 0, 50)
AIMToggle.Size = UDim2.new(1, -36, 0, 40)
AIMToggle.BackgroundColor3 = Color3.fromRGB(29, 29, 37)
AIMToggle.TextColor3 = Color3.fromRGB(235, 235, 240)
AIMToggle.TextSize = 13
AIMToggle.Font = Enum.Font.GothamMedium
AIMToggle.TextXAlignment = Enum.TextXAlignment.Left
AIMToggle.BorderSizePixel = 0
AIMToggle.ZIndex = 12
AIMToggle.Parent = AIMContent

local AIMToggleCorner = Instance.new("UICorner")
AIMToggleCorner.CornerRadius = UDim.new(0, 7)
AIMToggleCorner.Parent = AIMToggle

local function refreshAIMToggle()

    AIMToggle.Text =
        "   AIM     ["
        .. (AIM_ENABLED and "ON" or "OFF")
        .. "]"

    if AIM_ENABLED then

        AIMToggle.BackgroundColor3 =
            Color3.fromRGB(25, 65, 75)

    else

        AIMToggle.BackgroundColor3 =
            Color3.fromRGB(29, 29, 37)
    end
end

AIMToggle.MouseButton1Click:Connect(function()

    AIM_ENABLED = not AIM_ENABLED

    if not AIM_ENABLED then
        aimHolding = false
        aimToggled = false
    end

    refreshAIMToggle()
end)

refreshAIMToggle()

--==================================================
-- SLIDER
--==================================================

local function createSlider(
    parent,
    y,
    title,
    minValue,
    maxValue,
    initialValue,
    callback
)

    local container = Instance.new("Frame")

    container.Position =
        UDim2.new(0, 18, 0, y)

    container.Size =
        UDim2.new(1, -36, 0, 62)

    container.BackgroundTransparency = 1
    container.ZIndex = 12
    container.Parent = parent

    local label = Instance.new("TextLabel")

    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(1, 0, 0, 22)
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 13
    label.Parent = container

    local bar = Instance.new("Frame")

    bar.Position = UDim2.new(0, 0, 0, 32)
    bar.Size = UDim2.new(1, 0, 0, 7)
    bar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    bar.BorderSizePixel = 0
    bar.ZIndex = 13
    bar.Parent = container

    local barCorner = Instance.new("UICorner")

    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")

    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = AIM_COLOR
    fill.BorderSizePixel = 0
    fill.ZIndex = 14
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner")

    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local dragging = false

    local function setValue(newValue)

        local value =
            math.clamp(
                newValue,
                minValue,
                maxValue
            )

        local percent =
            (value - minValue)
            / (maxValue - minValue)

        fill.Size =
            UDim2.new(
                percent,
                0,
                1,
                0
            )

        label.Text =
            title
            .. ": "
            .. tostring(math.floor(value))

        callback(value)
    end

    local function updateFromMouse(x)

        if bar.AbsoluteSize.X <= 0 then
            return
        end

        local relative =
            math.clamp(
                x - bar.AbsolutePosition.X,
                0,
                bar.AbsoluteSize.X
            )

        local percent =
            relative / bar.AbsoluteSize.X

        setValue(
            minValue
            + (
                (maxValue - minValue)
                * percent
            )
        )
    end

    bar.InputBegan:Connect(function(input)

        if input.UserInputType
            == Enum.UserInputType.MouseButton1
        then

            dragging = true

            updateFromMouse(
                input.Position.X
            )
        end
    end)

    UserInputService.InputChanged:Connect(function(input)

        if dragging
            and input.UserInputType
                == Enum.UserInputType.MouseMovement
        then

            updateFromMouse(
                input.Position.X
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)

        if input.UserInputType
            == Enum.UserInputType.MouseButton1
        then

            dragging = false
        end
    end)

    setValue(initialValue)

    return container
end

--==================================================
-- AIM SLIDERS
--==================================================

createSlider(
    AIMContent,
    100,
    "FOV",
    20,
    500,
    AIM_FOV,
    function(value)
        AIM_FOV = value
    end
)

createSlider(
    AIMContent,
    165,
    "Max Distance",
    50,
    2000,
    AIM_MAX_DISTANCE,
    function(value)
        AIM_MAX_DISTANCE = value
    end
)

createSlider(
    AIMContent,
    230,
    "Smoothness",
    1,
    30,
    AIM_SMOOTHNESS,
    function(value)
        AIM_SMOOTHNESS = value
    end
)

--==================================================
-- AIM OPTIONS
--==================================================

local function createOptionButton(
    y,
    title,
    getValue,
    setValue
)

    local button = Instance.new("TextButton")

    button.Position =
        UDim2.new(0, 18, 0, y)

    button.Size =
        UDim2.new(1, -36, 0, 38)

    button.BackgroundColor3 =
        Color3.fromRGB(29, 29, 37)

    button.TextColor3 =
        Color3.fromRGB(230, 230, 235)

    button.TextSize = 12
    button.Font = Enum.Font.GothamMedium
    button.TextXAlignment =
        Enum.TextXAlignment.Left

    button.BorderSizePixel = 0
    button.ZIndex = 12
    button.Parent = AIMContent

    local corner = Instance.new("UICorner")

    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    local function refresh()

        button.Text =
            "   "
            .. title
            .. ": "
            .. tostring(getValue())
    end

    button.MouseButton1Click:Connect(function()

        setValue()

        refresh()
    end)

    refresh()

    return button
end

createOptionButton(
    295,
    "Target Part",

    function()
        return AIM_TARGET_PART
    end,

    function()

        if AIM_TARGET_PART == "Head" then
            AIM_TARGET_PART = "HumanoidRootPart"
        else
            AIM_TARGET_PART = "Head"
        end
    end
)

createOptionButton(
    340,
    "Visible Check",

    function()
        return AIM_VISIBLE_CHECK
            and "ON"
            or "OFF"
    end,

    function()
        AIM_VISIBLE_CHECK =
            not AIM_VISIBLE_CHECK
    end
)

createOptionButton(
    385,
    "Team Check",

    function()
        return AIM_TEAM_CHECK
            and "ON"
            or "OFF"
    end,

    function()
        AIM_TEAM_CHECK =
            not AIM_TEAM_CHECK
    end
)

createOptionButton(
    430,
    "Selected Only",

    function()
        return AIM_SELECTED_ONLY
            and "ON"
            or "OFF"
    end,

    function()
        AIM_SELECTED_ONLY =
            not AIM_SELECTED_ONLY
    end
)

createOptionButton(
    475,
    "Activation",

    function()

        return AIM_HOLD_MODE
            and "HOLD Q"
            or "TOGGLE Q"
    end,

    function()

        AIM_HOLD_MODE =
            not AIM_HOLD_MODE

        aimHolding = false
        aimToggled = false
    end
)

--==================================================
-- AIM KEY
--==================================================

local KeyButton = Instance.new("TextButton")

KeyButton.Position =
    UDim2.new(0, 18, 0, 520)

KeyButton.Size =
    UDim2.new(1, -36, 0, 38)

KeyButton.BackgroundColor3 =
    Color3.fromRGB(29, 29, 37)

KeyButton.TextColor3 =
    Color3.fromRGB(230, 230, 235)

KeyButton.TextSize = 12
KeyButton.Font = Enum.Font.GothamMedium
KeyButton.TextXAlignment =
    Enum.TextXAlignment.Left

KeyButton.BorderSizePixel = 0
KeyButton.ZIndex = 12
KeyButton.Parent = AIMContent

local KeyCorner = Instance.new("UICorner")

KeyCorner.CornerRadius = UDim.new(0, 7)
KeyCorner.Parent = KeyButton

local function getKeyName()

    if AIM_KEY == Enum.KeyCode.Q then
        return "Q"
    end

    if typeof(AIM_KEY) == "EnumItem" then
        return AIM_KEY.Name
    end

    return "Unknown"
end

local function refreshKeyButton()

    if waitingForKey then

        KeyButton.Text =
            "   Aim Key: PRESS A KEY..."

    else

        KeyButton.Text =
            "   Aim Key: "
            .. getKeyName()
    end
end

KeyButton.MouseButton1Click:Connect(function()

    waitingForKey = true

    refreshKeyButton()
end)

refreshKeyButton()

--==================================================
-- TAB SWITCH
--==================================================

ESPTab.MouseButton1Click:Connect(function()

    ESPContent.Visible = true
    AIMContent.Visible = false

    ESPTab.BackgroundColor3 =
        Color3.fromRGB(40, 40, 52)

    ESPTab.TextColor3 =
        Color3.fromRGB(240, 240, 245)

    AIMTab.BackgroundColor3 =
        Color3.fromRGB(29, 29, 36)

    AIMTab.TextColor3 =
        Color3.fromRGB(180, 180, 190)
end)

AIMTab.MouseButton1Click:Connect(function()

    ESPContent.Visible = false
    AIMContent.Visible = true

    AIMTab.BackgroundColor3 =
        Color3.fromRGB(40, 40, 52)

    AIMTab.TextColor3 =
        Color3.fromRGB(240, 240, 245)

    ESPTab.BackgroundColor3 =
        Color3.fromRGB(29, 29, 36)

    ESPTab.TextColor3 =
        Color3.fromRGB(180, 180, 190)
end)

--==================================================
-- FOV CIRCLE
--==================================================

local FOVCircle = Instance.new("Frame")

FOVCircle.Name = "AIM_FOV_Circle"
FOVCircle.AnchorPoint =
    Vector2.new(0.5, 0.5)

FOVCircle.Size =
    UDim2.new(
        0,
        AIM_FOV * 2,
        0,
        AIM_FOV * 2
    )

FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Visible = false
FOVCircle.ZIndex = 5
FOVCircle.Parent = ScreenGui

local FOVCorner = Instance.new("UICorner")

FOVCorner.CornerRadius =
    UDim.new(1, 0)

FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")

FOVStroke.Color = AIM_COLOR
FOVStroke.Thickness = 1.5
FOVStroke.Transparency = 0.15
FOVStroke.Parent = FOVCircle

--==================================================
-- RAYCAST
--==================================================

local rayParams = RaycastParams.new()

rayParams.FilterType =
    Enum.RaycastFilterType.Exclude

local function isVisible(
    targetCharacter,
    targetPosition
)

    local camera =
        workspace.CurrentCamera

    if not camera then
        return false
    end

    local localCharacter =
        LocalPlayer.Character

    local filter = {}

    if localCharacter then
        table.insert(
            filter,
            localCharacter
        )
    end

    rayParams.FilterDescendantsInstances =
        filter

    local origin =
        camera.CFrame.Position

    local direction =
        targetPosition - origin

    local result =
        workspace:Raycast(
            origin,
            direction,
            rayParams
        )

    if not result then
        return true
    end

    return result.Instance
        and result.Instance:IsDescendantOf(
            targetCharacter
        )
end

--==================================================
-- TEAM CHECK
--==================================================

local function isEnemy(player)

    if not AIM_TEAM_CHECK then
        return true
    end

    if not LocalPlayer.Team
        or not player.Team
    then
        return true
    end

    return LocalPlayer.Team ~= player.Team
end

--==================================================
-- FIND AIM TARGET
--==================================================

local function getBestTarget()

    if not AIM_ENABLED then
        return nil
    end

    local camera =
        workspace.CurrentCamera

    if not camera then
        return nil
    end

    local viewport =
        camera.ViewportSize

    local screenCenter =
        Vector2.new(
            viewport.X / 2,
            viewport.Y / 2
        )

    local bestPlayer = nil
    local bestPart = nil

    local bestScreenDistance =
        AIM_FOV + 1

    local bestWorldDistance =
        math.huge

    local localCharacter =
        LocalPlayer.Character

    local localRoot =
        getRoot(localCharacter)

    if not localRoot then
        return nil
    end

    for _, player in ipairs(
        Players:GetPlayers()
    ) do

        if player ~= LocalPlayer then

            local character =
                player.Character

            if character
                and isAlive(character)
                and isEnemy(player)
            then

                if not AIM_SELECTED_ONLY
                    or selectedPlayers[player.UserId]
                then

                    local targetPart =
                        getTargetPart(character)

                    if targetPart then

                        local worldDistance =
                            (
                                targetPart.Position
                                - localRoot.Position
                            ).Magnitude

                        if worldDistance
                            <= AIM_MAX_DISTANCE
                        then

                            local screenPoint,
                                onScreen =
                                camera:WorldToViewportPoint(
                                    targetPart.Position
                                )

                            if onScreen
                                and screenPoint.Z > 0
                            then

                                local screenPosition =
                                    Vector2.new(
                                        screenPoint.X,
                                        screenPoint.Y
                                    )

                                local screenDistance =
                                    (
                                        screenPosition
                                        - screenCenter
                                    ).Magnitude

                                if screenDistance
                                    <= AIM_FOV
                                then

                                    local visible =
                                        true

                                    if AIM_VISIBLE_CHECK then

                                        visible =
                                            isVisible(
                                                character,
                                                targetPart.Position
                                            )
                                    end

                                    if visible then

                                        if
                                            screenDistance
                                            < bestScreenDistance
                                            or (
                                                math.abs(
                                                    screenDistance
                                                    - bestScreenDistance
                                                ) < 1
                                                and worldDistance
                                                < bestWorldDistance
                                            )
                                        then

                                            bestScreenDistance =
                                                screenDistance

                                            bestWorldDistance =
                                                worldDistance

                                            bestPlayer =
                                                player

                                            bestPart =
                                                targetPart
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return bestPlayer, bestPart
end

--==================================================
-- AIM
--==================================================

local function aimAt(
    targetPart,
    deltaTime
)

    if not targetPart then
        return
    end

    local camera =
        workspace.CurrentCamera

    if not camera then
        return
    end

    local cameraPosition =
        camera.CFrame.Position

    local targetPosition =
        targetPart.Position

    local desiredCFrame =
        CFrame.lookAt(
            cameraPosition,
            targetPosition
        )

    local smooth =
        1 - math.exp(
            -AIM_SMOOTHNESS
            * deltaTime
        )

    smooth =
        math.clamp(
            smooth,
            0.01,
            1
        )

    camera.CFrame =
        camera.CFrame:Lerp(
            desiredCFrame,
            smooth
        )
end

--==================================================
-- DRAG MENU
--==================================================

local dragging = false
local dragStart
local startPosition

TopBar.InputBegan:Connect(function(input)

    if input.UserInputType
        == Enum.UserInputType.MouseButton1
    then

        dragging = true

        dragStart =
            input.Position

        startPosition =
            Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)

    if dragging
        and input.UserInputType
            == Enum.UserInputType.MouseMovement
    then

        local delta =
            input.Position - dragStart

        Main.Position =
            UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset
                    + delta.X,

                startPosition.Y.Scale,
                startPosition.Y.Offset
                    + delta.Y
            )
    end
end)

UserInputService.InputEnded:Connect(function(input)

    if input.UserInputType
        == Enum.UserInputType.MouseButton1
    then

        dragging = false
    end
end)

--==================================================
-- MINIMIZE
--==================================================

local minimized = false

Minimize.MouseButton1Click:Connect(function()

    minimized =
        not minimized

    Sidebar.Visible =
        not minimized

    if minimized then

        ESPContent.Visible = false
        AIMContent.Visible = false

        Main.Size =
            UDim2.new(
                0,
                620,
                0,
                48
            )

        Minimize.Text = "+"

    else

        Main.Size =
            UDim2.new(
                0,
                620,
                0,
                440
            )

        Minimize.Text = "—"

        if AIMTab.BackgroundColor3
            == Color3.fromRGB(
                40,
                40,
                52
            )
        then

            AIMContent.Visible = true
            ESPContent.Visible = false

        else

            ESPContent.Visible = true
            AIMContent.Visible = false
        end
    end
end)

--==================================================
-- CLOSE
--==================================================

local running = true

Close.MouseButton1Click:Connect(function()

    running = false

    AIM_ENABLED = false
    aimHolding = false
    aimToggled = false

    removeAllESP()

    UserInputService.MouseBehavior =
        Enum.MouseBehavior.Default

    UserInputService.MouseIconEnabled =
        true

    pcall(function()
        RunService:UnbindFromRenderStep(
            "FTAP_AIM"
        )
    end)

    ScreenGui:Destroy()
end)

--==================================================
-- INPUT
--==================================================

UserInputService.InputBegan:Connect(
    function(input, gameProcessed)

        if not running then
            return
        end

        -- KEY BIND SETTING
        if waitingForKey then

            if input.UserInputType
                == Enum.UserInputType.Keyboard
            then

                if input.KeyCode
                    ~= Enum.KeyCode.Unknown
                then

                    AIM_KEY =
                        input.KeyCode

                    waitingForKey =
                        false

                    refreshKeyButton()

                    return
                end
            end
        end

        -- U = UNLOCK MOUSE
        if input.KeyCode
            == Enum.KeyCode.U
        then

            UserInputService.MouseBehavior =
                Enum.MouseBehavior.Default

            UserInputService.MouseIconEnabled =
                true
        end

        -- RIGHT SHIFT = MENU
        if input.KeyCode
            == Enum.KeyCode.RightShift
        then

            ScreenGui.Enabled =
                not ScreenGui.Enabled

            if ScreenGui.Enabled then

                UserInputService.MouseBehavior =
                    Enum.MouseBehavior.Default

                UserInputService.MouseIconEnabled =
                    true
            end

            return
        end

        if gameProcessed then
            return
        end

        -- AIM
        if AIM_ENABLED then

            if input.KeyCode
                == AIM_KEY
            then

                if AIM_HOLD_MODE then

                    aimHolding = true

                else

                    aimToggled =
                        not aimToggled
                end
            end
        end
    end
)

UserInputService.InputEnded:Connect(
    function(input)

        if not running then
            return
        end

        if AIM_HOLD_MODE then

            if input.KeyCode
                == AIM_KEY
            then

                aimHolding = false
            end
        end
    end
)

--==================================================
-- PLAYER EVENTS
--==================================================

Players.PlayerAdded:Connect(
    function(player)

        if player ~= LocalPlayer then

            selectedPlayers[player.UserId] =
                false

            player.CharacterAdded:Connect(
                function()

                    task.wait(0.5)

                    updatePlayerESP(
                        player
                    )
                end
            )

            refreshPlayerList()
        end
    end
)

Players.PlayerRemoving:Connect(
    function(player)

        selectedPlayers[player.UserId] =
            nil

        if player.Character then
            removeESP(
                player.Character
            )
        end

        refreshPlayerList()
    end
)

for _, player in ipairs(
    Players:GetPlayers()
) do

    if player ~= LocalPlayer then

        player.CharacterAdded:Connect(
            function()

                task.wait(0.5)

                updatePlayerESP(
                    player
                )
            end
        )
    end
end

--==================================================
-- RENDER LOOP
--==================================================

local botScanTimer = 0

RunService:BindToRenderStep(
    "FTAP_AIM",
    Enum.RenderPriority.Camera.Value + 1,

    function(deltaTime)

        if not running then
            return
        end

        local camera =
            workspace.CurrentCamera

        -- FOV CIRCLE
        if camera then

            local viewport =
                camera.ViewportSize

            FOVCircle.Position =
                UDim2.new(
                    0,
                    viewport.X / 2,
                    0,
                    viewport.Y / 2
                )

            FOVCircle.Size =
                UDim2.new(
                    0,
                    AIM_FOV * 2,
                    0,
                    AIM_FOV * 2
                )

            FOVCircle.Visible =
                AIM_ENABLED
        end

        -- AIM
        local activation

        if AIM_HOLD_MODE then
            activation = aimHolding
        else
            activation = aimToggled
        end

        if AIM_ENABLED
            and activation
        then

            local targetPlayer,
                targetPart =
                getBestTarget()

            if targetPlayer
                and targetPart
            then

                aimAt(
                    targetPart,
                    deltaTime
                )
            end
        end

        -- ESP
        if ESP_ENABLED then

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player ~= LocalPlayer then

                    local character =
                        player.Character

                    if character then

                        local data =
                            activeESP[character]

                        if selectedPlayers[
                            player.UserId
                        ]
                        then

                            if not data
                                or data.kind
                                    ~= "PLAYER"
                            then

                                updatePlayerESP(
                                    player
                                )
                            end

                        else

                            if data then
                                removeESP(
                                    character
                                )
                            end
                        end
                    end
                end
            end

            botScanTimer =
                botScanTimer
                + deltaTime

            if botScanTimer >= 1 then

                botScanTimer = 0

                scanBots()
            end
        end
    end
)

--==================================================
-- FINAL CLEANUP
--==================================================

for _, obj in ipairs(
    workspace:GetDescendants()
) do

    if obj:IsA("Highlight")
        and obj.Name
            == "FTAP_ESP_Highlight"
    then

        obj:Destroy()
    end

    if obj:IsA("BillboardGui")
        and obj.Name
            == "FTAP_ESP_Name"
    then

        obj:Destroy()
    end
end

print("================================")
print("FTAP Mod Menu loaded")
print("AIM KEY: Q")
print("RightShift = Menu")
print("U = Unlock Mouse")
print("================================")
