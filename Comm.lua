local LibDeflate = LibStub:GetLibrary("LibDeflate");

LootReserve = LootReserve or { };
LootReserve.Comm =
{
    Prefix    = "LootReserve",
    Handlers  = { },
    Listening = false,
};

local Opcodes =
{
    Version                   = 1,
    ReportIncompatibleVersion = 2,
    Hello                     = 3,
    SessionInfo               = 4,
    SessionStop               = 5,
    SessionReset              = 6,
    ReserveItem               = 7,
    ReserveResult             = 8,
    ReserveInfo               = 9,
    CancelReserve             = 10,
    CancelReserveResult       = 11,
    RequestRoll               = 12,
    PassRoll                  = 13,
    DeletedRoll               = 14,
    OptOut                    = 15,
    OptIn                     = 16,
    OptResult                 = 17,
    OptInfo                   = 18,
    SendWinner                = 19,
};

local LAST_UNCOMPRESSED_OPCODE = Opcodes.Hello;
local MAX_UNCOMPRESSED_SIZE = 20;

local COMM_DEBUG_SHOW_MESSAGES = false;
local COMM_DEBUG_CANCEL_BYPASS = false;

local function ThrottlingError()
    LootReserve:ShowError("There was an error when reading session host's communications.|n|nIf both your and the host's addons are up to date, then this is likely due to Blizzard's excessive addon communication throttling which results in some messages outright not being delivered.|n|nWait a few seconds and click \"Search For Host\" in LootReserve client window's settings menu to request up to date information from the host.");
end

function LootReserve.Comm:SendCommMessage(channel, target, opcode, ...)
    if COMM_DEBUG_SHOW_MESSAGES then
        local opKey;
        for k, v in pairs(Opcodes) do
            if v == opcode then
                opKey = k;
                break;
            end
        end
        LootReserve:debug("Sending", channel, target, opKey or opcode, ...);
    end
    
    local message = "";
    for _, part in ipairs({ ... }) do
        if type(part) == "boolean" then
            message = message .. tostring(part and 1 or 0) .. "|";
        else
            message = message .. tostring(part) .. "|";
        end
    end

    if opcode > LAST_UNCOMPRESSED_OPCODE then
        local length = #message;
        if length > MAX_UNCOMPRESSED_SIZE then
            message = LibDeflate:CompressDeflate(message);
            message = LibDeflate:EncodeForWoWAddonChannel(message);
        else
            length = -length;
        end
        message = length .. "|" .. message;
    end
    
    if not COMM_DEBUG_CANCEL_BYPASS and (channel ~= "WHISPER" or target and LootReserve:IsMe(target)) then
        local length
        local message = message
        if opcode > LAST_UNCOMPRESSED_OPCODE then
            length, message = strsplit("|", message, 2);
            length = tonumber(length);

            if length > 0 then
                message = LibDeflate:DecodeForWoWAddonChannel(message);
                message = message and LibDeflate:DecompressDeflate(message);
            end
        end
        C_Timer.After(0, function() self.Handlers[opcode](LootReserve:Me(), strsplit("|", message)); end);
    end

    message = opcode .. "|" .. message;

    LootReserve:SendCommMessage(self.Prefix, message, channel, target, "ALERT");

    return message;
end

function LootReserve.Comm:StartListening()
    if not self.Listening then
        self.Listening = true;
        LootReserve:RegisterComm(self.Prefix, function(prefix, text, channel, sender)
            if LootReserve.Enabled and prefix == self.Prefix then
                local opcode, message = strsplit("|", text, 2);
                opcode = tonumber(opcode);
                if not opcode or not message then
                    return ThrottlingError();
                end

                local handler = self.Handlers[opcode];
                if handler then
                    local length;
                    if opcode > LAST_UNCOMPRESSED_OPCODE then
                        length, message = strsplit("|", message, 2);
                        length = tonumber(length);
                        if not length or not message then
                            return ThrottlingError();
                        end

                        if length > 0 then
                            message = LibDeflate:DecodeForWoWAddonChannel(message);
                            message = message and LibDeflate:DecompressDeflate(message);
                        end

                        if not message or #message ~= math.abs(length) then
                            return ThrottlingError();
                        end
                    end

                    sender = LootReserve:Player(sender);
                    LootReserve.Server:SetAddonUser(sender, true);
                    
                    if COMM_DEBUG_SHOW_MESSAGES then
                        local opKey;
                        for k, v in pairs(Opcodes) do
                            if v == opcode then
                                opKey = k;
                                break;
                            end
                        end
                        LootReserve:debug("Received", channel, target, opKey or opcode, strsplit("|", message));
                    end
                    if COMM_DEBUG_CANCEL_BYPASS or not LootReserve:IsMe(sender) then
                        handler(sender, strsplit("|", message));
                    end
                end
            end
        end);
    end
