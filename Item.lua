LootReserve = LootReserve or { };
LootReserve.Item = { };

local itemMeta = {
    __index = LootReserve.Item,
    __eq    = function(item1, item2) return item1.id == item2.id and item1.suffix == item2.suffix end,
}

local function NewItem(id, suffix, uniqueID, info, texture, link, name, searchName, classesAllowed)
    return setmetatable({
        id             = tonumber(id),
        suffix         = tonumber(suffix),
        uniqueID       = tonumber(uniqueID),
        info           = info,
        texture        = texture,
        link           = link,
        name           = name,
        searchName     = searchName,
        classesAllowed = classesAllowed
    }, itemMeta);
end

local function UnpackItem(Item)
    return Item.id, Item.suffix, Item.uniqueID, Item.info, Item.texture, Item.link, Item.name, Item.searchName, Item.classesAllowed;
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
    if not self.name then
        local info = {GetItemInfo(self:GetString())};
        self.info = info;
        local name, link, _, _, _, _, _, _, _, texture = unpack(info);
        if name then
            self.texture    = teture;
            self.link       = link;
            self.name       = name;
            self.searchName = LootReserve:TransformSearchText(name);

            if not LootReserve.TooltipScanner then
                LootReserve.TooltipScanner = CreateFrame("GameTooltip", "LootReserveTooltipScanner", UIParent, "GameTooltipTemplate");
                LootReserve.TooltipScanner:Hide();
            end

            if not LootReserve.TooltipScanner.ClassesAllowed then
                LootReserve.TooltipScanner.ClassesAllowed = ITEM_CLASSES_ALLOWED:gsub("%%s", "(.+)");
            end

            LootReserve.TooltipScanner:SetOwner(UIParent, "ANCHOR_NONE");
            LootReserve.TooltipScanner:SetHyperlink("item:" .. self:GetID());
            for i = 1, LootReserve.TooltipScanner:NumLines() do
                local line = _G[LootReserve.TooltipScanner:GetName() .. "TextLeft" .. i];
                if line and line:GetText() then
                    local match = line:GetText():match(LootReserve.TooltipScanner.ClassesAllowed);
                    if match then
                        self.classesAllowed = match;
                        break;
                    end
                end
            end
            LootReserve.TooltipScanner:Hide();
            if not self.classesAllowed then
                self.classesAllowed = true;
            end
        end
    end
    if self.name then
        return unpack(self.info);
    end
    return nil;
end

function LootReserve.Item:Cache()
  return GetItemInfo(self:GetID()) ~= nil;
end


function LootReserve.Item:GetSearchName()
  return self.searchName;
end

function LootReserve.Item:GetClassesAllowed()
  return self.classesAllowed;
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

function LootReserve.Item:GetQuality()
  return ({self:GetInfo()})[3];
end