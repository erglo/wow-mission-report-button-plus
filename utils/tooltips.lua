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

local util = ns.utilities  --> <utils\mrbputils.lua>
local ExpansionInfo = ns.ExpansionInfo  --> <data\expansion.lua>
local LocalFactionInfo = ns.FactionInfo  --> <data\factions.lua>
local LocalMajorFactionInfo = ns.MajorFactionInfo  --> <data\majorfactions.lua>
local LocalDragonridingUtil = ns.DragonridingUtil  --> <utils\dragonriding.lua>

local LocalTooltipUtil = {}  --> Handler from this file
ns.utilities.tooltip = LocalTooltipUtil

local LibQTip = LibStub('LibQTip-1.0')
local LocalLibQTipUtil = ns.utils.libqtip  --> <utils\libqtip.lua>
-- local MenuTooltip, ExpansionTooltip 

----- Upvalues -----

local format = string.format
local tostring = tostring
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

local GENERIC_FRACTION_STRING = GENERIC_FRACTION_STRING
local MAJOR_FACTION_BUTTON_RENOWN_LEVEL = MAJOR_FACTION_BUTTON_RENOWN_LEVEL
local MAJOR_FACTION_BUTTON_FACTION_LOCKED = MAJOR_FACTION_BUTTON_FACTION_LOCKED
local TRADESKILL_NAME_RANK = TRADESKILL_NAME_RANK
local YOU_COLLECTED_LABEL = YOU_COLLECTED_LABEL
local PROFESSIONS_CURRENCY_AVAILABLE = PROFESSIONS_CURRENCY_AVAILABLE
local DRAGON_RIDING_CURRENCY_TUTORIAL = DRAGON_RIDING_CURRENCY_TUTORIAL

-- Return given text in an optional font color (defaults to white) delimited by 1 space character.
---@param text string
---@param color table|nil  A color class (see <FrameXML/GlobalColors.lua>), defaults to TOOLTIP_TEXT_FONT_COLOR
---@return string tooltipText
--
local function AppendColoredText(text, color)
    local FontColor = color or TOOLTIP_TEXT_FONT_COLOR
    return L.TEXT_DELIMITER..FontColor:WrapTextInColorCode(text)
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
		240,	--> maxWidth 
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
	return self:AddTextLine(tooltip, iconString..L.TEXT_DELIMITER..text, TextColor, ...)
end

function LocalTooltipUtil:AddObjectiveLine(tooltip, text, completed, TextColor, ...)
	if L:StringIsEmpty(text) then
        return
    end
	local iconString = completed and TOOLTIP_CHECK_MARK_ICON_STRING or TOOLTIP_DASH_ICON_STRING
	return self:AddTextLine(tooltip, iconString..L.TEXT_DELIMITER..text, completed and DISABLED_FONT_COLOR or TextColor, ...)
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
	local iconString = TOOLTIP_DASH_ICON_STRING..L.TEXT_DELIMITER..TOOLTIP_CLOCK_ICON_STRING
	return self:AddTextLine(tooltip, iconString..L.TEXT_DELIMITER..text, ...)
end

----- LibQTip - Cell Provider -----
--
-- REF.: <https://www.wowace.com/projects/libqtip-1-0/pages/api-reference>
-- REF.: <https://www.wowace.com/projects/libqtip-1-0/pages/standard-cell-provider-api>
-- REF.: <https://warcraft.wiki.gg/wiki/API_Frame_CreateTexture>
-- REF.: <https://warcraft.wiki.gg/wiki/Layer>
-- REF.: <https://warcraft.wiki.gg/wiki/API_TextureBase_SetAtlas>

local TextureCellProvider, TextureCellPrototype = LibQTip:CreateCellProvider(LibQTip.LabelProvider)
ns.TextureCellProvider = TextureCellProvider

