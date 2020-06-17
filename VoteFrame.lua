local LCVoteFrame = CreateFrame("Frame", "LCVoteFrame")
LCVoteFrame:RegisterEvent("ADDON_LOADED")
LCVoteFrame:RegisterEvent("LOOT_OPENED")
LCVoteFrame:RegisterEvent("LOOT_SLOT_CLEARED")
LCVoteFrame:RegisterEvent("LOOT_CLOSED")
LCVoteFrame.VotedItemsFrames = {}
LCVoteFrame.CurrentVotedItem = nil --slotIndex
LCVoteFrame.currentPlayersList = {} --all
LCVoteFrame.playersPerPage = 15
LCVoteFrame.itemVotes = {}
LCVoteFrame.LCVoters = 0

local LCVoteFrameComms = CreateFrame("Frame")
LCVoteFrameComms:RegisterEvent("CHAT_MSG_ADDON")

local me = UnitName('player')

LCVoteFrame.playersWhoWantItems = {}

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

TWLC_ROSTER = {
    ["Smultron"] = false, --voted
    ["Ilmane"] = false, --voted
    ["Tyrelys"] = false, --voted
    ["Babagiega"] = false, --voted
    ["Faralynn"] = false, --voted
    ["Momo"] = false, --voted
    ["Trepp"] = false, --voted
    ["Chlo"] = false, --voted
    ["Er"] = false, --voted
    ["Chlothar"] = false, --voted
    ["Aurelian"] = false, --voted
    ["Kzktst"] = false, --voted
    ["Testwarr"] = false, --voted
}

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
    ["bis"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cff38fd03", text = 'BIS' },
    ["ms"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cff28a606", text = 'MS' },
    ["os"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cffff9600", text = 'OS' },
    ["pass"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cff696969", text = 'pass' },
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
    ["INVTYPE_AMMO"] = 'Ammo', --	0',
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
    return 'unknown'
end

function GetPlayer(index)
    return LCVoteFrame.playersWhoWantItems[index]
end

LCVoteFrame:SetScript("OnEvent", function()
    if (event) then
        --        twdebug(event)
        if (event == "ADDON_LOADED") then
            getglobal('BroadcastLoot'):Disable()

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
            getglobal('BroadcastLoot'):Show()
            getglobal('BroadcastLoot'):Enable()
        end
        if (event == "LOOT_SLOT_CLEARED") then
        end
        if (event == "LOOT_CLOSED") then
        end
    end
end)

function BroadcastLoot_OnClick()
    SendAddonMessage("TWLCNF", "needframe=reset", "RAID")
    SendAddonMessage("TWLCNF", "voteframe=reset", "RAID")

    for id = 0, GetNumLootItems() do
        if GetLootSlotInfo(id) and GetLootSlotLink(id) then
            local lootIcon, lootName, _, _, q = GetLootSlotInfo(id)

            local _, _, itemLink = string.find(GetLootSlotLink(id), "(item:%d+:%d+:%d+:%d+)");
            local _, _, quality = GetItemInfo(itemLink)
            if (quality >= 0) then
                SendAddonMessage("TWLCNF", "loot=" .. id .. "=" .. lootIcon .. "=" .. lootName .. "=" .. GetLootSlotLink(id), "RAID")
            end
        end
    end
    getglobal("MLToWinner"):Disable();
end

function addVotedItem(index, texture, name, link)

    LCVoteFrame.itemVotes[index] = {}

    if (not LCVoteFrame.VotedItemsFrames[index]) then
        LCVoteFrame.VotedItemsFrames[index] = CreateFrame("Frame", "VotedItem" .. index,
            getglobal("VotedItemsFrame"), "VotedItemsButtonTemplate")
    end

    LCVoteFrame.VotedItemsFrames[index]:SetPoint("TOPLEFT", getglobal("VotedItemsFrame"), "TOPLEFT", 7, 36 - (36 * index))

    LCVoteFrame.VotedItemsFrames[index]:Show()
    LCVoteFrame.VotedItemsFrames[index].link = link
    LCVoteFrame.VotedItemsFrames[index].texture = texture
    --    LCVoteFrame.VotedItems[i]:SetBackdropColor(1, 0.5, 0, 1)
    addButtonOnEnterTooltip(getglobal('VotedItem' .. index .. 'VotedItemButton'), link)
    getglobal('VotedItem' .. index .. 'VotedItemButton'):SetID(index)
    --    getglobal('VotedItem' .. index .. 'VotedItemButton'):SetText(link)
    getglobal('VotedItem' .. index .. 'VotedItemButton'):SetNormalTexture(texture)
    getglobal('VotedItem' .. index .. 'VotedItemButton'):SetPushedTexture(texture)
    getglobal('VotedItem' .. index .. 'VotedItemButton'):SetHighlightTexture(texture)

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

    getglobal("MLToWinner"):Show();

    SetDesaturation(getglobal('VotedItem' .. id .. 'VotedItemButton'):GetNormalTexture(), 0)
    for index, v in next, LCVoteFrame.VotedItemsFrames do
        if (index ~= id) then
            SetDesaturation(getglobal('VotedItem' .. index .. 'VotedItemButton'):GetNormalTexture(), 1)
        end
    end
    setCurrentVotedItem(id)
end

function setCurrentVotedItem(id)
    --    twdebug('set cvi to ' .. id)
    LCVoteFrame.CurrentVotedItem = id
    --    twdebug('LCVoteFrame.CurrentVotedItem = ' .. LCVoteFrame.CurrentVotedItem)
    getglobal('LootLCVoteFrameWindowCurrentVotedItemIcon'):SetNormalTexture(LCVoteFrame.VotedItemsFrames[id].texture)
    getglobal('LootLCVoteFrameWindowCurrentVotedItemIcon'):SetPushedTexture(LCVoteFrame.VotedItemsFrames[id].texture)
    local link = LCVoteFrame.VotedItemsFrames[id].link
    addButtonOnEnterTooltip(getglobal('LootLCVoteFrameWindowCurrentVotedItemName'), link)
    getglobal('LootLCVoteFrameWindowCurrentVotedItemName'):SetText(link)
    addButtonOnEnterTooltip(getglobal('LootLCVoteFrameWindowCurrentVotedItemIcon'), link)

    local _, _, itemLink = string.find(link, "(item:%d+:%d+:%d+:%d+)");
    local name, link, quality, reqlvl, t1, t2, a7, equip_slot, tex = GetItemInfo(itemLink)
    local votedItemType = ''
    if (t1) then votedItemType = t1 end
    if (t2) then votedItemType = votedItemType .. ' ' .. t2 end
    if (equip_slot) then votedItemType = votedItemType .. ' ' .. getEquipSlot(equip_slot) end
    getglobal('LootLCVoteFrameWindowCurrentVotedItemNameItemType'):SetText(votedItemType)
    VoteFrameListScroll_Update()
end

function getPlayerInfo(playerIndexOrName)
    if (type(playerIndexOrName) == 'string') then
        for k, player in next, LCVoteFrame.currentPlayersList do
            if player['name'] == playerIndexOrName then
                return player['itemIndex'], player['name'], player['need'], player['votes'], player['ci1'], player['ci2'], player['random'], k
            end
        end
    end
    local player = LCVoteFrame.currentPlayersList[playerIndexOrName]
    if (player) then
        return player['itemIndex'], player['name'], player['need'], player['votes'], player['ci1'], player['ci2'], player['random'], playerIndexOrName
    else
        return false
    end
end

function getPlayerClass(name)
    for i = 0, GetNumRaidMembers() do
        if (GetRaidRosterInfo(i)) then
            local n, r, s, l, c, f, zone = GetRaidRosterInfo(i);
            if (name == n) then
                return string.lower(c)
            end
        end
    end
    return 'priest'
end

function VoteFrameListScroll_Update()

    --    twdebug('VoteFrameListScroll_Update()');

    refreshList()
    calculateVotes()
    updateLCVoters()
    calculateWinner()


    local itemIndex, name, need, votes, ci1, ci2, roll
    local button
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

            button = getglobal("ContestantFrame" .. i);
            button:SetID(playerIndex)
            button.playerIndex = playerIndex;
            itemIndex, name, need, votes, ci1, ci2, roll = getPlayerInfo(playerIndex);

            --            twdebug('votes[' .. name .. '] = ' .. votes)

            local class = getPlayerClass(name)
            local color = classColors[class]


            getglobal("ContestantFrame" .. i .. "Name"):SetText(color.c .. name .. " " .. playerIndex);
            getglobal("ContestantFrame" .. i .. "Need"):SetText(needs[need].c .. needs[need].text);
            if (roll > 0) then
                getglobal("ContestantFrame" .. i .. "Roll"):SetText(roll);
            else
                getglobal("ContestantFrame" .. i .. "Roll"):SetText();
            end

            getglobal("ContestantFrame" .. i .. "Votes"):SetText(votes);
            getglobal("ContestantFrame" .. i .. "VoteButton"):SetID(playerIndex);

            getglobal('ContestantFrame' .. i):SetBackdropColor(color.r, color.g, color.b, 0.5);
            getglobal('ContestantFrame' .. i .. 'ClassIcon'):SetTexture('Interface\\AddOns\\TWLC2\\classes\\' .. class);

            if (need == 'pass' or need == 'wait') then
                getglobal("ContestantFrame" .. i .. "VoteButton"):Hide();
            else
                getglobal("ContestantFrame" .. i .. "VoteButton"):Show();
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
            --            button:LockHighlight();
            --        else
            --            button:UnlockHighlight();
            --        end

            if (playerIndex > table.getn(LCVoteFrame.currentPlayersList)) then
                button:Hide();
            else
                button:Show();
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

function ResetVars()
    --    twdebug('reset')

    LCVoteFrame.myVotes = {}
    LCVoteFrame.LCVoters = 0

    getglobal('BroadcastLoot'):Disable()

    LCVoteFrame.CurrentVotedItem = nil
    for index, frame in next, LCVoteFrame.VotedItemsFrames do
        LCVoteFrame.VotedItemsFrames[index]:Hide()
    end
    getglobal("MLToWinner"):Hide();
end

-- comms
LCVoteFrameComms:SetScript("OnEvent", function()
    if (event) then
        if (event == 'CHAT_MSG_ADDON') then

            --            if (arg1 == "TWLC" and arg4 ~= me) then
            --                if (not isAssistOrRL(arg4)) then
            --                    return
            --                end

            --populate voted items
            --todo assist protection
            --si probabil ~me
            if (arg1 == "TWLCNF") then
                LCVoteFrameComms:handleSync(arg1, arg2, arg3, arg4)
            end
        end
    end
end)


function LCVoteFrameComms:handleSync(pre, t, ch, sender)
    twdebug(sender .. ' says: ' .. t)
    if (string.find(t, 'itemVote:', 1, true) and sender ~= me) then
        local itemVoteEx = string.split(t, ':')
        local votedItem = tonumber(itemVoteEx[2])
        local votedPlayer = itemVoteEx[3]
        local vote = itemVoteEx[4]
        --        twdebug('voteditem ' .. votedItem .. ' votedplayuer ' .. votedPlayer .. ' ' .. vote)
        if (not LCVoteFrame.itemVotes[votedItem][votedPlayer]) then
            LCVoteFrame.itemVotes[votedItem][votedPlayer] = {}
        end
        LCVoteFrame.itemVotes[votedItem][votedPlayer][sender] = vote
        VoteFrameListScroll_Update()
    end
    if (string.find(t, 'voteframe=', 1, true)) then
        local command = string.split(t, '=')
        if (command[2] == "reset") then
            ResetVars()
        end
    end
    if (string.find(t, 'loot=', 1, true)) then
        local item = string.split(t, "=")
        -- todo - checks
        local index = tonumber(item[2])
        local texture = item[3]
        local name = item[4]
        local link = item[5]
        addVotedItem(index, texture, name, link)
    end
    if (string.find(t, 'wait=', 1, true)) then

        local needEx = string.split(t, '=')

        LCVoteFrame.playersWhoWantItems[table.getn(LCVoteFrame.playersWhoWantItems) + 1] = {
            ['itemIndex'] = tonumber(needEx[2]),
            ['name'] = sender,
            ['need'] = 'wait',
            ['ci1'] = needEx[3],
            ['ci2'] = needEx[4],
            ['votes'] = 0,
            ['random'] = 0
        }

        LCVoteFrame.itemVotes[tonumber(needEx[2])][sender] = {}

        VoteFrameListScroll_Update()
    end
    --ms=1=item:123=item:323
    if (string.find(t, 'bis=', 1, true) or string.find(t, 'ms=', 1, true)
            or string.find(t, 'os=', 1, true) or string.find(t, 'pass=', 1, true)) then
        --add to talbeformat ?
        local needEx = string.split(t, '=')

        --dev
        local charSet = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"
        --endDev

        --check if exists from wait message ?
        for index, player in next, LCVoteFrame.playersWhoWantItems do
            if (player['name'] == sender and player['itemIndex'] == tonumber(needEx[2])) then
                -- found the wait=
                LCVoteFrame.playersWhoWantItems[index]['need'] = needEx[1]
                LCVoteFrame.playersWhoWantItems[index]['ci1'] = needEx[3]
                LCVoteFrame.playersWhoWantItems[index]['ci2'] = needEx[4]
                --            twdebug('LCVoteFrame.playersWhoWantItems[index][c1] ' .. LCVoteFrame.playersWhoWantItems[index]['c1'])
                break
            end
        end


        --        LCVoteFrame.playersWhoWantItems[table.getn(LCVoteFrame.playersWhoWantItems) + 1] = {
        --            ['itemIndex'] = tonumber(needEx[2]),
        --            ['name'] = sender,
        --            ['need'] = needEx[1],
        --            ['ci1'] = needEx[3],
        --            ['ci2'] = needEx[4],
        --            ['votes'] = 0,
        --            ['random'] = 0
        --        }
        --
        --        LCVoteFrame.itemVotes[tonumber(needEx[2])][sender] = {}

        VoteFrameListScroll_Update()
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
    --        twdebug(player['itemIndex'] .. " pindex:" .. i .. "? " .. player['name'] .. " " .. player['need'] .. " " .. player['votes'] .. " " .. player['ci1'] .. " " .. player['ci2'] .. " " .. player['random'])
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

        --        twdebug('setting LCVoteFrame.currentPlayersList[' .. pIndex .. '].votes = 0')

        --LCVoteFrame.currentPlayersList[pIndex].votes = 0

        --        twdebug('LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][' .. n .. '] size = '
        --                .. table.getn(LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][n]))

        for voter, vote in next, LCVoteFrame.itemVotes[LCVoteFrame.CurrentVotedItem][n] do
            --            twdebug('voter : ' .. voter .. ' vote:' .. vote .. ' for ' .. n .. ' id ' .. pIndex)
            if vote == '+' then
                LCVoteFrame.currentPlayersList[pIndex].votes = LCVoteFrame.currentPlayersList[pIndex].votes + 1
                --                twdebug('LCVoteFrame.currentPlayersList[pIndex].votes = ' .. LCVoteFrame.currentPlayersList[pIndex].votes)
            else
                --                twdebug('LCVoteFrame.currentPlayersList[pIndex].votes = ' .. LCVoteFrame.currentPlayersList[pIndex].votes)
                --                LCVoteFrame.currentPlayersList[pIndex].votes = LCVoteFrame.currentPlayersList[pIndex].votes - 1
            end
        end

        --        local _, _, _, votes = getPlayerInfo(n)
        --        twdebug('votes in CV : ' .. votes)
        --        getglobal("ContestantFrame" .. pIndex .. "Votes"):SetText(votes);
    end
end

function calculateWinner()
    -- calc winner
    local winner = ''
    local maxVotes = 0
    local voteTies = '';
    for i, d in next, LCVoteFrame.currentPlayersList do
        if d['itemIndex'] == LCVoteFrame.CurrentVotedItem then
            if (d['votes'] > 0 and d['votes'] > maxVotes) then
                maxVotes = d['votes']
                winner = d['name']
            end
        end
    end

    --    twdebug('maxVotes = ' .. maxVotes)
    --tie check
    local ties = 0
    for i, d in next, LCVoteFrame.currentPlayersList do
        if d['itemIndex'] == LCVoteFrame.CurrentVotedItem then
            if (d['votes'] == maxVotes and maxVotes > 0) then
                voteTies = voteTies .. d['name'] .. ' '
                ties = ties + 1
            end
        end
    end
    -- TODO lead check

    if (ties > 1) then
        getglobal("MLToWinner"):Enable();
        getglobal("MLToWinner"):SetText('Random ' .. voteTies);
    else
        if (winner ~= '') then
            getglobal("MLToWinner"):Enable();
            getglobal("MLToWinner"):SetText('Award ' .. winner);
        else
            getglobal("MLToWinner"):Disable();
            getglobal("MLToWinner"):SetText('Award...');
        end
    end
end

function updateLCVoters()
    --    twdebug('updateLCVoters()')
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
        if (v) then nr = nr + 1 end
    end
    getglobal('MLToWinnerNrOfVotes'):SetText(nr .. ' votes ')
end

function MLToWinner_OnClick()
end

function MLTOME()

    local meIndex = 0

    for i = 1, 40 do
        if GetMasterLootCandidate(i) == UnitName('player') then
            meIndex = i
            break
        end
    end

    if (meIndex == 0) then
        lcprint("Something went wrong, winner name is not on loot list.")
    else
        GiveMasterLoot(LCVoteFrame.CurrentVotedItem, meIndex);
    end
end


function Contestant_OnEnter(id)
    local r, g, b, a = getglobal('ContestantFrame' .. id):GetBackdropColor()
    getglobal('ContestantFrame' .. id):SetBackdropColor(r, g, b, 1)
end

function Contestant_OnLeave(id)
    local r, g, b, a = getglobal('ContestantFrame' .. id):GetBackdropColor()
    getglobal('ContestantFrame' .. id):SetBackdropColor(r, g, b, 0.5)
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
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, function(a, b) return a > b end)
    local i = 0 -- iterator variable
    local iter = function() -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end
