local LibCustomGlow = LibStub("LibCustomGlow-1.0");

function LootReserve.Server:UpdateReserveListRolls(lockdown)
    if not self.Window:IsShown() then return; end

    lockdown = lockdown or InCombatLockdown() or not self.Settings.UseUnitFrames;

    local list = (lockdown and self.Window.PanelReservesLockdown or self.Window.PanelReserves).Scroll.Container;
    list.Frames = list.Frames or { };

    for _, frame in ipairs(list.Frames) do
        if frame:IsShown() and frame.ReservesFrame then
            frame.Roll = self:IsRolling(frame.Item) and not self.RequestedRoll.Custom and self.RequestedRoll or nil;

            frame.ReservesFrame.HeaderRoll:SetShown(frame.Roll);
            frame.ReservesFrame.ReportRolls:SetShown(false);
            frame.ReservesFrame.ReportReserves:SetShown(true);
            frame.RequestRollButton.CancelIcon:SetShown(frame.Roll and not frame.Historical and self:IsRolling(frame.Item));

            local highest = LootReserve.Constants.RollType.NotRolled;
            if frame.Roll then
                for player, rolls in pairs(frame.Roll.Players) do
                    for _, roll in ipairs(rolls) do
                        if highest < roll then
                            highest = roll;
                        end
                    end
                end
            end

            for _, button in ipairs(frame.ReservesFrame.Players) do
                if button:IsShown() then
                    if frame.Roll and frame.Roll.Players[button.Player] and frame.Roll.Players[button.Player][button.RollNumber] then
                        local roll = frame.Roll.Players[button.Player][button.RollNumber];
                        local rolled = roll > LootReserve.Constants.RollType.NotRolled;
                        local passed = roll == LootReserve.Constants.RollType.Passed;
                        local deleted = roll == LootReserve.Constants.RollType.Deleted;
                        local winner;
                        if frame.Roll.Winners then
                            winner = LootReserve:Contains(frame.Roll.Winners, button.Player);
                        else
                            winner = rolled and highest > LootReserve.Constants.RollType.NotRolled and roll == highest; -- Backwards compatibility
                        end

                        local color = not LootReserve:IsPlayerOnline(button.Player) and GRAY_FONT_COLOR or winner and GREEN_FONT_COLOR or passed and GRAY_FONT_COLOR or deleted and RED_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
                        button.Roll:Show();
                        button.Roll:SetText(rolled and tostring(roll) or passed and "PASS" or deleted and "DEL" or "...");
                        button.Roll:SetTextColor(color.r, color.g, color.b);
                        if not frame.Historical then
                            if LootReserve.Server:HasAlreadyWon(button.Player, frame.Item:GetID()) then
                                button.RedHighlight.title = "Already won";
                                button.RedHighlight.text  = {format("%s has already won %s this session.", LootReserve:ColoredPlayer(button.Player), frame.Item:GetLink())};
                                button.RedHighlight:Show();
                            else
                                button.RedHighlight:Hide();
                            end
                            button.GreenHighlight:Hide();
                        else
                            button.RedHighlight:Hide();
                            button.GreenHighlight:SetShown(winner);
                        end
                    else
                        button.Roll:Hide();
                        button.RedHighlight:Hide();
                        button.GreenHighlight:Hide();
                    end
                end
            end
        end
    end

    self:UpdateReserveListButtons(lockdown);
end

function LootReserve.Server:UpdateReserveListButtons(lockdown)
    if not self.Window:IsShown() then return; end

    lockdown = lockdown or InCombatLockdown() or not self.Settings.UseUnitFrames;

    local list = (lockdown and self.Window.PanelReservesLockdown or self.Window.PanelReserves).Scroll.Container;
    list.Frames = list.Frames or { };

    for _, frame in ipairs(list.Frames) do
        if frame:IsShown() and frame.ReservesFrame then
            frame.Roll = self:IsRolling(frame.Item) and not self.RequestedRoll.Custom and self.RequestedRoll or nil;

            for _, button in ipairs(frame.ReservesFrame.Players) do
                if button:IsShown() then
                    button.Name.WonRolls:SetShown(self.CurrentSession and self.CurrentSession.Members[button.Player] and self.CurrentSession.Members[button.Player].WonRolls);
                    button.Name.RecentChat:SetShown(frame.Roll and self:HasRelevantRecentChat(frame.Roll, button.Player));
                end
            end
        end
    end
end

