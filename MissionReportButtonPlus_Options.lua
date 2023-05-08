--------------------------------------------------------------------------------
--[[ Mission Report Button Plus - Interface Options (Settings) ]]--
--
-- by erglo <erglo.coder+MRBP@gmail.com>
--
-- Copyright (C) 2023  Erwin D. Glockner (aka ergloCoder)
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
-- Files used for reference:
-- REF.: <FrameXML/InterfaceOptionsFrame.lua>	--> deprecated since WoW 10.x
-- REF.: <FrameXML/InterfaceOptionsPanels.lua>	--> deprecated since WoW 10.x
-- REF.: <FrameXML/OptionsPanelTemplates.lua>
-- REF.: <FrameXML/UIDropDownMenuTemplates.lua>
-- REF.: <FrameXML/UIDropDownMenu.lua>
-- REF.: <FrameXML/Settings/Blizzard_Deprecated.lua>
-- REF.: <FrameXML/Settings/Blizzard_ImplementationReadme.lua>
-- REF.: <FrameXML/GlobalColors.lua>
-- REF.: <FrameXML/SharedFontStyles.xml>
--
--------------------------------------------------------------------------------

local AddonID, ns = ...;
local L = ns.L;
local _log = ns.dbg_logger;
local util = ns.utilities;

----- User settings ------------------------------------------------------------

ns.settings = {};  --> user settings for currently active game session
ns.defaultSettings = {  --> default + fallback settings
	-- Common
	["showChatNotifications"] = true,
	["showMinimapButton"] = true,
	["showAddonNameInTooltip"] = true,
	-- Dropdown menu
	["showEntryTooltip"] = true,
	["preferExpansionName"] = true,
	["reverseSortorder"] = false,
	["showMissionTypeIcons"] = true,
	["showMissionCompletedHint"] = true,
	["showMissionCompletedHintOnlyForAll"] = false,
	["menuStyleID"] = "1",
	-- Menu entries
	["activeMenuEntries"] = {"5", "6", "7", "8", "9"},
	-- Menu entries tooltip
	-- ["showBountyRequirements"] = true,
	-- ["showThreatsTimeRemaining"] = true,
	-- ["showEntryRequirements"] = true,
	-- Dragonflight
	["showMajorFactionRenownLevel"] = true,
	["applyMajorFactionColors"] = true,
	["hideMajorFactionUnlockDescription"] = false,
	["showDragonGlyphs"] = true,
	["autoHideCompletedDragonGlyphZones"] = false,
	["showDragonflightWorldMapEvents"] = true,
	["showDragonridingRaceInfo"] = true,
	["showGrandHuntsInfo"] = true,
	["showCampAylaagInfo"] = true,
	["showCommunityFeastInfo"] = true,
	["showDragonbaneKeepInfo"] = true,
	["showElementalStormsInfo"] = true,
	-- Shadowlands
	["showCovenantMissionInfo"] = true,
	["showCovenantBounties"] = true,
	["showMawThreats"] = true,
	["showCovenantRenownLevel"] = true,
	["applyCovenantColors"] = true,
	-- Battle for Azeroth
	["showBfAMissionInfo"] = true,
	["showBfABounties"] = true,
	["showNzothThreats"] = true,
	["showBfAFactionAssaultsInfo"] = true,
	["showBfAWorldMapEvents"] = true,
	["applyBfAFactionColors"] = true,
	["showBfAIslandExpeditionsInfo"] = true,
	-- Legion
	["showLegionMissionInfo"] = true,
	["showLegionBounties"] = true,
	["showLegionWorldMapEvents"] = true,
	["showLegionAssaultsInfo"] = true,
	["showBrokenShoreInvasionInfo"] = true,
	["showArgusInvasionInfo"] = true,
	["applyInvasionColors"] = true,
	["showLegionTimewalkingVendor"] = true,
	-- Warlords of Draenor
	["showWoDMissionInfo"] = true,
	["showWoDGarrisonInvasionAlert"] = true,
	["showWoDWorldMapEvents"] = true,
	["showWoDTimewalkingVendor"] = true,
	-- Tests
	-- ["disableShowMinimapButtonSetting"] = false,   --> temp. solution for beta2
};

---Loads the saved variables for the current game character.
---**Note:** Always use `ns.settings` in this project. It holds ALL setting infos after loading,
---not so the saved variables. Variable names might also change after a while.
---
---REF.: <FrameXML/TableUtil.lua>
---
---@param verbose (boolean|nil)  If true, prints debug messages to chat
---
local function LoadSettings(verbose)
	local prev_loglvl = _log.level;
	_log.level = verbose and _log.DEBUG or _log.level;

	_log:info("Loading settings...");

	-- Load the default settings first and overwrite each changed value of the 
	-- current game session with those from the char-specific settings.
	ns.settings = CopyTable(ns.defaultSettings);
	_log:debug(format(".. defaults loaded: %d |4setting:settings; in total", util.tcount(ns.settings)));

	-- Prepare character-specific settings
	if (MRBP_PerCharSettings == nil) then
		MRBP_PerCharSettings = {};
		_log:debug(".. initializing character-specific settings");
	end
	-- Update `ns.settings` with current char's values
	local numCharSettings = util.tcount(MRBP_PerCharSettings);
	if (numCharSettings > 0) then
		MergeTable(ns.settings, MRBP_PerCharSettings);
		_log:debug(format(".. updated by %d character-specific |4setting:settings;", numCharSettings));
	end

	-- Clean-up old settings from the current ones, eg. from previous add-on
	-- versions which might have disappeared, in order to avoid clutter. Keep
	-- only those entries which exist in this version's defaults.
	for key, value in pairs(ns.settings) do
		if (ns.defaultSettings[key] == nil) then
			ns.settings[key] = nil;
			if (MRBP_PerCharSettings[key] ~= nil) then
				MRBP_PerCharSettings[key] = nil;
			end
			_log:debug("Removed old setting:", key);
		end
	end

	-- Prepare account-wide (global) settings (currently unused)
	if (MRBP_GlobalSettings ~= nil) then
		-- Empty old values for next phase: settings profiles
		MRBP_GlobalSettings = nil;
	-- else
	-- 	MRBP_GlobalSettings = {};
	-- 	_log:debug(".. initializing account-wide (global) settings");
	end

	_log:info("Settings are up-to-date.");

	_log.level = verbose and prev_loglvl or _log.level;
