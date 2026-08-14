--[[
     _      ___         ____  ______
    | | /| / (_)__  ___/ / / / /  _/
    | |/ |/ / / _ \/ _  / /_/ // /
    |__/|__/_/_//_/\_,_/\____/___/

    WindUI Anime Frost Visual Overhaul
    Target: WindUI v1.6.65

    Chỉ chỉnh sửa:
    - Theme / màu sắc
    - Hình nền URL
    - Glassmorphism / animated sheen
    - Hover / click animation
    - Glow / UIStroke / shadow
    - Snow particle
    - Lighting tùy chọn

    Không chỉnh sửa logic tạo Window, Button, Dropdown hoặc callback WindUI.
]]

local AnimeFrost = {}

AnimeFrost.VERSION = "2.0.0"
AnimeFrost.TARGET = "WindUI 1.6.65"
AnimeFrost.PACK_NAME = "animefrost"

--// ============================================================================
--// SERVICES
--// ============================================================================

local safeCloneref = cloneref
    or clonereference
    or function(service)
        return service
    end

local TweenService = safeCloneref(game:GetService("TweenService"))
local RunService = safeCloneref(game:GetService("RunService"))
local Lighting = safeCloneref(game:GetService("Lighting"))
local HttpService = safeCloneref(game:GetService("HttpService"))

--// ============================================================================
--// PALETTE — ANIME FROST
--// ============================================================================

local PALETTE = {
    VoidBlack = Color3.fromHex("#030610"),
    AbyssNavy = Color3.fromHex("#02040D"),
    DeepNavy = Color3.fromHex("#071225"),
    SteelNavy = Color3.fromHex("#0C1C35"),
    SlateNavy = Color3.fromHex("#102746"),
    SoftNavy = Color3.fromHex("#15345A"),

    RoyalBlue = Color3.fromHex("#2458F5"),
    ElectricBlue = Color3.fromHex("#527FFF"),
    AzureCore = Color3.fromHex("#2D9CFF"),
    IceGlow = Color3.fromHex("#4ADFFF"),
    CyanGlow = Color3.fromHex("#84ECFF"),
    SkyIcon = Color3.fromHex("#8CCBFF"),

    FrostWhite = Color3.fromHex("#EAF6FF"),
    SnowWhite = Color3.fromHex("#F6FBFF"),
    LineWhite = Color3.fromHex("#DCEEFF"),
    Silver = Color3.fromHex("#BED0E2"),
    MutedSteel = Color3.fromHex("#8FAAC8"),

    InkBlack = Color3.fromHex("#06121F"),
    SoftPurple = Color3.fromHex("#9C8CFF"),
}

AnimeFrost.Palette = PALETTE

--// ============================================================================
--// CONFIG
--// ============================================================================

local CONFIG = {
    DefaultTheme = "ColdBlue",

    Shapes = {},
    Icons = {},

    Background = {
        Enabled = true,
        URL = "https://raw.githubusercontent.com/ShadowDRAGONZ/Menu-load/refs/heads/main/3e7d921b6d65833efed723515659a2a7.jpg",
        FallbackAssetId = "rbxassetid://82801764111482",
        FilePath = "WindUI/AnimeFrost/assets/anime_frost_background.jpg",
        ImageTransparency = 0.12,
        DarkOverlayTransparency = 0.28,
        BlueOverlayTransparency = 0.86,
        ParallaxEnabled = true,
        ParallaxDuration = 14,
    },

    GlassSheen = {
        Enabled = true,
        Rotation = 35,
        Intensity = 0.42,
        MovementSpeed = 0.20,
        MovementAmount = 0.48,
        RotationAmount = 8,
    },

    Interaction = {
        Enabled = true,
        HoverScale = 1.018,
        PressScale = 0.965,
        HoverDuration = 0.18,
        PressDuration = 0.09,
        HoverBrightnessTransparency = 0.935,
        StrokeTransparency = 0.74,
    },

    Glow = {
        Enabled = true,
        Color = PALETTE.IceGlow,
        SecondaryColor = PALETTE.ElectricBlue,
        Thickness = 1.15,
        MaxThickness = 2.0,
        Transparency = 0.45,
        MaxTransparency = 0.80,
        Duration = 3.8,
    },

    Particles = {
        Enabled = true,
        Count = 20,
        ParticlesPerSecond = 8,
        MaxParticles = 42,
        InitialParticles = 18,
        RespawnDelayMin = 0.05,
        RespawnDelayMax = 0.55,
        MinSize = 8,
        MaxSize = 21,
        MinDuration = 7,
        MaxDuration = 14,
        MinTransparency = 0.20,
        MaxTransparency = 0.68,
    },

    Loading = {
        Enabled = true,
        Duration = 1.05,
        FadeDuration = 0.32,
        RingSize = 78,
        DefaultTitle = "ANIME FROST",
        ShowAuthor = true,
    },

    PanelGlass = {
        Enabled = true,
        SidebarTransparency = 0.58,
        MainTransparency = 0.58,
        BorderTransparency = 0.50,
    },

    Lighting = {
        Enabled = false,
        GlobalShadows = true,
        Tint = Color3.fromRGB(216, 235, 255),
        Saturation = -0.08,
        Contrast = 0.13,
        BloomIntensity = 0.30,
        BloomSize = 18,
        BloomThreshold = 1.1,
    },
}

AnimeFrost.Config = CONFIG

--// ============================================================================
--// INTERNAL STATE / CLEANUP
--// ============================================================================

local createdInstances = {}
local activeTweens = {}
local connections = {}
local animatedGradients = setmetatable({}, { __mode = "k" })
local decoratedObjects = setmetatable({}, { __mode = "k" })
local propertyBackups = setmetatable({}, { __mode = "k" })

local gradientRunner = nil
local savedLighting = nil
local createdLightingEffects = {}

local shapeHooked = false
local originalNewRoundFrame = nil

local function trackInstance(instance)
    if typeof(instance) == "Instance" then
        table.insert(createdInstances, instance)
    end
    return instance
end

local function trackConnection(connection)
    if connection then
        table.insert(connections, connection)
    end
    return connection
end

local function trackTween(tween)
    if tween then
        table.insert(activeTweens, tween)
    end
    return tween
end

local function tween(object, duration, properties, style, direction)
    if typeof(object) ~= "Instance" or not object.Parent or type(properties) ~= "table" then
        return nil
    end

    local ok, result = pcall(function()
        return TweenService:Create(
            object,
            TweenInfo.new(
                math.max(tonumber(duration) or 0, 0),
                style or Enum.EasingStyle.Quint,
                direction or Enum.EasingDirection.Out
            ),
            properties
        )
    end)

    if not ok or not result then
        return nil
    end

    trackTween(result)
    pcall(function()
        result:Play()
    end)
    return result
end

local function deepMerge(target, source)
    if type(source) ~= "table" then
        return target
    end

    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then
            deepMerge(target[key], value)
        else
            target[key] = value
        end
    end

    return target
end

local function backupProperty(object, property)
    if not object or object[property] == nil then
        return
    end

    propertyBackups[object] = propertyBackups[object] or {}

    if propertyBackups[object][property] == nil then
        propertyBackups[object][property] = object[property]
    end
end

--// ============================================================================
--// THEME SYSTEM
--// ============================================================================

