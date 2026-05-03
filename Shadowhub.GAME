-- ══════════════════════════════════════════
--        🎮 GAME CONFIG
-- ══════════════════════════════════════════

local games = {
    [16457183958] = {
        name = "Gojo vs Toji",
        script = "https://raw.githubusercontent.com/ShadowDRAGONZ/Gojo-vs-toji-game/refs/heads/main/GojovsToji.Game"
    },

    [11334800850] = {
        name = "Chainsawman Testing",
        script = "https://raw.githubusercontent.com/ShadowDRAGONZ/Menu-load/refs/heads/main/chainsawmantestingplace.FARM"
    }
}

local placeId = game.PlaceId
local gameData = games[placeId]

-- ❌ Không hỗ trợ
if not gameData then
    game.Players.LocalPlayer:Kick("❌ Game này không được hỗ trợ!")
    return
end

-- ══════════════════════════════════════════
--        ⚙️ SERVICES
-- ══════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════
--        🌑 UI LOADING
-- ══════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShadowHub_Loading"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Background
local bg = Instance.new("Frame")
bg.Size = UDim2.new(1,0,1,0)
bg.BackgroundColor3 = Color3.fromRGB(8,8,15)
bg.BorderSizePixel = 0
bg.Parent = screenGui

-- Card
local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5,0.5)
card.Position = UDim2.new(0.5,0,0.5,0)
card.Size = UDim2.new(0,360,0,260)
card.BackgroundColor3 = Color3.fromRGB(15,15,30)
card.Parent = bg

Instance.new("UICorner", card).CornerRadius = UDim.new(0,16)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,40)
title.Position = UDim2.new(0,0,0,20)
title.BackgroundTransparency = 1
title.Text = "SHADOW HUB"
title.Font = Enum.Font.GothamBold
title.TextSize = 26
title.TextColor3 = Color3.fromRGB(200,150,255)
title.Parent = card

-- Game name (auto)
local gameLabel = Instance.new("TextLabel")
gameLabel.Size = UDim2.new(1,0,0,25)
gameLabel.Position = UDim2.new(0,0,0,60)
gameLabel.BackgroundTransparency = 1
gameLabel.Text = gameData.name
gameLabel.Font = Enum.Font.Gotham
gameLabel.TextSize = 16
gameLabel.TextColor3 = Color3.fromRGB(160,120,255)
gameLabel.Parent = card

-- Progress bar bg
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(0.8,0,0,8)
barBg.Position = UDim2.new(0.1,0,0,120)
barBg.BackgroundColor3 = Color3.fromRGB(40,20,70)
barBg.Parent = card
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)

-- Fill
local bar = Instance.new("Frame")
bar.Size = UDim2.new(0,0,1,0)
bar.BackgroundColor3 = Color3.fromRGB(150,80,255)
bar.Parent = barBg
Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

-- Status
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,0,0,20)
status.Position = UDim2.new(0,0,0,140)
status.BackgroundTransparency = 1
status.Text = "Initializing..."
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(180,150,255)
status.Parent = card

-- Percent
local percent = Instance.new("TextLabel")
percent.Size = UDim2.new(1,0,0,30)
percent.Position = UDim2.new(0,0,0,165)
percent.BackgroundTransparency = 1
percent.Text = "0%"
percent.Font = Enum.Font.GothamBold
percent.TextSize = 20
percent.TextColor3 = Color3.fromRGB(220,180,255)
percent.Parent = card

-- ══════════════════════════════════════════
--        ⚡ LOADING LOGIC
-- ══════════════════════════════════════════

local steps = {
    {text="Checking game...", pct=20},
    {text="Loading modules...", pct=50},
    {text="Preparing script...", pct=80},
    {text="Launching...", pct=100},
}

task.spawn(function()
    local last = 0
    for _,step in ipairs(steps) do
        status.Text = step.text
        
        TweenService:Create(bar, TweenInfo.new(0.6), {
            Size = UDim2.new(step.pct/100,0,1,0)
        }):Play()

        for i = last, step.pct do
            percent.Text = i.."%"
            task.wait(0.01)
        end

        last = step.pct
        task.wait(0.3)
    end
end)

-- ══════════════════════════════════════════
--        🚀 LOAD SCRIPT
-- ══════════════════════════════════════════

task.delay(3, function()
    pcall(function()
        loadstring(game:HttpGet(gameData.script))()
    end)

    -- fade out
    TweenService:Create(bg, TweenInfo.new(0.5), {
        BackgroundTransparency = 1
    }):Play()

    task.wait(0.5)
    screenGui:Destroy()
end)