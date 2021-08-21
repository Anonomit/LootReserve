LootReserve = LootReserve or { };
LootReserve.Server =
{
    CurrentSession = nil,
    NewSessionSettings =
    {
        LootCategory         = 100,
        MaxReservesPerPlayer = 1,
        Multireserve         = nil,
        Duration             = 300,
        ChatFallback         = true,
        Blind                = false,
        Lock                 = false,
        ImportedMembers      = { },
    },
    Settings =
    {
        ChatAsRaidWarning               = { },
        ChatAnnounceWinToGuild          = false,
        ChatAnnounceWinToGuildThreshold = 3,
        ChatReservesList                = true,
        ChatUpdates                     = true,
        ReservesSorting                 = LootReserve.Constants.ReservesSorting.ByTime,
        UseGlobalProfile                = false,
        Phases                          = LootReserve:Deepcopy(LootReserve.Constants.DefaultPhases),
        RollUsePhases                   = false,
        RollPhases                      = { },
        RollAdvanceOnExpire             = true,
        RollLimitDuration               = false,
        RollDuration                    = 60,
        RollFinishOnExpire              = true,
        RollFinishOnAllReservingRolled  = false,
        RollFinishOnRaidRoll            = false,
        RollSkipNotContested            = false,
        RollHistoryDisplayLimit         = 5,
        RollMasterLoot                  = false,
        MasterLooting                   = false,
        ItemConditions                  = { },
        CollapsedExpansions             = { },
        HighlightSameItemWinners        = false,
        MaxRecentLoot                   = 15,
        RemoveRecentLootAfterRolling    = true,
        KeepUnlootedRecentLoot          = false,
        UseUnitFrames                   = true,
    },
    RequestedRoll       = nil,
    RollHistory         = { },
    RecentLoot          = { },
    CurrentLoot         = { },
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
        LootReserve.Server:CancelReserve(self.data.Player, self.data.Item, 1, false, true);
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

StaticPopupDialogs["LOOTRESERVE_CONFIRM_GLOBAL_PROFILE_ENABLE"] =
{
    text         = "By enabling global profile you acknowledge that all the mess you can create by e.g. swapping between characters who are in different raid groups will be on your conscience.|n|nDo you want to enable global profile?",
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

StaticPopupDialogs["LOOTRESERVE_CONFIRM_ANNOUNCE_BLIND_RESERVES"] =
{
    text         = "Blind reserves in effect. Are you sure you want to publicly announce all reserves?",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        LootReserve.Server:SendReservesList(nil, false, nil, true);
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
        return self.Settings.ChatAsRaidWarning[announcement] and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) and "RAID_WARNING" or "RAID";
    elseif IsInGroup() then
        return "PARTY";
    else
        return "WHISPER", UnitName("player");
    end
end

function LootReserve.Server:HasRelevantRecentChat(chat, player)
    if not chat or not chat[player] then return false; end
    if #chat[player] > 1 then return true; end
    local time, type, text = strsplit("|", chat[player][1], 3);
    return type ~= "SYSTEM";
end

function LootReserve.Server:IsAddonUser(player)
    return LootReserve:IsMe(player) or self.AddonUsers[player] or false;
end

function LootReserve.Server:SetAddonUser(player, isUser)
    if self.AddonUsers[player] ~= isUser then
        self.AddonUsers[player] = isUser;
        self:UpdateAddonUsers();
    end
end

function LootReserve.Server:GetSavedItemConditions(category)
    if not category then return { }; end
    local container = self.Settings.ItemConditions[category];
    if not container then
        container = { };
        self.Settings.ItemConditions[category] = container;
    end
    return container;
end

function LootReserve.Server:GetNewSessionItemConditions()
    return self:GetSavedItemConditions(self.NewSessionSettings.LootCategory);
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

    loadInto(self, LootReserveGlobalSave.Server, "NewSessionSettings");
    loadInto(self, LootReserveGlobalSave.Server, "Settings");

    if self.Settings.UseGlobalProfile then
        LootReserveGlobalSave.Server.GlobalProfile = LootReserveGlobalSave.Server.GlobalProfile or { };
        self.SaveProfile = LootReserveGlobalSave.Server.GlobalProfile;
    else
        self.SaveProfile = LootReserveCharacterSave.Server;
    end
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
    if self.NewSessionSettings.ItemConditions then
        for item, conditions in pairs(self.NewSessionSettings.ItemConditions) do
            local category = conditions.Custom;
            conditions.Custom = conditions.Custom and true or nil;

            if category then
                self.Settings.ItemConditions[category] = self.Settings.ItemConditions[category] or { };
                self.Settings.ItemConditions[category][item] = LootReserve:Deepcopy(conditions);
            end
            for _, category in ipairs(LootReserve.Data:GetItemCategories(item)) do
                self.Settings.ItemConditions[category] = self.Settings.ItemConditions[category] or { };
                self.Settings.ItemConditions[category][item] = LootReserve:Deepcopy(conditions);
            end
        end
        self.NewSessionSettings.ItemConditions = nil;
    end
    if self.CurrentSession then
        if not self.CurrentSession.ItemConditions then
            self.CurrentSession.ItemConditions = { };
        end

        if self.CurrentSession.Settings.ItemConditions then
            for item, conditions in pairs(self.CurrentSession.Settings.ItemConditions) do
                local category = conditions.Custom;
                conditions.Custom = conditions.Custom and true or nil;

                if category == self.CurrentSession.Settings.LootCategory or LootReserve.Data:IsItemInCategory(item, self.CurrentSession.Settings.LootCategory) then
                    self.CurrentSession.ItemConditions[item] = LootReserve:Deepcopy(conditions);
                end
            end
            self.CurrentSession.Settings.ItemConditions = nil;
        end
    end

    -- 2021-06-17: Upgrade roll history to support multiple rolls from the same player
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
            if roll.Item == item then
                return true;
            end
        end
    end
    return false;
end

function LootReserve.Server:PrepareLootTracking()
    if self.LootTrackingRegistered then return; end
    self.LootTrackingRegistered = true;

    local loot = LootReserve:FormatToRegexp(LOOT_ITEM);
    local lootMultiple = LootReserve:FormatToRegexp(LOOT_ITEM_MULTIPLE);
    local lootSelf = LootReserve:FormatToRegexp(LOOT_ITEM_SELF);
    local lootSelfMultiple = LootReserve:FormatToRegexp(LOOT_ITEM_SELF_MULTIPLE);
    LootReserve:RegisterEvent("CHAT_MSG_LOOT", function(text)
        local looter, item, count;
        item, count = text:match(lootSelfMultiple);
        if item and count then
            looter = LootReserve:Me();
        else
            item = text:match(lootSelf);
            if item then
                looter = LootReserve:Me();
                count = 1;
            else
                looter, item, count = text:match(lootMultiple);
                if looter and item and count then
                    -- ok
                else
                    looter, item = text:match(loot);
                    if looter and item then
                        count = 1;
                    else
                        return;
                    end
                end
            end
        end

        looter = LootReserve:Player(looter);
        item = tonumber(item:match("item:(%d+)"));
        count = tonumber(count);
        if looter and item and count then
            LootReserve:TableRemove(self.RecentLoot, item);
            table.insert(self.RecentLoot, item);
            while #self.RecentLoot > self.Settings.MaxRecentLoot do
                table.remove(self.RecentLoot, 1);
            end

            if self.CurrentSession and self.ReservableItems[item] then
                local tracking = self.CurrentSession.LootTracking[item] or
                {
                    TotalCount = 0,
                    Players    = { },
                };
                self.CurrentSession.LootTracking[item] = tracking;
                tracking.TotalCount = tracking.TotalCount + count;
                tracking.Players[looter] = (tracking.Players[looter] or 0) + count;

                self:UpdateReserveList();
            end
        end
    end);
    LootReserve:RegisterEvent("LOOT_OPENED", function(text)
        table.wipe(self.CurrentLoot);
        for lootSlot = 1, GetNumLootItems() do
            if GetLootSlotType(lootSlot) == 1 then -- loot slot contains item, not currency/empty
                local link = GetLootSlotLink(lootSlot);
                if link then
                    local item = tonumber(link:match("item:(%d+)"));
                    if item then
                        table.insert(self.CurrentLoot, item);
                    end
                end
            end
        end
    end);
    LootReserve:RegisterEvent("LOOT_CLOSED", function(text)
        if not self.Settings.KeepUnlootedRecentLoot then
            return;
        end

        for _, item in ipairs(self.CurrentLoot) do
            LootReserve:TableRemove(self.RecentLoot, item);
            table.insert(self.RecentLoot, item);
            while #self.RecentLoot > self.Settings.MaxRecentLoot do
                table.remove(self.RecentLoot, 1);
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
            if not LootReserve:UnitInRaid(player) and #member.ReservedItems == 0 then
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
                    ReservedItems = { },
                    Locked        = nil,
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

        LootReserve:RegisterEvent("GROUP_LEFT", function()
            if self.CurrentSession then
                self:StopSession();
                self:ResetSession();
            end
            table.wipe(self.AddonUsers);
            self:UpdateAddonUsers();
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

        GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
            if self.CurrentSession then
                local name, link = tooltip:GetItem();
                if not link then return; end

                local item = tonumber(link:match("item:(%d+)"));
                if item and self.CurrentSession.WonItems[item] then
                    local reservesText = LootReserve:FormatReservesTextColored(self.CurrentSession.WonItems[item].Players);
                    tooltip:AddLine("|TInterface\\BUTTONS\\UI-GroupLoot-Coin-Up:32:32:0:-4|t Won by " .. reservesText, 1, 1, 1);
                end
                if item and self.CurrentSession.ItemReserves[item] then
                    local reservesText = LootReserve:FormatReservesTextColored(self.CurrentSession.ItemReserves[item].Players);
                    tooltip:AddLine("|TInterface\\BUTTONS\\UI-GroupLoot-Dice-Up:32:32:0:-4|t Reserved by " .. reservesText, 1, 1, 1);
                end
            end
        end);
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
                    self:SendReservesList(sender, true);
                end
                return;
            elseif text == "!myreserve" or text == "!myreserves" or text == "!myres" then
                if self.Settings.ChatReservesList then
                    self:SendReservesList(sender, true, true);
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
                return;
            elseif stringStartsWith(text, "cancel") then
                text = text:sub(1 + #("cancel"));
                command = "cancel";
            end

            text = LootReserve:StringTrim(text);
            if command == "cancel" then
                local count = tonumber(text:match("^[Xx]?%s*(%d+)%s*[Xx]?$"));
                if #text == 0 then
                    count = 1;
                end
                if count then
                    if #member.ReservedItems > 0 then
                        local reservesCount = { };
                        for i = #member.ReservedItems, math.max(#member.ReservedItems - count + 1, 1), -1 do
                            reservesCount[member.ReservedItems[i]] = reservesCount[member.ReservedItems[i]] and reservesCount[member.ReservedItems[i]] + 1 or 1;
                        end

                        for item, count in pairs(reservesCount) do
                            self:CancelReserve(sender, item, count, true);
                        end
                    else
                        LootReserve:SendChatMessage("You don't have any reserves to cancel", "WHISPER", sender);
                    end
                    return;
                end
            end

            local function handleItemCommand(item, command, count)
                count = count or 1;
                if self.ReservableItems[item] then
                    if command == "reserve" then
                        self:Reserve(sender, item, count, true);
                    elseif command == "cancel" then
                        self:CancelReserve(sender, item, count, true);
                    end
                else
                    LootReserve:SendChatMessage("That item is not reservable in this raid.", "WHISPER", sender);
                end
            end

            local item = tonumber(text:match("item:(%d+)"));
            local count = tonumber(text:match("%]|h|r%s*[xX]?%s*(%d+)"));
            if item then
                handleItemCommand(item, command, count);
            else
                count = tonumber(text:match("%s*[xX]?%s*(%d+)%s*[Xx]?$"));
                if count then
                    text = text:match("^(.-)%s*[xX]?%s*(%d+)%s*[Xx]?$");
                else
                    count = 1;
                end
                text = LootReserve:TransformSearchText(text);
                local function handleItemCommandByName()
                    if self:UpdateItemNameCache() then
                        local match = nil;
                        local matches = { };
                        for item, name in pairs(self.ItemNames) do
                            if self.ReservableItems[item] and string.find(name, text) and not LootReserve:Contains(matches, item) then
                                match = match and 0 or item;
                                table.insert(matches, item);
                            end
                        end

                        if not match then
                            LootReserve:SendChatMessage("Cannot find an item with that name.", "WHISPER", sender);
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
                        end
                    else
                        C_Timer.After(0.25, handleItemCommandByName);
                    end
                end

                if #text >= 3 then
                    handleItemCommandByName();
                else
                    LootReserve:SendChatMessage("That name is too short, 3 or more letters required.", "WHISPER", sender);
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
    for item, conditions in pairs(self.CurrentSession.ItemConditions) do
        if item ~= 0 and conditions.Custom and LootReserve.ItemConditions:TestServer(item) then
            self.ReservableItems[item] = true;
        end
    end
    for id, category in pairs(LootReserve.Data.Categories) do
        if category.Children and (not self.CurrentSession.Settings.LootCategory or id == self.CurrentSession.Settings.LootCategory) and LootReserve.Data:IsCategoryVisible(category) then
            for _, child in ipairs(category.Children) do
                if child.Loot then
                    for _, item in ipairs(child.Loot) do
                        if item ~= 0 and LootReserve.ItemConditions:TestServer(item) then
                            self.ReservableItems[item] = true;
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
    for item, conditions in pairs(self:GetNewSessionItemConditions()) do
        if item ~= 0 and conditions.Custom then
            local name = GetItemInfo(item);
            if name then
                self.ItemNames[item] = LootReserve:TransformSearchText(name);
            else
                self.AllItemNamesCached = false;
            end
        end
    end
    if self.CurrentSession then
        for item, conditions in pairs(self.CurrentSession.ItemConditions) do
            if item ~= 0 and conditions.Custom then
                local name = GetItemInfo(item);
                if name then
                    self.ItemNames[item] = LootReserve:TransformSearchText(name);
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
                    for _, item in ipairs(child.Loot) do
                        if item ~= 0 and not self.ItemNames[item] then
                            local name = GetItemInfo(item);
                            if name then
                                self.ItemNames[item] = LootReserve:TransformSearchText(name);
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
                ReservesLeft = self.CurrentSession.Settings.MaxReservesPerPlayer,
                ReservedItems = { ItemID, ItemID, ... },
                Locked = nil,
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
                Players = { PlayerName, PlayerName, ... },
            },
            ...
        },
        ]]
        ItemReserves = { },
        --[[
        {
            [ItemID] =
            {
                Item = ItemID,
                StartTime = time(),
                Players = { PlayerName, PlayerName, ... },
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
                Players = { [PlayerName] = Count, ... },
            },
            ...
        },
        ]]
    };
    if self.CurrentSession.Settings.Multireserve then
        if self.CurrentSession.Settings.MaxReservesPerPlayer > 1 then
            self.CurrentSession.Settings.Multireserve = math.min(self.CurrentSession.Settings.MaxReservesPerPlayer, self.CurrentSession.Settings.Multireserve);
        else
            self.CurrentSession.Settings.Multireserve = nil;
        end
    end
    self.SaveProfile.CurrentSession = self.CurrentSession;

    LootReserve:ForEachRaider(function(name)
        self.CurrentSession.Members[name] =
        {
            ReservesLeft  = self.CurrentSession.Settings.MaxReservesPerPlayer,
            ReservedItems = { },
        };
    end);

    self:PrepareSession();

    -- Import reserves
    for player, importedMember in pairs(self.CurrentSession.Settings.ImportedMembers) do
        local member = self.CurrentSession.Members[player] or
        {
            ReservesLeft  = self.CurrentSession.Settings.MaxReservesPerPlayer,
            ReservedItems = { },
        };
        self.CurrentSession.Members[player] = member;
        for _, item in ipairs(importedMember.ReservedItems) do
            if self.ReservableItems[item] and --[[LootReserve.ItemConditions:TestPlayer(player, item, true) and]] --[[not LootReserve:Contains(member.ReservedItems, item) and--]] member.ReservesLeft > 0 then
                member.ReservesLeft = member.ReservesLeft - 1;
                table.insert(member.ReservedItems, item);

                local reserve = self.CurrentSession.ItemReserves[item] or
                {
                    Item      = item,
                    StartTime = time(),
                    Players   = { },
                };
                self.CurrentSession.ItemReserves[item] = reserve;
                table.insert(reserve.Players, player);
            end
        end
    end
    table.wipe(self.NewSessionSettings.ImportedMembers);
    table.wipe(self.CurrentSession.Settings.ImportedMembers);

    LootReserve.Comm:BroadcastVersion();
    LootReserve.Comm:BroadcastSessionInfo(true);
    if self.CurrentSession.Settings.ChatFallback then
        local category = LootReserve.Data.Categories[self.CurrentSession.Settings.LootCategory];
        local duration = self.CurrentSession.Settings.Duration
        local count = self.CurrentSession.Settings.MaxReservesPerPlayer;
        LootReserve:SendChatMessage(format("Loot reserves are now started%s%s%s. %d reserved %s per character%s.",
            category and format(" for %s", category.Name) or "",
            self.CurrentSession.Settings.Blind and " (blind)" or "",
            duration ~= 0 and format(" and will last for %d:%02d minutes", math.floor(duration / 60), duration % 60) or "",
            count,
            count == 1 and "item" or "items",
            self.CurrentSession.Settings.Multireserve and format(", up to x%d on a single item", self.CurrentSession.Settings.Multireserve) or ""
        ), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionStart));
        if self.Settings.ChatReservesList and not self.CurrentSession.Settings.Blind then
            LootReserve:SendChatMessage("To see all reserves made, whisper me:  !reserves", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionStart));
        end
        LootReserve:SendChatMessage("To reserve an item, whisper me:  !reserve ItemLinkOrName", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionStart));
        if self.CurrentSession.Settings.Multireserve then
            LootReserve:SendChatMessage("To reserve an item multiple times, whisper me:  !reserve ItemLinkOrName x" .. self.CurrentSession.Settings.Multireserve, self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionStart));
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
        LootReserve:SendChatMessage("Accepting loot reserves again.", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionResume));
        if self.Settings.ChatReservesList and not self.CurrentSession.Settings.Blind then
            LootReserve:SendChatMessage("To see all reserves made, whisper me:  !reserves", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionResume));
        end
        LootReserve:SendChatMessage("To reserve an item, whisper me:  !reserve ItemLinkOrName", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionResume));
        if self.CurrentSession.Settings.Multireserve then
            LootReserve:SendChatMessage("To reserve an item multiple times, whisper me:  !reserve ItemLinkOrName x" .. self.CurrentSession.Settings.Multireserve, self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionResume));
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
        LootReserve:SendChatMessage("No longer accepting loot reserves", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionStop));
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

