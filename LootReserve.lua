local addon, ns = ...;

LootReserve = LibStub("AceAddon-3.0"):NewAddon("LootReserve", "AceComm-3.0");
LootReserve.Version = GetAddOnMetadata(addon, "Version");
LootReserve.MinAllowedVersion = GetAddOnMetadata(addon, "X-Min-Allowed-Version");
LootReserve.LatestKnownVersion = LootReserve.Version;
LootReserve.Enabled = true;

LootReserve.EventFrame = CreateFrame("Frame", nil, UIParent);
LootReserve.EventFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0);
LootReserve.EventFrame:SetSize(0, 0);
LootReserve.EventFrame:Show();

LootReserve.ItemCacheFrame = CreateFrame("Frame", nil, UIParent);
LootReserve.ItemCacheFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0);
LootReserve.ItemCacheFrame:SetSize(0, 0);
LootReserve.ItemCacheFrame:Show();

LootReserveCharacterSave =
{
    Client =
    {
        CharacterFavorites = nil,
    },
    Server =
    {
        CurrentSession = nil,
        RequestedRoll  = nil,
        RollHistory    = nil,
        RecentLoot     = nil,
    },
};
LootReserveGlobalSave =
{
    Client =
    {
        Settings        = nil,
        GlobalFavorites = nil,
    },
    Server =
    {
        NewSessionSettings = nil,
        Settings           = nil,
        GlobalProfile      = nil,
    },
};

StaticPopupDialogs["LOOTRESERVE_GENERIC_ERROR"] =
{
    text         = "%s",
    button1      = CLOSE,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
};

LOOTRESERVE_BACKDROP_BLACK_4 =
{
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
};

SLASH_LOOTRESERVE1 = "/lootreserve";
SLASH_LOOTRESERVE2 = "/reserve";
SLASH_LOOTRESERVE3 = "/res";
function SlashCmdList.LOOTRESERVE(command)
    command = command:lower();

    if command == "" then
        LootReserve.Client.Window:SetShown(not LootReserve.Client.Window:IsShown());
    elseif command == "server" then
        LootReserve:ToggleServerWindow(not LootReserve.Server.Window:IsShown());
    elseif command == "roll" or command == "rolls" then
        LootReserve:ToggleServerWindow(not LootReserve.Server.Window:IsShown(), true);
    end
end

local pendingToggleServerWindow = nil;
local pendingLockdownHooked = nil;
function LootReserve:ToggleServerWindow(state, rolls)
    if InCombatLockdown() and LootReserve.Server.Window:IsProtected() then
        pendingToggleServerWindow = { state, rolls };
        if not pendingLockdownHooked then
            pendingLockdownHooked = true;
            self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
                if pendingToggleServerWindow then
                    local params = pendingToggleServerWindow;
                    pendingToggleServerWindow = nil;
                    self:ToggleServerWindow(unpack(params));
                end
            end);
        end
        self:PrintMessage("Server window will %s once you're out of combat", state and "open" or "close");
        return;
    end

    if rolls then
        self.Server.Window:Show();
        self.Server:OnWindowTabClick(self.Server.Window.TabRolls);
    else
        self.Server.Window:SetShown(state);
    end
end

function LootReserve:OnInitialize()
    LootReserve.Client:Load();
    LootReserve.Server:Load();
end

function LootReserve:OnEnable()
    LootReserve.Comm:StartListening();

    local function Startup()
        LootReserve.Server:Startup();
        -- Query other group members about their addon versions and request server session info if any
        LootReserve.Client:SearchForServer(true);
    end

    LootReserve:RegisterEvent("GROUP_JOINED", function()
        -- Load client and server after WoW client restart
        -- Server session should not normally exist when the player is outside of any raid groups, so restarting it upon regular group join shouldn't break anything
        -- With a delay, due to possible name cache issues
        C_Timer.After(1, Startup);
    end);

    -- Load client and server after UI reload
    -- This should be the only case when a player is already detected to be in a group at the time of addon loading
    Startup();
end

function LootReserve:OnDisable()
end

function LootReserve:ShowError(fmt, ...)
    StaticPopup_Show("LOOTRESERVE_GENERIC_ERROR", "|cFFFFD200LootReserve|r|n|n" .. format(fmt, ...) .. "|n ");