end

function LootReserve.Comm:CanWhisper(target)
    return LootReserve.Enabled and LootReserve:IsPlayerOnline(target);
end

function LootReserve.Comm:Broadcast(opcode, ...)
    if not LootReserve.Enabled then return; end

    local message;
    if IsInGroup() then
        message = self:SendCommMessage(IsInRaid() and "RAID" or "PARTY", nil, opcode, ...);
    else
        message = self:SendCommMessage("WHISPER", LootReserve:Me(), opcode, ...);
    end
end
function LootReserve.Comm:Whisper(target, opcode, ...)
    if not self:CanWhisper(target) then return; end
    local message = self:SendCommMessage("WHISPER", target, opcode, ...);
end
function LootReserve.Comm:Send(target, opcode, ...)
    if target then
        self:Whisper(target, opcode, ...);
    else
        self:Broadcast(opcode, ...);
    end
end
function LootReserve.Comm:WhisperServer(opcode, ...)
    if LootReserve.Client.SessionServer then
        self:Whisper(LootReserve.Client.SessionServer, opcode, ...);
    else
        LootReserve:ShowError("Loot reserves aren't active in your raid");
    end
end

-- Version
function LootReserve.Comm:BroadcastVersion()
    LootReserve.Comm:SendVersion();
end
function LootReserve.Comm:SendVersion(target)
    LootReserve.Comm:Send(target, Opcodes.Version,
        LootReserve.Version,
        LootReserve.MinAllowedVersion);
end
LootReserve.Comm.Handlers[Opcodes.Version] = function(sender, version, minAllowedVersion)
    if LootReserve.LatestKnownVersion >= version then return; end
    LootReserve.LatestKnownVersion = version;

    if LootReserve.Version < minAllowedVersion then
        PlaySoundFile("Interface\\Addons\\LootReserve\\Assets\\Sounds\\Shutting Down.wav", "SFX")
        LootReserve:PrintError("You're using an incompatible outdated version of LootReserve. LootReserve will be unable to communicate with other addon users until it is updated. Please update to version |cFFFFD200%s|r or newer to continue using the addon.", version);
        LootReserve:ShowError("You're using an incompatible outdated version of LootReserve.|n|nLootReserve will be unable to communicate with other addon users until it is updated.|n|nPlease update to version |cFFFFD200%s|r or newer to continue using the addon.", version);
        LootReserve.Comm:BroadcastReportIncompatibleVersion();
        LootReserve.Enabled = false;
        LootReserve.Client:StopSession();
        LootReserve.Client:ResetSession();
        LootReserve.Client:UpdateCategories();
        LootReserve.Client:UpdateLootList();
        LootReserve.Client:UpdateReserveStatus();
    elseif LootReserve.Version < version then
        LootReserve:PrintError("You're using an outdated version of LootReserve. It will continue to work, but please update to version |cFFFFD200%s|r or newer.", version);
    end
end

-- ReportIncompatibleVersion
function LootReserve.Comm:BroadcastReportIncompatibleVersion()
    LootReserve.Comm:Broadcast(Opcodes.ReportIncompatibleVersion);
end
LootReserve.Comm.Handlers[Opcodes.ReportIncompatibleVersion] = function(sender)
    LootReserve.Server:SetAddonUser(sender, false);
end

-- Hello
function LootReserve.Comm:BroadcastHello()
    LootReserve.Comm:Broadcast(Opcodes.Hello);
    LootReserve.Comm:BroadcastVersion();
end
LootReserve.Comm.Handlers[Opcodes.Hello] = function(sender)
    if not LootReserve:IsMe(sender) then
        LootReserve.Comm:SendVersion(sender);
        if LootReserve.Server.CurrentSession and LootReserve.Server:CanBeServer() then
            LootReserve.Comm:SendSessionInfo(sender, true);
        end
    end
    
    if LootReserve.Server.RequestedRoll and not LootReserve.Server.RequestedRoll.RaidRoll and LootReserve.Server:CanRoll(sender) then
        local players = { sender };
        if not LootReserve.Server.RequestedRoll.Custom then
            table.wipe(players);
            for _, roll in ipairs(LootReserve.Server.RequestedRoll.Players[sender] or { }) do
                if roll == 0 then
                    table.insert(players, sender);
                end
            end
        end
        local Roll = LootReserve.Server.RequestedRoll
        LootReserve.Comm:SendRequestRoll(sender, Roll.Item, players, Roll.Custom, Roll.Duration, Roll.MaxDuration, Roll.Phases or { }, Roll.Tiered and true or nil);
    end