function TextureCellPrototype:InitializeCell()
	LibQTip.LabelPrototype.InitializeCell(self)
	if not self.texture then
		self.texture = self:CreateTexture(nil, 'ARTWORK')
		self.texture:SetSize(16, 16)
		self.texture:SetPoint("CENTER", self)
	end
end

function TextureCellPrototype:SetupCell(tooltip, atlasName, ...)
	if L:StringIsEmpty(atlasName) then
		return 0, 0
	end

	self.texture.name = atlasName
	self.texture:SetAtlas(atlasName)
	self.texture:Show()

	return self.texture:GetSize()
end

function TextureCellPrototype:ReleaseCell()
	self.texture:Hide()
end

local HintIconCellProvider, HintIconCellPrototype = LibQTip:CreateCellProvider(LibQTip.LabelProvider)
ns.HintIconCellProvider = HintIconCellProvider

function HintIconCellPrototype:InitializeCell()
	LibQTip.LabelPrototype.InitializeCell(self)
	if not self.missionsHintTexture then
		-- When missions are completed, show this hint icon.
		self.missionsHintTexture = self:CreateTexture("MissionsHintTexture", "OVERLAY", nil, 5)
		self.missionsHintTexture:SetAtlas("QuestNormal")
		self.missionsHintTexture:SetSize(16, 16)
	end
	if not self.reputationHintTexture then
		-- When reputation reward is pending, show this hint icon.
		self.reputationHintTexture = self:CreateTexture("ReputationHintTexture", "OVERLAY", nil, 3)
		self.reputationHintTexture:SetAtlas("ParagonReputation_Bag")
		self.reputationHintTexture:SetSize(13, 16)
	end
	if not self.timewalkingVendorHintTexture then
		-- When the Timewalking Vendor is available, show this hint icon.
		self.timewalkingVendorHintTexture = self:CreateTexture("TimewalkingVendorHintTexture", "OVERLAY", nil, 1)
		self.timewalkingVendorHintTexture:SetAtlas("TimewalkingVendor-32x32")
		self.timewalkingVendorHintTexture:SetSize(16, 16)
	end
end

function HintIconCellPrototype:SetupCell(parent, hints, ...)
	if (type(hints) ~= "table") then
		return 0, 0
	end

	local missionsAvailable, reputationRewardPending, timeWalkingVendorAvailable = SafeUnpack(hints)
	if missionsAvailable then
		local offsetX = (reputationRewardPending or timeWalkingVendorAvailable) and 8 or 0
		self.missionsHintTexture:SetPoint("CENTER", self, offsetX, 0)
		self.missionsHintTexture:Show()
	end
	if reputationRewardPending then
		local offsetX = (missionsAvailable and timeWalkingVendorAvailable) and 2 or 0
		if missionsAvailable then
			offsetX = -2
		end
		if timeWalkingVendorAvailable then
			offsetX = 6
		end
		self.reputationHintTexture:SetPoint("CENTER", self, offsetX, 0)
		self.reputationHintTexture:Show()
	end
	if timeWalkingVendorAvailable then
		local offsetX = reputationRewardPending and -2 or 0
		if (missionsAvailable and reputationRewardPending) then
			offsetX = -4
		end
		self.timewalkingVendorHintTexture:SetPoint("CENTER", self, offsetX, 0)
		self.timewalkingVendorHintTexture:Show()
	end

	return self.missionsHintTexture:GetSize()
end

function HintIconCellPrototype:ReleaseCell()
	self.missionsHintTexture:ClearAllPoints()
	self.missionsHintTexture:Hide()
	self.reputationHintTexture:ClearAllPoints()
	self.reputationHintTexture:Hide()
	self.timewalkingVendorHintTexture:ClearAllPoints()
	self.timewalkingVendorHintTexture:Hide()
end

----- MRBP content -------------------------------------------------------------

local function GetMajorFactionIcon(majorFactionData)
	if (majorFactionData.expansionID >= ExpansionInfo.data.DRAGONFLIGHT.ID) then
		return "MajorFactions_Icons_"..majorFactionData.textureKit.."512"
	end
