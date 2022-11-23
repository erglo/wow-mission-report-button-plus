--------------------------------------------------------------------------------
--[[ Mission Report Button Plus ]]--
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
-- but WITHOUT ANY WARRANTY without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see http://www.gnu.org/licenses.
--
--
-- Files used for reference:
-- REF.: <FrameXML/Blizzard_APIDocumentation/GarrisonConstantsDocumentation.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentation/GarrisonInfoDocumentation.lua>
-- REF.: <FrameXML/GarrisonBaseUtils.lua>
-- REF.: <FrameXML/Minimap.lua>
-- REF.: <FrameXML/SharedColorConstants.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentation/CovenantSanctumDocumentation.lua>
-- REF.: <FrameXML/Blizzard_GarrisonTemplates/Blizzard_GarrisonMissionTemplates.lua>
-- REF.: <FrameXML/Blizzard_APIDocumentation/QuestLogDocumentation.lua>
-- (see also the function comments section for more reference)
--
--------------------------------------------------------------------------------

local AddonID, ns = ...
local L = ns.L
local _log = ns.dbg_logger
local util = ns.utilities

local MRBP_GARRISON_TYPE_INFOS = {}
local MRBP_EventMessagesCounter = {}

----- Main ---------------------------------------------------------------------

local MRBP = CreateFrame("Frame", AddonID.."EventListenerFrame")
--> core functions + event listener

