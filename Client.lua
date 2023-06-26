LootReserve = LootReserve or { };
LootReserve.Client =
{
    -- Server Connection
    SessionServer = nil,
    Masquerade    = nil,

    -- Server Session Info
    StartTime         = 0,
    AcceptingReserves = false,
    RemainingReserves = 0,
    MaxReserves       = 0,
    Locked            = false,
    OptedOut          = false,
    LootCategories    = nil,
    Duration          = nil,
    MaxDuration       = nil,
    ItemReserves      = { }, -- { [ItemID] = { "Playername", "Playername", ... }, ... }
    ItemConditions    = { },
    RollRequest       = nil,
    Equip             = true,
    Blind             = false,
    Multireserve      = 1,

    Settings =
    {
        RollRequestShow             = true,
        RollRequestShowUnusable     = false,
        RollRequestShowUnusableBoE  = false,
        RollRequestGlowOnlyReserved = true,
        RollRequestAutoRollReserved = true,
        RollRequestAutoCloseTiered  = false,
        RollRequestAutoRollNotified = false,
        RollRequestWinnerReaction   = true,
        RollRequestLoserReaction    = true,
        CollapsedExpansions         = { },
        CollapsedCategories         = { },
        SwapLDBButtons              = false,
        LibDBIcon                   = { },
        AllowPreCache               = false,
        ShowReopenHint              = true,
    },
    CharacterFavorites = { },
    GlobalFavorites    = { },

    ReservableIDs            = { },
    PendingItems             = { },
    PendingOpt               = nil,
    PendingOpen              = false,
    SkipOpen                 = false,
    ServerSearchTimeoutTime  = nil,
    DurationUpdateRegistered = false,
    SessionEventsRegistered  = false,
    CategoryFlashing         = false,
    
    PendingLootListUpdate = nil,

    SelectedCategory = nil,
    
    RollOnLoot = nil,
};


StaticPopupDialogs["LOOTRESERVE_CONFIRM_NEED_ROLL_RESERVED_ITEM"] =
{
    text         = "Are you sure you want to roll Need?|n|n%s has been reserved by:|n%s.",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self, data)
        LootReserve.Client.RollOnLoot(data.rollID, 1);
    end,
};

StaticPopupDialogs["LOOTRESERVE_PROMPT_REMOVE_FAVORITE"] =
{
    text         = "|cff00ff00Congratulations!|r|n|nWould you like to remove %s from your favorites?",
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self, data)
        LootReserve.Client:SetFavorite(data.item:GetID(), false);
    end,
};


function LootReserve.Client:Init()
    local function LootReserveRollOnLoot(rollID, rollType, ...)
        if not self.SessionServer then return; end
        
        if rollType ~= 1 then return; end
        
        local link = GetLootRollItemLink(rollID);
        if not link then return; end
        
        local item = LootReserve.ItemCache:Item(link);
        
        local token;
        if not self:IsItemReserved(itemID) then
            token = LootReserve.Data:GetToken(item:GetID());
            if token then
                token = LootReserve.ItemCache:Item(token);
            end
        end
        local itemID = token and token:GetID() or item:GetID();
        if self:IsItemReserved(itemID) and not self:IsItemReservedByMe(itemID, true) then
            local reservesText = LootReserve:FormatReservesTextColored(LootReserve.Client:GetItemReservers(itemID));
            StaticPopup_Show("LOOTRESERVE_CONFIRM_NEED_ROLL_RESERVED_ITEM", item:GetLink(), reservesText, {rollID = rollID});
            return true;
        end
    end
    
    self.RollOnLoot = _G.RollOnLoot
    _G.RollOnLoot = function(...)
        local args = {...};
        local success, result = pcall(function() LootReserveRollOnLoot(unpack(args)) end);
        if not success or not result then
            self.RollOnLoot(...)
        end
    end
end
LootReserve.Client:Init();


