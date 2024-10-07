----------------------------------------------------------------------------
--[[ Mission Report Button Plus - Interface Option Settings ]]--
--
-- by erglo <erglo.coder+MRBP@gmail.com>
--
-- Copyright (C) 2021  Erwin D. Glockner (aka erglo or ergloCoder)
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
--
-- Files used for reference:
-- REF.: <FrameXML/InterfaceOptionsFrame.lua>	--> deprecated since WoW 10.x
-- REF.: <FrameXML/InterfaceOptionsPanels.lua>	--> deprecated since WoW 10.x
-- REF.: <FrameXML/OptionsPanelTemplates.lua>
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

local PlayerInfo = ns.PlayerInfo;  --> <data\player.lua>
local ExpansionInfo = ns.ExpansionInfo;  --> <data\expansion.lua>
local LocalFactionInfo = ns.FactionInfo;  --> <data\factions.lua>
local LocalRequirementInfo = ns.RequirementInfo;  --> <data\requirements.lua>

local _, addonTitle, addonNotes = C_AddOns.GetAddOnInfo(AddonID);
local version, build, date, tocVersion, localizedVersion, buildType = GetBuildInfo();

local SettingsPanel = SettingsPanel;

local sort = table.sort;
local strjoin = strjoin;
local tostring = tostring;
local NEWLINE = "|n";
local NEW_PARAGRAPH = "|n|n";
local HEADER_COLON = HEADER_COLON;
local LIST_DELIMITER = LIST_DELIMITER;
-- local TEXT_DASH_SEPARATOR = L.TEXT_DELIMITER..QUEST_DASH..L.TEXT_DELIMITER;
local DEFAULT = DEFAULT;
local REFORGE_CURRENT = REFORGE_CURRENT;
local FONT_SIZE = FONT_SIZE;
local FONT_SIZE_TEMPLATE = FONT_SIZE_TEMPLATE;

local GRAY = function(txt) return GRAY_FONT_COLOR:WrapTextInColorCode(txt) end;
local LIGHT_GRAY = function(txt) return LIGHTGRAY_FONT_COLOR:WrapTextInColorCode(txt) end;

----- User settings ------------------------------------------------------------

ns.settings = {};  --> user settings for currently active game session
ns.defaultSettings = {  --> default + fallback settings
	-- Common
	["showChatNotifications"] = true,
	["showMinimapButton"] = true,
	["showAddonNameInTooltip"] = true,
	["useMiddleButton"] = true,
	["useMouseOverMinimapMode"] = false,
	-- ["useSingleExpansionLandingPageType"] = true,
	["currentExpansionLandingPageType"] = {garrisonTypeID=Enum.GarrisonType.Type_9_0_Garrison, landingPageTypeID=Enum.ExpansionLandingPageType.None},
	["showInAddonCompartment"] = true,
	["showAchievementTracking"] = true,
	-- Dropdown menu
	["showEntryTooltip"] = true,
	["preferExpansionName"] = true,
	["reverseSortorder"] = false,
	["showLandingPageIcons"] = true,
	["showMissionCompletedHint"] = true,
	["showMissionCompletedHintOnlyForAll"] = false,
	["showReputationRewardPendingHint"] = true,
	["showTimewalkingVendorHint"] = true,
	["highlightCurrentZone"] = true,
	-- Menu entries
	["activeMenuEntries"] = {"5", "6", "7", "8", "9", "10", "99"},
	-- The War Within
	["showExpansion10"] = true,
	["showMajorFactionRenownLevel10"] = true,
	["applyMajorFactionColors10"] = true,
	["hideMajorFactionUnlockDescription10"] = false,
	["separateMajorFactionTooltip10"] = false,
	["showBonusFactionReputation10"] = true,
	["separateBonusFactionTooltip10"] = true,
	["showDragonGlyphs10"] = true,
	["autoHideCompletedDragonGlyphZones10"] = false,
	-- Dragonflight
	["showExpansion9"] = true,
	["showMajorFactionRenownLevel9"] = true,
	["applyMajorFactionColors9"] = true,
	["hideMajorFactionUnlockDescription9"] = false,
	["separateMajorFactionTooltip9"] = false,
	["showBonusFactionReputation9"] = true,
	["separateBonusFactionTooltip9"] = true,
	["showDragonGlyphs9"] = true,
	["autoHideCompletedDragonGlyphZones9"] = false,
	["showDragonflightWorldMapEvents"] = true,
	["showDragonRaceInfo"] = true,
	["showGrandHuntsInfo"] = true,
	["showCampAylaagInfo"] = true,
	["showCommunityFeastInfo"] = true,
	["showDragonbaneKeepInfo"] = true,
	["showElementalStormsInfo"] = true,
	["showFyrakkAssaultsInfo"] = true,
	["showResearchersUnderFireInfo"] = true,
	["showTimeRiftInfo"] = true,
	["showDreamsurgeInfo"] = true,
	["showSuperbloomInfo"] = true,
	["showTheBigDigInfo"] = true,
	["hideEventDescriptions"] = false,
	-- Shadowlands
	["showExpansion8"] = true,
	["showFactionReputation8"] = true,
	["separateFactionTooltip8"] = true,
	["showBonusFactionReputation8"] = true,
	["separateBonusFactionTooltip8"] = true,
	["showCovenantMissionInfo"] = true,
	["showCovenantBounties"] = true,
	["showMawThreats"] = true,
	["showCovenantRenownLevel"] = true,
	["separateCovenantRenownLevelTooltip"] = true,
	["applyCovenantColors"] = true,
	-- Battle for Azeroth
	["showExpansion7"] = true,
	["showFactionReputation7"] = true,
	["separateFactionTooltip7"] = true,
	["showBonusFactionReputation7"] = true,
	["separateBonusFactionTooltip7"] = true,
	["showBfAMissionInfo"] = true,
	["showBfABounties"] = true,
	["showNzothThreats"] = true,
	["showBfAFactionAssaultsInfo"] = true,
	["showBfAWorldMapEvents"] = true,
	["applyBfAFactionColors"] = true,
	["showBfAIslandExpeditionsInfo"] = true,
	-- Legion
	["showExpansion6"] = true,
	["showFactionReputation6"] = true,
	["separateFactionTooltip6"] = true,
	["showBonusFactionReputation6"] = true,
	["separateBonusFactionTooltip6"] = true,
	["showLegionMissionInfo"] = true,
	["showLegionBounties"] = true,
	["showLegionWorldMapEvents"] = true,
	["showLegionAssaultsInfo"] = true,
	["showBrokenShoreInvasionInfo"] = true,
	["showArgusInvasionInfo"] = true,
	["applyInvasionColors"] = true,
	["showLegionTimewalkingVendor"] = true,
	-- Warlords of Draenor
	["showExpansion5"] = true,
	["showFactionReputation5"] = true,
	["separateFactionTooltip5"] = true,
	["showBonusFactionReputation5"] = true,
	["separateBonusFactionTooltip5"] = true,
	["showWoDMissionInfo"] = true,
	["showWoDGarrisonInvasionAlert"] = true,
	["hideWoDGarrisonInvasionAlertIcon"] = false,
	["showDraenorTreasures"] = true,
	["showWoDWorldMapEvents"] = true,
	["showWoDTimewalkingVendor"] = true,
	-- Appearance
	["menuMinWidth"] = 64,
	["menuTextAlignment"] = "LEFT",
	["menuTextPaddingLeft"] = 0,
	["menuTextPaddingRight"] = 0,
	["menuTextColor"] = HIGHLIGHT_FONT_COLOR:GenerateHexColor(),
	["menuTextFont"] = "GameTooltipText",
	["menuTextFontSize"] = 12,
	["menuLineHeight"] = 3,
	["menuAnchorPoint"] = "TOPRIGHT",
	["menuAnchorPointParent"] = "BOTTOM",
	["menuAnchorOffsetX"] = 18,
	["menuAnchorOffsetY"] = 4,
};