FrameUtil.RegisterFrameForEvents(MRBP, {
	"ADDON_LOADED",
	"PLAYER_ENTERING_WORLD",
	"GARRISON_SHOW_LANDING_PAGE",
	"GARRISON_HIDE_LANDING_PAGE",
	"GARRISON_BUILDING_ACTIVATABLE",
	"GARRISON_MISSION_FINISHED",
	"GARRISON_INVASION_AVAILABLE",
	"GARRISON_TALENT_COMPLETE",
	-- "GARRISON_MISSION_STARTED",  	--> TODO - Track twinks' missions
	-- "QUEST_TURNED_IN",
	-- "QUEST_AUTOCOMPLETE",
	"COVENANT_CALLINGS_UPDATED",
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
						buildingName = util:CreateInlineIcon(texture).." "..buildingName
						if (MRBP_EventMessagesCounter[event][garrisonType][buildingID] == nil) then
							MRBP_EventMessagesCounter[event][garrisonType][buildingID] = false
						end
						if (C_Garrison.IsPlayerInGarrison(garrisonType) or MRBP_EventMessagesCounter[event][garrisonType][buildingID] == false) then
							util:cprintEvent(garrInfo.expansion.name, GARRISON_BUILDING_COMPLETE, buildingName, GARRISON_FINALIZE_BUILDING_TOOLTIP)
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
			--> Draenor garrison only
			local garrInfo = MRBP_GARRISON_TYPE_INFOS[Enum.GarrisonType.Type_6_0]
			util:cprintEvent(garrInfo.expansion.name, GARRISON_LANDING_INVASION, nil, GARRISON_LANDING_INVASION_TOOLTIP)

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
				local missionName = util:CreateInlineIcon(missionIcon)..missionLink
				_log:debug(event, "followerTypeID:", followerTypeID, "missionID:", missionID, missionInfo.name)
				--> TODO - Count and show number of twinks' finished missions ???  --> MRBP_GlobalMissions
				--> TODO - Remove from MRBP_GlobalMissions
				util:cprintEvent(garrInfo.expansion.name, eventMsg, missionName, nil, true)
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
							local nameString = util:CreateInlineIcon(talent.icon).." "..talent.name
							util:cprintEvent(garrInfo.expansion.name, eventMsg, nameString)
						end
					end
				end
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

		elseif (event == "COVENANT_CALLINGS_UPDATED") then
			-- Updates the Shadowlands "bounty board" infos.
			-- REF.: <FrameXML/ObjectAPI/CovenantCalling.lua>
			-- REF.: <FrameXML/Blizzard_APIDocumentation/CovenantCallingsConstantsDocumentation.lua>
			-- REF.: <FrameXML/Blizzard_APIDocumentation/CovenantCallingsDocumentation.lua>
			--> updates on opening the world map in Shadowlands.
			local callings = ...
			_log:debug("Covenant callings received:", #callings)
			MRBP_GARRISON_TYPE_INFOS[Enum.GarrisonType.Type_9_0].bountyBoard.bounties = callings

		elseif (event == "PLAYER_ENTERING_WORLD") then
			local isInitialLogin, isReloadingUi = ...
			_log:info("isInitialLogin:", isInitialLogin, "- isReloadingUi:", isReloadingUi)

			local function printDayEvent()
				local isTodayDayEvent, dayEvent, dayEventMsg = util:IsTodayWorldQuestDayEvent()
				if isTodayDayEvent then
					ns.cprint(dayEventMsg)
				end
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

		end
	end

)

-- Load this add-on's functions when the MR minimap button is ready.
function MRBP:OnLoad()
	_log:info(string.format("Loading %s...", ns.AddonColor:WrapTextInColorCode(ns.AddonTitle)))

	-- Load settings and interface options
	-- MRBP_InterfaceOptionsPanel:Initialize()
	MRBP_Settings_Register();

	self:RegisterSlashCommands()
	self:SetButtonHooks()

	-- Create the dropdown menu
	self:LoadData()
	self:GarrisonLandingPageDropDown_OnLoad()

	_log:info("----- Addon is ready. -----")
end

-----[[ Data ]]-----------------------------------------------------------------

local MRBP_GARRISON_TYPE_INFOS_SORTORDER = {
	-- Enum.ExpansionLandingPageType.Dragonflight,
	Enum.GarrisonType.Type_9_0,
	Enum.GarrisonType.Type_8_0,
	Enum.GarrisonType.Type_7_0,
	Enum.GarrisonType.Type_6_0,
}

-- A collection of quest for (before) unlocking the command table.
--> <questID, questName_English (fallback)>
local MRBP_COMMAND_TABLE_UNLOCK_QUESTS = {
	[Enum.GarrisonType.Type_6_0] = {
		-- REF.: <https://www.wowhead.com/guides/garrisons/quests-to-unlock-a-level-1-and-level-2-garrison>
		["Horde"] = {34775, "Mission Probable"},  --> wowhead
		["Alliance"] = {34692, "Delegating on Draenor"},  --> Companion App
	},
	[Enum.GarrisonType.Type_7_0] = {
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
	[Enum.GarrisonType.Type_8_0] = {
		["Horde"] = {51771, "War of Shadows"},
		["Alliance"] = {51715, "War of Shadows"},
	},
	[Enum.GarrisonType.Type_9_0] = {
		[Enum.CovenantType.Kyrian] = {57878, "Choosing Your Purpose"},  	--> alt.: 62000 (when skipping story mode)
		[Enum.CovenantType.Venthyr] = {57878, "Choosing Your Purpose"}, 	--> optional: 59319, "Advancing Our Efforts"
		[Enum.CovenantType.NightFae] = {57878, "Choosing Your Purpose"},	--> optional: 61552, "The Hunt Watches"
		[Enum.CovenantType.Necrolord] = {57878, "Choosing Your Purpose"},
		["alt"] = {62000, "Choosing Your Purpose"},
		-- TEST - C_QuestLog.IsQuestFlaggedCompleted(57878)  --> story mode
		-- TEST - C_QuestLog.IsQuestFlaggedCompleted(62000)  --> skipping story mode
	},
	-- [Enum.ExpansionLandingPageType.Dragonflight] = {
	-- 	-- REF.: <FrameXML/Blizzard_ExpansionLandingPage/Blizzard_DragonflightLandingPage.lua>
	-- 	["Horde"] ={65444, "To the Dragon Isles!"},
	-- 	["Alliance"] = {67700, "To the Dragon Isles!"},
	-- 	["alt"] = {68798, "Dragon Glyphs and You"},
	-- },
}

-- Request data for the unlocking requirement quests; on initial log-in the
-- localized quest titles are not always available. This should help getting
-- the quest infos in the language the player has chosen.
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

-- Get quest infos of given garrison type for given tag.
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
--> Returns: boolean
local function MRBP_IsGarrisonTypeUnlocked(garrTypeID, tagName)
	local questData = MRBP_COMMAND_TABLE_UNLOCK_QUESTS[garrTypeID][tagName]
	local questID = questData[1]
	local IsCompleted = C_QuestLog.IsQuestFlaggedCompleted

	--> FIXME - Temp. work-around (better with achievement of same name ???)
	-- In Shadowlands if you skip the story mode you get a different quest (ID) with the same name, so
	-- we need to check both quests.
	if (garrTypeID == Enum.GarrisonType.Type_9_0) then
		local questID2 = MRBP_COMMAND_TABLE_UNLOCK_QUESTS[garrTypeID]["alt"][1]
		return IsCompleted(questID) or IsCompleted(questID2)
	end

	return IsCompleted(questID)
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

	-- Main data table with infos about each garrison type
	MRBP_GARRISON_TYPE_INFOS = {
		-----[[ Warlords of Draenor ]]-----
		[Enum.GarrisonType.Type_6_0] = {
			["tagName"] = playerInfo.factionGroup,
			["title"] = GARRISON_LANDING_PAGE_TITLE,
			["description"] = MINIMAP_GARRISON_LANDING_PAGE_TOOLTIP,
			["minimapIcon"] = string.format("GarrLanding-MinimapIcon-%s-Up", playerInfo.factionGroup),
			-- ["atlas"] = "accountupgradebanner-wod",  --> TODO
			["msg"] = {  --> menu entry tooltip messages
				["missionsTitle"] = GARRISON_MISSIONS_TITLE,
				["missionsReadyCount"] = GARRISON_LANDING_COMPLETED,  --> "%d/%d Ready for pickup"
				["missionsEmptyProgress"] = GARRISON_EMPTY_IN_PROGRESS_LIST,
				["missionsComplete"] = GarrisonFollowerOptions[Enum.GarrisonFollowerType.FollowerType_6_0].strings.LANDING_COMPLETE,
				["requirementText"] = MRBP_GetGarrisonTypeUnlockQuestInfo(Enum.GarrisonType.Type_6_0, playerInfo.factionGroup).requirementText,
			},
			["expansion"] = ns.ExpansionUtil.data.WarlordsOfDraenor,
			["continents"] = {572},  --> Draenor
			-- No bounties in Draenor; only available since Legion.
		},
		-----[[ Legion ]]-----
		[Enum.GarrisonType.Type_7_0] = {
			["tagName"] = playerInfo.className,
			["title"] = ORDER_HALL_LANDING_PAGE_TITLE,
			["description"] = MINIMAP_ORDER_HALL_LANDING_PAGE_TOOLTIP,
			["minimapIcon"] = string.format("legionmission-landingbutton-%s-up", playerInfo.className),
			-- ["atlas"] = "accountupgradebanner-legion",  --> TODO
			["msg"] = {
				["missionsTitle"] = GARRISON_MISSIONS,
				["missionsReadyCount"] = GARRISON_LANDING_COMPLETED,
				["missionsEmptyProgress"] = GARRISON_EMPTY_IN_PROGRESS_LIST,
				["missionsComplete"] = GarrisonFollowerOptions[Enum.GarrisonFollowerType.FollowerType_7_0].strings.LANDING_COMPLETE,
				["requirementText"] = MRBP_GetGarrisonTypeUnlockQuestInfo(Enum.GarrisonType.Type_7_0, playerInfo.className).requirementText,
			},
			["expansion"] = ns.ExpansionUtil.data.Legion,
			["continents"] = {619, 905},  --> Broken Isles + Argus
			["bountyBoard"] = {
				["title"] = BOUNTY_BOARD_LOCKED_TITLE,
				["noBountiesMessage"] = BOUNTY_BOARD_NO_BOUNTIES_DAYS_1,
				["bounties"] = C_QuestLog.GetBountiesForMapID(650),  --> any child zone from "continents" in Legion seems to work
				["areBountiesUnlocked"] = MapUtil.MapHasUnlockedBounties(650),
			},
		},
		-----[[ Battle for Azeroth ]]-----
		[Enum.GarrisonType.Type_8_0] = {
			["tagName"] = playerInfo.factionGroup,
			["title"] = GARRISON_TYPE_8_0_LANDING_PAGE_TITLE,
			["description"] = GARRISON_TYPE_8_0_LANDING_PAGE_TOOLTIP,
			["minimapIcon"] = string.format("bfa-landingbutton-%s-up", playerInfo.factionGroup),
			-- ["atlas"] = "accountupgradebanner-bfa",  --> TODO
			["msg"] = {
				["missionsTitle"] = GARRISON_MISSIONS,
				["missionsReadyCount"] = GARRISON_LANDING_COMPLETED,
				["missionsEmptyProgress"] = GARRISON_EMPTY_IN_PROGRESS_LIST,
				["missionsComplete"] = GarrisonFollowerOptions[Enum.GarrisonFollowerType.FollowerType_8_0].strings.LANDING_COMPLETE,
				["requirementText"] = MRBP_GetGarrisonTypeUnlockQuestInfo(Enum.GarrisonType.Type_8_0, playerInfo.factionGroup).requirementText,
			},
			["expansion"] = ns.ExpansionUtil.data.BattleForAzeroth,
			["continents"] = {876, 875, 1355},  --> Kul'Tiras + Zandalar (+ Nazjatar [Zone])
			["bountyBoard"] = {
				["title"] = BOUNTY_BOARD_LOCKED_TITLE,
				["noBountiesMessage"] = BOUNTY_BOARD_NO_BOUNTIES_DAYS_1,
				["bounties"] = C_QuestLog.GetBountiesForMapID(875),  --> or any child zone from "continents" seems to work as well.
				["areBountiesUnlocked"] = MapUtil.MapHasUnlockedBounties(875),  --> checking only Zandalar should be enough
			},
		},
		-----[[ Shadowlands ]]-----
		[Enum.GarrisonType.Type_9_0] = {
			["tagName"] = playerInfo.covenantID,
			["title"] = GARRISON_TYPE_9_0_LANDING_PAGE_TITLE,
			["description"] = GARRISON_TYPE_9_0_LANDING_PAGE_TOOLTIP,
			["minimapIcon"] = string.format("shadowlands-landingbutton-%s-up", playerInfo.covenantTex),
			-- ["atlas"] = "accountupgradebanner-shadowlands",  --> TODO
			["msg"] = {
				["missionsTitle"] = COVENANT_MISSIONS_TITLE,
				["missionsReadyCount"] = GARRISON_LANDING_COMPLETED,
				["missionsEmptyProgress"] = COVENANT_MISSIONS_EMPTY_IN_PROGRESS,
				["missionsComplete"] = GarrisonFollowerOptions[Enum.GarrisonFollowerType.FollowerType_9_0].strings.LANDING_COMPLETE,
				["requirementText"] = MRBP_GetGarrisonTypeUnlockQuestInfo(Enum.GarrisonType.Type_9_0, playerInfo.covenantID).requirementText,
			},
			["expansion"] = ns.ExpansionUtil.data.Shadowlands,
			["continents"] = {1550},  --> Shadowlands
			["bountyBoard"] = {
				["title"] = CALLINGS_QUESTS,
				["noBountiesMessage"] = BOUNTY_BOARD_NO_CALLINGS_DAYS_1,
				["bounties"] = {},  --> Shadowlands callings will be later added via the event handler.
				["areBountiesUnlocked"] = C_CovenantCallings.AreCallingsUnlocked(),
			},
		},
		-----[[ Dragonflight ]]-----
		-- [Enum.ExpansionLandingPageType.Dragonflight] = {
		-- -- 	["tagName"] = Enum.MajorFactionType.None,  -- playerInfo.majorFactionID,
		-- 	["tagName"] = playerInfo.factionGroup,
		-- 	["title"] = DRAGONFLIGHT_LANDING_PAGE_TITLE,
		-- 	["description"] = DRAGONFLIGHT_LANDING_PAGE_TOOLTIP,
		-- 	["minimapIcon"] = "dragonflight-landingbutton-up",
		-- 	-- ["atlas"] = "accountupgradebanner-dragonflight",  -- 199x133  --> TODO 
		-- 	["msg"] = {
		-- 		["missionsTitle"] = COVENANT_MISSIONS_TITLE,
		-- 		["missionsReadyCount"] = GARRISON_LANDING_COMPLETED,
		-- 		["missionsEmptyProgress"] = GARRISON_EMPTY_IN_PROGRESS_LIST,
		-- 		["missionsComplete"] = GarrisonFollowerOptions[Enum.GarrisonFollowerType.FollowerType_9_0].strings.LANDING_COMPLETE,
		-- 		["requirementText"] = MRBP_GetGarrisonTypeUnlockQuestInfo(Enum.GarrisonType.Type_9_0, playerInfo.covenantID).requirementText,
		-- 	},
		--  ["expansion"] = ns.ExpansionUtil.data.Dragonflight,
		-- -- 	["continents"] = {1550},  --> Shadowlands 
		-- -- 	["bountyBoard"] = {
		-- -- 		["title"] = CALLINGS_QUESTS,
		-- -- 		["noBountiesMessage"] = BOUNTY_BOARD_NO_CALLINGS_DAYS_1,
		-- -- 		["bounties"] = {},  --> Shadowlands callings will be later added via the event handler. 
		-- -- 		["areBountiesUnlocked"] = C_CovenantCallings.AreCallingsUnlocked(),
		-- -- 	},
		-- 	-- DRAGONFLIGHT_LANDING_PAGE_ALERT_DRAGONRIDING_UNLOCKED = "Fertigkeitenpfad für Drachenreiten freigeschaltet";
		-- 	-- DRAGONFLIGHT_LANDING_PAGE_ALERT_MAJOR_FACTION_UNLOCKED = "Hauptfraktion freigeschaltet";
		-- 	-- DRAGONFLIGHT_LANDING_PAGE_ALERT_SUMMARY_UNLOCKED = "Zusammenfassung der Dracheninseln freigeschaltet";
		-- },
	}
end

-- -- Check if given questID is part of the given garrison type
-- -- requirements to unlock the command table.
-- function MRBP_IsQuestGarrisonRequirement(questID)
-- 	--> Returns: boolean
-- 	_log:debug("IsQuestGarrisonRequirement?", questID)
-- 	local garrInfo, unlockQuestID

-- 	for _, garrTypeID in ipairs(MRBP_GARRISON_TYPE_INFOS_SORTORDER) do
-- 		garrInfo = MRBP_GARRISON_TYPE_INFOS[garrTypeID]
-- 		unlockQuestID = garrInfo.unlockQuest[1]
-- 		if (questID == unlockQuestID) then
-- 			_log:debug("... yes!")
-- 			return true
-- 		end
-- 	end

-- 	_log:debug("... no.")
-- 	return false
-- end

-- Check if the requirement for the given garrison type is met in order to
-- unlock the command table.
-- Note: Currently only the required quest is checked for completion and
--       nothing more. In Shadowlands there would be one more step needed, since
--       2 quest are available for this (see MRBP_IsGarrisonTypeUnlocked).
--> Returns: boolean
function MRBP_IsGarrisonRequirementMet(garrTypeID)
	local garrInfo = MRBP_GARRISON_TYPE_INFOS[garrTypeID]
	_log:info("Checking Garrison Requirement for", garrInfo.expansion.name, "...")

	local hasGarrison = C_Garrison.HasGarrison(garrTypeID)
	local isQuestCompleted = MRBP_IsGarrisonTypeUnlocked(garrTypeID, garrInfo.tagName)

	_log:debug("Garrison type:", YELLOW_FONT_COLOR:WrapTextInColorCode(tostring(garrTypeID).." "..garrInfo.expansion.name))
	_log:debug("hasGarrison:", hasGarrison)
	_log:debug("isQuestCompleted:", isQuestCompleted)

	return hasGarrison and isQuestCompleted
end

-- Check if at least one garrison is unlocked.
--> Returns: boolean
function MRBP_IsAnyGarrisonRequirementMet()
	for _, garrTypeID in ipairs(MRBP_GARRISON_TYPE_INFOS_SORTORDER) do
		local result = MRBP_IsGarrisonRequirementMet(garrTypeID)
		if result then
			return true
		end
	end

	_log:debug(RED_FONT_COLOR:WrapTextInColorCode("No unlocked garrison available."))
	return false
end
ns.MRBP_IsAnyGarrisonRequirementMet = MRBP_IsAnyGarrisonRequirementMet;

-----[[ Dropdown Menu ]]--------------------------------------------------------

-- Combine the menu entry text with an icon hint about completed missions
-- with the user preferences and add to the menu entry's description tooltip
-- informations about completed missions according to user preferences.
--> Returns: table  {string, string}
local function BuildMenuEntryLabelDesc(garrTypeID, isDisabled, activeThreats)
	local garrInfo = MRBP_GARRISON_TYPE_INFOS[garrTypeID]
	local numInProgress, numCompleted = util:GetInProgressMissionCount(garrTypeID)

	--[[ Set menu entry text (label) ]]--
	local labelText = ns.settings.preferExpansionName and garrInfo.expansion.name or garrInfo.title
	if (ns.settings.showMissionCompletedHint and numCompleted > 0) then
		if (not ns.settings.showMissionCompletedHintOnlyForAll) then
			labelText = labelText.." |TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0:0:0:0|t"
		end
		if (ns.settings.showMissionCompletedHintOnlyForAll and numCompleted == numInProgress) then
			labelText = labelText.." |TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0:0:0:0|t"
		end
	end

	--[[ In-progress mission infos ]]--
	local tooltipText = isDisabled and DISABLED_FONT_COLOR:WrapTextInColorCode(garrInfo.description) or garrInfo.description
	if (ns.settings.showMissionCountInTooltip and not isDisabled) then
		-- Add category title for missions
		tooltipText = tooltipText.."|n|n"..garrInfo.msg.missionsTitle

		-- Add mission count info
		tooltipText = tooltipText..HIGHLIGHT_FONT_COLOR_CODE
		if (numInProgress > 0) then
			tooltipText = tooltipText.."|n"..string.format(garrInfo.msg.missionsReadyCount, numCompleted, numInProgress)
		else
			tooltipText = tooltipText.."|n"..garrInfo.msg.missionsEmptyProgress
		end
		tooltipText = tooltipText..FONT_COLOR_CODE_CLOSE
		if ns.settings.showMissionCompletedHintOnlyForAll then
			if (numCompleted > 0 and numCompleted == numInProgress) then
				tooltipText = tooltipText.."|n|n"..garrInfo.msg.missionsComplete
			end
		else
			if (numCompleted > 0) then
				tooltipText = tooltipText.."|n|n"..garrInfo.msg.missionsComplete
			end
		end
	end
	-- Show requirement for unlocking the given garrison type
	if (isDisabled and ns.settings.showEntryRequirements) then
		-- CAMPAIGN_AVAILABLE_QUESTLINE = "Setzt die Kampagne fort, indem Ihr die Quest \"%s\" in %s annehmt.";
		tooltipText = tooltipText.."|n|n"..DIM_RED_FONT_COLOR:WrapTextInColorCode(garrInfo.msg.requirementText)

		return labelText, tooltipText  --> Stop here, don't process the rest below.
	end

	--[[ Bounty board infos ]]--
	if (garrTypeID ~= Enum.GarrisonType.Type_6_0) then
		-- Only available since Legion (WoW 7.x)
		local bountyBoard = garrInfo.bountyBoard

		if (bountyBoard.areBountiesUnlocked and ns.settings.showWorldmapBounties and #bountyBoard.bounties > 0) then
			tooltipText = tooltipText.."|n|n"..bountyBoard.title
			_log:debug(garrInfo.title, "- bounties:", #bountyBoard.bounties)
			if (garrTypeID == Enum.GarrisonType.Type_9_0) then
				-- Retrieves callings through event listening; try to update.
				CovenantCalling_CheckCallings()
				--> REF.: <FrameXML/ObjectAPI/CovenantCalling.lua>
			end
			for _, bountyData in ipairs(bountyBoard.bounties) do
				if bountyData then
					local questName = QuestUtils_GetQuestName(bountyData.questID)
					local icon = util:CreateInlineIcon(bountyData.icon)
					if (garrTypeID == Enum.GarrisonType.Type_9_0) then
						icon = util:CreateInlineIcon(bountyData.icon, 16)  --, nil, nil)
						-- C_QuestLog.GetBountiesForMapID(875)
					end
					if bountyData.turninRequirementText then
						--> REF.: <FrameXML//WorldMapBountyBoard.lua>
						local bountyString = GRAY_FONT_COLOR:WrapTextInColorCode("%s %s"):format(icon, questName)
						tooltipText = tooltipText.."|n"..bountyString
						if ns.settings.showBountyRequirements then
							tooltipText = tooltipText.."|n"..util:CreateInlineIcon(3083385)  --> dash icon texture
							tooltipText = tooltipText.." "..RED_FONT_COLOR:WrapTextInColorCode(bountyData.turninRequirementText)
						end
					else
						local bountyString = HIGHLIGHT_FONT_COLOR:WrapTextInColorCode("%s %s"):format(icon, questName)
						tooltipText = tooltipText.."|n"..bountyString
					end
				else
					tooltipText = tooltipText.."|n"..bountyBoard.noBountiesMessage
				end
			end
		end
		-- local color = finished and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR -- NORMAL_FONT_COLOR
 		-- local formattedTime, color, secondsRemaining = WorldMap_GetQuestTimeForTooltip(questID)

		--[[ World map threat infos ]]--
		if (activeThreats and ns.settings.showWorldmapThreats) then
			for threatExpansionLevel, threatData in pairs(activeThreats) do
				-- Add the infos to the corresponding expansions only
				if (threatExpansionLevel == garrInfo.expansion.ID) then
					-- Show the header *only once* per expansion
					local EXPANSION_LEVEL_BFA = 7
					if (threatExpansionLevel == EXPANSION_LEVEL_BFA) then
						tooltipText = tooltipText.."|n|n"..WORLD_MAP_THREATS
					else
						local zoneName = select(3, SafeUnpack(threatData[1]))
						tooltipText = tooltipText.."|n|n"..zoneName
					end
					for i, threatInfo in ipairs(threatData) do
						local questID, questName, zoneName = SafeUnpack(threatInfo)
						tooltipText = tooltipText.."|n"..HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(questName)
					end
				end
			end
		end
	end

	return labelText, tooltipText
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
-- Note: 'self' refers in this case to the dropdown menu frame.
function MRBP:GarrisonLandingPageDropDown_Initialize(level)
	_log:info("Initializing drop-down menu...")
	-- Sort display order *only once* per changed setting
	local isInitialSortOrder = max(SafeUnpack(MRBP_GARRISON_TYPE_INFOS_SORTORDER)) == MRBP_GARRISON_TYPE_INFOS_SORTORDER[1]

	if (ns.settings.reverseSortorder and isInitialSortOrder) then
		local sortFunc = function(a,b) return a<b end  --> 0-9
		table.sort(MRBP_GARRISON_TYPE_INFOS_SORTORDER, sortFunc)
		_log:debug("Showing reversed display order.")
	end
	if (not ns.settings.reverseSortorder and not isInitialSortOrder) then
		local sortFunc = function(a,b) return a>b end  --> 9-0 (default)
		table.sort(MRBP_GARRISON_TYPE_INFOS_SORTORDER, sortFunc)
		_log:debug("Showing initial display order.")
	end

	local filename, width, height, txLeft, txRight, txTop, txBottom  --> needed for not showing mission type icons
	local activeThreats = util:GetActiveWorldMapThreats()

	for i, garrTypeID in ipairs(MRBP_GARRISON_TYPE_INFOS_SORTORDER) do
		local garrInfo = MRBP_GARRISON_TYPE_INFOS[garrTypeID]
		if ns.settings.showMissionTypeIcons then
			filename, width, height, txLeft, txRight, txTop, txBottom = util:GetAtlasInfo(garrInfo.minimapIcon)
		end
		local shouldShowDisabled = not MRBP_IsGarrisonRequirementMet(garrTypeID)
		local playerOwnsExpansion = ns.ExpansionUtil:DoesPlayerOwnExpansion(garrInfo.expansion.ID)
		local isActiveEntry = tContains(ns.settings.activeMenuEntries, tostring(garrInfo.expansion.ID))  --> user option

		_log:debug(string.format("Got %s - owned: %s, disabled: %s",
		   NORMAL_FONT_COLOR:WrapTextInColorCode(garrInfo.expansion.name),
		   NORMAL_FONT_COLOR:WrapTextInColorCode(tostring(playerOwnsExpansion)),
		   NORMAL_FONT_COLOR:WrapTextInColorCode(tostring(shouldShowDisabled)))
		)

		if (playerOwnsExpansion and isActiveEntry) then
			local labelText, tooltipText = BuildMenuEntryLabelDesc(garrTypeID, shouldShowDisabled, activeThreats)

			local info = UIDropDownMenu_CreateInfo()
			info.owner = ExpansionLandingPageMinimapButton
			info.text = labelText
			info.notCheckable = 1
			info.tooltipOnButton = ns.settings.showEntryTooltip and 1 or nil
			info.tooltipTitle = ns.settings.preferExpansionName and garrInfo.title or garrInfo.expansion.name
			info.tooltipText = tooltipText
			if ns.settings.showMissionTypeIcons then
				info.icon = filename
				info.tCoordLeft = txLeft
				info.tCoordRight = txRight
				info.tCoordTop = txTop
				info.tCoordBottom = txBottom
				info.tSizeX = width
				info.tSizeY = height
				-- info.tFitDropDownSizeX = 1
				-- info.iconOnly = 1
				-- info.iconInfo = {
					-- tCoordLeft = txLeft,
					-- tCoordRight = txRight,
					-- tCoordTop = txTop,
					-- tCoordBottom = txBottom,
					-- tSizeX = width,
					-- tSizeY = height,
					-- tFitDropDownSizeX = 1,
				-- }
			end
			info.func = function(self)
				if (GarrisonLandingPage and GarrisonLandingPage:IsShown()) then
					HideUIPanel(GarrisonLandingPage)
				end
				ShowGarrisonLandingPage(garrTypeID)
			end
			info.disabled = shouldShowDisabled
			info.tooltipWhileDisabled = 1

			UIDropDownMenu_AddButton(info, level)
		end
	end
	if tContains(ns.settings.activeMenuEntries, ns.settingsMenuEntry) then
		-- Add settings button
		if ns.settings.showMissionTypeIcons then
			filename, width, height, txLeft, txRight, txTop, txBottom = util:GetAtlasInfo("Warfronts-BaseMapIcons-Empty-Workshop-Minimap")
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

		UIDropDownMenu_AddButton(info)
	end
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
					ns.settings.disableShowMinimapButtonSetting = false
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
					ns.settings.disableShowMinimapButtonSetting = false
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
		ns.settings.disableShowMinimapButtonSetting = true
	else
		local isCalledByUser = not isCalledByCancelFunc
		MRBP:ShowMinimapButton(isCalledByUser)
	end
end
ns.ShowMinimapButton_User = MRBP.ShowMinimapButton_User

-----[[ Hooks ]]----------------------------------------------------------------

-- Hook the functions related to the GarrisonLandingPage's minimap button
-- and frame (mission report frame).
function MRBP:SetButtonHooks()
	if ExpansionLandingPageMinimapButton then
		_log:info("Hooking into minimap button's tooltip + clicking behavior...")

		-- Minimap button tooltip hook
		ExpansionLandingPageMinimapButton:HookScript("OnEnter", MRBP_OnEnter)

		-- Mouse button hooks; by default only the left button is registered.
		ExpansionLandingPageMinimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		ExpansionLandingPageMinimapButton:SetScript("OnClick", MRBP_OnClick)
		-- ExpansionLandingPageMinimapButton:HookScript("OnClick", MRBP_OnClick)  --> safer, but doesn't work!
	end

	-- GarrisonLandingPage (mission report frame) hook
	hooksecurefunc("ShowGarrisonLandingPage", MRBP_ShowGarrisonLandingPage)
end

-- Handle mouse-over behavior of the minimap button.
-- Note: 'self' refers to the ExpansionLandingPageMinimapButton, the parent frame.
--
-- REF.: <FrameXML/Minimap.xml>
-- REF.: <FrameXML/SharedTooltipTemplates.lua>
function MRBP_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText(self.title, 1, 1, 1)
	GameTooltip:AddLine(self.description, nil, nil, nil, true)

	local tooltipAddonText = L.TOOLTIP_CLICKTEXT_MINIMAPBUTTON
	if ns.settings.showAddonNameInTooltip then
		tooltipAddonText = GRAY_FONT_COLOR:WrapTextInColorCode(ns.AddonTitleShort..ns.AddonTitleSeparator).." "..tooltipAddonText
	end
	local currentDateTime = C_DateAndTime.GetCurrentCalendarTime()
	if (currentDateTime.month == 12) then
		-- Show a Xmas Easter egg on December after the minimap tooltip text
		tooltipAddonText = tooltipAddonText.." "..util:CreateInlineIcon("Front-Tree-Icon")
	end
	GameTooltip_AddNormalLine(GameTooltip, tooltipAddonText)

	GameTooltip:Show()
end

-- Handle click behavior of the minimap button.
-- Note: 'self' refers to the parent frame 'ExpansionLandingPageMinimapButton'.
function MRBP_OnClick(self, button, isDown)
	_log:debug(string.format("Got mouse click: %s, isDown: %s", button, tostring(isDown)))

	if (button == "RightButton") then
		UIDropDownMenu_Refresh(MRBP.dropdown)
		ToggleDropDownMenu(1, nil, MRBP.dropdown, self, -14, 5)
	else
		-- Pass-through to original function on LeftButton click.
		ExpansionLandingPageMinimapButton:OnClick(button)
	end
end

-- Fix display errors caused by the Covenant Landing Page Mixin.
--
-- REF. <FrameXML/Blizzard_GarrisonUI/Blizzard_GarrisonLandingPage.lua>
function MRBP_ShowGarrisonLandingPage(garrTypeID)
	_log:debug("Opening report for garrTypeID:", garrTypeID, MRBP_GARRISON_TYPE_INFOS[garrTypeID].title)

	if (GarrisonLandingPageReport ~= nil) then
		if (garrTypeID ~= Enum.GarrisonType.Type_9_0) then
			-- Quick fix: the covenant missions don't hide some frame parts properly
			GarrisonLandingPageReport.Sections:Hide()
			GarrisonLandingPage.FollowerTab.CovenantFollowerPortraitFrame:Hide()
		else
			GarrisonLandingPageReport.Sections:Show()
		end
	end
	-- Quick fix for the invasion alert badge from WoD garrison on the upper
	-- side of the mission report frame only shows it for garrison missions.
	if ( garrTypeID ~= Enum.GarrisonType.Type_6_0 and GarrisonLandingPage.InvasionBadge:IsShown() ) then
		GarrisonLandingPage.InvasionBadge:Hide()
	end
end

local function MRBP_ReloadDropdown()
	MRBP.dropdown = nil
	MRBP:GarrisonLandingPageDropDown_OnLoad()
end
ns.MRBP_ReloadDropdown = MRBP_ReloadDropdown

-- Return the garrison type of the previous expansion, as long as the
-- player level hasn't reached the maximum level.
--> Returns: number
-- 
-- Note: At first log-in this always returns 0 (== no garrison at all).			--> FIXME - Find a solution for this
--
-- REF.: <FrameXML/Blizzard_APIDocumentation/ExpansionDocumentation.lua>
function MRBP_GetLandingPageGarrisonType()
	_log:info("Starting garrison type adjustment...")

	local garrTypeID = MRBP_GetLandingPageGarrisonType_orig()
	_log:debug("Got original garrison type:", garrTypeID)

	if ( garrTypeID > 0 and not MRBP_IsGarrisonRequirementMet(garrTypeID) ) then
		-- Build and return garrison type ID of previous expansion.
		local minExpansionID = ns.ExpansionUtil:GetMinimumExpansionLevel()  --> min. available, eg. 8 (Shadowlands)
		-- Need last attribute of 'Enum.GarrisonType.Type_8_0'
		local garrTypeID_Minimum = Enum.GarrisonType["Type_"..tostring(minExpansionID).."_0"]

		if (_log.level == _log.DEBUG) then
			-- Tests
			local playerExpansionID = ns.ExpansionUtil:GetExpansionForPlayerLevel()
			local maxExpansionID = ns.ExpansionUtil:GetMaximumExpansionLevel()  --> max. available, eg. 9 (Dragonflight)
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

-- --> TODO - Find a more secure way to pre-hook this.
MRBP_GetLandingPageGarrisonType_orig = C_Garrison.GetLandingPageGarrisonType
C_Garrison.GetLandingPageGarrisonType = MRBP_GetLandingPageGarrisonType

-----[[ Slash commands ]]-------------------------------------------------------

local SLASH_CMD_ARGLIST = {
	-- arg, description
	{"version", L.SLASHCMD_DESC_VERSION},
	{"chatmsg", L.SLASHCMD_DESC_CHATMSG},
	{"show", L.SLASHCMD_DESC_SHOW},
	{"hide", L.SLASHCMD_DESC_HIDE},
	{"config", BASIC_OPTIONS_TOOLTIP},  --> WoW global string
	--> TODO - "about"
}
ns.SLASH_CMD_ARGLIST = SLASH_CMD_ARGLIST;

function MRBP:RegisterSlashCommands()
	_log:info("Registering slash commands...")

	SLASH_MRBP1 = '/mrbp'
	SLASH_MRBP2 = '/missionreportbuttonplus'
	SlashCmdList["MRBP"] = function(msg, editbox)
		if (msg ~= '') then
			_log:debug(string.format("Got slash cmd: '%s'", msg))

			if (msg == 'version') then
				local shortVersionOnly = true
				util:printVersion(shortVersionOnly)

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

			-----[[ Tests ]]-----
			elseif (msg == 'garrtest') then
				local prev_loglvl = _log.level
				_log:info("Current GarrisonType:", MRBP_GetLandingPageGarrisonType())
				_log.level = _log.DEBUG

				for i, garrTypeID in ipairs(MRBP_GARRISON_TYPE_INFOS_SORTORDER) do
					local garrInfo = MRBP_GARRISON_TYPE_INFOS[garrTypeID]
				   _log:debug("HasGarrison:", C_Garrison.HasGarrison(garrTypeID),
							--   "-", string.format("%-3d", garrTypeID), garrInfo.expansion.name,
							  "- req:", MRBP_IsGarrisonRequirementMet(garrTypeID),
							--   "- unlocked:", garrInfo:IsUnlocked())
							  "- unlocked:", MRBP_IsGarrisonTypeUnlocked(garrTypeID, garrInfo.tagName))
				end

				local playerLevel = UnitLevel("player")
				local expansionLevelForPlayer = ns.ExpansionUtil:GetExpansionForPlayerLevel(playerLevel)
				local playerMaxLevelForExpansion = ns.ExpansionUtil:GetMaxPlayerLevel()
				local expansion = ns.ExpansionUtil:GetExpansionData(expansionLevelForPlayer)

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

			util:printVersion()
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
