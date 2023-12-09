LootReserve = LootReserve or { };
LootReserve.Server =
{
    CurrentSession = nil,
    NewSessionSettings =
    {
        LootCategories       = { },
        MaxReservesPerPlayer = 1,
        Multireserve         = 1,
        Duration             = 300,
        ChatFallback         = true,
        Equip                = true,
        Blind                = false,
        Lock                 = false,
        ImportedMembers      = { },
    },
    Settings =
    {
        ChatAsRaidWarning = {
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            false,
            false,
            false,
        },
        ChatAnnounceWinToGuild          = false,
        ChatAnnounceWinToGuildThreshold = 3,
        ChatReservesList                = true,
        ChatReservesListLimit           = 5,
        ChatUpdates                     = true,
        ReservesSorting                 = LootReserve.Constants.ReservesSorting.BySource,
        UseGlobalProfile                = false,
        RollUseTiered                   = true,
        Phases                          = LootReserve:Deepcopy(LootReserve.Constants.DefaultPhases),
        RollUsePhases                   = false,
        RollPhases                      = {"Main Spec", "Off Spec"},
        RollAdvanceOnExpire             = true,
        RollLimitDuration               = false,
        RollDuration                    = 30,
        RollFinishOnExpire              = false,
        Disenchanters                   = { },
        RollDisenchant                  = false,
        RollDisenchanters               = { },
        RollFinishOnAllReservingRolled  = true,
        RollFinishOnRaidRoll            = false,
        RollSkipNotContested            = true,
        RollHistoryDisplayLimit         = 10,
        RollHistoryKeepLimit            = 1000,
        RollHistoryHideEmpty            = true,
        RollHistoryHideNotOwed          = false,
        RollMasterLoot                  = true,
        AcceptAllRollFormats            = false,
        AcceptRollsAfterTimerEnded      = true,
        WinnerReservesRemoval           = LootReserve.Constants.WinnerReservesRemoval.Smart,
        ItemConditions                  = { },
        CollapsedExpansions             = { },
        RecentLootBlacklist             = { },
        MaxRecentLoot                   = 30,
        MinimumLootQuality              = 3,
        RemoveRecentLootAfterRolling    = true,
        UseUnitFrames                   = false,
        Use24HourTime                   = true,
        ShowReopenHint                  = true,
    },
    RequestedRoll       = nil,
    RollHistory         = { },
    RecentLoot          = { },
    LootedCorpses       = { },
    AddonUsers          = { },
    GuildMembers        = { },
    LootEdit            = { },
    MembersEdit         = { },
    Import              = { },
    Export              = {
        PendingRollsExportTextUpdate = nil,
    },
    PendingMasterLoot   = nil,
    RecentTradeAttempt  = nil,
    RecentLootAttempts  = nil,
    TradeAcceptState    = { false, false };
    OwedRolls           = { },
    ExtraRollRequestNag = { },
    SentMessages        = { },

    ReservableIDs                      = { },
    ReservableRewardIDs                = { },
    LootTrackingRegistered             = false,
    GuildMemberTrackingRegistered      = false,
    DurationUpdateRegistered           = false,
    RollDurationUpdateRegistered       = false,
    RollMatcherRegistered              = false,
    ChatTrackingRegistered             = false,
    ChatFallbackRegistered             = false,
    BasicChatListeningRegistered       = false,
    SessionEventsRegistered            = false,
    StartupAwaitingAuthority           = false,
    StartupAwaitingAuthorityRegistered = false,
    MasterLootListUpdateRegistered     = false,
    RollHistoryDisplayLimit            = 0,
    
    PendingReserveListUpdate  = nil,
    PendingRollListUpdate     = nil,
    PendingMembersEditUpdate  = nil,
    PendingLootEditUpdate     = nil,
    PendingLootEditTextUpdate = false,
    PendingInputOptionsUpdate = false,
    PendingReservesListUpdate = nil,
    
    PendingRecentLootAttemptsWipe = nil,
};

StaticPopupDialogs["LOOTRESERVE_CONFIRM_FORCED_CANCEL_RESERVE"] =
{
    text         = "Are you sure you want to remove %s's reserve for item %s?",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        LootReserve.Server:CancelReserve(self.data.Player, self.data.Item:GetID(), 1, false, true);
    end,
};

StaticPopupDialogs["LOOTRESERVE_CONFIRM_FORCED_CANCEL_ROLL"] =
{
    text         = "Are you sure you want to delete %s's roll for item %s?",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        LootReserve.Server:DeleteRoll(self.data.Player, self.data.RollNumber, self.data.Item);
    end,
};

StaticPopupDialogs["LOOTRESERVE_CONFIRM_CUSTOM_ROLL_RESERVED_ITEM"] =
{
    text         = "Are you sure you want to roll among all players?|n|n%s has been reserved by:|n%s.",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        self.data.Frame:SetItem(nil);
        local phases = LootReserve.Server.Settings.RollUsePhases and #LootReserve.Server.Settings.RollPhases > 0 and LootReserve.Server.Settings.RollPhases or nil;
        if self.data.Phase then
            phases = LootReserve:Deepcopy(LootReserve.Server.Settings.RollPhases)
            for i = 2, self.data.Phase do
                table.remove(phases, 1)
            end
        end
        LootReserve.Server:RequestCustomRoll(self.data.Item,
            LootReserve.Server.Settings.RollLimitDuration and LootReserve.Server.Settings.RollDuration or nil,
            phases,
            LootReserve.Server.Settings.RollUseTiered or nil);
    end,
};

StaticPopupDialogs["LOOTRESERVE_CONFIRM_DISENCHANT_RESERVED_ITEM"] =
{
    text         = "Are you sure you want to send to disenchanter?|n|n%s has been reserved by:|n%s.",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        self.data.Frame:SetItem(nil);
        LootReserve.Server:RecordDisenchant(self.data.Item, self.data.Disenchanter, true);
    end,
};

StaticPopupDialogs["LOOTRESERVE_CONFIRM_ROLL_RESERVED_ITEM_AGAIN"] =
{
    text         = "Are you sure you want to roll %s among reserving players?|n|nIt has already been won by %s.",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        if self.data.Frame then
            self.data.Frame:SetItem(nil);
        end
        local tokenID;
        if LootReserve.Server.ReservableRewardIDs[self.data.Item:GetID()] then
            tokenID = LootReserve.Data:GetToken(self.data.Item:GetID());
        end
        if LootReserve.Server.CurrentSession and LootReserve.Server.CurrentSession.ItemReserves[tokenID or self.data.Item:GetID()] then
            LootReserve.Server:RequestRoll(self.data.Item);
        end
    end,
};

StaticPopupDialogs["LOOTRESERVE_ACCEPT_ALL_ROLL_FORMATS_ENABLE"] =
{
    text         = "|cffff0000WARNING|r|nThis option causes LootReserve to accept any roll.|n|nA player could do|n|cffff0000/roll 100 100|r|nand LootReserve will consider it valid.|n|nYou'll see a player's full rolls in the Recent Chat tracker next to their name in the Rolls tab.|n|nDo you want to enable this option?",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        LootReserve.Server.Settings.AcceptAllRollFormats = true;
        CloseMenus();
    end,
};

StaticPopupDialogs["LOOTRESERVE_CONFIRM_GLOBAL_PROFILE_ENABLE"] =
{
    text         = "By enabling global profile you acknowledge that all the mess you can create (by e.g. swapping between characters who are in different raid groups) will be on your conscience.|n|nDo you want to enable global profile?",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        LootReserveGlobalSave.Server.GlobalProfile = LootReserveCharacterSave.Server;
        LootReserve.Server.Settings.UseGlobalProfile = true;
        LootReserve.Server:Load();
        CloseMenus();
    end,
};

StaticPopupDialogs["LOOTRESERVE_CONFIRM_GLOBAL_PROFILE_DISABLE"] =
{
    text         = "Disabling global profile will revert you back to using sessions stored on your other characters before you turned global profile on. Your current character will adopt the current session.|n|nDo you want to disable global profile?",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        LootReserveCharacterSave.Server = LootReserveGlobalSave.Server.GlobalProfile;
        LootReserveGlobalSave.Server.GlobalProfile = nil;
        LootReserve.Server.Settings.UseGlobalProfile = false;
        CloseMenus();
        LootReserve.Server:Load();
        LootReserve.Server:Startup();
        LootReserve.Server:UpdateReserveList();
        LootReserve.Server:UpdateRollList();
    end,
};

StaticPopupDialogs["LOOTRESERVE_NEW_PHASE_NAME"] =
{
    text         = "Name the new stage:",
    button1      = ACCEPT,
    button2      = CANCEL,
    hasEditBox   = true,
    maxLetters   = 50,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        local name = LootReserve:StringTrim(self.editBox:GetText():gsub("[,|]", ""));
        if #name > 0 and not LootReserve:Contains(LootReserve.Server.Settings.Phases, name) then
            table.insert(LootReserve.Server.Settings.Phases, name);
        end
    end,
    EditBoxOnEnterPressed = function(self)
        StaticPopupDialogs["LOOTRESERVE_NEW_PHASE_NAME"].OnAccept(self:GetParent());
        self:GetParent():Hide();
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide();
    end,
};

StaticPopupDialogs["LOOTRESERVE_CONFIRM_ADD_TO_RECENT_LOOT_BLACKLIST"] =
{
    text         = "Are you sure you want to add %s to the Recent Loot Blacklist?\n\nIt won't show up in Recent Loot until you clear the Blacklist.",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self, data)
        LootReserve.Server.Settings.RecentLootBlacklist[data.item:GetID()] = time();
        while LootReserve:TableRemove(LootReserve.Server.RecentLoot, data.item) do end
        CloseMenus();
    end,
};

StaticPopupDialogs["LOOTRESERVE_CONFIRM_CLEAR_RECENT_LOOT_BLACKLIST"] =
{
    text         = "Are you sure you want to clear the Recent Loot Blacklist?",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        wipe(LootReserve.Server.Settings.RecentLootBlacklist);
        CloseMenus();
    end,
};

StaticPopupDialogs["LOOTRESERVE_CONFIRM_RESET_PHASES"] =
{
    text         = "Are you sure you want to reset stages to default?",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        LootReserve.Server.Settings.Phases = LootReserve:Deepcopy(LootReserve.Constants.DefaultPhases);
    end,
};

StaticPopupDialogs["LOOTRESERVE_CONFIRM_RESET_DISENCHANTERS"] =
{
    text         = "Are you sure you want to clear the list of disenchanters?",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        LootReserve.Server.Settings.RollDisenchanters = { };
        LootReserve.Server.Settings.Disenchanters     = { };
    end,
};

StaticPopupDialogs["LOOTRESERVE_CONFIRM_CLEAR_HISTORY"] =
{
    text         = "Are you sure you want to clear all %d roll%s?",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        table.wipe(LootReserve.Server.RollHistory);
        table.wipe(LootReserve.Server.OwedRolls);
        LootReserve.Server:UpdateRollList();
    end,
};

StaticPopupDialogs["LOOTRESERVE_CONFIRM_ANNOUNCE_BLIND_RESERVES"] =
{
    text         = "Blind reserves in effect. Are you sure you want to publicly announce all reserves?",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        LootReserve.Server:SendReservesList(nil, nil, true);
    end,
};

StaticPopupDialogs["LOOTRESERVE_RELOAD_UI"] =
{
    text         = "%s",
    button1      = "Reload",
    button2      = CANCEL,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        ReloadUI();
    end,
};

local function stringStartsWith(str, start)
    return str:sub(1, #start) == start;
end

function LootReserve.Server:CanBeServer()
    return not IsInGroup() or UnitIsGroupLeader("player") or IsMasterLooter();
end

function LootReserve.Server:GetChatChannel(announcement)
    if IsInRaid() then
        return announcement and self.Settings.ChatAsRaidWarning[announcement] and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) and "RAID_WARNING" or "RAID";
    elseif IsInGroup() then
        return "PARTY";
    else
        return "WHISPER", LootReserve:Me();
    end
end

function LootReserve.Server:HasRelevantRecentChat(roll, player)
    local chat    = roll.Chat;
    local players = roll.Players;
    if not chat    or not chat[player]    then return false; end
    if not players or not players[player] then return false; end
    
    local alreadyRolledTiers = { };
    local chatRollCount = 0;
    for _, str in ipairs(chat[player]) do
        local time, channel, text = strsplit("|", str, 3);
        if channel ~= "SYSTEM" then
            return true;
        end
        local tier = text:match("%(1%-(%d+)%)");
        if not tier then
            return true;
        end
        if roll.Tiered then
            if alreadyRolledTiers[tier] then
                return true;
            end
        elseif tier ~= "100" then
            return true;
        end
        alreadyRolledTiers[tier] = true;
        chatRollCount = chatRollCount + 1;
    end
    return #players[player] < chatRollCount;
end

function LootReserve.Server:IsAddonUser(player)
    return LootReserve:IsMe(player) or self.AddonUsers[player];
end

function LootReserve.Server:SetAddonUser(player, isUser)
    if self.AddonUsers[player] ~= isUser then
        self.AddonUsers[player] = isUser;
        self:UpdateAddonUsers();
    end
end

local function GetSavedItemConditionsSingle(category)
    if not category then return { }; end
    local container = LootReserve.Server.Settings.ItemConditions[category];
    if not container then
        container = { };
        LootReserve.Server.Settings.ItemConditions[category] = container;
    end
    return container;
end

local function GetSavedItemConditions(categories)
    if not categories then return { }; end
    local container = { };
    for _, category in ipairs(categories) do
        for itemID, conditions in pairs(GetSavedItemConditionsSingle(category)) do
            container[itemID] = container[itemID] or { };
            container[itemID].ClassMask = bit.bor(container[itemID].ClassMask or 0, conditions.ClassMask or 0);
            container[itemID].Custom = container[itemID].Custom or conditions.Custom or nil;
            container[itemID].Hidden = container[itemID].Hidden or conditions.Hidden or nil;
            container[itemID].Limit = (container[itemID].Limit or 0) + (conditions.Limit or 0);
            if container[itemID].ClassMask == 0 then
                container[itemID].ClassMask = nil;
            end
            if container[itemID].Limit == 0 then
                container[itemID].Limit = nil;
            end
            -- container[itemID] = conditions;
        end
    end
    return container;
end

function LootReserve.Server:GetNewSessionItemConditions()
    if #self.NewSessionSettings.LootCategories == 1 then
        return GetSavedItemConditionsSingle(self.NewSessionSettings.LootCategories[1]);
    else
        return GetSavedItemConditions(self.NewSessionSettings.LootCategories);
    end
end

function LootReserve.Server:GetAllItemConditions()
    local categories = { };
    for category in pairs(LootReserve.Data.Categories) do
        if category > 0 then
            table.insert(categories, category);
        end
    end
    return GetSavedItemConditions(categories);
end

