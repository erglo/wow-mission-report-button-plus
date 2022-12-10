--------------------------------------------------------------------------------
--[[ Mission Report Button Plus - Utility and logging functions ]]--
--
-- by erglo <erglo.coder+MRBP@gmail.com>
--
-- Copyright (C) 2022  Erwin D. Glockner (aka erglo)
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
-- local L = ns.L;

ns.AddonTitle = GetAddOnMetadata(AddonID, "Title");
ns.AddonTitleShort = 'MRBP';
ns.AddonColor = CreateColor(0.6, 0.6, 0.6);	--> light gray
ns.AddonTitleSeparator = HEADER_COLON; --> WoW global string

----- Logging ------------------------------------------------------------------

local _log = {};
ns.dbg_logger = _log;  --> put to namespace for use in the core file

-- Logging levels
_log.INFO = 20;
_log.DEBUG = 10;
_log.NOTSET = 0;
_log.USER = -10;

-- _log.level = _log.INFO;
-- _log.level = _log.DEBUG;
-- _log.level = _log.NOTSET;
_log.level = _log.USER;

-- Convenience functions for additional output for debugging.
function _log:debug(...)
	if (_log.level == _log.DEBUG) then
		print(ns.AddonColor:WrapTextInColorCode(ns.AddonTitleShort),
			  DIM_RED_FONT_COLOR:WrapTextInColorCode("DEBUG:"),
			  ...
		);
	end
end

function _log:info(...)
	if (_log.level <= _log.INFO and _log.level > _log.NOTSET) then
		print(ns.AddonColor:WrapTextInColorCode(ns.AddonTitleShort),
			  DIM_GREEN_FONT_COLOR:WrapTextInColorCode("INFO:"),
			  ...
		);
	end
end

-- Convenience function for informing the user with a chat message.
-- (cprint --> chat_print)
local function cprint(...)
	if (_log.level == _log.USER) then
		print(ns.AddonColor:WrapTextInColorCode(ns.AddonTitleShort..":"), ...);
	end
end
ns.cprint = cprint;

----- Printing to chat ---------------------------------------------------------

local util = {};
ns.utilities = util;

-- Print the current add-on's version infos to chat.
function util.printVersion(shortVersionOnly)
	local version = GetAddOnMetadata(AddonID, "Version");
	if version then
		if shortVersionOnly then
			print(ns.AddonColor:WrapTextInColorCode(version));
		else
			local title = GetAddOnMetadata(AddonID, "Title");
			local author = GetAddOnMetadata(AddonID, "Author");
			local notes_enUS = GetAddOnMetadata(AddonID, "Notes");
			local notes_local = GetAddOnMetadata(AddonID, "Notes-"..GetLocale());
			local notes = notes_local or notes_enUS;
			local output = title..'|n'..version..' by '..author..'|n'..notes;
			print(ns.AddonColor:WrapTextInColorCode(output));
		end
	end
end

-- Print garrison related event messages, ie. finished missions/buildings
-- etc. to chat.
function util.cprintEvent(locationName, eventMsg, typeName, instructions, isHyperlink)
	if ( typeName and not isHyperlink ) then
		-- typeName = YELLOW_FONT_COLOR:WrapTextInColorCode(PARENS_TEMPLATE:format(typeName));  --> WoW global string
		typeName = LIGHTYELLOW_FONT_COLOR:WrapTextInColorCode(typeName);
	end
	cprint(DARKYELLOW_FONT_COLOR:WrapTextInColorCode(FROM_A_DUNGEON:format(locationName)),  --> WoW global string
		   eventMsg, typeName and typeName or '', instructions and '|n'..instructions or '');
end

----- Common helper function----------------------------------------------------

function util.tcount(tbl)
	local n = #tbl or 0;
	if (n == 0) then
		for _ in pairs(tbl) do
			n = n + 1;
		end
	end
	return n;
end

----- Atlas + Textures ---------------------------------------------------------

-- REF.: <FrameXML/Blizzard_Deprecated/Deprecated_8_1_0.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentation/TextureUtilsDocumentation.lua>
function util.GetAtlasInfo(atlas)
	local info = C_Texture.GetAtlasInfo(atlas);
	if info then
		local file = info.filename or info.file;
		return file, info.width, info.height, info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord, info.tilesHorizontally, info.tilesVertically;
	end
end

