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
local MenuTooltip, ExpansionTooltip
local LocalLibQTipUtil = ns.utils.libqtip

local MRBP_GARRISON_TYPE_INFOS = {}
local MRBP_EventMessagesCounter = {}
-- Tests
local MRBP_DRAGONRIDING_QUEST_ID = 68795;  --> "Dragonriding"
local MRBP_MAJOR_FACTIONS_QUEST_ID_HORDE = 65444;  --> "To the Dragon Isles!"
local MRBP_MAJOR_FACTIONS_QUEST_ID_ALLIANCE = 67700;  --> "To the Dragon Isles!"

-- Backwards compatibility 
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local LoadAddOn = C_AddOns.LoadAddOn
local C_CovenantCallings = C_CovenantCallings
local MapUtil = MapUtil

local DIM_RED_FONT_COLOR = DIM_RED_FONT_COLOR
local DISABLED_FONT_COLOR = DISABLED_FONT_COLOR
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR
local LIGHTGRAY_FONT_COLOR = LIGHTGRAY_FONT_COLOR
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR
local RED_FONT_COLOR = RED_FONT_COLOR
local WARNING_FONT_COLOR = WARNING_FONT_COLOR

local TEXT_DELIMITER = ITEM_NAME_DESCRIPTION_DELIMITER

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
	-- "ACHIEVEMENT_EARNED",  --> achievementID, alreadyEarned
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
			ns.data:CleanUpLabels()

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

			local garrInfo = MRBP_GARRISON_TYPE_INFOS[garrisonType]
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
							util.cprintEvent(garrInfo.expansion.name, GARRISON_BUILDING_COMPLETE, buildingName, GARRISON_FINALIZE_BUILDING_TOOLTIP);
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
			local expansionName = util.expansion.data.WarlordsOfDraenor.name;
			util.cprintEvent(expansionName, GARRISON_LANDING_INVASION, nil, GARRISON_LANDING_INVASION_TOOLTIP);

		elseif (event == "GARRISON_MISSION_FINISHED") then
			-- REF.: <FrameXML/Blizzard_GarrisonUI/Blizzard_GarrisonMissionUI.lua>
			local followerTypeID, missionID = ...
			local eventMsg = GarrisonFollowerOptions[followerTypeID].strings.ALERT_FRAME_TITLE
			-- local instructionMsg = GarrisonFollowerOptions[followerTypeID].strings.LANDING_COMPLETE
			local garrTypeID = GarrisonFollowerOptions[followerTypeID].garrisonType
			local garrInfo = MRBP_GARRISON_TYPE_INFOS[garrTypeID]
			local missionInfo = C_Garrison.GetBasicMissionInfo(missionID)
			if missionInfo then
				local missionLink = C_Garrison.GetMissionLink(missionID)
				local missionIcon = missionInfo.typeTextureKit and missionInfo.typeTextureKit.."-Map" or missionInfo.typeAtlas
				local missionName = util.CreateInlineIcon(missionIcon)..missionLink;
				_log:debug(event, "followerTypeID:", followerTypeID, "missionID:", missionID, missionInfo.name)
				--> TODO - Count and show number of twinks' finished missions ???  --> MRBP_GlobalMissions
				--> TODO - Remove from MRBP_GlobalMissions
				util.cprintEvent(garrInfo.expansion.name, eventMsg, missionName, nil, true);
			end

		elseif (event == "GARRISON_TALENT_COMPLETE") then
			local garrTypeID, doAlert = ...
			_log:debug(event, "garrTypeID:", garrTypeID, "doAlert:", doAlert)
			local followerTypeID = GetPrimaryGarrisonFollowerType(garrTypeID)
			local garrInfo = MRBP_GARRISON_TYPE_INFOS[garrTypeID]
			local eventMsg = GarrisonFollowerOptions[followerTypeID].strings.TALENT_COMPLETE_TOAST_TITLE
			-- REF. <FrameXML/Blizzard_GarrisonUI/Blizzard_GarrisonLandingPage.lua>
			local talentTreeIDs = C_Garrison.GetTalentTreeIDsByClassID(garrTypeID, select(3, UnitClass("player")))
			local completeTalentID = C_Garrison.GetCompleteTalent(garrTypeID)
			if (talentTreeIDs) then
				for treeIndex, treeID in ipairs(talentTreeIDs) do
					local treeInfo = C_Garrison.GetTalentTreeInfo(treeID)
					for talentIndex, talent in ipairs(treeInfo.talents) do
						if (talent.researched or talent.id == completeTalentID) then
							-- GetTalentLink(talent.id)
							local nameString = util.CreateInlineIcon(talent.icon).." "..talent.name;
							util.cprintEvent(garrInfo.expansion.name, eventMsg, nameString);
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
					MRBP:HideMinimapButton()
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
			_log:debug("Covenant callings received:", #callings);
			MRBP_GARRISON_TYPE_INFOS[util.expansion.data.Shadowlands.garrisonTypeID].bountyBoard["GetBounties"] = function() return callings end;

		elseif (event == "MAJOR_FACTION_UNLOCKED") then
			-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua>
			local majorFactionID = ...;
			local majorFactionData = util.garrison.GetMajorFactionData(majorFactionID);
			local unlockedMessage = DRAGONFLIGHT_LANDING_PAGE_ALERT_MAJOR_FACTION_UNLOCKED;
			if majorFactionData then
				local majorFactionColor = _G[strupper(majorFactionData.textureKit).."_MAJOR_FACTION_COLOR"];
				unlockedMessage = unlockedMessage.." - "..majorFactionColor:WrapTextInColorCode(majorFactionData.name);
			end
			ns.cprint(unlockedMessage);
			ns.MRBP_ReloadDropdown();

		end
	end
)

-- Load this add-on's functions when the MR minimap button is ready.
function MRBP:OnLoad()
	_log:info(string.format("Loading %s...", ns.AddonColor:WrapTextInColorCode(ns.AddonTitle)))

	-- Load data
	ns.data:LoadInGameLabels()

	-- Load settings and interface options
	MRBP_Settings_Register()

	self:RegisterSlashCommands()
	self:SetButtonHooks()

	-- Create the dropdown menu
	self:LoadData()
	self:GarrisonLandingPageDropDown_OnLoad()

	_log:info("----- Addon is ready. -----")
end

----- Data ---------------------------------------------------------------------

-- A collection of quest for (before) unlocking the command table.
--> <questID, questName_English (fallback)>
local MRBP_COMMAND_TABLE_UNLOCK_QUESTS = {
	[util.expansion.data.WarlordsOfDraenor.garrisonTypeID] = {
		-- REF.: <https://www.wowhead.com/guides/garrisons/quests-to-unlock-a-level-1-and-level-2-garrison>
		["Horde"] = {34775, "Mission Probable"},  --> wowhead
		["Alliance"] = {34692, "Delegating on Draenor"},  --> Companion App
	},
	[util.expansion.data.Legion.garrisonTypeID] = {
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
		["EVOKER"] = {0, "???"},  --> not available for Legion ???
	},
	[util.expansion.data.BattleForAzeroth.garrisonTypeID] = {
		["Horde"] = {51771, "War of Shadows"},
		["Alliance"] = {51715, "War of Shadows"},
	},
	[util.expansion.data.Shadowlands.garrisonTypeID] = {
		[Enum.CovenantType.Kyrian] = {57878, "Choosing Your Purpose"},
		[Enum.CovenantType.Venthyr] = {57878, "Choosing Your Purpose"}, 	--> optional: 59319, "Advancing Our Efforts"
		[Enum.CovenantType.NightFae] = {57878, "Choosing Your Purpose"},	--> optional: 61552, "The Hunt Watches"
		[Enum.CovenantType.Necrolord] = {57878, "Choosing Your Purpose"},
		["alt"] = {62000, "Choosing Your Purpose"},  --> when skipping story mode
	},
	[util.expansion.data.Dragonflight.garrisonTypeID] = {
		["Horde"] ={65444, "To the Dragon Isles!"},
		["Alliance"] = {67700, "To the Dragon Isles!"},
		-- ["alt"] = {68798, "Dragon Glyphs and You"},
	},
}

-- Request data for the unlocking requirement quests; on initial log-in the
-- localized quest titles are not always available. This should help getting
-- the quest details in the language the player has chosen.
local function MRBP_RequestLoadQuestData(playerInfo)
	local playerTagNames = {playerInfo.factionGroup, playerInfo.className, playerInfo.covenantID}
	for garrTypeID, questData in pairs(MRBP_COMMAND_TABLE_UNLOCK_QUESTS) do
		for tagName, questTable in pairs(questData) do
			local questID = questTable[1]
			if (questID > 0) then
				if tContains(playerTagNames, tagName) then
					_log:debug("Requesting data for", questTable[2])
					C_QuestLog.RequestLoadQuestByID(questID)
				end
			end
		end
	end
end

-- Get quest details of given garrison type for given tag.
--> Returns: table  {questID, questName, requirementText}
local function MRBP_GetGarrisonTypeUnlockQuestInfo(garrTypeID, tagName)
	local reqMessageTemplate = L.TOOLTIP_REQUIREMENTS_TEXT_S  --> same as Companion App text
	local questData = MRBP_COMMAND_TABLE_UNLOCK_QUESTS[garrTypeID][tagName]
	local questID = questData[1]
	local questFallbackName = questData[2]  --> quest name in English
	local questName = QuestUtils_GetQuestName(questID)

	local questInfo = {}
	questInfo["questID"] = questID
	questInfo["questName"] = strlen(questName) > 0 and questName or questFallbackName
	questInfo["requirementText"] = reqMessageTemplate:format(questInfo.questName)

	return questInfo
end

-- Check if given garrison type is unlocked for given tag.
---@param garrTypeID number
---@param tagName string|number
---@return boolean isCompleted
--
local function MRBP_IsGarrisonTypeUnlocked(garrTypeID, tagName)
	local questData = MRBP_COMMAND_TABLE_UNLOCK_QUESTS[garrTypeID][tagName];
	local questID = questData[1];
	local IsCompleted = C_QuestLog.IsQuestFlaggedCompleted;

	--> FIXME - Temp. work-around (better with achievement of same name ???)
	-- In Shadowlands if you skip the story mode you get a different quest (ID) with the same name, so
	-- we need to check both quests.
	if (garrTypeID == util.expansion.data.Shadowlands.garrisonTypeID) then
		local questID2 = MRBP_COMMAND_TABLE_UNLOCK_QUESTS[garrTypeID]["alt"][1];
		return IsCompleted(questID) or IsCompleted(questID2);
	end

	return IsCompleted(questID);
end

