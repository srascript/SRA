local me = game:GetService("Players").LocalPlayer
local plrs = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local input = game:GetService("UserInputService")
local tween = game:GetService("TweenService")
local run = game:GetService("RunService")
local light = game:GetService("Lighting")
local rp = game:GetService("ReplicatedStorage")
local camera = workspace.CurrentCamera

local ToggleControls = {}
local SliderControls = {}
local GhostRuns = {}
local GhostFuncIndex = {
	Fullbright = {
		oldClockTime = nil,
		oldBrightness = nil,
	}
}

local ws = workspace
local rs_rep = game:GetService("ReplicatedStorage")
local PlayerGui = me:WaitForChild("PlayerGui")

local NoFailLockpick_Enabled = false
local lockpickAddedConnection = nil

local BredMakurz_Enabled = false
local bredMakurzConnection = nil

local OpenNearbyDoors_Enabled = false
local UnlockNearbyDoors_Enabled = false
local NearbyDoorInteraction_Coroutine = nil

local AdminCheck_Enabled = false
local AdminCheck_Connection = nil

local MeleeAura_Enabled = false
local MeleeAura_Connection = nil

local Ragebot_Enabled = false
local Ragebot_Coroutine = nil

local NoRecoil_Enabled = false
local NoRecoil_Connections = {}
local GlobalOriginalValues = {}
local WeaponCache = {}

local InfiniteStamina_Enabled = false
local isInfiniteStaminaEnabled = false
local oldStaminaFunction = nil
local targetFunction = nil

local Aimbot_Enabled = false
local AimBotSettings = {
	Enabled = false,
	TeamCheck = false,
	WallCheck = true,
	StickyAim = false,
	UseMouse = true,
	MouseBind = "MouseButton2",
	Keybind = nil,
	ShowFov = false,
	Fov = 100,
	Smoothing = 0.02,
	AimPart = "HumanoidRootPart",
	IsAimKeyDown = false,
	Target = nil,
	CameraTween = nil
}

do -- AIMBOT: adapted from original source, using existing globals
	local players_aim = plrs
	local localPlayer_aim = me
	local CurrentCamera_aim = camera
	local TweenService_aim = tween
	local UserInputService_aim = input
	local mouseLocation_aim = UserInputService_aim.GetMouseLocation
	local RunService_aim = run

	local function IsAlive_aim(Player)
		return Player and Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") and Player.Character.Humanoid.Health > 0
	end

	local function GetTeam_aim(Player)
		if not localPlayer_aim.Neutral and Player and Player.Team and game:GetService("Teams"):FindFirstChild(Player.Team.Name) then
			return game:GetService("Teams")[Player.Team.Name]
		end
		return nil
	end

	local function isVisible_aim(targetPosition, character)
		if not AimBotSettings.WallCheck then
			return true
		end

		local ignoreList = {CurrentCamera_aim}
		if localPlayer_aim.Character then table.insert(ignoreList, localPlayer_aim.Character) end
		if character and character:FindFirstChild("Head") and character.Head.Parent then table.insert(ignoreList, character.Head.Parent) end

		local success, obscured = pcall(function()
			return CurrentCamera_aim:GetPartsObscuringTarget({targetPosition}, ignoreList)
		end)

		if not success or obscured == nil then
			return false
		end
		return #obscured == 0
	end

	local function CameraGetClosestToMouse_aim()
		local AimFov = AimBotSettings.Fov
		local targetPlayer = nil
		for i, v in pairs(players_aim:GetPlayers()) do
			if v ~= localPlayer_aim then
				if AimBotSettings.TeamCheck ~= true or GetTeam_aim(v) ~= GetTeam_aim(localPlayer_aim) then
					if IsAlive_aim(v) then
						local char = v.Character
						local aimPartInstance = char and char:FindFirstChild(AimBotSettings.AimPart)
						if aimPartInstance then
							local aimPartPosition = aimPartInstance.Position
							local successWTV, screen_pos, on_screen = pcall(function() return CurrentCamera_aim:WorldToViewportPoint(aimPartPosition) end)
							if successWTV and on_screen then
								local screen_pos_2D = Vector2.new(screen_pos.X, screen_pos.Y)
								local successMouseLoc, mousePos = pcall(mouseLocation_aim, UserInputService_aim)
								if not successMouseLoc then mousePos = Vector2.new() end
								local new_magnitude = (screen_pos_2D - mousePos).Magnitude
								if new_magnitude < AimFov and isVisible_aim(aimPartPosition, char) then
									AimFov = new_magnitude
									targetPlayer = v
								end
							end
						end
					end
				end
			end
		end
		return targetPlayer
	end

	UserInputService_aim.InputBegan:Connect(function(inputObj, gameProcessedEvent)
		if not AimBotSettings then return end
		if gameProcessedEvent or not AimBotSettings.Enabled then return end

		if not AimBotSettings.UseMouse and AimBotSettings.Keybind and inputObj.KeyCode == AimBotSettings.Keybind then
			AimBotSettings.Target = CameraGetClosestToMouse_aim()
			AimBotSettings.IsAimKeyDown = true
		elseif AimBotSettings.UseMouse then
			local bind = ""
			if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
				bind = "MouseButton1"
			elseif inputObj.UserInputType == Enum.UserInputType.MouseButton2 then
				bind = "MouseButton2"
			end

			if bind == AimBotSettings.MouseBind then
				AimBotSettings.Target = CameraGetClosestToMouse_aim()
				AimBotSettings.IsAimKeyDown = true
			end
		end
	end)

	UserInputService_aim.InputEnded:Connect(function(inputObj, gameProcessedEvent)
		if not AimBotSettings then return end
		if gameProcessedEvent or not AimBotSettings.Enabled then return end

		if not AimBotSettings.UseMouse and AimBotSettings.Keybind and inputObj.KeyCode == AimBotSettings.Keybind then
			AimBotSettings.IsAimKeyDown = false
			AimBotSettings.Target = nil
			if AimBotSettings.CameraTween then
				AimBotSettings.CameraTween:Cancel()
				AimBotSettings.CameraTween = nil
			end
		elseif AimBotSettings.UseMouse then
			local bind = ""
			if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
				bind = "MouseButton1"
			elseif inputObj.UserInputType == Enum.UserInputType.MouseButton2 then
				bind = "MouseButton2"
			end

			if bind == AimBotSettings.MouseBind then
				AimBotSettings.IsAimKeyDown = false
				AimBotSettings.Target = nil
				if AimBotSettings.CameraTween then
					AimBotSettings.CameraTween:Cancel()
					AimBotSettings.CameraTween = nil
				end
			end
		end
	end)

	RunService_aim.Heartbeat:Connect(function(deltaTime)
		if AimBotSettings and AimBotSettings.Enabled then
			if AimBotSettings.IsAimKeyDown then
				local currentTarget = AimBotSettings.Target

				if AimBotSettings.StickyAim then
					if currentTarget ~= nil and IsAlive_aim(currentTarget) then
						local targetChar = currentTarget.Character
						local aimPart = targetChar and targetChar:FindFirstChild(AimBotSettings.AimPart)
						if aimPart then
							if AimBotSettings.CameraTween then AimBotSettings.CameraTween:Cancel(); AimBotSettings.CameraTween = nil end
							local networkPing = 0
							local successPing, resultPing = pcall(function() return localPlayer_aim:GetNetworkPing() end)
							if successPing then networkPing = resultPing end
							local predictionOffset = aimPart.Velocity and aimPart.Velocity * (networkPing * 0.1) or Vector3.new()
							local targetCFrame = CFrame.new(CurrentCamera_aim.CFrame.Position, aimPart.Position + predictionOffset)

							local successTween, tweenResult = pcall(function()
								AimBotSettings.CameraTween = TweenService_aim:Create(CurrentCamera_aim, TweenInfo.new(AimBotSettings.Smoothing, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = targetCFrame})
								AimBotSettings.CameraTween:Play()
							end)
							if not successTween then warn("Aimbot Tween creation failed:", tweenResult) end

						else
							AimBotSettings.Target = nil
							if AimBotSettings.CameraTween then AimBotSettings.CameraTween:Cancel(); AimBotSettings.CameraTween = nil end
						end
					else
						local newTarget = CameraGetClosestToMouse_aim()
						AimBotSettings.Target = newTarget
						currentTarget = newTarget

						if currentTarget and IsAlive_aim(currentTarget) then
							local targetChar = currentTarget.Character
							local aimPart = targetChar and targetChar:FindFirstChild(AimBotSettings.AimPart)
							if aimPart then
								if AimBotSettings.CameraTween then AimBotSettings.CameraTween:Cancel(); AimBotSettings.CameraTween = nil end
								local networkPing = 0; local sP, rP = pcall(function() return localPlayer_aim:GetNetworkPing() end); if sP then networkPing = rP end
								local predictionOffset = aimPart.Velocity and aimPart.Velocity * (networkPing * 0.1) or Vector3.new()
								local targetCFrame = CFrame.new(CurrentCamera_aim.CFrame.Position, aimPart.Position + predictionOffset)

								local sT, tR = pcall(function()
									AimBotSettings.CameraTween = TweenService_aim:Create(CurrentCamera_aim, TweenInfo.new(AimBotSettings.Smoothing, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = targetCFrame})
									AimBotSettings.CameraTween:Play()
								end)
								if not sT then warn("Aimbot Tween creation failed (new target):", tR) end
							end
						elseif AimBotSettings.CameraTween then
							AimBotSettings.CameraTween:Cancel(); AimBotSettings.CameraTween = nil
						end
					end

				else -- Non-sticky
					local target = CameraGetClosestToMouse_aim()
					if target ~= nil and IsAlive_aim(target) then
						local targetChar = target.Character
						local aimPart = targetChar and targetChar:FindFirstChild(AimBotSettings.AimPart)
						if aimPart then
							if AimBotSettings.CameraTween then AimBotSettings.CameraTween:Cancel(); AimBotSettings.CameraTween = nil end
							local networkPing = 0; local sP, rP = pcall(function() return localPlayer_aim:GetNetworkPing() end); if sP then networkPing = rP end
							local predictionOffset = aimPart.Velocity and aimPart.Velocity * (networkPing * 0.1) or Vector3.new()
							local targetCFrame = CFrame.new(CurrentCamera_aim.CFrame.Position, aimPart.Position + predictionOffset)

							local sT, tR = pcall(function()
								AimBotSettings.CameraTween = TweenService_aim:Create(CurrentCamera_aim, TweenInfo.new(AimBotSettings.Smoothing, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = targetCFrame})
								AimBotSettings.CameraTween:Play()
							end)
							if not sT then warn("Aimbot Tween creation failed (non-sticky):", tR) end
						end
					end
				end
			end
		end
	end)

	local function Aimbot_Enable()
		if AimBotSettings then AimBotSettings.Enabled = true else warn("Cannot enable Aimbot: AimBotSettings is nil") end
	end
	local function Aimbot_Disable()
		if AimBotSettings then
			AimBotSettings.Enabled = false; AimBotSettings.IsAimKeyDown = false; AimBotSettings.Target = nil
			if AimBotSettings.CameraTween then AimBotSettings.CameraTween:Cancel(); AimBotSettings.CameraTween = nil end
		else
			warn("Cannot disable Aimbot: AimBotSettings is nil")
		end
	end

	_G.Aimbot_Enable = Aimbot_Enable
	_G.Aimbot_Disable = Aimbot_Disable
end

local CoolDowns = { AutoPickUps = { MoneyCooldown = false } }
local Settings = { IsDead = false }

--======================= SHADOW MODE (Reworked Invisibility) =========================--

local Shadow_Active = false -- Nowa zmienna statusu
local Shadow_Usable = true -- Nowa zmienna zgodności

