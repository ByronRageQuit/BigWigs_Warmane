------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Kil'jaeden"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local CheckInteractDistance = CheckInteractDistance

local db = nil
local started = nil
local deaths = 0
local pName = UnitName("player")
local bloomed = {}
local phase = nil
local sinister1 = nil
local sinister2 = nil
local sinister3 = nil

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "KilJaeden",

	bomb = "Darkness",
	bomb_desc = "Warn when Darkness of a Thousand Souls is being cast.",
	bomb_cast = "Incoming Big Bomb!",
	bomb_bar = "Explosion!",
	bomb_nextbar = "~Possible Bomb",
	bomb_warning = "Possible bomb in ~10sec",
	kalec_yell = "I will channel my powers into the orbs! Be ready!",
	kalec_yell2 = "I have empowered another orb! Use it quickly!",
	kalec_yell3 = "Another orb is ready! Make haste!",
	kalec_yell4 = "I have channeled all I can! The power is in your hands!",

	orb = "Shield Orb",
	orb_desc = "Warn when a Shield Orb is shadowbolting.",
	orb_shooting = "Orb Alive - Shooting People!",

	bloom = "Fire Bloom",
	bloom_desc = "Tells you who has been hit by Fire Bloom.",
	bloom_other = "Fire Bloom on %s!",
	bloom_bar = "Fire Blooms",
	bloom_message = "Fire Bloom in 5sec!",

	bloomsay = "Fire Bloom Say",
	bloomsay_desc = "Place a msg in say notifying that you have Fire Bloom",
	bloom_say = "Fire Bloom on "..strupper(pName).."!",

	bloomwhisper = "Fire Bloom Whisper",
	bloomwhisper_desc = "Whisper players with Fire Bloom.",
	bloom_you = "Fire Bloom on YOU!",

	icons = "Bloom Icons",
	icons_desc = "Place random Raid Icons on players with Fire Bloom (requires promoted or higher)",

	shadow = "Shadow Spike",
	shadow_desc = "Raid warn of casting of Shadow Spike.",
	shadow_message = "Shadow Spikes for 28sec!",
	shadow_bar = "Shadow Spikes Expire",
	shadow_warning = "Shadow Spikes done in 5sec!",
	shadow_debuff_bar = "Reduced Healing on %s",

	shadowdebuff = "Disable Shadow Bars",
	shadowdebuff_desc = "Timer bars for players affected by the Shadow Debuff",

	flame = "Flame Dart",
	flame_desc = "Show Flame Dart timer bar.",
	flame_bar = "Flame Dart",
	flame_message = "Flame Dart in 5sec!",

	sinister = "Sinister Reflections",
	sinister_desc = "Warns on Sinister Reflection spawns.",
	sinister_warning = "Sinister Reflections Soon!",
	sinister_message = "Sinister Reflections Up!",

	blueorb = "Dragon Orb",
	blueorb_desc = "Warns on Blue Dragonflight Orb spawns.",
	blueorb_message = "Blue Dragonflight Orb ready!",
	blueorb_warning = "Dragon Orb in ~5sec!",

	shield_up = "Shield is UP!",

	deceiver_dies = "Deceiver #%d Killed",
	["Hand of the Deceiver"] = true,

	phase = "Phase",
	phase_desc = "Warn for phase changes.",
	phase2_message = "Phase 2 - Kil'jaeden incoming!",
	phase3_trigger = "I will not be denied! This world shall fall!",
	phase3_message = "Phase 3 - add Darkness",
	phase4_trigger = "Do not harbor false hope. You cannot win!",
	phase4_message = "Phase 4 - add Meteor",
	phase5_trigger = "Ragh! The powers of the Sunwell turn against me! What have you done? What have you done?!",
	phase5_message = "Phase 5 - Sacrifice of Anveena",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local deceiver = L["Hand of the Deceiver"]
