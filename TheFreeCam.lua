local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/main/source.lua", true))()

local Window = Luna:CreateWindow({
	Name = "Zypher Hub (Freecam Test)", -- This Is Title Of Your Window
	Subtitle = "Call us Lazy", -- A Gray Subtitle next To the main title.
	LogoID = "82795327169782", -- The Asset ID of your logo. Set to nil if you do not have a logo for Luna to use.
	LoadingEnabled = true, -- Whether to enable the loading animation. Set to false if you do not want the loading screen or have your own custom one.
	LoadingTitle = "Preview", -- Header for loading screen
	LoadingSubtitle = "by VoxLar", -- Subtitle for loading screen

	ConfigSettings = {
		RootFolder = nil, -- The Root Folder Is Only If You Have A Hub With Multiple Game Scripts and u may remove it. DO NOT ADD A SLASH
		ConfigFolder = "Big Hub" -- The Name Of The Folder Where Luna Will Store Configs For This Script. DO NOT ADD A SLASH
	},

	KeySystem = false, -- As Of Beta 6, Luna Has officially Implemented A Key System!
	KeySettings = {
		Title = "Luna Example Key",
		Subtitle = "Key System",
		Note = "Best Key System Ever! Also, Please Use A HWID Keysystem like Pelican, Luarmor etc. that provide key strings based on your HWID since putting a simple string is very easy to bypass",
		SaveInRoot = false, -- Enabling will save the key in your RootFolder (YOU MUST HAVE ONE BEFORE ENABLING THIS OPTION)
		SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
		Key = {"Example Key"}, -- List of keys that will be accepted by the system, please use a system like Pelican or Luarmor that provide key strings based on your HWID since putting a simple string is very easy to bypass
		SecondAction = {
			Enabled = true, -- Set to false if you do not want a second action,
			Type = "Link", -- Link / Discord.
			Parameter = "" -- If Type is Discord, then put your invite link (DO NOT PUT DISCORD.GG/). Else, put the full link of your key system here.
		}
	}
})

-- Freecam Variables
local freecamEnabled = false
local freecamMode = "Fly" -- "Fly" or "Walk"
local freecamCFrame = CFrame.new()
local freecamFOV = 70
local originalCFrame = CFrame.new()
local originalFOV = 70
local originalCharacter = nil
local freecamSpeed = 5
local maxSpeed = 16
local minSpeed = 0.5
local isMoving = false

-- Movement Keys
local movementKeys = {
    Forward = false,
    Backward = false,
    Left = false,
    Right = false,
    Up = false,
    Down = false
}

-- Create Luna UI
local window = Luna:CreateWindow("Freecam Hub")
local tab = window:CreateTab("Freecam")

-- Toggle Freecam
local toggle = tab:CreateToggle({
    Name = "Enable Freecam",
    Callback = function(value)
        freecamEnabled = value
        if value then
            StartFreecam()
        else
            EndFreecam()
        end
    end
})

-- Freecam Mode Dropdown
local modeDropdown = tab:CreateDropdown({
    Name = "Freecam Mode",
    Options = {"Fly", "Walk"},
    Callback = function(value)
        freecamMode = value
    end
})

-- Freecam Speed Slider
local speedSlider = tab:CreateSlider({
    Name = "Freecam Speed",
    Min = 1,
    Max = 10,
    Default = 5,
    Callback = function(value)
        freecamSpeed = value
    end
})

-- Start Freecam
function StartFreecam()
    originalCharacter = Players.LocalPlayer.Character
    originalCFrame = workspace.CurrentCamera.CFrame
    originalFOV = workspace.CurrentCamera.FieldOfView

    -- Hide character
    if originalCharacter then
        for _, part in ipairs(originalCharacter:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
            end
        end
    end

    -- Set up freecam
    freecamCFrame = originalCFrame
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

    -- Input handling
    UserInputService.InputBegan:Connect(ProcessInput)
    UserInputService.InputEnded:Connect(ProcessInput)

    -- Camera movement loop
    RunService:BindToRenderStep("FreecamUpdate", Enum.RenderPriority.Camera.Value, UpdateFreecam)
end

-- End Freecam
function EndFreecam()
    -- Restore original camera
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    workspace.CurrentCamera.CFrame = originalCFrame
    workspace.CurrentCamera.FieldOfView = originalFOV

    -- Show character again
    if originalCharacter and originalCharacter.Parent then
        for _, part in ipairs(originalCharacter:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
            end
        end
    end

    -- Cleanup
    RunService:UnbindFromRenderStep("FreecamUpdate")
end

-- Process Key Inputs
function ProcessInput(input, gameProcessed)
    if gameProcessed then return end

    local key = input.KeyCode
    local state = input.UserInputState == Enum.UserInputState.Begin

    -- Movement keys
    if key == Enum.KeyCode.W then movementKeys.Forward = state
    elseif key == Enum.KeyCode.S then movementKeys.Backward = state
    elseif key == Enum.KeyCode.A then movementKeys.Left = state
    elseif key == Enum.KeyCode.D then movementKeys.Right = state
    elseif key == Enum.KeyCode.Space then movementKeys.Up = state
    elseif key == Enum.KeyCode.LeftShift then movementKeys.Down = state
    end

    -- Check if moving
    isMoving = movementKeys.Forward or movementKeys.Backward or
               movementKeys.Left or movementKeys.Right or
               movementKeys.Up or movementKeys.Down
end

-- Update Freecam Movement
function UpdateFreecam(dt)
    if not freecamEnabled then return end

    local camera = workspace.CurrentCamera
    local moveVector = Vector3.new(0, 0, 0)

    -- Calculate movement direction
    if movementKeys.Forward then moveVector = moveVector + camera.CFrame.LookVector end
    if movementKeys.Backward then moveVector = moveVector - camera.CFrame.LookVector end
    if movementKeys.Left then moveVector = moveVector - camera.CFrame.RightVector end
    if movementKeys.Right then moveVector = moveVector + camera.CFrame.RightVector end
    if movementKeys.Up and freecamMode == "Fly" then moveVector = moveVector + Vector3.new(0, 1, 0) end
    if movementKeys.Down and freecamMode == "Fly" then moveVector = moveVector - Vector3.new(0, 1, 0) end

    -- Normalize and apply speed
    if moveVector.Magnitude > 0 then
        moveVector = moveVector.Unit * freecamSpeed
    end

    -- Update camera position
    freecamCFrame = freecamCFrame + moveVector * dt * 60
    camera.CFrame = freecamCFrame
end

-- Mouse Look (optional, for better control)
UserInputService.InputChanged:Connect(function(input)
    if not freecamEnabled then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Delta
        freecamCFrame = freecamCFrame * CFrame.fromEulerAnglesYXZ(
            -delta.Y * 0.003,
            -delta.X * 0.003,
            0
        )
    end
end)
