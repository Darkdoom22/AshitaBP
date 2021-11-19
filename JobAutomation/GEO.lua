require('common')
local imgui = require('imgui')
local BuffUtility = require('Utilities\\BuffUtility') 
local ActionUtility = require('Utilities\\ActionUtility')
local CureManagerCore = require('Managers\\CureManagerCore')
local QueueManagerCore = require('Managers\\QueueManagerCore')
local GeoComponent = {}
local AutoTimer = os.clock()
local QueueSpamTimer = os.clock()
local QueueCommandTimer= os.clock()

local buffs = require('ExtraRes\\buffs')
local spells = require('ExtraRes\\spells')

function GeoComponent.Get()
    local IsActing = false
    local TargetIndex = 0
    local TargetId = 0
    local InputDelay = 0
    local GeoActionEnum = {}

    local QueueManager = {}

    --job settings
    local Settings = {
        ["Indi"] = "Indi-Fury",
        ["Geo"] = "Geo-Frailty",
        ["Entrust"] = {
            ["Target"] = "Uwu",
            ["Indi"] = "Indi-Refresh"
        },
    }

    --non geo bubble related spells/jas
    local GeoActionEnum = {
        ["Debuff"] = {
            [1] = "Dia II"
        },
        ["Buff"] = {
            ["Magic"] = {
                ["Self"] = {
                [1] = "Stoneskin",
               -- [2] = "Aquaveil",
                [2] = "Haste",
                },
                ["Other"] = {

                },
            },
            ["Ability"] = {
                ["Self"] = {},
                ["Other"] = {},
            }
        },
    }

    local geoBubbles = T{}
    local indiBubbles = T{}
    local colureBuff = buffs[612]

    for k,v in pairs(spells)do
        if((v.en):contains("Indi"))then
            indiBubbles:insert(v)
        elseif((v.en):contains("Geo"))then
            geoBubbles:insert(v)
        end
    end

    --public setters
    function GeoComponent:SetLastAttemptedSpell(spellName)
        QueueManagerCore:SetLastAttemptedSpell(spellName)
        print(("Attemping spell [%s]"):fmt(spellName))
    end

    function GeoComponent:SetLastAttemptedItem(itemName)
        QueueManagerCore:SetLastAttemptedItem(itemName)
        print(("Attempting item [%s]"):fmt(itemName))
    end

    function GeoComponent:SetLastAttemptedWeaponskill(wsName)
        QueueManagerCore:SetLastAttemptedWeaponskill(wsName)
        print(("Attempting WS [%s]"):fmt(wsName))
    end

    function GeoComponent:SetCompletedAction(completed)
        QueueManagerCore:SetCompletedAction(completed)
        print(("Completed last action [%s]"):fmt(completed))
    end

    function GeoComponent:SetIsActing(isActing)
        IsActing = isActing -- leaving for testing, will be removed
        QueueManagerCore:SetIsActing(isActing)
    end

    function GeoComponent:SetInputDelay(inputDelay)
        InputDelay = inputDelay -- leaving for testing, will be removed
        QueueManagerCore:SetInputDelay(inputDelay)
    end

    function GeoComponent:SetTargetId(targetId)
        TargetId = targetId
    end

    function GeoComponent:SetTargetIndex(targetIndex)
        TargetIndex = targetIndex
    end

    function GeoComponent:SetSettings(settings)
    end

    local function GetBuff(name)
        for i,v in pairs(buffs) do
            if(v.en == name)then
                return v
            end
        end
    end

    local function GetIndiSpell(name)
        for k,v in pairs(indiBubbles) do
            if(v.en == name)then
                return v
            end
        end
    end

    local function GetGeoSpell(name)
        for k,v in pairs(geoBubbles) do
            if(v.en == name)then
                return v
            end
        end
    end

    local function GetSpell(name)
        for k,v in pairs(spells) do
            if(v.en == name)then
                return v
            end
        end
    end

    --debuff delay table
    local lastDebuffTimes = T{}

    function GeoComponent:Auto()
        if(os.clock() - AutoTimer > 0.7 and IsActing == false)then
            --handle self indi buff
            if(not BuffUtility:HasBuff(colureBuff.id))then
                local indi = GetIndiSpell(Settings["Indi"])
                local queueEntry = {}
                queueEntry["ActionName"] = indi.en
                queueEntry["TargetId"] = 0
                queueEntry["ActionType"] = "Magic"
                queueEntry["SelfCast"] = true
                QueueManagerCore:Push(queueEntry)
            end

            local playerObject = GetPlayerEntity()
            --handle geo buff
            if(playerObject.PetTargetIndex == 0 and TargetIndex ~= 0)then
                local geo = GetGeoSpell(Settings["Geo"])
                local queueEntry = {}
                queueEntry["ActionName"] = geo.en
                queueEntry["TargetId"] = GetEntity(TargetIndex).ServerId 
                queueEntry["ActionType"] = "Magic"
                queueEntry["SelfCast"] = false
                QueueManagerCore:Push(queueEntry)
            end

            --handle entrust buff

            --handle debuffs
            for k,v in pairs(GeoActionEnum["Debuff"]) do
                if(TargetIndex ~= 0)then
                    local spell = GetSpell(v)
                    local queueEntry = {}
                    local foundInDebuffTimers = false
                    queueEntry["ActionName"] = spell.en
                    queueEntry["TargetId"] = GetEntity(TargetIndex).ServerId
                    queueEntry["ActionType"] = "Magic"
                    queueEntry["SelfCast"] = false

                    for k,v in pairs(lastDebuffTimes) do
                        if((v["Name"]):contains(spell.en) and os.clock() - v["Time"] > 60)then
                            QueueManagerCore:Push(queueEntry)
                            local lastDebuffTimeEntry = {}
                            lastDebuffTimes[k]["Name"] = spell.en
                            lastDebuffTimes[k]["Time"] = os.clock()
                        elseif((v["Name"]):contains(spell.en))then
                            foundInDebuffTimers = true
                        end
                    end
                    
                    if(foundInDebuffTimers == false)then
                        QueueManagerCore:Push(queueEntry)
                        local lastDebuffTimeEntry = {}
                        lastDebuffTimeEntry["Name"] = spell.en
                        lastDebuffTimeEntry["Time"] = os.clock()
                        lastDebuffTimes:insert(lastDebuffTimeEntry)
                    end               

                end
            end

            --handle self buffs
            for k,v in pairs(GeoActionEnum["Buff"]["Magic"]["Self"]) do
                local buff = GetBuff(v)
                if(not BuffUtility:HasBuff(buff.id))then
                    local spell = GetSpell(v)
                    local buffId = 0
                    local queueEntry = {}
                    queueEntry["ActionName"] = spell.en
                    --two haste ids, figure out a better way to handle
                    if(buff.en == "Haste")then
                        buffId = 33
                    else
                        buffId = buff.id
                    end
                    
                    queueEntry["SelfCast"] = true
                    queueEntry["ActionType"] = "Magic"
                    if(ActionUtility:SpellReady(queueEntry) and not BuffUtility:HasBuff(buffId))then
                        QueueManagerCore:Push(queueEntry)
                    end
                end
            end
            --handle cures
            AutoTimer = os.clock()
        end

    end

    function GeoComponent:ProcessQueue()
        QueueManagerCore:ProcessQueue()
    end

    function GeoComponent:ClearQueue()
        QueueManagerCore:ResetQueue()
    end

    function GeoComponent:DoRender()
        QueueManagerCore:DoRender()
        local playerObject = GetPlayerEntity()
        local shouldShow = playerObject.PetTargetIndex ~= 0
        local petObject = nil
        if(shouldShow)then
            petObject = GetEntity(playerObject.PetTargetIndex)
        end
        imgui.SetNextWindowSize({120,50}, ImGuiCond_Always)
        imgui.SetNextWindowPos({1300, 700})
        if(imgui.Begin("Luopan", shouldShow, ImguiWindowFlags_NoResize))then
            if(shouldShow)then
                imgui.Text(("%s ~ HPP%s"):fmt(petObject.Name, petObject.HPPercent))
            end
        end
    end


    return GeoComponent

end

return GeoComponent.Get()