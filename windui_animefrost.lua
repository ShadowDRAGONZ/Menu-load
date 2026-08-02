--[[
     _      ___         ____  ______
    | | /| / (_)__  ___/ / / / /  _/
    | |/ |/ / / _ \/ _  / /_/ // /  
    |__/|__/_/_//_/\_,_/\____/___/
    
    v1.6.65  |  2026-07-01  |  Roblox UI Library for scripts
    
    To view the source code, see the `src/` folder on the official GitHub repository.
    
    Author: Footagesus (Footages, .ftgs, oftgs)
    Github: https://github.com/Footagesus/WindUI
    Discord: https://discord.gg/ftgs-development-hub-1300692552005189632
    License: MIT
]]

--[[  ============================================================================
      WindUI VISUAL OVERHAUL — "ANIME FROST"
      ----------------------------------------------------------------------------
      Gói đại tu hình ảnh cho WindUI v1.6.65, lấy cảm hứng từ chân dung anime
      cell-shaded tông lạnh (tóc trắng/xanh băng, đồng tử hình chữ X).
      ============================================================================ ]]

local AnimeFrost = {}
AnimeFrost.VERSION   = "1.0.0"
AnimeFrost.TARGET    = "WindUI 1.6.65"
AnimeFrost.PACK_NAME = "animefrost"

local cloneref = (cloneref or clonereference or function(s) return s end)
local Lighting = cloneref(game:GetService("Lighting"))

-- 1. BẢNG MÀU GỐC (PALETTE)
local PALETTE = {
    VoidBlack   = Color3.fromHex("#04070D"),
    AbyssNavy   = Color3.fromHex("#02050E"),
    DeepNavy    = Color3.fromHex("#0A1424"),
    SteelNavy   = Color3.fromHex("#0F1E33"),
    SlateNavy   = Color3.fromHex("#101B2C"),
    RoyalBlue   = Color3.fromHex("#1B4FD8"),
    ElectricBlue= Color3.fromHex("#4C7BFF"),
    AzureCore   = Color3.fromHex("#2F9BFF"),
    IceGlow     = Color3.fromHex("#35D0FF"),
    SkyIcon     = Color3.fromHex("#7FC4FF"),
    FrostWhite  = Color3.fromHex("#EAF4FF"),
    SnowWhite   = Color3.fromHex("#F4F9FF"),
    LineWhite   = Color3.fromHex("#DCEBFF"),
    Silver      = Color3.fromHex("#B9C7D6"),
    MutedSteel  = Color3.fromHex("#8FA9C7"),
    InkBlack    = Color3.fromHex("#06121F"),
}
AnimeFrost.Palette = PALETTE

-- 2. CẤU HÌNH NGƯỜI DÙNG (Đã thêm AssetID theo yêu cầu)
local CONFIG = {
    DefaultTheme = "ColdBlue",
    Shapes = {},
    Icons = {},
    GlassSheen = {
        Enabled     = true,
        Rotation    = 45,
        Intensity   = 0.35,
    },
    Watermark = {
        Enabled      = true,
        Mode         = "Asset", -- Đã chuyển từ Procedural sang Asset
        AssetId      = "rbxassetid://82801764111482", -- Đã thêm ID hình nền
        TileSize     = 72,
        Transparency = 0.965,
        Columns      = 5,
        Rows         = 4,
        GlyphSize    = 18,
        Thickness    = 2,
        Color        = PALETTE.LineWhite,
    },
    Lighting = {
        Enabled       = false,
        GlobalShadows = true,
        Tint          = Color3.fromRGB(214, 232, 255),
        Saturation    = -0.08,
        Contrast      = 0.12,
        BloomIntensity= 0.35,
    },
}
AnimeFrost.Config = CONFIG

local function deepMerge(target, source)
    if type(source) ~= "table" then return target end
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then
            deepMerge(target[key], value)
        else
            target[key] = value
        end
    end
    return target
end

