--------------------------------------------------------------------------------
--[[ Mission Report Button Plus ]]--
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

local AddonID, ns = ...;
local ShortAddonID = "MRBP";
local L = ns.L;
local _log = ns.dbg_logger;
local util = ns.utilities;

local LibQTip = LibStub('LibQTip-1.0');
local MenuTooltip, ExpansionTooltip, ReputationTooltip;
local LocalLibQTipUtil = ns.utils.libqtip;
local LocalTooltipUtil = ns.utilities.tooltip;

local LocalL10nUtil = ns.L10nUtil;  --> <data\L10nUtils.lua>
local PlayerInfo = ns.PlayerInfo;  --> <data\player.lua>
local ExpansionInfo = ns.ExpansionInfo;  --> <data\expansion.lua>
local LandingPageInfo = ns.LandingPageInfo;  --> <data\landingpage.lua>
local LocalFactionInfo = ns.FactionInfo;  --> <data\factions.lua>
local LocalMajorFactionInfo = ns.MajorFactionInfo;  --> <data\majorfactions.lua>
local LocalRequirementInfo = ns.RequirementInfo;  --> <data\requirements.lua>
local LocalLandingPageTypeUtil = ns.LandingPageTypeUtil;  --> <utils\landingpagetype.lua>
local LocalDragonridingUtil = ns.DragonridingUtil;  --> <utils\dragonriding.lua> --> TODO - Rename to Skyriding

-- ns.poi9;  --> <utils\poi-9-dragonflight.lua>

local MRBP_EventMessagesCounter = {};

-- Backwards compatibility 
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded;
local LoadAddOn = C_AddOns.LoadAddOn;
local GarrisonFollowerOptions = GarrisonFollowerOptions;
local ExpansionLandingPageMinimapButton = ExpansionLandingPageMinimapButton;

local DIM_RED_FONT_COLOR = DIM_RED_FONT_COLOR;
local DISABLED_FONT_COLOR = DISABLED_FONT_COLOR;
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR;
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR;
local WARNING_FONT_COLOR = WARNING_FONT_COLOR;
local DARKGRAY_COLOR = DARKGRAY_COLOR;
local LIGHTERBLUE_FONT_COLOR = LIGHTERBLUE_FONT_COLOR;

local TEXT_DASH_SEPARATOR = L.TEXT_DELIMITER..QUEST_DASH..L.TEXT_DELIMITER;
local GENERIC_FRACTION_STRING = GENERIC_FRACTION_STRING;

----- Main ---------------------------------------------------------------------

-- Core functions + event listener frame
local MRBP = CreateFrame("Frame", AddonID.."EventListenerFrame")

