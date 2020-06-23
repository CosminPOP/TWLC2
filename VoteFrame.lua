local addonVer = "1.0.0" --don't use letters!
local me = UnitName('player')

TWLC_ROSTER = {}

function twprint(a)
    DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0[TWLC2] |cffffffff" .. a)
end

function twdebug(a)
    if (me == 'Er2' or
            me == 'Xerrbear' or
            me == 'Testwarr' or
            me == 'Kzktst' or
            me == 'Tabc') then
        twprint('|cff0070de[TWLC2Debug :' .. time() .. '] |cffffffff[' .. a .. ']')
    end
end

local RLWindowFrame = CreateFrame("Frame")
RLWindowFrame.assistFrames = {}

local LCVoteFrame = CreateFrame("Frame", "LCVoteFrame")

LCVoteFrame:RegisterEvent("ADDON_LOADED")
LCVoteFrame:RegisterEvent("LOOT_OPENED")
LCVoteFrame:RegisterEvent("LOOT_SLOT_CLEARED")
LCVoteFrame:RegisterEvent("LOOT_CLOSED")
LCVoteFrame:RegisterEvent("RAID_ROSTER_UPDATE")
LCVoteFrame:RegisterEvent("CHAT_MSG_SYSTEM")
LCVoteFrame.VotedItemsFrames = {}
LCVoteFrame.CurrentVotedItem = nil --slotIndex
LCVoteFrame.currentPlayersList = {} --all
LCVoteFrame.playersPerPage = 15
LCVoteFrame.itemVotes = {}
LCVoteFrame.LCVoters = 0
LCVoteFrame.playersWhoWantItems = {}
LCVoteFrame.voteTiePlayers = ''
LCVoteFrame.currentItemWinner = ''
LCVoteFrame.currentItemMaxVotes = 0
LCVoteFrame.currentRollWinner = ''
LCVoteFrame.currentMaxRoll = {}

LCVoteFrame.numPlayersThatWant = 0
LCVoteFrame.namePlayersThatWants = 0

LCVoteFrame.waitResponses = {}
LCVoteFrame.pickResponses = {}

local LCVoteFrameComms = CreateFrame("Frame")
LCVoteFrameComms:RegisterEvent("CHAT_MSG_ADDON")


local LCVoteSyncFrame = CreateFrame("Frame")

LCVoteSyncFrame.dataToSend = {}
LCVoteSyncFrame.NEW_ROSTER = {}
LCVoteSyncFrame:Hide()
LCVoteSyncFrame:SetScript("OnShow", function()
    if (LCVoteSyncFrame.dataToSend) then
        twdebug('[LCVoteSyncFrame] Starting...');
        this.startTime = (GetTime());
        this.dataIndex = 0
        for i = 1, table.getn(RLWindowFrame.assistFrames) do
            getglobal('AssistFrame' .. i .. 'AssistCheck'):Disable()
            getglobal('AssistFrame' .. i .. 'CLCheck'):Disable()
        end
    else
        twdebug('[LCVoteSyncFrame] no data to send');
        this.dataIndex = 0
    end
end)
LCVoteSyncFrame:SetScript("OnUpdate", function()
    if ((GetTime()) >= (this.startTime) + 0.1) then

        this.dataIndex = this.dataIndex + 1

        if (LCVoteSyncFrame.dataToSend[this.dataIndex]) then
            twdebug('sending... ' .. this.dataToSend[this.dataIndex])
            SendAddonMessage("TWLCNF", this.dataToSend[this.dataIndex], "RAID")
        else
            this:Hide()
            this.dataIndex = 0
            LCVoteSyncFrame.dataToSend = {}
            twdebug('[LCVoteSyncFrame] Sync finished.');
            SendAddonMessage("TWLCNF", "syncRoster=end", "RAID")

            if (twlc2isRL(me)) then checkAssists() end
        end

        this.startTime = (GetTime());
    else
    end
end)




local ContestantDropdownMenu = CreateFrame('Frame', 'ContestantDropdownMenu', UIParent, 'UIDropDownMenuTemplate')
ContestantDropdownMenu.currentContestantId = 0

local VoteCountdown = CreateFrame("Frame")


local TWLCCountDownFRAME = CreateFrame("Frame")
TWLCCountDownFRAME:Hide()
TWLCCountDownFRAME.currentTime = 1
TWLCCountDownFRAME:SetScript("OnShow", function()
    this.startTime = GetTime();
end)

TWLCCountDownFRAME:SetScript("OnUpdate", function()
    local plus = 0.03
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        if (TWLCCountDownFRAME.currentTime ~= TWLCCountDownFRAME.countDownFrom + plus) then
            --tick
            getglobal('LootLCVoteFrameWindowTimeLeftBar'):SetWidth((TWLCCountDownFRAME.countDownFrom - TWLCCountDownFRAME.currentTime + plus) * 500 / TWLCCountDownFRAME.countDownFrom)

            --            if (LCVoteFrame.pickResponses[LCVoteFrame.CurrentVotedItem] and LCVoteFrame.waitResponses[LCVoteFrame.CurrentVotedItem]) then
            --                if (TWLCCountDownFRAME.countDownFrom - TWLCCountDownFRAME.currentTime > 0) then
            --                    getglobal('LootLCVoteFrameWindowContestantCount'):SetText('(' .. math.floor(TWLCCountDownFRAME.countDownFrom - TWLCCountDownFRAME.currentTime) .. 's) Waiting picks ' ..
            --                            LCVoteFrame.pickResponses[LCVoteFrame.CurrentVotedItem] .. '/' .. LCVoteFrame.waitResponses[LCVoteFrame.CurrentVotedItem])
            --                end
            --            end
        end
        TWLCCountDownFRAME:Hide()
        if (TWLCCountDownFRAME.currentTime < TWLCCountDownFRAME.countDownFrom + plus) then
            --still tick
            TWLCCountDownFRAME.currentTime = TWLCCountDownFRAME.currentTime + plus
            TWLCCountDownFRAME:Show()
        elseif (TWLCCountDownFRAME.currentTime > TWLCCountDownFRAME.countDownFrom + plus) then

            --end
            TWLCCountDownFRAME:Hide()
            TWLCCountDownFRAME.currentTime = 1

            VoteCountdown:Show()

        else
            --
        end
    else
        --
    end
end)

VoteCountdown:Hide()
VoteCountdown.currentTime = 1
VoteCountdown.countDownFrom = 5
VoteCountdown:SetScript("OnShow", function()
    this.startTime = GetTime();
end)

VoteCountdown:SetScript("OnUpdate", function()
    local plus = 0.03
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        if (VoteCountdown.currentTime ~= VoteCountdown.countDownFrom + plus) then
            --tick

            for i = 1, LCVoteFrame.playersPerPage, 1 do
                if getglobal('ContestantFrame' .. i .. 'VoteButton'):IsEnabled() == 1 then
                    local w = math.floor(((VoteCountdown.countDownFrom - VoteCountdown.currentTime) / VoteCountdown.countDownFrom) * 1000)
                    w = w / 1000

                    if (w >= 0 and w <= 1) then
                        getglobal('ContestantFrame' .. i .. 'VoteButtonTimeLeftBackground'):SetWidth(w * 90)
                        getglobal('ContestantFrame' .. i .. 'VoteButtonMainBackground'):SetTexture(0.05, 0.56, 0.23, w)
                    end
                end
            end
            VoteCountdown:Hide()
            if (VoteCountdown.currentTime < VoteCountdown.countDownFrom + plus) then
                --still tick
                VoteCountdown.currentTime = VoteCountdown.currentTime + plus
                VoteCountdown:Show()
            elseif (VoteCountdown.currentTime > VoteCountdown.countDownFrom + plus) then

                --end
                VoteCountdown:Hide()
                VoteCountdown.currentTime = 1
                for i = 1, LCVoteFrame.playersPerPage, 1 do
                    if getglobal('ContestantFrame' .. i .. 'VoteButton'):IsEnabled() == 1 then
                        getglobal('ContestantFrame' .. i .. 'VoteButton'):Disable()
                        getglobal('ContestantFrame' .. i .. 'VoteButtonTimeLeftBackground'):SetTexture(0.4, 0.4, 0.4, 0)
                        getglobal('ContestantFrame' .. i .. 'VoteButtonMainBackground'):SetTexture(0.4, 0.4, 0.4, .4)
                    end
                end
                twdebug('vote countdown finished')
            end
        else
            --
        end
    else
        --
    end
end)


