----------------------------------
--      Module Declaration      --
----------------------------------
local boss = BB["High Astromancer Solarian"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Tempest Keep"]
mod.otherMenu = "The Eye"
mod.enabletrigger = {boss}
mod.guid = 18805
mod.wipemobs = {"Solarium Priest", "Solarium Agent"} --Add localization at some point
mod.toggleoptions = {"fear", "wrath", "vanish", "bosskill"}
mod.revision = 10000
local pName = UnitName("player")
local db = nil
local started = nil
local submerged = nil
local emerge_count = nil
local wrath_count = nil
local fear_count = nil
local phaseThreeAnnounced = nil

local timer = {
	submerge = 52,
	emerge = 20,
	wrath = {22,22,29},
	fear = {8,13}, --Needs testing
}
local icon = {
	submerge = "ability_vanish",
	emerge = "ability_creature_cursed_04",
	wrath = 33040,
	fear = 34322,
}
local syncName = {
	submerged = "Submerged"..mod.revision,
	emerged = "Emerged"..mod.revision,
	wrath = "Wrath"..mod.revision,
	fear = "SolFear"..mod.revision,
}

L:RegisterTranslations("enUS", function() return {
	cmd = "Solarian",
	
	vanish = "Vanish",
	vanish_desc = "Timer for vanish/reappear",
	
	wrath = "Wrath of the Astromancer",
	wrath_desc = "Timer and alert for bomb debuff",
	wrath_bar = "Wrath of the Astromancer",
	wrath_msg = "Wrath on %s",
	
	fear = "Fear",
	fear_desc = "Cooldown for phase 3 fear",
	fear_bar = "~Possible Fear~",
} end)

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	--Register spell events
	self:AddCombatListener("SPELL_CAST_START", "Wrath", 33040)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Fear", 34322)
	--For Phase 3 transition
	self:RegisterEvent("UNIT_HEALTH")
	--Register things for engage/wipe/kill
	self:AddCombatListener("UNIT_DIED", "BossDeath")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	--Register sync for engage and timers
	self:RegisterEvent("BigWigs_RecvSync")
	self:Throttle(10, syncName.emerged)
	self:Throttle(10, syncName.submerged)
	self:Throttle(10, syncName.wrath)
	self:Throttle(5, syncName.fear)
	
	started = nil
	submerged = nil
	emerge_count = nil
	wrath_count = nil
	fear_count = nil
	phaseThreeAnnounced = nil
	db = self.db.profile
end

------------------------------
--     Utility Functions    --
------------------------------
local function findLurker()
--scans raid if anyone has lurker targeted
	for i = 1, GetNumRaidMembers() do
		if UnitName("raid"..i.."target") == boss then
			return "raid"..i
		end
	end
	return false
end

------------------------------
--      Event Handlers      --
------------------------------
function mod:LurkerCheck()
	if not findLurker() and not submerged then --This triggers once lurker transitions from up to down
		self:Sync(syncName.submerged)
	elseif findLurker() and submerged then --This is triggers once lurker returns
		self:Sync(syncName.emerged)
	end
end

function mod:Wrath()
	self:ScheduleEvent("WrathTargetCheck", self.wrathAlert, 0.2, self)
end
function mod:wrathAlert()
	local wrath_target = UnitName(findLurker().."targettarget")
	if wrath_target then
		self:Sync(syncName.wrath, wrath_target)
	end
end

function mod:Fear()
	self:Sync(syncName.fear)
end

function mod:UNIT_HEALTH(msg)
	if UnitName(msg) == boss then
		local hp = UnitHealth(msg)
		if hp <= 20 and not phaseThreeAnnounced then
			phaseThreeAnnounced = true
			self:Fear()
		end
	end
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.submerged then
		submerged = true
		if db.vanish then
			self:TriggerEvent("BigWigs_StopBar", self, "Vanish")
			self:Bar("Return", timer.emerge, icon.emerge)
		end
	elseif sync == syncName.emerged then
		submerged = false
		if db.vanish then
			self:TriggerEvent("BigWigs_StopBar", self, "Return")
			self:Bar("Vanish", timer.submerge, icon.submerge)
		end
	elseif sync == syncName.wrath and rest and db.wrath then
		wrath_count = wrath_count+1
		local wrath_cycle = (wrath_count%3)+1
		self:Bar(L["wrath_bar"], timer.wrath[wrath_cycle], icon.wrath)
		self:IfMessage(L["wrath_msg"]:format(rest), "Attention", icon.wrath)
	elseif sync == syncName.fear and db.fear then
		if fear_count < 2 then fear_count = fear_count + 1 end --Cap at 2
		self:Bar(L["fear_bar"], timer.fear[fear_count], icon.fear)
	end

	if self:ValidateEngageSync(sync, rest) and not started then
		--set inital state
		started = true
		submerged = true -- this is done so that LurkerCheck will execute the emerge section
		emerge_count = 0
		wrath_count = -1 --This is due to lua starting index at 1 not 0
		fear_count = 0
		phaseThreeAnnounced = false
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
		self:LurkerCheck()
		--Start up repeating event to check lurker state
		self:ScheduleRepeatingEvent("CheckLurkerState", self.LurkerCheck, 0.5, self)
	end
end