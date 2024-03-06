--------------------------------------------------------------------------------
--[[ player.lua - Utilities handling player related data. ]]--
--
-- by erglo <erglo.coder+MRBP@gmail.com>
--
-- Copyright (C) 2024  Erwin D. Glockner (aka ergloCoder)
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

local AddonID, ns = ...;

local UnitFactionGroup = UnitFactionGroup;
local UnitClass = UnitClass;
local C_Covenants = C_Covenants;

local PlayerInfo = {};
ns.PlayerInfo = PlayerInfo;

----- Faction Group ------------------------------------------------------------

-- Return data about the player's faction group.
-- If KEY is given, this returns only the value of given key name. Available
-- key names are:
--> "tag"  - The file/tag name (string) <br>
--> "name" - The localized faction group name (string) <br><br>
---@param key string
---@return table|string factionGroupData_or_singleFactionGroupValue
--> Reference:<br>
--> + [Warcraft Wiki - API_UnitFactionGroup](https://warcraft.wiki.gg/wiki/API_UnitFactionGroup)
--
function PlayerInfo:GetFactionGroupData(key)
	local englishFaction, localizedFaction = UnitFactionGroup("player");
    self.factionGroupData = self.factionGroupData or {
        tag = englishFaction,
        name = localizedFaction,
    };

    if key then
        return self.factionGroupData[key];
    end
    return self.factionGroupData;
end

----- Class --------------------------------------------------------------------

-- Return data about the player's class.
-- If KEY is given, this returns only the value of given key name. Available
-- key names are:
--> "name" - The localized class name (string) <br>
--> "tag"  - The file/tag name (string) <br>
--> "ID"   - The class ID (number) <br><br>
---@param key string
---@return table|string|number classData_or_singleClassValue
--> Reference:<br>
--> + [Warcraft Wiki - API_UnitClass](https://warcraft.wiki.gg/wiki/API_UnitClass)<br>
--> + [Warcraft Wiki - ClassId](https://warcraft.wiki.gg/wiki/ClassId)
--
function PlayerInfo:GetClassData(key)
    local className, classFilename, classID = UnitClass("player");
    self.classData = self.classData or {
        name = className,
        tag = classFilename,
        ID = classID,
    };

    if key then
        return self.classData[key];
    end
    return self.classData;
end

----- Covenant -----------------------------------------------------------------

-- Return the player's currently active covenant ID. Defaults to Kyrian, if eg.
-- the player hasn't chosen a covenant, yet.
---@return Enum.CovenantType activeCovenantID
--> Reference:<br>
--> + [CovenantsDocumentation.lua](https://www.townlong-yak.com/framexml/live/Blizzard_APIDocumentationGenerated/CovenantsDocumentation.lua)<br>
--> + [Warcraft Wiki - API_C_Covenants.GetActiveCovenantID](https://warcraft.wiki.gg/wiki/API_C_Covenants.GetActiveCovenantID)
--
function PlayerInfo:GetActiveCovenantID()
    local activeCovenantID = C_Covenants.GetActiveCovenantID();
    if (activeCovenantID ~= self.activeCovenantID) then
        -- Player chose or changed the active covenant.
        self.activeCovenantID = activeCovenantID;
    end
    if (self.activeCovenantID == Enum.CovenantType.None) then
        self.activeCovenantID = Enum.CovenantType.Kyrian;
    end

    return self.activeCovenantID;
end

-- Return the covenant data of the player's active covenant. Defaults to Kyrian,
-- if eg. the player hasn't chosen a covenant, yet.
-- If KEY is given, this returns only the value of given key name. Available
-- key names are listed in "CovenantsDocumentation.lua" (follow link below).
---@param key string|nil
---@return CovenantData|string|number|number[] covenantData_or_singleCovenantValue
--> Reference:<br>
--> + [CovenantsDocumentation.lua](https://www.townlong-yak.com/framexml/live/Blizzard_APIDocumentationGenerated/CovenantsDocumentation.lua)<br>
--> + [Warcraft Wiki - API_C_Covenants.GetCovenantData](https://warcraft.wiki.gg/wiki/API_C_Covenants.GetCovenantData)
--
function PlayerInfo:GetCovenantData(key)
	local covenantData = C_Covenants.GetCovenantData(self:GetActiveCovenantID());

    if (key and covenantData) then
        return covenantData[key];
    end
    return covenantData;
end
