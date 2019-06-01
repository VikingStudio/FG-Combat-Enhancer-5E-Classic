--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.

function onInit()
	-- Set the displays to what should be shown
	setTargetingVisible();
	setAttributesVisible();
	setActiveVisible();
	setSpacingVisible();
	setEffectsVisible();

	-- Acquire token reference, if any
	linkToken();
	
	-- Set up the PC links
	onLinkChanged();
	
	-- Update the displays
	onFactionChanged();
	onHealthChanged();
	
	-- Register the deletion menu item for the host
	registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);
	-- Handle token updates (for widget)
	updateOnMapWidget(); 
    	DB.addHandler(self.getDatabaseNode().getPath() .. ".tokenonmap", "onUpdate", updateOnMapWidget);
	-- add listener for NPC
	OptionsManager.registerCallback("NPID", onIDChanged);
end

function onClose()
    DB.removeHandler(self.getDatabaseNode().getPath() .. ".tokenonmap", "onUpdate", updateOnMapWidget);
end

function updateOnMapWidget(nodefield)
	self.token.onPlacementChanged(); 
end

--
-- ID CHANGED
--
--[[
function onClose()
	OptionsManager.unregisterCallback("NPID", onIDChanged);
end

function onIDChanged()
	-- iterate through our list of window entries
	-- 
	updateName(); 
end

function updateName()
	local nodeNPCRecord = DB.findNode(DB.getValue(getDatabaseNode(),'npclistref',''));
	local nodeRecord = getDatabaseNode(); 
	local sLinkType = DB.getValue(getDatabaseNode(),'link');
	--Debug.console('CT_ENTRY NPID updatename linktype: ' .. sLinkType .. ' NPCRecord: ' .. tostring(nodeNPCRecord)); 

	if sLinkType == 'npc' and nodeNPCRecord ~= nil then
		local bID, bOptionID = LibraryData.getIDState("npc",sLinkRecord,true); 
		local sTrueName = DB.getValue(DB.getPath(nodeNPCRecord, "name"), "");
		local sNonIDName = DB.getValue(DB.getPath(nodeNPCRecord, "nonid_name"), "");
		local sCurName, sNumber = CombatManager.stripCreatureNumber(name.getValue());
		local nodeCTIdentified = nodeRecord.createChild('isidentified','number'); 
		local sSuffix = ''; 

		-- if nonIDName is not set, the put in default
		if sNonIDName == '' then
			sNonIDName = Interface.getString("library_recordtype_empty_nonid_npc"); 
		end

		if sNumber ~= nil then
			sSuffix = ' ' .. sNumber; 
		end

		-- if NPID is on 
		if not bID then
			name.setValue(sNonIDName .. sSuffix); 
			Debug.console('Changing CT name to (NID)' .. sNonIDName .. sSuffix); 
		else
			name.setValue(sTrueName .. sSuffix); 
		end
	end
end
]]--

