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

