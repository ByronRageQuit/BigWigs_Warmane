----------------------------------
--      Module Declaration      --
----------------------------------
local boss = BB["Azgalor"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Hyjal Summit"]
mod.enabletrigger = boss
mod.guid = 17842
mod.toggleoptions = {"fire", "doomtimer", "doomalert", "howl", "enrage", "bosskill"}
mod.revision = 10000
local pName = UnitName("player")
local db = nil
local started = nil
local howl_count

local timer = {
	doom = 45.7,
	howl = {15,18},--at least first howl seems to be faster
}
local icon = {
	doom = 31347,
	howl = 31344,
}
local syncName = {
	doom_timer = "DoomTimer"..mod.revision,
	howl = "Howl"..mod.revision,
	doom_alert = "DoomAlert"..mod.revision,
}

L:RegisterTranslations("enUS", function() return {
	cmd = "Azgalor",
	
	fire = "Rain of Fire",
	fire_desc = "Notification if standing in Raid of Fire",
	fire_msg = "Rain of Fire on YOU",
	
	doom = "Doom",
	doomtimer = "Doom Timer",
	doomtimer_bar = "Next Doom",
	doomtimer_desc = "Timer for doom",
	
	doomalert = "Doom Alert",
	doomalert_desc = "Alerts and marks who has Doom",
	doom_you = "Doom on YOU",
	doom_other = "Doom on %s",
	
	howl = "Howl of Azgalor",
	howl_desc = "Timer for Howl",
} end)

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	--Register Rain of Fire aura
	self:AddCombatListener("SPELL_AURA_APPLIED", "Rain_of_Fire", 31340)
	--Register doom triggers
	self:AddCombatListener("SPELL_CAST_START", "DoomTimer", 31347)
	self:AddCombatListener("SPELL_AURA_APPLIED", "DoomAlert", 31347)
	--Howl cast trigger
	self:AddCombatListener("SPELL_CAST_SUCCESS", "HowlTimer", 31344)
	
	--Register things for engage/wipe/kill
	self:AddCombatListener("UNIT_DIED", "BossDeath")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	--Register sync for engage and timers
	self:RegisterEvent("BigWigs_RecvSync")
	self:TriggerEvent("BigWigs_ThrottleSync", syncName.doom_timer, 5)
	self:TriggerEvent("BigWigs_ThrottleSync", syncName.howl, 5)
	self:TriggerEvent("BigWigs_ThrottleSync", syncName.doom_alert, 5)
	
	started = nil
	db = self.db.profile
	howl_count = 0
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:Rain_of_Fire(player, spellID)
	if db.fire and player == pName then	--If enabled and the player is affected
		self:LocalMessage(L["fire_msg"], "Urgent", 31340, "Alarm")
	end
end

function mod:DoomAlert(player)
	self:Sync(syncName.doom_alert, player)
end
function mod:DoomTimer()
	--db.doom is check in the RecvSync below
	self:Sync(syncName.doom_timer)
end

function mod:HowlTimer()
	self:Sync(syncName.howl)
end
	

function mod:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.doom_timer and db.doomtimer then
		self:Bar(L["doom"], timer.doom, icon.doom)
		self:ScheduleEvent("doomsoonmsg", "BigWigs_Message", timer.doom, "Doom within 5 sec", "Attention")
	elseif sync == syncName.howl and db.howl then
		howl_count = howl_count + 1
		if howl_count > 2 then howl_count = 2 end
		self:Bar(L["howl"], timer.howl[howl_count], icon.howl)
	elseif sync == syncName.doom_alert and db.doomalert and rest then
		local doomedplayer = rest
		local other = L["doom_other"]:format(doomedplayer)
		if doomedplayer == pName then
			self:LocalMessage(L["doom_you"], "Personal", icon.doom, "Long")
		else
			self:IfMessage(other, "Attention", icon.doom)
		end
		self:Icon(doomedplayer)
		self:ScheduleEvent("ClearIcon", "BigWigs_RemoveRaidIcon", 20, self) --Remove icon after death
	end
	if self:ValidateEngageSync(sync, rest) and not started then
		started = true
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
		--Start inital timers
		if db.enrage then
			self:Enrage(600)
		end
		--option check in recvSync
		self:DoomTimer()
		self:HowlTimer()
	end
end