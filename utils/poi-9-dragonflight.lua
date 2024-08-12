--------------------------------------------------------------------------------
--[[ Mission Report Button Plus - Utility and logging functions ]]--
--
-- by erglo <erglo.coder+MRBP@gmail.com>
--
-- Copyright (C) 2021  Erwin D. Glockner (aka erglo, ergloCoder)
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
local LocalL10nUtil = ns.data;  --> <data\labels.lua>

-- <utils\mrbputils.lua>
local LocalPoiUtil = ns.poiUtil;
local LocalMapUtil = ns.mapUtil;
local LocalAchievementUtil = ns.achievement;
local LocalQuestUtil = ns.questUtil;
local util = ns.utilities;

--------------------------------------------------------------------------------
----- POI event handler --------------------------------------------------------
--------------------------------------------------------------------------------

local LocalPoiData = {};
ns.poi9 = LocalPoiData;  --> for project-wide use

-- Tracked achievements
LocalPoiData.achievements = {
	THE_OHN_AHRAN_TRAIL_ID = 16462;
};

----- Camp Aylaag -----	(works in 11.0.0)

local CampAylaagData = {};
CampAylaagData.widgetSetIDs = {718, 719, 720};
CampAylaagData.mapID = 2023;  --> Ohn'ahra
CampAylaagData.mapInfo = LocalMapUtil.GetMapInfo(CampAylaagData.mapID);
CampAylaagData.CompareFunction = LocalPoiUtil.DoesEventDataMatchWidgetSetID;
CampAylaagData.areaIDsMap = {
	["7101"] = nil,    -- River Camp (east), no areaID found
	["7102"] = 13747,  -- Aylaag Outpost
	["7103"] = 14463,  -- Eaglewatch Outpost, Ohn'ahra
};

function LocalPoiData.GetCampAylaagInfo()
	local poiInfo = LocalPoiUtil.SingleArea.GetAreaPoiInfo(CampAylaagData);
	if poiInfo then
		LocalL10nUtil:SaveLabel("showCampAylaagInfo", poiInfo.name);  -- Needed as settings label
		if (poiInfo.areaPoiID == 7101) then
			poiInfo.areaName = L.ENTRYTOOLTIP_DF_CAMP_AYLAAG_AREA_NAME;
		else
			local areaID = CampAylaagData.areaIDsMap[tostring(poiInfo.areaPoiID)];
			poiInfo.areaName = areaID and LocalMapUtil.GetAreaInfo(areaID) or poiInfo.areaName;
		end
		LocalAchievementUtil.AddAchievementData(LocalPoiData.achievements.THE_OHN_AHRAN_TRAIL_ID, poiInfo);

		return poiInfo;
	end
end

----- Iskaara Community Feast ----- (works in 11.0.0)
--
-- REF.: <https://warcraft.wiki.gg/wiki/Community_Feast>
-- REF.: <https://eu.forums.blizzard.com/en/wow/t/weekly-reset-time-changing-to-0500-cet-on-16-november/398498>

local CommunityFeastData = {};
CommunityFeastData.areaPoiID = 7393;
CommunityFeastData.mapID = 2024;  -- Azure Span
CommunityFeastData.mapInfo = LocalMapUtil.GetMapInfo(CommunityFeastData.mapID);
CommunityFeastData.CompareFunction = LocalPoiUtil.DoesEventDataMatchAreaPoiID;
CommunityFeastData.GetNextEventTime = function(self)
	-- The Community Feast event occurs every 90 minutes.
	local now = GetServerTime();
	local feastTime = now + C_DateAndTime.GetSecondsUntilDailyReset();
	while feastTime > (now + 5400) do
		feastTime = feastTime - 5400;
		-- print(date("%y-%m-%d %H:%M:%S", feastTime));
	end
	return feastTime - now;