end

function LootReserve:PrintError(fmt, ...)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD200LootReserve: |r" .. format(fmt, ...), 1, 0, 0);
end

function LootReserve:PrintMessage(fmt, ...)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD200LootReserve: |r" .. format(fmt, ...), 1, 1, 1);
end

function LootReserve:debug(...)
    -- Curseforge automatic packaging will comment this out
    -- https://support.curseforge.com/en/support/solutions/articles/9000197281-automatic-packaging
    --@debug@
    print("[DEBUG] ", ...);
    --@end-debug@
end

function LootReserve:debugFunc(func)
    -- Curseforge automatic packaging will comment this out
    -- https://support.curseforge.com/en/support/solutions/articles/9000197281-automatic-packaging
    --@debug@
    func();
    --@end-debug@
end

function LootReserve:RegisterUpdate(handler)
    LootReserve.EventFrame:HookScript("OnUpdate", function(self, elapsed)
        handler(elapsed);
    end);
end

function LootReserve:RegisterEvent(...)
    if not LootReserve.EventFrame.RegisteredEvents then
        LootReserve.EventFrame.RegisteredEvents = { };
        LootReserve.EventFrame:SetScript("OnEvent", function(self, event, ...)
            local handlers = self.RegisteredEvents[event];
            if handlers then
                for _, handler in ipairs(handlers) do
                    handler(...);
                end
            end
        end);
    end

    local params = select("#", ...);

    local handler = select(params, ...);
    if type(handler) ~= "function" then
        error("LootReserve:RegisterEvent: The last passed parameter must be the handler function");
        return;
    end

    for i = 1, params - 1 do
        local event = select(i, ...);
        if type(event) == "string" then
            LootReserve.EventFrame:RegisterEvent(event);
            LootReserve.EventFrame.RegisteredEvents[event] = LootReserve.EventFrame.RegisteredEvents[event] or { };
            table.insert(LootReserve.EventFrame.RegisteredEvents[event], handler);
        else
            error("LootReserve:RegisterEvent: All but the last passed parameters must be event names");
        end
    end
end

function LootReserve:RunWhenItemCached(itemID, func, ...)
    if func(...) then
        local args = {...};
        if not LootReserve.ItemCacheFrame.Items then
            LootReserve.ItemCacheFrame.Items = { };
            LootReserve.ItemCacheFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED");
            LootReserve.ItemCacheFrame:SetScript("OnEvent", function(self, event, itemID, success)
                if not success then return; end
                local handlers = self.Items[itemID];
                if handlers then
                    for i = #handlers, 1 do
                        if handlers[i](unpack(args)) then
                            table.remove(handlers, i);
                        end
                    end
                end
            end);
        end
        if not LootReserve.ItemCacheFrame.Items[itemID] then
            LootReserve.ItemCacheFrame.Items[itemID] = { };
        end
        table.insert(LootReserve.ItemCacheFrame.Items[itemID], function() return func(unpack(args)); end);
    end
end

function LootReserve:OpenMenu(menu, menuContainer, anchor)
    if UIDROPDOWNMENU_OPEN_MENU == menuContainer then
        CloseMenus();
        return;
    end

    local function FixMenu(menu)
        for _, item in ipairs(menu) do
            if item.notCheckable == nil then
                item.notCheckable = item.checked == nil;
            end
            if item.keepShownOnClick == nil and item.checked ~= nil then
                item.keepShownOnClick = true;
            end
            if item.tooltipText and item.tooltipTitle == nil then
                item.tooltipTitle = item.text;
            end
            if item.tooltipText and item.tooltipOnButton == nil then
                item.tooltipOnButton = true;
            end
            if item.hasArrow == nil and item.menuList then
                item.hasArrow = true;
            end
            if item.keepShownOnClick == nil and item.menuList then
                item.keepShownOnClick = true;
            end
            if item.menuList then
                FixMenu(item.menuList);
            end
        end
    end
    FixMenu(menu);
    EasyMenu(menu, menuContainer, anchor, 0, 0, "MENU");
end