-- Preparing this data on start-up results sometimes, in empty (nil) values,
-- eg. the covenant data. So, simply load this after the add-on has
-- been loaded and before the dropdown menu will be created.
--
-- REF.: <FrameXML/GarrisonBaseUtils.lua>
function MRBP:LoadData()
	_log:info("Preparing data tables...")

	local playerInfo = {}
	playerInfo.factionGroup = UnitFactionGroup("player")  --> for Draenor and BfA icon
	playerInfo.className = select(2, UnitClass("player"))  --> for Legion icon
	local covenantData = C_Covenants.GetCovenantData(C_Covenants.GetActiveCovenantID())  --> for Shadowlands icon
	-- print("covenantData:", covenantData and covenantData.ID, covenantData and covenantData.textureKit)
	--> FIXME - Getting nil on initial login
	playerInfo.covenantTex = covenantData ~= nil and covenantData.textureKit or "kyrian"
	playerInfo.covenantID = covenantData ~= nil and covenantData.ID or Enum.CovenantType.Kyrian

	-- Prepare quest data for the unlocking requirements
	MRBP_RequestLoadQuestData(playerInfo)

	-- Main data table with details about each garrison type
	MRBP_GARRISON_TYPE_INFOS = {
		----- Warlords of Draenor -----
		[util.expansion.data.WarlordsOfDraenor.garrisonTypeID] = {
			["tagName"] = playerInfo.factionGroup,
			["title"] = GARRISON_LANDING_PAGE_TITLE,
			["description"] = MINIMAP_GARRISON_LANDING_PAGE_TOOLTIP,
			["minimapIcon"] = string.format("GarrLanding-MinimapIcon-%s-Up", playerInfo.factionGroup),
			-- ["banner"] = "accountupgradebanner-wod",  -- 199x117  			--> TODO - Use with new frame
			["msg"] = {  --> menu entry tooltip messages
				["missionsTitle"] = GARRISON_MISSIONS_TITLE,
				["missionsReadyCount"] = GARRISON_LANDING_COMPLETED,  --> "%d/%d Ready for pickup"
				["missionsEmptyProgress"] = GARRISON_EMPTY_IN_PROGRESS_LIST,
				["missionsComplete"] = GarrisonFollowerOptions[Enum.GarrisonFollowerType.FollowerType_6_0_GarrisonFollower].strings.LANDING_COMPLETE or '???',
				["requirementText"] = MRBP_GetGarrisonTypeUnlockQuestInfo(Enum.GarrisonType.Type_6_0_Garrison, playerInfo.factionGroup).requirementText,
			},
			["expansion"] = util.expansion.data.WarlordsOfDraenor,
			["continents"] = {572},  --> Draenor
			-- No bounties in Draenor; only available since Legion.
		},
		----- Legion -----
		[util.expansion.data.Legion.garrisonTypeID] = {
			["tagName"] = playerInfo.className,
			["title"] = ORDER_HALL_LANDING_PAGE_TITLE,
			["description"] = MINIMAP_ORDER_HALL_LANDING_PAGE_TOOLTIP,
			["minimapIcon"] = playerInfo.className == "EVOKER" and "UF-Essence-Icon-Active" or  -- "legionmission-landingbutton-demonhunter-up" or
							  string.format("legionmission-landingbutton-%s-up", playerInfo.className),
			-- ["banner"] = "accountupgradebanner-legion",  -- 199x117  		--> TODO - Use with new frame
			["msg"] = {
				["missionsTitle"] = GARRISON_MISSIONS,
				["missionsReadyCount"] = GARRISON_LANDING_COMPLETED,
				["missionsEmptyProgress"] = GARRISON_EMPTY_IN_PROGRESS_LIST,
				["missionsComplete"] = GarrisonFollowerOptions[Enum.GarrisonFollowerType.FollowerType_7_0_GarrisonFollower].strings.LANDING_COMPLETE,
				["requirementText"] = MRBP_GetGarrisonTypeUnlockQuestInfo(util.expansion.data.Legion.garrisonTypeID, playerInfo.className).requirementText,
			},
			["expansion"] = util.expansion.data.Legion,
			["continents"] = {619, 905},  --> Broken Isles + Argus
			["bountyBoard"] = {
				["title"] = BOUNTY_BOARD_LOCKED_TITLE,
				["noBountiesMessage"] = BOUNTY_BOARD_NO_BOUNTIES_DAYS_1,
				["GetBounties"] = function() return util.quest.GetBountiesForMapID(650) end,  --> any child zone from "continents" in Legion seems to work
				["AreBountiesUnlocked"] = function() return MapUtil.MapHasUnlockedBounties(650) end,
			},
		},
		----- Battle for Azeroth -----
		[util.expansion.data.BattleForAzeroth.garrisonTypeID] = {
			["tagName"] = playerInfo.factionGroup,
			["title"] = GARRISON_TYPE_8_0_LANDING_PAGE_TITLE,
			["description"] = GARRISON_TYPE_8_0_LANDING_PAGE_TOOLTIP,
			["minimapIcon"] = string.format("bfa-landingbutton-%s-up", playerInfo.factionGroup),
			-- ["banner"] = "accountupgradebanner-bfa",  -- 199x133  			--> TODO - Use with new frame
			["msg"] = {
				["missionsTitle"] = GARRISON_MISSIONS,
				["missionsReadyCount"] = GARRISON_LANDING_COMPLETED,
				["missionsEmptyProgress"] = GARRISON_EMPTY_IN_PROGRESS_LIST,
				["missionsComplete"] = GarrisonFollowerOptions[Enum.GarrisonFollowerType.FollowerType_8_0_GarrisonFollower].strings.LANDING_COMPLETE,
				["requirementText"] = MRBP_GetGarrisonTypeUnlockQuestInfo(util.expansion.data.BattleForAzeroth.garrisonTypeID, playerInfo.factionGroup).requirementText,
			},
			["expansion"] = util.expansion.data.BattleForAzeroth,
			["continents"] = {875, 876},  -- Zandalar, Kul Tiras
			["poiZones"] = {1355, 62, 14, 81, 1527},  -- Nazjatar, Darkshore, Arathi Highlands, Silithus, Uldum
			--> Note: Uldum and Vale of Eternal Blossoms are covered as world map threats.
			["bountyBoard"] = {
				["title"] = BOUNTY_BOARD_LOCKED_TITLE,
				["noBountiesMessage"] = BOUNTY_BOARD_NO_BOUNTIES_DAYS_1,
				["GetBounties"] = function() return util.quest.GetBountiesForMapID(875) end,  --> or any child zone from "continents" seems to work as well.
				["AreBountiesUnlocked"] = function() return MapUtil.MapHasUnlockedBounties(875) end,  --> checking only Zandalar should be enough
			},
		},
		----- Shadowlands -----
		[util.expansion.data.Shadowlands.garrisonTypeID] = {
			["tagName"] = playerInfo.covenantID,
			["title"] = GARRISON_TYPE_9_0_LANDING_PAGE_TITLE,
			["description"] = GARRISON_TYPE_9_0_LANDING_PAGE_TOOLTIP,
			["minimapIcon"] = string.format("shadowlands-landingbutton-%s-up", playerInfo.covenantTex),
			-- ["minimapIcon"] = string.format("SanctumUpgrades-%s-32x32", playerInfo.covenantTex),
			-- ["banner"] = "accountupgradebanner-shadowlands",  -- 199x133  	--> TODO - Use with new frame
			["msg"] = {
				["missionsTitle"] = COVENANT_MISSIONS_TITLE,
				["missionsReadyCount"] = GARRISON_LANDING_COMPLETED,
				["missionsEmptyProgress"] = COVENANT_MISSIONS_EMPTY_IN_PROGRESS,
				["missionsComplete"] = GarrisonFollowerOptions[Enum.GarrisonFollowerType.FollowerType_9_0_GarrisonFollower].strings.LANDING_COMPLETE,
				["requirementText"] = MRBP_GetGarrisonTypeUnlockQuestInfo(util.expansion.data.Shadowlands.garrisonTypeID, playerInfo.covenantID).requirementText,
			},
			["expansion"] = util.expansion.data.Shadowlands,
			["continents"] = {1550},  --> Shadowlands
			["bountyBoard"] = {
				["title"] = CALLINGS_QUESTS,
				["noBountiesMessage"] = BOUNTY_BOARD_NO_CALLINGS_DAYS_1,
				["GetBounties"] = function() return {} end,  --> Shadowlands callings will be added later via the event handler.
				["AreBountiesUnlocked"] = function() return C_CovenantCallings.AreCallingsUnlocked() end,
			},
		},
		----- Dragonflight -----
		[util.expansion.data.Dragonflight.garrisonTypeID] = {
			-- ["tagName"] = playerInfo.className == "EVOKER" and "alt" or playerInfo.factionGroup,
			["tagName"] = playerInfo.factionGroup,
			["title"] = DRAGONFLIGHT_LANDING_PAGE_TITLE,
			["description"] = DRAGONFLIGHT_LANDING_PAGE_TOOLTIP,
			["minimapIcon"] = "dragonflight-landingbutton-up",
			-- ["banner"] = "accountupgradebanner-dragonflight",  -- 199x133  	--> TODO - Use with new frame
			["msg"] = {
				["requirementText"] = MRBP_GetGarrisonTypeUnlockQuestInfo(util.expansion.data.Dragonflight.garrisonTypeID, playerInfo.factionGroup).requirementText,
			},
		 	["expansion"] = util.expansion.data.Dragonflight,
			["continents"] = {1978},  --> Dragon Isles
			--> Note: The bounty board in Dragonflight is only used for filtering world quests and switching to them. It
			-- doesn't show any bounty details anymore. Instead you get rewards for each new major faction renown level.
		},
	};

	-- Note: Shadowlands callings receive info through event listening or on
	-- opening the mission frame; try to update.
	CovenantCalling_CheckCallings();
	--> REF.: <FrameXML/ObjectAPI/CovenantCalling.lua>
end

-- Check if the requirement for the given garrison type is met in order to
-- unlock the command table.
-- Note: Currently only the required quest is checked for completion and
--       nothing more. In Shadowlands there would be one more step needed, since
--       2 quest are available for this (see MRBP_IsGarrisonTypeUnlocked).
---@param garrTypeID number
---@return boolean|nil isRequirementMet?
---
function MRBP_IsGarrisonRequirementMet(garrTypeID)
	local garrInfo = MRBP_GARRISON_TYPE_INFOS[garrTypeID]
	if not garrInfo then return false end
	_log:info("Checking Garrison Requirement for", garrInfo.expansion.name, "...")

	local hasGarrison = util.garrison.HasGarrison(garrTypeID)
	local isQuestCompleted = MRBP_IsGarrisonTypeUnlocked(garrTypeID, garrInfo.tagName)

	_log:debug("Garrison type:", YELLOW_FONT_COLOR:WrapTextInColorCode(tostring(garrTypeID).." "..garrInfo.expansion.name))
	_log:debug("hasGarrison:", hasGarrison)
	_log:debug("isQuestCompleted:", isQuestCompleted)

	if (garrInfo.expansion.ID >= util.expansion.data.Dragonflight.ID) then
		local isUnlocked = C_PlayerInfo.IsExpansionLandingPageUnlockedForPlayer(garrInfo.expansion.ID);
		return isUnlocked or isQuestCompleted;
	end

	return hasGarrison and isQuestCompleted
end

---Check if at least one garrison is unlocked.
---@return boolean
---
function MRBP_IsAnyGarrisonRequirementMet()
	local expansionList = util.expansion.GetExpansionsWithLandingPage();
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
	local expansion = util.expansion.GetExpansionDataByGarrisonType(garrTypeID);
	-- Always (!) hide the GarrisonLandingPage; all visible UI widgets can only
	-- be loaded properly on opening.
	if (expansion.ID < util.expansion.data.Dragonflight.ID) then
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

local TOOLTIP_DASH_ICON_STRING = util.CreateInlineIcon(3083385);
local TOOLTIP_CLOCK_ICON_STRING = util.CreateInlineIcon1("auctionhouse-icon-clock");  -- "worldquest-icon-clock");
local TOOLTIP_CHECK_MARK_ICON_STRING = util.CreateInlineIcon(628564);
local TOOLTIP_YELLOW_CHECK_MARK_ICON_STRING = util.CreateInlineIcon(130751);
-- local TOOLTIP_GRAY_CHECK_MARK_ICON_STRING = util.CreateInlineIcon(130750);
-- local TOOLTIP_ORANGE_CHECK_MARK_ICON_STRING = util.CreateInlineIcon("Adventures-Checkmark");

-- Add a text in normal font color to given tooltip text.
---@param tooltipText string
---@param text string
---@param skipSeparatorLine boolean  If true, skips the space between this and the previous section
---@return string tooltipText
--
local function TooltipText_AddHeaderLine(tooltipText, text, skipSeparatorLine)
	if not skipSeparatorLine then
		tooltipText = tooltipText.."|n";
	end
	if not L:StringIsEmpty(text) then
		tooltipText = tooltipText.."|n"..text;
	end
	return tooltipText;
end

-- Add a text in an optional font color to given tooltip text.
---@param tooltipText string
---@param text string
---@param lineColor table|nil  A color class (see <FrameXML/GlobalColors.lua>); defaults to WHITE_FONT_COLOR
---@return string tooltipText
--
local function TooltipText_AddTextLine(tooltipText, text, lineColor)
	local fontColor = lineColor or WHITE_FONT_COLOR;
	local skipSeparatorLine = true;
	return TooltipText_AddHeaderLine(tooltipText, fontColor:WrapTextInColorCode(text), skipSeparatorLine);
end

-- Append a text in an optional font color separated by 1 space character to given tooltip text.
---@param tooltipText string
---@param text string
---@param lineColor table|nil  A color class (see <FrameXML/GlobalColors.lua>); defaults to WHITE_FONT_COLOR
---@return string tooltipText
--
local function TooltipText_AppendText(tooltipText, text, lineColor)
	local fontColor = lineColor or WHITE_FONT_COLOR;
	tooltipText = tooltipText.." "..fontColor:WrapTextInColorCode(text);
	return tooltipText;
end

-- Add a white colored text line to given tooltip text with a preceding icon.
---@param tooltipText string
---@param text string
---@param iconID string|number|nil  An atlas name or texture ID
---@param lineColor table|nil  A color class (see <FrameXML/GlobalColors.lua>); defaults to WHITE_FONT_COLOR
---@param isIconString boolean|nil  Icon is already wrapped into a string
---@return string tooltipText
--
local function TooltipText_AddIconLine(tooltipText, text, iconID, lineColor, isIconString)
	local fontColor = lineColor or WHITE_FONT_COLOR;
	local iconString = isIconString and iconID or util.CreateInlineIcon1(iconID);  --> with offset -1
	tooltipText = tooltipText.."|n"..iconString.." "..fontColor:WrapTextInColorCode(text);
	return tooltipText;
end

-- Add a white or gray colored text line to given tooltip text with a preceding dash or check mark icon, depending
-- whether the objective has been completed.
---@param tooltipText string  The required tooltip string
---@param text string  The label or message text
---@param isCompleted boolean|nil  A line with a completed objective will be shown in a gray text color with a check mark in front of it.
---@param lineColor table|nil  A color class (see <FrameXML/GlobalColors.lua>); defaults to WHITE_FONT_COLOR
---@param appendCompleteIcon boolean|nil  Append the icon at the end of the line, instead of in front of it (default)
---@param alternativeIcon string|nil  An atlas string
---@return string tooltipText
--
local function TooltipText_AddObjectiveLine(tooltipText, text, isCompleted, lineColor, appendCompleteIcon, alternativeIcon, isTrackingAchievement)
	if L:StringIsEmpty(text) then return tooltipText; end

	local isIconString = alternativeIcon == nil;
	local checkMarkIconString = isTrackingAchievement and TOOLTIP_YELLOW_CHECK_MARK_ICON_STRING or TOOLTIP_CHECK_MARK_ICON_STRING;
	if not isCompleted then
		return TooltipText_AddIconLine(tooltipText, text, alternativeIcon or TOOLTIP_DASH_ICON_STRING, lineColor, isIconString);
	elseif appendCompleteIcon then
		-- Append icon at line end
		tooltipText = TooltipText_AddIconLine(tooltipText, text, alternativeIcon or TOOLTIP_DASH_ICON_STRING, DISABLED_FONT_COLOR, isIconString);
		return tooltipText.." "..checkMarkIconString;
	else
		-- Replace the dash icon with the check mark icon
		return TooltipText_AddIconLine(tooltipText, text, alternativeIcon or checkMarkIconString, DISABLED_FONT_COLOR, isIconString);
	end
