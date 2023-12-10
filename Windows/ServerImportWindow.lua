LootReserve.Server.Import.Separator        = ",";
LootReserve.Server.Import.UseHeaders       = false;
LootReserve.Server.Import.MatchPlayerNames = true;
LootReserve.Server.Import.SkipNotInRaid    = false;
LootReserve.Server.Import.MatchItemNames   = false;
LootReserve.Server.Import.Columns          = { };

function LootReserve.Server.Import:InitDropDown(dropdown)
    local self = dropdown
    local options = { };
    for _, text in ipairs({ strsplit("$", self.values) }) do
        local name, value = strsplit("=", text);
        value = value or name;
        value = tonumber(value) or value;
        value = value == "\\t" and "\t" or value;
        table.insert(options, { name = name, value = value });
    end
    local function GetOptionName(value)
        for _, option in ipairs(options) do
            if option.value == value then
                return option.name;
            end
        end
    end

    self.Header:SetText(self.name or "");
    if self.width then
        LootReserve.LibDD:UIDropDownMenu_SetWidth(self, math.max(self.width, self.Header:GetStringWidth()));
    end
    LootReserve.LibDD:UIDropDownMenu_JustifyText(self, self.justify or "LEFT");
    LootReserve.LibDD:UIDropDownMenu_Initialize(self, function(frame, level, menuList)
        local info = LootReserve.LibDD:UIDropDownMenu_CreateInfo();
        info.minWidth = self:GetWidth() - 40;
        info.func = function(info)
            if self.index then
                LootReserve.Server.Import[self.field][self.index] = info.value;
            else
                LootReserve.Server.Import[self.field] = info.value;
            end
            LootReserve.LibDD:UIDropDownMenu_SetSelectedValue(self, info.value);
            C_Timer.After(0, function() LootReserve.Server.Import:InputOptionsUpdated(); end);
        end
        for _, option in ipairs(options) do
            info.text = option.name;
            info.value = option.value;
            LootReserve.LibDD:UIDropDownMenu_AddButton(info);
            info.checked = false;
        end
    end);
    local value;
    if self.index then
        value = LootReserve.Server.Import[self.field][self.index];
    else
        value = LootReserve.Server.Import[self.field];
    end
    LootReserve.LibDD:UIDropDownMenu_SetText(self, GetOptionName(value));
    self.selectedValue = value;
end

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
        value = tonumber(value:match("[xX%*]%s*(%d+)") or value:match("(%d+)%s*[xX*]") or value:match("^(%d+)$"));
    end
    if value and type(value) == "number" and value > 1 then
        return value;
    end
end

local function ParseNumber(value)
    if type(value) == "string" then
        value = tonumber(value:match("([%+%-]?%d+)"));
    end
    if value and type(value) == "number" then
        return value;
    end
end

local function ParseClass(value)
    if value and type(value) == "string" then
        value = LootReserve.Constants.ClassLocalizedToFilename[value] or value;
        value = tonumber(LootReserve.Constants.ClassFilenameToClassID[value]);
    end
    return value;
end

