local addonVer = "1.0.2.1" --don't use letters or numbers > 10
local me = UnitName('player')

function twprint(a)
    if a == nil then
        DEFAULT_CHAT_FRAME:AddMessage('|cff69ccf0[TWLC2Error]|cff0070de:' .. time() .. '|cffffffff attempt to print a nil value.')
        return false
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0[TWLC2] |cffffffff" .. a)
end

function twerror(a)
    DEFAULT_CHAT_FRAME:AddMessage('|cff69ccf0[TWLC2Error]|cff0070de:' .. time() .. '|cffffffff[' .. a .. ']')
end

function twdebug(a)
    if not TWLC_DEBUG then return end
    twprint('|cff0070de[DEBUG:' .. time() .. ']|cffffffff[' .. a .. ']')
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
LCVoteFrame.playersPerPage = 10
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

LCVoteFrame.lootHistoryMinRarity = 3
LCVoteFrame.selectedPlayer = {}

LCVoteFrame.lootHistoryFrames = {}
LCVoteFrame.peopleWithAddon = ''

local LCVoteFrameComms = CreateFrame("Frame")
LCVoteFrameComms:RegisterEvent("CHAT_MSG_ADDON")


local LCVoteSyncFrame = CreateFrame("Frame")
LCVoteSyncFrame.NEW_ROSTER = {}

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
        if TWLCCountDownFRAME.currentTime ~= TWLCCountDownFRAME.countDownFrom + plus then
            --tick

            if LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem] then
                if LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].pickedByEveryone then
                    getglobal('LootLCVoteFrameWindowTimeLeftBar'):Hide()
                else
                    getglobal('LootLCVoteFrameWindowTimeLeftBar'):Show()
                end
            end

            local tlx = 15 + ((TWLCCountDownFRAME.countDownFrom - TWLCCountDownFRAME.currentTime + plus) * 500 / TWLCCountDownFRAME.countDownFrom)
            if tlx > 470 then tlx = 470 end
            if tlx <= 250 then tlx = 250 end
            if math.floor(TWLCCountDownFRAME.countDownFrom - TWLCCountDownFRAME.currentTime) > 55 then
                --                getglobal('LootLCVoteFrameWindowTimeLeft'):Hide()
                getglobal('LootLCVoteFrameWindowTimeLeft'):Show()
            end
            if math.floor(TWLCCountDownFRAME.countDownFrom - TWLCCountDownFRAME.currentTime) <= 55 then
                getglobal('LootLCVoteFrameWindowTimeLeft'):Show()
            end
            if math.floor(TWLCCountDownFRAME.countDownFrom - TWLCCountDownFRAME.currentTime) < 1 then
                getglobal('LootLCVoteFrameWindowTimeLeft'):Hide()
            end

            local secondsLeft = math.floor(TWLCCountDownFRAME.countDownFrom - TWLCCountDownFRAME.currentTime) -- .. 's'

            getglobal('LootLCVoteFrameWindowTimeLeft'):SetText(SecondsToClock(secondsLeft))
            --            getglobal('LootLCVoteFrameWindowTimeLeft'):SetPoint("BOTTOMLEFT", tlx, 10)
            getglobal('LootLCVoteFrameWindowTimeLeft'):SetPoint("BOTTOMLEFT", 240, 10)

            getglobal('LootLCVoteFrameWindowTimeLeftBar'):SetWidth((TWLCCountDownFRAME.countDownFrom - TWLCCountDownFRAME.currentTime + plus) * 500 / TWLCCountDownFRAME.countDownFrom)
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

            getglobal('MLToWinner'):Enable()

            VoteCountdown.votingOpen = true

            --desynch case, players have client minimised
            for index, votedItem in next, LCVoteFrame.VotedItemsFrames do
                for i = 1, table.getn(LCVoteFrame.playersWhoWantItems) do
                    if LCVoteFrame.playersWhoWantItems[i]['itemIndex'] == index then
                        if LCVoteFrame.playersWhoWantItems[i]['need'] == 'wait' then
                            changePlayerPickTo(LCVoteFrame.playersWhoWantItems[i]['name'], 'autopass', index)
                            if (LCVoteFrame.pickResponses[index]) then
                                if LCVoteFrame.pickResponses[index] < LCVoteFrame.waitResponses[index] then
                                    LCVoteFrame.pickResponses[index] = LCVoteFrame.pickResponses[index] + 1
                                end
                            end
                        end
                    end
                end
            end


            VoteFrameListScroll_Update()

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
VoteCountdown.votingOpen = true
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
            if (VoteCountdown.countDownFrom - VoteCountdown.currentTime) >= 0 then
                getglobal('LootLCVoteFrameWindowTimeLeft'):Show()
                local secondsLeftToVote = math.floor((VoteCountdown.countDownFrom - VoteCountdown.currentTime)) --.. 's left ! '
                getglobal('LootLCVoteFrameWindowTimeLeft'):SetPoint("BOTTOMLEFT", 202, 10)
                getglobal('LootLCVoteFrameWindowTimeLeft'):SetText('Please VOTE ! ' .. SecondsToClock(secondsLeftToVote))
            end

            for i = 1, LCVoteFrame.playersPerPage, 1 do
                if getglobal('ContestantFrame' .. i .. 'VoteButton'):IsEnabled() == 1 then
                    local w = math.floor(((VoteCountdown.countDownFrom - VoteCountdown.currentTime) / VoteCountdown.countDownFrom) * 1000)
                    w = w / 1000

                    if (w > 0 and w <= 1) then
                        getglobal('LootLCVoteFrameWindowTimeLeftBar'):Show()
                        --                        getglobal('ContestantFrame' .. i .. 'VoteButtonMainBackground'):SetTexture(0.05, 0.56, 0.23, 1)
                        getglobal('LootLCVoteFrameWindowTimeLeftBar'):SetWidth(500 * w)
                        --                        getglobal('ContestantFrame' .. i .. 'VoteButtonTimeLeftBackground'):SetWidth(math.floor(w * 90))
                    else
                        getglobal('LootLCVoteFrameWindowTimeLeftBar'):Hide()
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
                VoteCountdown.votingOpen = false
                for i = 1, LCVoteFrame.playersPerPage, 1 do
                    if getglobal('ContestantFrame' .. i .. 'VoteButton'):IsEnabled() == 1 then
                        getglobal('ContestantFrame' .. i .. 'VoteButton'):Disable()
                        --                        getglobal('ContestantFrame' .. i .. 'VoteButtonTimeLeftBackground'):SetTexture(0.4, 0.4, 0.4, 0)
                        getglobal('ContestantFrame' .. i .. 'VoteButtonMainBackground'):SetTexture(0.4, 0.4, 0.4, .4)
                        --                        getglobal('ContestantFrame' .. i .. 'VoteButtonTimeLeftBackground'):SetWidth(90)
                    end
                end

                getglobal('LootLCVoteFrameWindowTimeLeft'):Show()
                getglobal('LootLCVoteFrameWindowTimeLeft'):SetText('Time\'s up ! Voting closed !')
                getglobal("MLToWinner"):Enable()
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
    if cmd then
        if string.sub(cmd, 1, 3) == 'add' then
            local setEx = string.split(cmd, ' ')
            if setEx[2] then
                addToRoster(setEx[2])
            else
                twprint('Adds LC member')
                twprint('sintax: /twlc add <name>')
            end
        end
        if string.sub(cmd, 1, 3) == 'rem' then
            local setEx = string.split(cmd, ' ')
            if setEx[2] then
                remFromRoster(setEx[2])
            else
                twprint('Removes LC member')
                twprint('sintax: /twlc rem <name>')
            end
        end
        if string.sub(cmd, 1, 3) == 'set' then
            local setEx = string.split(cmd, ' ')
            if (setEx[2] and setEx[3]) then
                if (twlc2isRL(me)) then
                    if (setEx[2] == 'ttn') then
                        TIME_TO_NEED = tonumber(setEx[3])
                        TWLCCountDownFRAME.countDownFrom = TIME_TO_NEED
                        twprint('TIME_TO_NEED - set to ' .. TIME_TO_NEED .. 's')
                        SendAddonMessage("TWLCNF", 'ttn=' .. TIME_TO_NEED, "RAID")
                    end
                    if (setEx[2] == 'ttv') then
                        TIME_TO_VOTE = tonumber(setEx[3])
                        VoteCountdown.countDownFrom = TIME_TO_VOTE
                        twprint('TIME_TO_VOTE - set to ' .. TIME_TO_VOTE .. 's')
                        SendAddonMessage("TWLCNF", 'ttv=' .. TIME_TO_VOTE, "RAID")
                    end
                    if (setEx[2] == 'ttr') then
                        TIME_TO_ROLL = tonumber(setEx[3])
                        twprint('TIME_TO_ROLL - set to ' .. TIME_TO_ROLL .. 's')
                        SendAddonMessage("TWLCNF", 'ttr=' .. TIME_TO_ROLL, "RAID")
                    end
                    --factors
                    if (setEx[2] == 'ttnfactor') then
                        TWLC_TTN_FACTOR = tonumber(setEx[3])
                        getglobal('BroadcastLoot'):SetText('Broadcast Loot (' .. TWLC_TTN_FACTOR .. 's)')
                        twprint('TWLC_TTN_FACTOR - set to ' .. TWLC_TTN_FACTOR .. 's')
                        SendAddonMessage("TWLCNF", 'ttnfactor=' .. TWLC_TTN_FACTOR, "RAID")
                    end
                    if (setEx[2] == 'ttvfactor') then
                        TWLC_TTV_FACTOR = tonumber(setEx[3])
                        twprint('TWLC_TTV_FACTOR - set to ' .. TWLC_TTV_FACTOR .. 's')
                        SendAddonMessage("TWLCNF", 'ttvfactor=' .. TWLC_TTV_FACTOR, "RAID")
                    end
                else
                    twprint('You are not the raid leader.')
                end
            else
                twprint('SET Options')
                twprint('/twlc set ttnfactor <time> - sets TWLC_TTN_FACTOR (current value: numItems * ' .. TWLC_TTN_FACTOR .. 's)')
                twprint('/twlc set ttvfactor <time> - sets TWLC_TTV_FACTOR (current value: numItems * ' .. TWLC_TTV_FACTOR .. 's)')
                twprint('/twlc set ttr <time> - sets TIME_TO_ROLL (current value: ' .. TIME_TO_ROLL .. 's)')
            end
        end
        if cmd == 'list' then
            listRoster()
        end
        if cmd == 'debug' then
            TWLC_DEBUG = not TWLC_DEBUG
            if TWLC_DEBUG then
                twprint('|cff69ccf0[TWLCc] |cffffffffDebug ENABLED')
            else
                twprint('|cff69ccf0[TWLC2c] |cffffffffDebug DISABLED')
            end
        end
        if cmd == 'who' then
            if not UnitInRaid('player') then
                twprint('You are not in a raid.')
                return false
            end
            getglobal('VoteFrameWho'):Show()
            LCVoteFrame.peopleWithAddon = ''
            SendAddonMessage("TWLCNF", "voteframe=whoVF=" .. addonVer, "RAID")
        end
        if cmd == 'synchistory' then
            if not twlc2isRL(me) then return end
            syncLootHistory_OnClick()
        end
        if cmd == 'clearhistory' then
            TWLC_LOOT_HISTORY = {}
            twprint('Loot History cleared.')
        end
        if string.sub(cmd, 1, 6) == 'search' then
            local cmdEx = string.split(cmd, ' ')

            if cmdEx[2] then

                local numItems = 0
                for lootTime, item in pairsByKeysReverse(TWLC_LOOT_HISTORY) do
                    if string.lower(cmdEx[2]) == string.lower(item['player']) then
                        numItems = numItems + 1
                    end
                end

                twprint('Listing ' .. cmdEx[2] .. '\'s loot history:')
                if numItems > 0 then
                    for lootTime, item in pairsByKeysReverse(TWLC_LOOT_HISTORY) do
                        if string.lower(cmdEx[2]) == string.lower(item['player']) then
                            twprint(item['item'] .. ' - ' .. date("%d/%m", lootTime))
                        end
                    end
                else
                    twprint('- no recorded items -')
                end

            else
                twprint('Search syntax: /twlc search [Playername]')
            end
        end
    end
