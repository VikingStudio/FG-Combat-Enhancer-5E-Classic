--[[
	Copyright (C) 2018 Ken L.
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
	Handles a majority of the map token functions (ideally)
]]--

local MAP_NPC_TOKEN_LIST = 'map_npc_list'; 

function onInit()	
	--Debug.console('MAP TOKEN MANAGER LOADED'); 		
	local npcTokenElem = nil; 
	local npcTokenList = DB.findNode(MAP_NPC_TOKEN_LIST); 
	if not npcTokenList then
		npcTokenList = DB.createNode(MAP_NPC_TOKEN_LIST); 
	end

	if npcTokenList then
		tMapIds = npcTokenList.getChildren();
		for k,v in pairs(tMapIds) do
			--Debug.console('INIT MAP TOKEN CLEAN:' .. k .. ' NUM CHILD: ' .. v.getChildCount()); 
			if v.getChildCount() == 0 then
				v.delete(); 
			end
		end
	end
end

-- get the image control that contains this target
function getImgCtl(token)		
	local ctrlImage, wndImage, bWindowOpened;

	if token then
		local nodeImgCtl = token.getContainerNode(); 
		local nodeImg = nodeImgCtl.getParent(); 

		-- v1.3.0 adding support for background image
		-- Search for different image windows that host the image (normal or background)
		-- CoreRPG.Pak/Scripts/manager_image.lua handles background image code, called using ImageManager.
		-- ImageManager.function getImageControl(tokeninstance, bOpen) | Returns ctrlImage, winImage, bWindowOpened		

		ctrlImage, wndImage, bWindowOpened = ImageManager.getImageControl(token, false);			
		--Debug.chat('ctrlImage', ctrlImage, 'wndImage', wndImage, 'bWindowOpened', bWindowOpened);
		
		--local imageWindow = Interface.findWindow("imagewindow",nodeImg);		
				
		-- Creates a standard image window if none is available.
		if not wndImg then
			wndImg = Interface.openWindow("imagewindow",nodeImg); 			
		end		

		-- removed in 1.3.0, as it attempts to return same value as new varible ctrlImage to return at the end of the function (retval here)
		--[[
		if wndImg then			
			local tWndCtls = wndImg.getControls();			
			for k,v in pairs(tWndCtls) do
				if v.getDatabaseNode() then
					if v.getDatabaseNode().getPath() == nodeImgCtl.getPath() then
						Debug.chat('v', v);
						retval = v; 
						break; 
					end
				end
			end
		end		
		]]--

	end

	return ctrlImage; 	
end

--[[
	Add our additional token actions
]]--
function addAdditionalTokenMenus(token)
	token.registerMenuItem('Visibility','lockvisibilityon',8); 
	token.registerMenuItem('Always invisible','lockvisibilityoff',8,1); 
	token.registerMenuItem('Always visible','lockvisibilityon',8,8); 
	token.registerMenuItem('Mask sensitive','maskvisibility',8,7); 
	token.onMenuSelection = onExtendedTokenSelection; 
end

