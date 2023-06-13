-- Do not remove this comment, it is part of this aura: Effective Health - Magic and Physical
-- Dragonflight Version by Justbears-Illidan US
-- Credit to Zeler-Ravencrest EU for the original version




-- User settings
aura_env.display = aura_env.config.display
aura_env.align = aura_env.config.align
aura_env.decimals = aura_env.config.decimals
aura_env.show = aura_env.config.show
local Ptext = aura_env.config.Ptext
local Mtext = aura_env.config.Mtext
aura_env.aoe = aura_env.config.aoe
aura_env.countCheat = aura_env.config.countCheat
aura_env.conditionalReductions = aura_env.config.conditionalReductions
aura_env.lenienceenable = aura_env.config.lenience
aura_env.blockMode = aura_env.config.blockMode
aura_env.dynamicColors = aura_env.config.color.dynamicColors
local color = {aura_env.config.color.numberColor}
local textColorP = CreateColor(unpack(aura_env.config.color.textColorP)):GenerateHexColor()
local textColorM = CreateColor(unpack(aura_env.config.color.textColorM)):GenerateHexColor()
aura_env.immunityColor = CreateColor(unpack(aura_env.config.color.immunityColor)):GenerateHexColor()
aura_env.throttle = aura_env.config.advanced.throttle
aura_env.dynamicUpdates = aura_env.config.advanced.dynamicUpdates
aura_env.debug = aura_env.config.advanced.debug


aura_env.frame = 0
aura_env.lastUpdateFrame = 0
aura_env.lastUpdate = {} -- Only update when there are changes
aura_env.updateBuffs = false
aura_env.immunityPhysical, aura_env.immunityMagic = false, false
aura_env.cheatDeath = false
aura_env.antiMagicShellAbsorb, aura_env.bloodShield = 0, 0
aura_env.spellwardingAbsorb = 0
aura_env.unholyBondRank = 0
aura_env.splinterAbsorb = 0
aura_env.elusiveMistsRank = 0
aura_env.bounceBackRank = 0
aura_env.seasonedSoldier = 1
aura_env.dampenHarm = false
aura_env.celestialbrew = 0 -- Monk - Brewmaster
aura_env.earthwarden = 1 -- Guardian Druid - talent
aura_env.nameplateCheck = 0 -- Protection Paladin - Last Defender - talent
aura_env.mirrorimage = false -- Mage - Mirror Image
aura_env.mirrorimagereduction = 1
aura_env.touchOfKarma = 0
aura_env.feint = 1
aura_env.zephyr = 1
aura_env.generousPour = 1
aura_env.suppression = 1
aura_env.huntersAvoidance = 1
aura_env.ruggedTenacity = 0
aura_env.brambles = 0
aura_env.instanceDifficulty = select(3, GetInstanceInfo())

aura_env.update = true
aura_env.avoidance = 1
if aura_env.aoe then aura_env.avoidance = 1 - GetAvoidance() / 100 end
aura_env.playerLevel = UnitLevel("player")
aura_env.targetArmorScaling = UnitExists("target")
aura_env.highmountainTauren = IsPlayerSpell(255659) -- Rugged Tenacity - passive
aura_env.classID = select(3, UnitClass("player"))
aura_env.specID = GetSpecialization()

aura_env.separator = ""
if aura_env.display == 1 and aura_env.align == 1 then aura_env.separator = "\n"
elseif aura_env.display == 1 and aura_env.align == 2 then aura_env.separator = " | "
elseif aura_env.display == 1 and aura_env.align == 3 then aura_env.separator = " "
end

aura_env.textFormatPhysical = "|c"..textColorP..Ptext.."|r|c%s%."
aura_env.textFormatMagic = "|c"..textColorM..Mtext.."|r|c%s%."

local gameVersion = select(4, GetBuildInfo()) / 10000
if gameVersion > 10.0002 or gameVersion < 10 then
    aura_env.outOfDate = true
end

-- Include or ignore block
aura_env.includeBlock = false
if aura_env.blockMode > 1 then
    if aura_env.classID == 1 and aura_env.specID == 3 then
        aura_env.includeBlock = true
    elseif aura_env.classID == 2 and aura_env.specID == 2 then
        aura_env.includeBlock = true
    end
end

-- Color values. The accepted values are from 0 to 1
-- The first value is for red, second is for green, and third is for blue
if aura_env.dynamicColors and aura_env.playerLevel == 70 and aura_env.show ~= 2 then
    aura_env.color = {
        {1, 0, 0},  -- Lowest health
        {1, 0.5, 0},
        {0, 1, 0},
        {0, 1, 1},
        {1, 0, 1},
        {1, 1, 0},  -- Highest health
    }
else
    aura_env.color = color
end

for i, v in ipairs(aura_env.color) do
    aura_env.color[i] = CreateColor(unpack(v)):GenerateHexColor()
end
-- Thresholds at which the color changes, the values are in raw effective health number
aura_env.threshold = {
    {0, 64000, 128000, 192000, 256000, 320000}, -- Physical
    {0, 56000, 112000, 168000, 224000, 280000}, -- Magic
}

-- Shorten numbers
function aura_env.shorten(number)
    local char, div, deci = "", 1, 0
    if number < 10^3 or aura_env.decimals == 7 or aura_env.show == 2 then -- Don't shorten
        return char, div, deci
    end
    if number >= 10^12 then
        div = 10^12
        char = "t"
    elseif number >= 10^9 then
        div = 10^9
        char = "b"
    elseif number >= 10^6 then
        div = 10^6
        char = "m"
    else
        div = 10^3
        char = "k"
    end
    if number / div < 10 then
        deci = 2
    elseif number / div < 100 then
        deci = 1
    end
    return char, div, deci
end