end

-- Add time remaining string starting with a dash and a clock icon.
---@param tooltipText string
---@param timeString string
---@param lineColor table|nil  A color class (see <FrameXML/GlobalColors.lua>)
---@return string tooltipText
-- **Note:**  
-- The 'timeString' is usually already colored, eg. red for soon-to-expire, etc.
-- If you use 'lineColor' the time string color will be overwritten.
--
local function TooltipText_AddTimeRemainingLine(tooltipText, timeString, lineColor)
	if L:StringIsEmpty(timeString) then return tooltipText; end

	tooltipText = tooltipText.."|n"..TOOLTIP_DASH_ICON_STRING
	tooltipText = tooltipText.." "..TOOLTIP_CLOCK_ICON_STRING
	if lineColor then
		tooltipText = tooltipText.." "..lineColor:WrapTextInColorCode(timeString)
	else
		tooltipText = tooltipText.." "..timeString
	end

	return tooltipText
end

-- Add details about the garrison mission progress.
---@param garrInfo table  One of the entries from MRBP_GARRISON_TYPE_INFOS
---@param tooltipText string
---@return string tooltipText
--
local function AddTooltipMissionInfoText(tooltipText, garrInfo)
	local hasCompletedAllMissions = garrInfo.missions.numCompleted == garrInfo.missions.numInProgress;

	tooltipText = TooltipText_AddHeaderLine(tooltipText, garrInfo.msg.missionsTitle);
	-- Mission counter
	if (garrInfo.missions.numInProgress > 0) then
		local progressText = string.format(garrInfo.msg.missionsReadyCount, garrInfo.missions.numCompleted, garrInfo.missions.numInProgress);
		tooltipText = TooltipText_AddObjectiveLine(tooltipText, progressText, hasCompletedAllMissions);
	else
		tooltipText = TooltipText_AddTextLine(tooltipText, garrInfo.msg.missionsEmptyProgress);
	end
	-- Return to base info
	if ns.settings.showMissionCompletedHintOnlyForAll then
		if (hasCompletedAllMissions and garrInfo.missions.numCompleted > 0) then
			tooltipText = TooltipText_AddTextLine(tooltipText, garrInfo.msg.missionsComplete);
		end
	else
		if (garrInfo.missions.numCompleted > 0) then
			tooltipText = TooltipText_AddTextLine(tooltipText, garrInfo.msg.missionsComplete);
		end
	end

	return tooltipText;
end

local function AddTooltipCovenantRenownText(tooltipText, covenantInfo)
	local renownInfo = util.covenant.GetRenownData(covenantInfo.ID);
	if renownInfo then
		local fontColor = ns.settings.applyCovenantColors and covenantInfo.color or nil;
		local lineText = covenantInfo.name;
		local progressText = MAJOR_FACTION_RENOWN_CURRENT_PROGRESS:format(renownInfo.currentRenownLevel, renownInfo.maximumRenownLevel);
		if renownInfo.hasMaximumRenown then
			-- Append max. level after covenant name
			local renownLevelText = MAJOR_FACTION_BUTTON_RENOWN_LEVEL:format(renownInfo.currentRenownLevel);
			lineText = lineText.." "..HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(PARENS_TEMPLATE:format(renownLevelText));
			progressText = COVENANT_SANCTUM_RENOWN_REWARD_TITLE_COMPLETE;
		end
		tooltipText = TooltipText_AddObjectiveLine(tooltipText, lineText, covenantInfo.isCompleted, fontColor, true, covenantInfo.atlasName, covenantInfo.isCompleted);
		tooltipText = TooltipText_AddObjectiveLine(tooltipText, progressText, renownInfo.hasMaximumRenown);
	end

	return tooltipText;
end

local function AddTooltipDragonFlightFactionsRenownText(tooltipText)
	local majorFactionData = util.garrison.GetAllMajorFactionDataForExpansion(util.expansion.data.Dragonflight.ID);

	-- Display faction infos
	for _, factionData in ipairs(majorFactionData) do
		if factionData then
			local factionIconString = util.garrison.GetMajorFactionInlineIcon(factionData);
			local isIconString = true;
			local factionColor = ns.settings.applyMajorFactionColors and util.garrison.GetMajorFactionColor(factionData) or WHITE_FONT_COLOR;
			tooltipText = TooltipText_AddIconLine(tooltipText, factionData.name, factionIconString, factionColor, isIconString);
			if factionData.isUnlocked then
				-- Append renown level
				local renownLevelText = MAJOR_FACTION_BUTTON_RENOWN_LEVEL:format(factionData.renownLevel);
				tooltipText = TooltipText_AppendText(tooltipText, PARENS_TEMPLATE:format(renownLevelText), NORMAL_FONT_COLOR);
				-- Show current renown progress
				local hasMaxRenown = util.garrison.HasMaximumMajorFactionRenown(factionData.factionID);
				local progressText = MAJOR_FACTION_RENOWN_CURRENT_PROGRESS:format(factionData.renownReputationEarned, factionData.renownLevelThreshold);
				local lineText = hasMaxRenown and MAJOR_FACTION_MAX_RENOWN_REACHED or progressText;
				local appendCompleteIcon = true;
				tooltipText = TooltipText_AddObjectiveLine(tooltipText, lineText, hasMaxRenown, nil, appendCompleteIcon);
			else
				-- Major faction is not unlocked, yet :(
				tooltipText = TooltipText_AddObjectiveLine(tooltipText, MAJOR_FACTION_BUTTON_FACTION_LOCKED, nil, DISABLED_FONT_COLOR);
				-- Show unlock reason
				if not ns.settings.hideMajorFactionUnlockDescription then
					tooltipText = TooltipText_AddObjectiveLine(tooltipText, factionData.unlockDescription, nil, DISABLED_FONT_COLOR);
				end
			end
		end
	end

	return tooltipText;
end

local function AddTooltipDragonGlyphsText(tooltipText)
	local treeCurrencyInfo = util.garrison.GetDragonRidingTreeCurrencyInfo();
	local glyphsPerZone, numGlyphsCollected, numGlyphsTotal = util.garrison.GetDragonGlyphsCount();

	-- Add counter of collected glyphs per zone
	for mapName, count in pairs(glyphsPerZone) do
		local zoneName = mapName..HEADER_COLON;
		local isComplete = count.numComplete == count.numTotal;
		if not (isComplete and ns.settings.autoHideCompletedDragonGlyphZones) then
			tooltipText = TooltipText_AddObjectiveLine(tooltipText, zoneName, isComplete);
			local lineColor = isComplete and DISABLED_FONT_COLOR or NORMAL_FONT_COLOR;
			local countedText = GENERIC_FRACTION_STRING:format(count.numComplete, count.numTotal);
			tooltipText = TooltipText_AppendText(tooltipText, countedText, lineColor);
		end
	end
	-- Add glyph collection summary
	local currencySymbolString = util.CreateInlineIcon(treeCurrencyInfo.texture, 16, 16, 0, -1);
	local youCollectedAmountString = TRADESKILL_NAME_RANK:format(YOU_COLLECTED_LABEL, numGlyphsCollected, numGlyphsTotal);
	local collectedAll = numGlyphsCollected == numGlyphsTotal;
	local appendCompleteIcon = true;
	tooltipText = TooltipText_AddObjectiveLine(tooltipText, youCollectedAmountString, collectedAll, nil, appendCompleteIcon, treeCurrencyInfo.texture);
	if (treeCurrencyInfo.quantity > 0) then
		local availableAmountText = PROFESSIONS_CURRENCY_AVAILABLE:format(treeCurrencyInfo.quantity, currencySymbolString);
		tooltipText = TooltipText_AddObjectiveLine(tooltipText, availableAmountText);
	end
	if (numGlyphsCollected == 0) then
		-- Inform player on how to get some glyphs
		local isIconString = true;
		tooltipText = TooltipText_AddIconLine(tooltipText, DRAGON_RIDING_CURRENCY_TUTORIAL, currencySymbolString, DISABLED_FONT_COLOR, isIconString);
	end

	return tooltipText;
end

--> Note: Don't delete! Used for testing.
local function AddMultiPOITestText(poiInfos, tooltipText, addSeparator)
	if util.TableHasAnyEntries(poiInfos) then
		for _, poi in ipairs(poiInfos) do
			if addSeparator then
				-- Add space between this an previous details
				tooltipText = tooltipText.."|n";
			end
			-- Add event name
			if poi.atlasName then
				local poiIcon = util.CreateInlineIcon(poi.atlasName);
				tooltipText = tooltipText.."|n"..poiIcon..poi.name;
			else
				tooltipText = tooltipText.."|n"..poi.name;
			end
			tooltipText = tooltipText..WHITE_FONT_COLOR_CODE;
			if (_log.level ~= _log.DEBUG) then
				tooltipText = tooltipText.." "..GRAY_FONT_COLOR_CODE..tostring(poi.areaPoiID).." > "..tostring(poi.isPrimaryMapForPOI);
				tooltipText = tooltipText.."|n"..tostring(poi.widgetSetID or poi.atlasName or '??');  -- ..tostring(poi.factionID))
				tooltipText = tooltipText..FONT_COLOR_CODE_CLOSE;
			end
			-- Show description
			if poi.shouldShowDescription then
				tooltipText = tooltipText.."|n"..TOOLTIP_DASH_ICON_STRING;
				tooltipText = tooltipText..poi.description;
			end
			-- Add location name
			tooltipText = tooltipText.."|n"..TOOLTIP_DASH_ICON_STRING;
			tooltipText = tooltipText..poi.mapInfo.name;
			if (_log.level == _log.DEBUG) then
				tooltipText = tooltipText.." "..GRAY_FONT_COLOR:WrapTextInColorCode(tostring(poi.mapInfo.mapID));
			end
			-- Add time remaining info
			if (poi.isTimed and poi.timeString)then
				tooltipText = tooltipText.."|n"..TOOLTIP_DASH_ICON_STRING;
				tooltipText = tooltipText..TOOLTIP_CLOCK_ICON_STRING;
				tooltipText = tooltipText.." "..(poi.timeString or '???');
			end
			tooltipText = tooltipText..FONT_COLOR_CODE_CLOSE;
		end
	end

	return tooltipText;
end

-- Build the menu entry label with an icon hint about completed missions.
---@param garrInfo table  One of the entries from MRBP_GARRISON_TYPE_INFOS
---@return string labelText
--
local function BuildMenuEntryLabel(garrInfo)
	local labelText = ns.settings.preferExpansionName and garrInfo.expansion.name or garrInfo.title;
	local hasCompletedAllMissions = garrInfo.missions.numCompleted == garrInfo.missions.numInProgress;
	if (ns.settings.showMissionCompletedHint and garrInfo.missions.numCompleted > 0) then
		if not ns.settings.showMissionCompletedHintOnlyForAll then
			labelText = labelText.." |TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0:0:0:0|t";
		end
		if (ns.settings.showMissionCompletedHintOnlyForAll and hasCompletedAllMissions) then
			labelText = labelText.." |TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0:0:0:0|t";
		end
	end

	return labelText;
end

local function ShouldShowMissionsInfoText(garrisonTypeID)
	return (
		(garrisonTypeID == util.expansion.data.Shadowlands.garrisonTypeID and ns.settings.showCovenantMissionInfo) or
		(garrisonTypeID == util.expansion.data.BattleForAzeroth.garrisonTypeID and ns.settings.showBfAMissionInfo) or
		(garrisonTypeID == util.expansion.data.Legion.garrisonTypeID and ns.settings.showLegionMissionInfo) or
		(garrisonTypeID == util.expansion.data.WarlordsOfDraenor.garrisonTypeID and ns.settings.showWoDMissionInfo)
	);
end

local function ShouldShowBountyBoardText(garrisonTypeID)
	return (
		(garrisonTypeID == util.expansion.data.Shadowlands.garrisonTypeID and ns.settings.showCovenantBounties) or
		(garrisonTypeID == util.expansion.data.BattleForAzeroth.garrisonTypeID and ns.settings.showBfABounties) or
		(garrisonTypeID == util.expansion.data.Legion.garrisonTypeID and ns.settings.showLegionBounties)
	);
end

local function ShouldShowActiveThreatsText(garrisonTypeID)
	return (
		(garrisonTypeID == util.expansion.data.Shadowlands.garrisonTypeID and ns.settings.showMawThreats) or
		(garrisonTypeID == util.expansion.data.BattleForAzeroth.garrisonTypeID and ns.settings.showNzothThreats)
	);
end

-- Check whether the Timewalking Vendor details should be shown.
local function ShouldShowTimewalkingVendorText(expansionInfo)
	if (expansionInfo.ID == util.expansion.data.WarlordsOfDraenor.ID) then
		return ns.settings.showWoDWorldMapEvents and ns.settings.showWoDTimewalkingVendor
	end
	if (expansionInfo.ID == util.expansion.data.Legion.ID) then
		return ns.settings.showLegionWorldMapEvents and ns.settings.showLegionTimewalkingVendor
	end
	return false
end

