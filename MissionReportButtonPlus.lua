--------------------------------------------------------------------------------
--[[ Mission Report Button Plus ]]--
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
-- REF.: <FrameXML/Blizzard_APIDocumentation/GarrisonConstantsDocumentation.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentation/GarrisonInfoDocumentation.lua>
-- REF.: <FrameXML/GarrisonBaseUtils.lua>
-- REF.: <FrameXML/Minimap.lua>
-- REF.: <FrameXML/UIParent.lua>
-- REF.: <FrameXML/SharedColorConstants.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentation/CovenantSanctumDocumentation.lua>
-- REF.: <FrameXML/Blizzard_GarrisonTemplates/Blizzard_GarrisonMissionTemplates.lua>
-- REF.: <FrameXML/Blizzard_ExpansionLandingPage/Blizzard_ExpansionLandingPage.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentation/QuestLogDocumentation.lua>
-- (see also the function comments section for more reference)
--
--------------------------------------------------------------------------------

local AddonID, ns = ...
local ShortAddonID = "MRBP"
local L = ns.L
local _log = ns.dbg_logger
local util = ns.utilities

local LibQTip = LibStub('LibQTip-1.0')
local MenuTooltip, ExpansionTooltip, ReputationTooltip
local LocalLibQTipUtil = ns.utils.libqtip
local LocalTooltipUtil = ns.utilities.tooltip

local PlayerInfo = ns.PlayerInfo;  --> <data\player.lua>
local ExpansionInfo = ns.ExpansionInfo;  --> <data\expansion.lua>
local LandingPageInfo = ns.LandingPageInfo;  --> <data\landingpage.lua>
local LabelUtil = ns.data;  --> <data\labels.lua>
local LocalDragonridingUtil = ns.DragonridingUtil  --> <utils\dragonriding.lua>

-- ns.poi9;  --> <utils\poi-9-dragonflight.lua>

local MRBP_EventMessagesCounter = {}
-- Tests
local MRBP_DRAGONRIDING_QUEST_ID = 68795;  --> "Dragonriding"
local MRBP_MAJOR_FACTIONS_QUEST_ID_HORDE = 65444;  --> "To the Dragon Isles!"
local MRBP_MAJOR_FACTIONS_QUEST_ID_ALLIANCE = 67700;  --> "To the Dragon Isles!"

-- Backwards compatibility 
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local LoadAddOn = C_AddOns.LoadAddOn
local CreateAtlasMarkup = CreateAtlasMarkup
local C_QuestLog = C_QuestLog;
local GarrisonFollowerOptions = GarrisonFollowerOptions;
local ExpansionLandingPageMinimapButton = ExpansionLandingPageMinimapButton;

local DIM_RED_FONT_COLOR = DIM_RED_FONT_COLOR
local DISABLED_FONT_COLOR = DISABLED_FONT_COLOR
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR
local RED_FONT_COLOR = RED_FONT_COLOR
local WARNING_FONT_COLOR = WARNING_FONT_COLOR

local TEXT_DELIMITER = ITEM_NAME_DESCRIPTION_DELIMITER;
local TEXT_DASH_SEPARATOR = TEXT_DELIMITER..QUEST_DASH..TEXT_DELIMITER;
local GENERIC_FRACTION_STRING = GENERIC_FRACTION_STRING;

----- Main ---------------------------------------------------------------------

-- Core functions + event listener frame
local MRBP = CreateFrame("Frame", AddonID.."EventListenerFrame")

FrameUtil.RegisterFrameForEvents(MRBP, {
	"ADDON_LOADED",
	"PLAYER_ENTERING_WORLD",
	"PLAYER_QUITING",
	"GARRISON_SHOW_LANDING_PAGE",
	"GARRISON_HIDE_LANDING_PAGE",
	"GARRISON_BUILDING_ACTIVATABLE",
	"GARRISON_MISSION_FINISHED",
	"GARRISON_INVASION_AVAILABLE",
	"GARRISON_TALENT_COMPLETE",
	-- "GARRISON_MISSION_STARTED",  	--> TODO - Track twinks' missions
	"QUEST_TURNED_IN",
	-- "QUEST_AUTOCOMPLETE",
	"COVENANT_CHOSEN",
	"COVENANT_SANCTUM_RENOWN_LEVEL_CHANGED",
	"COVENANT_CALLINGS_UPDATED",
	"MAJOR_FACTION_UNLOCKED",
	}
)

