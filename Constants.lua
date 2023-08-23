LootReserve = LootReserve or { };
LootReserve.Constants = { };

LootReserve.Constants.MAX_RESERVES          = 99;
LootReserve.Constants.MAX_MULTIRESERVES     = 99;
LootReserve.Constants.MAX_RESERVES_PER_ITEM = 99;
LootReserve.Constants.MAX_CHAT_STORAGE      = 25;
LootReserve.Constants.MAX_PHASES            = 100;

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
    "Main Spec",
    "Off Spec",
    "Collection",
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
LootReserve.Constants.ItemLevelInvTypeWhitelist = setmetatable({
    [""]           = false,
    INVTYPE_BAG    = false,
    INVTYPE_TABARD = false,
    INVTYPE_BODY   = false,
}, { __index = function() return true end });
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
    -- "Corporealize",
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
    "Translocate",
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

(function()
    local input, output = LootReserve.Constants, "Sounds";
    setfenv(1, setmetatable({ Constants = LootReserve.Constants }, { __index = function(t, k) return input[k] end }));
    Constants[output] =
    {
        LevelUp = 1440,
        Cheer = {
            [Races.Human]    = {[Genders.Male] = 2677, [Genders.Female] = 2689},
            [Races.Dwarf]    = {[Genders.Male] = 2725, [Genders.Female] = 2737},
            [Races.Gnome]    = {[Genders.Male] = 2835, [Genders.Female] = 2847},
            [Races.NightElf] = {[Genders.Male] = 2749, [Genders.Female] = 2761},
            [Races.Orc]      = {[Genders.Male] = 2701, [Genders.Female] = 2713},
            [Races.Troll]    = {[Genders.Male] = 2859, [Genders.Female] = 2871},
            [Races.Tauren]   = {[Genders.Male] = 2797, [Genders.Female] = 2810},
            [Races.Scourge]  = {[Genders.Male] = 2773, [Genders.Female] = 2785},
            [Races.Draenei]  = {[Genders.Male] = 9706, [Genders.Female] = 9681},
            [Races.BloodElf] = {[Genders.Male] = 9656, [Genders.Female] = 9632},
        },
        Congratulate = {
            [Races.Human]    = {[Genders.Male] = 6168, [Genders.Female] = 6141},
            [Races.Dwarf]    = {[Genders.Male] = 6113, [Genders.Female] = 6104},
            [Races.Gnome]    = {[Genders.Male] = 6131, [Genders.Female] = 6122},
            [Races.NightElf] = {[Genders.Male] = 6186, [Genders.Female] = 6177},
            [Races.Orc]      = {[Genders.Male] = 6366, [Genders.Female] = 6357},
            [Races.Troll]    = {[Genders.Male] = 6402, [Genders.Female] = 6393},
            [Races.Tauren]   = {[Genders.Male] = 6384, [Genders.Female] = 6375},
            [Races.Scourge]  = {[Genders.Male] = 6420, [Genders.Female] = 6411},
            [Races.Draenei]  = {[Genders.Male] = 9707, [Genders.Female] = 9682},
            [Races.BloodElf] = {[Genders.Male] = 9657, [Genders.Female] = 9641},
        },
        Cry = {
            [Races.Human]    = {[Genders.Male] = 6921, [Genders.Female] = 6916},
            [Races.Dwarf]    = {[Genders.Male] = 6901, [Genders.Female] = 6895},
            [Races.Gnome]    = {[Genders.Male] = 6911, [Genders.Female] = 6906},
            [Races.NightElf] = {[Genders.Male] = 6931, [Genders.Female] = 6926},
            [Races.Orc]      = {[Genders.Male] = 6941, [Genders.Female] = 6936},
            [Races.Troll]    = {[Genders.Male] = 6961, [Genders.Female] = 6956},
            [Races.Tauren]   = {[Genders.Male] = 6951, [Genders.Female] = 6946},
            [Races.Scourge]  = {[Genders.Male] = 6972, [Genders.Female] = 6967},
            [Races.Draenei]  = {[Genders.Male] = 9701, [Genders.Female] = 9676},
            [Races.BloodElf] = {[Genders.Male] = 9651, [Genders.Female] = 9647},
        },
    };
end)();