function LootReserve.Server:UpdateReserveList(lockdown)
    if not self.Window:IsShown() then return; end

    lockdown = lockdown or InCombatLockdown() or not self.Settings.UseUnitFrames;

    local filter = LootReserve.ItemCache:FormatSearchText(self.Window.Searchbar:GetText());
    if #filter == 0 and not tonumber(filter) then
        filter = nil;
    end

    local list = (lockdown and self.Window.PanelReservesLockdown or self.Window.PanelReserves).Scroll.Container;
    list.Frames = list.Frames or { };
    list.LastIndex = 0;
    list.ContentHeight = 0;

    -- Clear everything
    for _, frame in ipairs(list.Frames) do
        frame:Hide();
    end

    local doneReserving = 0;
    local memberCount   = 0;
    if self.CurrentSession then
        for _, member in pairs(self.CurrentSession.Members) do
            memberCount = memberCount + 1;
            if member.ReservesLeft == 0 or member.OptedOut then
                doneReserving = doneReserving + 1;
            end
        end
    end
    self.Window.ButtonMenu:SetText(format("|cFF00FF00%d|r/%d", doneReserving, memberCount));
    if GameTooltip:IsOwned(self.Window.ButtonMenu) then
        self.Window.ButtonMenu:UpdateTooltip();
    end

    if not self.CurrentSession then
        return;
    end

    local function createFrame(item, reserve)
        list.LastIndex = list.LastIndex + 1;
        local frame = list.Frames[list.LastIndex];
        while not frame do
            frame = CreateFrame("Frame", nil, list, "LootReserveReserveListTemplate");
            table.insert(list.Frames, frame);
            frame = list.Frames[list.LastIndex];
        end

        frame:Show();

        item = LootReserve.ItemCache:Item(item);
        frame.Item = item;

        local name, link, texture = item:GetNameLinkTexture();
        frame.Link = link;
        frame.Historical = false;
        frame.Roll = self:IsRolling(frame.Item) and not self.RequestedRoll.Custom and self.RequestedRoll or nil;

        frame.ItemFrame.Icon:SetTexture(texture);
        frame.ItemFrame.Name:SetText((link or name or "|cFFFF4000Loading...|r"):gsub("[%[%]]", ""));
        local tracking = self.CurrentSession.LootTracking[item:GetID()];
        local fade = false;
        if LootReserve:IsLootingItem(item) then
            frame.ItemFrame.Misc:SetText("In loot");
            fade = false;
            if LibCustomGlow then
                LibCustomGlow.ButtonGlow_Start(frame.ItemFrame.IconGlow);
            end
        elseif tracking then
            local players = "";
            for player, count in pairs(tracking.Players) do
                players = players .. (#players > 0 and ", " or "") .. LootReserve:ColoredPlayer(player) .. (count > 1 and format(" (%d)", count) or "");
            end
            frame.ItemFrame.Misc:SetText("Looted by " .. players);
            fade = false;
            if LibCustomGlow then
                LibCustomGlow.ButtonGlow_Stop(frame.ItemFrame.IconGlow);
            end
        else
            frame.ItemFrame.Misc:SetText("Not looted");
            fade = self.Settings.ReservesSorting == LootReserve.Constants.ReservesSorting.ByLooter and next(self.CurrentSession.LootTracking) ~= nil;
            if LibCustomGlow then
                LibCustomGlow.ButtonGlow_Stop(frame.ItemFrame.IconGlow);
            end
        end
        frame:SetAlpha(fade and 0.25 or 1);

        frame.DurationFrame:SetShown(self:IsRolling(frame.Item) and self.RequestedRoll.MaxDuration and not self.RequestedRoll.Custom);
        frame.DurationFrame:SetHeight(frame.DurationFrame:IsShown() and 12 or 0.00001);

        local reservesHeight = 5 + 12 + 2;
        local last = 0;
        local playerNames = { };
        frame.ReservesFrame.Players = frame.ReservesFrame.Players or { };
        for i, player in ipairs(reserve.Players) do
            if i > #frame.ReservesFrame.Players then
                local button = CreateFrame("Button", nil, frame.ReservesFrame, lockdown and "LootReserveReserveListPlayerTemplate" or "LootReserveReserveListPlayerSecureTemplate");
                table.insert(frame.ReservesFrame.Players, button);
            end
            local unit = LootReserve:GetGroupUnitID(player);
            local button = frame.ReservesFrame.Players[i];
            if button.init then button:init(); end
            button:Show();
            button.Player = player;

            playerNames[player] = playerNames[player] and playerNames[player] + 1 or 1;
            button.RollNumber = playerNames[player];

            button.Unit = unit;
            if not lockdown then
                button:SetAttribute("unit", unit);
            end
            button.Name:SetText(format("%s%s", LootReserve:ColoredPlayer(player), LootReserve:IsPlayerOnline(player) == nil and "|cFF808080 (not in raid)|r" or LootReserve:IsPlayerOnline(player) == false and "|cFF808080 (offline)|r" or ""));
            button.Roll:SetText("");
            button.RedHighlight:Hide();
            button.GreenHighlight:Hide();
            button:SetPoint("TOPLEFT", frame.ReservesFrame, "TOPLEFT", 0, 5 - reservesHeight);
            button:SetPoint("TOPRIGHT", frame.ReservesFrame, "TOPRIGHT", 0, 5 - reservesHeight);
            reservesHeight = reservesHeight + button:GetHeight();
            last = i;
        end
        for i = last + 1, #frame.ReservesFrame.Players do
            local button = frame.ReservesFrame.Players[i];
            button:Hide();
            if not lockdown then
                button:SetAttribute("unit", nil);
            end
        end

        frame.ReservesFrame:SetPoint("TOP", frame.ItemFrame, "BOTTOM", 0, -5);
        frame:SetHeight(6 + 32 + 5 + reservesHeight - 1);
        frame:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -list.ContentHeight);
        frame:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, -list.ContentHeight);
        list.ContentHeight = list.ContentHeight + frame:GetHeight();
    end

    local function matchesFilter(item, reserve, filter)
        if #filter == 0 then
            return true;
        end

        if item:GetID() == tonumber(filter) then
            return true;
        end
        if string.find(item:GetSearchName(), filter, 1, true) then
            return true;
        end
        
        if reserve then
            for _, player in pairs(reserve.Players) do
                if string.find(LootReserve:SimplifyNameLower(player), filter, 1, true) then
                    return true;
                end
            end
        end

        return false;
    end

    local missing = { };
    local function getSortingTime(reserve)
        if LootReserve:IsLootingItem(reserve.Item) then
            return 0;
        end
        return reserve.StartTime;
    end
    local function getSortingName(reserve)
        if LootReserve:IsLootingItem(reserve.Item) then
            return "";
        end
        local name = ""
        local item = LootReserve.ItemCache:Item(reserve.Item);
        if item:IsCached() then
            name = item:GetName();
        elseif item:Exists() then
            table.insert(missing, item);
        end
        return name:upper();
    end
    local function getSortingSourceHelper(item)
        if LootReserve:IsLootingItem(item) then
            return 0;
        end
        local customIndex = 0;
        for itemID, conditions in pairs(self.CurrentSession.ItemConditions) do
            if conditions.Custom then
                customIndex = customIndex + 1;
                if itemID == item then
                    return customIndex;
                end
            end
        end
        for id, category in LootReserve:Ordered(LootReserve.Data.Categories, LootReserve.Data.CategorySorter) do
            if category.Children and (not self.CurrentSession or LootReserve:Contains(self.CurrentSession.Settings.LootCategories, id)) and LootReserve.Data:IsCategoryVisible(category) then
                for childIndex, child in ipairs(category.Children) do
                    if child.Loot then
                        for lootIndex, loot in ipairs(child.Loot) do
                            if loot == item then
                                return id * 10000 + childIndex * 100 + lootIndex;
                            end
                        end
                    end
                end
            end
        end
        return 100000000;
    end
    local sourceMemo = { };
    local function getSortingSource(reserve)
        local item = reserve.Item;
        if not sourceMemo[item] then
            sourceMemo[item] = getSortingSourceHelper(item);
        end
        return sourceMemo[item];
    end
    local function getSortingLooter(reserve)
        if LootReserve:IsLootingItem(reserve.Item) then
            return "";
        end
        local tracking = self.CurrentSession.LootTracking[reserve.Item];
        if tracking then
            for player, _ in LootReserve:Ordered(tracking.Players) do
                return player:upper();
            end
        else
            return "ZZZZZZZZZZZZ";
        end
    end

    local sorting = self.Settings.ReservesSorting;
        if sorting == LootReserve.Constants.ReservesSorting.ByTime   then sorting = getSortingTime;
    elseif sorting == LootReserve.Constants.ReservesSorting.ByName   then sorting = getSortingName;
    elseif sorting == LootReserve.Constants.ReservesSorting.BySource then sorting = getSortingSource;
    elseif sorting == LootReserve.Constants.ReservesSorting.ByLooter then sorting = getSortingLooter;
    else sorting = nil; end

    local function sorter(a, b)
        if sorting then
            local aOrder, bOrder = sorting(a), sorting(b);
            if aOrder ~= bOrder then
                return aOrder < bOrder;
            end
        end

        return a.Item < b.Item;
    end

    for itemID, reserve in LootReserve:Ordered(self.CurrentSession.ItemReserves, sorter) do
        local match = false;
        local item = LootReserve.ItemCache:Item(itemID);
        if item:IsCached() then
            if not filter or matchesFilter(item, reserve, filter) then
                createFrame(item, reserve, true);
                match = true;
            end
        elseif item:Exists() then
            table.insert(missing, item);
        end
        if filter and not match and LootReserve.Data:IsToken(itemID) then
            for _, rewardID in ipairs(LootReserve.Data:GetTokenRewards(itemID)) do
                local reward = LootReserve.ItemCache:Item(rewardID);
                if reward:IsCached() then
                    if item:IsCached() and matchesFilter(reward, nil, filter) then
                        createFrame(item, reserve, true);
                        break;
                    end
                elseif reward:Exists() then
                    table.insert(missing, reward);
                end
            end
        end
    end
    for i = list.LastIndex + 1, #list.Frames do
        local frame = list.Frames[i];
        frame:Hide();
        if not lockdown then
            for _, button in ipairs(frame.ReservesFrame.Players) do
                button:SetAttribute("unit", nil);
            end
        end
    end
    if #missing > 0 then
        if not self.PendingReserveListUpdate or self.PendingReserveListUpdate:IsComplete() then
            self.PendingReserveListUpdate = LootReserve.ItemCache:OnCache(missing, function()
                self:UpdateReserveList();
            end);
        end
    end

    list:GetParent():UpdateScrollChildRect();

    self:UpdateReserveListRolls(lockdown);
