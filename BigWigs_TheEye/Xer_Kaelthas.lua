----------------------------------
--      Module Declaration      --
----------------------------------

local boss = BB["Kael'thas Sunstrider"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local mod = BigWigs:NewModule(boss)

local capernian = BB["Grand Astromancer Capernian"]
local sanguinar = BB["Lord Sanguinar"]
local telonicus = BB["Master Engineer Telonicus"]
local thaladred = BB["Thaladred the Darkener"]

local axe = BB["Devastation"]
local mace = BB["Cosmic Infuser"]
local dagger = BB["Infinity Blades"]
local staff = BB["Staff of Disintegration"]
local sword = BB["Warp Slicer"]
local bow = BB["Netherstrand Longbow"]
local shield = BB["Phaseshift Bulwark"]

mod.zonename = BZ["Tempest Keep"]
mod.otherMenu = "The Eye"
mod.enabletrigger = {boss, capernian, sanguinar, telonicus, thaladred}
mod.guid = 19622
mod.wipemobs = {axe, mace, dagger, staff, sword, bow, shield}
mod.toggleoptions = {"conflagalert", -1, "mcalert", -1, "toy", "gaze", -1, "lapse", "barrier", "phoenix", "phase", "bosskill"}
mod.revision = 10000

local mc_players = {}
local conflag_players = {}
local fmt = string.format
local db = nil
local pName = UnitName("player")
local phase = nil
local barrier_count = nil
local phoenix_count = nil
local lapse_count = nil
local started = nil

local timer = {
	thaladred = 30,
	sanguinar = 13,
	capernian = 7,
	telonicus = 8,
	gaze = 9,
	toy = 60,
	advisors_inc = 101,
	kael_inc = 183,
	phoenix = {30,50, 90,40,70}, --first part is p4 second is p5
	barrier = {60,50}, --There is a chance that it can be 60,60,50
	lapse = {44,90},
}
local icon = {
	advisors = "Spell_Shadow_Charm",
	gaze = "Spell_Shadow_EvilEye",
	revive = "Spell_Holy_ReviveChampion",
	phoenix = "Spell_Fire_Burnout",
	barrier = "Spell_Nature_Lightningshield",
	lapse = "Spell_Nature_UnrelentingStorm",
	toy = 37027,
}
local syncName = {
	barrier = "Barrier"..mod.revision,
	gaze = "ThalGaze"..mod.revision,
	mc = "MC"..mod.revision,
	conflag = "Conflag"..mod.revision,
}

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Kael'thas",

	engage_trigger = "^Energy. Power.",
	thaladred_inc_trigger = "Impressive. Let us see how your nerves hold up against the Darkener, Thaladred!",
	sanguinar_inc_trigger = "You have persevered against some of my best advisors... but none can withstand the might of the Blood Hammer. Behold, Lord Sanguinar!",
	capernian_inc_trigger = "Capernian will see to it that your stay here is a short one.",
	telonicus_inc_trigger = "Well done, you have proven worthy to test your skills against my master engineer, Telonicus.",
	phase2_trigger = "As you see, I have many weapons in my arsenal....", --Weapons phase
	phase3_trigger = "Perhaps I underestimated you. It would be unfair to make you fight all four advisors at once, but... fair treatment was never shown to my people. I'm just returning the favor.",
	phase4_trigger = "Alas, sometimes one must take matters into one's own hands. Balamore shanal!",
	phase5_trigger = "I have not come this far to be stopped! The future I have planned will not be jeopardized! Now you will taste true power!!", --Flying phase
	
	phoenix = "Phoenix",
	phoenix_desc = "Timers for phoenix's",
	phoenix_bar = "Next Phoenix",
	phoenix_trigger1 = "Anar'anel belore!",
	phoenix_trigger2 = "By the power of the sun!",

	barrier = "Pyro/Barrier",
	barrier_desc = "Timer for pyroblast and Shock Barrier",
	barrier_bar = "Next Barrier/Pyro",
	
	lapse = "Gravity Lapse",
	lapse_desc = "Timer for Gravity Lapse",
	lapse_trigger1 = "Let us see how you fare when your world is turned upside down.",
	lapse_trigger2 = "Having trouble staying grounded?",
	
	gaze = "Gaze",
	gaze_desc = "Cooldown for Thaladred's gaze",
	gaze_bar = "~Gaze Cooldown~",
	gaze_alert = "Gaze on YOU!",
	gaze_trigger = "sets eyes on (%S+)!$",
	
	toy = "Remote Toy",
	toy_bar = "Remote Toy: %s",
	toy_alert = "Toy on %s",
	
	mcalert = "Mind Control",
	mcalert_desc = "Alert for the players that are Mind Controled",
	mcalert_msg = "Mind Controled: %s",
	
	conflagalert = "Conflag",
	conflagalert_desc = "Alert for players with conflag",
	conflagalert_msg = "Conflag on: %s",
	
	phase = "Phase warnings",
	phase_desc = "Timers for phases of the encounter.",
} end )

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_AURA_APPLIED", "Barrier", 36815) --Used to alert for barrier/pyro combo, unloaded after p4
	self:AddCombatListener("SPELL_AURA_APPLIED", "MC", 36797)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Conflag", 37018)
	self:AddCombatListener("SPELL_AURA_APPLIED", "ToyApply", 37027)
	self:AddCombatListener("SPELL_AURA_REMOVED", "ToyRemove", 37027)
	--Register things for engage/wipe/kill
	self:AddCombatListener("UNIT_DIED", "BossDeath")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	--Register sync for engage and timers
	self:RegisterEvent("BigWigs_RecvSync")
	self:Throttle(15, syncName.barrier)
	self:Throttle(5, syncName.gaze)

	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")

	db = self.db.profile
	started = nil
	phase = nil
	mc_players = {}
	conflag_players = {}
	barrier_count = nil
	phoenix_count = nil
	lapse_count = nil
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:Barrier()
	if phase ~= 4 then return end
	self:Sync(syncName.barrier)