function updateDisplay()
	local sFaction = friendfoe.getStringValue();
	local nPercentWounded, sStatus = ActorManager2.getPercentWounded2("ct", self.getDatabaseNode());
	--Debug.console("UPDATE DISPLAY (ct entry) " .. sStatus); 	

	if DB.getValue(getDatabaseNode(), "active", 0) == 1 then
		name.setFont("sheetlabel");
		nonid_name.setFont("sheetlabel");
		
		active_spacer_top.setVisible(true);
		active_spacer_bottom.setVisible(true);
		
		if sFaction == "friend" then
			if sStatus:match("Dying") or sStatus == "Dead" then
				setFrame("ctentrybox_friend_active_dark"); 
			elseif sStatus == "Unconscious" then
				setFrame("ctentrybox_friend_active_uncon"); 
			else
				setFrame("ctentrybox_friend_active");
			end
		elseif sFaction == "neutral" then
			if sStatus:match("Dying") or sStatus == "Dead" then
				setFrame("ctentrybox_neutral_active_dark");
			elseif sStatus == "Unconscious" then
				setFrame("ctentrybox_friend_active_uncon"); 
			else
				setFrame("ctentrybox_neutral_active");
			end
		elseif sFaction == "foe" then			
			if sStatus:match("Dying") or sStatus == "Dead" then								
				if (OptionsManager.getOption('CE_CTFNPC') == 'on') then				
					setFrame("ctentrybox_foe_active_dark");
				end
			elseif sStatus == "Unconscious" then
				setFrame("ctentrybox_foe_active_uncon");
			else
				setFrame("ctentrybox_foe_active");
			end
		else
			setFrame("ctentrybox_active");
			if sStatus:match("Dying") or sStatus == "Dead" then
				setFrame("ctentrybox_active_dark");
			elseif sStatus == "Unconscious" then
				setFrame("ctentrybox_active_uncon");
			else
				setFrame("ctentrybox_active");
			end
		end
	else
		name.setFont("sheettext");
		nonid_name.setFont("sheettext");
		
		active_spacer_top.setVisible(false);
		active_spacer_bottom.setVisible(false);
		
		if sFaction == "friend" then
			if sStatus:match("Dying") or sStatus == "Dead" then
				setFrame("ctentrybox_friend_dark");
			elseif sStatus == "Unconscious" then
				setFrame("ctentrybox_friend_uncon");
			else
				setFrame("ctentrybox_friend");
			end
		elseif sFaction == "neutral" then
			if sStatus:match("Dying") or sStatus == "Dead" then
				setFrame("ctentrybox_neutral_dark");
			elseif sStatus == "Unconscious" then
				setFrame("ctentrybox_neutral_uncon");
			else
				setFrame("ctentrybox_neutral");
			end
		elseif sFaction == "foe" then
			if sStatus:match("Dying") or sStatus == "Dead" then				
				if (OptionsManager.getOption('CE_CTFNPC') == 'on') then
					setFrame("ctentrybox_foe_dark");
				end					
			elseif sStatus == "Unconscious" then
				setFrame("ctentrybox_foe_uncon");
			else
				setFrame("ctentrybox_foe");
			end
		else
			if sStatus:match("Dying") or sStatus == "Dead" then
				setFrame("ctentrybox_dark");
			elseif sStatus == "Unconscious" then
				setFrame("ctentrybox_uncon");
			else
				setFrame("ctentrybox");
			end
		end
	end
end

function linkToken()
	local imageinstance = token.populateFromImageNode(tokenrefnode.getValue(), tokenrefid.getValue());
	if imageinstance then
		TokenManager.linkToken(getDatabaseNode(), imageinstance);
		TokenManager.updateAttributes(tokenrefid.getDatabaseNode()); 
	end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		delete();
	end
end

function delete()
	local node = getDatabaseNode();
	if not node then
		close();
		return;
	end
	
	-- Remember node name
	local sNode = node.getNodeName();
	
	-- Clear any effects first, so that saves aren't triggered when initiative advanced
	effects.reset(false);

	-- Move to the next actor, if this CT entry is active
	if DB.getValue(node, "active", 0) == 1 then
		CombatManager.nextActor();
	end

	-- Delete the database node and close the window
	node.delete();

	-- Update list information (global subsection toggles, targeting)
	windowlist.onVisibilityToggle();
	windowlist.onEntrySectionToggle();
end

function onLinkChanged()
	-- If a PC, then set up the links to the char sheet
	local sClass, sRecord = link.getValue();
	if sClass == "charsheet" then
		linkPCFields();
		name.setLine(false);
	end
	onIDChanged();
end

function onIDChanged()
	local nodeRecord = getDatabaseNode();
	local sClass = DB.getValue(nodeRecord, "link", "", "");
	if sClass == "npc" then
		local bID = LibraryData.getIDState("npc", nodeRecord, true);
		name.setVisible(bID);
		nonid_name.setVisible(not bID);
		isidentified.setVisible(true);
	else
		name.setVisible(true);
		nonid_name.setVisible(false);
		isidentified.setVisible(false);
	end
end

function onHealthChanged()
	local sColor, nPercentWounded, sStatus = ActorManager2.getWoundColor("ct", getDatabaseNode());
	-- Update the entry frame
	updateDisplay();

	wounds.setColor(sColor);
	status.setValue(sStatus);

	local sClass,_ = link.getValue();
	if sClass ~= "charsheet" then
		idelete.setVisibility((nPercentWounded >= 1));
	end
end

function onFactionChanged()
	-- Update the entry frame
	updateDisplay();

	-- If not a friend, then show visibility toggle
	if friendfoe.getStringValue() == "friend" then
		tokenvis.setVisible(false);
	else
		tokenvis.setVisible(true);
	end
end

