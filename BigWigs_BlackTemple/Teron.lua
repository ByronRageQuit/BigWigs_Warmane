------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Teron Gorefiend"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local pName = UnitName("player")
local db = nil
local beingCrushed = {}

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Teron",

	start_trigger = "Vengeance is mine!",

	shadow = "Shadow of Death",
	shadow_desc = "Tells you who has Shadow of Death.",
	shadow_other = "Shadow: %s!",
	shadow_you = "Shadow of Death on YOU!",

	ghost = "Ghost",
	ghost_desc = "Ghost timers.",
	ghost_bar = "Ghost: %s",

	icon = "Raid Icon",
	icon_desc = "Place a Raid Icon on players with Shadow of Death.",

	crush = "Crushing Shadows",
	crush_desc = "Warn who gets crushing shadows.",
	crush_warn = "Crushed: %s",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Black Temple"]
mod.enabletrigger = boss
mod.guid = 22871
mod.toggleoptions = {"shadow", "ghost", "icon", "crush", "bosskill"}
mod.revision = tonumber(("$Revision: 4718 $"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")

	self:AddCombatListener("SPELL_AURA_APPLIED", "Shadow", 40251)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Crushed", 40243)
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")

	db = self.db.profile
	for k in pairs(beingCrushed) do beingCrushed[k] = nil end
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L["start_trigger"] then
		self:Enrage(300)
	end
end

function mod:Shadow(player, spellID)
	if db.shadow then
		local other = L["shadow_other"]:format(player)
		if player == pName then
			self:LocalMessage(L["shadow_you"], "Personal", spellID, "Long")
			self:WideMessage(other)
		else
			self:IfMessage(other, "Attention", spellID)
		end
		self:ScheduleEvent("BWTeronGhost_"..player, self.Ghost, 55, self, player)
		self:Bar(other, 55, spellID)
		self:Icon(player, "icon")
	end
end

function mod:Ghost(player)
	self:Bar(L["ghost_bar"]:format(player), 60, "Ability_Druid_Dreamstate")
end

function mod:Crushed(player, spellID, _, _, spellName)
	if self.db.profile.crush then
		beingCrushed[player] = true
		self:ScheduleEvent("BWTeronCrushWarn", self.CrushWarn, 0.3, self)
		self:Bar(spellName, 15, spellID)
	end
end

function mod:CrushWarn()
	local msg = nil
	for k in pairs(beingCrushed) do
		if not msg then
			msg = k
		else
			msg = msg .. ", " .. k
		end
	end
	self:IfMessage(L["crush_warn"]:format(msg), "Important", 40243, "Alert")
	for k in pairs(beingCrushed) do beingCrushed[k] = nil end
end

