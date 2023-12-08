

local ADDON_NAME = "ItemCache"
local HOST_ADDON_NAME, Data = ...
local IsStandalone = ADDON_NAME == HOST_ADDON_NAME

local MAJOR, MINOR = ADDON_NAME, 6
local ItemCache, oldMinor = LibStub:NewLibrary(MAJOR, MINOR)
if not ItemCache and not IsStandalone then
  return
end

local Addon = {}
local L

if IsStandalone then
  Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
  L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
  
  Addon.AceConfig         = LibStub"AceConfig-3.0"
  Addon.AceConfigDialog   = LibStub"AceConfigDialog-3.0"
  Addon.AceConfigRegistry = LibStub"AceConfigRegistry-3.0"
  Addon.AceDB             = LibStub"AceDB-3.0"
  Addon.AceDBOptions      = LibStub"AceDBOptions-3.0"
  
  Addon.SemVer = LibStub"SemVer"
end



local assert       = assert
local type         = type
local next         = next
local ipairs       = ipairs
local pairs        = pairs
local getmetatable = getmetatable
local setmetatable = setmetatable
local tonumber     = tonumber

local format             = format
local strsplit           = strsplit
local wipe               = wipe
local GetMouseFocus      = GetMouseFocus
local DoesItemExistByID  = C_Item.DoesItemExistByID
local GetItemInfo        = GetItemInfo -- removes the need to bypass own hook
local GetItemInfoInstant = GetItemInfoInstant
local UnitExists         = UnitExists
local UnitClass          = UnitClass

local strmatch  = string.match
local strfind   = string.find
local strgmatch = string.gmatch
local strgsub   = string.gsub
local tblinsert = table.insert
local tblremove = table.remove
local floor     = math.floor



function Addon:MakeLookupTable(t, val, keepOrigVals)
  local ValFunc
  if val ~= nil then
    if type(val) == "function" then
      ValFunc = val
    else
      ValFunc = function() return val end
    end
  end
  local new = {}
  for k, v in next, t, nil do
    if ValFunc then
      new[v] = ValFunc(v, k, t)
    else
      new[v] = k
    end
    if keepOrigVals and new[k] == nil then
      new[k] = v
    end
  end
  return new
end



do
  Addon.expansions = {
    retail  = 10,
    wrath   = 3,
    wotlk   = 3,
    tbc     = 2,
    bcc     = 2,
    classic = 1,
  }
  Addon.expansionLevel = tonumber(GetBuildInfo():match"^(%d+)%.")
  if Addon.expansionLevel >= Addon.expansions.retail then
    Addon.expansionName = "retail"
  elseif Addon.expansionLevel >= Addon.expansions.wrath then
    Addon.expansionName = "wrath"
  elseif Addon.expansionLevel == Addon.expansions.tbc then
    Addon.expansionName = "tbc"
  elseif Addon.expansionLevel == Addon.expansions.classic then
    Addon.expansionName = "classic"
  end
  Addon.isRetail  = Addon.expansionName == "retail"
  Addon.isWrath   = Addon.expansionName == "wrath"
  Addon.isTBC     = Addon.expansionName == "tbc"
  Addon.isClassic = Addon.expansionName == "classic"
end

local MY_CLASS = select(2, UnitClassBase"player")




local CLASS_MAP_TO_ID = {}
for i = 1, GetNumClasses() do
  local name, file, id = GetClassInfo(i)
  if name then
    local maleNames, femaleNames = LOCALIZED_CLASS_NAMES_MALE[file], LOCALIZED_CLASS_NAMES_FEMALE[file]
    for _, v in ipairs{name, file, id, maleNames, femaleNames} do
      CLASS_MAP_TO_ID[v] = id
    end
  end
end
  

