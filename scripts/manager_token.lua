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

local nTokenDragUnits = nil;

local bDisplayDefaultHealth = false;
local fGetHealthInfo = null;
local bDisplayDefaultEffects = false;
local fGetEffectInfo = null;

function onInit()
	if User.isHost() then
		Token.onContainerChanged = onContainerChanged;
		Token.onTargetUpdate = onTargetUpdate;

		DB.addHandler("options.TFAC", "onUpdate", onOptionChanged);

		CombatManager.setCustomDeleteCombatantHandler(onCombatantDelete);
		CombatManager.addCombatantFieldChangeHandler("active", "onUpdate", updateActive);
		CombatManager.addCombatantFieldChangeHandler("space", "onUpdate", updateSpaceReach);
		CombatManager.addCombatantFieldChangeHandler("reach", "onUpdate", updateSpaceReach);
	else
		DB.addHandler("charsheet.*", "onDelete", deleteOwner);
		DB.addHandler("charsheet.*", "onObserverUpdate", updateOwner);
	end

	Token.onAdd = onTokenAdd;
	Token.onDelete = onTokenDelete;
	Token.onDrop = onDrop;
	Token.onScaleChanged = onScaleChanged;
	Token.onHover = onHover;
	Token.onDoubleClick = onDoubleClick;

	-- we rely on manual invocation in ct_token, image.lua and ct_entry to prevent recursive linkToken
	--CombatManager.addCombatantFieldChangeHandler("tokenrefid", "onUpdate", updateAttributes);
	CombatManager.addCombatantFieldChangeHandler("friendfoe", "onUpdate", updateFaction);
	CombatManager.addCombatantFieldChangeHandler("name", "onUpdate", updateName);
	CombatManager.addCombatantFieldChangeHandler("nonid_name", "onUpdate", updateName);
	CombatManager.addCombatantFieldChangeHandler("isidentified", "onUpdate", updateName);
	
	DB.addHandler("options.TNAM", "onUpdate", onOptionChanged);	
end

function linkToken(nodeCT, newTokenInstance)
	local nodeContainer = nil;
	if newTokenInstance then
		nodeContainer = newTokenInstance.getContainerNode();
	end
	
	if nodeContainer then
		DB.setValue(nodeCT, "tokenrefnode", "string", nodeContainer.getNodeName());
		DB.setValue(nodeCT, "tokenrefid", "string", newTokenInstance.getId());
	else
		DB.setValue(nodeCT, "tokenrefnode", "string", "");
		DB.setValue(nodeCT, "tokenrefid", "string", "");
	end

	return true;
end

--[[
	Check the token reference if it's still valid.
]]--
function checkTokenInstance(newTokenInstance)
	local a = newTokenInstance.getId(); 
	local b = newTokenInstance.getScale(); 
end

function onOptionChanged(nodeOption)
	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			updateAttributesHelper(tokenCT, nodeCT);
		end
	end
end

function onCombatantDelete(nodeCT)
	if TokenManager2 and TokenManager2.onCombatantDelete then
		if TokenManager2.onCombatantDelete(nodeCT) then
			return;
		end
	end
	
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
		if sClass ~= "charsheet" then
			tokenCT.delete();
		else
			local aWidgets = getWidgetList(tokenCT);
			for _, vWidget in pairs(aWidgets) do
				vWidget.destroy();
			end

			tokenCT.setActivable(true);
			tokenCT.setActive(false);
			tokenCT.setActivable(false);
			tokenCT.setTargetsVisible(false);
			tokenCT.setModifiable(true);
			tokenCT.setVisible(nil);

			tokenCT.setName();
			tokenCT.setGridSize(0);
			tokenCT.removeAllUnderlays();
		end
	end
end

function onTokenAdd(tokenMap)
	ImageManager.onTokenAdd(tokenMap);
end

function onTokenDelete(tokenMap)
	ImageManager.onTokenDelete(tokenMap);

	if User.isHost() then
		CombatManager.onTokenDelete(tokenMap);
		PartyManager.onTokenDelete(tokenMap);
	end
end

