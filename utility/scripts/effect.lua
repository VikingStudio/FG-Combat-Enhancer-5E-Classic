--[[
	'Fantasy Grounds' is a trademark of SmiteWorks USA, LLC. 'Fantasy Grounds' is Copyright 2004-2014 SmiteWorks USA LLC.
	The CoreRPG ruleset and all included files are copyright 2004-2013, Smiteworks USA LLC.
]]--

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

function checkData()
	if label.getValue() ~= DB.getValue(getDatabaseNode(), "label", "") then
		label.setValue(label.getValue());
	end
end

function actionDrag(draginfo)
	checkData();
	local rEffect = EffectManager.getEffect(getDatabaseNode());
	return ActionEffect.performRoll(draginfo, nil, rEffect);
end

function action()
	checkData();
	local rEffect = EffectManager.getEffect(getDatabaseNode());
	local rRoll = ActionEffect.getRoll(nil, nil, rEffect);
	if not rRoll then
		return true;
	end
	
	rRoll.sType = "effect";

	local rTarget = nil;
	if User.isHost() then
		applyEffectOnOpenImageWindows(rRoll); 
	else
		local iden = User.getCurrentIdentity();
		if iden then
			rTarget = ActorManager.getActor("pc", CombatManager.getCTFromNode("charsheet." .. User.getCurrentIdentity()));
			ActionsManager.resolveAction(nil, rTarget, rRoll);
			--applyEffectOnOpenImageWindows(rRoll,rEffect); 
		else
			Comm.addChatMessage({text="Select an identity first before attempting to apply an effect to yourself!",secret=true}); 
		end
	end
	
	return true;
end

function onGainFocus()
	window.setFrame("rowshade");
end

function onLoseFocus()
	window.setFrame(nil);
end


function applyEffectOnOpenImageWindows(rRoll,rEffect)
	local imgWnds = DB.findNode('image');
	local wnd; 
	--Debug.console(tostring(imgWnds)); 

	if imgWnds then
		imgWnds = imgWnds.getChildren(); 
		--Debug.console(tostring(imgWnds)); 
		for k,v in pairs(imgWnds) do
			--Debug.console(tostring(v.getPath()));
			wnd = getOpenImgWindow(v); 
			if wnd then
				--Debug.console('window ' .. v.getPath() .. ' is open!'); 
				local tokens = getSelectedTokens(wnd); 
				local tokenCTs = getTokenCTs(tokens); 
				local rTarget; 
				for k,v in pairs(tokenCTs) do
					rTarget = ActorManager.getActorFromCT(v); 	
					ActionsManager.resolveAction(nil,rTarget,rRoll); 
					--Debug.console("using EA rather than RA!'"); 
					--EffectManager.addEffect(sUser,nil,v,rEffect,true); 
				end
			end
		end
	end
end

function getTokenCTs(tokens)
	local retval = {};
	local tokenCT; 
	for k,v in pairs(tokens) do
		tokenCT = CombatManager.getCTFromToken(v); 
		if tokenCT then
			table.insert(retval,tokenCT); 
		end
	end
	--Debug.console("we found " .. #retval .. " connected CT Tokens"); 
	return retval; 
end

function getSelectedTokens(imgWindow)
	local retval = {};
	local controls = imgWindow.getControls(); 

	if #controls > 0 then
		local imgCtls = {}; 
		for k,v in pairs(controls) do
			local ctlName = v.getName(); 
			if ctlName == "play_image"
			or ctlName == "features_image"
			or ctlName == "image" then
				table.insert(imgCtls,v); 
			end
		end

		for k,v in pairs(imgCtls) do
			imgTokens = v.getSelectedTokens();
			for k2,v2 in pairs(imgTokens) do
				table.insert(retval,v2); 
			end
		end
	end
	
	--Debug.console("we found " .. #retval .. " selected tokens"); 
	return retval; 
end

function getOpenImgWindow(imgDbNode)
	local retval = nil;
	retval = Interface.findWindow("imagewindow",imgDbNode); 
	return retval; 
end