end

---Save a given value for a given variable name.
---@param varName (string)  The name of the variable
---@param value (boolean|table)  The new value of the given variable
---
local function SaveSingleSetting(varName, value)
	-- Save project-wide (namespace) settings
	ns.settings[varName] = value;

	-- Save character-specific settings
	if (ns.defaultSettings[varName] ~= value) then
		MRBP_PerCharSettings[varName] = value;
	else
		-- Don't keep duplicate (to defaults) entries
		MRBP_PerCharSettings[varName] = nil;
	end
end

---Print a user-friendly chat message about the currently selected setting.
---@param text (string)  The name of a given option
---@param isEnabled (boolean|table)  The value of given option
---
local function printOption(text, isEnabled)
	local msg = isEnabled and VIDEO_OPTIONS_ENABLED or VIDEO_OPTIONS_DISABLED;  --> WoW global strings
	ns.cprint(text, "-", NORMAL_FONT_COLOR:WrapTextInColorCode(msg));
end

----- Control utilities --------------------------------------------------------

---Handle the value of given setting control.
---@param owner (table)  The owner of given control (ignorable)
---@param setting (table)  The given setting control
---@param value (boolean|table)  The value of the given control
---
local function CheckBox_OnValueChanged(owner, setting, value)
	if (setting.variable == "showChatNotifications") then
		if not value then
			printOption(setting.name, value);
			_log.level = _log.NOTSET;  --> silent
		else
			_log.level = _log.USER;  --> verbose
			printOption(setting.name, value);
		end
	elseif ns.settings.showChatNotifications then
		-- Print user feedback on selected setting to chat
		printOption(setting.name, value);
	end
	if (setting.variable == "showMinimapButton") then  --> temporary solution for beta2
		-- Manually set by user
		local shouldShowMinimapButton = value;
		if shouldShowMinimapButton then
			ns:ShowMinimapButton_User()
		else
			ns:HideMinimapButton();
		end
	end
	-- Handle "activeMenuEntries"
	local varName, indexString = strsplit('#', setting.variable);
	if indexString then
		local activeEntriesList = ns.settings.activeMenuEntries;
		local exists = tContains(activeEntriesList, indexString);
		if (value == true and not exists) then
			tinsert(activeEntriesList, indexString);
		end
		if (value == false and exists) then
			for i, iStr in ipairs(activeEntriesList) do
				if (iStr == indexString) then
					tremove(activeEntriesList, i);
				end
			end
		end
		value = CopyTable(activeEntriesList);

		_log:debug("selectedMenuEntries:", SafeUnpack(ns.settings.activeMenuEntries));
	end

	SaveSingleSetting(varName, value);
end

