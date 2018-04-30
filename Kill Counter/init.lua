-- Author: Stephen Wills (https://github.com/StephenCWills)
-- From: psobb-kill-counter (https://github.com/StephenCWills/psobb-kill-counter)
-- License: GPL-3.0 (https://github.com/StephenCWills/psobb-kill-counter/blob/master/LICENSE)

-- This addon copies files from the lib folder of Soly's
-- PSOBBMod-Addons project so that this addon will remain
-- compatible with his addons as he continues making
-- changes. Appropriate attribution is provided in
-- the comment block the at top of each file.
local _MainMenu = require("core_mainmenu")
local _Helpers = require("Kill Counter.helpers")
local _Unitxt = require("Kill Counter.unitxt")
local _Success,_Configuration = pcall(require, "Kill Counter.configuration")

local _Difficulties = require("Kill Counter.difficulties")
local _Episodes = require("Kill Counter.episodes")
local _SectionIDs = require("Kill Counter.section-ids")
local _Areas = require("Kill Counter.areas")
local _Monsters = require("Kill Counter.monsters")

local _DisplayModes = require("Kill Counter.display-modes")

local _ConfigurationPath = "addons/Kill Counter/configuration.lua"
local _DataPath = "kill-counters.txt"
local _SessionsPath = "sessions"

local _PlayerMyIndex = 0x00A9C4F4
local _PlayerArray = 0x00A94254
local _PlayerCount = 0x00AAE168
local _BankPointer = 0x00A95EE0
local _MenuPointer = 0x00A97F44

local _Difficulty = 0x00A9CD68
local _Episode = 0x00A9B1C8
local _SectionID = 0x00A9C4D8
local _Location = 0x00AAFC9C

local _EntityCount = 0x00AAE164
local _EntityArray = 0x00AAD720

local _MonsterUnitxtID = 0x378
local _MonsterHP = 0x334
local _MonsterDeRolLeHP = 0x6B4
local _MonsterBarbaRayHP = 0x704
local _MonsterState = 0x32E
local _MonsterWave = 0x28
local _LilySlainState = 0xA
local _DubchicSlainCount = 0x394

local _DubwitchObjectCode = 0x00B267C0
local _VolOptStage2ObjectCode = 0x00AF6220
local _DarvantObjectCode = 0x00AF7D60
local _FalzStage2ObjectCode = 0x00AF77E0
local _FalzStage3ObjectCode = 0x00AF7A60
local _GolDragonObjectCode = 0x00AFB860
local _OlgaStage2ObjectCode = 0x00AF9A00

local _Dimensions
local _MonsterTable
local _GlobalCounter
local _SessionCounter
local _Session

local _ConfigurationWindow
local _GlobalCounterWindow
local _GlobalCounterDetailWindow
local _SessionCounterWindow
local _SessionCounterDetailWindow

local function LoadConfiguration()
    if not _Success then
        _Configuration = { }
    end

    _Configuration.configurationWindow = (_Configuration.configurationWindow == nil) or _Configuration.configurationWindow
    _Configuration.globalCounterWindow = (_Configuration.globalCounterWindow ~= nil) and _Configuration.globalCounterWindow
    _Configuration.globalCounterDetailWindow = (_Configuration.globalCounterDetailWindow ~= nil) and _Configuration.globalCounterDetailWindow
    _Configuration.sessionCounterWindow = (_Configuration.sessionCounterWindow ~= nil) and _Configuration.sessionCounterWindow
    _Configuration.sessionCounterDetailWindow = (_Configuration.sessionCounterDetailWindow ~= nil) and _Configuration.sessionCounterDetailWindow
    _Configuration.sessionInfoWindow = (_Configuration.sessionInfoWindow ~= nil) and _Configuration.sessionInfoWindow
    _Configuration.fontScale = _Configuration.fontScale or 1.0

    _Configuration.globalCounterDimensionsLocked = (_Configuration.globalCounterDimensionsLocked ~= nil) and _Configuration.globalCounterDimensionsLocked
    _Configuration.globalCounterDifficulty = _Configuration.globalCounterDifficulty or 0
    _Configuration.globalCounterEpisode = _Configuration.globalCounterEpisode or 0
    _Configuration.globalCounterSectionID = _Configuration.globalCounterSectionID or 0
    _Configuration.globalCounterArea = _Configuration.globalCounterArea or 0

    _Configuration.sessionCounterDimensionsLocked = (_Configuration.sessionCounterDimensionsLocked ~= nil) and _Configuration.sessionCounterDimensionsLocked
    _Configuration.sessionCounterDifficulty = _Configuration.sessionCounterDifficulty or 0
    _Configuration.sessionCounterEpisode = _Configuration.sessionCounterEpisode or 0
    _Configuration.sessionCounterSectionID = _Configuration.sessionCounterSectionID or 0
    _Configuration.sessionCounterArea = _Configuration.sessionCounterArea or 0

    _Configuration.globalCounterWindowDisplayMode = _Configuration.globalCounterWindowDisplayMode or 1
    _Configuration.globalCounterDetailWindowDisplayMode = _Configuration.globalCounterDetailWindowDisplayMode or 1
    _Configuration.sessionCounterWindowDisplayMode = _Configuration.sessionCounterWindowDisplayMode or 1
    _Configuration.sessionCounterDetailWindowDisplayMode = _Configuration.sessionCounterDetailWindowDisplayMode or 1
    _Configuration.sessionInfoWindowDisplayMode = _Configuration.sessionInfoWindowDisplayMode or 1

    if _Configuration.lockRoomID == nil then
        local ephinea = io.open("ephinea.dll", "r")

        _Configuration.lockRoomID = false

        if ephinea ~= nil then
            io.close(ephinea)
            _Configuration.lockRoomID = true
        end
    end

    _Configuration.serialize = function(configurationPath)
        local file = io.open(configurationPath, "w+")

        if file ~= nil then
            io.output(file)

            io.write("return {\n")
            io.write(string.format("    configurationWindow = %s,\n", tostring(_Configuration.configurationWindow)))
            io.write(string.format("    globalCounterWindow = %s,\n", tostring(_Configuration.globalCounterWindow)))
            io.write(string.format("    globalCounterDetailWindow = %s,\n", tostring(_Configuration.globalCounterDetailWindow)))
            io.write(string.format("    sessionCounterWindow = %s,\n", tostring(_Configuration.sessionCounterWindow)))
            io.write(string.format("    sessionCounterDetailWindow = %s,\n", tostring(_Configuration.sessionCounterDetailWindow)))
            io.write(string.format("    sessionInfoWindow = %s,\n", tostring(_Configuration.sessionInfoWindow)))
            io.write(string.format("    fontScale = %f,\n", _Configuration.fontScale))
            io.write("\n")
            io.write(string.format("    globalCounterDimensionsLocked = %s,\n", tostring(_Configuration.globalCounterDimensionsLocked)))
            io.write(string.format("    globalCounterDifficulty = %f,\n", _Configuration.globalCounterDifficulty))
            io.write(string.format("    globalCounterEpisode = %f,\n", _Configuration.globalCounterEpisode))
            io.write(string.format("    globalCounterSectionID = %f,\n", _Configuration.globalCounterSectionID))
            io.write(string.format("    globalCounterArea = %f,\n", _Configuration.globalCounterArea))
            io.write("\n")
            io.write(string.format("    sessionCounterDimensionsLocked = %s,\n", tostring(_Configuration.sessionCounterDimensionsLocked)))
            io.write(string.format("    sessionCounterDifficulty = %f,\n", _Configuration.sessionCounterDifficulty))
            io.write(string.format("    sessionCounterEpisode = %f,\n", _Configuration.sessionCounterEpisode))
            io.write(string.format("    sessionCounterSectionID = %f,\n", _Configuration.sessionCounterSectionID))
            io.write(string.format("    sessionCounterArea = %f,\n", _Configuration.sessionCounterArea))
            io.write("\n")
            io.write(string.format("    globalCounterWindowDisplayMode = %f,\n", _Configuration.globalCounterWindowDisplayMode))
            io.write(string.format("    globalCounterDetailWindowDisplayMode = %f,\n", _Configuration.globalCounterDetailWindowDisplayMode))
            io.write(string.format("    sessionCounterWindowDisplayMode = %f,\n", _Configuration.sessionCounterWindowDisplayMode))
            io.write(string.format("    sessionCounterDetailWindowDisplayMode = %f,\n", _Configuration.sessionCounterDetailWindowDisplayMode))
            io.write(string.format("    sessionInfoWindowDisplayMode = %f,\n", _Configuration.sessionInfoWindowDisplayMode))
            io.write("\n")
            io.write(string.format("    lockRoomID = %s\n", tostring(_Configuration.lockRoomID)))
            io.write("}\n")

            io.close(file)
        end
    end
end

local function Dimensions()
    local this = {
        difficulty = pso.read_u32(_Difficulty),
        episode = pso.read_u32(_Episode),
        sectionID = pso.read_u32(_SectionID),
        area = 0,
        hasChanged = true,
        lockRoomID = false
    }

    local _locationMap = {
        [0x01] = 0, [0x02] = 0,                         -- Forest
        [0x03] = 1, [0x04] = 1, [0x05] = 1,             -- Caves
        [0x06] = 2, [0x07] = 2,                         -- Mines
        [0x08] = 3, [0x09] = 3, [0x0A] = 3,             -- Ruins
        [0x0B] = 0, [0x0C] = 1, [0x0D] = 2, [0x0E] = 3, -- Bosses
        [0x13] = 7, [0x14] = 7,                         -- VR Temple
        [0x15] = 8, [0x16] = 8,                         -- VR Spaceship
        [0x17] = 5, [0x18] = 5, [0x19] = 5, [0x1A] = 5, -- Central Control Area
        [0x1C] = 6, [0x1D] = 6,                         -- Seabed
        [0x1E] = 5, [0x1F] = 6, [0x20] = 7, [0x21] = 8, -- Bosses
        [0x23] = 5,                                     -- Tower
        [0x24] = 9, [0x25] = 9, [0x26] = 9, [0x27] = 9, -- Crater (Exterior)
        [0x28] = 10,                                    -- Crater (Interior)
        [0x29] = 11, [0x2A] = 11, [0x2B] = 11,          -- Subterranean Desert
        [0x2C] = 11                                     -- Saint Milion
    }

    local _lockedRoomID = 0

    local _getPlayerAddress = function()
        local playerIndex = pso.read_u32(_PlayerMyIndex)
        return pso.read_u32(_PlayerArray + 4 * playerIndex)
    end

    local _getSectionID = function()
        local playerCount = pso.read_u32(_PlayerCount)
        local playerAddress = _getPlayerAddress()
        local location = pso.read_u32(_Location + 0x04)

        if location == 0xF or playerCount == 0 or playerAddress == 0 then
            _lockedRoomID = pso.read_u32(_SectionID)
        end

        return this.lockRoomID and _lockedRoomID or pso.read_u32(_SectionID)
    end

    local _getArea = function()
        local location = pso.read_u32(_Location)
        return _locationMap[location]
    end

    this.equals = function(dimensions)
        return
            this.difficulty == dimensions.difficulty and
            this.episode == dimensions.episode and
            this.sectionID == dimensions.sectionID and
            this.area == dimensions.area
    end

    this.update = function()
        local difficulty = pso.read_u32(_Difficulty)
        local episode = pso.read_u32(_Episode)
        local sectionID = _getSectionID()
        local area = _getArea() or this.area

        this.hasChanged =
            this.difficulty ~= difficulty or
            this.episode ~= episode or
            this.sectionID ~= sectionID or
            this.area ~= area

        if this.hasChanged then
            this.difficulty = difficulty
            this.episode = episode
            this.sectionID = sectionID
            this.area = area
        end
    end

    return this
end

local function MonsterTable(dimensions)
    local this = {
        monsters = {}
    }

    local _dimensions = dimensions
    local _previous = {}

    local _panArms = {}
    local _dubwitch = {}
    local _saintMilion = {}

    local _getMonsterHP = function(monster)
        if monster.id == 45 then
            return pso.read_u16(monster.address + _MonsterDeRolLeHP)
        elseif monster.id == 73 then
            return pso.read_u16(monster.address + _MonsterBarbaRayHP)
        else
            return pso.read_u16(monster.address + _MonsterHP)
        end
    end

    local _isSlain = function(monster)
        local mAddr = monster.address
        local mSlain = monster.hp == 0

        -- If monster has already been recorded as
        -- having been slain, then it is still slain
        if monster.previouslySlain then
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
            mSlain = mSlain or mState == _LilySlainState
        end

        -- Individual Dubchics must be slain five
        -- times before being truly slain
        if monster.id == 24 then
            local slainCount = pso.read_u16(mAddr + _DubchicSlainCount)

            if slainCount < 5 then
                mSlain = false
            end
        end

        -- Keep track of slain Dubwitches to
        -- set slain state of Dubchics later
        if monster.id == 49 and mSlain then
            table.insert(_dubwitch, monster)
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
            local difficulty = _dimensions.difficulty

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
            table.insert(_saintMilion, monster)
        end

        return mSlain
    end

    local _setDubchicsSlain = function(dubwitch)
        local dubwitchWave = pso.read_u32(dubwitch.address + _MonsterWave)
        local _,monster

        for _,monster in pairs(this.monsters) do
            if monster.id == 24 then
                local dubchicWave = pso.read_u32(monster.address + _MonsterWave)

                if dubchicWave == dubwitchWave then
                    monster.slain = true
                end
            end
        end
    end

    local _isSaintMilionSlain = function()
        local slain = 0

        for i,monster in ipairs(_saintMilion) do
            if i <= 4 and monster.slain then
                slain = slain + 1
            end

            monster.slain = false
        end

        return slain == 4
    end

    this.update = function()
        local i
        local playerCount = pso.read_u32(_PlayerCount)
        local entityCount = pso.read_u32(_EntityCount)

        _previous = this.monsters
        this.monsters = {}

        _dubwitch = {}
        _saintMilion = {}

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

                -- Darvants also have an id of zero, but they don't actually
                -- have an unitxt ID so we give it a fake ID of 999
                if objectCodeOffset == _DarvantObjectCode then
                    monster.id = 999
                end

                monster.hp = _getMonsterHP(monster)
                monster.previouslySlain = _previous[monster.address] ~= nil and _previous[monster.address].slain
                monster.slain = _isSlain(monster)
                this.monsters[monster.address] = monster

                -- Pan Arms HP is updated when damage is done
                -- to Hidoom and Migium, but not vice-versa
                if monster.id == 21 then
                    _panArms = monster
                elseif monster.id == 22 and monster.slain then
                    _panArms.slain = false
                elseif monster.id == 23 and monster.slain then
                    _panArms.slain = false
                end
            end
        end

        -- Apply logic to set slain state of Dubchics based
        -- on slain state of the corresponding Dubwitch
        local _,dubwitch

        for _,dubwitch in ipairs(_dubwitch) do
            _setDubchicsSlain(dubwitch)
        end

        -- Apply logic to determine whether to
        -- increment the kill counter for Saint-Milion
        if _isSaintMilionSlain() then
            _saintMilion[1].slain = true
        end
    end

    return this
end

local function KillCounter(dimensions, monsterTable)
    local this = {
        all = {},
        visible = {},
        byID = {},
        modified = false,
        visibleDimensions = Dimensions()
    }

    local _dimensions = dimensions
    local _monsterTable = monsterTable
    local _sortVisibleCounters = false

    local _getCounterOrder = function(counter1, counter2)
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

        return counter1.getMonsterName() < counter2.getMonsterName()
    end

    local _makeCounter = function(dimensions, monster)
        local _monsterName = nil

        local counter = {
            difficulty = dimensions.difficulty,
            episode = dimensions.episode,
            sectionID = dimensions.sectionID,
            area = dimensions.area,
            monsterID = monster.id,
            monsterColor = (_Monsters.m[monster.id] or { 0xFFFFFFFF })[1],
            kills = 1
        }

        counter.getMonsterName = function()
            if _monsterName == nil then
                if counter.monsterID ~= 999 then
                    _monsterName = _Unitxt.GetMonsterName(counter.monsterID, counter.difficulty == 3)
                else
                    _monsterName = "Darvant"
                end

                if _monsterName == "Unknown" then
                    _monsterName = string.format("Unknown (%d)", counter.monsterID)
                end

                if _monsterName ~= nil then
                    _sortVisibleCounters = true
                end
            end

            return _monsterName or string.format("%d", counter.monsterID)
        end

        return counter
    end

    local _makeVisibleCounter = function(areaCounter)
        local matchedCounters = {}
        local visibleCounter = {}

        local i
        local counter

        for i,counter in ipairs(this.all) do
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

    local _buildVisibleCounters = function()
        local i
        local counter
        local visibleDimensions = this.visibleDimensions

        this.visible = {}

        for i,counter in ipairs(this.all) do
            local isMatch =
                counter.difficulty == visibleDimensions.difficulty and
                counter.episode == visibleDimensions.episode and
                counter.sectionID == visibleDimensions.sectionID and
                counter.area == visibleDimensions.area

            if isMatch then
                table.insert(this.visible, _makeVisibleCounter(counter))
            end
        end

        table.sort(this.visible, _getCounterOrder)
    end

    local _buildCountersByID = function()
        local i
        local counter

        this.byID = {}

        for i,counter in ipairs(this.all) do
            local isMatch =
                counter.difficulty == _dimensions.difficulty and
                counter.episode == _dimensions.episode and
                counter.sectionID == _dimensions.sectionID and
                counter.area == _dimensions.area

            if isMatch then
                this.byID[counter.monsterID] = counter
            end
        end
    end

    this.update = function()
        local mAddr
        local monster
        local visibleDimensions = this.visibleDimensions

        this.modified = false

        if visibleDimensions.hasChanged then
            _buildVisibleCounters()
        end

        if _dimensions.hasChanged then
            _buildCountersByID()
        end

        for mAddr,monster in pairs(_monsterTable.monsters) do
            if monster.slain and not monster.previouslySlain then
                local counter = this.byID[monster.id]

                if counter then
                    counter.kills = counter.kills + 1
                else
                    counter = _makeCounter(_dimensions, monster)
                    table.insert(this.all, counter)
                    this.byID[monster.id] = counter

                    if _dimensions.equals(visibleDimensions) then
                        table.insert(this.visible, _makeVisibleCounter(counter))
                        _sortVisibleCounters = true
                    end
                end

                this.modified = true
            end
        end

        if _sortVisibleCounters then
            table.sort(this.visible, _getCounterOrder)
            _sortVisibleCounters = false
        end
    end

    this.sort = function()
        table.sort(this.all, _getCounterOrder)
    end

    this.serialize = function(filePath)
        local i
        local counter
        local file = io.open(filePath, "w+")

        if file ~= nil then
            io.output(file)

            for i,counter in pairs(this.all) do
                io.write(string.format("%d,%d,%d,%d,%d,%d\n",
                    counter.difficulty,
                    counter.episode,
                    counter.sectionID,
                    counter.area,
                    counter.monsterID,
                    counter.kills))
            end

            io.close(file)
        end
    end

    this.deserialize = function(filePath)
        this.all = {}

        local file = io.open(filePath, "r")
        if file == nil then
            return
        end

        io.input(file)

        local pattern = "(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)"
        local dimensions = {}
        local monster = {}

        local difficulty,episode,sectionID,area,monsterID,kills
        for difficulty,episode,sectionID,area,monsterID,kills in string.gfind(io.read("*all"), pattern) do
            dimensions.difficulty = tonumber(difficulty)
            dimensions.episode = tonumber(episode)
            dimensions.sectionID = tonumber(sectionID)
            dimensions.area = tonumber(area)
            monster.id = tonumber(monsterID)

            local counter = _makeCounter(dimensions, monster)
            counter.kills = tonumber(kills)
            table.insert(this.all, counter)
        end

        io.close(file)

        _buildVisibleCounters()
        _buildCountersByID()
    end

    this.export = function(filePath)
        local lineFormat = "%-10s  ||  %-7s  ||  %-10s  ||  %-22s  ||  %-16s  ||  %s\n"
        local file = io.open(filePath, "w+")
        io.output(file)

        io.write(string.format(lineFormat, "Difficulty", "Episode", "Section ID", "Area", "Monster", "Kill Count"))
        io.write(string.format(lineFormat, "----------", "-------", "----------", "----", "-------", "----------"))

        table.sort(this.all, _getCounterOrder)

        for i,counter in ipairs(this.all) do
            difficulty = _Difficulties.d[counter.difficulty] or string.format("Unknown (%d)", counter.difficulty)
            episode = _Episodes.e[counter.episode] or string.format("Unknown (%d)", counter.episode)
            sectionID = _SectionIDs.ids[counter.sectionID] or string.format("Unknown (%d)", counter.sectionID)
            area = _Areas.a[counter.area] or string.format("Unknown (%d)", counter.area)
            monster = counter.getMonsterName()

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

    this.reset = function()
        this.all = {}
        this.visible = {}
        this.byID = {}
        this.modified = false
    end

    return this
end

local function Session(dimensions, killCounter)
    local this = {
        questNumber = 0,
        mesetaEarned = 0,
        experienceEarned = 0,
        modified = false
    }

    local _meseta = nil
    local _bankMeseta = nil
    local _experience = nil
    local _isSessionActive = false
    local _everBeenModified = false

    local _now = os.time()
    local _startTimeInDungeon = _now
    local _timeSpentInDungeon = 0

    local _dimensions = dimensions
    local _killCounter = killCounter

    local _getQuestNumber = function()
        local questPtr = pso.read_u32(0xA95AA8)

        if questPtr == 0 then
            return 0
        end

        local questData = pso.read_u32(questPtr + 0x19C)

        if questData == 0 then
            return 0
        end

        return pso.read_u32(questData + 0x10)
    end

    local _getPlayerAddress = function()
        local playerIndex = pso.read_u32(_PlayerMyIndex)
        return pso.read_u32(_PlayerArray + 4 * playerIndex)
    end

    local _getPlayerExperience = function(playerAddress)
        return pso.read_u32(playerAddress + 0xE48)
    end

    local _getPlayerMeseta = function(playerAddress)
        return pso.read_u32(playerAddress + 0xE4C)
    end

    local _getBankMeseta = function()
        local bank = pso.read_u32(_BankPointer)

        if bank == 0 then
            return 0
        end

        return pso.read_u32(bank + 0x4)
    end

    local _reset = function()
        this.startTime = _now
        this.questNumber = 0
        this.mesetaEarned = 0
        this.experienceEarned = 0

        _meseta = nil
        _bankMeseta = nil
        _experience = nil
        _everBeenModified = false

        _startTimeInDungeon = _now
        _timeSpentInDungeon = 0

        _killCounter.reset()
    end

    this.startTime = _now

    this.getTimeSpent = function()
        return _now - this.startTime
    end

    this.getTimeSpentInDungeon = function()
        return _timeSpentInDungeon + (_now - _startTimeInDungeon)
    end

    this.update = function()
        local now = os.time()
        local playerCount = pso.read_u32(_PlayerCount)
        local playerAddress = _getPlayerAddress()
        local questNumber = _getQuestNumber()
        local location = pso.read_u32(_Location + 0x04)
        local remainder = now - math.floor(now / 5) * 5

        -- Location of 0xF indicates
        -- the player is in the lobby
        local isSessionActive =
            location ~= 0xF and
            playerCount ~= 0 and
            playerAddress ~= 0

        -- If the quest number changes, force the current session to
        -- end so a new session will be started for just the quest
        if _isSessionActive and this.questNumber ~= questNumber then
            isSessionActive = false
        end

        if not isSessionActive then
            -- If the session just ended, make sure the final
            -- state of the session will be saved to the file
            this.modified = _isSessionActive and _everBeenModified

            -- Freeze all session data while
            -- the session is inactive
            _isSessionActive = false
            return
        end

        -- This variable will be updated
        -- later if the session is modified
        this.modified = false

        -- Location of zero indicates the player is on Pioneer 2;
        -- this logic stops the time counter from increasing
        if location == 0 then
            _timeSpentInDungeon = _timeSpentInDungeon + (_now - _startTimeInDungeon)
            _startTimeInDungeon = now
        end

        -- After writing to the session file for the first time,
        -- the session file is updated every five seconds to ensure
        -- that the time spent values are kept fairly accurate
        if _everBeenModified and _now ~= now and remainder == 0 then
            this.modified = true
        end

        _now = now

        -- If the session state was previously inactive,
        -- a new session is started to replace the old session
        if not _isSessionActive then
            _isSessionActive = true
            _reset()
        end

        -- The rest of this method simply updates
        -- the session data with the latest values
        local meseta = _getPlayerMeseta(playerAddress)
        local bankMeseta = _getBankMeseta()
        local experience = _getPlayerExperience(playerAddress)

        if _meseta ~= nil and _bankMeseta ~= nil and _meseta ~= meseta then
            this.mesetaEarned = this.mesetaEarned + (meseta - _meseta) + (bankMeseta - _bankMeseta)
            this.modified = true
        end

        if _experience ~= nil and _experience ~= experience then
            this.experienceEarned = this.experienceEarned + (experience - _experience)
            this.modified = true
        end

        if _killCounter.modified then
            this.modified = true
        end

        if this.modified then
            _everBeenModified = true
        end

        this.questNumber = questNumber
        _meseta = meseta
        _bankMeseta = bankMeseta
        _experience = experience
    end

    this.serialize = function(sessionPath)
        local file = io.open(sessionPath, "w+")

        if file ~= nil then
            io.output(file)

            io.write(string.format("difficulty=%d\n", _dimensions.difficulty))
            io.write(string.format("episode=%d\n", _dimensions.episode))
            io.write(string.format("sectionID=%d\n", _dimensions.sectionID))
            io.write(string.format("quest=%d\n", this.questNumber))
            io.write(string.format("meseta=%d\n", this.mesetaEarned))
            io.write(string.format("experience=%d\n", this.experienceEarned))
            io.write(string.format("timeSpent=%d\n", this.getTimeSpent()))
            io.write(string.format("timeSpentInDungeon=%d\n", this.getTimeSpentInDungeon()))

            io.close(file)
        end
    end

    return this
end

local function ConfigurationWindow(configuration)
    local this = {
        title = "Kill Counter - Configuration",
        fontScale = 1.0,
        open = false,
        globalCounterWindow = nil,
        globalCounterDetailWindow = nil,
        sessionCounterWindow = nil,
        sessionCounterDetailWindow = nil,
        sessionInfoWindow = nil
    }

    local _configuration = configuration
    local _hasChanged = false

    local _sortByKey = function(tab)
        local keys = { }

        for k in pairs(tab) do
            table.insert(keys, k)
        end

        table.sort(keys)

        for i in ipairs(keys) do
            keys[i] = tab[keys[i]]
        end

        return keys
    end

    local _difficulties = _sortByKey(_Difficulties.d)
    local _episodes = _sortByKey(_Episodes.e)
    local _sectionIDs = _sortByKey(_SectionIDs.ids)
    local _areas = _sortByKey(_Areas.a)

    local _showWindowSettings = function()
        local success

        if imgui.TreeNodeEx("Windows", "DefaultOpen") then
            if imgui.Checkbox("Global Kill Counters", this.globalCounterWindow.open) then
                this.globalCounterWindow.open = not this.globalCounterWindow.open
            end

            imgui.SameLine(0, 50)
            if imgui.Checkbox("Global Kill Counter Detail", this.globalCounterDetailWindow.open) then
                this.globalCounterDetailWindow.open = not this.globalCounterDetailWindow.open
            end

            if imgui.Checkbox("Session Kill Counters", this.sessionCounterWindow.open) then
                this.sessionCounterWindow.open = not this.sessionCounterWindow.open
            end

            imgui.SameLine(0, 50)
            if imgui.Checkbox("Session Kill Counter Detail", this.sessionCounterDetailWindow.open) then
                this.sessionCounterDetailWindow.open = not this.sessionCounterDetailWindow.open
            end

            if imgui.Checkbox("Session Info Counters", this.sessionInfoWindow.open) then
                this.sessionInfoWindow.open = not this.sessionInfoWindow.open
            end

            imgui.PushItemWidth(80)
            success,this.fontScale = imgui.InputFloat("Font Scale", this.fontScale)
            this.globalCounterWindow.fontScale = this.fontScale
            this.globalCounterDetailWindow.fontScale = this.fontScale
            this.sessionCounterWindow.fontScale = this.fontScale
            this.sessionInfoWindow.fontScale = this.fontScale
            imgui.PopItemWidth()

            imgui.TreePop()
        end
    end

    local _showGlobalCounterSettings = function()
        local success

        if imgui.TreeNodeEx("Global Kill Counters") then
            if imgui.Checkbox("Enabled", this.globalCounterWindow.open) then
                this.globalCounterWindow.open = not this.globalCounterWindow.open
            end

            imgui.SameLine(0, 50)
            if imgui.Checkbox("Dimensions Locked", _configuration.globalCounterDimensionsLocked) then
                _configuration.globalCounterDimensionsLocked = not _configuration.globalCounterDimensionsLocked
                _hasChanged = true
            end

            local difficultyLabelSize = imgui.CalcTextSize("Difficulty")
            local episodeLabelSize = imgui.CalcTextSize("Episode")
            local sectionIDLabelSize = imgui.CalcTextSize("Section ID")
            local areaLabelSize = imgui.CalcTextSize("Area")

            local labelWidth1 = math.max(difficultyLabelSize, sectionIDLabelSize)
            local labelWidth2 = math.max(episodeLabelSize, areaLabelSize)

            -- Difficulty selection combo box
            local difficulty = _configuration.globalCounterDifficulty + 1

            imgui.Dummy(0, 0)
            imgui.SameLine(0, labelWidth1 - difficultyLabelSize)
            imgui.Text("Difficulty")
            imgui.SameLine(0, 10)

            imgui.PushItemWidth(100)
            success,difficulty = imgui.Combo("##Difficulty", difficulty, _difficulties, table.getn(_difficulties))
            imgui.PopItemWidth()
            imgui.SameLine(0, 50)

            if (_configuration.globalCounterDifficulty ~= difficulty - 1) or _configuration.globalCounterDimensionsLocked then
                _configuration.globalCounterDifficulty = difficulty - 1
                _configuration.globalCounterDimensionsLocked = true
                _hasChanged = true
            end

            -- Episode selection combo box
            local episode = _configuration.globalCounterEpisode + 1

            imgui.Dummy(0, 0)
            imgui.SameLine(0, labelWidth2 - episodeLabelSize)
            imgui.Text("Episode")
            imgui.SameLine(0, 10)

            imgui.PushItemWidth(100)
            success,episode = imgui.Combo("##Episode", episode, _episodes, table.getn(_episodes))
            imgui.PopItemWidth()

            if (_configuration.globalCounterEpisode ~= episode - 1) or _configuration.globalCounterDimensionsLocked then
                _configuration.globalCounterEpisode = episode - 1
                _configuration.globalCounterDimensionsLocked = true
                _hasChanged = true
            end

            -- Section ID selection combo box
            local sectionID = _configuration.globalCounterSectionID + 1

            imgui.Dummy(0, 0)
            imgui.SameLine(0, labelWidth1 - sectionIDLabelSize)
            imgui.Text("Section ID")
            imgui.SameLine(0, 10)

            imgui.PushItemWidth(100)
            success,sectionID = imgui.Combo("##Section ID", sectionID, _sectionIDs, table.getn(_sectionIDs))
            imgui.PopItemWidth()
            imgui.SameLine(0, 50)

            if (_configuration.globalCounterSectionID ~= sectionID - 1) or _configuration.globalCounterDimensionsLocked then
                _configuration.globalCounterSectionID = sectionID - 1
                _configuration.globalCounterDimensionsLocked = true
                _hasChanged = true
            end

            -- Area selection combo box
            local area = _configuration.globalCounterArea + 1

            imgui.Dummy(0, 0)
            imgui.SameLine(0, labelWidth2 - areaLabelSize)
            imgui.Text("Area")
            imgui.SameLine(0, 10)

            imgui.PushItemWidth(200)
            success,area = imgui.Combo("##Area", area, _areas, table.getn(_areas))
            imgui.PopItemWidth()

            if (_configuration.globalCounterArea ~= area - 1) or _configuration.globalCounterDimensionsLocked then
                _configuration.globalCounterArea = area - 1
                _configuration.globalCounterDimensionsLocked = true
                _hasChanged = true
            end

            imgui.TreePop()
        end
    end

    local _showSessionCounterSettings = function()
        local success

        if imgui.TreeNodeEx("Session Kill Counters") then
            if imgui.Checkbox("Enabled", this.sessionCounterWindow.open) then
                this.sessionCounterWindow.open = not this.sessionCounterWindow.open
            end

            imgui.SameLine(0, 50)
            if imgui.Checkbox("Dimensions Locked", _configuration.sessionCounterDimensionsLocked) then
                _configuration.sessionCounterDimensionsLocked = not _configuration.sessionCounterDimensionsLocked
                _hasChanged = true
            end

            local difficultyLabelSize = imgui.CalcTextSize("Difficulty")
            local episodeLabelSize = imgui.CalcTextSize("Episode")
            local sectionIDLabelSize = imgui.CalcTextSize("Section ID")
            local areaLabelSize = imgui.CalcTextSize("Area")

            local labelWidth1 = math.max(difficultyLabelSize, sectionIDLabelSize)
            local labelWidth2 = math.max(episodeLabelSize, areaLabelSize)

            -- Difficulty selection combo box
            local difficulty = _configuration.sessionCounterDifficulty + 1

            imgui.Dummy(0, 0)
            imgui.SameLine(0, labelWidth1 - difficultyLabelSize)
            imgui.Text("Difficulty")
            imgui.SameLine(0, 10)

            imgui.PushItemWidth(100)
            success,difficulty = imgui.Combo("##Difficulty", difficulty, _difficulties, table.getn(_difficulties))
            imgui.PopItemWidth()
            imgui.SameLine(0, 50)

            if (_configuration.sessionCounterDifficulty ~= difficulty - 1) or _configuration.globalCounterDimensionsLocked then
                _configuration.sessionCounterDifficulty = difficulty - 1
                _configuration.sessionCounterDimensionsLocked = true
                _hasChanged = true
            end

            -- Episode selection combo box
            local episode = _configuration.sessionCounterEpisode + 1

            imgui.Dummy(0, 0)
            imgui.SameLine(0, labelWidth2 - episodeLabelSize)
            imgui.Text("Episode")
            imgui.SameLine(0, 10)

            imgui.PushItemWidth(100)
            success,episode = imgui.Combo("##Episode", episode, _episodes, table.getn(_episodes))
            imgui.PopItemWidth()

            if (_configuration.sessionCounterEpisode ~= episode - 1) or _configuration.globalCounterDimensionsLocked then
                _configuration.sessionCounterEpisode = episode - 1
                _configuration.sessionCounterDimensionsLocked = true
                _hasChanged = true
            end

            -- Section ID selection combo box
            local sectionID = _configuration.sessionCounterSectionID + 1

            imgui.Dummy(0, 0)
            imgui.SameLine(0, labelWidth1 - sectionIDLabelSize)
            imgui.Text("Section ID")
            imgui.SameLine(0, 10)

            imgui.PushItemWidth(100)
            success,sectionID = imgui.Combo("##Section ID", sectionID, _sectionIDs, table.getn(_sectionIDs))
            imgui.PopItemWidth()
            imgui.SameLine(0, 50)

            if (_configuration.sessionCounterSectionID ~= sectionID - 1) or _configuration.globalCounterDimensionsLocked then
                _configuration.sessionCounterSectionID = sectionID - 1
                _configuration.sessionCounterDimensionsLocked = true
                _hasChanged = true
            end

            -- Area selection combo box
            local area = _configuration.sessionCounterArea + 1

            imgui.Dummy(0, 0)
            imgui.SameLine(0, labelWidth2 - areaLabelSize)
            imgui.Text("Area")
            imgui.SameLine(0, 10)

            imgui.PushItemWidth(200)
            success,area = imgui.Combo("##Area", area, _areas, table.getn(_areas))
            imgui.PopItemWidth()

            if (_configuration.sessionCounterArea ~= area - 1) or _configuration.globalCounterDimensionsLocked then
                _configuration.sessionCounterArea = area - 1
                _configuration.sessionCounterDimensionsLocked = true
                _hasChanged = true
            end

            imgui.TreePop()
        end
    end

    local _showDisplayModes = function()
        local success, mode

        if imgui.TreeNodeEx("Window Display Modes") then
            local globalKillCountersLabel = "Global Kill Counters"
            local globalKillCountersDetailLabel = "Global Kill Counter Detail"
            local sessionKillCountersLabel = "Session Kill Counters"
            local sessionKillCountersDetailLabel = "Session Kill Counter Detail"
            local sessionInfoLabel = "Session Info Counters"

            local globalKillCountersLabelWidth = imgui.CalcTextSize(globalKillCountersLabel)
            local globalKillCountersDetailLabelWidth = imgui.CalcTextSize(globalKillCountersDetailLabel)
            local sessionKillCountersLabelWidth = imgui.CalcTextSize(sessionKillCountersLabel)
            local sessionKillCountersDetailLabelWidth = imgui.CalcTextSize(sessionKillCountersDetailLabel)
            local sessionInfoLabelWidth = imgui.CalcTextSize(sessionInfoLabel)

            local widths = {
                globalKillCountersLabelWidth,
                globalKillCountersDetailLabelWidth,
                sessionKillCountersLabelWidth,
                sessionKillCountersDetailLabelWidth,
                sessionInfoLabelWidth
            }

            local labelWidth = 0

            for _,width in ipairs(widths) do
                labelWidth = math.max(labelWidth, width)
            end

            -- Global Kill Counter Window Display Mode
            mode = _configuration.globalCounterWindowDisplayMode

            imgui.Dummy(0, 0)
            imgui.SameLine(0, labelWidth - globalKillCountersLabelWidth)
            imgui.Text(globalKillCountersLabel)
            imgui.SameLine(0, 10)

            imgui.PushItemWidth(125)
            success,mode = imgui.Combo("##Global Kill Counters", mode, _DisplayModes, table.getn(_DisplayModes))
            imgui.PopItemWidth()

            _hasChanged = _hasChanged or (_configuration.globalCounterWindowDisplayMode ~= mode)
            _configuration.globalCounterWindowDisplayMode = mode
            this.globalCounterWindow.displayMode = mode

            -- Global Kill Counter Detail Window Display Mode
            mode = _configuration.globalCounterDetailWindowDisplayMode

            imgui.Dummy(0, 0)
            imgui.SameLine(0, labelWidth - globalKillCountersDetailLabelWidth)
            imgui.Text(globalKillCountersDetailLabel)
            imgui.SameLine(0, 10)

            imgui.PushItemWidth(125)
            success,mode = imgui.Combo("##Global Kill Counter Detail", mode, _DisplayModes, table.getn(_DisplayModes))
            imgui.PopItemWidth()

            _hasChanged = _hasChanged or (_configuration.globalCounterDetailWindowDisplayMode ~= mode)
            _configuration.globalCounterDetailWindowDisplayMode = mode
            this.globalCounterDetailWindow.displayMode = mode

            -- Session Kill Counter Window Display Mode
            mode = _configuration.sessionCounterWindowDisplayMode

            imgui.Dummy(0, 0)
            imgui.SameLine(0, labelWidth - sessionKillCountersLabelWidth)
            imgui.Text(sessionKillCountersLabel)
            imgui.SameLine(0, 10)

            imgui.PushItemWidth(125)
            success,mode = imgui.Combo("##Session Kill Counters", mode, _DisplayModes, table.getn(_DisplayModes))
            imgui.PopItemWidth()

            _hasChanged = _hasChanged or (_configuration.sessionCounterWindowDisplayMode ~= mode)
            _configuration.sessionCounterWindowDisplayMode = mode
            this.sessionCounterWindow.displayMode = mode

            -- Session Kill Counter Detail Window Display Mode
            mode = _configuration.sessionCounterDetailWindowDisplayMode

            imgui.Dummy(0, 0)
            imgui.SameLine(0, labelWidth - sessionKillCountersDetailLabelWidth)
            imgui.Text(sessionKillCountersDetailLabel)
            imgui.SameLine(0, 10)

            imgui.PushItemWidth(125)
            success,mode = imgui.Combo("##Session Kill Counter Detail", mode, _DisplayModes, table.getn(_DisplayModes))
            imgui.PopItemWidth()

            _hasChanged = _hasChanged or (_configuration.sessionCounterDetailWindowDisplayMode ~= mode)
            _configuration.sessionCounterDetailWindowDisplayMode = mode
            this.sessionCounterDetailWindow.displayMode = mode

            -- Session Info Counter Window Display Mode
            mode = _configuration.sessionInfoWindowDisplayMode

            imgui.Dummy(0, 0)
            imgui.SameLine(0, labelWidth - sessionInfoLabelWidth)
            imgui.Text(sessionInfoLabel)
            imgui.SameLine(0, 10)

            imgui.PushItemWidth(125)
            success,mode = imgui.Combo("##Session Info Counters", mode, _DisplayModes, table.getn(_DisplayModes))
            imgui.PopItemWidth()

            _hasChanged = _hasChanged or (_configuration.sessionInfoWindowDisplayMode ~= mode)
            _configuration.sessionInfoWindowDisplayMode = mode
            this.sessionInfoWindow.displayMode = mode

            imgui.TreePop()
        end
    end

    local _showAdvancedSettings = function()
        local success

        if imgui.TreeNodeEx("Advanced") then
            if imgui.Checkbox("Lock Room ID", _configuration.lockRoomID) then
                _configuration.lockRoomID = not _configuration.lockRoomID
                _hasChanged = true
            end

            imgui.TreePop()
        end
    end

    this.update = function()
        if not this.open then
            return
        end

        local success

        imgui.SetNextWindowSize(500, 400, 'FirstUseEver')
        success,this.open = imgui.Begin(this.title, this.open)
        imgui.SetWindowFontScale(this.fontScale)

        _hasChanged = false
        _showWindowSettings()
        _showGlobalCounterSettings()
        _showSessionCounterSettings()
        _showDisplayModes()
        _showAdvancedSettings()

        imgui.End()
    end

    this.hasChanged = function()
        return
            this.open ~= _configuration.configurationWindow or
            this.globalCounterWindow.open ~= _configuration.globalCounterWindow or
            this.globalCounterDetailWindow.open ~= _configuration.globalCounterDetailWindow or
            this.sessionCounterWindow.open ~= _configuration.sessionCounterWindow or
            this.sessionCounterDetailWindow.open ~= _configuration.sessionCounterDetailWindow or
            this.sessionInfoWindow.open ~= _configuration.sessionInfoWindow or
            this.fontScale ~= _configuration.fontScale or
            _hasChanged
    end

    return this
end

local function KillCounterWindow(killCounter)
    local this = {
        title = "Kill Counter - Main",
        fontScale = 1.0,
        displayMode = 1,
        open = false
    }

    local _killCounter = killCounter

    local _showCounters = function()
        local i
        local counter

        imgui.Columns(2)
        imgui.Text("Monster")
        imgui.NextColumn()
        imgui.Text("Kills")
        imgui.NextColumn()

        for i,counter in ipairs(_killCounter.visible) do
            local display = _Monsters.m[counter.monsterID] == nil or _Monsters.m[counter.monsterID][2]

            if display then
                _Helpers.imguiText(counter.getMonsterName(), counter.monsterColor, true)
                imgui.NextColumn()
                imgui.Text(string.format("%d", counter.kills()))
                imgui.NextColumn()
            end
        end
    end

    this.update = function(isMenuOpen)
        if not this.open then
            return
        end

        local displayMode = _DisplayModes[this.displayMode]

        if (displayMode == "Show with menu") and not isMenuOpen then
            return
        end

        if (displayMode == "Hide with menu") and isMenuOpen then
            return
        end

        local success

        imgui.SetNextWindowSize(270, 380, 'FirstUseEver')
        success,this.open = imgui.Begin(this.title, this.open)
        imgui.SetWindowFontScale(this.fontScale)

        _showCounters()

        imgui.End()
    end

    return this
end

local function KillCounterDetailWindow(killCounter)
    local this = {
        title = "Kill Counter - Detail",
        fontScale = 1.0,
        displayMode = 1,
        open = false,
        exportFilePath = "kill-counters-export.txt"
    }

    local _killCounter = killCounter

    local _showExport = function()
        local lineFormat = "%-10s  ||  %-7s  ||  %-10s  ||  %-22s  ||  %-16s  ||  %s\n"

        _killCounter.sort()

        imgui.Text(string.format(lineFormat, "Difficulty", "Episode", "Section ID", "Area", "Monster", "Kill Count"))
        imgui.Text(string.format(lineFormat, "----------", "-------", "----------", "----", "-------", "----------"))

        for i,counter in ipairs(_killCounter.all) do
            difficulty = _Difficulties.d[counter.difficulty] or string.format("Unknown (%d)", counter.difficulty)
            episode = _Episodes.e[counter.episode] or string.format("Unknown (%d)", counter.episode)
            sectionID = _SectionIDs.ids[counter.sectionID] or string.format("Unknown (%d)", counter.sectionID)
            area = _Areas.a[counter.area] or string.format("Unknown (%d)", counter.area)
            monster = counter.getMonsterName()

            imgui.Text(string.format(lineFormat,
                difficulty,
                episode,
                sectionID,
                area,
                monster,
                string.format("%d", counter.kills)))
        end
    end

    this.update = function(isMenuOpen)
        if not this.open then
            return
        end

        local displayMode = _DisplayModes[this.displayMode]

        if (displayMode == "Show with menu") and not isMenuOpen then
            return
        end

        if (displayMode == "Hide with menu") and isMenuOpen then
            return
        end

        local success

        imgui.SetNextWindowSize(800, 400, 'FirstUseEver')
        success,this.open = imgui.Begin(this.title, this.open)
        imgui.SetWindowFontScale(this.fontScale)

        success,this.exportFilePath = imgui.InputText("", this.exportFilePath, 260)

        imgui.SameLine(0, 5)
        if imgui.Button("Save to file") then
            _killCounter.export(this.exportFilePath)
        end

        _showExport()

        imgui.End()
    end

    return this
end

local function SessionInfoWindow(session)
    local this = {
        title = "Kill Counter - Session Info",
        displayMode = 1,
        open = false
    }

    local _session = session

    local _getValueOverTimeSpent = function(value, timeSpent)
        local valueOverTime = value / timeSpent
        local timePeriod = "per second"

        if math.abs(valueOverTime) < 1.0 then
            valueOverTime = valueOverTime * 60.0
            timePeriod = "per minute"
        end

        if math.abs(valueOverTime) < 1.0 then
            valueOverTime = valueOverTime * 60.0
            timePeriod = "per hour"
        end

        return string.format("%f %s", valueOverTime, timePeriod)
    end

    local _getFormattedTimeSpent = function(timeSpent)
        return os.date("!%H:%M:%S", timeSpent)
    end

    local _showSessionInfo = function()
        local timeSpent = _session.getTimeSpent()
        local timeSpentInDungeon = _session.getTimeSpentInDungeon()

        imgui.Text(string.format("Meseta: %d", _session.mesetaEarned))
        imgui.Text(string.format("Meseta: %s", _getValueOverTimeSpent(_session.mesetaEarned, timeSpent)))
        imgui.Text(string.format("Meseta: %s in dungeon", _getValueOverTimeSpent(_session.mesetaEarned, timeSpentInDungeon)))
        imgui.Separator()
        imgui.Text(string.format("Experience: %d", _session.experienceEarned))
        imgui.Text(string.format("Experience: %s", _getValueOverTimeSpent(_session.experienceEarned, timeSpent)))
        imgui.Text(string.format("Experience: %s in dungeon", _getValueOverTimeSpent(_session.experienceEarned, timeSpentInDungeon)))
        imgui.Separator()
        imgui.Text(string.format("Time: %s", _getFormattedTimeSpent(timeSpent)))
        imgui.Text(string.format("Dungeon Time: %s", _getFormattedTimeSpent(timeSpentInDungeon)))
    end

    this.update = function(isMenuOpen)
        if not this.open then
            return
        end

        local displayMode = _DisplayModes[this.displayMode]

        if (displayMode == "Show with menu") and not isMenuOpen then
            return
        end

        if (displayMode == "Hide with menu") and isMenuOpen then
            return
        end

        local success

        imgui.SetNextWindowSize(310, 200, 'FirstUseEver')
        success,this.open = imgui.Begin(this.title, this.open)
        imgui.SetWindowFontScale(this.fontScale)

        _showSessionInfo()

        imgui.End()
    end

    return this
end

local function present()
    local isMenuOpen = (pso.read_u32(_MenuPointer) == 1)

    _Dimensions.update()
    _MonsterTable.update()
    _GlobalCounter.update()
    _SessionCounter.update()
    _Session.update()

    _ConfigurationWindow.update()
    _GlobalCounterWindow.update(isMenuOpen)
    _GlobalCounterDetailWindow.update(isMenuOpen)
    _SessionCounterWindow.update(isMenuOpen)
    _SessionCounterDetailWindow.update(isMenuOpen)
    _SessionInfoWindow.update(isMenuOpen)

    _Dimensions.lockRoomID = _Configuration.lockRoomID

    if not _Configuration.globalCounterDimensionsLocked then
        _Configuration.globalCounterDifficulty = _Dimensions.difficulty
        _Configuration.globalCounterEpisode = _Dimensions.episode
        _Configuration.globalCounterSectionID = _Dimensions.sectionID
        _Configuration.globalCounterArea = _Dimensions.area
    end

    _GlobalCounter.visibleDimensions.hasChanged =
        _GlobalCounter.visibleDimensions.difficulty ~= _Configuration.globalCounterDifficulty or
        _GlobalCounter.visibleDimensions.episode ~= _Configuration.globalCounterEpisode or
        _GlobalCounter.visibleDimensions.sectionID ~= _Configuration.globalCounterSectionID or
        _GlobalCounter.visibleDimensions.area ~= _Configuration.globalCounterArea

    _GlobalCounter.visibleDimensions.difficulty = _Configuration.globalCounterDifficulty
    _GlobalCounter.visibleDimensions.episode = _Configuration.globalCounterEpisode
    _GlobalCounter.visibleDimensions.sectionID = _Configuration.globalCounterSectionID
    _GlobalCounter.visibleDimensions.area = _Configuration.globalCounterArea

    if not _Configuration.sessionCounterDimensionsLocked then
        _Configuration.sessionCounterDifficulty = _Dimensions.difficulty
        _Configuration.sessionCounterEpisode = _Dimensions.episode
        _Configuration.sessionCounterSectionID = _Dimensions.sectionID
        _Configuration.sessionCounterArea = _Dimensions.area
    end

    _SessionCounter.visibleDimensions.hasChanged =
        _SessionCounter.visibleDimensions.difficulty ~= _Configuration.sessionCounterDifficulty or
        _SessionCounter.visibleDimensions.episode ~= _Configuration.sessionCounterEpisode or
        _SessionCounter.visibleDimensions.sectionID ~= _Configuration.sessionCounterSectionID or
        _SessionCounter.visibleDimensions.area ~= _Configuration.sessionCounterArea

    _SessionCounter.visibleDimensions.difficulty = _Configuration.sessionCounterDifficulty
    _SessionCounter.visibleDimensions.episode = _Configuration.sessionCounterEpisode
    _SessionCounter.visibleDimensions.sectionID = _Configuration.sessionCounterSectionID
    _SessionCounter.visibleDimensions.area = _Configuration.sessionCounterArea

    if _ConfigurationWindow.hasChanged() then
        _Configuration.configurationWindow = _ConfigurationWindow.open
        _Configuration.globalCounterWindow = _GlobalCounterWindow.open
        _Configuration.globalCounterDetailWindow = _GlobalCounterDetailWindow.open
        _Configuration.sessionCounterWindow = _SessionCounterWindow.open
        _Configuration.sessionCounterDetailWindow = _SessionCounterDetailWindow.open
        _Configuration.sessionInfoWindow = _SessionInfoWindow.open
        _Configuration.serialize(_ConfigurationPath)
    end

    if _GlobalCounter.modified then
        _GlobalCounter.serialize(_DataPath)
    end

    if _Session.modified then
        local pathPrefix = _SessionsPath .. "\\" .. os.date("%Y%m%d%H%M%S", _Session.startTime)
        _Session.serialize(pathPrefix .. "-session-counters.txt")
        _SessionCounter.serialize(pathPrefix .. "-kill-counters.txt")
    end
end

local function init()
    LoadConfiguration()

    _Dimensions = Dimensions()
    _MonsterTable = MonsterTable(_Dimensions)
    _GlobalCounter = KillCounter(_Dimensions, _MonsterTable)
    _SessionCounter = KillCounter(_Dimensions, _MonsterTable)
    _Session = Session(_Dimensions, _SessionCounter)

    _Dimensions.lockRoomID = _Configuration.lockRoomID
    _GlobalCounter.deserialize(_DataPath)

    _GlobalCounterWindow = KillCounterWindow(_GlobalCounter)
    _GlobalCounterWindow.title = "Kill Counter - Global"
    _GlobalCounterWindow.fontScale = _Configuration.fontScale
    _GlobalCounterWindow.displayMode = _Configuration.globalCounterWindowDisplayMode
    _GlobalCounterWindow.open = _Configuration.globalCounterWindow

    _GlobalCounterDetailWindow = KillCounterDetailWindow(_GlobalCounter)
    _GlobalCounterDetailWindow.title = "Kill Counter - Global Detail"
    _GlobalCounterDetailWindow.fontScale = _Configuration.fontScale
    _GlobalCounterDetailWindow.displayMode = _Configuration.globalCounterDetailWindowDisplayMode
    _GlobalCounterDetailWindow.open = _Configuration.globalCounterDetailWindow

    _SessionCounterWindow = KillCounterWindow(_SessionCounter)
    _SessionCounterWindow.title = "Kill Counter - Session"
    _SessionCounterWindow.fontScale = _Configuration.fontScale
    _SessionCounterWindow.displayMode = _Configuration.sessionCounterWindowDisplayMode
    _SessionCounterWindow.open = _Configuration.sessionCounterWindow

    _SessionCounterDetailWindow = KillCounterDetailWindow(_SessionCounter)
    _SessionCounterDetailWindow.title = "Kill Counter - Session Detail"
    _SessionCounterDetailWindow.fontScale = _Configuration.fontScale
    _SessionCounterDetailWindow.displayMode = _Configuration.sessionCounterDetailWindowDisplayMode
    _SessionCounterDetailWindow.open = _Configuration.sessionCounterDetailWindow
    _SessionCounterDetailWindow.exportFilePath = "session-counters-export.txt"

    _SessionInfoWindow = SessionInfoWindow(_Session)
    _SessionInfoWindow.title = "Kill Counter - Session Info"
    _SessionInfoWindow.fontScale = _Configuration.fontScale
    _SessionInfoWindow.displayMode = _Configuration.sessionInfoWindowDisplayMode
    _SessionInfoWindow.open = _Configuration.sessionInfoWindow

    _ConfigurationWindow = ConfigurationWindow(_Configuration)
    _ConfigurationWindow.fontScale = _Configuration.fontScale
    _ConfigurationWindow.globalCounterWindow = _GlobalCounterWindow
    _ConfigurationWindow.globalCounterDetailWindow = _GlobalCounterDetailWindow
    _ConfigurationWindow.sessionCounterWindow = _SessionCounterWindow
    _ConfigurationWindow.sessionCounterDetailWindow = _SessionCounterDetailWindow
    _ConfigurationWindow.sessionInfoWindow = _SessionInfoWindow
    _ConfigurationWindow.open = _Configuration.configurationWindow

    local configurationButtonHandler = function()
        _ConfigurationWindow.open = not _ConfigurationWindow.open
    end

    _MainMenu.add_button('Kill Counter', configurationButtonHandler)

    return {
        name = "Kill Counter",
        version = "2.1.1",
        author = "staphen",
        description = "Tracks number of enemies defeated while playing",
        present = present
    }
end

return {
    __addon = {
        init = init
    }
}
