LootReserve = LootReserve or { };
LootReserve.Item = { };

local itemMeta = {
  __index = LootReserve.Item,
  __eq    = function(item1, item2) return item1.id == item2.id and item1.suffix == item2.suffix end,
}

local function NewItem(id, suffix, uniqueID)
  return setmetatable({id = tonumber(id), suffix = tonumber(suffix), uniqueID = tonumber(uniqueID)}, itemMeta);
end

setmetatable(LootReserve.Item, {
  __call = function(self, arg1, arg2, arg3)
    if type(arg1) == "table" then
      return NewItem(arg1.id, arg1.suffix, arg1.uniqueID);
    elseif type(arg1) == "string" and arg1:find("item:") then
      local id, suffix, uniqueID = arg1:match("^.-item:(%d-):%d-:%d-:%d-:%d-:%d-:(.-):(.-):");
      return NewItem(id, suffix, uniqueID);
    else
      return NewItem(tonumber(arg1), tonumber(arg2), tonumber(arg3));
    end
  end
});

function LootReserve.Item:GetID()
  return self.id;
end

function LootReserve.Item:GetSuffix()
  return self.suffix or "";
end

function LootReserve.Item:GetUniqueID()
  return self.uniqueID or "";
end

function LootReserve.Item:unpack()
  return self:GetID(), self:GetSuffix(), self:GetUniqueID();
end


function LootReserve.Item:GetString()
  return format("item:%d::::::%d:%d::::::::::", self:unpack());
end

function LootReserve.Item:GetInfo()
  return GetItemInfo(self:GetString())
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