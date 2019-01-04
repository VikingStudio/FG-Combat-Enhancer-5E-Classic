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

-- Standard effect fields
--		sName
--		nGMOnly
--		sSource

OOB_MSGTYPE_APPLYEFF = "applyeff";
OOB_MSGTYPE_EXPIREEFF = "expireeff";

EFFECT_TAG = "EFFECT"

local nLocked = 0;
local aExpireOnLockRelease = {};

local aEffectVarMap = {
	["sName"] = { sDBType = "string", sDBField = "label" },
	["nGMOnly"] = { sDBType = "number", sDBField = "isgmonly" },
	["sSource"] = { sDBType = "string", sDBField = "source_name", bClearOnUntargetedDrop = true },
	["sTarget"] = { sDBType = "string", bClearOnUntargetedDrop = true },
	["nDuration"] = { sDBType = "number", sDBField = "duration", vDBDefault = 1, sDisplay = "[D: %d]" },
	["nInit"] = { sDBType = "number", sDBField = "init", sSourceChangeSet = "initresult", bClearOnUntargetedDrop = true },
};
-- NOTE: isactive is a DB field that is part of all CT effects, but not tracked in the effect record

function onInit()
	--Debug.console("CUSTOM EFFECT MANAGER LOADED"); 
	CombatManager.setCustomInitChange(processEffects);
	
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYEFF, handleApplyEffect);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_EXPIREEFF, handleExpireEffect);
end

function registerEffectVar(sVar, vData)	
	if vData and (((vData.sDBType or "") ~= "string") and ((vData.sDBType or "") ~= "number")) then
		print("Invalid effect variable type registered. (" .. sVar .. ")");
		return;
	end
	aEffectVarMap[sVar] = vData;
end

--
-- CUSTOM EVENT HANDLING
--

local fCustomOnEffectAddStart = nil;
function setCustomOnEffectAddStart(f)
	fCustomOnEffectAddStart = f;
end

local fCustomOnEffectAddIgnoreCheck = nil;
function setCustomOnEffectAddIgnoreCheck(f)
	fCustomOnEffectAddIgnoreCheck = f;
end

local fCustomOnEffectAddEnd = nil;
function setCustomOnEffectAddEnd(f)
	fCustomOnEffectAddEnd = f;
end

local fCustomOnEffectExpire = nil;
function setCustomOnEffectExpire(f)
	fCustomOnEffectExpire = f;
end

local fCustomOnEffectDragDecode = nil;
function setCustomOnEffectDragDecode(f)
	fCustomOnEffectDragDecode = f;
end

local fCustomOnEffectRollEncode = nil;
function setCustomOnEffectRollEncode(f)
	fCustomOnEffectRollEncode = f;
end

local fCustomOnEffectRollDecode = nil;
function setCustomOnEffectRollDecode(f)
	fCustomOnEffectRollDecode = f;
end

local fCustomOnEffectTextEncode = nil;
function setCustomOnEffectTextEncode(f)
	fCustomOnEffectTextEncode = f;
end

local fCustomOnEffectTextDecode = nil;
function setCustomOnEffectTextDecode(f)
	fCustomOnEffectTextDecode = f;
end

-- NOTE: These 4 custom functions should return true, if effect expired/removed
local fCustomOnEffectActorStartTurn = nil;
function setCustomOnEffectActorStartTurn(f)
	fCustomOnEffectActorStartTurn = f;
end

local fCustomOnEffectActorEndTurn = nil;
function setCustomOnEffectActorEndTurn(f)
	fCustomOnEffectActorEndTurn = f;
end

local fCustomOnEffectStartTurn = nil;
function setCustomOnEffectStartTurn(f)
	fCustomOnEffectStartTurn = f;
end

local fCustomOnEffectEndTurn = nil;
function setCustomOnEffectEndTurn(f)
	fCustomOnEffectEndTurn = f;
end