function LootReserve:OpenSubMenu(...)
    for submenu = 1, select("#", ...) do
        local arg1 = select(submenu, ...);
        local opened = false;
        for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
            local button = _G["DropDownList"..submenu.."Button"..i];
            if button and button.arg1 == arg1 then
                local arrow = _G[button:GetName().."ExpandArrow"];
                if arrow then
                    arrow:Click();
                    opened = true;
                end
            end
        end
        if not opened then
            return false;
        end
    end
    return true;
end

function LootReserve:ReopenMenu(button, ...)
    CloseMenus();
    button:Click();
    self:OpenSubMenu(...);
end

-- Used to prevent LootReserve:SendChatMessage from breaking a hyperlink into multiple segments if the message is too long
-- Use it if a text of undetermined length preceeds the hyperlink
-- GOOD: format("%s win %s", strjoin(", ", players), LootReserve:FixLink(link)) - players might contain so many names that the message overflows 255 chars limit
--  BAD: format("%s won by %s", LootReserve:FixLink(link), strjoin(", ", players)) - link is always early in the message and will never overflow the 255 chars limit
function LootReserve:FixLink(link)
    return link:gsub(" ", "\1");
end

function LootReserve:SendChatMessage(text, channel, target)
    if channel == "RAID_WARNING" and not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        channel = "RAID";
    end
    if channel == "RAID" and not IsInRaid() then
        channel = "PARTY";
    end
    if channel == "PARTY" and not IsInGroup() then
        channel, target = "WHISPER", LootReserve:Me();
    end
    if target and not LootReserve:IsPlayerOnline(target) then return; end
    local function Send(text)
        if #text > 0 then
            if ChatThrottleLib then
                ChatThrottleLib:SendChatMessage("NORMAL", self.Comm.Prefix, text:gsub("\1", " "), channel, nil, target);
            else
                SendChatMessage(text:gsub("\1", " "), channel, nil, target);
            end
        end
    end

    if #text <= 250 then
        Send(text);
    else
        text = text .. " ";
        local accumulator = "";
        for word in text:gmatch("[^ ]- ") do
            if #accumulator + #word > 250 then
                Send(self:StringTrim(accumulator));
                accumulator = "";
            end
            accumulator = accumulator .. word;
        end
        Send(self:StringTrim(accumulator));
    end
end

function LootReserve:GetCurrentExpansion()
    local version = GetBuildInfo();
    local expansion, major, minor = strsplit(".", version);
    return tonumber(expansion) - 1;
end

function LootReserve:IsCrossRealm()
    return self:GetCurrentExpansion() == 0;
    -- This doesn't really work, because even in non-connected realms UnitFullName ends up returning your realm name,
    -- and we can't use UnitName either, because that one NEVER returns a realm for "player". WTB good API, 5g.
    --[[
    if self.CachedIsCrossRealm == nil then
        local name, realm = UnitFullName("player");
        if name then
            self.CachedIsCrossRealm = realm ~= nil;
        end
    end
    return self.CachedIsCrossRealm;
    ]]
end

function LootReserve:GetNumClasses()
    return 11;
end

function LootReserve:GetClassInfo(classID)
    local info = C_CreatureInfo.GetClassInfo(classID);
    if info then
        return info.className, info.classFile, info.classID;
    end
end

function LootReserve:Player(player)
    if not self:IsCrossRealm() then
        return Ambiguate(player, "short");
    end

    local name, realm = strsplit("-", player);
    if not realm then
        realm = GetNormalizedRealmName();
    end
    return name .. "-" .. realm;
end

function LootReserve:Me()
    return self:Player(UnitName("player"));
end

function LootReserve:IsMe(player)
    return self:IsSamePlayer(player, self:Me());
end

function LootReserve:IsSamePlayer(a, b)
    return self:Player(a) == self:Player(b);
end

function LootReserve:IsPlayerOnline(player)
    return self:ForEachRaider(function(name, _, _, _, _, _, _, online)
        if self:IsSamePlayer(name, player) then
            return online or false;
        end
    end);
end

local function LootReserve_UnitInRaid(player)
    if not LootReserve:IsCrossRealm() then
        return UnitInRaid(player);
    end

    return IsInRaid() and LootReserve:ForEachRaider(function(name, _, _, _, className, classFilename, _, online)
        if LootReserve:IsSamePlayer(name, player) then
            return true;
        end
    end);
