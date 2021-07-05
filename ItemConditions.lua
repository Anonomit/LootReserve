LootReserve = LootReserve or { };
LootReserve.ItemConditions = LootReserve.ItemConditions or { };

local DefaultConditions =
{
    Hidden    = nil,
    Custom    = nil,
    Faction   = nil,
    ClassMask = nil,
    Limit     = nil,
};

function LootReserve.ItemConditions:Get(item, server)
    if server and LootReserve.Server.CurrentSession then
        return LootReserve.Server.CurrentSession.ItemConditions[item] or LootReserve.Data.ItemConditions[item];
    elseif server then
        return LootReserve.Server:GetNewSessionItemConditions()[item] or LootReserve.Data.ItemConditions[item];
    else
        return LootReserve.Client.ItemConditions[item] or LootReserve.Data.ItemConditions[item];
    end
end

function LootReserve.ItemConditions:Make(item, server)
    if server and LootReserve.Server.CurrentSession then
        LootReserve:ShowError("Cannot edit loot during an active session");
        return nil;
    elseif server then
        local container = LootReserve.Server:GetNewSessionItemConditions();
        local conditions = container[item];
        if not conditions then
            conditions = LootReserve:Deepcopy(LootReserve.Data.ItemConditions[item]);
            if not conditions then
                conditions = LootReserve:Deepcopy(DefaultConditions);
            end
            container[item] = conditions;
        end
        return conditions;
    else
        LootReserve:ShowError("Cannot edit loot on client");
        return nil;
    end
end

function LootReserve.ItemConditions:Save(item, server)
    if server and LootReserve.Server.CurrentSession then
        LootReserve:ShowError("Cannot edit loot during an active session");
    elseif server then
        local container = LootReserve.Server:GetNewSessionItemConditions();
        local conditions = container[item];
        if conditions then
            -- Coerce conditions
            if conditions.ClassMask == 0 then
                conditions.ClassMask = nil;
            end
            if conditions.Hidden == false then
                conditions.Hidden = nil;
            end
            if conditions.Custom == false then
                conditions.Custom = nil;
            end
            if conditions.Limit and conditions.Limit <= 0 then
                conditions.Limit = nil;
            end
        end

        -- If conditions are no different from the default - delete the table
        if conditions then
            local different = false;
            local default = LootReserve.Data.ItemConditions[item];
            if default then
                for k, v in pairs(conditions) do
                    if v ~= default[k] then
                        different = true;
                        break;
                    end
                end
                for k, v in pairs(default) do
                    if v ~= conditions[k] then
                        different = true;
                        break;
                    end
                end
            else
                if next(conditions) then
                    different = true;
                end
            end

            if not different then
                conditions = nil;
                container[item] = nil;
            end
        end

        LootReserve.Server.LootEdit:UpdateLootList();
        LootReserve.Server.Import:SessionSettingsUpdated();
    else
        LootReserve:ShowError("Cannot edit loot on client");
    end
end

function LootReserve.ItemConditions:Delete(item, server)
    if server and LootReserve.Server.CurrentSession then
        LootReserve:ShowError("Cannot edit loot during an active session");
    elseif server then
        LootReserve.Server:GetNewSessionItemConditions()[item] = nil;

        LootReserve.Server.LootEdit:UpdateLootList();
        LootReserve.Server.Import:SessionSettingsUpdated();
    else
        LootReserve:ShowError("Cannot edit loot on client");
    end
end

function LootReserve.ItemConditions:Clear(category, server)
    if server and LootReserve.Server.CurrentSession then
        LootReserve:ShowError("Cannot edit loot during an active session");
    elseif server then
        table.wipe(LootReserve.Server:GetNewSessionItemConditions());

        LootReserve.Server.LootEdit:UpdateLootList();
        LootReserve.Server.Import:SessionSettingsUpdated();
    else
        LootReserve:ShowError("Cannot edit loot on client");
    end
end

function LootReserve.ItemConditions:HasCustom(server)
    local container;
    if server and LootReserve.Server.CurrentSession then
        container = LootReserve.Server.CurrentSession.ItemConditions
    elseif server then
        container = LootReserve.Server:GetNewSessionItemConditions();
    else
        container = LootReserve.Client.ItemConditions;
    end

    if container then
        for item, conditions in pairs(container) do
            if conditions.Custom then
                return true;
            end
        end
    end
    return false;
