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
	on Init
]]--
function onInit()
	--Debug.console("HEIGHT MANAGER LOADED"); 
	Token.onWheel = onWheel; 
end

--[[
	Replace the default onWheel token function with our own
]]--
function onWheel(target, notches)
	if Input.isShiftPressed() then
		--Debug.console("Hey shift is down on a token " .. target.getId()); 
		if not hasHeightWidget(target) then
			createHeightWidget(target);	
		else
			if notches > 0 then
				doIncreaseHeight(notches,target);
			else
				doDecreaseHeight(notches,target); 
			end
		end
	elseif Input.isControlPressed() then
		-- spiny spinny!
		target.setOrientation((target.getOrientation()+notches)%8); 
	elseif Input.isAltPressed() then
		local scale = target.getScale();
		scale = scale + notches/10; 
		if scale <= 0.1 then scale = 0.1 end
		target.setScale(scale); 
	end

	return true; 
end

function setupToken(token)
	if not hasHeightWidget(token) then
		createHeightWidget(token); 
	end
end

--[[
	Create the height widget
]]--
function createHeightWidget(token)
	--Debug.console("creating height widget for token: " .. token.getId()); 
	if hasCT(token) then
		height = getCTHeight(token); 
		wdg = token.addTextWidget("height",height .. ' ft'); 
		if wdg then
			if height == 0 then
				wdg.setVisible(false);
			else
				wdg.setVisible(true);
			end
			--Debug.console("widget made" .. token.getId()); 
			wdg.setName("height_text"); 
			wdg.setPosition("right",0,0); 
			wdg.setFrame('tempmodmini',10,10,10,4); 
			wdg.setColor('00000000');
			wdg.bringToFront(); 
			-- make CT height field if it doesn't exist; 
			local ct = hasCT(token);
			if ct then
				local heightNode = ct.createChild("height","number"); 
				if User.isHost() then
					addHolders(token); 
				end
			end
		end
	else
		Debug.console("refusing to create height widget for token: " .. token.getId()); 
	end
end

--[[
	We need to check if the data source is in fact owned by any one individual, if it is, then
	make the 'height' field of the CT entry owned by them as well.

	NOTE: we should in theory also hang on to identity ownership as when the identity shifts, we
	should change the owner of the height node as well to this new identity.
]]--
function addHolders(token)
	local ct = hasCT(token);
	local heightNode,charSheets,owner,iden,cl,cn; 

	if ct then
		heightNode = ct.createChild("height","number"); 
		if heightNode and User.isHost() then
			-- get datasource, try to find the charsheet
			-- if there's a charsheet, then get the list of users
			-- find all identities own by each user, if an identity owned by a user
			-- is equal to the name field on the ct, then make that user a holder
			--Debug.console("CT node: " .. ct.getPath()); 
			if ct.getChild('link').getValue() == 'charsheet'then
				iden = ct.getChild('name').getValue(); 
				--Debug.console("name of identity: " .. iden); 
				
				-- try iterating through char sheets
				charSheets = DB.findNode('charsheet');
				if charSheets then
					cl = charSheets.getChildren();
					for k,v in pairs(cl) do
						cn = v.getChild('name'); 
						if cn then
							cn = cn.getValue();
							--Debug.console("cn is >> " .. cn); 
							if cn == iden then
								--Debug.console("we have a match, time to look for an owner"); 
								owner = v.getOwner(); 
								--Debug.console("Owner is: " .. owner); 
								break; 
							end
						end
					end
					if owner then
						heightNode.addHolder(owner,true); 
					end
				end
			end
		end
	end
end

--[[
	On an identity change we should check all our holders are correct
]]--
function updateHolders(token)
end


--[[
	Increase height
]]--
function doIncreaseHeight(inc,token)
	--Debug.console("increasing height " .. inc .. " for token: " .. token.getId()); 
	local w = hasHeightWidget(token); 
	local height = getCTHeight(token); 
	local txtHeight = ""; 

	height = height+(inc*5); 
	setCTHeight(height,token); 

--[[
	if height == 0 then
		txtHeight = ''; 
		w.setVisible(false);
	else
		txtHeight = height .. txtHeight .. ' ft'; 
		w.setVisible(true);
	end

	w.setText(txtHeight); 
]]--
end

--[[
	Decrease height
]]--
function doDecreaseHeight(inc,token)
	--Debug.console("decreasing height " .. inc .. " for token: " .. token.getId()); 
	local w = hasHeightWidget(token); 
	local height = getCTHeight(token); 
	local txtHeight = ""; 

	height = height+(inc*5); 
	setCTHeight(height,token); 
--[[
	if height == 0 then
		txtHeight = ''; 
		w.setVisible(false);
	else
		txtHeight = height .. txtHeight .. ' ft'; 
		w.setVisible(true);
	end


	w.setText(txtHeight); 
]]--
end

--[[
	Return CT if the token is on the CT else, nil
]]--
function hasCT(token)
	local ct = CombatManager.getCTFromToken(token); 
	return ct; 
end

--[[
	Contrary to the name, this function update the widget display
	given the token
]]--
function updateHeight(token)
	local wdg = hasHeightWidget(token);  
	local ct = hasCT(token); 
	if wdg and ct then
		local height = getCTHeight(token); 	
		local txtHeight = ""; 

		if height == 0 then
			txtHeight = ''; 
			wdg.setVisible(false);
		else
			txtHeight = height .. txtHeight .. ' ft'; 
			wdg.setVisible(true);
		end
		wdg.setText(txtHeight); 
		wdg.bringToFront(); 
	end
end

--[[
	Set our exact height to the given value in the CT
	entry if available, else create one and set the
	height. If not on the CT, nothing
]]--
function setCTHeight(height,token)
	local ct = CombatManager.getCTFromToken(token); 

	if ct then
		heightNode = ct.createChild("height","number"); 
			if heightNode then
			--Debug.console("setHeight... owner is: " .. tostring(heightNode.getOwner())); 
			if heightNode then
				heightNode.setValue(height); 
				--Debug.console('height configured as ' .. height .. ' ready only? ' .. tostring(heightNode.isReadOnly())); 
			else
				--Debug.console("can't set height as: " .. height); 
			end
		end
	end

end


--[[
	Get the height value from the CT entry if available, else
	create one, and set the height to 0, and return 0. If not
	on the CT, nothing
]]--
function getCTHeight(token)
	local ct = CombatManager.getCTFromToken(token); 

	if ct then
		--Debug.console(ct.getPath()); 
		heightNode = ct.createChild("height","number"); 
		if heightNode then
			local height = tonumber(heightNode.getValue()); 
			--Debug.console('height is ' .. height); 
			return height; 
		else
			--Debug.console("can't get height"); 
		end
	end

	return 0; 
end

--[[
	Return the height widget if the token has it, else nil,
	dual purpose!
]]--
function hasHeightWidget(token)
	local w; 
	if token then
		w = token.findWidget("height_text"); 
		--Debug.console(tostring(w)); 
	end

	return w; 
end