FrameUtil.RegisterFrameForEvents(MRBP, {
	"ADDON_LOADED",
	"PLAYER_ENTERING_WORLD",
	"PLAYER_CAMPING",  --> when the player is camping (logging out)
	"PLAYER_QUITING",  --> when the player tries to quit, as opposed to logout, while outside an inn
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

		elseif (event == "PLAYER_QUITING" or event == "PLAYER_CAMPING") then
			-- Do some variables clean-up
			LocalL10nUtil:CleanUpLabels()

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
			local talentTreeIDs = C_Garrison.GetTalentTreeIDsByClassID(garrisonTypeID, PlayerInfo:GetClassData("ID"));
			local completeTalentID = C_Garrison.GetCompleteTalent(garrisonTypeID);
			if (talentTreeIDs) then
				for treeIndex, treeID in ipairs(talentTreeIDs) do
					local treeInfo = C_Garrison.GetTalentTreeInfo(treeID);
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
			local skyridingQuests = {
				LocalDragonridingUtil.DRAGONFLIGHT_DRAGONRIDING_QUEST_ID,
				LocalDragonridingUtil.WAR_WITHIN_SKYRIDING_QUEST_ID,
			};
			if tContains(skyridingQuests, questID) then
				local landingPageInfo = LandingPageInfo:GetLandingPageInfo(ExpansionInfo.data.DRAGONFLIGHT.ID);
				ns.cprint(landingPageInfo.msg.dragonridingUnlocked);
			end

		elseif (event == "GARRISON_HIDE_LANDING_PAGE") then
			self:ShowMinimapButton()

		elseif (event == "GARRISON_SHOW_LANDING_PAGE") then
			-- Minimap button already visible through WoW default process
			if (not ns.settings.showMinimapButton or ns.settings.useMouseOverMinimapMode) then
				self:HideMinimapButton()
			end

		elseif (event == "COVENANT_CHOSEN") then
			local covenantID = ...;
			util.covenant.UpdateData(covenantID);

		elseif (event == "COVENANT_SANCTUM_RENOWN_LEVEL_CHANGED") then
			local newRenownLevel, oldRenownLevel = ...;
			local covenantInfo = util.covenant.GetCovenantInfo();
			if covenantInfo then
				local covenantName = covenantInfo.color:WrapTextInColorCode(covenantInfo.name);
				ns.cprint(covenantName..L.TEXT_DASH_DELIMITER..COVENANT_SANCTUM_RENOWN_LEVEL_UNLOCKED:format(newRenownLevel));
				local renownInfo = util.covenant.GetRenownData(covenantInfo.ID);
				if renownInfo.hasMaximumRenown then
					ns.cprint(COVENANT_SANCTUM_RENOWN_REWARD_DESC_COMPLETE:format(covenantName));
				end
			end

		elseif (event == "COVENANT_CALLINGS_UPDATED") then
			-- Updates the Shadowlands "bounty board" infos.
			-- REF.: <FrameXML/ObjectAPI/CovenantCalling.lua>
			-- REF.: <FrameXML/Blizzard_APIDocumentation/CovenantCallingsConstantsDocumentation.lua>
			-- REF.: <FrameXML/Blizzard_APIDocumentation/CovenantCallingsDocumentation.lua>
			--> updates on opening the world map in Shadowlands.
			local callings = ...;
			-- _log:debug("Covenant callings received:", #callings);
			LandingPageInfo:CheckInitialize();
			LandingPageInfo[ExpansionInfo.data.SHADOWLANDS.ID].bountyBoard["GetBounties"] = function() return callings end;

		elseif (event == "MAJOR_FACTION_UNLOCKED") then
			-- REF.: <FrameXML/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua>
			local majorFactionID = ...;
			local majorFactionData = LocalMajorFactionInfo:GetMajorFactionData(majorFactionID);
			if majorFactionData then
				local landingPageInfo = LandingPageInfo:GetLandingPageInfo(majorFactionData.expansionID);
				local unlockedMessage = landingPageInfo.msg.majorFactionUnlocked;
				local majorFactionColor = _G[strupper(majorFactionData.textureKit).."_MAJOR_FACTION_COLOR"];
				unlockedMessage = unlockedMessage..TEXT_DASH_SEPARATOR..majorFactionColor:WrapTextInColorCode(majorFactionData.name);
				ns.cprint(unlockedMessage);
			end
		end
	end
);

-- Load this add-on's functions when the MR minimap button is ready.
function MRBP:OnLoad()
	-- Load data and their handler
	LocalL10nUtil:LoadInGameLabels();
	LandingPageInfo:CheckInitialize();
	-- Prepare quest data for the unlocking requirements
	LocalRequirementInfo:Initialize();

	-- Load settings and interface options
	MRBP_Settings_Register();

	self:RegisterSlashCommands();
	self:SetButtonHooks();

	-- _log:info("----- Addon is ready. -----")
end

----- Dropdown Menu ------------------------------------------------------------

-- Handle opening and closing of Garrison-/ExpansionLandingPage frames.
---@param garrisonTypeID number
--
local function MRBP_ToggleLandingPageFrames(garrisonTypeID, landingPageTypeID)
	-- Always (!) hide the GarrisonLandingPage; all visible UI widgets can only
	-- be loaded properly on opening.
	if not landingPageTypeID and LocalLandingPageTypeUtil:IsValidGarrisonType(garrisonTypeID) then
		if (ExpansionLandingPage and ExpansionLandingPage:IsShown()) then
			_log:debug("Hiding ExpansionLandingPage");
			HideUIPanel(ExpansionLandingPage);
		end
		if (GarrisonLandingPage == nil) then
			-- Hasn't been opened in this session, yet
			_log:debug("Showing GarrisonLandingPage1 type", garrisonTypeID);
			ShowGarrisonLandingPage(garrisonTypeID);
		else
			-- Toggle the GarrisonLandingPage frame; only re-open it
			-- if the garrison type is not the same.
			if (GarrisonLandingPage:IsShown()) then
				_log:debug("Hiding GarrisonLandingPage type", GarrisonLandingPage.garrTypeID);
				HideUIPanel(GarrisonLandingPage);
				if (garrisonTypeID ~= GarrisonLandingPage.garrTypeID) then
					_log:debug("Showing GarrisonLandingPage2 type", garrisonTypeID);
					ShowGarrisonLandingPage(garrisonTypeID);
				end
			else
				_log:debug("Showing GarrisonLandingPage3 type", garrisonTypeID);
				ShowGarrisonLandingPage(garrisonTypeID);
			end
		end
	end

	-- Note: works currently only in Dragonflight and newer expansions
	if LocalLandingPageTypeUtil:IsValidExpansionLandingPageType(landingPageTypeID) then
		if (GarrisonLandingPage and GarrisonLandingPage:IsShown()) then
			_log:debug("Hiding GarrisonLandingPage1 type", GarrisonLandingPage.garrTypeID);
			HideUIPanel(GarrisonLandingPage);
		end
		if (ExpansionLandingPage and ExpansionLandingPage:IsShown() and ExpansionLandingPage.expansionLandingPageType ~= landingPageTypeID) then
			HideUIPanel(ExpansionLandingPage);
		end

		ExpansionLandingPage.expansionLandingPageType = landingPageTypeID;
		MRBP_ApplyExpansionLandingPageOverlay(landingPageTypeID);
		ToggleExpansionLandingPage();
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
	return (
		(garrisonTypeID == ExpansionInfo.data.SHADOWLANDS.garrisonTypeID and ns.settings.showCovenantMissionInfo) or
		(garrisonTypeID == ExpansionInfo.data.BATTLE_FOR_AZEROTH.garrisonTypeID and ns.settings.showBfAMissionInfo) or
		(garrisonTypeID == ExpansionInfo.data.LEGION.garrisonTypeID and ns.settings.showLegionMissionInfo and not PlayerInfo:IsPlayerEvokerClass()) or
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
	if (expansionInfo.ID > ExpansionInfo.data.LEGION.ID) then return end

	if (expansionInfo.ID == ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID) then
		return ns.IsExpansionOptionSet("showWorldMapEvents", expansionInfo.ID) and ns.settings.showWoDTimewalkingVendor
	end
	if (expansionInfo.ID == ExpansionInfo.data.LEGION.ID) then
		return ns.IsExpansionOptionSet("showWorldMapEvents", expansionInfo.ID) and ns.settings.showLegionTimewalkingVendor
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
	if not LocalRequirementInfo:IsAnyLandingPageAvailable() then return; end

	local garrisonTypeID = MRBP_GetLandingPageGarrisonType()
	if LocalLandingPageTypeUtil:IsValidGarrisonType(garrisonTypeID) then
		if isCalledByUser then
			if ( not ExpansionLandingPageMinimapButton:IsShown() ) then
				ExpansionLandingPageMinimapButton:Show()
				ExpansionLandingPageMinimapButton:UpdateIcon()
				-- Manually set by user
				ns.settings.showMinimapButton = true
				_log:debug("--> Minimap button should stay visible. (user)")
			else
				-- Give user feedback, if button is already visible
				ns.cprint(L.CHATMSG_MINIMAPBUTTON_ALREADY_SHOWN)
			end
		else
			-- Fired by GARRISON_HIDE_LANDING_PAGE event
			if ( ns.settings.showMinimapButton and (not ExpansionLandingPageMinimapButton:IsShown()) )then
				ExpansionLandingPageMinimapButton:UpdateIcon()
				ExpansionLandingPageMinimapButton:Show()
				_log:debug("--> Minimap button should be visible. (event)")
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
	local isAnyUnlocked = LocalRequirementInfo:IsAnyLandingPageAvailable()
	if (not isAnyUnlocked) then
		-- Do nothing, as long as user hasn't unlocked any of the command tables available
		-- Inform user about this, and disable checkbutton in config.
		ns.cprint(L.CHATMSG_UNLOCKED_COMMANDTABLES_REQUIRED)
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
		-- ExpansionLandingPageMinimapButton:HookScript("SetTooltip", MRBP_OnEnter)

		-- Mouse button hooks; by default only the left button is registered.
		ExpansionLandingPageMinimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
		ExpansionLandingPageMinimapButton:SetScript("OnClick", MRBP_OnClick)
		-- ExpansionLandingPageMinimapButton:HookScript("OnClick", MRBP_OnClick)  --> safer, but doesn't work properly!

		-- Mouse Over Minimap Mode
		Minimap:HookScript("OnEnter", MRBP_OnMinimapEnter)
		Minimap:HookScript("OnLeave", MRBP_OnMinimapLeave)
		ExpansionLandingPageMinimapButton:HookScript("OnLeave", MRBP_OnMinimapLeave)
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

function MRBP:CheckShowMinimapButtonInMouseOverMode()
	if (ns.settings.useMouseOverMinimapMode and not ExpansionLandingPageMinimapButton:IsShown()) then
		ExpansionLandingPageMinimapButton:Show();
	end
end

-- Handle mouse-over behavior of the minimap button.
-- Note: 'self' refers to the ExpansionLandingPageMinimapButton, the parent frame.
--
-- REF.: <FrameXML/Minimap.xml>
-- REF.: <FrameXML/SharedTooltipTemplates.lua>
-- REF.: <FrameXML/Blizzard_Minimap/Minimap.lua>
-- 
function MRBP_OnEnter(self, button, description_only)
	if description_only then
		-- Needed for Addon Compartment details
		return self.description;
	end
	MRBP:CheckShowMinimapButtonInMouseOverMode();

	GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	if self:IsInMajorFactionRenownMode() then
		RenownRewardUtil.AddMajorFactionToTooltip(GameTooltip, self.majorFactionID, GenerateClosure(self.SetTooltip, self));
	else
		GameTooltip:SetText(self.title, 1, 1, 1);
		GameTooltip:AddLine(self.description, nil, nil, nil, true);
	end

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
	if (ns.settings.useMiddleButton and LocalDragonridingUtil:IsSkyridingUnlocked()) then
		local tooltipMiddleClickText = L.TOOLTIP_CLICKTEXT2_MINIMAPBUTTON;
		if ns.settings.showAddonNameInTooltip then
			local addonAbbreviation = ns.AddonTitleShort..ns.AddonTitleSeparator;
			tooltipMiddleClickText = GRAY_FONT_COLOR:WrapTextInColorCode(addonAbbreviation).." "..tooltipMiddleClickText;
		end
		GameTooltip_AddNormalLine(GameTooltip, tooltipMiddleClickText);
	end

	GameTooltip:Show();
end

function MRBP_OnMinimapEnter(self, ...)
	MRBP:CheckShowMinimapButtonInMouseOverMode();
end

function MRBP_OnMinimapLeave(self)
	if (ns.settings.useMouseOverMinimapMode and not (MenuTooltip and MenuTooltip:IsShown()) and not (Minimap.ZoomIn and Minimap.ZoomIn:IsShown())) then
		MRBP:HideMinimapButton();
	end
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
	local missionsAvailable, reputationRewardPending, timeWalkingVendorAvailable

	if (expansionInfo.ID < ExpansionInfo.data.DRAGONFLIGHT.ID) then
		missionsAvailable = ShouldShowMissionCompletedHint(expansionInfo.garrisonTypeID)
		reputationRewardPending = ns.settings.showReputationRewardPendingHint and LocalFactionInfo:HasExpansionAnyReputationRewardPending(expansionInfo.ID)
		timeWalkingVendorAvailable = ns.settings.showTimewalkingVendorHint and util.poi.HasTimewalkingVendor(expansionInfo.ID)

	else
		reputationRewardPending = ns.settings.showReputationRewardPendingHint and LocalMajorFactionInfo:HasMajorFactionReputationReward(expansionInfo.ID)
	end

	return {missionsAvailable, reputationRewardPending, timeWalkingVendorAvailable}
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
		ReputationTooltip:SetClampedToScreen(true)
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
	local garrisonInfo = LandingPageInfo:GetLandingPageInfo(expansionInfo.ID);  --> == landingPageInfo
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
	local isForWarWithin = expansionInfo.ID == ExpansionInfo.data.WAR_WITHIN.ID

	------ Unlocking requirements -----

	-- Moved to next category (see below)
	-- Special treatment for Evoker; they don't have a Class Hall in Legion, hence no mission table.
	if (isForLegion and expansionInfo.disabled) then
		if PlayerInfo:IsPlayerEvokerClass() then
			LocalLibQTipUtil:AddBlankLineToTooltip(ExpansionTooltip)
			LocalTooltipUtil:AddTextLine(ExpansionTooltip, garrisonInfo.msg.requirementText, DIM_RED_FONT_COLOR)
		end
	end

	----- Reputation -----

	if (expansionInfo.ID < ExpansionInfo.data.DRAGONFLIGHT.ID and LocalRequirementInfo:CanShowExpansionLandingPage(garrisonInfo)) then
		if ns.IsExpansionOptionSet("showFactionReputation", expansionInfo.ID) then
			local tooltip = ns.IsExpansionOptionSet("separateFactionTooltip", expansionInfo.ID) and ReputationTooltip or ExpansionTooltip
			LocalTooltipUtil:AddFactionReputationLines(tooltip, expansionInfo)
		end
		if ns.IsExpansionOptionSet("showBonusFactionReputation", expansionInfo.ID) then
			local tooltip = ns.IsExpansionOptionSet("separateBonusFactionTooltip", expansionInfo.ID) and ReputationTooltip or ExpansionTooltip
			LocalTooltipUtil:AddBonusFactionReputationLines(tooltip, expansionInfo)
		end
	end
	if (isForShadowlands and ns.settings.showCovenantRenownLevel) then
		local tooltip = ns.settings.separateCovenantRenownLevelTooltip and ReputationTooltip or ExpansionTooltip
		LocalTooltipUtil:AddCovenantRenownLevelLines(tooltip)
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
		if (ns.IsExpansionOptionSet("showWorldMapEvents", expansionInfo.ID) and ns.settings.showDraenorTreasures) then
			LocalTooltipUtil:AddDraenorTreasureLines(ExpansionTooltip)
		end
	end

	----- Bounty board infos (Legion + BfA + Shadowlands only) -----

	if ShouldShowBountyBoardText(expansionInfo.garrisonTypeID) then
		LocalTooltipUtil:AddBountyBoardLines(ExpansionTooltip, garrisonInfo)
	end

	----- Legion -----

	if (isForLegion and ns.IsExpansionOptionSet("showWorldMapEvents", expansionInfo.ID)) then
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
		if (ns.IsExpansionOptionSet("showWorldMapEvents", expansionInfo.ID) and ns.settings.showBfAFactionAssaultsInfo) then
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
				LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, islandExpeditionInfo.progressText..L.TEXT_DELIMITER..appendedText, islandExpeditionInfo.isCompleted)
			end
		end
	end

	----- Dragonflight -----

	if isForDragonflight then
		-- Faction reputation progress
		if ns.IsExpansionOptionSet("showMajorFactionRenownLevel", expansionInfo.ID) then
			local tooltip = ns.IsExpansionOptionSet("separateMajorFactionTooltip", expansionInfo.ID) and ReputationTooltip or ExpansionTooltip
			LocalTooltipUtil:AddMajorFactionsRenownLines(tooltip, expansionInfo)
		end
		if ns.IsExpansionOptionSet("showBonusFactionReputation", expansionInfo.ID) then
			local tooltip = ns.IsExpansionOptionSet("separateBonusFactionTooltip", expansionInfo.ID) and ReputationTooltip or ExpansionTooltip
			LocalTooltipUtil:AddBonusFactionReputationLines(tooltip, expansionInfo)
		end
		-- Dragon Glyphs
		if ns.IsExpansionOptionSet("showDragonGlyphs", expansionInfo.ID) then
			LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, L["showDragonGlyphs"])
			LocalTooltipUtil:AddDragonGlyphLines(ExpansionTooltip, expansionInfo.ID)
		end
		----- World Map events -----
		if ns.IsExpansionOptionSet("showWorldMapEvents", expansionInfo.ID) then
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

	----- The War Within -----

	if isForWarWithin then
		-- Faction reputation progress
		if ns.IsExpansionOptionSet("showMajorFactionRenownLevel", expansionInfo.ID) then
			local tooltip = ns.IsExpansionOptionSet("separateMajorFactionTooltip", expansionInfo.ID) and ReputationTooltip or ExpansionTooltip
			LocalTooltipUtil:AddMajorFactionsRenownLines(tooltip, expansionInfo)
		end
		if ns.IsExpansionOptionSet("showBonusFactionReputation", expansionInfo.ID) then
			local tooltip = ns.IsExpansionOptionSet("separateBonusFactionTooltip", expansionInfo.ID) and ReputationTooltip or ExpansionTooltip
			LocalTooltipUtil:AddBonusFactionReputationLines(tooltip, expansionInfo)
		end
		-- Dragon Glyphs
		if ns.IsExpansionOptionSet("showDragonGlyphs", expansionInfo.ID) then
			LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, L["showDragonGlyphs"])
			LocalTooltipUtil:AddDragonGlyphLines(ExpansionTooltip, expansionInfo.ID)
		end
		----- World Map events -----
		if ns.IsExpansionOptionSet("showWorldMapEvents", expansionInfo.ID) then
			-- Theater Troupe
			if ns.settings.showTheaterTroupeInfo then
				local twwTheaterTroupeInfo = ns.poi10.GetTheaterTroupeInfo()
				if twwTheaterTroupeInfo then
					-- The world map POI's tooltip info doesn't update unless we are in the same zone as the event.
					local mapIDonly = true
					local isPlayerInIsleOfDorn = (twwTheaterTroupeInfo.mapInfo.mapID == PlayerInfo:GetPlayerMapLocation(mapIDonly))
					LocalTooltipUtil:AddHeaderLine(ExpansionTooltip, isPlayerInIsleOfDorn and twwTheaterTroupeInfo.name or L["showTheaterTroupeInfo"])
					LocalTooltipUtil:AddIconLine(ExpansionTooltip, twwTheaterTroupeInfo.mapInfo.name, twwTheaterTroupeInfo.atlasName)
					LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, twwTheaterTroupeInfo.areaName)
					LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, twwTheaterTroupeInfo.timeString)  -- time until next event
					if twwTheaterTroupeInfo.timeString2 then
						LocalTooltipUtil:AddTimeRemainingLine(ExpansionTooltip, twwTheaterTroupeInfo.timeString2)  -- preparations + active timer
					end
					if (isPlayerInIsleOfDorn and not L:StringIsEmpty(twwTheaterTroupeInfo.description)) then  -- and not ns.settings.hideEventDescriptions then
						LocalTooltipUtil:AddObjectiveLine(ExpansionTooltip, twwTheaterTroupeInfo.description)
					end
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
	local lineIndex = MenuTooltip:AddLine('', '', '')
	MenuTooltip:SetCell(lineIndex, 1, info.hintIconInfo, nil, nil, nil, isSettingsLine and ns.TextureCellProvider or ns.HintIconCellProvider)
	MenuTooltip:SetCell(lineIndex, 2, info.label, MenuTooltip_GetCellStyle())
	MenuTooltip:SetCell(lineIndex, 3, info.minimapIcon, nil, nil, nil, ns.TextureCellProvider)
	if ns.settings.showEntryTooltip then
		MenuTooltip:SetLineScript(lineIndex, "OnEnter", MenuLine_OnEnter, info)
		MenuTooltip:SetLineScript(lineIndex, "OnLeave", MenuLine_OnLeave)
	end
	if info.color then
		MenuTooltip:SetLineTextColor(lineIndex, info.color:GetRGBA())
	end
	if info.disabled then														--> TODO - Check if still needed
    	MenuTooltip:SetLineTextColor(lineIndex, DISABLED_FONT_COLOR:GetRGBA())
	elseif info.func then
	-- if (info.func and not info.disabled) then
		MenuTooltip:SetLineScript(lineIndex, "OnMouseUp", MenuLine_OnClick, info)
	end
	-- Highlight expansion for current zone
	if ns.settings.highlightCurrentZone then
		local landingPageInfo = LandingPageInfo:GetPlayerLocationLandingPageInfo()
		if (landingPageInfo and landingPageInfo.expansionID == info.ID) then
			local r, g, b, a = DARKGRAY_COLOR:GetRGBA()
			MenuTooltip:SetLineColor(lineIndex, r, g, b, 0.75)
			MenuTooltip:SetLineTextColor(lineIndex, LIGHTERBLUE_FONT_COLOR:GetRGBA())
		end
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
		MRBP_OnMinimapLeave()
	end
	MenuTooltip:SetCellMarginV(ns.settings.menuLineHeight)
	MenuTooltip:SetFrameLevel(parent:GetFrameLevel() + 10)
	-- Mouse Over Minimap Mode
	MRBP:CheckShowMinimapButtonInMouseOverMode();
	-- Expansion list
	local sortFunc = ns.settings.reverseSortorder and ExpansionInfo.SortAscending or ExpansionInfo.SortDescending
	local expansionList = ExpansionInfo:GetExpansionsWithLandingPage(sortFunc)
	for _, expansionInfo in ipairs(expansionList) do
		local playerOwnsExpansion = ExpansionInfo:DoesPlayerOwnExpansion(expansionInfo.ID)
		local isActiveEntry = tContains(ns.settings.activeMenuEntries, tostring(expansionInfo.ID))  --> user option
		if (playerOwnsExpansion and isActiveEntry) then
			local landingPageInfo = LandingPageInfo:GetLandingPageInfo(expansionInfo.ID)
			expansionInfo.label = ns.settings.preferExpansionName and expansionInfo.name or landingPageInfo.title
			expansionInfo.minimapIcon = ns.settings.showLandingPageIcons and landingPageInfo:GetMinimapIcon() or ''
			expansionInfo.disabled = not LocalRequirementInfo:CanShowExpansionLandingPage(landingPageInfo)
			expansionInfo.hintIconInfo = ShouldShowHintColumn() and GetExpansionHintIconInfo(expansionInfo)
			expansionInfo.color = CreateColorFromHexString(ns.settings["menuTextColor"])
			expansionInfo.func = function() MRBP_ToggleLandingPageFrames(expansionInfo.garrisonTypeID, expansionInfo.landingPageTypeID) end
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
		PlaySound(MenuVariants.GetDropdownCloseSoundKit())
		ReleaseTooltip(MenuTooltip)
	else
		PlaySound(MenuVariants.GetDropdownOpenSoundKit())
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
		ToggleMenuTooltip(self);  --> New style (LibQTip.Tooltip)
	elseif (button == "MiddleButton" and not ns.settings.useMiddleButton) then
		return;  --> Do this instead of un-registering the mouse click.
	elseif (button == "MiddleButton" and ns.settings.useMiddleButton and LocalDragonridingUtil:IsSkyridingUnlocked()) then
		LocalDragonridingUtil:ToggleSkyridingSkillTree();
	else
		-- Pass-through the button click to the original function on LeftButton
		-- click, but hide an eventually already opened landing page frame.
		-- if (not ExpansionLandingPageMinimapButton.garrisonMode and GarrisonLandingPage and GarrisonLandingPage:IsShown()) then
		-- 	HideUIPanel(GarrisonLandingPage);
		-- end
		local garrisonTypeID = ExpansionLandingPageMinimapButton.garrisonType;
		local landingPageTypeID = ExpansionLandingPageMinimapButton.expansionLandingPageType;
		-- print("Toggling custom handler, IDs:", garrisonTypeID, landingPageTypeID)
		MRBP_ToggleLandingPageFrames(garrisonTypeID, landingPageTypeID);
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
	-- print(YELLOW_FONT_COLOR:WrapTextInColorCode("MRBP_GetLandingPageGarrisonType..."))

	-- -- Check non-garrison types (== newer expansions) first
	-- local landingPageTypeID = MRBP_GetLandingPageType_orig(ExpansionLandingPage);
	-- print("> landingPageTypeID1:", landingPageTypeID)
	-- if LocalLandingPageTypeUtil:IsValidExpansionLandingPageType(landingPageTypeID) then
	-- 	-- We're in Dragonflight or newer expansion area
	-- 	local nonGarrisonTypeID = 0;
	-- 	LocalLandingPageTypeUtil:SetLandingPageGarrisonType(nonGarrisonTypeID);
	-- 	return nonGarrisonTypeID;
	-- end

	-- if  LocalLandingPageTypeUtil.currentGarrisonTypeID == LocalLandingPageTypeUtil.previousGarrisonTypeID then
	-- 	-- We're still in the same area
	-- 	print("--> same area:", LocalLandingPageTypeUtil.currentGarrisonTypeID)
	-- 	return LocalLandingPageTypeUtil.currentGarrisonTypeID;
	-- end

	-- Get default values
	local garrisonTypeID = MRBP_GetLandingPageGarrisonType_orig() or 0;
	-- local currentType = ns.settings.currentExpansionLandingPageType;

	-- local value = (garrisonTypeID == currentType.garrisonTypeID) and garrisonTypeID or currentType.garrisonTypeID;
	local value = garrisonTypeID;
	-- print("> garrisonTypeID:", value)
	return value;

	-- -- Try custom type, a garrison type based on the player's current location
	-- local playerGarrisonInfo = LandingPageInfo:GetPlayerLocationLandingPageInfo();
	-- if playerGarrisonInfo then
	-- 	-- -- We ignore Dragonflight and newer expansion locations
	-- 	-- if LocalLandingPageTypeUtil:IsValidExpansionLandingPageType(playerGarrisonInfo.landingPageTypeID) then
	-- 	-- 	-- We're in Dragonflight or newer expansion area
	-- 	-- 	local nonGarrisonTypeID = 0;
	-- 	-- 	LocalLandingPageTypeUtil:SetLandingPageGarrisonType(nonGarrisonTypeID);
	-- 	-- 	return nonGarrisonTypeID;
	-- 	-- end

	-- 	local playerGarrisonTypeID = playerGarrisonInfo.garrisonTypeID;
	-- 	-- if LocalLandingPageTypeUtil:IsValidGarrisonType(playerGarrisonTypeID) and playerGarrisonTypeID ~= LocalLandingPageTypeUtil.previousGarrisonTypeID then
	-- 	if LocalLandingPageTypeUtil:IsValidGarrisonType(playerGarrisonTypeID) then
	-- 	-- 	local isUnlocked = LocalLandingPageTypeUtil:IsGarrisonTypeUnlocked(playerGarrisonTypeID);
	-- 	-- 	if isUnlocked then
	-- 	-- 		LocalLandingPageTypeUtil:SetLandingPageGarrisonType(playerGarrisonTypeID);
	-- 	-- 		return playerGarrisonTypeID;
	-- 	-- 	end
	-- 		print("> playerGarrisonTypeID:", playerGarrisonTypeID);
	-- 		return playerGarrisonTypeID;
	-- 	end
	-- -- elseif LocalLandingPageTypeUtil:IsValidGarrisonType(garrisonTypeID) then
	-- -- 	return garrisonTypeID;
	-- end

	-- -- Pass default garrison type through
	-- -- LocalLandingPageTypeUtil:SetLandingPageGarrisonType(garrisonTypeID);
	-- print("> garrisonTypeID:", garrisonTypeID);
	-- return garrisonTypeID;
