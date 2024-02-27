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

local LocalTooltipUtil = {}  --> Handler from this file
ns.utilities.tooltip = LocalTooltipUtil

local LibQTip = LibStub('LibQTip-1.0')
local LocalLibQTipUtil = ns.utils.libqtip
-- local MenuTooltip, ExpansionTooltip 

----- Upvalues -----

local format = string.format
local QuestUtils_GetQuestName = QuestUtils_GetQuestName
local CovenantCalling_CheckCallings = CovenantCalling_CheckCallings
local CreateTextureMarkup = CreateTextureMarkup
-- local CreateAtlasMarkup = CreateAtlasMarkup

----- Colors -----

local DISABLED_FONT_COLOR = DISABLED_FONT_COLOR
local LIGHTGRAY_FONT_COLOR = LIGHTGRAY_FONT_COLOR
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR
local RED_FONT_COLOR = RED_FONT_COLOR
local WARNING_FONT_COLOR = WARNING_FONT_COLOR
local WHITE_FONT_COLOR = WHITE_FONT_COLOR

local TOOLTIP_HEADER_FONT_COLOR = NORMAL_FONT_COLOR
local TOOLTIP_HEADER_SEPARATOR_COLOR = LIGHTGRAY_FONT_COLOR
local TOOLTIP_TEXT_FONT_COLOR = WHITE_FONT_COLOR

----- Icons -----

local TOOLTIP_DASH_ICON_STRING = util.CreateInlineIcon(3083385, 16)
local TOOLTIP_CLOCK_ICON_STRING = util.CreateInlineIcon("auctionhouse-icon-clock", 16)
local TOOLTIP_CHECK_MARK_ICON_STRING = util.CreateInlineIcon(628564, 16)
local TOOLTIP_YELLOW_CHECK_MARK_ICON_STRING = util.CreateInlineIcon(130751, 16, 16, 1)
local TOOLTIP_BAG_ICON_STRING = util.CreateInlineIcon("ParagonReputation_Bag", 13, 15)
local TOOLTIP_BAG_FULL_ICON_STRING = TOOLTIP_BAG_ICON_STRING..util.CreateInlineIcon("ParagonReputation_Checkmark", 14, 12, -9, -1)

----- Strings -----

local HEADER_COLON = HEADER_COLON
local PARENS_TEMPLATE = PARENS_TEMPLATE
local GENERIC_FRACTION_STRING = GENERIC_FRACTION_STRING
local MAJOR_FACTION_BUTTON_RENOWN_LEVEL = MAJOR_FACTION_BUTTON_RENOWN_LEVEL
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
local function AppendColoredText(text, color)
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

function LocalTooltipUtil:AddHeaderLine(tooltip, text, TextColor, isTooltipTitle, ...)
    local FontColor = TextColor or TOOLTIP_HEADER_FONT_COLOR
	if isTooltipTitle then
    	local lineIndex, nextColumnIndex = LocalLibQTipUtil:SetTitle(tooltip, text, ...)
		return lineIndex, nextColumnIndex
	end
	LocalLibQTipUtil:AddBlankLineToTooltip(tooltip)
	local lineIndex, nextColumnIndex = LocalLibQTipUtil:AddColoredLine(tooltip, FontColor, '', ...)
	tooltip:SetCell(lineIndex, 1, text, GetDefaultCellStyle())
	lineIndex, nextColumnIndex = tooltip:AddSeparator(2, TOOLTIP_HEADER_SEPARATOR_COLOR:GetRGBA())
    return lineIndex, nextColumnIndex
end

function LocalTooltipUtil:AddTextLine(tooltip, text, TextColor, ...)
	if L:StringIsEmpty(text) then
        return
    end
	local FontColor = TextColor or TOOLTIP_TEXT_FONT_COLOR
	local lineIndex, nextColumnIndex = LocalLibQTipUtil:AddColoredLine(tooltip, FontColor, '', ...)
	tooltip:SetCell(lineIndex, 1, text, GetDefaultCellStyle())
	return lineIndex, nextColumnIndex