SLASH_TWLC1 = "/twlc"
SlashCmdList["TWLC"] = function(cmd)
    if (cmd) then
        if (string.find(cmd, 'add', 1, true)) then
            local setEx = string.split(cmd, ' ')
            if (setEx[2]) then
                addToRoster(setEx[2])
            else
                twprint('Adds LC member')
                twprint('sintax: /twlc add <name>')
            end
        end
        if (string.find(cmd, 'rem', 1, true)) then
            local setEx = string.split(cmd, ' ')
            if (setEx[2]) then
                remFromRoster(setEx[2])
            else
                twprint('Removes LC member')
                twprint('sintax: /twlc rem <name>')
            end
        end
        if (string.find(cmd, 'set', 1, true)) then
            local setEx = string.split(cmd, ' ')
            if (setEx[2] and setEx[3]) then
                if (setEx[2] == 'ttn') then
                    TIME_TO_NEED = tonumber(setEx[3])
                    TWLCCountDownFRAME.countDownFrom = TIME_TO_NEED
                    twprint('TIME_TO_NEED - set to ' .. TIME_TO_NEED .. 's')
                    SendAddonMessage("TWLCNF", 'ttn=' .. TIME_TO_NEED, "RAID")
                end
            else
                twprint('SET Options')
                twprint('sintax: /twlc set ttn <time> - sets TIME_TO_NEED (current value: ' .. TIME_TO_NEED .. 's)')
            end
        end
        if (string.find(cmd, 'list', 1, true)) then
            listRoster()
        end
        if (cmd == 'show') then
            getglobal("LootLCVoteFrameWindow"):Show()
        end
        --        if (cmd == 'who') then
        --            lcprint("Listing people with the addon (* = can vote):")
        --            resetRoster()
        --            if isAssistOrRL(me) then
        --                lcprint("*" .. colorPlayer(me) .. " version " .. addonVer .. ")")
        --            else
        --                lcprint("" .. colorPlayer(me) .. " version " .. addonVer .. ")")
        --            end
        --            if (LCRoster[me] ~= nil) then
        --                LCRoster[me] = true
        --            end
        --            lcWho()
        --        end
    end
end

local minibtn = getglobal('TWLC2_Minimap')

function toggleMainWindow()
    if (getglobal('LootLCVoteFrameWindow'):IsVisible()) then
        getglobal('LootLCVoteFrameWindow'):Hide()
    else
        getglobal('LootLCVoteFrameWindow'):Show()
    end
end

function addToRoster(newName)
    if (not twlc2isRL(me)) then
        twprint('You are not the raid leader.')
        return
    end
    for name, v in next, TWLC_ROSTER do
        if (name == newName) then
            twprint(newName .. ' already exists.')
            return false
        end
    end
    TWLC_ROSTER[newName] = false
    twprint(newName .. ' added to TWLC Roster')
    syncRoster()
end

function remFromRoster(newName)
    if (not twlc2isRL(me)) then
        twprint('You are not the raid leader.')
        return
    end
    for name, v in next, TWLC_ROSTER do
        if (name == newName) then
            TWLC_ROSTER[newName] = nil
            twprint(newName .. ' removed from TWLC Roster')
            syncRoster()
            return true
        end
    end
    twprint(newName .. ' does not exist in the roster.')
end

function listRoster()
    local roster = ''
    for name, v in next, TWLC_ROSTER do
        roster = roster .. name .. ' '
    end
    twprint('Listing TWLC Roster')
    twprint(roster)
end

function syncRoster()
    local index = 0
    for name, v in next, TWLC_ROSTER do
        index = index + 1
        LCVoteSyncFrame.dataToSend[index] = "syncRoster=" .. name
    end
    SendAddonMessage("TWLCNF", "syncRoster=start", "RAID")
    LCVoteSyncFrame:Show()
end

