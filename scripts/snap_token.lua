--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.

local wLastSnapToken = nil; 


function onInit()
	Token.onClickRelease = onClickRelease;
	--CombatManager.setCustomTurnStart(customTurnStart); 
	--CombatManager.setCustomTurnEnd(customTurnEnd); 
end

function onClickRelease(target, button, image)
	if button ~= 1 then 
		return; 
	end
	
	local nodeCT = CombatManager.getCTFromToken(target);
	local sTokenCTNodePath = DB.getPath(nodeCT); 
	local wCT,wl_CT,tCTWindows,wTokenCTEntry,wActiveTokenCTEntry,sNodePath;

	-- Debug.console(sTokenCTNodePath); 
	
	if User.isHost() then
		wCT = Interface.findWindow("combattracker_host","combattracker");
	else
		wCT = Interface.findWindow("combattracker_client","combattracker"); 
	end
	
	if wCT ~= nil then
		-- Debug.console("we have the combat tracker window!"); 
	else
		-- Debug.console("Opening CT, it wasn't open"); 
		if User.isHost() then
			wCT = Interface.openWindow("combattracker_host","combattracker");
		else
			wCT = Interface.openWindow("combattracker_client","combattracker");
		end
	end

	-- bring it to the front. 
	wCT.bringToFront(); 

	-- try to get the ct_entry from the window by looking for the path
	-- WARN: we're directly hitching into an element, this can change
	tControls = wCT.getControls();
	for k,v in pairs(tControls) do
		-- Debug.console(tostring(k) .. ' -- ' .. tostring(v.getName())); 
		if v.getName() == 'list' then
			wl_CT = v; 
		end
	end

	tCTWindows = wl_CT.getWindows(false); 
	for k,v in pairs(tCTWindows) do
		sNodePath = DB.getPath(v.getDatabaseNode()); 
		-- Debug.console(sNodePath); 
		if sNodePath == sTokenCTNodePath then
			--Debug.console('Eurika!'); 
			wTokenCTEntry = v; 
		end
		if DB.getValue(v.getDatabaseNode(),'active',0) == 1 then
			--Debug.console('Found Active!'); 
			wActiveTokenCTEntry = v; 	
		end
	end

	if wTokenCTEntry ~= nil then
		doHighlightEntry(wTokenCTEntry,true); 
		if wLastSnapToken ~= nil then
			-- make sure our reference is still good
			noerr, errmsg = pcall(wLastSnapToken.getDatabaseNode,nil); 
			if noerr then 
				-- if you keep selecting the same token, make it a toggle
				if DB.getPath(wLastSnapToken.getDatabaseNode()) == DB.getPath(wTokenCTEntry.getDatabaseNode()) then
					wLastSnapToken = nil; 
					--Snap back to the active token if we have an active token
					if wActiveTokenCTEntry then
						wActiveTokenCTEntry.windowlist.scrollToWindow(wActiveTokenCTEntry);
					end
				else
					wLastSnapToken = wTokenCTEntry; 
					wTokenCTEntry.windowlist.scrollToWindow(wTokenCTEntry);
				end
			end
		else
			wLastSnapToken = wTokenCTEntry; 
			wTokenCTEntry.windowlist.scrollToWindow(wTokenCTEntry);
		end
	else
		doHighlightEntry(wTokenCTEntry,false); 
		wLastSnapToken = nil; 
		-- Debug.console("nope, can't find the entry for the token!"); 
	end

	-- open token information window (both for pc and npc) on control + left-click
	if Input.isControlPressed() == true then
		CombatEnhancer.openTokenInformationWindow(target, image)	
	end
end

