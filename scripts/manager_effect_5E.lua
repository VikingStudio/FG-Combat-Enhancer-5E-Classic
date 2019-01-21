--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.

function onInit()
	EffectManager.registerEffectVar("sUnits", { sDBType = "string", sDBField = "unit", bSkipAdd = true });
	EffectManager.registerEffectVar("sApply", { sDBType = "string", sDBField = "apply", sDisplay = "[%s]" });
	EffectManager.registerEffectVar("sTargeting", { sDBType = "string", bClearOnUntargetedDrop = true });
	
	EffectManager.setCustomOnEffectAddStart(onEffectAddStart);
	EffectManager.setCustomOnEffectAddIgnoreCheck(onEffectAddIgnoreCheck);
	
	EffectManager.setCustomOnEffectRollEncode(onEffectRollEncode);
	EffectManager.setCustomOnEffectTextEncode(onEffectTextEncode);
	EffectManager.setCustomOnEffectTextDecode(onEffectTextDecode);

	EffectManager.setCustomOnEffectActorStartTurn(onEffectActorStartTurn);
end

--
-- EFFECT MANAGER OVERRIDES
--

function onEffectAddStart(rEffect)
	rEffect.nDuration = rEffect.nDuration or 1;
	if rEffect.sUnits == "minute" then
		rEffect.nDuration = rEffect.nDuration * 10;
	elseif rEffect.sUnits == "hour" or rEffect.sUnits == "day" then
		rEffect.nDuration = 0;
	end
	rEffect.sUnits = "";
end

--function onEffectAddIgnoreCheck(nodeCT, rEffect)
function onEffectAddIgnoreCheck(sUser, sIdentity, nodeCT, rEffect, bShowMsg)
	-- Check immunities
	local sDuplicateMsg = nil; 
	local sOrigEffectName = rEffect.sName; 
	local nodeEffectsList = nodeCT.createChild("effects");
	local rSource = ActorManager.getActor("ct", rEffect.sSource);
	local rTarget = ActorManager.getActor("ct", nodeCT);
	local aCancelled = checkImmunities(rSource, rTarget, rEffect);
	if #aCancelled > 0 then
		if rEffect.sName == "" then
			local sMsg = "Effect ['" .. sOrigEffectName .. "'] -> [TARGET IMMUNE]";
			-- Rather than alter EffectManager too much, let's just stuff something with a low probability..
			rEffect.sName = "DUPLICATE_EFFECT_IMMUNE"; 
			return sMsg; 
		else
			local sMsg = "Effect ['" .. rEffect.sName .. "'] -> [TARGET PARTIALLY IMMUNE] [" .. table.concat(aCancelled, ",") .. "]";
			EffectManager.message(sMsg, nodeCT, false, sUser);
		end
	end
	-- check for duplicates, remove them
	for k, v in pairs(nodeEffectsList.getChildren()) do
		if (DB.getValue(v, "label", ""):lower() == rEffect.sName:lower()) then
				sDuplicateMsg = "Effect ['" .. rEffect.sName .. "'] -> [ALREADY EXISTS, REMOVING]"
				break; 
		end
	end

	return sDuplicateMsg;
end

function onEffectRollEncode(rRoll, rEffect)
	if rEffect.sTargeting and rEffect.sTargeting == "self" then
		rRoll.bSelfTarget = true;
	end
end

function onEffectTextEncode(rEffect)
	local aMessage = {};
	
	if rEffect.sUnits and rEffect.sUnits ~= "" then
		local sOutputUnits = nil;
		if rEffect.sUnits == "minute" then
			sOutputUnits = "MIN";
		elseif rEffect.sUnits == "hour" then
			sOutputUnits = "HR";
		elseif rEffect.sUnits == "day" then
			sOutputUnits = "DAY";
		end

		if sOutputUnits then
			table.insert(aMessage, "[UNITS " .. sOutputUnits .. "]");
		end
	end
	if rEffect.sTargeting and rEffect.sTargeting ~= "" then
		table.insert(aMessage, "[" .. rEffect.sTargeting:upper() .. "]");
	end
	if rEffect.sApply and rEffect.sApply ~= "" then
		table.insert(aMessage, "[" .. rEffect.sApply:upper() .. "]");
	end
	
	return table.concat(aMessage, " ");
end

