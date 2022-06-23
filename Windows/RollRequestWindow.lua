local LibCustomGlow = LibStub("LibCustomGlow-1.0");

local function RollRequested(self, sender, item, players, custom, duration, maxDuration, phase, example)
    local frame = LootReserveRollRequestWindow;

    if LibCustomGlow then
        LibCustomGlow.ButtonGlow_Stop(frame.ItemFrame.IconGlow);
    end

    self.RollRequest = nil;
    frame:Hide();
    
    if item:GetID() == 0 then
        return;
    end

    local _, myCount = LootReserve:GetReservesData(players, LootReserve:Me());
    
    if LootReserve.Client.Settings.RollRequestAutoRollReserved and not custom then
        LootReserve:PrintMessage("Automatically rolling on reserved item: %s%s", item:GetLink(), (myCount or 1) > 1 and ("x" .. myCount) or "");
        if not LootReserve.Client.Settings.RollRequestAutoRollNotified then
            LootReserve:PrintError("Automatic rolling on reserved items can be disabled in Settings.");
            LootReserve.Client.Settings.RollRequestAutoRollNotified = true;
        end
        for i = 1, myCount or 1 do
            RandomRoll(1, 100);
        end
        return;
    end
    
    if not example then
        if not self.Settings.RollRequestShow then return; end
        if not LootReserve:Contains(players, LootReserve:Me()) then return; end
        if custom and not self.Settings.RollRequestShowUnusable and (not LootReserve.ItemConditions:IsItemUsableByMe(item:GetID()) and (not self.Settings.RollRequestShowUnusableBoE or item:GetBindType() == LE_ITEM_BIND_ON_ACQUIRE)) then return; end
    end

    self.RollRequest =
    {
        Sender      = sender,
        Item        = item,
        Custom      = custom or nil,
        Duration    = duration and duration > 0 and duration or nil,
        MaxDuration = maxDuration and maxDuration > 0 and maxDuration or nil,
        Phase       = phase,
        Example     = example,
        Count       = myCount,
    };
    local roll = self.RollRequest;

    local description = LootReserve:GetItemDescription(item:GetID(), true);
    local name, link, texture = item:GetNameLinkTexture();

    frame.Sender = sender;
    frame.Item = item;
    frame.Roll = roll;
    frame.LabelSender:SetText(format(custom and "%s offers for you to roll%s:" or "%s asks you to roll%s on a reserved item:", LootReserve:ColoredPlayer(sender), phase and format(" for |cFF00FF00%s|r", phase) or ""));
    frame.ItemFrame.Icon:SetTexture(texture);
    frame.ItemFrame.Name:SetText((link or name or "|cFFFF4000Loading...|r"):gsub("[%[%]]", ""));
    frame.ItemFrame.Misc:SetText(description);
    frame.ButtonRoll:Disable();
    frame.ButtonRoll:SetAlpha(0.25);
    frame.ButtonRoll.Multi:SetText(format("x%d", myCount));
    frame.ButtonRoll.Multi:SetShown(myCount ~= 1);
    frame.ButtonPass:Disable();
    frame.ButtonPass:SetAlpha(0.25);

    frame.DurationFrame:SetShown(self.RollRequest.MaxDuration);
    local durationHeight = frame.DurationFrame:IsShown() and 20 or 0;
    frame.DurationFrame:SetHeight(math.max(durationHeight, 0.00001));

    frame:SetHeight(90 + durationHeight);
    frame:SetMinResize(300, 90 + durationHeight);
    frame:SetMaxResize(1000, 90 + durationHeight);

    frame:Show();

    C_Timer.After(1, function()
        if frame.Roll == roll then
            frame.ButtonRoll:Enable();
            frame.ButtonRoll:SetAlpha(1);
            frame.ButtonPass:Enable();
            frame.ButtonPass:SetAlpha(1);
            if LibCustomGlow and (not self.Settings.RollRequestGlowOnlyReserved or not roll.Custom) then
                LibCustomGlow.ButtonGlow_Start(frame.ItemFrame.IconGlow);
            end
        end
    end);

    if not name or not link then
        return true;
    end

    if not self.RollMatcherRegistered then
        self.RollMatcherRegistered = true;
        local rollMatcher = LootReserve:FormatToRegexp(RANDOM_ROLL_RESULT);
        LootReserve:RegisterEvent("CHAT_MSG_SYSTEM", function(text)
            if self.RollRequest and frame:IsShown() then
                local player, roll, min, max = text:match(rollMatcher);
                player = player and LootReserve:Player(player);
                if player and LootReserve:IsMe(player) and roll and min == "1" and max == "100" and tonumber(roll) then
                    if self.RollRequest.Count > 1 then
                        self.RollRequest.Count = self.RollRequest.Count - 1;
                        local myCount = self.RollRequest.Count;
                        frame.ButtonRoll.Multi:SetText(format("x%d", myCount));
                        frame.ButtonRoll.Multi:SetShown(myCount ~= 1);
                        frame.ButtonPass:Disable();
                        frame.ButtonPass:SetAlpha(0.25);
                    else
                        frame:Hide();
                    end
                end
            end
        end);
    end
end

function LootReserve.Client:RollRequested(sender, item, ...)
    local args = {...};
    if item:GetID() == 0 then
        RollRequested(LootReserve.Client, sender, item, ...);
    else
        item:OnCache(function()
            return RollRequested(LootReserve.Client, sender, item, unpack(args))
        end);
    end
end

function LootReserve.Client:RespondToRollRequest(response)
    if LibCustomGlow then
        LibCustomGlow.ButtonGlow_Stop(LootReserveRollRequestWindow.ItemFrame.IconGlow);
    end
    LootReserveRollRequestWindow:Hide();

    if not self.RollRequest then return; end

    if not self.RollRequest.Example then
        if response then
            for i = 1, self.RollRequest.Count or 1 do
                RandomRoll(1, 100);
            end
        else
            LootReserve.Comm:SendPassRoll(self.RollRequest.Item);
        end
    end
    self.RollRequest = nil;
end