function LootReserve.Server:Reserve(player, item, count, chat, skipChecks)
    count = math.max(1, count or 1);

    local function Failure(result, reservesLeft, postText, ...)
        LootReserve.Comm:SendReserveResult(player, item, result, reservesLeft);
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

    if not self.ReservableItems[item] then
        return Failure(LootReserve.Constants.ReserveResult.ItemNotReservable, member.ReservesLeft);
    end

    if not skipChecks then
        local canReserve, conditionResult = LootReserve.ItemConditions:TestPlayer(player, item, true);
        if not canReserve then
            return Failure(conditionResult or LootReserve.Constants.ReserveResult.FailedConditions, member.ReservesLeft);
        end

        if not self.CurrentSession.Settings.Multireserve and LootReserve:Contains(member.ReservedItems, item) then
            return Failure(LootReserve.Constants.ReserveResult.AlreadyReserved, member.ReservesLeft);
        end

        if member.ReservesLeft <= 0 then
            return Failure(LootReserve.Constants.ReserveResult.NoReservesLeft, member.ReservesLeft, ". You can cancel a reserve with  !reserve cancel [ItemLinkOrName]");
        end

        if member.ReservesLeft < count then
            return Failure(LootReserve.Constants.ReserveResult.NotEnoughReservesLeft, member.ReservesLeft, ". You have %d/%d %s left. You can cancel a reserve with  !reserve cancel [ItemLinkOrName]",
                member.ReservesLeft,
                self.CurrentSession.Settings.MaxReservesPerPlayer,
                self.CurrentSession.Settings.MaxReservesPerPlayer == 1 and "reserve" or "reserves"
            );
        end
    end

    -- Create item reserve
    local reserve = self.CurrentSession.ItemReserves[item] or
    {
        Item      = item,
        StartTime = time(),
        Players   = { },
    };
    self.CurrentSession.ItemReserves[item] = reserve;

    if self.CurrentSession.Settings.Multireserve then
        local _, myReserves = LootReserve:GetReservesData(reserve.Players, player);
        if myReserves >= self.CurrentSession.Settings.Multireserve then
            return Failure(LootReserve.Constants.ReserveResult.MultireserveLimit, member.ReservesLeft);
        end
    end

    -- Perform reserving
    local result = LootReserve.Constants.ReserveResult.OK;
    for i = 1, count do
        if self.CurrentSession.Settings.Multireserve then
            local _, myReserves = LootReserve:GetReservesData(reserve.Players, player);
            if myReserves >= self.CurrentSession.Settings.Multireserve then
                result = LootReserve.Constants.ReserveResult.MultireserveLimitPartial;
                break;
            end
        end

        if not LootReserve.ItemConditions:TestPlayer(player, item, true) then
            result = LootReserve.Constants.ReserveResult.FailedLimitPartial;
            break;
        end

        member.ReservesLeft = member.ReservesLeft - 1;
        table.insert(member.ReservedItems, item);
        table.insert(reserve.Players, player);
    end
    table.sort(reserve.Players);

    -- Send packets
    LootReserve.Comm:SendReserveResult(player, item, result, member.ReservesLeft);
    if self.CurrentSession.Settings.Blind then
        local _, myReserves = LootReserve:GetReservesData(reserve.Players, player);
        LootReserve.Comm:SendReserveInfo(player, item, LootReserve:RepeatedTable(player, myReserves));
    else
        LootReserve.Comm:BroadcastReserveInfo(item, reserve.Players);
    end

    -- Send chat messages
    if self.CurrentSession.Settings.ChatFallback then
        local function WhisperPlayer()
            local reserve = self.CurrentSession.ItemReserves[item];
            if not reserve or #reserve.Players == 0 then return; end

            local name, link = GetItemInfo(item);
            if not name or not link then
                C_Timer.After(0.25, WhisperPlayer);
                return;
            end

            local _, myReserves = LootReserve:GetReservesData(reserve.Players, player);
            LootReserve:SendChatMessage(format("You reserved %s%s. %s more %s available. You can cancel with  !reserve cancel [ItemLinkOrName]",
                link,
                myReserves > 1 and format(" x%d", myReserves) or "",
                member.ReservesLeft == 0 and "No" or tostring(member.ReservesLeft),
                member.ReservesLeft == 1 and "reserve" or "reserves"
            ), "WHISPER", player);

            local post = LootReserve:GetReservesString(true, reserve.Players, player, false, link);
            if #post > 0 then
                LootReserve:SendChatMessage(post, "WHISPER", player);
            end
        end
        if chat or not self:IsAddonUser(player) then
            WhisperPlayer();
        end

        local function WhisperOthers()
            local reserve = self.CurrentSession.ItemReserves[item];
            if not reserve or #reserve.Players <= 1 then return; end

            local name, link = GetItemInfo(item);
            if not name or not link then
                C_Timer.After(0.25, WhisperOthers);
                return;
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
        end
        if self.Settings.ChatUpdates and not self.CurrentSession.Settings.Blind then
            WhisperOthers();
        end
    end

    -- Update UI
    self:UpdateReserveList();
    self.MembersEdit:UpdateMembersList();

    return true;