local nInitDirection = -1;
function setInitAscending(b)
	if b then
		nInitDirection = 1;
	else
		nInitDirection = -1;
	end
end

--
-- EFFECT TURN CHANGE HANDLING
--

function processEffects(nodeCurrentActor, nodeNewActor)
	-- Get sorted combatant list
	local aEntries = CombatManager.getSortedCombatantList();
	if #aEntries == 0 then
		return;
	end
		
	-- Set up current and new initiative values for effect processing
	local nCurrentInit;
	if nodeCurrentActor then
		nCurrentInit = DB.getValue(nodeCurrentActor, "initresult", 0); 
	elseif nInitDirection > 0 then
		nCurrentInit = -10000;
	else
		nCurrentInit = 10000;
	end
	local nNewInit;
	if nodeNewActor then
		nNewInit = DB.getValue(nodeNewActor, "initresult", 0);
	elseif nInitDirection > 0 then
		nNewInit = 10000;
	else
		nNewInit = -10000;
	end
	
	-- For each actor, advance durations, and process start of turn special effects
	local bProcessSpecialStart = (nodeCurrentActor == nil);
	local bProcessSpecialEnd = (nodeCurrentActor == nil);
	for i = 1,#aEntries do
		local nodeActor = aEntries[i];
		
		if nodeActor == nodeCurrentActor then
			bProcessSpecialEnd = true;
		elseif nodeActor == nodeNewActor then
			bProcessSpecialEnd = false;
		end

		-- Check each effect
		for _,nodeEffect in pairs(DB.getChildren(nodeActor, "effects")) do
			processEffect(nodeActor, nodeEffect, nCurrentInit, nNewInit, bProcessSpecialStart, bProcessSpecialEnd);
		end -- END EFFECT LOOP
		
		if nodeActor == nodeCurrentActor then
			bProcessSpecialStart = true;
		elseif nodeActor == nodeNewActor then
			bProcessSpecialStart = false;
		end
	end -- END ACTOR LOOP
end

function processEffect(nodeActor, nodeEffect, nCurrentInit, nNewInit, bProcessSpecialStart, bProcessSpecialEnd)
	-- Make sure effect is active
	local sEffectPath = nodeEffect.getPath();
	local nActive = DB.getValue(nodeEffect, "isactive", 0);
	if (nActive ~= 0) then
		if bProcessSpecialStart then
			if fCustomOnEffectActorStartTurn then
				if fCustomOnEffectActorStartTurn(nodeActor, nodeEffect) then return; end
			end
		end

		if aEffectVarMap["nInit"] then
			local nEffInit = DB.getValue(nodeEffect, aEffectVarMap["nInit"].sDBField, aEffectVarMap["nInit"].vDBDefault or 0);
		
			-- Apply start of effect initiative changes
			if ((nInitDirection > 0) and (nEffInit > nCurrentInit and nEffInit <= nNewInit)) or (nEffInit < nCurrentInit and nEffInit >= nNewInit) then
				-- Start turn
				if fCustomOnEffectStartTurn then
					if fCustomOnEffectStartTurn(nodeActor, nodeEffect, nCurrentInit, nNewInit) then return; end
				end
				if aEffectVarMap["nDuration"] then
					local nDuration = DB.getValue(nodeEffect, aEffectVarMap["nDuration"].sDBField, 0);
					if nDuration > 0 then
						nDuration = nDuration - 1;
						if nDuration <= 0 then
							expireEffect(nodeActor, nodeEffect, 0);
							return;
						end
						DB.setValue(nodeEffect, "duration", "number", nDuration);
					end
				end
				
			-- Apply end of effect initiative changes
			elseif ((nInitDirection > 0) and (nEffInit >= nCurrentInit and nEffInit < nNewInit)) or (nEffInit <= nCurrentInit and nEffInit > nNewInit) then
				if fCustomOnEffectEndTurn then
					if fCustomOnEffectEndTurn(nodeActor, nodeEffect, nCurrentInit, nNewInit) then return; end
				end
			end
		end
		
		if bProcessSpecialEnd then
			if fCustomOnEffectActorEndTurn then
				if fCustomOnEffectActorEndTurn(nodeActor, nodeEffect) then return; end
			end
		end
	end -- END ACTIVE EFFECT CHECK
