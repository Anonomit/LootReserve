LootReserve = LootReserve or { };
LootReserve.Constants =
{
    MAX_RESERVES          = 99,
    MAX_MULTIRESERVES     = 99,
    MAX_RESERVES_PER_ITEM = 99,
    MAX_CHAT_STORAGE      = 25,
    
    OptResult =
    {
        OK                       = 0,
        NotInRaid                = 1,
        NoSession                = 2,
        NotMember                = 3,
    },
    ReserveResult =
    {
        OK                       = 0,
        NotInRaid                = 1,
        NoSession                = 2,
        NotMember                = 3,
        ItemNotReservable        = 4,
        AlreadyReserved          = 5,
        NoReservesLeft           = 6,
        FailedConditions         = 7,
        Locked                   = 8,
        NotEnoughReservesLeft    = 9,
        MultireserveLimit        = 10,
        MultireserveLimitPartial = 11,
        FailedClass              = 12,
        FailedFaction            = 13,
        FailedLimit              = 14,
        FailedLimitPartial       = 15,
        FailedUsable             = 16,
    },
    CancelReserveResult =
    {
        OK                = 0,
        NotInRaid         = 1,
        NoSession         = 2,
        NotMember         = 3,
        ItemNotReservable = 4,
        NotReserved       = 5,
        Forced            = 6,
        Locked            = 7,
        InternalError     = 8,
        NotEnoughReserves = 9,
    },
    ReservesSorting =
    {
        ByTime   = 0,
        ByName   = 1,
        BySource = 2,
        ByLooter = 3,
    },
    WinnerReservesRemoval =
    {
        None      = 0,
        Single    = 1,
        Duplicate = 2,
        All       = 3,
    },
    ChatReservesListLimit =
    {
        None = -1,
    },
    ChatAnnouncement =
    {
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
    },
    DefaultPhases =
    {
        "Main-Spec",
        "Off-Spec",
        "Learning",
        "Quest",
        "Reputation",
        "Profession",
        "Looks",
        "Vendor",
    },
    WonRollPhase =
    {
        Reserve  = 1,
        RaidRoll = 2,
    },
    RollType =
    {
        NotRolled = 0,
        Passed    = -1,
        Deleted   = -2,
    },
    LoadState =
    {
        NotStarted = 0,
        Started    = 1,
        ClientDone = 2,
        Pending    = 3,
        AllDone    = 4,
    },
    ClassFilenameToClassID   = { },
    ClassLocalizedToFilename = { },
    ItemQuality =
    {
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
    },
    RedundantSubTypes = {
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
    },
    WeaponTypeNames = {
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
    },
    Sounds = {
        LevelUp = 1440,
        Cheer = {
            [1]  = {[2] = 2677, [3] = 2689},
            [2]  = {[2] = 2701, [3] = 2713},
            [3]  = {[2] = 2725, [3] = 2737},
            [4]  = {[2] = 2749, [3] = 2761},
            [5]  = {[2] = 2773, [3] = 2785},
            [6]  = {[2] = 2797, [3] = 2810},
            [7]  = {[2] = 2835, [3] = 2847},
            [8]  = {[2] = 2859, [3] = 2871},
            [10] = {[2] = 9656, [3] = 9632},
            [11] = {[2] = 9706, [3] = 9681},
        },
        Congratulate = {
            [1]  = {[2] = 6168, [3] = 6141},
            [2]  = {[2] = 6366, [3] = 6357},
            [3]  = {[2] = 6113, [3] = 6104},
            [4]  = {[2] = 6186, [3] = 6177},
            [5]  = {[2] = 6420, [3] = 6411},
            [6]  = {[2] = 6384, [3] = 6375},
            [7]  = {[2] = 6131, [3] = 6122},
            [8]  = {[2] = 6402, [3] = 6393},
            [10] = {[2] = 9657, [3] = 9641},
            [11] = {[2] = 9707, [3] = 9682},
        },
    },
};

local result = LootReserve.Constants.OptResult;
LootReserve.Constants.OptResultText =
{
    [result.OK]                       = "",
    [result.NotInRaid]                = "You are not in the raid",
    [result.NoSession]                = "Loot reserves aren't active in your raid",
    [result.NotMember]                = "You are not participating in loot reserves",
};

local result = LootReserve.Constants.ReserveResult;
LootReserve.Constants.ReserveResultText =
{
    [result.OK]                       = "",
    [result.NotInRaid]                = "You are not in the raid",
    [result.NoSession]                = "Loot reserves aren't active in your raid",
    [result.NotMember]                = "You are not participating in loot reserves",
    [result.ItemNotReservable]        = "That item cannot be reserved in this raid",
    [result.AlreadyReserved]          = "You are already reserving that item",
    [result.NoReservesLeft]           = "You already reserved too many items",
    [result.FailedConditions]         = "You cannot reserve that item",
    [result.Locked]                   = "Your reserves are locked-in and cannot be changed anymore",
    [result.NotEnoughReservesLeft]    = "You don't have enough reserves to do that",
    [result.MultireserveLimit]        = "You cannot reserve that item more times",
    [result.MultireserveLimitPartial] = "Not all of your reserves were accepted because you reached the limit of how many times you are allowed to reserve a single item",
    [result.FailedClass]              = "Your class cannot reserve that item",
    [result.FailedFaction]            = "Your faction cannot reserve that item",
    [result.FailedLimit]              = "That item has reached the limit of reserves",
    [result.FailedLimitPartial]       = "Not all of your reserves were accepted because the item reached the limit of reserves",
};

local result = LootReserve.Constants.CancelReserveResult;
LootReserve.Constants.CancelReserveResultText =
{
    [result.OK]                = "",
    [result.NotInRaid]         = "You are not in the raid",
    [result.NoSession]         = "Loot reserves aren't active in your raid",
    [result.NotMember]         = "You are not participating in loot reserves",
    [result.ItemNotReservable] = "That item cannot be reserved in this raid",
    [result.NotReserved]       = "You did not reserve that item",
    [result.Forced]            = "",
    [result.Locked]            = "Your reserves are locked-in and cannot be changed anymore",
    [result.InternalError]     = "Internal error",
    [result.NotEnoughReserves] = "You don't have that many reserves on that item",
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
};

local enum = LootReserve.Constants.ChatReservesListLimit;
LootReserve.Constants.ChatReservesListLimitText =
{
    [enum.None] = "None",
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
