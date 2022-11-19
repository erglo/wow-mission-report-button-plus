--------------------------------------------------------------------------------
--[[ Mission Report Button Plus - Interface Options (Settings) ]]--
--
-- by erglo <erglo.coder+MRBP@gmail.com>
--
-- Copyright (C) 2022  Erwin D. Glockner (aka ergloCoder)
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
--
--------------------------------------------------------------------------------

local AddonID, ns = ...;
local L = ns.L;
local _log = ns.dbg_logger;
local util = ns.utilities;

----- User settings ------------------------------------------------------------

ns.settings = {};  --> user settings for currently active game session
ns.defaultSettings = {  --> default + fallback settings
	["showChatNotifications"] = true,
	["showMinimapButton"] = true,
	["showAddonNameInTooltip"] = true,
	["preferExpansionName"] = true,
	["reverseSortorder"] = false,
	["showMissionTypeIcons"] = true,
	["showMissionCompletedHint"] = true,
	["showMissionCompletedHintOnlyForAll"] = false,
	["showEntryTooltip"] = true,
	["showMissionCountInTooltip"] = true,
	["showWorldmapBounties"] = true,
	["showBountyRequirements"] = true,
	["showWorldmapThreats"] = true,
	["showEntryRequirements"] = true,
	["activeMenuEntries"] = {"5", "6", "7", "8", "9"},
	["menuStyleID"] = "1",
	["disableShowMinimapButtonSetting"] = false,   --> temp. solution for beta2
};