--RAID_CLASS_COLORS
--r, g, b, hex = GetItemQualityColor(quality)
local classColors = {
    ["warrior"] = { r = 0.78, g = 0.61, b = 0.43, c = "|cffc79c6e" },
    ["mage"] = { r = 0.41, g = 0.8, b = 0.94, c = "|cff69ccf0" },
    ["rogue"] = { r = 1, g = 0.96, b = 0.41, c = "|cfffff569" },
    ["druid"] = { r = 1, g = 0.49, b = 0.04, c = "|cffff7d0a" },
    ["hunter"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cffabd473" },
    ["shaman"] = { r = 0.14, g = 0.35, b = 1.0, c = "|cff0070de" },
    ["priest"] = { r = 1, g = 1, b = 1, c = "|cffffffff" },
    ["warlock"] = { r = 0.58, g = 0.51, b = 0.79, c = "|cff9482c9" },
    ["paladin"] = { r = 0.96, g = 0.55, b = 0.73, c = "|cfff58cba" },
    ["krieger"] = { r = 0.78, g = 0.61, b = 0.43, c = "|cffc79c6e" },
    ["magier"] = { r = 0.41, g = 0.8, b = 0.94, c = "|cff69ccf0" },
    ["schurke"] = { r = 1, g = 0.96, b = 0.41, c = "|cfffff569" },
    ["druide"] = { r = 1, g = 0.49, b = 0.04, c = "|cffff7d0a" },
    ["jäger"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cffabd473" },
    ["schamane"] = { r = 0.14, g = 0.35, b = 1.0, c = "|cff0070de" },
    ["priester"] = { r = 1, g = 1, b = 1, c = "|cffffffff" },
    ["hexenmeister"] = { r = 0.58, g = 0.51, b = 0.79, c = "|cff9482c9" },
}

local needs = {
    ["bis"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cffa335ee", text = 'BIS' },
    ["ms"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cff0070dd", text = 'MS Upgrade' },
    ["os"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cffe79e08", text = 'Offspec' },
    ["pass"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cff696969", text = 'pass' },
    ["autopass"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cff696969", text = 'auto pass' },
    ["wait"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cff999999", text = 'Waiting pick...' },
}

local itemTypes = {
    [0] = 'Consumable',
    [1] = 'Container',
    [2] = 'Weapon',
    [3] = 'Gem',
    [4] = 'Armor',
    [5] = 'Reagent',
    [6] = 'Projectile',
    [7] = 'Tradeskill',
    [8] = 'Item Enhancement',
    [9] = 'Recipe',
    [10] = 'Money(OBSOLETE)',
    [11] = 'Quiver	Obsolete',
    [12] = 'Quest',
    [13] = 'Key	Obsolete',
    [14] = 'Permanent(OBSOLETE)',
    [15] = 'Miscellaneous'
}

local equipSlots = {
    ["INVTYPE_AMMO"] = 'Ammo', --	0', --
    ["INVTYPE_HEAD"] = 'Head', --	1',
    ["INVTYPE_NECK"] = 'Neck', --	2',
    ["INVTYPE_SHOULDER"] = 'Shoulder', --	3',
    ["INVTYPE_BODY"] = 'Shirt', --	4',
    ["INVTYPE_CHEST"] = 'Chest', --	5',
    ["INVTYPE_ROBE"] = 'Chest', --	5',
    ["INVTYPE_WAIST"] = 'Waist', --	6',
    ["INVTYPE_LEGS"] = 'Legs', --	7',
    ["INVTYPE_FEET"] = 'Feet', --	8',
    ["INVTYPE_WRIST"] = 'Wrist', --	9',
    ["INVTYPE_HAND"] = 'Hands', --	10',
    ["INVTYPE_FINGER"] = 'Ring', --	11,12',
    ["INVTYPE_TRINKET"] = 'Trinket', --	13,14',
    ["INVTYPE_CLOAK"] = 'Cloak', --	15',
    ["INVTYPE_WEAPON"] = 'One-Hand', --	16,17',
    ["INVTYPE_SHIELD"] = 'Shield', --	17',
    ["INVTYPE_2HWEAPON"] = 'Two-Handed', --	16',
    ["INVTYPE_WEAPONMAINHAND"] = 'Main-Hand Weapon', --	16',
    ["INVTYPE_WEAPONOFFHAND"] = 'Off-Hand Weapon', --	17',
    ["INVTYPE_HOLDABLE"] = 'Held In Off-Hand', --	17',
    ["INVTYPE_RANGED"] = 'Bow', --	18',
    ["INVTYPE_THROWN"] = 'Ranged', --	18',
    ["INVTYPE_RANGEDRIGHT"] = 'Wands, Guns, and Crossbows', --	18',
    ["INVTYPE_RELIC"] = 'Relic', --	18',
    ["INVTYPE_TABARD"] = 'Tabard', --	19',
    ["INVTYPE_BAG"] = 'Container', --	20,21,22,23',
    ["INVTYPE_QUIVER"] = 'Quiver', --	20,21,22,23',
}

function getEquipSlot(j)
    for k, v in next, equipSlots do
        if (k == tostring(j)) then return v end
    end
    return ''
end

function GetPlayer(index)
    return LCVoteFrame.playersWhoWantItems[index]
end

LCVoteFrame:SetScript("OnEvent", function()
    if (event) then
        --        twdebug(event)
        if (event == "RAID_ROSTER_UPDATE") then
            if (twlc2isRL(me)) then
                getglobal('RLOptionsButton'):Show()
                getglobal('MLToWinner'):Show()
                getglobal('MLToWinner'):Disable()
                checkAssists() --todo asta poate trebuie on ?
            else
                getglobal('MLToWinner'):Hide()
            end
        end
        if (event == "CHAT_MSG_SYSTEM") then
            if (string.find(arg1, "rolls", 1, true) and not string.find(arg1, "(1-100)", 1, true)) then --vote tie rolls
                local r = string.split(arg1, " ")
                twdebug(' ' .. r[1] .. ' rolls ' .. r[3])
            end
        end
        if (event == "ADDON_LOADED" and arg1 == 'TWLC2') then

            if (not TIME_TO_NEED) then TIME_TO_NEED = 30 end

            TWLCCountDownFRAME.countDownFrom = TIME_TO_NEED

            getglobal('LootLCVoteFrameWindowTitle'):SetText('Turtle WoW Loot Council2 v' .. addonVer)

            getglobal('BroadcastLoot'):Disable()

            if (twlc2isRL(me)) then
                getglobal('RLOptionsButton'):Show()
                getglobal('ResetClose'):Show()
            else
                getglobal('RLOptionsButton'):Hide()
                getglobal('ResetClose'):Hide()
            end


            local backdrop = {
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
                tile = false,
                tileSize = 0,
                edgeSize = 1
            };
            --            getglobal('LootLCVoteFrameWindow'):SetBackdrop(backdrop);
            --            getglobal('LootLCVoteFrameWindow'):SetBackdropColor(0, 0, 0, .7);
            --            getglobal('LootLCVoteFrameWindow'):SetBackdropBorderColor(0, 0, 0, 1);
        end
        if (event == "LOOT_OPENED") then
            if (twlc2isRL(me)) then
                getglobal('BroadcastLoot'):Show()
                getglobal('BroadcastLoot'):Enable()
                getglobal('LootLCVoteFrameWindow'):Show()
                --            BroadcastLoot_OnClick() -- dev
            end
        end
        if (event == "LOOT_SLOT_CLEARED") then
        end
        if (event == "LOOT_CLOSED") then
            getglobal('BroadcastLoot'):Hide()
            getglobal('BroadcastLoot'):Disable()
        end
    end
end)

function setCLFromUI(id, to)

    if (to) then
        addToRoster(RLWindowFrame.assistFrames[id].name)
    else
        remFromRoster(RLWindowFrame.assistFrames[id].name)
    end
end

function setAssistFromUI(id, to)
    for i = 0, GetNumRaidMembers() do
        if (GetRaidRosterInfo(i)) then
            local n, r = GetRaidRosterInfo(i);
            if (n == RLWindowFrame.assistFrames[id].name) then
                if (to) then
                    twdebug('promote ')
                    PromoteToAssistant(n)
                else
                    twdebug('demote ')
                    DemoteAssistant(n)
                end
                return true
            end
        end
    end
    return false
end


function toggleRLOptionsFrame()
    if getglobal('RLWindowFrame'):IsVisible() then
        getglobal('RLWindowFrame'):Hide()
    else
        getglobal('RLWindowFrame'):Show()
        checkAssists()
    end
end

function checkAssists()


    local assistsAndCL = {}
    --get assists
    local i
    for i = 0, GetNumRaidMembers() do
        if (GetRaidRosterInfo(i)) then
            local n, r = GetRaidRosterInfo(i);
            if (r == 2 or r == 1) then
                assistsAndCL[n] = false
            end
        end
    end
    --getcls
    if (TWLC_ROSTER) then
        for clName in next, TWLC_ROSTER do
            assistsAndCL[clName] = false
        end
    end

    for i = 1, table.getn(RLWindowFrame.assistFrames), 1 do
        RLWindowFrame.assistFrames[i]:Hide()
    end

    local people = {}

    i = 0
    -- todo maybe remove this block
    for name, cl in next, assistsAndCL do
        i = i + 1

        people[i] = {
            y = -60 - 25 * i,
            color = classColors[getPlayerClass(name)].c,
            name = name,
            assist = twlc2isRLorAssist(name),
            cl = TWLC_ROSTER[name] ~= nil
        }
    end

    for i, d in next, people do
        if (not RLWindowFrame.assistFrames[i]) then
            RLWindowFrame.assistFrames[i] = CreateFrame('Frame', 'AssistFrame' .. i, getglobal("RLWindowFrame"), 'CLListFrameTemplate')
        end

        RLWindowFrame.assistFrames[i]:SetPoint("TOPLEFT", getglobal("RLWindowFrame"), "TOPLEFT", 0, d.y)
        RLWindowFrame.assistFrames[i]:Show()
        RLWindowFrame.assistFrames[i].name = d.name

        getglobal('AssistFrame' .. i .. 'AName'):SetText(d.color .. d.name)
        getglobal('AssistFrame' .. i .. 'CLCheck'):Enable()
        getglobal('AssistFrame' .. i .. 'AssistCheck'):Enable()

        getglobal('AssistFrame' .. i .. 'StatusIconOnline'):Hide()
        getglobal('AssistFrame' .. i .. 'StatusIconOffline'):Show()
        getglobal('AssistFrame' .. i .. 'AssistCheck'):Disable()
        if onlineInRaid(d.name) then
            getglobal('AssistFrame' .. i .. 'StatusIconOnline'):Show()
            getglobal('AssistFrame' .. i .. 'StatusIconOffline'):Hide()
            getglobal('AssistFrame' .. i .. 'AssistCheck'):Enable()
        end

        getglobal('AssistFrame' .. i .. 'CLCheck'):SetID(i)
        getglobal('AssistFrame' .. i .. 'AssistCheck'):SetID(i)

        getglobal('AssistFrame' .. i .. 'AssistCheck'):SetChecked(d.assist)
        getglobal('AssistFrame' .. i .. 'CLCheck'):SetChecked(d.cl)

        if (d.name == me) then getglobal('AssistFrame' .. i .. 'CLCheck'):Disable()
        end
        if (d.name == me) then getglobal('AssistFrame' .. i .. 'AssistCheck'):Disable()
        end
    end
end

function sendReset()
    SendAddonMessage("TWLCNF", "needframe=reset", "RAID")
    SendAddonMessage("TWLCNF", "voteframe=reset", "RAID")
end

function sendCloseWindow()
    SendAddonMessage("TWLCNF", "voteframe=close", "RAID")
end

function LCVoteFrame.closeWindow()
    getglobal('LootLCVoteFrameWindow'):Hide()
end

function LCVoteFrame.showWindow()
    getglobal('LootLCVoteFrameWindow'):Show()
end

--TWLCCloseLootFrame = HideUIPanel
--function HideUIPanel(frame)
--    twdebug('----------hideuicall----')
--    if (frame == LootFrame) then
--        twdebug('hideui ------------------ lootframe call')
--        TWLCCloseLootFrame(LootFrame)
--    else
--        twdebug('hideui otherframe call ')
--        TWLCCloseLootFrame(frame)
--    end
--end

--[[
doua functii. reset & close
]] --

function ResetClose_OnClick()
    sendReset()
    sendCloseWindow()
end

function BroadcastLoot_OnClick()

    SendAddonMessage("TWLCNF", 'ttn=' .. TIME_TO_NEED, "RAID")

    sendReset()

    SendAddonMessage("TWLCNF", "voteframe=show", "RAID")

    twdebug('broadcast start')

    TWLCCountDownFRAME:Show()
    SendAddonMessage("TWLCNF", 'countdownframe=show', "RAID")


    for id = 0, GetNumLootItems() do
        if GetLootSlotInfo(id) and GetLootSlotLink(id) then
            local lootIcon, lootName, _, _, q = GetLootSlotInfo(id)

            local _, _, itemLink = string.find(GetLootSlotLink(id), "(item:%d+:%d+:%d+:%d+)");
            local _, _, quality = GetItemInfo(itemLink)
            if (quality >= 0) then
                SendAddonMessage("TWLCNF", "loot=" .. id .. "=" .. lootIcon .. "=" .. lootName .. "=" .. GetLootSlotLink(id) .. "=" .. TWLCCountDownFRAME.countDownFrom, "RAID")
            end
        end
    end
    getglobal("MLToWinner"):Disable();
end

function addVotedItem(index, texture, name, link)

    --    twdebug('addvoteditem ' .. index)

    LCVoteFrame.itemVotes[index] = {}

    if (not LCVoteFrame.VotedItemsFrames[index]) then
        LCVoteFrame.VotedItemsFrames[index] = CreateFrame("Frame", "VotedItem" .. index,
            getglobal("VotedItemsFrame"), "VotedItemsFrameTemplate")
        --        twdebug('created frame ' .. index)
    end

    LCVoteFrame.VotedItemsFrames[index]:SetPoint("TOPLEFT", getglobal("VotedItemsFrame"), "TOPLEFT", 7, 40 - (40 * index))

    LCVoteFrame.VotedItemsFrames[index]:Show()
    LCVoteFrame.VotedItemsFrames[index].link = link
    LCVoteFrame.VotedItemsFrames[index].texture = texture
    LCVoteFrame.VotedItemsFrames[index].awardedTo = ''

    addButtonOnEnterTooltip(getglobal('VotedItem' .. index .. 'VotedItemButton'), link)

    --    getglobal('VotedItem' .. index .. 'VotedItemButton'):Show()
    getglobal('VotedItem' .. index .. 'VotedItemButton'):SetID(index)
    getglobal('VotedItem' .. index .. 'VotedItemButton'):SetNormalTexture(texture)
    getglobal('VotedItem' .. index .. 'VotedItemButton'):SetPushedTexture(texture)
    getglobal('VotedItem' .. index .. 'VotedItemButton'):SetHighlightTexture(texture)

    getglobal('VotedItem' .. index .. 'VotedItemButtonCheck'):Hide()
    getglobal('VotedItem' .. index .. 'VotedItemButton'):SetHighlightTexture(texture)

    --    twdebug('show : ' .. index)

    if (index ~= 1) then
        SetDesaturation(getglobal('VotedItem' .. index .. 'VotedItemButton'):GetNormalTexture(), 1)
    end

    if (not LCVoteFrame.CurrentVotedItem) then
        VotedItemButton_OnClick(index)
    end

    --    local _, _, itemLink = string.find(link, "(item:%d+:%d+:%d+:%d+)");
    --    twdebug('itemLink in addVotedItem: ' .. itemLink)
    --    local name, link, quality, reqlvl, t1, t2, a7, equip_slot, tex = GetItemInfo(itemLink)
    --    twdebug('a1 : ' .. name)
    --    twdebug('a2 : ' .. link)
    --    twdebug('a3 : ' .. quality)
    --    twdebug('reqlvl : ' .. reqlvl)
    --    twdebug('t1 : ' .. t1)
    --    twdebug('t2 : ' .. t2)
    --    twdebug('a7 : ' .. a7)
    --    twdebug('equip_slot : ' .. equip_slot)
    --    twdebug('tex : ' .. tex)
    --           twdebug(itemSubType)
    --           twdebug(itemEquipLoc)
end

function VotedItemButton_OnClick(id)

    getglobal('MLToWinner'):Hide()
    if (twlc2isRL(me)) then
        getglobal('MLToWinner'):Show()
    end

    SetDesaturation(getglobal('VotedItem' .. id .. 'VotedItemButton'):GetNormalTexture(), 0)
    for index, v in next, LCVoteFrame.VotedItemsFrames do
        if (index ~= id) then
            SetDesaturation(getglobal('VotedItem' .. index .. 'VotedItemButton'):GetNormalTexture(), 1)
        end
    end
    setCurrentVotedItem(id)
end

function setCurrentVotedItem(id)
    LCVoteFrame.CurrentVotedItem = id

    getglobal('LootLCVoteFrameWindowCurrentVotedItemIcon'):Show()
    getglobal('LootLCVoteFrameWindowVotedItemName'):Show()
    getglobal('LootLCVoteFrameWindowVotedItemType'):Show()

    getglobal('LootLCVoteFrameWindowCurrentVotedItemIcon'):SetNormalTexture(LCVoteFrame.VotedItemsFrames[id].texture)
    getglobal('LootLCVoteFrameWindowCurrentVotedItemIcon'):SetPushedTexture(LCVoteFrame.VotedItemsFrames[id].texture)

    local link = LCVoteFrame.VotedItemsFrames[id].link
    getglobal('LootLCVoteFrameWindowVotedItemName'):SetText(link)
    addButtonOnEnterTooltip(getglobal('LootLCVoteFrameWindowCurrentVotedItemIcon'), link)

    local _, _, itemLink = string.find(link, "(item:%d+:%d+:%d+:%d+)");
    local name, link, quality, reqlvl, t1, t2, a7, equip_slot, tex = GetItemInfo(itemLink)
    local votedItemType = ''
    --    if (t1) then votedItemType = t1 end
    if (t2) then votedItemType = votedItemType .. t2
    end
    if (equip_slot) then votedItemType = votedItemType .. ' ' .. getEquipSlot(equip_slot)
    end
    getglobal('LootLCVoteFrameWindowVotedItemType'):SetText(votedItemType)
    VoteFrameListScroll_Update()
end

function getPlayerInfo(playerIndexOrName)
    if (type(playerIndexOrName) == 'string') then
        for k, player in next, LCVoteFrame.currentPlayersList do
            if player['name'] == playerIndexOrName then
                return player['itemIndex'], player['name'], player['need'], player['votes'], player['ci1'], player['ci2'], player['roll'], k
            end
        end
    end
    local player = LCVoteFrame.currentPlayersList[playerIndexOrName]
    if (player) then
        return player['itemIndex'], player['name'], player['need'], player['votes'], player['ci1'], player['ci2'], player['roll'], playerIndexOrName
    else
        return false
    end
end

function getPlayerClass(name)
    for i = 0, GetNumRaidMembers() do
        if (GetRaidRosterInfo(i)) then
            local n = GetRaidRosterInfo(i);
            local _, unitClass = UnitClass('raid' .. i) --standard
            if (name == n) then
                return string.lower(unitClass)
            end
        end
    end
    return 'priest'
end

function buildContestantMenu()
    local id = ContestantDropdownMenu.currentContestantId
    local separator = {};
    separator.text = ""
    separator.disabled = true

    local title = {};
    title.text = getglobal("ContestantFrame" .. id .. "Name"):GetText()
    title.disabled = false
    title.isTitle = true
    title.func =
    function()
        --
    end
    UIDropDownMenu_AddButton(title);
    UIDropDownMenu_AddButton(separator);

    local award = {};
    award.text = "Award " .. getglobal('LootLCVoteFrameWindowVotedItemName'):GetText()
    award.disabled = LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].awardedTo ~= ''
    award.isTitle = false
    award.tooltipTitle = 'Award Raider'
    award.tooltipText = 'Give him them loots'
    award.justifyH = 'LEFT'
    award.func = function()
        awardWithConfirmation(getglobal("ContestantFrame" .. id).name)
        --        awardPlayer(getglobal("ContestantFrame" .. id).name)
    end
    UIDropDownMenu_AddButton(award);

    local close = {};
    close.text = "Close"
    close.disabled = false
    close.isTitle = false
    close.func =
    function()
        --
    end
    UIDropDownMenu_AddButton(close);
end

function ShowContenstantDropdownMenu(id)
    ContestantDropdownMenu.currentContestantId = id

    UIDropDownMenu_Initialize(ContestantDropdownMenu, buildContestantMenu, "MENU");
    ToggleDropDownMenu(1, nil, ContestantDropdownMenu, "cursor", 2, 3);
end

function buildMinimapMenu()
    local separator = {};
    separator.text = ""
    separator.disabled = true

    local title = {};
    title.text = "TWLC2"
    title.disabled = false
    title.isTitle = true
    title.func =
    function()
        --
    end
    UIDropDownMenu_AddButton(title);
    UIDropDownMenu_AddButton(separator);

    local menu1 = {};
    menu1.text = "Show/Hide Frame"
    menu1.disabled = false
    menu1.isTitle = false
    menu1.tooltipTitle = 'Show/Hide Frame'
    menu1.tooltipText = 'Shows/Hides Frame'
    menu1.justifyH = 'LEFT'
    menu1.func = function()
        toggleMainWindow()
    end
    UIDropDownMenu_AddButton(menu1);


    local close = {};
    close.text = "Close"
    close.disabled = false
    close.isTitle = false
    close.func =
    function()
        --
    end
    UIDropDownMenu_AddButton(close);
end

function ShowTWLCMinimapDropdown()
    local TWLC2MinimapMenuFrame = CreateFrame('Frame', 'TWLC2MinimapMenuFrame', UIParent, 'UIDropDownMenuTemplate')
    UIDropDownMenu_Initialize(TWLC2MinimapMenuFrame, buildMinimapMenu, "MENU");
    ToggleDropDownMenu(1, nil, TWLC2MinimapMenuFrame, "cursor", 2, 3);
end

function VoteFrameListScroll_Update()

    --    twdebug('VoteFrameListScroll_Update()');

    refreshList()
    calculateVotes()
    updateLCVoters()
    calculateWinner()

    if (not LCVoteFrame.pickResponses[LCVoteFrame.CurrentVotedItem]) then
        LCVoteFrame.pickResponses[LCVoteFrame.CurrentVotedItem] = 0
    end
    if (not LCVoteFrame.waitResponses[LCVoteFrame.CurrentVotedItem]) then
        LCVoteFrame.waitResponses[LCVoteFrame.CurrentVotedItem] = 0
    end
    if (LCVoteFrame.pickResponses[LCVoteFrame.CurrentVotedItem] == LCVoteFrame.waitResponses[LCVoteFrame.CurrentVotedItem]) then
        getglobal('LootLCVoteFrameWindowContestantCount'):SetText('|cff1fba1fEveryone(' .. LCVoteFrame.pickResponses[LCVoteFrame.CurrentVotedItem] .. ') has picked.')
    else
        getglobal('LootLCVoteFrameWindowContestantCount'):SetText('Waiting picks ' ..
                LCVoteFrame.pickResponses[LCVoteFrame.CurrentVotedItem] .. '/' .. LCVoteFrame.waitResponses[LCVoteFrame.CurrentVotedItem])
    end


    local itemIndex, name, need, votes, ci1, ci2, roll
    local playerIndex

    -- Scrollbar stuff
    local showScrollBar = false;
    if (table.getn(LCVoteFrame.currentPlayersList) > LCVoteFrame.playersPerPage) then
        showScrollBar = true;
    end

    local playerOffset = FauxScrollFrame_GetOffset(getglobal("ContestantScrollListFrame"));

    for i = 1, LCVoteFrame.playersPerPage, 1 do
        playerIndex = playerOffset + i;

        if (getPlayerInfo(playerIndex)) then


            getglobal("ContestantFrame" .. i):SetID(playerIndex)
            getglobal("ContestantFrame" .. i).playerIndex = playerIndex;
            itemIndex, name, need, votes, ci1, ci2, roll = getPlayerInfo(playerIndex);
            getglobal("ContestantFrame" .. i).name = name;


            local class = getPlayerClass(name)
            local color = classColors[class]

            getglobal("ContestantFrame" .. i .. "Name"):SetText(color.c .. name);
            getglobal("ContestantFrame" .. i .. "Need"):SetText(needs[need].c .. needs[need].text);
            if (roll > 0) then
                getglobal("ContestantFrame" .. i .. "Roll"):SetText(roll);
            else
                getglobal("ContestantFrame" .. i .. "Roll"):SetText();
            end

            getglobal("ContestantFrame" .. i .. "RightClickMenuButton1"):SetID(playerIndex);
            getglobal("ContestantFrame" .. i .. "RightClickMenuButton2"):SetID(playerIndex);
            getglobal("ContestantFrame" .. i .. "RightClickMenuButton3"):SetID(playerIndex);

            getglobal("ContestantFrame" .. i .. "Votes"):SetText(votes);
            if (votes == LCVoteFrame.currentItemMaxVotes and LCVoteFrame.currentItemMaxVotes > 0) then
                getglobal("ContestantFrame" .. i .. "Votes"):SetText('|cff1fba1f' .. votes);
            end

            getglobal("ContestantFrame" .. i .. "VoteButton"):Enable();

            if LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][name] then
                if LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][name][me] then
                    if LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][name][me] == '+' then
                        getglobal("ContestantFrame" .. i .. "VoteButton"):SetText('unvote')
                    else
                        getglobal("ContestantFrame" .. i .. "VoteButton"):SetText('VOTE')
                    end
                end
            end

            getglobal('ContestantFrame' .. i .. 'VoteButtonTimeLeftBackground'):SetTexture(0.05, 0.56, 0.23, 1)
            getglobal('ContestantFrame' .. i .. 'VoteButtonMainBackground'):SetTexture(0.05, 0.56, 0.23, 1)
            if (LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].awardedTo ~= '' or
                    LCVoteFrame.numPlayersThatWant == 1) then
                getglobal("ContestantFrame" .. i .. "VoteButton"):Disable();
                getglobal('ContestantFrame' .. i .. 'VoteButtonTimeLeftBackground'):SetTexture(0.4, 0.4, 0.4, .4)
                getglobal('ContestantFrame' .. i .. 'VoteButtonMainBackground'):SetTexture(0.4, 0.4, 0.4, .4)
            end

            getglobal("ContestantFrame" .. i .. "RollWinner"):Hide();
            if (LCVoteFrame.currentMaxRoll[LCVoteFrame.CurrentVotedItem] == roll and roll > 0) then
                getglobal("ContestantFrame" .. i .. "RollWinner"):Show();
            end
            getglobal("ContestantFrame" .. i .. "WinnerIcon"):Hide();
            if (LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].awardedTo == name) then
                getglobal("ContestantFrame" .. i .. "WinnerIcon"):Show();
            end

            getglobal("ContestantFrame" .. i .. "VoteButton"):SetID(playerIndex);

            getglobal('ContestantFrame' .. i):SetBackdropColor(color.r, color.g, color.b, 0.5);
            getglobal('ContestantFrame' .. i .. 'ClassIcon'):SetTexture('Interface\\AddOns\\TWLC2\\classes\\' .. class);

            getglobal("ContestantFrame" .. i .. "VoteButton"):Show();
            if (need == 'pass' or need == 'autopass' or need == 'wait') then
                getglobal("ContestantFrame" .. i .. "VoteButton"):Hide();
            end

            if (ci1 ~= "0") then
                local _, _, itemLink = string.find(ci1, "(item:%d+:%d+:%d+:%d+)");
                local n1, link, quality, reqlvl, t1, t2, a7, equip_slot, tex = GetItemInfo(itemLink)
                getglobal("ContestantFrame" .. i .. "ReplacesItem1"):SetNormalTexture(tex)
                getglobal("ContestantFrame" .. i .. "ReplacesItem1"):SetPushedTexture(tex)
                addButtonOnEnterTooltip(getglobal("ContestantFrame" .. i .. "ReplacesItem1"), itemLink)
                getglobal("ContestantFrame" .. i .. "ReplacesItem1"):Show()
            else
                getglobal("ContestantFrame" .. i .. "ReplacesItem1"):Hide()
            end
            if (ci2 ~= "0") then
                local _, _, itemLink = string.find(ci2, "(item:%d+:%d+:%d+:%d+)");
                local n1, link, quality, reqlvl, t1, t2, a7, equip_slot, tex = GetItemInfo(itemLink)
                getglobal("ContestantFrame" .. i .. "ReplacesItem2"):SetNormalTexture(tex)
                getglobal("ContestantFrame" .. i .. "ReplacesItem2"):SetPushedTexture(tex)
                addButtonOnEnterTooltip(getglobal("ContestantFrame" .. i .. "ReplacesItem2"), itemLink)
                getglobal("ContestantFrame" .. i .. "ReplacesItem2"):Show()
            else
                getglobal("ContestantFrame" .. i .. "ReplacesItem2"):Hide()
            end

            -- Highlight the correct who
            --        if (selectedRosterName == name) then
            --            getglobal("ContestantFrame" .. i):LockHighlight();
            --        else
            --            getglobal("ContestantFrame" .. i):UnlockHighlight();
            --        end

            if (playerIndex > table.getn(LCVoteFrame.currentPlayersList)) then
                getglobal("ContestantFrame" .. i):Hide();
            else
                getglobal("ContestantFrame" .. i):Show();
            end
        end
    end

    -- ScrollFrame update
    FauxScrollFrame_Update(getglobal("ContestantScrollListFrame"), table.getn(LCVoteFrame.currentPlayersList), LCVoteFrame.playersPerPage, 20);
end

function addButtonOnEnterTooltip(frame, itemLink)
    if (string.find(itemLink, "|", 1, true)) then
        local ex = string.split(itemLink, "|")

        frame:SetScript("OnEnter", function(self)
            LCTooltipVoteFrame:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4), -(this:GetHeight() / 4));
            LCTooltipVoteFrame:SetHyperlink(string.sub(ex[3], 2, string.len(ex[3])));
            LCTooltipVoteFrame:Show();
        end)
    else
        frame:SetScript("OnEnter", function(self)
            LCTooltipVoteFrame:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4), -(this:GetHeight() / 4));
            LCTooltipVoteFrame:SetHyperlink(itemLink);
            LCTooltipVoteFrame:Show();
        end)
    end
    frame:SetScript("OnLeave", function(self)
        LCTooltipVoteFrame:Hide();
    end)
