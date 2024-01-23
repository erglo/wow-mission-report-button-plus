--[[ Mission Report Button Plus - Data file for extending localized strings ]]--
--
-- by erglo <erglo.coder+MRBP@gmail.com>
--
-- Copyright (C) 2023  Erwin D. Glockner (aka erglo)
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

local ns = select(2, ...)
local L = ns.L
L.currentLocale = GetLocale()

L.IsEnglishLocale = function(self, locale)
    --> REF.: <FrameXML/LocaleUtil.lua>
    local englishLocales = {"enCN", "enGB", "enTW", "enUS"}
    return tContains(englishLocales, locale)
end

L.IsGermanLocale = function (self, locale)
    return locale == "deDE"
end

L.StringIsEmpty = function(self, str)
	return str == nil or strlen(str) == 0
end

-- Warlords of Draenor
L["showWoDMissionInfo"] = GARRISON_MISSIONS_TITLE
L["showWoDGarrisonInvasionAlert"] = GARRISON_LANDING_INVASION
L["showWoDWorldMapEvents"] = L.ENTRYTOOLTIP_WORLD_MAP_EVENTS_LABEL              --> TODO - Replace in locale files and remove from this file
L["showWoDTimewalkingVendor"] = L.ENTRYTOOLTIP_TIMEWALKING_VENDOR_LABEL
-- Legion
L["showLegionMissionInfo"] = GARRISON_MISSIONS
L["showLegionBounties"] = BOUNTY_BOARD_LOCKED_TITLE
L["showLegionWorldMapEvents"] = L.ENTRYTOOLTIP_WORLD_MAP_EVENTS_LABEL
L["applyInvasionColors"] = L.ENTRYTOOLTIP_LEGION_APPLY_INVASION_COLORS_LABEL
L["showLegionTimewalkingVendor"] = L.ENTRYTOOLTIP_TIMEWALKING_VENDOR_LABEL
-- Battle for Azeroth
L["showBfAMissionInfo"] = GARRISON_MISSIONS
L["showBfABounties"] = BOUNTY_BOARD_LOCKED_TITLE
L["showNzothThreats"] = WORLD_MAP_THREATS
L["showBfAWorldMapEvents"] = L.ENTRYTOOLTIP_WORLD_MAP_EVENTS_LABEL
L["showBfAFactionAssaultsInfo"] = L.ENTRYTOOLTIP_BFA_FACTION_ASSAULTS_LABEL     --> TODO - achievementID=13284
L["applyBfAFactionColors"] = L.ENTRYTOOLTIP_APPLY_FACTION_COLORS_LABEL
L["showBfAIslandExpeditionsInfo"] = ISLANDS_HEADER
-- Shadowlands
L["showCovenantMissionInfo"] = COVENANT_MISSIONS_TITLE
L["showCovenantBounties"] = CALLINGS_QUESTS
L["showMawThreats"] = L.ENTRYTOOLTIP_SL_MAW_THREATS_LABEL
L["showCovenantRenownLevel"] = COVENANT_PROGRESS.." "..PARENS_TEMPLATE:format(RENOWN_LEVEL_LABEL)
L["applyCovenantColors"] = L.ENTRYTOOLTIP_APPLY_FACTION_COLORS_LABEL
-- Dragonflight
L["showMajorFactionRenownLevel"] = MAJOR_FACTION_LIST_TITLE.." "..PARENS_TEMPLATE:format(LANDING_PAGE_RENOWN_LABEL)
L["applyMajorFactionColors"] = L.ENTRYTOOLTIP_APPLY_FACTION_COLORS_LABEL
L["hideMajorFactionUnlockDescription"] = L.ENTRYTOOLTIP_DF_HIDE_MF_UNLOCK_DESCRIPTION_LABEL
L["autoHideCompletedDragonGlyphZones"] = L.ENTRYTOOLTIP_DF_HIDE_DRAGON_GLYPHS_LABEL
L["showDragonflightWorldMapEvents"] = L.ENTRYTOOLTIP_WORLD_MAP_EVENTS_LABEL
L["hideEventDescriptions"] = L.ENTRYTOOLTIP_DF_HIDE_EVENT_DESCRIPTIONS_LABEL

