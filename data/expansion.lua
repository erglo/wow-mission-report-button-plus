--------------------------------------------------------------------------------
--[[ expansion.lua - Utilities handling expansion related data. ]]--
--
-- by erglo <erglo.coder+MRBP@gmail.com>
--
-- Copyright (C) 2024  Erwin D. Glockner (aka ergloCoder)
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
-- + [FrameXML - ExpansionDocumentation.lua](https://www.townlong-yak.com/framexml/live/Blizzard_APIDocumentationGenerated/ExpansionDocumentation.lua)
-- + [FrameXML - AccountUtil.lua](https://www.townlong-yak.com/framexml/live/AccountUtil.lua)
-- + [Warcraft Wiki - World_of_Warcraft_API#Expansions](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API#Expansions)
-- 
--------------------------------------------------------------------------------

local AddonID, ns = ...;

local ExpansionInfo = {};
ns.ExpansionInfo = ExpansionInfo;

----- Constants ----------------------------------------------------------------

-- Hold most basic infos about each expansion.
--> **Note:** Expansions prior to Warlords Of Draenor are of no use to this
-- add-on since they don't have world quests nor a landing page for mission
-- reports.
ExpansionInfo.data = {
	-- ["Classic"] = {
	-- 	["ID"] = LE_EXPANSION_CLASSIC,  -- 0
	-- 	["name"] = EXPANSION_NAME0,
	-- },
	-- ["BurningCrusade"] = {
	-- 	["ID"] = LE_EXPANSION_BURNING_CRUSADE,  -- 1
	-- 	["name"] = EXPANSION_NAME1,
	-- },
	-- ["WrathOfTheLichKing"] = {
	-- 	["ID"] = LE_EXPANSION_WRATH_OF_THE_LICH_KING,  -- 2
	-- 	["name"] = EXPANSION_NAME2,
	-- },
	-- ["Cataclysm"] = {
	-- 	["ID"] = LE_EXPANSION_CATACLYSM,  -- 3
	-- 	["name"] = EXPANSION_NAME3,
	-- },
	-- ["MistsOfPandaria"] = {
	-- 	["ID"] = LE_EXPANSION_MISTS_OF_PANDARIA,  -- 4
	-- 	["name"] = EXPANSION_NAME4,
	-- },
	WARLORDS_OF_DRAENOR = {
		["ID"] = LE_EXPANSION_WARLORDS_OF_DRAENOR,  -- 5
		["name"] = EXPANSION_NAME5,
		["garrisonTypeID"] = Enum.GarrisonType.Type_6_0_Garrison,
		["continents"] = {572}  -- Draenor
		-- **Note:** No bounties in Draenor; only available since Legion.
	},
	LEGION = {
		["ID"] = LE_EXPANSION_LEGION,  -- 6
		["name"] = EXPANSION_NAME6,
		["garrisonTypeID"] = Enum.GarrisonType.Type_7_0_Garrison,
		["continents"] = {619, 905},  -- Broken Isles + Argus
	},
	BATTLE_FOR_AZEROTH = {
		["ID"] = LE_EXPANSION_BATTLE_FOR_AZEROTH,  -- 7
		["name"] = EXPANSION_NAME7,
		["garrisonTypeID"] = Enum.GarrisonType.Type_8_0_Garrison,
		["continents"] = {875, 876},  -- Zandalar, Kul Tiras
		["poiZones"] = {1355, 62, 14, 81},  -- Nazjatar, Darkshore, Arathi Highlands, Silithus
	},
	SHADOWLANDS = {
		["ID"] = LE_EXPANSION_SHADOWLANDS,  -- 8
		["name"] = EXPANSION_NAME8,
		["garrisonTypeID"] = Enum.GarrisonType.Type_9_0_Garrison,
		["continents"] = {1550},  -- Shadowlands
	},
	DRAGONFLIGHT = {
		["ID"] = LE_EXPANSION_DRAGONFLIGHT,  -- 9
		["name"] = EXPANSION_NAME9,
		-- ["garrisonTypeID"] = Enum.ExpansionLandingPageType.Dragonflight,
		["garrisonTypeID"] = Enum.ExpansionLandingPageType.None,  --> 0
		["landingPageTypeID"] = Enum.ExpansionLandingPageType.Dragonflight,
		["continents"] = {1978},  -- Dragon Isles
	},
	WAR_WITHIN = {
		["ID"] = LE_EXPANSION_WAR_WITHIN,  -- 10
		["name"] = EXPANSION_NAME10,
		-- ["garrisonTypeID"] = Enum.ExpansionLandingPageType.WarWithin,  --> Note: is same number as Draenor ID (!)
		["garrisonTypeID"] = Enum.ExpansionLandingPageType.None,  --> 0
		["landingPageTypeID"] = Enum.ExpansionLandingPageType.WarWithin,
		["continents"] = {},  -- Khaz Algar
	},
};

----- Data Handler -------------------------------------------------------------

-- Return the expansion data of given expansion ID.
---@param expansionID number  The expansion level 
---@return table ExpansionData
--
function ExpansionInfo:GetExpansionData(expansionID)
	for _, expansion in pairs(self.data) do
		if (expansion.ID == expansionID) then
			return expansion;
		end
	end
	return {};																	--> TODO - Add default table for new expansions
end

-- Return the expansion data of given expansion ID.
---@param garrisonTypeID number  A landing page garrison type ID
---@return table|nil ExpansionData
-- 
function ExpansionInfo:GetExpansionDataByGarrisonType(garrisonTypeID)
	for _, expansion in pairs(self.data) do
		if (expansion.garrisonTypeID == garrisonTypeID) then
			return expansion;
		end
	end
	-- return {};
end

-- Comparison function: sort expansion list by ID in *ascending* order.
---@param a table  ExpansionInfo.data type
---@param b table  ExpansionInfo.data type
---@return boolean
--
function ExpansionInfo.SortAscending(a, b)
	return a.ID < b.ID;  --> 0-9
end

-- Comparison function: sort expansion list by ID in *descending* order.
---@param a table  ExpansionInfo.data type
---@param b table  ExpansionInfo.data type
---@return boolean
--
function ExpansionInfo.SortDescending(a, b)
	return a.ID > b.ID;  --> 9-0 (default)
end

-- Return the expansion data of those which have a landing page.
---@param compFunc function|nil  The function which handles the expansion sorting order. By default sort order is ascending.
---@return table expansionData
--
function ExpansionInfo:GetExpansionsWithLandingPage(compFunc)
	local expansionTable = {};
	for name, expansion in pairs(self.data) do
		tinsert(expansionTable, expansion);
	end
	local sortFunc = compFunc or self.SortAscending;
	table.sort(expansionTable, sortFunc);

	return expansionTable;
end

-- Return the given expansion's advertising display infos.
---@param expansionID number  The expansion level 
---@return ExpansionDisplayInfo table
--
function ExpansionInfo:GetDisplayInfo(expansionID)
	return GetExpansionDisplayInfo(expansionID);
end

----- Expansion ID Handler -----

-- Return the expansion ID which corresponds to the given player level.
---@param playerLevel number  A number wich represents a player level. Defaults to the current player level. 
---@return number expansionID  The expansion level
--
function ExpansionInfo:GetExpansionForPlayerLevel(playerLevel)
	local level = playerLevel or UnitLevel("player");
	return GetExpansionForLevel(level);
end

-- Return the ID of the most recent available expansion.
---@return number expansionID  The expansion level
--
function ExpansionInfo:GetMaximumExpansionLevel()
	return GetMaximumExpansionLevel();
end

-- Return the ID of the player's most lowest expansion.
---@return number expansionID  The expansion level
--
function ExpansionInfo:GetMinimumExpansionLevel()
	return GetMinimumExpansionLevel();
end

----- Player Level Handler -----

-- Return the maximal level the player can reach in the current expansion.
---@return number maxPlayerLevel
--
function ExpansionInfo:GetMaxPlayerLevel()
	return GetMaxLevelForPlayerExpansion();
end

-- Check if the given expansion is owned by the player.
---@param expansionID number  The expansion level 
---@return boolean playerOwnsExpansion
--
function ExpansionInfo:DoesPlayerOwnExpansion(expansionID)						--> TODO - Still needed ???
	local maxLevelForExpansion = GetMaxLevelForExpansionLevel(expansionID);
	local maxLevelForCurrentExpansion = self.GetMaxPlayerLevel();
	local playerOwnsExpansion = maxLevelForExpansion <= maxLevelForCurrentExpansion;
	return playerOwnsExpansion;
end