end

function LCVoteFrame.updateVotedItemsFrames()
    --setCurrentVotedItem(LCVoteFrame.CurrentVotedItem)
    for index, v in next, LCVoteFrame.VotedItemsFrames do
        getglobal('VotedItem' .. index .. 'VotedItemButtonCheck'):Hide()
        if (LCVoteFrame.VotedItemsFrames[index].awardedTo ~= '') then
            getglobal('VotedItem' .. index .. 'VotedItemButtonCheck'):Show()
        end
    end

    VoteFrameListScroll_Update()
end

function LCVoteFrame.ResetVars(show)

    LCVoteFrame.CurrentVotedItem = nil
    LCVoteFrame.currentPlayersList = {}
    LCVoteFrame.playersWhoWantItems = {}

    LCVoteFrame.waitResponses = {}
    LCVoteFrame.pickResponses = {}

    LCVoteFrame.itemVotes = {}

    LCVoteFrame.myVotes = {}
    LCVoteFrame.LCVoters = 0

    getglobal('LootLCVoteFrameWindowContestantCount'):SetText()

    getglobal('BroadcastLoot'):Disable()
    getglobal("MLToWinner"):Hide()
    getglobal("MLToWinner"):Disable()
    getglobal("MLToWinnerNrOfVotes"):SetText()

    for index, frame in next, LCVoteFrame.VotedItemsFrames do
        getglobal('VotedItem' .. index):Hide()
    end

    for i = 1, LCVoteFrame.playersPerPage, 1 do
        getglobal("ContestantFrame" .. i):Hide()
    end

    TWLCCountDownFRAME.currentTime = 1

    getglobal('LootLCVoteFrameWindowTimeLeftBar'):SetWidth(500)


    getglobal('LootLCVoteFrameWindowCurrentVotedItemIcon'):Hide()
    getglobal('LootLCVoteFrameWindowVotedItemName'):Hide()
    getglobal('LootLCVoteFrameWindowVotedItemType'):Hide()

    getglobal('LootLCVoteFrameWindowVotedItemType'):Hide()
