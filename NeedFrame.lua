local LootLCCountdown = CreateFrame("Frame")
local NeedFrameComms = CreateFrame("Frame")
NeedFrameComms:RegisterEvent("CHAT_MSG_ADDON")

LootLCCountdown:Hide()
LootLCCountdown.timeToNeed = 30

LootLCCountdown.T = 1
LootLCCountdown.C = LootLCCountdown.timeToNeed
LootLCCountdown.width = 300 --countdown line width


local LootLCNeedFrames = CreateFrame("Frame")
LootLCNeedFrames.itemFrames = {}


LootLCCountdown:SetScript("OnShow", function()
    this.startTime = math.floor(GetTime());
end)


LootLCCountdown:Show()

LootLCCountdown:SetScript("OnUpdate", function()
    if (math.floor(GetTime()) == math.floor(this.startTime) + 1) then
        if (LootLCCountdown.T ~= LootLCCountdown.timeToNeed + 1) then
            --tick
            getglobal('LootLCNeedFrameWindowTimeLeftCountdownFrameTimeLeft'):SetText(LootLCCountdown.C - LootLCCountdown.T + 1 .. "s")
            getglobal('LootLCNeedFrameWindowTimeLeftCountdownFrame'):SetWidth(math.floor(LootLCCountdown.C - LootLCCountdown.T + 1) * LootLCCountdown.width / LootLCCountdown.timeToNeed)
            if (LootLCCountdown.C - LootLCCountdown.T + 1 >= 20) then
                getglobal('LootLCNeedFrameWindowTimeLeftCountdownFrame'):SetBackdropColor(0, 0.88, 0.06, 1);
            elseif (LootLCCountdown.C - LootLCCountdown.T + 1 > 10 and LootLCCountdown.C - LootLCCountdown.T + 1 < 20) then
                getglobal('LootLCNeedFrameWindowTimeLeftCountdownFrame'):SetBackdropColor(1, 0.5, 0.02, 1);
            else
                getglobal('LootLCNeedFrameWindowTimeLeftCountdownFrame'):SetBackdropColor(1, 0, 0, 1);
            end
        end
        LootLCCountdown:Hide()
        if (LootLCCountdown.T < LootLCCountdown.C + 1) then
            --still tick
            LootLCCountdown.T = LootLCCountdown.T + 1
            LootLCCountdown:Show()
        elseif (LootLCCountdown.T == LootLCCountdown.timeToNeed + 1) then

            --end
            getglobal('LootLCNeedFrameWindowTimeLeftCountdownFrameTimeLeft'):SetText("CLOSED")
            LootLCCountdown:Hide()
            LootLCCountdown.T = 1


            --            local j = 0
            --            for n, v in next, LootLC.votes do
            --                j = j + 1
            --            end

            --            if (j == 0) then
            --                lcprint("Nobody linked")
            --            else
            --                LootLC:AddPlayers() -- ML/RL View
            --                getglobal("LootLCWindow"):SetHeight(170 + j * 40)
            --            end

        else
            --
        end
    else
        --
    end
end)

function LootLCNeedFrames.addItem(data)
    local item = string.split(data, "=")

    local index = tonumber(item[2])
    local texture = item[3]
    local name = item[4]
    local link = item[5]

    GetItemInfo(link) --cache ???

    if (not LootLCNeedFrames.itemFrames[index]) then
        LootLCNeedFrames.itemFrames[index] = CreateFrame("Frame", "LCNeedFrame" .. index, getglobal("LootLCNeedFrameWindow"), "NeedFrameItemTemplate")
    end

    LootLCNeedFrames.itemFrames[index]:Show()
    LootLCNeedFrames.itemFrames[index]:SetPoint("TOP", getglobal("LootLCNeedFrameWindow"), "TOP", 0, 0 - (55 * index))
    LootLCNeedFrames.itemFrames[index].link = link

    getglobal('LCNeedFrame' .. index .. 'ItemIcon'):SetNormalTexture(texture);
    getglobal('LCNeedFrame' .. index .. 'ItemButton'):SetText(link);

    getglobal('LCNeedFrame' .. index .. 'BISButton'):SetID(index);
    getglobal('LCNeedFrame' .. index .. 'MSUpgradeButton'):SetID(index);
    getglobal('LCNeedFrame' .. index .. 'OSButton'):SetID(index);
    getglobal('LCNeedFrame' .. index .. 'PassButton'):SetID(index);

    addOnEnterTooltipNeedFrame(getglobal('LCNeedFrame' .. index .. 'ItemIcon'), link)


    CalcMainWindowHeight()
    getglobal('LootLCNeedFrameWindow'):Show()
