LootReserve = LootReserve or { };
LootReserve.ItemSearch =
{
    BatchCap        = 100, -- max number of items to query in between UI updates
    BatchFrames     = 10, -- UI updates should happen in about this many frames (plus the delay of ITEM_DATA_LOAD_RESULT)
    DefaultSpeed    = 1,
    ZoomSpeed       = 250, -- used when every single item must be cached
    
    IDLists = {
        {min =     17, max =    287},
        {min =    414, max =    422},
        {min =    527, max =  46403},
        {min =  46544, max =  46545},
        {min =  46690, max =  50474},
        {min =  50603, max =  52062},
        {min =  52189, max =  52361},
        {min =  52541, max =  52572},
        {min =  52676, max =  52731},
        {min =  52835, max =  52835},
        {min =  53048, max =  53134},
        {min =  53476, max =  53510},
        {min =  53637, max =  53641},
        {min =  53785, max =  53963},
        {min =  54068, max =  54069},
        {min =  54212, max =  54653},
        {min =  54797, max =  54860},
        {min =  56806, max =  56806},
        {min = 122270, max = 122284},
        {min = 172070, max = 172070},
        {min = 180089, max = 180089},
        {min = 184865, max = 184938},
        {min = 185686, max = 185693},
        {min = 185848, max = 186163},
        {min = 186682, max = 186683},
        {min = 187048, max = 187130},
        {min = 187435, max = 187435},
        {min = 187643, max = 187815},
        {min = 190179, max = 190325},
        {min = 191060, max = 191061},
        {min = 191481, max = 191481},
        {min = 192455, max = 192455},
        {min = 194101, max = 194101},
        {min = 194518, max = 194518},
        {min = 198628, max = 198665},
        {min = 199210, max = 199210},
        {min = 199327, max = 199336},
        {min = 199463, max = 199530},
        {min = 199635, max = 199778},
        {min = 199909, max = 199914},
        {min = 200068, max = 200068},
        {min = 200235, max = 200240},
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