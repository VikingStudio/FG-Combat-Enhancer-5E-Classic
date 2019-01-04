-- 'Fantasy Grounds' is a trademark of SmiteWorks USA, LLC. 'Fantasy Grounds' is Copyright 2004-2014 SmiteWorks USA LLC.
-- The CoreRPG ruleset and all included files are copyright 2004-2013, Smiteworks USA LLC.

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
				setFrame("ctentrybox_foe_active_dark");
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
				setFrame("ctentrybox_foe_dark");
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
