--------------------------------------------------------------------------------
--[[ landingpage.lua - Utilities handling expansion and garrison landing page
--  related data. ]]--
--
-- by erglo <erglo.coder+MRBP@gmail.com>
--
-- Copyright (C) 2024  Erwin D. Glockner (aka ergloCoder)
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

local format = string.format;
local MapUtil = MapUtil;
local C_CovenantCallings = C_CovenantCallings;
local GarrisonFollowerOptions = GarrisonFollowerOptions;

local PlayerInfo = ns.PlayerInfo;  --> <data\player.lua>
local ExpansionInfo = ns.ExpansionInfo;  --> <data\expansion.lua>

----- Helper Functions ---------------------------------------------------------

-- Gather all bounty world quests of given map.
---@param mapID number  A UiMapID of a location from the world map.
---@return BountyInfo[] bounties  A list of currently available bounties
--> REF.: <FrameXML/Blizzard_APIDocumentationGenerated/BountySharedDocumentation.lua><br/>
--
function GetBountiesForMapID(mapID)
	return C_QuestLog.GetBountiesForMapID(mapID);
end

--------------------------------------------------------------------------------

-- Main data table with details about each landing page type
local LandingPageInfo = {};
ns.LandingPageInfo = LandingPageInfo;

function LandingPageInfo:CheckInitialize(expansionID)
    local exampleExpansionID = ExpansionInfo.data.SHADOWLANDS.ID;
    if not self[expansionID or exampleExpansionID] then
        self[ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID] = self:Load_Warlords_of_Draenor();
        self[ExpansionInfo.data.LEGION.ID] = self:Load_Legion();
        self[ExpansionInfo.data.BATTLE_FOR_AZEROTH.ID] = self:Load_Battle_for_Azeroth();
        self[ExpansionInfo.data.SHADOWLANDS.ID] = self:Load_Shadowlands();
        self[ExpansionInfo.data.DRAGONFLIGHT.ID] = self:Load_Dragonflight();
        self[ExpansionInfo.data.WAR_WITHIN.ID] = self:Load_The_War_Within();
    end
end

function LandingPageInfo:GetGarrisonInfo(garrisonTypeID)
    self:CheckInitialize();
    -- Look for garrison types only
    local expansionList = ExpansionInfo:GetExpansionsWithLandingPage();
    for _, expansion in ipairs(expansionList) do
        if (expansion.ID < ExpansionInfo.data.DRAGONFLIGHT.ID and expansion.garrisonTypeID == garrisonTypeID) then
            return self[expansion.ID];
        end
    end
end

function LandingPageInfo:GetGarrisonInfoByFollowerType(followerTypeID, onlyGarrisonTypeID)
    self:CheckInitialize();

    local garrisonTypeID =  GarrisonFollowerOptions[followerTypeID].garrisonType;
    if onlyGarrisonTypeID then
        return garrisonTypeID;
    end
    return self:GetGarrisonInfo(garrisonTypeID);
end

function LandingPageInfo:GetLandingPageInfo(expansionID)
    self:CheckInitialize();

    return self[expansionID];
end

function LandingPageInfo:GetLandingPageInfoByMapID(uiMapID)
    local continentMapInfo = ns.mapUtil:GetContinentMapInfo(uiMapID);
    if not continentMapInfo then return; end

    local expansionList = ExpansionInfo:GetExpansionsWithLandingPage();
    for _, expansion in ipairs(expansionList) do
        if tContains(expansion.continents, continentMapInfo.mapID) then
            return self[expansion.ID];
        end
    end
end

local LocationCache = {};  --> {[mapID] = landingpageInfo, ...}

-- Verify if the player's current area belongs to an expansion continent with a Landing Page.
function LandingPageInfo:GetPlayerLocationLandingPageInfo()
	local mapID = MapUtil.GetDisplayableMapForPlayer();
	-- local mapID = C_Map.GetBestMapForUnit("player");
    -- if not mapID then return; end

    if LocationCache[mapID] then
        return LocationCache[mapID];
    end

	local playerLandingPageInfo = self:GetLandingPageInfoByMapID(mapID);
	if playerLandingPageInfo then
        LocationCache[mapID] = playerLandingPageInfo;
		return playerLandingPageInfo;
	end

	-- -- No Landing Page details for player location found. Keep current one alive.
	-- return LandingPageInfo:GetGarrisonInfo(self.currentGarrisonTypeID);
end

----- Wrapper -----

