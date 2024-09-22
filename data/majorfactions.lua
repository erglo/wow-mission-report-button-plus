--------------------------------------------------------------------------------
--[[ majorfactions.lua - Utilities for handling Major Factions related data. ]]--
--
-- by erglo <erglo.coder+MRBP@gmail.com>
--
-- Copyright (C) 2024  Erwin D. Glockner (aka erglo, ergloCoder)
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see http://www.gnu.org/licenses.
-- 
-- Further reading:
-- + REF.: <FrameXML/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua>
-- + REF.: <FrameXML/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua>  
-- + REF.: <FrameXML/Blizzard_MajorFactions/Blizzard_MajorFactionRenown.lua>
-- + REF.: <https://www.townlong-yak.com/framexml/live/Blizzard_MajorFactions/Blizzard_MajorFactionsLandingTemplates.lua>
-- + REF.: <https://warcraft.wiki.gg/wiki/API_C_Reputation.IsFactionParagon>
-- + REF.: <https://warcraft.wiki.gg/wiki/API_C_Reputation.GetFactionParagonInfo>
-- (see also the function comments section for more reference)
-- 
--------------------------------------------------------------------------------

local AddonID, ns = ...;
local L = ns.L;

-- Upvalues
local C_MajorFactions = C_MajorFactions;
local C_Reputation = C_Reputation;
local GetQuestLogCompletionText = GetQuestLogCompletionText;
local GetLogIndexForQuestID = C_QuestLog.GetLogIndexForQuestID;

local ExpansionInfo = ns.ExpansionInfo;  --> <data\expansion.lua>

--------------------------------------------------------------------------------

local LocalMajorFactionInfo = {};
ns.MajorFactionInfo = LocalMajorFactionInfo;

----- Wrapper -----

