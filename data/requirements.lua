--------------------------------------------------------------------------------
--[[ requirements.lua - Utilities for handling Expansion Landing Page requirements. ]]--
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
--------------------------------------------------------------------------------

local AddonID, ns = ...;
local L = ns.L;

-- Upvalues
local C_QuestLog = C_QuestLog;
local HaveQuestData = HaveQuestData;
local QuestUtils_GetQuestName = QuestUtils_GetQuestName;
local GetCVarBitfield = GetCVarBitfield;
local C_Garrison = C_Garrison;

local PlayerInfo = ns.PlayerInfo;  --> <data\player.lua>
local ExpansionInfo = ns.ExpansionInfo;  --> <data\expansion.lua>
local LandingPageInfo = ns.LandingPageInfo;  --> <data\landingpage.lua>
local LocalMajorFactionInfo = ns.MajorFactionInfo;  --> <data\majorfactions.lua>

----- Helper Functions -----

-- REF.: <FrameXML/QuestUtils.lua>
--
local function GetQuestName(questID)
	if not HaveQuestData(questID) then
		C_QuestLog.RequestLoadQuestByID(questID);
	end
	return QuestUtils_GetQuestName(questID);
end

--------------------------------------------------------------------------------

local LocalRequirementInfo = {};
ns.RequirementInfo = LocalRequirementInfo;

----- Wrapper -----

function LocalRequirementInfo:IsExpansionLandingPageUnlocked(landingPageTypeID)
    return GetCVarBitfield("unlockedExpansionLandingPages", landingPageTypeID);  --> Available since `10.0.2`
end

----- Data -----

-- A collection of quest for (before) unlocking the command table.
--> <questID, questName_English (fallback name)>
local MRBP_COMMAND_TABLE_UNLOCK_QUESTS = {
	[ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID] = {
		-- REF.: <https://www.wowhead.com/guides/garrisons/quests-to-unlock-a-level-1-and-level-2-garrison>
		["Horde"] = {34775, "Mission Probable"},  --> wowhead
		["Alliance"] = {34692, "Delegating on Draenor"},  --> Companion App
	},
	[ExpansionInfo.data.LEGION.ID] = {
		["WARRIOR"] = {40585, "Thus Begins the War"},
		["PALADIN"] = {39696, "Rise, Champions"},
		["HUNTER"] = {42519, "Rise, Champions"},
		["ROGUE"] = {42139, "Rise, Champions"},
		["PRIEST"] = {43270, "Rise, Champions"},
		["DEATHKNIGHT"] = {43264, "Rise, Champions"},
		["SHAMAN"] = {42383, "Rise, Champions"},
		["MAGE"] = {42663, "Rise, Champions"},
		["WARLOCK"] = {42608, "Rise, Champions"},
		["MONK"] = {42187, "Rise, Champions"},
		["DRUID"] = {42583, "Rise, Champions"},
		["DEMONHUNTER"] = {42670, "Rise, Champions"},
		["EVOKER"] = {72129, "Aiding Khadgar"},  --> no Class Hall for Evoker (!); talk to Khadgar instead.
	},
	[ExpansionInfo.data.BATTLE_FOR_AZEROTH.ID] = {
		["Horde"] = {51771, "War of Shadows"},
		["Alliance"] = {51715, "War of Shadows"},
	},
	[ExpansionInfo.data.SHADOWLANDS.ID] = {
		[Enum.CovenantType.Kyrian] = {57878, "Choosing Your Purpose"},
		[Enum.CovenantType.Venthyr] = {57878, "Choosing Your Purpose"}, 	--> optional: 59319, "Advancing Our Efforts"
		[Enum.CovenantType.NightFae] = {57878, "Choosing Your Purpose"},	--> optional: 61552, "The Hunt Watches"
		[Enum.CovenantType.Necrolord] = {57878, "Choosing Your Purpose"},
		["alt"] = {62000, "Choosing Your Purpose"},  --> when skipping story mode
	},
	[ExpansionInfo.data.DRAGONFLIGHT.ID] = {
		["Horde"] = {65444, "To the Dragon Isles!"},
		["Alliance"] = {67700, "To the Dragon Isles!"},
	},
	[ExpansionInfo.data.WAR_WITHIN.ID] = {
		["Horde"] = {78722, "To Khaz Algar!"},
		["Alliance"] = {78722, "To Khaz Algar!"},
	},
}

--------------------------------------------------------------------------------

function LocalRequirementInfo:Initialize()
    -- Request data for the unlocking requirement quests; on initial log-in the
    -- localized quest titles are not always available. This should help getting
    -- the quest details in the language the player has chosen.
    for _, questData in pairs(MRBP_COMMAND_TABLE_UNLOCK_QUESTS) do
		for _, questTable in pairs(questData) do
			local questID = questTable[1];
            if questID and not HaveQuestData(questID) then
                C_QuestLog.RequestLoadQuestByID(questID);
            end
		end
	end

    -- Note: Shadowlands callings receive info through event listening or on
	-- opening the mission frame; try to update.
	CovenantCalling_CheckCallings();
	--> REF.: <FrameXML/ObjectAPI/CovenantCalling.lua>