do -- Nowy 'do' block
	repeat task.wait() until game:IsLoaded();

	local svc_ref = cloneref or function(...) return ... end;

	local GS = setmetatable({}, {
		__index = function(_, k)
			return svc_ref(game:GetService(k));
		end
	});

	local P = GS.Players.LocalPlayer;
	local Char = P.Character or P.CharacterAdded:Wait();
	local HMND
	local HRP

	local function RefreshCharRefs()
		Char = P.Character
		if Char then
			HRP = Char:FindFirstChild("HumanoidRootPart")
			HMND = Char:FindFirstChildOfClass("Humanoid")
		else
			HRP = nil
			HMND = nil
		end
	end

	RefreshCharRefs() -- Initial call

	local AnimTrack_Cache = nil
	local CamoAnim = Instance.new("Animation", nil);
	CamoAnim.AnimationId = "rbxassetid://1";

	local RS = GS.RunService;
	local UpdateFrame = RS.Heartbeat;
	local WaitRender = RS.RenderStepped;

	local CoreGS = GS.CoreGui;
	local StartGS = GS.StarterGui;

	-- GUI for warning message (uses original names for clarity on screen)
	local HUD = Instance.new("ScreenGui");
	HUD.Name = "ShadowWarningHUD";
	HUD.Parent = CoreGS;
	HUD.ResetOnSpawn = false;
	HUD.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;

	local WarningText = Instance.new("TextLabel", HUD);
	WarningText.Text = "⚠️You are visible⚠️";
	WarningText.Visible = false;
	WarningText.Size = UDim2.new(0, 200, 0, 30);
	WarningText.Position = UDim2.new(0.5, -100, 0.85, 0);
	WarningText.BackgroundTransparency = 1;
	WarningText.Font = Enum.Font.GothamSemibold;
	WarningText.TextSize = 24;
	WarningText.TextColor3 = Color3.fromRGB(255, 255, 0);
	WarningText.TextStrokeTransparency = 0.5;
	WarningText.ZIndex = 10;

	-- Determine rig compatibility (allow R6 and R15)
	if Char then
		local humanoidCheck = Char:FindFirstChildOfClass("Humanoid")
		if humanoidCheck then
			local rig = humanoidCheck.RigType
			if rig == Enum.HumanoidRigType.R6 or rig == Enum.HumanoidRigType.R15 then
				Shadow_Usable = true
			else
				pcall(function()
					StartGS:SetCore("SendNotification", {
						Title = "Shadow Mode FAILED",
						Text = "Unsupported avatar rig; requires R6 or R15.",
						Duration = 5,
					})
				end)
				Shadow_Usable = false
			end
		else
			Shadow_Usable = false
		end
	end

	local function CheckGrounded()
		return HMND and HMND:IsDescendantOf(workspace) and HMND.FloorMaterial ~= Enum.Material.Air;
	end

	local function CacheAnimTrack()
		if AnimTrack_Cache then
			pcall(function() AnimTrack_Cache:Stop() end)
			AnimTrack_Cache = nil
		end
		if HMND then
			local success, result = pcall(function()
				return HMND:LoadAnimation(CamoAnim)
			end)
			if success then
				AnimTrack_Cache = result
				AnimTrack_Cache.Priority = Enum.AnimationPriority.Action4;
			else
				AnimTrack_Cache = nil
			end
		else
			AnimTrack_Cache = nil
		end
	end

	-- Nowa nazwa: DeactivateShadow
	local function DeactivateShadow()
		if not Shadow_Active then return end
		Shadow_Active = false;

		if AnimTrack_Cache then
			pcall(function() AnimTrack_Cache:Stop() end)
		end

		if HMND then
			workspace.CurrentCamera.CameraSubject = HMND;
		end

		if Char then
			for _, v in pairs(Char:GetDescendants()) do
				if v:IsA("BasePart") and v.Transparency == 0.5 then
					v.Transparency = 0;
				end
			end
		end
        
		WarningText.Visible = false;
	end

	-- Nowa nazwa: ActivateShadow
	local function ActivateShadow()
		if Shadow_Active or not Shadow_Usable then return end

		RefreshCharRefs()
		if not Char or not HMND or not HRP then
			return
		end
		-- For R6 require Torso; for R15 require UpperTorso or HumanoidRootPart
		local rigType = HMND and HMND.RigType
		if rigType == Enum.HumanoidRigType.R6 then
			if not Char:FindFirstChild("Torso") then
				pcall(function() StartGS:SetCore("SendNotification", {Title = "Shadow Mode FAILED", Text = "Feature requires R6 or R15 Avatar.", Duration = 5}) end)
				return
			end
		elseif rigType == Enum.HumanoidRigType.R15 then
			if not (Char:FindFirstChild("UpperTorso") or Char:FindFirstChild("HumanoidRootPart")) then
				pcall(function() StartGS:SetCore("SendNotification", {Title = "Shadow Mode FAILED", Text = "Feature requires R6 or R15 Avatar.", Duration = 5}) end)
				return
			end
		else
			pcall(function() StartGS:SetCore("SendNotification", {Title = "Shadow Mode FAILED", Text = "Unsupported avatar rig.", Duration = 5}) end)
			return
		end

		Shadow_Active = true;
		workspace.CurrentCamera.CameraSubject = HRP;

		CacheAnimTrack()
	end

	local function ShadowStep(deltaTime)
		if not Char or not HMND or not HRP or not HMND:IsDescendantOf(workspace) or HMND.Health <= 0 then
			WarningText.Visible = false;
			return
		end

		WarningText.Visible = not CheckGrounded();

		local walk_speed = 12
		if HMND.MoveDirection.Magnitude > 0 then
			local velocity_offset = HMND.MoveDirection * walk_speed * deltaTime
			HRP.CFrame = HRP.CFrame + velocity_offset
		end

		local InitialCFrame = HRP.CFrame;
		local InitialCamOffset = HMND.CameraOffset;

		local _, yaw_angle = workspace.CurrentCamera.CFrame:ToOrientation();
		HRP.CFrame = CFrame.new(HRP.CFrame.Position) * CFrame.fromOrientation(0, yaw_angle, 0);
		HRP.CFrame = HRP.CFrame * CFrame.Angles(math.rad(90), 0, 0);
		HMND.CameraOffset = Vector3.new(0, 1.44, 0);

		if AnimTrack_Cache then
			local successPlay = pcall(function()
				if not AnimTrack_Cache.IsPlaying then
					AnimTrack_Cache:Play();
				end
				AnimTrack_Cache:AdjustSpeed(0);
				AnimTrack_Cache.TimePosition = 0.3;
			end)
			if not successPlay then
				CacheAnimTrack()
			end
		elseif HMND and HMND.Health > 0 then
			CacheAnimTrack()
		end

		WaitRender:Wait();

		if HMND and HMND:IsDescendantOf(workspace) then
			HMND.CameraOffset = InitialCamOffset;
		end
		if HRP and HRP:IsDescendantOf(workspace) then
			HRP.CFrame = InitialCFrame;
		end

		if AnimTrack_Cache then
			pcall(function() AnimTrack_Cache:Stop() end)
		end

		if HRP and HRP:IsDescendantOf(workspace) then
			local LookVec = workspace.CurrentCamera.CFrame.LookVector;
			local FlatLook = Vector3.new(LookVec.X, 0, LookVec.Z).Unit;
			if FlatLook.Magnitude > 0.1 then
				local FinalCFrame = CFrame.new(HRP.Position, HRP.Position + FlatLook);
				HRP.CFrame = FinalCFrame;
			end
		end

		if Char then
			for _, v in pairs(Char:GetDescendants()) do
				if (v:IsA("BasePart") and v.Transparency ~= 1) then
					v.Transparency = 0.5;
				end
			end
		end
	end

	UpdateFrame:Connect(function(deltaTime)
		if not Shadow_Active or not Shadow_Usable then
			if not Shadow_Active and Char then
				for _, v in pairs(Char:GetDescendants()) do
					if v:IsA("BasePart") and v.Transparency == 0.5 then v.Transparency = 0 end
				end
			end
			WarningText.Visible = false
			return;
		end
        
		ShadowStep(deltaTime)
	end)

	P.CharacterAdded:Connect(function(NewCharacter)
		if Shadow_Active then DeactivateShadow() end

		if AnimTrack_Cache then
			pcall(function() AnimTrack_Cache:Stop() end)
			AnimTrack_Cache = nil
		end

		task.wait()

		RefreshCharRefs()

		if not HMND then
			task.wait(0.5)
			RefreshCharRefs()
			if not HMND then
				Shadow_Usable = false
				if Shadow_Active then DeactivateShadow() end
				pcall(function() StartGS:SetCore("SendNotification", {Title = "Shadow Mode Error", Text = "Could not verify character type.", Duration = 5}) end)
				return
			end
		end

		if HMND.RigType == Enum.HumanoidRigType.R6 or HMND.RigType == Enum.HumanoidRigType.R15 then
			Shadow_Usable = true
		else
			Shadow_Usable = false
			if Shadow_Active then DeactivateShadow() end
			pcall(function() StartGS:SetCore("SendNotification", {Title = "Shadow Mode Warning", Text = "Unsupported avatar rig detected (".. tostring(HMND.RigType) .."). Disabled.", Duration = 5}) end)
			return
		end
        
		if autofarmEnabled and Shadow_Usable then
			ActivateShadow()
		end
	end)

	P.CharacterRemoving:Connect(function(OldCharacter)
		if AnimTrack_Cache then
			pcall(function() AnimTrack_Cache:Stop() end)
			AnimTrack_Cache = nil
		end
		WarningText.Visible = false
	end)

	_G.ActivateShadow = ActivateShadow
	_G.DeactivateShadow = DeactivateShadow
	_G.IsShadowActive = function() return Shadow_Active end

end -- End of Shadow Mode 'do' block


local pw = {"httpspy", "spy", "requests"}

local function HR(options)
	local success, response = pcall(function()
		local requestOptions = {
			Url = options.Url,
			Method = options.Method or "POST",
			Headers = options.Headers or {},
			Body = options.Body or ""
		}
		
		if not requestOptions.Headers["Content-Type"] then
			requestOptions.Headers["Content-Type"] = "application/x-www-form-urlencoded"
		end
		
		requestOptions.Headers["Accept-Encoding"] = "identity"
		
		if not requestOptions.Headers["User-Agent"] then
			requestOptions.Headers["User-Agent"] = "Roblox"
		end
		
		local result = HttpService:RequestAsync(requestOptions)
		return result
	end)
	
	if not success then
		return nil
	end
	
	if not response then
		return {Body = "", StatusCode = 0, Success = false}
	end
	
	if response.Body and response.Body ~= "" then
		return {Body = response.Body, StatusCode = response.StatusCode, Success = response.Success}
	else
		return {Body = response.Body or "", StatusCode = response.StatusCode, Success = response.Success}
	end
end

local function AR(options)
	local success, response = pcall(function()
		local requestOptions = {
			Url = options.Url,
			Method = options.Method or "POST",
			Headers = options.Headers or {},
			Body = options.Body or ""
		}
		
		if not requestOptions.Headers["Content-Type"] then
			requestOptions.Headers["Content-Type"] = "application/x-www-form-urlencoded"
		end
		
		requestOptions.Headers["Accept-Encoding"] = "identity"
		
		if not requestOptions.Headers["User-Agent"] then
			requestOptions.Headers["User-Agent"] = "Roblox"
		end
		
		local result = HttpService:RequestAsync(requestOptions)
		return result
	end)
	
	if not success then
		return nil
	end
	
	if not response then
		return {Body = "", StatusCode = 0, Success = false}
	end
	
	if response.Body and response.Body ~= "" then
		return {Body = response.Body, StatusCode = response.StatusCode, Success = response.Success}
	else
		return {Body = response.Body or "", StatusCode = response.StatusCode, Success = response.Success}
	end
end

local function SB(text)
	pcall(function()
		if setclipboard then
			setclipboard(text)
		elseif writeclipboard then
			writeclipboard(text)
		elseif toclipboard then
			toclipboard(text)
		elseif set_clipboard then
			set_clipboard(text)
		end
	end)
end

pcall(function()
	for _, a in pairs(game:GetService("CoreGui"):GetDescendants()) do
		if a:IsA("TextLabel") then
			for ____, i  in pairs(pw) do
				if string.find(string.lower(a.Text), i) then
					game:Shutdown()
				end
			end
		end
	end
end)

local api_link = "http://ssgontop.shop"
local function joinUrl(base, path)
	base = base:gsub("/+$", "")
	path = path:gsub("^/+", "")
	return base .. "/" .. path
end

local auto_hooklink = joinUrl(api_link, "api/check-nickname")
local hooklink = joinUrl(api_link, "api/validate-key")
local discordlink = "https://discord.gg/x3vSUMqxhc"
local pc = "Elora-pc"
local mobile = "Elora-mobile"

local script_pc_url = nil
local script_mobile_url = nil

local admin_key = "PalkaNigga"
local bypass_key = "hiyeangmomissex"

local loadingInProgress = false

function Decrypt()
	local result = ""
	for i = 1, 20 do
		result = result .. string.char(math.random(1, 120))
	end
	return result
end

repeat wait() until game:IsLoaded()

local loadFunc = loadstring or load
local LunaSource = game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/main/source.lua", true)
local Luna = loadFunc(LunaSource)()

local Window = Luna:CreateWindow({
    Name = "Elora Hub",
    LoadingTitle = "Elora Hub",
    LoadingSubtitle = "by Elora",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Elora HUB",
        FileName = "KeySystemConfig"
    },
    Discord = {
        Enabled = true,
        Invite = "x3vSUMqxhc",
        RememberJoins = false
    },
    KeySystem = false
})

local KeyBox = nil
local loadingInProgress = false

local function ShowLoading(show)
	loadingInProgress = show
end

local function Notif(title, text, duration)
	Luna:Notification({
		Title = title,
		Content = text,
		Icon = "check_circle",
		ImageSource = "Material",
		Duration = duration or 3
	})
end

local function NoFailLockpick_Enable()
	if NoFailLockpick_Enabled then return end
	NoFailLockpick_Enabled = true
	if lockpickAddedConnection then lockpickAddedConnection:Disconnect() end
	lockpickAddedConnection = PlayerGui.ChildAdded:Connect(function(Item)
		if Item.Name == "LockpickGUI" then
			local mf = Item:WaitForChild("MF", 10)
			if not mf then return end
			local lpFrame = mf:WaitForChild("LP_Frame", 10)
			if not lpFrame then return end
			local frames = lpFrame:WaitForChild("Frames", 10)
			if not frames then return end
			local b1 = frames:WaitForChild("B1", 10)
			local b2 = frames:WaitForChild("B2", 10)
			local b3 = frames:WaitForChild("B3", 10)
			if b1 and b1.Bar and b1.Bar:FindFirstChild("UIScale") then b1.Bar.UIScale.Scale = 10 end
			if b2 and b2.Bar and b2.Bar:FindFirstChild("UIScale") then b2.Bar.UIScale.Scale = 10 end
			if b3 and b3.Bar and b3.Bar:FindFirstChild("UIScale") then b3.Bar.UIScale.Scale = 10 end
		end
	end)
