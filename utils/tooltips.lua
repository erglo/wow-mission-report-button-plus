--------------------------------------------------------------------------------
--[[ tooltips.lua - Utilities for handling MRBP tooltips. ]]--
--
-- by erglo <erglo.coder+MRBP@gmail.com>
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

local AddonID, ns = ...
local ShortAddonID = "MRBP"
local L = ns.L
local util = ns.utilities

local LibQTip = LibStub('LibQTip-1.0')
local LocalLibQTipUtil = ns.utils.libqtip
-- local MenuTooltip, ExpansionTooltip 

----- Upvalues -----

local format = string.format

----- Colors -----

local DIM_RED_FONT_COLOR = DIM_RED_FONT_COLOR
local DISABLED_FONT_COLOR = DISABLED_FONT_COLOR
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR
local LIGHTGRAY_FONT_COLOR = LIGHTGRAY_FONT_COLOR
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR
local RED_FONT_COLOR = RED_FONT_COLOR
local WARNING_FONT_COLOR = WARNING_FONT_COLOR
local WHITE_FONT_COLOR = WHITE_FONT_COLOR

local TOOLTIP_HEADER_FONT_COLOR = NORMAL_FONT_COLOR
local TOOLTIP_HEADER_SEPARATOR_COLOR = LIGHTGRAY_FONT_COLOR
local TOOLTIP_TEXT_FONT_COLOR = WHITE_FONT_COLOR

----- Icons -----

local TOOLTIP_DASH_ICON_ID = 3083385
local TOOLTIP_DASH_ICON_STRING = util.CreateInlineIcon(3083385)
local TOOLTIP_CLOCK_ICON_STRING = util.CreateInlineIcon1("auctionhouse-icon-clock")
local TOOLTIP_CHECK_MARK_ICON_STRING = util.CreateInlineIcon(628564)
local TOOLTIP_YELLOW_CHECK_MARK_ICON_STRING = util.CreateInlineIcon(130751)
-- local TOOLTIP_GRAY_CHECK_MARK_ICON_STRING = util.CreateInlineIcon(130750)
-- local TOOLTIP_ORANGE_CHECK_MARK_ICON_STRING = util.CreateInlineIcon("Adventures-Checkmark")

----- Strings -----

local HEADER_COLON = HEADER_COLON
local PARENS_TEMPLATE = PARENS_TEMPLATE
local GENERIC_FRACTION_STRING = GENERIC_FRACTION_STRING
local MAJOR_FACTION_BUTTON_RENOWN_LEVEL = MAJOR_FACTION_BUTTON_RENOWN_LEVEL
local MAJOR_FACTION_MAX_RENOWN_REACHED = MAJOR_FACTION_MAX_RENOWN_REACHED
local MAJOR_FACTION_BUTTON_FACTION_LOCKED = MAJOR_FACTION_BUTTON_FACTION_LOCKED
local TRADESKILL_NAME_RANK = TRADESKILL_NAME_RANK
local YOU_COLLECTED_LABEL = YOU_COLLECTED_LABEL
local PROFESSIONS_CURRENCY_AVAILABLE = PROFESSIONS_CURRENCY_AVAILABLE
local DRAGON_RIDING_CURRENCY_TUTORIAL = DRAGON_RIDING_CURRENCY_TUTORIAL

local TEXT_DELIMITER = ITEM_NAME_DESCRIPTION_DELIMITER

-- Return given text in an optional font color (defaults to white) delimited by 1 space character.
---@param text string
---@param color table|nil  A color class (see <FrameXML/GlobalColors.lua>); defaults to TOOLTIP_TEXT_FONT_COLOR
---@return string tooltipText
--
local function AppendText(text, color)
    local FontColor = color or TOOLTIP_TEXT_FONT_COLOR
    return TEXT_DELIMITER..FontColor:WrapTextInColorCode(text)
end

----- LibQTip -----

-- REF.: qTip:SetCell(lineNum, colNum, value[, font][, justification][, colSpan][, provider][, leftPadding][, rightPadding][, maxWidth][, minWidth][, ...])
local GetDefaultCellStyle = function()
	return SafeUnpack({
		nil,	--> font 
		"LEFT",	--> justification 
		nil,	--> colSpan 
		nil,	--> provider 
		nil,	--> leftPadding 
		nil,	--> rightPadding 
		230,	--> maxWidth 
		150,	--> minWidth 
	})
