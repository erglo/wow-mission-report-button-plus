--------------------------------------------------------------------------------
--[[ landingpagetype.lua - Utilities for handling Landing Page related data. ]]--
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
-- + [ExpansionDocumentation.lua](https://www.townlong-yak.com/framexml/live/Blizzard_APIDocumentationGenerated/ExpansionDocumentation.lua)
-- + [AccountUtil.lua](https://warcraft.wiki.gg/wiki/Console_variables#List_of_Console_Variables)
-- + [Warcraft Wiki - World of Warcraft API, Expansions](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API#Expansions)
-- + [Warcraft Wiki - List of Console Variables](https://warcraft.wiki.gg/wiki/Console_variables#List_of_Console_Variables)
-- 
--------------------------------------------------------------------------------

local AddonID, ns = ...;

local ExpansionInfo = ns.ExpansionInfo;  --> <data\expansion.lua>
local LandingPageInfo = ns.LandingPageInfo;  --> <data\landingpage.lua>

-- Upvalues
local GetCVarBitfield = GetCVarBitfield;

--------------------------------------------------------------------------------

local LocalLandingPageTypeUtil = {};
ns.LandingPageTypeUtil = LocalLandingPageTypeUtil;

LocalLandingPageTypeUtil.currentGarrisonTypeID = 0;
LocalLandingPageTypeUtil.previousGarrisonTypeID = 0;
LocalLandingPageTypeUtil.currentLandingPageTypeID = 0;
LocalLandingPageTypeUtil.previousLandingPageTypeID = 0;

function LocalLandingPageTypeUtil:SetLandingPageGarrisonType(garrisonTypeID)
	-- print("< Set current garrisonTypeID:", garrisonTypeID)
	self.previousGarrisonTypeID = self.currentGarrisonTypeID;
	self.currentGarrisonTypeID = garrisonTypeID;
end

function LocalLandingPageTypeUtil:SetExpansionLandingPageType(landingPageTypeID)
	-- print("< Set current landingPageTypeID:", landingPageTypeID)
	self.previousLandingPageTypeID = self.currentLandingPageTypeID;
	self.currentLandingPageTypeID = landingPageTypeID;
end

function LocalLandingPageTypeUtil:IsValidGarrisonType(garrisonTypeID)
	return (garrisonTypeID and garrisonTypeID > 0);
end

function LocalLandingPageTypeUtil:IsValidExpansionLandingPageType(landingPageTypeID)
	return (landingPageTypeID and landingPageTypeID >= ExpansionInfo.data.DRAGONFLIGHT.landingPageTypeID);
end

-- Verify if given garrison type is available.
function LocalLandingPageTypeUtil:IsGarrisonTypeUnlocked(garrisonTypeID)
	local garrisonInfo = LandingPageInfo:GetGarrisonInfo(garrisonTypeID);
	local isUnlocked = ns.IsLandingPageTypeUnlocked(garrisonInfo.expansionID, garrisonInfo.tagName);

	return isUnlocked;
end

-- Verify if given Expansion Landing Page type is available.
function LocalLandingPageTypeUtil:IsExpansionLandingPageTypeUnlocked(landingPageTypeID)
    return GetCVarBitfield("unlockedExpansionLandingPages", landingPageTypeID);  --> Available since `10.0.2`
end

-- Build and return garrison type ID of previous available expansion.
---@param minimumLevel integer|nil
---@return integer minimumGarrisonTypeID
--
function LocalLandingPageTypeUtil:GetMinimumUnlockedExpansionGarrisonType(minimumLevel)
	local minimumExpansionID = minimumLevel or ExpansionInfo:GetMinimumExpansionLevel();  --> min. available, eg. 8 (Shadowlands)
	if minimumExpansionID < ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID then
		return 0;
	end

	-- Need last attribute, eg. 'Enum.GarrisonType.Type_8_0_Garrison'
	local minimumGarrisonTypeID = Enum.GarrisonType["Type_"..tostring(minimumExpansionID).."_0_Garrison"];

	-- Check if available
	local isMinimumUnlocked = self:IsGarrisonTypeUnlocked(minimumGarrisonTypeID);
	if isMinimumUnlocked then
		self:SetLandingPageGarrisonType(minimumGarrisonTypeID);
		-- print("<-- Found unlocked minimum:", minimumGarrisonTypeID)
		return minimumGarrisonTypeID;
	end

	-- Landing Page not unlocked, yet. Try expansion prior to this one.
	return self:GetMinimumUnlockedExpansionGarrisonType(minimumExpansionID-1);
end

function LocalLandingPageTypeUtil:GetLandingPageModeForLandingPageInfo(landingPageInfo, previousMode)
	-- Case 1: Area w/o a Landing Page  --> Note: Keep previous mode alive.
	if not landingPageInfo then
		-- print("MODE: previous")
		return previousMode;
	end

	-- Case 2: Draenor -> Shadowlands
	if self:IsValidGarrisonType(landingPageInfo.garrisonTypeID) then
		-- print("MODE: Garrison")
		return ExpansionLandingPageMode.Garrison;
	end

	-- Case 3: Dragonflight -> War Within  --> Note: MajorFactionRenown is handled by the game.
	if self:IsValidExpansionLandingPageType(landingPageInfo.landingPageTypeID) then
		-- print("MODE: Overlay")
		return ExpansionLandingPageMode.ExpansionOverlay;
	end
end