---Loads the saved variables for the current game character.
---**Note:** Always use `ns.settings` in this project. It holds ALL setting infos after loading,
---not so the saved variables. Variable names might also change after a while.
---
---REF.: <FrameXML/TableUtil.lua>
---
---@param verbose boolean|nil  If true, prints debug messages to chat
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

	-- -- Prepare account-wide (global) settings								--> TODO - See feature request (issue #11)
	-- if (MRBP_GlobalSettings == nil) then
	-- 	_log:debug(".. initializing account-wide (global) settings");
	-- 	MRBP_GlobalSettings = {};
	-- end

	_log:info("Settings are up-to-date.");

	_log.level = verbose and prev_loglvl or _log.level;
end

---Save a given value for a given variable name.
---@param varName string  The name of the variable
---@param value any  The new value of the given variable
---
local function SaveSingleSetting(varName, value)
	if (tocVersion < 110002) then												--> TODO - Remove in later release
		-- Save project-wide (namespace) settings
		ns.settings[varName] = value;  --> not needed after WoW 11.0.2
	end

	-- Save character-specific settings
	if (ns.defaultSettings[varName] ~= value) then
		MRBP_PerCharSettings[varName] = value;
	else
		-- Don't keep duplicate (to defaults) entries
		MRBP_PerCharSettings[varName] = nil;
	end
end

---Print a user-friendly chat message about the currently selected setting.
---@param text string  The name of a given option
---@param isEnabled boolean|table  The value of given option
---
local function printOption(text, isEnabled)
	local msg = isEnabled and VIDEO_OPTIONS_ENABLED or VIDEO_OPTIONS_DISABLED;
	if (type(isEnabled) ~= "boolean") then
		msg = tostring(isEnabled);  --> print value instead
	end
	ns.cprint(text, "-", NORMAL_FONT_COLOR:WrapTextInColorCode(msg));
end

local function IsExpansionOptionSet(varNamePrefix, expansionID)
	return ns.settings[varNamePrefix..tostring(expansionID)];
end
ns.IsExpansionOptionSet = IsExpansionOptionSet;

----- Control utilities --------------------------------------------------------

-- Temp.
local function CustomRegisterAddOnSetting(categoryTbl, name, variable, variableType, defaultValue, variableKey, variableTbl)
	local setting;
	if (tocVersion < 110002) then
		setting = Settings.RegisterAddOnSetting(categoryTbl, name, variable, variableType, defaultValue);
	else
		-- REF.: Settings.RegisterAddOnSetting(categoryTbl, name, variable, variableKey, variableTbl, variableType, defaultValue)
		setting = Settings.RegisterAddOnSetting(categoryTbl, variable, variable, ns.settings, variableType, name, defaultValue);
	end

	return setting;
end

-- Return a list of expansions which the user owns.
local function GetOwnedExpansionInfoList()
	local infoList = {};
	local sortFunc = ns.settings.reverseSortorder and ExpansionInfo.SortAscending or ExpansionInfo.SortDescending;
	local expansionList = ExpansionInfo:GetExpansionsWithLandingPage(sortFunc);
	for _, expansionInfo in ipairs(expansionList) do
		local ownsExpansion = ExpansionInfo:DoesPlayerOwnExpansion(expansionInfo.ID);
		if ownsExpansion then
			tinsert(infoList, expansionInfo);
		end
	end
	return infoList;
end

----- Text -----

local LocalFontUtil = {};
LocalFontUtil.fontSettings = {};

LocalFontUtil.TEXT_ALIGN_VALUES = {
	{"LEFT", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_LEFT, nil},
	{"CENTER", L.CFG_APPEARANCE_TEXT_ALIGNMENT_CENTERED_TEXT, nil},
	{"RIGHT", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_RIGHT, nil},
};

function LocalFontUtil:GetCurrentFontSize()
	local fontObject = _G["Custom"..ns.settings.menuTextFont] or _G[ns.settings.menuTextFont] or _G[ns.defaultSettings.menuTextFont];
	local fontFile, fontHeight, fontFlags = fontObject:GetFont();
	return floor(fontHeight);
end

local FontSizeValueFormatter = function(value)
	return FONT_SIZE_TEMPLATE:format(value);
end

---Handle the value of given setting control.
---@param owner table  The owner of given control (ignorable)
---@param setting table  The given setting control
---@param value boolean|table  The value of the given control
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
		printOption(setting.name, value);
	end

	if (setting.variable == "showMinimapButton") then
		if value then
			ns:ShowMinimapButton_User();
		else
			Settings.SetValue("useMouseOverMinimapMode", value);
			ns:HideMinimapButton();
		end
	end

	if (setting.variable == "useMouseOverMinimapMode") then
		if value then
			ns:HideMinimapButton();
		else
			ns:ShowMinimapButton_User();
		end
	end

	if (setting.variable == "showInAddonCompartment") then
		if value then
			util.AddonCompartment.RegisterAddon();
		else
			util.AddonCompartment.UnregisterAddon();
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
		-- Also update checkbox in corresponding tooltip details
		ns.settings["showExpansion"..indexString] = value;

		value = CopyTable(activeEntriesList);
	end

	SaveSingleSetting(varName, value);
end

---Intercept the value of the dropdown menu entry (expansions) items to block the last entry from being disabled.
---The dropdown menu **needs** at least one entry in order to appear. 
---@param value boolean  The clicked value
---@return boolean
---
local function Checkbox_OnInterceptActiveMenuEntries(value)
	-- REF.: <FrameXML/Settings/Blizzard_SettingControls.lua>
	--> Note: This function must return a boolean value; a nil value is NOT allowed!
	if (value == false and #ns.settings.activeMenuEntries == 1) then
		-- Without any menu items the dropdown menu won't show up, so inform user
		local warningText = L.CFG_DDMENU_ENTRYSELECTION_TEXT_WARNING;
		ns.cprint(ERROR_COLOR:WrapTextInColorCode(warningText));
		if UIErrorsFrame then
			UIErrorsFrame:AddExternalErrorMessage(warningText);
			-- UIErrorsFrame:AddMessage(warningText, ERROR_COLOR:GetRGBA());
		end
		return true;
	end
	return false;
end

local settingMixin = {};

function settingMixin:SetNewTagShown(state)
	self.newTagShown = state;
end

function settingMixin:IsNewTagShown()
	return self.newTagShown;
end

---Create a checkbox control and register it's setting and add it to the given category.
---@param category table  Add and register checkbox to this category.
---@param variableName string  The name of this checkbox' variable.
---@param name string  Label text of this checkbox.
---@param tooltip string|nil  Tooltip text for this checkbox. (Nilable)
---@return table setting  The registered setting
---@return table initializer The checkbox control
---
local function CheckBox_Create(category, variableName, name, tooltip, OnValueChangedCallback)
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
	local setting = CustomRegisterAddOnSetting(category, name, varName, Settings.VarType.Boolean, defaultValue);
	Mixin(setting, settingMixin);
	local initializer = (Settings.CreateCheckBox or Settings.CreateCheckbox)(category, setting, tooltip);
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
	local cbrHandle = Settings.SetOnValueChangedCallback(varName, OnValueChangedCallback or CheckBox_OnValueChanged, setting);
	--> Note: Handle is only needed to unregister this OnValueChanged event, if necessary.

	return setting, initializer;
end

---Create multiple checkboxes from a list of data.
---@param category table  The destination category.
---@param checkBoxList table  The list of data for each checkbox.
---
local function CheckBox_CreateFromList(category, checkBoxList)
	-- Create checkboxes
	local data = {};
	for i, cb in ipairs(checkBoxList) do
		local setting, initializer = CheckBox_Create(category, cb.variable, cb.name, cb.tooltip, cb.onValueChanged);
		if cb.tag then
			setting:SetNewTagShown(Settings.Default.True);
			initializer.IsNewTagShown = function() return Settings.Default.True end;
		end
		if cb.parentVariable then
			setting.parentVariable = cb.parentVariable;
		end
		if cb.modifyPredicate then
			initializer:AddModifyPredicate(cb.modifyPredicate);
		end
		if cb.shownPredicate then
			initializer:AddShownPredicate(cb.shownPredicate);
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

local function FormatTooltipTemplate(categoryName, tooltipText, additionalText)
	local needsReloadText = format("|n|n- %s (%s)", HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(REQUIRES_RELOAD), SLASH_RELOAD1);
	local needsUIReload = (not L:IsEnglishLocale(L.currentLocale) and L.defaultLabels[categoryName] == L[categoryName]);
	local formattedText = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(tooltipText or '');
	formattedText = additionalText and formattedText..additionalText or formattedText;
	formattedText = needsUIReload and formattedText..needsReloadText or formattedText;
	return formattedText;
end

local function AppendDefaultValueText(varName)
    local textTemplate = LIGHT_GRAY(NEW_PARAGRAPH..DEFAULT..HEADER_COLON)..L.TEXT_DELIMITER.."%s";
    local valueString = tostring(ns.defaultSettings[varName]);
	-- Exceptions
	if (varName == "menuTextFontSize") then
		valueString = FontSizeValueFormatter(LocalFontUtil:GetCurrentFontSize());
	end
	if (varName == "menuTextAlignment") then
		local defaultValueString = LocalFontUtil.TEXT_ALIGN_VALUES[1][2];
		valueString = defaultValueString;
	end
    return textTemplate:format(valueString);
end

local function AppendColorPreviewText(varName, isDefault)
	local text = isDefault and DEFAULT or REFORGE_CURRENT;
	local value = isDefault and ns.defaultSettings[varName] or ns.settings[varName];
	local TextColor = CreateColorFromHexString(value);
    local textTemplate = NEWLINE.."%s"..L.TEXT_DELIMITER..LIGHT_GRAY(PARENS_TEMPLATE:format(text));
	local exampleText = TextColor:WrapTextInColorCode(PREVIEW);
    return textTemplate:format(exampleText);
end

local function Slider_Create(category, variableName, minValue, maxValue, step, label, tooltip, formatter)
	local setting = CustomRegisterAddOnSetting(category, label, variableName, Settings.VarType.Number, ns.defaultSettings[variableName] or 0);

	local options = Settings.CreateSliderOptions(minValue, maxValue, step);
	options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatter);
	local defaultValueTooltip = tooltip..AppendDefaultValueText(variableName);
	-- REF.: Settings.CreateSlider(category, setting, options, tooltip) --> initializer
	local initializer = Settings.CreateSlider(category, setting, options, defaultValueTooltip);

	-- Track and display user changes
	if (ns.settings[variableName] ~= ns.defaultSettings[variableName]) then
		setting:SetValue(ns.settings[variableName]);
	elseif (variableName == "menuTextFontSize" and ns.settings.menuTextFont ~= ns.defaultSettings.menuTextFont) then
		setting:SetValue(LocalFontUtil:GetCurrentFontSize());
	end
	local function OnValueChanged(owner, setting, value)
		printOption(setting.name, value);
		SaveSingleSetting(setting.variable, value);
	end
	Settings.SetOnValueChangedCallback(variableName, OnValueChanged);

	return setting, initializer;
end

local QuestTextPreviewFrame = SettingsPanel.QuestTextPreview;
local previewFontString = QuestTextPreviewFrame.BodyText;
local originalFontObject = previewFontString:GetFontObject();
local originalText = previewFontString:GetText();
local exampleText = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, [...]";  -- sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.";

-- Show preview of hovered font entry (option)
local function OnEntryEnter_SetFontPreview(optionData)
	local selectedFontObject = _G[optionData.value];
	previewFontString:SetFontObject(selectedFontObject);
end

-- valueList: {{key, label, tooltip_description}, ...}
-- allowed key types: see Settings.VarType
local function DropDown_Create(category, variableName, valueList, defaultText, tooltip)
	-- "menuTextFont#1-4" will be handled separately
	local varName, menuTextFontIndexString = strsplit('#', variableName);

	local defaultValue = menuTextFontIndexString and ns.defaultSettings[varName] or ns.defaultSettings[variableName];
	local currentValue = menuTextFontIndexString and ns.settings[varName] or ns.settings[variableName];
	local varType = type(defaultValue);

	local setting = CustomRegisterAddOnSetting(category, defaultText, variableName, varType, defaultValue);

	local function GetOptions()
		local container = Settings.CreateControlTextContainer();
		local key, name, tooltip_description;
		for i, item in ipairs(valueList) do
			key, name, tooltip_description = SafeUnpack(item);
			container:Add(key, name, tooltip_description);
		end
		local data = container:GetData();
		for index, optionData in ipairs(data) do
			if menuTextFontIndexString then
				optionData.onEnter = OnEntryEnter_SetFontPreview;
			end
			if (optionData.value == defaultValue) then
				optionData.label = optionData.label..L.TEXT_DELIMITER..GRAY(PARENS_TEMPLATE:format(DEFAULT));
				-- optionData.recommend = Settings.Default.True;
				-- optionData.disabled = "Disabled text.";
				-- optionData.warning = "Warning text.";
			end
		end
		return data;
	end

	local defaultValueTooltip = tooltip..AppendDefaultValueText(menuTextFontIndexString and varName or variableName);
	-- REF.: Settings.CreateDropdown(category, setting, options, tooltip) --> initializer
	local initializer = Settings.CreateDropdown(category, setting, GetOptions, defaultValueTooltip);

	-- Track and display user changes
	setting:SetValue(currentValue);
	local function OnValueChanged(owner, settingInfo, value)
		local vName, ixString = strsplit('#', settingInfo.variable);
		-- Currently only "menuTextFont#1-4" returns an index string
		if (ixString and value ~= ns.settings.menuTextFont) then
			-- Current value derived from "primary" value
			ns.settings[vName] = value;  --> always update this, so 'ns.settings.menuTextFont' can be used in core.
			-- Update font size slider
			Settings.SetValue("menuTextFontSize", LocalFontUtil:GetCurrentFontSize());

			printOption(settingInfo.name, value);
			SaveSingleSetting(vName, value);  --> save to "primary"
			-- Update the other font dropdown controls
			for i, otherSetting in ipairs(LocalFontUtil.fontSettings) do
				local v, iString = strsplit('#', otherSetting.variable);
				if (ixString ~= iString) then
					otherSetting:SetValue(value);
				end
			end
		end
		if not ixString then
			printOption(settingInfo.name, value);
			SaveSingleSetting(settingInfo.variable, value);
		end
	end
	Settings.SetOnValueChangedCallback(variableName, OnValueChanged);

	-- Add a font preview frame, but only for the font selection
	if menuTextFontIndexString then
		local function OnShow()
			QuestTextPreviewFrame:Show();
			-- Prepare preview
			local selectedFontObject = _G[ns.settings[variableName]];
			previewFontString:SetFontObject(selectedFontObject);
			previewFontString:SetText(exampleText);
		end
		local function OnHide()
			QuestTextPreviewFrame:Hide();
			-- Restore original
			previewFontString:SetFontObject(originalFontObject);
			previewFontString:SetText(originalText);
		end
		initializer.OnShow = OnShow;
		initializer.OnHide = OnHide;
	end

	return setting, initializer;
end

----- OpenToCategory -----

function MRBP_Settings_OpenToAddonCategory(categoryID, scrollToElementName)
	return Settings.OpenToCategory(categoryID, scrollToElementName);
end

function MRBP_Settings_ToggleSettingsPanel(categoryID, scrollToElementName)
	-- Toggle settings frame
	if SettingsPanel:IsShown() then
		HideUIPanel(SettingsPanel);
	else
		return MRBP_Settings_OpenToAddonCategory(categoryID, scrollToElementName);
	end
end

----- Controls -----

local function CreateMenuTooltipSettings(category, layout)
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
			variable = "showLandingPageIcons",
			name = L.CFG_DDMENU_REPORTICONS_TEXT,
			tooltip = L.CFG_DDMENU_REPORTICONS_TOOLTIP,
		},
		{
			variable = "showMissionCompletedHint",
			name = L.CFG_DDMENU_HINT_MISSIONS_TEXT,
			tooltip = L.CFG_DDMENU_HINT_MISSIONS_TOOLTIP,
		},
		{
			variable = "showMissionCompletedHintOnlyForAll",
			name = L.CFG_DDMENU_HINT_MISSIONS_ALL_TEXT,
			tooltip = L.CFG_DDMENU_HINT_MISSIONS_ALL_TOOLTIP,
			parentVariable = "showMissionCompletedHint",
		},
		{
			variable = "showReputationRewardPendingHint",
			name = L.CFG_DDMENU_HINT_REPUTATION_TEXT,
			tooltip = L.CFG_DDMENU_HINT_REPUTATION_TOOLTIP..NEW_PARAGRAPH..GRAY(L.WORKS_ONLY_FOR_EXPANSION_S:format(ExpansionInfo.data.DRAGONFLIGHT.name)),
		},
		{
			variable = "showTimewalkingVendorHint",
			name = L.CFG_DDMENU_HINT_TIMEWALKING_VENDOR_TEXT,
			tooltip = L.CFG_DDMENU_HINT_TIMEWALKING_VENDOR_TOOLTIP,
		},
		{
			variable = "highlightCurrentZone",
			name = L.CFG_DDMENU_HIGHLIGHT_CURRENT_ZONE_TEXT,
			tooltip = L.CFG_DDMENU_HIGHLIGHT_CURRENT_ZONE_TOOLTIP,
		},
	};

	CheckBox_CreateFromList(category, checkBoxList_DropDownMenuSettings);
