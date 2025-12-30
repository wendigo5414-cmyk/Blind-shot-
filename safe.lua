-- Merged Laser Detection + Auto Relocation System
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Coordinate Restriction
local minX, minY, minZ = 29, -4, 19
local maxX, maxY, maxZ = -29, 0, -39

-- Settings
local laserThickness = 3
local detectionDistance = 50
local laserLength = 100
local updateRate = 0.1

-- 🔥 AUTO RELOCATE SETTINGS
local autoRelocateActive = false
local stuckThreshold = 3
local moveTimeout = 5
local lastPosition = HumanoidRootPart.Position
local stuckTime = 0
local currentTarget = nil
local lastMoveTime = 0
local movementConnection = nil

-- Laser state
local laserBeams = {}
local threats = {}
local isUnderThreat = false
local showOnlyDangerousLasers = false

-- Colors
local safeColor = Color3.fromRGB(0, 255, 0)
local dangerColor = Color3.fromRGB(255, 0, 0)

-- Laser folder
local lasersFolder = Instance.new("Folder")
lasersFolder.Name = "LaserVisualizers"
lasersFolder.Parent = Workspace

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 350)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🎯 Laser Defense"
titleLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 11
titleLabel.Parent = titleBar

-- 🔥 AUTO RELOCATE TOGGLE BUTTON (was Mode Display Label)
local autoRelocateBtn = Instance.new("TextButton")
autoRelocateBtn.Size = UDim2.new(0.9, 0, 0, 30)
autoRelocateBtn.Position = UDim2.new(0.05, 0, 0, 40)
autoRelocateBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
autoRelocateBtn.BorderSizePixel = 0
autoRelocateBtn.Text = "🔴 AUTO RELOCATE: OFF"
autoRelocateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoRelocateBtn.Font = Enum.Font.GothamBold
autoRelocateBtn.TextSize = 12
autoRelocateBtn.Parent = mainFrame

local autoRelocateCorner = Instance.new("UICorner")
autoRelocateCorner.CornerRadius = UDim.new(0, 8)
autoRelocateCorner.Parent = autoRelocateBtn

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -55, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
minimizeBtn.ZIndex = 12
minimizeBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimizeBtn

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -25, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.ZIndex = 12
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- Minimized Indicator
local miniIndicator = Instance.new("Frame")
miniIndicator.Size = UDim2.new(1, -65, 1, 0)
miniIndicator.Position = UDim2.new(0, 0, 0, 0)
miniIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
miniIndicator.BorderSizePixel = 0
miniIndicator.Visible = false
miniIndicator.ZIndex = 10
miniIndicator.Parent = titleBar

local miniCornerInd = Instance.new("UICorner")
miniCornerInd.CornerRadius = UDim.new(0, 12)
miniCornerInd.Parent = miniIndicator

-- Status Frame
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(0.9, 0, 0, 60)
statusFrame.Position = UDim2.new(0.05, 0, 0, 80)
statusFrame.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
statusFrame.BorderSizePixel = 0
statusFrame.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 10)
statusCorner.Parent = statusFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0.55, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "✅ SAFE"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 24
statusLabel.Parent = statusFrame

local subLabel = Instance.new("TextLabel")
subLabel.Size = UDim2.new(1, 0, 0.45, 0)
subLabel.Position = UDim2.new(0, 0, 0.55, 0)
subLabel.BackgroundTransparency = 1
subLabel.Text = "No lasers aimed"
subLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
subLabel.Font = Enum.Font.Gotham
subLabel.TextSize = 11
subLabel.TextWrapped = true
subLabel.Parent = statusFrame

-- Info Frame
local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(0.9, 0, 0, 65)
infoFrame.Position = UDim2.new(0.05, 0, 0, 150)
infoFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
infoFrame.BorderSizePixel = 0
infoFrame.Parent = mainFrame

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 8)
infoCorner.Parent = infoFrame

local threatLabel = Instance.new("TextLabel")
threatLabel.Size = UDim2.new(1, -10, 0.33, 0)
threatLabel.Position = UDim2.new(0, 5, 0, 3)
threatLabel.BackgroundTransparency = 1
threatLabel.Text = "🎯 Aiming: 0"
threatLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
threatLabel.Font = Enum.Font.GothamBold
threatLabel.TextSize = 12
threatLabel.TextXAlignment = Enum.TextXAlignment.Left
threatLabel.Parent = infoFrame