function onContainerChanged(tokenCT, nodeOldContainer, nOldId)
	if nodeOldContainer then
		local nodeCT = CombatManager.getCTFromTokenRef(nodeOldContainer, nOldId);
		if nodeCT then
			local nodeNewContainer = tokenCT.getContainerNode();
			if nodeNewContainer then
				DB.setValue(nodeCT, "tokenrefnode", "string", nodeNewContainer.getNodeName());
				DB.setValue(nodeCT, "tokenrefid", "string", tokenCT.getId());
			else
				DB.setValue(nodeCT, "tokenrefnode", "string", "");
				DB.setValue(nodeCT, "tokenrefid", "string", "");
			end
		end
	end
	local nodePS = PartyManager.getNodeFromTokenRef(nodeOldContainer, nOldId);
	if nodePS then
		local nodeNewContainer = tokenCT.getContainerNode();
		if nodeNewContainer then
			DB.setValue(nodePS, "tokenrefnode", "string", nodeNewContainer.getNodeName());
			DB.setValue(nodePS, "tokenrefid", "string", tokenCT.getId());
		else
			DB.setValue(nodePS, "tokenrefnode", "string", "");
			DB.setValue(nodePS, "tokenrefid", "string", "");
		end
	end
end
function onScaleChanged(tokenCT)
	local nodeCT = CombatManager.getCTFromToken(tokenCT);

	if nodeCT then
		updateNameScale(tokenCT);
		if bDisplayDefaultHealth then 
			local nPercentWounded = fGetHealthInfo(nodeCT);
			updateHealthBarScale(tokenCT, nPercentWounded); 
		end
		if bDisplayDefaultEffects then
			updateEffectsHelper(tokenCT, nodeCT);
		end
		if TokenManager2 and TokenManager2.onScaleChanged then
			TokenManager2.onScaleChanged(tokenCT, nodeCT);
		end
	end
end
function onTargetUpdate(tokenMap)
	TargetingManager.onTargetUpdate(tokenMap);
end

function onWheelHelper(tokenCT, notches)
	if not tokenCT then
		return;
	end
	
	if Input.isShiftPressed() then
		newscale = math.floor(tokenCT.getScale() + notches);
		if newscale < 1 then
			newscale = 1;
		end
	else
		newscale = tokenCT.getScale() + (notches * 0.1);
		if newscale < 0.1 then
			newscale = 0.1;
		end
	end
	
	tokenCT.setScale(newscale);
end

function onWheelCT(nodeCT, notches)
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		onWheelHelper(tokenCT, notches);
	end
end

function onDrop(tokenCT, draginfo)
	local nodeCT = CombatManager.getCTFromToken(tokenCT);
	if nodeCT then
		return CombatManager.onDrop("ct", nodeCT.getNodeName(), draginfo);
	else
		if draginfo.getType() == "targeting" then
			ChatManager.SystemMessage(Interface.getString("ct_error_targetingunlinkedtoken"));
			return true; 
		end
	end
end

function onHover(tokenMap, bOver)
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if nodeCT then
		if OptionsManager.isOption("TNAM", "hover") then
			for _, vWidget in pairs(getWidgetList(tokenMap, "name")) do
				vWidget.setVisible(bOver);
			end
		end
		if bDisplayDefaultHealth then
			local sOption;
			if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
				sOption = OptionsManager.getOption("TPCH");
			else
				sOption = OptionsManager.getOption("TNPCH");
			end
			if (sOption == "barhover") or (sOption == "dothover") then
				for _, vWidget in pairs(getWidgetList(tokenMap, "health")) do
					vWidget.setVisible(bOver);
				end
			end
		end
		if bDisplayDefaultEffects then
			local sOption;
			if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
				sOption = OptionsManager.getOption("TPCE");
			else
				sOption = OptionsManager.getOption("TNPCE");
			end
			if (sOption == "hover") or (sOption == "markhover") then
				for _, vWidget in pairs(getWidgetList(tokenMap, "effect")) do
					vWidget.setVisible(bOver);
				end
			end
		end
		
		if User.isHost() then
			hilightHover(tokenMap, bOver); 
		end
		
		if TokenManager2 and TokenManager2.onHover then
			TokenManager2.onHover(tokenMap, nodeCT, bOver);
		end
	end
end