-- Build the menu entry's description tooltip containing informations ie. about
-- completed missions.
---@param garrInfo table  One of the entries from MRBP_GARRISON_TYPE_INFOS
---@param activeThreats table  See util.threats.GetActiveThreats() for details
---@return string tooltipText
--
local function BuildMenuEntryTooltip(garrInfo, activeThreats)
	local isDisabled = garrInfo.shouldShowDisabled;
	local garrTypeID = garrInfo.expansion.garrisonTypeID;
	local isForWarlordsOfDraenor = garrTypeID == util.expansion.data.WarlordsOfDraenor.garrisonTypeID;
	local isForLegion = garrTypeID == util.expansion.data.Legion.garrisonTypeID;
	local isForBattleForAzeroth = garrTypeID == util.expansion.data.BattleForAzeroth.garrisonTypeID;
	local isForShadowlands = garrTypeID == util.expansion.data.Shadowlands.garrisonTypeID;
	local isForDragonflight = garrTypeID == util.expansion.data.Dragonflight.garrisonTypeID;

	-- Add landing page description; tooltip already comes with the menu item name
	local tooltipText = isDisabled and DISABLED_FONT_COLOR:WrapTextInColorCode(garrInfo.description) or garrInfo.description;

	-- Show requirement info for unlocking the given expansion type
	if (isDisabled) then  -- and ns.settings.showEntryRequirements) then
		tooltipText = tooltipText.."|n";
		tooltipText = TooltipText_AddTextLine(tooltipText, garrInfo.msg.requirementText, DIM_RED_FONT_COLOR);

		return tooltipText;  --> Stop here, don't process the rest below
	end

	----- In-progress missions -----

	if ShouldShowMissionsInfoText(garrTypeID) then
		tooltipText = AddTooltipMissionInfoText(tooltipText, garrInfo);
	end

	----- Bounty board infos (Legion + BfA + Shadowlands only) -----

	if ShouldShowBountyBoardText(garrTypeID) then
		-- Only available since Legion (WoW 7.x); no longer useful in Dragonflight (WoW 10.x)
		local bountyBoard = garrInfo.bountyBoard;
		if bountyBoard.AreBountiesUnlocked() then
			local bounties = bountyBoard.GetBounties()
			tooltipText = TooltipText_AddHeaderLine(tooltipText, bountyBoard.title);
			_log:debug(garrInfo.title, "- bounties:", #bounties)
			if isForShadowlands then
				-- Retrieves callings through event listening and on opening the mission frame; try to update (again).
				CovenantCalling_CheckCallings()
			end
			local isIconString = true;
			if (#bounties > 0) then
				for _, bountyData in ipairs(bounties) do
					if bountyData then
						local questName = QuestUtils_GetQuestName(bountyData.questID)
						local icon = util.CreateInlineIcon(bountyData.icon);
						if isForShadowlands then
							-- REF.: CreateTextureMarkup(file, fileWidth, fileHeight, width, height, left, right, top, bottom, xOffset, yOffset)
							icon = CreateTextureMarkup(bountyData.icon, 256, 256, 16, 16, 0.28, 0.74, 0.26, 0.72, 1, -1);
						end
						if bountyData.turninRequirementText then
							tooltipText = TooltipText_AddIconLine(tooltipText, questName, icon, DISABLED_FONT_COLOR, isIconString);
							-- if ns.settings.showBountyRequirements then			--> TODO - Re-add option to settings
							tooltipText = TooltipText_AddObjectiveLine(tooltipText, bountyData.turninRequirementText, nil, WARNING_FONT_COLOR);
							-- end
						else
							tooltipText = TooltipText_AddIconLine(tooltipText, questName, icon, nil, isIconString);
						end
					end
				end
			elseif not isForShadowlands then
				tooltipText = TooltipText_AddIconLine(tooltipText, bountyBoard.noBountiesMessage, TOOLTIP_DASH_ICON_STRING, nil, isIconString);
			end
		end
	end

	----- World map threats (Battle for Azeroth + Shadowlands) -----

	if (util.TableHasAnyEntries(activeThreats) and ShouldShowActiveThreatsText(garrTypeID)) then
		for threatExpansionLevel, threatData in pairs(activeThreats) do
			-- Add the infos only to the corresponding expansion
			if (threatExpansionLevel == garrInfo.expansion.ID) then
				-- Show the header *only once* per expansion
				local isBfAThreat = threatExpansionLevel == util.expansion.data.BattleForAzeroth.ID;
				local isShadowlandsThreat = threatExpansionLevel == util.expansion.data.Shadowlands.ID;
				if isBfAThreat then
					tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showNzothThreats"])
				elseif isShadowlandsThreat then
					tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showMawThreats"]);
				else
					local zoneName = threatData[1].mapInfo.name;
					tooltipText = TooltipText_AddHeaderLine(tooltipText, zoneName);
				end
				for i, threatInfo in ipairs(threatData) do
					local fontColor = ( (isBfAThreat and ns.settings.applyBfAFactionColors) or
										(isShadowlandsThreat and ns.settings.applyCovenantColors)) and threatInfo.color or nil;
					-- tooltipText = TooltipText_AddIconLine(tooltipText, threatInfo.questName, threatInfo.atlasName, fontColor);
					local appendCompleteIcon = true;
					tooltipText = TooltipText_AddObjectiveLine(tooltipText, threatInfo.questName, threatInfo.isCompleted, fontColor, appendCompleteIcon, threatInfo.atlasName, threatInfo.isCompleted);
					--> TODO - Add major-minor assault type icon for N'Zoth Assaults
					tooltipText = TooltipText_AddObjectiveLine(tooltipText, threatInfo.mapInfo.name);
					tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, threatInfo.timeLeftString);
				end
			end
		end
	end

	----- Warlords of Draenor -----

	-- Garrison Invasion
	if (isForWarlordsOfDraenor and ns.settings.showWoDGarrisonInvasionAlert and util.garrison.IsDraenorInvasionAvailable()) then
		tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showWoDGarrisonInvasionAlert"]);
		tooltipText = TooltipText_AddIconLine(tooltipText, GARRISON_LANDING_INVASION_ALERT, "worldquest-tracker-questmarker", WARNING_FONT_COLOR);
		tooltipText = TooltipText_AddTextLine(tooltipText, GARRISON_LANDING_INVASION_TOOLTIP);
	end

	----- Legion -----

	if (isForLegion and ns.settings.showLegionWorldMapEvents) then
		-- Legion Invasion
		if ns.settings.showLegionAssaultsInfo then
			local legionAssaultsAreaPoiInfo = util.poi.GetLegionAssaultsInfo();
			if legionAssaultsAreaPoiInfo then
				tooltipText = TooltipText_AddHeaderLine(tooltipText, legionAssaultsAreaPoiInfo.name)
				tooltipText = TooltipText_AddIconLine(tooltipText, legionAssaultsAreaPoiInfo.parentMapInfo.name, legionAssaultsAreaPoiInfo.atlasName, legionAssaultsAreaPoiInfo.color);
				tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, legionAssaultsAreaPoiInfo.timeString);
				tooltipText = TooltipText_AddObjectiveLine(tooltipText, legionAssaultsAreaPoiInfo.description, legionAssaultsAreaPoiInfo.isCompleted, nil, nil, nil, legionAssaultsAreaPoiInfo.isCompleted);
			end
		end
		-- Demon Invasions (Broken Shores)
		if ns.settings.showBrokenShoreInvasionInfo then
			local demonAreaPoiInfos = util.poi.GetBrokenShoreInvasionInfo();
			if util.TableHasAnyEntries(demonAreaPoiInfos) then
				tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showBrokenShoreInvasionInfo"]);
				for _, demonPoi in ipairs(demonAreaPoiInfos) do
					tooltipText = TooltipText_AddIconLine(tooltipText, demonPoi.name, demonPoi.atlasName, demonPoi.color);
					tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, demonPoi.timeString);
				end
			end
		end
		-- Invasion Points (Argus)
		if ns.settings.showArgusInvasionInfo then
			local riftAreaPoiInfos = util.poi.GetArgusInvasionPointsInfo();
			if util.TableHasAnyEntries(riftAreaPoiInfos) then
				tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showArgusInvasionInfo"]);
				for _, riftPoi in ipairs(riftAreaPoiInfos) do
					local appendCompleteIcon = true;
					tooltipText = TooltipText_AddObjectiveLine(tooltipText, riftPoi.description, riftPoi.isCompleted, riftPoi.color, appendCompleteIcon, riftPoi.atlasName, riftPoi.isCompleted);
					tooltipText = TooltipText_AddObjectiveLine(tooltipText, riftPoi.mapInfo.name);
					tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, riftPoi.timeString);
				end
			end
		end
	end

	----- Battle for Azeroth -----

	if isForBattleForAzeroth then
		if (ns.settings.showBfAWorldMapEvents and ns.settings.showBfAFactionAssaultsInfo) then
			-- Faction Assaults
			local factionAssaultsAreaPoiInfo = util.poi.GetBfAFactionAssaultsInfo();
			if factionAssaultsAreaPoiInfo then
				local fontColor = ns.settings.applyBfAFactionColors and factionAssaultsAreaPoiInfo.color or nil;
				tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showBfAFactionAssaultsInfo"]);
				tooltipText = TooltipText_AddIconLine(tooltipText, factionAssaultsAreaPoiInfo.parentMapInfo.name, factionAssaultsAreaPoiInfo.atlasName, fontColor);
				tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, factionAssaultsAreaPoiInfo.timeString);
				tooltipText = TooltipText_AddObjectiveLine(tooltipText, factionAssaultsAreaPoiInfo.description, factionAssaultsAreaPoiInfo.isCompleted, nil, nil, nil, factionAssaultsAreaPoiInfo.isCompleted);
			end
		end
		if ns.settings.showBfAIslandExpeditionsInfo then
			local islandExpeditionInfo = util.poi.GetBfAIslandExpeditionInfo();
			tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showBfAIslandExpeditionsInfo"]);
			tooltipText = TooltipText_AddIconLine(tooltipText, islandExpeditionInfo.name, islandExpeditionInfo.atlasName);
			tooltipText = TooltipText_AddObjectiveLine(tooltipText, islandExpeditionInfo.progressText, islandExpeditionInfo.isFinished);
			local appendedTextColor = islandExpeditionInfo.isFinished and DISABLED_FONT_COLOR or NORMAL_FONT_COLOR;
			tooltipText = TooltipText_AppendText(tooltipText, PARENS_TEMPLATE:format(islandExpeditionInfo.fulfilledPercentageString), appendedTextColor);
		end
	end

	----- Shadowlands -----

	if (isForShadowlands and ns.settings.showCovenantRenownLevel) then
		local covenantInfo = util.covenant.GetCovenantInfo();
		if util.TableHasAnyEntries(covenantInfo) then
			tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showCovenantRenownLevel"]);
			tooltipText = AddTooltipCovenantRenownText(tooltipText, covenantInfo);
		end
	end

	----- Dragonflight -----

	if isForDragonflight then
		-- Major Factions renown level and progress
		if ns.settings.showMajorFactionRenownLevel then
			tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showMajorFactionRenownLevel"]);
			tooltipText = AddTooltipDragonFlightFactionsRenownText(tooltipText);
		end
		-- Dragon Glyphs
		if ns.settings.showDragonGlyphs then
			tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showDragonGlyphs"]);
			if util.garrison.IsDragonridingUnlocked() then
				tooltipText = AddTooltipDragonGlyphsText(tooltipText);
			else
				-- Not unlocked, yet :(
				local dragonIconDisabled = util.CreateInlineIcon("dragonriding-barbershop-icon-category-head", 20, 20, -2);
				local disabledInfoText = DISABLED_FONT_COLOR:WrapTextInColorCode(LANDING_DRAGONRIDING_TREE_BUTTON_DISABLED);
				tooltipText = tooltipText.."|n"..dragonIconDisabled..disabledInfoText;
			end
		end
		----- World Map Events -----
		if ns.settings.showDragonflightWorldMapEvents then
			-- Dragonriding Race
			if ns.settings.showDragonRaceInfo then
				local raceAreaPoiInfo = util.poi.GetDragonRaceInfo()
				if raceAreaPoiInfo then
					tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showDragonRaceInfo"])
					tooltipText = TooltipText_AddIconLine(tooltipText, raceAreaPoiInfo.name, raceAreaPoiInfo.atlasName)
					tooltipText = TooltipText_AddObjectiveLine(tooltipText, raceAreaPoiInfo.areaName)
					tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, raceAreaPoiInfo.timeString)
					if raceAreaPoiInfo.eventInfo then
						local iconString = util.CreateInlineIcon(raceAreaPoiInfo.eventInfo.texture, 16, 16, 3, -1)
						tooltipText = TooltipText_AddIconLine(tooltipText, raceAreaPoiInfo.eventInfo.name, iconString, nil, true)
						tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, raceAreaPoiInfo.eventInfo.timeString)
					end
				end
			end
			-- Camp Aylaag
			if ns.settings.showCampAylaagInfo then
				local campAreaPoiInfo = util.poi.GetCampAylaagInfo();
				if campAreaPoiInfo then
					tooltipText = TooltipText_AddHeaderLine(tooltipText, campAreaPoiInfo.name);  -- L["showCampAylaagInfo"]
					tooltipText = TooltipText_AddIconLine(tooltipText, campAreaPoiInfo.mapInfo.name, campAreaPoiInfo.atlasName);
					tooltipText = TooltipText_AddObjectiveLine(tooltipText, campAreaPoiInfo.areaName, campAreaPoiInfo.isCompleted);
					if campAreaPoiInfo.timeString then
						tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, campAreaPoiInfo.timeString);
					else
						-- if not ns.settings.hideEventDescriptions then		--> TODO - Camp Aylaag description
						tooltipText = TooltipText_AddObjectiveLine(tooltipText, campAreaPoiInfo.description);
						-- end
					end
				end
			end
			-- Grand Hunts
			if ns.settings.showGrandHuntsInfo then
				local huntsAreaPoiInfo = util.poi.GetGrandHuntsInfo();
				if huntsAreaPoiInfo then
					tooltipText = TooltipText_AddHeaderLine(tooltipText, huntsAreaPoiInfo.name);  -- L["showGrandHuntsInfo"]
					tooltipText = TooltipText_AddIconLine(tooltipText, huntsAreaPoiInfo.mapInfo.name, huntsAreaPoiInfo.atlasName);
					-- tooltipText = TooltipText_AddObjectiveLine(tooltipText, huntsAreaPoiInfo.areaName);
					tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, huntsAreaPoiInfo.timeString);
				end
			end
			-- Iskaara Community Feast
			if ns.settings.showCommunityFeastInfo then
				local feastAreaPoiInfo = util.poi.GetCommunityFeastInfo()
				if feastAreaPoiInfo then
					tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showCommunityFeastInfo"])
					tooltipText = TooltipText_AddIconLine(tooltipText, feastAreaPoiInfo.mapInfo.name, feastAreaPoiInfo.atlasName)
					tooltipText = TooltipText_AddObjectiveLine(tooltipText, feastAreaPoiInfo.name)
					tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, feastAreaPoiInfo.timeString)
				end
			end
			-- Siege on Dragonbane Keep
			if ns.settings.showDragonbaneKeepInfo then
				local siegeAreaPoiInfo = util.poi.GetDragonbaneKeepInfo();
				if siegeAreaPoiInfo then
					tooltipText = TooltipText_AddHeaderLine(tooltipText, siegeAreaPoiInfo.name);  -- L["showDragonbaneKeepInfo"]
					tooltipText = TooltipText_AddIconLine(tooltipText, siegeAreaPoiInfo.mapInfo.name, siegeAreaPoiInfo.atlasName);
					tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, siegeAreaPoiInfo.timeString);
					if not ns.settings.hideEventDescriptions then
						tooltipText = TooltipText_AddObjectiveLine(tooltipText, siegeAreaPoiInfo.description);
					end
				end
			end
			-- Elemental Storms
			if ns.settings.showElementalStormsInfo then
				local stormsAreaPoiInfos = util.poi.GetElementalStormsInfo();
				if util.TableHasAnyEntries(stormsAreaPoiInfos) then
					tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showElementalStormsInfo"]);  -- stormsAreaPoiInfos[1].name);
					for _, stormPoi in ipairs(stormsAreaPoiInfos) do
						tooltipText = TooltipText_AddIconLine(tooltipText, stormPoi.mapInfo.name, stormPoi.atlasName);
						tooltipText = TooltipText_AddObjectiveLine(tooltipText, stormPoi.areaName);
						tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, stormPoi.timeString);
					end
				end
			end
			-- Fyrakk Assaults
			if ns.settings.showFyrakkAssaultsInfo then
				local dfFyrakkAssaultsAreaPoiInfo = util.poi.GetFyrakkAssaultsInfo();
				if dfFyrakkAssaultsAreaPoiInfo then
					tooltipText = TooltipText_AddHeaderLine(tooltipText, dfFyrakkAssaultsAreaPoiInfo.name);
					tooltipText = TooltipText_AddIconLine(tooltipText, dfFyrakkAssaultsAreaPoiInfo.mapInfo.name, dfFyrakkAssaultsAreaPoiInfo.atlasName);
					tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, dfFyrakkAssaultsAreaPoiInfo.timeString);
					if not ns.settings.hideEventDescriptions then
						tooltipText = TooltipText_AddObjectiveLine(tooltipText, dfFyrakkAssaultsAreaPoiInfo.description);
					end
				end
			end
			-- Researchers Under Fire
			if ns.settings.showResearchersUnderFireInfo then
				local dfResearchersUnderFireInfo = util.poi.GetResearchersUnderFireDataInfo();
				if dfResearchersUnderFireInfo then
					tooltipText = TooltipText_AddHeaderLine(tooltipText, dfResearchersUnderFireInfo.name);
					tooltipText = TooltipText_AddIconLine(tooltipText, dfResearchersUnderFireInfo.mapInfo.name, dfResearchersUnderFireInfo.atlasName);
					tooltipText = TooltipText_AddObjectiveLine(tooltipText, dfResearchersUnderFireInfo.areaName);
					tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, dfResearchersUnderFireInfo.timeString);
					if not ns.settings.hideEventDescriptions then
						tooltipText = TooltipText_AddObjectiveLine(tooltipText, dfResearchersUnderFireInfo.description);
					end
				end
			end
			-- Time Rifts 
			if ns.settings.showTimeRiftInfo then
				local dfTimeRiftsInfo = util.poi.GetTimeRiftInfo()
				if dfTimeRiftsInfo then
					tooltipText = TooltipText_AddHeaderLine(tooltipText, dfTimeRiftsInfo.name)
					tooltipText = TooltipText_AddIconLine(tooltipText, dfTimeRiftsInfo.mapInfo.name, dfTimeRiftsInfo.atlasName)
					tooltipText = TooltipText_AddObjectiveLine(tooltipText, dfTimeRiftsInfo.areaName)
					tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, dfTimeRiftsInfo.timeString)
					if not ns.settings.hideEventDescriptions then
						tooltipText = TooltipText_AddObjectiveLine(tooltipText, dfTimeRiftsInfo.description)
					end
				end
			end
			-- Dreamsurge
			if ns.settings.showDreamsurgeInfo then
				local dfDreamsurgeInfo = util.poi.GetDreamsurgeInfo()
				if dfDreamsurgeInfo then
					tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showDreamsurgeInfo"])
					tooltipText = TooltipText_AddIconLine(tooltipText, dfDreamsurgeInfo.mapInfo.name, dfDreamsurgeInfo.atlasName)
					tooltipText = TooltipText_AddObjectiveLine(tooltipText, dfDreamsurgeInfo.areaName)
					tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, dfDreamsurgeInfo.timeString)
					tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, dfDreamsurgeInfo.nextSurgeTimeString)
				end
			end
			-- Superbloom
			if ns.settings.showSuperbloomInfo then
				local dfSuperbloomInfo = util.poi.GetSuperbloomInfo()
				if dfSuperbloomInfo then
					tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showSuperbloomInfo"] or dfSuperbloomInfo.name)
					tooltipText = TooltipText_AddIconLine(tooltipText, dfSuperbloomInfo.mapInfo.name, dfSuperbloomInfo.atlasName)
					tooltipText = TooltipText_AddObjectiveLine(tooltipText, dfSuperbloomInfo.areaName)
					tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, dfSuperbloomInfo.timeString)
				end
			end
			-- The Big Dig
			if ns.settings.showTheBigDigInfo then
				local dfTheBigDigInfo = util.poi.GetTheBigDigInfo()
				if dfTheBigDigInfo then
					tooltipText = TooltipText_AddHeaderLine(tooltipText, L["showTheBigDigInfo"] or dfTheBigDigInfo.name)
					tooltipText = TooltipText_AddIconLine(tooltipText, dfTheBigDigInfo.name, dfTheBigDigInfo.atlasName)
					tooltipText = TooltipText_AddObjectiveLine(tooltipText, dfTheBigDigInfo.mapInfo.name)
					tooltipText = TooltipText_AddObjectiveLine(tooltipText, dfTheBigDigInfo.areaName)
					tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, dfTheBigDigInfo.timeString)
				end
			end
		end
	end

	----- Timewalking Vendor (currently Draenor + Legion only) -----
	if ShouldShowTimewalkingVendorText(garrInfo.expansion) then
		local vendorAreaPoiInfo = util.poi.FindTimewalkingVendor(garrInfo.expansion);
		if vendorAreaPoiInfo then
			tooltipText = TooltipText_AddHeaderLine(tooltipText, vendorAreaPoiInfo.name);
			tooltipText = TooltipText_AddIconLine(tooltipText, vendorAreaPoiInfo.mapInfo.name, vendorAreaPoiInfo.atlasName);
			tooltipText = TooltipText_AddTimeRemainingLine(tooltipText, vendorAreaPoiInfo.timeString);
		end
	end

	----- Tests -----

	if (_log.DEVMODE) then  -- and not isForLegion) then
		tooltipText = tooltipText.."|n|n"..DIM_GREEN_FONT_COLOR:WrapTextInColorCode(EVENTS_LABEL);
		for _, mapID in ipairs(garrInfo.continents) do
			local poiInfos = util.map.GetAreaPOIInfoForContinent(mapID);
			tooltipText = AddMultiPOITestText(poiInfos, tooltipText);
		end
		if garrInfo.poiZones then
			local zonePoiInfos = util.map.GetAreaPOIInfoForZones(garrInfo.poiZones);
			tooltipText = AddMultiPOITestText(zonePoiInfos, tooltipText);
		end
	end

	return tooltipText