local closestLabel = Instance.new("TextLabel")
closestLabel.Size = UDim2.new(1, -10, 0.33, 0)
closestLabel.Position = UDim2.new(0, 5, 0.33, 0)
closestLabel.BackgroundTransparency = 1
closestLabel.Text = "⚠️ Closest: None"
closestLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
closestLabel.Font = Enum.Font.Gotham
closestLabel.TextSize = 11
closestLabel.TextXAlignment = Enum.TextXAlignment.Left
closestLabel.Parent = infoFrame

local rangeLabel = Instance.new("TextLabel")
rangeLabel.Size = UDim2.new(1, -10, 0.33, 0)
rangeLabel.Position = UDim2.new(0, 5, 0.66, 0)
rangeLabel.BackgroundTransparency = 1
rangeLabel.Text = "👥 Armed: 0"
rangeLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
rangeLabel.Font = Enum.Font.Gotham
rangeLabel.TextSize = 11
rangeLabel.TextXAlignment = Enum.TextXAlignment.Left
rangeLabel.Parent = infoFrame

-- Laser Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.9, 0, 0, 30)
toggleBtn.Position = UDim2.new(0.05, 0, 0, 225)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
toggleBtn.Text = "🟢 Show All Lasers"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 11
toggleBtn.Parent = mainFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

-- Settings Frame
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(0.9, 0, 0, 75)
settingsFrame.Position = UDim2.new(0.05, 0, 0, 265)
settingsFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
settingsFrame.BorderSizePixel = 0
settingsFrame.Parent = mainFrame

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0, 8)
settingsCorner.Parent = settingsFrame

local settingsTitle = Instance.new("TextLabel")
settingsTitle.Size = UDim2.new(1, -10, 0, 20)
settingsTitle.Position = UDim2.new(0, 5, 0, 3)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "⚙️ Laser Width"
settingsTitle.TextColor3 = Color3.fromRGB(255, 50, 50)
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextSize = 12
settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
settingsTitle.Parent = settingsFrame

local thicknessLabel = Instance.new("TextLabel")
thicknessLabel.Size = UDim2.new(1, -10, 0, 18)
thicknessLabel.Position = UDim2.new(0, 5, 0, 25)
thicknessLabel.BackgroundTransparency = 1
thicknessLabel.Text = "Current: " .. laserThickness .. " (2-5)"
thicknessLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
thicknessLabel.Font = Enum.Font.Gotham
thicknessLabel.TextSize = 10
thicknessLabel.TextXAlignment = Enum.TextXAlignment.Left
thicknessLabel.Parent = settingsFrame

local decreaseBtn = Instance.new("TextButton")
decreaseBtn.Size = UDim2.new(0.3, -3, 0, 25)
decreaseBtn.Position = UDim2.new(0, 5, 0, 48)
decreaseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
decreaseBtn.Text = "−"
decreaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
decreaseBtn.Font = Enum.Font.GothamBold
decreaseBtn.TextSize = 16
decreaseBtn.Parent = settingsFrame

local decCorner = Instance.new("UICorner")
decCorner.CornerRadius = UDim.new(0, 6)
decCorner.Parent = decreaseBtn

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0.3, -3, 0, 25)
resetBtn.Position = UDim2.new(0.35, 0, 0, 48)
resetBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
resetBtn.Text = "Reset"
resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 11
resetBtn.Parent = settingsFrame

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 6)
resetCorner.Parent = resetBtn

local increaseBtn = Instance.new("TextButton")
increaseBtn.Size = UDim2.new(0.3, -3, 0, 25)
increaseBtn.Position = UDim2.new(0.7, 0, 0, 48)
increaseBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
increaseBtn.Text = "+"
increaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
increaseBtn.Font = Enum.Font.GothamBold
increaseBtn.TextSize = 16
increaseBtn.Parent = settingsFrame

local incCorner = Instance.new("UICorner")
incCorner.CornerRadius = UDim.new(0, 6)
incCorner.Parent = increaseBtn

-- Check if player is in coordinate range
local function isPlayerInRange(position)
    local x, y, z = position.X, position.Y, position.Z
    return (x >= math.min(minX, maxX) and x <= math.max(minX, maxX) and
            y >= math.min(minY, maxY) and y <= math.max(minY, maxY) and
            z >= math.min(minZ, maxZ) and z <= math.max(minZ, maxZ))
end

local function isInBounds(position)
    return isPlayerInRange(position)