end

-- comms
LCVoteFrameComms:SetScript("OnEvent", function()
    if (event) then
        if event == 'CHAT_MSG_ADDON' and arg1 == "TWLCNF" then
            LCVoteFrameComms:handleSync(arg1, arg2, arg3, arg4)
        end
    end
end)


function LCVoteFrameComms:handleSync(pre, t, ch, sender)
    twdebug(sender .. ' says: ' .. t)
    if (string.find(t, 'playerRoll:', 1, true)) then

        if not twlc2isRL(sender) or sender == me then return end
        if not canVote(me) then return end

        local indexEx = string.split(t, ':')
        if (indexEx[2] and indexEx[3]) then
            LCVoteFrame.playersWhoWantItems[tonumber(indexEx[2])]['roll'] = tonumber(indexEx[3])
            VoteFrameListScroll_Update()
        else
            --todo
        end
    end
    if (string.find(t, 'itemVote:', 1, true)) then

        if not canVote(sender) or sender == me then return end
        if not canVote(me) then return end

        local itemVoteEx = string.split(t, ':')
        if (itemVoteEx[2] and itemVoteEx[3] and itemVoteEx[4]) then
            local votedItem = tonumber(itemVoteEx[2])
            local votedPlayer = itemVoteEx[3]
            local vote = itemVoteEx[4]
            --        twdebug('voteditem ' .. votedItem .. ' votedplayuer ' .. votedPlayer .. ' ' .. vote)
            if (not LCVoteFrame.itemVotes[votedItem][votedPlayer]) then
                LCVoteFrame.itemVotes[votedItem][votedPlayer] = {}
            end
            LCVoteFrame.itemVotes[votedItem][votedPlayer][sender] = vote
            VoteFrameListScroll_Update()
        else
            twdebug('[ERROR] string split : string.find(t, itemVote:, 1, true)')
            twdebug('split[1] = ' .. itemVoteEx[1])
            twdebug('split[2] = ' .. itemVoteEx[2])
            twdebug('split[3] = ' .. itemVoteEx[3])
            twdebug('split[4] = ' .. itemVoteEx[4])
        end
    end
    if (string.find(t, 'voteframe=', 1, true)) then

        if not twlc2isRL(sender) then return end
        if not canVote(me) then return end

        local command = string.split(t, '=')
        if (command[2]) then
            if (command[2] == "reset") then
                LCVoteFrame.ResetVars()
            end
            if (command[2] == "close") then
                LCVoteFrame.closeWindow()
            end
            if (command[2] == "show") then
                LCVoteFrame.showWindow()
            end
        else
            twdebug(' voteframe command not found')
        end
    end
    if (string.find(t, 'loot=', 1, true)) then

        if not twlc2isRL(sender) then return end

        local item = string.split(t, "=")
        if (item[2] and item[3] and item[4] and item[5]) then
            local index = tonumber(item[2])
            local texture = item[3]
            local name = item[4]
            local link = item[5]
            addVotedItem(index, texture, name, link)
        else
            twdebug('item = string.split(t, "=") error')
        end
    end
    if (string.find(t, 'countdownframe=', 1, true)) then

        if not twlc2isRL(sender) then return end
        if not canVote(me) then return end

        local action = string.split(t, "=")
        if (action[2]) then
            if (action[2] == 'show') then TWLCCountDownFRAME:Show()
            end
        end
    end
    if (string.find(t, 'wait=', 1, true)) then

        if not canVote(me) then return end

        local needEx = string.split(t, '=')

        if (needEx[2] and needEx[3] and needEx[4]) then

            --todo : check daca exista deja, limit once
            if (LCVoteFrame.waitResponses[tonumber(needEx[2])]) then
                LCVoteFrame.waitResponses[tonumber(needEx[2])] = LCVoteFrame.waitResponses[tonumber(needEx[2])] + 1
            else
                LCVoteFrame.waitResponses[tonumber(needEx[2])] = 1
            end

            LCVoteFrame.playersWhoWantItems[table.getn(LCVoteFrame.playersWhoWantItems) + 1] = {
                ['itemIndex'] = tonumber(needEx[2]),
                ['name'] = sender,
                ['need'] = 'wait',
                ['ci1'] = needEx[3],
                ['ci2'] = needEx[4],
                ['votes'] = 0,
                ['roll'] = 0
            }

            LCVoteFrame.itemVotes[tonumber(needEx[2])] = {}
            LCVoteFrame.itemVotes[tonumber(needEx[2])][sender] = {}

            VoteFrameListScroll_Update()
        else
            twdebug('needEx = string.split(t, =) error')
        end
    end
    --ms=1=item:123=item:323
    if (string.find(t, 'bis=', 1, true) or string.find(t, 'ms=', 1, true)
            or string.find(t, 'os=', 1, true) or string.find(t, 'pass=', 1, true)
            or string.find(t, 'autopass=', 1, true)) then
        --or string.find(t, 'wait=')
        local needEx = string.split(t, '=')

        --todo : check daca exista deja, limit once

        if (needEx[2] and needEx[3] and needEx[4]) then

            if (LCVoteFrame.pickResponses[tonumber(needEx[2])]) then
                LCVoteFrame.pickResponses[tonumber(needEx[2])] = LCVoteFrame.pickResponses[tonumber(needEx[2])] + 1
            else
                LCVoteFrame.pickResponses[tonumber(needEx[2])] = 1
            end

            for index, player in next, LCVoteFrame.playersWhoWantItems do
                if (player['name'] == sender and player['itemIndex'] == tonumber(needEx[2])) then
                    -- found the wait=
                    LCVoteFrame.playersWhoWantItems[index]['need'] = needEx[1]
                    LCVoteFrame.playersWhoWantItems[index]['ci1'] = needEx[3]
                    LCVoteFrame.playersWhoWantItems[index]['ci2'] = needEx[4]
                    break
                end
            end

            if (canVote(me)) then
                getglobal('LootLCVoteFrameWindow'):Show()
            else
                getglobal('LootLCVoteFrameWindow'):Hide()
            end

            VoteFrameListScroll_Update()

        else
            twdebug('needEx = string.split(t, =) error')
        end
    end
    -- roster sync
    if (string.find(t, 'syncRoster=', 1, true)) then
        if not twlc2isRL(sender) then return end
        if sender == me then return end

        local command = string.split(t, '=')
        if (command[2]) then
            if (command[2] == "start") then
                LCVoteSyncFrame.NEW_ROSTER = {}
            elseif (command[2] == "end") then
                TWLC_ROSTER = LCVoteSyncFrame.NEW_ROSTER
                twdebug('Roster updated.')
            else
                LCVoteSyncFrame.NEW_ROSTER[command[2]] = false
            end
        end
    end
    if (string.find(t, 'youWon=', 1, true)) then
        if (not twlc2isRL(sender)) then return end
        local wonData = string.split(t, "=")
        if wonData[4] then
            LCVoteFrame.VotedItemsFrames[tonumber(wonData[4])].awardedTo = wonData[2]
            LCVoteFrame.updateVotedItemsFrames()
            --            twdebug('setting itemindex to ' .. tonumber(wonData[4]) .. ' for ' .. wonData[2])
        end
    end
    if (string.find(t, 'ttn=', 1, true)) then
        if (not twlc2isRL(sender)) then return end
        local ttn = string.split(t, "=")
        if ttn[2] then
            TIME_TO_NEED = tonumber(ttn[2])
            TWLCCountDownFRAME.countDownFrom = TIME_TO_NEED
        end
    end
    if (string.find(t, 'withAddonNF=', 1, true)) then
        local i = string.split(t, "=")
        if (i[2] == me) then --i[2] = who requested the who
            if (i[4]) then
                local verColor = ""
                --todo : addonVer aici e de la voteframe, i4 e de la needframe.
                if (twlc_ver(i[4]) == twlc_ver(addonVer)) then verColor = classColors['hunter'].c end
                if (twlc_ver(i[4]) < twlc_ver(addonVer)) then verColor = '|cffff222a' end
                local color = classColors[getPlayerClass(i[3])]
                twdebug(color.c .. i[3] .. " v" .. verColor .. i[4])
            end
        end
    end
