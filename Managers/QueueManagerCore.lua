require('common')
local imgui = require('imgui')
local QueueManagerCore = {}
local BuffUtility = require('Utilities\\BuffUtility')
local ActionUtility = require('Utilities\\ActionUtility')
local QueueProcessTimer = os.clock()

local QueueSettingsDefault = {
    ["ProcessDelay"] = 1,
}

function QueueManagerCore.Get()

    QueueManagerCore["Queue"] = T{}
    LastCompletedSpell = ""
    LastCompletedWeaponskill = ""
    LastCompletedItem = ""
    IsActing = false
    CompletedAction = false
    InputDelay = 0
    QueueClock = os.clock()
    QueueDelay = 1

    --setters
    function QueueManagerCore:SetLastAttemptedSpell(spellName)
        LastCompletedSpell = spellName
    end

    function QueueManagerCore:SetLastAttemptedItem(itemName)
        LastCompletedItem = itemName
    end

    function QueueManagerCore:SetLastAttemptedWeaponskill(wsName)
        LastCompletedWeaponskill = wsName
    end

    function QueueManagerCore:SetCompletedAction(completed)
        CompletedAction = completed
    end

    function QueueManagerCore:SetIsActing(isActing)
        IsActing = isActing
    end

    function QueueManagerCore:SetInputDelay(inputDelay)
        InputDelay = inputDelay
    end

    function QueueManagerCore:QueueContainsEntry(entry)
        for i,v in ipairs(self["Queue"]) do 
            if(v["ActionName"] == entry["ActionName"])then
                return true
            end
        end
        return false
    end

    function QueueManagerCore:DoesQueueHaveCure()
        for k,v in pairs(self["Queue"])do
            if((v["ActionName"]):find("Cure"))then
                return true
            end
        end
        return false
    end

    function QueueManagerCore:AddOrUpgradeCure(entry)
        local upgradedCure = false
        if(self:DoesQueueHaveCure() == true)then
            for k,v in pairs(self["Queue"]) do
                if(v["Tier"] and v["Tier"] < entry["Tier"])then
                    self["Queue"][k] = entry
                    upgradedCure = true
                end
            end
        elseif(not upgradedCure)then
            if(self:QueueContainsEntry(entry) == false)then
                self["Queue"]:insert(1, entry)
            end
        end
    end

    function QueueManagerCore:HasSpell(name)
        local resManager = AshitaCore:GetResourceManager()
        local mmRecast = AshitaCore:GetMemoryManager():GetRecast()  
    end

    function QueueManagerCore:SpellReady(entry)
        local resManager = AshitaCore:GetResourceManager()
        local mmRecast = AshitaCore:GetMemoryManager():GetRecast()

        for i = 0, 1024 do
            local spellTimer = mmRecast:GetSpellTimer(i)
            local spell = resManager:GetSpellById(i)

            if(spell and spell.Name[1] == entry["ActionName"])then
                if(spellTimer == 0)then
                  --  print(("Spell Ready %s"):fmt(spell.Name[1]))
                    return true
                end
            end
        end
        return false
    end

    function QueueManagerCore:AbilityReady(entry)
        local resManager = AshitaCore:GetResourceManager()
        local mmRecast = AshitaCore:GetMemoryManager():GetRecast()

        for i = 0, 31 do
            local abilityTimerId = mmRecast:GetAbilityTimerId(i)
            local abilityTimer = mmRecast:GetAbilityTimer(i)
            local ability = resManager:GetAbilityByTimerId(abilityTimerId)

            if(ability and ability.Name[1] == entry["ActionName"])then
                if(abilityTimer == 0)then
                    return true
                end
            end
        end
        return false
    end

    local function HasBuff(id)
        local playerObject = AshitaCore:GetMemoryManager():GetPlayer()
        local buffs = playerObject:GetBuffs()
        for k,v in pairs(buffs) do
            if(v.id == id)then
                return true
            end
        end
        return false
    end

    --QueueEntry
        -- ActionName
        -- TargetId
        -- ActionType
        -- Attempts
        -- InputString
        -- Priority
        -- SelfCast

    local function QueuePushMagic(entry)
        if(QueueManagerCore:SpellReady(entry) and QueueManagerCore:QueueContainsEntry(entry) == false)then
            --prep our entry fields
            entry["Attempts"] = 0

            local playerObject = GetPlayerEntity()

            if(entry["SelfCast"])then
                entry["TargetId"] = playerObject.ServerId
            end
            
            spellStr = ('/ma "%s" %s'):fmt(entry["ActionName"], entry["TargetId"])
            entry["InputString"] = spellStr
            --if its a cure, check if theres one already in the queue and upgrade it 
            --if not, inserts normally.
            if((entry["ActionName"]):find("Cure"))then
              --  print('adding cure')
                QueueManagerCore:AddOrUpgradeCure(entry)
            else --otherwise insert normally
                if(QueueManagerCore:SpellReady(entry))then
                    QueueManagerCore["Queue"]:insert(entry)
                end
            end
        end
    end

    local function QueuePushAbility(entry)
        if(QueueManagerCore:AbilityReady(entry) and QueueManagerCore:QueueContainsEntry(entry) == false)then
            entry["Attempts"] = 0

            local playerObject = GetPlayerEntity()
            if(entry["SelfCast"])then
                entry["TargetId"] = playerObject.ServerId
            end

            jaStr = ('/ja "%s" %s'):fmt(entry["ActionName"], entry["TargetId"])
            entry["InputString"] = jaStr

            QueueManagerCore["Queue"]:insert(entry)
        end
    end
        
    local QueuePushFuncTable = {
        ["Magic"] = function(entry)
            QueuePushMagic(entry)
        end,
        ["Ability"] = function(entry)
            QueuePushAbility(entry)
        end,
    }

    function QueueManagerCore:Push(entry)
        if(not self:QueueContainsEntry(entry))then
            QueuePushFuncTable[entry["ActionType"]](entry)
        end
    end

    function QueueManagerCore:ResetQueue()
        self["Queue"] = T{}
    end

    function QueueManagerCore:ProcessQueue()
        if(os.clock() - QueueClock > QueueDelay)then
            if(#self["Queue"] > 0)then
                if(self["Queue"][1]["Attempts"] > 5)then
                    self["Queue"]:remove(1)
                end
                if(not IsActing and os.clock() - InputDelay > 0)then
                    if(self["Queue"][1])then
                        self["Queue"][1]["Attempts"] = self["Queue"][1]["Attempts"] + 1  
                    --print(self["Queue"][1]["Attempts"])      
                        AshitaCore:GetChatManager():QueueCommand(0, self["Queue"][1]["InputString"])
                    end
                    elseif(CompletedAction)then
                    self["Queue"]:remove(1)
                    CompletedAction = false
                end
            end
            QueueClock = os.clock()
        end
    end

    function QueueManagerCore:DoRender()
        local shouldShow = #self["Queue"] > 0
        imgui.SetNextWindowSize({400, 300}, ImGuiCond_Always)
        imgui.SetNextWindowPos({1300, 300})
        if(imgui.Begin("Queue", shouldShow, ImguiWindowFlags_NoResize))then
            imgui.Indent(120)
            imgui.Text("Current Entries")
            imgui.Unindent(120)
            local str = ""
            for i,v in ipairs(self["Queue"])do
                str = ("Pos: [%s] -- [%s] [%s] [%s] Try: [%s]\n"):fmt(i, v["ActionType"], v["ActionName"], v["TargetId"], v["Attempts"])
                imgui.Text(str)
            end
        end
    end

    return QueueManagerCore

end

return QueueManagerCore.Get()