---Loads the saved variables for the current game character.
---**Note:** Always use `ns.settings` in this project. It holds ALL setting infos after loading,
---not so the saved variables. Variable names might also change after a while.
---
---REF.: <FrameXML/TableUtil.lua>
---
---@param verbose (boolean)  If true, prints debug messages to chat
---
local function LoadSettings(verbose)
	local prev_loglvl = _log.level;
	_log.level = verbose and _log.DEBUG or _log.level;

	_log:info("Loading settings...");

	-- Load the default settings first and overwrite each changed value of the 
	-- current game session with those from the char-specific settings.
	ns.settings = CopyTable(ns.defaultSettings);
	_log:debug(format(".. defaults loaded: %d |4setting:settings; in total", util:tcount(ns.settings)));

	-- Prepare character-specific settings
	if (MRBP_PerCharSettings == nil) then 
		MRBP_PerCharSettings = {};
		_log:debug(".. initializing character-specific settings");
	end
	-- Update `ns.settings` with current char's values
	local numCharSettings = util:tcount(MRBP_PerCharSettings);
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
			-- ns:ShowMinimapButton_User(isCancelled);
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
local function Checkbox_OnIntercept(value)
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
	setting:SetCommitFlags(Settings.CommitFlag.Apply, Settings.CommitFlag.Revertable);
	-- Handling "activeMenuEntries" vs. normal checkboxes
	if indexString then
		setting.defaultValue = defaultMenuEntryValue;
		initializer:SetSettingIntercept(Checkbox_OnIntercept);
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
			initializer:SetNewTagShown(Settings.Default.True);
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

	-----[[ General settings ]]-------------------------------------------------

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
				local result =  ns.MRBP_IsAnyGarrisonRequirementMet(); -- and ns.settings["disableShowMinimapButtonSetting"];
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

	-----[[ Dropdown menu settings ]]-------------------------------------------

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.CFG_DDMENU_SEPARATOR_HEADING));

	local checkBoxList_DropDownMenuSettings = {
		{
			variable = "preferExpansionName",
			name = L.CFG_DDMENU_NAMING_TEXT,
			tooltip = L.CFG_DDMENU_NAMING_TOOLTIP,
			-- modifyPredicate = IsMinimapButtonShown,
		},
		{
			variable = "reverseSortorder",
			name = L.CFG_DDMENU_SORTORDER_TEXT,
			tooltip = L.CFG_DDMENU_SORTORDER_TOOLTIP,
			-- modifyPredicate = IsMinimapButtonShown,
		},
		{
			variable = "showMissionTypeIcons",
			name = L.CFG_DDMENU_REPORTICONS_TEXT,
			tooltip = L.CFG_DDMENU_REPORTICONS_TOOLTIP,
			-- modifyPredicate = IsMinimapButtonShown,
		},
		{
			variable = "showMissionCompletedHint",
			name = L.CFG_DDMENU_ICONHINT_TEXT,
			tooltip = L.CFG_DDMENU_ICONHINT_TOOLTIP,
			-- modifyPredicate = IsMinimapButtonShown,
		},
		{
			variable = "showMissionCompletedHintOnlyForAll",
			name = L.CFG_DDMENU_ICONHINTALL_TEXT,
			tooltip = L.CFG_DDMENU_ICONHINTALL_TOOLTIP,
			parentVariable = "showMissionCompletedHint",
			-- modifyPredicate = IsMinimapButtonShown,
		},
	};

	CheckBox_CreateFromList(category, checkBoxList_DropDownMenuSettings);

	-----[[ Menu style selection ]]---------------------------------------------

	local styleMenu = {
		name = L.CFG_DDMENU_STYLESELECTION_LABEL,
		tooltip =   L.CFG_DDMENU_STYLESELECTION_TOOLTIP,
		variable = "menuStyleID",
		-- defaultValue = ns.defaultSettings.menuStyleID,
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
	styleMenuSetting:SetCommitFlags(Settings.CommitFlag.Apply, Settings.CommitFlag.Revertable);
	-- Keep track of value changes
	Settings.SetOnValueChangedCallback(styleMenu.variable, styleMenu.OnValueChanged, styleMenuSetting);

	-----[[ Menu entries selection ]]-------------------------------------------

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.CFG_DDMENU_ENTRYSELECTION_LABEL));

	local menuEntries = {};
	menuEntries.expansionNameList = {
			  -- placeholder,   --> "Classic"
		nil,  -- placeholder1,  --> "The Burning Crusade"
		nil,  -- placeholder2,  --> "Wrath of the Lich King"
		nil,  -- placeholder3,  --> "Cataclysm"
		nil,  -- placeholder4,  --> "Mists of Pandaria"
		EXPANSION_NAME5,  --> "Warlords of Draenor"
		EXPANSION_NAME6,  --> "Legion"
		EXPANSION_NAME7,  --> "Battle for Azeroth"
		EXPANSION_NAME8,  --> "Shadowlands"
		-- EXPANSION_NAME9,  --> "Dragonflight"
		"[ "..SETTINGS.." ]",  --> Additional "Settings" menu entry; WoW global string
	};
	--> Do NOT remove the placeholders! The position (index) of each expansion
	--  name is equal to the expansion ID which is used in the core file. The
	--  "Settings" entry is the extra value (latest expansion ID + 1).
	ns.settingsMenuEntry = tostring(#menuEntries.expansionNameList);

	--> TODO - Add CB: Show only available expansions
	-- EXPANSION_FILTER_TEXT

	local function getMenuEntryTooltip(expansionID)
		local featuresString = '';
		local displayInfo = GetExpansionDisplayInfo(expansionID);
		if displayInfo then
			local expansionInfo = util:GetExpansionInfo(expansionID);
			local playerMaxLevelForExpansion = GetMaxLevelForPlayerExpansion();
			local playerOwnsExpansion = expansionInfo.maxLevel <= playerMaxLevelForExpansion  --> eligibility check
			local _, width, height = util:GetAtlasInfo(displayInfo.banner);
			local bannerString = util:CreateInlineIcon(displayInfo.banner, width, height, 8, -16);
			featuresString = featuresString..bannerString.."|n";
			if not playerOwnsExpansion then
				featuresString = "|n"..ERROR_COLOR_CODE..featuresString..ERR_REQUIRES_EXPANSION_S:format(expansionInfo.name)..FONT_COLOR_CODE_CLOSE.."|n|n";  --> WoW global string
			end
			featuresString = featuresString..HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(FEATURES_LABEL).."|n|n";  --> WoW global string
			for _, feature in ipairs(displayInfo.features) do
				local iconString = util:CreateInlineIcon(feature.icon);
				featuresString = featuresString..iconString.." "..feature.text.."|n";
			end
		end
		return featuresString;
	end

	-- Map names to settings
	menuEntries.checkBoxList_MenuEntriesSettings = {};
	for i, name in pairs(menuEntries.expansionNameList) do
		if name then  --> ignore placeholders
			tinsert(menuEntries.checkBoxList_MenuEntriesSettings, {
					variable = "activeMenuEntries#"..tostring(i),
					name = HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(name),
					tooltip = ns.settingsMenuEntry ~= tostring(i) and getMenuEntryTooltip(i),
				}
			);
		end
	end

	CheckBox_CreateFromList(category, menuEntries.checkBoxList_MenuEntriesSettings);

	-- Add un-/check all buttons
	local function OnButtonClick(value)
		-- De-/Select all expansion entries
		for i, name in pairs(menuEntries.expansionNameList) do
			local varName = "activeMenuEntries#"..tostring(i);
			local setting = Settings.GetSetting(varName);
			if (value == Settings.Default.False and ns.settingsMenuEntry == tostring(i)) then
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

	-----[[ Menu entries' (details) tooltip settings ]]-------------------------

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.CFG_DDMENU_ENTRYTOOLTIP_LABEL));

	local checkBoxList_EntryTooltipSettings = {
		{
			variable = "showEntryTooltip",
			name = L.CFG_DDMENU_ENTRYTOOLTIP_SHOW_TEXT,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_SHOW_TOOLTIP,
			-- modifyPredicate = IsMinimapButtonShown,
		},
		{
			variable = "showMissionCountInTooltip",
			name = L.CFG_DDMENU_ENTRYTOOLTIP_INPROGRESS_TEXT,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_INPROGRESS_TOOLTIP,
			-- modifyPredicate = IsEntryTooltipShown,
		},
		{
			variable = "showWorldmapBounties",
			name = L.CFG_DDMENU_ENTRYTOOLTIP_BOUNTIES_TEXT,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_BOUNTIES_TOOLTIP,
			-- modifyPredicate = IsEntryTooltipShown,
		},
		{
			variable = "showBountyRequirements",
			name = L.CFG_DDMENU_ENTRYTOOLTIP_BOUNTYREQUIREMENTS_TEXT,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_BOUNTYREQUIREMENTS_TOOLTIP,
			parentVariable = "showWorldmapBounties",
			-- modifyPredicate = IsEntryTooltipShown,
		},
		{
			variable = "showWorldmapThreats",
			name = L.CFG_DDMENU_ENTRYTOOLTIP_THREATS_TEXT,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_THREATS_TOOLTIP,
			-- modifyPredicate = IsEntryTooltipShown,
		},
		{
			variable = "showEntryRequirements",
			name = L.CFG_DDMENU_ENTRYTOOLTIP_SHOW_REQUIREMENT_TEXT,
			tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_SHOW_REQUIREMENT_TOOLTIP,
			-- modifyPredicate = IsEntryTooltipShown,
			tag = Settings.Default.True,
		},
	};

	CheckBox_CreateFromList(category, checkBoxList_EntryTooltipSettings);

	----------------------------------------------------------------------------
	-----[[ About this addon ]]-------------------------------------------------
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

	-----[[ Add-on infos ]]-----------------------------------------------------

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
		local metaLabel = aboutFrame:CreateFontString(aboutFrame:GetName()..infoLabel.."Label", "ARTWORK", "GameFontNormalSmall");
		metaLabel:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 0, -8);
		metaLabel:SetWidth(100);
		metaLabel:SetJustifyH("RIGHT");
		metaLabel:SetText(NORMAL_FONT_COLOR:WrapTextInColorCode(labelText..HEADER_COLON));  --> WoW global string

		local metaValue = aboutFrame:CreateFontString(aboutFrame:GetName()..infoLabel.."Value", "ARTWORK", "GameFontHighlightSmall");
		metaValue:SetPoint("LEFT", metaLabel, "RIGHT", 4, 0);
		metaValue:SetJustifyH("LEFT");
		if ( infoLabel == "Author" ) then
			-- Append author's email address behind name
			local authorName, authorMail = GetAddOnMetadata(AddonID, infoLabel), GetAddOnMetadata(AddonID, "X-Email");
			metaValue:SetText(string.format("%s <%s>", authorName, authorMail));
		else
			metaValue:SetText(GetAddOnMetadata(AddonID, infoLabel));
		end
		--> TODO - Make email and website links clickable.

		parentFrame = metaLabel;
	end

	-----[[ Slash Commands ]]---------------------------------------------------

	local slashCmdSectionHeader = aboutFrame:CreateFontString(aboutFrame:GetName().."SlashCmdSectionHeader", "OVERLAY", "GameFontHighlightLarge");
	slashCmdSectionHeader:SetJustifyH("LEFT");
	slashCmdSectionHeader:SetJustifyV("TOP");
	slashCmdSectionHeader:SetHeight(45);
	slashCmdSectionHeader:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", -21, -32);
	slashCmdSectionHeader:SetText(L.CFG_ABOUT_SLASHCMD_LABEL);

	local slashParent = slashCmdSectionHeader;

	for _, slashCmdInfo in pairs(ns.SLASH_CMD_ARGLIST) do
		slashCmdText, helpText = slashCmdInfo[1], slashCmdInfo[2];

		local slashCmdLabel = aboutFrame:CreateFontString(aboutFrame:GetName()..infoLabel.."SlashCmdLabel", "ARTWORK", "GameFontNormal");
		if (slashParent == slashCmdSectionHeader) then
			slashCmdLabel:SetPoint("TOPLEFT", slashParent, "BOTTOMLEFT", 21, -4);
		else
			slashCmdLabel:SetPoint("TOPLEFT", slashParent, "BOTTOMLEFT", 0, -8);
		end
		slashCmdLabel:SetWidth(100);
		slashCmdLabel:SetJustifyH("RIGHT");
		slashCmdLabel:SetText(slashCmdText..HEADER_COLON);  --> WoW global string

		local slashCmdHelpLabel = aboutFrame:CreateFontString(aboutFrame:GetName()..infoLabel.."Value", "ARTWORK", "GameFontNormal");
		slashCmdHelpLabel:SetPoint("LEFT", slashCmdLabel, "RIGHT", 4, 0);
		slashCmdHelpLabel:SetText(helpText);
		slashCmdHelpLabel:SetVertexColor(HIGHLIGHT_FONT_COLOR:GetRGBA());

		slashParent = slashCmdLabel;
	end

	--[[ Tests ]]--

	-- layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Tests"));

	-- local testList = category;
	-- for k,v in pairs(testList) do
	-- 	print(k, "-->", v);
	-- end

	-- -- About button

	-- local sep = layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.CFG_ABOUT_ADDON_LABEL));

	-- -- local warnVar = "warnVar";
	-- -- local warnSetting = Settings.RegisterAddOnSetting(category, "Warn message", warnVar, Settings.VarType.Boolean, true);
	-- -- local warnData = Settings.CreateSettingInitializerData(warnSetting, nil, "Warning message tooltip.");
	-- -- warnData.name = "Warning message"
	-- -- local warnInitializer = Settings.CreateSettingInitializer("TwitterPanelTemplate", warnData);
	-- -- layout:AddInitializer(warnInitializer);

	-- local mainSubText = aboutFrame:CreateFontString(aboutFrame:GetName().."SubText", "OVERLAY", "GameFontHighlightSmall");
	-- mainSubText:SetJustifyH("LEFT");
	-- mainSubText:SetJustifyV("TOP");
	-- mainSubText:SetHeight(22);
	-- mainSubText:SetNonSpaceWrap(true);
	-- mainSubText:SetMaxLines(2);
	-- mainSubText:SetPoint("TOPLEFT", mainTitle, "BOTTOMLEFT", 0, -8);
	-- mainSubText:SetPoint("RIGHT", -32, 0);
	-- mainSubText:SetText(string.gsub(addonNotes, "[|\\]n", " "));  --> replace newline break with space
	
	-- local function OnButtonClick()
	-- 	-- MRBP_Settings_OpenToCategory(aboutFrame);
	-- 	MRBP_Settings_OpenToCategory(AddonID.."AboutFrame");
	-- 	print("Go to", AddonID.."AboutFrame");
	-- end
	-- local infoButtonInitializer = CreateSettingsButtonInitializer("Add-on Infos", "Anzeigen", OnButtonClick, "Infos zu diesem Add-on anzeigen.");  --> TODO - L10n
	-- layout:AddInitializer(infoButtonInitializer);
end