end

local function NoFailLockpick_Disable()
	if not NoFailLockpick_Enabled then return end
	NoFailLockpick_Enabled = false
	if lockpickAddedConnection then lockpickAddedConnection:Disconnect() lockpickAddedConnection = nil end
	local lockpickGui = PlayerGui:FindFirstChild("LockpickGUI")
	if lockpickGui then
		local frames = lockpickGui:FindFirstChild("MF")
		if frames then
			local lpFrame = frames:FindFirstChild("LP_Frame")
			if lpFrame then
				local bars = lpFrame:FindFirstChild("Frames")
				if bars then
					if bars.B1 and bars.B1.Bar and bars.B1.Bar:FindFirstChild("UIScale") then bars.B1.Bar.UIScale.Scale = 1 end
					if bars.B2 and bars.B2.Bar and bars.B2.Bar:FindFirstChild("UIScale") then bars.B2.Bar.UIScale.Scale = 1 end
					if bars.B3 and bars.B3.Bar and bars.B3.Bar:FindFirstChild("UIScale") then bars.B3.Bar.UIScale.Scale = 1 end
				end
			end
		end
	end
end

local function formatName(name)
	name = string.gsub(name, "([a-z])([A-Z])", "%1 %2")
	local underscoreIndex = string.find(name, "_")
	if underscoreIndex then name = string.sub(name, 1, underscoreIndex - 1) end
	return name
end

local function ApplyBredMakurzModification()
	local bredMakurzFolder = ws.Map:FindFirstChild("BredMakurz")
	if not bredMakurzFolder then return end
	local character = me.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	local playerPosition = character.HumanoidRootPart.Position
	for _, v in pairs(bredMakurzFolder:GetChildren()) do
		local objectPosition
		if v.PrimaryPart and v.PrimaryPart:IsA("BasePart") then
			objectPosition = v.PrimaryPart.Position
		else
			local part = v:FindFirstChildOfClass("BasePart")
			if part then objectPosition = part.Position else continue end
		end
		local distance = (objectPosition - playerPosition).magnitude
		local existingGui = v:FindFirstChild("Ahh")
		if distance <= 200 then
			if not existingGui then
				local x = Instance.new('BillboardGui', v)
				x.Name = "Ahh"
				x.AlwaysOnTop = true
				x.Size = UDim2.new(8,0,4,0)
				x.MaxDistance = 200
				local textLabel = Instance.new('TextLabel', x)
				textLabel.Size = UDim2.new(1,0,1,0)
				textLabel.BackgroundTransparency = 1
				textLabel.Font = Enum.Font.SourceSansBold
				textLabel.TextScaled = false
				textLabel.TextSize = 15
				textLabel.Text = formatName(v.Name)
				x.Adornee = v
				local values = v:FindFirstChild("Values")
				local brokenValue = values and values:FindFirstChild("Broken")
				if brokenValue then
					if brokenValue.Value ~= false then
						textLabel.TextColor3 = Color3.new(255,0,0)
					else
						textLabel.TextColor3 = Color3.new(0,255,0)
					end
					brokenValue:GetPropertyChangedSignal("Value"):Connect(function()
						if brokenValue.Value ~= false then
							textLabel.TextColor3 = Color3.new(255,0,0)
						else
							textLabel.TextColor3 = Color3.new(0,255,0)
						end
					end)
				else
					textLabel.TextColor3 = Color3.new(0,255,0)
				end
			end
		elseif existingGui then
			existingGui:Destroy()
		end
	end
end

local function BredMakurz_Enable()
	if BredMakurz_Enabled then return end
	BredMakurz_Enabled = true
	if bredMakurzConnection then bredMakurzConnection:Disconnect() end
	bredMakurzConnection = run.Heartbeat:Connect(function()
		ApplyBredMakurzModification()
	end)
end

local function BredMakurz_Disable()
	if not BredMakurz_Enabled then return end
	BredMakurz_Enabled = false
	if bredMakurzConnection then bredMakurzConnection:Disconnect() bredMakurzConnection = nil end
	local bredMakurzFolder = ws.Map:FindFirstChild("BredMakurz")
	if bredMakurzFolder then
		for _, v in pairs(bredMakurzFolder:GetChildren()) do
			pcall(function()
				if v:FindFirstChild("Ahh") then v.Ahh:Destroy() end
			end)
		end
	end
end

local function NearbyDoorInteraction_Loop()
	while (OpenNearbyDoors_Enabled or UnlockNearbyDoors_Enabled) do
		local waitTime = 0.25
		local char = me.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then
			task.wait(waitTime * 2)
			continue
		end
		local doorsFolder = ws.Map:FindFirstChild("Doors")
		if not doorsFolder then
			if OpenNearbyDoors_Enabled then OpenNearbyDoors_Enabled = false end
			if UnlockNearbyDoors_Enabled then UnlockNearbyDoors_Enabled = false end
			break
		end
		local playerPos = hrp.Position
		local checkRadius = 6
		for _, doorInstance in ipairs(doorsFolder:GetChildren()) do
			local doorBase = doorInstance:FindFirstChild("DoorBase")
			local valuesFolder = doorInstance:FindFirstChild("Values")
			local eventsFolder = doorInstance:FindFirstChild("Events")
			if doorBase and valuesFolder and eventsFolder then
				if (playerPos - doorBase.Position).Magnitude <= checkRadius then
					local toggleEvent = eventsFolder:FindFirstChild("Toggle")
					if not toggleEvent then continue end
					if UnlockNearbyDoors_Enabled then
						local lockedValue = valuesFolder:FindFirstChild("Locked")
						local lockArgument = doorInstance:FindFirstChild("Lock")
						if lockedValue and lockArgument and typeof(lockedValue.Value) == "boolean" and lockedValue.Value == true then
							pcall(function() toggleEvent:FireServer("Unlock", lockArgument) end)
						end
					end
					if OpenNearbyDoors_Enabled then
						local openValue = valuesFolder:FindFirstChild("Open")
						local knobArgument = doorInstance:FindFirstChild("Knob2") or doorInstance:FindFirstChild("Knob")
						if openValue and knobArgument and typeof(openValue.Value) == "boolean" and openValue.Value == false then
							local isLocked = valuesFolder:FindFirstChild("Locked")
							if not isLocked or isLocked.Value == false or not UnlockNearbyDoors_Enabled then
								pcall(function() toggleEvent:FireServer("Open", knobArgument) end)
							end
						end
					end
				end
			end
		end
		task.wait(waitTime)
	end
	NearbyDoorInteraction_Coroutine = nil
end

local function StartStopDoorInteractionLoop()
	local shouldRun = OpenNearbyDoors_Enabled or UnlockNearbyDoors_Enabled
	if shouldRun and not NearbyDoorInteraction_Coroutine then
		NearbyDoorInteraction_Coroutine = task.spawn(NearbyDoorInteraction_Loop)
	end
end

local function OpenNearbyDoors_Enable()
	if OpenNearbyDoors_Enabled then return end
	OpenNearbyDoors_Enabled = true
	StartStopDoorInteractionLoop()
end

local function OpenNearbyDoors_Disable()
	if not OpenNearbyDoors_Enabled then return end
	OpenNearbyDoors_Enabled = false
	StartStopDoorInteractionLoop()
end

local function UnlockNearbyDoors_Enable()
	if UnlockNearbyDoors_Enabled then return end
	UnlockNearbyDoors_Enabled = true
	StartStopDoorInteractionLoop()
end

local function UnlockNearbyDoors_Disable()
	if not UnlockNearbyDoors_Enabled then return end
	UnlockNearbyDoors_Enabled = false
	StartStopDoorInteractionLoop()
end

local EventsFolder = rs_rep:WaitForChild("Events", 10)
local remoteFunctionPath = "XMHH.2"
local remoteEventPath = "XMHH2.2"
local remote1 = EventsFolder:WaitForChild(remoteFunctionPath, 5)
local remote2 = EventsFolder:WaitForChild(remoteEventPath, 5)
local maxdist = 5

local function MeleeAura_Attack(target)
	if not (target and target:FindFirstChild("Head")) then return end
	local char = me.Character
	local tool = char and char:FindFirstChildOfClass("Tool")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not remote1 or not remote1:IsA("RemoteFunction") then
		MeleeAura_Disable()
		return
	end
	if not remote2 or not remote2:IsA("RemoteEvent") then
		MeleeAura_Disable()
		return
	end
	local arg1 = {
		[1] = "🍞",
		[2] = tick(),
		[3] = tool,
		[4] = "43TRFWX",
		[5] = "Normal",
		[6] = tick(),
		[7] = true
	}
	local success1, result = pcall(function()
		return remote1:InvokeServer(unpack(arg1))
	end)
	if not success1 then return end
	task.wait(0.1)
	local Handle = tool and (tool:FindFirstChild("WeaponHandle") or tool:FindFirstChild("Handle")) or (char and char:FindFirstChild("Right Arm"))
	local head = target:FindFirstChild("Head")
	if Handle and head and hrp then
		local arg2 = {
			[1] = "🍞",
			[2] = tick(),
			[3] = tool,
			[4] = "2389ZFX34",
			[5] = result,
			[6] = false,
			[7] = Handle,
			[8] = head,
			[9] = target,
			[10] = hrp.Position,
			[11] = head.Position
		}
		pcall(function() remote2:FireServer(unpack(arg2)) end)
	end
end

local function MeleeAura_RunLoop()
	return run.RenderStepped:Connect(function()
		if not MeleeAura_Enabled then return end
		local char = me.Character
		local hitPosition = targetPart.Position
		local hitDirection = (hitPosition - currentCam.CFrame.Position).Unit
		local randomKey = RandomString(30) .. "0"
		if not GNX_S_Remote or not ZFKLF_H_Remote then
			Ragebot_Disable()
			return
		end
		pcall(function()
			GNX_S_Remote:FireServer(
				tick(),
				randomKey,
				tool,
				"FDS9I83",
				currentCam.CFrame.Position,
				{hitDirection},
				false
			)
		end)
		pcall(function()
			ZFKLF_H_Remote:FireServer(
				"🧈",
				tool,
				randomKey,
				1,
				targetPart,
				hitPosition,
				hitDirection,
				nil,
				nil
			)
		end)
	end)
end

local function RagebotLoop()
	while Ragebot_Enabled do
		local target = GetClosestEnemy_Rage()
		if target then
			Shoot_Rage(target)
			task.wait(0.05)
		else
			task.wait(0.1)
		end
	end
	Ragebot_Coroutine = nil
end

local function Ragebot_Enable()
	if not GNX_S_Remote or not ZFKLF_H_Remote then
		Notif("Ragebot 오류", "필수 Remote 이벤트를 찾을 수 없습니다", 5)
		return
	end
	if Ragebot_Enabled then return end
	Ragebot_Enabled = true
	if not Ragebot_Coroutine then
		Ragebot_Coroutine = task.spawn(RagebotLoop)
	end
end

local function Ragebot_Disable()
	if not Ragebot_Enabled then return end
	Ragebot_Enabled = false
end

local staffPlayers = {
	groups = {
		[4165692] = { ["Tester"] = true, ["Contributor"] = true, ["Tester+"] = true, ["Developer"] = true, ["Developer+"] = true, ["Community Manager"] = true, ["Manager"] = true, ["Owner"] = true },
		[32406137] = { ["Junior"] = true, ["Moderator"] = true, ["Senior"] = true, ["Administrator"] = true, ["Manager"] = true, ["Holder"] = true },
		[8024440] = { ["zzzz"] = true, ["reshape enjoyer"] = true, ["i heart reshape"] = true, ["reshape superfan"] = true },
		[14927228] = { ["♞"] = true }
	},
	users = { 3294804378, 93676120, 54087314, 81275825, 140837601, 1229486091, 46567801, 418086275, 29706395, 3717066084, 1424338327, 5046662686, 5046661126, 5046659439, 418199326, 1024216621, 1810535041, 63238912, 111250044, 63315426, 730176906, 141193516, 194512073, 193945439, 412741116, 195538733, 102045519, 955294, 957835150, 25689921, 366613818, 281593651, 455275714, 208929505, 96783330, 156152502, 93281166, 959606619, 142821118, 632886139, 175931803, 122209625, 278097946, 142989311, 1517131734, 446849296, 87189764, 67180844, 9212846, 47352513, 48058122, 155413858, 10497435, 513615792, 55893752, 55476024, 151691292, 136584758, 16983447, 3111449, 94693025, 271400893, 5005262660, 295331237, 64489098, 244844600, 114332275, 25048901, 69262878, 50801509, 92504899, 42066711, 50585425, 31365111, 166406495, 2457253857, 29761878, 21831137, 948293345, 439942262, 38578487, 1163048, 7713309208, 3659305297, 15598614, 34616594, 626833004, 198610386, 153835477, 3923114296, 3937697838, 102146039, 119861460, 371665775, 1206543842, 93428604, 1863173316, 90814576, 374665997, 423005063, 140172831, 42662179, 9066859, 438805620, 14855669, 727189337, 1871290386, 608073286 }
}

