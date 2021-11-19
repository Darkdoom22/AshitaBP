require('common')
local BuffUtility = require('Utilities\\BuffUtility')
local ActionUtility = require('Utilities\\ActionUtility')
local CureManagerCore = {}

local PreferredAgaTargets = {
    "Uwu",
    "Doomvtwo"
}

--["TargetIndex"] = 0 added when returned
local CureActionEnum = {
    ["SingleTarget"] = {
        {
            ["ActionName"] = "Cure",
            ["ActionId"] = 1,
            ["ActionType"] = "Magic",
            ["RecastId"] = 1,
            ["MinHeal"] = 200,
            ["Tier"] = 1,
        },
        {
            ["ActionName"] = "Cure II",
            ["ActionId"] = 2,
            ["ActionType"] = "Magic",
            ["RecastId"] = 2,
            ["MinHeal"] = 300,
            ["Tier"] = 2
        },
        {
            ["ActionName"] = "Cure III",
            ["ActionId"] = 3,
            ["ActionType"] = "Magic",
            ["RecastId"] = 3,
            ["MinHeal"] = 700,
            ["Tier"] = 3,
        },
        {
            ["ActionName"] = "Cure IV",
            ["ActionId"] = 4,
            ["ActionType"] = "Magic",
            ["RecastId"] = 4,
            ["MinHeal"] = 900,
            ["Tier"] = 4,
        },
        {
            ["ActionName"] = "Cure V",
            ["ActionId"] = 5,
            ["ActionType"] = "Magic",
            ["RecastId"] = 5,
            ["MinHeal"] = 1200,
            ["Tier"] = 5,
        },
        {
            ["ActionName"] = "Cure VI",
            ["ActionId"] = 6,
            ["ActionType"] = "Magic",
            ["RecastId"] = 6,
            ["MinHeal"] = 1400,
            ["Tier"] = 6,
        },
    },
    ["MultiTarget"] = {
        {
            ["ActionName"] = "Curaga",
            ["ActionId"] = 7,
            ["ActionType"] = "Magic",
            ["RecastId"] = 7,
            ["MinHeal"] = 100,
            ["Tier"] = 1,
        },
        {
            ["ActionName"] = "Curaga II",
            ["ActionId"] = 8,
            ["ActionType"] = "Magic",
            ["RecastId"] = 8,
            ["MinHeal"] = 200,
            ["Tier"] = 2,
        },
        {
            ["ActionName"] = "Curaga III",
            ["ActionId"] = 9,
            ["ActionType"] = "Magic",
            ["RecastId"] = 9,
            ["MinHeal"] = 475,
            ["Tier"] = 3,
        },
        {
            ["ActionName"] = "Curaga IV",
            ["ActionId"] = 10,
            ["ActionType"] = "Magic",
            ["RecastId"] = 10,
            ["MinHeal"] = 775,
            ["Tier"] = 4,
        },  
        {
            ["ActionName"] = "Curaga V",
            ["ActionId"] = 11,
            ["ActionType"] = "Magic",
            ["RecastId"] = 11,
            ["MinHeal"] = 975,
            ["Tier"] = 5,
        },
    },
}

local PerJobCuresAllowed = {
    ["PLD"] = {
        CureActionEnum["SingleTarget"][1],
        CureActionEnum["SingleTarget"][2],
        CureActionEnum["SingleTarget"][3],
        CureActionEnum["SingleTarget"][4],
    },
    ["GEO"] = {
        CureActionEnum["SingleTarget"][1],
        CureActionEnum["SingleTarget"][2],
        CureActionEnum["SingleTarget"][3],
        CureActionEnum["SingleTarget"][4],
        ["Sub"] = {
            ["WHM"] = {
                CureActionEnum["MultiTarget"][1],
                CureActionEnum["MultiTarget"][2],
                CureActionEnum["MultiTarget"][3],
            }
        }
    }
}

function CureManagerCore.Get()

    local function CalculateMaxHP(current, percent)
        return math.floor(current * (100/percent))
    end

    --need to figure out how I want to handle curaga logic still
    local function GetBestCure(allowedTable, amount, agaAvailable)
        for k,v in pairs(allowedTable) do
            if(v["MinHeal"] >= amount)then
               -- print(v["MinHeal"].." "..amount)
                return v
            end
        end
    end

    local function CheckBestCurePLD()
        local preferTier = 3
        local playerObject = GetPlayerEntity()
        local allowedCures = PerJobCuresAllowed["PLD"]
        local party = AshitaCore:GetMemoryManager():GetParty();
        local curagaAvailable = party:GetMemberSubJob(0) == 3--WHM
        local zone = party:GetMemberZone(0)
        local highestMissingHp = 0
        local highestMissingId = 0
        local memberHp = 0
        local targetId = 0
        local memberMax = 0

        for i = 1, 6 do
            if(party:GetMemberIsActive(i - 1) == 1)then
                memberHp = party:GetMemberHP(i - 1)
                targetId = party:GetMemberServerId(i - 1)
                memberMax = CalculateMaxHP(memberHp, party:GetMemberHPPercent(i - 1))
                if(memberMax-memberHp > highestMissingHp and targetId ~= 0)then
                    highestMissingHp = memberMax-memberHp
                    highestMissingId = targetId
                end
            end
        end

        local bestCure = GetBestCure(allowedCures, highestMissingHp, curagaAvailable)
        if(bestCure and bestCure["Tier"] >= preferTier and highestMissingId ~= 0)then
            bestCure["TargetId"] = highestMissingId
            return bestCure
        end

    end

    local function CheckBestCureGEO()
        local preferTier = 3
        local playerObject = GetPlayerEntity()
        local allowedCures = PerJobCuresAllowed["PLD"]
        local party = AshitaCore:GetMemoryManager():GetParty()
        local zone = party:GetMemberZone(0)
        local curagaAvailable = party:GetMemberSubJob(0) == 3--WHM
        local highestMissingHp = 0
        local highestMissingId = 0
        local memberHp = 0
        local targetId = 0
        local memberMax = 0

        for i = 1, 6 do
            if(party:GetMemberIsActive(i - 1) == 1)then
                memberHp = party:GetMemberHP(i - 1)
                targetId = party:GetMemberServerId(i - 1)
                memberMax = CalculateMaxHP(memberHp, party:GetMemberHPPercent(i - 1))
                if(memberMax-memberHp > highestMissingHp and targetId ~= 0)then
                    highestMissingHp = memberMax-memberHp
                    highestMissingId = targetId
                end
            end
        end

        local bestCure = GetBestCure(allowedCures, highestMissingHp, curagaAvailable)
        if(bestCure and bestCure["Tier"] >= preferTier and highestMissingId ~= 0)then
            bestCure["TargetId"] = highestMissingId
            return bestCure
        end

    end

    CureManagerCore["JobSpecificCureLogicTable"] = {
        ["PLD"] = CheckBestCurePLD,
        ["GEO"] = CheckBestCureGEO,
    }

    function CureManagerCore:GetBestCure(job)
        return CureManagerCore["JobSpecificCureLogicTable"][job]()
    end

    return CureManagerCore

end

return CureManagerCore.Get()