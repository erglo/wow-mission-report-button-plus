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

-- util.CreateInlineIcon(628564);  --> check mark icon texture
-- util.CreateInlineIcon(3083385);  --> dash icon texture

-- Return a color for given time based on world quest threshold.
---@param seconds number  The amount of seconds remaining
---@param normalColor table|nil  A color class (see <FrameXML/GlobalColors.lua>)
---@param warningColor table|nil  A color class (see <FrameXML/GlobalColors.lua>)
---@param criticalColor table|nil  A color class (see <FrameXML/GlobalColors.lua>)
--> REF.: <FrameXML/QuestUtils.lua>
--
function util.GetTimeRemainingColorForSeconds(seconds, normalColor, warningColor, criticalColor)
	local function IsWithinTimeThreshold(secondsRemaining, threshold)
		return secondsRemaining and secondsRemaining <= threshold or false;
	end
	local color = NORMAL_FONT_COLOR;
	local normColor = normalColor or color;
	local warnColor = warningColor or WARNING_FONT_COLOR;
	local critColor = criticalColor or RED_FONT_COLOR;
	color = IsWithinTimeThreshold(seconds, WORLD_QUESTS_TIME_LOW_MINUTES) and warnColor or normColor;  --> within 75 min.
	color = IsWithinTimeThreshold(seconds, WORLD_QUESTS_TIME_CRITICAL_MINUTES) and critColor or normColor;  --> within 15 min.
	return color;
end

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

-- function util.quest.GetQuestTimeColor(secondsRemaining, useCustomColors)
-- 	-- REF.: <FrameXML/QuestUtils.lua>
-- 	-- REF.: <FrameXML/TimeUtil.lua>
-- 	if not useCustomColors then
-- 		return QuestUtils_GetQuestTimeColor(secondsRemaining);
-- 	end
-- 	local isWithinCriticalTime = secondsRemaining <= MinutesToSeconds(WORLD_QUESTS_TIME_CRITICAL_MINUTES);
-- 	return isWithinCriticalTime and RED_FONT_COLOR or WHITE_FONT_COLOR;
-- end

-- Return a color for a given quest based on the time left.
---@param questID number
---@param normalColor table  A color class (see <FrameXML/GlobalColors.lua>)
---@param warningColor table  A color class (see <FrameXML/GlobalColors.lua>)
---@param criticalColor table  A color class (see <FrameXML/GlobalColors.lua>)
--
function util.quest.GetQuestTimeColorByQuestID(questID, normalColor, warningColor, criticalColor)
	local color = NORMAL_FONT_COLOR;
	local normColor = normalColor or color;
	local warnColor = warningColor or YELLOW_THREAT_COLOR;  -- WARNING_FONT_COLOR;
	local critColor = criticalColor or RED_THREAT_COLOR;  -- RED_FONT_COLOR;
	-- NOT_ON_THREAT_COLOR
	-- NO_THREAT_COLOR
	-- ORANGE_THREAT_COLOR
	-- if QuestUtils_ShouldDisplayExpirationWarning(questID) then
	color = QuestUtils_IsQuestWithinLowTimeThreshold(questID) and warnColor or normColor;  --> within 75 min.
	color = QuestUtils_IsQuestWithinCriticalTimeThreshold(questID) and critColor or normColor;  --> within 15 min.
	return color;
end

function util.quest.GetQuestTimeLeftInfo(questID)
	-- REF.: <FrameXML/WorldMapFrame.lua>
	-- REF.: <FrameXML/GameTooltip.lua>
	-- REF.: <FrameXML/TimeUtil.lua>
	local seconds = C_TaskQuest.GetQuestTimeLeftSeconds(questID);
	if (seconds and seconds > 0) then
		local timeLeftInfo = {};
		timeLeftInfo.seconds = seconds;
		-- timeLeftInfo.color = util.quest.GetQuestTimeColor(timeLeftInfo.seconds);
		timeLeftInfo.color = util.quest.GetQuestTimeColorByQuestID(questID, WHITE_FONT_COLOR);
		local abbreviationType = SecondsFormatter.Abbreviation.Truncate;
		timeLeftInfo.timeString = WorldQuestsSecondsFormatter:Format(timeLeftInfo.seconds, abbreviationType);
		timeLeftInfo.timeLeftString = BONUS_OBJECTIVE_TIME_LEFT:format(timeLeftInfo.timeString);
		timeLeftInfo.coloredTimeLeftString = timeLeftInfo.color:WrapTextInColorCode(timeLeftInfo.timeLeftString);
		return timeLeftInfo;
	end
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
--> REF.: <FrameXML/Blizzard_APIDocumentationGenerated/BountySharedDocumentation.lua><br/>
--[[
<pre>
	Name = "BountyInfo",
	Type = "Structure",
	Fields =
	{
		{ Name = "questID", Type = "number", Nilable = false },
		{ Name = "factionID", Type = "number", Nilable = false },
		{ Name = "icon", Type = "number", Nilable = false },
		{ Name = "numObjectives", Type = "number", Nilable = false },
		{ Name = "turninRequirementText", Type = "string", Nilable = true },
	}
</pre>
--]]
function util.quest.GetBountiesForMapID(mapID)
	return C_QuestLog.GetBountiesForMapID(mapID);