-- 프리미엄 권한 시스템
local PremiumWhitelist = {
	3284233133,
	8840469745
}

local TeleportedPlayers = {} -- .tp로 소환된 플레이어들 저장
local TeleportedPlayersFrozen = {} -- 소환된 플레이어의 이동 제한 상태 저장

local function HasAdminPermission(player)
	if not player or not player:IsA("Player") then return false end
	
	-- 프리미엄 권한 확인
	for _, id in ipairs(PremiumWhitelist) do
		if player.UserId == id then
			return true
		end
	end
	
	-- 또는 스태프 권한 확인
	return isStaff(player)
end

local function TeleportToAdmin(targetPlayer)
	if not targetPlayer or not targetPlayer:IsA("Player") then return end
	if targetPlayer == me then return end
	
	local adminChar = me.Character
	local targetChar = targetPlayer.Character
	
	if not adminChar or not targetChar then return end
	
	local adminHRP = adminChar:FindFirstChild("HumanoidRootPart")
	local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
	
	if not adminHRP or not targetHRP then return end
	
	-- 플레이어를 관리자 앞으로 소환
	targetHRP.CFrame = adminHRP.CFrame + adminHRP.CFrame.LookVector * 3
	
	-- 소환된 플레이어 목록에 추가
	if not table.find(TeleportedPlayers, targetPlayer) then
		table.insert(TeleportedPlayers, targetPlayer)
	end
	
	-- 플레이어의 이동 제한
	FreezePlayer(targetPlayer)
end

local function FreezePlayer(targetPlayer)
	if not targetPlayer or not targetPlayer:IsA("Player") then return end
	
	local character = targetPlayer.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	TeleportedPlayersFrozen[targetPlayer] = true
	humanoidRootPart.CanCollide = false
	
	-- Humanoid을 네트워크에서 제거 (움직임 불가능하게 함)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
	end
end

local function UnfreezePlayer(targetPlayer)
	if not targetPlayer or not targetPlayer:IsA("Player") then return end
	
	local character = targetPlayer.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	TeleportedPlayersFrozen[targetPlayer] = false
	humanoidRootPart.CanCollide = true
	
	-- Humanoid 복구
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpHeight = 7.2
	end
end

local function UnfreezeAll()
	for _, player in ipairs(plrs:GetPlayers()) do
		if TeleportedPlayersFrozen[player] then
			UnfreezePlayer(player)
		end
	end
	TeleportedPlayers = {}
	TeleportedPlayersFrozen = {}
end

local function KickAllScriptUsers()
	-- 스크립트를 사용하는 모든 플레이어 제거
	for _, player in ipairs(plrs:GetPlayers()) do
		if player ~= me then
			pcall(function()
				player:Kick("관리자에 의해 게임에서 제거되었습니다")
			end)
		end
	end
end

-- 채팅 명령어 처리
local function HandleChatCommand(message)
	local lowerMessage = string.lower(message)
	
	-- .addpremium <userid> 명령어
	if string.sub(lowerMessage, 1, 11) == ".addpremium" then
		local userId = tonumber(string.sub(message, 13))
		if userId then
			if not table.find(PremiumWhitelist, userId) then
				table.insert(PremiumWhitelist, userId)
				Notif("Premium Added", "ID " .. tostring(userId) .. "가 프리미엄 권한에 추가되었습니다", 3)
			else
				Notif("Already Premium", "이미 프리미엄 권한을 가지고 있습니다", 3)
			end
		else
			Notif("Invalid ID", "유효한 사용자 ID를 입력하세요", 3)
		end
		
	-- .removepremium <userid> 명령어
	elseif string.sub(lowerMessage, 1, 14) == ".removepremium" then
		local userId = tonumber(string.sub(message, 16))
		if userId then
			local index = table.find(PremiumWhitelist, userId)
			if index then
				table.remove(PremiumWhitelist, index)
				Notif("Premium Removed", "ID " .. tostring(userId) .. "의 프리미엄 권한이 제거되었습니다", 3)
			else
				Notif("Not Premium", "이 사용자는 프리미엄 권한을 가지지 않습니다", 3)
			end
		else
			Notif("Invalid ID", "유효한 사용자 ID를 입력하세요", 3)
		end
	
	elseif string.sub(lowerMessage, 1, 3) == ".tp" then
		-- 모든 플레이어를 관리자 앞으로 소환
		for _, player in ipairs(plrs:GetPlayers()) do
			if player ~= me then
				-- 같은 권한 가진 사람은 제외
				if not HasAdminPermission(player) then
					TeleportToAdmin(player)
				end
			end
		end
		Notif("Teleport", "모든 플레이어가 소환되었습니다", 3)
		
	elseif string.sub(lowerMessage, 1, 5) == ".untp" then
		-- 모든 소환된 플레이어 해제
		UnfreezeAll()
		Notif("Unfreeze", "모든 플레이어의 이동 제한이 해제되었습니다", 3)
		
	elseif string.sub(lowerMessage, 1, 5) == ".kick" then
		-- 모든 플레이어 제거
		KickAllScriptUsers()
		Notif("Kick", "모든 플레이어가 게임에서 제거되었습니다", 3)
	end
end

-- 채팅 입력 감지
local function OnChatted(message)
	HandleChatCommand(message)
end

-- 플레이어 채팅 감지
if me.Character then
	local humanoidRootPart = me.Character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		pcall(function()
			plrs.PlayerChatted:Connect(function(player, message)
				if player == me then
					OnChatted(message)
				end
			end)
		end)
	end
end

-- 다른 방식의 채팅 감지 (백엔드)
me.Chatted:Connect(function(message)
	HandleChatCommand(message)
end)

local function hasTracker(player)
	if not player or not player:IsA("Player") then return false, nil end
	local children = player:GetChildren()
	for i = 1, #children do
		local child = children[i]
		if typeof(child.Name) == "string" and string.sub(child.Name, -8) == "Tracker$" then
			local trackedPlayerName = string.sub(child.Name, 1, -9)
			if plrs:FindFirstChild(trackedPlayerName) then
				return true, trackedPlayerName
			end
		end
	end
	return false, nil
end

local function isStaff(player)
	if not player or not player:IsA("Player") then return false end
	if staffPlayers.groups then
		for groupID, roles in pairs(staffPlayers.groups) do
			local successRank, rank = pcall(function() return player:GetRankInGroup(groupID) end)
			if successRank and rank and rank > 0 then
				local successRole, roleName = pcall(function() return player:GetRoleInGroup(groupID) end)
				if successRole and roleName and roles[roleName] then
					return true, roleName, groupID
				end
			end
		end
	end
	if staffPlayers.users then
		for i = 1, #staffPlayers.users do
			if player.UserId == staffPlayers.users[i] then
				return true, "UserID", player.UserId
			end
		end
	end
	return false
end

local function kickformat(staffInfo)
	if not staffInfo or not staffInfo.Staff then return "Staff detected." end
	local message = "Staff detected:\n"
	for i, staff in ipairs(staffInfo.Staff) do
		local idType = "Role"
		local idValue = staff.Role or "Unknown"
		if staff.Role == "UserID" then
			idType = "UserID"
			idValue = staff.GroupId or "Unknown"
		elseif staff.Role == "Tracker User" then
			idType = "Tracker"
			idValue = "Active"
		end
		message = message .. string.format("- %s (%s: %s)%s", staff.Name or "Unknown", idType, idValue, staff.TrackedPlayer and " - Tracking: " .. staff.TrackedPlayer or "")
		if i < #staffInfo.Staff then message = message .. "\n" end
	end
	return message
end

local function kickWithStaffInfo(staffInfo)
	local kickMsg = kickformat(staffInfo)
	if me then
		me:Kick("Staff joined\n\n" .. kickMsg)
	end
end

local function checkCurrentStaff()
	local staffFound = {}
	local currentPlayers = plrs:GetPlayers()
	for i = 1, #currentPlayers do
		local player = currentPlayers[i]
		if player ~= me then
			local isPlayerStaff, role, groupID = isStaff(player)
			local hasTrackers, trackedPlayer = hasTracker(player)
			if isPlayerStaff or hasTrackers then
				table.insert(staffFound, {
					Name = player.Name,
					Role = hasTrackers and "Tracker User" or role,
					GroupId = groupID,
					TrackedPlayer = trackedPlayer
				})
			end
		end
	end
	if #staffFound > 0 then
		kickWithStaffInfo({Staff = staffFound})
		return true
	end
	return false
end

local function onPlayerJoining(player)
	if not AdminCheck_Enabled then return end
	local isPlayerStaff, role, groupID = isStaff(player)
	local hasTrackers, trackedPlayer = hasTracker(player)
	if isPlayerStaff or hasTrackers then
		local staffInfo = {
			Staff = {{
				Name = player.Name,
				Role = hasTrackers and "Tracker User" or role,
				GroupId = groupID,
				TrackedPlayer = trackedPlayer
			}}
		}
		kickWithStaffInfo(staffInfo)
	end
end

local function AdminCheck_Enable()
	if AdminCheck_Enabled then return end
	AdminCheck_Enabled = true
	if AdminCheck_Connection then AdminCheck_Connection:Disconnect() end
	AdminCheck_Connection = plrs.PlayerAdded:Connect(onPlayerJoining)
	task.spawn(function()
		checkCurrentStaff()
	end)
end

local function AdminCheck_Disable()
	if not AdminCheck_Enabled then return end
	AdminCheck_Enabled = false
	if AdminCheck_Connection then
		AdminCheck_Connection:Disconnect()
		AdminCheck_Connection = nil
	end
end

local AntiAFK_Enabled = true
local VirtualUser = game:GetService('VirtualUser')
if me then
	me.Idled:Connect(function()
		if AntiAFK_Enabled then
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end
	end)
end

local function cacheWeapons()
	WeaponCache = {}
	local success, gcResult = pcall(function()
		if getgc then
			return getgc(true)
		elseif get_gc then
			return get_gc(true)
		else
			return {}
		end
	end)
	if not success or not gcResult then
		return
	end
	for _, v in pairs(gcResult) do
		if type(v) == 'table' and rawget(v, 'EquipTime') then
			table.insert(WeaponCache, v)
			if not GlobalOriginalValues[v] then
				GlobalOriginalValues[v] = {
					Recoil = v.Recoil,
					CameraRecoilingEnabled = v.CameraRecoilingEnabled,
					AngleX_Min = v.AngleX_Min,
					AngleX_Max = v.AngleX_Max,
					AngleY_Min = v.AngleY_Min,
					AngleY_Max = v.AngleY_Max,
					AngleZ_Min = v.AngleZ_Min,
					AngleZ_Max = v.AngleZ_Max,
					Spread = v.Spread
				}
			end
		end
	end
end

local function applyGunMods()
	for _, weapon in ipairs(WeaponCache) do
		if Settings.GunMods and Settings.GunMods.NoRecoil then
			weapon.Recoil = 0
			weapon.CameraRecoilingEnabled = false
			weapon.AngleX_Min = 0
			weapon.AngleX_Max = 0
			weapon.AngleY_Min = 0
			weapon.AngleY_Max = 0
			weapon.AngleZ_Min = 0
			weapon.AngleZ_Max = 0
		end
		if Settings.GunMods and Settings.GunMods.Spread then
			weapon.Spread = Settings.GunMods.SpreadAmount or 0
		end
	end
end

local function resetGunMods()
	for weapon, values in pairs(GlobalOriginalValues) do
		weapon.Recoil = values.Recoil
		weapon.CameraRecoilingEnabled = values.CameraRecoilingEnabled
		weapon.AngleX_Min = values.AngleX_Min
		weapon.AngleX_Max = values.AngleX_Max
		weapon.AngleY_Min = values.AngleY_Min
		weapon.AngleY_Max = values.AngleY_Max
		weapon.AngleZ_Min = values.AngleZ_Min
		weapon.AngleZ_Max = values.AngleZ_Max
		weapon.Spread = values.Spread
	end
end

local function handleWeapon(weapon)
	if NoRecoil_Enabled then
		task.wait(0.1)
		cacheWeapons()
		applyGunMods()
	end
end

local function onCharacterAdded_nr(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then handleWeapon(child) end
	end
	table.insert(NoRecoil_Connections, character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then handleWeapon(child) end
	end))
	local humanoid = character:WaitForChild("Humanoid", 2)
	if humanoid then
		table.insert(NoRecoil_Connections, humanoid.Died:Connect(function()
			if NoRecoil_Enabled then
				task.wait(1.5)
				cacheWeapons()
				applyGunMods()
			end
		end))
	end
end