function onVisibilityChanged()
	TokenManager.updateVisibility(getDatabaseNode());
	windowlist.onVisibilityToggle();
end

function onActiveChanged()
	local isActive = (self.getDatabaseNode().getChild('active').getValue() == 1); 
	setActiveVisible();
	activeHighlight(isActive); 
end

function activeHighlight(active)
	--Debug.console('NAME: ' .. self.getDatabaseNode().getChild('name').getValue()  .. ' ACTIVE: ' .. tostring(active)); 
	if User.isHost() then
		local nodeCT = self.getDatabaseNode(); 
		if active and nodeCT then
			local tokenCT = CombatManager.getTokenFromCT(nodeCT);
			if tokenCT then
				-- the token exists
				local space = nodeCT.getChild('space');  
				if space == nil then 
					space = 1;
				else
					space = space.getValue()/5/2+0.5; 
				end

				local childs = nodeCT.getChildren(); 
				for k,v in pairs(childs) do
					--Debug.console('k: ' .. k .. ' v: ' .. tostring(v)); 	
				end
				--Debug.console('space is ' .. space); 
				tokenCT.addUnderlay(space, CombatEnhancer.TOKENUNDERLAYCOLOR_1); 
			end
		elseif nodeCT then
			local tokenCT = CombatManager.getTokenFromCT(nodeCT);
			if tokenCT then
				-- the token exists
				tokenCT.removeAllUnderlays(); 
			end
		end
	end
end

function linkPCFields()
	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		name.setLink(nodeChar.createChild("name", "string"), true);

		hptotal.setLink(nodeChar.createChild("hp.total", "number"));
		hptemp.setLink(nodeChar.createChild("hp.temporary", "number"));
		wounds.setLink(nodeChar.createChild("hp.wounds", "number"));
		deathsavesuccess.setLink(nodeChar.createChild("hp.deathsavesuccess", "number"));
		deathsavefail.setLink(nodeChar.createChild("hp.deathsavefail", "number"));

		strength.setLink(nodeChar.createChild("abilities.strength.score", "number"), true);
		dexterity.setLink(nodeChar.createChild("abilities.dexterity.score", "number"), true);
		constitution.setLink(nodeChar.createChild("abilities.constitution.score", "number"), true);
		intelligence.setLink(nodeChar.createChild("abilities.intelligence.score", "number"), true);
		wisdom.setLink(nodeChar.createChild("abilities.wisdom.score", "number"), true);
		charisma.setLink(nodeChar.createChild("abilities.charisma.score", "number"), true);

		init.setLink(nodeChar.createChild("initiative.total", "number"), true);
		ac.setLink(nodeChar.createChild("defenses.ac.total", "number"), true);
		speed.setLink(nodeChar.createChild("speed.total", "number"), true);
	end
end

--
-- SECTION VISIBILITY FUNCTIONS
--

function setTargetingVisible()
	local v = false;
	if activatetargeting.getValue() == 1 then
		v = true;
	end

	targetingicon.setVisible(v);
	
	sub_targeting.setVisible(v);
	
	frame_targeting.setVisible(v);

	target_summary.onTargetsChanged();
end

function setAttributesVisible()
	local v = false;
	if activateattributes.getValue() == 1 then
		v = true;
	end
	
	attributesicon.setVisible(v);

	strength.setVisible(v);
	strength_label.setVisible(v);
	dexterity.setVisible(v);
	dexterity_label.setVisible(v);
	constitution.setVisible(v);
	constitution_label.setVisible(v);
	intelligence.setVisible(v);
	intelligence_label.setVisible(v);
	wisdom.setVisible(v);
	wisdom_label.setVisible(v);
	charisma.setVisible(v);
	charisma_label.setVisible(v);
	
	spacer_attribute.setVisible(v);
	
	frame_attributes.setVisible(v);
end