end

function refreshList()
    --    twdebug('refreshList()')
    -- sort list ?
    local tempTable = LCVoteFrame.playersWhoWantItems
    LCVoteFrame.playersWhoWantItems = {}
    local j = 0
    for index, d in next, tempTable do
        if d['need'] == 'bis' then
            j = j + 1
            LCVoteFrame.playersWhoWantItems[j] = d
        end
    end
    for index, d in next, tempTable do
        if d['need'] == 'ms' then
            j = j + 1
            LCVoteFrame.playersWhoWantItems[j] = d
        end
    end
    for index, d in next, tempTable do
        if d['need'] == 'os' then
            j = j + 1
            LCVoteFrame.playersWhoWantItems[j] = d
        end
    end
    for index, d in next, tempTable do
        if d['need'] == 'pass' then
            j = j + 1
            LCVoteFrame.playersWhoWantItems[j] = d
        end
    end
    for index, d in next, tempTable do
        if d['need'] == 'autopass' then
            j = j + 1
            LCVoteFrame.playersWhoWantItems[j] = d
        end
    end
    for index, d in next, tempTable do
        if d['need'] == 'wait' then
            j = j + 1
            LCVoteFrame.playersWhoWantItems[j] = d
        end
    end
    -- sort
    LCVoteFrame.currentPlayersList = {}
    for i = 1, LCVoteFrame.playersPerPage, 1 do
        getglobal('ContestantFrame' .. i):Hide();
    end
    for pIndex, data in next, LCVoteFrame.playersWhoWantItems do
        if (data['itemIndex'] == LCVoteFrame.CurrentVotedItem) then
            --            twdebug('printing LCVoteFrame.playersWhoWantItems[' .. pIndex .. ']')
            --            twdebug('name ' .. LCVoteFrame.playersWhoWantItems[pIndex]['name'])
            --            twdebug('votes ' .. LCVoteFrame.playersWhoWantItems[pIndex]['votes'])
            LCVoteFrame.currentPlayersList[table.getn(LCVoteFrame.currentPlayersList) + 1] = LCVoteFrame.playersWhoWantItems[pIndex]
        end
    end
