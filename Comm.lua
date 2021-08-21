local LibDeflate = LibStub:GetLibrary("LibDeflate");

LootReserve = LootReserve or { };
LootReserve.Comm =
{
    Prefix    = "LootReserve",
    Handlers  = { },
    Listening = false,
    Debug     = false,
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
};

local LAST_UNCOMPRESSED_OPCODE = Opcodes.Hello;
local MAX_UNCOMPRESSED_SIZE = 20;

local function ThrottlingError()
    LootReserve:ShowError("There was an error when reading session server's communications.|n|nIf both your and the server's addons are up to date, then this is likely due to Blizzard's excessive addon communication throttling which results in some messages outright not being delivered.|n|nWait a few seconds and click \"Search For Server\" in LootReserve client window's settings menu to request up to date information from the server.");
end

function LootReserve.Comm:SendCommMessage(channel, target, opcode, ...)
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

                    if self.Debug then
                        print("[DEBUG] Received from " .. sender .. ": " .. opcode .. (length and ("||" .. length) or "") .. "||" .. message:gsub("|", "||"));
                    end

                    sender = LootReserve:Player(sender);
                    LootReserve.Server:SetAddonUser(sender, true);
                    handler(sender, strsplit("|", message));
                end
            end
        end);
    end
end

function LootReserve.Comm:CanWhisper(target, opcode)
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

    if self.Debug then
        print("[DEBUG] Raid Broadcast: " .. message:gsub("|", "||"));
    end
end
function LootReserve.Comm:Whisper(target, opcode, ...)
    if not self:CanWhisper(target, opcode) then return; end

    local message = self:SendCommMessage("WHISPER", target, opcode, ...);

    if self.Debug then
        print("[DEBUG] Sent to " .. target .. ": " .. message:gsub("|", "||"));
    end
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
        LootReserve:PrintError("You're using an incompatible outdated version of LootReserve. Please update to version |cFFFFD200%s|r or newer to continue using the addon.", version);
        LootReserve:ShowError("You're using an incompatible outdated version of LootReserve. Please update to version |cFFFFD200%s|r or newer to continue using the addon.", version);
        LootReserve.Comm:BroadcastReportIncompatibleVersion();
        LootReserve.Enabled = false;
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
end
LootReserve.Comm.Handlers[Opcodes.Hello] = function(sender)
    LootReserve.Comm:SendVersion(sender);

    if LootReserve.Server.CurrentSession and LootReserve.Server:CanBeServer() then
        LootReserve.Comm:SendSessionInfo(sender);
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
        LootReserve.Comm:SendRequestRoll(sender, LootReserve.Server.RequestedRoll.Item, players, LootReserve.Server.RequestedRoll.Custom, LootReserve.Server.RequestedRoll.Duration, LootReserve.Server.RequestedRoll.MaxDuration);
    end
end

