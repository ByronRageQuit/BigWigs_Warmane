local boss = "Vicious Teromoth"
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local started
local db = nil

L:RegisterTranslations("enUS", function() return {
	cmd = "Teromoth",
	
	buffet = "Wing Buffet",
	buffet_desc = "Timer for Wing Buffet",
	
	dust = "Dazzling Dust",
	dust_msg = "Dazzling Dust on %s",
	dust_desc = "Warning for Dazzling Dust",
} end)

----------------------------------
--      Module Declaration      --
----------------------------------
local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Terokkar Forest"]
mod.otherMenu = "Outland"
mod.enabletrigger = boss
mod.toggleoptions = {"buffet", "dust", "enrage", "bosskill"}
mod.revision = 10000
local syncName = {
	buffet = "Buffet"..mod.revision,
	dust = "Dust"..mod.revision,
}
local buffetCount = 0
local buffetTimer = {5,6,7}

function mod:OnEnable()
	self:AddCombatListener("UNIT_DIED", "BossDeath")
	self:AddCombatListener("SPELL_CAST_START", "buffet", 32914) --buffet
	self:AddCombatListener("SPELL_AURA_APPLIED", "dust", 32913)

    self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("BigWigs_RecvSync")
	self:Throttle(2, syncName.buffet)
	self:TriggerEvent("BigWigs_StartCounterBar", self, "TEST", 10)
	self:TriggerEvent("BigWigs_SetCounterBar", self, "TEST", 10)
	--self:TriggerEvent("BigWigs_SetCounterBar", self, "TEST", 5)
	--self:ScheduleEvent("thing", "BigWigs_PauseCounterBar", 0.1, self, "TEST")
	--self:ScheduleEvent("thing", "BigWigs_StopCounterBar", 3, self, "TEST")
	--self:ScheduleEvent("EVENT NAME", Function/Event to run, time, arg1, arg2, arg3, ...) the args are what are passed to the function/event
	--self:ScheduleEvent("ClearIcon", "BigWigs_RemoveRaidIcon", 15, self)
	
	db = self.db.profile
	started = nil
	buffetCount = 0
end

function mod:stopCounter(name)
	self:TriggerEvent("BigWigs_StopCounterBar", self, name)
end
function mod:startCounter(name, maxTime, icon)
	self:TriggerEvent("BigWigs_StartCounterBar", self, name, maxTime, icon)
end
function mod:setCounter(name, count)
	self:TriggerEvent("BigWigs_SetCounterBar", self, name, count)
end
function mod:buffet()
	self:Sync(syncName.buffet)
end
	
function mod:dust(player, spellID)
	self:Sync(syncName.dust, player)
end

function mod:repeattest()
	ChatFrame1:AddMessage("TEST")
end

function mod:BigWigs_RecvSync( sync, rest, nick )
		if sync == syncName.buffet and db.buffet then
			buffetCount = buffetCount + 1
			self:Bar(L["buffet"], buffetTimer[buffetCount], 32914)
		elseif sync == syncName.dust and db.dust and rest then
			local dust_player = rest
			local msg = L["dust_msg"]:format(dust_player)
			self:IfMessage(msg, "Attention", 32913)
		end
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