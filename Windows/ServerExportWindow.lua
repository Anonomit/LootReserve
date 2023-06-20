
LootReserve.Server.Export.reservesExportHeaderText    = "Player,Class,ExtraReserves,RollBonus,Item,Count";
LootReserve.Server.Export.reservesExportFormatPattern = "\n%s,%s,%d,%d,%d,%d";
LootReserve.Server.Export.rollsExportHeaderText       = "Time,Item ID,Item Name,Winner,Reserved,Raid Rolled,Disenchanted,Reason";
LootReserve.Server.Export.rollsExportFormatPattern    = "\n%d,%d,%s,%s,%d,%d,%d,%s";


function LootReserve.Server.Export:UpdateReservesExportText()
    local members = LootReserve.Server.CurrentSession and LootReserve.Server.CurrentSession.Members or LootReserve.Server.NewSessionSettings.ImportedMembers;
    local text = "";
    if members and next(members) then
        for player, member in LootReserve:Ordered(members, function(aMember, bMember, aPlayer, bPlayer) return aPlayer < bPlayer; end) do
            local counts = { };
            for i, itemID in ipairs(member.ReservedItems) do
                counts[itemID] = (counts[itemID] or 0) + 1;
            end
            for itemID, count in pairs(counts) do
                text = text .. format(self.reservesExportFormatPattern, player, member.Class and select(2, LootReserve:GetClassInfo(member.Class)) or "", member.ReservesDelta, member.RollBonus[itemID], itemID, count);
            end
        end
        text = self.reservesExportHeaderText .. text;
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
                        
                        local winners = roll.Winners;
                        if not winners then
                            -- this can happen with older rolls, or on a reserved item when nobody rolled
                            winners = { };
                            local max = LootReserve.Constants.RollType.NotRolled;
                            for player, rolls in pairs(roll.Players) do
                                for _, rollNumber in ipairs(rolls) do
                                    if rollNumber >= max then
                                        if rollNumber > max then
                                            wipe(winners);
                                            max = rollNumber;
                                        end
                                        table.insert(winners, player);
                                    end
                                end
                            end
                            if max <= LootReserve.Constants.RollType.NotRolled then
                                wipe(winners);
                            end
                        end
                        
                        for _, winner in ipairs(winners) do
                            local max = 100;
                            local _;
                            if roll.Tiered then
                                local highest = LootReserve.Server:GetWinningRollAndPlayers(roll);
                                _, max = LootReserve.Server:ConvertFromTieredRoll(highest);
                            end
                            text = text .. format(self.rollsExportFormatPattern,
                                roll.StartTime,
                                roll.Item:GetID(),
                                roll.Item:GetName(),
                                winner,
                                (roll.Custom or roll.Disenchant) and 0 or 1,
                                roll.RaidRoll and 1 or 0,
                                roll.Disenchant and 1 or 0,
                                roll.Phases and roll.Phases[101-max] or "");
                        end
                    end
                elseif roll.Item:Exists() then
                    table.insert(missing, roll.Item);
                end
            end
        end
        if #missing > 0 then
            text = format("Loading item names...\nRemaining: %d\n\nInstall/Update ItemCache to remember the item database between sessions...", #missing);
        elseif text ~= "" then
            text = self.rollsExportHeaderText .. text;
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
    LootReserve:SetResizeBounds(self.Window, 300, 130);
end
