------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Akil'zon"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local CheckInteractDistance = CheckInteractDistance
local db = nil

local timer = {
	enrage = 600,
	storm_pull = 50,
	storm_cd = 55,
	storm_duration = 8,
}

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Akil'zon",

	engage_trigger = "I be da predator! You da prey...",
	engage_message = "%s Engaged - Storm in ~55sec!",

	elec = "Electrical Storm",
	elec_desc = "Warn who has Electrical Storm.",
	elec_bar = "~Storm Cooldown",
	elec_message = "Storm on %s!",
	elec_warning = "Storm soon!",

	ping = "Ping",
	ping_desc = "Ping your current location if you are afflicted by Electrical Storm.",
	ping_message = "Storm - Pinging your location!",

	icon = "Raid Icon",
	icon_desc = "Place a Raid Target Icon on the player with Electrical Storm. (requires promoted or higher)",
	
	lightning = "Lightning Count",
	storm_warn = "4th Lightning! Everyone Stack!"
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Zul'Aman"]
mod.enabletrigger = boss
mod.guid = 23574
mod.toggleoptions = {"elec", "ping", "icon", "enrage", "proximity", "bosskill"}
mod.revision = tonumber(("$Revision: 4722 $"):sub(12, -3))
mod.proximityCheck = function( unit ) return CheckInteractDistance( unit, 3 ) end
mod.proximitySilent = true

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	
	self:AddCombatListener("SPELL_AURA_APPLIED", "Storm", 43648)
	self:AddCombatListener("SPELL_AURA_REMOVED", "RemoveIcon", 43648)
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")

	db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:Storm(player, spellID)
	if not db.elec then return end

	local show = L["elec_message"]:format(player)
	self:IfMessage(show, "Attention", spellID)
	self:Bar(show, timer.storm_duration, spellID)
	self:Bar(L["elec_bar"], timer.storm_cd, spellID)
	self:DelayedMessage(timer.storm_cd-timer.storm_duration, L["elec_warning"], "Urgent")
	if UnitIsUnit(player, "player") and db.ping then
		Minimap:PingLocation()
		BigWigs:Print(L["ping_message"])
	end
	self:Icon(player, "icon")
	
	count.lightning = 0
end

function mod:RemoveIcon()
	self:TriggerEvent("BigWigs_RemoveRaidIcon")
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L["engage_trigger"] then
		if db.enrage then
			self:Enrage(timer.enrage, true, true)
		end
		if db.elec then
			self:Message(L["engage_message"]:format(boss), "Positive")
			self:Bar(L["elec_bar"], timer.storm_pull, 43648)
			self:DelayedMessage(timer.storm_pull-3, L["elec_warning"], "Urgent")
		end
		self:TriggerEvent("BigWigs_ShowProximity", self)
		
	end
end

