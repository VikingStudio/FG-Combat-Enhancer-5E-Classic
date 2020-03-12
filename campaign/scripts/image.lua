--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.

function onInit()
	if User.isHost() then
		setTokenOrientationMode(false);
		-- Setup map tokens; 
		MapTokenManager.initMapTokens(self); 
		-- Add additiona token functions on init
		local tokenList = self.getTokens();
		for _,token in pairs(tokenList) do
			MapTokenManager.addAdditionalTokenMenus(token); 
		end
	end
	
	onCursorModeChanged();
	onGridStateChanged();
	-- window.updateDisplay();

	-- height modifications

	-- Set onZoom handler to do nothing
	--self.onZoom = function() end;
end

--[[
	Add additional visibility parameters
]]--
function onTokenAdded(token)
	if User.isHost() then
		MapTokenManager.addAdditionalTokenMenus(token); 
	end
end

-- place the token if we're in select mode
function onClickRelease(button, x, y)
	local sTool = getCursorMode(); 

	if User.isHost() and sTool == nil then
		--Debug.console('click release! no active tool!'); 
		-- get location of mouse with respect to viewport + grid
		local vpx, vpy, vpz = getViewpoint();
		x = x / vpz;
		y = y / vpz;
					
		PingManager.doPing(x,y,self);
		--FOW.toggleFOW(x,y,self);
	end

end

function onCursorModeChanged(sTool)
	window.onCursorModeChanged();
end

function onGridStateChanged(gridtype)
	--Debug.console("image.lua: onGridStateChanged.  Image control = " .. self.getName());
	--EXT
	if self.hasGrid() then
		window.syncToPlayImageGrid(self);	
	else
		-- The grid has been turned off on this layer - turn it off across all layers
		window.removeGrid();	
	end

	--Debug.console("image.lua: onGridStateChanged. Calling updateDisplay.");
	window.onGridStateChanged();
	-- window.updateDisplay();
end

function onTargetSelect(aTargets)

	-- Enhanced Images: Added to disable GM targeting on base and features layer
	-- TODO: Currently not working - returning false to onTargetSelect doesn't seem to stop target processing.
	if self.getName() ~= "play_image" then
		----Debug.console("image.lua: onTargetSelect - image control = " .. self.getName());
		return false;
	end
	
	local aSelected = getSelectedTokens();
	if #aSelected == 0 then
		local tokenActive = TargetingManager.getActiveToken(self);
		if tokenActive then
			local bAllTargeted = true;
			for _,vToken in ipairs(aTargets) do
				if not vToken.isTargetedBy(tokenActive) then
					bAllTargeted = false;
					break;
				end
			end
			
			for _,vToken in ipairs(aTargets) do
				tokenActive.setTarget(not bAllTargeted, vToken);
			end
			return true;
		end
	end
end

function onDrop(x, y, draginfo)
	local sDragType = draginfo.getType();

	-- Determine image viewpoint
	-- Handle zoom factor (>100% or <100%) and offset drop coordinates
	local vpx, vpy, vpz = getViewpoint();
	x = x / vpz;
	y = y / vpz;
	
	-- If grid, then snap drop point and adjust drop spread
	local nDropSpread = 15;
	if hasGrid() then
		x, y = snapToGrid(x, y);
		nDropSpread = getGridSize();
	end

	-- for the map tokens, we also want to ensure only the host can do this
	if sDragType == "shortcut" and User.isHost() then
		local dbref = draginfo.getDatabaseNode();
		if dbref then
			local nodeName = dbref.getNodeName();
			local topLevelName,pathItems; 
			pathItems = StringManager.split(nodeName,'.'); 

			topLevelName = pathItems[1]; 
			--Debug.console('shortcut: ' .. topLevelName .. ' full node name: ' .. nodeName); 
			if topLevelName == 'npc' then
				MapTokenManager.prepMapToken(x,y,dbref,self); 
				return true; 
			elseif topLevelName == 'reference' then
				local secondLevelName = pathItems[2];
				if secondLevelName == 'npcdata' then
					MapTokenManager.prepMapToken(x,y,dbref,self); 
					return true; 
				end
			end
		end
	elseif sDragType == "shortcut" then
		local sClass,_ = draginfo.getShortcutData();
		if sClass == "charsheet" then
			if not Input.isShiftPressed() then
				return true;
			end
		end
	elseif sDragType == "combattrackerff" then
		return CombatManager.handleFactionDropOnImage(draginfo, self, x, y);
	elseif sDragType == "token" and User.isHost() then
		-- MIGRATED to onDragEnd of the tokenfield
	else
		--Debug.console('drag type is : ' .. sDragType); 
	end