end

local function CreateMenuEntriesSelection(category, layout)
	local sortFunc = ns.settings.reverseSortorder and ExpansionInfo.SortAscending or ExpansionInfo.SortDescending;

	local menuEntries = {};
	menuEntries.expansionList = ExpansionInfo:GetExpansionsWithLandingPage(sortFunc);
	menuEntries.settingsCB = {  --> Additional "Settings" menu entry
		ID = 99,
		name = "[ "..SETTINGS.." ]"
	};
	tinsert(menuEntries.expansionList, menuEntries.settingsCB);
	ns.settingsMenuEntry = tostring(menuEntries.settingsCB.ID);

	local function getMenuEntryTooltip(expansionID, playerOwnsExpansion)
		local featuresString = '';
		local displayInfo = ExpansionInfo:GetDisplayInfo(expansionID);
		if displayInfo then
			local expansion = ExpansionInfo:GetExpansionData(expansionID);
			local _, width, height = util.GetAtlasInfo(displayInfo.banner);
			local bannerString = util.CreateInlineIcon(displayInfo.banner, width, height, 8, -16);
			featuresString = featuresString..bannerString..NEWLINE;
			if not playerOwnsExpansion then
				featuresString = NEWLINE..ERROR_COLOR_CODE..featuresString..ERR_REQUIRES_EXPANSION_S:format(expansion.name)..FONT_COLOR_CODE_CLOSE..NEW_PARAGRAPH;
			end
			featuresString = featuresString..HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(FEATURES_LABEL)..NEW_PARAGRAPH;
			for _, feature in ipairs(displayInfo.features) do
				local iconString = util.CreateInlineIcon(feature.icon);
				featuresString = featuresString..iconString.." "..feature.text..NEWLINE;
			end
		end
		return featuresString;
	end

	-- Map names to settings
	menuEntries.checkBoxList_MenuEntriesSettings = {};

	for _, expansion in ipairs(menuEntries.expansionList) do
		local ownsExpansion = ExpansionInfo:DoesPlayerOwnExpansion(expansion.ID);
		tinsert(menuEntries.checkBoxList_MenuEntriesSettings, {
			variable = "activeMenuEntries#"..tostring(expansion.ID),
			name = ownsExpansion and expansion.name or DISABLED_FONT_COLOR:WrapTextInColorCode(expansion.name),
			tooltip = ns.settingsMenuEntry ~= tostring(expansion.ID) and getMenuEntryTooltip(expansion.ID, ownsExpansion),
			modifyPredicate = function() return ownsExpansion end;
			-- tag = (expansion.ID == ExpansionInfo.data.WAR_WITHIN.ID) and Settings.Default.True or Settings.Default.False,
		});
	end

	CheckBox_CreateFromList(category, menuEntries.checkBoxList_MenuEntriesSettings);

	-- Add un-/check all entry buttons
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
	-- REF.: CreateSettingsButtonInitializer(name, buttonText, buttonClick, tooltip, addSearchTags)
	local addSearchTags = Settings.Default.False;
	local checkAllInitializer = CreateSettingsButtonInitializer('', CHECK_ALL, OnCheckAll, nil, addSearchTags);
	layout:AddInitializer(checkAllInitializer);
	local unCheckAllInitializer = CreateSettingsButtonInitializer('', UNCHECK_ALL, OnUncheckAll, nil, addSearchTags);
	layout:AddInitializer(unCheckAllInitializer);
