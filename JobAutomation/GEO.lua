require('common')
local imgui = require('imgui')
local AutomationBase = require('JobAutomation\\AutomationBase')
local BuffUtility = require('Utilities\\BuffUtility') 
local ActionUtility = require('Utilities\\ActionUtility')
local CureManagerCore = require('Managers\\CureManagerCore')

local GeoComponent = {}
setmetatable(GeoComponent, {__index = AutomationBase})

local buffs = require('ExtraRes\\buffs')
local spells = require('ExtraRes\\spells')

function GeoComponent.Get()

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
    
    --job settings
    local Settings = {
        ["Indi"] = "Indi-Fury",
        ["Geo"] = "Geo-Frailty",
        ["Entrust"] = {
            ["Target"] = "Uwu",
            ["Indi"] = "Indi-Refresh"
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

    local function GetEntityByName(name)
        for i = 0, 2303 do
            local entity = GetEntity(i)
            if(entity and entity.Name == name)then
                return entity
            end
        end
        return nil
    end

    --debuff delay table
    local lastDebuffTimes = T{}

    function GeoComponent:Auto()
        if(os.clock() - self["AutomationTimer"] > 0.9 and self["Vars"]["IsActing"] == false)then
            --handle self indi buff
            if(BuffUtility:HasBuff(colureBuff.id) == false)then -- need to check for active bubble buff too and make sure its what we want
                local indi = GetIndiSpell(Settings["Indi"])
                local buff = GetBuff(Settings["Indi"])
                local queueEntry = {}
                queueEntry["ActionName"] = indi.en
                queueEntry["TargetId"] = 0
                queueEntry["ActionType"] = "Magic"
                queueEntry["SelfCast"] = true
                if(buff and BuffUtility:HasBuff(buff.id) == false)then
                    self["QueueManager"]:Push(queueEntry)
                end
            end

            local playerObject = GetPlayerEntity()
            --handle geo buff
            if(playerObject.PetTargetIndex == 0 and self["Vars"]["TargetIndex"] ~= 0)then
                local geo = GetGeoSpell(Settings["Geo"])
                local queueEntry = {}
                queueEntry["ActionName"] = geo.en
                queueEntry["TargetId"] = GetEntity(self["Vars"]["TargetIndex"]).ServerId 
                queueEntry["ActionType"] = "Magic"
                queueEntry["SelfCast"] = false
                self["QueueManager"]:Push(queueEntry)
            end

            --handle entrust buff
            local entrust = GetBuff("Entrust")
            local bubble = GetIndiSpell(Settings["Entrust"]["Indi"])
            if(ActionUtility:AbilityReady({ActionName = "Entrust"}))then
                if(BuffUtility:HasBuff(entrust.id) == false)then
                    local queueEntry = {}
                    local indi = GetIndiSpell(Settings["Entrust"]["Indi"])
                    queueEntry["ActionName"] = "Entrust"
                    queueEntry["ActionType"] = "Ability"
                    queueEntry["TargetId"] = 0
                    queueEntry["SelfCast"] = true
                    self["QueueManager"]:Push(queueEntry)
                end
            end
            if(BuffUtility:HasBuff(entrust.id) == true and bubble and BuffUtility:HasBuff(bubble.id) == false)then
                print('here')
                local queueEntry = {}
                local indi = GetIndiSpell(Settings["Entrust"]["Indi"])
                queueEntry["ActionName"] = indi.en
                queueEntry["ActionType"] = "Magic"
                queueEntry["SelfCast"] = false
                local entrustTarget = GetEntityByName(Settings["Entrust"]["Target"])
                if(entrustTarget)then
                    queueEntry["TargetId"] = entrustTarget.ServerId
                    self["QueueManager"]:Push(queueEntry)
                end
            end

            --handle debuffs
            for k,v in pairs(GeoActionEnum["Debuff"]) do
                if(self["Vars"]["TargetIndex"] ~= 0)then
                    local spell = GetSpell(v)
                    local queueEntry = {}
                    local foundInDebuffTimers = false
                    queueEntry["ActionName"] = spell.en
                    queueEntry["TargetId"] = GetEntity(self["Vars"]["TargetIndex"]).ServerId
                    queueEntry["ActionType"] = "Magic"
                    queueEntry["SelfCast"] = false

                    for k,v in pairs(lastDebuffTimes) do
                        if((v["Name"]):contains(spell.en) and os.clock() - v["Time"] > 60)then
                            self["QueueManager"]:Push(queueEntry)
                            local lastDebuffTimeEntry = {}
                            lastDebuffTimes[k]["Name"] = spell.en
                            lastDebuffTimes[k]["Time"] = os.clock()
                        elseif((v["Name"]):contains(spell.en))then
                            foundInDebuffTimers = true
                        end
                    end
                    
                    if(foundInDebuffTimers == false)then
                        self["QueueManager"]:Push(queueEntry)
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
                local buffId = 0
                --several haste ids, figure out a better way to handle
                if(buff.en == "Haste")then
                    buffId = 33
                else
                    buffId = buff.id
                end
                if(BuffUtility:HasBuff(buffId) == false)then
                    local spell = GetSpell(v)

                    local queueEntry = {}
                    queueEntry["ActionName"] = spell.en
                    queueEntry["SelfCast"] = true
                    queueEntry["ActionType"] = "Magic"
                    if(ActionUtility:SpellReady(queueEntry) == true)then
                        self["QueueManager"]:Push(queueEntry)
                    end
                end
            end

            --handle persistent party member buffs (this needs a whole system to track)

            --handle cures
            if(self["Vars"]["IsActing"] == false)then
                --make preferred mp a setting
                if(AshitaCore:GetMemoryManager():GetParty():GetMemberMPPercent(0) > 50)then
                    local bestCure = CureManagerCore:GetBestCure("GEO")
                    if(bestCure)then
                        if(ActionUtility:SpellReady(bestCure))then
                            self["QueueManager"]:Push(bestCure)
                        end
                    end
                end
            end

            --handle status effect removal

            --handle item usage
            
            self["AutomationTimer"] = os.clock()
        end

    end

    --override for job window
    function GeoComponent:DoRender()
        self["QueueManager"]:DoRender()
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