function LandingPageInfo:IsExpansionLandingPageUnlocked(expansionID)
    -- if (expansionID == ExpansionInfo.data.DRAGONFLIGHT.ID) then
    --     local unlockInfo = {  -- "To the Dragon Isles!"
    --     	["Horde"] = 65444,
    --     	["Alliance"] = 67700,
    --     };
    --     local questID = unlockInfo[PlayerInfo:GetFactionGroupData("tag")];
    --     return questID and C_QuestLog.IsQuestFlaggedCompleted(questID);
    -- end

    -- return C_PlayerInfo.IsExpansionLandingPageUnlockedForPlayer(expansionID);

    local expansionInfo = ExpansionInfo:GetExpansionData(expansionID);

    return  GetCVarBitfield("unlockedExpansionLandingPages", expansionInfo.landingPageTypeID);
end

----- Landing Page Data -----

function LandingPageInfo:Load_Warlords_of_Draenor()
    local playerFactionGroupTag = PlayerInfo:GetFactionGroupData("tag");
    local garrisonFollowerTypeID = Enum.GarrisonFollowerType.FollowerType_6_0_GarrisonFollower;
    local expansionID = ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID;
    return {
        ["garrisonTypeID"] = ExpansionInfo.data.WARLORDS_OF_DRAENOR.garrisonTypeID,
        ["garrisonFollowerTypeID"] = garrisonFollowerTypeID,
        ["tagName"] = playerFactionGroupTag,
        ["title"] = GARRISON_LANDING_PAGE_TITLE,
        ["description"] = MINIMAP_GARRISON_LANDING_PAGE_TOOLTIP,
        ["minimapIcon"] = format("GarrLanding-MinimapIcon-%s-Up", playerFactionGroupTag),
        ["bannerAtlas"] = "accountupgradebanner-wod",  -- 199x117
        ["msg"] = {  --> menu entry tooltip messages
            ["missionsTitle"] = GARRISON_MISSIONS_TITLE,
            ["missionsReadyCount"] = GARRISON_LANDING_COMPLETED,  --> "%d/%d Ready for pickup"
            ["missionsEmptyProgress"] = GARRISON_EMPTY_IN_PROGRESS_LIST,
            ["missionsComplete"] = GarrisonFollowerOptions[garrisonFollowerTypeID].strings.LANDING_COMPLETE or '???',
            ["requirementText"] = ns.GetLandingPageTypeUnlockInfo(expansionID, playerFactionGroupTag).requirementText,
        },
        ["expansionID"] = expansionID,
        ["continents"] = ExpansionInfo.data.WARLORDS_OF_DRAENOR.continents,
        -- ["poiZones"] = {525, 534, 535, 539, 542, 543, 550, 588},  -- Frostfire Ridge, Tanaan Jungle, Taladoor, Shadowmoon Valley, Spires of Arak, Gorgrond, Nagrand, Ashran
        -- No bounties in Draenor; only available since Legion.
    };
end

function LandingPageInfo:Load_Legion()
    local playerClassTag = PlayerInfo:GetClassData("tag");
    local garrisonFollowerTypeID = Enum.GarrisonFollowerType.FollowerType_7_0_GarrisonFollower;
    local expansionID = ExpansionInfo.data.LEGION.ID;
    local mapID = 650;  -- Highmountain
    return {
        ["garrisonTypeID"] = ExpansionInfo.data.LEGION.garrisonTypeID,
        ["garrisonFollowerTypeID"] = garrisonFollowerTypeID,
        ["tagName"] = playerClassTag,
        ["title"] = ORDER_HALL_LANDING_PAGE_TITLE,
        ["description"] = MINIMAP_ORDER_HALL_LANDING_PAGE_TOOLTIP,
        ["minimapIcon"] = playerClassTag == "EVOKER" and "UF-Essence-Icon-Active" or format("legionmission-landingbutton-%s-up", playerClassTag),
        ["bannerAtlas"] = "accountupgradebanner-legion",  -- 199x117
        ["msg"] = {
            ["missionsTitle"] = GARRISON_MISSIONS,
            ["missionsReadyCount"] = GARRISON_LANDING_COMPLETED,
            ["missionsEmptyProgress"] = GARRISON_EMPTY_IN_PROGRESS_LIST,
            ["missionsComplete"] = GarrisonFollowerOptions[garrisonFollowerTypeID].strings.LANDING_COMPLETE,
            ["requirementText"] = ns.GetLandingPageTypeUnlockInfo(expansionID, playerClassTag).requirementText,
        },
        ["expansionID"] = expansionID,
        ["continents"] = ExpansionInfo.data.LEGION.continents,
        ["poiZones"] = {
        	630, 634, 641, 646, 650, 680, 790,  -- Azsuna, Stormheim, Val'sharah, Broken Shore, Highmountain, Suramar, Eye of Azshara
        	830, 882, 885, -- Krokuun, Eredath, Antoran Wastes
        },
        ["bountyBoard"] = {
            ["title"] = BOUNTY_BOARD_LOCKED_TITLE,
            ["noBountiesMessage"] = BOUNTY_BOARD_NO_BOUNTIES_DAYS_1,
            ["isCompleteMessage"] = BOUNTY_TUTORIAL_BOUNTY_FINISHED,
            ["GetBounties"] = function() return GetBountiesForMapID(mapID) end,  --> any child zone from "continents" in Legion seems to work
            ["AreBountiesUnlocked"] = function() return MapUtil.MapHasUnlockedBounties(mapID) end,
        },
    };