-- Retrieve the data for given major faction ID.
-- 
-- `MajorFactionData` fields:
-- * `name` --> cstring
-- * `factionID` --> number
-- * `expansionID` --> number
-- * `bountySetID` --> number
-- * `isUnlocked` --> bool
-- * `unlockDescription` --> cstring?
-- * `uiPriority` --> number
-- * `renownLevel` --> number
-- * `renownReputationEarned` --> number
-- * `renownLevelThreshold` --> number
-- * `textureKit` --> textureKit
-- * `celebrationSoundKit` --> number
-- * `renownFanfareSoundKitID` --> number
--
-- REF.: [MajorFactionsDocumentation.lua](https://www.townlong-yak.com/framexml/56421/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua)
-- 
function LocalMajorFactionInfo:GetMajorFactionData(factionID)
	return C_MajorFactions.GetMajorFactionData(factionID);
end

-- Check if player has reached the maximum renown level for given major faction.
function LocalMajorFactionInfo:HasMaximumMajorFactionRenown(currentFactionID)
	return C_MajorFactions.HasMaximumRenown(currentFactionID);
end

-- Check if given faction is/supports paragon reputation.
function LocalMajorFactionInfo:IsFactionParagon(factionID)
	return C_Reputation.IsFactionParagon(factionID);
end

-- Return the wrapped paragon info for given faction.
function LocalMajorFactionInfo:GetFactionParagonInfo(factionID)
	local currentValue, threshold, rewardQuestID, hasRewardPending, tooLowLevelForParagon = C_Reputation.GetFactionParagonInfo(factionID);
	---@class FactionParagonInfo
	---@field currentValue number
	---@field threshold number
	---@field rewardQuestID number
	---@field hasRewardPending boolean
	---@field tooLowLevelForParagon boolean
	return {
		currentValue = currentValue,
		threshold = threshold,
		rewardQuestID = rewardQuestID,
		hasRewardPending = hasRewardPending,
		tooLowLevelForParagon = tooLowLevelForParagon,
	};
end

----- Helper Functions -----

-- Sorting function for major factions. <br>
-- (Gleaned from the file below. Credits go to its author(s).) <br>
-- REF.: [Blizzard_MajorFactionsLandingTemplates.lua](https://www.townlong-yak.com/framexml/live/Blizzard_MajorFactions/Blizzard_MajorFactionsLandingTemplates.lua)
--
local function MajorFactionSort(faction1, faction2)
	if faction1.uiPriority ~= faction2.uiPriority then
		return faction1.uiPriority > faction2.uiPriority;
	end
	return strcmputf8i(faction1.name, faction2.name) < 0;
end

--------------------------------------------------------------------------------

-- Retrieve and sort the data for all major factions of given expansion.
-->REF.: <FrameXML/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua>  
-- REF.: <FrameXML/Blizzard_MajorFactions/Blizzard_MajorFactionRenown.lua>
--
function LocalMajorFactionInfo:GetAllMajorFactionDataForExpansion(expansionID)
	local majorFactionData = {};
	local majorFactionIDs = C_MajorFactions.GetMajorFactionIDs(expansionID);

	for _, factionID in ipairs(majorFactionIDs) do
		tinsert(majorFactionData, self:GetMajorFactionData(factionID));
	end

	table.sort(majorFactionData, MajorFactionSort);
	return majorFactionData;
end

-- Build and return the color of the given major faction.
function LocalMajorFactionInfo:GetMajorFactionColor(majorFactionData, fallbackColor)
	local normalColor = fallbackColor or NORMAL_FONT_COLOR;

	if (majorFactionData.expansionID >= ExpansionInfo.data.DRAGONFLIGHT.ID) then
		local colorName = strupper(majorFactionData.textureKit).."_MAJOR_FACTION_COLOR";
		return _G[colorName] or normalColor;
	end

	return normalColor;
end

----- Paragon Info -----

-- Build a generic reputation progress string for given paragon and return it.
---@param paragonInfo FactionParagonInfo
---@return string progressText
--
function LocalMajorFactionInfo:GetFactionParagonProgressText(paragonInfo)
	local value = mod(paragonInfo.currentValue, paragonInfo.threshold);

	-- Show overflow if a reward is pending
	if paragonInfo.hasRewardPending then
		value = value + paragonInfo.threshold;
	end

	local progressText = L.REPUTATION_PROGRESS_FORMAT:format(value, paragonInfo.threshold);

	return progressText;
end

-- Get the completion text for given paragon and return it.
function LocalMajorFactionInfo:GetParagonCompletionText(paragonInfo)
	if paragonInfo.hasRewardPending then
		local questIndex = GetLogIndexForQuestID(paragonInfo.rewardQuestID);
		local text = GetQuestLogCompletionText(questIndex);
		if not L:StringIsEmpty(text) then
			return text;
		end
	end

	return '';
end

-- Check if given expansion has reputation rewards pending.
function LocalMajorFactionInfo:HasMajorFactionReputationReward(expansionID)
	local majorFactionData = self:GetAllMajorFactionDataForExpansion(expansionID);
	if (#majorFactionData == 0) then
		return false;
	end

	for i, factionData in ipairs(majorFactionData) do
		if factionData.isUnlocked then
			if self:IsFactionParagon(factionData.factionID) then
				local paragonInfo = self:GetFactionParagonInfo(factionData.factionID);
				if paragonInfo.hasRewardPending then
					return true;
				end
			else
				local hasRewardPending = factionData.renownReputationEarned >= factionData.renownLevelThreshold;
				if hasRewardPending then
					return true;
				end
			end
		end
	end

	return false;
end

-- Check if any Major Faction is unlocked for given expansion.
function LocalMajorFactionInfo:HasAnyUnlockedMajorFaction(expansionID)
	local majorFactionData = self:GetAllMajorFactionDataForExpansion(expansionID);
	if (#majorFactionData > 0) then
		for _, factionData in ipairs(majorFactionData) do
			if factionData.isUnlocked then
				return true;
			end
		end
	end

	return false;
end
