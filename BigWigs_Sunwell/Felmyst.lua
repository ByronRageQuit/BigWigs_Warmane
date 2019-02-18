------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Felmyst"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local started = nil
local IsItemInRange = IsItemInRange
local UnitName = UnitName
local UnitExists = UnitExists
local db = nil
local count = 1
local gasCount = 0
local fail = {}
local bandages = {
	[21991] = true, -- Heavy Netherweave Bandage
	[21990] = true, -- Netherweave Bandage
	[14530] = true, -- Heavy Runecloth Bandage
	[14529] = true, -- Runecloth Bandage
	[8545] = true, -- Heavy Mageweave Bandage
	[8544] = true, -- Mageweave Bandage
	[6451] = true, -- Heavy Silk Bandage
	[6450] = true, -- Silk Bandage
	[3531] = true, -- Heavy Wool Bandage
	[3530] = true, -- Wool Bandage
	[2581] = true, -- Heavy Linen Bandage
	[1251] = true, -- Linen Bandage
}
local pName = UnitName("player")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Felmyst",

	encaps = "Encapsulate",
	encaps_desc = "Warn who has Encapsulate.",
	encaps_warning = "Encapsulate in ~5sec!",
	encaps_message = "Encapsulate: %s",

	gas = "Gas Nova",
	gas_desc = "Warn for Gas Nova being cast.",
	gas_message = "Casting Gas Nova!",
	gas_bar = "~Gas Nova Cooldown",

	vapor = "Demonic Vapor",
	vapor_desc = "Warn who gets Demonic Vapor.",
	vapor_message = "Vapor: %s",
	vapor_you = "Vapor on You!",

	icon = "Icon",
	icon_desc = "Place a Raid Target Icon on players with Encapsulate or Demonic Vapor. (requires promoted or higher)",

	phase = "Phases",
	phase_desc = "Warn for takeoff and landing phases.",
	airphase_trigger = "I am stronger than ever before!",
	takeoff_bar = "Takeoff",
	takeoff_message = "Taking off in 5sec!",
	landing_bar = "Landing",
	landing_message = "Landing in 10sec!",

	breath = "Deep Breath",
	breath_desc = "Deep Breath warnings.",
	breath_nextbar = "~Breath Cooldown (%d)",
	breath_warn = "Inc Breath (%d)!",

	dispel = "Mass Dispel Results",
	dispel_desc = "If you're a priest, will print in /say who your mass dispel failed on.",
	dispel_fail = "Mass Dispel failed: ",

	warning = "WARNING\n--\nFor Encapsulate scanning to work properly you need to have your Main Tank in the Blizzard Main Tank list!!",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Sunwell Plateau"]
mod.enabletrigger = boss
mod.guid = 25038
mod.toggleoptions = {"phase", "breath", "vapor", "icon", -1, "encaps", "gas", "dispel", "enrage", "proximity", "bosskill"}
mod.revision = tonumber(("$Revision: 4735 $"):sub(12, -3))
mod.proximityCheck = function( unit ) 
	for k, v in pairs( bandages ) do
		if IsItemInRange( k, unit) == 1 then
			return true
		end
	end
	return false
end
mod.proximitySilent = true

------------------------------
--      Initialization      --
------------------------------

local warn = true
function mod:OnEnable()
	started = nil

	self:AddCombatListener("SPELL_CAST_START", "Gas", 45855)
	self:AddCombatListener("SPELL_SUMMON", "Vapor", 45392)
	--self:AddCombatListener("SPELL_AURA_APPLIED", "Encapsulate", 45662) --Maybe one day
	local _, class = UnitClass("player")
	if class == "PRIEST" then
		self:AddCombatListener("SPELL_DISPEL_FAILED", "DispelFail", 32375) --Mass Dispel catcher
	end
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")

	self:RegisterEvent("BigWigs_RecvSync")

	db = self.db.profile
	if warn then
		BigWigs:Print(L["warning"])
		warn = nil
	end
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:Gas(_, spellID)
	gasCount = gasCount + 1

	if db.gas then
		self:IfMessage(L["gas_message"], "Attention", spellID)
		
		if gasCount < 3 then
			self:Bar(L["gas_bar"], 20, spellID)
		else
			self:Bar(L["gas_bar"], 122, spellID)
		end
	end
	
	--first encap is 8s after gas, second encap is 13s after gas
	if db.encaps then
		if gasCount == 1 then
			self:Bar(L["encaps"], 8, 45661)
			self:DelayedMessage(3, L["encaps_warning"], "Attention")
		else 
			if gasCount == 2 then
				self:Bar(L["encaps"], 13, 45661)
				self:DelayedMessage(8, L["encaps_warning"], "Attention")
			end
		end
	end 
	
	if gasCount == 3 then
		gasCount = 0
	end	
