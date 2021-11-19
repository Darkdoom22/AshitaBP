addon.author = "Uwu/Darkdoom"
addon.name = "AshitaBP"
addon.version = "0.1"

require('common');
local chat = require('chat');
local fonts = require('fonts');
local imgui = require('imgui');
local WeaponSkillsRes = require('ExtraRes\\weapon_skills')
local JobManagerCore = require('Managers\\JobManagerCore')
local IpcManagerCore = require('Managers\\IpcManagerCore')
local TownExclusions = require('Misc\\TownZoneExclusions')

local AshitaBP = {
    ["ActionManager"] = {
        ["IsActing"] = false,
        ["InputDelay"] = 0,
    },
    ["JobManager"] = {
        ["MainJobStr"] = JobManagerCore:GetMainJobStr()
    },
    ["AutomationManager"] = {
        ["Manager"] = {},
    },
    ["TargetManager"] = {
        ["TargetIndex"] = 0,   
    },
    ["PartyCommandManager"] = {
        ["HandleCommand"] = function(cmd)
            if(PCmdDictionary[cmd])then
                PCmdDictionary[cmd]()
            end
        end,
    },
    ["CommandManager"] = {
        ["HandleCommand"] = function(args)

        end,
    },
    ["QueueManager"] = {

    },
    ["IpcManager"] = IpcManagerCore,
}

local Settings = {
    ["Mules"] = {
        "Doomvtwo", "Mierin", "Mingway", "Sombermabari", "Uwu"
    },
    ["FollowChar"] = "Uwu",
    ["Controllers"] = T{
        "Uwu", "Mierin", "Mingway", "Sombermabari", 
    },
    ["AlwaysShowQueueWindow"] = true,
    ["AutomateJob"] = false,
    ["JaZero"] = true,
    ["CheckFileDelay"] = 1
}

function AshitaBP:AddonMsg(str)
    if(str)then
        print(chat.header(addon.name):append(chat.message(chat.color1(6, str))));
    end
end

--addon commands
local CmdDictionary = {
    ["auto"] = function()
        Settings["AutomateJob"] = not Settings["AutomateJob"]
        AshitaBP:AddonMsg(("Job Automation set to %s"):fmt(Settings["AutomateJob"]))
    end,
    ["clearq"] = function()
        AshitaBP["AutomationManager"]["Manager"]:ClearQueue()
        AshitaBP:AddonMsg("Clearing Queue!")
    end,
}

--party commands
local PCmdDictionary = {
    ["follow"] = function()
        AshitaCore:GetChatManager():QueueCommand(1, ('/follow %s'):fmt(Settings["FollowChar"]));
    end, 
}

function AshitaBP:SetAutomationManager(mainJob)
    self["AutomationManager"]["Manager"] = require(string.format('JobAutomation\\%s', mainJob));
end