end

function LootReserve.Server:CancelReserve(player, item, count, chat, forced)
    count = math.max(1, count or 1);

    local function Failure(result, reservesLeft, postText, ...)
        LootReserve.Comm:SendCancelReserveResult(player, item, result, reservesLeft);
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

    if not self.ReservableItems[item] then
        return Failure(LootReserve.Constants.CancelReserveResult.ItemNotReservable, member.ReservesLeft);
    end

    if not LootReserve:Contains(member.ReservedItems, item) then
        return Failure(LootReserve.Constants.CancelReserveResult.NotReserved, member.ReservesLeft);
    end

    local reserve = self.CurrentSession.ItemReserves[item];
    if not reserve then
        return Failure(LootReserve.Constants.CancelReserveResult.InternalError, member.ReservesLeft);
    end

    local _, myReserves = LootReserve:GetReservesData(reserve.Players, player);
    if myReserves < count then
        return Failure(LootReserve.Constants.CancelReserveResult.NotEnoughReserves, member.ReservesLeft);
    end

    -- Perform reserve cancelling
    for i = 1, count do
        if not LootReserve:Contains(member.ReservedItems, item) then
            break;
        end

        -- Remove player from the active roll on that item
        if self:IsRolling(item) and not self.RequestedRoll.Custom and not self.RequestedRoll.RaidRoll and self.RequestedRoll.Players[player] then
            if #self.RequestedRoll.Players[player] == 1 then
                self.RequestedRoll.Players[player] = nil;
            else
                table.remove(self.RequestedRoll.Players[player]);
            end
        end

        member.ReservesLeft = math.min(member.ReservesLeft + 1, self.CurrentSession.Settings.MaxReservesPerPlayer);
        LootReserve:TableRemove(member.ReservedItems, item);
        LootReserve:TableRemove(reserve.Players, player);
    end

    -- Send packets
    LootReserve.Comm:SendCancelReserveResult(player, item, forced and LootReserve.Constants.CancelReserveResult.Forced or LootReserve.Constants.CancelReserveResult.OK, member.ReservesLeft);
    if self.CurrentSession.Settings.Blind then
        local _, myReserves = LootReserve:GetReservesData(reserve.Players, player);
        LootReserve.Comm:SendReserveInfo(player, item, LootReserve:RepeatedTable(player, myReserves));
    else
        LootReserve.Comm:BroadcastReserveInfo(item, reserve.Players);
    end

    -- Remove the item entirely if all reserves were cancelled
    if #reserve.Players == 0 then
        self:CancelRollRequest(item);
        self.CurrentSession.ItemReserves[item] = nil;
    end

    -- Send chat messages
    if self.CurrentSession.Settings.ChatFallback then
        local function WhisperPlayer()
            local name, link = GetItemInfo(item);
            if not name or not link then
                C_Timer.After(0.25, WhisperPlayer);
                return;
            end

            LootReserve:SendChatMessage(format(forced and "Your reserve for %s has been forcibly removed. %d more %s available." or "You cancelled your reserve for %s. %d more %s available.",
                link,
                member.ReservesLeft,
                member.ReservesLeft == 1 and "reserve" or "reserves"
            ), "WHISPER", player);
        end
        if chat or not self:IsAddonUser(player) then
            WhisperPlayer();
        end

        local function WhisperOthers()
            local reserve = self.CurrentSession.ItemReserves[item];
            if not reserve or #reserve.Players == 0 then return; end

            local name, link = GetItemInfo(item);
            if not name or not link then
                C_Timer.After(0.25, WhisperOthers);
                return;
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
        end
        if self.Settings.ChatUpdates and not self.CurrentSession.Settings.Blind then
            WhisperOthers();
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