end

function mod:Vapor(_, _, source)
	if db.vapor then
		local other = L["vapor_message"]:format(source)
		if source == pName then
			self:LocalMessage(L["vapor_you"], "Personal", nil, "Long")
			self:WideMessage(other)
		else
			self:IfMessage(other, "Urgent", 45402)
		end
		self:Bar(other, 10, 45402)
		self:Icon(source, "icon")
	end
end

function mod:DispelFail(player, _, source)
	if UnitIsUnit(source, "player") and db.dispel then
		fail[player] = true
		self:ScheduleEvent("BWFelmystDispelWarn", self.DispelWarn, 0.3, self)
	end
end

function mod:DispelWarn()
	local msg = nil
	for k in pairs(fail) do
		if not msg then
			msg = k
		else
			msg = msg .. ", " .. k
		end
	end
	SendChatMessage(L["dispel_fail"]..msg, "SAY")
	for k in pairs(fail) do fail[k] = nil end
end

do
	local cachedId = nil
	local lastTarget = nil
	function mod:Encapsulate()
		local found = nil
		if cachedId and UnitExists(cachedId) and UnitName(cachedId) == boss then found = true end
		if not found then
			cachedId = self:Scan()
			if cachedId then found = true end
		end
		if not found then return end
		local target = UnitName(cachedId .. "target")
		if target and target ~= lastTarget and UnitExists(target) then
			if not GetPartyAssignment("maintank", target) then
				local msg = L["encaps_message"]:format(target)
				self:IfMessage(msg, "Important", 45665, "Alert")
				self:Bar(msg, 6, 45665)
				self:Icon(target, "icon")
			end
			lastTarget = target
		end
	end
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if self:ValidateEngageSync(sync, rest) and not started then
		started = true
		for k in pairs(fail) do fail[k] = nil end
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
		self:PhaseOne()
		if db.encaps then
			self:ScheduleRepeatingEvent("BWEncapsScan", self.Encapsulate, 0.5, self)
		end
		self:TriggerEvent("BigWigs_ShowProximity", self)
		if db.enrage then
			self:Enrage(480)
		end
		
		if db.gas then
			self:Bar(L["gas_bar"], 20, spellID)
		end
		
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, unit)
	if db.breath and unit == boss then
		--19879 track dragonkin, looks like a dragon breathing 'deep breath' :)
		self:IfMessage(L["breath_warn"]:format(count), "Attention", 19879)
		self:Bar(L["breath_warn"]:format(count), 4, 19879)
		count = count + 1
		if count < 4 then
			self:Bar(L["breath_nextbar"]:format(count), 17, 19879)
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L["airphase_trigger"] then
		if db.phase then
			self:Bar(L["landing_bar"], 100, 31550)
			self:DelayedMessage(90, L["landing_message"], Attention)
		end
		self:ScheduleEvent("BWFelmystStage", self.PhaseOne, 100, self)
		if db.breath then
			count = 1
			self:Bar(L["breath_nextbar"]:format(count), 47.5, 19879)
		end
		self:CancelScheduledEvent("BWEncapsScan")
	end
end

function mod:PhaseOne()
	if db.phase then
		self:Bar(L["takeoff_bar"], 60, 31550)
		self:DelayedMessage(55, L["takeoff_message"], "Attention")
	end

	if db.encaps then
		--self:Bar(L["encaps"], 30, 45661)
		--self:DelayedMessage(25, L["encaps_warning"], "Attention")
		self:ScheduleRepeatingEvent("BWEncapsScan", self.Encapsulate, 0.5, self)
	end
	
	gasCount = 0
end

