--[[
	Custom modifications Copyright (C) 2018 Ken L., Original Work.	
	Custom modifications Copyright (C) December 2018 onwards Styrmir, code and graphics modified by Styrmir from Original Work and other sources. Changelog available in Features and Changes document.	

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
	Header above the button list that handels the toggling of the effect target,

	for the host it'll show the option to put effects on selected/targeted with the
	lack of a selection simply placing the effect on the token over which the window
	spawned (if applicible and on the CT) 

	for the Player, they have the option to place it on targets of the chosen token, or
	simply the chosen token.

	NOTE: margins are the same as the subwindow
]]--
local FRAME_XMARGIN = 12; 
local FRAME_YMARGIN = 12; 

local sActive = 'context'; 

function onInit()
		-- Targeted button
		btn = createControl("button_toggle_effect","btn_use_target"); 
		btn.setStaticBounds(FRAME_XMARGIN,FRAME_YMARGIN+5,50,16); 
		btn.setText('targeted'); 
		btn.setValue(1); 

		-- Selected button
		btn = createControl("button_toggle_effect","btn_use_select"); 
		btn.setStaticBounds(FRAME_XMARGIN+65,FRAME_YMARGIN+5,50,16); 
		btn.setText('selected'); 
		btn.setValue(2); 

		-- make selection default
		setActive('context'); 
end

--[[
	Look for our two button names and react to them, set our
	mode for others to use in effect application
]]-- 
function setActive(btnValue)
	if btnValue == 'btn_use_target' then
		-- toggle off
		if sActive == 'targeted' then
			btn_use_target.setColor('FFFFFFFF'); 	
			sActive = 'context'; 
			MiniEffect.setMode('context'); 
		else
			btn_use_target.setColor('44FFFFFF'); 	
			btn_use_select.setColor('FFFFFFFF'); 	
			sActive = 'targeted'; 
			MiniEffect.setMode('targeted'); 
		end
	elseif btnValue == 'btn_use_select' then
		-- toggle off
		if sActive == 'selected' then
			btn_use_select.setColor('FFFFFFFF'); 	
			sActive = 'context'; 
			MiniEffect.setMode('context'); 
		else
			btn_use_target.setColor('FFFFFFFF'); 	
			btn_use_select.setColor('44FFFFFF'); 	
			sActive = 'selected'; 
			MiniEffect.setMode('selected'); 
		end
	else
		sActive = 'context'; 
	end
end