--[[
	Extended token selection parameters that chains
	into the NpcMenuSelection
]]--
function onExtendedTokenSelection(target, ...)
	local topSelection = arg[1];	
	local selectedTokens = getImgCtl(target).getSelectedTokens(); 
	

	--Debug.console('EXTENDED SELECTION'); 

	if topSelection == 8 then
		local secondSelection = arg[2];
		local nodeCT; 
		if secondSelection then
			if secondSelection == 1 then
				-- always invis
				--Debug.console('always invisible!'); 
				if #selectedTokens > 0 then
					for _,selToken in pairs(selectedTokens) do
						selToken.setVisible(false); 
						setCTVisibility(selToken,0); 
					end
				else
					target.setVisible(false); 
					setCTVisibility(target,0); 
				end
			elseif secondSelection == 8 then
				-- always vis
				--Debug.console('always visible!'); 
				if #selectedTokens > 0 then
					for _,selToken in pairs(selectedTokens) do
						selToken.setVisible(true); 
						setCTVisibility(selToken,1); 
					end
				else
					target.setVisible(true); 
					setCTVisibility(target,1); 
				end
			elseif secondSelection == 7 then
				-- mask sensitive
				--Debug.console('mask sensitive!'); 
				if #selectedTokens > 0 then
					for _,selToken in pairs(selectedTokens) do
						selToken.setVisible(nil); 
						setCTVisibility(selToken,1); 
					end
				else
					target.setVisible(nil); 
					setCTVisibility(target,1); 
				end
			end
		end
	elseif topSelection == 7 or topSelection == 3 then
		--Debug.console('EXTENDED SELECTION 7-3'); 
		-- check if we need to chain in
		-- chain handler into npcTokenList, note we may be double-validating
		local npcTokenList = DB.findNode(MAP_NPC_TOKEN_LIST); 
		if npcTokenList then
			--Debug.console('EXTENDED SELECTION NPC TOKEN LIST'); 
			local sMapKey = getMapTokenIndex(target); 
			local nodeMapKey = npcTokenList.getChild(sMapKey);
			if nodeMapKey ~= nil then
				local nodeTokenKey = nodeMapKey.getChild('tokenid' .. target.getId()); 
				if nodeTokenKey ~= nil then
					-- if the elem exist in the npcTokenList, then chain into the handler
					--Debug.console('MAP TOKEN TRIGGER: ' .. tostring(nodeMapKey) .. ' ++ ' .. tostring(nodeTokenKey) .. ' ++ ' .. nodeTokenKey.getName()); 
					onNpcMenuSelection(target,topSelection); 
				else
					-- else if the token exists on the CT, chain into the CTMenu handler
					local nodeCT = CombatManager.getCTFromToken(target); 
					if nodeCT then
						--Debug.console('CT TOKEN TRIGGER'); 
						onCTMenuSelection(target,topSelection); 
					else
						--Debug.console('NON CT or MAP TOKEN TRIGGER'); 
					end
				end
			else
				-- else if the token exists on the CT, chain into the CTMenu handler
				local nodeCT = CombatManager.getCTFromToken(target); 
				if nodeCT then
					--Debug.console('CT TOKEN TRIGGER'); 
					onCTMenuSelection(target,topSelection); 
				else
					--Debug.console('NON CT or MAP TOKEN TRIGGER'); 
				end
			end
		end
	end
end

--[[
	Set CTVisibility
]]--
function setCTVisibility(token,visible)
	local nodeCT = CombatManager.getCTFromToken(token); 
	if nodeCT then
		local tokenvis = nodeCT.createChild('tokenvis','number');
		if visible == 0 then
			tokenvis.setValue(0); 
		elseif visible == 1 then
			tokenvis.setValue(1); 
		end
	end
end

--[[
	Prepare the map token by adding it to the map_npc_list datanode
]]--
function prepMapToken(x,y,mapTokenNode,imgCtl)
	-- create a token on the image control we may need to add a widget to indicate it's not on the tracker
	-- create an reference list if it does not exist within the image control
	-- create an entry in this list with the tokenID, set the value to the npc reference's node-Name; 
	-- NOTE when we check this later, we need to confirm that this node name exists before we add to the tracker
	-- NOTE OR we can hook into the onDelete to remove these references as a form of garbage collection
	--Debug.console('attempting to prep the map token'); 
	local sName = DB.getValue(mapTokenNode,'name'); 
	
	local tokenProto = DB.getValue(mapTokenNode, "token", "");
	if tokenProto == "" or not Interface.isToken(tokenProto) then
		local sLetter = StringManager.trim(sName):match("^([a-zA-Z])");
		if sLetter then
			tokenProto = "tokens/Medium/" .. sLetter:lower() .. ".png@Letter Tokens";
		else
			tokenProto = "tokens/Medium/z.png@Letter Tokens";
		end
		--DB.setValue(mapTokenNode, "token", "token", tokenProto);
	end


	-- Add it to the image at the drop coordinates using the npc's space from CM
	local space, reach = CombatManager.getNPCSpaceReach(mapTokenNode); 
	TokenManager.setDragTokenUnits(space);
	local newMapToken = imgCtl.addToken(tokenProto,x,y); 
	TokenManager.endDragTokenWithUnits();

	--Debug.console('newToken: ' .. tostring(newMapToken) .. ' ++ proto is: ' .. tokenProto); 
	if newMapToken == nil then
		-- we failed to create a token, inform the user to put in a token image to use this feature
		Comm.addChatMessage({text="Failed to create NPC map link, make sure you have an actual token image for that npc entry (using the default letters does not count)",secret=true}); 
	else
		-- we have a token reference, so let's do work!
		local npcTokenList = DB.findNode(MAP_NPC_TOKEN_LIST); 
		if not npcTokenList then
			npcTokenList = DB.createNode(MAP_NPC_TOKEN_LIST); 
		end
		if npcTokenList then
			--Debug.console('npc list made/found ' .. newMapToken.getId()); 
			-- we need an elem name that is a combination of the image name + token id
			--local npcTokenElem = npcTokenList.createChild('npc' .. newMapToken.getId(),'string'); 
			local npcTokenElem = getMapTokenEntry(newMapToken); 
			if npcTokenElem then
				--Debug.console('npc element made'); 
				npcTokenElem.setValue(mapTokenNode.getNodeName()); 
				setupMapTokenMenu(newMapToken); 
				-- add an underlay to denote that this is a 'map' token and not on the CT yet
				newMapToken.addUnderlay(space/5/2, Modifications.TOKENUNDERLAYCOLOR_2); 
				-- add double click handler to open the NPC entry
				newMapToken.onDoubleClick = onMapTokenDoubleClick; 
				-- initial state is invisible
				newMapToken.setVisible(false); 
				-- flag them as unmodifiable
				newMapToken.setModifiable(false); 
			end
		end

	end
