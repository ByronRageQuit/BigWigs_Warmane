------------------------------
--      Are you local?      --
------------------------------

local lady = BB["Lady Sacrolash"]
local lock = BB["Grand Warlock Alythess"]
local boss = BB["The Eredar Twins"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local db = nil
local wipe = nil
local started = nil
local deaths = 0

local pName = UnitName("player")
local CheckInteractDistance = CheckInteractDistance

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "EredarTwins",

	wipe_bar = "Respawn",

	nova = "Shadow Nova",
	nova_desc = "Warn for Shadow Nova being cast.",
	nova_message = "Shadow Nova on %s",
	nova_bar = "~Nova Cooldown",

	conflag = "Conflagration",
	conflag_desc = "Warn for Conflagration being cast.",
	conflag_message = "Conflag on %s",
	conflag_you = "Conflag on YOU!",
	conflag_bar = "Conflag",
	conflag_cd = "~Next Conflag",

	icon = "Raid Icon",
	icon_desc = "Place a Raid Target Icon on the player that Shadow Nova and Conflagration is being cast on.",

	pyro = "Pyrogenics",
	pyro_desc = "Warn who gains and removes Pyrogenics.",
	pyro_gain = "%s gained Pyrogenics",
	pyro_remove = "%s removed Pyrogenics",

	blow = "Confounding Blow",
	blow_desc = "Show a timer bar for Confounding Blow.",
	blow_bar = "Confounding Blow",

	blades = "Shadow Blades",
	blades_desc = "Show a timer bar for Shadow Blades.",
	blades_bar = "Shadow Blades",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Sunwell Plateau"]
mod.enabletrigger = {lady, lock, boss}
mod.guid = 25166
mod.toggleoptions = {"nova", "conflag", "icon", -1, "pyro", -1, "blow", "blades", "enrage", "bosskill"}
mod.revision = tonumber(("$Revision: 4740 $"):sub(12, -3))
mod.proximityCheck = function( unit ) return CheckInteractDistance( unit, 3 ) end
mod.proximitySilent = true

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_AURA_APPLIED", "PyroGain", 45230)
	self:AddCombatListener("SPELL_STOLEN", "PyroRemove")
	self:AddCombatListener("SPELL_DISPEL", "PyroRemove")
	self:AddCombatListener("SPELL_DAMAGE", "Blow", 45256)
	self:AddCombatListener("SPELL_CAST_START", "Blades", 45248)
	self:AddCombatListener("SPELL_CAST_START", "Conflagration", 45342)
	self:AddCombatListener("UNIT_DIED", "Deaths")

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	--seemed to be missed on warmane
	--self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("BigWigs_RecvSync")

	db = self.db.profile
	if wipe and BigWigs:IsModuleActive(boss) then
		self:Bar(L["wipe_bar"], 5, 44670)
		wipe = nil
	end
	started = nil
	deaths = 0
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:PyroGain(unit, spellID)
	if unit == lock and db.pyro then
		self:Message(L["pyro_gain"]:format(unit), "Positive", nil, nil, nil, spellID)
		self:Bar(L["pyro"], 15, spellID)
	end
end

function mod:PyroRemove(_, _, source, spellID)
	if spellID and spellID == 45230 then
		if db.pyro then
			self:Message(L["pyro_remove"]:format(source), "Positive")
			self:TriggerEvent("BigWigs_StopBar", self, L["pyro"])
		end
	end
end

function mod:Blow()
	if db.blow then
		self:Bar(L["blow_bar"], 20, 45256)
	end
end

function mod:Blades()
	if db.blades then
		self:Bar(L["blades_bar"], 10, 45248)
	end
end

function mod:Conflagration()
	if db.conflag then
		self:Bar(L["conflag_cd"], 31, 45333)
	end
end

function mod:Deaths(_, guid)
	guid = tonumber((guid):sub(-12,-7),16)
	if guid == self.guid or guid == 25165 then
		deaths = deaths + 1
	end
	if deaths == 2 then
		self:BossDeath(nil, self.guid, true)
	end
end

--Don't think this "emote" is getting hit on warmane 
--function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, unit, _, _, player)
--	if ((unit == lady and deaths == 0) or (unit == lock and deaths == 1)) and db.nova then
--		if player == pName then
--			self:LocalMessage(L["nova_message"]:format(player), "Personal", 45329, "Long")
--		else
--			self:Message(L["nova_message"]:format(player), "Urgent", nil, nil, nil, 45329)
--		end
--		self:Bar(L["nova_bar"], 30.5, 45329)
--		self:Icon(player, "icon")
--	elseif ((unit == lock and deaths == 0) or (unit == lady and deaths == 1)) and db.conflag then
--		if player == pName then
--			self:LocalMessage(L["conflag_message"]:format(player), "Personal", 45333, "Long")
--		else
--			self:Message(L["conflag_message"]:format(player), "Attention", nil, nil, nil, 45333)
--			self:Whisper(player, L["conflag_you"])
--		end
--		self:Bar(L["conflag_bar"], 32, 45333)
--		self:Icon(player, "icon")
--	end
--end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if self:ValidateEngageSync(sync, rest) and not started then
		started = true
		wipe = true
		deaths = 0
		self:TriggerEvent("BigWigs_ShowProximity", self)
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
		if db.enrage then
			self:Enrage(315) -- 5:15
		end
		
		if db.conflag then
			self:Bar(L["conflag_cd"], 18, 45333)
		end
	end
end
