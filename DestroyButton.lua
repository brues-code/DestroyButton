local addonName = ...
local destroy = CreateFrame("Button", addonName, UIParent, "SecureActionButtonTemplate")

local profInfo = {
    ["prospect"] = {
        tipString = ITEM_PROSPECTABLE,
        spellId = 31252,
        stack = 5,
        fontColor = { r = 1, g = 1, b = 1 }
    },
    ["mill"] = {
        tipString = ITEM_MILLABLE,
        spellId = 51005,
        stack = 5,
        fontColor = { r = 1, g = 1, b = 1 }
    },
    ["lockpick"] = {
        tipString = LOCKED,
        spellId = 1804,
        stack = 1,
        fontColor = { r = 1, g = 0.5, b = 0.25 }
    }
}

local function NormalizeRGBValues(font)
    local function f(v)
        return floor(v * 100 + 0.5) / 100
    end
    local r, g, b = font:GetTextColor()
    return f(r),f(g),f(b)
end

local function CanRun()
    return not LootFrame:IsVisible() and not CastingBarFrame:IsVisible() and not UnitCastingInfo("player") and not MerchantFrame:IsVisible()
end

function destroy:InvSlotHasText(bagSlot, itemSlot, value, startsWith)
    if not self.tooltip then
        self.tooltip = CreateFrame("GameTooltip", self:GetName().."Tooltip", nil, "GameTooltipTemplate")
    end
    self.tooltip:SetOwner(self, ANCHOR_NONE)
    self.tooltip:ClearLines()
    if bagSlot == BANK_CONTAINER then
        local invSlot = BankButtonIDToInvSlotID(itemSlot)
        self.tooltip:SetInventoryItem('player', invSlot)
    else
        self.tooltip:SetBagItem(bagSlot, itemSlot)
    end
    for i = 1, self.tooltip:NumLines() do
        local tipName = ("%sText%%s%s"):format(self.tooltip:GetName(), i)
        local left = _G[tipName:format("Left")]
        local right = _G[tipName:format("Right")]
        local leftText = left:GetText() or ""
        local rightText = right:GetText() or ""
        if startsWith then
            if leftText:find(value) then
                return left
            elseif rightText:find(value) then
                return right
            end
        elseif leftText == value then
            return left
        elseif rightText == value then
            return right
        end
    end
end

function destroy:findmat()
    local function f(bagSlot, itemSlot)
        local _, itemCount = GetContainerItemInfo(bagSlot,itemSlot)
        if itemCount and itemCount >= self.destroyInfo.stack then
            local font = self:InvSlotHasText(bagSlot, itemSlot, self.destroyInfo.tipString)
            if font then
                local r,g,b = NormalizeRGBValues(font)
                local destroyColor = self.destroyInfo.fontColor
                return r == destroyColor.r and g == destroyColor.g and b == destroyColor.b
            end
        end
    end
    for i = 0, 4 do
        for j = 1, GetContainerNumSlots(i) do
            if f(i,j) then
                return i,j
            end
        end
    end
end

function destroy:Setup(destroyType)
    self.destroyInfo = profInfo[destroyType]
    if not self.destroyInfo then
        print(addonName..': INVALID DESTROY TYPE')
        return
    end

    if self:GetAttribute("type") ~= "macro" then
        self:SetAttribute("type", "macro")
    end

    local text = ""
    if CanRun() then
        local b,s = self:findmat()
        if b and s then
            local destroy_spell = GetSpellInfo(self.destroyInfo.spellId)
            text = format( "%s %s\n%s %s %s", SLASH_CAST1, destroy_spell, SLASH_USE1, b, s )
        end
    end

    self:SetAttribute("macrotext",text)
end