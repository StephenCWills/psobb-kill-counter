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

local _EntityCount = 0x00AAE164
local _EntityArray = 0x00AAD720

local _MonsterUnitxtID = 0x378
local _MonsterHP = 0x334
local _MonsterDeRolLeHP = 0x6B4
local _MonsterBarbaRayHP = 0x704
local _MonsterState = 0x32F

local _DubwitchObjectCode = 0x00B267C0
local _VolOptStage2ObjectCode = 0x00AF6220
local _FalzStage2ObjectCode = 0x00AF77E0
local _FalzStage3ObjectCode = 0x00AF7A60
local _GolDragonObjectCode = 0x00AFB860
local _OlgaStage2ObjectCode = 0x00AF9A00

local _CurrentDifficulty = 0
local _CurrentEpisode = 0
local _CurrentSectionID = 0
local _CurrentArea = 0

local _MonsterTable = {}
local _AllCounters = {}
local _VisibleCounters = {}
local _CountersByID = {}

local _PanArms = {}
local _Dubwitch = {}
local _SaintMilion = {}

local _SortVisibleCounters = false
local _DetailWindowOpen = false

local function GetArea()
    local area = pso.read_u32(_Area)

    -- Convert Dark Falz' area to Ruins
    if area == 4 then
        area = 3
    end

    return area
end

local function GetMonsterName(counter)
    if counter.monsterName == nil then
        counter.monsterName = unitxt.GetMonsterName(counter.monsterID, counter.difficulty == 3)

        if counter.monsterName == "Unknown" then
            counter.monsterName = string.format("Unknown (%d)", counter.monsterID)
        end

        if counter.monsterName ~= nil then
            _SortVisibleCounters = true
        end
    end

    return counter.monsterName or string.format("%d", counter.monsterID)
end

local function GetMonsterHP(monster)
    if monster.id == 45 then
        return pso.read_u16(monster.address + _MonsterDeRolLeHP)
    elseif monster.id == 73 then
        return pso.read_u16(monster.address + _MonsterBarbaRayHP)
    else
        return pso.read_u16(monster.address + _MonsterHP)
    end
end

local function IsSlain(monster)
    local difficulty = pso.read_u32(_Difficulty)
    local mAddr = monster.address
    local mSlain = monster.hp == 0

    -- If monster has already been recorded as
    -- having been slain, then it is still slain
    if _MonsterTable[mAddr] ~= nil and _MonsterTable[mAddr].slain then
        return true
    end

    -- Many NPCs have ID of zero
    if monster.id == 0 then
        mSlain = false
    end

    -- Because Poison Lily suicide does not bring HP
    -- to zero, we need to check the monster state
    if monster.id == 13 or monster.id == 14 or monster.id == 83 then
        local mState = pso.read_u16(mAddr + _MonsterState)
        mSlain = mSlain or mState == 0x0A
    end

    -- Pan Arms HP is updated when damage is done
    -- to Hidoom and Migium, but not vice-versa
    if monster.id == 21 then
        _PanArms = monster
    elseif monster.id == 22 and mSlain then
        _PanArms.slain = false
    elseif monster.id == 23 and mSlain then
        _PanArms.slain = false
    end

    -- Individual Dubchics must be slain five
    -- times before being truly slain
    if monster.id == 24 then
        local slainCount = pso.read_u16(mAddr + 0x394)

        if slainCount < 5 then
            mSlain = false
        end
    end

    -- Keep track of slain Dubwitches to
    -- set slain state of Dubchics later
    if monster.id == 49 and mSlain then
        table.insert(_Dubwitch, monster)
    end

    -- Only count De Rol Le's body, not his shells
    if monster.id == 45 and monster.index ~= 1 then
        mSlain = false
    end

    -- Only count Barba Ray's body, not his shells
    if monster.id == 73 and monster.index ~= 1 then
        mSlain = false
    end

    -- Only count Vol Opt's final form
    if monster.id == 46 then
        local objectCodeOffset = pso.read_u32(mAddr)

        if objectCodeOffset ~= _VolOptStage2ObjectCode then
            mSlain = false
        end
    end

    -- Only count when last stage of Dark Falz is slain
    if monster.id == 47 then
        local objectCodeOffset = pso.read_u32(mAddr)

        if difficulty == 0 and objectCodeOffset ~= _FalzStage2ObjectCode then
            mSlain = false
        elseif difficulty ~= 0 and objectCodeOffset ~= _FalzStage3ObjectCode then
            mSlain = false
        end
    end

    -- Don't count kills for copies of the Gol Dragon
    if monster.id == 76 then
        local objectCodeOffset = pso.read_u32(mAddr)

        if objectCodeOffset ~= _GolDragonObjectCode then
            mSlain = false
        end
    end

    -- Only count when last stage of Olga Flow is slain
    if monster.id == 78 then
        local objectCodeOffset = pso.read_u32(mAddr)

        if objectCodeOffset ~= _OlgaStage2ObjectCode then
            mSlain = false
        end
    end

    -- Saint-Milion and his variants require special
    -- logic to be applied after building the monster table
    if monster.id == 106 or monster.id == 107 or monster.id == 108 then
        table.insert(_SaintMilion, monster)
    end

    return mSlain
