require('common')
local BuffUtility = require('Utilities\\BuffUtility') 
local ActionUtility = require('Utilities\\ActionUtility')
local CureManagerCore = require('Managers\\CureManagerCore')
local QueueManagerCore = require('Managers\\QueueManagerCore')
local PldComponent = {}
local AutoTimer = os.clock()
local QueueSpamTimer = os.clock()
local QueueCommandTimer = os.clock()

function PldComponent.Get()
    local IsActing = false
    local TargetIndex = 0
    local InputDelay = 0
    local PldActionEnum = {
        ["Buff"] = {
            {
                ["ActionName"] = "Phalanx",
                ["ActionType"] = "Magic",
                ["ActionId"] = 106,
                ["BuffId"] = 116,
                ["RecastId"] = 106,
                ["SelfCast"] = true,
            },
            {
                ["ActionName"] = "Crusade",
                ["ActionType"] = "Magic",
                ["ActionId"] = 476,
                ["BuffId"] = 289,
                ["RecastId"] = 476,
                ["SelfCast"] = true,
            },
            {
               ["ActionName"] = "Cocoon",
               ["ActionType"] = "Magic",
               ["ActionId"] = 547,
               ["BuffId"] = 93,
               ["RecastId"] = 547,
               ["SelfCast"] = true,
            },
            {
                ["ActionName"] = "Reprisal",
                ["ActionType"] = "Magic",
                ["ActionId"] = 97,
                ["BuffId"] = 403,
                ["RecastId"] = 97,
                ["SelfCast"] = true,
            },
            {
                ["ActionName"] = "Enlight II",
                ["ActionType"] = "Magic",
                ["ActionId"] = 855,
                ["BuffId"] = 274,
                ["RecastId"] = 855,
                ["SelfCast"] = true,
            },
        },
        ["Ability"] = {
            {
                ["ActionName"] = "Shield Bash",
                ["ActionId"] = 46,
                ["ActionType"] = "Ability",
                ["RecastId"] = 73,
                ["SelfCast"] = false,
            },
            {
                ["ActionName"] = "Majesty",
                ["ActionId"] = 394,
                ["ActionType"] = "Ability",
                ["BuffId"] = 621,
                ["RecastId"] = 150,
                ["SelfCast"] = true,
            },
            {
                ["ActionName"] = "Chivalry",
                ["ActionId"] = 158,
                ["ActionType"] = "Ability",
                ["RecastId"] = 79,
                ["SelfCast"] = true,
            },
            {
                ["ActionName"] = "Palisade",
                ["ActionId"] = 278,
                ["ActionType"] = "Ability",
                ["RecastId"] = 42,
                ["SelfCast"] = true,
            },
            {
                ["ActionName"] = "Rampart",
                ["ActionId"] = 92,
                ["ActionType"] = "Ability",
                ["RecastId"] = 77,
                ["SelfCast"] = true,
            },
            {
                ["ActionName"] = "Sentinel",
                ["ActionId"] = 48,
                ["ActionType"] = "Ability",
                ["RecastId"] = 75,
                ["SelfCast"] = true,
            },
        },
        ["Enmity"] = {
            {
                ["ActionName"] = "Sheep Song",
                ["ActionType"] = "Magic",
                ["ActionId"] = 584,
                ["BuffId"] = 0,
                ["RecastId"] = 584,
                ["SelfCast"] = false,
            },
            {
                ["ActionName"] = "Jettatura",
                ["ActionType"] = "Magic",
                ["ActionId"] = 575,
                ["BuffId"] = 0,
                ["RecastId"] = 575,
                ["SelfCast"] = false,
            },
            {
                ["ActionName"] = "Geist Wall",
                ["ActionType"] = "Magic",
                ["ActionId"] = 605,
                ["BuffId"] = 0,
                ["RecastId"] = 605,
                ["SelfCast"] = false,
            },
            {
                ["ActionName"] = "Blank Gaze",
                ["ActionType"] = "Magic",
                ["ActionId"] = 592,
                ["BuffId"] = 0,
                ["RecastId"] = 592,
                ["SelfCast"] = false,
            },
            {
                ["ActionName"] = "Soporific",
                ["ActionType"] = "Magic",
                ["ActionId"] = 598,
                ["BuffId"] = 0,
                ["RecastId"] = 598,
                ["SelfCast"] = false,
            },
            {
                ["ActionName"] = "Flash",
                ["ActionType"] = "Magic",
                ["ActionId"] = 112,
                ["BuffId"] = 0,
                ["RecastId"] = 112,
                ["SelfCast"] = false,
            }
        },
    }
    
    local QueueManager = {}

    local PldCommandQueue = {
        ["Queue"] = T{},
    }
    
    local Settings = {

    }

    --QueueEntry
    -- ActionName 
    -- Target
    -- ActionType
    -- Attempts
    -- Input string
    -- Priority

    local function QueueContainsEntry(entry)
        for k,v in ipairs(PldCommandQueue["Queue"]) do
            if(v["ActionName"] == entry["ActionName"])then
                return true
            end
        end
       -- print("Queue does not have entry "..entry["ActionName"])
        return false
    end

    local function DoesQueueHaveCure()
        --print('here')
        for k,v in ipairs(PldCommandQueue["Queue"])do
           -- print(v["ActionName"])
            if((v["ActionName"]):find("Cure"))then
               -- print("Queue has a cure")
                return true
            end
        end
        return false
    end

    local function AddOrUpgradeCure(entry)
        --print('here 2')
        if(DoesQueueHaveCure() == true)then
            for i,v in ipairs(PldCommandQueue["Queue"])do
                if(v["Tier"] and v["Tier"] < entry["Tier"])then
                    v = entry
                end
            end
        else
            if(DoesQueueHaveCure() == false)then
                if(not QueueContainsEntry(entry))then
                    PldCommandQueue["Queue"]:insert(1, entry)
                end
            end
        end
    end

    function PldComponent:SetLastAttemptedSpell(spellName)
        QueueManagerCore:SetLastAttemptedSpell(spellName)
        print(("Attemping spell [%s]"):fmt(spellName))
    end

    function PldComponent:SetLastAttemptedItem(itemName)
        QueueManagerCore:SetLastAttemptedItem(itemName)
        print(("Attempting item [%s]"):fmt(itemName))
    end

    function PldComponent:SetLastAttemptedWeaponskill(wsName)
        QueueManagerCore:SetLastAttemptedWeaponskill(wsName)
        print(("Attempting WS [%s]"):fmt(wsName))
    end

    function PldComponent:SetCompletedAction(completed)
        QueueManagerCore:SetCompletedAction(completed)
        print(("Completed last action [%s]"):fmt(completed))
    end

    function PldComponent:SetIsActing(isActing)
        IsActing = isActing -- leaving for testing, will be removed
        QueueManagerCore:SetIsActing(isActing)
    end

    function PldComponent:SetInputDelay(inputDelay)
        InputDelay = inputDelay -- leaving for testing, will be removed
        QueueManagerCore:SetInputDelay(inputDelay)
    end

    function PldCommandQueue:Push(action, isSpell, isAbility, isSelfCast, targetId)
    
        local recasts = AshitaCore:GetMemoryManager():GetRecast()
        local resManager = AshitaCore:GetResourceManager()
        local queueEntry = {
            ["ActionName"] = "",
            ["Target"] = "",
            ["ActionType"] = "",
            ["Attempts"] = 0,
            ["InputString"] = "",
            ["Priority"] = 0,
        }
        if(isSpell)then

            local spellRes = resManager:GetSpellById(action["ActionId"])
            local spellStr = ""
            if(isSelfCast)then

                local playerObject = GetPlayerEntity()
                spellStr = ('/ma "%s" %s'):fmt(spellRes.Name[1], playerObject.Name)
                queueEntry["ActionName"] = spellRes.Name[1]
                queueEntry["Target"] = playerObject.Name
                queueEntry["ActionType"] = "Magic"
                queueEntry["Attempts"] = 0
                queueEntry["InputString"] = spellStr
                if(not QueueContainsEntry(queueEntry))then

                    if((queueEntry["ActionName"]):find("Cure") and not DoesQueueHaveCure())then
                        --self["Queue"]:insert(1, queueEntry)
                        AddOrUpgradeCure(queueEntry)
                    else
                    --print(''..spellStr)
                        self["Queue"]:insert(queueEntry)
                    end
                    --self["Queue"]:insert(spellStr);
                  --  self["Queue"]:sort()
                end

            elseif(isSelfCast == false)then

                spellStr = ('/ma "%s" %s'):fmt(spellRes.Name[1], targetId)
                queueEntry["ActionName"] = spellRes.Name[1]
                queueEntry["Target"] = targetId
                queueEntry["ActionType"] = "Magic"
                queueEntry["Attempts"] = 0
                queueEntry["InputString"] = spellStr
                if(not QueueContainsEntry(queueEntry))then
                    
                    if((queueEntry["ActionName"]):find("Cure") and not DoesQueueHaveCure())then
                        --self["Queue"]:insert(1, queueEntry)
                        AddOrUpgradeCure(queueEntry)
                    else
                        self["Queue"]:insert(queueEntry)
                    end
                   -- self["Queue"]:sort()
                end

            end

        elseif(isAbility)then

            local abilityRes = resManager:GetAbilityById(action["ActionId"])

            local abilityStr = ""

            if(isSelfCast)then

                local playerObject = GetPlayerEntity()
                if(playerObject)then

                    abilityStr = ('/ja "%s" %s'):fmt(action["ActionName"], playerObject.Name)
                
                    queueEntry["ActionName"] = action["ActionName"]
                    queueEntry["Target"] = playerObject.Name
                    queueEntry["ActionType"] = "JA"
                    queueEntry["Attempts"] = 0
                    queueEntry["InputString"] = abilityStr
                    if(not QueueContainsEntry(queueEntry))then
                        self["Queue"]:insert(queueEntry)
                      --  self["Queue"]:sort()
                    end

                end

            elseif(not isSelfCast)then
                
                abilityStr = ('/ja "%s" %s'):fmt(action["ActionName"], targetId)

                queueEntry["ActionName"] = action["ActionName"]
                queueEntry["Target"] = targetId
                queueEntry["ActionType"] = "JA"
                queueEntry["Attempts"] = 0
                queueEntry["InputString"] = abilityStr
                if(not QueueContainsEntry(queueEntry))then
                    self["Queue"]:insert(queueEntry)
                   -- self["Queue"]:sort()
                end

            end

        end

    end

    function PldCommandQueue:Pop()
        if(#self["Queue"] > 0)then
            local element = self["Queue"]:remove(1)
            return element
        end
        return nil
    end

    local function AbilityReady(action)
        local resManager = AshitaCore:GetResourceManager()
        local mmRecast  = AshitaCore:GetMemoryManager():GetRecast();

        for i = 0, 31 do
            local abilityTimerId = mmRecast:GetAbilityTimerId(i)
            local abilityTimer = mmRecast:GetAbilityTimer(i)
            local ability = resManager:GetAbilityByTimerId(abilityTimerId)
            
            if(ability and ability.Name[1] == action["ActionName"])then
                if(abilityTimer == 0)then
                    return true
                end
            end
        end
        return false
    end

    local function SpellReady(action)
        local resManager = AshitaCore:GetResourceManager()
        local mmRecast = AshitaCore:GetMemoryManager():GetRecast()

        for i = 0, 1024 do
            local spellTimerId = i
            local spellTimer = mmRecast:GetSpellTimer(i)
            local spell = resManager:GetSpellById(spellTimerId)

            if(spell and spell.Name[1] == action["ActionName"])then
                if(spellTimer == 0)then
                    return true
                end
            end
        end
        return false
    end
    --move this out 
    local function HasBuff(id)
        local playerObject = AshitaCore:GetMemoryManager():GetPlayer()
        local buffs = playerObject:GetBuffs()
        for k,v in pairs(buffs) do
            if(v == id)then
                return true
            end
        end
        return false
    end

    function PldComponent:Auto()

        local resManager = AshitaCore:GetResourceManager()
        local recasts = AshitaCore:GetMemoryManager():GetRecast()
        local playerObject = AshitaCore:GetMemoryManager():GetPlayer()
        local buffs = playerObject:GetBuffs()

        --queue commands to game
        if(os.clock() - AutoTimer > 0.7)then

            if(os.clock() - QueueCommandTimer > 0.5)then

                if(#PldCommandQueue["Queue"] > 0 and IsActing == false and os.clock() - InputDelay > 0)then

                    local cmd = PldCommandQueue:Pop()

                    if(cmd)then
                       -- AshitaCore:GetChatManager():QueueCommand(0, cmd["InputString"])

                    end

                end

                QueueCommandTimer = os.clock()

            end

            if(os.clock() - QueueSpamTimer > 1 and IsActing == false)then
                --only check cures if we have decent mp
                if(AshitaCore:GetMemoryManager():GetParty():GetMemberMPPercent(0) > 50)then
                    local bestCure = CureManagerCore:GetBestCure("PLD")
                    
                    if(bestCure)then
                       -- print(bestCure["ActionName"])
                        if(SpellReady(bestCure))then
                          --  print("Should be pushing cure")
                           QueueManagerCore:Push(bestCure) 
                       -- PldCommandQueue:Push(bestCure, true, false, false, bestCure["TargetId"])
                        end
                    end
                end


                --update job abilities in queue
                for k,v in pairs(PldActionEnum["Ability"]) do

                    if(AbilityReady(v))then

                        if(v["SelfCast"])then
                            if(not HasBuff(v["BuffId"]))then
                                --PldCommandQueue:Push(v, false, true, true, 0)
                                QueueManagerCore:Push(v)
                            end
                        else        
                            local target = GetEntity(TargetIndex)
                            
                            if(target and target.HPPercent > 0 and target.WarpPointer ~= 0)then
                                v["TargetId"] = target.ServerId
                                QueueManagerCore:Push(v)
                               -- PldCommandQueue:Push(v, false, true, false, target.ServerId)
                            end
                            
                        end

                    end

                end

                --update self buff spells in queue
                for k,v in pairs(PldActionEnum["Buff"]) do
                    
                    if(SpellReady(v))then

                        if(not HasBuff(v["BuffId"]))then
                                                
                            if(not QueueContainsEntry(v))then
                                PldActionEnum["Buff"][k]["ActionType"] = "Magic" 
                                QueueManagerCore:Push(v)
                                PldCommandQueue:Push(v, true, false, true, 0)
                            end

                        end

                    end

                end

                --update hate spells in queue
                for k,v in pairs(PldActionEnum["Enmity"]) do

                    if(SpellReady(v))then

                        local target = GetEntity(TargetIndex)   
 
                        if(target and target.HPPercent > 0 and target.WarpPointer ~= 0 and not QueueContainsEntry(v))then
                           -- PldCommandQueue:Push(v, true, false, false, target.ServerId)
                           v["TargetId"] = target.ServerId
                           QueueManagerCore:Push(v)
                        end

                    end

                end

                QueueSpamTimer = os.clock()

            end

            AutoTimer = os.clock()

        end

    end

    function PldComponent:SetTargetIndex(targetIndex)
        TargetIndex = targetIndex
        print("Updating target indx..")
    end

    function PldComponent:UpdateActingCallback(acting)
        IsActing = acting
    end

    function PldComponent:UpdateSettingsCallback(setting, value)

    end

    function PldComponent:ClearQueue()
        PldCommandQueue["Queue"] = T{}
        QueueManagerCore:ResetQueue()
       -- print("Clearing queue")
    end

    function PldComponent:GetQueueAsStr()  
        str = ""
        for i,v in ipairs(PldCommandQueue["Queue"]) do
            str = str..v["ActionType"].." Act: "..v["ActionName"].." Tgt: "..v["Target"].." Atmpt: "..v["Attempts"].."\n"
        end
        return str
    end

    function PldComponent:GetQueue()
        return PldCommandQueue["Queue"]
    end

    function PldComponent:RenderSettingsWindow()

    end

    function PldComponent:ProcessQueue()
        QueueManagerCore:ProcessQueue()
    end

    function PldComponent:DoRender()
        QueueManagerCore:DoRender()
    end

    return PldComponent

end

return PldComponent.Get()
