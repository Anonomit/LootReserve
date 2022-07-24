

local ADDON_NAME = "ItemCache"
local HOST_ADDON_NAME, Data = ...
local IsStandalone = ADDON_NAME == HOST_ADDON_NAME

local MAJOR, MINOR = ADDON_NAME, 3
local ItemCache, oldMinor = LibStub:NewLibrary(MAJOR, MINOR)
if not ItemCache and not IsStandalone then
  return
end

local Addon = {}
local L
local AceConfig
local AceConfigDialog
local AceConfigRegistry
local AceDB
local AceDBOptions
local SemVer

if IsStandalone then
  Addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0") or {}
  ItemCacheAddon = Addon
  L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
  
  AceConfig         = LibStub"AceConfig-3.0"
  AceConfigDialog   = LibStub"AceConfigDialog-3.0"
  AceConfigRegistry = LibStub"AceConfigRegistry-3.0"
  AceDB             = LibStub"AceDB-3.0"
  AceDBOptions      = LibStub"AceDBOptions-3.0"
  
  SemVer            = LibStub"SemVer"
end



local assert            = assert
local type              = type
local next              = next
local ipairs            = ipairs
local pairs             = pairs
local getmetatable      = getmetatable
local setmetatable      = setmetatable
local tonumber          = tonumber

local format            = format
local strsplit          = strsplit
local wipe              = wipe
local GetMouseFocus     = GetMouseFocus
local DoesItemExistByID = C_Item.DoesItemExistByID
local GetItemInfo       = GetItemInfo -- removes the need to bypass own hook
local UnitExists        = UnitExists
local UnitClass         = UnitClass

local strmatch          = string.match
local strfind           = string.find
local strgmatch         = string.gmatch
local strgsub           = string.gsub
local tblinsert         = table.insert
local tblremove         = table.remove
local floor             = math.floor



function Addon:GetDB()
  return self.db
end
function Addon:GetDefaultDB()
  return self.dbDefault
end
function Addon:GetProfile()
  return self:GetDB().profile
end
function Addon:GetDefaultProfile()
  return self:GetDefaultDB().profile
end
function Addon:GetGlobal()
  return self:GetDB().global
end
function Addon:GetDefaultGlobal()
  return self:GetDefaultDB().global
end
local function GetOption(self, db, ...)
  local val = db
  for _, key in ipairs{...} do
    val = val[key]
  end
  return val
end
function Addon:GetOption(...)
  return GetOption(self, self:GetProfile(), ...)
end
function Addon:GetDefaultOption(...)
  return GetOption(self, self:GetDefaultProfile(), ...)
end
function Addon:GetGlobalOption(...)
  return GetOption(self, self:GetGlobal(), ...)
end
function Addon:GetDefaultGlobalOption(...)
  return GetOption(self, self:GetDefaultGlobal(), ...)