end

-- Create the minimap button's dropdown frame.
function MRBP:GarrisonLandingPageDropDown_OnLoad()
	_log:info("Creating dropdown menu...")

	self.dropdown = CreateFrame("Frame", AddonID.."GarrisonLandingPageDropDownFrame", UIParent, "UIDropDownMenuTemplate")
	self.dropdown:SetClampedToScreen(true)
	self.dropdown.point = "TOPRIGHT"  --> default: "TOPLEFT"
	self.dropdown.relativePoint = "BOTTOMRIGHT"  --> default: "BOTTOMLEFT"

	UIDropDownMenu_Initialize(self.dropdown, self.GarrisonLandingPageDropDown_Initialize, ns.settings.menuStyleID == "1" and "MENU" or '')
end

-- Create the dropdown menu items.
--> **Note:** 'self' refers in this case to the dropdown menu frame.
---@param level number  Level number of submenus
--
function MRBP:GarrisonLandingPageDropDown_Initialize(level)
	_log:info("Initializing drop-down menu...");
	local sortFunc = ns.settings.reverseSortorder and util.expansion.SortAscending or util.expansion.SortDescending;
	local expansionList = util.expansion.GetExpansionsWithLandingPage(sortFunc);
	local filename, width, height, txLeft, txRight, txTop, txBottom;  --> needed for not showing mission type icons
	local activeThreats = util.threats.GetActiveThreats();

	for _, expansion in ipairs(expansionList) do
		local garrTypeID = expansion.garrisonTypeID;
		local garrInfo = MRBP_GARRISON_TYPE_INFOS[garrTypeID];
		if ns.settings.showMissionTypeIcons then
			filename, width, height, txLeft, txRight, txTop, txBottom = util.GetAtlasInfo(garrInfo.minimapIcon);
		end
		garrInfo.shouldShowDisabled = not MRBP_IsGarrisonRequirementMet(garrTypeID);
		local playerOwnsExpansion = util.expansion.DoesPlayerOwnExpansion(garrInfo.expansion.ID);
		local isActiveEntry = tContains(ns.settings.activeMenuEntries, tostring(garrInfo.expansion.ID)) ; --> user option
		garrInfo.missions = {};
		garrInfo.missions.numInProgress, garrInfo.missions.numCompleted = util.garrison.GetInProgressMissionCount(garrTypeID);

		_log:debug(string.format("Got %s - owned: %s, disabled: %s",
		   NORMAL_FONT_COLOR:WrapTextInColorCode(garrInfo.expansion.name),
		   NORMAL_FONT_COLOR:WrapTextInColorCode(tostring(playerOwnsExpansion)),
		   NORMAL_FONT_COLOR:WrapTextInColorCode(tostring(garrInfo.shouldShowDisabled)))
		)

		if (playerOwnsExpansion and isActiveEntry) then
			-- Create a menu entry for each expansion
			local info = UIDropDownMenu_CreateInfo();
			info.owner = ExpansionLandingPageMinimapButton;
			info.text = BuildMenuEntryLabel(garrInfo);
			info.notCheckable = 1;
			info.tooltipOnButton = ns.settings.showEntryTooltip and 1 or nil;
			info.tooltipTitle = ns.settings.preferExpansionName and garrInfo.title or garrInfo.expansion.name;
			info.tooltipText = BuildMenuEntryTooltip(garrInfo, activeThreats);
			-- info.tooltipWarning = "Warning example";
			if ns.settings.showMissionTypeIcons then
				info.icon = filename;
				-- info.iconTooltipTitle = "Testtitle";
				-- info.iconTooltipText = "Testtext";
				info.tCoordLeft = txLeft;
				info.tCoordRight = txRight;
				info.tCoordTop = txTop;
				info.tCoordBottom = txBottom;
				info.tSizeX = 20;  -- width
				info.tSizeY = 20;  -- height
			end
			info.func = function() MRBP_ToggleLandingPageFrames(garrTypeID) end;
			info.disabled = garrInfo.shouldShowDisabled;
			info.tooltipWhileDisabled = 1;

			UIDropDownMenu_AddButton(info, level);
		end
	end
	if tContains(ns.settings.activeMenuEntries, ns.settingsMenuEntry) then
		-- Add settings button
		if ns.settings.showMissionTypeIcons then
			filename, width, height, txLeft, txRight, txTop, txBottom = util.GetAtlasInfo("Warfronts-BaseMapIcons-Empty-Workshop-Minimap");
		end
		local info = UIDropDownMenu_CreateInfo()
		info.notCheckable = true
		info.text = SETTINGS  --> WoW global string
		info.colorCode = NORMAL_FONT_COLOR:GenerateHexColorMarkup()
		if ns.settings.showMissionTypeIcons then
			info.icon = filename
			info.tSizeX = width
			info.tSizeY = height
			info.tCoordLeft = txLeft
			info.tCoordRight = txRight
			info.tCoordTop = txTop
			info.tCoordBottom = txBottom
		end
		info.func = function(self)
			MRBP_Settings_OpenToCategory(AddonID);
		end
		info.tooltipOnButton = 1
		info.tooltipTitle = SETTINGS  --> WoW global string
		info.tooltipText = BASIC_OPTIONS_TOOLTIP  --> WoW global string
		-- info.tooltipBackdropStyle = BACKDROP_GOLD_DIALOG_32_32;

		UIDropDownMenu_AddButton(info)
	end