end

local function Tooltip_AddHeaderLine(tooltip, text, TextColor, isTooltipTitle, ...)
    local FontColor = TextColor or TOOLTIP_HEADER_FONT_COLOR
	if isTooltipTitle then
    	local lineIndex, nextColumnIndex = LocalLibQTipUtil:SetColoredTitle(tooltip, FontColor, text, ...)
		return lineIndex, nextColumnIndex
	end
	LocalLibQTipUtil:AddBlankLineToTooltip(tooltip)
	local lineIndex, nextColumnIndex = LocalLibQTipUtil:AddColoredLine(tooltip, FontColor, '', ...)
	tooltip:SetCell(lineIndex, 1, text, GetDefaultCellStyle())
	lineIndex, nextColumnIndex = tooltip:AddSeparator(2, TOOLTIP_HEADER_SEPARATOR_COLOR:GetRGBA())
    return lineIndex, nextColumnIndex
end

local function Tooltip_AddTextLine(tooltip, text, TextColor, ...)
	if L:StringIsEmpty(text) then
        return
    end
	local FontColor = TextColor or TOOLTIP_TEXT_FONT_COLOR
	local lineIndex, nextColumnIndex = LocalLibQTipUtil:AddColoredLine(tooltip, FontColor, '', ...)
	tooltip:SetCell(lineIndex, 1, text, GetDefaultCellStyle())
	return lineIndex, nextColumnIndex
end

local function Tooltip_AddIconLine(tooltip, text, icon, TextColor, ...)
	if not icon then
		return Tooltip_AddTextLine(tooltip, text, TextColor, ...)
	end
	local iconString = util.CreateInlineIcon1(icon)  --> with yOffset = -1
	return Tooltip_AddTextLine(tooltip, iconString..TEXT_DELIMITER..text, TextColor, ...)
end

local function Tooltip_AddObjectiveLine(tooltip, text, completed, TextColor, ...)
	if L:StringIsEmpty(text) then
        return
    end
	local iconString = completed and TOOLTIP_CHECK_MARK_ICON_STRING or TOOLTIP_DASH_ICON_STRING
	return Tooltip_AddTextLine(tooltip, iconString..TEXT_DELIMITER..text, completed and DISABLED_FONT_COLOR or TextColor, ...)
end

local function Tooltip_AddAchievementLine(tooltip, text, icon, TextColor, completed, ...)
	if not completed then
		return Tooltip_AddIconLine(tooltip, text, icon, TextColor, ...)
	end
	local lineText = text..TEXT_DELIMITER..TOOLTIP_YELLOW_CHECK_MARK_ICON_STRING
	return Tooltip_AddIconLine(tooltip, lineText, icon, completed and DISABLED_FONT_COLOR or TextColor, ...)
end

local function Tooltip_AddTimeRemainingLine(tooltip, timeString, ...)
	local text = timeString or RED_FONT_COLOR:WrapTextInColorCode(RETRIEVING_DATA)
	local iconString = TOOLTIP_DASH_ICON_STRING..TEXT_DELIMITER..TOOLTIP_CLOCK_ICON_STRING
	return Tooltip_AddTextLine(tooltip, iconString..TEXT_DELIMITER..text, ...)
end

----- MRBP content -----

local function GetMajorFactionIcon(majorFactionData)
	if (majorFactionData.expansionID == util.expansion.data.Dragonflight.ID) then
		return "MajorFactions_MapIcons_"..majorFactionData.textureKit.."64"
	end
end