end

function LocalTooltipUtil:AddIconLine(tooltip, text, icon, TextColor, ...)
	if not icon then
		return self:AddTextLine(tooltip, text, TextColor, ...)
	end
	local iconString = util.CreateInlineIcon(icon)
	return self:AddTextLine(tooltip, iconString..TEXT_DELIMITER..text, TextColor, ...)
end

function LocalTooltipUtil:AddObjectiveLine(tooltip, text, completed, TextColor, ...)
	if L:StringIsEmpty(text) then
        return
    end
	local iconString = completed and TOOLTIP_CHECK_MARK_ICON_STRING or TOOLTIP_DASH_ICON_STRING
	return self:AddTextLine(tooltip, iconString..TEXT_DELIMITER..text, completed and DISABLED_FONT_COLOR or TextColor, ...)
end

function LocalTooltipUtil:AddAchievementLine(tooltip, text, icon, TextColor, completed, ...)
	if not completed then
		return self:AddIconLine(tooltip, text, icon, TextColor, ...)
	end
	local lineText = text..TOOLTIP_YELLOW_CHECK_MARK_ICON_STRING
	return self:AddIconLine(tooltip, lineText, icon, completed and DISABLED_FONT_COLOR or TextColor, ...)
end

function LocalTooltipUtil:AddTimeRemainingLine(tooltip, timeString, ...)
	local text = timeString or RED_FONT_COLOR:WrapTextInColorCode(RETRIEVING_DATA)
	local iconString = TOOLTIP_DASH_ICON_STRING..TEXT_DELIMITER..TOOLTIP_CLOCK_ICON_STRING
	return self:AddTextLine(tooltip, iconString..TEXT_DELIMITER..text, ...)
end

----- MRBP content -----

local function GetMajorFactionIcon(majorFactionData)
	if (majorFactionData.expansionID == util.expansion.data.Dragonflight.ID) then
		return "MajorFactions_MapIcons_"..majorFactionData.textureKit.."64"
	end
end

