----------------------------------
--      Module Declaration      --
----------------------------------
local boss = BB["Rage Winterchill"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Hyjal Summit"]
mod.enabletrigger = boss
mod.guid = 17767
mod.toggleoptions = {"decaytimer", "decayalert", -1, "icebolttimer", "iceboltalert", "icebolticon", "enrage", "bosskill"}
mod.revision = 10000
local pName = UnitName("player")
local db = nil
local started = nil
local decaycount = 0

local timer = {
	icebolt = 6,
	decay = {45,70}, --first is good, second is close ~65-70
}
local icon = {
	icebolt = 31249,
	decay = 31258,
}
local syncName = {
	icebolttimer = "IceboltTimer"..mod.revision,
	iceboltalert = "IceboltAlert"..mod.revision,
	decaytimer = "Decaytimer"..mod.revision,
}


L:RegisterTranslations("enUS", function() return {
	cmd = "Winterchill",
	
	icebolt = "Icebolt",
	icebolttimer = "Ice Bolt Timer",
	icebolttimer_desc = "Timer bar for icebolts",
	
	iceboltalert = "Icebolt Alert",
	iceboltalert_desc = "Notification for icebolt target",
	iceboltalert_msg = "Icebolt on %s",
	icebolticon = "Icebolt Icon",
	icebolticon_desc = "Puts an icon on the icebolted target",
	
	decayalert = "Death & Decay Alert",
	decayalert_desc = "Notification if in Death & Decay",
	decayalert_msg = "Death & Decay on YOU",
	decaytimer = "Death & Decay Timer",
	decaytimer_desc = "Timer bar for Death & Decay Cooldown",
	decaybartext = "~Possible D&D~",
	
} end)


------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_CAST_SUCCESS", "IceboltTimer", 31249)
	self:AddCombatListener("SPELL_AURA_APPLIED", "IceboltAlert", 31249)
	self:AddCombatListener("SPELL_AURA_APPLIED", "DecayAlert", 31258)
	self:AddCombatListener("SPELL_CAST_START", "DecayTimer", 31258)
	--Register things for engage/wipe/kill
	self:AddCombatListener("UNIT_DIED", "BossDeath")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	--Register sync for engage and timers
	self:RegisterEvent("BigWigs_RecvSync")
	self:TriggerEvent("BigWigs_ThrottleSync", syncName.icebolttimer, 2)
	self:TriggerEvent("BigWigs_ThrottleSync", syncName.iceboltalert, 2)
	self:TriggerEvent("BigWigs_ThrottleSync", syncName.decaytimer, 16)
	
	
	started = nil
	db = self.db.profile
	decaycount = 0
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:IceboltTimer()
	self:Sync(syncName.icebolttimer)
end
function mod:IceboltAlert(player, spellID)
	self:Sync(syncName.iceboltalert, player)
end
function mod:DecayAlert(player, spellID)
	if db.decayalert and player == pName then
		self:IfMessage(L["decayalert_msg"], "Attention", icon.decay)
	end
end
function mod:DecayTimer()
	self:Sync(syncName.decaytimer)
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.icebolttimer and db.icebolttimer then
		self:Bar(L["icebolt"], timer.icebolt, icon.icebolt)
	elseif sync == syncName.iceboltalert and rest then
		local IBPlayer = rest
		local IBAlertmsg = L["iceboltalert_msg"]:format(IBPlayer)
		if db.iceboltalert then
			self:IfMessage(IBAlertmsg, "Attention", icon.icebolt)
		end
		if db.icebolticon then
			self:Icon(IBPlayer)
		end
	elseif sync == syncName.decaytimer then
		decaycount = decaycount + 1
		if decaycount > 2 then decaycount = 2 end
		if db.decaytimer then
			self:Bar(L["decaybartext"], timer.decay[decaycount], icon.decay)
		end
		if db.icebolttimer then
			--self:TriggerEvent("BigWigs_StopBar", self, L["icebolt"])
			self:Bar(L["icebolt"], 15, icon.icebolt) --D&D stops icebolts, but will cast one iimmediately after, should not user aura_applied as it ticks and resets this timer
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
		--start inital timers
		self:DecayTimer()
		self:IceboltTimer()
	end
end