-- Basic damage reductions
-- [Spell ID]  = {physical reduction, magic reduction}
aura_env.basicReductions = {
    
    --- Warrior ---
    [339461] = {0.85, 0.85}, -- Defensive Stance
    [385391] = {1.00, 0.80}, -- Spell Reflection
    [118038] = {0.70, 0.70}, -- Die by the Sword
    [184364] = {0.70, 0.70}, -- Enrage Regeneration
    [871] = {0.60, 0.60}, -- Shield Wall
    [394056] = {0.96, 0.96}, -- Protection T23 2-set
    
    --- Paladin ---
    [6940] = {0.70, 0.70}, -- Blessing of Sacrifice
    [498] = {0.80, 0.80}, -- Divine Protection
    [86659] = {0.50, 0.50}, -- Guardian of Ancient Kings
    [385126] = {0.96, 0.96}, -- Blessing of Dusk
    [205191] = {0.65, 1.00}, -- Eye for an eye
    [387804] = {0.85, 0.85}, -- Echoing Blessing
    
    --- Rogue ---
    [386237] = {0.90, 0.90}, -- Fade to Nothing
    
    --- Priest ---
    [81782] = {0.75, 0.75}, -- Power Ward: Barrier
    [33206] = {0.60, 0.60}, -- Pain Suppression
    [45242] = {0.85, 0.85}, -- Focused Will
    [47585] = {0.25, 0.25}, -- Dispersion
    [193065] = {0.90, 0.90}, -- Protective Light
    [390677] = {0.95, 1.00}, -- Inspiration
    ---
    --- Death Knight ---
    [48792] = {0.70, 0.70}, -- icebound fortitude
    [145629] = {0.80, 0.80}, -- anti-magic zone
    [194679] = {0.80, 0.80}, -- rune tap
    
    --- Shaman ---
    [383018] = {0.90, 1.00}, -- Stoneskin Totem
    [381765] = {0.95, 0.95}, -- Primordial Bond
    [325174] = {0.90, 0.90}, -- Spirit Link Totem
    
    --- Mage ---
    [113862] = {0.40, 0.40}, -- Greater Invisibility
    
    --- Warlock ---
    [386869] = {0.96, 0.96}, -- Teachings of the Black Harvest
    [389614] = {0.96, 0.96}, -- Abyss Walker
    
    --- Monk ---
    [120954] = {0.80, 0.80}, -- Fortifying Brew
    [122783] = {1.00, 0.40}, -- Diffuse Magic
    
    --- Druid ---
    [61336] = {0.50, 0.50}, -- Survival Instincts
    [200851] = {0.75, 0.75}, -- Rage of the Sleeper
    [391955] = {0.95, 0.95}, -- Protective Growth
    [102342] = {0.80, 0.80}, -- Ironbark
    [395944] = {0.95, 0.95}, -- Guardian T23 2-set
    
    --- Demon Hunter ---
    [393009] = {1.00, 0.90}, -- Fel Flame Fortification
    
    --- Evoker ---
    [363916] = {0.70, 0.70}, -- Obsidian Scales
    
    --- Race ---
    [65116]  = {0.90, 1.00}, -- Stoneform
    
    --- World ---
    [377874] = {0.85, 0.85}, -- Earth Shield
    
    --- Dungeon ---
    [267904] = {0.25, 0.25}, -- Reinforcing Ward (BFA/Shrine of the Storm)
    [268212] = {0.25, 0.25}, -- Minor Reinforcing Ward (BFA/Shrine of the Storm)
    
    --- Legacy ---
    [273809] = {1.30, 1.30}, -- Idol of Rage
    [303350] = {0.90, 0.90}  -- Paralytic Spines
}


function aura_env.checkBuffs()
    aura_env.antiMagicShellAbsorb, aura_env.bloodShield = 0, 0
    aura_env.spellwardingAbsorb = 0
    aura_env.splinterAbsorb = 0
    aura_env.celestialbrew = 0
    aura_env.zephyr = 1
    aura_env.generousPour = 1
    aura_env.feint, aura_env.earthwarden = 1, 1
    aura_env.immunityPhysical, aura_env.immunityMagic = false, false
    aura_env.cheatDeath, aura_env.dampenHarm = false, false
    local reductionPhysical, reductionMagic = 1, 1
    local n = 1
    local _,_,stacks,_,_,_,caster,_,_,spellID,_,_,_,_,_,tooltip1,tooltip2= UnitBuff("player", n)
    while spellID do
        local reduction = 1
        local reductionPhysicalBuff = 1
        local reductionMagicBuff = 1
        
        if aura_env.basicReductions[spellID] then
            reductionPhysical = reductionPhysical * aura_env.basicReductions[spellID][1]
            reductionMagic = reductionMagic * aura_env.basicReductions[spellID][2]
        else
            
            --- Death Knight ---
            if spellID == 48707 then -- Anti-Magic Shell
                aura_env.antiMagicShellAbsorb = tooltip1 or 0
            elseif spellID == 77535 then -- Blood Shield
                aura_env.bloodShield = tooltip1 or 0
            elseif spellID == 49039 then -- lichborne
                if IsPlayerSpell(389682) then
                    reduction = 0.85
                else
                    reduction = 0.90
                end
            elseif spellID == 356337 then -- rune of spellwarding
                if aura_env.unholyBondRank == 0 then
                    reductionMagicBuff = 0.96
                else
                    reductionMagicBuff = 1 - (0.04 * (1 + 0.1 * aura_env.unholyBondRank))
                end
            elseif spellID == 326867 then
                aura_env.spellwardingAbsorb = tooltip1 or 0
                --TODO: check purgatory
                
                --- Demon Hunter ---
            elseif spellID == 196555 then -- Netherwalk
                aura_env.immunityPhysical = true
                aura_env.immunityMagic = true
            elseif spellID == 212800 then -- Blur
                if aura_env.desperateInstincts then
                    reduction = 0.70
                else
                    reduction = 0.80
                end
            elseif spellID == 391171 then -- Calcified Spikes
                reduction = 1 + (tooltip1 or 0) / 100
                
                
                --- Druid ---
            elseif spellID == 203975 and aura_env.conditionalReductions then -- Earthwarden - talent
                reductionPhysicalBuff = 0.70
                aura_env.earthwarden = 0.70
            elseif spellID == 22812 then -- Barkskin
                if aura_env.reinforcedFur then
                    reduction = 0.75 -- reinforced Fur (guardian tree)
                else
                    reduction = 0.80
                end
                --elseif spellID == 5487 and aura_env.ursineAdept then -- Ursine Adept (guardian tree)
                --    reduction = 0.90
                
                --- Hunter ---
            elseif spellID == 264735 then -- survival of the fittest
                if aura_env.naturesEndurance then
                    reduction = 0.60
                else
                    reduction = 0.80
                end
            elseif spellID == 186265 then
                reduction = 0.70
                if aura_env.conditionalReductions then
                    aura_env.immunityPhysical = true
                end
                
                --- Mage ---
            elseif spellID == 45438 then -- Ice Block
                aura_env.immunityPhysical = true
                aura_env.immunityMagic = true
            elseif spellID == 235450 then -- prismatic barrier
                if aura_env.improvedPrismaticBarrier then
                    reductionMagicBuff = 0.8
                else
                    reductionMagicBuff = 0.85
                end
                
                --- Monk ---
            elseif spellID == 322507 then -- Celestial Brew // track Celestial Brew to remove it from absorb later
                -- TODO: why remove celestial brew from absorb???
                aura_env.celestialbrew = tooltip1
            elseif spellID == 122278 then -- Dampen Harm
                aura_env.dampenHarm = true
                if aura_env.conditionalReductions then
                    reduction = 0.50
                else
                    reduction = 0.80
                end
            elseif spellID == 389577 then -- bounce back
                reduction = 1 - (0.1 * aura_env.bounceBackRank)
            elseif spellID == 261769 then -- Inner Strength
                reduction = 1 + (tooltip1 or 0) / 100
            elseif spellID == 394797 then -- T23 2-set
                reduction = 1 - (0.01 * stacks)
            elseif spellID == 389685 and aura_env.aoe then -- Generous Pour
                reduction = 1 + (tooltip1 or 0) / 100
                aura_env.generousPour = 1 + (tooltip1 or 0) / 100
                
                --- Paladin ---
            elseif spellID == 642 then -- Divine Shield
                aura_env.immunityPhysical = true
                aura_env.immunityMagic = true
            elseif spellID == 1022 then -- Blessing of Protection
                aura_env.immunityPhysical = true
            elseif spellID == 31850 then -- Ardent Defender
                if aura_env.improvedArdentDefender then
                    reduction = 0.70
                else
                    reduction = 0.80
                end
                aura_env.cheatDeath = true
            elseif spellID == 389539 then -- sentinel
                reduction = 1 - (0.02 * stacks)
            elseif spellID == 188370 then -- Consecration
                if aura_env.specID == 2 then -- protection
                    local s2 = select(2, strsplit("%", GetSpellDescription(76671)))
                    local mastery = select(11, strsplit(" ", s2))
                    reduction = 1 - mastery / 100
                end
            elseif spellID == 204018 then -- Blessing of Spellwarding
                aura_env.immunityMagic = true
            elseif spellID == 465 then -- Devotion Aura
                reduction = 1 + (tooltip1 or 0) / 100
                
                --- Priest ---
            elseif spellID == 194384 then -- Lenience - talent
                if aura_env.lenience then
                    reduction = 0.97
                elseif aura_env.lenienceenable then
                    reduction = 0.97
                end
            elseif spellID == 47788 then -- Guardian Spirit
                aura_env.cheatDeath = true
            elseif spellID == 586 then -- fade dr from talent
                if aura_env.translucentImage then
                    reduction = 0.90
                end
                
                --- Rogue ---
            elseif spellID == 1966 then
                if not aura_env.aoe and aura_env.elusiveness then
                    reduction = 0.80 -- Elusiveness
                    aura_env.feint = 0.60
                elseif aura_env.aoe then
                    reduction = 0.60
                    aura_env.feint = 0.60
                end
            elseif spellID == 31224 then -- Cloak of Shadows
                aura_env.immunityMagic = true
            elseif spellID == 5277 then -- evasion
                if aura_env.conditionalReductions then
                    aura_env.immunityPhysical = true
                end
                if aura_env.elusiveness then
                    reduction = 0.90
                end
                
                --- Shaman ---
            elseif spellID == 260881 then -- Spirit Wolf
                reduction = 1 - (tonumber(stacks or 1)) * 5 / 100
            elseif spellID == 108271 then -- Astral Shift
                if aura_env.astralBulwark then
                    reduction = 0.45
                else
                    reduction = 0.60
                end
                
                --- Warlock ---
            elseif spellID == 104773 then -- Unending Resolve
                if aura_env.strengthOfWill then
                    reduction = 0.60
                else
                    reduction = 0.75
                end
            elseif aura_env.felArmor and spellID == 108366 then -- TODO: need to confirm the mechanism for this one
                reduction = 1 - (0.05 * (aura_env.felArmorRank or 1))
                
                --- Warrior ---
            elseif spellID == 184362 and aura_env.warPaint then -- Enrage
                reduction = 0.90 -- War Paint
                
                --- Evoker ---
            elseif spellID == 374227 and aura_env.aoe then -- zephyr
                reduction = 0.80
                aura_env.zephyr = 0.80
            elseif spellID == 357170 then -- time dilation
                if aura_env.delayHarm then
                    reduction = 0.30
                else
                    reduction = 0.50
                end
                
                --- Miscellaneous ---
            elseif spellID == 395175 then -- Treemouth's Festering Splinter
                reduction = 0.5
                aura_env.splinterAbsorb = tooltip2 or 0
                
            end
            reductionPhysical = reductionPhysical * reduction * reductionPhysicalBuff
            reductionMagic = reductionMagic * reduction * reductionMagicBuff
        end
        
        n = n + 1
        _,_,stacks,_,_,_,caster,_,_,spellID,_,_,_,_,_,tooltip1,tooltip2 = UnitBuff("player", n)
    end
    return reductionPhysical, reductionMagic