function LootReserve.Server:SendReservesList(player, chat, onlyRelevant, force)
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
        local function Announce()
            local list = { };

            local function sortByItemName(_, _, aItem, bItem)
                local aName = GetItemInfo(aItem);
                local bName = GetItemInfo(bItem);
                if not aName then return false; end
                if not bName then return true; end
                return aName < bName;
            end

            for item, reserve in LootReserve:Ordered(self.CurrentSession.ItemReserves, sortByItemName) do
                if --[[LootReserve.ItemConditions:TestPlayer(player, item, true)]]true then
                    local name, link = GetItemInfo(item);
                    if not name or not link then
                        C_Timer.After(0.25, Announce);
                        return;
                    end
                    local reservesText = LootReserve:GetReservesData(self.CurrentSession.ItemReserves[item].Players);
                    local _, myReserves = LootReserve:GetReservesData(self.CurrentSession.ItemReserves[item].Players, player);
                    if not onlyRelevant or myReserves > 0 then
                        table.insert(list, format("%s: %s", link, reservesText));
                    end
                end
            end

            if #list > 0 then
                LootReserve:SendChatMessage("%seserved items:", onlyRelevant and "Your r" or "R", player and "WHISPER" or "RAID", player);
                for _, line in ipairs(list) do
                    LootReserve:SendChatMessage(line, player and "WHISPER" or "RAID", player);
                end
            else
                LootReserve:SendChatMessage("No reserves were made yet", player and "WHISPER" or "RAID", player);
            end
        end
        Announce();
    end