end

local function MRBP_ReloadDropdown()
	MRBP.dropdown = nil
	MRBP:GarrisonLandingPageDropDown_OnLoad()
end
ns.MRBP_ReloadDropdown = MRBP_ReloadDropdown

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
		ExpansionLandingPageMinimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
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

-- Release the given `LibQTip.Tooltip`.
---@param tooltip LibQTip.Tooltip
--
local function ReleaseTooltip(tooltip)
	if tooltip then
		-- print("Leaving", tooltip, "-->", tooltip.key)
		-- tooltip:SetFrameStrata("TOOLTIP")
		LibQTip:Release(tooltip)
		tooltip = nil
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
	ReleaseTooltip(ExpansionTooltip)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	GameTooltip:SetText(self.title, 1, 1, 1);
	GameTooltip:AddLine(self.description, nil, nil, nil, true);

	local tooltipAddonText = L.TOOLTIP_CLICKTEXT_MINIMAPBUTTON;
	if ns.settings.showAddonNameInTooltip then
		local addonAbbreviation = ns.AddonTitleShort..ns.AddonTitleSeparator;
		tooltipAddonText = GRAY_FONT_COLOR:WrapTextInColorCode(addonAbbreviation).." "..tooltipAddonText;
	end
	_log:debug_type(_log.type.CALENDAR, "Scanning for WINTER_HOLIDAY_EVENT...")
	local dayEvent = util.calendar.GetActiveDayEvent(util.calendar.WINTER_HOLIDAY_EVENT_ID);
	if dayEvent then
		-- Show an icon after the minimap tooltip text during the winter holiday event
		local eventIcon = util.calendar.WINTER_HOLIDAY_ATLAS_NAME;
		tooltipAddonText = tooltipAddonText.." "..util.CreateInlineIcon1(eventIcon);
	end
	GameTooltip_AddNormalLine(GameTooltip, tooltipAddonText);

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

local uiScale = UIParent:GetEffectiveScale()
local screenHeight = GetScreenHeight() * uiScale

local function ShowExpansionTooltip()
	-- Compare tooltip height with screen height
	local questLineHeight = ExpansionTooltip:GetHeight() * uiScale
	if (questLineHeight > screenHeight) then
		ExpansionTooltip:UpdateScrolling()
		ExpansionTooltip:SetScrollStep(50)
	end
	ExpansionTooltip:SetClampedToScreen(true)
	if not ExpansionTooltip:IsShown() then
		ExpansionTooltip:Show()
	end
end

function Tooltip_AddObjectiveLine(tooltipText, text, isCompleted, lineColor, appendCompleteIcon, alternativeIcon, isTrackingAchievement)
	if L:StringIsEmpty(text) then return tooltipText; end

	local isIconString = alternativeIcon == nil;
	local checkMarkIconString = isTrackingAchievement and TOOLTIP_YELLOW_CHECK_MARK_ICON_STRING or TOOLTIP_CHECK_MARK_ICON_STRING;
	if not isCompleted then
		return TooltipText_AddIconLine(tooltipText, text, alternativeIcon or TOOLTIP_DASH_ICON_STRING, lineColor, isIconString);
	elseif appendCompleteIcon then
		-- Append icon at line end
		tooltipText = TooltipText_AddIconLine(tooltipText, text, alternativeIcon or TOOLTIP_DASH_ICON_STRING, DISABLED_FONT_COLOR, isIconString);
		return tooltipText.." "..checkMarkIconString;
	else
		-- Replace the dash icon with the check mark icon
		return TooltipText_AddIconLine(tooltipText, text, alternativeIcon or checkMarkIconString, DISABLED_FONT_COLOR, isIconString);
	end
end

----- LibQTip -----

local maxWidth, minWidth = 250, nil

local function ExpansionTooltip_AddHeaderLine(text, TextColor, isTooltipTitle, ...)
	if isTooltipTitle then
    	local lineIndex, nextColumnIndex = LocalLibQTipUtil:SetTitle(ExpansionTooltip, text, ...)
		return lineIndex, nextColumnIndex
	end
	LocalLibQTipUtil:AddBlankLineToTooltip(ExpansionTooltip)					--> TODO - Add to options ???
	local FontColor = TextColor or NORMAL_FONT_COLOR
	local lineIndex, nextColumnIndex = LocalLibQTipUtil:AddColoredLine(ExpansionTooltip, FontColor, '', ...)
	ExpansionTooltip:SetCell(lineIndex, 1, text, nil, "LEFT", nil, nil, nil, nil, maxWidth, minWidth)
	lineIndex, nextColumnIndex = ExpansionTooltip:AddSeparator(1, LIGHTGRAY_FONT_COLOR:GetRGBA())
    return lineIndex, nextColumnIndex
end

local function ExpansionTooltip_AddTextLine(text, TextColor, ...)
	local FontColor = TextColor or HIGHLIGHT_FONT_COLOR
	local lineIndex, nextColumnIndex = LocalLibQTipUtil:AddColoredLine(ExpansionTooltip, FontColor, '', ...)
	ExpansionTooltip:SetCell(lineIndex, 1, text, nil, nil, nil, nil, nil, nil, maxWidth, minWidth)
	return lineIndex, nextColumnIndex
end

local function ExpansionTooltip_AddIconLine(text, icon, TextColor, ...)
	if not icon then
		return ExpansionTooltip_AddTextLine(text, TextColor, ...)
	end
	local iconString = util.CreateInlineIcon1(icon)  --> with yOffset = -1
	return ExpansionTooltip_AddTextLine(iconString..TEXT_DELIMITER..text, TextColor, ...)
end

local function ExpansionTooltip_AddObjectiveLine(text, completed, TextColor, ...)
	local iconString = completed and TOOLTIP_CHECK_MARK_ICON_STRING or TOOLTIP_DASH_ICON_STRING
	return ExpansionTooltip_AddTextLine(iconString..TEXT_DELIMITER..text, completed and DISABLED_FONT_COLOR or TextColor, ...)
end

local function ExpansionTooltip_AddAchievementLine(text, icon, TextColor, completed, ...)
	if not completed then
		return ExpansionTooltip_AddIconLine(text, icon, TextColor, ...)
	end
	local lineText = text..TEXT_DELIMITER..TOOLTIP_YELLOW_CHECK_MARK_ICON_STRING
	return ExpansionTooltip_AddIconLine(lineText, icon, completed and DISABLED_FONT_COLOR or TextColor, ...)
end

function ExpansionTooltip_AddTimeRemainingLine(timeString, ...)
	local text = timeString or RETRIEVING_DATA
	local iconStrings = TOOLTIP_DASH_ICON_STRING..TEXT_DELIMITER..TOOLTIP_CLOCK_ICON_STRING
	ExpansionTooltip_AddTextLine(iconStrings..TEXT_DELIMITER..text, ...)
end

-- Create expansion summary content tooltip
function MenuLine_CreateTooltip(parentFrame)
	ExpansionTooltip = LibQTip:Acquire(ShortAddonID.."LibQTooltipExpansionSummary", 1, "LEFT")
	ExpansionTooltip:SetPoint("LEFT", parentFrame, "RIGHT", -5, 0)
	ExpansionTooltip.OnRelease = ReleaseTooltip
	ExpansionTooltip:SetCellMarginV(0)
end

