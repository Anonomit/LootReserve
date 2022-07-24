LootReserve = LootReserve or { };
LootReserve.Constants = { };

LootReserve.Constants.MAX_RESERVES          = 99;
LootReserve.Constants.MAX_MULTIRESERVES     = 99;
LootReserve.Constants.MAX_RESERVES_PER_ITEM = 99;
LootReserve.Constants.MAX_CHAT_STORAGE      = 25;

LootReserve.Constants.ReserveResult = {
    OK                       = 0,
    NotInRaid                = 1,
    NoSession                = 2,
    NotAccepting             = 3,
    NotMember                = 4,
    ItemNotReservable        = 5,
    AlreadyReserved          = 6,
    NoReservesLeft           = 7,
    FailedConditions         = 8,
    Locked                   = 9,
    NotEnoughReservesLeft    = 10,
    MultireserveLimit        = 11,
    MultireserveLimitPartial = 12,
    FailedClass              = 13,
    FailedFaction            = 14,
    FailedLimit              = 15,
    FailedLimitPartial       = 16,
    FailedUsable             = 17,
};
LootReserve.Constants.CancelReserveResult = {
    OK                = 0,
    NotInRaid         = 1,
    NoSession         = 2,
    NotAccepting      = 3,
    NotMember         = 4,
    ItemNotReservable = 5,
    NotReserved       = 6,
    Forced            = 7,
    Locked            = 8,
    InternalError     = 9,
    NotEnoughReserves = 10,
};
LootReserve.Constants.OptResult = {
    OK                = 0,
    NotInRaid         = 1,
    NoSession         = 2,
    NotMember         = 4,
};
LootReserve.Constants.ReserveDeltaResult = {
    NoSession         = 2,
    NotMember         = 4,
};
LootReserve.Constants.ReservesSorting = {
    ByTime   = 0,
    ByName   = 1,
    BySource = 2,
    ByLooter = 3,
};
LootReserve.Constants.WinnerReservesRemoval = {
    None      = 0,
    Single    = 1,
    Smart     = 2,
    All       = 3,
    Duplicate = 4,
};
LootReserve.Constants.ChatReservesListLimit = {
    None = -1,
};
LootReserve.Constants.ChatAnnouncement = {
    SessionStart        = 1,
    SessionResume       = 2,
    SessionStop         = 3,
    RollStartReserved   = 4,
    RollStartCustom     = 5,
    RollWinner          = 6,
    RollTie             = 7,
    SessionInstructions = 8,
    RollCountdown       = 9,
    SessionBlindToggle  = 10,
    SessionReserves     = 11,
};
LootReserve.Constants.DefaultPhases = {
    "MainSpec",
    "OffSpec",
    "Learning",
    "Quest",
    "Reputation",
    "Profession",
    "Looks",
    "Vendor",
};
LootReserve.Constants.WonRollPhase = {
    Reserve  = 1,
    RaidRoll = 2,
};
LootReserve.Constants.RollType = {
    NotRolled = 0,
    Passed    = -1,
    Deleted   = -2,
};
LootReserve.Constants.LoadState = {
    NotStarted  = 0,
    Started     = 1,
    SessionDone = 2,
    Pending     = 3,
    AllDone     = 4,
};
LootReserve.Constants.ClassFilenameToClassID   = { };
LootReserve.Constants.ClassLocalizedToFilename = { };
LootReserve.Constants.ItemQuality = {
    [-1] = "All",
    [0]  = "Junk",
    [1]  = "Common",
    [2]  = "Uncommon",
    [3]  = "Rare",
    [4]  = "Epic",
    [5]  = "Legendary",
    [6]  = "Artifact",
    [7]  = "Heirloom",
    [99] = "None",
};
LootReserve.Constants.RedundantSubTypes = {
    ["Polearms"]  = "Polearm",
    ["Staves"]    = "Staff",
    ["Bows"]      = "Bow",
    ["Crossbows"] = "Crossbow",
    ["Guns"]      = "Gun",
    ["Thrown"]    = "Thrown Weapon",
    ["Wands"]     = "Wand",
    ["Relic"]     = "Relic",
    
    ["Shields"]   = "Shield",
    ["Idols"]     = "Idol",
    ["Librams"]   = "Libram",
    ["Totems"]    = "Totem",
    ["Sigils"]    = "Sigil",
};
LootReserve.Constants.WeaponTypeNames = {
    ["Two-Handed Axes"]   = "Axe",
    ["One-Handed Axes"]   = "Axe",
    ["Two-Handed Swords"] = "Sword",
    ["One-Handed Swords"] = "Sword",
    ["Two-Handed Maces"]  = "Mace",
    ["One-Handed Maces"]  = "Mace",
    ["Polearms"]          = "Polearm",
    ["Staves"]            = "Staff",
    ["Daggers"]           = "Dagger",
    ["Fist Weapons"]      = "Fist Weapon",
    ["Bows"]              = "Bow",
    ["Crossbows"]         = "Crossbow",
    ["Guns"]              = "Gun",
    ["Thrown"]            = "Thrown Weapon",
    ["Wands"]             = "Wand",
};
LootReserve.Constants.Genders = {
    Male   = 2,
    Female = 3,
};
LootReserve.Constants.Races = {
    Human    = 1,
    Dwarf    = 3,
    Gnome    = 7,
    NightElf = 4,
    Orc      = 2,
    Troll    = 8,
    Tauren   = 6,
    Scourge  = 5,
    Draenei  = 11,
    BloodElf = 10,
    Worgen   = 22,
    Goblin   = 9,
};
LootReserve.Constants.Sounds = {
    LevelUp = 1440,
    Cheer = {
        [LootReserve.Constants.Races.Human]    = {[LootReserve.Constants.Genders.Male] = 2677, [LootReserve.Constants.Genders.Female] = 2689},
        [LootReserve.Constants.Races.Dwarf]    = {[LootReserve.Constants.Genders.Male] = 2725, [LootReserve.Constants.Genders.Female] = 2737},
        [LootReserve.Constants.Races.Gnome]    = {[LootReserve.Constants.Genders.Male] = 2835, [LootReserve.Constants.Genders.Female] = 2847},
        [LootReserve.Constants.Races.NightElf] = {[LootReserve.Constants.Genders.Male] = 2749, [LootReserve.Constants.Genders.Female] = 2761},
        [LootReserve.Constants.Races.Orc]      = {[LootReserve.Constants.Genders.Male] = 2701, [LootReserve.Constants.Genders.Female] = 2713},
        [LootReserve.Constants.Races.Troll]    = {[LootReserve.Constants.Genders.Male] = 2859, [LootReserve.Constants.Genders.Female] = 2871},
        [LootReserve.Constants.Races.Tauren]   = {[LootReserve.Constants.Genders.Male] = 2797, [LootReserve.Constants.Genders.Female] = 2810},
        [LootReserve.Constants.Races.Scourge]  = {[LootReserve.Constants.Genders.Male] = 2773, [LootReserve.Constants.Genders.Female] = 2785},
        [LootReserve.Constants.Races.Draenei]  = {[LootReserve.Constants.Genders.Male] = 9706, [LootReserve.Constants.Genders.Female] = 9681},
        [LootReserve.Constants.Races.BloodElf] = {[LootReserve.Constants.Genders.Male] = 9656, [LootReserve.Constants.Genders.Female] = 9632},
    },
    Congratulate = {
        [LootReserve.Constants.Races.Human]    = {[LootReserve.Constants.Genders.Male] = 6168, [LootReserve.Constants.Genders.Female] = 6141},
        [LootReserve.Constants.Races.Dwarf]    = {[LootReserve.Constants.Genders.Male] = 6113, [LootReserve.Constants.Genders.Female] = 6104},
        [LootReserve.Constants.Races.Gnome]    = {[LootReserve.Constants.Genders.Male] = 6131, [LootReserve.Constants.Genders.Female] = 6122},
        [LootReserve.Constants.Races.NightElf] = {[LootReserve.Constants.Genders.Male] = 6186, [LootReserve.Constants.Genders.Female] = 6177},
        [LootReserve.Constants.Races.Orc]      = {[LootReserve.Constants.Genders.Male] = 6366, [LootReserve.Constants.Genders.Female] = 6357},
        [LootReserve.Constants.Races.Troll]    = {[LootReserve.Constants.Genders.Male] = 6402, [LootReserve.Constants.Genders.Female] = 6393},
        [LootReserve.Constants.Races.Tauren]   = {[LootReserve.Constants.Genders.Male] = 6384, [LootReserve.Constants.Genders.Female] = 6375},
        [LootReserve.Constants.Races.Scourge]  = {[LootReserve.Constants.Genders.Male] = 6420, [LootReserve.Constants.Genders.Female] = 6411},
        [LootReserve.Constants.Races.Draenei]  = {[LootReserve.Constants.Genders.Male] = 9707, [LootReserve.Constants.Genders.Female] = 9682},
        [LootReserve.Constants.Races.BloodElf] = {[LootReserve.Constants.Genders.Male] = 9657, [LootReserve.Constants.Genders.Female] = 9641},
    },
    Cry = {
        [LootReserve.Constants.Races.Human]    = {[LootReserve.Constants.Genders.Male] = 6921, [LootReserve.Constants.Genders.Female] = 6916},
        [LootReserve.Constants.Races.Dwarf]    = {[LootReserve.Constants.Genders.Male] = 6901, [LootReserve.Constants.Genders.Female] = 6895},
        [LootReserve.Constants.Races.Gnome]    = {[LootReserve.Constants.Genders.Male] = 6911, [LootReserve.Constants.Genders.Female] = 6906},
        [LootReserve.Constants.Races.NightElf] = {[LootReserve.Constants.Genders.Male] = 6931, [LootReserve.Constants.Genders.Female] = 6926},
        [LootReserve.Constants.Races.Orc]      = {[LootReserve.Constants.Genders.Male] = 6941, [LootReserve.Constants.Genders.Female] = 6936},
        [LootReserve.Constants.Races.Troll]    = {[LootReserve.Constants.Genders.Male] = 6961, [LootReserve.Constants.Genders.Female] = 6956},
        [LootReserve.Constants.Races.Tauren]   = {[LootReserve.Constants.Genders.Male] = 6951, [LootReserve.Constants.Genders.Female] = 6946},
        [LootReserve.Constants.Races.Scourge]  = {[LootReserve.Constants.Genders.Male] = 6972, [LootReserve.Constants.Genders.Female] = 6967},
        [LootReserve.Constants.Races.Draenei]  = {[LootReserve.Constants.Genders.Male] = 9701, [LootReserve.Constants.Genders.Female] = 9676},
        [LootReserve.Constants.Races.BloodElf] = {[LootReserve.Constants.Genders.Male] = 9651, [LootReserve.Constants.Genders.Female] = 9647},
    },
};
LootReserve.Constants.LocomotionPhrases = {
    "Advance",
    "Amble",
    "Apparate",
    "Aviate",
    -- "Backpack",
    "Bike",
    "Bolt",
    -- "Bounce",
    -- "Bound",
    -- "Bowl",
    "Briskly Jog",
    "Canter",
    -- "Carom",
    "Carpool",
    "Cartwheel",
    "Catapult",
    -- "Cavort",
    "Charge",
    -- "Clamber",
    -- "Climb",
    -- "Clump",
    -- "Coast",
    "Commute",
    "Corporealize",
    "Crawl",
    -- "Creep",
    "Cycle",
    "Breakdance",
    "Dart",
    "Dash",
    "Dig",
    -- "Dodder",
    "Drift",
    "Drive",
    "Embark",
    "Engage Warp",
    -- "File",
    -- "Flit",
    -- "Float",
    "Fly",
    -- "Frolic",
    -- "FTL Warp",
    "Gallop",
    -- "Gambol",
    "Glide",
    "Go Fast",
    "Goosestep",
    "Hang Glide",
    "Hasten",
    "Hike",
    "Hobble",
    "Hop",
    "Hurry",
    "Hurtle",
    -- "Inch",
    "Jog",
    "Journey",
    "Jump",
    "Leap",
    "Limp",
    "Locomote",
    "Lollop",
    "Lope",
    -- "Lumber",
    "Lurch",
    "March",
    "Materialize",
    "Meander",
    -- "Mince",
    "Moonwalk",
    "Mosey",
    -- "Nip",
    -- "Pad",
    "Paddle",
    -- "Parade",
    "Perambulate", "Perambulate", "Perambulate", "Perambulate", "Perambulate", "Perambulate", "Perambulate", "Perambulate", "Perambulate", "Perambulate",
    "Plod",
    "Prance",
    -- "Promenade",
    "Prowl",
    "Race",
    -- "Ramble",
    "Reverse",
    -- "Roam",
    "Roll",
    -- "Romp",
    "Rove",
    "Row",
    "Run",
    "Rush",
    "Sail",
    "Sashay",
    "Saunter",
    "Scamper",
    "Scoot",
    "Scram",
    "Scramble",
    -- "Scud",
    "Scurry",
    -- "Scutter",
    "Scuttle",
    "Shamble",
    -- "Shuffle",
    "Sidle",
    "Skedaddle",
    "Ski",
    -- "Skip",
    "Skitter",
    "Skulk",
    "Sleepwalk",
    "Slide",
    "Slink",
    "Slippy Slide",
    "Slither",
    -- "Slog",
    -- "Slouch",
    "Sneak",
    "Somersault",
    -- "Speed",
    "Speedwalk",
    -- "Stagger",
    -- "Stomp",
    -- "Stray",
    "Streak",
    "Stride",
    "Stroll",
    "Strut",
    -- "Stumble",
    -- "Stump",
    -- "Swagger",
    -- "Sweep",
    "Swim",
    -- "Tack",
    "Taxi",
    -- "Tear",
    "Teleport",
    "Tiptoe",
    "Toddle",
    "Totter",
    "Traipse",
    -- "Tramp",
    "Travel",
    "Trek",
    -- "Troop",
    "Trot",
    -- "Trudge",
    -- "Trundle",
    "Tunnel",
    -- "Vault",
    "Velocitize",
    "Vibrate",
    "Waddle",
    "Wade",
    "Walk",
    "Wander",
    -- "Warp",
    "Water Ski",
    "Water Walk",
    -- "Whiz",
    "Zigzag",
    "Zoom",
};