end

local function LootReserve_UnitInParty(player)
    if not LootReserve:IsCrossRealm() then
        return UnitInParty(player);
    end

    return IsInGroup() and not IsInRaid() and LootReserve:ForEachRaider(function(name, _, _, _, className, classFilename, _, online)
        if LootReserve:IsSamePlayer(name, player) then
            return true;
        end
    end);
end

function LootReserve:UnitInGroup(player)
    if not self:IsCrossRealm() then
        if IsInRaid() then
            return LootReserve_UnitInRaid(player) and true;
        elseif IsInGroup() then
            return LootReserve_UnitInParty(player);
        else
            return LootReserve:IsMe(player);
        end
    end

    return self:ForEachRaider(function(name)
        if self:IsSamePlayer(name, player) then
            return true;
        end
    end);
end

function LootReserve:UnitClass(player)
    if not self:IsCrossRealm() then
        return UnitClass(player);
    end

    return self:ForEachRaider(function(name, _, _, _, className, classFilename)
        if self:IsSamePlayer(name, player) then
            return className, classFilename, LootReserve.Constants.ClassFilenameToClassID[classFilename];
        end
    end);
end

function LootReserve:UnitRace(player)
    if not self:IsCrossRealm() then
        return UnitRace(player);
    end

    return self:ForEachRaider(function(name)
        if self:IsSamePlayer(name, player) then
            local unitID = self:GetGroupUnitID(player);
            if unitID then
                return UnitRace(unitID);
            end
        end
    end);
end

local function GetPlayerClassColor(player, dim, class)
    local className, classFilename, classId = LootReserve:UnitClass(player);
    if class then
        className, classFilename, classId = LootReserve:GetClassInfo(class);
    end
    if classFilename then
        local colors = RAID_CLASS_COLORS[classFilename];
        if colors then
            if dim then
                local r, g, b, a = colors:GetRGBA();
                return format("FF%02X%02X%02X", r * 128, g * 128, b * 128);
            else
                return colors.colorStr;
            end
        end
    end
    return dim and "FF404040" or "FF808080";
end

local function GetRaidUnitID(player)
    for i = 1, MAX_RAID_MEMBERS do
        local unit = UnitName("raid" .. i);
        if unit and LootReserve:IsSamePlayer(LootReserve:Player(unit), player) then
            return "raid" .. i;
        end
    end

    if LootReserve:IsMe(player) then
        return "player";
    end
end

local function GetPartyUnitID(player)
    for i = 1, MAX_PARTY_MEMBERS do
        local unit = UnitName("party" .. i);
        if unit and LootReserve:IsSamePlayer(LootReserve:Player(unit), player) then
            return "party" .. i;
        end
    end

    if LootReserve:IsMe(player) then
        return "player";
    end
end

function LootReserve:GetGroupUnitID(player)
    if IsInRaid() then
        return GetRaidUnitID(player);
    elseif IsInGroup() then
        return GetPartyUnitID(player);
    elseif self:IsMe(player) then
        return "player"
    end
end

function LootReserve:ColoredPlayer(player, class)
    local name, realm = strsplit("-", player);
    return realm and format("|c%s%s|r|c%s-%s|r", GetPlayerClassColor(player, false, class), name, GetPlayerClassColor(player, true, class), realm)
                  or format("|c%s%s|r",          GetPlayerClassColor(player, false, class), player);
end

function LootReserve:ForEachRaider(func)
    if not IsInGroup() then
        local className, classFilename = UnitClass("player");
        local raceName,  raceFilename  = UnitRace("player");
        return func(self:Me(), 0, 1, UnitLevel("player"), className, classFilename, nil, true, UnitIsDead("player"), raceName, raceFilename);
    end

    for i = 1, MAX_RAID_MEMBERS do
        local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i);
        if name then
            local result, a, b = func(self:Player(name), rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole);
            if result ~= nil then
                return result, a, b;
            end
        else
            break;
        end
    end
end