end

local minibtn = getglobal('TWLC2_Minimap')

function syncLootHistory_OnClick()
    local totalItems = 0

    getglobal('RLWindowFrameSyncLootHistory'):Disable()

    for lootTime, item in next, TWLC_LOOT_HISTORY do
        totalItems = totalItems + 1
    end

    twprint('Starting History Sync, ' .. totalItems .. ' entries...')
    ChatThrottleLib:SendAddonMessage("BULK", "TWLCNF", "loot_history_sync;start", "RAID")
    for lootTime, item in next, TWLC_LOOT_HISTORY do
        ChatThrottleLib:SendAddonMessage("BULK", "TWLCNF", "loot_history_sync;" .. lootTime .. ";" .. item['player'] .. ";" .. item['item'], "RAID")
    end
    ChatThrottleLib:SendAddonMessage("BULK", "TWLCNF", "loot_history_sync;end", "RAID")
end

function toggleMainWindow()
    if not canVote(me) and not twlc2isRL(me) then return false end
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
    for i = 1, table.getn(RLWindowFrame.assistFrames) do
        getglobal('AssistFrame' .. i .. 'AssistCheck'):Disable()
        getglobal('AssistFrame' .. i .. 'CLCheck'):Disable()
    end
    ChatThrottleLib:SendAddonMessage("BULK", "TWLCNF", "syncRoster=start", "RAID")
    for name, v in next, TWLC_ROSTER do
        index = index + 1
        ChatThrottleLib:SendAddonMessage("BULK", "TWLCNF", "syncRoster=" .. name, "RAID")
    end
    ChatThrottleLib:SendAddonMessage("BULK", "TWLCNF", "syncRoster=end", "RAID")
    if (twlc2isRL(me)) then checkAssists() end
