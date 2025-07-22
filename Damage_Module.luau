local Debris = game:GetService("Debris")



local function AttackMark(Target,AT,AN,AL)
	local Av = Instance.new("StringValue")
	Av.Name = AN
	Av.Value = AT.Name
	Av.Parent = Target
	if AL ~= "None" then
		Debris:AddItem(Av,AL)
	end
	return Av
end

local function CanAttackTarget(Target,AT,AN)
	for _,Av in pairs(Target:GetChildren()) do
		if Av:IsA("StringValue") and Av.Name == AN then
			if Av.Value == AT.Name then
				return false,Av
			end
		end
	end
	return true
end

local function DamageTarget(Target,E_Hm,AT,AN,AD,AL)
	E_Hm:TakeDamage(AD)
	AttackMark(Target,AT,AN,AL)
end


local Damage_Module = {}

function Damage_Module.CreateHitBox(Sz,Tp,CF)
	local HB = Instance.new("Part")
	HB.BrickColor = BrickColor.new("Bright red")
	HB.Size = Sz
	HB.CFrame = CF
	HB.Transparency = Tp
	HB.Anchored = false
	HB.CanCollide = false
	HB.Massless = true
	HB.CanTouch = true
	HB.Parent = workspace
	return HB
end

function Damage_Module.CreateAttackCoolDown(AT,AN,Length)
	local CV = Instance.new("StringValue")
	CV.Name = AN.."_OnCoolDown"
	CV.Value = AT.Name
	CV.Parent = AT
	spawn(function()
		wait(Length)
		CV:Destroy()
		print(AT.Name.." "..AN.." Cooldown is over.")
	end)
end

function Damage_Module.NormalAttack(Hit,AT,AN,AD,AL)
	local En = Hit.Parent
	local E_Hm = En:FindFirstChild("Humanoid")
	if E_Hm and E_Hm.Health > 0 and E_Hm ~= AT.Humanoid then
		local E_rp = En.PrimaryPart
		local CD = CanAttackTarget(En,AT,AN)--Can Damage
		if CD then
			print("CanDamage")
			DamageTarget(En,E_Hm,AT,AN,AD,AL)
			return true,En,E_Hm,E_rp
		end
	end
end




return Damage_Module
