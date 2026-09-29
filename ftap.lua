--// FTAP MOD MENU
--// ESP + LOCK
--// LOCK KEY: Q
--// Red ESP / Select All / Clear All / Selected Player Lock

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

pcall(function()
    local old = CoreGui:FindFirstChild("FTAP_ModMenu")
    if old then old:Destroy() end
end)
pcall(function()
    local old = LocalPlayer.PlayerGui:FindFirstChild("FTAP_ModMenu")
    if old then old:Destroy() end
end)

--==================================================
-- SETTINGS
--==================================================

local ESP_ENABLED = false
local BOTS_ENABLED = false

local LOCK_ENABLED = false
local LOCK_FOV = 150
local LOCK_MAX_DISTANCE = 500
local LOCK_STRENGTH = 8
local LOCK_TARGET_PART = "Head"
local LOCK_VISIBLE_CHECK = true
local LOCK_TEAM_CHECK = false
local LOCK_KEY = Enum.KeyCode.Q

local selectedPlayers = {}
local activeESP = {}
local lockedPlayer = nil
local lockActive = false
local waitingForKey = false
local running = true

local RED = Color3.fromRGB(255, 55, 55)
local RED_DARK = Color3.fromRGB(120, 30, 35)
local RED_SOFT = Color3.fromRGB(55, 28, 32)
local WHITE = Color3.fromRGB(242, 242, 246)
local MUTED = Color3.fromRGB(160, 160, 172)
local PANEL = Color3.fromRGB(17, 18, 23)
local PANEL2 = Color3.fromRGB(23, 24, 31)
local PANEL3 = Color3.fromRGB(30, 31, 40)
local BORDER = Color3.fromRGB(52, 53, 65)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then selectedPlayers[p.UserId] = false end
end

--==================================================
-- HELPERS
--==================================================

local function characterOf(player)
    return player and player.Character
end