end

function LandingPageInfo:Load_Battle_for_Azeroth()
    local playerFactionGroupTag = PlayerInfo:GetFactionGroupData("tag");
    local garrisonFollowerTypeID = Enum.GarrisonFollowerType.FollowerType_8_0_GarrisonFollower;
    local expansionID = ExpansionInfo.data.BATTLE_FOR_AZEROTH.ID;
    local mapID = playerFactionGroupTag == "Horde" and 875 or 876;
    return {
        ["garrisonTypeID"] = ExpansionInfo.data.BATTLE_FOR_AZEROTH.garrisonTypeID,
        ["garrisonFollowerTypeID"] = garrisonFollowerTypeID,
        ["tagName"] = playerFactionGroupTag,
        ["title"] = GARRISON_TYPE_8_0_LANDING_PAGE_TITLE,
        ["description"] = GARRISON_TYPE_8_0_LANDING_PAGE_TOOLTIP,
        ["minimapIcon"] = format("bfa-landingbutton-%s-up", playerFactionGroupTag),
        ["bannerAtlas"] = "accountupgradebanner-bfa",  -- 199x133
        ["msg"] = {
            ["missionsTitle"] = GARRISON_MISSIONS,
            ["missionsReadyCount"] = GARRISON_LANDING_COMPLETED,
            ["missionsEmptyProgress"] = GARRISON_EMPTY_IN_PROGRESS_LIST,
            ["missionsComplete"] = GarrisonFollowerOptions[garrisonFollowerTypeID].strings.LANDING_COMPLETE,
            ["requirementText"] = ns.GetLandingPageTypeUnlockInfo(expansionID, playerFactionGroupTag).requirementText,
        },
        ["expansionID"] = expansionID,
        ["continents"] = ExpansionInfo.data.BATTLE_FOR_AZEROTH.continents,
        ["poiZones"] = {
            62, 14, 1355, 1462, -- Arathi Highlands, Darkshore, Nazjatar, Mechagon
            81, 1527,  -- Silithus, Uldum  --> TODO - Pandaria N'Zoth
        },
        --> Note: Uldum and Vale of Eternal Blossoms are already covered as world map threats.
        ["bountyBoard"] = {
            ["title"] = BOUNTY_BOARD_LOCKED_TITLE,
            ["noBountiesMessage"] = BOUNTY_BOARD_NO_BOUNTIES_DAYS_1,
            ["isCompleteMessage"] = BOUNTY_TUTORIAL_BOUNTY_FINISHED,
            ["GetBounties"] = function() return GetBountiesForMapID(mapID) end,  --> continent map or any child zone seems to work as well
            ["AreBountiesUnlocked"] = function() return MapUtil.MapHasUnlockedBounties(mapID) end,  --> checking only by continent map should be enough
        },
    };
end