-- toggle our highlight effects, note we must account for the
-- chance that the ct_entry isn't valid as we must still
-- handle the wLastSnapToken irregardless of if the ct_entry
-- is valid.
function doHighlightEntry(ct_entry,toggle)
	local sFaction,bActive,bLastActive; 
	local nPercentWounded, sStatus; 

	if toggle then
		-- only highlight if we're not the active, the active already has a pretty obvious highlight
		-- we only need to seek to it which is handled elsewhere
		if ct_entry ~= nil then
			bActive = DB.getValue(ct_entry.getDatabaseNode(), "active", 0) == 1; 
			nPercentWounded, sStatus = ActorManager2.getPercentWounded2("ct", ct_entry.getDatabaseNode());
			sFaction = ct_entry.friendfoe.getStringValue();
			ct_entry.setFrame(getHighlightEntryFrame(sFaction,true,bActive,sStatus));
			doExpandHighlightEntry(ct_entry,true,bActive); 
		end
		-- clean up last snapped token
		if wLastSnapToken ~= nil then
			-- make sure our reference is still good
			noerr, errmsg = pcall(wLastSnapToken.getDatabaseNode,nil); 
			if noerr then
				bLastActive = DB.getValue(wLastSnapToken.getDatabaseNode(), "active", 0) == 1; 
				nPercentWounded,sStatus = ActorManager2.getPercentWounded2("ct", wLastSnapToken.getDatabaseNode());
				sFaction = wLastSnapToken.friendfoe.getStringValue();
				wLastSnapToken.setFrame(getHighlightEntryFrame(sFaction,false,bLastActive,sStatus));
				doExpandHighlightEntry(wLastSnapToken,false,bLastActive); 
			else
				wLastSnapToken = nil; 
			end
		end
	else
		if ct_entry ~= nil then
			bActive = DB.getValue(ct_entry.getDatabaseNode(), "active", 0) == 1; 
			nPercentWounded, sStatus = ActorManager2.getPercentWounded2("ct", ct_entry.getDatabaseNode());
			sFaction = ct_entry.friendfoe.getStringValue();
			ct_entry.setFrame(getHighlightEntryFrame(sFaction,false,bActive,sStatus));
			doExpandHighlightEntry(ct_entry,false,bActive); 
		end
		-- clean up last snapped token
		if wLastSnapToken ~= nil then
			-- make sure our reference is still good
			noerr, errmsg = pcall(wLastSnapToken.getDatabaseNode,nil); 
			if noerr then
				bLastActive = DB.getValue(wLastSnapToken.getDatabaseNode(), "active", 0) == 1; 
				nPercentWounded, sStatus = ActorManager2.getPercentWounded2("ct", wLastSnapToken.getDatabaseNode());
				sFaction = wLastSnapToken.friendfoe.getStringValue();
				wLastSnapToken.setFrame(getHighlightEntryFrame(sFaction,false,bLastActive,sStatus));
				doExpandHighlightEntry(wLastSnapToken,false,bLastActive); 
			else
				wLastSnapToken = nil; 
			end
		end
	end
end

-- expand some portions of the highlighted entry pending on host/client
function doExpandHighlightEntry(ct_entry,toggle,bActive)
	local sClass, sRecord = ct_entry.link.getValue();
	local bNPC = (sClass ~= "charsheet");

	if toggle then
		if User.isHost() then
			if not bActive then
				ct_entry.activateactive.setValue(1); 
				ct_entry.setActiveVisible(); 
			end
			ct_entry.activateeffects.setValue(1); 
			ct_entry.activateattributes.setValue(1); 
			ct_entry.setEffectsVisible(); 
			ct_entry.setAttributesVisible(); 
		else
			-- client
			ct_entry.activateeffects.setValue(1); 
		end
	else
		if User.isHost() then
			if not bActive then
				ct_entry.activateactive.setValue(0); 
				ct_entry.setActiveVisible(); 
			end
			ct_entry.activateeffects.setValue(0); 
			ct_entry.activateattributes.setValue(0); 
			ct_entry.setEffectsVisible(); 
			ct_entry.setAttributesVisible(); 
		else
			-- client
			ct_entry.activateeffects.setValue(0); 
		end
	end
end