end

-- function MRBP_GetLandingPageType(self)
-- 	-- print(YELLOW_FONT_COLOR:WrapTextInColorCode("MRBP_GetLandingPageType..."))

-- 	-- Get default values
-- 	local landingPageTypeID = MRBP_GetLandingPageType_orig(self);
-- 	-- local currentType = ns.settings.currentExpansionLandingPageType;

-- 	-- local value = (landingPageTypeID == currentType.landingPageTypeID) and landingPageTypeID or currentType.landingPageTypeID;
-- 	local value = landingPageTypeID;
-- 	print("--> landingPageTypeID:", value)
-- 	return value;

	-- -- if not LocalLandingPageTypeUtil:IsValidExpansionLandingPageType(landingPageTypeID) then
	-- -- 	return landingPageTypeID;
	-- -- end

	-- -- if landingPageTypeID == LocalLandingPageTypeUtil.currentLandingPageTypeID then
	-- -- 	-- We're still in the same area
	-- -- 	print("-->> same area:", landingPageTypeID)
	-- -- 	return landingPageTypeID;
	-- -- end

	-- -- Try custom type, a garrison type based on the player's current location
	-- local playerLandingPageTypeInfo = LandingPageInfo:GetPlayerLocationLandingPageInfo();
	-- local playerLandingPageTypeID = playerLandingPageTypeInfo and playerLandingPageTypeInfo.landingPageTypeID;
	-- print("> playerLandingPageTypeID:", playerLandingPageTypeID);
	-- -- if LocalLandingPageTypeUtil:IsValidExpansionLandingPageType(playerLandingPageTypeID) then
	-- -- -- 	local isUnlocked = LocalLandingPageTypeUtil:IsExpansionLandingPageTypeUnlocked(landingPageTypeID);
	-- -- -- 	if isUnlocked then
	-- -- -- 		LocalLandingPageTypeUtil:SetExpansionLandingPageType(landingPageTypeID);
	-- -- -- 		return landingPageTypeID;
	-- -- -- 	end
	-- -- 	return playerLandingPageTypeID;
	-- -- end

	-- local playerGarrisonTypeID = playerLandingPageTypeInfo and playerLandingPageTypeInfo.garrisonTypeID;
	-- if LocalLandingPageTypeUtil:IsValidGarrisonType(playerGarrisonTypeID) then
	-- 	print("--> landingPageTypeID:", 0)
	-- 	return 0;
	-- end

	-- -- Fallback to default value
	-- -- LocalLandingPageTypeUtil:SetExpansionLandingPageType(landingPageTypeID);
	-- print("--> landingPageTypeID:", landingPageTypeID)
	-- return landingPageTypeID;