end

local function ShouldApplyFactionColors(expansionID)
	local varName = "applyMajorFactionColors" .. tostring(expansionID)
	return ns.settings[varName]
end

local function ShouldHideMajorFactionUnlockDescription(expansionID)
	local varName = "hideMajorFactionUnlockDescription" .. tostring(expansionID)
	return ns.settings[varName]
end

local function ShouldAutoHideCompletedDragonGlyphZones(expansionID)
	local varName = "autoHideCompletedDragonGlyphZones" .. tostring(expansionID)
	return ns.settings[varName]
end

local function IsReputationTooltip(tooltip)
	return tooltip.key == ShortAddonID.."LibQTipReputationTooltip"
end

local function IsMainFactionShownInReputationTooltip(expansionID)
	return ns.IsExpansionOptionSet("showFactionReputation", expansionID) and ns.IsExpansionOptionSet("separateFactionTooltip", expansionID)
end

local function HighlightWatchedFactionLines(tooltip, lineIndex, factionData)
	if not ns.settings.highlightWatchedFaction then return end

	local watchedFactionData = LocalFactionInfo:GetWatchedFactionData()
	if not watchedFactionData or watchedFactionData.factionID == 0 then return end

	if (watchedFactionData.factionID == factionData.factionID) then
		-- Highlight both lines, faction name + faction progress
		local r, g, b, a = FRIENDS_GRAY_COLOR:GetRGBA()
		tooltip:SetLineColor(lineIndex-1, r, g, b, 0.6)
		tooltip:SetLineColor(lineIndex, r, g, b, 0.6)
	end
end

