------------------------------
--      Are you local?      --
------------------------------

local boss = BB["The Illidari Council"]
local malande = BB["Lady Malande"]
local gathios = BB["Gathios the Shatterer"]
local zerevor = BB["High Nethermancer Zerevor"]
local veras = BB["Veras Darkshadow"]

local fmt = string.format
local db = nil
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local pName = UnitName("player")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "TheIllidariCouncil",

	engage_trigger1 = "You wish to test me?",
	engage_trigger2 = "Common... such a crude language. Bandal!",
	engage_trigger3 = "I have better things to do...",
	engage_trigger4 = "Flee or die!",

	vanish = "Vanish",
	vanish_desc = "Estimated timers for Vanish.",
	vanish_message = "Veras: Vanished! Back in ~30sec",
	vanish_warning = "Vanish Over - %s back!",
	vanish_bar = "Veras Stealthed",

	immune = "Immunity Warning",
	immune_desc = "Warn when Malande becomes immune to spells or melee attacks.",
	immune_message = "Malande: %s Immune for 15sec!",
	immune_bar = "%s Immune!",

	spell = "Spell",
	melee = "Melee",

	shield = "Reflective Shield",
	shield_desc = "Warn when Malande Gains Reflective Shield.",
	shield_message = "Reflective Shield on Malande!",

	poison = "Deadly Poison",
	poison_desc = "Warn for Deadly Poison on players.",
	poison_other = "%s has Deadly Poison!",
	poison_you = "Deadly Poison on YOU!",

	icon = "Raid Icon",
	icon_desc = "Place a Raid Icon on the player with Deadly Poison.",

	circle = "Circle of Healing",
	circle_desc = "Warn when Malande begins to cast Circle of Healing.",
	circle_trigger = "Lady Malande begins to cast Circle of Healing.",
	circle_message = "Casting Circle of Healing!",
	circle_heal_message = "Healed! - Next in ~20sec",
	circle_fail_message = "%s Interrupted! - Next in ~12sec",
	circle_bar = "~Circle of Healing Cooldown",
	
	flamestrike_bar = "Flamestrike",	
	flamestrike_message = "Flamestrike",
	flamestrike = "Flamestrike",
	flamestrike_desc = "Warn for Flamestrike.",
	
	divinewrath_bar = "Divine Wrath",	
	divinewrath_message = "Divine Wrath",
	divinewrath = "Divine Wrath",	
	divinewrath_desc = "Warn if Divine Wrath is being casted.",	

	divinewrathon = "Divine Wrath on",
	divinewrathon_other = "%s has Divine Wrath",
	divinewrathon_you = "Divine Wrath on YOU",
	divinewrathon_desc = "Warn for Divine Wrath on players.",

	res = "Resistance Aura",
	res_desc = "Warn when Gathios the Shatterer gains Chromatic Resistance Aura.",
	res_message = "Gathios: Resistance for 30 sec!",
	res_bar = "Resistance Aura",

	blizzard = "Blizzard on You",
	blizzard_desc = "Warn when you are in a Blizzard.",
	blizzard_message = "Blizzard on YOU!",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Black Temple"]
mod.enabletrigger = {malande, gathios, zerevor, veras}
mod.guid = 22951
mod.toggleoptions = {"immune", "res", "shield", -1, "vanish", "circle", -1, "poison", "icon", -1, "blizzard", "enrage", "bosskill", -1, "flamestrike", "divinewrath", "divinewrathon"}
mod.revision = tonumber(("$Revision: 4722 $"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_AURA_APPLIED", "Vanish", 41476)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Vanish", 41476)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Vanish", 41479)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Vanish", 41479)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Shield", 41475)
	self:AddCombatListener("SPELL_AURA_APPLIED", "ResAura", 41453)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Poison", 41485)

	self:AddCombatListener("SPELL_AURA_APPLIED", "SpellWarding", 41451)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Protection", 41450)
	self:AddCombatListener("SPELL_CAST_START", "HealingStart", 41455)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Healed", 41455)
	self:AddCombatListener("SPELL_INTERRUPT", "HealingFailed")
	self:AddCombatListener("SPELL_AURA_APPLIED", "Blizzard", 41482)
	self:AddCombatListener("UNIT_DIED", "BossDeath")
	
	self:AddCombatListener("SPELL_CAST_START", "Flamestrike", 41481)
	self:AddCombatListener("SPELL_CAST_START", "DivineWrath", 41472)
	self:AddCombatListener("SPELL_AURA_APPLIED", "DivineWrathOn", 41472)

	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")

	db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:Vanish(_, spellID)
	if db.vanish then
		self:IfMessage(L["vanish_message"], "Urgent", spellID, "Alert")
		self:Bar(L["vanish_bar"], 30, spellID)
		self:DelayedMessage(30, fmt(L["vanish_warning"], veras), "Attention")
	end
