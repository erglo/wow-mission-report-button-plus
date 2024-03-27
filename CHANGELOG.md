# Changelog

All notable changes to this project will be documented in this file (or linked to this file).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2024-03-27

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

## [v0.21.1+100205] - 2024-01-23

### Changed

* Uploaded locale files.

## [v0.21.0+100205] - 2024-01-23

### Added

* Dragonflight: added the Big Dig event details for the `Azerothian Archives`.

### Changed

* Updated TOC file version to `WoW 10.2.5`.

## [v0.20.1+100200] - 2023-12-07

### Changed

* Updated dragon glyphs counter for Emerald Dream.

## [v0.20.0+100200] - 2023-11-09

### Added

* Dragonflight: added `Superbloom` event details.

### Changed

* Updated TOC file version to `WoW 10.2.0`.
* Adapted API changes concerning `C_AddOns` and `Blizzard_SettingControls.lua`.
* PKGMETA file: added `tools-used` section.

### Fixed

* [Issue #19] Due to additional arguments in `CreateSettingsButtonInitializer(...)` an assertion error occurred. (Thanks to [SpareSimian](https://github.com/SpareSimian) this has been a quick fix.)

## [v0.19.0+100107] - 2023-10-07

### Added

* Dragon Race: added `Eastern Kingdoms Cup` details.
* Dragonflight: added `Dreamsurge` event details.
* Dragonflight: re-added `Iskaara Community Feast` event details, with manual timer.
* Dragonflight: added a manual timer to `Researchers Under Fire` for the other zones in Dragonflight outside of Zaralek Cavern.
* Dragonflight: cross-reference for `Camp Aylaag` with the achievement "The Ohn'ahran Trail".

### Changed

* Updated the Addon Compartment entry for `Camp Aylaag`; it shows the area name now.
* Updated README files.

## [0.18.0+100107] - 2023-09-06

### Changed

* Updated TOC file version to `WoW 10.1.7`.

### Fixed

* [Issue #17] Changes in `C_MajorFactions` with `WoW 10.1.7` caused an error with sorting the DF major faction data. (Thanks to [justinkb](https://github.com/justinkb) for this quick fix.)

## [0.17.3+100105] - 2023-09-01

### Fixed

* [Issue #15] The Legion status was not working after unlocking the command table.
* Fixed bonus event message for world quests; `GetCalendarEventLink` couldn't get needed informations properly.

## [0.17.2+100105] - 2023-07-21

### Fixed

* [Issue #13] An error occurred in `labels.lua` in the clean-up function. Said function was called as soon as the player leaves the world but the event fired presumably before the global variable was initialized. Now it is only called once when the player quits the game.
* English default strings haven't been merged with the global localization table correctly.
* Corrected a translated string in `deDE` locale.

## [0.17.1+100105] - 2023-07-20

### Changed

* Debug mode was partially still active. It's turned it off now.

## [0.17.0+100105] - 2023-07-20

### Added

* Data: Dynamic category names retrieval; English default names will be replaced in non-English locales as soon an event is active.
* Dragonflight: added `Time Rift` details.

### Changed

* Updated TOC file version to `WoW 10.1.5`.
* Refined `area names` for some POI details.
* `Timewalking Vendor` details for Warlords of Draenor and Legion don't depend on calendar event data anymore.
* Calendar data look-up process refurbished.

### Fixed

* Not all `Addon Compartment` icons have been displayed; using now mostly inline icons instead.

## [0.16.4+100100] - 2023-07-07

### Added

* The `Timewalking Vendor` details have been added to the Addon Compartment tooltip.
* New locale `zhCN`, thanks to [EK (EKE00372)](https://github.com/EKE00372).

### Fixed

* Due to the recent changes in processing calendar day events the `Timewalking Vendor` details didn't show up in the tooltip.

## [0.16.3+100100] - 2023-06-29

### Fixed

* The calendar day event message which appears in chat after logging-in during bonus events didn't show the correct amount of days left.

## [0.16.2+100100] - 2023-06-26

### Fixed

* [Issue #10] Mission Complete messages appeared in chat even though the chat notifications have been disabled in the settings.

## [0.16.1+100100] - 2023-06-22

### Fixed

* [Issue #9] Due to character encoding differences an error occurred for the `zhTW` locale users due to the recent changes in displaying additionally the closest flight point for `Camp Aylaag`.

## [0.16.0+100100] - 2023-06-21

### Added

* New line for contributed translations in the about this addon section in the settings.
* New locale `zhTW`, thanks to [EK (EKE00372)](https://github.com/EKE00372).
* The Addon Compartment entry is now optional and can be de-/activated in the settings.
* Dragonflight: added details for the events `Dragonriding Race`, `Camp Aylaag`, `Grand Hunts`, `Siege on Dragonbane Keep` and `Elemental Storms` to the Addon Compartment.
* Warlords of Draenor: the `Garrison Invasion alert icon` on top of the Garrison Landing Page (Mission) Report frame can now be hidden permanently, even if your Garrison is being invaded.

### Changed

* Updated locale files, localizations will now be automatically integrated from CurseForge during GitHub workflow.
* Updated readme files and added a _Thank You!_ section for the contributors.
* Dragonflight: the `Aylaag Camp` entry now additionally shows the name of the closest flight point for easier camp location identification.

### Removed

* Some of the world map icons have been merged in `WoW 10.0.7` which led to the problem that the details about the `Iskaara Community Feast` event on the Dragon Isles can no longer be retrieved by its area POI icon and had to be removed.

## [0.15.1+100100] - 2023-06-15

### Added

* Shadowlands: cross-reference for `Covenant Campaigns` with the achievement "Dead Men Tell Some Tales".

### Fixed

* BfA achievement for `Faction Assaults` didn't show the tracking hint properly.

## [0.15.0+100100] - 2023-06-14

### Added

* New settings option for achievement tracking hints.
* Shadowlands: cross-reference for `Maw Assault` threats with the achievement "United Front".
* Battle for Azeroth: cross-reference for `Faction Assaults` with the achievements "Frontline Warrior".
* Legion: cross-reference for `Legion Assaults` with the achievement "Defender of the Broken Isles".

### Changed

* A try-next-day hint message will now be shown when all Bounty Board quest have been completed.
* Updated readme files + homepages and added some badges.
* Split the changelog into 2 files for complete and latest changes.

## [0.14.1+100100] - 2023-06-07

### Fixed

* [Issue #6] An recursion error occurred when retrieving the localized title for the `Researchers Under Fire` event.
* Clicking the entry in the Addon Compartment without having any Expansion Landing Pages unlocked will now be ignored.

## [0.14.0+100100] - 2023-06-05

### Added

* [Issue #3] Automated packaging and releasing to `GitHub`, `CurseForge`, `Wago` and `WoWInterface`.
* World Map Event description texts can now be hidden via settings.
* Dragonflight: added `Researchers Under Fire` details.
* Dragonflight: added `Fyrakk Assaults` details.
* Legion: added `Greater Invasion Point` details as well as an icon hint cross-referencing the achievement "Invasion Obliteration".

### Changed

* Updated project meta files.
* Reworked the World Map Event category name retrieval for better performance and lesser localizing effort.

## [0.13.0+100100] - 2023-05-19

### Added

* Addon Compartment details.
* New addon icon; the Addon List now supports displaying addon icons which can be added to the TOC file.
* Alternative icon for Evoker class in Legion.

### Changed

* Updated dragon glyphs counter for Zaralek Cavern.
* Updated functions which have been renamed or removed in `Deprecated_10_1_0.lua`.
* Updated TOC file version to `WoW 10.1.0`.

### Fixed

* Toggling a garrison type landing page didn't work correctly when the `ExpansionLandingPageMinimapButton` was in garrison mode.
* Dragonflight unlocking requirement hasn't been recognized correctly; using built-in function introduced in Dragonflight now as well.
* [Issue #5] "In retail version 10.1, SetNewTagShown is nil". Blizzard devs moved `SetNewTagShown` from the initializer to the setting mixin class.
* Corrected a misspelled string in the German locale file.

## [0.12.2+100007] - 2023-03-30

### Changed

* Updated dragon glyphs counter for Forbidden Reach.

## [0.12.1+100007] - 2023-03-29

### Changed

* Updated TOC file to `WoW 10.0.7`.

### Fixed

* Garrison types and follower constants have been renamed in `WoW 10.0.7`.

## [0.12.0+100005] - 2023-03-03

### Added

* Battle for Azeroth: Amount of collected Azerite from `Island Expeditions`.

## [0.11.1+100005] - 2023-02-13

### Added

* New slash command `hook`, for manually re-registering the minimap button hooks; just in case that there are other addons interfering.

### Fixed

* [Issue #2] Right-click menu interference by _cfxfox_'s [War Plan](https://beta.curseforge.com/wow/addons/war-plan), by auto-updating the minimap button hooks on player login.

## [0.11.0+100005] - 2023-02-08

### Added

* Shadowlands: Covenant colors.
* Shadowlands: Covenant Renown level details.

### Changed

* Separated threat colors settings for Shadowlands and BfA.

## [0.10.0+100005] - 2023-02-03

### Added

* Added `Timewalking Vendor` availability hint for Draenor and Legion.
* Added faction colors for world map threats and assaults.
* Dragonflight: added `Elemental Storms` details.
* Dragonflight: added `Siege on Dragonbane Keep` details.
* Dragonflight: added `Iskaara Community Feast` details.
* Dragonflight: added `Clan Aylaag` details.
* Dragonflight: added `Dragonriding Race` details.
* Dragonflight: added `Grand Hunts` details.
* Battle for Azeroth: added `Faction Assaults` details.
* Legion: added `Invasion Rifts` details from Argus.
* Legion: added `Demon Invasion` details from Broken Shore.
* Legion: added `Legion Assaults` details to tooltip and settings.
* Warlords of Draenor: added `Garrison Invasion alert` to tooltip and settings.

### Changed

* Updated the README file.
* Updated the TOC file's interface version.
* Unified labels for tooltip and settings category groups.
* Separated and regrouped settings for each expansion.
* The time remaining string in tooltips has been shortened. It shows now a clock icon instead of a preceding text.
* Extended calendar specials, including a cache.

### Removed

* Slash command for `version` info is not needed anymore.

## [0.9.0+100002] - 2022-12-27

### Added

* New settings for timer/colors/glyphs + localization.
* Time remaining info for world map threats.
* Major Factions renown status in entry tooltip.

### Changed

* Updated details display in menu entry tooltips and restructured its code for better readability.

## [0.8.0+100002] - 2022-12-13

### Added

* Details about collected dragon riding glyphs were added to the Dragonflight menu entry tooltip.
* Basic Dragonflight support

### Fixed

* Covenant calling icons have a transparent border which made them look much smaller. They are now properly displayed.

### Changed

* Extended the utility file's content by separating and adding expansion and garrison handler.
* The settings' menu entry selection now shows expansions not owned by the player as disabled with a tooltip hint.
* Removed `.SetCommitFlags` from settings. Usage seems to be reserved for Blizzard only.
* Updated settings and its 'About this Add-on' section.

## [0.7.2+100002] - 2022-11-25

### Added

* Dracthyr Evoker support

### Fixed

* Minimap button appeared for newly created Evoker even though nothing was unlocked yet.
* Minimap button did not appear with the last available expansion while the most current command table hasn't been unlocked.

### Changed

* Updated settings and the about section.
* Reworked the expansion info handler in the utilities file for easier handling of expansion related data and better backwards compatibility.
* Switched to [Semantic Versioning](https://semver.org) based on the format on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

----

## Pre-Semantic Versioning Changes

_(The 🏷️ symbol indicates a tagged release.)_

----

v2022.11.20 (beta) 🏷️
------------------

- **Fixed** banner display in the settings' menu entry selection tooltip.
- **Added** screenshots files.
- **Updated** README file.

v2022.11.18 (beta) 🏷️
------------------

- _Public release of the `beta-2` version._
- **Fixed** interface options in order to work with the new WoW 10.x settings UI.
- **Fixed** right-click menu which did not to appear due to recent WoW 10.x changes, eg. `GarrisonLandingPageMinimapButton` was renamed to `ExpansionLandingPageMinimapButton`.

v2022.08.31 (beta) 🏷️
------------------

- **Updated** TOC file to WoW version `9.2.7`.
- **Fixed** localized quest names for unlocking requirements; only the English fallback title was shown on initial
  log-in with an other locale.

v2022.08.12 (beta) 🏷️
-------------------

- **Added** tooltip strings for frFR, esES, itIT.
- **Updated** locale files with current changes.
- **Fixed** the hint message; it shows now the quest name which is required to unlock the command table.
- **Fixed** the requirements feature; it now recognizes correctly which garrison type has got an unlocked command table. [Issue #1]

v2021.11.22 (beta) 🏷️
-------------------

- _Public release of the `beta-2` version._

v2021.11.19 (beta)
-------------------

- **Updated** locale files.
- **Added** turn-in requirements function + UI options for Emissary Quests (bounties).
- **Updated** the features list in the README file.
- _Rebase of master branch; `squash`ed some commits and corrected some misspelled or vaguely formulated commit messages._

v2021.11.17 (beta)
-------------------

- **Updated** locale files with recent UI option changes.

v2021.11.16 (beta)
-------------------

- _Merged the new features (`v2021.10.22 (beta)`+) into the master branch._

v2021.11.11 (beta)
-------------------

- **Updated** and refined loading procedure for global and individual settings.
- **Updated** UI options for showing requirements for unlocking a command table.
- **Updated** UI options for showing/hiding the minimap button.

v2021.11.08 (beta)
-------------------

- **Updated** functionality to keep the minimap button always shown or always hidden, when entering a new zone.

v2021.11.04 (beta)
-------------------

- **Updated** TOC file to WoW version `9.1.5`.

v2021.11.03 (beta)
-----------------

- **Updated** locale files.

v2021.10.22 (beta)
-------------------

- **Added** main feature to re-show the hidden minimap button on each new expansion.

v2021.10.18 (beta)
-------------------

- **Updated** the header strings for World Map Threats in the details tooltip.

v2021.10.09 (beta)
-------------------

- **Updated** documentation of all LUA files to be more conform with the LUA language specs.

v2021.10.08 (beta)
-------------------

- **Updated** locale files with TOC file notes.

v2021.10.04 (beta)
-------------------

- **Updated** the README and meta files to be more compatible with both code hosting platforms.

v2021.10.02 (beta) 🏷️
-------------------

- _First public release_ of `beta` version with **Git** on [CurseForge.com](https://www.curseforge.com/wow/addons/mission-report-button-plus) and [GitHub.com](https://github.com/erglo/mission-report-button-plus).
- **Updated** locale files with recent UI option strings.

v2021.10.01 (beta)
------------

- **Added** bounties + threats to the UI options.

v2021.09.30 (beta)
-------------------

- **Added** world-map threat infos to menu item's tooltip.
- **Added** bounty board infos to menu item's tooltip.

v2021.09.20 (beta)
-------------------

- **Updated** UI options and added un-check all to the menu entry selection drop-down menu.
- **Updated** slash commands list.
- **Added** a chat notification for the world-quest calendar event.

v2021.09.18 (beta)
-------------------

- **Fixed** an error where the calendar world quest event wasn't recognized correctly.

v2021.09.17 (beta)
-------------------

- **Added** more details to the description file.

v2021.09.15 (beta)
-------------------

- **Updated** project status to `beta`. **Testers welcome!**

v2021.09.14 (beta)
-------------------

- **Added** version control management with **Git**, including meta files.
- **Added** calendar world quest event week watcher.

v2021.09.10 (alpha)
-------------------

- **Added** a new file for utility functions in order to keep the core file clear.
- **Added** slash command `show` to show the minimap button, when not displayed. (experimental)
- **Added** requirement checks for each expansion; instead of player level check (unreliable due to level squish) the quests are used as shown in the mobile app.

v2021.08.21 (alpha)
-------------------

- **Updated** and refined UI options for live change preview.

v2021.07.10 (alpha)
-------------------

- **Added** graphical interface options.
- **Added** locale strings for options.
- **Added** functionality to de-/select menu items.
- **Added** menu item for quickly accessing the settings.

v2021.05.15 (alpha) 🏷️
-------------------

- _Second public release_ of alpha version.
- **Added** locale strings for slash command descriptions and chat messages.

v2021.05.12 (alpha)
-------------------

- **Added** slash commands for all currently available settings.

v2021.05.10 (alpha)
-------------------

- **Added** reversible display order of the drop-down menu entries.

v2021.04.28 (alpha)
-------------------

- **Added** icon hint on menu entries on completed missions.
- **Added** tooltip infos about in-progress missions.
- **Updated** expansion eligibility check; entries for expansions the user doesn't
  (yet) own don't appear in the drop-down menu (optional); if the user decides
  to see them anyway, they appear as disabled entries in order to avoid
  UI errors.
- **Updated** player level check for better filtering; entries of garrison types
  not yet available for the user are now disabled in order to avoid UI errors.
- **Added** tooltip hint over disabled menu entries about activation requirements,
  eg. name of required expansion or required player level (experimental feature).

v2021.04.20 (alpha)
-------------------

- **Updated** and changed post hooks to pre-hooks to catch and redirect mouse clicks more
  efficient; mission reports from different garrison types can now be changed
  while the report frame is open.

v2021.03.31 (alpha)
-------------------

- **Added** expansion eligibility check; unavailable entries will now be hidden.
- **Added** player level check; unavailable entries will now be disabled.
- **Added** expansion names to be shown as entry label in the drop-down menu; the
  garrison landing page name is now in the tooltip of each entry instead.

v2021.03.26 (alpha) 🏷️
-------------------

- _Initial public release_ of `alpha` version.
- **Added** copyright infos and long description.
- **Added** locale files (enUS + deDE).
- **Added** add-on page at
  [CurseForge.com](https://www.curseforge.com/wow/addons/mission-report-button-plus).

v2021.03.19 (alpha)
-------------------

- _Initial tests_
- **Added** right-click behavior and menu to the
  `GarrisonLandingPageMinimapButton`.
- **Added** slash commands for version infos and help.
- **Added** additional tooltip info to the `GarrisonLandingPageMinimapButton`.
- **Added** logging functions to simplify debugging.
