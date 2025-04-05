local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/main/source.lua", true))()
local Window = Luna:CreateWindow({
    Name = "Dead Rails Hub",
    Theme = "Dark",
    Size = UDim2.new(0, 500, 0, 400)
})

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Create all tabs at the top
local CombatTab = Window:CreateTab("Combat")
local VisualTab = Window:CreateTab("Visuals")
local PlayerTab = Window:CreateTab("Player")

-- COMBAT TAB --
CombatTab:CreateSection("Aimbot Settings")
local AimToggle = CombatTab:CreateToggle({Name = "Enable Aimbot", Default = false})
local AimFOV = CombatTab:CreateSlider({Name = "FOV Size", Min = 30, Max = 300, Default = 100})
local AimPart = CombatTab:CreateDropdown({Name = "Aim Part", Options = {"Head", "Torso"}, Default = "Head"})
local HorseToggle = CombatTab:CreateToggle({Name = "Ignore Horses", Default = true})
local WallToggle = CombatTab:CreateToggle({Name = "Wall Check", Default = true})
local AimKey = CombatTab:CreateKeybind({Name = "Aimbot Hotkey", Default = "Q"})

-- VISUAL TAB --
VisualTab:CreateSection("ESP Settings")
local NpcEsp = VisualTab:CreateToggle({Name = "NPC Outlines", Default = false})
local CorpseEsp = VisualTab:CreateToggle({Name = "Corpse Outlines", Default = false})
local OreEsp = VisualTab:CreateToggle({Name = "Ore Outlines", Default = false})
local ToolEsp = VisualTab:CreateToggle({Name = "Tool Outlines", Default = false})
local ItemEsp = VisualTab:CreateToggle({Name = "Item Outlines", Default = false})
local ScanSpeed = VisualTab:CreateSlider({Name = "Scan Interval", Min = 0.1, Max = 5, Default = 0.5})

-- PLAYER TAB --
PlayerTab:CreateSection("NoClip Settings")
local NoclipToggle = PlayerTab:CreateToggle({Name = "Enable NoClip", Default = false})
local NoclipKey = PlayerTab:CreateKeybind({Name = "NoClip Hotkey", Default = "F"})
local NoclipBtn = PlayerTab:CreateToggle({Name = "Show Button", Default = true})

-- Initialize Settings
local AimSettings = {
    Enabled = AimToggle.Value,
    FOV = AimFOV.Value,
    AimPart = AimPart.Value,
    IgnoreHorses = HorseToggle.Value,
    WallCheck = WallToggle.Value,
    Hotkey = AimKey.Value
}

local OutlineSettings = {
    NPCs = NpcEsp.Value,
    Corpses = CorpseEsp.Value,
    Ores = OreEsp.Value,
    Tools = ToolEsp.Value,
    Items = ItemEsp.Value,
    ScanInterval = ScanSpeed.Value
}

local NoClipSettings = {
    Enabled = NoclipToggle.Value,
    Hotkey = NoclipKey.Value,
    ButtonVisible = NoclipBtn.Value
}

-- Connect UI Callbacks
AimToggle:OnChanged(function(v) AimSettings.Enabled = v end)
AimFOV:OnChanged(function(v) AimSettings.FOV = v end)
AimPart:OnChanged(function(v) AimSettings.AimPart = v end)
HorseToggle:OnChanged(function(v) AimSettings.IgnoreHorses = v end)
WallToggle:OnChanged(function(v) AimSettings.WallCheck = v end)
AimKey:OnChanged(function(v) AimSettings.Hotkey = v end)

NpcEsp:OnChanged(function(v) OutlineSettings.NPCs = v end)
CorpseEsp:OnChanged(function(v) OutlineSettings.Corpses = v end)
OreEsp:OnChanged(function(v) OutlineSettings.Ores = v end)
ToolEsp:OnChanged(function(v) OutlineSettings.Tools = v end)
ItemEsp:OnChanged(function(v) OutlineSettings.Items = v end)
ScanSpeed:OnChanged(function(v) OutlineSettings.ScanInterval = v end)

-- AIMBOT IMPLEMENTATION --
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(0, 255, 255)
FOVCircle.Thickness = 1
FOVCircle.Radius = AimSettings.FOV
FOVCircle.Filled = false

local function IsNPC(model)
    return model and model:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(model)
end

local function IsHorse(model)
    return model and (model.Name:lower():find("horse") or model:FindFirstChild("HorseTag"))
end