end

-- return the maptoken index used for this imagecontrol
function getMapTokenIndex(token,imgCtl)
	local imgCtlNode; 
	if not imgCtl then 		
		imgCtlNode = getImgCtl(token).getDatabaseNode(); 
	else
		imgCtlNode = imgCtl.getDatabaseNode(); 
	end

	local imgNode = imgCtlNode.getParent(); 
	local simgName = imgNode.getChild('name').getValue(); 

	simgName = simgName .. imgNode.getName() .. imgCtlNode.getName(); 
	simgName = sanatizeXML(simgName); 

	return simgName; 
end

--[[
	Given a token, create an entry on the map token list of the format:

	imagename
	 -> tokenid

	 return the reference if successful, else nil
]]--
function getMapTokenEntry(token,imgCtl)
	local npcTokenElem = nil; 
	local npcTokenList = DB.findNode(MAP_NPC_TOKEN_LIST); 
	if not npcTokenList then
		npcTokenList = DB.createNode(MAP_NPC_TOKEN_LIST); 
	end

	if npcTokenList then
		local sImageKey = getMapTokenIndex(token,imgCtl); 
		--Debug.console('GET--> imagekey: ' .. sImageKey .. ' tokenid: ' .. token.getId()); 
		local nodeImgKey = npcTokenList.createChild(sImageKey); 
		npcTokenElem = nodeImgKey.createChild('tokenid'..token.getId(),"string"); 
	end

	return npcTokenElem; 
end

--[[
	Check for the existance of the token in the map token list
]]--
function checkMapTokenEntry(token,imgCtl)
	local npcTokenElem = nil; 
	local npcTokenList = DB.findNode(MAP_NPC_TOKEN_LIST); 
	if not npcTokenList then
		npcTokenList = DB.createNode(MAP_NPC_TOKEN_LIST); 
		return false; 
	end

	if npcTokenList then
		local sImageKey = getMapTokenIndex(token,imgCtl); 
		local nodeImgKey = npcTokenList.getChild(sImageKey); 
		if nodeImgKey then
			npcTokenElem = nodeImgKey.getChild('tokenid'..token.getId()); 
			--Debug.console('CHECK--> imagekey: ' .. sImageKey .. ' tokenid: ' .. token.getId() .. ' ++ ' .. tostring(npcTokenElem)); 
			if npcTokenElem and npcTokenElem.getValue() ~= ''  then
				return true; 
			end
		end
	end
end

-- return the maptoken index used for this imagecontrol
function getMapTokenIndexInit(imgCtl)
	local imgCtlNode = imgCtl.getDatabaseNode(); 
	local imgNode = imgCtlNode.getParent(); 
	local simgName = imgNode.getChild('name').getValue(); 
	simgName = simgName .. imgNode.getName() .. imgCtlNode.getName(); 
	simgName = sanatizeXML(simgName); 

	return simgName; 
end

