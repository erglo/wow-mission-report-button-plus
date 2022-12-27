if (GetLocale() ~= "frFR") then
	return;
end

local ns = select(2, ...);

-- Note: Not fully translated locales need to be merged with the english defaults in order
--       to get a new table without empty strings.
-- MergeTable(destination, source)  REF.: <FrameXML/TableUtil.lua>
MergeTable(ns.L,  {
	--[[ Tooltips ]]--
	TOOLTIP_CLICKTEXT_MINIMAPBUTTON = "Cliquez droit pour sélectionner l'extension",
	TOOLTIP_REQUIREMENTS_TEXT_S = 'Achevez la quête « %s » pour débloquer ce contenu',
	}
);