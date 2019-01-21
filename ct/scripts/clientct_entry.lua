--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.

function onInit()
	--Debug.console('CLient CTENTRY Init: ' .. self.getDatabaseNode().getPath()); 
	onIDChanged();
	onFactionChanged();
	onHealthChanged();
end

function updateDisplay()
	local sFaction = friendfoe.getStringValue();
	local nPercentWounded, sStatus = ActorManager2.getPercentWounded2("ct", self.getDatabaseNode());
	local sOptCTSI = OptionsManager.getOption("CTSI");
	local bShowInit = ((sOptCTSI == "friend") and (sFaction == "friend")) or (sOptCTSI == "on");
	initresult.setVisible(bShowInit);	

	--Debug.console("Client CTENTRY Update: " .. self.getDatabaseNode().getPath()); 
	
	if active.getValue() == 1 then
		name.setFont("sheetlabel");
		nonid_name.setFont("sheetlabel");

		active_spacer_top.setVisible(true);
		active_spacer_bottom.setVisible(true);
		
		if sFaction == "friend" then
			if sStatus == "Dying" or sStatus == "Dead" then
				setFrame("ctentrybox_friend_active_dark"); 
			elseif sStatus == "Unconscious" then
				setFrame("ctentrybox_friend_active_uncon"); 
			else
				setFrame("ctentrybox_friend_active");
			end
		elseif sFaction == "neutral" then
			if sStatus == "Dying" or sStatus == "Dead" then
				setFrame("ctentrybox_neutral_active_dark");
			elseif sStatus == "Unconscious" then
				setFrame("ctentrybox_friend_active_uncon"); 
			else
				setFrame("ctentrybox_neutral_active");
			end
		elseif sFaction == "foe" then		
			if sStatus == "Dying" or sStatus == "Dead" then	
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
			if sStatus == "Dying" or sStatus == "Dead" then
				setFrame("ctentrybox_active_dark");
			elseif sStatus == "Unconscious" then
				setFrame("ctentrybox_active_uncon");
			else
				setFrame("ctentrybox_active");
			end
		end
		windowlist.scrollToWindow(self);
	else
		name.setFont("sheettext");
		nonid_name.setFont("sheettext");

		active_spacer_top.setVisible(false);
		active_spacer_bottom.setVisible(false);
		
		if sFaction == "friend" then
			if sStatus == "Dying" or sStatus == "Dead" then
				setFrame("ctentrybox_friend_dark");
			elseif sStatus == "Unconscious" then
				setFrame("ctentrybox_friend_uncon");
			else
				setFrame("ctentrybox_friend");
			end
		elseif sFaction == "neutral" then
			if sStatus == "Dying" or sStatus == "Dead" then
				setFrame("ctentrybox_neutral_dark");
			elseif sStatus == "Unconscious" then
				setFrame("ctentrybox_neutral_uncon");
			else
				setFrame("ctentrybox_neutral");
			end
		elseif sFaction == "foe" then			
			if sStatus == "Dying" or sStatus == "Dead" then
				if (OptionsManager.getOption('CE_CTFNPC') == 'on') then
					setFrame("ctentrybox_foe_dark");				
				end					
			elseif sStatus == "Unconscious" then
				setFrame("ctentrybox_foe_uncon");
			else
				setFrame("ctentrybox_foe");
			end
		else
			if sStatus == "Dying" or sStatus == "Dead" then
				setFrame("ctentrybox_dark");
			elseif sStatus == "Unconscious" then
				setFrame("ctentrybox_uncon");
			else
				setFrame("ctentrybox");
			end
		end
	end
	--onIDChanged(); 
end

function onActiveChanged()
	updateDisplay();
end

function onIDChanged()
	local nodeRecord = getDatabaseNode();
	local sClass = DB.getValue(nodeRecord, "link", "npc", "");
	if sClass == "npc" then
		local bID = LibraryData.getIDState("npc", nodeRecord, true);
		name.setVisible(bID);
		nonid_name.setVisible(not bID);
	else
		name.setVisible(true);
		nonid_name.setVisible(false);
	end
end

function onFactionChanged()
	updateHealthDisplay();
	updateDisplay();
end

function onTypeChanged()
	updateHealthDisplay();
end

function onHealthChanged()
	local sColor = ActorManager2.getWoundColor("ct", getDatabaseNode());
	updateDisplay();
	wounds.setColor(sColor);
	status.setColor(sColor);
end

function updateHealthDisplay()
	local sOption;
	if friendfoe.getStringValue() == "friend" then
		sOption = OptionsManager.getOption("SHPC");
	else
		sOption = OptionsManager.getOption("SHNPC");
	end
	
	if sOption == "detailed" then
		hptotal.setVisible(true);
		hptemp.setVisible(true);
		wounds.setVisible(true);

		status.setVisible(false);
	elseif sOption == "status" then
		hptotal.setVisible(false);
		hptemp.setVisible(false);
		wounds.setVisible(false);

		status.setVisible(true);
	else
		hptotal.setVisible(false);
		hptemp.setVisible(false);
		wounds.setVisible(false);

		status.setVisible(false);
	end
end
