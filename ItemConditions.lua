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

function LootReserve.ItemConditions:Get(itemID, server)
    if server and LootReserve.Server.CurrentSession then
        return LootReserve.Server.CurrentSession.ItemConditions[itemID] or LootReserve.Data.ItemConditions[itemID];
    elseif server then
        return LootReserve.Server:GetNewSessionItemConditions()[itemID] or LootReserve.Data.ItemConditions[itemID];
    else
        return LootReserve.Client.ItemConditions[itemID] or LootReserve.Data.ItemConditions[itemID];
    end
end

function LootReserve.ItemConditions:Make(itemID, server)
    if server and LootReserve.Server.CurrentSession then
        LootReserve:ShowError("Cannot edit loot during an active session");
        return nil;
    elseif server then
        local container = LootReserve.Server:GetNewSessionItemConditions();
        local conditions = container[itemID];
        if not conditions then
            conditions = LootReserve:Deepcopy(LootReserve.Data.ItemConditions[itemID]);
            if not conditions then
                conditions = LootReserve:Deepcopy(DefaultConditions);
            end
            container[itemID] = conditions;
        end
        return conditions;
    else
        LootReserve:ShowError("Cannot edit loot on client");
        return nil;
    end
end

function LootReserve.ItemConditions:Save(itemID, server)
    if server and LootReserve.Server.CurrentSession then
        LootReserve:ShowError("Cannot edit loot during an active session");
    elseif server then
        local container = LootReserve.Server:GetNewSessionItemConditions();
        local conditions = container[itemID];
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
            local default = LootReserve.Data.ItemConditions[itemID];
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
                container[itemID] = nil;
            end
        end

        LootReserve.Server.LootEdit:UpdateLootList();
        LootReserve.Server.Import:SessionSettingsUpdated();
    else
        LootReserve:ShowError("Cannot edit loot on client");
    end
end

function LootReserve.ItemConditions:Delete(itemID, server)
    if server and LootReserve.Server.CurrentSession then
        LootReserve:ShowError("Cannot edit loot during an active session");
    elseif server then
        LootReserve.Server:GetNewSessionItemConditions()[itemID] = nil;

        LootReserve.Server.LootEdit:UpdateLootList();
        LootReserve.Server.Import:SessionSettingsUpdated();
    else
        LootReserve:ShowError("Cannot edit loot on client");
    end
end

function LootReserve.ItemConditions:Clear(server)
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
        for _, conditions in pairs(container) do
            if conditions.Custom then
                return true;
            end
        end
    end
    return false;
end



local UNUSABLE_EQUIPMENT = {};

local armorClasses = {"Miscellaneous", "Cloth", "Leather", "Mail", "Shields", "Plate", "Librams", "Idols", "Totems"};

local usableArmor = {
    WARRIOR = {Leather = true, Mail = true, Plate = true, Shields = true},
    ROGUE   = {Leather = true},
    MAGE    = {},
    PRIEST  = {},
    WARLOCK = {},
    HUNTER  = {Leather = true, Mail = true},
    DRUID   = {Leather = true, Idols = true},
    SHAMAN  = {Leather = true, Mail = true, Shields = true, Totems = true},
    PALADIN = {Leather = true, Mail = true, Plate = true, Shields = true, Librams = true},
};
for _, armorTypes in pairs(usableArmor) do
    armorTypes.Miscellaneous = true;
    armorTypes.Cloth = true;
end
for class in pairs(usableArmor) do
    UNUSABLE_EQUIPMENT[class] = {
        [ARMOR]  = {},
        [WEAPON] = {},
    };
    for _, armorType in ipairs(armorClasses) do
        UNUSABLE_EQUIPMENT[class][ARMOR][armorType] = not usableArmor[class][armorType];
    end
end

local function setClassWeapons(class, ...)
    for _, weapon in ipairs{...} do
        UNUSABLE_EQUIPMENT[class][WEAPON][weapon] = nil;
    end
end

for class in pairs(usableArmor) do
    for _, weapon in ipairs{"Two-Handed Axes", "One-Handed Axes", "Two-Handed Swords", "One-Handed Swords",
                            "Two-Handed Maces", "One-Handed Maces", "Polearms", "Staves", "Daggers",
                            "Fist Weapons", "Bows", "Crossbows", "Guns", "Thrown", "Wands", "Relic"} do
        UNUSABLE_EQUIPMENT[class][WEAPON][weapon] = true;
    end
end

setClassWeapons("DRUID",   "Two-Handed Maces", "One-Handed Maces", "Staves", "Daggers", "Fist Weapons", "Relic");
setClassWeapons("HUNTER",  "Two-Handed Axes", "One-Handed Axes", "Two-Handed Swords", "One-Handed Swords",
                           "Polearms", "Staves", "Daggers", "Fist Weapons", "Bows", 
                           "Crossbows", "Guns", "Thrown");
setClassWeapons("MAGE",    "One-Handed Swords", "Staves", "Daggers", "Wands");
setClassWeapons("PALADIN", "Two-Handed Axes", "One-Handed Axes", "Two-Handed Swords", "One-Handed Swords",
                           "Two-Handed Maces", "One-Handed Maces", "Polearms", "Relic");
setClassWeapons("PRIEST",  "One-Handed Maces", "Staves", "Daggers", "Wands");
setClassWeapons("ROGUE",   "One-Handed Swords", "One-Handed Maces", "Daggers", "Fist Weapons",
                           "Bows", "Crossbows", "Guns", "Thrown");
setClassWeapons("SHAMAN",  "Two-Handed Axes", "One-Handed Axes", "Two-Handed Maces", "One-Handed Maces",
                           "Staves", "Daggers", "Fist Weapons", "Relic");