end

function LootReserve.Server:IsRolling(item)
    return self.RequestedRoll and self.RequestedRoll.Item == item;
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
            for player, roll in pairs(self.RequestedRoll.Players) do
                count = count + 1;
            end
            if count == 1 then
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
            local function Announce()
                local name, link = GetItemInfo(item);
                if not name or not link then
                    C_Timer.After(0.25, Announce);
                    return;
                end

                local playersText = LootReserve:FormatReservesText(players);
                LootReserve:SendChatMessage(format("Tie for %s between players %s. All rolled %d. Please /roll again", link, playersText, roll), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollTie));
            end
            Announce();

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

            local itemWinners = self.CurrentSession.WonItems[item] or {
                TotalCount = 0,
                Players    = { },
            };
            self.CurrentSession.WonItems[item] = itemWinners;
            table.insert(itemWinners.Players, player);
            itemWinners.TotalCount = itemWinners.TotalCount + 1;
        end
    end

    if self:IsRolling(item) then
        local roll, players = self:GetWinningRollAndPlayers();
        if roll and players then
            local raidroll = self.RequestedRoll.RaidRoll;
            local phases = LootReserve:Deepcopy(self.RequestedRoll.Phases);
            local category = self.CurrentSession and LootReserve.Data.Categories[self.CurrentSession.Settings.LootCategory] or nil;

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

            local function Announce()
                local name, link, quality = GetItemInfo(item);
                if not name or not link then
                    C_Timer.After(0.25, Announce);
                    return;
                end

                local playersText = LootReserve:FormatPlayersText(players);
                LootReserve:SendChatMessage(format(raidroll and "%s won %s%s via raid-roll" or "%s won %s%s with a roll of %d", playersText, LootReserve:FixLink(link), phases and format(" for %s", phases[1] or "") or "", roll), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollWinner));
                if LootReserve.Server.Settings.ChatAnnounceWinToGuild and IsInGuild() and quality >= (LootReserve.Server.Settings.ChatAnnounceWinToGuildThreshold or 3) then
                    for _, player in ipairs(players) do
                        if LootReserve:Contains(self.GuildMembers, player) then
                            LootReserve:SendChatMessage(format("%s won %s%s%s", playersText, LootReserve:FixLink(link), phases and format(" for %s", phases[1] or "") or "", category and format(" from %s", category.Name) or ""), "GUILD");
                            break;
                        end
                    end
                end
            end
            Announce();

            if self.Settings.MasterLooting and self.Settings.RollMasterLoot then
                self:MasterLootItem(item, players[1], #players > 1);
            end
        elseif soleReserver and not self.RequestedRoll.Custom and next(self.RequestedRoll.Players) then
            local player = next(self.RequestedRoll.Players);
            players = { player };
            RecordRollWinner(player, item, LootReserve.Constants.WonRollPhase.Reserve);

            local category = self.CurrentSession and LootReserve.Data.Categories[self.CurrentSession.Settings.LootCategory] or nil;
            local function Announce()
                local name, link, quality = GetItemInfo(item);
                if not name or not link then
                    C_Timer.After(0.25, Announce);
                    return;
                end

                LootReserve:SendChatMessage(format("%s won %s as the only reserver", player, LootReserve:FixLink(link)), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollWinner));
                if LootReserve.Server.Settings.ChatAnnounceWinToGuild and IsInGuild() and quality >= (LootReserve.Server.Settings.ChatAnnounceWinToGuildThreshold or 3) then
                    if LootReserve:Contains(self.GuildMembers, player) then
                        LootReserve:SendChatMessage(format("%s won %s%s", player, LootReserve:FixLink(link), category and format(" from %s", category.Name) or ""), "GUILD");
                    end
                end
            end
            Announce();

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
            table.insert(self.RollHistory, self.RequestedRoll);

            if LootReserve:GetTradeableItemCount(item) <= 1 then
                if self.Settings.RemoveRecentLootAfterRolling then
                    LootReserve:TableRemove(self.RecentLoot, item);
                end
                LootReserve:TableRemove(self.CurrentLoot, item);
            end
        end

        LootReserve.Comm:BroadcastRequestRoll(0, { }, self.RequestedRoll.Custom or self.RequestedRoll.RaidRoll);
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
                if player and roll and min == "1" and (max == "100" or self.RequestedRoll.RaidRoll and tonumber(max) == GetNumGroupMembers()) and tonumber(roll) and self:CanRoll(player) then
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

                        if tonumber(max) ~= #raid or #raid ~= GetNumGroupMembers() then return; end

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

                                local name, link = GetItemInfo(closureItem);
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

                            if not self:IsAddonUser(player) then
                                WhisperPlayer();
                            else
                                self.ExtraRollRequestNag[player] = C_Timer.NewTimer(3, WhisperPlayer);
                            end
                        end
                    end
                end
            end
        end);

        local function ProcessChat(text, sender)
            sender = LootReserve:Player(sender);

            text = text:lower();
            text = LootReserve:StringTrim(text);
            if text == "pass" or text == "p" then
                if self.RequestedRoll then
                    self:PassRoll(sender, self.RequestedRoll.Item, true);
                end
                return;
            end
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
        };
        for _, type in ipairs(chatTypes) do
            LootReserve:RegisterEvent(type, ProcessChat);
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
        for _, type in ipairs(chatTypes) do
            local savedType = type:gsub("CHAT_MSG_", "");
            LootReserve:RegisterEvent(type, function(text, sender)
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

    local reserve = self.CurrentSession.ItemReserves[item];
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

        local function BroadcastRoll()
            local name, link = GetItemInfo(item);
            if not name or not link then
                C_Timer.After(0.25, BroadcastRoll);
                return;
            end

            local playersText = LootReserve:FormatReservesText(players);
            LootReserve:SendChatMessage(format("%s - roll on reserved %s%s", playersText, LootReserve:FixLink(link), durationStr), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollStartReserved));

            local sentToPlayer = { };
            for player, roll in self:GetOrderedPlayerRolls(self.RequestedRoll.Players) do
                local _, myReserves = LootReserve:GetReservesData(players, player);
                if roll == LootReserve.Constants.RollType.NotRolled and LootReserve:IsPlayerOnline(player) and not self:IsAddonUser(player) and not sentToPlayer[player] then
                    local rollProgressText = "";
                    if myReserves > 1 then
                        rollProgressText = format(" (%d/%d)", 1, myReserves);
                    end
                    LootReserve:SendChatMessage(format("Please /roll on %s you reserved%s.%s", link, rollProgressText, durationStr), "WHISPER", player);
                    sentToPlayer[player] = true;
                end
            end
        end
        BroadcastRoll();
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

        local function BroadcastRoll()
            local name, link = GetItemInfo(item);
            if not name or not link then
                C_Timer.After(0.25, BroadcastRoll);
                return;
            end

            if allowedPlayers then
                -- Should already be announced in LootReserve.Server:ResolveRollTie
                --LootReserve:SendChatMessage(format("%s - roll on %s%s", strjoin(", ", unpack(allowedPlayers)), LootReserve:FixLink(link), durationStr), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollStartCustom));

                local sentToPlayer = { };
                for player, roll in self:GetOrderedPlayerRolls(self.RequestedRoll.Players) do
                    local _, myReserves = LootReserve:GetReservesData(allowedPlayers, player);
                    if roll == LootReserve.Constants.RollType.NotRolled and LootReserve:IsPlayerOnline(player) and not self:IsAddonUser(player) and not sentToPlayer[player] then
                        LootReserve:SendChatMessage(format("Please /roll on %s%s.%s", link, myReserves > 1 and format(" x%d", myReserves) or "", durationStr), "WHISPER", player);
                        sentToPlayer[player] = true;
                    end
                end
            else
                LootReserve:SendChatMessage(format("Roll%s on %s%s", self.RequestedRoll.Phases and format(" for %s", self.RequestedRoll.Phases[1] or "") or "", link, durationStr), self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.RollStartCustom));
            end
        end
        BroadcastRoll();
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
    RandomRoll(1, GetNumGroupMembers());

    self:UpdateRollList();
