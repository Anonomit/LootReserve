function LootReserve.Server.LootEdit:UpdateLootList()
    LootReserveServerButtonLootEdit:SetGlow(false);
    for _ in pairs(LootReserve.Server:GetNewSessionItemConditions()) do
        LootReserveServerButtonLootEdit:SetGlow(true);
        break;
    end

    if not self.Window:IsShown() then return; end

    local filter = LootReserve:TransformSearchText(self.Window.Search:GetText());
    if #filter < 3 and not tonumber(filter) then
        filter = nil;
    end

    local list = self.Window.Loot.Scroll.Container;
    list.Frames = list.Frames or { };
    list.LastIndex = 0;
    list.ContentHeight = 0;

    if not list.RevertEditsFrame then
        list.RevertEditsFrame = CreateFrame("Frame", nil, list, "LootReserveLootEditRevertEditsFrame");
    end
    list.RevertEditsFrame:Hide();
    if not list.AddCustomFrame then
        list.AddCustomFrame = CreateFrame("Frame", nil, list, "LootReserveLootEditAddCustomFrame");
    end
    list.AddCustomFrame:Hide();

    local function cleanupFrame(frame)
        if UIDROPDOWNMENU_OPEN_MENU == frame.ConditionsFrame.ClassMaskMenu then
            CloseMenus();
        end
        frame.ConditionsFrame.Limit.EditBox:ClearFocus();
    end

    local function createFrame(item, source)
        list.LastIndex = list.LastIndex + 1;
        local frame = list.Frames[list.LastIndex];
        while not frame do
            frame = CreateFrame("Frame", nil, list, "LootReserveLootEditListTemplate");

            if #list.Frames == 0 then
                frame:SetPoint("TOPLEFT", list, "TOPLEFT");
                frame:SetPoint("TOPRIGHT", list, "TOPRIGHT");
            else
                frame:SetPoint("TOPLEFT", list.Frames[#list.Frames], "BOTTOMLEFT", 0, 0);
                frame:SetPoint("TOPRIGHT", list.Frames[#list.Frames], "BOTTOMRIGHT", 0, 0);
            end
            table.insert(list.Frames, frame);
            frame = list.Frames[list.LastIndex];
        end

        if frame.Item ~= item:GetID() then
            cleanupFrame(frame);
        end

        frame.Item = item:GetID();

        if item:GetID() == 0 then
            if list.LastIndex <= 1 or not list.Frames[list.LastIndex - 1]:IsShown() then
                frame:SetHeight(0.00001);
                frame:Hide();
            else
                frame:SetHeight(32);
                frame:Hide();
            end
        else
            frame:SetHeight(44);
            frame:Show();

            local description = LootReserve:GetItemDescription(item:GetID());
            local name, link, texture = item:GetNameLinkTexture();

            frame.Link = link;

            frame.ItemFrame.Icon:SetTexture(texture);
            frame.ItemFrame.Name:SetText((link or name or "|cFFFF4000Loading...|r"):gsub("[%[%]]", ""));
            frame.ItemFrame.Misc:SetText(source or description);

            local conditions = LootReserve.ItemConditions:Get(itemID, true);
            frame.ItemFrame:SetAlpha(conditions and (conditions.Hidden or conditions.Faction and not LootReserve.ItemConditions:TestFaction(conditions.Faction)) and 0.25 or 1);
            frame.ConditionsFrame.ClassMask:Update();
            frame.ConditionsFrame.State:Update();
            frame.ConditionsFrame.Limit:Update();
            frame.ConditionsFrame.LimitNoHover:Update();
            frame.hovered = nil;
        end

        list.ContentHeight = list.ContentHeight + frame:GetHeight();
    end

    local function matchesFilter(item, filter)
        filter = (filter or "");
        if #filter == 0 then
            return true;
        end

        if item:GetID() == tonumber(filter) then
            return true;
        end
        if string.find(item:GetSearchName(), filter, 1, true) then
            return true;
        end

        return false;
    end

    local missing = false;
    if self.SelectedCategory and self.SelectedCategory.Edited then
        for itemID, conditions in pairs(LootReserve.Server:GetNewSessionItemConditions()) do
            local item = LootReserve.ItemSearch:Get(itemID);
            if item and item:GetInfo() then
                createFrame(item);
            elseif item or LootReserve.ItemSearch:IsPending(itemID) then
                missing = true;
            end
        end
    elseif self.SelectedCategory and self.SelectedCategory.Search and filter then
        for itemID, conditions in pairs(LootReserve.Server:GetNewSessionItemConditions()) do
            if itemID ~= 0 and conditions.Custom then
                local match = false;
                local item = LootReserve.ItemSearch:Get(itemID);
                if item and item:GetInfo() then
                    if matchesFilter(item, filter) then
                        createFrame(item, "Custom Item");
                        match = true;
                    end
                elseif item or LootReserve.ItemSearch:IsPending(itemID) then
                    missing = true;
                end
                if filter and not match and LootReserve.Data:IsToken(itemID) then
                    for _, rewardID in ipairs(LootReserve.Data:GetTokenRewards(itemID)) do
                        local reward = LootReserve.ItemSearch:Get(rewardID);
                        if reward and reward:GetInfo() then
                            if matchesFilter(reward, filter) then
                                createFrame(item, "Custom Item");
                                break;
                            end
                        elseif reward or LootReserve.ItemSearch:IsPending(rewardID) then
                            missing = true;
                        end
                    end
                end
            end
        end
        if select(2, LootReserve.ItemSearch:GetProgress()) < LootReserve.Constants.LoadState.SessionDone then
            LootReserve.ItemSearch:SetSpeed(250);
            missing = true;
        else
            for id, category in LootReserve:Ordered(LootReserve.Data.Categories, LootReserve.Data.CategorySorter) do
                if category.Children and (not LootReserve.Server.NewSessionSettings.LootCategories or LootReserve:Contains(LootReserve.Server.NewSessionSettings.LootCategories, id)) and LootReserve.Data:IsCategoryVisible(category) then
                    for _, child in ipairs(category.Children) do
                        if child.Loot then
                            for _, itemID in ipairs(child.Loot) do
                                if itemID ~= 0 then
                                    local match = false;
                                    local item = LootReserve.ItemSearch:Get(itemID);
                                    if item and item:GetInfo() then
                                        if matchesFilter(item, filter) then
                                            createFrame(item, format("%s > %s", category.Name, child.Name));
                                            match = true;
                                        end
                                    elseif item or LootReserve.ItemSearch:IsPending(itemID) then
                                        missing = true;
                                    end
                                    if filter and not match and LootReserve.Data:IsToken(itemID) then
                                        for _, rewardID in ipairs(LootReserve.Data:GetTokenRewards(itemID)) do
                                            local reward = LootReserve.ItemSearch:Get(rewardID);
                                            if reward and reward:GetInfo() then
                                                if matchesFilter(reward, filter) then
                                                    createFrame(item, format("%s > %s", category.Name, child.Name));
                                                    break;
                                                end
                                            elseif reward or LootReserve.ItemSearch:IsPending(rewardID) then
                                                missing = true;
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    elseif self.SelectedCategory and self.SelectedCategory.Custom then
        for itemID, conditions in pairs(LootReserve.Server:GetNewSessionItemConditions()) do
            if itemID ~= 0 and conditions.Custom then
                local item = LootReserve.ItemSearch:Get(itemID);
                if item and item:GetInfo() then
                    createFrame(item);
                elseif item or LootReserve.ItemSearch:IsPending(itemID) then
                    missing = true;
                end
            end
        end
    elseif self.SelectedCategory and self.SelectedCategory.Loot then
        for _, itemID in ipairs(self.SelectedCategory.Loot) do
            if itemID ~= 0 then
                local item = LootReserve.ItemSearch:Get(itemID);
                if item and item:GetInfo() then
                    createFrame(item);
                elseif item or LootReserve.ItemSearch:IsPending(itemID) then
                    missing = true;
                end
            elseif itemID == 0 then
                createFrame(LootReserve.Item(0))
            end
        end
    end
    if missing then
        if not self.PendingLootEditUpdate then
            C_Timer.After(0.1, function()
                self.PendingLootEditUpdate = false;
                self:UpdateLootList();
            end);
            self.PendingLootEditUpdate = true;
        end
    end

    if self.SelectedCategory.Edited and list.LastIndex > 0 then
        list.RevertEditsFrame:Show();
        list.RevertEditsFrame:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -list.ContentHeight);
        list.RevertEditsFrame:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, -list.ContentHeight);
    elseif self.SelectedCategory.Custom then
        list.AddCustomFrame:Show();
        list.AddCustomFrame:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -list.ContentHeight);
        list.AddCustomFrame:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, -list.ContentHeight);
    end

    for i = list.LastIndex + 1, #list.Frames do
        cleanupFrame(list.Frames[i]);
        list.Frames[i]:Hide();
    end

    list:GetParent():UpdateScrollChildRect();