function hilightHover(tokenMap, bOver)
	local nodeActiveCT = CombatManager.getActiveCT();
	local nodeCT = CombatManager.getCTFromToken(tokenMap); 
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);

	if bOver and tokenCT then
		-- add blue underlay if not active
		if nodeActiveCT and nodeActiveCT.getNodeName() ~= nodeCT.getNodeName() then
			tokenCT.removeAllUnderlays(); 
			local space = nodeCT.getChild('space');  
			if space == nil then 
				space = 1;
			else
				space = space.getValue()/5/2+0.5; 
			end
			tokenCT.addUnderlay(space, Modifications.TOKENUNDERLAYCOLOR_3);
		end

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
				tokenCT.addUnderlay(space, Modifications.TOKENUNDERLAYCOLOR_1); 
			end
		end
	end

end

function onDoubleClick(tokenMap, vImage)
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if Input.isShiftPressed() then
		if nodeCT then
			if User.isHost() then
				local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
				if sRecord ~= "" then
					Interface.openWindow(sClass, sRecord);
				else
					Interface.openWindow(sClass, nodeCT);
				end
			else
				if (DB.getValue(nodeCT, "friendfoe", "") == "friend") then
					local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
					if sClass == "charsheet" then
						if sRecord ~= "" and DB.isOwner(sRecord) then
							Interface.openWindow(sClass, sRecord);
						else
							ChatManager.SystemMessage(Interface.getString("ct_error_openpclinkedtokenwithoutaccess"));
						end
					else
						local nodeActor;
						if sRecord ~= "" then
							nodeActor = DB.findNode(sRecord);
						else
							nodeActor = nodeCT;
						end
						if nodeActor then
							Interface.openWindow(sClass, nodeActor);
						else
							ChatManager.SystemMessage(Interface.getString("ct_error_openotherlinkedtokenwithoutaccess"));
						end
					end
					vImage.clearSelectedTokens();
				end
			end
		end
	end
	return true; 
end

function updateAttributesFromToken(tokenMap)
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if nodeCT then
		updateAttributesHelper(tokenMap, nodeCT);
	end
	
	if User.isHost() then
		local nodePS = PartyManager.getNodeFromToken(tokenMap);
		if nodePS then
			tokenMap.setTargetable(false);
			tokenMap.setActivable(true);
			tokenMap.setActive(false);
			tokenMap.setVisible(true);
			
			tokenMap.setName(DB.getValue(nodePS, "name", ""));
		end
	end
end

