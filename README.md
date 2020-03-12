# Combat Enhancer 5E Classic
A community extension I've written to improve 5e combat in Fantasy Grounds for the original Fantasy Grounds.

The FG Unity extension that carries over some of this functionality is found here: https://github.com/StyrmirThorarins/FG-5E-Enhancer

Support thread: https://www.fantasygrounds.com/forums/showthread.php?47146-5e-Combat-Enhancer-(built-on-retired-GPL-Advanced-Kombat-extension)

Dependency: The Core 'RPG Token Helper' extension is required for this extension to fully work. https://github.com/StyrmirThorarins/FG-Core-RPG-Token-Helper

Features Summary

    This is a summary of the main features. I may miss a feature or two here, but it contains the majority of them. See Changelog for detailed updates and features.

    5e Combat Enhancer is mainly a visual and quality of life improvement, for running combat in D&D 5e in FG. It includes things such as, layers to the maps, black mask (instead of pale grey) for default theme, new graphics to signify damage, blood splatter, condition graphics, chat graphics and text formatting etc.

    Things such as being able to easily see what token refers to which entry in the CT (combat tracker), and wise versa due to highlighting.
    Being able to add tokens directly onto the map and from there onto the CT as easily as vice versa, by right clicking the tokens. For the DM, dragging and dropping an NPC from the NPC list will automatically add the token hidden, if available (no need to open up entry and drag token image onto map).

    Large clearly readable, semi-transparent, horizontal health bars and dot health bulbs. Larger than the default and scale automatically with the size of the tokens.

    Semi-transparent easily customizable color and transparency highlight backgrounds.

    The DM and players can both drag and drop conditions onto themselves (token or in CT). If the condition already exists on the target when dropped, it is removed instead.
    Right-clicking tokens linked with the CT gives a new option, Effects. This opens up a custom, compact movable window that contains all the effects. You can drag and drop effects from this onto any CT linked token on the map as normal.

    Check or cross mark graphics on top of tokens after making saving throw attack to graphically show the results. Clear again after save by using one of the new buttons on top of the map.

    Also try interacting with the tokens AND map, while holding down shift, alt, ctrl keys, or a combination of those, while using the left and right mouse buttons and the scroll wheel to discover some special functionality.
    - Shift + scroll while hovering over a token, gives you an altitude counter for example, and the distance to your target is actually calculated with the height in mind.
    - Shift + left click on token. Opens tokens information dialogue window.
    - Ctrl + Shift + left click on map, zooms and relocates the players view to that of the DM in their clients if they have that map/image open.
    - Alt + left click on token. Deletes the token image from the map.
    - Alt + ctrl + left click on token. Deletes the token image from the map and entry in CT.

    - Middle mouse button on player token to commit suggested movement path.

    - Middle mouse button held and mouse dragged on image / map. Drags image around similar to using golden button in lower right corner of image.

    Add on top of that all the additions and changes from the changelog in the next post.

New Menu Options

    Automatic ranged modifiers
        Checks on ranged weapon range, applies disadvantage if not Displays messages with details of ranged attacks.
    Blood splatter scaling
        Scales the size of the bloodsplatter that appears on token death.
    Change NPC background on death in CT
        If on, the background of dead NPCs in the combat tracker changes, otherwise it remains unchanged on death.
    Change NPC token effect icons on death
        If on, the token effect icons on NPCs are greyed on NPC death. If off their remain unchanged on death.
    Draw blood on token
        Draws blood splatters on tokens when they take certain percentile amounts of damage.
    Draw skull on death
        Draw skull on token on death.
    Height font size
        Modifies the size of the height text that appears when middle mouse button is scrolled over token.
    Horizontal health bars
        When health bars are on, it displays them as larger partially opaque health horizontal bars on top of the tokens instead of the default.
    Ranged in melee modifier
        If a ranged attack is made, checks if an enemy is in melee range. If character has the Crossbow Expert feat, they are not effected. Displays a message.
    Render blood splatter on death
    Draw a blodd splatter under the token on token death.
    Skip CT actors that haven't rolled initiative
        Skips actors in the CT that don't have any initatives yet.
    Token effect icon size
        Scales the size of the effect icons.
    Token max effect icon number
        Sets the number of maximum effect icons to display.
    Token underlay opacity (GM only)
        Controls the opacity of the underlay layer graphics that highlights tokens on the combat map for the GM/DM.
    Use flanking rules
        Gives advantage if a flanking attack takes place. Also considers if actor, or ally are to far away from the target on the vertical plane.