end

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
        if (event == "RAID_ROSTER_UPDATE") then
            if (twlc2isRL(me)) then
                twdebug('RAID_ROSTER_UPDATE');
                for i = 0, GetNumRaidMembers() do
                    if (GetRaidRosterInfo(i)) then
                        local n, r = GetRaidRosterInfo(i);
                        if twlc2isCL(n) and r ~= 1 and n ~= me then
                            twdebug('PROMOTE TRIGGER');
                            PromoteToAssistant(n)
                            return false
                        end
                    end
                end
                twdebug('RAID_ROSTER_UPDATE CONTINUE');
                getglobal('RLOptionsButton'):Show()
                getglobal('RLExtraFrame'):Show()
                getglobal('MLToWinner'):Show()
                getglobal('MLToWinner'):Disable()
                getglobal('ResetClose'):Show()
                checkAssists()
            else
                getglobal('MLToWinner'):Hide()
                getglobal('RLExtraFrame'):Hide()
                getglobal('RLOptionsButton'):Hide()
                getglobal('RLWindowFrame'):Hide()
                getglobal('ResetClose'):Hide()
            end
            if not canVote(me) then
                getglobal('LootLCVoteFrameWindow'):Hide()
            end
        end
        if (event == "CHAT_MSG_SYSTEM") then
            if ((string.find(arg1, "rolls", 1, true) or string.find(arg1, "würfelt. Ergebnis", 1, true)) and string.find(arg1, "(1-100)", 1, true)) then --vote tie rolls
                --en--Er rolls 47 (1-100)
                --de--Er würfelt. Ergebnis: 47 (1-100)
                local r = string.split(arg1, " ")

                if not r[2] or not r[3] then
                    twerror('bad roll syntax')
                    twerror(arg1)
                    return false
                end

                local name = r[1]
                local roll = tonumber(r[3])

                if string.find(arg1, "würfelt. Ergebnis", 1, true) then
                    if not r[4] then
                        twerror('bad german roll syntax')
                        twerror(arg1)
                        return false
                    end
                    roll = tonumber(r[4])
                end

                --check if name is in playersWhoWantItems with vote == -2
                for pwIndex, pwPlayer in next, LCVoteFrame.playersWhoWantItems do
                    if (pwPlayer['name'] == name and pwPlayer['roll'] == -2) then
                        LCVoteFrame.playersWhoWantItems[pwIndex]['roll'] = roll
                        SendAddonMessage("TWLCNF", "playerRoll:" .. pwIndex .. ":" .. roll .. ":" .. LCVoteFrame.CurrentVotedItem, "RAID")
                        VoteFrameListScroll_Update()
                        break
                    end
                end
            end
        end
        if (event == "ADDON_LOADED" and arg1 == 'TWLC2') then

            if not TIME_TO_NEED then TIME_TO_NEED = 30 end
            if not TIME_TO_VOTE then TIME_TO_VOTE = 30 end
            if not TIME_TO_ROLL then TIME_TO_ROLL = 30 end
            if not TWLC_ROSTER then TWLC_ROSTER = {} end
            if not TWLC_LOOT_HISTORY then TWLC_LOOT_HISTORY = {} end
            if not TWLC_ENABLED then TWLC_ENABLED = false end
            if not TWLC_LOOT_HISTORY then TWLC_LOOT_HISTORY = {} end
            if not TWLC_DEBUG then TWLC_DEBUG = false end
            if not TWLC_TTN_FACTOR then TWLC_TTN_FACTOR = 15 end
            if not TWLC_TTV_FACTOR then TWLC_TTV_FACTOR = 15 end

            TWLCCountDownFRAME.countDownFrom = TIME_TO_NEED
            VoteCountdown.countDownFrom = TIME_TO_VOTE

            getglobal('LootLCVoteFrameWindowTitle'):SetText('Turtle WoW Loot Council2 v' .. addonVer)
            getglobal('LootLCVoteFrameWindowNewTitleFrameTitle'):SetText('Turtle WoW Loot Council2 v' .. addonVer)

            getglobal('BroadcastLoot'):Disable()

            if (twlc2isRL(me)) then
                getglobal('RLOptionsButton'):Show()
                getglobal('ResetClose'):Show()
                getglobal('RLExtraFrame'):Show()
            else
                getglobal('RLOptionsButton'):Hide()
                getglobal('ResetClose'):Hide()
                getglobal('RLExtraFrame'):Hide()
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
            if not TWLC_ENABLED then return end
            if (twlc2isRL(me)) then

                --                if not UnitInRaid('player') then
                --                    twprint('You are not in a raid.')
                --                    return false
                --                end

                local lootmethod = GetLootMethod()
                if (lootmethod == 'master') then
                    getglobal('BroadcastLoot'):Show()
                    getglobal('BroadcastLoot'):Enable()
                    getglobal('BroadcastLoot'):SetText('Broadcast Loot (' .. TWLC_TTN_FACTOR .. 's)')
                    getglobal('LootLCVoteFrameWindow'):Show()
                else
                    twprint('Looting method is not master looter. (' .. lootmethod .. ')')
                    getglobal('BroadcastLoot'):Hide()
                end
            end
        end
        if (event == "LOOT_SLOT_CLEARED") then
        end
        if (event == "LOOT_CLOSED") then
            --            getglobal('BroadcastLoot'):Hide()
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
        if getglobal('TWLCLootHistoryFrame'):IsVisible() then
            LootHistoryClose()
        end

        local totalItems = 0

        for lootTime, item in next, TWLC_LOOT_HISTORY do
            totalItems = totalItems + 1
        end

        getglobal('RLWindowFrameSyncLootHistory'):SetText('Sync Loot History (' .. totalItems .. ' entries)')


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

    getglobal('RLWindowFrame'):SetHeight(100 + table.getn(people) * 25)

    for i, d in next, people do
        if (not RLWindowFrame.assistFrames[i]) then
            RLWindowFrame.assistFrames[i] = CreateFrame('Frame', 'AssistFrame' .. i, getglobal("RLWindowFrame"), 'CLListFrameTemplate')
        end

        RLWindowFrame.assistFrames[i]:SetPoint("TOPLEFT", getglobal("RLWindowFrame"), "TOPLEFT", 4, d.y)
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

        if (d.name == me) then
            if getglobal('AssistFrame' .. i .. 'CLCheck'):GetChecked() then
                getglobal('AssistFrame' .. i .. 'CLCheck'):Disable()
            end
            getglobal('AssistFrame' .. i .. 'AssistCheck'):Disable()
        end
    end
end

function sendReset()
    SendAddonMessage("TWLCNF", "needframe=reset", "RAID")
    SendAddonMessage("TWLCNF", "voteframe=reset", "RAID")
    SendAddonMessage("TWLCNF", "rollframe=reset", "RAID")
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

function ResetClose_OnClick()
    sendReset()
    sendCloseWindow()
end

function BroadcastLoot_OnClick()

    if (GetNumLootItems() == 0) then
        twprint('There are no items in the loot frame.')
        return
    end

    getglobal('BroadcastLoot'):Disable()

    SendAddonMessage("TWLCNF", 'ttnfactor=' .. TWLC_TTN_FACTOR, "RAID")
    SendAddonMessage("TWLCNF", 'ttvfactor=' .. TWLC_TTV_FACTOR, "RAID")

    TIME_TO_NEED = GetNumLootItems() * TWLC_TTN_FACTOR
    TWLCCountDownFRAME.countDownFrom = TIME_TO_NEED
    SendAddonMessage("TWLCNF", 'ttn=' .. TIME_TO_NEED, "RAID")
    TIME_TO_VOTE = GetNumLootItems() * TWLC_TTV_FACTOR
    SendAddonMessage("TWLCNF", 'ttv=' .. TIME_TO_VOTE, "RAID")
    SendAddonMessage("TWLCNF", 'ttr=' .. TIME_TO_ROLL, "RAID")

    sendReset()

    SendAddonMessage("TWLCNF", "voteframe=show", "RAID")

    TWLCCountDownFRAME:Show()
    SendAddonMessage("TWLCNF", 'countdownframe=show', "RAID")


    for id = 0, GetNumLootItems() do
        if GetLootSlotInfo(id) and GetLootSlotLink(id) then
            local lootIcon, lootName, _, _, q = GetLootSlotInfo(id)

            local _, _, itemLink = string.find(GetLootSlotLink(id), "(item:%d+:%d+:%d+:%d+)");
            local _, _, quality = GetItemInfo(itemLink)
            if (quality >= 0) then
                ChatThrottleLib:SendAddonMessage("ALERT", "TWLCNF", "loot=" .. id .. "=" .. lootIcon .. "=" .. lootName .. "=" .. GetLootSlotLink(id) .. "=" .. TWLCCountDownFRAME.countDownFrom, "RAID")
                --                SendAddonMessage("TWLCNF", "loot=" .. id .. "=" .. lootIcon .. "=" .. lootName .. "=" .. GetLootSlotLink(id) .. "=" .. TWLCCountDownFRAME.countDownFrom, "RAID")
            end
        end
    end
    getglobal("MLToWinner"):Disable();
end

function addVotedItem(index, texture, name, link)

    LCVoteFrame.itemVotes[index] = {}

    LCVoteFrame.selectedPlayer[index] = ''

    if (not LCVoteFrame.VotedItemsFrames[index]) then
        LCVoteFrame.VotedItemsFrames[index] = CreateFrame("Frame", "VotedItem" .. index,
            getglobal("VotedItemsFrame"), "VotedItemsFrameTemplate")
    end

    getglobal("VotedItemsFrame"):SetHeight(40 * index + 35)

    LCVoteFrame.VotedItemsFrames[index]:SetPoint("TOPLEFT", getglobal("VotedItemsFrame"), "TOPLEFT", 8, 30 - (40 * index))

    LCVoteFrame.VotedItemsFrames[index]:Show()
    LCVoteFrame.VotedItemsFrames[index].link = link
    LCVoteFrame.VotedItemsFrames[index].texture = texture
    LCVoteFrame.VotedItemsFrames[index].awardedTo = ''
    LCVoteFrame.VotedItemsFrames[index].rolled = false
    LCVoteFrame.VotedItemsFrames[index].pickedByEveryone = false

    addButtonOnEnterTooltip(getglobal('VotedItem' .. index .. 'VotedItemButton'), link)

    --    getglobal('VotedItem' .. index .. 'VotedItemButton'):Show()
    getglobal('VotedItem' .. index .. 'VotedItemButton'):SetID(index)
    getglobal('VotedItem' .. index .. 'VotedItemButton'):SetNormalTexture(texture)
    getglobal('VotedItem' .. index .. 'VotedItemButton'):SetPushedTexture(texture)
    getglobal('VotedItem' .. index .. 'VotedItemButton'):SetHighlightTexture(texture)

    getglobal('VotedItem' .. index .. 'VotedItemButtonCheck'):Hide()
    getglobal('VotedItem' .. index .. 'VotedItemButton'):SetHighlightTexture(texture)

    if (index ~= 1) then
        SetDesaturation(getglobal('VotedItem' .. index .. 'VotedItemButton'):GetNormalTexture(), 1)
    end

    if (not LCVoteFrame.CurrentVotedItem) then
        VotedItemButton_OnClick(index)
    end
end

