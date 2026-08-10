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
        ImageTransparency = 0.05,
        DarkOverlayTransparency = 0.34,
        BlueOverlayTransparency = 0.82,
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
        MinSize = 8,
        MaxSize = 21,
        MinDuration = 8,
        MaxDuration = 17,
        MinTransparency = 0.20,
        MaxTransparency = 0.68,
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

local function isValidInstance(value, className)
    if typeof(value) ~= "Instance" then
        return false
    end
    if className and not value:IsA(className) then
        return false
    end
    return true
end

local function tween(object, duration, properties, style, direction, repeatCount, reverses)
    if not isValidInstance(object) or not object.Parent then
        return nil
    end

    local ok, result = pcall(function()
        return TweenService:Create(
            object,
            TweenInfo.new(
                math.max(0, tonumber(duration) or 0),
                style or Enum.EasingStyle.Quint,
                direction or Enum.EasingDirection.Out,
                repeatCount or 0,
                reverses == true
            ),
            properties or {}
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
                if isValidInstance(gradient, "UIGradient") and gradient.Parent then
                    pcall(function()
                        local speed = data.Speed or 0.2
                        local amount = data.Amount or 0.35
                        local phase = data.Phase or 0
                        local wave = currentTime * speed + phase
                        gradient.Offset = Vector2.new(
                            math.sin(wave) * amount,
                            math.cos(wave * 0.63) * amount * 0.18
                        )
                        if data.BaseRotation ~= nil then
                            gradient.Rotation = data.BaseRotation + math.sin(wave * 0.71) * (data.RotationAmount or 5)
                        end
                    end)
                else
                    animatedGradients[gradient] = nil
                end
            end
        end)
    end)

    if ok then
        gradientRunner = connection
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
    if not makefolder or not isfolder then
        return
    end

    local accumulated = ""
    for part in string.gmatch(path, "[^/\\]+") do
        accumulated = accumulated == "" and part or accumulated .. "/" .. part
        if not isfolder(accumulated) then
            pcall(makefolder, accumulated)
        end
    end
end

local function getRequestFunction()
    return http_request
        or request
        or (syn and syn.request)
        or nil
end

local function requestURL(url)
    local requestFunction = getRequestFunction()

    if requestFunction then
        local success, response = pcall(function()
            return requestFunction({
                Url = url,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "WindUI-AnimeFrost/2.0",
                    ["Accept"] = "image/avif,image/webp,image/png,image/jpeg,*/*",
                },
            })
        end)

        if success and response then
            local body = response.Body or response.body
            local statusCode = response.StatusCode or response.Status
            if type(body) == "string"
                and #body > 0
                and (statusCode == nil or (statusCode >= 200 and statusCode < 300))
            then
                return body
            end
        end
    end

    if type(game) == "Instance" and game.HttpGet then
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)
        if success and type(result) == "string" and #result > 0 then
            return result
        end
    end

    local success, result = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if success and type(result) == "string" and #result > 0 then
        return result
    end

    return nil
end

local function getOnlineImage(url, fileName, fallback)
    fallback = fallback or CONFIG.Background.FallbackAssetId

    local hasFileIO = type(writefile) == "function"
        and type(readfile) == "function"
        and type(getcustomasset) == "function"
        and type(makefolder) == "function"

    if not hasFileIO then
        return fallback, false
    end

    local targetPath = tostring(fileName or "")
    if targetPath == "" then
        return fallback, false
    end

    local folder = string.match(targetPath, "^(.*)[/\\][^/\\]+$")
    if folder and folder ~= "" then
        pcall(ensureFolder, folder)
    end

    local fileExists = false
    if type(isfile) == "function" then
        local ok, result = pcall(isfile, targetPath)
        fileExists = ok and result == true
    else
        local ok = pcall(function()
            return readfile(targetPath)
        end)
        fileExists = ok
    end

    if not fileExists then
        local body = requestURL(url)
        if type(body) ~= "string" or #body == 0 then
            return fallback, false
        end

        local wrote = pcall(writefile, targetPath, body)
        if not wrote then
            return fallback, false
        end
    end

    local okAsset, asset = pcall(getcustomasset, targetPath)
    if okAsset and type(asset) == "string" and #asset > 0 then
        return asset, true
    end

    return fallback, false
end

local function loadWebImage(url, filePath, fallback)
    return getOnlineImage(url, filePath, fallback)