end

--[[ Tests

MapUtil.ShouldShowTask(mapID, info)
MapUtil.MapHasEmissaries(mapID)
MapUtil.MapHasUnlockedBounties(mapID)

isAccountQuest = C_QuestLog.IsAccountQuest(questID)
isThreat = C_QuestLog.IsThreatQuest(questID)
isBounty = C_QuestLog.IsQuestBounty(questID)
isCalling = C_QuestLog.IsQuestCalling(questID)

--> <FrameXML/QuestUtils.lua>
local ECHOS_OF_NYLOTHA_CURRENCY_ID = 1803;
C_CurrencyInfo.GetFactionGrantedByCurrency(currencyID);
C_CurrencyInfo.GetCurrencyInfo(currencyID)
local currencyInfo = { name = name, texture = texture, numItems = numItems, currencyID = currencyID, rarity = rarity, firstInstance = firstInstance };
table.sort(currencies,
	function(currency1, currency2)
		if currency1.rarity ~= currency2.rarity then
			return currency1.rarity > currency2.rarity;
		end
		return currency1.currencyID > currency2.currencyID;
	end
);
local currencyColor = GetColorForCurrencyReward(currencyInfo.currencyID, currencyInfo.numItems);

QuestUtils_GetQuestName(questID)
QuestUtils_IsQuestWorldQuest(questID)

-- lock icons
"QuestSharing-QuestDetails-Padlock"
130944  -- "Interface/ChatFrame/UI-ChatFrame-LockIcon"
["QuestSharing-QuestLog-Padlock"]={24, 29, 0.224609, 0.271484, 0.757812, 0.984375, false, false, "1x"},
["QuestSharing-Padlock"]={24, 29, 0.00195312, 0.0488281, 0.554688, 0.78125, false, false, "1x"},  				<--
["QuestSharing-QuestDetails-Padlock"]={20, 20, 0.537109, 0.576172, 0.835938, 0.992188, false, false, "1x"},
["Legionfall_Padlock"]={38, 45, 0.853516, 0.890625, 0.000976562, 0.0449219, false, false, "1x"},

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

-- Check if the dragon riding feature in Dragonflight is unlocked.
---@return boolean isUnlocked
-- REF.: <FrameXML/Blizzard_ExpansionLandingPage/Blizzard_DragonflightLandingPage.lua>
-- REF.: <FrameXML/AchievementUtil.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/AchievementInfoDocumentation.lua>
-- REF.: <https://wowpedia.fandom.com/wiki/World_of_Warcraft_API#Achievements>
--
function util.garrison.IsDragonRidingUnlocked()
	local DRAGONRIDING_ACCOUNT_ACHIEVEMENT_ID = 15794;
	local DRAGONRIDING_INTRO_QUEST_ID = 68798;
	local hasAccountAchievement = select(4, GetAchievementInfo(DRAGONRIDING_ACCOUNT_ACHIEVEMENT_ID));
	return hasAccountAchievement or util.quest.IsFlaggedCompleted(DRAGONRIDING_INTRO_QUEST_ID);
end
Test_IsDragonRidingUnlocked = util.garrison.IsDragonRidingUnlocked;

-- Create a string with the amount and icon of given currency info.
---@param treeCurrencyInfo table  A TreeCurrencyInfo table
---@param includeMaximum boolean|nil  Whether to include the maximal amount to the returned string or not
---@return string currencyString
-- REF.: <FrameXML/Blizzard_SharedTalentUI/Blizzard_SharedTalentFrame.lua>
--
function util.garrison.CreateCurrencyString(treeCurrencyInfo, includeMaximum, iconWidth, iconOffsetX, iconOffsetY)
	local flags, traitCurrencyType, currencyTypesID, overrideIcon = C_Traits.GetTraitCurrencyInfo(treeCurrencyInfo.traitCurrencyID);
	local amountString = format("%2d", treeCurrencyInfo.quantity);
	local width = iconWidth or 20;
	local offsetX = iconOffsetX or 3;
	local offsetY = iconOffsetY or 0;
	local iconString = overrideIcon and util.CreateInlineIcon(overrideIcon, width, width, offsetX, offsetY) or '';
	local currencyString = '';
	if includeMaximum then
		local maxCurrencyString = tostring(treeCurrencyInfo.maxQuantity);
		currencyString = TALENT_FRAME_CURRENCY_FORMAT_WITH_MAXIMUM:format(amountString, maxCurrencyString, iconString);
	else
		currencyString = TALENT_FRAME_CURRENCY_FORMAT:format(amountString, iconString);
	end

	return currencyString;
end

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
		{mapID = 2022, achievementID = 16575},  -- "Waking Shores Glyph Hunter"
		{mapID = 2023, achievementID = 16576},  -- "Ohn'ahran Plains Glyph Hunter"
		{mapID = 2024, achievementID = 16577},  -- "Azure Span Glyph Hunter"
		{mapID = 2025, achievementID = 16578},  -- "Thaldraszus Glyph Hunter"
	};
	local glyphsPerZone = {};  -- Glyph count by map ID
	local numGlyphsTotal = 0;  -- The total number of glyphs from all zones
	local numGlyphsCollected = 0;  -- The number of collected glyphs from all zones
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
		glyphsPerZone[mapInfo.name] = {};  -- The name of a zone
		glyphsPerZone[mapInfo.name].numTotal = numCriteria;  -- The total number of glyphs per zone
		glyphsPerZone[mapInfo.name].numComplete = numComplete;  -- The number of collected glyphs per zone
		numGlyphsTotal = numGlyphsTotal + numCriteria;
		numGlyphsCollected = numGlyphsCollected + numComplete;
	end

	return glyphsPerZone, numGlyphsCollected, numGlyphsTotal;
end

-- Return a list of major faction IDs.
---@param expansionID number  The expansion level
---@return number[] majorFactionIDs
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua>
-- REF.: <FrameXML/Blizzard_MajorFactions/Blizzard_MajorFactionRenown.lua>
--
function util.garrison.GetMajorFactionIDs(expansionID)
	return C_MajorFactions.GetMajorFactionIDs(expansionID);
end

-- Retrieve the data for given major faction ID.
---@param factionID number  A major faction ID (since Dragonflight WoW 10.x)
---@return MajorFactionData table  For details see "MajorFactionData" fields below
--[[
<pre>
	Name = "MajorFactionData",
	Type = "Structure",
	Fields =
	{
		{ Name = "name", Type = "string", Nilable = false },
		{ Name = "factionID", Type = "number", Nilable = false },
		{ Name = "expansionID", Type = "number", Nilable = false },
		{ Name = "bountySetID", Type = "number", Nilable = false },
		{ Name = "isUnlocked", Type = "bool", Nilable = false },
		{ Name = "unlockDescription", Type = "string", Nilable = true },
		{ Name = "unlockOrder", Type = "number", Nilable = false },
		{ Name = "renownLevel", Type = "number", Nilable = false },
		{ Name = "renownReputationEarned", Type = "number", Nilable = false },
		{ Name = "renownLevelThreshold", Type = "number", Nilable = false },
		{ Name = "textureKit", Type = "string", Nilable = false },
		{ Name = "celebrationSoundKit", Type = "number", Nilable = false },
		{ Name = "renownFanfareSoundKitID", Type = "number", Nilable = false },
	}
</pre>
--]]
function util.garrison.GetMajorFactionData(factionID)
	return C_MajorFactions.GetMajorFactionData(factionID);
end

-- Build and return the icon of the given expansion's major faction.
---@param majorFactionData table  See 'util.garrison.GetMajorFactionData' doc string for details
---@return string majorFactionIcon
--
function util.garrison.GetMajorFactionInlineIcon(majorFactionData)
	if (majorFactionData.expansionID == util.expansion.data.Dragonflight.ID) then
		-- return util.CreateInlineIcon("MajorFactions_Icons_"..majorFactionData.textureKit.."512", 16, 16, -1, 0);
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
---@return boolean hasMaxRenown^
--
function util.garrison.HasMaximumMajorFactionRenown(currentFactionID)
	return C_MajorFactions.HasMaximumRenown(currentFactionID);
end

-- Return a list with details about currently running garrison missions.
---@param followerType Enum.GarrisonFollowerType
---@return missionInfo[] inProgressMissions  A list of tables with mission info
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

-- Find active threats in the world, if active for current player; eg. the
-- covenant attacks in The Maw or the N'Zoth's attacks in Battle for Azeroth.
---@return table|nil activeThreats
--
function util.map.GetActiveThreats()
	if util.quest.HasActiveThreats() then
		local threatQuests = util.quest.GetThreatQuests();
		local activeThreats = {};
		for i, questID in ipairs(threatQuests) do
			if util.quest.IsActiveWorldQuest(questID) then
				local questInfo = util.quest.GetWorldQuestInfoByQuestID(questID);
				local typeAtlas = QuestUtil.GetThreatPOIIcon(questID);
				local questName = util.CreateInlineIcon(typeAtlas)..WHITE_FONT_COLOR:WrapTextInColorCode(questInfo.questTitle);
				local mapID = util.quest.GetWorldQuestZoneID(questID);
				local mapInfo = util.map.GetMapInfo(mapID);
				local timeLeftInfo = util.quest.GetQuestTimeLeftInfo(questID);
				local timeLeftString = timeLeftInfo and timeLeftInfo.coloredTimeLeftString or '';
				local questExpansionLevel = GetQuestExpansion(questID);
				if questExpansionLevel then
					_log:debug("Threat:", questID, questInfo.questTitle, ">", mapID, mapInfo.name, "expLvl:", questExpansionLevel);
					if ( not activeThreats[questExpansionLevel] ) then
						-- Add table values per expansion IDs
						activeThreats[questExpansionLevel] = {};
					end
					tinsert(activeThreats[questExpansionLevel], {questID, questName, mapInfo.name, timeLeftString});
				end
		   end
		end
		return activeThreats;
	end
end

-- -- local POIs = {
-- -- 	[tostring(util.expansion.data.Dragonflight.ID)] = {
-- -- 		-- {mapID, poiID}
-- -- 		GrandHunts = {1978, {7343}},  -- "minimap-genericevent-hornicon"
-- -- 		-- "racing"
-- -- 	},
-- -- };
-- local POIs = {
-- 	["racing"] = {2022, 2023, 2024, 2025},  --> Enum.UIMapType.Zone,
-- 	["minimap-genericevent-hornicon"] = 1978,  --> Enum.UIMapType.Continent
--  ["MajorFactions_MapIcons_Centaur64"} = {2023}
-- };

-- Returns a table with POI IDs currently active on the world map.
---@param mapID number
---@return table areaPOIs
--
function util.map.GetAreaPOIForMap(mapID)
	-- REF.: <FrameXML/Blizzard_SharedMapDataProviders/AreaPOIDataProvider.lua>
	-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/AreaPoiInfoDocumentation.lua>
	-- REF.: <FrameXML/TableUtil.lua>
	local areaPOIs = GetAreaPOIsForPlayerByMapIDCached(mapID);
	areaPOIs = TableIsEmpty(areaPOIs) and C_AreaPoiInfo.GetAreaPOIForMap(mapID) or areaPOIs;
	return areaPOIs;
end

-- function util.map.GetPOIForExpansionMap(expansionID, mapID, areaPoiList)
-- 	local activePOIs = {};
-- 	local areaPOIs = util.map.GetAreaPOIForMap(mapID);
-- 	for i, areaPoiID in ipairs(areaPOIs) do
-- 		if tContains(areaPoiList, areaPoiID) then
-- 			local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapID, areaPoiID);
-- 			local mapInfo = C_Map.GetMapInfoAtPosition(mapID, poiInfo.position:GetXY());
-- 			if ( not activePOIs[expansionID] ) then
-- 				-- Add table values per expansion IDs
-- 				activePOIs[expansionID] = {};
-- 			end
-- 			local poiIcon = util.CreateInlineIcon(poiInfo.atlasName);
-- 			local poiName = poiIcon.." "..poiInfo.name;
-- 			local timeLeftString = '';
-- 			if C_AreaPoiInfo.IsAreaPOITimed(areaPoiID) then
-- 				local timeLeftSeconds = C_AreaPoiInfo.GetAreaPOISecondsLeft(areaPoiID);
-- 				-- local timeLeftColor = util.GetTimeRemainingColorForSeconds(timeLeftSeconds, WHITE_FONT_COLOR);
-- 				local abbreviationType = SecondsFormatter.Abbreviation.Truncate;
-- 				local formattedTimeString = WorldQuestsSecondsFormatter:Format(timeLeftSeconds, abbreviationType);
-- 				timeLeftString = BONUS_OBJECTIVE_TIME_LEFT:format(formattedTimeString);
-- 				-- local coloredTimeLeftString = timeLeftInfo.color:WrapTextInColorCode(timeLeftString);
-- 			end
-- 			tinsert(activePOIs[expansionID], {poiName, mapInfo.name, timeLeftString});
-- 		end
-- 	end
-- 	return activePOIs;
-- end
-- -- C_Map.GetMapChildrenInfo(1978, Enum.UIMapType.Zone)
-- Test_GetPOIForExpansionMap = util.map.GetPOIForExpansionMap;
-- -- Test_GetPOIForExpansionMap(9, 1978, {7343})