end

--
-- EFFECT APPLICATION AND EXPIRATION HANDLING
--

function handleApplyEffect(msgOOB)
	-- Get the target combat tracker node
	local nodeCTEntry = DB.findNode(msgOOB.sTargetNode);
	if not nodeCTEntry then
		ChatManager.SystemMessage(Interface.getString("ct_error_effectapplyfail") .. " (" .. msgOOB.sTargetNode .. ")");
		return;
	end
	
	-- Reconstitute the effect details
	local rEffect = {};
	for k,v in pairs(msgOOB) do
		if aEffectVarMap[k] then
			if aEffectVarMap[k].sDBType == "number" then
				rEffect[k] = tonumber(msgOOB[k]) or 0;
			else
				rEffect[k] = msgOOB[k];
			end
		end
	end
	
	-- Apply the effect
	addEffect(msgOOB.user, msgOOB.identity, nodeCTEntry, rEffect, true);
end

function notifyApply(rEffect, vTargets)
	-- Build OOB message to pass effect to host
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYEFF;
	for k,v in pairs(rEffect) do
		if aEffectVarMap[k] then
			if aEffectVarMap[k].sDBType == "number" then
				msgOOB[k] = rEffect[k] or aEffectVarMap[k].vDBDefault or 0;
			else
				msgOOB[k] = rEffect[k] or aEffectVarMap[k].vDBDefault or "";
			end
		end
	end
	if User.isHost() then
		msgOOB.user = "";
	else
		msgOOB.user = User.getUsername();
	end
	msgOOB.identity = User.getIdentityLabel();

	-- Send one message for each target
	if type(vTargets) == "table" then
		for _, v in pairs(vTargets) do
			msgOOB.sTargetNode = v;
			Comm.deliverOOBMessage(msgOOB, "");
		end
	else
		msgOOB.sTargetNode = vTargets;
		Comm.deliverOOBMessage(msgOOB, "");
	end
end

function handleExpireEffect(msgOOB)
	local nodeEffect = DB.findNode(msgOOB.sEffectNode);
	if not nodeEffect then
		ChatManager.SystemMessage(Interface.getString("ct_error_effectdeletefail") .. " (" .. msgOOB.sEffectNode .. ")");
		return;
	end
	local nodeActor = nodeEffect.getChild("...");
	if not nodeActor then
		ChatManager.SystemMessage(Interface.getString("ct_error_effectmissingactor") .. " (" .. msgOOB.sEffectNode .. ")");
		return;
	end
	
	expireEffect(nodeActor, nodeEffect, tonumber(msgOOB.nExpireClause) or 0);
end

function notifyExpire(varEffect, nMatch, bImmediate)
	if type(varEffect) == "databasenode" then
		varEffect = varEffect.getNodeName();
	elseif type(varEffect) ~= "string" then
		return;
	end
	
	if (nLocked > 0) and not bImmediate then
		table.insert(aExpireOnLockRelease, varEffect);
		return;
	end
	
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_EXPIREEFF;
	msgOOB.sEffectNode = varEffect;
	msgOOB.nExpireClause = nMatch;
	
	Comm.deliverOOBMessage(msgOOB, "");
end

function setEffect(nodeEffect, rEffect)
	for k, v in pairs(aEffectVarMap) do
		if v.sDBField then
			local nodeEffectChild = nodeEffect.getChild(v.sDBField);
			if nodeEffectChild then
				nodeEffectChild.setValue(rEffect[k]);
			end
		end
	end
end

