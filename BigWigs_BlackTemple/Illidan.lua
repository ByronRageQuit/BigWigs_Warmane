------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Illidan Stormrage"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local pName = UnitName("player")
local db = nil
local bCount = 0
local p2Announced = nil
local p2 = nil
local p4Announced = nil
local flamesDead = 0
local flamed = { }
local fmt = string.format
local CheckInteractDistance = CheckInteractDistance

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Illidan",

	berserk_trigger = "You are not prepared!",

	parasite = "Parasitic Shadowfiend",
	parasite_desc = "Warn who has Parasitic Shadowfiend.",
	parasite_you = "You have a Parasite!",
	parasite_other = "%s has a Parasite!",

	icon = "Raid Icon",
	icon_desc = "Place a Raid Icon on the player with Parasitic Shadowfiend or Dark Barrage.",

	barrage = "Dark Barrage",
	barrage_desc = "Warn who has Dark Barrage.",
	barrage_message = "%s is being Barraged!",
	barrage_warn = "Barrage Soon!",
	barrage_warn_bar = "~Next Barrage",
	barrage_bar = "Barrage: %s",

	eyeblast = "Eye Blast",
	eyeblast_desc = "Warn when Eye Blast is cast.",
	eyeblast_trigger = "Stare into the eyes of the Betrayer!",
	eyeblast_message = "Eye Blast!",

	shear = "Shear",
	shear_desc = "Warn about Shear on players.",
	shear_message = "Shear on %s!",
	shear_bar = "Shear: %s",

	flame = "Agonizing Flames",
	flame_desc = "Warn who has Agonizing Flames.",
	flame_message = "%s has Agonizing Flames!",

	demons = "Shadow Demons",
	demons_desc = "Warn when Illidan is summoning Shadow Demons.",
	demons_message = "Shadow Demons!",
	demons_warn = "Demons Soon!",

	phase = "Phases",
	phase_desc = "Warns when Illidan goes into different stages.",
	phase2_soon_message = "Phase 2 soon!",
	phase2_message = "Phase 2 - Blades of Azzinoth!",
	phase3_message = "Phase 3!",
	demon_phase_trigger = "Behold the power... of the demon within!",
	demon_phase_message = "Demon Form!",
	demon_bar = "Next Normal Phase",
	demon_warning = "Demon over in ~ 5 sec!",
	normal_bar = "~Possible Demon Phase",
	normal_warning = "Possible Demon Phase in ~5 sec!",
	phase4_trigger = "Is this it, mortals? Is this all the fury you can muster?",
	phase4_soon_message = "Phase 4 soon!",
	phase4_message = "Phase 4 - Maiev Incoming!",

	burst = "Flame Burst",
	burst_desc = "Warns when Illidan will use Flame Burst",
	burst_message = "Flame Burst!",
	burst_cooldown_bar = "Flame Burst cooldown",
	burst_cooldown_warn = "Flame Burst soon!",
	burst_warn = "Flame Burst in 5sec!",

	enrage_trigger = "Feel the hatred of ten thousand years!",
	enrage_message = "Enraged!",

	["Flame of Azzinoth"] = true,

	--very first yell to start engage timer
	illi_start = "Akama. Your duplicity is hardly surprising. I should have slaughtered you and your malformed brethren long ago.",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Black Temple"]
mod.enabletrigger = boss
mod.guid = 22917
mod.toggleoptions = {"berserk", "phase", "parasite", "shear", "eyeblast", "barrage", "flame", "demons", "burst", "enrage", "proximity", "bosskill"}
mod.wipemobs = {L["Flame of Azzinoth"]}
mod.revision = tonumber(("$Revision: 4724 $"):sub(12, -3))
mod.proximityCheck = function( unit ) return CheckInteractDistance( unit, 3 ) end
mod.proximitySilent = true

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_CAST_SUCCESS", "FlameBurst", 41126)
	self:AddCombatListener("SPELL_SUMMON", "Phase2", 39855)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Parasite", 41914, 41917)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Barrage", 40585)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Shear", 41032)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Flame", 40932)
	self:AddCombatListener("SPELL_CAST_START", "Demons", 41117)
	self:AddCombatListener("UNIT_DIED", "Deaths")

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")

	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("UNIT_HEALTH")
	self:Throttle(50, "FlameBurst") --Only want this sync to trigger on the first burst of each demon phase

	db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:FlameBurst(_, spellID)
	if db.burst then
		bCount = bCount + 1
		self:IfMessage(L["burst_message"], "Important", spellID, "Alert")
		if bCount < 3 then -- He'll only do three times before transforming again
			self:Bar(L["burst"], 20, spellID)
			self:DelayedMessage(15, L["burst_warn"], "Positive")
		end
		self:Sync("FlameBurst")
	end
end

function mod:Phase2()
	if p2 then return end
	p2 = true

	self:TriggerEvent("BigWigs_RemoveRaidIcon")
	flamesDead = 0
	if db.barrage then
		self:Bar(L["barrage_warn_bar"], 80, "Spell_Shadow_PainSpike")
		--self:DelayedMessage(77, L["barrage_warn"], "Important")
	end
	if db.phase then
		self:Message(L["phase2_message"], "Important", nil, "Alarm")
	end
end

function mod:Parasite(player, spellID)
	if db.parasite then
		local other = fmt(L["parasite_other"], player)
		if player == pName then
			self:LocalMessage(L["parasite_you"], "Personal", spellID, "Long")
			self:WideMessage(other)
		else
			self:IfMessage(other, "Attention", spellID)
		end
		self:Icon(player, "icon")
		self:Bar(other, 10, spellID)
	end
