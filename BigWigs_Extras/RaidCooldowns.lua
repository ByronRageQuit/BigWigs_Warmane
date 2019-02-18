assert(BigWigs, "BigWigs not found!")

----------------------------
--      Localization      --
----------------------------

local L = AceLibrary("AceLocale-2.2"):new("BigWigsRaidCDs")

L:RegisterTranslations("enUS", function() return {
	["Options for the Raid Cooldown module."] = true,
	["Shield Wall"] = true,
	["Shows the duration of Shield Wall on a Warrior."] = true,
	["Last Stand"] = true,
	["Shows the duration of Last Stand on a Warrior."] = true,
	["AOE Taunt"] = true,
	["Shows the duration of the AOE Taunt from a Warrior or Druid."] = true,
	["Bloodlust"] = true,
	["Show duration and group of Bloodlust"] = true,
	bloodlust_msg = "Bloodlust: %s",
} end)

L:RegisterTranslations("deDE", function() return {
	["Options for the Raid Cooldown module."] = "Optionen für das Raid Cooldown Modul",
	["Shield Wall"] = "Schildwall",
	["Shows the duration of Shield Wall on a Warrior."] = "Zeigt die Dauer von Schildwall auf einem Krieger an.",
	["Last Stand"] = "Letztes Gefecht",
	["Shows the duration of Last Stand on a Warrior."] = "Zeigt die Dauer von Letztes Gefecht auf einem Krieger an.",
	["AOE Taunt"] = "Massen-Spott",
	["Shows the duration of the AOE Taunt from a Warrior or Druid."] = "Zeigt die Dauer von einem Massen-Spott von einem Krieger oder Druiden an.",
	["Bloodlust"] = true,
	["Show duration and group of Bloodlust"] = true,
	bloodlust_msg = "Bloodlust: %s",
} end)

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule("RaidCDs")
mod.revision = tonumber(("$Revision: 1 $"):sub(12, -3))
mod.defaultDB = {
	ShieldWall = true,
	LastStand = true,
	AOETaunt = true,
	Bloodlust = true,
}
mod.external = true
mod.consoleCmd = "RaidCDs"
mod.consoleOptions = {
	type = "group",
	name = "RaidCDs",
	desc = L["Options for the Raid Cooldown module."],
	args = {
		["ShieldWall"] = {
			type = "toggle",
			name = L["Shield Wall"],
			desc = L["Shows the duration of Shield Wall on a Warrior."],
			get = function() return mod.db.profile.ShieldWall end,
			set = function(v)
				mod.db.profile.ShieldWall = v
			end,
		},
		["LastStand"] = {
			type = "toggle",
			name = L["Last Stand"],
			desc = L["Shows the duration of Last Stand on a Warrior."],
			get = function() return mod.db.profile.LastStand end,
			set = function(v)
				mod.db.profile.LastStand = v
			end,
		},
		["AOETaunt"] = {
			type = "toggle",
			name = L["AOE Taunt"],
			desc = L["Shows the duration of the AOE Taunt from a Warrior or Druid."],
			get = function() return mod.db.profile.AOETaunt end,
			set = function(v)
				mod.db.profile.AOETaunt = v
			end,
		},
		["Bloodlust"] = {
			type = "toggle",
			name = L["Bloodlust"],
			desc = L["Show duration and group of Bloodlust"],
			get = function () return mod.db.profile.Bloodlust end,
			set = function(v)
				mod.db.profile.Bloodlust = v
			end,
		},
	}
}

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_CAST_SUCCESS", "ShieldWall", 871)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "LastStand", 12975)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "AOETaunt", 1161)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "AOETaunt", 5209)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Bloodlust", 2825)
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:ShieldWall(_, spellID, source)
	if self.db.profile.ShieldWall then
		self:Bar(L["Shield Wall"].." - "..(source or "Unknown"), 15, spellID, true, 0, 0, 1)
	end
end

function mod:LastStand(_, spellID, source)
	if self.db.profile.ShieldWall then
		self:Bar(L["Last Stand"].." - "..(source or "Unknown"), 20, spellID, true, 0, 0, 1)
	end
end

function mod:AOETaunt(_, spellID, source)
	if self.db.profile.ShieldWall then
		self:Bar(L["AOE Taunt"].." - "..(source or "Unknown"), 6, spellID, true, 1, 0, 0)
	end
end

function mod:Bloodlust(_, spellID, source)
	if self.db.profile.Bloodlust then
		local player_subgroup = self:getSubgroup(source)
		self:Bar("Bloodlust: Group "..(player_subgroup or "Unknown"), 40, spellID)
	end
end

function mod:getSubgroup(name)
	for i = 1, GetNumRaidMembers() do
		local player_name, _, player_subgroup = GetRaidRosterInfo(i)
		if player_name == name then
			return player_subgroup
		end
	end
end