-- end

-- local function GetCurrentLandingPageInfo()
--     -- -- Always return same LandingPageInfo
--     -- return self:GetLandingPageInfo(ExpansionInfo.data.BATTLE_FOR_AZEROTH.ID);
--     local currentType = ns.settings.currentExpansionLandingPageType;

--     if LocalLandingPageTypeUtil:IsValidGarrisonType(currentType.garrisonTypeID) then
--         return LandingPageInfo:GetGarrisonInfo(currentType.garrisonTypeID);
--     end
--     if LocalLandingPageTypeUtil:IsValidExpansionLandingPageType(currentType.landingPageTypeID) then
--         return LandingPageInfo:GetLandingPageInfo(currentType.landingPageTypeID);
--     end
-- end

-- REF.: <https://www.townlong-yak.com/framexml/live/Blizzard_Minimap/Minimap.lua>
-- 
-- function MRBP_RefreshButton(self, forceUpdateIcon)
-- 	-- print(YELLOW_FONT_COLOR:WrapTextInColorCode("Refreshing Minimap Button, forceUpdateIcon:"), forceUpdateIcon)

-- 	-- local playerLandingPageInfo = LandingPageInfo:GetPlayerLocationLandingPageInfo();
-- 	local playerLandingPageInfo = GetCurrentLandingPageInfo();
-- 	self.mode = LocalLandingPageTypeUtil:GetLandingPageModeForLandingPageInfo(playerLandingPageInfo, self.mode);
-- 	-- print("--> mode:", self.mode, self:IsInGarrisonMode(), self:IsInMajorFactionRenownMode(), self:IsExpansionOverlayMode())