end

function mod:Barrage(player, spellID)
	if db.barrage then
		self:IfMessage(fmt(L["barrage_message"], player), "Important", spellID, "Alert")
		self:Bar(fmt(L["barrage_bar"], player), 10, spellID)
		self:Icon(player, "icon")

		self:Bar(L["barrage_warn_bar"], 41, spellID)
		--self:ScheduleEvent("BarrageWarn", "BigWigs_Message", 47, L["barrage_warn"], "Important")
	end
end

function mod:Shear(player, spellID)
	if db.shear then
		self:IfMessage(fmt(L["shear_message"], player), "Important", spellID, "Alert")
		self:Bar(fmt(L["shear_bar"], player), 7, spellID)
	end
end

function mod:Flame(player)
	if db.flame then
		flamed[player] = true
		self:ScheduleEvent("FlameCheck", self.FlameWarn, 0.5, self)
	end
end

function mod:Demons()
	if db.demons then
		self:IfMessage(L["demons_message"], "Important", 41117, "Alert")
	end
end

function mod:Normal()
	self:Bar(L["normal_bar"], 70, "Spell_Shadow_Metamorphosis")
	self:ScheduleEvent("BWIlliNormalSoon", "BigWigs_Message", 65, L["normal_warning"], "Attention")
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L["eyeblast_trigger"] and db.eyeblast then
		self:Message(L["eyeblast_message"], "Important", nil, "Alert")
	elseif msg == L["demon_phase_trigger"] then
		bCount = 0
		if db.demons then
			self:Bar(L["demons"], 30, "Spell_Shadow_SoulLeech_3")
			self:DelayedMessage(25, L["demons_warn"], "Positive")
		end
		if db.phase then
			self:Message(L["demon_phase_message"], "Important", nil, "Alarm")
			self:Bar(L["demon_bar"], 65, "Spell_Shadow_Metamorphosis")
			self:ScheduleEvent("BWIlliDemonOver", "BigWigs_Message", 60, L["demon_warning"], "Attention")
			self:ScheduleEvent("BWIlliNormal", self.Normal, 60, self)
		end
		if db.burst then
			self:DelayedMessage(15, L["burst_cooldown_warn"], "Positive")
			self:Bar(L["burst_cooldown_bar"], 20, "Spell_Fire_BlueRainOfFire")
		end
	elseif msg == L["phase4_trigger"] then
		if db.phase then
			self:Message(L["phase4_message"], "Important", nil, "Alarm")
		end
		self:CancelScheduledEvent("BWIlliNormal")
		self:CancelScheduledEvent("BWIlliDemonOver")
		self:CancelScheduledEvent("BWIlliNormalSoon")
		self:TriggerEvent("BigWigs_StopBar", self, L["demon_bar"])
		self:TriggerEvent("BigWigs_StopBar", self, L["normal_bar"])
		if db.phase then
			self:Bar(L["normal_bar"], 90, "Spell_Shadow_Metamorphosis")
			self:ScheduleEvent("BWIlliNormalSoon", "BigWigs_Message", 85, L["normal_warning"], "Attention")
		end
	elseif db.enrage and msg == L["enrage_trigger"] then
		self:Message(L["enrage_message"], "Important", nil, "Alert")
	elseif db.berserk and msg == L["berserk_trigger"] then
		self:Enrage(1200, true)
	elseif msg == L["illi_start"] then
		self:Bar(boss, 37, "Spell_Shadow_Charm")
		p2 = nil
	end
end

function mod:UNIT_HEALTH(msg)
	if UnitName(msg) == boss and db.phase then
		local hp = UnitHealth(msg)
		if hp > 65 and hp < 70 and not p2Announced then
			self:Message(L["phase2_soon_message"], "Attention")
			p2Announced = true
			for k in pairs(flamed) do flamed[k] = nil end
		elseif hp > 70 and p2Announced then
			p2Announced = nil
			p2 = nil
		elseif hp > 30 and hp < 35 and not p4Announced then
			self:Message(L["phase4_soon_message"], "Attention")
			p4Announced = true
			p2 = nil
		elseif hp > 35 and p4Announced then
			p4Announced = nil
		end
	end
end

function mod:Deaths(unit)
	if unit == L["Flame of Azzinoth"] then
		flamesDead = flamesDead + 1
		if flamesDead == 2 then
			if db.phase then
				self:Message(L["phase3_message"], "Important", nil, "Alarm")
				self:Bar(L["normal_bar"], 82, "Spell_Shadow_Metamorphosis")
				self:ScheduleEvent("BWIlliNormalSoon", "BigWigs_Message", 70, L["normal_warning"], "Attention")
			end
			self:CancelScheduledEvent("BarrageWarn")
			self:TriggerEvent("BigWigs_StopBar", self, L["barrage_warn_bar"])
			self:TriggerEvent("BigWigs_ShowProximity", self) -- Proximity Warning
		end
	elseif unit == boss then
		self:BossDeath(nil, self.guid)
	end
end

function mod:FlameWarn()
	local msg = nil
	for k in pairs(flamed) do
		if not msg then
			msg = k
		else
			msg = msg .. ", " .. k
		end
	end
	self:IfMessage(fmt(L["flame_message"], msg), "Important", 40932, "Alert")
	for k in pairs(flamed) do flamed[k] = nil end
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if sync == "FlameBurst" then
		self:Bar(L["demons"], 15, "Spell_Shadow_SoulLeech_3")
	end
end