function getEffect(nodeEffect)
	local rEffect = {};
	for k, v in pairs(aEffectVarMap) do
		if v.sDBField then
			rEffect[k] = DB.getValue(nodeEffect, v.sDBField, v.vDBDefault);
		end
	end
	return rEffect;
end

function onUntargetedDrop(rEffect)
	for k,v in pairs(rEffect) do
		if aEffectVarMap[k] and aEffectVarMap[k].bClearOnUntargetedDrop then
			rEffect[k] = nil;
		end
	end
end

function onEffectSourceChanged(rEffect, nodeSource)
	for k, v in pairs(aEffectVarMap) do
		if v.sSourceChangeSet then
			if v.sDBType == "number" then
				rEffect[k] = DB.getValue(nodeSource, v.sSourceChangeSet, v.vDBDefault or 0);
			else
				rEffect[k] = DB.getValue(nodeSource, v.sSourceChangeSet, v.vDBDefault or "");
			end
		end
	end
end

function onCTEffectSourceChanged(nodeEffect, nodeSource)
	for k, v in pairs(aEffectVarMap) do
		if v.sSourceChangeSet and v.sDBType and v.sDBField then
			if v.sDBType == "number" then
				DB.setValue(nodeEffect, v.sDBField, v.sDBType, DB.getValue(nodeSource, v.sSourceChangeSet, v.vDBDefault or 0));
			else
				DB.setValue(nodeEffect, v.sDBField, v.sDBType, DB.getValue(nodeSource, v.sSourceChangeSet, v.vDBDefault or ""));
			end
		end
	end
end

--
-- EFFECTS
--

function message(sMsg, nodeCTEntry, bGMOnly, sUser)
	local msg = {font = "msgfont", icon = "roll_effect", text = sMsg};
	if nodeCTEntry then
		msg.text = msg.text .. " [on " .. ActorManager.getDisplayName(nodeCTEntry) .. "]";
	end
	
	if sUser then
		if sUser == "" then
			Comm.addChatMessage(msg);
		else
			Comm.deliverChatMessage(msg, sUser);
		end
	elseif bGMOnly then
		msg.secret = true;
		if User.isHost() then
			Comm.addChatMessage(msg);
		else
			Comm.deliverChatMessage(msg, User.getUsername());
		end
	else
		Comm.deliverChatMessage(msg);
	end
end

function getEffectString(nodeEffect, bPublicOnly)
	if DB.getValue(nodeEffect, "isactive", 0) ~= 1 then
		return "";
	end
	
	local sLabel = DB.getValue(nodeEffect, "label", "");

	local bAddEffect = true;
	local bGMOnly = false;
	if sLabel == "" then
		bAddEffect = false;
	elseif DB.getValue(nodeEffect, "isgmonly", 0) == 1 then
		if User.isHost() and not bPublicOnly then
			bGMOnly = true;
		else
			bAddEffect = false;
		end
	end

	if not bAddEffect then
		return "";
	end
	
	local aEffectComps = parseEffect(sLabel);

	if isTargetedEffect(nodeEffect) then
		local sTargets = table.concat(getEffectTargets(nodeEffect, true), ",");
		table.insert(aEffectComps, 1, "[TRGT: " .. sTargets .. "]");
	end
	
	for k,v in pairs(aEffectVarMap) do
		if v.fDisplay then
			local vValue = v.fDisplay(nodeEffect);
			if vValue then
				table.insert(aEffectComps, vValue);
			end
		elseif v.sDisplay and v.sDBField then
			local vDBValue;
			if v.sDBType == "number" then
				vDBValue = DB.getValue(nodeEffect, v.sDBField, v.vDBDefault or 0);
				if vDBValue == 0 then
					vDBValue = nil;
				end
			else
				vDBValue = DB.getValue(nodeEffect, v.sDBField, v.vDBDefault or "");
				if vDBValue == "" then
					vDBValue = nil;
				end
			end
			if vDBValue then
				table.insert(aEffectComps, string.format(v.sDisplay, tostring(vDBValue):upper()));
			end
		end
	end

	local sOutputLabel = rebuildParsedEffect(aEffectComps);
	if bGMOnly then
		sOutputLabel = "(" .. sOutputLabel .. ")";
	end

	return sOutputLabel;