end

-- Check if player has ANY Skin (Skin_1 to Skin_10)
local function hasAnySkin(player)
    local character = Workspace:FindFirstChild(player.Name)
    if character then
        for i = 1, 10 do
            if character:FindFirstChild("Skin_" .. i) then
                return true, "Skin_" .. i
            end
        end
    end
    return false, nil
end

-- Functions
local function createLaserBeam()
    local beam = Instance.new("Part")
    beam.Name = "LaserBeam"
    beam.Anchored = true
    beam.CanCollide = false
    beam.Material = Enum.Material.Neon
    beam.Shape = Enum.PartType.Cylinder
    beam.Size = Vector3.new(laserLength, laserThickness, laserThickness)
    beam.Transparency = 0.5
    beam.CastShadow = false
    beam.Parent = lasersFolder
    return beam
end

local function isLaserHittingMe(rightArm)
    if not rightArm then return false, 0 end
    local offsetCFrame = rightArm.CFrame * CFrame.new(-0.2, -1, -0.75)
    local armPosition = offsetCFrame.Position
    local rotatedCFrame = rightArm.CFrame * CFrame.Angles(math.rad(-90), 0, 0)
    local laserDirection = rotatedCFrame.LookVector

    local DETECTION_THICKNESS = 5

    local partsToCheck = {
        {part = HumanoidRootPart, name = "Body"},
        {part = Character:FindFirstChild("Head"), name = "Head"},
        {part = Character:FindFirstChild("Left Leg") or Character:FindFirstChild("LeftUpperLeg"), name = "Leg"},
        {part = Character:FindFirstChild("Right Leg") or Character:FindFirstChild("RightUpperLeg"), name = "Leg"}
    }

    local closestDistance = math.huge
    local hitPartName = nil

    for _, partData in pairs(partsToCheck) do
        if partData.part then
            local toPartPosition = partData.part.Position - armPosition
            local projectionLength = toPartPosition:Dot(laserDirection)

            if projectionLength >= 0 then
                local closestPointOnLaser = armPosition + (laserDirection * projectionLength)
                local perpendicularDistance = (partData.part.Position - closestPointOnLaser).Magnitude

                if perpendicularDistance < closestDistance then
                    closestDistance = perpendicularDistance
                    hitPartName = partData.name
                end
            end
        end
    end

    return closestDistance <= DETECTION_THICKNESS, closestDistance
end

local function updateLaserBeam(beam, rightArm, isDangerous)
    if not rightArm then 
        beam.Transparency = 1
        return 
    end
    local offsetCFrame = rightArm.CFrame * CFrame.new(-0.2, -1, -0.75)
    local startPos = offsetCFrame.Position
    local rotatedCFrame = rightArm.CFrame * CFrame.Angles(math.rad(-90), 0, 0)
    local direction = rotatedCFrame.LookVector
    local endPos = startPos + (direction * laserLength)
    local midPoint = (startPos + endPos) / 2
    beam.CFrame = CFrame.new(midPoint, endPos) * CFrame.Angles(0, math.rad(90), 0)
    beam.Size = Vector3.new(laserLength, laserThickness, laserThickness)
    if isDangerous then
        beam.Color = dangerColor
        beam.Transparency = 0.2
    else
        beam.Color = safeColor
        beam.Transparency = 0.6
    end
end

-- 🔥 AUTO RELOCATE FUNCTIONS
local function findSafeArea()
    if not isUnderThreat then
        return nil
    end

    local bestPosition = nil
    local bestScore = -math.huge
    local attempts = 50

    for i = 1, attempts do
        local randomX = math.random(math.min(minX, maxX) * 10, math.max(minX, maxX) * 10) / 10
        local randomY = math.random(math.min(minY, maxY) * 10, math.max(minY, maxY) * 10) / 10
        local randomZ = math.random(math.min(minZ, maxZ) * 10, math.max(minZ, maxZ) * 10) / 10

        local testPos = Vector3.new(randomX, randomY, randomZ)

        local minDistanceToThreat = math.huge
        local safeFromThreats = true

        -- Check distance from all threatening players
        for _, threat in pairs(threats) do
            if threat.player and threat.player.Character then
                local otherHRP = threat.player.Character:FindFirstChild("HumanoidRootPart")
                if otherHRP then
                    local distance = (testPos - otherHRP.Position).Magnitude
                    minDistanceToThreat = math.min(minDistanceToThreat, distance)

                    if distance < 10 then
                        safeFromThreats = false
                        break
                    end
                end
            end
        end

        if safeFromThreats then
            local score = minDistanceToThreat

            if score > bestScore then
                bestScore = score
                bestPosition = testPos
            end
        end
    end

    return bestPosition