function onEffectTextDecode(sEffect, rEffect)
	local s = sEffect;
	
	local sUnits = s:match("%[UNITS ([^]]+)]");
	if sUnits then
		s = s:gsub("%[UNITS ([^]]+)]", "");
		if sUnits == "MIN" then
			rEffect.sUnits = "minute";
		elseif sUnits == "HR" then
			rEffect.sUnits = "hour";
		elseif sUnits == "DAY" then
			rEffect.sUnits = "day";
		end
	end
	if s:match("%[SELF%]") then
		s = s:gsub("%[SELF%]", "");
		rEffect.sTargeting = "self";
	end
	if s:match("%[ACTION%]") then
		s = s:gsub("%[ACTION%]", "");
		rEffect.sApply = "action";
	elseif s:match("%[ROLL%]") then
		s = s:gsub("%[ROLL%]", "");
		rEffect.sApply = "roll";
	elseif s:match("%[SINGLE%]") then
		s = s:gsub("%[SINGLE%]", "");
		rEffect.sApply = "single";
	end
	
	return s;
end

function onEffectActorStartTurn(nodeActor, nodeEffect)
	local sEffName = DB.getValue(nodeEffect, "label", "");
	local aEffectComps = EffectManager.parseEffect(sEffName);
	for _,sEffectComp in ipairs(aEffectComps) do
		local rEffectComp = parseEffectComp(sEffectComp);
		-- Conditionals
		if rEffectComp.type == "IFT" then
			break;
		elseif rEffectComp.type == "IF" then
			local rActor = ActorManager.getActorFromCT(nodeActor);
			if not checkConditional(rActor, nodeEffect, rEffectComp.remainder) then
				break;
			end
		
		-- Ongoing damage and regeneration
		elseif rEffectComp.type == "DMGO" or rEffectComp.type == "REGEN" then
			local nActive = DB.getValue(nodeEffect, "isactive", 0);
			if nActive == 2 then
				DB.setValue(nodeEffect, "isactive", "number", 1);
			else
				applyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp);
			end

		-- NPC power recharge
		elseif rEffectComp.type == "RCHG" then
			local nActive = DB.getValue(nodeEffect, "isactive", 0);
			if nActive == 2 then
				DB.setValue(nodeEffect, "isactive", "number", 1);
			else
				applyRecharge(nodeActor, nodeEffect, rEffectComp);
			end
		end
	end
end

--
-- CUSTOM FUNCTIONS
--

