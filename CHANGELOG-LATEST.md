## Latest changes

[//]: <> (Rendered badges - Unfortunately most addon hosting websites do not support badges directly, but)
[//]: <> (fortunately GitHub renders them as images)

!["Latest"](https://camo.githubusercontent.com/ca14bf29cae000a0fd25bafe7c9ac56767e537cd30e6bfcc02c661fef144829c/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f7461672d76302e31372e312d696e666f726d6174696f6e616c3f6c6f676f3d476974487562266c6f676f436f6c6f723d6c6967687467726179 "Latest release") !["WoW-retail"](https://camo.githubusercontent.com/077f6a676e53c872c2aff71cd9d838971d0df35ae13a416ec0af7a5098d4a890/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f576f572d2d72657461696c2d31302e312e352d6f72616e6765 "Supported game version")

### Fixed

- English default strings haven't been merged with the global localization table correctly.
- [Issue #13] An error occurred in `labels.lua` in the clean-up function. Said function was called as soon as the player leaves the world but the event fired presumably before the global variable was initialized. Now it is only called once when the player quits the game.
&nbsp;  

## Previous changes

- For a complete history of changes see the [changelog file on GitHub](https://github.com/erglo/mission-report-button-plus/blob/main/CHANGELOG.md "CHANGELOG.md").

&nbsp;  
**Note:** _This is an unreleased version and still in development._  
[![WoW](https://img.shields.io/badge/WoW--retail-10.1.5-orange)](https://addons.wago.io/addons/mission-report-button-plus "Supported game version")
!["tag-latest"](https://img.shields.io/badge/tag-v0.17.2-informational?logo=GitHub&logoColor=lightgray "Test version")