local result = LootReserve.Constants.ReserveResult;
LootReserve.Constants.ReserveResultText =
{
    [result.OK]                       = "",
    [result.NotInRaid]                = "You are not in the raid",
    [result.NoSession]                = "Loot reserves aren't active",
    [result.NotAccepting]             = "Loot reserves are not currently being accepted",
    [result.NotMember]                = "You are not participating in loot reserves",
    [result.ItemNotReservable]        = "That item is not reservable",
    [result.AlreadyReserved]          = "You are already reserving that item",
    [result.NoReservesLeft]           = "You are at your reserve limit",
    [result.FailedConditions]         = "You cannot reserve that item",
    [result.Locked]                   = "Your reserves are locked in and cannot be changed",
    [result.NotEnoughReservesLeft]    = "You don't have enough reserves to do that",
    [result.MultireserveLimit]        = "You cannot reserve that item more times",
    [result.MultireserveLimitPartial] = "Not all of your reserves were accepted because you reached the limit of how many times you are allowed to reserve a single item",
    [result.FailedClass]              = "Your class cannot reserve that item",
    [result.FailedFaction]            = "Your faction cannot reserve that item",
    [result.FailedLimit]              = "That item has reached the limit of reserves",
    [result.FailedLimitPartial]       = "Not all of your reserves were accepted because the item reached the limit of reserves",
    [result.FailedUsable]             = "You may not reserve unusable items",
};

