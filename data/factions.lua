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
local HasMajorFactionMaximumRenown = C_MajorFactions.HasMaximumRenown;

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

-- Retrieve the data of the currently watched faction.
---@return FactionData? watchedFactionData
--
function LocalFactionInfo:GetWatchedFactionData()
    return C_Reputation.GetWatchedFactionData();
end

----- Helper Functions ---------------------------------------------------------

function LocalFactionInfo:HasMaximumReputation(factionData)
    if self:IsFactionParagon(factionData.factionID) then return; end

    if (factionData.reputationType == self.ReputationType.Friendship) then
        local friendshipData = C_GossipInfo.GetFriendshipReputation(factionData.factionID);
    	if (friendshipData and friendshipData.friendshipFactionID > 0) then
    		local repRankInfo = C_GossipInfo.GetFriendshipReputationRanks(factionData.factionID);
    		return repRankInfo.currentLevel == repRankInfo.maxLevel;
    	end
    end
    if (factionData.reputationType == self.ReputationType.MajorFaction) then
        return HasMajorFactionMaximumRenown(factionData.factionID);
    end
    -- ReputationType.Standard
    return factionData.reaction == MAX_REPUTATION_REACTION;  --> 8
end

-- REF.: [SharedColorConstants.lua](https://www.townlong-yak.com/framexml/live/Blizzard_SharedXML/SharedColorConstants.lua)
-- 
function LocalFactionInfo:GetFactionStandingColor(factionData)
    return FACTION_BAR_COLORS[factionData.reaction];
end

----- Sorting -----

function LocalFactionInfo.SortAscendingByFactionID(dataA, dataB)
    return dataA.factionID < dataB.factionID;  --> 0-9
end

-- REF.: [SortUtil.lua](https://www.townlong-yak.com/framexml/live/Blizzard_SharedXML/SortUtil.lua)
function LocalFactionInfo.SortAscendingByFactionName(dataA, dataB)
    -- return SortUtil.CompareUtf8i(dataA.name, dataB.name);  --> A-Z
    return dataA.name < dataB.name;  --> A-Z
end

----- Unit Faction Groups -----

LocalFactionInfo.PlayerFactionGroupID = UnitFactionGroup("player");
LocalFactionInfo.PlayerFactionGroupColor = PLAYER_FACTION_COLORS[PLAYER_FACTION_GROUP[LocalFactionInfo.PlayerFactionGroupID]];
LocalFactionInfo.PlayerFactionGroupAtlas = LocalFactionInfo.PlayerFactionGroupID == "Horde" and "questlog-questtypeicon-horde" or "questlog-questtypeicon-alliance"

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

----- Reputation Type -----

LocalFactionInfo.ReputationType = EnumUtil.MakeEnum(
	"Standard",
	"Friendship",
	"MajorFaction"
);

-- Determine the given faction's reputation type.
function LocalFactionInfo:GetReputationType(factionData)
	if not factionData then return; end

	local friendshipData = C_GossipInfo.GetFriendshipReputation(factionData.factionID);
	local isFriendshipReputation = friendshipData and friendshipData.friendshipFactionID > 0;
	if isFriendshipReputation then
		return self.ReputationType.Friendship;
	end

	if C_Reputation.IsMajorFaction(factionData.factionID) then
		return self.ReputationType.MajorFaction;
	end

	return self.ReputationType.Standard;
end

----- Data ---------------------------------------------------------------------

local FACTION_ID_LIST = {
    [ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID] = {
        [LocalFactionInfo.UnitFactionGroupID.Alliance] = {
            ["1731"] = {englishName="Council of Exarchs",  icon=1048727},       -- achievementID=9470
            ["1710"] = {englishName="Sha'tari Defense", icon=1042739},          -- achievementID=9476
            ["1682"] = {englishName="Wrynn's Vanguard", icon=1042294, isPVP=true},  -- achievementID=9214 (PvP)
            ["1847"] = {englishName="Hand of the Prophet", icon=930038},        -- Tanaan Diplomat, achievementID=10350
        },
        [LocalFactionInfo.UnitFactionGroupID.Horde] = {
            ["1445"] = {englishName="Frostwolf Orcs", icon=1044164},            -- achievementID=9471
            ["1708"] = {englishName="Laughing Skull Orcs", icon=1043559},       -- achievementID=9475
            ["1681"] = {englishName="Vol'jin's Spear", icon=1042727, isPVP=true},  -- achievementID=9215 (PvP)
            ["1848"] = {englishName="Vol'jin's Headhunters", icon=5197938},     -- Tanaan Diplomat, achievementID=10349 (Horde), 10350 (Alliance)
        },
        [LocalFactionInfo.UnitFactionGroupID.Neutral] = {
            ["1515"] = {englishName="Arakkoa Outcasts", icon=1042646},          -- achievementID=9469
            ["1711"] = {englishName="Steamwheedle Preservation Society", icon=1052654},  -- achievementID=9472
            ["1849"] = {englishName="Order of the Awakened", icon=1240656},     -- Tanaan Diplomat, achievementID=10349 (Horde), 10350 (Alliance)
            ["1850"] = {englishName="The Saberstalkers", icon=1240657},         -- Tanaan Diplomat, achievementID=10349 (Horde), 10350 (Alliance)
        },
        --> TODO - Add "Barracks Bodyguards" ???
    },
};

local BONUS_FACTION_ID_LIST = {
    [ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID] = {                             -- achievementID=9499
        [LocalFactionInfo.UnitFactionGroupID.Alliance] = {
            ["1733"] = {englishName="Delvar Ironfist", icon=236685, iconTemplate="Interface/Icons/Achievement_Reputation_0"},  -- eg. "Interface/Icons/Achievement_Reputation_06" (236686)
            ["1738"] = {englishName="Defender Illona", icon=236685, iconTemplate="Interface/Icons/Achievement_Reputation_0"},
        },
        [LocalFactionInfo.UnitFactionGroupID.Horde] = {
            ["1739"] = {englishName="Vivianne", icon=236687, iconTemplate="Interface/Icons/Achievement_Reputation_0"},
            ["1740"] = {englishName="Aeda Brightdawn", icon=236687, iconTemplate="Interface/Icons/Achievement_Reputation_0"},
        },
        [LocalFactionInfo.UnitFactionGroupID.Neutral] = {
            ["1736"] = {englishName="Tormmok", icon=236688, iconTemplate="Interface/Icons/Achievement_Reputation_0"},
            ["1737"] = {englishName="Talonpriest Ishaal", icon=236688, iconTemplate="Interface/Icons/Achievement_Reputation_0"},
            ["1741"] = {englishName="Leorajh", icon=236688, iconTemplate="Interface/Icons/Achievement_Reputation_0"},
        },
    },
};

-- REF.: [ArtTextureID.lua](https://www.townlong-yak.com/framexml/live/Helix/ArtTextureID.lua)
local BONUS_FACTION_STANDING_ICON_LIST = {
    [1] = 236681,  --> "Interface/Icons/Achievement_Reputation_01"
	[2] = 236682,  --> "Interface/Icons/Achievement_Reputation_02"
	[3] = 236683,  --> "Interface/Icons/Achievement_Reputation_03"
	[4] = 236684,  --> "Interface/Icons/Achievement_Reputation_04"
	[5] = 236685,  --> "Interface/Icons/Achievement_Reputation_05"
	[6] = 236686,  --> "Interface/Icons/Achievement_Reputation_06"
	[7] = 236687,  --> "Interface/Icons/Achievement_Reputation_07"
	[8] = 236688,  --> "Interface/Icons/Achievement_Reputation_08"
};

local function GetBonusFactionStandingIcon(factionData)
    return BONUS_FACTION_STANDING_ICON_LIST[factionData.reaction];
end

function LocalFactionInfo:GetExpansionFactionIDs(expansionID)
    return FACTION_ID_LIST[expansionID];
end

function LocalFactionInfo:GetExpansionBonusFactionIDs(expansionID)
    return BONUS_FACTION_ID_LIST[expansionID];
end

function LocalFactionInfo:GetAllFactionDataForExpansion(expansionID, isBonusFaction, sortFunc)
    local factionData = {};
    local factionIDs = isBonusFaction and self:GetExpansionBonusFactionIDs(expansionID) or self:GetExpansionFactionIDs(expansionID);

    for unitFactionGroup, expansionFactionIDs in pairs(factionIDs) do
        if self:IsSuitableFactionGroupForPlayer(unitFactionGroup) then
            for factionIDstring, factionTbl in pairs(expansionFactionIDs) do
                local faction = self:GetFactionDataByID(tonumber(factionIDstring));
                faction.icon = isBonusFaction and GetBonusFactionStandingIcon(faction) or factionTbl.icon;
                faction.reputationType = LocalFactionInfo:GetReputationType(faction);
                faction.isPVP = factionTbl.isPVP;
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
    if (factionData.reputationType == self.ReputationType.Standard) then
        local gender = PlayerInfo:GetPlayerSex();
        local reputationStandingText = L:GetText("FACTION_STANDING_LABEL" .. factionData.reaction, gender);
        return reputationStandingText;
    end
    if (factionData.reputationType == self.ReputationType.Friendship) then
        local friendshipData = C_GossipInfo.GetFriendshipReputation(factionData.factionID);
        return friendshipData and friendshipData.reaction or '';
    end
    if (factionData.reputationType == self.ReputationType.MajorFaction) then
        local majorFactionData = C_MajorFactions.GetMajorFactionData(factionData.factionID);
        return majorFactionData and L.RENOWN_LEVEL_LABEL..L.TEXT_DELIMITER..majorFactionData.renownLevel;
    end

    return L.UNKNOWN;
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