setClassWeapons("WARLOCK", "One-Handed Swords", "Staves", "Daggers", "Wands");
setClassWeapons("WARRIOR", "Two-Handed Axes", "One-Handed Axes", "Two-Handed Swords", "One-Handed Swords",
                           "Two-Handed Maces", "One-Handed Maces", "Polearms", "Staves", "Daggers", "Fist Weapons", 
                           "Bows", "Crossbows", "Guns", "Thrown");


local function IsItemUsable(itemID, playerClass, playerRace)
    -- If item is Armor or Weapon then fail if class cannot equip it
    local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemID);
    if UNUSABLE_EQUIPMENT[playerClass][itemType] then
        if UNUSABLE_EQUIPMENT[playerClass][itemType][itemSubType] then
           return false; 
        end
    end
    
    -- If item is class-locked or race-locked then make sure this class/race is listed
    if not LootReserve.TooltipScanner then
        LootReserve.TooltipScanner = CreateFrame("GameTooltip", "LootReserveTooltipScanner", UIParent, "GameTooltipTemplate");
        LootReserve.TooltipScanner:Hide();
    end

    if not LootReserve.TooltipScanner.ClassesAllowed then
        LootReserve.TooltipScanner.ClassesAllowed = ITEM_CLASSES_ALLOWED:gsub("%.", "%%."):gsub("%%s", "(.+)");
    end
    if not LootReserve.TooltipScanner.RacesAllowed then
        LootReserve.TooltipScanner.RacesAllowed = ITEM_RACES_ALLOWED:gsub("%.", "%%."):gsub("%%s", "(.+)");
    end

    LootReserve.TooltipScanner:SetOwner(UIParent, "ANCHOR_NONE");
    LootReserve.TooltipScanner:SetHyperlink("item:" .. itemID);
    for i = 1, 50 do
        local line = _G[LootReserve.TooltipScanner:GetName() .. "TextLeft" .. i];
        if line and line:GetText() then
            if line:GetText():match(LootReserve.TooltipScanner.ClassesAllowed) then
                local found = line:GetText():match(LOCALIZED_CLASS_NAMES_MALE[playerClass]) or line:GetText():match(LOCALIZED_CLASS_NAMES_FEMALE[playerClass]);
                LootReserve.TooltipScanner:Hide();
                return not not found;
            elseif line:GetText():match(LootReserve.TooltipScanner.RacesAllowed) then
                local found = line:GetText():match(playerRace);
                LootReserve.TooltipScanner:Hide();
                return not not found;
            end
        end
    end
    
    
    LootReserve.TooltipScanner:Hide();
    return true;
end


function LootReserve.ItemConditions:IsItemUsable(itemID, playerClass, playerRace)
    return IsItemUsable(itemID, playerClass or select(2, LootReserve:UnitClass(LootReserve:Me())), playerRace or LootReserve:UnitRace(LootReserve:Me()));
end

function LootReserve.ItemConditions:TestClassMask(classMask, playerClass)
    return classMask and playerClass and bit.band(classMask, bit.lshift(1, playerClass - 1)) ~= 0;
end

function LootReserve.ItemConditions:TestFaction(faction)
    return faction and UnitFactionGroup("player") == faction;
end

function LootReserve.ItemConditions:TestLimit(limit, itemID, player, server)
    if limit <= 0 then
        -- Has no limiton the number of reserves
        return true;
    end

    if server then
        local reserves = LootReserve.Server.CurrentSession.ItemReserves[itemID];
        if not reserves then
            -- Not reserved by anyone yet
            return true;
        end

        return #reserves.Players < limit;
    else
        return #LootReserve.Client:GetItemReservers(itemID) < limit;
    end
end

function LootReserve.ItemConditions:TestPlayer(player, itemID, server)
    if not server and not LootReserve.Client.SessionServer then
        -- Show all items until connected to a server
        return true;
    end

    local conditions = self:Get(itemID, server);
    local equip
    if server then
        equip = LootReserve.Server.CurrentSession and LootReserve.Server.CurrentSession.Settings.Equip or false;
    else
        equip = LootReserve.Client.Equip;
    end
    if conditions and conditions.Hidden then
        return false, LootReserve.Constants.ReserveResult.ItemNotReservable;
    end
    if conditions and conditions.ClassMask and not self:TestClassMask(conditions.ClassMask, select(3, LootReserve:UnitClass(player))) then
        return false, LootReserve.Constants.ReserveResult.FailedClass;
    end
    if equip and not self:IsItemUsable(itemID) then
        return false, LootReserve.Constants.ReserveResult.FailedUsable;
    end
    if conditions and conditions.Faction and not self:TestFaction(conditions.Faction) then
        return false, LootReserve.Constants.ReserveResult.FailedFaction;
    end
    if conditions and conditions.Limit and not self:TestLimit(conditions.Limit, itemID, player, server) then
        return false, LootReserve.Constants.ReserveResult.FailedLimit;
    end
    return true;
end

function LootReserve.ItemConditions:TestServer(itemID)
    local conditions = self:Get(itemID, true);
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

function LootReserve.ItemConditions:IsItemVisibleOnClient(itemID)
    local canReserve, conditionResult = self:TestPlayer(LootReserve:Me(), itemID, false);
    return canReserve or conditionResult == LootReserve.Constants.ReserveResult.FailedLimit
           or ((conditionResult == LootReserve.Constants.ReserveResult.FailedClass or conditionResult == LootReserve.Constants.ReserveResult.FailedUsable) and (LootReserve.Client.Locked or not LootReserve.Client.AcceptingReserves));
end

function LootReserve.ItemConditions:IsItemReservableOnClient(itemID)
    local canReserve, conditionResult = self:TestPlayer(LootReserve:Me(), itemID, false);
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