end

function LootReserve.ItemConditions:TestClassMask(classMask, playerClass)
    return classMask and playerClass and bit.band(classMask, bit.lshift(1, playerClass - 1)) ~= 0;
end

function LootReserve.ItemConditions:TestFaction(faction)
    return faction and UnitFactionGroup("player") == faction;
end

function LootReserve.ItemConditions:TestLimit(limit, item, player, server)
    if limit <= 0 then
        -- Has no limiton the number of reserves
        return true;
    end

    if server then
        local reserves = LootReserve.Server.CurrentSession.ItemReserves[item];
        if not reserves then
            -- Not reserved by anyone yet
            return true;
        end

        return #reserves.Players < limit;
    else
        return #LootReserve.Client:GetItemReservers(item) < limit;
    end
end

function LootReserve.ItemConditions:TestPlayer(player, item, server)
    if not server and not LootReserve.Client.SessionServer then
        -- Show all items until connected to a server
        return true;
    end

    local conditions = self:Get(item, server);
    if conditions then
        if conditions.Hidden then
            return false, LootReserve.Constants.ReserveResult.ItemNotReservable;
        end
        if conditions.ClassMask and not self:TestClassMask(conditions.ClassMask, select(3, LootReserve:UnitClass(player))) then
            return false, LootReserve.Constants.ReserveResult.FailedClass;
        end
        if conditions.Faction and not self:TestFaction(conditions.Faction) then
            return false, LootReserve.Constants.ReserveResult.FailedFaction;
        end
        if conditions.Limit and not self:TestLimit(conditions.Limit, item, player, server) then
            return false, LootReserve.Constants.ReserveResult.FailedLimit;
        end
    end
    return true;
end

function LootReserve.ItemConditions:TestServer(item)
    local conditions = self:Get(item, true);
    if conditions then
        if conditions.Hidden then
            return false;
        end
        if conditions.Faction and not self:TestFaction(conditions.Faction) then
            return false;
        end
    end
    return true;
end

function LootReserve.ItemConditions:IsItemVisibleOnClient(item)
    local canReserve, conditionResult = self:TestPlayer(LootReserve:Me(), item, false);
    return canReserve or conditionResult == LootReserve.Constants.ReserveResult.FailedLimit;
end

function LootReserve.ItemConditions:IsItemReservableOnClient(item)
    local canReserve, conditionResult = self:TestPlayer(LootReserve:Me(), item, false);
    return canReserve;
end

function LootReserve.ItemConditions:Pack(conditions)
    local text = "";
    if conditions.Hidden then
        text = text .. "-";
    elseif conditions.Custom then
        text = text .. "+";
    end
    if conditions.Faction == "Alliance" then
        text = text .. "A";
    elseif conditions.Faction == "Horde" then
        text = text .. "H";
    end
    if conditions.ClassMask and conditions.ClassMask ~= 0 then
        text = text .. "C" .. conditions.ClassMask;
    end
    if conditions.Limit and conditions.Limit ~= 0 then
        text = text .. "L" .. conditions.Limit;
    end
    return text;
end

function LootReserve.ItemConditions:Unpack(text)
    local conditions = LootReserve:Deepcopy(DefaultConditions);

    for i = 1, #text do
        local char = text:sub(i, i);
        if char == "-" then
            conditions.Hidden = true;
        elseif char == "+" then
            conditions.Custom = true;
        elseif char == "A" then
            conditions.Faction = "Alliance";
        elseif char == "H" then
            conditions.Faction = "Horde";
        elseif char == "C" then
            for len = 1, 10 do
                local mask = text:sub(i + 1, i + len);
                if tonumber(mask) then
                    conditions.ClassMask = tonumber(mask);
                else
                    break;
                end
            end
        elseif char == "L" then
            for len = 1, 10 do
                local limit = text:sub(i + 1, i + len);
                if tonumber(limit) then
                    conditions.Limit = tonumber(limit);
                else
                    break;
                end
            end
        end
    end
    return conditions;
end