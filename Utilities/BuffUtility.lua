require('common')
local BuffUtility = {}

function BuffUtility.Get()

    function BuffUtility:HasBuff(id)
        local playerObject = AshitaCore:GetMemoryManager():GetPlayer()
        local buffs = playerObject:GetBuffs()
        for k,v in pairs(buffs) do
            if(v == id)then
                return true
            end
        end
        return false
    end

    return BuffUtility

end

return BuffUtility.Get()