-- REF.: <FrameXML/TextureUtil.lua>
-- REF.: <https://wowpedia.fandom.com/wiki/UI_escape_sequences#Textures>
function util.CreateInlineIcon(atlasNameOrTexID, sizeX, sizeY, xOffset, yOffset)  --> Returns: string
	sizeX = sizeX or 16;
	sizeY = sizeY or sizeX;
	xOffset = xOffset or 0;
	yOffset = yOffset or -1;

	local isNumberString = tonumber(atlasNameOrTexID) ~= nil;
	if isNumberString then
		atlasNameOrTexID = tonumber(atlasNameOrTexID);
	end
	if ( type(atlasNameOrTexID) == "number") then
		-- REF.: CreateTextureMarkup(file, fileWidth, fileHeight, width, height, left, right, top, bottom, xOffset, yOffset)
		return CreateTextureMarkup(atlasNameOrTexID, 0, 0, sizeX, sizeY, 0, 0, 0, 0, xOffset, yOffset);  --> keep original color
		-- return string.format("|T%d:%d:%d:%d:%d|t", atlasNameOrTexID, size, size, xOffset, yOffset);
	end
	if ( type(atlasNameOrTexID) == "string" or tonumber(atlasNameOrTexID) ~= nil ) then
		-- REF.: CreateAtlasMarkup(atlasName, width, height, offsetX, offsetY, rVertexColor, gVertexColor, bVertexColor)
		return CreateAtlasMarkup(atlasNameOrTexID, sizeX, sizeY, xOffset, yOffset);  --> keep original color
	end
end

-- function util.CreateSimpleTextureMarkup(file, width, height)
-- 	-- REF.: <FrameXML/TextureUtil.lua>
-- 	return ("|T%s:%d:%d|t"):format(
-- 		  file
-- 		, height or width
-- 		, width
-- 	);
-- end

----- Quest utilities ----------------------------------------------------------
--> C_QuestLog, C_TaskQuest
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/QuestTaskInfoDocumentation.lua>
-- REF.: <https://wowpedia.fandom.com/wiki/World_of_Warcraft_API#World_Quests>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/BountySharedDocumentation.lua>

-- A collection of quest related handler.
--> **Note:** Task Quests refer to World Quests or Bonus Objective quests. (see WoWpedia link above for more)
util.quest = {};

-- Check whether given quest ID has been completed.
---@param questID number
---@return boolean isCompleted
--
function util.quest.IsFlaggedCompleted(questID)
	return C_QuestLog.IsQuestFlaggedCompleted(questID);
end

-- Check whether there are any active world threats available.
---@return boolean hasActiveThreats
--
function util.quest.HasActiveThreats()
	return C_QuestLog.HasActiveThreats();
end

-- Get the world quest IDs of all currently available world threats.
---@return number[] quests  A list of world quest IDs
--
function util.quest.GetThreatQuests()
	return C_TaskQuest.GetThreatQuests();
end

-- Check whether given world quest is currently available as an active quest.
---@param questID number  A world quest ID
---@return boolean isActive
--
function util.quest.IsActiveWorldQuest(questID)
	return C_TaskQuest.IsActive(questID);
end

-- Gather basic info about given world quest.
---@param questID number  A world quest ID
---@return table questInfo
---@field questTitle string  The title of the world quest
---@field factionID number  The faction for the world quest
---@field isCapped boolean  Is the quest flagged completed ???
---@field displayAsObjective boolean  Is quest available as objective ???
--
function util.quest.GetWorldQuestInfoByQuestID(questID)
	local questTitle, factionID, capped, displayAsObjective = C_TaskQuest.GetQuestInfoByQuestID(questID);
	local questInfo = {
		["questTitle"] = questTitle,
		["factionID"] = factionID,
		["isCapped"] = capped,
		["displayAsObjective"] = displayAsObjective,
	};
	return questInfo;
end

-- Return the map ID of the location where given world quest is currently active.
---@param questID number  A world quest ID
---@return number uiMapID
--
function util.quest.GetWorldQuestZoneID(questID)
	return C_TaskQuest.GetQuestZoneID(questID);
end