---Intercept the value of the dropdown menu entry (expansions) items to block the last entry from being disabled.
---The dropdown menu **needs** at least one entry in order to appear. 
---@param value (boolean)  The clicked value
---@return boolean
---
local function Checkbox_OnInterceptActiveMenuEntries(value)
	-- REF.: <FrameXML/Settings/Blizzard_SettingControls.lua>
	--> Note: This function must return a boolean value; a nil value is NOT allowed!
	if (value == false and #ns.settings.activeMenuEntries == 1) then
		-- Without any menu items the dropdown menu won't show up, so inform user
		local warningText = L.CFG_DDMENU_ENTRYSELECTION_TEXT_WARNING;
		ns.cprint(ERROR_COLOR:WrapTextInColorCode(warningText));  --> WoW global color
		if UIErrorsFrame then
			UIErrorsFrame:AddExternalErrorMessage(warningText);
			-- UIErrorsFrame:AddMessage(warningText, ERROR_COLOR:GetRGBA());
		end
		return true;
	end
	return false;
end

---Create a checkbox control and register it's setting and add it to the given category.
---@param category (table)  Add and register checkbox to this category.
---@param variableName (string)  The name of this checkbox' variable.
---@param name (string)  Label text of this checkbox.
---@param tooltip (string|nil)  Tooltip text for this checkbox. (Nilable)
---@return table setting  The registered setting
---@return table initializer The checkbox control
---
local function CheckBox_Create(category, variableName, name, tooltip)
	-- Prepare values
	local defaultValue = ns.settings[variableName];
	--> Note: This works only with the currently set value; defaultValue is set below.
	local varName, indexString = strsplit('#', variableName);
	local defaultMenuEntryValue = false;
	if indexString then
		local exists = tContains(ns.settings[varName], indexString);
		defaultMenuEntryValue = tContains(ns.defaultSettings[varName], indexString);
		defaultValue = exists;
		varName = variableName;
	end
	-- Create checkbox
	local setting = Settings.RegisterAddOnSetting(category, name, varName, Settings.VarType.Boolean, defaultValue);
	local initializer = Settings.CreateCheckBox(category, setting, tooltip);
	-- setting:SetCommitFlags(Settings.CommitFlag.Apply, Settings.CommitFlag.Revertable);
	-- Handling "activeMenuEntries" vs. normal checkboxes
	if indexString then
		setting.defaultValue = defaultMenuEntryValue;
		initializer:SetSettingIntercept(Checkbox_OnInterceptActiveMenuEntries);
	else
		setting.defaultValue = ns.defaultSettings[varName];
	end
	-- Work-around until I find a better solution
	setting.initializer = initializer;
	-- Keep track of value changes
	local cbrHandle = Settings.SetOnValueChangedCallback(varName, CheckBox_OnValueChanged, setting);
	--> Note: Handle is needed to unregister this OnValueChanged event, if necessary.

	return setting, initializer;
end

---Create multiple checkboxes from a list of data.
---@param category (table)  The destination category.
---@param checkBoxList (table)  The list of data for each checkbox.
---
local function CheckBox_CreateFromList(category, checkBoxList)
	-- Create checkboxes
	local data = {};
	for i, cb in ipairs(checkBoxList) do
		local setting, initializer = CheckBox_Create(category, cb.variable, cb.name, cb.tooltip);
		if cb.tag then
			-- initializer:SetNewTagShown(Settings.Default.True);
			setting:SetNewTagShown(Settings.Default.True);
		end
		if cb.parentVariable then
			setting.parentVariable = cb.parentVariable;
		end
		if cb.modifyPredicate then
			initializer:AddModifyPredicate(cb.modifyPredicate);
		end
		data[setting] = initializer;
	end
	-- Set dependencies for each checkbox after (!) it has been created
	for setting, initializer in pairs(data) do
		local hasParentInitializer = setting.parentVariable ~= nil;
		if hasParentInitializer then
			local parentSetting = Settings.GetSetting(setting.parentVariable);
			local function IsModifiable()
				return parentSetting:GetValue();
			end
			initializer:SetParentInitializer(parentSetting.initializer, IsModifiable);
		end
	end
end

--------------------------------------------------------------------------------
----- Settings panel -----------------------------------------------------------
--------------------------------------------------------------------------------
-- REF.: <FrameXML/Settings/Blizzard_Deprecated.lua>
-- REF.: <FrameXML/Settings/Blizzard_ImplementationReadme.lua>
-- REF.: <FrameXML/Settings/Blizzard_SettingsPanel.lua>
-- REF.: <FrameXML/Settings/Blizzard_SettingControls.lua>
-- REF.: <FrameXML/Settings/Blizzard_Settings.lua>
-- REF.: <FrameXML/Settings/Blizzard_Setting.lua>

---Open the settings panel to the given category.
---@param categoryIDOrFrame (string|number|table)  The category identifier
---@return boolean result  ???
---
function MRBP_Settings_OpenToCategory(categoryIDOrFrame)
	if type(categoryIDOrFrame) == "table" then
		local categoryID = categoryIDOrFrame.name;
		return Settings.OpenToCategory(categoryID);
	else
		return Settings.OpenToCategory(categoryIDOrFrame);
	end
end

---Register this addon's settings to the new (WoW 10.x) settings UI.
---
function MRBP_Settings_Register()
	local category, layout = Settings.RegisterVerticalLayoutCategory(AddonID);
	category.ID = AddonID;
	Settings.RegisterAddOnCategory(category);

	LoadSettings();
	--> TODO - Check need for 'ns.settings'; is maybe .GetVariableValue() better?

	------- General settings ---------------------------------------------------

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(GENERAL_SUBHEADER));  --> WoW global string

	local checkBoxList_CommonSettings = {
		{
			variable = "showChatNotifications",
			name = L.CFG_CHAT_NOTIFY_TEXT,
			tooltip = L.CFG_CHAT_NOTIFY_TOOLTIP,
		},
		{
			variable = "showMinimapButton",
			name = strjoin(" ", L.CFG_MINIMAPBUTTON_SHOWBUTTON_TEXT, GRAY_FONT_COLOR:WrapTextInColorCode(L.WORK_IS_EXPERIMENTAL)),
			tooltip = strjoin("|n|n", L.CFG_MINIMAPBUTTON_SHOWBUTTON_TOOLTIP, L.WORK_IS_EXPERIMENTAL_TOOLTIP_ADDITION),
			modifyPredicate = function()
				local result =  ns.MRBP_IsAnyGarrisonRequirementMet();
				if not result then
					-- Inform user about the reason
					printOption(L.CFG_MINIMAPBUTTON_SHOWBUTTON_TEXT, result);
					ns.cprint(L.CHATMSG_UNLOCKED_COMMANDTABLES_REQUIRED);
				end
				return result;
			end
		},
		{
			variable = "showAddonNameInTooltip",
			name = L.CFG_MINIMAPBUTTON_SHOWNAMEINTOOLTIP_TEXT,
			tooltip = L.CFG_MINIMAPBUTTON_SHOWNAMEINTOOLTIP_TOOLTIP,
			parentVariable = "showMinimapButton",
		},
	};

	CheckBox_CreateFromList(category, checkBoxList_CommonSettings);

	------- Dropdown menu settings ---------------------------------------------

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.CFG_DDMENU_SEPARATOR_HEADING));

	local checkBoxList_DropDownMenuSettings = {
		{
			variable = "showEntryTooltip",
			name = L.CFG_DDMENU_ENTRYTOOLTIP_SHOW_TEXT,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_SHOW_TOOLTIP,
		},
		{
			variable = "preferExpansionName",
			name = L.CFG_DDMENU_NAMING_TEXT,
			tooltip = L.CFG_DDMENU_NAMING_TOOLTIP,
		},
		{
			variable = "reverseSortorder",
			name = L.CFG_DDMENU_SORTORDER_TEXT,
			tooltip = L.CFG_DDMENU_SORTORDER_TOOLTIP,
		},
		{
			variable = "showMissionTypeIcons",
			name = L.CFG_DDMENU_REPORTICONS_TEXT,
			tooltip = L.CFG_DDMENU_REPORTICONS_TOOLTIP,
		},
		{
			variable = "showMissionCompletedHint",
			name = L.CFG_DDMENU_ICONHINT_TEXT,
			tooltip = L.CFG_DDMENU_ICONHINT_TOOLTIP,
		},
		{
			variable = "showMissionCompletedHintOnlyForAll",
			name = L.CFG_DDMENU_ICONHINTALL_TEXT,
			tooltip = L.CFG_DDMENU_ICONHINTALL_TOOLTIP,
			parentVariable = "showMissionCompletedHint",
		},
	};

	CheckBox_CreateFromList(category, checkBoxList_DropDownMenuSettings);

	------- Menu style selection -----------------------------------------------

	local styleMenu = {
		name = L.CFG_DDMENU_STYLESELECTION_LABEL,
		tooltip =   L.CFG_DDMENU_STYLESELECTION_TOOLTIP,
		variable = "menuStyleID",
		defaultValue = ns.settings.menuStyleID,
	};
	function styleMenu.GetOptions()
		local container = Settings.CreateControlTextContainer();
		local optionText1 = L.CFG_DDMENU_STYLESELECTION_VALUE1_TEXT..GRAY_FONT_COLOR:WrapTextInColorCode(" ("..DEFAULT..")");  --> WoW global string
		local optionText2 = L.CFG_DDMENU_STYLESELECTION_VALUE2_TEXT;
		container:Add("1", optionText1, L.CFG_DDMENU_STYLESELECTION_VALUE1_TOOLTIP);
		container:Add("2", optionText2, L.CFG_DDMENU_STYLESELECTION_VALUE2_TOOLTIP);
		return container:GetData();
	end
	function styleMenu.OnValueChanged(owner, setting, value)
		SaveSingleSetting("menuStyleID", value);
		ns.MRBP_ReloadDropdown();
		_log:debug("Menu style ID selected:", value);
		if ns.settings.showChatNotifications then
			local data = styleMenu.GetOptions();
			for i, option in ipairs(data) do
				if (value == option.value) then
					printOption(format("%s - %s", setting.name, option.label), Settings.Default.True);
					--> always true for each selected style
				end
			end
		end
	end
	-- REF.: Settings.RegisterAddOnSetting(categoryTbl, name, variable, variableType, defaultValue)
	-- REF.: Settings.CreateDropDown(categoryTbl, setting, options, tooltip)
	local styleMenuSetting = Settings.RegisterAddOnSetting(category, styleMenu.name, styleMenu.variable, Settings.VarType.String, styleMenu.defaultValue);
	local styleMenuInitializer = Settings.CreateDropDown(category, styleMenuSetting, styleMenu.GetOptions, styleMenu.tooltip);
	-- styleMenuSetting:SetCommitFlags(Settings.CommitFlag.Apply, Settings.CommitFlag.Revertable);
	-- Keep track of value changes
	Settings.SetOnValueChangedCallback(styleMenu.variable, styleMenu.OnValueChanged, styleMenuSetting);

	------- Menu entries selection ---------------------------------------------

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.CFG_DDMENU_ENTRYSELECTION_LABEL));

	local menuEntries = {};
	menuEntries.expansionList = util.expansion.GetExpansionsWithLandingPage();
	menuEntries.settingsCB = {  --> Additional "Settings" menu entry
		ID = 99,
		name = "[ "..SETTINGS.." ]"  --> WoW global string
	};
	tinsert(menuEntries.expansionList, menuEntries.settingsCB);
	ns.settingsMenuEntry = tostring(menuEntries.settingsCB.ID);

	local function getMenuEntryTooltip(expansionID, playerOwnsExpansion)
		local featuresString = '';
		local displayInfo = util.expansion.GetDisplayInfo(expansionID);
		if displayInfo then
			local expansion = util.expansion.GetExpansionData(expansionID);
			-- local playerOwnsExpansion = util.expansion.DoesPlayerOwnExpansion(expansionID);
			local _, width, height = util.GetAtlasInfo(displayInfo.banner);
			local bannerString = util.CreateInlineIcon(displayInfo.banner, width, height, 8, -16);
			featuresString = featuresString..bannerString.."|n";
			if not playerOwnsExpansion then
				featuresString = "|n"..ERROR_COLOR_CODE..featuresString..ERR_REQUIRES_EXPANSION_S:format(expansion.name)..FONT_COLOR_CODE_CLOSE.."|n|n";  --> WoW global string
			end
			featuresString = featuresString..HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(FEATURES_LABEL).."|n|n";  --> WoW global string
			for _, feature in ipairs(displayInfo.features) do
				local iconString = util.CreateInlineIcon(feature.icon);
				featuresString = featuresString..iconString.." "..feature.text.."|n";
			end
		end
		return featuresString;
	end

	-- Map names to settings
	menuEntries.checkBoxList_MenuEntriesSettings = {};

	for _, expansion in ipairs(menuEntries.expansionList) do
		local ownsExpansion = util.expansion.DoesPlayerOwnExpansion(expansion.ID);
		tinsert(menuEntries.checkBoxList_MenuEntriesSettings, {
				variable = "activeMenuEntries#"..tostring(expansion.ID),
				name = ownsExpansion and HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(expansion.name) or expansion.name,
				tooltip = ns.settingsMenuEntry ~= tostring(expansion.ID) and getMenuEntryTooltip(expansion.ID, ownsExpansion),
				-- tag = expansion.ID == util.expansion.data.Dragonflight.ID and Settings.Default.True or nil,
				modifyPredicate = function() return ownsExpansion end;
				-- modifyPredicate = function()
				-- 	return util.expansion.DoesPlayerOwnExpansion(expansion.ID);
				-- 	name = HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(expansion.name),
				-- end
			}
		);
	end

	CheckBox_CreateFromList(category, menuEntries.checkBoxList_MenuEntriesSettings);

	-- Add un-/check all buttons
	local function OnButtonClick(value)
		-- De-/Select all expansion entries
		for _, expansion in ipairs(menuEntries.expansionList) do
			local varName = "activeMenuEntries#"..tostring(expansion.ID);
			local setting = Settings.GetSetting(varName);
			if (value == Settings.Default.False and ns.settingsMenuEntry == tostring(expansion.ID)) then
				setting:SetValue(Settings.Default.True);
			else
				setting:SetValue(value);
			end
		end
	end
	local function OnCheckAll()
		OnButtonClick(Settings.Default.True);
	end
	local function OnUncheckAll()
		OnButtonClick(Settings.Default.False);
	end
	local checkAllInitializer = CreateSettingsButtonInitializer('', CHECK_ALL, OnCheckAll);  --> WoW global string
	layout:AddInitializer(checkAllInitializer);
	local unCheckAllInitializer = CreateSettingsButtonInitializer('', UNCHECK_ALL, OnUncheckAll);  --> WoW global string
	layout:AddInitializer(unCheckAllInitializer);

	------- Menu entries tooltip settings --------------------------------------

	local function ShouldShowEntryTooltip()
		return ns.settings.showEntryTooltip;
	end

	local entryTooltipSubcategoryLabel = GRAY_FONT_COLOR:WrapTextInColorCode(L.CFG_DDMENU_ENTRYTOOLTIP_LABEL..HEADER_COLON.." ");

	-- layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.CFG_DDMENU_ENTRYTOOLTIP_LABEL));

	-- local checkBoxList_EntryTooltipSettings = {
	-- 	-- {
	-- 	-- 	variable = "showMissionCountInTooltip",
	-- 	-- 	name = L.CFG_DDMENU_ENTRYTOOLTIP_INPROGRESS_TEXT,
	-- 	-- 	tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_INPROGRESS_TOOLTIP,
	-- 	-- 	modifyPredicate = ShouldShowEntryTooltip,
	-- 	-- },
	-- 	-- {
	-- 	-- 	variable = "showBountyRequirements",
	-- 	-- 	name = L.CFG_DDMENU_ENTRYTOOLTIP_BOUNTYREQUIREMENTS_TEXT,
	-- 	-- 	tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_BOUNTYREQUIREMENTS_TOOLTIP,
	-- 	-- 	modifyPredicate = ShouldShowEntryTooltip,
	-- 	-- },
	-- 	-- {
	-- 	-- 	variable = "showThreatsTimeRemaining",
	-- 	-- 	name = L.CFG_DDMENU_ENTRYTOOLTIP_THREATS_TIMELEFT_TEXT,
	-- 	-- 	tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_THREATS_TIMELEFT_TOOLTIP,
	-- 	-- 	modifyPredicate = ShouldShowEntryTooltip,
	-- 	-- },
	-- 	{
	-- 		variable = "showEntryRequirements",
	-- 		name = L.CFG_DDMENU_ENTRYTOOLTIP_SHOW_REQUIREMENT_TEXT,
	-- 		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_SHOW_REQUIREMENT_TOOLTIP,
	-- 		modifyPredicate = ShouldShowEntryTooltip,
	-- 	},
	-- };

	-- CheckBox_CreateFromList(category, checkBoxList_EntryTooltipSettings);

	------- Tooltip settings - Warlords of Draenor -----------------------------

	local expansionName_WarlordsOfDraenor = util.expansion.data.WarlordsOfDraenor.name;
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(entryTooltipSubcategoryLabel..expansionName_WarlordsOfDraenor));

	local checkBoxList_WoDEntryTooltipSettings = {
		{
			variable = "showWoDMissionInfo",
			name = ns.label.showWoDMissionInfo,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MISSION_INFO_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showWoDGarrisonInvasionAlert",
			name = ns.label.showWoDGarrisonInvasionAlert,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_GARRISON_INVASION_ALERT_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showWoDWorldMapEvents",
			name = ns.label.showWoDWorldMapEvents,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_WORLD_MAP_EVENTS_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showWoDTimewalkingVendor",
			name = ns.label.showWoDTimewalkingVendor,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_TIMEWALKING_VENDOR_TOOLTIP,
			parentVariable = "showWoDWorldMapEvents",
			modifyPredicate = ShouldShowEntryTooltip,
		},
	};

	CheckBox_CreateFromList(category, checkBoxList_WoDEntryTooltipSettings);

	------- Tooltip settings - Legion ------------------------------------------

	local expansionName_Legion = util.expansion.data.Legion.name;
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(entryTooltipSubcategoryLabel..expansionName_Legion));

	local checkBoxList_LegionEntryTooltipSettings = {
		{
			variable = "showLegionMissionInfo",
			name = ns.label.showLegionMissionInfo,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MISSION_INFO_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showLegionBounties",
			name = ns.label.showLegionBounties,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_LEGION_BOUNTIES_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showLegionWorldMapEvents",
			name = ns.label.showLegionWorldMapEvents,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_WORLD_MAP_EVENTS_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showLegionAssaultsInfo",
			name = ns.label.showLegionAssaultsInfo,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_LEGION_INVASION),
			parentVariable = "showLegionWorldMapEvents",
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showBrokenShoreInvasionInfo",
			name = ns.label.showBrokenShoreInvasionInfo,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_DEMON_INVASION),
			parentVariable = "showLegionWorldMapEvents",
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showArgusInvasionInfo",
			name = ns.label.showArgusInvasionInfo,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_ARGUS_INVASION),
			parentVariable = "showLegionWorldMapEvents",
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "applyInvasionColors",
			name = ns.label.applyInvasionColors,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_LEGION_INVASION_COLORS_TOOLTIP,
			parentVariable = "showLegionWorldMapEvents",
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showLegionTimewalkingVendor",
			name = ns.label.showLegionTimewalkingVendor,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_TIMEWALKING_VENDOR_TOOLTIP,
			parentVariable = "showLegionWorldMapEvents",
			modifyPredicate = ShouldShowEntryTooltip,
		},
	};

	CheckBox_CreateFromList(category, checkBoxList_LegionEntryTooltipSettings);

	------- Tooltip settings - Battle for Azeroth ------------------------------

	local expansionName_BattleForAzeroth = util.expansion.data.BattleForAzeroth.name;
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(entryTooltipSubcategoryLabel..expansionName_BattleForAzeroth));

	local checkBoxList_BfAEntryTooltipSettings = {
		{
			variable = "showBfAMissionInfo",
			name = ns.label.showBfAMissionInfo,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MISSION_INFO_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showBfABounties",
			name = ns.label.showBfABounties,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_BFA_BOUNTIES_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showNzothThreats",
			name = ns.label.showNzothThreats,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_NZOTH_THREATS_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showBfAWorldMapEvents",
			name = ns.label.showBfAWorldMapEvents,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_WORLD_MAP_EVENTS_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showBfAFactionAssaultsInfo",
			name = ns.label.showBfAFactionAssaultsInfo,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_BFA_FACTION_ASSAULTS),
			parentVariable = "showBfAWorldMapEvents",
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "applyBfAFactionColors",
			name = ns.label.applyBfAFactionColors,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_FACTION_COLORS_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showBfAIslandExpeditionsInfo",
			name = ns.label.showBfAIslandExpeditionsInfo,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_BFA_ISLAND_EXPEDITIONS_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
			-- tag = Settings.Default.True,
		},
	};

	CheckBox_CreateFromList(category, checkBoxList_BfAEntryTooltipSettings);

	------- Tooltip settings - Shadowlands -------------------------------------

	local expansionName_Shadowlands = util.expansion.data.Shadowlands.name;
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(entryTooltipSubcategoryLabel..expansionName_Shadowlands));

	local checkBoxList_SLEntryTooltipSettings = {
		{
			variable = "showCovenantMissionInfo",
			name = ns.label.showCovenantMissionInfo,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MISSION_INFO_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showCovenantBounties",
			name = ns.label.showCovenantBounties,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_COVENANT_BOUNTIES_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showMawThreats",
			name = ns.label.showMawThreats,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MAW_THREATS_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showCovenantRenownLevel",
			name = ns.label.showCovenantRenownLevel,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_COVENANT_RENOWN_TOOLTIP,
		},
		{
			variable = "applyCovenantColors",
			name = ns.label.applyCovenantColors,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_FACTION_COLORS_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
	};

	CheckBox_CreateFromList(category, checkBoxList_SLEntryTooltipSettings);

	------- Tooltip settings - Dragonflight ------------------------------------

	local dfName = util.expansion.data.Dragonflight.name;
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(entryTooltipSubcategoryLabel..dfName));

	local checkBoxList_dfEntryTooltipSettings = {
		{
			variable = "showMajorFactionRenownLevel",
			name = ns.label.showMajorFactionRenownLevel,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MAJOR_FACTION_RENOWN_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "applyMajorFactionColors",
			name = ns.label.applyMajorFactionColors,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_FACTION_COLORS_TOOLTIP,
			parentVariable = "showMajorFactionRenownLevel",
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "hideMajorFactionUnlockDescription",
			name = ns.label.hideMajorFactionUnlockDescription,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MAJOR_FACTION_UNLOCK_TOOLTIP,
			parentVariable = "showMajorFactionRenownLevel",
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showDragonGlyphs",
			name = ns.label.showDragonGlyphs,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_DRAGON_GLYPHS_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "autoHideCompletedDragonGlyphZones",
			name = ns.label.autoHideCompletedDragonGlyphZones,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_HIDE_DRAGON_GLYPHS_TOOLTIP,
			parentVariable = "showDragonGlyphs",
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showDragonflightWorldMapEvents",
			name = ns.label.showDragonflightWorldMapEvents,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_WORLD_MAP_EVENTS_TOOLTIP,
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showDragonridingRaceInfo",
			name = ns.label.showDragonridingRaceInfo,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_DRAGONRIDING_RACE),
			parentVariable = "showDragonflightWorldMapEvents",
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showCampAylaagInfo",
			name = ns.label.showCampAylaagInfo,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_CAMP_AYLAAG),
			parentVariable = "showDragonflightWorldMapEvents",
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showGrandHuntsInfo",
			name = ns.label.showGrandHuntsInfo,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_GRAND_HUNTS),
			parentVariable = "showDragonflightWorldMapEvents",
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showCommunityFeastInfo",
			name = ns.label.showCommunityFeastInfo,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_ISKAARA_FEAST),
			parentVariable = "showDragonflightWorldMapEvents",
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showDragonbaneKeepInfo",
			name = ns.label.showDragonbaneKeepInfo,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_DRAGONBANE_KEEP),
			parentVariable = "showDragonflightWorldMapEvents",
			modifyPredicate = ShouldShowEntryTooltip,
		},
		{
			variable = "showElementalStormsInfo",
			name = ns.label.showElementalStormsInfo,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_ELEMENTAL_STORMS),
			parentVariable = "showDragonflightWorldMapEvents",
			modifyPredicate = ShouldShowEntryTooltip,
		},
	};

	CheckBox_CreateFromList(category, checkBoxList_dfEntryTooltipSettings);

	----------------------------------------------------------------------------
	------- About this addon ---------------------------------------------------
	----------------------------------------------------------------------------

	local aboutFrame = CreateFrame("Frame", AddonID.."AboutFrame");
	aboutFrame.name = aboutFrame:GetName();
	aboutFrame.OnCommit = function (self)
		-- Required function; even if empty
	end
	aboutFrame.OnDefault = function (self)
		-- Required function; even if empty
	end
	aboutFrame.OnRefresh  = function (self)
		-- Required function; even if empty
	end

	local subcategory, sublayout = Settings.RegisterCanvasLayoutSubcategory(category, aboutFrame, L.CFG_ABOUT_ADDON_LABEL);
	subcategory.ID = aboutFrame.name;
	sublayout:AddAnchorPoint("TOPLEFT", 10, -10);
	sublayout:AddAnchorPoint("BOTTOMRIGHT", -10, 10);

	------- Add-on infos -------------------------------------------------------

	local _, addonTitle, addonNotes = GetAddOnInfo(AddonID);

	local aboutSectionHeader = aboutFrame:CreateFontString(aboutFrame:GetName().."AboutSectionHeader", "OVERLAY", "GameFontHighlightLarge");
	aboutSectionHeader:SetJustifyH("LEFT");
	aboutSectionHeader:SetJustifyV("TOP");
	aboutSectionHeader:SetHeight(45);
	aboutSectionHeader:SetPoint("TOPLEFT", 7, -16);
	aboutSectionHeader:SetText(L.CFG_ABOUT_ADDON_LABEL);

	local mainTitle = aboutFrame:CreateFontString(aboutFrame:GetName().."Title", "OVERLAY", "GameFontNormalLarge");
	mainTitle:SetJustifyH("LEFT");
	mainTitle:SetJustifyV("TOP");
	mainTitle:SetPoint("TOPLEFT", aboutSectionHeader, "BOTTOMLEFT", 21, 0);
	mainTitle:SetText(addonTitle);

	local mainSubText = aboutFrame:CreateFontString(aboutFrame:GetName().."SubText", "OVERLAY", "GameFontHighlightSmall");
	mainSubText:SetJustifyH("LEFT");
	mainSubText:SetJustifyV("TOP");
	mainSubText:SetHeight(22);
	mainSubText:SetNonSpaceWrap(true);
	mainSubText:SetMaxLines(2);
	mainSubText:SetPoint("TOPLEFT", mainTitle, "BOTTOMLEFT", 0, -8);
	mainSubText:SetPoint("RIGHT", -32, 0);
	mainSubText:SetText(string.gsub(addonNotes, "[|\\]n", " "));  --> replace newline breaks with space

	-- Show user some infos about this add-on.
	local addonInfos = {
		--> label, tag
		{L.CFG_ADDONINFOS_VERSION, "Version"},
		{L.CFG_ADDONINFOS_AUTHOR, "Author"},
		-- {L.CFG_ADDONINFOS_EMAIL, "X-Email"},
		{L.CFG_ADDONINFOS_HOMEPAGE, "X-Project-Homepage"},
		{L.CFG_ADDONINFOS_LICENSE, "X-License"},
	};
	local parentFrame = mainSubText;
	local labelText, infoLabel;

	for _, infos in ipairs(addonInfos) do
		labelText, infoLabel = infos[1], infos[2];
		local metaLabel = aboutFrame:CreateFontString(aboutFrame:GetName().."MetaLabel"..infoLabel, "ARTWORK", "GameFontNormalSmall");
		metaLabel:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 0, -8);
		metaLabel:SetWidth(100);
		metaLabel:SetJustifyH("RIGHT");
		metaLabel:SetText(labelText..HEADER_COLON);  --> WoW global string

		local metaValue = aboutFrame:CreateFontString(aboutFrame:GetName().."MetaValue"..infoLabel, "ARTWORK", "GameFontHighlightSmall");
		metaValue:SetPoint("LEFT", metaLabel, "RIGHT", 4, 0);
		metaValue:SetJustifyH("LEFT");
		if ( strlower(infoLabel) == "author" ) then
			-- Append author's email address behind name
			local authorName, authorMail = ns.GetAddOnMetadata(AddonID, infoLabel), ns.GetAddOnMetadata(AddonID, "X-Email");
			metaValue:SetText(string.format("%s <%s>", authorName, authorMail));
		else
			metaValue:SetText(ns.GetAddOnMetadata(AddonID, infoLabel));
		end
		--> TODO - Make email and website links clickable.
		-- TALENT_FRAME_DROP_DOWN_EXPORT = "Teilen |cnLIGHTGRAY_FONT_COLOR:(in Zwischenablage kopieren)|r";

		parentFrame = metaLabel;
	end

	------- Slash Commands -----------------------------------------------------

	local separatorTexture = aboutFrame:CreateTexture(aboutFrame:GetName().."Separator", "ARTWORK");
	separatorTexture:SetSize(575, 1);
	separatorTexture:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 0, -32);
	separatorTexture:SetColorTexture(0.25, 0.25, 0.25);  -- gray

	local slashCmdSectionHeader = aboutFrame:CreateFontString(aboutFrame:GetName().."SlashCmdSectionHeader", "OVERLAY", "GameFontHighlightLarge");
	slashCmdSectionHeader:SetJustifyH("LEFT");
	slashCmdSectionHeader:SetJustifyV("TOP");
	slashCmdSectionHeader:SetHeight(45);
	slashCmdSectionHeader:SetPoint("TOPLEFT", separatorTexture, "BOTTOMLEFT", -21, -30);
	slashCmdSectionHeader:SetText(L.CFG_ABOUT_SLASHCMD_LABEL);

	local slashParent = slashCmdSectionHeader;

	for _, slashCmdInfo in pairs(ns.SLASH_CMD_ARGLIST) do
		local slashCmdText, helpText = slashCmdInfo[1], slashCmdInfo[2];

		local slashCmdLabel = aboutFrame:CreateFontString(aboutFrame:GetName()..strupper(slashCmdText).."SlashCmd", "ARTWORK", "GameFontNormal");
		if (slashParent == slashCmdSectionHeader) then
			slashCmdLabel:SetPoint("TOPLEFT", slashParent, "BOTTOMLEFT", 21, -4);
		else
			slashCmdLabel:SetPoint("TOPLEFT", slashParent, "BOTTOMLEFT", 0, -8);
		end
		slashCmdLabel:SetWidth(100);
		slashCmdLabel:SetJustifyH("RIGHT");
		slashCmdLabel:SetText(slashCmdText..HEADER_COLON);  --> WoW global string

		local slashCmdHelpLabel = aboutFrame:CreateFontString(aboutFrame:GetName()..strupper(slashCmdText).."Description", "ARTWORK", "GameFontHighlight");
		slashCmdHelpLabel:SetPoint("LEFT", slashCmdLabel, "RIGHT", 4, 0);
		slashCmdHelpLabel:SetText(helpText);

		slashParent = slashCmdLabel;
	end

	---- Tests ----

	-- layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Tests"));

	-- local testList = settingSMB.initializer;
	-- for k,v in pairs(testList) do
	-- 	print(k, "-->", v);
	-- end

	-- About button

	-- local sep = layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.CFG_ABOUT_ADDON_LABEL));

	-- -- local warnVar = "warnVar";
	-- -- local warnSetting = Settings.RegisterAddOnSetting(category, "Warn message", warnVar, Settings.VarType.Boolean, true);
	-- -- local warnData = Settings.CreateSettingInitializerData(warnSetting, nil, "Warning message tooltip.");
	-- -- warnData.name = "Warning message"
	-- -- local warnInitializer = Settings.CreateSettingInitializer("TwitterPanelTemplate", warnData);
	-- -- layout:AddInitializer(warnInitializer);

	-- local function OnButtonClick()
	-- 	-- MRBP_Settings_OpenToCategory(aboutFrame);
	-- 	MRBP_Settings_OpenToCategory(AddonID.."AboutFrame");
	-- 	print("Go to", AddonID.."AboutFrame");
	-- end
	-- local infoButtonInitializer = CreateSettingsButtonInitializer("Add-on Infos", "Anzeigen", OnButtonClick, "Infos zu diesem Add-on anzeigen.");
	-- layout:AddInitializer(infoButtonInitializer);
end
