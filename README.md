# Mission Report Button Plus

Adds a right-click menu to the mission report button on the minimap (aka. the `Garrison-\ExpansionLandingPageMinimapButton`) for selecting mission reports of previous expansions.  
*(See full feature list [below](#features))*  

**Note:  
If you're using an add-on manager, like eg. the CurseForge App, you need to change the "Release Type" to `Beta` in order to find this add-on.**  

![Button tooltip and right-click menu with expansion names](.screenshots/mbrp_tooltip-dropdown.jpg "Right-click on the Kyrian mission report button on the minimap opens the menu.")
![The right-click menu with in-progress mission infos](.screenshots/mbrp_dropdown_bfa-missioncount.jpg "Mouse-over a menu entry shows details about running missions.")  
(More images on this [project's screenshots page](https://www.curseforge.com/wow/addons/mission-report-button-plus/screenshots))

## About this add-on

### Problem

As soon as a new WoW expansion has been released the button on the minimap which opens the mission report frame is disabled until you meet certain criteria in order to send your little helpers on missions. But only the reports from the current expansion can be viewed by the now *replaced* minimap button with *no other options* to view reports of previous expansions any more unless you visit your old mission tables, and often only to find out that your too early and your missions are still *not completed*.  
I was very pleased to see that the WoW Companion app for mobile phones addressed this problem, but the main game still doesn't.

### Solution

It is still possible to access mission reports from previous expansions but the Blizzard devs still haven't implemented a possibility for users to access them via the graphical interface. So here comes this add-on to work:

+ it adds a right-click menu to the already available minimap button for mission reports,
+ with a selection of mission reports of previous expansions, which are...
+ **anytime and anywhere accessible.**  
*(See full feature list below.)*

----

## Features

+ [x] adds a right-click menu to the minimap button
+ [x] a click on an menu entry opens the (read-only) Mission Report Frame of the corresponding expansion
+ [x] show or hide the minimap button itself
+ [x] get informed in chat on finished missions, talents, buildings (WoD garrison only) or WoD garrison invasions
+ [x] choose from a variety of settings and adjust the addon to your liking
  + [x] or de-/select the menu entries with the expansions that are no longer of interest to you
+ [x] expansions you (yet) don't own will be hidden in the menu
+ [x] expansions without an unlocked command table will be displayed, but disabled
  + [x] now showing a hint on which quest unlocks it
+ [x] display the minimap button of the previous expansion as long as the current command table hasn't been unlocked
+ [x] see details about in-progress mission of each command table
+ [x] see which bounties and threats of each expansion are currently active (WIP)
+ [x] more to come...  
  *(Want to see some examples? Go visit this project's [screenshots page](https://www.curseforge.com/wow/addons/mission-report-button-plus/screenshots) )*  

----

### Known Issues

+ As soon as you unlock a command table the minimap button doesn't update automatically. The add-on gathers this information only once at startup in order to save memory. You need to reload the UI manually, eg. by typing `/reload` in the chat frame. Logging-out and -in again also works.  
  I will tend to this as soon as possible.

----

### Interested in helping?

*Contributors are most welcome!*  
[Report a problem](https://github.com/erglo/mission-report-button-plus/issues) on this project's issues page as soon as you find any errors.  
[Start translating](https://www.curseforge.com/wow/addons/mission-report-button-plus/localization) when you're missing your language or simply want to help with localization.  
[Leave a comment](https://www.curseforge.com/wow/addons/mission-report-button-plus#comments) if you have a *feature request* or *tell me what you think* about this add-on.

----

### Tools used

+ Microsoft's [Visual Studio Code](https://code.visualstudio.com) with ...  
  + Ketho's [World of Warcraft API](https://github.com/Ketho/vscode-wow-api) extension  
  + Stanzilla's [World of Warcraft TOC Language Support](https://github.com/Stanzilla/vscode-wow-toc) extension  
+ Version control management with [Git](https://git-scm.com)

### References

+ Townlong Yak's FrameXML archive (<https://www.townlong-yak.com/framexml/live>)
+ WoWpedia's World of Warcraft API (<https://wowpedia.fandom.com/wiki/World_of_Warcraft_API>)
+ Wowhead.com (<https://www.wowhead.com>)
+ Matt Cone's "The Markdown Guide" (<https://www.markdownguide.org>)
  *(Buy his [book](https://www.markdownguide.org/book)!)*
+ The Git Book (<https://git-scm.com/book>)
+ Documentation for Visual Studio Code (<https://code.visualstudio.com/docs>)