function parseEffectComp(s)
	local sType = nil;
	local aDice = {};
	local nMod = 0;
	local aRemainder = {};
	local nRemainderIndex = 1;
	
	local aWords, aWordStats = StringManager.parseWords(s, "%[%]%(%):");
	if #aWords > 0 then
		sType = aWords[1]:match("^([^:]+):");
		if sType then
			nRemainderIndex = 2;
			
			local sValueCheck = aWords[1]:sub(#sType + 2);
			if sValueCheck ~= "" then
				table.insert(aWords, 2, sValueCheck);
				table.insert(aWordStats, 2, { startpos = aWordStats[1].startpos + #sType + 1, endpos = aWordStats[1].endpos });
				aWords[1] = aWords[1]:sub(1, #sType + 1);
				aWordStats[1].endpos = #sType + 1;
			end
			
			if #aWords > 1 then
				if StringManager.isDiceString(aWords[2]) then
					aDice, nMod = StringManager.convertStringToDice(aWords[2]);
					nRemainderIndex = 3;
				end
			end
		end
		
		if nRemainderIndex <= #aWords then
			while nRemainderIndex <= #aWords and aWords[nRemainderIndex]:match("^%[[%+%-]?%w+%]$") do
				table.insert(aRemainder, aWords[nRemainderIndex]);
				nRemainderIndex = nRemainderIndex + 1;
			end
		end
		
		if nRemainderIndex <= #aWords then
			local sRemainder = s:sub(aWordStats[nRemainderIndex].startpos);
			local nStartRemainderPhrase = 1;
			local i = 1;
			while i < #sRemainder do
				local sCheck = sRemainder:sub(i, i);
				if sCheck == "," then
					local sRemainderPhrase = sRemainder:sub(nStartRemainderPhrase, i - 1);
					if sRemainderPhrase and sRemainderPhrase ~= "" then
						sRemainderPhrase = StringManager.trim(sRemainderPhrase);
						table.insert(aRemainder, sRemainderPhrase);
					end
					nStartRemainderPhrase = i + 1;
				elseif sCheck == "(" then
					while i < #sRemainder do
						if sRemainder:sub(i, i) == ")" then
							break;
						end
						i = i + 1;
					end
				elseif sCheck == "[" then
					while i < #sRemainder do
						if sRemainder:sub(i, i) == "]" then
							break;
						end
						i = i + 1;
					end
				end
				i = i + 1;
			end
			local sRemainderPhrase = sRemainder:sub(nStartRemainderPhrase, #sRemainder);
			if sRemainderPhrase and sRemainderPhrase ~= "" then
				sRemainderPhrase = StringManager.trim(sRemainderPhrase);
				table.insert(aRemainder, sRemainderPhrase);
			end
		end
	end

	return  {
		type = sType or "", 
		mod = nMod, 
		dice = aDice, 
		remainder = aRemainder, 
		original = StringManager.trim(s)
	};
end

function rebuildParsedEffectComp(rComp)
	if not rComp then
		return "";
	end
	
	local aComp = {};
	if rComp.type ~= "" then
		table.insert(aComp, rComp.type .. ":");
	end
	local sDiceString = StringManager.convertDiceToString(rComp.dice, rComp.mod);
	if sDiceString ~= "" then
		table.insert(aComp, sDiceString);
	end
	if #(rComp.remainder) > 0 then
		table.insert(aComp, table.concat(rComp.remainder, ","));
	end
	return table.concat(aComp, " ");
end

function removeEffectByType(nodeCT, sEffectType)
	if not sEffectType then
		return;
	end
	local aEffectsToDelete = {};

	for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
		local nActive = DB.getValue(nodeEffect, "isactive", 0);
		if (nActive ~= 0) then
			local s = DB.getValue(nodeEffect, "label", "");
			
			local aCompsToDelete = {};
			
			local aEffectComps = EffectManager.parseEffect(s);
			local nComp = 1;
			for _,sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = parseEffectComp(sEffectComp);
				-- Check conditionals
				if rEffectComp.type == "IFT" then
					break;
				elseif rEffectComp.type == "IF" then
					local rActor = ActorManager.getActorFromCT(nodeActor);
					if not checkConditional(rActor, nodeEffect, rEffectComp.remainder) then
						break;
					end
				
				-- Check for effect match
				elseif rEffectComp.type == sEffectType then
					table.insert(aCompsToDelete, nComp);
				end
				
				nComp = nComp + 1;
			end
			
			-- Delete portion of effect that matches (or register for full deletion)
			if #aCompsToDelete >= #aEffectComps then
				table.insert(aEffectsToDelete, nodeEffect);
			elseif #aCompsToDelete > 0 then
				local aNewEffectComps = {};
				local nEffectComps = #aEffectComps;
				for i = 1,nEffectComps do
					if not StringManager.contains(aCompsToDelete, i) then
						table.insert(aNewEffectComps, aEffectComps[i]);
					end
				end
				
				local sNewEffect = EffectManager.rebuildParsedEffect(aNewEffectComps);
				DB.setValue(nodeEffect, "label", "string", sNewEffect);
			end
		end
	end
	
	for _,v in ipairs(aEffectsToDelete) do
		v.delete();
	end
end

function checkImmunities(rSource, rTarget, rEffect)
	local aImmune = getEffectsByType(rTarget, "IMMUNE", {}, rSource);
	
	local aImmuneConditions = {};
	for _,v in pairs(aImmune) do
		for _,vType in pairs(v.remainder) do
			if vType ~= "" and vType:sub(1,1) ~= "!" and vType:sub(1,1) ~= "~" then
				if StringManager.contains(DataCommon.conditions, vType) then
					table.insert(aImmuneConditions, vType:lower());
				end
			end
		end
	end
	if #aImmuneConditions == 0 then
		return {};
	end
	
	local aNewEffectComps = {};
	local aCancelled = {};
	
	local aEffectComps = EffectManager.parseEffect(rEffect.sName);
	for _,sEffectComp in ipairs(aEffectComps) do
		local rEffectComp = parseEffectComp(sEffectComp);
		if StringManager.contains(aImmuneConditions, rEffectComp.original:lower()) then
			table.insert(aCancelled, rEffectComp.original);
		else
			table.insert(aNewEffectComps, sEffectComp);
		end
	end
	if #aCancelled == 0 then
		return {};
	end
	
	rEffect.sName = EffectManager.rebuildParsedEffect(aNewEffectComps);
	return aCancelled;
end

function applyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp)
	if #(rEffectComp.dice) == 0 and rEffectComp.mod == 0 then
		return;
	end
	
	local rTarget = ActorManager.getActor("ct", nodeActor);
	if rEffectComp.type == "REGEN" then
		local nPercentWounded = ActorManager2.getPercentWounded2("ct", nodeActor);
		
		-- If not wounded, then return
		if nPercentWounded <= 0 then
			return;
		end
		-- Regeneration does not work once creature falls below 1 hit point
		if nPercentWounded >= 1 then
			return;
		end
		
		local rAction = {};
		rAction.label = "Regeneration";
		rAction.clauses = {};
		
		local aClause = {};
		aClause.dice = rEffectComp.dice;
		aClause.modifier = rEffectComp.mod;
		table.insert(rAction.clauses, aClause);
		
		local rRoll = ActionHeal.getRoll(nil, rAction);
		if EffectManager.isGMEffect(nodeActor, nodeEffect) then
			rRoll.bSecret = true;
		end
		ActionsManager.actionDirect(nil, "heal", { rRoll }, { { rTarget } });
	else
		local rAction = {};
		rAction.label = "Ongoing damage";
		rAction.clauses = {};
		
		local aClause = {};
		aClause.dice = rEffectComp.dice;
		aClause.modifier = rEffectComp.mod;
		aClause.dmgtype = string.lower(table.concat(rEffectComp.remainder, ","));
		table.insert(rAction.clauses, aClause);
		
		local rRoll = ActionDamage.getRoll(nil, rAction);
		if EffectManager.isGMEffect(nodeActor, nodeEffect) then
			rRoll.bSecret = true;
		end
		ActionsManager.actionDirect(nil, "damage", { rRoll }, { { rTarget } });
	end
end

function applyRecharge(nodeActor, nodeEffect, rEffectComp)
	local rActor = ActorManager.getActorFromCT(nodeActor);
	local sRecharge = table.concat(rEffectComp.remainder, " ");
	ActionRecharge.performRoll(nil, rActor, sRecharge, rEffectComp.mod, EffectManager.isGMEffect(nodeActor, nodeEffect), nodeEffect);
end

function evalAbilityHelper(rActor, sEffectAbility)
	local sSign, sModifier, sTag = sEffectAbility:match("^%[([%+%-]?)([H2]?)([A-Z]+)%]$");
	
	local nAbility = nil;
	if sTag == "STR" then
		nAbility = ActorManager2.getAbilityBonus(rActor, "strength");
	elseif sTag == "DEX" then
		nAbility = ActorManager2.getAbilityBonus(rActor, "dexterity");
	elseif sTag == "CON" then
		nAbility = ActorManager2.getAbilityBonus(rActor, "constitution");
	elseif sTag == "INT" then
		nAbility = ActorManager2.getAbilityBonus(rActor, "intelligence");
	elseif sTag == "WIS" then
		nAbility = ActorManager2.getAbilityBonus(rActor, "wisdom");
	elseif sTag == "CHA" then
		nAbility = ActorManager2.getAbilityBonus(rActor, "charisma");
	elseif sTag == "LVL" then
		nAbility = ActorManager2.getAbilityBonus(rActor, "level");
	elseif sTag == "PRF" then
		nAbility = ActorManager2.getAbilityBonus(rActor, "prf");
	else
		nAbility = ActorManager2.getAbilityScore(rActor, sTag:lower());
	end
	
	if nAbility then
		if sSign == "-" then
			nAbility = 0 - nAbility;
		end
		if sModifier == "H" then
			if nAbility > 0 then
				nAbility = math.floor(nAbility / 2);
			else
				nAbility = math.ceil(nAbility / 2);
			end
		elseif sModifier == "2" then
			nAbility = nAbility * 2;
		end
	end
	
	return nAbility;
end

function evalEffect(rActor, s)
	if not s then
		return "";
	end
	if not rActor then
		return s;
	end
	
	local aNewEffectComps = {};
	local aEffectComps = EffectManager.parseEffect(s);
	for _,sEffectComp in ipairs(aEffectComps) do
		local vComp = parseEffectComp(sEffectComp);
		for i = #(vComp.remainder), 1, -1 do
			if vComp.remainder[i]:match("^%[([%+%-]?)([H2]?)([A-Z]+)%]$") then
				local nAbility = evalAbilityHelper(rActor, vComp.remainder[i]);
				if nAbility then
					vComp.mod = vComp.mod + nAbility;
					table.remove(vComp.remainder, i);
				end
			end
		end
		table.insert(aNewEffectComps, rebuildParsedEffectComp(vComp));
	end
	local sOutput = EffectManager.rebuildParsedEffect(aNewEffectComps);

	return sOutput;
end

function getEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
	if not rActor then
		return {};
	end
	local results = {};
	
	-- Set up filters
	local aRangeFilter = {};
	local aOtherFilter = {};
	if aFilter then
		for _,v in pairs(aFilter) do
			if type(v) ~= "string" then
				table.insert(aOtherFilter, v);
			elseif StringManager.contains(DataCommon.rangetypes, v) then
				table.insert(aRangeFilter, v);
			else
				table.insert(aOtherFilter, v);
			end
		end
	end
	
	-- Determine effect type targeting
	local bTargetSupport = StringManager.isWord(sEffectType, DataCommon.targetableeffectcomps);
	
	-- Iterate through effects
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		-- Check active
		local nActive = DB.getValue(v, "isactive", 0);
		if (nActive ~= 0) then
			local sLabel = DB.getValue(v, "label", "");
			local sApply = DB.getValue(v, "apply", "");

			-- IF COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETS, THEN CHECK AGAINST OUR TARGET
			local bTargeted = EffectManager.isTargetedEffect(v);
			if not bTargeted or EffectManager.isEffectTarget(v, rFilterActor) then
				local aEffectComps = EffectManager.parseEffect(sLabel);

				-- Look for type/subtype match
				local nMatch = 0;
				for kEffectComp,sEffectComp in ipairs(aEffectComps) do
					local rEffectComp = parseEffectComp(sEffectComp);
					-- Handle conditionals
					if rEffectComp.type == "IF" then
						if not checkConditional(rActor, v, rEffectComp.remainder) then
							break;
						end
					elseif rEffectComp.type == "IFT" then
						if not rFilterActor then
							break;
						end
						if not checkConditional(rFilterActor, v, rEffectComp.remainder, rActor) then
							break;
						end
						bTargeted = true;
					
					-- Compare other attributes
					else
						-- Strip energy/bonus types for subtype comparison
						local aEffectRangeFilter = {};
						local aEffectOtherFilter = {};
						local j = 1;
						while rEffectComp.remainder[j] do
							local s = rEffectComp.remainder[j];
							if #s > 0 and ((s:sub(1,1) == "!") or (s:sub(1,1) == "~")) then
								s = s:sub(2);
							end
							if StringManager.contains(DataCommon.dmgtypes, s) or s == "all" or 
									StringManager.contains(DataCommon.bonustypes, s) or
									StringManager.contains(DataCommon.conditions, s) or
									StringManager.contains(DataCommon.connectors, s) then
								-- SKIP
							elseif StringManager.contains(DataCommon.rangetypes, s) then
								table.insert(aEffectRangeFilter, s);
							else
								table.insert(aEffectOtherFilter, s);
							end
							
							j = j + 1;
						end
					
						-- Check for match
						local comp_match = false;
						if rEffectComp.type == sEffectType then

							-- Check effect targeting
							if bTargetedOnly and not bTargeted then
								comp_match = false;
							else
								comp_match = true;
							end
						
							-- Check filters
							if #aEffectRangeFilter > 0 then
								local bRangeMatch = false;
								for _,v2 in pairs(aRangeFilter) do
									if StringManager.contains(aEffectRangeFilter, v2) then
										bRangeMatch = true;
										break;
									end
								end
								if not bRangeMatch then
									comp_match = false;
								end
							end
							if #aEffectOtherFilter > 0 then
								local bOtherMatch = false;
								for _,v2 in pairs(aOtherFilter) do
									if type(v2) == "table" then
										local bOtherTableMatch = true;
										for k3, v3 in pairs(v2) do
											if not StringManager.contains(aEffectOtherFilter, v3) then
												bOtherTableMatch = false;
												break;
											end
										end
										if bOtherTableMatch then
											bOtherMatch = true;
											break;
										end
									elseif StringManager.contains(aEffectOtherFilter, v2) then
										bOtherMatch = true;
										break;
									end
								end
								if not bOtherMatch then
									comp_match = false;
								end
							end
						end

						-- Match!
						if comp_match then
							nMatch = kEffectComp;
							if nActive == 1 then
								table.insert(results, rEffectComp);
							end
						end
					end
				end -- END EFFECT COMPONENT LOOP

				-- Remove one shot effects
				if nMatch > 0 then
					if nActive == 2 then
						DB.setValue(v, "isactive", "number", 1);
					else
						if sApply == "action" then
							EffectManager.notifyExpire(v, 0);
						elseif sApply == "roll" then
							EffectManager.notifyExpire(v, 0, true);
						elseif sApply == "single" then
							EffectManager.notifyExpire(v, nMatch, true);
						end
					end
				end
			end -- END TARGET CHECK
		end  -- END ACTIVE CHECK
	end  -- END EFFECT LOOP
	
	-- RESULTS
	return results;
end

function getEffectsBonusByType(rActor, aEffectType, bAddEmptyBonus, aFilter, rFilterActor, bTargetedOnly)
	if not rActor or not aEffectType then
		return {}, 0;
	end
	
	-- MAKE BONUS TYPE INTO TABLE, IF NEEDED
	if type(aEffectType) ~= "table" then
		aEffectType = { aEffectType };
	end
	
	-- PER EFFECT TYPE VARIABLES
	local results = {};
	local bonuses = {};
	local penalties = {};
	local nEffectCount = 0;
	
	for k, v in pairs(aEffectType) do
		-- LOOK FOR EFFECTS THAT MATCH BONUSTYPE
		local aEffectsByType = getEffectsByType(rActor, v, aFilter, rFilterActor, bTargetedOnly);

		-- ITERATE THROUGH EFFECTS THAT MATCHED
		for k2,v2 in pairs(aEffectsByType) do
			-- LOOK FOR ENERGY OR BONUS TYPES
			local dmg_type = nil;
			local mod_type = nil;
			for _,v3 in pairs(v2.remainder) do
				if StringManager.contains(DataCommon.dmgtypes, v3) or StringManager.contains(DataCommon.conditions, v3) or v3 == "all" then
					dmg_type = v3;
					break;
				elseif StringManager.contains(DataCommon.bonustypes, v3) then
					mod_type = v3;
					break;
				end
			end
			
			-- IF MODIFIER TYPE IS UNTYPED, THEN APPEND MODIFIERS
			-- (SUPPORTS DICE)
			if dmg_type or not mod_type then
				-- ADD EFFECT RESULTS 
				local new_key = dmg_type or "";
				local new_results = results[new_key] or {dice = {}, mod = 0, remainder = {}};

				-- BUILD THE NEW RESULT
				for _,v3 in pairs(v2.dice) do
					table.insert(new_results.dice, v3); 
				end
				if bAddEmptyBonus then
					new_results.mod = new_results.mod + v2.mod;
				else
					new_results.mod = math.max(new_results.mod, v2.mod);
				end
				for _,v3 in pairs(v2.remainder) do
					table.insert(new_results.remainder, v3);
				end

				-- SET THE NEW DICE RESULTS BASED ON ENERGY TYPE
				results[new_key] = new_results;

			-- OTHERWISE, TRACK BONUSES AND PENALTIES BY MODIFIER TYPE 
			-- (IGNORE DICE, ONLY TAKE BIGGEST BONUS AND/OR PENALTY FOR EACH MODIFIER TYPE)
			else
				local bStackable = StringManager.contains(DataCommon.stackablebonustypes, mod_type);
				if v2.mod >= 0 then
					if bStackable then
						bonuses[mod_type] = (bonuses[mod_type] or 0) + v2.mod;
					else
						bonuses[mod_type] = math.max(v2.mod, bonuses[mod_type] or 0);
					end
				elseif v2.mod < 0 then
					if bStackable then
						penalties[mod_type] = (penalties[mod_type] or 0) + v2.mod;
					else
						penalties[mod_type] = math.min(v2.mod, penalties[mod_type] or 0);
					end
				end

			end
			
			-- INCREMENT EFFECT COUNT
			nEffectCount = nEffectCount + 1;
		end
	end

	-- COMBINE BONUSES AND PENALTIES FOR NON-ENERGY TYPED MODIFIERS
	for k2,v2 in pairs(bonuses) do
		if results[k2] then
			results[k2].mod = results[k2].mod + v2;
		else
			results[k2] = {dice = {}, mod = v2, remainder = {}};
		end
	end
	for k2,v2 in pairs(penalties) do
		if results[k2] then
			results[k2].mod = results[k2].mod + v2;
		else
			results[k2] = {dice = {}, mod = v2, remainder = {}};
		end
	end

	return results, nEffectCount;
end

function getEffectsBonus(rActor, aEffectType, bModOnly, aFilter, rFilterActor, bTargetedOnly)
	if not rActor or not aEffectType then
		if bModOnly then
			return 0, 0;
		end
		return {}, 0, 0;
	end
	
	-- MAKE BONUS TYPE INTO TABLE, IF NEEDED
	if type(aEffectType) ~= "table" then
		aEffectType = { aEffectType };
	end
	
	-- START WITH AN EMPTY MODIFIER TOTAL
	local aTotalDice = {};
	local nTotalMod = 0;
	local nEffectCount = 0;
	
	-- ITERATE THROUGH EACH BONUS TYPE
	local masterbonuses = {};
	local masterpenalties = {};
	for k, v in pairs(aEffectType) do
		-- GET THE MODIFIERS FOR THIS MODIFIER TYPE
		local effbonusbytype, nEffectSubCount = getEffectsBonusByType(rActor, v, true, aFilter, rFilterActor, bTargetedOnly);
		
		-- ITERATE THROUGH THE MODIFIERS
		for k2, v2 in pairs(effbonusbytype) do
			-- IF MODIFIER TYPE IS UNTYPED, THEN APPEND TO TOTAL MODIFIER
			-- (SUPPORTS DICE)
			if k2 == "" or StringManager.contains(DataCommon.dmgtypes, k2) then
				for k3, v3 in pairs(v2.dice) do
					table.insert(aTotalDice, v3);
				end
				nTotalMod = nTotalMod + v2.mod;
			
			-- OTHERWISE, WE HAVE A NON-ENERGY MODIFIER TYPE, WHICH MEANS WE NEED TO INTEGRATE
			-- (IGNORE DICE, ONLY TAKE BIGGEST BONUS AND/OR PENALTY FOR EACH MODIFIER TYPE)
			else
				if v2.mod >= 0 then
					masterbonuses[k2] = math.max(v2.mod, masterbonuses[k2] or 0);
				elseif v2.mod < 0 then
					masterpenalties[k2] = math.min(v2.mod, masterpenalties[k2] or 0);
				end
			end
		end

		-- ADD TO EFFECT COUNT
		nEffectCount = nEffectCount + nEffectSubCount;
	end

	-- ADD INTEGRATED BONUSES AND PENALTIES FOR NON-ENERGY TYPED MODIFIERS
	for k,v in pairs(masterbonuses) do
		nTotalMod = nTotalMod + v;
	end
	for k,v in pairs(masterpenalties) do
		nTotalMod = nTotalMod + v;
	end
	
	if bModOnly then
		return nTotalMod, nEffectCount;
	end
	return aTotalDice, nTotalMod, nEffectCount;
end

function hasEffectCondition(rActor, sEffect)
	return hasEffect(rActor, sEffect, nil, false, true);
end

function hasEffect(rActor, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
	if not sEffect or not rActor then
		return false;
	end
	local sLowerEffect = sEffect:lower();
	
	-- Iterate through each effect
	local aMatch = {};
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);
		if nActive ~= 0 then
			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local bTargeted = EffectManager.isTargetedEffect(v);
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for kEffectComp,sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = parseEffectComp(sEffectComp);
				-- Handle conditionals
				if rEffectComp.type == "IF" then
					if not checkConditional(rActor, v, rEffectComp.remainder) then
						break;
					end
				elseif rEffectComp.type == "IFT" then
					if not rTarget then
						break;
					end
					if not checkConditional(rTarget, v, rEffectComp.remainder, rActor) then
						break;
					end
				
				-- Check for match
				elseif rEffectComp.original:lower() == sLowerEffect then
					if bTargeted and not bIgnoreEffectTargets then
						if EffectManager.isEffectTarget(v, rTarget) then
							nMatch = kEffectComp;
						end
					elseif not bTargetedOnly then
						nMatch = kEffectComp;
					end
				end
				
			end
			
			-- If matched, then remove one-off effects
			if nMatch > 0 then
				if nActive == 2 then
					DB.setValue(v, "isactive", "number", 1);
				else
					table.insert(aMatch, v);
					local sApply = DB.getValue(v, "apply", "");
					if sApply == "action" then
						EffectManager.notifyExpire(v, 0);
					elseif sApply == "roll" then
						EffectManager.notifyExpire(v, 0, true);
					elseif sApply == "single" then
						EffectManager.notifyExpire(v, nMatch, true);
					end
				end
			end
		end
	end
	
	if #aMatch > 0 then
		return true;
	end
	return false;
end

function checkConditional(rActor, nodeEffect, aConditions, rTarget, aIgnore)
	local bReturn = true;
	
	if not aIgnore then
		aIgnore = {};
	end
	table.insert(aIgnore, nodeEffect.getNodeName());
	
	for _,v in ipairs(aConditions) do
		local sLower = v:lower();
		if sLower == DataCommon.healthstatusfull then
			local nPercentWounded = ActorManager2.getPercentWounded(rActor);
			if nPercentWounded > 0 then
				bReturn = false;
			end
		elseif sLower == DataCommon.healthstatushalf then
			local nPercentWounded = ActorManager2.getPercentWounded(rActor);
			if nPercentWounded < .5 then
				bReturn = false;
			end
		elseif sLower == DataCommon.healthstatuswounded then
			local nPercentWounded = ActorManager2.getPercentWounded(rActor);
			if nPercentWounded == 0 then
				bReturn = false;
			end
		elseif StringManager.contains(DataCommon.conditions, sLower) then
			if not checkConditionalHelper(rActor, sLower, rTarget, aIgnore) then
				bReturn = false;
			end
		elseif StringManager.contains(DataCommon.conditionaltags, sLower) then
			if not checkConditionalHelper(rActor, sLower, rTarget, aIgnore) then
				bReturn = false;
			end
		else
			local sAlignCheck = sLower:match("^align%s*%(([^)]+)%)$");
			local sSizeCheck = sLower:match("^size%s*%(([^)]+)%)$");
			local sTypeCheck = sLower:match("^type%s*%(([^)]+)%)$");
			local sCustomCheck = sLower:match("^custom%s*%(([^)]+)%)$");
			if sAlignCheck then
				if not ActorManager2.isAlignment(rActor, sAlignCheck) then
					bReturn = false;
				end
			elseif sSizeCheck then
				if not ActorManager2.isSize(rActor, sSizeCheck) then
					bReturn = false;
				end
			elseif sTypeCheck then
				if not ActorManager2.isCreatureType(rActor, sTypeCheck) then
					bReturn = false;
				end
			elseif sCustomCheck then
				if not checkConditionalHelper(rActor, sCustomCheck, rTarget, aIgnore) then
					bReturn = false;
				end
			end
		end
	end
	
	table.remove(aIgnore);
	
	return bReturn;
end

function checkConditionalHelper(rActor, sEffect, rTarget, aIgnore)
	if not rActor then
		return false;
	end
	
	local bReturn = false;
	
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);
		if nActive ~= 0 and not StringManager.contains(aIgnore, v.getNodeName()) then
			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local bTargeted = EffectManager.isTargetedEffect(v);
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for kEffectComp, sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = parseEffectComp(sEffectComp);
				-- CHECK FOR FOLLOWON EFFECT TAGS, AND IGNORE THE REST
				if rEffectComp.type == "AFTER" or rEffectComp.type == "FAIL" then
					break;
				
				-- CHECK CONDITIONALS
				elseif rEffectComp.type == "IF" then
					if not checkConditional(rActor, v, rEffectComp.remainder, nil, aIgnore) then
						break;
					end
				elseif rEffectComp.type == "IFT" then
					if not rTarget then
						break;
					end
					if not checkConditional(rTarget, v, rEffectComp.remainder, rActor, aIgnore) then
						break;
					end
				
				-- CHECK FOR AN ACTUAL EFFECT MATCH
				elseif rEffectComp.original:lower() == sEffect then
					if bTargeted then
						if EffectManager.isEffectTarget(v, rTarget) then
							bReturn = true;
						end
					else
						bReturn = true;
					end
				end
			end
		end
	end
	
	return bReturn;
end

function encodeEffectForCT(rEffect)
	local aMessage = {};
	
	if rEffect then
		table.insert(aMessage, "EFF:");
		table.insert(aMessage, rEffect.sName);

		local sDurDice = StringManager.convertDiceToString(rEffect.aDice, rEffect.nDuration);
		if sDurDice ~= "" then
			local sOutputUnits = nil;
			if rEffect.sUnits and rEffect.sUnits ~= "" then
				if rEffect.sUnits == "minute" then
					sOutputUnits = "MIN";
				elseif rEffect.sUnits == "hour" then
					sOutputUnits = "HR";
				elseif rEffect.sUnits == "day" then
					sOutputUnits = "DAY";
				end
			end
			
			if sOutputUnits then
				table.insert(aMessage, "(D:" .. sDurDice .. " " .. sOutputUnits .. ")");
			else
				table.insert(aMessage, "(D:" .. sDurDice .. ")");
			end
		end

		if rEffect.sTargeting and rEffect.sTargeting ~= "" then
			table.insert(aMessage, "(T:" .. rEffect.sTargeting:upper() .. ")");
		end
		
		if rEffect.sApply and rEffect.sApply ~= "" then
			table.insert(aMessage, "(A:" .. rEffect.sApply:upper() .. ")");
		end
	end
	
	return "[" .. table.concat(aMessage, " ") .. "]";
end

function decodeEffectFromCT(sEffect)
	local rEffect = nil;

	local sEffectName = sEffect:match("EFF: ?(.+)");
	if sEffectName then
		rEffect = {};
		
		rEffect.sType = "effect";
		
		rEffect.nDuration = 0;
		rEffect.sUnits = "";
		local sDurDice, sUnits = sEffect:match("%(D:([d%dF%+%-]+) ?([^)]*)%)");
		if sDurDice then
			rEffect.aDice, rEffect.nDuration = StringManager.convertStringToDice(sDurDice);
			if sUnits then
				if sUnits == "MIN" then
					rEffect.sUnits = "minute";
				elseif sUnits == "HR" then
					rEffect.sUnits = "hour";
				elseif sUnits == "DAY" then
					rEffect.sUnits = "day";
				end
			end
		end
		sEffectName = sEffectName:gsub("%(D:[^)]*%)", "");
		
		rEffect.sTargeting = "";
		if sEffect:match("%(T:SELF%)") then
			rEffect.sTargeting = "self";
		end
		sEffectName = sEffectName:gsub("%(T:[^)]*%)", "");
		
		rEffect.sApply = "";
		if sEffect:match("%(A:ACTION%)") then
			rEffect.sApply = "action";
		elseif sEffect:match("%(A:ROLL%)") then
			rEffect.sApply = "roll";
		elseif sEffect:match("%(A:SINGLE%)") then
			rEffect.sApply = "single";
		end
		sEffectName = sEffectName:gsub("%(A:[^)]*%)", "");

		rEffect.sName = StringManager.trim(sEffectName);
	end
	
	return rEffect;
end

