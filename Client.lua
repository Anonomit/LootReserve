LootReserve = LootReserve or { };
LootReserve.Client =
{
    -- Server Connection
    SessionServer = nil,

    -- Server Session Info
    StartTime         = 0,
    AcceptingReserves = false,
    RemainingReserves = 0,
    Locked            = false,
    OptedOut          = false,
    LootCategory      = nil,
    Duration          = nil,
    MaxDuration       = nil,
    ItemReserves      = { }, -- { [ItemID] = { "Playername", "Playername", ... }, ... }
    ItemConditions    = { },
    RollRequest       = nil,
    Equip             = true,
    Blind             = false,
    Multireserve      = nil,

    Settings =
    {
        RollRequestShow             = true,
        RollRequestShowUnusable     = false,
        RollRequestGlowOnlyReserved = true,
        CollapsedExpansions         = { },
        CollapsedCategories         = { },
        SwapLDBButtons              = false,
        LibDBIcon                   = { },
    },
    CharacterFavorites = { },
    GlobalFavorites    = { },

    PendingItems             = { },
    PendingOpt               = nil,
    ServerSearchTimeoutTime  = nil,
    DurationUpdateRegistered = false,
    SessionEventsRegistered  = false,
    CategoryFlashing         = false,

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
            button.icon:SetTexture("Interface\\AddOns\\LootReserve\\Textures\\Icon");
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
            tooltip:AddLine(format("Left-Click: Open %s Window", self.Settings.SwapLDBButtons and "Server" or "Client"));
            tooltip:AddLine(format("Right-Click: Open %s Window", self.Settings.SwapLDBButtons and "Client" or "Server"));
        end,
    }), self.Settings.LibDBIcon);
end

function LootReserve.Client:IsFavorite(item)
    return self.CharacterFavorites[item] or self.GlobalFavorites[item];
end

function LootReserve.Client:SetFavorite(item, enabled)
    if self:IsFavorite(item) == (enabled and true or false) then return; end

    local name, _, _, _, _, _, _, _, _, _, _, _, _, bindType = GetItemInfo(item);
    if not name or not bindType then return; end

    local favorites = bindType == 1 and self.CharacterFavorites or self.GlobalFavorites;
    favorites[item] = enabled and true or nil;
    self:FlashCategory("Favorites");
end

function LootReserve.Client:SearchForServer(startup)
    if not startup and self.ServerSearchTimeoutTime and time() < self.ServerSearchTimeoutTime then return; end
    self.ServerSearchTimeoutTime = time() + 10;

    LootReserve.Comm:BroadcastHello();
end

function LootReserve.Client:StartSession(server, starting, startTime, acceptingReserves, lootCategory, duration, maxDuration, equip, blind, multireserve)
    self:ResetSession(true);
    self.SessionServer = server;
    self.StartTime = startTime;
    self.AcceptingReserves = acceptingReserves;
    self.LootCategory = lootCategory;
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
    end

    if starting then
        PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_ENTER_WORLD);
    end
end

function LootReserve.Client:StopSession()
    self.AcceptingReserves = false;
end

function LootReserve.Client:ResetSession(refresh)
    self.SessionServer     = nil;
    self.RemainingReserves = 0;
    self.LootCategory      = nil;
    self.ItemReserves      = { };
    self.ItemConditions    = { };
    self.Equip             = true;
    self.Blind             = false;
    self.Multireserve      = nil;
    self.PendingItems      = { };
    self.PendingOps        = nil;

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

function LootReserve.Client:IsItemReserved(item)
    return #self:GetItemReservers(item) > 0;
end
function LootReserve.Client:IsItemReservedByMe(item)
    for _, player in ipairs(self:GetItemReservers(item)) do
        if LootReserve:IsMe(player) then
            return true;
        end
    end
    return false;
end
function LootReserve.Client:GetItemReservers(item)
    if not self.SessionServer then return { }; end
    return self.ItemReserves[item] or { };
end

function LootReserve.Client:IsItemPending(item)
    return self.PendingItems[item];
end
function LootReserve.Client:SetItemPending(item, pending)
    self.PendingItems[item] = pending or nil;
end

function LootReserve.Client:Reserve(item)
    if not self.SessionServer then return; end
    if not self.AcceptingReserves then return; end
    LootReserve.Client:SetItemPending(item, true);
    LootReserve.Client:UpdateReserveStatus();
    LootReserve.Comm:SendReserveItem(item);
end

function LootReserve.Client:CancelReserve(item)
    if not self.SessionServer then return; end
    if not self.AcceptingReserves then return; end
    LootReserve.Client:SetItemPending(item, true);
    LootReserve.Client:UpdateReserveStatus();
    LootReserve.Comm:SendCancelReserve(item);
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