function VotedItemButton_OnClick(id)

    getglobal('MLToWinner'):Hide()
    if (twlc2isRL(me)) then
        getglobal('MLToWinner'):Show()
    end
    if (canVote(me) and not twlc2isRL(me)) then
        getglobal('WinnerStatus'):Show()
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
    if (t2) then
        if not string.find(string.lower(t2), 'misc', 1, true)
                and not string.find(string.lower(t2), 'shields', 1, true) then
            votedItemType = votedItemType .. t2 .. ' '
        end
    end
    if (equip_slot) then votedItemType = votedItemType .. getEquipSlot(equip_slot) end

    if votedItemType == 'Cloth Cloak' then votedItemType = 'Cloak' end

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
            if (name == n) then
                local _, unitClass = UnitClass('raid' .. i) --standard
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
    title.text = getglobal("ContestantFrame" .. id .. "Name"):GetText() .. ' ' ..
            getglobal("ContestantFrame" .. id .. "Need"):GetText()
    title.disabled = false
    title.isTitle = true
    title.func = function()
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
        --        awardWithConfirmation(getglobal("ContestantFrame" .. id).name)
        awardPlayer(getglobal("ContestantFrame" .. id).name)
    end
    UIDropDownMenu_AddButton(award);
    UIDropDownMenu_AddButton(separator);

    local changeToBIS = {}
    changeToBIS.text = "Change to " .. needs['bis'].c .. needs['bis'].text
    changeToBIS.disabled = getglobal("ContestantFrame" .. id).need == 'bis'
    changeToBIS.isTitle = false
    changeToBIS.tooltipTitle = 'Change choice'
    changeToBIS.tooltipText = 'Change contestant\'s choice to ' .. needs['bis'].c .. needs['bis'].text
    changeToBIS.justifyH = 'LEFT'
    changeToBIS.func = function()
        changePlayerPickTo(getglobal("ContestantFrame" .. id).name, 'bis', LCVoteFrame.CurrentVotedItem)
    end
    UIDropDownMenu_AddButton(changeToBIS);

    local changeToMS = {}
    changeToMS.text = "Change to " .. needs['ms'].c .. needs['ms'].text
    changeToMS.disabled = getglobal("ContestantFrame" .. id).need == 'ms'
    changeToMS.isTitle = false
    changeToMS.tooltipTitle = 'Change choice'
    changeToMS.tooltipText = 'Change contestant\'s choice to ' .. needs['ms'].c .. needs['ms'].text
    changeToMS.justifyH = 'LEFT'
    changeToMS.func = function()
        changePlayerPickTo(getglobal("ContestantFrame" .. id).name, 'ms', LCVoteFrame.CurrentVotedItem)
    end
    UIDropDownMenu_AddButton(changeToMS);

    local changeToOS = {}
    changeToOS.text = "Change to " .. needs['os'].c .. needs['os'].text
    changeToOS.disabled = getglobal("ContestantFrame" .. id).need == 'os'
    changeToOS.isTitle = false
    changeToOS.tooltipTitle = 'Change choice'
    changeToOS.tooltipText = 'Change contestant\'s choice to ' .. needs['os'].c .. needs['os'].text
    changeToOS.justifyH = 'LEFT'
    changeToOS.func = function()
        changePlayerPickTo(getglobal("ContestantFrame" .. id).name, 'os', LCVoteFrame.CurrentVotedItem)
    end
    UIDropDownMenu_AddButton(changeToOS);

    UIDropDownMenu_AddButton(separator);

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

function changePlayerPickTo(playerName, newPick, itemIndex)
    for pIndex, data in next, LCVoteFrame.playersWhoWantItems do
        if data['itemIndex'] == itemIndex and data['name'] == playerName then
            LCVoteFrame.playersWhoWantItems[pIndex]['need'] = newPick
            break
        end
    end
    if twlc2isRL(me) then
        SendAddonMessage("TWLCNF", "changePickTo@" .. playerName .. "@" .. newPick .. "@" .. itemIndex, "RAID")
    end

    VoteFrameListScroll_Update()
end

LCVoteFrame.HistoryId = 0
function ContestantClick(id)

    local playerOffset = FauxScrollFrame_GetOffset(getglobal("ContestantScrollListFrame"));
    id = id - playerOffset

    if (arg1 == 'RightButton') then
        ShowContenstantDropdownMenu(id)
        return true
    end

    if (getglobal('TWLCLootHistoryFrame'):IsVisible() and LCVoteFrame.selectedPlayer[LCVoteFrame.CurrentVotedItem] == getglobal("ContestantFrame" .. id).name) then
        LootHistoryClose()
    else

        LCVoteFrame.HistoryId = id

        if getglobal('RLWindowFrame'):IsVisible() then
            getglobal('RLWindowFrame'):Hide()
        end

        --hide prevs
        for index in next, LCVoteFrame.lootHistoryFrames do
            LCVoteFrame.lootHistoryFrames[index]:Hide()
        end

        LootHistory_Update()
    end
end

function LootHistory_Update()
    local itemOffset = FauxScrollFrame_GetOffset(getglobal("TWLCLootHistoryFrameScrollFrame"));

    local id = LCVoteFrame.HistoryId

    LCVoteFrame.selectedPlayer[LCVoteFrame.CurrentVotedItem] = getglobal("ContestantFrame" .. id).name

    local totalItems = 0

    local historyPlayerName = getglobal("ContestantFrame" .. id).name
    for lootTime, item in next, TWLC_LOOT_HISTORY do
        if (historyPlayerName == item['player']) then
            totalItems = totalItems + 1
        end
    end

    for index in next, LCVoteFrame.lootHistoryFrames do
        LCVoteFrame.lootHistoryFrames[index]:Hide()
    end

    if totalItems > 0 then

        local index = 0
        for lootTime, item in pairsByKeysReverse(TWLC_LOOT_HISTORY) do
            if (historyPlayerName == item['player']) then

                index = index + 1

                if index > itemOffset and index <= itemOffset + 14 then

                    if not LCVoteFrame.lootHistoryFrames[index] then
                        LCVoteFrame.lootHistoryFrames[index] = CreateFrame('Frame', 'HistoryItem' .. index, getglobal("TWLCLootHistoryFrame"), 'HistoryItemTemplate')
                    end

                    LCVoteFrame.lootHistoryFrames[index]:SetPoint("TOPLEFT", getglobal("TWLCLootHistoryFrame"), "TOPLEFT", 10, -8 - 22 * (index - itemOffset))
                    LCVoteFrame.lootHistoryFrames[index]:Show()

                    local today = ''
                    if date("%d/%m") == date("%d/%m", lootTime) then
                        today = classColors['mage'].c
                    end

                    local _, _, itemLink = string.find(item['item'], "(item:%d+:%d+:%d+:%d+)");
                    local name, il, quality, _, _, _, _, _, tex = GetItemInfo(itemLink)

                    getglobal("HistoryItem" .. index .. 'Date'):SetText(classColors['rogue'].c .. today .. date("%d/%m", lootTime))
                    getglobal("HistoryItem" .. index .. 'Item'):SetNormalTexture(tex)
                    getglobal("HistoryItem" .. index .. 'Item'):SetPushedTexture(tex)
                    addButtonOnEnterTooltip(getglobal("HistoryItem" .. index .. "Item"), item['item'])
                    getglobal("HistoryItem" .. index .. 'ItemName'):SetText(item['item'])
                end
            end
        end
    end

    getglobal('TWLCLootHistoryFrameTitle'):SetText(classColors[getPlayerClass(historyPlayerName)].c .. historyPlayerName .. classColors['priest'].c .. " Loot History (" .. totalItems .. ")")
    getglobal('TWLCLootHistoryFrame'):Show()

    -- ScrollFrame update
    FauxScrollFrame_Update(getglobal("TWLCLootHistoryFrameScrollFrame"), totalItems, 14, 22);
end

function LootHistoryClose()
    if LCVoteFrame.selectedPlayer[LCVoteFrame.CurrentVotedItem] then
        LCVoteFrame.selectedPlayer[LCVoteFrame.CurrentVotedItem] = ''
    end
    getglobal('TWLCLootHistoryFrame'):Hide()
    VoteFrameListScroll_Update()
end

