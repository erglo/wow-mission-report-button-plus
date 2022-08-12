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
function util:printVersion(shortVersionOnly)
	local version = GetAddOnMetadata(AddonID, "Version");
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

-- Print garrison related event messages, ie. finished missions/buildings
-- etc. to chat.
function util:cprintEvent(locationName, eventMsg, typeName, instructions, isHyperlink)
	if ( typeName and not isHyperlink ) then
		-- typeName = YELLOW_FONT_COLOR:WrapTextInColorCode(PARENS_TEMPLATE:format(typeName));  --> WoW global string
		typeName = LIGHTYELLOW_FONT_COLOR:WrapTextInColorCode(typeName);
	end
	cprint(DARKYELLOW_FONT_COLOR:WrapTextInColorCode(FROM_A_DUNGEON:format(locationName)),  --> WoW global string
		   eventMsg, typeName and typeName or '', instructions and '|n'..instructions or '');
end

----- Common helper function----------------------------------------------------

function util:tcount(tbl)
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
function util:GetAtlasInfo(atlas)
	local info = C_Texture.GetAtlasInfo(atlas);
	if info then
		local file = info.filename or info.file;
		return file, info.width, info.height, info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord, info.tilesHorizontally, info.tilesVertically;
	end
end

-- REF.: <FrameXML/TextureUtil.lua>
-- REF.: <https://wowpedia.fandom.com/wiki/UI_escape_sequences#Textures>
function util:CreateInlineIcon(atlasNameOrTexID, size, xOffset, yOffset)  --> Returns: string
	size = size or 16;
	xOffset = xOffset or 0;
	yOffset = yOffset or -1;

	local isNumberString = tonumber(atlasNameOrTexID) ~= nil;
	if isNumberString then
		atlasNameOrTexID = tonumber(atlasNameOrTexID);
	end
	if ( type(atlasNameOrTexID) == "number") then
		-- REF.: CreateTextureMarkup(file, fileWidth, fileHeight, width, height, left, right, top, bottom, xOffset, yOffset)
		return CreateTextureMarkup(atlasNameOrTexID, 0, 0, size, size, 0, 0, 0, 0, xOffset, yOffset);  --> keep original color
		-- return string.format("|T%d:%d:%d:%d:%d|t", atlasNameOrTexID, size, size, xOffset, yOffset);
	end
	if ( type(atlasNameOrTexID) == "string" or tonumber(atlasNameOrTexID) ~= nil ) then
		-- REF.: CreateAtlasMarkup(atlasName, width, height, offsetX, offsetY, rVertexColor, gVertexColor, bVertexColor)
		return CreateAtlasMarkup(atlasNameOrTexID, size, size, xOffset, yOffset);  --> keep original color
	end
end
-- util:CreateInlineIcon(314096, 12)  --> new feature icon

----- Data handler -------------------------------------------------------------

-- Collects infos about the current expansion, eg. name, banner, etc.
--> Returns: <table> (attributes: name, expansionLevel, maxLevel, minLevel[, logo, banner])
--
-- REF.: <FrameXML/Blizzard_ClassTrial/Blizzard_ClassTrial.lua>
-- REF.: <FrameXMLBlizzard_APIDocumentation/ExpansionDocumentation.lua>
-- REF.: <FrameXML/GlobalStrings.lua>
-- REF.: <FrameXML/AccountUtil.lua>
function util:GetExpansionInfo(expansionLevel)
	local expansionInfo = {};
	local expansionNames = {
		      -- EXPANSION_NAME0,  --> "Classic"
		nil,  -- EXPANSION_NAME1,  --> "The Burning Crusade"
		nil,  -- EXPANSION_NAME2,  --> "Wrath of the Lich King"
		nil,  -- EXPANSION_NAME3,  --> "Cataclysm"
		nil,  -- EXPANSION_NAME4,  --> "Mists of Pandaria"
		EXPANSION_NAME5,  --> "Warlords of Draenor"
		EXPANSION_NAME6,  --> "Legion"
		EXPANSION_NAME7,  --> "Battle for Azeroth"
		EXPANSION_NAME8,  --> "Shadowlands"
	};

	if not expansionLevel then
		_log:debug("Expansion level not given; using clamped level instead.");
		local currentExpansionLevel = GetClampedCurrentExpansionLevel();
		expansionLevel = currentExpansionLevel;
	end

	expansionInfo.expansionLevel = expansionLevel;
	expansionInfo.name = expansionNames[expansionLevel];
	expansionInfo.maxLevel = GetMaxLevelForExpansionLevel(expansionLevel);
	expansionInfo.minLevel = GetMaxLevelForExpansionLevel(expansionLevel-1);  --> TODO - Check if still needed

	return expansionInfo;
