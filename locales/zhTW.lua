if (GetLocale() ~= "zhTW") then
	return;
end

local ns = select(2, ...);

-- Translated by EK (EKE00372)
--> @Translators: replace the line above with your name and/or email address or homepage

local L;
-- @localization(locale="zhTW", format="lua_table", handle-unlocalized="english")@
if L then
	ns.L = L;
end

--@do-not-package@
--------------------------------------------------------------------------------
--> Note: This section is used for local testing and will not be packaged in the
--  released version. The release version of this localization is hosted at 
--  CurseForge and will be automatically integrated during release workflow.

ns.L = {
	--[[ TOC file notes ]]--
	TOC_FILE_NOTES = "替小地圖上的資料片按鈕添加右鍵選單，點擊選單可以查看各個資料片版本的任務桌。",
	--[[ Tooltips ]]--
	TOOLTIP_CLICKTEXT_MINIMAPBUTTON = "右鍵選擇資料片",
	TOOLTIP_REQUIREMENTS_TEXT_S = "完成任務「%s」以解鎖此資料片的內容",
	--[[ Slash command descriptions ]]--
	SLASHCMD_DESC_CHATMSG = "切換聊天通知",
	SLASHCMD_DESC_SHOW = "顯示小地圖按鈕",
	SLASHCMD_DESC_HIDE = "隱藏小地圖按鈕",
	SLASHCMD_DESC_HOOK = "Updates the minimap button hooks",
	--[[ Chat messages ]]--
	CHATMSG_SYNTAX_INFO_S = "請使用指令： '%s <argument>'",
	CHATMSG_SILENT_S = "聊天通知已關閉，如要重新打開，請輸入：%s",
	CHATMSG_VERBOSE_S = "聊天通知已開啟，如要重新關閉，請輸入：%s",
	CHATMSG_RESET = "已將設定重置為預設值。",
	CHATMSG_UNLOCKED_COMMANDTABLES_REQUIRED = "無法顯示小地圖按鈕：至少要解鎖一個資料片，才會顯示資料片按鈕。",
	CHATMSG_MINIMAPBUTTON_ALREADY_SHOWN = "小地圖按鈕已啟用",
	CHATMSG_MINIMAPBUTTON_HOOKS_UPDATED = "Minimap button hooks have been updated.",
	--[[ Menu entry tooltip ]]--
	ENTRYTOOLTIP_WORLD_MAP_EVENTS_LABEL = "世界地圖事件",
	ENTRYTOOLTIP_APPLY_FACTION_COLORS_LABEL = "陣營染色",
	ENTRYTOOLTIP_TIMEWALKING_VENDOR_LABEL = "時光商人",
	ENTRYTOOLTIP_LEGION_APPLY_INVASION_COLORS_LABEL = "陣營染色",
	ENTRYTOOLTIP_BFA_FACTION_ASSAULTS_LABEL = "陣營入侵",
	ENTRYTOOLTIP_SL_MAW_THREATS_LABEL = "誓盟進攻戰",
	ENTRYTOOLTIP_DF_HIDE_MF_UNLOCK_DESCRIPTION_LABEL = "隱藏解鎖提示",
	-- ENTRYTOOLTIP_DF_DRAGON_GLYPHS_LABEL = "飛龍雕紋",
	ENTRYTOOLTIP_DF_HIDE_DRAGON_GLYPHS_LABEL = "隱藏完成區域",
	-- ENTRYTOOLTIP_DF_DRAGONRIDING_RACE_LABEL = "飛龍競速",
	ENTRYTOOLTIP_DF_CAMP_AYLAAG_AREA_NAME = "River Camp",
	-- ENTRYTOOLTIP_DF_COMMUNITY_FEAST_LABEL = "集體盛宴",
	ENTRYTOOLTIP_DF_HIDE_EVENT_DESCRIPTIONS_LABEL = "隱藏事件描述",
	--[[ UI options ]]--
	CFG_ADDONINFOS_VERSION = "版本",
	CFG_ADDONINFOS_AUTHOR = "作者",
	CFG_ADDONINFOS_EMAIL = "Email",
	CFG_ADDONINFOS_HOMEPAGE = "項目主頁",
	CFG_ADDONINFOS_LICENSE = "授權",
	CFG_ADDONINFOS_L10N_S = "翻譯 (%s)",
	CFG_ADDONINFOS_L10N_CONTACT = "EK (EKE00372)",  --> @Translators: add your name and/or email address
	CFG_CHAT_NOTIFY_TEXT = "切換聊天通知",
	CFG_CHAT_NOTIFY_TOOLTIP = "取消勾選會停用聊天通知。",
	CFG_MINIMAPBUTTON_SHOWNAMEINTOOLTIP_TEXT = "顯示插件名字縮寫",
	CFG_MINIMAPBUTTON_SHOWNAMEINTOOLTIP_TOOLTIP = "啟用後，在小地圖的按鈕顯示縮寫「MRBP」，而不是插件的全名。",
	CFG_MINIMAPBUTTON_SHOWBUTTON_TEXT = "顯示小地圖按鈕",
	CFG_MINIMAPBUTTON_SHOWBUTTON_TOOLTIP = "在你達到可以開啟當前版本資料片內容的等級之前，小地圖的資料片按鈕都是隱藏的。|n|n啟用此選項後，只要你解鎖了任意資料片，就可以強制顯示按鈕。",
	CFG_TRACK_ACHIEVEMENTS_TEXT = "追蹤成就",
	CFG_TRACK_ACHIEVEMENTS_TOOLTIP = "Events linked to the achievements below will be displayed in a gray colored text and marked with a yellow check mark symbol.",
	CFG_SHOW_ADDON_COMPARTMENT_TEXT = "暴雪插件按鈕",
	CFG_SHOW_ADDON_COMPARTMENT_TOOLTIP = "在暴雪的插件收納按鈕顯示這個插件。這個按鈕的預設位置在小地圖右上方。",
	CFG_DDMENU_SEPARATOR_HEADING = "下拉選單",
	CFG_DDMENU_NAMING_TEXT = "顯示資料片名稱",
	CFG_DDMENU_NAMING_TOOLTIP = "啟用以資料片名稱顯示不同版本，禁用則顯示各版本任務桌的名字。",
	CFG_DDMENU_SORTORDER_TEXT = "反向排列",
	CFG_DDMENU_SORTORDER_TOOLTIP = "下拉選單的資料片選項是自上至下，由新到舊。如果啟用此選項，將會反向排列，使最舊的資料片排在最上面。",
	CFG_DDMENU_REPORTICONS_TEXT = "任務桌圖示",
	CFG_DDMENU_REPORTICONS_TOOLTIP = "在下拉選單的右側顯示版本圖示。",
	CFG_DDMENU_HINT_MISSIONS_TEXT = "任務完成提示",
	CFG_DDMENU_HINT_MISSIONS_TOOLTIP = "任務完成後，在選單的資料片名稱後面顯示一個驚嘆號。|n|n關閉此選項將不顯示驚嘆號提示。",
	CFG_DDMENU_HINT_MISSIONS_ALL_TEXT = "所有任務",
	CFG_DDMENU_HINT_MISSIONS_ALL_TOOLTIP = "所有任務都完成才顯示驚嘆號。",
	CFG_DDMENU_HINT_REPUTATION_TEXT = "Hint Reputation Reward",
	CFG_DDMENU_HINT_REPUTATION_TOOLTIP = "An icon appears on the left side of the menu as soon as reputation reward is available.",
	CFG_DDMENU_HINT_TIMEWALKING_VENDOR_TEXT = "Hint Timewalking Vendor",
	CFG_DDMENU_HINT_TIMEWALKING_VENDOR_TOOLTIP = "An icon appears on the left side of the menu as soon as the Timewalking Vendor is available.",
	CFG_DDMENU_ENTRYTOOLTIP_LABEL = "提示資訊",
	CFG_DDMENU_ENTRYTOOLTIP_SHOW_TEXT = "顯示滑鼠提示",
	CFG_DDMENU_ENTRYTOOLTIP_SHOW_TOOLTIP = "滑鼠指向選單時，顯示該資料片的詳細資訊。如果禁用此選項則不會顯示滑鼠提示。",
	CFG_DDMENU_ENTRYTOOLTIP_DRAGON_GLYPHS_TOOLTIP = "顯示每個地圖的飛龍雕紋收集進度",
	CFG_DDMENU_ENTRYTOOLTIP_HIDE_DRAGON_GLYPHS_TOOLTIP = "隱藏飛龍雕紋已收集完畢的區域。",
	CFG_DDMENU_ENTRYTOOLTIP_MISSION_INFO_TOOLTIP = "為你從任務桌派遣的追隨者任務顯示摘要。",
	CFG_DDMENU_ENTRYTOOLTIP_GARRISON_INVASION_ALERT_TOOLTIP = "在要塞入侵時提醒你。",
	CFG_DDMENU_ENTRYTOOLTIP_WORLD_MAP_EVENTS_TOOLTIP = "掃描世界地圖，檢索地圖事件，並顯示摘要。",
	CFG_DDMENU_ENTRYTOOLTIP_TIMEWALKING_VENDOR_TOOLTIP = "在時光漫遊期間，顯示時光商人的位置資訊。",
	CFG_DDMENU_ENTRYTOOLTIP_LEGION_BOUNTIES_TOOLTIP = "在滑鼠提示中列出破碎群島和阿古斯目前的特使任務。",
	CFG_DDMENU_ENTRYTOOLTIP_BFA_BOUNTIES_TOOLTIP = "在滑鼠提示中列出贊達拉和庫爾提拉斯目前的特使任務。",
	CFG_DDMENU_ENTRYTOOLTIP_BFA_ISLAND_EXPEDITIONS_TOOLTIP = "顯示海嶼遠征的每周任務收集艾澤萊晶岩的進度。",
	CFG_DDMENU_ENTRYTOOLTIP_COVENANT_BOUNTIES_TOOLTIP = "在滑鼠提示中顯示暗影之境目前的誓盟使命任務。",
	CFG_DDMENU_ENTRYTOOLTIP_LEGION_INVASION_COLORS_TOOLTIP = "以淡綠色替入侵點名稱著色。",
	CFG_DDMENU_ENTRYTOOLTIP_FACTION_COLORS_TOOLTIP = "以誓盟配色替誓盟名稱著色。",
	CFG_DDMENU_ENTRYTOOLTIP_NZOTH_THREATS_TOOLTIP = "為艾澤拉斯的恩若司入侵顯示摘要。",
	CFG_DDMENU_ENTRYTOOLTIP_MAW_THREATS_TOOLTIP = "為淵喉的誓盟進攻戰顯示摘要。",
	CFG_DDMENU_ENTRYTOOLTIP_COVENANT_RENOWN_TOOLTIP = "為暗影之境誓盟的名望等級顯示進度。",
	CFG_DDMENU_ENTRYTOOLTIP_MAJOR_FACTION_RENOWN_TOOLTIP = "為巨龍群島的陣營聲望顯示進度。",
	CFG_DDMENU_ENTRYTOOLTIP_MAJOR_FACTION_UNLOCK_TOOLTIP = "顯示解鎖陣營聲望的提示。",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TEMPLATE_TOOLTIP = "在滑鼠提示中，為「%s」顯示摘要。",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_LEGION_INVASION = "破碎群島的軍團入侵點",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_DEMON_INVASION = "破碎海岸的惡魔入侵點",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_ARGUS_INVASION = "阿古斯的軍團入侵點",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_BFA_FACTION_ASSAULTS = "贊達拉和庫爾提拉斯的陣營入侵",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_DRAGONRIDING_RACE = "巨龍群島的多人飛龍競速賽",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_CAMP_AYLAAG = "雍亞拉平原的艾拉格營地",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_GRAND_HUNTS = "巨龍群島的大狩獵任務",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_ISKAARA_FEAST = "伊斯凱拉巨牙海民的集體盛宴。",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_DRAGONBANE_KEEP = "甦醒海岸的攻打龍禍要塞",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_ELEMENTAL_STORMS = "巨龍群島的元素風暴",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_FYRAKK_ASSAULTS = "巨龍群島的菲拉卡襲擊",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_TIME_RIFTS = "the Time Rifts in Thaldraszus",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_RESEARCHERS_UNDER_FIRE = "Researchers Under Fire in the Zaralek Cavern",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_ONLY_IN_ZARALEK_CAVERN = "(Works in Zaralek Cavern only!)",
	CFG_DDMENU_ENTRYTOOLTIP_EVENT_POI_HIDE_EVENT_DESCRIPTIONS = "隱藏事件內容的描述。",
	CFG_DDMENU_ENTRYSELECTION_LABEL = "選單選項",
	CFG_DDMENU_ENTRYSELECTION_TOOLTIP = "Choose the dropdown menu's entry items that should be displayed. Simply uncheck those items which are no longer of interest to you.",
	CFG_DDMENU_ENTRYSELECTION_TEXT_D = "%d |4menu item:menu items; selected",
	CFG_DDMENU_ENTRYSELECTION_TEXT_WARNING = "At least 1 menu item required",
	CFG_DDMENU_STYLESELECTION_LABEL = "選單樣式",
	CFG_DDMENU_STYLESELECTION_TOOLTIP = "Choose your favorite dropdown menu style.|n|n(More to come.)",
	CFG_DDMENU_STYLESELECTION_VALUE1_TEXT = "滑鼠提示",
	CFG_DDMENU_STYLESELECTION_VALUE1_TOOLTIP = "The look of this style is that of a common tooltip bubble.",
	CFG_DDMENU_STYLESELECTION_VALUE2_TEXT = "下拉選單",
	CFG_DDMENU_STYLESELECTION_VALUE2_TOOLTIP = "This style represents the look of a common dialog (pre-Dragonflight).",
	CFG_WOD_HIDE_GARRISON_INVASION_ALERT_ICON_TEXT = "Hide Alert Icon",
	CFG_WOD_HIDE_GARRISON_INVASION_ALERT_ICON_TOOLTIP = "Hide the Invasion Alert icon on top of the Draenor Garrison Landing Page frame, even if an invasion is available.",
	CFG_ABOUT_ADDON_LABEL = "關於本插件",
	CFG_ABOUT_SLASHCMD_LABEL = "聊天指令",
	--[[ Testing ]]--
	WORK_IS_EXPERIMENTAL = "（實驗性功能）",
	WORK_IS_EXPERIMENTAL_TOOLTIP_ADDITION = "（實驗性功能尚未開發完成，功能可能不完整，甚至可能無法正常運作。）",
	WORKS_ONLY_FOR_EXPANSION_S = "(Currently only supported for %s)",
};
--------------------------------------------------------------------------------
--@end-do-not-package@