end
CommunityFeastData.GetTimeLeft = function(self)
	-- The event starts every 90 minutes: 
	--> 15-minutes for meal preparations before cooking starts (part of normal countdown),
	--> 15 minutes while cooking is active (main event) and
	--> 60 minutes of soup time after the main cooking event.
	local secondsLeft = self:GetNextEventTime();
	local isActive = secondsLeft <= 5400 and secondsLeft >= 4500;
	local isSoupReady = secondsLeft < 4500 and secondsLeft > 900;
	-- print("secondsLeft:", secondsLeft);
	-- print("isActive:", isActive, "- isSoupReady:", isSoupReady);
	if (secondsLeft >= 0) then
		local timeLeftInfo = {};
		if isActive then
			timeLeftInfo = LocalQuestUtil.GetQuestTimeLeftInfo(nil, secondsLeft-4500);
		elseif isSoupReady then
			timeLeftInfo = LocalQuestUtil.GetQuestTimeLeftInfo(nil, secondsLeft-900);
			timeLeftInfo.coloredTimeLeftString = WHITE_FONT_COLOR:WrapTextInColorCode(timeLeftInfo.timeString);
		else
			timeLeftInfo = LocalQuestUtil.GetQuestTimeLeftInfo(nil, secondsLeft);
		end
		local timeLeftString = timeLeftInfo and timeLeftInfo.coloredTimeLeftString;
		return timeLeftString, isActive, isSoupReady;
	end
end

-- Community Feast is an event happening in Iskaara in the Azure Span every 90 minutes.
--> REF.: <https://wowpedia.fandom.com/wiki/Community_Feast>
--
function LocalPoiData.GetCommunityFeastInfo()
	local poiInfo = LocalPoiUtil.SingleArea.GetAreaPoiInfo(CommunityFeastData);
	if poiInfo then
		if L:StringIsEmpty(poiInfo.timeString) then
			local timeLeftString, isActive, isSoupReady = CommunityFeastData:GetTimeLeft();
			if timeLeftString then
				local activeTimeLeftString = timeLeftString.." "..GREEN_FONT_COLOR:WrapTextInColorCode(SPEC_ACTIVE);
				poiInfo.timeString = isActive and activeTimeLeftString or timeLeftString;
				poiInfo.timeString = isSoupReady and timeLeftString..util.CreateInlineIcon(4659336, nil, nil, 3) or poiInfo.timeString;
				--> icon: [4659336]="Interface/Icons/INV_Cooking_10_HeartyStew"
			end
		end

		return poiInfo;
	end
end

----- Elemental Storms event ----- (works in 11.0.0)

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
ElementalStormData.mapID = LocalMapUtil.DRAGON_ISLES_MAP_ID;
ElementalStormData.mapInfos = LocalMapUtil.GetMapChildrenInfo(ElementalStormData.mapID, Enum.UIMapType.Zone);
ElementalStormData.CompareFunction = LocalPoiUtil.DoesEventDataMatchAtlasName;
ElementalStormData.SortingFunction = LocalPoiUtil.SortMapIDsAscending;
ElementalStormData.includeAreaName = true;

function LocalPoiData.GetElementalStormsInfo()
	local poiInfos = LocalPoiUtil.MultipleAreas.GetMultipleAreaPoiInfos(ElementalStormData);
	if poiInfos and poiInfos[1] then
		LocalL10nUtil:SaveLabel("showElementalStormsInfo", poiInfos[1].name);
	end

	return poiInfos;
end

----- Fyrakk Assaults ----- (works in 11.0.0)

local FyrakkAssaultsData = {};
FyrakkAssaultsData.widgetSetIDs = {779, 780};
FyrakkAssaultsData.mapID = LocalMapUtil.DRAGON_ISLES_MAP_ID;
FyrakkAssaultsData.mapInfos = LocalMapUtil.GetMapChildrenInfo(FyrakkAssaultsData.mapID, Enum.UIMapType.Zone);
FyrakkAssaultsData.CompareFunction = LocalPoiUtil.DoesEventDataMatchWidgetSetID;
FyrakkAssaultsData.includeAreaName = true;

function LocalPoiData.GetFyrakkAssaultsInfo()
	local poiInfo = LocalPoiUtil.MultipleAreas.GetAreaPoiInfo(FyrakkAssaultsData);
	if poiInfo then
		LocalL10nUtil:SaveLabel("showFyrakkAssaultsInfo", poiInfo.name);

		return poiInfo;
	end
end