end

-- SessionInfo
function LootReserve.Comm:BroadcastSessionInfo(starting)
    LootReserve:NotifyListeners("RESERVES");
    local session = LootReserve.Server.CurrentSession;
    if session.Settings.Blind then
        for player in pairs(session.Members) do
            if LootReserve:IsPlayerOnline(player) then
                LootReserve.Comm:SendSessionInfo(player, starting);
            end
        end
    else
        LootReserve.Comm:SendSessionInfo(nil, starting);
    end
end
function LootReserve.Comm:SendSessionInfo(target, starting)
    local session = LootReserve.Server.CurrentSession;
    if not session then return; end

    target = target and LootReserve:Player(target);
    local realTarget = target
    if target and LootReserve:IsMe(target) and LootReserve.Client.Masquerade then
        realTarget = target
        target     = LootReserve.Client.Masquerade
    end
    if target and not session.Members[target] then return; end

    local membersInfo = "";
    local refPlayers = { };
    for player, member in pairs(session.Members) do
        if not target or LootReserve:IsSamePlayer(player, target) then
            membersInfo = membersInfo .. (#membersInfo > 0 and ";" or "") .. format("%s=%s,%d", player, session.Settings.Lock and member.Locked and "#" or member.ReservesLeft, session.Settings.MaxReservesPerPlayer + member.ReservesDelta);
            table.insert(refPlayers, player);
        end
    end

    local optInfo = "";
    local refPlayers = { };
    for player, member in pairs(session.Members) do
        if not target or LootReserve:IsSamePlayer(player, target) then
            optInfo = optInfo .. (#optInfo > 0 and ";" or "") .. format("%s=%s", player, strjoin(",", member.OptedOut and "1" or "0"));
        end
    end

    local refPlayerToIndex = { };
    for index, player in ipairs(refPlayers) do
        refPlayerToIndex[player] = index;
    end

    local itemReserves = "";
    for itemID, reserve in pairs(session.ItemReserves) do
        if session.Settings.Blind and target then
            if LootReserve:Contains(reserve.Players, target) then
                local _, myReserves = LootReserve:GetReservesData(reserve.Players, target);
                itemReserves = itemReserves .. (#itemReserves > 0 and ";" or "") .. format("%d=%s", itemID, strjoin(",", unpack(LootReserve:RepeatedTable(refPlayerToIndex[target] or target, myReserves))));
            end
        else
            local players = { };
            for _, player in ipairs(reserve.Players) do
                table.insert(players, refPlayerToIndex[player] or player);
            end
            itemReserves = itemReserves .. (#itemReserves > 0 and ";" or "") .. format("%d=%s", itemID, strjoin(",", unpack(players)));
        end
    end

    local itemConditions = "";
    for itemID, conditions in pairs(session.ItemConditions) do
        local packed = LootReserve.ItemConditions:Pack(conditions);
        itemConditions = itemConditions .. (#itemConditions > 0 and ";" or "") .. format("%d=%s", itemID, packed);
    end

    local lootCategories = "";
    for i, category in ipairs(session.Settings.LootCategories) do
        lootCategories = format("%s%s%s", lootCategories, i == 1 and "" or ";", category);
    end

    LootReserve.Comm:Send(realTarget, Opcodes.SessionInfo,
        starting == true,
        session.StartTime or 0,
        session.AcceptingReserves and true or false, -- In case it's nil
        membersInfo,
        lootCategories,
        format("%.2f", session.Duration),
        session.Settings.Duration,
        itemReserves,
        itemConditions,
        session.Settings.Equip,
        session.Settings.Blind,
        session.Settings.Multireserve or 1,
        optInfo);
end
LootReserve.Comm.Handlers[Opcodes.SessionInfo] = function(sender, starting, startTime, acceptingReserves, membersInfo, lootCategories, duration, maxDuration, itemReserves, itemConditions, equip, blind, multireserve, optInfo)
    starting = tonumber(starting) == 1;
    startTime = tonumber(startTime);
    acceptingReserves = tonumber(acceptingReserves) == 1;
    duration = tonumber(duration);
    maxDuration = tonumber(maxDuration);
    equip = tonumber(equip) == 1;
    blind = tonumber(blind) == 1;
    multireserve = tonumber(multireserve);
    multireserve = math.max(1, multireserve);

    if LootReserve.Client.SessionServer and LootReserve.Client.SessionServer ~= sender and LootReserve.Client.StartTime > startTime then
        LootReserve:ShowError("%s is attempting to broadcast their older loot reserve session, but you're already connected to %s.|n|nPlease tell %s that they need to reset their session.", LootReserve:ColoredPlayer(sender), LootReserve:ColoredPlayer(LootReserve.Client.SessionServer), LootReserve:ColoredPlayer(sender));
        return;
    end
    
    if #lootCategories > 0 then
        lootCategories = { strsplit(";", lootCategories) };
    else
        lootCategories = { };
    end
    for i, category in ipairs(lootCategories) do
        lootCategories[i] = tonumber(category);
    end

    LootReserve.Client:StartSession(sender, starting, startTime, acceptingReserves, lootCategories, duration, maxDuration, equip, blind, multireserve);

    LootReserve.Client.RemainingReserves = 0;
    LootReserve.Client.MaxReserves       = 0;
    local refPlayers = { };
    if #membersInfo > 0 then
        membersInfo = { strsplit(";", membersInfo) };
        for _, infoStr in ipairs(membersInfo) do
            local player, info = strsplit("=", infoStr, 2);
            table.insert(refPlayers, player);
            if LootReserve:IsSamePlayer(LootReserve.Client.Masquerade or LootReserve:Me(), player) then
                local remainingReserves, maxReserves = strsplit(",", info);
                LootReserve.Client.RemainingReserves = tonumber(remainingReserves) or 0;
                LootReserve.Client.MaxReserves = tonumber(maxReserves) or 0;
                LootReserve.Client.Locked = remainingReserves == "#";
            end
        end
    end
    
    if #optInfo > 0 then
        optInfo = { strsplit(";", optInfo) };
        for _, infoStr in ipairs(optInfo) do
            local player, info = strsplit("=", infoStr, 2);
            table.insert(refPlayers, player);
            if LootReserve:IsSamePlayer(LootReserve.Client.Masquerade or LootReserve:Me(), player) then
                local optOut = strsplit(",", info);
                LootReserve.Client.OptedOut = optOut == "1" or nil;
            end
        end
    end

    LootReserve.Client.ItemReserves = { };
    if #itemReserves > 0 then
        itemReserves = { strsplit(";", itemReserves) };
        for _, reserves in ipairs(itemReserves) do
            local itemID, playerRefs = strsplit("=", reserves, 2);
            local players;
            if #playerRefs > 0 then
                players = { };
                for _, ref in ipairs({ strsplit(",", playerRefs) }) do
                    table.insert(players, tonumber(ref) and refPlayers[tonumber(ref)] or ref);
                end
            end
            LootReserve.Client.ItemReserves[tonumber(itemID)] = players;
        end
    end

    LootReserve.Client.ItemConditions = { };
    if #itemConditions > 0 then
        itemConditions = { strsplit(";", itemConditions) };
        for _, conditions in ipairs(itemConditions) do
            local itemID, packed = strsplit("=", conditions, 2);
            LootReserve.Client.ItemConditions[tonumber(itemID)] = LootReserve.ItemConditions:Unpack(packed);
        end
    end

    LootReserve.Client:UpdateCategories();
    LootReserve.Client:UpdateLootList();
    if LootReserve.Client.SkipOpen then
        LootReserve.Client.SkipOpen = false;
    else
        LootReserve.Client.Window:PendOpen();
    end
end

-- SessionStop
function LootReserve.Comm:SendSessionStop()
    LootReserve.Comm:Broadcast(Opcodes.SessionStop);
end
LootReserve.Comm.Handlers[Opcodes.SessionStop] = function(sender)
    if LootReserve.Client.SessionServer == sender then
        LootReserve.Client:StopSession();
        LootReserve.Client:UpdateReserveStatus();
    end
end

-- SessionReset
function LootReserve.Comm:SendSessionReset()
    LootReserve.Comm:Broadcast(Opcodes.SessionReset);
end
LootReserve.Comm.Handlers[Opcodes.SessionReset] = function(sender)
    if LootReserve.Client.SessionServer == sender then
        LootReserve.Client:ResetSession();
        LootReserve.Client:UpdateCategories();
        LootReserve.Client:UpdateLootList();
    end
end
function LootReserve.Comm:SendOptInfo(target, out)
    local session = LootReserve.Server.CurrentSession;
    if not session then return; end

    target = target and LootReserve:Player(target);
    if target and not session.Members[target] then return; end

    LootReserve.Comm:Send(target, Opcodes.OptInfo, out == true);
end
LootReserve.Comm.Handlers[Opcodes.OptInfo] = function(sender, out)
    out = tonumber(out) == 1;

    if LootReserve.Client.SessionServer and LootReserve.Client.SessionServer ~= sender and LootReserve.Client.StartTime > startTime then
        LootReserve:ShowError("%s is attempting to broadcast their older loot reserve session, but you're already connected to %s.|n|nPlease tell %s that they need to reset their session.", LootReserve:ColoredPlayer(sender), LootReserve:ColoredPlayer(LootReserve.Client.SessionServer), LootReserve:ColoredPlayer(sender));
        return;
    end

    LootReserve.Client.OptedOut = out;

    LootReserve.Client:UpdateReserveStatus();
    if LootReserve.Client.OptedOut then
        if not LootReserve.Client.Masquerade then
            LootReserve.Client.Window:Hide();
        end
    end
    LootReserve.Client.Window:PendOpen();
end

-- Opt Out
function LootReserve.Comm:SendOptOut()
    LootReserve.Comm:WhisperServer(Opcodes.OptOut);
end
LootReserve.Comm.Handlers[Opcodes.OptOut] = function(sender)
    if LootReserve.Server.CurrentSession then
        LootReserve.Server:Opt(sender, true);
    end
end

-- Opt In
function LootReserve.Comm:SendOptIn()
    LootReserve.Comm:WhisperServer(Opcodes.OptIn);
end
LootReserve.Comm.Handlers[Opcodes.OptIn] = function(sender)
    if LootReserve.Server.CurrentSession then
        LootReserve.Server:Opt(sender, nil);
    end
end

-- OptResult
function LootReserve.Comm:SendOptResult(target, result, forced)
    LootReserve.Comm:Whisper(target, Opcodes.OptResult,
        result,
        forced);
end
LootReserve.Comm.Handlers[Opcodes.OptResult] = function(sender, result, forced)
    result = tonumber(result);
    forced = tonumber(forced) == 1;

    if LootReserve.Client.SessionServer == sender then

        local text = LootReserve.Constants.OptResultText[result];
        if not text or #text > 0 then
            LootReserve:ShowError("Failed to opt out/in:|n%s", text or "Unknown error");
        end

        if forced then
            local categories = LootReserve:GetCategoriesText(LootReserve.Client.LootCategories);
            local msg1 = format("%s has opted you %s using your %d%s reserve%s%s.",
                LootReserve:ColoredPlayer(sender),
                result and "out of" or "into",
                LootReserve.Client.ReservesLeft,
                LootReserve.Client:GetMaxReserves() == 0 and "" or " remaining",
                LootReserve.Client.ReservesLeft == 1 and "" or "s",
                categories ~= "" and format(" for %s", categories) or "");
            local msg2 = format("You can opt back %s with  !opt %s.",
                result and "in" or "out",
                result and "in" or "out");
            LootReserve:PrintError(msg1 .. " " .. msg2)
            LootReserve:ShowError(msg1 .. "|n" .. msg2)
        else
        
        end
        LootReserve.Client:SetOptPending(false);
        LootReserve.Client:UpdateReserveStatus();
    end
end

-- ReserveItem
function LootReserve.Comm:SendReserveItem(itemID)
    LootReserve.Comm:WhisperServer(Opcodes.ReserveItem, itemID);
end
LootReserve.Comm.Handlers[Opcodes.ReserveItem] = function(sender, itemID)
    itemID = tonumber(itemID);

    if LootReserve.Server.CurrentSession and itemID then
        LootReserve.ItemCache(itemID):OnCache(function()
            LootReserve.Server:Reserve(sender, itemID);
        end);
    end
end

-- ReserveResult
function LootReserve.Comm:SendReserveResult(target, itemID, result, remainingReserves, forced)
    LootReserve.Comm:Whisper(target, Opcodes.ReserveResult,
        itemID,
        result,
        remainingReserves,
        forced);
end
LootReserve.Comm.Handlers[Opcodes.ReserveResult] = function(sender, itemID, result, remainingReserves, forced)
    itemID = tonumber(itemID);
    result = tonumber(result);
    local locked = remainingReserves == "#";
    remainingReserves = tonumber(remainingReserves) or 0;
    forced = tonumber(forced) == 1;

    if LootReserve.Client.SessionServer == sender then
        LootReserve.Client.RemainingReserves = remainingReserves;
        LootReserve.Client.Locked = locked;
        if result == LootReserve.Constants.ReserveResult.Locked then
            LootReserve.Client.Locked = true;
        end

        local text = LootReserve.Constants.ReserveResultText[result];
        if not text or #text > 0 then
            LootReserve:ShowError("Failed to reserve:|n%s", text or "Unknown error");
        end
        if forced then
            LootReserve.ItemCache:Item(itemID):OnCache(function(item)
                local link = item:GetLink();
                LootReserve:PrintError("%s has reserved an item for you: %s", LootReserve:ColoredPlayer(sender), link);
                LootReserve:ShowError("%s has reserved an item for you:|n%s", LootReserve:ColoredPlayer(sender), link);
            end);
        end

        for _, rewardID in ipairs(LootReserve.Data:GetTokenRewards(itemID) or {}) do
            LootReserve.Client:SetItemPending(rewardID, false);
        end
        LootReserve.Client:SetItemPending(itemID, false);
        LootReserve.Client:UpdateReserveStatus();
        
        -- opting back in is implied
        LootReserve.Comm.Handlers[Opcodes.OptInfo](sender, false);
        
        LootReserve.Client.Window:PendOpen();
    end
end

-- ReserveInfo
function LootReserve.Comm:BroadcastReserveInfo(itemID, players)
    LootReserve.Comm:SendReserveInfo(nil, itemID, players);
end
function LootReserve.Comm:SendReserveInfo(target, itemID, players)
    LootReserve.Comm:Send(target, Opcodes.ReserveInfo,
        itemID,
        strjoin(",", unpack(players)));
end
LootReserve.Comm.Handlers[Opcodes.ReserveInfo] = function(sender, itemID, players)
    itemID = tonumber(itemID);

    if LootReserve.Client.SessionServer == sender then
        local wasReserver = LootReserve.Client:IsItemReservedByMe(itemID, true);

        if #players > 0 then
            players = { strsplit(",", players) };
        else
            players = { };
        end

        local previousReserves = LootReserve.Client.ItemReserves[itemID];
        local _, myOldReserves, oldReservers, oldRolls = LootReserve:GetReservesData(previousReserves or { }, LootReserve:Me());
        local _, myNewReserves, newReservers, newRolls = LootReserve:GetReservesData(players, LootReserve:Me());
        local isUpdate = oldRolls ~= newRolls;

        LootReserve.Client.ItemReserves[itemID] = players;

        if LootReserve.Client.SelectedCategory and LootReserve.Client.SelectedCategory.Reserves then
            LootReserve.Client:UpdateLootList();
        else
            LootReserve.Client:UpdateReserveStatus();
        end
        if not LootReserve.Client.Blind then
            LootReserve.Client:FlashCategory("Reserves", "all");
        end
        local isReserver = LootReserve.Client:IsItemReservedByMe(itemID, true);
        if wasReserver or isReserver then
            local isViewingMyReserves = LootReserve.Client.SelectedCategory and LootReserve.Client.SelectedCategory.Reserves == "my";
            LootReserve.Client:FlashCategory("Reserves", "my", wasReserver and isReserver and myOldReserves == myNewReserves and oldRolls ~= newRolls and not isViewingMyReserves);
        end
        if wasReserver and isReserver and myOldReserves == myNewReserves and oldRolls ~= newRolls then
            PlaySound(oldRolls < newRolls and SOUNDKIT.ALARM_CLOCK_WARNING_3 or SOUNDKIT.ALARM_CLOCK_WARNING_2);
            LootReserve.ItemCache:Item(itemID):OnCache(function(item)
                LootReserve:PrintMessage(LootReserve:GetReservesStringColored(false, players, LootReserve:Me(), isUpdate, item:GetLink()));
            end);
        end
    end
end

-- CancelReserve
function LootReserve.Comm:SendCancelReserve(itemID)
    LootReserve.Comm:WhisperServer(Opcodes.CancelReserve, itemID);
end
LootReserve.Comm.Handlers[Opcodes.CancelReserve] = function(sender, itemID)
    itemID = tonumber(itemID);

    if LootReserve.Server.CurrentSession then
        LootReserve.Server:CancelReserve(sender, itemID);
    end
end

-- CancelReserveResult
function LootReserve.Comm:SendCancelReserveResult(target, itemID, result, remainingReserves, count, quiet)
    LootReserve.Comm:Whisper(target, Opcodes.CancelReserveResult,
        itemID,
        result,
        remainingReserves,
        count,
        quiet);
end
LootReserve.Comm.Handlers[Opcodes.CancelReserveResult] = function(sender, itemID, result, remainingReserves, count, quiet)
    itemID = tonumber(itemID);
    result = tonumber(result);
    local locked = remainingReserves == "#";
    remainingReserves = tonumber(remainingReserves) or 0;
    count = tonumber(count);
    quiet = tonumber(quiet) == 1;

    if LootReserve.Client.SessionServer == sender then
        LootReserve.Client.RemainingReserves = remainingReserves;
        LootReserve.Client.Locked = locked;
        if result == LootReserve.Constants.CancelReserveResult.Forced then
            LootReserve.ItemCache:Item(itemID):OnCache(function(item)
                local link = item:GetLink();
                if quiet then
                    LootReserve:PrintError("%s removed your reserve for %s%s due to winning an item.", LootReserve:ColoredPlayer(sender), link, count > 1 and format(" x%d", count) or "");
                else
                    LootReserve:ShowError("%s removed your reserve for %s%s", LootReserve:ColoredPlayer(sender), link, count > 1 and format(" x%d", count) or "");
                    LootReserve:PrintError("%s removed your reserve for %s%s", LootReserve:ColoredPlayer(sender), link, count > 1 and format(" x%d", count) or "");
                end
            end);
        elseif result == LootReserve.Constants.CancelReserveResult.Locked then
            LootReserve.Client.Locked = true;
        end

        local text = LootReserve.Constants.CancelReserveResultText[result];
        if not text or #text > 0 then
            LootReserve:ShowError("Failed to cancel reserve:|n%s", text or "Unknown error");
        end

        for _, rewardID in ipairs(LootReserve.Data:GetTokenRewards(itemID) or {}) do
            LootReserve.Client:SetItemPending(rewardID, false);
        end
        LootReserve.Client:SetItemPending(itemID, false);
        if LootReserve.Client.SelectedCategory and LootReserve.Client.SelectedCategory.Reserves then
            LootReserve.Client:UpdateLootList();
        else
            LootReserve.Client:UpdateReserveStatus();
        end
        
        -- opting back in is implied
        LootReserve.Comm.Handlers[Opcodes.OptInfo](sender, false);
        
        LootReserve.Client.Window:PendOpen();
    end
end

-- RequestRoll
function LootReserve.Comm:BroadcastRequestRoll(item, players, custom, duration, maxDuration, phases, tiered)
    LootReserve.Comm:SendRequestRoll(nil, item, players, custom, duration, maxDuration, phases or { }, tiered);
end
function LootReserve.Comm:SendRequestRoll(target, item, players, custom, duration, maxDuration, phases, tiered)
    LootReserve.Comm:Send(target, Opcodes.RequestRoll,
        format("%d,%d", item:GetID(), item:GetSuffix() or 0),
        strjoin(",", unpack(players)),
        custom == true,
        format("%.2f", duration or 0),
        maxDuration or 0,
        tiered and strjoin(",", unpack(phases or { })) or (phases or { })[1],
        LootReserve.Server.Settings.AcceptRollsAfterTimerEnded,
        tiered);
end
LootReserve.Comm.Handlers[Opcodes.RequestRoll] = function(sender, item, players, custom, duration, maxDuration, phases, acceptRollsAfterTimerEnded, tiered)
    local id, suffix = strsplit(",", item);
    item = LootReserve.ItemCache:Item(tonumber(id), tonumber(suffix));
    custom = tonumber(custom) == 1;
    duration = tonumber(duration);
    maxDuration = tonumber(maxDuration);
    phases = phases and #phases > 0 and phases or "";
    acceptRollsAfterTimerEnded = tonumber(acceptRollsAfterTimerEnded) == 1;
    tiered = tonumber(tiered) == 1;
    
    
    if LootReserve.Client.SessionServer == sender or custom then
        if #players > 0 then
            players = { strsplit(",", players) };
        else
            players = { };
        end
        if #phases > 0 then
            phases = { strsplit(",", phases) };
        else
            phases = { };
        end
        LootReserve.Client:RollRequested(sender, item, players, custom, duration, maxDuration, phases, acceptRollsAfterTimerEnded, tiered);
    end
end

-- PassRoll
function LootReserve.Comm:SendPassRoll(item)
    LootReserve.Comm:Whisper(LootReserve.Client.RollRequest.Sender, Opcodes.PassRoll, format("%d,%s", item:GetID(), item:GetSuffix() or 0));
end
LootReserve.Comm.Handlers[Opcodes.PassRoll] = function(sender, item)
    item = LootReserve.ItemCache:Item(strsplit(",", item));
    LootReserve.Server:PassRoll(sender, item);
end

-- DeletedRoll
function LootReserve.Comm:SendDeletedRoll(player, item, roll, phase)
    LootReserve.Comm:Whisper(player, Opcodes.DeletedRoll,
        format("%d,%s", item:GetID(), item:GetSuffix() or 0), roll, phase);
end
LootReserve.Comm.Handlers[Opcodes.DeletedRoll] = function(sender, item, roll, phase)
    item = LootReserve.ItemCache:Item(strsplit(",", item));
    roll = tonumber(roll);

    item:OnCache(function()
        local link = item:GetLink();
        LootReserve:ShowError ("Your %sroll%s on %s was deleted", phase and #phase > 0 and format("%s ", phase) or "", roll and format(" of %d", roll) or "", link);
        LootReserve:PrintError("Your %sroll%s on %s was deleted", phase and #phase > 0 and format("%s ", phase) or "", roll and format(" of %d", roll) or "", link);
    end);
end


-- SendWinner
function LootReserve.Comm:BroadcastWinner(...)
    LootReserve.Comm:SendWinner(nil, ...);
end
function LootReserve.Comm:SendWinner(target, item, winners, losers, roll, custom, phase, raidRoll)
    LootReserve.Comm:Send(target, Opcodes.SendWinner,
        format("%d,%s", item:GetID(), item:GetSuffix() or 0),
        strjoin(",", unpack(winners)),
        strjoin(",", unpack(losers)),
        roll or "",
        custom == true,
        phase or "",
        raidRoll == true);
end
LootReserve.Comm.Handlers[Opcodes.SendWinner] = function(sender, item, winners, losers, roll, custom, phase, raidRoll)
    item     = LootReserve.ItemCache:Item(strsplit(",", item));
    roll     = tonumber(roll);
    custom   = tonumber(custom) == 1;
    phase    = phase and #phase > 0 and phase or nil;
    raidRoll = tonumber(raidRoll) == 1;

    if LootReserve.Client.SessionServer == sender or custom then
        if #winners > 0 then
            winners = { strsplit(",", winners) };
        else
            winners = { };
        end
        if #losers > 0 then
            losers = { strsplit(",", losers) };
        else
            losers = { };
        end
        if LootReserve:Contains(winners, LootReserve:Me()) then
            if LootReserve.Client:IsFavorite(item:GetID()) then
                StaticPopup_Show("LOOTRESERVE_PROMPT_REMOVE_FAVORITE", item:GetLink(), nil, {item = item});
            end
            if LootReserve.Client.Settings.RollRequestWinnerReaction then
                item:OnCache(function()
                    local race, sex = select(3, LootReserve:UnitRace(LootReserve:Me())), LootReserve:UnitSex(LootReserve:Me());
                    local soundTable = custom and LootReserve.Constants.Sounds.Congratulate or LootReserve.Constants.Sounds.Cheer;
                    if race and sex and soundTable[race] and soundTable[race][sex] then
                        PlaySound(soundTable[race][sex]);
                    end
                    PlaySound(LootReserve.Constants.Sounds.LevelUp);
                    
                    LootReserve:PrintMessage("Congratulations! %s has awarded you %s%s%s",
                        LootReserve:ColoredPlayer(sender),
                        item:GetLink(),
                        raidRoll and " via raid-roll" or custom and phase and format(" for %s", phase or "") or "",
                        roll and not raidRoll and format(" with a roll of %d", roll) or ""
                    );
                end);
            end
        end
        if LootReserve.Client.Settings.RollRequestLoserReaction and LootReserve:Contains(losers, LootReserve:Me()) then
            item:OnCache(function()
                local race, sex = select(3, LootReserve:UnitRace(LootReserve:Me())), LootReserve:UnitSex(LootReserve:Me());
                local soundTable = LootReserve.Constants.Sounds.Cry;
                if race and sex and soundTable[race] and soundTable[race][sex] then
                    PlaySound(soundTable[race][sex]);
                end
                
                LootReserve:PrintMessage("You have lost a roll for %s",
                    item:GetLink()
                );
            end);
        end
    end
end
