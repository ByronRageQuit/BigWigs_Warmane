local boss = "Bonechewer Backbreaker"
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local started
local db = nil

L:RegisterTranslations("enUS", function() return {
	cmd = "Chewer",
	shock = "Shadow Shock",
	shock_desc = "test",
	bolt = "Shadow Bolt",
	bolt_desc = "Test",
} end)

----------------------------------
--      Module Declaration      --
----------------------------------
local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Terokkar Forest"]
mod.otherMenu = "Outland"
mod.enabletrigger = boss
mod.toggleoptions = {"bolt", "shock", "enrage", "bosskill"}
mod.revision = 10000
local syncName = {
	buffet = "Buffet"..mod.revision,
}

function mod:OnEnable()
	self:AddCombatListener("SPELL_CAST_SUCCESS", "shock", 16583)
	self:AddCombatListener("SPELL_CAST_START", "bolt", 9613)
	self:AddCombatListener("UNIT_DIED", "BossDeath")

    self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("BigWigs_RecvSync")
	
	db = self.db.profile
	started = nil
end

function mod:shock()
	self:Bar("Shock", 10, 16583)
end
function mod:bolt()
	self:Bar("Bolt", 10, 9613)
end

function mod:BigWigs_RecvSync( sync, rest, nick )
        if self:ValidateEngageSync(sync, rest) and not started then
                started = true
                if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
                        self:UnregisterEvent("PLAYER_REGEN_DISABLED")
                end
				if db.enrage then
					self:Enrage(60)
				end
		end
end