local charSimplifications =
{
    ["a"  ] = "[ÀÁÂÃÄÅàáâãäåĀāĂăĄąǍǎǞǟǠǡǺǻȀȁȂȃɐɑɒ]",
    ["ae" ] = "[ÆæǢǣǼǽ]",
    ["b"  ] = "[ƀƁƂƃɓʙ]",
    ["c"  ] = "[ÇçĆćĈĉĊċČčƇƈɔɕʗ]",
    ["d"  ] = "[ĎďĐđƉƊƋƌɖɗ]",
    ["dz" ] = "[ǄǅǆǱǲǳʣʥ]",
    ["e"  ] = "[ÈÉÊËèéêëĒēĔĕĖėĘęĚěƎƐǝȄȅȆȇɘəɚɛɜɝɞʚ]",
    ["eth"] = "[ð]",
    ["f"  ] = "[Ƒƒɟ]",
    ["g"  ] = "[ĜĝĞğĠġĢģƓǤǥǦǧǴǵɠɡɢʛ]",
    ["h"  ] = "[ĤĥĦħɥɦɧʜ]",
    ["i"  ] = "[ÌÍÎÏìíîïĨĩĪīĬĭĮįİıƗǏǐȈȉȊȋɨɩɪ]",
    ["ij" ] = "[Ĳĳ]",
    ["j"  ] = "[Ĵĵǰʄʝ]",
    ["k"  ] = "[ĶķĸƘƙǨǩʞ]",
    ["l"  ] = "[ĹĺĻļĽľĿŀŁłƚɫɬɭʟ]",
    ["lj" ] = "[Ǉǈǉ]",
    ["m"  ] = "[Ɯɯɰɱ]",
    ["n"  ] = "[ÑñŃńŅņŇňŉŊŋƝƞɲɳɴ]",
    ["nj" ] = "[Ǌǋǌ]",
    ["o"  ] = "[ÒÓÔÕÖØòóôõöøŌōŎŏŐőƆƟƠơǑǒǪǫǬǭǾǿȌȍȎȏɵ]",
    ["oe" ] = "[Œœɶ]",
    ["oi" ] = "[Ƣƣ]",
    ["p"  ] = "[ÞþƤƥ]",
    ["q"  ] = "[ʠ]",
    ["r"  ] = "[ŔŕŖŗŘřƦȐȑȒȓɹɺɻɼɽɾɿʀʁ]",
    ["s"  ] = "[ŚśŜŝŞşŠšſʂ]",
    ["ss" ] = "[ß]",
    ["t"  ] = "[ŢţŤťŦŧƫƬƭƮʇʈ]",
    ["u"  ] = "[ÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųƯưǓǔǕǖǗǘǙǚǛǜȔȕȖȗʉʊ]",
    ["v"  ] = "[Ʋʋʌ]",
    ["w"  ] = "[Ŵŵʍ]",
    ["y"  ] = "[ÝýÿŶŷŸƳƴʎʏ]",
    ["z"  ] = "[ŹźŻżŽžƵƶʐʑ]",
};

local simplificationMapping = { }
for replacement, pattern in pairs(charSimplifications) do
    local len = pattern:utf8len();
    for i = 1, len do
        local char = pattern:utf8sub(i, i);
        if char ~= "[" and char ~= "]" then
            simplificationMapping[char] = replacement;
        end
    end
end

function LootReserve:NormalizeName(name)
    for i = 1, name:utf8len() do
        if name:utf8sub(i, i) == "-" then
            return name:utf8sub(1, 1):utf8upper() .. name:utf8sub(2, i - 1):utf8lower() .. name:utf8sub(i);
        end
    end
    return name:utf8sub(1, 1):utf8upper() .. name:utf8sub(2):utf8lower();
end

function LootReserve:SimplifyName(name)
    for i = 1, name:utf8len() do
        if name:utf8sub(i, i) == "-" then
            return self:NormalizeName(name:utf8sub(1, i - 1):utf8replace(simplificationMapping));
        end
    end
    return self:NormalizeName(name:utf8replace(simplificationMapping));
end

function LootReserve:GetNumGroupMembers(func)
    local count = 0;
    self:ForEachRaider(function() count = count + 1; end);
    return count;
end

function LootReserve:IsItemBoP(itemID)
    return select(14, GetItemInfo(itemID)) == 1;