(function()
    local input, output = LootReserve.Constants.ReserveResult, "ReserveResultText";
    setfenv(1, setmetatable({ Constants = LootReserve.Constants }, { __index = function(t, k) return input[k] end }));
    Constants[output] =
    {
        [OK]                       = "",
        [NotInRaid]                = "You are not in the raid",
        [NoSession]                = "Loot reserves aren't active",
        [NotAccepting]             = "Loot reserves are not currently being accepted",
        [NotMember]                = "You are not participating in loot reserves",
        [ItemNotReservable]        = "That item is not reservable",
        [AlreadyReserved]          = "You are already reserving that item",
        [NoReservesLeft]           = "You are at your reserve limit",
        [FailedConditions]         = "You cannot reserve that item",
        [Locked]                   = "Your reserves are locked in and cannot be changed",
        [NotEnoughReservesLeft]    = "You don't have enough reserves to do that",
        [MultireserveLimit]        = "You cannot reserve that item more times",
        [MultireserveLimitPartial] = "Not all of your reserves were accepted because you reached the limit of how many times you are allowed to reserve a single item",
        [FailedClass]              = "Your class cannot reserve that item",
        [FailedFaction]            = "Your faction cannot reserve that item",
        [FailedLimit]              = "That item has reached the limit of reserves",
        [FailedLimitPartial]       = "Not all of your reserves were accepted because the item reached the limit of reserves",
        [FailedUsable]             = "You may not reserve unusable items",
    };
end)();

(function()
    local input, output = LootReserve.Constants.CancelReserveResult, "CancelReserveResultText";
    setfenv(1, setmetatable({ Constants = LootReserve.Constants }, { __index = function(t, k) return input[k] end }));
    Constants[output] =
    {
        [OK]                = "",
        [NotInRaid]         = "You are not in the raid",
        [NoSession]         = "Loot reserves aren't active",
        [NotAccepting]      = "Loot reserves are not currently being accepted",
        [NotMember]         = "You are not participating in loot reserves",
        [ItemNotReservable] = "That item is not reservable",
        [NotReserved]       = "You did not reserve that item",
        [Forced]            = "",
        [Locked]            = "Your reserves are locked in and cannot be changed",
        [InternalError]     = "Internal error",
        [NotEnoughReserves] = "You don't have that many reserves on that item",
    };
end)();

(function()
    local input, output = LootReserve.Constants.OptResult, "OptResultText";
    setfenv(1, setmetatable({ Constants = LootReserve.Constants }, { __index = function(t, k) return input[k] end }));
    Constants[output] =
    {
        [OK]                       = "",
        [NotInRaid]                = "You are not in the raid",
        [NoSession]                = "Loot reserves aren't active",
        [NotMember]                = "You are not participating in loot reserves",
    };
end)();

(function()
    local input, output = LootReserve.Constants.ReserveDeltaResult, "ReserveDeltaResultText";
    setfenv(1, setmetatable({ Constants = LootReserve.Constants }, { __index = function(t, k) return input[k] end }));
    Constants[output] =
    {
        [NoSession]         = "Loot reserves aren't active",
        [NotMember]         = "You are not participating in loot reserves",
    };
end)();

(function()
    local input, output = LootReserve.Constants.ReservesSorting, "ReservesSortingText";
    setfenv(1, setmetatable({ Constants = LootReserve.Constants }, { __index = function(t, k) return input[k] end }));
    Constants[output] =
    {
        [ByTime]   = "By Time",
        [ByName]   = "By Item Name",
        [BySource] = "By Boss",
        [ByLooter] = "By Looter",
    };
end)();

(function()
    local input, output = LootReserve.Constants.WinnerReservesRemoval, "WinnerReservesRemovalText";
    setfenv(1, setmetatable({ Constants = LootReserve.Constants }, { __index = function(t, k) return input[k] end }));
    Constants[output] =
    {
        [None]      = "None",
        [Single]    = "Just one",
        [Duplicate] = "Duplicate",
        [All]       = "All",
        [Smart]     = "Smart",
    };
end)();

(function()
    local input, output = LootReserve.Constants.ChatReservesListLimit, "ChatReservesListLimitText";
    setfenv(1, setmetatable({ Constants = LootReserve.Constants }, { __index = function(t, k) return input[k] end }));
    Constants[output] =
    {
        [None] = "None",
    };
end)();

(function()
    local input, output = LootReserve.Constants.WonRollPhase, "WonRollPhaseText";
    setfenv(1, setmetatable({ Constants = LootReserve.Constants }, { __index = function(t, k) return input[k] end }));
    Constants[output] =
    {
        [Reserve]  = "Reserve",
        [RaidRoll] = "Raid-Roll",
    };
end)();

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