-- Expansion summary content
function MenuLine_OnEnter(...)
	local lineFrame, expansionInfo, _ = ...
	-- Empty eventual previous content
	ExpansionTooltip:Clear()
	-- Tooltip header (title + description)
	local garrisonInfo = MRBP_GARRISON_TYPE_INFOS[expansionInfo.garrisonTypeID]
	local isSettingsLine = expansionInfo.ID == nil
	local tooltipTitle = (ns.settings.preferExpansionName and not isSettingsLine) and garrisonInfo.title or expansionInfo.name
	ExpansionTooltip_AddHeaderLine(isSettingsLine and expansionInfo.label or tooltipTitle, nil, true)
	local tooltipDescription = expansionInfo.description or garrisonInfo.description
	if tooltipDescription then
		local FontColor = expansionInfo.disabled and DISABLED_FONT_COLOR or NORMAL_FONT_COLOR
		ExpansionTooltip_AddTextLine(tooltipDescription, FontColor, ...)
	end
	if isSettingsLine then
		-- Stop here; no content body for the settings line
		ShowExpansionTooltip()
		return
	end
	-- Tooltip body
	local isForShadowlands = expansionInfo.garrisonTypeID == util.expansion.data.Shadowlands.garrisonTypeID

	------ Unlocking Requirements -----

	if expansionInfo.disabled then
		-- Show requirement info for unlocking the given expansion type
		LocalLibQTipUtil:AddBlankLineToTooltip(ExpansionTooltip)
		ExpansionTooltip_AddTextLine(garrisonInfo.msg.requirementText, DIM_RED_FONT_COLOR, ...)
		-- Stop here; no content for locked expansions
		ShowExpansionTooltip()
		return
	end

	----- In-progress missions -----

	if ShouldShowMissionsInfoText(expansionInfo.garrisonTypeID) then
		local numInProgress, numCompleted = util.garrison.GetInProgressMissionCount(expansionInfo.garrisonTypeID)
		local hasCompletedAllMissions = numCompleted > 0 and numCompleted == numInProgress
		ExpansionTooltip_AddHeaderLine(garrisonInfo.msg.missionsTitle)
		-- Mission counter
		if (numInProgress > 0) then
			local progressText = string.format(garrisonInfo.msg.missionsReadyCount, numCompleted, numInProgress)
			ExpansionTooltip_AddObjectiveLine(progressText, hasCompletedAllMissions)
		else
			-- No missions active
			ExpansionTooltip_AddTextLine(garrisonInfo.msg.missionsEmptyProgress)
		end
		-- Return to base info
		if ShouldShowMissionCompletedHint(expansionInfo.garrisonTypeID) then
			ExpansionTooltip_AddTextLine(garrisonInfo.msg.missionsComplete)
		end
	end

	----- Bounty board infos (Legion + BfA + Shadowlands only) -----

	if ShouldShowBountyBoardText(expansionInfo.garrisonTypeID) then
		-- Only available since Legion (WoW 7.x); no longer useful in Dragonflight (WoW 10.x)
		local bountyBoard = garrisonInfo.bountyBoard
		if bountyBoard.AreBountiesUnlocked() then
			local bounties = bountyBoard.GetBounties()
			if (isForShadowlands and #bounties == 0) then
				-- System retrieves callings through event listening and on opening the mission frame; try to update (again).
				CovenantCalling_CheckCallings()
			end
			if (#bounties > 0) then
				ExpansionTooltip_AddHeaderLine(bountyBoard.title)
				for _, bountyData in ipairs(bounties) do
					if bountyData then
						local questName = QuestUtils_GetQuestName(bountyData.questID)
						if isForShadowlands then
							-- Shadowland bounties have a golden border around their icon; need special treatment.
							-- REF.: CreateTextureMarkup(file, fileWidth, fileHeight, width, height, left, right, top, bottom, xOffset, yOffset)
							local iconString = CreateTextureMarkup(bountyData.icon, 256, 256, 16, 16, 0.28, 0.74, 0.26, 0.72, 1, -1);
							questName = iconString..TEXT_DELIMITER..questName
						end
						local bountyIcon = not isForShadowlands and bountyData.icon or nil
						if bountyData.turninRequirementText then
							ExpansionTooltip_AddIconLine(questName, bountyIcon, DISABLED_FONT_COLOR)
							-- if ns.settings.showBountyRequirements then		--> TODO - Re-add option to settings
							ExpansionTooltip_AddObjectiveLine(bountyData.turninRequirementText, nil, WARNING_FONT_COLOR)
							-- end
						else
							ExpansionTooltip_AddIconLine(questName, bountyIcon)
						end
					end
				end
			elseif not isForShadowlands then									--> TODO - Check if still needed
				ExpansionTooltip_AddObjectiveLine(bountyBoard.noBountiesMessage)
			end
		end
	end

	----- Warlords of Draenor -----

	local isForWarlordsOfDraenor = expansionInfo.garrisonTypeID == util.expansion.data.WarlordsOfDraenor.garrisonTypeID

	-- Garrison Invasion
	if (isForWarlordsOfDraenor and ns.settings.showWoDGarrisonInvasionAlert and util.garrison.IsDraenorInvasionAvailable()) then
		ExpansionTooltip_AddHeaderLine( L["showWoDGarrisonInvasionAlert"] )
		ExpansionTooltip_AddIconLine(GARRISON_LANDING_INVASION_ALERT, "worldquest-tracker-questmarker", WARNING_FONT_COLOR)
		ExpansionTooltip_AddTextLine(GARRISON_LANDING_INVASION_TOOLTIP)
		-- Stop here; end of WoD content
		ShowExpansionTooltip()
		return
	end

	----- Legion -----

	local isForLegion = expansionInfo.garrisonTypeID == util.expansion.data.Legion.garrisonTypeID

	if (isForLegion and ns.settings.showLegionWorldMapEvents) then
		-- Legion Invasion
		if ns.settings.showLegionAssaultsInfo then
			local legionAssaultsAreaPoiInfo = util.poi.GetLegionAssaultsInfo()
			if legionAssaultsAreaPoiInfo then
				ExpansionTooltip_AddHeaderLine(legionAssaultsAreaPoiInfo.name)
				ExpansionTooltip_AddIconLine(legionAssaultsAreaPoiInfo.parentMapInfo.name, legionAssaultsAreaPoiInfo.atlasName, legionAssaultsAreaPoiInfo.color)
				ExpansionTooltip_AddTimeRemainingLine(legionAssaultsAreaPoiInfo.timeString)
				ExpansionTooltip_AddObjectiveLine(legionAssaultsAreaPoiInfo.description, legionAssaultsAreaPoiInfo.isCompleted) --, legionAssaultsAreaPoiInfo.isCompleted)
			end
		end
		-- Demon Invasions (Broken Shores)
		if ns.settings.showBrokenShoreInvasionInfo then
			local demonAreaPoiInfos = util.poi.GetBrokenShoreInvasionInfo()
			if util.TableHasAnyEntries(demonAreaPoiInfos) then
				ExpansionTooltip_AddHeaderLine( L["showBrokenShoreInvasionInfo"] )
				for _, demonPoi in ipairs(demonAreaPoiInfos) do
					ExpansionTooltip_AddIconLine(demonPoi.name, demonPoi.atlasName, demonPoi.color)
					ExpansionTooltip_AddTimeRemainingLine(demonPoi.timeString)
				end
			end
		end
		-- Invasion Points (Argus)
		if ns.settings.showArgusInvasionInfo then
			local riftAreaPoiInfos = util.poi.GetArgusInvasionPointsInfo()
			if util.TableHasAnyEntries(riftAreaPoiInfos) then
				ExpansionTooltip_AddHeaderLine( L["showArgusInvasionInfo"] )
				for _, riftPoi in ipairs(riftAreaPoiInfos) do
					-- local appendCompleteIcon = true
					-- tooltipText = TooltipText_AddObjectiveLine(tooltipText, riftPoi.description, riftPoi.isCompleted, riftPoi.color, appendCompleteIcon, riftPoi.atlasName, riftPoi.isCompleted)
					ExpansionTooltip_AddAchievementLine(riftPoi.description, riftPoi.atlasName, riftPoi.color, riftPoi.isCompleted)
					ExpansionTooltip_AddObjectiveLine(riftPoi.mapInfo.name)
					ExpansionTooltip_AddTimeRemainingLine(riftPoi.timeString)
				end
			end
		end
		-- Stop here; end of Legion content
		ShowExpansionTooltip()
		return
	end

	----- Shadowlands -----

	if (isForShadowlands and ns.settings.showCovenantRenownLevel) then
		local covenantInfo = util.covenant.GetCovenantInfo()
		if util.TableHasAnyEntries(covenantInfo) then
			ExpansionTooltip_AddHeaderLine( L["showCovenantRenownLevel"] )
			local renownInfo = util.covenant.GetRenownData(covenantInfo.ID)
			if renownInfo then
				local FontColor = ns.settings.applyCovenantColors and covenantInfo.color or nil
				local lineText = covenantInfo.name
				local progressText = MAJOR_FACTION_RENOWN_CURRENT_PROGRESS:format(renownInfo.currentRenownLevel, renownInfo.maximumRenownLevel)
				if renownInfo.hasMaximumRenown then
					-- Append max. level after covenant name
					local renownLevelText = MAJOR_FACTION_BUTTON_RENOWN_LEVEL:format(renownInfo.currentRenownLevel)
					lineText = lineText..TEXT_DELIMITER..HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(PARENS_TEMPLATE:format(renownLevelText))
					progressText = COVENANT_SANCTUM_RENOWN_REWARD_TITLE_COMPLETE
				end
				ExpansionTooltip_AddAchievementLine(lineText, covenantInfo.atlasName, FontColor, covenantInfo.isCompleted)
				ExpansionTooltip_AddObjectiveLine(progressText, renownInfo.hasMaximumRenown)
			end
		end
		-- Stop here; end of Shadowlands content
		ShowExpansionTooltip()
		return
	end

	ShowExpansionTooltip()
end

local function AddMenuTooltipLine(info)
	local name = info.color and info.color:WrapTextInColorCode(info.label) or info.label
	local lineIndex = MenuTooltip:AddLine(info.iconString or '', '', info.minimapIcon or '')
	-- REF.: qTip:SetCell(lineNum, colNum, value[, font][, justification][, colSpan][, provider][, leftPadding][, rightPadding][, maxWidth][, minWidth][, ...])
	MenuTooltip:SetCell(lineIndex, 2, name, nil, nil, nil, nil, nil, nil, nil, 150)
	if ns.settings.showEntryTooltip then
		MenuTooltip:SetLineScript(lineIndex, "OnEnter", MenuLine_OnEnter, info)
		MenuTooltip:SetLineScript(lineIndex, "OnLeave", ReleaseTooltip)
	end
	if info.func then
		MenuTooltip:SetLineScript(lineIndex, "OnMouseUp", MenuLine_OnClick, info)
	end
	if info.disabled then
    	MenuTooltip:SetLineTextColor(lineIndex, DISABLED_FONT_COLOR:GetRGBA())
	end
end

local settingsInfo = {
	label = SETTINGS,
	description = BASIC_OPTIONS_TOOLTIP,
	color = NORMAL_FONT_COLOR,
	iconString = util.CreateInlineIcon1("Warfronts-BaseMapIcons-Empty-Workshop-Minimap"),
	func = function() MRBP_Settings_OpenToCategory(AddonID) end
}

local function ShowMenuTooltip(parent)
	ReleaseTooltip(MenuTooltip)
	-- Create dropdown menu from tooltip
	MenuTooltip = LibQTip:Acquire(ShortAddonID.."LibQTooltipMenu", 3, "CENTER", "LEFT", "CENTER")
	-- MenuTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 10, 0)
	MenuTooltip:SetPoint("TOPRIGHT", parent, "BOTTOM", 12, 5)
	MenuTooltip:SetFrameStrata("MEDIUM")
	MenuTooltip:SetAutoHideDelay(0.25, parent)
	MenuTooltip.OnRelease = function(self)
		ReleaseTooltip(self)
		ReleaseTooltip(ExpansionTooltip)
	end
	-- Expansion list
	local sortFunc = ns.settings.reverseSortorder and util.expansion.SortAscending or util.expansion.SortDescending
	local expansionList = util.expansion.GetExpansionsWithLandingPage(sortFunc)
	for _, expansionInfo in ipairs(expansionList) do
		local garrisonInfo = MRBP_GARRISON_TYPE_INFOS[expansionInfo.garrisonTypeID]
		expansionInfo.label = ns.settings.preferExpansionName and expansionInfo.name or garrisonInfo.title
		expansionInfo.minimapIcon = ns.settings.showMissionTypeIcons and util.CreateInlineIcon(garrisonInfo.minimapIcon)
		expansionInfo.disabled = not MRBP_IsGarrisonRequirementMet(expansionInfo.garrisonTypeID)
		expansionInfo.iconString = ShouldShowMissionCompletedHint(expansionInfo.garrisonTypeID) and util.CreateInlineIcon("QuestNormal") or nil
		expansionInfo.func = function() MRBP_ToggleLandingPageFrames(expansionInfo.garrisonTypeID) end
		local playerOwnsExpansion = util.expansion.DoesPlayerOwnExpansion(expansionInfo.ID)
		local isActiveEntry = tContains(ns.settings.activeMenuEntries, tostring(expansionInfo.ID))  --> user option
		if (playerOwnsExpansion and isActiveEntry) then
			AddMenuTooltipLine(expansionInfo)
		end
	end
	-- Options
	if tContains(ns.settings.activeMenuEntries, ns.settingsMenuEntry) then
		MenuTooltip:AddSeparator()
		AddMenuTooltipLine(settingsInfo)
	end
	-- Content tooltip
	if ns.settings.showEntryTooltip then
		MenuLine_CreateTooltip(MenuTooltip)
	end
	MenuTooltip:Show()
end

-- Handle click behavior of the minimap button.
---@param self table  The 'ExpansionLandingPageMinimapButton' itself
---@param button string  Name of the button which has been clicked
---@param isDown boolean  The state of the button, eg. pressed (true) or released (false)
--
function MRBP_OnClick(self, button, isDown)
	_log:debug(string.format("Got mouse click: %s, isDown: %s", button, tostring(isDown)))

	if (button == "RightButton") then
		-- UIDropDownMenu_Refresh(MRBP.dropdown)
		-- ToggleDropDownMenu(1, nil, MRBP.dropdown, self, -14, 5)
		ShowMenuTooltip(self)
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
	_log:debug("Opening report for garrTypeID:", garrTypeID, MRBP_GARRISON_TYPE_INFOS[garrTypeID].title)

	if (GarrisonLandingPageReport ~= nil) then
		if (garrTypeID ~= util.expansion.data.Shadowlands.garrisonTypeID) then
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
	if  (garrTypeID ~= util.expansion.data.WarlordsOfDraenor.garrisonTypeID or ns.settings.hideWoDGarrisonInvasionAlertIcon) and GarrisonLandingPage.InvasionBadge:IsShown() then
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

	if (garrTypeID > 0 and not MRBP_IsGarrisonRequirementMet(garrTypeID) ) then
		-- Build and return garrison type ID of previous expansion.
		local minExpansionID = util.expansion.GetMinimumExpansionLevel()  --> min. available, eg. 8 (Shadowlands)
		-- Need last attribute of eg. 'Enum.GarrisonType.Type_8_0_Garrison'
		local garrTypeID_Minimum = Enum.GarrisonType["Type_"..tostring(minExpansionID).."_0"]

		if (_log.level == _log.DEBUG) then
			-- Tests
			local playerExpansionID = util.expansion.GetExpansionForPlayerLevel()
			local maxExpansionID = util.expansion.GetMaximumExpansionLevel()  --> max. available, eg. 9 (Dragonflight)
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
	return garrTypeID
end

--> TODO - Find a more secure way to pre-hook this.
MRBP_GetLandingPageGarrisonType_orig = C_Garrison.GetLandingPageGarrisonType
C_Garrison.GetLandingPageGarrisonType = MRBP_GetLandingPageGarrisonType

----- Slash commands -----------------------------------------------------------

local SLASH_CMD_ARGLIST = {
	-- arg, description
	{"chatmsg", L.SLASHCMD_DESC_CHATMSG},
	{"show", L.SLASHCMD_DESC_SHOW},
	{"hide", L.SLASHCMD_DESC_HIDE},
	{"hook", L.SLASHCMD_DESC_HOOK},
	{"config", BASIC_OPTIONS_TOOLTIP},  --> WoW global string
	--> TODO - "about"
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
				MRBP_Settings_OpenToCategory(AddonID);

			-- elseif (msg == 'about') then
			-- 	MRBP_Settings_OpenToCategory("AboutFrame");

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
				local prev_loglvl = _log.level
				_log:info("Current GarrisonType:", MRBP_GetLandingPageGarrisonType())
				_log.level = _log.DEBUG

				local expansionList = util.expansion.GetExpansionsWithLandingPage();
				for _, expansion in ipairs(expansionList) do
					local garrTypeID = expansion.garrisonTypeID;
					local garrInfo = MRBP_GARRISON_TYPE_INFOS[garrTypeID]
				   _log:debug("HasGarrison:", util.garrison.HasGarrison(garrTypeID),
							--   "-", string.format("%-3d", garrTypeID), garrInfo.expansion.name,
							  "- req:", MRBP_IsGarrisonRequirementMet(garrTypeID),
							--   "- unlocked:", garrInfo:IsUnlocked())
							  "- unlocked:", MRBP_IsGarrisonTypeUnlocked(garrTypeID, garrInfo.tagName))
				end

				local playerLevel = UnitLevel("player")
				local expansionLevelForPlayer = util.expansion.GetExpansionForPlayerLevel(playerLevel)
				local playerMaxLevelForExpansion = util.expansion.GetMaxPlayerLevel()
				local expansion = util.expansion.GetExpansionData(expansionLevelForPlayer)

				_log:debug("expansionLevelForPlayer:", expansionLevelForPlayer, ",", expansion.name)
				_log:debug("playerLevel:", playerLevel)
				_log:debug("playerMaxLevelForExpansion:", playerMaxLevelForExpansion)

				_log.level = prev_loglvl
			end
			---------------------
		else
			-- Print this to chat even if the notifications are disabled
			local prev_loglvl = _log.level
			_log.level = _log.USER

			util.printVersion();
			ns.cprint(YELLOW_FONT_COLOR:WrapTextInColorCode(L.CHATMSG_SYNTAX_INFO_S:format(SLASH_MRBP1)).."|n")
			local name, desc
			for _, info in pairs(SLASH_CMD_ARGLIST) do
				name, desc = SafeUnpack(info)
				print("   "..YELLOW_FONT_COLOR:WrapTextInColorCode(name)..": "..desc)
			end

			_log.level = prev_loglvl
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