end

function aura_env.checkDebuffs()
    local reduction, reductionPhysical, reductionMagic = 1, 1, 1
    
    if aura_env.cauterize and not WA_GetUnitDebuff("player", 87024) then -- fire mage cheat death
        aura_env.cheatDeath = true
    end
    if aura_env.rogueCheatDeath and not WA_GetUnitDebuff("player", 45181) then -- rogue cheat death
        aura_env.cheatDeath = true
    end
    if aura_env.lastResort and not WA_GetUnitDebuff("player", 209261) then -- dh tank cheat death
        aura_env.cheatDeath = true
    end
    
    --- Dungeons ---
    if WA_GetUnitDebuff("player", 388072) then -- Telash Greywing // Vault Rune
        reduction = reduction * 0.50
    end
    
    reductionPhysical = reductionPhysical * reduction
    reductionMagic = reductionMagic * reduction
    return reductionPhysical, reductionMagic
end

function aura_env.checkTalents()
    local reduction = 1
    local reductionPhysical, reductionMagic = 1, 1
    
    --- Warrior ---
    if aura_env.classID == 1 then
        aura_env.warPaint = IsPlayerSpell(208154)
        aura_env.punish = IsPlayerSpell(275334)
        --if IsPlayerSpell(71) then -- vanguard
        --    reduction = reduction * 0.95
        --end
        if IsPlayerSpell(279423) and aura_env.aoe then
            reduction = reduction * 0.90
            aura_env.seasonedSoldier = 0.90
        end
        
        --- Paladin ---
    elseif aura_env.classID == 2 then
        aura_env.improvedArdentDefender = IsPlayerSpell(393114)
        aura_env.crusadersResolve = IsPlayerSpell(380188)
        --if IsPlayerSpell(358934) then -- Aegis of Light (rank 2)
        --    reduction = reduction * 0.90
        --end
        
        --- Hunter ---
    elseif aura_env.classID == 3 then
        aura_env.naturesEndurance = IsPlayerSpell(388042)
        if aura_env.aoe and IsPlayerSpell(384799) then
            reduction = reduction * 0.94
            aura_env.huntersAvoidance = 0.94
        end
        
        --- Rogue ---
    elseif aura_env.classID == 4 then
        aura_env.elusiveness = IsPlayerSpell(79008)
        aura_env.rogueCheatDeath = IsPlayerSpell(31230)
        if IsPlayerSpell(231719) then -- Deadened Nerves
            reductionPhysical = reductionPhysical * 0.97
        end
        
        --- Priest ---
    elseif aura_env.classID == 5 then
        aura_env.perseverance = IsPlayerSpell(235189)
        aura_env.translucentImage = IsPlayerSpell(373446)
        aura_env.lenience = IsPlayerSpell(238063)
        if IsPlayerSpell(390667) then
            reductionMagic = reductionMagic * 0.97
        end
        
        --- Death Knight ---
    elseif aura_env.classID == 6 then
        aura_env.necropolis = IsPlayerSpell(206967) -- Will of the Necropolis (class tree)
        if aura_env.aoe and IsPlayerSpell(374049) then -- Suppression (class tree)
            reduction = reduction * 0.97
            aura_env.suppression = 0.97
        end
        if IsPlayerSpell(374261) then -- unholy bond (class tree)
            aura_env.unholyBondRank = aura_env.findTalentRank(374261)
        end
        --if IsPlayerSpell(374721) then -- blood fortification
        --    reduction = reduction * 0.90
        --end
        
        --- Shaman ---
    elseif aura_env.classID == 7 then
        aura_env.astralBulwark = IsPlayerSpell(377933)
        if IsPlayerSpell(381650) then -- Elemental Warding
            local rank = aura_env.findTalentRank(381650)
            reductionMagic = reductionMagic * (1 - 0.02 * (rank or 1))
        end
        
        --- Mage ---
    elseif aura_env.classID == 8 then
        aura_env.cauterize = IsPlayerSpell(86949)
        aura_env.improvedPrismaticBarrier = IsPlayerSpell(321745)
        if IsPlayerSpell(383092) then -- Arcane Warding (class tree)
            local rank = aura_env.findTalentRank(383092)
            reductionMagic = reductionMagic * (1 - 0.02 * (rank or 1))
        end
        --- Warlock ---
    elseif aura_env.classID == 9 then
        aura_env.profaneBargain = IsPlayerSpell(389576)
        if not aura_env.profaneBargain and IsPlayerSpell(108415) and UnitExists("pet") then
            reduction = reduction * 0.90
        end
        aura_env.strengthOfWill = IsPlayerSpell(317138)
        if IsPlayerSpell(386124) then -- Fel Armor
            aura_env.felArmorRank = aura_env.findTalentRank(386124)
            reduction = reduction * (1 - 0.015 * (aura_env.felArmorRank or 1))
        end
        
        --- Monk ---
    elseif aura_env.classID == 10 then
        aura_env.blackoutCombo = IsPlayerSpell(196736)
        --if IsPlayerSpell(245013) then -- Brewmaster's Balance
        --    reduction = reduction * 0.90
        --end
        if IsPlayerSpell(388664) then -- calming presence
            reduction = reduction * 0.97
        end
        if IsPlayerSpell(388681) then -- elusive mists
            aura_env.elusiveMistsRank = aura_env.findTalentRank(388681)
        end
        if IsPlayerSpell(389577) then
            aura_env.bounceBackRank = aura_env.findTalentRank(389577)
        end
        --- Druid ---
    elseif aura_env.classID == 11 then
        aura_env.rendAndTear = IsPlayerSpell(204053)
        aura_env.bramblesTalent = IsPlayerSpell(203953)
        aura_env.scintillatingMoonlight = IsPlayerSpell(238049)
        aura_env.ursineAdept = IsPlayerSpell(300346)
        aura_env.reinforcedFur = IsPlayerSpell(393618)
        aura_env.innerPeace = IsPlayerSpell(197073)
        
        if IsPlayerSpell(16931) then -- Thick Hide
            local rank = aura_env.findTalentRank(16931)
            reduction = reduction * (1 - 0.03 * (rank or 1))
        end
        
        --- Demon Hunter ---
    elseif aura_env.classID == 12 then
        aura_env.desperateInstincts = IsPlayerSpell(205411)
        aura_env.voidReaver = IsPlayerSpell(268175)
        aura_env.lastResort = IsPlayerSpell(209258)
        if IsPlayerSpell(389696) then
            local rank = aura_env.findTalentRank(389696)
            reductionMagic = reductionMagic * (1 - 0.03 * (rank or 1))
        end
        -- Demonic Wards
        --if aura_env.specID == 1 then -- Havoc
        reduction = reduction * 0.90
        --elseif aura_env.specID == 2 then -- Vengeance
        --    reduction = reduction * 0.80
        --end
        --- Evoker ---
    elseif aura_env.classID == 13 then
        aura_env.delayHarm = IsPlayerSpell(376207)
        if IsPlayerSpell(375544) then -- inherent resistance
            local rank = aura_env.findTalentRank(375544)
            reductionMagic = reductionMagic * (1 - 0.02 * (rank or 1))
        end
    end
    
    --- racial ---
    if IsPlayerSpell(265224) then -- darkiron dwarf
        reductionPhysical = reductionPhysical * 0.99
    end
    
    reductionPhysical = reductionPhysical * reduction
    reductionMagic = reductionMagic * reduction
    
    return reductionPhysical, reductionMagic
