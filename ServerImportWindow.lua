LootReserve.Server.Import.Separator = ",";
LootReserve.Server.Import.UseHeaders = false;
LootReserve.Server.Import.MatchNames = false;
LootReserve.Server.Import.SkipNotInRaid = false;
LootReserve.Server.Import.Columns = { };

local function ParseCSVLine(line, sep)
    local res = { };
    local pos = 1;
    sep = sep or ",";
    while true do
        local c = string.sub(line, pos, pos);
        if c == "" then break; end
        if c == '"' then
            local txt = "";
            repeat
                local startp,endp = string.find(line, '^%b""', pos);
                txt = txt .. string.sub(line, startp + 1, endp - 1);
                pos = endp + 1;
                c = string.sub(line, pos, pos);
                if c == '"' then txt = txt..'"' end
            until c ~= '"'
            table.insert(res, txt);
            pos = pos + 1;
        else
            local startp, endp = string.find(line, sep, pos, true);
            if startp then
                table.insert(res, string.sub(line, pos, startp - 1));
                pos = endp + 1;
            else
                table.insert(res, string.sub(line, pos));
                break;
            end
        end
    end
    return res;
end

local function ParseMultireserveCount(value)
    if type(value) == "string" then
        value = tonumber(value:match("[Xx]%s-(%d+)") or value:match("(%d+)%s-[Xx]") or value:match("^(%d+)$"));
    end
    if value and type(value) == "number" and value > 1 then
        return value;
    end
end