local function humanoidOf(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function alive(character)
    local h = humanoidOf(character)
    return h and h.Health > 0
end

local function rootOf(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
end

local function targetPartOf(character)
    if not character then return nil end
    if LOCK_TARGET_PART == "Head" then
        return character:FindFirstChild("Head") or rootOf(character)
    end
    return rootOf(character)
end

local function destroyOldESP(character)
    if not character then return end
    local data = activeESP[character]
    if data then
        pcall(function() data.highlight:Destroy() end)
        pcall(function() data.billboard:Destroy() end)
        activeESP[character] = nil
    end
    local h = character:FindFirstChild("FTAP_ESP_Highlight")
    if h then h:Destroy() end
    local b = character:FindFirstChild("FTAP_ESP_Name")
    if b then b:Destroy() end
end

local function createESP(character, name, kind)
    if not character then return end
    destroyOldESP(character)

    local color = RED
    if kind == "BOT" then color = Color3.fromRGB(255, 95, 65) end

    local highlight = Instance.new("Highlight")
    highlight.Name = "FTAP_ESP_Highlight"
    highlight.Adornee = character
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.58
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    local bill = Instance.new("BillboardGui")
    bill.Name = "FTAP_ESP_Name"
    bill.Adornee = rootOf(character)
    bill.Size = UDim2.fromOffset(260, 50)
    bill.StudsOffset = Vector3.new(0, 3.1, 0)
    bill.AlwaysOnTop = true
    bill.MaxDistance = 10000
    bill.Parent = character

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Text = name
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.Parent = bill

    activeESP[character] = {
        highlight = highlight,
        billboard = bill,
        text = label,
        kind = kind
    }
end

local function updatePlayerESP(player)
    if not player or player == LocalPlayer then return end
    local character = player.Character
    if not character then return end
    destroyOldESP(character)
    if ESP_ENABLED and selectedPlayers[player.UserId] then
        createESP(character, player.DisplayName .. "  [" .. player.Name .. "]", "PLAYER")
    end
end

local function isPlayerCharacter(character)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == character then return true end
    end
    return false
end

local function scanBots()
    if not ESP_ENABLED or not BOTS_ENABLED then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not isPlayerCharacter(obj) then
            local h = humanoidOf(obj)
            if h and h.Health > 0 and rootOf(obj) and not activeESP[obj] then
                local n = obj:GetAttribute("DisplayName") or obj.Name or "BOT"
                createESP(obj, tostring(n) .. "  [BOT]", "BOT")
            end
        end
    end
end

local function removeAllESP()
    for character in pairs(activeESP) do
        destroyOldESP(character)
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Highlight") and obj.Name == "FTAP_ESP_Highlight")
            or (obj:IsA("BillboardGui") and obj.Name == "FTAP_ESP_Name") then
            obj:Destroy()
        end
    end
end

--==================================================
-- GUI HELPERS
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FTAP_ModMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.DisplayOrder = 2147483647
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(760, 500)
Main.Position = UDim2.new(.5, -380, .5, -250)
Main.BackgroundColor3 = PANEL
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = Main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = BORDER
mainStroke.Thickness = 1
mainStroke.Parent = Main

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 58)
Top.BackgroundColor3 = PANEL2
Top.BorderSizePixel = 0
Top.Parent = Main

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(20, 5)
title.Size = UDim2.fromOffset(500, 28)
title.Text = "FTAP  /  CONTROL CENTER"
title.TextColor3 = WHITE
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = Top

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(21, 31)
subtitle.Size = UDim2.fromOffset(500, 20)
subtitle.Text = "ESP + PLAYER LOCK"
subtitle.TextColor3 = MUTED
subtitle.TextSize = 10
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = Top

local function button(parent, text, pos, size)
    local b = Instance.new("TextButton")
    b.Position = pos
    b.Size = size
    b.BackgroundColor3 = PANEL3
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = WHITE
    b.TextSize = 12
    b.Font = Enum.Font.GothamMedium
    b.AutoButtonColor = false
    b.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b
    return b
end

local Min = button(Top, "—", UDim2.new(1, -90, 0, 13), UDim2.fromOffset(34, 32))
local Close = button(Top, "×", UDim2.new(1, -48, 0, 13), UDim2.fromOffset(34, 32))
Close.BackgroundColor3 = RED_DARK

local Side = Instance.new("Frame")
Side.Position = UDim2.fromOffset(0, 58)
Side.Size = UDim2.new(0, 145, 1, -58)
Side.BackgroundColor3 = Color3.fromRGB(20, 21, 27)
Side.BorderSizePixel = 0
Side.Parent = Main

local ESPTab = button(Side, "◈   ESP", UDim2.fromOffset(10, 16), UDim2.fromOffset(125, 44))
local LockTab = button(Side, "◎   LOCK", UDim2.fromOffset(10, 68), UDim2.fromOffset(125, 44))

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(12, 430)
status.Size = UDim2.fromOffset(120, 35)
status.Text = "Q  LOCK\nRightShift  MENU"
status.TextColor3 = MUTED
status.TextSize = 10
status.Font = Enum.Font.GothamMedium
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = Side

local ESPPage = Instance.new("Frame")
ESPPage.Position = UDim2.fromOffset(145, 58)
ESPPage.Size = UDim2.new(1, -145, 1, -58)
ESPPage.BackgroundTransparency = 1
ESPPage.Parent = Main

local LockPage = Instance.new("ScrollingFrame")
LockPage.Position = UDim2.fromOffset(145, 58)
LockPage.Size = UDim2.new(1, -145, 1, -58)
LockPage.BackgroundTransparency = 1
LockPage.BorderSizePixel = 0
LockPage.ScrollBarThickness = 4
LockPage.ScrollBarImageColor3 = RED
LockPage.CanvasSize = UDim2.new(0, 0, 0, 610)
LockPage.Visible = false
LockPage.Parent = Main

local function heading(parent, text, y)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = UDim2.fromOffset(22, y)
    l.Size = UDim2.new(1, -44, 0, 30)
    l.Text = text
    l.TextColor3 = WHITE
    l.TextSize = 16
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

heading(ESPPage, "ESP SETTINGS", 18)
heading(LockPage, "PLAYER LOCK", 18)

local function toggleButton(parent, text, y, getter, setter)
    local b = button(parent, "", UDim2.fromOffset(22, y), UDim2.new(1, -44, 0, 40))
    local function refresh()
        local on = getter()
        b.Text = "   " .. text .. "                         " .. (on and "ON" or "OFF")
        b.BackgroundColor3 = on and RED_SOFT or PANEL3
        b.TextColor3 = on and WHITE or MUTED
    end
    b.MouseButton1Click:Connect(function()
        setter(not getter())
        refresh()
    end)
    refresh()
    return b, refresh
end

local espToggle, refreshESP = toggleButton(ESPPage, "MASTER ESP", 55,
    function() return ESP_ENABLED end,
    function(v)
        ESP_ENABLED = v
        if not v then removeAllESP() else
            for _, p in ipairs(Players:GetPlayers()) do updatePlayerESP(p) end
            scanBots()
        end
    end)

local botToggle, refreshBots = toggleButton(ESPPage, "BOT ESP", 102,
    function() return BOTS_ENABLED end,
    function(v)
        BOTS_ENABLED = v
        if not v then
            for c, d in pairs(activeESP) do
                if d.kind == "BOT" then destroyOldESP(c) end
            end
        else scanBots() end
    end)

local allBtn = button(ESPPage, "   SELECT ALL PLAYERS", UDim2.fromOffset(22, 149), UDim2.new(.48, -28, 0, 40))
allBtn.BackgroundColor3 = RED_DARK
local clearBtn = button(ESPPage, "   CLEAR ALL", UDim2.new(.52, 0, 0, 149), UDim2.new(.48, -28, 0, 40))
allBtn.Parent = ESPPage
clearBtn.Parent = ESPPage

local selectedLabel = Instance.new("TextLabel")
selectedLabel.BackgroundTransparency = 1
selectedLabel.Position = UDim2.fromOffset(22, 198)
selectedLabel.Size = UDim2.new(1, -44, 0, 24)
selectedLabel.Text = "PLAYER SELECTION"
selectedLabel.TextColor3 = MUTED
selectedLabel.TextSize = 11
selectedLabel.Font = Enum.Font.GothamBold
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = ESPPage

local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Position = UDim2.fromOffset(22, 226)
PlayerList.Size = UDim2.new(1, -44, 0, 190)
PlayerList.BackgroundColor3 = Color3.fromRGB(13, 14, 18)
PlayerList.BorderSizePixel = 0
PlayerList.ScrollBarThickness = 4
PlayerList.ScrollBarImageColor3 = RED
PlayerList.Parent = ESPPage

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 9)
listCorner.Parent = PlayerList

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Parent = PlayerList