function LandingPageInfo:Load_Shadowlands()
    local playerCovenantData = PlayerInfo:GetCovenantData();  --> adds PlayerInfo.activeCovenantID
    local garrisonFollowerTypeID = Enum.GarrisonFollowerType.FollowerType_9_0_GarrisonFollower;
    local expansionID = ExpansionInfo.data.SHADOWLANDS.ID;
    return {
        ["garrisonTypeID"] = ExpansionInfo.data.SHADOWLANDS.garrisonTypeID,
        ["garrisonFollowerTypeID"] = garrisonFollowerTypeID,
        ["tagName"] = PlayerInfo.activeCovenantID,
        ["title"] = GARRISON_TYPE_9_0_LANDING_PAGE_TITLE,
        ["description"] = GARRISON_TYPE_9_0_LANDING_PAGE_TOOLTIP,
        ["minimapIcon"] = format("shadowlands-landingbutton-%s-up", playerCovenantData.textureKit),
        ["bannerAtlas"] = "accountupgradebanner-shadowlands",  -- 199x133
        ["msg"] = {
            ["missionsTitle"] = COVENANT_MISSIONS_TITLE,
            ["missionsReadyCount"] = GARRISON_LANDING_COMPLETED,
            ["missionsEmptyProgress"] = COVENANT_MISSIONS_EMPTY_IN_PROGRESS,
            ["missionsComplete"] = GarrisonFollowerOptions[garrisonFollowerTypeID].strings.LANDING_COMPLETE,
            ["requirementText"] = ns.GetLandingPageTypeUnlockInfo(expansionID, PlayerInfo.activeCovenantID).requirementText,
        },
        ["expansionID"] = expansionID,
        ["continents"] = ExpansionInfo.data.SHADOWLANDS.continents,
        ["poiZones"] = {
            -- 1525, 1533, 1536, 1565, 1543,  -- Revendreth, Bastion, Maldraxxus, Ardenweald, The Maw
            1970, 1961,  -- Zereth Mortis, Korthia
        },
        ["bountyBoard"] = {
            ["title"] = CALLINGS_QUESTS,
            ["noBountiesMessage"] = BOUNTY_BOARD_NO_CALLINGS_DAYS_1,
            ["isCompleteMessage"] = BOUNTY_TUTORIAL_BOUNTY_FINISHED,
            ["GetBounties"] = function() return {} end,  --> Shadowlands callings will be added later via the event handler.
            ["AreBountiesUnlocked"] = function() return C_CovenantCallings.AreCallingsUnlocked() end,
        },
    };
end

function LandingPageInfo:Load_Dragonflight()
    local playerFactionGroupTag = PlayerInfo:GetFactionGroupData("tag");
    local expansionID = ExpansionInfo.data.DRAGONFLIGHT.ID;
    return {
        ["landingPageTypeID"] = ExpansionInfo.data.DRAGONFLIGHT.landingPageTypeID,
        ["garrisonTypeID"] = ExpansionInfo.data.DRAGONFLIGHT.garrisonTypeID,
        ["tagName"] = playerFactionGroupTag,
        ["title"] = DRAGONFLIGHT_LANDING_PAGE_TITLE,
        ["description"] = DRAGONFLIGHT_LANDING_PAGE_TOOLTIP,
        ["minimapIcon"] = "dragonflight-landingbutton-up",
        ["bannerAtlas"] = "accountupgradebanner-dragonflight",  -- 199x133
        ["msg"] = {
            ["requirementText"] = ns.GetLandingPageTypeUnlockInfo(expansionID, playerFactionGroupTag).requirementText,
        },
        ["expansionID"] = expansionID,
        ["continents"] = ExpansionInfo.data.DRAGONFLIGHT.continents,
        ["poiZones"] = {
            2022, 2023, 2024, 2025, 2118,  -- Waking Shores, Ohn'ahran Plains, Azure Span, Thaldraszus, The Forbidden Reach
            2133, 2151, 2200, 2239,  -- Zaralek Cavern, The Forbidden Reach, Emerald Dream, Amirdrassil
        },
        --> Note: The bounty board in Dragonflight is only used for filtering world quests and switching to them. It
        -- doesn't show any bounty details anymore. Instead you get rewards for each new major faction renown level.
	};
end

function LandingPageInfo:Load_The_War_Within()
    local playerFactionGroupTag = PlayerInfo:GetFactionGroupData("tag");
    -- local playerClassTag = PlayerInfo:GetClassData("tag");  --> New allied race: The Earthen.
    local expansionID = ExpansionInfo.data.WAR_WITHIN.ID;
    return {
        ["landingPageTypeID"] = ExpansionInfo.data.WAR_WITHIN.landingPageTypeID,
        ["garrisonTypeID"] = ExpansionInfo.data.WAR_WITHIN.garrisonTypeID,
        ["tagName"] = playerFactionGroupTag,
        ["title"] = WAR_WITHIN_LANDING_PAGE_TITLE,
        ["description"] = WAR_WITHIN_LANDING_PAGE_TOOLTIP,
        ["minimapIcon"] = "warwithin-landingbutton-up",
        ["bannerAtlas"] = "accountupgradebanner-thewarwithin",  -- 199x133
        ["msg"] = {
            ["requirementText"] = ns.GetLandingPageTypeUnlockInfo(expansionID, playerFactionGroupTag).requirementText,
            -- ["majorFactionUnlocked"] = WAR_WITHIN_LANDING_PAGE_ALERT_MAJOR_FACTION_UNLOCKED,
            -- ["summaryUnlocked"] = WAR_WITHIN_LANDING_PAGE_ALERT_SUMMARY_UNLOCKED,
        },
        ["expansionID"] = expansionID,
        ["continents"] = ExpansionInfo.data.WAR_WITHIN.continents,
        ["poiZones"] = nil,
	};
end