-- Gather all bounty world quests of given map.
---@param mapID number  A UiMapID of a location from the world map.
---@return BountyInfo[] bounties  A list of currently available bounties
---@field questID number  A world quest ID
---@field factionID number  The faction for the world quest
---@field icon number  The type icon
---@field numObjectives number  The number of objectives to complete the bounty
---@field turninRequirementText string  A description about why the quest can't be turned in
--
function util.quest.GetBountiesForMapID(mapID)
	return C_QuestLog.GetBountiesForMapID(mapID);
end

--[[
MapUtil.MapHasUnlockedBounties(mapID)
MapUtil.MapHasEmissaries(mapID)

isAccountQuest = C_QuestLog.IsAccountQuest(questID)
isThreat = C_QuestLog.IsThreatQuest(questID)
isBounty = C_QuestLog.IsQuestBounty(questID)
isCalling = C_QuestLog.IsQuestCalling(questID)

--]]

----- Expansion utilities ------------------------------------------------------
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/ExpansionDocumentation.lua>
-- REF.: <FrameXML/AccountUtil.lua>
-- RER.: <https://wowpedia.fandom.com/wiki/World_of_Warcraft_API#Expansions>

-- A collection of expansion related handler.
util.expansion = {};

-- Set most basic infos about each expansion.
--> **Note:** Expansions prior to Warlords Of Draenor are no use to this add-on since
--  they don't have a mission table nor a landing page for mission reports.
util.expansion.data = {
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
	["WarlordsOfDraenor"] = {
		["ID"] = LE_EXPANSION_WARLORDS_OF_DRAENOR,  -- 5
		["name"] = EXPANSION_NAME5,
		-- ["banner"] = "accountupgradebanner-wod",  -- 199x117
		["garrisonTypeID"] = Enum.GarrisonType.Type_6_0,
	},
	["Legion"] = {
		["ID"] = LE_EXPANSION_LEGION,  -- 6
		["name"] = EXPANSION_NAME6,
		-- ["banner"] = "accountupgradebanner-legion",  -- 199x117
		["garrisonTypeID"] = Enum.GarrisonType.Type_7_0,
	},
	["BattleForAzeroth"] = {
		["ID"] = LE_EXPANSION_BATTLE_FOR_AZEROTH,  -- 7
		["name"] = EXPANSION_NAME7,
		-- ["banner"] = "accountupgradebanner-bfa",  -- 199x133
		["garrisonTypeID"] = Enum.GarrisonType.Type_8_0,
	},
	["Shadowlands"] = {
		["ID"] = LE_EXPANSION_SHADOWLANDS,  -- 8
		["name"] = EXPANSION_NAME8,
		-- ["banner"] = "accountupgradebanner-shadowlands",  -- 199x133
		["garrisonTypeID"] = Enum.GarrisonType.Type_9_0,
	},
	["Dragonflight"] = {
		["ID"] = LE_EXPANSION_DRAGONFLIGHT,  -- 9
		["name"] = EXPANSION_NAME9,
		-- ["banner"] = "accountupgradebanner-dragonflight",  -- 199x133
		["garrisonTypeID"] = Enum.ExpansionLandingPageType.Dragonflight,
	},
};

---Return the expansion data of given expansion ID.
---@param expansionID number  The expansion level 
---@return table ExpansionData
---
function util.expansion.GetExpansionData(expansionID)
	for name, expansion in pairs(util.expansion.data) do
		if (expansion.ID == expansionID) then
			return expansion;
		end
	end
	return {};
end

---Comparison function: sort expansion list by ID in *ascending* order.
---@param a table  ExpansionData
---@param b table  ExpansionData
---@return boolean
---
function util.expansion.SortAscending(a, b)
	return a.ID < b.ID;  --> 0-9
end

---Comparison function: sort expansion list by ID in *descending* order.
---@param a table  ExpansionData
---@param b table  ExpansionData
---@return boolean
---
function util.expansion.SortDescending(a, b)
	return a.ID > b.ID;  --> 9-0 (default)
end

---Return the expansion data of those which have a landing page.
---@param compFunc function|nil  The function which handles the expansion sorting order. By default sort order is ascending.
---@return table expansionData
---
function util.expansion.GetExpansionsWithLandingPage(compFunc)
	local expansionTable = {};
	for name, expansion in pairs(util.expansion.data) do
		-- if (expansion.ID >= util.expansion.data.WarlordsOfDraenor.ID) then
		tinsert(expansionTable, expansion);
		-- end
	end
	local sortFunc = compFunc or util.expansion.SortAscending;
	table.sort(expansionTable, sortFunc);

	return expansionTable;