local result = LootReserve.Constants.CancelReserveResult;
LootReserve.Constants.CancelReserveResultText =
{
    [result.OK]                = "",
    [result.NotInRaid]         = "You are not in the raid",
    [result.NoSession]         = "Loot reserves aren't active",
    [result.NotAccepting]      = "Loot reserves are not currently being accepted",
    [result.NotMember]         = "You are not participating in loot reserves",
    [result.ItemNotReservable] = "That item is not reservable",
    [result.NotReserved]       = "You did not reserve that item",
    [result.Forced]            = "",
    [result.Locked]            = "Your reserves are locked in and cannot be changed",
    [result.InternalError]     = "Internal error",
    [result.NotEnoughReserves] = "You don't have that many reserves on that item",
};

local result = LootReserve.Constants.OptResult;
LootReserve.Constants.OptResultText =
{
    [result.OK]                       = "",
    [result.NotInRaid]                = "You are not in the raid",
    [result.NoSession]                = "Loot reserves aren't active",
    [result.NotMember]                = "You are not participating in loot reserves",
};

local result = LootReserve.Constants.ReserveDeltaResult;
LootReserve.Constants.ReserveDeltaResultText =
{
    [result.NoSession]         = "Loot reserves aren't active",
    [result.NotMember]         = "You are not participating in loot reserves",
};