end

function getEffectsString(nodeCTEntry, bPublicOnly)
	local aOutputEffects = {};
	
	-- Iterate through each effect
	local aSorted = {};
	for _,nodeChild in pairs(DB.getChildren(nodeCTEntry, "effects")) do
		table.insert(aSorted, nodeChild);
	end
	table.sort(aSorted, function (a, b) return a.getName() < b.getName() end);
	for _,v in pairs(aSorted) do
		local sEffect = getEffectString(v, bPublicOnly);
		if sEffect ~= "" then
			table.insert(aOutputEffects, sEffect);
		end
	end
	
	return table.concat(aOutputEffects, " | ");
end

function isGMEffect(nodeActor, nodeEffect)
	if nodeEffect and (DB.getValue(nodeEffect, "isgmonly", 0) == 1) then
		return true;
	end
	if nodeActor and CombatManager.isCTHidden(nodeActor) then
		return true;
	end
	return false;
end

function removeEffect(nodeCTEntry, sEffPatternToRemove)
	if not sEffPatternToRemove then
		return;
	end
	for _,nodeEffect in pairs(DB.getChildren(nodeCTEntry, "effects")) do
		if DB.getValue(nodeEffect, "label", ""):match(escMagic(sEffPatternToRemove)) then
			nodeEffect.delete();
			return;
		end
	end
end

--[[
	Escape magic characters
]]--
function escMagic(str)
	if not str then return; end
	str = str:gsub('%(','%%('); 
	str = str:gsub('%)','%%)'); 
	str = str:gsub('%.','%%.'); 
	str = str:gsub('%+','%%+'); 
	str = str:gsub('%-','%%-'); 
	str = str:gsub('%*','%%*'); 
	str = str:gsub('%?','%%?'); 
	str = str:gsub('%[','%%['); 
	str = str:gsub('%^','%%^'); 
	str = str:gsub('%$','%%$'); 
	return str; 
end

function addEffect(sUser, sIdentity, nodeCT, rNewEffect, bShowMsg)
	if not nodeCT or not rNewEffect or not rNewEffect.sName then
		return;
	end
	local nodeEffectsList = nodeCT.createChild("effects");
	if not nodeEffectsList then
		return;
	end
	
	if fCustomOnEffectAddStart then
		fCustomOnEffectAddStart(rNewEffect);
	end
	
	-- Check whether to ignore new effect (i.e. duplicates)
	local sDuplicateMsg = nil;
	if fCustomOnEffectAddIgnoreCheck then
		sDuplicateMsg = fCustomOnEffectAddIgnoreCheck(sUser, sIdentity, nodeCT, rNewEffect, bShowMsg);
	else
		for k, v in pairs(nodeEffectsList.getChildren()) do
			--Debug.console('comparing: ' .. DB.getValue(v, "label", ""):lower() .. ' to ' .. rNewEffect.sName:lower()); 
			if (DB.getValue(v, "label", ""):lower() == rNewEffect.sName:lower()) --[[and 
					(DB.getValue(v, "init", 0) == rNewEffect.nInit) and
					(DB.getValue(v, "duration", 0) == rNewEffect.nDuration)]]--
					then
				sDuplicateMsg = "Effect ['" .. rNewEffect.sName .. "'] -> [ALREADY EXISTS, REMOVING]"
				break;
			end
		end
	end
	if sDuplicateMsg then
		message(sDuplicateMsg, nodeCT, false, sUser);
		-- we should try to remove the effect instead!
		removeEffect(nodeCT,rNewEffect.sName); 
		return;
	end
	
	-- Write effect record
	local nodeTargetEffect = nodeEffectsList.createChild();
	for k,v in pairs(aEffectVarMap) do
		if rNewEffect[k] and v.sDBType and v.sDBField and not v.bSkipAdd then
			DB.setValue(nodeTargetEffect, v.sDBField, v.sDBType, rNewEffect[k]);
		end
	end
	DB.setValue(nodeTargetEffect, "isactive", "number", 1);

	-- Handle effect targeting
	if rNewEffect.sTarget and rNewEffect.sTarget ~= "" then
		addEffectTarget(nodeTargetEffect, rNewEffect.sTarget);
	end
	
	if fCustomOnEffectAddEnd then
		fCustomOnEffectAddEnd(nodeTargetEffect, rNewEffect);
	end

	-- Handle effect ownership
	if sUser ~= "" then
		DB.setOwner(nodeTargetEffect, sUser);
	end

	-- Build output message
	local msg = {font = "msgfont", icon = "roll_effect"};
	msg.text = "Effect ['" .. rNewEffect.sName .. "'] ";
	msg.text = msg.text .. "-> [to " .. ActorManager.getDisplayName(nodeCT) .. "]";
	if rNewEffect.sSource and rNewEffect.sSource ~= "" then
		msg.text = msg.text .. " [by " .. ActorManager.getDisplayName(DB.findNode(rNewEffect.sSource)) .. "]";
	end
	
	-- Output message
	if bShowMsg then
		if isGMEffect(nodeCT, nodeTargetEffect) then
			if sUser == "" then
				msg.secret = true;
				Comm.addChatMessage(msg);
			elseif sUser ~= "" then
				Comm.addChatMessage(msg);
				Comm.deliverChatMessage(msg, sUser);
			end
		else
			Comm.deliverChatMessage(msg);
		end
	end