end

function LootReserve.Server.LootEdit:UpdateCategories()
    LootReserveServerButtonLootEdit:SetGlow(false);
    for _ in pairs(LootReserve.Server:GetNewSessionItemConditions()) do
        LootReserveServerButtonLootEdit:SetGlow(true);
        break;
    end

    if not self.Window:IsShown() then return; end

    local list = self.Window.Categories.Scroll.Container;
    list.Frames = list.Frames or { };
    list.LastIndex = 0;

    local function createButton(id, category)
        list.LastIndex = list.LastIndex + 1;
        local frame = list.Frames[list.LastIndex];
        while not frame do
            frame = CreateFrame("CheckButton", nil, list,
                category.Separator and "LootReserveCategoryListSeparatorTemplate" or
                category.Children and "LootReserveCategoryListHeaderTemplate" or
                category.Header and "LootReserveCategoryListSubheaderTemplate" or
                "LootReserveCategoryListButtonTemplate");

            if #list.Frames == 0 then
                frame:SetPoint("TOPLEFT", list, "TOPLEFT");
                frame:SetPoint("TOPRIGHT", list, "TOPRIGHT");
            else
                frame:SetPoint("TOPLEFT", list.Frames[#list.Frames], "BOTTOMLEFT", 0, 0);
                frame:SetPoint("TOPRIGHT", list.Frames[#list.Frames], "BOTTOMRIGHT", 0, 0);
            end
            table.insert(list.Frames, frame);
            frame = list.Frames[list.LastIndex];
        end

        frame.CategoryID = id;
        frame.Category = category;
        frame.DefaultHeight = frame.DefaultHeight or frame:GetHeight();

        if category.Separator then
            frame:EnableMouse(false);
        else
            frame.Text:SetText(category.Name);
            if category.Children or category.Header then
                frame:EnableMouse(false);
            else
                frame:RegisterForClicks("LeftButtonDown");
                frame:SetScript("OnClick", function(frame) self:OnCategoryClick(frame); end);
            end
        end
    end

    local function createCategoryButtonsRecursively(id, category)
        if category.Name or category.Separator then
            createButton(id, category);
        end
        if category.Children then
            for i, child in ipairs(category.Children) do
                if not child.Reserves and not child.Favorites then
                    createCategoryButtonsRecursively(id, child);
                end
            end
        end
    end

    for id, category in LootReserve:Ordered(LootReserve.Data.Categories, LootReserve.Data.CategorySorter) do
        if LootReserve.Data:IsCategoryVisible(category) then
            createCategoryButtonsRecursively(id, category);
        end
    end

    for i, frame in ipairs(list.Frames) do
        if i <= list.LastIndex and (frame.CategoryID < 0 or not LootReserve.Server.NewSessionSettings.LootCategories or LootReserve:Contains(LootReserve.Server.NewSessionSettings.LootCategories, frame.CategoryID)) then
            frame:SetHeight(frame.DefaultHeight);
            frame:Show();
        else
            frame:Hide();
            frame:SetHeight(0.00001);
        end
    end

    for i, frame in ipairs(list.Frames) do
        if i <= list.LastIndex and frame.Category.Edited then
            frame:Click();
        end
    end

    list:GetParent():UpdateScrollChildRect();
end

function LootReserve.Server.LootEdit:OnCategoryClick(button)
    CloseMenus();
    if self.FocusedEditBox then
        self.FocusedEditBox:ClearFocus();
    end

    if not button.Category.Search then
        self.Window.Search:ClearFocus();
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

    self.SelectedCategory = button.Category;
    self.Window.Loot.Scroll:SetVerticalScroll(0);
    self:UpdateLootList();
end

function LootReserve.Server.LootEdit:OnWindowLoad(window)
    self.Window = window;
    self.Window.TopLeftCorner:SetSize(32, 32); -- Blizzard UI bug?
    self.Window.TitleText:SetText("LootReserve Host - Loot List Edit");
    self.Window:SetMinResize(550, 250);
    self:UpdateCategories();
end
