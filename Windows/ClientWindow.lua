function LootReserve.Client:UpdateReserveStatus()
    if not LootReserve.Enabled then
        self.Window.RemainingText:SetText("|cFFFF0000LootReserve is out of date|r");
        self.Window.RemainingTextGlow:SetVertexColor(1, 1, 1, 0.15);
        self.Window.OptOut:SetShown(false);
        self.Window.OptIn:SetShown(false);
    elseif not self.SessionServer then
        self.Window.RemainingText:SetText("|cFF808080Loot reserves are not started in your raid|r");
        self.Window.RemainingTextGlow:SetVertexColor(1, 1, 1, 0.15);
        self.Window.OptOut:SetShown(false);
        self.Window.OptIn:SetShown(false);
    elseif not self.AcceptingReserves then
        self.Window.RemainingText:SetText("|cFF808080Loot reserves are not currently being accepted|r");
        --self.Window.RemainingTextGlow:SetVertexColor(1, 0, 0, 0.15);
        -- animated in LootReserve.Client:OnWindowLoad instead
        self.Window.OptOut:SetShown(false);
        self.Window.OptIn:SetShown(false);
    elseif self.Locked then
        self.Window.RemainingText:SetText("|cFF808080You are locked-in and cannot change your reserves|r");
        --self.Window.RemainingTextGlow:SetVertexColor(1, 0, 0, 0.15);
        -- animated in LootReserve.Client:OnWindowLoad instead
        self.Window.OptOut:SetShown(false);
        self.Window.OptIn:SetShown(false);
    else
        local reservesLeft = LootReserve.Client:GetRemainingReserves();
        local maxReserves = self:GetMaxReserves();
        self.Window.RemainingText:SetText(format("%s %s|cFF%s %d%s|r item |4reserve:reserves; %s", 
            self.Masquerade and LootReserve:ColoredPlayer(self.Masquerade) or "You",
            self.Masquerade and "has" or "have",
            reservesLeft > 0 and (reservesLeft < maxReserves and "FF7700" or "00FF00") or "FF0000",
            reservesLeft,
            reservesLeft < maxReserves and format("/%d", maxReserves) or "",
            reservesLeft < maxReserves and "remaining" or "in total"
        ));
        --self.Window.RemainingTextGlow:SetVertexColor(reservesLeft > 0 and 0 or 1, reservesLeft > 0 and 1 or 0, 0);
        --local r, g, b = self.Window.Duration:GetStatusBarColor();
        --self.Window.RemainingTextGlow:SetVertexColor(r, g, b, 0.15);
        -- animated in LootReserve.Client:OnWindowLoad instead
        self.Window.OptOut:SetShown(not self.OptedOut);
        self.Window.OptIn:SetShown(self.OptedOut);
    end
    self.Window.MasqueradeHelperText:SetShown(self.SessionServer and LootReserve:IsMe(self.SessionServer));
    self.Window.Masquerade:SetShown(self.SessionServer and LootReserve:IsMe(self.SessionServer));
    self.Window.Masquerade.Text:SetText(LootReserve:ColoredPlayer(self.Masquerade or LootReserve:Me()));
    self.Window.Masquerade:SetWidth(math.max(100, self.Window.Masquerade.Text:GetUnboundedStringWidth() + self.Window.Masquerade.Icon:GetWidth()*4));

    self.Window.OptOut:SetEnabled(not self:IsOptPending());
    self.Window.OptIn:SetEnabled(not self:IsOptPending());
    

    local list = self.Window.Loot.Scroll.Container;
    list.Frames = list.Frames or { };

    for i, frame in ipairs(list.Frames) do
        local item = frame.Item;
        local tokenID = LootReserve.Data:GetToken(item:GetID());
        if tokenID then
            if not (LootReserve.Client.SessionServer and not LootReserve.Client.ReservableIDs[tokenID]) then
                item = LootReserve.ItemCache:Item(tokenID);
            end
        end
        if item:GetID() ~= 0 then
            local _, myReserves, uniquePlayers, totalReserves = LootReserve:GetReservesData(self:GetItemReservers(item:GetID()), self.Masquerade or LootReserve:Me());
            local canReserve = self.SessionServer and self:HasRemainingReserves() and LootReserve.ItemConditions:IsItemReservableOnClient(item:GetID()) and (not self.Multireserve or myReserves < self.Multireserve);
            frame.ReserveFrame.ReserveButton:SetShown(canReserve and myReserves == 0);
            frame.ReserveFrame.MultiReserveButton:SetShown(canReserve and myReserves > 0);
            frame.ReserveFrame.MultiReserveButton:SetText(format("x%d", myReserves + 1));
            frame.ReserveFrame.CancelReserveButton:SetShown(self.SessionServer and self:IsItemReservedByMe(item:GetID()) and self.AcceptingReserves);
            frame.ReserveFrame.CancelReserveButton:SetWidth(frame.ReserveFrame.ReserveButton:GetWidth() - (frame.ReserveFrame.MultiReserveButton:IsShown() and frame.ReserveFrame.MultiReserveButton:GetWidth() - select(4, frame.ReserveFrame.MultiReserveButton:GetPoint(1)) or 0));
            frame.ReserveFrame.ReserveIcon.One:Hide();
            frame.ReserveFrame.ReserveIcon.Many:Hide();
            frame.ReserveFrame.ReserveIcon.Number:Hide();
            frame.ReserveFrame.ReserveIcon.NumberLimit:Hide();
            frame.ReserveFrame.ReserveIcon.NumberMany:Hide();
            frame.ReserveFrame.ReserveIcon.NumberMulti:Hide();

            local pending = self:IsItemPending(item:GetID());
            frame.ReserveFrame.ReserveButton:SetEnabled(not pending and not self.Locked);
            frame.ReserveFrame.MultiReserveButton:SetEnabled(not pending and not self.Locked);
            frame.ReserveFrame.CancelReserveButton:SetEnabled(not pending and not self.Locked);

            if self.SessionServer then
                local conditions = self.ItemConditions[item:GetID()];
                local numberString;
                if conditions and conditions.Limit and conditions.Limit ~= 0 then
                    numberString = format(totalReserves >= conditions.Limit and "|cFFFF0000%d/%d|r" or "%d/%d", totalReserves, conditions.Limit);
                else
                    numberString = tostring(totalReserves);
                end

                if myReserves > 0 then
                    if uniquePlayers == 1 and not self.Blind then
                        frame.ReserveFrame.ReserveIcon.One:Show();
                    else
                        frame.ReserveFrame.ReserveIcon.Many:Show();
                        if not self.Blind then
                            frame.ReserveFrame.ReserveIcon.NumberMany:SetText(numberString);
                            frame.ReserveFrame.ReserveIcon.NumberMany:Show();
                        end
                    end
                    if myReserves > 1 then
                        frame.ReserveFrame.ReserveIcon.NumberMulti:SetText(format("x%d", myReserves));
                        frame.ReserveFrame.ReserveIcon.NumberMulti:Show();
                    end
                else
                    if conditions and conditions.Limit and conditions.Limit ~= 0 then
                        frame.ReserveFrame.ReserveIcon.NumberLimit:SetText(numberString);
                        frame.ReserveFrame.ReserveIcon.NumberLimit:Show();
                    elseif totalReserves > 0 then
                        frame.ReserveFrame.ReserveIcon.Number:SetText(numberString);
                        frame.ReserveFrame.ReserveIcon.Number:Show();
                    end
                end
            end
        end
    end
