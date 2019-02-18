local boss = BB["Shade of Akama"] --Check this
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local started = nil
local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Black Temple"]
mod.enabletrigger = {boss, "Ashtongue Channeler"}
mod.wipemobs = {rogue, elementalist, spiritbinder, defender}
mod.toggleoptions = {"spawns", "phase", "bosskill"}
mod.revision = 1000
local db = nil
local mob_ids = {}

local timer = {
	door_spawn = 35,
	defender_spawn = 20,
	sorcerer_spawn = 60,
	phase2 = 60, --Time for shade to kill akama	
}
local icon = {
	door_spawn = "ability_rogue_shadowstrikes",
	--defender_spawn =,
	--sorcerer_spawn = ,
	--phase2 =,
}
local syncName = {}

local door_adds = {
	rogue = "Ashtongue Rogue",
	elementalist = "Ashtongue Elementalist",
	spiritbinder = "Ashtongue Spiritbinder",
}
local defender = "Ashtongue Defender"

L:RegisterTranslations("enUS", function() return {
	cmd = "Akama",
	
	spawns = "Add Spawn Timers",
	spawns_desc = "Spawn Timers for Adds",
	spawns_defender_bar = "Next Defender",
	spawns_door_bar = "Next Door Pack",
	spawns_sorcerer_bar = "Next Sorcerer",
	
	phase = "Phases",
	phase_desc = "Timer and warning for Phase 2",
	phase_wipe_bar = "Akama Death",
	
} end)

function mod:OnEnable()
	self:AddCombatListener("UNIT_DIED", "BossDeath")

    self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("BigWigs_RecvSync")
	
	db = self.db.profile
	started = nil
	mob_ids = {}
end

function mod:doorTimer()
	self:Bar(L["spawns_door_bar"], timer.door_spawn, icon.door_spawn)
end

function mod:addCheck()
	for i = 1, GetNumRaidMembers() do
		local player_target = "raid"..i.."target"
		for key,name in pairs(door_adds) do
			if UnitName(player_target) == name then
				local door_add = UnitGUID(player_target)
				if not mob_ids[door_add] then
					mob_ids[door_add] = true
					self:doorTimer()
					ChatFrame1:AddMessage("Door Spawn")
				end
			end
		end
	end
end

function mod:BigWigs_RecvSync( sync, rest, nick )
	if self:ValidateEngageSync(sync, rest) and not started then
		started = true
		mob_ids = {}
		self:Bar("DOOR", timer.door_spawn)
		self:Bar("Def", timer.defender_spawn)
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
	end
end