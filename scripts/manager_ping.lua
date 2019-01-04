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
	Ping manager: essentially flips a single boolean to trigger a database update
	for handling the 'ping' function
]]--

function onInit()
	-- handler for ping
	--Debug.console('PING MANAGER LOADED'); 
	OOBManager.registerOOBMsgHandler('PING_UPDATE',receivePingOOB); 
end

function doPing(x,y,imgctl)
	local tokenproto = "tokens/host/items/ping_target.png";

	-- check parent for our image control siblings, if we
	-- have an 'image sibling' get that window and place
	-- our marker there else nothing
	local tWndCtls = imgctl.window.getControls(); 
	local wndImgRef = imgctl.window.getDatabaseNode().getPath(); 
	local imgctlPing = nil; 
	for k,v in pairs(tWndCtls) do
		----Debug.console (tostring(k) .. ' ---> ' .. tostring(v.getName())); 
		if v.getName() == 'image' then
			-- we found the image, 
			imgctlPing = v; 
			break; 
		end
	end

	-- check if our datanode has a ping token reference
	-- of so then we remove it, and clear the reference
	-- else we put the token id and image name to force
	-- an update to connected players that react to
	-- the DB handlers
	--
	-- Note that toggle may end up juggling windows (opening/closing)
	-- to clear the prior ping token. We'll need to refresh our reference
	togglePing(imgctlPing); 

	-- Refresh the references
	local wndImg = Interface.openWindow("imagewindow",wndImgRef); 
	if wndImg then
		tWndCtls = wndImg.getControls(); 
		for k,v in pairs(tWndCtls) do
			--Debug.console('k: ' .. k .. ' v: ' .. tostring(v.getName())); 
			if v.getName() == "image" then
				imgctlPing = v; 
				break; 
			end
		end
	end
	-- Create the token
	if Input.isShiftPressed() and imgctlPing then
		local tokenMap = imgctlPing.addToken(tokenproto, x, y);
		if tokenMap then
			tokenMap.setVisible(true); 
			--Debug.console('creation was a success!'); 
			updatePingDataNode(tokenMap,imgctlPing); 
		end
	else
		updatePingDataNode(nil,imgctlPing); 
	end

end

--[[
	Replaces the database update with an OOB
]]--
function sendPingOOB(nodeImage,x,y,z)
	local OOBMsg = {type="PING_UPDATE",xcoord=x,ycoord=y,zoom=z,image=nodeImage.getPath()};
	Comm.deliverOOBMessage(OOBMsg); 
	--Debug.console("SENT PING OOB"); 
end

--[[
	Respond to the OOB if we're not the host
]]--
function receivePingOOB(OOBMsg)
	if not User.isHost() then
		--Debug.console("GOT PING OOB"); 
		local x = OOBMsg.xcoord;
		local y = OOBMsg.ycoord;
		local z = OOBMsg.zoom;
		local nodeImage = DB.findNode(OOBMsg.image);
		if nodeImage then
			local imageName = nodeImage.getName();
			--Debug.console('image name: ' .. imageName); 
			local w = Interface.openWindow('imagewindow',nodeImage);
			--Debug.console('want to open window @' .. imageName .. ' x:' .. x .. ' y:' .. y); 
			w.image.setViewpointCenter(x,y,z);
		end
	end
end

--[[ 
	Update the ping data node. If a token is present
	then update the reference, if it's not then remove it.
]]--
function updatePingDataNode(token,imgctlPing)
	local nodePing = DB.findNode('ping');
	local nodePingId = nil;
	local nodePingImage = nil; 

	if nil == nodePing then
		createPingData(); 
	else
		nodePingId = DB.findNode('ping.tokenid'); 
		nodePingImage = DB.findNode('ping.image'); 
		nodePing.setPublic(true); 

		-- failsafe
		if not nodePingId
		or not nodePingImage then
			nodePingId = nodePing.createChild('tokenid','string');
			nodePingImage = nodePing.createChild('image','string');  
		end
		-- rectify if needed
		nodePingId.setPublic(true); 
		nodePingImage.setPublic(true); 

		if token then
			local vpx, vpy, vpz = imgctlPing.getViewpoint();
			local imgNode = imgctlPing.getDatabaseNode(); 
			imgNode = imgNode.getParent(); 
			
			--Debug.console('setting imagename: '  .. simgName); 
			nodePingImage.setValue(imgNode.getPath()); 
			local x,y = token.getPosition();
			--Debug.console('position x:' .. x .. ' y:' .. y); 
			nodePingId.setValue(tostring(token.getId()));
			sendPingOOB(imgNode,x,y,vpz); 
		else
			nodePingImage.setValue(''); 
			nodePingId.setValue(''); 
		end
	end