----- Dreamsurge ----- (works in 11.0.0)

local DreamsurgeData = {};
DreamsurgeData.atlasName = "dreamsurge_hub-icon";  -- "dreamsurge_fire-portal-icon"   "dreamsurge-world-quest-icon"
DreamsurgeData.mapID = LocalMapUtil.DRAGON_ISLES_MAP_ID;
DreamsurgeData.mapInfos = LocalMapUtil.GetMapChildrenInfo(DreamsurgeData.mapID, Enum.UIMapType.Zone);
DreamsurgeData.CompareFunction = LocalPoiUtil.DoesEventDataMatchAtlasName;
DreamsurgeData.includeAreaName = true;
DreamsurgeData.GetTimeTillNextSurge = function()
	-- A Waking Dream portal opens every 30 minutes with each surge
	local gameTimeHour, gameTimeMinutes = GetLocalGameTime();
	local minutesLeft = gameTimeMinutes <= 30 and (30 - gameTimeMinutes) or (60 - gameTimeMinutes);
	if (minutesLeft >= 0) then
		local timeLeftInfo = LocalQuestUtil.GetQuestTimeLeftInfo(nil, MinutesToSeconds(minutesLeft));
		local timeLeftString = timeLeftInfo and timeLeftInfo.coloredTimeLeftString;
		return timeLeftString;
	end
end

-- Appears each week in one of the four original zones in the Dragon Isles.  
-- Every 30 minutes, a major Waking Dream portal will open in the affected zone as a group event.
--> REF.: <https://worldofwarcraft.blizzard.com/en-us/news/23988136/unite-and-face-the-onslaught-of-the-dreamsurge>
--
function LocalPoiData.GetDreamsurgeInfo()
	local poiInfo = LocalPoiUtil.MultipleAreas.GetAreaPoiInfo(DreamsurgeData);
	if poiInfo then
		LocalL10nUtil:SaveLabel("showDreamsurgeInfo", poiInfo.name);
		-- By default poiInfo.timeString holds the time until the weekly reset,
		-- additionally we are going to show the time until the next Dreamsurge.
		poiInfo.nextSurgeTimeString = DreamsurgeData:GetTimeTillNextSurge();

		return poiInfo;
	end
end

----- Time Rifts ----- (works as map event since 11.0.0)

local TimeRiftData = {};
TimeRiftData.areaPoiID = 7492;
TimeRiftData.mapID = 2025;  -- Thaldraszus
TimeRiftData.mapInfo = LocalMapUtil.GetMapInfo(TimeRiftData.mapID);
TimeRiftData.CompareFunction = LocalPoiUtil.DoesEventDataMatchAreaPoiID;
TimeRiftData.GetTimeLeft = function()
	-- The event starts every hour and lasts for 15 minutes
	local gameTimeHour, gameTimeMinutes = GetLocalGameTime();
	local isActive = gameTimeMinutes <= 15;
	local minutesLeft = isActive and (15 - gameTimeMinutes) or (60 - gameTimeMinutes);
	if (minutesLeft >= 0) then
		local timeLeftInfo = LocalQuestUtil.GetQuestTimeLeftInfo(nil, MinutesToSeconds(minutesLeft));
		local timeLeftString = timeLeftInfo and timeLeftInfo.coloredTimeLeftString;
		return timeLeftString, isActive;
	end
end
TimeRiftData.includeAreaName = true;
TimeRiftData.isMapEvent = true;

function LocalPoiData.GetTimeRiftInfo()
	local poiInfo = LocalPoiUtil.SingleArea.GetAreaPoiInfo(TimeRiftData);
	if poiInfo then
		LocalL10nUtil:SaveLabel("showTimeRiftInfo", poiInfo.name);
		if not poiInfo.isTimed then
			local timeLeftString, isActive = TimeRiftData:GetTimeLeft();
			if timeLeftString then
				local activeTimeLeftString = timeLeftString.." "..GREEN_FONT_COLOR:WrapTextInColorCode(SPEC_ACTIVE);
				poiInfo.timeString = isActive and activeTimeLeftString or timeLeftString;
				poiInfo.isTimed = true;
			end
		end

		return poiInfo;
	end
end