local function buildThemes(WindUI)
    local function gradient(colorA, colorB, rotation)
        return WindUI:Gradient({
            ["0"] = { Color = colorA, Transparency = 0 },
            ["100"] = { Color = colorB, Transparency = 0 },
        }, { Rotation = rotation or 90 })
    end

    local themes = {}

    themes.ColdBlue = {
        Name = "ColdBlue",
        Accent = gradient(Color3.fromHex("#08152B"), Color3.fromHex("#102C53"), 115),
        Dialog = gradient(Color3.fromHex("#09182E"), Color3.fromHex("#102C4D"), 90),
        Background = gradient(PALETTE.AbyssNavy, Color3.fromHex("#08162C"), 90),
        WindowBackground = Color3.fromHex("#06101F"),
        WindowShadow = PALETTE.IceGlow,
        Outline = PALETTE.LineWhite,
        Text = PALETTE.FrostWhite,
        Placeholder = PALETTE.MutedSteel,
        Button = gradient(Color3.fromHex("#2457E6"), Color3.fromHex("#37B8FF"), 45),
        Icon = PALETTE.SkyIcon,
        Primary = PALETTE.AzureCore,
        Toggle = PALETTE.IceGlow,
        Slider = PALETTE.AzureCore,
        Checkbox = PALETTE.AzureCore,
        SliderIcon = PALETTE.Silver,
        PanelBackground = Color3.fromHex("#A4D8FF"),
        PanelBackgroundTransparency = 0.91,
        LabelBackground = Color3.fromHex("#071528"),
        LabelBackgroundTransparency = 0.30,
        ElementBackground = Color3.fromHex("#102A49"),
        ElementBackgroundTransparency = 0.18,
        DropdownBackground = Color3.fromHex("#08172B"),
        DropdownTabBackground = Color3.fromHex("#173657"),
        PopupBackground = Color3.fromHex("#08182D"),
        PopupBackgroundTransparency = 0.08,
        DialogBackground = Color3.fromHex("#091A31"),
        DialogBackgroundTransparency = 0.06,
        Tooltip = Color3.fromHex("#102C4A"),
        TooltipText = PALETTE.FrostWhite,
        Notification = Color3.fromHex("#07172B"),
        Notification2 = PALETTE.IceGlow,
        Notification2Transparency = 0.91,
        TabBackground = PALETTE.IceGlow,
        TabBackgroundHover = PALETTE.CyanGlow,
        TabBackgroundHoverTransparency = 0.93,
        TabBackgroundActive = PALETTE.AzureCore,
        TabBackgroundActiveTransparency = 0.82,
        TabBorder = PALETTE.LineWhite,
        TabBorderTransparency = 1,
        TabBorderTransparencyActive = 0.64,
        SectionBoxBackground = Color3.fromHex("#112D4C"),
        SectionBoxBackgroundTransparency = 0.22,
        SectionBoxBorder = PALETTE.IceGlow,
        SectionBoxBorderTransparency = 0.72,
        SearchBarBorder = PALETTE.IceGlow,
        SearchBarBorderTransparency = 0.72,
        DropdownTabBorder = PALETTE.IceGlow,
        CheckboxBorder = PALETTE.LineWhite,
        CheckboxBorderTransparency = 0.65,
    }

    themes.MidnightAesthetic = {
        Name = "MidnightAesthetic",
        Accent = gradient(Color3.fromHex("#070D20"), Color3.fromHex("#141D48"), 90),
        Dialog = gradient(Color3.fromHex("#0B1230"), Color3.fromHex("#18184A"), 135),
        Background = gradient(Color3.fromHex("#01030A"), Color3.fromHex("#0A1030"), 90),
        WindowBackground = Color3.fromHex("#040713"),
        WindowShadow = PALETTE.SoftPurple,
        Outline = Color3.fromHex("#DDE6FF"),
        Text = Color3.fromHex("#E9ECFF"),
        Placeholder = Color3.fromHex("#8294CA"),
        Button = gradient(Color3.fromHex("#3D47C8"), Color3.fromHex("#5E8BFF"), 45),
        Icon = Color3.fromHex("#8DB7FF"),
        Primary = PALETTE.ElectricBlue,
        Toggle = Color3.fromHex("#52D8FF"),
        Slider = PALETTE.ElectricBlue,
        Checkbox = PALETTE.ElectricBlue,
        SliderIcon = Color3.fromHex("#AAB8E6"),
        PanelBackground = Color3.fromHex("#9BAAFF"),
        PanelBackgroundTransparency = 0.94,
        LabelBackground = Color3.fromHex("#090E25"),
        LabelBackgroundTransparency = 0.27,
        ElementBackground = Color3.fromHex("#131C3C"),
        ElementBackgroundTransparency = 0.14,
        DropdownBackground = Color3.fromHex("#090F27"),
        DropdownTabBackground = Color3.fromHex("#1B2851"),
        Tooltip = Color3.fromHex("#151D47"),
        TooltipText = Color3.fromHex("#EFF2FF"),
        TabBackground = PALETTE.SoftPurple,
        TabBackgroundHover = Color3.fromHex("#B0A8FF"),
        TabBackgroundHoverTransparency = 0.93,
        TabBackgroundActive = PALETTE.ElectricBlue,
        TabBackgroundActiveTransparency = 0.82,
        Notification = Color3.fromHex("#090E25"),
        Notification2 = PALETTE.SoftPurple,
        Notification2Transparency = 0.92,
    }

    themes.FrostLight = {
        Name = "FrostLight",
        Accent = gradient(Color3.fromHex("#D9EDFF"), Color3.fromHex("#F4FAFF"), 90),
        Dialog = Color3.fromHex("#EDF6FF"),
        Background = Color3.fromHex("#F7FBFF"),
        WindowBackground = Color3.fromHex("#F4FAFF"),
        WindowShadow = Color3.fromHex("#69BFFF"),
        Outline = Color3.fromHex("#FFFFFF"),
        Text = PALETTE.InkBlack,
        Placeholder = Color3.fromHex("#60758B"),
        Button = gradient(Color3.fromHex("#1678E8"), Color3.fromHex("#35BCE9"), 45),
        Icon = Color3.fromHex("#246FAE"),
        Primary = Color3.fromHex("#208CFF"),
        Toggle = Color3.fromHex("#14B9D6"),
        Slider = Color3.fromHex("#208CFF"),
        Checkbox = Color3.fromHex("#208CFF"),
        SliderIcon = Color3.fromHex("#5A7897"),
        PanelBackground = Color3.fromHex("#E2F2FF"),
        PanelBackgroundTransparency = 0.10,
        LabelBackground = Color3.fromHex("#F3F9FF"),
        LabelBackgroundTransparency = 0.04,
        ElementBackground = Color3.fromHex("#FFFFFF"),
        ElementBackgroundTransparency = 0.05,
        DropdownBackground = Color3.fromHex("#F7FBFF"),
        DropdownTabBackground = Color3.fromHex("#DCEFFF"),
        TabBackground = Color3.fromHex("#D3EAFF"),
        TabBackgroundHover = Color3.fromHex("#C4E5FF"),
        TabBackgroundHoverTransparency = 0.12,
        TabBackgroundActive = Color3.fromHex("#A9D9FF"),
        TabBackgroundActiveTransparency = 0.08,
        Tooltip = Color3.fromHex("#D9EEFF"),
        TooltipText = PALETTE.InkBlack,
        Notification = Color3.fromHex("#F1F8FF"),
        Notification2 = Color3.fromHex("#2999FF"),
        Notification2Transparency = 0.82,
    }

    local function alias(sourceName, newName, patch)
        local clone = {}
        for key, value in pairs(themes[sourceName]) do
            clone[key] = value
        end
        clone.Name = newName
        if patch then
            for key, value in pairs(patch) do
                clone[key] = value
            end
        end
        themes[newName] = clone
    end

    alias("ColdBlue", "Dark")
    alias("MidnightAesthetic", "Midnight")
    alias("FrostLight", "Light")

    alias("ColdBlue", "Sky", {
        Accent = gradient(Color3.fromHex("#06212E"), Color3.fromHex("#0A4155"), 90),
        Dialog = Color3.fromHex("#082A3C"),
        Primary = PALETTE.IceGlow,
        Slider = PALETTE.IceGlow,
        Checkbox = PALETTE.IceGlow,
        Icon = Color3.fromHex("#6EE8FF"),
        ElementBackground = Color3.fromHex("#103445"),
        ElementBackgroundTransparency = 0.10,
    })

    return themes
end

--// ============================================================================
--// ANIMATED GRADIENT ENGINE
--// ============================================================================

local function startGradientRunner()
    if gradientRunner then
        return
    end

    local ok, connection = pcall(function()
        return RunService.Heartbeat:Connect(function()
            local currentTime = os.clock()
            for gradient, data in pairs(animatedGradients) do
                pcall(function()
                    if typeof(gradient) == "Instance" and gradient.Parent then
                        local speed = data.Speed or 0.2
                        local amount = data.Amount or 0.35
                        local phase = data.Phase or 0
                        local wave = currentTime * speed + phase
                        gradient.Offset = Vector2.new(
                            math.sin(wave) * amount,
                            math.cos(wave * 0.63) * amount * 0.18
                        )
                        if data.BaseRotation then
                            gradient.Rotation = data.BaseRotation + math.sin(wave * 0.71) * (data.RotationAmount or 5)
                        end
                    else
                        animatedGradients[gradient] = nil
                    end
                end)
            end
        end)
    end)

    if ok and connection then
        gradientRunner = trackConnection(connection)
    end
end