-- seperated host active from client active incase of divergence
function getHighlightEntryFrame(sFaction,selected,bActive,sStatus) 
	local retval = nil; 

	if User.isHost() then
		if bActive then
			if sFaction == "friend" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_friend_active_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_friend_active_uncon");
				else
					return ("ctentrybox_friend_active");
				end
			elseif sFaction == "neutral" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_neutral_active_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_neutral_active_uncon");
				else
					return ("ctentrybox_neutral_active");
				end
			elseif sFaction == "foe" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_foe_active_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_foe_active_uncon");
				else
					return ("ctentrybox_foe_active");
				end
			else
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_active_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_active_uncon");
				else
					return ("ctentrybox_active");
				end
			end
		elseif selected then
			if sFaction == "friend" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_friend_selected_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_friend_selected_uncon");
				else
					return ("ctentrybox_friend_selected");
				end
			elseif sFaction == "neutral" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_neutral_selected_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_neutral_selected_uncon");
				else
					return ("ctentrybox_neutral_selected");
				end
			elseif sFaction == "foe" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_foe_selected_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_foe_selected_uncon");
				else
					return ("ctentrybox_foe_selected");
				end
			else
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_selected_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_selected_uncon");
				else
					return ("ctentrybox_selected");
				end
			end
		else
			if sFaction == "friend" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_friend_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_friend_uncon");
				else
					return ("ctentrybox_friend");
				end
			elseif sFaction == "neutral" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_neutral_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_neutral_uncon");
				else
					return ("ctentrybox_neutral");
				end
			elseif sFaction == "foe" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_foe_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_foe_uncon");
				else
					return ("ctentrybox_foe");
				end
			else
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_uncon");
				else
					return ("ctentrybox");
				end
			end
		end
	else
		if bActive then
			if sFaction == "friend" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_friend_active_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_friend_active_uncon");
				else
					return ("ctentrybox_friend_active");
				end
			elseif sFaction == "neutral" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_neutral_active_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_neutral_active_uncon");
				else
					return ("ctentrybox_neutral_active");
				end
			elseif sFaction == "foe" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_foe_active_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_foe_active_uncon");
				else
					return ("ctentrybox_foe_active");
				end
			else
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_active_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_active_uncon");
				else
					return ("ctentrybox_active");
				end
			end
		elseif selected then
			if sFaction == "friend" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_friend_selected_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_friend_selected_uncon");
				else
					return ("ctentrybox_friend_selected");
				end
			elseif sFaction == "neutral" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_neutral_selected_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_neutral_selected_uncon");
				else
					return ("ctentrybox_neutral_selected");
				end
			elseif sFaction == "foe" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_foe_selected_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_foe_selected_uncon");
				else
					return ("ctentrybox_foe_selected");
				end
			else
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_selected_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_selected_uncon");
				else
					return ("ctentrybox_selected");
				end
			end
		else
			if sFaction == "friend" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_friend_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_friend_uncon");
				else
					return ("ctentrybox_friend");
				end
			elseif sFaction == "neutral" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_neutral_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_neutral_uncon");
				else
					return ("ctentrybox_neutral");
				end
			elseif sFaction == "foe" then
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_foe_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_foe_uncon");
				else
					return ("ctentrybox_foe");
				end
			else
				if sStatus == "Dead" or sStatus:match("Dying") then
					return ("ctentrybox_dark");
				elseif sStatus == "Unconscious" then
					return ("ctentrybox_uncon");
				else
					return ("ctentrybox");
				end
			end
		end
	end
end

function customTurnStart(nodeCT)
	if User.isHost() then
		if nodeCT then
			local tokenCT = CombatManager.getTokenFromCT(nodeCT);
			if tokenCT then
				-- the token exists
				local space = nodeCT.getChild('space');  
				if space == nil then 
					space = 1;
				else
					space = space.getValue()/5/2+0.5; 
				end

				--Debug.console('space is ' .. space); 
				tokenCT.addUnderlay(space, CombatEnhancer.TOKENUNDERLAYCOLOR_1); 
			end
		end
	end
end

function customTurnEnd(nodeCT)
	if User.isHost() then
		if nodeCT then
			local tokenCT = CombatManager.getTokenFromCT(nodeCT);
			if tokenCT then
				-- the token exists
				tokenCT.removeAllUnderlays(); 
			end
		end
	end
end