end

---Return the given expansion's advertising display infos.
---@param expansionID number  The expansion level 
---@return ExpansionDisplayInfo table
---
function util.expansion.GetDisplayInfo(expansionID)
	return GetExpansionDisplayInfo(expansionID);
end

---Check if a given expansion has an unlocked landing page (aka. mission table).
---@param expansionID number  The expansion level 
---@return boolean isUnlocked
---
function util.expansion.IsLandingPageUnlocked(expansionID)
	if (expansionID < util.expansion.data.Dragonflight.ID) then
		-- Every expansion since Draenor and before Dragonflight has a garrison.
		local expansion = util.expansion.GetExpansionData(expansionID);
		local hasGarrison = util.garrison.HasGarrison(expansion.garrisonTypeID) or false;
		return hasGarrison;
	end
	return C_PlayerInfo.IsExpansionLandingPageUnlockedForPlayer(expansionID);
end

-----[[ Expansion ID handler ]]-------------------------------------------------

-- Return the player's current expansion ID.
---@return number expansionID  The expansion level
--
function util.expansion.GetCurrentID()
	-- return GetClampedCurrentExpansionLevel();
	return LE_EXPANSION_LEVEL_CURRENT;
end

-- Return the expansion ID which corresponds to the given player level.
---@param playerLevel number  A number wich represents a player level. Defaults to the current player level. 
---@return number expansionID  The expansion level
--
function util.expansion.GetExpansionForPlayerLevel(playerLevel)
	local level = playerLevel or UnitLevel("player");
	return GetExpansionForLevel(level);
end

-- Return the ID of the most recent available expansion.
---@return number expansionID  The expansion level
--
function util.expansion.GetMaximumExpansionLevel()
	return GetMaximumExpansionLevel();
end

-- Return the ID of the player's most lowest expansion.
---@return number expansionID  The expansion level
--
function util.expansion.GetMinimumExpansionLevel()
	return GetMinimumExpansionLevel();
end

-----[[ Player level handler ]]-------------------------------------------------

-- Return the maximal player level for given expansion.
---@param expansionID number  The expansion level 
---@return number playerMaxLevel
--
function util.expansion.GetMaxExpansionLevel(expansionID)
	return GetMaxLevelForExpansionLevel(expansionID);
end

-- Return the maximal level the player can reach in the current expansion.
---@return number maxPlayerLevel
--
function util.expansion.GetMaxPlayerLevel()
	return GetMaxLevelForPlayerExpansion();
end

-- Check if the given expansion is owned by the player.
---@param expansionID number  The expansion level 
---@return boolean playerOwnsExpansion
--
function util.expansion.DoesPlayerOwnExpansion(expansionID)
	local maxLevelForExpansion = util.expansion.GetMaxExpansionLevel(expansionID);
	local maxLevelForCurrentExpansion = util.expansion.GetMaxPlayerLevel();
	local playerOwnsExpansion = maxLevelForExpansion <= maxLevelForCurrentExpansion;
	return playerOwnsExpansion;
end  --> TODO - Not good enough, refine this

----- Garrison utilities -----------------------------------------------------
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/GarrisonInfoDocumentation.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/GarrisonSharedDocumentation.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/GarrisonConstantsDocumentation.lua>
-- REF.: <FrameXML/GarrisonBaseUtils.lua>
-- REF.: <FrameXML/Blizzard_GarrisonUI/Blizzard_GarrisonMissionUI.lua>

-- A collection of garrison related helper functions; also used for backward 
-- compatibility with often changing WoW globals
util.garrison = {};

-- -- Available garrison landing page types
-- --> **Note:** The Dragonflight landing page is *not* a garrison type
-- util.garrison.GARRISON_TYPES = {
-- 	[Enum.GarrisonType.Type_6_0] = Enum.GarrisonType.Type_6_0,
-- 	[Enum.GarrisonType.Type_7_0] = Enum.GarrisonType.Type_7_0,
-- 	[Enum.GarrisonType.Type_8_0] = Enum.GarrisonType.Type_8_0,
-- 	[Enum.GarrisonType.Type_9_0] = Enum.GarrisonType.Type_9_0,
-- };

