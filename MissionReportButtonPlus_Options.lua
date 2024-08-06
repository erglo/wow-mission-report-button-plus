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

local ExpansionInfo = ns.ExpansionInfo;

local _, addonTitle, addonNotes = C_AddOns.GetAddOnInfo(AddonID);

local sort = table.sort;
local strjoin = strjoin;
local NEWLINE = "|n";
local NEW_PARAGRAPH = "|n|n";
local HEADER_COLON = HEADER_COLON;
local LIST_DELIMITER = LIST_DELIMITER;
local TEXT_DELIMITER = ITEM_NAME_DESCRIPTION_DELIMITER;
-- local TEXT_DASH_SEPARATOR = TEXT_DELIMITER..QUEST_DASH..TEXT_DELIMITER;

local GRAY = function(txt) return GRAY_FONT_COLOR:WrapTextInColorCode(txt) end;
local LIGHT_GRAY = function(txt) return LIGHTGRAY_FONT_COLOR:WrapTextInColorCode(txt) end;

----- User settings ------------------------------------------------------------

ns.settings = {};  --> user settings for currently active game session
ns.defaultSettings = {  --> default + fallback settings
	-- Common
	["showChatNotifications"] = true,
	["showMinimapButton"] = true,
	["showAddonNameInTooltip"] = true,
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
	-- Menu entries
	["activeMenuEntries"] = {"5", "6", "7", "8", "9", "99"},
	-- Dragonflight
	["showMajorFactionRenownLevel"] = true,
	["applyMajorFactionColors"] = true,
	["hideMajorFactionUnlockDescription"] = false,
	["separateMajorFactionTooltip"] = false,
	["showDragonGlyphs"] = true,
	["autoHideCompletedDragonGlyphZones"] = false,
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
---@param text string  The name of a given option
---@param isEnabled boolean|table  The value of given option
---
local function printOption(text, isEnabled)
	local msg = isEnabled and VIDEO_OPTIONS_ENABLED or VIDEO_OPTIONS_DISABLED;
	ns.cprint(text, "-", NORMAL_FONT_COLOR:WrapTextInColorCode(msg));
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

----- Control utilities --------------------------------------------------------

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
			ns:HideMinimapButton();
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
		value = CopyTable(activeEntriesList);

		_log:debug("selectedMenuEntries:", SafeUnpack(ns.settings.activeMenuEntries));
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
	local cbrHandle = Settings.SetOnValueChangedCallback(varName, CheckBox_OnValueChanged, setting);
	--> Note: Handle is needed to unregister this OnValueChanged event, if necessary.

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
		local setting, initializer = CheckBox_Create(category, cb.variable, cb.name, cb.tooltip);
		if cb.tag then
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

local function FormatTooltipTemplate(categoryName, tooltipText, additionalText)
	local needsReloadText = format("|n|n- %s (%s)", HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(REQUIRES_RELOAD), SLASH_RELOAD1);
	local needsUIReload = (not L:IsEnglishLocale(L.currentLocale) and L.defaultLabels[categoryName] == L[categoryName]);
	local formattedText = L.CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP:format(tooltipText or '');
	formattedText = additionalText and formattedText..additionalText or formattedText;
	formattedText = needsUIReload and formattedText..needsReloadText or formattedText;
	return formattedText;
end

local function AppendDefaultValueText(varName)
    local textTemplate = LIGHT_GRAY(NEW_PARAGRAPH..DEFAULT..HEADER_COLON)..TEXT_DELIMITER.."%s";
    local valueString = tostring(ns.defaultSettings[varName]);
    return textTemplate:format(valueString);
end

local function AppendDefaultColorTextLine(varName)
    local TextColor = CreateColorFromHexString(ns.defaultSettings[varName]);
	local textTemplate = NEWLINE.."%s"..TEXT_DELIMITER..LIGHT_GRAY(PARENS_TEMPLATE:format(DEFAULT));
	local exampleText = TextColor:WrapTextInColorCode(PREVIEW);
    return textTemplate:format(exampleText);
end

local function AppendCurrentColorTextLine(varName)
	local TextColor = CreateColorFromHexString(ns.settings[varName]);
    local textTemplate = NEWLINE.."%s"..TEXT_DELIMITER..LIGHT_GRAY(PARENS_TEMPLATE:format(REFORGE_CURRENT));
	local exampleText = TextColor:WrapTextInColorCode(PREVIEW);
    return textTemplate:format(exampleText);
end

local function Slider_Create(category, variableName, minValue, maxValue, step, label, tooltip, formatter)
	local setting = Settings.RegisterAddOnSetting(category, label, variableName, Settings.VarType.Number, ns.defaultSettings[variableName]);

	local options = Settings.CreateSliderOptions(minValue, maxValue, step);
	options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatter);
	local defaultValueTooltip = tooltip..AppendDefaultValueText(variableName);
	-- REF.: Settings.CreateSlider(category, setting, options, tooltip) --> initializer
	local initializer = Settings.CreateSlider(category, setting, options, defaultValueTooltip);

	-- Track and display user changes
	if (ns.settings[variableName] ~= ns.defaultSettings[variableName]) then
		setting:SetValue(ns.settings[variableName]);
	end
	local function OnValueChanged(owner, setting, value)
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

