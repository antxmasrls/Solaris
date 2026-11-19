local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local DraggableLabel = Library:AddDraggableLabel("Solaris.lol")
DraggableLabel:SetVisible(true)

local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end

    DraggableLabel:SetText(('Solaris.lol | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ))
end)

local Window = Library:CreateWindow({
	Title = "Solaris.lol",
	Footer = "",
	Icon = 133875143937220,
	NotifySide = "Right",
	ShowCustomCursor = false,
    IconSize = UDim2.fromOffset(42, 42),
    Size = UDim2.fromOffset(680, 450),
})

-- ////////////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////Main///////////////////////////////////////////////

local MainTab = Window:AddTab({
    Name = "Main",
    Description = "",
    Icon = "crosshair",
    Tooltip = "Sheriff & Combat features",
})

local SheriffGroupbox = MainTab:AddGroupbox({
    Side = "Left",
    Name = "Sheriff Combat",
    Description = "",
    IconName = "crosshair",
    DisableCollapsing = true,
})

local AimbotToggle = SheriffGroupbox:AddToggle("Aimbot", {
    Text = "Aimbot",
    Default = false,
})

_G.SheriffOnly = true 
_G.HitPart = "HumanoidRootPart"
_G.WallCheck = false
_G.DeadCheck = false
_G.espenabled = false
_G.CSwareIsFlinging = false

local function IsLocalSheriff()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    if not LocalPlayer.Character then return false end

    local function checkTool(tool)
        if not tool or not tool:IsA("Tool") then return false end
        local name = tool.Name:lower()
        return name:find("gun") or name:find("revolver") or name:find("sheriff")
    end

    local currentTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if checkTool(currentTool) then
        return true
    end

    if LocalPlayer:FindFirstChild("Backpack") then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if checkTool(item) then
                    return true
                end
            end
        end
    end

    return false
end

local function IsVisible(targetPart)
    if not _G.WallCheck then return true end
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then return false end

    local origin = LocalPlayer.Character.Head.Position
    local direction = targetPart.Position - origin

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = { LocalPlayer.Character, targetPart.Parent }
    raycastParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, raycastParams)
    return result == nil
end

local function GetMurderer()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0 then
            if _G.DeadCheck and Player.Character.Humanoid.Health <= 0 then
                continue
            end

            local isMurderer = false

            local backpack = Player:FindFirstChild("Backpack")
            if backpack then
                for _, item in ipairs(backpack:GetChildren()) do
                    if item.Name == "Knife" or item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("cutter")) then
                        isMurderer = true
                        break
                    end
                end
            end

            local tool = Player.Character:FindFirstChildOfClass("Tool")
            if tool then
                if tool.Name == "Knife" or tool.Name:lower():find("knife") or tool.Name:lower():find("cutter") then
                    isMurderer = true
                end
            end

            if isMurderer then
                local targetPart = Player.Character:FindFirstChild(_G.HitPart)
                if targetPart and IsVisible(targetPart) then
                    return Player
                end
            end
        end
    end
    return nil
end

Toggles.Aimbot:OnChanged(function(state)
    Library:Notify({ Title = "Aimbot", Description = state and "Aimbot Enabled" or "Aimbot Disabled", Time = 4 })
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local Camera = Workspace.CurrentCamera

    local AimbotConnection
    if state then
        AimbotConnection = RunService.RenderStepped:Connect(function()
            if not Toggles.Aimbot or not Toggles.Aimbot.Value then
                if AimbotConnection then AimbotConnection:Disconnect() end
                return
            end

            if _G.SheriffOnly and not IsLocalSheriff() then
                return
            end

            local TargetPlayer = GetMurderer()
            if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild(_G.HitPart) then
                local TargetPart = TargetPlayer.Character[_G.HitPart]
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, TargetPart.Position)
            end
        end)
    end
end)

SheriffGroupbox:AddToggle("WallCheck", {
    Text = "Wallcheck",
    Default = false,
}):OnChanged(function(state)
    Library:Notify({ Title = "Wallcheck", Description = state and "Wallcheck Enabled" or "Wallcheck Disabled", Time = 4 })
    _G.WallCheck = state
end)

SheriffGroupbox:AddToggle("DeadCheck", {
    Text = "Deadcheck",
    Default = false,
}):OnChanged(function(state)
    Library:Notify({ Title = "Deadcheck", Description = state and "Deadcheck Enabled" or "Deadcheck Disabled", Time = 4 })
    _G.DeadCheck = state
end)

local HitPartDropdown = SheriffGroupbox:AddDropdown("HitPart", {
    Text = "HitPart",
    Values = { "HumanoidRootPart", "Head" },
    Default = 1,
    Multi = false,
})
HitPartDropdown:OnChanged(function(value)
    Library:Notify({ Title = "HitPart", Description = "HitPart set to: " .. tostring(value), Time = 4 })
    _G.HitPart = HitPartDropdown.Value
end)
_G.HitPart = HitPartDropdown.Value

SheriffGroupbox:AddDivider()

local SilentToggle = SheriffGroupbox:AddToggle("SilentToggle", {
    Text = "Silent Aim",
    Default = false,
})
Toggles.SilentToggle:OnChanged(function(state)
Library:Notify({ Title = "Silent Aim", Description = state and "Silent Aim Enabled" or "Silent Aim Disabled", Time = 4 })
_G.VertexSilentAim = state

if _G.VertexSilentAim then
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    if getgenv().VertexSilentAimCleanup then
        pcall(getgenv().VertexSilentAimCleanup)
    end
    
    local shootConnection
    getgenv().VertexSilentAimCleanup = function()
        if shootConnection then
            shootConnection:Disconnect()
            shootConnection = nil
        end
    end

    task.spawn(function()
        while _G.VertexSilentAim do
            task.wait(0.5)
            pcall(function()
                local character = LocalPlayer.Character
                if not character then return end

                local gun = character:FindFirstChild("Gun")

                if not gun and shootConnection then
                    shootConnection:Disconnect()
                    shootConnection = nil
                end

                local function getMurderer()
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Backpack:FindFirstChild("Knife") or (p.Character and p.Character:FindFirstChild("Knife")) then
                            return p.Name
                        end
                    end
                    return nil
                end

                if gun and not shootConnection then
                    shootConnection = gun.Activated:Connect(function()
                        local murdererName = Murderer or getMurderer()
                        local murdererPlayer = murdererName and Players:FindFirstChild(tostring(murdererName))
                        if not murdererPlayer or not murdererPlayer.Character then return end

                        local Root = murdererPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if not Root then return end

                        local ohCFrame1
                        local hrp = character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local rootAttachment = hrp:FindFirstChild("RootAttachment")
                            if rootAttachment then
                                ohCFrame1 = rootAttachment.WorldCFrame
                            else
                                ohCFrame1 = hrp.CFrame
                            end
                        else
                            ohCFrame1 = character:GetPrimaryPartCFrame()
                        end

                        local ohCFrame2 = Root.CFrame
                        local gunObj = character:FindFirstChild("Gun")
                        if gunObj and gunObj:FindFirstChild("Shoot") then
                            gunObj.Shoot:FireServer(ohCFrame1, ohCFrame2)
                        end
                    end)
                end
            end)
        end
    end)
else
    if getgenv().VertexSilentAimCleanup then
        pcall(getgenv().VertexSilentAimCleanup)
        getgenv().VertexSilentAimCleanup = nil
    end
end
end)

SheriffGroupbox:AddButton({
    Text = "Shoot Murderer",
    Func = function()
    Library:Notify({ Title = "Combat", Description = "Shooting the Murderer!", Time = 4 })
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local function Fetch(itemName)
        for _, player in ipairs(Players:GetPlayers()) do 
            if player.Backpack:FindFirstChild(itemName) or (player.Character and player.Character:FindFirstChild(itemName)) then
                return player.Name
            end
        end   
        return nil 
    end

    local function Equip(toolName)
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local tool = LocalPlayer.Backpack:FindFirstChild(toolName)

        if humanoid and tool then
            humanoid:EquipTool(tool)
        end
    end

    local function ShootOnce()
        local Murderer = Fetch("Knife")
        local player = LocalPlayer
        if not player then return end

        local Gun = nil
        if player:FindFirstChild("Backpack") then
            Gun = player.Backpack:FindFirstChild("Gun")
        end
        if not Gun and player.Character then
            Gun = player.Character:FindFirstChild("Gun")
        end
        if not Gun then return end

        if not Murderer then return end
        local murderer = Players:FindFirstChild(Murderer)
        if not murderer or not murderer.Character then return end

        local murdererHRP = murderer.Character:FindFirstChild("HumanoidRootPart")
        local murdererHum = murderer.Character:FindFirstChild("Humanoid")
        if not murdererHRP or not murdererHum then return end

        local velocity = murdererHRP.AssemblyLinearVelocity or Vector3.new(0,0,0)
        local moveDir = murdererHum.MoveDirection or Vector3.new(0,0,0)
        local predictedPos = murdererHRP.Position + (velocity * Vector3.new(0, 0.5, 0)) * (2.8 / 15) + moveDir * 2.8
        local ohCFrame1
        local ohCFrame2 = CFrame.new(predictedPos)

        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local gunShoulder = hrp:FindFirstChild("GunShoulderAttachment")
        if gunShoulder then
            ohCFrame1 = gunShoulder.WorldCFrame
        else
            ohCFrame1 = hrp.CFrame
        end

        if Gun and Gun:FindFirstChild("Handle") then
            local handle = Gun.Handle
            if handle:FindFirstChild("Reload") and not handle.Reload.Playing then
                local shootEvent = workspace:FindFirstChild(player.Name) and workspace[player.Name]:FindFirstChild("Gun") and workspace[player.Name].Gun:FindFirstChild("Shoot")
                if shootEvent then
                    Equip("Gun")
                    task.wait(0.05)
                    shootEvent:FireServer(ohCFrame1, ohCFrame2)
                end
            end
        end
    end

    ShootOnce()
    end
})

local AutoShootToggle = SheriffGroupbox:AddToggle("AutoShootToggle", {
    Text = "Auto Shoot",
    Default = false,
})
Toggles.AutoShootToggle:OnChanged(function(state)
Library:Notify({ Title = "Auto Shoot", Description = state and "Auto Shoot Enabled" or "Auto Shoot Disabled", Time = 4 })
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

shared.AutoShootActive = state

if not shared.AutoShootActive then
    return
end

local function Fetch(itemName)
    for _, player in ipairs(Players:GetPlayers()) do 
        if player.Backpack:FindFirstChild(itemName) or (player.Character and player.Character:FindFirstChild(itemName)) then
            return player.Name
        end
    end   
    return nil 
end

local function Equip(toolName)
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local tool = LocalPlayer.Backpack:FindFirstChild(toolName)

    if humanoid and tool then
        humanoid:EquipTool(tool)
    end
end

local function isPlayerVisible(player)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local targetHRP = player.Character.HumanoidRootPart
        local rayDirection = (targetHRP.Position - rootPart.Position).Unit * 50
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        
        local hit = workspace:Raycast(rootPart.Position, rayDirection, raycastParams)
        return not hit or hit.Instance.Parent == player.Character
    end
    
    return false
end

local function ShootMurderer(Murderer)
    local murdererName = Murderer
    local player = LocalPlayer
    if not player then return end

    local Gun = nil
    if player:FindFirstChild("Backpack") then
        Gun = player.Backpack:FindFirstChild("Gun")
    end
    if not Gun and player.Character then
        Gun = player.Character:FindFirstChild("Gun")
    end
    if not Gun then return end

    if not murdererName then return end
    local murderer = Players:FindFirstChild(murdererName)
    if not murderer or not murderer.Character then return end

    local murdererHRP = murderer.Character:FindFirstChild("HumanoidRootPart")
    local murdererHum = murderer.Character:FindFirstChild("Humanoid")
    if not murdererHRP or not murdererHum then return end

    local velocity = murdererHRP.AssemblyLinearVelocity or Vector3.new(0,0,0)
    local moveDir = murdererHum.MoveDirection or Vector3.new(0,0,0)
    local predictedPos = murdererHRP.Position + (velocity * Vector3.new(0, 0.5, 0)) * (2.8 / 15) + moveDir * 2.8
    local ohCFrame1
    local ohCFrame2 = CFrame.new(predictedPos)

    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local gunShoulder = hrp:FindFirstChild("GunShoulderAttachment")
    if gunShoulder then
        ohCFrame1 = gunShoulder.WorldCFrame
    else
        ohCFrame1 = hrp.CFrame
    end

    if Gun and Gun:FindFirstChild("Handle") then
        local handle = Gun.Handle
        if handle:FindFirstChild("Reload") and not handle.Reload.Playing then
            local shootEvent = workspace:FindFirstChild(player.Name) and workspace[player.Name]:FindFirstChild("Gun") and workspace[player.Name].Gun:FindFirstChild("Shoot")
            if shootEvent then
                shootEvent:FireServer(ohCFrame1, ohCFrame2)
            end
        end
    end
end

task.spawn(function()
    while shared.AutoShootActive do
        task.wait()
        pcall(function()
            local Murderer = Fetch("Knife")
            local Sheriff = Fetch("Gun")

            if Murderer and Sheriff and Sheriff == LocalPlayer.Name then
                local murderer = Players:FindFirstChild(Murderer)

                if murderer and isPlayerVisible(murderer) then
                    Equip("Gun")
                    ShootMurderer(Murderer) 
                end
            end
        end)
    end
end)
end)

