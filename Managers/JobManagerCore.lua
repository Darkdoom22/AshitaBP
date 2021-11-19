local JobManagerCore = {}

local Enums = {
    ["Jobs"] = {
        [0] = "None",
        [1] = "WAR",
        [2] = "MNK",
        [3] = "WHM",
        [4] = "BLM",
        [5] = "RDM",
        [6] = "THF",
        [7] = "PLD",
        [8] = "DRK",
        [9] = "BST",
        [10] = "BRD",
        [11] = "RNG",
        [12] = "SAM",
        [13] = "NIN",
        [14] = "DRG",
        [15] = "SMN",
        [16] = "BLU",
        [17] = "COR",
        [18] = "PUP",
        [19] = "DNC",
        [20] = "SCH",
        [21] = "GEO",
        [22] = "RUN",
        [23] = "MON",
    }
}

function JobManagerCore.Get()

    function JobManagerCore:GetMainJobStr()

        local playerObject = AshitaCore:GetMemoryManager():GetPlayer();
        if(playerObject)then
            local mj = playerObject:GetMainJob();
            return Enums["Jobs"][mj];
        end

    end

    return JobManagerCore;

end

return JobManagerCore.Get();