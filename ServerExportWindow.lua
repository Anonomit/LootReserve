function LootReserve.Server.Export:UpdateExportText()
    local members = LootReserve.Server.CurrentSession and LootReserve.Server.CurrentSession.Members or LootReserve.Server.NewSessionSettings.ImportedMembers;
    local text = "";
    if members and next(members) then
        text = text .. "Player,Item";
        for player, member in LootReserve:Ordered(members, function(aMember, bMember, aPlayer, bPlayer) return aPlayer < bPlayer; end) do
            for _, item in ipairs(member.ReservedItems) do
                text = text .. format("\n%s,%d", player, item);
            end
        end
    end
    self.Window.Output.Scroll.EditBox:SetText(text);
    self.Window.Output.Scroll.EditBox:SetFocus();
    self.Window.Output.Scroll.EditBox:HighlightText();
    self.Window.Output.Scroll:UpdateScrollChildRect();
end

function LootReserve.Server.Export:OnWindowLoad(window)
    self.Window = window;
    self.Window.TopLeftCorner:SetSize(32, 32); -- Blizzard UI bug?
    self.Window.TitleText:SetText("Loot Reserve Server - Export");
    self.Window:SetMinResize(250, 130);
    self:UpdateExportText();
end
