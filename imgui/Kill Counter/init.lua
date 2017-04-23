-- Author: Stephen Wills (https://github.com/Solybum)
-- From: PSOBBMod-Addons (https://github.com/StephenCWills/PSOBBMod-Addons)
-- License: GPL-3.0 (https://github.com/StephenCWills/PSOBBMod-Addons/blob/master/LICENSE)

-- This addon copies files from the lib folder of Soly's
-- PSOBBMod-Addons project so that this addon will remain
-- compatible with his addons as he continues making
-- changes. Appropriate attribution is provided in
-- the comment block the top of each file.
helpers = require("Kill Counter.helpers")
unitxt = require("Kill Counter.Unitxt")
monsters = require("Kill Counter.Monsters")

cfgFileName = "kill-counters.txt"
cfgFontColor = 0xFFFFFFFF
cfgFontSize = 1.0

_PlayerCount = 0x00AAE168
_Difficulty = 0x00A9CD68
_Episode = 0x00A9B1C8
_Area = 0x00AC9CF8

_MonsterCount = 0x00AAE164
_MonsterArray = 0x00AAD720

_MonsterPosX = 0x38
_MonsterPosY = 0x3C
_MonsterPosZ = 0x40
_MonsterID = 0x378
_MonsterHP = 0x334
_MonsterHPMax = 0x2BC

_MonsterTable = {}
_KillTable = {}

local function readMonsters()
    difficulty = pso.read_u32(_Difficulty)
    episode = pso.read_u32(_Episode)
    area = pso.read_u32(_Area)
    killTableKey = string.format("%d,%d,%d", difficulty, episode, area)
    killTable = _KillTable[killTableKey] or {}
    
    playerCount = pso.read_u32(_PlayerCount)
    monsterCount = pso.read_u32(_MonsterCount)
    monsterTable = {}
    modified = false

    for i=1,monsterCount,1 do
        mAddr = pso.read_u32(_MonsterArray + 4 * (i - 1 + playerCount))

        if mAddr ~= 0 then
            mID = pso.read_u32(mAddr + _MonsterID)

            if mID ~= 0 then
                --mPosX = pso.read_f32(mAddr + _MonsterPosX)
                --mPosY = pso.read_f32(mAddr + _MonsterPosY)
                --mPosZ = pso.read_f32(mAddr + _MonsterPosZ)
                mHP = pso.read_u16(mAddr + _MonsterHP)
                --mHPMax = pso.read_u16(mAddr + _MonsterHPMax)
                
                monsterTable[mAddr] = mHP
                
                if mHP == 0 and _MonsterTable[mAddr] and _MonsterTable[mAddr] ~= 0 then
                    if killTable[mID] == nil then
                        killTable[mID] = 1
                    else
                        killTable[mID] = killTable[mID] + 1
                    end
                    
                    modified = true
                end
                
                -- Rappies get back up after they are killed so we
                -- can't indiscriminately update the monster table
                if _MonsterTable[mAddr] == 0 then
                    monsterTable[mAddr] = 0
                end
            end
        end
    end
    
    _MonsterTable = monsterTable

    imgui.Columns(2)
    helpers.imguiTextLine("Monster", 0xFFFFFFFF)
    imgui.NextColumn()
    helpers.imguiTextLine("Kills", 0xFFFFFFFF)
    imgui.NextColumn()

    for mID,killCount in pairs(killTable) do
        mName = unitxt.ReadMonsterName(mID, difficulty)
        mColor = 0xFFFFFFFF
        mDisplay = true

        if monsters.m[mID] ~= nil then
            mColor = monsters.m[mID][1]
            mDisplay = monsters.m[mID][2]
        end
        
        if mDisplay == true then
            helpers.imguiTextLine(string.format("%s", mName), mColor)
            imgui.NextColumn()
            helpers.imguiTextLine(string.format("%d", killCount), cfgFontColor)
            imgui.NextColumn()
        end
    end
        
    if modified then
        _KillTable[killTableKey] = killTable
    
        file = io.open(cfgFileName, "w+")
        io.output(file)
        
        for killTableKey,killTable in pairs(_KillTable) do
            for mID,killCount in pairs(killTable) do
                io.write(string.format("%s,%d,%d\n", killTableKey, mID, killCount))
            end
        end
        
        io.close(file)
    end
end

local present = function()
    imgui.Begin("Kill Counter")
    imgui.SetWindowFontScale(cfgFontSize)
    
    if imgui.Button("Reset") then
        file = io.open(cfgFileName, "w+")
        io.close(file)
        _KillTable = {}
    end
    
    readMonsters()
    imgui.End()
end

local init = function()
    pattern = "(%d+),(%d+),(%d+),(%d+),(%d+)"
    file = io.open(cfgFileName, "r")
    io.input(file)
    
    for difficulty,episode,area,mID,killCount in string.gfind(io.read("*all"), pattern) do
        killTableKey = string.format("%s,%s,%s", difficulty, episode, area)
        killTable = _KillTable[killTableKey] or {}
        
        mID = tonumber(mID)
        killCount = tonumber(killCount)
        killTable[mID] = killCount
        _KillTable[killTableKey] = killTable
    end
    
    io.close(file)

    return 
    {
        name = "Kill Counter",
        version = "1.0.0",
        author = "staphen"
    }
end

pso.on_init(init)
pso.on_present(present)

return {
    init = init,
    present = present,
}