end

--[[
	Return true if the map is active, if so, remove the token if it's present

	NOTE: it only removes the token if the token is on the ping'd image window,
	if a new image window is pinged, the ping graphic WILL NOT be removed from
	the former!

	Change this such that 'imagename' is now the imageid
]]--
function togglePing(imgctlPing)
	local nodePing = DB.findNode('ping');
	local nodePingId = nil;
	local nodePingImage = nil; 

	if nodePing then
		nodePingId = DB.findNode('ping.tokenid'); 
		nodePingImage = DB.findNode('ping.image'); 
		
		if not nodePingId or not nodePingImage then
			return false;
		end

		-- So we're not allowed to look at the <token> list in an image node..
		-- fine, then we'll cheat by opening up the old image window, deleteing our
		-- token, and then reopening the current.

		local tokenImgPath = nodePingImage.getValue(); 
		local tokenId = nodePingId.getValue(); 
		local curImgPath = imgctlPing.getDatabaseNode().getParent().getPath(); 
		local tokenlist,wndImg_other,prioropen; 
		--Debug.console('tokenImgpath: ' .. tostring(tokenImgPath)); 

		if tokenImgPath ~= nil and tokenImgPath ~= '' then
			if tokenImgPath == curImgPath then
				tokenlist = imgctlPing.getTokens();
			else
				-- open other image window 
				local nodeImg = DB.findNode(tokenImgPath); 
				--Debug.console('nodeImg: ' .. tostring(nodeImg)); 
				if nodeImg then
					wndImg_other = Interface.findWindow("imagewindow",nodeImg); 
					if not wndImg_other then 
						prioropen = true; 
						wndImg_other = Interface.openWindow("imagewindow",nodeImg); 
					end
					if wndImg_other then
						local other_ctls = wndImg_other.getControls(); 
						for k,v in pairs(other_ctls) do
							--Debug.console('k: ' .. k .. ' v: ' .. tostring(v.getName())); 
							if v.getName() == "image" then
								tokenlist = v.getTokens(); 
								break; 
							end
						end
					end
				end
			end
			-- check if token id still exists
			if tokenlist then
				for _,v in pairs(tokenlist) do
					--Debug.console('checking: ' .. tokenId .. ' vs: ' .. v.getId()); 
					if tostring(v.getId()) == tokenId then
						--Debug.console('ping token already active, removing it!'); 
						v.delete(); 
						-- close our 'other window' if open, reopen, or bring to front our original
						if wndImg_other and prioropen then
							wndImg_other.close(); 
							Interface.openWindow("imagewindow",curImgPath); 
						end
						return true;
					end
				end
			end
			-- close our 'other window' if open, reopen, or bring to front our original
			if wndImg_other and prioropen then
				wndImg_other.close(); 
				Interface.openWindow("imagewindow",curImgPath); 
			end
		end

	else
		createPingData(); 
	end

	--Debug.console('ping token NOT active!'); 
	return false; 
end

--[[
	Create the Ping datanode if it does not exist
]]--
function createPingData()
	local nodePing = nil;
	local nodePingId = nil;
	local nodePingImage = nil; 

	nodePing = DB.createNode('ping');
	nodePing.setPublic(true); 
	nodePingId = nodePing.createChild('tokenid','string');
	nodePingId.setPublic(true); 
	nodePingImage = nodePing.createChild('image','string');  
	nodePingImage.setPublic(true); 

	nodePingImage.setValue(''); 
	nodePingId.setValue(''); 
end