local listPad = Instance.new("UIPadding")
listPad.PaddingTop = UDim.new(0, 7)
listPad.PaddingBottom = UDim.new(0, 7)
listPad.PaddingLeft = UDim.new(0, 7)
listPad.PaddingRight = UDim.new(0, 7)
listPad.Parent = PlayerList

local function refreshPlayerList()
    for _, c in ipairs(PlayerList:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p) end
    end
    table.sort(list, function(a,b) return a.Name:lower() < b.Name:lower() end)

    for _, p in ipairs(list) do
        if selectedPlayers[p.UserId] == nil then selectedPlayers[p.UserId] = false end
        local b = button(PlayerList,
            "  " .. p.DisplayName .. "  [" .. p.Name .. "]     " ..
            (selectedPlayers[p.UserId] and "ESP ON" or "ESP OFF"),
            UDim2.new(), UDim2.new(1, 0, 0, 32))
        b.BackgroundColor3 = selectedPlayers[p.UserId] and RED_SOFT or PANEL3
        b.TextColor3 = selectedPlayers[p.UserId] and RED or WHITE
        b.Parent = PlayerList

        b.MouseButton1Click:Connect(function()
            selectedPlayers[p.UserId] = not selectedPlayers[p.UserId]
            updatePlayerESP(p)
            if not selectedPlayers[p.UserId] and lockedPlayer == p then
                lockActive = false
            end
            refreshPlayerList()
        end)
    end

    task.defer(function()
        PlayerList.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 14)
    end)
end

