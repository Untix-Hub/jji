repeat wait() until game:IsLoaded()

local player = game.Players.LocalPlayer
local guiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local teleportService = game:GetService("TeleportService")

function quickJoin()
    game:GetService("ReplicatedStorage").Remotes.Server.Raids.QuickStart:InvokeServer(config.mode, config.level, config.difficulty)
end

function getQuest()
    local questInfo = string.lower(game:GetService("Players").LocalPlayer.PlayerGui.StorylineDialogue.Frame.QuestFrame.QuestInfo.Task.Description.Text)
    if string.find(questInfo, "exorcise") then
        return "kill"
    elseif string.find(questInfo, "rescue") then
        return "save"
    elseif string.find(questInfo, "collect") then
        return "find"
    end
end

function voidMobs()
    for _, v in pairs(workspace.Objects.Mobs:GetChildren()) do
        local humanoidRootPart = v:FindFirstChild("HumanoidRootPart")
        local humanoid = v:FindFirstChild("Humanoid")
        if humanoidRootPart and humanoid then
            repeat
                player.Character.HumanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position)
                humanoid.Health = 0
                wait()
            until humanoid:FindFirstChild("CombatAgent") and humanoid.CombatAgent.Dead.Value
        end
    end
end

function saveCivilians()
    for _, v in pairs(workspace.Objects.MissionItems:GetChildren()) do
        local humanoidRootPart = v:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            -- Teleport to the civilian
            
            local prompt = v:FindFirstChildWhichIsA("ProximityPrompt")
            if prompt then
                -- Wait for ProximityPrompt to be interactable
                repeat
                    fireproximityprompt(prompt)
                    wait(0.1)
                    player.Character.HumanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position)
                    wait(0.1) -- wait for teleportation to complete
                until not v:FindFirstChildWhichIsA("ProximityPrompt") or not humanoidRootPart:FindFirstChild("QuestMarker")
                
                -- After saving, teleport back to spawn
                repeat
                    local spawnLocation = workspace.Map.Parts.SpawnLocation.Position
                    player.Character.HumanoidRootPart.CFrame = CFrame.new(spawnLocation)
                    wait(0.1) -- wait for the teleportation to complete
                until v.Parent == nil
            end
        else
            print(v.Name .. " is missing HumanoidRootPart")
        end
    end
end

function collectObjects()
    for _, v in pairs(workspace.Objects.MissionItems:GetChildren()) do
        player.Character.HumanoidRootPart.CFrame = CFrame.new(v.Position)
        task.wait(0.1)
        local prompt = v:FindFirstChild("Collect")
        if prompt then
            repeat
                fireproximityprompt(prompt)
                task.wait(0.1)
            until v.Parent == nil or prompt.Enabled == false
        end
    end
end

function doQuest()
    local task = getQuest()
    if task == "kill" then
		print('kill quest')
        voidMobs()
    elseif task == "save" then
		print('save quest')
        saveCivilians()
    elseif task == "find" then
		print('find quest')
        collectObjects()
    end
	player.Character.HumanoidRootPart.CFrame = CFrame.new(workspace.Map.Parts.SpawnLocation.Position) + Vector3.new(0,55,0)
end

function collectChest(chest)
    local prompt = chest:FindFirstChild("Collect")
    if prompt then
        print("Interacting with chest: " .. chest.Name)
        fireproximityprompt(prompt)

        -- Wait for the loot GUI to appear
        repeat
            wait(0.1)
        until player.PlayerGui.Loot.Enabled == true

        -- Select the flip button and simulate pressing Enter to collect the loot
        repeat
            guiService.SelectedObject = player.PlayerGui.Loot.Frame.Flip
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            wait(0.1)
        until player.PlayerGui.Loot.Enabled == false
    else
        warn("No 'Collect' proximity prompt found for chest: " .. chest.Name)
    end
end

function ensureAllChestsCollected()
    local chests = workspace.Objects.Drops:GetChildren()
    for _, chest in ipairs(chests) do
        if chest:IsA("Model") and chest:FindFirstChild("Collect") then
            collectChest(chest)
        end
    end

    -- Wait and retry for remaining chests
    while #workspace.Objects.Drops:GetChildren() > 0 do
        for _, chest in ipairs(workspace.Objects.Drops:GetChildren()) do
            if chest:IsA("Model") and chest:FindFirstChild("Collect") then
                collectChest(chest)
            end
        end
    end
end

if game.PlaceId == 119359147980471 or game.PlaceId == 78904562518018 then
	quickJoin()
end

if config.mode == "Investigation" then
    print("Investigation Mode")
	repeat wait() until player.PlayerGui:FindFirstChild("StorylineDialogue")

	local skyPart = Instance.new("Part")
	skyPart.Anchored = true;
	skyPart.Parent = workspace
	skyPart.Size = Vector3.new(25,1,25)
	skyPart.Transparency = 0.85
	skyPart.Position = workspace.Map.Parts.SpawnLocation.Position + Vector3.new(0,50,0)

    -- Handle quests
	game:GetService("Players").LocalPlayer.PlayerGui.StorylineDialogue.Frame.QuestFrame.QuestInfo.Task.Description:GetPropertyChangedSignal("Text"):Connect(function()
		player.Character.HumanoidRootPart.CFrame = CFrame.new(workspace.Map.Parts.SpawnLocation.Position) + Vector3.new(0,55,0)
		task.wait(10)
        doQuest()
    end)
end

player.PlayerGui.Results:GetPropertyChangedSignal("Enabled"):Connect(function()
    if player.PlayerGui.Results.Enabled then
        ensureAllChestsCollected()
        
        -- Wait for Ready Screen and restart
        repeat wait() until player.PlayerGui.ReadyScreen.Enabled
        guiService.SelectedObject = player.PlayerGui.ReadyScreen.Frame.Replay
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end
end)
player.OnTeleport:Connect(function()
    queueteleport("loadstring(game:HttpGet('https://github.com/Untix-Hub/jji/blob/main/autofarm.lua'))()")
end)
