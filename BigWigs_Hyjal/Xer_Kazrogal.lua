----------------------------------
--      Module Declaration      --
----------------------------------
local boss = BB["Kaz'rogal"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Hyjal Summit"]
mod.enabletrigger = boss
mod.guid = 17888
mod.toggleoptions = {"manaalert", "marktimer", "stomptimer", "bosskill"}
mod.revision = 10000
local pName = UnitName("player")
local db = nil
local started = nil
local count = 0

local timer = {
	stomp = 10.1,
	mark = 45,
}
--Think the mark timer works like this, from engage to first is say 43.52 sec, then the next will be 40,35,30 etc. following the normal pattern.
local icon = {
	stomp = 31480,
	mark = 31447,
}
local syncName = {
	stomp = "Stomp"..mod.revision,
	mark = "Mark"..mod.revision,
}

----------------------------
--      Localization      --
----------------------------
L:RegisterTranslations("enUS", function() return {
	cmd = "Kazrogal",
	
	stomptimer = "War Stomp Timer",
	stomptimer_desc = "Timer for War Stomp",
	stomptimer_bar = "~Stomp~",
	
	marktimer = "Mark Timer",
	marktimer_desc = "Mark of Kaz'rogal timer",
	marktimer_bar = "Next Mark (%d)",
	
	manaalert = "Mana Alert",
	manaalert_desc = "Alerts you if you mana is low on mark application",
	manaalert_msg = "MANA LOW!!!",
} end)

------------------------------
--      Initialization      --
------------------------------
function mod:OnEnable()
	self:AddCombatListener("SPELL_CAST_SUCCESS", "stomp", 31480)
	self:AddCombatListener("SPELL_CAST_START", "mark", 31447)
	self:AddCombatListener("SPELL_AURA_APPLIED", "manacheck", 31480)
	--Register things for engage/wipe/kill
	self:AddCombatListener("UNIT_DIED", "BossDeath")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	--Register sync for engage and timers
	self:RegisterEvent("BigWigs_RecvSync")
	self:Throttle(5, syncName.stomp)
	self:Throttle(5, syncName.mark)
	
	started = nil
	db = self.db.profile
	count = 0
	
end

------------------------------
--      Event Handlers      --
------------------------------
function mod:stomp()
	self:Sync(syncName.stomp)
end
function mod:mark()
	self:Sync(syncName.mark)
end
function mod:manacheck(player)
	if player == pName and UnitPowerType("player") == 0 and UnitMana("player") < 4000 and db.manaalert then
		self:IfMessage(L["manaalert_msg"], "Attention")
	end
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.stomp and db.stomptimer then
		self:Bar(L["stomptimer_bar"], timer.stomp, icon.stomp)
	elseif sync == syncName.mark and db.marktimer then
		count = count + 1
		if count > 8 then count = 8 end --Caps the timer at 10 sec
		self:Bar(L["marktimer_bar"]:format(count), timer.mark-(5*(count-1)), icon.mark)
	end

	if self:ValidateEngageSync(sync, rest) and not started then
		started = true
		count = 0
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
		self:Sync(syncName.stomp)
		self:Sync(syncName.mark)
	end
end