end

function aura_env.checkStagger()
    -- TODO: check if stagger calculation is changed
    local staggerPhyiscal = 1
    local staggerMagic = 1
    if aura_env.classID == 10 and aura_env.specID == 1 then -- Brewmaster Monk
        -- Get Stagger's effect against current target. If no target is found then use base
        local stagger, staggerAgainstTarget = C_PaperDollInfo.GetStaggerPercentage("player")
        if not staggerAgainstTarget then staggerAgainstTarget = stagger end
        staggerMagic = staggerAgainstTarget * 0.35
        staggerPhyiscal = 1 - staggerAgainstTarget / 100
        staggerMagic = 1 - staggerMagic / 100
        
        -- Stagger cap --
        local staggerDamage = UnitStagger("player") or 0 -- Calculate cap for Stagger
        local staggerCapPhysical = (aura_env.currentHealth + aura_env.absorb) /
        (aura_env.currentHealth + aura_env.absorb + 100 * aura_env.maxHealth - staggerDamage * 10)
        
        local staggerCapMagic = (aura_env.currentHealth + aura_env.absorb) /
        (aura_env.currentHealth + aura_env.absorb + 100 * aura_env.maxHealth - staggerDamage * 10)
        
        if staggerCapPhysical < 0.01 then staggerCapPhysical = 0.01 end -- Stagger caps at 99%
        if staggerCapMagic < 0.01 then staggerCapMagic = 0.01 end
        if staggerPhyiscal < staggerCapPhysical then staggerPhyiscal = staggerCapPhysical end
        if staggerMagic < staggerCapMagic then staggerMagic = staggerCapMagic end
    end
    return staggerPhyiscal, staggerMagic
end

function aura_env.checkStats()
    local versatility = GetVersatilityBonus(31) + GetCombatRatingBonus(31)
    local versDR = 1 - versatility / 100
    local reductionPhysical = versDR
    local reductionMagic = versDR
    
    if aura_env.highmountainTauren then
        local stamina = UnitStat("player", 3)
        aura_env.ruggedTenacity = floor((stamina * 0.0003 * 20) + 0.5)
    end
    if aura_env.bramblesTalent then -- Brambles - talent
        aura_env.brambles = floor((PlayerEffectiveAttackPower() * 0.06) + 0.5)
    else
        aura_env.brambles = 0
    end
    
    return reductionPhysical, reductionMagic
end

function aura_env.checkArmor()
    local armor = select(2, UnitArmor("player"))
    if aura_env.targetArmorScaling then -- Gets the reduction percentage and makes it usable
        armor = 1 - (C_PaperDollInfo.GetArmorEffectivenessAgainstTarget(armor) or C_PaperDollInfo.GetArmorEffectiveness(armor, aura_env.playerLevel))
    else
        armor = 1 - C_PaperDollInfo.GetArmorEffectiveness(armor, aura_env.playerLevel)
    end
    return armor
end

