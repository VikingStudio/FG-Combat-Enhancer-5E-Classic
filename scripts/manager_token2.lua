--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.

local OOB_MSGTYPE_FORCETOKENUPDATE = "FORCE_TOKEN_UPDATE";

local totalMaxEffects = 20;
local TOKEN_MAX_OVERLAY = 2;
local tokenEffectWidth = 58;
local TOKEN_EFFECT_MARGIN = 2;
local TOKEN_EFFECT_OFFSETX = 6;
local TOKEN_EFFECT_OFFSETY = -6;
local TOKEN_HEALTH_MINBAR = 14;
local TOKEN_HEALTH_WIDTH = 20;

function onInit()
	-- TokenManager to get distance
	TokenManager.getDistance = getDistance;
	local distance, badjacent = TokenManager.getDistance();
	--Debug.chat(distance);

	--Debug.console('LOADED CUSTOM TOKENMANAGER2'); 
	DB.addHandler("combattracker.list.*.hp", "onUpdate", updateHealth);
	DB.addHandler("combattracker.list.*.hptemp", "onUpdate", updateHealth);
	DB.addHandler("combattracker.list.*.wounds", "onUpdate", updateHealth);
	DB.addHandler("combattracker.list.*.height", "onUpdate", updateHeight);

	-- Scaling of condition markers
	DB.addHandler("combattracker.list.*.tokenscale", "onUpdate", updateEffects);
	-- Save icon clear state
	DB.addHandler("combattracker.list.*.saveclear", "onUpdate", updateSaveOverlay);
	-- Handle Status Changes if client
	DB.addHandler("combattracker.list.*.status", "onUpdate", updateStatus);
	-- Handle Death Save updates
	DB.addHandler("combattracker.list.*.deathsavefail", "onAdd", updateDeathWatch);
	DB.addHandler("combattracker.list.*.deathsavefail", "onUpdate", updateDeathWatch);


	DB.addHandler("combattracker.list.*.effects", "onChildUpdate", updateEffectsList);
	DB.addHandler("combattracker.list.*.effects.*.isactive", "onAdd", updateEffects);
	DB.addHandler("combattracker.list.*.effects.*.isactive", "onUpdate", updateEffects);
	DB.addHandler("combattracker.list.*.effects.*.isgmonly", "onAdd", updateEffects);
	DB.addHandler("combattracker.list.*.effects.*.isgmonly", "onUpdate", updateEffects);
	DB.addHandler("combattracker.list.*.effects.*.label", "onAdd", updateEffects);
	DB.addHandler("combattracker.list.*.effects.*.label", "onUpdate", updateEffects);


	-- Options handler
	OptionsManager.registerOption2("TNPCH", false, "option_header_token", "option_label_TNPCH", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "tooltip|bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });
	OptionsManager.registerOption2("TPCH", false, "option_header_token", "option_label_TPCH", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "tooltip|bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });
	OptionsManager.registerOption2("WNDC", false, "option_header_combat", "option_label_WNDC", "option_entry_cycler", 
			{ labels = "option_val_detailed", values = "detailed", baselabel = "option_val_simple", baseval = "off", default = "off" });
	OptionsManager.registerOption2("TNPCE", false, "option_header_token", "option_label_TNPCE", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "tooltip|on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("TPCE", false, "option_header_token", "option_label_TPCE", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "tooltip|on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });

	DB.addHandler("options.TNPCH", "onUpdate", TokenManager.onOptionChanged);
	DB.addHandler("options.TPCH", "onUpdate", TokenManager.onOptionChanged);
	DB.addHandler("options.WNDC", "onUpdate", TokenManager.onOptionChanged);
	DB.addHandler("options.TNPCE", "onUpdate", TokenManager.onOptionChanged); 
	DB.addHandler("options.TPCE", "onUpdate", TokenManager.onOptionChanged);
	
	-- NPCID Option migrated to tokenManager

	-- listen to force updates from the host
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_FORCETOKENUPDATE,updateFromHost); 
end

--[[
	Host triggered force update
]]--

function updateFromHost(OOBMsg)
	if not User.isHost() then
		local nodeCT = DB.findNode(OOBMsg.dbref); 

		Debug.console('UPDATING TOKEN REFERENCE: Got force update from host'); 
		if nodeCT ~= nil then
			local nodeRef = nodeCT.getChild('tokenrefid'); 
			local nodeName = nodeCT.getChild('name'); 
			if nodeRef then
				TokenManager.updateAttributes(nodeRef); 
				-- nodeName must also be valid
				TokenManager.updateName(nodeName); 
			end
		end
	end
end

--[[
	Send an OOB to force client updates
]]--
function sendForceUpdateOOB(nodeCT)
	local OOBMsg = {type=OOB_MSGTYPE_FORCETOKENUPDATE,dbref=nodeCT.getPath()}; 
	Comm.deliverOOBMessage(OOBMsg); 
end