--[[
	Given a token, create an entry on the map token list of the format:

	imagename
	 -> tokenid

	 return the reference if successful, else nil
]]--
function getMapTokenEntryInit(token,imgCtl)
	local npcTokenElem = nil; 
	local npcTokenList = DB.findNode(MAP_NPC_TOKEN_LIST); 
	if not npcTokenList then
		npcTokenList = DB.createNode(MAP_NPC_TOKEN_LIST); 
	end

	if npcTokenList then
		local sImageKey = getMapTokenIndexInit(imgCtl); 
		--Debug.console('GET--> imagekey: ' .. sImageKey .. ' tokenid: ' .. token.getId()); 
		local nodeImgKey = npcTokenList.createChild(sImageKey); 
		npcTokenElem = nodeImgKey.createChild('tokenid'..token.getId(),"string"); 
	end

	return npcTokenElem; 
end

--[[
	Check for the existance of the token in the map token list
]]--
function checkMapTokenEntryInit(token,imgCtl)
	local npcTokenElem = nil; 
	local npcTokenList = DB.findNode(MAP_NPC_TOKEN_LIST); 
	if not npcTokenList then
		npcTokenList = DB.createNode(MAP_NPC_TOKEN_LIST); 
		return false; 
	end

	if npcTokenList then
		local sImageKey = getMapTokenIndexInit(imgCtl); 
		local nodeImgKey = npcTokenList.getChild(sImageKey); 
		if nodeImgKey then
			npcTokenElem = nodeImgKey.getChild('tokenid'..token.getId()); 
			--Debug.console('CHECK--> imagekey: ' .. sImageKey .. ' tokenid: ' .. token.getId() .. ' ++ ' .. tostring(npcTokenElem)); 
			if npcTokenElem and npcTokenElem.getValue() ~= ''  then
				return true; 
			end
		end
	end
end


-- Light, half-butt sanitation
function sanatizeXML(str)
	str = str:gsub('%s',''); 
	str = str:gsub('%.',''); 
	str = str:gsub('%(',''); 
	str = str:gsub('%)',''); 
	str = str:gsub('%%',''); 
	str = str:gsub('%-',''); 
	str = str:gsub('%+',''); 
	str = str:gsub('%*',''); 
	str = str:gsub('%?',''); 
	str = str:gsub('%[',''); 
	str = str:gsub('%]',''); 
	str = str:gsub('%^',''); 
	str = str:gsub('%$',''); 

	return str; 
end

--[[
	on ImageControl init, we need to rebind the menu and delete handlers for tokens that have connected
	map_npc_list mappings!
]]--
function initMapTokens(imgCtl)
	local npcTokenList = DB.findNode(MAP_NPC_TOKEN_LIST); 
	local listTokens = imgCtl.getTokens(); 
	local nodeCT; 

	if npcTokenList then
		-- check if we have a mapping in map_npc_list
		--Debug.console('I- npc token list found'); 
		for _,token in pairs(listTokens) do
			nodeCT = CombatManager.getCTFromToken(token); 
			if not nodeCT then
				if checkMapTokenEntry(token,imgCtl) then
					local npcTokenElem = getMapTokenEntry(token,imgCtl); 
					local npcDataNodeName = npcTokenElem.getValue(); 
					local npcDataNode = DB.findNode(npcDataNodeName); 
					--Debug.console('I- npc element : ' .. npcDataNodeName); 
					-- we're 100% sure, now bind the handlers
					setupMapTokenMenu(token); 
					-- add an underlay to denote that this is a 'map' token and not on the CT yet
					-- we need to find the NPC node again to get the space
					local space, reach = CombatManager.getNPCSpaceReach(npcDataNode); 
					token.removeAllUnderlays(); 
					token.addUnderlay(space/5/2, Modifications.TOKENUNDERLAYCOLOR_2); 
					-- add double click handler to open the NPC entry
					token.onDoubleClick = onMapTokenDoubleClick; 
					-- flag them as unmodifiable
					token.setModifiable(false); 
				end
			else
				local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
				if sClass == 'npc' then
					setupCombatTokenMenu(token); 
				end
			end
		end
	end
end