function LootReserve.Server:Load()
    LootReserveCharacterSave.Server = LootReserveCharacterSave.Server or { };
    LootReserveGlobalSave.Server = LootReserveGlobalSave.Server or { };

    -- Copy data from saved variables into runtime tables
    -- Don't outright replace tables, as new versions of the addon could've added more fields that would be missing in the saved data
    local function loadInto(to, from, field)
        if from and to and field then
            if from[field] then
                for k, v in pairs(from[field]) do
                    to[field] = to[field] or { };
                    to[field][k] = v;
                    empty = false;
                end
            end
            from[field] = to[field];
        end
    end

    local versionGlobal = LootReserveGlobalSave.Server.Version and LootReserveGlobalSave.Server.Version or "0"
    loadInto(self, LootReserveGlobalSave.Server, "NewSessionSettings");
    loadInto(self, LootReserveGlobalSave.Server, "Settings");

    if self.Settings.UseGlobalProfile then
        LootReserveGlobalSave.Server.GlobalProfile = LootReserveGlobalSave.Server.GlobalProfile or { };
        self.SaveProfile = LootReserveGlobalSave.Server.GlobalProfile;
    else
        self.SaveProfile = LootReserveCharacterSave.Server;
    end
    local versionSave = self.SaveProfile.Version and self.SaveProfile.Version or "0"
    loadInto(self, self.SaveProfile, "CurrentSession");
    loadInto(self, self.SaveProfile, "RequestedRoll");
    loadInto(self, self.SaveProfile, "RollHistory");
    loadInto(self, self.SaveProfile, "RecentLoot");

    for name, key in pairs(LootReserve.Constants.ChatAnnouncement) do
        if self.Settings.ChatAsRaidWarning[key] == nil then
            self.Settings.ChatAsRaidWarning[key] = true;
        end
    end
    
    -- 2021-08-28: Convert active session LootCategory to LootCategories
    -- Date is late because the check was added late
    if versionSave < "2022-05-21" then
        if self.CurrentSession and not self.CurrentSession.Settings.LootCategories then
            self.CurrentSession.Settings.LootCategories = {self.CurrentSession.Settings.LootCategory};
            self.NewSessionSettings.LootCategories = {self.CurrentSession.Settings.LootCategory};
        end
    end

    -- 2021-02-12: Upgrade item conditions
    if versionGlobal < "2021-02-12" then
        if self.NewSessionSettings.ItemConditions then
            for itemID, conditions in pairs(self.NewSessionSettings.ItemConditions) do
                local category = conditions.Custom;
                conditions.Custom = conditions.Custom and true or nil;

                if category then
                    self.Settings.ItemConditions[category] = self.Settings.ItemConditions[category] or { };
                    self.Settings.ItemConditions[category][itemID] = LootReserve:Deepcopy(conditions);
                end
                for _, category in ipairs(LootReserve.Data:GetItemCategories(itemID)) do
                    self.Settings.ItemConditions[category] = self.Settings.ItemConditions[category] or { };
                    self.Settings.ItemConditions[category][itemID] = LootReserve:Deepcopy(conditions);
                end
            end
            self.NewSessionSettings.ItemConditions = nil;
        end
    end
    if versionSave < "2021-02-12" then
        if self.CurrentSession then
            if not self.CurrentSession.ItemConditions then
                self.CurrentSession.ItemConditions = { };
            end

            if self.CurrentSession.Settings.ItemConditions then
                for itemID, conditions in pairs(self.CurrentSession.Settings.ItemConditions) do
                    local category = conditions.Custom;
                    conditions.Custom = conditions.Custom and true or nil;

                    if LootReserve:Contains(self.CurrentSession.Settings.LootCategories, category) or LootReserve.Data:IsItemInCategories(item, self.CurrentSession.Settings.LootCategories) then
                        self.CurrentSession.ItemConditions[itemID] = LootReserve:Deepcopy(conditions);
                    end
                end
                self.CurrentSession.Settings.ItemConditions = nil;
            end
        end
    end

    -- 2021-06-17: Upgrade roll history to support multiple rolls from the same player
    if versionSave < "2021-06-17" then
        for _, rollTable in ipairs({self.RollHistory, {self.RequestedRoll}}) do
            for _, roll in ipairs(rollTable or { }) do
                local needsUpgrade = false;
                for player, rolls in pairs(roll.Players) do
                    if type(rolls) == "number" then
                        needsUpgrade = true;
                        break;
                    end
                end
                if needsUpgrade then
                    local players = { };
                    for player, rolls in LootReserve:Ordered(roll.Players) do
                        players[player] = players[player] or { };
                        if type(rolls) == "number" then
                            table.insert(players[player], rolls);
                        elseif type(rolls) == "table" then
                            for _, roll in ipairs(rolls) do
                                table.insert(players[player], roll);
                            end
                        end
                    end
                    roll.Players = players;
                end
            end
        end
    end
    
    -- 2021-09-01: Prune unneeded historical data
    if versionSave < "2021-09-01" then
        if #self.RollHistory > 0 then
            if self.RollHistory[#self.RollHistory].Duration then
                for _, roll in ipairs(self.RollHistory) do
                    roll.Duration    = nil;
                    roll.MaxDuration = nil;
                    if roll.Phases then
                        roll.Phases = {roll.Phases[1]};
                    end
                end
            end
        end
    end
    
    -- 2021-09-20: Add self.CurrentSession.Members[player].ReservesDelta and update self.CurrentSession.Settings.MultiReserve
    -- 2021-09-20: Prune deprecated settings
    -- 2021-09-20: Prune old chat history
    if versionSave < "2021-09-20" then
        if self.CurrentSession then
            for _, member in pairs(self.CurrentSession.Members) do
                member.ReservesDelta = member.ReservesDelta or 0;
            end
            if not self.CurrentSession.Settings.Multireserve then
                self.CurrentSession.Settings.MultiReserve = 1;
            end
        end
        
        self.Settings.ChatThrottle             = nil;
        self.Settings.KeepUnlootedRecentLoot   = nil;
        self.Settings.MasterLooting            = nil;
        self.Settings.HighlightSameItemWinners = nil;
        
        for _, rollTable in ipairs({self.RollHistory, {self.RequestedRoll}}) do
            for _, entry in ipairs(rollTable or { }) do
                for player, lines in pairs(entry.Chat or { }) do
                    for i = #lines, LootReserve.Constants.MAX_CHAT_STORAGE + 1, -1 do
                        lines[i] = nil;
                    end
                end
            end
        end
    end
    
    -- 2022-06-16: Delete irrelevant chat
    if versionSave < "2022-06-16" then
        for _, roll in ipairs(self.RollHistory) do
            local toRemove = { };
            if roll.Chat then
                for player, chat in pairs(roll.Chat) do
                    if self:HasRelevantRecentChat(roll, player) then
                        local text = chat[1]
                        if text:match("Tie for |cff%x%x%x%x%x%x|Hitem:%d+[:%d%-]+|h%[.+%]|h|r between players .+%. All rolled %d+%. Please /roll again") then
                            table.remove(chat, 1);
                        end
                        text = chat[1]
                        if text:match(".+ %- roll on reserved |cff%x%x%x%x%x%x|Hitem:%d+[:%d%-]+|h%[.+%]|h|r")
                        or text:match("Roll.* on |cff%x%x%x%x%x%x|Hitem:%d+[:%d%-]+|h%[.+%]|h|r") then
                            table.remove(chat, 1);
                        end
                    end
                    if not self:HasRelevantRecentChat(roll, player) then
                        table.insert(toRemove, player);
                    end
                end
                for _, player in ipairs(toRemove) do
                    roll.Chat[player] = nil;
                end
                if not next(roll.Chat) then
                    roll.Chat = nil;
                end
            end
        end
    end
    
    -- 2022-10-30: Add RollBonus field
    if versionSave < "2022-10-30" then
        if self.CurrentSession and self.CurrentSession.Members then
            for member, memberData in pairs(self.CurrentSession.Members) do
                if not memberData.RollBonus then
                    memberData.RollBonus = { }; -- metatable added in next block
                end
            end
        end
    end
    
    -- 2023-06-20: Remove illegal characters in phases
    if versionSave < "2023-06-20" then
        for _, t in ipairs({LootReserve.Server.Settings.RollPhases, LootReserve.Server.Settings.Phases}) do
            for i, phase in ipairs(t) do
                t[i] = phase:gsub("[,|]", "");
            end
        end
    end
    
    -- Create RollBonus metatables
    if self.CurrentSession then
        for _, member in pairs(self.CurrentSession.Members) do
            member.RollBonus = setmetatable(member.RollBonus, { __index = function() return 0 end })
        end
    end
    
    -- Create Item objects
    for _, roll in ipairs(self.RollHistory) do
        roll.Item = LootReserve.ItemCache:Item(roll.Item);
        -- Populate list of items that have not been distributed
        if roll.Owed then
            table.insert(self.OwedRolls, roll);
        end
    end
    if self.RequestedRoll then
       self.RequestedRoll.Item = LootReserve.ItemCache:Item(self.RequestedRoll.Item); 
    end
    if self.CurrentSession then
        for _, member in pairs(self.CurrentSession.Members) do
            if member.WonRolls then
                for i, won in ipairs(member.WonRolls) do
                    won.Item = LootReserve.ItemCache:Item(won.Item);
                end
            end
        end
    end
    for i, item in ipairs(self.RecentLoot) do
        self.RecentLoot[i] = LootReserve.ItemCache:Item(item);
    end

    -- Verify that all the required fields are present in the session
    if self.CurrentSession then
        for _, field in ipairs({ "Settings", "StartTime", "Duration", "DurationEndTimestamp", "Members", "WonItems", "ItemReserves", "LootTracking" }) do
            if self.CurrentSession and self.CurrentSession[field] == nil then
                self.CurrentSession = nil;
                self.SaveProfile.CurrentSession = nil;
                break;
            end
        end
    end
    
    -- Verify that all loot categories actually exist. deselect categories and/or terminate session otherwise
    if self.CurrentSession then
        for _, category in ipairs(self.CurrentSession.Settings.LootCategories or {}) do
            if not LootReserve.Data.Categories[category] or LootReserve.Data.Categories[category].Expansion > LootReserve:GetCurrentExpansion() then
                self.CurrentSession = nil;
                self.SaveProfile.CurrentSession = nil;
                break;
            end
        end
    end
    do
        local newLootCategories = { };
        for _, category in ipairs(self.NewSessionSettings.LootCategories or {}) do
            if LootReserve.Data.Categories[category] and LootReserve.Data.Categories[category].Expansion <= LootReserve:GetCurrentExpansion() then
                table.insert(newLootCategories, category);
            end
        end
        self.NewSessionSettings.LootCategories = newLootCategories;
    end
    
    -- Warn player if a stale session or roll exists
    if self.CurrentSession and self.CurrentSession.LogoutTime and time() > self.CurrentSession.LogoutTime + 1*15*60 then
        if self.CurrentSession.AcceptingReserves then
            LootReserve:ShowError("You logged out with an active session.|nYou can stop and reset the session in the Host window.")
        else
            LootReserve:ShowError("You logged out with an active session.|nYou can reset the session in the Host window.")
        end
    end
    if self.RequestedRoll and time() > self.RequestedRoll.StartTime + 1*15*60 then
        LootReserve:ShowError("You logged out with an active roll.|nYou can end the roll in the Host window.")
        self.Window:Show();
        PanelTemplates_SetTab(self.Window, 3);
        self:SetWindowTab(3);
    end

    -- Rearm the duration timer, to make it expire at about the same time (second precision) as it would've otherwise if the server didn't log out/reload UI
    -- Unless the timer would've expired during that time, in which case set it to a dummy 1 second to allow the code to finish reserves properly upon expiration
    if self.CurrentSession and self.CurrentSession.AcceptingReserves and self.CurrentSession.Duration ~= 0 then
        self.CurrentSession.Duration = math.max(1, self.CurrentSession.DurationEndTimestamp - time());
    end

    -- Same for current roll
    if self.RequestedRoll and self.RequestedRoll.MaxDuration and self.RequestedRoll.Duration ~= 0 then
        self.RequestedRoll.Duration = math.max(1, self.RequestedRoll.StartTime + self.RequestedRoll.MaxDuration - time());
    end
    
    self.SaveProfile.Version = LootReserve.Version;

    -- Update the UI according to loaded settings
    self:LoadNewSessionSettings();
    self.LootEdit:UpdateCategories();
end

function LootReserve.Server:Startup()
    -- Hook roll handlers if needed
    if self.RequestedRoll then
        self:PrepareRequestRoll();
    end

    if self.CurrentSession and not LootReserve.Client.SessionServer then
        if self:CanBeServer() then
            -- Hook handlers
            self:PrepareSession();
            -- Inform other players about ongoing session
            LootReserve.Comm:BroadcastSessionInfo();
        else
            -- If we have a session but no authority to be a server - wait until we have RL/ML role and restart the server again
            self.StartupAwaitingAuthority = true;
            self:UpdateServerAuthority();
            if not self.StartupAwaitingAuthorityRegistered then
                self.StartupAwaitingAuthorityRegistered = true;
                LootReserve:RegisterEvent("GROUP_ROSTER_UPDATE", function()
                    if self.StartupAwaitingAuthority and self.CurrentSession and not LootReserve.Client.SessionServer and self:CanBeServer() then
                        self.StartupAwaitingAuthority = false;
                        self:Startup();
                    end
                end);
            end
        end

        -- Update UI
        if self.CurrentSession.AcceptingReserves then
            self:SessionStarted();
        else
            self:SessionStopped();
        end

        self:UpdateReserveList();

        self.Window:Show();

        -- Immediately after logging in retrieving raid member names might not work (names not yet cached?)
        -- so update the UI a little bit later, otherwise reserving players will show up as "(not in raid)"
        -- until the next group roster change
        C_Timer.After(5, function()
            self:UpdateReserveList();
            self:UpdateRollList();
        end);
    end
    
    -- Prepare dropdown lists for displaying item tooltips
    local OnTooltipEnter = function(self)
        if type(self.tooltipOnButton) == "string" and self.tooltipOnButton:find("item:%d+") then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetHyperlink(self.tooltipOnButton);
            GameTooltip:Show();
        end
    end
    
    -- Hook all existing dropdown buttons
    local list, index = 1, 1
    while _G["L_DropDownList"..list] do
        while _G["L_DropDownList"..list.."Button"..index] do
            _G["L_DropDownList"..list.."Button"..index]:HookScript("OnEnter", OnTooltipEnter)
            index = index + 1
        end
        list = list + 1
    end
    
    -- Hook all future dropdown buttons
    hooksecurefunc("CreateFrame", function(frameType, name, _, template, _, ...)
        if frameType == "Button" and name and type(name) == "string" and name:find("L_DropDownList%d+Button%d+") and template == "L_UIDropDownMenuButtonTemplate" then
            _G[name]:HookScript("OnEnter", OnTooltipEnter)
        end
    end)

    -- Show reserves even if no longer the server, just a failsafe
    self:UpdateReserveList();

    -- Hook events to record recent loot and track looters
    self:PrepareLootTracking();

    self:PrepareGuildTracking();
end

function LootReserve.Server:HasAlreadyWon(player, item)
    local won = self.CurrentSession and self.CurrentSession.Members[player] and self.CurrentSession.Members[player].WonRolls;
    if won then
        local item = LootReserve.Data:GetToken(item) or item;
        for i, roll in ipairs(won) do
            if roll.Item:GetID() == item then
                return true;
            end
        end
    end
    return false;
end

function LootReserve.Server:UpdateTradeFrameAutoButton(accepting)
    if not TradeFrame:IsShown() then
        return;
    end
    
    local target        = LootReserve:Player(UnitName("npc"));
    local itemsToInsert = { };
    local slotsFree     = 6;
    local relevantSlots = 0;
    -- Add all "recent" owed items to the list
    for _, roll in ipairs(self.OwedRolls) do
        if roll.Winners[1] == target then
            table.insert(itemsToInsert, roll.Item);
        end
    end
    -- Remove items which are currently being traded
    local offsets = { };
    if accepting then
        self.RecentTradeAttempt = { target = target };
    end
    for i = 1, 6 do
        local name, texture, quantity, quality, isUsable, enchant = GetTradePlayerItemInfo(i);
        local link = GetTradePlayerItemLink(i);
        if link then
            local item = LootReserve.ItemCache:Item(link);
            if not offsets[item] then
                offsets[item] = -1;
            end
            offsets[item] = offsets[item] + 1;
            if accepting then
                self.RecentTradeAttempt[i] = {item = item, quantity = quantity};
            end
            
            if LootReserve:TableRemove(itemsToInsert, item) then
                relevantSlots = relevantSlots + 1;
            end
            slotsFree = slotsFree - 1;
        end
    end
    
    -- Remove items which aren't found in bags
    for i = #itemsToInsert, 1, -1 do
        local item = itemsToInsert[i]
        if not offsets[item] then
            offsets[item] = -1;
        end
        offsets[item] = offsets[item] + 1;
        if LootReserve:GetTradeableItemCount(item) - offsets[item] < 1 then
            table.remove(itemsToInsert, i);
        end
    end
    
    if relevantSlots > 0 and (slotsFree == 0 or #itemsToInsert == 0) then
        LootReserveTradeFrameAutoButton:Show();
        LootReserveTradeFrameAutoButton:SetEnabled(not self.TradeAcceptState[1]);
        LootReserveTradeFrameAutoButton:SetText("|TInterface\\AddOns\\LootReserve\\Assets\\Textures\\IconDice:16:16:0:0|t Trade");
        LootReserveTradeFrameAutoButton.ItemsToInsert = nil;
    elseif #itemsToInsert > 0 then
        LootReserveTradeFrameAutoButton:Show();
        LootReserveTradeFrameAutoButton:SetEnabled(slotsFree ~= 0);
        LootReserveTradeFrameAutoButton:SetText(format("|TInterface\\AddOns\\LootReserve\\Assets\\Textures\\IconDice:16:16:0:0|t Insert %s%d |4item:items;", #itemsToInsert > slotsFree and format("%d / ", slotsFree) or "", #itemsToInsert));
        LootReserveTradeFrameAutoButton.ItemsToInsert = itemsToInsert;
    else
        LootReserveTradeFrameAutoButton:Hide();
    end
end

function LootReserve.Server:AddRecentLoot(item, acceptAllQualities)
    if self.Settings.RecentLootBlacklist[item:GetID()] or LootReserve.Data.RecentLootBlacklist[item:GetID()] then return; end
    if not item:IsCached() then
        if item:Exists() then
            item:OnCache(function() self:AddRecentLoot(item) end);
        end
        return
    end
    
    if not acceptAllQualities and item:GetQuality() < self.Settings.MinimumLootQuality then return; end
    if item:GetStackSize() > 1 then
        LootReserve:TableRemove(self.RecentLoot, item);
    end
    local count = 1;
    while LootReserve:TableRemove(self.RecentLoot, item) do
        count = count + 1;
    end
    for i = 1, count do
        table.insert(self.RecentLoot, item);
    end
    while #self.RecentLoot > self.Settings.MaxRecentLoot do
        table.remove(self.RecentLoot, 1);
    end
    
    -- try to get the tooltip to cache
    if not LootReserve.TooltipScanner then
        LootReserve.TooltipScanner = CreateFrame("GameTooltip", "LootReserveTooltipScanner", nil, "GameTooltipTemplate");
        LootReserve.TooltipScanner:Hide();
    end
    LootReserve.TooltipScanner:SetOwner(WorldFrame, "ANCHOR_NONE");
    LootReserve.TooltipScanner:SetHyperlink(item:GetString());
    LootReserve.TooltipScanner:Hide();
end

function LootReserve.Server:PrepareLootTracking()
    if self.LootTrackingRegistered then return; end
    self.LootTrackingRegistered = true;
    
    local function MarkDistributed(item, player)
        for i, roll in ipairs(self.OwedRolls) do
            if roll.Item == item and roll.Winners[1] == player then
                roll.Owed = nil;
                table.remove(self.OwedRolls, i);
                return;
            end
        end
    end
    
    local function AddLootToTrackingList(looter, item, count)
        count = tonumber(count);
        if looter and item and count then
            if LootReserve:IsMe(looter) then
                self:AddRecentLoot(item);
            end

            if self.CurrentSession and self.ReservableIDs[item:GetID()] then
                local tracking = self.CurrentSession.LootTracking[item:GetID()] or
                {
                    TotalCount = 0,
                    Players    = { },
                };
                self.CurrentSession.LootTracking[item:GetID()] = tracking;
                tracking.TotalCount = tracking.TotalCount + count;
                tracking.Players[looter] = (tracking.Players[looter] or 0) + count;

                self:UpdateReserveList();
            end
        end
    end

    local loot = LootReserve:FormatToRegexp(LOOT_ITEM);
    local lootMultiple = LootReserve:FormatToRegexp(LOOT_ITEM_MULTIPLE);
    local lootSelf = LootReserve:FormatToRegexp(LOOT_ITEM_SELF);
    local lootSelfMultiple = LootReserve:FormatToRegexp(LOOT_ITEM_SELF_MULTIPLE);
    LootReserve:RegisterEvent("CHAT_MSG_LOOT", function(text)
        if IsMasterLooter() and not self.RecentLootAttempts then
            return;
        end
        local looter, itemLink, count;
        itemLink, count = text:match(lootSelfMultiple);
        if itemLink and count then
            looter = LootReserve:Me();
        else
            itemLink = text:match(lootSelf);
            if itemLink then
                looter = LootReserve:Me();
                count = 1;
            else
                looter, itemLink, count = text:match(lootMultiple);
                if looter and itemLink and count then
                    -- ok
                else
                    looter, itemLink = text:match(loot);
                    if looter and itemLink then
                        count = 1;
                    else
                        return;
                    end
                end
            end
        end
        looter = LootReserve:Player(looter);
        if IsMasterLooter() then
            LootReserve.ItemCache:Item(itemLink):OnCache(function(item)
                if not self.RecentLootAttempts then return; end
                for lootSlot, lootData in pairs(self.RecentLootAttempts) do
                    if lootData.item == item and lootData.player == looter then
                        MarkDistributed(item, looter);
                        self.RecentLootAttempts[lootSlot] = nil;
                    end
                end
            end);
        else
            LootReserve.ItemCache:Item(itemLink):OnCache(function(item)
                if (item:GetStackSize() == 1 or not item:IsBindOnPickup()) then
                    return AddLootToTrackingList(looter, item, count);
                end
            end);
        end
    end);
    LootReserve:RegisterEvent("LOOT_READY", function(text)
        if not IsMasterLooter() then
           return;
        end
        if self.PendingRecentLootAttemptsWipe then
            self.PendingRecentLootAttemptsWipe:Cancel();
            self.PendingRecentLootAttemptsWipe = nil;
        end
        self.RecentLootAttempts = { };
        -- best guess at what object the player is looting. won't work for chests
        local guid = UnitExists("target") and UnitIsDead("target") and not UnitIsFriend("player", "target") and UnitGUID("target") or "CHEST";
        if self.LootedCorpses[guid] then
            return;
        else
            self.LootedCorpses[guid] = true;
        end
        for lootSlot = 1, GetNumLootItems() do
            if GetLootSlotType(lootSlot) == 1 then -- loot slot contains item, not currency/empty
                local itemID = GetLootSlotInfo(lootSlot);
                if itemID then
                    local itemLink = GetLootSlotLink(lootSlot);
                    if itemLink and itemLink:find("item:%d") then -- GetLootSlotLink() sometimes returns "|Hitem:::::::::70:::::::::[]"
                        self:AddRecentLoot(LootReserve.ItemCache:Item(itemLink));
                    end
                end
            end
        end
    end);
    
    hooksecurefunc("GiveMasterLoot", function(lootSlot, playerSlot)
        local itemLink = GetLootSlotLink(lootSlot);
        if not itemLink or not itemLink:find("item:%d") then -- GetLootSlotLink() sometimes returns "|Hitem:::::::::70:::::::::[]"
            return;
        end
        local item = LootReserve.ItemCache:Item(itemLink);
        local candidate = GetMasterLootCandidate(lootSlot, playerSlot);
        if not candidate then return; end
        if self.RecentLootAttempts then
            self.RecentLootAttempts[lootSlot] = {item = item, player = LootReserve:Player(candidate)};
        end
    end);
    LootReserve:RegisterEvent("LOOT_CLOSED", function(lootSlot)
        self.LootedCorpses["CHEST"] = nil;
        if self.RecentLootAttempts and not self.PendingRecentLootAttemptsWipe then
            self.PendingRecentLootAttemptsWipe = C_Timer.NewTicker(0.5, function() self.RecentLootAttempts = nil; self.PendingRecentLootAttemptsWipe = nil; end, 1);
        end
    end);
    LootReserve:RegisterEvent("LOOT_SLOT_CLEARED", function(lootSlot)
        if not self.RecentLootAttempts then return; end
        if self.RecentLootAttempts[lootSlot] then
            MarkDistributed(self.RecentLootAttempts[lootSlot].item, self.RecentLootAttempts[lootSlot].player);
            self.RecentLootAttempts[lootSlot] = nil;
        end
    end);
    LootReserve:RegisterEvent("TRADE_ACCEPT_UPDATE", function(player, target)
        self.TradeAcceptState = { player == 1, target == 1 };
        LootReserve.Server:UpdateTradeFrameAutoButton(true);
    end);
    LootReserve:RegisterEvent("TRADE_CLOSED", function(player, target)
        self.TradeAcceptState = { false, false };
    end);
    LootReserve:RegisterEvent("UI_INFO_MESSAGE", function(e, msg)
        if msg == ERR_TRADE_COMPLETE then
            if self.RecentTradeAttempt then
                for i = 1, 6 do
                    if self.RecentTradeAttempt[i] then
                        for j = 1, self.RecentTradeAttempt[i].quantity do
                            MarkDistributed(self.RecentTradeAttempt[i].item, self.RecentTradeAttempt.target);
                        end
                    end
                end
            end
        end
    end);
    
    -- Announce reserves when a group loot roll starts
    LootReserve:RegisterEvent("START_LOOT_ROLL", function(rollID)
        if not self.CurrentSession then return; end
        
        local link = GetLootRollItemLink(rollID);
        if not link then return; end
        
        local item = LootReserve.ItemCache:Item(link);
        
        local token;
        if not self.ReservableIDs[item:GetID()] and self.ReservableRewardIDs[item:GetID()] then
            token = LootReserve.ItemCache:Item(LootReserve.Data:GetToken(item:GetID()));
        end
        local itemID = token and token:GetID() or item:GetID();
        if self.CurrentSession.ItemReserves[itemID] then
            item:OnCache(function()
                if not self.CurrentSession then return end
                local reservesText = LootReserve:GetReservesData(self.CurrentSession.ItemReserves[itemID].Players);
                LootReserve:SendChatMessage(format("%s is reserved by: %s", item:GetLink(), reservesText), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollStartReserved));
            end);
        end
    end);
    
    -- Fix blizzard bug
    -- This can be removed once blizzard stops resetting the highlights on every GET_ITEM_INFO_RECEIVED
    hooksecurefunc("TradeFrame_Update", function()
        TradeFrame_SetAcceptState(self.TradeAcceptState[1] and 1 or 0, self.TradeAcceptState[2] and 1 or 0);
    end);
end

function LootReserve.Server:PrepareGuildTracking()
    if self.GuildMemberTrackingRegistered then return; end
    self.GuildMemberTrackingRegistered = true;

    LootReserve:RegisterEvent("GUILD_ROSTER_UPDATE", function()
        table.wipe(self.GuildMembers);
        for i = 1, GetNumGuildMembers() do
            local name = GetGuildRosterInfo(i);
            if name then
                name = LootReserve:Player(name);
                table.insert(self.GuildMembers, name);
            end
        end
    end);

    GuildRoster();
end

function LootReserve.Server:UpdateGroupMembers()
    if self.CurrentSession then
        -- Remove member info for players who left with no reserves
        local leavers = { };
        for player, member in pairs(self.CurrentSession.Members) do
            if not LootReserve:UnitInGroup(player) and #member.ReservedItems == 0 and member.ReservesDelta == 0 and not member.WonRolls then
                table.insert(leavers, player);

                -- for i = #member.ReservedItems, 1, -1 do
                --     self:CancelReserve(player, member.ReservedItems[i], 1, false, true);
                -- end
            end
        end

        for _, player in ipairs(leavers) do
            self.CurrentSession.Members[player] = nil;
            self.MembersEdit:UpdateMembersList();
        end

        -- Add member info for players who joined
        LootReserve:ForEachRaider(function(name, _, _, _, _, _, _, _, _, _, _, _, index)
            if not self.CurrentSession.Members[name] then
                self.CurrentSession.Members[name] =
                {
                    Class         = select(3, LootReserve:UnitClass(index)),
                    ReservesLeft  = self.CurrentSession.Settings.MaxReservesPerPlayer,
                    ReservesDelta = 0,
                    ReservedItems = { },
                    Locked        = nil,
                    OptedOut      = nil,
                    RollBonus     = setmetatable({ }, { __index = function() return 0 end }),
                };
                self.MembersEdit:UpdateMembersList();
            end
            -- Add class info to players who are missing it
            if not self.CurrentSession.Members[name].Class then
                self.CurrentSession.Members[name].Class = select(3, LootReserve:UnitClass(index));
            end
        end);
    end
    self:UpdateReserveList();
    self:UpdateRollList();
    self:UpdateAddonUsers();
end

function LootReserve.Server:PrepareSession()
    if self.CurrentSession.Settings.Duration ~= 0 and not self.DurationUpdateRegistered then
        self.DurationUpdateRegistered = true;
        LootReserve:RegisterUpdate(function(elapsed)
            if self.CurrentSession and self.CurrentSession.AcceptingReserves and self.CurrentSession.Duration ~= 0 then
                if self.CurrentSession.Duration > elapsed then
                    self.CurrentSession.Duration = self.CurrentSession.Duration - elapsed;
                else
                    self.CurrentSession.Duration = 0;
                    self:StopSession();
                end
            end
        end);
    end

    if not self.SessionEventsRegistered then
        self.SessionEventsRegistered = true;

        -- For the future. But it needs proper periodic time sync broadcasts to work correctly anyway
        --[[
        LootReserve:RegisterEvent("LOADING_SCREEN_DISABLED", function()
            if self.CurrentSession and self.CurrentSession.AcceptingReserves and self.CurrentSession.Duration ~= 0 then
                self.CurrentSession.Duration = math.max(1, self.CurrentSession.DurationEndTimestamp - time());
            end
        end);
        ]]

        LootReserve:RegisterEvent("PLAYER_LOGOUT", function()
            if self.CurrentSession then
                self.CurrentSession.LogoutTime = time();
            end
        end);

        LootReserve:RegisterEvent("GROUP_ROSTER_UPDATE", function()
            self:UpdateGroupMembers();
        end);
        LootReserve:RegisterEvent("UNIT_NAME_UPDATE", function(unit)
            if unit and (stringStartsWith(unit, "raid") or stringStartsWith(unit, "party")) then
                self:UpdateGroupMembers();
            end
        end);
        LootReserve:RegisterEvent("UNIT_CONNECTION", function(unit)
            if unit and (stringStartsWith(unit, "raid") or stringStartsWith(unit, "party")) then
                self:UpdateGroupMembers();
            end
        end);

        local function OnTooltipSetHyperlink(tooltip)
            if self.CurrentSession then
                local name, link = tooltip:GetItem();
                if not link then return; end
                
                -- Check if it's already been added
                local frame, text;
                for i = 1, tooltip:NumLines() do
                frame = _G[tooltip:GetName() .. "TextLeft" .. i];
                if frame then
                    text = frame:GetText();
                end
                if text and string.find(text, " Won by ", 1, true) then return; end
                end

                local itemID = LootReserve.ItemCache:Item(link):GetID();
                itemID = LootReserve.Data:GetToken(itemID) or itemID;
                
                if self.CurrentSession.WonItems[itemID] then
                    local playerCounts = { };
                    for _, player in ipairs(self.CurrentSession.WonItems[itemID].Players) do
                        playerCounts[player] = playerCounts[player] and playerCounts[player] + 1 or 1;
                        local found = 0;
                        for _, roll in ipairs(self.CurrentSession.Members[player] and self.CurrentSession.Members[player].WonRolls or { }) do
                            if itemID == LootReserve.ItemCache:Item(roll.Item):GetID() then
                                found = found + 1;
                                if found == playerCounts[player] then
                                    local text = format("%s%s", LootReserve:ColoredPlayer(player), roll.Phase and format(" %s %s", type(roll.Phase) == "number" and "by" or "for", LootReserve.Constants.WonRollPhaseText[roll.Phase] or roll.Phase) or "")
                                    tooltip:AddLine("|TInterface\\BUTTONS\\UI-GroupLoot-Coin-Up:32:32:0:-4|t Won by " .. text, 1, 1, 1);
                                    break;
                                end
                            end
                        end
                    end
                end
                if self.CurrentSession.ItemReserves[itemID] then
                    local reservesText = LootReserve:FormatReservesTextColored(self.CurrentSession.ItemReserves[itemID].Players);
                    tooltip:AddLine("|TInterface\\BUTTONS\\UI-GroupLoot-Dice-Up:32:32:0:-4|t Reserved by " .. reservesText, 1, 1, 1);
                end
            end
        end
        GameTooltip             : HookScript("OnTooltipSetItem", OnTooltipSetHyperlink);
        ItemRefTooltip          : HookScript("OnTooltipSetItem", OnTooltipSetHyperlink);
        ItemRefShoppingTooltip1 : HookScript("OnTooltipSetItem", OnTooltipSetHyperlink);
        ItemRefShoppingTooltip2 : HookScript("OnTooltipSetItem", OnTooltipSetHyperlink);
        ShoppingTooltip1        : HookScript("OnTooltipSetItem", OnTooltipSetHyperlink);
        ShoppingTooltip2        : HookScript("OnTooltipSetItem", OnTooltipSetHyperlink);
    end

    if self.CurrentSession.Settings.ChatFallback and not self.ChatFallbackRegistered then
        self.ChatFallbackRegistered = true;
        
        local prefixString     = "^([!¡]+)"
        local reservesStrings  = {"^([!¡]*)reserve[sdr](.*)"};
        local myResStrings     = {"^([!¡]*)myreserve[sd]", "^([!¡]*)myreserve", "^([!¡]*)myres"};
        local optStrings       = {"^([!¡]*)opt%s*(in)", "^([!¡]*)opt%s*(out)"};
        local cancelStrings    = {"^([!¡]*)cancelreserve(.*)", "^([!¡]*)cancelres(.*)", "^([!¡]*)cancel(.*)", "^([!¡]*)unreserve(.*)", "^([!¡]*)unres(.*)", "^([!¡]*)rescancel(.*)", "^([!¡]*)reservecancel(.*)", "^([!¡]*)remove(.*)"};
        local reserveStrings   = {"^([!¡]*)reserve(.*)", "^([!¡]*)res(.*)"};
        
        local greedyResStrings = {"^[!¡]+(.*)"};
        local failString       = "^[!¡]+";
        local linkResString    = {"(.*)"};
        

        local function ProcessChat(origText, sender, chatType)
            local isWhisper = chatType == "CHAT_MSG_WHISPER"
            sender = LootReserve:Player(sender);
            if not self.CurrentSession then return; end;

            local member = self.CurrentSession.Members[sender];
            if not member or not LootReserve:IsPlayerOnline(sender) then return; end

            local text = origText:lower();
            text = LootReserve:StringTrim(text);
            
            if isWhisper and LootReserve:IsMe(sender) and not text:match(prefixString) then
                return;
            end
            
            local command, greedy, reqLink;
            for _, pattern in ipairs(reservesStrings) do
                local exclamation, args = text:match(pattern);
                if args and (isWhisper or #exclamation > 0) then
                    command = "reserves";
                    text = args;
                    break;
                end
            end
            
            for _, pattern in ipairs(myResStrings) do
                local exclamation = text:match(pattern);
                if exclamation and (isWhisper or #exclamation > 0) then
                    if self.Settings.ChatReservesList then
                        self:SendReservesList(sender, true);
                    end
                    return;
                end
            end
            
            for _, pattern in ipairs(optStrings) do
                local exclamation, direction = text:match(pattern);
                if direction and (isWhisper or #exclamation > 0) then
                    if direction == "in" then
                        self:Opt(sender, nil, true);
                        return;
                    elseif direction == "out" then
                        self:Opt(sender, true, true);
                        return;
                    end
                end
            end
            
            if not command then
                for _, pattern in ipairs(cancelStrings) do
                    local exclamation, args = text:match(pattern);
                    if args and (isWhisper or #exclamation > 0) then
                        command = "cancel";
                        text = args;
                        break;
                    end
                end
            end
            
            if not command then
                for _, pattern in ipairs(reserveStrings) do
                    local exclamation, args = text:match(pattern);
                    if args and (isWhisper or #exclamation > 0) then
                        command = "reserve";
                        text = args;
                        break;
                    end
                end
            end
            
            if not command then
                for _, pattern in ipairs(greedyResStrings) do
                    local args = text:match(pattern);
                    if args then
                        command = "reserve";
                        text = args;
                        greedy = true;
                        break;
                    end
                end
            end
            
            if not command and not text:match(failString) and not (LootReserve:IsMe(sender) and self.SentMessages[LootReserve:FixText(origText)]) and isWhisper then
                for _, pattern in ipairs(linkResString) do
                    local args = text:match(pattern);
                    if args then
                        command = "reserve";
                        text = args;
                        greedy  = true;
                        reqLink = true;
                        break;
                    end
                end
            end
            
            if not command then return; end

            if not self.CurrentSession.AcceptingReserves and (command == "reserve" or command == "cancel") and not greedy then
                LootReserve:SendChatMessage("Loot reserves are not currently being accepted.", "WHISPER", sender);
                return;
            end

            text = LootReserve:StringTrim(text);
            if command == "reserve" and #text == 0 and not greedy then
                LootReserve:SendChatMessage("Seems like you forgot to enter the item you want to reserve. Whisper: !reserve ItemLinkOrName. You can link the item, or spell out the partial or full name.", "WHISPER", sender);
                self:SendSupportString(sender, true);
                return;
            elseif command == "reserves" and #text == 0 then
                if self.Settings.ChatReservesList then
                    local count = 0;
                    for id in pairs(self.CurrentSession.ItemReserves) do
                        count = count + 1;
                    end
                    if self.Settings.ChatReservesListLimit == LootReserve.Constants.ChatReservesListLimit.None or count <= self.Settings.ChatReservesListLimit then
                        self:SendReservesList(sender);
                    else
                        LootReserve:SendChatMessage(format("Too many items to send at once. This limit is in place due to the game's chat throttling. You can use !myreserves instead, or enter up to %d item%s at a time to see reserves on those items. Whisper: !reserves ItemLinkOrName", self.Settings.ChatReservesListLimit, self.Settings.ChatReservesListLimit == 1 and "" or "s"), "WHISPER", sender);
                        self:SendSupportString(sender, true);
                    end
                end
                return;
            end

            if command == "cancel" then
                local count = tonumber(text:match("^[Xx%*]?%s*(%d+)%s*[Xx%*]?$"));
                if #text == 0 then
                    count = 1;
                end
                if count then
                    if #member.ReservedItems > 0 then
                        local reservesCount = { };
                        for i = #member.ReservedItems, math.max(#member.ReservedItems - count + 1, 1), -1 do
                            reservesCount[member.ReservedItems[i]] = reservesCount[member.ReservedItems[i]] and reservesCount[member.ReservedItems[i]] + 1 or 1;
                        end

                        for itemID, count in pairs(reservesCount) do
                            self:CancelReserve(sender, itemID, count, true);
                        end
                    else
                        LootReserve:SendChatMessage(format("You have no items reserved.%s", self:GetSupportString(sender, " ")), "WHISPER", sender);
                    end
                    return;
                end
            end

            local function handleItemCommand(itemID, command, count)
                count = count or 1;
                if self.ReservableRewardIDs[itemID] then
                    itemID = LootReserve.Data:GetToken(itemID);
                end
                if self.ReservableIDs[itemID] then
                    if command == "reserve" then
                        LootReserve.ItemCache(itemID):OnCache(function()
                            self:Reserve(sender, itemID, count, true);
                        end);
                    elseif command == "cancel" then
                        self:CancelReserve(sender, itemID, count, true);
                    elseif command == "reserves" then
                        self:SendReservesList(sender);
                    end
                else
                    LootReserve:SendChatMessage(format("%s.%s", LootReserve.Constants.ReserveResultText[LootReserve.Constants.ReserveResult.ItemNotReservable], self:GetSupportString(sender, " ", true)), "WHISPER", sender);
                end
            end

            local itemID = tonumber(text:match("item[:=](%d+)"));
            if itemID then
                local charI = 0;
                local items = { };
                local itemCounts = { };
                while true do
                    local s, e, itemID;
                    -- Match various forms of item linking, including incorrect ones
                    if not s then
                         -- Correctly-formatted itemlink
                        s, e, itemID = text:find("\124cff%x%x%x%x%x%x\124hitem:(%d+)[:%d]*\124h%[[^%[%]]*%]\124h\124r", charI);
                    end
                    if not s then
                        -- Wowhead In-Game Link
                        s, e, itemID = text:find("/%S+%s*default_chat_frame:addmessage%(\"\\124cff%x%x%x%x%x%x\\124hitem:(%d+)[:%d]*\\124h%[[^%[%]]*%]\\124h\\124r\"%);", charI);
                    end
                    if not s then
                        -- URL
                        s, e, itemID = text:find("https?://%S*item=(%d+)%S*", charI);
                    end
                    itemID = tonumber(itemID);
                    if itemID then
                        table.insert(items, {s = s, e = e, ID = itemID});
                        charI = e + 1;
                    else
                        break;
                    end
                end
                if command == "reserve" or command == "cancel" then
                    for i, itemData in ipairs(items) do
                        local s, e = items[i-1] and items[i-1].e+1 or 1, items[i+1] and items[i+1].s-1 or text:len();
                        local pre, post = text:sub(s, itemData.s-1), text:sub(itemData.e+1, e);
                        local count1, count2 = pre:match("(%d+)%s*[xX%*]"), post:match("[xX%*]%s*(%d+)");
                        local ambig1, ambig2 = pre:match("(%d+)%s*^"), post:match("^%s*(%d+)");
                        local counterambig1, counterambig2 = pre:match("[xX%*]%s*(%d+)"), post:match("(%d+)%s*[xX%*]");
                        
                        -- [xX*] is not always necessary, as a solo number is not ambiguous at the start or end
                        if i == 1 and not count1 then
                            count1 = ambig1;
                        end
                        if i == #items + 1 and not count2 then
                            count2 = ambig2;
                        end
                        
                        local ambiguous = false;
                        if ambig1 and not count1 and i ~= 1 then
                            if not counterambig1 or not items[i-1] then
                                ambiguous = true;
                            end
                        elseif ambig2 and not count2 and i ~= #items + 1 then
                            if not counterambig2 or not items[i+1] then
                                ambiguous = true;
                            end
                        end
                        
                        if (count1 and count2 and count1 ~= count2) or ambiguous then
                            LootReserve:SendChatMessage(format("Can't tell how many items you want to reserve. Please be unambiguous.%s", self:GetSupportString(sender, " ", true)), "WHISPER", sender);
                            return;
                        else
                            if not itemCounts[itemData.ID] then
                                itemCounts[itemData.ID] = 0;
                            end
                            itemCounts[itemData.ID] = itemCounts[itemData.ID] + (count1 or count2 or 1);
                        end
                    end
                    for _, itemData in pairs(items) do
                        if itemCounts[itemData.ID] then
                            handleItemCommand(itemData.ID, command, itemCounts[itemData.ID]);
                            itemCounts[itemData.ID] = nil;
                        end
                    end
                elseif command == "reserves" and self.Settings.ChatReservesList then
                    local whitelist = { };
                    local count = 0;
                    for _, itemData in pairs(items) do
                        whitelist[itemData.ID] = true;
                        count = count + 1;
                    end
                    if self.Settings.ChatReservesListLimit == LootReserve.Constants.ChatReservesListLimit.None or count <= self.Settings.ChatReservesListLimit then
                        self:SendReservesList(sender, nil, nil, whitelist);
                    else
                        LootReserve:SendChatMessage(format("Too many items to send at once. You may enter up to %d item%s at a time to see reserves on those items. This limit is in place due to the game's chat throttling. Whisper: !reserves ItemLinkOrName", self.Settings.ChatReservesListLimit, self.Settings.ChatReservesListLimit == 1 and "" or "s"), "WHISPER", sender);
                        self:SendSupportString(sender, true);
                    end
                end
            elseif not reqLink then
                local count = tonumber(text:match("%s*[xX%*]?%s*(%d+)%s*[Xx%*]?$"));
                if count then
                    text = text:match("^(.-)%s*[xX%*]?%s*(%d+)%s*[Xx%*]?$");
                else
                    count = 1;
                end
                local whitelist = { };
                text = LootReserve.ItemCache:FormatSearchText(text);
                local function handleItemCommandByName()
                    local matchIDs = { };
                    local matches  = { };
                    local missing  = { };
                    for itemID in pairs(self.ReservableIDs) do
                        local item = LootReserve.ItemCache:Item(itemID);
                        if item:IsCached() then
                            if item:Matches(text) then
                                matchIDs[itemID] = item;
                            end
                        elseif item:Exists() then
                            table.insert(missing, item);
                        end
                        if LootReserve.Data:IsToken(itemID) then
                            for _, rewardID in ipairs(LootReserve.Data:GetTokenRewards(itemID)) do
                                local reward = LootReserve.ItemCache:Item(rewardID);
                                if reward:IsCached() and item:IsCached() then
                                    if reward:Matches(text) and not matchIDs[itemID] then
                                        matchIDs[itemID] = reward;
                                        break;
                                    end
                                elseif reward:Exists() then
                                    table.insert(missing, reward);
                                end
                            end
                        end
                    end
                    for id, item in pairs(matchIDs) do
                        table.insert(matches, item:GetID());
                    end

                    if #missing == 0 then
                        if #matches == 0 then
                            if not greedy then
                                LootReserve:SendChatMessage(format("That item was not found in the current raid, which is %s. Check your spelling, or try using a shorter search term.%s",
                                    LootReserve:GetCategoriesText(self.CurrentSession.Settings.LootCategories, false),
                                    self:GetSupportString(sender, " ", true)
                                ), "WHISPER", sender);
                            end
                        elseif #matches == 1 then
                            if command == "reserve" or command == "cancel" then
                                handleItemCommand(matches[1], command, count);
                            elseif command == "reserves" then
                                whitelist[matches[1]] = true;
                            end
                        elseif #matches > 1 then
                            local names = { };
                            for _, itemID in ipairs(matches) do
                                local item = LootReserve.ItemCache:Item(itemID);
                                if item and item:GetInfo() then
                                    table.insert(names, item:GetName());
                                end
                                if #matches >= 5 then
                                    break;
                                end
                            end
                            LootReserve:SendChatMessage(format("Try being more specific, %d items match that name%s%s%s",
                                #matches,
                                #names > 0 and ": " or "",
                                strjoin(", ", unpack(names)),
                                #names > 0 and #matches > #names and format(" and %d more...", #matches - #names) or ""
                            ), "WHISPER", sender);
                            self:SendSupportString(sender, true);
                        end
                    else
                        LootReserve.ItemCache:OnCache(missing, handleItemCommandByName);
                    end
                    if command == "reserves" and self.Settings.ChatReservesList then
                        local count = 0;
                        for i in pairs(whitelist) do
                            count = count + 1;
                        end
                        if self.Settings.ChatReservesListLimit == LootReserve.Constants.ChatReservesListLimit.None or count <= self.Settings.ChatReservesListLimit then
                            self:SendReservesList(sender, nil, nil, whitelist);
                        else
                            LootReserve:SendChatMessage(format("Too many items to send at once. You may enter up to %d item%s at a time to see reserves on those items. This limit is in place due to the game's chat throttling. Whisper: !reserves ItemLinkOrName", self.Settings.ChatReservesListLimit, self.Settings.ChatReservesListLimit == 1 and "" or "s"), "WHISPER", sender);
                            self:SendSupportString(sender, true);
                        end
                    end
                end

                if #text >= 3 then
                    handleItemCommandByName();
                elseif not greedy then
                    LootReserve:SendChatMessage(format("That name is too short, 3 or more letters required.%s", self:GetSupportString(sender, " ", true)), "WHISPER", sender);
                end
            end
        end

        local chatTypes =
        {
            "CHAT_MSG_WHISPER",
            -- Just in case some people can't follow instructions
            "CHAT_MSG_SAY",
            "CHAT_MSG_YELL",
            "CHAT_MSG_PARTY",
            "CHAT_MSG_PARTY_LEADER",
            "CHAT_MSG_RAID",
            "CHAT_MSG_RAID_LEADER",
            "CHAT_MSG_RAID_WARNING",
        };
        for _, type in ipairs(chatTypes) do
            LootReserve:RegisterEvent(type, function(text, sender) return ProcessChat(text, sender, type); end);
        end
    end

    -- Cache the list of items players can reserve
    table.wipe(self.ReservableIDs);
    table.wipe(self.ReservableRewardIDs);
    for itemID, conditions in pairs(self.CurrentSession.ItemConditions) do
        if itemID ~= 0 and conditions.Custom then
            if LootReserve.ItemConditions:TestServer(itemID) then
                self.ReservableIDs[itemID] = true;
                if LootReserve.Data:IsToken(itemID) then
                    for _, rewardID in pairs(LootReserve.Data:GetTokenRewards(itemID)) do
                        if LootReserve.ItemConditions:TestServer(rewardID) then
                            self.ReservableRewardIDs[rewardID] = true;
                        end
                    end
                end
            end
        end
    end
    local rewardIDs = { };
    local hiddenIDs = { };
    for id, category in pairs(LootReserve.Data.Categories) do
        if category.Children and (not self.CurrentSession.Settings.LootCategories or LootReserve:Contains(self.CurrentSession.Settings.LootCategories, id)) and LootReserve.Data:IsCategoryVisible(category) then
            for _, child in ipairs(category.Children) do
                if child.Loot then
                    for _, itemID in ipairs(child.Loot) do
                        if itemID ~= 0 then
                            if LootReserve.ItemConditions:TestServer(itemID) then
                                if LootReserve.Data:IsTokenReward(itemID) then
                                    table.insert(rewardIDs, itemID);
                                else
                                    self.ReservableIDs[itemID] = true;
                                end
                                if LootReserve.Data:IsToken(itemID) then
                                    for _, rewardID in ipairs(LootReserve.Data:GetTokenRewards(itemID)) do
                                        if LootReserve.ItemConditions:TestServer(rewardID) then
                                            self.ReservableRewardIDs[rewardID] = true;
                                        end
                                    end
                                end
                            else
                                hiddenIDs[itemID] = true;
                            end
                        end
                    end
                end
            end
        end
    end
    for _, rewardID in ipairs(rewardIDs) do
        local tokenID = LootReserve.Data:GetToken(rewardID);
        if not self.ReservableIDs[tokenID] and not hiddenIDs[tokenID] then
            self.ReservableIDs[rewardID] = true;
        end
    end
    
    -- Add myself if not in a group
    self:UpdateGroupMembers();
end

function LootReserve.Server:StartSession()
    if not self:CanBeServer() then
        LootReserve:ShowError("You must be the raid leader or the master looter to start loot reserves");
        return;
    end

    if self.CurrentSession then
        LootReserve:ShowError("Loot reserves are already started");
        return;
    end

    if LootReserve.Client.SessionServer then
        LootReserve:ShowError("Loot reserves are already started in this raid");
        return;
    end

    self.CurrentSession =
    {
        AcceptingReserves    = nil,
        Settings             = LootReserve:Deepcopy(self.NewSessionSettings),
        ItemConditions       = LootReserve:Deepcopy(self:GetNewSessionItemConditions()),
        StartTime            = time(),
        Duration             = self.NewSessionSettings.Duration,
        DurationEndTimestamp = time() + self.NewSessionSettings.Duration, -- Used to resume the session after relog or UI reload
        Members              = { },
        --[[
        {
            [PlayerName] =
            {
                Class         = 1,
                ReservesLeft  = self.CurrentSession.Settings.MaxReservesPerPlayer,
                ReservesDelta = 0,
                ReservedItems = { ItemID, ItemID, ... },
                RollBonus     = { [ItemID] = 0, [ItemID] = 10, ... },
                Locked        = nil,
                OptedOut      = nil,
            },
            ...
        },
        ]]
        WonItems = { },
        --[[
        {
            [ItemID] =
            {
                TotalCount = 0,
                Players    = { PlayerName, PlayerName, ... },
            },
            ...
        },
        ]]
        ItemReserves = { },
        --[[
        {
            [ItemID] =
            {
                Item      = ItemID,
                StartTime = time(),
                Players   = { PlayerName, PlayerName, ... },
            },
            ...
        },
        ]]
        LootTracking = { },
        --[[
        {
            [ItemID] =
            {
                TotalCount = 0,
                Players    = { [PlayerName] = Count, ... },
            },
            ...
        },
        ]]
    };
    self.SaveProfile.CurrentSession = self.CurrentSession;

    LootReserve:ForEachRaider(function(name)
        self.CurrentSession.Members[name] =
        {
            Class         = select(3, LootReserve:UnitClass(name)),
            ReservesLeft  = self.CurrentSession.Settings.MaxReservesPerPlayer,
            ReservesDelta = 0,
            ReservedItems = { },
            RollBonus     = setmetatable({ }, { __index = function() return 0 end }),
            Locked        = nil,
            OptedOut      = nil,
        };
    end);

    self:PrepareSession();

    -- Import reserves
    for player, importedMember in pairs(self.CurrentSession.Settings.ImportedMembers) do
        local member = self.CurrentSession.Members[player] or
        {
            Class         = importedMember.Class,
            ReservesLeft  = self.CurrentSession.Settings.MaxReservesPerPlayer,
            ReservesDelta = 0,
            ReservedItems = { },
            RollBonus     = setmetatable({ }, { __index = function() return 0 end }),
            Locked        = nil,
            OptedOut      = nil,
        };
        member.RollBonus = importedMember.RollBonus;
        self.CurrentSession.Members[player] = member;
        for _, itemID in ipairs(importedMember.ReservedItems) do
            itemID = LootReserve.Data:GetToken(itemID) or itemID;
            if self.ReservableIDs[itemID] and member.ReservesLeft > 0 then
                member.ReservesLeft = member.ReservesLeft - 1;
                table.insert(member.ReservedItems, itemID);

                local reserve = self.CurrentSession.ItemReserves[itemID] or
                {
                    Item      = itemID,
                    StartTime = time(),
                    Players   = { },
                };
                self.CurrentSession.ItemReserves[itemID] = reserve;
                table.insert(reserve.Players, player);
            end
        end
        for _, reserve in pairs(self.CurrentSession.ItemReserves) do
            table.sort(reserve.Players)
        end
    end
    table.wipe(self.NewSessionSettings.ImportedMembers);
    table.wipe(self.CurrentSession.Settings.ImportedMembers);

    LootReserve.Comm:BroadcastVersion();
    LootReserve.Comm:BroadcastSessionInfo(true);

    self:UpdateReserveList();
    self.MembersEdit:UpdateMembersList();

    self:SessionStopped();
    return true;
end

function LootReserve.Server:ResumeSession()
    if not self.CurrentSession then
        LootReserve:ShowError("Loot reserves haven't been started");
        return;
    end

    local previouslyStarted = self.CurrentSession.AcceptingReserves ~= nil;
    
    self.CurrentSession.AcceptingReserves = true;
    self.CurrentSession.DurationEndTimestamp = time() + math.floor(self.CurrentSession.Duration);

    LootReserve.Comm:BroadcastSessionInfo();
    
    if previouslyStarted then
        if self.CurrentSession.Settings.ChatFallback then
            local categories = LootReserve:GetCategoriesText(self.CurrentSession and self.CurrentSession.Settings.LootCategories);
            
            LootReserve:SendChatMessage(format("Accepting loot reserves again%s.%s",
                categories ~= "" and format(" for %s", categories) or "",
                self.CurrentSession.Settings.Lock and " Session is locked. Previous members may not change reserves." or ""
            ), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionResume));
            LootReserve:SendChatMessage("To reserve an item, whisper me: !reserve ItemLinkOrName", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionResume));
            if self.Settings.ChatReservesList then
                if self.CurrentSession.Settings.Blind then
                    LootReserve:SendChatMessage("To see your reserves, whisper me: !myreserves", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionResume));
                else
                    LootReserve:SendChatMessage("To see reserves made, whisper me: !reserves  or  !myreserves", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionResume));
                end
            end
        end
    else
        if self.CurrentSession.Settings.ChatFallback then
            local categories = LootReserve:GetCategoriesText(self.CurrentSession and self.CurrentSession.Settings.LootCategories);
            local duration = self.CurrentSession.Settings.Duration
            local count = self.CurrentSession.Settings.MaxReservesPerPlayer;
            LootReserve:SendChatMessage(format("Loot reserves are now started%s%s%s. %d reserve%s per player%s.",
                categories ~= "" and format(" for %s", categories) or "",
                self.CurrentSession.Settings.Blind and " (blind)" or "",
                duration ~= 0 and format(" and will last for %d:%02d minutes", math.floor(duration / 60), duration % 60) or "",
                count,
                count == 1 and "" or "s",
                self.CurrentSession.Settings.Multireserve > 1 and ", reserving an item multiple times is permitted" or ""
            ), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionStart));
            LootReserve:SendChatMessage("To reserve an item, whisper me: !reserve ItemLinkOrName", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionStart));
            if self.Settings.ChatReservesList then
                if self.CurrentSession.Settings.Blind then
                    LootReserve:SendChatMessage("To see your reserves, whisper me: !myreserves", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionStart));
                else
                    LootReserve:SendChatMessage("To see reserves made, whisper me: !reserves  or  !myreserves", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionStart));
                end
            end
        end
    end

    self:UpdateReserveList();
    self.MembersEdit:UpdateMembersList();

    self:SessionStarted();
    return true;