-- -- Available follower types of each garrison landing page
-- util.garrison.GARRISON_FOLLOWER_TYPES = {
-- 	Enum.GarrisonFollowerType.FollowerType_6_0,
-- 	Enum.GarrisonFollowerType.FollowerType_6_2,
-- 	Enum.GarrisonFollowerType.FollowerType_7_0,
-- 	Enum.GarrisonFollowerType.FollowerType_8_0,
-- 	Enum.GarrisonFollowerType.FollowerType_9_0,
-- };

-- Check if given garrison type ID is unlocked.
---@param garrisonTypeID number  A landing page garrison type ID
---@return boolean hasGarrison
--
function util.garrison.HasGarrison(garrisonTypeID)
	return C_Garrison.HasGarrison(garrisonTypeID);
end

-- function util.garrison.HasExpansionGarrison(expansionID)
-- 	local expansion = util.expansion.GetExpansionData(expansionID);
-- 	return C_Garrison.HasGarrison(expansion.garrisonTypeID);
-- end

-- Check whether the garrison from Warlords of Draenor has invasions available.
---@return boolean isAvailable
--
function util.garrison.IsDraenorInvasionAvailable()
	return C_Garrison.IsInvasionAvailable();
end

----- [[ Dragonflight ]] -----
--
-- REF.: <FrameXML/AchievementUtil.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/AchievementInfoDocumentation.lua>
-- REF.: <https://wowpedia.fandom.com/wiki/World_of_Warcraft_API#Achievements>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua>
-- REF.: <FrameXML/Blizzard_MajorFactions/Blizzard_MajorFactionRenown.lua>

-- Check if the dragon riding feature in Dragonflight is unlocked.
---@return boolean isUnlocked
--
function util.garrison.IsDragonRidingUnlocked()
	-- REF.: <FrameXML/Blizzard_ExpansionLandingPage/Blizzard_DragonflightLandingPage.lua>
	local DRAGONRIDING_ACCOUNT_ACHIEVEMENT_ID = 15794;
	local DRAGONRIDING_INTRO_QUEST_ID = 68798;
	local hasAccountAchievement = select(4, GetAchievementInfo(DRAGONRIDING_ACCOUNT_ACHIEVEMENT_ID));
	return hasAccountAchievement or util.quest.IsFlaggedCompleted(DRAGONRIDING_INTRO_QUEST_ID);
end
Test_IsDragonRidingUnlocked = util.garrison.IsDragonRidingUnlocked;

-- Count the available dragon glyphs of each zone in Dragonflight.
---@return table glyphCount
--
function util.garrison.GetDragonGlyphsCount()
	local DRAGONRIDING_GLYPH_HUNTER_ACHIEVEMENTS = {
		{mapID = 2022, achievementID = 16575},  -- "Waking Shores Glyph Hunter"
		{mapID = 2023, achievementID = 16576},  -- "Ohn'ahran Plains Glyph Hunter"
		{mapID = 2024, achievementID = 16577},  -- "Azure Span Glyph Hunter"
		{mapID = 2025, achievementID = 16578},  -- "Thaldraszus Glyph Hunter"
	};
	local glyphCount = {};  -- Glyph count by map ID
	for _, info in ipairs(DRAGONRIDING_GLYPH_HUNTER_ACHIEVEMENTS) do
		local numCriteria = GetAchievementNumCriteria(info.achievementID);
		local mapInfo = util.map.GetMapInfo(info.mapID);
		local numComplete = 0;
		for i=1, numCriteria do
			local criteriaCompleted = select(3, GetAchievementCriteriaInfo(info.achievementID, i));
			if criteriaCompleted then
				numComplete = numComplete + 1;
			end
		end
		glyphCount[mapInfo.name] = {};  -- The name of a zone
		glyphCount[mapInfo.name].numTotal = numCriteria;  -- The total number of glyphs per zone
		glyphCount[mapInfo.name].numComplete = numComplete;  -- The number of collected glyphs per zone
	end

	return glyphCount;
end
Test_GetDragonGlyphsCount = util.garrison.GetDragonGlyphsCount;

-- Return a list of major faction IDs.
---@param expansionID number  The expansion level
---@return number[] majorFactionIDs
--
function util.garrison.GetMajorFactionIDs(expansionID)
	return C_MajorFactions.GetMajorFactionIDs(expansionID);
end