-- setup a single token that may have been reset somehow
function initSingleToken(token)
	local nodeCT; 

	nodeCT = CombatManager.getCTFromToken(token); 
	if not nodeCT then
		-- check if we have a mapping in map_npc_list
		local npcTokenList = DB.findNode(MAP_NPC_TOKEN_LIST); 
		if npcTokenList then
			--Debug.console('I- npc token list found'); 

			if checkMapTokenEntry(token) then
				local npcTokenElem = getMapTokenEntry(token); 
				local npcDataNodeName = npcTokenElem.getValue(); 
				local npcDataNode = DB.findNode(npcDataNodeName); 
				--Debug.console('I- npc element : ' .. npcDataNodeName); 
				-- we're 100% sure, now bind the handlers
				setupMapTokenMenu(token); 
				-- add an underlay to denote that this is a 'map' token and not on the CT yet
				-- we need to find the NPC node again to get the space
				local space, reach = CombatManager.getNPCSpaceReach(npcDataNode); 
				token.removeAllUnderlays(); 
				token.addUnderlay(space/5/2, Modifications.TOKENUNDERLAYCOLOR_2); 
				-- add double click handler to open the NPC entry
				token.onDoubleClick = onMapTokenDoubleClick; 
				-- flag them as unmodifiable
				token.setModifiable(false); 
			end
		end
	else
		local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
		if sClass == 'npc' then
			setupCombatTokenMenu(token); 
		end
	end
end

--[[
	
]]--
function onMapTokenDoubleClick(tokenMap, vImage)
	if Input.isShiftPressed() and User.isHost() then
		local npcTokenList = DB.findNode(MAP_NPC_TOKEN_LIST); 
		if npcTokenList then
			--Debug.console('MC- npc token list found'); 

			if checkMapTokenEntry(tokenMap) then
				local npcTokenElem = getMapTokenEntry(tokenMap); 
				local npcDataNodeName = npcTokenElem.getValue(); 
				local npcDataNode = DB.findNode(npcDataNodeName); 
				--Debug.console('MC- npc element : ' .. npcDataNodeName); 
				if npcDataNode then
					Interface.openWindow("npc", npcDataNode);
					vImage.clearSelectedTokens();
				end
			end
		end
	end
	return true; 
end

--[[
	setup a new map_npc_list binding, we override position 3, and use
	4 for a group selection
]]--
function setupMapTokenMenu(token)
	token.registerMenuItem('Add to Tracker','addcombat_radial',3); 
	token.registerMenuItem('Add Selected Tracker','addcombat_multi_radial',7); 

	-- we handle this in our addToken function, chaining into onNPCMenuSelection
	--token.onMenuSelection = onNpcMenuSelection; 
	token.onDelete = onNpcDelete; 
	-- migrated this to CombatSnap's manager_token.lua
	--token.onDoubleClick = onNpcDoubleClick; 
end

function setupCombatTokenMenu(token)
	token.registerMenuItem('Remove from Tracker','delcombat_radial',3); 
	token.registerMenuItem('Remove Selected from Tracker','delcombat_multi_radial',7); 
end

--[[
	our delete handler for when npc tokens are removed
]]--
function onNpcDelete(target)
	local npcTokenList = DB.findNode(MAP_NPC_TOKEN_LIST); 
	if npcTokenList then
		--Debug.console('D- npc token list found'); 
		if checkMapTokenEntry(target) then
			local npcTokenElem = getMapTokenEntry(target); 
			local npcDataNodeName = npcTokenElem.getValue(); 
			--Debug.console('D- npc element : ' .. npcDataNodeName); 
			npcTokenElem.delete(); 
		end
		--clean everything!
		--[[
		local list = npcTokenList.getChildren();
		for k,v in pairs(list) do
			v.delete(); 
		end
		]]--
	end

end

