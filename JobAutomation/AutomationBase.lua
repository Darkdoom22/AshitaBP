local imgui = require('imgui')
local AutomationBase = {}
AutomationBase.__index = AutomationBase

AutomationBase["BuffRes"] = require('ExtraRes\\buffs')
AutomationBase["SpellRes"] = require('ExtraRes\\spells')
AutomationBase["WsRes"] = require('ExtraRes\\weapon_skills')
AutomationBase["AutomationTimer"] = os.clock()
AutomationBase["QueueSpamTimer"] = os.clock()
AutomationBase["QueueManager"] = require('Managers\\QueueManagerCore')

function AutomationBase.Get()
   
    --shared variables
    AutomationBase["Vars"] = {
        ["IsActing"] = false,
        ["TargetIndex"] = 0,
        ["TargetId"] = 0,
        ["InputDelay"] = 0,
    }

    --shared settings
    AutomationBase["Settings"] = {
        ["AutoBuff"] = true,
        ["AutoAbility"] = true,
        ["AutoCure"] = true,
        ["AutoStatusRemove"] = true,
        ["AutoEnmity"] = true,
    }

    --imgui formatted
    local editorVars = {
        ["AutoBuff"] = {true},
        ["AutoAbility"] = {true},
        ["AutoCure"] = {true},
        ["AutoStatusRemove"] = {true},
        ["AutoEnmity"] = {true},
    }

    --shared setters
    function AutomationBase:SetLastAttemptedSpell(spellName)
        self["QueueManager"]:SetLastAttemptedSpell(spellName)
    end

    function AutomationBase:SetLastAttemptedItem(itemName)
        self["QueueManager"]:SetLastAttemptedItem(itemName)
    end

    function AutomationBase:SetLastAttemptedWeaponskill(wsName)
        self["QueueManager"]:SetLastAttemptedWeaponskill(wsName)
    end

    function AutomationBase:SetCompletedAction(completed)
        self["QueueManager"]:SetCompletedAction(completed)
    end

    function AutomationBase:SetIsActing(isActing)
        self["Vars"]["IsActing"] = isActing
        self["QueueManager"]:SetIsActing(isActing)
    end

    function AutomationBase:SetInputDelay(inputDelay)
        self["Vars"]["InputDelay"] = inputDelay
        self["QueueManager"]:SetInputDelay(inputDelay)
    end

    function AutomationBase:SetTargetId(targetId)
        self["Vars"]["TargetId"] = targetId
    end

    function AutomationBase:SetTargetIndex(targetIndex)
        self["Vars"]["TargetIndex"] = targetIndex
    end

    --shared functions
    function AutomationBase:ProcessQueue()
        self["QueueManager"]:ProcessQueue()
    end

    function AutomationBase:ClearQueue()
        self["QueueManager"]:ResetQueue()
    end

    --job files should override this 
    function AutomationBase:DoRender()
        self["QueueManager"]:DoRender()
    end

    --default editor
    --need to add saving/loading settings
    function AutomationBase:RenderEditor(show)
        imgui.SetNextWindowSize({200, 200}, ImGuiCond_Always)
        imgui.SetNextWindowPos({300, 700})
        if(imgui.Begin("BaseEditor", show, ImGuiWindowFlags_NoResize))then
            imgui.Checkbox("Auto Buff", editorVars["AutoBuff"])
            imgui.Checkbox("Auto Ability", editorVars["AutoAbility"])
            imgui.Checkbox("Auto Cure", editorVars["AutoCure"])
            imgui.Checkbox("Auto Status Removal", editorVars["AutoStatusRemove"])
            imgui.Checkbox("Auto Enmity", editorVars["AutoEnmity"])
            for k,v in pairs(editorVars) do
                AutomationBase["Settings"][k] = v[1]
            end 
        end
    end


    return AutomationBase

end

return AutomationBase.Get()
