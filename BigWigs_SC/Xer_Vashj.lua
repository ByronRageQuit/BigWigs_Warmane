----------------------------------
--      Module Declaration      --
----------------------------------
local boss = BB["Lady Vashj"]
local elite = BB["Coilfang Elite"]
local strider = BB["Coilfang Strider"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local mod = BigWigs:NewModule(boss)
local pName = UnitName("player")
local db = nil
local started = nil
local activeGens = nil
local mob_ids = {}
local mc_players = {}

L:RegisterTranslations("enUS", function() return {
	["Tainted Elemental"] = true,
	["Enchanted Elemental"] = true,
	cmd = "Vashj",
	
	--Triggers
	phase2_trigger = "none standing", --use string:find()
	phase3_trigger = "take cover", --use string:find()
	
	chargealert = "Static Charge Alert",
	chargealert_desc = "Alert for player with Static Charge",
	charge_msg = "Static Charge on %s",
	chargeicon = "Static Charge Icon", 
	chargeicon_desc = "Places an icon on the player with Static Charge",
	
	core = "Tainted Core",
	core_desc = "Warn who loots the Tainted Cores.",
	core_msg = "%s has core!",
	coreicon = "Tainted Core Icon",
	coreicon_desc = "Place icon on player with Tainted Core",
	
	mcalert = "Mind Control",
	mcalert_desc = "Alert for players that are mind controled",
	mcalert_msg = "Mind Controled: %s",
	
	genCount = "Generator Count",
	genCount_desc = "Bar that tracks # of active generators.",
	genCount_bar = "Active Generators",
} end)

mod.zonename = BZ["Serpentshrine Cavern"]
mod.enabletrigger = boss
mod.guid = 21212
mod.wipemobs = {elite, strider, L["Tainted Elemental"]}
mod.toggleoptions = {"mcalert", "core", "coreicon", "genCount", -1, "chargealert", "chargeicon", "bosskill"}
mod.revision = 10000

local timer = {
	naga = 50,
	strider = 60,
	elemental = 40,
}
local icon = {
	charge = 38280,
	naga = "INV_Misc_MonsterHead_02",
	strider = "Spell_Nature_AstralRecal",
	elemental = "Spell_Nature_ElementalShields",
	core = 38132,
	gen = 38112,
}
local syncName = {
	charge = "StaticCharge"..mod.revision,
	coreLoot = "CoreLoot"..mod.revision,
	barrier = "BarrierRemove"..mod.revision,
	taint_death = "TaintedDeath"..mod.revision,
}

------------------------------
--      Initialization      --
------------------------------
function mod:OnEnable()
	--Register static charge applied
	self:AddCombatListener("SPELL_AURA_APPLIED", "ChargeAlert", 38280)
	self:AddCombatListener("SPELL_AURA_APPLIED", "CoreUpdate", 38132) --root aura trigger for when someone gets a core
	self:AddCombatListener("SPELL_AURA_REMOVED", "BarrierRemove", 38112) --Barrier remove trigger for icon reset
	self:AddCombatListener("SPELL_AURA_APPLIED", "MC", 38511)
	--Register things for engage/wipe/kill
	self:AddCombatListener("UNIT_DIED", "Deaths")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	--Register sync for engage and timers
	self:RegisterEvent("BigWigs_RecvSync")
	self:Throttle(2, syncName.coreLoot)
	self:Throttle(2, syncName.charge)
	self:Throttle(2, syncName.taint_death)
	
	started = nil
	activeGens = nil
	mob_ids = {}
	mc_players = {}
	db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------
function mod:ChargeAlert(player, spellID)
	self:Sync(syncName.charge, player)
end

function mod:CoreUpdate(player, spellID)
	self:Sync(syncName.coreLoot, player)
end

function mod:BarrierRemove()
	self:Sync(syncName.barrier)
end

function mod:MC(player)
	if not db.mcalert then return end
	mc_players[player] = true
	self:ScheduleEvent("MCAlert", self.MCAlert, 0.3, self)
end

function mod:nagaTimer()
	self:Bar("Naga", timer.naga, icon.naga)
	self:ScheduleEvent("NagaWarn", "BigWigs_Message", timer.naga, "Naga within 5 sec", "Personal")
end
function mod:striderTimer()
	self:Bar("Strider", timer.strider, icon.strider)
	self:ScheduleEvent("StriderWarn", "BigWigs_Message", timer.strider, "Strider within 10 sec", "Personal")
end
function mod:elementalTimer()
	self:Bar("Elemental", timer.elemental, icon.elemental)
	self:ScheduleEvent("EleWarn", "BigWigs_Message", timer.elemental, "Elemental within 5 sec", "Personal")
end

function mod:Deaths(unit)
	if unit == boss then
		self:BossDeath(nil, self.guid)
	-- elseif unit == elite then
		-- ChatFrame1:AddMessage("Naga Death")
	-- elseif unit == strider then
		-- ChatFrame1:AddMessage("Strider Death")
	-- elseif unit == L["Tainted Elemental"] then
		-- ChatFrame1:AddMessage("Tainted Death")
	-- elseif unit == L["Enchanted Elemental"] then
		-- ChatFrame1:AddMessage("Enchanted Death")
	end
end

function mod:MCAlert()
	local temp_msg = ""
	for k in pairs(mc_players) do
		temp_msg = temp_msg..k..", "
	end
	self:Message(L["mcalert_msg"]:format(temp_msg), "Important")
	mc_players = {} --reset the table
end

function mod:addCheck()
	for i = 1, GetNumRaidMembers() do
		local player_target = "raid"..i.."target"
		if UnitName(player_target) == elite then
			local naga_add = UnitGUID(player_target)
			if not mob_ids[naga_add] then
				mob_ids[naga_add] = true
				self:nagaTimer()
				--ChatFrame1:AddMessage("Naga Spawn")
			end
		elseif UnitName(player_target) == strider then
			local strider_add = UnitGUID(player_target)
			if not mob_ids[strider_add] then
				mob_ids[strider_add] = true
				self:striderTimer()
				--ChatFrame1:AddMessage("Strider Spawn")
			end
		elseif UnitName(player_target) == L["Tainted Elemental"] then
			local tainted_add = UnitGUID(player_target)
			if not mob_ids[tainted_add] then
				mob_ids[tainted_add] = true
				self:elementalTimer()
				--ChatFrame1:AddMessage("Tainted Spawn")
			end
		end
	end
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.charge and rest then
		local charged_player = rest
		if charged_player == pName then charged_player = "YOU" end
		if db.chargealert then
			self:IfMessage(L["charge_msg"]:format(charged_player), "Attention", icon.charge)
		end
		if db.chargeicon then
			self:Icon(charged_player)
			self:ScheduleEvent("ClearIcon", "BigWigs_RemoveRaidIcon", 15, self) --Clear the icon after debuff is gone
		end
	elseif sync == syncName.coreLoot and db.core and rest then
		local core_player = rest
		self:IfMessage(L["core_msg"]:format(core_player), "Important", icon.core)
		if db.coreicon then
			self:Icon(core_player)
		end
	elseif sync == syncName.barrier then --When a barrier is removed, remove the icon for the core and update counter
		self:TriggerEvent("BigWigs_RemoveRaidIcon")
		if db.genCount then
			activeGens = activeGens-1 --Reduce count by 1
			self:TriggerEvent("BigWigs_SetCounterBar", self, L["genCount_bar"], activeGens) --set counter
		end
	end
	if self:ValidateEngageSync(sync, rest) and not started then
		started = true
		mob_ids = {}
		mc_players = {}
		self:IfMessage("Vashj Engaged", "Attention")
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg:find(L["phase2_trigger"]) then
		self:IfMessage("PHASE 2", "Important")
		--Set Vars
		activeGens = 4
		--Start counter
		if db.genCount then
			self:TriggerEvent("BigWigs_StartCounterBar", self, L["genCount_bar"], 4) --Start counter
			self:TriggerEvent("BigWigs_SetCounterBar", self, L["genCount_bar"], 4) --Set to 4 so it displaces properly
		end
		--Inital timers
		self:nagaTimer()
		self:striderTimer()
		self:elementalTimer()
		self:ScheduleRepeatingEvent("VashjAddCheck", self.addCheck, 0.3, self) --start add check
	elseif msg:find(L["phase3_trigger"]) then
		self:IfMessage("PHASE 3", "Important")
		--Cancel unneeded events
		self:CancelScheduledEvent("NagaWarn")
		self:CancelScheduledEvent("StriderWarn")
		self:CancelScheduledEvent("EleWarn")
		self:CancelScheduledEvent("VashjAddCheck")
		--Cancel Unneeded bars
		self:TriggerEvent("BigWigs_StopBar", self, "Naga")
		self:TriggerEvent("BigWigs_StopBar", self, "Strider")
		self:TriggerEvent("BigWigs_StopBar", self, "Elemental")
		self:TriggerEvent("BigWigs_StopCounterBar", self, L["genCount_bar"])
	end
end