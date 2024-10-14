--------------------------------------------------------------------------------
--[[ poi-10-warwithin.lua - Utility and wrapper functions for handling
-- 							Khaz Algar's World Map events in WoW. ]]--
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
local LocalL10nUtil = ns.L10nUtil;  --> <data\L10nUtils.lua>

-- From <utils\mrbputils.lua>
local LocalPoiUtil = ns.poiUtil;
local LocalMapUtil = ns.mapUtil;
local LocalAchievementUtil = ns.achievement;
local LocalQuestUtil = ns.questUtil;
local util = ns.utilities;

local SPEC_ACTIVE = SPEC_ACTIVE;

--------------------------------------------------------------------------------
----- POI event handler --------------------------------------------------------
--------------------------------------------------------------------------------
-- Quick note on event identifier I chose:
-- 	+ widgetSetIDs - in every area the same, but changes when event status changes (renamed in 11.0.2 to '.tooltipWidgetSet')
--  + areaPoiIDs - in each area different, also changes when event status changes
--  + areaPoiEvents - same as areaPoiIDs but clickable, stay usually in same area
--  + atlasNames - very specific identifier, area independent
--  + vignetteIDs - similar to areaPoiIDs but moving

local LocalPoiData = {};
ns.poi10 = LocalPoiData;  --> for project-wide use


----- Theater Troupe -----

local TheaterTroupeData = {};
TheaterTroupeData.widgetSetID = 1016;
TheaterTroupeData.mapID = 2248;  -- Isle of Dorn
TheaterTroupeData.mapInfo = LocalMapUtil.GetMapInfo(TheaterTroupeData.mapID);
TheaterTroupeData.CompareFunction = LocalPoiUtil.DoesEventDataMatchWidgetSetID;
TheaterTroupeData.includeAreaName = true;
TheaterTroupeData.isMapEvent = true;

TheaterTroupeData.GetNextEventTime = function(self)
	-- The Superbloom event occurs every full hour.
	local now = GetServerTime();
	local waitTimeSeconds = 3600;
	local eventTime = now + C_DateAndTime.GetSecondsUntilDailyReset();
	while eventTime > (now + waitTimeSeconds) do
		eventTime = eventTime - waitTimeSeconds;
	end
	return eventTime - now;
end
TheaterTroupeData.GetTimeLeft = function(self)
	-- The event starts every full hour: 
	--> 5 minutes for preparations before (!) main event (part of normal countdown),
	--> 10 minutes for main event (display as countdown)
	local secondsLeft = self:GetNextEventTime();
	local isActive = (3600-secondsLeft) <= 600;  -- event lasts for 10 minutes
	if (secondsLeft >= 0) then
		local timeLeftSeconds = isActive and (secondsLeft-3000) or secondsLeft;
		local timeLeftInfo = LocalQuestUtil.GetQuestTimeLeftInfo(nil, timeLeftSeconds);
		local timeLeftString = timeLeftInfo and timeLeftInfo.coloredTimeLeftString;
		return timeLeftString, isActive;
	end
end

function LocalPoiData.GetTheaterTroupeInfo()
	local poiInfo = LocalPoiUtil.SingleArea.GetAreaPoiInfo(TheaterTroupeData);
	if poiInfo then
		-- Note: don't save name, it always changes.
        -- Show 'timeString2' only during theater preparations and event duration.
		local timeLeftString, isActive = TheaterTroupeData:GetTimeLeft();
		if (poiInfo.secondsLeft and poiInfo.secondsLeft >= 3300) then
			poiInfo.timeString2 = timeLeftString..util.CreateInlineIcon("activities-clock-standard", 13, 13, 3);
		end
		if isActive then
			poiInfo.isActive = isActive;
			poiInfo.timeString2 = timeLeftString..L.TEXT_DELIMITER..GREEN_FONT_COLOR:WrapTextInColorCode(SPEC_ACTIVE);
		end

		return poiInfo;
	end
end
-- Test_GetTheaterTroupeInfo = LocalPoiData.GetTheaterTroupeInfo;
