local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local FreezeRay_Folder = game:GetService("ReplicatedStorage"):WaitForChild("FreezeRay_Folder")
local Damage_Module = require(script.Damage_Module)

local char = nil
local Hm = nil
local rp = nil

--Tool Info--
local Tool = script.Parent
local Track = nil
local Gun = Tool:WaitForChild("Gun")
local Active = Tool.Active

--Attack Info--
local Attack_Name = "Freeze"
local Attack_Damage = 5
local Damage_Length = 2
local CoolDown_Length = 2
local Max_Freeze_Length = 3


local Frozen_Length = 1

---------------------
-- LOCAL FUNCTIONS--
----------------------

local function WeldItem(P1,P2,WeldName)
	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = P1
	Weld.Part1 = P2
	Weld.Name = WeldName
	Weld.Parent = P1
end

local function Glow(Gun,Action,Speed)
	local SpotLight = Gun:WaitForChild("InsidePart"):WaitForChild("Light_Attachment"):WaitForChild("SpotLight")
	local Goals = {
		["Lights On"] = {
			Brightness = 20;
			Angle = 90;
			Range = 21;
		};
		
		["Lights Off"] = {
			Brightness = 0;
			Angle = 0;
			Range = 0;
		}
	}
	
	TweenService:Create(SpotLight,TweenInfo.new(Speed,Enum.EasingStyle.Bounce),Goals[Action]):Play()
end

local function IcySmoke(Gun,Action)
	local Particles_Attachment = Gun.InsidePart.IcySmoke_Particles
	for _,v in pairs(Particles_Attachment:GetChildren()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = Action
		end
	end
end

local function Freeze_Particles_Effect(Gun,Action)
	local InsidePart = Gun.InsidePart
	local Particles = {
		InsidePart.Freeze_Particles;
		InsidePart.Frost_Particles;
	}
	if Action == "Freeze" then
		spawn(function()
			for i=1,20 do
				for _,v in pairs(Particles[2]:GetChildren()) do
					if v:IsA("ParticleEmitter") then
						v:Emit(2)
					end
					wait()
				end
			end
		end)
		wait(0.2)
		spawn(function()
			for _,v in pairs(Particles) do
				for _,p in pairs(v:GetChildren()) do
					p.Enabled = true
				end
			end
		end)
	else
		for _,v in pairs(Particles) do
			for _,p in pairs(v:GetChildren()) do
				p.Enabled = false
			end
		end
	end
end	

local function FreezeBody(Body)
	local Frozen_Parts = {}
		
	for _,v in pairs(Body:GetChildren()) do
		local FP = nil
		if v:IsA("MeshPart") then
			FP = v:Clone()
		elseif v.Name == "Head" then
			FP = FreezeRay_Folder:WaitForChild("Fake_Head"):Clone()
		end
		
		if FP ~= nil then
			FP.Anchored=  false
			FP.CanTouch = false
			FP.Massless = true
			FP.CanCollide = false
			
			FP.Name = "Frozen_Part"
			FP.Material = "Ice"
			FP.Color = Color3.fromRGB(82, 195, 255)
			FP.Transparency = 1
			FP.Size = v.Size * 1.2
			FP.CFrame = v.CFrame
			WeldItem(FP,v,"Frozen_Part_Weld")
			FP.Parent = workspace
			table.insert(Frozen_Parts,#Frozen_Parts+1,FP)
			TweenService:Create(FP,TweenInfo.new(0.5),{Transparency = 0.1}):Play()
		end
	end
	
	spawn(function()
		wait(Frozen_Length)
		for _,FP in pairs(Frozen_Parts) do
			TweenService:Create(FP,TweenInfo.new(0.5),{Transparency = 0.5}):Play()
			Debris:AddItem(FP,0.5)
		end
	end)
end

local function Freeze_Damage(Hit,AT,AN,AD,AL)
	local DidHit,En,E_Hm,E_rp = Damage_Module.NormalAttack(Hit,AT,AN,AD,AL)
	if DidHit then
		for _,Animation in pairs(E_Hm:GetPlayingAnimationTracks()) do
			Animation:AdjustSpeed(0)
		end
		
		E_Hm.WalkSpeed = 0
		E_Hm.JumpPower = 0
		E_Hm.AutoRotate = false
		FreezeBody(En)
		wait(Frozen_Length)
		E_Hm.WalkSpeed = 16
		E_Hm.JumpPower = 50
		E_Hm.AutoRotate = true
		
		for _,Animation in pairs(E_Hm:GetPlayingAnimationTracks()) do
			Animation:AdjustSpeed(1)
		end
	end
end


Tool.Equipped:Connect(function()
	if not Gun:FindFirstChild("Gun_Weld") then
		char = Tool.Parent
		Hm = char.Humanoid
		rp = char.PrimaryPart
		
		Gun.PrimaryPart.Anchored = false
		local char = Tool.Parent
		local RH = char.RightHand
		
		Gun:SetPrimaryPartCFrame(RH.CFrame * CFrame.new(0,-0.7,-0.3) * CFrame.Angles(-1.6,0,0))
		WeldItem(Gun.PrimaryPart,RH,"Gun_Weld")
	end
end)

Tool.Activated:Connect(function()
	Track = Hm:LoadAnimation(Tool.Shoot)
	local HB = nil
	
	if Track ~= nil and Attack_Name.."_OnCoolDown" then
		if Active.Value ~= true then
			Track:GetMarkerReachedSignal("Shoot"):Connect(function()
				IcySmoke(Gun,false)
				Active.Value = true
				Track:AdjustSpeed(0)
				Track.TimePosition = Track:GetTimeOfKeyframe("Pose")
				Glow(Gun,"Lights On",0.5)
				
				Freeze_Particles_Effect(Gun,"Freeze")	
				HB = Damage_Module.CreateHitBox(Vector3.new(4.9, 7.473, 15.66),1,rp.CFrame * CFrame.new(1.5,1.5,-12))
				WeldItem(HB,rp,"HitBox_Weld")
				
				HB.Touched:Connect(function(Hit)
					Freeze_Damage(Hit,char,Attack_Name,Attack_Damage,Damage_Length)
				end)
				
				spawn(function()
					while Active.Value == true do
						for _,Hit in pairs(HB:GetTouchingParts()) do
							Freeze_Damage(Hit,char,Attack_Name,Attack_Damage,Damage_Length)
						end
						wait()
					end
				end)
			end)	
			
			Track:GetMarkerReachedSignal("Turn Off"):Connect(function()
				HB:Destroy()
				Glow(Gun,"Lights Off",1)
				Freeze_Particles_Effect(Gun,"Off")
				IcySmoke(Gun,true)
			end)

			Track:GetMarkerReachedSignal("End"):Connect(function()
				Active.Value = false
				Damage_Module.CreateAttackCoolDown(char,Attack_Name.."_OnCoolDown",CoolDown_Length)
			end)
			
			Track:Play()
			spawn(function()
				local Sec = 1
				
				repeat 
					Sec = Sec + 1
					wait(1)
				until Sec == Max_Freeze_Length
				
				Track:AdjustSpeed(1)
			end)
		end		
	end
end)

Tool.Deactivated:Connect(function()
	Track:AdjustSpeed(1)
end)
