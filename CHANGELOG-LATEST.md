## Latest changes

[//]: <> (Rendered badges - Unfortunately most addon hosting websites do not support badges directly, but)
[//]: <> (fortunately GitHub renders them as images)

!["Latest"](https://camo.githubusercontent.com/4a784c58fcf6f2922fdb34073776606075ce563ac5b28dff56d8c5b881948599/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f7461672d76302e31372e322d696e666f726d6174696f6e616c3f6c6f676f3d476974487562266c6f676f436f6c6f723d6c6967687467726179 "Latest release") !["WoW-retail"](https://camo.githubusercontent.com/077f6a676e53c872c2aff71cd9d838971d0df35ae13a416ec0af7a5098d4a890/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f576f572d2d72657461696c2d31302e312e352d6f72616e6765 "Supported game version")

### Fixed

- [Issue #13] An error occurred in `labels.lua` in the clean-up function. Said function was called as soon as the player leaves the world but the event fired presumably before the global variable was initialized. Now it is only called once when the player quits the game.
- English default strings haven't been merged with the global localization table correctly.
- Corrected a translated string in `deDE` locale.
&nbsp;  

## Previous changes

- For a complete history of changes see the [changelog file on GitHub](https://github.com/erglo/mission-report-button-plus/blob/main/CHANGELOG.md "CHANGELOG.md").
