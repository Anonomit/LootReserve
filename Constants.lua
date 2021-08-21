LootReserve = LootReserve or { };
LootReserve.Constants =
{
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
    ClassFilenameToClassID = { },
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

for i = 1, LootReserve:GetNumClasses() do
    local name, file, id = LootReserve:GetClassInfo(i);
    if file and id then
        LootReserve.Constants.ClassFilenameToClassID[file] = id;
    end
end
