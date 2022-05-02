LootReserve = LootReserve or { };
LootReserve.ItemSearch =
{
    BatchCap        = 100,
    DefaultSpeed    = 1,
    LeapSpeed       = 10,
    ZoomSpeed       = 250,
    
    IDLists = {
        {min =      1, max =  34900},
        {min =  35300, max =  35600},
        {min =  37800, max =  38300},
        {min =  38450, max =  38650},
        {min =  39149, max =  39149},
        {min =  39476, max =  39477},
        {min =  39656, max =  39656},
        {min =  43516, max =  43516},
        {min = 122270, max = 122290},
        {min = 172070, max = 172070},
        {min = 180089, max = 180089},
        {min = 184865, max = 184938},
        {min = 185686, max = 185693},
        {min = 185848, max = 186163},
        {min = 186682, max = 186683},
        {min = 187048, max = 187130},
        {min = 187435, max = 187435},
        {min = 187714, max = 187815},
        {min = 190179, max = 190325},
    },
};

function LootReserve.ItemSearch:Load()
    if self.FullCache then return end
    
    local itemsToCache = { };
    local alreadyAddedIDs = { [0] = true };
    for id, category in pairs(LootReserve.Data.Categories) do
        for _, child in ipairs(category.Children or { }) do
            for _, itemID in ipairs(child.Loot or { }) do
                if not alreadyAddedIDs[itemID] then
                    table.insert(itemsToCache, itemID);
                    alreadyAddedIDs[itemID] = true;
                end
            end
        end
    end
    for i = #itemsToCache, 1, -1 do
        for _, rewardID in ipairs(LootReserve.Data:GetTokenRewards(itemID) or { }) do
            if not alreadyAddedIDs[rewardID] then
                table.insert(itemsToCache, rewardID);
                alreadyAddedIDs[rewardID] = true;
            end
        end
    end
    
    for _, list in ipairs(self.IDLists) do
        for i = list.min, list.max do
            if not alreadyAddedIDs[i] then
                table.insert(itemsToCache, i);
            end
        end
    end
    
    self.FullCache = LootReserve.ItemCache:Cache(itemsToCache):SetSpeed(self.DefaultSpeed);
end