local IsItemUsable, IsItemUnusable
do
  -- WARRIOR, PALADIN, HUNTER, ROGUE, PRIEST, DEATHKNIGHT, SHAMAN, MAGE, WARLOCK, MONK, DRUID, DEMONHUNTER
  local ID = {}
  for i = 1, GetNumClasses() do
    local classInfo = C_CreatureInfo.GetClassInfo(i)
    if classInfo then
      ID[classInfo.classFile] = classInfo.classID
    end
  end
  
  local weapon      = Enum.ItemClass.Weapon
  local subWeapon   = Enum.ItemWeaponSubclass
  local armor       = Enum.ItemClass.Armor
  local subArmor    = Enum.ItemArmorSubclass
  local usableTypes = Addon:MakeLookupTable({weapon, armor}, function() return {} end)
  
  usableTypes[weapon][subWeapon.Unarmed]  = Addon:MakeLookupTable{ID.DRUID,       ID.HUNTER,  ID.ROGUE,   ID.SHAMAN,  ID.WARRIOR} -- Fist Weapons
  usableTypes[weapon][subWeapon.Axe1H]    = Addon:MakeLookupTable{ID.DEATHKNIGHT, ID.HUNTER,  ID.PALADIN, ID.ROGUE,   ID.SHAMAN,  ID.WARRIOR}
  usableTypes[weapon][subWeapon.Axe2H]    = Addon:MakeLookupTable{ID.DEATHKNIGHT, ID.HUNTER,  ID.PALADIN, ID.SHAMAN,  ID.WARRIOR}
  usableTypes[weapon][subWeapon.Bows]     = Addon:MakeLookupTable{ID.HUNTER,      ID.ROGUE,   ID.WARRIOR}
  usableTypes[weapon][subWeapon.Guns]     = Addon:MakeLookupTable{ID.HUNTER,      ID.ROGUE,   ID.WARRIOR}
  usableTypes[weapon][subWeapon.Mace1H]   = Addon:MakeLookupTable{ID.DEATHKNIGHT, ID.DRUID,   ID.PALADIN, ID.PRIEST,  ID.ROGUE,   ID.SHAMAN,  ID.WARRIOR}
  usableTypes[weapon][subWeapon.Mace2H]   = Addon:MakeLookupTable{ID.DEATHKNIGHT, ID.DRUID,   ID.PALADIN, ID.SHAMAN,  ID.WARRIOR}
  usableTypes[weapon][subWeapon.Polearm]  = Addon:MakeLookupTable{ID.DEATHKNIGHT, ID.DRUID,   ID.HUNTER,  ID.PALADIN, ID.WARRIOR}
  usableTypes[weapon][subWeapon.Sword1H]  = Addon:MakeLookupTable{ID.DEATHKNIGHT, ID.HUNTER,  ID.MAGE,    ID.PALADIN, ID.ROGUE,   ID.WARLOCK, ID.WARRIOR}
  usableTypes[weapon][subWeapon.Sword2H]  = Addon:MakeLookupTable{ID.DEATHKNIGHT, ID.HUNTER,  ID.PALADIN, ID.WARRIOR}
  usableTypes[weapon][subWeapon.Staff]    = Addon:MakeLookupTable{ID.DRUID,       ID.HUNTER,  ID.MAGE,    ID.PRIEST,  ID.SHAMAN,  ID.WARLOCK, ID.WARRIOR}
  usableTypes[weapon][subWeapon.Dagger]   = Addon:MakeLookupTable{ID.DRUID,       ID.HUNTER,  ID.MAGE,    ID.PRIEST,  ID.ROGUE,   ID.SHAMAN,  ID.WARLOCK, ID.WARRIOR}
  usableTypes[weapon][subWeapon.Crossbow] = Addon:MakeLookupTable{ID.HUNTER,      ID.ROGUE,   ID.WARRIOR}
  usableTypes[weapon][subWeapon.Wand]     = Addon:MakeLookupTable{ID.MAGE,        ID.PRIEST,  ID.WARLOCK}
  usableTypes[weapon][subWeapon.Thrown]   = Addon:MakeLookupTable{ID.HUNTER,      ID.ROGUE,   ID.WARRIOR}
  
  usableTypes[armor][subArmor.Leather]    = Addon:MakeLookupTable{ID.DEATHKNIGHT, ID.DRUID,   ID.HUNTER,  ID.PALADIN, ID.ROGUE,   ID.SHAMAN,  ID.WARRIOR}
  usableTypes[armor][subArmor.Mail]       = Addon:MakeLookupTable{ID.DEATHKNIGHT, ID.HUNTER,  ID.PALADIN, ID.SHAMAN,  ID.WARRIOR}
  usableTypes[armor][subArmor.Plate]      = Addon:MakeLookupTable{ID.DEATHKNIGHT, ID.PALADIN, ID.WARRIOR}
  usableTypes[armor][subArmor.Shield]     = Addon:MakeLookupTable{ID.PALADIN,     ID.SHAMAN,  ID.WARRIOR}
  usableTypes[armor][subArmor.Libram]     = Addon:MakeLookupTable{ID.PALADIN}
  usableTypes[armor][subArmor.Idol]       = Addon:MakeLookupTable{ID.DRUID}
  usableTypes[armor][subArmor.Totem]      = Addon:MakeLookupTable{ID.SHAMAN}
  usableTypes[armor][subArmor.Sigil]      = Addon:MakeLookupTable{ID.DEATHKNIGHT}
  -- usableTypes[weapon][subWeapon.Warglaive]   = Addon:MakeLookupTable{}
  -- usableTypes[weapon][subWeapon.Bearclaw]    = Addon:MakeLookupTable{}
  -- usableTypes[weapon][subWeapon.Catclaw]     = Addon:MakeLookupTable{}
  -- usableTypes[weapon][subWeapon.Unarmed]     = Addon:MakeLookupTable{}
  -- usableTypes[weapon][subWeapon.Generic]     = Addon:MakeLookupTable{}
  -- usableTypes[weapon][subWeapon.Obsolete3]   = Addon:MakeLookupTable{} -- Spears
  -- usableTypes[weapon][subWeapon.Fishingpole] = Addon:MakeLookupTable{}
  
  -- usableTypes[armor][subArmor.Generic]       = Addon:MakeLookupTable{}
  -- usableTypes[armor][subArmor.Cloth]         = Addon:MakeLookupTable{}
  -- usableTypes[armor][subArmor.Cosmetic]      = Addon:MakeLookupTable{}
  -- usableTypes[armor][subArmor.Relic]         = Addon:MakeLookupTable{}
  
  
  if Addon.expansionLevel <= Addon.expansions.tbc then
    usableTypes[weapon][subWeapon.Axe1H][ID.ROGUE]   = nil
    usableTypes[weapon][subWeapon.Polearm][ID.DRUID] = nil
  end
  
  local dualWielders = Addon:MakeLookupTable{ID.DEATHKNIGHT, ID.HUNTER, ID.ROGUE, ID.SHAMAN, ID.WARRIOR}
  
  IsItemUsable = function(item, classID)
    local invType, _, itemClassID, subClassID = select(4, item:GetInfoInstant())
    if usableTypes[itemClassID] and usableTypes[itemClassID][subClassID] then
      local class = classID or MY_CLASS
      return usableTypes[itemClassID][subClassID][class] and (invType ~= "INVTYPE_WEAPONOFFHAND" or dualWielders[class]) and true or false
    end
    return true
  end
  IsItemUnusable = function(...) return IsItemUsable(...) end
  
end




local ItemDB = {}
local Item   = {}

local privates = setmetatable({}, {__mode = "k"})
local function private(obj)
  return privates[obj]
end
local function setPrivate(obj, p)
  privates[obj] = p
  return private(obj)
end


local function Round(num, decimalPlaces)
  local mult = 10^(tonumber(decimalPlaces) or 0)
  return floor(tonumber(num) * mult + 0.5) / mult
end



