## Latest Changes

## [1.0.1+100206] - 2024-03-27

### Changed

* ExpansionTooltip: raised frame level by 10 in order to avoid overlapping with the dropdown menu.
* MenuTooltip: reset frame strata.
* MenuTooltip: deactivating ALL optional hint icons now hides the whole column.
* MenuTooltip: deactivating the optional expansion icons now hides the whole column.

### Fixed

* [Issue #21] MenuTooltip: the dropdown menu is now clamped to the screen.
* MenuTooltip: expansion icons didn't hide when deactivating their settings option, only after reloading the UI.
* [Issue #22] MenuTooltip: line color couldn't be changed since some cells didn't have a font string layer.

## [1.0.0+100206] - 2024-03-25

### Added

* Dragonflight: added `Paragon reputation progress` to major factions.
* Legion: added pseudo-requirement quest "Aiding Khadgar" for Evoker.
* Warlords of Draenor: added an optional list of yet uncollected `treasures` in Draenor.
* MenuTooltip: added optional icon hint for pending reputation reward from major factions.
* MenuTooltip: added optional icon hint for when the Timewalking Vendor is visiting.
* ReputationTooltip: Dragonflight major factions can be `separated` into its own tooltip.
* ExpansionTooltip: expansion content tooltips are now `scrollable`.
* Tooltips: added `new tooltip handler` [LibQTip](https://www.curseforge.com/wow/addons/libqtip-1-0) for better organizing and displaying the tooltip content.

### Changed

* Updated TOC file version to `WoW 10.2.6`.
* L10n: updated locale files.
* Settings: reorganized addon settings into multiple subcategories.
* Minimap Button: right-clicking the minimap button now toggles the menu.
* Legion + BfA: refined bounty data retrieval.
* ExpansionTooltip: moved expansion unlocking requirements to in-progress missions; expansion tooltips are no longer completely locked.
* Tooltips: converted content to the new tooltip format.

### Fixed

* Dragonflight: Superbloom event details didn't appear while in Emerald Dream zone; only worked outside the zone.

### Removed

* Tooltips: removed legacy tooltip.
&nbsp;

## Previous Changes

* For a complete history of changes see the [changelog file on GitHub](https://github.com/erglo/mission-report-button-plus/blob/main/CHANGELOG.md "CHANGELOG.md").

&nbsp;  
⚠️**Note:** _This is an pre-release version and still in development._