L.defaultLabels = {  -- English defaults
    ["showLegionAssaultsInfo"] = "Legion Assault",                              -- Legion
    ["showBrokenShoreInvasionInfo"] = "Broken Shore: Demon Invasions",
    ["showArgusInvasionInfo"] = "Argus: Invasion Point",
    ["showDragonRaceInfo"] = "Dragon Racing",                                   -- Dragonflight
    ["showDragonGlyphs"] = "Dragon Glyphs",
    ["showCampAylaagInfo"] = "Aylaag Camp",
    ["showGrandHuntsInfo"] = "Grand Hunts",
    ["showCommunityFeastInfo"] = "Community Feast",
    ["showDragonbaneKeepInfo"] = "Siege on Dragonbane Keep",
    ["showElementalStormsInfo"] = "Elemental Storm",
    ["showFyrakkAssaultsInfo"] = "Fyrakk Assault",
    ["showResearchersUnderFireInfo"] = "Researchers Under Fire",
    ["showTimeRiftInfo"] = "Time Rift",
    ["showDreamsurgeInfo"] = "Dreamsurge",
    ["showSuperbloomInfo"] = "Superbloom",
    ["showTheBigDigInfo"] = "Azerothian Archives",
}
--> TODO - Add Shadowlands "Covenant Assaults"
--> TODO - Add BfA "Faction Assaults"