SheriffGroupbox:AddButton({
    Text = "Kill Murderer",
    Func = function()
  Library:Notify({ Title = "Combat", Description = "Executing Kill Murderer sequence!", Time = 4 })
  task.spawn(function()
    pcall(function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local RS = game:GetService("ReplicatedStorage")
        local LocalPlayer = Players.LocalPlayer

        local CRC
        pcall(function() CRC = require(RS:WaitForChild("Modules"):WaitForChild("CurrentRoundClient")) end)

        local function roundData(plr)
            return CRC and CRC.PlayerData and CRC.PlayerData[plr.Name]
        end

        local function getHRP(ch)
            return ch and ch:FindFirstChild("HumanoidRootPart")
        end

        local function charHasWeapon(ch, kind)
            for _, t in ipairs(ch:GetChildren()) do
                if t:IsA("Tool") then
                    if kind == "Gun" and (t.Name == "Gun" or t:FindFirstChild("Shoot")) then return true end
                    if kind == "Knife" and (t.Name == "Knife" or t:FindFirstChild("Events")) then return true end
                end
            end
            return false
        end

        local function roleOf(plr)
            local d = roundData(plr)
            local r = d and d.Role
            if r == "Murderer" then return "Murderer" end
            if r == "Sheriff" or r == "Hero" then return r end
            local ch = plr.Character
            local bp = plr:FindFirstChildOfClass("Backpack")
            if (ch and charHasWeapon(ch, "Gun")) or (bp and bp:FindFirstChild("Gun")) then return "Hero" end
            if (ch and charHasWeapon(ch, "Knife")) or (bp and bp:FindFirstChild("Knife")) then return "Murderer" end
            return r or "Innocent"
        end

        local function alive(plr)
            local d = roundData(plr)
            if d and d.Dead == true then return false end
            local ch = plr.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            return ch and hum and hum.Health > 0 and getHRP(ch) ~= nil
        end

        local function findMurderer()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and roleOf(p) == "Murderer" then
                    return p
                end
            end
            return nil
        end

        local function findWeapon(name)
            local ch = LocalPlayer.Character
            local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
            return (ch and ch:FindFirstChild(name)) or (bp and bp:FindFirstChild(name))
        end

        local function equip(tool)
            local ch = LocalPlayer.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if tool and hum and tool.Parent ~= ch then
                pcall(function() hum:EquipTool(tool) end)
            end
        end

        local SNAP_HEIGHT = 5
        local shotLag = 0.08

        local function gunOrigin()
            local ch = LocalPlayer.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hrp then return nil end
            local att = hrp:FindFirstChild("GunRaycastAttachment")
            if att then return att.WorldCFrame end
            return hrp.CFrame
        end

        local function aimPoint(ch)
            local part = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("UpperTorso")
                or ch:FindFirstChild("Torso") or ch:FindFirstChild("Head")
            return part and part.Position
        end

        local gun = findWeapon("Gun")
        if not gun then
            return
        end

        local target = findMurderer()
        if not target or not alive(target) then
            return
        end

        local myHrp = getHRP(LocalPlayer.Character)
        local tChar = target.Character
        local tHrp = tChar and getHRP(tChar)
        if not (myHrp and tHrp) then return end

        local shoot = gun:FindFirstChild("Shoot")
        if not shoot then return end

        local home = myHrp.CFrame
        local homeVel = myHrp.AssemblyLinearVelocity
        local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local homeState = myHum and myHum:GetState() or nil

        equip(gun)
        local deadline = os.clock() + 0.4
        while os.clock() < deadline do
            local h = getHRP(LocalPlayer.Character)
            if h and h:FindFirstChild("GunRaycastAttachment") then break end
            RunService.Heartbeat:Wait()
        end

        local aim = aimPoint(tChar)
        if not aim then return end

        local side = home.Position - aim
        side = Vector3.new(side.X, 0, side.Z)
        if side.Magnitude < 0.5 then
            local lv = tHrp.CFrame.LookVector
            side = Vector3.new(lv.X, 0, lv.Z)
        end
        if side.Magnitude < 0.5 then side = Vector3.new(0, 0, 1) end
        side = side.Unit

        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { tChar, LocalPlayer.Character }
        if workspace:Raycast(aim, side * SNAP_HEIGHT, rp) then side = -side end
        local relOff = side * SNAP_HEIGHT

        local chest = aim
        local lagT = math.clamp(shotLag, 0.03, 0.25)
        local preLock = math.clamp(lagT * 1.5, 0.12, 0.35)

        local t0 = os.clock()
        repeat
            local h = getHRP(LocalPlayer.Character)
            local tr = target.Character and getHRP(target.Character)
            if not (h and tr) then break end
            local nxt = aimPoint(target.Character)
            if nxt and (nxt - chest).Magnitude > 60 then break end
            chest = nxt or chest
            h.CFrame = CFrame.new(chest + relOff, chest)
            h.AssemblyLinearVelocity = Vector3.zero
            h.AssemblyAngularVelocity = Vector3.zero
            RunService.Heartbeat:Wait()
        until os.clock() - t0 >= preLock

        local origin = gunOrigin()
        if origin then
            local tr2 = target.Character and getHRP(target.Character)
            local vel = tr2 and tr2.AssemblyLinearVelocity or Vector3.zero
            shoot:FireServer(origin, CFrame.new(chest + vel * lagT))
        end

        RunService.Heartbeat:Wait()
        local h3 = getHRP(LocalPlayer.Character)
        if h3 then
            h3.CFrame = home
            h3.AssemblyLinearVelocity = homeVel
            h3.AssemblyAngularVelocity = Vector3.zero
        end
        if myHum then
            if homeState and homeState ~= Enum.HumanoidStateType.Dead then
                pcall(function() myHum:ChangeState(homeState) end)
            else
                pcall(function() myHum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            end
            pcall(function() myHum:Move(myHum.MoveDirection, false) end)
        end
    end)
end)
    end
})

local AutoKillMurdToggle = SheriffGroupbox:AddToggle("AutoKillMurdToggle", {
    Text = "Auto Kill Murderer",
    Default = false,
})
Toggles.AutoKillMurdToggle:OnChanged(function(state)
Library:Notify({ Title = "Auto Kill Murderer", Description = state and "Auto Kill Murderer Enabled" or "Auto Kill Murderer Disabled", Time = 4 })
_G.CSwareAutoKillLoop = state

if _G.CSwareAutoKillLoop then
    task.spawn(function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local RS = game:GetService("ReplicatedStorage")
        local LocalPlayer = Players.LocalPlayer

        local CRC
        pcall(function() CRC = require(RS:WaitForChild("Modules"):WaitForChild("CurrentRoundClient")) end)

        local function roundData(plr)
            return CRC and CRC.PlayerData and CRC.PlayerData[plr.Name]
        end

        local function getHRP(ch)
            return ch and ch:FindFirstChild("HumanoidRootPart")
        end

        local function charHasWeapon(ch, kind)
            for _, t in ipairs(ch:GetChildren()) do
                if t:IsA("Tool") then
                    if kind == "Gun" and (t.Name == "Gun" or t:FindFirstChild("Shoot")) then return true end
                    if kind == "Knife" and (t.Name == "Knife" or t:FindFirstChild("Events")) then return true end
                end
            end
            return false
        end

        local function roleOf(plr)
            local d = roundData(plr)
            local r = d and d.Role
            if r == "Murderer" then return "Murderer" end
            if r == "Sheriff" or r == "Hero" then return r end
            local ch = plr.Character
            local bp = plr:FindFirstChildOfClass("Backpack")
            if (ch and charHasWeapon(ch, "Gun")) or (bp and bp:FindFirstChild("Gun")) then return "Hero" end
            if (ch and charHasWeapon(ch, "Knife")) or (bp and bp:FindFirstChild("Knife")) then return "Murderer" end
            return r or "Innocent"
        end

        local function alive(plr)
            local d = roundData(plr)
            if d and d.Dead == true then return false end
            local ch = plr.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            return ch and hum and hum.Health > 0 and getHRP(ch) ~= nil
        end

        local function findMurderer()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and roleOf(p) == "Murderer" then
                    return p
                end
            end
            return nil
        end

        local function findWeapon(name)
            local ch = LocalPlayer.Character
            local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
            return (ch and ch:FindFirstChild(name)) or (bp and bp:FindFirstChild(name))
        end

        local function equip(tool)
            local ch = LocalPlayer.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if tool and hum and tool.Parent ~= ch then
                pcall(function() hum:EquipTool(tool) end)
            end
        end

        local SNAP_HEIGHT = 5
        local GUN_COOLDOWN = 3.25
        local snapAt = -10
        local shotLag = 0.08
        local snapping = false

        local function gunOrigin()
            local ch = LocalPlayer.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hrp then return nil end
            local att = hrp:FindFirstChild("GunRaycastAttachment")
            if att then return att.WorldCFrame end
            return hrp.CFrame
        end

        local function aimPoint(ch)
            local part = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("UpperTorso")
                or ch:FindFirstChild("Torso") or ch:FindFirstChild("Head")
            return part and part.Position
        end

        local function gunBusy(lead)
            local gun = findWeapon("Gun")
            if not gun then return false end
            if os.clock() - snapAt < GUN_COOLDOWN - (lead or 0) then return true end
            return false
        end

        local gfConn
        pcall(function()
            local cs = RS:FindFirstChild("ClientServices")
            local ws = cs and cs:FindFirstChild("WeaponService")
            local gf = ws and ws:FindFirstChild("GunFired")
            if gf and gf:IsA("RemoteEvent") then
                gfConn = gf.OnClientEvent:Connect(function(handle)
                    local ch = LocalPlayer.Character
                    if ch and typeof(handle) == "Instance" and handle:IsDescendantOf(ch) then
                        local rt = os.clock() - snapAt
                        if rt > 0 and rt < 1.5 then
                            shotLag = shotLag * 0.7 + rt * 0.3
                        end
                        snapAt = os.clock()
                    end
                end)
            end
        end)

        local function snapShot(target)
            if snapping or not _G.CSwareAutoKillLoop then return false end
            local lagT = math.clamp(shotLag, 0.03, 0.25)
            local preLock = math.clamp(lagT * 1.5, 0.12, 0.35)
            if gunBusy(preLock) then return false end

            local gun = findWeapon("Gun")
            if not gun then return false end
            local shoot = gun:FindFirstChild("Shoot")
            if not shoot then return false end

            local myHrp = getHRP(LocalPlayer.Character)
            local tChar = target and target.Character
            local tHrp = tChar and getHRP(tChar)
            if not (myHrp and tHrp and alive(LocalPlayer)) then return false end

            snapping = true
            local home = myHrp.CFrame
            local homeVel = myHrp.AssemblyLinearVelocity
            local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            local homeState = myHum and myHum:GetState() or nil
            local fired = false

            pcall(function()
                equip(gun)
                local deadline = os.clock() + 0.4
                while os.clock() < deadline and _G.CSwareAutoKillLoop do
                    local h = getHRP(LocalPlayer.Character)
                    if h and h:FindFirstChild("GunRaycastAttachment") then break end
                    RunService.Heartbeat:Wait()
                end

                local aim = aimPoint(tChar)
                if not aim then return end

                local side = home.Position - aim
                side = Vector3.new(side.X, 0, side.Z)
                if side.Magnitude < 0.5 then
                    local lv = tHrp.CFrame.LookVector
                    side = Vector3.new(lv.X, 0, lv.Z)
                end
                if side.Magnitude < 0.5 then side = Vector3.new(0, 0, 1) end
                side = side.Unit

                local rp = RaycastParams.new()
                rp.FilterType = Enum.RaycastFilterType.Exclude
                rp.FilterDescendantsInstances = { tChar, LocalPlayer.Character }
                if workspace:Raycast(aim, side * SNAP_HEIGHT, rp) then side = -side end
                local relOff = side * SNAP_HEIGHT

                local chest = aim
                local function lockOn(dur)
                    local t0 = os.clock()
                    repeat
                        if not _G.CSwareAutoKillLoop then return false end
                        local h = getHRP(LocalPlayer.Character)
                        local tr = target.Character and getHRP(target.Character)
                        if not (h and tr) then return false end
                        local nxt = aimPoint(target.Character)
                        if nxt and (nxt - chest).Magnitude > 60 then return false end
                        chest = nxt or chest
                        h.CFrame = CFrame.new(chest + relOff, chest)
                        h.AssemblyLinearVelocity = Vector3.zero
                        h.AssemblyAngularVelocity = Vector3.zero
                        RunService.Heartbeat:Wait()
                    until os.clock() - t0 >= dur
                    return true
                end

                if not lockOn(preLock) then return end

                local origin = gunOrigin()
                if origin then
                    local tr2 = target.Character and getHRP(target.Character)
                    local vel = tr2 and tr2.AssemblyLinearVelocity or Vector3.zero
                    shoot:FireServer(origin, CFrame.new(chest + vel * lagT))
                    snapAt = os.clock()
                    fired = true
                    lockOn(math.clamp(lagT * 2, 0.16, 0.5))
                end
            end)

            RunService.Heartbeat:Wait()
            local h3 = getHRP(LocalPlayer.Character)
            if h3 then
                h3.CFrame = home
                h3.AssemblyLinearVelocity = homeVel
                h3.AssemblyAngularVelocity = Vector3.zero
            end
            local hum3 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum3 then
                if homeState and homeState ~= Enum.HumanoidStateType.Dead then
                    pcall(function() hum3:ChangeState(homeState) end)
                else
                    pcall(function() hum3:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                end
                pcall(function() hum3:Move(hum3.MoveDirection, false) end)
            end
            snapping = false
            return fired
        end

        while _G.CSwareAutoKillLoop do
            pcall(function()
                local role = roleOf(LocalPlayer)
                if (role == "Sheriff" or role == "Hero" or findWeapon("Gun") ~= nil) and role ~= "Murderer" then
                    local m = findMurderer()
                    if m and alive(m) then
                        snapShot(m)
                    end
                end
            end)
            task.wait(0.05)
        end

        if gfConn then
            pcall(function() gfConn:Disconnect() end)
        end
    end)
end
end)

local MurdererGroupbox = MainTab:AddGroupbox({
    Side = "Right",
    Name = "Murderer Combat",
    Description = "",
    IconName = "knife",
    DisableCollapsing = true
})

MurdererGroupbox:AddButton({
    Text = "Kill All",
    Func = function()
    Library:Notify({ Title = "Murderer", Description = "Executing Kill All action!", Time = 4 })
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local CollectionService = game:GetService("CollectionService")
    local LocalPlayer = Players.LocalPlayer

    local CRC
    pcall(function()
        CRC = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))
    end)

    local KNIFE_PARTS = {"HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso", "Head"}

    local function isAlive(plr)
        local d = CRC and CRC.PlayerData and CRC.PlayerData[plr.Name]
        if d and d.Dead == true then return false end
        local ch = plr.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        return ch and hum and hum.Health > 0 and ch:FindFirstChild("HumanoidRootPart") ~= nil
    end

    local function amIMurderer()
        local d = CRC and CRC.PlayerData and CRC.PlayerData[LocalPlayer.Name]
        if d and d.Role == "Murderer" then return true end

        local ch = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if (ch and ch:FindFirstChild("Knife")) or (bp and bp:FindFirstChild("Knife")) then
            return true
        end

        for _, t in ipairs(CollectionService:GetTagged("Weapon_Knife")) do
            if t.Parent == ch or t.Parent == bp then
                return true
            end
        end
        return false
    end

    local function getAndEquipKnife()
        local ch = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        local knife = (ch and ch:FindFirstChild("Knife")) or (bp and bp:FindFirstChild("Knife"))
        if knife and ch and knife.Parent ~= ch then
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function() hum:EquipTool(knife) end)
            end
        end
        return knife
    end

    local function knifeKill(ev, targetChar)
        if not (ev and targetChar) then return end
        local ht = ev:FindFirstChild("HandleTouched")
        local ks = ev:FindFirstChild("KnifeStabbed")
        if not ht then return end
        
        if ks then ks:FireServer() end
        for _, pn in ipairs(KNIFE_PARTS) do
            local part = targetChar:FindFirstChild(pn)
            if part then
                ht:FireServer(part)
                return
            end
        end
    end

    task.spawn(function()
        if amIMurderer() and isAlive(LocalPlayer) then
            local knife = getAndEquipKnife()
            local ev = knife and knife:FindFirstChild("Events")
            if ev then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and isAlive(plr) and plr.Character then
                        knifeKill(ev, plr.Character)
                    end
                end
            end
        end
    end)
    end
})

local AutoKillAllToggle = MurdererGroupbox:AddToggle("AutoKillAllToggle", {
    Text = "Auto Kill All",
    Default = false,
})
Toggles.AutoKillAllToggle:OnChanged(function(state)
Library:Notify({ Title = "Auto Kill All", Description = state and "Auto Kill All Enabled" or "Auto Kill All Disabled", Time = 4 })
getgenv().KillAll = state

if not getgenv().KillAll then return end
if getgenv().MM2_KillAll_Running then return end
getgenv().MM2_KillAll_Running = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

local CRC
pcall(function()
    CRC = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))
end)

local KNIFE_PARTS = {"HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso", "Head"}

local function isAlive(plr)
    local d = CRC and CRC.PlayerData and CRC.PlayerData[plr.Name]
    if d and d.Dead == true then return false end
    local ch = plr.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    return ch and hum and hum.Health > 0 and ch:FindFirstChild("HumanoidRootPart") ~= nil
end

local function amIMurderer()
    local d = CRC and CRC.PlayerData and CRC.PlayerData[LocalPlayer.Name]
    if d and d.Role == "Murderer" then return true end

    local ch = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if (ch and ch:FindFirstChild("Knife")) or (bp and bp:FindFirstChild("Knife")) then
        return true
    end

    for _, t in ipairs(CollectionService:GetTagged("Weapon_Knife")) do
        if t.Parent == ch or t.Parent == bp then
            return true
        end
    end
    return false
end

local function getAndEquipKnife()
    local ch = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    local knife = (ch and ch:FindFirstChild("Knife")) or (bp and bp:FindFirstChild("Knife"))
    if knife and ch and knife.Parent ~= ch then
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() hum:EquipTool(knife) end)
        end
    end
    return knife
end