end

function parseEffect(sEffect)
	local aEffectComps = {};
	for s in sEffect:gmatch("([^;]*);?") do
		local sTrim = StringManager.trim(s);
		if sTrim ~= "" then
			table.insert(aEffectComps, sTrim);
		end
	end
	return aEffectComps;
end

function rebuildParsedEffect(aEffectComps)
	return table.concat(aEffectComps, "; ");
end

function expireEffect(nodeActor, nodeEffect, nExpireComp)
	if not nodeEffect then
		return false;
	end
	
	local bGMOnly = isGMEffect(nodeActor, nodeEffect);

	if fCustomOnEffectExpire then
		local sExpirationMsg = fCustomOnEffectExpire(nodeEffect, nExpireComp or 0);
		if sExpirationMsg then
			message(sExpirationMsg, nodeActor, bGMOnly);
			return true;
		end
	end

	local sEffect = DB.getValue(nodeEffect, "label", "");

	-- Check for partial expiration
	if (nExpireComp or 0) > 0 then
		local aEffectComps = parseEffect(sEffect);
		if #aEffectComps > 1 then
			table.remove(aEffectComps, nExpireComp);
			DB.setValue(nodeEffect, "label", "string", rebuildParsedEffect(aEffectComps));
			message("Effect ['" .. sEffect .. "'] -> [SINGLE MOD USED]", nodeActor, bGMOnly);
			return true;
		end
	end
	
	-- Process full expiration
	nodeEffect.delete();
	message("Effect ['" .. sEffect .. "'] -> [EXPIRED]", nodeActor, bGMOnly);
	return true;
end

function disableEffect(nodeActor, nodeEffect)
	if not nodeEffect then
		return false;
	end

	local sEffect = DB.getValue(nodeEffect, "label", "");
	local bGMOnly = isGMEffect(nodeActor, nodeEffect);
	
	DB.setValue(nodeEffect, "isactive", "number", 2);
	message("Effect ['" .. sEffect .. "'] -> [DISABLED]", nodeActor, bGMOnly);
end

--
--  HANDLE EFFECT LOCKING
--

function lock()
	nLocked = nLocked + 1;
end

