--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.

local scaleWidget = nil;

function onPlacementChanged()
	local nodeCT = window.getDatabaseNode(); 
	local nOnmap = DB.getValue(nodeCT,'tokenonmap',0); 
	if  nOnmap == 1  then
		local nodeImg = DB.findNode(DB.getValue(nodeCT,"tokenrefnode","")); 
		nodeImg = nodeImg.getParent(); 
		if nodeImg then
			--Debug.console('got img node ' .. nodeImg.getPath()); 
			window.map_widget.setTooltipText('Placed on map "' .. 
				DB.getValue(nodeImg,"name",Interface.getString("library_recordtype_empty_image")) .. '"'); 
		end

		--Debug.console(DB.getValue(nodeCT,"name","noname") .. ' is ON on the map'); 
		window.map_widget.setVisible(true); 
	else
		--Debug.console(DB.getValue(nodeCT,"name","noname") .. ' is OFF the map'); 
		window.map_widget.setVisible(false); 
	end
end

function onDrop(x, y, draginfo)
	if draginfo.isType("token") then
		if not draginfo.getCustomData() then
			local prototype, dropref = draginfo.getTokenData();
			setPrototype(prototype);
			CombatManager.replaceCombatantToken(window.getDatabaseNode(), dropref);
			TokenManager.updateAttributes(window.getDatabaseNode().getChild('tokenrefid')); 
		else
			-- if we have custom data, let the window onDrop handle it
			window.onDrop(x, y, draginfo); 
		end
		return true;
	end
end

--[[
	Make this multi-purpose, add the dbnode to our window
]]--
function onDragStart(button,x,y,draginfo)
	local nSpace = DB.getValue(window.getDatabaseNode(), "space");

	--Diagnostics.dumpDragData(draginfo); 
	
	draginfo.setType('token');
	draginfo.setTokenData(self.getPrototype()); 
	draginfo.setCustomData(window.getDatabaseNode()); 

	--CTDragManager.setData(window.getDatabaseNode()); 

	TokenManager.setDragTokenUnits(nSpace);
	return true; 
end

function onDragEnd(draginfo)
	TokenManager.endDragTokenWithUnits();

	local prototype, dropref = draginfo.getTokenData();
	if dropref then
		CombatManager.replaceCombatantToken(window.getDatabaseNode(), dropref);
		TokenManager.updateAttributes(window.getDatabaseNode().getChild('tokenrefid')); 
		-- MIGRATED to updateAttributesHelper
		--[[
		if MapTokenManager then
			MapTokenManager.setupCombatTokenMenu(dropref); 
		end
		]]--
	end
	return true;
end

function onHover(state)
	local nodeActiveCT = CombatManager.getActiveCT();
	local nodeCT = window.getDatabaseNode(); 
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);

	if state and tokenCT then
		-- add blue underlay
		tokenCT.removeAllUnderlays(); 
		local space = nodeCT.getChild('space');  
		if space == nil then 
			space = 1;
		else
			space = space.getValue()/5/2+0.5; 
		end
		tokenCT.addUnderlay(space, CombatEnhancer.TOKENUNDERLAYCOLOR_3); 

	elseif tokenCT then
		-- remove all underlays, if active then put back active underlay
		tokenCT.removeAllUnderlays(); 
		if nodeActiveCT and nodeActiveCT.getNodeName() == nodeCT.getNodeName() then
			local tokenActiveCT = CombatManager.getTokenFromCT(nodeActiveCT);
			if tokenActiveCT then
				local space = nodeActiveCT.getChild('space');  
				if space == nil then 
					space = 1;
				else
					space = space.getValue()/5/2+0.5; 
				end
				tokenCT.addUnderlay(space, CombatEnhancer.TOKENUNDERLAYCOLOR_1); 
			end
		end
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if button == 1 then
		-- Snap to token on map
		CombatManager.openMap(window.getDatabaseNode());
		-- CTRL + left click to target CT entry with active CT entry
		if Input.isControlPressed() then
			local nodeActive = CombatManager.getActiveCT();
			if nodeActive then
				local nodeTarget = window.getDatabaseNode();
				if nodeTarget then
					TargetingManager.toggleCTTarget(nodeActive, nodeTarget);
				end
			end
		-- All other left clicks will toggle activation outline for linked token (if any)
		-- DISABLED HIGHLIGHT EFFECT
		--[[
		else
			local tokeninstance = CombatManager.getTokenFromCT(window.getDatabaseNode());
			if tokeninstance and tokeninstance.isActivable() then
				tokeninstance.setActive(not tokeninstance.isActive());
			end
		--]]
		end
	
	-- Middle click to reset linked token scale
	else
		local tokeninstance = CombatManager.getTokenFromCT(window.getDatabaseNode());
		if tokeninstance then
			tokeninstance.setScale(1.0);
		end
	end

	return true;
end

function onDoubleClick(x, y)
	--CombatManager.openMap(window.getDatabaseNode());
end

function onWheel(notches)
	--TokenManager.onWheelCT(window.getDatabaseNode(), notches);
	return true;
end

function replace(newTokenInstance)
	local oldTokenInstance = CombatManager.getTokenFromCT(window.getDatabaseNode());
	if oldTokenInstance and oldTokenInstance ~= newTokenInstance then
		if not newTokenInstance then
			local nodeContainerOld = oldTokenInstance.getContainerNode();
			if nodeContainerOld then
				local x,y = oldTokenInstance.getPosition();
				TokenManager.setDragTokenUnits(DB.getValue(window.getDatabaseNode(), "space"));
				newTokenInstance = Token.addToken(nodeContainerOld.getNodeName(), getPrototype(), x, y);
				TokenManager.endDragTokenWithUnits();
			end
		end
		oldTokenInstance.delete();
	end

	TokenManager.linkToken(window.getDatabaseNode(), newTokenInstance);
	TokenManager.updateVisibility(window.getDatabaseNode());
	
	TargetingManager.updateTargetsFromCT(window.getDatabaseNode(), newTokenInstance);
end
