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
        RollRequestGlowOnlyReserved = true,
        RollRequestAutoRollReserved = true,
        RollRequestAutoRollNotified = false,
        RollRequestWinnerReaction   = true,
        RollRequestLoserReaction    = true,
        CollapsedExpansions         = { },
        CollapsedCategories         = { },
        SwapLDBButtons              = false,
        LibDBIcon                   = { },
    },
    CharacterFavorites = { },
    GlobalFavorites    = { },

    PendingItems             = { },
    PendingOpt               = nil,
    PendingOpen              = false,
    ServerSearchTimeoutTime  = nil,
    DurationUpdateRegistered = false,
    SessionEventsRegistered  = false,
    CategoryFlashing         = false,
    
    PendingLootListUpdate    = false,

    SelectedCategory = nil,
};

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
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText("LootReserve", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1);
            tooltip:AddLine(format("Left-Click: Open %s Window", self.Settings.SwapLDBButtons and "Host" or "Client"));
            tooltip:AddLine(format("Right-Click: Open %s Window", self.Settings.SwapLDBButtons and "Client" or "Host"));
        end,
    }), self.Settings.LibDBIcon);
    
    LootReserve.ItemSearch:Load(10);
end

function LootReserve.Client:IsFavorite(itemID)
    return self.CharacterFavorites[itemID] or self.GlobalFavorites[itemID];
end

function LootReserve.Client:SetFavorite(itemID, enabled)
    if self:IsFavorite(itemID) == (enabled and true or false) then return; end
    
    local item = LootReserve.ItemSearch:Get(itemID);
    if not item or not item:GetInfo() then return; end
    local bindType = item:GetBindType();

    local favorites = bindType == LE_ITEM_BIND_ON_ACQUIRE and self.CharacterFavorites or self.GlobalFavorites;
    favorites[itemID] = enabled and true or nil;
    self:FlashCategory("Favorites");
end

function LootReserve.Client:SearchForServer(startup)
    if not startup and self.ServerSearchTimeoutTime and time() < self.ServerSearchTimeoutTime then return; end
    self.ServerSearchTimeoutTime = time() + 10;

    LootReserve.Comm:BroadcastHello();
end

function LootReserve.Client:SetMasquerade(player)
    if self.SessionServer and LootReserve:IsMe(self.SessionServer) and LootReserve.Server and LootReserve.Server.CurrentSession then
        if not player or LootReserve:IsMe(player) then
            self.Masquerade = nil
        else
            self.Masquerade = player
        end
        LootReserve.Comm:SendSessionInfo(LootReserve:Me());
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
            if self.SessionServer and self.PendingOpen then
                self.Window:Show();
            end
            self.PendingOpen = false;
        end);

        local function OnTooltipSetHyperlink(tooltip)
            if self.SessionServer and not LootReserve:IsMe(self.SessionServer) then
                local name, link = tooltip:GetItem();
                if not link then return; end
                
                -- Check if it's already been added
                local frame, text;
                for i = 1, 50 do
                frame = _G[tooltip:GetName() .. "TextLeft" .. i];
                if frame then
                    text = frame:GetText();
                end
                if text and string.find(text, " Reserved by ", 1, true) then return; end
                end

                local item = LootReserve.Item(link);
                if #self:GetItemReservers(item:GetID()) > 0 then
                    local reservesText = LootReserve:FormatReservesTextColored(self:GetItemReservers(item:GetID()));
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
        PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_ENTER_WORLD);
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
    LootReserve.Client:SetItemPending(itemID, true);
    LootReserve.Client:UpdateReserveStatus();
    LootReserve.Comm:SendReserveItem(itemID);
end

function LootReserve.Client:CancelReserve(itemID)
    if not self.SessionServer then return; end
    if not self.AcceptingReserves then return; end
    LootReserve.Client:SetItemPending(itemID, true);
    LootReserve.Client:UpdateReserveStatus();
    LootReserve.Comm:SendCancelReserve(itemID);
end

function LootReserve.Client:IsOptPending()
    return self.PendingOpt;
end
function LootReserve.Client:SetOptPending(pending)
    self.PendingOpt = pending or nil;
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