MRBP:SetScript("OnEvent", function(self, event, ...)

		if (event == "ADDON_LOADED") then
			local addOnName = ...

			if (addOnName == AddonID) then
				-- Start add-on action from here
				self:OnLoad()
				self:UnregisterEvent("ADDON_LOADED")
			end

		elseif (event == "PLAYER_QUITING") then
			-- Do some variables clean-up
			LabelUtil:CleanUpLabels()

		elseif (event == "GARRISON_BUILDING_ACTIVATABLE") then
			-- REF. <FrameXML/Blizzard_GarrisonUI/Blizzard_GarrisonLandingPage.lua>
			local buildingName, garrisonType = ...
			_log:debug(event, "buildingName:", buildingName, "garrisonType:", garrisonType)
			-- These messages appear way too often, eg. every time the player teleports somewhere. This counter limits
			-- the number of these messages per log-in session as follows:
			--     1x / log-in session if player was not in garrison zone
			--     1x / garrison
			if (MRBP_EventMessagesCounter[event] == nil) then
				MRBP_EventMessagesCounter[event] = {}
			end
			if (MRBP_EventMessagesCounter[event][garrisonType] == nil) then
				MRBP_EventMessagesCounter[event][garrisonType] = {}
			end

			local buildings = C_Garrison.GetBuildings(garrisonType)
			if buildings then
				for i = 1, #buildings do
					local buildingID = buildings[i].buildingID
					local name, texture, shipmentCapacity = C_Garrison.GetLandingPageShipmentInfo(buildingID)
					if (name == buildingName) then
						_log:debug("building:", buildingID, name)
						-- Add icon to building name
						buildingName = util.CreateInlineIcon(texture).." "..buildingName;
						if (MRBP_EventMessagesCounter[event][garrisonType][buildingID] == nil) then
							MRBP_EventMessagesCounter[event][garrisonType][buildingID] = false
						end
						if (C_Garrison.IsPlayerInGarrison(garrisonType) or MRBP_EventMessagesCounter[event][garrisonType][buildingID] == false) then
							local expansion = ExpansionInfo:GetExpansionDataByGarrisonType(garrisonType);
							util.cprintEvent(expansion.name, GARRISON_BUILDING_COMPLETE, buildingName, GARRISON_FINALIZE_BUILDING_TOOLTIP);
							MRBP_EventMessagesCounter[event][garrisonType][buildingID] = true
						else
							_log:debug("Skipped:", event, garrisonType, buildingID, name)
						end
						break
					end
				end
			end

		elseif (event == "GARRISON_INVASION_AVAILABLE") then
			_log:debug(event, ...)
			--> Draenor garrison only (!)
			local expansionName = ExpansionInfo.data.WARLORDS_OF_DRAENOR.name;
			util.cprintEvent(expansionName, GARRISON_LANDING_INVASION, nil, GARRISON_LANDING_INVASION_TOOLTIP);

		elseif (event == "GARRISON_MISSION_FINISHED") then
			-- REF.: <FrameXML/Blizzard_GarrisonUI/Blizzard_GarrisonMissionUI.lua>
			local followerTypeID, missionID = ...;
			local eventMsg = GarrisonFollowerOptions[followerTypeID].strings.ALERT_FRAME_TITLE;
			local onlyGarrisonTypeID = true;
			local garrisonTypeID = LandingPageInfo:GetGarrisonInfoByFollowerType(followerTypeID, onlyGarrisonTypeID);
			local missionInfo = C_Garrison.GetBasicMissionInfo(missionID);
			if missionInfo then
				local missionLink = C_Garrison.GetMissionLink(missionID)
				local missionIcon = missionInfo.typeTextureKit and missionInfo.typeTextureKit.."-Map" or missionInfo.typeAtlas
				local missionName = util.CreateInlineIcon(missionIcon)..missionLink;
				_log:debug(event, "followerTypeID:", followerTypeID, "missionID:", missionID, missionInfo.name)
				--> TODO - Count and show number of twinks' finished missions ???  --> MRBP_GlobalMissions
				--> TODO - Remove from MRBP_GlobalMissions
				local expansion = ExpansionInfo:GetExpansionDataByGarrisonType(garrisonTypeID);
				util.cprintEvent(expansion.name, eventMsg, missionName, nil, true);
			end

		elseif (event == "GARRISON_TALENT_COMPLETE") then
			local garrisonTypeID, doAlert = ...
			-- _log:debug(event, "garrTypeID:", garrTypeID, "doAlert:", doAlert)
			local followerTypeID = GetPrimaryGarrisonFollowerType(garrisonTypeID)
			local eventMsg = GarrisonFollowerOptions[followerTypeID].strings.TALENT_COMPLETE_TOAST_TITLE
			-- REF. <FrameXML/Blizzard_GarrisonUI/Blizzard_GarrisonLandingPage.lua>
			local talentTreeIDs = C_Garrison.GetTalentTreeIDsByClassID(garrisonTypeID, select(3, UnitClass("player")))
			local completeTalentID = C_Garrison.GetCompleteTalent(garrisonTypeID)
			if (talentTreeIDs) then
				for treeIndex, treeID in ipairs(talentTreeIDs) do
					local treeInfo = C_Garrison.GetTalentTreeInfo(treeID)
					for talentIndex, talent in ipairs(treeInfo.talents) do
						if (talent.researched or talent.id == completeTalentID) then
							-- GetTalentLink(talent.id)
							local nameString = util.CreateInlineIcon(talent.icon).." "..talent.name;
							local expansion = ExpansionInfo:GetExpansionDataByGarrisonType(garrisonTypeID);
							util.cprintEvent(expansion.name, eventMsg, nameString);
						end
					end
				end
			end

		elseif (event == "PLAYER_ENTERING_WORLD") then
			local isInitialLogin, isReloadingUi = ...
			_log:info("isInitialLogin:", isInitialLogin, "- isReloadingUi:", isReloadingUi)

			-- The calendar and its data is not available until it has been opened at least once.
			ToggleCalendar()
			HideUIPanel(CalendarFrame)

			local function printDayEvent()
				_log:debug_type(_log.type.CALENDAR, "Scanning for WORLDQUESTS_EVENT...")
				local dayEvent = util.calendar.GetActiveDayEvent(util.calendar.WORLDQUESTS_EVENT_ID) or util.calendar.GetActiveDayEvent(util.calendar.EASTERN_KINGDOMS_CUP_EVENT_ID)
				local dayEventMsg = util.calendar.GetDayEventChatMessage(dayEvent);
				if dayEventMsg then ns.cprint(dayEventMsg) end;
			end
			if isInitialLogin then
				local addonName = "Blizzard_Calendar"
				local loaded, finished = IsAddOnLoaded(addonName)
				if not ( loaded ) then
					_log:debug("Loading "..addonName)
					local isLoaded, failedReason = LoadAddOn(addonName)
					if failedReason then
						_log:debug(string.format(ADDON_LOAD_FAILED, addonName, _G["ADDON_"..failedReason]))
					end
				end
				C_Timer.After(5, printDayEvent)
				--> FIXME - Not working on first account-login :(
				-- But works after manual UI reload.
			end
			if isReloadingUi then
				printDayEvent()
			end

			-- Check addons which interfere with this one; eg. by messing-up the button hooks
			--> Currently known interference is the right-click menu of `War Plan` by cfxfox
			local interferingAddonIDs = {"WarPlan"}
			local informUser = false  -- avoid informing the user on every single login or reload
			local foundMessage = WARNING_FONT_COLOR:WrapTextInColorCode("Found interfering addon:")
			for _, interferingAddonName in ipairs(interferingAddonIDs) do
				if IsAddOnLoaded(interferingAddonName) then
					local addonTitle = ns.GetAddOnMetadata(interferingAddonName, "Title")
					_log.info(foundMessage, addonTitle)
					self:RedoButtonHooks(informUser)
					return  -- stop at first match
				end
			end

		elseif (event == "QUEST_TURNED_IN") then
			-- REF.: <FrameXML/Blizzard_ExpansionLandingPage/Blizzard_DragonflightLandingPage.lua>
			local questID, xpReward, moneyReward = ...;
			if (questID == MRBP_DRAGONRIDING_QUEST_ID) then
				ns.cprint(DRAGONFLIGHT_LANDING_PAGE_ALERT_DRAGONRIDING_UNLOCKED);
			elseif (questID == MRBP_MAJOR_FACTIONS_QUEST_ID_ALLIANCE or questID == MRBP_MAJOR_FACTIONS_QUEST_ID_HORDE) then
				ns.cprint(DRAGONFLIGHT_LANDING_PAGE_ALERT_SUMMARY_UNLOCKED);
			end

		-- elseif (event == "QUEST_TURNED_IN" or event == "QUEST_AUTOCOMPLETE") then
		-- 	-- REF.: <FrameXML/Blizzard_APIDocumentation/QuestLogDocumentation.lua>
		-- 	-- REF.: <FrameXML/QuestUtils.lua>
		-- 	local questID = ...
		-- 	local questName = QuestUtils_GetQuestName(questID)
		-- 	_log:debug(event, questID, questName)
		-- 	if MRBP_IsQuestGarrisonRequirement(questID) then
		-- 		_log:info("Required quest completed!", questID, questName)
		-- 		--> TODO - Print 'is unlocked/complete' info to chat
		-- 	end

		elseif (event == "GARRISON_SHOW_LANDING_PAGE" or event == "GARRISON_HIDE_LANDING_PAGE") then
			-- print(event, ...)
			if (event == "GARRISON_HIDE_LANDING_PAGE") then
				self:ShowMinimapButton()
			else
				-- Minimap already visible through WoW default process
				if (not ns.settings.showMinimapButton) then
					self:HideMinimapButton()
				end
			end

		elseif (event == "COVENANT_CHOSEN") then
			local covenantID = ...;
			util.covenant.UpdateData(covenantID);

		elseif (event == "COVENANT_SANCTUM_RENOWN_LEVEL_CHANGED") then
			local newRenownLevel, oldRenownLevel = ...;
			ns.cprint(COVENANT_SANCTUM_RENOWN_LEVEL_UNLOCKED:format(newRenownLevel));
			local covenantInfo = util.covenant.GetCovenantInfo();
			local renownInfo = util.covenant.GetRenownData(covenantInfo.ID);
			if renownInfo.hasMaximumRenown then
				local covenantName = covenantInfo.color:WrapTextInColorCode(covenantInfo.name);
				ns.cprint(COVENANT_SANCTUM_RENOWN_REWARD_DESC_COMPLETE:format(covenantName));
			end

		elseif (event == "COVENANT_CALLINGS_UPDATED") then
			-- Updates the Shadowlands "bounty board" infos.
			-- REF.: <FrameXML/ObjectAPI/CovenantCalling.lua>
			-- REF.: <FrameXML/Blizzard_APIDocumentation/CovenantCallingsConstantsDocumentation.lua>
			-- REF.: <FrameXML/Blizzard_APIDocumentation/CovenantCallingsDocumentation.lua>
			--> updates on opening the world map in Shadowlands.
			local callings = ...;
			-- _log:debug("Covenant callings received:", #callings);
			if not LandingPageInfo[ExpansionInfo.data.SHADOWLANDS.ID] then
				LandingPageInfo:Initialize();
			end
			LandingPageInfo[ExpansionInfo.data.SHADOWLANDS.ID].bountyBoard["GetBounties"] = function() return callings end;

		elseif (event == "MAJOR_FACTION_UNLOCKED") then
			-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua>
			local majorFactionID = ...;
			local majorFactionData = util.garrison.GetMajorFactionData(majorFactionID);
			local unlockedMessage = DRAGONFLIGHT_LANDING_PAGE_ALERT_MAJOR_FACTION_UNLOCKED;
			if majorFactionData then
				local majorFactionColor = _G[strupper(majorFactionData.textureKit).."_MAJOR_FACTION_COLOR"];
				unlockedMessage = unlockedMessage..TEXT_DASH_SEPARATOR..majorFactionColor:WrapTextInColorCode(majorFactionData.name);
			end
			ns.cprint(unlockedMessage);
		end
	end
);

-- Load this add-on's functions when the MR minimap button is ready.
function MRBP:OnLoad()
	-- Load data and their handler
	LabelUtil:LoadInGameLabels()
	LandingPageInfo:Initialize();
	-- Prepare quest data for the unlocking requirements
	self:RequestLoadData();

	-- Load settings and interface options
	MRBP_Settings_Register()

	self:RegisterSlashCommands()
	self:SetButtonHooks()

	-- _log:info("----- Addon is ready. -----")
end

----- Data ---------------------------------------------------------------------

-- A collection of quest for (before) unlocking the command table.
--> <questID, questName_English (fallback)>
local MRBP_COMMAND_TABLE_UNLOCK_QUESTS = {
	[ExpansionInfo.data.WARLORDS_OF_DRAENOR.garrisonTypeID] = {
		-- REF.: <https://www.wowhead.com/guides/garrisons/quests-to-unlock-a-level-1-and-level-2-garrison>
		["Horde"] = {34775, "Mission Probable"},  --> wowhead
		["Alliance"] = {34692, "Delegating on Draenor"},  --> Companion App
	},
	[ExpansionInfo.data.LEGION.garrisonTypeID] = {
		["WARRIOR"] = {40585, "Thus Begins the War"},
		["PALADIN"] = {39696, "Rise, Champions"},
		["HUNTER"] = {42519, "Rise, Champions"},
		["ROGUE"] = {42139, "Rise, Champions"},
		["PRIEST"] = {43270, "Rise, Champions"},
		["DEATHKNIGHT"] = {43264, "Rise, Champions"},
		["SHAMAN"] = {42383, "Rise, Champions"},
		["MAGE"] = {42663, "Rise, Champions"},
		["WARLOCK"] = {42608, "Rise, Champions"},
		["MONK"] = {42187, "Rise, Champions"},
		["DRUID"] = {42583, "Rise, Champions"},
		["DEMONHUNTER"] = {42670, "Rise, Champions"},
		["EVOKER"] = {72129, "Aiding Khadgar"},  --> no Class Hall for Evoker (!); talk to Khadgar instead.
	},
	[ExpansionInfo.data.BATTLE_FOR_AZEROTH.garrisonTypeID] = {
		["Horde"] = {51771, "War of Shadows"},
		["Alliance"] = {51715, "War of Shadows"},
	},
	[ExpansionInfo.data.SHADOWLANDS.garrisonTypeID] = {
		[Enum.CovenantType.Kyrian] = {57878, "Choosing Your Purpose"},
		[Enum.CovenantType.Venthyr] = {57878, "Choosing Your Purpose"}, 	--> optional: 59319, "Advancing Our Efforts"
		[Enum.CovenantType.NightFae] = {57878, "Choosing Your Purpose"},	--> optional: 61552, "The Hunt Watches"
		[Enum.CovenantType.Necrolord] = {57878, "Choosing Your Purpose"},
		["alt"] = {62000, "Choosing Your Purpose"},  --> when skipping story mode
	},
	[ExpansionInfo.data.DRAGONFLIGHT.landingPageType] = {
		["Horde"] = {65444, "To the Dragon Isles!"},
		["Alliance"] = {67700, "To the Dragon Isles!"},
		-- ["alt"] = {68798, "Dragon Glyphs and You"},
	},
	[ExpansionInfo.data.WAR_WITHIN.landingPageType] = {						--> TODO - TWW (Note: has same ID as Draenor)
		["Horde"] = {0, UNKNOWN},
		["Alliance"] = {0, UNKNOWN},
		--> New allied race: The Earthen.
	},
}

-- Request data for the unlocking requirement quests; on initial log-in the
-- localized quest titles are not always available. This should help getting
-- the quest details in the language the player has chosen.
function MRBP:RequestLoadData()
	local playerClassTag = PlayerInfo:GetClassData("tag");
	local playerCovenantID = PlayerInfo:GetActiveCovenantID();
	local playerFactionGroupTag = PlayerInfo:GetFactionGroupData("tag");
	local tagNames = {playerFactionGroupTag, playerClassTag, playerCovenantID};
	for garrisonTypeID, questData in pairs(MRBP_COMMAND_TABLE_UNLOCK_QUESTS) do
		-- if not questData then break; end
		for tagName, questTable in pairs(questData) do
			local questID = questTable[1];
			if (questID > 0) then
				if tContains(tagNames, tagName) then
					C_QuestLog.RequestLoadQuestByID(questID);
				end
			end
		end
	end

    -- Note: Shadowlands callings receive info through event listening or on
	-- opening the mission frame; try to update.
	CovenantCalling_CheckCallings();
	--> REF.: <FrameXML/ObjectAPI/CovenantCalling.lua>
end

-- Get quest details of given garrison type for given tag.
--> Returns: table  {questID, questName, requirementText}
local function MRBP_GetGarrisonTypeUnlockQuestInfo(garrTypeID, tagName)
	local reqMessageTemplate = L.TOOLTIP_REQUIREMENTS_TEXT_S  --> same as Companion App text
	local questData = MRBP_COMMAND_TABLE_UNLOCK_QUESTS[garrTypeID] and MRBP_COMMAND_TABLE_UNLOCK_QUESTS[garrTypeID][tagName]
	if not questData then return {requirementText=UNKNOWN}; end
	local questID = questData[1]
	local questFallbackName = questData[2]  --> quest name in English
	local questName = QuestUtils_GetQuestName(questID)

	local questInfo = {}
	questInfo["questID"] = questID
	questInfo["questName"] = strlen(questName) > 0 and questName or questFallbackName
	questInfo["requirementText"] = reqMessageTemplate:format(questInfo.questName)

	return questInfo
end
ns.MRBP_GetGarrisonTypeUnlockQuestInfo = MRBP_GetGarrisonTypeUnlockQuestInfo;

-- Check if given garrison type is unlocked for given tag.
---@param garrTypeID number
---@param tagName string|number
---@return boolean isCompleted
--
local function MRBP_IsGarrisonTypeUnlocked(garrTypeID, tagName)
	local questData = MRBP_COMMAND_TABLE_UNLOCK_QUESTS[garrTypeID][tagName];
	-- if not questData then return true; end

	local questID = questData[1];
	local IsCompleted = C_QuestLog.IsQuestFlaggedCompleted;

	--> FIXME - Temp. work-around (better with achievement of same name ???)
	-- In Shadowlands if you skip the story mode you get a different quest (ID) with the same name, so
	-- we need to check both quests.
	if (garrTypeID == ExpansionInfo.data.SHADOWLANDS.garrisonTypeID) then
		local questID2 = MRBP_COMMAND_TABLE_UNLOCK_QUESTS[garrTypeID]["alt"][1];
		return IsCompleted(questID) or IsCompleted(questID2);
	end

	return IsCompleted(questID);
end

-- Check if the requirement for the given garrison type is met in order to
-- unlock the command table.
-- Note: Currently only the required quest is checked for completion and
--       nothing more. In Shadowlands there would be one more step needed, since
--       2 quest are available for this (see MRBP_IsGarrisonTypeUnlocked).
---@param garrisonTypeID number
---@return boolean|nil isRequirementMet?
---
function MRBP_IsGarrisonRequirementMet(garrisonTypeID)
	local garrisonInfo = LandingPageInfo:GetGarrisonInfo(garrisonTypeID);
	if not garrisonInfo then return false end

	local hasGarrison = util.garrison.HasGarrison(garrisonInfo.garrisonTypeID);
	local isQuestCompleted = MRBP_IsGarrisonTypeUnlocked(garrisonInfo.garrisonTypeID, garrisonInfo.tagName);

	if (garrisonInfo.expansionID >= ExpansionInfo.data.DRAGONFLIGHT.ID) then
		local isUnlocked = C_PlayerInfo.IsExpansionLandingPageUnlockedForPlayer(garrisonInfo.expansionID);
		return isUnlocked or isQuestCompleted;
	end

	return hasGarrison and isQuestCompleted;
end

---Check if at least one garrison is unlocked.
---@return boolean
---
function MRBP_IsAnyGarrisonRequirementMet()
	local expansionList = ExpansionInfo:GetExpansionsWithLandingPage();
	for _, expansion in ipairs(expansionList) do
		local result = MRBP_IsGarrisonRequirementMet(expansion.garrisonTypeID);
		if result then
			return true;
		end
	end

	_log:debug(RED_FONT_COLOR:WrapTextInColorCode("No unlocked garrison available."))
	return false
end
ns.MRBP_IsAnyGarrisonRequirementMet = MRBP_IsAnyGarrisonRequirementMet;

----- Dropdown Menu ------------------------------------------------------------

-- Handle opening and closing of Garrison-/ExpansionLandingPage frames.
---@param garrTypeID number
--
local function MRBP_ToggleLandingPageFrames(garrTypeID)
	local expansion = ExpansionInfo:GetExpansionDataByGarrisonType(garrTypeID);
	-- Always (!) hide the GarrisonLandingPage; all visible UI widgets can only
	-- be loaded properly on opening.
	if (expansion.ID < ExpansionInfo.data.DRAGONFLIGHT.ID) then
		if (ExpansionLandingPage and ExpansionLandingPage:IsShown()) then
			_log:debug("Hiding ExpansionLandingPage");
			HideUIPanel(ExpansionLandingPage);
		end
		if (GarrisonLandingPage == nil) then
			-- Hasn't been opened in this session, yet
			_log:debug("Showing GarrisonLandingPage1 type", garrTypeID);
			ShowGarrisonLandingPage(garrTypeID);
		else
			-- Toggle the GarrisonLandingPage frame; only re-open it
			-- if the garrison type is not the same.
			if (GarrisonLandingPage:IsShown()) then
				_log:debug("Hiding GarrisonLandingPage type", GarrisonLandingPage.garrTypeID);
				HideUIPanel(GarrisonLandingPage);
				if (garrTypeID ~= GarrisonLandingPage.garrTypeID) then
					_log:debug("Showing GarrisonLandingPage2 type", garrTypeID);
					ShowGarrisonLandingPage(garrTypeID);
				end
			else
				_log:debug("Showing GarrisonLandingPage3 type", garrTypeID);
				ShowGarrisonLandingPage(garrTypeID);
			end
		end
	else
		if (GarrisonLandingPage and GarrisonLandingPage:IsShown()) then
			_log:debug("Hiding GarrisonLandingPage1 type", GarrisonLandingPage.garrTypeID);
			HideUIPanel(GarrisonLandingPage);
		end
		-- ToggleExpansionLandingPage();
		ExpansionLandingPageMinimapButton:ToggleLandingPage()
	end
end

----- Menu item tooltip -----

local TOOLTIP_DASH_ICON_ID = 3083385;
-- local TOOLTIP_DASH_ICON_STRING = util.CreateInlineIcon(3083385);
local TOOLTIP_CLOCK_ICON_STRING = util.CreateInlineIcon1("auctionhouse-icon-clock");  -- "worldquest-icon-clock");
-- local TOOLTIP_CHECK_MARK_ICON_STRING = util.CreateInlineIcon(628564);
-- local TOOLTIP_YELLOW_CHECK_MARK_ICON_STRING = util.CreateInlineIcon(130751);
-- local TOOLTIP_GRAY_CHECK_MARK_ICON_STRING = util.CreateInlineIcon(130750);
-- local TOOLTIP_ORANGE_CHECK_MARK_ICON_STRING = util.CreateInlineIcon("Adventures-Checkmark");

--> Note: Don't delete! Used for testing.
local function AddMultiPOITestText(poiInfos, tooltipText)
	if util.TableHasAnyEntries(poiInfos) then
		tooltipText = tooltipText.."|n"
		for _, poi in ipairs(poiInfos) do
			-- Event name
			if poi.atlasName then
				local poiIcon = util.CreateInlineIcon(poi.atlasName)
				tooltipText = tooltipText.."N:"..poiIcon..poi.name
			else
				tooltipText = tooltipText.."N:"..poi.name
			end
			-- POI IDs
			tooltipText = tooltipText.."|n"..GRAY_FONT_COLOR_CODE
			tooltipText = tooltipText.." > "..tostring(poi.areaPoiID)
			tooltipText = tooltipText.." > "..tostring(poi.isPrimaryMapForPOI)
			tooltipText = tooltipText.." > "..tostring(poi.widgetSetID or poi.atlasName or poi.textureIndex or '??')  -- ..tostring(poi.factionID))
			-- tooltipText = tooltipText..FONT_COLOR_CODE_CLOSE
			-- Show description
			if not L:StringIsEmpty(poi.description) then
				tooltipText = tooltipText.."|nD:"..poi.description
			end
			-- Add location name
			if poi.mapInfo then
				tooltipText = tooltipText.."|nM:"..poi.mapInfo.name
				tooltipText = tooltipText.." > "..tostring(poi.mapInfo.mapID)
			end
			-- Add time remaining info
			if (poi.isTimed and poi.timeString)then
				tooltipText = tooltipText.."|nT:"..TOOLTIP_CLOCK_ICON_STRING
				tooltipText = tooltipText.." "..(poi.timeString or '???')
			end
			tooltipText = tooltipText..FONT_COLOR_CODE_CLOSE
			-- Add space between this an previous details
			tooltipText = tooltipText.."|n|n"
		end
	end

	return tooltipText;