end

local function moveToPosition(targetPos)
    if not Character or not HumanoidRootPart then return end
    Humanoid:MoveTo(targetPos)
    lastMoveTime = tick()
    return targetPos
end

local function stopMovement()
    if Humanoid then
        Humanoid:MoveTo(HumanoidRootPart.Position)
    end
end

local function isStuck()
    local currentPos = HumanoidRootPart.Position
    local distance = (currentPos - lastPosition).Magnitude

    if distance < 0.5 then
        stuckTime = stuckTime + updateRate
    else
        stuckTime = 0
    end

    lastPosition = currentPos
    return stuckTime >= stuckThreshold
end

-- Button Events
increaseBtn.MouseButton1Click:Connect(function()
    laserThickness = math.min(laserThickness + 0.5, 5)
    thicknessLabel.Text = "Current: " .. laserThickness .. " (2-5)"
end)

decreaseBtn.MouseButton1Click:Connect(function()
    laserThickness = math.max(laserThickness - 0.5, 2)
    thicknessLabel.Text = "Current: " .. laserThickness .. " (2-5)"
end)

resetBtn.MouseButton1Click:Connect(function()
    laserThickness = 3
    thicknessLabel.Text = "Current: " .. laserThickness .. " (2-5)"
end)

toggleBtn.MouseButton1Click:Connect(function()
    showOnlyDangerousLasers = not showOnlyDangerousLasers
    if showOnlyDangerousLasers then
        toggleBtn.Text = "🔴 Danger Only"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    else
        toggleBtn.Text = "🟢 Show All Lasers"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    end
end)

-- 🔥 AUTO RELOCATE TOGGLE BUTTON
autoRelocateBtn.MouseButton1Click:Connect(function()
    autoRelocateActive = not autoRelocateActive

    if autoRelocateActive then
        -- ON: Activate auto relocate + speed boost
        autoRelocateBtn.Text = "🟢 AUTO RELOCATE: ON"
        autoRelocateBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        Humanoid.WalkSpeed = 66
        print("🔥 Auto Relocate ACTIVATED - Speed: 66")
    else
        -- OFF: Deactivate + normal speed
        autoRelocateBtn.Text = "🔴 AUTO RELOCATE: OFF"
        autoRelocateBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        Humanoid.WalkSpeed = 16
        stopMovement()
        currentTarget = nil
        stuckTime = 0
        print("⏸️ Auto Relocate DEACTIVATED - Speed: 16")
    end
end)

local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Size = UDim2.new(0, 280, 0, 35)
        autoRelocateBtn.Visible = false
        statusFrame.Visible = false
        infoFrame.Visible = false
        settingsFrame.Visible = false
        toggleBtn.Visible = false
        miniIndicator.Visible = true
        titleLabel.Text = "🎯 Laser"
    else
        mainFrame.Size = UDim2.new(0, 280, 0, 350)
        autoRelocateBtn.Visible = true
        statusFrame.Visible = true
        infoFrame.Visible = true
        settingsFrame.Visible = true
        toggleBtn.Visible = true
        miniIndicator.Visible = false
        titleLabel.Text = "🎯 Laser Defense"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    lasersFolder:Destroy()
end)

