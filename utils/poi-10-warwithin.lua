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
local LocalL10nUtil = ns.L10nUtil;  --> <data\labels.lua>

-- From <utils\mrbputils.lua>
local LocalPoiUtil = ns.poiUtil;
local LocalMapUtil = ns.mapUtil;
local LocalAchievementUtil = ns.achievement;
local LocalQuestUtil = ns.questUtil;
local util = ns.utilities;

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