function LootReserve.Client:Load()
    LootReserveCharacterSave.Client = LootReserveCharacterSave.Client or { };
    LootReserveGlobalSave.Client = LootReserveGlobalSave.Client or { };

    -- Copy data from saved variables into runtime tables
    -- Don't outright replace tables, as new versions of the addon could've added more fields that would be missing in the saved data
    local function loadInto(to, from, field)
        if from and to and field then
            if from[field] then
                for k, v in pairs(from[field]) do
                    to[field] = to[field] or { };
                    to[field][k] = v;
                    empty = false;
                end
            end
            from[field] = to[field];
        end
    end
    local versionSave = LootReserveGlobalSave.Client.Version and LootReserveGlobalSave.Client.Version or "0"
    loadInto(self, LootReserveGlobalSave.Client, "Settings");
    loadInto(self, LootReserveCharacterSave.Client, "CharacterFavorites");
    loadInto(self, LootReserveGlobalSave.Client, "GlobalFavorites");

    LibStub("LibDBIcon-1.0").RegisterCallback("LootReserve", "LibDBIcon_IconCreated", function(event, button, name)
        if name == "LootReserve" then
            button.icon:SetTexture("Interface\\AddOns\\LootReserve\\Assets\\Textures\\Icon");
        end
    end);
    LibStub("LibDBIcon-1.0"):Register("LootReserve", LibStub("LibDataBroker-1.1"):NewDataObject("LootReserve", {
        type = "launcher",
        text = "LootReserve",
        icon = "Interface\\Buttons\\UI-GroupLoot-Dice-Up",
        OnClick = function(ldb, button)
            if button == "LeftButton" or button == "RightButton" then
                local window = ((button == "LeftButton") == self.Settings.SwapLDBButtons) and LootReserve.Server.Window or LootReserve.Client.Window;
                if InCombatLockdown() and window:IsProtected() and window == LootReserve.Server.Window then
                    LootReserve:ToggleServerWindow(not window:IsShown());
                else
                    window:SetShown(not window:IsShown());
                end
            elseif button == "MiddleButton" then
                LootReserve.Client.Settings.LibDBIcon.hide = true;
                LibStub("LibDBIcon-1.0"):Hide("LootReserve");
                CloseMenus(); -- close options menu if it's open
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText("LootReserve", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1);
            tooltip:AddLine(format("Left-Click: Open %s Window", self.Settings.SwapLDBButtons and "Host" or "Reserves"));
            tooltip:AddLine(format("Right-Click: Open %s Window", self.Settings.SwapLDBButtons and "Reserves" or "Host"));
            tooltip:AddLine("Middle-Click: Hide Minimap Button");
            tooltip:AddLine("(Toggle icon visibility in Reserves window)");
        end,
    }), self.Settings.LibDBIcon);
    
    
    -- 2023-06-20: Reset auto roll notification
    if versionSave < "2023-06-20" then
        self.Settings.RollRequestAutoRollNotified = false;
    end
    
    LootReserveGlobalSave.Client.Version = LootReserve.Version;
end

function LootReserve.Client:IsFavorite(itemID)
    return self.CharacterFavorites[itemID] or self.GlobalFavorites[itemID];
end

function LootReserve.Client:SetFavorite(itemID, enabled)
    if self:IsFavorite(itemID) == (enabled and true or false) then return; end
    
    local item = LootReserve.ItemCache:Item(itemID);
    if not item or not item:GetInfo() then return; end
    local bindType = item:GetBindType();

    local favorites = bindType == LE_ITEM_BIND_ON_ACQUIRE and self.CharacterFavorites or self.GlobalFavorites;
    favorites[itemID] = enabled and true or nil;
    
    LootReserve.Client:UpdateLootList();
    self:FlashCategory("Favorites");
end

function LootReserve.Client:SearchForServer(startup)
    if not startup and self.ServerSearchTimeoutTime and time() < self.ServerSearchTimeoutTime then return; end
    self.ServerSearchTimeoutTime = time() + 10;

    LootReserve.Comm:BroadcastHello();
end

function LootReserve.Client:SetMasquerade(player)
    local oldMasquerade = self.Masquerade;
    if self.SessionServer and LootReserve:IsMe(self.SessionServer) and LootReserve.Server and LootReserve.Server.CurrentSession then
        if not player or LootReserve:IsMe(player) then
            self.Masquerade = nil;
        else
            self.Masquerade = player;
        end
        if oldMasquerade ~= self.Masquerade then
            LootReserve.Comm:SendSessionInfo(LootReserve:Me());
        end
    end
end

