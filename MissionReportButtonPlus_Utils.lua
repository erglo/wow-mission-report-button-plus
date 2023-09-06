--------------------------------------------------------------------------------
--[[ Mission Report Button Plus - Utility and logging functions ]]--
--
-- by erglo <erglo.coder+MRBP@gmail.com>
--
-- Copyright (C) 2023  Erwin D. Glockner (aka erglo)
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
local data = ns.data

-- Backwards compatibility
ns.GetAddOnMetadata = C_AddOns.GetAddOnMetadata;

ns.AddonTitle = ns.GetAddOnMetadata(AddonID, "Title");
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

_log.DEVMODE = false;

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

-- Debug specific areas or features only
_log.type = {
	BUILDINGS = "buildings",
	MINIMAP_BUTTON = "minimap_button",
	MISSIONS = "missions",
	CALENDAR = "calendar",
};
-- _log.type_level = _log.type.CALENDAR;

-- Convenience functions for debugging specific areas or features in the code.
function _log:debug_type(logType, ...)
	if (_log.DEVMODE and _log.type_level == logType) then
		local title = ns.AddonColor:WrapTextInColorCode(ns.AddonTitleShort);
		-- local prefix = format("DBG-%s:", strupper(logType));
		-- print(title, DIM_RED_FONT_COLOR:WrapTextInColorCode(prefix), ...);
		print(title, DIM_RED_FONT_COLOR:WrapTextInColorCode("DEBUG:"), ...);
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
	-- if (_log.level == _log.USER) then
	if ns.settings.showChatNotifications then
		print(ns.AddonColor:WrapTextInColorCode(ns.AddonTitleShort..":"), ...);
	end
end
ns.cprint = cprint;

----- Printing to chat -----

local util = {};
ns.utilities = util;

-- Print the current add-on's version infos to chat.
--
function util.printVersion(shortVersionOnly)
	local version = ns.GetAddOnMetadata(AddonID, "Version");
	if version then
		if shortVersionOnly then
			print(ns.AddonColor:WrapTextInColorCode(version));
		else
			local title = ns.GetAddOnMetadata(AddonID, "Title");
			local author = ns.GetAddOnMetadata(AddonID, "Author");
			local notes_enUS = ns.GetAddOnMetadata(AddonID, "Notes");
			local notes_local = ns.GetAddOnMetadata(AddonID, "Notes-"..L.currentLocale);
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

-- Strip the hyphen character from German locale strings.
---@param text string
---@return string
--
function util.strip_DE_hyphen(text)
	if L:IsGermanLocale(L.currentLocale) then
		local prefix, postfix = strsplit('-', text);
		if postfix then
			-- Only when text contained a hyphen is postfix non-empty
			return prefix..strtrim(postfix);
		end
	end
	return text;
end


-- Check if given table exists and if it has any entries.  
-- **Note:** This is an extended version of Blizzard's `TableHasAnyEntries` utility function.
---@param tbl table
---@return boolean
--
-- REF.: <https://www.townlong-yak.com/framexml/live/TableUtil.lua>
--
function util.TableHasAnyEntries(tbl)
	if not tbl then return false end

	return next(tbl) ~= nil
end

--------------------------------------------------------------------------------
----- Atlas + Textures ---------------------------------------------------------
--------------------------------------------------------------------------------
-- REF.: <FrameXML/Blizzard_Deprecated/Deprecated_8_1_0.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentation/TextureUtilsDocumentation.lua>

function util.GetAtlasInfo(atlas)
	local info = C_Texture.GetAtlasInfo(atlas);
	if info then
		local file = info.filename or info.file;
		return file, info.width, info.height, info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord, info.tilesHorizontally, info.tilesVertically;
	end
end

-- Convert an atlas name to a texture file and add it to given tooltip.
--
-- REF.: <https://wowpedia.fandom.com/wiki/API_GameTooltip_AddTexture>
--
function util.GameTooltip_AddAtlas(tooltip, atlasName, atlasWidth, atlasHeight, anchor, marginRight)
	local atlasInfo = C_Texture.GetAtlasInfo(atlasName)
	tooltip:AddTexture(atlasInfo.file, {
		width = atlasWidth or 16,    -- atlasInfo.width,
		height = atlasHeight or 16,  -- atlasInfo.height,
		texCoords = {
			left = atlasInfo.leftTexCoord,
			right = atlasInfo.rightTexCoord,
			top = atlasInfo.topTexCoord,
			bottom = atlasInfo.bottomTexCoord,
		},
		margin = {
			left = 0,
			right = marginRight or 1,
			top = 0,
			bottom = 0,
		},
		anchor = anchor or Enum.TooltipTextureAnchor.LeftCenter,
	})
end

-- Add given text as an objective line with a prepending icon
function util.GameTooltip_AddObjectiveLine(tooltip, text, isCompleted, wrap, leftOffset, altDashIcon, altColor, isTrackingAchievement)
	if L:StringIsEmpty(text) then return end

	local defaultLeftOffset = leftOffset or 1
	if isCompleted then
		local checkMarkIcon = isTrackingAchievement and "common-icon-checkmark-yellow" or "common-icon-checkmark"
		local lineText = util.CreateInlineIcon(checkMarkIcon).." "..text  -- ITEM_NAME_DESCRIPTION_DELIMITER
		GameTooltip_AddDisabledLine(tooltip, lineText, wrap, defaultLeftOffset)
		return
	end
	local lineText = util.CreateInlineIcon(altDashIcon or 3083385).." "..text
	GameTooltip_AddColoredLine(tooltip, lineText, altColor or NORMAL_FONT_COLOR, wrap, defaultLeftOffset)
end


-- Insert a texture ID or atlas name into a font string.
---@param atlasNameOrTexID string|number
---@param sizeX number
---@param sizeY number
---@param xOffset number
---@param yOffset number
---@return string iconString
--
-- REF.: <FrameXML/TextureUtil.lua>  
-- REF.: <https://wowpedia.fandom.com/wiki/UI_escape_sequences#Textures>
--
function util.CreateInlineIcon(atlasNameOrTexID, sizeX, sizeY, xOffset, yOffset)
	sizeX = sizeX or 16;
	sizeY = sizeY or sizeX;
	xOffset = xOffset or 0;
	yOffset = yOffset or 0;  -- -1;

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

function util.CreateInlineIcon1(atlasNameOrTexID, sizeX, sizeY, xOffset, yOffset)
	return util.CreateInlineIcon(atlasNameOrTexID, sizeX, sizeY, xOffset, yOffset or -1);
end

function util.CreateInlineIcon2(atlasNameOrTexID, sizeX, sizeY, xOffset, yOffset)
	return util.CreateInlineIcon(atlasNameOrTexID, sizeX, sizeY, xOffset or 2, yOffset or -2);
end

--> REF.: <FrameXML/QuestUtils.lua>
local function IsWithinTimeThreshold(secondsRemaining, threshold)
	return secondsRemaining and secondsRemaining <= MinutesToSeconds(threshold) or false;
end

-- Return a color for given time based on world quest threshold.
---@param seconds number  The amount of seconds remaining
---@param normalColor table|nil  A color class (see <FrameXML/GlobalColors.lua>); defaults to NORMAL_FONT_COLOR.
---@param warningColor table|nil  A color class (see <FrameXML/GlobalColors.lua>)
---@param criticalColor table|nil  A color class (see <FrameXML/GlobalColors.lua>)
--
function util.GetTimeRemainingColorForSeconds(seconds, normalColor, warningColor, criticalColor)
	local color = NORMAL_FONT_COLOR;
	local normColor = normalColor or color;
	local warnColor = warningColor or WARNING_FONT_COLOR;
	local critColor = criticalColor or RED_FONT_COLOR;
	-- Overwrite normal color depending on the time remaining threshold
	color = IsWithinTimeThreshold(seconds, WORLD_QUESTS_TIME_LOW_MINUTES) and warnColor or normColor;  --> within 75 min.
	color = IsWithinTimeThreshold(seconds, WORLD_QUESTS_TIME_CRITICAL_MINUTES) and critColor or normColor;  --> within 15 min.
	return color;
end

-- Get the time remaining until the weekly reset as formatted time string.
---@return string timeString
--> REF.: <FrameXML/TimeUtil.lua> </br>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/DateAndTimeDocumentation.lua>
--
function util.GetTimeStringUntilWeeklyReset()
	local secondsLeft = C_DateAndTime.GetSecondsUntilWeeklyReset();
	local color = util.GetTimeRemainingColorForSeconds(secondsLeft, WHITE_FONT_COLOR);
	local abbreviationType = SecondsFormatter.Abbreviation.Truncate;
	local timeString = WorldQuestsSecondsFormatter:Format(secondsLeft, abbreviationType);
	return color:WrapTextInColorCode(timeString);
end

--------------------------------------------------------------------------------
----- Quest utilities ----------------------------------------------------------
--------------------------------------------------------------------------------
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/QuestTaskInfoDocumentation.lua>
-- REF.: <https://wowpedia.fandom.com/wiki/World_of_Warcraft_API#World_Quests>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/BountySharedDocumentation.lua>

-- A collection of quest related handler.
--> **Note:** Task Quests refer to World Quests or Bonus Objective quests. (see WoWpedia link above for more)
util.quest = {};

-- Gather all bounty world quests of given map.
---@param mapID number  A UiMapID of a location from the world map.
---@return BountyInfo[] bounties  A list of currently available bounties
--> REF.: <FrameXML/Blizzard_APIDocumentationGenerated/BountySharedDocumentation.lua><br/>
--
function util.quest.GetBountiesForMapID(mapID)
	return C_QuestLog.GetBountiesForMapID(mapID);
end

-- -- Check if access to World Quests in the Broken Isles (Legion) are unlocked.
-- ---@return boolean
-- --
-- function util.quest.AreBrokenIslesWorldQuestsUnlocked()						--> TODO - Keep ???
-- 	local UNITING_THE_ISLES_QUEST_ID = 43341;
-- 	return LocalQuestUtil.IsQuestFlaggedCompleted(UNITING_THE_ISLES_QUEST_ID);
-- end

-- **Note:** `QuestUtil` is a WoW global class.
local LocalQuestUtil = {};

-- Check whether given quest ID has been completed.
---@param questID number
---@return boolean isCompleted
--
function LocalQuestUtil.IsQuestFlaggedCompleted(questID)
	return C_QuestLog.IsQuestFlaggedCompleted(questID);
end

-- Check whether given world quest is currently available as an active quest.
---@param questID number  A world quest ID
---@return boolean isActive
--
function LocalQuestUtil.IsActiveWorldQuest(questID)
	return C_TaskQuest.IsActive(questID);
end

function LocalQuestUtil.GetQuestTimeLeftInfo(questID, secondsLeft)				--> TODO - Documentation
	-- REF.: <FrameXML/WorldMapFrame.lua>
	-- REF.: <FrameXML/GameTooltip.lua>
	-- REF.: <FrameXML/TimeUtil.lua>
	local seconds = secondsLeft or C_TaskQuest.GetQuestTimeLeftSeconds(questID);
	if (seconds and seconds > 0) then
		local timeLeftInfo = {};
		timeLeftInfo.seconds = seconds;
		timeLeftInfo.color = util.GetTimeRemainingColorForSeconds(seconds, WHITE_FONT_COLOR);
		local abbreviationType = SecondsFormatter.Abbreviation.Truncate;
		timeLeftInfo.timeString = WorldQuestsSecondsFormatter:Format(timeLeftInfo.seconds, abbreviationType);
		-- timeLeftInfo.timeString = SecondsToTime(timeLeftInfo.seconds);  --> deprecated
		timeLeftInfo.timeLeftString = BONUS_OBJECTIVE_TIME_LEFT:format(timeLeftInfo.timeString);
		timeLeftInfo.coloredTimeLeftString = timeLeftInfo.color:WrapTextInColorCode(timeLeftInfo.timeString);
		return timeLeftInfo;
	end
end