-- These strings have been saved using the global variable; once they have been
-- copied to this table they will be removed automatically from the global variable
local savedLabels = {
    ["deDE"] = {
        ["showLegionAssaultsInfo"] = "Angriff der Legion",                      -- Legion
        ["showBrokenShoreInvasionInfo"] = "Verheerte Küste: Dämoneninvasionen",
        ["showArgusInvasionInfo"] = "Argus: Invasionspunkt",
        ["showDragonRaceInfo"] = "Drachenrennen",                               -- Dragonflight
        ["showDragonGlyphs"] = "Drachenglyphen",
        ["showCampAylaagInfo"] = "Lager der Aylaag",
        ["showGrandHuntsInfo"] = "Große Jagden",
        ["showCommunityFeastInfo"] = "Gemeinschaftliches Festmahl",
        ["showDragonbaneKeepInfo"] = "Belagerung der Drachenfluchfestung",
        ["showElementalStormsInfo"] = "Elementarsturm",
        ["showFyrakkAssaultsInfo"] = "Angriff von Fyrakk",
        ["showResearchersUnderFireInfo"] = "Forscher unter Feuer",
        ["showTimeRiftInfo"] = "Zeitriss",
        ["showDreamsurgeInfo"] = "Traumsprung",
        ["showSuperbloomInfo"] = "Superblüte",
        ["showTheBigDigInfo"] = "Archive von Azeroth",
    },
    ["esES"] = {
        ["showLegionAssaultsInfo"] = "Asalto de la Legión",                     -- Legion
        ["showBrokenShoreInvasionInfo"] = "Costa Abrupta: Invasiones demoníacas",
        ["showArgusInvasionInfo"] = "Argus: Punto de invasión",
        ["showDragonRaceInfo"] = "Carreras de dragones",                        -- Dragonflight
        ["showDragonGlyphs"] = "Glifos dracónicos",
        ["showCampAylaagInfo"] = "Campamento Aylaag",
        ["showGrandHuntsInfo"] = "Grandes cacerías",
        ["showCommunityFeastInfo"] = "Festín comunitario",
        ["showDragonbaneKeepInfo"] = "Asedio en la Fortaleza de Ruinadragón",
        ["showElementalStormsInfo"] = "Tormenta elemental",
        ["showFyrakkAssaultsInfo"] = "Asalto de Fyrakk",
        ["showResearchersUnderFireInfo"] = "Investigadores bajo el fuego",
        ["showTimeRiftInfo"] = "Falla temporal",
        ["showDreamsurgeInfo"] = "Pico Onírico",
        ["showSuperbloomInfo"] = "Superfloración",
        ["showTheBigDigInfo"] = "Archivos de Azeroth",
    },
    ["frFR"] = {
        ["showLegionAssaultsInfo"] = "Assaut de la Légion",                     -- Legion
        ["showBrokenShoreInvasionInfo"] = "Rivage Brisé : Invasions démoniaques",
        ["showArgusInvasionInfo"] = "Argus : Site d’invasion",
        ["showDragonRaceInfo"] = "Course de Dragons",                           -- Dragonflight
        ["showDragonGlyphs"] = "Dracoglyphes",
        ["showCampAylaagInfo"] = "Camp Aylaag",
        ["showGrandHuntsInfo"] = "Grandes chasses",
        ["showCommunityFeastInfo"] = "Festin tribal",
        ["showDragonbaneKeepInfo"] = "Siège du donjon du Fléau-des-Dragons",
        ["showElementalStormsInfo"] = "Tempête élémentaire",
        ["showFyrakkAssaultsInfo"] = "Assaut de Fyrakka",
        ["showResearchersUnderFireInfo"] = "Chercheurs sous le feu",
        ["showTimeRiftInfo"] = "Faille temporelle",
        ["showDreamsurgeInfo"] = "Poussée onirique",
        ["showSuperbloomInfo"] = "Superfloraison",
        ["showTheBigDigInfo"] = "Archives d’Azeroth",
    },
    ["itIT"] = {
        ["showLegionAssaultsInfo"] = "Assalto della Legione ",                  -- Legion
        ["showBrokenShoreInvasionInfo"] = "Riva Dispersa: Invasioni demoniache",
        ["showArgusInvasionInfo"] = "Argus: Punto di Invasione",
        ["showDragonRaceInfo"] = "Corsa dei Draghi",                            -- Dragonflight
        ["showDragonGlyphs"] = "Glifi del Drago",
        ["showCampAylaagInfo"] = "Campo Aylaag",
        ["showGrandHuntsInfo"] = "Grandi Cacce",
        ["showCommunityFeastInfo"] = "Banchetto della Comunità",
        ["showDragonbaneKeepInfo"] = "Assedio al Forte del Flagello dei Draghi",
        ["showElementalStormsInfo"] = "Tempesta Elementale",
        ["showFyrakkAssaultsInfo"] = "Assalto di Fyrakk",
        ["showResearchersUnderFireInfo"] = "Ricercatori sotto attacco",
        ["showTimeRiftInfo"] = "Fenditura del Tempo",
        ["showDreamsurgeInfo"] = "Sovronirico",
        ["showSuperbloomInfo"] = "Superfioritura",
        ["showTheBigDigInfo"] = "Archivi Azerothiani",
    },
    ["ptBR"] = {
        ["showLegionAssaultsInfo"] = "Ataque da Legião",                        -- Legion
        ["showBrokenShoreInvasionInfo"] = "Costa Partida: Invasões de Demônios",
        ["showArgusInvasionInfo"] = "Argus: Ponto de Invasão",
        ["showDragonRaceInfo"] = "Corrida de Dragões",                          -- Dragonflight
        ["showDragonGlyphs"] = "Glifos do Dragão",
        ["showCampAylaagInfo"] = "Acampamento Aylaag",
        ["showGrandHuntsInfo"] = "Grandes Caçadas",
        ["showCommunityFeastInfo"] = "Banquete da comunidade",
        ["showDragonbaneKeepInfo"] = "Cerco à Bastilha de Ruína Dragônica",
        ["showElementalStormsInfo"] = "Tempestade Elemental",
        ["showFyrakkAssaultsInfo"] = "Ofensiva de Fyrakk",
        ["showResearchersUnderFireInfo"] = "Pesquisadores sob fogo",
        ["showTimeRiftInfo"] = "Fenda Temporal",
        ["showDreamsurgeInfo"] = "Surto Onírico",
        ["showSuperbloomInfo"] = "Superflorada",
        ["showTheBigDigInfo"] = "Arquivo Azerothiano",
    },
    ["ruRU"] = {
        ["showLegionAssaultsInfo"] = "Атака Легиона",                           -- Legion
        ["showBrokenShoreInvasionInfo"] = "Расколотый берег: Вторжение демонов",
        ["showArgusInvasionInfo"] = "Аргус: Точка вторжения",
        ["showDragonRaceInfo"] = "Гонки драконов",                              -- Dragonflight
        ["showDragonGlyphs"] = "Драконьи символы",
        ["showCampAylaagInfo"] = "Айлаагский лагерь",
        ["showGrandHuntsInfo"] = "Великая охота",
        ["showCommunityFeastInfo"] = "Большое пиршество",
        ["showDragonbaneKeepInfo"] = "Осада Драконьей Погибели",
        ["showElementalStormsInfo"] = "Буря стихий",
        ["showFyrakkAssaultsInfo"] = "Налет Фиракка",
        ["showResearchersUnderFireInfo"] = "Исследователи под огнем",
        ["showTimeRiftInfo"] = "Портал времени",
        ["showDreamsurgeInfo"] = "Прилив Снов",
        ["showSuperbloomInfo"] = "Цветочный бум",
        ["showTheBigDigInfo"] = "Азеротские Архивы",
    },
    ["zhCN"] = {
        ["showLegionAssaultsInfo"] = "军团入侵",                                 -- Legion
        ["showBrokenShoreInvasionInfo"] = "破碎海滩： 恶魔入侵",
        ["showArgusInvasionInfo"] = "阿古斯： 侵入点",
        ["showDragonRaceInfo"] = "驭龙竞速",                                     -- Dragonflight
        ["showDragonGlyphs"] = "巨龙雕纹",
        ["showCampAylaagInfo"] = "艾拉格营地",
        ["showGrandHuntsInfo"] = "洪荒狩猎",
        ["showCommunityFeastInfo"] = "社区盛宴",
        ["showDragonbaneKeepInfo"] = "围攻灭龙要塞",
        ["showElementalStormsInfo"] = "元素风暴",
        ["showFyrakkAssaultsInfo"] = "菲莱克突袭",
        ["showResearchersUnderFireInfo"] = "研究员遇袭",
        ["showTimeRiftInfo"] = "时光裂隙",
        ["showDreamsurgeInfo"] = "梦涌",
        ["showSuperbloomInfo"] = "超然",
        ["showTheBigDigInfo"] = "艾泽拉斯档案馆",
    },
    ["zhTW"] = {
        ["showLegionAssaultsInfo"] = "軍團入侵",                                 -- Legion
        ["showBrokenShoreInvasionInfo"] = "破碎海岸： 惡魔入侵",
        ["showArgusInvasionInfo"] = "阿古斯： 入侵點",
        ["showDragonRaceInfo"] = "飛龍競速",                                     -- Dragonflight
        ["showDragonGlyphs"] = "飛龍雕紋",
        ["showCampAylaagInfo"] = "艾拉格營地",
        ["showGrandHuntsInfo"] = "大狩獵",
        ["showCommunityFeastInfo"] = "集體盛宴",
        ["showDragonbaneKeepInfo"] = "攻打龍禍要塞",
        ["showElementalStormsInfo"] = "元素風暴",
        ["showFyrakkAssaultsInfo"] = "菲拉卡襲擊",
        -- ["showResearchersUnderFireInfo"] = "",
        ["showTimeRiftInfo"] = "時間裂隙",
        -- ["showDreamsurgeInfo"] = "",
        -- ["showSuperbloomInfo"] = "",
        -- ["showTheBigDigInfo"] = "",
    },
}