-- local function trimTextLength(text, length)
-- 	if (strlen(text) <= length) then return text; end

-- 	return strsub(text, 1, length);
-- end

-- Show preview of hovered font entry (option)
local function OnEntryEnter_SetFontPreview(optionData)
	local selectedFontObject = _G[optionData.value];
	previewFontString:SetFontObject(selectedFontObject);
end

-- valueList: {{key, label, tooltip_description}, ...}
-- allowed key types: see Settings.VarType
local function DropDown_Create(category, variableName, valueList, defaultText, tooltip)
	local defaultValue = ns.defaultSettings[variableName];
	local currentValue = ns.settings[variableName];
	local varType = type(valueList[1][1])  --> eg. Settings.VarType.String;

	local setting = Settings.RegisterAddOnSetting(category, defaultText, variableName, varType, defaultValue);

	local function GetOptions()
		local container = Settings.CreateControlTextContainer();
		local key, name, tooltip_description;
		for i, item in ipairs(valueList) do
			key, name, tooltip_description = SafeUnpack(item);
			container:Add(key, name, tooltip_description);
		end
		local data = container:GetData();
		for index, optionData in ipairs(data) do
			if (variableName == "menuTextFont") then
				optionData.onEnter = OnEntryEnter_SetFontPreview;
			end
			if (optionData.value == defaultValue) then
				optionData.label = optionData.label..TEXT_DELIMITER..GRAY(PARENS_TEMPLATE:format(DEFAULT));
				-- optionData.recommend = Settings.Default.True;
				-- optionData.disabled = "Disabled text.";
				-- optionData.warning = "Warning text.";
			end
		end
		return data;
	end

	-- if (variableName == "menuTextFont") then
	-- 	print("-->", SettingsSelectionPopoutDetailsMixin.AdjustWidth)
	-- 	SettingsSelectionPopoutDetailsMixin:AdjustWidth(false, 200);
	-- end

	local defaultValueTooltip = tooltip..AppendDefaultValueText(variableName);
	-- REF.: Settings.CreateDropdown(category, setting, options, tooltip) --> initializer
	local initializer = Settings.CreateDropdown(category, setting, GetOptions, defaultValueTooltip);

	-- Track and display user changes
	setting:SetValue(currentValue);
	local function OnValueChanged(owner, settingInfo, value)
		SaveSingleSetting(settingInfo.variable, value);
	end
	Settings.SetOnValueChangedCallback(variableName, OnValueChanged);

	-- Add a font preview frame, but only for the font selection
	if (variableName == "menuTextFont") then
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