end

function LootReserve.Server:UpdateRollListRolls(lockdown)
    if not self.Window:IsShown() then return; end

    lockdown = lockdown or InCombatLockdown() or not self.Settings.UseUnitFrames;

    local list = (lockdown and self.Window.PanelRollsLockdown or self.Window.PanelRolls).Scroll.Container;
    list.Frames = list.Frames or { };

    for i, frame in ipairs(list.Frames) do
        if frame:IsShown() and frame.ReservesFrame then
            frame.ReservesFrame.HeaderRoll:SetShown(frame.Roll);
            frame.ReservesFrame.ReportRolls:SetShown(true);
            frame.ReservesFrame.ReportReserves:SetShown(false);
            frame.RequestRollButton.CancelIcon:SetShown(frame.Roll and not frame.Historical and self:IsRolling(frame.Item));

            local highest = LootReserve.Constants.RollType.NotRolled;
            if frame.Roll then
                for player, rolls in pairs(frame.Roll.Players) do
                    for _, roll in ipairs(rolls) do
                        if highest < roll then
                            highest = roll;
                        end
                    end
                end
            end

            local alreadyHighlighted = { };
            for _, button in ipairs(frame.ReservesFrame.Players) do
                if button:IsShown() then
                    if frame.Roll and frame.Roll.Players[button.Player] and frame.Roll.Players[button.Player][button.RollNumber] then
                        local roll = frame.Roll.Players[button.Player][button.RollNumber];
                        local rolled = roll > LootReserve.Constants.RollType.NotRolled;
                        local passed = roll == LootReserve.Constants.RollType.Passed;
                        local deleted = roll == LootReserve.Constants.RollType.Deleted;
                        local rollText = tostring(roll);
                        if rolled and frame.Roll.Tiered then
                            local roll, max = self:ConvertFromTieredRoll(roll);
                            rollText = format("%d/%d", roll, max);
                        end
                        local winner;
                        if frame.Roll.Winners then
                            if LootReserve:Contains(frame.Roll.Winners, button.Player) and not alreadyHighlighted[button.Player] then
                                winner = true;
                                alreadyHighlighted[button.Player] = true;
                            end
                        elseif not frame.Historical then
                            winner = rolled and highest > LootReserve.Constants.RollType.NotRolled and roll == highest;
                        end

                        local color = winner and GREEN_FONT_COLOR or passed and GRAY_FONT_COLOR or deleted and RED_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
                        button.Roll:Show();
                        button.Roll:SetText(rolled and rollText or passed and "PASS" or deleted and "DEL" or "...");
                        button.Roll:SetTextColor(color.r, color.g, color.b);
                        if not frame.Historical then
                            button.RedHighlight:Hide();
                            button.RedHighlight.text = nil;
                            
                            if LootReserve.Server:HasAlreadyWon(button.Player, frame.Item:GetID()) then
                                button.RedHighlight.title = "Already won";
                                button.RedHighlight.text  = {format("%s has already won %s this session.", LootReserve:ColoredPlayer(button.Player), frame.Item:GetLink())};
                                button.RedHighlight:Show();
                            end
                            if (LootReserve.Server.CurrentSession and LootReserve.Server.CurrentSession.Settings or LootReserve.Server.NewSessionSettings).Equip then
                                local playerClass = select(2, LootReserve:UnitClass(button.Player))
                                if playerClass and not LootReserve.ItemConditions:IsItemUsable(frame.Item:GetID(), playerClass) then
                                    local text = format("%s cannot use %s", LootReserve:ColoredPlayer(button.Player), frame.Item:GetLink());
                                    button.RedHighlight.title = "Warning";
                                    if not button.RedHighlight.text then
                                        button.RedHighlight.title = "Unusable item";
                                        button.RedHighlight.text = { };
                                    end
                                    table.insert(button.RedHighlight.text, format("%s cannot use %s.", LootReserve:ColoredPlayer(button.Player), frame.Item:GetLink()));
                                    button.RedHighlight:Show();
                                end
                            end
                            button.GreenHighlight:Hide();
                        else
                            button.RedHighlight:Hide();
                            button.GreenHighlight:SetShown(winner);
                        end
                    else
                        button.Roll:Hide();
                        button.RedHighlight:Hide();
                        button.GreenHighlight:Hide();
                    end
                end
            end
        end
    end

    self:UpdateRollListButtons(lockdown);