local function registerAnimatedGradient(gradient, options)
    if not gradient or not gradient:IsA("UIGradient") then
        return
    end

    options = options or {}

    animatedGradients[gradient] = {
        Speed = options.Speed or CONFIG.GlassSheen.MovementSpeed,
        Amount = options.Amount or CONFIG.GlassSheen.MovementAmount,
        Phase = options.Phase or math.random() * math.pi * 2,
        BaseRotation = options.BaseRotation or gradient.Rotation,
        RotationAmount = options.RotationAmount or CONFIG.GlassSheen.RotationAmount,
    }

    startGradientRunner()
end

--// ============================================================================
--// WEB IMAGE LOADER
--// ============================================================================

local function ensureFolder(path)
    if type(path) ~= "string" or path == "" then
        return false
    end
    if type(makefolder) ~= "function" or type(isfolder) ~= "function" then
        return false
    end

    local accumulated = ""
    for part in string.gmatch(path, "[^/\\]+") do
        accumulated = accumulated == "" and part or accumulated .. "/" .. part
        local ok, exists = pcall(isfolder, accumulated)
        if ok and not exists then
            pcall(makefolder, accumulated)
        end
    end
    return true
end

local function requestURL(url)
    if type(url) ~= "string" or url == "" then
        return nil
    end

    local requestFunction = http_request or request or (syn and syn.request)
    if type(requestFunction) == "function" then
        local ok, response = pcall(function()
            return requestFunction({
                Url = url,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "WindUI-AnimeFrost/3.0",
                    ["Accept"] = "image/avif,image/webp,image/png,image/jpeg,*/*",
                },
            })
        end)
        if ok and type(response) == "table" then
            local body = response.Body or response.body
            local status = tonumber(response.StatusCode or response.Status)
            if type(body) == "string" and #body > 0 and (not status or (status >= 200 and status < 300)) then
                return body
            end
        end
    end

    local okGame, body = pcall(function()
        return game:HttpGet(url)
    end)
    if okGame and type(body) == "string" and #body > 0 then
        return body
    end

    local okHttp, bodyHttp = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if okHttp and type(bodyHttp) == "string" and #bodyHttp > 0 then
        return bodyHttp
    end

    return nil
end

local function getOnlineImage(url, fileName)
    local fallback = CONFIG.Background.FallbackAssetId
    if type(writefile) ~= "function"
        or type(readfile) ~= "function"
        or type(getcustomasset) ~= "function"
        or type(makefolder) ~= "function"
        or type(isfolder) ~= "function"
        or type(isfile) ~= "function"
    then
        return fallback, false
    end

    if type(url) ~= "string" or type(fileName) ~= "string" or fileName == "" then
        return fallback, false
    end

    local folder = string.match(fileName, "^(.*)[/\\][^/\\]+$")
    if folder and not ensureFolder(folder) then
        return fallback, false
    end

    local exists = false
    local okFile, result = pcall(isfile, fileName)
    exists = okFile and result == true

    if exists then
        local okRead = pcall(readfile, fileName)
        if not okRead then
            exists = false
        end
    end

    if not exists then
        local body = requestURL(url)
        if not body then
            return fallback, false
        end
        local okWrite = pcall(writefile, fileName, body)
        if not okWrite then
            return fallback, false
        end
    end

    local okAsset, asset = pcall(getcustomasset, fileName)
    if okAsset and type(asset) == "string" and asset ~= "" then
        return asset, true
    end

    return fallback, false
end

--// ============================================================================
--// GLASS SHEEN EFFECT
--// ============================================================================

local function addFrostSheen(guiObject)
    if not CONFIG.GlassSheen.Enabled then
        return
    end

    if not guiObject or not guiObject:IsA("GuiObject") then
        return
    end

    if guiObject:FindFirstChild("AF_FrostSheen") then
        return
    end

    local intensity = math.clamp(CONFIG.GlassSheen.Intensity or 0.42, 0, 1)
    local sheen

    if guiObject:IsA("ImageLabel") or guiObject:IsA("ImageButton") then
        sheen = Instance.new("ImageLabel")
        sheen.BackgroundTransparency = 1
        sheen.Image = guiObject.Image
        sheen.ImageRectOffset = guiObject.ImageRectOffset
        sheen.ImageRectSize = guiObject.ImageRectSize
        sheen.ScaleType = guiObject.ScaleType
        sheen.SliceCenter = guiObject.SliceCenter
        sheen.SliceScale = guiObject.SliceScale
        sheen.ImageColor3 = Color3.new(1, 1, 1)
        sheen.ImageTransparency = 0
    else
        sheen = Instance.new("Frame")
        sheen.BackgroundColor3 = Color3.new(1, 1, 1)
        sheen.BackgroundTransparency = 0
        sheen.BorderSizePixel = 0

        local sourceCorner = guiObject:FindFirstChildOfClass("UICorner")
        local corner = Instance.new("UICorner")
        corner.CornerRadius = sourceCorner and sourceCorner.CornerRadius or UDim.new(0, 12)
        corner.Parent = sheen
    end

    sheen.Name = "AF_FrostSheen"
    sheen.Size = UDim2.fromScale(1, 1)
    sheen.Position = UDim2.fromScale(0, 0)
    sheen.ZIndex = guiObject.ZIndex
    sheen.Active = false
    sheen.Selectable = false
    sheen.Parent = guiObject

    trackInstance(sheen)

    local gradient = Instance.new("UIGradient")
    gradient.Name = "AF_AnimatedSheen"
    gradient.Rotation = CONFIG.GlassSheen.Rotation or 35
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, PALETTE.LineWhite),
        ColorSequenceKeypoint.new(0.32, PALETTE.CyanGlow),
        ColorSequenceKeypoint.new(0.52, PALETTE.SnowWhite),
        ColorSequenceKeypoint.new(0.70, PALETTE.IceGlow),
        ColorSequenceKeypoint.new(1.00, PALETTE.LineWhite),
    })
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.00, 1),
        NumberSequenceKeypoint.new(0.22, 1),
        NumberSequenceKeypoint.new(0.42, 1 - intensity * 0.35),
        NumberSequenceKeypoint.new(0.50, 1 - intensity),
        NumberSequenceKeypoint.new(0.58, 1 - intensity * 0.35),
        NumberSequenceKeypoint.new(0.78, 1),
        NumberSequenceKeypoint.new(1.00, 1),
    })
    gradient.Offset = Vector2.new(-0.4, 0)
    gradient.Parent = sheen

    registerAnimatedGradient(gradient, {
        Speed = CONFIG.GlassSheen.MovementSpeed,
        Amount = CONFIG.GlassSheen.MovementAmount,
        BaseRotation = CONFIG.GlassSheen.Rotation,
        RotationAmount = CONFIG.GlassSheen.RotationAmount,
    })

    if guiObject:IsA("ImageLabel") or guiObject:IsA("ImageButton") then
        local function syncImage()
            if not sheen or not sheen.Parent then
                return
            end
            sheen.Image = guiObject.Image
            sheen.ImageRectOffset = guiObject.ImageRectOffset
            sheen.ImageRectSize = guiObject.ImageRectSize
            sheen.ScaleType = guiObject.ScaleType
            sheen.SliceCenter = guiObject.SliceCenter
            sheen.SliceScale = guiObject.SliceScale
        end

        trackConnection(guiObject:GetPropertyChangedSignal("Image"):Connect(syncImage))
        trackConnection(guiObject:GetPropertyChangedSignal("SliceCenter"):Connect(syncImage))
        trackConnection(guiObject:GetPropertyChangedSignal("SliceScale"):Connect(syncImage))
    end
end

local function isNativeInputControl(instance)
    if typeof(instance) ~= "Instance" then
        return false
    end

    local current = instance
    for _ = 1, 20 do
        if not current then
            break
        end

        local name = string.lower(tostring(current.Name or ""))
        if name == "topbar"
            or name == "slidercontainer"
            or name == "hitbox"
            or name == "resize"
            or name == "drag"
            or name == "frame" and current.Parent and string.lower(tostring(current.Parent.Name or "")) == "topbar"
        then
            return true
        end

        current = current.Parent
    end

    return false
end

