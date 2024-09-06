--------------------------------------------------------------------------------
--[[ dragonriding.lua - Utility and wrapper functions for handling dragonriding in WoW. ]]--
--
-- by erglo <erglo.coder+MRBP@gmail.com>
--
-- Copyright (C) 2024  Erwin D. Glockner (aka erglo)
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see http://www.gnu.org/licenses.
--
--------------------------------------------------------------------------------
--
-- Files used for reference:
-- REF.: [DragonridingUtil.lua](https://www.townlong-yak.com/framexml/live/Blizzard_FrameXMLUtil/DragonridingUtil.lua)
-- 
--------------------------------------------------------------------------------

local AddonID, ns = ...;

local ExpansionInfo = ns.ExpansionInfo;  --> <data\expansion.lua>
local LocalMapUtil = ns.mapUtil;  --> <utils\mrbputils.lua>

--------------------------------------------------------------------------------

local LocalDragonridingUtil = {};
ns.DragonridingUtil = LocalDragonridingUtil;

----- Constants ----------------------------------------------------------------

LocalDragonridingUtil.DRAGONFLIGHT_DRAGONRIDING_QUEST_ID = 68795;  -- "Dragonriding" --> Unlocks ability to ride skyriding mounts.
LocalDragonridingUtil.WAR_WITHIN_SKYRIDING_QUEST_ID = 78533;  -- "Secure the Beach" --> Unlocks Skyriding in Khaz Algar.

----- Wrapper ------------------------------------------------------------------

function LocalDragonridingUtil:IsDragonridingUnlocked()
	return DragonridingUtil.IsDragonridingUnlocked();
end
LocalDragonridingUtil.IsSkyridingUnlocked = LocalDragonridingUtil.IsDragonridingUnlocked;

function LocalDragonridingUtil:ToggleDragonridingTree()
	DragonridingPanelSkillsButtonMixin:OnClick();
end
LocalDragonridingUtil.ToggleSkyridingSkillTree =  LocalDragonridingUtil.ToggleDragonridingTree;

function LocalDragonridingUtil:IsDragonridingTreeOpen()
	return DragonridingUtil.IsDragonridingTreeOpen();
end

function LocalDragonridingUtil:CanSpendDragonridingGlyphs()
	return DragonridingUtil.CanSpendDragonridingGlyphs();
end

----- Data Handler -------------------------------------------------------------


-- Return details about the currency used in the DF dragon riding skill tree.
---@return TreeCurrencyInfo table  A TreeCurrencyInfo table + glyph texture ID
-- REF.: <FrameXML/Blizzard_GenericTraitUI/Blizzard_GenericTraitFrame.lua><br>
-- REF.: <FrameXML/Blizzard_SharedTalentUI/Blizzard_SharedTalentFrame.lua><br>
-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/SharedTraitsDocumentation.lua><br>
-- REF.: [DragonridingUtil.lua](https://www.townlong-yak.com/framexml/live/Blizzard_FrameXMLUtil/DragonridingUtil.lua)
--
function LocalDragonridingUtil:GetDragonRidingTreeCurrencyInfo()				--> TODO - Check if really needed
	local DRAGON_RIDING_TRAIT_CURRENCY_ID = 2563;
	local DRAGON_RIDING_TRAIT_CURRENCY_TEXTURE = 4728198;  -- glyph
	local dragonridingConfigID = C_Traits.GetConfigIDBySystemID(Constants.MountDynamicFlightConsts.TRAIT_SYSTEM_ID);
	local excludeStagedChanges = true;
	local treeCurrencyInfos = C_Traits.GetTreeCurrencyInfo(dragonridingConfigID, Constants.MountDynamicFlightConsts.TREE_ID, excludeStagedChanges);
	local treeCurrencyFallbackInfo = {quantity=0, maxQuantity=0, spent=0, traitCurrencyID=DRAGON_RIDING_TRAIT_CURRENCY_ID};
	-- if (#treeCurrencyInfos <= 0) then return treeCurrencyFallbackInfo; end
	local treeCurrencyInfo = treeCurrencyInfos and treeCurrencyInfos[1] or treeCurrencyFallbackInfo;
	treeCurrencyInfo.texture = DRAGON_RIDING_TRAIT_CURRENCY_TEXTURE;

	return treeCurrencyInfo;
end

-- Count the available dragon glyphs of each zone in Dragonflight.
---@return table glyphsPerZone  {mapName = {numTotal, numComplete}, ...}
---@return integer numGlyphsCollected  The number of glyphs already collected
---@return integer numGlyphsTotal  The number of glyphs on the Dragon Isles altogether
--
function LocalDragonridingUtil:GetDragonGlyphsCount(expansionID)
	local DRAGONRIDING_GLYPH_HUNTER_ACHIEVEMENTS = {
		[tostring(ExpansionInfo.data.DRAGONFLIGHT.ID)] = {
			{mapID = 2022, achievementID = 16575},  -- Waking Shores Glyph Hunter
			{mapID = 2023, achievementID = 16576},  -- Ohn'ahran Plains Glyph Hunter
			{mapID = 2024, achievementID = 16577},  -- Azure Span Glyph Hunter
			{mapID = 2025, achievementID = 16578},  -- Thaldraszus Glyph Hunter
			{mapID = 2151, achievementID = 17411},  -- Forbidden Reach Glyph Hunter
			{mapID = 2133, achievementID = 18150},  -- Zaralek Cavern Glyph Hunter
			{mapID = 2200, achievementID = 19306},  -- Emerald Dream Glyph Hunter
		},
		[tostring(ExpansionInfo.data.WAR_WITHIN.ID)] = {
			{mapID = 2248, achievementID = 40166},  -- Isle of Dorn Glyph Hunter
			{mapID = 2214, achievementID = 40703},  -- The Ringing Deeps Glyph Hunter
			{mapID = 2215, achievementID = 40704},  -- Hallowfall Glyph Hunter
			{mapID = 2255, achievementID = 40705},  -- Azj-Kahet Glyph Hunter
		},
	};
	local achievements = DRAGONRIDING_GLYPH_HUNTER_ACHIEVEMENTS[tostring(expansionID)];

	local glyphsPerZone = {};  -- Glyph count by map ID
	local numGlyphsTotal = 0;  -- The total number of glyphs from all zones
	local numGlyphsCollected = 0;  -- The number of collected glyphs from all zones

	for _, info in ipairs(achievements) do
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