end

-- Enhanced images extension - used to synch layers when "dragging" with the middle button - i.e. panning the image.
local last = {};

function getLastCoords()
	if last.x and last.y then
		return last.x, last.y;
	else
		return 0, 0;
	end
end

function updateLastCoords(x, y) 
	last.x = x;
	last.y = y;
end

function onClickDown(button, x, y)
    -- Determine if middle mouse button is clicked
	if button==2 then		
	    -- update last x, y position with current coordinates
		last.x = x;
		last.y = y;
	end

	-- if status icons is loaded, then we want to close the fake 'context window'
	local wnd = Interface.findWindow('minieffects','effects'); 
	if wnd then
		wnd.close(); 
	end

end

function onClose()
	-- if status icons is loaded, then we want to close the fake 'context window'
	local wnd = Interface.findWindow('minieffects','effects'); 
	if wnd then
		wnd.close(); 
	end

end

function onDragStart(button, x, y, dragdata)
	return onDrag(button, x, y, dragdata);
end

function onDrag(button, x, y, draginfo)
	-- Determine if middle mouse button is clicked
	if button == 2 then		
		-- Determine drag distance since initial click
		local dx = x - (last.x or 0);
		local dy = y - (last.y or 0);
		-- Determine image viewpoint
		local nx, ny, zoom = getViewpoint();
		 -- update last x, y position with current coordinates
		updateLastCoords(x,y);
		
		if User.isHost() then
			-- set the new viewpoint based upon current viewpoint + drag distance
			window.image.setViewpoint(nx+dx, ny+dy, zoom);
			-- sync viewpoints for all layers
			window.syncToImageViewpoint();
		else
			-- set the new viewpoint based upon current viewpoint + drag distance
			window.play_image.setViewpoint(nx+dx, ny+dy, zoom);
			-- sync viewpoints for all layers
			window.syncToPlayImageViewpoint();
		end
		return true;
	end
end


-- Height Extension modifications
local measureLock = false; 
function acquireMeasureSemaphore()
	if not measureLock then
		measureLock = true; 
		return true; 
	end
	return false; 
end

-- releases the semaphore if it is held
function releaseMeasureSemaphore()
	if measureLock then
		measureLock = false;
	end
end

-- peek at the semaphore without acquiring it
function checkMeasureSempahore()
	return measureLock;
end

local listCT; 
-- We're preforming up to N lookups each time to find tokens
-- at the pointer start/end positions, fortunately,
-- the points given for targeting are directly
-- at the center of each token, the pixel length
-- is useless, the map coords are where the real
-- meat is.
function getNodeHeightsAt(posSX,posSY,posEX,posEY,gridSize)
	local startTokenHeight = nil; 
	local endTokenHeight = nil; 

	if not listCT then
		listCT = DB.findNode('combattracker.list'); 
	end

	local ctEntries = listCT.getChildren(); 

	for k,v in pairs(ctEntries) do
		token = CombatManager.getTokenFromCT(v); 
		if token then
			local posX,posY = token.getPosition()
			--Debug.console('coords of token ' .. v.getChild('name').getValue() .. ' X: ' .. posX .. ' Y: ' .. posY .. ' ++VS++ X: ' .. posSX .. ' Y: ' .. posSY); 
			if posX == posSX and posY == posSY then
				startTokenHeight = getCTEntryHeight(v); 
			elseif posX == posEX and posY == posEY then
				endTokenHeight = getCTEntryHeight(v); 
			end
			-- end prematurely
			if startTokenHeight ~= nil and endTokenHeight ~= nil then
				break;
			end
		end
	end

	if startTokenHeight == nil then
		startTokenHeight = 0;
	end
	if endTokenHeight == nil then
		endTokenHeight = 0;
	end


	return startTokenHeight, endTokenHeight; 