-- 3. HỆ THỐNG THEME
local function buildThemes(WindUI)
    local function grad(a, b, rotation)
        return WindUI:Gradient({
            ["0"]   = { Color = a, Transparency = 0 },
            ["100"] = { Color = b, Transparency = 0 },
        }, { Rotation = rotation or 90 })
    end

    local themes = {}

    themes.ColdBlue = {
        Name        = "ColdBlue",
        Accent      = PALETTE.DeepNavy,
        Dialog      = PALETTE.SteelNavy,
        Background  = PALETTE.VoidBlack,
        Outline     = PALETTE.LineWhite,
        Text        = PALETTE.FrostWhite,
        Placeholder = PALETTE.MutedSteel,
        Button      = PALETTE.RoyalBlue,
        Icon        = PALETTE.SkyIcon,
        Primary     = PALETTE.AzureCore,
        Toggle      = PALETTE.IceGlow,
        Slider      = PALETTE.AzureCore,
        Checkbox    = PALETTE.AzureCore,
        SliderIcon  = PALETTE.Silver,

        PanelBackground             = PALETTE.SkyIcon,
        PanelBackgroundTransparency = 0.94,
        LabelBackground             = PALETTE.VoidBlack,
        LabelBackgroundTransparency = 0.78,
        ElementBackground             = PALETTE.SlateNavy,
        ElementBackgroundTransparency = 0,

        DropdownBackground    = PALETTE.SteelNavy,
        DropdownTabBackground = PALETTE.SlateNavy,
        Tooltip               = PALETTE.SteelNavy,
    }

    themes.MidnightAesthetic = {
        Name        = "MidnightAesthetic",
        Accent      = grad(Color3.fromHex("#0A1226"), Color3.fromHex("#111C3D"), 90),
        Dialog      = Color3.fromHex("#0C1630"),
        Background  = grad(PALETTE.AbyssNavy, Color3.fromHex("#081131"), 90),
        Outline     = PALETTE.LineWhite,
        Text        = Color3.fromHex("#DCE6FF"),
        Placeholder = Color3.fromHex("#7E90C4"),
        Button      = grad(Color3.fromHex("#2B49B8"), PALETTE.ElectricBlue, 45),
        Icon        = Color3.fromHex("#6EA8FF"),
        Primary     = PALETTE.ElectricBlue,
        Toggle      = Color3.fromHex("#3FA9FF"),
        Slider      = PALETTE.ElectricBlue,
        Checkbox    = PALETTE.ElectricBlue,

        PanelBackground             = Color3.fromHex("#8FA8FF"),
        PanelBackgroundTransparency = 0.95,
        LabelBackground             = PALETTE.AbyssNavy,
        LabelBackgroundTransparency = 0.75,
        ElementBackground             = Color3.fromHex("#111A34"),
        ElementBackgroundTransparency = 0,

        DropdownBackground    = Color3.fromHex("#0C1630"),
        DropdownTabBackground = Color3.fromHex("#16214A"),
    }

    themes.FrostLight = {
        Name        = "FrostLight",
        Accent      = Color3.fromHex("#E6F1FD"),
        Dialog      = Color3.fromHex("#EDF4FD"),
        Background  = PALETTE.SnowWhite,
        Outline     = Color3.fromHex("#FFFFFF"),
        Text        = PALETTE.InkBlack,
        Placeholder = Color3.fromHex("#5D7085"),
        Button      = Color3.fromHex("#1D6FE0"),
        Icon        = Color3.fromHex("#2C6FB5"),
        Primary     = Color3.fromHex("#1F8BFF"),
        Toggle      = Color3.fromHex("#12B5D8"),
        Slider      = Color3.fromHex("#1F8BFF"),
        Checkbox    = Color3.fromHex("#1F8BFF"),

        TabBackground                  = Color3.fromHex("#FFFFFF"),
        TabBackgroundHover             = Color3.fromHex("#EDF4FD"),
        TabBackgroundHoverTransparency = 0,
        TabBackgroundActive            = Color3.fromHex("#DCE9F9"),
        TabBackgroundActiveTransparency= 0,

        PanelBackground             = Color3.fromHex("#EAF2FC"),
        PanelBackgroundTransparency = 0,
        LabelBackground             = Color3.fromHex("#EAF2FC"),
        LabelBackgroundTransparency = 0,
        ElementBackground             = Color3.fromHex("#FFFFFF"),
        ElementBackgroundTransparency = 0,

        DropdownBackground    = Color3.fromHex("#FFFFFF"),
        DropdownTabBackground = Color3.fromHex("#DCE9F9"),
    }

    local function alias(sourceName, newName, patch)
        local clone = {}
        for key, value in pairs(themes[sourceName]) do clone[key] = value end
        clone.Name = newName
        if patch then for key, value in pairs(patch) do clone[key] = value end end
        themes[newName] = clone
    end

    alias("ColdBlue", "Dark")
    alias("MidnightAesthetic", "Midnight")
    alias("FrostLight", "Light")
    alias("ColdBlue", "Sky", {
        Accent   = Color3.fromHex("#08202B"),
        Dialog   = Color3.fromHex("#0B2C3A"),
        Primary  = PALETTE.IceGlow,
        Slider   = PALETTE.IceGlow,
        Checkbox = PALETTE.IceGlow,
        Icon     = Color3.fromHex("#5FE0FF"),
        ElementBackground = Color3.fromHex("#0E2733"),
    })

    return themes