end

function LootReserve.Client:UpdateLootList()
    local filter = LootReserve.ItemCache:FormatSearchText(self.Window.Searchbar:GetText());
    if #filter < 3 and not tonumber(filter) then
        filter = nil;
    end

    local list = self.Window.Loot.Scroll.Container;
    list.Frames = list.Frames or { };
    list.LastIndex = 0;
    list.ContentHeight = 0;

    if list.CharacterFavoritesHeader then
        list.CharacterFavoritesHeader:Hide();
    end
    if list.GlobalFavoritesHeader then
        list.GlobalFavoritesHeader:Hide();
    end

    local missing     = { };
    local missingLoad = { };
    local function createFrame(item, source)
        if item:GetID() ~= 0 and not item:IsCached() then
            return;
        end
        
        list.LastIndex = list.LastIndex + 1;
        local frame = list.Frames[list.LastIndex];
        while not frame do
            frame = CreateFrame("Frame", nil, list, "LootReserveLootListTemplate");
            table.insert(list.Frames, frame);
            frame = list.Frames[list.LastIndex];
        end

        frame.Item = LootReserve.ItemCache:Item(item);

        if item:GetID() == 0 then
            if list.LastIndex <= 1 or not list.Frames[list.LastIndex - 1]:IsShown() then
                frame:SetHeight(0.00001);
                frame:Hide();
            else
                frame:SetHeight(32);
                frame:Hide();
            end
            frame.Favorite:Hide();
        else
            frame:SetHeight(44);
            frame:Show();

            local usable, usabilityCached = LootReserve.ItemConditions:IsItemUsableByMe(item:GetID());
            if not usabilityCached and item:Exists() then
                table.insert(missingLoad, item);
            end
            if source then
                source = format("%s%s", usable and "" or "|cFFFF2020", source);
            end
            local description = format("%s%s", usable and "" or "|cFFFF2020", LootReserve:GetItemDescription(item:GetID(), LootReserve.Data:IsHeroicMirror(item:GetID())) or "");
            local name, link, texture = item:GetNameLinkTexture();
            frame.Link = link;

            local tokenID = LootReserve.Data:GetToken(item:GetID());
            local conditions;
            if LootReserve.Client.SessionServer and not LootReserve.Client.ReservableIDs[tokenID] then
                conditions = self.ItemConditions[item:GetID()];
            else
                conditions = self.ItemConditions[tokenID];
            end
            if conditions and conditions.Limit and conditions.Limit ~= 0 then
                source = format("|cFFFF0000(Max %d |4reserve:reserves;) |r%s", conditions.Limit, source or description or "");
            end

            frame.ItemFrame.Icon:SetTexture(texture);
            frame.ItemFrame.Name:SetMaxLines(1);
            frame.ItemFrame.Name:SetText((link or name or "|cFFFF4000Loading...|r"):gsub("[%[%]]", ""));
            frame.ItemFrame.Misc:SetText(source or description);
            frame.Favorite:SetPoint("LEFT", frame.ItemFrame.Name, "LEFT", math.min(frame.ItemFrame:GetWidth() - 57, frame.ItemFrame.Name:GetStringWidth()), 0);
            frame.Favorite.Set:SetShown(not self:IsFavorite(item:GetID()));
            frame.Favorite.Unset:SetShown(not frame.Favorite.Set:IsShown());
            frame.Favorite:SetShown(frame.hovered or frame.Favorite.Unset:IsShown());
            frame.ItemFrame.Name:SetPoint("TOPRIGHT", frame.ItemFrame, "TOPRIGHT", frame.Favorite:IsShown() and -20 or 0, 0);
        end
        
        if frame:GetHeight() > 1 then
            frame:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -list.ContentHeight);
            frame:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, -list.ContentHeight);
            list.ContentHeight = list.ContentHeight + frame:GetHeight();
        else
            frame:ClearAllPoints();
        end
    end

    local function matchesFilter(item, reserve, filter, sourceCategory, sourceChild)
        filter = (filter or "");
        if #filter == 0 then
            return true;
        end

        if item:GetID() == tonumber(filter) then
            return true;
        end
        if item:GetSearchName():find(filter, 1, true) then
            return true;
        end
        if LootReserve.ItemCache:FormatSearchText(LootReserve:GetItemDescription(item:GetID(), true) or ""):find(filter, 1, true) then
            return true;
        end
        if sourceCategory and LootReserve.ItemCache:FormatSearchText(sourceCategory):find(filter, 1, true) then
            return true;
        end
        if sourceChild and LootReserve.ItemCache:FormatSearchText(sourceChild):find(filter, 1, true) then
            return true;
        end
        
        if reserve then
            for _, player in pairs(reserve) do
                if string.find(LootReserve:SimplifyNameLower(player), filter, 1, true) then
                    return true;
                end
            end
        end

        return false;
    end
    
    local function getSortingSourceHelper(item)
        local customIndex = 0;
        for itemID, conditions in pairs(self.ItemConditions) do
            if conditions.Custom then
                customIndex = customIndex + 1;
                if itemID == item:GetID() then
                    return customIndex;
                end
            end
        end
        for id, category in LootReserve:Ordered(LootReserve.Data.Categories, LootReserve.Data.CategorySorter) do
            if category.Children and (not self.SessionServer or LootReserve:Contains(self.LootCategories, id)) and LootReserve.Data:IsCategoryVisible(category) then
                for childIndex, child in ipairs(category.Children) do
                    if child.Loot then
                        for lootIndex, loot in ipairs(child.Loot) do
                            if loot == item:GetID() then
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
    local function getSortingSource(item)
        if not sourceMemo[item] then
            sourceMemo[item] = getSortingSourceHelper(item);
        end
        return sourceMemo[item];
    end

    local function sortBySource(_, _, aItemID, bItemID)
        aItem = LootReserve.ItemCache:Item(aItemID);
        bItem = LootReserve.ItemCache:Item(bItemID);
        if not aItem or not aItem:GetInfo() then
            return false;
        end
        if not bItem or not bItem:GetInfo() then
            return false;
        end
        return getSortingSource(aItem) < getSortingSource(bItem);
    end

    -- local function sortByItemName(_, _, aItemID, bItemID)
    --     aItem = LootReserve.ItemCache:Item(aItemID);
    --     bItem = LootReserve.ItemCache:Item(bItemID);
    --     if not aItem or not aItem:GetInfo() then
    --         return false;
    --     end
    --     if not bItem or not bItem:GetInfo() then
    --         return false;
    --     end
    --     return aItem:GetName() < bItem:GetName();
    -- end

    if self.SelectedCategory and self.SelectedCategory.Reserves and self.SessionServer then
        for itemID in LootReserve:Ordered(self.ItemReserves, sortBySource) do
            local item = LootReserve.ItemCache:Item(itemID);
            if self.SelectedCategory.Reserves == "my" and self:IsItemReservedByMe(itemID) then
                createFrame(item);
            elseif self.SelectedCategory.Reserves == "all" and self:IsItemReserved(itemID) and not self.Blind then
                createFrame(item);
            end
            if not item:IsCached() and item:Exists() then
                table.insert(missing, item);
            end
        end
    elseif self.SelectedCategory and self.SelectedCategory.Favorites then
        for _, favorites in ipairs({ self.CharacterFavorites, self.GlobalFavorites }) do
            local first = true;
            for itemID in LootReserve:Ordered(favorites, sortBySource) do
                local conditions = self.ItemConditions[itemID];
                if itemID ~= 0 and (not self.LootCategories or LootReserve.Data:IsItemInCategories(itemID, self.LootCategories) or conditions and conditions.Custom) and LootReserve.ItemConditions:IsItemVisibleOnClient(itemID) then
                    if first then
                        first = false;
                        if favorites == self.CharacterFavorites then
                            if not list.CharacterFavoritesHeader then
                                list.CharacterFavoritesHeader = CreateFrame("Frame", nil, list, "LootReserveLootFavoritesHeader");
                                list.CharacterFavoritesHeader.Text:SetText(format("%s's Favorites", LootReserve:ColoredPlayer(LootReserve:Me())));
                            end
                            list.CharacterFavoritesHeader:Show();
                            list.CharacterFavoritesHeader:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -list.ContentHeight);
                            list.CharacterFavoritesHeader:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, -list.ContentHeight);
                            list.ContentHeight = list.ContentHeight + list.CharacterFavoritesHeader:GetHeight();
                        elseif favorites == self.GlobalFavorites then
                            if not list.GlobalFavoritesHeader then
                                list.GlobalFavoritesHeader = CreateFrame("Frame", nil, list, "LootReserveLootFavoritesHeader");
                                list.GlobalFavoritesHeader.Text:SetText("Account Favorites");
                            end
                            list.GlobalFavoritesHeader:Show();
                            list.GlobalFavoritesHeader:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -list.ContentHeight);
                            list.GlobalFavoritesHeader:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, -list.ContentHeight);
                            list.ContentHeight = list.ContentHeight + list.GlobalFavoritesHeader:GetHeight();
                        end
                    end
                    
                    local item = LootReserve.ItemCache:Item(itemID);
                    createFrame(item);
                    if not item:IsCached() and item:Exists() then
                        table.insert(missing, item);
                    end
                end
            end
        end
    elseif self.SelectedCategory and self.SelectedCategory.SearchResults and filter then
        local alreadyFoundIDs = { };
        for itemID, conditions in pairs(self.ItemConditions) do
            if itemID ~= 0 and conditions.Custom and not alreadyFoundIDs[itemID] then
                local match = false;
                local item = LootReserve.ItemCache:Item(itemID);
                if item:IsCached() then
                    if matchesFilter(item, self.ItemReserves[itemID], filter) and LootReserve.ItemConditions:IsItemVisibleOnClient(itemID) then
                        createFrame(item, "Custom Item");
                        alreadyFoundIDs[itemID] = true;
                        match = true;
                    end
                elseif item:Exists() then
                    table.insert(missing, item);
                end
                if filter and not match and LootReserve.Data:IsToken(itemID) then
                    for _, rewardID in ipairs(LootReserve.Data:GetTokenRewards(itemID)) do
                        local reward = LootReserve.ItemCache:Item(rewardID);
                        if reward:IsCached() then
                            if item:IsCached() and matchesFilter(reward, self.ItemReserves[rewardID], filter) and LootReserve.ItemConditions:IsItemVisibleOnClient(itemID) then
                                createFrame(item, "Custom Item");
                                alreadyFoundIDs[itemID] = true;
                                break;
                            end
                        elseif reward:Exists() then
                            table.insert(missing, reward);
                        end
                    end
                end
            end
        end
        local parentCategoryName = "";
        for id, category in LootReserve:Ordered(LootReserve.Data.Categories, LootReserve.Data.CategorySorter) do
            if category.Children and (not self.LootCategories or LootReserve:Contains(self.LootCategories, id)) and LootReserve.Data:IsCategoryVisible(category) then
                for _, child in ipairs(category.Children) do
                    if child.Name and child.IndentType ~= 1 then
                        parentCategoryName = child.Name;
                    end
                    if child.Loot then
                        for _, itemID in ipairs(child.Loot) do
                            if itemID ~= 0 and not alreadyFoundIDs[itemID] then
                                local match = false;
                                local item = LootReserve.ItemCache:Item(itemID);
                                if item:IsCached() then
                                    if matchesFilter(item, self.ItemReserves[itemID], filter, category.Name, child.Name) and LootReserve.ItemConditions:IsItemVisibleOnClient(itemID) then
                                        createFrame(item, child.IndentType == 1 and format("%s > %s > %s", category.NameShort, parentCategoryName, child.Name) or format("%s > %s", category.NameShort, child.Name));
                                        alreadyFoundIDs[itemID] = true;
                                        match = true;
                                    end
                                elseif item:Exists() then
                                    table.insert(missing, item);
                                end
                                if filter and not match and LootReserve.Data:IsToken(itemID) then
                                    for _, rewardID in ipairs(LootReserve.Data:GetTokenRewards(itemID)) do
                                        local reward = LootReserve.ItemCache:Item(rewardID);
                                        if reward:IsCached() then
                                            if item:IsCached() and matchesFilter(reward, self.ItemReserves[rewardID], filter, category.Name, child.Name) and LootReserve.ItemConditions:IsItemVisibleOnClient(itemID) then
                                                createFrame(item, child.IndentType == 1 and format("%s > %s > %s", category.NameShort, parentCategoryName, child.Name) or format("%s > %s", category.NameShort, child.Name));
                                                alreadyFoundIDs[itemID] = true;
                                                break;
                                            end
                                        elseif reward:Exists() then
                                            table.insert(missing, reward);
                                        end
                                    end
                                end
                                if LootReserve.Data:IsTokenReward(itemID) then
                                    local token = LootReserve.ItemCache:Item(LootReserve.Data:GetToken(itemID));
                                    if not token:IsCached() and token:Exists() then
                                        table.insert(missing, token);
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
    elseif self.SelectedCategory and self.SelectedCategory.Custom then
        for itemID, conditions in pairs(self.ItemConditions) do
            if itemID ~= 0 and conditions.Custom then
                local item = LootReserve.ItemCache:Item(itemID);
                if LootReserve.ItemConditions:IsItemVisibleOnClient(itemID) then
                    createFrame(item);
                end
                if not item:IsCached() and item:Exists() then
                    table.insert(missing, item);
                end
            end
        end
    elseif self.SelectedCategory and self.SelectedCategory.Loot then
        for _, itemID in ipairs(self.SelectedCategory.Loot) do
            if itemID ~= 0 then
                local item = LootReserve.ItemCache:Item(itemID);
                if LootReserve.ItemConditions:IsItemVisibleOnClient(itemID) then
                    createFrame(item);
                end
                if not item:IsCached() and item:Exists() then
                    table.insert(missing, item);
                end
                if LootReserve.Data:IsTokenReward(itemID) then
                    local token = LootReserve.ItemCache:Item(LootReserve.Data:GetToken(itemID));
                    if not token:IsCached() and token:Exists() then
                        table.insert(missing, token);
                    end
                end
            elseif itemID == 0 then
                createFrame(LootReserve.ItemCache:Item(0));
            end
        end
    end
    if #missing > 0 then
        if #missing > LootReserve.ItemSearch.BatchCap then
            for i = LootReserve.ItemSearch.BatchCap + 1, #missing do
                missing[i] = nil;
            end
        end
        if not self.PendingLootListUpdate or self.PendingLootListUpdate:IsComplete() then
            self.PendingLootListUpdate = LootReserve.ItemCache:OnCache(missing, function()
                self:UpdateLootList();
            end);
        end
        self.PendingLootListUpdate:SetSpeed(math.ceil(#missing/LootReserve.ItemSearch.BatchFrames));
    elseif #missingLoad > 0 then
        if #missingLoad > LootReserve.ItemSearch.BatchCap then
            for i = LootReserve.ItemSearch.BatchCap + 1, #missingLoad do
                missingLoad[i] = nil;
            end
        end
        if not self.PendingLootListUpdate or self.PendingLootListUpdate:IsComplete() then
            self.PendingLootListUpdate = LootReserve.ItemCache:OnLoad(missingLoad, function()
                self:UpdateLootList();
            end);
        end
        self.PendingLootListUpdate:SetSpeed(math.ceil(#missingLoad/LootReserve.ItemSearch.BatchFrames));
    end
    for i = list.LastIndex + 1, #list.Frames do
        list.Frames[i]:Hide();
    end

    if self.Blind and not list.BlindHint then
        list.BlindHint = CreateFrame("Frame", nil, list, "LootReserveLootBlindHint");
    end
    if list.BlindHint then
        list.BlindHint:SetShown(self.Blind and self.SelectedCategory and self.SelectedCategory.Reserves == "all");
    end

    list:GetParent():UpdateScrollChildRect();

    self:UpdateReserveStatus();
end

function LootReserve.Client:UpdateCategories()
    local list = self.Window.Categories.Scroll.Container;
    list.Frames = list.Frames or { };
    list.LastIndex = 0;
    list.ContentHeight = 0;

    local function createButton(id, category, expansion)
        list.LastIndex = list.LastIndex + 1;
        local frame = list.Frames[list.LastIndex];
        while not frame do
            frame = CreateFrame("CheckButton", nil, list,
                not category and "LootReserveCategoryListExpansionTemplate" or
                category.Separator and "LootReserveCategoryListSeparatorTemplate" or
                category.Children and "LootReserveCategoryListHeaderTemplate" or
                category.Header and "LootReserveCategoryListSubheaderTemplate" or
                "LootReserveCategoryListButtonTemplate");
            table.insert(list.Frames, frame);
            frame = list.Frames[list.LastIndex];
        end

        frame.CategoryID = id;
        frame.Category = category;
        frame.Expansion = expansion;
        frame.DefaultHeight = frame.DefaultHeight or frame:GetHeight();

        if not category then
            frame.Text:SetText(format(self.Settings.CollapsedExpansions[frame.Expansion] and "|cFF404040%s|r" or "|cFFFFD200%s|r", _G["EXPANSION_NAME"..expansion]));
            frame.GlowLeft:SetShown(not self.Settings.CollapsedExpansions[frame.Expansion]);
            frame.GlowRight:SetShown(not self.Settings.CollapsedExpansions[frame.Expansion]);
            frame:RegisterForClicks("LeftButtonDown");
            frame:SetScript("OnClick", function(frame) self:OnExpansionToggle(frame); end);
        elseif category.Separator then
            frame:EnableMouse(false);
        elseif category.Header then
            frame.Text:SetText(category.Name);
            frame:EnableMouse(false);
        elseif category.Children then
            local categoryCollapsed = self.Settings.CollapsedCategories[frame.CategoryID];
            if frame.CategoryID < 0 or self.LootCategories and LootReserve:Contains(self.LootCategories, frame.CategoryID) then
                categoryCollapsed = false;
                frame:EnableMouse(false);
            else
                frame:EnableMouse(true);
                frame:RegisterForClicks("LeftButtonDown");
                frame:SetScript("OnClick", function(frame) self:OnCategoryToggle(frame); end);
            end
            frame.Text:SetText(format(categoryCollapsed and "|cFF806900%s|r" or "%s", category.Name));
        else
            frame.Text:SetText(category.IndentType == 1 and (" - " .. category.Name) or category.IndentType == 2 and (" + " .. category.Name) or category.Name);
            frame:RegisterForClicks("LeftButtonDown");
            frame:SetScript("OnClick", function(frame) self:OnCategoryClick(frame); end);
        end
    end

    local lastExpansion = nil;

    local function createCategoryButtonsRecursively(id, category)
        if category.Expansion and category.Expansion ~= lastExpansion then
            lastExpansion = category.Expansion;
            if LootReserve:GetCurrentExpansion() > 0 then
                createButton(nil, nil, lastExpansion);
            end
        end
        if category.Name or category.Separator then
            createButton(id, category, lastExpansion);
        end
        if category.Children then
            for i, child in ipairs(category.Children) do
                if not child.Edited then
                    createCategoryButtonsRecursively(id, child);
                end
            end
        end
    end

    local categories = LootReserve:GetCategoriesText(self.LootCategories, true);
    if categories ~= "" then
        self.Window.TitleText:SetText(format("LootReserve:  %s", categories));
    else
        self.Window.TitleText:SetText("LootReserve");
    end
    
    for id, category in LootReserve:Ordered(LootReserve.Data.Categories, LootReserve.Data.CategorySorter) do
        if LootReserve.Data:IsCategoryVisible(category) then
            createCategoryButtonsRecursively(id, category);
        end
    end

    local needsSelect = not self.SelectedCategory;
    for i, frame in ipairs(list.Frames) do
        local expansionCollapsed = self.Settings.CollapsedExpansions[frame.Expansion];
        local categoryCollapsed = self.Settings.CollapsedCategories[frame.CategoryID];
        if self.LootCategories and LootReserve:Contains(self.LootCategories, frame.CategoryID) then
            expansionCollapsed = false;
            categoryCollapsed = false;
        end

        if i <= list.LastIndex
            and (not self.LootCategories or not frame.CategoryID or frame.CategoryID < 0 or LootReserve:Contains(self.LootCategories, frame.CategoryID))
            and (not frame.Category or not frame.Category.Custom or LootReserve.ItemConditions:HasCustom(false))
            and (not categoryCollapsed or not frame.Category or frame.Category.Children)
            and (not expansionCollapsed or not frame.Category)
            and (not frame.Expansion or frame.Category or not self.LootCategories)
            then
            if categoryCollapsed and frame.Category and frame.Category.Children then
                frame:SetHeight(frame.DefaultHeight - 7);
            else
                frame:SetHeight(frame.DefaultHeight);
            end
            frame:Show();
        else
            frame:Hide();
            frame:SetHeight(0.00001);
            if frame.Category == self.SelectedCategory then
                needsSelect = true;
            end
        end
        
        if frame:GetHeight() > 1 then
            frame:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -list.ContentHeight);
            frame:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, -list.ContentHeight);
            list.ContentHeight = list.ContentHeight + frame:GetHeight();
        else
            frame:ClearAllPoints();
        end
        
    end

    if needsSelect then
        for i, frame in ipairs(list.Frames) do
            if frame.Category.Favorites then
                frame:Click();
                break;
            end
        end
    end

    list:GetParent():UpdateScrollChildRect();
end

function LootReserve.Client:OnCategoryClick(button)
    if not button.Category.SearchResults then
        self.Window.Searchbar:ClearFocus();
    end

    -- Don't allow deselecting the current selected category
    if not button:GetChecked() then
        button:SetChecked(true);
        return;
    end;

    -- Toggle off all the other checkbuttons
    for _, b in pairs(self.Window.Categories.Scroll.Container.Frames) do
        if b ~= button then
            b:SetChecked(false);
        end
    end

    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    self:StopCategoryFlashing(button);

    self.SelectedCategory = button.Category;
    self.Window.Loot.Scroll:SetVerticalScroll(0);
    self:UpdateLootList();
end

function LootReserve.Client:OnCategoryToggle(button)
    button:SetChecked(false);
    self.Settings.CollapsedCategories[button.CategoryID] = not self.Settings.CollapsedCategories[button.CategoryID] or nil;
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    self:UpdateCategories();
end

function LootReserve.Client:OnExpansionToggle(button)
    button:SetChecked(false);
    self.Settings.CollapsedExpansions[button.Expansion] = not self.Settings.CollapsedExpansions[button.Expansion] or nil;
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    self:UpdateCategories();
end

function LootReserve.Client:FlashCategory(categoryField, value, continuously)
    for _, button in pairs(self.Window.Categories.Scroll.Container.Frames) do
        if button:IsShown() and button.Flash and not button.Expansion and button.Category and button.Category[categoryField] and (value == nil or button.Category[categoryField] == value) then
            button.Flash:SetAlpha(1);
            button.ContinuousFlashing = (button.ContinuousFlashing or continuously) and 0 or nil;
            self.CategoryFlashing = true;
        end
    end
end

function LootReserve.Client:StopCategoryFlashing(button)
    if button then
        button.Flash:SetAlpha(0);
        button.ContinuousFlashing = nil;
    else
        self.CategoryFlashing = false;
        for _, button in pairs(self.Window.Categories.Scroll.Container.Frames) do
            if button:IsShown() and button.Flash then
                button.Flash:SetAlpha(0);
                button.ContinuousFlashing = nil;
            end
        end
    end
end

function LootReserve.Client:OnWindowLoad(window)
    self.Window = window;
    self.Window.TopLeftCorner:SetSize(32, 32); -- Blizzard UI bug?
    self.Window.TitleText:SetPoint("TOP", self.Window, "TOP", 0, -4);
    self.Window.TitleText:SetText("LootReserve");
    LootReserve:SetResizeBounds(self.Window, 550, 250);
    self:UpdateCategories();
    self:UpdateReserveStatus();
    LootReserve:RegisterUpdate(function(elapsed)
        if self.CategoryFlashing and self.Window:IsShown() then
            self.CategoryFlashing = false;
            for _, button in pairs(self.Window.Categories.Scroll.Container.Frames) do
                if button:IsShown() and button.Flash and (button.Flash:GetAlpha() > 0 or button.ContinuousFlashing) then
                    if button.ContinuousFlashing then
                        button.ContinuousFlashing = (button.ContinuousFlashing + elapsed) % 1;
                        button.Flash:SetAlpha(0.5 + 0.25 * (1 + math.cos(button.ContinuousFlashing * 2 * 3.14159265)));
                    else
                        button.Flash:SetAlpha(math.max(0, button.Flash:GetAlpha() - elapsed));
                    end
                    self.CategoryFlashing = true;
                end
            end
        end

        if not self.SessionServer then
        elseif not self.AcceptingReserves or self.Locked then
            local r, g, b, a = self.Window.RemainingTextGlow:GetVertexColor();
            elapsed = math.min(elapsed, 1);
            r = r + (1 - r) * elapsed / 0.5;
            g = g + (0 - g) * elapsed / 0.5;
            b = b + (0 - b) * elapsed / 0.5;
            a = a + (0.15 - a) * elapsed / 0.5;
            self.Window.RemainingTextGlow:SetVertexColor(r, g, b, a);
        elseif self.Duration == 0 then
            self.Window.RemainingTextGlow:SetVertexColor(0, 1, 0);
        else
            local r, g, b = self.Window.Duration:GetStatusBarColor();
            self.Window.RemainingTextGlow:SetVertexColor(r, g, b, 0.15 + r * 0.25);
        end
    end);
end
