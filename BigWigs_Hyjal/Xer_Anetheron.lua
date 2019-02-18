local boss = BB["Anetheron"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local db = nil
local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Hyjal Summit"]
mod.enabletrigger = boss
mod.wipemobs = {"Towering Infernal"} --Localize at some point
mod.guid = 17808
mod.toggleoptions = {"infernaltimer", "infernalalert", "icon", "swarm", "bosskill"}
mod.revision = 1000

local timer = {
	swarm = 12,
	infernal = 48,
}
local icon = {
	swarm = 31306,
	infernal = 31299,
}
local syncName = {
	infernalTimer = "InfernalTimer"..mod.revision,
	infernalAlert = "InfernalAlert"..mod.revision,
}

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Anetheron",
	
	infernaltimer = "Infernal",
	infernaltimer_desc = "Timer for Summon Infernal",
	infernal_bar = "Next Infernal",
	
	infernalalert = "Infernal Alert",
	infernalalert_desc = "Alert for the target of Infernal",
	infernalalert_msg = "Infernal on %s!",
	
	icon = "Infernal Icon",
	icon_desc = "Puts icon on the Infernal target",

	swarm = "Carrion Swarm",
	swarm_desc = "Carrion Swarm cooldown timer",
	swarm_bar = "~Swarm Cooldown~",
} end )

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Swarm", 31306)
	self:AddCombatListener("SPELL_CAST_START", "Infernal", 31299)
	self:AddCombatListener("UNIT_DIED", "BossDeath")
	
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("BigWigs_RecvSync")
	self:Throttle(30, syncName.infernalTimer)
	self:Throttle(30, syncName.infernalAlert)

	db = self.db.profile
end

------------------------------
--     Utility Functions    --
------------------------------
local function findUnit(unit)
	for i = 1, GetNumRaidMembers() do
		if UnitName("raid"..i.."target") == unit then
			return "raid"..i.."target"
		end
	end
	return false
end

------------------------------
--      Event Handlers      --
------------------------------
function mod:Swarm()
	if not db.swarm then return end
	self:Bar(L["swarm_bar"], timer.swarm, icon.swarm)
end
function mod:Infernal()
	self:Sync(syncName.infernalTimer) --Send timer sync
	self:ScheduleEvent("InfernalTargetCheck", self.infernalAlert, 0.3, self) --Start target check
end
function mod:infernalAlert()
	local infernal_target = UnitName(findUnit(boss).."target")
	if infernal_target then
		self:Sync(syncName.infernalAlert, infernal_target)
	end
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.infernalTimer and db.infernaltimer then
		self:Bar(L["infernal_bar"], timer.infernal, icon.infernal)
		
	elseif sync == syncName.infernalAlert and rest then
		if db.infernalalert then
			self:Message(L["infernalalert_msg"]:format(rest), "Important")
		end
		if db.icon then
			self:Icon(rest)
			self:ScheduleEvent("ClearIcon", "BigWigs_RemoveRaidIcon", 5, self)
		end
	end

	if self:ValidateEngageSync(sync, rest) and not started then
		started = true
		--start inital timers
		self:Swarm()
		self:Sync(syncName.infernalTimer)
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
	end
end