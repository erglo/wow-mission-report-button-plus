if ( GetLocale() ~= "esES" ) then
	return
end

local ns = select(2, ...)

ns.L = {
	--[[ TOC file notes ]]--
	TOC_FILE_NOTES = "Adds a right-click menu to the mission report button on the minimap|nfor selecting reports of previous extensions as well.",
	--[[ Tooltips ]]--
	TOOLTIP_CLICKTEXT_MINIMAPBUTTON = "Haz clic derecho para seleccionar la expansión",
	TOOLTIP_REQUIREMENTS_TEXT_S = 'Completa "%s" para desbloquear contenido',
	--[[ Slash command descriptions ]]--
	SLASHCMD_DESC_VERSION = "Prints this add-on's current version info",
	SLASHCMD_DESC_CHATMSG = "Toggles chat notifications",
	SLASHCMD_DESC_SHOW = "Shows the minimap button",
	SLASHCMD_DESC_HIDE = "Hides the minimap button",
	--[[ Chat messages ]]--
	CHATMSG_SYNTAX_INFO_S = "Usage: '%s <argument>'",
	CHATMSG_SILENT_S = "Chat notifications disabled. Re-enable with '%s'.",
	CHATMSG_VERBOSE_S = "Chat notifications enabled. Disable with '%s'.",
	CHATMSG_RESET = "Settings have been reset to default values.",
	CHATMSG_UNLOCKED_COMMANDTABLES_REQUIRED = "Requirements for displaying the minimap button not met. At least one of the command tables available must be unlocked.",
	CHATMSG_MINIMAPBUTTON_ALREADY_SHOWN = "Minimap button is already visible.",
	--[[ UI options ]]--
	CFG_ADDONINFOS_VERSION = "Version",
	CFG_ADDONINFOS_AUTHOR = "Author",
	CFG_ADDONINFOS_EMAIL = "Email",
	CFG_ADDONINFOS_HOMEPAGE = "Homepage",
	CFG_ADDONINFOS_LICENSE = "License",
	CFG_CHAT_NOTIFY_TEXT = "Toggle Chat Notifications",
	CFG_CHAT_NOTIFY_TOOLTIP = "Disable to turn chat notifications off.",
	CFG_MINIMAPBUTTON_SHOWNAMEINTOOLTIP_TEXT = "Show Abbreviation in Button Tooltip",
	CFG_MINIMAPBUTTON_SHOWNAMEINTOOLTIP_TOOLTIP = "If enabled, the add-on's abbreviation will be displayed in the minimap button's tooltip.",
	CFG_MINIMAPBUTTON_SHOWBUTTON_TEXT = "Show Minimap Button",
	CFG_MINIMAPBUTTON_SHOWBUTTON_TOOLTIP = "As long as you haven't reached the highest level available for an extension by WoW default the minimap button for the garrison landing page remains hidden.|n|nIf enabled, this option shows you the button again with access to your last command table along with additional informations.",
	CFG_DDMENU_SEPARATOR_HEADING = "Dropdown Menu",
	CFG_DDMENU_NAMING_TEXT = "Prefer Expansion Names",
	CFG_DDMENU_NAMING_TOOLTIP = "The dropdown menu items are by default the names of each expansion.|n|nIf disabled, the name of each mission report will be displayed instead.",
	CFG_DDMENU_SORTORDER_TEXT = "Reverse Names Order",
	CFG_DDMENU_SORTORDER_TOOLTIP = "The dropdown menu items are by default sorted by expansion release; eg. the current expansion comes first, the one before that next, etc.|n|nIf enabled, the sorting order will be reversed.",
	CFG_DDMENU_REPORTICONS_TEXT = "Show Report-specific Icons",
	CFG_DDMENU_REPORTICONS_TOOLTIP = "If disabled, the report type icons on the right side will be hidden.",
	CFG_DDMENU_ICONHINT_TEXT = "Show Icon Hint after Names",
	CFG_DDMENU_ICONHINT_TOOLTIP = "After each menu item an exclamation mark icon appears as soon as an in-progress mission is finished.|n|nIf disabled, the icon will be hidden.",
	CFG_DDMENU_ICONHINTALL_TEXT = "Only after Finishing ALL Missions",
	CFG_DDMENU_ICONHINTALL_TOOLTIP = "The hint icon will only show up after ALL in-progress missions were finished.",
	CFG_DDMENU_ENTRYTOOLTIP_SHOW_TEXT = "Show Details Tooltip",
	CFG_DDMENU_ENTRYTOOLTIP_SHOW_TOOLTIP = "On mouse-over each menu item details about the corresponding expansion were shown in a tooltip.|n|nIf disabled, this tooltip will not appear.",
	CFG_DDMENU_ENTRYTOOLTIP_INPROGRESS_TEXT = "In-Progress Mission Counter",
	CFG_DDMENU_ENTRYTOOLTIP_INPROGRESS_TOOLTIP = "The numbers of the in-progress missions were shown in the tooltip of each menu item.|n|nIf disabled, these numbers will be hidden.",
	CFG_DDMENU_ENTRYTOOLTIP_BOUNTIES_TEXT = "Bounty Board Quests",
	CFG_DDMENU_ENTRYTOOLTIP_BOUNTIES_TOOLTIP = "Lists the currently active and unlocked Emissary Quests available for each expansion in the tooltip.",
	CFG_DDMENU_ENTRYTOOLTIP_BOUNTYREQUIREMENTS_TEXT = "Show Turn-in Requirements",
	CFG_DDMENU_ENTRYTOOLTIP_BOUNTYREQUIREMENTS_TOOLTIP = "Some Emissary Quests appear as available although the World Quests for that faction haven't been unlocked.|n|nEnable in order to show an unlocking requirement hint in the tooltip.",
	CFG_DDMENU_ENTRYTOOLTIP_THREATS_TEXT = "World Map Threats",
	CFG_DDMENU_ENTRYTOOLTIP_THREATS_TOOLTIP = "Lists the currently active and unlocked world map threats (eg. N'Zoth or Covenant assaults) for each expansion in the tooltip.",
	CFG_DDMENU_ENTRYTOOLTIP_SHOW_REQUIREMENT_TEXT = "Include Requirement Info",
	CFG_DDMENU_ENTRYTOOLTIP_SHOW_REQUIREMENT_TOOLTIP = "An expansion's mission report cannot be accessed unless its command table has been unlocked.|n|nEnable to show a hint message in the tooltip on how to unlock it.",
	CFG_DDMENU_ENTRYSELECTION_LABEL = "Menu Items",
	CFG_DDMENU_ENTRYSELECTION_TOOLTIP = "Choose the dropdown menu's entry items that should be displayed. Simply uncheck those items which are no longer of interest to you.",
	CFG_DDMENU_ENTRYSELECTION_TEXT_D = "%d |4menu item:menu items; selected",
	CFG_DDMENU_ENTRYSELECTION_TEXT_WARNING = "Need at least 1 menu item",  --> max. 27 chars
	CFG_DDMENU_STYLESELECTION_LABEL = "Menu Style",
	CFG_DDMENU_STYLESELECTION_TOOLTIP = "Choose your favorite dropdown menu style.|n|n(More to come.)",
	CFG_DDMENU_STYLESELECTION_VALUE1_TEXT = "Tooltip Style",
	CFG_DDMENU_STYLESELECTION_VALUE2_TEXT = "Dropdown Menu Style",
	--[[ Testing ]]--
	WORK_IS_EXPERIMENTAL = "(Experimental)",
	WORK_IS_EXPERIMENTAL_TOOLTIP_ADDITION = "(This function is experimental and under development. It might deliver incomplete information or even not work properly.)",
}