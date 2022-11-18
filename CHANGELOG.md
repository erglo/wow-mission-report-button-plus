Changelog
=========

v2022.11.18 (beta)
------------------

- **Fixed** interface options in order to work with the new WoW 10.x settings UI.
- **Fixed** right-click menu which did not to appear due to recent WoW 10.x changes, eg. `GarrisonLandingPageMinimapButton` was renamed to `ExpansionLandingPageMinimapButton`.

v2022.08.31 (beta)
------------------

- **Updated** TOC file to WoW version `9.2.7`.
- **Fixed** localized quest names for unlocking requirements; only the English fallback title was shown on initial
  log-in with an other locale.

v2022.08.12 (beta)
-------------------

- **Added** tooltip strings for frFR, esES, itIT.
- **Updated** locale files with current changes.
- **Fixed** the hint message; it shows now the quest name which is required to unlock the command table.
- **Fixed** the requirements feature; it now recognizes correctly which garrison type has got an unlocked command table.

v2021.11.22 (beta)
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

v2021.10.02 (beta)
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

v2021.05.15 (alpha)
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

v2021.03.26 (alpha)
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