-- 	local previousMode = self.mode;
-- 	-- print("<< previousMode:", previousMode)
-- 	local wasInGarrisonMode = self:IsInGarrisonMode();
-- 	if C_GameRules.IsGameRuleActive(Enum.GameRule.LandingPageFactionID) then
-- 		self.mode = ExpansionLandingPageMode.MajorFactionRenown;
-- 		self.majorFactionID = C_GameRules.GetGameRuleAsFloat(Enum.GameRule.LandingPageFactionID);
-- 	-- elseif ExpansionLandingPage:IsOverlayApplied() then
-- 	-- 	self.mode = ExpansionLandingPageMode.ExpansionOverlay;
-- 	-- else
-- 	-- 	self.mode = nil;
-- 	end
-- 	if wasInGarrisonMode and not self:IsInGarrisonMode() then
-- 		-- print("wasInGarrisonMode:", wasInGarrisonMode)
-- 		if (GarrisonLandingPage and GarrisonLandingPage:IsShown()) then
-- 			HideUIPanel(GarrisonLandingPage);
-- 		end
-- 		self:ClearPulses();
-- 		-- FrameUtil.UnregisterFrameForEvents(self, LocalGarrisonLandingPageEvents);
-- 	end
-- 	-- if self.mode ~= previousMode or forceUpdateIcon == true then
-- 	-- 	self:Hide();
-- 	-- 	-- -- Intervene
-- 	-- 	-- print(">> defaultMode:", self.mode, "peviousMode:", previousMode)
-- 	-- 	-- if not self.mode then
-- 	-- 	-- 	local playerLandingPageInfo = LandingPageInfo:GetPlayerLocationLandingPageInfo();
-- 	-- 	-- 	self.mode = LocalLandingPageTypeUtil:GetLandingPageModeForLandingPageInfo(playerLandingPageInfo, previousMode);
-- 	-- 	-- 	print("--> mode:", self.mode)
-- 	-- 	-- end
-- 	-- 	-- -- 
-- 	-- 	if self.mode then
-- 	-- 		self:UpdateIcon();
-- 	-- 		self:Show();
-- 	-- 	end
-- 	-- end
-- 	if self.mode ~= previousMode or forceUpdateIcon == true then
-- 		-- print("> Hiding previous button...")
-- 		self:Hide();
-- 	end
-- 	if self.mode then
-- 		-- print("> Icon is being updated...")
-- 		self:UpdateIcon();
-- 		self:Show();
-- 	end
-- end

