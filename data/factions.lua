--------------------------------------------------------------------------------
--[[ factions.lua - Utilities for handling Factions related data prior to Dragonflight. ]]--
--
-- by erglo <erglo.coder+MRBP@gmail.com>
--
-- Copyright (C) 2024  Erwin D. Glockner (aka erglo, ergloCoder)
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
-- Further reading:
-- + REF.: <https://warcraft.wiki.gg/wiki/Reputation>
-- + REF.: <https://warcraft.wiki.gg/wiki/FactionID>
-- + REF.: <https://www.townlong-yak.com/framexml/live/Blizzard_APIDocumentationGenerated/ReputationInfoDocumentation.lua>  
-- + REF.: <https://www.townlong-yak.com/framexml/live/Blizzard_UIPanels_Game/ReputationFrame.lua>
-- + REF.: <https://www.townlong-yak.com/framexml/live/Blizzard_ActionBar/ReputationBar.lua>
-- + REF.: <https://warcraft.wiki.gg/wiki/API_C_Reputation.GetFactionDataByID>
-- + REF.: <https://warcraft.wiki.gg/wiki/API_C_Reputation.IsFactionParagon>
-- + REF.: <https://warcraft.wiki.gg/wiki/API_C_Reputation.GetFactionParagonInfo>
-- + REF.: <https://warcraft.wiki.gg/wiki/API_C_GossipInfo.GetFriendshipReputation>
-- + REF.: <https://warcraft.wiki.gg/wiki/API_C_GossipInfo.GetFriendshipReputationRanks>
-- (see also the function comments section for more reference)
-- 
--------------------------------------------------------------------------------

local AddonID, ns = ...;
local L = ns.L;

-- Upvalues
local C_Reputation = C_Reputation;
local BreakUpLargeNumbers = BreakUpLargeNumbers;
local HasMajorFactionMaximumRenown = C_MajorFactions.HasMaximumRenown;
local GetMajorFactionData = C_MajorFactions.GetMajorFactionData;
local GetFriendshipReputation = C_GossipInfo.GetFriendshipReputation;
local GetFriendshipReputationRanks = C_GossipInfo.GetFriendshipReputationRanks;
local CreateAtlasMarkup = CreateAtlasMarkup;

local PlayerInfo = ns.PlayerInfo;  --> <data\player.lua>
local ExpansionInfo = ns.ExpansionInfo;  --> <data\expansion.lua>

--------------------------------------------------------------------------------

local LocalFactionInfo = {};
ns.FactionInfo = LocalFactionInfo;

----- Wrapper -----