--[[
	Update for IDChange
--]]
function updateNPCID(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		--Debug.console('UPDATING OVERLAY ID Change>> ' .. tokenCT.getName()); 
		tokenCT = updateStatusOverlayWidget(tokenCT,nodeCT); 
		updateTooltip(tokenCT,nodeCT); 

		-- nodeName must also be valid
		local nodeName = nodeCT.getChild('name'); 
		TokenManager.updateName(nodeName); 

		-- Force the clients to update
		sendForceUpdateOOB(nodeCT);
	end

end

--[[
	Monitor failed death saves
]]--
function updateDeathWatch(nodeField)
	Debug.console('DEATH WATCH! ' .. tostring(nodeField.getValue())); 
	-- force the update
	local nodeCT = nodeField.getParent(); 
	local nodeRef = nodeCT.getChild('tokenrefid'); 
	if nodeRef then
		TokenManager.updateAttributes(nodeRef); 
	end
end

--[[
	trigger on status string
]]--
function updateStatus(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	local sStatus = nodeField.getValue(); 
	if tokenCT then
		--Debug.console('UPDATING OVERLAY StatusChange>> ' .. tokenCT.getName()); 
		tokenCT = updateStatusOverlayWidget(tokenCT,nodeCT); 
		updateEffectsHelper(tokenCT, nodeCT);
		updateTooltip(tokenCT,nodeCT); 
	end
end


--[[
	Create the node entry in the CT if it does not exist, and
	set the save value.

	0 - nothing
	1 - success
	2 - failure

]]--
function setSaveOverlay(nodeCT, success)
	--Debug.console('set save overlay'); 
	if nodeCT then
		local saveclearNode = nodeCT.createChild("saveclear","number"); 
		if saveclearNode then
			saveclearNode.setValue(success); 
		end
	end

end
--[[
	Apply the save overlay for success/failure for easy
	recognition.
]]--
function updateSaveOverlay(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	local success = nodeField.getValue(); 
	local widgetSuccess;

	if tokenCT then
		local wToken, hToken = tokenCT.getSize();
		-- now add the widget
		-- destroy old success widgets if present
		widgetSuccess = tokenCT.findWidget("success1");
		if widgetSuccess then widgetSuccess.destroy() end

		if success == 1 then 
			widgetSuccess = tokenCT.addBitmapWidget(); 
			widgetSuccess.setName("success1"); 
			widgetSuccess.bringToFront(); 
			widgetSuccess.setBitmap("overlay_save_success"); 
			widgetSuccess.setSize(math.floor(wToken*1), math.floor(hToken*1)); 
		elseif success == 2 then
			widgetSuccess = tokenCT.addBitmapWidget(); 
			widgetSuccess.setName("success1"); 
			widgetSuccess.bringToFront(); 
			widgetSuccess.setBitmap("overlay_save_failure"); 
			widgetSuccess.setSize(math.floor(wToken*1), math.floor(hToken*1)); 
		else
			-- leave it removed
		end
	end
end


function onScaleChanged(tokenCT, nodeCT)
	local bHorizontalHealthBars = OptionsManager.getOption('CE_HHB');
	--Debug.console("+++onScaleChanged"); 
	tokenCT = updateStatusOverlayWidget(tokenCT,nodeCT); 
	-- scale for wide horizontal health bars if menu setting on, otherwise use default slim vertical health bars
	if bHorizontalHealthBars == "on" then				
		updateHealthBarScaleHorizontal(tokenCT, nodeCT);
	else
		updateHealthBarScaleDefault(tokenCT, nodeCT);
	end				
	updateEffectsHelper(tokenCT, nodeCT);
	--Debug.console("---onScaleChanged"); 
end

function onHover(tokenCT, nodeCT, bOver)
	local sFaction = DB.getValue(nodeCT, "friendfoe", "");

	local sOptEffects, sOptHealth;
	if sFaction == "friend" then
		sOptEffects = OptionsManager.getOption("TPCE");
		sOptHealth = OptionsManager.getOption("TPCH");
	else
		sOptEffects = OptionsManager.getOption("TNPCE");
		sOptHealth = OptionsManager.getOption("TNPCH");
	end
		
	local aWidgets = {};
	if sOptHealth == "barhover" then
		aWidgets["healthbar"] = tokenCT.findWidget("healthbar");
	elseif sOptHealth == "dothover" then
		aWidgets["healthdot"] = tokenCT.findWidget("healthdot");
	end
	if sOptEffects == "hover" or sOptEffects == "markhover" then
		for i = 1, totalMaxEffects do
			aWidgets["effect" .. i] = tokenCT.findWidget("effect" .. i);
		end
	end

	for _, vWidget in pairs(aWidgets) do
		vWidget.setVisible(bOver);
	end
end

function updateHeight(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if (HeightManager) then
		HeightManager.updateHeight(tokenCT); 
	end
end

function updateAttributesHelper(tokenCT, nodeCT)
	--Debug.console("+++updateAttributeHelper"); 
	tokenCT = updateStatusOverlayWidget(tokenCT,nodeCT); 

	-- nodename must also be valid
	local nodeName = nodeCT.getChild('name'); 
	TokenManager.updateName(nodeName); 

	updateHealthHelper(tokenCT, nodeCT);
	updateEffectsHelper(tokenCT, nodeCT);
	updateTooltip(tokenCT, nodeCT)

	if (MiniEffect) then
		MiniEffect.setupMenuItems(tokenCT); 
	end
	if (HeightManager) then
		HeightManager.setupToken(tokenCT); 
	end
	if (MapTokenManager and User.isHost()) then
		local sClass, sRef = DB.getValue(nodeCT,'link'); 
		if sClass == 'npc' then
			MapTokenManager.setupCombatTokenMenu(tokenCT); 
		end
	end
	if (CombatSnap) then
		if tokenCT and tokenCT.isActive() then
			CombatSnap.customTurnStart(nodeCT); 
		end
	end
	--Debug.console("---updateAttributeHelper"); 
	-- Force the client to update if the host updated
	if User.isHost() then
		-- if we're updating attributes, then the token is on the map
		DB.setValue(nodeCT, "tokenonmap", "number", 1);
		sendForceUpdateOOB(nodeCT);
	end
end

function updateTooltip(tokenCT, nodeCT)
	local sOptTNAM = OptionsManager.getOption("TNAM");
	local sOptTH, sOptTE;
	local bID = LibraryData.getIDState("npc", nodeCT, true);
	local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
	if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		sOptTE = OptionsManager.getOption("TPCE");
		sOptTH = OptionsManager.getOption("TPCH");
	else
		sOptTE = OptionsManager.getOption("TNPCE");
		sOptTH = OptionsManager.getOption("TNPCH");
	end
		
	local aTooltip = {};
	if sOptTNAM == "tooltip" then
		if bID or sClass == "charsheet" then
			table.insert(aTooltip, DB.getValue(nodeCT, "name", ""));
		else
			table.insert(aTooltip, DB.getValue(nodeCT, "nonid_name", ""));
		end
	end
	if sOptTH == "tooltip" then
		local sStatus;
		_, sStatus = ActorManager2.getPercentWounded2("ct", nodeCT);
		table.insert(aTooltip, sStatus);
	end
	if sOptTE == "tooltip" then
		local aCondList = getConditionIconList(nodeCT, true);
		for _,v in ipairs(aCondList) do
			table.insert(aTooltip, v.sLabel);
		end
	end
	
	tokenCT.setName(table.concat(aTooltip, "\r"));
end

function updateFaction(tokenCT, nodeCT)
	updateHealthHelper(tokenCT, nodeCT);
	updateEffectsHelper(tokenCT, nodeCT);
end

function updateHealth(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		--Debug.console("+++updateHealth"); 
		tokenCT = updateStatusOverlayWidget(tokenCT,nodeCT); 
		updateHealthHelper(tokenCT, nodeCT);
		updateTooltip(tokenCT, nodeCT);
		--Debug.console("---updateHealth"); 
	end
end

function updateHealthHelper(tokenCT, nodeCT)
	local bHorizontalHealthBars = OptionsManager.getOption('CE_HHB');
	local aWidgets = getWidgetList(tokenCT, "health");
	local sOptTH;

	if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		sOptTH = OptionsManager.getOption("TPCH");
	else
		sOptTH = OptionsManager.getOption("TNPCH");
	end		
	
	if sOptTH == "off" or sOptTH == "tooltip" then
		for _, vWidget in pairs(aWidgets) do
			vWidget.destroy();
		end
	else
		local sColor, nPercentWounded, sStatus = ActorManager2.getWoundBarColor("ct", nodeCT);			
		if sOptTH == "bar" or sOptTH == "barhover" then
			local w, h = tokenCT.getSize();
		
			if h >= TOKEN_HEALTH_MINBAR then
				local widgetHealthBar = aWidgets["healthbar"];
				if not widgetHealthBar then

					-- horizontal health bars if menu setting on, otherwise use default slim vertical health bars										
					if bHorizontalHealthBars == "on" then 											
						widgetHealthBar = tokenCT.addBitmapWidget('healthbar_horizontal');												
					else												
						widgetHealthBar = tokenCT.addBitmapWidget('healthbar_original');						
					end
										
					widgetHealthBar.sendToBack();
					widgetHealthBar.setName("healthbar");
				end
				if widgetHealthBar then
					widgetHealthBar.setColor(sColor);
					widgetHealthBar.setTooltipText(sStatus);
					widgetHealthBar.setVisible(sOptTH == "bar");
				end
			end

			-- scale for wide horizontal health bars if menu setting on, otherwise use default slim vertical health bars
			if bHorizontalHealthBars == "on" then				
				updateHealthBarScaleHorizontal(tokenCT, nodeCT);
			else
				updateHealthBarScaleDefault(tokenCT, nodeCT);
			end						
			
			if aWidgets["healthdot"] then
				aWidgets["healthdot"].destroy();
			end
		elseif sOptTH == "dot" or sOptTH == "dothover" then
			local widgetHealthDot = aWidgets["healthdot"];
			if not widgetHealthDot then
				widgetHealthDot = tokenCT.addBitmapWidget("healthdot");				

				-- set size and location of dot health indicator by ratio to token size, (v 1.2.0)
				local w, h = tokenCT.getSize();									
				widgetHealthDot.setSize( math.floor(w / 5), math.floor(h / 5) );				
				widgetHealthDot.setPosition("bottomright", - math.floor(w / 10), - math.floor(h / 10) ); 
				
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

-- Horizontal health bar: Changed health bar to appear above token, full token width when health 100%, horizontal health bar, above token
function updateHealthBarScaleHorizontal(tokenCT, nodeCT)		
	local widgetHealthBar = tokenCT.findWidget("healthbar");
	if widgetHealthBar then
		local nPercentWounded = ActorManager2.getPercentWounded2("ct", nodeCT);
		
		local w, h = tokenCT.getSize();				

		widgetHealthBar.setSize(w, h);
		local barw, barh = widgetHealthBar.getSize();
		
		token_health_minbar = 0; -- constant TOKEN_HEALTH_MINBAR = 14		
		--Resize bar to match health percentage
		if w >= token_health_minbar then
			barw = (math.max(1.0 - nPercentWounded, 0) * (math.min(w, barw) - token_health_minbar)) + token_health_minbar;
		else
			barw = token_health_minbar;
		end				

		-- making health bars wider and taller, appearing on top, resize and place ratio wise due to different mat grids and resolution sizes
		widgetHealthBar.setSize(barw - math.floor(barw / 90), math.floor(barh / 10), "left");
		widgetHealthBar.setPosition("left", (barw / 2), - math.floor(h / 1.7) ); 		
	end
end

-- Default vertical health bar
function updateHealthBarScaleDefault(tokenCT, nodeCT)
	local widgetHealthBar = tokenCT.findWidget("healthbar");
	if widgetHealthBar then
		local nPercentWounded = ActorManager2.getPercentWounded2("ct", nodeCT);
		
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

		widgetHealthBar.setSize(barw, barh, "bottom");
		widgetHealthBar.setPosition("bottomright", -4, -(barh / 2) + 4);		
	end
end

function updateEffects(nodeEffectField)
	local nodeEffect = nodeEffectField.getChild("..");
	local nodeCT = nodeEffect.getChild("...");
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		--Debug.console("+++updateEffects"); 
		tokenCT = updateStatusOverlayWidget(tokenCT,nodeCT); 
		updateEffectsHelper(tokenCT, nodeCT);
		updateTooltip(tokenCT, nodeCT);
		--Debug.console("---updateEffects"); 
	end
end

function updateEffectsList(nodeEffectsList, bListChanged)
	if bListChanged then
		local nodeCT = nodeEffectsList.getParent();
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			--Debug.console("+++updateEffectsList"); 
			tokenCT = updateStatusOverlayWidget(tokenCT,nodeCT); 
			updateEffectsHelper(tokenCT, nodeCT);
			updateTooltip(tokenCT, nodeCT);
			--console("---updateEffectsList"); 
		end
	end
end


function updateEffectsHelper(tokenCT, nodeCT)
	local sOptTE;	
	totalMaxEffects = CombatEnhancer.getMaxTokenEffects();

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
		local aCondList = getConditionIconList(nodeCT);
		for _,v in ipairs(aCondList) do
			table.insert(aTooltip, v.sLabel);
		end
		
		if #aTooltip > 0 then
			local w = aWidgets["effect1"];
			if not w then
				w = tokenCT.addBitmapWidget();
				w.setPosition("bottomleft", TOKEN_EFFECT_OFFSETX, TOKEN_EFFECT_OFFSETY);
				w.setName("effect1");
			end
			if w then
				w.setBitmap("cond_generic");
				w.setVisible(bWidgetsVisible);
				w.setTooltipText(table.concat(aTooltip, "\r"));
			end
			for i = 2, totalMaxEffects do
				local w = aWidgets["effect" .. i];
				if w then
					w.destroy();
				end
			end
		else
			for i = 1, totalMaxEffects do
				local w = aWidgets["effect" .. i];
				if w then
					w.destroy();
				end
			end
		end
	else
		local bWidgetsVisible = (sOptTE == "on");
		local nPercentWounded, sStatus = ActorManager2.getPercentWounded2("ct", nodeCT);
		local aCondList = getConditionIconList(nodeCT);
		local nConds = #aCondList;
		local wToken, hToken = tokenCT.getSize();
        --Debug.console("token size is" .. wToken .. ' - ' .. hToken);
		--local nMaxToken = math.floor(((wToken - TOKEN_HEALTH_WIDTH - TOKEN_EFFECT_MARGIN) / (tokenEffectWidth + TOKEN_EFFECT_MARGIN)) + 0.5);
		tokenEffectWidth = CombatEnhancer.getTokenEffectWidth();
		--wToken = tokenEffectWidth;
		--hToken = tokenEffectWidth;
		--tokenCT.setSize(tokenEffectWidth, tokenEffectWidth);
        local nMaxToken = math.floor(wToken/tokenEffectWidth);


		if nMaxToken < 1 then
			nMaxToken = 1;
		end
		--local nMaxShown = math.min(nMaxToken, totalMaxEffects);
		local nMaxShown = math.min(nMaxToken*nMaxToken,totalMaxEffects); 
		
		local i = 1;
		local nMaxLoop = math.min(nConds, nMaxShown);

		while i <= nMaxLoop do
			local w = aWidgets["effect" .. i];
			if not w then
				w = tokenCT.addBitmapWidget();	
				w.setSize(tokenEffectWidth, tokenEffectWidth);			
				--w.setPosition("bottomleft", TOKEN_EFFECT_OFFSETX + ((tokenEffectWidth + TOKEN_EFFECT_MARGIN) * (i - 1)), TOKEN_EFFECT_OFFSETY);
				--wToken = 0.5;
				--hToken = 0.5;
				updateEffectWidgetPosition(w,wToken,hToken,i);
				w.setName("effect" .. i);
			end
			if w then
				if i == nMaxLoop and nConds > nMaxLoop then
					w.setBitmap("cond_more");
					local aTooltip = {};
					for j = i, nConds do
						table.insert(aTooltip, aCondList[j].sLabel);
					end
					w.setTooltipText(table.concat(aTooltip, "\r"));
					updateEffectWidgetPosition(w,wToken,hToken,i);
				else
					w.setBitmap(aCondList[i].sIcon);
					w.setTooltipText(aCondList[i].sText);
					updateEffectWidgetPosition(w,wToken,hToken,i);
				end
				w.setVisible(bWidgetsVisible);
			end
			i = i + 1;
		end

		-- get rid of extra widgets from prior to when we added
		while i <= totalMaxEffects do
			local w = aWidgets["effect" .. i];
			if w then
				w.destroy();
			end
			i = i + 1;
		end

		-- darken widgets for dying creatures
		-- make transparent for normal creatures (when/if they flip)
		aWidgets = getWidgetList(tokenCT, "effect");
		for k,v in pairs(aWidgets) do
			local w = aWidgets[k];
			if w then
				if sStatus:match('Dying') or 
				sStatus == "Unconscious" then
					-- check if 'Change NPC token effect icons on death' Settings menu item is on or off
					if OptionsManager.getOption("CE_CFNPC") == 'on' then
						w.setColor('00555555'); 
					end										
				elseif sStatus == "Dead" then
					w.destroy(); 
				else
					w.setColor('FFFFFFFF'); 
				end
			end
		end

	end

	-- make sure our height is atop any status widgets
	if (HeightManager) then
		HeightManager.setupToken(tokenCT); 
	end
end

--[[
	Extra widget for friendlies, TEAMMATE DOWN!
]]--
function updateFriendlyDownWidget(tokenCT,nodeCT,status)
	local sFaction = DB.getValue(nodeCT, "friendfoe", "");

	if sFaction == 'friend' then
		if status:match('Dying') then
			widgetAlert = tokenCT.addBitmapWidget(); 
			widgetAlert.setName("overlay2"); 
			widgetAlert.setBitmap("overlay_alert"); 
			widgetAlert.setSize(96,96); 
			widgetAlert.setPosition("left",0,0);
			widgetAlert.bringToFront(); 
		end
	end
end

-- update the status overlay, a simple widget that
-- toggles on specific health threshold below
-- all other effect widgets, a kind of 'tint'
--
function updateStatusOverlayWidget(tokenCT,nodeCT)
	-- Let's try to draw an extra widget
	local widgetStatus, aoWidgets;
	local wToken, hToken = tokenCT.getSize();
	local nPercentWounded, sStatus = ActorManager2.getPercentWounded2("ct", nodeCT);
	local sFaction = DB.getValue(nodeCT, "friendfoe", "");
	-- piggy backing on widget visibility, let's move the token from 'play_image' to 'features_image'
	local imgContainer = tokenCT.getContainerNode();
	--Debug.console('source container >> ' .. imgContainer.getName()); 
	--Debug.console('UPDATING OVERLAY >> ' .. tokenCT.getName()); 
	--Debug.console('nodeCT >> ' .. nodeCT.getName()); 
	--Debug.console('parent nodeCT >> ' .. nodeCT.getParent().getName()); 
	-- first get the tokenref node from the CT entry
	-- next get the image from the CT node,
	-- get the parent image

	--Debug.console(tokenCT.getName() .. ' status: ' .. sStatus); 

	--Get related menu option Settings
	local drawSkullOnDeath = OptionsManager.getOption('CE_DSOD');	
	local drawBloodOnToken = OptionsManager.getOption('CE_DBOT');		

	if (sStatus == "Dead" or
	sStatus:match("Dying")) and
	imgContainer.getName() == 'play_image' then
		tokenCT = updateStatusOverlayWidgetHelper(tokenCT,nodeCT,'features_image'); 		
		-- if we're Dead/Dying then make a splatter too!
		if (sStatus:match("Dying") or 
		sStatus == "Dead") and
		User.isHost() then			
			createSplatter(tokenCT,nodeCT,'image');
		end
	elseif (sStatus == "Critical" or
	sStatus == "Heavy" or
	sStatus == "Moderate" or
	sStatus == "Wounded" or
	sStatus == "Light" or
	sStatus == "Critical" or
	sStatus == "Healthy") and
	imgContainer.getName() == 'features_image' then
		tokenCT = updateStatusOverlayWidgetHelper(tokenCT,nodeCT,'play_image'); 
	end

	-- remove old status
	-- Position is important, as if tokenCT is swapped, the new token will initialize (attribhelp)
	-- in the middle, or another update such that two overlay widget updates are called.
	-- the 'nested' overlay call's widgets must be removed so the outer can add the final widget
	aoWidgets = getWidgetList(tokenCT, "overlay"); 
	for k,v in pairs(aoWidgets) do
		local w = aoWidgets[k]; 
		w.destroy(); 
	end
	

	if sStatus:match("Dying") or 
	sStatus == "Dead" or
	sStatus == "Moderate" or
	sStatus == "Heavy" or
	sStatus == "Critical" then
		--Debug.console("sStatus is " .. sStatus .. " for " .. tokenCT.getName() .. " id: " .. tokenCT.getId()); 
		widgetStatus = tokenCT.addBitmapWidget(); 
		widgetStatus.setName("overlay1"); 
		widgetStatus.sendToBack(); 
		if sStatus:match('Dying') then
			-- if we're dying, check for the stable status to make it colored green
			local rActor = ActorManager.getActorFromCT(nodeCT);
			if EffectManager5E.hasEffect(rActor, "Stable") then
				if sFaction == 'friend' then
					widgetStatus.setBitmap("overlay_dying_ally_stable"); 
				else
					if drawSkullOnDeath == 'on' then
						widgetStatus.setBitmap("overlay_dying_stable"); 
					end;
				end
			else
				if sFaction == 'friend' then
					widgetStatus.setBitmap("overlay_dying_ally"); 
				else
					if drawSkullOnDeath == 'on' then
						widgetStatus.setBitmap("overlay_dying"); 
					end
				end
			end
			widgetStatus.setSize(math.floor(wToken*1), math.floor(hToken*1)); 
		elseif sStatus == 'Dead' then
			if drawSkullOnDeath == 'on' then
				widgetStatus.setBitmap("overlay_dead"); 
				widgetStatus.setSize(math.floor(wToken*1), math.floor(hToken*1)); 
			end
		elseif sStatus == 'Unconscious' then
			widgetStatus.setBitmap("overlay_ko"); 
			widgetStatus.setSize(math.floor(wToken*1.5), math.floor(hToken*1.5)); 
		elseif sStatus == 'Moderate' then
			if drawBloodOnToken == 'on' then
				widgetStatus.setBitmap("overlay_moderate"); 
				widgetStatus.setSize(math.floor(wToken*1), math.floor(hToken*1)); 
			end				
		elseif sStatus == 'Heavy' then
			if drawBloodOnToken == 'on' then
				widgetStatus.setBitmap("overlay_heavy"); 
				widgetStatus.setSize(math.floor(wToken*1), math.floor(hToken*1)); 
			end
		elseif sStatus == 'Critical' then
			if drawBloodOnToken == 'on' then
				widgetStatus.setBitmap("overlay_critical"); 
				widgetStatus.setSize(math.floor(wToken*1), math.floor(hToken*1)); 
			end				
		else
			Debug.console("BAD STATUS!!"); 
			aoWidgets = getWidgetList(tokenCT, "overlay"); 
			for k,v in pairs(aoWidgets) do
				local w = aoWidgets[k]; 
				w.destroy(); 
			end
		end
	end

	-- insert our friendly down widget
	updateFriendlyDownWidget(tokenCT,nodeCT,sStatus); 


	-- our target has changed; 
	return tokenCT; 
	-- bonus: add a blood stain with random rotation

end

-- Shift the token
function updateStatusOverlayWidgetHelper(tokenCT,nodeCT,targetLayer)
	local imgCtlBackground,imgCtlFeature,imgCtlPlay; 
	local imgParentContainer = tokenCT.getContainerNode().getParent(); 

	--Debug.console("ATTEMPTING To Grab Image Window of " .. tokenCT.getName() .. " id: " .. tokenCT.getId()); 			
	--local w = Interface.findWindow("imagewindow", imgParentContainer)	
	
	-- v1.3.0, wndImage returns the value for all image panel version, regular and background
	local ctrlImage, wndImage, bWindowOpened = ImageManager.getImageControl(tokenCT, false);		
	w = wndImage;

	if w then
		--Debug.console("Found imagewindow " .. tokenCT.getName()); 
		wc = w.getControls();
		for k,v in pairs(wc) do					
			--Debug.console("WINDOW INSTANCE >> " .. tostring(k) .. ' -- ' .. tostring(v.getName())); 
			if v.getName() == "image" then
				imgCtlBackground = v; 	
			elseif v.getName() == "features_image" then
				imgCtlFeature = v; 	
			elseif v.getName() == "play_image" then
				imgCtlPlay = v; 	
			end
		end
		

	--Debug.chat('ctrlImage', ctrlImage);
	--if w then		
		--imgCtlBackground = ctrlImage;
		--imgCtlFeature = ctrlImage;
		--imgCtlPlay = ctrlImage;
		
		local tokenproto = tokenCT.getPrototype(); 
		local posX, posY, scale; 
		posX, posY = tokenCT.getPosition(); 
		scale = tokenCT.getScale(); 

		local ctwnd = Interface.findWindow("combattracker_host", "combattracker");
		local ctEntry = nil; 
		--Debug.chat('ctwnd', ctwnd);
		if ctwnd then
			for k,v in pairs(ctwnd.list.getWindows()) do
				if DB.getPath(v.getDatabaseNode()) == DB.getPath(nodeCT) then
					ctEntry = v; 
				end
			end
			--Debug.chat('ctEntry', ctEntry);
			if ctEntry then
				local tokenMap; 
				if targetLayer == "features_image" then
					imgCtlFeature.setTokenScale(imgCtlPlay.getTokenScale()); 
					tokenMap = imgCtlFeature.addToken(tokenproto, posX, posY);

				elseif targetLayer == "play_image" then
					imgCtlFeature.setTokenScale(imgCtlPlay.getTokenScale()); 
					tokenMap = imgCtlPlay.addToken(tokenproto, posX, posY);
				else
					-- don't do anything
					return tokenCT; 
				end

				tokenMap.setScale(scale); 

				-- We need to clear ourselves from anyone who was targeting us, as well
				-- as anyone we were targeting
				--Debug.console("old token targreted? " .. tostring(tokenCT.isTargeted())); 
				--Debug.console("new token targreted? " .. tostring(tokenMap.isTargeted())); 

				clearSelfTargets(tokenCT,nodeCT); 

				--tokenCT = tokenMap; 
				-- Update the CT entry's token references
				--ctEntry.token.replace(tokenMap);
				replaceToken(nodeCT,tokenMap,tokenCT); 
				tokenCT = tokenMap; 
				--Debug.console("----- replacing with new token >>> " .. tokenCT.getName() .. " id: " .. tokenCT.getId()); 
			end
		end
	else
		--Debug.console("Could not open window " .. tokenCT.getName()); 
	end
	
	return tokenCT; 
end

function replaceToken(nodeCT,newTokenInstance,oldTokenInstance)	
	-- Link the token without checking the old
	TokenManager.linkToken(nodeCT, newTokenInstance);
	TokenManager.updateVisibility(nodeCT);
	TargetingManager.updateTargetsFromCT(nodeCT, newTokenInstance);
	Debug.console('UPDATING attributes for replaced token'); 
	-- We need to send an update to the clients
	--nodeCT.createChild('forceupdate','string').setValue('update' .. newTokenInstance.getId()); 	
	sendForceUpdateOOB(nodeCT); 
	-- update on the host side
	TokenManager.updateAttributes(nodeCT.getChild('tokenrefid')); 

	oldTokenInstance.delete(); 
end

-- Clears all targets on the token as well as removes itself from the
-- target list of anyone else on the CT. 
function clearSelfTargets(tokenCT,nodeCT)
	--iterate through the CT targeting fields and find cts that have
	local cts = nodeCT.getParent().getChildren(); 
	local targets,targetNodeRef,targetNodeRefValue; 
	--Debug.console("our noderef is: " .. nodeCT.getPath()); 
	-- clean our own targets
	tokenCT.clearTargets(); 

	for k,v in pairs(cts) do
		targets = v.getChild('targets'); 
		--Debug.console("ct entry: " .. k); 
		--Debug.console("targets : " .. tostring(type(v.getChild('targets')))); 
		if targets then
			--Debug.console('target children: ' .. targets.getChildCount()); 
			--Debug.console('target valueType: ' .. type(targets.getValue())); 
			targets = targets.getChildren();
			for tk,tv in pairs(targets) do
				targetNodeRef = tv.getChild('noderef'); 
				targetNodeRef = targetNodeRef.getValue(); 
				--Debug.console(tk .. ' and ' .. targetNodeRef); 
				if nodeCT.getPath() == targetNodeRef then
					-- Delete this node!
						tv.delete(); 	
				end
			end
		end
	end
end


function onSplatterDragStart(target,button,x,y,dragdata)
	-- do nothing
	if Input.isControlPressed() then
		return nil; 
	else
		return true; 
	end
end

function onSplatterDrag(target,button,x,y,dragdata)
	-- do nothing
	if Input.isControlPressed() then
		return nil; 
	else
		return true; 
	end
end

function onSplatterDragEnd(target,dragdata)
	-- do nothing
	if Input.isControlPressed() then
		return nil; 
	else
		return true; 
	end
end


-- Creates a splatter using local files that are assumed to be loaded by FG.
-- WARN if these files are gone, it effectively breaks this script!
function createSplatter(tokenCT,nodeCT,targetLayer)
	
	local imgCtlBackground,imgCtlFeature,imgCtlPlay; 
	local imgParentContainer = tokenCT.getContainerNode().getParent(); 

	-- check menu settings to see if these are turned off, if so exit function
	if (OptionsManager.getOption('CE_RBS') ) == 'off' then
		Debug.console('Blood splatters turned off in menu Settings, function exited.')
		return;
	end	

	local bloodPrototypes = {
		'tokens/host/Combat Enhancer/blood.png',
		'tokens/host/Combat Enhancer/blood_3.png',
		'tokens/host/Combat Enhancer/blood_5.png',
		'tokens/host/Combat Enhancer/blood_7.png',
		'tokens/host/Combat Enhancer/blood_10.png',
		'tokens/host/Combat Enhancer/blood_8.png',
		'tokens/host/Combat Enhancer/blood_9.png',
		'tokens/host/Combat Enhancer/blood_11.png',
		'tokens/host/Combat Enhancer/blood_12.png',
		'tokens/host/Combat Enhancer/blood_13.png'
	}; 

	local bloodPrototypesScale = {
		1.5,
		2,
		4,
		1.5,
		2,
		2,
		1.5,
		2,
		3,
		1.5
	}; 

	Debug.console("ATTEMPTING To Grab Image Window of " .. tokenCT.getName() .. " id: " .. tokenCT.getId()); 	
	local ctrlImage, wndImage, bWindowOpened = ImageManager.getImageControl(tokenCT, false);

	if ctrlImage then	
		imgCtlBackground = ctrlImage;		
		imgCtlPlay = ctrlImage;		

		local posX, posY, tokenMap; 
		posX, posY = tokenCT.getPosition(); 
		local rand = math.random(#bloodPrototypes); 
		local tokenproto = bloodPrototypes[rand]; 			
		local scale = bloodPrototypesScale[rand]; 		
		Debug.console("blood proto is : " .. tokenproto .. ' scale is ' .. scale); 

		imgCtlBackground.setTokenScale(imgCtlPlay.getTokenScale()); 
		tokenMap = imgCtlBackground.addToken(tokenproto, posX, posY);
		-- we use the blood token's scale as it spawns within the grid + the image mod	
		
		Debug.console("token is now " .. tostring(tokenMap) .. ' maptoken scale is ' .. tokenMap.getScale()); 
		if tokenMap then
			local Ss,Is,Id;
			posX, posY = tokenCT.getImageSize();
			--Debug.console('token source size is ' .. posX .. " " .. posY); 
			Ss = tokenCT.getScale();
			Is = math.max(posX,posY); 
			posX, posY = tokenMap.getImageSize();
			Id = math.max(posX,posY); 
			
			-- find token scaling and image size in pixels
			local tokenScale = tokenCT.getScale();
			local sizeX, sizeY;
			sizeX, sizeY = tokenMap.getImageSize();
			--
			local imageSizeMax = math.max(sizeX, sizeY);

			-- get the scale factor as function of the source token scale NOTE: off by 2x?

			-- Check to see if the extension menu Settings are configured to override the inbuilt 'Auto-scale to grid'. 
			-- If so set the token scale to ignore that setting otherwise scale as per the setting.
			--local optionTokenAutoScale = OptionsManager.getOption('TASG'); -- Settings > Token(GM) > Auto-scale to grid. { labels = "option_val_scale80|option_val_scale100", values = "80|100", baselabel = "option_val_off", baseval = "off", default = "80" });
			local optionBloodSplatterScaling = OptionsManager.getOption('CE_BSS'); -- Settings > 5e Combat Enhancer > Blood splatter scaling						

			if optionBloodSplatterScaling == 'default' then
				tokenMap.setScale(((Ss*Is)/Id)*scale); 
				Debug.console('auto-scale blood splatter, default token scale')				
			end							
			if 	optionBloodSplatterScaling == 'default_1' then						
				tokenMap.setScale(((Ss*Is)/Id)*scale*0.5); 				
				Debug.console('blood splatter scaling, token scale x 0.5')	
			end		
			if 	optionBloodSplatterScaling == 'default_2' then						
				tokenMap.setScale(((Ss*Is)/Id)*scale*0.75); 				
				Debug.console('blood splatter scaling, token scale x 0.75')	
			end		
			if 	optionBloodSplatterScaling == 'default_3' then						
				tokenMap.setScale(((Ss*Is)/Id)*scale*1.25); 				
				Debug.console('blood splatter scaling, token scale x 1.25')	
			end		
			if 	optionBloodSplatterScaling == 'default_4' then						
				tokenMap.setScale(((Ss*Is)/Id)*scale*1.5); 				
				Debug.console('blood splatter scaling, token scale x 1.5')	
			end			
			if 	optionBloodSplatterScaling == 'default_5' then						
				tokenMap.setScale(((Ss*Is)/Id)*scale*1.75); 				
				Debug.console('blood splatter scaling, token scale x 1.75')	
			end						
			if 	optionBloodSplatterScaling == 'default_6' then						
				tokenMap.setScale(((Ss*Is)/Id)*scale*2); 				
				Debug.console('blood splatter scaling, token scale x 2')	
			end													

			tokenMap.setOrientation(math.random(0,7)); 
			--[[
			tokenMap.onDragStart = onSplatterDragStart; 
			tokenMap.onDrag = onSplatterDrag; 
			tokenMap.onDragEnd = onSplatterDragEnd; 
			]]--
		else
			Debug.console("WARN: could not get blood splatter " .. tokenproto .. ' for ' .. tokenCT.getName()); 
		end
	else
		Debug.console("(splatter) Could not open window " .. tokenCT.getName()); 
	end

	return tokenCT; 
end



-- Create a grig lattice from bottom up, left to right
-- Note nMaxToken is max effects per column/row
function updateEffectWidgetPosition(widget,wToken,hToken,numEffects)
	local row, column, x, y; 
	tokenEffectWidth = CombatEnhancer.getTokenEffectWidth();

	e = math.floor(wToken/tokenEffectWidth); 

	row = math.floor(numEffects/e);
	column = numEffects%e; 

	x = 0-math.floor(wToken/2) + math.floor(tokenEffectWidth/2) + (numEffects%e-1)*tokenEffectWidth; 
	y = math.floor(hToken/2) - math.floor(tokenEffectWidth/2) - math.floor(numEffects/e)*tokenEffectWidth; 

	if column == 0 then
		x = 0-math.floor(wToken/2) + math.floor(tokenEffectWidth/2) + tokenEffectWidth*(e-1); 
		--Debug.console("0 column x is " .. x); 
	end
	if numEffects%e == 0 then
		y = math.floor(hToken/2) - math.floor(tokenEffectWidth/2) - tokenEffectWidth*(row-1); 
		--Debug.console("0 row y is " .. y); 
	end
	

	widget.setPosition("center",x,y); 

    --widget.setPosition("center", 0-math.floor(wToken/2)+(tokenEffectWidth + TOKEN_EFFECT_MARGIN)*(numEffects-1) + math.floor(tokenEffectWidth/2),
		--math.floor(hToken/2)-math.floor(tokenEffectWidth/2));
end



function getConditionIconList(nodeCT, bSkipGMOnly)
	local aIconList = {};

	local rActor = ActorManager.getActorFromCT(nodeCT);
	
	-- Iterate through effects
	local aSorted = {};
	for _,nodeChild in pairs(DB.getChildren(nodeCT, "effects")) do
		table.insert(aSorted, nodeChild);
	end
	table.sort(aSorted, function (a, b) return a.getName() < b.getName() end);

	for k,v in pairs(aSorted) do
		if DB.getValue(v, "isactive", 0) == 1 then
			if (not bSkipGMOnly and User.isHost()) or (DB.getValue(v, "isgmonly", 0) == 0) then
				local sLabel = DB.getValue(v, "label", "");
				
				local sEffect = nil;
				local bSame = true;
				local sLastIcon = nil;
				local tFirstIconGroup = nil;
				local nFirstIconStatus = 1;

				local aEffectComps = EffectManager.parseEffect(sLabel);
				for kComp,sEffectComp in ipairs(aEffectComps) do
					local vComp = EffectManager5E.parseEffectComp(sEffectComp);
					-- CHECK CONDITIONALS
					if vComp.type == "IF" then
						if not EffectManager5E.checkConditional(rActor, v, vComp.remainder) then
							break;
						end
					elseif vComp.type == "IFT" then
						-- Do nothing
					
					else
						local sNewIcon = nil;
						local icons = nil; 
						local iconStatus = 1; 
						
						-- CHECK FOR A BONUS OR PENALTY
						local sComp = vComp.type;
						if StringManager.contains(DataCommon.bonuscomps, sComp) then
							-- Use our comp bonus/penalty graphics
							icons = DataCommon.bonuscomps_icon[sComp]; 

							if #(vComp.dice) > 0 or vComp.mod > 0 then
								sNewIcon = icons[1];
								iconStatus = 1; 
							elseif vComp.mod < 0 then
								sNewIcon = icons[2];
								iconStatus = 2; 
							else
								sNewIcon = "cond_generic";
							end
					
						-- CHECK FOR OTHER VISIBLE EFFECT TYPES
						else
							icons = DataCommon.othercomps[sComp];
							if icons then
								sNewIcon = icons[1];
								iconStatus = 1; 
								if sComp == 'EXHAUSTION' then
									if vComp.mod == 1 then
										icons = DataCommon.exhaustion[1]; 
										sNewIcon = icons[1];
									elseif vComp.mod == 2 then
										icons = DataCommon.exhaustion[2]; 
										sNewIcon = icons[1];
									elseif vComp.mod == 3 then
										icons = DataCommon.exhaustion[3]; 
										sNewIcon = icons[1];
									elseif vComp.mod == 4 then
										icons = DataCommon.exhaustion[4]; 
										sNewIcon = icons[1];
									elseif vComp.mod == 5 then
										icons = DataCommon.exhaustion[5]; 
										sNewIcon = icons[1];
									elseif vComp.mod == 6 then
										icons = DataCommon.exhaustion[6]; 
										sNewIcon = icons[1];
									end
								end
							end
						end
					
						-- CHECK FOR A CONDITION
						if not sNewIcon then
							sComp = vComp.original:gsub("-", ""):lower();
							icons = DataCommon.condcomps[sComp]; 
							if icons then
								iconStatus = 1; 
								sNewIcon = icons[1];
							else
								icons = DataCommon.condcomps_extra[sComp]; 
								if icons then
									iconStatus = 1; 
									sNewIcon = icons[1];
								end
							end
						end

						-- set first icon group if valid
						if icons and tFirstIconGroup == nil then
							tFirstIconGroup = icons; 
							nFirstIconStatus = iconStatus; 
						end
						
						if sNewIcon then
							if bSame then
								if sLastIcon and sLastIcon ~= sNewIcon then
									bSame = false;
								end
								sLastIcon = sNewIcon;
							end
						else
							if kComp == 1 then
								sEffect = vComp.original;
							end
						end
					end
				end
				
				if #aEffectComps > 0 then
					local sFinalIcon;
					if bSame and sLastIcon then
						sFinalIcon = sLastIcon;
					else
						-- check if the tFirstIconGroup variable is valid, if so
						-- then we use the 'more' icon from that condition, take adv
						-- of array positioning
						if tFirstIconGroup ~= nil then
							sFinalIcon = tFirstIconGroup[nFirstIconStatus+2]; 
						else
							sFinalIcon = "cond_generic";
						end
					end
					
					local sFinalLabel;
					if sEffect then
						sFinalLabel = sEffect;
					else
						sFinalLabel = sLabel;
					end
					
					table.insert(aIconList, { sText = sFinalLabel, sIcon = sFinalIcon, sLabel = sLabel } );
				end
			end
		end
	end
	
	return aIconList;
end

function getStatusValue(nodeCT)
	local sStatus = DB.getValue(nodeCT,'status','none'); 
	return sStatus; 
end

function getWidgetList(tokenCT, sSubset)
	local aWidgets = {};

	local w = nil;
	if not sSubset or sSubset == "health" then
		for _, vName in pairs({"healthbar", "healthdot"}) do
			w = tokenCT.findWidget(vName);
			if w then
				aWidgets[vName] = w;
			end
		end
	end
	if not sSubset or sSubset == "effect" then
		for i = 1, totalMaxEffects do
			w = tokenCT.findWidget("effect" .. i);
			if w then
				aWidgets["effect" .. i] = w;
			end
		end
	end
	-- subset overlay
	if not sSubset or sSubset == "overlay" then
		for i = 1, totalMaxEffects do
			w = tokenCT.findWidget("overlay" .. i);
			if w then
				aWidgets["overlay" .. i] = w;
			end
		end
	end

	
	return aWidgets;
end






-- Code base start for automated range advantages/disadvantages/auto fail to attacks given range between attacker and set target ranged attack is made against.
function getDistance(nodeAttacker, nodeTarget)
	if nodeAttacker and nodeTarget then
		local tokenAttacker = CombatManager.getTokenFromCT(CombatManager.asNodeCTName(nodeAttacker))
		local tokenTarget = CombatManager.getTokenFromCT(CombatManager.asNodeCTName(nodeTarget))
		if tokenAttacker and tokenTarget then
			local nodeAttackerContainer = tokenAttacker.getContainerNode()
			local nodeTargetContainer = tokenTarget.getContainerNode()
			if nodeAttackerContainer.getNodeName() == nodeTargetContainer.getNodeName() then
				local ctrlImage, winImage, bWindowOpened = ImageManager.getImageControl(tokenAttacker, true)
				if ctrlImage and winImage then
					local nDistance, _, bAdjacent = getTokenDistance(ctrlImage, tokenAttacker, tokenTarget)
					if bWindowOpened then
						winImage.close()
					end					
					return nDistance, bAdjacent
				end
			end
		end
	end
end

function getTokenDistance(ctrlImage, tokenTargeter, tokenTarget)
	if ctrlImage and ctrlImage.hasGrid() and tokenTargeter and tokenTarget then
		local scaleCtrl = function(ctrlImage)
			if ctrlImage.window and
				ctrlImage.window.toolbar and
				ctrlImage.window.toolbar.subwindow and
				ctrlImage.window.toolbar.subwindow.scale then
				local ctrlScale = ctrlImage.window.toolbar.subwindow.scale
				if ctrlScale.isValid and ctrlScale.getScaleValue and ctrlScale.getScaleLabel then
					return ctrlScale
				end
			end
		end
		local sGridType = ctrlImage.getGridType()
		local nTargeterPosX, nTargeterPosY = tokenTargeter.getPosition()
		local nTargetPosX, nTargetPosY = tokenTarget.getPosition()
		local nPositionX = nTargetPosX - nTargeterPosX
		local nPositionY = nTargetPosY - nTargeterPosY
		local nDistance = 0
		local bAdjacent = false
		local nSizeAdjustment = 0
		local nodeAttackerCT = CombatManager.getCTFromToken(tokenTargeter)
		local nodeTargetCT = CombatManager.getCTFromToken(tokenTarget)
		if nodeAttackerCT and nodeTargetCT then
			local nAttackerSize = math.max(DB.getValue(nodeAttackerCT, "space", 0), 1)
			local nTargetSize = math.max(DB.getValue(nodeTargetCT, "space", 0), 1)
			nSizeAdjustment = (nAttackerSize + nTargetSize - 2) / 2
		end
		if sGridType == "hexrow" or sGridType == "hexcolumn" then
			local nGridHexWidth, nGridHexHeight = ctrlImage.getGridHexElementDimensions()
			nDistance, bAdjacent = ImageManagerSW.measureVector(nPositionX, nPositionY, sGridType, ctrlImage.getGridSize(), nGridHexWidth, nGridHexHeight, nSizeAdjustment)
		else
			nDistance, bAdjacent = ImageManagerSW.measureVector(nPositionX, nPositionY, sGridType, ctrlImage.getGridSize(), nil, nil, nSizeAdjustment)
		end
		local ctrlScale = scaleCtrl(ctrlImage)
		if ctrlScale and ctrlScale.isValid() then
			return ImageManagerSW.scaledDistance(nDistance, ctrlScale), ctrlScale.getScaleLabel(), bAdjacent
		else
			return nDistance, nil, bAdjacent
		end
	end
end


-- calling getDistance in SW ruleset
--[[

	local getDistance = function(nodeAttacker, nodeTarget)
		if OptionsManager.isOption("AARP", "on") then
			local nDistance, bAdjacent = TokenManager.getDistance(nodeAttacker, nodeTarget)
			return nDistance, bAdjacent
		end
	end

local sAttackerType, nodeAttacker = ActorManager.getTypeAndNode(rSource)
local sTargetType, nodeTarget = ActorManager.getTypeAndNode(rTarget)

for _,rTarget in pairs(vTargets or {}) do
		local nScore = rRollResult.nTotalScore
		
		local sTargetType, nodeTarget = ActorManager.getTypeAndNode(rTarget)
		local aAgainstTargetModifiers = EffectManager.getEffectAgainstMe(sTargetType, nodeTarget)
		local nDistance, bAdjacent = getDistance(nodeAttacker, nodeTarget)
]]--