end

function mod:Shield(_, spellID)
	if db.shield then
		self:IfMessage(L["shield_message"], "Important", spellID, "Long")
		self:Bar(L["shield_message"], 20, spellID)
	end
end

function mod:ResAura(_, spellID)
	if db.res then
		self:IfMessage(L["res_message"], "Positive", spellID)
		self:Bar(L["res_bar"], 30, spellID)
	end
end

function mod:Poison(player, spellID)
	if db.poison then
		local other = fmt(L["poison_other"], player)
		if player == pName then
			self:LocalMessage(L["poison_you"], "Important", spellID, "Long")
			self:WideMessage(other)
		else
			self:IfMessage(other, "Attention", spellID)
		end
		self:Icon(player, "icon")
	end
end

function mod:SpellWarding(unit, spellID)
	if unit == malande and db.immune then
		self:IfMessage(fmt(L["immune_message"], L["spell"]), "Positive", spellID)
		self:TriggerEvent("BigWigs_StopBar", self, fmt(L["immune_message"], L["melee"]))
		self:Bar(fmt(L["immune_bar"], L["spell"]), 15, spellID)
	end
end

function mod:Protection(unit, spellID)
	if unit == malande and db.immune then
		self:IfMessage(fmt(L["immune_message"], L["melee"]), "Positive", spellID)
		self:TriggerEvent("BigWigs_StopBar", self, fmt(L["immune_message"], L["spell"]))
		self:Bar(fmt(L["immune_bar"], L["melee"]), 15, spellID)
	end
end

function mod:HealingStart(_, spellID, source)
	if source == malande and db.circle then
		self:IfMessage(L["circle_message"], "Attention", spellID, "Info")
		self:Bar(L["circle"], 2.5, spellID)
	end
end

function mod:Healed(_, spellID, source)
	if source == malande  and db.circle then
		self:IfMessage(L["circle_heal_message"], "Urgent", spellID)
		self:Bar(L["circle_bar"], 20, spellID)
	end
end

function mod:HealingFailed(_, _, source, spellID)
	if spellID == 41455 and db.circle then
		self:Message(fmt(L["circle_fail_message"], source), "Urgent")
		self:Bar(L["circle_bar"], 12, spellID)
	end
end

function mod:Blizzard(player)
	if player == pName and db.blizzard then
		self:LocalMessage(L["blizzard_message"], "Personal", 41482, "Alarm")
	end
end

function mod:Flamestrike(_, spellID, source)
	if source == zerevor and db.flamestrike then
		self:IfMessage(L["flamestrike_message"], "Attention", spellID, "Info")
		self:Bar(L["flamestrike_bar"], 1.5, spellID)
	end
end

function mod:DivineWrath(_, spellID, source)
	if source == malande and db.divinewrath then
		self:IfMessage(L["divinewrath_message"], "Attention", spellID, "Info")
		self:Bar(L["divinewrath_bar"], 2, spellID)
	end
end

function mod:DivineWrathOn(player, spellID)
	if db.divinewrathon then
		local other = fmt(L["divinewrathon_other"], player)
		if player == pName then
			self:LocalMessage(L["divinewrathon_you"], "Important", spellID, "Long")
			self:WideMessage(other)
		else
			self:IfMessage(other, "Attention", spellID)
		end
		self:Icon(player, "icon")
	end
end


function mod:CHAT_MSG_MONSTER_YELL(msg)
	if db.enrage and msg:find(L["engage_trigger1"]) then
		--msg:find(L["engage_trigger2"])
		--msg:find(L["engage_trigger3"])
		--msg:find(L["engage_trigger4"])
		self:Enrage(600)
	end
end