-- Requires expansionInfo, eg. util.expansion.data.Dragonflight
function LocalTooltipUtil:AddMajorFactionsRenownLines(tooltip, expansionInfo)
	local majorFactionData = util.garrison.GetAllMajorFactionDataForExpansion(expansionInfo.ID)
	if #majorFactionData then
		if (tooltip.key == ShortAddonID.."LibQTipReputationTooltip") then
			-- self:AddHeaderLine(tooltip, L["showMajorFactionRenownLevel"], nil, true)
			self:AddHeaderLine(tooltip, expansionInfo.name, nil, true)
		end
		self:AddHeaderLine(tooltip, L["showMajorFactionRenownLevel"])
		for _, factionData in ipairs(majorFactionData) do
			local factionIcon = GetMajorFactionIcon(factionData)
			local FactionColor = ns.settings.applyMajorFactionColors and util.garrison.GetMajorFactionColor(factionData) or TOOLTIP_TEXT_FONT_COLOR
			self:AddIconLine(tooltip, factionData.name, factionIcon, FactionColor)
			if factionData.isUnlocked then
				-- Show current renown progress
				local levelText = MAJOR_FACTION_BUTTON_RENOWN_LEVEL:format(factionData.renownLevel)
				local progressText = GENERIC_FRACTION_STRING:format(factionData.renownReputationEarned, factionData.renownLevelThreshold)
				local progressTextParens = AppendColoredText(PARENS_TEMPLATE:format(progressText), TOOLTIP_TEXT_FONT_COLOR)
				-- local hasMaxRenown = util.garrison.HasMaximumMajorFactionRenown(factionData.factionID)
				if not util.garrison.IsFactionParagon(factionData.factionID) then
					self:AddObjectiveLine(tooltip, levelText..TEXT_DELIMITER..progressTextParens) -- , nil, hasMaxRenown and DISABLED_FONT_COLOR)
				else
					local paragonInfo = util.garrison.GetFactionParagonInfo(factionData.factionID)
					local bagIconString = paragonInfo.hasRewardPending and TOOLTIP_BAG_FULL_ICON_STRING or TOOLTIP_BAG_ICON_STRING
					progressText = util.garrison.GetFactionParagonProgressText(paragonInfo)
					progressTextParens = AppendColoredText(PARENS_TEMPLATE:format(progressText), TOOLTIP_TEXT_FONT_COLOR)
					self:AddObjectiveLine(tooltip, levelText..TEXT_DELIMITER..progressTextParens..TEXT_DELIMITER..bagIconString, nil, DISABLED_FONT_COLOR)
					if paragonInfo.hasRewardPending then
						local completionText = util.garrison.GetParagonCompletionText(paragonInfo)
						self:AddObjectiveLine(tooltip, completionText)
					end
				end
			else
				-- Major Faction is not unlocked, yet :(
				self:AddObjectiveLine(tooltip, MAJOR_FACTION_BUTTON_FACTION_LOCKED, nil, DISABLED_FONT_COLOR)
				if not ns.settings.hideMajorFactionUnlockDescription then
					self:AddObjectiveLine(tooltip, factionData.unlockDescription, nil, DISABLED_FONT_COLOR)
				end
			end
		end
	end
end

function LocalTooltipUtil:AddDragonGlyphLines(tooltip)
	if util.garrison.IsDragonridingUnlocked() then
		local glyphsPerZone, numGlyphsCollected, numGlyphsTotal = util.garrison.GetDragonGlyphsCount()
		-- Show collected glyphs per zone
		for mapName, count in pairs(glyphsPerZone) do
			local isComplete = count.numComplete == count.numTotal
			if not (isComplete and ns.settings.autoHideCompletedDragonGlyphZones) then
				local zoneName = mapName..HEADER_COLON
				local counterText = GENERIC_FRACTION_STRING:format(count.numComplete, count.numTotal)
				local lineColor = isComplete and DISABLED_FONT_COLOR or NORMAL_FONT_COLOR
				local resultsText = AppendColoredText(counterText, lineColor)
				self:AddObjectiveLine(tooltip, zoneName..resultsText, isComplete)
			end
		end
		-- Add glyph collection summary
		local treeCurrencyInfo = util.garrison.GetDragonRidingTreeCurrencyInfo()
		local youCollectedAmountString = TRADESKILL_NAME_RANK:format(YOU_COLLECTED_LABEL, numGlyphsCollected, numGlyphsTotal)
		local collectedAll = numGlyphsCollected == numGlyphsTotal
		local lineColor = collectedAll and DISABLED_FONT_COLOR or NORMAL_FONT_COLOR
		local lineSuffix = collectedAll and TEXT_DELIMITER..TOOLTIP_CHECK_MARK_ICON_STRING or ''
		self:AddIconLine(tooltip, youCollectedAmountString..lineSuffix, treeCurrencyInfo.texture, lineColor)
		if (treeCurrencyInfo.quantity > 0) then
			-- Inform user that there are glyphs to spend
			local currencySymbolString = util.CreateInlineIcon(treeCurrencyInfo.texture, 16, 16, 0, -1)
			local availableAmountText = PROFESSIONS_CURRENCY_AVAILABLE:format(treeCurrencyInfo.quantity, currencySymbolString)
			self:AddObjectiveLine(tooltip, availableAmountText)
		end
		if (numGlyphsCollected == 0) then
			-- Inform player on how to get some glyphs
			self:AddIconLine(tooltip, DRAGON_RIDING_CURRENCY_TUTORIAL, treeCurrencyInfo.texture, DISABLED_FONT_COLOR)
		end
	else
		-- Not unlocked, yet :(
		local dragonIconDisabled = util.CreateInlineIcon("dragonriding-barbershop-icon-category-head", 20, 20, -2)
		local disabledInfoText = LANDING_DRAGONRIDING_TREE_BUTTON_DISABLED
		self:AddTextLine(tooltip, dragonIconDisabled..disabledInfoText, DISABLED_FONT_COLOR)
	end
end

----- Missions -----

function LocalTooltipUtil:AddGarrisonMissionLines(tooltip, garrisonInfo, shouldShowMissionCompletedMessage)
    local numInProgress, numCompleted = util.garrison.GetInProgressMissionCount(garrisonInfo.garrisonTypeID)
	local hasCompletedAllMissions = numCompleted > 0 and numCompleted == numInProgress
	-- self:AddHeaderLine(tooltip, garrisonInfo.msg.missionsTitle)
	-- Mission counter
	if (numInProgress > 0) then
		local progressText = format(garrisonInfo.msg.missionsReadyCount, numCompleted, numInProgress)
		self:AddObjectiveLine(tooltip, progressText, hasCompletedAllMissions)
	else
		-- No missions active
		self:AddTextLine(tooltip, garrisonInfo.msg.missionsEmptyProgress)
	end
	-- Return to base info
	if shouldShowMissionCompletedMessage then
		self:AddTextLine(tooltip, garrisonInfo.msg.missionsComplete)
    end
end

----- Bounty board -----

function LocalTooltipUtil:AddBountyBoardLines(tooltip, garrisonInfo)
	local isForShadowlands = garrisonInfo.garrisonTypeID == util.expansion.data.Shadowlands.garrisonTypeID

    -- Only available since Legion (WoW 7.x); no longer useful in Dragonflight (WoW 10.x)
	local bountyBoard = garrisonInfo.bountyBoard
	if not bountyBoard.AreBountiesUnlocked() then
		return
	end

	-- List available bounties
	local bounties = bountyBoard.GetBounties()
	if (isForShadowlands and #bounties == 0) then
		-- System retrieves callings through event listening and on opening the mission frame; try to update (again).
		CovenantCalling_CheckCallings()
		bounties = bountyBoard.GetBounties()
	end
	self:AddHeaderLine(tooltip, bountyBoard.title)
	if (#bounties > 0) then
		for _, bountyData in ipairs(bounties) do
			local questName = QuestUtils_GetQuestName(bountyData.questID)
			if isForShadowlands then
				-- Shadowland bounties have a golden border around their icon; need special treatment.
				-- REF.: CreateTextureMarkup(file, fileWidth, fileHeight, width, height, left, right, top, bottom, xOffset, yOffset)
				local iconString = CreateTextureMarkup(bountyData.icon, 256, 256, 16, 16, 0.28, 0.74, 0.26, 0.72, 1, -1)
				questName = iconString..TEXT_DELIMITER..questName
			end
			local bountyIcon = not isForShadowlands and bountyData.icon or nil
			if bountyData.turninRequirementText then
				self:AddIconLine(tooltip, questName, bountyIcon, DISABLED_FONT_COLOR)
				-- if ns.settings.showBountyRequirements then					--> TODO - Re-add option to settings
				self:AddObjectiveLine(tooltip, bountyData.turninRequirementText, nil, WARNING_FONT_COLOR)
				-- end
			else
				local complete = C_QuestLog.IsComplete(bountyData.questID)
				questName = complete and questName..TEXT_DELIMITER..TOOLTIP_CHECK_MARK_ICON_STRING or questName
				self:AddIconLine(tooltip, questName, bountyIcon, complete and DISABLED_FONT_COLOR)
				if complete then
					self:AddObjectiveLine(tooltip, bountyBoard.isCompleteMessage)
				end
			end
		end
	-- elseif not isForShadowlands then									    	--> TODO - Check if still needed
		-- self:AddObjectiveLine(tooltip, bountyBoard.noBountiesMessage)
	else
		self:AddObjectiveLine(tooltip, RETRIEVING_DATA, false, RED_FONT_COLOR)
	end
end

--------------------------------------------------------------------------------
