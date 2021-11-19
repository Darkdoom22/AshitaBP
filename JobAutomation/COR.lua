require('common')
local imgui = require('imgui')
local AutomationBase = require('JobAutomation\\AutomationBase')
local BuffUtility = require('Utilities\\BuffUtility')
local ActionUtility = require('Utilities\\ActionUtility')

local CorComponent = {}
setmetatable(CorComponent, {__index = AutomationBase})

function CorComponent.Get()

    local ShorthandRollName     = {

        ['sam']         = "Samurai Roll",       ['stp']         = "Samurai Roll",       ['att']         = "Chaos Roll",         ['at']          = "Chaos Roll",
        ['atk']         = "Chaos Roll",         ['da']          = "Fighter's Roll",     ['dbl']         = "Fighter's Roll",     ['sc']          = "Allies' Roll",
        ['acc']         = "Hunter's Roll",      ['mab']         = "Wizard's Roll",      ['matk']        = "Wizard's Roll",      ['macc']        = "Warlock's Roll",
        ['regain']      = "Tactician's Roll",   ['tp']          = "Tactician's Roll",   ['mev']         = "Runeist's Roll",     ['meva']        = "Runeist's Roll",
        ['mdb']         = "Magus's Roll",       ['patt']        = "Beast Roll",         ['patk']        = "Beast Roll",         ['pacc']        = "Drachen Roll",
        ['pmab']        = "Puppet Roll",        ['pmatk']       = "Puppet Roll",        ['php']         = "Companion's Roll",   ['php+']        = "Companion's Roll",
        ['pregen']      = "Companion's Roll",   ['comp']        = "Companion's Roll",   ['refresh']     = "Evoker's Roll",      ['mp']          = "Evoker's Roll",
        ['mp+']         = "Evoker's Roll",      ['xp']          = "Corsair's Roll",     ['exp']         = "Corsair's Roll",     ['cp']          = "Corsair's Roll",
        ['crit']        = "Rogue's Roll",       ['def']         = "Gallant's Roll",     ['eva']         = "Ninja's Roll",       ['sb']          = "Monk's Roll",
        ['conserve']    = "Scholar's Roll",     ['fc']          = "Caster's Roll",      ['snapshot']    = "Courser's Roll",     ['delay']       = "Blitzer's Roll",
        ['counter']     = "Avenger's Roll",     ['savetp']      = "Miser's Roll",       ['speed']       = "Bolter's Roll",      ['enhancing']   = "Naturalist's Roll",
        ['regen']       = "Dancer's Roll",      ['sird']        = "Choral's Roll",      ['cure']        = "Healer's Roll",
    
    }
    
    local LuckyRollNum = {
    
        ["Samurai Roll"]        = 2,    ["Chaos Roll"]          = 4,
        ["Hunter's Roll"]       = 4,    ["Fighter's Roll"]      = 5,
        ["Wizard's Roll"]       = 5,    ["Tactician's Roll"]    = 5,
        ["Runeist's Roll"]      = 4,    ["Beast Roll"]          = 4,
        ["Puppet Roll"]         = 3,    ["Corsair's Roll"]      = 5,
        ["Evoker's Roll"]       = 5,    ["Companion's Roll"]    = 2,
        ["Warlock's Roll"]      = 4,    ["Magus's Roll"]        = 2,
        ["Drachen Roll"]        = 4,    ["Allies' Roll"]        = 3,
        ["Rogue's Roll"]        = 5,    ["Gallant's Roll"]      = 3,
        ["Healer's Roll"]       = 3,    ["Ninja's Roll"]        = 4,
        ["Choral Roll"]         = 2,    ["Monk's Roll"]         = 3,
        ["Dancer's Roll"]       = 3,    ["Scholar's Roll"]      = 2,
        ["Naturalist's Roll"]   = 3,    ["Avenger's Roll"]      = 4,
        ["Bolter's Roll"]       = 3,    ["Caster's Roll"]       = 2,
        ["Courser's Roll"]      = 3,    ["Blitzer's Roll"]      = 4,
        ["Miser's Roll"]        = 5,
    
    }
    
    local UnluckyRollNum = {
    
        ["Samurai Roll"]        = 6,    ["Chaos Roll"]          = 8,
        ["Hunter's Roll"]       = 8,    ["Fighter's Roll"]      = 9,
        ["Wizard's Roll"]       = 9,    ["Tactician's Roll"]    = 8,
        ["Runeist's Roll"]      = 8,    ["Beast Roll"]          = 8,
        ["Puppet Roll"]         = 7,    ["Corsair's Roll"]      = 9,
        ["Evoker's Roll"]       = 9,    ["Companion's Roll"]    = 10,
        ["Warlock's Roll"]      = 8,    ["Magus's Roll"]        = 6,
        ["Drachen Roll"]        = 8,    ["Allies' Roll"]        = 10,
        ["Rogue's Roll"]        = 9,    ["Gallant's Roll"]      = 7,
        ["Healer's Roll"]       = 7,    ["Ninja's Roll"]        = 8,
        ["Choral Roll"]         = 6,    ["Monk's Roll"]         = 7,
        ["Dancer's Roll"]       = 7,    ["Scholar's Roll"]      = 6,
        ["Naturalist's Roll"]   = 7,    ["Avenger's Roll"]      = 8,
        ["Bolter's Roll"]       = 9,    ["Caster's Roll"]       = 7,
        ["Courser's Roll"]      = 9,    ["Blitzer's Roll"]      = 9,
        ["Miser's Roll"]        = 7,
    
    }
    
    local Settings = {
        ["Roll1"] = "Chaos Roll",
        ["Roll2"] = "Samurai Roll",
    }


    return CorComponent
end

return CorComponent.Get()