end

function LootReserve.Server:StopSession()
    if not self.CurrentSession then
        LootReserve:ShowError("Loot reserves haven't been started");
        return;
    end

    self.CurrentSession.AcceptingReserves = false;

    for player, member in pairs(self.CurrentSession.Members) do
        member.Locked = true;
    end

    LootReserve.Comm:BroadcastSessionInfo();
    LootReserve.Comm:SendSessionStop();

    if self.CurrentSession.Settings.ChatFallback then
        local categories = LootReserve:GetCategoriesText(self.CurrentSession and self.CurrentSession.Settings.LootCategories);
        
        LootReserve:SendChatMessage(format("No longer accepting loot reserves%s.",
            categories ~= "" and format(" for %s", categories) or ""
        ), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionStop));
    end

    self:UpdateReserveList();
    self.MembersEdit:UpdateMembersList();

    self:SessionStopped();
    return true;
end

function LootReserve.Server:ResetSession()
    if not self.CurrentSession then
        return true;
    end

    if self.CurrentSession.AcceptingReserves then
        LootReserve:ShowError("You need to stop loot reserves first");
        return;
    end

    if self.RequestedRoll and not self.RequestedRoll.Custom and not self.RequestedRoll.RaidRoll then
        self:CancelRollRequest(self.RequestedRoll.Item);
    end

    LootReserve.Comm:SendSessionReset();

    self.CurrentSession = nil;
    self.SaveProfile.CurrentSession = self.CurrentSession;

    self:UpdateReserveList();
    self:UpdateRollListButtons();
    self.MembersEdit:UpdateMembersList();

    self:SessionReset();
    return true;
