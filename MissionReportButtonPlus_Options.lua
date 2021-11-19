--------------------------------------------------------------------------------
--[[ Mission Report Button Plus - Interface Options ]]--
--
-- by erglo <erglo.coder@gmail.com>
--
-- Copyright (C) 2021  Erwin D. Glockner (aka erglo)
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
-- REF.: <FrameXML/InterfaceOptionsFrame.lua>
-- REF.: <FrameXML/InterfaceOptionsPanels.lua>
-- REF.: <FrameXML/OptionsPanelTemplates.lua>
-- REF.: <FrameXML/UIDropDownMenu.lua>
--
--------------------------------------------------------------------------------

local AddonID, ns = ...;
local L = ns.L;
local _log = ns.dbg_logger;
local util = ns.utilities;

----- User settings ------------------------------------------------------------

ns.settings = {};  --> user settings for current char
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

-- Loads the saved settings dynamically.
-- Note: ns.settings always holds ALL setting infos after loading.
--
-- REF.: <FrameXML/TableUtil.lua>
local function LoadSettings()
	_log:info("Loading settings...");
	-- Step 1 - Load the default settings first and
	-- overwrite each entry of the user settings with
	-- those from the global and char-specific settings.
	ns.settings = CopyTable(ns.defaultSettings);
	_log:debug(format(".. defaults loaded: %d settings.", util:tcount(ns.settings)));

	-- Step 2 - Load global settings
	if (MRBP_GlobalSettings == nil) then
		-- Init. table for account-wide settings
		MRBP_GlobalSettings = {};
	else
		-- Update settings with the globally saved values
		MergeTable(ns.settings, MRBP_GlobalSettings);
		_log:debug(".. updated by account-wide (global) settings");
	end

	-- Step 3 - Load character-specific settings
	if (MRBP_PerCharSettings == nil) then
		-- Init. table for individual settings
		MRBP_PerCharSettings = {};
	else
		-- Update settings with current char's values
		MergeTable(ns.settings, MRBP_PerCharSettings);
		_log:debug(".. updated by character-specific settings");
	end

	--[[ Maintenance ]]--

	-- Clean-up old settings from the saved variables, eg.
	-- from previous versions to avoid clutter. Only keep
	-- entries which exist in the default settings as well.
	for key, value in pairs(ns.settings) do
		if ( ns.defaultSettings[key] == nil ) then
			ns.settings[key] = nil;
			_log:debug("Removed old setting:", key);
		end
	end

	_log:info("Settings are up-to-date.");
end

-- Set the settings of the current char as default (global) setting
-- for all other chars.
local function SetAsGlobalSettings()
	_log:info("Setting current settings globally");
	MRBP_GlobalSettings = CopyTable(MRBP_PerCharSettings);
end

-- Save user settings dynamically; If current char settings differ
-- from global settings, create individual settings.
local function SaveSettings()
	-- Compare with global and default settings and save only changed values.
	_log:info("Saving current char's settings...");
	for key, value in pairs(ns.settings) do
		MRBP_PerCharSettings[key] = nil;  -- Reset previous value
		-- local valueIsTable = type(value) == "table";							--> TODO - Add table values comparison
		if (MRBP_GlobalSettings[key] == nil) then
			if (ns.defaultSettings[key] ~= value ) then
				MRBP_PerCharSettings[key] = value;
				_log:debug(".. saved char setting:", key, "-->", value, "def:", ns.defaultSettings[key]);
			end
		else
			if (MRBP_GlobalSettings[key] ~= value) then
				MRBP_PerCharSettings[key] = value;
				_log:debug(".. saved char setting:", key, "-->", value, "glob:", MRBP_GlobalSettings[key]);
			end
		end
	end
	-- On first use, set a char-settings also as global settings
	if (util:tcount(MRBP_GlobalSettings) == 0) then
		_log:debug(".. global settings are empty; using current ones.")
		SetAsGlobalSettings();
	end
	_log:info("Done saving.");
end

-- Print a user-friendly chat message about the currently selected setting.
local function printOption(text, isEnabled, ignore)
	if (not ignore) then
		local msg = isEnabled and VIDEO_OPTIONS_ENABLED or VIDEO_OPTIONS_DISABLED;  --> WoW global strings
		ns.cprint(text, "-", NORMAL_FONT_COLOR:WrapTextInColorCode(msg));
	end
end

-- Set given value to a checkbutton, but only on manual change.
-- Note: 'value' is for some reason a binary string value. This function
-- changes it into a real boolean value.
local function CheckButton_SetValue(control, value, isRefreshing, isCancelled)
	local booleanValue = value and value ~= "0";
	if (not isRefreshing) then
		control.newValue = booleanValue;
	end
	control:SetChecked(booleanValue);

	_log:debug("value:", value, "-->", booleanValue, control:GetValue());

	if (ns.settings.showChatNotifications and not isRefreshing) then
		-- Print user feedback on selected setting to chat
		printOption(control.text:GetText(), booleanValue, isCancelled);
	end
	if (control.varname == "showChatNotifications" and not isRefreshing) then
		if not booleanValue then
			printOption(control.text:GetText(), booleanValue, isCancelled);
			_log.level = _log.NOTSET;  --> silent
		else
			_log.level = _log.USER;  --> verbose
			printOption(control.text:GetText(), booleanValue, isCancelled);
		end
	end
	if (control.varname == "showMinimapButton" and not isRefreshing) then
		-- Manually set by user
		local shouldShowMinimapButton = control.newValue;
		if shouldShowMinimapButton then
			ns:ShowMinimapButton_User(isCancelled);
		else
			ns:HideMinimapButton();
		end
	end

	ns.settings[control.varname] = booleanValue;
	--> for user preview only; this will be undone, when user clicks "Cancel".
