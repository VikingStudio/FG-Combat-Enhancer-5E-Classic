-- 'Fantasy Grounds' is a trademark of SmiteWorks USA, LLC. 'Fantasy Grounds' is Copyright 2004-2014 SmiteWorks USA LLC.
-- The CoreRPG ruleset and all included files are copyright 2004-2013, Smiteworks USA LLC.

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


-- Does not fuction as intended yet due to permission issues
--[[
function onPlacementChanged()
	local nodeCT = window.getDatabaseNode(); 
	local nOnmap = DB.getValue(nodeCT,'tokenonmap',0); 
	if  nOnmap == 1  then
		--Debug.console(DB.getValue(nodeCT,"name","noname") .. ' is ON on the map'); 
		local nodeImg = DB.findNode(DB.getValue(nodeCT,"tokenrefnode","")); 
		if nodeImg and nodeImg.isPublic() then
			local bID, bOptionID = LibraryData.getIDState("image", nodeImg);
			Debug.console('got img node'); 
			if bID then
				window.map_widget.setTooltipText('Placed on map "' .. 
					DB.getValue(nodeImg,"name",Interface.getString("library_recordtype_empty_image") .. '"')); 
			else
				window.map_widget.setTooltipText('Placed on map ' .. 
					DB.getValue(nodeImg,"nonid_name",Interface.getString("library_recordtype_empty_nonid_image") .. '"')); 
			end
		else
			window.map_widget.setTooltipText('Placed on a map'); 
		end
		window.map_widget.setVisible(true); 
	else
		--Debug.console(DB.getValue(nodeCT,"name","noname") .. ' is OFF the map'); 
		window.map_widget.setVisible(false); 
	end
end
]]--

function onHover(state)
	--[[
	local nodeCT = window.getDatabaseNode(); 
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);

	if state and tokenCT then
		-- snap map to position
		CombatManager.openMap(nodeCT); 
	end
	]]--
end


function onClickDown(target, button, image)
	--Debug.console("Client click down"); 
	return true; 
end

function onClickRelease(target, button, image)
	if button > 0 then
		-- Snap to token on map
		CombatManager.openMap(window.getDatabaseNode());
	end
	return true;
end