end

function LootReserve:IsTradeableItem(bag, slot)
    return not C_Item.IsBound(ItemLocation:CreateFromBagAndSlot(bag, slot)) or LootReserve:IsItemSoulboundTradeable(bag, slot);
end

function LootReserve:GetTradeableItemCount(item)
    local count = 0;
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag);
        if slots > 0 then
            for slot = 1, slots do
                local _, quantity, _, _, _, _, bagItem = GetContainerItemInfo(bag, slot);
                bagItem = bagItem and LootReserve.Item(bagItem);
                if bagItem and bagItem == item and self:IsTradeableItem(bag, slot) then
                    count = count + quantity;
                end
            end
        end
    end
    return count;
end

function LootReserve:IsItemSoulboundTradeable(bag, slot)
    if not self.TooltipScanner then
        self.TooltipScanner = CreateFrame("GameTooltip", "LootReserveTooltipScanner", UIParent, "GameTooltipTemplate");
        self.TooltipScanner:Hide();
    end

    if not self.TooltipScanner.SoulboundTradeable then
        self.TooltipScanner.SoulboundTradeable = BIND_TRADE_TIME_REMAINING:gsub("%.", "%%."):gsub("%%s", "(.+)");
    end

    self.TooltipScanner:SetOwner(UIParent, "ANCHOR_NONE");
    self.TooltipScanner:SetBagItem(bag, slot);
    for i = 50, 1, -1 do
        local line = _G[self.TooltipScanner:GetName() .. "TextLeft" .. i];
        if line and line:GetText() and line:GetText():match(self.TooltipScanner.SoulboundTradeable) then
            self.TooltipScanner:Hide();
            return true;
        end
    end
    self.TooltipScanner:Hide();
    return false;
end

function LootReserve:IsItemBeingTraded(item)
    for i = 1, 6 do
        local link = GetTradePlayerItemLink(i);
        local tradeItem = LootReserve.Item(link);
        if tradeItem:GetID() and tradeItem == item then
            return true;
        end
    end
    return false;
end

function LootReserve:PutItemInTrade(bag, slot)
    for i = 1, 6 do
        if not GetTradePlayerItemInfo(i) then
            PickupContainerItem(bag, slot);
            ClickTradeButton(i);
            return true;
        end
    end
    return false;
end

function LootReserve:GetItemDescription(itemID)
    local name, link, _, _, _, itemType, itemSubType, _, equipLoc, texture, _, _, _, bindType = GetItemInfo(itemID);
    local itemText = "";
    if not itemType then return; end
    
    if LootReserve.Constants.RedundantSubTypes[itemSubType] then
        itemText = LootReserve.Constants.RedundantSubTypes[itemSubType];
    elseif itemType == ARMOR then
        if itemSubType == MISCELLANEOUS or equipLoc == "INVTYPE_CLOAK" then
            itemText = itemText .. (_G[equipLoc] or "");
        else
            itemText = itemText .. itemSubType .. " " .. (_G[equipLoc] or "");
        end
    elseif itemType == WEAPON then
        itemText = itemText .. (_G[equipLoc] and (_G[equipLoc] .. " ") or "") .. (LootReserve.Constants.WeaponTypeNames[itemSubType] or "");
    elseif itemType == MISCELLANEOUS then
        if itemSubType == "Junk" or itemSubType == "Other" then
            itemText = itemType;
        else
           itemText = itemSubType; 
        end
    elseif itemType == "Recipe" then
        if itemSubType == "Book" then
            itemText = itemText .. "Skill Book";
        else
            itemText = itemText .. itemSubType .. " " .. itemType;
        end
    elseif itemType == "Container" then
        itemText = itemText .. (_G[equipLoc] or "");
    elseif itemType == "Trade Goods" then
        itemText = itemText .. "Trade Good";
    else
        itemText = itemText .. itemType;
    end
    
    if bindType == LE_ITEM_BIND_ON_ACQUIRE then
        -- itemText = itemText .. "  (BoP)";
    elseif bindType == LE_ITEM_BIND_ON_EQUIP then
        itemText = itemText .. "  (BoE)";
    elseif itemText == LE_ITEM_BIND_ON_USE then
        itemText = itemText .. "  (BoU)";
    end
    
    return itemText;