end

local function SetDubchicsSlain(monsterTable, dubwitch)
    local _, monster
    local dubwitchWave = pso.read_u32(dubwitch.address + 0x28)

    for _,monster in pairs(monsterTable) do
        if monster.id == 24 then
            local dubchicWave = pso.read_u32(monster.address + 0x28)

            if dubchicWave == dubwitchWave then
                monster.slain = true
            end
        end
    end
end

local function IsSaintMilionSlain()
    local slain = 0

    for i,monster in ipairs(_SaintMilion) do
        if i <= 4 and monster.slain then
            slain = slain + 1
        end

        monster.slain = false
    end

    return slain == 4
end

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

    return GetMonsterName(counter1) < GetMonsterName(counter2)
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
    local area = GetArea()

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
    local area = GetArea()

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

    _Dubwitch = {}
    _SaintMilion = {}

    for i=1,entityCount do
        local monster = {}

        monster.index = i
        monster.address = pso.read_u32(_EntityArray + 4 * (i - 1 + playerCount))

        if monster.address ~= 0 then
            local objectCodeOffset = pso.read_u32(monster.address)

            monster.id = pso.read_u32(monster.address + _MonsterUnitxtID)

            -- Dubwitches have an id of zero so we force it to 49
            -- instead, which is where the Dubwitch unitxt data is
            if objectCodeOffset == _DubwitchObjectCode then
                monster.id = 49
            end

            monster.hp = GetMonsterHP(monster)
            monster.slain = IsSlain(monster)
            monsterTable[monster.address] = monster
        end
    end

    -- Apply logic to set slain state of Dubchics based
    -- on slain state of the corresponding Dubwitch
    local _, dubwitch

    for _,dubwitch in ipairs(_Dubwitch) do
        SetDubchicsSlain(monsterTable, dubwitch)
    end

    -- Apply logic to determine whether to
    -- increment the kill counter for Saint-Milion
    if IsSaintMilionSlain() then
        _SaintMilion[1].slain = true
    end

    return monsterTable
end

local function UpdateKillTable(monsterTable)
    local difficulty = pso.read_u32(_Difficulty)
    local episode = pso.read_u32(_Episode)
    local sectionID = pso.read_u32(_SectionID)
    local area = GetArea()
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

    if _SortVisibleCounters then
        table.sort(_VisibleCounters, GetCounterOrder)
        _SortVisibleCounters = false
    end

    for i,counter in ipairs(_VisibleCounters) do
        local display = monsters.m[counter.monsterID] == nil or monsters.m[counter.monsterID][2]

        if display then
            helpers.imguiText(GetMonsterName(counter), counter.monsterColor, true)
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
        monster = GetMonsterName(counter)

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
    local area = GetArea()

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

local function ShowMainWindow()
    imgui.SetNextWindowSize(270, 380, 'FirstUseEver')
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

    if imgui.Button("Details...") then
        _DetailWindowOpen = not _DetailWindowOpen
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

local function ShowDetailWindow()
    local success

    if not _DetailWindowOpen then
        return
    end

    imgui.SetNextWindowSize(800, 400, 'FirstUseEver')
    success,_DetailWindowOpen = imgui.Begin("Kill Counter Detail", _DetailWindowOpen)
    imgui.SetWindowFontScale(cfgFontSize)

    success,cfgExportFileName = imgui.InputText("", cfgExportFileName, 260)
    imgui.SameLine(0, 5)

    if imgui.Button("Save to file") then
        ExportCounters()
    end

    local lineFormat = "%-10s  ||  %-7s  ||  %-10s  ||  %-22s  ||  %-16s  ||  %s\n";

    imgui.Text(string.format(lineFormat, "Difficulty", "Episode", "Section ID", "Area", "Monster", "Kill Count"))
    imgui.Text(string.format(lineFormat, "----------", "-------", "----------", "----", "-------", "----------"))

    table.sort(_AllCounters, GetCounterOrder)

    for i,counter in ipairs(_AllCounters) do
        difficulty = difficulties.d[counter.difficulty] or string.format("Unknown (%d)", counter.difficulty)
        episode = episodes.e[counter.episode] or string.format("Unknown (%d)", counter.episode)
        sectionID = sectionIDs.ids[counter.sectionID] or string.format("Unknown (%d)", counter.sectionID)
        area = areas.a[counter.area] or string.format("Unknown (%d)", counter.area)
        monster = GetMonsterName(counter)

        imgui.Text(string.format(lineFormat,
            difficulty,
            episode,
            sectionID,
            area,
            monster,
            string.format("%d", counter.kills)))
    end

    imgui.End()
end

local function present()
    ShowMainWindow()
    ShowDetailWindow()
end

local function init()
    BuildAllCounters()
    BuildVisibleCounters()
    BuildCountersByID()

    return
    {
        name = "Kill Counter",
        version = "1.2.4",
        author = "staphen",
        description = "Tracks number of enemies defeated while playing",
        present = present
    }
end

return
{
    __addon =
    {
        init = init
    }
}