function unlock()
	nLocked = nLocked - 1;
	if nLocked < 0 then
		nLocked = 0;
	end

	if nLocked == 0 then
		local aExpired = {};
		for _,v in ipairs(aExpireOnLockRelease) do
			if not aExpired[v] then
				EffectManager.notifyExpire(v, 0, true);
				aExpired[v] = true;
			end
		end
		aExpireOnLockRelease = {};
	end
end

--
-- EFFECT TARGETING
--

function setEffectSource(nodeEffect, nodeCT)
	if not nodeCT then
		return;
	end
	local nodeEffectActor = DB.getChild(nodeEffect, "...");
	if not nodeEffectActor then
		return;
	end
	
	local sSourcePath = nodeCT.getPath();
	if nodeEffectActor.getPath() == sSourcePath then
		DB.setValue(nodeEffect, "source_name", "string", "");
		nodeCT = nil;
	else
		DB.setValue(nodeEffect, "source_name", "string", sSourcePath);
	end
	
	onCTEffectSourceChanged(nodeEffect, nodeCT);
end

function isTargetedEffect(nodeEffect)
	return (DB.getChildCount(nodeEffect, "targets") > 0);
end

function isEffectTarget(nodeEffect, rTarget)
	local bMatch = false;
	
	local sTargetCT = ActorManager.getCTNodeName(rTarget);
	if sTargetCT ~= "" then
		for _,v in pairs(DB.getChildren(nodeEffect, "targets")) do
			if DB.getValue(v, "noderef", "") == sTargetCT then
				bMatch = true;
				break;
			end
		end
	end

	return bMatch;
end

function getEffectTargets(nodeEffect, bUseName)
	local aTargets = {};
	
	for _,nodeTarget in pairs(DB.getChildren(nodeEffect, "targets")) do
		local sNode = DB.getValue(nodeTarget, "noderef", "");
		if bUseName then
			table.insert(aTargets, ActorManager.getDisplayName(sNode));
		else
			table.insert(aTargets, sNode);
		end
	end

	return aTargets;
end

function addEffectTarget(vEffect, sTargetNode)
	if sTargetNode == "" then
		return;
	end
	
	local nodeTargetList = nil;
	if type(vEffect) == "string" then
		nodeTargetList = DB.createChild(DB.findNode(vEffect), "targets");
	elseif type(vEffect) == "databasenode" then
		nodeTargetList = DB.createChild(vEffect, "targets");
	end
	if not nodeTargetList then
		return;
	end
	
	for _,nodeTarget in pairs(nodeTargetList.getChildren()) do
		if (DB.getValue(nodeTarget, "noderef", "") == sTargetNode) then
			return;
		end
	end

	local nodeNewTarget = nodeTargetList.createChild();
	if nodeNewTarget then
		DB.setValue(nodeNewTarget, "noderef", "string", sTargetNode);
	end
end

function setEffectFactionTargets(nodeEffect, sFaction, bNegated)
	if not nodeEffect then
		return;
	end
	
	clearEffectTargets(nodeEffect);
	
	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		if bNegated then
			if DB.getValue(nodeCT, "friendfoe", "") ~= sFaction then
				addEffectTarget(nodeEffect, nodeCT.getNodeName());
			end
		else
			if DB.getValue(nodeCT, "friendfoe", "") == sFaction then
				addEffectTarget(nodeEffect, nodeCT.getNodeName());
			end
		end
	end
end

function clearEffectTargets(nodeEffect)
	for _,nodeTarget in pairs(DB.getChildren(nodeEffect, "targets")) do
		nodeTarget.delete();
	end
end

--
-- HELPER FUNCTIONS
--