end

-- Check wether the given garrison type has running or completed missions
-- and return the number of those in-progress missions.
--> Returns: 2-array   --> {numInProgress, numCompleted}
--
-- REF.: <FrameXML/Blizzard_APIDocumentation/GarrisonConstantsDocumentation.lua>
-- REF.: <FrameXML/GarrisonBaseUtils.lua>
-- REF.: <FrameXML/Blizzard_GarrisonUI/Blizzard_GarrisonMissionUI.lua>
function util:GetInProgressMissionCount(garrTypeID)
	local numInProgress, numCompleted = 0, 0;
	local missions;

	_log:info("Counting in-progress missions for garrison type", garrTypeID);

	for followerType, followerOptions in pairs(GarrisonFollowerOptions) do
		if (followerOptions.garrisonType == garrTypeID) then
			missions = C_Garrison.GetInProgressMissions(followerType);
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

----- WorldMap and Positioning -------------------------------------------------

-- -- Retrieve the zones of given continent's map ID.
-- --> Returns: <table>
-- --
-- -- REF.: <FrameXML/Blizzard_APIDocumentation/MapDocumentation.lua>
-- function util:GetContinentZones(mapID, allDescendants)
-- 	local infos = {};
-- 	local ALL_DESCENDANTS = allDescendants or false;

-- 	for i, mapInfo in pairs(C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone, ALL_DESCENDANTS)) do
-- 		tinsert(infos, mapInfo);
-- 		-- print(i, mapInfo.mapID, mapInfo.name, "-->", mapInfo.mapType);
-- 	end

-- 	return infos;
-- end


-- Find active threats in the world, if active for current player; eg. the
-- covenant attacks in The Maw or the N'Zoth's attacks in Battle for Azeroth.
--> Returns: <table>
--
-- REF.: <FrameXML/Blizzard_WorldMap/Blizzard_WorldMapTemplates.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentation/QuestTaskInfoDocumentation.lua>
-- REF.: <https://wowpedia.fandom.com/wiki/UI_escape_sequences>
function util:GetActiveWorldMapThreats()
	if C_QuestLog.HasActiveThreats() then
		local threatQuests = C_TaskQuest.GetThreatQuests();
		local activeThreats = {};
		for i, questID in ipairs(threatQuests) do
			if C_TaskQuest.IsActive(questID) then
				local questTitle, factionID = C_TaskQuest.GetQuestInfoByQuestID(questID);
				local typeAtlas =  QuestUtil.GetThreatPOIIcon(questID);
				-- local questLink = string.format("%s|Hquest:%d:-1|h[%s]|h|r", NORMAL_FONT_COLOR_CODE, questID, questTitle);
				-- local questName = util:CreateInlineIcon(typeAtlas)..questLink;
				local questName = util:CreateInlineIcon(typeAtlas)..questTitle;
				local mapID = C_TaskQuest.GetQuestZoneID(questID);
				local mapInfo = C_Map.GetMapInfo(mapID);
				local questExpansionLevel = GetQuestExpansion(questID);
				_log:debug("Threat:", questID, questTitle, ">", mapID, mapInfo.name, "expLvl:", questExpansionLevel);
				if ( not activeThreats[questExpansionLevel] ) then
					-- Add table values per expansion IDs
					activeThreats[questExpansionLevel] = {};
				end
				tinsert(activeThreats[questExpansionLevel], {questID, questName, mapInfo.name});
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
function util:IsTodayWorldQuestDayEvent()
	_log:info("Scanning calendar for day events...");
	local event;
	local eventID_WORLDQUESTS = 613;

	local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime();  --> today
	-- Tests:
	-- currentCalendarTime.monthDay = 15;
	-- currentCalendarTime.weekday = 4;
	-- currentCalendarTime.hour = 5;
	local monthOffset = 0;  --> this month
	local numDayEvents = C_Calendar.GetNumDayEvents(monthOffset, currentCalendarTime.monthDay);
	_log:info("numDayEvents:", numDayEvents);

	for eventIndex = 1, numDayEvents do
		event = C_Calendar.GetDayEvent(monthOffset, currentCalendarTime.monthDay, eventIndex);
		-- _log:debug("eventID:", event.eventID, eventID_WORLDQUESTS, event.eventID == eventID_WORLDQUESTS);

		if ( event.eventID == eventID_WORLDQUESTS ) then
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
