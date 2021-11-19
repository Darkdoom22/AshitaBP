require('common')
local AutomationBase = require('JobAutomation\\AutomationBase')
local BuffUtility = require('Utilities\\BuffUtility') 
local ActionUtility = require('Utilities\\ActionUtility')
local CureManagerCore = require('Managers\\CureManagerCore')
local QueueManagerCore = require('Managers\\QueueManagerCore')

local PldComponent = {}
setmetatable(PldComponent, {__index = AutomationBase})

function PldComponent.Get()
    --desired actions to automate
    --get the ids from resources
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
    
    
    local Settings = {

    }

    function PldComponent:Auto()

        local resManager = AshitaCore:GetResourceManager()
        local recasts = AshitaCore:GetMemoryManager():GetRecast()
        local playerObject = AshitaCore:GetMemoryManager():GetPlayer()
        local buffs = playerObject:GetBuffs()

        if(os.clock() - self["AutomationTimer"] > 0.7)then

            if(self["Vars"]["IsActing"] == false)then

                --handle cures
                if(AshitaCore:GetMemoryManager():GetParty():GetMemberMPPercent(0) > 50)then
                    local bestCure = CureManagerCore:GetBestCure("PLD")
                    if(bestCure)then
                        if(ActionUtility:SpellReady(bestCure))then
                           self["QueueManager"]:Push(bestCure) 
                        end
                    end
                end

                --handle job abilities
                for k,v in pairs(PldActionEnum["Ability"]) do
                    if(ActionUtility:AbilityReady(v))then
                        if(v["SelfCast"])then
                            if(BuffUtility:HasBuff(v["BuffId"]) == false)then
                                self["QueueManager"]:Push(v)
                            end
                        else        
                            local target = GetEntity(self["Vars"]["TargetIndex"])
                            if(target and target.HPPercent > 0 and target.WarpPointer ~= 0)then
                                v["TargetId"] = target.ServerId
                                self["QueueManager"]:Push(v)
                            end
                        end
                    end
                end

                ---handle buffs
                for k,v in pairs(PldActionEnum["Buff"]) do
                    if(ActionUtility:SpellReady(v))then
                        if(BuffUtility:HasBuff(v["BuffId"]) == false)then
                            PldActionEnum["Buff"][k]["ActionType"] = "Magic" 
                            self["QueueManager"]:Push(v)
                        end
                    end
                end

                --handle enmity
                for k,v in pairs(PldActionEnum["Enmity"]) do
                    if(ActionUtility:SpellReady(v))then
                        local target = GetEntity(self["Vars"]["TargetIndex"])   
                        if(target and target.HPPercent > 0 and target.WarpPointer ~= 0)then
                           -- PldCommandQueue:Push(v, true, false, false, target.ServerId)
                           v["TargetId"] = target.ServerId
                           self["QueueManager"]:Push(v)
                        end
                    end
                end

            end

            self["AutomationTimer"] = os.clock()

        end

    end

    function PldComponent:DoRender()
        QueueManagerCore:DoRender()
    end

    return PldComponent

end

return PldComponent.Get()