end

local function ShouldShowMissionsInfoText(garrisonTypeID)
	local className = select(2, UnitClass("player"));
	return (
		(garrisonTypeID == ExpansionInfo.data.SHADOWLANDS.garrisonTypeID and ns.settings.showCovenantMissionInfo) or
		(garrisonTypeID == ExpansionInfo.data.BATTLE_FOR_AZEROTH.garrisonTypeID and ns.settings.showBfAMissionInfo) or
		(garrisonTypeID == ExpansionInfo.data.LEGION.garrisonTypeID and ns.settings.showLegionMissionInfo and className ~= "EVOKER") or
		(garrisonTypeID == ExpansionInfo.data.WARLORDS_OF_DRAENOR.garrisonTypeID and ns.settings.showWoDMissionInfo)
	);
end

local function ShouldShowBountyBoardText(garrisonTypeID)
	return (
		(garrisonTypeID == ExpansionInfo.data.SHADOWLANDS.garrisonTypeID and ns.settings.showCovenantBounties) or
		(garrisonTypeID == ExpansionInfo.data.BATTLE_FOR_AZEROTH.garrisonTypeID and ns.settings.showBfABounties) or
		(garrisonTypeID == ExpansionInfo.data.LEGION.garrisonTypeID and ns.settings.showLegionBounties)
	);
end

local function ShouldShowActiveThreatsText(garrisonTypeID)
	return (
		(garrisonTypeID == ExpansionInfo.data.SHADOWLANDS.garrisonTypeID and ns.settings.showMawThreats) or
		(garrisonTypeID == ExpansionInfo.data.BATTLE_FOR_AZEROTH.garrisonTypeID and ns.settings.showNzothThreats)
	);
end

-- Check whether the Timewalking Vendor details should be shown.
local function ShouldShowTimewalkingVendorText(expansionInfo)
	if (expansionInfo.ID == ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID) then
		return ns.settings.showWoDWorldMapEvents and ns.settings.showWoDTimewalkingVendor
	end
	if (expansionInfo.ID == ExpansionInfo.data.LEGION.ID) then
		return ns.settings.showLegionWorldMapEvents and ns.settings.showLegionTimewalkingVendor
	end
	return false
end

-- Display the ExpansionLandingPageMinimapButton
function MRBP:ShowMinimapButton(isCalledByUser)
	if (_log.level == _log.DEBUG) then
		ns.cprint("IsShown:", ExpansionLandingPageMinimapButton:IsShown())
		ns.cprint("IsVisible:", ExpansionLandingPageMinimapButton:IsVisible())
		ns.cprint("showMinimapButton:", ns.settings.showMinimapButton)
		ns.cprint("isCalledByUser:", isCalledByUser or false)
		ns.cprint("garrisonType:", MRBP_GetLandingPageGarrisonType())
	end
	if MRBP_IsAnyGarrisonRequirementMet() then
		if (MRBP_GetLandingPageGarrisonType() > 0) then
			if isCalledByUser then
				if ( not ExpansionLandingPageMinimapButton:IsShown() ) then
					ExpansionLandingPageMinimapButton:Show()
					ExpansionLandingPageMinimapButton:UpdateIcon(ExpansionLandingPageMinimapButton)
					-- Manually set by user
					ns.settings.showMinimapButton = true
					_log:debug("--> Minimap button should be visible. (user)")
					-- ns.settings.disableShowMinimapButtonSetting = false
				else
					-- Give user feedback, if button is already visible
					ns.cprint(L.CHATMSG_MINIMAPBUTTON_ALREADY_SHOWN)
				end
			else
				-- Fired by GARRISON_HIDE_LANDING_PAGE event
				if ( ns.settings.showMinimapButton and (not ExpansionLandingPageMinimapButton:IsShown()) )then
					ExpansionLandingPageMinimapButton:UpdateIcon(ExpansionLandingPageMinimapButton)
					ExpansionLandingPageMinimapButton:Show()
					_log:debug("--> Minimap button should be visible. (event)")
					-- ns.settings.disableShowMinimapButtonSetting = false
				end
			end
		end
	end
end

-- Hide the ExpansionLandingPageMinimapButton
function MRBP:HideMinimapButton()
	if ExpansionLandingPageMinimapButton:IsShown() then
		ExpansionLandingPageMinimapButton:Hide()
	end
end
ns.HideMinimapButton = MRBP.HideMinimapButton

-- Handle user action of showing the minimap button. Show it only if any command
-- table is unlocked.
function MRBP:ShowMinimapButton_User(isCalledByCancelFunc)
	local isAnyUnlocked = MRBP_IsAnyGarrisonRequirementMet()
	if (not isAnyUnlocked) then
		-- Do nothing, as long as user hasn't unlocked any of the command tables available
		-- Inform user about this, and disable checkbutton in config.
		ns.cprint(L.CHATMSG_UNLOCKED_COMMANDTABLES_REQUIRED)
		-- ns.settings.disableShowMinimapButtonSetting = true
	else
		local isCalledByUser = not isCalledByCancelFunc
		MRBP:ShowMinimapButton(isCalledByUser)
	end
end
ns.ShowMinimapButton_User = MRBP.ShowMinimapButton_User

----- Hooks --------------------------------------------------------------------

-- Hook the functions related to the landing page's minimap button
-- and frame (mission report frame).
function MRBP:SetButtonHooks()
	if ExpansionLandingPageMinimapButton then
		_log:info("Hooking into the minimap button's tooltip + clicking behavior...")

		-- Minimap button tooltip hook
		ExpansionLandingPageMinimapButton:HookScript("OnEnter", MRBP_OnEnter)

		-- Mouse button hooks; by default only the left button is registered.
		ExpansionLandingPageMinimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
		ExpansionLandingPageMinimapButton:SetScript("OnClick", MRBP_OnClick)
		-- ExpansionLandingPageMinimapButton:HookScript("OnClick", MRBP_OnClick)  --> safer, but doesn't work!
	end

	-- GarrisonLandingPage (mission report frame) post hook
	hooksecurefunc("ShowGarrisonLandingPage", MRBP_ShowGarrisonLandingPage)
end

function MRBP:RedoButtonHooks(informUser)
	self:SetButtonHooks()
	if informUser then
		ns.cprint(L.CHATMSG_MINIMAPBUTTON_HOOKS_UPDATED)
	end
end

-- Handle mouse-over behavior of the minimap button.
-- Note: 'self' refers to the ExpansionLandingPageMinimapButton, the parent frame.
--
-- REF.: <FrameXML/Minimap.xml>
-- REF.: <FrameXML/SharedTooltipTemplates.lua>
function MRBP_OnEnter(self, button, description_only)
	if description_only then
		-- Needed for Addon Compartment details
		return self.description;
	end
	GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	GameTooltip:SetText(self.title, 1, 1, 1);
	GameTooltip:AddLine(self.description, nil, nil, nil, true);

	-- Add right click description
	local tooltipAddonText = L.TOOLTIP_CLICKTEXT_MINIMAPBUTTON;
	if ns.settings.showAddonNameInTooltip then
		local addonAbbreviation = ns.AddonTitleShort..ns.AddonTitleSeparator;
		tooltipAddonText = GRAY_FONT_COLOR:WrapTextInColorCode(addonAbbreviation).." "..tooltipAddonText;
	end
	-- Add special treat
	local dayEvent = util.calendar.GetActiveDayEvent(util.calendar.WINTER_HOLIDAY_EVENT_ID);
	if dayEvent then
		-- Show an icon after the minimap tooltip text during the winter holiday event
		local eventIcon = util.calendar.WINTER_HOLIDAY_ATLAS_NAME;
		tooltipAddonText = tooltipAddonText.." "..util.CreateInlineIcon1(eventIcon);
	end
	GameTooltip_AddNormalLine(GameTooltip, tooltipAddonText);

	-- Add middle click description
	if (self.expansionLandingPageType >= Enum.ExpansionLandingPageType.Dragonflight) then --> TODO - Replace below Enum value with ExpansionInfo.data.DRAGONFLIGHT...
		local tooltipMiddleClickText = L.TOOLTIP_CLICKTEXT2_MINIMAPBUTTON;
		if ns.settings.showAddonNameInTooltip then
			local addonAbbreviation = ns.AddonTitleShort..ns.AddonTitleSeparator;
			tooltipMiddleClickText = GRAY_FONT_COLOR:WrapTextInColorCode(addonAbbreviation).." "..tooltipMiddleClickText;
		end
		GameTooltip_AddNormalLine(GameTooltip, tooltipMiddleClickText);
	end

	GameTooltip:Show();