end

-- 4. SKIN HÌNH DẠNG + LỚP KÍNH KHÚC XẠ
local isApplying = setmetatable({}, { __mode = "k" })

local function addFrostSheen(frame)
    if frame:FindFirstChild("AF_FrostSheen") then return end
    local intensity = math.clamp(CONFIG.GlassSheen.Intensity or 0.35, 0, 1)
    local sheen = Instance.new("UIGradient")
    sheen.Name     = "AF_FrostSheen"
    sheen.Rotation = CONFIG.GlassSheen.Rotation or 45
    sheen.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, PALETTE.LineWhite),
        ColorSequenceKeypoint.new(0.48, PALETTE.IceGlow),
        ColorSequenceKeypoint.new(1.00, PALETTE.LineWhite),
    })
    sheen.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.00, 1),
        NumberSequenceKeypoint.new(0.28, 1 - intensity * 0.55),
        NumberSequenceKeypoint.new(0.50, 1 - intensity),
        NumberSequenceKeypoint.new(0.72, 1 - intensity * 0.55),
        NumberSequenceKeypoint.new(1.00, 1),
    })
    sheen.Parent = frame
end

local function skinRoundFrame(frame, api, shapeType)
    if typeof(frame) ~= "Instance" then return end
    if not (frame:IsA("ImageLabel") or frame:IsA("ImageButton")) then return end

    local function refresh()
        if isApplying[frame] then return end
        local currentType = shapeType
        if api and api.GetType then
            local ok, resolved = pcall(function() return api:GetType() end)
            if ok and resolved then currentType = resolved end
        end
        local skin = CONFIG.Shapes[currentType]
        if not (skin and skin.Image) then return end

        isApplying[frame] = true
        frame.Image = skin.Image
        if skin.Rect       then frame.SliceCenter = skin.Rect end
        if skin.SliceScale then frame.SliceScale  = skin.SliceScale end
        isApplying[frame] = false
    end

    refresh()
    frame:GetPropertyChangedSignal("Image"):Connect(refresh)

    if CONFIG.GlassSheen.Enabled and typeof(shapeType) == "string"
        and string.find(shapeType, "Glass", 1, true) then
        addFrostSheen(frame)
    end
end

local function hookShapes(WindUI)
    local Creator = WindUI.Creator
    if not Creator or AnimeFrost._shapeHooked then return end

    local original = Creator.NewRoundFrame
    AnimeFrost._originalNewRoundFrame = original

    Creator.NewRoundFrame = function(radius, shapeType, props, children, isButton)
        local frame, api = original(radius, shapeType, props, children, isButton)
        pcall(skinRoundFrame, frame, api, shapeType)
        return frame, api
    end

    AnimeFrost._shapeHooked = true
end

-- 5. ICON PACK ANIME
local ICON_FALLBACK = {
    ["x-eye"]         = "eye",
    ["x-pupil"]       = "circle-dot",
    ["x-eye-pattern"] = "sparkles",
    ["frost-star"]    = "snowflake",
}

local registeredIcons = {}

local function registerIcons(WindUI)
    local pack, count = {}, 0
    for name, id in pairs(CONFIG.Icons) do
        if type(id) == "number" and id > 0 then id = "rbxassetid://" .. id end
        if type(id) == "string" and id:match("^rbxassetid://%d+$") and id ~= "rbxassetid://0" then
            pack[name] = id
            registeredIcons[name] = true
            count = count + 1
        end
    end
    if count > 0 then
        pcall(function() WindUI.Creator.AddIcons(AnimeFrost.PACK_NAME, pack) end)
    end