-- Retrieve the data for given major faction ID.
---@param factionID number  A major faction ID (since Dragonflight WoW 10.x)
---@return MajorFactionData table
--
function util.garrison.GetMajorFactionData(factionID)
	return C_MajorFactions.GetMajorFactionData(factionID);
end

--[[
MapUtil.ShouldShowTask(mapID, info)
MapUtil.MapHasEmissaries(mapID)
MapUtil.MapHasUnlockedBounties(mapID)
--]]

-- Return a list with details about currently running garrison missions.
---@param followerType Enum.GarrisonFollowerType
---@return missionInfo[] inProgressMissions
--
function util.garrison.GetInProgressMissions(followerType)
	return C_Garrison.GetInProgressMissions(followerType);
end

-- Check wether the given garrison type has running or completed missions
-- and return the number of those missions.
---@param garrisonTypeID number  A landing page garrison type ID
---@return number numInProgress  Number of currently running missions
---@return number numCompleted  Number of completed missions
--
function util.garrison.GetInProgressMissionCount(garrisonTypeID)
	local numInProgress, numCompleted = 0, 0;
	local missions;

	_log:info("Counting in-progress missions for garrison type", garrisonTypeID);

	for followerType, followerOptions in pairs(GarrisonFollowerOptions) do
		if (followerOptions.garrisonType == garrisonTypeID) then
			missions = util.garrison.GetInProgressMissions(followerType);
			if missions then
				for i, mission in ipairs(missions) do
					if (mission.isComplete == nil) then
						-- Quick fix; the 'isComplete' attribute is sometimes nil even though the mission is finished.
						mission.isComplete = mission.timeLeftSeconds == 0;
					end
					if mission.isComplete then
						numCompleted = numCompleted + 1;
					end
					numInProgress = numInProgress + 1;
				end
			end
		end
	end
	_log:debug(string.format("Got %d missions active and %d completed.", numInProgress, numCompleted));

	return numInProgress, numCompleted;
end

----- World threats ------------------------------------------------------------
-- REF.: <FrameXML/Blizzard_WorldMap/Blizzard_WorldMapTemplates.lua>
-- REF.: <https://wowpedia.fandom.com/wiki/UI_escape_sequences>

-- A collection of map related functions.
util.map = {};

-- Return informations about given map zone.
---@param mapID number  A UiMapID of a location from the world map.
---@return UiMapDetails table MapDocumentation.UiMapDetails
function util.map.GetMapInfo(mapID)
	return C_Map.GetMapInfo(mapID);
end

-- -- Retrieve the zones of given continent's map ID.
-- --> Returns: <table>
-- --
-- -- REF.: <FrameXML/Blizzard_APIDocumentation/MapDocumentation.lua>
-- function util.map.GetContinentZones(mapID, allDescendants)
-- 	local infos = {};
-- 	local ALL_DESCENDANTS = allDescendants or false;

-- 	for i, mapInfo in pairs(C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone, ALL_DESCENDANTS)) do
-- 		tinsert(infos, mapInfo);
-- 		-- print(i, mapInfo.mapID, mapInfo.name, "-->", mapInfo.mapType);
-- 	end

-- 	return infos;
-- end
-- Test_GetContinentZones = util.map.GetContinentZones;

-- Find active threats in the world, if active for current player; eg. the
-- covenant attacks in The Maw or the N'Zoth's attacks in Battle for Azeroth.
---@return table activeThreats
---@return boolean hasActiveThreats
--
function util.map.GetActiveThreats()
	if util.quest.HasActiveThreats() then
		local threatQuests = util.quest.GetThreatQuests();
		local activeThreats = {};
		for i, questID in ipairs(threatQuests) do
			if util.quest.IsActiveWorldQuest(questID) then
				local questInfo = util.quest.GetWorldQuestInfoByQuestID(questID);
				local typeAtlas =  QuestUtil.GetThreatPOIIcon(questID);
				-- local questLink = string.format("%s|Hquest:%d:-1|h[%s]|h|r", NORMAL_FONT_COLOR_CODE, questID, questInfo.questTitle);
				-- local questName = util.CreateInlineIcon(typeAtlas)..questLink;
				local questName = util.CreateInlineIcon(typeAtlas)..questInfo.questTitle;
				local mapID = util.quest.GetWorldQuestZoneID(questID);
				local mapInfo = util.map.GetMapInfo(mapID);
				local questExpansionLevel = GetQuestExpansion(questID);
				if questExpansionLevel then
					_log:debug("Threat:", questID, questInfo.questTitle, ">", mapID, mapInfo.name, "expLvl:", questExpansionLevel);
					if ( not activeThreats[questExpansionLevel] ) then
						-- Add table values per expansion IDs
						activeThreats[questExpansionLevel] = {};
					end
					tinsert(activeThreats[questExpansionLevel], {questID, questName, mapInfo.name});
				end
		   end
		end
		return activeThreats;
	 end
	return false;