end

-----

local function MenuLine_OnClick(...)
	-- print("Clicked:", ...)
	local parentLineFrame, lineInfo, buttonName, isUp = ...

	if lineInfo.func then
		lineInfo.func()
	end
end

-- Verify whether the mission-is-completed hint icon should be shown in the menu or not.
---@param garrisonTypeID number
---@return boolean
--
local function ShouldShowMissionCompletedHint(garrisonTypeID)
	if not ns.settings.showMissionCompletedHint then
		return false
	end
	local numInProgress, numCompleted = util.garrison.GetInProgressMissionCount(garrisonTypeID)
	local hasCompletedMissions = numCompleted > 0
	local hasCompletedAllMissions = hasCompletedMissions and numCompleted == numInProgress
	if not ns.settings.showMissionCompletedHintOnlyForAll then
		return hasCompletedMissions
	end
	return hasCompletedAllMissions
end

-- Return suitable information about eg. mission hints for given expansion.
local function GetExpansionHintIconInfo(expansionInfo)
	local missionsAvailable, reputationRewardPending, timeWalkingVendorAvailable = false, false, false;
	if (expansionInfo.ID < ExpansionInfo.data.DRAGONFLIGHT.ID) then
		missionsAvailable = ShouldShowMissionCompletedHint(expansionInfo.garrisonTypeID);
		timeWalkingVendorAvailable = ns.settings.showTimewalkingVendorHint and util.poi.HasTimewalkingVendor(expansionInfo.ID);
	elseif ns.settings.showReputationRewardPendingHint then
		reputationRewardPending = util.garrison.HasMajorFactionReputationReward(expansionInfo.ID);
	end
	return {missionsAvailable, reputationRewardPending, timeWalkingVendorAvailable};
end

local function ShouldShowHintColumn()
	local show = ns.settings.showMissionCompletedHint or ns.settings.showReputationRewardPendingHint or ns.settings.showTimewalkingVendorHint
	return show
end

local settingsAtlasName = "Warfronts-BaseMapIcons-Empty-Workshop-Minimap"

----- LibQTip -----

local uiScale = UIParent:GetEffectiveScale()
-- local screenHeight = GetScreenHeight() * uiScale

-- Release the given `LibQTip.Tooltip`.
---@param tooltip LibQTip.Tooltip
--
local function ReleaseTooltip(tooltip)
	if tooltip then
		LibQTip:Release(tooltip)
		tooltip = nil
	end
end

local function MenuLine_ShowTooltips()
	if (ExpansionTooltip and ExpansionTooltip:GetLineCount() > 0) then
		-- Check if tooltip height fits the screen height
		local screenHeight = GetScreenHeight() * uiScale;  --> needs to be here, not reliable at start-up
		local tooltipHeight = ExpansionTooltip:GetHeight() * uiScale;
		if (tooltipHeight > screenHeight) then
			ExpansionTooltip:UpdateScrolling();
			-- local TOOLTIP_PADDING = 10;										--> TODO - Add to style options
			-- local sizeDifference = tooltipHeight - screenHeight;
			-- ExpansionTooltip:SetHeight(2 * TOOLTIP_PADDING + ExpansionTooltip.height - sizeDifference);
		end
		ExpansionTooltip:SetClampedToScreen(true)
		ExpansionTooltip:Show()
	end
	if (ReputationTooltip and ReputationTooltip:GetLineCount() > 0) then
		ReputationTooltip:Show()
	end
end

-- Create expansion summary content tooltip
local function MenuLine_CreateExpansionTooltip(parentFrame)
	ExpansionTooltip = LibQTip:Acquire(ShortAddonID.."LibQTipExpansionTooltip", 1, "LEFT")
	ExpansionTooltip:SetPoint("LEFT", parentFrame, "RIGHT", -5, 0)
	ExpansionTooltip.OnRelease = ReleaseTooltip
	ExpansionTooltip:SetScrollStep(50)
	ExpansionTooltip:SetFrameLevel(parentFrame:GetFrameLevel() + 10)
end

-- Create (major) faction reputation summary content tooltip
local function MenuLine_CreateReputationTooltip(parentFrame)
	ReputationTooltip = LibQTip:Acquire(ShortAddonID.."LibQTipReputationTooltip", 1, "LEFT")
	ReputationTooltip:SetPoint("BOTTOMRIGHT", ExpansionTooltip, "BOTTOMLEFT", 1, 0)
	ReputationTooltip.OnRelease = ReleaseTooltip
	ReputationTooltip:SetFrameLevel(parentFrame:GetFrameLevel() + 10)
end

local function MenuLine_OnLeave()
	if ( ExpansionTooltip.slider and ExpansionTooltip.slider:IsShown() ) then
		ReleaseTooltip(ExpansionTooltip)
		MenuLine_CreateExpansionTooltip(MenuTooltip)
		if ReputationTooltip then
			ReleaseTooltip(ReputationTooltip)
			MenuLine_CreateReputationTooltip(MenuTooltip)
		end
		return
	end
	if (ExpansionTooltip:GetLineCount() > 0) then
		ExpansionTooltip:Clear()
		ExpansionTooltip:Hide()
	end
	if (ReputationTooltip:GetLineCount() > 0) then
		ReputationTooltip:Clear()
		ReputationTooltip:Hide()
	end
end