local function knifeKill(ev, targetChar)
    if not (ev and targetChar) then return end
    local ht = ev:FindFirstChild("HandleTouched")
    local ks = ev:FindFirstChild("KnifeStabbed")
    if not ht then return end
    
    if ks then ks:FireServer() end
    for _, pn in ipairs(KNIFE_PARTS) do
        local part = targetChar:FindFirstChild(pn)
        if part then
            ht:FireServer(part)
            return
        end
    end
end

task.spawn(function()
    while true do
        if not getgenv().KillAll then
            getgenv().MM2_KillAll_Running = nil
            break
        end
        if amIMurderer() and isAlive(LocalPlayer) then
            local knife = getAndEquipKnife()
            local ev = knife and knife:FindFirstChild("Events")
            if ev then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if not getgenv().KillAll then break end
                    if plr ~= LocalPlayer and isAlive(plr) and plr.Character then
                        knifeKill(ev, plr.Character)
                    end
                end
            end
            task.wait(0.05)
        else
            task.wait(0.15)
        end
    end
end)
end)

MurdererGroupbox:AddDivider()

local InstantThrowToggle = MurdererGroupbox:AddToggle("InstantThrowToggle", {
    Text = "Instant Knife Throw",
    Default = false,
})
Toggles.InstantThrowToggle:OnChanged(function(state)
    Library:Notify({ Title = "Instant Knife Throw", Description = state and "Instant Knife Throw Enabled" or "Instant Knife Throw Disabled", Time = 4 })
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    _G.CSwareInstantKnife = state

    if not _G.CSwareInstantKnife then
        if _G.CSwareKnifeConnection then
            _G.CSwareKnifeConnection:Disconnect()
            _G.CSwareKnifeConnection = nil
        end
        return
    end

    local function throwKnifeNow()
        local ch = LocalPlayer.Character
        if not ch then return false end
        
        local knife = ch:FindFirstChild("Knife")
        if not knife then
            local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
            local stowed = bp and bp:FindFirstChild("Knife")
            if stowed then
                local hum = ch:FindFirstChildOfClass("Humanoid")
                if hum then pcall(function() hum:EquipTool(stowed) end) end
                knife = ch:FindFirstChild("Knife") or stowed
            end
        end
        
        if not knife then return false end
        local ev = knife:FindFirstChild("Events")
        local thrown = ev and ev:FindFirstChild("KnifeThrown")
        if not thrown then return false end
        
        if knife:GetAttribute("Disabled") == true then return false end
        
        local Camera = workspace.CurrentCamera
        local mouseLocation = game:GetService("UserInputService"):GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
        local target = ray.Origin + ray.Direction.Unit * 300
        
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        
        local d = target - hrp.Position
        d = (d.Magnitude > 0.1) and d.Unit or Vector3.new(0, 0, -1)
        
        local handle = knife:FindFirstChild("Handle")
        local origin = handle and handle.CFrame or CFrame.new(target - d * 0.6, target)
        
        thrown:FireServer(origin, CFrame.new(target))
        return true
    end

    local UserInputService = game:GetService("UserInputService")
    _G.CSwareKnifeConnection = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 and _G.CSwareInstantKnife and Toggles.InstantThrowToggle.Value then
            throwKnifeNow()
        end
    end)
end)

local InnoLeftGroupbox = MainTab:AddGroupbox({
    Side = "Right",
    Name = "Innocent Tools",
    Description = "",
    IconName = "shield",
    DisableCollapsing = true,
})

InnoLeftGroupbox:AddButton({
    Text = "Grab Gun",
    Func = function()
        Library:Notify({ Title = "Innocent Tools", Description = "Teleporting to gun drop!", Time = 4 })
        local Players = game:GetService("Players")
        local Workspace = game:GetService("Workspace")
        local LocalPlayer = Players.LocalPlayer

        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")

        if rootPart then
            local gunDrop = Workspace:FindFirstChild("GunDrop", true)

            if gunDrop and gunDrop:IsA("BasePart") then
                local oldCFrame = rootPart.CFrame
                rootPart.CFrame = gunDrop.CFrame - Vector3.new(0, 1, 0)
                task.wait(0.1)
                rootPart.CFrame = oldCFrame
            end
        end
    end
})

local GrabLoopToggle = InnoLeftGroupbox:AddToggle("GrabLoop", {
    Text = "Auto Grab Gun",
    Default = false,
})
Toggles.GrabLoop:OnChanged(function(state)
    Library:Notify({ Title = "Auto Grab Gun", Description = state and "Auto Grab Gun Enabled" or "Auto Grab Gun Disabled", Time = 4 })
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    if state then
        if _G.AutoGunConnection then
            _G.AutoGunConnection:Disconnect()
            _G.AutoGunConnection = nil
        end

        _G.AutoGunConnection = Workspace.DescendantAdded:Connect(function(child)
            if child.Name == "GunDrop" and child:IsA("BasePart") and Toggles.GrabLoop.Value then
                task.wait(0.05)
                
                local character = LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                
                if rootPart then
                    local oldCFrame = rootPart.CFrame
                    rootPart.CFrame = child.CFrame - Vector3.new(0, 1, 0)
                    task.wait(0.1)
                    rootPart.CFrame = oldCFrame
                end
            end
        end)
    else
        if _G.AutoGunConnection then
            _G.AutoGunConnection:Disconnect()
            _G.AutoGunConnection = nil
        end
    end
end)


-- ////////////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////Visual/////////////////////////////////////////////

local VisualsTab = Window:AddTab({
    Name = "Visual",
    Description = "",
    Icon = "eye",
    Tooltip = "ESP and player highlights",
})

local ESPGroupbox = VisualsTab:AddGroupbox({
    Side = "Left",
    Name = "ESP Settings",
    Description = "",
    IconName = "eye",
    DisableCollapsing = false
})

ESPGroupbox:AddToggle("ESPMainToggle", {
    Text = "Enable ESP",
    Default = false,
}):OnChanged(function(state)
    Library:Notify({ Title = "ESP Master", Description = state and "ESP Master Enabled" or "ESP Master Disabled", Time = 4 })
    _G.espenabled = state
end)

ESPGroupbox:AddDivider()

ESPGroupbox:AddToggle("Highlights", { Text = "Highlights", Default = false }):OnChanged(function(state)
    Library:Notify({ Title = "Highlights", Description = state and "Highlights Enabled" or "Highlights Disabled", Time = 4 })
end)
ESPGroupbox:AddToggle("TracerToggle", { Text = "Tracers", Default = false }):OnChanged(function(state)
    Library:Notify({ Title = "Tracers", Description = state and "Tracers Enabled" or "Tracers Disabled", Time = 4 })
end)
ESPGroupbox:AddToggle("BoxESP", { Text = "Box ESP", Default = false }):OnChanged(function(state)
    Library:Notify({ Title = "Box ESP", Description = state and "Box ESP Enabled" or "Box ESP Disabled", Time = 4 })
end)
ESPGroupbox:AddToggle("SkeleESP", { Text = "Skeleton ESP", Default = false }):OnChanged(function(state)
    Library:Notify({ Title = "Skeleton ESP", Description = state and "Skeleton ESP Enabled" or "Skeleton ESP Disabled", Time = 4 })
end)
ESPGroupbox:AddToggle("DistanceESP", { Text = "Distance ESP", Default = false }):OnChanged(function(state)
    Library:Notify({ Title = "Distance ESP", Description = state and "Distance ESP Enabled" or "Distance ESP Disabled", Time = 4 })
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Colors = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 115, 255),
    Innocent = Color3.fromRGB(0, 255, 0)
}

local function getPlayerRole(player)
    if not player then return "Innocent" end
    
    local function checkName(name)
        name = name:lower()
        if name:find("knife") or name:find("cutter") then
            return "Murderer"
        elseif name:find("gun") or name:find("revolver") or name:find("sheriff") then
            return "Sheriff"
        end
        return nil
    end

    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                local res = checkName(item.Name)
                if res then return res end
            end
        end
    end
    
    local character = player.Character
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                local res = checkName(item.Name)
                if res then return res end
            end
        end
    end
    
    return "Innocent"
end

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local MM2_Tracers = {}
local MM2_BoxESPTable = {}
local MM2_SkeletonTable = {}
local MM2_DistanceTable = {}

local BoneConnections = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

local function clearPlayerESP(player)
    if player and player.Character then
        local hl = player.Character:FindFirstChild("MM2_Highlight")
        if hl then hl:Destroy() end
    end
    if MM2_Tracers[player] then
        pcall(function() MM2_Tracers[player].Visible = false MM2_Tracers[player]:Remove() end)
        MM2_Tracers[player] = nil
    end
    if MM2_BoxESPTable[player] then
        local boxData = MM2_BoxESPTable[player]
        if boxData.Box then boxData.Box.Visible = false boxData.Box:Remove() end
        if boxData.Outline then boxData.Outline.Visible = false boxData.Outline:Remove() end
        MM2_BoxESPTable[player] = nil
    end
    if MM2_SkeletonTable[player] then
        for _, line in pairs(MM2_SkeletonTable[player]) do
            pcall(function() line.Visible = false line:Remove() end)
        end
        MM2_SkeletonTable[player] = nil
    end
    if MM2_DistanceTable[player] then
        pcall(function() MM2_DistanceTable[player].Visible = false MM2_DistanceTable[player]:Remove() end)
        MM2_DistanceTable[player] = nil
    end
end

local function clearAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        clearPlayerESP(player)
    end
end

local function getBoxData(player)
    if MM2_BoxESPTable[player] then return MM2_BoxESPTable[player] end
    local outline = Drawing.new("Square")
    outline.Thickness = 3
    outline.Color = Color3.fromRGB(0, 0, 0)
    outline.Filled = false
    outline.Transparency = 1
    outline.Visible = false

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = Color3.fromRGB(255, 255, 255)
    box.Filled = false
    box.Transparency = 1
    box.Visible = false

    local data = { Outline = outline, Box = box }
    MM2_BoxESPTable[player] = data
    return data
end

local function getSkeletonLines(player)
    if MM2_SkeletonTable[player] then return MM2_SkeletonTable[player] end
    local lines = {}
    for i = 1, #BoneConnections do
        local success, l = pcall(function()
            local line = Drawing.new("Line")
            line.Thickness = 1.5
            line.Transparency = 1
            line.Visible = false
            return line
        end)
        if success and l then table.insert(lines, l) end
    end
    MM2_SkeletonTable[player] = lines
    return lines
end

local function getDistanceText(player)
    if MM2_DistanceTable[player] then return MM2_DistanceTable[player] end
    local textObj = Drawing.new("Text")
    textObj.Size = 16
    textObj.Center = true
    textObj.Outline = true
    textObj.OutlineColor = Color3.fromRGB(0, 0, 0)
    textObj.Visible = false
    MM2_DistanceTable[player] = textObj
    return textObj
end

RunService.RenderStepped:Connect(function()
    local masterActive = Toggles.ESPMainToggle and Toggles.ESPMainToggle.Value or false
    local hlActive = Toggles.Highlights and Toggles.Highlights.Value or false
    local tracerActive = Toggles.TracerToggle and Toggles.TracerToggle.Value or false
    local boxActive = Toggles.BoxESP and Toggles.BoxESP.Value or false
    local skeleActive = Toggles.SkeleESP and Toggles.SkeleESP.Value or false
    local distanceActive = Toggles.DistanceESP and Toggles.DistanceESP.Value or false

    if not masterActive then
        clearAllESP()
        return
    end

    local screenCenterBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local localChar = LocalPlayer.Character
    local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local hrp = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if hrp and humanoid and humanoid.Health > 0 then
                local role = getPlayerRole(player)
                local roleColor = Colors[role] or Colors["Innocent"]

                if hlActive then
                    local highlight = character:FindFirstChild("MM2_Highlight")
                    if not highlight then
                        pcall(function()
                            highlight = Instance.new("Highlight")
                            highlight.Name = "MM2_Highlight"
                            highlight.Adornee = character
                            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            highlight.FillTransparency = 0.4
                            highlight.OutlineTransparency = 0
                            highlight.Parent = character
                        end)
                    else
                        highlight.FillColor = roleColor
                        highlight.OutlineColor = roleColor
                        highlight.Enabled = true
                        if highlight.Adornee ~= character then
                            highlight.Adornee = character
                        end
                        if highlight.Parent ~= character then
                            highlight.Parent = character
                        end
                    end
                else
                    local highlight = character:FindFirstChild("MM2_Highlight")
                    if highlight then highlight:Destroy() end
                end

                if tracerActive then
                    local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    local line = MM2_Tracers[player]
                    if not line then
                        pcall(function()
                            local l = Drawing.new("Line")
                            l.Thickness = 1.5
                            l.Transparency = 1
                            l.Visible = false
                            line = l
                            MM2_Tracers[player] = l
                        end)
                    end
                    if line then
                        if onScreen then
                            line.From = screenCenterBottom
                            line.To = Vector2.new(vector.X, vector.Y)
                            line.Color = roleColor
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    end
                else
                    if MM2_Tracers[player] then
                        MM2_Tracers[player].Visible = false
                        MM2_Tracers[player]:Remove()
                        MM2_Tracers[player] = nil
                    end
                end

                if boxActive then
                    local cf, size = character:GetBoundingBox()
                    local corners = {
                        cf * CFrame.new(size.X / 2, size.Y / 2, size.Z / 2),
                        cf * CFrame.new(-size.X / 2, size.Y / 2, size.Z / 2),
                        cf * CFrame.new(size.X / 2, -size.Y / 2, size.Z / 2),
                        cf * CFrame.new(-size.X / 2, -size.Y / 2, size.Z / 2),
                        cf * CFrame.new(size.X / 2, size.Y / 2, -size.Z / 2),
                        cf * CFrame.new(-size.X / 2, size.Y / 2, -size.Z / 2),
                        cf * CFrame.new(size.X / 2, -size.Y / 2, -size.Z / 2),
                        cf * CFrame.new(-size.X / 2, -size.Y / 2, -size.Z / 2),
                    }

                    local minX, minY = math.huge, math.huge
                    local maxX, maxY = -math.huge, -math.huge
                    local onScreenAny = false

                    for _, corner in ipairs(corners) do
                        local screenPos, onScreen = Camera:WorldToViewportPoint(corner.Position)
                        if onScreen then
                            onScreenAny = true
                        end
                        minX = math.min(minX, screenPos.X)
                        minY = math.min(minY, screenPos.Y)
                        maxX = math.max(maxX, screenPos.X)
                        maxY = math.max(maxY, screenPos.Y)
                    end

                    if onScreenAny then
                        local boxData = getBoxData(player)
                        local boxPos = Vector2.new(minX, minY)
                        local boxSize = Vector2.new(maxX - minX, maxY - minY)

                        boxData.Box.Color = roleColor
                        boxData.Outline.Size = boxSize
                        boxData.Outline.Position = boxPos
                        boxData.Outline.Visible = true

                        boxData.Box.Size = boxSize
                        boxData.Box.Position = boxPos
                        boxData.Box.Visible = true
                    else
                        if MM2_BoxESPTable[player] then
                            MM2_BoxESPTable[player].Box.Visible = false
                            MM2_BoxESPTable[player].Outline.Visible = false
                        end
                    end
                else
                    if MM2_BoxESPTable[player] then
                        local boxData = MM2_BoxESPTable[player]
                        if boxData.Box then boxData.Box.Visible = false boxData.Box:Remove() end
                        if boxData.Outline then boxData.Outline.Visible = false boxData.Outline:Remove() end
                        MM2_BoxESPTable[player] = nil
                    end
                end

                if skeleActive then
                    local lines = getSkeletonLines(player)
                    for index, connection in ipairs(BoneConnections) do
                        local partA = character:FindFirstChild(connection[1])
                        local partB = character:FindFirstChild(connection[2])
                        local line = lines[index]
                        if partA and partB and line then
                            local posA, onScreenA = Camera:WorldToViewportPoint(partA.Position)
                            local posB, onScreenB = Camera:WorldToViewportPoint(partB.Position)
                            if onScreenA and onScreenB then
                                line.From = Vector2.new(posA.X, posA.Y)
                                line.To = Vector2.new(posB.X, posB.Y)
                                line.Color = roleColor
                                line.Visible = true
                            else
                                line.Visible = false
                            end
                        elseif line then
                            line.Visible = false
                        end
                    end
                else
                    if MM2_SkeletonTable[player] then
                        for _, line in pairs(MM2_SkeletonTable[player]) do
                            pcall(function() line.Visible = false line:Remove() end)
                        end
                        MM2_SkeletonTable[player] = nil
                    end
                end

                if distanceActive and localHrp then
                    local feetPos = hrp.Position - Vector3.new(0, 3.5, 0)
                    local screenPos, onScreen = Camera:WorldToViewportPoint(feetPos)

                    if onScreen then
                        local distance = math.floor((localHrp.Position - hrp.Position).Magnitude)
                        local textObj = getDistanceText(player)

                        textObj.Text = "[" .. tostring(distance) .. "m]"
                        textObj.Position = Vector2.new(screenPos.X, screenPos.Y)
                        textObj.Color = roleColor
                        textObj.Visible = true
                    else
                        if MM2_DistanceTable[player] then
                            MM2_DistanceTable[player].Visible = false
                        end
                    end
                else
                    if MM2_DistanceTable[player] then
                        pcall(function() MM2_DistanceTable[player].Visible = false MM2_DistanceTable[player]:Remove() end)
                        MM2_DistanceTable[player] = nil
                    end
                end

            else
                clearPlayerESP(player)
            end
        else
            clearPlayerESP(player)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    clearPlayerESP(player)
end)