function aura_env.checkHealth()
    local currentHealth = UnitHealth("player")
    local healthBasedReduction = 1
    if aura_env.necropolis then
        local rank  = aura_env.findTalentRank(206967)
        if currentHealth / aura_env.maxHealth < 0.30 then
            if rank == 1 then
                healthBasedReduction = healthBasedReduction * 0.80
            elseif rank == 2 then
                healthBasedReduction = healthBasedReduction * 0.65
            end
        end
    end
    if aura_env.profaneBargain then
        local rank = aura_env.findTalentRank(389576)
        if currentHealth / aura_env.maxHealth < 0.35 then
            healthBasedReduction = healthBasedReduction * (1 - 0.1 - 0.05 * (rank or 1))
        else
            healthBasedReduction = healthBasedReduction * 0.90
        end
    end
    return currentHealth, healthBasedReduction
end

function aura_env.checkChannel()
    local spellID = select(8, UnitChannelInfo("player"))
    local reduction  = 1
    if aura_env.classID == 11 then
        if aura_env.specID == 4 and aura_env.innerPeace then
            if spellID == 740 then
                reduction = 0.8
            end
        end
    elseif aura_env.classID == 10 then
        if aura_env.specID == 1 and spellID == 115176 then
            reduction = 0.4
        end
        if aura_env.elusiveMistsRank > 0 and spellID == 115175 then
            reduction = 1 - (0.03 * (aura_env.elusiveMistsRank or 1))
        end
    end
    return reduction
end

function aura_env.checkTargetReduction()
    local targetReduction = 1
    local targetReductionPhysical, targetReductionMagic = 1, 1
    
    --- Death Knight ---
    if aura_env.classID == 6 then
        if select(7, WA_GetUnitDebuff("target", 327092)) == "player" then -- Rune of the Apocalypse
            if aura_env.unholyBondRank == 0 then
                targetReduction = targetReduction * 0.98
            else
                targetReduction = targetReduction * (1 - 0.02 * (1 + (aura_env.unholyBondRank or 1) / 10))
            end
        end
        
        --- Paladin ---
    elseif aura_env.classID == 2 then
        if select(7, WA_GetUnitDebuff("target", 387174)) == "player" then -- Eye of Tyr
            targetReduction = targetReduction * 0.75
        end
        if aura_env.crusadersResolve then
            local _,_,stacks,_,_,_,source = WA_GetUnitDebuff("target", 383843)
            if source == "player" then -- Crusader's Resolve
                targetReduction = targetReduction * (1 - 0.02 * stacks)
            end
        end
        
        --- Demon Hunter ---
    elseif aura_env.classID == 12 then
        if aura_env.specID == 2 then -- Vengeance
            if select(7, WA_GetUnitDebuff("target", 207771)) == "player" then -- Fiery Brand
                targetReduction = targetReduction * 0.60
            end
            if aura_env.voidReaver then
                local _,_,stacks, _,_,_,source = WA_GetUnitDebuff("target", 247456)
                if source == "player" then -- Void Reaver
                    targetReduction = targetReduction * (1 - 0.04 * stacks)
                end
            end
            if select(7, WA_GetUnitDebuff("target", 394933)) == "player" then -- Demon Muzzle
                targetReduction = targetReduction * 0.92
            end
            if select(7, WA_GetUnitDebuff("target", 394958)) == "player" then -- T23 4-set
                targetReduction = targetReduction * 0.85
            end
        end
        
        --- Druid ---
    elseif aura_env.classID == 11 then
        if aura_env.specID == 3 then -- Guardian
            if aura_env.rendAndTear then -- Rend and Tear (guardian tree)
                local _,_,stacks,_,_,_,caster = WA_GetUnitDebuff("target", 192090)
                if caster == "player" then
                    targetReduction = targetReduction * (1 - 0.02 * (stacks or 1))
                end
            end
            if select(7, WA_GetUnitDebuff("target", 80313)) == "player" then -- Pulverize (guardian tree)
                targetReduction = targetReduction * 0.65
            end
            if select(7, WA_GetUnitDebuff("target", 135601)) == "player" then -- Tooth and Claw (guardian tree)
                targetReduction = targetReduction * 0.85
            end
            if aura_env.scintillatingMoonlight then
                if select(7, WA_GetUnitDebuff("target", 164812)) == "player" then  -- scintillating moonlight (guardian tree)
                    local rank = aura_env.findTalentRank(238049)
                    targetReduction = targetReduction * (1 - 0.05 * (rank or 1))
                end
            end
        end
        
        --- Monk ---
    elseif aura_env.classID == 10 then
        if aura_env.specID == 1 then -- Brewmaster
            local _,_,_,_,_,_,source,_,_,_,_,_,_,_,_,_,t1 = WA_GetUnitDebuff("target", 123725) -- Breath of Fire
            if source == "player" then
                if aura_env.blackoutCombo then
                    targetReduction = targetReduction * (1 + t1 / 100)
                else
                    targetReduction = targetReduction * 0.95
                end
            end
        end
        
        --- Warrior ---
    elseif aura_env.classID == 1 then
        if aura_env.specID == 3 then -- Protection
            if select(7, WA_GetUnitDebuff("target", 1160)) == "player" then -- Demoralizing Shout
                targetReduction = targetReduction * 0.80
            end
            if aura_env.punish then -- Punish
                local _,_,stacks,_,_,_,caster = WA_GetUnitDebuff("target", 192090)
                if caster == "player" then
                    targetReduction = targetReduction * (1 - 0.03 * (stacks or 1))
                end
            end
        end
    end
    
    targetReductionPhysical = targetReductionPhysical * targetReduction
    targetReductionMagic = targetReductionMagic * targetReduction
    
    if targetReductionPhysical ~= 1 or targetReductionMagic ~= 1 then
        aura_env.update = true
    end
    return targetReductionPhysical, targetReductionMagic
end

function aura_env.checkTargetAbsorb()
    local absorb = 0
    --- Paladin ---
    if aura_env.classID == 2 then
        if select(7, WA_GetUnitDebuff("target", 204301)) == "player" then -- blessed hammer
            absorb = select(17, WA_GetUnitDebuff("target", 204301))
        end
    end
    return absorb
end

function aura_env.checkBlock()
    local blockReduction = 0
    if aura_env.includeBlock then
        local blockChance = GetBlockChance()
        local blockAmount = GetShieldBlock()
        local block = 0
        local critBlock = 1
        local adjust = 1
        local K = 12827 -- +10 mythic plus (beta 10.0.2.46619)
        -- k = 11765 for normal mob, k = 15196 against other lv70 player
        if aura_env.classID == 1 then
            critBlock = 2
        end
        if aura_env.blockMode == 2 then
            if blockChance >= 100 then
                block = blockAmount / (blockAmount + K)
            end
        elseif aura_env.blockMode == 3 then
            if blockChance >= 100 then
                block = blockAmount / (blockAmount + K) * critBlock
            end
        elseif aura_env.blockMode == 4 then
            block = blockAmount / (blockAmount + K)
            adjust = blockChance / 100
        elseif aura_env.blockMode == 5 then
            block = blockAmount / (blockAmount + K) * 2
            adjust = blockChance / 100
        elseif aura_env.blockMode == 6 then
            block = blockAmount / (blockAmount + K)
        elseif aura_env.blockMode == 7 then
            block = blockAmount / (blockAmount + K) * critBlock
        end
        if adjust > 1 then adjust = 1 end
        blockReduction = block * adjust
    end
    return blockReduction
