--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.


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

