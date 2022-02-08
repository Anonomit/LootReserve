function LootReserve.Server.Export:UpdateExportText()
    local members = LootReserve.Server.CurrentSession and LootReserve.Server.CurrentSession.Members or LootReserve.Server.NewSessionSettings.ImportedMembers;
    local text = "";
    if members and next(members) then
        local maxItems = 0
        for player, member in LootReserve:Ordered(members, function(aMember, bMember, aPlayer, bPlayer) return aPlayer < bPlayer; end) do
            text = text .. format("\n%s,%s,%d", player, member.Class and select(2, LootReserve:GetClassInfo(member.Class)) or "", member.ReservesDelta);
            for i, itemID in ipairs(member.ReservedItems) do
                text = text .. format(",%d", itemID);
                maxItems = i > maxItems and i or maxItems;
            end
        end
        text = format("Player,Class,Delta%s", string.rep(",Item", maxItems)) .. text;
    end
    self.Window.Output.Scroll.EditBox:SetText(text);
    self.Window.Output.Scroll.EditBox:SetFocus();
    self.Window.Output.Scroll.EditBox:HighlightText();
    self.Window.Output.Scroll:UpdateScrollChildRect();
end

function LootReserve.Server.Export:OnWindowLoad(window)
    self.Window = window;
    self.Window.TopLeftCorner:SetSize(32, 32); -- Blizzard UI bug?
    self.Window.TitleText:SetText("LootReserve Host - Export");
    self.Window:SetMinResize(250, 130);
    self:UpdateExportText();
end
