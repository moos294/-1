local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if not Remotes then return end
local TrainEvent = Remotes:WaitForChild("TrainEvent", 10)
if not TrainEvent then return end

local function tryGet(parent, name)
    if not parent then return nil end
    return parent:FindFirstChild(name)
end

local RebirthEvent = tryGet(Remotes, "RebirthEvent") or tryGet(Remotes, "Rebirth")

local Config = {
    TRAIN_ACTION        = "PushUp",
    INTERVAL            = 0.1,
    AUTO_START          = false,
    AUTO_REBIRTH        = false,
    AUTO_REBIRTH_DELAY  = 3,
    ANTI_AFK            = true,
    AUTO_RESET          = false,
    AUTO_RESET_INTERVAL = 300,
    SAVE_SETTINGS       = true,
    NOTIFICATION        = true,
    MINIMIZE_ON_START   = false,
}

local ActionList = { "PushUp", "SitUp", "PullUp", "Squat" }

local isTraining, trainThread = false, nil
local trainCount, totalCount = 0, 0
local startTime, startTimeTotal = 0, tick()
local isMinimized = false

local CONFIG_FILE = "CrownStrength_config.json"

local function saveConfig()
    if not Config.SAVE_SETTINGS or not writefile then return end
    pcall(function()
        local data = {}
        for k, v in pairs(Config) do
            if type(v) ~= "table" and type(v) ~= "function" then data[k] = v end
        end
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
end

local function loadConfig()
    if not Config.SAVE_SETTINGS or not (isfile and readfile) then return end
    if not isfile(CONFIG_FILE) then return end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if ok and type(data) == "table" then
        for k, v in pairs(data) do
            if Config[k] ~= nil and type(Config[k]) == type(v) then Config[k] = v end
        end
    end
end

loadConfig()

local function startAutoTrain()
    if isTraining then return end
    isTraining = true
    trainCount = 0
    startTime = tick()
    trainThread = task.spawn(function()
        while isTraining do
            local ok = pcall(function() TrainEvent:FireServer(Config.TRAIN_ACTION) end)
            if ok then
                trainCount = trainCount + 1
                totalCount = totalCount + 1
            end
            task.wait(Config.INTERVAL)
        end
    end)
end

local function stopAutoTrain()
    isTraining = false
    if trainThread then
        task.cancel(trainThread)
        trainThread = nil
    end
end

-- ============================================================
-- THEME
-- ============================================================
local Theme = {
    BG          = Color3.fromRGB(18, 18, 24),
    PANEL       = Color3.fromRGB(26, 26, 34),
    PANEL_ALT   = Color3.fromRGB(32, 32, 42),
    STROKE      = Color3.fromRGB(48, 48, 62),
    TEXT        = Color3.fromRGB(232, 232, 240),
    TEXT_DIM    = Color3.fromRGB(140, 140, 160),
    ACCENT      = Color3.fromRGB(255, 190, 60),
    ACCENT_DARK = Color3.fromRGB(200, 140, 20),
    SUCCESS     = Color3.fromRGB(70, 210, 120),
    DANGER      = Color3.fromRGB(240, 70, 90),
    INFO        = Color3.fromRGB(110, 170, 255),
    PURPLE      = Color3.fromRGB(180, 130, 255),
    FONT        = Enum.Font.Gotham,
    FONT_BOLD   = Enum.Font.GothamBold,
    FONT_MED    = Enum.Font.GothamMedium,
}

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.STROKE
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function padding(parent, p)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, p)
    pad.PaddingBottom = UDim.new(0, p)
    pad.PaddingLeft = UDim.new(0, p)
    pad.PaddingRight = UDim.new(0, p)
    pad.Parent = parent
    return pad
end

local function gradient(parent, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 90
    g.Parent = parent
    return g
end

local function tween(obj, props, dur, style, dir)
    local t = TweenService:Create(obj,
        TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props)
    t:Play()
    return t
end

-- ============================================================
-- ROOT
-- ============================================================
local oldGui = LocalPlayer.PlayerGui:FindFirstChild("CrownStrengthUI")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CrownStrengthUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local W, H = 320, 560

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, W, 0, H)
Main.Position = UDim2.new(0, 30, 0.5, -H/2)
Main.BackgroundColor3 = Theme.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true
Main.Parent = ScreenGui
corner(Main, 14)