end

----- Expansion-specific Settings -----

local ExpansionTooltipSettings = {};

ExpansionTooltipSettings[ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID] = {
	{
		variable = "showFactionReputation5",
		name = L["MainFactionReputationLabel"],
		tooltip = L.CFG_FACTION_REPUTATION_TOOLTIP_S:format(LIGHT_GRAY(ExpansionInfo.data.WARLORDS_OF_DRAENOR.name)),
		tag = Settings.Default.True,
	},
	{
		variable = "separateFactionTooltip5",
		name = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TEXT,
		tooltip = L.CFG_FACTION_REPUTATION_SEPARATE_TOOLTIP_TOOLTIP,
		parentVariable = "showFactionReputation5",
	},
	{
		variable = "showBonusFactionReputation5",
		name = L["BonusFactionReputationLabel5"],
		tooltip = L.CFG_FACTION_REPUTATION_BARRACKS_BODYGUARDS_TOOLTIP,
		tag = Settings.Default.True,
	},
	{
		variable = "separateBonusFactionTooltip5",
		name = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TEXT,
		tooltip = L.CFG_FACTION_REPUTATION_SEPARATE_TOOLTIP_TOOLTIP,
		parentVariable = "showBonusFactionReputation5",
	},
	{
		variable = "showWoDMissionInfo",
		name = L["showWoDMissionInfo"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MISSION_INFO_TOOLTIP,
	},
	{
		variable = "showWoDGarrisonInvasionAlert",
		name = L["showWoDGarrisonInvasionAlert"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_GARRISON_INVASION_ALERT_TOOLTIP,
	},
	{
		variable = "hideWoDGarrisonInvasionAlertIcon",
		name = L.CFG_WOD_HIDE_GARRISON_INVASION_ALERT_ICON_TEXT,
		tooltip = L.CFG_WOD_HIDE_GARRISON_INVASION_ALERT_ICON_TOOLTIP,
		parentVariable = "showWoDGarrisonInvasionAlert",
	},
	{
		variable = "showWoDWorldMapEvents",
		name = L["showWoDWorldMapEvents"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_WORLD_MAP_EVENTS_TOOLTIP,
	},
	{
		variable = "showWoDTimewalkingVendor",
		name = L["showWoDTimewalkingVendor"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_TIMEWALKING_VENDOR_TOOLTIP,
		parentVariable = "showWoDWorldMapEvents",
	},
	{
		variable = "showDraenorTreasures",
		name = L["showDraenorTreasures"],
		tooltip = L.CFG_WOD_SHOW_DRAENOR_TREASURES_TOOLTIP,
		parentVariable = "showWoDWorldMapEvents",
	},
};

ExpansionTooltipSettings[ExpansionInfo.data.LEGION.ID] = {
	{
		variable = "showFactionReputation6",
		name = L["MainFactionReputationLabel"],
		tooltip = L.CFG_FACTION_REPUTATION_TOOLTIP_S:format(LIGHT_GRAY(ExpansionInfo.data.LEGION.name)),
		tag = Settings.Default.True,
	},
	{
		variable = "separateFactionTooltip6",
		name = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TEXT,
		tooltip = L.CFG_FACTION_REPUTATION_SEPARATE_TOOLTIP_TOOLTIP,
		parentVariable = "showFactionReputation6",
	},
	{
		variable = "showBonusFactionReputation6",
		name = L["BonusFactionReputationLabel"],
		tooltip = L.CFG_FACTION_REPUTATION_OTHER_FACTIONS_TOOLTIP,
		tag = Settings.Default.True,
	},
	{
		variable = "separateBonusFactionTooltip6",
		name = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TEXT,
		tooltip = L.CFG_FACTION_REPUTATION_SEPARATE_TOOLTIP_TOOLTIP,
		parentVariable = "showBonusFactionReputation6",
	},
	{
		variable = "showLegionMissionInfo",
		name = L["showLegionMissionInfo"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MISSION_INFO_TOOLTIP,
		modifyPredicate = function() return not PlayerInfo:IsPlayerEvokerClass(); end
	},
	{
		variable = "showLegionBounties",
		name = L["showLegionBounties"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_LEGION_BOUNTIES_TOOLTIP,
	},
	{
		variable = "showLegionWorldMapEvents",
		name = L["showLegionWorldMapEvents"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_WORLD_MAP_EVENTS_TOOLTIP,
	},
	{
		variable = "showLegionAssaultsInfo",
		name = L["showLegionAssaultsInfo"],
		tooltip = FormatTooltipTemplate("showLegionAssaultsInfo", L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_LEGION_INVASION),
		parentVariable = "showLegionWorldMapEvents",
	},
	{
		variable = "showBrokenShoreInvasionInfo",
		name = L["showBrokenShoreInvasionInfo"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_DEMON_INVASION),
		parentVariable = "showLegionWorldMapEvents",
	},
	{
		variable = "showArgusInvasionInfo",
		name = L["showArgusInvasionInfo"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_ARGUS_INVASION),
		parentVariable = "showLegionWorldMapEvents",
	},
	{
		variable = "applyInvasionColors",
		name = L["applyInvasionColors"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_LEGION_INVASION_COLORS_TOOLTIP,
		parentVariable = "showLegionWorldMapEvents",
	},
	{
		variable = "showLegionTimewalkingVendor",
		name = L["showLegionTimewalkingVendor"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_TIMEWALKING_VENDOR_TOOLTIP,
		parentVariable = "showLegionWorldMapEvents",
	},
};

ExpansionTooltipSettings[ExpansionInfo.data.BATTLE_FOR_AZEROTH.ID] = {
	{
		variable = "showFactionReputation7",
		name = L["MainFactionReputationLabel"],
		tooltip = L.CFG_FACTION_REPUTATION_TOOLTIP_S:format(LIGHT_GRAY(ExpansionInfo.data.BATTLE_FOR_AZEROTH.name)),
		tag = Settings.Default.True,
	},
	{
		variable = "separateFactionTooltip7",
		name = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TEXT,
		tooltip = L.CFG_FACTION_REPUTATION_SEPARATE_TOOLTIP_TOOLTIP,
		parentVariable = "showFactionReputation7",
	},
	{
		variable = "showBonusFactionReputation7",
		name = L["BonusFactionReputationLabel7"],
		tooltip = L.CFG_FACTION_REPUTATION_OTHER_FACTIONS_TOOLTIP,
		tag = Settings.Default.True,
	},
	{
		variable = "separateBonusFactionTooltip7",
		name = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TEXT,
		tooltip = L.CFG_FACTION_REPUTATION_SEPARATE_TOOLTIP_TOOLTIP,
		parentVariable = "showBonusFactionReputation7",
	},
	{
		variable = "showBfAMissionInfo",
		name = L["showBfAMissionInfo"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MISSION_INFO_TOOLTIP,
	},
	{
		variable = "showBfABounties",
		name = L["showBfABounties"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_BFA_BOUNTIES_TOOLTIP,
	},
	{
		variable = "showNzothThreats",
		name = L["showNzothThreats"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_NZOTH_THREATS_TOOLTIP,
	},
	{
		variable = "showBfAWorldMapEvents",
		name = L["showBfAWorldMapEvents"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_WORLD_MAP_EVENTS_TOOLTIP,
	},
	{
		variable = "showBfAFactionAssaultsInfo",
		name = L["showBfAFactionAssaultsInfo"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_BFA_FACTION_ASSAULTS),
		parentVariable = "showBfAWorldMapEvents",
	},
	{
		variable = "applyBfAFactionColors",
		name = L["applyBfAFactionColors"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_FACTION_COLORS_TOOLTIP,
	},
	{
		variable = "showBfAIslandExpeditionsInfo",
		name = L["showBfAIslandExpeditionsInfo"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_BFA_ISLAND_EXPEDITIONS_TOOLTIP,
	},
};

ExpansionTooltipSettings[ExpansionInfo.data.SHADOWLANDS.ID] = {
	{
		variable = "showFactionReputation8",
		name = L["MainFactionReputationLabel"],
		tooltip = L.CFG_FACTION_REPUTATION_TOOLTIP_S:format(LIGHT_GRAY(ExpansionInfo.data.SHADOWLANDS.name)),
		tag = Settings.Default.True,
	},
	{
		variable = "separateFactionTooltip8",
		name = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TEXT,
		tooltip = L.CFG_FACTION_REPUTATION_SEPARATE_TOOLTIP_TOOLTIP,
		parentVariable = "showFactionReputation8",
	},
	{
		variable = "showBonusFactionReputation8",
		name = L["BonusFactionReputationLabel"],
		tooltip = L.CFG_FACTION_REPUTATION_OTHER_FACTIONS_TOOLTIP,
		shownPredicate = function() return LocalFactionInfo:HasBonusFactions(ExpansionInfo.data.SHADOWLANDS.ID); end,
		tag = Settings.Default.True,
	},
	{
		variable = "separateBonusFactionTooltip8",
		name = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TEXT,
		tooltip = L.CFG_FACTION_REPUTATION_SEPARATE_TOOLTIP_TOOLTIP,
		shownPredicate = function() return LocalFactionInfo:HasBonusFactions(ExpansionInfo.data.SHADOWLANDS.ID); end,
		parentVariable = "showBonusFactionReputation8",
	},
	{
		variable = "showCovenantMissionInfo",
		name = L["showCovenantMissionInfo"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MISSION_INFO_TOOLTIP,
	},
	{
		variable = "showCovenantBounties",
		name = L["showCovenantBounties"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_COVENANT_BOUNTIES_TOOLTIP,
	},
	{
		variable = "showMawThreats",
		name = L["showMawThreats"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MAW_THREATS_TOOLTIP,
	},
	{
		variable = "showCovenantRenownLevel",
		name = L["showCovenantRenownLevel"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_COVENANT_RENOWN_TOOLTIP,
	},
	{
		variable = "separateCovenantRenownLevelTooltip",
		name = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TEXT,
		tooltip = L.CFG_FACTION_REPUTATION_SEPARATE_TOOLTIP_TOOLTIP,
		parentVariable = "showCovenantRenownLevel",
		tag = Settings.Default.True,
	},
	{
		variable = "applyCovenantColors",
		name = L["applyCovenantColors"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_FACTION_COLORS_TOOLTIP,
	},
};

ExpansionTooltipSettings[ExpansionInfo.data.DRAGONFLIGHT.ID] = {
	{
		variable = "showMajorFactionRenownLevel9",
		name = L["showMajorFactionRenownLevel"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MAJOR_FACTION_RENOWN_TOOLTIP,
	},
	{
		variable = "applyMajorFactionColors9",
		name = L["applyMajorFactionColors"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_FACTION_COLORS_TOOLTIP,
		parentVariable = "showMajorFactionRenownLevel9",
	},
	{
		variable = "hideMajorFactionUnlockDescription9",
		name = L["hideMajorFactionUnlockDescription"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MAJOR_FACTION_UNLOCK_TOOLTIP,
		parentVariable = "showMajorFactionRenownLevel9",
	},
	{
		variable = "separateMajorFactionTooltip9",
		name = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TEXT,
		tooltip = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TOOLTIP,
		parentVariable = "showMajorFactionRenownLevel9",
	},
	{
		variable = "showBonusFactionReputation9",
		name = L["BonusFactionReputationLabel"],
		tooltip = L.CFG_FACTION_REPUTATION_OTHER_FACTIONS_TOOLTIP,
		tag = Settings.Default.True,
	},
	{
		variable = "separateBonusFactionTooltip9",
		name = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TEXT,
		tooltip = L.CFG_FACTION_REPUTATION_SEPARATE_TOOLTIP_TOOLTIP,
		parentVariable = "showBonusFactionReputation9",
	},
	{
		variable = "showDragonGlyphs9",
		name = L["showDragonGlyphs"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_DRAGON_GLYPHS_TOOLTIP,
	},
	{
		variable = "autoHideCompletedDragonGlyphZones9",
		name = L["autoHideCompletedDragonGlyphZones"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_HIDE_DRAGON_GLYPHS_TOOLTIP,
		parentVariable = "showDragonGlyphs9",
	},
	{
		variable = "showDragonflightWorldMapEvents",
		name = L["showDragonflightWorldMapEvents"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_WORLD_MAP_EVENTS_TOOLTIP,
	},
	{
		variable = "showDragonRaceInfo",
		name = L["showDragonRaceInfo"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_DRAGONRIDING_RACE),
		parentVariable = "showDragonflightWorldMapEvents",
	},
	{
		variable = "showCampAylaagInfo",
		name = L["showCampAylaagInfo"],
		tooltip = FormatTooltipTemplate("showCampAylaagInfo", L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_CAMP_AYLAAG),
		parentVariable = "showDragonflightWorldMapEvents",
	},
	{
		variable = "showGrandHuntsInfo",
		name = L["showGrandHuntsInfo"],
		tooltip = FormatTooltipTemplate("showGrandHuntsInfo", L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_GRAND_HUNTS),
		parentVariable = "showDragonflightWorldMapEvents",
	},
	{
		variable = "showCommunityFeastInfo",
		name = L["showCommunityFeastInfo"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_ISKAARA_FEAST),
		parentVariable = "showDragonflightWorldMapEvents",
	},
	{
		variable = "showDragonbaneKeepInfo",
		name = L["showDragonbaneKeepInfo"],
		tooltip = FormatTooltipTemplate("showDragonbaneKeepInfo", L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_DRAGONBANE_KEEP),
		parentVariable = "showDragonflightWorldMapEvents",
	},
	{
		variable = "showElementalStormsInfo",
		name = L["showElementalStormsInfo"],
		tooltip = FormatTooltipTemplate("showElementalStormsInfo", L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_ELEMENTAL_STORMS),
		parentVariable = "showDragonflightWorldMapEvents",
	},
	{
		variable = "showFyrakkAssaultsInfo",
		name = L["showFyrakkAssaultsInfo"],
		tooltip = FormatTooltipTemplate("showFyrakkAssaultsInfo", L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_FYRAKK_ASSAULTS),
		parentVariable = "showDragonflightWorldMapEvents",
	},
	{
		variable = "showResearchersUnderFireInfo",
		name = L["showResearchersUnderFireInfo"],
		tooltip = FormatTooltipTemplate("showResearchersUnderFireInfo", L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_RESEARCHERS_UNDER_FIRE, NEW_PARAGRAPH..L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_ONLY_IN_ZARALEK_CAVERN),
		parentVariable = "showDragonflightWorldMapEvents",
	},
	{
		variable = "showTimeRiftInfo",
		name = L["showTimeRiftInfo"],
		tooltip = FormatTooltipTemplate("showTimeRiftInfo", L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TIME_RIFTS),
		parentVariable = "showDragonflightWorldMapEvents",
	},
	{
		variable = "showDreamsurgeInfo",
		name = L["showDreamsurgeInfo"],
		tooltip = FormatTooltipTemplate("showDreamsurgeInfo", L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_DREAMSURGE),
		parentVariable = "showDragonflightWorldMapEvents",
	},
	{
		variable = "showSuperbloomInfo",
		name = L["showSuperbloomInfo"],
		tooltip = FormatTooltipTemplate("showSuperbloomInfo", L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_SUPERBLOOM),
		parentVariable = "showDragonflightWorldMapEvents",
	},
	{
		variable = "showTheBigDigInfo",
		name = L["showTheBigDigInfo"],
		tooltip = FormatTooltipTemplate("showTheBigDigInfo", L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_THE_BIG_DIG),
		parentVariable = "showDragonflightWorldMapEvents",
	},
	{
		variable = "hideEventDescriptions",
		name = L["hideEventDescriptions"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_HIDE_EVENT_DESCRIPTIONS,
		parentVariable = "showDragonflightWorldMapEvents",
		-- modifyPredicate = ShouldShowEntryTooltip,
	},
};

ExpansionTooltipSettings[ExpansionInfo.data.WAR_WITHIN.ID] = {
	{
		variable = "showMajorFactionRenownLevel10",
		name = L["showMajorFactionRenownLevel"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MAJOR_FACTION_RENOWN_TOOLTIP,
	},
	{
		variable = "applyMajorFactionColors10",
		name = L["applyMajorFactionColors"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_FACTION_COLORS_TOOLTIP,
		parentVariable = "showMajorFactionRenownLevel10",
	},
	{
		variable = "hideMajorFactionUnlockDescription10",
		name = L["hideMajorFactionUnlockDescription"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MAJOR_FACTION_UNLOCK_TOOLTIP,
		parentVariable = "showMajorFactionRenownLevel10",
	},
	{
		variable = "separateMajorFactionTooltip10",
		name = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TEXT,
		tooltip = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TOOLTIP,
		parentVariable = "showMajorFactionRenownLevel10",
	},
	{
		variable = "showBonusFactionReputation10",
		name = L["BonusFactionReputationLabel"],
		tooltip = L.CFG_FACTION_REPUTATION_OTHER_FACTIONS_TOOLTIP,
		tag = Settings.Default.True,
	},
	{
		variable = "separateBonusFactionTooltip10",
		name = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TEXT,
		tooltip = L.CFG_FACTION_REPUTATION_SEPARATE_TOOLTIP_TOOLTIP,
		parentVariable = "showBonusFactionReputation10",
	},
	{
		variable = "showDragonGlyphs10",
		name = L["showDragonGlyphs"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_DRAGON_GLYPHS_TOOLTIP,
	},
	{
		variable = "autoHideCompletedDragonGlyphZones10",
		name = L["autoHideCompletedDragonGlyphZones"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_HIDE_DRAGON_GLYPHS_TOOLTIP,
		parentVariable = "showDragonGlyphs10",
	},
};

local function CreateExpansionTooltipSettings(category, expansionInfo)
	local checkBoxList = ExpansionTooltipSettings[expansionInfo.ID];
	if checkBoxList then
		CheckBox_CreateFromList(category, checkBoxList);
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

---Register this addon's settings to the new (WoW 10.x) settings UI.
function MRBP_Settings_Register()
	local mainCategory, mainLayout = Settings.RegisterVerticalLayoutCategory(addonTitle);
	mainCategory.ID = AddonID;
	Settings.RegisterAddOnCategory(mainCategory);

	LoadSettings();

	----- General settings -----

	mainLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer(GENERAL_SUBHEADER));

	local checkBoxList_CommonSettings = {
		{
			variable = "showChatNotifications",
			name = L.CFG_CHAT_NOTIFY_TEXT,
			tooltip = L.CFG_CHAT_NOTIFY_TOOLTIP,
		},
		{
			variable = "showMinimapButton",
			name = L.CFG_MINIMAPBUTTON_SHOWBUTTON_TEXT,
			tooltip = L.CFG_MINIMAPBUTTON_SHOWBUTTON_TOOLTIP,
			modifyPredicate = function()
				local result = LocalRequirementInfo:IsAnyLandingPageAvailable();
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
		{
			variable = "useMouseOverMinimapMode",
			name = L.CFG_MINIMAPBUTTON_MOUSE_OVER_MINIMAP_MODE_TEXT,
			tooltip = L.CFG_MINIMAPBUTTON_MOUSE_OVER_MINIMAP_MODE_TOOLTIP,
			parentVariable = "showMinimapButton",
		},
		{
			variable = "useMiddleButton",
			name = L.CFG_MINIMAPBUTTON_USE_MIDDLE_BUTTON_TEXT,
			tooltip = L.CFG_MINIMAPBUTTON_USE_MIDDLE_BUTTON_TOOLTIP,
			parentVariable = "showMinimapButton",
		},
		-- {
		-- 	variable = "useSingleExpansionLandingPageType",						--> TODO - L10n
		-- 	name = "Eine Erweiterung für alle Zonen",
		-- 	tooltip = "Wenn aktiviert, wird eine der im Menü verfügbaren Erweiterungen als Minikarten-Button durchgehend in allen Zonen angezeigt.",
		-- 	parentVariable = "showMinimapButton",
		-- 	tag = Settings.Default.True,
		-- },
		util.AddonCompartment.IsAddonCompartmentAvailable() and {
			variable = "showInAddonCompartment",
			name = L.CFG_SHOW_ADDON_COMPARTMENT_TEXT,
			tooltip = L.CFG_SHOW_ADDON_COMPARTMENT_TOOLTIP,
		},
		{
			variable = "showAchievementTracking",
			name = L.CFG_TRACK_ACHIEVEMENTS_TEXT,
			tooltip = L.CFG_TRACK_ACHIEVEMENTS_TOOLTIP.."|n|n- "..strjoin("|n- ", SafeUnpack(ns.GetTrackedAchievementTitles())),
		},
	};

	CheckBox_CreateFromList(mainCategory, checkBoxList_CommonSettings);

	if (ns.settings.showInAddonCompartment and not util.AddonCompartment.IsAddonRegistered()) then
		util.AddonCompartment.RegisterAddon();
	end

	----- Shortcut buttons to settings subcategories -----															

	local addSearchTags = Settings.Default.False;

	-- Right-click menu button
	do
		local OnMenuTooltipButtonClick = function()
			MRBP_Settings_OpenToAddonCategory(mainCategory.ID.."MenuTooltipSettings");
		end
		local menuTooltipButtonLabel = strjoin(LIST_DELIMITER, L.CFG_DDMENU_ENTRYSELECTION_LABEL, L.CFG_DDMENU_SEPARATOR_HEADING);
		local menuTooltipButtonInitializer = CreateSettingsButtonInitializer(menuTooltipButtonLabel, L.CFG_DDMENU_SEPARATOR_HEADING, OnMenuTooltipButtonClick, L.CFG_DDMENU_ENTRYSELECTION_TOOLTIP, addSearchTags);
		mainLayout:AddInitializer(menuTooltipButtonInitializer);
	end

	-- Appearance button
	do
		local OnAppearanceButtonClick = function()
			MRBP_Settings_OpenToAddonCategory(mainCategory.ID.."AppearanceSettings");
		end
		local appearanceButtonLabel = strjoin(LIST_DELIMITER, HUD_EDIT_MODE_SETTING_MICRO_MENU_SIZE, FONT_SIZE);
		local appearanceButtonInitializer = CreateSettingsButtonInitializer(appearanceButtonLabel, APPEARANCE_LABEL, OnAppearanceButtonClick, L.CFG_DDMENU_STYLESELECTION_TOOLTIP, addSearchTags);
		mainLayout:AddInitializer(appearanceButtonInitializer);
		-- appearanceButtonInitializer.IsNewTagShown = function() return Settings.Default.True end;
	end

	-- Details tooltip option shortcuts (Expansion buttons)
	do
		mainLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.CFG_DDMENU_ENTRYTOOLTIP_LABEL));
		for _, expansionInfo in ipairs(GetOwnedExpansionInfoList()) do
			local categoryID = format("%sExpansion%02dSettings", mainCategory.ID, expansionInfo.ID);
			local OnExpansionButtonClick = function()
				mainCategory.expanded = Settings.Default.True;  --> is not properly set by default
				mainCategory:SetExpanded(Settings.Default.True);
				MRBP_Settings_OpenToAddonCategory(mainCategory.ID.."MenuTooltipSettings");
				MRBP_Settings_OpenToAddonCategory(categoryID);
			end
			local expansionButtonInitializer = CreateSettingsButtonInitializer('', expansionInfo.name, OnExpansionButtonClick, '', addSearchTags);
			mainLayout:AddInitializer(expansionButtonInitializer);
			-- if (expansionInfo.ID >= ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID) and
			--    (expansionInfo.ID <= ExpansionInfo.data.WAR_WITHIN.ID) then
			-- 	expansionButtonInitializer.IsNewTagShown = function() return Settings.Default.True end;
			-- end
			expansionButtonInitializer.IsNewTagShown = function() return Settings.Default.True end;
		end
	end

	-- About frame button
	do
		mainLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.CFG_ABOUT_ADDON_LABEL));
		local OnAboutButtonClick = function()
			MRBP_Settings_OpenToAddonCategory(mainCategory.ID.."AboutFrame");
		end
		local aboutButtonLabel = strjoin(LIST_DELIMITER, L.CFG_ADDONINFOS_VERSION, L.CFG_ABOUT_SLASHCMD_LABEL);
		local aboutButtonInitializer = CreateSettingsButtonInitializer(aboutButtonLabel, L.CFG_ABOUT_ADDON_LABEL, OnAboutButtonClick, L.CFG_ABOUT_ADDON_LABEL, addSearchTags);
		mainLayout:AddInitializer(aboutButtonInitializer);
	end

	----------------------------------------------------------------------------
	----- MenuTooltip (dropdown menu) ------------------------------------------
	----------------------------------------------------------------------------

	local menuTooltipCategory, menuTooltipLayout = Settings.RegisterVerticalLayoutSubcategory(mainCategory, L.CFG_DDMENU_SEPARATOR_HEADING);
	menuTooltipCategory.ID = AddonID.."MenuTooltipSettings";

	----- Right-click menu settings -----
	CreateMenuTooltipSettings(menuTooltipCategory, menuTooltipLayout);

	----- Menu entries selection -----
	menuTooltipLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.CFG_DDMENU_ENTRYSELECTION_LABEL));
	CreateMenuEntriesSelection(menuTooltipCategory, menuTooltipLayout);

	----- Expansion tooltip settings (separate subcategories) -----
	local function cbOnValueChangedCallback(owner, setting, value)
		local expansionIDstring = string.gsub(setting.variable, "showExpansion", '');  --> eg. "10"
		local activeMenuEntrySetting = Settings.GetSetting("activeMenuEntries#"..expansionIDstring);
		if activeMenuEntrySetting then
			ns.settings["activeMenuEntries#"..expansionIDstring] = value;
			CheckBox_OnValueChanged(owner, activeMenuEntrySetting, value);
		end
	end

	if ns.settings.showEntryTooltip then
		for _, expansionInfo in ipairs(GetOwnedExpansionInfoList()) do
			-- Register expansion in its own subcategory
			local expansionCategory, expansionLayout = Settings.RegisterVerticalLayoutSubcategory(menuTooltipCategory, expansionInfo.name);
			expansionCategory.ID = format("%sExpansion%02dSettings", AddonID, expansionInfo.ID);

			-- Add show/hide entry checkboxes for each expansion details settings
			if (ns.settingsMenuEntry ~= tostring(expansionInfo.ID)) then
				local expansionTooltipName = BANK_TAB_EXPANSION_ASSIGNMENT:format(expansionInfo.name);
				local cbShowHide = {
					{
						variable = "showExpansion"..tostring(expansionInfo.ID),
						name = L.CFG_DDMENU_SHOW_EXPANSION_ENTRY_TEXT,
						tooltip = L.CFG_DDMENU_SHOW_EXPANSION_ENTRY_TOOLTIP_S:format(expansionTooltipName),
						modifyPredicate = function() return ExpansionInfo:DoesPlayerOwnExpansion(expansionInfo.ID); end,
						onValueChanged = cbOnValueChangedCallback,
					},
				};
				CheckBox_CreateFromList(expansionCategory, cbShowHide);
			end

			-- Add subcategory content
			expansionLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.CFG_DDMENU_ENTRYTOOLTIP_LABEL));
			CreateExpansionTooltipSettings(expansionCategory, expansionInfo);
		end
	end

	----------------------------------------------------------------------------
	----- Tooltip appearance ---------------------------------------------------
	----------------------------------------------------------------------------

	local appearanceCategory, appearanceLayout = Settings.RegisterVerticalLayoutSubcategory(mainCategory, APPEARANCE_LABEL);
	appearanceCategory.ID = AddonID.."AppearanceSettings";

	local menuNameTemplate = GRAY(L.CFG_DDMENU_SEPARATOR_HEADING..HEADER_COLON)..L.TEXT_DELIMITER.."%s";

	------- MenuTooltip: Anchor -----
	do
		appearanceLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer(menuNameTemplate:format(L.CFG_APPEARANCE_ANCHOR_LABEL)));
		-- REF.: frame:SetPoint(point [, relativeTo [, relativePoint]] [, offsetX, offsetY])

		-- Point
		local pointValues = {
			{"TOPLEFT", "TOPLEFT", nil},
			{"TOPRIGHT", "TOPRIGHT", nil},
			{"BOTTOMLEFT", "BOTTOMLEFT", nil},
			{"BOTTOMRIGHT", "BOTTOMRIGHT", nil},
			{"TOP", "TOP", nil},
			{"BOTTOM", "BOTTOM", nil},
			{"LEFT", "LEFT", nil},
			{"RIGHT", "RIGHT", nil},
			{"CENTER", "CENTER", nil},
		};
		local pointLabel = L.CFG_APPEARANCE_ANCHOR_LABEL..HEADER_COLON..L.TEXT_DELIMITER..L.CFG_DDMENU_SEPARATOR_HEADING;
		DropDown_Create(appearanceCategory, "menuAnchorPoint", pointValues, pointLabel, L.CFG_APPEARANCE_ANCHOR_POINT_MENU_TOOLTIP);

		-- relativePoint
		local parentPointLabel = L.CFG_APPEARANCE_ANCHOR_LABEL..HEADER_COLON..L.TEXT_DELIMITER..L.CFG_APPEARANCE_ANCHOR_POINT_BUTTON_TEXT;
		DropDown_Create(appearanceCategory, "menuAnchorPointParent", pointValues, parentPointLabel, L.CFG_APPEARANCE_ANCHOR_POINT_BUTTON_TOOLTIP);

		-- offsetX
		local minOffsetXValue, maxOffsetXValue, offsetXStep = -64, 64, 1;
		local offsetXLabel = L.CFG_APPEARANCE_ANCHOR_DISTANCE_TEXT..L.TEXT_DELIMITER..PARENS_TEMPLATE:format(HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION_HORIZONTAL);
		Slider_Create(appearanceCategory, "menuAnchorOffsetX", minOffsetXValue, maxOffsetXValue, offsetXStep, offsetXLabel, L.CFG_APPEARANCE_ANCHOR_DISTANCE_TOOLTIP);

		-- offsetY
		local minOffsetYValue, maxOffsetYValue, offsetYStep = -64, 64, 1;
		local offsetYLabel = L.CFG_APPEARANCE_ANCHOR_DISTANCE_TEXT..L.TEXT_DELIMITER..PARENS_TEMPLATE:format(HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION_VERTICAL);
		Slider_Create(appearanceCategory, "menuAnchorOffsetY", minOffsetYValue, maxOffsetYValue, offsetYStep, offsetYLabel, L.CFG_APPEARANCE_ANCHOR_DISTANCE_TOOLTIP);
	end

	----- MenuTooltip: Text -----
	do
		appearanceLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer(menuNameTemplate:format(LOCALE_TEXT_LABEL)));

		-- Alignment
		DropDown_Create(appearanceCategory, "menuTextAlignment", LocalFontUtil.TEXT_ALIGN_VALUES, HUD_EDIT_MODE_SETTING_MICRO_MENU_ORIENTATION, L.CFG_APPEARANCE_TEXT_ALIGNMENT_TOOLTIP);

		-- Padding (Left)
		local padLeftMinValue, padLeftMaxValue, padLeftStep = 0, 64, 1;
		local padLeftLabel = L.CFG_APPEARANCE_TEXT_PADDING_TEXT..L.TEXT_DELIMITER..PARENS_TEMPLATE:format(HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_LEFT);
		Slider_Create(appearanceCategory, "menuTextPaddingLeft", padLeftMinValue, padLeftMaxValue, padLeftStep, padLeftLabel, L.CFG_APPEARANCE_TEXT_PADDING_TOOLTIP);

		-- Padding (Right)
		local padRightMinValue, padRightMaxValue, padRightStep = 0, 64, 1;
		local padRightLabel = L.CFG_APPEARANCE_TEXT_PADDING_TEXT..L.TEXT_DELIMITER..PARENS_TEMPLATE:format(HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_RIGHT);
		Slider_Create(appearanceCategory, "menuTextPaddingRight", padRightMinValue, padRightMaxValue, padRightStep, padRightLabel, L.CFG_APPEARANCE_TEXT_PADDING_TOOLTIP);

		-- Text Color
		do
			local menuTextColorVarName = "menuTextColor";
			local menuTextColorSetting = CustomRegisterAddOnSetting(appearanceCategory, L.CFG_APPEARANCE_TEXT_COLOR_TEXT, menuTextColorVarName, Settings.VarType.String, ns.defaultSettings[menuTextColorVarName]);

			ColorPickerFrame.Footer.OkayButton:HookScript("OnClick", function()
				local r, g, b = ColorPickerFrame:GetColorRGB();
				local UserColor = CreateColor(r, g, b, ColorPickerFrame.previousValues.a or 1);
				local hexColorString = UserColor:GenerateHexColor();
				menuTextColorSetting:SetValue(hexColorString);
			end);

			local menuTextColorButton_OnClick = function()
				-- REF.: <https://www.townlong-yak.com/framexml/live/ColorPickerFrame.lua>
				-- REF.: <https://www.townlong-yak.com/framexml/live/Color.lua>
				local TextColor = CreateColorFromHexString(ns.settings[menuTextColorVarName]);
				local r, g, b, a = TextColor:GetRGBA();
				ColorPickerFrame.hasOpacity = Settings.Default.False;
				ColorPickerFrame.previousValues = {r = r, g = g, b = b, a = a};
				ColorPickerFrame.swatchFunc = function()
					-- **Note:** The ColorPickerFrame needs this function, but we will ignore it.
					-- The current ColorPickerFrame setup triggers too many calls to it!
					-- We're going to use the "OnClick" hook above instead.
				end
				ColorPickerFrame.cancelFunc = function(previousValues)
					local PreviousColor = CreateColor( ColorPickerFrame:GetPreviousValues() );
					local previousHexColorString = PreviousColor:GenerateHexColor();
					menuTextColorSetting:SetValue(previousHexColorString);
				end
				ColorPickerFrame.Content.ColorPicker:SetColorRGB(r, g, b);
				ColorPickerFrame:Show();
			end

			local function OnValueChanged(owner, setting, value)
				local TextColor = CreateColorFromHexString(value);
				printOption(setting.name, TextColor:WrapTextInColorCode(value));
				SaveSingleSetting(setting.variable, value);
			end
			Settings.SetOnValueChangedCallback(menuTextColorVarName, OnValueChanged);

			local menuTextColorTooltip = L.CFG_APPEARANCE_TEXT_COLOR_TOOLTIP..NEWLINE..AppendColorPreviewText(menuTextColorVarName, Settings.Default.True)..AppendColorPreviewText(menuTextColorVarName);
			local menuTextColorButtonInitializer = CreateSettingsButtonInitializer(L.CFG_APPEARANCE_TEXT_COLOR_TEXT, L.CFG_APPEARANCE_COLOR_BUTTON_TEXT, menuTextColorButton_OnClick, menuTextColorTooltip, addSearchTags);
			appearanceLayout:AddInitializer(menuTextColorButtonInitializer);
		end

		-- Font selection dropdown
		-- REF.: <https://www.townlong-yak.com/framexml/live/Blizzard_APIDocumentationGenerated/FontDocumentation.lua>
		do
			local menuTextFontVarName = "menuTextFont";

			local menuTextFontValues = {};
			local menuTextFontValues2 = {};
			local menuTextFontValues3 = {};
			local menuTextFontValues4 = {};
			local menuTextFontValueList = {menuTextFontValues, menuTextFontValues2, menuTextFontValues3, menuTextFontValues4};
			local fontNames = GetFonts();
			sort(fontNames)
			for i, name in ipairs(fontNames) do										--> TODO - Find a more elegant solution. Maybe an external font library?
				local line = {name, name, nil};
				if (i <= 100) then
					tinsert(menuTextFontValues, line);
				end
				if (i > 100 and i <= 200) then
					tinsert(menuTextFontValues2, line);
				end
				if (i > 200 and i <= 300) then
					tinsert(menuTextFontValues3, line);
				end
				if (i > 300 and i <= 382) then
					tinsert(menuTextFontValues4, line);
				end
			end

			local menuTextFontLabel = L.CFG_APPEARANCE_FONT_SELECTION_TEXT..L.TEXT_DELIMITER..PARENS_TEMPLATE:format(L.SELECTION_PART_NUM_D);
			-- Note:
			-- As of now Blizzard only allows 1 variable per each setting control. (2024-08-17)
			-- We need to register 4 variables for each control, but only the above variable holds the current font
			-- value. It remains the "primary" variable which will be saved/loaded by the game.
			for i = 1, #menuTextFontValueList do
				local varName = menuTextFontVarName.."#"..tostring(i);
				ns.settings[varName] = ns.settings[menuTextFontVarName];
				local setting, initializer = DropDown_Create(appearanceCategory, varName, menuTextFontValueList[i],  menuTextFontLabel:format(i), L.CFG_APPEARANCE_FONT_SELECTION_TOOLTIP);
				tinsert(LocalFontUtil.fontSettings, setting);
			end
			--> TODO - Apply font's built-in color as well?
		end

		-- Font size
		local minFontSize, maxFontSize, fontSizeStep = 6, 64, 1;
		Slider_Create(appearanceCategory, "menuTextFontSize", minFontSize, maxFontSize, fontSizeStep, FONT_SIZE, L.CFG_APPEARANCE_FONT_SIZE_TOOLTIP, FontSizeValueFormatter);
	end

	----- MenuTooltip: Dimensions -----
	do
		appearanceLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer(menuNameTemplate:format(L.CFG_APPEARANCE_DIMENSIONS_LABEL)));

		-- MenuTooltip: Frame Width
		local minWidth, maxWidth, widthStep = 64, floor(GetScreenWidth()/3), 1;
		Slider_Create(appearanceCategory, "menuMinWidth", minWidth, maxWidth, widthStep, HUD_EDIT_MODE_SETTING_UNIT_FRAME_WIDTH, L.CFG_APPEARANCE_DIMENSIONS_FRAME_WIDTH_TOOLTIP);

		-- MenuTooltip: Line Height
		local minHeight, maxHeight, heightStep = 0, 64, 1;
		Slider_Create(appearanceCategory, "menuLineHeight", minHeight, maxHeight, heightStep, L.CFG_APPEARANCE_DIMENSIONS_LINE_HEIGHT_TEXT, L.CFG_APPEARANCE_DIMENSIONS_LINE_HEIGHT_TOOLTIP);
	end

	----------------------------------------------------------------------------
	----- About this addon -----------------------------------------------------
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

	local aboutCategory, aboutLayout = Settings.RegisterCanvasLayoutSubcategory(mainCategory, aboutFrame, L.CFG_ABOUT_ADDON_LABEL);
	aboutCategory.ID = aboutFrame.name;
	aboutLayout:AddAnchorPoint("TOPLEFT", 10, -10);
	aboutLayout:AddAnchorPoint("BOTTOMRIGHT", -10, 10);

	------- Add-on infos -------------------------------------------------------

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
		--> label, tag, non-tag-text
		{L.CFG_ADDONINFOS_VERSION, "Version"},
		{L.CFG_ADDONINFOS_AUTHOR, "Author"},
		{L.CFG_ADDONINFOS_HOMEPAGE, nil, " GitHub [1], Wago [2], CurseForge [3], WOWInterface [4]"},
		{"[1]", "X-Project-Repository"},
		{"[2]", "X-Project-Homepage-Wago"},
		{"[3]", "X-Project-Homepage"},
		{"[4]", "X-Project-Homepage-WOWInterface"},
		{L.CFG_ADDONINFOS_LICENSE, "X-License"},
	};
	local contributions = {"zhTW", "enUS"};
	if tContains(contributions, L.currentLocale) then
		tinsert(addonInfos, {L.CFG_ADDONINFOS_L10N_S:format(L.currentLocale), nil, HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(L.CFG_ADDONINFOS_L10N_CONTACT)});
	end
	local parentFrame = mainSubText;
	local labelText, infoLabel;

	for i, infos in ipairs(addonInfos) do
		labelText, infoLabel, infoText = SafeUnpack(infos);
		local metaLabel = aboutFrame:CreateFontString(aboutFrame:GetName().."MetaLabel"..tostring(i), "ARTWORK", "GameFontNormalSmall");
		metaLabel:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 0, -8);
		metaLabel:SetWidth(100);
		metaLabel:SetJustifyH("RIGHT");
		metaLabel:SetText(labelText..HEADER_COLON);

		if infoLabel then
			local metaValue = aboutFrame:CreateFontString(aboutFrame:GetName().."MetaValue"..tostring(i), "ARTWORK", "GameFontHighlightSmall");
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
		end
		if infoText then
			local metaText = aboutFrame:CreateFontString(aboutFrame:GetName().."MetaText"..tostring(i), "ARTWORK", "GameFontNormalSmall");
			metaText:SetPoint("LEFT", metaLabel, "RIGHT", 4, 0);
			metaText:SetJustifyH("LEFT");
			metaText:SetText(infoText);
		end

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
		slashCmdLabel:SetText(slashCmdText..HEADER_COLON);

		local slashCmdHelpLabel = aboutFrame:CreateFontString(aboutFrame:GetName()..strupper(slashCmdText).."Description", "ARTWORK", "GameFontHighlight");
		slashCmdHelpLabel:SetPoint("LEFT", slashCmdLabel, "RIGHT", 4, 0);
		slashCmdHelpLabel:SetText(helpText);

		slashParent = slashCmdLabel;
	end
end

--@do-not-package@
--------------------------------------------------------------------------------
	---- Tests ----

	-- layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Tests"));

	-- local testList = settingSMB.initializer;
	-- for k,v in pairs(testList) do
	-- 	print(k, "-->", v);
	-- end

	-- About button

	-- local sep = layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.CFG_ABOUT_ADDON_LABEL));

	-- -- local warnVar = "warnVar";
	-- -- local warnSetting = CustomRegisterAddOnSetting(category, "Warn message", warnVar, Settings.VarType.Boolean, true);
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

--[[

	-- TEXTURES_SUBHEADER = "Texturen";
	-- BACKGROUND = "Hintergrund";
	-- HUD_EDIT_MODE_SETTING_UNIT_FRAME_ROW_SIZE = "Zeilengröße";
	-- HUD_EDIT_MODE_SETTING_UNIT_FRAME_HEIGHT = "Fensterhöhe";
	-- HUD_EDIT_MODE_SETTING_UNIT_FRAME_WIDTH = "Fensterbreite";
	-- COMPACT_UNIT_FRAME_PROFILE_FRAMEHEIGHT = "Fensterhöhe";
	-- COMPACT_UNIT_FRAME_PROFILE_FRAMEWIDTH = "Fensterbreite";
	-- FONT_SIZE = "Schriftgröße";
	-- FONT_SIZE_TEMPLATE = "%d Pt.";
	-- COLOR = "Farbe";
	-- COLORS = "Farben";
	-- HUD_EDIT_MODE_SETTING_ACTION_BAR_ICON_SIZE = "Symbolgröße";
	-- HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_DOWN = "Unten";
	-- HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_LEFT = "Links";
	-- HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_RIGHT = "Rechts";
	-- HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_UP = "Oben";
	-- 
	-- MAXIMUM = "Maximum";
	-- MINIMUM = "Minimum";

GRAY(APPEARANCE_LABEL..L.TEXT_DELIMITER..PARENS_TEMPLATE:format(FEATURE_NOT_YET_AVAILABLE))

	--> TODO - add more appearance settings (see below)
	-- 	menuHighlightTexture

	-- 	tipScrollStep
	-- 	tipSeparatorLineColor
	-- 	tipHeaderTextJustify
	-- 	tipHeaderTextColor
	-- 	tipHeaderBackgroundColor

	-- show border for settings
	-- add defaults to tooltip


	-- appearanceCategory.tutorial = {
	-- 	tooltip = "This it a tutorial test.",
	-- 	callback = function(buttonTbl, buttonName, isDown)
	-- 		print("Clicked tutorial button:", buttonTbl:GetName(), buttonName, isDown);
	-- 	end
	-- };
	-- appearanceCategory:SetCategoryTutorialInfo("This it a tutorial test.", function(buttonTbl, buttonName, isDown)
	-- 	print("Clicked tutorial button:", buttonTbl:GetName(), buttonName, isDown);
	-- end)

]]--
--------------------------------------------------------------------------------
--@end-do-not-package@