local function stabilizeNativeInput(window)
    local root = window and window.UIElements and window.UIElements.Main
    if typeof(root) ~= "Instance" or not root.Parent then
        return
    end

    pcall(function()
        root.Active = true
    end)

    local function stabilize(object)
        if typeof(object) ~= "Instance" then
            return
        end

        local name = string.lower(tostring(object.Name or ""))
        local shouldActivate =
            name == "topbar"
            or name == "slidercontainer"
            or name == "hitbox"
            or name == "frame" and object.Parent and string.lower(tostring(object.Parent.Name or "")) == "topbar"

        if shouldActivate and object:IsA("GuiObject") then
            pcall(function()
                object.Active = true
                object.Selectable = false
            end)
        end
    end

    for _, descendant in ipairs(root:GetDescendants()) do
        pcall(stabilize, descendant)
    end

    trackConnection(root.DescendantAdded:Connect(function(descendant)
        task.defer(function()
            pcall(stabilize, descendant)
        end)
    end))

    local openButtonMain = window.OpenButtonMain
    if openButtonMain and openButtonMain.Button then
        pcall(function()
            local button = openButtonMain.Button
            local dragFrame = button.Parent
            if typeof(dragFrame) == "Instance" and dragFrame:IsA("GuiObject") then
                dragFrame.Active = true
                dragFrame.Selectable = false
            end
            if button:IsA("GuiButton") then
                button.Active = true
                button.Selectable = false
            end
        end)
    end
end

--// ============================================================================
--// HOVER / CLICK ANIMATION
--// ============================================================================

local function addInteractionEffects(button)
    if not CONFIG.Interaction.Enabled then
        return
    end

    if not button or not button:IsA("GuiButton") then
        return
    end

    -- Never attach visual input handlers to WindUI's native interaction controls.
    -- These objects own drag/click state and share WindUI.CurrentInput.
    if isNativeInputControl(button) then
        return
    end

    -- WindUI sliders own their drag/input lifecycle. Never decorate slider hitboxes.
    local function isSliderControl(instance)
        local current = instance
        for _ = 1, 8 do
            if not current then
                break
            end
            local name = string.lower(tostring(current.Name or ""))
            if name == "slidercontainer"
                or name == "slidericon"
                or name == "thumb"
                or string.find(name, "slider", 1, true)
            then
                return true
            end
            current = current.Parent
        end
        return false
    end

    if isSliderControl(button) then
        return
    end

    if decoratedObjects[button] then
        return
    end

    decoratedObjects[button] = true

    local interactionConfig = CONFIG.Interaction
    local hovering = false
    local pressing = false
    local scale = nil

    if not button:FindFirstChildOfClass("UIScale") then
        scale = Instance.new("UIScale")
        scale.Name = "AF_InteractionScale"
        scale.Scale = 1
        scale.Parent = button
        trackInstance(scale)
    end

    local overlay = Instance.new("Frame")
    overlay.Name = "AF_HoverBrightness"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.new(1, 1, 1)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.Active = false
    overlay.Selectable = false
    overlay.ZIndex = button.ZIndex
    overlay.Parent = button
    trackInstance(overlay)

    local sourceCorner = button:FindFirstChildOfClass("UICorner")
    local corner = Instance.new("UICorner")
    corner.CornerRadius = sourceCorner and sourceCorner.CornerRadius or UDim.new(0, 11)
    corner.Parent = overlay

    local hoverGradient = Instance.new("UIGradient")
    hoverGradient.Name = "AF_HoverGradient"
    hoverGradient.Rotation = 25
    hoverGradient.Offset = Vector2.new(-1, 0)
    hoverGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, PALETTE.ElectricBlue),
        ColorSequenceKeypoint.new(0.48, PALETTE.SnowWhite),
        ColorSequenceKeypoint.new(1.00, PALETTE.IceGlow),
    })
    hoverGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.00, 0.92),
        NumberSequenceKeypoint.new(0.45, 0.55),
        NumberSequenceKeypoint.new(0.55, 0.36),
        NumberSequenceKeypoint.new(1.00, 0.92),
    })
    hoverGradient.Parent = overlay

    local stroke = Instance.new("UIStroke")
    stroke.Name = "AF_InteractionStroke"
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = PALETTE.IceGlow
    stroke.Thickness = 1
    stroke.Transparency = 1
    stroke.Parent = button
    trackInstance(stroke)

    local function animateScale(value, duration)
        if scale and scale.Parent then
            tween(scale, duration, { Scale = value }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        end
    end

    trackConnection(button.MouseEnter:Connect(function()
        hovering = true
        if not pressing then
            animateScale(interactionConfig.HoverScale, interactionConfig.HoverDuration)
        end

        tween(overlay, interactionConfig.HoverDuration, {
            BackgroundTransparency = interactionConfig.HoverBrightnessTransparency,
        }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        tween(stroke, interactionConfig.HoverDuration, {
            Transparency = interactionConfig.StrokeTransparency,
            Thickness = 1.35,
        }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        hoverGradient.Offset = Vector2.new(-1, 0)
        tween(hoverGradient, 0.65, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    end))

    trackConnection(button.MouseLeave:Connect(function()
        hovering = false
        pressing = false
        animateScale(1, interactionConfig.HoverDuration)
        tween(overlay, interactionConfig.HoverDuration, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        tween(stroke, interactionConfig.HoverDuration, { Transparency = 1, Thickness = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    end))

    trackConnection(button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            pressing = true
            animateScale(interactionConfig.PressScale, interactionConfig.PressDuration)
            tween(overlay, interactionConfig.PressDuration, { BackgroundTransparency = 0.88 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            tween(stroke, interactionConfig.PressDuration, { Transparency = 0.35, Thickness = 1.8 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        end
    end))

    trackConnection(button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            pressing = false
            animateScale(hovering and interactionConfig.HoverScale or 1, 0.16)
            tween(overlay, 0.16, {
                BackgroundTransparency = hovering and interactionConfig.HoverBrightnessTransparency or 1,
            }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            tween(stroke, 0.18, {
                Transparency = hovering and interactionConfig.StrokeTransparency or 1,
                Thickness = hovering and 1.35 or 1,
            }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        end
    end))
end

--// ============================================================================
--// BREATHING GLOW
--// ============================================================================

local function addBreathingGlow(guiObject, name, color)
    if not CONFIG.Glow.Enabled then
        return nil
    end

    if not guiObject or not guiObject:IsA("GuiObject") then
        return nil
    end

    name = name or "AF_BreathingGlow"

    local existing = guiObject:FindFirstChild(name)
    if existing then
        return existing
    end

    local glowConfig = CONFIG.Glow

    local stroke = Instance.new("UIStroke")
    stroke.Name = name
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    stroke.Color = color or glowConfig.Color
    stroke.Thickness = glowConfig.Thickness
    stroke.Transparency = glowConfig.Transparency
    stroke.Parent = guiObject
    trackInstance(stroke)

    local gradient = Instance.new("UIGradient")
    gradient.Name = "AF_GlowGradient"
    gradient.Rotation = 35
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, PALETTE.ElectricBlue),
        ColorSequenceKeypoint.new(0.30, PALETTE.CyanGlow),
        ColorSequenceKeypoint.new(0.55, PALETTE.SnowWhite),
        ColorSequenceKeypoint.new(0.75, PALETTE.IceGlow),
        ColorSequenceKeypoint.new(1.00, PALETTE.SoftPurple),
    })
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.00, 0.40),
        NumberSequenceKeypoint.new(0.30, 0.02),
        NumberSequenceKeypoint.new(0.55, 0.26),
        NumberSequenceKeypoint.new(0.78, 0.04),
        NumberSequenceKeypoint.new(1.00, 0.44),
    })
    gradient.Parent = stroke

    registerAnimatedGradient(gradient, {
        Speed = 0.13,
        Amount = 0.28,
        BaseRotation = 35,
        RotationAmount = 16,
    })

    local ok, breathingTween = pcall(function()
        return TweenService:Create(
            stroke,
            TweenInfo.new(glowConfig.Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {
                Thickness = glowConfig.MaxThickness,
                Transparency = glowConfig.MaxTransparency,
            }
        )
    end)

    if ok and breathingTween then
        trackTween(breathingTween)
        pcall(function()
            breathingTween:Play()
        end)
    end

    return stroke
end

--// ============================================================================
--// BACKGROUND + OVERLAY
--// ============================================================================

local function applyBackground(window)
    local backgroundConfig = CONFIG.Background

    if not backgroundConfig.Enabled then
        return
    end

    local root = window and window.UIElements and window.UIElements.Main
    if typeof(root) ~= "Instance" or not root.Parent then
        return
    end

    local host = root:FindFirstChild("Main")
    if typeof(host) ~= "Instance" or not host.Parent then
        host = root
    end

    local oldLayer = host:FindFirstChild("AF_Watermark")
    if oldLayer then
        AnimeFrost._backgroundLayer = oldLayer
        return oldLayer
    end

    local layer = Instance.new("Frame")
    layer.Name = "AF_Watermark"
    layer.Size = UDim2.fromScale(1, 1)
    layer.Position = UDim2.fromScale(0, 0)
    layer.BackgroundTransparency = 1
    layer.BorderSizePixel = 0
    layer.ClipsDescendants = true
    layer.Active = false
    layer.Selectable = false
    layer.ZIndex = -10
    layer.Parent = host
    trackInstance(layer)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, tonumber(window.UICorner) or 16)
    corner.Parent = layer

    local image = Instance.new("ImageLabel")
    image.Name = "AF_WebBackground"
    image.Size = UDim2.fromScale(1.04, 1.04)
    image.Position = UDim2.fromScale(-0.02, -0.02)
    image.BackgroundTransparency = 1
    image.BorderSizePixel = 0
    image.Image = backgroundConfig.FallbackAssetId or ""
    image.ImageTransparency = math.clamp(tonumber(backgroundConfig.ImageTransparency) or 0.44, 0, 1)
    image.ScaleType = Enum.ScaleType.Crop
    image.Active = false
    image.Selectable = false
    image.ZIndex = -10
    image.Parent = layer
    trackInstance(image)

    local darkOverlay = Instance.new("Frame")
    darkOverlay.Name = "AF_DarkOverlay"
    darkOverlay.Size = UDim2.fromScale(1, 1)
    darkOverlay.BackgroundColor3 = PALETTE.VoidBlack
    darkOverlay.BackgroundTransparency = math.clamp(
        tonumber(backgroundConfig.DarkOverlayTransparency) or 0.45,
        0,
        1
    )
    darkOverlay.BorderSizePixel = 0
    darkOverlay.Active = false
    darkOverlay.Selectable = false
    darkOverlay.ZIndex = -9
    darkOverlay.Parent = layer
    trackInstance(darkOverlay)

    local colorOverlay = Instance.new("Frame")
    colorOverlay.Name = "AF_ColorOverlay"
    colorOverlay.Size = UDim2.fromScale(1, 1)
    colorOverlay.BackgroundColor3 = Color3.new(1, 1, 1)
    colorOverlay.BackgroundTransparency = math.clamp(
        tonumber(backgroundConfig.BlueOverlayTransparency) or 0.78,
        0,
        1
    )
    colorOverlay.BorderSizePixel = 0
    colorOverlay.Active = false
    colorOverlay.Selectable = false
    colorOverlay.ZIndex = -8
    colorOverlay.Parent = layer
    trackInstance(colorOverlay)

    local colorGradient = Instance.new("UIGradient")
    colorGradient.Name = "AF_BackgroundGradient"
    colorGradient.Rotation = 125
    colorGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, PALETTE.AbyssNavy),
        ColorSequenceKeypoint.new(0.35, PALETTE.DeepNavy),
        ColorSequenceKeypoint.new(0.68, PALETTE.AzureCore),
        ColorSequenceKeypoint.new(1.00, PALETTE.SoftPurple),
    })
    colorGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.00, 0.18),
        NumberSequenceKeypoint.new(0.35, 0.44),
        NumberSequenceKeypoint.new(0.68, 0.72),
        NumberSequenceKeypoint.new(1.00, 0.50),
    })
    colorGradient.Parent = colorOverlay

    registerAnimatedGradient(colorGradient, {
        Speed = 0.08,
        Amount = 0.16,
        BaseRotation = 125,
        RotationAmount = 5,
    })

    -- Load asynchronously so WindUI never waits for the executor's HTTP layer.
    task.spawn(function()
        local ok, asset, loadedFromURL = pcall(function()
            return getOnlineImage(backgroundConfig.URL, backgroundConfig.FilePath)
        end)

        if ok and typeof(image) == "Instance" and image.Parent and type(asset) == "string" then
            pcall(function()
                image.Image = asset
            end)
        end

        if not loadedFromURL then
            pcall(function()
                warn("[AnimeFrost] Background URL unavailable; fallback asset retained.")
            end)
        end
    end)

    if backgroundConfig.ParallaxEnabled then
        local ok, parallaxTween = pcall(function()
            return TweenService:Create(
                image,
                TweenInfo.new(
                    math.max(tonumber(backgroundConfig.ParallaxDuration) or 8, 0.1),
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut,
                    -1,
                    true
                ),
                {
                    Size = UDim2.fromScale(1.10, 1.10),
                    Position = UDim2.fromScale(-0.05, -0.05),
                }
            )
        end)

        if ok and parallaxTween then
            trackTween(parallaxTween)
            pcall(function()
                parallaxTween:Play()
            end)
        end
    end

    AnimeFrost._backgroundLayer = layer
    return layer
