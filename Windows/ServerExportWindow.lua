

function LootReserve.Server.Export:UpdateReservesExportText()
    local members = LootReserve.Server.CurrentSession and LootReserve.Server.CurrentSession.Members or LootReserve.Server.NewSessionSettings.ImportedMembers;
    local text = "";
    if members and next(members) then
        local maxItems = 0
        for player, member in LootReserve:Ordered(members, function(aMember, bMember, aPlayer, bPlayer) return aPlayer < bPlayer; end) do
            text = text .. format("\n%s,%s,%d", player, member.Class and select(2, LootReserve:GetClassInfo(member.Class)) or "", member.ReservesDelta);
            for i, itemID in ipairs(member.ReservedItems) do
                text = text .. format(",%d", itemID);
                maxItems = i > maxItems and i or maxItems;
            end
        end
        text = format("Player,Class,Delta%s", string.rep(",Item", maxItems)) .. text;
    end
    self:SetText(text);
end

function LootReserve.Server.Export:UpdateRollsExportText(onlySession)
    local minTime = 0;
    if onlySession then
        if LootReserve.Server.CurrentSession then
            minTime = LootReserve.Server.CurrentSession.StartTime;
        else
            minTime = -1
        end
    end
    local text = "";
    local missing = { };
    
    if minTime >= 0 then
        for _, roll in ipairs(LootReserve.Server.RollHistory) do
            if roll.StartTime >= minTime then
                if roll.Item:IsCached() then
                    if #missing == 0 then
                        if roll.Winners then
                            for _, winner in ipairs(roll.Winners) do
                                text = text .. format("\n%d,%d,%s,%s", roll.StartTime, roll.Item:GetID(), roll.Item:GetName(), winner);
                            end
                        else
                            -- this can happen with older rolls, or on a reserved item when nobody rolled
                            local max = 0;
                            local winners = { };
                            for player, rolls in pairs(roll.Players) do
                                for _, rollNumber in ipairs(rolls) do
                                    if rollNumber >= max then
                                        if rollNumber > max then
                                            wipe(winners);
                                            max = rollNumber;
                                        end
                                        winners[player] = true;
                                    end
                                end
                            end
                            if max > 0 then
                                for winner in pairs(winners) do
                                    text = text .. format("\n%d,%d,%s,%s", roll.StartTime, roll.Item:GetID(), roll.Item:GetName(), winner);
                                end
                            end
                        end
                    end
                else
                    table.insert(missing, roll.Item);
                end
            end
        end
        if #missing > 0 then
            text = format("Loading item names...\nRemaining: %d\n\nInstall/Update ItemCache to remember the item database between sessions...", #missing);
        elseif text ~= "" then
            text = "Time,Item ID,Item Name,Winner" .. text;
        end
    end
    
    self:SetText(text);
    
    if #missing > 0 then
        if #missing > LootReserve.ItemSearch.BatchCap then
            for i = LootReserve.ItemSearch.BatchCap + 1, #missing do
                missing[i] = nil;
            end
        end
        if not self.PendingRollsExportTextUpdate or self.PendingRollsExportTextUpdate:IsComplete() then
            self.PendingRollsExportTextUpdate = LootReserve.ItemCache:OnCache(missing, function()
                self:UpdateRollsExportText();
            end);
        end
        self.PendingRollsExportTextUpdate:SetSpeed(math.ceil(#missing/LootReserve.ItemSearch.BatchFrames));
    end
end

function LootReserve.Server.Export:SetText(text)
    self.Window.Output.Scroll.EditBox:SetText(text);
    self.Window.Output.Scroll.EditBox:SetFocus();
    self.Window.Output.Scroll.EditBox:HighlightText();
    self.Window.Output.Scroll:UpdateScrollChildRect();
end

function LootReserve.Server.Export:OnWindowLoad(window)
    self.Window = window;
    self.Window.TopLeftCorner:SetSize(32, 32); -- Blizzard UI bug?
    self.Window.TitleText:SetText("LootReserve Host - Export");
    self.Window:SetMinResize(300, 130);
end