-- Main Loop
local armedPlayers = 0
RunService.Heartbeat:Connect(function()
    if not Character or not Character.Parent then
        Character = LocalPlayer.Character
        if Character then
            HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
            Humanoid = Character:WaitForChild("Humanoid")
        else
            return
        end
    end

    threats = {}
    armedPlayers = 0
    local processedPlayers = {}
    local closestThreat = nil
    local closestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then

            local hasSkin, skinName = hasAnySkin(player)

            if not hasSkin then
                if laserBeams[player.UserId] then
                    laserBeams[player.UserId].Transparency = 1
                end
            else
                armedPlayers = armedPlayers + 1

                local rightArm = player.Character:FindFirstChild("Right Arm") 
                              or player.Character:FindFirstChild("RightHand")
                              or player.Character:FindFirstChild("RightUpperArm")

                local otherHRP = player.Character:FindFirstChild("HumanoidRootPart")

                if rightArm and otherHRP and isPlayerInRange(otherHRP.Position) then
                    local distance = (otherHRP.Position - HumanoidRootPart.Position).Magnitude

                    if distance <= detectionDistance then
                        local isDangerous, perpDist = isLaserHittingMe(rightArm)

                        if isDangerous then
                            table.insert(threats, {
                                player = player,
                                distance = distance,
                                perpDistance = perpDist,
                                skinName = skinName
                            })

                            if distance < closestDistance then
                                closestDistance = distance
                                closestThreat = threats[#threats]
                            end
                        end

                        if not laserBeams[player.UserId] then
                            laserBeams[player.UserId] = createLaserBeam()
                        end

                        local beam = laserBeams[player.UserId]

                        if showOnlyDangerousLasers and not isDangerous then
                            beam.Transparency = 1
                        else
                            updateLaserBeam(beam, rightArm, isDangerous)
                        end

                        processedPlayers[player.UserId] = true
                    end
                end
            end
        end
    end

    for userId, beam in pairs(laserBeams) do
        if not processedPlayers[userId] then
            beam.Transparency = 1
        end
    end

    -- Update GUI
    isUnderThreat = #threats > 0

    if isUnderThreat then
        statusFrame.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
        statusLabel.Text = "🚨 DANGER!"
        miniIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

        if closestThreat then
            subLabel.Text = string.format("%s aiming! %.1fs | %.1f°", 
                closestThreat.player.Name, 
                closestThreat.distance,
                closestThreat.perpDistance
            )
        end
        subLabel.TextColor3 = Color3.fromRGB(255, 200, 200)

        local flash = math.sin(tick() * 12) > 0
        if minimized then
            miniIndicator.BackgroundColor3 = flash and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(180, 0, 0)
        else
            statusFrame.BackgroundColor3 = flash and Color3.fromRGB(220, 0, 0) or Color3.fromRGB(180, 0, 0)
        end
    else
            statusFrame.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            statusLabel.Text = "✅ SAFE"
            subLabel.Text = "No lasers aimed"
            subLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
            miniIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            end

            threatLabel.Text = string.format("🎯 Aiming: %d", #threats)

            if closestThreat then
            closestLabel.Text = string.format("⚠️ Closest: %s (%.1fs)", closestThreat.player.Name, closestThreat.distance)
            else
            closestLabel.Text = "⚠️ Closest: None"
            end

            rangeLabel.Text = string.format("👥 Armed: %d", armedPlayers)

            -- 🔥 AUTO RELOCATE LOGIC
            if autoRelocateActive then
            if not isInBounds(HumanoidRootPart.Position) then
                stopMovement()
            elseif isUnderThreat then
                local needsToMove = false
                if isStuck() or (tick() - lastMoveTime > moveTimeout and currentTarget) then
                    needsToMove = true
                else
                    needsToMove = true
                end
                if needsToMove then
                    local safePos = findSafeArea()
                    if safePos then
                        currentTarget = safePos
                        moveToPosition(currentTarget)
                    else
                        stopMovement()
                    end
                    stuckTime = 0
                end
            else
                stopMovement()
            end
            end

            task.wait(updateRate)
            end)

            -- Cleanup
            Players.PlayerRemoving:Connect(function(player)
            if laserBeams[player.UserId] then
            laserBeams[player.UserId]:Destroy()
            laserBeams[player.UserId] = nil
            end
            end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    Humanoid = Character:WaitForChild("Humanoid")
    lastPosition = HumanoidRootPart.Position
    if autoRelocateActive then
        Humanoid.WalkSpeed = 66
    else
        Humanoid.WalkSpeed = 16
    end
end)

-- 🔥 SPEED CHECKER: Har 3 second pe speed verify karo
task.spawn(function()
    while true do
        task.wait(3)  -- 3 second delay
        if Character and Humanoid then
            if autoRelocateActive then
                if Humanoid.WalkSpeed ~= 66 then
                    Humanoid.WalkSpeed = 66
                    print("🔥 Speed corrected: 66")
                end
            else
                if Humanoid.WalkSpeed ~= 16 then
                    Humanoid.WalkSpeed = 16
                    print("⏸️ Speed corrected: 16")
                end
            end
        end
    end
end)

            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🛡️ MERGED LASER DEFENSE LOADED")
            print("🎯 Laser Detection + Auto Relocate")
            print("🔥 Toggle 'AUTO RELOCATE' to activate!")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