local function IsVisible(targetPart)
    if not AimSettings.WallCheck then return true end
    local camera = workspace.CurrentCamera
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local rayResult = workspace:Raycast(camera.CFrame.Position, (targetPart.Position - camera.CFrame.Position).Unit * 1000, raycastParams)
    return not rayResult or rayResult.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetClosestNPC()
    local closest, minDist = nil, AimSettings.FOV
    local camera = workspace.CurrentCamera
    local mousePos = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)

    for _, npc in ipairs(workspace:GetDescendants()) do
        if IsNPC(npc) and (not AimSettings.IgnoreHorses or not IsHorse(npc)) then
            local part = npc:FindFirstChild(AimSettings.AimPart) or npc:FindFirstChild("HumanoidRootPart")
            if part and IsVisible(part) then
                local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < minDist then
                        closest = part
                        minDist = dist
                    end
                end
            end
        end
    end
    return closest
end

-- OUTLINE IMPLEMENTATION --
local Highlights = {}

local function CreateHighlight(instance, color)
    if not instance or not instance.Parent then return end
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 1
    highlight.OutlineColor = color
    highlight.Parent = instance
    Highlights[instance] = highlight
end

local function RemoveHighlight(instance)
    if Highlights[instance] then
        Highlights[instance]:Destroy()
        Highlights[instance] = nil
    end
end

local function ShouldHighlight(instance)
    if not instance then return nil end
    
    if instance:IsA("Model") then
        if OutlineSettings.NPCs and IsNPC(instance) and not IsHorse(instance) then
            return Color3.fromRGB(255, 50, 50)
        elseif OutlineSettings.Corpses and instance:FindFirstChild("CorpseTag") then
            return Color3.fromRGB(0, 200, 0)
        end
    elseif instance:IsA("BasePart") then
        if OutlineSettings.Ores and instance.Name:lower():find("ore") then
            return Color3.fromRGB(255, 165, 0)
        elseif OutlineSettings.Tools and instance:IsA("Tool") then
            return Color3.fromRGB(0, 150, 255)
        elseif OutlineSettings.Items and (instance.Name:lower():find("item") or (instance.Parent and instance.Parent.Name:lower():find("item"))) then
            return Color3.fromRGB(150, 0, 255)
        end
    end
    return nil
end

local function UpdateOutlines()
    for instance, _ in pairs(Highlights) do
        if not instance or not instance.Parent then
            RemoveHighlight(instance)
        end
    end

    for _, instance in ipairs(workspace:GetDescendants()) do
        local color = ShouldHighlight(instance)
        if color then
            if not Highlights[instance] then
                CreateHighlight(instance, color)
            end
        else
            RemoveHighlight(instance)
        end
    end
end

-- NOCLIP IMPLEMENTATION --
local NoClipButton = Instance.new("TextButton")
NoClipButton.Name = "NoClipToggle"
NoClipButton.Size = UDim2.new(0, 100, 0, 40)
NoClipButton.Position = UDim2.new(0.85, 0, 0.8, 0)
NoClipButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
NoClipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
NoClipButton.Text = "NoClip: OFF"
NoClipButton.Font = Enum.Font.GothamBold
NoClipButton.TextSize = 14
NoClipButton.BorderSizePixel = 0
NoClipButton.AutoButtonColor = true
NoClipButton.Parent = game:GetService("CoreGui")

local function ToggleNoClip()
    NoClipSettings.Enabled = not NoClipSettings.Enabled
    NoClipButton.Text = NoClipSettings.Enabled and "NoClip: ON" or "NoClip: OFF"
    NoClipButton.BackgroundColor3 = NoClipSettings.Enabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(30, 30, 30)
end

NoclipToggle:OnChanged(function(v) 
    NoClipSettings.Enabled = v 
    ToggleNoClip() 
end)

NoclipKey:OnChanged(function(v) NoClipSettings.Hotkey = v end)

NoclipBtn:OnChanged(function(v) 
    NoClipSettings.ButtonVisible = v 
    NoClipButton.Visible = v 
end)

-- RUNTIME CONNECTIONS --
RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = AimSettings.Enabled
    FOVCircle.Radius = AimSettings.FOV
    FOVCircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2)

    if AimSettings.Enabled then
        local target = GetClosestNPC()
        if target then
            workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, target.Position)
        end
    end
end)

RunService.Stepped:Connect(function()
    if NoClipSettings.Enabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

task.spawn(function()
    while task.wait(OutlineSettings.ScanInterval) do
        if OutlineSettings.NPCs or OutlineSettings.Corpses or OutlineSettings.Ores or OutlineSettings.Tools or OutlineSettings.Items then
            UpdateOutlines()
        else
            for instance, _ in pairs(Highlights) do
                RemoveHighlight(instance)
            end
        end
    end
end)

UIS.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode[AimSettings.Hotkey] then
            AimSettings.Enabled = not AimSettings.Enabled
        elseif input.KeyCode == Enum.KeyCode[NoClipSettings.Hotkey] then
            ToggleNoClip()
        end
    end
end)

-- Initialize
NoClipButton.Visible = NoClipSettings.ButtonVisible
Luna:Notification({
    Title = "Script Loaded",
    Text = "Dead Rails hub activated!",
    Duration = 5
})
