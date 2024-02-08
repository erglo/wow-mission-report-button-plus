--------------------------------------------------------------------------------
--[[ libqtip.lua - A collection of wrapper for the LibQTip-1.0 library.]]--
--
-- by erglo <erglo.coder+WAU@gmail.com>
--
-- Copyright (C) 2024  Erwin D. Glockner (aka erglo)
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see http://www.gnu.org/licenses.
--
--------------------------------------------------------------------------------
-- 
-- This is a collection of simple wrapper functions around LibQTip's tooltip
-- methods. Many of these functions are heavily inspired by the WoW GameTooltip
-- API. See <SharedTooltipTemplates.lua> for more.
--
-- Further reading:
-- REF.: <https://www.wowace.com/projects/libqtip-1-0/pages/api-reference>  <br>
-- REF.: <https://www.townlong-yak.com/framexml/live/SharedTooltipTemplates.lua>
-- REF.: <https://www.townlong-yak.com/framexml/live/QuestUtils.lua>
-- REF.: <https://www.townlong-yak.com/framexml/live/Helix/GlobalColors.lua>
-- REF.: <https://www.townlong-yak.com/framexml/live/SharedColorConstants.lua>
-- 
--------------------------------------------------------------------------------

local AddonID, ns = ...

local LocalLibQTipUtil = {}
ns.utils = ns.utils or {}
ns.utils.libqtip = LocalLibQTipUtil

----- Wrapper ------------------------------------------------------------------

-- Add a new empty line to the bottom of the LibQTip tooltip.
--> See `LibQTip.Tooltip.AddLine` for more.
---@param tooltip LibQTip.Tooltip  The `LibQTip.Tooltip` frame.
---@param ... any  Values redirected to `LibQTip.Tooltip.AddLine`.
---@return number lineIndex  The index of the newly added line.
---@return number columnIndex  The index of the next empty cell in the line or nil if it is full.
function LocalLibQTipUtil:AddBlankLineToTooltip(tooltip, ...)
    return tooltip:AddLine(" ")
end

-- Add a new line with text in given font color to the bottom of the LibQTip tooltip.
--> See `LibQTip.Tooltip.AddLine` for more.
---@param tooltip LibQTip.Tooltip  The `LibQTip.Tooltip` frame.
---@param FontColor ColorMixin  A color from eg. <GlobalColors.lua> or <SharedColorConstants.lua>
---@param ... any  Values redirected to `LibQTip.Tooltip.AddLine`.
---@return number lineIndex  The index of the newly added line.
---@return number columnIndex  The index of the next empty cell in the line or nil if it is full.
function LocalLibQTipUtil:AddColoredLine(tooltip, FontColor, ...)
    local lineIndex, columnIndex = tooltip:AddLine(...)
    tooltip:SetLineTextColor(lineIndex, FontColor:GetRGBA())
    return lineIndex, columnIndex
end

-- Add a new line with GRAY text to the bottom of the LibQTip tooltip.
--> See `LibQTip.Tooltip.AddLine` for more.
---@param tooltip LibQTip.Tooltip  The `LibQTip.Tooltip` frame.
---@param ... any  Values redirected to `LibQTip.Tooltip.AddLine`.
---@return number lineIndex  The index of the newly added line.
---@return number columnIndex  The index of the next empty cell in the line or nil if it is full.
function LocalLibQTipUtil:AddDisabledLine(tooltip, ...)
    local lineIndex, columnIndex = tooltip:AddLine(...)
    tooltip:SetLineTextColor(lineIndex, DISABLED_FONT_COLOR:GetRGBA())
    return lineIndex, columnIndex
end

-- Add a new line with RED text to the bottom of the LibQTip tooltip.
--> See `LibQTip.Tooltip.AddLine` for more.
---@param tooltip LibQTip.Tooltip  The `LibQTip.Tooltip` frame.
---@param ... any  Values redirected to `LibQTip.Tooltip.AddLine`.
---@return number lineIndex  The index of the newly added line.
---@return number columnIndex  The index of the next empty cell in the line or nil if it is full.
function LocalLibQTipUtil:AddErrorLine(tooltip, ...)
    local lineIndex, columnIndex = tooltip:AddLine(...)
    tooltip:SetLineTextColor(lineIndex, RED_FONT_COLOR:GetRGBA())
    return lineIndex, columnIndex
end

-- Add a new line with 'highlighted' (white) text color to the bottom of the LibQTip tooltip.
--> See `LibQTip.Tooltip.AddLine` for more.
---@param tooltip LibQTip.Tooltip  The `LibQTip.Tooltip` frame.
---@param ... any  Values redirected to `LibQTip.Tooltip.AddLine`.
---@return number lineIndex  The index of the newly added line.
---@return number columnIndex  The index of the next empty cell in the line or nil if it is full.
function LocalLibQTipUtil:AddHighlightLine(tooltip, ...)
    local lineIndex, columnIndex = tooltip:AddLine(...)
    tooltip:SetLineTextColor(lineIndex, HIGHLIGHT_FONT_COLOR:GetRGBA())
    return lineIndex, columnIndex
end

-- Add a new line with GREEN text to the bottom of the LibQTip tooltip.
--> See `LibQTip.Tooltip.AddLine` for more.
---@param tooltip LibQTip.Tooltip  The `LibQTip.Tooltip` frame.
---@param ... any  Values redirected to `LibQTip.Tooltip.AddLine`.
---@return number lineIndex  The index of the newly added line.
---@return number columnIndex  The index of the next empty cell in the line or nil if it is full.
function LocalLibQTipUtil:AddInstructionLine(tooltip, ...)
    local lineIndex, columnIndex = tooltip:AddLine(...)
    tooltip:SetLineTextColor(lineIndex, GREEN_FONT_COLOR:GetRGBA())
    return lineIndex, columnIndex