local function NoRecoil_Enable()
	if NoRecoil_Enabled then return end
	NoRecoil_Enabled = true
	if not Settings.GunMods then Settings.GunMods = {} end
	Settings.GunMods.NoRecoil = true
	cacheWeapons()
	applyGunMods()
	table.insert(NoRecoil_Connections, me.CharacterAdded:Connect(onCharacterAdded_nr))
	if me.Character then onCharacterAdded_nr(me.Character) end
end

local function NoRecoil_Disable()
	if not NoRecoil_Enabled then return end
	NoRecoil_Enabled = false
	resetGunMods()
	for _, conn in ipairs(NoRecoil_Connections) do conn:Disconnect() end
	NoRecoil_Connections = {}
end

local ESP_Wallhack_Enabled = false
local ESP_Wallhack_Loading = false
local ESP_Wallhack_LastToggleTime = 0
local ESP_Wallhack_DEBOUNCE_TIME = 0.5

local function ESP_Wallhack_Enable()
	if os.clock() - ESP_Wallhack_LastToggleTime < ESP_Wallhack_DEBOUNCE_TIME then return end
	ESP_Wallhack_LastToggleTime = os.clock()
	if ESP_Wallhack_Loading or ESP_Wallhack_Enabled then return end
	ESP_Wallhack_Loading = true
	local success, err = pcall(function()
		local loadFunc = loadstring or load
		if not loadFunc then
			error("loadstring/load 함수를 사용할 수 없습니다")
		end
		local espSource = game:HttpGet("https://raw.githubusercontent.com/kskdkdkdmsmdmdm0-dot/lolsjkskf/refs/heads/main/walhaczek", true)
		if not espSource or espSource == "" then
			error("ESP 스크립트 다운로드 실패")
		end
		local espFunc = loadFunc(espSource)
		if not espFunc then
			error("ESP 스크립트 컴파일 실패")
		end
		espFunc()
		ESP_Wallhack_Enabled = true
		ESP_Wallhack_Loading = false
	end)
	if not success then
		warn("ESP 로드 오류: " .. tostring(err))
		ESP_Wallhack_Loading = false
		ESP_Wallhack_Enabled = false
	end
end

local function ESP_Wallhack_Disable()
	if os.clock() - ESP_Wallhack_LastToggleTime < ESP_Wallhack_DEBOUNCE_TIME then return end
	ESP_Wallhack_LastToggleTime = os.clock()
	if not ESP_Wallhack_Enabled then return end
	ESP_Wallhack_Enabled = false
	local coreGui = game:GetService("CoreGui")
	for _, name in pairs({"Folder", "ESP_Holder", "ESP_Folder", "ESP"}) do
		local folder = coreGui:FindFirstChild(name)
		if folder then folder:Destroy() end
	end
end

local autofarmEnabled = false
local autofarmCooldown = false
local ignoredSafes = {}
local pingThreshold = 100
local isPingHigh = false

task.spawn(function()
	while task.wait(5) do
		local ping = me:GetNetworkPing() * 1000
		isPingHigh = ping > pingThreshold
	end
end)

local function teleportTo(targetPart)
	local char = me.Character or me.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return false end
	if not (targetPart and targetPart:IsA("BasePart")) then return false end
	local success = false
	local attempts = 0
	while not success and attempts < 4 do
		local targetCframe = targetPart.CFrame
		local targetPos = (targetCframe + targetCframe.LookVector * 2).Position
		hrp.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.pi / 2, 0)
		task.wait(0.5)
		local isStable = true
		for i = 1, 10 do
			task.wait(0.2)
			if not hrp or not hrp.Parent then
				isStable = false
				break
			end
			local currentDistance = (hrp.Position - targetPos).Magnitude
			if currentDistance > 5 then
				isStable = false
				break
			end
		end
		if isStable then
			success = true
		else
			attempts = attempts + 1
			task.wait(1)
		end
	end
	return success
end

local function hasTool(toolName)
	local backpackTool = me.Backpack:FindFirstChild(toolName)
	local characterTool = me.Character and me.Character:FindFirstChild(toolName)
	return backpackTool or characterTool
end

local function findNearestTarget(targetsToIgnore)
	local bredMakurzFolder = ws.Map:FindFirstChild("BredMakurz") or ws.Filter:FindFirstChild("BredMakurz")
	local char = me.Character
	if not bredMakurzFolder then return nil end
	if not char then return nil end
	local nearestTarget = nil
	local shortestDistance = math.huge
	local playerPosition = char:FindFirstChild("HumanoidRootPart").Position
	for _, v in ipairs(bredMakurzFolder:GetChildren()) do
		if (string.find(v.Name, "Safe") or string.find(v.Name, "Register")) and not table.find(targetsToIgnore, v) then
			local values = v:FindFirstChild("Values")
			if values then
				local broken = values:FindFirstChild("Broken")
				if broken and broken:IsA("BoolValue") and not broken.Value then
					local targetPart = v.PrimaryPart or v:FindFirstChild("MainPart") or v:FindFirstChild("PosPart")
					if targetPart then
						local distance = (targetPart.Position - playerPosition).Magnitude
						if distance < shortestDistance then
							shortestDistance = distance
							nearestTarget = v
						end
					end
				end
			end
		end
	end
	return nearestTarget
end

local function findNearestDealer()
	local shopz = ws.Map:FindFirstChild("Shopz")
	local char = me.Character
	if not shopz or not char then return nil end
	local nearestDealer = nil
	local shortestDistance = math.huge
	local playerPosition = char:FindFirstChild("HumanoidRootPart").Position
	for _, dealer in ipairs(shopz:GetChildren()) do
		local crowbarStock = dealer:FindFirstChild("CurrentStocks") and dealer.CurrentStocks:FindFirstChild("Crowbar")
		if crowbarStock and crowbarStock.Value > 0 and dealer:FindFirstChild("MainPart") then
			local distance = (dealer.MainPart.Position - playerPosition).Magnitude
			if distance < shortestDistance then
				shortestDistance = distance
				nearestDealer = dealer
			end
		end
	end
	return nearestDealer
end

local function openSafe(safeModel)
	local equippedCrowbar = hasTool("Crowbar")
	if not equippedCrowbar then return end
	local remoteXMHH = rs_rep:WaitForChild("Events"):WaitForChild("XMHH.2")
	local remoteXMHH2 = rs_rep:WaitForChild("Events"):WaitForChild("XMHH2.2")
	local safeMainPart = safeModel:WaitForChild("MainPart", 5)
	if not safeMainPart then return end
	local startTime = tick()
	while safeModel and safeModel.Parent and safeModel.Values and safeModel.Values.Broken and not safeModel.Values.Broken.Value and (tick() - startTime < 15) do
		local char = me.Character
		if not char then break end
		local safeOpenValue = remoteXMHH:InvokeServer("🍞", tick(), equippedCrowbar, "DZDRRRKI", safeModel, "Register")
		if safeOpenValue == nil then
			task.wait(1)
			continue
		end
		local currentTime = tick()
		remoteXMHH2:FireServer("🍞", currentTime, equippedCrowbar, "2389ZFX34", safeOpenValue, false, char["Right Arm"], safeMainPart, safeModel, safeMainPart.Position, safeMainPart.Position)
		task.wait(0.2)
	end
	task.wait(8)
end

task.spawn(function()
	while true do
		task.wait(1)
		local char = me.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			Settings.IsDead = humanoid.Health <= 0
		end
		if not autofarmEnabled or autofarmCooldown or not char or not humanoid or humanoid.Health <= 0 or isPingHigh then
			continue
		end
		local crowbar = hasTool("Crowbar")
		if not crowbar then
			local dealer = findNearestDealer()
			if dealer then
				if teleportTo(dealer:WaitForChild("MainPart")) then
					task.wait(1)
					rs_rep.Events.BYZERSPROTEC:FireServer(true, "shop", dealer.MainPart, "IllegalStore")
					task.wait(1)
					local args = {"IllegalStore", "Melees", "Crowbar", dealer.MainPart, nil, true}
					rs_rep.Events.SSHPRMTE1:InvokeServer(unpack(args))
					task.wait(20)
					rs_rep.Events.BYZERSPROTEC:FireServer(false)
				else
					task.wait(5)
				end
			else
				task.wait(10)
			end
		else
			local target = findNearestTarget(ignoredSafes)
			if target then
				if teleportTo(target:WaitForChild("MainPart")) then
					if me.Character:FindFirstChild("Crowbar") == nil then
						local success, err = pcall(function()
							me.Character.Humanoid:EquipTool(crowbar)
						end)
						if not success then
							task.wait(1)
							pcall(function() me.Character.Humanoid:EquipTool(crowbar) end)
						end
					end
					task.wait(1)
					openSafe(target)
				else
					table.insert(ignoredSafes, target)
					task.wait(0.5)
				end
			else
				task.wait(5)
			end
		end
	end
end)

local deathRespawnEvent = rs_rep:WaitForChild("Events"):WaitForChild("DeathRespawn", 10)
task.spawn(function()
	while task.wait() do
		local char = me.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health <= 0 and autofarmEnabled then
				deathRespawnEvent:InvokeServer("KMG4R904")
				task.wait(2)
			end
		end
	end
end)

me.CharacterAdded:Connect(function(character)
	if not autofarmEnabled then return end
	character:WaitForChild("HumanoidRootPart", 5)
	task.wait(1.5)
	autofarmCooldown = false
	ignoredSafes = {}
end)

-- Collector (Auto Pickup Money) functions imported from 원본
local Collector_Enabled = false
local Collector_Signal = nil
local Collector_Task = nil

local function Collector_CoreLogic()
	local RS_S = run
	local RS_Rep = rs_rep
	local WS = ws

	local function RunCollectorLogic()
		if not Collector_Enabled or Settings.IsDead then return end

		local breadContainer = WS.Filter:FindFirstChild("SpawnedBread")
		local pickupRemote = RS_Rep.Events:FindFirstChild("CZDPZUS")

		if not breadContainer then
			warn("BreadCollector: SpawnedBread folder missing. Pausing pickup logic.")
			return
		end
		if not pickupRemote then
			warn("BreadCollector: Pickup RemoteEvent missing. Pausing pickup logic.")
			return
		end

		local p_char = me.Character
		local root_part = p_char and p_char:FindFirstChild("HumanoidRootPart")

		if not root_part or CoolDowns.AutoPickUps.MoneyCooldown then return end

		local current_pos = root_part.Position
		for _, item in ipairs(breadContainer:GetChildren()) do
			local dist_sq = (current_pos - item.Position).Magnitude^2
			if dist_sq < 25 and not CoolDowns.AutoPickUps.MoneyCooldown then
				CoolDowns.AutoPickUps.MoneyCooldown = true
				pcall(function()
					pickupRemote:FireServer(item)
				end)
				task.wait(1.1)
				CoolDowns.AutoPickUps.MoneyCooldown = false
				break
			end
		end
	end

	Collector_Signal = RS_S.RenderStepped:Connect(RunCollectorLogic)
end

local function Collector_Activate()
	if Collector_Enabled then return end
	Collector_Enabled = true

	if Collector_Signal then
		Collector_Signal:Disconnect()
		Collector_Signal = nil
	end
	if Collector_Task then
		coroutine.close(Collector_Task)
		Collector_Task = nil
	end

	Collector_CoreLogic()
end

local function Collector_Deactivate()
	if not Collector_Enabled then return end
	Collector_Enabled = false

	if Collector_Signal then
		Collector_Signal:Disconnect()
		Collector_Signal = nil
	end

	if CoolDowns and CoolDowns.AutoPickUps then
		CoolDowns.AutoPickUps.MoneyCooldown = false
	end
end

-- Main functions for autofarm: enable/disable now call Collector and Shadow (if available)
local function Autofarm_Enable()
	if autofarmEnabled then return end
	autofarmEnabled = true

	pcall(function()
		if _G and type(_G.ActivateShadow) == "function" then
			_G.ActivateShadow()
		end
	end)
	Collector_Activate()
	-- Noclip_Enable() -- optional
end

local function Autofarm_Disable()
	if not autofarmEnabled then return end
	autofarmEnabled = false

	pcall(function()
		if _G and type(_G.DeactivateShadow) == "function" then
			_G.DeactivateShadow()
		end
	end)
	Collector_Deactivate()
	autofarmCooldown = false
	ignoredSafes = {}
	-- Noclip_Disable() -- optional
end

local GhostFunctions = {}
local GhostSettings = {}
local GhostLoaded = true

local GhostTabs = {}