allBtn.MouseButton1Click:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            selectedPlayers[p.UserId] = true
            updatePlayerESP(p)
        end
    end
    refreshPlayerList()
end)

clearBtn.MouseButton1Click:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            selectedPlayers[p.UserId] = false
            updatePlayerESP(p)
        end
    end
    lockedPlayer = nil
    lockActive = false
    refreshPlayerList()
end)

refreshPlayerList()

--==================================================
-- LOCK CONTROLS
--==================================================

local lockToggle, refreshLock = toggleButton(LockPage, "MASTER LOCK", 55,
    function() return LOCK_ENABLED end,
    function(v)
        LOCK_ENABLED = v
        if not v then lockActive = false end
    end)

local function slider(parent, y, titleText, minV, maxV, initial, callback)
    local holder = Instance.new("Frame")
    holder.Position = UDim2.fromOffset(22, y)
    holder.Size = UDim2.new(1, -44, 0, 66)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local lab = Instance.new("TextLabel")
    lab.BackgroundTransparency = 1
    lab.Size = UDim2.new(1, 0, 0, 24)
    lab.TextColor3 = WHITE
    lab.TextSize = 12
    lab.Font = Enum.Font.GothamMedium
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.Parent = holder

    local bar = Instance.new("Frame")
    bar.Position = UDim2.fromOffset(0, 34)
    bar.Size = UDim2.new(1, 0, 0, 7)
    bar.BackgroundColor3 = PANEL3
    bar.BorderSizePixel = 0
    bar.Parent = holder
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1,0); bc.Parent = bar

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = RED
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1,0); fc.Parent = fill

    local dragging = false
    local function set(v)
        v = math.clamp(v, minV, maxV)
        local pct = (v-minV)/(maxV-minV)
        fill.Size = UDim2.new(pct,0,1,0)
        lab.Text = titleText .. "   " .. math.floor(v)
        callback(v)
    end
    local function mouse(x)
        local pct = math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        set(minV+(maxV-minV)*pct)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging=true; mouse(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then mouse(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    set(initial)
end

slider(LockPage, 102, "FOV", 20, 500, LOCK_FOV, function(v) LOCK_FOV=v end)
slider(LockPage, 170, "LOCK STRENGTH", 1, 30, LOCK_STRENGTH, function(v) LOCK_STRENGTH=v end)
slider(LockPage, 238, "MAX DISTANCE", 50, 2000, LOCK_MAX_DISTANCE, function(v) LOCK_MAX_DISTANCE=v end)

local function option(parent, y, titleText, get, set)
    local b = button(parent, "", UDim2.fromOffset(22,y), UDim2.new(1,-44,0,40))
    local function refresh()
        b.Text = "   " .. titleText .. "                         " .. tostring(get())
        b.BackgroundColor3 = PANEL3
    end
    b.MouseButton1Click:Connect(function() set(); refresh() end)
    refresh()
    return b
end

option(LockPage, 306, "TARGET PART", function() return LOCK_TARGET_PART end, function()
    LOCK_TARGET_PART = LOCK_TARGET_PART == "Head" and "HumanoidRootPart" or "Head"
end)

option(LockPage, 353, "VISIBLE CHECK", function() return LOCK_VISIBLE_CHECK and "ON" or "OFF" end, function()
    LOCK_VISIBLE_CHECK = not LOCK_VISIBLE_CHECK
end)

option(LockPage, 400, "TEAM CHECK", function() return LOCK_TEAM_CHECK and "ON" or "OFF" end, function()
    LOCK_TEAM_CHECK = not LOCK_TEAM_CHECK
end)

local keyBtn = button(LockPage, "", UDim2.fromOffset(22, 447), UDim2.new(1,-44,0,40))
local function keyName() return LOCK_KEY.Name end
local function refreshKey()
    keyBtn.Text = "   LOCK KEY                         " .. (waitingForKey and "PRESS A KEY..." or keyName())
end
keyBtn.MouseButton1Click:Connect(function()
    waitingForKey=true
    refreshKey()
end)
refreshKey()

local targetLabel = Instance.new("TextLabel")
targetLabel.BackgroundTransparency = 1
targetLabel.Position = UDim2.fromOffset(22, 496)
targetLabel.Size = UDim2.new(1,-44,0,25)
targetLabel.Text = "LOCK TARGET  •  select a player in ESP tab"
targetLabel.TextColor3 = MUTED
targetLabel.TextSize = 11
targetLabel.Font = Enum.Font.GothamMedium
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = LockPage

--==================================================
-- FOV
--==================================================

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "LOCK_FOV"
FOVCircle.AnchorPoint = Vector2.new(.5,.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Visible = false
FOVCircle.Parent = ScreenGui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1,0)
fovCorner.Parent = FOVCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = RED
fovStroke.Thickness = 2
fovStroke.Transparency = .1
fovStroke.Parent = FOVCircle

--==================================================
-- LOCK LOGIC
--==================================================

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function visible(character, pos)
    if not LOCK_VISIBLE_CHECK then return true end
    local cam = workspace.CurrentCamera
    if not cam then return false end

    local filter = {}
    if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
    rayParams.FilterDescendantsInstances = filter

    local result = workspace:Raycast(cam.CFrame.Position, pos-cam.CFrame.Position, rayParams)
    return not result or result.Instance:IsDescendantOf(character)
end

local function enemy(p)
    if not LOCK_TEAM_CHECK then return true end
    if not LocalPlayer.Team or not p.Team then return true end
    return LocalPlayer.Team ~= p.Team
end

local function validLockTarget(p)
    if not p or p == LocalPlayer then return false end
    if not p.Character or not alive(p.Character) then return false end
    if not enemy(p) then return false end
    if not selectedPlayers[p.UserId] then return false end

    local part = targetPartOf(p.Character)
    local myRoot = rootOf(LocalPlayer.Character)
    if not part or not myRoot then return false end

    local dist = (part.Position-myRoot.Position).Magnitude
    if dist > LOCK_MAX_DISTANCE then return false end

    local cam = workspace.CurrentCamera
    if not cam then return false end
    local point, onScreen = cam:WorldToViewportPoint(part.Position)
    if not onScreen or point.Z <= 0 then return false end

    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    local d = (Vector2.new(point.X,point.Y)-center).Magnitude
    if d > LOCK_FOV then return false end

    if not visible(p.Character, part.Position) then return false end
    return true, part
end

local function applyLock(part, dt)
    local cam = workspace.CurrentCamera
    if not cam or not part then return end
    local desired = CFrame.lookAt(cam.CFrame.Position, part.Position)
    local alpha = 1-math.exp(-LOCK_STRENGTH*dt)
    alpha = math.clamp(alpha, .01, 1)
    cam.CFrame = cam.CFrame:Lerp(desired, alpha)
end

--==================================================
-- TABS
--==================================================

local function showESP()
    ESPPage.Visible = true
    LockPage.Visible = false
    ESPTab.BackgroundColor3 = RED_SOFT
    ESPTab.TextColor3 = WHITE
    LockTab.BackgroundColor3 = PANEL3
    LockTab.TextColor3 = MUTED
end

local function showLock()
    ESPPage.Visible = false
    LockPage.Visible = true
    LockTab.BackgroundColor3 = RED_SOFT
    LockTab.TextColor3 = WHITE
    ESPTab.BackgroundColor3 = PANEL3
    ESPTab.TextColor3 = MUTED
end

ESPTab.MouseButton1Click:Connect(showESP)
LockTab.MouseButton1Click:Connect(showLock)
showESP()

--==================================================
-- DRAG
--==================================================

local dragging, dragStart, startPos = false, nil, nil
Top.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=i.Position; startPos=Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d=i.Position-dragStart
        Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)

--==================================================
-- MINIMIZE / CLOSE
--==================================================

local minimized=false
Min.MouseButton1Click:Connect(function()
    minimized=not minimized
    Side.Visible=not minimized
    ESPPage.Visible=not minimized and not LockPage.Visible
    LockPage.Visible=not minimized and LockPage.Visible
    Main.Size=minimized and UDim2.fromOffset(760,58) or UDim2.fromOffset(760,500)
    Min.Text=minimized and "+" or "—"
end)

Close.MouseButton1Click:Connect(function()
    running=false
    lockActive=false
    removeAllESP()
    pcall(function() RunService:UnbindFromRenderStep("FTAP_LOCK") end)
    UserInputService.MouseBehavior=Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled=true
    ScreenGui:Destroy()
end)

--==================================================
-- INPUT
--==================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not running then return end

    if waitingForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard
            and input.KeyCode ~= Enum.KeyCode.Unknown then
            LOCK_KEY=input.KeyCode
            waitingForKey=false
            refreshKey()
            return
        end
    end

    if input.KeyCode == Enum.KeyCode.RightShift then
        ScreenGui.Enabled=not ScreenGui.Enabled
        UserInputService.MouseBehavior=Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled=true
        return
    end

    if input.KeyCode == Enum.KeyCode.U then
        UserInputService.MouseBehavior=Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled=true
    end

    if gameProcessed then return end

    if LOCK_ENABLED and input.KeyCode == LOCK_KEY then
        if lockedPlayer and lockActive then
            lockActive=false
            lockedPlayer=nil
        else
            -- Lock only to the player explicitly selected in ESP.
            local chosen=nil
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and selectedPlayers[p.UserId] then
                    if validLockTarget(p) then
                        chosen=p
                        break
                    end
                end
            end
            if chosen then
                lockedPlayer=chosen
                lockActive=true
            end
        end
    end
end)