-- Retrieve the data for given faction ID.
-- 
-- `FactionData` fields:
-- * `factionID` --> number
-- * `name` --> cstring
-- * `description` --> cstring
-- * `reaction` --> luaIndex
-- * `currentReactionThreshold` --> number
-- * `nextReactionThreshold` --> number
-- * `currentStanding` --> number
-- * `atWarWith` --> bool
-- * `canToggleAtWar` --> bool
-- * `isChild` --> bool
-- * `isHeader` --> bool
-- * `isHeaderWithRep` --> bool
-- * `isCollapsed` --> bool
-- * `isWatched` --> bool
-- * `hasBonusRepGain` --> bool
-- * `canSetInactive` --> bool
-- * `isAccountWide` --> bool
-- 
---@param factionID number
---@return FactionData?
--
-- REF.: [ReputationInfoDocumentation.lua](https://www.townlong-yak.com/framexml/live/Blizzard_APIDocumentationGenerated/ReputationInfoDocumentation.lua)
-- 
function LocalFactionInfo:GetFactionDataByID(factionID)
    return C_Reputation.GetFactionDataByID(factionID);
end

-- Check if given faction supports paragon reputation.
function LocalFactionInfo:IsFactionParagon(factionID)
    return C_Reputation.IsFactionParagon(factionID);
end

-- Return the wrapped paragon info for given faction.
function LocalFactionInfo:GetFactionParagonInfo(factionID)
	local currentValue, threshold, rewardQuestID, hasRewardPending, tooLowLevelForParagon = C_Reputation.GetFactionParagonInfo(factionID);
	---@class FactionParagonInfo
	---@field currentValue number
	---@field threshold number
	---@field rewardQuestID number
	---@field hasRewardPending boolean
	---@field tooLowLevelForParagon boolean
	return {
		currentValue = currentValue,
		threshold = threshold,
		rewardQuestID = rewardQuestID,
		hasRewardPending = hasRewardPending,
		tooLowLevelForParagon = tooLowLevelForParagon,
	};
end

-- Retrieve the data of the currently watched faction.
---@return FactionData? watchedFactionData
--
function LocalFactionInfo:GetWatchedFactionData()
    return C_Reputation.GetWatchedFactionData();
end

function LocalFactionInfo:IsMajorFaction(factionID)
    C_Reputation.IsMajorFaction(factionID);
end

----- Helper Functions ---------------------------------------------------------

function LocalFactionInfo:HasMaximumReputation(factionData)
    if self:IsFactionParagon(factionData.factionID) then return; end

    if (factionData.reputationType == self.ReputationType.Friendship) then
        local friendshipData = GetFriendshipReputation(factionData.factionID);
    	if (friendshipData and friendshipData.friendshipFactionID > 0) then
    		local repRankInfo = GetFriendshipReputationRanks(factionData.factionID);
    		return repRankInfo.currentLevel == repRankInfo.maxLevel;
    	end
    end
    if (factionData.reputationType == self.ReputationType.MajorFaction) then
        return HasMajorFactionMaximumRenown(factionData.factionID);
    end
    -- ReputationType.Standard
    return factionData.reaction == MAX_REPUTATION_REACTION;  --> 8
end

-- REF.: [SharedColorConstants.lua](https://www.townlong-yak.com/framexml/live/Blizzard_SharedXML/SharedColorConstants.lua)
-- 
function LocalFactionInfo:GetFactionStandingColor(factionData)
    return FACTION_BAR_COLORS[factionData.reaction];
end

----- Sorting -----

function LocalFactionInfo.SortAscendingByFactionID(dataA, dataB)
    return dataA.factionID < dataB.factionID;  --> 0-9
end

-- REF.: [SortUtil.lua](https://www.townlong-yak.com/framexml/live/Blizzard_SharedXML/SortUtil.lua)
function LocalFactionInfo.SortAscendingByFactionName(dataA, dataB)
    -- return SortUtil.CompareUtf8i(dataA.name, dataB.name);  --> A-Z
    return dataA.name < dataB.name;  --> A-Z
end

----- Unit Faction Groups -----

LocalFactionInfo.PlayerFactionGroupID = UnitFactionGroup("player");
LocalFactionInfo.PlayerFactionGroupColor = PLAYER_FACTION_COLORS[PLAYER_FACTION_GROUP[LocalFactionInfo.PlayerFactionGroupID]];
LocalFactionInfo.PlayerFactionGroupAtlas = LocalFactionInfo.PlayerFactionGroupID == "Horde" and "questlog-questtypeicon-horde" or "questlog-questtypeicon-alliance"

-- {Alliance=1, Horde=2, Neutral=3, Player=1|2}
LocalFactionInfo.UnitFactionGroupID = EnumUtil.MakeEnum(
    PLAYER_FACTION_GROUP[1],
    PLAYER_FACTION_GROUP[0],
    "Neutral"
);
LocalFactionInfo.UnitFactionGroupID["Player"] = LocalFactionInfo.UnitFactionGroupID[LocalFactionInfo.PlayerFactionGroupID];

function LocalFactionInfo:IsSuitableFactionGroupForPlayer(unitFactionGroup)
    return (unitFactionGroup == self.UnitFactionGroupID.Player or
            unitFactionGroup == self.UnitFactionGroupID.Neutral);
end

----- Reputation Type -----

LocalFactionInfo.ReputationType = EnumUtil.MakeEnum(
	"Standard",
	"Friendship",
	"MajorFaction"
);

-- Determine the given faction's reputation type.
function LocalFactionInfo:GetReputationType(factionData)
	if not factionData then return; end

	local friendshipData = GetFriendshipReputation(factionData.factionID);
	local isFriendshipReputation = friendshipData and friendshipData.friendshipFactionID > 0;
	if isFriendshipReputation then
		return self.ReputationType.Friendship;
	end

	if self:IsMajorFaction(factionData.factionID) then
		return self.ReputationType.MajorFaction;
	end

	return self.ReputationType.Standard;
end

local function GetColoredPvPIconText(color, appendText)
	local FontColor = color or LocalFactionInfo.PlayerFactionGroupColor;
	local iconString = CreateAtlasMarkup("questlog-questtypeicon-pvp", 16, 16);  -- LocalFactionInfo.PlayerFactionGroupAtlas
	local text = FontColor:WrapTextInColorCode(iconString..L.PVP);
    if appendText then
        return L.TEXT_DELIMITER..L.PARENS_TEMPLATE:format(text);
    end

    return text;
end

----- Data ---------------------------------------------------------------------

local FACTION_ID_LIST = {
    [ExpansionInfo.data.SHADOWLANDS.ID] = {
        -- REF.: [Shadowlands Reputation Overview](https://www.wowhead.com/de/guide/shadowlands-reputations-overview)
        [LocalFactionInfo.UnitFactionGroupID.Neutral] = {
            ["2407"] = {englishName="The Ascended", icon=3555147},              -- Bastion, criteria-of=14315/shadowlands-diplomat
            ["2410"] = {englishName="The Undying Army", icon=3604102},          -- Maldraxxus, criteria-of=14315/shadowlands-diplomat
            ["2413"] = {englishName="Court of Harvesters", icon=3540525},       -- Revendreth, criteria-of=14315/shadowlands-diplomat
            ["2432"] = {englishName="Ve'nari", icon=1392953},                   -- The Maw
            ["2439"] = {englishName="The Avowed", icon=460694},                 -- Revendreth (Halls of Atonement dungeon) 3601526
            ["2464"] = {englishName="Court of Night", icon=3235306},           -- Ardenweald
            ["2465"] = {englishName="The Wild Hunt", icon=3517784},             -- Ardenweald, criteria-of=14315/shadowlands-diplomat
            ["2470"] = {englishName="Death's Advance", icon=4083292},           -- Korthia, The Maw (Added in 9.1)
            ["2472"] = {englishName="The Archivists' Codex", icon=2101967},     -- Korthia, The Maw (Added in 9.1)
            ["2478"] = {englishName="The Enlightened", icon=4280206},           -- Zereth Mortis (Added in 9.2)
        },
    },
    [ExpansionInfo.data.BATTLE_FOR_AZEROTH.ID] = {
        -- REF.: [Battle for Azeroth Reputation Overview](https://www.wowhead.com/guide/battle-for-azeroth-reputation-overview)
        [LocalFactionInfo.UnitFactionGroupID.Alliance] = {
            ["2159"] = {englishName="7th Legion", icon=2065569},
            ["2160"] = {englishName="Proudmoore Admiralty", icon=2065573},      -- criteria-of=12947/azerothian-diplomat
            ["2161"] = {englishName="Order of Embers", icon=2065572},           -- criteria-of=12947/azerothian-diplomat
            ["2162"] = {englishName="Storm's Wake", icon=2065574},              -- criteria-of=12947/azerothian-diplomat
            ["2400"] = {englishName="Waveblade Ankoan", icon=2909045},          -- criteria-of=13250/battle-for-azeroth-pathfinder-part-two (Added in 8.2)
        },
        [LocalFactionInfo.UnitFactionGroupID.Horde] = {
            ["2103"] = {englishName="Zandalari Empire", icon=2065579},
            ["2156"] = {englishName="Talanji's Expedition", icon=2065575},
            ["2157"] = {englishName="The Honorbound", icon=2065571},            -- criteria-of=12947/azerothian-diplomat
            ["2158"] = {englishName="Voldunai", icon=2065577},
            ["2373"] = {englishName="The Unshackled", icon=2821782},            -- criteria-of=13250/battle-for-azeroth-pathfinder-part-two (Added in 8.2)
        },
        [LocalFactionInfo.UnitFactionGroupID.Neutral] = {
            ["2163"] = {englishName="Tortollan Seekers", icon=2065576},         -- criteria-of=12947/azerothian-diplomat
            ["2164"] = {englishName="Champions of Azeroth", icon=2065570},      -- criteria-of=12947/azerothian-diplomat
            ["2391"] = {englishName="Rustbolt Resistance", icon=2909316},       -- criteria-of=13250/battle-for-azeroth-pathfinder-part-two (Added in 8.2)
            ["2415"] = {englishName="Rajani", icon=3196265},                    -- (Added in 8.3)
            ["2417"] = {englishName="Uldum Accord", icon=3196264},              -- (Added in 8.3)
        },
    },
    [ExpansionInfo.data.LEGION.ID] = {
        -- REF.: [Legion Reputation Overview](https://www.wowhead.com/guide/reputation/legion/overview)
        [LocalFactionInfo.UnitFactionGroupID.Neutral] = {
            ["1828"] = {englishName="Highmountain Tribe", icon=1450996},        -- , achievements={10672, 11159}},
            ["1859"] = {englishName="The Nightfallen", icon=1450998},           -- , achievements={10672, 11159}},
            ["1883"] = {englishName="Dreamweavers", icon=1450995},              -- , achievements={10672, 11159}},
            ["1894"] = {englishName="The Wardens", icon=1451000},               -- , achievements={10672, 11159}},
            ["1900"] = {englishName="Court of Farondis", icon=1450994},         -- , achievements={10672, 11159}},
            ["1948"] = {englishName="Valarjar", icon=1450999},                  -- , achievements={10672, 11159}},
            ["2045"] = {englishName="Armies of Legionfall", icon=1708507},
            ["2165"] = {englishName="Army of the Light", icon=1708506},
            ["2170"] = {englishName="Argussian Reach", icon=1708505},
        },
    },
    [ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID] = {
        -- REF.: [Warlords of Draenor Reputation Overview](https://www.wowhead.com/de/guide/reputation/wod/warlords-of-draenor-reputation-overview)
        [LocalFactionInfo.UnitFactionGroupID.Alliance] = {
            ["1682"] = {englishName="Wrynn's Vanguard", icon=1042294, isPVP=true},  -- achievementID=9214 (PvP)
            ["1710"] = {englishName="Sha'tari Defense", icon=1042739},          -- achievementID=9476
            ["1731"] = {englishName="Council of Exarchs",  icon=1048727},       -- achievementID=9470
            ["1847"] = {englishName="Hand of the Prophet", icon=930038},        -- Tanaan Diplomat, achievementID=10350
        },
        [LocalFactionInfo.UnitFactionGroupID.Horde] = {
            ["1445"] = {englishName="Frostwolf Orcs", icon=1044164},            -- achievementID=9471
            ["1681"] = {englishName="Vol'jin's Spear", icon=1042727, isPVP=true},  -- achievementID=9215 (PvP)
            ["1708"] = {englishName="Laughing Skull Orcs", icon=1043559},       -- achievementID=9475
            ["1848"] = {englishName="Vol'jin's Headhunters", icon=5197938},     -- Tanaan Diplomat, achievementID=10349 (Horde), 10350 (Alliance)
        },
        [LocalFactionInfo.UnitFactionGroupID.Neutral] = {
            ["1515"] = {englishName="Arakkoa Outcasts", icon=1042646},          -- achievementID=9469
            ["1711"] = {englishName="Steamwheedle Preservation Society", icon=1052654},  -- achievementID=9472
            ["1849"] = {englishName="Order of the Awakened", icon=1240656},     -- Tanaan Diplomat, achievementID=10349 (Horde), 10350 (Alliance)
            ["1850"] = {englishName="The Saberstalkers", icon=1240657},         -- Tanaan Diplomat, achievementID=10349 (Horde), 10350 (Alliance)
        },
        --> TODO - Add "Barracks Bodyguards" ???
    },
};

local friendshipType = LocalFactionInfo.ReputationType.Friendship;
-- C_GossipInfo.GetFriendshipReputation(2376)

local BONUS_FACTION_ID_LIST = {
    [ExpansionInfo.data.WAR_WITHIN.ID] = {
        [LocalFactionInfo.UnitFactionGroupID.Neutral] = {,
	    ["2640"] = {englishName="Brann Bronzebeard", icon=236444},
            ["2601"] = {englishName="The Weaver", icon=4549278, parentFactionID=2600},
            ["2605"] = {englishName="The General", icon=4549279, parentFactionID=2600},
            ["2607"] = {englishName="The Vizier", icon=4549280, parentFactionID=2600},
	},
    },
    [ExpansionInfo.data.DRAGONFLIGHT.ID] = {
        [LocalFactionInfo.UnitFactionGroupID.Neutral] = {
            ["2550"] = {englishName="Cobalt Assembly", icon=135732},
	    ["2544"] = {englishName="Artisan's Consortium - Dragon Isles Branch", icon=4643982},
	    ["2517"] = {englishName="Wrathion", icon=896771},  -- criteria-of=16494/loyalty-to-the-prince
            ["2518"] = {englishName="Sabellian", icon=236469},  -- criteria-of=16760/the-obsidian-bloodline
	    ["2526"] = {englishName="Winterpelt Furbolg", icon=1535070},
	    ["2553"] = {englishName="Soridormi", icon=3193844},
            ["2615"] = {englishName="Azerothian Archives", icon=5315246},  -- added in 10.2.5
            ["2568"] = {englishName="Glimmerogg Racer", icon=4632789},  -- added in 10.1.0
	},
    },
    [ExpansionInfo.data.BATTLE_FOR_AZEROTH.ID] = {
        [LocalFactionInfo.UnitFactionGroupID.Alliance] = {
            ["2375"] = {englishName="Hunter Akana", reputationType=friendshipType, parentFactionID=2400},      -- achievements={13743, 13753, 13758} -- criteria-of=13704/nautical-battlefield-training
            ["2376"] = {englishName="Farseer Ori", reputationType=friendshipType, parentFactionID=2400},       -- achievements={13745, 13755, 13760} -- criteria-of=13704/nautical-battlefield-training
            ["2377"] = {englishName="Bladesman Inowari", reputationType=friendshipType, parentFactionID=2400}, -- achievements={13744, 13754, 13759} -- criteria-of=13704/nautical-battlefield-training
        },
        [LocalFactionInfo.UnitFactionGroupID.Horde] = {
            ["2388"] = {englishName="Poen Gillbrack", reputationType=friendshipType, parentFactionID=2373},    -- achievements={13747, 13751, 13756} -- criteria-of=13645/nautical-battlefield-training
            ["2389"] = {englishName="Neri Sharpfin", reputationType=friendshipType, parentFactionID=2373},     -- achievements={13746, 13749, 13750} -- criteria-of=13645/nautical-battlefield-training
            ["2390"] = {englishName="Vim Brineheart", reputationType=friendshipType, parentFactionID=2373},    -- achievements={13748, 13752, 13757} -- criteria-of=13645/nautical-battlefield-training
        },
    },
    [ExpansionInfo.data.LEGION.ID] = {
        [LocalFactionInfo.UnitFactionGroupID.Neutral] = {
            ["1090"] = {englishName="Kirin Tor", icon=1450997},
            ["2135"] = {englishName="Chromie"},
            ["2018"] = {englishName="Talon's Vengeance", icon=134496, isPVP=true},
        },
    },
    [ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID] = {                             --> TODO -  achievementID=9499 "Wingmen"
        [LocalFactionInfo.UnitFactionGroupID.Alliance] = {
            ["1733"] = {englishName="Delvar Ironfist"},
            ["1738"] = {englishName="Defender Illona"},
        },
        [LocalFactionInfo.UnitFactionGroupID.Horde] = {
            ["1739"] = {englishName="Vivianne"},
            ["1740"] = {englishName="Aeda Brightdawn"},
        },
        [LocalFactionInfo.UnitFactionGroupID.Neutral] = {
            ["1736"] = {englishName="Tormmok"},
            ["1737"] = {englishName="Talonpriest Ishaal"},
            ["1741"] = {englishName="Leorajh"},
        },
    },
};

-- REF.: [ArtTextureID.lua](https://www.townlong-yak.com/framexml/live/Helix/ArtTextureID.lua)
local BONUS_FACTION_STANDING_ICON_LIST = {
    [1] = 236681,  --> "Interface/Icons/Achievement_Reputation_01"
	[2] = 236682,  --> "Interface/Icons/Achievement_Reputation_02"
	[3] = 236683,  --> "Interface/Icons/Achievement_Reputation_03"
	[4] = 236684,  --> "Interface/Icons/Achievement_Reputation_04"
	[5] = 236685,  --> "Interface/Icons/Achievement_Reputation_05"
	[6] = 236686,  --> "Interface/Icons/Achievement_Reputation_06"
	[7] = 236687,  --> "Interface/Icons/Achievement_Reputation_07"
	[8] = 236688,  --> "Interface/Icons/Achievement_Reputation_08"
};

local function GetBonusFactionStandingIcon(factionData)
    return BONUS_FACTION_STANDING_ICON_LIST[factionData.reaction];
end

function LocalFactionInfo:GetExpansionFactionIDs(expansionID)
    return FACTION_ID_LIST[expansionID];
end

function LocalFactionInfo:GetExpansionBonusFactionIDs(expansionID)
    return BONUS_FACTION_ID_LIST[expansionID];
end

local function ConvertFriendshipToFactionInfo(friendshipData)
    local factionID = friendshipData.friendshipFactionID;
    local convertedFactionInfo = {
        ["factionID"] = factionID,
        ["name"] = friendshipData.name,
        ["description"] = friendshipData.text,
        ["reaction"] = 5, -- Friendships always use same  --> <FrameXML/.../ReputationBar.lua>
        ["currentReactionThreshold"] = friendshipData.reactionThreshold,
        ["nextReactionThreshold"] = friendshipData.nextThreshold,
        ["currentStanding"] = friendshipData.standing,
        ["atWarWith"] = false,
        ["canToggleAtWar"] = false,
        ["isAccountWide"] = C_Reputation.IsAccountWideReputation(factionID),
    };

    return convertedFactionInfo;
end

function LocalFactionInfo:GetAllFactionDataForExpansion(expansionID, isBonusFaction, sortFunc)
    local factionIDs = isBonusFaction and self:GetExpansionBonusFactionIDs(expansionID) or self:GetExpansionFactionIDs(expansionID);
    if not factionIDs then return; end

    local factionData = {};
    for unitFactionGroup, expansionFactionIDs in pairs(factionIDs) do
        if self:IsSuitableFactionGroupForPlayer(unitFactionGroup) then
            for factionIDstring, factionTbl in pairs(expansionFactionIDs) do
                local factionInfo = self:GetFactionDataByID(tonumber(factionIDstring));

                if (not factionInfo and factionTbl.reputationType == self.ReputationType.Friendship) then
                    -- Note: some factions, eg. BfA bonus factions, are not in the ReputationFrame and don't seem to
                    -- have faction data directly available, but their friendshipInfo has enough data in a slightly
                    -- different format which we are going to use.
                    local friendshipData = GetFriendshipReputation(tonumber(factionIDstring));
                    factionInfo = ConvertFriendshipToFactionInfo(friendshipData);
                end

                if factionInfo then
                    factionInfo.icon = factionTbl.icon or isBonusFaction and GetBonusFactionStandingIcon(factionInfo) or 0;
                    factionInfo.isPVP = factionTbl.isPVP;
                    factionInfo.reputationType = factionTbl.reputationType or self:GetReputationType(factionInfo);
                    -- Name formatting
                    if (factionInfo.reputationType == self.ReputationType.Friendship) then
                        local appendText = true;
                        factionInfo.name = factionInfo.name..self:GetFriendshipReputationProgressText(factionInfo, appendText);
                    end
                    if factionInfo.isPVP then
                        local appendText = true;
                        factionInfo.name = factionInfo.name..GetColoredPvPIconText(nil, appendText);
                    end
                    tinsert(factionData, factionInfo);
                end
            end
        end
    end

    table.sort(factionData, sortFunc or self.SortAscendingByFactionName);

    return factionData;
end

----- Formatting -----

-- Retrieve the player's current reputation standing with given faction as text.
function LocalFactionInfo:GetFactionReputationStandingText(factionData)
    if (factionData.reputationType == self.ReputationType.Standard) then
        local gender = PlayerInfo:GetPlayerSex();
        local reputationStandingText = L:GetText("FACTION_STANDING_LABEL" .. factionData.reaction, gender);
        return reputationStandingText;
    end
    if (factionData.reputationType == self.ReputationType.Friendship) then
        local friendshipData = GetFriendshipReputation(factionData.factionID);
        return friendshipData and friendshipData.reaction or '';
    end
    if (factionData.reputationType == self.ReputationType.MajorFaction) then
        local majorFactionData = GetMajorFactionData(factionData.factionID);
        return majorFactionData and L.RENOWN_LEVEL_LABEL..L.TEXT_DELIMITER..majorFactionData.renownLevel;
    end

    return L.UNKNOWN;
end

-- Build a generic reputation progress string from given faction data and return it.
function LocalFactionInfo:GetFactionReputationProgressText(factionData)
    local minValue, maxValue, currentValue;
    local isCapped = self:HasMaximumReputation(factionData);

    if (factionData.reputationType == self.ReputationType.Standard) then
        minValue, maxValue, currentValue = isCapped and 0 or factionData.currentReactionThreshold, factionData.nextReactionThreshold, factionData.currentStanding;

    elseif (factionData.reputationType == self.ReputationType.Friendship) then
        local friendshipData = GetFriendshipReputation(factionData.factionID);
        minValue, maxValue, currentValue = (isCapped and 0 or friendshipData.reactionThreshold), friendshipData.nextThreshold or friendshipData.standing, friendshipData.standing;

    elseif (factionData.reputationType == self.ReputationType.MajorFaction) then
        local majorFactionData = GetMajorFactionData(factionData.factionID);
        minValue = 0;
        maxValue = majorFactionData and majorFactionData.renownLevelThreshold or 0;
        currentValue = majorFactionData and majorFactionData.renownReputationEarned or 0;

    else
        minValue, maxValue, currentValue = 0, 0, 0;
    end

    if self:IsFactionParagon(factionData.factionID) then
	    local paragonInfo = self:GetFactionParagonInfo(factionData.factionID);
        local value = mod(paragonInfo.currentValue, paragonInfo.threshold);
        if paragonInfo.hasRewardPending then
            value = value + paragonInfo.threshold;
        end
        minValue, maxValue, currentValue = 0, paragonInfo.threshold, value;
    end

    -- Normalize values
    maxValue = maxValue - minValue;
    currentValue = currentValue - minValue;

    local reputationProgressText = L.REPUTATION_PROGRESS_FORMAT:format(BreakUpLargeNumbers(currentValue), BreakUpLargeNumbers(maxValue));
    return reputationProgressText;
end

function LocalFactionInfo:GetFriendshipReputationProgressText(factionData, appendText)
    local friendshipData = GetFriendshipReputation(factionData.factionID);
    if (friendshipData and friendshipData.friendshipFactionID > 0) then
        local reputationRankInfo = GetFriendshipReputationRanks(factionData.factionID);
        local reputationRankProgressText = L.REPUTATION_PROGRESS_FORMAT:format(reputationRankInfo.currentLevel, reputationRankInfo.maxLevel);
        if appendText then
            return L.TEXT_DELIMITER..L.PARENS_TEMPLATE:format(reputationRankProgressText);
        end

        return reputationRankProgressText;
    end
end

--@do-not-package@
----- Tests --------------------------------------------------------------------

-- local function NormalizeBarValues(minValue, maxValue, currentValue)
-- 	maxValue = maxValue - minValue;
-- 	currentValue = currentValue - minValue;
-- 	minValue = 0;
-- 	return minValue, maxValue, currentValue;
-- end

-- function TestFactions()
--     print(ExpansionInfo.data.WARLORDS_OF_DRAENOR.name)

--     local factionData = LocalFactionInfo:GetAllFactionDataForExpansion(ExpansionInfo.data.WARLORDS_OF_DRAENOR.ID);

--     for i, faction in ipairs(factionData) do
--         local reputationProgressText = LocalFactionInfo:GetFactionReputationProgressText(faction);
--         local reputationStandingText = LocalFactionInfo:GetFactionReputationStandingText(faction);

--         print("-", i, faction.factionID, faction.name);
--         -- print("-->", faction.atWarWith, faction.isChild, faction.hasBonusRepGain);
--         print("-->", reputationStandingText, L.PARENS_TEMPLATE:format(reputationProgressText));
--     end
-- end

----- Bonus Factions -----

-- [ExpansionInfo.data.LEGION.ID] = {
--     [LocalFactionInfo.UnitFactionGroupID.Neutral] = {
--         ["1090"] = {englishName="Kirin Tor", icon=1450997},
--         ["2135"] = {englishName="Chromie"},
--         -- ["1899"] = {englishName="Moonguard"},  --> for Hunters only ???
--         -- ["2018"] = {englishName="Talon's Vengeance", icon=134496, isPVP=true},  --> via Battlepet quests ???
--         -- ["1975"] = {englishName="Conjurer Margoss"},
--         -- [""] = {englishName="", icon=0},

--         --> TODO
--         -- C_Reputation.AreLegacyReputationsShown()
--         -- C_Reputation.IsAccountWideReputation(factionID)
--         -- Add Faction 1947 "Illidari" - neutral, but for Demon Hunters only!
--         -- Add Faction 1975 "Conjurer Margoss" + 4? others - Fishing - add to own category ???
--         -- Include achievements, eg. "criteria-of" as iconString
--     },
-- },
--@end-do-not-package@