function LootReserve.Client:StartSession(server, starting, startTime, acceptingReserves, lootCategories, duration, maxDuration, equip, blind, multireserve)
    self:ResetSession(true);
    self.SessionServer = server;
    self.StartTime = startTime;
    self.AcceptingReserves = acceptingReserves;
    self.LootCategories = lootCategories;
    self.Duration = duration;
    self.MaxDuration = maxDuration;
    self.Equip = equip;
    self.Blind = blind;
    self.Multireserve = multireserve;
    
    -- Cache the list of items players can reserve
    table.wipe(self.ReservableIDs);
    for itemID, conditions in pairs(self.ItemConditions) do
        if itemID ~= 0 and conditions.Custom then
            if LootReserve.ItemConditions:TestServer(itemID) then
                self.ReservableIDs[itemID] = true;
            end
        end
    end
    local rewardIDs = { };
    local hiddenIDs = { };
    for id, category in LootReserve:Ordered(LootReserve.Data.Categories, LootReserve.Data.CategorySorter) do
        if category.Children and (not self.LootCategories or LootReserve:Contains(self.LootCategories, id)) and LootReserve.Data:IsCategoryVisible(category) then
            for _, child in ipairs(category.Children) do
                if child.Loot then
                    for _, itemID in ipairs(child.Loot) do
                        if itemID ~= 0 then
                            if LootReserve.ItemConditions:TestServer(itemID) then
                                if LootReserve.Data:IsTokenReward(itemID) then
                                    table.insert(rewardIDs, itemID);
                                else
                                    self.ReservableIDs[itemID] = true;
                                end
                            else
                                hiddenIDs[itemID] = true;
                            end
                        end
                    end
                end
            end
        end
    end
    for _, rewardID in ipairs(rewardIDs) do
        local tokenID = LootReserve.Data:GetToken(rewardID);
        if not self.ReservableIDs[tokenID] and not hiddenIDs[itemID] then
            self.ReservableIDs[rewardID] = true;
        end
    end

    if self.MaxDuration ~= 0 and not self.DurationUpdateRegistered then
        self.DurationUpdateRegistered = true;
        LootReserve:RegisterUpdate(function(elapsed)
            if self.SessionServer and self.AcceptingReserves and self.Duration ~= 0 then
                if self.Duration > elapsed then
                    self.Duration = self.Duration - elapsed;
                else
                    self.Duration = 0;
                    self:StopSession();
                end
            end
        end);
    end

    if not self.SessionEventsRegistered then
        self.SessionEventsRegistered = true;

        LootReserve:RegisterEvent("GROUP_LEFT", function()
            if self.SessionServer and not LootReserve:IsMe(self.SessionServer) then
                self:StopSession();
                self:ResetSession();
                self:UpdateCategories();
                self:UpdateLootList();
                self:UpdateReserveStatus();
            end
        end);

        LootReserve:RegisterEvent("GROUP_ROSTER_UPDATE", function()
            if self.SessionServer and not LootReserve:UnitInGroup(self.SessionServer) then
                self:StopSession();
                self:ResetSession();
                self:UpdateCategories();
                self:UpdateLootList();
                self:UpdateReserveStatus();
            end
        end);

        LootReserve:RegisterEvent("PLAYER_REGEN_ENABLED", function()
            if self.PendingOpen and self.SessionServer and self.AcceptingReserves and not self.Locked and self.RemainingReserves > 0 and not self.OptedOut then
                self.Window:Show();
            end
            self.PendingOpen = false;
        end);
        
        -- Auto need on reserved items during group loot (when multireserves disabled)
        LootReserve:RegisterEvent("START_LOOT_ROLL", function(rollID)
            if not self.SessionServer or self.Multireserve > 1 or not self.Settings.RollRequestAutoRollReserved then return; end
            
            local link = GetLootRollItemLink(rollID);
            if not link then return; end
            
            local item = LootReserve.ItemCache:Item(link);
            
            local token;
            if not self:IsItemReserved(itemID) then
                token = LootReserve.Data:GetToken(item:GetID());
                if token then
                    token = LootReserve.ItemCache:Item(token);
                end
            end
            local itemID = token and token:GetID() or item:GetID();
            if self:IsItemReservedByMe(itemID, true) then
                LootReserve:PrintMessage("Automatically rolling Need on reserved item: %s", item:GetLink());
                if not self.Settings.RollRequestAutoRollNotified then
                    LootReserve:PrintError("Automatic rolling on reserved items can be disabled in Reserve window settings.");
                    self.Settings.RollRequestAutoRollNotified = true;
                end
                self.RollOnLoot(rollID, 1);
                ConfirmLootRoll(rollID, 1);
                StaticPopup_Hide("CONFIRM_LOOT_ROLL");
            end
        end);
        
        
        local function OnTooltipSetHyperlink(tooltip)
            if self.SessionServer and not LootReserve:IsMe(self.SessionServer) then
                local name, link = tooltip:GetItem();
                if not link then return; end
                
                -- Check if it's already been added
                local frame, text;
                for i = 1, tooltip:NumLines() do
                frame = _G[tooltip:GetName() .. "TextLeft" .. i];
                if frame then
                    text = frame:GetText();
                end
                if text and string.find(text, " Reserved by ", 1, true) then return; end
                end

                local itemID = LootReserve.ItemCache:Item(link):GetID();
                local tokenID = LootReserve.Data:GetToken(itemID);
                if LootReserve.Client.SessionServer and not LootReserve.Client.ReservableIDs[tokenID] then
                    tokenID = nil;
                end
                if #self:GetItemReservers(tokenID or itemID) > 0 then
                    local reservesText = LootReserve:FormatReservesTextColored(self:GetItemReservers(tokenID or itemID));
                    tooltip:AddLine("|TInterface\\BUTTONS\\UI-GroupLoot-Dice-Up:32:32:0:-4|t Reserved by " .. reservesText, 1, 1, 1);
                end
            end
        end
        GameTooltip             : HookScript("OnTooltipSetItem", OnTooltipSetHyperlink);
        ItemRefTooltip          : HookScript("OnTooltipSetItem", OnTooltipSetHyperlink);
        ItemRefShoppingTooltip1 : HookScript("OnTooltipSetItem", OnTooltipSetHyperlink);
        ItemRefShoppingTooltip2 : HookScript("OnTooltipSetItem", OnTooltipSetHyperlink);
        ShoppingTooltip1        : HookScript("OnTooltipSetItem", OnTooltipSetHyperlink);
        ShoppingTooltip2        : HookScript("OnTooltipSetItem", OnTooltipSetHyperlink);
    end

    if starting then
        self.Masquerade = nil;
        local lootCategoriesText = LootReserve:GetCategoriesText(self.LootCategories);
        LootReserve:PrintMessage("Session started%s%s.", lootCategoriesText ~= "" and " for " or "", lootCategoriesText);
        if self.AcceptingReserves then
            PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_ENTER_WORLD);
        end
    end
