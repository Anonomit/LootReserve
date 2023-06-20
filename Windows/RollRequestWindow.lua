local LibCustomGlow = LibStub("LibCustomGlow-1.0");

local function RollRequested(self, sender, item, players, custom, duration, maxDuration, phases, acceptRollsAfterTimerEnded, tiered, example)
    local frame = LootReserveRollRequestWindow;
    
    if item:GetID() == 0 and self.RollRequest and self.RollRequest.Example then
        return;
    end

    if LibCustomGlow then
        LibCustomGlow.ButtonGlow_Stop(frame.ItemFrame.IconGlow);
    end

    frame:Hide();
    
    if item:GetID() == 0 then
        return;
    end

    local _, myCount = LootReserve:GetReservesData(players, LootReserve:Me());
    
    if LootReserve.Client.Settings.RollRequestAutoRollReserved and not custom and (myCount or 0) > 0 then
        LootReserve:PrintMessage("Automatically rolling on reserved item: %s%s", item:GetLink(), (myCount or 1) > 1 and ("x" .. myCount) or "");
        if not LootReserve.Client.Settings.RollRequestAutoRollNotified then
            LootReserve:PrintError("Automatic rolling on reserved items can be disabled in Reserve window settings.");
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
    
    local isFavorite = self:IsFavorite(item:GetID());
    if not isFavorite then
        for _, rewardID in ipairs(LootReserve.Data:GetTokenRewards(item:GetID()) or { }) do
            if self:IsFavorite(rewardID) then
                isFavorite = true;
                break;
            end
        end
    end

    self.RollRequest =
    {
        Sender      = sender,
        Item        = item,
        Custom      = custom or nil,
        Tiered      = tiered or nil,
        Duration    = duration,
        MaxDuration = maxDuration and maxDuration > 0 and maxDuration or nil,
        Phases      = phases,
        Example     = example,
        Count       = myCount,
        Persistent  = acceptRollsAfterTimerEnded,
    };
    local roll = self.RollRequest;

    local description = LootReserve:GetItemDescription(item:GetID(), true);
    local name, link, texture = item:GetNameLinkTexture();

    frame.Sender = sender;
    frame.Item = item;
    frame.Roll = roll;
    local text = format("%s %ss for you to roll%s:", LootReserve:ColoredPlayer(roll.Sender), roll.Custom and "offer" or "ask", roll.Custom and (roll.Phases[1] and format(" for |n|cFF00FF00%s|r", roll.Tiered and strjoin(", ", unpack(roll.Phases)) or roll.Phases[1]) or "") or " on a reserved item");
    frame.LabelSender:SetText(text);
    frame.ItemFrame.Icon:SetTexture(texture);
    frame.ItemFrame.Name:SetText((link or name or "|cFFFF4000Loading...|r"):gsub("[%[%]]", ""));
    frame.ItemFrame.Misc:SetText(description);
    frame.ItemFrame.Favorite:SetShown(isFavorite);
    
    for i, button in ipairs({frame.ButtonRoll1, frame.ButtonRoll2, frame.ButtonRoll3}) do
        button:Disable();
        button:SetAlpha(0.25);
        button.phase = roll.Phases and roll.Phases[i] or "";
        button.PassedIcon:Hide();
    end
    frame.ButtonPass:Disable();
    frame.ButtonPass:SetAlpha(0.25);
    
    local contentWidth = 0;
    if self.RollRequest.Tiered and (not roll.Phases[1] or #roll.Phases >= 3) then
        frame.ButtonRoll3:SetPoint("RIGHT", frame.ButtonPass, "LEFT", -5 - contentWidth, 0);
        frame.ButtonRoll3:Show();
        contentWidth = contentWidth + frame.ButtonRoll3:GetWidth() + 5;
    else
        frame.ButtonRoll3:Hide();
    end
    if self.RollRequest.Tiered and (not roll.Phases[1] or #roll.Phases >= 2) then
        frame.ButtonRoll2:SetPoint("RIGHT", frame.ButtonPass, "LEFT", -5 - contentWidth, 0);
        frame.ButtonRoll2:Show();
        contentWidth = contentWidth + frame.ButtonRoll2:GetWidth() + 5;
    else
        frame.ButtonRoll2:Hide();
    end
    frame.ButtonRoll1:SetPoint("RIGHT", frame.ButtonPass, "LEFT", -5 - contentWidth, 0);
    
    frame.ButtonRoll1.Multi:SetText(format("x%d", myCount));
    frame.ButtonRoll1.Multi:SetShown(myCount ~= 1);

    frame.DurationFrame:SetShown(self.RollRequest.MaxDuration);
    local durationHeight = frame.DurationFrame:IsShown() and 20 or 0;
    frame.DurationFrame:SetHeight(math.max(durationHeight, 0.00001));

    frame:SetHeight(90 + durationHeight);
    LootReserve:SetResizeBounds(frame, 364, 90 + durationHeight, 1000, 90 + durationHeight);
    if frame:GetWidth() < 364 then
        frame:SetWidth(364)
    end

    frame:Show();
    
    if LibCustomGlow and (--[[not self.Settings.RollRequestGlowOnlyReserved or--]] not roll.Custom or isFavorite) then
        LibCustomGlow.ButtonGlow_Start(frame.ItemFrame.IconGlow);
    end

    C_Timer.After(1, function()
        if frame.Roll == roll then
            for _, button in ipairs({frame.ButtonRoll1, frame.ButtonRoll2, frame.ButtonRoll3, frame.ButtonPass}) do
                button:Enable();
                button:SetAlpha(1);
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
                roll, min, max = tonumber(roll), tonumber(min), tonumber(max);
                if player and LootReserve:IsMe(player) and roll and min == 1 and (max == 100 or self.RollRequest.Tiered) then
                    if self.RollRequest.Tiered then
                        local button = ({[100] = frame.ButtonRoll1, [99] = frame.ButtonRoll2, [98] = frame.ButtonRoll3})[max];
                        if button then
                            button:Disable();
                            button:SetAlpha(0.5);
                        end
                        if LootReserve.Client.Settings.RollRequestAutoCloseTiered then
                            frame:Hide();
                        end
                    elseif self.RollRequest.Count > 1 then
                        self.RollRequest.Count = self.RollRequest.Count - 1;
                        local myCount = self.RollRequest.Count;
                        frame.ButtonRoll1.Multi:SetText(format("x%d", myCount));
                        frame.ButtonRoll1.Multi:SetShown(myCount ~= 1);
                        
                        -- disabling pass button in case someone forgets they have a second roll and tries to dismiss the popup
                        frame.ButtonPass:Disable();
                        frame.ButtonPass:SetAlpha(0.5);
                    else
                        frame:Hide();
                    end
                end
            end
        end);
        
        local chatTypes =
        {
            "CHAT_MSG_WHISPER",
            "CHAT_MSG_SAY",
            "CHAT_MSG_YELL",
            "CHAT_MSG_PARTY",
            "CHAT_MSG_PARTY_LEADER",
            "CHAT_MSG_RAID",
            "CHAT_MSG_RAID_LEADER",
            "CHAT_MSG_RAID_WARNING",
            "CHAT_MSG_EMOTE",
            "CHAT_MSG_GUILD",
            "CHAT_MSG_OFFICER",
        };
        for _, eventName in ipairs(chatTypes) do
            LootReserve:RegisterEvent(eventName, function(text, sender)
                if self.RollRequest and frame:IsShown() then
                    if LootReserve:IsMe(sender) then
                        text = text:lower();
                        if text:match("^pa?s*$") or text == "-1" then
                            if LootReserve.Client.Settings.RollRequestAutoCloseTiered or not self.RollRequest.Tiered then
                                frame:Hide();
                            else
                                local success = false;
                                for _, button in ipairs({frame.ButtonRoll1, frame.ButtonRoll2, frame.ButtonRoll3}) do
                                    if not button:IsEnabled() and not button.PassedIcon:IsShown() then
                                        button.PassedIcon:Show();
                                        success = true;
                                        break;
                                    end
                                end
                                if not success then
                                    frame:Hide();
                                end
                            end
                        end
                    end
                end
            end);
        end
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

function LootReserve.Client:RespondToRollRequest(tier)
    if not self.RollRequest then return; end
    
    local frame = LootReserveRollRequestWindow;

    if not self.RollRequest.Example then
        if tier then
            for i = 1, self.RollRequest.Count or 1 do
                RandomRoll(1, tier);
            end
        else
            LootReserve.Comm:SendPassRoll(self.RollRequest.Item);
            local success = false;
            for _, button in ipairs({frame.ButtonRoll1, frame.ButtonRoll2, frame.ButtonRoll3}) do
                if not button:IsEnabled() and not button.PassedIcon:IsShown() then
                    button.PassedIcon:Show();
                    success = true;
                    break;
                end
            end
            if not success then
                frame:Hide();
                return;
            end
        end
    end
    
    if LootReserve.Client.Settings.RollRequestAutoCloseTiered or not self.RollRequest.Tiered then
        frame:Hide();
    end
end