end

-- Converts binary string values to real boolean values.
local function CheckButton_GetValue(control)
	local binaryStringValue = BlizzardOptionsPanel_CheckButton_GetSetting(control);
	local booleanValue = binaryStringValue and binaryStringValue ~= "0";

	_log:debug("GetValue:", binaryStringValue, type(binaryStringValue), "-->", booleanValue, type(booleanValue));

	return booleanValue;
end

----- Interface options --------------------------------------------------------

MRBP_InterfaceOptionsPanel = CreateFrame("Frame", "MissionReportButtonPlusInterfaceOptionsFrame");

function MRBP_InterfaceOptionsPanel:Initialize()
	----------------------------------------------------------------------------
	-- Main Interface Options
	--
	-- REF.: <FrameXML/InterfaceOptionsFrame.lua>
	----------------------------------------------------------------------------
	local _, addonTitle, addonNotes = GetAddOnInfo(AddonID);
	local panelContainerWidth = InterfaceOptionsFramePanelContainer:GetWidth() - 32;

	self.name = addonTitle;
	self.labelTitle = addonTitle;
	self.labelDesc = addonNotes;
	self.okay = function(self)
		-- Optional function
		-- This method will run when the player clicks "okay" in the Interface Options.
		_log:info("Applying changed options...");
		SaveSettings();
	end
	self.cancel = function(self)
		-- Optional function
		-- This method will run when the player clicks "cancel" in the Interface Options.
		-- Use this to revert their changes.
		-- Note: Do NOT use control.value since BlizzardOptionsPanel_* functions are
		-- messing them up. They only use the string values of 0 and 1: "0" and "1".
		for i, control in ipairs(self.controls) do
			if (control.newValue ~= nil) then
				ns.settings[control.varname] = not control.newValue;  --> restore value
				_log:info("Restoring", control.varname, control.newValue, "-", ns.settings[control.varname]);
				control.newValue = nil;
				local isCancelled = true;
				control:SetValue(ns.settings[control.varname], nil, isCancelled);
			end
		end
	end
	self.default = function(self)
		-- Optional function
		-- This method will run when the player clicks "defaults". Use this to revert their changes to your defaults.
		_log:info("Restoring default settings...");
		MRBP_GlobalSettings = {};
		MRBP_PerCharSettings = {};
		ns.settings = {};
		LoadSettings();
	end
	self.refresh = function(self)
		-- Optional function
		-- This method will run when the Interface Options frame calls its OnShow function and after defaults
		-- have been applied via the panel.default method described above.
		-- Use this to refresh your panel's UI in case settings were changed without player interaction.
		_log:info("Refreshing options...");
		local isRefreshing = true;
		for i, control in ipairs(self.controls) do
			control.newValue = nil;  --> reset to remember temp./cancel-able settings
			if (control.type == CONTROLTYPE_CHECKBOX) then
				local value = ns.settings[control.varname];
				control:SetValue(value, isRefreshing);
				_log:debug(i, control.varname, ns.settings[control.varname], value);
				if control.dependentControls then
					for _, subcontrol in ipairs(control.dependentControls) do
						-- if control:GetChecked() then
						if (value and ns.settings.showMinimapButton) then
							local isWhiteTextColor = true;
							BlizzardOptionsPanel_CheckButton_Enable(subcontrol, isWhiteTextColor);
						else
							BlizzardOptionsPanel_CheckButton_Disable(subcontrol);
						end
					end
				end
				if (control.varname == "showMinimapButton") then  --> temporary solution for beta2
					-- Show config button disabled if no command table is unlocked
					if (ns.settings.disableShowMinimapButtonSetting == false) then
						local isWhiteColor = true;
						BlizzardOptionsPanel_CheckButton_Enable(control, isWhiteColor);
					else
						BlizzardOptionsPanel_CheckButton_Disable(control);
					end
				end
			elseif ( control.type == CONTROLTYPE_DROPDOWN ) then
				-- ns.settings[control.varname] = ns.settings[control.varname];
				control:RefreshValues();
			end
		end
	end

	InterfaceOptions_AddCategory(self);

	LoadSettings();

	--[[ Add-on infos ]]--

	local mainTitle = self:CreateFontString(self:GetName().."Title", "ARTWORK", "GameFontNormalLarge");
	mainTitle:SetJustifyH("LEFT");
	mainTitle:SetJustifyV("TOP");
	mainTitle:SetPoint("TOPLEFT", 16, -16);
	mainTitle:SetText(self.labelTitle);

	local mainSubText = self:CreateFontString(self:GetName().."SubText", "ARTWORK", "GameFontHighlightSmall");
	mainSubText:SetJustifyH("LEFT");
	mainSubText:SetJustifyV("TOP");
	mainSubText:SetHeight(22);
	mainSubText:SetNonSpaceWrap(true);
	mainSubText:SetMaxLines(2);
	mainSubText:SetPoint("TOPLEFT", mainTitle, "BOTTOMLEFT", 0, -8);
	mainSubText:SetPoint("RIGHT", -32, 0);
	mainSubText:SetText(string.gsub(self.labelDesc, "[|\\]n", " "));  --> replace line break with space

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
		local metaLabel = self:CreateFontString(self:GetName()..infoLabel.."Label", "ARTWORK", "GameFontNormalSmall");
		metaLabel:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 0, -8);
		metaLabel:SetWidth(panelContainerWidth/4);
		metaLabel:SetJustifyH("RIGHT");
		metaLabel:SetText( NORMAL_FONT_COLOR:WrapTextInColorCode(labelText..HEADER_COLON) );  --> WoW global string

		local metaValue = self:CreateFontString(self:GetName()..infoLabel.."Value", "ARTWORK", "GameFontHighlightSmall");
		metaValue:SetPoint("LEFT", metaLabel, "RIGHT", 4, 0);
		metaValue:SetWidth(panelContainerWidth/1.5);
		metaValue:SetJustifyH("LEFT");
		if ( infoLabel == "Author" ) then
			-- Append author's email address behind name
			local authorName, authorMail = GetAddOnMetadata(AddonID, infoLabel), GetAddOnMetadata(AddonID, "X-Email");
			metaValue:SetText( string.format("%s <%s>", authorName, authorMail) );
		else
			metaValue:SetText( GetAddOnMetadata(AddonID, infoLabel) );
		end
		--> TODO - Make email and website links clickable.

		parentFrame = metaLabel;
	end

	local separatorTexture = self:CreateTexture(self:GetName().."Separator", "ARTWORK");
	separatorTexture:SetSize(panelContainerWidth, 1);
	separatorTexture:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 0, -12);
	separatorTexture:SetColorTexture(0.25, 0.25, 0.25);

	--[[ General settings ]]--

	local chatMsgCB = CreateFrame("CheckButton", self:GetName().."ChatMsgCB", self, "InterfaceOptionsCheckButtonTemplate");
	chatMsgCB:SetPoint("TOPLEFT", separatorTexture, "BOTTOMLEFT", 0, -12);
	chatMsgCB.type = CONTROLTYPE_CHECKBOX;
	chatMsgCB.text = _G[chatMsgCB:GetName().."Text"];
	chatMsgCB.text:SetText(L.CFG_CHAT_NOTIFY_TEXT);
	chatMsgCB.tooltipText = L.CFG_CHAT_NOTIFY_TOOLTIP;
	chatMsgCB.varname = "showChatNotifications";
	chatMsgCB.GetValue = CheckButton_GetValue;
	chatMsgCB.SetValue = CheckButton_SetValue;
	BlizzardOptionsPanel_RegisterControl(chatMsgCB, self);

	local showMinimapButtonCB = CreateFrame("CheckButton", self:GetName().."ShowMinimapButtonCB", self, "InterfaceOptionsCheckButtonTemplate");
	showMinimapButtonCB:SetPoint("LEFT", chatMsgCB, "LEFT", (panelContainerWidth/2)-16, 0);
	showMinimapButtonCB.type = CONTROLTYPE_CHECKBOX;
	showMinimapButtonCB.text = _G[showMinimapButtonCB:GetName().."Text"];
	showMinimapButtonCB.text:SetText(strjoin(" ", L.CFG_MINIMAPBUTTON_SHOWBUTTON_TEXT, GRAY_FONT_COLOR:WrapTextInColorCode(L.WORK_IS_EXPERIMENTAL)));
	showMinimapButtonCB.tooltipText = strjoin("|n|n", L.CFG_MINIMAPBUTTON_SHOWBUTTON_TOOLTIP, L.WORK_IS_EXPERIMENTAL_TOOLTIP_ADDITION);
	showMinimapButtonCB.varname = "showMinimapButton";
	showMinimapButtonCB.GetValue = CheckButton_GetValue;
	showMinimapButtonCB.SetValue = CheckButton_SetValue;
	showMinimapButtonCB:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true);
	end);
	showMinimapButtonCB:SetScript("OnLeave", GameTooltip_Hide);
	BlizzardOptionsPanel_RegisterControl(showMinimapButtonCB, self);

	local addonNameCB = CreateFrame("CheckButton", self:GetName().."AddonNameCB", self, "InterfaceOptionsCheckButtonTemplate");
	addonNameCB:SetPoint("TOPLEFT", chatMsgCB, "BOTTOMLEFT", 0, -8);
	addonNameCB.type = CONTROLTYPE_CHECKBOX;  --> WoW global
	addonNameCB.text = _G[addonNameCB:GetName().."Text"];
	addonNameCB.text:SetText(L.CFG_MINIMAPBUTTON_SHOWNAMEINTOOLTIP_TEXT);
	addonNameCB.tooltipText = L.CFG_MINIMAPBUTTON_SHOWNAMEINTOOLTIP_TOOLTIP;
	addonNameCB.varname = "showAddonNameInTooltip";  --> Links this checkbutton with a saved variable
	addonNameCB.GetValue = CheckButton_GetValue;
	addonNameCB.SetValue = CheckButton_SetValue;
	BlizzardOptionsPanel_RegisterControl(addonNameCB, self);
	BlizzardOptionsPanel_SetupDependentControl(showMinimapButtonCB, addonNameCB);

	--> TODO - Hide WoD garrison invasion badge (GarrisonLandingPage.InvasionBadge)

	--[[ Dropdown menu settings ]]--

	local dropdownHeading = self:CreateFontString(self:GetName().."DropdownHeading", "ARTWORK", "GameFontNormal");
	dropdownHeading:SetPoint("TOPLEFT", addonNameCB, "BOTTOMLEFT", 0, -12);
	dropdownHeading:SetJustifyH("LEFT");
	dropdownHeading:SetJustifyV("TOP");
	dropdownHeading:SetText(L.CFG_DDMENU_SEPARATOR_HEADING);

	local sepTexDropdown = self:CreateTexture(self:GetName().."DropdownSeparator", "ARTWORK");
	sepTexDropdown:SetSize(panelContainerWidth-dropdownHeading:GetWidth()-8, 1);
	sepTexDropdown:SetPoint("LEFT", dropdownHeading, "RIGHT", 8, 0);
	sepTexDropdown:SetColorTexture(0.25, 0.25, 0.25);

	local entryNameCB = CreateFrame("CheckButton", self:GetName().."EntryNameCB", self, "InterfaceOptionsCheckButtonTemplate");
	entryNameCB:SetPoint("TOPLEFT", dropdownHeading, "BOTTOMLEFT", 0, -12);
	entryNameCB.type = CONTROLTYPE_CHECKBOX;
	entryNameCB.text = _G[entryNameCB:GetName().."Text"];
	entryNameCB.text:SetText(L.CFG_DDMENU_NAMING_TEXT);
	entryNameCB.tooltipText = L.CFG_DDMENU_NAMING_TOOLTIP;
	entryNameCB.varname = "preferExpansionName";
	entryNameCB.GetValue = CheckButton_GetValue;
	entryNameCB.SetValue = CheckButton_SetValue;
	BlizzardOptionsPanel_RegisterControl(entryNameCB, self);
	BlizzardOptionsPanel_SetupDependentControl(showMinimapButtonCB, entryNameCB);

	local sortorderCB = CreateFrame("CheckButton", self:GetName().."SortorderCB", self, "InterfaceOptionsCheckButtonTemplate");
	sortorderCB:SetPoint("TOPLEFT", entryNameCB, "BOTTOMLEFT", 0, -8);
	sortorderCB.type = CONTROLTYPE_CHECKBOX;
	sortorderCB.text = _G[sortorderCB:GetName().."Text"];
	sortorderCB.text:SetText(L.CFG_DDMENU_SORTORDER_TEXT);
	sortorderCB.tooltipText = L.CFG_DDMENU_SORTORDER_TOOLTIP;
	sortorderCB.varname = "reverseSortorder";
	sortorderCB.GetValue = CheckButton_GetValue;
	sortorderCB.SetValue = CheckButton_SetValue;
	BlizzardOptionsPanel_RegisterControl(sortorderCB, self);
	BlizzardOptionsPanel_SetupDependentControl(showMinimapButtonCB, sortorderCB);

	local missionReportIconCB = CreateFrame("CheckButton", self:GetName().."MissionReportIconCB", self, "InterfaceOptionsCheckButtonTemplate");
	missionReportIconCB:SetPoint("TOPLEFT", sortorderCB, "BOTTOMLEFT", 0, -8);
	missionReportIconCB.type = CONTROLTYPE_CHECKBOX;
	missionReportIconCB.text = _G[missionReportIconCB:GetName().."Text"];
	missionReportIconCB.text:SetText(L.CFG_DDMENU_REPORTICONS_TEXT);
	missionReportIconCB.tooltipText = L.CFG_DDMENU_REPORTICONS_TOOLTIP;
	missionReportIconCB.varname = "showMissionTypeIcons";
	missionReportIconCB.GetValue = CheckButton_GetValue;
	missionReportIconCB.SetValue = CheckButton_SetValue;
	BlizzardOptionsPanel_RegisterControl(missionReportIconCB, self);
	BlizzardOptionsPanel_SetupDependentControl(showMinimapButtonCB, missionReportIconCB);

	local entryHintCB = CreateFrame("CheckButton", self:GetName().."EntryHintCB", self, "InterfaceOptionsCheckButtonTemplate");
	entryHintCB:SetPoint("TOPLEFT", missionReportIconCB, "BOTTOMLEFT", 0, -8);
	entryHintCB.type = CONTROLTYPE_CHECKBOX;
	entryHintCB.text = _G[entryHintCB:GetName().."Text"];
	entryHintCB.text:SetText(L.CFG_DDMENU_ICONHINT_TEXT);
	entryHintCB.tooltipText = L.CFG_DDMENU_ICONHINT_TOOLTIP;
	entryHintCB.varname = "showMissionCompletedHint";
	entryHintCB.GetValue = CheckButton_GetValue;
	entryHintCB.SetValue = CheckButton_SetValue;
	BlizzardOptionsPanel_RegisterControl(entryHintCB, self);
	BlizzardOptionsPanel_SetupDependentControl(showMinimapButtonCB, entryHintCB);

	local entryHintAllCB = CreateFrame("CheckButton", self:GetName().."EntryHintAllCB", self, "InterfaceOptionsCheckButtonTemplate");
	entryHintAllCB:SetPoint("TOPLEFT", entryHintCB, "BOTTOMLEFT", 16, -8);
	entryHintAllCB.type = CONTROLTYPE_CHECKBOX;
	entryHintAllCB.text = _G[entryHintAllCB:GetName().."Text"];
	entryHintAllCB.text:SetText(L.CFG_DDMENU_ICONHINTALL_TEXT);
	entryHintAllCB.tooltipText = L.CFG_DDMENU_ICONHINTALL_TOOLTIP;
	entryHintAllCB.varname = "showMissionCompletedHintOnlyForAll";
	entryHintAllCB.GetValue = CheckButton_GetValue;
	entryHintAllCB.SetValue = CheckButton_SetValue;
	BlizzardOptionsPanel_RegisterControl(entryHintAllCB, self);
	BlizzardOptionsPanel_SetupDependentControl(entryHintCB, entryHintAllCB);
	BlizzardOptionsPanel_SetupDependentControl(showMinimapButtonCB, entryHintAllCB);

	--[[ Menu entries' tooltip ]]--

	local entryTooltipCB = CreateFrame("CheckButton", self:GetName().."EntryTooltipCB", self, "InterfaceOptionsCheckButtonTemplate");
	entryTooltipCB:SetPoint("LEFT", entryNameCB, "LEFT", (panelContainerWidth/2)-16, 0);
	entryTooltipCB.type = CONTROLTYPE_CHECKBOX;
	entryTooltipCB.text = _G[entryTooltipCB:GetName().."Text"];
	entryTooltipCB.text:SetText(L.CFG_DDMENU_ENTRYTOOLTIP_SHOW_TEXT);
	entryTooltipCB.tooltipText = L.CFG_DDMENU_ENTRYTOOLTIP_SHOW_TOOLTIP;
	entryTooltipCB.varname = "showEntryTooltip";
	entryTooltipCB.GetValue = CheckButton_GetValue;
	entryTooltipCB.SetValue = CheckButton_SetValue;
	BlizzardOptionsPanel_RegisterControl(entryTooltipCB, self);
	BlizzardOptionsPanel_SetupDependentControl(showMinimapButtonCB, entryTooltipCB);

	local entryTooltipInProgressCB = CreateFrame("CheckButton", self:GetName().."EntryTooltipInProgressCB", self, "InterfaceOptionsCheckButtonTemplate");
	entryTooltipInProgressCB:SetPoint("TOPLEFT", entryTooltipCB, "BOTTOMLEFT", 16, -8);
	entryTooltipInProgressCB.type = CONTROLTYPE_CHECKBOX;
	entryTooltipInProgressCB.text = _G[entryTooltipInProgressCB:GetName().."Text"];
	entryTooltipInProgressCB.text:SetText(L.CFG_DDMENU_ENTRYTOOLTIP_INPROGRESS_TEXT);
	entryTooltipInProgressCB.tooltipText = L.CFG_DDMENU_ENTRYTOOLTIP_INPROGRESS_TOOLTIP;
	entryTooltipInProgressCB.varname = "showMissionCountInTooltip";
	entryTooltipInProgressCB.GetValue = CheckButton_GetValue;
	entryTooltipInProgressCB.SetValue = CheckButton_SetValue;
	BlizzardOptionsPanel_RegisterControl(entryTooltipInProgressCB, self);
	BlizzardOptionsPanel_SetupDependentControl(entryTooltipCB, entryTooltipInProgressCB);
	BlizzardOptionsPanel_SetupDependentControl(showMinimapButtonCB, entryTooltipInProgressCB);

	local entryTooltipBountiesCB = CreateFrame("CheckButton", self:GetName().."EntryTooltipBountiesCB", self, "InterfaceOptionsCheckButtonTemplate");
	entryTooltipBountiesCB:SetPoint("TOPLEFT", entryTooltipInProgressCB, "BOTTOMLEFT", 0, -8);
	entryTooltipBountiesCB.type = CONTROLTYPE_CHECKBOX;
	entryTooltipBountiesCB.text = _G[entryTooltipBountiesCB:GetName().."Text"];
	entryTooltipBountiesCB.text:SetText(L.CFG_DDMENU_ENTRYTOOLTIP_BOUNTIES_TEXT);
	entryTooltipBountiesCB.tooltipText = L.CFG_DDMENU_ENTRYTOOLTIP_BOUNTIES_TOOLTIP;
	entryTooltipBountiesCB.varname = "showWorldmapBounties";
	entryTooltipBountiesCB.GetValue = CheckButton_GetValue;
	entryTooltipBountiesCB.SetValue = CheckButton_SetValue;
	BlizzardOptionsPanel_RegisterControl(entryTooltipBountiesCB, self);
	BlizzardOptionsPanel_SetupDependentControl(entryTooltipCB, entryTooltipBountiesCB);
	BlizzardOptionsPanel_SetupDependentControl(showMinimapButtonCB, entryTooltipBountiesCB);

	local entryBountyReqCB = CreateFrame("CheckButton", self:GetName().."EntryBountyRequirementsCB", self, "InterfaceOptionsCheckButtonTemplate");
	entryBountyReqCB:SetPoint("TOPLEFT", entryTooltipBountiesCB, "BOTTOMLEFT", 16, -8);
	entryBountyReqCB.type = CONTROLTYPE_CHECKBOX;
	entryBountyReqCB.text = _G[entryBountyReqCB:GetName().."Text"];
	entryBountyReqCB.text:SetText(L.CFG_DDMENU_ENTRYTOOLTIP_BOUNTYREQUIREMENTS_TEXT);
	entryBountyReqCB.tooltipText = L.CFG_DDMENU_ENTRYTOOLTIP_BOUNTYREQUIREMENTS_TOOLTIP;
	entryBountyReqCB.varname = "showBountyRequirements";
	entryBountyReqCB.GetValue = CheckButton_GetValue;
	entryBountyReqCB.SetValue = CheckButton_SetValue;
	BlizzardOptionsPanel_RegisterControl(entryBountyReqCB, self);
	BlizzardOptionsPanel_SetupDependentControl(entryTooltipBountiesCB, entryBountyReqCB);
	BlizzardOptionsPanel_SetupDependentControl(showMinimapButtonCB, entryBountyReqCB);

	local entryTooltipThreatsCB = CreateFrame("CheckButton", self:GetName().."EntryTooltipThreatsCB", self, "InterfaceOptionsCheckButtonTemplate");
	entryTooltipThreatsCB:SetPoint("TOPLEFT", entryBountyReqCB, "BOTTOMLEFT", -16, -8);
	entryTooltipThreatsCB.type = CONTROLTYPE_CHECKBOX;
	entryTooltipThreatsCB.text = _G[entryTooltipThreatsCB:GetName().."Text"];
	entryTooltipThreatsCB.text:SetText(L.CFG_DDMENU_ENTRYTOOLTIP_THREATS_TEXT);
	entryTooltipThreatsCB.tooltipText = L.CFG_DDMENU_ENTRYTOOLTIP_THREATS_TOOLTIP;
	entryTooltipThreatsCB.varname = "showWorldmapThreats";
	entryTooltipThreatsCB.GetValue = CheckButton_GetValue;
	entryTooltipThreatsCB.SetValue = CheckButton_SetValue;
	BlizzardOptionsPanel_RegisterControl(entryTooltipThreatsCB, self);
	BlizzardOptionsPanel_SetupDependentControl(entryTooltipCB, entryTooltipThreatsCB);
	BlizzardOptionsPanel_SetupDependentControl(showMinimapButtonCB, entryTooltipThreatsCB);

	local entryTooltipReqsCB = CreateFrame("CheckButton", self:GetName().."EntryTooltipRequirementsCB", self, "InterfaceOptionsCheckButtonTemplate");
	entryTooltipReqsCB:SetPoint("TOPLEFT", entryTooltipThreatsCB, "BOTTOMLEFT", 0, -8);
	entryTooltipReqsCB.type = CONTROLTYPE_CHECKBOX;
	entryTooltipReqsCB.text = _G[entryTooltipReqsCB:GetName().."Text"];
	entryTooltipReqsCB.text:SetText(strjoin(" ", L.CFG_DDMENU_ENTRYTOOLTIP_SHOW_REQUIREMENT_TEXT, GRAY_FONT_COLOR:WrapTextInColorCode(L.WORK_IS_EXPERIMENTAL)));
	entryTooltipReqsCB.tooltipText = strjoin("|n|n", L.CFG_DDMENU_ENTRYTOOLTIP_SHOW_REQUIREMENT_TOOLTIP, L.WORK_IS_EXPERIMENTAL_TOOLTIP_ADDITION);
	entryTooltipReqsCB.varname = "showEntryRequirements";
	entryTooltipReqsCB.GetValue = CheckButton_GetValue;
	entryTooltipReqsCB.SetValue = CheckButton_SetValue;
	BlizzardOptionsPanel_RegisterControl(entryTooltipReqsCB, self);
	BlizzardOptionsPanel_SetupDependentControl(entryTooltipCB, entryTooltipReqsCB);
	BlizzardOptionsPanel_SetupDependentControl(showMinimapButtonCB, entryTooltipReqsCB);

	--[[ Menu entries selection dropdown ]]--

	local menuEntriesDD = CreateFrame("Frame", self:GetName().."MenuEntriesDropDown", self, "UIDropDownMenuTemplate");
	menuEntriesDD.type = CONTROLTYPE_DROPDOWN;
	menuEntriesDD.label = menuEntriesDD:CreateFontString(menuEntriesDD:GetName().."Label", "BACKGROUND", "GameFontNormal");
	menuEntriesDD.label:SetPoint("TOPLEFT", entryHintAllCB, "BOTTOMLEFT", -12, -12);
	menuEntriesDD.label:SetText(L.CFG_DDMENU_ENTRYSELECTION_LABEL);
	menuEntriesDD.tooltipText = L.CFG_DDMENU_ENTRYSELECTION_TOOLTIP;
	menuEntriesDD:SetPoint("TOPLEFT", menuEntriesDD.label, "BOTTOMLEFT", -16, -3);
	menuEntriesDD.varname = "activeMenuEntries";  --> Links drop-down menu with saved variable
	-- menuEntriesDD.GetValue = function(self) return ns.settings[self.varname]; end;
	-- menuEntriesDD.SetValue = function (self, value) ns.settings[self.varname] = CopyTable(value); end;
	menuEntriesDD.RefreshValues = function(self)
		UIDropDownMenu_Initialize(self, MenuEntriesSelectionDropDown_Initialize);
		UIDropDownMenu_SetText(self, format(L.CFG_DDMENU_ENTRYSELECTION_TEXT_D, #ns.settings[self.varname]));
	end
	menuEntriesDD:SetScript("OnEnter", function(self)
		if ( not self.isDisabled ) then
			GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
			GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true);
		end
	end);
	menuEntriesDD:SetScript("OnLeave", GameTooltip_Hide);
	BlizzardOptionsPanel_RegisterControl(menuEntriesDD, self);
	BlizzardOptionsPanel_SetupDependentControl(showMinimapButtonCB, menuEntriesDD);

	local expansionNames = {
	          -- placeholder,   --> "Classic"
		nil,  -- placeholder1,  --> "The Burning Crusade"
		nil,  -- placeholder2,  --> "Wrath of the Lich King"
		nil,  -- placeholder3,  --> "Cataclysm"
		nil,  -- placeholder4,  --> "Mists of Pandaria"
		EXPANSION_NAME5,  --> "Warlords of Draenor"
		EXPANSION_NAME6,  --> "Legion"
		EXPANSION_NAME7,  --> "Battle for Azeroth"
		EXPANSION_NAME8,  --> "Shadowlands"
		"[ "..SETTINGS.." ]",  --> Additional "Settings" menu entry; WoW global string
	};
	--> Do NOT remove the placeholders! The position (index) of each expansion
	--  name is equal to the expansion ID which is used in the core file. The
	--  "Settings" entry is the extra value (latest expansion ID + 1) .
	ns.settingsMenuEntry = tostring(#expansionNames);

	local function MenuEntriesSelectionDropDown_OnClick(self)
		--
		-- Note: 'self' refers to the currently clicked menu entry frame.
		--
		local selectedValue = self.value;

		if ( not tContains(ns.settings.activeMenuEntries, selectedValue) ) then
			-- Add to the selection list
			tinsert(ns.settings.activeMenuEntries, selectedValue);
		else
			-- Remove value from the selection list
			for i, value in pairs(ns.settings.activeMenuEntries) do
				if (selectedValue == value) then
					tremove(ns.settings.activeMenuEntries, i);
				end
			end
		end

		printOption(expansionNames[tonumber(selectedValue)], self.checked);
		_log:debug("selectedMenuEntries:", SafeUnpack(ns.settings.activeMenuEntries));

		if ( #ns.settings.activeMenuEntries < 1 ) then
			-- Without any menu items the dropdown menu won't show up, so inform user
			local warningText = RED_FONT_COLOR:WrapTextInColorCode(L.CFG_DDMENU_ENTRYSELECTION_TEXT_WARNING);
			ns.cprint(warningText);
			UIDropDownMenu_SetText(menuEntriesDD, warningText);
		else
			UIDropDownMenu_SetText(menuEntriesDD, format(L.CFG_DDMENU_ENTRYSELECTION_TEXT_D, #ns.settings.activeMenuEntries));
		end
	end

	local function MenuEntriesSelectionDropDown_Initialize(self)
		--
		-- Create the selection dropdown for the menu entries
		--
		local info = UIDropDownMenu_CreateInfo();

		for i, name in pairs(expansionNames) do
			if name then  --> ignore placeholders
				info.text = name;
				info.func = MenuEntriesSelectionDropDown_OnClick;
				info.value = tostring(i);
				info.isNotRadio = 1;
				info.keepShownOnClick = 1;
				if tContains(ns.settings.activeMenuEntries, info.value) then
					info.checked = 1;
				else
					info.checked = nil;
				end
				UIDropDownMenu_AddButton(info);
			end
		end

		UIDropDownMenu_AddSeparator()

		local info = UIDropDownMenu_CreateInfo();
		info.text = CHECK_ALL;  --> WoW global string
		info.value = "all";
		info.notCheckable = 1;
		-- info.keepShownOnClick = 1;
		info.justifyH = "CENTER";
		info.colorCode = NORMAL_FONT_COLOR:GenerateHexColorMarkup();
		info.func = function(self)
			-- Mark all entries in the selection list as checked
			for i, value in pairs(ns.defaultSettings.activeMenuEntries) do
				ns.settings.activeMenuEntries[i] = value;
			end
			UIDropDownMenu_SetText(menuEntriesDD, format(L.CFG_DDMENU_ENTRYSELECTION_TEXT_D, #ns.settings.activeMenuEntries));
		end;
		UIDropDownMenu_AddButton(info);

		local info = UIDropDownMenu_CreateInfo();
		info.text = UNCHECK_ALL;  --> WoW global string
		info.func = nil;
		info.value = "none";
		info.notCheckable = 1;
		-- info.keepShownOnClick = 1;
		info.justifyH = "CENTER";
		info.colorCode = NORMAL_FONT_COLOR:GenerateHexColorMarkup();
		info.func = function(self)
			-- Uncheck all values from the selection list, except SETTINGS
			ns.settings.activeMenuEntries = {ns.settingsMenuEntry};
			UIDropDownMenu_SetText(menuEntriesDD, format(L.CFG_DDMENU_ENTRYSELECTION_TEXT_D, #ns.settings.activeMenuEntries));
		end
		UIDropDownMenu_AddButton(info);						--> TODO - Add unselect disabled entries
	end

	UIDropDownMenu_SetWidth(menuEntriesDD, panelContainerWidth/3);
	UIDropDownMenu_Initialize(menuEntriesDD, MenuEntriesSelectionDropDown_Initialize);

	--[[ Border type selection dropdown ]]--

	local menuStyleDD = CreateFrame("Frame", self:GetName().."MenuStyleDropDown", self, "UIDropDownMenuTemplate");
	menuStyleDD.type = CONTROLTYPE_DROPDOWN;
	menuStyleDD.label = menuStyleDD:CreateFontString(menuStyleDD:GetName().."Label", "BACKGROUND", "GameFontNormal");
	menuStyleDD.label:SetPoint("TOPLEFT", menuEntriesDD, "BOTTOMLEFT", 16, -16);
	menuStyleDD.label:SetText(L.CFG_DDMENU_STYLESELECTION_LABEL);
	menuStyleDD.tooltipText = L.CFG_DDMENU_STYLESELECTION_TOOLTIP;
	menuStyleDD:SetPoint("TOPLEFT", menuStyleDD.label, "BOTTOMLEFT", -16, -3);
	menuStyleDD.varname = "menuStyleID";  --> Links drop-down menu with saved variable
	menuStyleDD.RefreshValues = function(self)									--> FIXME - Shows "user defined" on refresh or reset
		-- local newValue = ns.settings[self.varname];
		-- local currentValue = UIDropDownMenu_GetSelectedValue(self);
		-- _log:debug("Refreshing", newValue, currentValue, newValue == currentValue);
		-- if (newValue ~= currentValue) then
		-- 	UIDropDownMenu_SetSelectedValue(self, ns.settings[self.varname]);
		-- end
	end
	menuStyleDD:SetScript("OnEnter", function(self)
		-- if ( not self.isDisabled ) then
		GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
		GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true);
		-- end
	end);
	menuStyleDD:SetScript("OnLeave", GameTooltip_Hide);
	BlizzardOptionsPanel_RegisterControl(menuStyleDD, self);
	BlizzardOptionsPanel_SetupDependentControl(showMinimapButtonCB, menuStyleDD);

	menuStyleDD.valueList = {
		L.CFG_DDMENU_STYLESELECTION_VALUE1_TEXT..GRAY_FONT_COLOR:WrapTextInColorCode(" ("..DEFAULT..")"),  --> WoW global string
		L.CFG_DDMENU_STYLESELECTION_VALUE2_TEXT,
	};

	function BorderSelectionDropDown_OnClick(self)
		-- Note: 'self' refers to the currently clicked menu entry frame.
		ns.settings.menuStyleID = self.value;
		UIDropDownMenu_SetSelectedValue(menuStyleDD, self.value);
		ns.MRBP_ReloadDropdown();

		printOption(UIDropDownMenu_GetText(menuStyleDD), true);
		_log:debug("Menu style ID selected:", self.value);
	end

	local function BorderSelectionDropDown_Initialize(self)
		-- Create the border selection dropdown menu
		local selectedValue = UIDropDownMenu_GetSelectedValue(self); -- or ns.settings.menuStyleID;
		local info = UIDropDownMenu_CreateInfo();

		for i, styleName in ipairs(menuStyleDD.valueList) do
			info.text = styleName;
			info.func = BorderSelectionDropDown_OnClick;
			info.value = tostring(i);
			if (info.value == selectedValue) then
				info.checked = 1;
			else
				info.checked = nil;
			end
			UIDropDownMenu_AddButton(info);
		end
	end

	UIDropDownMenu_SetWidth(menuStyleDD, panelContainerWidth/3);
	UIDropDownMenu_Initialize(menuStyleDD, BorderSelectionDropDown_Initialize);
	UIDropDownMenu_SetSelectedValue(menuStyleDD, ns.settings.menuStyleID);

	--[[ Account-wide options ]]--												--> TODO - Really needed?

	-- -- <Interface/AddOns/Blizzard_BindingUI/Blizzard_BindingUI.xml#L158>
	-- local setGlobalsButton = CreateFrame("Button", self:GetName().."SetGlobalsButton", self, "UIPanelButtonTemplate");
	-- setGlobalsButton:SetPoint("BOTTOMRIGHT", self, -16, 16);
	-- setGlobalsButton.text = _G[setGlobalsButton:GetName().."Text"];
	-- setGlobalsButton.text:SetText("Als Vorlage verwenden");					--> TODO - L10n
	-- setGlobalsButton.tooltipText = "Aktuelle Einstellungen speichern und als Vorlage für alle Charaktere verwenden.";
	-- setGlobalsButton:SetSize(setGlobalsButton:GetTextWidth()+40, 22);
	-- setGlobalsButton:SetScript("OnClick", function(self, button, isDown)
	-- 	PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK);
	-- 	MRBP_GlobalSettings = {};
	-- 	SaveSettings();
	-- 	-- SetAsGlobalSettings();
	-- 	self:Disable();
	-- end);
	-- setGlobalsButton:SetScript("OnEnter", function(self)
	-- 	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
	-- 	GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true);
	-- end);
	-- setGlobalsButton:SetScript("OnLeave", GameTooltip_Hide);
end