ESPGroupbox:AddDivider()

local NameESPToggle = ESPGroupbox:AddToggle("NameESPToggle", {
    Text = "Name ESP",
    Default = false,
})
Toggles.NameESPToggle:OnChanged(function(state)
Library:Notify({ Title = "Name ESP", Description = state and "Name ESP Enabled" or "Name ESP Disabled", Time = 4 })
getgenv().NameESP = state

if getgenv().MM2_NameESP_Connections then
    for _, conn in ipairs(getgenv().MM2_NameESP_Connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
end
getgenv().MM2_NameESP_Connections = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

if not getgenv().NameESP then
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Head") then
            local esp = player.Character.Head:FindFirstChild("MM2_NameESP")
            if esp then
                esp:Destroy()
            end
        end
    end
    return
end

local Colors = {
    Murderer = Color3.fromRGB(255, 45, 45),
    Sheriff = Color3.fromRGB(45, 135, 255),
    Innocent = Color3.fromRGB(45, 255, 100)
}

local function getPlayerRole(player)
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character

    local function hasTool(name)
        if backpack and backpack:FindFirstChild(name) then
            return true
        end
        if character and character:FindFirstChild(name) then
            return true
        end
        return false
    end

    if hasTool("Knife") then
        return "Murderer"
    elseif hasTool("Gun") then
        return "Sheriff"
    else
        return "Innocent"
    end
end

local function createESP(player)
    if player == LocalPlayer then return end

    local function setupCharacter(character)
        if not getgenv().NameESP then return end

        local head = character:WaitForChild("Head", 5)
        if not head or not getgenv().NameESP then return end

        if head:FindFirstChild("MM2_NameESP") then
            head.MM2_NameESP:Destroy()
        end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "MM2_NameESP"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = true
        billboard.Parent = head

        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "NameLabel"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 14
        textLabel.TextStrokeTransparency = 0.2
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.TextColor3 = Colors.Innocent
        textLabel.Parent = billboard
    end

    if player.Character then
        task.spawn(setupCharacter, player.Character)
    end
    
    local charConn = player.CharacterAdded:Connect(setupCharacter)
    table.insert(getgenv().MM2_NameESP_Connections, charConn)
end

for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

local addedConn = Players.PlayerAdded:Connect(createESP)
table.insert(getgenv().MM2_NameESP_Connections, addedConn)

local renderConn = RunService.RenderStepped:Connect(function()
    if not getgenv().NameESP then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local billboard = head:FindFirstChild("MM2_NameESP")
                if billboard then
                    local role = getPlayerRole(player)
                    local label = billboard:FindFirstChild("NameLabel")
                    if label then
                        label.TextColor3 = Colors[role]
                    end
                end
            end
        end
    end
end)
table.insert(getgenv().MM2_NameESP_Connections, renderConn)
end)


-- ////////////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////Player////////////////////////////////-------------

local PlayerTab = Window:AddTab({
    Name = "Player",
    Description = "",
    Icon = "user",
    Tooltip = "Character modifications and movement",
})

local SJLeftGroupBox = PlayerTab:AddGroupbox({
    Side = "Left",
    Name = "Movement",
    Description = "",
    IconName = "zap",
    DisableCollapsing = true
})

local SpeedToggle = SJLeftGroupBox:AddToggle("SpeedToggle", {
    Text = "Speed",
    Default = false,
})
Toggles.SpeedToggle:OnChanged(function(state)
Library:Notify({ Title = "Speed", Description = state and "Speed Enabled" or "Speed Disabled", Time = 4 })
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local player = Players.LocalPlayer

if _G.Speed == nil then
    _G.Speed = 24
end

if _G.TPWalk ~= true then
    _G.TPWalk = false
end

local connectionName = "CSware_TPWalk_Connection"

if not state then
    if getgenv()[connectionName] then
        getgenv()[connectionName]:Disconnect()
        getgenv()[connectionName] = nil
        
        local character = player.Character
        if character and character:FindFirstChildOfClass("Humanoid") then
            character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
        end
    end
    return
end

local keysPressed = { W = false, S = false, A = false, D = false }

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.W then keysPressed.W = true end
    if input.KeyCode == Enum.KeyCode.S then keysPressed.S = true end
    if input.KeyCode == Enum.KeyCode.A then keysPressed.A = true end
    if input.KeyCode == Enum.KeyCode.D then keysPressed.D = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then keysPressed.W = false end
    if input.KeyCode == Enum.KeyCode.S then keysPressed.S = false end
    if input.KeyCode == Enum.KeyCode.A then keysPressed.A = false end
    if input.KeyCode == Enum.KeyCode.D then keysPressed.D = false end
end)

getgenv()[connectionName] = RunService.RenderStepped:Connect(function(dt)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    if humanoid and hrp and humanoid.Health > 0 then
        if _G.TPWalk == true then
            humanoid.WalkSpeed = 16
            
            local camCF = camera.CFrame
            local lookVector = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
            local rightVector = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit
            
            local moveVector = Vector3.new(0, 0, 0)
            if keysPressed.W then moveVector = moveVector + lookVector end
            if keysPressed.S then moveVector = moveVector - lookVector end
            if keysPressed.D then moveVector = moveVector + rightVector end
            if keysPressed.A then moveVector = moveVector - rightVector end
            
            if moveVector.Magnitude > 0 then
                moveVector = moveVector.Unit
                hrp.CFrame = hrp.CFrame + (moveVector * (_G.Speed * dt))
            end
        else
            humanoid.WalkSpeed = _G.Speed
        end
    end
end)
end)

local TPWalkToggle = SJLeftGroupBox:AddCheckbox("TPWalkToggle", {
    Text = "Use CFrame",
    Default = false,
})
Toggles.TPWalkToggle:OnChanged(function(state)
Library:Notify({ Title = "CFrame Walk", Description = state and "CFrame Walk Enabled" or "CFrame Walk Disabled", Time = 4 })
_G.TPWalk = state
end)

SJLeftGroupBox:AddSlider("SpeedValue", {
    Text = "Speed Value",
    Default = 16,
    Min = 16,
    Max = 300,
    Rounding = 0,
    Suffix = "",
})
Options.SpeedValue:OnChanged(function(value)
_G.Speed = value
end)

SJLeftGroupBox:AddDivider()

local JumpPowerToggle = SJLeftGroupBox:AddToggle("JumpPowerToggle", {
    Text = "Jumppower",
    Default = false,
})
Toggles.JumpPowerToggle:OnChanged(function(state)
Library:Notify({ Title = "JumpPower", Description = state and "JumpPower Enabled" or "JumpPower Disabled", Time = 4 })
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

if _G.JumpPower == nil then
    _G.JumpPower = 50
end

local connectionName = "CSware_JumpPowerToggle_Connection"

if not state then
    if getgenv()[connectionName] then
        getgenv()[connectionName]:Disconnect()
        getgenv()[connectionName] = nil
        
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") then
            local humanoid = character.Humanoid
            humanoid.UseJumpPower = true
            humanoid.JumpPower = 50
        end
    end
    return
end

getgenv()[connectionName] = RunService.RenderStepped:Connect(function()
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = _G.JumpPower
        end
    end
end)
end)

SJLeftGroupBox:AddSlider("JumpPowerValue", {
    Text = "Jumppower Value",
    Default = 50,
    Min = 50,
    Max = 300,
    Rounding = 0,
    Suffix = "",
})
Options.JumpPowerValue:OnChanged(function(value)
_G.JumpPower = value
end)

local FlyRightGroupBox = PlayerTab:AddGroupbox({
    Side = "Right",
    Name = "Flight",
    Description = "",
    IconName = "cloud",
    DisableCollapsing = true,
})

local FlyToggle = FlyRightGroupBox:AddToggle("FlyToggle", {
    Text = "Fly",
    Default = false,
})
Toggles.FlyToggle:OnChanged(function(state)
Library:Notify({ Title = "Fly", Description = state and "Fly Enabled" or "Fly Disabled", Time = 4 })
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

if _G.FlySpeed == nil then
    _G.FlySpeed = 50
end

if _G.CFrameFly ~= true then
    _G.CFrameFly = false
end

local connectionName = "CSware_FixedFly_Connection"

if not state then
    if getgenv()[connectionName] then
        local data = getgenv()[connectionName]
        if type(data) == "table" then
            if data.Connection then data.Connection:Disconnect() end
            if data.BodyVelocity then data.BodyVelocity:Destroy() end
            if data.BodyGyro then data.BodyGyro:Destroy() end
        end
        
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if humanoid then 
                humanoid.PlatformStand = false
                humanoid.Sit = false
            end
            if hrp then 
                hrp.Anchored = false 
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.2, 0)
            end
        end
        
        getgenv()[connectionName] = nil
    end
    return
end

local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

humanoid.PlatformStand = true

local bg, bv

local function setupPhysics()
    if not bg then
        bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.P = 15000
        bg.CFrame = humanoidRootPart.CFrame
        bg.Parent = humanoidRootPart
    end
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = humanoidRootPart
    end
    humanoidRootPart.Anchored = false
end

local function cleanupPhysics()
    if bg then bg:Destroy(); bg = nil end
    if bv then bv:Destroy(); bv = nil end
end

if not _G.CFrameFly then
    setupPhysics()
end

local inputMap = { W = false, S = false, A = false, D = false, Space = false, LeftShift = false }

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.W then inputMap.W = true end
    if input.KeyCode == Enum.KeyCode.S then inputMap.S = true end
    if input.KeyCode == Enum.KeyCode.A then inputMap.A = true end
    if input.KeyCode == Enum.KeyCode.D then inputMap.D = true end
    if input.KeyCode == Enum.KeyCode.Space then inputMap.Space = true end
    if input.KeyCode == Enum.KeyCode.LeftShift then inputMap.LeftShift = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then inputMap.W = false end
    if input.KeyCode == Enum.KeyCode.S then inputMap.S = false end
    if input.KeyCode == Enum.KeyCode.A then inputMap.A = false end
    if input.KeyCode == Enum.KeyCode.D then inputMap.D = false end
    if input.KeyCode == Enum.KeyCode.Space then inputMap.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then inputMap.LeftShift = false end
end)

local lastMode = _G.CFrameFly
local lockedPosition = humanoidRootPart.Position

local renderConnection
renderConnection = RunService.RenderStepped:Connect(function(dt)
    if not character or not humanoidRootPart or humanoid.Health <= 0 then
        return
    end

    humanoid.PlatformStand = true
    
    if _G.CFrameFly ~= lastMode then
        lastMode = _G.CFrameFly
        if lastMode then
            cleanupPhysics()
            lockedPosition = humanoidRootPart.Position
        else
            setupPhysics()
        end
    end

    local camCF = camera.CFrame
    local lookVector = camCF.LookVector
    local rightVector = camCF.RightVector
    
    local moveVector = Vector3.new(0, 0, 0)
    if inputMap.W then moveVector = moveVector + lookVector end
    if inputMap.S then moveVector = moveVector - lookVector end
    if inputMap.D then moveVector = moveVector + rightVector end
    if inputMap.A then moveVector = moveVector - rightVector end
    if inputMap.Space then moveVector = moveVector + Vector3.new(0, 1, 0) end
    if inputMap.LeftShift then moveVector = moveVector - Vector3.new(0, 1, 0) end

    if moveVector.Magnitude > 0 then
        moveVector = moveVector.Unit
    end

    if _G.CFrameFly then
        humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        
        if moveVector.Magnitude > 0 then
            lockedPosition = humanoidRootPart.Position + (moveVector * (_G.FlySpeed * dt))
            humanoidRootPart.CFrame = CFrame.new(lockedPosition, lockedPosition + lookVector)
        else
            humanoidRootPart.CFrame = CFrame.new(lockedPosition, lockedPosition + lookVector)
        end
    else
        if bg and bv then
            bg.CFrame = camCF
            bv.Velocity = moveVector * _G.FlySpeed
        end
    end
    
    if getgenv()[connectionName] and type(getgenv()[connectionName]) == "table" then
        getgenv()[connectionName].BodyVelocity = bv
        getgenv()[connectionName].BodyGyro = bg
    end
end)

getgenv()[connectionName] = {
    Connection = renderConnection,
    BodyVelocity = bv,
    BodyGyro = bg
}
end)

FlyRightGroupBox:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = 50,
    Min = 16,
    Max = 300,
    Rounding = 0,
    Suffix = "",
})
Options.FlySpeed:OnChanged(function(value)
_G.FlySpeed = value
end)

local CFrameToggle = FlyRightGroupBox:AddCheckbox("CFrameToggle", {
    Text = "Use CFrame",
    Default = false,
})
Toggles.CFrameToggle:OnChanged(function(state)
Library:Notify({ Title = "CFrame Fly", Description = state and "CFrame Fly Enabled" or "CFrame Fly Disabled", Time = 4 })
_G.CFrameFly = state
end)

local MiscRightGroupbox = PlayerTab:AddGroupbox({
    Side = "Right",
    Name = "Character",
    Description = "",
    IconName = "user",
    DisableCollapsing = true,
})

local InfJumpToggle = MiscRightGroupbox:AddToggle("InfJumpToggle", {
    Text = "Infinite Jump",
    Default = false,
})
Toggles.InfJumpToggle:OnChanged(function(state)
Library:Notify({ Title = "Infinite Jump", Description = state and "Infinite Jump Enabled" or "Infinite Jump Disabled", Time = 4 })
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local connectionName = "CSware_InfiniteJump_Connection"

if not state then
    if getgenv()[connectionName] then
        getgenv()[connectionName]:Disconnect()
        getgenv()[connectionName] = nil
    end
    return
end

getgenv()[connectionName] = UserInputService.JumpRequest:Connect(function()
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)
end)

local NoclipToggle = MiscRightGroupbox:AddToggle("NoclipToggle", {
    Text = "Noclip",
    Default = false,
})
Toggles.NoclipToggle:OnChanged(function(state)
Library:Notify({ Title = "Noclip", Description = state and "Noclip Enabled" or "Noclip Disabled", Time = 4 })
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local connectionName = "CSware_CleanJumpNoclip_Connection"

if not state then
    if getgenv()[connectionName] then
        getgenv()[connectionName]:Disconnect()
        getgenv()[connectionName] = nil
        
        local character = player.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
    return
end

getgenv()[connectionName] = RunService.Stepped:Connect(function()
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    if humanoid and hrp then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        
        if humanoid:GetState() == Enum.HumanoidStateType.Jumping then
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 35, hrp.AssemblyLinearVelocity.Z)
        end
    end
end)
end)