-- Expansion summary content
local function MenuLine_OnEnter(...)
	local lineFrame, expansionInfo, _ = ...
	ExpansionTooltip:SetCellMarginV(0)  --> needs to be set every time, since it has been reset by ":Clear()".
	ReputationTooltip:SetCellMarginV(0)											--> TODO - add to style options ???
	-- Tooltip header (title + description)
	local garrisonInfo = LandingPageInfo:GetGarrisonInfo(expansionInfo.garrisonTypeID);
	local isSettingsLine = expansionInfo.ID == nil
	local tooltipTitle = (ns.settings.preferExpansionName and not isSettingsLine) and garrisonInfo.title or expansionInfo.name
	LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, isSettingsLine and expansionInfo.label or tooltipTitle, nil, true)
	local tooltipDescription = expansionInfo.description or garrisonInfo.description
	if tooltipDescription then
		local FontColor = expansionInfo.disabled and DISABLED_FONT_COLOR or NORMAL_FONT_COLOR
		LocalTooltipUtil:AddTextLine(ExpansionTooltip, tooltipDescription, FontColor, ...)
	end
	if isSettingsLine then
		-- Stop here; no content body for the settings line
		MenuLine_ShowTooltips()
		return
	end
	-- Tooltip body
	local isForWarlordsOfDraenor = expansionInfo.ID == ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID
	local isForLegion = expansionInfo.ID == ExpansionInfo.data.LEGION.ID
	local isForBattleForAzeroth = expansionInfo.ID == ExpansionInfo.data.BATTLE_FOR_AZEROTH.ID
	local isForShadowlands = expansionInfo.ID == ExpansionInfo.data.SHADOWLANDS.ID
	local isForDragonflight = expansionInfo.ID == ExpansionInfo.data.DRAGONFLIGHT.ID

	------ Unlocking requirements -----

	-- Moved to next category (see below)
	-- Special treatment for Evoker; they don't have a Class Hall in Legion, hence no mission table.
	if (isForLegion and expansionInfo.disabled) then
		local className = select(2, UnitClass("player"))
		if (className == "EVOKER") then
			LocalLibQTipUtil:AddBlankLineToTooltip(ExpansionTooltip)
			LocalTooltipUtil:AddTextLine(ExpansionTooltip, garrisonInfo.msg.requirementText, DIM_RED_FONT_COLOR)
		end
	end

	----- In-progress missions -----

	if ShouldShowMissionsInfoText(expansionInfo.garrisonTypeID) then
		LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, garrisonInfo.msg.missionsTitle)
		if expansionInfo.disabled then
			-- Show requirement info for unlocking the given expansion type
			LocalTooltipUtil:AddTextLine(ExpansionTooltip, garrisonInfo.msg.requirementText, DIM_RED_FONT_COLOR)
		else
			local shouldShowMissionCompletedMessage = ShouldShowMissionCompletedHint(expansionInfo.garrisonTypeID)
			LocalTooltipUtil:AddGarrisonMissionLines(ExpansionTooltip, garrisonInfo, shouldShowMissionCompletedMessage)
		end
	end

	----- Timewalking Vendor (currently Draenor + Legion only) -----

	if ShouldShowTimewalkingVendorText(expansionInfo) then
		local vendorAreaPoiInfo = util.poi.FindTimewalkingVendor(expansionInfo);
		if vendorAreaPoiInfo then
			LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, vendorAreaPoiInfo.name)
			LocalTooltipUtil:AddIconLine(ExpansionTooltip, vendorAreaPoiInfo.mapInfo.name, vendorAreaPoiInfo.atlasName)
			LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, vendorAreaPoiInfo.timeString)
		end
	end

	----- Warlords of Draenor -----

	if isForWarlordsOfDraenor then
		-- Garrison Invasion
		if (ns.settings.showWoDGarrisonInvasionAlert and util.garrison.IsDraenorInvasionAvailable()) then
			LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, L["showWoDGarrisonInvasionAlert"])
			LocalTooltipUtil:AddIconLine(ExpansionTooltip, GARRISON_LANDING_INVASION_ALERT, "worldquest-tracker-questmarker", WARNING_FONT_COLOR)
			LocalTooltipUtil:AddTextLine(ExpansionTooltip, GARRISON_LANDING_INVASION_TOOLTIP)
		end
		-- Draenor Treasures
		if (ns.settings.showWoDWorldMapEvents and ns.settings.showDraenorTreasures) then
			LocalTooltipUtil:AddDraenorTreasureLines(ExpansionTooltip)
		end
	end

	----- Bounty board infos (Legion + BfA + Shadowlands only) -----

	if ShouldShowBountyBoardText(expansionInfo.garrisonTypeID) then
		LocalTooltipUtil:AddBountyBoardLines(ExpansionTooltip, garrisonInfo)
	end

	----- Legion -----

	if (isForLegion and ns.settings.showLegionWorldMapEvents) then
		-- Legion Invasion
		if ns.settings.showLegionAssaultsInfo then
			local legionAssaultsAreaPoiInfo = util.poi.GetLegionAssaultsInfo()
			if legionAssaultsAreaPoiInfo then
				LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, legionAssaultsAreaPoiInfo.name)
				LocalTooltipUtil:AddIconLine(ExpansionTooltip, legionAssaultsAreaPoiInfo.parentMapInfo.name, legionAssaultsAreaPoiInfo.atlasName, ns.settings.applyInvasionColors and legionAssaultsAreaPoiInfo.color)
				LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, legionAssaultsAreaPoiInfo.timeString)
				LocalTooltipUtil:AddAchievementLine(ExpansionTooltip, legionAssaultsAreaPoiInfo.description, TOOLTIP_DASH_ICON_ID, nil, legionAssaultsAreaPoiInfo.isCompleted)
			end
		end
		-- Demon Invasions (Broken Shores)
		if ns.settings.showBrokenShoreInvasionInfo then
			local demonAreaPoiInfos = util.poi.GetBrokenShoreInvasionInfo()
			if util.TableHasAnyEntries(demonAreaPoiInfos) then
				LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, L["showBrokenShoreInvasionInfo"])
				for _, demonPoi in ipairs(demonAreaPoiInfos) do
					LocalTooltipUtil:AddIconLine(ExpansionTooltip, demonPoi.name, demonPoi.atlasName, ns.settings.applyInvasionColors and demonPoi.color)
					LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, demonPoi.timeString)
				end
			end
		end
		-- Invasion Points (Argus)
		if ns.settings.showArgusInvasionInfo then
			local riftAreaPoiInfos = util.poi.GetArgusInvasionPointsInfo()
			if util.TableHasAnyEntries(riftAreaPoiInfos) then
				LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, L["showArgusInvasionInfo"])
				for _, riftPoi in ipairs(riftAreaPoiInfos) do
					LocalTooltipUtil:AddAchievementLine(ExpansionTooltip, riftPoi.description, riftPoi.atlasName, ns.settings.applyInvasionColors and riftPoi.color, riftPoi.isCompleted)
					LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, riftPoi.mapInfo.name)
					LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, riftPoi.timeString)
				end
			end
		end
	end

	----- World map threats (BfA + Shadowlands) -----

	if ShouldShowActiveThreatsText(expansionInfo.garrisonTypeID) then
		local activeThreats = util.threats.GetActiveThreats()
		local threatData = activeThreats and activeThreats[expansionInfo.ID]
		if threatData then
			local headerName = (
				isForBattleForAzeroth and L["showNzothThreats"] or
				isForShadowlands and L["showMawThreats"] or
				threatData[1].mapInfo.name or  --> for future (yet uncovered) expansions
				UNKNOWN  --> just in case
			)
			local showColor = (
				isForBattleForAzeroth and ns.settings.applyBfAFactionColors or
				isForShadowlands and ns.settings.applyCovenantColors
			)
			LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, headerName)
			for i, threatInfo in ipairs(threatData) do 							--> TODO - Add major-minor assault type icon for N'Zoth Assaults
				LocalTooltipUtil:AddAchievementLine(ExpansionTooltip, threatInfo.questName, threatInfo.atlasName, showColor and threatInfo.color, threatInfo.isCompleted)
				LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, threatInfo.mapInfo.name)
				LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, threatInfo.timeLeftString)
			end
		end
	end

	----- Battle for Azeroth -----

	if isForBattleForAzeroth then
		if (ns.settings.showBfAWorldMapEvents and ns.settings.showBfAFactionAssaultsInfo) then
			local factionAssaultsAreaPoiInfo = util.poi.GetBfAFactionAssaultsInfo()
			if factionAssaultsAreaPoiInfo then
				LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, L["showBfAFactionAssaultsInfo"])
				LocalTooltipUtil:AddIconLine(ExpansionTooltip, factionAssaultsAreaPoiInfo.parentMapInfo.name, factionAssaultsAreaPoiInfo.atlasName, ns.settings.applyBfAFactionColors and factionAssaultsAreaPoiInfo.color)
				LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, factionAssaultsAreaPoiInfo.timeString)
				LocalTooltipUtil:AddAchievementLine(ExpansionTooltip, factionAssaultsAreaPoiInfo.description, TOOLTIP_DASH_ICON_ID, nil, factionAssaultsAreaPoiInfo.isCompleted)
			end
		end
		if ns.settings.showBfAIslandExpeditionsInfo then
			local islandExpeditionInfo = util.poi.GetBfAIslandExpeditionInfo()
			if islandExpeditionInfo then
				LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, L["showBfAIslandExpeditionsInfo"])
				LocalTooltipUtil:AddIconLine(ExpansionTooltip, islandExpeditionInfo.name, islandExpeditionInfo.atlasName)
				local appendedTextColor = islandExpeditionInfo.isCompleted and DISABLED_FONT_COLOR or NORMAL_FONT_COLOR
				local appendedText = appendedTextColor:WrapTextInColorCode( PARENS_TEMPLATE:format(islandExpeditionInfo.fulfilledPercentageString) )
				LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, islandExpeditionInfo.progressText..TEXT_DELIMITER..appendedText, islandExpeditionInfo.isCompleted)
			end
		end
	end

	----- Shadowlands -----

	if (isForShadowlands and ns.settings.showCovenantRenownLevel) then
		local covenantInfo = util.covenant.GetCovenantInfo()
		if util.TableHasAnyEntries(covenantInfo) then
			LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, L["showCovenantRenownLevel"])
			local renownInfo = util.covenant.GetRenownData(covenantInfo.ID)
			if renownInfo then
				local lineText = covenantInfo.name
				local progressText = MAJOR_FACTION_RENOWN_CURRENT_PROGRESS:format(renownInfo.currentRenownLevel, renownInfo.maximumRenownLevel)
				if renownInfo.hasMaximumRenown then
					-- Append max. level after covenant name
					local renownLevelText = MAJOR_FACTION_BUTTON_RENOWN_LEVEL:format(renownInfo.currentRenownLevel)
					lineText = lineText..TEXT_DELIMITER..DISABLED_FONT_COLOR:WrapTextInColorCode(PARENS_TEMPLATE:format(renownLevelText))
					progressText = COVENANT_SANCTUM_RENOWN_REWARD_TITLE_COMPLETE
				end
				LocalTooltipUtil:AddAchievementLine(ExpansionTooltip, lineText, covenantInfo.atlasName, ns.settings.applyCovenantColors and covenantInfo.color, covenantInfo.isCompleted)
				LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, progressText, renownInfo.hasMaximumRenown)
			end
		end
	end

	----- Dragonflight -----

	if isForDragonflight then
		-- Major Factions renown level and progress
		if ns.settings.showMajorFactionRenownLevel then
			local tooltip = ns.settings.separateMajorFactionTooltip and ReputationTooltip or ExpansionTooltip
			LocalTooltipUtil:AddMajorFactionsRenownLines(tooltip, expansionInfo)
		end
		-- Dragon Glyphs
		if ns.settings.showDragonGlyphs then
			LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, L["showDragonGlyphs"])
			LocalTooltipUtil:AddDragonGlyphLines(ExpansionTooltip, expansionInfo.ID)
		end
		----- World Map events -----
		if ns.settings.showDragonflightWorldMapEvents then
			-- Dragonriding Race
			if ns.settings.showDragonRaceInfo then
				local raceAreaPoiInfo = util.poi.GetDragonRaceInfo()
				if raceAreaPoiInfo then
					LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, L["showDragonRaceInfo"])
					LocalTooltipUtil:AddIconLine(ExpansionTooltip, raceAreaPoiInfo.name, raceAreaPoiInfo.atlasName)
					LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, raceAreaPoiInfo.areaName)
					LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, raceAreaPoiInfo.timeString)
					if raceAreaPoiInfo.eventInfo then							--> TODO - Test this for next event
						local iconString = util.CreateInlineIcon(raceAreaPoiInfo.eventInfo.texture, 16, 16, 3, -1)
						LocalTooltipUtil:AddTextLine(ExpansionTooltip, iconString..raceAreaPoiInfo.eventInfo.name)
						LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, raceAreaPoiInfo.eventInfo.timeString)
					end
				end
			end
			-- Camp Aylaag
			if ns.settings.showCampAylaagInfo then
				local campAreaPoiInfo = ns.poi9.GetCampAylaagInfo();
				if campAreaPoiInfo then
					LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, campAreaPoiInfo.name);
					LocalTooltipUtil:AddIconLine(ExpansionTooltip, campAreaPoiInfo.mapInfo.name, campAreaPoiInfo.atlasName);
					LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, campAreaPoiInfo.areaName, campAreaPoiInfo.isCompleted);
					LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, campAreaPoiInfo.timeString and campAreaPoiInfo.timeString or campAreaPoiInfo.description);
				end
			end
			-- Grand Hunts
			if ns.settings.showGrandHuntsInfo then
				local huntsAreaPoiInfo = ns.poi9.GetGrandHuntsInfo();
				if huntsAreaPoiInfo then
					LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, huntsAreaPoiInfo.name);
					LocalTooltipUtil:AddIconLine(ExpansionTooltip, huntsAreaPoiInfo.mapInfo.name, huntsAreaPoiInfo.atlasName);
					LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, huntsAreaPoiInfo.timeString);
				end
			end
			-- Iskaara Community Feast
			if ns.settings.showCommunityFeastInfo then
				local feastAreaPoiInfo = ns.poi9.GetCommunityFeastInfo();
				if feastAreaPoiInfo then
					LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, L["showCommunityFeastInfo"]);
					LocalTooltipUtil:AddIconLine(ExpansionTooltip, feastAreaPoiInfo.mapInfo.name, feastAreaPoiInfo.atlasName);
					LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, feastAreaPoiInfo.name);
					LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, feastAreaPoiInfo.timeString);
				end
			end
			-- Siege on Dragonbane Keep
			if ns.settings.showDragonbaneKeepInfo then
				local siegeAreaPoiInfo = ns.poi9.GetDragonbaneKeepInfo();
				if siegeAreaPoiInfo then
					LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, siegeAreaPoiInfo.name);
					LocalTooltipUtil:AddIconLine(ExpansionTooltip, siegeAreaPoiInfo.mapInfo.name, siegeAreaPoiInfo.atlasName);
					LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, siegeAreaPoiInfo.areaName);
					LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, siegeAreaPoiInfo.timeString);
					if not L:StringIsEmpty(siegeAreaPoiInfo.description) and not ns.settings.hideEventDescriptions then
						LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, siegeAreaPoiInfo.description);

					end
				end
			end
			-- Elemental Storms
			if ns.settings.showElementalStormsInfo then
				local stormsAreaPoiInfos = ns.poi9.GetElementalStormsInfo();
				if util.TableHasAnyEntries(stormsAreaPoiInfos) then
					LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, L["showElementalStormsInfo"]);
					for _, stormPoi in ipairs(stormsAreaPoiInfos) do
						LocalTooltipUtil:AddIconLine(ExpansionTooltip, stormPoi.mapInfo.name, stormPoi.atlasName);
						LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, stormPoi.areaName);
						LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, stormPoi.timeString);
					end
				end
			end
			-- Fyrakk Assaults
			if ns.settings.showFyrakkAssaultsInfo then
				local dfFyrakkAssaultsAreaPoiInfo = ns.poi9.GetFyrakkAssaultsInfo();
				if dfFyrakkAssaultsAreaPoiInfo then
					LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, dfFyrakkAssaultsAreaPoiInfo.name);
					LocalTooltipUtil:AddIconLine(ExpansionTooltip, dfFyrakkAssaultsAreaPoiInfo.mapInfo.name, dfFyrakkAssaultsAreaPoiInfo.atlasName);
					LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, dfFyrakkAssaultsAreaPoiInfo.areaName);
					LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, dfFyrakkAssaultsAreaPoiInfo.timeString);
					if not ns.settings.hideEventDescriptions then
						LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, dfFyrakkAssaultsAreaPoiInfo.description);
					end
				end
			end
			-- Researchers Under Fire
			if ns.settings.showResearchersUnderFireInfo then
				local dfResearchersUnderFireInfo = ns.poi9.GetResearchersUnderFireDataInfo();
				if dfResearchersUnderFireInfo then
					LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, dfResearchersUnderFireInfo.name);
					LocalTooltipUtil:AddIconLine(ExpansionTooltip, dfResearchersUnderFireInfo.mapInfo.name, dfResearchersUnderFireInfo.atlasName);
					LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, dfResearchersUnderFireInfo.areaName);
					LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, dfResearchersUnderFireInfo.timeString);
					if not ns.settings.hideEventDescriptions then
						LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, dfResearchersUnderFireInfo.description);
					end
				end
			end
			-- Time Rifts 
			if ns.settings.showTimeRiftInfo then
				local dfTimeRiftsInfo = ns.poi9.GetTimeRiftInfo();
				if dfTimeRiftsInfo then
					LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, dfTimeRiftsInfo.name);
					LocalTooltipUtil:AddIconLine(ExpansionTooltip, dfTimeRiftsInfo.mapInfo.name, dfTimeRiftsInfo.atlasName);
					LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, dfTimeRiftsInfo.areaName);
					LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, dfTimeRiftsInfo.timeString);
					if not L:StringIsEmpty(dfTimeRiftsInfo.description) and not ns.settings.hideEventDescriptions then
						LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, dfTimeRiftsInfo.description);
						if _log.DEVMODE then print(dfTimeRiftsInfo.name, "-->", dfTimeRiftsInfo.description); end
					end
				end
			end
			-- Dreamsurge
			if ns.settings.showDreamsurgeInfo then
				local dfDreamsurgeInfo = ns.poi9.GetDreamsurgeInfo();
				if dfDreamsurgeInfo then
					LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, L["showDreamsurgeInfo"]);
					LocalTooltipUtil:AddIconLine(ExpansionTooltip, dfDreamsurgeInfo.mapInfo.name, dfDreamsurgeInfo.atlasName);
					LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, dfDreamsurgeInfo.areaName);
					LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, dfDreamsurgeInfo.timeString);
					LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, dfDreamsurgeInfo.nextSurgeTimeString);
				end
			end
			-- Superbloom
			if ns.settings.showSuperbloomInfo then
				local dfSuperbloomInfo = ns.poi9.GetSuperbloomInfo();
				if dfSuperbloomInfo then
					LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, dfSuperbloomInfo.name or L["showSuperbloomInfo"]);
					LocalTooltipUtil:AddIconLine(ExpansionTooltip, dfSuperbloomInfo.mapInfo.name, dfSuperbloomInfo.atlasName);
					LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, dfSuperbloomInfo.areaName);
					LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, dfSuperbloomInfo.timeString);
				end
			end
			-- The Big Dig
			if ns.settings.showTheBigDigInfo then
				local dfTheBigDigInfo = ns.poi9.GetTheBigDigInfo();
				if dfTheBigDigInfo then
					LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, L["showTheBigDigInfo"]);
					LocalTooltipUtil:AddIconLine(ExpansionTooltip, dfTheBigDigInfo.name, dfTheBigDigInfo.atlasName);
					LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, dfTheBigDigInfo.mapInfo.name);
					LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, dfTheBigDigInfo.areaName);
					LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, dfTheBigDigInfo.timeString);
				end
			end
		end
	end

	----- Tests -----

	if (_log.DEVMODE) then
		LocalLibQTipUtil:AddBlankLineToTooltip(ExpansionTooltip)
		LocalTooltipUtil:AddTextLine(ExpansionTooltip, EVENTS_LABEL, DIM_GREEN_FONT_COLOR)
		local tooltipText = ''
		for _, mapID in ipairs(garrisonInfo.continents) do
			local poiInfos = util.map.GetAreaPOIInfoForContinent(mapID)
			tooltipText = AddMultiPOITestText(poiInfos, tooltipText)
			LocalTooltipUtil:AddTextLine(ExpansionTooltip, tooltipText)
		end
		if garrisonInfo.poiZones then
			local zonePoiInfos = util.map.GetAreaPOIInfoForZones(garrisonInfo.poiZones)
			tooltipText = AddMultiPOITestText(zonePoiInfos, tooltipText)
			LocalTooltipUtil:AddTextLine(ExpansionTooltip, tooltipText)
		end
	end

	MenuLine_ShowTooltips()