end

function LootReserve.Client:StopSession()
    self.AcceptingReserves = false;
end

function LootReserve.Client:ResetSession(refresh)
    self.SessionServer     = nil;
    self.RemainingReserves = 0;
    self.MaxReserves       = 0;
    self.LootCategories    = nil;
    self.ItemReserves      = { };
    self.ItemConditions    = { };
    self.Equip             = true;
    self.Blind             = false;
    self.Multireserve      = 1;
    self.PendingItems      = { };
    self.PendingOpts       = nil;

    if not refresh then
        self:StopCategoryFlashing();
    end
end

function LootReserve.Client:GetRemainingReserves()
    return self.SessionServer and self.AcceptingReserves and self.RemainingReserves or 0;
end
function LootReserve.Client:HasRemainingReserves()
    return self:GetRemainingReserves() > 0;
end
function LootReserve.Client:GetMaxReserves()
    return self.SessionServer and self.MaxReserves or 0;
end

function LootReserve.Client:IsItemReserved(itemID)
    return #self:GetItemReservers(itemID) > 0;
end
function LootReserve.Client:IsItemReservedByMe(itemID, bypassMasquerade)
    for _, player in ipairs(self:GetItemReservers(itemID)) do
        if LootReserve:IsSamePlayer(not bypassMasquerade and LootReserve.Client.Masquerade or LootReserve:Me(), player) then
            return true;
        end
    end
    return false;
end
function LootReserve.Client:GetItemReservers(itemID)
    if not self.SessionServer then return { }; end
    return self.ItemReserves[itemID] or { };
end

function LootReserve.Client:IsItemPending(itemID)
    return self.PendingItems[itemID];
end
function LootReserve.Client:SetItemPending(itemID, pending)
    self.PendingItems[itemID] = pending or nil;
end

function LootReserve.Client:Reserve(itemID)
    if not self.SessionServer then return; end
    if not self.AcceptingReserves then return; end
    
    local tokenID = LootReserve.Data:GetToken(itemID);
    if not self.ReservableIDs[tokenID] then
        tokenID = nil;
    end
    if tokenID then
        LootReserve.Client:SetItemPending(tokenID, true);
    end
    LootReserve.Client:SetItemPending(itemID, true);
    
    LootReserve.Client:UpdateReserveStatus();
    LootReserve.Comm:SendReserveItem(tokenID or itemID);
end

function LootReserve.Client:CancelReserve(itemID)
    if not self.SessionServer then return; end
    if not self.AcceptingReserves then return; end
    
    local tokenID = LootReserve.Data:GetToken(itemID);
    if not self.ReservableIDs[tokenID] then
        tokenID = nil;
    end
    if tokenID then
        LootReserve.Client:SetItemPending(tokenID, true);
    end
    LootReserve.Client:SetItemPending(itemID, true);
    
    LootReserve.Client:UpdateReserveStatus();
    LootReserve.Comm:SendCancelReserve(tokenID or itemID);
end

function LootReserve.Client:IsOptPending()
    return self.PendingOpt;
end
function LootReserve.Client:SetOptPending(pending)
    self.PendingOpt = pending or nil;
end

function LootReserve.Client:IsOptedOut()
    return self.OptedOut or false;
end
function LootReserve.Client:IsOptedIn()
    return not self:IsOptedOut();
end

function LootReserve.Client:OptOut()
    if not self.SessionServer then return; end
    if not self.AcceptingReserves then return; end
    self:SetOptPending(true);
    LootReserve.Client:UpdateReserveStatus();
    LootReserve.Comm:SendOptOut();
end

function LootReserve.Client:OptIn()
    if not self.SessionServer then return; end
    if not self.AcceptingReserves then return; end
    self:SetOptPending(true);
    LootReserve.Client:UpdateReserveStatus();
    LootReserve.Comm:SendOptIn();
end