local InvisToggle = MiscRightGroupbox:AddToggle("InvisToggle", {
    Text = "Invisibility",
    Default = false,
})
Toggles.InvisToggle:OnChanged(function(state)
    Library:Notify({ Title = "Invisibility", Description = state and "Invisibility Enabled" or "Invisibility Disabled", Time = 4 })
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    getgenv().CSwareInvisActive = state

    local function destroyGhost(char)
        if not char then return end
        local ghost = char:FindFirstChild("CSware_GhostRig")
        if ghost then
            ghost:Destroy()
        end
    end

    local function syncGhost(char)
        if not char then return end
        local ghost = char:FindFirstChild("CSware_GhostRig")
        if not ghost then
            ghost = Instance.new("Model")
            ghost.Name = "CSware_GhostRig"
            ghost.Archivable = false

            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    local clonePart = Instance.new("Part")
                    clonePart.Name = part.Name
                    clonePart.Size = part.Size
                    clonePart.Color = Color3.fromRGB(0, 220, 255)
                    clonePart.Material = Enum.Material.ForceField
                    clonePart.Transparency = 0.65
                    clonePart.CanCollide = false
                    clonePart.CanTouch = false
                    clonePart.CanQuery = false
                    clonePart.Massless = true
                    clonePart.Anchored = true
                    clonePart.CFrame = part.CFrame
                    clonePart.Parent = ghost

                    local mesh = part:FindFirstChildOfClass("SpecialMesh")
                    if mesh then
                        local cloneMesh = mesh:Clone()
                        cloneMesh.Parent = clonePart
                    end
                end
            end

            ghost.Parent = char
        end

        for _, clonePart in ipairs(ghost:GetChildren()) do
            if clonePart:IsA("BasePart") then
                local realPart = char:FindFirstChild(clonePart.Name)
                if realPart and realPart:IsA("BasePart") then
                    clonePart.Size = realPart.Size
                    clonePart.CFrame = realPart.CFrame
                end
            end
        end
    end

    local function restoreCharacterVisuals(char, savedMap)
        if not char then return end
        destroyGhost(char)
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("BasePart") then
                if savedMap and savedMap.Parts and savedMap.Parts[desc] ~= nil then
                    desc.LocalTransparencyModifier = 0
                    desc.Transparency = savedMap.Parts[desc]
                elseif desc.Name == "HumanoidRootPart" then
                    desc.Transparency = 1
                else
                    desc.LocalTransparencyModifier = 0
                    desc.Transparency = 0
                end
            elseif desc:IsA("Decal") or desc:IsA("Texture") then
                if savedMap and savedMap.Decals and savedMap.Decals[desc] ~= nil then
                    desc.Transparency = savedMap.Decals[desc]
                else
                    desc.Transparency = 0
                end
            elseif desc:IsA("Beam") or desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("BillboardGui") then
                if savedMap and savedMap.Effects and savedMap.Effects[desc] ~= nil then
                    desc.Enabled = savedMap.Effects[desc]
                end
            end
        end
    end

    local function applyCharacterInvis(char, savedMap)
        if not char then return end
        for _, desc in ipairs(char:GetDescendants()) do
            if desc.Parent and desc.Parent.Name == "CSware_GhostRig" then
                continue
            end
            if desc:IsA("BasePart") then
                if savedMap and savedMap.Parts and savedMap.Parts[desc] == nil then
                    savedMap.Parts[desc] = desc.Transparency
                end
                if desc.Name ~= "HumanoidRootPart" then
                    desc.Transparency = 1
                    desc.LocalTransparencyModifier = 1
                end
            elseif desc:IsA("Decal") or desc:IsA("Texture") then
                if savedMap and savedMap.Decals and savedMap.Decals[desc] == nil then
                    savedMap.Decals[desc] = desc.Transparency
                end
                desc.Transparency = 1
            elseif desc:IsA("Beam") or desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("BillboardGui") then
                if savedMap and savedMap.Effects and savedMap.Effects[desc] == nil then
                    savedMap.Effects[desc] = desc.Enabled
                end
                desc.Enabled = false
            end
        end
        syncGhost(char)
    end

    if getgenv().CSwareInvisConn then
        getgenv().CSwareInvisConn:Disconnect()
        getgenv().CSwareInvisConn = nil
    end

    if not state then
        local st = getgenv().CSwareInvisState
        restoreCharacterVisuals(LocalPlayer.Character, st)
        getgenv().CSwareInvisState = nil
        return
    end

    local savedMap = {
        Parts = {},
        Decals = {},
        Effects = {},
    }
    getgenv().CSwareInvisState = savedMap

    if LocalPlayer.Character then
        applyCharacterInvis(LocalPlayer.Character, savedMap)
    end

    getgenv().CSwareInvisConn = RunService.RenderStepped:Connect(function()
        if not getgenv().CSwareInvisActive then return end
        if LocalPlayer.Character then
            applyCharacterInvis(LocalPlayer.Character, getgenv().CSwareInvisState)
        end
    end)
end)

local TPLeftGroupbox = PlayerTab:AddGroupbox({
    Side = "Left",
    Name = "Teleport Tool",
    Description = "",
    IconName = "map-pin",
    DisableCollapsing = false,
})

local ClickTPToggle = TPLeftGroupbox:AddToggle("ClickTPToggle", {
    Text = "Click TP",
    Default = false,
})
Toggles.ClickTPToggle:OnChanged(function(state)
Library:Notify({ Title = "Click TP", Description = state and "Click TP Enabled" or "Click TP Disabled", Time = 4 })
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local connectionName = "CSware_ClickTP_Connection"

if not state then
    if getgenv()[connectionName] then
        getgenv()[connectionName]:Disconnect()
        getgenv()[connectionName] = nil
    end
    return
end

getgenv()[connectionName] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        if _G.CtrlClick == true then
            local ctrlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
            if not ctrlDown then
                return
            end
        end
        
        if mouse.Target then
            local targetPos = mouse.Hit.Position + Vector3.new(0, 3, 0)
            character.HumanoidRootPart.CFrame = CFrame.new(targetPos)
        end
    end
end)
end)

local UseCTRLToggle = TPLeftGroupbox:AddCheckbox("UseCTRLToggle", {
    Text = "Use CTRL + Click",
    Default = false,
})
Toggles.UseCTRLToggle:OnChanged(function(state)
Library:Notify({ Title = "CTRL + Click", Description = state and "CTRL + Click Enabled" or "CTRL + Click Disabled", Time = 4 })
_G.CtrlClick = state
end)


-- ////////////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////Misc///////////////////////////////////////////////

local MiscTab = Window:AddTab({
    Name = "Misc",
    Description = "",
    Icon = "wrench",
    Tooltip = "Fling, Spoof and Server utilities",
})

local module = loadstring(game:HttpGet("https://raw.smokingscripts.org/module"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Options = Library.Options

getgenv().CSwareAutoFlingBusy = false
getgenv().CSwareAutoFlingToken = 0

local function isValidCharacter(plr)
    local char = plr and plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return char ~= nil and hrp ~= nil and hum ~= nil and hum.Health > 0
end

local function findRolePlayer(itemName)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local bp = plr:FindFirstChildOfClass("Backpack")
            local char = plr.Character
            if (bp and bp:FindFirstChild(itemName)) or (char and char:FindFirstChild(itemName)) then
                if isValidCharacter(plr) then
                    return plr
                end
            end
        end
    end
    return nil
end

local function returnToSafeSpot(homeCFrame, homeVel)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Parent and part.Parent.Name ~= "CSware_GhostRig" then
                part.Velocity = Vector3.zero
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
                if part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
    end

    if hrp then
        hrp.Anchored = false
        hrp.Velocity = Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        if homeCFrame then
            hrp.CFrame = homeCFrame
        end
    end

    if hum and hum.Health > 0 then
        hum.PlatformStand = false
        hum.Sit = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        pcall(function() hum:Move(hum.MoveDirection, false) end)
    end

    if getgenv().AntiFlingToggle and homeCFrame then
        getgenv().CSwareAntiFlingLastSafeCFrame = homeCFrame
    end
end

local function runOwnFling(fn, target)
    if not isValidCharacter(LocalPlayer) then return false end
    if target and not isValidCharacter(target) then return false end
    if getgenv().CSwareAutoFlingBusy then return false end

    getgenv().CSwareAutoFlingBusy = true

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local homeCFrame = hrp and hrp.CFrame or nil
    local homeVel = hrp and hrp.AssemblyLinearVelocity or Vector3.zero

    _G.CSwareIsFlinging = true
    local ok, err = pcall(fn)

    local waitStart = os.clock()
    while os.clock() - waitStart < 0.25 do
        if target and not isValidCharacter(target) then
            break
        end
        RunService.Heartbeat:Wait()
    end

    returnToSafeSpot(homeCFrame, homeVel)
    _G.CSwareIsFlinging = false
    getgenv().CSwareAutoFlingBusy = false

    if not ok then
        warn(err)
    end

    return ok
end

local FlingLeftGroupbox = MiscTab:AddGroupbox({
    Side = "Left",
    Name = "Fling",
    Description = "",
    IconName = "wind",
    DisableCollapsing = true,
})

local playerNames = {}
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        table.insert(playerNames, player.Name)
    end
end

local PlayerDropdown = FlingLeftGroupbox:AddDropdown("SelectedTargetPlayer", {
    Text = "Target Player",
    Values = playerNames,
    Default = 1,
    Multi = false,
})

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        table.insert(PlayerDropdown.Values, player.Name)
        PlayerDropdown:SetValues(PlayerDropdown.Values)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    for i, v in ipairs(PlayerDropdown.Values) do
        if v == player.Name then
            table.remove(PlayerDropdown.Values, i)
            break
        end
    end
    PlayerDropdown:SetValues(PlayerDropdown.Values)
end)

FlingLeftGroupbox:AddButton({
    Text = "Fling",
    Callback = function()
        Library:Notify({ Title = "Fling", Description = "Executing Fling on target player!", Time = 4 })
        local selectedName = Options.SelectedTargetPlayer.Value
        if type(selectedName) == "table" then
            for k, _ in pairs(selectedName) do
                selectedName = k
                break
            end
        end

        if not selectedName or selectedName == "" then return end

        local target = Players:FindFirstChild(selectedName)
        if not isValidCharacter(target) then return end

        task.spawn(function()
            runOwnFling(function()
                module:fling(target)
            end, target)
        end)
    end
})

FlingLeftGroupbox:AddDivider()

FlingLeftGroupbox:AddButton({
    Text = "Fling Sheriff",
    Callback = function()
    Library:Notify({ Title = "Fling", Description = "Attempting to fling the Sheriff!", Time = 4 })
    task.spawn(function()
        local target = findRolePlayer("Gun")
        if target then
            runOwnFling(function()
                module:fling(target)
            end, target)
        end
    end)
    end
})

FlingLeftGroupbox:AddToggle("AutoFlingSheriffToggle", {
    Text = "Auto Fling Sheriff",
    Default = false,
}):OnChanged(function(value)
    Library:Notify({ Title = "Auto Fling Sheriff", Description = value and "Auto Fling Sheriff Enabled" or "Auto Fling Sheriff Disabled", Time = 4 })
    getgenv().AutoFlingSheriffRunning = value
    getgenv().CSwareAutoFlingToken += 1
    local myToken = getgenv().CSwareAutoFlingToken

    if not value then
        return
    end

    task.spawn(function()
        while getgenv().AutoFlingSheriffRunning and getgenv().CSwareAutoFlingToken == myToken do
            if not getgenv().CSwareAutoFlingBusy and isValidCharacter(LocalPlayer) then
                local target = findRolePlayer("Gun")
                if target then
                    runOwnFling(function()
                        if getgenv().AutoFlingSheriffRunning and getgenv().CSwareAutoFlingToken == myToken and isValidCharacter(target) then
                            module:fling(target)
                        end
                    end, target)
                    task.wait(3.2)
                else
                    task.wait(0.6)
                end
            else
                task.wait(0.25)
            end
        end
    end)
end)

FlingLeftGroupbox:AddButton({
    Text = "Fling Murderer",
    Callback = function()
    Library:Notify({ Title = "Fling", Description = "Attempting to fling the Murderer!", Time = 4 })
    task.spawn(function()
        local target = findRolePlayer("Knife")
        if target then
            runOwnFling(function()
                module:fling(target)
            end, target)
        end
    end)
    end
})

FlingLeftGroupbox:AddToggle("AutoFlingMurdererToggle", {
    Text = "Auto Fling Murderer",
    Default = false,
}):OnChanged(function(value)
    Library:Notify({ Title = "Auto Fling Murderer", Description = value and "Auto Fling Murderer Enabled" or "Auto Fling Murderer Disabled", Time = 4 })
    getgenv().AutoFlingMurdererRunning = value
    getgenv().CSwareAutoFlingToken += 1
    local myToken = getgenv().CSwareAutoFlingToken

    if not value then
        return
    end

    task.spawn(function()
        while getgenv().AutoFlingMurdererRunning and getgenv().CSwareAutoFlingToken == myToken do
            if not getgenv().CSwareAutoFlingBusy and isValidCharacter(LocalPlayer) then
                local target = findRolePlayer("Knife")
                if target then
                    runOwnFling(function()
                        if getgenv().AutoFlingMurdererRunning and getgenv().CSwareAutoFlingToken == myToken and isValidCharacter(target) then
                            module:fling(target)
                        end
                    end, target)
                    task.wait(3.2)
                else
                    task.wait(0.6)
                end
            else
                task.wait(0.25)
            end
        end
    end)
end)

FlingLeftGroupbox:AddDivider()

local TouchFlingToggle = FlingLeftGroupbox:AddToggle("TouchFlingToggle", {
    Text = "Touch Fling",
    Default = false,
})
Toggles.TouchFlingToggle:OnChanged(function(state)
Library:Notify({ Title = "Touch Fling", Description = state and "Touch Fling Enabled" or "Touch Fling Disabled", Time = 4 })
local ReplicatedStorage = game:GetService("ReplicatedStorage")

getgenv().TouchFlingActive = state
_G.CSwareIsFlinging = state

if getgenv().TouchFlingActive then
    if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
        local detection = Instance.new("Decal")
        detection.Name = "juisdfj0i32i0eidsuf0iok"
        detection.Parent = ReplicatedStorage
    end
    
    if getgenv().TouchFlingConnection then
        task.cancel(getgenv().TouchFlingConnection)
        getgenv().TouchFlingConnection = nil
    end
    
    getgenv().TouchFlingConnection = task.spawn(function()
        local lp = Players.LocalPlayer
        local c, hrp, vel, movel = nil, nil, nil, 0.1
    
        while getgenv().TouchFlingActive do
            RunService.Heartbeat:Wait()
            c = lp.Character
            hrp = c and c:FindFirstChild("HumanoidRootPart")
    
            if hrp then
                vel = hrp.Velocity
                hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
                RunService.RenderStepped:Wait()
                hrp.Velocity = vel
                RunService.Stepped:Wait()
                hrp.Velocity = vel + Vector3.new(0, movel, 0)
                movel = -movel
            end
        end
    end)
else
    if getgenv().TouchFlingConnection then
        pcall(function() task.cancel(getgenv().TouchFlingConnection) end)
        getgenv().TouchFlingConnection = nil
    end

    task.spawn(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")

        if hrp and char then
            if humanoid then
                humanoid.PlatformStand = true
            end

            for i = 1, 5 do
                hrp.Velocity = Vector3.new(0, 0, 0)
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Parent and part.Parent.Name ~= "CSware_GhostRig" then
                        part.Velocity = Vector3.new(0, 0, 0)
                        part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        part.CanCollide = true
                    end
                end
                RunService.Heartbeat:Wait()
            end

            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end)
end
end)

local AntiFlingToggle = FlingLeftGroupbox:AddToggle("AntiFlingToggle", {
    Text = "Anti Fling",
    Default = false,
})
Toggles.AntiFlingToggle:OnChanged(function(state)
Library:Notify({ Title = "Anti Fling", Description = state and "Anti Fling Enabled" or "Anti Fling Disabled", Time = 4 })
getgenv().AntiFlingToggle = state

local function cleanupAntiFling()
    if getgenv().AntiFling_SteppedConn then
        getgenv().AntiFling_SteppedConn:Disconnect()
        getgenv().AntiFling_SteppedConn = nil
    end
    if getgenv().AntiFling_HeartbeatConn then
        getgenv().AntiFling_HeartbeatConn:Disconnect()
        getgenv().AntiFling_HeartbeatConn = nil
    end
end

if not getgenv().AntiFlingToggle then
    cleanupAntiFling()
    return
end

cleanupAntiFling()

getgenv().CSwareAntiFlingLastSafeCFrame = nil

getgenv().AntiFling_SteppedConn = RunService.Stepped:Connect(function()
    if not getgenv().AntiFlingToggle then return end

    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not (ch and hrp and hum) then return end

    if _G.CSwareIsFlinging then
        return
    end

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= LocalPlayer and other.Character then
            for _, part in ipairs(other.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end

    local lv = hrp.AssemblyLinearVelocity
    local av = hrp.AssemblyAngularVelocity
    local nanVel = (lv.X ~= lv.X) or (lv.Y ~= lv.Y) or (lv.Z ~= lv.Z)
    local nanAng = (av.X ~= av.X) or (av.Y ~= av.Y) or (av.Z ~= av.Z)

    local humState = hum:GetState()
    local isAirborneOrClimbing = (humState == Enum.HumanoidStateType.Freefall)
        or (humState == Enum.HumanoidStateType.Jumping)
        or (humState == Enum.HumanoidStateType.Climbing)

    local velLimit = isAirborneOrClimbing and 140 or 95

    if nanVel or nanAng or lv.Magnitude > velLimit or av.Magnitude > 22 then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        for _, part in ipairs(ch:GetDescendants()) do
            if part:IsA("BasePart") and part.Parent and part.Parent.Name ~= "CSware_GhostRig" then
                part.Velocity = Vector3.zero
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end
        if getgenv().CSwareAntiFlingLastSafeCFrame then
            hrp.CFrame = getgenv().CSwareAntiFlingLastSafeCFrame
        end
    else
        if humState ~= Enum.HumanoidStateType.Seated and humState ~= Enum.HumanoidStateType.PlatformStand then
            getgenv().CSwareAntiFlingLastSafeCFrame = hrp.CFrame
        end
    end
end)

getgenv().AntiFling_HeartbeatConn = RunService.Heartbeat:Connect(function()
    if not getgenv().AntiFlingToggle or _G.CSwareIsFlinging then return end
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local lv = hrp.AssemblyLinearVelocity
    if lv.Magnitude > 160 then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        if getgenv().CSwareAntiFlingLastSafeCFrame then
            hrp.CFrame = getgenv().CSwareAntiFlingLastSafeCFrame
        end
    end
end)
end)

local SpoofRightGroupbox = MiscTab:AddGroupbox({
    Side = "Right",
    Name = "Level Spoof",
    Description = "",
    IconName = "award",
    DisableCollapsing = true,
})

local LevelSpoofToggle = SpoofRightGroupbox:AddToggle("LevelSpoofToggle", {
    Text = "Enable Level Spoof",
    Default = false,
})
Toggles.LevelSpoofToggle:OnChanged(function(state)
Library:Notify({ Title = "Level Spoof", Description = state and "Level Spoof Enabled" or "Level Spoof Disabled", Time = 4 })
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

_G.SpoofLevelNumber = _G.SpoofLevelNumber or 100
_G.CSwareLevelSpoof = state

if not _G.CSwareLevelSpoof then
    if _G.LevelSpoofConn then
        _G.LevelSpoofConn:Disconnect()
        _G.LevelSpoofConn = nil
    end

    if _G.LevelSpoofOriginals then
        for obj, origText in pairs(_G.LevelSpoofOriginals) do
            if obj and obj.Parent then
                obj.Text = origText
            end
        end
        _G.LevelSpoofOriginals = nil
    end
    return
end

_G.LevelSpoofOriginals = {}

local function findPlayerRow(nameLabel)
    local current = nameLabel.Parent
    for _ = 1, 4 do
        if not current then break end
        if current.Name == LocalPlayer.Name or current.Name == tostring(LocalPlayer.UserId) or current:IsA("TextButton") or current:IsA("ImageButton") then
            return current
        end
        for _, desc in ipairs(current:GetDescendants()) do
            if desc:IsA("TextLabel") and desc ~= nameLabel then
                if desc.Text:match("^%d+$") or desc.Name:lower():find("level") then
                    return current
                end
            end
        end
        current = current.Parent
    end
    return nameLabel.Parent
end

_G.LevelSpoofConn = RunService.RenderStepped:Connect(function()
    if not _G.CSwareLevelSpoof then return end

    local spoofValue = tostring(math.floor(tonumber(_G.SpoofLevelNumber) or 1))

    local dataFolder = LocalPlayer:FindFirstChild("Data") or LocalPlayer:FindFirstChild("PlayerData")
    if dataFolder then
        local lvlObj = dataFolder:FindFirstChild("Level")
        if lvlObj and lvlObj:IsA("IntValue") then
            lvlObj.Value = tonumber(spoofValue) or 1
        end
    end

    for _, v in ipairs(PlayerGui:GetDescendants()) do
        if v:IsA("TextLabel") and (v.Text == LocalPlayer.Name or v.Text == LocalPlayer.DisplayName) then
            local rowContainer = findPlayerRow(v)
            if rowContainer then
                for _, child in ipairs(rowContainer:GetDescendants()) do
                    if child:IsA("TextLabel") and child ~= v then
                        if not Players:FindFirstChild(child.Text) then
                            if child.Text:match("^%d+$") or child.Name:lower():find("level") or _G.LevelSpoofOriginals[child] ~= nil then
                                if _G.LevelSpoofOriginals[child] == nil then
                                    _G.LevelSpoofOriginals[child] = child.Text
                                end
                                child.Text = spoofValue
                            end
                        end
                    end
                end
            end
        end
    end
end)
end)

SpoofRightGroupbox:AddSlider("LevelValue", {
    Text = "Level Value",
    Default = 0,
    Min = 0,
    Max = 9999,
    Rounding = 0,
    Suffix = "",
})
Options.LevelValue:OnChanged(function(value)
_G.SpoofLevelNumber = value
end)

local ServerGroupbox = MiscTab:AddGroupbox({
    Side = "Right",
    Name = "Server",
    Description = "",
    IconName = "server",
    DisableCollapsing = true,
})

ServerGroupbox:AddButton({
    Text = "Rejoin",
    Func = function()
        Library:Notify({ Title = "Server", Description = "Rejoining current server...", Time = 4 })
        local TeleportService = game:GetService("TeleportService")
        local Players = game:GetService("Players")
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
        end)
    end
})

ServerGroupbox:AddButton({
    Text = "Serverhop",
    Func = function()
        Library:Notify({ Title = "Server", Description = "Hopping to a new server...", Time = 4 })
        local TeleportService = game:GetService("TeleportService")
        local HttpService = game:GetService("HttpService")
        local Players = game:GetService("Players")

        task.spawn(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            local success, result = pcall(function()
                return game:HttpGet(url)
            end)
            
            if success then
                local data = HttpService:JSONDecode(result)
                if data and data.data then
                    for _, server in ipairs(data.data) do
                        if server.id ~= game.JobId and server.playing < server.maxPlayers then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Players.LocalPlayer)
                            break
                        end
                    end
                end
            end
        end)
    end
})

