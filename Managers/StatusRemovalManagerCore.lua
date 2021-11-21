require('common')
local math = require('math')
local StatusRemovalManagerCore = {}
local BuffsRes = require('ExtraRes\\buffs')

function StatusRemovalManagerCore.Get()

    local PartyBuffs = T{}
    local PriorityMap = T{
        ["Petrification"] = 10,
        ["Silence"] = 9,
        ["Sleep"] = 8,
        ["Paralyze"] = 7,
        
    }

    function StatusRemovalManagerCore:ParsePartyBuffs(packetData)
        local party = AshitaCore:GetMemoryManager():GetParty()
        PartyBuffs = T{}
        
        for i = 1, 5 do
            PartyBuffs:insert({StatusIds=T{}, MemberId=struct.unpack('I', packetData, ((i-1)*48+5))})
            for j = 1, 32 do
                local currentBuff = packetData:byte((i-1)*48+5+16+j-1) + 256 * (math.floor( packetData:byte((i-1)*48+5+8 + math.floor((j-1)/4)) / 4^((j-1)%4) )%4)
                if (currentBuff > 0 and currentBuff ~= 255) then
                    PartyBuffs[i]["StatusIds"]:insert(currentBuff)
                end
            end
        end
        --[[for k,v in ipairs(PartyBuffs) do
            print(v.MemberId)
            local member = GetEntityByServerId(v.MemberId)
            for kk,vv in pairs(v.StatusIds) do
                if BuffsRes[vv] then
                    local buff = BuffsRes[vv]
                    print(("%s has %s, id %s"):fmt(member.Name, buff.en, vv))
                end
            end
        end]]--
    end

    function StatusRemovalManagerCore:GetBestRemoval()

    end

    return StatusRemovalManagerCore
end

return StatusRemovalManagerCore.Get()