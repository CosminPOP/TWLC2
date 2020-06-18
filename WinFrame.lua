local WinAnimFrame = CreateFrame("Frame")
WinAnimFrame:RegisterEvent("CHAT_MSG_ADDON")
WinAnimFrame:Hide()
WinAnimFrame.quality = 0
WinAnimFrame:SetScript("OnEvent", function()
    if (event) then
        if (event == "CHAT_MSG_ADDON") then
            if (arg1 == "TWLCNF") then
                if (string.find(arg2, 'youWon=')) then
                    local winEx = string.split(arg2, '=')
                    if (winEx[1] and winEx[2] and winEx[3]) then
                        if (winEx[2] == UnitName('player')) then
                            local _, _, itemLink = string.find(winEx[3], "(item:%d+:%d+:%d+:%d+)");
                            local name, _, quality, _, _, _, _, _, tex = GetItemInfo(itemLink)
                            local _, _, _, color = GetItemQualityColor(quality)
                            WinAnimFrame.quality = quality
                            DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0[TWLC2] |cffffffff" .. arg2)
                            getglobal('WinFrameIcon'):SetNormalTexture(tex)
                            getglobal('WinFrameItemName'):SetText(color .. name)
                            start_anim()
                        end
                    end
                end
            end
        end
    end
end)
function start_anim()
    WinAnimFrame:Hide()
    WinAnimFrame:Show()
    getglobal('WinFrame'):SetAlpha(0)
    getglobal('WinFrame'):Show()
    WinAnimFrame.doAnim = true
    WinAnimFrame.showLootWindow = true
end

WinAnimFrame.doAnim = false
WinAnimFrame.showLootWindow = false

WinAnimFrame:SetScript("OnShow", function()
    this.startTime = (GetTime());
    this.frameIndex = 0;
end)
WinAnimFrame:SetScript("OnUpdate", function()
    if (WinAnimFrame.showLootWindow) then
        if ((GetTime()) >= (this.startTime) + 0.05) then

            this.startTime = (GetTime());


            local frame = getglobal('WinFrame')

            local image = 'loot_frame_' .. WinAnimFrame.quality .. '_';
            if this.frameIndex < 10 then
                image = image .. '0' .. this.frameIndex;
            else
                image = image .. this.frameIndex;
            end

            this.frameIndex = this.frameIndex + 1

            if (WinAnimFrame.doAnim) then
                local backdrop = {
                    bgFile = 'Interface\\AddOns\\TWLC2\\images\\loot\\' .. image
                };
                frame:SetBackdrop(backdrop)
                frame:SetAlpha(frame:GetAlpha() + 0.05)
            end
            if (this.frameIndex == 21) then
                WinAnimFrame.doAnim = false
            end

            if (this.frameIndex > 60) then
                frame:SetAlpha(frame:GetAlpha() - 0.05)
            end
            if (this.frameIndex == 80) then
                WinAnimFrame.showLootWindow = false
                this.frameIndex = 0;
                frame:Hide()
            end
        end
    end
end)


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