end

function VoteButton_OnClick(id)
    local itemIndex, name = getPlayerInfo(id)

    if (not LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][name]) then
        LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][name] = {
            [me] = '+'
        }
        SendAddonMessage("TWLCNF", "itemVote:" .. LCVoteFrame.CurrentVotedItem .. ":" .. name .. ":+", "RAID")
    else
        if LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][name][me] == '+' then
            LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][name][me] = '-'
            SendAddonMessage("TWLCNF", "itemVote:" .. LCVoteFrame.CurrentVotedItem .. ":" .. name .. ":-", "RAID")
        else
            LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][name][me] = '+'
            SendAddonMessage("TWLCNF", "itemVote:" .. LCVoteFrame.CurrentVotedItem .. ":" .. name .. ":+", "RAID")
        end
    end

    VoteFrameListScroll_Update()
end

function calculateVotes()

    --    twdebug('calculateVotes()')
    --    twdebug('listing playerslist')
    --    local i = 0
    --    for k, player in next, LCVoteFrame.currentPlayersList do
    --        i = i + 1
    --        twdebug(player['itemIndex'] .. " pindex:" .. i .. "? " .. player['name'] .. " " .. player['need'] .. " " .. player['votes'] .. " " .. player['ci1'] .. " " .. player['ci2'] .. " " .. player['roll'])
    --    end
    --    twdebug('-------------- listing itemVotes, CI : ' .. LCVoteFrame.CurrentVotedItem)
    --    for k, players in next, LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem] do
    --        for kp, voters in next, players do
    --            twdebug(k .. ' vote from ' .. kp .. ' ' .. voters)
    --        end
    --    end

    --init votes to 0
    for pIndex in next, LCVoteFrame.currentPlayersList do
        LCVoteFrame.currentPlayersList[pIndex].votes = 0
    end

    for n, d in next, LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem] do

        local _, _, _, _, _, _, _, pIndex = getPlayerInfo(n)

        for voter, vote in next, LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][n] do
            if vote == '+' then
                LCVoteFrame.currentPlayersList[pIndex].votes = LCVoteFrame.currentPlayersList[pIndex].votes + 1
            else
            end
        end
    end
end

function calculateWinner()


    -- calc roll winner(s)
    LCVoteFrame.currentRollWinner = ''
    LCVoteFrame.currentMaxRoll[LCVoteFrame.CurrentVotedItem] = 0
    --    twdebug('calculare maxroll')
    for i, d in next, LCVoteFrame.currentPlayersList do
        if d['itemIndex'] == LCVoteFrame.CurrentVotedItem and d['roll'] > 0 and d['roll'] > LCVoteFrame.currentMaxRoll[LCVoteFrame.CurrentVotedItem] then
            LCVoteFrame.currentMaxRoll[LCVoteFrame.CurrentVotedItem] = d['roll']
            LCVoteFrame.currentRollWinner = d['name']
        end
    end
    --    twdebug('maxroll = ' .. LCVoteFrame.currentMaxRoll[LCVoteFrame.CurrentVotedItem])

    if (LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].awardedTo ~= '') then
        getglobal("MLToWinner"):Disable();
        getglobal("MLToWinner"):SetText('Awarded to ' .. LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].awardedTo);
        return
    end

    -- roll tie detection
    local rollTie = 0
    for i, d in next, LCVoteFrame.currentPlayersList do
        if d['itemIndex'] == LCVoteFrame.CurrentVotedItem and d['roll'] > 0 and d['roll'] == LCVoteFrame.currentMaxRoll[LCVoteFrame.CurrentVotedItem] then
            rollTie = rollTie + 1
        end
    end

    if (rollTie ~= 0) then
        if (rollTie == 1) then
            getglobal("MLToWinner"):Enable();
            getglobal("MLToWinner"):SetText('Award ' .. LCVoteFrame.currentRollWinner);
            twdebug('set text to award x')
            LCVoteFrame.currentItemWinner = LCVoteFrame.currentRollWinner
            LCVoteFrame.voteTiePlayers = ''
        else
            getglobal("MLToWinner"):Enable();
            getglobal("MLToWinner"):SetText('ROLL VOTE TIE'); -- .. voteTies
        end
        return
    else

        -- calc vote winner
        LCVoteFrame.currentItemWinner = ''
        LCVoteFrame.currentItemMaxVotes = 0
        LCVoteFrame.voteTiePlayers = '';
        LCVoteFrame.numPlayersThatWant = 0
        LCVoteFrame.namePlayersThatWants = ''
        for i, d in next, LCVoteFrame.currentPlayersList do
            if d['itemIndex'] == LCVoteFrame.CurrentVotedItem then

                -- calc winner if only one exists with bis, ms, os
                if d['need'] == 'bis' or d['need'] == 'ms' or d['need'] == 'os' then
                    LCVoteFrame.numPlayersThatWant = LCVoteFrame.numPlayersThatWant + 1
                    LCVoteFrame.namePlayersThatWants = d['name']
                end

                if (d['votes'] > 0 and d['votes'] > LCVoteFrame.currentItemMaxVotes) then
                    LCVoteFrame.currentItemMaxVotes = d['votes']
                    LCVoteFrame.currentItemWinner = d['name']
                end
            end
        end

        if (LCVoteFrame.numPlayersThatWant == 1) then
            LCVoteFrame.currentItemWinner = LCVoteFrame.namePlayersThatWants
            getglobal("MLToWinner"):Enable();
            getglobal("MLToWinner"):SetText('Award single needer ' .. LCVoteFrame.currentItemWinner);
            return
        end

        --    twdebug('maxVotes = ' .. maxVotes)
        --tie check
        local ties = 0
        for i, d in next, LCVoteFrame.currentPlayersList do
            if d['itemIndex'] == LCVoteFrame.CurrentVotedItem then
                if (d['votes'] == LCVoteFrame.currentItemMaxVotes and LCVoteFrame.currentItemMaxVotes > 0) then
                    LCVoteFrame.voteTiePlayers = LCVoteFrame.voteTiePlayers .. d['name'] .. ' '
                    ties = ties + 1
                end
            end
        end
        LCVoteFrame.voteTiePlayers = trim(LCVoteFrame.voteTiePlayers)

        if (ties > 1) then
            getglobal("MLToWinner"):Enable();
            getglobal("MLToWinner"):SetText('ROLL VOTE TIE'); -- .. voteTies
        else
            --no tie
            LCVoteFrame.voteTiePlayers = ''
            if (LCVoteFrame.currentItemWinner ~= '') then
                getglobal("MLToWinner"):Enable();
                getglobal("MLToWinner"):SetText('Award ' .. LCVoteFrame.currentItemWinner);
            else
                getglobal("MLToWinner"):Disable()
                getglobal("MLToWinner"):SetText('Waiting votes...')
            end
        end
    end