function ShowContenstantDropdownMenu(id)

    if not twlc2isRL(me) then return end

    local playerOffset = FauxScrollFrame_GetOffset(getglobal("ContestantScrollListFrame"));
    id = id - playerOffset
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

    --    local menu1 = {};
    --    menu1.text = "Show/Hide Frame"
    --    menu1.disabled = false
    --    menu1.isTitle = false
    --    menu1.tooltipTitle = 'Show/Hide Frame'
    --    menu1.tooltipText = 'Shows/Hides Frame'
    --    menu1.justifyH = 'LEFT'
    --    menu1.func = function()
    --        toggleMainWindow()
    --    end
    --    UIDropDownMenu_AddButton(menu1);

    --    UIDropDownMenu_AddButton(separator);

    local menu_enabled = {};
    menu_enabled.text = "Enabled"
    menu_enabled.disabled = false
    menu_enabled.isTitle = false
    menu_enabled.tooltipTitle = 'Enabled'
    menu_enabled.tooltipText = 'Use TWLC2 when you are the raid leader.'
    menu_enabled.checked = TWLC_ENABLED
    menu_enabled.justifyH = 'LEFT'
    menu_enabled.func = function()
        TWLC_ENABLED = not TWLC_ENABLED
        if (TWLC_ENABLED) then
            twprint('Addon enabled.')
        else
            twprint('Addon disabled.')
        end
    end
    UIDropDownMenu_AddButton(menu_enabled);
    UIDropDownMenu_AddButton(separator);

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

    if not LCVoteFrame.CurrentVotedItem then return false end

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
        LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].pickedByEveryone = true
        getglobal('LootLCVoteFrameWindowTimeLeftBar'):Hide()
    else
        getglobal('LootLCVoteFrameWindowContestantCount'):SetText('Waiting picks ' ..
                LCVoteFrame.pickResponses[LCVoteFrame.CurrentVotedItem] .. '/' .. LCVoteFrame.waitResponses[LCVoteFrame.CurrentVotedItem])
        LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].pickedByEveryone = false
        getglobal('LootLCVoteFrameWindowTimeLeftBar'):Show()
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
            getglobal("ContestantFrame" .. i).need = need;

            local class = getPlayerClass(name)
            local color = classColors[class]

            getglobal("ContestantFrame" .. i .. "Name"):SetText(color.c .. name);
            getglobal("ContestantFrame" .. i .. "Need"):SetText(needs[need].c .. needs[need].text);
            if (roll > 0) then
                getglobal("ContestantFrame" .. i .. "Roll"):SetText(roll);
            else
                getglobal("ContestantFrame" .. i .. "Roll"):SetText();
            end
            getglobal("ContestantFrame" .. i .. "RollPass"):Hide();
            if (roll == -1) then
                getglobal("ContestantFrame" .. i .. "RollPass"):Show();
                getglobal("ContestantFrame" .. i .. "Roll"):SetText(' -');
            end
            if (roll == -2) then
                getglobal("ContestantFrame" .. i .. "Roll"):SetText('...');
            end

            getglobal("ContestantFrame" .. i .. "RightClickMenuButton1"):SetID(playerIndex);
            getglobal("ContestantFrame" .. i .. "RightClickMenuButton2"):SetID(playerIndex);
            getglobal("ContestantFrame" .. i .. "RightClickMenuButton3"):SetID(playerIndex);

            getglobal("ContestantFrame" .. i .. "Votes"):SetText(votes);
            if (votes == LCVoteFrame.currentItemMaxVotes and LCVoteFrame.currentItemMaxVotes > 0) then
                getglobal("ContestantFrame" .. i .. "Votes"):SetText('|cff1fba1f' .. votes);
            end

            getglobal("ContestantFrame" .. i .. "VoteButton"):Enable();

            getglobal("ContestantFrame" .. i .. "VoteButton"):SetText('VOTE')


            --            getglobal('ContestantFrame' .. i .. 'VoteButtonTimeLeftBackground'):SetTexture(0.05, 0.56, 0.23, 1)
            --            getglobal('ContestantFrame' .. i .. 'VoteButtonMainBackground'):SetTexture(0.05, 0.56, 0.23, 1)
            if LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].awardedTo ~= '' or
                    LCVoteFrame.numPlayersThatWant == 1 or
                    LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].rolled or
                    not LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].pickedByEveryone or
                    not VoteCountdown.votingOpen then
                getglobal("ContestantFrame" .. i .. "VoteButton"):Disable();
                --                getglobal('ContestantFrame' .. i .. 'VoteButtonTimeLeftBackground'):SetTexture(0.4, 0.4, 0.4, .4)
                getglobal('ContestantFrame' .. i .. 'VoteButtonMainBackground'):SetTexture(0.4, 0.4, 0.4, .4)
                getglobal('ContestantFrame' .. i .. 'VoteButtonMainBackground'):SetWidth(90)
            end
            if LCVoteFrame.pickResponses[LCVoteFrame.CurrentVotedItem] == LCVoteFrame.waitResponses[LCVoteFrame.CurrentVotedItem]
                    and LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].awardedTo == '' then
                getglobal("ContestantFrame" .. i .. "VoteButton"):Enable();
                getglobal('ContestantFrame' .. i .. 'VoteButtonMainBackground'):SetTexture(0.05, 0.56, 0.23, 1)
            end

            if LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][name] then
                if LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][name][me] then
                    if LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][name][me] == '+' then
                        getglobal("ContestantFrame" .. i .. "VoteButton"):SetText('unvote')
                        getglobal('ContestantFrame' .. i .. 'VoteButtonMainBackground'):SetTexture(0.05, 0.56, 0.23, .5)
                    end
                end
            end

            getglobal("ContestantFrame" .. i .. "RollWinner"):Hide();
            if (LCVoteFrame.currentMaxRoll[LCVoteFrame.CurrentVotedItem] == roll and roll > 0) then
                getglobal("ContestantFrame" .. i .. "RollWinner"):Show();
            end
            getglobal("ContestantFrame" .. i .. "WinnerIcon"):Hide();
            if (LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].awardedTo == name) then
                getglobal("ContestantFrame" .. i .. "WinnerIcon"):Show();
            end

            getglobal("ContestantFrame" .. i .. "CLVote"):Hide();
            if LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][name] then
                for voter, vote in next, LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][name] do
                    if vote == '+' and class == getPlayerClass(voter) then
                        getglobal("ContestantFrame" .. i .. "CLVote"):Show();
                    end
                end
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

                if not tex then tex = 'Interface\\Icons\\inv_misc_questionmark' end

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

                if not tex then tex = 'Interface\\Icons\\inv_misc_questionmark' end

                getglobal("ContestantFrame" .. i .. "ReplacesItem2"):SetNormalTexture(tex)
                getglobal("ContestantFrame" .. i .. "ReplacesItem2"):SetPushedTexture(tex)
                addButtonOnEnterTooltip(getglobal("ContestantFrame" .. i .. "ReplacesItem2"), itemLink)
                getglobal("ContestantFrame" .. i .. "ReplacesItem2"):Show()
            else
                getglobal("ContestantFrame" .. i .. "ReplacesItem2"):Hide()
            end

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

        if not ex[2] or not ex[3] then
            twerror('bad addButtonOnEnterTooltip itemLink syntadx')
            twerror(itemLink)
            return false
        end

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

    TWLCCountDownFRAME:Hide()
    VoteCountdown:Hide()

    LCVoteFrame.CurrentVotedItem = nil
    LCVoteFrame.currentPlayersList = {}
    LCVoteFrame.playersWhoWantItems = {}

    LCVoteFrame.waitResponses = {}
    LCVoteFrame.pickResponses = {}

    LCVoteFrame.itemVotes = {}

    LCVoteFrame.myVotes = {}
    LCVoteFrame.LCVoters = 0

    LCVoteFrame.selectedPlayer = {}

    getglobal('LootLCVoteFrameWindowContestantCount'):SetText()

    getglobal('BroadcastLoot'):Disable()
    getglobal("WinnerStatus"):Hide()
    getglobal("MLToWinner"):Hide()
    getglobal("MLToWinner"):Disable()
    getglobal("MLToWinnerNrOfVotes"):SetText()
    getglobal("WinnerStatusNrOfVotes"):SetText()

    for index, frame in next, LCVoteFrame.VotedItemsFrames do
        getglobal('VotedItem' .. index):Hide()
    end

    for i = 1, LCVoteFrame.playersPerPage, 1 do
        getglobal("ContestantFrame" .. i):Hide()
    end

    TWLCCountDownFRAME.currentTime = 1
    VoteCountdown.currentTime = 1
    VoteCountdown.votingOpen = false

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
    if string.find(t, 'playerRoll:', 1, true) then

        if not twlc2isRL(sender) or sender == me then return end
        if not canVote(me) then return end

        local indexEx = string.split(t, ':')

        if not indexEx[2] or not indexEx[3] then
            twerror('bad playerRoll syntax')
            twerror(t)
            return false
        end
        if not tonumber(indexEx[3]) then return false end

        LCVoteFrame.playersWhoWantItems[tonumber(indexEx[2])]['roll'] = tonumber(indexEx[3])
        LCVoteFrame.VotedItemsFrames[tonumber(indexEx[4])].rolled = true
        VoteFrameListScroll_Update()
    end
    if string.find(t, 'changePickTo@', 1, true) then

        if not twlc2isRL(sender) or sender == me then return end
        if not canVote(me) then return end

        local pickEx = string.split(t, '@')
        if not pickEx[2] or not pickEx[3] or not pickEx[4] then
            twerror('bad changePick syntax')
            twerror(t)
            return false
        end

        if not tonumber(pickEx[4]) then
            twerror('bad changePick itemIndex')
            twerror(t)
            return false
        end

        changePlayerPickTo(pickEx[2], pickEx[3], tonumber(pickEx[4]))
    end

    if string.find(t, 'rollChoice=', 1, true) then

        if not canVote(me) then return end

        local r = string.split(t, '=')
        --r[2] = voteditem id
        --r[3] = roll
        if not r[2] or not r[3] then
            twdebug('bad rollChoice syntax')
            twdebug(t)
            return false
        end

        if (tonumber(r[3]) == -1) then

            local name = sender
            local roll = tonumber(r[3]) -- -1

            --check if name is in playersWhoWantItems with vote == -2
            for pwIndex, pwPlayer in next, LCVoteFrame.playersWhoWantItems do
                if (pwPlayer['name'] == name and pwPlayer['roll'] == -2) then
                    LCVoteFrame.playersWhoWantItems[pwIndex]['roll'] = roll
                    VoteFrameListScroll_Update()
                    break
                end
            end
        else
            twdebug('ROLLCATCHER ' .. sender .. ' rolled for ' .. r[2])
        end
    end
    if string.find(t, 'itemVote:', 1, true) then

        if not canVote(sender) or sender == me then return end
        if not canVote(me) then return end

        local itemVoteEx = string.split(t, ':')

        if not itemVoteEx[2] or not itemVoteEx[3] or not itemVoteEx[4] then
            twerror('bad itemVote syntax')
            twerror(t)
            return false
        end

        local votedItem = tonumber(itemVoteEx[2])
        local votedPlayer = itemVoteEx[3]
        local vote = itemVoteEx[4]
        if (not LCVoteFrame.itemVotes[votedItem][votedPlayer]) then
            LCVoteFrame.itemVotes[votedItem][votedPlayer] = {}
        end
        LCVoteFrame.itemVotes[votedItem][votedPlayer][sender] = vote
        VoteFrameListScroll_Update()
    end
    if string.find(t, 'voteframe=', 1, true) then
        local command = string.split(t, '=')

        if not command[2] then
            twerror('bad voteframe syntax')
            twerror(t)
            return false
        end

        if (command[2] == "whoVF") then
            ChatThrottleLib:SendAddonMessage("NORMAL", "TWLCNF", "withAddonVF=" .. sender .. "=" .. me .. "=" .. addonVer, "RAID")
            return
        end

        if not twlc2isRL(sender) then return end
        if not canVote(me) then return end

        if (command[2] == "reset") then
            LCVoteFrame.ResetVars()
        end
        if (command[2] == "close") then
            LCVoteFrame.closeWindow()
        end
        if (command[2] == "show") then
            LCVoteFrame.showWindow()
        end
    end
    if string.find(t, 'loot=', 1, true) then

        if not twlc2isRL(sender) then return end

        local item = string.split(t, "=")

        if not item[2] or not item[3] or not item[4] or not item[5] then
            twerror('bad loot syntax')
            twerror(t)
            return false
        end

        if not tonumber(item[2]) then
            twerror('bad loot index')
            twerror(t)
            return false
        end

        local index = tonumber(item[2])
        local texture = item[3]
        local name = item[4]
        local link = item[5]
        addVotedItem(index, texture, name, link)
    end
    if string.find(t, 'countdownframe=', 1, true) then

        if not twlc2isRL(sender) then return end
        if not canVote(me) then return end

        local action = string.split(t, "=")

        if not action[2] then
            twerror('bad countdownframe syntax')
            twerror(t)
            return false
        end

        if (action[2] == 'show') then TWLCCountDownFRAME:Show() end
    end
    if string.find(t, 'wait=', 1, true) then

        if not canVote(me) then return end

        local startWork = GetTime()
        local needEx = string.split(t, '=')

        if not needEx[2] or not needEx[3] or not needEx[4] then
            twerror('bad wait syntax')
            twerror(t)
            return false
        end

        if not tonumber(needEx[2]) then
            twerror('bad wait itemIndex')
            twerror(t)
            return false
        end

        if (table.getn(LCVoteFrame.playersWhoWantItems) ~= 0) then
            for i = 1, table.getn(LCVoteFrame.playersWhoWantItems) do
                if LCVoteFrame.playersWhoWantItems[i]['itemIndex'] == tonumber(needEx[2]) and
                        LCVoteFrame.playersWhoWantItems[i]['name'] == sender then
                    return false --exists already
                end
            end
        end

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
    end
    --ms=1=item:123=item:323
    if string.sub(t, 1, 4) == 'bis='
            or string.sub(t, 1, 3) == 'ms='
            or string.sub(t, 1, 3) == 'os='
            or string.sub(t, 1, 5) == 'pass='
            or string.sub(t, 1, 9) == 'autopass=' then

        if (canVote(me)) then

            local needEx = string.split(t, '=')

            if not needEx[2] or not needEx[3] or not needEx[4] then
                twerror('bad need syntax')
                twerror(t)
                return false
            end

            if (LCVoteFrame.pickResponses[tonumber(needEx[2])]) then
                if LCVoteFrame.pickResponses[tonumber(needEx[2])] < LCVoteFrame.waitResponses[tonumber(needEx[2])] then
                    LCVoteFrame.pickResponses[tonumber(needEx[2])] = LCVoteFrame.pickResponses[tonumber(needEx[2])] + 1
                end
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

            getglobal('LootLCVoteFrameWindow'):Show()
            VoteFrameListScroll_Update()
        else
            getglobal('LootLCVoteFrameWindow'):Hide()
        end
    end
    -- roster sync
    if (string.find(t, 'syncRoster=', 1, true)) then
        if not twlc2isRL(sender) then return end
        if sender == me then return end

        local command = string.split(t, '=')

        if not command[2] then
            twerror('bad syncRoster syntax')
            twerror(t)
            return false
        end

        if (command[2] == "start") then
            LCVoteSyncFrame.NEW_ROSTER = {}
        elseif (command[2] == "end") then
            TWLC_ROSTER = LCVoteSyncFrame.NEW_ROSTER
            twdebug('Roster updated.')
        else
            LCVoteSyncFrame.NEW_ROSTER[command[2]] = false
        end
    end
    --code still here, but disabled in awardplayer
    if string.find(t, 'youWon=', 1, true) then
        if (not twlc2isRL(sender)) then return end
        local wonData = string.split(t, "=")
        if wonData[4] then
            LCVoteFrame.VotedItemsFrames[tonumber(wonData[4])].awardedTo = wonData[2]
            LCVoteFrame.updateVotedItemsFrames()
        end
    end
    --using playerWon instead, to let other CL know who got loot
    if string.find(t, 'playerWon#', 1, true) then
        if (not twlc2isRL(sender)) then return end
        local wonData = string.split(t, "#") --youWon#unitIndex#link#votedItem

        if not wonData[2] or not wonData[3] or not wonData[4] then
            twerror('bad playerWon syntax')
            twerror(t)
            return false
        end

        LCVoteFrame.VotedItemsFrames[tonumber(wonData[4])].awardedTo = wonData[2]
        LCVoteFrame.updateVotedItemsFrames()
        --save loot in history
        TWLC_LOOT_HISTORY[time()] = {
            ['player'] = wonData[2],
            ['item'] = LCVoteFrame.VotedItemsFrames[tonumber(wonData[4])].link
        }
    end
    if string.sub(t, 1, 4) == 'ttn=' then
        if (not twlc2isRL(sender)) then return end

        local ttn = string.split(t, "=")

        if not ttn[2] then
            twerror('bad ttn syntax')
            twerror(t)
            return false
        end

        TIME_TO_NEED = tonumber(ttn[2])
        TWLCCountDownFRAME.countDownFrom = TIME_TO_NEED
    end
    if string.sub(t, 1, 4) == 'ttv=' then
        if (not twlc2isRL(sender)) then return end

        local ttv = string.split(t, "=")

        if not ttv[2] then
            twerror('bad ttv syntax')
            twerror(t)
            return false
        end

        TIME_TO_VOTE = tonumber(ttv[2])
        VoteCountdown.countDownFrom = TIME_TO_VOTE
    end
    if string.sub(t, 1, 4) == 'ttr=' then
        if not twlc2isRL(sender) then return end

        local ttr = string.split(t, "=")

        if not ttr[2] then
            twerror('bat ttr syntax')
            twerror(t)
            return false
        end

        TIME_TO_ROLL = tonumber(ttr[2])
    end
    if string.sub(t, 1, 10) == 'ttnfactor=' then
        if not twlc2isRL(sender) then return end

        local ttnfactor = string.split(t, "=")

        if not ttnfactor[2] then
            twerror('bat ttr syntax')
            twerror(t)
            return false
        end

        TWLC_TTN_FACTOR = tonumber(ttnfactor[2])
        getglobal('BroadcastLoot'):SetText('Broadcast Loot (' .. TWLC_TTN_FACTOR .. 's)')
    end
    if string.sub(t, 1, 10) == 'ttvfactor=' then
        if not twlc2isRL(sender) then return end

        local ttvfactor = string.split(t, "=")

        if not ttvfactor[2] then
            twerror('bat ttr syntax')
            twerror(t)
            return false
        end

        TWLC_TTV_FACTOR = tonumber(ttvfactor[2])
    end
    if string.find(t, 'withAddonVF=', 1, true) then
        local i = string.split(t, "=")

        if not i[2] or not i[3] or not i[4] then
            twerror('bad withAddonVF syntax')
            twerror(t)
            return false
        end

        if (i[2] == me) then --i[2] = who requested the who
            local verColor = ""
            if (twlc_ver(i[4]) == twlc_ver(addonVer)) then verColor = classColors['hunter'].c end
            if (twlc_ver(i[4]) < twlc_ver(addonVer)) then verColor = '|cffff222a' end
            local star = ' '
            if string.len(i[4]) < 7 then i[4] = '0.' .. i[4] end
            if twlc2isRLorAssist(sender) then star = '*' end
            LCVoteFrame.peopleWithAddon = LCVoteFrame.peopleWithAddon .. star ..
                    classColors[getPlayerClass(sender)].c ..
                    sender .. ' ' .. verColor .. i[4] .. '\n'
            getglobal('VoteFrameWhoTitle'):SetText('TWLC2 With Addon')
            getglobal('VoteFrameWhoText'):SetText(LCVoteFrame.peopleWithAddon)
        end
    end
    if string.find(t, 'loot_history_sync;', 1, true) then

        if twlc2isRL(sender) and sender == me and t == 'loot_history_sync;end' then
            twprint('History Sync complete.')
            getglobal('RLWindowFrameSyncLootHistory'):Enable()
        end

        if not twlc2isRL(sender) or sender == me then return end
        local lh = string.split(t, ";")

        if not lh[2] or not lh[3] or not lh[4] then
            twerror('bad loot_history_sync syntax')
            twerror(t)
            return false
        end

        if lh[2] == 'start' then
            --TWLC_LOOT_HISTORY = {}
        elseif lh[2] == 'end' then
            twdebug('loot history synced.')
        else
            TWLC_LOOT_HISTORY[tonumber(lh[2])] = {
                ["player"] = lh[3],
                ["item"] = lh[4],
            }
        end
    end
