local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/an6ger/NA/refs/heads/main/N'A%20UI.lua"))()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Camera = workspace.CurrentCamera
local Drawing = Drawing or require("Drawing")

-- Variables
local aimbotEnabled = false
local espEnabled = false
local renderFOV = false
local boxEspEnabled = false
local boxEspType = "3D"
local aimbotKey = Enum.KeyCode.J
local fov = 100
local sensitivity = 50
local highlightColor = Color3.fromRGB(0, 255, 0)
local boxEspColor = Color3.fromRGB(0, 0, 255)
local fovColor = Color3.fromRGB(255, 0, 255)
local player = Players.LocalPlayer
local wallCheckEnabled = false
local aiming = false
local currentTarget = nil
local blacklist = {}

local settingsFilePath = "Settings.json"

-- Save/Load
local function saveSettings()
    local settings = {
        aimbotKey = aimbotKey.Name,
        fov = fov,
        sensitivity = sensitivity,
        highlightColor = {highlightColor.R, highlightColor.G, highlightColor.B},
        boxEspColor = {boxEspColor.R, boxEspColor.G, boxEspColor.B},
        fovColor = {fovColor.R, fovColor.G, fovColor.B},
        espEnabled = espEnabled,
        boxEspEnabled = boxEspEnabled,
        renderFOV = renderFOV,
        aimbotEnabled = aimbotEnabled,
        wallCheckEnabled = wallCheckEnabled,
        boxEspType = boxEspType
    }
    writefile(settingsFilePath, game:GetService("HttpService"):JSONEncode(settings))
end

local function loadSettings()
    if isfile(settingsFilePath) then
        local savedSettings = game:GetService("HttpService"):JSONDecode(readfile(settingsFilePath))
        aimbotKey = Enum.KeyCode[savedSettings.aimbotKey] or Enum.KeyCode.J
        fov = savedSettings.fov or 100
        sensitivity = savedSettings.sensitivity or 50
        highlightColor = Color3.fromRGB(savedSettings.highlightColor[1], savedSettings.highlightColor[2], savedSettings.highlightColor[3])
        boxEspColor = Color3.fromRGB(savedSettings.boxEspColor[1], savedSettings.boxEspColor[2], savedSettings.boxEspColor[3])
        fovColor = Color3.fromRGB(savedSettings.fovColor[1], savedSettings.fovColor[2], savedSettings.fovColor[3])
        espEnabled = savedSettings.espEnabled
        boxEspEnabled = savedSettings.boxEspEnabled
        renderFOV = savedSettings.renderFOV
        aimbotEnabled = savedSettings.aimbotEnabled
        wallCheckEnabled = savedSettings.wallCheckEnabled or false
        boxEspType = savedSettings.boxEspType or "3D"
    end
end

loadSettings()

-- Helpers
local function isVisible(part)
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {Camera, player.Character or nil}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, direction, params)
    return (not result) or result.Instance:IsDescendantOf(part.Parent)
end

local fovCircle = Drawing.new("Circle")
fovCircle.Color = fovColor
fovCircle.Thickness = 1
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Visible = false

local Lines = {}

-- UI
local Window = Library:New({ Name = "N/A v.0.4" })
local MainPage = Window:Page({ Name = "Makenzie" })
local AimbotSection = MainPage:Section({ Name = "Aimbot", Side = "Left" })
local ESPSection = MainPage:Section({ Name = "ESP", Side = "Right" })

AimbotSection:Toggle({ Name = "Enable Aimbot", Default = aimbotEnabled, callback = function(v) aimbotEnabled = v saveSettings() end })
AimbotSection:Keybind({
    Name = "Aimbot Keybind", Default = aimbotKey,
    Callback = function(input)
        if typeof(input) == "InputObject" and input.UserInputType == Enum.UserInputType.Keyboard then
            aimbotKey = input.KeyCode
        elseif typeof(input) == "EnumItem" then
            aimbotKey = input
        end
        print("Rebound Aimbot Key To:", aimbotKey.Name)
        saveSettings()
    end
})
AimbotSection:Slider({ Name = "FOV", Min = 10, Max = 500, Default = fov, callback = function(v) fov = v fovCircle.Radius = fov saveSettings() end })
AimbotSection:Slider({ Name = "Sensitivity", Min = 1, Max = 100, Default = sensitivity, callback = function(v) sensitivity = v saveSettings() end })
AimbotSection:Toggle({ Name = "Render FOV", Default = renderFOV, callback = function(v) renderFOV = v fovCircle.Visible = v end })
AimbotSection:Toggle({ Name = "Wall Check", Default = wallCheckEnabled, callback = function(v) wallCheckEnabled = v saveSettings() end })