-- Gather basic info about given world quest.
---@param questID number  A world quest ID
---@return table questInfo
---@class questInfo
---@field title string  The title of the world quest
---@field factionID number  The faction for the world quest
---@field isCapped boolean  Is the quest flagged completed ???
---@field displayAsObjective boolean  Is quest available as objective ???
--
function LocalQuestUtil.GetWorldQuestInfoByQuestID(questID)
	local questTitle, factionID, capped, displayAsObjective = C_TaskQuest.GetQuestInfoByQuestID(questID);
	local questInfo = {
		["title"] = questTitle,
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
function LocalQuestUtil.GetWorldQuestZoneID(questID)
	return C_TaskQuest.GetQuestZoneID(questID);
end

--> REF.: <FrameXML/QuestUtils.lua>
--
function LocalQuestUtil.GetQuestName(questID)
	if not HaveQuestData(questID) then
		C_QuestLog.RequestLoadQuestByID(questID);
	end
	return QuestUtils_GetQuestName(questID);
end

--------------------------------------------------------------------------------
----- Achievement utilities ----------------------------------------------------
--------------------------------------------------------------------------------
-- REF.: <https://wowpedia.fandom.com/wiki/World_of_Warcraft_API#Achievements>

-- A collection of utility functions handling achievement details.
util.achieve = {};
local LocalAchievementUtil = {}

-- Achievements IDs
local INVASION_OBLITERATION_ID = 12026;  -- Legion Invasion Point Generals
local DEFENDER_OF_THE_BROKEN_ISLES_ID = 11544;
local FRONTLINE_WARRIOR_ALLIANCE_ASSAULTS_ID = 13283;  -- BfA Faction Assaults
local FRONTLINE_WARRIOR_HORDE_ASSAULTS_ID = 13284;  -- BfA Faction Assaults
local UNITED_FRONT_ID = 15000;  -- Shadowlands threat in The Maw 
local DEAD_MEN_TELL_SOME_TALES_ID = 15647;  -- Shadowlands Covenant Campaign
--> Note: The assetIDs returned for this achievement are always 0,
--  see util.covenant.UpdateData(...) for alternative solution.
local TEMPORAL_ACQUISITIONS_SPECIALIST_ID = 18554  -- Time Rifts

-- Pattern: {[areaPoi] = assetID, ...}
local AREA_POI_ASSET_MAP = {
	-- Legion Generals (Greater Invasion Points on Argus)
	["5375"] = 124625,  -- Mistress Alluradel
	["5376"] = 124492,  -- Occularus
	["5377"] = 124719,  -- Pit Lord Vilemus
	["5379"] = 124592,  -- Inquisitor Meto
	["5380"] = 124555,  -- Sotanathor
	["5381"] = 124514,  -- Matron Folnuna
	-- Legion: Defender of the Broken Isles
	["5175"] = 47193,  -- Azsuna
	["5177"] = 47194,  -- Highmountain
	["5178"] = 47195,  -- Stormheim
	["5210"] = 47196,  -- Val'sharahs
	-- BfA Faction Assaults {Horde, Alliance}
	["5896"] = {54314, 53711},  -- Tiragardesound
	["5964"] = {54319, 54318},  -- Drustvar
	["5966"] = {54316, 54317},  -- Stormsong Valley
	["5969"] = {54326, 54325},  -- Nazmir
	["5970"] = {54322, 54315},  -- Vol'dun
	["5973"] = {54323, 54324},  -- Zuldazar
	-- Shadowlands (threat in The Maw)
	["63543"] = 63543,  -- Necrolord Assault
	["63822"] = 63822,  -- Venthyr Assault
	["63823"] = 63823,  -- Night Fae Assault
	["63824"] = 63824,  -- Kyrian Assault
};

-- function Test_ListAchievementAssetIDs(achievementID)
-- 	local aID, aName = GetAchievementInfo(achievementID);
-- 	print(aID, aName);
-- 	local numCriteria = GetAchievementNumCriteria(achievementID);
-- 	for i=1, numCriteria do
-- 		local criteriaInfo = SafePack(GetAchievementCriteriaInfo(achievementID, i));
-- 		local cName, cType, isCompleted, criteriaAssetID, criteriaID = criteriaInfo[1], criteriaInfo[2], criteriaInfo[3], criteriaInfo[8], criteriaInfo[10];
-- 		print(i, criteriaAssetID, cType, criteriaID, "isCompleted:", isCompleted, "-->", cName);
-- 	end
-- end
-- --> REF.: <https://wow.tools/dbc/?dbc=criteria>
-- -- Test_ListAchievementAssetIDs(16462)

-- Check if given areaPoiID has an assetID for an achievement.
---@param areaPoiID number
---@return boolean isRelevant
--
function LocalAchievementUtil.IsRelevantAreaPOI(areaPoiID)
	local areaPoiIDstring = tostring(areaPoiID);
	return AREA_POI_ASSET_MAP[areaPoiIDstring] ~= nil;
end

-- Return the assetID for given areaPoiID.
---@param areaPoiID number
---@return number|table assetID
--
function LocalAchievementUtil.GetAreaPOIAssetID(areaPoiID)
	local areaPoiIDstring = tostring(areaPoiID);
	return AREA_POI_ASSET_MAP[areaPoiIDstring];
end

-- Check if the criteria of given assetID for given achievementID has been completed.
---@param achievementID number
---@param assetID number|table
---@return boolean isCompleted
-- 
--> REF.: <https://wowpedia.fandom.com/wiki/API_GetAchievementNumCriteria>  
--> REF.: <https://wowpedia.fandom.com/wiki/API_GetAchievementCriteriaInfo>  
--
function LocalAchievementUtil.IsAssetCriteriaCompleted(achievementID, assetID)
	local numCriteria = GetAchievementNumCriteria(achievementID);
	for i=1, numCriteria do
		-- Default return values:
		-- 1:criteriaString, 2:criteriaType, 3:completed, 4:quantity, 5:reqQuantity,
		-- 6:charName, 7:flags, 8:assetID, 9:quantityString, 10:criteriaID,
		-- 11:eligible, [12:duration], [13:elapsed]
		local criteriaInfo = SafePack(GetAchievementCriteriaInfo(achievementID, i));
		local isCompleted, criteriaAssetID = criteriaInfo[3], criteriaInfo[8];
		-- The assetID can be anything depending on the criteriaType, eg. a creatureID, questID, etc.
		if (criteriaAssetID == assetID) then
			return isCompleted;
		end
	end
	return false;
end

-- Add achievement relevant details in-place to given areaPoiInfo or threatInfo for given achievementID.
---@param achievementID number  The achievement identification number
---@param eventInfo table  A areaPoiInfo or threatInfo table
--
function LocalAchievementUtil.AddAchievementData(achievementID, eventInfo, index)
	local eventID = eventInfo.areaPoiID or eventInfo.questID;
	if LocalAchievementUtil.IsRelevantAreaPOI(eventID) then
		local assetInfo = LocalAchievementUtil.GetAreaPOIAssetID(eventID);
		local assetID = index and assetInfo[index] or assetInfo;
		local complete = LocalAchievementUtil.IsAssetCriteriaCompleted(achievementID, assetID);
		eventInfo.isCompleted = ns.settings.showAchievementTracking and complete or false;
	end
end

--------------------------------------------------------------------------------
----- World map utilities ------------------------------------------------------
--------------------------------------------------------------------------------
-- REF.: <FrameXML/Blizzard_WorldMap/Blizzard_WorldMapTemplates.lua>
-- REF.: <https://wowpedia.fandom.com/wiki/UI_escape_sequences>

-- A collection of map related functions.
util.map = {};

-- **Note:** Not to confuse with `MapUtil`, a WoW global class.
local LocalMapUtil = {};

-- Return informations about given map zone.
---@param mapID number  A UiMapID of a location from the world map.
---@return UiMapDetails table MapDocumentation.UiMapDetails
--
function LocalMapUtil.GetMapInfo(mapID)
	return C_Map.GetMapInfo(mapID);
end

-- Get the mapInfo of each child zone of given map.
---@param mapID number
---@param mapType number|Enum.UIMapType
---@param allDescendants boolean
---@return UiMapDetails[] table
--
function LocalMapUtil.GetMapChildrenInfo(mapID, mapType, allDescendants)
	return C_Map.GetMapChildrenInfo(mapID, mapType, allDescendants);
end

-- Returns a map area/subzone name.  
---@param areaID number
---@return string areaName
-- [Documentation](https://wowpedia.fandom.com/wiki/API_C_Map.GetAreaInfo),
-- [AreaTable.db2](https://wow.tools/dbc/?dbc=areatable)
--
function LocalMapUtil.GetAreaInfo(areaID)
	return C_Map.GetAreaInfo(areaID)
end

--------------------------------------------------------------------------------
----- Expansion utilities ------------------------------------------------------
--------------------------------------------------------------------------------
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/ExpansionDocumentation.lua>
-- REF.: <FrameXML/AccountUtil.lua>
-- RER.: <https://wowpedia.fandom.com/wiki/World_of_Warcraft_API#Expansions>

-- A collection of expansion related handler.
util.expansion = {};

-- Set most basic infos about each expansion.
--> **Note:** Expansions prior to Warlords Of Draenor are of no use to this add-on since
--  they don't have world quests nor a landing page for mission reports.
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
		["garrisonTypeID"] = Enum.GarrisonType.Type_6_0_Garrison,
		["continents"] = {572}  --> Draenor
		-- **Note:** No bounties in Draenor; only available since Legion.
	},
	["Legion"] = {
		["ID"] = LE_EXPANSION_LEGION,  -- 6
		["name"] = EXPANSION_NAME6,
		["garrisonTypeID"] = Enum.GarrisonType.Type_7_0_Garrison,
		["continents"] = {619, 905},  --> Broken Isles + Argus
	},
	["BattleForAzeroth"] = {
		["ID"] = LE_EXPANSION_BATTLE_FOR_AZEROTH,  -- 7
		["name"] = EXPANSION_NAME7,
		["garrisonTypeID"] = Enum.GarrisonType.Type_8_0_Garrison,
		["continents"] = {875, 876},  -- Zandalar, Kul Tiras
		["poiZones"] = {1355, 62, 14, 81},  -- Nazjatar, Darkshore, Arathi Highlands, Silithus
	},
	["Shadowlands"] = {
		["ID"] = LE_EXPANSION_SHADOWLANDS,  -- 8
		["name"] = EXPANSION_NAME8,
		["garrisonTypeID"] = Enum.GarrisonType.Type_9_0_Garrison,
		["continents"] = {1550},  --> Shadowlands
	},
	["Dragonflight"] = {
		["ID"] = LE_EXPANSION_DRAGONFLIGHT,  -- 9
		["name"] = EXPANSION_NAME9,
		["garrisonTypeID"] = Enum.ExpansionLandingPageType.Dragonflight,
		["continents"] = {1978},  --> Dragon Isles
	},
};

---Return the expansion data of given expansion ID.
---@param expansionID number  The expansion level 
---@return table ExpansionData
---
function util.expansion.GetExpansionData(expansionID)
	for _, expansion in pairs(util.expansion.data) do
		if (expansion.ID == expansionID) then
			return expansion;
		end
	end
	return {};																	--> TODO - Add default table for new expansions
end

---Return the expansion data of given expansion ID.
---@param garrisonTypeID number  A landing page garrison type ID
---@return table|nil ExpansionData
---
function util.expansion.GetExpansionDataByGarrisonType(garrisonTypeID)
	for _, expansion in pairs(util.expansion.data) do
		if (expansion.garrisonTypeID == garrisonTypeID) then
			return expansion;
		end
	end
	-- return {};
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

----- Expansion ID handler -----

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

----- Player level handler -----

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
function util.expansion.DoesPlayerOwnExpansion(expansionID)						--> TODO - Not good enough, refine this - Needed ???
	local maxLevelForExpansion = GetMaxLevelForExpansionLevel(expansionID);
	local maxLevelForCurrentExpansion = util.expansion.GetMaxPlayerLevel();
	local playerOwnsExpansion = maxLevelForExpansion <= maxLevelForCurrentExpansion;
	return playerOwnsExpansion;
end

--------------------------------------------------------------------------------
----- Garrison utilities -------------------------------------------------------
--------------------------------------------------------------------------------
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/GarrisonInfoDocumentation.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/GarrisonSharedDocumentation.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/GarrisonConstantsDocumentation.lua>
-- REF.: <FrameXML/GarrisonBaseUtils.lua>
-- REF.: <FrameXML/Blizzard_GarrisonUI/Blizzard_GarrisonMissionUI.lua>

-- A collection of garrison related helper functions; also used for backwards 
-- compatibility with often changing WoW globals
util.garrison = {};

-- -- Available follower types of each garrison landing page
-- util.garrison.GARRISON_FOLLOWER_TYPES = {
-- 	Enum.GarrisonFollowerType.FollowerType_6_0_GarrisonFollower,
-- 	Enum.GarrisonFollowerType.FollowerType_6_0_Boat,
-- 	Enum.GarrisonFollowerType.FollowerType_7_0_GarrisonFollower,
-- 	Enum.GarrisonFollowerType.FollowerType_8_0_GarrisonFollower,
-- 	Enum.GarrisonFollowerType.FollowerType_9_0_GarrisonFollower,
-- };

-- Check if given garrison type ID is unlocked.
---@param garrisonTypeID number  A landing page garrison type ID
---@return boolean hasGarrison
--
function util.garrison.HasGarrison(garrisonTypeID)
	return C_Garrison.HasGarrison(garrisonTypeID);
end

-- Check whether the garrison from Warlords of Draenor has invasions available.
---@return boolean isAvailable
--
function util.garrison.IsDraenorInvasionAvailable()
	return C_Garrison.IsInvasionAvailable();
end


-- function IsExpansionLandingPageUnlocked(garrisonTypeID)
-- 	local expansion = util.expansion.GetExpansionDataByGarrisonType(garrisonTypeID);
-- 	if (expansion and expansion.ID >= util.expansion.data.Dragonflight.ID)
-- 		return C_PlayerInfo.IsExpansionLandingPageUnlockedForPlayer(expansion.ID);
-- 	end
-- end
																				--> TODO - Needed ???
--> Check MRBP_COMMAND_TABLE_UNLOCK_QUESTS in core; need quest IDs for requirements.

----- Missions -----

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
			missions = C_Garrison.GetInProgressMissions(followerType);
			if missions then
				for i, mission in ipairs(missions) do
					if (mission.isComplete == nil) then
						-- Quick fix: the 'isComplete' attribute is sometimes nil even though the mission is finished.
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

----- Dragonflight -----

-- Check if the dragon riding feature in Dragonflight is unlocked.
---@return boolean isUnlocked
-- REF.: <FrameXML/Blizzard_ExpansionLandingPage/Blizzard_DragonflightLandingPage.lua>
-- REF.: <FrameXML/AchievementUtil.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/AchievementInfoDocumentation.lua>
-- REF.: <https://wowpedia.fandom.com/wiki/World_of_Warcraft_API#Achievements>
--
function util.garrison.IsDragonridingUnlocked()
	local DRAGONRIDING_ACCOUNT_ACHIEVEMENT_ID = 15794;
	local DRAGONRIDING_INTRO_QUEST_ID = 68798;
	local hasAccountAchievement = select(4, GetAchievementInfo(DRAGONRIDING_ACCOUNT_ACHIEVEMENT_ID));
	return hasAccountAchievement or LocalQuestUtil.IsQuestFlaggedCompleted(DRAGONRIDING_INTRO_QUEST_ID);
end

-- -- Create a string with the amount and icon of given currency info.
-- ---@param treeCurrencyInfo table  A TreeCurrencyInfo table
-- ---@param includeMaximum boolean|nil  Whether to include the maximal amount to the returned string or not
-- ---@return string currencyString
-- -- REF.: <FrameXML/Blizzard_SharedTalentUI/Blizzard_SharedTalentFrame.lua>
-- --
-- function util.garrison.CreateCurrencyString(treeCurrencyInfo, includeMaximum, iconWidth, iconOffsetX, iconOffsetY)
-- 	local flags, traitCurrencyType, currencyTypesID, overrideIcon = C_Traits.GetTraitCurrencyInfo(treeCurrencyInfo.traitCurrencyID);
-- 	local amountString = format("%2d", treeCurrencyInfo.quantity);
-- 	local width = iconWidth or 20;
-- 	local offsetX = iconOffsetX or 3;
-- 	local offsetY = iconOffsetY or 0;
-- 	local iconString = overrideIcon and util.CreateInlineIcon(overrideIcon, width, width, offsetX, offsetY) or '';
-- 	local currencyString = '';
-- 	if includeMaximum then
-- 		local maxCurrencyString = tostring(treeCurrencyInfo.maxQuantity);
-- 		currencyString = TALENT_FRAME_CURRENCY_FORMAT_WITH_MAXIMUM:format(amountString, maxCurrencyString, iconString);
-- 	else
-- 		currencyString = TALENT_FRAME_CURRENCY_FORMAT:format(amountString, iconString);
-- 	end

-- 	return currencyString;
-- end

-- Return details about the currency used in the DF dragon riding skill tree.
---@return TreeCurrencyInfo table  A TreeCurrencyInfo table + glyph texture ID
-- REF.: <FrameXML/Blizzard_GenericTraitUI/Blizzard_GenericTraitFrame.lua>
-- REF.: <FrameXML/Blizzard_SharedTalentUI/Blizzard_SharedTalentFrame.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/SharedTraitsDocumentation.lua>
--
function util.garrison.GetDragonRidingTreeCurrencyInfo()
	local DRAGON_RIDING_TRAIT_TREE_ID = 672;  -- GenericTraitFrame:GetTalentTreeID()
	local DRAGON_RIDING_TRAIT_CURRENCY_ID = 2563;
	local DRAGON_RIDING_TRAIT_CURRENCY_TEXTURE = 4728198;  -- glyph
	local DRAGON_RIDING_TRAIT_CONFIG_ID = C_Traits.GetConfigIDByTreeID(DRAGON_RIDING_TRAIT_TREE_ID);
	local excludeStagedChanges = true;
	local treeCurrencyFallbackInfo = {quantity=0, maxQuantity=0, spent=0, traitCurrencyID=DRAGON_RIDING_TRAIT_CURRENCY_ID};
	local treeCurrencyInfos = C_Traits.GetTreeCurrencyInfo(DRAGON_RIDING_TRAIT_CONFIG_ID, DRAGON_RIDING_TRAIT_TREE_ID, excludeStagedChanges);
	local treeCurrencyInfo = treeCurrencyInfos and treeCurrencyInfos[1] or treeCurrencyFallbackInfo;
	treeCurrencyInfo.texture = DRAGON_RIDING_TRAIT_CURRENCY_TEXTURE;

	return treeCurrencyInfo;
end

-- Count the available dragon glyphs of each zone in Dragonflight.
---@return table glyphsPerZone  {mapName = {numTotal, numComplete}, ...}
---@return integer numGlyphsCollected  The number of glyphs already collected
---@return integer numGlyphsTotal  The number of glyphs on the Dragon Isles altogether
--
function util.garrison.GetDragonGlyphsCount()
	local DRAGONRIDING_GLYPH_HUNTER_ACHIEVEMENTS = {
		{mapID = 2022, achievementID = 16575},  -- Waking Shores Glyph Hunter
		{mapID = 2023, achievementID = 16576},  -- Ohn'ahran Plains Glyph Hunter
		{mapID = 2024, achievementID = 16577},  -- Azure Span Glyph Hunter
		{mapID = 2025, achievementID = 16578},  -- Thaldraszus Glyph Hunter
		{mapID = 2151, achievementID = 17411},  -- Forbidden Reach Glyph Hunter
		{mapID = 2133, achievementID = 18150},  -- Zaralek Cavern Glyph Hunter
	};
	local glyphsPerZone = {};  -- Glyph count by map ID
	local numGlyphsTotal = 0;  -- The total number of glyphs from all zones
	local numGlyphsCollected = 0;  -- The number of collected glyphs from all zones
	for _, info in ipairs(DRAGONRIDING_GLYPH_HUNTER_ACHIEVEMENTS) do
		local numCriteria = GetAchievementNumCriteria(info.achievementID);
		local mapInfo = LocalMapUtil.GetMapInfo(info.mapID);
		local numComplete = 0;
		for i=1, numCriteria do
			local criteriaCompleted = select(3, GetAchievementCriteriaInfo(info.achievementID, i));
			if criteriaCompleted then
				numComplete = numComplete + 1;
			end
		end
		glyphsPerZone[mapInfo.name] = {};  -- The name of a zone
		glyphsPerZone[mapInfo.name].numTotal = numCriteria;  -- The total number of glyphs per zone
		glyphsPerZone[mapInfo.name].numComplete = numComplete;  -- The number of collected glyphs per zone
		numGlyphsTotal = numGlyphsTotal + numCriteria;
		numGlyphsCollected = numGlyphsCollected + numComplete;
	end

	return glyphsPerZone, numGlyphsCollected, numGlyphsTotal;
end

-- Retrieve the data for given major faction ID.
---@param factionID number  A major faction ID (since Dragonflight WoW 10.x)
---@return MajorFactionData table  For details see "MajorFactionData" fields below
--
function util.garrison.GetMajorFactionData(factionID)
	return C_MajorFactions.GetMajorFactionData(factionID);
end

-- Retrieve and sort the data for all major factions of given expansion.
-->REF.: <FrameXML/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua>  
-- REF.: <FrameXML/Blizzard_MajorFactions/Blizzard_MajorFactionRenown.lua>
--
function util.garrison.GetAllMajorFactionDataForExpansion(expansionID)
	local majorFactionData = {};
	local majorFactionIDs = C_MajorFactions.GetMajorFactionIDs(expansionID);
	for _, factionID in ipairs(majorFactionIDs) do
		tinsert(majorFactionData, util.garrison.GetMajorFactionData(factionID));
	end
	local sortFunc = function(a, b) return a.uiPriority < b.uiPriority end;  --> 0-9 (Fixed thanks to @justinkb.)
	table.sort(majorFactionData, sortFunc);

	return majorFactionData;
end

-- Build and return the icon of the given expansion's major faction.
---@param majorFactionData table  See 'util.garrison.GetMajorFactionData' doc string for details
---@return string majorFactionIcon
--
function util.garrison.GetMajorFactionInlineIcon(majorFactionData)
	if (majorFactionData.expansionID == util.expansion.data.Dragonflight.ID) then
		return util.CreateInlineIcon("MajorFactions_MapIcons_"..majorFactionData.textureKit.."64", 16, 16, 0, 0);
	end
	return '';
end

-- Build and return the color of the given major faction.
---@param majorFactionData any
---@return table majorFactionColor
--
function util.garrison.GetMajorFactionColor(majorFactionData, fallbackColor)
	local normalColor = fallbackColor or NORMAL_FONT_COLOR;
	if(majorFactionData.expansionID == util.expansion.data.Dragonflight.ID) then
		return _G[strupper(majorFactionData.textureKit).."_MAJOR_FACTION_COLOR"] or normalColor;
	end
	return normalColor;
end

-- Check if player has reached the maximum renown level for given major faction.
---@param currentFactionID number
---@return boolean hasMaxRenown
--
function util.garrison.HasMaximumMajorFactionRenown(currentFactionID)
	return C_MajorFactions.HasMaximumRenown(currentFactionID);
end

----- Shadowlands - Covenant utilities -----
--
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/CovenantsDocumentation.lua>
-- REF.: <FrameXML/Blizzard_CovenantRenown/Blizzard_CovenantRenown.lua>
-- REF.: <FrameXML/Blizzard_CovenantSanctum/Blizzard_CovenantSanctumUpgrades.lua>

-- A collection of utilities for the currently active Covenant in Shadowlands. 
util.covenant = {};

local LocalCovenantUtil = {};
LocalCovenantUtil.data = {};  -- used for updating on events
LocalCovenantUtil.atlasNameTemplate = "SanctumUpgrades-%s-32x32";
LocalCovenantUtil.covenantColors = {
	[Enum.CovenantType.Kyrian] = KYRIAN_BLUE_COLOR,
	[Enum.CovenantType.Venthyr] = VENTHYR_RED_COLOR,
	[Enum.CovenantType.NightFae] = NIGHT_FAE_BLUE_COLOR,
	[Enum.CovenantType.Necrolord] = NECROLORD_GREEN_COLOR,
};
LocalCovenantUtil.COVENANT_CAMPAIGN = {
	-- DEAD_MEN_TELL_SOME_TALES_ID  --> Note: returns no assetID; not usable with AREA_POI_ASSET_MAP.
	[Enum.CovenantType.Kyrian] = 62557,  --> "Our Realm Reclaimed"
	[Enum.CovenantType.Necrolord] = 62406,  --> "Staff of the Primus"
	[Enum.CovenantType.NightFae] = 60108,  --> "Drust and Ashes"
	[Enum.CovenantType.Venthyr] = 58407,  --> "The Medallion of Dominion"
};

function util.covenant.UpdateData(activeCovenantID)
	local covenantID = activeCovenantID or C_Covenants.GetActiveCovenantID();
	if (covenantID ~= util.covenant.ID) then
		local covenantData = C_Covenants.GetCovenantData(covenantID);
		if covenantData then
			local campaignQuestID = LocalCovenantUtil.COVENANT_CAMPAIGN[covenantData.ID];
			local complete = LocalQuestUtil.IsQuestFlaggedCompleted(campaignQuestID);
			LocalCovenantUtil.data = {
				ID = covenantData.ID,
				name = covenantData.name,
				atlasName = LocalCovenantUtil.atlasNameTemplate:format(covenantData.textureKit),
				color = LocalCovenantUtil.covenantColors[covenantData.ID],
				isCompleted = ns.settings.showAchievementTracking and complete or false;
			};
		end
	end
end

-- Get a custom table with covenant data.
---@param covenantID number
---@return table covenantInfo
---@class covenantInfo
---@field ID number
---@field name string
---@field atlasName string
---@field color table  A color class (see <FrameXML/GlobalColors.lua>)
--
function util.covenant.GetCovenantInfo(covenantID)
	util.covenant.UpdateData(covenantID);
	return LocalCovenantUtil.data;
end

-- Get a custom table with renown data of given covenant ID.
---@param covenantID number
---@return table|nil renownInfo
---@class renownInfo
---@field currentRenownLevel number
---@field hasMaximumRenown boolean
---@field maximumRenownLevel number
--
function util.covenant.GetRenownData(covenantID)
	local currentRenownLevel = C_CovenantSanctumUI.GetRenownLevel();
	if (currentRenownLevel >= 1) then
		local renownData = {
			currentRenownLevel = currentRenownLevel,
			hasMaximumRenown = C_CovenantSanctumUI.HasMaximumRenown(),
			maximumRenownLevel = #C_CovenantSanctumUI.GetRenownLevels(covenantID),
		};
		return renownData;
	end
end

--------------------------------------------------------------------------------
----- Threat utilities ---------------------------------------------------------
--------------------------------------------------------------------------------

-- A collection of utility functions handling world threats.
util.threats = {};

local LocalThreatUtil = {};

-- REF.: <FrameXML/SharedColorConstants.lua>
LocalThreatUtil.TYPE_COLORS = {
	-- ["5"] = YELLOW_FONT_COLOR,  						--> TODO - Add Garrison Invasions to threat list; currently only as chat info
	["6"] = INVASION_FONT_COLOR,  --> Legion Invasions
	["7"] = {
		["AllianceAssaultsMapBanner"] = PLAYER_FACTION_COLORS[1],
		["HordeAssaultsMapBanner"] = PLAYER_FACTION_COLORS[0],
		["1527"] = CORRUPTION_COLOR,   --> Uldum (N'Zoth Assaults)
		["1530"] = CORRUPTION_COLOR,   --> Vale of Eternal Blossoms (N'Zoth Assaults)
	},
	["8"] = {  --> Maw Covenant Assaults
		["63543"] = NECROLORD_GREEN_COLOR,
		["63822"] = VENTHYR_RED_COLOR,
		["63823"] = NIGHT_FAE_BLUE_COLOR,
		["63824"] = KYRIAN_BLUE_COLOR,
	},
};

-- Check whether there are any active world threats currently available.
---@return boolean hasActiveThreats
--
function LocalThreatUtil.HasActiveThreats()
	return C_QuestLog.HasActiveThreats();
end

-- Get the world quest IDs of all currently available world threats.
---@return number[] quests  An array of world quest IDs
--
function LocalThreatUtil.GetThreatQuests()
	return C_TaskQuest.GetThreatQuests();
end

-- Retrieve the faction color of given world threat.
---@param expansionID number  The expansion level number
---@param subCategoryID number  Either a questID or a mapID, depending whether it's a threat for Shadowlands or BfA
---@param fallbackColor table  A color class (see <FrameXML/GlobalColors.lua>); defaults to NORMAL_FONT_COLOR
---@return table factionColor  A color class (see <FrameXML/GlobalColors.lua>); defaults to NORMAL_FONT_COLOR
--
function LocalThreatUtil.GetExpansionThreatColor(expansionID, subCategoryID, fallbackColor)
	if expansionID > 0 then
		local colorTypeID = tostring(expansionID);
		local threatColor;
		if subCategoryID then
			local colorSubtypeID = tostring(subCategoryID);
			threatColor = LocalThreatUtil.TYPE_COLORS[colorTypeID][colorSubtypeID];
		else
			threatColor = LocalThreatUtil.TYPE_COLORS[colorTypeID];
		end
		return threatColor or fallbackColor or NORMAL_FONT_COLOR;
	end
	return fallbackColor or NORMAL_FONT_COLOR;
end

-- Find active threats in the world, if active for current player; eg. the
-- covenant attacks in The Maw or the N'Zoth's attacks in Battle for Azeroth.
---@return nil|activeThreatInfo[] activeThreats
---@class activeThreatInfo
---@field questID number
---@field questName string
---@field atlasName string
---@field factionID number
---@field mapInfo table
---@field timeLeftString string
--
function util.threats.GetActiveThreats()
	if LocalThreatUtil.HasActiveThreats() then
		local threatQuests = LocalThreatUtil.GetThreatQuests();
		local activeThreats = {};
		for i, questID in ipairs(threatQuests) do
			if LocalQuestUtil.IsActiveWorldQuest(questID) then
				local questInfo = LocalQuestUtil.GetWorldQuestInfoByQuestID(questID);
				local typeAtlas = QuestUtil.GetThreatPOIIcon(questID);
				local mapID = LocalQuestUtil.GetWorldQuestZoneID(questID);
				local mapInfo = LocalMapUtil.GetMapInfo(mapID);
				local timeLeftInfo = LocalQuestUtil.GetQuestTimeLeftInfo(questID);
				local timeLeftString = timeLeftInfo and timeLeftInfo.coloredTimeLeftString;
				local questExpansionLevel = GetQuestExpansion(questID);
				local isShadowlandsThreat = questExpansionLevel == util.expansion.data.Shadowlands.ID;
				-- print(questExpansionLevel, isShadowlandsThreat and questID or mapID);
				local threatColor = LocalThreatUtil.GetExpansionThreatColor(questExpansionLevel, isShadowlandsThreat and questID or mapID);
				if questExpansionLevel then
					_log:debug("Threat:", questID, questInfo.title, ">", mapID, mapInfo.name, "expLvl:", questExpansionLevel);
					if ( not activeThreats[questExpansionLevel] ) then
						-- Add table values per expansion IDs
						activeThreats[questExpansionLevel] = {};
					end
					local threatInfo = {
						questID = questID,
						questName = questInfo.title,
						atlasName = typeAtlas,
						factionID = questInfo.factionID,
					 	mapInfo = mapInfo,
						timeLeftString = timeLeftString,
						color = threatColor,
					};
					LocalAchievementUtil.AddAchievementData(UNITED_FRONT_ID, threatInfo);
					_log:debug("Adding threat:", questExpansionLevel, questID, questInfo.title);
					tinsert(activeThreats[questExpansionLevel], threatInfo);
				end
		    end
		end
		return activeThreats;
	end
end

--------------------------------------------------------------------------------
----- POI event handler --------------------------------------------------------
--------------------------------------------------------------------------------

-- A collection of utility functions for handling POI events from the world map.
util.poi = {};  --> used project-wide

local DRAGON_ISLES_MAP_ID = 1978;

-- Utility functions for handling custom AreaPOIInfo data structures.
local LocalPoiUtil = {};  --> used in this file only (!)

-- Compare given array of atlas names with that of the given POI info.
---@param atlasNames table
---@param poiInfo table
---@return table|nil poiInfo
--
function LocalPoiUtil.FilterPOIByAtlasName(atlasNames, poiInfo, ignorePrimaryMapForPOI)
	if tContains(atlasNames, poiInfo.atlasName) then
		-- if (not ignorePrimaryMapForPOI and poiInfo.isPrimaryMapForPOI) then
		if ignorePrimaryMapForPOI then
			return poiInfo;
		elseif poiInfo.isPrimaryMapForPOI then
			return poiInfo;
		end
	end
end

function LocalPoiUtil.FilterPOIByWidgetSetID(widgetSetID, poiInfo, ignorePrimaryMapForPOI)
	if (poiInfo.widgetSetID == widgetSetID) then
		if ignorePrimaryMapForPOI then
			return poiInfo;
		elseif poiInfo.isPrimaryMapForPOI then
			return poiInfo;
		end
	end
end

function LocalPoiUtil.DoesEventDataMatchAtlasName(eventData, poiInfo)
	local doesMatch = false;
	if eventData.atlasName then
		-- Single image file name
		doesMatch = eventData.atlasName == poiInfo.atlasName;
	end
	if eventData.atlasNames then
		-- A table of multiple image file names; POI must match with one of those
		doesMatch = tContains(eventData.atlasNames, poiInfo.atlasName);
	end
	if doesMatch then
		if eventData.ignorePrimaryMapForPOI then
			-- Needed for POI on maps without this attribute
			return poiInfo;
		elseif poiInfo.isPrimaryMapForPOI then
			return poiInfo;
		end
	end
end

function LocalPoiUtil.DoesEventDataMatchWidgetSetID(eventData, poiInfo)
	local doesMatch = false;
	if eventData.widgetSetID then
		doesMatch = poiInfo.widgetSetID == eventData.widgetSetID;
	end
	if eventData.widgetSetIDs then
		doesMatch = tContains(eventData.widgetSetIDs, poiInfo.widgetSetID);
	end
	if doesMatch then
		if eventData.ignorePrimaryMapForPOI then
			-- Needed for POI on maps without this attribute
			return poiInfo;
		elseif poiInfo.isPrimaryMapForPOI then
			return poiInfo;
		end
	end
end

function LocalPoiUtil.DoesEventDataMatchAreaPoiID(eventData, poiInfo)
	local doesMatch = false;
	if eventData.areaPoiID then
		doesMatch = poiInfo.areaPoiID == eventData.areaPoiID;
	end
	if eventData.areaPoiIDs then
		doesMatch = tContains(eventData.areaPoiIDs, poiInfo.areaPoiID);
	end
	if doesMatch then
		if eventData.ignorePrimaryMapForPOI then
			-- Needed for POI on maps without this attribute
			return poiInfo;
		elseif poiInfo.isPrimaryMapForPOI then
			return poiInfo;
		end
	end
end

-- Comparison function: sort a list of custom POI by map ID in *ascending* order.
function LocalPoiUtil.SortMapIDsAscending(a, b)
	return a.mapInfo.mapID < b.mapInfo.mapID;  --> 0-9
end

-- Comparison function: sort a list of custom POI by areaPoiID in *ascending* order.
function LocalPoiUtil.SortPoiIDsAscending(a, b)
	return a.areaPoiID < b.areaPoiID;  --> 0-9
end

LocalPoiUtil.SingleArea = {};

-- Scan a single zone and return the world map POI for given event data table.
---@param eventData table  A custom table with data for a specific world map event.
---@return table|nil areaPoiInfo
--
function LocalPoiUtil.SingleArea.GetAreaPoiInfo(eventData)
	local activeAreaPOIs = LocalMapUtil.GetAreaPOIForMapInfo(eventData.mapInfo, eventData.includeAreaName);
	if (activeAreaPOIs and #activeAreaPOIs > 0) then
		for _, poiInfo in ipairs(activeAreaPOIs) do
			if eventData.CompareFunction(eventData, poiInfo) then
				return poiInfo;
			end
		end
	end
end

function LocalPoiUtil.SingleArea.GetMultipleAreaPoiInfos(eventData, ignoreSorting)
	local events = {};
	local activeAreaPOIs = LocalMapUtil.GetAreaPOIForMapInfo(eventData.mapInfo, eventData.includeAreaName);
	if (activeAreaPOIs and #activeAreaPOIs > 0) then
		for _, poiInfo in ipairs(activeAreaPOIs) do
			if eventData.CompareFunction(eventData, poiInfo) then
				tinsert(events, poiInfo);
			end
		end
	end
	if not ignoreSorting then
		table.sort(events, eventData.SortingFunction);
	end
	return events;
end

LocalPoiUtil.MultipleAreas = {};

-- Scan multiple zones and return a single world map POI for given event data table.
---@param eventData table
---@return table|nil areaPoiInfo
--
function LocalPoiUtil.MultipleAreas.GetAreaPoiInfo(eventData)
	for _, mapInfo in ipairs(eventData.mapInfos) do
		local activeAreaPOIs = LocalMapUtil.GetAreaPOIForMapInfo(mapInfo, eventData.includeAreaName);
		if (activeAreaPOIs and #activeAreaPOIs > 0) then
			for _, poiInfo in ipairs(activeAreaPOIs) do
				if eventData.CompareFunction(eventData, poiInfo) then
					return poiInfo;
				end
			end
		end
	end
end

function LocalPoiUtil.MultipleAreas.GetMultipleAreaPoiInfos(eventData)
	local events = {};
	local ignoreSorting = true;  -- ignore sorting for each zone; sort all below instead
	for _, mapInfo in ipairs (eventData.mapInfos) do
		-- Set map info for each child zone
		eventData.mapInfo = mapInfo;
		local childEvents = LocalPoiUtil.SingleArea.GetMultipleAreaPoiInfos(eventData, ignoreSorting);
		if util.TableHasAnyEntries(childEvents) then
			tAppendAll(events, childEvents);
		end
	end
	table.sort(events, eventData.SortingFunction);
	return events;
end

----- Dragonriding Race -----

local DragonRidingRaceData = {};
DragonRidingRaceData.atlasName = "racing";
DragonRidingRaceData.mapID = DRAGON_ISLES_MAP_ID;
DragonRidingRaceData.mapInfos = LocalMapUtil.GetMapChildrenInfo(DragonRidingRaceData.mapID, Enum.UIMapType.Zone);
DragonRidingRaceData.CompareFunction = LocalPoiUtil.DoesEventDataMatchAtlasName;
DragonRidingRaceData.includeAreaName = true;

function util.poi.GetDragonridingRaceInfo()
	return LocalPoiUtil.MultipleAreas.GetAreaPoiInfo(DragonRidingRaceData);
end

----- Camp Aylaag -----

local CampAylaagData = {};
CampAylaagData.widgetSetIDs = {718, 719, 720};
CampAylaagData.mapID = 2023;  --> Ohn'ahra
CampAylaagData.mapInfo = LocalMapUtil.GetMapInfo(CampAylaagData.mapID);
CampAylaagData.CompareFunction = LocalPoiUtil.DoesEventDataMatchWidgetSetID;
-- CampAylaagData.includeAreaName = true;
CampAylaagData.areaIDsMap = {
	["7101"] = nil,    -- River Camp (east), no areaID found
	["7102"] = 13747,  -- Aylaag Outpost
	["7103"] = 14463,  -- Eaglewatch Outpost, Ohn'ahra
}																				--> TODO - The Ohn'ahran Trail (achievement=16462)

function util.poi.GetCampAylaagInfo()
	local poiInfo = LocalPoiUtil.SingleArea.GetAreaPoiInfo(CampAylaagData)
	if poiInfo then
		data:SaveLabel("showCampAylaagInfo", poiInfo.name)
		local areaID = CampAylaagData.areaIDsMap[tostring(poiInfo.areaPoiID)]
		if (poiInfo.areaPoiID == 7101) then
			poiInfo.areaName = L.ENTRYTOOLTIP_DF_CAMP_AYLAAG_AREA_NAME
		else
			poiInfo.areaName = areaID and LocalMapUtil.GetAreaInfo(areaID) or poiInfo.areaName
		end
		return poiInfo
	end
end

----- Grand Hunts -----

local GrandHuntsData = {};
GrandHuntsData.widgetSetID = 712;
GrandHuntsData.mapID = DRAGON_ISLES_MAP_ID;
GrandHuntsData.mapInfo = LocalMapUtil.GetMapInfo(GrandHuntsData.mapID);
GrandHuntsData.CompareFunction = LocalPoiUtil.DoesEventDataMatchWidgetSetID;
GrandHuntsData.ignorePrimaryMapForPOI = true;

function util.poi.GetGrandHuntsInfo()
	local poiInfo = LocalPoiUtil.SingleArea.GetAreaPoiInfo(GrandHuntsData)
	if poiInfo then
		data:SaveLabel("showGrandHuntsInfo", poiInfo.name)
		return poiInfo
	end
end

----- Iskaara Community Feast -----

-- local CommunityFeastData = {};
-- CommunityFeastData.areaPoiIDs = {7218, 7219, 7220, 7393};
-- CommunityFeastData.mapID = 2024;  --> Azure Span
-- CommunityFeastData.mapInfo = LocalMapUtil.GetMapInfo(CommunityFeastData.mapID);
-- CommunityFeastData.CompareFunction = LocalPoiUtil.DoesEventDataMatchAreaPoiID;

-- function util.poi.GetCommunityFeastInfo()
-- 	return LocalPoiUtil.SingleArea.GetAreaPoiInfo(CommunityFeastData);
-- end
-- -- Test_GetCommunityFeastInfo = util.poi.GetCommunityFeastInfo;

----- Siege on Dragonbane Keep event -----

local DragonbaneKeepData = {};
DragonbaneKeepData.widgetSetID = 713;
DragonbaneKeepData.mapID = 2022;  --> Waken Shores
DragonbaneKeepData.mapInfo = LocalMapUtil.GetMapInfo(DragonbaneKeepData.mapID);
DragonbaneKeepData.CompareFunction = LocalPoiUtil.DoesEventDataMatchWidgetSetID;

function util.poi.GetDragonbaneKeepInfo()
	local poiInfo = LocalPoiUtil.SingleArea.GetAreaPoiInfo(DragonbaneKeepData)
	if poiInfo then
		data:SaveLabel("showDragonbaneKeepInfo", poiInfo.name)
		return poiInfo
	end
end

----- Elemental Storms event -----

local ElementalStormData = {};
ElementalStormData.atlasNames = {
	"ElementalStorm-Lesser-Air",
	"ElementalStorm-Lesser-Earth",
	"ElementalStorm-Lesser-Fire",
	"ElementalStorm-Lesser-Water",
	"ElementalStorm-Boss-Air",
	"ElementalStorm-Boss-Earth",
	"ElementalStorm-Boss-Fire",
	"ElementalStorm-Boss-Water",
};
ElementalStormData.mapID = DRAGON_ISLES_MAP_ID;
ElementalStormData.mapInfos = LocalMapUtil.GetMapChildrenInfo(ElementalStormData.mapID, Enum.UIMapType.Zone);
ElementalStormData.CompareFunction = LocalPoiUtil.DoesEventDataMatchAtlasName;
ElementalStormData.SortingFunction = LocalPoiUtil.SortMapIDsAscending;
ElementalStormData.includeAreaName = true;

function util.poi.GetElementalStormsInfo()
	local poiInfos = LocalPoiUtil.MultipleAreas.GetMultipleAreaPoiInfos(ElementalStormData)
	if poiInfos and poiInfos[1] then
		data:SaveLabel("showElementalStormsInfo", poiInfos[1].name)
	end
	return poiInfos
end

----- Fyrakk Assaults -----

local FyrakkAssaultsData = {};
FyrakkAssaultsData.widgetSetIDs = {779, 780};
FyrakkAssaultsData.mapID = DRAGON_ISLES_MAP_ID;
FyrakkAssaultsData.mapInfos = LocalMapUtil.GetMapChildrenInfo(FyrakkAssaultsData.mapID, Enum.UIMapType.Zone);
FyrakkAssaultsData.CompareFunction = LocalPoiUtil.DoesEventDataMatchWidgetSetID;

function util.poi.GetFyrakkAssaultsInfo()
	local poiInfo = LocalPoiUtil.MultipleAreas.GetAreaPoiInfo(FyrakkAssaultsData)
	if poiInfo then
		data:SaveLabel("showFyrakkAssaultsInfo", poiInfo.name)
		return poiInfo
	end
end

----- Researchers Under Fire -----

local ResearchersUnderFireData = {};
ResearchersUnderFireData.widgetSetID = 807;
ResearchersUnderFireData.mapID = 2133;
ResearchersUnderFireData.mapInfo = LocalMapUtil.GetMapInfo(ResearchersUnderFireData.mapID);
ResearchersUnderFireData.CompareFunction = LocalPoiUtil.DoesEventDataMatchWidgetSetID;
ResearchersUnderFireData.ignorePrimaryMapForPOI = true;
ResearchersUnderFireData.includeAreaName = true;

function util.poi.GetResearchersUnderFireDataInfo()
	local poiInfo = LocalPoiUtil.SingleArea.GetAreaPoiInfo(ResearchersUnderFireData)
	if poiInfo then
		data:SaveLabel("showResearchersUnderFireInfo", poiInfo.name)
		return poiInfo
	end
end

----- Time Rifts -----

local TimeRiftData = {}
TimeRiftData.widgetSetID = 845
TimeRiftData.mapID = 2025  -- Thaldraszus
TimeRiftData.mapInfo = LocalMapUtil.GetMapInfo(TimeRiftData.mapID)
TimeRiftData.CompareFunction = LocalPoiUtil.DoesEventDataMatchWidgetSetID
TimeRiftData.GetTimeLeft = function()
	-- The event starts every hour and lasts for 15 minutes
	local gameTimeHour, gameTimeMinutes = GetLocalGameTime()
	local isActive = gameTimeMinutes <= 15
	local minutesLeft = isActive and (15 - gameTimeMinutes) or (60 - gameTimeMinutes)
	if (minutesLeft >= 0) then
		local timeLeftInfo = LocalQuestUtil.GetQuestTimeLeftInfo(nil, MinutesToSeconds(minutesLeft))
		local timeLeftString = timeLeftInfo and timeLeftInfo.coloredTimeLeftString
		return timeLeftString, isActive
	end
end
TimeRiftData.includeAreaName = true

function util.poi.GetTimeRiftInfo()
	local poiInfo = LocalPoiUtil.SingleArea.GetAreaPoiInfo(TimeRiftData)
	if poiInfo then
		data:SaveLabel("showTimeRiftInfo", poiInfo.name)
		if not poiInfo.isTimed then
			local timeLeftString, isActive = TimeRiftData.GetTimeLeft()
			if timeLeftString then
				local activeTimeLeftString = timeLeftString.." "..GREEN_FONT_COLOR:WrapTextInColorCode(SPEC_ACTIVE)
				poiInfo.timeString = isActive and activeTimeLeftString or timeLeftString
				poiInfo.isTimed = true
			end
		end
		return poiInfo
	end
end

----- Battle for Azeroth: Faction Assaults -----

local BfAFactionAssaultsData = {};
BfAFactionAssaultsData.atlasNames = {"AllianceAssaultsMapBanner", "HordeAssaultsMapBanner"};
BfAFactionAssaultsData.mapInfos = {LocalMapUtil.GetMapInfo(875),  LocalMapUtil.GetMapInfo(876)};  --> Zandalar, Kul Tiras
BfAFactionAssaultsData.CompareFunction = LocalPoiUtil.DoesEventDataMatchAtlasName;
BfAFactionAssaultsData.ignorePrimaryMapForPOI = true;
local expansionIDstringBfA = tostring(util.expansion.data.BattleForAzeroth.ID);
local playerFactionGroup = UnitFactionGroup("player");  --> Needed to index: {1:Horde, 2:Alliance}
BfAFactionAssaultsData.playerFactionIndex = playerFactionGroup == 'Horde' and 1 or 2;
BfAFactionAssaultsData.achievementIDs = {FRONTLINE_WARRIOR_HORDE_ASSAULTS_ID, FRONTLINE_WARRIOR_ALLIANCE_ASSAULTS_ID};

function util.poi.GetBfAFactionAssaultsInfo()
	local poiInfo = LocalPoiUtil.MultipleAreas.GetAreaPoiInfo(BfAFactionAssaultsData);
	if poiInfo then
		poiInfo.parentMapInfo = LocalMapUtil.GetMapInfo(poiInfo.mapInfo.parentMapID);
		poiInfo.color = LocalThreatUtil.TYPE_COLORS[expansionIDstringBfA][poiInfo.atlasName];
		local achievementID = BfAFactionAssaultsData.achievementIDs[BfAFactionAssaultsData.playerFactionIndex];
		LocalAchievementUtil.AddAchievementData(achievementID, poiInfo, BfAFactionAssaultsData.playerFactionIndex);
		return poiInfo;
	end
end

--- BfA: Island Expeditions ---

function util.poi.GetBfAIslandExpeditionInfo()
	local islandExpeditionsQuestID = C_IslandsQueue.GetIslandsWeeklyQuestID();   --> 53435
	local numObjectives = C_QuestLog.GetNumQuestObjectives(islandExpeditionsQuestID);  --> 1
	local displayAsCompleted = false;
	local text, objectiveType, isFinished, numFulfilled, numRequired = GetQuestObjectiveInfo(islandExpeditionsQuestID, numObjectives, displayAsCompleted);
	local fulfilledPercentage = (numFulfilled / numRequired) * 100;  --> eg. (30224/36000)*100 = 83,95
	local data = {
		name = QuestUtils_GetQuestName(islandExpeditionsQuestID),  --> "Azerit für die Horde"
		atlasName = "poi-islands-table",
		isFinished = isFinished,
		fulfilledPercentageString = PERCENTAGE_STRING:format(fulfilledPercentage),  --> eg. '83 %'
		progressText = ISLANDS_QUEUE_WEEKLY_QUEST_PROGRESS:format(numFulfilled, numRequired),  --> "%d/%d Azerite";
	};

	return data;
end

----- Legion: Legion Assaults (Legion Invasion on The Broken Isles) -----

local LegionAssaultsData = {};
LegionAssaultsData.atlasName = "legioninvasion-map-icon-portal";
LegionAssaultsData.mapID =  619;  --> Broken Isles
LegionAssaultsData.mapInfo = LocalMapUtil.GetMapInfo(LegionAssaultsData.mapID);
LegionAssaultsData.ignorePrimaryMapForPOI = true;
LegionAssaultsData.CompareFunction = LocalPoiUtil.DoesEventDataMatchAtlasName;
LegionAssaultsData.achievementID = DEFENDER_OF_THE_BROKEN_ISLES_ID;

function util.poi.GetLegionAssaultsInfo()
	local poiInfo = LocalPoiUtil.SingleArea.GetAreaPoiInfo(LegionAssaultsData);
	if poiInfo then
		data:SaveLabel("showLegionAssaultsInfo", poiInfo.name)
		poiInfo.parentMapInfo = LocalMapUtil.GetMapInfo(poiInfo.mapInfo.parentMapID);
		poiInfo.color = LocalThreatUtil.TYPE_COLORS[tostring(util.expansion.data.Legion.ID)];
		LocalAchievementUtil.AddAchievementData(LegionAssaultsData.achievementID, poiInfo);
		return poiInfo;
	end
end

----- Legion: Broken Shore Invasion (Demon Invasions) -----

local BrokenShoreInvasionData = {};
BrokenShoreInvasionData.atlasNames = {"DemonInvasion5", "DemonShip", "DemonShip_East"};
BrokenShoreInvasionData.mapID = 646;
BrokenShoreInvasionData.mapInfo = LocalMapUtil.GetMapInfo(BrokenShoreInvasionData.mapID);
BrokenShoreInvasionData.ignorePrimaryMapForPOI = true;
BrokenShoreInvasionData.CompareFunction = LocalPoiUtil.DoesEventDataMatchAtlasName;
BrokenShoreInvasionData.SortingFunction = LocalPoiUtil.SortPoiIDsAscending;

function util.poi.GetBrokenShoreInvasionInfo()
	local poiInfo = LocalPoiUtil.SingleArea.GetMultipleAreaPoiInfos(BrokenShoreInvasionData)
	if poiInfo then
		poiInfo.color = LocalThreatUtil.TYPE_COLORS[tostring(util.expansion.data.Legion.ID)]
		local areaName = BrokenShoreInvasionData.mapInfo.name
		data:SaveLabel("showBrokenShoreInvasionInfo", areaName..HEADER_COLON.." "..SPLASH_LEGION_PREPATCH_FEATURE1_TITLE)
		return poiInfo
	end
end

----- Legion: Argus Invasion (Invasion Points) -----

local ArgusInvasionData = {};
ArgusInvasionData.atlasNames = {"poi-rift1", "poi-rift2"};
ArgusInvasionData.continentMapID = 905;
ArgusInvasionData.continentMapInfo = LocalMapUtil.GetMapInfo(ArgusInvasionData.continentMapID);
ArgusInvasionData.mapInfos = LocalMapUtil.GetMapChildrenInfo(ArgusInvasionData.continentMapID);
ArgusInvasionData.CompareFunction = LocalPoiUtil.DoesEventDataMatchAtlasName;
ArgusInvasionData.SortingFunction = LocalPoiUtil.SortPoiIDsAscending;
ArgusInvasionData.achievementID = INVASION_OBLITERATION_ID;  -- Invasion Point Generals

function util.poi.GetArgusInvasionPointsInfo()
	local poiInfoTable = LocalPoiUtil.MultipleAreas.GetMultipleAreaPoiInfos(ArgusInvasionData);
	if util.TableHasAnyEntries(poiInfoTable) then
		for _, poiInfo in ipairs(poiInfoTable) do
			poiInfo.color = LocalThreatUtil.TYPE_COLORS[tostring(util.expansion.data.Legion.ID)];
			LocalAchievementUtil.AddAchievementData(ArgusInvasionData.achievementID, poiInfo);
		end
		local areaName = ArgusInvasionData.continentMapInfo.name
		data:SaveLabel("showArgusInvasionInfo",  areaName..HEADER_COLON.." "..poiInfoTable[1].name)
		return poiInfoTable
	end
end

local GreaterInvasionPointData = {};
GreaterInvasionPointData.atlasName = "poi-rift2";
GreaterInvasionPointData.continentMapID = 905;
GreaterInvasionPointData.mapInfos = LocalMapUtil.GetMapChildrenInfo(GreaterInvasionPointData.continentMapID);
GreaterInvasionPointData.CompareFunction = LocalPoiUtil.DoesEventDataMatchAtlasName;
GreaterInvasionPointData.achievementID = INVASION_OBLITERATION_ID;  -- Invasion Point Generals

function util.poi.GetGreaterInvasionPointDataInfo()
	local poiInfo = LocalPoiUtil.MultipleAreas.GetAreaPoiInfo(GreaterInvasionPointData);
	if poiInfo then
		poiInfo.color = LocalThreatUtil.TYPE_COLORS[tostring(util.expansion.data.Legion.ID)];
		LocalAchievementUtil.AddAchievementData(GreaterInvasionPointData.achievementID, poiInfo);
		return poiInfo;
	end
end

----- Timewalking Vendor -----

-- function Test_GetTimewalkingInfo()											    --> TODO - Add other expansions
-- 	local TIMEWALKING_SPELL_IDs = {
-- 		335152,  -- Sign of Iron (Warlords of Draenor)
-- 		359082,  -- Sign of the Legion
-- 	};
-- 	for _, spellID in ipairs(TIMEWALKING_SPELL_IDs) do
-- 		local auraInfo = C_UnitAuras.GetPlayerAuraBySpellID(spellID);  --> returns only active buffs
-- 		if auraInfo then
-- 			-- Add description; is by default not available in auraInfo
-- 			auraInfo.description = GetSpellDescription(spellID);
-- 			return auraInfo;
-- 		end
-- 	end
-- end

local TimewalkingVendorData = {};
TimewalkingVendorData.atlasName = "TimewalkingVendor-32x32";
TimewalkingVendorData.mapInfos = {LocalMapUtil.GetMapInfo(588), LocalMapUtil.GetMapInfo(627)}  -- , LocalMapUtil.GetMapInfo(85)};
-- TimewalkingVendorData.CompareFunction = LocalPoiUtil.DoesEventDataMatchAtlasName;
TimewalkingVendorData.areaPoiIDs = {6985, 7018};  --> Draenor, Legion
TimewalkingVendorData.CompareFunction = LocalPoiUtil.DoesEventDataMatchAreaPoiID;

function util.poi.FindTimewalkingVendor(expansionInfo)
	local poiInfo = LocalPoiUtil.MultipleAreas.GetAreaPoiInfo(TimewalkingVendorData);
	if poiInfo then
		poiInfo.timeString = util.GetTimeStringUntilWeeklyReset();
		if (expansionInfo.ID == util.expansion.data.WarlordsOfDraenor.ID and poiInfo.areaPoiID == 6985) then  -- and poiInfo.mapInfo.mapID == 588
			return poiInfo
		end
		if (expansionInfo.ID == util.expansion.data.Legion.ID and poiInfo.areaPoiID == 7018) then  -- and poiInfo.mapInfo.mapID == 627
			return poiInfo
		end
	end
end

--------------------------------------------------------------------------------

local PoiFilter = {};

-- Name patterns for non-relevant world map POIs; not every POI is an event.
PoiFilter.ignoredZoneAtlasNamePatterns = {
	"^taxinode.*",
	"^flightmaster.*",
	"^vignettekill.*",
	"^vignetteloot.*",
	"^warlockportal.*",
	"^groupfinder.*",
	-- "^groupfinder[-]icon[-]class[-].*",
	"map[-]icon[-].*classhall",
	"^Zidormi.*",
	"^poi[-]torghast",
	-- "^fishing[-]hole",
};

-- Check if given atlas name should be ignored.
---@param atlasName string
---@return boolean shouldIgnore
--
function PoiFilter.ShouldIgnoreAtlasName(atlasName)
	for _, pattern in pairs(PoiFilter.ignoredZoneAtlasNamePatterns) do
		if strmatch(atlasName, pattern) then
			return true;
		end
	end
	return false;
end

-- Area POI IDs which have been already handled, or are non-relevant or which are without an icon (atlasName)
PoiFilter.ignoredAreaPoiIDs = {
	-- Dragonflight
	"7089",  -- Grand Hunting Party (doubles from other zones)
	"7090",  -- Grand Hunting Party (doubles from other zones)
	"7091",  -- Grand Hunting Party (doubles from other zones)
	"7092",  -- Grand Hunting Party (doubles from other zones)
	"7093",  -- Grand Hunting Party (doubles from other zones)
	"7097",  -- Grand Hunting Party (double: Ohn'ahra, Thaldraszus)
	"7099",  -- Grand Hunting Party (double: Ohn'ahra, Thaldraszus)
	"7053",  -- Grand Hunting Party (double: Ohn'ahra, Thaldraszus)
	"7365",  -- Dragonscale Basecamp
	"7391",  -- The Seat of the Aspects
	"7392",  -- Maruukai
	"7393",  -- Iskaara
	"7394",  -- Obsidian Citadel + Dragonbane Keep
	"7414",  -- Zskera Vaults
	"7408",  -- Primal Storm at Froststone Vault - Forbidden Reach
	"7489",  -- Loamm
	"7086",  -- Fishing Hole, Waken Shore
	"7266",  -- Fishing Hole, Azure Span
	"7270",  -- Fishing Hole, Ohn'ahran Plains
	"7271",  -- Fishing Hole, Thaldraszus
	"7272",  -- Fishing Hole, Waken Shore
	"7412",  -- Fishing Hole, Forbidden Isle
	-- Shadowlands
	-- "6640",  -- Torghast, The Maw
	"6991",  -- Kyrian Assault, The Maw (covered as threat)
	"6992",  -- Night Fae Assault, The Maw (covered as threat)
	"6989",  -- Necrolord Assault, The Maw (covered as threat)
	"6990",  -- Venthyr Assault, The Maw (covered as threat)
	-- Battle for Azeroth
	"6548",  -- Zidormi, Uldum
	"5760",  -- Zidormi, Darkshore
	"5561",  -- Zidormi, Silithus
	"5989",  -- Zidormi, Arathi Highlands
	-- Warlords of Draenor
	"4183",  -- Elixir of Shadow Sight
	"4184",  -- Elixir of Shadow Sight
	"4185",  -- Elixir of Shadow Sight
	"4186",  -- Elixir of Shadow Sight
	"4187",  -- Elixir of Shadow Sight
	"4188",  -- Elixir of Shadow Sight
	"4586",  -- Ashran Quartermaster (PvP, Alliance)
	"4587",  -- Ashran Quartermaster (PvP, Horde)
};

function PoiFilter.ShouldIgnoreAreaPOI(poiInfo)
	local ignoreAtlas = poiInfo.atlasName and PoiFilter.ShouldIgnoreAtlasName(strlower(poiInfo.atlasName)) or false;
	local ignorePOI = tContains(PoiFilter.ignoredAreaPoiIDs, tostring(poiInfo.areaPoiID));
	return ignoreAtlas or ignorePOI;
end

-- Returns a table with POI IDs currently active on the world map.
---@param mapID number
---@return number[] areaPoiIDs
-- REF.: <FrameXML/Blizzard_SharedMapDataProviders/AreaPOIDataProvider.lua>
-- REF.: <FrameXML/Blizzard_SharedMapDataProviders/SharedMapPoiTemplates.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/AreaPoiInfoDocumentation.lua>
-- REF.: <FrameXML/TableUtil.lua>
--
function LocalMapUtil.GetAreaPOIForMap(mapID)
	local areaPOIs = GetAreaPOIsForPlayerByMapIDCached(mapID);
	areaPOIs = TableIsEmpty(areaPOIs) and C_AreaPoiInfo.GetAreaPOIForMap(mapID) or areaPOIs;
	return areaPOIs;
end

-- Main POI retrieval function; Gets all POIs of given map info.
---@param mapInfo table|UiMapDetails
---@param includeAreaName boolean|nil
---@return AreaPOIInfo[]|nil activeAreaPOIs
---@class AreaPOIInfo
--
function LocalMapUtil.GetAreaPOIForMapInfo(mapInfo, includeAreaName)
	local areaPOIs = LocalMapUtil.GetAreaPOIForMap(mapInfo.mapID);
	if (areaPOIs and #areaPOIs > 0) then
		local activeAreaPOIs = {};
		for i, areaPoiID in ipairs(areaPOIs) do
			local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapInfo.mapID, areaPoiID);
			if not poiInfo then
				ClearCachedAreaPOIsForPlayer();
				break;
			end
			if not PoiFilter.ShouldIgnoreAreaPOI(poiInfo) then
				-- Add more details about this POI
				poiInfo.isTimed = C_AreaPoiInfo.IsAreaPOITimed(areaPoiID);
				if poiInfo.isTimed then
					poiInfo.secondsLeft = C_AreaPoiInfo.GetAreaPOISecondsLeft(areaPoiID);
					-- Note: Even if the POI event is timed, the seconds left won't load sometimes, probably due to
					-- high connection latency.
					if (poiInfo.secondsLeft and poiInfo.secondsLeft > 0) then
						local color = util.GetTimeRemainingColorForSeconds(poiInfo.secondsLeft, WHITE_FONT_COLOR);
						local timeString = SecondsToTime(poiInfo.secondsLeft);	--> TODO - Combine as util and use new time formatter class.
						poiInfo.timeString = color:WrapTextInColorCode(timeString);
					end
				end
				if (mapInfo.mapType == Enum.UIMapType.Continent) then
					-- Needs more accurate zone infos
					mapInfo = C_Map.GetMapInfoAtPosition(mapInfo.mapID, poiInfo.position:GetXY());
				end
				if includeAreaName then
					-- -- User map name as fallback
					-- local areaName = MapUtil.FindBestAreaNameAtMouse(mapInfo.mapID, poiInfo.position:GetXY())
					-- poiInfo.areaName = areaName and areaName or mapInfo.name
					poiInfo.areaName = MapUtil.FindBestAreaNameAtMouse(mapInfo.mapID, poiInfo.position:GetXY())
				end
				poiInfo.mapInfo = mapInfo;
				tinsert(activeAreaPOIs, poiInfo);
			end
		end
		return activeAreaPOIs;
	end
end

----- POI tests -----

if _log.DEVMODE then
	local TestPoiUtil = {};

	-- Area POI IDs which have been already handled. (This is only used for testing!)
	--> Don't show this in the tooltip's test section!
	TestPoiUtil.separatedAreaPoiIDs = {
		-- Dragonflight
		"7096",  -- Grand Hunts - Azure Span
		"7342",  -- Grand Hunts - Ohn'ahra
		"7343",  -- Grand Hunts - Waking Shores
		"7344",  -- Grand Hunts - Thaldraszus
		"7345",  -- Grand Hunts - Azure Span
		"7101",  -- Camp Aylaag (east)
		"7102",  -- Camp Aylaag (north)
		"7103",  -- Camp Aylaag (west)
		"7261",  -- Dragonriding Race - Thaldraszus
		"7262",  -- Dragonriding Race - Ohn'ahran Plains
		"7263",  -- Dragonriding Race - Azure Span
		"7264",  -- Dragonriding Race - Thaldraszus
		"7104",  -- Siege of Dragonbane Keep
		"7267",  -- pre-Siege of Dragonbane Keep
		"7413",  -- post-Siege of Dragonbane Keep
		-- "7218",  -- pre-Community Feast
		-- "7219",  -- pre-Community Feast
		-- "7220",  -- post-Community Feast
		"7429",  -- Fyrakk Assaults - Ohn'ahra (continent view)
		"7432",  -- Fyrakk Assaults - Azure Span
		"7433",  -- Fyrakk Assaults - Azure Span
		"7435",  -- Fyrakk Assaults - Azure Span
		"7471",  -- Fyrakk Assaults - Ohn'ahra
		"7486",  -- Fyrakk Assaults - Ohn'ahra
		"7221",  -- Elemental Storm (Air)
		"7224",  -- Elemental Storm (Water)
		"7229",  -- Elemental Storm (Air) - Ohn'ahran Plains
		"7231",  -- Elemental Storm (Fire)
		"7232",  -- Elemental Storm (Water)
		"7233",  -- Elemental Storm (Air)
		"7235",  -- Elemental Storm (Fire)
		"7236",  -- Elemental Storm (Water)
		"7237",  -- Elemental Storm (Air)
		"7238",  -- Elemental Storm (Earth) - Azure Span
		"7239",  -- Elemental Storm (Fire)
		"7240",  -- Elemental Storm (Water)
		"7245",  -- Elemental Storm (Air)
		"7246",  -- Elemental Storm (Earth)
		"7247",  -- Elemental Storm (Fire) - Thaldraszus
		"7253",  -- Elemental Storm (Air) - Waking Shores
		"7254",  -- Elemental Storm (Earth) - Waking Shores
		"7255",  -- Elemental Storm (Fire) - Waking Shores
		"7256",  -- Elemental Storm (Water) - Waking Shores
		-- "7257",  -- Elemental Storm (???) - Waking Shores
		"7258",  -- Elemental Storm (Earth)
		"7259",  -- Elemental Storm (Fire)
		"7260",  -- Elemental Storm (Water) - Waking Shores
		"7459",  -- pre-Researchers Under Fire - Zaralek Cavern
		"7460",  -- pre-Researchers Under Fire - Zaralek Cavern
		"7461",  -- mid-Researchers Under Fire - Zaralek Cavern
		"7462",  -- mid-Researchers Under Fire - Zaralek Cavern
		"7492",  -- Time Rift, Thaldraszus
		-- Shadowlands
		-- Battle for Azeroth
		"5896",  -- Faction Assaults (Horde attacking Tiragardesound)
		"5964",  -- Faction Assaults (Horde attacking Drustvar)
		"5966",  -- Faction Assaults (Horde attacking Stormsong Valley)
		"5969",  -- Faction Assaults (Alliance attacking Nazmir)
		"5970",  -- Faction Assaults (Alliance attacking Vol'dun)
		"5973",  -- Faction Assaults (Alliance attacking Zuldazar)
		-- Legion
		"5175",  -- Legion Invasion - Azsuna
		"5177",  -- Legion Invasion - Highmountain
		"5178",  -- Legion Invasion - Stormheim
		"5210",  -- Legion Invasion - Val'sharah
		"5252",  -- Sentinax - Broken Shore
		"5254",  -- Sentinax (East) - Broken Shore
		"5255",  -- Sentinax (East) - Broken Shore
		"5256",  -- Sentinax (East) - Broken Shore
		"5257",  -- Sentinax - Broken Shore
		"5258",  -- Sentinax - Broken Shore
		"5259",  -- Sentinax (East) - Broken Shore
		"5260",  -- Sentinax - Broken Shore
		"5261",  -- Sentinax (East) - Broken Shore
		"5284",  -- Demon Malgrazoth - Broken Shore
		"5285",  -- Demon Salethan - Broken Shore
		"5286",  -- Demon Malorus - Broken Shore
		"5287",  -- Demon Emberfire - Broken Shore
		"5288",  -- Demon Glug - Broken Shore
		"5289",  -- Demon Emberfire - Broken Shore
		"5290",  -- Demon Inquisitor Chillbane - Broken Shore
		"5291",  -- Demon Zar'thoz - Broken Shore
		"5292",  -- Demon Dreadblade Annihilator - Broken Shore
		"5293",  -- Demon Xar'thok - Broken Shore
		"5294",  -- Demon Xorogun - Broken Shore
		"5295",  -- Demon Corrupted Bonebreaker - Broken Shore
		"5296",  -- Demon Zelthae - Broken Shore
		"5297",  -- Demon Dreadeye - Broken Shore
		"5298",  -- Demon Hel'nurath - Broken Shore
		"5299",  -- Demon Bruva - Broken Shore
		"5300",  -- Demon Flllurlokkr - Broken Shore
		"5301",  -- Demon Aqueux - Broken Shore
		"5302",  -- Demon Nix - Broken Shore
		"5303",  -- Demon Grossir - Broken Shore
		"5304",  -- Demon Eldrathe - Broken Shore
		"5305",  -- Demon Somber Dawn - Broken Shore
		"5306",  -- Demon Sithizi - Broken Shore
		"5307",  -- Demon Eye of Gurgh - Broken Shore
		"5308",  -- Demon Badatin - Broken Shore
		"5350",  -- Invasion Point Sangua - Argus, Krokuun
		"5359",  -- Invasion Point Cen'gar - Argus, Krokuun
		"5360",  -- Invasion Point Val - Argus, Krokuun
		"5366",  -- Invasion Point Bonich - Argus, Eredath
		"5367",  -- Invasion Point Aurinor - Argus, Eredath
		"5368",  -- Invasion Point Naigtal - Argus, Eredath
		"5369",  -- Invasion Point Sangua - Argus, Antoran Wastes
		"5370",  -- Invasion Point Cen'gar - Argus, Antoran Wastes
		"5371",  -- Invasion Point Bonich - Argus, Antoran Wastes
		"5372",  -- Invasion Point Val - Argus, Antoran Wastes
		"5373",  -- Invasion Point Aurinor - Argus, Antoran Wastes
		"5374",  -- Invasion Point Naigtal - Argus, Antoran Wastes
		"5375",  -- Invasion Point Boss Alluradel - Argus, Antoran Wastes
		"5376",  -- Invasion Point Boss Occularus
		"5377",  -- Invasion Point Boss Pit Lord Vilemus
		"5379",  -- Invasion Point Boss Meto - Argus, Antoran Wastes
		"5380",  -- Invasion Point Boss Sotanathor
		"5381",  -- Invasion Point Boss Matron Folnuna
		-- "7018",  -- Timewalking Vendor in Azsuna + Broken Shore (don't filter)
		-- Draenor
		-- "6985",  -- Timewalking Vendor in Ashran (don't filter)
	};

	function TestPoiUtil.GetAreaPOIInfoForZones(zoneMaps, isContentTypeMapInfo)
		local mapInfos = {};
		if not isContentTypeMapInfo then
			for _, mapID in ipairs(zoneMaps) do
				local mapInfo = LocalMapUtil.GetMapInfo(mapID);
				tinsert(mapInfos, mapInfo);
			end
		else
			mapInfos = zoneMaps;
		end

		local poiInfos = {};
		for _, mapInfo in ipairs(mapInfos) do
			local activeAreaPOIs = LocalMapUtil.GetAreaPOIForMapInfo(mapInfo);
			if (activeAreaPOIs and #activeAreaPOIs > 0) then
				for _, poiInfo in ipairs(activeAreaPOIs) do
					if not tContains(TestPoiUtil.separatedAreaPoiIDs, tostring(poiInfo.areaPoiID)) then
						tinsert(poiInfos, poiInfo);
					end
				end
			end
		end
		table.sort(poiInfos,
			function (a, b)
				return a.mapInfo.mapID < b.mapInfo.mapID;  --> 0-9
			end
		);

		return poiInfos;
	end

	function TestPoiUtil.GetAreaPOIInfoForContinent(contMapID)
		-- Get the map IDs of the continent of all its zones
		local mapInfos = {};
		local contMapInfo = LocalMapUtil.GetMapInfo(contMapID);
		tinsert(mapInfos, contMapInfo);
		tAppendAll(mapInfos, LocalMapUtil.GetMapChildrenInfo(contMapID, Enum.UIMapType.Zone));

		local isContentTypeMapInfo = true;
		return TestPoiUtil.GetAreaPOIInfoForZones(mapInfos, isContentTypeMapInfo);
	end

	util.map.GetAreaPOIInfoForZones = TestPoiUtil.GetAreaPOIInfoForZones;
	util.map.GetAreaPOIInfoForContinent = TestPoiUtil.GetAreaPOIInfoForContinent;
end

--------------------------------------------------------------------------------

-- -- Use 8-bit separator as default, but use 16-bit for Chinese locales
-- local SEPARATOR_8BIT = ",";
-- local SEPARATOR_16BIT = "，";
-- local FMP_ZONE_SUBZONE_NOSPACE_SEPARATOR = SEPARATOR_8BIT;
-- if tContains({"zhCN", "zhTW"}, L.currentLocale) then
-- 	FMP_ZONE_SUBZONE_NOSPACE_SEPARATOR = SEPARATOR_16BIT;
-- end

-- -- Separate the zone name from the taxi node name and return both strings.
-- ---@param taxiNodeData MapTaxiNodeInfo
-- ---@param sep string
-- ---@return string
-- ---@return string
-- --
-- local function trimTaxiNodeName(taxiNodeData, sep)
-- 	sep = sep or FMP_ZONE_SUBZONE_NOSPACE_SEPARATOR;
-- 	local nodeNameMatch, zoneNameMatch = strsplit(FMP_ZONE_SUBZONE_NOSPACE_SEPARATOR, taxiNodeData.name);
-- 	local cleanNodeName = nodeNameMatch and strtrim(nodeNameMatch) or taxiNodeData.name;
-- 	local cleanZoneName = zoneNameMatch and strtrim(zoneNameMatch) or '';
-- 	return cleanNodeName, cleanZoneName;
-- end

--------------------------------------------------------------------------------

function ns.GetTrackedAchievementTitles(textColor)
	local fontColor = textColor or HIGHLIGHT_FONT_COLOR;
	local trackedAchievements = {
		LegionAssaultsData.achievementID,
		ArgusInvasionData.achievementID,
		BfAFactionAssaultsData.achievementIDs[BfAFactionAssaultsData.playerFactionIndex],
		UNITED_FRONT_ID,  --> Shadowlands, The Maw assault threat
		DEAD_MEN_TELL_SOME_TALES_ID,  --> Shadowlands Covenant Campaign
	};
	table.sort(trackedAchievements);
	local titles = {};
	for _, achievementID in ipairs(trackedAchievements) do
		local aID, aName = GetAchievementInfo(achievementID);
		tinsert(titles, fontColor:WrapTextInColorCode(aName));
	end
	return titles;
end

--------------------------------------------------------------------------------
----- Specials -----------------------------------------------------------------
--------------------------------------------------------------------------------

-- A collection of utility functions related to calendar events.
util.calendar = {};  --> for global use (project-wide)
-- util.calendar.TIMEWALKING_EVENT_ID_DRAENOR = 1063;
-- util.calendar.TIMEWALKING_EVENT_ID_DRAENOR2 = 1056;
-- util.calendar.TIMEWALKING_EVENT_ID_LEGION = 1265;
util.calendar.WINTER_HOLIDAY_EVENT_ID = 141;
util.calendar.WINTER_HOLIDAY_ATLAS_NAME = "Front-Tree-Icon";
util.calendar.WORLDQUESTS_EVENT_ID = 613;

local LocalCalendarUtil = {};  --> for local use (in this file)
-- LocalCalendarUtil.WORLDQUESTS_EVENT_TEXTURE_ID = "worldquest-tracker-questmarker";  -- 1467050;
-- LocalCalendarUtil.WOW_BIRTHDAY_EVENT_ID = 1262;
-- LocalCalendarUtil.TIMEWALKING_ATLAS_NAME = "TimewalkingVendor-32x32";

LocalCalendarUtil.cache = {};
LocalCalendarUtil.cache.data = {};
LocalCalendarUtil.cache.lastUpdatedTime = 0  -- Unix timestamp

function LocalCalendarUtil.cache:AddItem(item, itemID)
	_log:debug_type(_log.type.CALENDAR, "Adding item to cache:", itemID)
	local itemIDstr = tostring(itemID);
	-- Add or update item
	self.data[itemIDstr] = item;
end

function LocalCalendarUtil.cache:GetItem(itemID)
	local itemIDstr = tostring(itemID);
	return self.data[itemIDstr];
end

function LocalCalendarUtil.cache:HasItem(itemID)
	_log:debug_type(_log.type.CALENDAR, "Has item in cache:", itemID, self:GetItem(itemID) ~= nil)
	return self:GetItem(itemID) ~= nil;
end

-- Find and return the currently active calendar day event by given ID.
---@param eventID number
---@return CalendarDayEvent|nil dayEvent
---@return number|nil comparison
--> REF.: <FrameXML/CalendarUtil.lua>  
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/DateAndTimeDocumentation.lua>  
-- REF.: <<https://wowpedia.fandom.com/wiki/API_C_Calendar.GetDayEvent>>
--
function util.calendar.GetActiveDayEvent(eventID)
	_log:debug_type(_log.type.CALENDAR, "Looking for event:", eventID, "...");

	-- Update cache at start and every hour
	local timePassedSeconds = (GetServerTime() - LocalCalendarUtil.cache.lastUpdatedTime)
	-- print("timePassedSeconds:", timePassedSeconds, "lastUpdatedTime:", LocalCalendarUtil.cache.lastUpdatedTime)
	if (timePassedSeconds >= 3600 or LocalCalendarUtil.cache.lastUpdatedTime == 0) then
		_log:debug_type(_log.type.CALENDAR, "Updating day event cache...")
		local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime();  --> today
		local monthOffset = 0;  --> offset from this month
		-- -- Tests
		-- currentCalendarTime.monthDay = 9
		-- currentCalendarTime.hour = 7
		-- monthOffset = 1
		local numDayEvents = C_Calendar.GetNumDayEvents(monthOffset, currentCalendarTime.monthDay);
		-- print("numDayEvents:", numDayEvents, monthOffset, currentCalendarTime.monthDay)
		for eventIndex = 1, numDayEvents do
			local event = C_Calendar.GetDayEvent(monthOffset, currentCalendarTime.monthDay, eventIndex);
			-- print(eventIndex, event.eventID, event.eventID == eventID, event.eventType, event.calendarType, event.title);
			LocalCalendarUtil.cache:AddItem(event, event.eventID)
		end
		LocalCalendarUtil.cache.lastUpdatedTime = GetServerTime()  -- Unix timestamp
	end

	if LocalCalendarUtil.cache:HasItem(eventID) then
		_log:debug_type(_log.type.CALENDAR, "Returning cached item", eventID, "...");
		return LocalCalendarUtil.cache:GetItem(eventID);
	end
end
-- Test_GetActiveDayEvent = util.calendar.GetActiveDayEvent;
-- -- Test_GetActiveDayEvent(613)  --> util.calendar.WORLDQUESTS_EVENT_ID

-- Build the chat message for given calendar event.
---@param event CalendarDayEvent
---@return string|nil chatMessage
--
function util.calendar.GetDayEventChatMessage(event)
	if not event then return end;
	_log:debug_type(_log.type.CALENDAR, "Got event:", event.eventID, event.eventType, event.sequenceType, event.title);

	local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime();  --> today
	local monthOffset = 0;  --> this month

	if ( event.sequenceType == "END" and currentCalendarTime.hour >= event.endTime.hour ) then
		-- Event is over; don't show anything on last day *after* event ends
		return;
	end

	local timeString, suffixString;
	local indexInfo = C_Calendar.GetEventIndexInfo(event.eventID);  -- , monthOffset, currentCalendarTime.monthDay);
	if not indexInfo then
		indexInfo = {offsetMonths = monthOffset, monthDay = currentCalendarTime.monthDay, eventIndex = 1};
	end
	local eventLinkText = GetCalendarEventLink(indexInfo.offsetMonths, indexInfo.monthDay, indexInfo.eventIndex);
	local eventLink = LINK_FONT_COLOR:WrapTextInColorCode(COMMUNITIES_CALENDAR_CHAT_EVENT_TITLE_FORMAT:format(eventLinkText));

	_log:debug_type(_log.type.CALENDAR, "--> seq:", event.numSequenceDays, event.sequenceIndex, event.numSequenceDays - event.sequenceIndex, "days left");

	if ( event.sequenceType == "START" and currentCalendarTime.hour >= event.endTime.hour ) then
		-- Mark event as ongoing on the first day *after* event starts
		event.sequenceType = "ONGOING";
	end

	if (event.sequenceType == "ONGOING") then
		-- Show during days between the first and the last day
		timeString = COMMUNITIES_CALENDAR_ONGOING_EVENT_PREFIX;
		-- Also show roughly the remaining time for the ongoing event
		-- local timeLeft = event.endTime.monthDay - currentCalendarTime.monthDay;
		local timeLeft = event.numSequenceDays - event.sequenceIndex;
		suffixString = SPELL_TIME_REMAINING_DAYS:format(timeLeft);
	else
		-- Show on first and last day of the event
		if (event.sequenceType == "START") then
			timeString = GameTime_GetFormattedTime(event.startTime.hour, event.startTime.minute, true);
		end
		if (event.sequenceType == "END") then
			timeString = GameTime_GetFormattedTime(event.endTime.hour, event.endTime.minute, true);

		end
		-- Add localized text whether the today's event starts or ends
		eventLink = _G["CALENDAR_EVENTNAME_FORMAT_"..event.sequenceType]:format(eventLink);
		timeString = COMMUNITIES_CALENDAR_EVENT_FORMAT:format(COMMUNITIES_CALENDAR_TODAY, timeString);
	end
	local chatMsg = YELLOW_FONT_COLOR:WrapTextInColorCode(COMMUNITIES_CALENDAR_CHAT_EVENT_BROADCAST_FORMAT:format(timeString, eventLink, suffixString or ''));

	return chatMsg;
end

--------------------------------------------------------------------------------
----- Addon Compartment --------------------------------------------------------
--------------------------------------------------------------------------------
-- REF.: <FrameXML/AddonCompartment.lua>
-- REF.: <https://wowpedia.fandom.com/wiki/API_C_AddOns.GetAddOnMetadata>

local LocalAddonCompartmentUtil = {};
util.AddonCompartment = LocalAddonCompartmentUtil;

function LocalAddonCompartmentUtil.IsAddonCompartmentAvailable()
	return AddonCompartmentFrame ~= nil;
end

function LocalAddonCompartmentUtil.IsAddonRegistered()
	if LocalAddonCompartmentUtil.IsAddonCompartmentAvailable() then
		return tContains(AddonCompartmentFrame.registeredAddons, LocalAddonCompartmentUtil.info);
	end
end

function LocalAddonCompartmentUtil.RegisterAddon()
	-- if LocalAddonCompartmentUtil.IsAddonCompartmentAvailable() then
	if not util.AddonCompartment.IsAddonRegistered() then
		LocalAddonCompartmentUtil.info = {
			text = ns.GetAddOnMetadata(AddonID, "Title"),
			icon = ns.GetAddOnMetadata(AddonID, "IconTexture") or ns.GetAddOnMetadata(AddonID, "IconAtlas"),
			notCheckable = true,
			registerForAnyClick = true,
			func = ns.MissionReportButtonPlus_OnAddonCompartmentClick,
			funcOnEnter = ns.MissionReportButtonPlus_OnAddonCompartmentEnter,
			funcOnLeave = ns.MissionReportButtonPlus_OnAddonCompartmentLeave,
		};
		AddonCompartmentFrame:RegisterAddon(LocalAddonCompartmentUtil.info);
		_log:info("[AC] Addon registered.");
	else
		_log:info("[AC] Addon already registered.");
	end
end

function LocalAddonCompartmentUtil.UnregisterAddon()
	if LocalAddonCompartmentUtil.IsAddonRegistered() then
		for index, compartmentAddon in ipairs(AddonCompartmentFrame.registeredAddons) do
			if (compartmentAddon.text == ns.AddonTitle) then
				tremove(AddonCompartmentFrame.registeredAddons, index);
				AddonCompartmentFrame:UpdateDisplay();
				_log:debug("[AC] Found and removed from index:", index);
				_log:info("[AC] Addon unregistered.");
				return;
			end
		end
	end
	_log:info("[AC] Addon wasn't registered.");
end

--@do-not-package@
----- more to come -------------------------------------------------------------

--> TODO - More ideas
-- Timewalking Dragonflight (2023-05-03)
-- Forscher unter Feuer
-- local FISHERFRIEND_OF_THE_ISLES_ID = 11725;  -- Fishing achievement
-- local UNDER_THE_WEATHER_ID = 17540;  -- Elemental Storm achievement
-- Reputation reminder if ready to collect reward 
-- <https://www.wowhead.com/de/today-in-wow>

----- Tests --------------------------------------------------------------------

-- -- Return the UiMapDetails of the current zone.
-- function LocalMapUtil.GetCurrentZoneMapInfo()
-- 	local mapID = C_Map.GetBestMapForUnit("player")
-- 	local mapInfo = LocalMapUtil.GetMapInfo(mapID)
-- 	return mapInfo
-- end
-- Test_GetCurrentZoneMapInfo = LocalMapUtil.GetCurrentZoneMapInfo
-- -- C_Map.GetMapLinksForMap(2023)	--> TODO - QH

-- function Test_MapInfoAtPosition()
-- 	local mapInfo = LocalMapUtil.GetCurrentZoneMapInfo()
-- 	local pos = C_Map.GetPlayerMapPosition(mapInfo.mapID, "player")  -- Only works for the player and party members.
-- 	if pos then
-- 		-- return C_Map.GetMapInfoAtPosition(mapInfo.mapID, pos:GetXY())
-- 	-- 	local areaIDs = C_MapExplorationInfo.GetExploredAreaIDsAtPosition(mapInfo.mapID, pos)
-- 	-- 	if areaIDs then
-- 	-- 		for i=1, #areaIDs do
-- 	-- 			local areaID = areaIDs[i]
-- 	-- 			local areaName = LocalMapUtil.GetAreaInfo(areaID)
-- 	-- 			print(i, areaID, areaName)
-- 	-- 		end
-- 	-- 	end
-- 		return MapUtil.FindBestAreaNameAtMouse(mapInfo.mapID, pos:GetXY())
-- 	end
-- end

-- MapUtil.ShouldShowTask(mapID, info)
-- MapUtil.MapHasEmissaries(mapID)
-- MapUtil.MapHasUnlockedBounties(mapID)

-- isAccountQuest = C_QuestLog.IsAccountQuest(questID)
-- isThreat = C_QuestLog.IsThreatQuest(questID)
-- isBounty = C_QuestLog.IsQuestBounty(questID)
-- isCalling = C_QuestLog.IsQuestCalling(questID)

-- local AZERITE_CURRENCY_ID = 1553;
-- C_CurrencyInfo.GetCurrencyInfo(

-- --> <FrameXML/QuestUtils.lua>
-- local ECHOS_OF_NYLOTHA_CURRENCY_ID = 1803;
-- C_CurrencyInfo.GetFactionGrantedByCurrency(currencyID);
-- C_CurrencyInfo.GetCurrencyInfo(currencyID)
-- local currencyInfo = { name = name, texture = texture, numItems = numItems, currencyID = currencyID, rarity = rarity, firstInstance = firstInstance };
-- table.sort(currencies,
-- 	function(currency1, currency2)
-- 		if currency1.rarity ~= currency2.rarity then
-- 			return currency1.rarity > currency2.rarity;
-- 		end
-- 		return currency1.currencyID > currency2.currencyID;
-- 	end
-- );
-- local currencyColor = GetColorForCurrencyReward(currencyInfo.currencyID, currencyInfo.numItems);

-- QuestUtils_GetQuestName(questID)

-- -- lock icons
-- "QuestSharing-QuestDetails-Padlock"
-- 130944  -- "Interface/ChatFrame/UI-ChatFrame-LockIcon"
-- ["QuestSharing-QuestLog-Padlock"]={24, 29, 0.224609, 0.271484, 0.757812, 0.984375, false, false, "1x"},
-- ["QuestSharing-Padlock"]={24, 29, 0.00195312, 0.0488281, 0.554688, 0.78125, false, false, "1x"},  				<--
-- ["QuestSharing-QuestDetails-Padlock"]={20, 20, 0.537109, 0.576172, 0.835938, 0.992188, false, false, "1x"},
-- ["Legionfall_Padlock"]={38, 45, 0.853516, 0.890625, 0.000976562, 0.0449219, false, false, "1x"},

-- IsFlyableArea()
-- IsIndoors()
-- IsOutdoors()
-- IsMounted()
-- IsSwimming()
-- local hasAlternateForm, inAlternateForm = d;
-- (buff) Time Anomaly

-----																			--> TODO - Add currency info

-- REF.: <FrameXML/FormattingUtil.lua>
-- local currencyString = GetCurrencyString(currencyID, overrideAmount, colorCode, abbreviate)
-- local currencyString = GetCurrenciesString(currencies);

-- REF.: <FrameXML/Blizzard_CovenantSanctum/Blizzard_CovenantSanctumUpgrades.lua>
-- C_CovenantSanctumUI.GetSoulCurrencies() --> works ONLY with opened Sanctum UI (!)
-- local soulCurrencyID = 1810;  --> "Redeemed Soul"
-- local animaCurrencyID, maxDisplayableValue = C_CovenantSanctumUI.GetAnimaInfo();  --> 1813, 200000
-- C_CurrencyInfo.GetCurrencyInfo(soulCurrencyID)  --> .name, .iconFileID, .quantity, .maxQuantity, 
--@end-do-not-package@