end

function refreshList()
    --getto ordering
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

    if LCVoteFrame.CurrentVotedItem ~= nil then
        for n, d in next, LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem] do

            if getPlayerInfo(n) then
                local _, _, _, _, _, _, _, pIndex = getPlayerInfo(n)

                for voter, vote in next, LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][n] do
                    if vote == '+' then
                        LCVoteFrame.currentPlayersList[pIndex].votes = LCVoteFrame.currentPlayersList[pIndex].votes + 1
                    end
                end
            else
                twerror('getPlayerInfo(' .. n .. ') Not Found. Please report this.')
            end
        end
    end
end

function calculateWinner()

    if not LCVoteFrame.CurrentVotedItem then return false end

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
        local color = classColors[getPlayerClass(LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].awardedTo)]
        getglobal("MLToWinner"):SetText('Awarded to ' .. color.c .. LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].awardedTo);
        getglobal("WinnerStatus"):SetText('Awarded to ' .. color.c .. LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].awardedTo);
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
            local color = classColors[getPlayerClass(LCVoteFrame.currentRollWinner)]
            getglobal("MLToWinner"):SetText('Award ' .. color.c .. LCVoteFrame.currentRollWinner);
            getglobal("WinnerStatus"):SetText('Winner: ' .. color.c .. LCVoteFrame.currentRollWinner);
            --            twdebug('set text to award x')
            LCVoteFrame.currentItemWinner = LCVoteFrame.currentRollWinner
            LCVoteFrame.voteTiePlayers = ''
        else
            getglobal("MLToWinner"):Enable();
            getglobal("MLToWinner"):SetText('ROLL VOTE TIE'); -- .. voteTies
            getglobal("WinnerStatus"):SetText('VOTE TIE'); -- .. voteTies
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
            local color = classColors[getPlayerClass(LCVoteFrame.currentItemWinner)]
            getglobal("MLToWinner"):SetText('Award single picker ' .. color.c .. LCVoteFrame.currentItemWinner);
            getglobal("WinnerStatus"):SetText('Single picker ' .. color.c .. LCVoteFrame.currentItemWinner);
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
            getglobal("WinnerStatus"):SetText('VOTE TIE'); -- .. voteTies
        else
            --no tie
            LCVoteFrame.voteTiePlayers = ''
            if (LCVoteFrame.currentItemWinner ~= '') then
                if not VoteCountdown.votingOpen then
                    getglobal("MLToWinner"):Enable();
                end
                local color = classColors[getPlayerClass(LCVoteFrame.currentItemWinner)]
                getglobal("MLToWinner"):SetText('Award ' .. color.c .. LCVoteFrame.currentItemWinner);
                getglobal("WinnerStatus"):SetText('Winner: ' .. color.c .. LCVoteFrame.currentItemWinner);
            else
                getglobal("MLToWinner"):Disable()
                getglobal("MLToWinner"):SetText('Waiting votes...')
                getglobal("WinnerStatus"):SetText('Waiting votes...')
            end
        end
    end