end

-- REF.: <https://warcraft.wiki.gg/wiki/UIOBJECT_Font>
local function GetCustomFont()
	local newFontName = "Custom"..ns.settings.menuTextFont;
	local fontObject = _G[newFontName] or CreateFont(newFontName);
	fontObject:CopyFontObject(_G[ns.settings.menuTextFont]);

	local fontFile, fontHeight, fontFlags = fontObject:GetFont();
	fontObject:SetFont(fontFile, ns.settings.menuTextFontSize, fontFlags);

	return fontObject;
end

-- REF.: qTip:SetCell(lineNum, colNum, value[, font][, justification][, colSpan][, provider][, leftPadding][, rightPadding][, maxWidth][, minWidth][, ...])
local MenuTooltip_GetCellStyle = function()
	return SafeUnpack({
		GetCustomFont(),                   --> font
		ns.settings.menuTextAlignment,     --> justification
		nil,  --> colSpan
		nil,  --> provider
		ns.settings.menuTextPaddingLeft,   --> leftPadding
		ns.settings.menuTextPaddingRight,  --> rightPadding
		floor(GetScreenWidth()),           --> maxWidth
		ns.settings.menuMinWidth,          --> minWidth
	})
end

local function AddMenuTooltipLine(info)
	local isSettingsLine = info.ID == nil
	local name = info.color and info.color:WrapTextInColorCode(info.label) or info.label
	local lineIndex = MenuTooltip:AddLine('', '', '')
	MenuTooltip:SetCell(lineIndex, 1, info.hintIconInfo, nil, nil, nil, isSettingsLine and ns.TextureCellProvider or ns.HintIconCellProvider)
	MenuTooltip:SetCell(lineIndex, 2, name, MenuTooltip_GetCellStyle())
	MenuTooltip:SetCell(lineIndex, 3, info.minimapIcon, nil, nil, nil, ns.TextureCellProvider)
	if ns.settings.showEntryTooltip then
		MenuTooltip:SetLineScript(lineIndex, "OnEnter", MenuLine_OnEnter, info)
		MenuTooltip:SetLineScript(lineIndex, "OnLeave", MenuLine_OnLeave)
	end
	if info.disabled then
    	MenuTooltip:SetLineTextColor(lineIndex, DISABLED_FONT_COLOR:GetRGBA())
	elseif info.func then
		MenuTooltip:SetLineScript(lineIndex, "OnMouseUp", MenuLine_OnClick, info)
	end
end