end

--// ============================================================================
--// GLASS SHEEN EFFECT
--// ============================================================================

local function addFrostSheen(guiObject)
    if not CONFIG.GlassSheen.Enabled then
        return
    end

    if not isValidInstance(guiObject, "GuiObject") then
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

--// ============================================================================
--// HOVER / CLICK ANIMATION
--// ============================================================================

local function addInteractionEffects(button)
    if not CONFIG.Interaction.Enabled then
        return
    end

    if not isValidInstance(button, "GuiButton") then
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

    if not isValidInstance(guiObject, "GuiObject") then
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

    local breathingTween = tween(
        stroke,
        glowConfig.Duration,
        {
            Thickness = glowConfig.MaxThickness,
            Transparency = glowConfig.MaxTransparency,
        },
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        -1,
        true
    )

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
    if not isValidInstance(root) then
        return
    end

    local oldLayer = root:FindFirstChild("AF_Watermark", true)
    if oldLayer then
        return
    end

    local host = root:FindFirstChild("Background") or root

    local layer = Instance.new("Frame")
    layer.Name = "AF_Watermark"
    layer.Size = UDim2.fromScale(1, 1)
    layer.Position = UDim2.fromScale(0, 0)
    layer.BackgroundTransparency = 1
    layer.BorderSizePixel = 0
    layer.ClipsDescendants = true
    layer.Active = false
    layer.ZIndex = host.ZIndex + 1
    layer.Parent = host
    trackInstance(layer)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, window.UICorner or 16)
    corner.Parent = layer

    local image = Instance.new("ImageLabel")
    image.Name = "AF_WebBackground"
    image.Size = UDim2.fromScale(1.07, 1.07)
    image.Position = UDim2.fromScale(-0.035, -0.035)
    image.BackgroundTransparency = 1
    image.BorderSizePixel = 0
    image.Image = backgroundConfig.FallbackAssetId or ""
    image.ImageTransparency = backgroundConfig.ImageTransparency
    image.ScaleType = Enum.ScaleType.Crop
    image.Active = false
    image.ZIndex = layer.ZIndex
    image.Parent = layer
    trackInstance(image)

    task.spawn(function()
        pcall(function()
            local asset, loadedFromURL = getOnlineImage(backgroundConfig.URL, backgroundConfig.FilePath, backgroundConfig.FallbackAssetId)
            if isValidInstance(image) and image.Parent and asset then
                image.Image = asset
            end
            if not loadedFromURL then
                warn("[AnimeFrost] Executor không hỗ trợ tải ảnh URL trực tiếp; đang sử dụng FallbackAssetId.")
            end
        end)
    end)

    if backgroundConfig.ParallaxEnabled then
        tween(
            image,
            backgroundConfig.ParallaxDuration,
            {
                Size = UDim2.fromScale(1.12, 1.12),
                Position = UDim2.fromScale(-0.06, -0.06),
            },
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut,
            -1,
            true
        )
    end

    local darkOverlay = Instance.new("Frame")
    darkOverlay.Name = "AF_DarkOverlay"
    darkOverlay.Size = UDim2.fromScale(1, 1)
    darkOverlay.BackgroundColor3 = PALETTE.VoidBlack
    darkOverlay.BackgroundTransparency = backgroundConfig.DarkOverlayTransparency
    darkOverlay.BorderSizePixel = 0
    darkOverlay.Active = false
    darkOverlay.ZIndex = layer.ZIndex + 1
    darkOverlay.Parent = layer
    trackInstance(darkOverlay)

    local darkCorner = Instance.new("UICorner")
    darkCorner.CornerRadius = UDim.new(0, window.UICorner or 16)
    darkCorner.Parent = darkOverlay

    local colorOverlay = Instance.new("Frame")
    colorOverlay.Name = "AF_ColorOverlay"
    colorOverlay.Size = UDim2.fromScale(1, 1)
    colorOverlay.BackgroundColor3 = Color3.new(1, 1, 1)
    colorOverlay.BackgroundTransparency = backgroundConfig.BlueOverlayTransparency
    colorOverlay.BorderSizePixel = 0
    colorOverlay.Active = false
    colorOverlay.ZIndex = layer.ZIndex + 2
    colorOverlay.Parent = layer
    trackInstance(colorOverlay)

    local colorCorner = Instance.new("UICorner")
    colorCorner.CornerRadius = UDim.new(0, window.UICorner or 16)
    colorCorner.Parent = colorOverlay

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
        NumberSequenceKeypoint.new(0.00, 0.15),
        NumberSequenceKeypoint.new(0.35, 0.42),
        NumberSequenceKeypoint.new(0.68, 0.70),
        NumberSequenceKeypoint.new(1.00, 0.46),
    })
    colorGradient.Parent = colorOverlay

    registerAnimatedGradient(colorGradient, {
        Speed = 0.08,
        Amount = 0.17,
        BaseRotation = 125,
        RotationAmount = 5,
    })

    AnimeFrost._backgroundLayer = layer
    return layer
