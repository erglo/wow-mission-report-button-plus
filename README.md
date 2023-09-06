# Mission Report Button Plus

Adds a right-click menu to the mission report button on the minimap (aka. `Garrison-/ExpansionLandingPageMinimapButton`) for selecting mission reports and summaries of current and previous expansions.  
*(See full feature list [below](#features))*

![Button tooltip and right-click menu with expansion names](https://raw.githubusercontent.com/erglo/wow-mission-report-button-plus/main/.screenshots/mbrp_tooltip-dropdown_df-winter.jpg "Button tooltip and right-click menu with expansion names")
![Button tooltip and right-click menu with expansion names](https://raw.githubusercontent.com/erglo/wow-mission-report-button-plus/main/.screenshots/mrbp_menu-tooltip_df-summary.jpg "The MRBP Dragon Isles Summary tooltip")  
(More images can be found on this addon's [screenshots page](https://www.curseforge.com/wow/addons/mission-report-button-plus/screenshots) on CurseForge.)

## Status

![GitHub release (with filter)](https://img.shields.io/github/v/release/erglo/wow-mission-report-button-plus?logo=github&label=latest "GitHub Version")
![GitHub (Pre-)Release Date](https://img.shields.io/github/release-date-pre/erglo/wow-mission-report-button-plus?logo=github "GitHub Release Date")
![GitHub all releases](https://img.shields.io/github/downloads/erglo/wow-mission-report-button-plus/total?logo=github "GitHub Downloads")
![GitHub last commit (branch)](https://img.shields.io/github/last-commit/erglo/wow-mission-report-button-plus/main?logo=github "GitHub Last Commit (main)")

![CurseForge Version](https://img.shields.io/curseforge/v/461804?logo=curseforge&label=latest "CurseForge Version")
![CurseForge Game Versions](https://img.shields.io/curseforge/game-versions/461804?logo=curseforge&label=WoW-retail&color=%23F16436 "Game Versions")
![CurseForge Downloads](https://img.shields.io/curseforge/dt/461804?logo=curseforge&color=%23F16436 "CurseForge Downloads")

----

## Features

### Minimap Landing Page Button

* [x] adds a right-click menu to the minimap's expansion landing page button
* [x] displays the minimap button of the *previous* expansion as long as the current command table or expansion requirements haven't been unlocked
* [x] optionally shows or hides the minimap button itself permanently
* [x] clicking a menu entry opens the (read-only) Mission Report Frame of the corresponding expansion

### Dropdown Menu

* [x] see details about in-progress missions of each command table
* [x] see which bounties, threats and world map events of each expansion are currently active
* [x] expansions you (yet) don't own will be hidden in the menu
* [x] expansions without unlocked requirements (eg. a command table) will be displayed, but disabled
  + [x] now optionally showing a hint on how to unlock it
* [x] WoD: get notified about Garrison Invasions
* [x] Legion: see details about Demon Invasions and Invasion Points
* [x] BfA: see details about Faction and N'Zoth Assaults as well as you Isle Expedition Azerite progress
* [x] Shadowlands: see details about Covenant Assaults in The Maw as well as your Covenant Renown status
* [x] Dragonflight: see a summary of your Major Factions Renown status, collected Dragon Glyphs and many Dragon Isles events

### Chat

* [x] get informed in-chat about finished missions, talents, WoD garrison invasions and buildings, etc.
* [x] chat messages are optionally and can be disabled in the settings

### Addon Compartment

* [x] get an overview of all expansions with a landing page
* [x] see a summary of all expansions at once
* [x] in case you're hiding your minimap (button) you won't lose track of your mission progress and other expansion details
* [x] it is completely optional and can be de-/activated in the settings

### Common

* [x] choose from a variety of settings and adjust the addon to your liking
  + [x] or de-/select the menu entries with the expansions that are no longer of interest to you
* [x] some events are linked to an achievement; see whether you achieved it or not by an icon hint
* [x] **many more things to come**...

*If you want to see some examples of these features, go visit this addon's [screenshots page](https://www.curseforge.com/wow/addons/mission-report-button-plus/screenshots) on CurseForge.*

----

## About this addon

### Problem

As soon as a new WoW expansion has been released the button on the minimap which opens the mission report frame (aka. `Garrison-/ExpansionLandingPageMinimapButton`) is disabled until our character meets certain criteria in order to send our little helper companions on missions or until we see any expansion summary. But only the reports from the current expansion can be viewed by the newly *replaced* minimap button with *no other options* on how to view reports of any previous expansions anymore unless we visit the old mission tables, and in many cases we do so only to find out that we're too early and our missions are still on-going.  
I was very pleased to see that the WoW Companion app for mobile phones addressed this problem, but unfortunately the main game still doesn't.

### Solution

It is still possible to access mission reports from previous expansions but the Blizzard Devs still haven't implemented a possibility for users to access those via the graphical interface. **This is where this addon comes into play:**

* it makes the minimap button for mission reports available in case it has been hidden,
* it adds a right-click menu to the minimap button,
* with a selection of unlocked expansions and access to eg. mission reports, bounty quests, summaries, etc. which are...
* **anytime and anywhere accessible.**  
*(See full feature list above.)*

----

## How to install

### Download sources

[![CurseForge](https://img.shields.io/badge/%F0%9F%94%97-CurseForge-f16436)](https://www.curseforge.com/wow/addons/mission-report-button-plus) [![Wago.io](https://img.shields.io/badge/%F0%9F%94%97-Wago.io-c1272d)](https://addons.wago.io/addons/mission-report-button-plus) [![WoWInterface](https://img.shields.io/badge/%F0%9F%94%97-WoWInterface-da8a00)](https://www.wowinterface.com/downloads/info26583-MissionReportButtonPlus.html) [![GitHub](https://img.shields.io/badge/%F0%9F%94%97-GitHub-6e7681)](https://github.com/erglo/wow-mission-report-button-plus)

### Install manually

* Download the latest addon package from one of the above sources.
* Unpack the ZIP file into your `World of Warcraft/_retail_/Interface/AddOns` folder.
* Done. Start or reload your game.

### Install using an app

* There are many Addon Managers apps out there. Download your favorite one or get one from one of the above sources (eg. CurseForge or Wago).
* Install the manager application and run it.
* Search for `Mission Report Button Plus` inside the app and click on "Install".
* Done. Start or reload your game.

#### ℹ Further help

* [WoWInterface - FAQ: Installing AddOns](https://www.wowinterface.com/forums/faq.php?faq=install)
* [Wowhead - AddOns: How to Install and Maintain](https://www.wowhead.com/guide/addons-how-to-install-and-maintain-1998)
* [Wowpedia - Installing an addon](https://wowpedia.fandom.com/wiki/AddOn#Installing_an_addon)

----

## Contributing

*Interested in helping? Contributors are most welcome!*  
[Report a problem](https://github.com/erglo/wow-mission-report-button-plus/issues) or send a feature request on the repository's issues page on GitHub.  
[Help translating](https://www.curseforge.com/wow/addons/mission-report-button-plus/localization) on CurseForge if you're missing your language or simply want to help with localization.

### Thank you! 🎉

* Thanks go to [SpareSimian](https://github.com/SpareSimian) and [others](https://github.com/erglo/wow-mission-report-button-plus/issues?q=is%3Aissue+is%3Aclosed) for their awesome bug reports.
* Thanks go to [EK (EKE00372)](https://github.com/EKE00372) for the `zhTW` and the `zhCN` localization.
* Thanks go to [justinkb](https://github.com/justinkb) for the very [quick fix PR](https://github.com/erglo/wow-mission-report-button-plus/pull/16) for [issue #17](https://github.com/erglo/wow-mission-report-button-plus/issues/17).

### Known Issues

* When opening the garrison landing page of Draenor with an *upgraded* character an recursion error occurs. The game expects a list with mission details but receives empty values instead. I will tend to this as soon as possible, but it seems to be a sever-side problem at first glance.
* [FIXED] When using MRBP together with *cfxfox*'s addon [War Plan](https://beta.curseforge.com/wow/addons/war-plan) the minimap button's right-click handler was overridden showing only War Plan's dropdown menu. This has been fixed.
*In case of other addons doing something similar I added the slash command `hook`, which simply re-registers the MRBP's button hooks (tooltip + right-click menu).*
* As soon as you unlock a command table the minimap button doesn't update automatically. The addon gathers this information only once at startup in order to save memory. You need to reload the UI manually, eg. by typing `/reload` in the chat frame. Logging-out and -in again also works. I will tend to this as soon as possible.

----

### Tools Used

* Microsoft's [Visual Studio Code](https://code.visualstudio.com) with ...
  + Sumneko's [Lua Language Server](https://github.com/LuaLS/lua-language-server) extension
  + Ketho's [World of Warcraft API](https://github.com/Ketho/vscode-wow-api) extension
  + Stanzilla's [World of Warcraft TOC Language Support](https://github.com/Stanzilla/vscode-wow-toc) extension
  + David Anson's [Markdown linting and style checking](https://github.com/DavidAnson/vscode-markdownlint) extension
* Version control management with [Git](https://git-scm.com) + [GitHub](https://github.com/)
  + GitHub workflow via [BigWigsMods/packager](https://github.com/BigWigsMods/packager)
* In-game development tools (addons):
  + [Ace3](https://www.curseforge.com/wow/addons/ace3),
    [BugGrabber](https://www.curseforge.com/wow/addons/bug-grabber),
    [BugSack](https://www.curseforge.com/wow/addons/bugsack),
    [idTip](https://www.curseforge.com/wow/addons/idtip),
    [TextureViewer](https://www.curseforge.com/wow/addons/textureviewer),
    [WoWLua](https://www.curseforge.com/wow/addons/wowlua).

### References

* Townlong Yak's [FrameXML archive](https://www.townlong-yak.com/framexml/live)
* WoWpedia's [World of Warcraft API](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API)
* [Wowhead.com](https://www.wowhead.com)
* Matt Cone's ["The Markdown Guide"](https://www.markdownguide.org)
  *(Buy his [book](https://www.markdownguide.org/book)!)*
* [The Git Book](https://git-scm.com/book)
* [Documentation](https://code.visualstudio.com/docs) for Visual Studio Code
