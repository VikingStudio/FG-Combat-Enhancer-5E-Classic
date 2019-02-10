# 5e-Combat-Enhancer
A community extension I'm writing to improve 5e combat in Fantasy Grounds.

Support thread: https://www.fantasygrounds.com/forums/showthread.php?47146-5e-Combat-Enhancer-(built-on-retired-GPL-Advanced-Kombat-extension)

Github: https://github.com/StyrmirThorarins/5e-Combat-Enhancer


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
    - Shift + left click on map, zooms and relocates the players view to that of the DM in their clients if they have that map/image open.
    - Alt + left click on token. Deletes the token image from the map.
    - Alt + ctrl + left click on token. Deletes the token image from the map and entry in CT.

    - Middle mouse button held and mouse dragged on image / map. Drags image around similar to using golden button in lower right corner of image.

    Add on top of that all the additions and changes from the changelog in the next post.


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





   