end

function LootReserve.Server:IncrementReservesDelta(player, amount, automatic, winner)
    local function Failure(result, ...)
        LootReserve:ShowError(LootReserve.Constants.ReserveDeltaResultText[result]);
        return false;
    end

    if not self.CurrentSession then
        return Failure(LootReserve.Constants.ReserveDeltaResult.NoSession);
    end

    local member = self.CurrentSession.Members[player];
    if not member then
        return Failure(LootReserve.Constants.ReserveDeltaResult.NotMember);
    end
    
    if amount == 0 then return; end
    amount = amount or 1;
    
    member.ReservesLeft = self.CurrentSession.Settings.MaxReservesPerPlayer + member.ReservesDelta - #member.ReservedItems;
    local count = 0 - member.ReservesLeft - amount;
    if count > 0 then
        local reservesCount = { };
        for i = #member.ReservedItems, math.max(#member.ReservedItems - count + 1, 1), -1 do
            reservesCount[member.ReservedItems[i]] = reservesCount[member.ReservedItems[i]] and reservesCount[member.ReservedItems[i]] + 1 or 1;
        end

        -- Removing ReservesLeft first to avoid race condition while sending multiple CancelReserve messages
        for itemID, count in pairs(reservesCount) do
            member.ReservesLeft = member.ReservesLeft - count;
        end
        for itemID, count in pairs(reservesCount) do
            self:CancelReserve(player, itemID, count, false, true, winner, false);
        end
    else
        member.ReservesLeft = member.ReservesLeft + amount;
    end
    
    member.ReservesDelta = member.ReservesDelta + amount;

    -- Send packets
    LootReserve.Comm:SendSessionInfo(player);
    if LootReserve.Client.Masquerade and LootReserve:IsSamePlayer(LootReserve.Client.Masquerade, player) then
        LootReserve.Comm:SendSessionInfo(LootReserve:Me());
    end

    -- Send chat messages
    if self.CurrentSession.Settings.ChatFallback then
        if not self:IsAddonUser(player) and not automatic then
            LootReserve:SendChatMessage(format("Your reserve limit has been %screased to %d. You have %d reserve%s remaining.",
                amount > 0 and "in" or "de",
                self.CurrentSession.Settings.MaxReservesPerPlayer + member.ReservesDelta,
                member.ReservesLeft,
                member.ReservesLeft == 1 and "" or "s"
            ), "WHISPER", player);
        end
    end
    
    self:UpdateReserveList();
    self.MembersEdit:UpdateMembersList();
    return true;
end