end

--// ============================================================================
--// SNOW PARTICLES
--// ============================================================================

local function createSnowParticles(layer)
    local particleConfig = CONFIG.Particles
    if not particleConfig.Enabled or not isValidInstance(layer) then
        return
    end

    if layer:FindFirstChild("AF_SnowParticles") then
        return
    end

    local holder = Instance.new("Frame")
    holder.Name = "AF_SnowParticles"
    holder.Size = UDim2.fromScale(1, 1)
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.ClipsDescendants = true
    holder.Active = false
    holder.ZIndex = layer.ZIndex + 3
    holder.Parent = layer
    trackInstance(holder)

    local randomGenerator = Random.new()
    local symbols = { "•", "·", "✦", "❄", "✧" }

    local function animateParticle(particle, initial)
        task.spawn(function()
            if initial then
                task.wait(randomGenerator:NextNumber(0, 4))
            end

            while particle and particle.Parent and holder.Parent do
                local startX = randomGenerator:NextNumber(-0.05, 1.05)
                local drift = randomGenerator:NextNumber(-0.16, 0.16)
                local size = randomGenerator:NextInteger(particleConfig.MinSize, particleConfig.MaxSize)
                local duration = randomGenerator:NextNumber(particleConfig.MinDuration, particleConfig.MaxDuration)

                particle.TextSize = size
                particle.Text = symbols[randomGenerator:NextInteger(1, #symbols)]
                particle.Position = UDim2.fromScale(startX, randomGenerator:NextNumber(-0.22, -0.04))
                particle.Rotation = randomGenerator:NextNumber(-30, 30)
                particle.TextTransparency = randomGenerator:NextNumber(particleConfig.MinTransparency, particleConfig.MaxTransparency)

                local fallTween = tween(
                    particle,
                    duration,
                    {
                        Position = UDim2.fromScale(startX + drift, 1.12),
                        Rotation = particle.Rotation + randomGenerator:NextNumber(-160, 160),
                        TextTransparency = 0.92,
                    },
                    Enum.EasingStyle.Linear,
                    Enum.EasingDirection.InOut
                )

                if fallTween then
                    pcall(function()
                        fallTween.Completed:Wait()
                    end)
                end

                task.wait(randomGenerator:NextNumber(0.05, 1.2))
            end
        end)
    end

    for index = 1, particleConfig.Count do
        local particle = Instance.new("TextLabel")
        particle.Name = "AF_Snowflake_" .. index
        particle.Size = UDim2.fromOffset(28, 28)
        particle.AnchorPoint = Vector2.new(0.5, 0.5)
        particle.BackgroundTransparency = 1
        particle.BorderSizePixel = 0
        particle.Text = "❄"
        particle.TextColor3 = index % 3 == 0 and PALETTE.CyanGlow or PALETTE.FrostWhite
        particle.TextStrokeColor3 = PALETTE.AzureCore
        particle.TextStrokeTransparency = 0.84
        particle.Font = Enum.Font.Gotham
        particle.Active = false
        particle.ZIndex = holder.ZIndex
        particle.Parent = holder
        trackInstance(particle)
        animateParticle(particle, true)
    end
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
        local ok, frame, api = pcall(originalNewRoundFrame, radius, shapeType, properties, children, isButton, slice)
        if not ok then
            warn("[AnimeFrost] NewRoundFrame hook failed: " .. tostring(frame))
            return nil, nil
        end

        task.defer(function()
            if isValidInstance(frame) and frame.Parent then
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
--// WINDOW LIFECYCLE ANIMATION
--// ============================================================================

local windowLifecycleBusy = false

local function supportsProperty(object, propertyName)
    if not isValidInstance(object) then
        return false
    end
    return pcall(function()
        return object[propertyName]
    end)
end

local function setupWindowScale(root)
    if not isValidInstance(root) then
        return nil
    end

    local scale = root:FindFirstChild("AF_WindowScale")
    if isValidInstance(scale, "UIScale") then
        return scale
    end

    scale = Instance.new("UIScale")
    scale.Name = "AF_WindowScale"
    scale.Scale = 1
    scale.Parent = root
    trackInstance(scale)
    return scale
end

local function animateWindowOpen(root)
    if not isValidInstance(root) or not root.Parent then
        return
    end

    local scale = setupWindowScale(root)
    local hasGroupTransparency = supportsProperty(root, "GroupTransparency")

    if hasGroupTransparency then
        backupProperty(root, "GroupTransparency")
        pcall(function()
            root.GroupTransparency = 1
        end)
    end

    pcall(function()
        root.Visible = true
    end)

    if scale then
        pcall(function()
            scale.Scale = 0.75
        end)
        tween(scale, 0.42, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end

    if hasGroupTransparency then
        tween(root, 0.42, { GroupTransparency = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end
end

local function animateWindowClose(root)
    if not isValidInstance(root) or not root.Parent then
        return
    end

    local scale = setupWindowScale(root)
    local hasGroupTransparency = supportsProperty(root, "GroupTransparency")

    if scale then
        pcall(function()
            scale.Scale = 1
        end)
        tween(scale, 0.20, { Scale = 0.75 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    end

    if hasGroupTransparency then
        tween(root, 0.20, { GroupTransparency = 1 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    end
end

--// ============================================================================
--// WINDOW DESCENDANT WATCHER
--// ============================================================================

local function processVisualObject(object)
    if not isValidInstance(object) then
        return
    end

    if object:IsA("GuiButton") then
        addInteractionEffects(object)
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
        if string.find(objectName, "glass", 1, true)
            or string.find(objectName, "outline", 1, true)
        then
            addFrostSheen(object)
        end
    end
end

local function watchWindow(window)
    local root = window and window.UIElements and window.UIElements.Main
    if not isValidInstance(root) then
        return
    end

    for _, descendant in ipairs(root:GetDescendants()) do
        pcall(processVisualObject, descendant)
    end

    trackConnection(root.DescendantAdded:Connect(function(descendant)
        task.defer(function()
            if isValidInstance(descendant) and descendant.Parent then
                pcall(processVisualObject, descendant)
            end
        end)
    end))

    local okVisible, visibleConnection = pcall(function()
        return root:GetPropertyChangedSignal("Visible"):Connect(function()
            if windowLifecycleBusy or not isValidInstance(root) then
                return
            end

            if root.Visible == false then
                windowLifecycleBusy = true
                task.spawn(function()
                    pcall(function()
                        root.Visible = true
                    end)
                    animateWindowClose(root)
                    task.wait(0.22)
                    if isValidInstance(root) and root.Parent then
                        pcall(function()
                            root.Visible = false
                        end)
                    end
                    windowLifecycleBusy = false
                end)
            end
        end)
    end)

    if okVisible and visibleConnection then
        trackConnection(visibleConnection)
    end
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

    pcall(decorateMainFrames, window)
    pcall(watchWindow, window)

    local root = window and window.UIElements and window.UIElements.Main
    if isValidInstance(root) then
        pcall(function()
            root.Visible = true
        end)
        animateWindowOpen(root)
    end

    return AnimeFrost
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
    local root = AnimeFrost.Window and AnimeFrost.Window.UIElements and AnimeFrost.Window.UIElements.Main
    if isValidInstance(root) then
        windowLifecycleBusy = true
        pcall(function()
            animateWindowClose(root)
        end)
        task.wait(0.22)
    end

    if gradientRunner then
        pcall(function()
            gradientRunner:Disconnect()
        end)
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
            if isValidInstance(instance) and instance.Parent then
                instance:Destroy()
            end
        end)
    end
    table.clear(createdInstances)

    for object, properties in pairs(propertyBackups) do
        if isValidInstance(object) then
            for property, value in pairs(properties) do
                pcall(function()
                    object[property] = value
                end)
            end
        end
    end

    propertyBackups = setmetatable({}, { __mode = "k" })
    decoratedObjects = setmetatable({}, { __mode = "k" })
    windowLifecycleBusy = false

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
