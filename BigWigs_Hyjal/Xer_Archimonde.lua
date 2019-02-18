----------------------------------
--      Module Declaration      --
----------------------------------
local boss = BB["Archimonde"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Hyjal Summit"]
mod.enabletrigger = boss
mod.guid = 17968
mod.toggleoptions = {"burst", "grip", "fear", "doomfire", "proximity", "enrage", "bosskill"}
mod.revision = 10000
mod.proximitySilent = true
mod.proximityCheck = function(unit)  --18 yards, via wiki burst is 15 yards
	if IsItemInRange(1251, unit) == 1 then --1251 is Linen Bandage, from testing this works even if the player does not have a bandage or first aid for that matter.
		return true
	end
	return false
end
local pName = UnitName("player")
local db = nil
local started = nil

local timer = {
	doomfire = 20,
	fear = 41.3,
}
local icon = {
	doomfire = 31903,
	fear = 31970,
	grip = 31972,
}
local syncName = {
	doomfire = "Doomfire"..mod.revision,
	fear = "Fear"..mod.revision,
	grip = "Grip"..mod.revision,
	grip_dispel = "gripDispel"..mod.revision,
	burst = "AirBurst"..mod.revision,
}

----------------------------
--      Localization      --
----------------------------
L:RegisterTranslations("enUS", function() return {
	cmd = "Archimonde",
	
	doomfire = "Doomfire",
	doomfire_desc = "Timer and alert for Doomfire Strikes",
	doomfire_alert = "Doomfire in 5 sec",
	
	fear = "AOE Fear",
	fear_desc = "Cooldown timer for AOE Fear",
	fear_bar = "~Fear Cooldown~",
	fear_alert = "AOE Fear Soon!",
	
	grip = "Grip of the Legion",
	grip_desc = "Alert for player with grip",
	grip_alert = "Grip on %s",
	
	burst = "Air Burst",
	burst_desc = "Alerts who has Air Burst",
	burst_say = "Air Burst on ME!",
	
	proximity = "Proximity",
	proximity = "Toggle display of the proximity box",
} end)

------------------------------
--      Initialization      --
------------------------------
function mod:OnEnable()
	--Register Doomfire trigger, if this does not work use yell trigger
	self:AddCombatListener("SPELL_CAST_SUCCESS", "doomfire", 31903)
	--Register fear trigger
	self:AddCombatListener("SPELL_CAST_START", "fear", 31970)
	--Grip trigger
	self:AddCombatListener("SPELL_AURA_APPLIED", "grip", 31972)
	self:AddCombatListener("SPELL_DISPEL", "gripDispel", 31972)

	self:AddCombatListener("SPELL_CAST_START", "burst", 32014)
	--Register things for engage/wipe/kill
	self:AddCombatListener("UNIT_DIED", "BossDeath")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	--Register sync for engage and timers
	self:RegisterEvent("BigWigs_RecvSync")
	self:TriggerEvent("BigWigs_ThrottleSync", syncName.doomfire, 5)
	self:TriggerEvent("BigWigs_ThrottleSync", syncName.fear, 5)
	self:Throttle(2, syncName.burst)
	self:Throttle(2, syncName.grip)
	self:Throttle(2, syncName.grip_dispel)
	
	started = nil
	db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------
function mod:doomfire()
	self:Sync(syncName.doomfire)
end
function mod:fear()
	self:Sync(syncName.fear)
end
function mod:grip(player,_)
	self:Sync(syncName.grip, player)
end
function mod:gripDispel(player)
	self:Sync(syncname.grip_dispel, player)
end

function mod:burst()
	self:ScheduleEvent("BurstTargetCheck", self.burstAlert, 0.2, self)
end
local function findUnit(unit)
	for i = 1, GetNumRaidMembers() do
		if UnitName("raid"..i.."target") == unit then
			return "raid"..i.."target"
		end
	end
	return false
end
function mod:burstAlert()
	local burst_target = UnitName(findUnit(boss).."target")
	if burst_target then
		self:Sync(syncName.burst, burst_target)
	end
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.doomfire and db.doomfire then
		self:Bar(L["doomfire"], timer.doomfire, icon.doomfire)
		self:DelayedMessage(timer.doomfire-5, doomfire_alert, "Important", icon.doomfire, "Alarm")
	elseif sync == syncName.fear and db.fear then
		self:Bar(L["fear_bar"], timer.fear, icon.fear)
		self:DelayedMessage(timer.fear-5, fear_alert, "Important", icon.fear, "Alarm")
	elseif sync == syncName.grip and db.grip and rest then
		local msg = L["grip_alert"]:format(rest)
		self:Message(msg, "Attention", icon.grip)
		self:Icon(rest)
	elseif sync == syncName.grip_dispel and rest then --Possible issue if the are more then one grip
		self:TriggerEvent("BigWigs_RemoveRaidIcon")
	elseif sync == syncName.burst and rest and db.burst then
		if rest == pName then
			SendChatMessage(L["burst_say"], "SAY")
		end
	end
	if self:ValidateEngageSync(sync, rest) and not started then
		started = true
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
		if db.enrage then
			self:Enrage(600)
		end
		--Start inital timers
		self:doomfire()
		self:fear()
		--Show proximity
		if db.proximity then
			self:TriggerEvent("BigWigs_ShowProximity", self)
		end
	end
end