function LootReserve.Server:Opt(player, out, chat)
    local masquerade;
    if LootReserve:IsMe(player) and LootReserve.Client.Masquerade then
        player     = LootReserve.Client.Masquerade;
        masquerade = LootReserve:Me();
    end
    
    local function Failure(result, reservesLeft, postText, ...)
        LootReserve.Comm:SendOptResult(masquerade or player, result);
        if chat then
            local text = LootReserve.Constants.OptResultText[result] or "";
            if postText then
                text = text .. postText;
            end
            LootReserve:SendChatMessage(format(text, ...), "WHISPER", player);
        end
        return false;
    end

    if not masquerade and not LootReserve:IsPlayerOnline(player) then
        return Failure(LootReserve.Constants.OptResult.NotInRaid, 0);
    end

    if not self.CurrentSession then
        return Failure(LootReserve.Constants.OptResult.NoSession, 0);
    end

    local member = self.CurrentSession.Members[player];
    if not member then
        return Failure(LootReserve.Constants.OptResult.NotMember, 0);
    end
    
    member.OptedOut = out;

    -- Send packets
    LootReserve.Comm:SendOptResult(player, LootReserve.Constants.OptResult.OK, masquerade);
    LootReserve.Comm:SendOptInfo(player, out);
    if masquerade then
        LootReserve.Comm:SendOptResult(masquerade, LootReserve.Constants.OptResult.OK);
        LootReserve.Comm:SendOptInfo(masquerade, out);
    end

    -- Send chat messages
    if self.CurrentSession.Settings.ChatFallback then
        if chat or not self:IsAddonUser(player) and LootReserve:IsPlayerOnline(player) then
            local categories = LootReserve:GetCategoriesText(self.CurrentSession and self.CurrentSession.Settings.LootCategories);
            
            LootReserve:SendChatMessage(format("%s have opted%s %s using your %d%s reserve%s%s. You can opt back %s with  !opt %s",
                masquerade and "I" or "You",
                masquerade and " you" or "",
                member.OptedOut and "out of" or "into",
                member.ReservesLeft,
                #member.ReservedItems == 0 and "" or " remaining",
                member.ReservesLeft == 1 and "" or "s",
                categories ~= "" and format(" for %s", categories) or "",
                member.OptedOut and "in" or "out",
                member.OptedOut and "in" or "out"
            ), "WHISPER", player);
            self:SendSupportString(player);
            -- self:SendReservesList(player, true);
        end
    end
    

    self:UpdateReserveList();
    self.MembersEdit:UpdateMembersList();
    return true;
end

function LootReserve.Server:Reserve(player, itemID, count, chat, skipChecks)
    count = math.max(1, count or 1);
    
    local masquerade;
    if LootReserve:IsMe(player) and LootReserve.Client.Masquerade then
        player     = LootReserve.Client.Masquerade;
        masquerade = LootReserve:Me();
    end

    local function Failure(result, reservesLeft, postText, ...)
        LootReserve.Comm:SendReserveResult(masquerade or player, itemID, result, reservesLeft);
        if chat then
            local text = LootReserve.Constants.ReserveResultText[result] or "";
            if postText then
                text = text .. postText;
            end
            LootReserve:SendChatMessage(format(text, ...), "WHISPER", player);
        end
        return false;
    end

    if not masquerade and not skipChecks and not LootReserve:IsPlayerOnline(player) then
        return Failure(LootReserve.Constants.ReserveResult.NotInRaid, 0);
    end

    if not self.CurrentSession then
        return Failure(LootReserve.Constants.ReserveResult.NoSession, 0);
    end
    
    if not self.CurrentSession.AcceptingReserves then
        return Failure(LootReserve.Constants.ReserveResult.NotAccepting, 0);
    end

    local member = self.CurrentSession.Members[player];
    if not member then
        return Failure(LootReserve.Constants.ReserveResult.NotMember, 0);
    end

    if not masquerade and not skipChecks and self.CurrentSession.Settings.Lock and member.Locked then
        return Failure(LootReserve.Constants.ReserveResult.Locked, "#");
    end

    if not self.ReservableIDs[itemID] then
        return Failure(LootReserve.Constants.ReserveResult.ItemNotReservable, member.ReservesLeft);
    end

    if not skipChecks then
        local canReserve, conditionResult = LootReserve.ItemConditions:TestPlayer(player, itemID, true);
        if not canReserve then
            return Failure(conditionResult or LootReserve.Constants.ReserveResult.FailedConditions, member.ReservesLeft);
        end

        if self.CurrentSession.Settings.Multireserve <= 1 and LootReserve:Contains(member.ReservedItems, itemID) then
            return Failure(LootReserve.Constants.ReserveResult.AlreadyReserved, member.ReservesLeft);
        end

        if member.ReservesLeft <= 0 then
            return Failure(LootReserve.Constants.ReserveResult.NoReservesLeft, member.ReservesLeft, ". To cancel a reserve, whisper me: !cancel ItemLinkOrName");
        end

        if member.ReservesLeft < count then
            return Failure(LootReserve.Constants.ReserveResult.NotEnoughReservesLeft, member.ReservesLeft, ". You have %d/%d %s left. To cancel a reserve, whisper me: !cancel ItemLinkOrName",
                member.ReservesLeft,
                self.CurrentSession.Settings.MaxReservesPerPlayer + member.ReservesDelta,
                self.CurrentSession.Settings.MaxReservesPerPlayer + member.ReservesDelta == 1 and "reserve" or "reserves"
            );
        end
    end

    -- Create item reserve
    local reserve = self.CurrentSession.ItemReserves[itemID] or
    {
        Item      = itemID,
        StartTime = time(),
        Players   = { },
    };
    self.CurrentSession.ItemReserves[itemID] = reserve;

    local _, myReserves = LootReserve:GetReservesData(reserve.Players, player);
    if myReserves >= self.CurrentSession.Settings.Multireserve then
        return Failure(LootReserve.Constants.ReserveResult.MultireserveLimit, member.ReservesLeft);
    end

    -- Perform reserving
    local result = LootReserve.Constants.ReserveResult.OK;
    for i = 1, count do
        local _, myReserves = LootReserve:GetReservesData(reserve.Players, player);
        if myReserves >= self.CurrentSession.Settings.Multireserve then
            result = LootReserve.Constants.ReserveResult.MultireserveLimitPartial;
            break;
        end

        if not LootReserve.ItemConditions:TestPlayer(player, itemID, true) then
            result = LootReserve.Constants.ReserveResult.FailedLimitPartial;
            break;
        end

        member.OptedOut = nil;
        member.ReservesLeft = member.ReservesLeft - 1;
        table.insert(member.ReservedItems, itemID);
        table.insert(reserve.Players, player);
    end
    table.sort(reserve.Players);

    -- Send packets
    LootReserve.Comm:SendReserveResult(player, itemID, result, member.ReservesLeft, not not masquerade);
    -- LootReserve.Comm:SendOptInfo(player, member.OptedOut);
    if masquerade then
        LootReserve.Comm:SendReserveResult(masquerade, itemID, result, member.ReservesLeft);
        -- LootReserve.Comm:SendOptInfo(masquerade, member.OptedOut);
    end
    
    if self.CurrentSession.Settings.Blind then
        local _, myReserves = LootReserve:GetReservesData(reserve.Players, player);
        LootReserve.Comm:SendReserveInfo(player, itemID, LootReserve:RepeatedTable(player, myReserves));
        if masquerade then
            LootReserve.Comm:SendReserveInfo(masquerade, itemID, LootReserve:RepeatedTable(player, myReserves));
        end
    else
        LootReserve.Comm:BroadcastReserveInfo(itemID, reserve.Players);
    end
    LootReserve:NotifyListeners("RESERVES");

    -- Send chat messages
    if self.CurrentSession.Settings.ChatFallback then
        if chat or not self:IsAddonUser(player) and LootReserve:IsPlayerOnline(player) then
            -- Whisper player
            LootReserve.ItemCache:Item(itemID):OnCache(function(item)
                local reserve = self.CurrentSession.ItemReserves[itemID];
                if not reserve or #reserve.Players == 0 then return; end

                local link = item:GetLink();
                local _, myReserves = LootReserve:GetReservesData(reserve.Players, player);
                LootReserve:SendChatMessage(format("You %s %s%s. %s more %s available. To cancel a reserve, whisper me: !cancel ItemLinkOrName",
                    masquerade and "have had an item added to your reserves:" or "reserved",
                    link,
                    myReserves > 1 and format(" x%d", myReserves) or "",
                    member.ReservesLeft == 0 and "No" or tostring(member.ReservesLeft),
                    member.ReservesLeft == 1 and "reserve" or "reserves"
                ), "WHISPER", player);

                local post = LootReserve:GetReservesString(true, reserve.Players, player, false, link);
                if #post > 0 then
                    LootReserve:SendChatMessage(post, "WHISPER", player);
                end
                self:SendSupportString(player);
            end);
        end

        if self.Settings.ChatUpdates and not self.CurrentSession.Settings.Blind then
            --Whisper others
            LootReserve.ItemCache:Item(itemID):OnCache(function(item)
                local reserve = self.CurrentSession.ItemReserves[itemID];
                if not reserve or #reserve.Players <= 1 then return; end

                local sentToPlayer = { };
                for _, other in ipairs(reserve.Players) do
                    if other ~= player and LootReserve:IsPlayerOnline(other) and not self:IsAddonUser(other) and not sentToPlayer[other] then
                        local post = LootReserve:GetReservesString(true, reserve.Players, other, true, item:GetLink());
                        if #post > 0 then
                            LootReserve:SendChatMessage(post, "WHISPER", other);
                        end
                        sentToPlayer[other] = true;
                    end
                end
            end);
        end
    end

    -- Update UI
    self:UpdateReserveList();
    self.MembersEdit:UpdateMembersList();

    return true;
end

function LootReserve.Server:CancelReserve(player, itemID, count, chat, forced, winner, noRefund)
    count = math.max(1, count or 1);
    
    local masquerade;
    if not forced and LootReserve:IsMe(player) and LootReserve.Client.Masquerade then
        player     = LootReserve.Client.Masquerade;
        masquerade = LootReserve:Me();
    end

    local function Failure(result, reservesLeft, postText, ...)
        LootReserve.Comm:SendCancelReserveResult(masquerade or player, itemID, result, reservesLeft, count);
        if chat then
            local text = LootReserve.Constants.CancelReserveResultText[result] or "";
            if postText then
                text = text .. postText;
            end
            LootReserve:SendChatMessage(format(text, ...), "WHISPER", player);
        end
        return false;
    end

    if not forced and not masquerade and not LootReserve:IsPlayerOnline(player) then
        return Failure(LootReserve.Constants.CancelReserveResult.NotInRaid, 0);
    end

    if not self.CurrentSession then
        return Failure(LootReserve.Constants.CancelReserveResult.NoSession, 0);
    end
    
    if not forced and not self.CurrentSession.AcceptingReserves then
        return Failure(LootReserve.Constants.CancelReserveResult.NotAccepting, 0);
    end

    local member = self.CurrentSession.Members[player];
    if not member then
        return Failure(LootReserve.Constants.CancelReserveResult.NotMember, 0);
    end

    if not forced and not masquerade and self.CurrentSession.Settings.Lock and member.Locked then
        return Failure(LootReserve.Constants.CancelReserveResult.Locked, "#");
    end

    if not self.ReservableIDs[itemID] then
        return Failure(LootReserve.Constants.CancelReserveResult.ItemNotReservable, member.ReservesLeft);
    end

    if not LootReserve:Contains(member.ReservedItems, itemID) then
        return Failure(LootReserve.Constants.CancelReserveResult.NotReserved, member.ReservesLeft);
    end

    local reserve = self.CurrentSession.ItemReserves[itemID];
    if not reserve then
        return Failure(LootReserve.Constants.CancelReserveResult.InternalError, member.ReservesLeft);
    end

    local _, myReserves = LootReserve:GetReservesData(reserve.Players, player);
    if myReserves < count then
        return Failure(LootReserve.Constants.CancelReserveResult.NotEnoughReserves, member.ReservesLeft);
    end

    -- Perform reserve cancelling
    for i = 1, count do
        if not LootReserve:Contains(member.ReservedItems, itemID) then
            break;
        end

        -- Remove player from the active roll on that item
        if self:IsRolling(itemID) and not self.RequestedRoll.Custom and not self.RequestedRoll.RaidRoll and self.RequestedRoll.Players[player] then
            if #self.RequestedRoll.Players[player] == 1 then
                self.RequestedRoll.Players[player] = nil;
            else
                table.remove(self.RequestedRoll.Players[player]);
            end
        end

        member.OptedOut = nil;
        member.ReservesLeft = math.min(member.ReservesLeft + (noRefund and 0 or 1), self.CurrentSession.Settings.MaxReservesPerPlayer + member.ReservesDelta);
        LootReserve:TableRemove(member.ReservedItems, itemID);
        LootReserve:TableRemove(reserve.Players, player);
    end

    -- Send packets
    if not (LootReserve.Client.Masquerade and forced and LootReserve:IsMe(player)) then
        -- Don't send if client is masquerading and the server cancelled own reserve from server window. This would send wrong player's data to client
        -- LootReserve.Comm:SendOptInfo(player, member.OptedOut);
        LootReserve.Comm:SendCancelReserveResult(player, itemID, (forced or masquerade) and LootReserve.Constants.CancelReserveResult.Forced or LootReserve.Constants.CancelReserveResult.OK, member.ReservesLeft, count, winner);
    end
    if masquerade then
        -- LootReserve.Comm:SendOptInfo(masquerade, member.OptedOut);
        LootReserve.Comm:SendCancelReserveResult(masquerade, itemID, LootReserve.Constants.CancelReserveResult.OK, member.ReservesLeft, count, winner);
    end
    
    if self.CurrentSession.Settings.Blind then
        local _, myReserves = LootReserve:GetReservesData(reserve.Players, player);
        LootReserve.Comm:SendReserveInfo(player, itemID, LootReserve:RepeatedTable(player, myReserves));
        if masquerade then
            LootReserve.Comm:SendReserveInfo(masquerade, itemID, LootReserve:RepeatedTable(player, myReserves));
        end
    else
        LootReserve.Comm:BroadcastReserveInfo(itemID, reserve.Players);
    end
    LootReserve:NotifyListeners("RESERVES");

    -- Remove the item entirely if all reserves were cancelled
    if #reserve.Players == 0 then
        self.CurrentSession.ItemReserves[itemID] = nil;
    end

    -- Send chat messages
    if self.CurrentSession.Settings.ChatFallback then
        if chat or not self:IsAddonUser(player) and LootReserve:IsPlayerOnline(player) then
            -- Whisper player
            LootReserve.ItemCache:Item(itemID):OnCache(function(item)
                local link = item:GetLink();
                if winner then
                    LootReserve:SendChatMessage(format("Your reserve for %s%s has been automatically removed due to winning an item.", link, count > 1 and format(" x%d", count) or ""), "WHISPER", player);
                else
                    LootReserve:SendChatMessage(format((forced or masquerade) and "Your reserve for %s%s has been removed. %d more %s available.%s" or "You cancelled your reserve for %s%s. %d more %s available.%s",
                        link,
                        count > 1 and format(" x%d", count) or "",
                        member.ReservesLeft,
                        member.ReservesLeft == 1 and "reserve" or "reserves",
                        "You can check your reserves with  !myreserves"
                    ), "WHISPER", player);
                end
            end);
        end

        if self.Settings.ChatUpdates and not self.CurrentSession.Settings.Blind then
            -- Whisper others
            LootReserve.ItemCache:Item(itemID):OnCache(function(item)
                local reserve = self.CurrentSession.ItemReserves[itemID];
                if not reserve or #reserve.Players == 0 then return; end

                local sentToPlayer = { };
                for _, other in ipairs(reserve.Players) do
                    if player ~= other and LootReserve:IsPlayerOnline(other) and not self:IsAddonUser(other) and not sentToPlayer[other] then
                        local post = LootReserve:GetReservesString(true, reserve.Players, other, true, item:GetLink());
                        if #post > 0 then
                            LootReserve:SendChatMessage(post, "WHISPER", other);
                        end
                        sentToPlayer[other] = true;
                    end
                end
            end);
        end
    end
    
    if winner then
        LootReserve.ItemCache:Item(itemID):OnCache(function(item)
            LootReserve:PrintMessage(format("%s'%s reserve for %s%s has been automatically removed.",
                LootReserve:ColoredPlayer(player),
                player:match(".$") == "s" and "" or "s",
                item:GetLink(),
                count > 1 and format(" x%d", count) or ""
            ));
        end);
    end

    -- Remove member info if player no longer has any reserves left and isn't in the group anymore
    self:UpdateGroupMembers();

    -- Update UI
    self:UpdateReserveList();
    self:UpdateReserveListRolls();
    self.MembersEdit:UpdateMembersList();

    return true;
end

function LootReserve.Server:SendReservesList(player, onlyRelevant, force, itemList)
    if player then
        if not LootReserve:IsPlayerOnline(player) then
            LootReserve:SendChatMessage("You are not in the raid", "WHISPER", player);
            return;
        end

        if not self.CurrentSession then
            LootReserve:SendChatMessage("Loot reserves aren't active in your raid", "WHISPER", player);
            return;
        end

        if not self.CurrentSession.Members[player] then
            LootReserve:SendChatMessage("You are not participating in loot reserves", "WHISPER", player);
            return;
        end

        if self.CurrentSession.Settings.Blind then
            LootReserve:SendChatMessage("Blind reserves in effect, you can't see what other players have reserved", "WHISPER", player);
            return;
        end
    else
        if not self.CurrentSession then
            LootReserve:ShowError("Loot reserves aren't active in your raid");
            return;
        end

        if self.CurrentSession.Settings.Blind and not force then
            StaticPopup_Show("LOOTRESERVE_CONFIRM_ANNOUNCE_BLIND_RESERVES");
            return;
        end
    end

    if self.CurrentSession.Settings.ChatFallback then
        -- whisper player
        local function WhisperPlayer()
            local list = { };

            local function sortByItemName(_, _, aItemID, bItemID)
                aItem = LootReserve.ItemCache:Item(aItemID);
                bItem = LootReserve.ItemCache:Item(bItemID);
                if not aItem or not aItem:GetInfo() then
                    return false;
                end
                if not bItem or not bItem:GetInfo() then
                    return false;
                end
                return aItem:GetName() < bItem:GetName();
            end

            local missing = { };
            for itemID, reserve in LootReserve:Ordered(self.CurrentSession.ItemReserves, sortByItemName) do
                if not itemList or itemList[itemID] then
                    local item = LootReserve.ItemCache:Item(itemID);
                    if item:IsCached() then
                        local reservesText = LootReserve:GetReservesData(self.CurrentSession.ItemReserves[itemID].Players);
                        local _, myReserves = LootReserve:GetReservesData(self.CurrentSession.ItemReserves[itemID].Players, player);
                        if not onlyRelevant or myReserves > 0 then
                            table.insert(list, format("%s: %s", item:GetLink(), reservesText));
                        end
                    elseif item:Exists() then
                        table.insert(missing, item);
                    end
                end
            end
            if #missing > 0 then
                LootReserve.ItemCache:OnCache(missing, WhisperPlayer);
                return;
            end

            if #list > 0 then
                LootReserve:SendChatMessage(format("%seserved items:", onlyRelevant and "Your r" or "R"), player and "WHISPER" or self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionReserves), player);
                for _, line in ipairs(list) do
                    LootReserve:SendChatMessage(line, player and "WHISPER" or self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionReserves), player);
                end
            else
                local count = 0;
                for _ in pairs(itemList or {}) do
                    count = count + 1;
                end
                local message;
                if onlyRelevant then
                    message = "You currently have no reserves. To reserve an item, whisper me: !reserve ItemLinkOrName";
                elseif count > 0 then
                    message = count > 1 and "There are currently no reserves on these items" or "There are currently no reserves on this item";
                else
                    message = "There are currently no reserves";
                end
                LootReserve:SendChatMessage(message, player and "WHISPER" or self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionReserves), player);
            end
            if player then self:SendSupportString(player); end
        end
        WhisperPlayer();
    end
