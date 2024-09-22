--------------------------------------------------------------------------------
--[[ factions.lua - Utilities for handling Factions related data prior to Dragonflight. ]]--
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
-- + REF.: <https://warcraft.wiki.gg/wiki/Reputation>
-- + REF.: <https://warcraft.wiki.gg/wiki/FactionID>
-- + REF.: <https://warcraft.wiki.gg/wiki/API_C_GossipInfo.GetFriendshipReputation>
-- + REF.: <https://www.townlong-yak.com/framexml/live/Blizzard_APIDocumentationGenerated/ReputationInfoDocumentation.lua>  
-- + REF.: <https://www.townlong-yak.com/framexml/live/Blizzard_UIPanels_Game/ReputationFrame.lua>
-- + REF.: <https://warcraft.wiki.gg/wiki/API_C_Reputation.GetFactionDataByID>
-- + REF.: <https://warcraft.wiki.gg/wiki/API_C_Reputation.IsFactionParagon>
-- + REF.: <https://warcraft.wiki.gg/wiki/API_C_Reputation.GetFactionParagonInfo>
-- (see also the function comments section for more reference)
-- 
--------------------------------------------------------------------------------

local AddonID, ns = ...;
local L = ns.L;

-- Upvalues
local C_Reputation = C_Reputation;
local BreakUpLargeNumbers = BreakUpLargeNumbers;

local PlayerInfo = ns.PlayerInfo;  --> <data\player.lua>
local ExpansionInfo = ns.ExpansionInfo;  --> <data\expansion.lua>

--------------------------------------------------------------------------------

local LocalFactionInfo = {};
ns.FactionInfo = LocalFactionInfo;

----- Wrapper -----