end

function PlayerNeedItemButton_OnClick(id, need)

    local myItem1 = "0"
    local myItem2 = "0"

    local _, _, itemLink = string.find(LootLCNeedFrames.itemFrames[id].link, "(item:%d+:%d+:%d+:%d+)");
    local name, link, quality, reqlvl, t1, t2, a7, equip_slot, tex = GetItemInfo(itemLink)
    if equip_slot then
        -- twdebug('player need equip_slot frame : ' .. equip_slot)
    else
        twdebug(' nu am gasit item slot wtffff : ' .. itemLink)
    end

    for i = 1, 19 do
        if GetInventoryItemLink('player', i) then
            local _, _, itemID = string.find(GetInventoryItemLink('player', i), "item:(%d+):%d+:%d+:%d+")
            local _, _, eqItemLink = string.find(GetInventoryItemLink('player', i), "(item:%d+:%d+:%d+:%d+)");

            local _, _, itemRarity, _, _, _, _, itemSlot, _ = GetItemInfo(eqItemLink)

            if (itemSlot) then
                if (equip_slot == itemSlot) then
                    if (myItem1 == "0") then
                        myItem1 = eqItemLink
                    else
                        myItem2 = eqItemLink
                    end
                end
            else
                twdebug(' !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! itemslot ')
            end
        end
    end

    SendAddonMessage("TWLCNF", need .. "=" .. id .. "=" .. myItem1 .. "=" .. myItem2, "RAID")
    LootLCNeedFrames.itemFrames[id]:Hide()

    groupNeedFrames()
    CalcMainWindowHeight()
end

function groupNeedFrames()
    local visibleFrames = 0;
    for i = 1, table.getn(LootLCNeedFrames.itemFrames), 1 do
        if (LootLCNeedFrames.itemFrames[i]) then
            if LootLCNeedFrames.itemFrames[i]:IsVisible() then
                visibleFrames = visibleFrames + 1
--                LootLCNeedFrames.itemFrames[i]:SetPoint("TOP", getglobal("LootLCNeedFrameWindow"), "TOP", 0, 0 - (55 * visibleFrames))
            end
        end
    end
end

function CalcMainWindowHeight()
    local framesNo = 0
    for index, fr in next, LootLCNeedFrames.itemFrames do
        if (LootLCNeedFrames.itemFrames[index]) then
            if (LootLCNeedFrames.itemFrames[index]:IsVisible()) then
                framesNo = framesNo + 1
            end
        end
    end
    getglobal('LootLCNeedFrameWindow'):SetHeight(55 + 55 * framesNo)

    if (framesNo == 0) then
        getglobal('LootLCNeedFrameWindow'):Hide()
    end
end

function ResetVars()
    twdebug('Need reset')
    for index, frame in next, LootLCNeedFrames.itemFrames do
        LootLCNeedFrames.itemFrames[index]:Hide()
    end
    CalcMainWindowHeight()
end

-- comms

NeedFrameComms:SetScript("OnEvent", function()
    --TWLCNF
    if (event) then
        if (event == 'CHAT_MSG_ADDON') then
            if (arg1 == 'TWLCNF') then
                --                twdebug(arg1 .. ": " .. arg2)
                if (string.find(arg2, 'loot=', 1, true)) then
                    LootLCNeedFrames.addItem(arg2)
                end

                if (string.find(arg2, 'needframe=', 1, true)) then
                    local command = string.split(arg2, '=')
                    if (command[2] == "reset") then
                        ResetVars()
                    end
                end
            end
        end
    end
end)


-- utils

function addOnEnterTooltipNeedFrame(frame, itemLink)
    local ex = string.split(itemLink, "|")

    if (not ex[3]) then return end

    frame:SetScript("OnEnter", function(self)
        LCTooltipNeedFrame:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 2), -(this:GetHeight() / 2));
        LCTooltipNeedFrame:SetHyperlink(string.sub(ex[3], 2, string.len(ex[3])));
        LCTooltipNeedFrame:Show();
    end)
    frame:SetScript("OnLeave", function(self)
        LCTooltipNeedFrame:Hide();
    end)
end