end

function aura_env.findTalentRank(spellID)
    local configId = C_ClassTalents.GetActiveConfigID()
    if configId then
        local configInfo = C_Traits.GetConfigInfo(configId)
        
        for _,treeId in pairs(configInfo.treeIDs) do
            local treeNodes = C_Traits.GetTreeNodes(treeId)
            for _,nodeId in pairs(treeNodes) do
                local nodeInfo = C_Traits.GetNodeInfo(configId, nodeId)
                for _, entryId in pairs(nodeInfo.entryIDs) do
                    local entryInfo = C_Traits.GetEntryInfo(configId, entryId)
                    local defId = entryInfo.definitionID
                    local defInfo = C_Traits.GetDefinitionInfo(defId)
                    if defInfo.spellID == spellID then
                        return nodeInfo.currentRank
                    end
                end
            end
        end
        
    end
end

aura_env.talentPhysical, aura_env.talentMagic = aura_env.checkTalents()
aura_env.maxHealth = UnitHealthMax("player")
aura_env.currentHealth, aura_env.healthBasedReduction = aura_env.checkHealth()
aura_env.buffPhysical, aura_env.buffMagic = aura_env.checkBuffs()
aura_env.debuffPhysical, aura_env.debuffMagic = aura_env.checkDebuffs()
aura_env.absorb = UnitGetTotalAbsorbs("player")
aura_env.targetAbsorb = aura_env.checkTargetAbsorb()
aura_env.staggerPhysical, aura_env.staggerMagic = aura_env.checkStagger()
aura_env.statsPhysical, aura_env.statsMagic = aura_env.checkStats()
aura_env.armor = aura_env.checkArmor()
aura_env.targetReductionPhysical, aura_env.targetReductionMagic = aura_env.checkTargetReduction()
aura_env.block = aura_env.checkBlock()
aura_env.channelReduction = aura_env.checkChannel()




-- Do not remove this comment, it is part of this aura: Effective Health - DF Mythic+ 
-- Dragonflight Version by Justbears-Illidan US


local decimals = aura_env.config.decimals - 1
local space = aura_env.config.space
if space then space = " " else space = "" end
aura_env.colorPhysical = CreateColor(unpack(aura_env.config.colorPhysical)):GenerateHexColor()
aura_env.colorMagic = CreateColor(unpack(aura_env.config.colorMagic)):GenerateHexColor()
aura_env.percentage = aura_env.config.advanced.percentage

aura_env.debug = false
aura_env.classID = select(3, UnitClass("player"))
aura_env.specID = GetSpecialization()
aura_env.necropolisReduction = 1
aura_env.turtle = false
aura_env.reductionHoly = 1
aura_env.reductionFire = 1
aura_env.reductionNature = 1
aura_env.reductionFrost = 1
aura_env.reductionShadow = 1
aura_env.reductionArcane = 1
aura_env.modifier = 1

-- Some default values used for preview
aura_env.currentHealth = 10^5
aura_env.maxHealth = 10^5
aura_env.reductionPhysical = 0.80
aura_env.reductionMagic = 1
aura_env.absorbPhysical = 0
aura_env.absorbMagic = 0
aura_env.armor = 0.80
aura_env.avoidance = 1
aura_env.staggerPhysical = 1
aura_env.staggerMagic = 1
aura_env.immunityPhysical = false
aura_env.immunityMagic = false
aura_env.conditionalReductions = false


local textFormat = ":"..space.."|c%s%."..decimals.."f%%|r"
if not aura_env.percentage then
    textFormat = ":"..space.."|c%s%."
end

local colorImmunity     = "ff0077ff" -- The color used if you have an immunity active
local colorHighHealth   = "ff00ff00" -- The color used if you will have >= 20% health left
local colorMediumHealth = "ffff8000" -- The color used if you will have >= 10% health left
local colorLowHealth    = "ffff0000" -- The color used if you will have < 10% health left

-- Returns formatted health based on percentage
function aura_env.numberFormat(health, multiplier, deci, immunity)
    if aura_env.percentage then
        if immunity then
            return string.format(textFormat, colorImmunity, health)
        elseif health >= 19.5 then
            return string.format(textFormat, colorHighHealth, health)
        elseif health >= 9.5 then
            return string.format(textFormat, colorMediumHealth, health)
        else
            return string.format(textFormat, colorLowHealth, health)
        end
    else
        local char = ""
        if health >= 10^12 or health <= -10^12 then
            char = "t"
        elseif health >= 10^9 or health <= -10^9 then
            char = "b"
        elseif health >= 10^6 or health <= -10^6 then
            char = "m"
        elseif health >= 10^3 or health <= -10^3 then
            char = "k"
        end
        if health >= 40000 then
            return string.format(textFormat..deci.."f"..char.."|r", colorHighHealth, health / multiplier)
        elseif health >= 10000 then
            return string.format(textFormat..deci.."f"..char.."|r", colorMediumHealth, health / multiplier)
        else
            return string.format(textFormat..deci.."f"..char.."|r", colorLowHealth, health / multiplier)
        end
    end
end

function aura_env.shorten(hp, immunity)
    local div, deci = 1, 2
    if hp >= 10^12 or hp <= -10^12 then
        div = 10^12
    elseif hp >= 10^9 or hp <= -10^9 then
        div = 10^9
    elseif hp >= 10^6 or hp <= -10^6 then
        div = 10^6
    elseif hp >= 10^3 or hp <= -10^3 then
        div = 10^3
    end
    if hp / div >= 100 or hp / div <= -100 then
        deci = 0
    elseif hp / div >= 10 or hp / div <= -10 then
        deci = 1
    end
    return aura_env.numberFormat(hp, div, deci, immunity)
end

aura_env.spellSchoolData = {
    0x1, -- physical
    0x01, -- holy
    0x04, -- fire
    0x08, -- nature
    0x10, -- frost
    0x20, -- shadow
    0x40, -- arcane
}

aura_env.auraCheck = {}
aura_env.castCheck = {}
aura_env.powerCheck = {}

for _,spells in pairs(aura_env.config.spells) do
    for _,v in pairs(spells) do
        -- separate the spells into catagories to reduce loop size
        if v.trigger == 1 then
            aura_env.auraCheck[#aura_env.auraCheck+1] = {
                display = v.name,
                npcId = v.npcId,
                spellId = v.spellId,
                school = v.school,
                damage = v.damage,
                aoe = v.aoe,
                ignoreArmor = v.armor,
                turtle = v.turtle,
            }
        elseif v.trigger == 2 then
            aura_env.castCheck[#aura_env.castCheck+1] = {
                display = v.name,
                npcId = v.npcId,
                spellId = v.spellId,
                school = v.school,
                damage = v.damage,
                aoe = v.aoe,
                ignoreArmor = v.armor,
                targeted = v.targeted,
                turtle = v.turtle,
            }
        elseif v.trigger == 3 then
            aura_env.powerCheck[#aura_env.powerCheck+1] = {
                display = v.name,
                npcId = v.npcId,
                spellId = v.spellId,
                school = v.school,
                damage = v.damage,
                aoe = v.aoe,
                ignoreArmor = v.armor,
                turtle = v.turtle,
            }
        end
    end