end

function updateLCVoters()

    if not LCVoteFrame.CurrentVotedItem then return false end

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
        getglobal('WinnerStatusNrOfVotes'):SetText('|cff1fba1fEveryone voted!')
        getglobal('MLToWinner'):Enable()
    else
        getglobal('MLToWinnerNrOfVotes'):SetText('|cffa53737' .. nr .. '/' .. numOfficersInRaid .. ' votes')
        getglobal('WinnerStatusNrOfVotes'):SetText('|cffa53737' .. nr .. '/' .. numOfficersInRaid .. ' votes')
        getglobal('MLToWinner'):Disable()
    end
end

function MLToWinner_OnClick()
    --    twdebug(LCVoteFrame.voteTiePlayers)
    if (LCVoteFrame.voteTiePlayers ~= '') then
        LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].rolled = true
        local players = string.split(LCVoteFrame.voteTiePlayers, ' ')
        for i, d in next, LCVoteFrame.currentPlayersList do
            for pIndex, tieName in next, players do
                if d['itemIndex'] == LCVoteFrame.CurrentVotedItem and d['name'] == tieName then

                    local linkString = LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].link
                    local _, _, itemLink = string.find(linkString, "(item:%d+:%d+:%d+:%d+)");
                    local name, il, quality, _, _, _, _, _, tex = GetItemInfo(itemLink)


                    local roll = math.random(1, 100)
                    for pwIndex, pwPlayer in next, LCVoteFrame.playersWhoWantItems do
                        if (pwPlayer['name'] == tieName and pwPlayer['itemIndex'] == LCVoteFrame.CurrentVotedItem) then
                            -- found the wait=
                            LCVoteFrame.playersWhoWantItems[pwIndex]['roll'] = -2 --roll
                            --send to officers
                            SendAddonMessage("TWLCNF", "playerRoll:" .. pwIndex .. ":-2:" .. LCVoteFrame.CurrentVotedItem, "RAID")
                            --send to raiders
                            SendAddonMessage("TWLCNF", 'rollFor=' .. LCVoteFrame.CurrentVotedItem .. '=' .. tex .. '=' .. name .. '=' .. linkString .. '=' .. TIME_TO_ROLL .. '=' .. tieName, "RAID")
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