local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Sunwell Plateau"]
mod.enabletrigger = {deceiver, boss}
mod.guid = 25315
mod.toggleoptions = {"phase", -1, "bomb", "orb", "flame", -1, "bloom", "bloomwhisper", "bloomsay", "icons", -1, "sinister", "blueorb", "shadow", "shadowdebuff", "proximity", "bosskill"}
mod.revision = tonumber(("$Revision: 4762 $"):sub(12, -3))
mod.proximityCheck = function( unit ) return CheckInteractDistance( unit, 3 ) end
mod.proximitySilent = true

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Sinister", 45892)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Shield", 45848)
	self:AddCombatListener("SPELL_DAMAGE", "Orb", 45680)
	self:AddCombatListener("SPELL_MISSED", "Orb", 45680)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Bloom", 45641)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Shadow", 45885)
	self:AddCombatListener("SPELL_CAST_START", "ShadowCast", 46680)
	self:AddCombatListener("SPELL_CAST_START", "DarknessCast", 46605)
	
	self:AddCombatListener("UNIT_DIED", "Deaths")

	--self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE") either not happening or not triggering on warmane (Kil'Jaeden/Kil'jaeden difference?)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("UNIT_HEALTH")

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("BigWigs_RecvSync")

	db = self.db.profile
	started = nil
	deaths = 0
	phase = 0
	for i = 1, #bloomed do bloomed[i] = nil end
end

------------------------------
--      Event Handlers      --
------------------------------

--sinister reflections casted
function mod:Sinister()
	self:CancelScheduledEvent("BombWarn")
	self:TriggerEvent("BigWigs_StopBar", self, L["bomb_nextbar"])
	if db.sinister then
		self:IfMessage(L["sinister_message"], "Attention", 45892)
	end
	if db.flame then
		self:Bar(L["flame_bar"], 57, 45737)
		self:DelayedMessage(52, L["flame_message"], "Attention")
	end
	if db.blueorb then
		-- 23018, looks like a Blue Dragonflight Orb :)
		if phase == 2 or phase == 3 then
			self:Bar(L["blueorb"], 37, 23018)
			self:DelayedMessage(32, L["blueorb_warning"], "Urgent")
		elseif phase == 4 then
			self:Bar(L["blueorb"], 45, 23018)
			self:DelayedMessage(40, L["blueorb_warning"], "Urgent")
		end
	end
end

--sheild of the blue information
function mod:Shield()
	self:IfMessage(L["shield_up"], "Urgent", 45848)
	self:Bar(L["shield_up"], 5, 45848)
end

--alerts for shield orbs shooting people
local last = 0
function mod:Orb()
	local time = GetTime()
	if (time - last) > 10 then
		last = time
		if db.orb then
			self:IfMessage(L["orb_shooting"], "Attention", 45680, "Alert")
		end
	end
end

--darkness of 1k souls start cast (originally was a emote check)
function mod:DarknessCast()
	if db.bomb then
		self:Bar(L["bomb_bar"], 8, "Spell_Shadow_BlackPlague")
		self:IfMessage(L["bomb_cast"], "Positive")
		if phase == 3 or phase == 4 then
			self:Bar(L["bomb_nextbar"], 46, "Spell_Shadow_BlackPlague")
			self:ScheduleEvent("BombWarn", "BigWigs_Message", 36, L["bomb_warning"], "Attention")
		elseif phase == 5 then
			self:Bar(L["bomb_nextbar"], 25, "Spell_Shadow_BlackPlague")
			self:DelayedMessage(15, L["bomb_warning"], "Attention")
		end
	end
end

--shadow spike bar
function mod:ShadowCast(_, spellID)
	if db.shadow then
		self:Bar(L["shadow_bar"], 28.7, spellID)
		self:IfMessage(L["shadow_message"], "Attention", spellID)
		self:DelayedMessage(23.7, L["shadow_warning"], "Attention")
	end
end

