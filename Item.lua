LootReserve = LootReserve or { };
LootReserve.Item = { };

local itemMeta = {
    __index = LootReserve.Item,
    __eq    = function(item1, item2) return item1.id == item2.id and item1.suffix == item2.suffix end,
}

local function NewItem(id, suffix, uniqueID, info, searchName, classesAllowed, unique)
    return setmetatable({
        id             = tonumber(id),
        suffix         = tonumber(suffix),
        uniqueID       = tonumber(uniqueID),
        info           = info,
        name           = name,
        link           = link,
        texture        = texture,
        searchName     = searchName,
        classesAllowed = classesAllowed,
        classesAllowed = unique
    }, itemMeta);
end

local function UnpackItem(Item)
    return Item.id, Item.suffix, Item.uniqueID, Item.info, Item.searchName, Item.classesAllowed, Item.unique;
end

setmetatable(LootReserve.Item, {
    __call = function(self, arg1, ...)
        if type(arg1) == "table" then
            return NewItem(UnpackItem(arg1));
        elseif type(arg1) == "string" and arg1:find("item:") then
            local id, suffix, uniqueID = arg1:match("^.-item:(%d-):%d-:%d-:%d-:%d-:%d-:(.-):(.-):");
            return NewItem(id, suffix, uniqueID);
        else
            return NewItem(arg1, unpack{...});
        end
    end
});

function LootReserve.Item:GetID()
    return self.id;
end

function LootReserve.Item:GetSuffix()
    return self.suffix;
end

function LootReserve.Item:GetUniqueID()
    return self.uniqueID;
end

function LootReserve.Item:GetStringData()
    return self:GetID(), self:GetSuffix() or "", self:GetUniqueID() or "";
end


function LootReserve.Item:GetString()
    return format("item:%d::::::%d:%d::::::::::", self:GetStringData());
end

function LootReserve.Item:GetInfo()
    if not self.info then
        local info = {GetItemInfo(self:GetString())};
        -- local name, link, quality, _, _, itemType, itemSubType, _, equipLoc, texture, _, _, _, bindType = unpack(info);
        local name = info[1];
        if name then
            self.info       = info;
            self.searchName = LootReserve:TransformSearchText(name);

            if not LootReserve.TooltipScanner then
                LootReserve.TooltipScanner = CreateFrame("GameTooltip", "LootReserveTooltipScanner", UIParent, "GameTooltipTemplate");
                LootReserve.TooltipScanner:Hide();
            end

            if not LootReserve.TooltipScanner.ClassesAllowed then
                LootReserve.TooltipScanner.ClassesAllowed = format("^%s$", ITEM_CLASSES_ALLOWED:gsub("%%s", "(.+)"));
            end
            if not LootReserve.TooltipScanner.Unique then
                LootReserve.TooltipScanner.Unique = format("^(%s)$", ITEM_UNIQUE);
            end
            if not LootReserve.TooltipScanner.StartsQuest then
                LootReserve.TooltipScanner.StartsQuest = format("^(%s)$", ITEM_STARTS_QUEST);
            end

            LootReserve.TooltipScanner:SetOwner(UIParent, "ANCHOR_NONE");
            LootReserve.TooltipScanner:SetHyperlink("item:" .. self:GetID());
            for i = 1, LootReserve.TooltipScanner:NumLines() do
                local line = _G[LootReserve.TooltipScanner:GetName() .. "TextLeft" .. i];
                if line and line:GetText() then
                    if line:GetText():match(LootReserve.TooltipScanner.ClassesAllowed) then
                        self.classesAllowed = line:GetText():match(LootReserve.TooltipScanner.ClassesAllowed);
                    
                    elseif line:GetText():match(LootReserve.TooltipScanner.Unique) then
                        self.unique = true;
                    
                    elseif line:GetText():match(LootReserve.TooltipScanner.StartsQuest) then
                        self.startsQuest = true;
                    end
                end
            end
            LootReserve.TooltipScanner:Hide();
            if not self.classesAllowed then
                self.classesAllowed = true;
            end
            if not self.unique then
                self.unique = false;
            end
            if not self.startsQuest then
                self.startsQuest = false;
            end
        end
    end
    if self.info then
        return unpack(self.info);
    end
    return nil;
end

function LootReserve.Item:Loaded()
  return GetItemInfo(self:GetID()) ~= nil;
end


function LootReserve.Item:GetSearchName()
  return self.searchName;
end

function LootReserve.Item:GetClassesAllowed()
  return self.classesAllowed;
end
function LootReserve.Item:IsUnique()
  return self.unique;
end
function LootReserve.Item:StartsQuest()
  return self.startsQuest;
end

function LootReserve.Item:GetName()
  return ({self:GetInfo()})[1];
end
function LootReserve.Item:GetLink()
  return ({self:GetInfo()})[2];
end
function LootReserve.Item:GetTexture()
  return ({self:GetInfo()})[10];
end

function LootReserve.Item:GetNameLinkTexture()
  local name, link, _, _, _, _, _, _, _, texture = self:GetInfo();
  return name, link, texture;
end

function LootReserve.Item:GetType()
  return ({self:GetInfo()})[6];
end
function LootReserve.Item:GetSubType()
  return ({self:GetInfo()})[7];
end
function LootReserve.Item:GetTypeAndSubType()
  local _, _, _, _, _, itemType, itemSubType = self:GetInfo();
  return itemType, itemSubType;
end

function LootReserve.Item:GetQuality()
  return ({self:GetInfo()})[3];
end

function LootReserve.Item:GetEquipLocation()
  return ({self:GetInfo()})[9];
end

function LootReserve.Item:GetBindType()
  return ({self:GetInfo()})[14];
end