end

function LootReserve.Server:UpdateRollListButtons(lockdown)
    if not self.Window:IsShown() then return; end

    lockdown = lockdown or InCombatLockdown() or not self.Settings.UseUnitFrames;

    local list = (lockdown and self.Window.PanelRollsLockdown or self.Window.PanelRolls).Scroll.Container;
    list.Frames = list.Frames or { };

    for _, frame in ipairs(list.Frames) do
        if frame:IsShown() and frame.ReservesFrame then
            for _, button in ipairs(frame.ReservesFrame.Players) do
                if button:IsShown() then
                    button.Name.WonRolls:SetShown(self.CurrentSession and self.CurrentSession.Members[button.Player] and self.CurrentSession.Members[button.Player].WonRolls);
                    button.Name.RecentChat:SetShown(frame.Roll and self:HasRelevantRecentChat(frame.Roll, button.Player));
                end
            end
        end
    end
end

function LootReserve.Server:UpdateRollList(lockdown)
    self:UpdateTradeFrameAutoButton();
    if not self.Window:IsShown() then return; end

    lockdown = lockdown or InCombatLockdown() or not self.Settings.UseUnitFrames;

    local filter = LootReserve.ItemCache:FormatSearchText(self.Window.Searchbar:GetText());
    if #filter < 3 and not tonumber(filter) then
        filter = nil;
    end

    local list = (lockdown and self.Window.PanelRollsLockdown or self.Window.PanelRolls).Scroll.Container;
    list.Frames = list.Frames or { };
    list.LastIndex = 0;
    list.ContentHeight = 0;

    if not list.HistoryHeader then
        list.HistoryHeader = CreateFrame("Frame", nil, list, "LootReserveRollHistoryHeader");
    end
    list.HistoryHeader:Hide();
    local historicalDisplayed = 0;
    local firstHistoricalHidden = true;
    if not list.HistoryShowMore then
        list.HistoryShowMore = CreateFrame("Frame", nil, list, "LootReserveRollHistoryShowMore");
    end
    list.HistoryShowMore:Hide();
    
    local function createFrame(item, roll, historical)
        if historical then
            historicalDisplayed = historicalDisplayed + 1;
            if historicalDisplayed > self.RollHistoryDisplayLimit then
                if firstHistoricalHidden then
                    firstHistoricalHidden = false;
                    list.HistoryShowMore.Button:SetText(format("Show %d more", self.Settings.RollHistoryDisplayLimit));
                    list.HistoryShowMore:Show();
                    list.HistoryShowMore:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -list.ContentHeight);
                    list.HistoryShowMore:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, -list.ContentHeight);
                    list.ContentHeight = list.ContentHeight + list.HistoryShowMore:GetHeight();
                end
                return;
            end
        end

        list.LastIndex = list.LastIndex + 1;
        local frame = list.Frames[list.LastIndex];
        while not frame do
            frame = CreateFrame("Frame", nil, list, item and "LootReserveReserveListTemplate" or "LootReserveRollPlaceholderTemplate");
            table.insert(list.Frames, frame);
            frame = list.Frames[list.LastIndex];
        end

        frame:Show();

        if item and roll then
            frame.Item = item;

            local name, link, texture = item:GetNameLinkTexture();
            frame.Link = link;
            frame.Historical = historical;
            frame.Roll = roll;

            frame:SetBackdropBorderColor(historical and 0.25 or 1, historical and 0.25 or 1, historical and 0.25 or 1);
            frame.RequestRollButton:SetShown(not historical or not self.RequestedRoll);
            frame.RequestRollButton:SetWidth(frame.RequestRollButton:IsShown() and 32 or 0.00001);
            frame.ItemFrame.Icon:SetTexture(texture);
            frame.ItemFrame.Name:SetText((link or name or "|cFFFF4000Loading...|r"):gsub("[%[%]]", ""));
            
            local tradeableItemCount = LootReserve:GetTradeableItemCount(item);
            frame.DistributeButton:SetShown(historical);
            local lootable = LootReserve:IsLootingItem(item);
            local tradeable = tradeableItemCount > 0;
            
            if roll.Owed then
                local player = roll.Winners[1];
                frame.DistributeButton:SetShown(true);
                frame.DistributeButton.LibCustomGlow = LibCustomGlow;
                frame.DistributeButton.Glow          = frame.ItemFrame.IconGlow;
                frame.DistributeButton.Player        = player;
                frame.DistributeButton.Lootable      = lootable;
                frame.DistributeButton.Tradeable     = tradeable;
                
                local unit = LootReserve:GetGroupUnitID(player);
                if not unit and UnitExists("target") and UnitIsPlayer("target") and LootReserve:Player(UnitName("target")) == player then
                    unit = "target";
                end
                frame.DistributeButton.Unit = unit;
            else
                frame.DistributeButton:SetShown(false);
                if LibCustomGlow then
                    LibCustomGlow.ButtonGlow_Stop(frame.ItemFrame.IconGlow)
                end
            end
            
            if historical then
                if not roll.StartTime then
                    frame.ItemFrame.Misc:SetText("");
                elseif self.Settings.Use24HourTime then
                    frame.ItemFrame.Misc:SetText(date(format("%%B%s%%e  %%H:%%M", date("*t", roll.StartTime).day < 10 and "" or " "), roll.StartTime));
                else
                    local hour = date("%I", roll.StartTime);
                    hour = hour:match("^0(%d)$") or hour;
                    frame.ItemFrame.Misc:SetText(date(format("%%B%s%%e  %s:%%M %%p", date("*t", roll.StartTime).day < 10 and "" or " ", hour), roll.StartTime));
                end
                
            elseif tradeableItemCount < 1 and not LootReserve:IsLootingItem(item) then
                frame.ItemFrame.Misc:SetText("|cFFFF0000Cannot distribute|r");
            else
                local token;
                if not self.ReservableIDs[item:GetID()] and self.ReservableRewardIDs[item:GetID()] then
                    token = LootReserve.ItemCache:Item(LootReserve.Data:GetToken(item:GetID())) or LootReserve.ItemCache:Item(LootReserve.Data:GetToken(item:GetID()));
                end
                local reservers = 0;
                if LootReserve.Server.CurrentSession then
                    if self.CurrentSession.ItemReserves[token and token:GetID() or item:GetID()] then
                        local _, _, uniquePlayers = LootReserve:GetReservesData(self.CurrentSession.ItemReserves[token and token:GetID() or item:GetID()].Players);
                        reservers = uniquePlayers;
                    end
                end
                frame.ItemFrame.Misc:SetText(reservers > 0 and format("Reserved by %d |4player:players;", reservers) or "Not reserved");
            end

            frame.DurationFrame:SetShown(not historical and self:IsRolling(frame.Item) and self.RequestedRoll.MaxDuration);
            frame.DurationFrame:SetHeight(frame.DurationFrame:IsShown() and 12 or 0.00001);

            local reservesHeight = 5 + 12 + 2;
            local last = 0;
            frame.ReservesFrame.Players = frame.ReservesFrame.Players or { };

            local highest = LootReserve.Constants.RollType.NotRolled;
            for player, roll, rollIndex in LootReserve.Server:GetOrderedPlayerRolls(roll.Players) do
                if highest < roll then
                    highest = roll;
                end
                last = last + 1;
                if last > #frame.ReservesFrame.Players then
                    local button = CreateFrame("Button", nil, frame.ReservesFrame, lockdown and "LootReserveReserveListPlayerTemplate" or "LootReserveReserveListPlayerSecureTemplate");
                    table.insert(frame.ReservesFrame.Players, button);
                end
                local unit = LootReserve:GetGroupUnitID(player);
                local button = frame.ReservesFrame.Players[last];
                if button.init then button:init(); end
                button:Show();
                button.Player = player;
                button.RollNumber = rollIndex;
                button.Unit = unit;
                if not lockdown then
                    button:SetAttribute("unit", unit);
                end
                button.Name:SetText(format("%s%s", LootReserve:ColoredPlayer(player), historical and "" or LootReserve:IsPlayerOnline(player) == nil and "|cFF808080 (not in raid)|r" or LootReserve:IsPlayerOnline(player) == false and "|cFF808080 (offline)|r" or ""));
                button.Roll:SetText("");
                button.RedHighlight:Hide();
                button.GreenHighlight:Hide();
                button:SetPoint("TOPLEFT", frame.ReservesFrame, "TOPLEFT", 0, 5 - reservesHeight);
                button:SetPoint("TOPRIGHT", frame.ReservesFrame, "TOPRIGHT", 0, 5 - reservesHeight);
                reservesHeight = reservesHeight + button:GetHeight();
            end
            for i = last + 1, #frame.ReservesFrame.Players do
                local button = frame.ReservesFrame.Players[i];
                button:Hide();
                if not lockdown then
                    button:SetAttribute("unit", nil);
                end
            end

            local phase = roll.Phases and roll.Phases[1];
            if roll.Tiered then
                local rollNumber, max = self:ConvertFromTieredRoll(highest);
                phase = roll.Phases and roll.Phases[101-max];
            end
            frame.ReservesFrame.HeaderPlayer:SetText(roll.RaidRoll and "Raid-rolled to" or roll.Disenchant and "Disenchanted" or roll.Custom and format("Rolled%s by", phase and format(" for |cFF00FF00%s|r", phase or "") or "") or "Reserved by");
            frame.ReservesFrame.NoRollsPlaceholder:SetShown(last == 0);
            if frame.ReservesFrame.NoRollsPlaceholder:IsShown() then
                reservesHeight = reservesHeight + 16;
            end
            
            if frame.DistributeButton:IsShown() then
                frame:SetHeight(6 + 32 + 2 + 20 + 5 + reservesHeight - 1);
                frame.ReservesFrame:SetPoint("TOP", frame.DistributeButton, "BOTTOM", 0, -5);
            elseif frame.DurationFrame:IsShown() then
                frame:SetHeight(6 + 32 + 12 + 5 + reservesHeight - 1);
                frame.ReservesFrame:SetPoint("TOP", frame.DurationFrame, "BOTTOM", 0, -5);
            else
                frame:SetHeight(6 + 32 + 5 + reservesHeight - 1);
                frame.ReservesFrame:SetPoint("TOP", frame.ItemFrame, "BOTTOM", 0, -5);
            end
        else
            frame:SetShown(not self.RequestedRoll);
            frame:SetHeight(frame:IsShown() and 44 or 0.00001);
        end

        frame:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -list.ContentHeight);
        frame:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, -list.ContentHeight);
        list.ContentHeight = list.ContentHeight + frame:GetHeight();
        
    end

    local function matchesFilter(item, roll, filter)
        if #filter == 0 then
            return true;
        end

        if item:GetID() == tonumber(filter) then
            return true;
        end
        if string.find(item:GetSearchName(), filter, 1, true) then
            return true;
        end
        
        if roll then
            for player in pairs(roll.Players) do
                if string.find(LootReserve:SimplifyNameLower(player), filter, 1, true) then
                    return true;
                end
            end
        end

        return false;
    end

    createFrame();
    if self.RequestedRoll then
        --if not filter or matchesFilter(self.RequestedRoll.Item, self.RequestedRoll, filter) then
            createFrame(self.RequestedRoll.Item, self.RequestedRoll, false);
        --end
    end
    list.HistoryHeader:Show();
    list.HistoryHeader:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -list.ContentHeight);
    list.HistoryHeader:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, -list.ContentHeight);
    list.ContentHeight = list.ContentHeight + list.HistoryHeader:GetHeight();
    
    local missing = { };
    local itemsVisible = 0;
    for i = #self.RollHistory, 1, -1 do
        if itemsVisible > self.RollHistoryDisplayLimit then
            break;
        end
        local match = false;
        local roll = self.RollHistory[i];
        local item = roll.Item;
        if self.Settings.RollHistoryHideEmpty and next(roll.Players) == nil or self.Settings.RollHistoryHideNotOwed and not roll.Owed then
            match = true;
        elseif item:IsCached() then
            if not filter or matchesFilter(item, roll, filter) then
                createFrame(item, roll, true);
                itemsVisible = itemsVisible + 1;
                match = true;
            end
        elseif item:Exists() then
            table.insert(missing, item);
        end
        if filter and not match and LootReserve.Data:IsTokenReward(roll.Item:GetID()) then
            local token = LootReserve.ItemCache:Item(LootReserve.Data:GetToken(roll.Item:GetID()));
            if token:IsCached() then
                if item:IsCached() and matchesFilter(token, nil, filter) then
                    createFrame(item, roll, true);
                    match = true;
                end
            elseif token:Exists() then
                table.insert(missing, token);
            end
        end
        if filter and not match and LootReserve.Data:IsToken(roll.Item:GetID()) then
            for _, rewardID in ipairs(LootReserve.Data:GetTokenRewards(roll.Item:GetID())) do
                local reward = LootReserve.ItemCache:Item(rewardID);
                if reward:IsCached() then
                    if item:IsCached() and matchesFilter(reward, nil, filter) then
                        createFrame(item, roll, true);
                        itemsVisible = itemsVisible + 1;
                        break;
                    end
                elseif reward:Exists() then
                    table.insert(missing, reward);
                end
            end
        end
    end
    for i = list.LastIndex + 1, #list.Frames do
        local frame = list.Frames[i];
        if frame then
            frame:Hide();
            if not lockdown then
                for _, button in ipairs(frame.ReservesFrame.Players) do
                    button:SetAttribute("unit", nil);
                end
            end
        end
    end
    if #missing > 0 then
        if #missing > LootReserve.ItemSearch.BatchCap then
            for i = LootReserve.ItemSearch.BatchCap + 1, #missing do
                missing[i] = nil;
            end
        end
        if not self.PendingRollListUpdate or self.PendingRollListUpdate:IsComplete() then
            self.PendingRollListUpdate = LootReserve.ItemCache:OnCache(missing, function()
                self:UpdateRollList();
            end);
        end
        self.PendingRollListUpdate:SetSpeed(math.ceil(#missing/LootReserve.ItemSearch.BatchFrames));
    end

    list:GetParent():UpdateScrollChildRect();

    self:UpdateRollListRolls(lockdown);
end

function LootReserve.Server:OnWindowTabClick(tab)
    PanelTemplates_Tab_OnClick(tab, self.Window);
    PanelTemplates_SetTab(self.Window, tab:GetID());
    self:SetWindowTab(tab:GetID());
    CloseMenus();
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
end

function LootReserve.Server:SetWindowTab(tab, lockdown)
    lockdown = lockdown or InCombatLockdown() or not self.Settings.UseUnitFrames;

    self.RollHistoryDisplayLimit = self.Settings.RollHistoryDisplayLimit;
    if tab == 1 then
        self.Window.InsetBg:SetPoint("TOPLEFT", self.Window, "TOPLEFT", 4, -24);
        self.Window.Duration:Hide();
        self.Window.Searchbar:Hide();
        self.Window.ButtonMenu:Hide();
    elseif tab == 2 then
        self.Window.InsetBg:SetPoint("TOPLEFT", self.Window.Searchbar, "BOTTOMLEFT", -6, 0);
        self.Window.Duration:SetShown(self.CurrentSession and self.CurrentSession.AcceptingReserves and self.CurrentSession.Duration ~= 0 and self.CurrentSession.Settings.Duration ~= 0);
        self.Window.Searchbar:Show();
        self.Window.ButtonMenu:Show();
        if self.Window.Duration:IsShown() then
            self.Window.Searchbar:SetPoint("TOPLEFT", self.Window.Duration, "BOTTOMLEFT", 3, -3);
            self.Window.Searchbar:SetPoint("TOPRIGHT", self.Window.Duration, "BOTTOMRIGHT", 3 - 80, -3);
            (lockdown and self.Window.PanelReservesLockdown or self.Window.PanelReserves):SetPoint("TOPLEFT", self.Window, "TOPLEFT", 7, -61);
        else
            self.Window.Searchbar:SetPoint("TOPLEFT", self.Window, "TOPLEFT", 10, -25);
            self.Window.Searchbar:SetPoint("TOPRIGHT", self.Window, "TOPRIGHT", -7 - 80, -25);
            (lockdown and self.Window.PanelReservesLockdown or self.Window.PanelReserves):SetPoint("TOPLEFT", self.Window, "TOPLEFT", 7, -48);
        end
    elseif tab == 3 then
        self.Window.InsetBg:SetPoint("TOPLEFT", self.Window.Searchbar, "BOTTOMLEFT", -6, 0);
        self.Window.Duration:Hide();
        self.Window.Searchbar:Show();
        self.Window.ButtonMenu:Hide();
        self.Window.Searchbar:SetPoint("TOPLEFT", self.Window, "TOPLEFT", 10, -25);
        self.Window.Searchbar:SetPoint("TOPRIGHT", self.Window, "TOPRIGHT", -7, -25);
        (lockdown and self.Window.PanelRollsLockdown or self.Window.PanelRolls):SetPoint("TOPLEFT", self.Window, "TOPLEFT", 7, -48);
        self.RollHistoryKeepLimit = self.Settings.RollHistoryKeepLimit;
    end

    for i, panel in ipairs(self.Window.Panels) do
        if panel.Lockdown then
            if lockdown then
                if panel:IsShown() then
                    panel:Hide();
                end
                panel = panel.Lockdown;
            else
                panel.Lockdown:Hide();
            end
        end
        panel:SetShown(i == tab);
    end
    self:UpdateServerAuthority();
end

function LootReserve.Server:RefreshWindowTab(lockdown)
    for i, panel in ipairs(self.Window.Panels) do
        if panel:IsShown() or panel.Lockdown and panel.Lockdown:IsShown() then
            self:SetWindowTab(i, lockdown or InCombatLockdown() or not self.Settings.UseUnitFrames);
            return;
        end
    end
end

function LootReserve.Server:OnWindowLoad(window)
    self.Window = window;
    self.Window.TopLeftCorner:SetSize(32, 32); -- Blizzard UI bug?
    self.Window.TitleText:SetPoint("TOP", self.Window, "TOP", 0, -4);
    self.Window.TitleText:SetText("LootReserve Host");
    LootReserve:SetResizeBounds(self.Window, 230, 365);
    self.Window.PanelSession.LabelDuration:SetPoint("RIGHT", self.Window.PanelSession.DropDownDuration.Text, "LEFT", -16, 0);
    self.Window.PanelSession.DropDownDuration:SetPoint("CENTER", self.Window.PanelSession.Duration, "CENTER", (6 + self.Window.PanelSession.LabelDuration:GetStringWidth()) / 2, 0);
    PanelTemplates_SetNumTabs(self.Window, 3);
    PanelTemplates_SetTab(self.Window, 1);
    self:SetWindowTab(1);
    self:UpdateServerAuthority();
    self:LoadNewSessionSettings();

    LootReserve:RegisterEvent("GROUP_JOINED", "GROUP_LEFT", "PARTY_LEADER_CHANGED", "PARTY_LOOT_METHOD_CHANGED", "GROUP_ROSTER_UPDATE", function()
        self:UpdateServerAuthority();
        self:UpdateAddonUsers();
    end);
    function self.OnEnterCombat()
        -- Swap out the real (tainted) reserves and rolls panels for slightly less functional ones, but ones that don't have taint
        self:RefreshWindowTab(true);
        -- Sync changes between real and lockdown panels
        self:UpdateReserveList(true);
        self.Window.PanelReservesLockdown.Scroll:UpdateScrollChildRect();
        self.Window.PanelReservesLockdown.Scroll:SetVerticalScroll(self.Window.PanelReserves.Scroll:GetVerticalScroll());
        self:UpdateRollList(true);
        self.Window.PanelRollsLockdown.Scroll:UpdateScrollChildRect();
        self.Window.PanelRollsLockdown.Scroll:SetVerticalScroll(self.Window.PanelRolls.Scroll:GetVerticalScroll());
        local list = self.Window.PanelRolls.Scroll.Container;
        local listLockdown = self.Window.PanelRollsLockdown.Scroll.Container;
        if list and list.Frames and list.Frames[1] and listLockdown and listLockdown.Frames and listLockdown.Frames[1] then
            listLockdown.Frames[1]:SetItem(list.Frames[1].Item);
        end
    end
    function self.OnExitCombat()
        -- Restore original panels
        self:RefreshWindowTab();
        -- Sync changes between real and lockdown panels
        self:UpdateReserveList();
        self.Window.PanelReserves.Scroll:UpdateScrollChildRect();
        self.Window.PanelReserves.Scroll:SetVerticalScroll(self.Window.PanelReservesLockdown.Scroll:GetVerticalScroll());
        self:UpdateRollList();
        self.Window.PanelRolls.Scroll:UpdateScrollChildRect();
        self.Window.PanelRolls.Scroll:SetVerticalScroll(self.Window.PanelRollsLockdown.Scroll:GetVerticalScroll());
        local list = self.Window.PanelRolls.Scroll.Container;
        local listLockdown = self.Window.PanelRollsLockdown.Scroll.Container;
        if list and list.Frames and list.Frames[1] and listLockdown and listLockdown.Frames and listLockdown.Frames[1] then
            list.Frames[1]:SetItem(listLockdown.Frames[1].Item);
        end
    end
    LootReserve:RegisterEvent("PLAYER_REGEN_DISABLED", self.OnEnterCombat);
    LootReserve:RegisterEvent("PLAYER_REGEN_ENABLED", self.OnExitCombat);
    LootReserve:RegisterEvent("LOOT_READY", "LOOT_CLOSED", "LOOT_SLOT_CHANGED", "LOOT_SLOT_CLEARED", function()
        self:UpdateReserveList();
        self:UpdateRollList();
    end);
    LootReserve:RegisterEvent("TRADE_SHOW", "TRADE_CLOSED", "TRADE_PLAYER_ITEM_CHANGED", "TRADE_ACCEPT_UPDATE", "PLAYER_TARGET_CHANGED", "GROUP_JOINED", "GROUP_LEFT", "GROUP_ROSTER_UPDATE", function()
        LootReserve:WipeBagCache();
        LootReserve.Server:UpdateRollList();
    end);
    local tempBagFix;
    LootReserve:RegisterEvent("BAG_UPDATE", function() -- Return to hooking BAG_UPDATED_DELAYED when blizzard fixes it
        if not tempBagFix then
            tempBagFix = C_Timer.NewTicker(0, function()
                LootReserve:WipeBagCache();
                LootReserve.Server:UpdateRollList();
                tempBagFix = nil;
            end, 1);
        end
    end);
end

local activeSessionChanges =
{
    ButtonStartSession  = "Hide",
    ButtonStartReserves = "Show",
    ButtonStopReserves  = "Show",
    ButtonResetSession  = "Hide",
    LabelRaid           = "Label",
    DropDownRaid        = "DropDown",
    LabelCount          = "Label",
    EditBoxCount        = "Disable",
    LabelMultireserve   = "Label",
    EditBoxMultireserve = "Disable",
    LabelDuration       = "Hide",
    DropDownDuration    = "Hide",
    ButtonLootEdit      = "Disable",
    CheckButtonEquip    = "Checkbox",

    Apply = function(self, panel, active)
        for k, action in pairs(self) do
            local region = panel[k];
            if action == "Hide" then
                region:SetShown(not active);
            elseif action == "Show" then
                region:SetShown(active);
            elseif action == "DropDown" then
                if active then
                    LootReserve.LibDD:UIDropDownMenu_DisableDropDown(region);
                else
                    LootReserve.LibDD:UIDropDownMenu_EnableDropDown(region);
                end
            elseif action == "Disable" then
                region:SetEnabled(not active);
            elseif action == "Checkbox" then
                region:SetEnabled(not active);
                region:SetAlpha(active and 0.5 or 1);
            elseif action == "Label" then
                local color = active and GRAY_FONT_COLOR or NORMAL_FONT_COLOR;
                region:SetTextColor(color.r, color.g, color.b);
            end
        end
    end
};

function LootReserve.Server:SessionStarted()
    activeSessionChanges:Apply(self.Window.PanelSession, true);
    self:LoadNewSessionSettings();
    self.Window.PanelSession.CheckButtonEquip:SetChecked(self.CurrentSession.Settings.Equip);
    self.Window.PanelSession.CheckButtonBlind:SetChecked(self.CurrentSession.Settings.Blind);
    self.Window.PanelSession.CheckButtonLock:SetChecked(self.CurrentSession.Settings.Lock);
    self.Window.PanelSession.Duration:SetShown(self.CurrentSession.Settings.Duration ~= 0);
    self.Window.PanelSession.ButtonStartSession:Hide();
    self.Window.PanelSession.ButtonStartReserves:Hide();
    self.Window.PanelSession.ButtonStopReserves:Show();
    self.Window.PanelSession.ButtonResetSession:Hide();
    self:UpdateServerAuthority();
    self:UpdateRollList();
    self.LootEdit.Window:Hide();
    self.Import.Window:Hide();
end

function LootReserve.Server:SessionStopped()
    activeSessionChanges:Apply(self.Window.PanelSession, true);
    self:LoadNewSessionSettings();
    self.Window.PanelSession.CheckButtonEquip:SetChecked(self.CurrentSession.Settings.Equip);
    self.Window.PanelSession.CheckButtonBlind:SetChecked(self.CurrentSession.Settings.Blind);
    self.Window.PanelSession.CheckButtonLock:SetChecked(self.CurrentSession.Settings.Lock);
    self.Window.PanelSession.Duration:SetShown(self.CurrentSession.Settings.Duration ~= 0);
    self.Window.PanelSession.ButtonStartSession:Hide();
    self.Window.PanelSession.ButtonStartReserves:Show();
    self.Window.PanelSession.ButtonStopReserves:Hide();
    self.Window.PanelSession.ButtonResetSession:Show();
    self:RefreshWindowTab();
    self:UpdateServerAuthority();
    self:UpdateRollList();
    self.LootEdit.Window:Hide();
    self.Import.Window:Hide();
end

function LootReserve.Server:SessionReset()
    activeSessionChanges:Apply(self.Window.PanelSession, false);
    self:LoadNewSessionSettings();
    self.Window.PanelSession.CheckButtonEquip:SetChecked(self.NewSessionSettings.Equip);
    self.Window.PanelSession.CheckButtonBlind:SetChecked(self.NewSessionSettings.Blind);
    self.Window.PanelSession.CheckButtonLock:SetChecked(self.NewSessionSettings.Lock);
    self.Window.PanelSession.Duration:Hide();
    self.Window.PanelSession.ButtonStartSession:Show();
    self.Window.PanelSession.ButtonStartReserves:Hide();
    self.Window.PanelSession.ButtonStopReserves:Hide();
    self.Window.PanelSession.ButtonResetSession:Hide();
    self:UpdateServerAuthority();
    self:UpdateRollList();
end

function LootReserve.Server:RollEnded()
    if L_UIDROPDOWNMENU_OPEN_MENU then
        for _, panel in ipairs({ "PanelReserves", "PanelReservesLockdown", "PanelRolls", "PanelRollsLockdown" }) do
            local list = self.Window[panel].Scroll.Container;
            if list and list.Frames then
                for _, frame in ipairs(list.Frames) do
                    if L_UIDROPDOWNMENU_OPEN_MENU == frame.Menu then
                        CloseMenus();
                        return;
                    end
                end
            end
        end
    end
end

function LootReserve.Server:UpdateServerAuthority()
    local hasAuthority = self:CanBeServer();
    self.Window.PanelSession.ButtonStartSession:SetEnabled(hasAuthority);
    self.Window.PanelSession:SetAlpha((hasAuthority or self.CurrentSession and not self.StartupAwaitingAuthority) and 1 or 0.15);
    self.Window.NoAuthority:SetShown(not hasAuthority and not self.CurrentSession and self.Window.PanelSession:IsShown());
    self.Window.AwaitingAuthority:SetShown(not hasAuthority and self.CurrentSession and self.Window.PanelSession:IsShown() and self.StartupAwaitingAuthority);
end

function LootReserve.Server:UpdateAddonUsers()
    if GameTooltip:IsOwned(self.Window.PanelSession.AddonUsers) then
        self.Window.PanelSession.AddonUsers:UpdateTooltip();
    end
    local count = 0;
    for player, compatible in pairs(self.AddonUsers) do
        if compatible and LootReserve:UnitInGroup(player) then
            count = count + 1;
        end
    end
    self.Window.PanelSession.AddonUsers.Text:SetText(format("%d/%d", count, LootReserve:GetNumGroupMembers()));
    self.Window.PanelSession.AddonUsers:SetShown(LootReserve:GetNumGroupMembers() > 1);
end

function LootReserve.Server:LoadNewSessionSettings()
    if not self.Window:IsShown() then return; end

    local function setDropDownValue(dropDown, value)
        if dropDown.init then dropDown:init(); end
        LootReserve.LibDD:ToggleDropDownMenu(nil, nil, dropDown);
        LootReserve.LibDD:UIDropDownMenu_SetSelectedValue(dropDown, value);
        CloseMenus();
    end

    setDropDownValue(self.Window.PanelSession.DropDownRaid, 1);
    self.Window.PanelSession.DropDownRaid:UpdateText();
    self.Window.PanelSession.EditBoxCount:SetText(tostring(self.NewSessionSettings.MaxReservesPerPlayer));
    self.Window.PanelSession.EditBoxMultireserve:SetText(self.NewSessionSettings.Multireserve);
    setDropDownValue(self.Window.PanelSession.DropDownDuration, self.NewSessionSettings.Duration);
    if self.CurrentSession then
        self.Window.PanelSession.CheckButtonEquip:SetChecked(self.CurrentSession.Settings.Equip);
        self.Window.PanelSession.CheckButtonBlind:SetChecked(self.CurrentSession.Settings.Blind);
        self.Window.PanelSession.CheckButtonLock:SetChecked(self.CurrentSession.Settings.Lock);
    else
        self.Window.PanelSession.CheckButtonEquip:SetChecked(self.NewSessionSettings.Equip);
        self.Window.PanelSession.CheckButtonBlind:SetChecked(self.NewSessionSettings.Blind);
        self.Window.PanelSession.CheckButtonLock:SetChecked(self.NewSessionSettings.Lock);
    end
end