-- function MissionReportButtonPlus_OnAddonCompartmentEnter(addonName, button)
function ns.MissionReportButtonPlus_OnAddonCompartmentEnter(button)
	local addonTitle = button.value;
	local leftOffset = 1;
	local wrapLine = false;
	local tooltip = GameTooltip;

	tooltip:SetOwner(button, "ANCHOR_LEFT");
	GameTooltip_SetTitle(tooltip, addonTitle);
	GameTooltip_AddNormalLine(tooltip, MRBP_OnEnter(ExpansionLandingPageMinimapButton, nil, true), wrapLine);
	--> The above line doesn't show up if the ExpansionLandingPageButton doesn't exist
	util.GameTooltip_AddAtlas(tooltip, "newplayertutorial-icon-mouse-leftbutton");
	GameTooltip_AddNormalLine(tooltip, BASIC_OPTIONS_TOOLTIP);
	util.GameTooltip_AddAtlas(tooltip, "newplayertutorial-icon-mouse-rightbutton");
	if MRBP_IsGarrisonRequirementMet(Enum.ExpansionLandingPageType.Dragonflight) then
		GameTooltip_AddNormalLine(tooltip, GENERIC_TRAIT_FRAME_DRAGONRIDING_TITLE.." - "..LANDING_DRAGONRIDING_PANEL_SUBTITLE);
		util.GameTooltip_AddAtlas(tooltip, "newplayertutorial-icon-mouse-middlebutton");
	end
	-- GameTooltip_AddBlankLineToTooltip(tooltip);

	-- Display data for each expansion
	local sortFunc = ns.settings.reverseSortorder and util.expansion.SortAscending or util.expansion.SortDescending;
	local expansionList = util.expansion.GetExpansionsWithLandingPage(sortFunc);
	local activeThreats = util.threats.GetActiveThreats();

	for _, expansion in ipairs(expansionList) do
		local garrInfo = MRBP_GARRISON_TYPE_INFOS[expansion.garrisonTypeID];
		garrInfo.shouldShowDisabled = not MRBP_IsGarrisonRequirementMet(expansion.garrisonTypeID);
		local playerOwnsExpansion = util.expansion.DoesPlayerOwnExpansion(expansion.ID);
		local isActiveEntry = tContains(ns.settings.activeMenuEntries, tostring(expansion.ID)); --> user option
		garrInfo.missions = {};
		garrInfo.missions.numInProgress, garrInfo.missions.numCompleted = util.garrison.GetInProgressMissionCount(expansion.garrisonTypeID);

		if (playerOwnsExpansion and isActiveEntry) then
			if garrInfo.shouldShowDisabled then
				GameTooltip_AddDisabledLine(tooltip, expansion.name);
				util.GameTooltip_AddAtlas(tooltip, garrInfo.minimapIcon, 36, 36, Enum.TooltipTextureAnchor.RightCenter);
				GameTooltip_AddErrorLine(tooltip, garrInfo.msg.requirementText, nil, leftOffset);
			else
				-- Expansion name
				GameTooltip_AddHighlightLine(tooltip, expansion.name);
				util.GameTooltip_AddAtlas(tooltip, garrInfo.minimapIcon, 36, 36, Enum.TooltipTextureAnchor.RightCenter);
				-- Major Factions
				local majorFactionData = util.garrison.GetAllMajorFactionDataForExpansion(expansion.ID);
				if util.TableHasAnyEntries(majorFactionData) then
					for _, factionData in ipairs(majorFactionData) do
						if factionData.isUnlocked then
							local factionAtlasName = "MajorFactions_MapIcons_"..factionData.textureKit.."64";
							local factionColor = util.garrison.GetMajorFactionColor(factionData);  -- WHITE_FONT_COLOR
							local renownLevelText = factionColor:WrapTextInColorCode(MAJOR_FACTION_BUTTON_RENOWN_LEVEL:format(factionData.renownLevel));
							local reputationLevelText = format("%d/%d", factionData.renownReputationEarned, factionData.renownLevelThreshold);
							local hasMaxRenown = util.garrison.HasMaximumMajorFactionRenown(factionData.factionID);
							local lineText = format("%s: %s - %s", util.strip_DE_hyphen(factionData.name), renownLevelText, reputationLevelText);
							if hasMaxRenown then
								lineText = format("%s: %s", util.strip_DE_hyphen(factionData.name), renownLevelText);
							end
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, hasMaxRenown, wrapLine, leftOffset, factionAtlasName);
						end
					end
				end
				-- Dragon Glyphs
				if (expansion.ID == util.expansion.data.Dragonflight.ID) then
					local treeCurrencyInfo = util.garrison.GetDragonRidingTreeCurrencyInfo();
					local glyphsPerZone, numGlyphsCollected, numGlyphsTotal = util.garrison.GetDragonGlyphsCount();
					local collectedAmountString = WHITE_FONT_COLOR:WrapTextInColorCode(format("%d/%d", numGlyphsCollected, numGlyphsTotal));
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
						local campAreaPoiInfo = util.poi.GetCampAylaagInfo()
						if campAreaPoiInfo then
							local timeLeft = campAreaPoiInfo.timeString or "..."
							local lineText = format("%s @ %s", campAreaPoiInfo.name, campAreaPoiInfo.areaName)..": "..timeLeft
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, campAreaPoiInfo.isCompleted, wrapLine, leftOffset, campAreaPoiInfo.atlasName)
						end
					end
					-- Grand Hunts
					if ns.settings.showGrandHuntsInfo then
						local huntsAreaPoiInfo = util.poi.GetGrandHuntsInfo();
						if huntsAreaPoiInfo then
							local timeLeft = huntsAreaPoiInfo.timeString or "...";
							local lineText = format("%s @ %s", huntsAreaPoiInfo.name, huntsAreaPoiInfo.mapInfo.name)..": "..timeLeft
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, huntsAreaPoiInfo.atlasName)
						end
					end
					-- Iskaara Community Feast
					if ns.settings.showCommunityFeastInfo then
						local feastAreaPoiInfo = util.poi.GetCommunityFeastInfo()
						if feastAreaPoiInfo then
							local timeLeft = feastAreaPoiInfo.timeString or "..."
							local lineText = format("%s @ %s", L["showCommunityFeastInfo"], feastAreaPoiInfo.name)..": "..timeLeft
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, feastAreaPoiInfo.atlasName)
						end
					end
					-- Siege on Dragonbane Keep
					if ns.settings.showDragonbaneKeepInfo then
						local siegeAreaPoiInfo = util.poi.GetDragonbaneKeepInfo();
						if siegeAreaPoiInfo then
							local timeLeft = siegeAreaPoiInfo.timeString or "...";
							local lineText = siegeAreaPoiInfo.name..": "..timeLeft
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, siegeAreaPoiInfo.atlasName)
						end
					end
					-- Elemental Storms
					if ns.settings.showElementalStormsInfo then
						local stormsAreaPoiInfos = util.poi.GetElementalStormsInfo();
						if util.TableHasAnyEntries(stormsAreaPoiInfos) then
							for _, stormPoi in ipairs(stormsAreaPoiInfos) do
								local timeLeft = stormPoi.timeString or "...";
								local lineText = format("%s @ %s", stormPoi.name, stormPoi.mapInfo.name)..": "..timeLeft
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, stormPoi.atlasName)
							end
						end
					end
					-- Fyrakk Assaults
					if ns.settings.showFyrakkAssaultsInfo then
						local dfFyrakkAssaultsAreaPoiInfo = util.poi.GetFyrakkAssaultsInfo();
						if dfFyrakkAssaultsAreaPoiInfo then
							local timeLeft = dfFyrakkAssaultsAreaPoiInfo.timeString or "...";
							local lineText = format("%s @ %s", dfFyrakkAssaultsAreaPoiInfo.name, dfFyrakkAssaultsAreaPoiInfo.mapInfo.name)..": "..timeLeft
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, dfFyrakkAssaultsAreaPoiInfo.atlasName)
						end
					end
					-- Researchers Under Fire
					if ns.settings.showResearchersUnderFireInfo then
						local dfResearchersUnderFireInfo = util.poi.GetResearchersUnderFireDataInfo();
						if dfResearchersUnderFireInfo then
							local timeLeft = dfResearchersUnderFireInfo.timeString or "...";
							local lineText = dfResearchersUnderFireInfo.name..": "..timeLeft
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, dfResearchersUnderFireInfo.atlasName)
						end
					end
					-- Time Rifts 
					if ns.settings.showTimeRiftInfo then
						local dfTimeRiftsInfo = util.poi.GetTimeRiftInfo();
						if dfTimeRiftsInfo then
							local timeLeft = dfTimeRiftsInfo.timeString or "...";
							local lineText = format("%s @ %s", dfTimeRiftsInfo.name, dfTimeRiftsInfo.mapInfo.name)..": "..timeLeft
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, dfTimeRiftsInfo.atlasName)
						end
					end
					-- Dreamsurge
					if ns.settings.showDreamsurgeInfo then
						local dfDreamsurgeInfo = util.poi.GetDreamsurgeInfo()
						if dfDreamsurgeInfo then
							local timeLeft = dfDreamsurgeInfo.nextSurgeTimeString or dfDreamsurgeInfo.timeString or "...";
							local lineText = format("%s @ %s", L["showDreamsurgeInfo"], dfDreamsurgeInfo.mapInfo.name)..": "..timeLeft
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, dfDreamsurgeInfo.atlasName)
						end
					end
					-- Superbloom
					if ns.settings.showSuperbloomInfo then
						local dfSuperbloomInfo = util.poi.GetSuperbloomInfo()
						if dfSuperbloomInfo then
							local timeLeft = dfSuperbloomInfo.timeString or "...";
							local lineText = format("%s @ %s", dfSuperbloomInfo.name, dfSuperbloomInfo.mapInfo.name)..": "..timeLeft
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, dfSuperbloomInfo.atlasName)
						end
					end
					-- The Big Dig
					if ns.settings.showTheBigDigInfo then
						local dfTheBigDigInfo = util.poi.GetTheBigDigInfo()
						if dfTheBigDigInfo then
							local timeLeft = dfTheBigDigInfo.timeString or "...";
							local lineText = format("%s @ %s", dfTheBigDigInfo.name, dfTheBigDigInfo.mapInfo.name)..": "..timeLeft
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, dfTheBigDigInfo.atlasName)
						end
					end
				end
				if (expansion.ID == util.expansion.data.Shadowlands.ID) then
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
				if (expansion.ID ~= util.expansion.data.Dragonflight.ID and garrInfo.missions.numInProgress > 0) then
					local hasCompletedAllMissions = garrInfo.missions.numCompleted == garrInfo.missions.numInProgress;
					local progressText = string.format("%d/%d", garrInfo.missions.numCompleted, garrInfo.missions.numInProgress);
					util.GameTooltip_AddObjectiveLine(tooltip, garrInfo.msg.missionsTitle..": "..progressText, hasCompletedAllMissions);
				end
				-- Bounty Board + Covenant Callings
				if (expansion.ID ~= util.expansion.data.Dragonflight.ID and
					expansion.ID ~= util.expansion.data.WarlordsOfDraenor.ID) then
					local bountyBoard = garrInfo.bountyBoard;
					if bountyBoard.AreBountiesUnlocked() then
						local bounties = bountyBoard.GetBounties()
						util.GameTooltip_AddObjectiveLine(tooltip, format("%s: %d/3", bountyBoard.title, #bounties), #bounties == 0);
					end
				end
				-- Threats (Maw + N'Zoth)
				if activeThreats then
					local expansionThreats = activeThreats[expansion.ID];
					if expansionThreats then
						if (expansion.ID == util.expansion.data.Shadowlands.ID) then
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
				if (expansion.ID == util.expansion.data.BattleForAzeroth.ID) then
					-- BfA Faction Assaults
					local factionAssaultsAreaPoiInfo = util.poi.GetBfAFactionAssaultsInfo();
					if factionAssaultsAreaPoiInfo then
						local timeLeft = factionAssaultsAreaPoiInfo.timeString or "...";
						local lineText = factionAssaultsAreaPoiInfo.description..": "..timeLeft;
						util.GameTooltip_AddObjectiveLine(tooltip, lineText, factionAssaultsAreaPoiInfo.isCompleted, wrapLine, leftOffset, factionAssaultsAreaPoiInfo.atlasName, factionAssaultsAreaPoiInfo.color, factionAssaultsAreaPoiInfo.isCompleted);
					end
				end
				if (expansion.ID == util.expansion.data.Legion.ID) then
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
				if (expansion.ID == util.expansion.data.WarlordsOfDraenor.ID and util.garrison.IsDraenorInvasionAvailable()) then
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

-- function nMissionReportButtonPlus_OnAddonCompartmentClick(addonName, mouseButton, button)
function ns.MissionReportButtonPlus_OnAddonCompartmentClick(button, _, _, _, mouseButton)
	if (mouseButton == "LeftButton") then
		local result =  MRBP_IsAnyGarrisonRequirementMet();
		if result then
			MRBP_OnClick(button, mouseButton, true);
		end
	end
	if (mouseButton == "RightButton") then
		MRBP_Settings_OpenToCategory(AddonID);
	end
	if (mouseButton == "MiddleButton" and MRBP_IsGarrisonRequirementMet(Enum.ExpansionLandingPageType.Dragonflight)) then
		DragonridingPanelSkillsButtonMixin:OnClick();
	end
end
