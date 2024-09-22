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

local function IsSuitableFactionGroupForPlayer(unitFactionGroup)
    return (unitFactionGroup == LocalFactionInfo.UnitFactionGroupID.Player or
            unitFactionGroup == LocalFactionInfo.UnitFactionGroupID.Neutral);
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

----- Unit Faction Groups ------

LocalFactionInfo.PlayerFactionGroupID = UnitFactionGroup("player");

-- {Alliance=1, Horde=2, Neutral=3, Player=1|2}
LocalFactionInfo.UnitFactionGroupID = EnumUtil.MakeEnum(
    PLAYER_FACTION_GROUP[1],
    PLAYER_FACTION_GROUP[0],
    "Neutral"
);
LocalFactionInfo.UnitFactionGroupID["Player"] = LocalFactionInfo.UnitFactionGroupID[LocalFactionInfo.PlayerFactionGroupID];

----- Data Handler -------------------------------------------------------------

----- Draenor -----

LocalFactionInfo.FactionIDs = {
    [ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID] = {
        [LocalFactionInfo.UnitFactionGroupID.Alliance] = {
            ["1731"] = "Council of Exarchs",
            ["1710"] = "Sha'tari Defense",
            ["1682"] = "Wrynn's Vanguard",
            ["1847"] = "Hand of the Prophet",
        },
        [LocalFactionInfo.UnitFactionGroupID.Horde] = {
            ["1445"] = "Frostwolf Orcs",
            ["1708"] = "Laughing Skull Orcs",
            ["1681"] = "Vol'jin's Spear",
            ["1848"] = "Vol'jin's Headhunters",
        },
        [LocalFactionInfo.UnitFactionGroupID.Neutral] = {
            ["1515"] = "Arakkoa Outcasts",
            ["1711"] = "Steamwheedle Preservation Society",
            ["1849"] = "Order of the Awakened",
            ["1850"] = "The Saberstalkers",
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
        if IsSuitableFactionGroupForPlayer(unitFactionGroup) then
            for factionIDstring, fallbackName in pairs(expansionFactionIDs) do
                tinsert(factionData, self:GetFactionDataByID(tonumber(factionIDstring)));
            end
        end
    end

    table.sort(factionData, sortFunc or LocalFactionInfo.SortAscendingByFactionName);

    return factionData;
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
--     -- local expansionList = ExpansionInfo:GetExpansionsWithLandingPage();
--     -- for _, expansion in ipairs(expansionList) do
--     --     if expansion.ID < ExpansionInfo.data.DRAGONFLIGHT.ID then
--     --         -- TODO
--     --     end
--     -- end
--     print(ExpansionInfo.data.WARLORDS_OF_DRAENOR.name)

--     local factionDataList = LocalFactionInfo:GetAllFactionDataForExpansion(ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID);

--     for i, faction in ipairs(factionDataList) do
--         -- Draenor Reputation: InitializeBarForStandardReputation
--         local isCapped = faction.reaction == MAX_REPUTATION_REACTION;  --> 8
--         local minValue, maxValue, currentValue;
--         if isCapped then
--             -- Max rank, make it look like a full bar
--             minValue, maxValue, currentValue = 0, faction.nextReactionThreshold, faction.currentStanding;
--         else
--             minValue, maxValue, currentValue = faction.currentReactionThreshold, faction.nextReactionThreshold, faction.currentStanding;
--             maxValue = maxValue - minValue;
-- 	        currentValue = currentValue - minValue;
--         end
--         -- minValue, maxValue, currentValue = NormalizeBarValues(minValue, maxValue, currentValue);

--         -- local reputationString = "("..currentValue.." / "..maxValue..")";
--         local reputationValuesString = L.REPUTATION_PROGRESS_FORMAT:format(BreakUpLargeNumbers(currentValue), BreakUpLargeNumbers(maxValue));
--         local gender = PlayerInfo:GetPlayerSex();

--         local reputationStandingText = L.GetText("FACTION_STANDING_LABEL" .. faction.reaction, gender);
--         print("-", i, faction.factionID, faction.name);
--         -- print("-->", faction.atWarWith, faction.isChild, faction.hasBonusRepGain, reputationString);
--         print("-->", reputationStandingText, L.PARENS_TEMPLATE:format(reputationValuesString));  --, C_Reputation.IsFactionActive());
--     end
-- end
--@end-do-not-package@