end

function LootReserve.Server:IsRolling(item)
    return self.RequestedRoll and self.RequestedRoll.Item == LootReserve.ItemCache:Item(item) or false;
end

function LootReserve.Server:ExpireRollRequest()
    if self.RequestedRoll then
        local item = self.RequestedRoll.Item;
        local disenchanter = self:GetDisenchanter();
        if self:GetWinningRollAndPlayers(self.RequestedRoll) then
            -- If someone rolled on this phase - end the roll
            if self.Settings.RollFinishOnExpire then
                self:FinishRollRequest(self.RequestedRoll.Item);
            end
        else
            -- If nobody rolled on this phase - advance to the next
            if self.Settings.RollAdvanceOnExpire and not self.RequestedRoll.Tiered then
                if not self:AdvanceRollPhase(self.RequestedRoll.Item) then
                    -- If the phase cannot advance (i.e. because we ran out of phases) - end the roll
                    if self.Settings.RollFinishOnExpire then
                        self:FinishRollRequest(self.RequestedRoll.Item);
                        if disenchanter then
                            self:RecordDisenchant(item, disenchanter);
                        end
                    end
                end
            elseif not self.RequestedRoll.Phases or #self.RequestedRoll.Phases <= 1 or self.RequestedRoll.Tiered then
                -- If no more phases remaining - end the roll
                if self.Settings.RollFinishOnExpire then
                    self:FinishRollRequest(self.RequestedRoll.Item);
                    if disenchanter then
                        self:RecordDisenchant(item, disenchanter);
                    end
                end
            end
        end

        self:RollEnded();
    end
end

function LootReserve.Server:TryFinishRoll()
    if self.RequestedRoll then
        -- Check if only one player exists in the roll request
        if not self.RequestedRoll.Custom and not self.RequestedRoll.RaidRoll and self.Settings.RollSkipNotContested then
            local count = 0;
            local winner;
            for player, roll in pairs(self.RequestedRoll.Players) do
                count = count + 1;
                winner = player;
            end
            if count == 1 then
                self:FinishRollRequest(self.RequestedRoll.Item, true);
                self:RollEnded();
                return true;
            end
        end

        -- Check if any player other than the current winning player has still not rolled
        if (not self.RequestedRoll.Custom or self.RequestedRoll.AllowedPlayers) and not self.RequestedRoll.RaidRoll and self.Settings.RollFinishOnAllReservingRolled then
            local highestPlayers = select(2, self:GetWinningRollAndPlayers(self.RequestedRoll)) or { };
            local missingRolls = #highestPlayers ~= 1;
            if not missingRolls then
                for player, roll in self:GetOrderedPlayerRolls(self.RequestedRoll.Players) do
                    if roll == LootReserve.Constants.RollType.NotRolled and player ~= highestPlayers[1] then
                        missingRolls = true;
                        break;
                    end
                end
            end
            if not missingRolls then
                self:FinishRollRequest(self.RequestedRoll.Item);
                self:RollEnded();
                return true;
            end
        end

        -- Check if this is a raid roll that should autocomplete
        if self.RequestedRoll.RaidRoll and self.Settings.RollFinishOnRaidRoll and next(self.RequestedRoll.Players) then
            self:FinishRollRequest(self.RequestedRoll.Item);
            self:RollEnded();
            return true;
        end

        return false;
    end
end

function LootReserve.Server:GetWinningRollAndPlayers(Roll)
    if Roll then
        local highestRoll = LootReserve.Constants.RollType.NotRolled;
        local highestPlayers = { };
        local losers = { };
        for player, roll in self:GetOrderedPlayerRolls(Roll.Players) do
            if highestRoll <= roll and roll > LootReserve.Constants.RollType.NotRolled then
                if highestRoll ~= roll then
                    highestRoll = roll;
                    for _, player in ipairs(highestPlayers) do
                        table.insert(losers, player);
                    end
                    table.wipe(highestPlayers);
                end
                if not LootReserve:Contains(highestPlayers, player) then
                    table.insert(highestPlayers, player);
                end
            elseif roll > LootReserve.Constants.RollType.NotRolled then
                table.insert(losers, player);
            end
        end
        if highestRoll > LootReserve.Constants.RollType.NotRolled then
            for _, winner in ipairs(highestPlayers) do
                LootReserve:TableRemove(losers, winner);
            end
            return highestRoll, highestPlayers, losers;
        end
    end
end

function LootReserve.Server:ResolveRollTie(item)
    if self:IsRolling(item) then
        local roll, winners, losers = self:GetWinningRollAndPlayers(self.RequestedRoll);
        if roll and winners and #winners > 1 then
            if self.RequestedRoll.Tiered then
                roll = self:ConvertFromTieredRoll(roll);
            end
            item:OnCache(function()
                local playersText = LootReserve:FormatReservesText(winners);
                
                local msg = format("Tie for %s between players %s. All rolled %d. Please /roll again", item:GetLink(), playersText, roll);
                LootReserve:SendChatMessage(msg, self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollTie));
            end);

            
            local phase;
            if self.RequestedRoll.RaidRoll then
                phase = LootReserve.Constants.WonRollPhase.RaidRoll;
            elseif self.RequestedRoll.Custom then
                phase = self.RequestedRoll.Phases and self.RequestedRoll.Phases[1];
            else
                phase = LootReserve.Constants.WonRollPhase.Reserve;
            end
            LootReserve.Comm:BroadcastWinner(item, { }, losers, roll, self.RequestedRoll.Custom, phase, self.RequestedRoll.RaidRoll);
            
            if self.RequestedRoll.Custom then
                self:CancelRollRequest(item);
                self:RequestCustomRoll(item, self.Settings.RollLimitDuration and self.Settings.RollDuration or nil, nil, nil, winners);
            else
                self:CancelRollRequest(item);
                self:RequestRoll(item, winners);
            end
        end
    end
end