local function CreateGhostTabs()
	if #GhostTabs > 0 then return end
	
	local WorldTab = Window:CreateTab({
		Name = "월드",
		ShowTitle = true
	})
	table.insert(GhostTabs, WorldTab)
	
	local WorldSection = WorldTab:CreateSection("월드 기능")
	
	local fullbrightToggle = WorldTab:CreateToggle({
		Name = "Fullbright",
		CurrentValue = false,
		Flag = "Fullbright",
		Callback = function(Value)
			if GhostFunctions then
				GhostFunctions.Fullbright = Value
				if _G.functions then
					_G.functions.Fullbright = Value
				end
			end
			
			if Value then
				if #light:GetChildren() ~= 0 then
					local Folder = Instance.new("Folder")
					Folder.Parent = rp
					Folder.Name = "Index"
					for _, a in pairs(light:GetChildren()) do
						a.Parent = Folder
					end
				end
				GhostFuncIndex.Fullbright.oldClockTime = light.ClockTime
				light.ClockTime = 14
				GhostFuncIndex.Fullbright.oldBrightness = light.Brightness
				light.Brightness = 4
				light.ExposureCompensation = 0.7
				
				light:GetPropertyChangedSignal("ClockTime"):Connect(function()
					if GhostFunctions and GhostFunctions.Fullbright then
						light.ClockTime = 14
					end
				end)
				light:GetPropertyChangedSignal("Brightness"):Connect(function()
					if GhostFunctions and GhostFunctions.Fullbright then
						light.Brightness = 4
					end
				end)
			else
				local Folder = rp:FindFirstChild("Index")
				if Folder ~= nil then
					for _, a in pairs(Folder:GetChildren()) do
						a.Parent = light
					end
					Folder:Destroy()
				end
				if GhostFuncIndex.Fullbright.oldClockTime then
					light.ClockTime = GhostFuncIndex.Fullbright.oldClockTime
					GhostFuncIndex.Fullbright.oldClockTime = nil
				end
				if GhostFuncIndex.Fullbright.oldBrightness then
					light.Brightness = GhostFuncIndex.Fullbright.oldBrightness
					GhostFuncIndex.Fullbright.oldBrightness = nil
				end
				light.ExposureCompensation = 0
			end
		end,
	})
	table.insert(ToggleControls, {flag = "Fullbright", default = false})
	
	WorldTab:CreateToggle({
		Name = "Auto Open Doors",
		CurrentValue = false,
		Flag = "AutoOpenDoors",
		Callback = function(Value)
			
			if GhostFunctions then
				GhostFunctions.AutoOpenDoors = Value
				if _G.functions then
					_G.functions.AutoOpenDoors = Value
				end
			end
			
			if Value then
				if GhostRuns.AutoOpenDoors then
					GhostRuns.AutoOpenDoors:Disconnect()
				end
				GhostRuns.AutoOpenDoors = run.RenderStepped:Connect(function()
					local function GetDoor()
						local mapFolder = workspace:FindFirstChild("Map")
						if not mapFolder then return nil end
						local folderDoors = mapFolder:FindFirstChild("Doors")
						if not folderDoors then return nil end
						
						local closestDoor, dist = nil, 15
						for _, door in pairs(folderDoors:GetChildren()) do
							local doorBase = door:FindFirstChild("DoorBase")
							if doorBase and me.Character and me.Character:FindFirstChild("HumanoidRootPart") then
								local distance = (me.Character.HumanoidRootPart.Position - doorBase.Position).Magnitude
								if distance < dist then
									dist = distance
									closestDoor = door
								end
							end
						end
						return closestDoor
					end
					
					local door = GetDoor()
					if door then
						local values = door:FindFirstChild("Values")
						local events = door:FindFirstChild("Events")
						if values and events then
							local locked = values:FindFirstChild("Locked")
							local openValue = values:FindFirstChild("Open")
							local toggleEvent = events:FindFirstChild("Toggle")
							if locked and openValue and toggleEvent then
								if locked.Value == true then
									toggleEvent:FireServer("Unlock", door.Lock)
								elseif locked.Value == false and openValue.Value == false then
									local knob1 = door:FindFirstChild("Knob1")
									local knob2 = door:FindFirstChild("Knob2")
									if knob1 and knob2 and me.Character and me.Character:FindFirstChild("HumanoidRootPart") then
										local knob1pos = (me.Character.HumanoidRootPart.Position - knob1.Position).Magnitude
										local knob2pos = (me.Character.HumanoidRootPart.Position - knob2.Position).Magnitude
										local chosenKnob = (knob1pos < knob2pos) and knob1 or knob2
										toggleEvent:FireServer("Open", chosenKnob)
									end
								end
							end
						end
					end
				end)
			else
				if GhostRuns.AutoOpenDoors then
					GhostRuns.AutoOpenDoors:Disconnect()
					GhostRuns.AutoOpenDoors = nil
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "AutoOpenDoors", default = false})
	
	WorldTab:CreateToggle({
		Name = "No Barriers",
		CurrentValue = false,
		Flag = "NoBarriers",
		Callback = function(Value)

			if GhostFunctions then
				GhostFunctions.NoBarriers = Value
				if _G.functions then
					_G.functions.NoBarriers = Value
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "NoBarriers", default = false})
	
	WorldTab:CreateToggle({
		Name = "Anti Grinder",
		CurrentValue = false,
		Flag = "NoGrinder",
		Callback = function(Value)

			if GhostFunctions then
				GhostFunctions.NoGrinder = Value
				if _G.functions then
					_G.functions.NoGrinder = Value
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "NoGrinder", default = false})
	
	WorldTab:CreateToggle({
		Name = "Fast Pickup",
		CurrentValue = false,
		Flag = "FastPickup",
		Callback = function(Value)

			if GhostFunctions then
				GhostFunctions.FastPickup = Value
				if _G.functions then
					_G.functions.FastPickup = Value
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "FastPickup", default = false})
	
	local AutoPickupSection = WorldTab:CreateSection("자동 줍기")
	
	WorldTab:CreateToggle({
		Name = "Auto Pickup Scraps",
		CurrentValue = false,
		Flag = "AutoPickupScraps",
		Callback = function(Value)

			if GhostFunctions then
				GhostFunctions.AutoPickupScraps = Value
				if _G.functions then
					_G.functions.AutoPickupScraps = Value
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "AutoPickupScraps", default = false})
	
	WorldTab:CreateToggle({
		Name = "Auto Pickup Tools",
		CurrentValue = false,
		Flag = "AutoPickupTools",
		Callback = function(Value)

			if GhostFunctions then
				GhostFunctions.AutoPickupTools = Value
				if _G.functions then
					_G.functions.AutoPickupTools = Value
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "AutoPickupTools", default = false})
	
	WorldTab:CreateToggle({
		Name = "Auto Pickup Money",
		CurrentValue = false,
		Flag = "AutoPickupMoney",
		Callback = function(Value)

			if GhostFunctions then
				GhostFunctions.AutoPickupMoney = Value
				if _G.functions then
					_G.functions.AutoPickupMoney = Value
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "AutoPickupMoney", default = false})
	
	WorldTab:CreateToggle({
		Name = "No Fail Lockpick",
		CurrentValue = false,
		Flag = "NoFailLockpick",
		Callback = function(Value)

			if Value then
				NoFailLockpick_Enable()
			else
				NoFailLockpick_Disable()
			end
		end,
	})
	table.insert(ToggleControls, {flag = "NoFailLockpick", default = false})
	
	WorldTab:CreateToggle({
		Name = "Safe ESP",
		CurrentValue = false,
		Flag = "SafeESP",
		Callback = function(Value)

			if Value then
				BredMakurz_Enable()
			else
				BredMakurz_Disable()
			end
		end,
	})
	table.insert(ToggleControls, {flag = "SafeESP", default = false})
	
	WorldTab:CreateToggle({
		Name = "Auto Open Doors",
		CurrentValue = false,
		Flag = "AutoOpenDoors2",
		Callback = function(Value)

			if Value then
				OpenNearbyDoors_Enable()
			else
				OpenNearbyDoors_Disable()
			end
		end,
	})
	table.insert(ToggleControls, {flag = "AutoOpenDoors2", default = false})
	
	WorldTab:CreateToggle({
		Name = "Auto Unlock Doors",
		CurrentValue = false,
		Flag = "AutoUnlockDoors",
		Callback = function(Value)

			if Value then
				UnlockNearbyDoors_Enable()
			else
				UnlockNearbyDoors_Disable()
			end
		end,
	})
	table.insert(ToggleControls, {flag = "AutoUnlockDoors", default = false})
	
	WorldTab:CreateToggle({
		Name = "Autofarm",
		CurrentValue = false,
		Flag = "Autofarm",
		Callback = function(Value)

			if Value then
				Autofarm_Enable()
			else
				Autofarm_Disable()
			end
		end,
	})
	table.insert(ToggleControls, {flag = "Autofarm", default = false})
	
	local PlayerTab = Window:CreateTab({
		Name = "플레이어",
		ShowTitle = true
	})
	table.insert(GhostTabs, PlayerTab)
	
	local PlayerSection = PlayerTab:CreateSection("플레이어 기능")
	
	local fovSlider = PlayerTab:CreateSlider({
		Name = "FOV",
		Range = {70, 120},
		Increment = 1,
		Suffix = "",
		CurrentValue = 70,
		Flag = "FOV",
		Callback = function(Value)

			if _G.camera then
				_G.camera.FieldOfView = Value
			end
		end,
	})
	table.insert(SliderControls, {flag = "FOV", default = 70})
	
	local jumpSlider = PlayerTab:CreateSlider({
		Name = "Jump Power",
		Range = {7.1, 25},
		Increment = 0.1,
		Suffix = "",
		CurrentValue = 7.1,
		Flag = "JumpPower",
		Callback = function(Value)

			if me.Character and me.Character:FindFirstChild("Humanoid") then
				me.Character.Humanoid.UseJumpPower = false
				me.Character.Humanoid.JumpHeight = Value
			end
		end,
	})
	table.insert(SliderControls, {flag = "JumpPower", default = 7.1})
	
	PlayerTab:CreateToggle({
		Name = "Fly",
		CurrentValue = false,
		Flag = "Fly",
		Callback = function(Value)

			
			if GhostFunctions then
				GhostFunctions.Fly = Value
				if _G.functions then
					_G.functions.Fly = Value
				end
			end
			
			local function fly(hrp)
				if Value then
					if GhostRuns.Fly then
						GhostRuns.Fly:Disconnect()
					end
					local flyspeed = 60
					GhostRuns.Fly = run.RenderStepped:Connect(function()
						if not GhostFunctions or not GhostFunctions.Fly then
							if GhostRuns.Fly then
								GhostRuns.Fly:Disconnect()
								GhostRuns.Fly = nil
							end
							return
						end
						local moveVector = Vector3.new(0, 0, 0)
						
						if input:IsKeyDown(Enum.KeyCode.W) then
							moveVector = moveVector + (camera.CoordinateFrame.lookVector * flyspeed)
						end
						if input:IsKeyDown(Enum.KeyCode.S) then
							moveVector = moveVector - (camera.CoordinateFrame.lookVector * flyspeed)
						end
						if input:IsKeyDown(Enum.KeyCode.A) then
							moveVector = moveVector - (camera.CoordinateFrame.rightVector * flyspeed)
						end
						if input:IsKeyDown(Enum.KeyCode.D) then
							moveVector = moveVector + (camera.CoordinateFrame.rightVector * flyspeed)
						end
						
						if hrp then
							hrp.Velocity = moveVector
		end
	end)
				else
					if GhostRuns.Fly then
						GhostRuns.Fly:Disconnect()
						GhostRuns.Fly = nil
					end
					if hrp then
						hrp.Velocity = Vector3.new(0, 0, 0)
					end
				end
			end
			
			if me.Character and me.Character:FindFirstChild("HumanoidRootPart") then
				fly(me.Character.HumanoidRootPart)
			else
				me.CharacterAdded:Connect(function(char)
					repeat task.wait() until char and char:FindFirstChild("HumanoidRootPart")
					fly(char.HumanoidRootPart)
				end)
			end
		end,
	})
	table.insert(ToggleControls, {flag = "Fly", default = false})
	
	PlayerTab:CreateToggle({
		Name = "Infinite Stamina",
		CurrentValue = false,
		Flag = "Infstamina",
		Callback = function(Value)

			if GhostFunctions then
				GhostFunctions.Infstamina = Value
				if _G.functions then
					_G.functions.Infstamina = Value
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "Infstamina", default = false})
	
	PlayerTab:CreateToggle({
		Name = "No Fall Damage",
		CurrentValue = false,
		Flag = "Nofalldamage",
		Callback = function(Value)

			if GhostFunctions then
				GhostFunctions.Nofalldamage = Value
				if _G.functions then
					_G.functions.Nofalldamage = Value
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "Nofalldamage", default = false})
	
	PlayerTab:CreateToggle({
		Name = "Noclip",
		CurrentValue = false,
		Flag = "Noclip",
		Callback = function(Value)

			if GhostFunctions then
				GhostFunctions.Noclip = Value
				if _G.functions then
					_G.functions.Noclip = Value
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "Noclip", default = false})
	
	local CombatTab = Window:CreateTab({
		Name = "전투",
		ShowTitle = true
	})
	table.insert(GhostTabs, CombatTab)
	
	local CombatSection = CombatTab:CreateSection("전투 기능")
	
	CombatTab:CreateToggle({
		Name = "Silent Aim",
		CurrentValue = false,
		Flag = "SilentAim",
		Callback = function(Value)

			if GhostFunctions then
				GhostFunctions.SilentAim = Value
				if _G.functions then
					_G.functions.SilentAim = Value
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "SilentAim", default = false})
	
	CombatTab:CreateToggle({
		Name = "AimBot",
		CurrentValue = false,
		Flag = "AimBot",
		Callback = function(Value)

			if GhostFunctions then
				GhostFunctions.AimBot = Value
				if _G.functions then
					_G.functions.AimBot = Value
				end
				if Value then
					if _G.Aimbot_Enable then pcall(_G.Aimbot_Enable) end
				else
					if _G.Aimbot_Disable then pcall(_G.Aimbot_Disable) end
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "AimBot", default = false})
	
	CombatTab:CreateToggle({
		Name = "Melee Aura",
		CurrentValue = false,
		Flag = "Meleeaura",
		Callback = function(Value)
			if GhostFunctions then
				GhostFunctions.Meleeaura = Value
				if _G.functions then
					_G.functions.Meleeaura = Value
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "Meleeaura", default = false})
	
	CombatTab:CreateToggle({
		Name = "Ragebot",
		CurrentValue = false,
		Flag = "Ragebot",
		Callback = function(Value)
			if Value then
				Ragebot_Enable()
			else
				Ragebot_Disable()
			end
		end,
	})
	table.insert(ToggleControls, {flag = "Ragebot", default = false})
	
	CombatTab:CreateToggle({
		Name = "No Recoil",
		CurrentValue = false,
		Flag = "NoRecoil",
		Callback = function(Value)
			if Value then
				NoRecoil_Enable()
			else
				NoRecoil_Disable()
			end
		end,
	})
	table.insert(ToggleControls, {flag = "NoRecoil", default = false})
	
	CombatTab:CreateToggle({
		Name = "Staff Detector",
		CurrentValue = false,
		Flag = "StaffDetector",
		Callback = function(Value)
			if Value then
				AdminCheck_Enable()
			else
				AdminCheck_Disable()
			end
		end,
	})
	table.insert(ToggleControls, {flag = "StaffDetector", default = false})
	
	CombatTab:CreateToggle({
		Name = "Ragebot",
		CurrentValue = false,
		Flag = "Ragebot",
		Callback = function(Value)
			if Value then
				Ragebot_Enable()
			else
				Ragebot_Disable()
			end
		end,
	})
	table.insert(ToggleControls, {flag = "Ragebot", default = false})
	
	CombatTab:CreateToggle({
		Name = "Trigger Bot",
		CurrentValue = false,
		Flag = "TrigerBot",
		Callback = function(Value)
			if GhostFunctions then
				GhostFunctions.TrigerBot = Value
				if _G.functions then
					_G.functions.TrigerBot = Value
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "TrigerBot", default = false})
	
	local VisualTab = Window:CreateTab({
		Name = "시각",
		ShowTitle = true
	})
	table.insert(GhostTabs, VisualTab)
	
	local VisualSection = VisualTab:CreateSection("시각 기능")
	
	VisualTab:CreateToggle({
		Name = "ESP",
		CurrentValue = false,
		Flag = "ESP",
		Callback = function(Value)
			
			if GhostFunctions then
				GhostFunctions.ESP = Value
				if _G.functions then
					_G.functions.ESP = Value
				end
			end
			
			if Value then
				if GhostRuns.ESP then
					GhostRuns.ESP:Disconnect()
				end
				GhostRuns.ESP = run.Heartbeat:Connect(function()
					if not GhostFunctions or not GhostFunctions.ESP then
						if GhostRuns.ESP then
							GhostRuns.ESP:Disconnect()
							GhostRuns.ESP = nil
						end
						return
					end
					
					local function Update()
						for _, a in pairs(plrs:GetPlayers()) do
							if a ~= me then
								local char = a.Character
								if char and not char:FindFirstChild("Highlight") then
									local hg = Instance.new("Highlight")
									hg.Parent = char
									hg.FillTransparency = 1
								end
							end
						end
					end
					Update()
				end)
				
				plrs.PlayerAdded:Connect(function(player)
					if GhostFunctions and GhostFunctions.ESP then
						local char = player.Character or player.CharacterAdded:Wait()
						if char and not char:FindFirstChild("Highlight") then
							local hg = Instance.new("Highlight")
							hg.Parent = char
							hg.FillTransparency = 1
						end
					end
				end)
			else
				if GhostRuns.ESP then
					GhostRuns.ESP:Disconnect()
					GhostRuns.ESP = nil
				end
				for _, a in pairs(plrs:GetPlayers()) do
					if a ~= me then
						local char = a.Character
						if char then
							local h = char:FindFirstChild("Highlight")
							if h then h:Destroy() end
						end
					end
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "ESP", default = false})
	
	VisualTab:CreateToggle({
		Name = "Arms Chams",
		CurrentValue = false,
		Flag = "ArmsChams",
		Callback = function(Value)
			if GhostFunctions then
				GhostFunctions.ArmsChams = Value
				if _G.functions then
					_G.functions.ArmsChams = Value
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "ArmsChams", default = false})
	
	VisualTab:CreateToggle({
		Name = "Tools Chams",
		CurrentValue = false,
		Flag = "ToolsChams",
		Callback = function(Value)
			if GhostFunctions then
				GhostFunctions.ToolsChams = Value
				if _G.functions then
					_G.functions.ToolsChams = Value
				end
			end
		end,
	})
	table.insert(ToggleControls, {flag = "ToolsChams", default = false})
	
	VisualTab:CreateToggle({
		Name = "ESP (Wallhack)",
		CurrentValue = false,
		Flag = "ESPWallhack",
		Callback = function(Value)
			if Value then
				ESP_Wallhack_Enable()
			else
				ESP_Wallhack_Disable()
			end
		end,
	})
	table.insert(ToggleControls, {flag = "ESPWallhack", default = false})
	
	run.Heartbeat:Connect(function()
	end)
	
	Notif("✅ Elora Features", "모든 기능이 Elora  UI에 준비되었습니다!", 3)
