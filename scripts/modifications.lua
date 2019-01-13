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
	Token.onClickDown = onClickDown	
	-- Token.onDrag = dynamicShadows	
	Token.onDoubleClick = onDoubleClick;	
end


-- Delete token / and CT entry on mouse click.
-- Use: Mouse Left-click Token on combat map while holding down either 'Alt' or 'Alt+Ctrl'
-- Pre: Token on combat map
-- Post: Token removed from combat map (Alt) or combat map and combat tracker (Atl+Ctrl)
-- NOTE: button (number), Returns a numerical value indicating the button pressed (1 = left, 2 = middle, 4 = button 4, 5 = button 5). Right button is used for radial menus.
function onClickDown( token, button, image ) 	
	-- Deletes token from combat map, if Alt held on left mouse click.
	if (Input.isAltPressed() == true) and (User.isHost() == true) and (button==1) then
		local nodeCT = CombatManager.getCTFromToken(token);
		token.delete();		

		-- Deletes token from combat tracker if Ctrl was also held on click.
		if (Input.isControlPressed() == true) then
			if nodeCT then -- only attempt delete if there is a CT entry
				nodeCT.delete();					
			end				
		end
	end		

	-- Code below works, but for now leaving it as double-click on token, as this is the default behaviour of FG.
	-- Opens up NPC dialogue sheet if ctrl + left mouse click on token
	--[[
	if (Input.isControlPressed() == true) and (User.isHost() == true) and (button==1) then		
		--Debug.chat('open NPC sheet');
		onDoubleClick(token, image);		
	end	
	]]--	

	-- Allow players to move their own tokens with middle mouse button press when tokens are locked.
	-- Possibly add this as a menu option to allow or disallow.
	--if button == 2 then
		-- token move on path defined during locked stage
	--	owner = getTokenPlayer( token );
	--end

end

-- a modified Token.onDrag event, for handling dynamic shadows
function dynamicShadows( token, mouseButton, x, y, dragdata )
	Debug.chat('token ', token)	
	--local image = UpdatedImageWindow.image
	Debug.chat('controls ', image)	
	local gridType = image.getGridType() -- only work with square hexes for simplicy to begin with
	local gridSize = image.getGridSize()
	local gridOffset = image.getGridOffset()
	local maskTool = image.getMaskTool()
	local maskLayer = image.hasMask()

	image.setMaskEnabled(true)
	image.setDrawingSize(500,500, 50, 50)
	-- make selection
	-- mask or unmask
	image.setMaskTool(unmaskelection) --Valid values are "maskselection" and "unmaskelection

	--Debug.chat('image ', image, ' gridType ', gridType)		
end

-- Open record when token is double clicked (direct copy from CoreRPG.pak FG v3.3.7)
function onDoubleClick(tokenMap, vImage)
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if nodeCT then
		if User.isHost() then
			local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
			if sRecord ~= "" then
				Interface.openWindow(sClass, sRecord);				
			else
				Interface.openWindow(sClass, nodeCT);				
			end
		else
			if (DB.getValue(nodeCT, "friendfoe", "") == "friend") then
				local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
				if sClass == "charsheet" then
					if sRecord ~= "" and DB.isOwner(sRecord) then
						Interface.openWindow(sClass, sRecord);						
					else
						ChatManager.SystemMessage(Interface.getString("ct_error_openpclinkedtokenwithoutaccess"));
					end
				else
					local nodeActor;
					if sRecord ~= "" then
						nodeActor = DB.findNode(sRecord);
					else
						nodeActor = nodeCT;
					end
					if nodeActor then
						Interface.openWindow(sClass, nodeActor);						
					else
						ChatManager.SystemMessage(Interface.getString("ct_error_openotherlinkedtokenwithoutaccess"));
					end
				end
				vImage.clearSelectedTokens();
			end
		end
	end
end

-- Ctrl click on map, timed function that draws circles ever larger (up to a set point), while deleting previous, to indicate a pinged location. 
-- Giving the impression of a timed expanding circle.
function pingExpandingCircle()
	-- PointerToolkit  using scripts/pointer_toolkit.lua
end

-- Return owner for character sheet connected to Token
function getTokenPlayer(token)	
	local nodeCT = CombatManager.getCTFromToken(token);
	if nodeCT then
		local owner = nodeCT.getOwner();
		Debug.console('modifications>getTokenPlayer, nodeCt owner:', owner);
		--- DB.isOwner( nodeid )
		
		if User.isHost() then
		end	
		if not User.isHost() then
		end
	end				
end