--------------------------------------------------------------------------------

local landingPageOverlay = {
	[ExpansionInfo.data.DRAGONFLIGHT.ID] = CreateFromMixins(DragonflightLandingOverlayMixin),
	[ExpansionInfo.data.WAR_WITHIN.ID] = CreateFromMixins(WarWithinLandingOverlayMixin),
};

function MRBP_ApplyExpansionLandingPageOverlay(landingPageTypeID)
	local expansionInfo = ExpansionInfo:GetExpansionDataByExpansionLandingPageType(landingPageTypeID);
	local expansionID = expansionInfo.ID;

	if not expansionID or expansionID < ExpansionInfo.data.DRAGONFLIGHT.ID then
		return;
	end

	local overlay = landingPageOverlay[expansionID];

	if ExpansionLandingPage.overlayFrame then
		ExpansionLandingPage.overlayFrame:Hide();
	end

	ExpansionLandingPage.overlayFrame = overlay.CreateOverlay(ExpansionLandingPage.Overlay);
	ExpansionLandingPage.overlayFrame:Show();
end

-- This is called eg. on every zone change. Get the newest unlocked expansion overlay und refresh.
--> Note: This is almost exactly what Blizzard's default function does, but for some reasons it doesn't work outside
--> zones of newer expansions, eg. outside Dragonflight or Khaz Algar.
-- 
-- REF.: [Blizzard_ExpansionLandingPage.lua](https://www.townlong-yak.com/framexml/live/Blizzard_ExpansionLandingPage/Blizzard_ExpansionLandingPage.lua)
-- 
function MRBP_RefreshExpansionOverlay(self)
	local newestOverlay = self:GetNewestExpansionOverlayForPlayer();
	-- print("Overlay update...", "LandingPageType:", ExpansionLandingPage:GetLandingPageType())

	if newestOverlay then
		-- Blizzard shows by default DF overlay in DF zones, TWW overlay in TWW zones, etc. This overwrites this
		-- behavior in order to stick to the most latest (newest) unlocked expansion.
		local newestUnlockedExpansionID = LocalLandingPageTypeUtil:GetMaximumUnlockedLandingPageExpansionID();
		local landingPageInfo = LandingPageInfo:GetLandingPageInfo(newestUnlockedExpansionID);
		if landingPageInfo then
			local displayInfo = newestOverlay.GetMinimapDisplayInfo();
			if displayInfo and displayInfo.expansionLandingPageType ~= landingPageInfo.landingPageTypeID then
				-- print("> Overwriting newestOverlay...")
				newestOverlay = landingPageOverlay[newestUnlockedExpansionID];
			end
		end
	end

	if not newestOverlay then
		-- No overlay available outside the Dragon Isles or Khaz Algar by default before unlocking upcoming Expansion Landing Page. Retrieve manually.
		local newestUnlockedExpansionID = LocalLandingPageTypeUtil:GetMaximumUnlockedLandingPageExpansionID();
		newestOverlay = landingPageOverlay[newestUnlockedExpansionID] and landingPageOverlay[newestUnlockedExpansionID];
		-- print("> Updating manually... -->", newestUnlockedExpansionID)
	end
	-- print("-->", ExpansionLandingPage.expansionLandingPageType, ExpansionLandingPageMinimapButton.expansionLandingPageType) --, landingPageTypeID)

	-- Original code
	if newestOverlay ~= self.overlay then
		if self.overlayFrame then
			self.overlayFrame:Hide();
		end

		if self.overlay then
			local minimapAnimationEvents = self.overlay.GetMinimapAnimationEvents();
			if minimapAnimationEvents then
				FrameUtil.UnregisterFrameForEvents(self, minimapAnimationEvents);
			end
		end

		self.overlay = newestOverlay;

		if self.overlay then
			self.overlayFrame = newestOverlay.CreateOverlay(self.Overlay);
			self.overlayFrame:Show();

			local minimapAnimationEvents = self.overlay.GetMinimapAnimationEvents();
			if minimapAnimationEvents then
				FrameUtil.RegisterFrameForEvents(self, minimapAnimationEvents);
			end
		end

		EventRegistry:TriggerEvent("ExpansionLandingPage.ClearPulses");
		EventRegistry:TriggerEvent("ExpansionLandingPage.OverlayChanged");

		if self.overlay and self.overlay.TryCelebrateUnlock then
			self.overlay:TryCelebrateUnlock();
			-- Renew minimap button hook
			ExpansionLandingPageMinimapButton:SetScript("OnClick", MRBP_OnClick);
		end
	end