ServerGroupbox:AddButton({
    Text = "Most Players",
    Func = function()
        Library:Notify({ Title = "Server", Description = "Finding server with most players...", Time = 4 })
        local TeleportService = game:GetService("TeleportService")
        local HttpService = game:GetService("HttpService")
        local Players = game:GetService("Players")

        task.spawn(function()
            local url = "https://games.roproxy.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
            local success, result = pcall(function()
                return game:HttpGet(url)
            end)
            
            if success then
                local data = HttpService:JSONDecode(result)
                if data and data.data then
                    table.sort(data.data, function(a, b)
                        return a.playing > b.playing
                    end)
                    
                    for _, server in ipairs(data.data) do
                        if server.id ~= game.JobId and server.playing < server.maxPlayers then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Players.LocalPlayer)
                            break
                        end
                    end
                end
            end
        end)
    end
})

ServerGroupbox:AddButton({
    Text = "Least Players",
    Func = function()
        Library:Notify({ Title = "Server", Description = "Finding server with least players...", Time = 4 })
        local TeleportService = game:GetService("TeleportService")
        local HttpService = game:GetService("HttpService")
        local Players = game:GetService("Players")

        task.spawn(function()
            local url = "https://games.roproxy.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            local success, result = pcall(function()
                return game:HttpGet(url)
            end)
            
            if success then
                local data = HttpService:JSONDecode(result)
                if data and data.data then
                    table.sort(data.data, function(a, b)
                        return a.playing < b.playing
                    end)
                    
                    for _, server in ipairs(data.data) do
                        if server.id ~= game.JobId and server.playing < server.maxPlayers then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Players.LocalPlayer)
                            break
                        end
                    end
                end
            end
        end)
    end
})

local AutoFarmGroupBox = MiscTab:AddGroupbox({
    Side = "Right",
    Name = "Coins Farm",
    Description = "",
    IconName = "dollar-sign",
    DisableCollapsing = false,
})

local AutoFarmToggle = AutoFarmGroupBox:AddToggle("AutoFarmToggle", {
    Text = "Coinsfarm",
    Default = false,
})
Toggles.AutoFarmToggle:OnChanged(function(state)
Library:Notify({ Title = "Coins Farm", Description = state and "Coins Farm Enabled" or "Coins Farm Disabled", Time = 4 })
_G.KillAfterFarm = true
local SPEED = 34
local UNDERGROUND_OFFSET = -6.5

getgenv().CoinFarmActive = state

getgenv().MM2_CoinFarm_ID = (getgenv().MM2_CoinFarm_ID or 0) + 1
local currentID = getgenv().MM2_CoinFarm_ID

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

if getgenv().CoinFarm_NoclipConn then
    getgenv().CoinFarm_NoclipConn:Disconnect()
    getgenv().CoinFarm_NoclipConn = nil
end

local function resetCharacterPhysics()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if hum then hum.PlatformStand = false end
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        local currentPos = hrp.Position
        hrp.CFrame = CFrame.new(currentPos)
    end
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Parent and part.Parent.Name ~= "CSware_GhostRig" then
                part.CanCollide = true
            end
        end
    end
end

if not getgenv().CoinFarmActive then
    resetCharacterPhysics()
    return
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function getCashBag()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local mainGui = pGui and pGui:FindFirstChild("MainGUI")
    local gameGui = mainGui and mainGui:FindFirstChild("Game")
    return gameGui and gameGui:FindFirstChild("CashBag")
end

local function isActivelyInRound()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (char and hrp and hum and hum.Health > 0) then
        return false
    end

    local container = workspace:FindFirstChild("CoinContainer", true)
    if not container then
        return false
    end

    local cashBag = getCashBag()
    if cashBag then
        return cashBag.Visible == true
    end

    return true
end

local function isBagFull()
    local cashBag = getCashBag()
    if cashBag and cashBag.Visible then
        local coinsLabel = cashBag:FindFirstChild("Coins", true)
        local fullLabel = cashBag:FindFirstChild("Full", true)
        
        if fullLabel and fullLabel:IsA("GuiObject") and fullLabel.Visible then
            return true
        end

        if coinsLabel and coinsLabel:IsA("TextLabel") then
            local cur, max = coinsLabel.Text:match("(%d+)%s*/%s*(%d+)")
            if cur and max and tonumber(cur) >= tonumber(max) and tonumber(max) > 0 then
                return true
            end
        end
    end
    return false
end

local function getBestCoin(hrp, char)
    local container = workspace:FindFirstChild("CoinContainer", true)
    if not container then return nil end

    rayParams.FilterDescendantsInstances = { char, container }

    local bestCoin = nil
    local bestScore = math.huge

    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Transparency < 1 then
            if obj.Position.X == obj.Position.X then
                local dist = (obj.Position - hrp.Position).Magnitude
                if dist < 350 then
                    local roofHit = workspace:Raycast(obj.Position + Vector3.new(0, 1, 0), Vector3.new(0, 35, 0), rayParams)
                    local exposurePenalty = roofHit and 0 or 22

                    local score = dist + exposurePenalty
                    if score < bestScore then
                        bestScore = score
                        bestCoin = obj
                    end
                end
            end
        end
    end

    return bestCoin
end

getgenv().CoinFarm_NoclipConn = RunService.Stepped:Connect(function()
    if not getgenv().CoinFarmActive or getgenv().MM2_CoinFarm_ID ~= currentID then
        return
    end
    if isActivelyInRound() and not isBagFull() then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Parent and part.Parent.Name ~= "CSware_GhostRig" and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

local bagCompletedThisRound = false
local isUnderground = false

task.spawn(function()
    while getgenv().CoinFarmActive and getgenv().MM2_CoinFarm_ID == currentID do
        if not isActivelyInRound() then
            if isUnderground then
                resetCharacterPhysics()
                isUnderground = false
            end
            bagCompletedThisRound = false
            task.wait(0.25)
            continue
        end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if hrp and hum and hum.Health > 0 then
            if isBagFull() then
                if not bagCompletedThisRound then
                    bagCompletedThisRound = true
                    resetCharacterPhysics()
                    isUnderground = false

                    if _G.KillAfterFarm then
                        task.wait(0.1)
                        if hum and hum.Health > 0 then
                            hum.Health = 0
                        end
                    end
                end
                task.wait(0.4)
                continue
            end

            local targetCoin = getBestCoin(hrp, char)
            if targetCoin and targetCoin.Parent then
                hum.PlatformStand = true
                isUnderground = true

                while getgenv().CoinFarmActive 
                    and getgenv().MM2_CoinFarm_ID == currentID 
                    and isActivelyInRound() 
                    and not isBagFull()
                    and targetCoin.Parent 
                    and targetCoin.Transparency < 1 do
                    
                    local dt = RunService.Heartbeat:Wait()
                    if not hrp or not hrp.Parent then break end

                    local currentPos = hrp.Position
                    local targetUndergroundPos = Vector3.new(targetCoin.Position.X, targetCoin.Position.Y + UNDERGROUND_OFFSET, targetCoin.Position.Z)
                    local offsetVec = targetUndergroundPos - currentPos
                    local horizontalDist = Vector2.new(offsetVec.X, offsetVec.Z).Magnitude

                    if horizontalDist ~= horizontalDist or horizontalDist > 400 then break end

                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero

                    if horizontalDist <= 2.2 then
                        local startPos = hrp.Position
                        local surfacePos = targetCoin.Position
                        local upSteps = 20

                        for i = 1, upSteps do
                            if not hrp or not hrp.Parent then break end
                            local alpha = i / upSteps
                            local lerpPos = startPos:Lerp(surfacePos, alpha)
                            hrp.CFrame = CFrame.new(lerpPos) * CFrame.Angles(math.rad(90), 0, 0)
                            RunService.Heartbeat:Wait()
                        end

                        task.wait(0.1)

                        local topPos = hrp.Position
                        for i = 1, upSteps do
                            if not hrp or not hrp.Parent then break end
                            local alpha = i / upSteps
                            local lerpPos = topPos:Lerp(targetUndergroundPos, alpha)
                            hrp.CFrame = CFrame.new(lerpPos) * CFrame.Angles(math.rad(90), 0, 0)
                            RunService.Heartbeat:Wait()
                        end
                        break
                    else
                        local step = math.min(SPEED * dt, horizontalDist)
                        local moveDir = Vector3.new(offsetVec.X, 0, offsetVec.Z).Unit
                        local nextPos = currentPos + (moveDir * step)
                        
                        hrp.CFrame = CFrame.new(Vector3.new(nextPos.X, targetUndergroundPos.Y, nextPos.Z)) * CFrame.Angles(math.rad(90), 0, 0)
                    end
                end
            else
                if isUnderground then
                    resetCharacterPhysics()
                    isUnderground = false
                end
                task.wait(0.2)
            end
        else
            task.wait(0.2)
        end
    end

    if getgenv().CoinFarm_NoclipConn then
        getgenv().CoinFarm_NoclipConn:Disconnect()
        getgenv().CoinFarm_NoclipConn = nil
    end
    resetCharacterPhysics()
    isUnderground = false
end)
end)


-- ////////////////////////////////////////////////////////////////////////////////////////////////
-- ///////////////////////////////////////////Teleport/////////////////////////////////////////////

local TeleportTab = Window:AddTab({
    Name = "Teleport",
    Description = "",
    Icon = "navigation",
    Tooltip = "Quick player and map teleports",
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    if #list == 0 then
        table.insert(list, "No Players")
    end
    return list
end

local Tele1GroupBox = TeleportTab:AddGroupbox({
    Side = "Left",
    Name = "Player Teleport",
    Description = "",
    IconName = "user",
    DisableCollapsing = true,
})

local MyDropdown = Tele1GroupBox:AddDropdown("MyDropdown", {
    Text = "Target",
    Values = getPlayerList(),
    Default = 1,
    Multi = false,
})

Players.PlayerAdded:Connect(function()
    pcall(function()
        MyDropdown:SetValues(getPlayerList())
    end)
end)

Players.PlayerRemoving:Connect(function()
    pcall(function()
        MyDropdown:SetValues(getPlayerList())
    end)
end)

Tele1GroupBox:AddButton({
    Text = "Teleport",
    Func = function()
        Library:Notify({ Title = "Teleport", Description = "Teleporting to target player!", Time = 4 })
        local selectedName = MyDropdown.Value
        if type(selectedName) == "table" then
            selectedName = selectedName[1]
        end
        if not selectedName or selectedName == "No Players" or selectedName == "" then return end
        
        local targetPlayer = Players:FindFirstChild(selectedName)
        if targetPlayer and targetPlayer.Character then
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP and myHRP then
                myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 3)
            end
        end
    end
})

local Tele2Groupbox = TeleportTab:AddGroupbox({
    Side = "Right",
    Name = "Roles & Lobby",
    Description = "",
    IconName = "map",
    DisableCollapsing = true,
})

Tele2Groupbox:AddButton({
    Text = "Teleport To Lobby",
    Callback = function()
    Library:Notify({ Title = "Teleport", Description = "Teleporting to lobby!", Time = 4 })
pcall(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, folder in pairs(workspace:GetChildren()) do
        if folder:IsA("Model") or folder:IsA("Folder") then
            if string.find(string.lower(folder.Name), "lobby") then
                for _, object in pairs(folder:GetDescendants()) do
                    if object:IsA("SpawnLocation") then
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        hrp.CFrame = object.CFrame + Vector3.new(0, 5, 0)
                        return
                    end
                end
            end
        end
    end
end)
    end,
})

Tele2Groupbox:AddButton({
    Text = "Teleport To Map",
    Callback = function()
    Library:Notify({ Title = "Teleport", Description = "Teleporting to map spawns!", Time = 4 })
pcall(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local function TargetModel(target)
        for _, model in pairs(workspace:GetChildren()) do
            if model:IsA("Model") and not string.find(string.lower(model.Name), "lobby") then
                local spawnsFolder = model:FindFirstChild("Spawns")
                if target == "Spawns" and spawnsFolder then
                    return spawnsFolder
                end
            end
        end
        return nil
    end

    local spawns = TargetModel("Spawns")
    if spawns then
        for _, spawn in ipairs(spawns:GetDescendants()) do
            if spawn:IsA("BasePart") or spawn:IsA("SpawnLocation") then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
                break
            end
        end
    end
end)
    end,
})

Tele2Groupbox:AddDivider()

Tele2Groupbox:AddButton({
    Text = "Murderer",
    Func = function()
        Library:Notify({ Title = "Teleport", Description = "Teleporting to Murderer!", Time = 4 })
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local bp = p:FindFirstChildOfClass("Backpack")
                local char = p.Character
                if (bp and bp:FindFirstChild("Knife")) or char:FindFirstChild("Knife") then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and myHRP then
                        myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 3)
                        break
                    end
                end
            end
        end
    end
})

Tele2Groupbox:AddButton({
    Text = "Sheriff",
    Func = function()
        Library:Notify({ Title = "Teleport", Description = "Teleporting to Sheriff!", Time = 4 })
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local bp = p:FindFirstChildOfClass("Backpack")
                local char = p.Character
                if (bp and bp:FindFirstChild("Gun")) or char:FindFirstChild("Gun") then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and myHRP then
                        myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 3)
                        break
                    end
                end
            end
        end
    end
})


