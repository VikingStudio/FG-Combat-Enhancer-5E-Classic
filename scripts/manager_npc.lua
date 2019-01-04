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

function onInit()
	if User.isHost() then
		DB.addHandler(DB.getPath(CombatManager.CT_COMBATANT_PATH, "isidentified"), "onUpdate", onCTEntryIDUpdate);
		DB.addHandler(DB.getPath("npc.*", "isidentified"), "onUpdate", onNPCEntryIDUpdate);
	end
end

local bProcessingCTEntryIDUpdate = false;
function onCTEntryIDUpdate(vNode)
	if bProcessingCTEntryIDUpdate then return; end
	bProcessingCTEntryIDUpdate = true;
	
	local nodeCT = vNode.getParent();
	local nIsIdentified = DB.getValue(nodeCT, "isidentified", 1);
	local _,sCTEntrySourceRecord = DB.getValue(nodeCT, "sourcelink", "", "");
	if sCTEntrySourceRecord ~= "" then
		for _,v in pairs(CombatManager.getCombatantNodes()) do
			local _,sRecord = DB.getValue(v, "sourcelink", "", "");
			if sRecord == sCTEntrySourceRecord then
				DB.setValue(v, "isidentified", "number", nIsIdentified);
			end
		end
		-- set the base NPC node as well
		local nodeNPC = DB.findNode(sCTEntrySourceRecord);
		if nodeNPC then
			--Debug.console('CT entry id state changed (npc manager), updating npc id state'); 
			local nodeIdentified = nodeNPC.createChild('isidentified','number'); 
			nodeIdentified.setValue(nIsIdentified); 
		end

	end

	bProcessingCTEntryIDUpdate = false;
end

--[[
-- Lets do this moons way then from the NPCManager
]]--
local bSemaphoreProcessingNPCEntryUpdate = false; 
function onNPCEntryIDUpdate(vNode)
	--Debug.console("attempting to respond to npc entry id"); 
	if bSemaphoreProcessingNPCEntryUpdate or bProcessingCTEntryIDUpdate then return; end
	bSemaphoreProcessingNPCEntryUpdate = true; 
	bProcessingCTEntryIDUpdate = true;

	local nodeNPC = vNode.getParent();
	local nodeNPCRef = nodeNPC.getPath(); 
	local nIsIdentified = DB.getValue(nodeNPC, "isidentified", 1); 

	--Debug.console("attempting to up CT entries"); 
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		local _,sRecord = DB.getValue(v, "sourcelink", "", "");
		if sRecord == nodeNPCRef then
			DB.setValue(v, "isidentified", "number", nIsIdentified);
		end
	end

	bProcessingCTEntryIDUpdate = false;
	bSemaphoreProcessingNPCEntryUpdate = false; 
end

function addLinkToBattle(nodeBattle, sLinkClass, sLinkRecord, nCount)
	local sTargetNPCList = LibraryData.getCustomData("battle", "npclist") or "npclist";

	if sLinkClass == "battle" then
		for _,nodeSrcNPC in pairs(DB.getChildren(DB.getPath(sLinkRecord, sTargetNPCList))) do
			local nodeTargetNPC = DB.createChild(DB.getChild(nodeBattle, sTargetNPCList));
			DB.copyNode(nodeSrcNPC, nodeTargetNPC);
			if nCount then
				DB.setValue(nodeTargetNPC, "count", "number", DB.getValue(nodeTargetNPC, "count", 1) * nCount);
			end
		end
	else
		local bHandle = false;
		if LibraryData.isRecordDisplayClass("npc", sLinkClass) then
			bHandle = true;
		else
			local aCombatClasses = LibraryData.getCustomData("battle", "acceptdrop") or { "npc" };
			if StringManager.contains(aCombatClasses, sLinkClass) then
				bHandle = true;
			end
		end

		if bHandle then
			local sName = DB.getValue(DB.getPath(sLinkRecord, "name"), "");

			local nodeTargetNPC = DB.createChild(DB.getChild(nodeBattle, sTargetNPCList));
			DB.setValue(nodeTargetNPC, "count", "number", nCount or 1);
			DB.setValue(nodeTargetNPC, "name", "string", sName);
			DB.setValue(nodeTargetNPC, "link", "windowreference", sLinkClass, sLinkRecord);
			
			local nodeID = DB.getChild(sLinkRecord, "isidentified");
			if nodeID then
				DB.setValue(nodeTargetNPC, "isidentified", "number", nodeID.getValue());
			end
			
			local sToken = DB.getValue(DB.getPath(sLinkRecord, "token"), "");
			if sToken == "" or not Interface.isToken(sToken) then
				local sLetter = StringManager.trim(sName):match("^([a-zA-Z])");
				if sLetter then
					sToken = "tokens/Medium/" .. sLetter:lower() .. ".png@Letter Tokens";
				else
					sToken = "tokens/Medium/z.png@Letter Tokens";
				end
			end
			DB.setValue(nodeTargetNPC, "token", "token", sToken);
		else
			return false;
		end
	end
	
	return true;
end