IMPORTANT

    If you're trying to interact with a token, pin or image on your map and it doesn't seem to work. Then odds are it's on another layer than the one you currently have selected. Change layers on top of the image panel.
    Only place player character tokens on the top layer. Otherwise they will not be able to interact with them. Same goes for NPC tokens, so the formatting of health bars and other graphics is done correctly.

    When a player is at 0 hp's you have to apply your healing directly to the them on the combat tracker, rather than to their token on the combat map. As soon as they are at 1 hp or above their token is returned to the interactionable top layer again and you can interact with it as normal.

    Make sure you go to your Settings > Combat (GM) > View : Wound Categories, and set them to 'Detailed'. This is so the code can accurately add wound graphics onto the tokens. 



Install
    
    Open the folder "- INSTALL VERSIONS (extension file and needed graphics folder)"
      
      Extension file: "5e-Combat-Enhancer v?_?_?.ext"

      Includes: 
        This is the actual extension, it includes the compressed codebase and a number of graphics.

      Where to place:
        Copy this file to your extension folder (example: Fantasy Grounds\Data\extensions\ [place file here] ).


      =======


      Graphics folder: "5e Combat Enhancer" folder.

      Includes:
        Fog of War graphics.
        Blood splatter graphics on npc/pc death.
        Map focus graphics (when GM shift + left-click's map).


      Where to place:
        Copy and paste this folder '5e Combat Enhancer' into the tokens\host folder. 

        Your path should look something like this if you installed your data folder with the default name:
        [Some drive, C: for example]\[any sub directory path if any]\Fantasy Grounds Data\tokens\host\5e Combat Enhancer

        You can also find this path by opening up your game. Clicking on Tokens -> GM.




Changelog

5e Combat Enhancer Changelog

//////////////////////////////////////////

Changelog / Added / Modified:
Versioning: v(Major.Minor.Patch) https://en.wikipedia.org/wiki/Software_versioning

v1.1.0 (December 26th, 2018) (major features) [80 ish downloads]
- Created new loading icon.
- Version checking. Changed to check for version 3.3.7 as core of module is working for that version. [scripts/manager_versionchk.lua]
    Currently only works with regular image view panel, not the background versions added in 3.3.7, as it relies on layers support by https://www.fantasygrounds.com/forums/showthread.php?20231-Enhanced-Images-(layers)-for-FG-3-0-CoreRPG-(and-rulesets-based-on-CoreRPG).
- Combat tracker. Effects icon change. [graphics/graphics_buttons.xlm]
    Changed icon for effects in combat tracker to be the same as in the CoreRPG set (the little man/woman), and on the actions section of character sheets.
    Edited image to make it fit better with the others in the CT. Removed most of the sheen around the image, enlarged it, added a tint of brown to the image.
- Images in regular view given a black backround/mask color. Graphics based on default theme. [extension.xml]
- Blood Splatter and Pointer Graphics to Copy. Folder added containing blood splatter and pointer graphics. Open the folder for directions where to copy to make it work in-game.
- Fast deletion of Tokens. [scripts/modifications.lua]
    Deletes token from combat map for host, if left-clicked  while Alt key is held down.
    Deletes token from combat map and combat tracker for host, if left-clicked while Alt + Control keys are held down.
    ps. note that dead tokens are on the second layer, and blood splatter is on the third.        

v1.2.0 (December 27th, 2018) (major features) [90ish downloads]
- Horizontal health bars, slightly less than token width when full health, appear above token. Larger and more easily readable. Resize and relocate ratio wise to account for different grid and resolutions sizes. Light transparency added to health bar. [ new horizontal health bar graphics, graphics/graphics_icons.xml, manager_token2.lua : updateHealthBarScale(tokenCT, nodeCT) ; updateHealthHelper(tokenCT, nodeCT) ]
    Health bars dissapear when no health left (incapacitated/dead).            
- Dot health indicators roughly doubled in size for better readability. Resize and relocate ratio wise to account for different grid and resolutions sizes. [ updated graphics for health dot, relocated dot to align due to increased dimensions, manager_token2.lua : updateHealthHelper(tokenCT, nodeCT) ]

v1.2.1 (January 1st, 2019)(patch)  [129 downloads] 
- Blood Splatter and Pointer Graphics to Copy.zip. Fixed directory instructions for "Where to place to work.txt". Set to default of "Fantasy Grounds Data/tokens/".
- Token highlight underlays made more transparent (20%), so the effect is softer and less visually distracting. Thanks to AlphaDecay for the suggestion. [11 instances of token.addUnderlay() in: scripts\modifications.lua, scripts\manager_token.lua (two spots in hilightHover, scripts\manager_maptoken.lua (one in prepMapToken, one in initMapTokens, one in initSingleToken, two in onCTMenuSelection), scripts\snap_token.lua (one in customTurnStart), ct\scripts\ct_token.lua (two in onHover), ct\scripts\ct_entry.lua (one in activeHighlight)]
    Constant colors used are set in scripts/modifications.lua (TOKENUNDERLAYCOLOR_1, TOKENUNDERLAYCOLOR_2, TOKENUNDERLAYCOLOR_3). You can change them there and they will be changed over the whole extension in the appropriate places after save and reload.
    Replaced in files: AA00FF00 with 3300FF00, AAF9FF44 with 33F9FF44, AA0000FF with 330000FF.
    First two numbers/letters refer to the alpha channel or transparency levels. Alpha channel (ranging from 0-255) in hex, opacity at 40% = 66, 30% = 4D , 20% = 33, 10% = 1A    
- Incorrect console message on version checking. Referred to Advanced Kombat, fixed to refer to 5e Combat Enhancer. [manager_versionchk.lua]

v1.3.0 (January 13th, 2019) (major features) [82 downloads]
NOW FULLY COMPATABLE WITH FG 3.3.7.
- Compatability added for FG 3.3.7 background image options. 
- Layers support for background images. Updated project with new code from Enhanced Images extension, https://www.fantasygrounds.com/forums/showthread.php?20231-Enhanced-Images-(layers)-for-FG-3-0-CoreRPG-(and-rulesets-based-on-CoreRPG. [campaign/record_image.xml]
    [campaign/scripts/manager_maptoken.lua] modified code to support background image panels and to work with updated Enhanced Images code
    [campaign/scripts/image.lua] modified code to support background image panels and to work with updated Enhanced Images code
    [campaign/record_image.xml] overwritten with code from Enhanced Images: campaign/updated_record_image.xml
    [campaign/scripts/updated_image.lua] added
    [campaign/scripts/updated_imagewindow.lua] added, replacing older imagewindow.lua, references updated to point to updated_imagewindow.lua
- Added clear saves button to all image panel types (regular/background). [scripts/manager_maptoken.lua] [campaign/record_image.xml]       
- Black mask (fog of war) for all image versions, regular and background. [extension.xml, graphics/frames/imagepanel v2.png]    
- Added check for left-click only activation for alt and alt+ctrl mouse clicks on tokens [modifications.lua, onClickDown]
- Changed background image buttons from Test version to smaller Live version editions by removing prior image refernces in xml, defaulting to default. [graphics/icons.xml]
- Changed image grid menu item buttons to the smaller default graphics. For better readbility and distinction from layers button graphics. [template_toolbar.xml]
- Removed a number of unneeded console outputs that happened during runtime.
- Blood splatter code changed to work with backgound image layers as well. [scripts/manager_token2.lua : function createSplatter(tokenCT,nodeCT,targetLayer), function updateStatusOverlayWidgetHelper(tokenCT,nodeCT,targetLayer)]    
- Shift+left mouse click, ping and move view for players to gm focus now working with backgound images as well. [campaign/record_image.xml] 
- Double-clicking Token on battlemap, now opens up character or NPC dialogue window, similarly to the default behaviour in FG. [scripts/modifications.lua : function onInit(), function onDoubleClick(tokenMap, vImage)]

v1.4.0 (January 21st, 2019) (major features) [- downloads]
- Updates to COPYRIGHT.txt. Copyright text updates across project to point to the COPYRIGHT.txt file for details as applicable.
- Features and patches split into: 'Changelog (versions).txt' and 'TODO, Wishlist.txt'. 
- Refractoring:
    'scripts/modifications.lua' renamed to '5e_combat_enhancer.lua', name changed to 'CombatEnhancer', references in code fixed to point to renamed script and name. 
    'updated_image.lua' from Enhanced layers extension deleted, as all code updates have been updated to image.lua which includes a lot of additional code for this extension. 
    'campaign/scripts/toolbar_draw.lua' deleted as I've written updated code to switch between layers when masking button used in 'campaign/record_image.xml'.
- Menu items added under new menu heading of '5e Combat Enhancer' with various functionality: [extension.xml, script/5e_combat_enhancer : registerMenuItems(), onInit()]
    Change the opacity of GM token underlays colors, ranging from 100%-10%. 20% recommended for best appearance. [scripts/5e_combat_enhancer : updateUnderlayOpacity(), onInit()]            
    Turn on of off drawing blood on tokens as they take damage. [scripts/manager_token2.lua : updateStatusOverlayWidget(tokenCT,nodeCT)]
    Turn on or off drawing of skull on death. [scripts/manager_token2.lua : updateStatusOverlayWidget(tokenCT,nodeCT)]
    Turn on or off blood splatter rendering on death. [scripts/manager_token2.lua : createSplatter(tokenCT,nodeCT,targetLayer)]
    Turn on or off to show NPC death clearly in the CT by fading the entry. [ct/scripts/clientct_entry.lua : updateDisplay(), ct/scripts/ct_entry.lua : updateDisplay()]
    Turn on or off to show NPC death by fading effects icons on top of token. 
    Scaling options for blood splatters on token death, default x1 - x3. [scripts/manager_token2.lua : createSplatter(tokenCT,nodeCT,targetLayer)]        
- Clear saves button only appears if there are tokens on the battle map. [campaign/record_image.xml]   
- Clear saves button was to close to the edge. Fixed. [campaign/record_image.xml]
- Moved double-click to open token information window (PC or NPC) to ctrl + left-click. This was done to enable the window to open up on top of the CT, due to the way the code is layed out. [scripts/5e_combat_enhancer : openTokenInformationWindow(tokenMap, vImage), scripts/snap_token.lua : onClickRelease(target, button, image)]
- Pressing masking button will do the following now: If not on background (image) layer, switch to background (image) layer and enable masking tool. If on background layer, disable masking tool and switch to top (play) layer. [campaign/record_image.xml : toolbar_draw : function onButtonPress(id) ; for both instances of toolbar_draw, one for floating image, one for background image]

v1.4.1 (January 21st, 2019) (patch) [24 downloads]
- Removed 'Chat and modifiers on top (full screen)' menu item, as only part of development testing, not intended for public release. [scripts/5e_combat_enhancer.lua : registerMenuItems()]
- Menu item added: Turn on or off token condition icon color fade on death. [scripts/5e_combat_enhancer.lua : registerMenuItems(), scripts/manager_token2.lua : updateEffectsHelper(tokenCT, nodeCT)]
- Moved ctrl-click to open token information window (PC or NPC) to shift + left-click, due to overlapping functionality for selecting target with ctrl + left-click. [scripts/snap_token.lua : onClickRelease(target, button, image)]

v1.4.2 (January 23rd, 2019) (patch) [288 downloads]
- Menu items: 
    Change token condition icon size (tiny/small/medium). [scripts/5e_combat_enhancer : getTokenEffectWidth(), scripts/manager_token2 : updateEffectsHelper(tokenCT, nodeCT)]
    Change token max condition icon number (1-20). [scripts/5e_combat_enhancer : getMaxTokenEffects(), scripts/manager_token2 : updateEffectsHelper(tokenCT, nodeCT)]

v1.5.0 (March 11, 2019) (major features)    
PROJECT DOWNLOADS AND UPDATES MOVED TO GitHub
- Folder with install versions added to GitHub, including compressed .ext file for extension folder and extra graphics folder needed.
- Added README.md file for GitHub.
- Ping on map moved to ctrl + shift + left-click on map. [scripts/manager_ping.lua : doPing(x,y,imgctl)]
- Restructure: Renamed folder containing blood splatter and other token graphics for the extension from 'items' to 'Combat Enhancer'.
    Changed code references to the new folder name.
- Refractoring, renaming, restructuring and removing of unused and active functions for future transparency in 5e_combat_enhancer.lua.    
- Menu setting to modify the size of the font for showing token height. small/medium/large options. [extension.xml, graphics/graphics_fonts.xml, 5e_combat_enhancer : registerMenuItems(), scripts/manager_height.lua : createHeightWidget]
- Menu setting to skip actors in CT that haven't rolled initiative. [extension.xml, 5e_combat_enhancer : registerMenuItems(), scripts/manager_combat : nextActor ]
- Menu setting to switch between new horizontal health bars and the default vertical ones. [extension.xml, scripts/5e_combat_enhancer : registerMenuItems(); scripts/manager_token2.lua : updateHealthHelper, updateHealthBarScaleHorizontal, updateHealthBarScaleDefault; graphics/graphics_icons.xml ]
- Bloodsplatter size scaling toned down a little. [scripts/manager_token2.lua : createSplatter -> local bloodPrototypesScale]-
- Menu setting to enable using automated flanking rules (advantage on attack if conscious ally opposite of target). Currently only for medium sized actors and targets. 
- Menu setting of automatic disadvantage if within melee range, while attacking with ranged weapon, if actor doesn't have the Crossbow Feat.
- Menu Setting for automatic ranged attack modifiers with ranged weapons, against single a target for current Actor in CT.  
    [scripts/5e_combat_enhancer: ]
    [added scripts/manager_action_attack.lua from 5e Ruleset]
    [scripts/manager_action_attack.lua: modAttack]
    [campaign/scripts/image.lua: onMeasurePointer]   
    - Menu item setting. [extension.xml, 5e_combat_enhancer: registerMenuItems(), scripts/manager_action_attack : getRoll] 
    If attacking with a ranged weapon (for up to 10 weapon items list on Actions tab):
    - If in melee, a disadvantage is automatically added. This checks for any enemies that are within melee reach (this could be 5' or 10' etc, depending the reach of the enemy) of the actor and not uncoscious, a message is displayed in the chat window.
    - If between long and max range, a disadvantage is automatically added, a message is displayed in the chat window.
    - If beyond max range, a message is displayed in the chat window.
    - Exceptions included:
        If target prone, disadvantage added. This is already part of FG core functionality when condition has been applied.
        Feat: Crossbow Expert (for PC): Being within 5 feet of a hostile creature doesn't impose disadvantage on your ranged attack rolls. Logic added.
        Feat: Sharpshooter (for PC): Attacking at long range doesn't impose disadvantage on your ranged weapon attack rolls. Logic added.     
- Shadow tokens added for player tokens while in background (mask) and middle layers for the GM. To make player token movements visible to the GM while on those layers.
    These are updates made by Trenloe to his Enhanced Images Extension that I implemented over. (https://www.fantasygrounds.com/forums/showthread.php?20231-Enhanced-Images-(layers)-for-FG-3-0-CoreRPG-(and-rulesets-based-on-CoreRPG)               
    [campaign/scripts/updated_imagewindow.lua: showlayer, added setTokensPlayerLayerMoveHandler, added playLayerTokenMoved]
- Button added to image menu to toggle between top (play) and bottom (background) layer. (saves going through two-click to see background notes and back)    
    [campaign/record_image.xml, common/template_toolbar.xml, /graphics/toolbar/tool_layers_toggle_play_and_background_30.png]
- Bug fix: Holding down alt while mouse wheel scrolling over token produced error (token resize). Fixed. [scripts/manager_token2.lua : onScaleChanged]
- Bug fix: Height changes didn't update range correctly for actor when target changed altitude. Fixed. [scripts/manager_height.lua]

v1.5.1 (March 15th, 2019) (patch)
- New flanking modifier options for menu. Off/Advantage/+2/+5. [5e_combat_enhancer: registerMenuItems, manager_action_attack: modAttack]
- Bug fix: Pinging map didn't work. Fixed. [manager_ping.lua: doPing (fixed image path)]
- Bug fix: Blood splatter size scaling issues. Fixed. Menu options changed to re-balance to changes. [scripts/manager_token2.lua: createSplatter, 5e_combat_enhancer.lua: registerMenuItems]

v1.5.2 (March 18th, 2019) (patch)
* Added conditions checking function call before running ranged modifier logic. This was done to cover various situations, such as when running theater of the mind combat, entries on CT but missing or no tokens on map, no map open, attacking from CT entry (without token) onto token on map, etc. [scripts/manager_action_attack.lua: modAttack]

v1.5.3 (March 29th, 2019) (patch)
* Added dependency for the Token Helper extension. [extension.xml]
* Fixed scaling issues of blood splatters for certain maps. [scripts/manager_token2.lua: createSplatter]
* Removed some deprecated range code. [scripts/manager_token2.lua: getDistance, getTokenDistance]

v1.5.4 (March 29th, 2019) (patch)
* Dependency changes. [extension.xml]

v1.5.5 (June 1st, 2019) (patch)
* Spell slots missing for NPC entries in CT for spell casters (not innate spellcasters). Added spellslots to CT for casters. [ct/scripts/ct_entry.lua: setActiveVisible]

v1.5.6 (July 6th, 2019) (patch)
* Shift + Left-Mouse Click on image, now adds a ping icon on the map, without moving the players views and zoom level. [scripts/manager_ping.lua: doPing, updatePingDataNode]
* Added option for a +1 modifier for flanking. [scripts/5e_combat_enhancer.lua: registerMenuItems | scripts/manager_action_attack.lua: modAttack]

v1.5.7 (August 7th, 2019) (updated)
* Updated version checking to check for FG v3.3.8 instead of previous v3.3.7. [scripts/manager_versionchk.lua]

v1.5.8 (October 14th, 2019) (updated)
* Disabled FG version checking. [extension.xml: <script name="VersionCheck" file="scripts/manager_versionchk.lua" />]

v1.5.9 (December 4th, 2019) (patch)
* Removing a target of an actor in a CT, by left-clicking the icon of the target, would cause an error. Fixed. [scripts/manager_targeting.lua: removeCTTargetEntry]

v1.6.0 (March 12th, 2020) 
* Extension made compatible with FGC v3.3.10.
* Added load order.