end

-- just get the node
function getCTNodesAt(posSX,posSY,posEX,posEY)
	local startNodeCT = nil; 
	local endNodeCT = nil; 

	if not listCT then
		listCT = DB.findNode('combattracker.list'); 
	end

	local ctEntries = listCT.getChildren(); 

	for k,v in pairs(ctEntries) do
		token = CombatManager.getTokenFromCT(v); 
		if token then
			local posX,posY = token.getPosition()
			--Debug.console('coords of token ' .. v.getChild('name').getValue() .. ' X: ' .. posX .. ' Y: ' .. posY .. ' ++VS++ X: ' .. posSX .. ' Y: ' .. posSY); 
			if posX == posSX and posY == posSY then
				startNodeCT = v; 
			elseif posX == posEX and posY == posEY then
				endNodeCT = v; 
			end
			-- end prematurely
			if startNodeCT ~= nil and endNodeCT ~= nil then
				break;
			end
		end
	end

	return startNodeCT, endNodeCT; 
end

-- get the CT Height entry if it exists
function getCTEntryHeight(ctEntry)
	if ctEntry then
		local heightNode = ctEntry.getChild('height');
		if heightNode then
			return heightNode.getValue(); 
		else
			--Debug.console('no height node!'); 
		end
	end
	return 0; 
end

-- sub in the measurement text for our custom varient for height
function onMeasurePointer(pixellength,pointertype,startx,starty,endx,endy)
	local lock = acquireMeasureSemaphore(); 
	if lock then
		--Debug.console("node of CT " .. tostring(type(DB.findNode('combattracker.list')))); 
		local gridSize = self.getGridSize(); 
		local snapSX,snapSY = snapToGrid(startx,starty); 
		local snapEX,snapEY = snapToGrid(endx,endy); 
		--Debug.console('coords are x:' .. snapSX/gridSize .. ' y: ' .. snapSY/gridSize .. ' to x: ' .. snapEX/gridSize .. ' y: ' .. snapEY/gridSize); 

		--local ctNodeStart,ctNodeEnd = getCTNodesAt(startx,starty,endx,endy,gridSize); 
		local ctNodeStart,ctNodeEnd = getCTNodesAt(startx,starty,endx,endy); 


		local heightDistance = 0; 
		if HeightManager ~= nil then
			local sh = getCTEntryHeight(ctNodeStart);
			local eh = getCTEntryHeight(ctNodeEnd); 
			-- height is stored in 5ft units, we're working in raw units
			heightDistance = math.abs(eh-sh)/5; 
		end

		local lenX = math.floor(math.abs(snapSX - snapEX)/gridSize); 
		local lenY = math.floor(math.abs(snapSY - snapEY)/gridSize); 
		local baseDistance = math.max(lenX,lenY) + math.floor(math.min(lenX,lenY)/2); 
		local distance = baseDistance;

		--local offX,offY = getGridOffset(); 
		--Debug.console('offX: ' .. offX .. ' offY: ' .. offY); 


		--Debug.console('baseDistance: ' .. baseDistance .. ' heightDistance: ' .. heightDistance); 
		if heightDistance > 0 then
			distance = math.sqrt((baseDistance^2)+(heightDistance^2)); 
			distance = math.floor((distance*10)+0.5)/10; 
		end
		releaseMeasureSemaphore(); 		

		--Debug.chat('' .. (distance*5) .. ' ft');
		return ('' .. (distance*5) .. ' ft'); 
		--return ('' .. (distance*5) .. ' ft' .. ' SH: ' .. sh .. ' EH: ' .. eh); 
		--return ('' .. distance .. ' units'); 
		--return ('X: ' .. lenX .. ' Y: ' .. lenY); 
	end
	return ''; 
end