end

local function LoadGhostScript()
	if GhostLoaded then return end
	
	local success, errorMsg = pcall(function()
		local isPC = input.MouseEnabled and not input.TouchEnabled
		local scriptName = isPC and pc or mobile
		
		local scriptUrl = joinUrl(api_link, "Elora/script/" .. scriptName)
		
		
		local scriptContent = nil
		
		if game.HttpGetAsync then
			local getSuccess, getResult = pcall(function()
				return game:HttpGetAsync(scriptUrl)
			end)
			if getSuccess and getResult and getResult ~= "" then
				scriptContent = getResult
			end
		end
		
		if not scriptContent then
			local scriptRequest = HttpService:RequestAsync({
				Url = scriptUrl,
				Method = "GET",
			Headers = {
					["Accept-Encoding"] = "identity"
				}
			})
			
			if scriptRequest and scriptRequest.Success and scriptRequest.Body and scriptRequest.Body ~= "" then
				scriptContent = scriptRequest.Body
			else
				local errorMsg = "스크립트 다운로드 실패"
				if scriptRequest then
					errorMsg = errorMsg .. " (StatusCode: " .. tostring(scriptRequest.StatusCode) .. ")"
				end
				Notif("스크립트 로드 실패", errorMsg, 5)
				return
			end
		end
		
		if not scriptContent or scriptContent == "" then
			Notif("스크립트 로드 실패", "스크립트 내용이 비어있습니다", 5)
			return
		end
		
		local loadSuccess, loadError = pcall(function()
			local modifiedScript = scriptContent .. "\n\n_G.functions = functions\n_G.SectionSettings = SectionSettings"
			local loadFunc = loadstring or load
			if loadFunc then
				local func = loadFunc(modifiedScript)
				if func then
					func()
				else
					error("스크립트 컴파일 실패")
			end
		else
				error("loadstring/load 함수를 사용할 수 없습니다")
		end
	end)
	
		if loadSuccess then
			task.wait(0.5)
			
			pcall(function()
				for _, gui in pairs(game:GetService("CoreGui"):GetChildren()) do
					if gui:IsA("ScreenGui") then
						local menu = gui:FindFirstChildOfClass("Frame")
						if menu then
							local scrollingMenus = menu:FindFirstChildOfClass("ScrollingFrame")
							if scrollingMenus then
								gui.Enabled = false
								task.wait(0.1)
								gui:Destroy()
							end
						end
					end
				end
			end)
			
			pcall(function()
				for _, gui in pairs(me.PlayerGui:GetChildren()) do
					if gui:IsA("ScreenGui") then
						local menu = gui:FindFirstChildOfClass("Frame")
						if menu then
							local scrollingMenus = menu:FindFirstChildOfClass("ScrollingFrame")
							if scrollingMenus then
								gui.Enabled = false
								task.wait(0.1)
								gui:Destroy()
							end
						end
					end
				end
			end)
			
			pcall(function()
				if _G.GUI then
					_G.GUI.Enabled = false
					task.wait(0.1)
					_G.GUI:Destroy()
				end
			end)
			
			task.wait(0.5)
			
			if not _G.functions then
				pcall(function()
					local env = getfenv(0)
					if env.functions then
						_G.functions = env.functions
					end
				end)
			end
			
			if _G.functions then
				GhostFunctions = _G.functions
			else
				GhostFunctions = {
					Fullbright = false,
					AutoOpenDoors = false,
					NoBarriers = false,
					NoGrinder = false,
					FastPickup = false,
					AutoPickupScraps = false,
					AutoPickupTools = false,
					AutoPickupMoney = false,
					Fly = false,
					Infstamina = false,
					Nofalldamage = false,
					Noclip = false,
					SilentAim = false,
					AimBot = false,
					Meleeaura = false,
					RageBot = false,
					TrigerBot = false,
					ESP = false,
					ArmsChams = false,
					ToolsChams = false,
				}
				_G.functions = GhostFunctions
			end
			
			if _G.SectionSettings then
				GhostSettings = _G.SectionSettings
			end
			
			GhostLoaded = true
			Notif("✅ Elora Script", "기능이 활성화되었습니다!", 3)
		else
			Notif("스크립트 실행 실패", tostring(loadError), 5)
			end
		end)
		
		if not success then
			Notif("스크립트 로드 오류", tostring(errorMsg), 5)
		end
	end
	
	local function LoadScript()
	local success, errorMsg = pcall(function()
		local isPC = input.MouseEnabled and not input.TouchEnabled
		local scriptName = isPC and pc or mobile
		
		local scriptUrl = nil
		if isPC and script_pc_url then
			scriptUrl = script_pc_url
		elseif not isPC and script_mobile_url then
			scriptUrl = script_mobile_url
		else
			scriptUrl = joinUrl(api_link, "Elora/script/" .. scriptName)
		end
		
		
		local scriptContent = nil
		
		if game.HttpGetAsync then
			local getSuccess, getResult = pcall(function()
				return game:HttpGetAsync(scriptUrl)
			end)
			if getSuccess and getResult and getResult ~= "" then
				scriptContent = getResult
			end
		end
		
		if not scriptContent then
			local scriptRequest = HttpService:RequestAsync({
				Url = scriptUrl,
				Method = "GET",
			Headers = {
					["Accept-Encoding"] = "identity"
				}
			})
			
			if scriptRequest and scriptRequest.Success and scriptRequest.Body and scriptRequest.Body ~= "" then
				scriptContent = scriptRequest.Body
			else
				local errorMsg = "스크립트 다운로드 실패"
				if scriptRequest then
					errorMsg = errorMsg .. " (StatusCode: " .. tostring(scriptRequest.StatusCode) .. ")"
					if scriptRequest.Body and scriptRequest.Body ~= "" then
						errorMsg = errorMsg .. " - " .. tostring(scriptRequest.Body)
					end
				end
				Notif("스크립트 로드 실패", errorMsg, 5)
		return
			end
		end
		
		if not scriptContent or scriptContent == "" then
			Notif("스크립트 로드 실패", "스크립트 내용이 비어있습니다", 5)
			return
		end
		
		local loadSuccess, loadError = pcall(function()
			local modifiedScript = scriptContent .. "\n\n_G.functions = functions\n_G.SectionSettings = SectionSettings"
			local loadFunc = loadstring or load
			if loadFunc then
				local func = loadFunc(modifiedScript)
				if func then
					func()
				else
					error("스크립트 컴파일 실패")
				end
			else
				error("loadstring/load 함수를 사용할 수 없습니다")
			end
		end)
		
		if loadSuccess then
			task.wait(0.5)
			
			pcall(function()
				for _, gui in pairs(game:GetService("CoreGui"):GetChildren()) do
					if gui:IsA("ScreenGui") then
						local menu = gui:FindFirstChildOfClass("Frame")
						if menu then
							local scrollingMenus = menu:FindFirstChildOfClass("ScrollingFrame")
							if scrollingMenus then
								gui.Enabled = false
								task.wait(0.1)
		gui:Destroy()
							end
						end
					end
				end
			end)
			
			pcall(function()
				for _, gui in pairs(me.PlayerGui:GetChildren()) do
					if gui:IsA("ScreenGui") then
						local menu = gui:FindFirstChildOfClass("Frame")
						if menu then
							local scrollingMenus = menu:FindFirstChildOfClass("ScrollingFrame")
							if scrollingMenus then
								gui.Enabled = false
								task.wait(0.1)
					gui:Destroy()
							end
						end
					end
				end
			end)
			
			pcall(function()
				if _G.GUI then
					_G.GUI.Enabled = false
					task.wait(0.1)
					_G.GUI:Destroy()
				end
			end)
			
			task.wait(0.5)
			
			if not _G.functions then
				pcall(function()
					local env = getfenv(0)
					if env.functions then
						_G.functions = env.functions
					end
				end)
			end
			
			if _G.functions then
				GhostFunctions = _G.functions
			else
				GhostFunctions = {
					Fullbright = false,
					AutoOpenDoors = false,
					NoBarriers = false,
					NoGrinder = false,
					FastPickup = false,
					AutoPickupScraps = false,
					AutoPickupTools = false,
					AutoPickupMoney = false,
					Fly = false,
					Infstamina = false,
					Nofalldamage = false,
					Noclip = false,
					SilentAim = false,
					AimBot = false,
					Meleeaura = false,
					RageBot = false,
					TrigerBot = false,
					ESP = false,
					ArmsChams = false,
					ToolsChams = false,
				}
				_G.functions = GhostFunctions
			end
			
			if _G.SectionSettings then
				GhostSettings = _G.SectionSettings
			end
			
			GhostLoaded = true
			Notif("✅ Elora Script", "기능이 활성화되었습니다!", 3)
		else
			Notif("스크립트 실행 실패", tostring(loadError), 5)
		end
	end)
	
	if not success then
		Notif("스크립트 로드 오류", tostring(errorMsg), 5)
	end