-- Requires expansionInfo, eg. ExpansionInfo.data.DRAGONFLIGHT
function LocalTooltipUtil:AddMajorFactionsRenownLines(tooltip, expansionInfo)
	local majorFactionData = LocalMajorFactionInfo:GetAllMajorFactionDataForExpansion(expansionInfo.ID)
	if (#majorFactionData == 0) then return end

	-- Header
	if IsReputationTooltip(tooltip) then
		self:AddHeaderLine(tooltip, expansionInfo.name, nil, true)
	end
	self:AddHeaderLine(tooltip, L["showMajorFactionRenownLevel"])

	-- Body
	for _, factionData in ipairs(majorFactionData) do
		local factionIcon = GetMajorFactionIcon(factionData)
		local FactionColor = ShouldApplyFactionColors(expansionInfo.ID) and LocalMajorFactionInfo:GetMajorFactionColor(factionData) or TOOLTIP_TEXT_FONT_COLOR
		self:AddIconLine(tooltip, factionData.name, factionIcon, FactionColor)

		if factionData.isUnlocked then
			-- Show current renown progress
			local levelText = MAJOR_FACTION_BUTTON_RENOWN_LEVEL:format(factionData.renownLevel)
			local progressText = L.REPUTATION_PROGRESS_FORMAT:format(factionData.renownReputationEarned, factionData.renownLevelThreshold)
			local progressTextParens = AppendColoredText(L.PARENS_TEMPLATE:format(progressText), TOOLTIP_TEXT_FONT_COLOR)
			local lineIndex, columnIndex

			if not LocalFactionInfo:IsFactionParagon(factionData.factionID) then
				lineIndex, columnIndex = self:AddObjectiveLine(tooltip, levelText..L.TEXT_DELIMITER..progressTextParens) -- , nil, hasMaxRenown and DISABLED_FONT_COLOR)
			else
				local paragonInfo = LocalFactionInfo:GetFactionParagonInfo(factionData.factionID)
				local bagIconString = paragonInfo.hasRewardPending and TOOLTIP_BAG_FULL_ICON_STRING or TOOLTIP_BAG_ICON_STRING
				progressText = LocalMajorFactionInfo:GetFactionParagonProgressText(paragonInfo)
				progressTextParens = AppendColoredText(L.PARENS_TEMPLATE:format(progressText), TOOLTIP_TEXT_FONT_COLOR)
				lineIndex, columnIndex = self:AddObjectiveLine(tooltip, levelText..L.TEXT_DELIMITER..progressTextParens..L.TEXT_DELIMITER..bagIconString, nil, DISABLED_FONT_COLOR)

				if paragonInfo.hasRewardPending then
					local completionText = LocalMajorFactionInfo:GetParagonCompletionText(paragonInfo)
					lineIndex, columnIndex = self:AddObjectiveLine(tooltip, completionText)
				end
			end

			HighlightWatchedFactionLines(tooltip, lineIndex, factionData)
		else
			-- Major Faction is not unlocked, yet :(
			self:AddObjectiveLine(tooltip, MAJOR_FACTION_BUTTON_FACTION_LOCKED, nil, DISABLED_FONT_COLOR)

			if not ShouldHideMajorFactionUnlockDescription(expansionInfo.ID) then
				self:AddObjectiveLine(tooltip, factionData.unlockDescription, nil, DISABLED_FONT_COLOR)
			end
		end
	end
end

function LocalTooltipUtil:AddDragonGlyphLines(tooltip, expansionID)
	if LocalDragonridingUtil:IsSkyridingUnlocked() then
		local glyphsPerZone, numGlyphsCollected, numGlyphsTotal = LocalDragonridingUtil:GetDragonGlyphsCount(expansionID)

		-- Show collected glyphs per zone
		for mapName, count in pairs(glyphsPerZone) do
			local isComplete = count.numComplete == count.numTotal
			if not (isComplete and ShouldAutoHideCompletedDragonGlyphZones(expansionID)) then
				local zoneName = mapName..L.HEADER_COLON
				local counterText = GENERIC_FRACTION_STRING:format(count.numComplete, count.numTotal)
				local lineColor = isComplete and DISABLED_FONT_COLOR or NORMAL_FONT_COLOR
				local resultsText = AppendColoredText(counterText, lineColor)
				self:AddObjectiveLine(tooltip, zoneName..resultsText, isComplete)
			end
		end

		-- Add glyph collection summary
		local treeCurrencyInfo = LocalDragonridingUtil:GetDragonRidingTreeCurrencyInfo()
		local youCollectedAmountString = TRADESKILL_NAME_RANK:format(YOU_COLLECTED_LABEL, numGlyphsCollected, numGlyphsTotal)
		local collectedAll = numGlyphsCollected == numGlyphsTotal
		local lineColor = collectedAll and DISABLED_FONT_COLOR or NORMAL_FONT_COLOR
		local lineSuffix = collectedAll and L.TEXT_DELIMITER..TOOLTIP_CHECK_MARK_ICON_STRING or ''
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
	local isForShadowlands = garrisonInfo.garrisonTypeID == ExpansionInfo.data.SHADOWLANDS.garrisonTypeID

    -- Only available since Legion (WoW 7.x), no longer useful in Dragonflight (WoW 10.x)
	local bountyBoard = garrisonInfo.bountyBoard
	if not bountyBoard.AreBountiesUnlocked() then
		return
	end

	-- List available bounties
	local bounties = bountyBoard.GetBounties()
	if (isForShadowlands and #bounties == 0) then
		-- System retrieves callings through event listening and on opening the mission frame, try to update (again).
		CovenantCalling_CheckCallings()
		bounties = bountyBoard.GetBounties()
	end
	self:AddHeaderLine(tooltip, bountyBoard.title)
	if (#bounties > 0) then
		for _, bountyData in ipairs(bounties) do
			local questName = ns.GetQuestName(bountyData.questID)
			if isForShadowlands then
				-- Shadowland bounties have a golden border around their icon, need special treatment.
				-- REF.: CreateTextureMarkup(file, fileWidth, fileHeight, width, height, left, right, top, bottom, xOffset, yOffset)
				local iconString = CreateTextureMarkup(bountyData.icon, 256, 256, 16, 16, 0.28, 0.74, 0.26, 0.72, 1, -1)
				questName = iconString..L.TEXT_DELIMITER..questName
			end
			local bountyIcon = not isForShadowlands and bountyData.icon or nil
			if bountyData.turninRequirementText then
				self:AddIconLine(tooltip, questName, bountyIcon, DISABLED_FONT_COLOR)
				-- if ns.settings.showBountyRequirements then					--> TODO - Re-add option to settings
				self:AddObjectiveLine(tooltip, bountyData.turninRequirementText, nil, WARNING_FONT_COLOR)
				-- end
			else
				local complete = C_QuestLog.IsComplete(bountyData.questID)
				questName = complete and questName..L.TEXT_DELIMITER..TOOLTIP_CHECK_MARK_ICON_STRING or questName
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

----- Draenor Treasures -----

function LocalTooltipUtil:AddDraenorTreasureLines(tooltip)
	util.poi.PrepareDraenorTreasureArePoiIDs()
	local draenorTreasuresAreaPoiInfos = util.poi.FindDraenorTreasures()
	if draenorTreasuresAreaPoiInfos then
		self:AddHeaderLine(tooltip, L["showDraenorTreasures"])
		for mapName, poiCountsPerMap in pairs(draenorTreasuresAreaPoiInfos) do
			self:AddIconLine(tooltip, mapName, "VignetteLoot", ORANGE_FONT_COLOR)
			for poiName, poiCount in pairs(poiCountsPerMap) do
				local lineName = poiName..L.TEXT_DELIMITER..NORMAL_FONT_COLOR:WrapTextInColorCode("x"..tostring(poiCount))
				self:AddObjectiveLine(tooltip, lineName)
			end
		end
	end
end

----- Faction Reputation -----

function LocalTooltipUtil:AddCovenantRenownLevelLines(tooltip)
	local covenantInfo = util.covenant.GetCovenantInfo()
	if not util.TableHasAnyEntries(covenantInfo) then return end

	local renownInfo = util.covenant.GetRenownData(covenantInfo.ID)
	if not renownInfo then return end

	-- Header
	local expansionInfo = ExpansionInfo.data.SHADOWLANDS
	if (IsReputationTooltip(tooltip) and not IsMainFactionShownInReputationTooltip(expansionInfo.ID)) then
		self:AddHeaderLine(tooltip, expansionInfo.name, nil, true)
	end
	self:AddHeaderLine(tooltip, L["showCovenantRenownLevel"])

	-- Body
	local lineText = covenantInfo.name
	local progressText = L.MAJOR_FACTION_RENOWN_CURRENT_PROGRESS:format(renownInfo.currentRenownLevel, renownInfo.maximumRenownLevel)
	if renownInfo.hasMaximumRenown then
		-- Append max. level after covenant name
		local renownLevelText = MAJOR_FACTION_BUTTON_RENOWN_LEVEL:format(renownInfo.currentRenownLevel)
		lineText = lineText..L.TEXT_DELIMITER..DISABLED_FONT_COLOR:WrapTextInColorCode(L.PARENS_TEMPLATE:format(renownLevelText))
		progressText = L.COVENANT_SANCTUM_RENOWN_REWARD_TITLE_COMPLETE
	end
	LocalTooltipUtil:AddAchievementLine(tooltip, lineText, covenantInfo.atlasName, ns.settings.applyCovenantColors and covenantInfo.color, covenantInfo.isCompleted)
	local lineIndex, columnIndex = LocalTooltipUtil:AddObjectiveLine(tooltip, progressText, renownInfo.hasMaximumRenown)

	return lineIndex, columnIndex
end

function LocalTooltipUtil:AddFactionReputationProgressLine(tooltip, factionData)
	local hasMaxReputation = LocalFactionInfo:HasMaximumReputation(factionData)
	local isParagon = LocalFactionInfo:IsFactionParagon(factionData.factionID)

	local standingText = LocalFactionInfo:GetFactionReputationStandingText(factionData)
	local StandingColor = (hasMaxReputation or isParagon) and DISABLED_FONT_COLOR or LocalFactionInfo:GetFactionStandingColor(factionData)

	local progressText = LocalFactionInfo:GetFactionReputationProgressText(factionData)
	local ProgressColor = hasMaxReputation and DISABLED_FONT_COLOR or TOOLTIP_TEXT_FONT_COLOR
	local progressTextParens = AppendColoredText(L.PARENS_TEMPLATE:format(progressText), ProgressColor)

	local lineText = (hasMaxReputation and standingText..L.TEXT_DELIMITER..L.PARENS_TEMPLATE:format(CAPPED) or  -- MAXIMUM
					  standingText..L.TEXT_DELIMITER..progressTextParens)
	local lineIndex, columnIndex

	if not isParagon then
		lineIndex, columnIndex = self:AddObjectiveLine(tooltip, lineText, hasMaxReputation, StandingColor)

	else
		local paragonInfo = LocalFactionInfo:GetFactionParagonInfo(factionData.factionID)
		lineText = lineText..L.TEXT_DELIMITER..TOOLTIP_BAG_ICON_STRING
		lineIndex, columnIndex = self:AddObjectiveLine(tooltip, lineText, paragonInfo.hasRewardPending or hasMaxReputation, StandingColor)

		if paragonInfo.hasRewardPending then
			local completionText = LocalMajorFactionInfo:GetParagonCompletionText(paragonInfo)
			lineIndex, columnIndex = self:AddObjectiveLine(tooltip, completionText, nil, LIGHTERBLUE_FONT_COLOR)  -- TUTORIAL_BLUE_FONT_COLOR, ACCOUNT_WIDE_FONT_COLOR
		end
	end

	HighlightWatchedFactionLines(tooltip, lineIndex, factionData)
	return lineIndex, columnIndex
end

function LocalTooltipUtil:AddFactionReputationLines(tooltip, expansionInfo)
    local factionData = LocalFactionInfo:GetAllFactionDataForExpansion(expansionInfo.ID)
	if (not factionData or #factionData == 0) then return end

	-- Header
	if IsReputationTooltip(tooltip) then
		self:AddHeaderLine(tooltip, expansionInfo.name, nil, true)
	end
	self:AddHeaderLine(tooltip, L["MainFactionReputationLabel"])

	-- Body
    for i, faction in ipairs(factionData) do
		-- local ExpansionColor = _G["EXPANSION_COLOR_"..expansionInfo.ID]		--> TODO - Currently not valid color, re-check from time to time
		-- self:AddTextLine(tooltip, faction.name, ExpansionColor)
		self:AddIconLine(tooltip, faction.name, faction.icon)  --, LIGHTYELLOW_FONT_COLOR)
		self:AddFactionReputationProgressLine(tooltip, faction)
    end
end

function LocalTooltipUtil:AddBonusFactionReputationLines(tooltip, expansionInfo)
	local isBonusFaction = true
	local bonusFactionData = LocalFactionInfo:GetAllFactionDataForExpansion(expansionInfo.ID, isBonusFaction)
	if (not bonusFactionData or #bonusFactionData == 0) then return end

 	-- Header
	if (IsReputationTooltip(tooltip) and not IsMainFactionShownInReputationTooltip(expansionInfo.ID)) then
		self:AddHeaderLine(tooltip, expansionInfo.name, nil, true)
	end
	local labelName = L["BonusFactionReputationLabel"..tostring(expansionInfo.ID)] or L["BonusFactionReputationLabel"]
	self:AddHeaderLine(tooltip, labelName)

	-- Body
	for i, bonusFaction in ipairs(bonusFactionData) do
		self:AddIconLine(tooltip, bonusFaction.name, bonusFaction.icon)
		self:AddFactionReputationProgressLine(tooltip, bonusFaction)
	end
end

--------------------------------------------------------------------------------