function setActiveVisible()
	local v = false;
	if activateactive.getValue() == 1 then
		v = true;
	end

	local sClass, sRecord = link.getValue();
	local bNPC = (sClass ~= "charsheet");
	if bNPC and active.getValue() == 1 then
		v = true;
	end
	
	activeicon.setVisible(v);

	reaction.setVisible(v);
	reaction_label.setVisible(v);
	init.setVisible(v);
	initlabel.setVisible(v);
	ac.setVisible(v);
	aclabel.setVisible(v);
	speed.setVisible(v);
	speedlabel.setVisible(v);
	
	spacer_action.setVisible(v);
	
	if bNPC and traits.getWindowCount() > 0 then
		traits.setVisible(v);
		traits_label.setVisible(v);
	else
		traits.setVisible(false);
		traits_label.setVisible(false);
	end

	if bNPC then
		actions.setVisible(v);
		actions_label.setVisible(v);
		actions_emptyadd.update();
	else
		actions.setVisible(false);
		actions_label.setVisible(false);
		actions_emptyadd.setVisible(false);
	end
	
	if bNPC and reactions.getWindowCount() > 0 then
		reactions.setVisible(v);
		reactions_label.setVisible(v);
	else
		reactions.setVisible(false);
		reactions_label.setVisible(false);
	end

	if bNPC and legendaryactions.getWindowCount() > 0 then
		legendaryactions.setVisible(v);
		legendaryactions_label.setVisible(v);
	else
		legendaryactions.setVisible(false);
		legendaryactions_label.setVisible(false);
	end

	if bNPC and lairactions.getWindowCount() > 0 then
		lairactions.setVisible(v);
		lairactions_label.setVisible(v);
	else
		lairactions.setVisible(false);
		lairactions_label.setVisible(false);
	end

	if bNPC and innatespells.getWindowCount() > 0 then
		innatespells.setVisible(v);
		innatespells_label.setVisible(v);
	else
		innatespells.setVisible(false);
		innatespells_label.setVisible(false);
	end

	if bNPC and spells.getWindowCount() > 0 then
		spellslots.setVisible(v);
		spells.setVisible(v);
		spells_label.setVisible(v);
	else
		spells.setVisible(false);
		spells_label.setVisible(false);
	end

	spacer_action2.setVisible(v);
	
	frame_active.setVisible(v);
end

function setSpacingVisible(v)
	local v = false;
	if activatespacing.getValue() == 1 then
		v = true;
	end

	spacingicon.setVisible(v);
	
	space.setVisible(v);
	spacelabel.setVisible(v);
	reach.setVisible(v);
	reachlabel.setVisible(v);
	
	spacer_space.setVisible(v);

	frame_spacing.setVisible(v);
end

function setEffectsVisible(v)
	local v = false;
	if activateeffects.getValue() == 1 then
		v = true;
	end
	
	effecticon.setVisible(v);
	
	effects.setVisible(v);
	effects_iadd.setVisible(v);
	for _,w in pairs(effects.getWindows()) do
		w.idelete.setValue(0);
	end
	
	frame_effects.setVisible(v);

	effect_summary.onEffectsChanged();
end

function onDrop(x,y,dragdata)
	local sType = dragdata.getType(); 
	--Debug.console('ctentry windowinstance onDrop -- type: ' .. sType); 
	--Diagnostics.dumpDragData(dragdata); 


	if sType == 'token' then
		--nodeCT = CTDragManager.getData();
		--CTDragManager.setData(nil); 
		nodeCT = dragdata.getCustomData(); 
		if nodeCT then
			--Debug.console('ctnode: ' .. nodeCT.getPath()); 

			local nInit = DB.getValue(self.getDatabaseNode(),'initresult',0);
			local nOtherInit = DB.getValue(nodeCT,'initresult',0); 
			local nGreaterInit; 
			local nNewInit; 
			--Debug.console('target init: ' .. nInit); 
			--Debug.console('drag init: ' .. nOtherInit); 
			-- find ct entries with greater init
			local wnds = windowlist.getWindows(); 
			for _,v in pairs(wnds) do
				nCurInit = DB.getValue(v.getDatabaseNode(),'initresult',0); 
				if nCurInit > nInit then
					if not nGreaterInit then
						nGreaterInit = nCurInit;
					elseif nCurInit < nGreaterInit then
						nGreaterInit = nCurInit; 
					end
				end
			end
			-- if no greater, init +1
			--Debug.console('greater: ' .. tostring(nGreaterInit) .. ' target: ' .. tostring(nInit)); 
			if not nGreaterInit then
				nNewInit = math.floor(nInit) + 1;	
			else
				nNewInit = nInit + math.min((nGreaterInit-nInit)/2,1); 
			end
			--Debug.console('New Init? ' .. nNewInit .. ' type: ' .. tostring(type(nNewInit))); 
			DB.setValue(nodeCT,'initresult','number',nNewInit); 
			windowlist.applySort(true); 
		end
	end

end