end


--// ============================================================================
--// SNOW PARTICLES
--// ============================================================================

local function createSnowParticles(layer)
    local cfg = CONFIG.Particles
    if not cfg.Enabled or typeof(layer) ~= "Instance" or not layer.Parent then
        return
    end

    local existing = layer:FindFirstChild("AF_SnowParticles")
    if existing then
        return existing
    end

    local holder = Instance.new("Frame")
    holder.Name = "AF_SnowParticles"
    holder.Size = UDim2.fromScale(1, 1)
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.ClipsDescendants = true
    holder.Active = false
    holder.Selectable = false
    holder.ZIndex = -7
    holder.Parent = layer
    trackInstance(holder)

    local random = Random.new()
    local symbols = {"❄", "✦", "✧", "·", "•"}
    local active = {}
    local activeCount = 0
    local pool = {}

    local maxParticles = math.clamp(
        math.floor(tonumber(cfg.MaxParticles) or tonumber(cfg.Count) or 42),
        4,
        160
    )

    local function setParticleStyle(particle)
        local minSize = math.max(4, math.floor(tonumber(cfg.MinSize) or 8))
        local maxSize = math.max(minSize, math.floor(tonumber(cfg.MaxSize) or 21))
        local minTransparency = math.clamp(tonumber(cfg.MinTransparency) or 0.20, 0, 1)
        local maxTransparency = math.clamp(tonumber(cfg.MaxTransparency) or 0.68, minTransparency, 1)

        particle.Text = symbols[random:NextInteger(1, #symbols)]
        particle.TextSize = random:NextInteger(minSize, maxSize)
        particle.TextColor3 = random:NextInteger(1, 3) == 1 and PALETTE.CyanGlow or PALETTE.FrostWhite
        particle.TextStrokeColor3 = PALETTE.AzureCore
        particle.TextStrokeTransparency = 0.82
        particle.TextTransparency = random:NextNumber(minTransparency, maxTransparency)
        particle.Rotation = random:NextNumber(-25, 25)
    end

    local function getParticle()
        local particle = table.remove(pool)
        if particle and particle.Parent then
            return particle
        end

        if activeCount >= maxParticles then
            return nil
        end

        particle = Instance.new("TextLabel")
        particle.Name = "AF_Snowflake"
        particle.Size = UDim2.fromOffset(28, 28)
        particle.AnchorPoint = Vector2.new(0.5, 0.5)
        particle.BackgroundTransparency = 1
        particle.BorderSizePixel = 0
        particle.Font = Enum.Font.Gotham
        particle.Active = false
        particle.Selectable = false
        particle.ZIndex = -6
        particle.Parent = holder
        trackInstance(particle)
        return particle
    end

    local function launchParticle(initial)
        if not holder.Parent or not CONFIG.Particles.Enabled then
            return
        end

        local particle = getParticle()
        if not particle then
            return
        end

        if active[particle] then
            return
        end

        active[particle] = true
        activeCount += 1
        setParticleStyle(particle)

        local startX = random:NextNumber(-0.04, 1.04)
        local drift = random:NextNumber(-0.12, 0.12)
        local startY = initial
            and random:NextNumber(-0.18, 0.95)
            or random:NextNumber(-0.16, -0.03)

        particle.Position = UDim2.fromScale(startX, startY)

        local duration = random:NextNumber(
            math.max(tonumber(cfg.MinDuration) or 7, 1),
            math.max(tonumber(cfg.MaxDuration) or 14, 1.1)
        )

        local targetTransparency = 0.96
        local targetRotation = particle.Rotation + random:NextNumber(-150, 150)

        local fallTween = tween(
            particle,
            duration,
            {
                Position = UDim2.fromScale(startX + drift, 1.12),
                Rotation = targetRotation,
                TextTransparency = targetTransparency,
            },
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.InOut
        )

        if fallTween then
            task.spawn(function()
                pcall(function()
                    fallTween.Completed:Wait()
                end)

                if active[particle] then
                    active[particle] = nil
                    activeCount = math.max(0, activeCount - 1)
                end

                if particle.Parent and holder.Parent and CONFIG.Particles.Enabled then
                    task.wait(random:NextNumber(
                        tonumber(cfg.RespawnDelayMin) or 0.05,
                        tonumber(cfg.RespawnDelayMax) or 0.55
                    ))
                    if holder.Parent and CONFIG.Particles.Enabled then
                        table.insert(pool, particle)
                    end
                else
                    table.insert(pool, particle)
                end
            end)
        else
            if active[particle] then
                active[particle] = nil
                activeCount = math.max(0, activeCount - 1)
            end
            table.insert(pool, particle)
        end
    end

    local initialCount = math.clamp(
        math.floor(tonumber(cfg.InitialParticles) or tonumber(cfg.Count) or 18),
        0,
        maxParticles
    )

    for _ = 1, initialCount do
        launchParticle(true)
    end

    local accumulator = 0
    local okConnection, snowConnection = pcall(function()
        return RunService.RenderStepped:Connect(function(dt)
            local stepOk = pcall(function()
                if not holder.Parent then
                    return
                end

                if not CONFIG.Particles.Enabled then
                    return
                end

                local rate = math.clamp(
                    tonumber(CONFIG.Particles.ParticlesPerSecond) or 8,
                    0.1,
                    120
                )

                accumulator += math.max(tonumber(dt) or 0, 0)

                local spawned = 0
                while accumulator >= (1 / rate) and spawned < maxParticles do
                    accumulator -= (1 / rate)
                    launchParticle(false)
                    spawned += 1

                    if activeCount >= maxParticles then
                        break
                    end
                end
            end)

            if not stepOk then
                accumulator = 0
            end
        end)
    end)

    if okConnection and snowConnection then
        trackConnection(snowConnection)
    end

    return holder
end


--// ============================================================================
--// MAIN WINDOW GLASS / GLOW DECORATION
--// ============================================================================

local function decorateMainFrames(window)
    if not window or not window.UIElements then
        return
    end

    local root = window.UIElements.Main
    local mainBar = window.UIElements.MainBar
    local sideBar = window.UIElements.SideBarContainer

    if root then
        addBreathingGlow(root, "AF_MainWindowGlow", CONFIG.Glow.Color)
    end

    if mainBar then
        addBreathingGlow(mainBar, "AF_MainPanelGlow", CONFIG.Glow.SecondaryColor)
        local panelBackground = mainBar:FindFirstChild("Background")
        if panelBackground then
            addFrostSheen(panelBackground)
        end
    end

    if sideBar then
        addBreathingGlow(sideBar, "AF_SidebarGlow", PALETTE.AzureCore)
    end
end

--// ============================================================================
--// SHAPE VISUAL HOOK
--// ============================================================================

local applyingShape = setmetatable({}, { __mode = "k" })

local function applyOptionalShape(frame, api, shapeType)
    if typeof(frame) ~= "Instance" then
        return
    end

    if not frame:IsA("ImageLabel") and not frame:IsA("ImageButton") then
        return
    end

    local current = frame
    for _ = 1, 8 do
        if not current then
            break
        end

        local name = string.lower(tostring(current.Name or ""))
        if name == "slidercontainer"
            or name == "slidericon"
            or name == "thumb"
            or string.find(name, "slider", 1, true)
        then
            return
        end

        current = current.Parent
    end

    local resolvedType = shapeType

    if api and api.GetType then
        local success, result = pcall(function()
            return api:GetType()
        end)

        if success and result then
            resolvedType = result
        end
    end

    local customShape = CONFIG.Shapes[resolvedType]
    if customShape and customShape.Image then
        applyingShape[frame] = true
        frame.Image = customShape.Image
        if customShape.Rect then
            frame.SliceCenter = customShape.Rect
        end
        if customShape.SliceScale then
            frame.SliceScale = customShape.SliceScale
        end
        applyingShape[frame] = nil
    end

    if type(resolvedType) == "string" and string.find(resolvedType, "Glass", 1, true) then
        addFrostSheen(frame)
    end

    if frame:IsA("ImageButton") then
        addInteractionEffects(frame)
    end
end

local function hookShapes(WindUI)
    if shapeHooked then
        return
    end

    local creator = WindUI.Creator
    if not creator or type(creator.NewRoundFrame) ~= "function" then
        return
    end

    originalNewRoundFrame = creator.NewRoundFrame

    creator.NewRoundFrame = function(radius, shapeType, properties, children, isButton, slice)
        local frame, api = originalNewRoundFrame(radius, shapeType, properties, children, isButton, slice)
        task.defer(function()
            if frame and frame.Parent then
                pcall(applyOptionalShape, frame, api, shapeType)
            end
        end)
        return frame, api
    end

    shapeHooked = true
end

--// ============================================================================
--// ICON PACK
--// ============================================================================

local ICON_FALLBACK = {
    ["x-eye"] = "eye",
    ["x-pupil"] = "circle-dot",
    ["x-eye-pattern"] = "sparkles",
    ["frost-star"] = "snowflake",
    ["frost-sparkle"] = "sparkles",
    ["ice-crystal"] = "snowflake",
}

local registeredIcons = {}

local function registerIcons(WindUI)
    local pack = {}
    local count = 0

    for name, id in pairs(CONFIG.Icons) do
        if type(id) == "number" and id > 0 then
            id = "rbxassetid://" .. id
        end

        if type(id) == "string"
            and id:match("^rbxassetid://%d+$")
            and id ~= "rbxassetid://0"
        then
            pack[name] = id
            registeredIcons[name] = true
            count += 1
        end
    end

    if count > 0 then
        pcall(function()
            WindUI.Creator.AddIcons(AnimeFrost.PACK_NAME, pack)
        end)
    end
end

function AnimeFrost.Icon(name)
    if registeredIcons[name] then
        return AnimeFrost.PACK_NAME .. ":" .. name
    end
    return ICON_FALLBACK[name] or "eye"
end

--// ============================================================================
--// LIGHTING / POST PROCESSING
--// ============================================================================

local function applyLighting()
    local lightingConfig = CONFIG.Lighting

    if not lightingConfig.Enabled or savedLighting then
        return
    end

    savedLighting = {
        GlobalShadows = Lighting.GlobalShadows,
    }

    Lighting.GlobalShadows = lightingConfig.GlobalShadows

    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "AF_ColorCorrection"
    colorCorrection.TintColor = lightingConfig.Tint
    colorCorrection.Saturation = lightingConfig.Saturation
    colorCorrection.Contrast = lightingConfig.Contrast
    colorCorrection.Parent = Lighting
    table.insert(createdLightingEffects, colorCorrection)

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "AF_Bloom"
    bloom.Intensity = lightingConfig.BloomIntensity
    bloom.Size = lightingConfig.BloomSize
    bloom.Threshold = lightingConfig.BloomThreshold
    bloom.Parent = Lighting
    table.insert(createdLightingEffects, bloom)
end

local function restoreLighting()
    for _, effect in ipairs(createdLightingEffects) do
        pcall(function()
            effect:Destroy()
        end)
    end

    table.clear(createdLightingEffects)

    if savedLighting then
        for property, value in pairs(savedLighting) do
            pcall(function()
                Lighting[property] = value
            end)
        end
        savedLighting = nil
    end
end

--// ============================================================================
--// WINDOW DESCENDANT WATCHER
--// ============================================================================

local function processVisualObject(object)
    if not object then
        return
    end

    local lowerName = string.lower(tostring(object.Name or ""))
    local sliderRelated = string.find(lowerName, "slider", 1, true)
        or lowerName == "thumb"
        or lowerName == "slidercontainer"
        or lowerName == "slidericon"

    if isNativeInputControl(object) then
        return
    elseif object:IsA("GuiButton") then
        if not sliderRelated then
            addInteractionEffects(object)
        end
    elseif object:IsA("UIGradient") then
        if object.Name == "LibraryGradient" then
            registerAnimatedGradient(object, {
                Speed = 0.075,
                Amount = 0.10,
                BaseRotation = object.Rotation,
                RotationAmount = 3,
            })
        end
    elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then
        local objectName = string.lower(object.Name)
        if not sliderRelated
            and (
                string.find(objectName, "glass", 1, true)
                or string.find(objectName, "outline", 1, true)
            )
        then
            addFrostSheen(object)
        end
    end
end

local function watchWindow(window)
    local root = window and window.UIElements and window.UIElements.Main
    if not root then
        return
    end

    for _, descendant in ipairs(root:GetDescendants()) do
        pcall(processVisualObject, descendant)
    end

    trackConnection(root.DescendantAdded:Connect(function(descendant)
        task.defer(function()
            if descendant and descendant.Parent then
                pcall(processVisualObject, descendant)
            end
        end)
    end))
end

local function applyPanelGlass(window)
    if not CONFIG.PanelGlass.Enabled or not window or not window.UIElements then
        return
    end

    local mainBar = window.UIElements.MainBar
    local sideBar = window.UIElements.SideBarContainer

    if typeof(mainBar) == "Instance" then
        local bg = mainBar:FindFirstChild("Background")
        if typeof(bg) == "Instance" then
            backupProperty(bg, "ImageTransparency")
            backupProperty(bg, "ImageColor3")
            pcall(function()
                bg.ImageTransparency = math.clamp(CONFIG.PanelGlass.MainTransparency, 0, 1)
                bg.ImageColor3 = PALETTE.SteelNavy
                bg.Visible = true
            end)
        end
    end

    if typeof(sideBar) == "Instance" and not sideBar:FindFirstChild("AF_SidebarGlass") then
        local glass = Instance.new("Frame")
        glass.Name = "AF_SidebarGlass"
        glass.Size = UDim2.fromScale(1, 1)
        glass.BackgroundColor3 = PALETTE.DeepNavy
        glass.BackgroundTransparency = math.clamp(CONFIG.PanelGlass.SidebarTransparency, 0, 1)
        glass.BorderSizePixel = 0
        glass.ZIndex = 0
        glass.Active = false
        glass.Parent = sideBar
        trackInstance(glass)

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, tonumber(window.UICorner) or 16)
        corner.Parent = glass

        local stroke = Instance.new("UIStroke")
        stroke.Name = "AF_SidebarGlassStroke"
        stroke.Color = PALETTE.IceGlow
        stroke.Thickness = 1
        stroke.Transparency = math.clamp(CONFIG.PanelGlass.BorderTransparency, 0, 1)
        stroke.Parent = glass
        trackInstance(stroke)

        addFrostSheen(glass)
    end
end

local function getWindowTitle(window)
    local fallback = CONFIG.Loading.DefaultTitle or "ANIME FROST"
    if not window then
        return fallback, nil
    end

    local title

    pcall(function()
        if type(window.Title) == "string" and window.Title ~= "" then
            title = window.Title
        end
    end)

    local root = window.UIElements and window.UIElements.Main
    if not title and typeof(root) == "Instance" then
        pcall(function()
            local titleObject = root:FindFirstChild("Title", true)
            if titleObject and titleObject:IsA("TextLabel") and titleObject.Text ~= "" then
                title = titleObject.Text
            end
        end)
    end

    local author
    if CONFIG.Loading.ShowAuthor and typeof(root) == "Instance" then
        pcall(function()
            local authorObject = root:FindFirstChild("Author", true)
            if authorObject and authorObject:IsA("TextLabel") and authorObject.Text ~= "" then
                author = authorObject.Text
            end
        end)
    end

    return title or fallback, author
end

local function createTabScrollArrow(window)
    if not window or not window.UIElements then
        return
    end

    local sidebarContainer = window.UIElements.SideBarContainer
    local sidebar = window.UIElements.SideBar

    if typeof(sidebarContainer) ~= "Instance" or typeof(sidebar) ~= "Instance" then
        return
    end

    if sidebarContainer:FindFirstChild("AF_TabDownArrow") then
        return
    end

    local arrow = Instance.new("TextButton")
    arrow.Name = "AF_TabDownArrow"
    arrow.AnchorPoint = Vector2.new(0.5, 1)
    arrow.Position = UDim2.new(0.5, 0, 1, -6)
    arrow.Size = UDim2.fromOffset(34, 30)
    arrow.BackgroundColor3 = PALETTE.DeepNavy
    arrow.BackgroundTransparency = 0.16
    arrow.BorderSizePixel = 0
    arrow.AutoButtonColor = false
    arrow.Text = "⌄"
    arrow.TextSize = 25
    arrow.Font = Enum.Font.GothamBold
    arrow.TextColor3 = PALETTE.FrostWhite
    arrow.TextTransparency = 0.05
    arrow.ZIndex = 250
    arrow.Visible = false
    arrow.Active = true
    arrow.Parent = sidebarContainer
    trackInstance(arrow)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = arrow

    local stroke = Instance.new("UIStroke")
    stroke.Color = PALETTE.IceGlow
    stroke.Thickness = 1
    stroke.Transparency = 0.32
    stroke.Parent = arrow
    trackInstance(stroke)

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = arrow
    trackInstance(scale)

    local function canScrollDown()
        local current = math.max(0, tonumber(sidebar.CanvasPosition.Y) or 0)
        local canvas = math.max(0, tonumber(sidebar.AbsoluteCanvasSize.Y) or 0)
        local viewport = math.max(0, tonumber(sidebar.AbsoluteWindowSize.Y) or sidebar.AbsoluteSize.Y)
        local maxY = math.max(0, canvas - viewport)
        return maxY > 3 and current < (maxY - 3), maxY, current
    end

    local function updateArrow()
        local ok = pcall(function()
            local show = canScrollDown()
            arrow.Visible = show
        end)
        if not ok then
            arrow.Visible = false
        end
    end

    trackConnection(sidebar:GetPropertyChangedSignal("CanvasPosition"):Connect(updateArrow))
    trackConnection(sidebar:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateArrow))
    trackConnection(sidebar:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateArrow))
    trackConnection(sidebar:GetPropertyChangedSignal("Visible"):Connect(updateArrow))

    trackConnection(arrow.MouseEnter:Connect(function()
        tween(scale, 0.16, {Scale = 1.10}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        tween(arrow, 0.16, {BackgroundTransparency = 0.02}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        tween(stroke, 0.16, {Transparency = 0.05}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end))

    trackConnection(arrow.MouseLeave:Connect(function()
        tween(scale, 0.18, {Scale = 1}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        tween(arrow, 0.18, {BackgroundTransparency = 0.16}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        tween(stroke, 0.18, {Transparency = 0.32}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end))

    trackConnection(arrow.Activated:Connect(function()
        local ok = pcall(function()
            local _, maxY, current = canScrollDown()
            if maxY <= 0 then
                return
            end

            local target = math.min(current + math.max(120, sidebar.AbsoluteWindowSize.Y * 0.65), maxY)
            local scrollTween = TweenService:Create(
                sidebar,
                TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {CanvasPosition = Vector2.new(0, target)}
            )
            trackTween(scrollTween)
            scrollTween:Play()
        end)

        if not ok then
            pcall(function()
                arrow.Visible = false
            end)
        end
    end))

    task.defer(updateArrow)
end

local function playLoading(window)
    if not CONFIG.Loading.Enabled or not window or not window.UIElements then
        return true
    end

    local root = window.UIElements.Main
    if typeof(root) ~= "Instance" or not root.Parent then
        return true
    end

    local ok, result = pcall(function()
        local overlay = Instance.new("Frame")
        overlay.Name = "AF_LoadingOverlay"
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.BackgroundColor3 = PALETTE.VoidBlack
        overlay.BackgroundTransparency = 0.08
        overlay.BorderSizePixel = 0
        overlay.ZIndex = 10000
        overlay.Active = true
        overlay.Parent = root
        trackInstance(overlay)

        local blur = Instance.new("Frame")
        blur.Size = UDim2.fromScale(1, 1)
        blur.BackgroundColor3 = PALETTE.DeepNavy
        blur.BackgroundTransparency = 0.30
        blur.BorderSizePixel = 0
        blur.Parent = overlay
        trackInstance(blur)

        local ring = Instance.new("Frame")
        ring.Name = "FrostRing"
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.Position = UDim2.fromScale(0.5, 0.5)
        ring.Size = UDim2.fromOffset(CONFIG.Loading.RingSize, CONFIG.Loading.RingSize)
        ring.BackgroundTransparency = 1
        ring.Parent = overlay
        trackInstance(ring)

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ring
        local stroke = Instance.new("UIStroke")
        stroke.Color = PALETTE.IceGlow
        stroke.Thickness = 3
        stroke.Transparency = 0.14
        stroke.Parent = ring
        trackInstance(stroke)

        local ring2 = Instance.new("Frame")
        ring2.AnchorPoint = Vector2.new(0.5, 0.5)
        ring2.Position = UDim2.fromScale(0.5, 0.5)
        ring2.Size = UDim2.fromOffset(CONFIG.Loading.RingSize - 18, CONFIG.Loading.RingSize - 18)
        ring2.BackgroundTransparency = 1
        ring2.Parent = overlay
        trackInstance(ring2)
        local corner2 = Instance.new("UICorner")
        corner2.CornerRadius = UDim.new(1, 0)
        corner2.Parent = ring2
        local stroke2 = Instance.new("UIStroke")
        stroke2.Color = PALETTE.SnowWhite
        stroke2.Thickness = 1.5
        stroke2.Transparency = 0.50
        stroke2.Parent = ring2
        trackInstance(stroke2)

        local title = Instance.new("TextLabel")
        title.AnchorPoint = Vector2.new(0.5, 0)
        title.Position = UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(0, 52)
        title.Size = UDim2.fromOffset(260, 30)
        title.BackgroundTransparency = 1
        local windowTitle, windowAuthor = getWindowTitle(window)
        title.Text = tostring(windowTitle)
        title.TextColor3 = PALETTE.FrostWhite
        title.TextTransparency = 0.05
        title.TextSize = 17
        title.Font = Enum.Font.GothamBold
        title.TextTruncate = Enum.TextTruncate.AtEnd
        title.Parent = overlay
        trackInstance(title)

        if windowAuthor and windowAuthor ~= "" then
            local authorLabel = Instance.new("TextLabel")
            authorLabel.AnchorPoint = Vector2.new(0.5, 0)
            authorLabel.Position = UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(0, 82)
            authorLabel.Size = UDim2.fromOffset(240, 20)
            authorLabel.BackgroundTransparency = 1
            authorLabel.Text = tostring(windowAuthor)
            authorLabel.TextColor3 = PALETTE.MutedSteel
            authorLabel.TextTransparency = 0.18
            authorLabel.TextSize = 12
            authorLabel.Font = Enum.Font.Gotham
            authorLabel.TextTruncate = Enum.TextTruncate.AtEnd
            authorLabel.Parent = overlay
            trackInstance(authorLabel)
            tween(authorLabel, 0.18, {TextTransparency = 0.18}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end

        local spin1
        local spin2
        pcall(function()
            spin1 = TweenService:Create(
                ring,
                TweenInfo.new(1.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
                {Rotation = 360}
            )
            trackTween(spin1)
            spin1:Play()
        end)
        pcall(function()
            spin2 = TweenService:Create(
                ring2,
                TweenInfo.new(0.85, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
                {Rotation = -360}
            )
            trackTween(spin2)
            spin2:Play()
        end)

        local scale = root:FindFirstChild("AF_OpenScale")
        if not scale then
            scale = Instance.new("UIScale")
            scale.Name = "AF_OpenScale"
            scale.Scale = 0.965
            scale.Parent = root
            trackInstance(scale)
        else
            scale.Scale = 0.965
        end
        tween(scale, CONFIG.Loading.FadeDuration + 0.12, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        task.wait(math.max(tonumber(CONFIG.Loading.Duration) or 0.95, 0))
        tween(overlay, CONFIG.Loading.FadeDuration, {BackgroundTransparency = 1}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        tween(blur, CONFIG.Loading.FadeDuration, {BackgroundTransparency = 1}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        tween(ring, CONFIG.Loading.FadeDuration, {Size = UDim2.fromOffset(8, 8)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tween(ring2, CONFIG.Loading.FadeDuration, {Size = UDim2.fromOffset(4, 4)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tween(title, CONFIG.Loading.FadeDuration, {TextTransparency = 1}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        task.wait(CONFIG.Loading.FadeDuration + 0.03)
        if overlay.Parent then
            pcall(function() overlay:Destroy() end)
        end
        return true
    end)

    if not ok then
        return false
    end
    return result ~= false
end

local function animateWindowOpen(window)
    if not window or not window.UIElements then
        return
    end

    local root = window.UIElements.Main
    if typeof(root) ~= "Instance" or not root.Parent then
        return
    end

    pcall(function()
        local scale = root:FindFirstChild("AF_OpenScale")
        if not scale then
            scale = Instance.new("UIScale")
            scale.Name = "AF_OpenScale"
            scale.Scale = 0.96
            scale.Parent = root
            trackInstance(scale)
        end
        tween(scale, 0.28, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
end

--// ============================================================================
--// PUBLIC API
--// ============================================================================

function AnimeFrost.Apply(WindUI, options)
    assert(
        type(WindUI) == "table" and type(WindUI.CreateWindow) == "function",
        "[AnimeFrost] Tham số đầu tiên phải là WindUI đã được load."
    )

    if options then
        deepMerge(CONFIG, options)
    end

    AnimeFrost.WindUI = WindUI

    local themes = buildThemes(WindUI)
    AnimeFrost.Themes = themes

    for _, theme in pairs(themes) do
        pcall(function()
            WindUI:AddTheme(theme)
        end)
    end

    pcall(function()
        WindUI:SetTheme(CONFIG.DefaultTheme)
    end)

    pcall(hookShapes, WindUI)
    pcall(registerIcons, WindUI)
    pcall(applyLighting)

    startGradientRunner()

    return AnimeFrost
end

function AnimeFrost.Decorate(window)
    assert(
        window and window.UIElements,
        "[AnimeFrost] Decorate cần Window được trả về từ WindUI:CreateWindow()."
    )

    AnimeFrost.Window = window

    local backgroundLayer
    local success, result = pcall(applyBackground, window)

    if success then
        backgroundLayer = result
    else
        warn("[AnimeFrost] Background error: " .. tostring(result))
    end

    if backgroundLayer then
        pcall(createSnowParticles, backgroundLayer)
    end

    pcall(applyPanelGlass, window)
    pcall(decorateMainFrames, window)
    pcall(stabilizeNativeInput, window)
    pcall(watchWindow, window)
    pcall(createTabScrollArrow, window)
    pcall(playLoading, window)
    pcall(stabilizeNativeInput, window)
    pcall(animateWindowOpen, window)

    return AnimeFrost
end

function AnimeFrost.SetSnowRate(particlesPerSecond)
    local value = tonumber(particlesPerSecond)
    if not value or value ~= value or value == math.huge or value <= 0 then
        return false
    end
    local ok = pcall(function()
        CONFIG.Particles.ParticlesPerSecond = math.clamp(value, 0.1, 120)
    end)
    return ok
end

function AnimeFrost.SetParticlesEnabled(enabled)
    CONFIG.Particles.Enabled = enabled == true

    local layer = AnimeFrost._backgroundLayer
    if not layer then
        return AnimeFrost
    end

    local holder = layer:FindFirstChild("AF_SnowParticles")
    if holder then
        holder.Visible = CONFIG.Particles.Enabled
    elseif CONFIG.Particles.Enabled then
        createSnowParticles(layer)
    end

    return AnimeFrost
end

function AnimeFrost.SetBackgroundTransparency(transparency)
    local layer = AnimeFrost._backgroundLayer
    if not layer then
        return AnimeFrost
    end

    local image = layer:FindFirstChild("AF_WebBackground")
    if image then
        image.ImageTransparency = math.clamp(tonumber(transparency) or 0, 0, 1)
    end

    return AnimeFrost
end

function AnimeFrost.Restore()
    if gradientRunner then
        gradientRunner:Disconnect()
        gradientRunner = nil
    end

    table.clear(animatedGradients)

    for _, activeTween in ipairs(activeTweens) do
        pcall(function()
            activeTween:Cancel()
        end)
    end
    table.clear(activeTweens)

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(connections)

    for index = #createdInstances, 1, -1 do
        local instance = createdInstances[index]
        pcall(function()
            if instance and instance.Parent then
                instance:Destroy()
            end
        end)
    end
    table.clear(createdInstances)

    for object, properties in pairs(propertyBackups) do
        if object then
            for property, value in pairs(properties) do
                pcall(function()
                    object[property] = value
                end)
            end
        end
    end

    propertyBackups = setmetatable({}, { __mode = "k" })
    decoratedObjects = setmetatable({}, { __mode = "k" })

    restoreLighting()

    if shapeHooked
        and AnimeFrost.WindUI
        and AnimeFrost.WindUI.Creator
        and originalNewRoundFrame
    then
        AnimeFrost.WindUI.Creator.NewRoundFrame = originalNewRoundFrame
    end

    shapeHooked = false
    originalNewRoundFrame = nil
    AnimeFrost._backgroundLayer = nil
    AnimeFrost.Window = nil

    return AnimeFrost
end

return AnimeFrost