--==================================================
-- PLAYER EVENTS
--==================================================

Players.PlayerAdded:Connect(function(p)
    if p==LocalPlayer then return end
    selectedPlayers[p.UserId]=false
    p.CharacterAdded:Connect(function()
        task.wait(.4)
        updatePlayerESP(p)
    end)
    refreshPlayerList()
end)

Players.PlayerRemoving:Connect(function(p)
    selectedPlayers[p.UserId]=nil
    if lockedPlayer==p then
        lockedPlayer=nil
        lockActive=false
    end
    if p.Character then destroyOldESP(p.Character) end
    refreshPlayerList()
end)

for _,p in ipairs(Players:GetPlayers()) do
    if p~=LocalPlayer then
        p.CharacterAdded:Connect(function()
            task.wait(.4)
            updatePlayerESP(p)
        end)
    end
end

--==================================================
-- RENDER
--==================================================

local botTimer=0
RunService:BindToRenderStep("FTAP_LOCK", Enum.RenderPriority.Camera.Value+1, function(dt)
    if not running then return end

    local cam=workspace.CurrentCamera
    if cam then
        FOVCircle.Position=UDim2.fromOffset(cam.ViewportSize.X/2,cam.ViewportSize.Y/2)
        FOVCircle.Size=UDim2.fromOffset(LOCK_FOV*2,LOCK_FOV*2)
        FOVCircle.Visible=LOCK_ENABLED
    end

    if LOCK_ENABLED and lockActive and lockedPlayer then
        local ok,part=validLockTarget(lockedPlayer)
        if ok and part then
            applyLock(part,dt)
        else
            -- The lock stays assigned to the chosen player, but pauses
            -- while the target is outside FOV, dead, too far away, or hidden.
        end
    end

    if ESP_ENABLED then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer then
                local c=p.Character
                if c then
                    local d=activeESP[c]
                    if selectedPlayers[p.UserId] then
                        if not d or d.kind~="PLAYER" then updatePlayerESP(p) end
                    elseif d and d.kind=="PLAYER" then
                        destroyOldESP(c)
                    end
                end
            end
        end

        botTimer=botTimer+dt
        if botTimer>=1 then
            botTimer=0
            scanBots()
        end
    end
end)

-- Clean old ESP objects from previous executions.
for _,obj in ipairs(workspace:GetDescendants()) do
    if (obj:IsA("Highlight") and obj.Name=="FTAP_ESP_Highlight")
        or (obj:IsA("BillboardGui") and obj.Name=="FTAP_ESP_Name") then
        obj:Destroy()
    end
end

print("FTAP Control Center loaded")
print("LOCK KEY:", LOCK_KEY.Name)
print("RightShift = Menu")
print("U = Unlock Mouse")
