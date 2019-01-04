--[[
	Copyright (C) 2018 December, Styrmir
	Licensed under the GPL Version 3 license.
	http://www.gnu.org/licenses/gpl.html
	This script is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This script is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
]]--

--[[
	on Init
]]--

-- Global Constants --

-- Underlay colors for tokens on the map. First two numbers/letters refer to the alpha channel or transparency levels.
-- Alpha channel (ranging from 0-255) in hex, opacity at 40% = 66, 30% = 4D , 20% = 33, 10% = 1A.
TOKENUNDERLAYCOLOR_1 = "3300FF00"; -- Tokens active turn. 
TOKENUNDERLAYCOLOR_2 = "33F9FF44"; -- Token added to battlemap, but not on combat tracker.
TOKENUNDERLAYCOLOR_3 = "330000FF"; -- Token mouse over hover.




function onInit()	
	Token.onClickDown = onClickDown; 		
end


-- Delete token / and CT entry on mouse click.
-- Use: Mouse Left-click Token on combat map while holding down either 'Alt' or 'Alt+Ctrl'
-- Pre: Token on combat map
-- Post: Token removed from combat map (Alt) or combat map and combat tracker (Atl+Ctrl)
function onClickDown( token, button, image ) 	
	-- Deletes token from combat map, if Alt held on click.
	if (Input.isAltPressed() == true) and (User.isHost() == true) then
		local nodeCT = CombatManager.getCTFromToken(token);
		token.delete();		

		-- Deletes token from combat tracker if Ctrl was also held on click.
		if (Input.isControlPressed() == true) then
			if nodeCT then -- only attempt delete if there is a CT entry
				nodeCT.delete();					
			end				
		end
	end		
end