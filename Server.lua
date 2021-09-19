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
            false,
            true,
            true,
            true,
            false,
            true,
            true,
        },
        ChatAnnounceWinToGuild          = false,
        ChatAnnounceWinToGuildThreshold = 3,
        ChatReservesList                = true,
        ChatUpdates                     = true,
        ReservesSorting                 = LootReserve.Constants.ReservesSorting.ByBoss,
        UseGlobalProfile                = false,
        Phases                          = LootReserve:Deepcopy(LootReserve.Constants.DefaultPhases),
        RollUsePhases                   = false,
        RollPhases                      = {"Main-Spec", "Off-Spec"},
        RollAdvanceOnExpire             = true,
        RollLimitDuration               = false,
        RollDuration                    = 30,
        RollFinishOnExpire              = false,
        RollFinishOnAllReservingRolled  = true,
        RollFinishOnRaidRoll            = false,
        RollSkipNotContested            = true,
        RollHistoryDisplayLimit         = 10,
        RollHistoryKeepLimit            = 1000,
        RollMasterLoot                  = true,
        MasterLooting                   = true,
        WinnerReservesRemoval           = LootReserve.Constants.WinnerReservesRemoval.Duplicate,
        ItemConditions                  = { },
        CollapsedExpansions             = { },
        HighlightSameItemWinners        = true,
        MaxRecentLoot                   = 25,
        MinimumLootQuality              = 2,
        RemoveRecentLootAfterRolling    = true,
        UseUnitFrames                   = true,
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
    Export              = { },
    PendingMasterLoot   = nil,
    ExtraRollRequestNag = { },

    ReservableItems                    = { },
    ItemNames                          = { },
    LootTrackingRegistered             = false,
    GuildMemberTrackingRegistered      = false,
    DurationUpdateRegistered           = false,
    RollDurationUpdateRegistered       = false,
    RollMatcherRegistered              = false,
    ChatTrackingRegistered             = false,
    ChatFallbackRegistered             = false,
    BasicChatListeningRegistered       = false,
    SessionEventsRegistered            = false,
    AllItemNamesCached                 = false,
    StartupAwaitingAuthority           = false,
    StartupAwaitingAuthorityRegistered = false,
    MasterLootListUpdateRegistered     = false,
    RollHistoryDisplayLimit            = 0,
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
        LootReserve.Server:RequestCustomRoll(self.data.Item,
            LootReserve.Server.Settings.RollLimitDuration and LootReserve.Server.Settings.RollDuration or nil,
            LootReserve.Server.Settings.RollUsePhases and #LootReserve.Server.Settings.RollPhases > 0 and LootReserve.Server.Settings.RollPhases or nil);
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
        if LootReserve.Server.CurrentSession and LootReserve.Server.CurrentSession.ItemReserves[self.data.Item:GetID()] then
            LootReserve.Server:RequestRoll(self.data.Item);
        end
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
        local name = LootReserve:StringTrim(self.editBox:GetText());
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

function LootReserve.Server:HasRelevantRecentChat(chat, player)
    if not chat or not chat[player] then return false; end
    if #chat[player] > 1 then return true; end
    local time, type, text = strsplit("|", chat[player][1], 3);
    return type ~= "SYSTEM";
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
            container[itemID].Hidden = container[itemID].Hidden and conditions.Hidden or nil;
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
        for _, rollTable in ipairs{self.RollHistory, self.RequestedRoll} do
            for _, roll in ipairs(rollTable) do
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
    
    -- 2021-09-13: Add self.CurrentSession.Members[player].ReservesDelta and update self.CurrentSession.Settings.MultiReserve
    if versionSave < "2021-09-17" then
        if self.CurrentSession then
            for _, member in pairs(self.CurrentSession.Members) do
                member.ReservesDelta = member.ReservesDelta or 0;
            end
            if not self.CurrentSession.Settings.Multireserve then
                self.CurrentSession.Settings.MultiReserve = 1;
            end
        end
    end
    
    -- Create Item objects
    for _, roll in ipairs(self.RollHistory) do
        roll.Item = LootReserve.Item(roll.Item);
    end
    if self.RequestedRoll then
       self.RequestedRoll.Item = LootReserve.Item(self.RequestedRoll.Item); 
    end
    if self.CurrentSession then
        for _, member in pairs(self.CurrentSession.Members) do
            if member.WonRolls then
                for i, won in ipairs(member.WonRolls) do
                    won.Item = LootReserve.Item(won.Item);
                end 
            end
        end
    end
    for i, item in ipairs(self.RecentLoot) do
        self.RecentLoot[i] = LootReserve.Item(item);
    end

    -- Expire session if more than 1 hour has passed since the player was last online
    if self.CurrentSession and self.CurrentSession.LogoutTime and time() > self.CurrentSession.LogoutTime + 3600 then
        self.CurrentSession = nil;
    end

    -- Verify that all the required fields are present in the session
    if self.CurrentSession then
        local function verifySessionField(field)
            if self.CurrentSession and self.CurrentSession[field] == nil then
                self.CurrentSession = nil;
            end
        end

        local fields = { "AcceptingReserves", "Settings", "StartTime", "Duration", "DurationEndTimestamp", "Members", "WonItems", "ItemReserves", "LootTracking" };
        for _, field in ipairs(fields) do
            verifySessionField(field);
        end
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

    -- Show reserves even if no longer the server, just a failsafe
    self:UpdateReserveList();

    -- Hook events to record recent loot and track looters
    self:PrepareLootTracking();

    self:PrepareGuildTracking();
end

function LootReserve.Server:HasAlreadyWon(player, item)
    local won = self.CurrentSession and self.CurrentSession.Members[player] and self.CurrentSession.Members[player].WonRolls;
    if won then
        for i, roll in ipairs(won) do
            if roll.Item:GetID() == item then
                return true;
            end
        end
    end
    return false;
end

function LootReserve.Server:PrepareLootTracking()
    if self.LootTrackingRegistered then return; end
    self.LootTrackingRegistered = true;

    local function AddLootToList(looter, item, count)
        local quality;
        looter = LootReserve:Player(looter);
        if item then
            local name, link, q = item:GetInfo();
            if not name or not link then
                return true;
            end
            if q >= self.Settings.MinimumLootQuality then
                quality = q;
            end
        end
        count = tonumber(count);
        if looter and item and quality and count then
            if LootReserve:IsMe(looter) then
                LootReserve:TableRemove(self.RecentLoot, item);
                table.insert(self.RecentLoot, item);
                while #self.RecentLoot > self.Settings.MaxRecentLoot do
                    table.remove(self.RecentLoot, 1);
                end
            end

            if self.CurrentSession and self.ReservableItems[item:GetID()] then
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
        if IsMasterLooter()  then
            return;
        end
        local looter, itemID, count;
        itemID, count = text:match(lootSelfMultiple);
        if itemID and count then
            looter = LootReserve:Me();
        else
            itemID = text:match(lootSelf);
            if itemID then
                looter = LootReserve:Me();
                count = 1;
            else
                looter, itemID, count = text:match(lootMultiple);
                if looter and itemID and count then
                    -- ok
                else
                    looter, itemID = text:match(loot);
                    if looter and itemID then
                        count = 1;
                    else
                        return;
                    end
                end
            end
        end
        LootReserve:RunWhenItemCached(itemID, function() return AddLootToList(looter, LootReserve.Item(itemID), count) end);
    end);
    LootReserve:RegisterEvent("LOOT_READY", function(text)
        if not IsMasterLooter() then
           return; 
        end
        -- best guess at what object the player is looting. won't work for chests
        local guid = UnitExists("target") and UnitIsDead("target") and not UnitIsFriend("player", "target") and UnitGUID("target");
        if guid then
            if self.LootedCorpses[guid] then
                return;
            else
                self.LootedCorpses[guid] = true;
            end
        end
        for lootSlot = 1, GetNumLootItems() do
            if GetLootSlotType(lootSlot) == 1 then -- loot slot contains item, not currency/empty
                local itemID = GetLootSlotInfo(lootSlot);
                if itemID then
                    local item = LootReserve.Item(GetLootSlotLink(lootSlot));
                    local quality = item:GetQuality();
                    if quality >= self.Settings.MinimumLootQuality then
                        LootReserve:TableRemove(self.RecentLoot, item);
                        table.insert(self.RecentLoot, item);
                        while #self.RecentLoot > self.Settings.MaxRecentLoot do
                            table.remove(self.RecentLoot, 1);
                        end
                    end
                end
            end
        end
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
            if not LootReserve:UnitInGroup(player) and #member.ReservedItems == 0 then
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
        LootReserve:ForEachRaider(function(name)
            if not self.CurrentSession.Members[name] then
                self.CurrentSession.Members[name] =
                {
                    ReservesLeft  = self.CurrentSession.Settings.MaxReservesPerPlayer,
                    ReservesDelta = 0,
                    ReservedItems = { },
                    Locked        = nil,
                    OptedOut      = nil,
                };
                self.MembersEdit:UpdateMembersList();
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
                for i = 1, 50 do
                frame = _G[tooltip:GetName() .. "TextLeft" .. i];
                if frame then
                    text = frame:GetText();
                end
                if text and string.find(text, " Reserved by ", 1, true) then return; end
                end

                local item = LootReserve.Item(link);
                if self.CurrentSession.WonItems[item:GetID()] then
                    local reservesText = LootReserve:FormatReservesTextColored(self.CurrentSession.WonItems[item:GetID()].Players);
                    tooltip:AddLine("|TInterface\\BUTTONS\\UI-GroupLoot-Coin-Up:32:32:0:-4|t Won by " .. reservesText, 1, 1, 1);
                end
                if self.CurrentSession.ItemReserves[item:GetID()] then
                    local reservesText = LootReserve:FormatReservesTextColored(self.CurrentSession.ItemReserves[item:GetID()].Players);
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

    self.AllItemNamesCached = false; -- If category is changed - other item names might need to be cached

    if self.CurrentSession.Settings.ChatFallback and not self.ChatFallbackRegistered then
        self.ChatFallbackRegistered = true;

        local prefix1A = "!reserve";
        local prefix1B = "!res";
        local prefix1C = "!";
        
        local prefix2A = "!cancelreserve";
        local prefix2B = "!cancelres";
        local prefix2C = "!cancel";
        local prefix2D = "!unreserve";
        -- local prefixZ = "!cancelreserves";

        local function ProcessChat(text, sender)
            sender = LootReserve:Player(sender);
            if not self.CurrentSession then return; end;

            local member = self.CurrentSession.Members[sender];
            if not member or not LootReserve:IsPlayerOnline(sender) then return; end

            text = text:lower();
            text = LootReserve:StringTrim(text);
            if text == "!reserves" then
                if self.Settings.ChatReservesList then
                    self:SendReservesList(sender);
                end
                return;
            elseif text == "!myreserve" or text == "!myreserves" or text == "!myres" then
                if self.Settings.ChatReservesList then
                    self:SendReservesList(sender, true);
                end
                return;
            elseif stringStartsWith(text, "!opt") then
                local direction = text:match("^!opt%s*(.*)");
                if stringStartsWith(direction, "out") then
                    self:Opt(sender, true, true);
                elseif stringStartsWith(direction, "in") then
                    self:Opt(sender, nil, true);
                end
                return;
            elseif stringStartsWith(text, prefix1A) then
                text = text:sub(1 + #prefix1A);
            elseif stringStartsWith(text, prefix1B) then
                text = text:sub(1 + #prefix1B);
            elseif stringStartsWith(text, prefix2A) then
                text = "cancel" .. text:sub(1 + #prefix2A);
            elseif stringStartsWith(text, prefix2B) then
                text = "cancel" .. text:sub(1 + #prefix2B);
            elseif stringStartsWith(text, prefix2C) then
                text = "cancel" .. text:sub(1 + #prefix2C);
            elseif stringStartsWith(text, prefix2D) then
                text = "cancel" .. text:sub(1 + #prefix2D);
            elseif stringStartsWith(text, prefix1C) then
                text = text:sub(1 + #prefix1C);
            else
                return;
            end

            if not self.CurrentSession.AcceptingReserves then
                LootReserve:SendChatMessage("Loot reserves are no longer being accepted.", "WHISPER", sender);
                return;
            end

            text = LootReserve:StringTrim(text);
            local command = "reserve";
            if #text == 0 then
                LootReserve:SendChatMessage("Seems like you forgot to enter the item you want to reserve. Whisper  !reserve ItemLinkOrName", "WHISPER", sender);
                self:SendSupportString(sender, true);
                return;
            elseif stringStartsWith(text, "cancel") then
                text = text:sub(1 + #("cancel"));
                command = "cancel";
            end

            text = LootReserve:StringTrim(text);
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
                        self:SendChatMessage(format("You have no items reserved.%s", self:GetSupportString(sender, " ")), "WHISPER", sender);
                    end
                    return;
                end
            end

            local function handleItemCommand(itemID, command, count)
                count = count or 1;
                if self.ReservableItems[itemID] then
                    if command == "reserve" then
                        self:Reserve(sender, itemID, count, true);
                    elseif command == "cancel" then
                        self:CancelReserve(sender, itemID, count, true);
                    end
                else
                    LootReserve:SendChatMessage(format("That item is not reservable in this raid.%s", self:GetSupportString(sender, " ", true)), "WHISPER", sender);
                end
            end

            local itemID = tonumber(text:match("item[:=](%d+)"));
            if itemID then
                local charI = 0;
                local items = { };
                local itemCommands = { };
                while true do
                    local s, e, itemID;
                    -- Match various forms of item linking, including incorrect ones
                    if not s then
                         -- Correctly-formatted itemlink
                        s, e, itemID = text:find("\124cff......\124hitem:(%d+)[:%d]*\124h%[[^%[%]]*%]\124h\124r", charI);
                    end
                    if not s then
                        -- Wowhead In-Game Link
                        s, e, itemID = text:find("/%S+%s*default_chat_frame:addmessage%(\"\\124cff......\\124hitem:(%d+)[:%d]*\\124h%[[^%[%]]*%]\\124h\\124r\"%);", charI);
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
                for i, itemData in ipairs(items) do
                    local s, e = items[i-1] and items[i-1].e+1 or 1, items[i+1] and items[i+1].s-1 or text:len();
                    local pre, post = text:sub(s, itemData.s-1), text:sub(itemData.e+1, e);
                    local count1, count2 = pre:match("(%d+)%s*[xX%*]"), post:match("[xX%*]%s*(%d+)");
                    local ambig1, ambig2 = pre:match("(%d+)"), post:match("(%d+)");
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
                    
                    if count1 and count2 or ambiguous then
                        LootReserve:SendChatMessage(format("Can't tell how many items you want to reserve. It appears to be ambiguous.%s", self:GetSupportString(sender, " ", true)), "WHISPER", sender);
                        return;
                    else
                        if not itemCommands[itemData.ID] then
                            itemCommands[itemData.ID] = 0;
                        end
                        itemCommands[itemData.ID] = itemCommands[itemData.ID] + (count1 or count2 or 1);
                    end
                end
                
                for _, itemData in pairs(items) do
                    if itemCommands[itemData.ID] then
                        handleItemCommand(itemData.ID, command, itemCommands[itemData.ID]);
                        itemCommands[itemData.ID] = nil;
                    end
                end
            else
                local count = tonumber(text:match("%s*[xX%*]?%s*(%d+)%s*[Xx%*]?$"));
                if count then
                    text = text:match("^(.-)%s*[xX%*]?%s*(%d+)%s*[Xx%*]?$");
                else
                    count = 1;
                end
                text = LootReserve:TransformSearchText(text);
                local function handleItemCommandByName()
                    if self:UpdateItemNameCache() then
                        local match = nil;
                        local matches = { };
                        for itemID, name in pairs(self.ItemNames) do
                            if self.ReservableItems[itemID] and string.find(name, text, 1, true) and not LootReserve:Contains(matches, itemID) then
                                match = match and 0 or itemID;
                                table.insert(matches, itemID);
                            end
                        end

                        if not match then
                            LootReserve:SendChatMessage(format("That item was not found in the current raid, which is %s. Check your spelling, or try using a shorter search term.%s",
                                LootReserve:GetCategoriesText(self.CurrentSession.Settings.LootCategories, false),
                                self:GetSupportString(sender, " ", true)
                            ), "WHISPER", sender);
                        elseif match > 0 then
                            handleItemCommand(match, command, count);
                        elseif match == 0 then
                            local names = { };
                            for i = 1, math.min(5, #matches) do
                                names[i] = GetItemInfo(matches[i]);
                            end
                            LootReserve:SendChatMessage(format("Try being more specific, %d items match that name: %s%s",
                                #matches,
                                strjoin(", ", unpack(names)),
                                #matches > #names and format(" and %d more...", #matches - #names) or ""
                            ), "WHISPER", sender);
                            self:SendSupportString(sender, true);
                        end
                    else
                        C_Timer.After(0.1, handleItemCommandByName);
                    end
                end

                if #text >= 3 then
                    handleItemCommandByName();
                else
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
            LootReserve:RegisterEvent(type, ProcessChat);
        end
    end

    -- Cache the list of items players can reserve
    table.wipe(self.ReservableItems);
    for itemID, conditions in pairs(self.CurrentSession.ItemConditions) do
        if itemID ~= 0 and conditions.Custom and LootReserve.ItemConditions:TestServer(itemID) then
            self.ReservableItems[itemID] = true;
        end
    end
    for id, category in pairs(LootReserve.Data.Categories) do
        if category.Children and (not self.CurrentSession.Settings.LootCategories or LootReserve:Contains(self.CurrentSession.Settings.LootCategories, id)) and LootReserve.Data:IsCategoryVisible(category) then
            for _, child in ipairs(category.Children) do
                if child.Loot then
                    for _, itemID in ipairs(child.Loot) do
                        if itemID ~= 0 and LootReserve.ItemConditions:TestServer(itemID) then
                            self.ReservableItems[itemID] = true;
                        end
                    end
                end
            end
        end
    end
end

function LootReserve.Server:UpdateItemNameCache()
    if self.AllItemNamesCached then return self.AllItemNamesCached; end

    self.AllItemNamesCached = true;
    for itemID, conditions in pairs(self:GetNewSessionItemConditions()) do
        if itemID ~= 0 and conditions.Custom then
            local name = GetItemInfo(itemID);
            if name then
                self.ItemNames[itemID] = LootReserve:TransformSearchText(name);
            else
                self.AllItemNamesCached = false;
            end
        end
    end
    if self.CurrentSession then
        for itemID, conditions in pairs(self.CurrentSession.ItemConditions) do
            if itemID ~= 0 and conditions.Custom then
                local name = GetItemInfo(itemID);
                if name then
                    self.ItemNames[itemID] = LootReserve:TransformSearchText(name);
                else
                    self.AllItemNamesCached = false;
                end
            end
        end
    end
    for id, category in pairs(LootReserve.Data.Categories) do
        if category.Children and LootReserve.Data:IsCategoryVisible(category) then
            for _, child in ipairs(category.Children) do
                if child.Loot then
                    for _, itemID in ipairs(child.Loot) do
                        if itemID ~= 0 and not self.ItemNames[itemID] then
                            local name = GetItemInfo(itemID);
                            if name then
                                self.ItemNames[itemID] = LootReserve:TransformSearchText(name);
                            else
                                self.AllItemNamesCached = false;
                            end
                        end
                    end
                end
            end
        end
    end
    return self.AllItemNamesCached;
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
        AcceptingReserves    = true,
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
                ReservesLeft  = self.CurrentSession.Settings.MaxReservesPerPlayer,
                ReservesDelta = 0,
                ReservedItems = { ItemID, ItemID, ... },
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
            ReservesLeft  = self.CurrentSession.Settings.MaxReservesPerPlayer,
            ReservesDelta = 0,
            ReservedItems = { },
            Locked        = nil,
            OptedOut      = nil,
        };
    end);

    self:PrepareSession();

    -- Import reserves
    for player, importedMember in pairs(self.CurrentSession.Settings.ImportedMembers) do
        local member = self.CurrentSession.Members[player] or
        {
            ReservesLeft  = self.CurrentSession.Settings.MaxReservesPerPlayer,
            ReservesDelta = 0,
            ReservedItems = { },
            Locked        = nil,
            OptedOut      = nil,
        };
        self.CurrentSession.Members[player] = member;
        for _, itemID in ipairs(importedMember.ReservedItems) do
            if self.ReservableItems[itemID] and member.ReservesLeft > 0 then
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
    end
    table.wipe(self.NewSessionSettings.ImportedMembers);
    table.wipe(self.CurrentSession.Settings.ImportedMembers);

    LootReserve.Comm:BroadcastVersion();
    LootReserve.Comm:BroadcastSessionInfo(true);
    if self.CurrentSession.Settings.ChatFallback then
        local categories = LootReserve:GetCategoriesText(self.CurrentSession and self.CurrentSession.Settings.LootCategories);
        local duration = self.CurrentSession.Settings.Duration
        local count = self.CurrentSession.Settings.MaxReservesPerPlayer;
        LootReserve:SendChatMessage(format("Loot reserves are now started%s%s%s. %d reserved %s per character%s.",
            categories ~= "" and format(" for %s", categories) or "",
            self.CurrentSession.Settings.Blind and " (blind)" or "",
            duration ~= 0 and format(" and will last for %d:%02d minutes", math.floor(duration / 60), duration % 60) or "",
            count,
            count == 1 and "item" or "items",
            self.CurrentSession.Settings.Multireserve > 1 and format(", up to x%d on a single item", self.CurrentSession.Settings.Multireserve) or ""
        ), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionStart));
        if self.Settings.ChatReservesList and not self.CurrentSession.Settings.Blind then
            LootReserve:SendChatMessage("To see all reserves made, whisper me:  !reserves", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionStart));
        end
        LootReserve:SendChatMessage("To reserve an item, whisper me:  !reserve ItemLinkOrName", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionStart));
        if self.CurrentSession.Settings.Multireserve > 1 then
            LootReserve:SendChatMessage("To reserve an item multiple times, whisper me:  !reserve ItemLinkOrName x2", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionStart));
        end
    end

    self:UpdateReserveList();
    self.MembersEdit:UpdateMembersList();

    self:SessionStarted();
    return true;
end

function LootReserve.Server:ResumeSession()
    if not self.CurrentSession then
        LootReserve:ShowError("Loot reserves haven't been started");
        return;
    end

    self.CurrentSession.AcceptingReserves = true;
    self.CurrentSession.DurationEndTimestamp = time() + math.floor(self.CurrentSession.Duration);

    LootReserve.Comm:BroadcastSessionInfo();

    if self.CurrentSession.Settings.ChatFallback then
        local categories = LootReserve:GetCategoriesText(self.CurrentSession and self.CurrentSession.Settings.LootCategories);
        
        LootReserve:SendChatMessage(format("Accepting loot reserves again%s.",
            categories ~= "" and format(" for %s", categories) or ""
        ), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionResume));
        if self.Settings.ChatReservesList and not self.CurrentSession.Settings.Blind then
            LootReserve:SendChatMessage("To see all reserves made, whisper me:  !reserves", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionResume));
        end
        LootReserve:SendChatMessage("To reserve an item, whisper me:  !reserve ItemLinkOrName", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionResume));
        if self.CurrentSession.Settings.Multireserve > 1 then
            LootReserve:SendChatMessage("To reserve an item multiple times, whisper me:  !reserve ItemLinkOrName x2", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionResume));
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

function LootReserve.Server:IncrementReservesDelta(player, amount, winner)
    local function Failure(result, ...)
        LootReserve:ShowError(LootReserve.Constants.ReserveResultText[result]);
        return false;
    end

    if not self.CurrentSession then
        return Failure(LootReserve.Constants.ReserveResult.NoSession);
    end

    local member = self.CurrentSession.Members[player];
    if not member then
        return Failure(LootReserve.Constants.ReserveResult.NotMember);
    end
    
    if amount == 0 then return; end
    amount = amount or 1;
    
    local count = 0 - member.ReservesLeft - amount;
    if count > 0 then
        local reservesCount = { };
        for i = #member.ReservedItems, math.max(#member.ReservedItems - count + 1, 1), -1 do
            reservesCount[member.ReservedItems[i]] = reservesCount[member.ReservedItems[i]] and reservesCount[member.ReservedItems[i]] + 1 or 1;
        end

        for itemID, count in pairs(reservesCount) do
            self:CancelReserve(player, itemID, count, false, true, winner);
        end
    end
    
    if member.ReservesLeft == 0 then
        member.OptedOut = nil;
    end
    member.ReservesLeft = member.ReservesLeft + amount;
    member.ReservesDelta = member.ReservesDelta + amount;

    -- Send packets
    LootReserve.Comm:SendSessionInfo(player);

    -- Send chat messages
    if self.CurrentSession.Settings.ChatFallback then
        if not self:IsAddonUser(player) then
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
    local function Failure(result, reservesLeft, postText, ...)
        LootReserve.Comm:SendOptResult(player, result);
        if chat then
            local text = LootReserve.Constants.OptResultText[result] or "";
            if postText then
                text = text .. postText;
            end
            LootReserve:SendChatMessage(format(text, ...), "WHISPER", player);
        end
        return false;
    end

    if not LootReserve:IsPlayerOnline(player) then
        return Failure(LootReserve.Constants.ReserveResult.NotInRaid, 0);
    end

    if not self.CurrentSession or not self.CurrentSession.AcceptingReserves then
        return Failure(LootReserve.Constants.ReserveResult.NoSession, 0);
    end

    local member = self.CurrentSession.Members[player];
    if not member then
        return Failure(LootReserve.Constants.ReserveResult.NotMember, 0);
    end
    
    member.OptedOut = out;

    -- Send packets
    LootReserve.Comm:SendOptResult(player, LootReserve.Constants.OptResult.OK);
    LootReserve.Comm:SendOptInfo(player, out);

    -- Send chat messages
    if self.CurrentSession.Settings.ChatFallback then
        if chat or not self:IsAddonUser(player) then
            local categories = LootReserve:GetCategoriesText(self.CurrentSession and self.CurrentSession.Settings.LootCategories);
            
            LootReserve:SendChatMessage(format("You have opted %s using your %d%s reserve%s%s. You can opt back %s with  !opt %s",
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

    local function Failure(result, reservesLeft, postText, ...)
        LootReserve.Comm:SendReserveResult(player, itemID, result, reservesLeft);
        if chat then
            local text = LootReserve.Constants.ReserveResultText[result] or "";
            if postText then
                text = text .. postText;
            end
            LootReserve:SendChatMessage(format(text, ...), "WHISPER", player);
        end
        return false;
    end

    if not skipChecks and not LootReserve:IsPlayerOnline(player) then
        return Failure(LootReserve.Constants.ReserveResult.NotInRaid, 0);
    end

    if not self.CurrentSession or not self.CurrentSession.AcceptingReserves then
        return Failure(LootReserve.Constants.ReserveResult.NoSession, 0);
    end

    local member = self.CurrentSession.Members[player];
    if not member then
        return Failure(LootReserve.Constants.ReserveResult.NotMember, 0);
    end

    if not skipChecks and self.CurrentSession.Settings.Lock and member.Locked then
        return Failure(LootReserve.Constants.ReserveResult.Locked, "#");
    end

    if not self.ReservableItems[itemID] then
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
            return Failure(LootReserve.Constants.ReserveResult.NoReservesLeft, member.ReservesLeft, ". To cancel a reserve, whisper me:  !cancel ItemLinkOrName");
        end

        if member.ReservesLeft < count then
            return Failure(LootReserve.Constants.ReserveResult.NotEnoughReservesLeft, member.ReservesLeft, ". You have %d/%d %s left. To cancel a reserve, whisper me:  !cancel ItemLinkOrName",
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
    LootReserve.Comm:SendReserveResult(player, itemID, result, member.ReservesLeft);
    LootReserve.Comm:SendOptInfo(player, member.OptedOut);
    if self.CurrentSession.Settings.Blind then
        local _, myReserves = LootReserve:GetReservesData(reserve.Players, player);
        LootReserve.Comm:SendReserveInfo(player, itemID, LootReserve:RepeatedTable(player, myReserves));
    else
        LootReserve.Comm:BroadcastReserveInfo(itemID, reserve.Players);
    end

    -- Send chat messages
    if self.CurrentSession.Settings.ChatFallback then
        if chat or not self:IsAddonUser(player) then
            -- Whisper player
            LootReserve:RunWhenItemCached(itemID, function()
                local reserve = self.CurrentSession.ItemReserves[itemID];
                if not reserve or #reserve.Players == 0 then return; end

                local name, link = GetItemInfo(itemID);
                if not name or not link then
                    return true;
                end

                local _, myReserves = LootReserve:GetReservesData(reserve.Players, player);
                LootReserve:SendChatMessage(format("You reserved %s%s. %s more %s available. To cancel a reserve, whisper me:  !cancel ItemLinkOrName",
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
            LootReserve:RunWhenItemCached(itemID, function()
                local reserve = self.CurrentSession.ItemReserves[itemID];
                if not reserve or #reserve.Players <= 1 then return; end

                local name, link = GetItemInfo(itemID);
                if not name or not link then
                    return true;
                end

                local sentToPlayer = { };
                for _, other in ipairs(reserve.Players) do
                    if other ~= player and LootReserve:IsPlayerOnline(other) and not self:IsAddonUser(other) and not sentToPlayer[other] then
                        local post = LootReserve:GetReservesString(true, reserve.Players, other, true, link);
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

function LootReserve.Server:CancelReserve(player, itemID, count, chat, forced, winner)
    count = math.max(1, count or 1);

    local function Failure(result, reservesLeft, postText, ...)
        LootReserve.Comm:SendCancelReserveResult(player, itemID, result, reservesLeft);
        if chat then
            local text = LootReserve.Constants.CancelReserveResultText[result] or "";
            if postText then
                text = text .. postText;
            end
            LootReserve:SendChatMessage(format(text, ...), "WHISPER", player);
        end
        return false;
    end

    if not LootReserve:IsPlayerOnline(player) and not forced then
        return Failure(LootReserve.Constants.CancelReserveResult.NotInRaid, 0);
    end

    if not self.CurrentSession or (not self.CurrentSession.AcceptingReserves and not forced) then
        return Failure(LootReserve.Constants.CancelReserveResult.NoSession, 0);
    end

    local member = self.CurrentSession.Members[player];
    if not member then
        return Failure(LootReserve.Constants.CancelReserveResult.NotMember, 0);
    end

    if self.CurrentSession.Settings.Lock and member.Locked and not forced then
        return Failure(LootReserve.Constants.CancelReserveResult.Locked, "#");
    end

    if not self.ReservableItems[itemID] then
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
        member.ReservesLeft = math.min(member.ReservesLeft + 1, self.CurrentSession.Settings.MaxReservesPerPlayer + member.ReservesDelta);
        LootReserve:TableRemove(member.ReservedItems, itemID);
        LootReserve:TableRemove(reserve.Players, player);
    end

    -- Send packets
    LootReserve.Comm:SendOptInfo(player, member.OptedOut);
    LootReserve.Comm:SendCancelReserveResult(player, itemID, forced and LootReserve.Constants.CancelReserveResult.Forced or LootReserve.Constants.CancelReserveResult.OK, member.ReservesLeft, winner);
    if self.CurrentSession.Settings.Blind then
        local _, myReserves = LootReserve:GetReservesData(reserve.Players, player);
        LootReserve.Comm:SendReserveInfo(player, itemID, LootReserve:RepeatedTable(player, myReserves));
    else
        LootReserve.Comm:BroadcastReserveInfo(itemID, reserve.Players);
    end

    -- Remove the item entirely if all reserves were cancelled
    if #reserve.Players == 0 then
        self:CancelRollRequest(item);
        self.CurrentSession.ItemReserves[itemID] = nil;
    end

    -- Send chat messages
    if self.CurrentSession.Settings.ChatFallback then
        if chat or not self:IsAddonUser(player) then
            -- Whisper player
            LootReserve:RunWhenItemCached(itemID, function()
                local name, link = GetItemInfo(itemID);
                if not name or not link then
                    return true;
                end

                if winner then
                    LootReserve:PrintMessage(format("%s'%s reserve for %s%s has been automatically removed.",
                        LootReserve:ColoredPlayer(player),
                        player:match(".$") == "s" and "" or "s",
                        link,
                        count > 1 and format(" x%d", count) or ""
                    ));
                    LootReserve:SendChatMessage(format("Your reserve for %s%s has been automatically removed.", link, count > 1 and format(" x%d", count) or ""), "WHISPER", player);
                else
                    LootReserve:SendChatMessage(format(forced and "Your reserve for %s%s has been removed. %d more %s available.%s" or "You cancelled your reserve for %s%s. %d more %s available.%s",
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
            LootReserve:RunWhenItemCached(itemID, function()
                local reserve = self.CurrentSession.ItemReserves[itemID];
                if not reserve or #reserve.Players == 0 then return; end

                local name, link = GetItemInfo(itemID);
                if not name or not link then
                    return true;
                end

                local sentToPlayer = { };
                for _, other in ipairs(reserve.Players) do
                    if player ~= other and LootReserve:IsPlayerOnline(other) and not self:IsAddonUser(other) and not sentToPlayer[other] then
                        local post = LootReserve:GetReservesString(true, reserve.Players, other, true, link);
                        if #post > 0 then
                            LootReserve:SendChatMessage(post, "WHISPER", other);
                        end
                        sentToPlayer[other] = true;
                    end
                end
            end);
        end
    end

    -- Remove member info if player no longer has any reserves left and isn't in the group anymore
    self:UpdateGroupMembers();

    -- Update UI
    self:UpdateReserveList();
    self:UpdateReserveListRolls();
    self.MembersEdit:UpdateMembersList();

    return true;
end

function LootReserve.Server:SendReservesList(player, onlyRelevant, force)
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
        -- Announce()
        LootReserve:RunWhenItemCached(itemID, function()
            local list = { };

            local function sortByItemName(_, _, aItem, bItem)
                local aName = GetItemInfo(aItem);
                local bName = GetItemInfo(bItem);
                if not aName then return false; end
                if not bName then return true; end
                return aName < bName;
            end

            for itemID, reserve in LootReserve:Ordered(self.CurrentSession.ItemReserves, sortByItemName) do
                local name, link = GetItemInfo(itemID);
                if not name or not link then
                    return true;
                end
                local reservesText = LootReserve:GetReservesData(self.CurrentSession.ItemReserves[itemID].Players);
                local _, myReserves = LootReserve:GetReservesData(self.CurrentSession.ItemReserves[itemID].Players, player);
                if not onlyRelevant or myReserves > 0 then
                    table.insert(list, format("%s: %s", link, reservesText));
                end
            end

            if #list > 0 then
                LootReserve:SendChatMessage(format("%seserved items:", onlyRelevant and "Your r" or "R"), player and "WHISPER" or self:GetChatChannel(), player);
                for _, line in ipairs(list) do
                    LootReserve:SendChatMessage(line, player and "WHISPER" or self:GetChatChannel(), player);
                end
            else
                LootReserve:SendChatMessage(onlyRelevant and "You currently have no reserves. To reserve an item, whisper me:  !reserve ItemLinkOrName" or "There are currently no reserves", player and "WHISPER" or self:GetChatChannel(), player);
            end
            self:SendSupportString(player);
        end);
    end
end

function LootReserve.Server:IsRolling(item)
    if type(item) == "number" then
        return self.RequestedRoll and self.RequestedRoll.Item:GetID() == item;
    else
        return self.RequestedRoll and self.RequestedRoll.Item == LootReserve.Item(item);
    end
end

function LootReserve.Server:ExpireRollRequest()
    if self.RequestedRoll then
        if self:GetWinningRollAndPlayers() then
            -- If someone rolled on this phase - end the roll
            if self.Settings.RollFinishOnExpire then
                self:FinishRollRequest(self.RequestedRoll.Item);
            end
        else
            -- If nobody rolled on this phase - advance to the next
            if self.Settings.RollAdvanceOnExpire then
                if not self:AdvanceRollPhase(self.RequestedRoll.Item) then
                    -- If the phase cannot advance (i.e. because we ran out of phases) - end the roll
                    if self.Settings.RollFinishOnExpire then
                        self:FinishRollRequest(self.RequestedRoll.Item);
                    end
                end
            elseif not self.RequestedRoll.Phases or #self.RequestedRoll.Phases <= 1 then
                -- If no more phases remaining - end the roll
                if self.Settings.RollFinishOnExpire then
                    self:FinishRollRequest(self.RequestedRoll.Item);
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
            if count == 1 and LootReserve:IsPlayerOnline(winner) then
                self:FinishRollRequest(self.RequestedRoll.Item, true);
                self:RollEnded();
                return true;
            end
        end

        -- Check if any player other than the current winning player has still not rolled
        if (not self.RequestedRoll.Custom or self.RequestedRoll.AllowedPlayers) and not self.RequestedRoll.RaidRoll and self.Settings.RollFinishOnAllReservingRolled then
            local highestPlayers = select(2, self:GetWinningRollAndPlayers()) or { };
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

function LootReserve.Server:GetWinningRollAndPlayers()
    if self.RequestedRoll then
        local highestRoll = LootReserve.Constants.RollType.NotRolled;
        local highestPlayers = { };
        for player, roll in self:GetOrderedPlayerRolls(self.RequestedRoll.Players) do
            if highestRoll <= roll and LootReserve:IsPlayerOnline(player) then
                if highestRoll ~= roll then
                    highestRoll = roll;
                    table.wipe(highestPlayers);
                end
                if not LootReserve:Contains(highestPlayers, player) then
                    table.insert(highestPlayers, player);
                end
            end
        end
        if highestRoll > LootReserve.Constants.RollType.NotRolled then
            return highestRoll, highestPlayers;
        end
    end
end

function LootReserve.Server:ResolveRollTie(item)
    if self:IsRolling(item) then
        local roll, players = self:GetWinningRollAndPlayers();
        if roll and players and #players > 1 then
            LootReserve:RunWhenItemCached(item:GetID(), function()
                local name, link = item:GetInfo();
                if not name or not link then
                    return true;
                end

                local playersText = LootReserve:FormatReservesText(players);
                LootReserve:SendChatMessage(format("Tie for %s between players %s. All rolled %d. Please /roll again", link, playersText, roll), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollTie));
            end);

            if self.RequestedRoll.Custom then
                self:CancelRollRequest(item);
                self:RequestCustomRoll(item, self.Settings.RollLimitDuration and self.Settings.RollDuration or nil, nil, players);
            else
                self:CancelRollRequest(item);
                self:RequestRoll(item, nil, nil, players);
            end
        end
    end
end

function LootReserve.Server:FinishRollRequest(item, soleReserver)
    local function RecordRollWinner(player, item, phase)
        if self.CurrentSession then
            local member = self.CurrentSession.Members[player];
            if member then
                if not member.WonRolls then member.WonRolls = { }; end
                table.insert(member.WonRolls,
                {
                    Item  = item,
                    Phase = phase,
                    Time  = time(),
                });
            end

            local itemWinners = self.CurrentSession.WonItems[item:GetID()] or {
                TotalCount = 0,
                Players    = { },
            };
            self.CurrentSession.WonItems[item:GetID()] = itemWinners;
            table.insert(itemWinners.Players, player);
            itemWinners.TotalCount = itemWinners.TotalCount + 1;
            
            -- Remove winner's reserves
            if self.CurrentSession.ItemReserves[item:GetID()] and LootReserve:Contains(self.CurrentSession.ItemReserves[item:GetID()].Players, player) then
                if self.Settings.WinnerReservesRemoval == LootReserve.Constants.WinnerReservesRemoval.Single then
                    self:CancelReserve(player, item:GetID(), 1, false, true, true);
                    self:IncrementReservesDelta(player, -1);
                elseif self.Settings.WinnerReservesRemoval == LootReserve.Constants.WinnerReservesRemoval.Duplicate then
                    local count = 0;
                    for i, itemID in ipairs(member.ReservedItems) do
                        if itemID == item:GetID() then
                            count = count + 1;
                        end
                    end
                    self:CancelReserve(player, item:GetID(), count, false, true, true);
                    self:IncrementReservesDelta(player, 0 - count);
                elseif self.Settings.WinnerReservesRemoval == LootReserve.Constants.WinnerReservesRemoval.All then
                    self:IncrementReservesDelta(player, 0 - member.ReservesLeft - #member.ReservedItems, true);
                end
            end
        end
    end

    if self:IsRolling(item) then
        local roll, players = self:GetWinningRollAndPlayers();
        if roll and players then
            local raidroll = self.RequestedRoll.RaidRoll;
            local phases = LootReserve:Deepcopy(self.RequestedRoll.Phases);

            local recordPhase;
            if self.RequestedRoll.RaidRoll then
                recordPhase = LootReserve.Constants.WonRollPhase.RaidRoll;
            elseif self.RequestedRoll.Custom then
                recordPhase = phases and phases[1];
            else
                recordPhase = LootReserve.Constants.WonRollPhase.Reserve;
            end
            for _, player in ipairs(players) do
                RecordRollWinner(player, item, recordPhase);
            end

            LootReserve:RunWhenItemCached(item:GetID(), function()
                local name, link = item:GetInfo();
                if not name or not link then
                    return true;
                end

                local quality = select(3, GetItemInfo(item:GetID()));
                local playersText = LootReserve:FormatPlayersText(players);
                LootReserve:SendChatMessage(format(raidroll and "%s won %s%s via raid-roll" or "%s won %s%s with a roll of %d", playersText, LootReserve:FixLink(link), phases and format(" for %s", phases[1] or "") or "", roll), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollWinner));
                if LootReserve.Server.Settings.ChatAnnounceWinToGuild and IsInGuild() and quality >= (LootReserve.Server.Settings.ChatAnnounceWinToGuildThreshold or 3) then
                    for _, player in ipairs(players) do
                        if LootReserve:Contains(self.GuildMembers, player) then
                            LootReserve:SendChatMessage(format("%s won %s%s", playersText, LootReserve:FixLink(link), phases and format(" for %s", phases[1] or "") or ""), "GUILD");
                            break;
                        end
                    end
                end
            end);

            if self.Settings.MasterLooting and self.Settings.RollMasterLoot then
                self:MasterLootItem(item, players[1], #players > 1);
            end
        elseif soleReserver and not self.RequestedRoll.Custom and next(self.RequestedRoll.Players) then
            local player = next(self.RequestedRoll.Players);
            players = { player };
            RecordRollWinner(player, item, LootReserve.Constants.WonRollPhase.Reserve);

            -- Announce
            LootReserve:RunWhenItemCached(item:GetID(), function()
                local name, link, quality = item:GetInfo();
                if not name or not link then
                    return true;
                end

                LootReserve:SendChatMessage(format("%s won %s as the only reserver", player, LootReserve:FixLink(link)), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollWinner));
                if LootReserve.Server.Settings.ChatAnnounceWinToGuild and IsInGuild() and quality >= (LootReserve.Server.Settings.ChatAnnounceWinToGuildThreshold or 3) then
                    if LootReserve:Contains(self.GuildMembers, player) then
                        LootReserve:SendChatMessage(format("%s won %s", player, LootReserve:FixLink(link)), "GUILD");
                    end
                end
            end);

            if self.Settings.MasterLooting and self.Settings.RollMasterLoot then
                self:MasterLootItem(item, player);
            end
        end

        self:CancelRollRequest(item, players);
    end

    self:UpdateReserveListRolls();
    self:UpdateRollListRolls();
    self.MembersEdit:UpdateMembersList();
end

function LootReserve.Server:AdvanceRollPhase(item)
    if self:IsRolling(item) then
        if self:GetWinningRollAndPlayers() then return; end
        if not self.RequestedRoll.Custom then return; end

        local phases = LootReserve:Deepcopy(self.RequestedRoll.Phases);
        if not phases or #phases <= 1 then return; end
        table.remove(phases, 1);

        self:CancelRollRequest(item);
        self:RequestCustomRoll(item, self.Settings.RollLimitDuration and self.Settings.RollDuration or nil, phases);
        return true;
    end
end

function LootReserve.Server:CancelRollRequest(item, winners, noHistory)
    self.NextRollCountdown = nil;
    if self:IsRolling(item) then
        if type(item) == "number" then
            item = self.RequestedRoll.Item;
        end
        -- Cleanup chat from players who didn't roll to reduce memory and storage space usage
        if self.RequestedRoll.Chat then
            local toRemove = { };
            for player in pairs(self.RequestedRoll.Chat) do
                if not self.RequestedRoll.Players[player] then
                    table.insert(toRemove, player);
                end
            end
            for _, player in ipairs(toRemove) do
                self.RequestedRoll.Chat[player] = nil;
            end
        end

        if winners then
            self.RequestedRoll.Winners = { };
            for _, winner in ipairs(winners) do
                table.insert(self.RequestedRoll.Winners, winner);
            end
        end

        if not noHistory then
            local historicalEntry = LootReserve:Deepcopy(self.RequestedRoll);
            historicalEntry.Duration    = nil;
            historicalEntry.MaxDuration = nil;
            if historicalEntry.Phases then
                historicalEntry.Phases = {historicalEntry.Phases[1]};
            end
            table.insert(self.RollHistory, historicalEntry);
            while #self.RollHistory > self.Settings.RollHistoryKeepLimit do
               table.remove(self.RollHistory, 1); 
            end

            if LootReserve:GetTradeableItemCount(item) <= 1 then
                if self.Settings.RemoveRecentLootAfterRolling then
                    LootReserve:TableRemove(self.RecentLoot, item);
                end
            end
            if winners then
                LootReserve:PrintMessage(format("%s won by: %s", self.RequestedRoll.Item:GetLink(), LootReserve:FormatPlayersTextColored(self.RequestedRoll.Winners)));
            end
        end

        LootReserve.Comm:BroadcastRequestRoll(LootReserve.Item(0), { }, self.RequestedRoll.Custom or self.RequestedRoll.RaidRoll);
        self.RequestedRoll = nil;
        self.SaveProfile.RequestedRoll = self.RequestedRoll;
        self:UpdateReserveListRolls();
        self:UpdateRollList();
    end
end

function LootReserve.Server:CanRoll(player)
    -- Roll must exist
    if not self.RequestedRoll then return false; end
    -- Roll must not have expired yet
    if self.RequestedRoll.MaxDuration and self.RequestedRoll.Duration == 0 then return false; end
    -- Player must be online and in raid
    if not LootReserve:IsPlayerOnline(player) then return false; end
    -- Player must be allowed to roll if the roll is limited to specific players
    if self.RequestedRoll.AllowedPlayers and not LootReserve:Contains(self.RequestedRoll.AllowedPlayers, player) then return false; end
    -- Only raid roll creator is allowed to re-roll the raid-roll
    if self.RequestedRoll.RaidRoll then return LootReserve:IsMe(player); end
    -- Player must have reserved the item if the roll is for a reserved item
    if not self.RequestedRoll.Custom and not self.RequestedRoll.Players[player] then return false; end
    -- Player cannot roll if they have rolled their allotted number of times already
    if self.RequestedRoll.Players[player] then
        local hasRolls = false;
        for _, roll in ipairs(self.RequestedRoll.Players[player]) do
            if roll == LootReserve.Constants.RollType.NotRolled then
               hasRolls = true;
               break;
            end
        end
        if not hasRolls then
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
                        if online and strsplit("-", name) == player and self:CanRoll(name) then
                            return name;
                        end
                    end);
                end
                player = player and LootReserve:Player(player);
                if player and roll and min == "1" and (max == "100" or self.RequestedRoll.RaidRoll and tonumber(max) == LootReserve:GetNumGroupMembers()) and tonumber(roll) and self:CanRoll(player) then
                    -- Re-roll the raid-roll
                    if self.RequestedRoll.RaidRoll then
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

                        if tonumber(max) ~= #raid or #raid ~= LootReserve:GetNumGroupMembers() then return; end

                        player = raid[tonumber(roll)];
                    else
                        self.RequestedRoll.Chat = self.RequestedRoll.Chat or { };
                        self.RequestedRoll.Chat[player] = self.RequestedRoll.Chat[player] or { };
                        table.insert(self.RequestedRoll.Chat[player], format("%d|%s|%s", time(), "SYSTEM", text));
                    end

                    local rollSubmitted = false;
                    local extraRolls    = false;
                    if not self.RequestedRoll.Players[player] then
                       self.RequestedRoll.Players[player] = { LootReserve.Constants.RollType.NotRolled }; -- Should only even happen for custom rolls, non-custom ones should fail in LootReserve.Server:CanRoll
                    end
                    for i, oldRoll in ipairs(self.RequestedRoll.Players[player]) do
                        if oldRoll == LootReserve.Constants.RollType.NotRolled then
                            if not rollSubmitted then
                                self.RequestedRoll.Players[player][i] = tonumber(roll);
                                rollSubmitted = true;
                            else
                                extraRolls = true;
                            end
                        end
                    end

                    self:UpdateReserveListRolls();
                    self:UpdateRollList();

                    if self.ExtraRollRequestNag[player] then
                        self.ExtraRollRequestNag[player]:Cancel();
                        self.ExtraRollRequestNag[player] = nil;
                    end

                    if not self:TryFinishRoll() then
                        if extraRolls then
                            -- RollRequestWindow will currently just trigger /roll multiple times, uncomment to send roll request after roll request until the player exhausts all their roll slots
                            -- LootReserve.Comm:SendRequestRoll(player, self.RequestedRoll.Item, {player}, self.RequestedRoll.Custom, self.RequestedRoll.Duration, self.RequestedRoll.MaxDuration, self.RequestedRoll.Phases and self.RequestedRoll.Phases[1] or "");

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
                                local name, link = closureItem:GetName(), closureItem:GetLink();
                                if not name or not link then
                                    C_Timer.After(0.25, WhisperPlayer);
                                    return;
                                end
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
                            self.ExtraRollRequestNag[player] = C_Timer.NewTimer(4, WhisperPlayer);
                        end
                    end
                end
            end
        end);

        local function ProcessChat(text, sender, isPrivateChannel)
            sender = LootReserve:Player(sender);

            text = text:lower();
            text = LootReserve:StringTrim(text);
            if text == "pass" or text == "p" then
                if self.RequestedRoll then
                    self:PassRoll(sender, self.RequestedRoll.Item, true, isPrivateChannel);
                end
                return;
            end
        end
        local chatTypes =
        {
            "CHAT_MSG_YELL",
            "CHAT_MSG_RAID",
            "CHAT_MSG_RAID_LEADER",
            "CHAT_MSG_RAID_WARNING",
        };
        local chatTypesPrivate = {
            "CHAT_MSG_WHISPER",
            "CHAT_MSG_SAY",
            "CHAT_MSG_GUILD",
            "CHAT_MSG_OFFICER",
        }
        local partyChat = IsInRaid() and chatTypesPrivate or chatTypes;
        table.insert(partyChat, "CHAT_MSG_PARTY");
        table.insert(partyChat, "CHAT_MSG_PARTY_LEADER");
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
                    self.RequestedRoll.Chat = self.RequestedRoll.Chat or { };
                    self.RequestedRoll.Chat[player] = self.RequestedRoll.Chat[player] or { };
                    table.insert(self.RequestedRoll.Chat[player], format("%d|%s|%s", time(), savedType, text));
                    self:UpdateReserveListButtons();
                    self:UpdateRollListButtons();
                end
            end);
        end
    end
end

function LootReserve.Server:RequestRoll(item, duration, phases, allowedPlayers)
    if not self.CurrentSession then
        LootReserve:ShowError("Loot reserves haven't been started");
        return;
    end

    local reserve = self.CurrentSession.ItemReserves[item:GetID()];
    if not reserve then
        LootReserve:ShowError("That item is not reserved by anyone");
        return;
    end

    local players = allowedPlayers or reserve.Players

    self.RequestedRoll =
    {
        Item        = item,
        StartTime   = time(),
        MaxDuration = duration and duration > 0 and duration or nil,
        Duration    = duration and duration > 0 and duration or nil,
        Phases      = phases and #phases > 0 and phases or nil,
        Custom      = nil,
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

    LootReserve.Comm:BroadcastRequestRoll(item, players, self.RequestedRoll.Custom, self.RequestedRoll.Duration, self.RequestedRoll.MaxDuration, self.RequestedRoll.Phases and self.RequestedRoll.Phases[1] or "");

    if self.CurrentSession.Settings.ChatFallback then
        local durationStr = "";
        if self.RequestedRoll.MaxDuration then
            local time = self.RequestedRoll.MaxDuration;
            durationStr = time < 60      and format(" (%d %s)", time,      time ==  1 and "sec" or "secs")
                       or time % 60 == 0 and format(" (%d %s)", time / 60, time == 60 and "min" or "mins")
                       or                    format(" (%d:%02d mins)", math.floor(time / 60), time % 60);
        end

        -- Broadcast roll
        LootReserve:RunWhenItemCached(item:GetID(), function()
            local name, link = item:GetInfo();
            if not name or not link then
                return true;
            end

            local playersText = LootReserve:FormatReservesText(players);
            LootReserve:SendChatMessage(format("%s - roll on reserved %s%s", playersText, LootReserve:FixLink(link), durationStr), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollStartReserved));

            local closureRoll = self.RequestedRoll;
            local closureItem = self.RequestedRoll.Item;
            
            local sentToPlayer = { };
            for player, roll in self:GetOrderedPlayerRolls(self.RequestedRoll.Players) do
                local function WhisperPlayer()
                    if not self.RequestedRoll or self.RequestedRoll ~= closureRoll or self.RequestedRoll.Item ~= closureItem then return; end
                    local rollsCount = 0;
                    local extraRolls = 0;
                    for _, roll in ipairs(self.RequestedRoll.Players[player]) do
                        rollsCount = rollsCount + 1;
                    end
                    local name, link = closureItem:GetName(), closureItem:GetLink();
                    if not name or not link then
                        C_Timer.After(0.25, WhisperPlayer);
                        return;
                    end
                    LootReserve:SendChatMessage(format("Please /roll on %s you reserved%s.%s",
                        link,
                        rollsCount > 1 and format(" (1/%d)", rollsCount) or "",
                        durationStr
                    ), "WHISPER", player);
                end
                
                local _, myReserves = LootReserve:GetReservesData(players, player);
                if roll == LootReserve.Constants.RollType.NotRolled and LootReserve:IsPlayerOnline(player) and not sentToPlayer[player] then
                    self.ExtraRollRequestNag[player] = C_Timer.NewTimer(self:IsAddonUser(player) and 4 or 6, WhisperPlayer);
                    sentToPlayer[player] = true;
                end
            end
        end);
    end

    self:UpdateReserveListRolls();
    self:UpdateRollList();
end

function LootReserve.Server:RequestCustomRoll(item, duration, phases, allowedPlayers)
    self.RequestedRoll =
    {
        Item           = item,
        StartTime      = time(),
        MaxDuration    = duration and duration > 0 and duration or nil,
        Duration       = duration and duration > 0 and duration or nil,
        Phases         = phases and #phases > 0 and phases or nil,
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

    LootReserve.Comm:BroadcastRequestRoll(item, players, true, self.RequestedRoll.Duration, self.RequestedRoll.MaxDuration, self.RequestedRoll.Phases and self.RequestedRoll.Phases[1] or "");

    if not self.CurrentSession or self.CurrentSession.Settings.ChatFallback then
        local durationStr = "";
        if self.RequestedRoll.MaxDuration then
            local time = self.RequestedRoll.MaxDuration;
            durationStr = time < 60      and format(" (%d %s)", time,      time ==  1 and "sec" or "secs")
                       or time % 60 == 0 and format(" (%d %s)", time / 60, time == 60 and "min" or "mins")
                       or                    format(" (%d:%02d mins)", math.floor(time / 60), time % 60);
        end

        -- Broadcast roll
        LootReserve:RunWhenItemCached(item:GetID(), function()
            local link = item:GetLink();
            if not link then
                return true;
            end

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
                    local name, link = closureItem:GetName(), closureItem:GetLink();
                    if not name or not link then
                        C_Timer.After(0.25, WhisperPlayer);
                        return;
                    end
                    LootReserve:SendChatMessage(format("Please /roll on %s%s.%s",
                        link,
                        rollsCount > 1 and format(" (1/%d)", rollsCount) or "",
                        durationStr
                    ), "WHISPER", player);
                end
                
                local _, myReserves = LootReserve:GetReservesData(players, player);
                if roll == LootReserve.Constants.RollType.NotRolled and LootReserve:IsPlayerOnline(player) and not sentToPlayer[player] then
                    self.ExtraRollRequestNag[player] = C_Timer.NewTimer(self:IsAddonUser(player) and 4 or 6, WhisperPlayer);
                    sentToPlayer[player] = true;
                end
                end
            else
                LootReserve:SendChatMessage(format("Roll%s on %s%s", self.RequestedRoll.Phases and format(" for %s", self.RequestedRoll.Phases[1] or "") or "", link, durationStr), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollStartCustom));
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

    if not chat then
        -- If the player passed through the addon button - they may have done it after /rolling manually, so ignore it if they have even a single roll already registered
        local i = 1;
        for _, roll in ipairs(self.RequestedRoll.Players[player]) do
            if roll > LootReserve.Constants.RollType.NotRolled then
               return;
            end
        end
    else
        -- If the player passed through a chat message - consider it a deliberate choice and overwrite all their rolls with passes
    end

    local success = false;
    local i = 1;
    for i, roll in ipairs(self.RequestedRoll.Players[player]) do
        if roll >= LootReserve.Constants.RollType.NotRolled then
            self.RequestedRoll.Players[player][i] = LootReserve.Constants.RollType.Passed;
            success = true;
        end
    end

    if not success then
        return;
    end

    local item = self.RequestedRoll.Item;
    if chat then
        LootReserve.Comm:SendRequestRoll(player, LootReserve.Item(0), { }, self.RequestedRoll.Custom or self.RequestedRoll.RaidRoll);

        -- Whisper player
        LootReserve:RunWhenItemCached(item:GetID(), function()
            if not self.RequestedRoll or self.RequestedRoll.Item ~= item then return; end

            local name, link = item:GetInfo();
            if not name or not link then
                return true;
            end

            local phase = self.RequestedRoll.Phases and self.RequestedRoll.Phases[1] or nil;
            LootReserve:SendChatMessage(format("You have passed on %s%s.", link, phase and format(" for %s", phase)), "WHISPER", player);
        end);
    end
    if not chat or isPrivateChannel then
        -- Announce
        LootReserve:RunWhenItemCached(item:GetID(), function()
            if not self.RequestedRoll or self.RequestedRoll.Item ~= item then return; end

            local name, link = item:GetInfo();
            if not name or not link then
                return true;
            end

            local phase = self.RequestedRoll.Phases and self.RequestedRoll.Phases[1] or nil;
            LootReserve:SendChatMessage(format("%s has passed on %s%s.", player, link, phase and format(" for %s", phase)), "RAID");
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
    self.RequestedRoll.Players[player][rollNumber] = LootReserve.Constants.RollType.Deleted;

    local phase = self.RequestedRoll.Phases and self.RequestedRoll.Phases[1] or nil;

    LootReserve.Comm:SendDeletedRoll(player, item, oldRoll, phase);
    if (not self.CurrentSession or self.CurrentSession.Settings.ChatFallback) and not self:IsAddonUser(player) then
        -- Whisper player
        LootReserve:RunWhenItemCached(item:GetID(), function()
            local name, link = item:GetInfo();
            if not name or not link then
                return true;
            end

            LootReserve:SendChatMessage(format("Your %sroll of %d on %s was deleted.", phase and format("%s ", phase) or "", oldRoll, link), "WHISPER", player);
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




-- Applying temporary fix for Blizzard issue involving MasterLoot frame.
-- This can be removed once Blizzard fixes the issue on their end.

-- Issue can be reproduced as follows:
-- Open the loot frame
-- Click on an item to be masterlooted
-- Without the below fix, many addon-created dropdowns will no longer work.

--[[
    MasterLootWindowFix - version 1.0 (06/26/21)
    Kirsia - Dalaran (US-retail)
    Roxi - Atiesh (US-TBCC)
]]--

-- Just clearing all points when the ML frame is hidden
-- so it is no longer bound to the drop down menu
hooksecurefunc(MasterLooterFrame, 'Hide', function(self) self:ClearAllPoints() end)




function LootReserve.Server:MasterLootItem(item, player, multipleWinners)
    if not item or not player then return; end

    local name, link = item:GetInfo();
    if not name or not link then return; end
    local quality = select(3, GetItemInfo(item:GetID()))

    if not self.Settings.MasterLooting or not self.Settings.RollMasterLoot then
        -- LootReserve:ShowError("Failed to masterloot %s to %s: masterlooting not enabled in LootReserve settings", link, LootReserve:ColoredPlayer(player));
        return;
    end

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
                for playerIndex = 1, 40 do
                    if not GetMasterLootCandidate(pending.ItemIndex, playerIndex) then
                        break;
                    end
                    if LootReserve:IsSamePlayer(GetMasterLootCandidate(pending.ItemIndex, playerIndex), pending.Player) then
                        GiveMasterLoot(pending.ItemIndex, playerIndex);
                        MasterLooterFrame:Hide();
                        return;
                    end
                end
                if MasterLooterFrame and MasterLooterFrame:IsShown() then
                   MasterLooterFrame:Hide(); 
                end
                LootReserve:ShowError("Failed to masterloot %s to %s: Player is not a masterloot candidate for this item", link, LootReserve:ColoredPlayer(pending.Player));
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

function LootReserve.Server:WhisperPlayerWithoutReserves(target)
    if not self.CurrentSession then return; end
    if not self.CurrentSession.AcceptingReserves then return; end
    
    local member = self.CurrentSession.Members[target]
    if not member then return; end

    if member.ReservesLeft > 0 and not member.OptedOut and LootReserve:IsPlayerOnline(target) then
        if member.Locked then
            member.Locked = false;
        end
        local categories = LootReserve:GetCategoriesText(self.CurrentSession and self.CurrentSession.Settings.LootCategories);
        
        LootReserve.Comm:SendSessionInfo(target);
        LootReserve:SendChatMessage(format("Don't forget to reserve your item%s%s. You have %d reserve%s left. Whisper  !reserve ItemLinkOrName",
            self.CurrentSession.Settings.MaxReservesPerPlayer + member.ReservesDelta == 1 and "" or "s",
            categories ~= "" and format(" for %s", categories) or "",
            member.ReservesLeft,
            member.ReservesLeft == 1 and "" or "s"
        ), "WHISPER", target);
        LootReserve:SendChatMessage(format("You can opt out of using your remaining %d %s by whispering  !opt out",
            member.ReservesLeft,
            member.ReservesLeft == 1 and "reserve" or "reserves"
        ), "WHISPER", target);
        self:SendSupportString(target);
    end
end

function LootReserve.Server:WhisperAllWithoutReserves()
    if not self.CurrentSession then return; end
    if not self.CurrentSession.AcceptingReserves then return; end

    for player, member in pairs(self.CurrentSession.Members) do
        if member.ReservesLeft > 0 and not member.OptedOut and LootReserve:IsPlayerOnline(player) then
            if member.Locked then
                member.Locked = false;
            end
            local categories = LootReserve:GetCategoriesText(self.CurrentSession and self.CurrentSession.Settings.LootCategories);
            
            LootReserve.Comm:SendSessionInfo(target);
            LootReserve:SendChatMessage(format("Don't forget to reserve your item%s%s. You have %d reserve%s left. Whisper  !reserve ItemLinkOrName",
                self.CurrentSession.Settings.MaxReservesPerPlayer + member.ReservesDelta == 1 and "" or "s",
                categories ~= "" and format(" for %s", categories) or "",
                member.ReservesLeft,
                member.ReservesLeft == 1 and "" or "s"
            ), "WHISPER", player);
            LootReserve:SendChatMessage(format("You can opt out of using your remaining %d %s by whispering  !opt out",
                member.ReservesLeft,
                member.ReservesLeft == 1 and "reserve" or "reserves"
            ), "WHISPER", player);
            self:SendSupportString(player);
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
    if self.Settings.ChatReservesList and not self.CurrentSession.Settings.Blind then
        LootReserve:SendChatMessage("To see all reserves made, whisper me:  !reserves", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionInstructions));
    end
    LootReserve:SendChatMessage("To reserve an item, whisper me:  !reserve ItemLinkOrName", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionInstructions));
    if self.CurrentSession.Settings.Multireserve > 1 then
        LootReserve:SendChatMessage("To reserve an item multiple times, whisper me:  !reserve ItemLinkOrName x" .. self.CurrentSession.Settings.Multireserve, self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionResume));
    end
end