--handles deaths of hands of deceiver
function mod:Deaths(unit, guid)
	if type(guid) == "string" and tonumber((guid):sub(-12,-7),16) == 25588 then --Hand of the Deceiver
		deaths = deaths + 1
		self:IfMessage(L["deceiver_dies"]:format(deaths), "Positive")
		if deaths == 3 then
			phase = 2
			self:Bar(boss, 10, "Spell_Shadow_Charm")
			self:TriggerEvent("BigWigs_ShowProximity", self)
			if db.phase then
				self:Message(L["phase2_message"], "Important", nil, "Alarm")
			end
		end
		return
	end

	self:BossDeath(nil, guid)
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if (msg == L["kalec_yell"] or msg == L["kalec_yell2"] or msg == L["kalec_yell3"]) then
		if db.bomb then
			self:Bar(L["bomb_nextbar"], 40, "Spell_Shadow_BlackPlague")
			self:DelayedMessage(30, L["bomb_warning"], "Attention")
		end
		if db.blueorb then
			self:IfMessage(L["blueorb_message"], "Attention")
		end
	elseif msg == L["kalec_yell4"] then
		if db.bomb then
			self:Bar(L["bomb_nextbar"], 13, "Spell_Shadow_BlackPlague")
			self:DelayedMessage(3, L["bomb_warning"], "Attention")
		end
		if db.blueorb then
			self:IfMessage(L["blueorb_message"], "Attention")
		end
	elseif msg == L["phase3_trigger"] then
		phase = 3
		if db.phase then
			self:Message(L["phase3_message"], "Important", nil, "Alarm")
		end
	elseif msg == L["phase4_trigger"] then
		phase = 4
		if db.phase then
			self:Message(L["phase4_message"], "Important", nil, "Alarm")
		end
	elseif msg == L["phase5_trigger"] then
		phase = 5
		if db.phase then
			self:Message(L["phase5_message"], "Important", nil, "Alarm")
		end
	end
end

--shows a bar if someone got it by shadow spike (default not shown)
function mod:Shadow(player, spellId)
	if not db.shadowdebuff then
		self:Bar(L["shadow_debuff_bar"]:format(player), 10, spellId) 
	end
end

function mod:Bloom(player)
	if db.bloom then
		tinsert(bloomed, player)
		self:Whisper(player, L["bloom_you"], "bloomwhisper")
		self:ScheduleEvent("BWBloomWarn", self.BloomWarn, 0.4, self)
		if player == pName and db.bloomsay then
			self:LocalMessage(L["bloom_you"], "Personal", 45641, "Long")
			SendChatMessage(L["bloom_say"], "SAY")
		end
	end
end

function mod:BloomWarn()
	local msg = nil
	table.sort(bloomed)

	for i,v in ipairs(bloomed) do
		if not msg then
			msg = v
		else
			msg = msg .. ", " .. v
		end
		if db.icons then
			SetRaidTarget(v, i)
		end
	end

	self:IfMessage(L["bloom_other"]:format(msg), "Important", 45641, "Alert")
	self:Bar(L["bloom_bar"], 20, 45641)
	self:DelayedMessage(15, L["bloom_message"], "Attention")
	for i = 1, #bloomed do bloomed[i] = nil end
end

function mod:UNIT_HEALTH(msg)
	if UnitName(msg) == boss and db.sinister then
		local health = UnitHealth(msg)
		if not sinister1 and health > 86 and health <= 88 then
			sinister1 = true
			self:Message(L["sinister_warning"], "Attention")
		elseif not sinister2 and health > 56 and health <= 58 then
			sinister2 = true
			self:Message(L["sinister_warning"], "Attention")
		elseif not sinister3 and health > 26 and health <= 28 then
			sinister3 = true
			self:Message(L["sinister_warning"], "Attention")
		end
	end
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if self:ValidateEngageSync(sync, rest) and not started then
		started = true
		phase = 1
		sinister1 = nil
		sinister2 = nil
		sinister3 = nil
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
	end
end