function updateAttributes(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		updateAttributesHelper(tokenCT, nodeCT);
	end
end

function updateAttributesHelper(tokenCT, nodeCT)
	if User.isHost() then
		tokenCT.setTargetable(true);
		tokenCT.setActivable(true);
		
		if OptionsManager.isOption("TFAC", "on") then
			tokenCT.setOrientationMode("facing");
		else
			tokenCT.setOrientationMode();
		end
		
		updateActiveHelper(tokenCT, nodeCT);
		updateFactionHelper(tokenCT, nodeCT);
		updateSizeHelper(tokenCT, nodeCT);
	else
		updateOwnerHelper(tokenCT, nodeCT);
	end
	
	updateNameHelper(tokenCT, nodeCT);
	updateTooltip(tokenCT, nodeCT);
	if bDisplayDefaultHealth then 
		updateHealthHelper(tokenCT, nodeCT); 
	end
	if bDisplayDefaultEffects then
		updateEffectsHelper(tokenCT, nodeCT);
	end
	if TokenManager2 and TokenManager2.updateAttributesHelper then
		TokenManager2.updateAttributesHelper(tokenCT, nodeCT);
	end
end

function updateTooltip(tokenCT, nodeCT)
	if TokenManager2 and TokenManager2.updateTooltip then
		TokenManager2.updateTooltip(tokenCT, nodeCT);
		return;
	end
	
	if User.isHost() then
		local aTooltip = {};
		local sFaction = DB.getValue(nodeCT, "friendfoe", "");
		
		local sOptTNAM = OptionsManager.getOption("TNAM");
		if sOptTNAM == "tooltip" then
			local sName = ActorManager.getDisplayName(nodeCT);
			table.insert(aTooltip, sName);
		end
		if bDisplayDefaultHealth then 
			local sOptTH;
			if sFaction == "friend" then
				sOptTH = OptionsManager.getOption("TPCH");
			else
				sOptTH = OptionsManager.getOption("TNPCH");
			end
			if sOptTH == "tooltip" then
				local _,sStatus,_ = fGetHealthInfo(nodeCT);
				table.insert(aTooltip, sStatus);
			end
		end
		if bDisplayDefaultEffects then
			local sOptTE;
			if sFaction == "friend" then
				sOptTE = OptionsManager.getOption("TPCE");
			else
				sOptTE = OptionsManager.getOption("TNPCE");
			end
			if sOptTE == "tooltip" then
				local aCondList = fGetEffectInfo(nodeCT, true);
				for _,v in ipairs(aCondList) do
					table.insert(aTooltip, v.sEffect);
				end
			end
		end
		
		tokenCT.setName(table.concat(aTooltip, "\r"));
	end
end

function updateName(nodeName)
	local nodeCT = nodeName.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		updateNameHelper(tokenCT, nodeCT);
		updateTooltip(tokenCT, nodeCT);
	end
end

function updateNameHelper(tokenCT, nodeCT)
	local sOptTNAM = OptionsManager.getOption("TNAM");
	
	local sName = ActorManager.getDisplayName(nodeCT);
	local aWidgets = getWidgetList(tokenCT, "name");
	
	if sOptTNAM == "off" or sOptTNAM == "tooltip" then
		for _, vWidget in pairs(aWidgets) do
			vWidget.destroy();
		end
	else
		local w, h = tokenCT.getSize();
		if w > 10 then
			local nStarts, _, sNumber = string.find(sName, " ?(%d+)$");
			if nStarts then
				sName = string.sub(sName, 1, nStarts - 1);
			end
			local bWidgetsVisible = (sOptTNAM == "on");

			local widgetName = aWidgets["name"];
			if not widgetName then
				widgetName = tokenCT.addTextWidget("mini_name", "");
				widgetName.setPosition("top", 0, -2);
				widgetName.setFrame("mini_name", 5, 1, 5, 1);
				widgetName.setName("name");
			end
			if widgetName then
				widgetName.setVisible(bWidgetsVisible);
				widgetName.setText(sName);
				widgetName.setTooltipText(sName);
			end
			updateNameScale(tokenCT);

			if sNumber then
				local widgetOrdinal = aWidgets["ordinal"];
				if not widgetOrdinal then
					widgetOrdinal = tokenCT.addTextWidget("sheetlabel", "");
					widgetOrdinal.setPosition("topright", -4, -2);
					widgetOrdinal.setFrame("tokennumber", 7, 1, 7, 1);
					widgetOrdinal.setName("ordinal");
				end
				if widgetOrdinal then
					widgetOrdinal.setVisible(bWidgetsVisible);
					widgetOrdinal.setText(sNumber);
				end
			else
				if aWidgets["ordinal"] then
					aWidgets["ordinal"].destroy();
				end
			end
		end
	end
end

function updateNameScale(tokenCT)
	local widgetName = tokenCT.findWidget("name");
	if widgetName then
		local w, h = tokenCT.getSize();
		if w > 10 then
			widgetName.setMaxWidth(w - 10);
		else
			widgetName.setMaxWidth(0);
		end
	end
end

function updateVisibility(nodeCT)
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		updateVisibilityHelper(tokenCT, nodeCT);
	end
	
	if DB.getValue(nodeCT, "tokenvis", 0) == 0 then
		TargetingManager.removeCTTargeted(nodeCT);
	end
end

function updateVisibilityHelper(tokenCT, nodeCT)
	if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		tokenCT.setVisible(true);
	else
		if DB.getValue(nodeCT, "tokenvis", 0) == 1 then
			if tokenCT.isVisible() ~= true then
				tokenCT.setVisible(nil);
			end
		else
			tokenCT.setVisible(false);
		end
	end
end

function deleteOwner(nodePC)
	local nodeCT = CombatManager.getCTFromNode(nodePC);
	if nodeCT then
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			tokenCT.setTargetsVisible(false);
		end
	end
end

function updateOwner(nodePC)
	local nodeCT = CombatManager.getCTFromNode(nodePC);
	if nodeCT then
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			updateOwnerHelper(tokenCT, nodeCT);
		end
	end
end

function updateOwnerHelper(tokenCT, nodeCT)
	if not User.isHost() then
		local bOwned = false;
		
		local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
		if DB.isOwner(sRecord) then
			bOwned = true;
		end

		tokenCT.setTargetsVisible(bOwned);
	end
end

function updateActive(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		updateActiveHelper(tokenCT, nodeCT);
	end
end

function updateActiveHelper(tokenCT, nodeCT)
	if User.isHost() then
		if tokenCT.isActivable() then
			local bActive = (DB.getValue(nodeCT, "active", 0) == 1);
			if bActive then
				tokenCT.setActive(true);
			else
				tokenCT.setActive(false);
			end
		end
	end
end

function updateFaction(nodeFaction)
	local nodeCT = nodeFaction.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		if User.isHost() then
			updateFactionHelper(tokenCT, nodeCT);
		end
		updateTooltip(tokenCT, nodeCT);
		if bDisplayDefaultHealth then 
			updateHealthHelper(tokenCT, nodeCT); 
		end
		if bDisplayDefaultEffects then
			updateEffectsHelper(tokenCT, nodeCT);
		end
		if TokenManager2 and TokenManager2.updateFaction then
			TokenManager2.updateFaction(tokenCT, nodeCT);
		end
	end
end

function updateFactionHelper(tokenCT, nodeCT)
	if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		tokenCT.setModifiable(true);
	else
		tokenCT.setModifiable(false);
	end

	updateVisibilityHelper(tokenCT, nodeCT);
	updateSizeHelper(tokenCT, nodeCT);
end

function updateSpaceReach(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		updateSizeHelper(tokenCT, nodeCT);
	end
end

function updateSizeHelper(tokenCT, nodeCT)
	local nDU = GameSystem.getDistanceUnitsPerGrid();
	
	local nSpace = math.ceil(DB.getValue(nodeCT, "space", nDU) / nDU);
	local nHalfSpace = nSpace / 2;
	local nReach = math.ceil(DB.getValue(nodeCT, "reach", nDU) / nDU) + nHalfSpace;

	-- Clear underlays
	tokenCT.removeAllUnderlays();

	-- Reach underlay
	--[[
	local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
	if sClass == "charsheet" then
		tokenCT.addUnderlay(nReach, "4f000000", "hover");
	else
		tokenCT.addUnderlay(nReach, "4f000000", "hover,gmonly");
	end
	]]--

	-- Faction/space underlay
	--[[
	local sFaction = DB.getValue(nodeCT, "friendfoe", "");
	if sFaction == "friend" then
		tokenCT.addUnderlay(nHalfSpace, "2f00ff00");
	elseif sFaction == "foe" then
		tokenCT.addUnderlay(nHalfSpace, "2fff0000");
	elseif sFaction == "neutral" then
		tokenCT.addUnderlay(nHalfSpace, "2fffff00");
	end
	]]--
	
	-- Set grid spacing
	tokenCT.setGridSize(nSpace);
end

local aWidgetSets = { ["name"] = { "name", "ordinal" } };
function registerWidgetSet(sKey, aSet)
	aWidgetSets[sKey] = aSet;
end
function getWidgetList(tokenCT, sSet)
	local aWidgets = {};

	if (sSet or "") == "" then
		for _,aSet in pairs(aWidgetSets) do
			for _,sWidget in pairs(aSet) do
				local w = tokenCT.findWidget(sWidget);
				if w then
					aWidgets[sWidget] = w;
				end
			end
		end
	else
		if aWidgetSets[sSet] then
			for _,sWidget in pairs(aWidgetSets[sSet]) do
				local w = tokenCT.findWidget(sWidget);
				if w then
					aWidgets[sWidget] = w;
				end
			end
		end
	end
	
	return aWidgets;
end

function setDragTokenUnits(nUnits)
	nTokenDragUnits = nUnits;
end

function endDragTokenWithUnits()
	nTokenDragUnits = nil;
end

function getTokenSpace(tokenMap)
	local nSpace = 1;
	if nTokenDragUnits then
		local nDU = GameSystem.getDistanceUnitsPerGrid();
		nSpace = math.max(math.ceil(nTokenDragUnits / nDU), 1);
	else
		local nodeCT = CombatManager.getCTFromToken(tokenMap);
		if nodeCT then
			nSpace = DB.getValue(nodeCT, "space", 1);
			local nDU = GameSystem.getDistanceUnitsPerGrid();
			nSpace = math.max(math.ceil(nSpace / nDU), 1);
		end
	end
	return nSpace;
end

function autoTokenScale(tokenMap)
	if tokenMap.getScale() ~= 1 then
		return;
	end
	
	local w, h = tokenMap.getImageSize();
	if w <= 0 or h <= 0 then
		return;
	end
	
	local aImage = tokenMap.getContainerNode().getValue();
	if not aImage or not aImage.gridsize or (aImage.gridsize <= 0) then
		return;
	end

	local nSpace = getTokenSpace(tokenMap);
	local nSpacePixels = nSpace * aImage.gridsize;
	local sOptTASG = OptionsManager.getOption("TASG");
	if sOptTASG == "80" then
		nSpacePixels = nSpacePixels * 0.8;
	end

	if aImage.tokenscale then
		local fNewScale = math.min((nSpacePixels * aImage.tokenscale) / w, (nSpacePixels * aImage.tokenscale) / h);
		if fNewScale < 0.9 or fNewScale > 1.1 then
			tokenMap.setScale(fNewScale);
		end
	elseif nSpacePixels > 0 then
		local fNewScale = math.min(w / nSpacePixels, h / nSpacePixels);
		tokenMap.setContainerScale(fNewScale);
	end
end

--
-- Common token manager add-on health bar/dot functionality
--
-- Callback assumed input of:
--		* nodeCT
-- Assume callback function provided returns 3 parameters
--		* percent wounded (number), 
--		* status text (string), 
--		* status color (string, hex color)
--

local TOKEN_HEALTH_MINBAR = 14;
function addDefaultHealthFeatures(f, aHealthFields)
	if not f then return; end
	bDisplayDefaultHealth = true;
	fGetHealthInfo = f;
	registerWidgetSet("health", {"healthbar", "healthdot"});

	for _,sField in ipairs(aHealthFields) do
		CombatManager.addCombatantFieldChangeHandler(sField, "onUpdate", updateHealth);
	end

	OptionsManager.registerOption2("TNPCH", false, "option_header_token", "option_label_TNPCH", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "tooltip|bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });
	OptionsManager.registerOption2("TPCH", false, "option_header_token", "option_label_TPCH", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "tooltip|bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });
	OptionsManager.registerOption2("WNDC", false, "option_header_combat", "option_label_WNDC", "option_entry_cycler", 
			{ labels = "option_val_detailed", values = "detailed", baselabel = "option_val_simple", baseval = "off", default = "off" });
	DB.addHandler("options.TNPCH", "onUpdate", onOptionChanged);
	DB.addHandler("options.TPCH", "onUpdate", onOptionChanged);
	DB.addHandler("options.WNDC", "onUpdate", onOptionChanged);
end
function updateHealth(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		updateHealthHelper(tokenCT, nodeCT);
		updateTooltip(tokenCT, nodeCT);
	end
end
function updateHealthHelper(tokenCT, nodeCT)
	local sOptTH;
	if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		sOptTH = OptionsManager.getOption("TPCH");
	else
		sOptTH = OptionsManager.getOption("TNPCH");
	end
	local aWidgets = getWidgetList(tokenCT, "health");

	if sOptTH == "off" or sOptTH == "tooltip" then
		for _,vWidget in pairs(aWidgets) do
			vWidget.destroy();
		end
	else
		local nPercentWounded,sStatus,sColor = fGetHealthInfo(nodeCT);
		
		if sOptTH == "bar" or sOptTH == "barhover" then
			local w, h = tokenCT.getSize();
		
			if h >= TOKEN_HEALTH_MINBAR then
				local widgetHealthBar = aWidgets["healthbar"];
				if not widgetHealthBar then
					widgetHealthBar = tokenCT.addBitmapWidget("healthbar");
					widgetHealthBar.sendToBack();
					widgetHealthBar.setName("healthbar");
				end
				if widgetHealthBar then
					widgetHealthBar.setColor(sColor);
					widgetHealthBar.setTooltipText(sStatus);
					widgetHealthBar.setVisible(sOptTH == "bar");
				end
			end
			updateHealthBarScale(tokenCT, nPercentWounded);
			
			if aWidgets["healthdot"] then
				aWidgets["healthdot"].destroy();
			end
		elseif sOptTH == "dot" or sOptTH == "dothover" then
			local widgetHealthDot = aWidgets["healthdot"];
			if not widgetHealthDot then
				widgetHealthDot = tokenCT.addBitmapWidget("healthdot");
				widgetHealthDot.setPosition("bottomright", -4, -6);
				widgetHealthDot.setName("healthdot");
			end
			if widgetHealthDot then
				widgetHealthDot.setColor(sColor);
				widgetHealthDot.setTooltipText(sStatus);
				widgetHealthDot.setVisible(sOptTH == "dot");
			end

			if aWidgets["healthbar"] then
				aWidgets["healthbar"].destroy();
			end
		end
	end
end
function updateHealthBarScale(tokenCT, nPercentWounded)
	local widgetHealthBar = tokenCT.findWidget("healthbar");
	if widgetHealthBar then
		local w, h = tokenCT.getSize();
		h = h + 4;

		widgetHealthBar.setSize();
		local barw, barh = widgetHealthBar.getSize();
		
		-- Resize bar to match health percentage, but preserve bulb portion of bar graphic
		if h >= TOKEN_HEALTH_MINBAR then
			barh = (math.max(1.0 - nPercentWounded, 0) * (math.min(h, barh) - TOKEN_HEALTH_MINBAR)) + TOKEN_HEALTH_MINBAR;
		else
			barh = TOKEN_HEALTH_MINBAR;
		end

		--[[ original 
		widgetHealthBar.setSize(barw, barh, "bottom");
		widgetHealthBar.setPosition("bottomright", -4, -(barh / 2) + 4);
		--]]

		-- Health bar made wider, taller and pushed to the right.
		Debug.chat('updateHealthBarScale run');
		barw = barw + 20;
		widgetHealthBar.setSize(barw, barh, "bottom");
		widgetHealthBar.setPosition("bottomright", -20, -(barh / 2) + 4);		
	end
end

--
-- Common token manager add-on effect functionality
--
-- Callback assumed input of: 
--		* nodeCT
--		* bSkipGMOnlyEffects
-- Callback assumed output of: 
--		* integer-based array of tables with following format
-- 			{ 
--				sName = "<Effect name to display>", (Currently, as effect icon tooltips when each displayed)
--				sIcon = "<Effect icon asset to display on token>",
--				sEffect = "<Original effect string>" (Currently used for large tooltips (multiple effects))
--			}
--

local TOKEN_MAX_EFFECTS = 6;
local TOKEN_EFFECT_WIDTH = 12;
local TOKEN_EFFECT_MARGIN = 2;
local TOKEN_EFFECT_OFFSETX = 6;
local TOKEN_EFFECT_OFFSETMAXX = 20;
local TOKEN_EFFECT_OFFSETY = 6;
function addDefaultEffectFeatures(f)
	bDisplayDefaultEffects = true;
	fGetEffectInfo = f;
	local aEffectSet = {}; for i = 1, TOKEN_MAX_EFFECTS do table.insert(aEffectSet, "effect" .. i); end
	registerWidgetSet("effect", aEffectSet);

	CombatManager.setCustomAddCombatantEffectHandler(updateEffects);
	CombatManager.setCustomDeleteCombatantEffectHandler(updateEffects);
	CombatManager.addCombatantEffectFieldChangeHandler("isactive", "onAdd", updateEffectsField);
	CombatManager.addCombatantEffectFieldChangeHandler("isactive", "onUpdate", updateEffectsField);
	CombatManager.addCombatantEffectFieldChangeHandler("isgmonly", "onAdd", updateEffectsField);
	CombatManager.addCombatantEffectFieldChangeHandler("isgmonly", "onUpdate", updateEffectsField);
	CombatManager.addCombatantEffectFieldChangeHandler("label", "onAdd", updateEffectsField);
	CombatManager.addCombatantEffectFieldChangeHandler("label", "onUpdate", updateEffectsField);

	OptionsManager.registerOption2("TNPCE", false, "option_header_token", "option_label_TNPCE", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "tooltip|on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("TPCE", false, "option_header_token", "option_label_TPCE", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "tooltip|on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });
	DB.addHandler("options.TNPCE", "onUpdate", onOptionChanged);
	DB.addHandler("options.TPCE", "onUpdate", onOptionChanged);
end
function updateEffectsField(nodeEffectField)
	updateEffects(nodeEffectField.getChild("...."));
end
function updateEffects(nodeCT)
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		updateEffectsHelper(tokenCT, nodeCT);
		updateTooltip(tokenCT, nodeCT);
	end
end
function updateEffectsHelper(tokenCT, nodeCT)
	local sOptTE;
	if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		sOptTE = OptionsManager.getOption("TPCE");
	else
		sOptTE = OptionsManager.getOption("TNPCE");
	end

	local aWidgets = getWidgetList(tokenCT, "effect");
	
	if sOptTE == "off" or sOptTE == "tooltip" then
		for _, vWidget in pairs(aWidgets) do
			vWidget.destroy();
		end
	elseif sOptTE == "mark" or sOptTE == "markhover" then
		local bWidgetsVisible = (sOptTE == "mark");
		
		local aTooltip = {};
		local aCondList = fGetEffectInfo(nodeCT);
		for _,v in ipairs(aCondList) do
			table.insert(aTooltip, v.sEffect);
		end
		
		if #aTooltip > 0 then
			local w = aWidgets["effect1"];
			if not w then
				w = tokenCT.addBitmapWidget();
				w.setPosition("bottomleft", TOKEN_EFFECT_OFFSETX, -TOKEN_EFFECT_OFFSETY);
				w.setName("effect1");
			end
			if w then
				w.setBitmap("cond_generic");
				w.setVisible(bWidgetsVisible);
				w.setTooltipText(table.concat(aTooltip, "\r"));
			end
			for i = 2, TOKEN_MAX_EFFECTS do
				local w = aWidgets["effect" .. i];
				if w then
					w.destroy();
				end
			end
		else
			for i = 1, TOKEN_MAX_EFFECTS do
				local w = aWidgets["effect" .. i];
				if w then
					w.destroy();
				end
			end
		end
	else
		local bWidgetsVisible = (sOptTE == "on");
		
		local aCondList = fGetEffectInfo(nodeCT);
		local nConds = #aCondList;
		
		local wToken, hToken = tokenCT.getSize();
		local nMaxToken = math.floor(((wToken - TOKEN_EFFECT_OFFSETMAXX - TOKEN_EFFECT_MARGIN) / (TOKEN_EFFECT_WIDTH + TOKEN_EFFECT_MARGIN)) + 0.5);
		if nMaxToken < 1 then
			nMaxToken = 1;
		end
		local nMaxShown = math.min(nMaxToken, TOKEN_MAX_EFFECTS);
		
		local i = 1;
		local nMaxLoop = math.min(nConds, nMaxShown);
		while i <= nMaxLoop do
			local w = aWidgets["effect" .. i];
			if not w then
				w = tokenCT.addBitmapWidget();
				w.setPosition("bottomleft", TOKEN_EFFECT_OFFSETX + ((TOKEN_EFFECT_WIDTH + TOKEN_EFFECT_MARGIN) * (i - 1)), -TOKEN_EFFECT_OFFSETY);
				w.setName("effect" .. i);
			end
			if w then
				if i == nMaxLoop and nConds > nMaxLoop then
					w.setBitmap("cond_more");
					local aTooltip = {};
					for j = i, nConds do
						table.insert(aTooltip, aCondList[j].sEffect);
					end
					w.setTooltipText(table.concat(aTooltip, "\r"));
				else
					w.setBitmap(aCondList[i].sIcon);
					w.setTooltipText(aCondList[i].sName);
				end
				w.setVisible(bWidgetsVisible);
			end
			i = i + 1;
		end
		while i <= TOKEN_MAX_EFFECTS do
			local w = aWidgets["effect" .. i];
			if w then
				w.destroy();
			end
			i = i + 1;
		end
	end
end