local mainStroke = stroke(Main, Theme.STROKE, 1)

local topGlow = Instance.new("Frame")
topGlow.Size = UDim2.new(1, 0, 0, 2)
topGlow.BackgroundColor3 = Theme.ACCENT
topGlow.BorderSizePixel = 0
topGlow.ZIndex = 5
topGlow.Parent = Main
gradient(topGlow, Theme.ACCENT, Theme.PURPLE, 0)

-- ============================================================
-- HEADER
-- ============================================================
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3 = Theme.PANEL
Header.BorderSizePixel = 0
Header.Parent = Main

local HeaderGrad = Instance.new("Frame")
HeaderGrad.Size = UDim2.new(1, 0, 0, 52)
HeaderGrad.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HeaderGrad.BackgroundTransparency = 0.94
HeaderGrad.BorderSizePixel = 0
HeaderGrad.Parent = Header
gradient(HeaderGrad, Theme.ACCENT, Theme.PURPLE, 25)

local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, 0, 0, 1)
HeaderLine.Position = UDim2.new(0, 0, 1, -1)
HeaderLine.BackgroundColor3 = Theme.STROKE
HeaderLine.BorderSizePixel = 0
HeaderLine.Parent = Header

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 26, 0, 26)
Logo.Position = UDim2.new(0, 16, 0.5, -13)
Logo.BackgroundColor3 = Theme.ACCENT
Logo.BorderSizePixel = 0
Logo.Parent = Header
corner(Logo, 8)
gradient(Logo, Theme.ACCENT, Theme.ACCENT_DARK, 90)

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "C"
LogoText.TextColor3 = Color3.fromRGB(30, 20, 0)
LogoText.Font = Theme.FONT_BOLD
LogoText.TextSize = 15
LogoText.Parent = Logo

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -120, 0, 18)
TitleLbl.Position = UDim2.new(0, 52, 0, 10)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "CROWN OF STRENGTH"
TitleLbl.TextColor3 = Theme.TEXT
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Font = Theme.FONT_BOLD
TitleLbl.TextSize = 13
TitleLbl.Parent = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -120, 0, 14)
SubTitle.Position = UDim2.new(0, 52, 0, 26)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Auto Trainer"
SubTitle.TextColor3 = Theme.TEXT_DIM
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Font = Theme.FONT
SubTitle.TextSize = 10
SubTitle.Parent = Header

-- Header buttons
local function headerButton(text, color, xOffset)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 26, 0, 26)
    b.Position = UDim2.new(1, xOffset, 0.5, -13)
    b.BackgroundColor3 = color
    b.BackgroundTransparency = 0.5
    b.Text = text
    b.TextColor3 = Theme.TEXT
    b.Font = Theme.FONT_BOLD
    b.TextSize = 14
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.Parent = Header
    corner(b, 6)

    b.MouseEnter:Connect(function()
        tween(b, {BackgroundTransparency = 0.2}, 0.15)
    end)
    b.MouseLeave:Connect(function()
        tween(b, {BackgroundTransparency = 0.5}, 0.15)
    end)
    return b
end

local CloseBtn = headerButton("x", Theme.DANGER, -38)
local MinBtn   = headerButton("-", Theme.PANEL_ALT, -70)

CloseBtn.MouseButton1Click:Connect(function()
    stopAutoTrain()
    saveConfig()
    tween(Main, {Size = UDim2.new(0, W, 0, 0), BackgroundTransparency = 1}, 0.25)
    task.wait(0.28)
    ScreenGui:Destroy()
end)

-- ============================================================
-- CONTENT
-- ============================================================
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, 0, 1, -52 - 62)
Content.Position = UDim2.new(0, 0, 0, 52)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Theme.STROKE
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Main

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 10)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

padding(Content, 14)

-- Section title helper
local function sectionTitle(text)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 16)
    row.BackgroundTransparency = 1
    row.LayoutOrder = 0
    row.Parent = Content

    local lbl =