-- Create tooltip and display as dropdown menu
local function ShowMenuTooltip(parent)
	MenuTooltip = LibQTip:Acquire(ShortAddonID.."LibQTipMenuTooltip", 3, "CENTER", ns.settings.menuTextAlignment, "CENTER")
	MenuTooltip:SetPoint(ns.settings.menuAnchorPoint, parent, ns.settings.menuAnchorPointParent, ns.settings.menuAnchorOffsetX, ns.settings.menuAnchorOffsetY)
	MenuTooltip:SetAutoHideDelay(0.25, parent)
	MenuTooltip.OnRelease = function(self)
		ReleaseTooltip(self)
		ReleaseTooltip(ExpansionTooltip)
	end
	MenuTooltip:SetCellMarginV(ns.settings.menuLineHeight)
	MenuTooltip:SetFrameLevel(parent:GetFrameLevel() + 10)
	-- Expansion list
	local sortFunc = ns.settings.reverseSortorder and ExpansionInfo.SortAscending or ExpansionInfo.SortDescending
	local expansionList = ExpansionInfo:GetExpansionsWithLandingPage(sortFunc)
	for _, expansionInfo in ipairs(expansionList) do
		local playerOwnsExpansion = ExpansionInfo:DoesPlayerOwnExpansion(expansionInfo.ID)
		local isActiveEntry = tContains(ns.settings.activeMenuEntries, tostring(expansionInfo.ID))  --> user option
		if (playerOwnsExpansion and isActiveEntry) then
			local garrisonInfo = LandingPageInfo:GetGarrisonInfo(expansionInfo.garrisonTypeID)
			local hints = GetExpansionHintIconInfo(expansionInfo)
			expansionInfo.label = ns.settings.preferExpansionName and expansionInfo.name or garrisonInfo.title
			expansionInfo.minimapIcon = ns.settings.showLandingPageIcons and garrisonInfo.minimapIcon or ''
			expansionInfo.disabled = not MRBP_IsGarrisonRequirementMet(expansionInfo.garrisonTypeID)
			expansionInfo.hintIconInfo = ShouldShowHintColumn() and hints
			expansionInfo.color = CreateColorFromHexString(ns.settings["menuTextColor"])
			expansionInfo.func = function() MRBP_ToggleLandingPageFrames(expansionInfo.garrisonTypeID) end
			AddMenuTooltipLine(expansionInfo)
		end
	end
	-- Options
	if tContains(ns.settings.activeMenuEntries, ns.settingsMenuEntry) then
		if (#ns.settings.activeMenuEntries > 1) then
			MenuTooltip:AddSeparator()
		end
		local settingsInfo = {
			label = (not ShouldShowHintColumn() and not ns.settings.showLandingPageIcons) and SETTINGS..util.CreateInlineIcon(settingsAtlasName, 16, 16, 2, -1) or SETTINGS,
			minimapIcon = (not ShouldShowHintColumn() and ns.settings.showLandingPageIcons) and settingsAtlasName or '',
			description = BASIC_OPTIONS_TOOLTIP,
			color = NORMAL_FONT_COLOR,
			hintIconInfo = ShouldShowHintColumn() and settingsAtlasName or '',
			func = function() MRBP_Settings_ToggleSettingsPanel(AddonID) end
		}
		AddMenuTooltipLine(settingsInfo)
	end
	-- Content tooltip
	if ns.settings.showEntryTooltip then
		MenuLine_CreateExpansionTooltip(MenuTooltip)
		MenuLine_CreateReputationTooltip(MenuTooltip)
	end
	MenuTooltip:SetClampedToScreen(true)
	MenuTooltip:Show()
end

local function ToggleMenuTooltip(parent)
	if (MenuTooltip and MenuTooltip:IsShown()) then
		ReleaseTooltip(MenuTooltip)
	else
		ShowMenuTooltip(parent)
	end
end

-- Handle click behavior of the minimap button.
---@param self table  The 'ExpansionLandingPageMinimapButton' itself
---@param button string  Name of the button which has been clicked
---@param isDown boolean  The state of the button, eg. pressed (true) or released (false)
--
function MRBP_OnClick(self, button, isDown)
	-- _log:debug(string.format("Got mouse click: %s, isDown: %s", button, tostring(isDown)))
	if (button == "RightButton") then
		-- New style (LibQTip.Tooltip)
		ToggleMenuTooltip(self);
	elseif (button == "MiddleButton") then										--> TODO - Check for TWW compatibility
		LocalDragonridingUtil:ToggleDragonridingTree();
	else
		-- Pass-through the button click to the original function on LeftButton
		-- click, but hide an eventually already opened landing page frame.
		if (not ExpansionLandingPageMinimapButton.garrisonMode and GarrisonLandingPage and GarrisonLandingPage:IsShown()) then
			HideUIPanel(GarrisonLandingPage);
		end
		ExpansionLandingPageMinimapButton:OnClick(button);
	end
end

-- Fix display errors caused by the WoW 9.x covenant landing page mixin.
---@param garrTypeID number The garrison type ID.
-- REF.: <FrameXML/Blizzard_GarrisonUI/Blizzard_GarrisonLandingPage.lua>
--
function MRBP_ShowGarrisonLandingPage(garrTypeID)
	if (GarrisonLandingPageReport ~= nil) then
		if (garrTypeID ~= ExpansionInfo.data.SHADOWLANDS.garrisonTypeID) then
			-- Quick fix: the covenant missions don't hide some frame parts properly
			GarrisonLandingPageReport.Sections:Hide()
			GarrisonLandingPage.FollowerTab.CovenantFollowerPortraitFrame:Hide()
		else
			GarrisonLandingPageReport.Sections:Show()
		end
	end
	-- Quick fix for the invasion alert badge from the WoD garrison reports
	-- frame on top of the mission report frame now only shows for garrison
	-- missions. Without this it shows on top of every ExpansionLandingPage.
	if  (garrTypeID ~= ExpansionInfo.data.WARLORDS_OF_DRAENOR.garrisonTypeID or ns.settings.hideWoDGarrisonInvasionAlertIcon) and GarrisonLandingPage.InvasionBadge:IsShown() then
		GarrisonLandingPage.InvasionBadge:Hide()
	end
end

-- Return the garrison type of the previous expansion, as long as the most
-- current one hasn't been unlocked.
---@return integer garrTypeID  The landing page garrison type ID
--
-- **Note:** At first log-in this always returns 0 (== no garrison at all).
--
function MRBP_GetLandingPageGarrisonType()
	_log:info("Starting garrison type adjustment...")

	local garrTypeID = MRBP_GetLandingPageGarrisonType_orig();
	_log:debug("Got original garrison type:", garrTypeID)

	if (garrTypeID and garrTypeID > 0 and not MRBP_IsGarrisonRequirementMet(garrTypeID) ) then
		-- Build and return garrison type ID of previous expansion.
		local minExpansionID = ExpansionInfo:GetMinimumExpansionLevel()  --> min. available, eg. 8 (Shadowlands)
		-- Need last attribute of eg. 'Enum.GarrisonType.Type_8_0_Garrison'
		local garrTypeID_Minimum = Enum.GarrisonType["Type_"..tostring(minExpansionID).."_0"]

		if (_log.level == _log.DEBUG) then
			-- Tests
			local playerExpansionID = ExpansionInfo:GetExpansionForPlayerLevel()
			local maxExpansionID = ExpansionInfo:GetMaximumExpansionLevel()  --> max. available, eg. 9 (Dragonflight)
			local garrTypeID_Player = Enum.GarrisonType["Type_"..tostring(playerExpansionID+1).."_0"]
			_log:debug("playerExpansionID:", playerExpansionID)
			_log:debug("maxExpansionID:", maxExpansionID)
			_log:debug("minExpansionID:", minExpansionID)
			_log:debug("garrTypeID_Player:", garrTypeID_Player)
			_log:debug("garrTypeID_Minimum:", garrTypeID_Minimum)
		end

		garrTypeID = garrTypeID_Minimum
	end

	_log:debug("Returning garrison type:", garrTypeID)
	return garrTypeID or 0;
end

--> TODO - Find a more secure way to pre-hook this.
MRBP_GetLandingPageGarrisonType_orig = C_Garrison.GetLandingPageGarrisonType
C_Garrison.GetLandingPageGarrisonType = MRBP_GetLandingPageGarrisonType

--> TODO - Try ExpansionLandingPageMixin:GetLandingPageType()

----- Slash commands -----------------------------------------------------------

local SLASH_CMD_ARGLIST = {
	-- arg, description
	{"chatmsg", L.SLASHCMD_DESC_CHATMSG},
	{"show", L.SLASHCMD_DESC_SHOW},
	{"hide", L.SLASHCMD_DESC_HIDE},
	{"hook", L.SLASHCMD_DESC_HOOK},
	{"config", BASIC_OPTIONS_TOOLTIP},
	{"about", L.CFG_ABOUT_ADDON_LABEL},
}
ns.SLASH_CMD_ARGLIST = SLASH_CMD_ARGLIST;

function MRBP:RegisterSlashCommands()
	_log:info("Registering slash commands...")

	SLASH_MRBP1 = '/mrbp'
	SLASH_MRBP2 = '/missionreportbuttonplus'
	SlashCmdList[ShortAddonID] = function(msg, editbox)
		if (msg ~= '') then
			_log:debug(string.format("Got slash cmd: '%s'", msg))

			if (msg == 'version') then
				local shortVersionOnly = true
				util.printVersion(shortVersionOnly);

			elseif (msg == 'chatmsg') then
				local enabled = ns.settings.showChatNotifications
				if (not enabled) then
					_log.level = _log.USER
					ns.cprint(L.CHATMSG_VERBOSE_S:format(SLASH_MRBP1.." "..SLASH_CMD_ARGLIST[2][1]))
				else
					ns.cprint(L.CHATMSG_SILENT_S:format(SLASH_MRBP1.." "..SLASH_CMD_ARGLIST[2][1]))
					_log.level = _log.NOTSET
				end
				ns.settings.showChatNotifications = not enabled

			elseif (msg == 'config') then
				MRBP_Settings_ToggleSettingsPanel(AddonID);

			elseif (msg == 'tooltip' or msg == 'tip') then
				MRBP_Settings_ToggleSettingsPanel(AddonID.."MenuTooltipSettings");

			elseif (msg == 'about') then
				MRBP_Settings_ToggleSettingsPanel(AddonID.."AboutFrame");

			elseif (msg == 'show') then
				MRBP:ShowMinimapButton_User()

			elseif (msg == 'hide') then
				MRBP:HideMinimapButton()
				-- Manually set by user
				ns.settings.showMinimapButton = false

			elseif (msg == 'hook') then
				local informUser = true
				MRBP:RedoButtonHooks(informUser)

			----- Tests -----
			elseif (msg == 'garrtest') then
				local prev_loglvl = _log.level;
				_log:info("Current GarrisonType:", MRBP_GetLandingPageGarrisonType());
				_log.level = _log.DEBUG;

				local expansionList = ExpansionInfo:GetExpansionsWithLandingPage();
				for _, expansion in ipairs(expansionList) do
					_log:debug(expansion.ID, expansion.garrisonTypeID, YELLOW_FONT_COLOR:WrapTextInColorCode(expansion.name))
					local garrisonInfo = LandingPageInfo:GetGarrisonInfo(expansion.garrisonTypeID);
				    _log:debug("HasGarrison:", util.garrison.HasGarrison(expansion.garrisonTypeID),
							   "- req:", MRBP_IsGarrisonRequirementMet(expansion.garrisonTypeID),
							   "- unlocked:", MRBP_IsGarrisonTypeUnlocked(expansion.garrisonTypeID, garrisonInfo.tagName));
				end

				local playerLevel = UnitLevel("player");
				local expansionLevelForPlayer = ExpansionInfo:GetExpansionForPlayerLevel(playerLevel);
				local playerMaxLevelForExpansion = ExpansionInfo:GetMaxPlayerLevel();
				local expansion = ExpansionInfo:GetExpansionData(expansionLevelForPlayer);

				_log:debug("|nexpansionLevelForPlayer:", expansionLevelForPlayer, ",", expansion.name);
				_log:debug("playerLevel:", playerLevel);
				_log:debug("playerMaxLevelForExpansion:", playerMaxLevelForExpansion);

				_log.level = prev_loglvl;
			end
			---------------------
		else
			-- Print this to chat even if the notifications are disabled
			local prev_loglvl = _log.level;
			_log.level = _log.USER;

			util.printVersion();
			ns.cprint(YELLOW_FONT_COLOR:WrapTextInColorCode(L.CHATMSG_SYNTAX_INFO_S:format(SLASH_MRBP1)).."|n");
			local name, desc;
			for _, info in pairs(SLASH_CMD_ARGLIST) do
				name, desc = SafeUnpack(info);
				print("   "..YELLOW_FONT_COLOR:WrapTextInColorCode(name)..": "..desc);
			end

			_log.level = prev_loglvl;
		end
	end
end

--------------------------------------------------------------------------------
----- Addon Compartment --------------------------------------------------------
--------------------------------------------------------------------------------
--
-- REF.: <https://wowpedia.fandom.com/wiki/Addon_compartment>
-- REF.: <FrameXML/GameTooltip.lua>
-- REF.: <FrameXML/SharedTooltipTemplates.lua>

local TOOLTIP_BAG_ICON_STRING = util.CreateInlineIcon("ParagonReputation_Bag", 13, 15);
local TOOLTIP_BAG_FULL_ICON_STRING = TOOLTIP_BAG_ICON_STRING..util.CreateInlineIcon("ParagonReputation_Checkmark", 14, 12, -9, -1);

-- function MissionReportButtonPlus_OnAddonCompartmentEnter(addonName, button)
function ns.MissionReportButtonPlus_OnAddonCompartmentEnter(button)
	local addonTitle = button.value or ns.AddonTitle;
	local leftOffset = 1;
	local wrapLine = false;
	local tooltip = GameTooltip;

	-- Title + descriptions
	tooltip:SetOwner(button, "ANCHOR_LEFT");
	GameTooltip_SetTitle(tooltip, addonTitle);
	if ExpansionLandingPageMinimapButton then
		-- The description doesn't show up if the ExpansionLandingPageButton doesn't exist
		GameTooltip_AddNormalLine(tooltip, MRBP_OnEnter(ExpansionLandingPageMinimapButton, nil, true), wrapLine);
		util.GameTooltip_AddAtlas(tooltip, "newplayertutorial-icon-mouse-leftbutton");
		GameTooltip_AddNormalLine(tooltip, BASIC_OPTIONS_TOOLTIP);
		util.GameTooltip_AddAtlas(tooltip, "newplayertutorial-icon-mouse-rightbutton");
		-- if MRBP_IsGarrisonRequirementMet(Enum.ExpansionLandingPageType.Dragonflight) then
		if (ExpansionLandingPageMinimapButton.expansionLandingPageType >= Enum.ExpansionLandingPageType.Dragonflight) then
			GameTooltip_AddNormalLine(tooltip, GENERIC_TRAIT_FRAME_DRAGONRIDING_TITLE..TEXT_DASH_SEPARATOR..LANDING_DRAGONRIDING_PANEL_SUBTITLE);
			util.GameTooltip_AddAtlas(tooltip, "newplayertutorial-icon-mouse-middlebutton");
		end
		-- GameTooltip_AddBlankLineToTooltip(tooltip);
	end

	-- Display data for each expansion
	local sortFunc = ns.settings.reverseSortorder and ExpansionInfo.SortAscending or ExpansionInfo.SortDescending;
	local expansionList = ExpansionInfo:GetExpansionsWithLandingPage(sortFunc);
	local activeThreats = util.threats.GetActiveThreats();

	for _, expansion in ipairs(expansionList) do
		local garrisonInfo = LandingPageInfo:GetGarrisonInfo(expansion.garrisonTypeID);
		garrisonInfo.shouldShowDisabled = not MRBP_IsGarrisonRequirementMet(expansion.garrisonTypeID);
		local playerOwnsExpansion = ExpansionInfo:DoesPlayerOwnExpansion(expansion.ID);
		local isActiveEntry = tContains(ns.settings.activeMenuEntries, tostring(expansion.ID)); --> user option
		garrisonInfo.missions = {};
		garrisonInfo.missions.numInProgress, garrisonInfo.missions.numCompleted = util.garrison.GetInProgressMissionCount(expansion.garrisonTypeID);

		if (playerOwnsExpansion and isActiveEntry) then
			if garrisonInfo.shouldShowDisabled then
				GameTooltip_AddDisabledLine(tooltip, expansion.name);
				util.GameTooltip_AddAtlas(tooltip, garrisonInfo.minimapIcon, 36, 36, Enum.TooltipTextureAnchor.RightCenter);
				GameTooltip_AddErrorLine(tooltip, garrisonInfo.msg.requirementText, nil, leftOffset);
			else
				-- Expansion name
				GameTooltip_AddHighlightLine(tooltip, expansion.name);
				util.GameTooltip_AddAtlas(tooltip, garrisonInfo.minimapIcon, 36, 36, Enum.TooltipTextureAnchor.RightCenter);
				-- Major Factions
				local majorFactionData = util.garrison.GetAllMajorFactionDataForExpansion(expansion.ID);
				if util.TableHasAnyEntries(majorFactionData) then
					for _, factionData in ipairs(majorFactionData) do
						if factionData.isUnlocked then
							local factionAtlasName = "MajorFactions_MapIcons_"..factionData.textureKit.."64";
							local factionColor = util.garrison.GetMajorFactionColor(factionData);  -- WHITE_FONT_COLOR
							local renownLevelText = factionColor:WrapTextInColorCode(MAJOR_FACTION_BUTTON_RENOWN_LEVEL:format(factionData.renownLevel));
							local levelThreshold = factionData.renownLevelThreshold;
							local reputationEarned = factionData.renownReputationEarned;
							local suffixText = '';
							local isParagon = util.garrison.IsFactionParagon(factionData.factionID);
							if isParagon then
								local paragonInfo = util.garrison.GetFactionParagonInfo(factionData.factionID);
								local value = mod(paragonInfo.currentValue, paragonInfo.threshold);
								levelThreshold = paragonInfo.threshold;
								reputationEarned = paragonInfo.hasRewardPending and value + paragonInfo.threshold or value;
								local bagIconString = paragonInfo.hasRewardPending and TOOLTIP_BAG_FULL_ICON_STRING or TOOLTIP_BAG_ICON_STRING;
								suffixText = TEXT_DELIMITER..bagIconString;
							end
							local reputationLevelText = GENERIC_FRACTION_STRING:format(reputationEarned, levelThreshold);
							local lineText = format("%s: %s - %s", factionData.name, renownLevelText, HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(reputationLevelText));
							local hasMaxRenown = util.garrison.HasMaximumMajorFactionRenown(factionData.factionID);
							util.GameTooltip_AddObjectiveLine(tooltip, lineText..suffixText, hasMaxRenown, wrapLine, leftOffset, factionAtlasName);
						end
					end
				end
				-- Dragon Glyphs
				if (expansion.ID == ExpansionInfo.data.DRAGONFLIGHT.ID) then
					local treeCurrencyInfo = LocalDragonridingUtil:GetDragonRidingTreeCurrencyInfo();
					local glyphsPerZone, numGlyphsCollected, numGlyphsTotal = LocalDragonridingUtil:GetDragonGlyphsCount(expansion.ID);
					local collectedAmountString = WHITE_FONT_COLOR:WrapTextInColorCode(GENERIC_FRACTION_STRING:format(numGlyphsCollected, numGlyphsTotal));
					local isCompleted = numGlyphsCollected == numGlyphsTotal;
					util.GameTooltip_AddObjectiveLine(tooltip, L["showDragonGlyphs"]..": "..collectedAmountString, isCompleted, wrapLine, leftOffset, treeCurrencyInfo.texture);
					-- Dragonriding Race
					if ns.settings.showDragonRaceInfo then
						local raceAreaPoiInfo = util.poi.GetDragonRaceInfo()
						if raceAreaPoiInfo then
							local timeLeft = raceAreaPoiInfo.timeString or "...";
							local lineText = raceAreaPoiInfo.name..": "..timeLeft
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, raceAreaPoiInfo.atlasName)
							if raceAreaPoiInfo.eventInfo then
								local lineTextEvent = raceAreaPoiInfo.eventInfo.name..": "..raceAreaPoiInfo.eventInfo.timeString
								util.GameTooltip_AddObjectiveLine(tooltip, lineTextEvent, nil, wrapLine, leftOffset, raceAreaPoiInfo.atlasName)
							end
						end
					end
					-- Camp Aylaag
					if ns.settings.showCampAylaagInfo then
						local campAreaPoiInfo = ns.poi9.GetCampAylaagInfo();
						if campAreaPoiInfo then
							local timeLeft = campAreaPoiInfo.timeString or "...";
							local lineText = format("%s @ %s", campAreaPoiInfo.name, campAreaPoiInfo.areaName)..": "..timeLeft;
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, campAreaPoiInfo.isCompleted, wrapLine, leftOffset, campAreaPoiInfo.atlasName);
						end
					end
					-- Grand Hunts
					if ns.settings.showGrandHuntsInfo then
						local huntsAreaPoiInfo = ns.poi9.GetGrandHuntsInfo();
						if huntsAreaPoiInfo then
							local timeLeft = huntsAreaPoiInfo.timeString or "...";
							local lineText = format("%s @ %s", huntsAreaPoiInfo.name, huntsAreaPoiInfo.mapInfo.name)..": "..timeLeft;
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, huntsAreaPoiInfo.atlasName);
						end
					end
					-- Iskaara Community Feast
					if ns.settings.showCommunityFeastInfo then
						local feastAreaPoiInfo = ns.poi9.GetCommunityFeastInfo();
						if feastAreaPoiInfo then
							local timeLeft = feastAreaPoiInfo.timeString or "...";
							local lineText = format("%s @ %s", L["showCommunityFeastInfo"], feastAreaPoiInfo.name)..": "..timeLeft;
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, feastAreaPoiInfo.atlasName);
						end
					end
					-- Siege on Dragonbane Keep
					if ns.settings.showDragonbaneKeepInfo then
						local siegeAreaPoiInfo = ns.poi9.GetDragonbaneKeepInfo();
						if siegeAreaPoiInfo then
							local timeLeft = siegeAreaPoiInfo.timeString or "...";
							local lineText = siegeAreaPoiInfo.name..": "..timeLeft;
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, siegeAreaPoiInfo.atlasName);
						end
					end
					-- Elemental Storms
					if ns.settings.showElementalStormsInfo then
						local stormsAreaPoiInfos = ns.poi9.GetElementalStormsInfo();
						if util.TableHasAnyEntries(stormsAreaPoiInfos) then
							for _, stormPoi in ipairs(stormsAreaPoiInfos) do
								local timeLeft = stormPoi.timeString or "...";
								local lineText = format("%s @ %s", stormPoi.name, stormPoi.mapInfo.name)..": "..timeLeft;
								util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, stormPoi.atlasName);
							end
						end
					end
					-- Fyrakk Assaults
					if ns.settings.showFyrakkAssaultsInfo then
						local dfFyrakkAssaultsAreaPoiInfo = ns.poi9.GetFyrakkAssaultsInfo();
						if dfFyrakkAssaultsAreaPoiInfo then
							local timeLeft = dfFyrakkAssaultsAreaPoiInfo.timeString or "...";
							local lineText = format("%s @ %s", dfFyrakkAssaultsAreaPoiInfo.name, dfFyrakkAssaultsAreaPoiInfo.mapInfo.name)..": "..timeLeft;
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, dfFyrakkAssaultsAreaPoiInfo.atlasName);
						end
					end
					-- Researchers Under Fire
					if ns.settings.showResearchersUnderFireInfo then
						local dfResearchersUnderFireInfo = ns.poi9.GetResearchersUnderFireDataInfo();
						if dfResearchersUnderFireInfo then
							local timeLeft = dfResearchersUnderFireInfo.timeString or "...";
							local lineText = dfResearchersUnderFireInfo.name..": "..timeLeft;
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, dfResearchersUnderFireInfo.atlasName);
						end
					end
					-- Time Rifts 
					if ns.settings.showTimeRiftInfo then
						local dfTimeRiftsInfo = ns.poi9.GetTimeRiftInfo();
						if dfTimeRiftsInfo then
							local timeLeft = dfTimeRiftsInfo.timeString or "...";
							local lineText = format("%s @ %s", dfTimeRiftsInfo.name, dfTimeRiftsInfo.mapInfo.name)..": "..timeLeft;
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, dfTimeRiftsInfo.atlasName);
						end
					end
					-- Dreamsurge
					if ns.settings.showDreamsurgeInfo then
						local dfDreamsurgeInfo = ns.poi9.GetDreamsurgeInfo();
						if dfDreamsurgeInfo then
							local timeLeft = dfDreamsurgeInfo.nextSurgeTimeString or dfDreamsurgeInfo.timeString or "...";
							local lineText = format("%s @ %s", L["showDreamsurgeInfo"], dfDreamsurgeInfo.mapInfo.name)..": "..timeLeft;
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, dfDreamsurgeInfo.atlasName);
						end
					end
					-- Superbloom
					if ns.settings.showSuperbloomInfo then
						local dfSuperbloomInfo = ns.poi9.GetSuperbloomInfo();
						if dfSuperbloomInfo then
							local timeLeft = dfSuperbloomInfo.timeString or "...";
							local lineText = format("%s @ %s", dfSuperbloomInfo.name, dfSuperbloomInfo.mapInfo.name)..": "..timeLeft;
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, dfSuperbloomInfo.atlasName);
						end
					end
					-- The Big Dig
					if ns.settings.showTheBigDigInfo then
						local dfTheBigDigInfo = ns.poi9.GetTheBigDigInfo();
						if dfTheBigDigInfo then
							local timeLeft = dfTheBigDigInfo.timeString or "...";
							local lineText = format("%s @ %s", dfTheBigDigInfo.name, dfTheBigDigInfo.mapInfo.name)..": "..timeLeft;
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, dfTheBigDigInfo.atlasName);
						end
					end
				end
				if (expansion.ID == ExpansionInfo.data.SHADOWLANDS.ID) then
					-- Covenant Renown
					local covenantInfo = util.covenant.GetCovenantInfo();
					local renownInfo = util.covenant.GetRenownData(covenantInfo.ID);
					if renownInfo then
						local renownLevelText = GARRISON_TYPE_9_0_LANDING_PAGE_RENOWN_LEVEL:format(renownInfo.currentRenownLevel);  --, renownInfo.maximumRenownLevel);
						local lineText = format("%s: %s", covenantInfo.name, WHITE_FONT_COLOR:WrapTextInColorCode(renownLevelText));
						util.GameTooltip_AddObjectiveLine(tooltip, lineText, covenantInfo.isCompleted, wrapLine, leftOffset, covenantInfo.atlasName, nil, covenantInfo.isCompleted);
					end
				end
				-- Command table missions
				if (expansion.ID ~= ExpansionInfo.data.DRAGONFLIGHT.ID and garrisonInfo.missions.numInProgress > 0) then
					local hasCompletedAllMissions = garrisonInfo.missions.numCompleted == garrisonInfo.missions.numInProgress;
					local progressText = GENERIC_FRACTION_STRING:format(garrisonInfo.missions.numCompleted, garrisonInfo.missions.numInProgress);
					util.GameTooltip_AddObjectiveLine(tooltip, garrisonInfo.msg.missionsTitle..": "..progressText, hasCompletedAllMissions);
				end
				-- Bounty Board + Covenant Callings
				if (expansion.ID ~= ExpansionInfo.data.DRAGONFLIGHT.ID and
					expansion.ID ~= ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID) then
					local bountyBoard = garrisonInfo.bountyBoard;
					if bountyBoard.AreBountiesUnlocked() then
						local bounties = bountyBoard.GetBounties()
						util.GameTooltip_AddObjectiveLine(tooltip, format("%s: %d/3", bountyBoard.title, #bounties), #bounties == 0);
					end
				end
				-- Threats (Maw + N'Zoth)
				if activeThreats then
					local expansionThreats = activeThreats[expansion.ID];
					if expansionThreats then
						if (expansion.ID == ExpansionInfo.data.SHADOWLANDS.ID) then
							local covenantAssaultInfo = expansionThreats[1];
							local timeLeftText = covenantAssaultInfo.timeLeftString and covenantAssaultInfo.timeLeftString or "...";
							local lineText = covenantAssaultInfo.questName..": "..timeLeftText;
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, covenantAssaultInfo.isCompleted, wrapLine, leftOffset, covenantAssaultInfo.atlasName, covenantAssaultInfo.color, covenantAssaultInfo.isCompleted);
						else
							for _, assaultInfo in ipairs(expansionThreats) do
								local timeLeft = assaultInfo.timeLeftString and assaultInfo.timeLeftString or "...";
								local lineText = assaultInfo.mapInfo.name..": "..timeLeft
								util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, assaultInfo.atlasName, assaultInfo.color)
							end
						end
					end
				end
				if (expansion.ID == ExpansionInfo.data.BATTLE_FOR_AZEROTH.ID) then
					-- BfA Faction Assaults
					local factionAssaultsAreaPoiInfo = util.poi.GetBfAFactionAssaultsInfo();
					if factionAssaultsAreaPoiInfo then
						local timeLeft = factionAssaultsAreaPoiInfo.timeString or "...";
						local lineText = factionAssaultsAreaPoiInfo.description..": "..timeLeft;
						util.GameTooltip_AddObjectiveLine(tooltip, lineText, factionAssaultsAreaPoiInfo.isCompleted, wrapLine, leftOffset, factionAssaultsAreaPoiInfo.atlasName, factionAssaultsAreaPoiInfo.color, factionAssaultsAreaPoiInfo.isCompleted);
					end
				end
				if (expansion.ID == ExpansionInfo.data.LEGION.ID) then
					-- Legion Assaults
					local legionAssaultsAreaPoiInfo = util.poi.GetLegionAssaultsInfo();
					if legionAssaultsAreaPoiInfo then
						local timeLeft = legionAssaultsAreaPoiInfo.timeString or "...";
						local lineText = legionAssaultsAreaPoiInfo.description..": "..timeLeft;
						util.GameTooltip_AddObjectiveLine(tooltip, lineText, legionAssaultsAreaPoiInfo.isCompleted, wrapLine, leftOffset, legionAssaultsAreaPoiInfo.atlasName, legionAssaultsAreaPoiInfo.color, legionAssaultsAreaPoiInfo.isCompleted);
					end
					-- Legion: Invasion Points
					local greaterInvasionAreaPoiInfo = util.poi.GetGreaterInvasionPointDataInfo();
					if greaterInvasionAreaPoiInfo then
						local timeLeft = greaterInvasionAreaPoiInfo.timeString or "...";
						local lineText = greaterInvasionAreaPoiInfo.description..": "..timeLeft;
						util.GameTooltip_AddObjectiveLine(tooltip, lineText, greaterInvasionAreaPoiInfo.isCompleted, wrapLine, leftOffset, greaterInvasionAreaPoiInfo.atlasName, greaterInvasionAreaPoiInfo.color, greaterInvasionAreaPoiInfo.isCompleted);
					end
				end
				-- Garrison Invasion
				if (expansion.ID == ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID and util.garrison.IsDraenorInvasionAvailable()) then
					local lineText = GARRISON_LANDING_INVASION_ALERT
					util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, "worldquest-tracker-questmarker", WARNING_FONT_COLOR)
				end
				-- Timewalking Vendor (currently Draenor + Legion only)
				if ShouldShowTimewalkingVendorText(expansion) then
					local vendorAreaPoiInfo = util.poi.FindTimewalkingVendor(expansion);
					if vendorAreaPoiInfo then
						local timeLeft = vendorAreaPoiInfo.timeString or "...";
						local lineText = format("%s @ %s", vendorAreaPoiInfo.name, vendorAreaPoiInfo.mapInfo.name)..": "..timeLeft
						util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, vendorAreaPoiInfo.atlasName);
					end
				end
			end
		end
	end
	-- GameTooltip_AddBlankLineToTooltip(tooltip);

	tooltip:Show();
end
ns.MissionReportButtonPlus_OnAddonCompartmentLeave = GameTooltip_Hide;

-- REF.: [AddonCompartment.lua](https://www.townlong-yak.com/framexml/55818/Blizzard_Minimap/AddonCompartment.lua)
-- 
function ns.MissionReportButtonPlus_OnAddonCompartmentClick(data, menuInputData, menu)
	local clickInfo = menuInputData;  --> .context=2, .buttonName

	if (clickInfo.buttonName == "LeftButton") then
		local result =  MRBP_IsAnyGarrisonRequirementMet();
		if result then
			MRBP_OnClick(ExpansionLandingPageMinimapButton, clickInfo.buttonName, false);
		end
	end
	if (clickInfo.buttonName == "RightButton") then
		MRBP_Settings_ToggleSettingsPanel(AddonID);
	end
	if (clickInfo.buttonName == "MiddleButton" and MRBP_IsGarrisonRequirementMet(Enum.ExpansionLandingPageType.Dragonflight)) then
		LocalDragonridingUtil:ToggleDragonridingTree();
	end
end