--[[
	our menu selection handler for map tokens
]]--
function onNpcMenuSelection(target, ...)
	local topSelection = arg[1]; 
	local imgCtl = getImgCtl(target); 
	--Debug.console("selected an item! NPC " .. tostring(topSelection)); 
	if topSelection == 3 then
		--Debug.console("in item! " .. tostring(topSelection)); 
		local npcTokenList = DB.findNode(MAP_NPC_TOKEN_LIST); 
		if npcTokenList then
			--Debug.console('npc token list found'); 

			if checkMapTokenEntry(target) then
				local npcTokenElem = getMapTokenEntry(target); 
				local npcDataNodeName = npcTokenElem.getValue(); 
				local npcDataNode = DB.findNode(npcDataNodeName); 
				--Debug.console('npc element : ' .. npcDataNodeName); 
				if npcDataNode then
					-- we try to insert our NPC into the combat tracker
					local visibility = target.isVisible(); 
					local nodeCT = CombatManager.addNPC('npc', npcDataNode); 
					--local nodeCT = CombatManager2.addNPC('npc', npcDataNode, npcDataNode.getChild('name').getValue())
					-- destroy the map_npc_list links and the menu additions
					npcTokenElem.delete(); 
					target.resetMenuItems();
					-- re-add our visibility menus
					addAdditionalTokenMenus(target); 
					-- add combat menus MIGRATED to updateAttributeHelper
					--setupCombatTokenMenu(target); 
					--target.onDelete = nil; 
					--target.onMenuSelection = nil; 
					-- remove our 'map token' underlay;
					target.removeAllUnderlays(); 
					-- finish configuration that normally occurs in combat manager
					DB.setValue(nodeCT, "token", "token", target.getPrototype());
					-- strip the local onClickHandler that was used for unbinded map-tokens
					target.onDoubleClick = TokenManager.onDoubleClick; 
					TokenManager.linkToken(nodeCT, target);
					TokenManager.updateAttributes(nodeCT.getChild('tokenrefid')); 
					local visNode = nodeCT.getChild('tokenvis'); 
					if visNode then
						if visibility then
							visNode.setValue(1); 
						else
							visNode.setValue(0); 
						end
					end
				else
					--Debug.console('BAD DATA NODE'); 
					Comm.addChatMessage({text="NPC linked no longer exists! Deleting token..",secret=true}); 
					target.delete(); 
				end
			end
		end
	elseif topSelection == 7 then
		local listTokens = imgCtl.getSelectedTokens(); 
		local npcTokenList = DB.findNode(MAP_NPC_TOKEN_LIST); 
		if npcTokenList then
			--Debug.console('S- npc token list found'); 
			for _,token in pairs(listTokens) do
				-- check if we have a mapping in map_npc_list

				if checkMapTokenEntry(token)  then
					local npcTokenElem = getMapTokenEntry(token); 
					local npcDataNodeName = npcTokenElem.getValue(); 
					local npcDataNode = DB.findNode(npcDataNodeName); 
					--Debug.console('S- npc element : ' .. npcDataNodeName); 
					-- we're 100$ sure, now add them
					if npcDataNode then
						-- we try to insert our NPC into the combat tracker
						local visibility = token.isVisible(); 
						local nodeCT = CombatManager.addNPC('npc', npcDataNode)
						--local nodeCT = CombatManager2.addNPC('npc', npcDataNode, npcDataNode.getChild('name').getValue())
						-- destroy the map_npc_list links and the menu additions
						npcTokenElem.delete(); 
						token.resetMenuItems(); 		
						-- re-add our visibility menus
						addAdditionalTokenMenus(token); 
						-- add combat menus MIGRATED to updateAttributHelper
						--setupCombatTokenMenu(token); 
						-- finish configuration that normally occurs in combat manager
						DB.setValue(nodeCT, "token", "token", token.getPrototype());
						-- strip the local onClickHandler that was used for unbinded map-tokens
						token.onDoubleClick = TokenManager.onDoubleClick; 
						TokenManager.linkToken(nodeCT, token);
						TokenManager.updateAttributes(nodeCT.getChild('tokenrefid')); 
						local visNode = nodeCT.getChild('tokenvis'); 
						if visNode then
							if visibility then
								visNode.setValue(1); 
							else
								visNode.setValue(0); 
							end
						end
					else
						--Debug.console('BAD DATA NODE'); 
						Comm.addChatMessage({text="NPC linked no longer exists! Deleting token..",secret=true}); 
						token.delete(); 
					end
				end
			end
		end
	end
end