-- Requires expansionID, eg. util.expansion.data.Dragonflight.ID
local function Tooltip_AddMajorFactionsRenownLines(tooltip, expansionID)
	local majorFactionData = util.garrison.GetAllMajorFactionDataForExpansion(expansionID)
	for _, factionData in ipairs(majorFactionData) do
		if factionData then
			local factionIcon = GetMajorFactionIcon(factionData)
			local FactionColor = ns.settings.applyMajorFactionColors and util.garrison.GetMajorFactionColor(factionData) or TOOLTIP_TEXT_FONT_COLOR
			Tooltip_AddIconLine(tooltip, factionData.name, factionIcon, FactionColor)
			if factionData.isUnlocked then
				-- Show current renown progress
				local renownLevelText = MAJOR_FACTION_BUTTON_RENOWN_LEVEL:format(factionData.renownLevel)
				local progressText = GENERIC_FRACTION_STRING:format(factionData.renownReputationEarned, factionData.renownLevelThreshold)
				local hasMaxRenown = util.garrison.HasMaximumMajorFactionRenown(factionData.factionID)
				local renownLevelSuffix = AppendText(PARENS_TEMPLATE:format(renownLevelText), hasMaxRenown and DISABLED_FONT_COLOR or NORMAL_FONT_COLOR)
				local lineText = hasMaxRenown and MAJOR_FACTION_MAX_RENOWN_REACHED or progressText
				Tooltip_AddObjectiveLine(tooltip, lineText..renownLevelSuffix, hasMaxRenown)
				if util.garrison.IsFactionParagon(factionData.factionID) then
					local paragonInfo = util.garrison.GetFactionParagonInfo(factionData.factionID)
					local bagIcon = paragonInfo.hasRewardPending and "Levelup-Icon-Bag" or "ParagonReputation_Bag"
					local bagIconString = util.CreateInlineIcon(bagIcon, 13, 15, 3, 0)
					local paragonProgressText = util.garrison.GetFactionParagonProgressText(paragonInfo)
					Tooltip_AddObjectiveLine(tooltip, paragonProgressText..bagIconString)
				end
			else
				-- Major Faction is not unlocked, yet :(
				Tooltip_AddObjectiveLine(tooltip, MAJOR_FACTION_BUTTON_FACTION_LOCKED, nil, DISABLED_FONT_COLOR)
				if not ns.settings.hideMajorFactionUnlockDescription then
					Tooltip_AddObjectiveLine(tooltip, factionData.unlockDescription, nil, DISABLED_FONT_COLOR)
				end
			end
		end
	end
end

local function Tooltip_AddDragonGlyphLines(tooltip)
	local glyphsPerZone, numGlyphsCollected, numGlyphsTotal = util.garrison.GetDragonGlyphsCount()
	-- Show collected glyphs per zone
	for mapName, count in pairs(glyphsPerZone) do
		local isComplete = count.numComplete == count.numTotal
		if not (isComplete and ns.settings.autoHideCompletedDragonGlyphZones) then
            local zoneName = mapName..HEADER_COLON
			local counterText = GENERIC_FRACTION_STRING:format(count.numComplete, count.numTotal)
			local lineColor = isComplete and DISABLED_FONT_COLOR or NORMAL_FONT_COLOR
            local resultsText = AppendText(counterText, lineColor)
			Tooltip_AddObjectiveLine(tooltip, zoneName..resultsText, isComplete)
		end
	end
	-- Add glyph collection summary
	local treeCurrencyInfo = util.garrison.GetDragonRidingTreeCurrencyInfo()
	local youCollectedAmountString = TRADESKILL_NAME_RANK:format(YOU_COLLECTED_LABEL, numGlyphsCollected, numGlyphsTotal)
	local collectedAll = numGlyphsCollected == numGlyphsTotal
	local lineColor = collectedAll and DISABLED_FONT_COLOR or NORMAL_FONT_COLOR
	local lineSuffix = collectedAll and TEXT_DELIMITER..TOOLTIP_CHECK_MARK_ICON_STRING or ''
	Tooltip_AddIconLine(tooltip, youCollectedAmountString..lineSuffix, treeCurrencyInfo.texture, lineColor)
	if (treeCurrencyInfo.quantity > 0) then
		-- Inform user that there are glyphs to spend
		local currencySymbolString = util.CreateInlineIcon(treeCurrencyInfo.texture, 16, 16, 0, -1)
		local availableAmountText = PROFESSIONS_CURRENCY_AVAILABLE:format(treeCurrencyInfo.quantity, currencySymbolString)
		Tooltip_AddObjectiveLine(tooltip, availableAmountText)
	end
	if (numGlyphsCollected == 0) then
		-- Inform player on how to get some glyphs
		Tooltip_AddIconLine(tooltip, DRAGON_RIDING_CURRENCY_TUTORIAL, treeCurrencyInfo.texture, DISABLED_FONT_COLOR)
	end
end

----- Missions -----

local function Tooltip_AddGarrisonMissionLines(tooltip, garrisonTypeID, garrisonInfo, shouldShowMissionCompletedMessage)
    local numInProgress, numCompleted = util.garrison.GetInProgressMissionCount(expansionInfo.garrisonTypeID)
	local hasCompletedAllMissions = numCompleted > 0 and numCompleted == numInProgress
	Tooltip_AddHeaderLine(tooltip, garrisonInfo.msg.missionsTitle)
	-- Mission counter
	if (numInProgress > 0) then
		local progressText = format(garrisonInfo.msg.missionsReadyCount, numCompleted, numInProgress)
		Tooltip_AddObjectiveLine(tooltip, progressText, hasCompletedAllMissions)
	else
		-- No missions active
		Tooltip_AddTextLine(tooltip, garrisonInfo.msg.missionsEmptyProgress)
	end
	-- Return to base info
	if shouldShowMissionCompletedMessage then
		Tooltip_AddTextLine(tooltip, garrisonInfo.msg.missionsComplete)
    end
end

----- Bounty board -----

local QuestUtils_GetQuestName = QuestUtils_GetQuestName
local CovenantCalling_CheckCallings = CovenantCalling_CheckCallings
local CreateTextureMarkup = CreateTextureMarkup

local function Tooltip_AddBountyBoardLines(tooltip, expansionInfo, garrisonInfo)
    local isForLegion = expansionInfo.garrisonTypeID == util.expansion.data.Legion.garrisonTypeID
	local isForBattleForAzeroth = expansionInfo.garrisonTypeID == util.expansion.data.BattleForAzeroth.garrisonTypeID
	local isForShadowlands = expansionInfo.garrisonTypeID == util.expansion.data.Shadowlands.garrisonTypeID
	
    -- Only available since Legion (WoW 7.x); no longer useful in Dragonflight (WoW 10.x)
	local bountyBoard = garrisonInfo.bountyBoard
	if bountyBoard.AreBountiesUnlocked() then
		local bounties = bountyBoard.GetBounties()
		if (isForShadowlands and #bounties == 0) then
			-- System retrieves callings through event listening and on opening the mission frame; try to update (again).
			CovenantCalling_CheckCallings()
			bounties = bountyBoard.GetBounties()
		end
		if (#bounties > 0) then
			Tooltip_AddHeaderLine(tooltip, bountyBoard.title)
			for _, bountyData in ipairs(bounties) do
				if bountyData then
					local questName = QuestUtils_GetQuestName(bountyData.questID)
					if isForShadowlands then
						-- Shadowland bounties have a golden border around their icon; need special treatment.
						-- REF.: CreateTextureMarkup(file, fileWidth, fileHeight, width, height, left, right, top, bottom, xOffset, yOffset)
						local iconString = CreateTextureMarkup(bountyData.icon, 256, 256, 16, 16, 0.28, 0.74, 0.26, 0.72, 1, -1)
						questName = iconString..TEXT_DELIMITER..questName
					end
					local bountyIcon = not isForShadowlands and bountyData.icon or nil
					if bountyData.turninRequirementText then
						Tooltip_AddIconLine(tooltip, questName, bountyIcon, DISABLED_FONT_COLOR)
						-- if ns.settings.showBountyRequirements then		--> TODO - Re-add option to settings
						Tooltip_AddObjectiveLine(tooltip, bountyData.turninRequirementText, nil, WARNING_FONT_COLOR)
						-- end
					else
						Tooltip_AddIconLine(tooltip, questName, bountyIcon)
					end
				end
			end
		elseif not isForShadowlands then									    --> TODO - Check if still needed
			Tooltip_AddObjectiveLine(tooltip, bountyBoard.noBountiesMessage)
		end
	end
end

--------------------------------------------------------------------------------