function MRBP_Settings_OpenToAddonCategory(categoryID)
	local SettingsPanel = SettingsPanel;
	-- Try Blizzard's way; works usually for addons in main category
	local successful = SettingsPanel:OpenToCategory(categoryID);
	if successful then
		return;
	end
	local function FindCategory(categoryID, categories)
		local categoryList = categories or SettingsPanel:GetAllCategories();
		for _, category in ipairs(categoryList) do
			-- Ignore categories from game settings; subcategories don't seem to have a category set
			if (category.categorySet == Settings.CategorySet.AddOns or category.categorySet == nil) then
				if (category.ID == categoryID) then
					return category;
				end
				-- No luck in main categories, go check subcategories
				if category:HasSubcategories() then
					local categoryTbl = FindCategory(categoryID, category:GetSubcategories());
					if categoryTbl then
						return categoryTbl;
					end
				end
			end
		end
	end
	local categoryTbl = FindCategory(categoryID);
	if categoryTbl then
		SettingsPanel:SelectCategory(categoryTbl);
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
			tag = Settings.Default.True,
		},
		{
			variable = "showTimewalkingVendorHint",
			name = L.CFG_DDMENU_HINT_TIMEWALKING_VENDOR_TEXT,
			tooltip = L.CFG_DDMENU_HINT_TIMEWALKING_VENDOR_TOOLTIP,
			tag = Settings.Default.True,
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
		tag = Settings.Default.True,
	},
};

