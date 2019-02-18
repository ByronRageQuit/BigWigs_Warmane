----------------------------------
--      Module Declaration      --
----------------------------------
local boss = BB["The Lurker Below"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Serpentshrine Cavern"]
mod.enabletrigger = {boss, "Strange Pool"}
mod.guid = 21217
mod.wipemobs = {"Coilfang Guardian", "Coilfang Ambusher"} --Add localization at some point
mod.toggleoptions = {"spouttimer", "dive", "whirltimer", "bosskill"}
mod.revision = 10000
local pName = UnitName("player")
local db = nil
local started = nil
local submerged = nil
local emerge_count = nil

local timer = {
	whirl = {16,27}, --Update as tested
	spout = {37,71}, --Update as tested
	dive = {90,120}, --first is 90 rest are 120
	submerged = 60, --Time lurker is submerged
}
local icon = {
	whirl = 37363,
	spout = 37433,
	dive = "Spell_Frost_Stun",
}
local syncName = {
	whirl = "Whirl"..mod.revision,
	submerged = "Submerged"..mod.revision,
	emerged = "Emerged"..mod.revision,
}

L:RegisterTranslations("enUS", function() return {
	cmd = "Lurker",
	
	whirltimer = "Whirl Timer",
	whirltimer_desc = "Timer for Whirl",
	whirltimer_bar = "~Possible Whirl~",
	
	dive = "Dive",
	dive_desc = "Timer for lurker dive and emerge",
	
	spouttimer = "Spout",
	spouttimer_desc = "Estimation for spout",
	spouttimer_bar = "~Possible Spout~",
} end)

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	--Register whirl hits for timer
	self:AddCombatListener("SPELL_DAMAGE", "WhirlTimer", 37363)
	self:AddCombatListener("SPELL_MISSED", "WhirlTimer", 37363)
	--Register things for engage/wipe/kill
	self:AddCombatListener("UNIT_DIED", "BossDeath")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	--Register sync for engage and timers
	self:RegisterEvent("BigWigs_RecvSync")
	self:Throttle(10, syncName.whirl)
	self:Throttle(10, syncName.submerged)
	self:Throttle(10, syncName.emerged)
	
	started = nil
	submerged = nil
	emerge_count = nil
	db = self.db.profile
end

------------------------------
--     Utility Functions    --
------------------------------
local function findLurker()
--scans raid if anyone has lurker targeted
	for i = 1, GetNumRaidMembers() do
		if UnitName("raid"..i.."target") == boss then
			return true
		end
	end
	return false
end

function mod:startWhirl()
	self:Bar(L["whirltimer_bar"], timer.whirl[1], icon.whirl)
	self:ScheduleEvent("RepeatWhirl", self.startWhirl, timer.whirl[1], self) --Keeps timer if it skips, this might be broken
end
function mod:resetWhirl()
	self:CancelScheduledEvent("RepeatWhirl")
	self:TriggerEvent("BigWigs_StopBar", self, L["whirltimer_bar"])
end
function mod:resetSpout()
	self:TriggerEvent("BigWigs_StopBar", self, L["spouttimer_bar"])
end
------------------------------
--      Event Handlers      --
------------------------------
function mod:WhirlTimer()
	self:Sync(syncName.whirl)
end

function mod:LurkerCheck()
	if not findLurker() and not submerged then --This triggers once lurker transitions from up to down
		self:Sync(syncName.submerged)
	elseif findLurker() and submerged then --This is triggers once lurker returns
		self:Sync(syncName.emerged)
	end
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.whirl and db.whirltimer then
		self:resetWhirl()
		self:startWhirl()
		
	elseif sync == syncName.submerged then
		--cancel previous timers/events
		self:resetWhirl()
		self:resetSpout()
		self:TriggerEvent("BigWigs_StopBar", self, L["dive"]) -- reset Dive
		submerged = true --Update lurker state
		if db.dive then
			self:Bar("Emerge", timer.submerged, icon.dive) --start emerge timer
		end
		
	elseif sync == syncName.emerged then
		submerged = false --Update lurker state
		if emerge_count < 2 then emerge_count = emerge_count + 1 end --cap counter at 2
		if db.dive then
			self:Bar(L["dive"], timer.dive[emerge_count], icon.dive)
		end
		if db.whirltimer then
			self:Bar(L["whirltimer_bar"], timer.whirl[emerge_count], icon.whirl)
			self:ScheduleEvent("RepeatWhirl", self.startWhirl, timer.whirl[emerge_count], self)
		end
		if db.spouttimer then
			self:Bar(L["spouttimer_bar"], timer.spout[emerge_count], icon.spout)
		end
	end
	if self:ValidateEngageSync(sync, rest) and not started then
		--set inital state
		started = true
		submerged = true -- this is done so that LurkerCheck will execute the emerge section
		emerge_count = 0
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
		self:LurkerCheck()
		--Start up repeating event to check lurker state
		self:ScheduleRepeatingEvent("CheckLurkerState", self.LurkerCheck, 0.5, self)
	end
end