-- Merge saved localized strings with the global localized strings table
if L:IsEnglishLocale(L.currentLocale) then
    savedLabels[L.currentLocale] = L.defaultLabels
end

-- print("Merging", L.currentLocale, "labels...")
if savedLabels[L.currentLocale] then
    MergeTable(L, savedLabels[L.currentLocale])
elseif (L.currentLocale == "esMX") then
    MergeTable(L, savedLabels["esES"])
elseif (L.currentLocale == "ptPT") then
    MergeTable(L, savedLabels["ptBR"])
end

-----|--------------------------------------------------------------------------

ns.data = {}

function ns.data:InitializeLabels()
    -- Initialize global variable
    if (MRBP_GlobalSettings == nil) then
        MRBP_GlobalSettings = {};
    end
    if not MRBP_GlobalSettings.labels then
        MRBP_GlobalSettings.labels = {}
    end
    if not MRBP_GlobalSettings.labels[L.currentLocale] then
        MRBP_GlobalSettings.labels[L.currentLocale] = {}
    end
    if not savedLabels[L.currentLocale] then
        savedLabels[L.currentLocale] = {}
    end
    -- print("Initialized labels")
end

-- Check if the category label is neither saved locally nor in the global variable
function ns.data:IsEmptyLabel(categoryName)
    local isEmptyVariable = L:StringIsEmpty(MRBP_GlobalSettings.labels[L.currentLocale][categoryName])
    local isEmptyLocally = L:StringIsEmpty(savedLabels[L.currentLocale][categoryName])
    -- print("isEmpty", isEmptyVariable, isEmptyLocally, "-->", categoryName)
    return isEmptyVariable and isEmptyLocally