function LootReserve.Server.Import:UpdateReservesList()
    if not self.Window:IsShown() then return; end

    self.Window.Header.Name:SetWidth(LootReserve:IsCrossRealm() and 300 or 200);
    LootReserve:SetResizeBounds(self.Window, LootReserve:IsCrossRealm() and 490 or 390, 440);

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
        frame.Name:SetText(format("%s%s", LootReserve:ColoredPlayer(player, member.Class), LootReserve:IsPlayerOnline(player) == nil and format("|cFF808080 (%s)|r", member.NameMatchResult or "not in raid") or LootReserve:IsPlayerOnline(player) == false and "|cFF808080 (offline)|r" or ""));

        local missing = { };
        local last = 0;
        frame.ReservesFrame.Items = frame.ReservesFrame.Items or { };
        for index, itemID in ipairs(member.ReservedItems) do
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
            button.Item = LootReserve.ItemCache:Item(itemID);
            if not button.Item:IsCached() and button.Item:GetID() ~= 0 and button.Item:Exists() then
                table.insert(missing, button.Item)
            end

            local name, link, texture = button.Item:GetNameLinkTexture();
            button.Link = link;
            button.Icon.Texture:SetTexture(texture or "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK");
            if #member.ReservedItems == 1 and itemID ~= 0 then
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
        if #missing > 0 then
            if not self.PendingReservesListUpdate or self.PendingReservesListUpdate:IsComplete() then
                self.PendingReservesListUpdate = LootReserve.ItemCache:OnCache(missing, function()
                    self:UpdateReservesList();
                end);
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
    self:InitDropDown(self.Window.InputOptions.Input.Separator);
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
            for _, header in ipairs({"name", "player", "member", "character", "delta", "bonus"}) do
                for _, cell in ipairs(self.Rows[1]) do
                    if tostring(cell):lower():match(header) then
                        self.UseHeaders = true;
                        break;
                    end
                end
            end
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
                if header:find("item") and not (header:find("note") or header:find("tier")) then
                    self.Columns[i] = "Item";
                elseif (header:find("name") or header:find("player")) and not (header:find("member") or header:find("guild") or header:find("class") or header:find("race") or header:find("group")) then
                    self.Columns[i] = "Player";
                elseif header:find("count") or header:find("quantity") then
                    -- Search for meaningful numbers first (basically where count > 1)
                    for _, row in ipairs(self.Rows) do
                        if row[i] and ParseMultireserveCount(row[i]) then
                            self.Columns[i] = "Count";
                            break;
                        end
                    end
                elseif header:find("delta") or header:find("reserves?%s*bonus") or header:find("bonus%s*reserves?") or header:find("extra%s*reserves?") then
                    self.Columns[i] = "Extra Reserves"
                elseif header:find("class") then
                    self.Columns[i] = "Class";
                elseif header:find("roll%s*bonus") then
                    self.Columns[i] = "Roll Bonus";
                elseif header:find("character_is_alt") or header:find("is_offspec") or header:find("received_at") then -- ThatsMyBis export
                    self.Columns[i] = "Do Not Reserve";
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
            frame = LootReserve.LibDD:Create_UIDropDownMenu(nil, list);
            table.insert(list.Columns, frame);
            
            frame.field   = "Columns";
            frame.values  = "|cFF808080Unused|r=Unused$Player$Item$Count$Class$Extra Reserves$Roll Bonus$Do Not Reserve";
            frame.width   = 75;
            frame.justify = "LEFT";
            
            frame:SetHeight(32);
            
            frame.Header = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
            frame.Header:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 25, 0);
            
            frame.Rows = CreateFrame("Frame", nil, frame);
            frame.Rows:SetClipsChildren(true);
            frame.Rows:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 25, 0);
            frame.Rows:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -25, 0);
            frame.Rows:SetPoint("BOTTOM", list);
            frame.Rows.Text = frame.Rows:CreateFontString(nil, nil, "GameFontWhiteSmall");
            frame.Rows.Text:SetJustifyH("LEFT");
            frame.Rows.Text:SetJustifyV("TOP");
            frame.Rows.Text:SetPoint("TOPLEFT", frame.Rows);
            
            if #list.Columns == 1 then
                frame:SetPoint("TOPLEFT", list, "TOPLEFT", -10, -12);
            else
                frame:SetPoint("TOPLEFT", list.Columns[#list.Columns - 1], "TOPRIGHT", -25, 0);
            end
            frame = list.Columns[i];
        end
        frame.name = self.Headers and #self.Headers >= i and self.Headers[i] or format("Column %d", i);
        frame.index = i;
        self:InitDropDown(frame);
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
            row.Delta = nil;
            row.Class = nil;
            row.Bonus = nil;
            row.Ignore = nil;
            for i, column in ipairs(self.Columns) do
                if column == "Count" and row[i] then
                    if not row.Count then
                        row.Count = ParseMultireserveCount(row[i]);
                    else
                        return "Only one column can be marked as \"Count\"";
                    end
                end
                if column == "Extra Reserves" and row[i] then
                    if not row.Delta then
                        row.Delta = ParseNumber(row[i]);
                    else
                        return "Only one column can be marked as \"Extra Reserves\"";
                    end
                end
                if column == "Class" and row[i] then
                    if not row.Class then
                        row.Class = ParseClass(row[i]);
                    else
                        return "Only one column can be marked as \"Class\"";
                    end
                end
                if column == "Roll Bonus" and row[i] then
                    if not row.Bonus then
                        row.Bonus = ParseNumber(row[i]);
                    else
                        return "Only one column can be marked as \"Roll Bonus\"";
                    end
                end
                if column == "Do Not Reserve" and row[i] then
                    if not row.Ignore then
                        if type(row[i]) == "string" then
                            local text = row[i]:lower();
                            if text ~= "" and text ~= "false" and text ~= "no" then
                                row.Ignore = true;
                            end
                        elseif row[i] ~= 0 then
                            row.Ignore = true;
                        end
                    end
                end
            end
        end
        
        if self.ItemNameMatch then
            for _, row in ipairs(self.Rows) do
                if not row.Ignore then
                    for _, itemColumn in ipairs(itemColumns) do
                        local itemID = row[itemColumn];
                        if itemID and itemID ~= 0 and itemID ~= "" then
                            if type(itemID) == "string" then
                                LootReserve.ItemSearch:Load();
                                if not LootReserve.ItemSearch.FullCache:IsComplete() then
                                    LootReserve.ItemSearch.FullCache:SetSpeed(LootReserve.ItemSearch.ZoomSpeed);
                                    
                                    if not self.PendingInputOptionsUpdate then
                                        self.PendingInputOptionsUpdate = true;
                                        C_Timer.After(0.1, function()
                                            self.PendingInputOptionsUpdate = false;
                                            if LootReserveServerImportWindow:IsShown() then
                                                self:InputOptionsUpdated();
                                            end
                                        end);
                                    end
                                    return format("Creating item name database... (%d%%)|n|nInstall/Update ItemCache to remember the item database between sessions", LootReserve.ItemSearch.FullCache:GetProgress(0));
                                end
                            end
                        end
                    end
                end
            end
        end


        local simplifiedRaidNames        = nil;
        local simplifiedRaidNamesByClass = nil;
        if self.MatchPlayerNames then
            simplifiedRaidNames        = { };
            simplifiedRaidNamesByClass = { };
            LootReserve:ForEachRaider(function(name)
                local simplified = LootReserve:SimplifyName(name);
                local class      = select(3, LootReserve:UnitClass(name));
                local existing   = simplifiedRaidNames[simplified];
                if not simplifiedRaidNamesByClass[class] then
                    simplifiedRaidNamesByClass[class] = { };
                end
                local existingByClass = simplifiedRaidNamesByClass[class][simplified];
                if not existing then
                    simplifiedRaidNames[simplified] = name;
                elseif type(existing) == "string" then
                    simplifiedRaidNames[simplified] = 2;
                elseif type(existing) == "number" then
                    simplifiedRaidNames[simplified] = existing + 1;
                end
                if not existingByClass then
                    simplifiedRaidNamesByClass[class][simplified] = name;
                elseif type(existingByClass) == "string" then
                    simplifiedRaidNamesByClass[class][simplified] = 2;
                elseif type(existingByClass) == "number" then
                    simplifiedRaidNamesByClass[class][simplified] = existingByClass + 1;
                end
            end);
        end

        local itemReserveCount = { };
        local itemReserveCountByPlayer = { };

        local function ParseRow(player, nameMatchResult, itemID, itemName, row, itemCount, playerCount)
            if player and (LootReserve:IsPlayerOnline(player) ~= nil or not self.SkipNotInRaid) then

                if not self.Members[player] then
                    self.Members[player] =
                    {
                        NameMatchResult = nameMatchResult,
                        ReservedItems   = { },
                        RollBonus       = setmetatable({ }, { __index = function() return 0 end }),
                        InvalidReasons  = { },
                        ReservesDelta   = nil,
                        Class           = nil,
                    };
                end
                local member = self.Members[player];
                if nameMatchResult and not member.NameMatchResult then
                    member.NameMatchResult = nameMatchResult;
                end
                for i = 1, (row.Count or 1) * itemCount * playerCount do
                    table.insert(member.ReservedItems, itemID);
                    if row.Bonus and row.Bonus ~= 0 then
                        member.RollBonus[itemID] = row.Bonus;
                    end
                    itemReserveCount[itemID] = (itemReserveCount[itemID] or 0) + 1;
                    itemReserveCountByPlayer[player] = itemReserveCountByPlayer[player] or { };
                    itemReserveCountByPlayer[player][itemID] = (itemReserveCountByPlayer[player][itemID] or 0) + 1;
                    member.ReservesDelta = member.ReservesDelta or row.Delta;
                    local conditions = LootReserve.Server:GetNewSessionItemConditions()[itemID];
                    local class = select(3, UnitClass(player)) or row.Class;
                    member.Class = member.Class or class;
                    local className = class and select(2, LootReserve:GetClassInfo(class));
                    if itemID == 0 then
                        member.InvalidReasons[#member.ReservedItems] = "Item with the name \"" .. itemName .. "\" was not be found|nor it can't be reserved due to session settings.";
                    elseif not (LootReserve.Data:IsItemInCategories(itemID, LootReserve.Server.NewSessionSettings.LootCategories) or conditions and conditions.Custom) or not LootReserve.ItemConditions:TestServer(itemID) then
                        member.InvalidReasons[#member.ReservedItems] = "Item can't be reserved due to session settings.|nChange to the appropriate raid map or add this item as a custom item.";
                    elseif conditions and conditions.ClassMask and class and not LootReserve.ItemConditions:TestClassMask(conditions.ClassMask, class) then
                        member.InvalidReasons[#member.ReservedItems] = player .. "'s class cannot reserve this item.|nEdit the raid loot to change the class restrictions on this item, or it will not be imported.";
                    elseif LootReserve.Server.NewSessionSettings.Equip and className and not LootReserve.ItemConditions:IsItemUsable(itemID, className) then
                        member.InvalidReasons[#member.ReservedItems] = player .. "'s class cannot reserve this item.|nEdit the raid loot to change the class restrictions on this item, or it will not be imported.";
                    elseif conditions and conditions.Limit and itemReserveCount[itemID] > conditions.Limit then
                        member.InvalidReasons[#member.ReservedItems] = "This item has hit the limit of how many times it can be reserved.|nEdit the raid loot to increase or remove the limit on this item, or it will not be imported.";
                    elseif #member.ReservedItems > LootReserve.Server.NewSessionSettings.MaxReservesPerPlayer + (member.ReservesDelta or 0) then
                        member.InvalidReasons[#member.ReservedItems] = "Player has more reserved items than allowed.|nIncrease the number of allowed reserves, or this item will not be imported.";
                    elseif itemReserveCountByPlayer[player][itemID] > LootReserve.Server.NewSessionSettings.Multireserve then
                        member.InvalidReasons[#member.ReservedItems] = "Player has reserved this item more times than allowed.|nIncrease the number of allowed multireserves, or this item will not be imported.";
                    end
                end
            end
        end

        for _, row in ipairs(self.Rows) do
            if not row.Ignore then
                row.Players   = { };
                row.ItemIDs   = { };
                row.ItemNames = { };
                for _, playerColumn in ipairs(playerColumns) do
                    local player = row[playerColumn];
                    if type(player) ~= "string" then
                        player = nil;
                    end

                    if player then
                        row.Players[player] = row.Players[player] and row.Players[player] + 1 or 1;
                    end
                end
                    
                for _, itemColumn in ipairs(itemColumns) do
                    local itemID = row[itemColumn];


                    if itemID and itemID ~= 0 and itemID ~= "" then
                        -- Transform Item Name -> Item ID
                        if type(itemID) == "string" then
                            if self.ItemNameMatch then
                                local query = LootReserve.ItemCache:FormatSearchText(itemID);
                                local results = LootReserve.ItemCache:Filter(function(item) return item:Matches(query) end)
                                if #results == 1 then
                                    itemID = results[1]:GetID();
                                end

                                if type(itemID) == "string" then
                                    itemID = 0;
                                end
                                if LootReserve.Data:IsTokenReward(itemID) and not LootReserve.Server:GetNewSessionItemConditions()[itemID] then
                                    itemID = LootReserve.Data:GetToken(itemID)
                                end
                                if not row.ItemNames[itemID] then
                                    row.ItemNames[itemID] = {Count = 0, Name = row[itemColumn]};
                                end
                                row.ItemNames[itemID].Count = row.ItemNames[itemID].Count + 1;
                            end
                        else
                            if LootReserve.Data:IsTokenReward(itemID) then
                                itemID = LootReserve.Data:GetToken(itemID)
                            end
                            row.ItemIDs[itemID] = row.ItemIDs[itemID] and row.ItemIDs[itemID] + 1 or 1;
                        end
                    end
                end

                for player, playerCount in pairs(row.Players) do
                    
                    local nameMatchResult = nil;
                    if player and #player > 0 then
                        player = LootReserve:Player(LootReserve:NormalizeName(player));
                        if self.MatchPlayerNames and LootReserve:IsPlayerOnline(player) == nil then
                            if row.Class then
                                local simplified = simplifiedRaidNamesByClass[row.Class] and simplifiedRaidNamesByClass[row.Class][LootReserve:SimplifyName(player)];
                                if not simplified then
                                    nameMatchResult = "not in raid";
                                elseif type(simplified) == "string" then
                                    player = simplified;
                                elseif type(simplified) == "number" then
                                    nameMatchResult = "ambiguous name";
                                end
                            else
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
                        for itemID, itemCount in pairs(row.ItemIDs) do
                            if not row.ItemNames[itemID] or row.ItemNames[itemID].Count == 1 then
                                ParseRow(player, nameMatchResult, itemID, itemID, row, itemCount, playerCount);
                            end
                        end
                        for itemID, itemData in pairs(row.ItemNames) do
                            if not row.ItemIDs[itemID] or (row.ItemIDs[itemID] == 1 and itemData.Count > 1) then
                                ParseRow(player, nameMatchResult, itemID, itemData.Name, row, itemData.Count, playerCount);
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
            for i, itemID in ipairs(member.ReservedItems) do
                if not member.InvalidReasons[i] then
                    LootReserve.Server.NewSessionSettings.ImportedMembers[player] = LootReserve.Server.NewSessionSettings.ImportedMembers[player] or {
                        Class         = member.Class,
                        ReservesLeft  = nil,
                        ReservesDelta = 0,
                        ReservedItems = { },
                        RollBonus     = member.RollBonus,
                        Locked        = nil,
                        OptedOut      = nil,
                    };
                    table.insert(LootReserve.Server.NewSessionSettings.ImportedMembers[player].ReservedItems, itemID);
                end
            end
            if member.ReservesDelta then
                LootReserve.Server.NewSessionSettings.ImportedMembers[player] = LootReserve.Server.NewSessionSettings.ImportedMembers[player] or {
                    Class         = member.Class,
                    ReservesLeft  = nil,
                    ReservesDelta = 0,
                    ReservedItems = { },
                    RollBonus     = member.RollBonus,
                    Locked        = nil,
                    OptedOut      = nil,
                };
                LootReserve.Server.NewSessionSettings.ImportedMembers[player].ReservesDelta = member.ReservesDelta
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
    self.Window.TitleText:SetText("LootReserve Host - Import");
    LootReserve:SetResizeBounds(self.Window, LootReserve:IsCrossRealm() and 490 or 390, 460);
    self.Window.InputOptions.Input.MatchPlayerNames:SetChecked(self.MatchPlayerNames);
    self:InputUpdated();
end