ExpansionTooltipSettings[ExpansionInfo.data.LEGION.ID] = {
	{
		variable = "showLegionMissionInfo",
		name = L["showLegionMissionInfo"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MISSION_INFO_TOOLTIP,
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
		variable = "applyCovenantColors",
		name = L["applyCovenantColors"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_FACTION_COLORS_TOOLTIP,
	},
};

ExpansionTooltipSettings[ExpansionInfo.data.DRAGONFLIGHT.ID] = {
	{
		variable = "showMajorFactionRenownLevel",
		name = L["showMajorFactionRenownLevel"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MAJOR_FACTION_RENOWN_TOOLTIP,
	},
	{
		variable = "applyMajorFactionColors",
		name = L["applyMajorFactionColors"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_FACTION_COLORS_TOOLTIP,
		parentVariable = "showMajorFactionRenownLevel",
	},
	{
		variable = "hideMajorFactionUnlockDescription",
		name = L["hideMajorFactionUnlockDescription"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_MAJOR_FACTION_UNLOCK_TOOLTIP,
		parentVariable = "showMajorFactionRenownLevel",
	},
	{
		variable = "separateMajorFactionTooltip",
		name = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TEXT,
		tooltip = L.CFG_MAJOR_FACTION_SEPARATE_TOOLTIP_TOOLTIP,
		parentVariable = "showMajorFactionRenownLevel",
		tag = Settings.Default.True,
	},
	{
		variable = "showDragonGlyphs",
		name = L["showDragonGlyphs"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_DRAGON_GLYPHS_TOOLTIP,
	},
	{
		variable = "autoHideCompletedDragonGlyphZones",
		name = L["autoHideCompletedDragonGlyphZones"],
		tooltip = L.CFG_DDMENU_ENTRYTOOLTIP_HIDE_DRAGON_GLYPHS_TOOLTIP,
		parentVariable = "showDragonGlyphs",
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
	--> TODO - Check need for 'ns.settings'; is maybe .GetVariableValue() better?

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
			MRBP_Settings_OpenToAddonCategory(AddonID.."MenuTooltipSettings");
		end
		local menuTooltipButtonLabel = strjoin(LIST_DELIMITER, L.CFG_DDMENU_ENTRYSELECTION_LABEL, L.CFG_DDMENU_SEPARATOR_HEADING);
		local menuTooltipButtonInitializer = CreateSettingsButtonInitializer(menuTooltipButtonLabel, L.CFG_DDMENU_SEPARATOR_HEADING, OnMenuTooltipButtonClick, L.CFG_DDMENU_ENTRYSELECTION_TOOLTIP, addSearchTags);
		mainLayout:AddInitializer(menuTooltipButtonInitializer);
	end

	-- Appearance button
	do
		local OnAppearanceButtonClick = function()
			MRBP_Settings_OpenToAddonCategory(AddonID.."AppearanceSettings");
		end
		local appearanceButtonLabel = strjoin(LIST_DELIMITER, HUD_EDIT_MODE_SETTING_MICRO_MENU_SIZE, FONT_SIZE);
		local appearanceButtonInitializer = CreateSettingsButtonInitializer(appearanceButtonLabel, APPEARANCE_LABEL, OnAppearanceButtonClick, FEATURE_NOT_YET_AVAILABLE, addSearchTags);
		mainLayout:AddInitializer(appearanceButtonInitializer);
		appearanceButtonInitializer.IsNewTagShown = function() return Settings.Default.True end;
	end

	-- Details tooltip option shortcuts (Expansion buttons)
	do
		mainLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.CFG_DDMENU_ENTRYTOOLTIP_LABEL));
		for _, expansionInfo in ipairs(GetOwnedExpansionInfoList()) do
			local categoryID = format("%sExpansion%02dSettings", AddonID, expansionInfo.ID);
			local OnExpansionButtonClick = function()
				MRBP_Settings_OpenToAddonCategory(AddonID.."MenuTooltipSettings");
				MRBP_Settings_OpenToAddonCategory(categoryID);
			end
			local expansionButtonInitializer = CreateSettingsButtonInitializer('', expansionInfo.name, OnExpansionButtonClick, '', addSearchTags);
			mainLayout:AddInitializer(expansionButtonInitializer);
		end
	end

	-- About frame button
	do
		mainLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.CFG_ABOUT_ADDON_LABEL));
		local OnAboutButtonClick = function()
			MRBP_Settings_OpenToAddonCategory(AddonID.."AboutFrame");
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
	if ns.settings.showEntryTooltip then
		for _, expansionInfo in ipairs(GetOwnedExpansionInfoList()) do
			-- Register expansion in its own subcategory
			local expansionCategory, expansionLayout = Settings.RegisterVerticalLayoutSubcategory(menuTooltipCategory, expansionInfo.name);
			expansionCategory.ID = format("%sExpansion%02dSettings", AddonID, expansionInfo.ID);
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

	----- MenuTooltip appearance -----

	local menuNameTemplate = GRAY(L.CFG_DDMENU_SEPARATOR_HEADING..HEADER_COLON)..TEXT_DELIMITER.."%s";
	appearanceLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer(menuNameTemplate:format("Dimensionen")));

	-- MenuTooltip: Width
	do
		local minValue, maxValue, step = 64, 320, 1;
		local label = HUD_EDIT_MODE_SETTING_UNIT_FRAME_WIDTH;
		Slider_Create(appearanceCategory, "menuMinWidth", minValue, maxValue, step, label, "Mindestbreite festlegen");  --> TODO - L10n
	end

	-- MenuTooltip: Line Height
	do																			--> TODO - L10n
		local minValue, maxValue, step = 0, 32, 1;
		Slider_Create(appearanceCategory, "menuLineHeight", minValue, maxValue, step, "Line Height", "Zeilenhöhe festlegen.");
	end

	----- MenuTooltip: Text -----
	do																			--> TODO - L10n
		appearanceLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer(menuNameTemplate:format(LOCALE_TEXT_LABEL)));

		-- Alignment
		local alignValues = {
			{"LEFT", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_LEFT, nil},
			{"CENTER", "Center", nil},
			{"RIGHT", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_RIGHT, nil},
		};
		local alignLabel = HUD_EDIT_MODE_SETTING_MICRO_MENU_ORIENTATION;
		DropDown_Create(appearanceCategory, "menuTextAlignment", alignValues, alignLabel, "Align names to this side.");

		-- Padding (Left)
		local padLeftMinValue, padLeftMaxValue, padLeftStep = 0, 64, 1;
		local padLeftLabel = format("Padding (%s)", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_LEFT);
		Slider_Create(appearanceCategory, "menuTextPaddingLeft", padLeftMinValue, padLeftMaxValue, padLeftStep, padLeftLabel, "Textabstand links festlegen.");

		-- Padding (Right)
		local padRightMinValue, padRightMaxValue, padRightStep = 0, 64, 1;
		local padRightLabel = format("Padding (%s)", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_RIGHT);
		Slider_Create(appearanceCategory, "menuTextPaddingRight", padRightMinValue, padRightMaxValue, padRightStep, padRightLabel, "Textabstand rechts festlegen.");

		-- Text Color
		do
			local menuTextColorVarName = "menuTextColor";

			ColorPickerFrame.Footer.OkayButton:HookScript("OnClick", function()
				local r, g, b = ColorPickerFrame:GetColorRGB();
				local UserColor = CreateColor(r, g, b, ColorPickerFrame.previousValues.a or 1);
				local hexColorString = UserColor:GenerateHexColor();
				SaveSingleSetting(menuTextColorVarName, hexColorString);
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
					SaveSingleSetting(menuTextColorVarName, PreviousColor:GenerateHexColor());
				end
				ColorPickerFrame.Content.ColorPicker:SetColorRGB(r, g, b);
				ColorPickerFrame:Show();
			end
			local menuTextColorLabel = "Text Color";
			local menuTextColorTooltip = "Choose a font color."..NEWLINE..AppendDefaultColorTextLine(menuTextColorVarName)..AppendCurrentColorTextLine(menuTextColorVarName);
			local menuTextColorButtonInitializer = CreateSettingsButtonInitializer(menuTextColorLabel, "Choose a color...", menuTextColorButton_OnClick, menuTextColorTooltip, addSearchTags);
			appearanceLayout:AddInitializer(menuTextColorButtonInitializer);
		end

		-- Font selection dropdown
		-- REF.: <https://www.townlong-yak.com/framexml/live/Blizzard_APIDocumentationGenerated/FontDocumentation.lua>
		local menuTextFontVarName = "menuTextFont";

		local menuTextFontValues = {};
		local GetFontNames = function()
			local fonts = GetFonts();
			local newFonts = {};
			for i = 1, 10 do
				tinsert(newFonts, fonts[i]);
			end
			sort(newFonts);
			return newFonts;
		end
		for i, name in ipairs(GetFontNames()) do
			local line = {name, name, nil};
			tinsert(menuTextFontValues, line);
		end
		DropDown_Create(appearanceCategory, menuTextFontVarName, menuTextFontValues, "Schriftart", "Choose the font of your liking.");
	end

	------- MenuTooltip: Anchor -----
	do																			--> TODO - L10n
		appearanceLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer(menuNameTemplate:format("Ankerpunkt")));
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
		local pointLabel = "Anchor Point"..HEADER_COLON..TEXT_DELIMITER..L.CFG_DDMENU_SEPARATOR_HEADING;
		DropDown_Create(appearanceCategory, "menuAnchorPoint", pointValues, pointLabel, "The right-click menu's anchor point.");

		-- relativePoint
		local parentPointLabel = "Anchor Point"..HEADER_COLON..TEXT_DELIMITER.."Minimap Button";
		DropDown_Create(appearanceCategory, "menuAnchorPointParent", pointValues, parentPointLabel, "The minimap button's anchor point.");

		-- offsetX
		local minOffsetXValue, maxOffsetXValue, offsetXStep = -64, 64, 1;
		local offsetXLabel = "Distance (H)";  -- "Anchor Point"..HEADER_COLON..TEXT_DELIMITER.."Distance (H)";
		Slider_Create(appearanceCategory, "menuAnchorOffsetX", minOffsetXValue, maxOffsetXValue, offsetXStep, offsetXLabel, "Horizontaler Abstand zum Minikarten-Button.");

		-- offsetY
		local minOffsetYValue, maxOffsetYValue, offsetYStep = -64, 64, 1;
		local offsetYLabel = "Distance (V)";  -- "Anchor Point"..HEADER_COLON..TEXT_DELIMITER.."Distance (V)";
		Slider_Create(appearanceCategory, "menuAnchorOffsetY", minOffsetYValue, maxOffsetYValue, offsetYStep, offsetYLabel, "Vertikaler Abstand zum Minikarten-Button.");
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

GRAY(APPEARANCE_LABEL..TEXT_DELIMITER..PARENS_TEMPLATE:format(FEATURE_NOT_YET_AVAILABLE))

	--> TODO - (see below)
	-- 	menuHighlightTexture

	-- 	tipScrollStep
	-- 	tipSeparatorLineColor
	-- 	tipHeaderTextJustify
	-- 	tipHeaderTextColor
	-- 	tipHeaderBackgroundColor

	-- show border for settings
	-- add defaults to tooltip
]]--
--------------------------------------------------------------------------------
--@end-do-not-package@