function decodeEffectFromDrag(draginfo, rTarget)
	local rEffect = nil;
	
	local sDragType = draginfo.getType();
	local sDragDesc = "";

	local bEffectDrag = false;
	if sDragType == "effect" then
		bEffectDrag = true;
		sDragDesc = draginfo.getStringData();
	elseif sDragType == "number" then
		if sDragDesc:match("%[" .. EFFECT_TAG) then
			bEffectDrag = true;
			sDragDesc = draginfo.getDescription();
		end
	end
	
	if bEffectDrag then
		rEffect = decodeEffectFromText(sDragDesc, draginfo.getSecret());
		if rEffect then
			if aEffectVarMap["nDuration"] then
				rEffect.nDuration = draginfo.getNumberData();
			end
			if fCustomOnEffectDragDecode then
				fCustomOnEffectDragDecode(draginfo, rEffect);
			end
			if not rTarget then
				onUntargetedDrop(rEffect);
			end
		end
	end
	
	return rEffect;
end

function encodeEffect(rAction)
	local rRoll = {};
	rRoll.sType = "effect";
	rRoll.sDesc = encodeEffectAsText(rAction);
	if rAction.nGMOnly then
		rRoll.bSecret = (rAction.nGMOnly ~= 0);
	end
	if aEffectVarMap["nDuration"] then
		rRoll.aDice = rAction.aDice or {};
		rRoll.nMod = rAction.nDuration or 0;
	end
	if fCustomOnEffectRollEncode then
		fCustomOnEffectRollEncode(rRoll, rAction);
	end
	return rRoll;
end

function decodeEffect(rRoll)
	local rEffect = decodeEffectFromText(rRoll.sDesc, rRoll.bSecret);
	if not rEffect then return nil; end
	if aEffectVarMap["nDuration"] then
		rEffect.aDice = rRoll.aDice;
		rEffect.nMod = rRoll.nMod;
		rEffect.nDuration = ActionsManager.total(rRoll);
	end
	if rEffect and fCustomOnEffectRollDecode then
		fCustomOnEffectRollDecode(rRoll, rEffect);
	end
	return rEffect;
end

function encodeEffectAsText(rEffect)
	local aMessage = {};
	
	if rEffect then
		table.insert(aMessage, "[" .. EFFECT_TAG .. "] " .. rEffect.sName);

		if fCustomOnEffectTextEncode then
			local sEncode = fCustomOnEffectTextEncode(rEffect);
			if sEncode ~= "" then
				table.insert(aMessage, sEncode);
			end
		end

		if aEffectVarMap["nInit"] and rEffect.nInit and rEffect.nInit ~= 0 then
			table.insert(aMessage, "[INIT " .. rEffect.nInit .. "]");
		end
		
		if rEffect.sSource and rEffect.sSource ~= "" then
			table.insert(aMessage, "[by " .. rEffect.sSource .. "]");
		end
	end
	
	return table.concat(aMessage, " ");
end

function decodeEffectFromText(sEffect, bSecret)
	local rEffect = {};

	local s = sEffect;
	if fCustomOnEffectTextDecode then
		s = fCustomOnEffectTextDecode(s, rEffect);
	end

	rEffect.sSource = sEffect:match("%[by ([^]]+)%]") or "";
	s = s:gsub("%[by ([^]]+)%]", "");
	
	if aEffectVarMap["nInit"] then
		local sEffectInit = sEffect:match("%[INIT (%d+)%]");
		if sEffectInit then
			s = s:gsub("%[INIT (%d+)%]", "");
			rEffect.nInit = tonumber(sEffectInit) or 0;
		end
	end

	s = s:gsub("^%[" .. EFFECT_TAG .. "%] ", "");
	s = StringManager.trim(s);
	
	if s == "" then
		return nil;
	end
		
	rEffect.sName = s;
	if bSecret then
		rEffect.nGMOnly = 1;
	else
		rEffect.nGMOnly = 0;
	end

	return rEffect;
end

function onEffectFilter(w)
	local node = w.getDatabaseNode();
	if DB.getValue(node, "isgmonly", 0) == 1 then
		return false;
	end
	if not DB.isOwner(node) then
		if DB.getValue(node, "isactive", 1) == 0 then
			return false;
		end
	end
	return true;
end