end

function LootReserve:IsLootingItem(item)
    for i = 1, GetNumLootItems() do
        local itemID = GetLootSlotInfo(i);
        if itemID then
            local lootItem = LootReserve.Item(GetLootSlotLink(i));
            if lootItem and (type(item) == "table" and lootItem or lootItem:GetID()) == item then
                return i;
            end
        end
    end
end

function LootReserve:TransformSearchText(text)
    text = self:StringTrim(text, "[%s%[%]]");
    text = text:upper();
    text = text:gsub("`", "'"):gsub("´", "'"); -- For whatever reason [`´] doesn't work
    return text;
end

function LootReserve:StringTrim(str, chars)
    chars = chars or "%s"
    return (str:match("^" .. chars .. "*(.-)" .. chars .. "*$"));
end

function LootReserve:FormatToRegexp(fmt)
    return fmt:gsub("%(", "%%("):gsub("%)", "%%)"):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)");
end

function LootReserve:Deepcopy(orig)
    if type(orig) == 'table' then
        local copy = { };
        for orig_key, orig_value in next, orig, nil do
            copy[self:Deepcopy(orig_key)] = self:Deepcopy(orig_value)
        end
        setmetatable(copy, self:Deepcopy(getmetatable(orig)))
        return copy;
    else
        return orig;
    end
end

function LootReserve:TableRemove(tbl, item)
    for index, i in ipairs(tbl) do
        if i == item then
            table.remove(tbl, index);
            return true;
        end
    end
    return false;
end

function LootReserve:Contains(table, item)
    for _, i in ipairs(table) do
        if i == item then
            return true;
        end
    end
    return false;
end

local __orderedIndex = { };
function LootReserve:Ordered(tbl, sorter)
    local function __genOrderedIndex(t)
        local orderedIndex = { };
        for key in pairs(t) do
            table.insert(orderedIndex, key);
        end
        if sorter then
            table.sort(orderedIndex, function(a, b)
                return sorter(t[a], t[b], a, b);
            end);
        else
            table.sort(orderedIndex);
        end
        return orderedIndex;
    end

    local function orderedNext(t, state)
        local key;
        if state == nil then
            __orderedIndex[t] = __genOrderedIndex(t)
            key = __orderedIndex[t][1];
        else
            for i = 1, table.getn(__orderedIndex[t]) do
                if __orderedIndex[t][i] == state then
                    key = __orderedIndex[t][i + 1];
                end
            end
        end

        if key then
            return key, t[key];
        end

        __orderedIndex[t] = nil;
        return
    end

    return orderedNext, tbl, nil;
end

function LootReserve:MakeMenuSeparator()
    return
    {
        text              = "",
        hasArrow          = false,
        dist              = 0,
        isTitle           = true,
        isUninteractable  = true,
        notCheckable      = true,
        iconOnly          = true,
        icon              = "Interface\\Common\\UI-TooltipDivider-Transparent",
        tCoordLeft        = 0,
        tCoordRight       = 1,
        tCoordTop         = 0,
        tCoordBottom      = 1,
        tSizeX            = 0,
        tSizeY            = 8,
        tFitDropDownSizeX = true,
        iconInfo =
        {
            tCoordLeft        = 0,
            tCoordRight       = 1,
            tCoordTop         = 0,
            tCoordBottom      = 1,
            tSizeX            = 0,
            tSizeY            = 8,
            tFitDropDownSizeX = true
        },
    };
end

function LootReserve:RepeatedTable(element, count)
    local result = { };
    for i = 1, count do
        table.insert(result, element);
    end
    return result;
end

function LootReserve:FormatPlayersText(players, colorFunc)
    colorFunc = colorFunc or function(...) return ...; end

    local playersSorted = { };
    local playerNames = { };
    for _, player in ipairs(players) do
        if not playerNames[player] then
           table.insert(playersSorted, player);
           playerNames[player] = true;
        end
    end
    table.sort(playersSorted);

    local text = "";
    for _, player in ipairs(playersSorted) do
        text = text .. (#text > 0 and ", " or "") .. colorFunc(player);
    end
    return text;
end

function LootReserve:FormatPlayersTextColored(players, colorFunc)
    return self:FormatPlayersText(players, function(...) return self:ColoredPlayer(...); end);
end

local function FormatReservesText(players, excludePlayer, colorFunc)
    colorFunc = colorFunc or function(...) return ...; end

    local reservesCount = { };
    for _, player in ipairs(players) do
        if not excludePlayer or player ~= excludePlayer then
            reservesCount[player] = reservesCount[player] and reservesCount[player] + 1 or 1;
        end
    end

    local playersSorted = { };
    for player in pairs(reservesCount) do
        table.insert(playersSorted, player);
    end
    table.sort(playersSorted);

    local text = "";
    for _, player in ipairs(playersSorted) do
        text = text .. (#text > 0 and ", " or "") .. colorFunc(player) .. (reservesCount[player] > 1 and format(" x%d", reservesCount[player]) or "");
    end
    return text;
end

function LootReserve:FormatReservesText(players, excludePlayer)
    return FormatReservesText(players, excludePlayer);
end

function LootReserve:FormatReservesTextColored(players, excludePlayer)
    return FormatReservesText(players, excludePlayer, function(...) return self:ColoredPlayer(...); end);
end

function LootReserve:GetCategoriesText(categories, shortName, delimiter)
    local name = shortName and "NameShort" or "Name";
    delimiter = delimiter or " / ";
    local text = ""
    for i, category in ipairs(categories or { }) do
        text = format("%s%s%s", text, i == 1 and "" or delimiter, LootReserve.Data.Categories[category][name]);
    end
    return text;
end

local function GetReservesData(players, me, colorFunc)
    local reservesCount = { };
    for _, player in ipairs(players) do
        reservesCount[player] = reservesCount[player] and reservesCount[player] + 1 or 1;
    end

    local uniquePlayers = { };
    for player in pairs(reservesCount) do
        table.insert(uniquePlayers, player);
    end

    return FormatReservesText(players, me, colorFunc), me and reservesCount[me] or 0, #uniquePlayers, #players;
end

function LootReserve:GetReservesData(players, me)
    return GetReservesData(players, me);
end

function LootReserve:GetReservesDataColored(players, me)
    return GetReservesData(players, me, function(...) return self:ColoredPlayer(...); end);
end

local function GetReservesString(server, isUpdate, link, reservesText, myReserves, uniqueReservers, reserves)
    local blind, multireserve;
    if server then
        blind = LootReserve.Server.CurrentSession and LootReserve.Server.CurrentSession.Settings.Blind;
        multireserve = LootReserve.Server.CurrentSession and LootReserve.Server.CurrentSession.Settings.Multireserve;

        if blind then
            return "";
        end
    else
        blind = LootReserve.Client.Blind;
        multireserve = LootReserve.Client.Multireserve;
    end

    if uniqueReservers <= 1 then
        if myReserves > 0 then
            return format("You are%s%s reserving %s%s.%s",
                isUpdate and " now" or "",
                blind and "" or " the only player",
                link,
                (isUpdate or blind) and "" or " thus far",
                multireserve > 1 and format(" You have %d %s on this item.", myReserves, myReserves == 1 and "reserve" or "reserves") or "");
        else
           return "";
        end
    elseif myReserves > 0 then
        local otherReserves = reserves - myReserves;
        local otherReservers = uniqueReservers - 1;
        return format("There %s%s %d %s for %s: %s.",
            otherReserves == 1 and "is" or "are",
            isUpdate and " now" or "",
            otherReserves,
            multireserve > 1 and format("%s by %d %s", otherReserves == 1 and "other reserve" or "other reserves",
                                                       otherReservers,
                                                       otherReservers == 1 and "player" or "players")
                             or format("%s", otherReserves == 1 and "other contender" or "other contenders"),
            link,
            reservesText);
    else
        return "";
    end
end

function LootReserve:GetReservesString(server, players, player, isUpdate, link)
    return GetReservesString(self, isUpdate, link, self:GetReservesData(players, player));
end

function LootReserve:GetReservesStringColored(server, players, player, isUpdate, link)
    return GetReservesString(server, isUpdate, link, self:GetReservesDataColored(players, player));
end