end

function ns.data:SaveLabel(categoryName, label)
    if L:StringIsEmpty(label) then return end
    -- Add or update name in global variable
    if self:IsEmptyLabel(categoryName) then
        MRBP_GlobalSettings.labels[L.currentLocale][categoryName] = label
        L[categoryName] = label
        -- print("format("Saved '%s' in '%s'", label, categoryName))
        return
    end
    -- Clean-up variable
    if (savedLabels[L.currentLocale][categoryName] and MRBP_GlobalSettings.labels[L.currentLocale][categoryName]) then
        MRBP_GlobalSettings.labels[L.currentLocale][categoryName] = nil
        -- print("Cleaned-up", L.currentLocale, categoryName)
    end
end

function ns.data:GetLabel(categoryName)
    local fallbackLabel = L.defaultLabels[categoryName]  -- only needed for non-English locales
    local variableLabel = MRBP_GlobalSettings.labels[L.currentLocale][categoryName]
    local label = L[categoryName] or variableLabel or fallbackLabel or ''
    -- print(">", categoryName, label)
    return label
end

-- Clean up variable strings already saved in this file
--> (See "PLAYER_LEAVING_WORLD" event in main file)
function ns.data:CleanUpLabels()
    if MRBP_GlobalSettings.labels then
        if (MRBP_GlobalSettings.labels[L.currentLocale] and TableIsEmpty(MRBP_GlobalSettings.labels[L.currentLocale])) then
            MRBP_GlobalSettings.labels[L.currentLocale] = nil
        end
        if TableIsEmpty(MRBP_GlobalSettings.labels) then
            MRBP_GlobalSettings.labels = nil
        end
    end
    if TableIsEmpty(MRBP_GlobalSettings) then
        MRBP_GlobalSettings = nil
    end
end

-- A collection of category names/labels for the menu entry tooltip as well
-- as the settings frame.
-- Note: The following strings will be retrieved while gaming.
--
ns.data.LoadInGameLabels = function(self)
    self:InitializeLabels()
    -- Legion
    L["showLegionAssaultsInfo"] = ns.data:GetLabel("showLegionAssaultsInfo")    --> TODO - achievementID=11201
    L["showBrokenShoreInvasionInfo"] = ns.data:GetLabel("showBrokenShoreInvasionInfo")
    L["showArgusInvasionInfo"] = ns.data:GetLabel("showArgusInvasionInfo")
    -- Dragonflight
    L["showDragonRaceInfo"] = ns.data:GetLabel("showDragonRaceInfo")
    L["showDragonGlyphs"] = ns.data:GetLabel("showDragonGlyphs")
    L["showCampAylaagInfo"] = ns.data:GetLabel("showCampAylaagInfo")
    L["showGrandHuntsInfo"] = ns.data:GetLabel("showGrandHuntsInfo")
    L["showCommunityFeastInfo"] = ns.data:GetLabel("showCommunityFeastInfo")
    L["showDragonbaneKeepInfo"] = ns.data:GetLabel("showDragonbaneKeepInfo")
    L["showElementalStormsInfo"] = ns.data:GetLabel("showElementalStormsInfo")
    L["showFyrakkAssaultsInfo"] = ns.data:GetLabel("showFyrakkAssaultsInfo")
    L["showResearchersUnderFireInfo"] = ns.data:GetLabel("showResearchersUnderFireInfo")
    L["showTimeRiftInfo"] = ns.data:GetLabel("showTimeRiftInfo")
    L["showDreamsurgeInfo"] = ns.data:GetLabel("showDreamsurgeInfo")
    L["showSuperbloomInfo"] = ns.data:GetLabel("showSuperbloomInfo")
    L["showTheBigDigInfo"] = ns.data:GetLabel("showTheBigDigInfo")
end