-- function util.map.GetActivePOIsForMap(mapID, otherActivePOIs)
-- 	local activePOIs = otherActivePOIs or {};
-- 	local mapInfo;
-- 	if (type(mapID) =="table") then
-- 		mapInfo = mapID;
-- 	else
-- 		mapInfo = util.map.GetMapInfo(mapID);
-- 	end
-- 	print("Scanning map", mapInfo.mapID, mapInfo.name, "...");
-- 	if (mapInfo.mapType == Enum.UIMapType.Continent) then
-- 		local mapChildren = C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone);
-- 		for _, zoneMapInfo in ipairs(mapChildren) do
-- 			-- local areaPOIs = util.map.GetAreaPOIForMap(zoneMapInfo.mapID);
-- 			-- for i, areaPoiID in ipairs(areaPOIs) do
-- 			-- 	local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapID, areaPoiID);
-- 			-- 	tinsert(activePOIs, {poiName, mapInfo.name, timeLeftString});
-- 			-- end
-- 			-- tinsert(activePOIs, util.map.GetActivePOIsForMap(zoneMapInfo.mapID))
-- 			util.map.GetActivePOIsForMap(zoneMapInfo, activePOIs);
-- 		end
-- 	else
-- 		local areaPOIs = util.map.GetAreaPOIForMap(mapInfo.mapID);
-- 		for i, areaPoiID in ipairs(areaPOIs) do
-- 			local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapInfo.mapID, areaPoiID);
-- 			local poiIcon = util.CreateInlineIcon(poiInfo.atlasName);
-- 			local poiName = poiIcon.." "..poiInfo.name;
-- 			local timeLeftString = '';
-- 			if C_AreaPoiInfo.IsAreaPOITimed(areaPoiID) then
-- 				local timeLeftSeconds = C_AreaPoiInfo.GetAreaPOISecondsLeft(areaPoiID);
-- 				-- local timeLeftColor = util.GetTimeRemainingColorForSeconds(timeLeftSeconds, WHITE_FONT_COLOR);
-- 				local abbreviationType = SecondsFormatter.Abbreviation.Truncate;
-- 				local formattedTimeString = WorldQuestsSecondsFormatter:Format(timeLeftSeconds, abbreviationType);
-- 				timeLeftString = BONUS_OBJECTIVE_TIME_LEFT:format(formattedTimeString);
-- 				-- local coloredTimeLeftString = timeLeftInfo.color:WrapTextInColorCode(timeLeftString);
-- 			end
-- 			tinsert(activePOIs, {poiName, mapInfo.name, timeLeftString});
-- 		end
-- 	end
-- 	return activePOIs;
-- end
-- Test_GetActivePOIsForMap =  util.map.GetActivePOIsForMap;
-- -- Test_GetActivePOIsForMap(1978)

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