end

-- Add a new line with 'normal' (golden) text color to the bottom of the LibQTip tooltip.
--> See `LibQTip.Tooltip.AddLine` for more.
---@param tooltip LibQTip.Tooltip  The `LibQTip.Tooltip` frame.
---@param ... any  Values redirected to `LibQTip.Tooltip.AddLine`.
---@return number lineIndex  The index of the newly added line.
---@return number columnIndex  The index of the next empty cell in the line or nil if it is full.
function LocalLibQTipUtil:AddNormalLine(tooltip, ...)
    local lineIndex, columnIndex = tooltip:AddLine(...)
    tooltip:SetLineTextColor(lineIndex, NORMAL_FONT_COLOR:GetRGBA())
    return lineIndex, columnIndex
end

-- Add a new header line with 'highlighted' (white) text color and a slightly bigger font size to the bottom of the LibQTip tooltip.
--> See `LibQTip.Tooltip.AddHeader` for more.
---@param tooltip LibQTip.Tooltip  The `LibQTip.Tooltip` frame.
---@param ... any  Values redirected to `LibQTip.Tooltip.AddHeader`.
---@return number lineIndex  The index of the newly added line.
---@return number columnIndex  The index of the next empty cell in the line or nil if it is full.
function LocalLibQTipUtil:SetTitle(tooltip, ...)
    local lineIndex, columnIndex = tooltip:AddHeader(...)
    tooltip:SetLineTextColor(lineIndex, HIGHLIGHT_FONT_COLOR:GetRGBA())
    return lineIndex, columnIndex
end

-- Add a new header line with text in given font color and a slightly bigger font size to the bottom of the LibQTip tooltip.
--> See `LibQTip.Tooltip.AddHeader` for more.
---@param tooltip LibQTip.Tooltip  The `LibQTip.Tooltip` frame.
---@param FontColor ColorMixin  A color from eg. <GlobalColors.lua> or <SharedColorConstants.lua>
---@param ... any  Values redirected to `LibQTip.Tooltip.AddLine`.
---@return number lineIndex  The index of the newly added line.
---@return number columnIndex  The index of the next empty cell in the line or nil if it is full.
function LocalLibQTipUtil:SetColoredTitle(tooltip, FontColor, ...)
    local lineIndex, columnIndex = tooltip:AddHeader(...)
    tooltip:SetLineTextColor(lineIndex, FontColor:GetRGBA())
    return lineIndex, columnIndex
end

----- Quest Type Tags ----------------------------------------------------------

-- Retrieve the quest type icon from given tag ID and decorate a text with it.
-- Needed for `LocalLibQTipUtil.AddQuestTagTooltipLine`, but borrowed from REF. below.
-- Credits go to the authors of that file.
--> REF.: [QuestUtils.lua](https://www.townlong-yak.com/framexml/live/QuestUtils.lua)
local function GetQuestTypeIconMarkupStringFromTagData(tagID, worldQuestType, text, iconWidth, iconHeight)
	local atlasName = QuestUtils_GetQuestTagAtlas(tagID, worldQuestType)
	if atlasName then
		iconWidth = iconWidth or 20
		iconHeight = iconHeight or 20
		local atlasMarkup = CreateAtlasMarkup(atlasName, iconWidth, iconHeight)
		return string.format("%s %s", atlasMarkup, text)
	end
end

-- Add a new line with given quest type tag in 'normal' (golden) text color to
-- the bottom of the LibQTip tooltip.
--> See `LibQTip.Tooltip.AddLine` for more.<br>
--> Also see [QuestUtils.lua](https://www.townlong-yak.com/framexml/live/QuestUtils.lua) for more.
---@param tooltip LibQTip.Tooltip  The `LibQTip.Tooltip` frame.
---@param ... any  Values redirected to `LibQTip.Tooltip.AddLine`.
---@return number|nil lineIndex  The index of the newly added line.
---@return number|nil columnIndex  The index of the next empty cell in the line or nil if it is full.
function LocalLibQTipUtil:AddQuestTagTooltipLine(tooltip, tagName, tagID, worldQuestType, color, iconWidth, iconHeight, ...)
    local tooltipLine = GetQuestTypeIconMarkupStringFromTagData(tagID, worldQuestType, tagName, iconWidth, iconHeight)
	if tooltipLine then
        local lineIndex, columnIndex = tooltip:AddLine(tooltipLine, ...)
        local LineColor = color or NORMAL_FONT_COLOR
        tooltip:SetLineTextColor(lineIndex, LineColor:GetRGBA())
        return lineIndex, columnIndex
	end
end

----- Convenience --------------------------------------------------------------

-- Copy the GameTooltip's left side text to the given LibQTip tooltip.
---@param tooltip LibQTip.Tooltip  The `LibQTip.Tooltip` frame.
---@param FontColor ColorMixin|nil  An optional color for the header from eg. <GlobalColors.lua> or <SharedColorConstants.lua>. Defaults to NORMAL_FONT_COLOR.
function LocalLibQTipUtil:CopyGameTooltipTo(tooltip, FontColor)
    local GameTooltip = _G.GameTooltip
    local headerLine = _G[GameTooltip:GetName() .. "TextLeft" .. 1]:GetText()
    self:SetColoredTitle(tooltip, FontColor or NORMAL_FONT_COLOR, headerLine)
    local line, text
    for i = 2, GameTooltip:NumLines() do
        line = _G[GameTooltip:GetName() .. "TextLeft" .. i]
        text = line and line:GetText() or ''
        tooltip:AddLine(text)
    end
end