function Contestant_OnEnter(id)
    local playerOffset = FauxScrollFrame_GetOffset(getglobal("ContestantScrollListFrame"));
    id = id - playerOffset
    local r, g, b, a = getglobal('ContestantFrame' .. id):GetBackdropColor()
    getglobal('ContestantFrame' .. id):SetBackdropColor(r, g, b, 1)
end

function Contestant_OnLeave()
    for i = 1, LCVoteFrame.playersPerPage do
        local r, g, b, a = getglobal('ContestantFrame' .. i):GetBackdropColor()
        if (LCVoteFrame.selectedPlayer[LCVoteFrame.CurrentVotedItem] ~= getglobal('ContestantFrame' .. i).name) then
            getglobal('ContestantFrame' .. i):SetBackdropColor(r, g, b, 0.5)
        end
    end
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

function pairsByKeysReverse(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n)
    end
    table.sort(a, function(a, b) return a > b
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

    if not playerName or playerName == '' then
        twerror('AwardPlayer: playerName is nil.')
        return false
    end
    --debug
    --    local link = LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].link
    --    ChatThrottleLib:SendAddonMessage("NORMAL","TWLCNF", "youWon=" .. playerName .. "=" .. link .. "=" .. LCVoteFrame.CurrentVotedItem, "RAID")
    --enddebug

    local unitIndex = 0
    twdebug(playerName)

    for i = 1, 40 do
        if GetMasterLootCandidate(i) == playerName then
            twdebug('found: loot candidate' .. GetMasterLootCandidate(i) .. ' ==  arg1:' .. playerName)
            unitIndex = i
            break
        end
    end

    if (unitIndex == 0) then
        twprint("Something went wrong, " .. playerName .. " is not on loot list.")
    else
        local link = LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].link
        local itemIndex = LCVoteFrame.CurrentVotedItem

        twdebug('ML item should be ' .. link)
        local foundItemIndexInLootFrame = false
        for id = 0, GetNumLootItems() do
            if GetLootSlotInfo(id) and GetLootSlotLink(id) then
                if link == GetLootSlotLink(id) then
                    foundItemIndexInLootFrame = true
                    itemIndex = id
                end
            end
        end

        if foundItemIndexInLootFrame then

            SendAddonMessage("TWLCNF", "playerWon#" .. GetMasterLootCandidate(unitIndex) .. "#" .. link .. "#" .. LCVoteFrame.CurrentVotedItem, "RAID")

            GiveMasterLoot(itemIndex, unitIndex);

            local itemIndex, name, need, votes, ci1, ci2, roll = getPlayerInfo(GetMasterLootCandidate(unitIndex));

            SendChatMessage(GetMasterLootCandidate(unitIndex) .. ' was awarded with ' .. link .. ' for ' .. needs[need].text .. '!', "RAID")
            LCVoteFrame.VotedItemsFrames[LCVoteFrame.CurrentVotedItem].awardedTo = playerName
            LCVoteFrame.updateVotedItemsFrames()

        else
            twerror('Item not found. Is the loot window opened ?')
        end
    end
end


function twlc_ver(ver)
    if string.sub(ver, 7, 7) == '' then ver = '0.' .. ver end

    return tonumber(string.sub(ver, 1, 1)) * 1000 +
            tonumber(string.sub(ver, 3, 3)) * 100 +
            tonumber(string.sub(ver, 5, 5)) * 10 +
            tonumber(string.sub(ver, 7, 7)) * 1
end

function closeWhoWindow()
    getglobal('VoteFrameWho'):Hide()
end


function SecondsToClock(seconds)
    local seconds = tonumber(seconds)

    if seconds <= 0 then
        return "00:00";
    else
        hours = string.format("%02.f", math.floor(seconds / 3600));
        mins = string.format("%02.f", math.floor(seconds / 60 - (hours * 60)));
        secs = string.format("%02.f", math.floor(seconds - hours * 3600 - mins * 60));
        return mins .. ":" .. secs
    end
end

StaticPopupDialogs["TWLC_CONFIRM_LOOT_DISTRIBUTION"] = {
    text = "TWLC You wish to assign %s to %s.  Is this correct?",
    button1 = "yes",
    button2 = "no",
    timeout = 0,
    hideOnEscape = 1,
};

StaticPopupDialogs["TWLC_CONFIRM_LOOT_DISTRIBUTION"].OnAccept = function(data)
    --    twdebug('popul confirm loot data : ' .. data)
    if not LCVoteFrame.CurrentVotedItem then
        --        twdebug('popul confirm loot LCVoteFrame.CurrentVotedItem : nil ')
    else
        --        twdebug('popul confirm loot LCVoteFrame.CurrentVotedItem : ' .. LCVoteFrame.CurrentVotedItem)
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

function testComs(j)
    local total = 0
    local k = 0
    for i = 1, j do
        k = k + 1
        if k == 1 then SendAddonMessage("TWLCNF", "bis=1=0=0", "RAID") end
        if k == 2 then SendAddonMessage("TWLCNF", "ms=1=0=0", "RAID") end
        if k == 3 then SendAddonMessage("TWLCNF", "os=1=0=0", "RAID") end
        if k == 4 then SendAddonMessage("TWLCNF", "pass=1=0=0", "RAID") k = 0 end
        total = total + string.len("pass=1=0=0")
    end
    twdebug('come len : ' .. total)
end


function TestNeedButton_OnClick()

    local testItem1 = "\124cffa335ee\124Hitem:19401:0:0:0:0:0:0:0:0\124h[Primalist's Linked Legguards]\124h\124r";
    local testItem2 = "\124cffa335ee\124Hitem:19362:0:0:0:0:0:0:0:0\124h[Doom's Edge]\124h\124r";
--    local testItem3 = "\124cffa335ee\124Hitem:16533:0:0:0:0:0:0:0:0\124h[Warlord's Silk Cowl]\124h\124r";

    local _, _, itemLink1 = string.find(testItem1, "(item:%d+:%d+:%d+:%d+)");
    local lootName1, itemLink1, quality1, _, _, _, _, _, lootIcon1 = GetItemInfo(itemLink1)

    local _, _, itemLink2 = string.find(testItem2, "(item:%d+:%d+:%d+:%d+)");
    local lootName2, itemLink2, quality2, _, _, _, _, _, lootIcon2 = GetItemInfo(itemLink2)

    if quality1 and lootIcon1 and quality2 and lootIcon2 then

        SendChatMessage('This is a test, click whatever you want!', "RAID_WARNING")
        getglobal('BroadcastLoot'):Disable()

        SendAddonMessage("TWLCNF", 'ttnfactor=' .. TWLC_TTN_FACTOR, "RAID")
        SendAddonMessage("TWLCNF", 'ttvfactor=' .. TWLC_TTV_FACTOR, "RAID")

        TIME_TO_NEED = 2 * TWLC_TTN_FACTOR
        TWLCCountDownFRAME.countDownFrom = TIME_TO_NEED
        SendAddonMessage("TWLCNF", 'ttn=' .. TIME_TO_NEED, "RAID")
        TIME_TO_VOTE = 2 * TWLC_TTV_FACTOR
        SendAddonMessage("TWLCNF", 'ttv=' .. TIME_TO_VOTE, "RAID")
        SendAddonMessage("TWLCNF", 'ttr=' .. TIME_TO_ROLL, "RAID")

        sendReset()

        SendAddonMessage("TWLCNF", "voteframe=show", "RAID")

        TWLCCountDownFRAME:Show()
        SendAddonMessage("TWLCNF", 'countdownframe=show', "RAID")

        ChatThrottleLib:SendAddonMessage("ALERT", "TWLCNF", "loot=1=" .. lootIcon1 .. "=" .. lootName1 .. "=" .. testItem1 .. "=" .. TWLCCountDownFRAME.countDownFrom, "RAID")
        ChatThrottleLib:SendAddonMessage("ALERT", "TWLCNF", "loot=2=" .. lootIcon2 .. "=" .. lootName2 .. "=" .. testItem2 .. "=" .. TWLCCountDownFRAME.countDownFrom, "RAID")

        getglobal("MLToWinner"):Disable();
    else

        local _, _, itemLink1 = string.find(testItem1, "(item:%d+:%d+:%d+:%d+)");
        GameTooltip:SetHyperlink(itemLink1)
        GameTooltip:Hide()

        local _, _, itemLink2 = string.find(testItem2, "(item:%d+:%d+:%d+:%d+)");
        GameTooltip:SetHyperlink(itemLink2)
        GameTooltip:Hide()

        twerror(testItem1 .. ' or ' .. testItem2 .. ' was not seen before, try again...')
    end
end
