if (GetLocale() ~= "itIT") then
	return;
end

local ns = select(2, ...);

-- Note: Not fully translated locales need to be merged with the english defaults in order
--       to get a new table without empty strings.
-- MergeTable(destination, source)  REF.: <FrameXML/TableUtil.lua>
MergeTable(ns.L,  {
	--[[ Tooltips ]]--
	TOOLTIP_CLICKTEXT_MINIMAPBUTTON = "Clicca col pulsante destro per selezionare l'espansione",
	TOOLTIP_REQUIREMENTS_TEXT_S = 'Completa "%s" per sbloccare il contenuto',
	}
);