end

function mod:MC(player)
	self:Sync(syncName.mc, player)
end

function mod:Conflag(player)
	self:Sync(syncName.conflag, player)
end

function mod:ToyApply(player)
	if db.toy and phase < 3 then
		self:Message(L["toy_alert"]:format(player), "Important", icon.toy)
		self:Bar(L["toy_bar"]:format(player), timer.toy, icon.toy)
	end
end

function mod:ToyRemove(player)
	if db.toy then
		self:TriggerEvent("BigWigs_StopBar", self, L["toy_bar"]:format(player))
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg:find(L["engage_trigger"]) then
		started = true
		phase = 1
		barrier_count = 0
		phoenix_count = 0
		fear_count = 0
		lapse_count = 0
		mc_players = {}
		conflag_players = {}
		self:Bar(thaladred, timer.thaladred, icon.advisors)
	elseif msg == L["phase2_trigger"] then
		phase = 2
		self:Bar("Phase 3", timer.advisors_inc, icon.revive)
	elseif msg == L["phase3_trigger"] then
		phase = 3
		self:Bar("Phase 4 - Kael'thas", timer.kael_inc, icon.advisors)
	elseif msg == L["phase4_trigger"] then
		phase = 4
		self:phoenixTimer()
		--Start first barrier timer
		self:Barrier()
	elseif msg == L["phase5_trigger"] then
		phase = 5
		phoenix_count = 2 --Makes sure that the p5 timers will be correct
		--cancel barrier stuff
		self:TriggerEvent("BigWigs_StopBar", self, L["barrier_bar"])
		self:phoenixTimer()
		self:lapseTimer()
	elseif msg == L["sanguinar_inc_trigger"] then
		self:Bar(sanguinar, timer.sanguinar, icon.advisors)
	elseif msg == L["capernian_inc_trigger"] then
		self:Bar(capernian, timer.capernian, icon.advisors)
	elseif msg == L["telonicus_inc_trigger"] then
		self:Bar(telonicus, timer.telonicus, icon.advisors)
	elseif (msg == L["phoenix_trigger1"] or msg == L["phoenix_trigger2"]) then
		self:phoenixTimer()
	elseif (msg == L["lapse_trigger1"] or msg == L["lapse_trigger2"]) then
		self:lapseTimer()
	end
end

function mod:CHAT_MSG_MONSTER_EMOTE(msg)
	if not db.gaze then return end
	local player = select(3, msg:find(L["gaze_trigger"]))
	self:Sync(syncName.gaze, player)
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.barrier and db.barrier then
		if barrier_count < 2 then barrier_count = barrier_count + 1 end --Cap at 2
		self:Bar(L["barrier_bar"], timer.barrier[barrier_count], icon.barrier)
	elseif sync == syncName.gaze and rest and db.gaze then
		if rest == pName then
			self:Message(L["gaze_alert"], "Urgent")
		end
		self:Bar(L["gaze_bar"], timer.gaze, icon.gaze)
	elseif sync == syncName.mc and rest and db.mcalert then
		mc_players[rest] = true
		self:ScheduleEvent("MCAlert", self.MCAlert, 0.3, self)
	elseif sync == syncName.conflag and rest and db.conflagalert then
		conflag_players[rest] = true
		self:ScheduleEvent("ConflagAlert", self.conflagAlert, 0.3, self)
	end
end

------------------------------
--     Helper Functions     --
------------------------------
function mod:lapseTimer()
	if db.lapse then
		if lapse_count < 2 then lapse_count = lapse_count+1 end
		self:Bar(L["lapse"], timer.lapse[lapse_count], icon.lapse)
	end
end

function mod:phoenixTimer()
	if not db.phoenix then return end
	if phase == 4 then
		if phoenix_count < 2 then phoenix_count = phoenix_count+1 end --In p4 cap at 2
	elseif phase == 5 then
		if phoenix_count < 5 then phoenix_count = phoenix_count+1 end --Then in p5 cap at 5
	end
	self:Bar(L["phoenix_bar"], timer.phoenix[phoenix_count], icon.phoenix)
end

function mod:MCAlert()
	local temp_msg = ""
	for k in pairs(mc_players) do
		temp_msg = temp_msg..k..", "
	end
	self:Message(L["mcalert_msg"]:format(temp_msg), "Important")
	mc_players = {} --reset the table
end

function mod:conflagAlert()
	local temp_conflag_msg = ""
	for k in pairs(conflag_players) do
		temp_conflag_msg = temp_conflag_msg..k..", "
	end
	self:Message(L["conflagalert_msg"]:format(temp_conflag_msg), "Important")
	conflag_players = {}
end