end

function aura_env.checkKey()
    aura_env.tyrannical = false
    aura_env.modifier = 1
    
    local keyLevel, keyAffix = C_ChallengeMode.GetActiveKeystoneInfo()
    if keyLevel then
        local keyMod = C_ChallengeMode.GetPowerLevelDamageHealthMod(keyLevel)
        aura_env.modifier = aura_env.modifier * (1 + keyMod / 100)
        for _,affix in pairs(keyAffix) do
            if affix == 9 then
                aura_env.tyrannical = true
            end
        end
    end
end

function aura_env.checkTalents()
    --- Death Knight ---
    if aura_env.classID == 6 then
        aura_env.necropolis = IsPlayerSpell(206967)
        aura_env.necropolisReduction = 1
        if aura_env.necropolis then
            local rank  = aura_env.findTalentRank(206967)
            if rank == 1 then
                aura_env.necropolisReduction = aura_env.necropolisReduction * 0.80
            elseif rank == 2 then
                aura_env.necropolisReduction = aura_env.necropolisReduction * 0.65
            end
        end
        aura_env.suppression = IsPlayerSpell(374049)
        --- Hunter ---
    elseif aura_env.classID == 3 then
        aura_env.huntersAvoidance = IsPlayerSpell(384799)
        --- Rogue ---
    elseif aura_env.classID == 4 then
        aura_env.elusiveness = IsPlayerSpell(79008)
        --- Warlock ---
    elseif aura_env.classID == 9 then
        aura_env.profaneBargain = IsPlayerSpell(389576)
    elseif aura_env.classID == 1 then
        aura_env.seasonedSoldier = IsPlayerSpell(279423)
    end
    
    --- Racial ---
    if IsPlayerSpell(20551) or IsPlayerSpell(20583) then -- tauran / night elf
        aura_env.reductionNature = aura_env.reductionNature * 0.99
    elseif IsPlayerSpell(20579) or IsPlayerSpell(59221) or IsPlayerSpell(255668) then -- undead / draenei / void elf
        aura_env.reductionShadow = aura_env.reductionShadow * 0.99
    elseif IsPlayerSpell(255664) or IsPlayerSpell(20592) or IsPlayerSpell(822) then -- nightborne / gnome / blood elf
        aura_env.reductionArcane = aura_env.reductionArcane * 0.99
    elseif IsPlayerSpell(312198) then -- vulpera
        aura_env.eductionFire = aura_env.reductionFire * 0.99
    elseif IsPlayerSpell (291417) then -- kul tiran
        aura_env.reductionFrost = aura_env.reductionFrost * 0.99
        aura_env.reductionNature = aura_env.reductionNature * 0.99
    elseif IsPlayerSpell(20596) then -- dwarf
        aura_env.reductionFrost = aura_env.reductionFrost * 0.99
    elseif IsPlayerSpell(255651) then -- lightforged draenei
        aura_env.reductionHoly = aura_env.reductionHoly * 0.99
    elseif IsPlayerSpell(68976) then -- worgen
        aura_env.reductionShadow = aura_env.reductionShadow * 0.99
        aura_env.reductionNature = aura_env.reductionNature * 0.99
    end
end


function aura_env.checkModifier(unit, spellDamage, spellId)
    local damage = spellDamage or 0
    local multiplier = aura_env.modifier
    if aura_env.tyrannical then
        multiplier = multiplier * 1.15
    end
    
    if UnitExists(unit) then
        if WA_GetUnitDebuff(unit, 209859) then -- Bolster Affix
            multiplier = multiplier * 1.2
        elseif WA_GetUnitDebuff(unit, 228318) then -- Raging Affix
            multiplier = multiplier * 1.5
            -- elseif spellId == 0 and WA_GetUnitDebuff(unit, 0) then -- Sadana // Dark Communion
        end
    end
    
    if spellId == 377004 and WA_GetUnitDebuff("player", 397210) then -- Crawth // Sonic Vulnerability
        local stacks = select(3, WA_GetUnitDebuff("player", 397210))
        multiplier = multiplier * (1 + 0.5 * (stacks or 1))
    -- if lava spray and magmatusk has magma tentacle stacks
    elseif spellId == 375251 and WA_GetUnitBuff("target", 374410) then
        -- check for the stacks and apply the multiplier to the damage
        local stacks = select(3, WA_GetUnitBuff("target", 374410))
        multiplier = multiplier * stacks
    end
    return damage * multiplier
end

function aura_env.findTalentRank(spellID)
    local configId = C_ClassTalents.GetActiveConfigID()
    local configInfo = C_Traits.GetConfigInfo(configId)
    
    for _,treeId in pairs(configInfo.treeIDs) do
        local treeNodes = C_Traits.GetTreeNodes(treeId)
        for _,nodeId in pairs(treeNodes) do
            local nodeInfo = C_Traits.GetNodeInfo(configId, nodeId)
            for _, entryId in pairs(nodeInfo.entryIDs) do
                local entryInfo = C_Traits.GetEntryInfo(configId, entryId)
                local defId = entryInfo.definitionID
                local defInfo = C_Traits.GetDefinitionInfo(defId)
                if defInfo.spellID == spellID then
                    return nodeInfo.currentRank
                end
            end
        end
    end
end

