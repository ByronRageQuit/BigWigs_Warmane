------------------------------
--      Are you local?    --
------------------------------

local boss = BB["Supremus"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local started = nil
local pName = UnitName("player")
local db = nil
local previous = nil
local UnitName = UnitName
local fmt = string.format

----------------------------
--      Localization     --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Supremus",

	phase = "Phases",
	phase_desc = "Warn about the different phases.",
	normal_phase_message = "Tank'n'spank!",
	normal_phase_trigger = "Supremus punches the ground in anger!",
	kite_phase_message = "%s loose!",
	kite_phase_trigger = "The ground begins to crack open!",
	next_phase_bar = "Next phase",
	next_phase_message = "Phase change in 10sec!",

	punch = "Molten Punch",
	punch_desc = "Alert when he does Molten Punch, and display a countdown bar.",
	punch_message = "Molten Punch!",
	punch_bar = "~Possible Punch!",

	target = "Target",
	target_desc = "Warn who he targets during the kite phase, and put a raid icon on them.",
	target_message = "%s being chased!",
	target_you = "YOU are being chased!",
	target_message_nounit = "New target!",

	icon = "Raid Target Icon",
	icon_desc = "Place a Raid Target Icon on the player being chased(requires promoted or higher).",
} end )

----------------------------------
--    Module Declaration   --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Black Temple"]
mod.enabletrigger = boss
mod.guid = 22898
mod.toggleoptions = {"punch", "target", "icon", "phase", "enrage", "bosskill"}
mod.revision = tonumber(("$Revision: 4720 $"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Punch", 40126)
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	started = nil
	previous = nil

	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("BigWigs_RecvSync")

	db = self.db.profile
end

------------------------------
--    Event Handlers     --
------------------------------

function mod:Punch(_, spellID)
	if db.punch then
		self:IfMessage(L["punch_message"], "Attention", spellID)
		self:Bar(L["punch_bar"], 10, spellID)
	end
end

function mod:TargetCheck()
	local target
	if UnitName("target") == boss then
		target = UnitName("targettarget")
	elseif UnitName("focus") == boss then
		target = UnitName("focustarget")
	else
		local num = GetNumRaidMembers()
		for i = 1, num do
			if UnitName(fmt("%s%d%s", "raid", i, "target")) == boss then
				target = UnitName(fmt("%s%d%s", "raid", i, "targettarget"))
				break
			end
		end
	end
	if target ~= previous then
		if target then
			local other = fmt(L["target_message"], target)
			if target == pName then
				self:LocalMessage(L["target_you"], "Personal", nil, "Alarm")
				self:WideMessage(other)
			else
				self:Message(other, "Attention")
			end
			self:Icon(target, "icon")
			previous = target
		else
			previous = nil
		end
	end
end

local phaselength = 60
function mod:Normal()
	if db.phase then
		self:Message(L["normal_phase_message"], "Positive")
		self:Bar(L["next_phase_bar"], phaselength, "INV_Helmet_08")
		self:DelayedMessage(phaselength-10, L["next_phase_message"], "Attention")
	end
	if db.target then
		self:CancelScheduledEvent("BWSupremusToTScan")
		self:TriggerEvent("BigWigs_RemoveRaidIcon")
	end
	self:ScheduleEvent("NextPhase", self.Kite, phaselength, self)
end

function mod:Kite()
	if db.phase then
		self:Message(fmt(L["kite_phase_message"], boss), "Positive")
		self:Bar(L["next_phase_bar"], phaselength, "Spell_Fire_MoltenBlood")
		self:DelayedMessage(phaselength-10, L["next_phase_message"], "Attention")
	end
	if db.target then
		self:ScheduleRepeatingEvent("BWSupremusToTScan", self.TargetCheck, 1, self)
	end
	self:ScheduleEvent("NextPhase", self.Normal, phaselength, self)
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if self:ValidateEngageSync(sync, rest) and not started then
		started = true
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
		if db.phase then
			self:Normal()
		end
		if db.enrage then
			self:Enrage(600)
		end
	end
end

