require('common')
local ActionUtility = {}

function ActionUtility.Get()

    function ActionUtility:AbilityReady(action)
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

    function ActionUtility:SpellReady(action)
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

    return ActionUtility

end

return ActionUtility.Get()