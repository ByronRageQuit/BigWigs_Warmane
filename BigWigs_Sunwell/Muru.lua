------------------------------
--      Are you local?      --
------------------------------

local entropius = BB["Entropius"]
local boss = BB["M'uru"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local db = nil
local started = nil
local phase = nil
local voidcount = 1
local humanoidcount = 1

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Muru",

	darkness = "Darkness",
	darkness_desc = "Warn who has Darkness.",
	darkness_message = "Darkness: %s",
	darkness_next = "Darkness",
	darkness_soon = "Darkness in 5sec!",

	void = "Void Sentinel",
	void_desc = "Warn when the Void Sentinel spawns.",
	void_next = "Sentinel (%d)",
	void_soon = "Sentinel (%d) in 5sec!",

	humanoid = "Humanoid Adds",
	humanoid_desc = "Warn when the Humanoid Adds spawn.",
	humanoid_next = "Humanoids (%d)",
	humanoid_soon = "Humanoids (%d) in 5sec!",

	fiends = "Dark Fiends",
	fiends_desc = "Warn for Dark Fiends spawning.",
	fiends_message = "Dark Fiends Inc!",

	phase = "Phases",
	phase_desc = "Warn for phase changes.",
	phase2_message = "Phase 2",

	gravity = "Gravity Balls",
	gravity_desc = "Warn for Gravity Balls.",
	gravity_next = "Gravity Ball",
	gravity_soon = "Gravity Ball soon!",
	gravity_spawned = "Gravity Ball summoned!",
	
	darkzone = "Darkness Phase 2 Zone",
	darkzone_desc = "Warn when darkness in p2 spawns.",
	darkzone_message = "Darkness Zone Spawned!",
	darkzone_next = "Next Darkness Zone",
	darkzone_soon = "Darkness Zone Soon",
	
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Sunwell Plateau"]
mod.enabletrigger = boss
mod.guid = 25840
mod.toggleoptions = {"phase", -1, "darkness", "void", "humanoid", "fiends", "gravity", "enrage", "bosskill"}
mod.revision = tonumber(("$Revision: 4742 $"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	--p1
	self:AddCombatListener("SPELL_AURA_APPLIED", "Darkness", 45996)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Fiends", 45934)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Portals", 46177)
	
	--p2
	self:AddCombatListener("SPELL_SUMMON", "GravityBall", 46282)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "DarknessP2", 46269) -- just alert that darkness is spawning
	self:AddCombatListener("SPELL_SUMMON", "DarknessP2Summon", 46268) -- just alert that darkness summoned
	
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("BigWigs_RecvSync")

	db = self.db.profile
	started = nil
	phase = 0
end

------------------------------
--  Event Handlers Phase 2  --
------------------------------

--singularity
function mod:GravityBall()
	if db.gravity then
		--44218 , looks like a Gravity Balls :p
		self:Bar(L["gravity_next"], 15, 44218)
	end
end

--spell cast success (summoning the dark zone)
function mod:DarknessP2()
	if db.darkness then
		self:Bar(L["darkzone_next"], 15, 44218)
	end
end

--darkness / fiends summon
function mod:DarknessP2Summon()
	if db.darkness then
		self:Message(L["darkzone_message"], "Attention")
	end
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:Darkness(unit, spellID)
	if unit == boss and db.darkness then
		self:Bar(L["darkness"], 20, spellID)
		self:IfMessage(L["darkness_message"]:format(unit), "Positive", spellID)
		self:Bar(L["darkness_next"], 45, spellID)
		self:ScheduleEvent("DarknessWarn", "BigWigs_Message", 40, L["darkness_soon"], "Positive")
	end
end

local last = 0
function mod:Fiends()
	if db.fiends then
		if phase == 1 then
			local time = GetTime()
			if (time - last) > 5 then
				last = time
				self:Message(L["fiends_message"], "Important", true, nil, nil, 45934)
			end
		elseif phase == 2 then
			self:Message(L["fiends_message"], "Important", true, nil, nil, 45934)
		end
	end
end

function mod:Portals()
	phase = 2

	self:CancelScheduledEvent("VoidWarn")
	self:CancelScheduledEvent("HumanoidWarn")
	self:CancelScheduledEvent("Void")
	self:CancelScheduledEvent("Humanoid")
	self:CancelScheduledEvent("DarknessWarn")
	self:TriggerEvent("BigWigs_StopBar", self, L["void_next"])
	self:TriggerEvent("BigWigs_StopBar", self, L["humanoid_next"])
	self:TriggerEvent("BigWigs_StopBar", self, L["darkness_next"])
	if db.phase then
		self:Message(L["phase2_message"], "Attention")
		self:Bar(entropius, 10, 46087)
	end
	if db.gravity then
		self:Bar(L["gravity_next"], 22, 44218)
	end
	if db.darkness then
		self:Bar(L["darkzone_next"], 17, 44218)
	end
end


function mod:RepeatVoid()
	self:Bar(L["void_next"]:format(voidcount), 30, 46087)
	self:ScheduleEvent("VoidWarn", "BigWigs_Message", 25, L["void_soon"]:format(voidcount), "Attention")
	voidcount = voidcount + 1
	self:ScheduleEvent("Void", self.RepeatVoid, 30, self)
end

function mod:RepeatHumanoid()
	self:Bar(L["humanoid_next"]:format(humanoidcount), 60, 46087)
	self:ScheduleEvent("HumanoidWarn", "BigWigs_Message", 55, L["humanoid_soon"]:format(humanoidcount), "Urgent")
	humanoidcount = humanoidcount + 1
	self:ScheduleEvent("Humanoid", self.RepeatHumanoid, 60, self)
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if self:ValidateEngageSync(sync, rest) and not started then
		started = true
		phase = 1
		voidcount = 1
		humanoidcount = 1
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
		if db.darkness then
			self:Bar(L["darkness_next"], 45, 45996)
			self:DelayedMessage(40, L["darkness_soon"], "Positive")
		end
		if db.void then
			self:Bar(L["void_next"]:format(voidcount), 30, 46087)
			self:DelayedMessage(25, L["void_soon"]:format(voidcount), "Attention")
			voidcount = voidcount + 1
			self:ScheduleEvent("Void", self.RepeatVoid, 30, self)
		end
		if db.humanoid then
			self:Bar(L["humanoid_next"]:format(humanoidcount), 10, 46087)
			humanoidcount = humanoidcount + 1
			self:ScheduleEvent("Humanoid", self.RepeatHumanoid, 10, self)
		end
		if db.enrage then
			self:Enrage(600)
		end
	end
end