end

function LootReserve.Server:PassRoll(player, item, chat)
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

    if chat then
        LootReserve.Comm:SendRequestRoll(player, 0, { }, self.RequestedRoll.Custom or self.RequestedRoll.RaidRoll);

        local item = self.RequestedRoll.Item;
        local function WhisperPlayer()
            if not self.RequestedRoll or self.RequestedRoll.Item ~= item then return; end

            local name, link = GetItemInfo(item);
            if not name or not link then
                C_Timer.After(0.25, WhisperPlayer);
                return;
            end

            LootReserve:SendChatMessage(format("You passed on %s", link), "WHISPER", player);
        end
        WhisperPlayer();
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
        RandomRoll(1, GetNumGroupMembers());
        return;
    end

    local oldRoll = self.RequestedRoll.Players[player][rollNumber];
    self.RequestedRoll.Players[player][rollNumber] = LootReserve.Constants.RollType.Deleted;

    local phase = self.RequestedRoll.Phases and self.RequestedRoll.Phases[1] or nil;

    LootReserve.Comm:SendDeletedRoll(player, item, oldRoll, phase);
    if not self.CurrentSession or self.CurrentSession.Settings.ChatFallback then
        local function WhisperPlayer()
            local name, link = GetItemInfo(item);
            if not name or not link then
                C_Timer.After(0.25, BroadcastRoll);
                return;
            end

            LootReserve:SendChatMessage(format("Your %sroll of %d on %s was deleted.", phase and format("%s ", phase) or "", oldRoll, link), "WHISPER", player);
        end
        if not self:IsAddonUser(player) then
            WhisperPlayer();
        end
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

    local name, link, quality = GetItemInfo(item);
    if not name or not link or not quality then return; end

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
        LootReserve:ShowError("%s was not automatically masterlooted: more than one candidate", link);
        return;
    end

    if not self.MasterLootListUpdateRegistered then
        self.MasterLootListUpdateRegistered = true;
        LootReserve:RegisterEvent("OPEN_MASTER_LOOT_LIST", "UPDATE_MASTER_LOOT_LIST", function()
            local pending = self.PendingMasterLoot;
            self.PendingMasterLoot = nil;
            if pending and pending.ItemIndex == LootReserve:IsLootingItem(pending.Item) and pending.Timeout >= time() then
                for playerIndex = 1, MAX_RAID_MEMBERS do
                    if LootReserve:IsSamePlayer(GetMasterLootCandidate(pending.ItemIndex, playerIndex), pending.Player) then
                        GiveMasterLoot(pending.ItemIndex, playerIndex);
                        MasterLooterFrame:Hide();
                        return;
                    end
                end
                LootReserve:ShowError("Failed to masterloot %s to %s: player was not found in the list of masterloot candidates", link, LootReserve:ColoredPlayer(pending.Player));
            end
        end);
    end

    -- Prevent duplicate request. Hopefully...
    if self.PendingMasterLoot and self.PendingMasterLoot.Item == item and self.PendingMasterLoot.Timeout >= time() then
        LootReserve:ShowError("Failed to masterloot %s to %s: there's another master loot attempt in progress. Try again in 5 seconds", link, LootReserve:ColoredPlayer(player));
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

    if member.ReservesLeft > 0 and LootReserve:IsPlayerOnline(target) then
        LootReserve:SendChatMessage(format("Don't forget to reserve your items. You have %d %s left. Whisper  !reserve ItemLinkOrName",
            member.ReservesLeft,
            member.ReservesLeft == 1 and "reserve" or "reserves"
        ), "WHISPER", target);
    end
