local boss = BB["Gurtogg Bloodboil"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Black Temple"]
mod.enabletrigger = boss
mod.toggleoptions = {"bloodboil", "phase", "fel_rage", "icon", "enrage","bosskill"} --eject, acid_breath later
mod.revision = 1000
local db = nil
local started = nil
local blood_count = nil

local timer = {
	phase1_duration = 68,
	phase2_duration = 30,
	bloodboil = {10,55}, --second is the 6th that gets delayed by rage/p2
}

local icon = {
	bloodboil = 42005,
	fel_rage = 40604,
}

local syncName = {
	bloodboil = "bloodboil"..mod.revision,
}

L:RegisterTranslations("enUS", function() return {
	cmd = "Gurtogg",
	engage_trigger = "Horde will", --use string:find()
	
	phase = "Phases",
	phase_desc = "Phase Timers",
	phase1_bar = "Phase 1",
	phase2_bar = "Phase 2",
	phase2_soon_msg = "Phase 2 in 10sec!",
	
	bloodboil = "Bloodboil",
	bloodboil_desc = "Bloodboil timer and count",
	bloodboil_msg = "Bloodboil: Group %s Next",
	bloodboil_bar = "Next Bloodboil",
	
	fel_rage = "Fel Rage",
	fel_rage_desc = "Alert for Fel Rage target",
	fel_rage_msg = "Fel Rage on %s!",
	
} end)

function mod:OnEnable()
	self:AddCombatListener("SPELL_AURA_APPLIED", "Bloodboil", 42005)
	self:AddCombatListener("SPELL_AURA_APPLIED_DOSE", "Bloodboil", 42005)
	self:AddCombatListener("SPELL_AURA_APPLIED", "FelRageApplied", 40604)
	self:AddCombatListener("SPELL_AURA_REMOVED", "FelRageRemoved", 40594)
	self:AddCombatListener("UNIT_DIED", "BossDeath")

    self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("BigWigs_RecvSync")
	
	self:Throttle(5, syncName.bloodboil)
	
	db = self.db.profile
	started = nil
	blood_count = nil
end

function mod:Bloodboil()
	self:Sync(syncName.bloodboil)
end

function mod:FelRageApplied(player)
	if not db.fel_rage then return end
	if db.icon then
		self:Icon(player)
	end
	if UnitIsUnit(player, "player") then player = "YOU" end
	self:Message(L["fel_rage_msg"]:format(player), "Urgent", icon.fel_rage)
	self:Bar(L["phase1_bar"], timer.phase2_duration)
end
function mod:FelRageRemoved()
	self:EnterPhase1()
end
function mod:EnterPhase1()
	self:Bar(L["phase2_bar"], timer.phase1_duration, icon.fel_rage)
	self:ScheduleEvent("Phase2Warn", "BigWigs_Message", timer.phase1_duration-5, "Phase 2 in 5 sec", "Attention")
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.bloodboil and db.bloodboil then
		blood_count = blood_count+1
		local blood_group = (blood_count%3)+1
		if (blood_count ~= 0) and (blood_count%5 == 0) then --if not the first and is the 6th boil then use second time
			self:Bar(L["bloodboil_bar"], timer.bloodboil[2], icon.bloodboil)
		else
			self:Bar(L["bloodboil_bar"], timer.bloodboil[1], icon.bloodboil)
		end
		self:Message(L["bloodboil_msg"]:format(blood_group), "Attention", icon.bloodboil, "None")
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg:find(L["engage_trigger"]) then
		blood_count = -1
		self:Sync(syncName.bloodboil)
		self:EnterPhase1()
		--self:Enrage(600)
	end
end