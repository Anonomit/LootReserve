LootReserve = LootReserve or { };
LootReserve.ItemSearch =
{
    LoadingState  = nil,
    LoadingThread = nil,
    LoadingTicker = nil,
    Names         = { },
    PendingNames  = { };
    MaxID         = 40000,
    LoadedNames   = 0,
    TotalNames    = 0,
};

function LootReserve.ItemSearch:Load()
    if self.LoadingState ~= nil then return 100 * self.LoadedNames / math.max(1, self.TotalNames); end
    self.LoadingState = false;
    self.TotalNames = self.MaxID;

    LootReserve:RegisterEvent("GET_ITEM_INFO_RECEIVED", function(itemID, success)
        if itemID and self.PendingNames[itemID] then
            self.PendingNames[itemID] = nil;
            if success then
                self.Names[itemID] = LootReserve:TransformSearchText(GetItemInfo(itemID) or "");
                self.LoadedNames = self.LoadedNames + 1;
            else
                self.TotalNames = self.TotalNames - 1;
            end
        end
    end);

    self.LoadingThread = coroutine.create(function()
        for itemID = 1, self.MaxID do
            if C_Item.DoesItemExistByID(itemID) then
                local name = GetItemInfo(itemID);
                if name then
                    self.Names[itemID] = LootReserve:TransformSearchText(name);
                    self.LoadedNames = self.LoadedNames + 1;
                else
                    self.PendingNames[itemID] = true;
                end
            else
                self.TotalNames = self.TotalNames - 1;
            end
            if itemID % 250 == 0 then
                coroutine.yield();
            end
        end
        while next(self.PendingNames) do
            coroutine.yield();
        end
        self.LoadingState = true;
    end);

    self.LoadingTicker = C_Timer.NewTicker(0.05, function()
        coroutine.resume(self.LoadingThread);
        if coroutine.status(self.LoadingThread) == "dead" then
            self.LoadingTicker:Cancel();
        end
    end);

    return 0;
end

function LootReserve.ItemSearch:Search(query)
    local progress = self:Load();
    if not self.LoadingState then return nil, progress; end

    query = LootReserve:TransformSearchText(query);

    local results = { };
    for itemID, name in pairs(self.Names) do
        if string.find(name, query, 1, true) then
            table.insert(results, itemID);
        end
    end
    return results;
end