end

function LootReserve.Server:WhisperAllWithoutReserves()
    if not self.CurrentSession then return; end
    if not self.CurrentSession.AcceptingReserves then return; end

    for player, member in pairs(self.CurrentSession.Members) do
        if member.ReservesLeft > 0 and LootReserve:IsPlayerOnline(player) then
            LootReserve:SendChatMessage(format("Don't forget to reserve your items. You have %d %s left. Whisper  !reserve ItemLinkOrName",
                member.ReservesLeft,
                member.ReservesLeft == 1 and "reserve" or "reserves"
            ), "WHISPER", player);
        end
    end
end

function LootReserve.Server:BroadcastInstructions()
    if not self.CurrentSession then return; end
    if not self.CurrentSession.AcceptingReserves then return; end

    LootReserve:SendChatMessage("Loot reserves are currently ongoing.", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionInstructions));
    if self.Settings.ChatReservesList and not self.CurrentSession.Settings.Blind then
        LootReserve:SendChatMessage("To see all reserves made, whisper me:  !reserves", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionInstructions));
    end
    LootReserve:SendChatMessage("To reserve an item, whisper me:  !reserve ItemLinkOrName", self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionInstructions));
    if self.CurrentSession.Settings.Multireserve then
        LootReserve:SendChatMessage("To reserve an item multiple times, whisper me:  !reserve ItemLinkOrName x" .. self.CurrentSession.Settings.Multireserve, self:GetChatChannel(LootReserve.Constants.ChatAnnouncement.SessionInstructions));
    end
end
