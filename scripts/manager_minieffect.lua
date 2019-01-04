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



local lastContextToken; 
local effectMode = 'context'; 

function onInit()

end

function setupMenuItems(token)
	token.registerMenuItem('Effects','effect_radial',4); 
	token.onMenuSelection = onMenuSelection; 
end

-- popup our window
function onMenuSelection(target, ...)
	local topSelection = arg[1]; 
	--Debug.console("selected an item! " .. tostring(topSelection)); 
	if topSelection == 4 then
		wnd = Interface.findWindow('minieffects','effects');
		if wnd then
			--Debug.console("last: " .. tostring(lastContextToken) .. ' current: ' .. tostring(target)); 
			if lastContextToken.getId() ~= target.getId() then
				local cPosX,cPosY = Input.getMousePosition(); 
				local sW,sL = wnd.getSize(); 
				local posX = math.floor(cPosX-sW/2);
				local posY = math.floor(cPosY-sL/2); 
				wnd.setPosition(posX,posY); 
				lastContextToken = target; 
			else
				wnd.close(); 
			end
			--wnd.setPosition(Input.getMousePosition()); 
			--wnd.bringToFront(); 
			--local sL,sW = wnd.getSize(); 
			--wnd.close(); 
			--Debug.console('wnd size l: ' .. sL .. ' w: ' .. sW)
			return true; 
		else
			wnd = Interface.openWindow('minieffects','effects'); 
			if wnd then
				local cPosX,cPosY = Input.getMousePosition(); 
				local sW,sL = wnd.getSize(); 
				local posX = math.floor(cPosX-sW/2);
				local posY = math.floor(cPosY-sL/2); 
				wnd.setPosition(posX,posY); 
				lastContextToken = target; 
				setMode('context'); 
				--Debug.console('wnd size l: ' .. sL .. ' w: ' .. sW)
				return true; 
			end
		end
	end
end

-- return the last context token
function getLastContextToken()
	return lastContextToken; 
end

--[[
	Confirm that the lastContextToken reference is active
]]--
function isContextTokenValid()
	-- check reference
	local err, errmsg; 
	err, errmsg = pcall(TokenManager.checkTokenInstance,lastContextToken); 
	if (not err) then
		Debug.console('Warning: checkContextToken, context token is unavailable: ' .. tostring(errmsg)); 
		lastContextToken = nil;
		return false; 
	end
	return true; 
end

--[[ 
	set the mode we want to apply our effects, we just hold on to this
	info, the effect appliers will make use of it
]]--
function setMode(strMode)
	if strMode == 'targeted' then
		effectMode = 'targeted';
	elseif strMode == 'selected' then
		effectMode = 'selected'; 
	else
		effectMode = 'context'; 
	end
end

--[[
	get the mode, effet appliers use this
]]--
function getMode()
	return effectMode; 
end

