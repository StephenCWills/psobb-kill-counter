-- Author: Stephen Wills (https://github.com/StephenCWills)
-- From: PSOBBMod-Addons (https://github.com/StephenCWills/psobb-kill-counter)
-- License: GPL-3.0 (https://github.com/StephenCWills/psobb-kill-counter/blob/master/LICENSE)

-- This addon copies files from the lib folder of Soly's
-- PSOBBMod-Addons project so that this addon will remain
-- compatible with his addons as he continues making
-- changes. Appropriate attribution is provided in
-- the comment block the at top of each file.
local helpers = require("Kill Counter.helpers")
local unitxt = require("Kill Counter.Unitxt")

local difficulties = require("Kill Counter.difficulties")
local episodes = require("Kill Counter.episodes")
local sectionIDs = require("Kill Counter.section-ids")
local areas = require("Kill Counter.areas")
local monsters = require("Kill Counter.Monsters")

local cfgFileName = "kill-counters.txt"
local cfgExportFileName = "kill-counters-export.txt"
local cfgFontColor = 0xFFFFFFFF
local cfgFontSize = 1.0

local _PlayerCount = 0x00AAE168
local _Difficulty = 0x00A9CD68
local _Episode = 0x00A9B1C8
local _Area = 0x00AC9CF8
local _SectionID = 0x00A9C4D8

local _MonsterCount = 0x00AAE164
local _MonsterArray = 0x00AAD720

local _MonsterPosX = 0x38
local _MonsterPosY = 0x3C
local _MonsterPosZ = 0x40
local _MonsterID = 0x378
local _MonsterHP = 0x334
local _MonsterHPMax = 0x2BC

local _CurrentDifficulty = 0
local _CurrentEpisode = 0
local _CurrentSectionID = 0
local _CurrentArea = 0

local _MonsterTable = {}
local _AllCounters = {}
local _VisibleCounters = {}
local _CountersByID = {}

local function GetCounterOrder(counter1, counter2)
    if counter1.difficulty ~= counter2.difficulty then
        return counter1.difficulty < counter2.difficulty
    end

    if counter1.episode ~= counter2.episode then
        return counter1.episode < counter2.episode
    end

    if counter1.sectionID ~= counter2.sectionID then
        return counter1.sectionID < counter2.sectionID
    end

    if counter1.area ~= counter2.area then
        return counter1.area < counter2.area
    end

    return counter1.monsterName < counter2.monsterName
end

local function GetVisibleCounter(areaCounter)
    local matchedCounters = {}
    local visibleCounter = {}

    local i
    local counter

    for i,counter in ipairs(_AllCounters) do
        local isMatch =
            counter.difficulty == areaCounter.difficulty and
            counter.episode == areaCounter.episode and
            counter.sectionID == areaCounter.sectionID and
            counter.monsterID == areaCounter.monsterID

        if isMatch then
            table.insert(matchedCounters, counter)
        end
    end

    for k,v in pairs(areaCounter) do
        visibleCounter[k] = v
    end

    visibleCounter.kills = function()
        local sum = 0

        for i,counter in ipairs(matchedCounters) do
            sum = sum + counter.kills
        end

        return sum
    end

    return visibleCounter
end

local function BuildAllCounters()
    _AllCounters = {}

    local file = io.open(cfgFileName, "a")
    io.close(file)

    local pattern = "(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)"
    file = io.open(cfgFileName, "r")
    io.input(file)

    local difficulty
    local episode
    local sectionID
    local area
    local monsterID
    local kills

    for difficulty,episode,sectionID,area,monsterID,kills in string.gfind(io.read("*all"), pattern) do
        difficulty = tonumber(difficulty)
        episode = tonumber(episode)
        sectionID = tonumber(sectionID)
        area = tonumber(area)
        monsterID = tonumber(monsterID)
        kills = tonumber(kills)

        local counter = {
            difficulty = difficulty,
            episode = episode,
            sectionID = sectionID,
            area = area,
            monsterID = monsterID,
            monsterName = unitxt.GetMonsterName(monsterID, difficulty == 3),
            monsterColor = (monsters.m[monsterID] or { 0xFFFFFFFF })[1],
            kills = kills
        }

        table.insert(_AllCounters, counter)
    end

    io.close(file)
end

local function BuildVisibleCounters()
    _VisibleCounters = {}

    local difficulty = pso.read_u32(_Difficulty)
    local episode = pso.read_u32(_Episode)
    local sectionID = pso.read_u32(_SectionID)
    local area = pso.read_u32(_Area)

    local visibleTable = {}
    local i
    local counter

    for i,counter in ipairs(_AllCounters) do
        local isMatch =
            counter.difficulty == difficulty and
            counter.episode == episode and
            counter.sectionID == sectionID and
            counter.area == area

        if isMatch then
            table.insert(_VisibleCounters, GetVisibleCounter(counter))
        end
    end

    table.sort(_VisibleCounters, GetCounterOrder)
end

local function BuildCountersByID()
    _CountersByID = {}

    local difficulty = pso.read_u32(_Difficulty)
    local episode = pso.read_u32(_Episode)
    local sectionID = pso.read_u32(_SectionID)
    local area = pso.read_u32(_Area)

    local i
    local counter

    for i,counter in ipairs(_AllCounters) do
        local isMatch =
            counter.difficulty == difficulty and
            counter.episode == episode and
            counter.sectionID == sectionID and
            counter.area == area

        if isMatch then
            _CountersByID[counter.monsterID] = counter
        end
    end
end

local function GetMonsterTable()
    local i
    local monsterTable = {}

    local playerCount = pso.read_u32(_PlayerCount)
    local entityCount = pso.read_u32(_EntityCount)

    for i=1,entityCount,1 do
        local mAddr = pso.read_u32(_EntityArray + 4 * (i - 1 + playerCount))

        -- If we got a pointer, then read from it
        if mAddr ~= 0 then
            -- Get monster data
            local mUnitxtID = pso.read_u32(mAddr + _MonsterUnitxtID)
            local mHP = pso.read_u16(mAddr + _MonsterHP)
            local mSlain = mHP == 0 or (_MonsterTable[mAddr] ~= nil and _MonsterTable[mAddr].slain)

            monsterTable[mAddr] = { id = mUnitxtID, slain = mSlain }
        end
    end

    return monsterTable
end

local function UpdateKillTable(monsterTable)
    local difficulty = pso.read_u32(_Difficulty)
    local episode = pso.read_u32(_Episode)
    local sectionID = pso.read_u32(_SectionID)
    local area = pso.read_u32(_Area)
    local tableModified = false

    local mAddr
    local monster

    for mAddr,monster in pairs(monsterTable) do
        local incrementCounter =
            monsterTable[mAddr].slain and
            _MonsterTable[mAddr] ~= nil and
            not _MonsterTable[mAddr].slain

        if incrementCounter then
            if _CountersByID[monster.id] then
                _CountersByID[monster.id].kills = _CountersByID[monster.id].kills + 1
            else
                local counter = {
                    difficulty = difficulty,
                    episode = episode,
                    sectionID = sectionID,
                    area = area,
                    monsterID = monster.id,
                    monsterName = unitxt.GetMonsterName(monster.id, difficulty == 3),
                    monsterColor = (monsters.m[monster.id] or { 0xFFFFFFFF })[1],
                    kills = 1
                }

                table.insert(_AllCounters, counter)
                table.insert(_VisibleCounters, GetVisibleCounter(counter))
                table.sort(_VisibleCounters, GetCounterOrder)
                _CountersByID[monster.id] = counter
            end

            tableModified = true
        end
    end

    if tableModified then
        local i
        local counter
        local file = io.open(cfgFileName, "w+")
        io.output(file)

        for i,counter in pairs(_AllCounters) do
            io.write(string.format("%d,%d,%d,%d,%d,%d\n", counter.difficulty, counter.episode, counter.sectionID, counter.area, counter.monsterID, counter.kills))
        end

        io.close(file)
    end

    return tableModified
end

local function PrintCounters(monsterTable)
    local i
    local counter

    imgui.Columns(2)
    helpers.imguiText("Monster", cfgFontColor, true)
    imgui.NextColumn()
    helpers.imguiText("Kills", cfgFontColor, true)
    imgui.NextColumn()

    for i,counter in ipairs(_VisibleCounters) do
        local display = monsters.m[counter.monsterID] == nil or monsters.m[counter.monsterID][2]

        if display then
            helpers.imguiText(string.format("%s", counter.monsterName), counter.monsterColor, true)
            imgui.NextColumn()
            helpers.imguiText(string.format("%d", counter.kills()), cfgFontColor, true)
            imgui.NextColumn()
        end
    end
end

local function ExportCounters()
    local lineFormat = "%-10s  ||  %-7s  ||  %-10s  ||  %-22s  ||  %-16s  ||  %s\n";
    local file = io.open(cfgExportFileName, "w+")
    io.output(file)

    io.write(string.format(lineFormat, "Difficulty", "Episode", "Section ID", "Area", "Monster", "Kill Count"))
    io.write(string.format(lineFormat, "----------", "-------", "----------", "----", "-------", "----------"))

    table.sort(_AllCounters, GetCounterOrder)

    for i,counter in ipairs(_AllCounters) do
        difficulty = difficulties.d[counter.difficulty] or string.format("Unknown (%d)", counter.difficulty)
        episode = episodes.e[counter.episode] or string.format("Unknown (%d)", counter.episode)
        sectionID = sectionIDs.ids[counter.sectionID] or string.format("Unknown (%d)", counter.sectionID)
        area = areas.a[counter.area] or string.format("Unknown (%d)", counter.area)
        monster = counter.monsterName

        io.write(string.format(lineFormat,
            difficulty,
            episode,
            sectionID,
            area,
            monster,
            string.format("%d", counter.kills)))
    end

    io.close(file)
end

local function AreaHasChanged()
    local difficulty = pso.read_u32(_Difficulty)
    local episode = pso.read_u32(_Episode)
    local sectionID = pso.read_u32(_SectionID)
    local area = pso.read_u32(_Area)

    local areaHasChanged =
        difficulty ~= _CurrentDifficulty or
        episode ~= _CurrentEpisode or
        sectionID ~= _CurrentSectionID or
        area ~= _CurrentArea

    _CurrentDifficulty = difficulty
    _CurrentEpisode = episode
    _CurrentSectionID = sectionID
    _CurrentArea = area

    return areaHasChanged
end

local present = function()
    imgui.Begin("Kill Counter")
    imgui.SetWindowFontScale(cfgFontSize)

    if imgui.Button("Reset") then
        local file = io.open(cfgFileName, "w+")
        io.close(file)

        _AllCounters = {}
        _VisibleCounters = {}
        _CountersByID = {}
    end

    imgui.SameLine(0, 5)

    if imgui.Button("Save to file") then
        ExportCounters()
    end

    if AreaHasChanged() then
        BuildVisibleCounters()
        BuildCountersByID()
    end

    local monsterTable = GetMonsterTable()
    UpdateKillTable(monsterTable)
    PrintCounters(monsterTable)
    _MonsterTable = monsterTable

    imgui.End()
end

local init = function()
    BuildAllCounters()
    BuildVisibleCounters()
    BuildCountersByID()

    return
    {
        name = "Kill Counter",
        version = "1.1.0",
        author = "staphen"
    }
end

pso.on_init(init)
pso.on_present(present)

return {
    init = init,
    present = present,
}