local Queue = {}
local queueMeta = {
  __index    = function(_, k) assert(Queue[k], "Queue has no field: " .. tostring(k) .. ". Make sure ItemCache is up to date.") return Queue[k] end,
  __tostring = function(self) return "Queue" end,
}
local function MakeQueue(_, vals)
  local queue = vals or {}
  setPrivate(queue, {head = 1, tail = #queue + 1})
  setmetatable(queue, queueMeta)
  return queue
end
setmetatable(Queue, {__call = MakeQueue})
function Queue:len()
  local private = private(self)
  return private.tail - private.head
end
function Queue:isEmpty()
  return self:len() <= 0
end
function Queue:hasValues()
  return self:len() > 0
end
function Queue:add(v)
  local private = private(self)
  self[private.tail] = v
  private.tail = private.tail + 1
  return self
end
function Queue:peek()
  return self[private(self).head]
end
function Queue:pop()
  local private = private(self)
  local v = self:peek()
  self[private.head] = nil
  private.head = private.head + 1
  return v
end
function Queue:empty()
  local private = private(self)
  private.head, private.tail = 1, 1
  wipe(self)
  return self
end



local retrieveModes = {
  cache = {Retrieve = function(self) return self:Cache() end, IsRetrieved = function(self) return self:IsCached() end},
  load  = {Retrieve = function(self) return self:Load()  end, IsRetrieved = function(self) return self:IsLoaded() end},
}

local CallbackController = {}
local callbackControllerMeta = {
  __index    = function(_, k) assert(CallbackController[k], "CallbackController has no field: " .. tostring(k) .. ". Make sure ItemCache is up to date.") return CallbackController[k] end,
  __tostring = function(self) return "CallbackController" end,
}
local function MakeCallbackController(_, items, retrieveMode, callback, ...)
  local queue = {}
  for id, suffixItems in pairs(items) do
    for suffix, item in pairs(suffixItems) do
      tblinsert(queue, item)
    end
  end
  
  local callbackControllerPrivate          = {...}
  callbackControllerPrivate.items          = items;
  callbackControllerPrivate.queue          = Queue(queue);
  callbackControllerPrivate.Retrieve       = retrieveModes[retrieveMode].Retrieve;
  callbackControllerPrivate.IsRetrieved    = retrieveModes[retrieveMode].IsRetrieved;
  callbackControllerPrivate.callback       = callback;
  callbackControllerPrivate.itemsRemaining = #queue;
  callbackControllerPrivate.max            = #queue;
  callbackControllerPrivate.speed          = 1;
  callbackControllerPrivate.suspended      = false;
  callbackControllerPrivate.cancelled      = false;
  
  local callbackController = {}
  setPrivate(callbackController, callbackControllerPrivate);
  return setmetatable(callbackController, callbackControllerMeta);
end
setmetatable(CallbackController, {__call = MakeCallbackController})
function CallbackController:GetSize()
  return private(self).max
end
function CallbackController:GetRemaining()
  return private(self).itemsRemaining
end
function CallbackController:GetProgress(decimalPlaces)
  local private = private(self)
  return Round(private.max == 0 and 100 or (private.max - private.itemsRemaining) * 100/private.max, decimalPlaces or 2)
end
function CallbackController:IsComplete()
  return private(self).itemsRemaining == 0
end
function CallbackController:GetSpeed()
  return private(self).speed
end
function CallbackController:SetSpeed(speed)
  private(self).speed = speed
  return self
end
function CallbackController:IsSuspended()
  return private(self).suspended
end
function CallbackController:Suspend()
  private(self).suspended = true
  return self
end
function CallbackController:Resume()
  private(self).suspended = false
  return self
end
function CallbackController:Cancel()
  if not self:IsComplete() and not self.cancelled then
    private(self).cancelled = true
    ItemDB:UnregisterCallbackController(self)
  end
  return self
end
function CallbackController:IsCancelled()
  return private(self).cancelled
end


local storage

local matchMeta = {}
local itemMeta = {
  -- GetDebugName because of Blizzard_DebugTools\Blizzard_TableInspectorAttributeDataProvider.lua:61
  __index     = function(_, k) assert(k == "GetDebugName" or Item[k], "Item has no field: " .. tostring(k) .. ". Make sure ItemCache is up to date.") return Item[k] end,
  __newindex  = function(self, k, v) error("Item cannot be modified") end,
  __metatable = matchMeta,
  __eq        = function(item1, item2) return item1:GetID() == item2:GetID() and item1:GetSuffix() == item2:GetSuffix() end,
  __lt        = function(item1, item2) return (item1:GetName() or "") <  (item2:GetName() or "") end,
  __le        = function(item1, item2) return (item1:GetName() or "") <= (item2:GetName() or "") end,
  __tostring  = function(self) return "Item " .. self:GetID() .. (self:HasSuffix() and (":" .. self:GetSuffix()) or "") end,
}

function ItemCache:DoesItemExistByID(id)
  if not DoesItemExistByID(id) then
    return false
  end
  if storage[id] then
    for suffix, itemPrivate in pairs(storage[id]) do
      if suffix ~= 0 then
        return true
      elseif itemPrivate.dne then
        return false
      end
    end
  end
  return true
end

local function IsItem(item)
  return type(item) == "table" and getmetatable(item) == matchMeta
end

local function MakeItem(id, suffix)
  if suffix == 0 then
    suffix = nil
  end
  local facade = {id, suffix} -- this table could be used to rebuild the Item without a metatable (like after being stored in savedvars). it is NOT protected from editing, but should not be changed
  local item -- this table is protected from editing, and contains the actual id and suffix used by Item
  if storage[id] and storage[id][suffix or 0] then
    item = storage[id][suffix or 0]
  else
    item = {id = id, suffix = suffix}
  end
  setPrivate(facade, item)
  setPrivate(item, _G.Item:CreateFromItemID(id))
  return setmetatable(facade, itemMeta)
end

function ItemCache:FormatSearchText(text)
  return text:gsub("%W", ""):lower()
end

local function InterpretItem(arg, suffix)
  if IsItem(arg) then
    return arg:GetID(), arg:GetSuffix()
  end
  local argType = type(arg)
  if argType == "table" and (arg.id or #arg > 0) then
    return arg.id or arg[1], arg.suffix or arg[2]
  elseif argType == "string" then -- try to decipher itemlink
    local id = tonumber(arg)
    if id then
      return id
    end
    local id, suffix = strmatch(arg, "^.-item:(%d-):[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:([%-%d]*):")
    id, suffix = tonumber(id or ""), tonumber(suffix or "")
    if id then
      return id, suffix
    end
    return nil -- this can happen if GetItemInfo is passed an item name or any random string
  elseif argType == "number" then -- must be an itemID
    return arg, suffix
  else
    return nil
  end
end

function ItemCache:Filter(...)
  return ItemDB:Filter(...)
end

function ItemCache:All()
  return ItemDB:Filter(function() return true end)
end

function ItemCache:GetItemInfo(...)
  return ItemCache:Item(...):GetInfo()
end

function ItemCache:Item(arg, suffix)
  if IsItem(arg) then
    return arg
  else
    local id, suffix = InterpretItem(arg, suffix)
    assert(id, format("Bad Item format: %s", arg and tostring(arg) or "nil"))
    return ItemDB:Get(id, suffix)
  end
  return nil
end
ItemCache.Get = ItemCache.Item
setmetatable(ItemCache, {__call = ItemCache.Item})






function ItemDB:Check(id, suffix)
  if not self.cache[id] then
    return nil
  end
  return self.cache[id][suffix or 0]
end
function ItemDB:Get(id, suffix)
  if not self.cache[id] then
    self.cache[id] = {}
  end
  local item = self.cache[id][suffix or 0]
  if not item then
    item = MakeItem(id, suffix)
    self.cache[id][suffix or 0] = item
  end
  return item
end

-- check if an item is in storage
function ItemDB:IsStored(item)
  local id, suffix = item:GetIDSuffix()
  return storage[id] and storage[id][suffix or 0] and true or false
end

-- save an item into storage
function ItemDB:Store(item)
  if not storage[item:GetID()] then
    if not item:HasSuffix() then
      storage[item:GetID()] = {[0] = private(item)}
    end
  elseif item:HasSuffix() and not storage[item:GetID()][item:GetSuffix()] then -- only store suffix items if the suffix matters
    local noSuffixItem = self:Get(item:GetID())
    if noSuffixItem and item:GetName() ~= noSuffixItem:GetName() then
      storage[item:GetID()][item:GetSuffix()] = private(item)
    end
  end
end

function ItemDB:Filter(func)
  local list = {}
  for id, items in pairs(self.cache) do
    for suffix, item in pairs(items) do
      if self:IsStored(item) and func(item, id, suffix) then
        tblinsert(list, item)
      end
    end
  end
  return list
end

function ItemDB:GetItemInfoPacked(...)
  return {GetItemInfo(...)}
end

function ItemDB:AddQueryItems(callbackController)
  tblinsert(self.queryCallbacks, callbackController)
end

function ItemDB:AddLoadCallback(callbackController)
  tblinsert(self.loadCallbacks, callbackController)
end


function ItemDB:RunLoadCallbacks(item)
  local id, suffix = item:GetID(), item:GetSuffix() or 0
  for i = #self.loadCallbacks, 1, -1 do
    local private = private(self.loadCallbacks[i])
    local items = private.items
    if items[id] and items[id][suffix] then
      items[id][suffix] = nil
      if not next(items[id]) then
        items[id] = nil
      end
      private.itemsRemaining = private.itemsRemaining - 1
      if private.itemsRemaining == 0 then
        if private.callback then
          private.callback(unpack(private))
        end
        tblremove(self.loadCallbacks, i)
      end
    end
  end
end

function ItemDB:RegisterCallbackController(callbackController)
  tblinsert(self.queryCallbacks, callbackController)
  tblinsert(self.loadCallbacks, callbackController)
  private(callbackController).registered = true
end

function ItemDB:UnregisterCallbackController(callbackController)
  for _, tbl in ipairs{self.queryCallbacks, self.loadCallbacks} do
    for i, v in ipairs(tbl) do
      if v == callbackController then
        tblremove(tbl, i)
      end
    end
  end
  private(callbackController).registered = false
end




function ItemDB:InitTooltipScanner()
  self.tooltipScanner = ItemCachetooltipScanner
  if not self.tooltipScanner then
    self.tooltipScanner = CreateFrame("GameTooltip", "ItemCachetooltipScanner", nil, "GameTooltipTemplate")
    self.tooltipScanner:Hide()
    
    self.tooltipScanner.ClassesAllowed = format("^%s$"  , ITEM_CLASSES_ALLOWED:gsub("%d+%$", ""):gsub("%%s", "(.+)"))
    self.tooltipScanner.SkillRequired  = format("^%s$"  , ITEM_MIN_SKILL:gsub("%d+%$", ""):gsub("%%s ", "([%%a%%s]+) "):gsub("%(%%d%)", "%%((%%d+)%%)"))
    self.tooltipScanner.Unique         = format("^(%s)$", ITEM_UNIQUE:gsub("%d+%$", ""))
    self.tooltipScanner.StartsQuest    = format("^(%s)$", ITEM_STARTS_QUEST:gsub("%d+%$", ""))
  end
end

function ItemDB:InitQueryCallbacks()
  self.QueryFrame = CreateFrame("Frame", nil, UIItem)
  self.QueryFrame:SetPoint("TOPLEFT", UIItem, "TOPLEFT", 0, 0)
  self.QueryFrame:SetSize(0, 0)
  self.QueryFrame:Show()
  
  self.QueryFrame:SetScript("OnUpdate", function()
    if #self.queryCallbacks == 0 then return end
    for i = #self.queryCallbacks, 1, -1 do
      local private        = private(self.queryCallbacks[i])
      local queue          = private.queue
      local yieldThreshold = private.speed
      if private.itemsRemaining == 0 then
        queue:empty()
        tblremove(self.queryCallbacks, i)
      elseif not private.suspended then
        local Retrieve    = private.Retrieve
        local IsRetrieved = private.IsRetrieved
        while queue:hasValues() do
          if yieldThreshold <= 0 then
            break
          end
          local item = queue:pop()
          if not IsItem(item) then
            local id, suffix = InterpretItem(item)
            if not self:Check(id, suffix) then
              yieldThreshold = yieldThreshold - 1
            end
            item = ItemCache:Item(id, suffix)
          end
          if IsRetrieved(item) then
            self:RunLoadCallbacks(item)
          else
            Retrieve(item)
            if IsRetrieved(item) then
              self:RunLoadCallbacks(item)
            else
              yieldThreshold = yieldThreshold - 1
              if item:Exists() then
                queue:add(item)
              else
                private.itemsRemaining = private.itemsRemaining - 1
                if private.itemsRemaining == 0 then
                  if private.callback then
                    private.callback(unpack(private))
                  end
                  tblremove(self.loadCallbacks, i)
                end
              end
            end
          end
        end
        if not queue:hasValues() then
          tblremove(self.queryCallbacks, i)
        end
      end
    end
  end)
end

function ItemDB:RegisterEvents(frame)
  for _, event in ipairs(frame.events or {}) do
    frame:RegisterEvent(event)
  end
end

function ItemDB:UnregisterEvents(frame)
  for _, event in ipairs(frame.events or {}) do
    frame:UnregisterEvent(event)
  end
end

function ItemDB:InitItemInfoListener()
  self.ItemInfoListenerFrame = CreateFrame("Frame", nil, UIItem)
  self.ItemInfoListenerFrame:SetPoint("TOPLEFT", UIItem, "TOPLEFT", 0, 0)
  self.ItemInfoListenerFrame:SetSize(0, 0)
  self.ItemInfoListenerFrame:Show()
  
  self.ItemInfoListenerFrame.events = {"GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT"}
  self:RegisterEvents(self.ItemInfoListenerFrame)
  self.ItemInfoListenerFrame:SetScript("OnEvent", function(_, event, id, success)
    self:Get(id)
    for suffix in pairs(self.cache[id]) do
      local item = self:Get(id, suffix)
      if not item:IsCached() then
        if success then
          item:Cache()
          
        else
            private(item).dne = true
            ItemDB:Store(item)
          if not self.loadAttempts[id] then
            self.loadAttempts[id] = 0
          end
          self.loadAttempts[id] = self.loadAttempts[id] + 1
          if self.loadAttempts[id] >= self.MAX_LOAD_ATTEMPTS then
            private(item).dne = true
          else
            item:Load()
          end
        end
      end
    end
  end)
end

function ItemDB:InitChatListener()
  self.ChatListenerFrame = CreateFrame("Frame", nil, UIItem)
  self.ChatListenerFrame:SetPoint("TOPLEFT", UIItem, "TOPLEFT", 0, 0)
  self.ChatListenerFrame:SetSize(0, 0)
  self.ChatListenerFrame:Show()
  
  
  self.ChatListenerFrame.events =  {"CHAT_MSG_CHANNEL", "CHAT_MSG_ADDON", "CHAT_MSG_BN_WHISPER",
                                    "CHAT_MSG_EMOTE", "CHAT_MSG_GUILD", "CHAT_MSG_LOOT",
                                    "CHAT_MSG_OFFICER", "CHAT_MSG_OPENING", "CHAT_MSG_PARTY",
                                    "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
                                    "CHAT_MSG_RAID_WARNING", "CHAT_MSG_SAY", "CHAT_MSG_TEXT_EMOTE",
                                    "CHAT_MSG_TRADESKILLS", "CHAT_MSG_WHISPER", "CHAT_MSG_YELL"}
  self:RegisterEvents(self.ChatListenerFrame)
  self.ChatListenerFrame:SetScript("OnEvent", function(_, event, message)
    for itemString in strgmatch(message, "item[%-?%d:]+") do
      local id, suffix = InterpretItem(itemString)
      if id then
        local item = self:Get(id, suffix)
        if item:Exists() then
          item:Cache()
        end
      end
    end
  end)
end

function ItemDB:InitMouseoverHook()
  self.mouseoverHook = true
  GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
    if not self.mouseoverHook then return end
    
    local name, link = tooltip:GetItem()
    if not link then return end
    local itemString = strmatch(link, "item[%-?%d:]+")
    
    local id, suffix = InterpretItem(itemString)
    if id and id ~= 0 then
      local item = self:Get(id, suffix)
      if item:Exists() then
        item:Cache()
      end
    elseif TradeSkillFrame and TradeSkillFrame:IsVisible() then
      if GetMouseFocus():GetName() == "TradeSkillSkillIcon" then
        local id, suffix = InterpretItem(GetTradeSkillItemLink(TradeSkillFrame.selectedSkill))
        if id then
          local item = self:Get(id, suffix)
          if item:Exists() then
            item:Cache()
          end
        end
      else
        for i = 1, 8 do
          if GetMouseFocus():GetName() == "TradeSkillReagent"..i then
            local id, suffix = InterpretItem(GetTradeSkillReagentItemLink(TradeSkillFrame.selectedSkill, i))
            if id then
              local item = self:Get(id, suffix)
              if item:Exists() then
                item:Cache()
              end
            end
            break
          end
        end
      end
    end
  end)
end

function ItemDB:InitGetItemInfoHook()
  self.GetItemInfoHook = true
  hooksecurefunc("GetItemInfo", function(...)
    if not self.GetItemInfoHook then return end
    local id, suffix = InterpretItem(...)
    if id then
      local item = self:Get(id, suffix)
      if item then
        item:Cache()
      end
    end
  end)
end

function ItemDB:Destructor()
  self.QueryFrame:Hide()
  self:UnregisterEvents(self.ItemInfoListenerFrame)
  self:UnregisterEvents(self.ChatListenerFrame)
  
  self.GetItemInfoHook = false
  self.tooltipHook     = false
  self.mouseoverHook   = false
  
  wipe(self.cache)
  wipe(self.loadCallbacks)
  wipe(self.queryCallbacks)
end

function ItemDB:Init()
  if self.initialized then return end
  local version, build = GetBuildInfo()
  
  if not ItemCacheStorage then
    ItemCacheStorage = {}
  end
  local db = ItemCacheStorage
  
  if not db._BUILD or db._BUILD < build then
    wipe(db)
    db._BUILD = build
  end
  if IsStandalone and not Addon:GetGlobalOption"UsePersistentStorage" then
    ItemCacheStorage = nil
  end
  
  local locale = GetLocale()
  if not db[locale] then
    db[locale] = {}
  end
  storage = db[locale]
  
  self.cache             = {}
  self.loadCallbacks     = {}
  self.queryCallbacks    = {}
  self.loadAttempts      = {}
  self.MAX_LOAD_ATTEMPTS = 10
  
  self:InitTooltipScanner()
  self:InitQueryCallbacks()
  self:InitItemInfoListener()
  self:InitChatListener()
  self:InitGetItemInfoHook()
  self:InitMouseoverHook()
  
  self.initialized = true
  
  -- Bring all stored items into cache
  for id, items in pairs(storage) do
    if type(id) == "number" then
      for suffix, item in pairs(items) do
        self:Get(id, suffix)
      end
    end
  end
  
  -- Shut down if a newer version is found
  local timer
  timer = C_Timer.NewTicker(1, function()
    local _, minor = LibStub:GetLibrary(ADDON_NAME)
    if minor ~= MINOR then
      timer:Cancel()
      self:Destructor()
    end
  end)
end


local function Items_OnCacheOrLoad(items, self, retrieveMode, func, ...)
  local itemsToLoad = {}
  local IsRetrieved = retrieveModes[retrieveMode].IsRetrieved
  for _, item in pairs(items) do
    local id, suffix = InterpretItem(item)
    assert(id, format("Bad Item format: %s", item and tostring(item) or "nil"))
    local loadItem = true
    if not ItemCache:DoesItemExistByID(id) then
      loadItem = false
    end
    if loadItem and ItemDB:Check(id, suffix) then
      item = ItemDB:Get(id, suffix)
      if IsRetrieved(item) then
        loadItem = false
      end
    end
    if loadItem then
      if not itemsToLoad[id] then
        itemsToLoad[id] = {}
      end
      itemsToLoad[id][suffix or 0] = ItemDB:Check(id, suffix) and ItemDB:Get(id, suffix) or item
    end
  end
  if next(itemsToLoad) then
    local callbackController
    if self then
      callbackController = CallbackController(itemsToLoad, retrieveMode, func, self, ...)
    else
      callbackController = CallbackController(itemsToLoad, retrieveMode)
    end
    ItemDB:RegisterCallbackController(callbackController)
    return callbackController
  else
    if self then
      func(self, ...)
      return CallbackController({}, retrieveMode, func, self, ...)
    else
      return CallbackController({}, retrieveMode)
    end
  end
end


function ItemCache:OnCache(items, ...)
  return Items_OnCacheOrLoad(items, items, "cache", ...)
end
function ItemCache:OnLoad(items, ...)
  return Items_OnCacheOrLoad(items, items, "load", ...)
end
function ItemCache:Cache(items)
  return Items_OnCacheOrLoad(items, nil, "cache")
end
function ItemCache:Load(items)
  return Items_OnCacheOrLoad(items, nil, "load")
end

function Item:OnCache(...)
  return Items_OnCacheOrLoad({self}, self, "cache", ...)
end
function Item:OnLoad(...)
  return Items_OnCacheOrLoad({self}, self, "load", ...)
end



function Item:GetID()
  return private(self).id
end
Item.GetId = Item.GetID
function Item:GetSuffix()
  return private(self).suffix
end
function Item:HasSuffix()
  return private(self).suffix ~= nil
end
function Item:GetIDSuffix()
  return self:GetID(), self:GetSuffix()
end
Item.GetIdSuffix = Item.GetIDSuffix


function Item:GetString()
  return format("item:%d::::::%d:::::::::::", self:GetID(), self:GetSuffix() or "")
end

function Item:Exists()
  return ItemCache:DoesItemExistByID(self:GetID())
end
function Item:IsLoaded()
  return private(private(self)):IsItemDataCached()
end
function Item:Load()
  C_Item.RequestLoadItemDataByID(self:GetID())
end

function Item:IsCached()
  return private(self).info ~= nil
end
function Item:Cache()
  if not self:IsCached() then
    self:GetInfo()
  end
  return self
end

function Item:GetInfo()
  if self:Exists() then
    if not private(self).info then
      if not self:IsLoaded() then
        self:Load()
        return
      end
      local info = ItemDB:GetItemInfoPacked(self:GetString())
      private(self).dne = nil
      info[2] = strgsub(info[2], "(item:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:)([^:]*):", "%1:")
      private(self).info = info
      -- local name, link, quality, level, minLevel, itemType, itemSubType, maxStackSize, equipLoc, texture, sellPrice, classID, subclassID, bindType = unpack(info)
      private(self).searchName = ItemCache:FormatSearchText(info[1])
      
      ItemDB.tooltipScanner:SetOwner(WorldFrame, "ANCHOR_NONE")
      ItemDB.tooltipScanner:SetHyperlink("item:" .. self:GetID())
      for i = 1, ItemDB.tooltipScanner:NumLines() do
        local line = _G[ItemDB.tooltipScanner:GetName() .. "TextLeft" .. i]
        if line and line:GetText() then
          if strmatch(line:GetText(), ItemDB.tooltipScanner.Unique) then
            private(self).unique = true
            
          elseif strmatch(line:GetText(), ItemDB.tooltipScanner.StartsQuest) then
            private(self).startsQuest = true
            
          else
            local skill, level = strmatch(line:GetText(), ItemDB.tooltipScanner.SkillRequired)
            if skill then
              private(self).skillRequired      = skill
              private(self).skillLevelRequired = tonumber(level)
            else
              local classesAllowedText = strmatch(line:GetText(), ItemDB.tooltipScanner.ClassesAllowed)
              if classesAllowedText then
                local classesAllowed = {}
                for _, names in ipairs{LOCALIZED_CLASS_NAMES_MALE, LOCALIZED_CLASS_NAMES_FEMALE} do
                  for file, name in pairs(names) do
                    if strmatch(classesAllowedText, name) then
                      classesAllowed[CLASS_MAP_TO_ID[file]] = true
                    end
                  end
                end
                private(self).classesAllowed = classesAllowed
              end
            end
          end
        end
      end
      ItemDB.tooltipScanner:Hide()
      ItemDB:Store(self)
      ItemDB:RunLoadCallbacks(self)
    end
  end
  local info = private(self).info
  if info then
    return info[1], strgsub(info[2], "(item:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*)([^:]*)(:.*)", "%1" .. UnitLevel"player" .. "%3"), select(3, unpack(info))
  end
  return nil
end
function Item:GetInfoPacked()
  return {self:GetInfo()}
end

function Item:GetInfoInstant()
  return GetItemInfoInstant(self:GetID())
end

function Item:GetInfoInstantPacked()
  return {self:GetInfoInstant()}
end



function Item:IsUsableBy(classOrUnit)
  local classID = CLASS_MAP_TO_ID[classOrUnit]
  if not classID and UnitExists(classOrUnit) then
    classID = select(2, UnitClassBase(classOrUnit))
  end
  local classesAllowed = private(self).classesAllowed
  if classesAllowed then
    return classesAllowed[classID] or false
  end
  return IsItemUsable(self, classID)
end
function Item:IsUsable(classOrUnit)
  return self:IsUsableBy(classOrUnit or MY_CLASS)
end
function Item:GetSkillRequired()
  if not self:IsCached() then return nil end
  local skill, level = private(self).skillRequired, private(self).skillLevelRequired
  if not skill then
    skill = false
  end
  return skill, level
end

function Item:RequiresSkill(skill, level)
  local skillRequired, levelRequired = self:GetSkillRequired()
  if skillRequired == nil then return nil end
  return (not skill or skill == skillRequired) and (not level or level <= levelRequired) and true or false
end

function Item:RequiresCooking(...)        return self:RequiresSkill(PROFESSIONS_COOKING,                 ...) end
function Item:RequiresFirstAid(...)       return self:RequiresSkill(PROFESSIONS_FIRST_AID,               ...) end
function Item:RequiresFishing(...)        return self:RequiresSkill(PROFESSIONS_FISHING,                 ...) end

-- these GlobalStrings are not appearing ingame (yet?)
  
-- function Item:RequiresAlchemy(...)        return self:RequiresSkill(CHARACTER_PROFESSION_ALCHEMY,        ...) end
-- function Item:RequiresBlacksmithing(...)  return self:RequiresSkill(CHARACTER_PROFESSION_BLACKSMITHING,  ...) end
-- function Item:RequiresEnchanting(...)     return self:RequiresSkill(CHARACTER_PROFESSION_ENCHANTING,     ...) end
-- function Item:RequiresEngineering(...)    return self:RequiresSkill(CHARACTER_PROFESSION_ENGINEERING,    ...) end
-- function Item:RequiresHerbalism(...)      return self:RequiresSkill(CHARACTER_PROFESSION_HERBALISM,      ...) end
-- function Item:RequiresInscription(...)    return self:RequiresSkill(CHARACTER_PROFESSION_INSCRIPTION,    ...) end
-- function Item:RequiresJewelcrafting(...)  return self:RequiresSkill(CHARACTER_PROFESSION_JEWELCRAFTING,  ...) end
-- function Item:RequiresLeatherworking(...) return self:RequiresSkill(CHARACTER_PROFESSION_LEATHERWORKING, ...) end
-- function Item:RequiresMining(...)         return self:RequiresSkill(CHARACTER_PROFESSION_MINING,         ...) end
-- function Item:RequiresPoisons(...)        return self:RequiresSkill(MINIMAP_TRACKING_VENDOR_POISON,      ...) end
-- function Item:RequiresRiding(...)         return self:RequiresSkill("Riding",                            ...) end
-- function Item:RequiresTailoring(...)      return self:RequiresSkill(CHARACTER_PROFESSION_TAILORING,      ...) end


function Item:IsUnique()
  if not self:IsCached() then return nil end
  return private(self).unique or false
end
function Item:StartsQuest()
  if not self:IsCached() then return nil end
  return private(self).startsQuest or false
end
function Item:GetSearchName()
  return private(self).searchName
end

function Item:Matches(text)
  local id = tonumber(text)
  if id then
    return self:GetID() == id
  end
  local searchName = private(self).searchName
  if searchName then
    return strfind(searchName, text)
  end
  return nil
end

function Item:GetName()
  return (select(1, self:GetInfo()))
end
function Item:GetLink()
  return (select(2, self:GetInfo()))
end
function Item:GetNameLink()
  local name, link = self:GetInfo()
  return name, link
end
function Item:GetTexture()
  return (select(5, self:GetInfoInstant()))
end
Item.GetIcon = Item.GetTexture
function Item:GetNameLinkTexture()
  local name, link, _, _, _, _, _, _, _, texture = self:GetInfo()
  return name, link, texture
end
Item.GetNameLinkIcon = Item.GetNameLinkTexture

function Item:GetType()
  return (select(2, self:GetInfoInstant()))
end
function Item:GetSubType()
  return (select(3, self:GetInfoInstant()))
end
function Item:GetTypeSubType()
  local _, itemType, itemSubType = self:GetInfoInstant()
  return itemType, itemSubType
end

function Item:GetQuality()
  return (select(3, self:GetInfo()))
end

function Item:GetLevel()
  return (select(4, self:GetInfo()))
end

function Item:GetMinLevel()
  return (select(5, self:GetInfo()))
end

function Item:GetDetailedLevelInfo()
  return GetDetailedItemLevelInfo(self:GetString())
end

function Item:GetStackSize()
  return (select(8, self:GetInfo()))
end

function Item:GetSellPrice()
  return (select(11, self:GetInfo()))
end
Item.GetVendorPrice = Item.GetSellPrice
Item.GetPrice       = Item.GetSellPrice
Item.GetValue       = Item.GetSellPrice

function Item:GetBindType()
  return (select(14, self:GetInfo()))
end
function Item:DoesNotBind()    return self:GetBindType() == LE_ITEM_BIND_NONE       end
function Item:CanBind()        return self:GetBindType() ~= LE_ITEM_BIND_NONE       end
function Item:IsBindOnPickup() return self:GetBindType() == LE_ITEM_BIND_ON_ACQUIRE end
function Item:IsBindOnEquip()  return self:GetBindType() == LE_ITEM_BIND_ON_EQUIP   end
function Item:IsBindOnUse()    return self:GetBindType() == LE_ITEM_BIND_ON_USE     end
Item.Binds = Item.CanBind
Item.IsBoP = Item.IsBindOnPickup
Item.IsBoE = Item.IsBindOnEquip
Item.IsBoU = Item.IsBindOnUse


function Item:GetEquipLocation()
  return (select(4, self:GetInfoInstant()))
end
function Item:IsEquippable()     return self:GetEquipLocation() ~= ""                       and self:GetEquipLocation() ~= "INVTYPE_NON_EQUIP" end
function Item:IsHelm()           return self:GetEquipLocation() == "INVTYPE_HEAD"           end
function Item:IsNecklace()       return self:GetEquipLocation() == "INVTYPE_NECK"           end
function Item:IsShoulder()       return self:GetEquipLocation() == "INVTYPE_SHOULDER"       end
function Item:IsShirt()          return self:GetEquipLocation() == "INVTYPE_BODY"           end
function Item:IsTabard()         return self:GetEquipLocation() == "INVTYPE_TABARD"         end
function Item:IsChest()          return self:GetEquipLocation() == "INVTYPE_CHEST"          or  self:GetEquipLocation() == "INVTYPE_ROBE"      end
function Item:IsBelt()           return self:GetEquipLocation() == "INVTYPE_WAIST"          end
function Item:IsPants()          return self:GetEquipLocation() == "INVTYPE_LEGS"           end
function Item:IsBoots()          return self:GetEquipLocation() == "INVTYPE_FEET"           end
function Item:IsBracers()        return self:GetEquipLocation() == "INVTYPE_WRIST"          end
function Item:IsGloves()         return self:GetEquipLocation() == "INVTYPE_HAND"           end
function Item:IsRing()           return self:GetEquipLocation() == "INVTYPE_FINGER"         end
function Item:IsTrinket()        return self:GetEquipLocation() == "INVTYPE_TRINKET"        end
function Item:IsCloak()          return self:GetEquipLocation() == "INVTYPE_CLOAK"          end

function Item:IsQuiver()         return self:GetEquipLocation() == "INVTYPE_QUIVER"         end
function Item:IsNormalBag()      return self:GetEquipLocation() == "INVTYPE_BAG"            end

function Item:IsRelic()          return self:GetEquipLocation() == "INVTYPE_RELIC"          end
function Item:IsShield()         return self:GetEquipLocation() == "INVTYPE_SHIELD"         end
function Item:IsHoldable()       return self:GetEquipLocation() == "INVTYPE_HOLDABLE"       end

function Item:IsOneHandWeapon()  return self:GetEquipLocation() == "INVTYPE_WEAPON"         end
function Item:IsTwoHandWeapon()  return self:GetEquipLocation() == "INVTYPE_2HWEAPON"       end
function Item:IsMainHandWeapon() return self:GetEquipLocation() == "INVTYPE_WEAPONMAINHAND" end
function Item:IsOffHandWeapon()  return self:GetEquipLocation() == "INVTYPE_WEAPONOFFHAND"  end

function Item:IsGunOrBow()       return self:GetEquipLocation() == "INVTYPE_RANGED"         end
function Item:IsThrownWeapon()   return self:GetEquipLocation() == "INVTYPE_THROWN"         end

function Item:IsBag()          return self:IsNormalBag()     or self:IsQuiver()        end
function Item:IsOffHand()      return self:IsRelic()         or self:IsShield()        or  self:IsHoldable()       or self:IsOffHandWeapon()  end
function Item:IsRangedWeapon() return self:IsGunOrBow()      or self:IsThrownWeapon()  end
function Item:IsMeleeWeapon()  return self:IsOneHandWeapon() or self:IsTwoHandWeapon() or  self:IsMainHandWeapon() or  self:IsOffHandWeapon() end
function Item:IsWeapon()       return self:IsMeleeWeapon()   or self:IsRangedWeapon()  end

Item.IsHat   = Item.IsHelm
Item.IsNeck  = Item.IsNecklace
Item.IsRobe  = Item.IsChest
Item.IsLegs  = Item.IsPants
Item.IsShoes = Item.IsBoots








function Addon:OnChatCommand(input)
  local arg = self:GetArgs(input, 1)
  
  local func = arg and self.chatArgs[arg] or nil
  if func then
    func(self)
  else
    self:OpenConfig(ADDON_NAME)
  end
end


function Addon:CreateOptions()
  self:MakeAddonOptions(self.chatCommands[1])
  
  -- Debug Options
  if self:IsDebugEnabled() then
    self:MakeDebugOptions(self.L["Debug"], self.chatCommands[1], "debug", "db", "d")
  end
end

function Addon:InitDB()
  local configVersion = self.SemVer(self:GetOption"version" or tostring(self.version))
  
  if not self:GetOption"version" then -- first run
    
  else -- upgrade data schema
    
  end
  
  self:SetOption(tostring(self.version), "version")
end


function Addon:OnInitialize()
  self.db        = self.AceDB:New(("%sDB"):format(ADDON_NAME), self:MakeDefaultOptions(), true)
  self.dbDefault = self.AceDB:New({}                         , self:MakeDefaultOptions(), true)
  
  self:RunInitializeCallbacks()
  
  ItemDB:Init()
end

function Addon:OnEnable()
  self.version = self.SemVer(GetAddOnMetadata(ADDON_NAME, "Version"))
  self:InitDB()
  self:GetDB().RegisterCallback(self, "OnProfileChanged", "InitDB")
  self:GetDB().RegisterCallback(self, "OnProfileCopied" , "InitDB")
  self:GetDB().RegisterCallback(self, "OnProfileReset"  , "InitDB")
  
  self:InitChatCommands{"ic", ADDON_NAME:lower()}
  
  self:RunEnableCallbacks()
end

function Addon:OnDisable()
end




if not IsStandalone then
  ItemDB:Init()
end