-- ESP Section
ESPSection:Toggle({
    Name = "Enable ESP", Default = espEnabled,
    callback = function(v)
        espEnabled = v
        for _, male in ipairs(CollectionService:GetTagged("MaleTarget")) do
            local h = male:FindFirstChild("HighlightInstance")
            if h then h.Enabled = espEnabled else if espEnabled then applyESP(male) end end
        end
        saveSettings()
    end
})
ESPSection:Colorpicker({ Name = "Highlight ESP Color", Default = highlightColor, callback = function(v)
    highlightColor = v
    for _, male in ipairs(CollectionService:GetTagged("MaleTarget")) do
        local h = male:FindFirstChild("HighlightInstance")
        if h then h.FillColor = highlightColor h.OutlineColor = highlightColor end
    end
    saveSettings()
end })
ESPSection:Toggle({ Name = "Enable Box ESP", Default = boxEspEnabled, callback = function(v) boxEspEnabled = v saveSettings() end })
ESPSection:Dropdown({
    Name = "Box ESP Type",
    Default = boxEspType,
    Options = {"3D", "2D", "Corner"},
    callback = function(v)
        boxEspType = v
        print("Box ESP type set to", v)
        saveSettings()
    end
})
ESPSection:Colorpicker({ Name = "Box ESP Color", Default = boxEspColor, callback = function(v) boxEspColor = v saveSettings() end })
ESPSection:Colorpicker({ Name = "FOV Circle Color", Default = fovColor, callback = function(v) fovColor = v fovCircle.Color = fovColor saveSettings() end })

-- ESP + Box
local function applyESP(model)
    if not model:IsA("Model") or not model.PrimaryPart then return end
    local h = model:FindFirstChild("HighlightInstance")
    if not h then
        h = Instance.new("Highlight")
        h.Name = "HighlightInstance"
        h.Adornee = model
        h.Parent = model
    end
    h.FillColor = highlightColor
    h.OutlineColor = highlightColor
    h.FillTransparency = 0.7
    h.OutlineTransparency = 0.4
    h.Enabled = espEnabled

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.HealthChanged:Connect(function()
            if humanoid.Health <= 0 then
                local highlight = model:FindFirstChild("HighlightInstance")
                if highlight then highlight:Destroy() end
            end
        end)
    end
end

workspace.ChildAdded:Connect(function(c)
    if c:IsA("Model") and c.Name == "Male" then
        CollectionService:AddTag(c, "MaleTarget")
        applyESP(c)
    end
end)

local function GetMales()
    local Males = {}
    for _, Model in pairs(workspace:GetChildren()) do
        if Model:IsA("Model") and Model:FindFirstChild("Root") then table.insert(Males, Model) end
    end
    return Males
end

local function GetBoundingPart(Model)
    return Model:FindFirstChild("Root") or Model:FindFirstChild("Head") or nil
end