function LootReserve.Server:FinishRollRequest(item, soleReserver, silent, noLosers)
    local function RecordRollWinner(player, item, phase)
        if self.CurrentSession then
            local token;
            if self.ReservableRewardIDs[item:GetID()] then
                token = LootReserve.ItemCache:Item(LootReserve.Data:GetToken(item:GetID())) or LootReserve.ItemCache:Item(LootReserve.Data:GetToken(item:GetID()));
            end
            local member = self.CurrentSession.Members[player];
            if member then
                if not member.WonRolls then member.WonRolls = { }; end
                table.insert(member.WonRolls,
                {
                    Item  = token or item,
                    Phase = phase,
                    Time  = time(),
                });
            end

            local itemWinners = self.CurrentSession.WonItems[token and token:GetID() or item:GetID()] or {
                TotalCount = 0,
                Players    = { },
            };
            self.CurrentSession.WonItems[token and token:GetID() or item:GetID()] = itemWinners;
            table.insert(itemWinners.Players, player);
            itemWinners.TotalCount = itemWinners.TotalCount + 1;
        end
    end

    if self:IsRolling(item) then
        local masterLoot = nil;
        local roll, winners, losers = self:GetWinningRollAndPlayers(self.RequestedRoll);
        if roll and winners then
            local raidroll = self.RequestedRoll.RaidRoll;
            local phases = LootReserve:Deepcopy(self.RequestedRoll.Phases);
            local max = 100;
            if self.RequestedRoll.Tiered then
                roll, max = self:ConvertFromTieredRoll(roll);
            end

            local recordPhase;
            local announcePhase;
            if self.RequestedRoll.RaidRoll then
                recordPhase = LootReserve.Constants.WonRollPhase.RaidRoll;
                announcePhase = recordPhase;
            elseif self.RequestedRoll.Custom then
                recordPhase = phases and phases[101-max];
                announcePhase = recordPhase;
            else
                recordPhase = LootReserve.Constants.WonRollPhase.Reserve;
            end
            for _, player in ipairs(winners) do
                RecordRollWinner(player, item, recordPhase);
            end
            if not silent then
                LootReserve.Comm:BroadcastWinner(item, winners, noLosers and { } or losers, roll, self.RequestedRoll.Custom, recordPhase, raidroll);
                
                -- Announce winner
                item:OnCache(function()
                    local link        = item:GetLink();
                    local playersText = LootReserve:FormatPlayersText(winners);
                    LootReserve:SendChatMessage(format(raidroll and "%s won %s%s via raid-roll" or "%s won %s%s with %s of %d", playersText, LootReserve:FixLink(link), announcePhase and format(" for %s", announcePhase or "") or "", #winners > 1 and "rolls" or "a roll", roll), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollWinner));
                    if LootReserve.Server.Settings.ChatAnnounceWinToGuild and IsInGuild() and item:GetQuality() >= (LootReserve.Server.Settings.ChatAnnounceWinToGuildThreshold or 3) then
                        for _, player in ipairs(winners) do
                            if LootReserve:Contains(self.GuildMembers, player) then
                                LootReserve:SendChatMessage(format("%s won %s%s", playersText, LootReserve:FixLink(link), recordPhase and format(" for %s", recordPhase or "") or ""), "GUILD");
                                break;
                            end
                        end
                    end
                end);
            end

            if self.Settings.RollMasterLoot then
                masterLoot = function() self:MasterLootItem(item, winners[1], #winners > 1); end;
            end
        elseif soleReserver and not self.RequestedRoll.Custom and next(self.RequestedRoll.Players) then
            local player = next(self.RequestedRoll.Players);
            winners = { player };
            RecordRollWinner(player, item, LootReserve.Constants.WonRollPhase.Reserve);
            
            if not silent then
                -- Send packets
                LootReserve.Comm:SendWinner(player, item, winners, { });
                
                -- Announce
                item:OnCache(function()
                    local link = item:GetLink();
                    LootReserve:SendChatMessage(format("%s won %s as the only reserver", player, LootReserve:FixLink(link)), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollWinner));
                    if LootReserve.Server.Settings.ChatAnnounceWinToGuild and IsInGuild() and item:GetQuality() >= (LootReserve.Server.Settings.ChatAnnounceWinToGuildThreshold or 3) then
                        if LootReserve:Contains(self.GuildMembers, player) then
                            LootReserve:SendChatMessage(format("%s won %s", player, LootReserve:FixLink(link)), "GUILD");
                        end
                    end
                end);
            end

            if self.Settings.RollMasterLoot then
                masterLoot = function() self:MasterLootItem(item, player); end;
            end
        end

        self:CancelRollRequest(item, winners);
        if masterLoot then
            masterLoot();
        end
    end

    self:UpdateReserveListRolls();
    self:UpdateRollListRolls();
    self.MembersEdit:UpdateMembersList();
end

function LootReserve.Server:AdvanceRollPhase(item)
    if self:IsRolling(item) then
        if self:GetWinningRollAndPlayers(self.RequestedRoll) then return; end
        if not self.RequestedRoll.Custom then return; end

        local phases = LootReserve:Deepcopy(self.RequestedRoll.Phases);
        if not phases or #phases <= 1 then return; end
        table.remove(phases, 1);

        self:CancelRollRequest(item, nil, nil, true);
        self:RequestCustomRoll(item, self.Settings.RollLimitDuration and self.Settings.RollDuration or nil, phases, self.Settings.RollUseTiered or nil);
        return true;
    end
end

function LootReserve.Server:CancelRollRequest(item, winners, noHistory, advancing)
    self.NextRollCountdown = nil;
    if self:IsRolling(item) then
        if type(item) == "number" then
            item = self.RequestedRoll.Item;
        end
        -- Cleanup chat from players who didn't roll to reduce memory and storage space usage
        if self.RequestedRoll.Chat then
            local toRemove = { };
            for player in pairs(self.RequestedRoll.Chat) do
                if not self:HasRelevantRecentChat(self.RequestedRoll, player) then
                -- if not self.RequestedRoll.Players[player] then
                    table.insert(toRemove, player);
                end
            end
            for _, player in ipairs(toRemove) do
                self.RequestedRoll.Chat[player] = nil;
            end
        end
        
        local RequestedRoll = self.RequestedRoll;
        self.RequestedRoll = nil;
        self.SaveProfile.RequestedRoll = self.RequestedRoll;

        local uniqueWinners = { };
        for _, winner in ipairs(winners or { }) do
            uniqueWinners[winner] = true;
        end
        if not noHistory then
            if winners then
                self:RecordRollHistory(RequestedRoll, winners[1]);
                if self.Settings.RemoveRecentLootAfterRolling then
                    LootReserve:TableRemove(self.RecentLoot, item);
                end
                if #winners > 1 then
                    for i = 2, #winners do
                        local Roll, doRequestedRoll = self:GetContinueRollData(self.RollHistory[#self.RollHistory]);
                        self:RecordRollHistory(Roll, winners[i]);
                        if self.Settings.RemoveRecentLootAfterRolling then
                            LootReserve:TableRemove(self.RecentLoot, item);
                        end
                    end
                end
            else
                self:RecordRollHistory(RequestedRoll);
                if not advancing and self.Settings.RemoveRecentLootAfterRolling then
                    while LootReserve:TableRemove(LootReserve.Server.RecentLoot, item) do end
                end
            end
        end
        
        if not advancing then
            LootReserve.Comm:BroadcastRequestRoll(LootReserve.ItemCache:Item(0), { }, RequestedRoll and (RequestedRoll.Custom or RequestedRoll.RaidRoll));
        end
        
        -- Remove winners' reserves
        if self.CurrentSession and not RequestedRoll.Custom then
            local token;
            if self.ReservableRewardIDs[item:GetID()] then
                token = LootReserve.ItemCache:Item(LootReserve.Data:GetToken(item:GetID())) or LootReserve.ItemCache:Item(LootReserve.Data:GetToken(item:GetID()));
            end
            local itemID = token and token:GetID() or item:GetID();
            LootReserve.ItemCache:Item(itemID):OnCache(function(reservedItem)
                for player in pairs(uniqueWinners) do
                    if self.CurrentSession.ItemReserves[reservedItem:GetID()] and LootReserve:Contains(self.CurrentSession.ItemReserves[reservedItem:GetID()].Players, player) then
                        local smartOverride;
                        if self.Settings.WinnerReservesRemoval == LootReserve.Constants.WinnerReservesRemoval.Smart then
                            -- For most items, assume the player can only use one.
                            smartOverride = LootReserve.Constants.WinnerReservesRemoval.Duplicate;
                            -- If players can reserve unusable items, never remove more than one reserve.
                            if not self.CurrentSession.Settings.Equip then
                                smartOverride = LootReserve.Constants.WinnerReservesRemoval.Single;
                                
                            -- Make sure the item is not unique and is not a quest starter.
                            elseif not reservedItem:IsUnique() and not item:StartsQuest() and not (reservedItem:GetType() == "Recipe" and reservedItem:GetBindType() == LE_ITEM_BIND_ON_ACQUIRE) then
                                -- Players may genuinely want multiple copies of the same ring to equip together.
                                if reservedItem:GetEquipLocation() == "INVTYPE_FINGER" then
                                    smartOverride = LootReserve.Constants.WinnerReservesRemoval.Single;
                                -- Trying to filter to raid mats. Excluding equippable items, tokens, and quest drops.
                                elseif reservedItem:GetEquipLocation() == "" and not LootReserve.Data:IsToken(reservedItem:GetID()) and not LootReserve.Data.QuestDrops[reservedItem:GetID()] then
                                    smartOverride = LootReserve.Constants.WinnerReservesRemoval.Single;
                                end
                            end
                        end
                        
                        if self.Settings.WinnerReservesRemoval == LootReserve.Constants.WinnerReservesRemoval.Single or smartOverride == LootReserve.Constants.WinnerReservesRemoval.Single then
                            self:CancelReserve(player, reservedItem:GetID(), 1, false, true, true, true);
                            self:IncrementReservesDelta(player, -1, true);
                        elseif self.Settings.WinnerReservesRemoval == LootReserve.Constants.WinnerReservesRemoval.Duplicate or smartOverride == LootReserve.Constants.WinnerReservesRemoval.Duplicate then
                            local count = 0;
                            for i, id in ipairs(self.CurrentSession.Members[player].ReservedItems) do
                                if id == reservedItem:GetID() then
                                    count = count + 1;
                                end
                            end
                            self:CancelReserve(player, reservedItem:GetID(), count, false, true, true, true);
                            self:IncrementReservesDelta(player, 0 - count, true);
                        elseif self.Settings.WinnerReservesRemoval == LootReserve.Constants.WinnerReservesRemoval.All then
                            self:IncrementReservesDelta(player, 0 - self.CurrentSession.Members[player].ReservesLeft - #self.CurrentSession.Members[player].ReservedItems, true, true);
                        end
                    end
                end
            end)
        end
        self:UpdateReserveListRolls();
        self:UpdateRollList();
    end
end

function LootReserve.Server:RecordRollHistory(roll, winner)
    if winner then
        roll.Winners = { winner };
    end
    local historicalEntry = LootReserve:Deepcopy(roll);
    historicalEntry.Item = LootReserve.ItemCache:Item(historicalEntry.Item);
    historicalEntry.Duration    = nil;
    historicalEntry.MaxDuration = nil;
    if winner and (LootReserve:IsLootingItem(historicalEntry.Item) or not (LootReserve:IsMe(winner) and LootReserve:GetTradeableItemCount(historicalEntry.Item) > 0)) then
        historicalEntry.Owed = true;
        table.insert(self.OwedRolls, historicalEntry);
    end
    table.insert(self.RollHistory, historicalEntry);
    if #self.RollHistory > self.Settings.RollHistoryKeepLimit then
        wipe(self.OwedRolls);
        local delta = #self.RollHistory - self.Settings.RollHistoryKeepLimit;
        for i = 1, self.Settings.RollHistoryKeepLimit do
            self.RollHistory[i] = self.RollHistory[i+1];
            if self.RollHistory[i].Owed then
                table.insert(self.OwedRolls, self.RollHistory[i]);
            end
        end
        for i = #self.RollHistory, self.Settings.RollHistoryKeepLimit + 1, -1 do
            self.RollHistory[i] = nil;
        end
    end
end

function LootReserve.Server:RecordDisenchant(item, disenchanter, handleRecentLootRemoval)
    LootReserve.Server:RecordRollHistory(
    {
        Players = { [disenchanter] = { 0 } },
        Item = item,
        StartTime = time(),
        Disenchant = true,
    }, disenchanter);
    if self.Settings.RollMasterLoot then
        self:MasterLootItem(item, disenchanter);
    end
    if handleRecentLootRemoval and self.Settings.RemoveRecentLootAfterRolling then
        LootReserve:TableRemove(self.RecentLoot, item);
    end
    self:UpdateRollList();
end

function LootReserve.Server:GetDisenchanter()
    local names = { };
    LootReserve:ForEachRaider(function(name) names[name] = true end);
    if self.Settings.RollDisenchant then
        for _, name in ipairs(self.Settings.RollDisenchanters) do
            if names[name] then
                return name;
            end
        end
    end
    return nil;
end

function LootReserve.Server:GetContinueRollData(oldRoll)
    -- Copy historical roll into RequestedRoll
    local Roll = LootReserve:Deepcopy(oldRoll);
    Roll.Item = oldRoll.Item;
    
    -- Discard deleted and passed rolls
    local toRemove = { };
    for player, rolls in pairs(Roll.Players) do
        for i = #rolls, 1, -1 do
            if rolls[i] < 0 then
              table.remove(rolls, i);
            end
        end
        if #rolls == 0 then
          table.insert(toRemove, player);
        end
    end
    for _, player in ipairs(toRemove) do
      Roll.Players[player] = nil;
    end
    
    local doRequestRoll = true;
    if Roll.Disenchant then
        doRequestRoll = false;
    elseif Roll.Custom then
        for _, winner in ipairs(Roll.Winners or {}) do
            Roll.Players[winner] = nil;
        end
        if not next(Roll.Players) then
            local phases = Roll.Phases;
            if phases and #phases > 1 then
                table.remove(phases, 1);
            else
                doRequestRoll = nil;
            end
        end
    elseif Roll.Winners then
        if self.CurrentSession then
            for _, winner in ipairs(Roll.Winners) do
                -- Remove winning roll
                local maxI, maxRoll = 1, Roll.Players[winner][1];
                for i, roll in ipairs(Roll.Players[winner]) do
                    if roll > maxRoll then
                        maxI, maxRoll= i, roll;
                    end
                end
                table.remove(Roll.Players[winner], maxI);
                
                if #Roll.Players[winner] == 0 then
                    Roll.Players[winner] = nil;
                end
                local reserve = self.CurrentSession.ItemReserves[Roll.Item:GetID()];
                if not reserve or not LootReserve:Contains(reserve.Players, winner) then
                    Roll.Players[winner] = nil;
                end
            end
            if not next(Roll.Players) then
                doRequestRoll = nil;
            end
        else
            doRequestRoll = nil;
        end
    end
    Roll.Winners = nil;
    Roll.Owed    = nil;
    
    Roll.MaxDuration = self.Settings.RollLimitDuration and self.Settings.RollDuration or nil
    Roll.Duration    = Roll.MaxDuration and 0 or nil
    
    return Roll, doRequestRoll;
end

function LootReserve.Server:ContinueRoll(oldRoll, noFill)
    if self.RequestedRoll then
        LootReserve:ShowError("There's a roll in progress");
        return;
    end
    
    local Roll, doRequestedRoll = self:GetContinueRollData(oldRoll);
    if doRequestedRoll then
        if next(Roll.Players or {}) then
            self.RequestedRoll             = Roll;
            self.SaveProfile.RequestedRoll = Roll;
        elseif Roll.Custom then
            self:RequestCustomRoll(Roll.Item, self.Settings.RollLimitDuration and self.Settings.RollDuration or nil, Roll.Phases, Roll.Tiered, next(Roll.Players) and Roll.Players or nil);
        else
            self:RequestRoll(Roll.Item)
        end
    end
    
    -- Fill the item frame with the previously reserved item, or empty it
    for _, panelRolls in ipairs({self.Window.PanelRollsLockdown, self.Window.PanelRolls}) do
        local frames = panelRolls.Scroll.Container.Frames;
        if frames and frames[1] and frames[1]:IsShown() then
            frames[1]:SetItem(not noFill and not self.RequestedRoll and Roll.Item or nil);
        end
        panelRolls.Scroll:SetVerticalScroll(0);
    end
    
    self:UpdateRollList();
end

function LootReserve.Server:CanRoll(player, rollTier)
    -- Roll must exist
    if not self.RequestedRoll then return false; end
    -- Roll must not have expired yet
    if self.RequestedRoll.MaxDuration and self.RequestedRoll.Duration == 0 and not self.Settings.AcceptRollsAfterTimerEnded then return false; end
    -- Player must be online and in raid
    if not LootReserve:IsPlayerOnline(player) then return false; end
    -- Player must be allowed to roll if the roll is limited to specific players
    if self.RequestedRoll.AllowedPlayers and not LootReserve:Contains(self.RequestedRoll.AllowedPlayers, player) then return false; end
    -- Only raid roll creator is allowed to re-roll the raid-roll
    if self.RequestedRoll.RaidRoll then return LootReserve:IsMe(player); end
    -- Player must have reserved the item if the roll is for a reserved item
    if not self.RequestedRoll.Custom and not self.RequestedRoll.Players[player] then return false; end
    -- Player cannot roll if it's a tiered roll and they've passed or deleted a roll at this tier
    if rollTier and self.RequestedRoll.Tiered and self.RequestedRoll.Tiered[player] and self.RequestedRoll.Tiered[player][rollTier] then
        return false;
    end
    -- Player cannot roll if they have already passed, or have rolled their allotted number of times already
    if self.RequestedRoll.Players[player] then
        local hasRoll = false;
        for _, roll in ipairs(self.RequestedRoll.Players[player]) do
            if self.RequestedRoll.Tiered and rollTier then
                local roll, max = self:ConvertFromTieredRoll(roll);
                if max == rollTier then
                    return false;
                end
            elseif roll == LootReserve.Constants.RollType.NotRolled then
               hasRoll = true;
               break;
            elseif roll == LootReserve.Constants.RollType.Passed then
                return false;
            end
        end
        if not hasRoll and not self.RequestedRoll.Tiered then
            return false;
        end
    end

    return true;
end

function LootReserve.Server:PrepareRequestRoll()
    if self.RequestedRoll and self.RequestedRoll.Duration and not self.RollDurationUpdateRegistered then
        self.RollDurationUpdateRegistered = true;
        LootReserve:RegisterUpdate(function(elapsed)
            if self.RequestedRoll and self.RequestedRoll.Duration and self.RequestedRoll.Duration ~= 0 then
                if self.RequestedRoll.Duration > elapsed then
                    self.RequestedRoll.Duration = self.RequestedRoll.Duration - elapsed;
                    if self.Settings.RollCountdown then
                        if not self.NextRollCountdown then
                            self.NextRollCountdown = math.min(self.Settings.RollCountdown, math.floor(self.RequestedRoll.Duration));
                        end
                        if self.RequestedRoll.Duration <= self.NextRollCountdown then
                            LootReserve:SendChatMessage(format("%d...", self.NextRollCountdown), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollCountdown));
                            self.NextRollCountdown = self.NextRollCountdown - 1;
                        end
                    end
                else
                    self.RequestedRoll.Duration = 0;
                    self.NextRollCountdown = nil;
                    self:ExpireRollRequest();
                end
            end
        end);
    end

    if not self.RollMatcherRegistered then
        self.RollMatcherRegistered = true;
        local rollMatcher = LootReserve:FormatToRegexp(RANDOM_ROLL_RESULT);
        LootReserve:RegisterEvent("CHAT_MSG_SYSTEM", function(text)
            if self.RequestedRoll then
                local player, roll, min, max = text:match(rollMatcher);
                if player and LootReserve:IsCrossRealm() then
                    -- Roll chat messages don't have the player's realm in them, ever.
                    -- In case we have two players with the same name in the raid, the best we can do right now
                    -- is to just find the first-best online player with matching name who's eligible to roll
                    -- and attribute the roll to them. It's exploitable, but that's the best we can do in these circumstances...
                    player = LootReserve:ForEachRaider(function(name, _, _, _, _, _, _, online)
                        if online and strsplit("-", name) == player and self:CanRoll(name, self.RequestedRoll.Tiered and max or nil) then
                            return name;
                        end
                    end);
                end
                player = player and LootReserve:Player(player);
                local roll, min, max = tonumber(roll), tonumber(min), tonumber(max);
                if player and roll then
                    if self.RequestedRoll.Tiered then
                        roll = self:ConvertToTieredRoll(roll, max);
                    end
                    local valid = self:CanRoll(player, self.RequestedRoll.Tiered and max or nil);
                    if valid then
                        if self.RequestedRoll.RaidRoll then
                            valid = min == 1 and max == LootReserve:GetNumGroupMembers();
                        elseif self.RequestedRoll.Tiered then
                            valid = min == 1 and max <= 100;
                        elseif self.Settings.AcceptAllRollFormats then
                            valid = true;
                        else
                            valid = min == 1 and max == 100;
                        end
                    end
                    
                    -- Re-roll the raid-roll
                    if valid and self.RequestedRoll.RaidRoll then
                        table.wipe(self.RequestedRoll.Players);

                        local subgroups = { };
                        for i = 1, NUM_RAID_GROUPS do
                            subgroups[i] = { };
                        end
                        LootReserve:ForEachRaider(function(name, _, subgroup)
                            if subgroup then
                                table.insert(subgroups[subgroup], name);
                            end
                        end);
                        local raid = { };
                        for _, subgroup in ipairs(subgroups) do
                            for _, player in ipairs(subgroup) do
                                table.insert(raid, player);
                            end
                        end

                        if max ~= #raid or #raid ~= LootReserve:GetNumGroupMembers() then return; end

                        player = raid[roll];
                    elseif not self.RequestedRoll.RaidRoll then
                        self.RequestedRoll.Chat = self.RequestedRoll.Chat or { };
                        self.RequestedRoll.Chat[player] = self.RequestedRoll.Chat[player] or { Class = select(3, LootReserve:UnitClass(player)) };
                        if #self.RequestedRoll.Chat[player] < LootReserve.Constants.MAX_CHAT_STORAGE then
                            table.insert(self.RequestedRoll.Chat[player], format("%d|%s|%s", time(), "SYSTEM", text));
                        end
                    end
                    
                    if valid then
                        local rollSubmitted = false;
                        local extraRolls    = false;
                        if not self.RequestedRoll.Players[player] then
                           self.RequestedRoll.Players[player] = { LootReserve.Constants.RollType.NotRolled }; -- Should only even happen for custom rolls, non-custom ones should fail in LootReserve.Server:CanRoll
                        end
                        for i, oldRoll in ipairs(self.RequestedRoll.Players[player]) do
                            if oldRoll == LootReserve.Constants.RollType.NotRolled then
                                if not rollSubmitted then
                                    local rollBonus = (not self.RequestedRoll.Custom and self.CurrentSession and self.CurrentSession.Members and self.CurrentSession.Members[player]) and self.CurrentSession.Members[player].RollBonus[self.RequestedRoll.Item:GetID()] or 0;
                                    self.RequestedRoll.Players[player][i] = roll + rollBonus;
                                    rollSubmitted = true;
                                else
                                    extraRolls = true;
                                end
                            end
                        end
                        if self.RequestedRoll.Tiered and not rollSubmitted then
                            table.insert(self.RequestedRoll.Players[player], roll);
                        end
                    end

                    self:UpdateReserveListRolls();
                    self:UpdateRollList();
                    
                    if valid then
                        if self.ExtraRollRequestNag[player] then
                            self.ExtraRollRequestNag[player]:Cancel();
                            self.ExtraRollRequestNag[player] = nil;
                        end

                        if not self:TryFinishRoll() then
                            if extraRolls then
                                local closureRoll = self.RequestedRoll;
                                local closureItem = self.RequestedRoll.Item;

                                -- whisper player
                                local function WhisperPlayer()
                                    if not self.RequestedRoll or self.RequestedRoll ~= closureRoll or self.RequestedRoll.Item ~= closureItem then return; end
                                    local rollsCount = 0;
                                    local extraRolls = 0;
                                    for _, roll in ipairs(self.RequestedRoll.Players[player]) do
                                        if roll == LootReserve.Constants.RollType.NotRolled then
                                            extraRolls = extraRolls + 1;
                                        end
                                        rollsCount = rollsCount + 1;
                                    end
                                    if extraRolls == 0 then
                                        return;
                                    end
                                    local name, link = closureItem:GetInfo();
                                    local durationStr = "";
                                    if self.RequestedRoll.Duration then
                                        local time = math.ceil(self.RequestedRoll.Duration);
                                        durationStr = time < 60      and format(" (%d %s)", time,      time ==  1 and "sec" or "secs")
                                                   or time % 60 == 0 and format(" (%d %s)", time / 60, time == 60 and "min" or "mins")
                                                   or                    format(" (%d:%02d mins)", math.floor(time / 60), time % 60);
                                    end
                                    LootReserve:SendChatMessage(format("Please /roll again on %s you reserved%s.%s",
                                        link,
                                        rollsCount > 1 and format(" (%d/%d)", rollsCount - extraRolls + 1, rollsCount) or "",
                                        durationStr
                                    ), "WHISPER", player);
                                end
                                self.ExtraRollRequestNag[player] = C_Timer.NewTimer(4, function() closureItem:OnCache(WhisperPlayer) end);
                            end
                        end
                    end
                end
            end
        end);

        local function ProcessChat(origText, sender, isPrivateChannel)
            if not self.RequestedRoll then return end
            sender = LootReserve:Player(sender);

            local text = origText:lower();
            text = LootReserve:StringTrim(text);
            if text:match("^pa?s*$") or text == "-1" then
                self:PassRoll(sender, self.RequestedRoll.Item, true, isPrivateChannel);
                return;
            elseif (text:match("%f[%w]pas+%f[^%w]") or text:match("%f[%w]p%f[^%w]")) and self.RequestedRoll.Players[sender] and not self.SentMessages[LootReserve:FixText(origText)] then
                local item = self.RequestedRoll.Item;
                
                -- Whisper player
                item:OnCache(function()
                    if not self.RequestedRoll or self.RequestedRoll.Item ~= item then return; end

                    local phase = self.RequestedRoll.Phases and self.RequestedRoll.Phases[1] or nil;
                    LootReserve:SendChatMessage(format("Did you mean to pass on %s%s? You can type 'p' or 'pass' to automatically pass on an item.", item:GetLink(), phase and format(" for %s", phase) or ""), "WHISPER", sender);
                end);
            end
        end
        local chatTypes =
        {
            "CHAT_MSG_RAID",
            "CHAT_MSG_RAID_LEADER",
            "CHAT_MSG_RAID_WARNING",
        };
        local chatTypesPrivate = {
            "CHAT_MSG_PARTY",
            "CHAT_MSG_PARTY_LEADER",
            "CHAT_MSG_WHISPER",
            "CHAT_MSG_SAY",
            "CHAT_MSG_YELL",
            "CHAT_MSG_EMOTE",
            "CHAT_MSG_GUILD",
            "CHAT_MSG_OFFICER",
        }
        for _, eventName in ipairs(chatTypes) do
            LootReserve:RegisterEvent(eventName, function(text, sender) return ProcessChat(text, sender); end);
        end
        for _, eventName in ipairs(chatTypesPrivate) do
            LootReserve:RegisterEvent(eventName, function(text, sender) return ProcessChat(text, sender, true); end);
        end

        local chatTypes =
        {
            "CHAT_MSG_WHISPER",
            "CHAT_MSG_SAY",
            "CHAT_MSG_YELL",
            "CHAT_MSG_PARTY",
            "CHAT_MSG_PARTY_LEADER",
            "CHAT_MSG_RAID",
            "CHAT_MSG_RAID_LEADER",
            "CHAT_MSG_RAID_WARNING",
            "CHAT_MSG_EMOTE",
            "CHAT_MSG_GUILD",
            "CHAT_MSG_OFFICER",
        };
        for _, eventName in ipairs(chatTypes) do
            local savedType = eventName:gsub("CHAT_MSG_", "");
            LootReserve:RegisterEvent(eventName, function(text, sender)
                if self.RequestedRoll then
                    local player = LootReserve:Player(sender);
                    
                    -- Filter out LootReserve messages
                    if LootReserve:IsMe(player) then
                        if self.SentMessages[LootReserve:FixText(text)] then
                            return;
                        end
                    end
                    
                    self.RequestedRoll.Chat = self.RequestedRoll.Chat or { };
                    self.RequestedRoll.Chat[player] = self.RequestedRoll.Chat[player] or { Class = select(3, LootReserve:UnitClass(player)) };
                    if #self.RequestedRoll.Chat[player] < LootReserve.Constants.MAX_CHAT_STORAGE then
                        table.insert(self.RequestedRoll.Chat[player], format("%d|%s|%s", time(), savedType, text));
                        self:UpdateReserveListButtons();
                        self:UpdateRollListButtons();
                    end
                end
            end);
        end
    end
end

function LootReserve.Server:RequestRoll(item, allowedPlayers)
    if not self.CurrentSession then
        LootReserve:ShowError("Loot reserves haven't been started");
        return;
    end

    local reserve = self.CurrentSession.ItemReserves[item:GetID()];
    if not reserve and self.ReservableRewardIDs[item:GetID()] then
        reserve = self.CurrentSession.ItemReserves[LootReserve.Data:GetToken(item:GetID())];
    end
    if not reserve then
        LootReserve:ShowError("That item is not reserved by anyone");
        return;
    end

    local players = allowedPlayers or reserve.Players;
    
    -- Give the item a suffix if it doesn't have one. Source it from loot and inventory
    if not item:HasSuffix() then
        if LootFrame:IsShown() then
            for lootSlot = 1, GetNumLootItems() do
                if GetLootSlotType(lootSlot) == 1 then -- loot slot contains item, not currency/empty
                    local itemID = GetLootSlotInfo(lootSlot);
                    if itemID and itemID == item:GetID() then
                        local itemLink = GetLootSlotLink(lootSlot);
                        if itemLink and itemLink:find("item:%d") then -- GetLootSlotLink() sometimes returns "|Hitem:::::::::70:::::::::[]"
                            local suffixItem = LootReserve.ItemCache:Item(itemLink);
                            if suffixItem:HasSuffix() then
                                item = LootReserve.ItemCache:Item(itemLink);
                                break;
                            end
                        end
                    end
                end
            end
        end
        if LootReserve.BagCache then
            for _, slotData in ipairs(LootReserve.BagCache) do
                if slotData.item:GetID() == item:GetID() then
                    if LootReserve:GetTradeableItemCount(slotData.item) > 0 then
                        item = slotData.item;
                        break;
                    end
                end
            end
        end
    end

    self.RequestedRoll =
    {
        Item        = item,
        StartTime   = time(),
        Players     = { },
        --[[
        {
            [PlayerName] = {Roll, Roll, ...},
            ...
        },
        ]]
        AllowedPlayers = allowedPlayers,
    };
    self.SaveProfile.RequestedRoll = self.RequestedRoll;

    for _, player in ipairs(players) do
        self.RequestedRoll.Players[player] = self.RequestedRoll.Players[player] or { };
        table.insert(self.RequestedRoll.Players[player], LootReserve.Constants.RollType.NotRolled);
    end

    if self:TryFinishRoll() then
        return;
    end

    self:PrepareRequestRoll();

    LootReserve.Comm:BroadcastRequestRoll(item, players);

    if self.CurrentSession.Settings.ChatFallback then
        local durationStr = "";
        if self.RequestedRoll.MaxDuration then
            local time = self.RequestedRoll.MaxDuration;
            durationStr = time < 60      and format(" (%d %s)", time,      time ==  1 and "sec" or "secs")
                       or time % 60 == 0 and format(" (%d %s)", time / 60, time == 60 and "min" or "mins")
                       or                    format(" (%d:%02d mins)", math.floor(time / 60), time % 60);
        end

        local closureRoll = self.RequestedRoll;
        local closureItem = self.RequestedRoll.Item;
        
        -- Broadcast roll
        item:OnCache(function()
            local link = item:GetLink();

            local playersText = LootReserve:FormatReservesText(players);
            local msg = format("%s - roll on reserved %s%s", playersText, LootReserve:FixLink(link), durationStr);
            LootReserve:SendChatMessage(msg, self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollStartReserved));
            
            local sentToPlayer = { };
            for player, roll in self:GetOrderedPlayerRolls(self.RequestedRoll.Players) do
                local function WhisperPlayer()
                    if not self.RequestedRoll or self.RequestedRoll ~= closureRoll or self.RequestedRoll.Item ~= closureItem then return; end
                    local rollsCount = 0;
                    local extraRolls = 0;
                    for _, roll in ipairs(self.RequestedRoll.Players[player]) do
                        rollsCount = rollsCount + 1;
                    end
                    LootReserve:SendChatMessage(format("Please /roll on %s you reserved%s.%s",
                        link,
                        rollsCount > 1 and format(" (1/%d)", rollsCount) or "",
                        durationStr
                    ), "WHISPER", player);
                end
                
                local _, myReserves = LootReserve:GetReservesData(players, player);
                if roll == LootReserve.Constants.RollType.NotRolled and LootReserve:IsPlayerOnline(player) and not sentToPlayer[player] then
                    self.ExtraRollRequestNag[player] = C_Timer.NewTimer(self:IsAddonUser(player) and 5 or 7, function() WhisperPlayer(); end); -- Wrap in anonymous function just in case of blizzard bug
                    sentToPlayer[player] = true;
                end
            end
        end);
    end

    self:UpdateReserveListRolls();
    self:UpdateRollList();
end

function LootReserve.Server:RequestCustomRoll(item, duration, phases, tiered, allowedPlayers)
    self.RequestedRoll =
    {
        Item           = item,
        StartTime      = time(),
        MaxDuration    = duration and duration > 0 and duration or nil,
        Duration       = duration and duration > 0 and duration or nil,
        Phases         = phases and #phases > 0 and phases or nil,
        Tiered         = tiered and { } or nil,
        Custom         = true,
        Players        = { },
        AllowedPlayers = allowedPlayers,
    };
    self.SaveProfile.RequestedRoll = self.RequestedRoll;

    if allowedPlayers then
        for _, player in ipairs(allowedPlayers) do
            self.RequestedRoll.Players[player] = self.RequestedRoll.Players[player] or { };
            table.insert(self.RequestedRoll.Players[player], LootReserve.Constants.RollType.NotRolled);
        end
    end

    self:PrepareRequestRoll();

    local players = allowedPlayers or { };
    if not allowedPlayers then
        LootReserve:ForEachRaider(function(name, _, _, _, _, _, _, online)
            if online then
                table.insert(players, name);
            end
        end);
    end

    LootReserve.Comm:BroadcastRequestRoll(item, players, true, self.RequestedRoll.Duration, self.RequestedRoll.MaxDuration, self.RequestedRoll.Phases or { }, self.RequestedRoll.Tiered and true or nil);

    if not self.CurrentSession or self.CurrentSession.Settings.ChatFallback then
        local durationStr = "";
        if self.RequestedRoll.MaxDuration then
            local time = self.RequestedRoll.MaxDuration;
            durationStr = time < 60      and format(" (%d %s)", time,      time ==  1 and "sec" or "secs")
                       or time % 60 == 0 and format(" (%d %s)", time / 60, time == 60 and "min" or "mins")
                       or                    format(" (%d:%02d mins)", math.floor(time / 60), time % 60);
        end

        local closureRoll = self.RequestedRoll;
        local closureItem = self.RequestedRoll.Item;
        
        -- Broadcast roll
        item:OnCache(function()
            local link = item:GetLink();

            if allowedPlayers then
                -- Should already be announced in LootReserve.Server:ResolveRollTie
                --LootReserve:SendChatMessage(format("%s - roll on %s%s", strjoin(", ", unpack(allowedPlayers)), LootReserve:FixLink(link), durationStr), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollStartCustom));

                local sentToPlayer = { };
                for player, roll in self:GetOrderedPlayerRolls(self.RequestedRoll.Players) do
                local function WhisperPlayer()
                    if not self.RequestedRoll or self.RequestedRoll ~= closureRoll or self.RequestedRoll.Item ~= closureItem then return; end
                    local rollsCount = 0;
                    local extraRolls = 0;
                    for _, roll in ipairs(self.RequestedRoll.Players[player]) do
                        rollsCount = rollsCount + 1;
                    end
                    LootReserve:SendChatMessage(format("Please /roll on %s%s.%s",
                        link,
                        rollsCount > 1 and format(" (1/%d)", rollsCount) or "",
                        durationStr
                    ), "WHISPER", player);
                end
                
                local _, myReserves = LootReserve:GetReservesData(players, player);
                if roll == LootReserve.Constants.RollType.NotRolled and LootReserve:IsPlayerOnline(player) and not sentToPlayer[player] then
                    self.ExtraRollRequestNag[player] = C_Timer.NewTimer(self:IsAddonUser(player) and 5 or 7, function() WhisperPlayer(); end); -- Wrap in anonymous function just in case of blizzard bug
                    sentToPlayer[player] = true;
                end
                end
            else
                local phaseText = "";
                if self.RequestedRoll.Phases then
                    if self.RequestedRoll.Tiered then
                        local phases = { };
                        for i, phase in ipairs(self.RequestedRoll.Phases) do
                            table.insert(phases, format("%s (1-%d)", phase, 100-i+1));
                        end
                        phaseText = format(" for %s", strjoin(", ", unpack(phases)));
                    else
                        phaseText = format(" for %s", self.RequestedRoll.Phases[1] or "")
                    end
                end
                
                local msg = format("Roll%s on %s%s", phaseText or "", link, durationStr);
                LootReserve:SendChatMessage(msg, self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollStartCustom));
            end
        end);
    end

    self:UpdateRollList();
end

function LootReserve.Server:RaidRoll(item)
    self.RequestedRoll =
    {
        Item           = item,
        StartTime      = time(),
        RaidRoll       = true,
        Players        = { },
        AllowedPlayers = { LootReserve:Me() },
    };
    self.SaveProfile.RequestedRoll = self.RequestedRoll;

    self:PrepareRequestRoll();
    RandomRoll(1, LootReserve:GetNumGroupMembers());

    self:UpdateRollList();
end

function LootReserve.Server:PassRoll(player, item, chat, isPrivateChannel)
    if not self:IsRolling(item) or not self.RequestedRoll.Players[player] then
        return;
    end

    local max = 100;
    local success = false;
    if self.RequestedRoll.Tiered then
        for rollingPlayer, roll, rollIndex in LootReserve.Server:GetOrderedPlayerRolls(self.RequestedRoll.Players) do
            if rollingPlayer == player then
                if roll <= LootReserve.Constants.RollType.NotRolled then
                    break;
                end
                local oldRoll = roll;
                self.RequestedRoll.Players[player][rollIndex] = LootReserve.Constants.RollType.Passed;
                success = true;
                
                roll, max = self:ConvertFromTieredRoll(oldRoll);
                self.RequestedRoll.Tiered[player] = self.RequestedRoll.Tiered[player] or { };
                self.RequestedRoll.Tiered[player][max] = true;
                break;
            end
        end
    else
        for i, roll in ipairs(self.RequestedRoll.Players[player]) do
            if roll >= LootReserve.Constants.RollType.NotRolled then
                local oldRoll = roll;
                self.RequestedRoll.Players[player][i] = LootReserve.Constants.RollType.Passed;
                success = true;
            end
        end
    end

    if not success then
        return;
    end

    local phase = self.RequestedRoll.Phases and self.RequestedRoll.Phases[101-max] or nil;
    local item = self.RequestedRoll.Item;
    if chat then
        if not self.RequestedRoll.Tiered then
            LootReserve.Comm:SendRequestRoll(player, LootReserve.ItemCache:Item(0), { }, self.RequestedRoll.Custom or self.RequestedRoll.RaidRoll);
        end

        -- Whisper player
        item:OnCache(function()
            if not self.RequestedRoll or self.RequestedRoll.Item ~= item then return; end
            LootReserve:SendChatMessage(format("You have passed on %s%s.", item:GetLink(), phase and format(" for %s", phase) or ""), "WHISPER", player);
        end);
    end
    if not chat or isPrivateChannel then
        -- Announce
        item:OnCache(function()
            if not self.RequestedRoll or self.RequestedRoll.Item ~= item then return; end
            LootReserve:SendChatMessage(format("%s has passed on %s%s.", player, item:GetLink(), phase and format(" for %s", phase) or ""), "RAID");
        end);
    end

    self:UpdateReserveListRolls();
    self:UpdateRollList();

    self:TryFinishRoll();
end

function LootReserve.Server:DeleteRoll(player, rollNumber, item)
    if not self:IsRolling(item) or not self.RequestedRoll.Players[player] or not self.RequestedRoll.Players[player][rollNumber] or self.RequestedRoll.Players[player][rollNumber] < 0 then
        return;
    end

    if self.RequestedRoll.RaidRoll then
        RandomRoll(1, LootReserve:GetNumGroupMembers());
        return;
    end

    local oldRoll = self.RequestedRoll.Players[player][rollNumber];
    local max = 100;
    self.RequestedRoll.Players[player][rollNumber] = LootReserve.Constants.RollType.Deleted;
    if self.RequestedRoll.Tiered then
        oldRoll, max = self:ConvertFromTieredRoll(oldRoll);
        self.RequestedRoll.Tiered[player] = self.RequestedRoll.Tiered[player] or { };
        self.RequestedRoll.Tiered[player][max] = true;
    end

    local phase = self.RequestedRoll.Phases and self.RequestedRoll.Phases[101-max] or nil;

    LootReserve.Comm:SendDeletedRoll(player, item, oldRoll, phase);
    if (not self.CurrentSession or self.CurrentSession.Settings.ChatFallback) and not self:IsAddonUser(player) then
        -- Whisper player
        item:OnCache(function()
            LootReserve:SendChatMessage(format("Your %sroll of %d on %s was deleted.", phase and format("%s ", phase) or "", oldRoll, item:GetLink()), "WHISPER", player);
        end);
    end

    self:UpdateReserveListRolls();
    self:UpdateRollList();

    self:TryFinishRoll();
end

function LootReserve.Server:GetOrderedPlayerRolls(roll)
    local playerRolls = { };
    for player, rolls in pairs(roll) do
        for i, roll in ipairs(rolls) do
            table.insert(playerRolls, { Player = player, RollNumber = i, Roll = roll });
        end
    end
    table.sort(playerRolls, function(aData, bData)
        if aData.Roll ~= bData.Roll then
            return aData.Roll > bData.Roll;
        elseif aData.Player ~= bData.Player then
            return aData.Player < bData.Player;
        else
            return aData.RollNumber < bData.RollNumber;
        end
    end);

    local i = 0;
    return function()
        i = i + 1;
        if playerRolls[i] then
            return playerRolls[i].Player, playerRolls[i].Roll, playerRolls[i].RollNumber;
        else
            return;
        end
    end
end

function LootReserve.Server:MasterLootItem(item, player, multipleWinners)
    if not item or not player then return; end

    local name, link = item:GetInfo();
    if not name or not link then return; end
    local quality = item:GetQuality()

    -- if not self.Settings.RollMasterLoot then
        -- LootReserve:ShowError("Failed to masterloot %s to %s: masterlooting not enabled in LootReserve settings", link, LootReserve:ColoredPlayer(player));
    --     return;
    -- end

    if not IsMasterLooter() or GetLootMethod() ~= "master" then
        -- LootReserve:ShowError("Failed to masterloot %s to %s: not master looter", link, LootReserve:ColoredPlayer(player));
        return;
    end

    local itemIndex = LootReserve:IsLootingItem(item);
    if not itemIndex then
        -- LootReserve:ShowError("Failed to masterloot %s to %s: item not found in the current loot", link, LootReserve:ColoredPlayer(player));
        return;
    end

    if quality < GetLootThreshold() then
        -- LootReserve:ShowError("Failed to masterloot %s to %s: item quality below masterloot threshold", link, LootReserve:ColoredPlayer(player));
        return;
    end

    if multipleWinners then
        LootReserve:ShowError("%s was not automatically masterlooted: More than one candidate", link);
        return;
    end

    if not self.MasterLootListUpdateRegistered then
        self.MasterLootListUpdateRegistered = true;
        LootReserve:RegisterEvent("OPEN_MASTER_LOOT_LIST", "UPDATE_MASTER_LOOT_LIST", function()
            local pending = self.PendingMasterLoot;
            self.PendingMasterLoot = nil;
            if pending and pending.ItemIndex == LootReserve:IsLootingItem(pending.Item) and pending.Timeout >= time() then
                local gapExists = false;
                for playerIndex = 1, MAX_RAID_MEMBERS do
                    local player = GetMasterLootCandidate(pending.ItemIndex, playerIndex);
                    
                    if not player then
                        -- don't do this, just in case gaps are possible
                        -- break;
                        gapExists = true;
                    end
                    if LootReserve:IsSamePlayer(GetMasterLootCandidate(pending.ItemIndex, playerIndex), pending.Player) then
                        if gapExists then
                            LootReserve:debug("Masterloot index gap exists");
                        end
                        GiveMasterLoot(pending.ItemIndex, playerIndex);
                        MasterLooterFrame:Hide();
                        return;
                    end
                end
                if MasterLooterFrame and MasterLooterFrame:IsShown() then
                   MasterLooterFrame:Hide(); 
                end
                LootReserve:ShowError("Failed to masterloot %s to %s: Player is not a masterloot candidate for this item", pending.Link, LootReserve:ColoredPlayer(pending.Player));
            end
        end);
    end

    -- Prevent duplicate request. Hopefully...
    if self.PendingMasterLoot and self.PendingMasterLoot.Item == item and self.PendingMasterLoot.Timeout >= time() then
        LootReserve:ShowError("Failed to masterloot %s to %s: There's another master loot attempt in progress. Try again in 5 seconds", link, LootReserve:ColoredPlayer(player));
        return;
    end

    self.PendingMasterLoot =
    {
        Item      = item,
        Link      = link,
        ItemIndex = itemIndex,
        Player    = player,
        Timeout   = time() + 5,
    };

    --LootSlot(itemIndex); -- Can't do it this way, LootFrame breaks due to some crucial variables not being filled
    --[[ Can't do it this way either, addons that change LootFrame and unhook its event handlers won't work
    local numItemsPerPage = LOOTFRAME_NUMBUTTONS;
    local numLootItems = LootFrame.numLootItems or 0;
    if numLootItems > LOOTFRAME_NUMBUTTONS then
        numItemsPerPage = numItemsPerPage - 1;
    end
    for page = 1, math.ceil(numLootItems / numItemsPerPage) do
        LootFrame.page = page;
        LootFrame_Update();
        for index = 1, numItemsPerPage do
            local button = _G["LootButton" .. index];
            if button and button:IsShown() and button.slot == itemIndex then
                LootButton_OnClick(button, "LeftButton"); -- Now wait for OPEN_MASTER_LOOT_LIST/UPDATE_MASTER_LOOT_LIST
                return;
            end
        end
    end
    LootReserve:ShowError("Failed to masterloot %s to %s: looting UI is closed or the item was not found in the loot", link, LootReserve:ColoredPlayer(player));
    ]]
    local lootIcon, lootName, lootQuantity, _, lootQuality = GetLootSlotInfo(itemIndex);
    local fake = LootReserveRollFakeMasterLoot;
    fake.slot = itemIndex;
    fake.quality = lootQuality;
    fake.Text:SetText(lootName); -- May differ from item record name due to RandomProperties and RandomSuffix
    fake.IconTexture:SetTexture(lootIcon);
    LootButton_OnClick(fake, "LeftButton"); -- Now wait for OPEN_MASTER_LOOT_LIST/UPDATE_MASTER_LOOT_LIST
end

function LootReserve.Server:WhisperPlayerWithoutReserves(player)
    if not self.CurrentSession then return; end
    if not self.CurrentSession.AcceptingReserves then return; end
    
    local member = self.CurrentSession.Members[player]
    if not member then return; end

    if member.ReservesLeft > 0 and not member.OptedOut and LootReserve:IsPlayerOnline(player) then
        if member.Locked then
            member.Locked = false;
        end
        local categories = LootReserve:GetCategoriesText(self.CurrentSession and self.CurrentSession.Settings.LootCategories);
        
        LootReserve.Comm:SendSessionInfo(player);
        local msg1 = format("Don't forget to reserve your item%s%s. You have %d reserve%s left. Whisper: !reserve ItemLinkOrName",
            self.CurrentSession.Settings.MaxReservesPerPlayer + member.ReservesDelta == 1 and "" or "s",
            categories ~= "" and format(" for %s", categories) or "",
            member.ReservesLeft,
            member.ReservesLeft == 1 and "" or "s"
        );
        local msg2 = "If you are done reserving, whisper: !opt out";
        local combined = format("%s. %s", msg1, msg2);
        if #combined <= 250 then
            LootReserve:SendChatMessage(combined, "WHISPER", player);
        else
            LootReserve:SendChatMessage(msg1, "WHISPER", player);
            LootReserve:SendChatMessage(msg2, "WHISPER", player);
        end
        self:SendSupportString(player);
    end
end

function LootReserve.Server:WhisperAllWithoutReserves()
    if not self.CurrentSession then return; end
    if not self.CurrentSession.AcceptingReserves then return; end

    local i = 0;
    for player, member in pairs(self.CurrentSession.Members) do
        if member.ReservesLeft > 0 and not member.OptedOut and LootReserve:IsPlayerOnline(player) then
            C_Timer.After(i, function() self:WhisperPlayerWithoutReserves(player) end);
            i = i + 2;
        end
    end
end

function LootReserve.Server:GetSupportString(player, prefix, force)
    local addonUser = self:IsAddonUser(player);
    if addonUser and not force then
        return "";
    else
        return format("%sFor full support, %s the addon: LootReserve", prefix or "", addonUser == false and "update" or "install");
    end
end

function LootReserve.Server:SendSupportString(player, force)
    local supportString = self:GetSupportString(player, nil, force);
    if supportString ~= "" then
        LootReserve:SendChatMessage(supportString, "WHISPER", player);
    end
end

function LootReserve.Server:BroadcastInstructions()
    if not self.CurrentSession then return; end
    if not self.CurrentSession.AcceptingReserves then return; end
    local categories = LootReserve:GetCategoriesText(self.CurrentSession and self.CurrentSession.Settings.LootCategories);

    LootReserve:SendChatMessage(format("Loot reserves are currently ongoing%s.",
        categories ~= "" and format(" for %s", categories) or ""
    ), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionInstructions));
    LootReserve:SendChatMessage("To reserve an item, whisper me: !reserve ItemLinkOrName", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionInstructions));
    if self.Settings.ChatReservesList then
        if self.CurrentSession.Settings.Blind then
            LootReserve:SendChatMessage("To see your reserves, whisper me: !myreserves", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionInstructions));
        else
            LootReserve:SendChatMessage("To see reserves made, whisper me: !reserves  or  !myreserves", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionInstructions));
        end
    end
end

function LootReserve.Server:ConvertToTieredRoll(roll, max)
    return max + roll/1000;
end

function LootReserve.Server:ConvertFromTieredRoll(tieredRoll)
    if tieredRoll <= LootReserve.Constants.RollType.NotRolled then
        return tieredRoll, 0;
    end
    local max = math.floor(tieredRoll);
    local roll = LootReserve:Round((tieredRoll - max) * 1000);
    return roll, max;
end