-- ////////////////////////////////////////////////////////////////////////////////////////////////
-- ////////////////////////////////////////Animations//////////////////////////////////////////////

local AnimationPackTab = Window:AddTab({
    Name = "Animations",
    Description = "",
    Icon = "smile",
    Tooltip = "Custom animation packs",
})

local function applyAnimation(tabList, packName)
    Library:Notify({ Title = "Animations", Description = "Applied animation pack: " .. packName, Time = 4 })
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Animate = Character:WaitForChild("Animate")
    local Humanoid = Character:WaitForChild("Humanoid")

    local function setAnim(folderName, animName, id)
        local folder = Animate:FindFirstChild(folderName)
        if folder then
            local anim = folder:FindFirstChild(animName) or folder:FindFirstChildOfClass("Animation")
            if anim then anim.AnimationId = id end
        end
    end

    setAnim("idle", "Animation1", tabList[1])
    setAnim("idle", "Animation2", tabList[2])
    setAnim("walk", "WalkAnim", tabList[3])
    setAnim("run", "RunAnim", tabList[4])
    setAnim("jump", "JumpAnim", tabList[5])
    setAnim("fall", "FallAnim", tabList[6])
    setAnim("climb", "ClimbAnim", tabList[7])
    setAnim("swim", "Swim", tabList[8])
    setAnim("swimming", "Swim", tabList[9])

    for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end
end

local AnimationgroupboxOne = AnimationPackTab:AddGroupbox({
    Side = "Left",
    Name = "Packs Part 1",
    Description = "",
    IconName = "smile",
    DisableCollapsing = true,
})

AnimationgroupboxOne:AddButton({ Text = "Astronaut", Func = function() applyAnimation({"rbxassetid://891621366", "rbxassetid://891633237", "rbxassetid://891668102", "rbxassetid://891636393", "rbxassetid://891627522", "rbxassetid://891617961", "rbxassetid://891609353", "rbxassetid://891645063", "rbxassetid://891656094"}, "Astronaut") end })
AnimationgroupboxOne:AddButton({ Text = "Bubblegum", Func = function() applyAnimation({"rbxassetid://910004836", "rbxassetid://910009958", "rbxassetid://910030921", "rbxassetid://910025107", "rbxassetid://910016857", "rbxassetid://910001910", "rbxassetid://909998782", "rbxassetid://910020188", "rbxassetid://910022207"}, "Bubblegum") end })
AnimationgroupboxOne:AddButton({ Text = "Cartoony", Func = function() applyAnimation({"rbxassetid://742637544", "rbxassetid://742638445", "rbxassetid://742640026", "rbxassetid://742638842", "rbxassetid://742637942", "rbxassetid://742636889", "rbxassetid://742636368", "rbxassetid://742639148", "rbxassetid://742639591"}, "Cartoony") end })
AnimationgroupboxOne:AddButton({ Text = "Knight", Func = function() applyAnimation({"rbxassetid://657593203", "rbxassetid://657593203", "rbxassetid://657552424", "rbxassetid://657564596", "rbxassetid://658409194", "rbxassetid://657600962", "rbxassetid://658360781", "rbxassetid://657571211", "rbxassetid://657579822"}, "Knight") end })
AnimationgroupboxOne:AddButton({ Text = "Levitation", Func = function() applyAnimation({"rbxassetid://616006778", "rbxassetid://616008087", "rbxassetid://616013216", "rbxassetid://616010382", "rbxassetid://616008936", "rbxassetid://616005863", "rbxassetid://616003713", "rbxassetid://616011509", "rbxassetid://616012453"}, "Levitation") end })
AnimationgroupboxOne:AddButton({ Text = "Mage", Func = function() applyAnimation({"rbxassetid://707742142", "rbxassetid://707855907", "rbxassetid://707897309", "rbxassetid://707861613", "rbxassetid://707853694", "rbxassetid://707829716", "rbxassetid://707826000", "rbxassetid://707867822", "rbxassetid://707886001"}, "Mage") end })
AnimationgroupboxOne:AddButton({ Text = "Ninja", Func = function() applyAnimation({"rbxassetid://656117400", "rbxassetid://656118341", "rbxassetid://656121766", "rbxassetid://656118852", "rbxassetid://656117801", "rbxassetid://656115606", "rbxassetid://656114830", "rbxassetid://656120666", "rbxassetid://656121109"}, "Ninja") end })
AnimationgroupboxOne:AddButton({ Text = "Pirate", Func = function() applyAnimation({"rbxassetid://750781874", "rbxassetid://750782770", "rbxassetid://750785693", "rbxassetid://750783738", "rbxassetid://750782230", "rbxassetid://750780242", "rbxassetid://750779899", "rbxassetid://750784238", "rbxassetid://750785002"}, "Pirate") end })

local AnimationGroupboxTwo = AnimationPackTab:AddGroupbox({
    Side = "Right",
    Name = "Packs Part 2",
    Description = "",
    IconName = "smile",
    DisableCollapsing = true,
})

AnimationGroupboxTwo:AddButton({ Text = "Popstar", Func = function() applyAnimation({"rbxassetid://1212980348", "rbxassetid://1212980348", "rbxassetid://1212954642", "rbxassetid://1212980348", "rbxassetid://1212954642", "rbxassetid://1212900995", "rbxassetid://1213044953", "rbxassetid://1212852603", "rbxassetid://1212998578"}, "Popstar") end })
AnimationGroupboxTwo:AddButton({ Text = "Robot", Func = function() applyAnimation({"rbxassetid://616088211", "rbxassetid://616089759", "rbxassetid://616095330", "rbxassetid://616091570", "rbxassetid://616090535", "rbxassetid://616087089", "rbxassetid://616086103", "rbxassetid://616092788", "rbxassetid://616094281"}, "Robot") end })
AnimationGroupboxTwo:AddButton({ Text = "Stylish", Func = function() applyAnimation({"rbxassetid://616136790", "rbxassetid://616138447", "rbxassetid://616146170", "rbxassetid://616140816", "rbxassetid://616139451", "rbxassetid://616134815", "rbxassetid://616133594", "rbxassetid://616142382", "rbxassetid://616143973"}, "Stylish") end })
AnimationGroupboxTwo:AddButton({ Text = "Superhero", Func = function() applyAnimation({"rbxassetid://616111295", "rbxassetid://616113536", "rbxassetid://616123282", "rbxassetid://616117082", "rbxassetid://616115533", "rbxassetid://616109313", "rbxassetid://616104706", "rbxassetid://616119866", "rbxassetid://616121616"}, "Superhero") end })
AnimationGroupboxTwo:AddButton({ Text = "Toy", Func = function() applyAnimation({"rbxassetid://782841498", "rbxassetid://782845736", "rbxassetid://782843345", "rbxassetid://782842708", "rbxassetid://782847020", "rbxassetid://782846423", "rbxassetid://782843869", "rbxassetid://782844519", "rbxassetid://782845134"}, "Toy") end })
AnimationGroupboxTwo:AddButton({ Text = "Vampire", Func = function() applyAnimation({"rbxassetid://1083445855", "rbxassetid://1083450166", "rbxassetid://1083473922", "rbxassetid://1083462077", "rbxassetid://1083455352", "rbxassetid://1083443587", "rbxassetid://1083439243", "rbxassetid://1083466106", "rbxassetid://1083468798"}, "Vampire") end })
AnimationGroupboxTwo:AddButton({ Text = "Werewolf", Func = function() applyAnimation({"rbxassetid://1083195517", "rbxassetid://1083214717", "rbxassetid://1083178339", "rbxassetid://1083216690", "rbxassetid://1083218792", "rbxassetid://1083189019", "rbxassetid://1083182000", "rbxassetid://1083220883", "rbxassetid://1083222378"}, "Werewolf") end })
AnimationGroupboxTwo:AddButton({ Text = "Zombie", Func = function() applyAnimation({"rbxassetid://616158929", "rbxassetid://616160032", "rbxassetid://616168032", "rbxassetid://616163682", "rbxassetid://616161997", "rbxassetid://616157476", "rbxassetid://616156119", "rbxassetid://616165109", "rbxassetid://616166651"}, "Zombie") end })


-- ////////////////////////////////////////////////////////////////////////////////////////////////
-- ///////////////////////////////////////////Limiteds/////////////////////////////////////////////

local LimitedsTab = Window:AddTab({
    Name = "Limiteds",
    Description = "",
    Icon = "star",
    Tooltip = "Visual limited items",
})

local LimitedsGroupboxOne = LimitedsTab:AddGroupbox({
    Side = "Left",
    Name = "Items",
    Description = "",
    IconName = "star",
    DisableCollapsing = true,
})

local HeadlessToggle = LimitedsGroupboxOne:AddToggle("HeadlessToggle", {
    Text = "Headless",
    Default = false,
})

Toggles.HeadlessToggle:OnChanged(function(state)
    Library:Notify({ Title = "Limiteds", Description = state and "Headless Enabled" or "Headless Disabled", Time = 4 })
    local player = game.Players.LocalPlayer
    getgenv().HeadlessEnabled = state

    local function applyHeadless(character)
        local head = character:WaitForChild("Head", 5)
        if not head then return end
        
        task.spawn(function()
            while getgenv().HeadlessEnabled and character and character.Parent and head do
                head.Transparency = 1
                for _, v in pairs(head:GetChildren()) do
                    if v:IsA("Decal") then
                        v.Transparency = 1
                    end
                end
                task.wait(1)
            end
            
            if not getgenv().HeadlessEnabled and head and head.Parent then
                head.Transparency = 0
                for _, v in pairs(head:GetChildren()) do
                    if v:IsA("Decal") then
                        v.Transparency = 0
                    end
                end
            end
        end)
    end

    if state then
        if player.Character then
            applyHeadless(player.Character)
        end
    end

    if not getgenv().HeadlessConnection then
        getgenv().HeadlessConnection = player.CharacterAdded:Connect(function(newChar)
            if getgenv().HeadlessEnabled then
                task.wait(0.5)
                applyHeadless(newChar)
            end
        end)
    end
end)

local KorbloxToggle = LimitedsGroupboxOne:AddToggle("KorbloxToggle", {
    Text = "Korblox",
    Default = false,
})