-- SessionInfo
function LootReserve.Comm:BroadcastSessionInfo(starting)
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
    if target and not session.Members[target] then return; end

    local membersInfo = "";
    local refPlayers = { };
    for player, member in pairs(session.Members) do
        if not target or LootReserve:IsSamePlayer(player, target) then
            membersInfo = membersInfo .. (#membersInfo > 0 and ";" or "") .. format("%s=%s", player, strjoin(",", session.Settings.Lock and member.Locked and "#" or member.ReservesLeft));
            table.insert(refPlayers, player);
        end
    end

    local refPlayerToIndex = { };
    for index, player in ipairs(refPlayers) do
        refPlayerToIndex[player] = index;
    end

    local itemReserves = "";
    for item, reserve in pairs(session.ItemReserves) do
        if session.Settings.Blind and target then
            if LootReserve:Contains(reserve.Players, target) then
                local _, myReserves = LootReserve:GetReservesData(reserve.Players, target);
                itemReserves = itemReserves .. (#itemReserves > 0 and ";" or "") .. format("%d=%s", item, strjoin(",", unpack(LootReserve:RepeatedTable(refPlayerToIndex[target] or target, myReserves))));
            end
        else
            local players = { };
            for _, player in ipairs(reserve.Players) do
                table.insert(players, refPlayerToIndex[player] or player);
            end
            itemReserves = itemReserves .. (#itemReserves > 0 and ";" or "") .. format("%d=%s", item, strjoin(",", unpack(players)));
        end
    end

    local itemConditions = "";
    for item, conditions in pairs(session.ItemConditions) do
        local packed = LootReserve.ItemConditions:Pack(conditions);
        itemConditions = itemConditions .. (#itemConditions > 0 and ";" or "") .. format("%d=%s", item, packed);
    end

    LootReserve.Comm:Send(target, Opcodes.SessionInfo,
        starting == true,
        session.StartTime or 0,
        session.AcceptingReserves,
        membersInfo,
        session.Settings.LootCategory,
        format("%.2f", session.Duration),
        session.Settings.Duration,
        itemReserves,
        itemConditions,
        session.Settings.Equip,
        session.Settings.Blind,
        session.Settings.Multireserve or 1);
end
LootReserve.Comm.Handlers[Opcodes.SessionInfo] = function(sender, starting, startTime, acceptingReserves, membersInfo, lootCategory, duration, maxDuration, itemReserves, itemConditions, equip, blind, multireserve)
    starting = tonumber(starting) == 1;
    startTime = tonumber(startTime);
    acceptingReserves = tonumber(acceptingReserves) == 1;
    lootCategory = tonumber(lootCategory);
    duration = tonumber(duration);
    maxDuration = tonumber(maxDuration);
    equip = tonumber(equip) == 1;
    blind = tonumber(blind) == 1;
    multireserve = tonumber(multireserve);
    if multireserve <= 1 then
        multireserve = nil;
    end

    if LootReserve.Client.SessionServer and LootReserve.Client.SessionServer ~= sender and LootReserve.Client.StartTime > startTime then
        LootReserve:ShowError("%s is attempting to broadcast their older loot reserve session, but you're already connected to %s.|n|nPlease tell %s that they need to reset their session.", LootReserve:ColoredPlayer(sender), LootReserve:ColoredPlayer(LootReserve.Client.SessionServer), LootReserve:ColoredPlayer(sender));
        return;
    end

    LootReserve.Client:StartSession(sender, starting, startTime, acceptingReserves, lootCategory, duration, maxDuration, equip, blind, multireserve);

    LootReserve.Client.RemainingReserves = 0;
    local refPlayers = { };
    if #membersInfo > 0 then
        membersInfo = { strsplit(";", membersInfo) };
        for _, infoStr in ipairs(membersInfo) do
            local player, info = strsplit("=", infoStr, 2);
            table.insert(refPlayers, player);
            if LootReserve:IsMe(player) then
                local remainingReserves = strsplit(",", info);
                LootReserve.Client.RemainingReserves = tonumber(remainingReserves) or 0;
                LootReserve.Client.Locked = remainingReserves == "#";
            end
        end
    end

    LootReserve.Client.ItemReserves = { };
    if #itemReserves > 0 then
        itemReserves = { strsplit(";", itemReserves) };
        for _, reserves in ipairs(itemReserves) do
            local item, playerRefs = strsplit("=", reserves, 2);
            local players;
            if #playerRefs > 0 then
                players = { };
                for _, ref in ipairs({ strsplit(",", playerRefs) }) do
                    table.insert(players, tonumber(ref) and refPlayers[tonumber(ref)] or ref);
                end
            end
            LootReserve.Client.ItemReserves[tonumber(item)] = players;
        end
    end

    LootReserve.Client.ItemConditions = { };
    if #itemConditions > 0 then
        itemConditions = { strsplit(";", itemConditions) };
        for _, conditions in ipairs(itemConditions) do
            local item, packed = strsplit("=", conditions, 2);
            LootReserve.Client.ItemConditions[tonumber(item)] = LootReserve.ItemConditions:Unpack(packed);
        end
    end

    LootReserve.Client:UpdateCategories();
    LootReserve.Client:UpdateLootList();
    if acceptingReserves then
        LootReserve.Client.Window:Show();
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

-- ReserveItem
function LootReserve.Comm:SendReserveItem(item)
    LootReserve.Comm:WhisperServer(Opcodes.ReserveItem,
        item);
end
LootReserve.Comm.Handlers[Opcodes.ReserveItem] = function(sender, item)
    item = tonumber(item);

    if LootReserve.Server.CurrentSession then
        LootReserve.Server:Reserve(sender, item);
    end
end

-- ReserveResult
function LootReserve.Comm:SendReserveResult(target, item, result, remainingReserves)
    LootReserve.Comm:Whisper(target, Opcodes.ReserveResult,
        item,
        result,
        remainingReserves);
end
LootReserve.Comm.Handlers[Opcodes.ReserveResult] = function(sender, item, result, remainingReserves)
    item = tonumber(item);
    result = tonumber(result);
    local locked = remainingReserves == "#";
    remainingReserves = tonumber(remainingReserves) or 0;

    if LootReserve.Client.SessionServer == sender then
        LootReserve.Client.RemainingReserves = remainingReserves;
        LootReserve.Client.Locked = locked;
        if result == LootReserve.Constants.ReserveResult.Locked then
            LootReserve.Client.Locked = true;
        end

        local text = LootReserve.Constants.ReserveResultText[result];
        if not text or #text > 0 then
            LootReserve:ShowError("Failed to reserve the item:|n%s", text or "Unknown error");
        end

        LootReserve.Client:SetItemPending(item, false);
        LootReserve.Client:UpdateReserveStatus();
    end
end

-- ReserveInfo
function LootReserve.Comm:BroadcastReserveInfo(item, players)
    LootReserve.Comm:SendReserveInfo(nil, item, players);
end
function LootReserve.Comm:SendReserveInfo(target, item, players)
    LootReserve.Comm:Send(target, Opcodes.ReserveInfo,
        item,
        strjoin(",", unpack(players)));
end
LootReserve.Comm.Handlers[Opcodes.ReserveInfo] = function(sender, item, players)
    item = tonumber(item);

    if LootReserve.Client.SessionServer == sender then
        local wasReserver = LootReserve.Client:IsItemReservedByMe(item);

        if #players > 0 then
            players = { strsplit(",", players) };
        else
            players = { };
        end

        local previousReserves = LootReserve.Client.ItemReserves[item];
        local _, myOldReserves, oldReservers, oldRolls = LootReserve:GetReservesData(previousReserves or { }, LootReserve:Me());
        local _, myNewReserves, newReservers, newRolls = LootReserve:GetReservesData(players, LootReserve:Me());
        local isUpdate = oldRolls ~= newRolls;

        LootReserve.Client.ItemReserves[item] = players;

        if LootReserve.Client.SelectedCategory and LootReserve.Client.SelectedCategory.Reserves then
            LootReserve.Client:UpdateLootList();
        else
            LootReserve.Client:UpdateReserveStatus();
        end
        if not LootReserve.Client.Blind then
            LootReserve.Client:FlashCategory("Reserves", "all");
        end
        local isReserver = LootReserve.Client:IsItemReservedByMe(item);
        if wasReserver or isReserver then
            local isViewingMyReserves = LootReserve.Client.SelectedCategory and LootReserve.Client.SelectedCategory.Reserves == "my";
            LootReserve.Client:FlashCategory("Reserves", "my", wasReserver == isReserver and not isViewingMyReserves);
        end
        if wasReserver and isReserver and myOldReserves == myNewReserves then
            local function Print()
                local name, link = GetItemInfo(item);
                if name and link then
                    LootReserve:PrintMessage(LootReserve:GetReservesStringColored(false, players, LootReserve:Me(), isUpdate, link));
                else
                    C_Timer.After(0.25, Print);
                end
            end
            Print();
        end
    end
end

-- CancelReserve
function LootReserve.Comm:SendCancelReserve(item)
    LootReserve.Comm:WhisperServer(Opcodes.CancelReserve,
        item);
end
LootReserve.Comm.Handlers[Opcodes.CancelReserve] = function(sender, item)
    item = tonumber(item);

    if LootReserve.Server.CurrentSession then
        LootReserve.Server:CancelReserve(sender, item);
    end
end

-- CancelReserveResult
function LootReserve.Comm:SendCancelReserveResult(target, item, result, remainingReserves)
    LootReserve.Comm:Whisper(target, Opcodes.CancelReserveResult,
        item,
        result,
        remainingReserves);
end
LootReserve.Comm.Handlers[Opcodes.CancelReserveResult] = function(sender, item, result, remainingReserves)
    item = tonumber(item);
    result = tonumber(result);
    local locked = remainingReserves == "#";
    remainingReserves = tonumber(remainingReserves) or 0;

    if LootReserve.Client.SessionServer == sender then
        LootReserve.Client.RemainingReserves = remainingReserves;
        LootReserve.Client.Locked = locked;
        if result == LootReserve.Constants.CancelReserveResult.Forced then
            local function ShowForced()
                local name, link = GetItemInfo(item);
                if name and link then
                    LootReserve:ShowError("%s removed your reserve for item %s", LootReserve:ColoredPlayer(sender), link);
                    LootReserve:PrintError("%s removed your reserve for item %s", LootReserve:ColoredPlayer(sender), link);
                else
                    C_Timer.After(0.25, ShowForced);
                end
            end
            ShowForced();
        elseif result == LootReserve.Constants.CancelReserveResult.Locked then
            LootReserve.Client.Locked = true;
        end

        local text = LootReserve.Constants.CancelReserveResultText[result];
        if not text or #text > 0 then
            LootReserve:ShowError("Failed to cancel reserve of the item:|n%s", text or "Unknown error");
        end

        LootReserve.Client:SetItemPending(item, false);
        if LootReserve.Client.SelectedCategory and LootReserve.Client.SelectedCategory.Reserves then
            LootReserve.Client:UpdateLootList();
        else
            LootReserve.Client:UpdateReserveStatus();
        end
    end
end

-- RequestRoll
function LootReserve.Comm:BroadcastRequestRoll(item, players, custom, duration, maxDuration, phase)
    LootReserve.Comm:SendRequestRoll(nil, item, players, custom, duration, maxDuration, phase);
end
function LootReserve.Comm:SendRequestRoll(target, item, players, custom, duration, maxDuration, phase)
    LootReserve.Comm:Send(target, Opcodes.RequestRoll,
        item,
        strjoin(",", unpack(players)),
        custom == true,
        format("%.2f", duration or 0),
        maxDuration or 0,
        phase or "");
end
LootReserve.Comm.Handlers[Opcodes.RequestRoll] = function(sender, item, players, custom, duration, maxDuration, phase)
    item = tonumber(item);
    custom = tonumber(custom) == 1;
    duration = tonumber(duration);
    maxDuration = tonumber(maxDuration);
    phase = phase and #phase > 0 and phase or nil;

    if LootReserve.Client.SessionServer == sender or custom then
        if #players > 0 then
            players = { strsplit(",", players) };
        else
            players = { };
        end
        LootReserve.Client:RollRequested(sender, item, players, custom, duration, maxDuration, phase);
    end
end

-- PassRoll
function LootReserve.Comm:SendPassRoll(item)
    LootReserve.Comm:Whisper(LootReserve.Client.RollRequest.Sender, Opcodes.PassRoll,
        item);
end
LootReserve.Comm.Handlers[Opcodes.PassRoll] = function(sender, item)
    item = tonumber(item);

    if true--[[LootReserve.Server.CurrentSession]] then
        LootReserve.Server:PassRoll(sender, item);
    end
end

-- DeletedRoll
function LootReserve.Comm:SendDeletedRoll(player, item, roll, phase)
    LootReserve.Comm:Whisper(player, Opcodes.DeletedRoll,
        item, roll, phase);
end
LootReserve.Comm.Handlers[Opcodes.DeletedRoll] = function(sender, item, roll, phase)
    item = tonumber(item);
    roll = tonumber(roll);

    if true--[[LootReserve.Client.SessionServer == sender]] then
        local function ShowDeleted()
            local name, link = GetItemInfo(item);
            if name and link then
                LootReserve:ShowError ("Your %sroll%s on %s was deleted", phase and format("%s ", phase) or "", roll and format(" of %d", roll) or "", link);
                LootReserve:PrintError("Your %sroll%s on %s was deleted", phase and format("%s ", phase) or "", roll and format(" of %d", roll) or "", link);
            else
                C_Timer.After(0.25, ShowDeleted);
            end
        end
        ShowDeleted();
    end
end