local enum = LootReserve.Constants.ReservesSorting;
LootReserve.Constants.ReservesSortingText =
{
    [enum.ByTime]   = "By Time",
    [enum.ByName]   = "By Item Name",
    [enum.BySource] = "By Boss",
    [enum.ByLooter] = "By Looter",
};

local enum = LootReserve.Constants.WinnerReservesRemoval;
LootReserve.Constants.WinnerReservesRemovalText =
{
    [enum.None]      = "None",
    [enum.Single]    = "Just one",
    [enum.Duplicate] = "Duplicate",
    [enum.All]       = "All",
    [enum.Smart]     = "Smart",
};

local enum = LootReserve.Constants.ChatReservesListLimit;
LootReserve.Constants.ChatReservesListLimitText =
{
    [enum.None] = "None",
};

local enum = LootReserve.Constants.WonRollPhase;
LootReserve.Constants.WonRollPhaseText =
{
    [enum.Reserve]  = "Reserve",
    [enum.RaidRoll] = "Raid-Roll",
};

for i = 1, LootReserve:GetNumClasses() do
    local name, file, id = LootReserve:GetClassInfo(i);
    if file and id then
        LootReserve.Constants.ClassFilenameToClassID[file] = id;
    end
end
for filename, localized in pairs(LOCALIZED_CLASS_NAMES_MALE) do
    LootReserve.Constants.ClassLocalizedToFilename[localized] = filename;
end
for filename, localized in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
    LootReserve.Constants.ClassLocalizedToFilename[localized] = filename;
end
for localized, filename in pairs(LootReserve.Constants.ClassLocalizedToFilename) do
    LootReserve.Constants.ClassLocalizedToFilename[localized:lower()] = filename;
end