Toggles.KorbloxToggle:OnChanged(function(state)
    Library:Notify({ Title = "Limiteds", Description = state and "Korblox Enabled" or "Korblox Disabled", Time = 4 })
    local player = game.Players.LocalPlayer
    getgenv().KorbloxEnabled = state

    local function applyKorblox(character)
        local rLower = character:WaitForChild("RightLowerLeg", 5)
        local rUpper = character:WaitForChild("RightUpperLeg", 5)
        local rFoot = character:WaitForChild("RightFoot", 5)
        local upperAttachment = rUpper:WaitForChild("RightHipRigAttachment", 5)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if not rLower or not rUpper or not rFoot or not upperAttachment then return end

        if not getgenv().KorbloxOriginals then
            getgenv().KorbloxOriginals = {
                LowerMesh = rLower.MeshId,
                LowerTrans = rLower.Transparency,
                UpperMesh = rUpper.MeshId,
                UpperTex = rUpper.TextureID,
                UpperTrans = rUpper.Transparency,
                FootMesh = rFoot.MeshId,
                FootTrans = rFoot.Transparency,
                AttachmentCFrame = upperAttachment.CFrame
            }
        end

        if not getgenv().KorbloxEnabled then
            local orig = getgenv().KorbloxOriginals
            if orig then
                rLower.MeshId = orig.LowerMesh
                rLower.Transparency = orig.LowerTrans
                rUpper.MeshId = orig.UpperMesh
                rUpper.TextureID = orig.UpperTex
                rUpper.Transparency = orig.UpperTrans
                rFoot.MeshId = orig.FootMesh
                rFoot.Transparency = orig.FootTrans
                upperAttachment.CFrame = orig.AttachmentCFrame
                
                if humanoid then
                    local currentJump = humanoid.JumpPower
                    humanoid.JumpPower = 0
                    task.delay(0.1, function()
                        humanoid.JumpPower = currentJump
                    end)
                end
            end
            return
        end

        task.spawn(function()
            while getgenv().KorbloxEnabled and character and character.Parent do
                rUpper.MeshId = "http://www.roblox.com/asset/?id=902942096"
                rUpper.TextureID = "http://roblox.com/asset/?id=902843398"
                rUpper.Transparency = 0
                
                rLower.MeshId = "902942093"
                rLower.Transparency = 1
                
                rFoot.MeshId = "902942089"
                rFoot.Transparency = 1
                
                upperAttachment.CFrame = CFrame.new(0, 0.19, 0)
                
                task.wait(0.5)
            end
            
            if not getgenv().KorbloxEnabled and rLower and rLower.Parent then
                local orig = getgenv().KorbloxOriginals
                if orig then
                    rLower.MeshId = orig.LowerMesh
                    rLower.Transparency = orig.LowerTrans
                    rUpper.MeshId = orig.UpperMesh
                    rUpper.TextureID = orig.UpperTex
                    rUpper.Transparency = orig.UpperTrans
                    rFoot.MeshId = orig.FootMesh
                    rFoot.Transparency = orig.FootTrans
                    upperAttachment.CFrame = orig.AttachmentCFrame
                    
                    if humanoid then
                        local currentJump = humanoid.JumpPower
                        humanoid.JumpPower = 0
                        task.delay(0.1, function()
                            humanoid.JumpPower = currentJump
                        end)
                    end
                end
            end
        end)
    end

    if player.Character then
        applyKorblox(player.Character)
    end

    if not getgenv().KorbloxConnection then
        getgenv().KorbloxConnection = player.CharacterAdded:Connect(function(newChar)
            if getgenv().KorbloxEnabled then
                task.wait(0.5)
                applyKorblox(newChar)
            end
        end)
    end
end)

LimitedsGroupboxOne:AddDivider()

local FieryHornsToggle = LimitedsGroupboxOne:AddToggle("FieryHornsToggle", {
    Text = "Fiery Horns",
    Default = false,
})

Toggles.FieryHornsToggle:OnChanged(function(state)
    Library:Notify({ Title = "Limiteds", Description = state and "Fiery Horns Enabled" or "Fiery Horns Disabled", Time = 4 })
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    if not state then
        _G.FieryHornsRunning = false
        if _G.CleanupFieryHorns then _G.CleanupFieryHorns() end
        if player.Character then
            local horn = player.Character:FindFirstChild("FieryHorns_Custom")
            if horn then horn:Destroy() end
        end
        return
    end

    _G.FieryHornsRunning = true
    local activeAccessory = nil
    local connection = nil

    local function cleanup()
        if connection then connection:Disconnect() connection = nil end
        if activeAccessory and activeAccessory.Parent then
            activeAccessory:Destroy()
        end
        if player.Character then
            local horn = player.Character:FindFirstChild("FieryHorns_Custom")
            if horn then horn:Destroy() end
        end
        activeAccessory = nil
    end
    _G.CleanupFieryHorns = cleanup

    local function weldParts(part0, part1, c0, c1)
        for _, child in pairs(part1:GetChildren()) do
            if child:IsA("Weld") or child:IsA("WeldConstraint") or child.Name == "AccessoryWeld" then
                child:Destroy()
            end
        end
        local weld = Instance.new("Weld")
        weld.Name = "AccessoryWeld"
        weld.Part0 = part0
        weld.Part1 = part1
        weld.C0 = c0
        weld.C1 = c1
        weld.Parent = part0
        return weld
    end

    local function findAttachment(rootPart, name)
        if not rootPart then return nil end
        for _, d in pairs(rootPart:GetDescendants()) do
            if d:IsA("Attachment") and d.Name == name then return d end
        end
        return nil
    end

    local function apply(character)
        if not _G.FieryHornsRunning then return end
        local head = character:WaitForChild("Head", 3)
        if not head then return end

        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://215718515")
        end)
        if not success or not result or #result == 0 or not _G.FieryHornsRunning then return end

        local accessory = result[1]
        accessory.Name = "FieryHorns_Custom"
        accessory.Parent = workspace

        local handle = accessory:FindFirstChild("Handle")
        if not handle or not handle:IsA("BasePart") then
            accessory:Destroy()
            return
        end

        local att = handle:FindFirstChildOfClass("Attachment")
        if att then
            local pAtt = findAttachment(head, att.Name)
            if pAtt then
                weldParts(head, handle, pAtt.CFrame, att.CFrame)
            else
                weldParts(head, handle, CFrame.new(0, 0, 0), att.CFrame)
            end
        else
            weldParts(head, handle, CFrame.new(0, 0.5, 0), CFrame.new())
        end

        handle.CanCollide = false
        accessory.Parent = character
        activeAccessory = accessory

        accessory.AncestryChanged:Connect(function(_, parent)
            if parent == nil and character.Parent and _G.FieryHornsRunning then
                task.delay(0.1, function()
                    if character.Parent and _G.FieryHornsRunning then
                        accessory.Parent = character
                    end
                end)
            end
        end)
    end

    connection = player.CharacterAdded:Connect(function(char)
        task.spawn(function()
            apply(char)
        end)
    end)

    if player.Character then
        task.spawn(function()
            apply(player.Character)
        end)
    end
end)

local FrozenHornsToggle = LimitedsGroupboxOne:AddToggle("FrozenHornsToggle", {
    Text = "Frozen Horns",
    Default = false,
})

Toggles.FrozenHornsToggle:OnChanged(function(state)
    Library:Notify({ Title = "Limiteds", Description = state and "Frozen Horns Enabled" or "Frozen Horns Disabled", Time = 4 })
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    if not state then
        _G.FrozenHornsRunning = false
        if _G.CleanupFrozenHorns then _G.CleanupFrozenHorns() end
        if player.Character then
            local horn = player.Character:FindFirstChild("FrozenHorns_Custom")
            if horn then horn:Destroy() end
        end
        return
    end

    _G.FrozenHornsRunning = true
    local activeAccessory = nil
    local connection = nil

    local function cleanup()
        if connection then connection:Disconnect() connection = nil end
        if activeAccessory and activeAccessory.Parent then
            activeAccessory:Destroy()
        end
        if player.Character then
            local horn = player.Character:FindFirstChild("FrozenHorns_Custom")
            if horn then horn:Destroy() end
        end
        activeAccessory = nil
    end
    _G.CleanupFrozenHorns = cleanup

    local function weldParts(part0, part1, c0, c1)
        for _, child in pairs(part1:GetChildren()) do
            if child:IsA("Weld") or child:IsA("WeldConstraint") or child.Name == "AccessoryWeld" then
                child:Destroy()
            end
        end
        local weld = Instance.new("Weld")
        weld.Name = "AccessoryWeld"
        weld.Part0 = part0
        weld.Part1 = part1
        weld.C0 = c0
        weld.C1 = c1
        weld.Parent = part0
        return weld
    end

    local function findAttachment(rootPart, name)
        if not rootPart then return nil end
        for _, d in pairs(rootPart:GetDescendants()) do
            if d:IsA("Attachment") and d.Name == name then return d end
        end
        return nil
    end

    local function apply(character)
        if not _G.FrozenHornsRunning then return end
        local head = character:WaitForChild("Head", 3)
        if not head then return end

        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://74891470")
        end)
        if not success or not result or #result == 0 or not _G.FrozenHornsRunning then return end

        local accessory = result[1]
        accessory.Name = "FrozenHorns_Custom"
        accessory.Parent = workspace

        local handle = accessory:FindFirstChild("Handle")
        if not handle or not handle:IsA("BasePart") then
            accessory:Destroy()
            return
        end

        local att = handle:FindFirstChildOfClass("Attachment")
        if att then
            local pAtt = findAttachment(head, att.Name)
            if pAtt then
                weldParts(head, handle, pAtt.CFrame, att.CFrame)
            else
                weldParts(head, handle, CFrame.new(0, 0, 0), att.CFrame)
            end
        else
            weldParts(head, handle, CFrame.new(0, 0.5, 0), CFrame.new())
        end

        handle.CanCollide = false
        accessory.Parent = character
        activeAccessory = accessory

        accessory.AncestryChanged:Connect(function(_, parent)
            if parent == nil and character.Parent and _G.FrozenHornsRunning then
                task.delay(0.1, function()
                    if character.Parent and _G.FrozenHornsRunning then
                        accessory.Parent = character
                    end
                end)
            end
        end)
    end

    connection = player.CharacterAdded:Connect(function(char)
        task.spawn(function()
            apply(char)
        end)
    end)

    if player.Character then
        task.spawn(function()
            apply(player.Character)
        end)
    end
end)

local PoisonedHornsToggle = LimitedsGroupboxOne:AddToggle("PoisonedHornsToggle", {
    Text = "Poisoned Horns",
    Default = false,
})

Toggles.PoisonedHornsToggle:OnChanged(function(state)
    Library:Notify({ Title = "Limiteds", Description = state and "Poisoned Horns Enabled" or "Poisoned Horns Disabled", Time = 4 })
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    if not state then
        _G.PoisonedHornsRunning = false
        if _G.CleanupPoisonedHorns then _G.CleanupPoisonedHorns() end
        if player.Character then
            local horn = player.Character:FindFirstChild("PoisonedHorns_Custom")
            if horn then horn:Destroy() end
        end
        return
    end

    _G.PoisonedHornsRunning = true
    local activeAccessory = nil
    local connection = nil

    local function cleanup()
        if connection then connection:Disconnect() connection = nil end
        if activeAccessory and activeAccessory.Parent then
            activeAccessory:Destroy()
        end
        if player.Character then
            local horn = player.Character:FindFirstChild("PoisonedHorns_Custom")
            if horn then horn:Destroy() end
        end
        activeAccessory = nil
    end
    _G.CleanupPoisonedHorns = cleanup

    local function weldParts(part0, part1, c0, c1)
        for _, child in pairs(part1:GetChildren()) do
            if child:IsA("Weld") or child:IsA("WeldConstraint") or child.Name == "AccessoryWeld" then
                child:Destroy()
            end
        end
        local weld = Instance.new("Weld")
        weld.Name = "AccessoryWeld"
        weld.Part0 = part0
        weld.Part1 = part1
        weld.C0 = c0
        weld.C1 = c1
        weld.Parent = part0
        return weld
    end

    local function findAttachment(rootPart, name)
        if not rootPart then return nil end
        for _, d in pairs(rootPart:GetDescendants()) do
            if d:IsA("Attachment") and d.Name == name then return d end
        end
        return nil
    end

    local function apply(character)
        if not _G.PoisonedHornsRunning then return end
        local head = character:WaitForChild("Head", 3)
        if not head then return end

        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://1744060292")
        end)
        if not success or not result or #result == 0 or not _G.PoisonedHornsRunning then return end

        local accessory = result[1]
        accessory.Name = "PoisonedHorns_Custom"
        accessory.Parent = workspace

        local handle = accessory:FindFirstChild("Handle")
        if not handle or not handle:IsA("BasePart") then
            accessory:Destroy()
            return
        end

        local att = handle:FindFirstChildOfClass("Attachment")
        if att then
            local pAtt = findAttachment(head, att.Name)
            if pAtt then
                weldParts(head, handle, pAtt.CFrame, att.CFrame)
            else
                weldParts(head, handle, CFrame.new(0, 0, 0), att.CFrame)
            end
        else
            weldParts(head, handle, CFrame.new(0, 0.5, 0), CFrame.new())
        end

        handle.CanCollide = false
        accessory.Parent = character
        activeAccessory = accessory

        accessory.AncestryChanged:Connect(function(_, parent)
            if parent == nil and character.Parent and _G.PoisonedHornsRunning then
                task.delay(0.1, function()
                    if character.Parent and _G.PoisonedHornsRunning then
                        accessory.Parent = character
                    end
                end)
            end
        end)
    end

    connection = player.CharacterAdded:Connect(function(char)
        task.spawn(function()
            apply(char)
        end)
    end)

    if player.Character then
        task.spawn(function()
            apply(player.Character)
        end)
    end
end)


-- ////////////////////////////////////////////////////////////////////////////////////////////////
-- ////////////////////////////////////////UI Settings/////////////////////////////////////////////

local UISettingsTab = Window:AddTab({
    Name = "Settings",
    Description = "",
    Icon = "settings",
    Tooltip = "UI configuration and configs",
})

local MenuGroup = UISettingsTab:AddGroupbox({
	Side = "Left",
	Name = "Menu",
	IconName = "wrench"
})

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library:Notify({ Title = "Settings", Description = value and "Keybind Menu Opened" or "Keybind Menu Closed", Time = 4 })
		Library.KeybindFrame.Visible = value
	end,
})

MenuGroup:AddToggle("KeybindMenuVisibilityControl", {
	Default = false,
	Text = "Keybind Menu Visibility",
	Callback = function(value)
		Library:Notify({ Title = "Settings", Description = value and "Keybind Visibility Control Enabled" or "Keybind Visibility Control Disabled", Time = 4 })
		Library.KeybindMenu:SetVisibilityControl(value)
	end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = Library.ShowCustomCursor,
	Callback = function(Value)
		Library:Notify({ Title = "Settings", Description = Value and "Custom Cursor Enabled" or "Custom Cursor Disabled", Time = 4 })
		Library.ShowCustomCursor = Value
	end,
})

MenuGroup:AddToggle("AlwaysOnTop", {
	Text = "Always On Top",
	Default = Window.AlwaysOnTop,
	Callback = function(Value)
		Library:Notify({ Title = "Settings", Description = Value and "Always On Top Enabled" or "Always On Top Disabled", Time = 4 })
		Window:SetAlwaysOnTop(Value)
	end,
})

MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(Value)
		Library:Notify({ Title = "Settings", Description = "Notification side set to " .. tostring(Value), Time = 4 })
		Library:SetNotifySide(Value)
	end,
})

MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",
	Text = "DPI Scale",
	Callback = function(Value)
		Library:Notify({ Title = "Settings", Description = "DPI Scale set to " .. tostring(Value), Time = 4 })
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)
		Library:SetDPIScale(DPI)
	end,
})

MenuGroup:AddSlider("UICornerSlider", {
	Text = "Corner Radius",
	Default = Library.CornerRadius,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(value)
		Window:SetCornerRadius(value)
	end
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
	Library:Notify({ Title = "Settings", Description = "Unloading UI...", Time = 4 })
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("Solaris MM2")
SaveManager:SetFolder("Solaris MM2")
SaveManager:SetSubFolder("Solaris MM2")

SaveManager:BuildConfigSection(UISettingsTab)
ThemeManager:ApplyToTab(UISettingsTab)

SaveManager:LoadAutoloadConfig()