function aura_env.updateDamage(ability, spellDamage, school, aoe, ignoreArmor, turtle)
    
    if spellDamage ~= 0 then
        -- Avoidance adjustments
        local removeAvoidance = 1
        if not aoe then
            removeAvoidance = removeAvoidance / aura_env.avoidance
            if aura_env.feintBuff and aura_env.elusiveness then -- Elusiveness
                removeAvoidance = removeAvoidance * 0.60
            elseif aura_env.huntersAvoidance then
                removeAvoidance = removeAvoidance * 0.94
            end
            if aura_env.zephyrBuff then
                removeAvoidance = removeAvoidance * 0.80
            end
            if aura_env.suppression then
                removeAvoidance = removeAvoidance * 0.97
            end
            if aura_env.generousPour then
                removeAvoidance = removeAvoidance * (1 + aura_env.generousPourTooltip / 100)
            end
            if aura_env.seasonedSoldier then
                removeAvoidance = removeAvoidance * 0.90
            end
        end
        
        -- Hunter Immunity
        local immunityPhysical = aura_env.immunityPhysical
        local immunityMagic = aura_env.immunityMagic
        if turtle and aura_env.turtle then
            immunityMagic = true
            immunityPhysical = true
        end
        
        local remainingPhysical, remainingMagic
        local result
        if school == 1 then
            local reductionPhysical = aura_env.reductionPhysical * aura_env.avoidance * removeAvoidance
            local absorbPhysical = aura_env.absorbPhysical
            if ignoreArmor then
                reductionPhysical = reductionPhysical / aura_env.armor
            end
            local EHP = aura_env.currentHealth / reductionPhysical
            
            if aura_env.classID == 10 then -- Monk
                if aura_env.dampenHarmBuff then -- Dampen Harm
                    reductionPhysical = reductionPhysical / 0.80 / aura_env.staggerPhysical -- Remove some reductions
                    -- Reduction scales linearly with the size of the hit relative to max health
                    local hitSizePhysical = reductionPhysical * spellDamage / aura_env.maxHealth
                    if hitSizePhysical > 1 then hitSizePhysical = 1 end
                    local dampenHarmPhysical = 0.8 - 0.3 * hitSizePhysical
                    reductionPhysical = reductionPhysical * dampenHarmPhysical * aura_env.staggerPhysical
                end
                
            elseif aura_env.classID == 6 then -- Death Knight
                if aura_env.necropolis and aura_env.currentHealth / aura_env.maxHealth * 100 >= 30 then
                    local abs = absorbPhysical / reductionPhysical
                    local maxEH = aura_env.maxHealth / reductionPhysical
                    local damage = spellDamage - abs
                    local absorbed = spellDamage - damage
                    if (EHP - damage) / maxEH * 100 < 30 then
                        local dmgPercent = 30 - ((EHP - damage) / maxEH * 100)
                        local expectedReduction = damage - (damage - (dmgPercent / 100) * maxEH * aura_env.necropolisReduction)
                        local notReduced = EHP / maxEH * 100 - 30
                        spellDamage = notReduced * maxEH / 100 + expectedReduction + absorbed
                    end
                end
                
            elseif aura_env.classID == 9 then -- Warlock
                if aura_env.profaneBargain and UnitExists("pet") and aura_env.currentHealth / aura_env.maxHealth * 100 >= 35 then
                    local abs = absorbPhysical / reductionPhysical
                    local maxEH = aura_env.maxHealth / reductionPhysical
                    local damage = spellDamage - abs
                    local absorbed = spellDamage - damage
                    if (EHP - damage) / maxEH * 100 < 35 then
                        local dmgPercent = 35 - ((EHP - damage) / maxEH * 100)
                        local expectedReduction = damage - (damage - (dmgPercent / 100) * maxEH * aura_env.profaneBargainReductionReduction)
                        local notReduced = EHP / maxEH * 100 - 35
                        aura_env.damage = notReduced * maxEH / 100 + expectedReduction + absorbed
                    end
                end
            end
            
            if aura_env.percentage then
                local afterAbsorbPhysical = spellDamage - absorbPhysical / reductionPhysical
                if afterAbsorbPhysical < 0 then afterAbsorbPhysical = 0 end
                remainingPhysical = (aura_env.currentHealth / reductionPhysical - afterAbsorbPhysical) / (aura_env.maxHealth / reductionPhysical) * 100
                remainingPhysical = aura_env.numberFormat(remainingPhysical, 1, 0, immunityPhysical)
            else
                local afterAbsorbPhysical = spellDamage - absorbPhysical / reductionPhysical
                remainingPhysical = aura_env.currentHealth / reductionPhysical - afterAbsorbPhysical
                remainingPhysical = aura_env.shorten(remainingPhysical, aura_env.immunityPhysical)
            end
            
            result = "|c"..aura_env.colorPhysical..ability.."|r"..remainingPhysical.."\n"
            
        else
            local reductionMagic = aura_env.reductionMagic * aura_env.avoidance * removeAvoidance
            local absorbMagic = aura_env.absorbMagic
            local EHM = aura_env.currentHealth / reductionMagic
            
            if aura_env.classID == 10 then -- Monk
                if aura_env.dampenHarmBuff then -- Dampen Harm
                    reductionMagic = reductionMagic / 0.80 / aura_env.staggerMagic -- Remove some reductions
                    -- Reduction scales linearly with the size of the hit relative to max health
                    local hitSizeMagic = reductionMagic * spellDamage / aura_env.maxHealth
                    if hitSizeMagic > 1 then hitSizeMagic = 1 end
                    local dampenHarmMagic = 0.8 - 0.3 * hitSizeMagic
                    reductionMagic = reductionMagic * dampenHarmMagic * aura_env.staggerMagic
                end
            elseif aura_env.classID == 6 then -- Death Knight
                local abs = absorbMagic / reductionMagic
                local maxEH = aura_env.maxHealth / reductionMagic
                local damage = spellDamage - abs
                local absorbed = spellDamage - damage
                if (EHM - damage) / maxEH * 100 < 30 then
                    local dmgPercent = 30 - ((EHM - damage) / maxEH * 100)
                    local expectedReduction = damage - (damage - (dmgPercent / 100) * maxEH * aura_env.necropolisReduction)
                    local notReduced = EHM / maxEH * 100 - 30
                    spellDamage = notReduced * maxEH / 100 + expectedReduction + absorbed
                end
                
            elseif aura_env.classID == 9 then -- Warlock
                local abs = absorbMagic / reductionMagic
                local maxEH = aura_env.maxHealth / reductionMagic
                local damage = spellDamage - abs
                local absorbed = spellDamage - damage
                if (EHM - damage) / maxEH * 100 < 35 then
                    local dmgPercent = 35 - ((EHM - damage) / maxEH * 100)
                    local expectedReduction = damage - (damage - (dmgPercent / 100) * maxEH * aura_env.profaneBargainReductionReduction)
                    local notReduced = EHM / maxEH * 100 - 35
                    aura_env.damage = notReduced * maxEH / 100 + expectedReduction + absorbed
                end
            end
            
            if school == 2 then
                reductionMagic = reductionMagic * aura_env.reductionHoly
            elseif school == 3 then
                reductionMagic = reductionMagic * aura_env.reductionFire
            elseif school == 4 then
                reductionMagic = reductionMagic * aura_env.reductionNature
            elseif school == 5 then
                reductionMagic = reductionMagic * aura_env.reductionFrost
            elseif school == 6 then
                reductionMagic = reductionMagic * aura_env.reductionShadow
            elseif school == 7 then
                reductionMagic = reductionMagic * aura_env.reductionArcane
            end
            
            if aura_env.percentage then
                local afterAbsorbMagic = spellDamage - absorbMagic / reductionMagic
                if afterAbsorbMagic < 0 then afterAbsorbMagic = 0 end
                remainingMagic = (aura_env.currentHealth / reductionMagic - afterAbsorbMagic) / (aura_env.maxHealth / reductionMagic) * 100
                remainingMagic = aura_env.numberFormat(remainingMagic, 1, 0, immunityMagic)
            else
                local afterAbsorbMagic = spellDamage - absorbMagic / reductionMagic
                remainingMagic = aura_env.currentHealth / reductionMagic - afterAbsorbMagic
                remainingMagic = aura_env.shorten(remainingMagic, aura_env.immunityMagic)
            end
            
            result = "|c"..aura_env.colorMagic..ability.."|r"..remainingMagic.."\n"
        end
        
        return result
    end
end

function aura_env.checkUnit(unitGUID)
    for i=1,40 do
        if unitGUID == UnitGUID("boss"..i) then
            return "boss"..i
        elseif unitGUID == UnitGUID("target"..i) then
            return "target"
        elseif unitGUID == UnitGUID("nameplate"..i) then
            return "nameplate"..i
        end
    end
end

aura_env.checkKey()
aura_env.checkTalents()