end

function updateLCVoters()

    local nr = 0
    -- reset OV
    for officer, voted in next, TWLC_ROSTER do
        TWLC_ROSTER[officer] = false
    end
    for n, d in next, LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem] do
        for voter, vote in next, LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][n] do
            for officer, voted in next, TWLC_ROSTER do
                if (voter == officer and vote == '+') then
                    TWLC_ROSTER[officer] = true
                end
            end
        end
    end
    for o, v in next, TWLC_ROSTER do
        if (v) then nr = nr + 1
        end
    end
    local numOfficersInRaid = 0
    for o, v in next, TWLC_ROSTER do
        if onlineInRaid(o) then
            numOfficersInRaid = numOfficersInRaid + 1
        end
    end
    if (nr == numOfficersInRaid) then
        getglobal('MLToWinnerNrOfVotes'):SetText('|cff1fba1fEveryone voted!')
    else
        getglobal('MLToWinnerNrOfVotes'):SetText('|cffa53737' .. nr .. '/' .. numOfficersInRaid .. ' votes')
    end
end

function MLToWinner_OnClick()
    twdebug(LCVoteFrame.voteTiePlayers)
    if (LCVoteFrame.voteTiePlayers ~= '') then
        local players = string.split(LCVoteFrame.voteTiePlayers, ' ')
        for i, d in next, LCVoteFrame.currentPlayersList do
            for pIndex, tieName in next, players do
                if d['itemIndex'] == LCVoteFrame.CurrentVotedItem and d['name'] == tieName then
                    local roll = math.random(1, 100)
                    for pwIndex, pwPlayer in next, LCVoteFrame.playersWhoWantItems do
                        if (pwPlayer['name'] == tieName and pwPlayer['itemIndex'] == LCVoteFrame.CurrentVotedItem) then
                            -- found the wait=
                            LCVoteFrame.playersWhoWantItems[pwIndex]['roll'] = roll
                            SendAddonMessage("TWLCNF", "playerRoll:" .. pwIndex .. ":" .. roll, "RAID")
                            break
                        end
                    end
                end
            end
        end
        getglobal("MLToWinner"):Disable();
        VoteFrameListScroll_Update()
    else
        -- no vote ties
        awardPlayer(LCVoteFrame.currentItemWinner)
        --awardWithConfirmation(LCVoteFrame.currentItemWinner)
    end
end

function MLTOME()
    awardWithConfirmation(UnitName('player'))
end

function whoNF()
    SendAddonMessage("TWLCNF", "needframe=whoNF=" .. addonVer, "RAID")
end





function Contestant_OnEnter(id)
    local r, g, b, a = getglobal('ContestantFrame' .. id):GetBackdropColor()
    getglobal('ContestantFrame' .. id):SetBackdropColor(r, g, b, 1)
end

function Contestant_OnLeave(id)
    local r, g, b, a = getglobal('ContestantFrame' .. id):GetBackdropColor()
    getglobal('ContestantFrame' .. id):SetBackdropColor(r, g, b, 0.5)
end

function twlc2isCL(name)
    return TWLC_ROSTER[name] ~= nil
end

function twlc2isRL(name)
    for i = 0, GetNumRaidMembers() do
        if (GetRaidRosterInfo(i)) then
            local n, r = GetRaidRosterInfo(i);
            if (n == name and r == 2) then
                return true
            end
        end
    end
    return false
end

function twlc2isAssist(name)
    for i = 0, GetNumRaidMembers() do
        if (GetRaidRosterInfo(i)) then
            local n, r = GetRaidRosterInfo(i);
            if (n == name and r == 1) then
                return true
            end
        end
    end
    return false
end


function twlc2isRLorAssist(name)
    return twlc2isAssist(name) or twlc2isRL(name)
end

function canVote(name) --assist and in CL/LC
    if (not twlc2isRLorAssist(name)) then return false
    end
    if (not twlc2isCL(name)) then return false
    end
    return true
end

function onlineInRaid(name)
    for i = 0, GetNumRaidMembers() do
        if (GetRaidRosterInfo(i)) then
            local n, _, _, _, _, _, z = GetRaidRosterInfo(i);
            if n == name and z ~= 'Offline' then
                return true
            end
        end
    end
    return false
end

function trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function string:split(delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(self, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(self, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(self, delimiter, from)
    end
    table.insert(result, string.sub(self, from))
    return result
end


function pairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n)
    end
    table.sort(a, function(a, b) return a < b
    end)
    local i = 0 -- iterator variable
    local iter = function() -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end

function awardWithConfirmation(playerName)

    local color = classColors[getPlayerClass(playerName)]

    local dialog = StaticPopup_Show("TWLC_CONFIRM_LOOT_DISTRIBUTION",
        LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].link,
        color.c .. playerName .. FONT_COLOR_CODE_CLOSE)
    if (dialog) then
        dialog.data = playerName
    end
end

function awardPlayer(playerName)

    local unitIndex = 0
    --    twdebug(playerName)

    for i = 1, 40 do
        if GetMasterLootCandidate(i) == playerName then
            unitIndex = i
            break
        end
    end

    if (unitIndex == 0) then
        twprint("Something went wrong, winner name is not on loot list.")
    else
        local link = LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].link
        SendAddonMessage("TWLCNF", "youWon=" .. GetMasterLootCandidate(unitIndex) .. "=" .. link .. "=" .. LCVoteFrame.CurrentVotedItem, "RAID")
        --GiveMasterLoot(itemIndex, unitIndex);
        LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].awardedTo = playerName
        LCVoteFrame.updateVotedItemsFrames()
        twdebug('GiveMasterLoot(' .. LCVoteFrame.CurrentVotedItem .. ', ' .. unitIndex .. ');')
    end
end


function twlc_ver(ver)
    return tonumber(string.sub(ver, 1, 1)) * 100 +
            tonumber(string.sub(ver, 3, 3)) * 10 +
            tonumber(string.sub(ver, 5, 5)) * 1
end

StaticPopupDialogs["TWLC_CONFIRM_LOOT_DISTRIBUTION"] = {
    text = "TWLC You wish to assign %s to %s.  Is this correct?",
    button1 = "yes",
    button2 = "no",
    timeout = 0,
    hideOnEscape = 1,
};

StaticPopupDialogs["TWLC_CONFIRM_LOOT_DISTRIBUTION"].OnAccept = function(data)
    twdebug('popul confirm loot data : ' .. data)
    if not LCVoteFrame.CurrentVotedItem then
        twdebug('popul confirm loot LCVoteFrame.CurrentVotedItem : nil ')
    else
        twdebug('popul confirm loot LCVoteFrame.CurrentVotedItem : ' .. LCVoteFrame.CurrentVotedItem)
    end
    --    awardPlayer(data)
    --    twdebug('GiveMasterLoot(' .. LCVoteFrame.CurrentVotedItem .. ', ' .. data .. ');')
end


StaticPopupDialogs["EXAMPLE_HELLOWORLD"] = {
    text = "Do you want to greet the world today?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        GreetTheWorld()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}