end

-- Check if given expansion is unlocked for given tag.
function LocalRequirementInfo:IsIntroQuestCompleted(expansionID, tagName)
	local questData = MRBP_COMMAND_TABLE_UNLOCK_QUESTS[expansionID] and MRBP_COMMAND_TABLE_UNLOCK_QUESTS[expansionID][tagName];
	if not questData then return; end

	local questID = questData[1];
	local IsCompleted = expansionID >= ExpansionInfo.data.DRAGONFLIGHT.ID and C_QuestLog.IsQuestFlaggedCompletedOnAccount or C_QuestLog.IsQuestFlaggedCompleted;

	--> FIXME - Temp. work-around (better with achievement of same name ???)
	-- In Shadowlands if you skip the story mode you get a different quest (ID) with the same name, so
	-- we need to check both quests.
	if (expansionID == ExpansionInfo.data.SHADOWLANDS.ID) then
		local questID2 = MRBP_COMMAND_TABLE_UNLOCK_QUESTS[expansionID]["alt"][1];
		return PlayerInfo:HasActiveCovenant() and (IsCompleted(questID) or IsCompleted(questID2));
	end

	return IsCompleted(questID);
end

-- Verify if given Garrison Landing Page (Draenor -> Shadowlands) is available.
function LocalRequirementInfo:IsGarrisonLandingPageUnlocked(garrisonTypeID, garrisonTypeInfo)
	local garrisonInfo = garrisonTypeInfo or LandingPageInfo:GetGarrisonInfo(garrisonTypeID);

	-- local hasGarrison = C_Garrison.HasGarrison(garrisonInfo.garrisonTypeID);
	-- return hasGarrison or self:IsIntroQuestCompleted(garrisonInfo.expansionID, garrisonInfo.tagName);
	return self:IsIntroQuestCompleted(garrisonInfo.expansionID, garrisonInfo.tagName);
end

-- Check if given Landing Page type is unlocked for given tag.
function LocalRequirementInfo:IsLandingPageUnlocked(landingPageInfo)
	if (landingPageInfo.expansionID >= ExpansionInfo.data.DRAGONFLIGHT.ID) then
		return self:IsExpansionLandingPageUnlocked(landingPageInfo.landingPageTypeID);
	end

	-- Landing pages with a garrison (Draenor -> Shadowlands)
	return self:IsGarrisonLandingPageUnlocked(nil, landingPageInfo);
end

-- Check if at least one Expansion Landing Page is unlocked.
function LocalRequirementInfo:IsAnyLandingPageAvailable()
	local expansionList = ExpansionInfo:GetExpansionsWithLandingPage();
	for _, expansion in ipairs(expansionList) do
		local landingPageInfo = LandingPageInfo:GetLandingPageInfo(expansion.ID);
		local isUnlocked = self:IsLandingPageUnlocked(landingPageInfo);
		if isUnlocked then
			return true;
		end
	end

	return false;
end

function LocalRequirementInfo:CanShowExpansionLandingPage(landingPageInfo)
	local isUnlocked = self:IsLandingPageUnlocked(landingPageInfo);

	if (landingPageInfo.expansionID >= ExpansionInfo.data.DRAGONFLIGHT.ID) then
		isUnlocked = isUnlocked or LocalMajorFactionInfo:HasAnyUnlockedMajorFaction(landingPageInfo.expansionID);
	end

	return isUnlocked;
end

--------------------------------------------------------------------------------

-- Get quest details of given garrison type for given tag.
local function GetLandingPageTypeUnlockInfo(expansionID, tagName)
	local questData = MRBP_COMMAND_TABLE_UNLOCK_QUESTS[expansionID] and MRBP_COMMAND_TABLE_UNLOCK_QUESTS[expansionID][tagName];
	if not questData and (expansionID == ExpansionInfo.data.SHADOWLANDS.ID) then
		questData = MRBP_COMMAND_TABLE_UNLOCK_QUESTS[expansionID]["alt"];
	end
	if not questData then return { requirementText = UNKNOWN }; end

	local questID = questData[1];
	local questFallbackName = questData[2];  --> quest name in English
	local questName = GetQuestName(questID);
	local reqMessageTemplate = L.TOOLTIP_REQUIREMENTS_TEXT_S;  --> same as Companion App text

	local questInfo = {};
	questInfo["questID"] = questID;
	questInfo["questName"] = not L.StringIsEmpty(questName) and questName or questFallbackName;
	questInfo["requirementText"] = reqMessageTemplate:format(questInfo.questName);

	return questInfo;
end
ns.GetLandingPageTypeUnlockInfo = GetLandingPageTypeUnlockInfo;
