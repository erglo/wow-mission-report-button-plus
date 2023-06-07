# Changelog

All notable changes to this project will be documented in this file (or linked to this file).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

----

## [0.14.1+100100] - 2023-06-07

### Fixed

- [Issue #6] An recursion error occurred when retrieving the localized title for the `Researchers Under Fire` event.
- Clicking the entry in the Addon Compartment without having any Expansion Landing Pages unlocked will now be ignored.

## [0.14.0+100100] - 2023-06-05

### Added

- [Issue #3] Automated packaging and releasing to `GitHub`, `CurseForge`, `Wago` and `WoWInterface`.
- World Map Event description texts can now be hidden via settings.
- Dragonflight: added `Researchers Under Fire` details.
- Dragonflight: added `Fyrakk Assaults` details.
- Legion: added `Greater Invasion Point` details as well as an icon hint cross-referencing the achievement "Invasion Obliteration".

### Changed

- Updated project meta files.
- Reworked the World Map Event category name retrieval for better performance and lesser localizing effort.
  
## [0.13.0+100100] - 2023-05-19  
  
### Added  
  
- Addon Compartment details.
- New addon icon; the Addon List now supports displaying addon icons which can be added to the TOC file.  
- Alternative icon for Evoker class in Legion.
  
### Changed  
  
- Updated dragon glyphs counter for Zaralek Cavern.  
- Updated functions which have been renamed or removed in `Deprecated_10_1_0.lua`.  
- Updated TOC file version to `WoW 10.1.0`.  
  
### Fixed  
  
- Toggling a garrison type landing page didn't work correctly when the `ExpansionLandingPageMinimapButton` was in garrison mode.
- Dragonflight unlocking requirement hasn't been recognized correctly; using built-in function introduced in Dragonflight now as well.
- [Issue #5] "In retail version 10.1, SetNewTagShown is nil". Blizzard devs moved `SetNewTagShown` from the initializer to the setting mixin class.  
- Corrected a misspelled string in the German locale file.  
  
----  
  
## Previous Versions (CurseForge)  
  
🏷️ [v0.12.2](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/4465019) - WoW 10.0.7 (retail)  
🏷️ [v0.12.1](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/4464214) - WoW 10.0.7 (retail)  
🏷️ [v0.12.0](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/4419495) - WoW 10.0.5 (retail)  
🏷️ [v0.11.1](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/4394724) - WoW 10.0.5 (retail)  
🏷️ [v0.11.0](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/4388074) - WoW 10.0.5 (retail)  
🏷️ [v0.10.0](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/4378645) - WoW 10.0.5 (retail)  
🏷️ [v0.9.0](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/4274082) - WoW 10.0.2 (retail)  
🏷️ [v0.8.0](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/4173683) - WoW 10.0.2 (retail)  
🏷️ [v0.7.2](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/4110896) - WoW 10.0.2 (retail)  
🏷️ [v2022.11.20 (beta)](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/4099565) - WoW 10.0.2 (retail)  
🏷️ [v2022.11.18 (beta)](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/4095108) - WoW 10.0.2 (retail)  
🏷️ [v2022.08.31 (beta)](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/3960563) - WoW 9.2.7 (retail)  
🏷️ [v2022.08.12 (beta)](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/3931064) - WoW 9.2.5 (retail)  
🏷️ [v2021.11.22 (beta)](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/3534034) - WoW 9.1.5 (retail)  
🏷️ [v2021.10.02 (beta)](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/3479455) - WoW 9.1.0 (retail)  
🏷️ [v2021.05.15 (alpha)](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/3310841) - WoW 9.0.5 (retail)  
🏷️ [v2021.03.26 (alpha)](https://www.curseforge.com/wow/addons/mission-report-button-plus/files/3251909) - WoW 9.0.5 (retail)  
  