end

function AnimeFrost.Icon(name)
    if registeredIcons[name] then
        return AnimeFrost.PACK_NAME .. ":" .. name
    end
    return ICON_FALLBACK[name] or "eye"
end

-- 6. WATERMARK / HÌNH NỀN GIAO DIỆN
local function applyWatermark(window)
    local cfg = CONFIG.Watermark
    if not cfg.Enabled then return end

    local mainBar = window and window.UIElements and window.UIElements.MainBar
    if not mainBar or mainBar:FindFirstChild("AF_Watermark") then return end

    local layer = Instance.new("Frame")
    layer.Name                   = "AF_Watermark"
    layer.Size                   = UDim2.fromScale(1, 1)
    layer.BackgroundTransparency = 1
    layer.ClipsDescendants       = true
    layer.ZIndex                 = 4
    layer.Parent                 = mainBar

    -- Đã sửa phần code bị đứt đoạn trước đó & tích hợp Logic load Asset
    if cfg.Mode == "Asset" and cfg.AssetId then
        local img = Instance.new("ImageLabel")
        img.Name                   = "AF_AssetImg"
        img.Size                   = UDim2.fromScale(1,1)
        img.BackgroundTransparency = 1
        img.Image                  = cfg.AssetId
        img.ImageTransparency      = cfg.Transparency
        img.ScaleType              = Enum.ScaleType.Crop
        -- Xóa bỏ hoặc thêm dấu -- để comment dòng TileSize bên dưới
        -- img.TileSize               = UDim2.fromOffset(cfg.TileSize, cfg.TileSize) 
        img.Parent                 = layer
    end
end

-- 7. LIGHTING & POST-PROCESSING (Phục hồi phần mã lỗi)
local savedLighting = nil
local createdEffects = {}

local function applyLighting()
    local cfg = CONFIG.Lighting
    if not cfg.Enabled then return end
    
    savedLighting = { GlobalShadows = Lighting.GlobalShadows }
    Lighting.GlobalShadows = cfg.GlobalShadows

    local cc = Instance.new("ColorCorrectionEffect")
    cc.TintColor = cfg.Tint
    cc.Saturation = cfg.Saturation
    cc.Contrast = cfg.Contrast
    cc.Parent = Lighting
    table.insert(createdEffects, cc)

    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = cfg.BloomIntensity
    bloom.Size      = 18
    bloom.Threshold = 1.1
    bloom.Parent    = Lighting
    table.insert(createdEffects, bloom)
end

local function restoreLighting()
    for _, effect in ipairs(createdEffects) do pcall(function() effect:Destroy() end) end
    createdEffects = {}
    if savedLighting then
        for property, value in pairs(savedLighting) do
            pcall(function() Lighting[property] = value end)
        end
        savedLighting = nil
    end
end

-- 8. API CÔNG KHAI
function AnimeFrost.Apply(WindUI, options)
    assert(type(WindUI) == "table" and WindUI.CreateWindow,
        "[AnimeFrost] Tham số đầu tiên phải là bảng WindUI đã loadstring.")

    deepMerge(CONFIG, options)
    AnimeFrost.WindUI = WindUI

    local themes = buildThemes(WindUI)
    AnimeFrost.Themes = themes
    for _, theme in pairs(themes) do
        pcall(function() WindUI:AddTheme(theme) end)
    end
    pcall(function() WindUI:SetTheme(CONFIG.DefaultTheme) end)

    pcall(hookShapes, WindUI)
    pcall(registerIcons, WindUI)
    pcall(applyLighting)

    return AnimeFrost
end

function AnimeFrost.Decorate(window)
    pcall(applyWatermark, window)
    return AnimeFrost
end

function AnimeFrost.Restore()
    restoreLighting()
    if AnimeFrost._shapeHooked and AnimeFrost.WindUI and AnimeFrost._originalNewRoundFrame then
        AnimeFrost.WindUI.Creator.NewRoundFrame = AnimeFrost._originalNewRoundFrame
        AnimeFrost._shapeHooked = false
    end
    return AnimeFrost
end

return AnimeFrost
