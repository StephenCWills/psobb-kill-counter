-- Author: Stephen Wills (https://github.com/StephenCWills)
-- From: PSOBBMod-Addons (https://github.com/StephenCWills/psobb-kill-counter)
-- License: GPL-3.0 (https://github.com/StephenCWills/psobb-kill-counter/blob/master/LICENSE)

-- This addon copies files from the lib folder of Soly's
-- PSOBBMod-Addons project so that this addon will remain
-- compatible with his addons as he continues making
-- changes. Appropriate attribution is provided in
-- the comment block the at top of each file.
local _MainMenu = require("core_mainmenu")
local _Helpers = require("Kill Counter.helpers")
local _Unitxt = require("Kill Counter.Unitxt")
local _Success,_Configuration = pcall(require, "Kill Counter.configuration")

local _Difficulties = require("Kill Counter.difficulties")
local _Episodes = require("Kill Counter.episodes")
local _SectionIDs = require("Kill Counter.section-ids")
local _Areas = require("Kill Counter.areas")
local _Monsters = require("Kill Counter.Monsters")

local _ConfigurationPath = "addons/Kill Counter/configuration.lua"
local _DataPath = "kill-counters.txt"
local _SessionsPath = "sessions"

local _PlayerMyIndex = 0x00A9C4F4
local _PlayerArray = 0x00A94254
local _PlayerCount = 0x00AAE168
local _BankPointer = 0x00A95EE0

local _Difficulty = 0x00A9CD68
local _Episode = 0x00A9B1C8
local _Area = 0x00AC9CF8
local _SectionID = 0x00A9C4D8
local _Location = 0x00AAFCA0

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

if not _Success then
    _Configuration = {
        configurationWindow = true,
        globalCounterWindow = false,
        globalCounterDetailWindow = false,
        sessionCounterWindow = false,
        sessionInfoWindow = false,
        fontScale = 1.0
    }
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
        io.write(string.format("    sessionInfoWindow = %s,\n", tostring(_Configuration.sessionInfoWindow)))
        io.write(string.format("    fontScale = %f\n", _Configuration.fontScale))
        io.write("}\n")

        io.close(file)
    end
end

local function Dimensions()
    local _getArea = function()
        local area = pso.read_u32(_Area)

        -- Convert Dark Falz' area to Ruins
        if area == 4 then
            area = 3
        end

        return area
    end

    local this = {
        difficulty = pso.read_u32(_Difficulty),
        episode = pso.read_u32(_Episode),
        sectionID = pso.read_u32(_SectionID),
        area = _getArea(),
        hasChanged = true
    }

    this.update = function()
        local difficulty = pso.read_u32(_Difficulty)
        local episode = pso.read_u32(_Episode)
        local sectionID = pso.read_u32(_SectionID)
        local area = _getArea()

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
        modified = false
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

        this.visible = {}

        for i,counter in ipairs(this.all) do
            local isMatch =
                counter.difficulty == _dimensions.difficulty and
                counter.episode == _dimensions.episode and
                counter.sectionID == _dimensions.sectionID and
                counter.area == _dimensions.area

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

        this.modified = false

        if _dimensions.hasChanged then
            _buildVisibleCounters()
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
                    table.insert(this.visible, _makeVisibleCounter(counter))
                    table.sort(this.visible, _getCounterOrder)
                    this.byID[monster.id] = counter
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
        local lineFormat = "%-10s  ||  %-7s  ||  %-10s  ||  %-22s  ||  %-16s  ||  %s\n";
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

    this.getSessionPath = function(sessionsPath)
        return sessionsPath .. os.date("%Y-%m-%d\\%H.%m.%S", this.startTime)
    end

    this.update = function()
        local now = os.time()
        local playerCount = pso.read_u32(_PlayerCount)
        local playerAddress = _getPlayerAddress()
        local questNumber = _getQuestNumber()
        local location = pso.read_u32(_Location)
        local remainder = now - math.floor(now / 5) * 5

        this.modified = false

        if location == 0 then
            _timeSpentInDungeon = _timeSpentInDungeon + (_now - _startTimeInDungeon)
            _startTimeInDungeon = now
        end

        if _everBeenModified and _now ~= now and remainder == 0 then
            this.modified = true
        end

        _now = now

        if location == 0xF or playerCount == 0 or playerAddress == 0 then
            _reset()
            return
        end

        if this.questNumber ~= questNumber then
            _reset()
            this.questNumber = questNumber
        end

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
        sessionInfoWindow = nil
    }

    local _configuration = configuration

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
            if imgui.Checkbox("Session Info Counters", this.sessionInfoWindow.open) then
                this.sessionInfoWindow.open = not this.sessionInfoWindow.open
            end

            success,this.fontScale = imgui.InputFloat("Font Scale", this.fontScale)
            this.globalCounterWindow.fontScale = this.fontScale
            this.globalCounterDetailWindow.fontScale = this.fontScale
            this.sessionCounterWindow.fontScale = this.fontScale
            this.sessionInfoWindow.fontScale = this.fontScale

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

        _showWindowSettings()

        imgui.End()
    end

    this.hasChanged = function()
        return
            this.open ~= _configuration.configurationWindow or
            this.globalCounterWindow.open ~= _configuration.globalCounterWindow or
            this.globalCounterDetailWindow.open ~= _configuration.globalCounterDetailWindow or
            this.sessionCounterWindow.open ~= _configuration.sessionCounterWindow or
            this.sessionInfoWindow.open ~= _configuration.sessionInfoWindow or
            this.fontScale ~= _configuration.fontScale
    end

    return this
end

local function KillCounterWindow(killCounter)
    local this = {
        title = "Kill Counter - Main",
        fontScale = 1.0,
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

    this.update = function()
        if not this.open then
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
        open = false,
        exportFilePath = "kill-counters-export.txt"
    }

    local _killCounter = killCounter

    local _showExport = function()
        local lineFormat = "%-10s  ||  %-7s  ||  %-10s  ||  %-22s  ||  %-16s  ||  %s\n";

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

    this.update = function()
        if not this.open then
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
        open = false
    }

    local _session = session

    local _getValueOverTimeSpent = function(value, timeSpent)
        local valueOverTime = value / timeSpent
        local timePeriod = "per second"

        if valueOverTime < 1.0 then
            valueOverTime = valueOverTime * 60.0
            timePeriod = "per minute"
        end

        if valueOverTime < 1.0 then
            valueOverTime = valueOverTime * 60.0
            timePeriod = "per hour"
        end

        return string.format("%f %s", valueOverTime, timePeriod)
    end

    local _getFormattedTimeSpent = function(timeSpent)
        local epoch = 5 * 60 * 60
        return os.date("%H:%M:%S", timeSpent + epoch)
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

    this.update = function()
        if not this.open then
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
    _Dimensions.update()
    _MonsterTable.update()
    _GlobalCounter.update()
    _SessionCounter.update()
    _Session.update()

    _ConfigurationWindow.update()
    _GlobalCounterWindow.update()
    _GlobalCounterDetailWindow.update()
    _SessionCounterWindow.update()
    _SessionInfoWindow.update()

    if _ConfigurationWindow.hasChanged() then
        _Configuration.configurationWindow = _ConfigurationWindow.open
        _Configuration.globalCounterWindow = _GlobalCounterWindow.open
        _Configuration.globalCounterDetailWindow = _GlobalCounterDetailWindow.open
        _Configuration.sessionCounterWindow = _SessionCounterWindow.open
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
    _Dimensions = Dimensions()
    _MonsterTable = MonsterTable(_Dimensions)
    _GlobalCounter = KillCounter(_Dimensions, _MonsterTable)
    _SessionCounter = KillCounter(_Dimensions, _MonsterTable)
    _Session = Session(_Dimensions, _SessionCounter)

    _GlobalCounter.deserialize(_DataPath)

    _GlobalCounterWindow = KillCounterWindow(_GlobalCounter)
    _GlobalCounterWindow.title = "Kill Counter - Global"
    _GlobalCounterWindow.fontScale = _Configuration.fontScale
    _GlobalCounterWindow.open = _Configuration.globalCounterWindow

    _GlobalCounterDetailWindow = KillCounterDetailWindow(_GlobalCounter)
    _GlobalCounterDetailWindow.title = "Kill Counter - Global Detail"
    _GlobalCounterDetailWindow.fontScale = _Configuration.fontScale
    _GlobalCounterDetailWindow.open = _Configuration.globalCounterDetailWindow

    _SessionCounterWindow = KillCounterWindow(_SessionCounter)
    _SessionCounterWindow.title = "Kill Counter - Session"
    _SessionCounterWindow.fontScale = _Configuration.fontScale
    _SessionCounterWindow.open = _Configuration.sessionCounterWindow

    _SessionInfoWindow = SessionInfoWindow(_Session)
    _SessionInfoWindow.title = "Kill Counter - Session Info"
    _SessionInfoWindow.fontScale = _Configuration.fontScale
    _SessionInfoWindow.open = _Configuration.sessionInfoWindow

    _ConfigurationWindow = ConfigurationWindow(_Configuration)
    _ConfigurationWindow.fontScale = _Configuration.fontScale
    _ConfigurationWindow.globalCounterWindow = _GlobalCounterWindow
    _ConfigurationWindow.globalCounterDetailWindow = _GlobalCounterDetailWindow
    _ConfigurationWindow.sessionCounterWindow = _SessionCounterWindow
    _ConfigurationWindow.sessionInfoWindow = _SessionInfoWindow
    _ConfigurationWindow.open = _Configuration.configurationWindow

    local configurationButtonHandler = function()
        _ConfigurationWindow.open = not _ConfigurationWindow.open
    end

    _MainMenu.add_button('Kill Counter', configurationButtonHandler)

    return {
        name = "Kill Counter",
        version = "2.0.2",
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