end


--> TODO - Find a more secure way to pre-hook these.
MRBP_GetLandingPageGarrisonType_orig = C_Garrison.GetLandingPageGarrisonType
C_Garrison.GetLandingPageGarrisonType = MRBP_GetLandingPageGarrisonType

-- MRBP_GetLandingPageType_orig = ExpansionLandingPage.GetLandingPageType;
-- ExpansionLandingPage.GetLandingPageType = MRBP_GetLandingPageType;

-- MRBP_RefreshButton_orig = ExpansionLandingPageMinimapButton.RefreshButton;
-- ExpansionLandingPageMinimapButton.RefreshButton = MRBP_RefreshButton;

MRBP_RefreshExpansionOverlay_orig = ExpansionLandingPage.RefreshExpansionOverlay;
ExpansionLandingPage.RefreshExpansionOverlay = MRBP_RefreshExpansionOverlay;

-- IsGarrisonLandingPageFeatured()
-- ExpansionLandingPage:IsOverlayApplied()
-- ExpansionLandingPageMinimapButton:RefreshButton(forceUpdateIcon)

-- ExpansionLandingPageMinimapButton:RefreshButton()
-- ExpansionLandingPageMinimapButton:ResetLandingPageIconOffset()
-- ExpansionLandingPageMinimapButton:UpdateIcon()

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
					local landingPageInfo = LandingPageInfo:GetLandingPageInfo(expansion.ID);
				    _log:debug("HasGarrison:", util.garrison.HasGarrison(expansion.garrisonTypeID),
							   "- unlocked:", LocalRequirementInfo:IsLandingPageUnlocked(landingPageInfo),
							   "- hasIntro:", LocalRequirementInfo:IsIntroQuestCompleted(expansion.ID, landingPageInfo.tagName));
				end

				local playerLevel = UnitLevel("player");
				local expansionLevelForPlayer = ExpansionInfo:GetExpansionForPlayerLevel(playerLevel);
				local playerMaxLevelForExpansion = ExpansionInfo:GetMaxPlayerLevel();
				local expansion = ExpansionInfo:GetExpansionData(expansionLevelForPlayer);

				_log:debug(" ");
				_log:debug("expansionLevelForPlayer:", expansionLevelForPlayer, ",", expansion.name);
				_log:debug("playerLevel:", playerLevel);
				_log:debug("playerMaxLevelForExpansion:", playerMaxLevelForExpansion);

				_log.level = prev_loglvl;

			elseif (msg == 'xptest') then
				local maxExpansionID = ExpansionInfo:GetMaximumExpansionLevel();  --> max. available
				local minExpansionID = ExpansionInfo:GetMinimumExpansionLevel();  --> min. available
				local playerExpansionID = ExpansionInfo:GetExpansionForPlayerLevel();  --> currently available for player
				print(" ");
				print("max. expansionID:", maxExpansionID);
				print("min. expansionID:", minExpansionID);
				print("player expansionID:", playerExpansionID);
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
		if (ns.settings.useMiddleButton and LocalDragonridingUtil:IsSkyridingUnlocked()) then
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
		local garrisonInfo = LandingPageInfo:GetLandingPageInfo(expansion.ID);
		garrisonInfo.shouldShowDisabled = not LocalRequirementInfo:IsIntroQuestCompleted(garrisonInfo.expansionID, garrisonInfo.tagName);
		local playerOwnsExpansion = ExpansionInfo:DoesPlayerOwnExpansion(expansion.ID);
		local isActiveEntry = tContains(ns.settings.activeMenuEntries, tostring(expansion.ID)); --> user option
		garrisonInfo.missions = {};
		garrisonInfo.missions.numInProgress, garrisonInfo.missions.numCompleted = util.garrison.GetInProgressMissionCount(expansion.garrisonTypeID);

		if (playerOwnsExpansion and isActiveEntry) then
			if garrisonInfo.shouldShowDisabled then
				GameTooltip_AddDisabledLine(tooltip, expansion.name);
				util.GameTooltip_AddAtlas(tooltip, garrisonInfo:GetMinimapIcon(), 36, 36, Enum.TooltipTextureAnchor.RightCenter);
				GameTooltip_AddErrorLine(tooltip, garrisonInfo.msg.requirementText, nil, leftOffset);
			else
				-- Expansion name
				GameTooltip_AddHighlightLine(tooltip, expansion.name);
				util.GameTooltip_AddAtlas(tooltip, garrisonInfo:GetMinimapIcon(), 36, 36, Enum.TooltipTextureAnchor.RightCenter);
				-- Dragonflight + War Within
				if (expansion.ID >= ExpansionInfo.data.DRAGONFLIGHT.ID) then
					-- Major Factions
					local majorFactionData = LocalMajorFactionInfo:GetAllMajorFactionDataForExpansion(expansion.ID);
					if (#majorFactionData > 0) then
						for _, factionData in ipairs(majorFactionData) do
							local factionAtlasName = "MajorFactions_Icons_"..factionData.textureKit.."512";
							if factionData.isUnlocked then
								local factionColor = LocalMajorFactionInfo:GetMajorFactionColor(factionData);
								local renownLevelText = factionColor:WrapTextInColorCode(MAJOR_FACTION_BUTTON_RENOWN_LEVEL:format(factionData.renownLevel));
								local levelThreshold = factionData.renownLevelThreshold;
								local reputationEarned = factionData.renownReputationEarned;
								local suffixText = '';
								local isParagon = LocalFactionInfo:IsFactionParagon(factionData.factionID);
								if isParagon then
									local paragonInfo = LocalFactionInfo:GetFactionParagonInfo(factionData.factionID);
									local value = mod(paragonInfo.currentValue, paragonInfo.threshold);
									levelThreshold = paragonInfo.threshold;
									reputationEarned = paragonInfo.hasRewardPending and value + paragonInfo.threshold or value;
									local bagIconString = paragonInfo.hasRewardPending and TOOLTIP_BAG_FULL_ICON_STRING or TOOLTIP_BAG_ICON_STRING;
									suffixText = L.TEXT_DELIMITER..bagIconString;
								end
								local reputationLevelText = L.REPUTATION_PROGRESS_FORMAT:format(reputationEarned, levelThreshold);
								local lineText = format("%s: %s - %s", factionData.name, renownLevelText, HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(reputationLevelText));
								local hasMaxRenown = LocalMajorFactionInfo:HasMaximumMajorFactionRenown(factionData.factionID);
								util.GameTooltip_AddObjectiveLine(tooltip, lineText..suffixText, hasMaxRenown, wrapLine, leftOffset, factionAtlasName);
							else
								local lineText = format("%s: %s", factionData.name, DISABLED_FONT_COLOR:WrapTextInColorCode(MAJOR_FACTION_BUTTON_FACTION_LOCKED));
								util.GameTooltip_AddObjectiveLine(tooltip, lineText, factionData.isUnlocked, wrapLine, leftOffset, factionAtlasName)
							end
						end
					end
					-- Dragon Glyphs
					local treeCurrencyInfo = LocalDragonridingUtil:GetDragonRidingTreeCurrencyInfo();
					local glyphsPerZone, numGlyphsCollected, numGlyphsTotal = LocalDragonridingUtil:GetDragonGlyphsCount(expansion.ID);
					local collectedAmountString = WHITE_FONT_COLOR:WrapTextInColorCode(GENERIC_FRACTION_STRING:format(numGlyphsCollected, numGlyphsTotal));
					local isCompleted = numGlyphsCollected == numGlyphsTotal;
					util.GameTooltip_AddObjectiveLine(tooltip, L["showDragonGlyphs"]..": "..collectedAmountString, isCompleted, wrapLine, leftOffset, treeCurrencyInfo.texture);
				end

				----- The War Within -----

				if (expansion.ID == ExpansionInfo.data.WAR_WITHIN.ID) then
					-- Theater Troupe
					if ns.settings.showTheaterTroupeInfo then
						local twwTheaterTroupeInfo = ns.poi10.GetTheaterTroupeInfo()
						if twwTheaterTroupeInfo then
							local timeLeft = twwTheaterTroupeInfo.timeString2 or twwTheaterTroupeInfo.timeString or "..."
							local lineText = format("%s @ %s", L["showTheaterTroupeInfo"], twwTheaterTroupeInfo.mapInfo.name)..": "..timeLeft;
							util.GameTooltip_AddObjectiveLine(tooltip, lineText, nil, wrapLine, leftOffset, twwTheaterTroupeInfo.atlasName);
						end
					end
				end

				----- Dragonflight -----

				if (expansion.ID == ExpansionInfo.data.DRAGONFLIGHT.ID) then
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
					local renownInfo = covenantInfo and util.covenant.GetRenownData(covenantInfo.ID);
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
				if ShouldShowBountyBoardText(expansion.garrisonTypeID) then
					local bountyBoard = garrisonInfo.bountyBoard;
					if bountyBoard and bountyBoard.AreBountiesUnlocked() then
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
		local isAnyUnlocked = LocalRequirementInfo:IsAnyLandingPageAvailable();
		if isAnyUnlocked then
			MRBP_OnClick(ExpansionLandingPageMinimapButton, clickInfo.buttonName, false);
		end
	end
	if (clickInfo.buttonName == "RightButton") then
		MRBP_Settings_ToggleSettingsPanel(AddonID);
	end
	if (clickInfo.buttonName == "MiddleButton" and ns.settings.useMiddleButton and LocalDragonridingUtil:IsSkyridingUnlocked()) then
		LocalDragonridingUtil:ToggleSkyridingSkillTree();
	end
end
