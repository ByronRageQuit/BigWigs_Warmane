local boss = "Underbog Colossus"
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local started
local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Serpentshrine Cavern"]
mod.enabletrigger = boss
mod.toggleoptions = {"frenzy", "quake", "bosskill"}
mod.otherMenu = "Serpentshrine Cavern"
mod.revision = 10000
local db = nil

local timer = {
	quake = 22,
	frenzy = 18.5,
}
local icon = {
	quake = 38976,
	frenzy = 39031,
}
local syncName = {}

L:RegisterTranslations("enUS", function() return {
	cmd = "Colossus",
	
	quake = "Spore Quake",
	quake_bar = "~Quake Cooldown~",
	quake_desc = "Timer for Spore Quake",
	
	frenzy = "Frenzy",
	frenzy_desc = "Alert for frenzy",
	frenzy_msg = "ENRAGE: Tranq now!",
} end)

function mod:OnEnable()
	self:AddCombatListener("UNIT_DIED", "BossDeath")

    self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("BigWigs_RecvSync")
	
	db = self.db.profile
	started = nil
end

function mod:BigWigs_RecvSync( sync, rest, nick )
        if self:ValidateEngageSync(sync, rest) and not started then
                started = true
				self:AddCombatListener("SPELL_CAST_SUCCESS", "quakeTimer", 38976) --Here due it being trash and.... cant remember why
				self:AddCombatListener("SPELL_AURA_APPLIED", "frenzy", 39031)
                if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
                        self:UnregisterEvent("PLAYER_REGEN_DISABLED")
                end
        end
end

function mod:quakeTimer()
	if not db.quake then return end
	self:Bar(L["quake_bar"], timer.quake, icon.quake)
end
function mod:frenzy()
	if not db.frenzy then return end
	self:Message(L["frenzy_msg"], "Personal")
end