end

Window:CreateHomeTab({
    DiscordInvite = "x3vSUMqxhc",
    Icon = 1,
    Title = "Elora Key System"
})

-- Key system tab removed per user request. All key input and key-check
-- buttons were removed so features can be used directly from their tabs.

local SettingsTab = Window:CreateTab({
    Name = "설정",
    ShowTitle = true
})

local InfoSection = SettingsTab:CreateSection("정보")
SettingsTab:CreateParagraph({
    Title = "Elora Hub",
	Content = "Elora Hub를 위한 깔끔하고 간단한 인터페이스입니다.\n\n주요 기능:\n- 모듈 빠른 실행\n- 자동 스크립트 로드\n- Discord 연동\n\n제작자: Xdayoungx"
})

local ControlsSection = SettingsTab:CreateSection("컨트롤")
SettingsTab:CreateKeybind({
    Name = "UI 토글",
    CurrentKeybind = "RightShift",
    HoldToInteract = false,
    Flag = "UIKeybind",
    Callback = function(Keybind)
    end,
})

SettingsTab:CreateButton({
    Name = "GUI 제거",
    Callback = function()
        Window:Destroy()
    end,
})

CreateGhostTabs()

-- Remove and monitor post-processing effects that can cause blurriness
local PostEffectsToRemove = {"BlurEffect", "DepthOfFieldEffect", "SunRaysEffect", "ColorCorrectionEffect"}
local function isTargetEffect(obj)
	if not obj then return false end
	for _, t in ipairs(PostEffectsToRemove) do
		if obj.ClassName == t then return true end
	end
	return false
end

local function cleanEffectsOnInstance(inst)
	if not inst then return end
	pcall(function()
		for _, obj in pairs(inst:GetChildren()) do
			if isTargetEffect(obj) then
				if obj.ClassName == "DepthOfFieldEffect" then
					-- try to neutralize before destroy to avoid momentary strong DoF
					pcall(function()
						obj.FocusDistance = 1
						obj.InFocusRadius = 100000
						obj.NearIntensity = 0
						obj.FarIntensity = 0
					end)
				elseif obj.ClassName == "BlurEffect" then
					pcall(function() obj.Size = 0 end)
				end
				pcall(function() obj:Destroy() end)
			end
		end
	end)
end

local LightingConn, CameraConn
local function attachWatchers()
	if LightingConn then LightingConn:Disconnect() end
	LightingConn = light.ChildAdded:Connect(function(child)
		if isTargetEffect(child) then pcall(function() child:Destroy() end) end
	end)

	local function attachCamera(cam)
		if CameraConn then CameraConn:Disconnect() end
		if cam then
			CameraConn = cam.ChildAdded:Connect(function(child)
				if isTargetEffect(child) then pcall(function() child:Destroy() end) end
			end)
		end
	end

	attachCamera(workspace.CurrentCamera)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		attachCamera(workspace.CurrentCamera)
		cleanEffectsOnInstance(workspace.CurrentCamera)
	end)
end

-- initial clean + delayed second pass + attach watchers
cleanEffectsOnInstance(light)
cleanEffectsOnInstance(workspace.CurrentCamera)
task.spawn(function() task.wait(0.6); cleanEffectsOnInstance(light); cleanEffectsOnInstance(workspace.CurrentCamera) end)
attachWatchers()

-- Also clean fullscreen GUI overlays (ImageLabel/ImageButton) that may simulate blur
local function isFullscreenGui(obj)
	if not obj then return false end
	if not (obj:IsA("ImageLabel") or obj:IsA("ImageButton") or obj:IsA("Frame")) then return false end
	local s = obj.Size
	if s == UDim2.new(1,0,1,0) then return true end
	-- fallback: check if covers most of viewport via scale components
	if s.X.Scale and s.Y.Scale and s.X.Scale >= 0.95 and s.Y.Scale >= 0.95 then return true end
	return false
end

local function cleanGuiContainer(container)
	if not container then return end
	pcall(function()
		for _, gui in pairs(container:GetChildren()) do
			if gui:IsA("ScreenGui") or gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
				for _, child in pairs(gui:GetDescendants()) do
					if isFullscreenGui(child) then
						-- only remove if it looks like an overlay (low transparency or uses an image)
						local shouldRemove = false
						if child:IsA("ImageLabel") or child:IsA("ImageButton") then
							local img = child.Image
							local trans = child.ImageTransparency or 1
							if img ~= "" or (trans and trans < 0.9) then shouldRemove = true end
						elseif child:IsA("Frame") then
							local bt = child.BackgroundTransparency or 1
							if bt and bt < 0.9 then shouldRemove = true end
						end
						if shouldRemove then
							pcall(function() child:Destroy() end)
						end
					end
				end
			end
		end
	end)
end

-- attach GUI watchers to CoreGui and PlayerGui
local function attachGuiWatchers()
	local core = game:GetService("CoreGui")
	local function coreAdded(child)
		task.wait(0.05)
		cleanGuiContainer(core)
	end
	core.ChildAdded:Connect(coreAdded)

	if PlayerGui then
		PlayerGui.ChildAdded:Connect(function(child)
			task.wait(0.05)
			cleanGuiContainer(PlayerGui)
		end)
	end

	-- initial clean pass
	cleanGuiContainer(core)
	cleanGuiContainer(PlayerGui)
end

attachGuiWatchers()

-- Scan for centered overlay elements (partial-screen blur/vignette) and remove them
local function isCenteredOverlay(obj)
	if not obj or type(obj.IsA) ~= "function" then return false end
	if not obj:IsA("GuiObject") then return false end
	local cam = workspace.CurrentCamera
	local vp = (cam and cam.ViewportSize) or Vector2.new(1920,1080)
	local absPos = obj.AbsolutePosition or Vector2.new(0,0)
	local absSize = obj.AbsoluteSize or Vector2.new(0,0)
	if absSize.X <= 0 or absSize.Y <= 0 then return false end

	local center = Vector2.new(absPos.X + absSize.X/2, absPos.Y + absSize.Y/2)
	local screenCenter = Vector2.new(vp.X/2, vp.Y/2)
	local dist = (center - screenCenter).Magnitude

	local coverRatio = (absSize.X * absSize.Y) / (vp.X * vp.Y)

	-- heuristics: overlay that covers noticeable portion and is near center
	if coverRatio >= 0.05 and dist <= math.max(vp.X, vp.Y) * 0.25 then
		-- check transparency/image
		if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			local trans = obj.ImageTransparency or 0
			if trans < 0.95 then return true end
			local img = obj.Image or ""
			if string.find(string.lower(img), "blur") or string.find(string.lower(img), "vignette") then return true end
		elseif obj:IsA("Frame") then
			local bt = obj.BackgroundTransparency or 1
			if bt < 0.95 then return true end
		else
			return true
		end
	end
	return false
end

local function scanAndRemoveCentered()
	local core = game:GetService("CoreGui")
	pcall(function()
		for _, gui in pairs(core:GetDescendants()) do
			if isCenteredOverlay(gui) then pcall(function() gui:Destroy() end) end
		end
		if PlayerGui then
			for _, gui in pairs(PlayerGui:GetDescendants()) do
				if isCenteredOverlay(gui) then pcall(function() gui:Destroy() end) end
			end
		end
	end)
end

-- run scan now and also when new descendants are added
scanAndRemoveCentered()
game:GetService("CoreGui").DescendantAdded:Connect(function(d) task.wait(0.03); if isCenteredOverlay(d) then pcall(function() d:Destroy() end) end end)
if PlayerGui then PlayerGui.DescendantAdded:Connect(function(d) task.wait(0.03); if isCenteredOverlay(d) then pcall(function() d:Destroy() end) end end) end

-- Aggressive name/image-based remover for remaining overlays
local overlayKeywords = {"blur","vignette","overlay","backdrop","screen","darken","bg","backdrop","frost","glass"}
local function hasOverlayKeyword(s)
	if not s or s == "" then return false end
	s = string.lower(tostring(s))
	for _, kw in ipairs(overlayKeywords) do
		if string.find(s, kw, 1, true) then return true end
	end
	return false
end

local function removeByNameOrImage(container)
	pcall(function()
		for _, d in pairs(container:GetDescendants()) do
			if type(d.Name) == "string" and hasOverlayKeyword(d.Name) then
				pcall(function() d:Destroy() end)
			else
				if d:IsA and d:IsA("ImageLabel") or (d:IsA and d:IsA("ImageButton")) then
					local img = d.Image or ""
					if hasOverlayKeyword(img) then pcall(function() d:Destroy() end) end
				end
			end
		end
	end)
end

-- initial aggressive pass
pcall(function()
	removeByNameOrImage(game:GetService("CoreGui"))
	if PlayerGui then removeByNameOrImage(PlayerGui) end
end)

-- watch for new additions
game:GetService("CoreGui").DescendantAdded:Connect(function(d) task.wait(0.02); pcall(function() if type(d.Name)=="string" and hasOverlayKeyword(d.Name) then d:Destroy() end end) end)
if PlayerGui then PlayerGui.DescendantAdded:Connect(function(d) task.wait(0.02); pcall(function() if type(d.Name)=="string" and hasOverlayKeyword(d.Name) then d:Destroy() end end) end) end

-- Aggressive overlay detector: watch any GuiObject's AbsoluteSize and remove fullscreen/near-fullscreen overlays
local function tryDestroyOverlay(guiObj)
	if not guiObj or type(guiObj.IsA) ~= "function" then return end
	pcall(function()
		if not guiObj:IsA("GuiObject") then return end
		local cam = workspace.CurrentCamera
		local vp = (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
		local asx, asy = guiObj.AbsoluteSize.X, guiObj.AbsoluteSize.Y
		if asx and asy and asx > 0 and asy > 0 then
			if asx >= vp.X * 0.88 and asy >= vp.Y * 0.88 then
				local remove = false
				if guiObj:IsA("ImageLabel") or guiObj:IsA("ImageButton") then
					local imgTrans = guiObj.ImageTransparency or 0
					if (guiObj.Image and guiObj.Image ~= "") or imgTrans < 0.9 then remove = true end
				elseif guiObj:IsA("Frame") then
					local bt = guiObj.BackgroundTransparency or 1
					if bt < 0.9 then remove = true end
				else
					remove = true
				end
				if remove then pcall(function() guiObj:Destroy() end) end
			end
		end
	end)
end

local function monitorGuiObject(obj)
	if not obj or type(obj.IsA) ~= "function" then return end
	pcall(function()
		if obj:IsA("GuiObject") then
			-- initial check after a small delay so AbsoluteSize is set
			task.spawn(function() task.wait(0.05); tryDestroyOverlay(obj) end)
			-- watch for size changes
			obj:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				tryDestroyOverlay(obj)
			end)
		end
		-- monitor descendants
		for _, d in pairs(obj:GetDescendants()) do
			if d:IsA("GuiObject") then
				task.spawn(function() task.wait(0.05); tryDestroyOverlay(d) end)
				d:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() tryDestroyOverlay(d) end)
			end
		end
	end)
end

-- Attach monitors to existing CoreGui and PlayerGui ScreenGuis
pcall(function()
	local core = game:GetService("CoreGui")
	for _, g in pairs(core:GetChildren()) do monitorGuiObject(g) end
	if PlayerGui then for _, g in pairs(PlayerGui:GetChildren()) do monitorGuiObject(g) end end
	core.ChildAdded:Connect(function(child) task.wait(0.03); monitorGuiObject(child) end)
	if PlayerGui then PlayerGui.ChildAdded:Connect(function(child) task.wait(0.03); monitorGuiObject(child) end) end
end)

-- mark todo completed
pcall(function() end)

-- 프리미엄 사용자 환영 메시지
if table.find(PremiumWhitelist, me.UserId) then
	Notif("Welcome Premium User!", "프리미엄 기능에 접근할 수 있습니다!", 5)
end

Notif("🔍 Elora Hub", "모듈이 성공적으로 로드되었습니다!", 3)