-- Retrieve the data for given faction ID.
-- 
-- `FactionData` fields:
-- * `factionID` --> number
-- * `name` --> cstring
-- * `description` --> cstring
-- * `reaction` --> luaIndex
-- * `currentReactionThreshold` --> number
-- * `nextReactionThreshold` --> number
-- * `currentStanding` --> number
-- * `atWarWith` --> bool
-- * `canToggleAtWar` --> bool
-- * `isChild` --> bool
-- * `isHeader` --> bool
-- * `isHeaderWithRep` --> bool
-- * `isCollapsed` --> bool
-- * `isWatched` --> bool
-- * `hasBonusRepGain` --> bool
-- * `canSetInactive` --> bool
-- * `isAccountWide` --> bool
-- 
---@param factionID number
---@return FactionData?
--
-- REF.: [ReputationInfoDocumentation.lua](https://www.townlong-yak.com/framexml/live/Blizzard_APIDocumentationGenerated/ReputationInfoDocumentation.lua)
-- 
function LocalFactionInfo:GetFactionDataByID(factionID)
    return C_Reputation.GetFactionDataByID(factionID);
end

-- Check if given faction supports paragon reputation.
function LocalFactionInfo:IsFactionParagon(factionID)
    return C_Reputation.IsFactionParagon(factionID);
end

-- Return the wrapped paragon info for given faction.
function LocalFactionInfo:GetFactionParagonInfo(factionID)
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

function LocalFactionInfo:HasMaximumReputation(factionData)
    return factionData.reaction == MAX_REPUTATION_REACTION;  --> 8
end

-- REF.: [SharedColorConstants.lua](https://www.townlong-yak.com/framexml/live/Blizzard_SharedXML/SharedColorConstants.lua)
-- 
function LocalFactionInfo:GetFactionStandingColor(factionData)
    return FACTION_BAR_COLORS[factionData.reaction];
end

-- Sorting

function LocalFactionInfo.SortAscendingByFactionID(dataA, dataB)
    return dataA.factionID < dataB.factionID;  --> 0-9
end

-- REF.: <https://www.townlong-yak.com/framexml/live/Blizzard_SharedXML/SortUtil.lua>
function LocalFactionInfo.SortAscendingByFactionName(dataA, dataB)
    -- return SortUtil.CompareUtf8i(dataA.name, dataB.name);  --> A-Z
    return dataA.name < dataB.name;  --> A-Z
end

-- Unit Faction Groups

LocalFactionInfo.PlayerFactionGroupID = UnitFactionGroup("player");

-- {Alliance=1, Horde=2, Neutral=3, Player=1|2}
LocalFactionInfo.UnitFactionGroupID = EnumUtil.MakeEnum(
    PLAYER_FACTION_GROUP[1],
    PLAYER_FACTION_GROUP[0],
    "Neutral"
);
LocalFactionInfo.UnitFactionGroupID["Player"] = LocalFactionInfo.UnitFactionGroupID[LocalFactionInfo.PlayerFactionGroupID];

function LocalFactionInfo:IsSuitableFactionGroupForPlayer(unitFactionGroup)
    return (unitFactionGroup == self.UnitFactionGroupID.Player or
            unitFactionGroup == self.UnitFactionGroupID.Neutral);
end

----- Data ---------------------------------------------------------------------

LocalFactionInfo.FactionIDs = {
    [ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID] = {
        [LocalFactionInfo.UnitFactionGroupID.Alliance] = {
            ["1731"] = {englishName="Council of Exarchs",  icon=1048727},
            ["1710"] = {englishName="Sha'tari Defense", icon=1042739},
            ["1682"] = {englishName="Wrynn's Vanguard", icon=1042294},
            ["1847"] = {englishName="Hand of the Prophet", icon=930038},
        },
        [LocalFactionInfo.UnitFactionGroupID.Horde] = {
            ["1445"] = {englishName="Frostwolf Orcs", icon=1044164},
            ["1708"] = {englishName="Laughing Skull Orcs", icon=1043559},
            ["1681"] = {englishName="Vol'jin's Spear", icon=1042727},
            ["1848"] = {englishName="Vol'jin's Headhunters", icon=5197938},  -- Basic_B_01_fadedred 5197944
        },
        [LocalFactionInfo.UnitFactionGroupID.Neutral] = {
            ["1515"] = {englishName="Arakkoa Outcasts", icon=1042646},
            ["1711"] = {englishName="Steamwheedle Preservation Society", icon=1052654},
            ["1849"] = {englishName="Order of the Awakened", icon=1240656},
            ["1850"] = {englishName="The Saberstalkers", icon=1240657},
        },
        --> TODO - Add "Barracks Bodyguards" ???
    },
};

function LocalFactionInfo:GetExpansionFactionIDs(expansionID)
    return self.FactionIDs[expansionID]
end

function LocalFactionInfo:GetAllFactionDataForExpansion(expansionID, sortFunc)
    local factionData = {};
    local factionIDs = self:GetExpansionFactionIDs(expansionID);

    for unitFactionGroup, expansionFactionIDs in pairs(factionIDs) do
        if self:IsSuitableFactionGroupForPlayer(unitFactionGroup) then
            for factionIDstring, factionTbl in pairs(expansionFactionIDs) do
                local faction = self:GetFactionDataByID(tonumber(factionIDstring));
                faction.icon = factionTbl.icon
                tinsert(factionData, faction);
            end
        end
    end

    table.sort(factionData, sortFunc or self.SortAscendingByFactionName);

    return factionData;
end

----- Formatting -----

-- Retrieve the player's current reputation standing with given faction as text.
function LocalFactionInfo:GetFactionReputationStandingText(factionData)
    local gender = PlayerInfo:GetPlayerSex();
    local reputationStandingText = L:GetText("FACTION_STANDING_LABEL" .. factionData.reaction, gender);

    return reputationStandingText;
end

-- Build a generic reputation progress string from given faction data and return it.
function LocalFactionInfo:GetFactionReputationProgressText(factionData)
    local minValue, maxValue, currentValue;
    local isCapped = self:HasMaximumReputation(factionData);

    if isCapped then
        minValue, maxValue, currentValue = 0, factionData.nextReactionThreshold, factionData.currentStanding;
    else
        minValue, maxValue, currentValue = factionData.currentReactionThreshold, factionData.nextReactionThreshold, factionData.currentStanding;
        maxValue = maxValue - minValue;
        currentValue = currentValue - minValue;
    end

    local reputationProgressText = L.REPUTATION_PROGRESS_FORMAT:format(BreakUpLargeNumbers(currentValue), BreakUpLargeNumbers(maxValue));

    return reputationProgressText;
end

--@do-not-package@
----- Tests --------------------------------------------------------------------

-- local function NormalizeBarValues(minValue, maxValue, currentValue)
-- 	maxValue = maxValue - minValue;
-- 	currentValue = currentValue - minValue;
-- 	minValue = 0;
-- 	return minValue, maxValue, currentValue;
-- end

-- function TestFactions()
--     print(ExpansionInfo.data.WARLORDS_OF_DRAENOR.name)

--     local factionData = LocalFactionInfo:GetAllFactionDataForExpansion(ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID);

--     for i, faction in ipairs(factionData) do
--         local reputationProgressText = LocalFactionInfo:GetFactionReputationProgressText(faction);
--         local reputationStandingText = LocalFactionInfo:GetFactionReputationStandingText(faction);

--         print("-", i, faction.factionID, faction.name);
--         -- print("-->", faction.atWarWith, faction.isChild, faction.hasBonusRepGain);
--         print("-->", reputationStandingText, L.PARENS_TEMPLATE:format(reputationProgressText));
--     end
-- end
--@end-do-not-package@