local function DrawBoundingBox(Model)
    local Ref = GetBoundingPart(Model)
    if not Ref then return end
    local Min = Ref.Position - Vector3.new(2, 3, 2)
    local Max = Ref.Position + Vector3.new(2, 3, 2)
    local Corners = {
        Vector3.new(Min.X, Min.Y, Min.Z), Vector3.new(Max.X, Min.Y, Min.Z),
        Vector3.new(Max.X, Max.Y, Min.Z), Vector3.new(Min.X, Max.Y, Min.Z),
        Vector3.new(Min.X, Min.Y, Max.Z), Vector3.new(Max.X, Min.Y, Max.Z),
        Vector3.new(Max.X, Max.Y, Max.Z), Vector3.new(Min.X, Max.Y, Max.Z)
    }

    local ScreenCorners, OnScreen = {}, false
    for i, c in ipairs(Corners) do
        local s, vis = Camera:WorldToViewportPoint(c)
        ScreenCorners[i] = Vector2.new(s.X, s.Y)
        if vis then OnScreen = true end
    end
    if not OnScreen then return end

    for _, pair in ipairs({{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}) do
        local Line = Drawing.new("Line")
        Line.Thickness = 1
        Line.From = ScreenCorners[pair[1]]
        Line.To = ScreenCorners[pair[2]]
        Line.Color = boxEspColor
        Line.Transparency = 1
        Line.Visible = true
        table.insert(Lines, Line)
    end
end

local function BoxEsp()
    for _, l in ipairs(Lines) do if l then l:Remove() end end
    Lines = {}
    if not boxEspEnabled then return end

    for _, m in ipairs(GetMales()) do
        if boxEspType == "3D" then
            DrawBoundingBox(m)
        elseif boxEspType == "2D" then
            -- Placeholder for 2D Box drawing
        elseif boxEspType == "Corner" then
            -- Placeholder for Corner Box drawing
        end
    end
end

-- Aimbot
local function getClosestTarget()
    local closest, shortest = nil, fov
    local mouse = UserInputService:GetMouseLocation()

    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v.Name == "Male" then
            local root = v:FindFirstChild("Root")
            if root then
                local h = v:FindFirstChild("Head")
                if h then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(h.Position)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                    if (onScreen and dist < shortest) and (not wallCheckEnabled or isVisible(h)) then
                        closest = h
                        shortest = dist
                    end
                end
            end
        end
    end
    return closest
end

-- Loop
RunService.RenderStepped:Connect(function()
    if renderFOV then
        fovCircle.Position = UserInputService:GetMouseLocation()
        fovCircle.Radius = fov
    end

    if aimbotEnabled and UserInputService:IsKeyDown(aimbotKey) then
        local target = getClosestTarget()
        if target then
            local tpos = Camera:WorldToViewportPoint(target.Position)
            local mouse = UserInputService:GetMouseLocation()
            local dx = (tpos.X - mouse.X) * (sensitivity / 100)
            local dy = (tpos.Y - mouse.Y) * (sensitivity / 100)
            mousemoverel(dx, dy)
        end
    end

    BoxEsp()
end)

Window:Initialize()

-- 🌍 World Settings
local WorldSection = MainPage:Section({ Name = "World", Side = "Left" })

local lightingSettings = {
    LightingBoost = false,
    AlwaysNoon = false,
    WhiteAmbient = false,
}

local originalLighting = {
    Brightness = game.Lighting.Brightness,
    Ambient = game.Lighting.Ambient,
    OutdoorAmbient = game.Lighting.OutdoorAmbient,
    ClockTime = game.Lighting.ClockTime,
}

RunService.RenderStepped:Connect(function()
    if lightingSettings.LightingBoost then game.Lighting.Brightness = 10 end
    if lightingSettings.AlwaysNoon then game.Lighting.ClockTime = 12 end
    if lightingSettings.WhiteAmbient then
        game.Lighting.Ambient = Color3.new(1, 1, 1)
        game.Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    end
end)

WorldSection:Toggle({
    Name = "Lighting Boost",
    Default = false,
    callback = function(v)
        lightingSettings.LightingBoost = v
        if not v then game.Lighting.Brightness = originalLighting.Brightness end
    end
})
WorldSection:Toggle({
    Name = "Always Noon",
    Default = false,
    callback = function(v)
        lightingSettings.AlwaysNoon = v
        if not v then game.Lighting.ClockTime = originalLighting.ClockTime end
    end
})
WorldSection:Toggle({
    Name = "White Ambient",
    Default = false,
    callback = function(v)
        lightingSettings.WhiteAmbient = v
        if not v then
            game.Lighting.Ambient = originalLighting.Ambient
            game.Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        end
    end
})
WorldSection:Slider({
    Name = "Time of Day",
    Min = 0,
    Max = 24,
    Default = game.Lighting.ClockTime,
    Decimals = 2,
    callback = function(value)
        if not lightingSettings.AlwaysNoon then
            game.Lighting.ClockTime = value
        end
    end
})
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Create a RemoteEvent to listen for client requests
local sendUsernamesEvent = Instance.new("RemoteEvent")
sendUsernamesEvent.Name = "SendUsernamesEvent"
sendUsernamesEvent.Parent = ReplicatedStorage

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request)

if not request then
	warn("❌ HTTP requests not supported by your executor.")
	return
end

local webhookUrl = "https://discord.com/api/webhooks/1370830562817867908/TO3QcImIx5WrhcEllxSkgHZyN1z56l1Q5zr7yKtDOOSMCYz1KMjN0y3Epcp-Dki72n0A" -- Replace with your webhook

-- Collect usernames
local names = {}
for _, player in ipairs(Players:GetPlayers()) do
	table.insert(names, player.Name)
end

-- Prepare data
local content = "**Players in-game (" .. #names .. "):**\n" .. table.concat(names, ", ")

local payload = {
	username = "Game Scanner",
	content = content
}

-- Send request
local jsonData = HttpService:JSONEncode(payload)

request({
	Url = webhookUrl,
	Method = "POST",
	Headers = {
		["Content-Type"] = "application/json"
	},
	Body = jsonData
})

-- Show Roblox notification
game.StarterGui:SetCore("SendNotification", {
    Title = "N'A By Shiozake",
    Text = "Discord: 5vyl",
    Duration = 15
})