end

----- Specials -----------------------------------------------------------------

-- Check the calendar if currently a world quest event is happening.
--> Returns: 3-array (<boolean>, <eventTable>, <formattedEventTextMessage>)
--
-- REF.: <FrameXML/CalendarUtil.lua>
function util.IsTodayWorldQuestDayEvent()
	_log:info("Scanning calendar for day events...");
	local event;
	local eventID_WORLDQUESTS = 613;
	-- local eventID_WINTER_HOLIDAY = 141;		--> TODO
	-- local eventID_WOW_BIRTHDAY = 1262; 		--> TODO

	local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime();  --> today
	-- Tests:
	-- currentCalendarTime.monthDay = 17;
	-- currentCalendarTime.weekday = 6;
	-- currentCalendarTime.hour = 5;
	local monthOffset = 0;  --> this month
	local numDayEvents = C_Calendar.GetNumDayEvents(monthOffset, currentCalendarTime.monthDay);
	_log:info("numDayEvents:", numDayEvents);

	for eventIndex = 1, numDayEvents do
		event = C_Calendar.GetDayEvent(monthOffset, currentCalendarTime.monthDay, eventIndex);
		-- _log:debug("eventID:", event.eventID, eventID_WORLDQUESTS, event.eventID == eventID_WORLDQUESTS);

		if ( event.eventID == eventID_WORLDQUESTS ) then
		-- if ( event.eventID == eventID_WINTER_HOLIDAY ) then
			_log:debug("Got:", event.title, event.endTime.monthDay - currentCalendarTime.monthDay, "days left");

			if ( event.sequenceType == "END" and currentCalendarTime.hour >= event.endTime.hour ) then
				-- Don't show anything on last day after event ends
				break;
			end
			if ( event.sequenceType == "START" and currentCalendarTime.hour >= event.endTime.hour ) then
				-- Show as ongoing on the first day after event starts
				event.sequenceType = "ONGOING";
			end

			local timeString, suffixString;
			local eventLinkText = GetCalendarEventLink(monthOffset, currentCalendarTime.monthDay, eventIndex);
			local eventLink = LINK_FONT_COLOR:WrapTextInColorCode(COMMUNITIES_CALENDAR_CHAT_EVENT_TITLE_FORMAT:format(eventLinkText));

			if ( event.sequenceType == "ONGOING" ) then
				-- Show on days between the first and the last day
				timeString = COMMUNITIES_CALENDAR_ONGOING_EVENT_PREFIX;
				-- Also show roughly the remaining time for the ongoing event
				local timeLeft = event.endTime.monthDay - currentCalendarTime.monthDay;
				suffixString = SPELL_TIME_REMAINING_DAYS:format(timeLeft);
			else
				-- Show on first and last day of the event
				if ( event.sequenceType == "START" ) then
					timeString = GameTime_GetFormattedTime(event.startTime.hour, event.startTime.minute, true);
				end
				if ( event.sequenceType == "END" ) then
					timeString = GameTime_GetFormattedTime(event.endTime.hour, event.endTime.minute, true);

				end
				-- Add localized text whether the today's event starts or ends
				eventLink = _G["CALENDAR_EVENTNAME_FORMAT_"..event.sequenceType]:format(eventLink);
				timeString = COMMUNITIES_CALENDAR_EVENT_FORMAT:format(COMMUNITIES_CALENDAR_TODAY, timeString);
			end
			local chatMsg = YELLOW_FONT_COLOR:WrapTextInColorCode(COMMUNITIES_CALENDAR_CHAT_EVENT_BROADCAST_FORMAT:format(timeString, eventLink, suffixString or ''));

			return true, event, chatMsg;
		end
	end

	_log:debug("Wanted day event not found.")
	return false, nil, nil;
end

----- more to come -------------------------------------------------------------