ashita.events.register('command', 'command_cb', function(e)
    local args = e.command:args()
    --check if its an addon command
    if(#args == 0 or args[1]:lower() ~= "/ashitabp" and args[1]:lower() ~= "/abp")then
        return
    end

    --handle
    if(#args == 2 and CmdDictionary[args[2]])then
        AshitaBP:AddonMsg("Valid Command received, doing thing")
        --change to manager for consistency 
        CmdDictionary[args[2]]()
    end

    --block message from going to game
    e.blocked = true

end)

ashita.events.register('text_in', 'text_in_cb', function(e)
end)

ashita.events.register('packet_in', 'packet_in_cb', function(e)
    if(e.id == 0x0017)then
        local mode = struct.unpack('h', e.data, 0x04 + 0x01)
        local senderName = struct.unpack('s', e.data, 0x08 + 0x01)
        local msg = struct.unpack('s', e.data, 0x17 + 0x01)
        if(mode == 4 and Settings["Controllers"]:contains(senderName))then
            AshitaBP:AddonMsg("Command from "..senderName.." mode "..mode.." msg "..msg)
            AshitaBP["PartyCommandManager"]["HandleCommand"](msg)
        end
    end
end)

--action specific enums, move out later
local ReadyActions = {
    [7] = 7,
    [8] = 8,
    [9] = 9,
    [12] = 12,
}

local FinishActions = {
    [2] = 2,
    [3] = 3,
    [4] = 4,
    [5] = 5,
    [6] = 6,
}

ashita.events.register('packet_out', 'packet_out_cb', function(e)
    if(e.id == 0x001A)then
        local category = struct.unpack('h', e.data, 0x0A + 0x01);
        local targetIndex = struct.unpack('h', e.data, 0x08 + 0x01);
        if(category == 2 or category == 15)then
            if(targetIndex)then
                local target = GetEntity(targetIndex)
                AshitaBP:AddonMsg(("Setting Target to [Idx: %s]"):fmt(targetIndex))
                AshitaBP["TargetManager"]["TargetIndex"] = targetIndex;
                AshitaBP["AutomationManager"]["Manager"]:SetTargetIndex(targetIndex)
                AshitaBP["IpcManager"]:SetMappedTargetId(target.ServerId)
                AshitaBP["IpcManager"]:SetMappedTargetIndex(targetIndex)
            end
        end
    end
end)

ashita.events.register('packet_in', 'packet_in_cb', function(e)
    if(e.id == 0x028)then
        local actor = struct.unpack('i', e.data, 0x05 + 0x01)
        local category = ashita.bits.unpack_le(e.data:totable(), 0x0A, 0x02, 0x4)
        local param = ashita.bits.unpack_be(e.data:totable(), 0xA, 0x6, 0x10)
        local t1param = ashita.bits.unpack_be(e.data:totable(), 0x1A, 0x3, 0x11)/4

        if(actor == GetPlayerEntity().ServerId)then
            if(category ~= 1 and not FinishActions[category])then
                AshitaBP["AutomationManager"]["Manager"]:SetCompletedAction(false)
            end
            --AshitaBP:AddonMsg(("Parsing our action packet category %s"):fmt(category))
            --AshitaBP:AddonMsg(("Action param %s"):fmt(param))

            local resManager = AshitaCore:GetResourceManager()

            if(ReadyActions[category])then
                --we're acting
                AshitaBP["AutomationManager"]["Manager"]:SetIsActing(true)
                AshitaBP["ActionManager"]["IsActing"] = true
                --we've been interrupted
                if(param == 28787)then
                    --superflous now 
                    AshitaBP["ActionManager"]["IsActing"] = false
                    AshitaBP["AutomationManager"]["Manager"]:SetIsActing(false)
                    AshitaBP["ActionManager"]["InputDelay"] = os.clock() + 1
                end
            elseif(FinishActions[category])then
                --we've finished acting
                AshitaBP["AutomationManager"]["Manager"]:SetIsActing(false)
                AshitaBP["AutomationManager"]["Manager"]:SetCompletedAction(true)
                AshitaBP["ActionManager"]["IsActing"] = false
            end
    
          --  AshitaBP:AddonMsg(("Acting: %s"):fmt(AshitaBP["ActionManager"]["IsActing"]))
            
            --update queue variables
            --update input delay
            if(param ~= 28787)then
                if(category == 7 and t1param < 255)then
                    AshitaBP["AutomationManager"]["Manager"]:SetLastAttemptedWeaponskill(WeaponSkillsRes[t1param].en)
                    AshitaBP["AutomationManager"]["Manager"]:SetInputDelay(os.clock() + 2.5)
                elseif(category == 8)then
                    AshitaBP["AutomationManager"]["Manager"]:SetLastAttemptedSpell(resManager:GetSpellById(t1param).Name[1])
                    AshitaBP["AutomationManager"]["Manager"]:SetInputDelay(os.clock() + 3.7)
                elseif(category == 9)then
                    AshitaBP["AutomationManager"]["Manager"]:SetLastAttemptedItem(resManager:GetItemById(t1param).Name[1])
                    AshitaBP["AutomationManager"]["Manager"]:SetInputDelay(os.clock() + 1.7)
                elseif(category == 6)then
                    AshitaBP["AutomationManager"]["Manager"]:SetInputDelay(os.clock() + 1.7)
                elseif(category == 14)then
                    AshitaBP["AutomationManager"]["Manager"]:SetLastAttemptedAbility(resManager:GetAbilityById(t1param).Name[1])
                    AshitaBP["AutomationManager"]["Manager"]:SetInputDelay(os.clock() + 1.7)
                end
            end

        end
    end
end)

--move out
local JaZero = {
    --change to pattern asaps
    ["Offsets"] = {
        ["FunctionOne"] = 0xA30C0,
        ["FunctionTwo"] = 0xA983C,
    },
    ["Original"] = {
        ["PatchOne"] = 0,
        ["PatchTwo"] = 0,
        ["PatchThree"] = 0,
    },
    ["Patched"] = {
        ["PatchOne"] = 0x90909090,
        ["PatchTwo"] = 0x66909090,
        ["PatchThree"] = 0x89900000,
    },
}

function JaZero:Apply()
    local xiMain = ashita.memory.get_base("FFXiMain.dll")
    -- might need to test my sigs again for this
   -- local scanTest = ashita.memory.find("FFXiMain.dll", 0, "C680????????01", 0, 1)
   -- AshitaBP:AddonMsg(("found addr? %s"):fmt((scanTest):hex()))
    --save original instructions
    --if game is already patched when you load this will just save the patch bytes
    self["Original"]["PatchOne"] = ashita.memory.read_uint32(xiMain+self["Offsets"]["FunctionOne"])
    self["Original"]["PatchTwo"] = ashita.memory.read_uint32(xiMain+self["Offsets"]["FunctionOne"]+0x4)
    self["Original"]["PatchThree"] = ashita.memory.read_uint32(xiMain+self["Offsets"]["FunctionTwo"])

    --patch functions
    ashita.memory.write_uint32(xiMain+self["Offsets"]["FunctionOne"], self["Patched"]["PatchOne"])
    ashita.memory.write_uint32(xiMain+self["Offsets"]["FunctionOne"] + 0x04, self["Patched"]["PatchTwo"])
    ashita.memory.write_uint32(xiMain+self["Offsets"]["FunctionTwo"], self["Patched"]["PatchThree"])
end

function JaZero:Restore()
    local xiMain = ashita.memory.get_base("FFXiMain.dll")
    ashita.memory.write_uint32(xiMain+self["Offsets"]["FunctionOne"] , self["Original"]["PatchOne"])
    ashita.memory.write_uint32(xiMain+self["Offsets"]["FunctionOne"] + 0x04, self["Original"]["PatchTwo"])
    ashita.memory.write_uint32(xiMain+self["Offsets"]["FunctionTwo"], self["Original"]["PatchThree"])
end



ashita.events.register('load', 'load_cb', function()
    AshitaBP:AddonMsg("Ashita BP Loaded!");
    AshitaBP:AddonMsg("Checking job..");

    local playerObject = AshitaCore:GetMemoryManager():GetPlayer();
    if(playerObject)then
        local mj = AshitaBP["JobManager"]["MainJobStr"];
        AshitaBP:SetAutomationManager(mj);
    end
    if(Settings["JaZero"])then
        JaZero:Apply()
    end

    --AshitaBP:AddonMsg("Test mapping file..")
    IpcManagerCore:CreateMappedFile()

end);

ashita.events.register('unload', 'unload_cb', function()
    IpcManagerCore:DisposeUnmanaged()
end)

local FileCheckTimer = os.clock()
ashita.events.register('d3d_present', 'present_cb', function ()

    local playerObj = GetPlayerEntity()--AshitaCore:GetMemoryManager():GetPlayer();
    if(IpcManagerCore:GetMappedTargetIndex() ~= 0 and IpcManagerCore:GetMappedTargetIndex() ~= AshitaBP["TargetManager"]["TargetIndex"])then
        AshitaBP["TargetManager"]["TargetIndex"] = IpcManagerCore:GetMappedTargetIndex()
        AshitaBP["AutomationManager"]["Manager"]:SetTargetIndex(IpcManagerCore:GetMappedTargetIndex())
        AshitaBP["AutomationManager"]["Manager"]:SetTargetId(IpcManagerCore:GetMappedTargetId())
    end
    local targetObj = GetEntity(AshitaBP["TargetManager"]["TargetIndex"]);
    
    if(targetObj and targetObj.HPPercent == 0 and AshitaBP["TargetManager"]["TargetIndex"] ~= 0)then
        AshitaBP["TargetManager"]["TargetIndex"] = 0
        AshitaBP["AutomationManager"]["Manager"]:SetTargetIndex(0)
        AshitaBP["ActionManager"]["IsActing"] = false
        AshitaBP["AutomationManager"]["Manager"]:SetIsActing(AshitaBP["ActionManager"]["IsActing"])
        AshitaBP["AutomationManager"]["Manager"]:ClearQueue()
        if(targetObj and targetObj.HPPercent == 0)then
            AshitaBP:AddonMsg("Target cleared..")
            AshitaBP["TargetManager"]["TargetIndex"] = 0
            AshitaBP["IpcManager"]:SetMappedTargetId(0)
            AshitaBP["IpcManager"]:SetMappedTargetIndex(0)
        end
    end

    local pObj2 = AshitaCore:GetMemoryManager():GetPlayer()
    
    --print(TownExclusions[GetPlayerEntity().ZoneId])
    if(Settings["AutomateJob"])then
        if(os.clock() - FileCheckTimer > Settings["CheckFileDelay"])then
            AshitaBP["IpcManager"]:CheckChanges()
            FileCheckTimer = os.clock()
        end
        AshitaBP["AutomationManager"]["Manager"]:Auto()
        AshitaBP["AutomationManager"]["Manager"]:DoRender()
        AshitaBP["AutomationManager"]["Manager"]:ProcessQueue()
    end

    local showTargetWindow = targetObj and true or false 
    local showInputDelayWindow = os.clock() - AshitaBP["ActionManager"]["InputDelay"] < 0 and true or false

    if(os.clock() - AshitaBP["ActionManager"]["InputDelay"] < 0)then
        imgui.SetNextWindowBgAlpha(0.6)
        imgui.SetNextWindowSize({200, 50}, ImguiCond_Always)
        imgui.SetNextWindowPos({1200, 200})
        if(imgui.Begin('InputDelay', showInputDelayWindow, ImguiWindowFlags_NoResize))then
            imgui.TextColored({0.0, 1.0, 1.0, 1.0}, "Input Delay:")
            imgui.SameLine();
            imgui.Text(("%.2f"):fmt(os.clock()-AshitaBP["ActionManager"]["InputDelay"]))
        end
    end

    if(targetObj)then
        imgui.SetNextWindowBgAlpha(0.8)
        imgui.SetNextWindowSize({300, 50}, ImGuiCond_Always)
        imgui.SetNextWindowPos({860, 200})
        if(imgui.Begin('BpTarget', showTargetWindow, ImguiWindowFlags_NoResize))then
            imgui.TextColored({0.0, 1.0, 1.0, 1.0}, "BpTarget:")
            imgui.SameLine()
            imgui.Text(targetObj.Name)
            imgui.SameLine()
            imgui.Text(""..targetObj.ServerId)
        end
    end

    imgui.SetNextWindowBgAlpha(0.8);
    imgui.SetNextWindowSize({350, 70}, ImGuiCond_Always);
    imgui.SetNextWindowPos({300, 400})

    if(imgui.Begin('AshitaBP', true, ImGuiWindowFlags_NoResize))then
        if(playerObj)then
            imgui.Indent(50)
            imgui.TextColored({0.0, 1.0, 1.0, 1.0}, "Char:");
            imgui.SameLine();
            imgui.Text(playerObj.Name);
            imgui.SameLine();
            imgui.TextColored({0.0, 1.0, 1.0, 1.0}, "Job:");
            imgui.SameLine();
            imgui.Text(AshitaBP["JobManager"]["MainJobStr"]);
            imgui.SameLine();
            imgui.TextColored({0.0, 1.0, 1.0, 1.0}, "Status:");
            imgui.SameLine();
            imgui.Text(""..playerObj.Status);
            imgui.Unindent(50)
        end

        if(targetObj)then
            imgui.Indent(50)
            imgui.TextColored({0.0, 1.0, 1.0, 1.0}, "Target:");
            imgui.SameLine();
            imgui.Text(targetObj.Name);
            imgui.SameLine();
            imgui.TextColored({0.0, 1.0, 1.0, 1.0}, "Idx:");
            imgui.SameLine();
            imgui.Text(""..targetObj.TargetIndex);
            imgui.Unindent(50)
        end
        --if(AshitaBP["AutomationManager"]["Manager"]:GetQueueAsStr())then
          --  imgui.TextColored({1.0, 0.4, 0.3, 1.0}, AshitaBP["AutomationManager"]["Manager"]:GetQueueAsStr())
        --end
    end
    imgui.End();
end);	