function LootReserve.Server.Import:UpdateReservesList()
    if not self.Window:IsShown() then return; end

    self.Window.Header.Name:SetWidth(LootReserve:IsCrossRealm() and 300 or 200);
    self.Window:SetMinResize(LootReserve:IsCrossRealm() and 490 or 390, 440);

    local list = self.Window.Scroll.Container;
    list.Frames = list.Frames or { };
    list.LastIndex = 0;

    -- Clear everything
    for _, frame in ipairs(list.Frames) do
        frame:Hide();
    end

    local data = self.Members;
    if not data then
        return;
    end

    local function createFrame(player, member)
        list.LastIndex = list.LastIndex + 1;
        local frame = list.Frames[list.LastIndex];
        while not frame do
            frame = CreateFrame("Frame", nil, list, "LootReserveServerImportReserveTemplate");

            if #list.Frames == 0 then
                frame:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -4);
                frame:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, -4);
            else
                frame:SetPoint("TOPLEFT", list.Frames[#list.Frames], "BOTTOMLEFT", 0, 0);
                frame:SetPoint("TOPRIGHT", list.Frames[#list.Frames], "BOTTOMRIGHT", 0, 0);
            end
            table.insert(list.Frames, frame);
            frame = list.Frames[list.LastIndex];
        end

        frame.Player = player;
        frame.Member = member;
        frame:Show();

        frame.Alt:SetShown(list.LastIndex % 2 == 0);
        frame.Name:SetText(format("%s%s", LootReserve:ColoredPlayer(player), LootReserve:IsPlayerOnline(player) == nil and format("|cFF808080 (%s)|r", member.NameMatchResult or "not in raid") or LootReserve:IsPlayerOnline(player) == false and "|cFF808080 (offline)|r" or ""));

        local last = 0;
        frame.ReservesFrame.Items = frame.ReservesFrame.Items or { };
        for index, item in ipairs(member.ReservedItems) do
            last = index;
            local button = frame.ReservesFrame.Items[last];
            while not button do
                button = CreateFrame("Button", nil, frame.ReservesFrame, "LootReserveServerImportItemTemplate");
                if last == 1 then
                    button:SetPoint("LEFT", frame.ReservesFrame, "LEFT");
                else
                    button:SetPoint("LEFT", frame.ReservesFrame.Items[last - 1], "RIGHT", 4, 0);
                end
                table.insert(frame.ReservesFrame.Items, button);
                button = frame.ReservesFrame.Items[last];
            end
            button:Show();
            button.Item = item;

            local name, link, _, _, _, _, _, _, _, texture = GetItemInfo(item);
            button.Link = link;
            button.Icon.Texture:SetTexture(texture or "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK");
            if #member.ReservedItems == 1 and item ~= 0 then
                button.Icon.Name:SetText(member.InvalidReasons[index] and format("|cFFFF0000%s|r", name or "") or (link or "|cFFFF0000Loading...|r"):gsub("[%[%]]", ""));
                button.Icon.Name:Show();
            else
                button.Icon.Name:Hide();
            end
            if member.InvalidReasons[index] then
                button.Tooltip = (link and (link:gsub("[%[%]]", "") .. "|n") or "") .. member.InvalidReasons[index];
                button.Icon.Texture:SetVertexColor(1, 0, 0);
            else
                button.Tooltip = nil;
                button.Icon.Texture:SetVertexColor(1, 1, 1);
            end
        end
        for i = last + 1, #frame.ReservesFrame.Items do
            frame.ReservesFrame.Items[i]:Hide();
        end
    end

    for player, member in LootReserve:Ordered(data, function(aMember, bMember, aPlayer, bPlayer) return aPlayer < bPlayer; end) do
        createFrame(player, member);
    end

    for i = list.LastIndex + 1, #list.Frames do
        list.Frames[i]:Hide();
    end

    list:GetParent():UpdateScrollChildRect();
end

function LootReserve.Server.Import:InputUpdated()
    self.Separator = nil;
    self.UseHeaders = nil;
    self.Columns = nil;
    self:InputOptionsUpdated();

    self.Separator = self.Separator or ",";
    self.Window.InputOptions.Input.Separator:init();
    self.Window.InputOptions.Input.UseHeaders:SetChecked(self.UseHeaders);
end

function LootReserve.Server.Import:InputOptionsUpdated()
    local input = self.Window.Input.Scroll.EditBox:GetText();
    input = input:gsub("    ", "\t");

    -- Read rows
    self.Rows = { };
    for line in input:gmatch("[^\r\n]+") do
        -- Try to guess the value separator character
        if not self.Separator then
            if line:find("\t") then
                self.Separator = "\t";
            elseif line:find(";") then
                self.Separator = ";"
            else
                self.Separator = ",";
            end
        end

        local row = { };
        for _, column in ipairs(ParseCSVLine(line, self.Separator)) do
            table.insert(row, tonumber(column) or column);
        end
        if #row > 0 then
            table.insert(self.Rows, row);
        end
    end

    -- Try to guess if there's a headers row
    if self.UseHeaders == nil then
        if #self.Rows > 1 then
            for i = 1, math.min(#self.Rows[1], #self.Rows[2]) do
                if type(self.Rows[1][i]) == "string" and type(self.Rows[2][i]) == "number" then
                    self.UseHeaders = true;
                    break;
                end
            end
        end
    end

    -- Extract the headers row if enabled
    if self.UseHeaders then
        self.Headers = self.Rows[1];
        table.remove(self.Rows, 1);
        if not self.Columns then
            self.Columns = { };
            -- Try to guess what each column means by the header
            for i, header in ipairs(self.Headers) do
                header = header:lower();
                if header:find("item") then
                    self.Columns[i] = "Item";
                elseif (header:find("name") or header:find("player") or header:find("member")) and not (header:find("guild") or header:find("class") or header:find("race")) then
                    self.Columns[i] = "Player";
                elseif header:find("note") or header:find("count") or header:find("quantity") then
                    -- Search for meaningful numbers first (basically where count > 1)
                    for _, row in ipairs(self.Rows) do
                        if row[i] and ParseMultireserveCount(row[i]) then
                            self.Columns[i] = "Count";
                            break;
                        end
                    end
                end
            end
        end
    else
        self.Headers = nil;
        self.Columns = self.Columns or { };
    end

    -- Count how many columns we have, checking each row, in case somewhere the data spilled out into unheadered columns
    local columns = self.Headers and #self.Headers or 0;
    for _, row in ipairs(self.Rows) do
        columns = math.max(#row, columns);
    end

    -- Create drop-down frames for each column
    local list = self.Window.InputOptions.Columns.Scroll.Container;
    local last = 0;
    list.Columns = list.Columns or { };
    for i = 1, columns do
        self.Columns[i] = self.Columns[i] or "Unused";
        last = i;
        local frame = list.Columns[i];
        while not frame do
            frame = CreateFrame("Frame", nil, list, "LootReserveServerImportOptionColumnTemplate");
            if #list.Columns == 1 then
                frame:SetPoint("TOPLEFT", list, "TOPLEFT", -10, -12);
            else
                frame:SetPoint("TOPLEFT", list.Columns[#list.Columns - 1], "TOPRIGHT", -25, 0);
            end
            frame = list.Columns[i];
        end
        frame.name = self.Headers and #self.Headers >= i and self.Headers[i] or format("Column %d", i);
        frame.index = i;
        frame:init();
        frame:Show();

        local rows = "";
        for index, row in ipairs(self.Rows) do
            rows = rows .. (#rows > 0 and "|n" or "") .. (row[i] and ((index % 2 == 0 and "|cFFAAAAAA" or "|cFFFFFFFF") .. tostring(row[i]) .. "|r") or "|cFF606060<MISSING>|r");
        end
        frame.Rows.Text:SetText(rows);
    end
    for i = last + 1, #list.Columns do
        list.Columns[i]:Hide();
    end
    list:GetParent():UpdateScrollChildRect();

    self:SessionSettingsUpdated();
end

function LootReserve.Server.Import:SessionSettingsUpdated()
    -- Gather indexes of used columns
    local playerColumns = { };
    local itemColumns = { };
    for i, column in ipairs(self.Columns) do
        if column == "Player" then
            table.insert(playerColumns, i);
        elseif column == "Item" then
            table.insert(itemColumns, i);
        end
    end

    self.Members = { };
    local function Parse()
        if #playerColumns == 0 or #itemColumns == 0 then
            return "Enter CSV text above and mark at least one|ncolumn as \"Player\" and \"Item\"";
        end

        for _, row in ipairs(self.Rows) do
            row.Count = nil;
            for i, column in ipairs(self.Columns) do
                if column == "Count" and row[i] then
                    if not row.Count then
                        row.Count = ParseMultireserveCount(row[i]);
                    else
                        return "Only one column can be marked as \"Count\"";
                    end
                end
            end
        end

        local simplifiedRaidNames = nil;
        if self.MatchNames then
            simplifiedRaidNames = { };
            LootReserve:ForEachRaider(function(name)
                local simplified = LootReserve:SimplifyName(name);
                local existing = simplifiedRaidNames[simplified];
                if not existing then
                    simplifiedRaidNames[simplified] = name;
                elseif type(existing) == "string" then
                    simplifiedRaidNames[simplified] = 2;
                elseif type(existing) == "number" then
                    simplifiedRaidNames[simplified] = existing + 1;
                end
            end);
        end

        local itemReserveCount = { };
        local itemReserveCountByPlayer = { };

        for _, row in ipairs(self.Rows) do
            local itemsOnThisRow = { };
            for _, playerColumn in ipairs(playerColumns) do
                for _, itemColumn in ipairs(itemColumns) do
                    local player = row[playerColumn];
                    local item = row[itemColumn];

                    if type(player) ~= "string" then
                        player = nil;
                    end

                    local nameMatchResult = nil;
                    if player and #player > 0 then
                        player = LootReserve:Player(LootReserve:NormalizeName(player));
                        if self.MatchNames and LootReserve:IsPlayerOnline(player) == nil then
                            local simplified = simplifiedRaidNames[LootReserve:SimplifyName(player)];
                            if not simplified then
                                nameMatchResult = "not in raid";
                            elseif type(simplified) == "string" then
                                player = simplified;
                            elseif type(simplified) == "number" then
                                nameMatchResult = "ambiguous name";
                            end
                        end
                    end

                    if player and (LootReserve:IsPlayerOnline(player) ~= nil or not self.SkipNotInRaid) and item and item ~= 0 and item ~= "" then
                        -- Transform Item Name -> Item ID
                        if type(item) == "string" then
                            if not LootReserve.Server:UpdateItemNameCache() then
                                C_Timer.After(0.25, function() LootReserve.Server.Import:InputOptionsUpdated(); end);
                                return "Loading item names, please wait...";
                            end

                            item = LootReserve:TransformSearchText(item);
                            for id, name in pairs(LootReserve.Server.ItemNames) do
                                if name == item and LootReserve.ItemConditions:TestServer(id) then
                                    item = id;
                                    break;
                                end
                            end

                            if type(item) == "string" then
                                item = 0;
                            end
                        end

                        if not self.Members[player] then
                            self.Members[player] =
                            {
                                NameMatchResult = nameMatchResult,
                                ReservedItems   = { },
                                InvalidReasons  = { },
                            };
                        end
                        local member = self.Members[player];
                        if nameMatchResult and not member.NameMatchResult then
                            member.NameMatchResult = nameMatchResult;
                        end
                        if not itemsOnThisRow[item] then
                            itemsOnThisRow[item] = true;
                            for i = 1, row.Count or 1 do
                                table.insert(member.ReservedItems, item);
                                itemReserveCount[item] = (itemReserveCount[item] or 0) + 1;
                                itemReserveCountByPlayer[player] = itemReserveCountByPlayer[player] or { };
                                itemReserveCountByPlayer[player][item] = (itemReserveCountByPlayer[player][item] or 0) + 1;
                                local conditions = LootReserve.Server:GetNewSessionItemConditions()[item];
                                local class = select(3, UnitClass(player));
                                if item == 0 then
                                    member.InvalidReasons[#member.ReservedItems] = "Item with the name \"" .. row[itemColumn] .. "\" was not be found|nor it can't be reserved due to session settings.";
                                elseif not (LootReserve.Data:IsItemInCategories(item, LootReserve.Server.NewSessionSettings.LootCategories) or conditions and conditions.Custom) or not LootReserve.ItemConditions:TestServer(item) then
                                    member.InvalidReasons[#member.ReservedItems] = "Item can't be reserved due to session settings.|nChange to the appropriate raid map or add this item as a custom item.";
                                elseif conditions and conditions.ClassMask and class and not LootReserve.ItemConditions:TestClassMask(conditions.ClassMask, class) then
                                    member.InvalidReasons[#member.ReservedItems] = player .. "'s class cannot reserve this item.|nEdit the raid loot to change the class restrictions on this item, or it will not be imported.";
                                elseif conditions and conditions.Limit and itemReserveCount[item] > conditions.Limit then
                                    member.InvalidReasons[#member.ReservedItems] = "This item has hit the limit of how many times it can be reserved.|nEdit the raid loot to increase or remove the limit on this item, or it will not be imported.";
                                elseif #member.ReservedItems > LootReserve.Server.NewSessionSettings.MaxReservesPerPlayer then
                                    member.InvalidReasons[#member.ReservedItems] = "Player has more reserved items than allowed by the session settings.|nIncrease the number of allowed reserves, or this item will not be imported.";
                                elseif itemReserveCountByPlayer[player][item] > (LootReserve.Server.NewSessionSettings.Multireserve or 1) then
                                    member.InvalidReasons[#member.ReservedItems] = "Player has reserved this item more times than allowed by the session settings.|nIncrease the number of allowed multireserves, or this item will not be imported.";
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    local error = Parse();
    if error then
        self.Window.Error:SetText(format("No reserves imported|n|n%s", error));
        self.Window.Error:Show();
    else
        self.Window.Error:Hide();
    end

    self:UpdateReservesList();
    self.Window.ImportButton:SetEnabled(self.Members and next(self.Members));
end

function LootReserve.Server.Import:Import()
    if LootReserve.Server.CurrentSession then return; end

    if self.Members and next(self.Members) then
        table.wipe(LootReserve.Server.NewSessionSettings.ImportedMembers);
        for player, member in pairs(self.Members) do
            for i, item in ipairs(member.ReservedItems) do
                if not member.InvalidReasons[i] then
                    LootReserve.Server.NewSessionSettings.ImportedMembers[player] = LootReserve.Server.NewSessionSettings.ImportedMembers[player] or { ReservedItems = { } };
                    table.insert(LootReserve.Server.NewSessionSettings.ImportedMembers[player].ReservedItems, item);
                end
            end
        end
    end
    self.Window:Hide();
    LootReserve.Server.MembersEdit.Window:Show();
    LootReserve.Server.MembersEdit:UpdateMembersList();
end

function LootReserve.Server.Import:OnWindowLoad(window)
    self.Window = window;
    self.Window.TopLeftCorner:SetSize(32, 32); -- Blizzard UI bug?
    self.Window.TitleText:SetText("Loot Reserve Server - Import");
    self.Window:SetMinResize(390, 440);
    self:InputUpdated();
    LootReserve:RegisterEvent("GET_ITEM_INFO_RECEIVED", function(item, success)
        if success and self.Members then
            for player, member in pairs(self.Members) do
                if LootReserve:Contains(member.ReservedItems, item) then
                    self:UpdateReservesList();
                    return;
                end
            end
        end
    end);
end
