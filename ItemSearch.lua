LootReserve = LootReserve or { };
LootReserve.ItemSearch =
{
    LoadState       = LootReserve.Constants.LoadState.NotStarted,
    LoadingThread   = nil,
    LoadingTicker   = nil,
    Items           = { },
    PendingIDs      = { };
    AttemptedIDs    = { };
    PendingCount    = { };
    AttemptedCount  = { };
    LoadedItems     = 0,
    MaxItems        = 0,
    Speed           = 10,
    
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
    if self.LoadState ~= 0 then return end
    
    self.LoadState = LootReserve.Constants.LoadState.Started;
    self.MaxItems = 0;
    for _, list in ipairs(self.IDLists) do
        self.MaxItems = self.MaxItems + list.max - list.min + 1;
    end

    LootReserve:RegisterEvent("GET_ITEM_INFO_RECEIVED", function(itemID, success)
        if itemID and not self.Items[itemID] then
            self.PendingIDs[itemID] = nil;
            self.AttemptedIDs[itemID] = true;
            if success then
                self.Items[itemID] = LootReserve.Item(itemID);
                self.Items[itemID]:GetInfo(); -- Make sure Item stores its info while it's available
                self.LoadedItems = self.LoadedItems + 1;
            end
        end
    end);

    self.LoadingThread = coroutine.create(function()
        local itemCount = 0;
        for id, category in pairs(LootReserve.Data.Categories) do
            if category.Children then
                for _, child in ipairs(category.Children) do
                    if child.Loot then
                        for _, itemID in ipairs(child.Loot) do
                            self:LoadItem(itemID);
                            itemCount = itemCount + 1;
                            if itemCount % self.Speed == 0 then
                                coroutine.yield();
                            end
                            if LootReserve.Data:IsToken(itemID) then
                                for _, reward in ipairs(LootReserve.Data:GetTokenRewards(itemID)) do
                                    self:LoadItem(reward);
                                    itemCount = itemCount + 1;
                                    if itemCount % self.Speed == 0 then
                                        coroutine.yield();
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        self.LoadState = LootReserve.Constants.LoadState.SessionDone;
        self.Speed = 10;
        
        for _, IDList in ipairs(self.IDLists) do
            for itemID = IDList.min, IDList.max do
                self:LoadItem(itemID);
                itemCount = itemCount + 1;
                if itemCount % self.Speed == 0 then
                    coroutine.yield();
                end
                if LootReserve.Data:IsToken(itemID) then
                    for _, reward in ipairs(LootReserve.Data:GetTokenRewards(itemID)) do
                        self:LoadItem(reward);
                        itemCount = itemCount + 1;
                        if itemCount % self.Speed == 0 then
                            coroutine.yield();
                        end
                    end
                end
            end
        end
        while next(self.PendingIDs) do
            coroutine.yield();
        end
        self.LoadState = LootReserve.Constants.LoadState.AllDone;
    end);

    self.LoadingTicker = C_Timer.NewTicker(0.05, function()
        local success, err = coroutine.resume(self.LoadingThread);
        if not success then
            error(err)
        end
        if coroutine.status(self.LoadingThread) == "dead" then
            self.LoadingTicker:Cancel();
        end
    end);

    return 0;
end

function LootReserve.ItemSearch:LoadItem(itemID)
    self:Load();
    
    if not self.AttemptedIDs[itemID] and itemID ~= 0 then
        self.AttemptedIDs[itemID] = true;
        if C_Item.DoesItemExistByID(itemID) then
            local item = LootReserve.Item(itemID);
            if item:GetInfo() then
                self.Items[itemID] = item;
                self.LoadedItems = self.LoadedItems + 1;
            else
                self.PendingIDs[itemID] = true;
            end
        else
            self.MaxItems = self.MaxItems - 1;
        end
    end
    return self.Items[itemID];
end

function LootReserve.ItemSearch:Get(itemID)
    if not self.Items[itemID] then
        self:LoadItem(itemID);
    end
    return self.Items[itemID];
end

function LootReserve.ItemSearch:IsPending(itemID)
    return self.PendingIDs[itemID];
end

function LootReserve.ItemSearch:Search(query)
    query = LootReserve:TransformSearchText(query);

    local items = { };
    for itemID, item in pairs(self.Items) do
        if string.find(item:GetSearchName(), query, 1, true) then
            table.insert(items, item);
        end
    end
    return items;
end

function LootReserve.ItemSearch:GetProgress()
    return math.min(self.LoadedItems / math.max(1, self.MaxItems), 1) * 100, self.LoadState;
end

function LootReserve.ItemSearch:SetSpeed(speed)
    self.Speed = speed;
end
