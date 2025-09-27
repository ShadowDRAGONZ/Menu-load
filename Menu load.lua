-- PlaceId bạn muốn hỗ trợ
local allowedPlaceId = 16457183958 -- Gojo vs Toji

if game.PlaceId == allowedPlaceId then
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Tạo GUI Loading
    local loadingGui = Instance.new("ScreenGui")
    loadingGui.Parent = playerGui
    loadingGui.IgnoreGuiInset = true

    -- Label Loading (3 dấu chấm to)
    local dotLabel = Instance.new("TextLabel")
    dotLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    dotLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    dotLabel.BackgroundTransparency = 1
    dotLabel.Text = ""
    dotLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    dotLabel.Font = Enum.Font.GothamBold
    dotLabel.TextSize = 72 -- ⚡ chữ to hơn gấp đôi
    dotLabel.Parent = loadingGui

    -- Hiệu ứng dấu chấm nhấp nháy cực đẹp
    task.spawn(function()
        while loadingGui.Parent do
            for i = 1, 3 do
                dotLabel.Text = string.rep(".", i)
                dotLabel.TextTransparency = 0
                for t = 0, 1, 0.08 do
                    dotLabel.TextTransparency = t
                    task.wait(0.04)
                end
                task.wait(0.15)
            end
        end
    end)

    -- Sau 4s thì load script
    task.delay(4, function()
        loadingGui:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ShadowDRAGONZ/Gojo-vs-toji-game/refs/heads/main/GojovsToji.Game"))()
    end)
else
    game.Players.LocalPlayer:Kick("❌ Not Support")
end