end
local function SetOption(self, db, val, ...)
  local keys = {...}
  local lastKey = tblremove(keys, #keys)
  local tbl = db
  for _, key in ipairs(keys) do
    tbl = tbl[key]
  end
  tbl[lastKey] = val
end
function Addon:SetOption(val, ...)
  return SetOption(self, self:GetProfile(), val, ...)
end
function Addon:ResetOption(...)
  return self:SetOption(val, self:GetDefaultOption(...))
end
function Addon:SetGlobalOption(val, ...)
  return SetOption(self, self:GetGlobal(), val, ...)
end
function Addon:ResetGlobalOption(...)
  return self:SetOption(val, self:GetDefaultGlobalOption(...))
end


local UNUSABLE_EQUIPMENT = {}

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
  
do
  -- these are constants, not normal translations
  -- they are not open to interpretation, and are required whether the library is run standalone or embedded
  -- this is why they are not in a separate locale file
  local localeSubTypes = {
    ["ptBR"] = {
      ["Totems"] = "Totens",
      ["Librams"] = "Incunábulos",
      ["Thrown"] = "Bestas",
      ["Idols"] = "Ídolos",
      ["Crossbows"] = "Arremesso",
      ["Plate"] = "Placas",
      ["One-Handed Maces"] = "Maças de Uma Mão",
      ["Polearms"] = "Armas de Haste",
      ["One-Handed Axes"] = "Machados de Uma Mão",
      ["Shields"] = "Escudos",
      ["Daggers"] = "Adagas",
      ["Mail"] = "Malha",
      ["Bows"] = "Arcos",
      ["Two-Handed Swords"] = "Espadas de Duas Mãos",
      ["Staves"] = "Báculos",
      ["Leather"] = "Couro",
      ["One-Handed Swords"] = "Espadas de Uma Mão",
      ["Guns"] = "Armas de Fogo",
      ["Fist Weapons"] = "Armas de punho",
      ["Cloth"] = "Tecido",
      ["Wands"] = "Varinhas",
      ["Two-Handed Maces"] = "Maças de Duas Mãos",
      ["Two-Handed Axes"] = "Machados de Duas Mãos",
    },
    ["ruRU"] = {
      ["Totems"] = "Тотемы",
      ["Librams"] = "Манускрипты",
      ["Thrown"] = "Арбалеты",
      ["Idols"] = "Идолы",
      ["Crossbows"] = "Метательное оружие",
      ["Plate"] = "Латы",
      ["One-Handed Maces"] = "Одноручное ударное оружие",
      ["Polearms"] = "Древковое оружие",
      ["One-Handed Axes"] = "Одноручные топоры",
      ["Shields"] = "Щиты",
      ["Daggers"] = "Кинжалы",
      ["Mail"] = "Кольчуга",
      ["Bows"] = "Луки",
      ["Two-Handed Swords"] = "Двуручные мечи",
      ["Staves"] = "Посохи",
      ["Leather"] = "Кожа",
      ["One-Handed Swords"] = "Одноручные мечи",
      ["Guns"] = "Ружья",
      ["Fist Weapons"] = "Кистевое оружие",
      ["Cloth"] = "Ткань",
      ["Wands"] = "Жезлы",
      ["Two-Handed Maces"] = "Двуручное ударное оружие",
      ["Two-Handed Axes"] = "Двуручные топоры",
    },
    ["frFR"] = {
      ["Totems"] = "Totems",
      ["Librams"] = "Librams",
      ["Thrown"] = "Arbalètes",
      ["Idols"] = "Idoles",
      ["Crossbows"] = "Armes de jet",
      ["Plate"] = "Plaques",
      ["One-Handed Maces"] = "Masses à une main",
      ["Polearms"] = "Armes d'hast",
      ["Two-Handed Maces"] = "Masses à deux mains",
      ["Shields"] = "Boucliers",
      ["Bows"] = "Arcs",
      ["Cloth"] = "Tissu",
      ["Daggers"] = "Dagues",
      ["Two-Handed Swords"] = "Epées à deux mains",
      ["Staves"] = "Bâtons",
      ["Leather"] = "Cuir",
      ["One-Handed Swords"] = "Epées à une main",
      ["Guns"] = "Fusils",
      ["Fist Weapons"] = "Armes de pugilat",
      ["Mail"] = "Mailles",
      ["Wands"] = "Baguettes",
      ["One-Handed Axes"] = "Haches à une main",
      ["Two-Handed Axes"] = "Haches à deux mains",
    },
    ["koKR"] = {
      ["Totems"] = "토템",
      ["Librams"] = "성서",
      ["Thrown"] = "석궁류",
      ["Idols"] = "우상",
      ["Crossbows"] = "투척 무기류",
      ["Plate"] = "판금",
      ["One-Handed Maces"] = "한손 둔기류",
      ["Polearms"] = "장창류",
      ["Two-Handed Maces"] = "양손 둔기류",
      ["Shields"] = "방패",
      ["Bows"] = "활류",
      ["Cloth"] = "천",
      ["Daggers"] = "단검류",
      ["Two-Handed Swords"] = "양손 도검류",
      ["Staves"] = "지팡이류",
      ["Leather"] = "가죽",
      ["One-Handed Swords"] = "한손 도검류",
      ["Guns"] = "총기류",
      ["Fist Weapons"] = "장착 무기류",
      ["Mail"] = "사슬",
      ["Wands"] = "마법봉류",
      ["One-Handed Axes"] = "한손 도끼류",
      ["Two-Handed Axes"] = "양손 도끼류",
    },
    ["esMX"] = {
      ["Totems"] = "Tótems",
      ["Librams"] = "Tratados",
      ["Thrown"] = "Ballestas",
      ["Idols"] = "Ídolos",
      ["Crossbows"] = "Armas arrojadizas",
      ["Plate"] = "Placas",
      ["One-Handed Maces"] = "Mazas de una mano",
      ["Polearms"] = "Armas de asta",
      ["Two-Handed Maces"] = "Mazas de dos manos",
      ["Shields"] = "Escudos",
      ["Bows"] = "Arcos",
      ["Cloth"] = "Tela",
      ["Daggers"] = "Dagas",
      ["Two-Handed Swords"] = "Espadas de dos manos",
      ["Staves"] = "Bastones",
      ["Leather"] = "Cuero",
      ["One-Handed Swords"] = "Espadas de una mano",
      ["Guns"] = "Armas de fuego",
      ["Fist Weapons"] = "Armas de puño",
      ["Mail"] = "Malla",
      ["Wands"] = "Varitas",
      ["One-Handed Axes"] = "Hachas de una mano",
      ["Two-Handed Axes"] = "Hachas de dos manos",
    },
    ["enUS"] = {
      ["Totems"] = "Totems",
      ["Librams"] = "Librams",
      ["Thrown"] = "Crossbows",
      ["Idols"] = "Idols",
      ["Crossbows"] = "Thrown",
      ["Plate"] = "Plate",
      ["One-Handed Maces"] = "One-Handed Maces",
      ["Polearms"] = "Polearms",
      ["Two-Handed Maces"] = "Two-Handed Maces",
      ["Shields"] = "Shields",
      ["Bows"] = "Bows",
      ["Cloth"] = "Cloth",
      ["Daggers"] = "Daggers",
      ["Two-Handed Swords"] = "Two-Handed Swords",
      ["Staves"] = "Staves",
      ["Leather"] = "Leather",
      ["One-Handed Swords"] = "One-Handed Swords",
      ["Guns"] = "Guns",
      ["Fist Weapons"] = "Fist Weapons",
      ["Mail"] = "Mail",
      ["Wands"] = "Wands",
      ["One-Handed Axes"] = "One-Handed Axes",
      ["Two-Handed Axes"] = "Two-Handed Axes",
    },
    ["zhCN"] = {
      ["Totems"] = "图腾",
      ["Librams"] = "圣契",
      ["Thrown"] = "弩",
      ["Idols"] = "神像",
      ["Crossbows"] = "投掷武器",
      ["Plate"] = "板甲",
      ["One-Handed Maces"] = "单手锤",
      ["Polearms"] = "长柄武器",
      ["Two-Handed Maces"] = "双手锤",
      ["Shields"] = "盾牌",
      ["One-Handed Axes"] = "单手斧",
      ["Bows"] = "弓",
      ["Daggers"] = "匕首",
      ["Two-Handed Swords"] = "双手剑",
      ["Staves"] = "法杖",
      ["Leather"] = "皮甲",
      ["One-Handed Swords"] = "单手剑",
      ["Guns"] = "枪械",
      ["Fist Weapons"] = "拳套",
      ["Cloth"] = "布甲",
      ["Wands"] = "魔杖",
      ["Mail"] = "锁甲",
      ["Two-Handed Axes"] = "双手斧",
    },
    ["deDE"] = {
      ["Totems"] = "Totems",
      ["Librams"] = "Buchbände",
      ["Thrown"] = "Armbrüste",
      ["Idols"] = "Götzen",
      ["Crossbows"] = "Wurfwaffen",
      ["Plate"] = "Platte",
      ["One-Handed Maces"] = "Einhandstreitkolben",
      ["Polearms"] = "Stangenwaffen",
      ["Two-Handed Maces"] = "Zweihandstreitkolben",
      ["Shields"] = "Schilde",
      ["Bows"] = "Bogen",
      ["Cloth"] = "Stoff",
      ["Daggers"] = "Dolche",
      ["Two-Handed Swords"] = "Zweihandschwerter",
      ["Staves"] = "Stäbe",
      ["Leather"] = "Leder",
      ["One-Handed Swords"] = "Einhandschwerter",
      ["Guns"] = "Schusswaffen",
      ["Fist Weapons"] = "Faustwaffen",
      ["Mail"] = "Schwere Rüstung",
      ["Wands"] = "Zauberstäbe",
      ["One-Handed Axes"] = "Einhandäxte",
      ["Two-Handed Axes"] = "Zweihandäxte",
    },
    ["zhTW"] = {
      ["Totems"] = "圖騰",
      ["Librams"] = "聖契",
      ["Thrown"] = "弩",
      ["Idols"] = "塑像",
      ["Crossbows"] = "投擲武器",
      ["Plate"] = "鎧甲",
      ["One-Handed Maces"] = "單手錘",
      ["Polearms"] = "長柄武器",
      ["Mail"] = "鎖甲",
      ["Shields"] = "盾牌",
      ["One-Handed Axes"] = "單手斧",
      ["Daggers"] = "匕首",
      ["Bows"] = "弓",
      ["Two-Handed Swords"] = "雙手劍",
      ["Staves"] = "法杖",
      ["Leather"] = "皮甲",
      ["One-Handed Swords"] = "單手劍",
      ["Guns"] = "槍械",
      ["Fist Weapons"] = "拳套",
      ["Cloth"] = "布甲",
      ["Wands"] = "魔杖",
      ["Two-Handed Maces"] = "雙手錘",
      ["Two-Handed Axes"] = "雙手斧",
    },
    ["esES"] = {
      ["Totems"] = "Tótems",
      ["Librams"] = "Tratados",
      ["Thrown"] = "Ballestas",
      ["Idols"] = "Ídolos",
      ["Crossbows"] = "Armas arrojadizas",
      ["Plate"] = "Placas",
      ["One-Handed Maces"] = "Mazas de una mano",
      ["Polearms"] = "Armas de asta",
      ["One-Handed Axes"] = "Hachas de una mano",
      ["Shields"] = "Escudos",
      ["Daggers"] = "Dagas",
      ["Mail"] = "Malla",
      ["Bows"] = "Arcos",
      ["Two-Handed Swords"] = "Espadas de dos manos",
      ["Staves"] = "Bastones",
      ["Leather"] = "Cuero",
      ["One-Handed Swords"] = "Espadas de una mano",
      ["Guns"] = "Armas de fuego",
      ["Fist Weapons"] = "Armas de puño",
      ["Cloth"] = "Tela",
      ["Wands"] = "Varitas",
      ["Two-Handed Maces"] = "Mazas de dos manos",
      ["Two-Handed Axes"] = "Hachas de dos manos",
    },
  }
  local translate = localeSubTypes[GetLocale()]
  if not translate then translate = localeSubTypes["enUS"] end

  local localeArmorTypes = {MISCELLANEOUS}
  for _, subType in ipairs{"Cloth", "Leather", "Mail", "Plate", "Shields", "Librams", "Idols", "Totems"} do
    tblinsert(localeArmorTypes, translate[subType])
  end
  
  local usableArmor = {}
  usableArmor[CLASS_MAP_TO_ID.WARRIOR] = {[translate["Leather"]] = true, [translate["Mail"]] = true, [translate["Plate"]] = true, [translate["Shields"]] = true}
  usableArmor[CLASS_MAP_TO_ID.ROGUE]   = {[translate["Leather"]] = true}
  usableArmor[CLASS_MAP_TO_ID.MAGE]    = {}
  usableArmor[CLASS_MAP_TO_ID.PRIEST]  = {}
  usableArmor[CLASS_MAP_TO_ID.WARLOCK] = {}
  usableArmor[CLASS_MAP_TO_ID.HUNTER]  = {[translate["Leather"]] = true, [translate["Mail"]] = true}
  usableArmor[CLASS_MAP_TO_ID.DRUID]   = {[translate["Leather"]] = true, [translate["Idols"]] = true}
  usableArmor[CLASS_MAP_TO_ID.SHAMAN]  = {[translate["Leather"]] = true, [translate["Mail"]] = true, [translate["Shields"]] = true, [translate["Totems"]] = true}
  usableArmor[CLASS_MAP_TO_ID.PALADIN] = {[translate["Leather"]] = true, [translate["Mail"]] = true, [translate["Plate"]] = true, [translate["Shields"]] = true, [translate["Librams"]] = true}
  
  for _, usableArmorTypes in pairs(usableArmor) do
    usableArmorTypes[MISCELLANEOUS]      = true
    usableArmorTypes[translate["Cloth"]] = true
  end
  for class in pairs(usableArmor) do
    UNUSABLE_EQUIPMENT[class] = {
      [ARMOR]  = {},
      [WEAPON] = {},
    }
    for _, armorType in ipairs(localeArmorTypes) do
      UNUSABLE_EQUIPMENT[class][ARMOR][armorType] = not usableArmor[class][armorType]
    end
  end
  
  local function SetClassWeapons(class, ...)
    local class = CLASS_MAP_TO_ID[class]
    for _, weapon in ipairs{...} do
      UNUSABLE_EQUIPMENT[class][WEAPON][translate[weapon]] = nil
    end
  end
  
  local localeWeaponTypes = {}
  for _, subType in ipairs{"Two-Handed Axes", "One-Handed Axes", "Two-Handed Swords", "One-Handed Swords",
                           "Two-Handed Maces", "One-Handed Maces", "Polearms", "Staves", "Daggers",
                           "Fist Weapons", "Bows", "Crossbows", "Guns", "Thrown", "Wands"} do
    tblinsert(localeWeaponTypes, translate[subType])
  end
  
  for class in pairs(usableArmor) do
    for _, weapon in ipairs(localeWeaponTypes) do
      UNUSABLE_EQUIPMENT[class][WEAPON][weapon] = true
    end
  end
  
  SetClassWeapons("DRUID",   "Two-Handed Maces", "One-Handed Maces", "Staves", "Daggers", "Fist Weapons")
  SetClassWeapons("HUNTER",  "Two-Handed Axes", "One-Handed Axes", "Two-Handed Swords", "One-Handed Swords",
                             "Polearms", "Staves", "Daggers", "Fist Weapons", "Bows", 
                             "Crossbows", "Guns", "Thrown")
  SetClassWeapons("MAGE",    "One-Handed Swords", "Staves", "Daggers", "Wands")
  SetClassWeapons("PALADIN", "Two-Handed Axes", "One-Handed Axes", "Two-Handed Swords", "One-Handed Swords",
                             "Two-Handed Maces", "One-Handed Maces", "Polearms")
  SetClassWeapons("PRIEST",  "One-Handed Maces", "Staves", "Daggers", "Wands")
  SetClassWeapons("ROGUE",   "One-Handed Swords", "One-Handed Maces", "Daggers", "Fist Weapons",
                             "Bows", "Crossbows", "Guns", "Thrown")
  SetClassWeapons("SHAMAN",  "Two-Handed Axes", "One-Handed Axes", "Two-Handed Maces", "One-Handed Maces",
                             "Staves", "Daggers", "Fist Weapons")
  SetClassWeapons("WARLOCK", "One-Handed Swords", "Staves", "Daggers", "Wands")
  SetClassWeapons("WARRIOR", "Two-Handed Axes", "One-Handed Axes", "Two-Handed Swords", "One-Handed Swords",
                             "Two-Handed Maces", "One-Handed Maces", "Polearms", "Staves", "Daggers", "Fist Weapons", 
                             "Bows", "Crossbows", "Guns", "Thrown")
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
  __tostring  = function(self) return "Item " .. self:GetID() end,
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
    if not item:GetSuffix() then
      storage[item:GetID()] = {[0] = private(item)}
    end
  elseif item:GetSuffix() and not storage[item:GetID()][item:GetSuffix()] then -- only store suffix items if the suffix matters
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
    self.tooltipScanner = CreateFrame("GameTooltip", "ItemCachetooltipScanner", UIParent, "GameTooltipTemplate")
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
  return self:GetSuffix() ~= nil
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
      
      ItemDB.tooltipScanner:SetOwner(UIParent, "ANCHOR_NONE")
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



function Item:IsUsableBy(classOrUnit)
  if not self:IsCached() then return nil end
  local id = CLASS_MAP_TO_ID[classOrUnit]
  if not id and UnitExists(classOrUnit) then
    local className, classFile, classID = UnitClass(classOrUnit)
    id = classID
  end
  local classesAllowed = private(self).classesAllowed
  if classesAllowed then
    return classesAllowed[id] or false
  end
  local itemType, itemSubType = self:GetTypeSubType()
  if itemType and itemSubType then
    if UNUSABLE_EQUIPMENT[id][itemType] and UNUSABLE_EQUIPMENT[id][itemType][itemSubType] then
      return false
    end
  end
  return true
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
  return (select(5, GetItemInfoInstant(self:GetString())))
end
Item.GetIcon = Item.GetTexture
function Item:GetNameLinkTexture()
  local name, link, _, _, _, _, _, _, _, texture = self:GetInfo()
  return name, link, texture
end
Item.GetNameLinkIcon = Item.GetNameLinkTexture

function Item:GetType()
  return (select(2, GetItemInfoInstant(self:GetString())))
end
function Item:GetSubType()
  return (select(3, GetItemInfoInstant(self:GetString())))
end
function Item:GetTypeSubType()
  local _, itemType, itemSubType = GetItemInfoInstant(self:GetString())
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
  return (select(4, GetItemInfoInstant(self:GetString())))
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
  self:OpenConfig(ADDON_NAME, true)
end

function Addon:OpenConfig(category, expandSection)
  InterfaceAddOnsList_Update()
  InterfaceOptionsFrame_OpenToCategory(category)
  
  if expandSection then
    -- Expand config if it's collapsed
    local i = 1
    while _G["InterfaceOptionsFrameAddOnsButton"..i] do
      local frame = _G["InterfaceOptionsFrameAddOnsButton"..i]
      if frame.element then
        if frame.element.name == ADDON_NAME then
          if frame.element.hasChildren and frame.element.collapsed then
            if _G["InterfaceOptionsFrameAddOnsButton"..i.."Toggle"] and _G["InterfaceOptionsFrameAddOnsButton"..i.."Toggle"].Click then
              _G["InterfaceOptionsFrameAddOnsButton"..i.."Toggle"]:Click()
              break
            end
          end
          break
        end
      end
      i = i + 1
    end
  end
end
function Addon:MakeDefaultFunc(category)
  return function()
    self:GetDB():ResetProfile()
    self:InitDB()
    self:Printf(L["Profile reset to default."])
    AceConfigRegistry:NotifyChange(category)
  end
end
function Addon:CreateOptionsCategory(categoryName, options)
  local category = ADDON_NAME
  if categoryName then
    category = ("%s.%s"):format(category, categoryName)
  end
  AceConfig:RegisterOptionsTable(category, options)
  local Panel = AceConfigDialog:AddToBlizOptions(category, categoryName, categoryName and ADDON_NAME or nil)
  Panel.default = self:MakeDefaultFunc(category)
  return Panel
end

function Addon:RefreshOptions()
  Data:RefreshOptionsTable(ADDON_NAME, self, L)
  
  AceConfigRegistry:NotifyChange(ADDON_NAME)
end

function Addon:CreateOptions()
  self.Options = {}
  
  self:CreateOptionsCategory(nil, Data:RefreshOptionsTable(ADDON_NAME, self, L))
  
  if self:GetOption("Debug", "menu") then
    self:CreateOptionsCategory("Debug" , Data:MakeDebugOptionsTable("Debug", self, L))
  end
end

function Addon:InitDB()
  local configVersion = SemVer(self:GetOption"_VERSION" or tostring(self.Version))
  if configVersion < self.Version then
    -- Update data schema here
  end
  self:SetOption(tostring(self.Version), "_VERSION")
end


function Addon:OnInitialize()
  self.Version   = SemVer(GetAddOnMetadata(ADDON_NAME, "Version"))
  self.db        = AceDB:New(("%sDB"):format(ADDON_NAME)        , Data:MakeDefaultOptions(), true)
  self.dbDefault = AceDB:New(("%sDB_Default"):format(ADDON_NAME), Data:MakeDefaultOptions(), true)
  
  self:RegisterChatCommand(Data.CHAT_COMMAND, "OnChatCommand", true)
  
  ItemDB:Init()
end

function Addon:OnEnable()
  self:InitDB()
  self:GetDB().RegisterCallback(self, "OnProfileChanged", "InitDB")
  self:GetDB().RegisterCallback(self, "OnProfileCopied" , "InitDB")
  self:GetDB().RegisterCallback(self, "OnProfileReset"  , "InitDB")
  
  self:CreateOptions()
end

function Addon:OnDisable()
end




if not IsStandalone then
  ItemDB:Init()
end