--[[
	our menu selection handler for combat tokens
]]--
function onCTMenuSelection(target, ...)
	local topSelection = arg[1]; 
	local imgCtl = getImgCtl(target); 
	--Debug.console("selected an item COMBAT!! " .. tostring(topSelection)); 

	if topSelection == 3 then
		--Debug.console("in item! " .. tostring(topSelection)); 
		local npcTokenList = DB.findNode(MAP_NPC_TOKEN_LIST); 
		if npcTokenList then
			--Debug.console('S- npc token list found'); 

			nodeCT = CombatManager.getCTFromToken(target); 
			if nodeCT then
				local x,y = target.getPosition(); 
				--Debug.console(nodeCT.getName()); 
				
				-- The record is useless as it'll point right back to the CT node we're deleting
				local sClass,sRecord = DB.getValue(nodeCT, "sourcelink", "", "");
				--Debug.console('S- class: ' .. tostring(sClass) .. ' Record: ' .. tostring(sRecord)); 

				-- we will only do this for npcs clearly, note that we don't check
				-- the sourcelink's validity if it's been deleted, we handle this 
				-- elsewhere when it's added to the tracker
				if sClass == 'npc' then
					local space, reach = CombatManager.getNPCSpaceReach(nodeCT); 
					TokenManager.setDragTokenUnits(space);
					local newMapToken = imgCtl.addToken(target.getPrototype(),x,y); 
					TokenManager.endDragTokenWithUnits();
					if newMapToken then
						local npcTokenElem = getMapTokenEntry(newMapToken); 
						if npcTokenElem then
							--Debug.console('S- npc element made'); 
							local space = DB.getValue(nodeCT,'space',5); 
							npcTokenElem.setValue(sRecord); 
							setupMapTokenMenu(newMapToken); 
							-- add an underlay to denote that this is a 'map' token and not on the CT yet
							newMapToken.addUnderlay(space/5/2, Modifications.TOKENUNDERLAYCOLOR_2); 
							-- add double click handler to open the NPC entry
							newMapToken.onDoubleClick = onMapTokenDoubleClick; 
							-- initial state is the CT's visibility
							newMapToken.setVisible(target.isVisible()); 
							-- finially remove the CT node
							nodeCT.delete(); 
						end
					else
						Comm.addChatMessage({text="Failed to create NPC map link, make sure you have an actual token image for that npc entry (using the default letters does not count)",secret=true}); 
					end
				end
			end
		end
	elseif topSelection == 7 then
		local listTokens = imgCtl.getSelectedTokens(); 
		local npcTokenList = DB.findNode(MAP_NPC_TOKEN_LIST); 
		if npcTokenList then
			--Debug.console('S- npc token list found'); 
			for _,token in pairs(listTokens) do
				-- check if we have a mapping in map_npc_list
				nodeCT = CombatManager.getCTFromToken(token); 
				if nodeCT then
					local x,y = token.getPosition(); 
					--Debug.console(nodeCT.getName()); 
					
					-- The record is useless as it'll point right back to the CT node we're deleting
					local sClass,sRecord = DB.getValue(nodeCT, "sourcelink", "", "");
					--Debug.console('S- class: ' .. tostring(sClass) .. ' Record: ' .. tostring(sRecord)); 

					-- we will only do this for npcs clearly, note that we don't check
					-- the sourcelink's validity if it's been deleted, we handle this 
					-- elsewhere when it's added to the tracker
					if sClass == 'npc' then
						local space, reach = CombatManager.getNPCSpaceReach(nodeCT); 
						TokenManager.setDragTokenUnits(space);
						local newMapToken = imgCtl.addToken(token.getPrototype(),x,y); 
						TokenManager.endDragTokenWithUnits();
						if newMapToken then
							local npcTokenElem = getMapTokenEntry(newMapToken); 
							if npcTokenElem then
								--Debug.console('S- npc element made'); 
								local space = DB.getValue(nodeCT,'space',5); 
								npcTokenElem.setValue(sRecord); 
								setupMapTokenMenu(newMapToken); 
								-- add an underlay to denote that this is a 'map' token and not on the CT yet
								newMapToken.addUnderlay(space/5/2, Modifications.TOKENUNDERLAYCOLOR_2); 
								-- add double click handler to open the NPC entry
								newMapToken.onDoubleClick = onMapTokenDoubleClick; 
								-- initial state is the CT's visibility
								newMapToken.setVisible(token.isVisible()); 
								-- finially remove the CT node
								nodeCT.delete(); 
							end
						else
							Comm.addChatMessage({text="Failed to create NPC map link, make sure you have an actual token image for that npc entry (using the default letters does not count)",secret=true}); 
						end
					end
				end
			end
		end
	end
end

